// Pure Dart: no Flutter imports (see CLAUDE.md, domain layer).

import 'srs_state.dart';

/// Number of Leitner boxes in v1; box 5 is "gemeistert" (PRODUCT.md).
const leitnerBoxCount = 5;

/// Default review intervals per box, about 1 / 4 / 14 / 40 / 90 days
/// (PRODUCT.md). Tunable later; the engine interface will own them.
const leitnerIntervals = [
  Duration(days: 1),
  Duration(days: 4),
  Duration(days: 14),
  Duration(days: 40),
  Duration(days: 90),
];

/// Time until the next review for a word in [box] (1–5).
Duration leitnerInterval(int box) {
  RangeError.checkValueInInterval(box, 1, leitnerBoxCount, 'box');
  return leitnerIntervals[box - 1];
}

/// Whole calendar days between [earlier] and [later], ignoring the time of
/// day and DST shifts.
int calendarDaysBetween(DateTime earlier, DateTime later) => DateTime.utc(
  later.year,
  later.month,
  later.day,
).difference(DateTime.utc(earlier.year, earlier.month, earlier.day)).inDays;

/// Box after a review (PRODUCT.md): a right answer moves the word up one box
/// (at most box 5), an error – a wrong attempt or "Wort erfahren" – sends it
/// back to box 1. In early practice ("Vorab-Üben", the Stapel-Revue) a right
/// answer keeps the box; errors still reset it.
int nextLeitnerBox(int box, {required bool correct, bool early = false}) {
  RangeError.checkValueInInterval(box, 1, leitnerBoxCount, 'box');
  if (!correct) return 1;
  if (early) return box;
  return box == leitnerBoxCount ? box : box + 1;
}

/// Review intervals in calendar days per box 1–5 (docs/srs.md); the
/// defaults match [leitnerIntervals].
class LeitnerSchedule {
  const LeitnerSchedule([this.intervalDays = const [1, 4, 14, 40, 90]]);

  final List<int> intervalDays;

  int daysFor(int box) {
    RangeError.checkValueInInterval(box, 1, leitnerBoxCount, 'box');
    if (intervalDays.length != leitnerBoxCount) {
      throw StateError(
        'need $leitnerBoxCount intervals, got ${intervalDays.length}',
      );
    }
    return intervalDays[box - 1];
  }
}

/// Midnight at the start of the local calendar day of [moment], shifted by
/// [plusDays] calendar days. Built from the calendar date, not by adding
/// 24-hour steps, so a daylight-saving change in between doesn't move it.
DateTime startOfLocalDay(DateTime moment, {int plusDays = 0}) {
  final local = moment.toLocal();
  return DateTime(local.year, local.month, local.day + plusDays);
}

/// Box and due date after the first pass of a card (PRODUCT.md, docs/srs.md):
/// - legacy penalizing help ([hintUsed]) → box 1; neutral synonyms never set it;
/// - an error ([errorCount] > 0) or "Wort erfahren" ([revealed]) → box 1;
/// - otherwise clean ("Fast richtig" before the exact form included): first
///   contact (box 0) → box 3; Revue and Vorab-Üben keep box and due date;
///   a regular review moves up one box (at most 5).
/// The due date is the start of the local day [answeredAt] + the interval of
/// the new box; unchanged boxes in early practice keep [dueAtBefore].
({int boxAfter, DateTime dueAtAfter}) scheduleReview({
  required int boxBefore,
  required DateTime? dueAtBefore,
  required ReviewMode mode,
  required int errorCount,
  required bool revealed,
  required bool hintUsed,
  required DateTime answeredAt,
  LeitnerSchedule schedule = const LeitnerSchedule(),
}) {
  RangeError.checkValueInInterval(boxBefore, 0, leitnerBoxCount, 'boxBefore');
  if (errorCount < 0) throw ArgumentError.value(errorCount, 'errorCount');
  ({int boxAfter, DateTime dueAtAfter}) to(int box) => (
    boxAfter: box,
    dueAtAfter: startOfLocalDay(answeredAt, plusDays: schedule.daysFor(box)),
  );
  if (hintUsed || errorCount > 0 || revealed) return to(1);
  if (boxBefore == 0) return to(3);
  if (mode.isEarlyPractice) {
    if (dueAtBefore == null) {
      throw ArgumentError('a seen card (box $boxBefore) needs its due date');
    }
    return (boxAfter: boxBefore, dueAtAfter: dueAtBefore);
  }
  return to(boxBefore == leitnerBoxCount ? boxBefore : boxBefore + 1);
}
