import 'dart:convert';

import 'content.dart';
import 'story_learning.dart';
import 'personal_sentence.dart';

/// A source occurrence, never a model instruction or a claimed pack identity.
class PersonalTarget {
  PersonalTarget({
    required this.lang,
    required this.text,
    required this.form,
    required this.start,
    required this.source,
  });
  final String lang, text, form, source;
  final int start;
  int get end => start + form.length;
  String get key =>
      learningHash(['personal-target-v1', lang, text, start, end]);
  String get anchor => 'private:v1:$key';
  LearningIdentity get identity =>
      LearningIdentity(lang, contentFormNorm(form), anchor);
  Map<String, dynamic> get body => {
    'contract': 2,
    'lang': lang,
    'text': text,
    'form': form,
    'start': start,
    'end': end,
  };
  void validate() {
    if (!{'en', 'pt-BR'}.contains(lang) ||
        text.isEmpty ||
        text.length > 600 ||
        text.contains('\n') ||
        form.isEmpty ||
        form.length > 80 ||
        start < 0 ||
        end > text.length ||
        text.substring(start, end) != form ||
        !personalWords(text).any((m) => m.start == start && m.end == end)) {
      throw const FormatException('Ungültige Wortstelle');
    }
  }
}

Iterable<RegExpMatch> personalWords(String text) => RegExp(
  r"[\p{L}\p{M}]+(?:['’\-][\p{L}\p{M}]+)*",
  unicode: true,
).allMatches(text);

/// Separate validation boundary; editorial StoryLearningCandidate is unchanged.
/// Constructed only after validating a complete, bounded creation response.
class PersonalLearningCandidate extends StoryLearningCandidate {
  PersonalLearningCandidate._(
    this.target,
    this.payload,
    this.independentOf,
    this.hints,
    StorySentence original,
    StoryToken selected,
    StoryPracticeContext practice,
  ) : super(
        storyId: target.source,
        revision: 'private_haiku_v1',
        lang: target.lang,
        sentence: original,
        token: selected,
        practiceContext: practice,
      );
  final PersonalTarget target;
  final Map<String, dynamic> payload;
  final Set<String> independentOf;
  final Map<String, dynamic> hints;
  String get provenance => jsonEncode({
    'kind': 'private_haiku_v1',
    'provider': 'anthropic',
    'model': 'claude-haiku-5-5',
    'original': target.body,
    'reason': payload['reason'],
    'reason_detail': payload['reason_detail'],
    'form_detail': payload['form_detail'],
    'function': payload['function'],
    'distinctions': payload['distinctions'],
    'cache_use': payload['cache_use'],
    'cache_note': payload['cache_note'],
    'translation_hints': hints,
  });
  factory PersonalLearningCandidate.parse(
    PersonalTarget t,
    Map<String, dynamic> p, {
    Set<String> independentOf = const {},
    Map<String, dynamic> hints = const {},
  }) {
    validatePersonalResponse(t, p);
    if (p['reuse_id'] != null) throw const FormatException('Existing target');
    if (independentOf.any(
      (id) => p['distinctions'][id]?['relation'] != 'independent',
    )) {
      throw const FormatException('Unbelegte Bedeutungsabgrenzung');
    }
    validatePersonalHints(t, p, hints);
    final lemmaId = 'private:lemma:${t.key}';
    StoryToken token(int index, int start, int end, String surface) =>
        StoryToken(
          index: index,
          start: start,
          end: end,
          surface: surface,
          lemmaId: lemmaId,
          lemma: p['lemma'] as String,
          pos: p['pos'] as String,
          senseId: t.anchor,
          senseKey: '${p['definition_de']} · ${p['form_detail']}',
          formFunction: p['function'] as String?,
          lexicalTargetId: p['function'] == null ? null : t.anchor,
          gloss: p['gloss_de'] as String,
          definition: p['definition_de'] as String,
        );
    final selected = token(0, t.start, t.end, t.form);
    final original = StorySentence(
      id: t.key,
      text: t.text,
      translation: '',
      paragraph: 0,
      tokens: [selected],
    );
    final text = p['sentence'] as String;
    final start = p['start'] as int;
    final tokens = <StoryToken>[];
    // Every non-whitespace span is represented; only the chosen word requires
    // linguistic annotation. Never manufacture senses for surrounding words.
    for (final m in RegExp(
      r"[\p{L}\p{M}]+(?:['’\-][\p{L}\p{M}]+)*|[^\s]",
      unicode: true,
    ).allMatches(text)) {
      tokens.add(
        m.start == start
            ? token(tokens.length, m.start, m.end, m[0]!)
            : StoryToken(
                index: tokens.length,
                start: m.start,
                end: m.end,
                surface: m[0]!,
              ),
      );
    }
    final chosen = tokens.singleWhere((v) => v.start == start);
    final sentence = StorySentence(
      id: 'private:context:${t.key}',
      text: text,
      translation: p['translation_de'] as String,
      paragraph: 0,
      tokens: tokens,
    );
    return PersonalLearningCandidate._(
      t,
      Map.unmodifiable(p),
      Set.unmodifiable(independentOf),
      Map.unmodifiable(hints),
      original,
      selected,
      StoryPracticeContext(sentence, chosen),
    );
  }
  @override
  String? validationProblem({bool needsContext = true}) {
    try {
      validatePersonalResponse(target, payload);
      target.validate();
    } catch (_) {
      return 'Die persönliche Lernkarte ist unvollständig.';
    }
    if (identity.semanticAnchor != target.anchor ||
        token.contextApproved ||
        practiceToken.surface != target.form ||
        practiceToken.start != payload['start']) {
      return 'Die persönliche Wortstelle passt nicht.';
    }
    return null;
  }
}

