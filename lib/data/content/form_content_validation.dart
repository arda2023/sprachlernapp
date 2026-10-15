import 'dart:convert';

import 'package:sqlite3/sqlite3.dart';

import '../../domain/content.dart';

/// Schema-4 transport validation only. No learner database or projection.
void validateFormContent(Database db) {
  Never reject(String message) => throw ContentUnavailable(
    ContentUnavailableReason.incompatible,
    'Schema 4: $message',
  );
  void require(bool ok, String message) {
    if (!ok) reject(message);
  }

  const columns = {
    'lexical_targets': [
      'id',
      'lang',
      'anchor_key',
      'note',
      'removed_in',
      'replaced_by',
    ],
    'card_lexical_targets': [
      'id',
      'lang',
      'card_id',
      'lexical_target_id',
      'note',
      'removed_in',
      'replaced_by',
    ],
    'form_targets': [
      'id',
      'lang',
      'sense_id',
      'form',
      'form_norm',
      'function',
      'card_id',
      'lexical_target_id',
      'note',
      'removed_in',
      'replaced_by',
    ],
    'deck_practice_targets': [
      'id',
      'deck_id',
      'form_target_id',
      'position',
      'removed_in',
      'replaced_by',
    ],
    'cards': ['identity_function', 'introduction_scope', 'learning'],
    'decks': ['practice_kind'],
    'sentence_tokens': ['form_target_id'],
  };
  for (final e in columns.entries) {
    final actual = db
        .select('PRAGMA table_info(${e.key})')
        .map((r) => r['name'])
        .toSet();
    require(actual.containsAll(e.value), 'Spalten fehlen: ${e.key}');
  }
  final tables = <String, Map<String, Map<String, Object?>>>{};
  for (final t in {
    ...columns.keys,
    'senses',
    'lemmas',
    'sentences',
    'card_sentences',
    'dictionary_forms',
    'story_sentences',
    'stories',
  }) {
    final rows = db.select('SELECT * FROM $t');
    final values = <String, Map<String, Object?>>{};
    for (final r in rows) {
      require(
        r['id'] is String && !values.containsKey(r['id']),
        'doppelte Identität: $t',
      );
      values[r['id'] as String] = Map<String, Object?>.from(r);
    }
    tables[t] = values;
  }
  bool live(Map<String, Object?> r) => r['removed_in'] == null;
  Iterable<Map<String, Object?>> active(String t) =>
      tables[t]!.values.where(live);
  // Per-validation indexes retain every active row, including duplicates.
  final tokensBySentence = <Object?, List<Map<String, Object?>>>{};
  for (final token in active('sentence_tokens')) {
    (tokensBySentence[token['sentence_id']] ??= []).add(token);
  }
  final dictionaryByForm =
      <(Object?, Object?, Object?), List<Map<String, Object?>>>{};
  for (final form in active('dictionary_forms')) {
    (dictionaryByForm[(form['lang'], form['sense_id'], form['form_norm'])] ??=
            [])
        .add(form);
  }
  Map<String, Object?> get(String t, Object? id, [Object? lang]) {
    final r = tables[t]![id];
    if (r == null || !live(r) || (lang != null && r['lang'] != lang)) {
      reject('fehlende/inaktive/fremdsprachige Referenz $t/$id');
    }
    return r;
  }

  bool text(Object? v) => v is String && v.trim().isNotEmpty;
  const functions = {'base', 'past', 'past_participle'};
  const deckFunctions = {
    'verb_base': 'base',
    'verb_past': 'past',
    'verb_participle': 'past_participle',
  };
  final lexicalKeys = <String>{};
  for (final l in active('lexical_targets')) {
    require(
      text(l['anchor_key']) &&
          text(l['note']) &&
          lexicalKeys.add('${l['lang']}|${l['anchor_key']}'),
      'lexikalische Identität/Notiz',
    );
  }
  final lexical = <String, String>{};
  for (final m in active('card_lexical_targets')) {
    get('cards', m['card_id'], m['lang']);
    get('lexical_targets', m['lexical_target_id'], m['lang']);
    require(
      text(m['note']) && !lexical.containsKey(m['card_id']),
      'doppelte/leere lexikalische Zuordnung',
    );
    lexical[m['card_id'] as String] = m['lexical_target_id'] as String;
  }
  final groups = <String, List<String>>{};
  for (final c in active('cards')) {
    final m = jsonDecode(c['learning'] as String) as Map;
    (groups[m['group_id'] as String] ??= []).add(c['id'] as String);
    final sense = get('senses', c['sense_id'], c['lang']);
    final lemma = get('lemmas', c['lemma_id'], c['lang']);
    require(
      sense['lemma_id'] == lemma['id'] && lemma['pos'] == c['pos'],
      'Karten-Sense/Lemma/POS',
    );
  }
  for (final ids in groups.values) {
    final assigned = ids
        .where(lexical.containsKey)
        .map((id) => lexical[id])
        .toSet();
    require(
      assigned.isEmpty ||
          (assigned.length == 1 && ids.every(lexical.containsKey)),
      'partielle/widersprüchliche lexikalische Gruppenbindung',
    );
  }
  final senseMembers = <String, List<String>>{};
  for (final c in active('cards')) {
    (senseMembers[jsonEncode([c['lang'], c['sense_id']])] ??= []).add(
      c['id'] as String,
    );
  }
  for (final ids in senseMembers.values) {
    final assigned = ids
        .where(lexical.containsKey)
        .map((id) => lexical[id])
        .toSet();
    require(
      assigned.isEmpty ||
          (assigned.length == 1 && ids.every(lexical.containsKey)),
      'partielle/widersprüchliche lexikalische Sense-Bindung',
    );
  }
  final forms = <String, Map<String, Object?>>{},
      identities = <String>{},
      senseLexical = <String, Object?>{};
  for (final f in active('form_targets')) {
    require(
      functions.contains(f['function']) && text(f['note']),
      'Formfunktion/Notiz',
    );
    final c = get('cards', f['card_id'], f['lang']);
    require({'VERB', 'AUX'}.contains(c['pos']), 'Formziel benötigt Verb-Sense');
    get('senses', f['sense_id'], f['lang']);
    get('lexical_targets', f['lexical_target_id'], f['lang']);
    require(
      c['form'] == f['form'] &&
          c['form_norm'] == f['form_norm'] &&
          c['sense_id'] == f['sense_id'],
      'Formziel passt nicht zur Karte',
    );
    require(
      lexical[c['id']] == f['lexical_target_id'],
      'lexikalisches Formziel passt nicht',
    );
    require(
      identities.add(
            jsonEncode([
              f['lang'],
              f['sense_id'],
              f['form_norm'],
              f['function'],
            ]),
          ) &&
          !forms.containsKey(c['id']),
      'doppelte aktive Formidentität',
    );
    forms[c['id'] as String] = f;
    final old = senseLexical.putIfAbsent(
      f['sense_id'] as String,
      () => f['lexical_target_id'],
    );
    require(
      old == f['lexical_target_id'],
      'gleicher Sense auf mehrere lexikalische Ziele verteilt',
    );
    require(
      c['identity_function'] == null || c['identity_function'] == f['function'],
      'identity_function widerspricht Formziel',
    );
  }
  for (final c in active('cards')) {
    require(
      {'ordinary', 'form_only'}.contains(c['introduction_scope']),
      'introduction_scope',
    );
    require(
      c['identity_function'] == null ||
          functions.contains(c['identity_function']),
      'identity_function',
    );
    if (c['introduction_scope'] == 'form_only' ||
        c['identity_function'] != null) {
      require(forms.containsKey(c['id']), 'Formkarte ohne Formziel');
    }
    if (c['identity_function'] != null) {
      final m = jsonDecode(c['learning'] as String) as Map;
      require(
        c['introduction_scope'] == 'form_only' &&
            m['primary_card_id'] == c['id'] &&
            groups[m['group_id']]!.length == 1,
        'Formkarte braucht eigene Einführungsgruppe',
      );
      for (final old in active('cards')) {
        if (old['id'] != c['id'] &&
            old['lang'] == c['lang'] &&
            old['form_norm'] == c['form_norm'] &&
            old['sense_id'] == c['sense_id']) {
          require(
            forms.containsKey(old['id']),
            'nicht klassifizierte konkurrierende Altkarte',
          );
        }
      }
    }
  }
  for (final d in active('decks')) {
    require(
      d['practice_kind'] == 'ordinary' ||
          deckFunctions.containsKey(d['practice_kind']),
      'practice_kind',
    );
  }
  final positions = <String, List<int>>{}, memberships = <String>{};
  for (final m in active('deck_practice_targets')) {
    final d = get('decks', m['deck_id']);
    final f = get('form_targets', m['form_target_id'], d['lang']);
    require(
      deckFunctions[d['practice_kind']] == f['function'],
      'falsche Funktion für Stapel',
    );
    require(
      m['position'] is int &&
          (m['position'] as int) > 0 &&
          memberships.add('${m['deck_id']}/${m['form_target_id']}'),
      'doppelte/ungültige Übungsposition',
    );
    (positions[d['id'] as String] ??= []).add(m['position'] as int);
  }
  for (final pos in positions.values) {
    pos.sort();
    require(
      pos.join(',') == List.generate(pos.length, (i) => i + 1).join(','),
      'Übungspositionen nicht 1..n',
    );
  }
  for (final t in active('sentence_tokens')) {
    final s = get('sentences', t['sentence_id']);
    final points = (s['text'] as String).runes.toList();
    require(t['start_pos'] is int && t['end_pos'] is int, 'Tokenoffset-Typ');
    final start = t['start_pos'] as int, end = t['end_pos'] as int;
    require(
      start >= 0 &&
          end > start &&
          end <= points.length &&
          String.fromCharCodes(points.sublist(start, end)) == t['surface'],
      'Tokenoffset/Oberfläche',
    );
    if (t['sense_id'] != null) {
      require(
        get('senses', t['sense_id'], s['lang'])['lemma_id'] == t['lemma_id'],
        'Token-Sense/Lemma',
      );
    }
    if (t['card_id'] != null) {
      final c = get('cards', t['card_id'], s['lang']);
      require(
        c['sense_id'] == t['sense_id'] &&
            c['form_norm'] == contentFormNorm(t['surface'] as String),
        'Tokenkarte',
      );
    }
    if (t['form_target_id'] != null) {
      final f = get('form_targets', t['form_target_id'], s['lang']);
      require(
        t['card_id'] == f['card_id'] &&
            t['sense_id'] == f['sense_id'] &&
            contentFormNorm(t['surface'] as String) == f['form_norm'],
        'Token-Formreferenz',
      );
    }
  }
  for (final link in active('card_sentences')) {
    final c = get('cards', link['card_id']);
    final s = get('sentences', link['sentence_id'], c['lang']);
    final points = (s['text'] as String).runes.toList();
    require(
      link['gap_start'] is int && link['gap_end'] is int,
      'Lückenoffset-Typ',
    );
    final start = link['gap_start'] as int, end = link['gap_end'] as int;
    require(
      start >= 0 &&
          end > start &&
          end <= points.length &&
          contentFormNorm(String.fromCharCodes(points.sublist(start, end))) ==
              c['form_norm'],
      'Lücke',
    );
    require(
      jsonEncode(jsonDecode(link['accepted'] as String)) ==
          jsonEncode([c['form']]),
      'accepted muss exakt Zielform sein',
    );
    final alternatives = jsonDecode(link['valid_alternatives'] as String);
    require(
      alternatives is List &&
          alternatives.every(
            (v) =>
                v is String &&
                v.isNotEmpty &&
                contentFormNorm(v.trim()) == v &&
                v != c['form_norm'],
          ) &&
          alternatives.toSet().length == alternatives.length,
      'Alternativen',
    );
    final targets = (tokensBySentence[link['sentence_id']] ?? const []).where(
      (t) =>
          t['start_pos'] == start &&
          t['end_pos'] == end &&
          t['card_id'] == c['id'],
    );
    require(targets.length == 1, 'Zieltoken fehlt/mehrdeutig');
    if (c['identity_function'] != null) {
      require(
        targets.single['form_target_id'] == forms[c['id']]!['id'],
        'Formfunktion im Zieltoken fehlt',
      );
    }
  }
  for (final sentence in active('sentences')) {
    require(text(sentence['translation_de']), 'Satzübersetzung fehlt');
    final tokens =
        (tokensBySentence[sentence['id']] ?? []).toList()
          ..sort((a, b) => (a['idx'] as int).compareTo(b['idx'] as int));
    final points = (sentence['text'] as String).runes.toList();
    var previous = 0;
    for (var i = 0; i < tokens.length; i++) {
      final t = tokens[i],
          start = tokens[i]['start_pos'] as int,
          end = tokens[i]['end_pos'] as int;
      require(
        t['idx'] == i &&
            start >= previous &&
            String.fromCharCodes(points.sublist(previous, start))
                .trim()
                .isEmpty,
        'Tokenreihenfolge/Abdeckung',
      );
      if (RegExp(r'[a-zA-Z0-9]').hasMatch(t['surface'] as String)) {
        final sense = get('senses', t['sense_id'], sentence['lang']);
        get('lemmas', t['lemma_id'], sentence['lang']);
        // Schema 4 keeps inherited senses unchanged. Their long definition is
        // nullable in the shared content schema; the gloss remains required.
        require(
          text(sense['gloss_de']) &&
              (sense['definition_de'] == null || text(sense['definition_de'])),
          'Bedeutung/Definition fehlt',
        );
        final tokenForm = contentFormNorm(t['surface'] as String);
        require(
          (dictionaryByForm[(sentence['lang'], t['sense_id'], tokenForm)] ??
                  const [])
              .any((d) => text(d['gloss_de'])),
          'Token-Wörterbuchbindung fehlt',
        );
      }
      previous = end;
    }
    require(
      String.fromCharCodes(points.sublist(previous)).trim().isEmpty,
      'Satz nicht vollständig annotiert',
    );
  }
  final storyPositions = <String, Set<int>>{};
  for (final link in active('story_sentences')) {
    final story = get('stories', link['story_id']);
    get('sentences', link['sentence_id'], story['lang']);
    require(
      link['idx'] is int &&
          (link['idx'] as int) >= 0 &&
          link['paragraph_idx'] is int &&
          (link['paragraph_idx'] as int) >= 0,
      'Storyposition',
    );
    require(
      (storyPositions[story['id'] as String] ??= {}).add(link['idx'] as int),
      'doppelte Storyposition',
    );
  }
  final dictionaryKeys = <String>{};
  for (final df in active('dictionary_forms')) {
    get('senses', df['sense_id'], df['lang']);
    require(
      dictionaryKeys.add(
        jsonEncode([df['lang'], df['form_norm'], df['sense_id']]),
      ),
      'mehrdeutige Wörterbuchzuordnung',
    );
    if (df['card_id'] != null) {
      final c = get('cards', df['card_id'], df['lang']);
      require(
        c['sense_id'] == df['sense_id'] && c['form_norm'] == df['form_norm'],
        'Wörterbuchkarte',
      );
    }
  }
}
