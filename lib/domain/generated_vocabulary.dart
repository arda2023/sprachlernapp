import 'content.dart';
import 'personal_learning.dart';
import 'personal_sentence.dart';
import 'story_learning.dart';

/// The bounded, consent-bearing wire request for a vocabulary suggestion list.
class GeneratedVocabularyRequest {
  GeneratedVocabularyRequest({
    required this.requestId,
    required this.lang,
    required String prompt,
    required this.count,
  }) : prompt = prompt.trim() {
    _require(_uuid.hasMatch(requestId), 'request_id');
    _require(languages.contains(lang), 'lang');
    _require(
      this.prompt.isNotEmpty &&
          this.prompt.length <= 400 &&
          !_controls.hasMatch(this.prompt),
      'prompt',
    );
    _require(_sentenceCount(this.prompt) <= 2, 'prompt sentences');
    _require(count >= 1 && count <= 50, 'count');
  }

  static const languages = {'en', 'es', 'it', 'nb', 'pt-BR'};
  final String requestId, lang, prompt;
  final int count;

  Map<String, dynamic> toJson() => {
    'contract': 1,
    'request_id': requestId,
    'lang': lang,
    'prompt': prompt,
    'count': count,
    'consent': 1,
  };
}

/// Validated suggestions, bound to the exact request that produced them.
class GeneratedVocabularyResponse {
  GeneratedVocabularyResponse._(this.requestId, this.lang, this.items);

  factory GeneratedVocabularyResponse.fromJson(
    Object? json, {
    required GeneratedVocabularyRequest request,
  }) {
    final map = _object(json, {'contract', 'request_id', 'lang', 'items'});
    _require(map['contract'] is int && map['contract'] == 1, 'contract');
    _require(map['request_id'] == request.requestId, 'request_id');
    _require(map['lang'] == request.lang, 'lang');
    final raw = map['items'];
    _require(
      raw is List && raw.isNotEmpty && raw.length <= request.count,
      'items',
    );
    final items = <GeneratedVocabularyItem>[];
    final forms = <String>{};
    for (final value in raw as List) {
      final item = GeneratedVocabularyItem.fromJson(value);
      _require(forms.add(item.formNorm), 'duplicate form');
      items.add(item);
    }
    return GeneratedVocabularyResponse._(
      request.requestId,
      request.lang,
      List.unmodifiable(items),
    );
  }

  final String requestId, lang;
  final List<GeneratedVocabularyItem> items;

  Map<String, dynamic> toJson() => {
    'contract': 1,
    'request_id': requestId,
    'lang': lang,
    'items': items.map((item) => item.toJson()).toList(),
  };
}

/// Untrusted model output becomes usable only after this validation boundary.
class GeneratedVocabularyItem {
  GeneratedVocabularyItem._({
    required this.form,
    required this.lemma,
    required this.pos,
    required this.glossDe,
    required this.definitionDe,
    required this.formDetail,
    required this.sentence,
    required this.translationDe,
    required this.start,
  });

  factory GeneratedVocabularyItem.fromJson(Object? json) {
    final map = _object(json, {
      'form',
      'lemma',
      'pos',
      'gloss_de',
      'definition_de',
      'form_detail',
      'sentence',
      'translation_de',
      'start',
    });
    final form = _string(map, 'form', 80);
    final lemma = _string(map, 'lemma', 80);
    final pos = _string(map, 'pos', 10);
    final gloss = _string(map, 'gloss_de', 200);
    final definition = _string(map, 'definition_de', 300);
    final detail = _string(map, 'form_detail', 200);
    final sentence = _string(map, 'sentence', 600);
    final translation = _string(map, 'translation_de', 1200);
    _require(_positions.contains(pos), 'pos');
    final words = personalWords(form).toList();
    _require(
      words.length == 1 &&
          words.single.start == 0 &&
          words.single.end == form.length,
      'form',
    );
    final start = map['start'];
    _require(
      start is int && start >= 0 && start + form.length <= sentence.length,
      'start',
    );
    final offset = start as int;
    final sentenceWords = personalWords(sentence).toList();
    _require(
      sentence.substring(offset, offset + form.length) == form &&
          sentenceWords.any(
            (word) => word.start == offset && word.end == offset + form.length,
          ),
      'word occurrence',
    );
    _require(
      sentenceWords.length >= 3 && sentenceWords.length <= 40,
      'sentence words',
    );
    _require(
      onePersonalSentence(sentence) &&
          !RegExp(r'[;\p{Pd}]', unicode: true).hasMatch(sentence),
      'sentence',
    );
    final normalized = contentFormNorm(form);
    for (final hint in [gloss, translation]) {
      _require(
        !personalWords(hint)
            .any((word) => contentFormNorm(word[0]!) == normalized),
        'answer in German hint',
      );
    }
    return GeneratedVocabularyItem._(
      form: form,
      lemma: lemma,
      pos: pos,
      glossDe: gloss,
      definitionDe: definition,
      formDetail: detail,
      sentence: sentence,
      translationDe: translation,
      start: offset,
    );
  }

  final String form, lemma, pos, glossDe, definitionDe, formDetail;
  final String sentence, translationDe;
  final int start;
  int get end => start + form.length;
  String get formNorm => contentFormNorm(form);

  /// Request IDs and example sentences do not affect lexical identity.
  String identity(String lang) {
    _require(GeneratedVocabularyRequest.languages.contains(lang), 'lang');
    return learningHash([
      'generated-vocabulary-v1',
      lang,
      formNorm,
      lemma,
      pos,
      definitionDe,
    ]);
  }

  Map<String, dynamic> toJson() => {
    'form': form,
    'lemma': lemma,
    'pos': pos,
    'gloss_de': glossDe,
    'definition_de': definitionDe,
    'form_detail': formDetail,
    'sentence': sentence,
    'translation_de': translationDe,
    'start': start,
  };
}

final _uuid = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);
final _controls = RegExp(r'[\p{Cc}\p{Cf}]', unicode: true);
final _terminals = RegExp(r'[.!?…]+(?:\s+|$)');
const _positions = {
  'ADJ',
  'ADP',
  'ADV',
  'AUX',
  'CCONJ',
  'DET',
  'INTJ',
  'NOUN',
  'NUM',
  'PART',
  'PRON',
  'PUNCT',
  'SCONJ',
  'SYM',
  'VERB',
  'X',
};

int _sentenceCount(String text) {
  final ends = _terminals.allMatches(text).toList();
  return ends.length +
      (ends.isEmpty || text.substring(ends.last.end).trim().isNotEmpty ? 1 : 0);
}

void _require(bool valid, String field) {
  if (!valid) throw FormatException('Ungültige Vokabelvorschläge: $field');
}

Map<Object?, Object?> _object(Object? json, Set<String> keys) {
  _require(
    json is Map && json.length == keys.length && json.keys.every(keys.contains),
    'fields',
  );
  return json as Map<Object?, Object?>;
}

String _string(Map<Object?, Object?> map, String field, int maxLength) {
  final value = map[field];
  _require(
    value is String &&
        value.trim().isNotEmpty &&
        value.length <= maxLength &&
        !_controls.hasMatch(value),
    field,
  );
  return value as String;
}
