// Pure Dart: no Flutter imports (see CLAUDE.md, domain layer).

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
