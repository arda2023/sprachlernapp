import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/notification_schedule.dart';
import 'notification_gateway.dart';

class LocalNotificationGateway implements NotificationGateway {
  final _plugin = FlutterLocalNotificationsPlugin();
  final _taps = StreamController<String>.broadcast();
  Future<void>? _initializing;

  @override
  bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  @override
  Future<void> initialize() => _initializing ??= _initialize();

  Future<void> _initialize() async {
    if (!supported) return;
    tz_data.initializeTimeZones();
    try {
      // iOS returns the permission-request result here: false is expected
      // when all automatic permission requests are disabled.
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_notification'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload != null && !_taps.isClosed) _taps.add(payload);
        },
      );
    } catch (_) {
      _initializing = null;
      rethrow;
    }
  }

  @override
  Future<NotificationPermission> readPermission() async {
    if (!supported) return NotificationPermission.denied;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final status = await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.checkPermissions();
      return status == null
          ? NotificationPermission.unknown
          : status.isEnabled && status.isAlertEnabled
          ? NotificationPermission.allowed
          : NotificationPermission.denied;
    }
    final allowed = await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.areNotificationsEnabled();
    return allowed == null
        ? NotificationPermission.unknown
        : allowed
        ? NotificationPermission.allowed
        : NotificationPermission.denied;
  }

  @override
  Future<NotificationPermission> requestPermission() async {
    if (!supported) return NotificationPermission.denied;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, sound: true);
    } else {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }
    return readPermission();
  }

  @override
  Future<String> localTimezone() async =>
      (await FlutterTimezone.getLocalTimezone()).identifier;

  @override
  Future<String?> launchPayload() async {
    if (!supported) return null;
    final details = await _plugin.getNotificationAppLaunchDetails();
    return details?.didNotificationLaunchApp == true
        ? details?.notificationResponse?.payload
        : null;
  }

  @override
  Stream<String> get taps => _taps.stream;

  @override
  Future<void> cancelOwned() async {
    if (!supported) return;
    // Cancel removes delivered notifications as well as pending requests.
    for (var day = 0; day < learningReminderHorizon; day++) {
      await _plugin.cancel(id: learningNotificationFirstId + day);
    }
    await _plugin.cancel(id: trialNotificationId);
  }

  @override
  Future<void> schedule(ScheduledLocalNotification notification) async {
    if (!supported) return;
    await _plugin.zonedSchedule(
      id: notification.id,
      title: notification.title,
      body: notification.body,
      scheduledDate: tz.TZDateTime.from(
        notification.at,
        reminderLocation(notification.timezone),
      ),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'learning_reminders',
          'Lernen und Testphase',
          channelDescription: 'Lern-Erinnerungen und das Ende deiner Testphase',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: 'ic_notification',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBadge: false,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: notification.payload,
    );
  }

  @override
  Future<void> openSettings() async {
    if (!supported) return;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.openAppNotificationSettings();
    } else {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.openAppNotificationSettings();
    }
  }

  @override
  void dispose() => unawaited(_taps.close());
}
