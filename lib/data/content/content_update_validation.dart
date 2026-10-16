import 'dart:convert';
import 'dart:io';

import 'package:sqlite3/sqlite3.dart';
import 'package:crypto/crypto.dart';

import 'content_database.dart';
import 'content_release_client.dart';
import 'context_revision_validation.dart';

const _tables = {
  'languages',
  'lemmas',
  'senses',
  'cards',
  'dictionary_forms',
  'decks',
  'deck_cards',
  'deck_words',
  'word_aliases',
  'sentences',
  'sentence_tokens',
  'card_sentences',
  'stories',
  'story_sentences',
  'exercises',
  'grammar_rules',
  'audio_assets',
  'content_releases',
  'lexical_targets',
  'card_lexical_targets',
  'form_targets',
  'deck_practice_targets',
  'story_context_corrections',
};
const _jsonColumns = {
  'cards': {'learning'},
  'sentences': {'qa_report', 'origins'},
  'card_sentences': {'accepted', 'valid_alternatives'},
  'sentence_tokens': {'context_snapshot'},
  'exercises': {'payload'},
  'grammar_rules': {'sections'},
  'story_context_corrections': {'previous_context', 'next_context'},
};
Map<String, dynamic> _row(String table, Row row) => {
  for (final key in row.keys)
    if (key != 'removed_in' && key != 'replaced_by')
      key: _jsonColumns[table]?.contains(key) == true && row[key] is String
          ? jsonDecode(row[key] as String)
          : table == 'cards' && key == 'is_multiword'
          ? row[key] == 1
          : row[key],
};

// Legacy inventories hash the export row before SQLite fills omitted nullable
// columns with NULL. Accept only omission of actual SQL NULLs in pass-through
// tables; non-null values and all schema/row/identity checks remain mandatory.
bool _matchesInventory(
  String table,
  Map<String, dynamic> row,
  Object? expected,
) {
  if (contextCanonicalHash(row) == expected) return true;
  if (!{
    'stories',
    'story_sentences',
    'exercises',
    'grammar_rules',
    'audio_assets',
  }.contains(table)) {
    return false;
  }
  final optional = row.keys.where((k) => row[k] == null).toList();
  if (optional.length > 10) return false;
  for (var mask = 1; mask < (1 << optional.length); mask++) {
    final candidate = Map<String, dynamic>.from(row);
    for (var i = 0; i < optional.length; i++) {
      if (mask & (1 << i) != 0) candidate.remove(optional[i]);
    }
    if (contextCanonicalHash(candidate) == expected) return true;
  }
  return false;
}

