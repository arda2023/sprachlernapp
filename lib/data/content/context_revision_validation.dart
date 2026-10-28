import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:unorm_dart/unorm_dart.dart' as unicode;

import '../../domain/content.dart';
import '../../domain/language_profile.dart';
import '../../domain/story_learning.dart';

Object? _sorted(Object? value) {
  if (value is Map) {
    final keys = value.keys.cast<String>().toList()..sort();
    return {for (final key in keys) key: _sorted(value[key])};
  }
  if (value is List) return value.map(_sorted).toList();
  return value;
}

String contextCanonicalHash(Object? value) =>
    sha256.convert(utf8.encode(jsonEncode(_sorted(value)))).toString();

String _stableId(List<String> values) => sha256
    .convert(utf8.encode(values.map(unicode.nfc).join('\u001f')))
    .toString()
    .substring(0, 32);

Map<String, Object?> encodeStoryCandidate(StoryLearningCandidate candidate) {
  Map<String, Object?> token(StoryToken t) => {
    'index': t.index,
    'start': t.start,
    'end': t.end,
    'surface': t.surface,
    'card_id': t.cardId,
    'lemma_id': t.lemmaId,
    'lemma': t.lemma,
    'pos': t.pos,
    'sense_id': t.senseId,
    'sense_key': t.senseKey,
    'gloss': t.gloss,
    'definition': t.definition,
    'function': t.function,
    'lexical_id': t.lexicalId,
    'context_approved': t.contextApproved,
  };
  Map<String, Object?> sentence(StorySentence s) => {
    'id': s.id,
    'text': s.text,
    'translation': s.translation,
    'paragraph': s.paragraph,
    'tokens': s.tokens.map(token).toList(),
  };
  return {
    'lang': candidate.lang,
    'story_id': candidate.storyId,
    'revision': candidate.revision,
    'sentence': sentence(candidate.sentence),
    'token_index': candidate.token.index,
    'practice_context': candidate.practiceContext == null
        ? null
        : {
            'sentence': sentence(candidate.practiceContext!.sentence),
            'token_index': candidate.practiceContext!.token.index,
          },
    'other_forms': candidate.otherForms.toList()..sort(),
    'identity_key': candidate.identity.key,
    'source_fingerprint': candidate.sourceFingerprint,
    'source_key': learningHash([
      candidate.storyId,
      candidate.sentence.id,
      candidate.token.index,
      candidate.identity.key,
    ]),
  };
}

StoryLearningCandidate decodeStoryCandidate(Map<String, dynamic> data) {
  StorySentence sentence(Map<String, dynamic> s) => StorySentence(
    id: s['id'] as String,
    text: s['text'] as String,
    translation: s['translation'] as String,
    paragraph: s['paragraph'] as int,
    tokens: [
      for (final t in s['tokens'] as List)
        StoryToken(
          index: t['index'] as int,
          start: t['start'] as int,
          end: t['end'] as int,
          surface: t['surface'] as String,
          cardId: t['card_id'] as String?,
          lemmaId: t['lemma_id'] as String?,
          lemma: t['lemma'] as String?,
          pos: t['pos'] as String?,
          senseId: t['sense_id'] as String?,
          senseKey: t['sense_key'] as String?,
          gloss: t['gloss'] as String?,
          definition: t['definition'] as String?,
          formFunction: t['function'] as String?,
          lexicalTargetId: t['lexical_id'] as String?,
          contextApproved: t['context_approved'] == true,
        ),
    ],
  );
  final source = sentence(data['sentence'] as Map<String, dynamic>);
  final practice = data['practice_context'] as Map<String, dynamic>?;
  final exercise = practice == null
      ? null
      : sentence(practice['sentence'] as Map<String, dynamic>);
  final candidate = StoryLearningCandidate(
    storyId: data['story_id'] as String,
    revision: data['revision'] as String,
    lang: data['lang'] as String,
    sentence: source,
    token: source.tokens.singleWhere((t) => t.index == data['token_index']),
    practiceContext: exercise == null
        ? null
        : StoryPracticeContext(
            exercise,
            exercise.tokens.singleWhere(
              (t) => t.index == practice!['token_index'],
            ),
          ),
    otherForms: (data['other_forms'] as List).cast<String>().toSet(),
  );
  candidate.validate();
  if (candidate.identity.key != data['identity_key'] ||
      candidate.sourceFingerprint != data['source_fingerprint'] ||
      encodeStoryCandidate(candidate)['source_key'] != data['source_key']) {
    throw const ContentUnavailable(
      ContentUnavailableReason.incompatible,
      'Storysnapshot passt nicht zum Fingerprint.',
    );
  }
  return candidate;
}

