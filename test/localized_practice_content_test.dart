import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/models/exercise_models.dart';
import 'package:sprachapp/models/localized_practice_content.dart';
import 'package:sprachapp/models/practice_models.dart';

void main() {
  test('each additional app language has a complete offline practice set', () {
    expect(localizedPracticeContent.keys.toSet(), {'es', 'it', 'nb', 'pt-BR'});
    final ids = <String>{};
    for (final entry in localizedPracticeContent.entries) {
      final language = entry.key;
      final content = entry.value;
      expect(content.texts, hasLength(3), reason: language);
      expect(content.listening, hasLength(3), reason: language);
      expect(content.grammar, hasLength(3), reason: language);
      expect(content.rules, hasLength(2), reason: language);
      for (final id in [
        ...content.texts.map((text) => text.id),
        ...content.listening.map((exercise) => exercise.id),
        ...content.grammar.map((exercise) => exercise.id),
        ...content.rules.map((rule) => rule.id),
      ]) {
        expect(id, startsWith('$language-'));
        expect(ids.add(id), isTrue, reason: 'Duplicate ID: $id');
      }
      for (final text in content.texts) {
        expect(text.language, language);
        expect(text.paragraphs, hasLength(2));
        final gaps = text.segments.expand((p) => p).whereType<TextGap>();
        expect(gaps.length, greaterThanOrEqualTo(6), reason: text.id);
        expect(
          gaps.map((gap) => gap.wordClass).toSet(),
          containsAll([WordClass.verb, WordClass.noun, WordClass.adjective]),
        );
        for (final gap in gaps) {
          expect(gap.answer.trim(), isNotEmpty);
          expect(gap.base.trim(), isNotEmpty);
        }
        final plainParagraphs = [
          for (final paragraph in text.segments)
            paragraph
                .map((part) => part is TextGap ? part.answer : part)
                .join(),
        ];
        expect(
          plainParagraphs.join(' ').split(RegExp(r'\s+')).length,
          greaterThanOrEqualTo(60),
          reason: text.id,
        );
        for (final paragraph in plainParagraphs) {
          expect(paragraph, isNot(contains('{')));
          for (final sentence in paragraph.split(RegExp(r'(?<=[.!?])\s+'))) {
            expect(content.translations[sentence], isNotNull, reason: sentence);
            expect(content.translations[sentence]!.trim(), isNotEmpty);
            expect(content.translations[sentence], isNot(sentence));
          }
        }
      }
      for (final exercise in [...content.listening, ...content.grammar]) {
        expect(exercise.targetLanguage, language);
        expect(exercise.sourceLanguage, 'de');
        expect(exercise.options.toSet().length, exercise.options.length);
        expect(
          exercise.options.where((o) => o == exercise.answer),
          hasLength(1),
        );
        expect(exercise.explanation, isNotEmpty);
        if (exercise.kind == PracticeKind.listening) {
          expect(exercise.audioText, isNotNull);
          expect(exercise.audioText!.split(' ').length, greaterThan(3));
        } else {
          expect('___'.allMatches(exercise.prompt), hasLength(1));
        }
      }
      for (final rule in content.rules) {
        expect(rule.targetLanguage, language);
        expect(rule.sourceLanguage, 'de');
        expect(rule.sections, isNotEmpty);
        expect(rule.sections.expand((section) => section.examples), isNotEmpty);
      }
    }
  });
}
