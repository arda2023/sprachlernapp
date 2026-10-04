// One pass of a card (docs/srs.md; decided rules of 04.10.2026: "Fast
// richtig" then exact is clean, first_attempt_correct stays literal).

import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/domain/answer_check.dart';
import 'package:sprachapp/domain/content.dart';
import 'package:sprachapp/domain/review_pass.dart';
import 'package:sprachapp/domain/srs_state.dart';

const went = ContentCard(
  id: 'card-went',
  lang: 'en',
  form: 'went',
  formNorm: 'went',
  lemmaId: 'lem-go',
  lemma: 'go',
  pos: 'VERB',
  formLabelDe: 'Verb, Vergangenheit',
);

const sentences = [
  CardSentence(
    cardId: 'card-went',
    sentenceId: 's1',
    position: 1,
    text: 'Mia went home after work.',
    gapStart: 4,
    gapEnd: 8,
    validAlternatives: ['walked'],
  ),
  CardSentence(
    cardId: 'card-went',
    sentenceId: 's2',
    position: 2,
    text: 'We went to the park.',
    gapStart: 3,
    gapEnd: 7,
  ),
  CardSentence(
    cardId: 'card-went',
    sentenceId: 's3',
    position: 3,
    text: 'Leo went to bed.',
    gapStart: 4,
    gapEnd: 8,
  ),
];

const item = PracticeItem(
  card: went,
  sentences: sentences,
  otherFormsOfLemma: {'go', 'goes', 'gone'},
);

final start = DateTime(2026, 10, 3, 9, 0, 0);
DateTime at(int seconds) => start.add(Duration(seconds: seconds));

ReviewPass pass({
  UserCardState? state,
  ReviewMode mode = ReviewMode.deck,
  bool logged = true,
  int sentence = 0,
}) => ReviewPass(
  id: 'pass-1',
  item: item,
  sentence: sentences[sentence],
  state: state,
  mode: mode,
  startedAt: start,
  logged: logged,
);

ReviewRecord? finish(ReviewPass p, [int seconds = 30]) =>
    p.complete(now: at(seconds), appVersion: '1.0.0+1', deviceId: 'dev-1');

