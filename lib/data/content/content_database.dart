import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../domain/content.dart';

part 'content_database.g.dart';

// No Flutter imports: tool/stage_content_pack.dart shares the checks below.

/// The content schema version this app reads (docs/content-schema.md).
const supportedContentSchemaVersion = 2;
const supportedContentSchemaVersions = {1, 2};

/// Tables and columns the app reads; anything missing is incompatible.
const requiredContentColumns = <String, List<String>>{
  'languages': ['code', 'gloss_lang'],
  'content_releases': ['id', 'lang', 'version', 'schema_version', 'notes'],
  'decks': [
    'id',
    'lang',
    'slug',
    'title_de',
    'description_de',
    'cefr_band',
    'sort',
    'removed_in',
  ],
  'deck_cards': ['id', 'deck_id', 'card_id', 'position', 'removed_in'],
  'lemmas': ['id', 'lang', 'lemma', 'pos', 'removed_in'],
  'senses': ['id', 'lemma_id', 'removed_in'],
  'cards': [
    'id',
    'lang',
    'form',
    'sense_id',
    'form_norm',
    'lemma_id',
    'pos',
    'form_kind',
    'form_label_de',
    'translation_de',
    'cefr_band',
    'removed_in',
  ],
  'sentences': ['id', 'lang', 'text', 'translation_de', 'removed_in'],
  'card_sentences': [
    'id',
    'card_id',
    'sentence_id',
    'position',
    'gap_start',
    'gap_end',
    'valid_alternatives',
    'removed_in',
  ],
  'dictionary_forms': ['id', 'lang', 'form_norm', 'sense_id', 'removed_in'],
};

/// Checks an opened pack: SQLite integrity, required tables and columns,
/// exactly one release row of [lang] with [supportedContentSchemaVersion],
/// and the language row. Throws [ContentUnavailable].
ContentInfo validateContentSchema(Database db, {required String lang}) {
  try {
    final check = db.select('PRAGMA quick_check');
    if (check.length != 1 || check.first.values.first != 'ok') {
      throw ContentUnavailable(
        ContentUnavailableReason.corrupt,
        'Integritätsprüfung fehlgeschlagen: '
        '${check.map((r) => r.values.first).take(3).join('; ')}',
      );
    }
    for (final MapEntry(key: table, value: columns)
        in requiredContentColumns.entries) {
      final present = {
        for (final row in db.select('PRAGMA table_info("$table")'))
          row['name'] as String,
      };
      if (present.isEmpty) {
        throw ContentUnavailable(
          ContentUnavailableReason.incompatible,
          'Tabelle $table fehlt',
        );
      }
      final missing = columns.where((c) => !present.contains(c)).toList();
      if (missing.isNotEmpty) {
        throw ContentUnavailable(
          ContentUnavailableReason.incompatible,
          'Spalten fehlen in $table: ${missing.join(', ')}',
        );
      }
    }
    final releases = db.select(
      'SELECT lang, version, schema_version, notes FROM content_releases',
    );
    if (releases.length != 1) {
      throw ContentUnavailable(
        ContentUnavailableReason.incompatible,
        'erwartet genau eine Zeile in content_releases, gefunden '
        '${releases.length}',
      );
    }
    final release = releases.first;
    if (release['lang'] != lang) {
      throw ContentUnavailable(
        ContentUnavailableReason.incompatible,
        'Sprache ${release['lang']}, erwartet $lang',
      );
    }
    if (!supportedContentSchemaVersions.contains(release['schema_version'])) {
      throw ContentUnavailable(
        ContentUnavailableReason.incompatible,
        'Schema-Version ${release['schema_version']}, erwartet '
        '$supportedContentSchemaVersion',
      );
    }
    if (release['schema_version'] == 2) validateSingleSentenceContent(db);
    final languages = db.select('SELECT code FROM languages WHERE code = ?', [
      lang,
    ]);
    if (languages.isEmpty) {
      throw ContentUnavailable(
        ContentUnavailableReason.incompatible,
        'Sprache $lang fehlt in languages',
      );
    }
    final version = release['version'];
    if (version is! String || version.isEmpty) {
      throw const ContentUnavailable(
        ContentUnavailableReason.incompatible,
        'content_releases.version fehlt',
      );
    }
    return ContentInfo(
      lang: lang,
      version: version,
      schemaVersion: release['schema_version'] as int,
      notes: release['notes'] as String?,
    );
  } on SqliteException catch (e) {
    throw ContentUnavailable(
      ContentUnavailableReason.corrupt,
      'nicht als Inhaltsdatenbank lesbar: ${e.message}',
    );
  }
}

