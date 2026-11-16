import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../data/notifications/notification_gateway.dart';
import '../../data/platform/json_store_base.dart';
import '../../domain/app_launch_intent.dart';
import '../../domain/learning_reminder_copy.dart';
import '../../domain/notification_schedule.dart';
import '../../domain/trial_reminder.dart';

typedef LearningReminderScope = ({String owner, String language});

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
    this.latestReviewAt,
    this.hasDueReviews = false,
  });

  /// Null while the account session is being restored or cannot be verified.
  final String? ownerKey;
  final String? language;
  final bool routingReady;
  final bool canRequestPermission;
  final bool? goalReachedToday;
  final DateTime? latestReviewAt;
  final bool hasDueReviews;

  LearningReminderScope? get scope {
    final owner = ownerKey;
    final lang = language;
    return owner != null && lang != null
        ? (owner: owner, language: lang)
        : null;
  }
}

class NotificationState {
  const NotificationState({
    required this.supported,
    this.ready = false,
    this.settings = const LearningReminderSettings(),
    this.permission = NotificationPermission.unknown,
    this.trialStatus = TrialReminderStatus.inactive,
    this.scheduledTrial,
    this.scope,
    this.canInvite = false,
    this.error,
  });

  final bool supported;
  final bool ready;
  final LearningReminderSettings settings;
  final NotificationPermission permission;
  final TrialReminderStatus trialStatus;
  final TrialReminderPlan? scheduledTrial;
  final LearningReminderScope? scope;
  final bool canInvite;
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
  final Map<LearningReminderScope, _ReminderCycle> _cycles = {};
  final Map<LearningReminderScope, String> _purposes = {};
  late final StreamSubscription<String> _tapSubscription;
  Future<void> _operations = Future<void>.value();
  NotificationContext _context = const NotificationContext();
  NotificationPermission _permission = NotificationPermission.unknown;
  bool _initialized = false;
  bool _loaded = false;
  bool _cyclesDirty = false;
  bool _disposed = false;
  int _generation = 0;
  String? _lastSignature;
  String? _error;
  String? _pendingPayload;
  String? _lastHandledPayload;

  LearningReminderSettings get _currentSettings =>
      _settings[_context.ownerKey] ?? const LearningReminderSettings();

  Future<void> update(NotificationContext context) {
    if (_disposed) return Future.value();
    final ownerChanged = context.ownerKey != _context.ownerKey;
    _context = context;
    final generation = ++_generation;
    if (ownerChanged) {
      _error = null;
    }
    _emit();
    _dispatchTap();
    return _enqueue(() => _reconcile(generation));
  }

  Future<void> refresh() => update(_context);