void main() {
  test('exact first answer on first contact → box 3', () {
    final p = pass();
    expect(p.submit('went', at(4))!.verdict, AnswerVerdict.target);
    final r = finish(p)!;
    expect(r.boxBefore, 0);
    expect(r.boxAfter, 3);
    expect(r.firstAttemptCorrect, isTrue);
    expect(r.errorCount, 0);
    expect(r.hintUsed, isFalse);
    expect(r.revealed, isFalse);
    expect(r.responseMs, 4000);
    expect(r.sentenceId, 's1');
    expect(r.mode, ReviewMode.deck);
    expect(r.id, 'pass-1');
    expect(r.createdAt.isUtc, isTrue);
    expect(p.needsRepeat, isFalse);
  });

  test(
    '"Fast richtig" then exact → box 3, first_attempt_correct false, no error',
    () {
      final p = pass();
      expect(p.submit('wnet', at(3))!.verdict, AnswerVerdict.almost);
      expect(p.solved, isFalse);
      expect(p.submit('went', at(6))!.verdict, AnswerVerdict.target);
      final r = finish(p)!;
      expect(r.boxAfter, 3);
      expect(r.firstAttemptCorrect, isFalse);
      expect(r.errorCount, 0);
      expect(r.responseMs, 3000); // first checked input
      expect(p.needsRepeat, isFalse);
    },
  );

  test('"Fast richtig" then exact in a regular review moves up one box', () {
    final p = pass(
      state: UserCardState(
        cardId: 'card-went',
        box: 2,
        dueAt: DateTime(2026, 10, 3),
      ),
    );
    p.submit('wint', at(2));
    p.submit('went', at(5));
    final r = finish(p)!;
    expect([r.boxBefore, r.boxAfter, r.firstAttemptCorrect], [2, 3, false]);
  });

  test('synonym then exact → box 1, hint_used, no error', () {
    final p = pass(
      state: UserCardState(
        cardId: 'card-went',
        box: 4,
        dueAt: DateTime(2026, 10, 3),
      ),
    );
    final hint = p.submit('Walked', at(2))!;
    expect(hint.verdict, AnswerVerdict.alternative);
    expect(
      hint.message,
      'Walked passt hier auch. Gesucht ist ein anderes Wort: w…',
    );
    expect(p.solved, isFalse);
    expect(p.hintUsed, isTrue);
    p.submit('went', at(7));
    final r = finish(p)!;
    expect(r.boxAfter, 1);
    expect(r.dueAtAfter, DateTime(2026, 10, 4));
    expect(r.hintUsed, isTrue);
    expect(r.errorCount, 0);
    expect(r.revealed, isFalse);
    expect(r.firstAttemptCorrect, isFalse);
    expect(p.needsRepeat, isTrue);
  });

  test('synonym on first contact → box 1, not box 3', () {
    final p = pass();
    p.submit('walked', at(1));
    p.submit('went', at(2));
    expect(finish(p)!.boxAfter, 1);
  });

  test('synonym then "Wort erfahren" → hint_used and revealed both true', () {
    final p = pass();
    p.submit('walked', at(1));
    expect(p.reveal(at(3)), isTrue);
    expect(p.reveal(at(4)), isFalse); // once only
    expect(p.solved, isFalse); // the form still has to be typed
    p.submit('went', at(6));
    final r = finish(p)!;
    expect(r.hintUsed, isTrue);
    expect(r.revealed, isTrue);
    expect(r.errorCount, 0);
    expect(r.boxAfter, 1);
  });

  test('hint_used stays set; later errors still count, box stays 1', () {
    final p = pass();
    p.submit('walked', at(1));
    p.submit('walked', at(2)); // repeated alternative: same hint, no error
    expect(p.errorCount, 0);
    expect(p.submit('ran', at(3))!.verdict, AnswerVerdict.wrong);
    p.submit('went', at(4));
    final r = finish(p)!;
    expect([r.hintUsed, r.errorCount, r.boxAfter], [true, 1, 1]);
  });

  test('wrong answer → error, box 1', () {
    final p = pass(
      state: UserCardState(
        cardId: 'card-went',
        box: 3,
        dueAt: DateTime(2026, 10, 3),
      ),
    );
    expect(p.submit('ran', at(2))!.verdict, AnswerVerdict.wrong);
    expect(p.errorCount, 1);
    p.submit('went', at(4));
    final r = finish(p)!;
    expect(
      [r.errorCount, r.boxAfter, r.firstAttemptCorrect, r.hintUsed],
      [1, 1, false, false],
    );
    expect(p.needsRepeat, isTrue);
  });

  test('wrong form → error with the lemma hint, box 1', () {
    final p = pass();
    final f = p.submit('goes', at(2))!;
    expect(f.verdict, AnswerVerdict.wrongForm);
    expect(f.message, 'Andere Form von „go“ – gesucht: Verb, Vergangenheit');
    p.submit('went', at(3));
    final r = finish(p)!;
    expect([r.errorCount, r.boxAfter], [1, 1]);
  });

  test('"Wort erfahren" alone → revealed, box 1, no error count', () {
    final p = pass();
    expect(p.reveal(at(5)), isTrue);
    p.submit('went', at(9));
    final r = finish(p)!;
    expect(
      [r.revealed, r.errorCount, r.boxAfter, r.firstAttemptCorrect],
      [true, 0, 1, false],
    );
    expect(r.responseMs, 5000);
  });

  test('empty input is not checked', () {
    final p = pass();
    expect(p.submit('   ', at(1)), isNull);
    p.submit('went', at(2));
    expect(finish(p)!.firstAttemptCorrect, isTrue);
  });

  test('the record comes exactly once; later inputs book nothing', () {
    final p = pass();
    expect(finish(p), isNull); // not solved yet
    p.submit('went', at(2));
    expect(p.submit('went', at(3)), isNull); // double submit
    expect(p.submit('ran', at(3)), isNull); // no error after solving
    expect(p.reveal(at(3)), isFalse);
    expect(finish(p), isNotNull);
    expect(finish(p), isNull);
    expect(p.completed, isTrue);
    expect(p.errorCount, 0);
  });

  test('early practice: clean keeps the box, synonym resets', () {
    final due = DateTime(2026, 10, 20);
    final clean = pass(
      mode: ReviewMode.revue,
      state: UserCardState(cardId: 'card-went', box: 4, dueAt: due),
    );
    clean.submit('went', at(2));
    final r1 = finish(clean)!;
    expect([r1.boxAfter, r1.dueAtAfter], [4, due]);

    final helped = pass(
      mode: ReviewMode.early,
      state: UserCardState(cardId: 'card-went', box: 4, dueAt: due),
    );
    helped.submit('walked', at(1));
    helped.submit('went', at(2));
    expect(finish(helped)!.boxAfter, 1);
  });

  test('a repeat pass is practised but never logged', () {
    final p = pass(logged: false);
    p.submit('ran', at(1));
    p.submit('went', at(2));
    expect(finish(p), isNull);
    expect(p.completed, isTrue);
    expect(p.needsRepeat, isFalse); // a repeat never repeats again
  });

  test('alternatives belong to their sentence only', () {
    final p = pass(sentence: 1); // s2 has no alternatives
    expect(p.submit('walked', at(1))!.verdict, AnswerVerdict.wrong);
    expect(p.hintUsed, isFalse);
  });

  test('sentence and state must belong to the card', () {
    const other = CardSentence(
      cardId: 'card-x',
      sentenceId: 'x',
      position: 1,
      text: 'x',
      gapStart: 0,
      gapEnd: 1,
    );
    expect(
      () => ReviewPass(
        id: 'p',
        item: item,
        sentence: other,
        state: null,
        mode: ReviewMode.deck,
        startedAt: start,
      ),
      throwsArgumentError,
    );
    expect(
      () => pass(
        state: const UserCardState(cardId: 'card-x', box: 0, dueAt: null),
      ),
      throwsArgumentError,
    );
  });

  test('sentence rotation by earlier reviews', () {
    expect(item.sentenceForPass(0).sentenceId, 's1');
    expect(item.sentenceForPass(1).sentenceId, 's1');
    expect(item.sentenceForPass(5).sentenceId, 's1');
  });
}
