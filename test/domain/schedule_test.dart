// Box and due date after a pass (PRODUCT.md, docs/srs.md). Dates are local;
// expectations use calendar fields, so the tests hold in every time zone.

import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/domain/leitner.dart';
import 'package:sprachapp/domain/srs_state.dart';

void main() {
  // Answered on 3 Oct 2026, 22:40 local time.
  final answered = DateTime(2026, 10, 3, 22, 40);

  void expectMidnight(DateTime due, int year, int month, int day) {
    final local = due.toLocal();
    expect(
      [
        local.year,
        local.month,
        local.day,
        local.hour,
        local.minute,
        local.second,
      ],
      [year, month, day, 0, 0, 0],
    );
  }

  ({int boxAfter, DateTime dueAtAfter}) schedule(
    int box, {
    ReviewMode mode = ReviewMode.deck,
    int errors = 0,
    bool revealed = false,
    bool hint = false,
    DateTime? dueBefore,
  }) => scheduleReview(
    boxBefore: box,
    dueAtBefore: dueBefore ?? (box == 0 ? null : DateTime(2026, 10, 3)),
    mode: mode,
    errorCount: errors,
    revealed: revealed,
    hintUsed: hint,
    answeredAt: answered,
  );

  group('local calendar day', () {
    test(
      'due date is midnight of answer day + interval (docs/srs.md example)',
      () {
        // Box 2 → 3 (14 days) from 3 Oct 22:40 → 17 Oct 00:00.
        final r = schedule(2);
        expect(r.boxAfter, 3);
        expectMidnight(r.dueAtAfter, 2026, 10, 17);
      },
    );

    test(
      'a late answer is due at the start of the next day, not 24 h later',
      () {
        final r = scheduleReview(
          boxBefore: 3,
          dueAtBefore: DateTime(2026, 10, 1),
          mode: ReviewMode.deck,
          errorCount: 1,
          revealed: false,
          hintUsed: false,
          answeredAt: DateTime(2026, 10, 3, 23, 59),
        );
        expect(r.boxAfter, 1);
        expectMidnight(r.dueAtAfter, 2026, 10, 4);
        expect(
          r.dueAtAfter.difference(DateTime(2026, 10, 3, 23, 59)).inMinutes,
          1,
        );
      },
    );

    test('month, year and leap-day boundaries', () {
      expectMidnight(
        startOfLocalDay(DateTime(2026, 12, 31, 18), plusDays: 1),
        2027,
        1,
        1,
      );
      expectMidnight(
        startOfLocalDay(DateTime(2028, 2, 28, 9), plusDays: 1),
        2028,
        2,
        29,
      );
      expectMidnight(
        startOfLocalDay(DateTime(2026, 1, 31, 9), plusDays: 40),
        2026,
        3,
        12,
      );
    });

    test('daylight-saving changes do not shift the due time', () {
      // Spans the EU switch (25 Oct 2026) and the US switch (1 Nov 2026):
      // calendar steps keep midnight wherever the test runs.
      for (final days in [1, 4, 14, 40, 90]) {
        final due = startOfLocalDay(
          DateTime(2026, 10, 24, 22, 30),
          plusDays: days,
        );
        final expected = DateTime(2026, 10, 24 + days);
        expectMidnight(due, expected.year, expected.month, expected.day);
      }
    });

    test('UTC input is converted to the local day first', () {
      final local = DateTime(2026, 10, 3, 12);
      expect(startOfLocalDay(local.toUtc()), DateTime(2026, 10, 3));
    });
  });

  group('first contact (box 0)', () {
    test('clean → box 3 (14 days)', () {
      final r = schedule(0);
      expect(r.boxAfter, 3);
      expectMidnight(r.dueAtAfter, 2026, 10, 17);
    });

    test('error, "Wort erfahren" or synonym hint → box 1, next day', () {
      for (final r in [
        schedule(0, errors: 1),
        schedule(0, revealed: true),
        schedule(0, hint: true),
      ]) {
        expect(r.boxAfter, 1);
        expectMidnight(r.dueAtAfter, 2026, 10, 4);
      }
    });
  });

  group('regular review (deck, mixed)', () {
    test('clean moves up one box, box 5 stays with a new due date', () {
      expect(schedule(1).boxAfter, 2);
      expect(schedule(4, mode: ReviewMode.mixed).boxAfter, 5);
      final top = schedule(5);
      expect(top.boxAfter, 5);
      expectMidnight(top.dueAtAfter, 2027, 1, 1); // 90 days
    });

    test('error or synonym hint → box 1 from any box', () {
      for (final box in [1, 2, 3, 4, 5]) {
        expect(schedule(box, errors: 2).boxAfter, 1);
        expect(schedule(box, hint: true).boxAfter, 1);
        expect(schedule(box, revealed: true).boxAfter, 1);
      }
    });
  });

  group('early practice (Stapel-Revue, Vorab-Üben)', () {
    final before = DateTime(2026, 10, 20);

    test('clean keeps box and due date', () {
      for (final mode in [ReviewMode.revue, ReviewMode.early]) {
        final r = schedule(3, mode: mode, dueBefore: before);
        expect(r.boxAfter, 3);
        expect(r.dueAtAfter, before);
      }
    });

    test('error or synonym hint → box 1, due the next day', () {
      for (final mode in [ReviewMode.revue, ReviewMode.early]) {
        for (final r in [
          schedule(4, mode: mode, errors: 1, dueBefore: before),
          schedule(4, mode: mode, hint: true, dueBefore: before),
          schedule(1, mode: mode, hint: true, dueBefore: before),
        ]) {
          expect(r.boxAfter, 1);
          expectMidnight(r.dueAtAfter, 2026, 10, 4);
        }
      }
    });
  });

  test('configured box-1 interval applies instead of the default', () {
    final r = scheduleReview(
      boxBefore: 4,
      dueAtBefore: DateTime(2026, 10, 1),
      mode: ReviewMode.deck,
      errorCount: 0,
      revealed: false,
      hintUsed: true,
      answeredAt: answered,
      schedule: const LeitnerSchedule([2, 4, 14, 40, 90]),
    );
    expectMidnight(r.dueAtAfter, 2026, 10, 5);
  });

  test('invalid input is rejected', () {
    expect(() => schedule(6), throwsRangeError);
    expect(() => schedule(2, errors: -1), throwsArgumentError);
    expect(
      () => scheduleReview(
        boxBefore: 2,
        dueAtBefore: null,
        mode: ReviewMode.revue,
        errorCount: 0,
        revealed: false,
        hintUsed: false,
        answeredAt: answered,
      ),
      throwsArgumentError,
    );
  });

  test('the placeholder Wortliste rule is unchanged', () {
    expect(nextLeitnerBox(2, correct: true), 3);
    expect(nextLeitnerBox(3, correct: true, early: true), 3);
    expect(nextLeitnerBox(4, correct: false), 1);
  });
}