  Future<void> setLearningEnabled(
    bool enabled, {
    LearningReminderScope? invitationScope,
  }) {
    final owner = _context.ownerKey;
    if (owner == null || !gateway.supported || _disposed) return Future.value();
    bool canApply() =>
        _isOwner(owner) &&
        (invitationScope == null || invitationScope == _context.scope);
    return _enqueue(() async {
      try {
        await _initialize();
        if (!canApply()) return;
        _permission = await gateway.readPermission();
        if (!canApply()) return;
        if (enabled && _permission != NotificationPermission.allowed) {
          if (!_context.canRequestPermission) return;
          _permission = await gateway.requestPermission();
          if (!canApply()) return;
        }
        final allowed =
            !enabled || _permission == NotificationPermission.allowed;
        if (enabled && allowed && !_currentSettings.enabled) {
          _cycles.removeWhere((scope, _) => scope.owner == owner);
        }
        _settings[owner] = _currentSettings.copyWith(
          enabled: enabled && allowed,
          invitationSeen: true,
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

  /// A real completion surface may claim the device-local invitation once.
  /// Claiming the card never opens the OS dialog.
  Future<bool> claimLearningInvitation(LearningReminderScope scope) async {
    var claimed = false;
    await _enqueue(() async {
      if (!_canInvite || scope != _context.scope) return;
      _settings[scope.owner] = _currentSettings.copyWith(invitationSeen: true);
      try {
        await _save();
        claimed = !_disposed && scope == _context.scope;
      } catch (_) {
        _error = 'Die Einstellung konnte nicht gespeichert werden.';
      }
      _emit();
    });
    return claimed;
  }

  Future<void> setLearningPurpose(String? purpose, {String? language}) {
    final owner = _context.ownerKey;
    final lang = language ?? _context.language;
    if (owner == null || lang == null || !gateway.supported) {
      return Future.value();
    }
    final scope = (owner: owner, language: lang);
    return _enqueue(() async {
      try {
        await _initialize();
        if (!_isOwner(owner)) return;
        if (learningReminderPurposeCode(purpose) case final code?) {
          _purposes[scope] = code;
        } else {
          _purposes.remove(scope);
        }
        await _save();
        if (_isOwner(owner)) await _reconcile(_generation);
      } catch (_) {
        if (_isOwner(owner)) {
          _error = 'Die Einstellung konnte nicht gespeichert werden.';
          _emit();
        }
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
          final owner = entry.key;
          final value = entry.value;
          if (owner is! String || value is! Map) continue;
          _settings[owner] = LearningReminderSettings.fromJson(value);
          final languages = value['languages'];
          if (languages is! Map) continue;
          for (final entry in languages.entries) {
            final language = entry.key;
            final value = entry.value;
            if (language is! String || value is! Map) continue;
            final scope = (owner: owner, language: language);
            if (_ReminderCycle.fromJson(value['cycle']) case final cycle?) {
              _cycles[scope] = cycle;
            }
            if (learningReminderPurposeCode(value['purpose'])
                case final code?) {
              _purposes[scope] = code;
            }
          }
        }
      }
      _loaded = true;
    }
  }

  Future<void> _save() {
    final languages = <String, Map<String, Object?>>{};
    for (final scope in {..._cycles.keys, ..._purposes.keys}) {
      (languages[scope.owner] ??= {})[scope.language] = {
        'purpose': ?_purposes[scope],
        'cycle': ?_cycles[scope]?.toJson(),
      };
    }
    return store.write({
      for (final owner in {..._settings.keys, ...languages.keys})
        owner: {
          ...(_settings[owner] ?? const LearningReminderSettings()).toJson(),
          'languages': ?languages[owner],
        },
    });
  }

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
      final owner = _context.ownerKey;
      final scope = _context.scope;
      String? zone;
      var scheduled = <ScheduledLocalNotification>[];
      if (_permission == NotificationPermission.allowed &&
          _currentSettings.enabled &&
          scope != null &&
          _context.goalReachedToday != null) {
        zone = await gateway.localTimezone();
        if (!_current(generation)) return;
        scheduled = _learningPlan(scope, zone);
      }
      final signature = jsonEncode([
        owner,
        zone,
        for (final notification in scheduled)
          [
            notification.id,
            notification.at.toIso8601String(),
            notification.payload,
            notification.title,
            notification.body,
          ],
      ]);
      final replace = _lastSignature != signature;
      if (replace) {
        _lastSignature = null;
        // The owned range also includes schedules from versions with trials
        // and up to 30 daily learning reminders.
        await gateway.cancelOwned();
        if (!_current(generation)) return;
      }
      if (_cyclesDirty) {
        await _save();
        _cyclesDirty = false;
        if (!_current(generation)) return;
      }
      if (replace) {
        for (final notification in scheduled) {
          // A native prompt or slow OS call may have consumed the lead time.
          if (!notification.at.isAfter(now())) continue;
          await gateway.schedule(notification);
          if (!_current(generation)) {
            await gateway.cancelOwned();
            return;
          }
        }
        _lastSignature = signature;
      }
      if (_permission == NotificationPermission.allowed) _error = null;
      _emit();
    } catch (_) {
      if (_current(generation)) await _failed();
    }
  }

  List<ScheduledLocalNotification> _learningPlan(
    LearningReminderScope scope,
    String zone,
  ) {
    final currentTime = now();
    final location = reminderLocation(zone);
    final today = reminderCalendarDay(currentTime, location);
    final latest = _context.latestReviewAt;
    final skipToday =
        _context.goalReachedToday == true ||
        (latest != null && reminderCalendarDay(latest, location) == today);
    final settings = _currentSettings;
    var cycle = _cycles[scope];
    final lastObserved = cycle?.latestReviewAt;
    if (cycle == null ||
        (latest != null &&
            (lastObserved == null || latest.isAfter(lastObserved)))) {
      final first = learningReminderTimes(
        now: currentTime,
        location: location,
        hour: settings.hour,
        minute: settings.minute,
        goalReachedToday: skipToday,
        days: 3,
      ).firstOrNull;
      if (first == null) return [];
      cycle = _ReminderCycle(reminderCalendarDay(first, location), latest);
      _cycles[scope] = cycle;
      _cyclesDirty = true;
    }
    final reminders = <ScheduledLocalNotification>[];
    for (final (attempt, at) in learningReminderAttempts(
      firstDay: cycle.firstDay,
      location: location,
      hour: settings.hour,
      minute: settings.minute,
    )) {
      final previous = cycle.attempts[attempt];
      // The OS cannot confirm whether a notification was seen. Once its
      // scheduled time passes, assume it may have been delivered.
      if (previous != null && !previous.isAfter(currentTime)) continue;
      final day = reminderCalendarDay(at, location);
      if (day == today && skipToday) {
        _cyclesDirty = cycle.attempts.remove(attempt) != null || _cyclesDirty;
        continue;
      }
      if (previous != at) {
        cycle.attempts[attempt] = at;
        _cyclesDirty = true;
      }
      if (!at.isAfter(currentTime)) continue;
      final copy = learningReminderCopy(
        day: day,
        attempt: attempt,
        hasDueReviews: _context.hasDueReviews,
        purpose: _purposes[scope],
      );
      reminders.add(
        ScheduledLocalNotification(
          id: learningNotificationFirstId + attempt,
          at: at,
          timezone: zone,
          title: copy.title,
          body: copy.body,
          payload: _payload('practice', scope.owner, scope.language, at),
        ),
      );
    }
    return reminders;
  }

  bool get _canInvite =>
      gateway.supported &&
      _loaded &&
      _context.scope != null &&
      _context.canRequestPermission &&
      !_currentSettings.enabled &&
      !_currentSettings.invitationSeen;

  Future<void> _failed() async {
    _lastSignature = null;
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
    onChanged(
      NotificationState(
        supported: gateway.supported,
        ready: _loaded && _context.ownerKey != null,
        settings: _currentSettings,
        permission: _permission,
        scope: _context.scope,
        canInvite: _canInvite,
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
    unawaited(_tapSubscription.cancel());
  }
}

class _ReminderCycle {
  _ReminderCycle(this.firstDay, this.latestReviewAt);

  final DateTime firstDay;
  final DateTime? latestReviewAt;
  final attempts = <int, DateTime>{};

  static _ReminderCycle? fromJson(Object? value) {
    if (value is! Map) return null;
    final day = _readDate(value['firstDay']);
    if (day == null) return null;
    final cycle = _ReminderCycle(day, _readDate(value['latestReviewAt']));
    final attempts = value['attempts'];
    if (attempts is Map) {
      for (var i = 0; i < learningReminderDayOffsets.length; i++) {
        if (_readDate(attempts['$i']) case final at?) cycle.attempts[i] = at;
      }
    }
    return cycle;
  }

  Map<String, Object?> toJson() => {
    'firstDay': firstDay.toIso8601String(),
    'latestReviewAt': latestReviewAt?.toUtc().toIso8601String(),
    'attempts': {
      for (final entry in attempts.entries)
        '${entry.key}': entry.value.toUtc().toIso8601String(),
    },
  };

  static DateTime? _readDate(Object? value) =>
      value is String ? DateTime.tryParse(value)?.toUtc() : null;
}
