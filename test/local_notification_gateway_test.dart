import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/data/notifications/local_notification_gateway.dart';
import 'package:sprachapp/data/notifications/notification_gateway.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    IOSFlutterLocalNotificationsPlugin.registerWith();
  });
  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  test('iOS initialization false is valid and never requests permission at startup', () async {
    final calls = <MethodCall>[];
    var allowed = false;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      switch (call.method) {
        case 'initialize':
          final args = call.arguments as Map;
          expect(args['requestAlertPermission'], false);
          expect(args['requestSoundPermission'], false);
          expect(args['requestBadgePermission'], false);
          // This is the actual iOS implementation's return value when no
          // permissions are requested, not an initialization failure.
          return false;
        case 'checkPermissions':
          return {'isEnabled': allowed, 'isAlertEnabled': allowed};
        case 'requestPermissions':
          final args = call.arguments as Map;
          expect(args['alert'], true);
          expect(args['sound'], true);
          expect(args['badge'], false);
          allowed = true;
          return true;
      }
      return null;
    });
    final gateway = LocalNotificationGateway();
    addTearDown(gateway.dispose);
    await gateway.initialize();
    expect(await gateway.readPermission(), NotificationPermission.denied);
    expect(calls.where((call) => call.method == 'requestPermissions'), isEmpty);
    expect(await gateway.requestPermission(), NotificationPermission.allowed);
    expect(
      calls.where((call) => call.method == 'requestPermissions'),
      hasLength(1),
    );
  });

  test(
    'only an actual notification launch exposes a cold-start payload',
    () async {
      var launched = false;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'initialize') return false;
        if (call.method == 'getNotificationAppLaunchDetails') {
          return {
            'notificationLaunchedApp': launched,
            'notificationResponse': {
              'notificationResponseType': 0,
              'payload': 'notification-payload',
            },
          };
        }
        return null;
      });
      final gateway = LocalNotificationGateway();
      addTearDown(gateway.dispose);
      await gateway.initialize();
      expect(await gateway.launchPayload(), isNull);
      launched = true;
      expect(await gateway.launchPayload(), 'notification-payload');
    },
  );
}
