import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/models/exercise_models.dart';
import 'package:sprachapp/models/sample_content.dart';

void main() {
  // Visible word counts and gap counts before the editorial extension.
  const originals = {
    'text-last-train-to-seville': (words: 46, gaps: 6),
    'text-saturday-market': (words: 15, gaps: 5),
    'text-slow-morning': (words: 41, gaps: 9),
    'text-at-the-station': (words: 27, gaps: 6),
    'text-visit-to-the-doctor': (words: 20, gaps: 7),
  };

  const extendedWordCounts = {
    'text-last-train-to-seville': 91,
    'text-saturday-market': 29,
    'text-slow-morning': 79,
    'text-at-the-station': 52,
    'text-visit-to-the-doctor': 39,
  };

  test(
    'all five texts retain their IDs and roughly double in visible length',
    () {
      expect(
        sampleExerciseTexts.map((text) => text.id).toSet(),
        originals.keys.toSet(),
      );
      for (final text in sampleExerciseTexts) {
        final plain = _plainText(text);
        final count = plain.split(RegExp(r'\s+')).length;
        final original = originals[text.id]!;
        expect(count, extendedWordCounts[text.id], reason: text.id);
        expect(
          count / original.words,
          inInclusiveRange(1.8, 2.2),
          reason: text.id,
        );
        expect(
          text.gapCount(ExerciseMode.anyWordClass),
          greaterThan(original.gaps),
          reason: text.id,
        );
        expect(
          text.gapCount(ExerciseMode.verbs),
          greaterThan(0),
          reason: text.id,
        );
      }
    },
  );

  test(
    'every complete exercise sentence has an offline German translation',
    () {
      for (final text in sampleExerciseTexts) {
        final sentences = RegExp(r'[^.!?]+[.!?]').allMatches(_plainText(text));
        expect(sentences, isNotEmpty, reason: text.id);
        for (final match in sentences) {
          final sentence = match.group(0)!.trim();
          final translation = sampleTranslateSentence(sentence);
          expect(translation, isNot('Übersetzung folgt.'), reason: sentence);
          expect(translation.trim(), isNotEmpty, reason: sentence);
          expect(translation, isNot(sentence), reason: sentence);
        }
      }
    },
  );

  test('all gap markup resolves to valid single word answers and hints', () {
    for (final text in sampleExerciseTexts) {
      expect(
        _plainText(text),
        isNot(contains(RegExp(r'[{}|]'))),
        reason: text.id,
      );
      for (final paragraph in text.segments) {
        for (final gap in paragraph.whereType<TextGap>()) {
          expect(gap.answer, matches(RegExp(r'^[A-Za-z]+$')), reason: text.id);
          expect(gap.base, matches(RegExp(r'^[A-Za-z]+$')), reason: text.id);
          expect(WordClass.values, contains(gap.wordClass), reason: text.id);
        }
      }
    }
  });
}

String _plainText(ExerciseText text) => text.segments
    .map(
      (paragraph) => paragraph
          .map(
            (segment) =>
                segment is TextGap ? segment.answer : segment as String,
          )
          .join(),
    )
    .join(' ');
