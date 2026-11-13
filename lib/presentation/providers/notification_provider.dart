import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/notifications/local_notification_gateway.dart';
import '../../data/notifications/notification_gateway.dart';
import '../../data/platform/json_store.dart';
import '../../data/platform/json_store_base.dart';
import '../../domain/trial_reminder.dart';
import '../notifications/notification_service.dart';
import 'app_launch_intent_provider.dart';
import 'auth_providers.dart';
import 'billing_provider.dart';
import 'database_providers.dart';
import 'language_selection_provider.dart';
import 'learning_providers.dart';
import 'purchase_provider.dart';

export '../notifications/notification_service.dart' show NotificationState;

final notificationGatewayProvider = Provider<NotificationGateway>((ref) {
  final gateway = LocalNotificationGateway();
  ref.onDispose(gateway.dispose);
  return gateway;
});

final notificationSettingsStoreProvider = Provider<JsonStore>(
  (ref) => platformJsonStore('notification_settings'),
);

final notificationProvider =
    NotifierProvider<NotificationController, NotificationState>(
      NotificationController.new,
    );

class NotificationController extends Notifier<NotificationState> {
  late NotificationService _service;
  bool _updateQueued = false;
  String? _purchaseSucceededOwner;

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
    final observer = _NotificationLifecycleObserver((lifecycle) {
      if (lifecycle == AppLifecycleState.resumed) {
        unawaited(refresh());
      } else {
        _queueUpdate();
      }
    });
    WidgetsBinding.instance.addObserver(observer);
    ref.onDispose(() {
      service.dispose();
      WidgetsBinding.instance.removeObserver(observer);
    });
    ref.listen(accountSessionProvider, (_, _) => _queueUpdate());
    ref.listen(selectedContentLanguageProvider, (_, _) => _queueUpdate());
    ref.listen(languageSelectionProvider, (_, _) => _queueUpdate());
    ref.listen(learningProgressProvider, (_, _) => _queueUpdate());
    ref.listen(billingProvider, (_, _) => _queueUpdate());
    ref.listen(purchaseProvider, (previous, next) {
      if (next.lastOutcome == PurchaseResult.success &&
          previous?.lastOutcome != PurchaseResult.success) {
        final account = ref.read(accountSessionProvider);
        if (!account.isLoading && !account.hasError) {
          _purchaseSucceededOwner = notificationOwnerKey(account.value?.id);
        }
      }
      _queueUpdate();
    });
    _queueUpdate();
    return NotificationState(supported: gateway.supported);
  }

  void _queueUpdate() {
    if (_updateQueued) return;
    _updateQueued = true;
    scheduleMicrotask(() {
      _updateQueued = false;
      if (!ref.mounted) return;
      final context = _context();
      final purchased =
          _purchaseSucceededOwner != null &&
          _purchaseSucceededOwner == context.ownerKey;
      _purchaseSucceededOwner = null;
      unawaited(_service.update(context, purchaseSucceeded: purchased));
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
    final billing = ref.read(billingProvider);
    final purchase = ref.read(purchaseProvider);
    return NotificationContext(
      ownerKey: notificationOwnerKey(account.value?.id),
      language: selected,
      routingReady: languageReady,
      canRequestPermission:
          WidgetsBinding.instance.lifecycleState == null ||
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed,
      goalReachedToday: selected != null && goal != null
          ? goal.done >= goal.target
          : null,
      trial: trialReminderDecision(
        now: ref.read(clockProvider)(),
        subscription: billing.phase == BillingPhase.ready
            ? billing.trial
            : null,
        purchaseActive: purchase.hasPremiumUiAccess,
        purchaseProductId: purchase.activeProductId,
        purchaseExpiresAt: purchase.expiresAt,
        purchaseWillRenew: purchase.willRenew,
        purchaseEnvironment: purchase.environment,
      ),
    );
  }

  Future<void> refresh() async {
    if (!ref.mounted) return;
    await _service.update(_context());
    if (!ref.mounted) return;
    final purchase = ref.read(purchaseProvider);
    if (!purchase.phase.isBusy) {
      await ref.read(billingProvider.notifier).refresh();
      if (!ref.mounted) return;
      await ref.read(purchaseProvider.notifier).refresh();
      if (!ref.mounted) return;
      await _service.update(_context());
    }
  }

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
