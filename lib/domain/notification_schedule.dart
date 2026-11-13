import 'package:timezone/timezone.dart' as tz;

const learningReminderHorizon = 30;

/// Some operating systems return UTC/GMT aliases that are not entries in the
/// bundled IANA database. Unknown geographical zones must still fail closed.
tz.Location reminderLocation(String name) =>
    const {'UTC', 'GMT', 'Etc/UTC', 'Etc/GMT'}.contains(name)
    ? tz.UTC
    : tz.getLocation(name);

/// Calendar reminders, not elapsed 24-hour intervals. A missing local time
/// moves to the first valid minute that day. A repeated time uses its first
/// occurrence, even when the second occurrence would still be in the future.
List<DateTime> learningReminderTimes({
  required DateTime now,
  required tz.Location location,
  required int hour,
  required int minute,
  required bool goalReachedToday,
  int days = learningReminderHorizon,
}) {
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
    throw ArgumentError('Invalid reminder time.');
  }
  if (days < 0 || days > learningReminderHorizon) {
    throw ArgumentError('Invalid reminder horizon.');
  }
  final localNow = tz.TZDateTime.from(now, location);
  final result = <DateTime>[];
  for (var day = 0; day < days; day++) {
    if (day == 0 && goalReachedToday) continue;
    final date = DateTime.utc(
      localNow.year,
      localNow.month,
      localNow.day + day,
    );
    final candidate = _firstLocalMinute(date, hour * 60 + minute, location);
    if (candidate != null && candidate.isAfter(now)) result.add(candidate);
  }
  return result;
}

DateTime? _firstLocalMinute(DateTime date, int minute, tz.Location location) {
  final offsets = location.zones.map((zone) => zone.offset).toSet();
  for (var wallMinute = minute; wallMinute < 24 * 60; wallMinute++) {
    final wall = date.add(Duration(minutes: wallMinute));
    DateTime? first;
    for (final offset in offsets) {
      final candidate = wall.subtract(offset);
      final local = tz.TZDateTime.from(candidate, location);
      if (local.year == date.year &&
          local.month == date.month &&
          local.day == date.day &&
          local.hour == wallMinute ~/ 60 &&
          local.minute == wallMinute % 60 &&
          (first == null || candidate.isBefore(first))) {
        first = candidate;
      }
    }
    if (first != null) return first;
  }
  // Some zones have skipped an entire calendar date. Never borrow the next
  // day's reminder and accidentally schedule two notifications on that date.
  return null;
}

class LearningReminderSettings {
  const LearningReminderSettings({
    this.enabled = false,
    this.hour = 19,
    this.minute = 0,
    this.askedTrial,
  });

  final bool enabled;
  final int hour;
  final int minute;
  final String? askedTrial;

  LearningReminderSettings copyWith({
    bool? enabled,
    int? hour,
    int? minute,
    String? askedTrial,
  }) => LearningReminderSettings(
    enabled: enabled ?? this.enabled,
    hour: hour ?? this.hour,
    minute: minute ?? this.minute,
    askedTrial: askedTrial ?? this.askedTrial,
  );

  factory LearningReminderSettings.fromJson(Object? value) {
    if (value is! Map) return const LearningReminderSettings();
    final hour = value['hour'];
    final minute = value['minute'];
    return LearningReminderSettings(
      enabled: value['enabled'] == true,
      hour: hour is int && hour >= 0 && hour <= 23 ? hour : 19,
      minute: minute is int && minute >= 0 && minute <= 59 ? minute : 0,
      askedTrial: value['askedTrial'] is String
          ? value['askedTrial'] as String
          : null,
    );
  }

  Map<String, Object?> toJson() => {
    'enabled': enabled,
    'hour': hour,
    'minute': minute,
    'askedTrial': askedTrial,
  };
}