/// Schema-2 ownership and active links, checked before installation or use.
void validateSingleSentenceContent(Database db) {
  void reject(String message) => throw ContentUnavailable(
    ContentUnavailableReason.incompatible,
    'Schema 2: $message',
  );
  for (final table in ['deck_words', 'word_aliases']) {
    if (db.select(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [table],
    ).isEmpty) {
      reject('Pflichttabelle $table fehlt');
    }
  }
  final words = db.select('SELECT * FROM deck_words WHERE removed_in IS NULL');
  final aliases = db.select(
    'SELECT id, lang, form_norm, word_id, removed_in FROM word_aliases',
  );
  final keys = <String>{};
  final primaries = <String>{};
  final positions = <String, List<int>>{};
  for (final w in words) {
    if (contentFormNorm(w['form_norm'] as String) != w['form_norm']) {
      reject('nicht normalisierter Wortbesitz');
    }
    if (!keys.add('${w['lang']}/${w['form_norm']}')) {
      reject('doppelter Wortbesitz ${w['form_norm']}');
    }
    final card = db.select(
      'SELECT * FROM cards WHERE id=? AND removed_in IS NULL',
      [w['primary_card_id']],
    );
    if (card.length != 1 ||
        card.single['lang'] != w['lang'] ||
        card.single['form_norm'] != w['form_norm']) {
      reject('ungültige Primärkarte ${w['primary_card_id']}');
    }
    if (db.select(
          'SELECT id FROM decks WHERE id=? AND lang=? AND removed_in IS NULL',
          [w['deck_id'], w['lang']],
        ).length !=
        1) {
      reject('Eigentümerstapel fehlt');
    }
    primaries.add('${w['deck_id']}/${w['primary_card_id']}/${w['position']}');
    (positions[w['deck_id'] as String] ??= []).add(w['position'] as int);
  }
  for (final pos in positions.values) {
    pos.sort();
    if (pos.join(',') != List.generate(pos.length, (i) => i + 1).join(',')) {
      reject('Stapelpositionen nicht 1..n');
    }
  }
  final aliasKeys = {...keys};
  for (final a in aliases.where((r) => r['removed_in'] == null)) {
    if (contentFormNorm(a['form_norm'] as String) != a['form_norm'] ||
        !aliasKeys.add('${a['lang']}/${a['form_norm']}') ||
        !words.any((w) => w['id'] == a['word_id'] && w['lang'] == a['lang'])) {
      reject('Alias ohne eindeutigen Wortbesitz ${a['form_norm']}');
    }
  }
  final membership = db.select(
    'SELECT * FROM deck_cards WHERE removed_in IS NULL',
  );
  if (membership.length != primaries.length ||
      membership.any(
        (r) => !primaries.contains(
          '${r['deck_id']}/${r['card_id']}/${r['position']}',
        ),
      )) {
    reject('Stapelzuordnung entspricht nicht Primärwörtern');
  }
  for (final c in db.select('SELECT * FROM cards WHERE removed_in IS NULL')) {
    if (contentFormNorm(c['form'] as String) != c['form_norm'] ||
        (c['form'] as String).trim() != c['form']) {
      reject('ungültige Wortnormalisierung');
    }
    if (!keys.contains('${c['lang']}/${c['form_norm']}')) {
      reject('Wort ohne Eigentümer ${c['form']}');
    }
    final links = db.select(
      'SELECT cs.position, s.removed_in FROM card_sentences cs JOIN sentences s ON s.id=cs.sentence_id WHERE cs.card_id=? AND cs.removed_in IS NULL',
      [c['id']],
    );
    if (links.length != 1 ||
        links.single['position'] != 1 ||
        links.single['removed_in'] != null) {
      reject('Karte ${c['id']} braucht genau einen aktiven Satz (Position 1)');
    }
  }
}

/// `content.manifest.json` next to the staged pack (written by
/// tool/stage_content_pack.dart): what the asset is and its checksum.
class ContentManifest {
  const ContentManifest({
    required this.lang,
    required this.version,
    required this.schemaVersion,
    required this.sha256,
    required this.sizeBytes,
    required this.internalTestPack,
    this.notes,
    this.source = const {},
  });

