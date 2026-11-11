import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

import '../user/user_database.dart';

/// Wire rows contain SQLite column values, never computed vocabulary counts.
class LearningSyncRow {
  const LearningSyncRow(
    this.table,
    this.key,
    this.data,
    this.changedAt,
    this.hash,
  );
  final String table, key, hash;
  final Map<String, Object?> data;
  final int changedAt;
  Map<String, Object?> toJson() => {
    'kind': table,
    'key': key,
    'data': data,
    'changed_at': changedAt,
    'hash': hash,
  };
  factory LearningSyncRow.fromJson(Map<String, dynamic> json) =>
      LearningSyncRow(
        json['kind'] as String,
        json['key'] as String,
        Map<String, Object?>.from(json['data'] as Map),
        (json['changed_at'] as num).toInt(),
        json['hash'] as String,
      );
}

abstract interface class LearningSyncGateway {
  Future<void> push(List<LearningSyncRow> rows);
  Future<List<LearningSyncRow>> pull({String? after});
}

class LearningSyncAccountMismatch implements Exception {
  const LearningSyncAccountMismatch();
}

/// Allowlist is also the dependency order for restoring local cards and their
/// immutable contexts before memberships. Private tokens/consents are excluded.
const learningSyncTables = <String, List<String>>{
  'user_cards': ['card_id'],
  'card_contexts': ['id'],
  'review_log': ['id'],
  'deck_settings': ['deck_id'],
  'story_learning_additions': ['card_id'],
  'generated_vocabulary_additions': ['card_id'],
  'story_word_sources': ['card_id', 'fingerprint'],
  'learning_identity_bindings': ['identity_key'],
  'form_identity_bindings': ['identity_key'],
  'language_learning_preferences': ['lang'],
  'learning_sync_documents': ['id'],
};
const _mutable = {
  'user_cards',
  'deck_settings',
  'language_learning_preferences',
  'learning_sync_documents',
};

String syncCanonicalJson(Object? value) {
  Object? sorted(Object? v) {
    if (v is Map) {
      final keys = v.keys.cast<String>().toList()..sort();
      return {for (final k in keys) k: sorted(v[k])};
    }
    if (v is List) return v.map(sorted).toList();
    return v;
  }

  return jsonEncode(sorted(value));
}

String _hash(Map<String, Object?> row) =>
    sha256.convert(utf8.encode(syncCanonicalJson(row))).toString();

/// Sidecars are deliberately separate from the generated learning schema.
Future<void> prepareLearningSync(UserDatabase db) async {
  await db.customStatement(
    'CREATE TABLE IF NOT EXISTS learning_sync_owner (id INTEGER PRIMARY KEY CHECK(id=1), owner TEXT NOT NULL)',
  );
  await db.customStatement(
    'CREATE TABLE IF NOT EXISTS learning_sync_versions (kind TEXT NOT NULL, row_key TEXT NOT NULL, hash TEXT NOT NULL, changed_at INTEGER NOT NULL, PRIMARY KEY(kind,row_key))',
  );
  await db.customStatement(
    'CREATE TABLE IF NOT EXISTS learning_sync_documents (id TEXT PRIMARY KEY, store TEXT NOT NULL, entry_key TEXT NOT NULL, payload TEXT NOT NULL, updated_at INTEGER NOT NULL, deleted INTEGER NOT NULL DEFAULT 0)',
  );
  await db.customStatement(
    'CREATE TABLE IF NOT EXISTS learning_sync_uploaded (kind TEXT NOT NULL,row_key TEXT NOT NULL,hash TEXT NOT NULL,PRIMARY KEY(kind,row_key))',
  );
  await db.customStatement(
    'CREATE TABLE IF NOT EXISTS learning_sync_document_imports (store TEXT PRIMARY KEY)',
  );
}

/// Sync never owns/closes the database. [isCurrent] fences every asynchronous
/// boundary; owner binding is persisted before any data can leave the device.
class LearningSyncService {
  LearningSyncService(
    this.db,
    this.gateway, {
    required this.owner,
    required this.isCurrent,
    DateTime Function()? clock,
  }) : clock = clock ?? DateTime.now;
  final UserDatabase db;
  final LearningSyncGateway gateway;
  final String owner;
  final bool Function() isCurrent;
  final DateTime Function() clock;
  Future<bool>? _running;
  void _check() {
    if (!isCurrent()) throw StateError('Lernkonto hat sich geändert.');
  }

