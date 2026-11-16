import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/data/notifications/notification_gateway.dart';
import 'package:sprachapp/data/platform/json_store_base.dart';
import 'package:sprachapp/data/user/drift_user_repository.dart';
import 'package:sprachapp/data/user/user_database.dart';
import 'package:sprachapp/domain/srs_state.dart';
import 'package:sprachapp/models/home_models.dart';
import 'package:sprachapp/presentation/providers/auth_providers.dart';
import 'package:sprachapp/presentation/providers/billing_provider.dart';
import 'package:sprachapp/presentation/providers/database_providers.dart';
import 'package:sprachapp/presentation/providers/deck_providers.dart';
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
  int refreshes = 0;
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
  Future<void> refresh() async => refreshes++;
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
        notificationLatestReviewProvider.overrideWith(
          (ref) async => lastReview,
        ),
        vocabBreakdownProvider.overrideWith(
          (ref) async =>
              const VocabBreakdown(due: 1, building: 0, mastered: 0, unseen: 0),
        ),

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
        billingProvider.overrideWith(() => billing),
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
  final billing = _Billing();
  DateTime? lastReview;
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

  test('purchase completion keeps entitlement refresh and never schedules trial reminders', () async {
    final h = _Harness();
    await h.signIn('account-a');
    h.purchases.successWhileServerLoads();
    await h.settle();
    h.purchases.confirm();
    h.gateway.permission = NotificationPermission.allowed;
    final refreshes = h.billing.refreshes;
    await h.settle();
    expect(h.billing.refreshes, greaterThan(refreshes));
    expect(h.gateway.prompts, 0);
    expect(h.gateway.scheduled, isEmpty);
    expect(h.container.read(notificationProvider).scheduledTrial, isNull);
  });

  test('startup and restore keep the old trial reminder disabled', () async {
    final h = _Harness(initiallyActive: true);
    await h.signIn('account-a');
    h.purchases.confirm(outcome: PurchaseResult.restored);
    await h.settle();
    expect(h.gateway.prompts, 0);
    expect(h.gateway.scheduled, isEmpty);
  });

  test(
    'new learning from the repository replaces an already scheduled day',
    () async {
      final h = _Harness();
      await h.signIn('account-a');
      await h.container
          .read(notificationProvider.notifier)
          .setLearningEnabled(true);
      expect(h.gateway.scheduled.first.at, DateTime.utc(2026, 11, 13, 18));
      h.lastReview = _now;
      h.container.invalidate(notificationLatestReviewProvider);
      await h.settle();
      expect(h.gateway.scheduled.first.at, DateTime.utc(2026, 11, 14, 18));
    },
  );

  test('a newly saved review is observed in the same second', () async {
    final db = UserDatabase(NativeDatabase.memory());
    final user = DriftUserRepository(db, lang: 'en');
    final container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(() => _now),
        userRepositoryProvider.overrideWith((ref) async => user),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await user.close();
    });
    final detected = Completer<DateTime>();
    container.listen(notificationLatestReviewProvider, (_, next) {
      if (next.asData?.value case final at? when !detected.isCompleted) {
        detected.complete(at);
      }
    });
    expect(
      await container.read(notificationLatestReviewProvider.future),
      isNull,
    );
    await user.ensureCards(['card'], now: _now, origin: CardOrigin.deck);
    expect(
      await user.recordReview(
        ReviewRecord(
          id: 'review',
          cardId: 'card',
          createdAt: _now,
          mode: ReviewMode.mixed,
          sentenceId: 'sentence',
          firstAttemptCorrect: true,
          errorCount: 0,
          revealed: false,
          hintUsed: false,
          boxBefore: 0,
          boxAfter: 1,
          dueAtAfter: _now.add(const Duration(days: 1)),
          responseMs: null,
          appVersion: 'test',
          deviceId: 'test',
        ),
      ),
      isTrue,
    );
    expect(await detected.future.timeout(const Duration(seconds: 2)), _now);
  });
}