  final String lang;
  final String version;
  final int schemaVersion;

  /// Lower-case hex SHA-256 of content.sqlite.
  final String sha256;
  final int sizeBytes;
  final bool internalTestPack;
  final String? notes;
  final Map<String, Object?> source;

  static const format = 1;

  /// Parses and checks a manifest; a malformed one is corrupt, another
  /// language or schema incompatible.
  factory ContentManifest.parse(String text, {required String lang}) {
    Object? json;
    try {
      json = jsonDecode(text);
    } on FormatException catch (e) {
      throw ContentUnavailable(
        ContentUnavailableReason.corrupt,
        'Manifest ist kein JSON: ${e.message}',
      );
    }
    if (json is! Map<String, Object?> ||
        json['format'] != format ||
        json['lang'] is! String ||
        json['version'] is! String ||
        json['schema_version'] is! int ||
        json['sha256'] is! String ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(json['sha256'] as String) ||
        json['size_bytes'] is! int ||
        json['internal_test_pack'] is! bool) {
      throw const ContentUnavailable(
        ContentUnavailableReason.corrupt,
        'Manifest unvollständig oder fehlerhaft',
      );
    }
    final manifest = ContentManifest(
      lang: json['lang'] as String,
      version: json['version'] as String,
      schemaVersion: json['schema_version'] as int,
      sha256: json['sha256'] as String,
      sizeBytes: json['size_bytes'] as int,
      internalTestPack: json['internal_test_pack'] as bool,
      notes: json['notes'] as String?,
      source: (json['source'] as Map<String, Object?>?) ?? const {},
    );
    if (manifest.lang != lang) {
      throw ContentUnavailable(
        ContentUnavailableReason.incompatible,
        'Manifest für Sprache ${manifest.lang}, erwartet $lang',
      );
    }
    if (!supportedContentSchemaVersions.contains(manifest.schemaVersion)) {
      throw ContentUnavailable(
        ContentUnavailableReason.incompatible,
        'Manifest-Schema ${manifest.schemaVersion}, erwartet '
        '$supportedContentSchemaVersion',
      );
    }
    return manifest;
  }

  /// Stable JSON (fixed key order, trailing newline): staging the same pack
  /// twice writes the same bytes.
  String toJson() =>
      '${const JsonEncoder.withIndent('  ').convert({'format': format, 'lang': lang, 'version': version, 'schema_version': schemaVersion, 'sha256': sha256, 'size_bytes': sizeBytes, 'internal_test_pack': internalTestPack, 'notes': notes, 'source': source})}\n';
}

/// The read-only content.sqlite of one language (Drift, no tables of its
/// own: only custom queries). Opened with `OpenMode.readOnly` and
/// `PRAGMA query_only`; Drift runs no migrations on it.
@DriftDatabase()
class ContentDatabase extends _$ContentDatabase {
  ContentDatabase._(Database raw, this.info)
    : _raw = raw,
      super(NativeDatabase.opened(raw, enableMigrations: false));

  final Database _raw;
  final ContentInfo info;

  /// Drift closes the connection only if it ever opened it; the raw handle
  /// is closed here in any case (idempotent), so no file stays locked.
  @override
  Future<void> close() async {
    await super.close();
    _raw.close();
  }

  @override
  int get schemaVersion => supportedContentSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (_) async =>
        throw StateError('content.sqlite is never created by the app'),
    onUpgrade: (_, _, _) async =>
        throw StateError('content.sqlite is never migrated by the app'),
  );

  /// Opens [file] read-only and validates it ([validateContentSchema]).
  static ContentDatabase open(File file, {required String lang}) {
    if (!file.existsSync()) {
      throw ContentUnavailable(
        ContentUnavailableReason.missing,
        'Kein Inhaltspaket installiert (${file.path})',
      );
    }
    final Database raw;
    try {
      raw = sqlite3.open(file.path, mode: OpenMode.readOnly);
    } on SqliteException catch (e) {
      throw ContentUnavailable(
        ContentUnavailableReason.corrupt,
        'Inhaltspaket lässt sich nicht öffnen: ${e.message}',
      );
    }
    try {
      raw.execute('PRAGMA query_only = ON');
      final info = validateContentSchema(raw, lang: lang);
      return ContentDatabase._(raw, info);
    } catch (_) {
      raw.close();
      rethrow;
    }
  }
}