/// Executed in an isolate. Traverses every row of every actual table, including
/// retired identities. No queries or executable schema supplied by the pack run.
void validateDownloadedContent(
  String path,
  Map<String, dynamic> offerJson,
  String? previousPath,
) {
  final offer = ReleaseOffer.parse(offerJson, offerJson['manifest']['lang']);
  final inventory = jsonDecode(
    File('${File(path).parent.path}/history_inventory.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  if (contextCanonicalHash(inventory) !=
          offer.manifest['history_inventory_sha256'] ||
      inventory['lang'] != offer.lang) {
    throw const FormatException('Historieninventar passt nicht.');
  }
  final db = sqlite3.open(path, mode: OpenMode.readOnly);
  Database? old;
  try {
    db.execute('PRAGMA query_only=ON');
    final schema = db.select(
      "SELECT type,name FROM sqlite_master WHERE name NOT LIKE 'sqlite_%'",
    );
    final names = <String>{};
    for (final row in schema) {
      if (row['type'] == 'table' && _tables.contains(row['name'])) {
        names.add(row['name'] as String);
        continue;
      }
      if (row['type'] == 'index' &&
          {
            'idx_sentence_tokens_active_sentence_idx',
            'idx_dictionary_forms_active_lookup',
          }.contains(row['name'])) {
        continue;
      }
      throw const FormatException('Unerwartetes ausführbares Inhaltsobjekt.');
    }
    if (names.length != _tables.length || !names.containsAll(_tables)) {
      throw const FormatException('Unvollständiges Inhaltsschema.');
    }
    final info = validateContentSchema(db, lang: offer.lang);
    if (info.version != offer.manifest['version'] || info.schemaVersion != 5) {
      throw const FormatException('Innere Releaseversion weicht ab.');
    }
    final tables = inventory['tables'] as Map<String, dynamic>;
    final expected = names.difference({'content_releases'});
    if (tables.length != expected.length || !expected.containsAll(tables.keys)) {
      throw const FormatException('Inventartabellen weichen ab.');
    }
    for (final table in expected) {
      final rows = db.select('SELECT * FROM "$table"');
      final entries = tables[table] as Map<String, dynamic>;
      if (rows.length != entries.length) {
        throw FormatException('Inventaranzahl $table weicht ab.');
      }
      for (final row in rows) {
        final id = row[table == 'languages' ? 'code' : 'id'];
        if (!_matchesInventory(table, _row(table, row), entries[id])) {
          throw FormatException('Inventarinhalt $table weicht ab.');
        }
      }
    }
    if (previousPath == null) return;
    final priorInventory = File(
      '${File(previousPath).parent.path}/history_inventory.json',
    );
    final priorOfferFile = File(
      '${File(previousPath).parent.path}/release.json',
    );
    Map<String, dynamic>? prior;
    if (priorInventory.existsSync() && priorOfferFile.existsSync()) {
      final previous = ReleaseOffer.parse(
        jsonDecode(priorOfferFile.readAsStringSync()) as Map<String, dynamic>,
        offer.lang,
      );
      final bytes = priorInventory.readAsBytesSync();
      prior = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      if (contextCanonicalHash(prior) !=
              previous.manifest['history_inventory_sha256'] ||
          sha256.convert(bytes).toString() !=
              previous.objects['history_inventory.json']['sha256']) {
        throw const FormatException('Installierte Historienbelege beschädigt.');
      }
      for (final table in (prior['tables'] as Map).keys) {
        final before = prior['tables'][table] as Map;
        final after = tables[table] as Map?;
        if (after == null || !before.keys.every(after.containsKey)) {
          throw const FormatException('Historische Identitäten fehlen.');
        }
        if ({
          'sentences',
          'sentence_tokens',
          'card_sentences',
          'stories',
          'story_sentences',
          'story_context_corrections',
        }.contains(table)) {
          for (final key in before.keys) {
            if (before[key] != after[key]) {
              throw const FormatException(
                'Unveränderliche Historie wurde verändert.',
              );
            }
          }
        }
      }
      final snapshots = (inventory['story_source_snapshots'] as List)
          .map(contextCanonicalHash)
          .toSet();
      for (final source in prior['story_source_snapshots'] as List) {
        if (!snapshots.contains(contextCanonicalHash(source))) {
          throw const FormatException('Storyhistorie fehlt.');
        }
      }
    }
    try {
      old = sqlite3.open(previousPath, mode: OpenMode.readOnly);
      old.execute('PRAGMA query_only=ON');
      validateContentSchema(old, lang: offer.lang);
    } catch (_) {
      // A forward repair can use the previously authenticated full inventory
      // when the old SQLite itself is unreadable. Never use an unbound sidecar.
      if (prior != null) return;
      rethrow;
    }
    for (final tableRow in old.select(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
    )) {
      final table = tableRow['name'] as String;
      if (table == 'content_releases') continue;
      if (!expected.contains(table)) {
        throw FormatException('Historientabelle $table fehlt.');
      }
      final key = table == 'languages' ? 'code' : 'id';
      final current = {
        for (final row in db.select('SELECT * FROM "$table"')) row[key]: row,
      };
      for (final before in old.select('SELECT * FROM "$table"')) {
        final after = current[before[key]];
        if (after == null) {
          throw FormatException('Historische Identität in $table fehlt.');
        }
        final immutable = {
          'sentences',
          'sentence_tokens',
          'card_sentences',
          'stories',
          'story_sentences',
          'story_context_corrections',
        }.contains(table);
        final fields = immutable
            ? _row(table, before).keys
            : table == 'cards'
            ? [
                'lang',
                'form',
                'form_norm',
                'sense_id',
                'lemma_id',
                'identity_function',
              ]
            : <String>[];
        final a = _row(table, before), b = _row(table, after);
        for (final column in fields) {
          if (a.containsKey(column) &&
              contextCanonicalHash(a[column]) !=
                  contextCanonicalHash(b[column])) {
            throw FormatException('Historischer Inhalt in $table verändert.');
          }
        }
      }
    }
  } finally {
    old?.close();
    db.close();
  }
}