void validatePersonalResponse(PersonalTarget t, Map<String, dynamic> p) {
  t.validate();
  const keys = {
    'distinctions',
    'cache_use',
    'cache_note',
    'reuse_id',
    'lemma',
    'pos',
    'definition_de',
    'gloss_de',
    'form_detail',
    'function',
    'sentence',
    'translation_de',
    'start',
    'reason',
    'reason_detail',
  };
  void require(bool value) {
    if (!value) throw const FormatException('Ungültige Lernkarte');
  }

  require(p.keys.toSet().length == keys.length && p.keys.every(keys.contains));
  for (final k in [
    'lemma',
    'pos',
    'definition_de',
    'gloss_de',
    'form_detail',
    'sentence',
    'translation_de',
    'reason',
    'reason_detail',
    'cache_note',
  ]) {
    final v = p[k];
    require(
      v is String &&
          v.trim().isNotEmpty &&
          v.length <=
              (k == 'sentence'
                  ? 600
                  : k == 'translation_de'
                  ? 1200
                  : 200) &&
          !RegExp(r'[\x00-\x1f]').hasMatch(v),
    );
  }
  require(
    {
      'NOUN',
      'VERB',
      'AUX',
      'ADJ',
      'ADV',
      'PRON',
      'DET',
      'ADP',
      'CCONJ',
      'SCONJ',
      'NUM',
      'PART',
      'INTJ',
    }.contains(p['pos']),
  );
  require(
    p['function'] == null ||
        {'base', 'past', 'past_participle'}.contains(p['function']),
  );
  require(
    p['distinctions'] is Map &&
        (p['distinctions'] as Map).values.every(
          (v) =>
              v is Map &&
              v.length == 2 &&
              {'independent', 'same', 'unclear'}.contains(v['relation']) &&
              v['reason'] is String &&
              (v['reason'] as String).trim().isNotEmpty &&
              (v['reason'] as String).length <= 200,
        ),
  );
  require(
    p['cache_use'] is Map &&
        (p['cache_use'] as Map).length == 2 &&
        p['cache_use']['word'] is bool &&
        p['cache_use']['sentence'] is bool,
  );
  require(p['reuse_id'] == null || p['reuse_id'] is String);
  require(p['start'] is int && (p['start'] as int) >= 0);
  require({'original', 'too_short', 'unusable_target'}.contains(p['reason']));
  if (p['reuse_id'] != null) return;
  final sentence = p['sentence'] as String, start = p['start'];
  require(
    start is int && start >= 0 && start + t.form.length <= sentence.length,
  );
  require(
    sentence.substring(start as int, start + t.form.length) == t.form &&
        personalWords(sentence)
            .any((m) => m.start == start && m.end == start + t.form.length),
  );
  final count = personalWords(sentence).length;
  require(count >= 3 && count <= 40);
  final reason = p['reason'];
  require({'original', 'too_short', 'unusable_target'}.contains(reason));
  if (reason != 'original') require(onePersonalSentence(sentence));
  if (reason == 'original') {
    require(sentence == t.text && start == t.start);
  }
  if (p['reuse_id'] == null) {
    if (personalWords(t.text).length <= 2) {
      require(reason == 'too_short');
    } else {
      require(reason != 'too_short');
    }
  }
  // A German hint must not reveal the answer token (including case variants).
  for (final field in ['gloss_de', 'translation_de']) {
    require(
      !personalWords(p[field] as String)
          .any((m) => contentFormNorm(m[0]!) == contentFormNorm(t.form)),
    );
  }
}

abstract interface class PersonalLearningStore {
  Future<StoryAddResult> savePersonalLearning(
    StoryLearningCandidate candidate, {
    required DateTime now,
    required PersonalTarget source,
    required void Function() verify,
  });
}

/// Cache evidence is never a complete card. Claimed reuse must be exact.
void validatePersonalHints(
  PersonalTarget t,
  Map<String, dynamic> p,
  Map<String, dynamic> hints,
) {
  final use = p['cache_use'] as Map;
  if (use['word'] == true) {
    final value = hints['word']?['value'];
    if (value is! Map ||
        value['lemma'] != p['lemma'] ||
        value['pos'] != p['pos'] ||
        value['gloss_de'] != p['gloss_de'] ||
        value['form_label'] != p['form_detail']) {
      throw const FormatException('Widersprüchliche Wortübernahme');
    }
  }
  if (use['sentence'] == true &&
      (hints['sentence'] == null ||
          p['sentence'] != t.text ||
          hints['sentence']['value'] != p['translation_de'])) {
    throw const FormatException('Widersprüchliche Satzübernahme');
  }
}
