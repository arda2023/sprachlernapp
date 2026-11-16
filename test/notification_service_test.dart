import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/data/notifications/notification_gateway.dart';
import 'package:sprachapp/data/platform/json_store_base.dart';
import 'package:sprachapp/domain/app_launch_intent.dart';
import 'package:sprachapp/presentation/notifications/notification_service.dart';
import 'package:timezone/data/latest.dart' as tz_data;

class _Gateway implements NotificationGateway {
  @override
  bool supported = true;
  NotificationPermission permission = NotificationPermission.denied;
  NotificationPermission requestResult = NotificationPermission.allowed;
  final events = StreamController<String>.broadcast(sync: true);
  final scheduled = <int, ScheduledLocalNotification>{};
  int requests = 0;
  int initializations = 0;
  int cancellations = 0;
  String zone = 'Europe/Berlin';
  String? coldPayload;
  Completer<void>? scheduleGate;
  Completer<void>? scheduleStarted;
  bool failSchedule = false;

  @override
  Future<void> initialize() async => initializations++;
  @override
  Future<NotificationPermission> readPermission() async => permission;
  @override
  Future<NotificationPermission> requestPermission() async {
    requests++;
    return permission = requestResult;
  }

  @override
  Future<String> localTimezone() async => zone;
  @override
  Future<String?> launchPayload() async => coldPayload;
  @override
  Stream<String> get taps => events.stream;
  @override
  Future<void> cancelOwned() async {
    cancellations++;
    scheduled.clear();
  }

  @override
  Future<void> schedule(ScheduledLocalNotification notification) async {
    if (failSchedule) throw StateError('native scheduling failed');
    if (scheduleStarted case final started?) {
      scheduleStarted = null;
      started.complete();
    }
    await scheduleGate?.future;
    scheduled[notification.id] = notification;
  }

  @override
  Future<void> openSettings() async {}
  @override
  void dispose() => unawaited(events.close());
}

class _Harness {
  _Harness({JsonStore? settingsStore})
    : store = settingsStore ?? MemoryJsonStore() {
    service = NotificationService(
      gateway: gateway,
      store: store,
      now: () => time,
      onChanged: states.add,
      onLaunch: launches.add,
    );
    addTearDown(() {
      service.dispose();
      gateway.dispose();
    });
  }
  final gateway = _Gateway();
  final JsonStore store;
  final states = <NotificationState>[];
  final launches = <AppLaunchIntent>[];
  DateTime time = DateTime.utc(2026, 11, 13, 10);
  late NotificationService service;
  NotificationState get state => states.last;

  NotificationContext context({
    String owner = 'account-a',
    String? language = 'en',
    bool? done = false,
    bool routingReady = true,
    bool foreground = true,
    DateTime? latestReview,
    bool hasDueReviews = false,
  }) => NotificationContext(
    ownerKey: notificationOwnerKey(owner),
    language: language,
    routingReady: routingReady,
    canRequestPermission: foreground,
    goalReachedToday: done,
    latestReviewAt: latestReview,
    hasDueReviews: hasDueReviews,
  );
}

