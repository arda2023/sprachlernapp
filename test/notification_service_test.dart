import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/data/notifications/notification_gateway.dart';
import 'package:sprachapp/data/platform/json_store_base.dart';
import 'package:sprachapp/domain/app_launch_intent.dart';
import 'package:sprachapp/domain/trial_reminder.dart';
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
    TrialReminderDecision? trial,
  }) => NotificationContext(
    ownerKey: notificationOwnerKey(owner),
    language: language,
    routingReady: routingReady,
    canRequestPermission: foreground,
    goalReachedToday: done,
    trial: trial ?? const TrialReminderDecision(TrialReminderStatus.inactive),
  );

  TrialReminderDecision trial() => TrialReminderDecision(
    TrialReminderStatus.ready,
    TrialReminderPlan(
      productId: 'yearly',
      expiresAt: time.add(const Duration(days: 7)),
      remindAt: time.add(const Duration(days: 6)),
      isSandbox: false,
    ),
  );
}

class _DelayedStore extends MemoryJsonStore {
  final writing = Completer<void>();
  final release = Completer<void>();
  @override
  Future<void> write(Object? json) async {
    if (!writing.isCompleted) writing.complete();
    await release.future;
    await super.write(json);
  }
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
      expect(h.gateway.scheduled, hasLength(30));
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
      expect(h.gateway.scheduled, hasLength(29));
      expect(
        h.gateway.scheduled.values.first.at,
        DateTime.utc(2026, 11, 14, 19, 15),
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
      expect(h.gateway.scheduled, hasLength(30));
      expect((await h.store.read()).toString(), isNot(contains('account-a')));
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
    'restore/startup does not ask; explicit confirmed trial asks once',
    () async {
      final h = _Harness();
      final context = h.context(trial: h.trial());
      await h.service.update(context);
      expect(h.gateway.requests, 0);
      expect(h.state.scheduledTrial, isNull);
      await h.service.update(context, purchaseSucceeded: true);
      expect(h.gateway.requests, 1);
      expect(h.gateway.scheduled.keys, [trialNotificationId]);
      expect(h.state.scheduledTrial, isNotNull);
      await h.service.update(context, purchaseSucceeded: true);
      expect(h.gateway.requests, 1);
      await h.service.update(h.context());
      expect(h.gateway.scheduled, isEmpty);
      expect(h.state.scheduledTrial, isNull);
    },
  );

  test(
    'denied trial prompt is persisted and never repeated for that trial',
    () async {
      final h = _Harness();
      h.gateway.requestResult = NotificationPermission.denied;
      final context = h.context(trial: h.trial());
      await h.service.update(context, purchaseSucceeded: true);
      await h.service.update(context, purchaseSucceeded: true);
      expect(h.gateway.requests, 1);
      expect(h.state.scheduledTrial, isNull);
      expect(h.gateway.scheduled, isEmpty);
    },
  );

  test(
    'late trial confirmation waits for foreground before asking permission',
    () async {
      final h = _Harness();
      final trial = h.trial();
      await h.service.update(
        h.context(trial: trial, foreground: false),
        purchaseSucceeded: true,
      );
      expect(h.gateway.requests, 0);
      expect(h.gateway.scheduled, isEmpty);
      await h.service.update(h.context(trial: trial));
      expect(h.gateway.requests, 1);
      expect(h.gateway.scheduled.keys, [trialNotificationId]);
    },
  );

  test(
    'progress while saving a trial prompt marker never loses the prompt',
    () async {
      final store = _DelayedStore();
      final h = _Harness(settingsStore: store);
      final trial = h.trial();
      final starting = h.service.update(
        h.context(trial: trial),
        purchaseSucceeded: true,
      );
      await store.writing.future;
      final progress = h.service.update(h.context(trial: trial, done: true));
      store.release.complete();
      await starting;
      await progress;
      expect(h.gateway.requests, 1);
      expect(h.state.scheduledTrial, isNotNull);
      expect(h.gateway.scheduled.keys, [trialNotificationId]);
    },
  );

  test(
    'trial conversion, elapsed lead and revoked permission remove the promise',
    () async {
      final h = _Harness();
      h.gateway.permission = NotificationPermission.allowed;
      final context = h.context(trial: h.trial());
      await h.service.update(context);
      expect(h.state.scheduledTrial, isNotNull);
      h.gateway.permission = NotificationPermission.denied;
      await h.service.refresh();
      expect(h.gateway.scheduled, isEmpty);
      expect(h.state.scheduledTrial, isNull);
      h.gateway.permission = NotificationPermission.allowed;
      await h.service.refresh();
      h.time = context.trial.plan!.remindAt;
      await h.service.refresh();
      expect(h.state.trialStatus, TrialReminderStatus.tooLate);
      expect(h.gateway.scheduled, isEmpty);
      expect(h.state.scheduledTrial, isNull);
    },
  );

  test(
    'unknown trial data and native failure never show a scheduled promise',
    () async {
      final h = _Harness();
      h.gateway.permission = NotificationPermission.allowed;
      await h.service.update(
        h.context(
          trial: const TrialReminderDecision(TrialReminderStatus.unavailable),
        ),
        purchaseSucceeded: true,
      );
      expect(h.gateway.scheduled, isEmpty);
      expect(h.state.trialStatus, TrialReminderStatus.unavailable);
      expect(h.gateway.requests, 0);
      h.gateway.failSchedule = true;
      await h.service.update(h.context(trial: h.trial()));
      expect(h.state.scheduledTrial, isNull);
      expect(h.state.error, isNotNull);
      expect(h.gateway.scheduled, isEmpty);
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
    await h.service.update(
      h.context(trial: h.trial()),
      purchaseSucceeded: true,
    );
    await h.service.setLearningEnabled(true);
    h.gateway.events.add('{}');
    expect(h.gateway.initializations, 0);
    expect(h.gateway.requests, 0);
    expect(h.gateway.cancellations, 0);
    expect(h.launches, isEmpty);
  });
}