/// Validates immutable context identities; ordinary form/ownership checks remain shared.
void validateContextRevisions(Database db, {required String lang}) {
  Never reject(String message) => throw ContentUnavailable(
    ContentUnavailableReason.incompatible,
    'Schema 5: $message',
  );
  void require(bool ok, String message) {
    if (!ok) reject(message);
  }

  final profiles = ContentLanguageProfile.supportedForLanguage(lang);
  require(profiles.isNotEmpty, 'Sprachprofil nicht unterstützt.');
  const required = {
    'sentences': ['root_sentence_id', 'revision_sha256'],
    'sentence_tokens': ['context_gloss_de', 'context_snapshot'],
    'story_context_corrections': [
      'id',
      'lang',
      'identity_key',
      'source_key',
      'previous_fingerprint',
      'next_fingerprint',
      'previous_revision',
      'next_revision',
      'previous_context',
      'next_context',
      'introduced_in',
      'reason',
    ],
  };
  for (final entry in required.entries) {
    final names = db
        .select('PRAGMA table_info(${entry.key})')
        .map((r) => r['name'])
        .toSet();
    require(
      names.containsAll(entry.value),
      'Kontextspalten fehlen: ${entry.key}',
    );
  }
  final tokens = <String, List<Map<String, Object?>>>{};
  for (final row in db.select(
    'SELECT * FROM sentence_tokens ORDER BY sentence_id,idx',
  )) {
    final t = Map<String, Object?>.from(row);
    final snapshot = jsonDecode(t['context_snapshot'] as String? ?? 'null');
    require(snapshot is Map<String, dynamic>, 'Kontextsnapshot fehlt.');
    t['context_snapshot'] = snapshot;
    if (RegExp(r'\p{L}', unicode: true).hasMatch(t['surface'] as String) &&
        snapshot['legacy'] != true) {
      require(
        t['context_gloss_de'] is String &&
            (t['context_gloss_de'] as String).trim().isNotEmpty,
        'Kontextübersetzung fehlt.',
      );
    }
    (tokens[t['sentence_id'] as String] ??= []).add(t);
  }
  final links = <String, List<Map<String, Object?>>>{};
  for (final row in db.select(
    'SELECT * FROM card_sentences ORDER BY sentence_id,card_id',
  )) {
    final link = Map<String, Object?>.from(row);
    for (final k in ['accepted', 'valid_alternatives']) {
      link[k] = link[k] == null ? null : jsonDecode(link[k] as String);
    }
    (links[link['sentence_id'] as String] ??= []).add(link);
  }
  const tokenFields = [
    'idx',
    'start_pos',
    'end_pos',
    'surface',
    'lemma_id',
    'sense_id',
    'card_id',
    'form_target_id',
    'context_gloss_de',
    'context_snapshot',
  ];
  const linkFields = [
    'card_id',
    'position',
    'gap_start',
    'gap_end',
    'accepted',
    'valid_alternatives',
  ];
  for (final s in db.select('SELECT * FROM sentences')) {
    final id = s['id'] as String;
    final revision = s['revision_sha256'];
    if (revision == null) {
      require(
        s['root_sentence_id'] == null &&
            id ==
                _stableId([
                  'sentences',
                  s['lang'] as String,
                  s['text'] as String,
                ]),
        'Historische Satzidentität verändert.',
      );
      continue;
    }
    for (final token in tokens[id] ?? <Map<String, Object?>>[]) {
      require(
        (token['context_snapshot'] as Map)['legacy'] != true,
        'Neue Satzrevision darf keine Legacyanzeige vortäuschen.',
      );
    }
    final payload = {
      'lang': s['lang'],
      'profile_sha256': profiles.first.sha256,
      'text': s['text'],
      'translation_de': s['translation_de'],
      'tokens': [
        for (final t in tokens[id] ?? <Map<String, Object?>>[])
          {for (final k in tokenFields) k: t[k]},
      ],
      'links': [
        for (final l in links[id] ?? <Map<String, Object?>>[])
          {for (final k in linkFields) k: l[k]},
      ],
    };
    require(
      revision is String &&
          revision.length == 64 &&
          s['root_sentence_id'] is String,
      'Ungültige Satzrevision.',
    );
    require(
      profiles.any(
            (profile) =>
                contextCanonicalHash({
                  ...payload,
                  'profile_sha256': profile.sha256,
                }) ==
                revision,
          ) &&
          id ==
              _stableId([
                'sentence_revisions',
                s['lang'] as String,
                s['root_sentence_id'] as String,
                revision as String,
              ]),
      'Satzrevision passt nicht zum Inhalt.',
    );
  }
  final successors = <String, String>{};
  for (final e in db.select('SELECT * FROM story_context_corrections')) {
    final key = '${e['source_key']}:${e['previous_fingerprint']}';
    require(
      e['lang'] == lang &&
          !successors.containsKey(key) &&
          e['previous_fingerprint'] != e['next_fingerprint'],
      'Mehrdeutige Storykorrektur.',
    );
    for (final prefix in ['previous', 'next']) {
      final context = jsonDecode(e['${prefix}_context'] as String);
      require(context is Map<String, dynamic>, 'Storykontext fehlt.');
      final candidate = decodeStoryCandidate(context as Map<String, dynamic>);
      require(
        candidate.lang == lang &&
            candidate.identity.key == e['identity_key'] &&
            candidate.sourceFingerprint == e['${prefix}_fingerprint'] &&
            candidate.revision == e['${prefix}_revision'] &&
            encodeStoryCandidate(candidate)['source_key'] == e['source_key'],
        'Storykante passt nicht zum Snapshot.',
      );
    }
    require(
      e['id'] ==
          _stableId([
            'story_context_corrections',
            lang,
            e['source_key'] as String,
            e['previous_fingerprint'] as String,
            e['next_fingerprint'] as String,
          ]),
      'Ungültige Korrekturidentität.',
    );
    successors[key] = '${e['source_key']}:${e['next_fingerprint']}';
  }
  for (var key in successors.keys) {
    final seen = <String>{};
    while (successors.containsKey(key)) {
      require(seen.add(key), 'Zyklische Storykorrektur.');
      key = successors[key]!;
    }
  }
}
