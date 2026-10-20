/// Daily streak and week stars, derived from the local calendar days on which
/// at least one review happened. Nothing here is stored (counters are always
/// derived, see docs/srs.md).
///
/// Rules (Redesign, 20.10.2026):
/// - A day counts as soon as the learner answers one exercise.
/// - A missed day resets the streak to 0; earned stars are kept.
/// - Day 7, 14, 21 … of an unbroken run earns a week star.
library;

/// Slots in the week bar before the star; the star is the seventh day.
const streakBarDays = 6;

class StreakSummary {
  const StreakSummary({
    required this.current,
    required this.starDays,
    required this.activeDays,
    required this.barFilled,
    required this.barMissed,
    required this.starToday,
    required this.practicedToday,
  });

  static const empty = StreakSummary(
    current: 0,
    starDays: {},
    activeDays: {},
    barFilled: 0,
    barMissed: false,
    starToday: false,
    practicedToday: false,
  );

  /// Consecutive days up to today (or yesterday, if today is still open).
  final int current;

  /// Days on which a week star was earned, across all runs.
  final Set<DateTime> starDays;

  /// Every day with at least one review.
  final Set<DateTime> activeDays;

  /// Checked slots of the current bar, 0–6. Seven days show as [starToday].
  final int barFilled;

  /// The previous run broke: the slot after [barFilled] shows a cross until
  /// the learner practises again, then the bar starts over from the left.
  final bool barMissed;

  /// Today completed seven days in a row: the star is lit.
  final bool starToday;

  final bool practicedToday;

  int get weeks => starDays.length;

  /// Days left until the star; 0 once it is lit.
  int get daysToStar => starToday ? 0 : streakBarDays + 1 - barFilled;

  DateTime? get latestStar =>
      starDays.isEmpty ? null : starDays.reduce((a, b) => a.isAfter(b) ? a : b);
}

DateTime calendarDay(DateTime t) => DateTime(t.year, t.month, t.day);

int _daysBetween(DateTime a, DateTime b) => DateTime.utc(
  b.year,
  b.month,
  b.day,
).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

StreakSummary summarizeStreak(Iterable<DateTime> reviewDays, DateTime now) {
  final today = calendarDay(now);
  final days = {
    for (final d in reviewDays)
      if (!calendarDay(d).isAfter(today)) calendarDay(d),
  };
  if (days.isEmpty) return StreakSummary.empty;

  final sorted = days.toList()..sort();
  final stars = <DateTime>{};
  var runLength = 0;
  DateTime? previous;
  for (final day in sorted) {
    final continues = previous != null && _daysBetween(previous, day) == 1;
    runLength = continues ? runLength + 1 : 1;
    if (runLength % (streakBarDays + 1) == 0) stars.add(day);
    previous = day;
  }

  final gap = _daysBetween(sorted.last, today);
  final position = runLength % (streakBarDays + 1);
  final alive = gap <= 1;
  return StreakSummary(
    current: alive ? runLength : 0,
    starDays: stars,
    activeDays: days,
    // A star yesterday means a fresh, empty week today.
    barFilled: gap == 0 && position == 0 ? streakBarDays : position,
    barMissed: !alive,
    starToday: gap == 0 && position == 0,
    practicedToday: gap == 0,
  );
}