void main() {
  setUpAll(tz_data.initializeTimeZones);

  test(
    'startup reads permission, enabling asks once and disabling clears',
    () async {
      final h = _Harness();
      await h.service.update(h.context());
      expect(h.gateway.requests, 0);
      expect(h.gateway.scheduled, isEmpty);
      await h.service.setLearningEnabled(true);
      expect(h.gateway.requests, 1);
      expect(h.state.learningEnabled, true);
      expect(h.gateway.scheduled, hasLength(3));
      await h.service.refresh();
      expect(h.gateway.requests, 1);
      await h.service.setLearningEnabled(false);
      expect(h.gateway.scheduled, isEmpty);
      expect(h.state.learningEnabled, false);
    },
  );

  test('denial never reports an enabled or scheduled reminder', () async {
    final h = _Harness();
    h.gateway.requestResult = NotificationPermission.denied;
    await h.service.update(h.context());
    await h.service.setLearningEnabled(true);
    expect(h.state.learningEnabled, false);
    expect(h.gateway.scheduled, isEmpty);
    expect(h.state.error, contains('Einstellungen'));
  });

  test(
    'time, timezone, progress and language replace the current plan',
    () async {
      final h = _Harness();
      await h.service.update(h.context());
      await h.service.setLearningEnabled(true);
      await h.service.setLearningTime(20, 15);
      expect(
        h.gateway.scheduled.values.first.at,
        DateTime.utc(2026, 11, 13, 19, 15),
      );
      await h.service.update(h.context(done: true));
      expect(h.gateway.scheduled, hasLength(2));
      expect(
        h.gateway.scheduled.values.first.at,
        DateTime.utc(2026, 11, 15, 19, 15),
      );
      await h.service.update(
        h.context(language: null, done: null, routingReady: false),
      );
      expect(h.gateway.scheduled, isEmpty);
      h.gateway.zone = 'America/New_York';
      await h.service.update(h.context(language: 'fr'));
      expect(
        h.gateway.scheduled.values.first.at,
        DateTime.utc(2026, 11, 14, 1, 15),
      );
      expect(
        jsonDecode(h.gateway.scheduled.values.first.payload)['language'],
        'fr',
      );
    },
  );

  test(
    'owner preferences are separate and logout clears old schedules',
    () async {
      final h = _Harness();
      await h.service.update(h.context());
      await h.service.setLearningEnabled(true);
      await h.service.setLearningTime(18, 30);
      await h.service.update(h.context(owner: 'account-b'));
      expect(h.gateway.scheduled, isEmpty);
      expect(h.state.settings.hour, 19);
      await h.service.update(const NotificationContext());
      expect(h.gateway.scheduled, isEmpty);
      await h.service.update(h.context());
      expect(h.state.settings.hour, 18);
      expect(h.gateway.scheduled, hasLength(3));
      expect((await h.store.read()).toString(), isNot(contains('account-a')));
    },
  );

  test('the optional purpose stays with its account and language', () async {
    final h = _Harness();
    await h.service.update(h.context());
    await h.service.setLearningPurpose('Reisen');
    await h.service.setLearningEnabled(true);
    expect(h.gateway.scheduled.values.first.title, contains('unterwegs'));

    final reopened = _Harness(settingsStore: h.store);
    reopened.gateway.permission = NotificationPermission.allowed;
    await reopened.service.update(reopened.context(language: 'fr'));
    expect(
      reopened.gateway.scheduled.values.first.title,
      isNot(contains('unterwegs')),
    );

    await reopened.service.update(reopened.context(owner: 'account-b'));
    await reopened.service.setLearningEnabled(true);
    expect(
      reopened.gateway.scheduled.values.first.title,
      isNot(contains('unterwegs')),
    );

    await reopened.service.update(reopened.context());
    expect(
      reopened.gateway.scheduled.values.first.title,
      contains('unterwegs'),
    );
  });

  test(
    'a legacy reminder setting is treated as an existing decision',
    () async {
      final store = MemoryJsonStore();
      await store.write({
        notificationOwnerKey('account-a'): {'enabled': false, 'hour': 17},
      });
      final h = _Harness(settingsStore: store);
      await h.service.update(h.context());
      expect(h.state.canInvite, false);
      expect(h.state.settings.hour, 17);
      expect(h.gateway.requests, 0);
    },
  );

  test(
    'an old schedule completing after account change is cleaned up',
    () async {
      final h = _Harness();
      await h.service.update(h.context());
      final started = Completer<void>();
      h.gateway.scheduleStarted = started;
      final gate = h.gateway.scheduleGate = Completer<void>();
      final enabling = h.service.setLearningEnabled(true);
      await started.future;
      final switching = h.service.update(h.context(owner: 'account-b'));
      gate.complete();
      await enabling;
      await switching;
      expect(h.gateway.scheduled, isEmpty);
      expect(h.state.learningEnabled, false);
    },
  );

  test(
    'expired inactivity cycle stays quiet across refresh and restart',
    () async {
      final h = _Harness();
      await h.service.update(h.context(hasDueReviews: true));
      await h.service.setLearningEnabled(true);
      final initial = h.gateway.scheduled.values.toList();
      expect(initial.map((n) => n.at), [
        DateTime.utc(2026, 11, 13, 18),
        DateTime.utc(2026, 11, 15, 18),
        DateTime.utc(2026, 11, 18, 18),
      ]);
      expect(initial.map((n) => n.title).toSet(), hasLength(3));
      expect(
        initial.first.title,
        anyOf(
          'Wörter zum Wiederholen',
          'Zeit für eine Wiederholung',
          'Schon im Kopf?',
        ),
      );
      h.time = initial[0].at.add(const Duration(minutes: 1));
      await h.service.setLearningTime(21, 0);
      expect(h.gateway.scheduled.keys, hasLength(2));
      expect(
        h.gateway.scheduled.values.first.at,
        DateTime.utc(2026, 11, 15, 20),
      );

      final reopened = _Harness(settingsStore: h.store);
      reopened.gateway.permission = NotificationPermission.allowed;
      reopened.time = h.time.add(const Duration(days: 7));
      await reopened.service.update(reopened.context());
      expect(reopened.state.learningEnabled, true);
      expect(reopened.gateway.scheduled, isEmpty);
      await reopened.service.refresh();
      expect(reopened.gateway.scheduled, isEmpty);

      final review = reopened.time.subtract(const Duration(minutes: 5));
      await reopened.service.update(reopened.context(latestReview: review));
      expect(reopened.gateway.scheduled, hasLength(3));
      expect(
        reopened.gateway.scheduled.values.first.at,
        DateTime.utc(2026, 11, 21, 20),
      );
      await reopened.service.update(reopened.context(latestReview: review));
      expect(reopened.gateway.scheduled, hasLength(3));
    },
  );

  test(
    'synced learning cancels the same-day reminder below the goal',
    () async {
      final h = _Harness();
      await h.service.update(h.context());
      await h.service.setLearningEnabled(true);
      expect(
        h.gateway.scheduled.values.first.at,
        DateTime.utc(2026, 11, 13, 18),
      );
      await h.service.update(h.context(latestReview: h.time));
      expect(
        h.gateway.scheduled.values.first.at,
        DateTime.utc(2026, 11, 14, 18),
      );
      expect(h.gateway.scheduled, hasLength(3));
    },
  );

  test(
    'an invitation is expended once per account and never prompts on claim',
    () async {
      final h = _Harness();
      await h.service.update(h.context(foreground: false));
      final scope = h.state.scope!;
      expect(await h.service.claimLearningInvitation(scope), false);
      await h.service.update(h.context());
      expect(h.state.canInvite, true);
      expect(await h.service.claimLearningInvitation(scope), true);
      expect(h.gateway.requests, 0);
      expect(await h.service.claimLearningInvitation(scope), false);

      final reopened = _Harness(settingsStore: h.store);
      await reopened.service.update(reopened.context(language: 'fr'));
      expect(reopened.state.canInvite, false);
      await reopened.service.setLearningEnabled(true, invitationScope: scope);
      expect(reopened.gateway.requests, 0);

      await reopened.service.update(reopened.context(owner: 'account-b'));
      expect(reopened.state.canInvite, true);
      expect(await reopened.service.claimLearningInvitation(scope), false);
      expect(reopened.gateway.requests, 0);
    },
  );

  test(
    'an old trial is canceled on launch and native failures clean up',
    () async {
      final h = _Harness();
      h.gateway.scheduled[trialNotificationId] = ScheduledLocalNotification(
        id: trialNotificationId,
        at: h.time.add(const Duration(days: 1)),
        timezone: h.gateway.zone,
        title: 'Trial',
        body: '',
        payload: '',
      );
      await h.service.update(h.context());
      expect(h.gateway.scheduled, isEmpty);
      expect(h.gateway.requests, 0);

      h.gateway.failSchedule = true;
      await h.service.setLearningEnabled(true);
      expect(h.state.error, isNotNull);
      expect(h.gateway.scheduled, isEmpty);
      h.gateway.failSchedule = false;
      await h.service.refresh();
      expect(h.gateway.scheduled, hasLength(3));
      expect(h.state.error, isNull);
    },
  );

  test('cold tap waits for identity and language, is consumed once, stale owner goes Home', () async {
    final h = _Harness();
    final payload = jsonEncode({
      'v': 1,
      'owner': notificationOwnerKey('account-a'),
      'language': 'en',
      'target': 'practice',
      'at': 'first',
    });
    h.gateway.coldPayload = payload;
    await h.service.update(const NotificationContext());
    expect(h.launches, isEmpty);
    await h.service.update(h.context(language: null, routingReady: false));
    expect(h.launches, isEmpty);
    await h.service.update(h.context());
    expect(h.launches.single.target, AppLaunchTarget.practice);
    h.gateway.events.add(payload);
    expect(h.launches, hasLength(1));
    await h.service.update(h.context(owner: 'account-b'));
    h.gateway.events.add(payload.replaceFirst('first', 'second'));
    expect(h.launches.last.target, AppLaunchTarget.home);
    h.gateway.events.add('invalid');
    expect(h.launches.last.target, AppLaunchTarget.home);
  });

  test('unsupported platform performs no native calls or navigation', () async {
    final h = _Harness();
    h.gateway.supported = false;
    await h.service.update(h.context());
    await h.service.setLearningEnabled(true);
    h.gateway.events.add('{}');
    expect(h.gateway.initializations, 0);
    expect(h.gateway.requests, 0);
    expect(h.gateway.cancellations, 0);
    expect(h.launches, isEmpty);
  });
}
