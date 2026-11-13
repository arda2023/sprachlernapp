import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/domain/notification_schedule.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(tz_data.initializeTimeZones);

  List<DateTime> times(
    DateTime now, {
    String zone = 'Europe/Berlin',
    int hour = 19,
    int minute = 0,
    bool done = false,
    int days = 3,
  }) => learningReminderTimes(
    now: now,
    location: reminderLocation(zone),
    hour: hour,
    minute: minute,
    goalReachedToday: done,
    days: days,
  );

  test('today is future only, and completing the goal skips just today', () {
    final now = DateTime.utc(2026, 11, 13, 17);
    expect(times(now).first, DateTime.utc(2026, 11, 13, 18));
    expect(times(now, done: true), times(now).skip(1));
    expect(
      times(DateTime.utc(2026, 11, 13, 18)).first,
      DateTime.utc(2026, 11, 14, 18),
    );
    expect(
      times(DateTime.utc(2026, 11, 13, 19)).first,
      DateTime.utc(2026, 11, 14, 18),
    );
  });

  test(
    'calendar midnight crosses month and year without copying today goal',
    () {
      final before = DateTime.utc(2026, 12, 31, 22, 59);
      expect(times(before, hour: 0).first, DateTime.utc(2026, 12, 31, 23));
      final after = DateTime.utc(2026, 12, 31, 23, 1);
      expect(times(after, hour: 0).first, DateTime.utc(2027, 1, 1, 23));
    },
  );

  test('same absolute instant respects the explicit device timezone', () {
    final now = DateTime.utc(2026, 11, 13, 20);
    expect(times(now, zone: 'UTC').first, DateTime.utc(2026, 11, 14, 19));
    expect(
      times(now, zone: 'America/New_York').first,
      DateTime.utc(2026, 11, 14, 0),
    );
    expect(
      times(now, zone: 'Asia/Tokyo').first,
      DateTime.utc(2026, 11, 14, 10),
    );
  });

  for (final (zone, date, expected) in [
    ('Europe/Berlin', DateTime.utc(2026, 3, 29), DateTime.utc(2026, 3, 29, 1)),
    (
      'America/New_York',
      DateTime.utc(2026, 3, 8, 5),
      DateTime.utc(2026, 3, 8, 7),
    ),
  ]) {
    test('$zone spring gap moves 02:30 to first valid minute', () {
      final result = times(date, zone: zone, hour: 2, minute: 30);
      expect(result.first, expected);
      final next = tz.TZDateTime.from(result[1], tz.getLocation(zone));
      expect((next.hour, next.minute), (2, 30));
    });
  }

  test('autumn overlap selects first instance and never repeats that day', () {
    final first = DateTime.utc(2026, 10, 25, 0, 30);
    expect(
      times(DateTime.utc(2026, 10, 24, 23), hour: 2, minute: 30).first,
      first,
    );
    final afterFirst = times(
      DateTime.utc(2026, 10, 25, 0, 45),
      hour: 2,
      minute: 30,
    );
    expect(afterFirst.first, DateTime.utc(2026, 10, 26, 1, 30));
    final us = times(
      DateTime.utc(2026, 11, 1, 5, 45),
      zone: 'America/New_York',
      hour: 1,
      minute: 30,
    );
    expect(us.first, DateTime.utc(2026, 11, 2, 6, 30));
  });

  test('at most 30 slots and one notification per local calendar day', () {
    final location = tz.getLocation('Europe/Berlin');
    final result = times(
      DateTime.utc(2026, 10, 15),
      hour: 2,
      minute: 30,
      days: 30,
    );
    expect(result, hasLength(30));
    expect(
      result.map((instant) {
        final local = tz.TZDateTime.from(instant, location);
        return (local.year, local.month, local.day);
      }).toSet(),
      hasLength(30),
    );
    expect(() => times(DateTime.utc(2026), days: 64), throwsArgumentError);
    expect(() => times(DateTime.utc(2026), hour: 24), throwsArgumentError);
  });
}