  Future<bool> synchronize() =>
      _running ??= _sync().whenComplete(() => _running = null);

  Future<void> _bind() async {
    await prepareLearningSync(db);
    await db.transaction(() async {
      _check();
      await db.customStatement(
        'INSERT OR IGNORE INTO learning_sync_owner (id,owner) VALUES (1,?)',
        [owner],
      );
      final bound = await db
          .customSelect('SELECT owner FROM learning_sync_owner WHERE id=1')
          .getSingle();
      if (bound.read<String>('owner') != owner) {
        throw const LearningSyncAccountMismatch();
      }
    });
  }

  Future<List<LearningSyncRow>> _snapshot() async {
    final rows = <LearningSyncRow>[];
    // Both callers run this within their snapshot transaction. Read the
    // metadata once instead of holding the learner database for one worker
    // round trip per card/review (twice on every periodic sync).
    final versions = {
      for (final row
          in await db
              .customSelect(
                'SELECT kind,row_key,hash,changed_at FROM learning_sync_versions',
              )
              .get())
        (row.read<String>('kind'), row.read<String>('row_key')): row,
    };
    for (final entry in learningSyncTables.entries) {
      final data = await db.customSelect('SELECT * FROM "${entry.key}"').get();
      for (final raw in data) {
        final row = Map<String, Object?>.from(raw.data);
        final key = syncCanonicalJson([
          for (final field in entry.value) row[field],
        ]);
        rows.add(
          await _version(entry.key, key, row, versions[(entry.key, key)]),
        );
      }
    }
    return rows;
  }

  Future<LearningSyncRow> _version(
    String table,
    String key,
    Map<String, Object?> data,
    QueryRow? previous,
  ) async {
    final hash = _hash(data);
    if (previous?.read<String>('hash') == hash) {
      return LearningSyncRow(
        table,
        key,
        data,
        previous!.read<int>('changed_at'),
        hash,
      );
    }
    final sourceTime =
        data['updated_at'] ?? data['created_at'] ?? data['added_at'];
    // Drift timestamps are seconds; the UI document table stores milliseconds.
    final existingTime = sourceTime is num
        ? sourceTime.toInt() * (table == 'learning_sync_documents' ? 1 : 1000)
        : DateTime.tryParse('$sourceTime')?.millisecondsSinceEpoch ?? 0;
    final changedAt = previous == null
        ? (existingTime > 0 ? existingTime : clock().millisecondsSinceEpoch)
        : [
            existingTime,
            clock().millisecondsSinceEpoch,
            previous.read<int>('changed_at') + 1,
          ].reduce((a, b) => a > b ? a : b);
    final row = LearningSyncRow(table, key, data, changedAt, hash);
    await _remember(row);
    return row;
  }

  Future<void> _remember(LearningSyncRow row) => db.customStatement(
    'INSERT INTO learning_sync_versions(kind,row_key,hash,changed_at) VALUES(?,?,?,?) ON CONFLICT(kind,row_key) DO UPDATE SET hash=excluded.hash,changed_at=excluded.changed_at',
    [row.table, row.key, row.hash, row.changedAt],
  );

  LearningSyncRow _preserveFinished(
    LearningSyncRow a,
    LearningSyncRow b,
    LearningSyncRow selected,
  ) {
    if (selected.table != 'learning_sync_documents' ||
        !(selected.data['store'] as String).startsWith('reading_progress_') ||
        a.data['deleted'] != 0 ||
        b.data['deleted'] != 0) {
      return selected;
    }
    final left = jsonDecode(a.data['payload'] as String) as Map;
    final right = jsonDecode(b.data['payload'] as String) as Map;
    final value = Map<String, Object?>.from(
      jsonDecode(selected.data['payload'] as String) as Map,
    );
    if (value['finished'] == true ||
        (left['finished'] != true && right['finished'] != true)) {
      return selected;
    }
    value['finished'] = true;
    final at =
        [
          a.changedAt,
          b.changedAt,
          clock().millisecondsSinceEpoch,
        ].reduce((x, y) => x > y ? x : y) +
        1;
    final data = {
      ...selected.data,
      'payload': syncCanonicalJson(value),
      'updated_at': at,
    };
    return LearningSyncRow(selected.table, selected.key, data, at, _hash(data));
  }

