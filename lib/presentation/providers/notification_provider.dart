import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/notifications/local_notification_gateway.dart';
import '../../data/notifications/notification_gateway.dart';
import '../../data/platform/json_store.dart';
import '../../data/platform/json_store_base.dart';
import '../../domain/review_activity.dart';
import '../notifications/notification_service.dart';
import 'app_launch_intent_provider.dart';
import 'auth_providers.dart';
import 'billing_provider.dart';
import 'database_providers.dart';
import 'deck_providers.dart';
import 'language_selection_provider.dart';
import 'learning_providers.dart';
import 'purchase_provider.dart';
import 'user_changes_provider.dart';

export '../notifications/notification_service.dart'
    show LearningReminderScope, NotificationState;

final notificationGatewayProvider = Provider<NotificationGateway>((ref) {
  final gateway = LocalNotificationGateway();
  ref.onDispose(gateway.dispose);
  return gateway;
});

final notificationSettingsStoreProvider = Provider<JsonStore>(
  (ref) => platformJsonStore('notification_settings'),
);

final notificationLatestReviewProvider = FutureProvider<DateTime?>((ref) async {
  ref.watch(userChangesProvider);
  // A resume or local midnight can change the relevant date even without sync.
  ref.watch(learningNowProvider);
  final now = ref.watch(clockProvider)().toLocal();
  final user = await ref.watch(userRepositoryProvider.future);
  final activity = await user.activityBetween(
    now.subtract(const Duration(days: 8)),
    DateTime(now.year, now.month, now.day + 1),
  );
  DateTime? latest;
  for (final review in activity) {
    if (latest == null || review.at.isAfter(latest)) latest = review.at;
  }
  return latest;
}, retry: (_, _) => null);

final notificationProvider =
    NotifierProvider<NotificationController, NotificationState>(
      NotificationController.new,
    );

class NotificationController extends Notifier<NotificationState> {
  late NotificationService _service;
  bool _updateQueued = false;

  @override
  NotificationState build() {
    final gateway = ref.watch(notificationGatewayProvider);
    _service = NotificationService(
      gateway: gateway,
      store: ref.watch(notificationSettingsStoreProvider),
      now: ref.watch(clockProvider),
      onChanged: (next) {
        if (ref.mounted) state = next;
      },
      onLaunch: (intent) {
        if (ref.mounted) {
          ref.read(appLaunchIntentProvider.notifier).publish(intent);
        }
      },
    );
    final service = _service;
    ref.onDispose(service.dispose);
    if (gateway.supported) {
      final observer = _NotificationLifecycleObserver((lifecycle) {
        if (lifecycle == AppLifecycleState.resumed) {
          unawaited(refresh());
        } else {
          _queueUpdate();
        }
      });
      WidgetsBinding.instance.addObserver(observer);
      ref.onDispose(() => WidgetsBinding.instance.removeObserver(observer));
      ref.listen(accountSessionProvider, (_, _) => _queueUpdate());
      ref.listen(selectedContentLanguageProvider, (_, _) => _queueUpdate());
      ref.listen(languageSelectionProvider, (_, _) => _queueUpdate());
      ref.listen(learningProgressProvider, (_, _) => _queueUpdate());
      ref.listen(notificationLatestReviewProvider, (_, _) => _queueUpdate());
      ref.listen(vocabBreakdownProvider, (_, _) => _queueUpdate());
      _queueUpdate();
    }
    return NotificationState(supported: gateway.supported);
  }

  void _queueUpdate() {
    if (_updateQueued) return;
    _updateQueued = true;
    scheduleMicrotask(() {
      _updateQueued = false;
      if (!ref.mounted) return;
      unawaited(_service.update(_context()));
    });
  }

  NotificationContext _context() {
    final account = ref.read(accountSessionProvider);
    if (account.isLoading || account.hasError) {
      return const NotificationContext();
    }
    final language = ref.read(selectedContentLanguageProvider);
    final switching = ref.read(languageSelectionProvider).switching;
    final languageReady = !switching && !language.isLoading;
    final selected = languageReady && !language.hasError
        ? language.asData?.value
        : null;
    final progress = ref.read(learningProgressProvider);
    final goal = !progress.isLoading && !progress.hasError
        ? progress.asData?.value.goal
        : null;
    final review = ref.read(notificationLatestReviewProvider);
    final reviewsReady = !review.isLoading && !review.hasError;
    final vocabulary = ref.read(vocabBreakdownProvider);
    return NotificationContext(
      ownerKey: notificationOwnerKey(account.value?.id),
      language: selected,
      routingReady: languageReady,
      canRequestPermission:
          WidgetsBinding.instance.lifecycleState == null ||
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed,
      goalReachedToday: selected != null && goal != null && reviewsReady
          ? goal.done >= goal.target
          : null,
      latestReviewAt: reviewsReady ? review.asData?.value : null,
      hasDueReviews:
          !vocabulary.isLoading && (vocabulary.asData?.value.due ?? 0) > 0,
    );
  }

  Future<void> refresh() async {
    if (!ref.mounted || !_service.gateway.supported) return;
    await _service.update(_context());
    if (!ref.mounted || ref.read(purchaseProvider).phase.isBusy) return;
    // Native resume also refreshes existing subscription entitlements.
    await ref.read(billingProvider.notifier).refresh();
    if (!ref.mounted) return;
    await ref.read(purchaseProvider.notifier).refresh();
  }

  Future<void> setLearningPurpose(String? purpose, {String? language}) {
    if (!_service.gateway.supported) return Future.value();
    // The callback can run in the same frame as a session change, before
    // the queued observer has copied the new owner into the scheduler.
    unawaited(_service.update(_context()));
    return _service.setLearningPurpose(purpose, language: language);
  }

  Future<bool> claimLearningInvitation(LearningReminderScope scope) =>
      _service.claimLearningInvitation(scope);

  Future<void> enableFromInvitation(LearningReminderScope scope) =>
      _service.setLearningEnabled(true, invitationScope: scope);

  Future<void> setLearningEnabled(bool enabled) =>
      _service.setLearningEnabled(enabled);
  Future<void> setLearningTime(int hour, int minute) =>
      _service.setLearningTime(hour, minute);
  Future<void> openSettings() => _service.openSettings();
}

class _NotificationLifecycleObserver extends WidgetsBindingObserver {
  _NotificationLifecycleObserver(this.onChange);
  final ValueChanged<AppLifecycleState> onChange;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    onChange(state);
  }
}
