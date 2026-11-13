import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../data/notifications/notification_gateway.dart';
import '../../data/platform/json_store_base.dart';
import '../../domain/app_launch_intent.dart';
import '../../domain/notification_schedule.dart';
import '../../domain/trial_reminder.dart';

String notificationOwnerKey(String? accountId) => sha256
    .convert(utf8.encode(accountId == null ? 'guest' : 'account:$accountId'))
    .toString();

class NotificationContext {
  const NotificationContext({
    this.ownerKey,
    this.language,
    this.routingReady = false,
    this.canRequestPermission = true,
    this.goalReachedToday,
    this.trial = const TrialReminderDecision(TrialReminderStatus.inactive),
  });

  /// Null while the account session is being restored or cannot be verified.
  final String? ownerKey;
  final String? language;
  final bool routingReady;
  final bool canRequestPermission;
  final bool? goalReachedToday;
  final TrialReminderDecision trial;
}

class NotificationState {
  const NotificationState({
    required this.supported,
    this.ready = false,
    this.settings = const LearningReminderSettings(),
    this.permission = NotificationPermission.unknown,
    this.trialStatus = TrialReminderStatus.inactive,
    this.scheduledTrial,
    this.error,
  });

  final bool supported;
  final bool ready;
  final LearningReminderSettings settings;
  final NotificationPermission permission;
  final TrialReminderStatus trialStatus;
  final TrialReminderPlan? scheduledTrial;
  final String? error;

  bool get learningEnabled =>
      settings.enabled && permission == NotificationPermission.allowed;
}

/// One queue owns every native mutation. A changed account or language
/// invalidates in-flight work, including the completion of a native prompt.
class NotificationService {
  NotificationService({
    required this.gateway,
    required this.store,
    required this.now,
    required this.onChanged,
    required this.onLaunch,
  }) {
    _tapSubscription = gateway.taps.listen(_receiveTap);
  }

  final NotificationGateway gateway;
  final JsonStore store;
  final DateTime Function() now;
  final void Function(NotificationState) onChanged;
  final void Function(AppLaunchIntent) onLaunch;
  final Map<String, LearningReminderSettings> _settings = {};
  late final StreamSubscription<String> _tapSubscription;
  Future<void> _operations = Future<void>.value();
  NotificationContext _context = const NotificationContext();
  NotificationPermission _permission = NotificationPermission.unknown;
  TrialReminderPlan? _scheduledTrial;
  TrialReminderStatus _trialStatus = TrialReminderStatus.inactive;
  Timer? _trialTimer;
  bool _initialized = false;
  bool _loaded = false;
  bool _disposed = false;
  int _generation = 0;
  String? _lastSignature;
  String? _error;
  String? _pendingPayload;
  String? _lastHandledPayload;
  String? _purchaseOwner;
  DateTime? _purchaseAt;

  LearningReminderSettings get _currentSettings =>
      _settings[_context.ownerKey] ?? const LearningReminderSettings();

  Future<void> update(
    NotificationContext context, {
    bool purchaseSucceeded = false,
  }) {
    if (_disposed) return Future.value();
    final ownerChanged = context.ownerKey != _context.ownerKey;
    _context = context;
    final generation = ++_generation;
    if (ownerChanged) {
      _scheduledTrial = null;
      _purchaseOwner = null;
      _purchaseAt = null;
      _error = null;
    }
    if (purchaseSucceeded && context.ownerKey != null) {
      _purchaseOwner = context.ownerKey;
      _purchaseAt = now();
    }
    if (_scheduledTrial?.identity != context.trial.plan?.identity) {
      _scheduledTrial = null;
    }
    _trialStatus = context.trial.status;
    _emit();
    _dispatchTap();
    return _enqueue(() => _reconcile(generation));
  }

  Future<void> refresh() => update(_context);

