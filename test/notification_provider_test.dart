import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/data/notifications/notification_gateway.dart';
import 'package:sprachapp/data/platform/json_store_base.dart';
import 'package:sprachapp/models/home_models.dart';
import 'package:sprachapp/presentation/providers/auth_providers.dart';
import 'package:sprachapp/presentation/providers/billing_provider.dart';
import 'package:sprachapp/presentation/providers/database_providers.dart';
import 'package:sprachapp/presentation/providers/learning_providers.dart';
import 'package:sprachapp/presentation/providers/notification_provider.dart';
import 'package:sprachapp/presentation/providers/purchase_provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

final _now = DateTime.utc(2026, 11, 13, 10);
final _expiry = _now.add(const Duration(days: 7));

class _Gateway implements NotificationGateway {
  int prompts = 0;
  NotificationPermission permission = NotificationPermission.denied;
  final scheduled = <ScheduledLocalNotification>[];
  @override
  bool get supported => true;
  @override
  Future<void> initialize() async {}
  @override
  Future<NotificationPermission> readPermission() async => permission;
  @override
  Future<NotificationPermission> requestPermission() async {
    prompts++;
    return permission = NotificationPermission.allowed;
  }

  @override
  Future<String> localTimezone() async => 'Europe/Berlin';
  @override
  Future<String?> launchPayload() async => null;
  @override
  Stream<String> get taps => const Stream.empty();
  @override
  Future<void> cancelOwned() async => scheduled.clear();
  @override
  Future<void> schedule(ScheduledLocalNotification notification) async =>
      scheduled.add(notification);
  @override
  Future<void> openSettings() async {}
  @override
  void dispose() {}
}

class _Billing extends BillingController {
  @override
  BillingState build() => BillingState(
    BillingPhase.ready,
    premiumActive: true,
    activeProductId: 'yearly',
    expiresAt: _expiry,
    trial: (
      productId: 'yearly',
      introductoryOfferType: 'free_trial',
      expiresAt: _expiry,
      willRenew: true,
      isSandbox: false,
      isRefunded: false,
      isInGracePeriod: false,
      isLifetime: false,
      dataConsistent: true,
    ),
  );
  @override
  Future<void> refresh() async {}
}

class _Purchases extends PurchaseController {
  _Purchases({this.initiallyActive = false});
  final bool initiallyActive;
  @override
  PurchaseState build() =>
      initiallyActive ? _confirmed(null) : const PurchaseState();
  @override
  Future<void> refresh() async {}
  void successWhileServerLoads() => state = const PurchaseState(
    lastOutcome: PurchaseResult.success,
    isSyncing: true,
  );
  void confirm({PurchaseResult? outcome}) =>
      state = _confirmed(outcome ?? state.lastOutcome);
  PurchaseState _confirmed(PurchaseResult? outcome) => PurchaseState(
    phase: PurchasePhase.ready,
    hasVerifiedAccount: true,
    billingReady: true,
    premiumActive: true,
    activeProductId: 'yearly',
    expiresAt: _expiry,
    willRenew: true,
    environment: 'Production',
    syncedAt: _now,
    lastOutcome: outcome,
  );
}

class _Harness {
  _Harness({bool initiallyActive = false}) {
    purchases = _Purchases(initiallyActive: initiallyActive);
    container = ProviderContainer(
      overrides: [
        notificationGatewayProvider.overrideWithValue(gateway),
        notificationSettingsStoreProvider.overrideWithValue(MemoryJsonStore()),
        accountSessionProvider.overrideWith((ref) => sessions.stream),
        selectedContentLanguageProvider.overrideWith((ref) async => 'en'),
        learningProgressProvider.overrideWith(
          (ref) async => (
            goal: const DailyGoal(done: 0, target: 10),
            week: WeekProgress(const []),
          ),
        ),
        billingProvider.overrideWith(_Billing.new),
        purchaseProvider.overrideWith(() => purchases),
        clockProvider.overrideWithValue(() => _now),
      ],
    );
    container.listen(notificationProvider, (_, _) {});
    addTearDown(() async {
      container.dispose();
      await sessions.close();
    });
  }
  final gateway = _Gateway();
  final sessions = StreamController<AccountSession?>.broadcast(sync: true);
  late final _Purchases purchases;
  late final ProviderContainer container;

  Future<void> settle() async {
    await Future<void>.delayed(Duration.zero);
    await container.pump();
    await container.read(notificationProvider.notifier).refresh();
  }

  Future<void> signIn(String id) async {
    sessions.add((id: id, email: null));
    await settle();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(tz_data.initializeTimeZones);

  test(
    'purchase success outlives the paywall and waits for confirmed trial data',
    () async {
      final h = _Harness();
      await h.signIn('account-a');
      expect(h.gateway.prompts, 0);
      // No Paywall widget is attached. The native transaction succeeds before
      // the server confirms its account, product, renewal and precise expiry.
      h.purchases.successWhileServerLoads();
      await h.settle();
      expect(h.gateway.prompts, 0);
      expect(h.gateway.scheduled, isEmpty);
      h.purchases.confirm();
      await h.settle();
      expect(h.gateway.prompts, 1);
      expect(h.gateway.scheduled.single.id, trialNotificationId);
      expect(h.container.read(notificationProvider).scheduledTrial, isNotNull);
      await h.settle();
      expect(h.gateway.prompts, 1);
    },
  );

  test(
    'restoring an existing trial and startup never trigger a system prompt',
    () async {
      final h = _Harness(initiallyActive: true);
      await h.signIn('account-a');
      expect(h.gateway.prompts, 0);
      h.purchases.confirm(outcome: PurchaseResult.restored);
      await h.settle();
      expect(h.gateway.prompts, 0);
      expect(h.gateway.scheduled, isEmpty);
    },
  );

  test(
    'a previous account purchase marker never prompts for the next account',
    () async {
      final h = _Harness();
      await h.signIn('account-a');
      h.purchases.successWhileServerLoads();
      await h.settle();
      await h.signIn('account-b');
      h.purchases.confirm();
      await h.settle();
      expect(h.gateway.prompts, 0);
      expect(h.gateway.scheduled, isEmpty);
    },
  );
}
