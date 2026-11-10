import 'dart:convert';

import 'package:drift/drift.dart';

import '../../presentation/providers/reading_providers.dart';
import '../user/user_database.dart';
import 'learning_sync.dart';

/// Per-entry reader/import documents in the same account-bound SQLite database.
/// A deleted entry remains a tombstone, so another device cannot resurrect it.
/// [legacy] is read once when upgrading an existing mobile installation.
class SyncJsonStore implements JsonStore {
  SyncJsonStore(
    this.database,
    this.name, {
    this.list = false,
    this.legacy,
    this.isCurrent,
  });
  final Future<UserDatabase> database;
  final String name;
  final bool list;
  final JsonStore? legacy;
  final bool Function()? isCurrent;
  void _check() {
    if (isCurrent != null && !isCurrent!()) {
      throw StateError('Lernkonto hat sich geändert.');
    }
  }

  Future<void>? _ready;
  final _knownKeys = <String>{};

  Map<String, Object?> _entries(Object? value) {
    if (list) {
      if (value is! List) return {};
      return {
        for (final item in value)
          if (item is Map && item['id'] is String) item['id'] as String: item,
      };
    }
    return value is Map ? Map<String, Object?>.from(value) : {};
  }

  Future<void> _initialize() => _ready ??= () async {
    _check();
    final db = await database;
    _check();
    await prepareLearningSync(db);
    final imported = await db
        .customSelect(
          'SELECT store FROM learning_sync_document_imports WHERE store=?',
          variables: [Variable(name)],
        )
        .getSingleOrNull();
    if (imported != null) return;
    final old = await legacy?.read();
    _check();
    await db.transaction(() async {
      _check();
      // INSERT OR IGNORE preserves any account data already downloaded.
      for (final entry in _entries(old).entries) {
        await _put(db, entry.key, entry.value, ignore: true);
      }
      await db.customStatement(
        'INSERT OR IGNORE INTO learning_sync_document_imports(store) VALUES(?)',
        [name],
      );
      _check();
    });
  }();

  @override
  Future<Object?> read() async {
    try {
      await _initialize();
      _check();
      final db = await database;
      _check();
      final rows = await db
          .customSelect(
            'SELECT entry_key,payload FROM learning_sync_documents WHERE store=? AND deleted=0 ORDER BY updated_at DESC,id',
            variables: [Variable(name)],
          )
          .get();
      final values = {
        for (final row in rows)
          row.read<String>('entry_key'): jsonDecode(
            row.read<String>('payload'),
          ),
      };
      _check();
      _knownKeys
        ..clear()
        ..addAll(values.keys);
      return list ? values.values.toList() : values;
    } catch (_) {
      // A disposed notifier may still await its initial read. The fenced
      // transaction has already rolled back; do not create an unhandled error.
      if (isCurrent != null && !isCurrent!()) return null;
      rethrow;
    }
  }

  Future<void> _put(
    UserDatabase db,
    String key,
    Object? value, {
    bool ignore = false,
  }) async {
    final map = value is Map ? value : null;
    final at =
        DateTime.tryParse('${map?['updatedAt'] ?? map?['createdAt']}')
            ?.millisecondsSinceEpoch ??
        DateTime.now().millisecondsSinceEpoch;
    await db.customStatement(
      'INSERT ${ignore ? 'OR IGNORE' : ''} INTO learning_sync_documents(id,store,entry_key,payload,updated_at,deleted) VALUES(?,?,?,?,?,0) ${ignore ? '' : 'ON CONFLICT(id) DO UPDATE SET payload=excluded.payload,updated_at=excluded.updated_at,deleted=0'}',
      [
        syncCanonicalJson([name, key]),
        name,
        key,
        syncCanonicalJson(value),
        at,
      ],
    );
  }

  @override
  Future<void> write(Object? json) async {
    await _initialize();
    _check();
    final db = await database;
    _check();
    final entries = _entries(json);
    await db.transaction(() async {
      _check();
      final before = await db
          .customSelect(
            'SELECT entry_key,payload,deleted FROM learning_sync_documents WHERE store=?',
            variables: [Variable(name)],
          )
          .get();
      final old = {for (final r in before) r.read<String>('entry_key'): r};
      for (final entry in entries.entries) {
        final previous = old[entry.key];
        if (previous?.read<int>('deleted') == 0 &&
            previous?.read<String>('payload') ==
                syncCanonicalJson(entry.value)) {
          continue;
        }
        await _put(db, entry.key, entry.value);
      }
      for (final row in before) {
        final key = row.read<String>('entry_key');
        if (!_knownKeys.contains(key) ||
            entries.containsKey(key) ||
            row.read<int>('deleted') != 0) {
          continue;
        }
        await db.customStatement(
          "UPDATE learning_sync_documents SET deleted=1,payload='null',updated_at=? WHERE id=?",
          [
            DateTime.now().millisecondsSinceEpoch,
            syncCanonicalJson([name, key]),
          ],
        );
      }
      _check();
    });
    _check();
    _knownKeys
      ..clear()
      ..addAll(entries.keys);
  }
}