  Future<void> _uploaded(LearningSyncRow row) => db.customStatement(
    'INSERT INTO learning_sync_uploaded(kind,row_key,hash) VALUES(?,?,?) ON CONFLICT(kind,row_key) DO UPDATE SET hash=excluded.hash',
    [row.table, row.key, row.hash],
  );

  Future<bool> _sync() async {
    await _bind();
    _check();
    final snapshot = await db.transaction(_snapshot);
    final uploaded = {
      for (final row
          in await db
              .customSelect('SELECT * FROM learning_sync_uploaded')
              .get())
        '${row.read<String>('kind')}\u001f${row.read<String>('row_key')}': row
            .read<String>('hash'),
    };
    final local = snapshot
        .where((r) => uploaded['${r.table}\u001f${r.key}'] != r.hash)
        .toList();
    for (var i = 0; i < local.length; i += 100) {
      _check();
      final batch = local.sublist(i, (i + 100).clamp(0, local.length));
      await gateway.push(batch);
      _check();
      await db.transaction(() async {
        for (final row in batch) {
          await _uploaded(row);
        }
      });
    }
    final remote = <LearningSyncRow>[];
    String? after;
    while (true) {
      _check();
      final page = await gateway.pull(after: after);
      _check();
      remote.addAll(page);
      if (page.length < 500) break;
      final last = page.last;
      final next = '${last.table}\u001f${last.key}';
      if (next == after) throw const FormatException('Ungültige Sync-Seite.');
      after = next;
    }
    var changed = false;
    await db.transaction(() async {
      _check();
      // Read again: changes made during the network request must not be lost.
      final latest = {
        for (final r in await _snapshot()) '${r.table}\u001f${r.key}': r,
      };
      for (final table in learningSyncTables.keys) {
        final columns =
            (await db.customSelect('PRAGMA table_info("$table")').get())
                .map((r) => r.read<String>('name'))
                .toSet();
        for (final incoming in remote.where((r) => r.table == table)) {
          _check();
          if (_hash(incoming.data) != incoming.hash ||
              !columns.containsAll(incoming.data.keys) ||
              incoming.data.keys.length != columns.length) {
            throw const FormatException('Inkompatibler Lernstand.');
          }
          final key = syncCanonicalJson([
            for (final field in learningSyncTables[table]!)
              incoming.data[field],
          ]);
          if (key != incoming.key) {
            throw const FormatException('Ungültige Lernstand-ID.');
          }
          final current = latest['$table\u001f$key'];
          if (current?.hash == incoming.hash) continue;
          var selected = incoming;
          if (current != null) {
            if (!_mutable.contains(table)) {
              throw const FormatException(
                'Widersprüchliche unveränderliche Lerndaten.',
              );
            }
            if (current.changedAt > incoming.changedAt ||
                (current.changedAt == incoming.changedAt &&
                    current.hash.compareTo(incoming.hash) >= 0)) {
              selected = current;
            }
            selected = _preserveFinished(current, incoming, selected);
            if (selected.hash == current.hash) continue;
          }
          final names = selected.data.keys.toList();
          final conflict = learningSyncTables[table]!
              .map((k) => '"$k"')
              .join(',');
          final update = names
              .where((k) => !learningSyncTables[table]!.contains(k))
              .map((k) => '"$k"=excluded."$k"')
              .join(',');
          final action = _mutable.contains(table)
              ? 'DO UPDATE SET $update'
              : 'DO NOTHING';
          await db.customStatement(
            'INSERT INTO "$table" (${names.map((k) => '"$k"').join(',')}) VALUES (${List.filled(names.length, '?').join(',')}) ON CONFLICT($conflict) $action',
            [for (final k in names) selected.data[k]],
          );
          await _remember(selected);
          if (selected.hash == incoming.hash) await _uploaded(incoming);
          changed = true;
        }
      }
      _check();
    });
    // customStatement bypasses Drift's automatic invalidation.
    if (changed) {
      db.notifyUpdates({
        for (final table in db.allTables) TableUpdate(table.actualTableName),
      });
    }
    return changed;
  }
}
