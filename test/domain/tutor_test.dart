import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/domain/tutor.dart';
import 'package:sprachapp/domain/tutor_skills.dart';

final now = DateTime.utc(2026, 11, 22, 12);
TutorItem item({
  String id = 'item',
  List<String> skills = const ['present_simple'],
  TutorOrigin origin = TutorOrigin.practice,
  String topic = 'alltag',
  bool shown = false,
  int failures = 0,
  String? lastRoundId,
  TutorItemStatus? status,
}) => TutorItem(
  id: id,
  lang: 'en',
  kind: TutorKind.translate,
  promptDe: 'Ich gehe heute nach Hause.',
  referenceAnswer: 'I am going home today.',
  skills: skills,
  topic: topic,
  origin: origin,
  answerShown: shown,
  failures: failures,
  lastRoundId: lastRoundId,
  status: status ?? (shown ? TutorItemStatus.retry : TutorItemStatus.fresh),
);
TutorSkillState skill(
  String id, {
  int box = 1,
  int streak = 0,
  String? topic,
  bool tested = true,
  DateTime? due,
}) => TutorSkillState(
  lang: 'en',
  skillId: id,
  tested: tested,
  box: box,
  freshStreak: streak,
  dueAt: due ?? now,
  updatedAt: now,
  lastFreshTopic: topic,
);
TutorAttempt attempt(
  TutorItem i,
  TutorOutcome outcome, {
  List<TutorError> errors = const [],
}) => TutorAttempt(
  attemptId: 'attempt',
  itemId: i.id,
  answer: 'answer',
  scores: switch (outcome) {
    TutorOutcome.correct => const TutorScores(2, 2, 2),
    TutorOutcome.acceptable => const TutorScores(2, 1, 1),
    TutorOutcome.incorrect => const TutorScores(0, 0, 0),
  },
  outcome: outcome,
  errors: errors,
  feedbackDe: 'Feedback.',
  idealAnswer: 'Ideal.',
  fresh: !i.answerShown,
  createdAt: now,
);