  Future<void> setLearningEnabled(bool enabled) {
    final owner = _context.ownerKey;
    if (owner == null || !gateway.supported || _disposed) return Future.value();
    return _enqueue(() async {
      try {
        await _initialize();
        if (!_isOwner(owner)) return;
        _permission = await gateway.readPermission();
        if (!_isOwner(owner)) return;
        if (enabled && _permission != NotificationPermission.allowed) {
          _permission = await gateway.requestPermission();
          if (!_isOwner(owner)) return;
        }
        final allowed =
            !enabled || _permission == NotificationPermission.allowed;
        _settings[owner] = _currentSettings.copyWith(
          enabled: enabled && allowed,
        );
        await _save();
        if (!_isOwner(owner)) return;
        _error = allowed ? null : 'Mitteilungen in Einstellungen erlauben.';
        await _reconcile(_generation);
      } catch (_) {
        await _failed();
      }
    });
  }

  Future<void> setLearningTime(int hour, int minute) {
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      throw ArgumentError('Invalid reminder time.');
    }
    final owner = _context.ownerKey;
    if (owner == null || !gateway.supported || _disposed) return Future.value();
    return _enqueue(() async {
      try {
        await _initialize();
        if (!_isOwner(owner)) return;
        _settings[owner] = _currentSettings.copyWith(
          hour: hour,
          minute: minute,
        );
        await _save();
        if (!_isOwner(owner)) return;
        _error = null;
        await _reconcile(_generation);
      } catch (_) {
        await _failed();
      }
    });
  }

  Future<void> openSettings() => gateway.openSettings();

  Future<void> _enqueue(Future<void> Function() action) {
    final operation = _operations.then((_) async {
      if (!_disposed) await action();
    });
    _operations = operation.catchError((Object _) {});
    return operation;
  }

  bool _current(int generation) => !_disposed && generation == _generation;
  bool _isOwner(String owner) => !_disposed && _context.ownerKey == owner;

  Future<void> _initialize() async {
    if (!gateway.supported) return;
    if (!_initialized) {
      await gateway.initialize();
      _initialized = true;
      final payload = await gateway.launchPayload();
      if (payload != null) _receiveTap(payload);
    }
    if (!_loaded) {
      final saved = await store.read();
      if (saved is Map) {
        for (final entry in saved.entries) {
          if (entry.key is String) {
            _settings[entry.key as String] = LearningReminderSettings.fromJson(
              entry.value,
            );
          }
        }
      }
      _loaded = true;
    }
  }

  Future<void> _save() => store.write({
    for (final entry in _settings.entries) entry.key: entry.value.toJson(),
  });

  Future<void> _reconcile(int generation) async {
    if (!_current(generation)) return;
    if (!gateway.supported) {
      _emit();
      return;
    }
    try {
      await _initialize();
      if (!_current(generation)) return;
      _permission = await gateway.readPermission();
      if (!_current(generation)) return;
      final context = _context;
      final owner = context.ownerKey;
      var plan = context.trial.plan;
      _trialStatus = context.trial.status;
      if (plan != null && !plan.remindAt.isAfter(now())) {
        plan = null;
        _trialStatus = TrialReminderStatus.tooLate;
      }
      final explicitRecentPurchase =
          owner != null &&
          _purchaseOwner == owner &&
          _purchaseAt != null &&
          now().difference(_purchaseAt!) < const Duration(minutes: 5);
      if (plan != null &&
          explicitRecentPurchase &&
          context.canRequestPermission &&
          _permission != NotificationPermission.allowed &&
          _currentSettings.askedTrial != plan.identity) {
        // Mark the attempt before calling the OS. This serial queue prevents
        // resume/rebuild from asking again; persist the marker after the OS
        // responds so a progress update during disk I/O cannot swallow a
        // prompt that has not actually started. Startup never sets this marker.
        _settings[owner] = _currentSettings.copyWith(askedTrial: plan.identity);
        _permission = await gateway.requestPermission();
        // The saved setting belongs to the captured owner even if the account
        // changed while the native sheet was open. Never schedule for them now.
        await _save();
        if (!_current(generation)) return;
      }
      final scheduled = <ScheduledLocalNotification>[];
      String? zone;
      if (owner != null && _permission == NotificationPermission.allowed) {
        zone = await gateway.localTimezone();
        if (!_current(generation)) return;
        final settings = _currentSettings;
        if (settings.enabled &&
            context.language != null &&
            context.goalReachedToday != null) {
          final times = learningReminderTimes(
            now: now(),
            location: reminderLocation(zone),
            hour: settings.hour,
            minute: settings.minute,
            goalReachedToday: context.goalReachedToday!,
          );
          for (final (index, at) in times.indexed) {
            scheduled.add(
              ScheduledLocalNotification(
                id: learningNotificationFirstId + index,
                at: at,
                timezone: zone,
                title: 'Zeit für ein paar Wörter',
                body: 'Deine nächste Runde wartet.',
                payload: _payload('practice', owner, context.language, at),
              ),
            );
          }
        }
        if (plan != null && plan.remindAt.isAfter(now())) {
          scheduled.add(
            ScheduledLocalNotification(
              id: trialNotificationId,
              at: plan.remindAt,
              timezone: zone,
              title: 'Deine Testphase endet bald',
              body: plan.isSandbox
                  ? 'Dein Testabo verlängert sich in Kürze.'
                  : 'Danach wird dein Abo kostenpflichtig.',
              payload: _payload('home', owner, context.language, plan.remindAt),
            ),
          );
        }
      }
      final signature = jsonEncode([
        owner,
        zone,
        for (final notification in scheduled)
          [
            notification.id,
            notification.at.toIso8601String(),
            notification.payload,
          ],
      ]);
      if (_lastSignature != signature) {
        _scheduledTrial = null;
        _lastSignature = null;
        await gateway.cancelOwned();
        if (!_current(generation)) return;
        for (final notification in scheduled) {
          // A native prompt or slow OS call may have consumed the lead time.
          if (!notification.at.isAfter(now())) continue;
          await gateway.schedule(notification);
          if (!_current(generation)) {
            await gateway.cancelOwned();
            return;
          }
          if (notification.id == trialNotificationId) _scheduledTrial = plan;
        }
        _lastSignature = signature;
      }
      if (plan == null || _permission != NotificationPermission.allowed) {
        _scheduledTrial = null;
      }
      if (_permission == NotificationPermission.allowed) _error = null;
      _trialTimer?.cancel();
      if (_scheduledTrial case final trial?) {
        final wait = trial.remindAt.difference(now());
        if (wait > Duration.zero) {
          _trialTimer = Timer(wait, () => unawaited(refresh()));
        }
      }
      _emit();
    } catch (_) {
      if (_current(generation)) await _failed();
    }
  }

  Future<void> _failed() async {
    _lastSignature = null;
    _scheduledTrial = null;
    try {
      if (_initialized) await gateway.cancelOwned();
    } catch (_) {
      // Keep the error visible; a later refresh will retry cleanup.
    }
    _error = 'Erinnerungen konnten nicht geplant werden.';
    _emit();
  }

  void _emit() {
    if (_disposed) return;
    final plan = _scheduledTrial;
    onChanged(
      NotificationState(
        supported: gateway.supported,
        ready: _loaded && _context.ownerKey != null,
        settings: _currentSettings,
        permission: _permission,
        trialStatus: _trialStatus,
        scheduledTrial: plan != null && plan.remindAt.isAfter(now())
            ? plan
            : null,
        error: _error,
      ),
    );
  }

  String _payload(String target, String owner, String? language, DateTime at) =>
      jsonEncode({
        'v': 1,
        'owner': owner,
        'language': language,
        'target': target,
        'at': at.toUtc().toIso8601String(),
      });

  void _receiveTap(String payload) {
    if (_disposed || !gateway.supported || payload == _lastHandledPayload) {
      return;
    }
    _pendingPayload = payload;
    _dispatchTap();
  }

  void _dispatchTap() {
    final payload = _pendingPayload;
    if (payload == null ||
        !_context.routingReady ||
        _context.ownerKey == null) {
      return;
    }
    _pendingPayload = null;
    _lastHandledPayload = payload;
    var intent = const AppLaunchIntent.home();
    try {
      final value = jsonDecode(payload);
      if (value is Map &&
          value['v'] == 1 &&
          value['owner'] == _context.ownerKey &&
          value['language'] == _context.language &&
          _context.language != null &&
          value['target'] == 'practice') {
        intent = const AppLaunchIntent.practice();
      }
    } catch (_) {
      // Unknown and old payload formats intentionally land on Home.
    }
    onLaunch(intent);
  }

  void dispose() {
    _disposed = true;
    _generation++;
    _trialTimer?.cancel();
    unawaited(_tapSubscription.cancel());
  }
}
