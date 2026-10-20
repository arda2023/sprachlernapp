import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/domain/streak.dart';

void main() {
  final today = DateTime(2026, 10, 20, 15);
  List<DateTime> lastDays(int count, {int endingDaysAgo = 0}) => [
    for (var i = 0; i < count; i++)
      DateTime(2026, 10, 20 - endingDaysAgo - i, 9),
  ];

  test('no reviews: empty bar, no cross, no streak', () {
    final s = summarizeStreak(const [], today);
    expect(s.current, 0);
    expect(s.barFilled, 0);
    expect(s.barMissed, isFalse);
    expect(s.weeks, 0);
  });

  test('one exercise today starts the streak', () {
    final s = summarizeStreak([DateTime(2026, 10, 20, 8)], today);
    expect(s.current, 1);
    expect(s.barFilled, 1);
    expect(s.practicedToday, isTrue);
    expect(s.daysToStar, 6);
  });

  test('today still open keeps yesterday\'s streak alive', () {
    final s = summarizeStreak(lastDays(4, endingDaysAgo: 1), today);
    expect(s.current, 4);
    expect(s.barFilled, 4);
    expect(s.barMissed, isFalse);
    expect(s.practicedToday, isFalse);
  });

  test('seventh day lights the star today', () {
    final s = summarizeStreak(lastDays(7), today);
    expect(s.current, 7);
    expect(s.starToday, isTrue);
    expect(s.barFilled, streakBarDays);
    expect(s.weeks, 1);
    expect(s.latestStar, DateTime(2026, 10, 20));
  });

  test('the day after a star starts an empty week', () {
    final s = summarizeStreak(lastDays(7, endingDaysAgo: 1), today);
    expect(s.current, 7);
    expect(s.starToday, isFalse);
    expect(s.barFilled, 0);
    expect(s.daysToStar, 7);
  });

  test('a missed day resets the streak but keeps the stars', () {
    // 10 days in a row (one star), ending three days ago.
    final s = summarizeStreak(lastDays(10, endingDaysAgo: 3), today);
    expect(s.current, 0);
    expect(s.weeks, 1);
    expect(s.barMissed, isTrue);
    expect(s.barFilled, 3); // day 8–10 of the broken run, then the cross
  });

  test('practising again after a gap starts the bar from the left', () {
    final days = [...lastDays(10, endingDaysAgo: 3), DateTime(2026, 10, 20, 7)];
    final s = summarizeStreak(days, today);
    expect(s.current, 1);
    expect(s.barMissed, isFalse);
    expect(s.barFilled, 1);
    expect(s.weeks, 1);
  });

  test('two full weeks earn two stars; future days are ignored', () {
    final s = summarizeStreak([...lastDays(14), DateTime(2026, 10, 25)], today);
    expect(s.weeks, 2);
    expect(s.current, 14);
    expect(s.starToday, isTrue);
  });
}
