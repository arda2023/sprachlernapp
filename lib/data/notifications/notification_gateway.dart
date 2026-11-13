enum NotificationPermission { unknown, denied, allowed }

const learningNotificationFirstId = 410000;
const trialNotificationId = 410100;

class ScheduledLocalNotification {
  const ScheduledLocalNotification({
    required this.id,
    required this.at,
    required this.timezone,
    required this.title,
    required this.body,
    required this.payload,
  });
  final int id;
  final DateTime at;
  final String timezone;
  final String title;
  final String body;
  final String payload;
}

abstract interface class NotificationGateway {
  bool get supported;
  Future<void> initialize();
  Future<NotificationPermission> readPermission();
  Future<NotificationPermission> requestPermission();
  Future<String> localTimezone();
  Future<String?> launchPayload();
  Stream<String> get taps;
  Future<void> cancelOwned();
  Future<void> schedule(ScheduledLocalNotification notification);
  Future<void> openSettings();
  void dispose();
}