void main() {
  group('rubric: all 27 score triples and major/minor positions', () {
    for (var m = 0; m <= 2; m++) {
      for (var g = 0; g <= 2; g++) {
        for (var n = 0; n <= 2; n++) {
          for (final position in [
            'none',
            'targetMajor',
            'otherMajor',
            'targetMinor',
          ]) {
            test('$m/$g/$n $position', () {
              final errors = position == 'none'
                  ? <TutorError>[]
                  : [
                      TutorError(
                        skill: position == 'otherMajor'
                            ? 'articles'
                            : 'present_simple',
                        severity: position == 'targetMinor'
                            ? TutorSeverity.minor
                            : TutorSeverity.major,
                        quote: '',
                        fix: '',
                      ),
                    ];
              final expected = m == 2 && g == 2 && n >= 1
                  ? TutorOutcome.correct
                  : m >= 1 && g >= 1 && n >= 1 && position != 'targetMajor'
                  ? TutorOutcome.acceptable
                  : TutorOutcome.incorrect;
              expect(
                tutorOutcome(TutorScores(m, g, n), errors, ['present_simple']),
                expected,
              );
            });
          }
        }
      }
    }
  });
  for (final outcome in TutorOutcome.values) {
    test('diagnostic start: ${outcome.name}', () {
      final i = item(origin: TutorOrigin.diagnostic);
      final next = applyTutorAttempt(
        item: i,
        attempt: attempt(i, outcome),
        states: {},
        now: now,
      );
      final s = next.states['present_simple']!;
      expect(
        s.box,
        {
          TutorOutcome.correct: 3,
          TutorOutcome.acceptable: 2,
          TutorOutcome.incorrect: 1,
        }[outcome],
      );
      expect(s.dueAt, now.add(Duration(days: tutorIntervals[s.box])));
      expect(s.tested, true);
      expect(s.freshStreak, outcome == TutorOutcome.correct ? 1 : 0);
    });
    for (var box = 1; box <= 5; box++) {
      for (final fresh in [true, false]) {
        test('${outcome.name}, box $box, fresh $fresh', () {
          final i = item(shown: !fresh);
          final next = applyTutorAttempt(
            item: i,
            attempt: attempt(i, outcome),
            states: {
              'present_simple': skill(
                'present_simple',
                box: box,
                streak: 1,
                topic: 'reisen',
              ),
            },
            now: now,
          );
          final s = next.states['present_simple']!;
          final expectedBox = switch (outcome) {
            TutorOutcome.correct => fresh ? (box + 1).clamp(1, 5) : box,
            TutorOutcome.acceptable => box,
            TutorOutcome.incorrect => (box - 2).clamp(1, 5),
          };
          expect(s.box, expectedBox);
          expect(
            s.freshStreak,
            outcome == TutorOutcome.correct ? (fresh ? 2 : 1) : 0,
          );
          expect(
            s.dueAt,
            now.add(
              Duration(
                days: outcome == TutorOutcome.correct && fresh
                    ? tutorIntervals[expectedBox]
                    : outcome == TutorOutcome.acceptable
                    ? 1
                    : 0,
              ),
            ),
          );
          expect(
            next.item.status,
            outcome == TutorOutcome.incorrect
                ? TutorItemStatus.retry
                : TutorItemStatus.retired,
          );
          expect(next.item.answerShown, true);
          expect(
            next.regeneration != null,
            !fresh && box == 1 && outcome == TutorOutcome.correct,
          );
        });
      }
    }
  }
  test(
    'same topic cannot establish secure mastery; different fresh topic can',
    () {
      final original = skill(
        'present_simple',
        box: 3,
        streak: 1,
        topic: 'alltag',
      );
      for (final topic in ['alltag', 'reisen']) {
        final i = item(topic: topic);
        final s = applyTutorAttempt(
          item: i,
          attempt: attempt(i, TutorOutcome.correct),
          states: {'present_simple': original},
          now: now,
        ).states['present_simple']!;
        expect(s.secure, topic == 'reisen');
        expect(original.box, 3);
      }
    },
  );
  test(
    'third failure retires and requests same skills with parent identity',
    () {
      var i = item(skills: ['present_simple', 'word_order']);
      var states = <String, TutorSkillState>{};
      for (var n = 1; n <= 3; n++) {
        final update = applyTutorAttempt(
          item: i,
          attempt: attempt(i, TutorOutcome.incorrect),
          states: states,
          now: now,
        );
        i = update.item;
        states = update.states;
        expect(i.failures, n);
        expect(update.regeneration != null, n == 3);
        if (n == 3) {
          expect(i.status, TutorItemStatus.retired);
          expect(i.regenerationNeeded, true);
          expect(update.regeneration!.parentItemId, 'item');
          expect(update.regeneration!.skills, ['present_simple', 'word_order']);
          expect(update.regeneration!.origin, TutorOrigin.regenerated);
        }
      }
    },
  );
  test('other major skills are demoted once, other and minor ignored', () {
    final i = item();
    const errors = [
      TutorError(
        skill: 'articles',
        severity: TutorSeverity.major,
        quote: '',
        fix: '',
      ),
      TutorError(
        skill: 'articles',
        severity: TutorSeverity.major,
        quote: '',
        fix: '',
      ),
      TutorError(
        skill: 'word_order',
        severity: TutorSeverity.major,
        quote: '',
        fix: '',
      ),
      TutorError(
        skill: 'other',
        severity: TutorSeverity.major,
        quote: '',
        fix: '',
      ),
      TutorError(
        skill: 'comparison',
        severity: TutorSeverity.minor,
        quote: '',
        fix: '',
      ),
    ];
    final next = applyTutorAttempt(
      item: i,
      attempt: attempt(i, TutorOutcome.acceptable, errors: errors),
      states: {'articles': skill('articles', box: 5, streak: 3)},
      now: now,
    );
    expect(next.states['articles']!.box, 4);
    expect(next.states['articles']!.freshStreak, 0);
    expect(next.states['articles']!.dueAt, now);
    expect(next.states['word_order']!.box, 1);
    expect(next.states.containsKey('other'), false);
    expect(next.states.containsKey('comparison'), false);
  });
  test('derived counts are language catalog scoped', () {
    final counts = tutorCounts('en', {
      'present_simple': skill('present_simple'),
      'articles': skill('articles', box: 4, streak: 2),
      'alien': skill('alien'),
    });
    expect(counts.weak, 1);
    expect(counts.secure, 1);
    expect(counts.untested, tutorSkills['en']!.length - 2);
  });
  group('round composition', () {
    test('situation prefers questions within each four-task group', () {
      final round = composeTutorRound(
        lang: 'pt-BR',
        states: {},
        items: [],
        now: now,
        premium: true,
        remainingDailyQuota: 3,
      );
      expect(
        round
            .firstWhere((s) => s.primarySkill == 'negation_questions')
            .request
            .kind,
        TutorKind.situation,
      );
      expect(
        round.where((s) => s.request.kind == TutorKind.situation),
        hasLength(2),
      );
    });
    List<TutorRoundSlot> compose({
      Map<String, TutorSkillState> states = const {},
      List<TutorItem> items = const [],
      bool premium = true,
      int quota = 3,
      String? previous,
      int offset = 0,
    }) => composeTutorRound(
      lang: 'en',
      states: states,
      items: items,
      now: now,
      premium: premium,
      remainingDailyQuota: quota,
      previousRoundId: previous,
      freshItemsSoFar: offset,
    );
    test(
      'new learner: level ordered, ten frozen slots, every fourth situation',
      () {
        final round = compose();
        expect(round, hasLength(10));
        expect(
          round.map((s) => s.primarySkill),
          tutorSkills['en']!.take(10).map((s) => s.id),
        );
        expect(
          round.where((s) => s.request.kind == TutorKind.situation),
          hasLength(2),
        );
        expect(() => round.clear(), throwsUnsupportedError);
        expect(
          compose().map((s) => s.primarySkill),
          round.map((s) => s.primarySkill),
        );
      },
    );
    test(
      'free capacity from zero to three, cadence persists across rounds',
      () {
        for (var n = 0; n <= 3; n++) {
          expect(compose(premium: false, quota: n), hasLength(n));
        }
        expect(compose(offset: 3).first.request.kind, TutorKind.situation);
      },
    );
    test(
      'reserve four diagnostics; up to three retries, fresh/retry interleaving',
      () {
        final ids = tutorSkills['en']!.take(8).map((s) => s.id).toList();
        final round = compose(
          states: {for (final id in ids) id: skill(id)},
          items: [
            for (var n = 0; n < 4; n++)
              item(id: '$n', skills: [ids[n]], shown: true),
          ],
        );
        expect(round.where((s) => s.retry), hasLength(3));
        expect(
          round.where((s) => s.request.origin == TutorOrigin.diagnostic).length,
          greaterThanOrEqualTo(4),
        );
        expect(round.first.retry, false);
        for (var n = 1; n < round.length; n++) {
          expect(round[n].primarySkill, isNot(round[n - 1].primarySkill));
        }
      },
    );
    test('last-round retry excluded, no same-round duplicates; future skills excluded', () {
      final states = {
        for (final s in tutorSkills['en']!)
          s.id: skill(s.id, box: 4, due: now.add(const Duration(days: 1))),
      };
      states['present_simple'] = skill('present_simple');
      final round = compose(
        states: states,
        previous: 'last',
        items: [item(shown: true, lastRoundId: 'last')],
      );
      expect(round, hasLength(1));
      expect(round.single.retry, false);
      expect(
        compose(
          states: {
            for (final s in tutorSkills['en']!)
              s.id: skill(s.id, due: now.add(const Duration(days: 1))),
          },
        ),
        isEmpty,
      );
    });
    test('cached fresh content reused; repeated mastery topic excluded', () {
      final i = item();
      final r = compose(
        states: {'present_simple': skill('present_simple')},
        items: [i],
      );
      expect(r.first.item, same(i));
      expect(
        compose(
          states: {'present_simple': skill('present_simple', topic: 'alltag')},
          items: [i],
        ).first.item,
        isNull,
      );
    });
    test('regeneration parent request survives across rounds', () {
      final i = item(
        shown: true,
        failures: 3,
        status: TutorItemStatus.retired,
      ).copyWith(regenerationNeeded: true);
      final r = compose(
        states: {'present_simple': skill('present_simple')},
        items: [i],
      );
      expect(r.first.request.parentItemId, i.id);
      expect(r.first.request.origin, TutorOrigin.regenerated);
    });
  });
  test('two distinct failed A1 diagnostics skip B1 only for this round', () {
    final a = item(id: 'a', origin: TutorOrigin.diagnostic);
    final b = item(
      id: 'b',
      origin: TutorOrigin.diagnostic,
      skills: ['word_order'],
    );
    final slot = TutorRoundSlot(
      request: TutorItemRequest(
        skills: ['prepositions'],
        origin: TutorOrigin.diagnostic,
      ),
    );
    final failures = [
      attempt(a, TutorOutcome.incorrect),
      attempt(b, TutorOutcome.incorrect),
    ];
    expect(skipTutorDiagnostic(slot, 'en', failures, {'a': a, 'b': b}), true);
    expect(skipTutorDiagnostic(slot, 'en', failures.take(1), {'a': a}), false);
    expect(skipTutorDiagnostic(slot, 'en', [], {}), false);
    expect(
      skipTutorDiagnostic(
        TutorRoundSlot(
          request: TutorItemRequest(
            skills: ['past_simple'],
            origin: TutorOrigin.diagnostic,
          ),
        ),
        'en',
        failures,
        {'a': a, 'b': b},
      ),
      false,
    );
  });
  test('prefix removal and German language phrases', () {
    for (final prefix in [
      'Übersetze:',
      'Übersetzen Sie:',
      'Translate:',
      'Bitte übersetze ins Englische:',
    ]) {
      expect(
        stripTutorInstruction('$prefix Ich gehe nach Hause.'),
        'Ich gehe nach Hause.',
      );
    }
    expect(
      stripTutorInstruction('Bitte komm nach Hause.'),
      'Bitte komm nach Hause.',
    );
    expect(tutorSkills.keys.map(tutorIntoLanguage), [
      'ins Englische',
      'ins Portugiesische',
      'ins Spanische',
      'ins Italienische',
      'ins Norwegische',
    ]);
    expect(tutorSkills.keys.map(tutorInLanguage), [
      'auf Englisch',
      'auf Portugiesisch',
      'auf Spanisch',
      'auf Italienisch',
      'auf Norwegisch',
    ]);
  });
}
