import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/data/billing/adapty_billing_gateway.dart';
import 'package:sprachapp/data/billing/billing_sync_gateway.dart';
import 'package:sprachapp/data/billing/purchase_gateway.dart';
import 'package:sprachapp/presentation/providers/auth_providers.dart';
import 'package:sprachapp/presentation/providers/billing_provider.dart';
import 'package:sprachapp/presentation/providers/purchase_provider.dart';
import 'package:sprachapp/screens/legal/legal_release_gate.dart';
import 'package:sprachapp/widgets/subscription_tile.dart';

class _BillingGateway implements BillingGateway {
  _BillingGateway(this._identity, {this.profileEntitlements = const {}}) {
    activation.complete();
  }

  String? _identity;
  final Map<String?, bool> profileEntitlements;
  final activation = Completer<void>();
  final updates = StreamController<BillingProfileSnapshot>.broadcast(
    sync: true,
  );

  @override
  Future<void> activate() => activation.future;

  @override
  Future<void> bindCustomerUserId(String? customerUserId) async {
    _identity = customerUserId;
  }

  @override
  Future<BillingProfileSnapshot> readProfile() async =>
      _profile(_identity, premium: profileEntitlements[_identity] ?? false);

  @override
  Stream<BillingProfileSnapshot> get profileUpdates => updates.stream;
}

class _ConnectingBillingGateway implements BillingGateway {
  final activation = Completer<void>();

  @override
  Future<void> activate() => activation.future;

  @override
  Future<void> bindCustomerUserId(String? customerUserId) async {}

  @override
  Future<BillingProfileSnapshot> readProfile() async => _profile('account-a');

  @override
  Stream<BillingProfileSnapshot> get profileUpdates => const Stream.empty();
}

class _PurchaseGateway implements PurchaseGateway {
  final products = const [
    PurchaseProduct(
      productId: 'monthly',
      plan: PurchasePlan.monthly,
      localizedPrice: '9,99 €',
      localizedPeriod: 'Monat',
      isRecommended: false,
    ),
    PurchaseProduct(
      productId: 'yearly',
      plan: PurchasePlan.yearly,
      localizedPrice: '49,99 €',
      localizedPeriod: 'Jahr',
      isRecommended: true,
    ),
  ];
  final purchaseReplies = <Completer<PurchaseOutcome>>[];
  final accounts = <String?>[];
  var purchaseCalls = 0;
  var restoreCalls = 0;
  Object? restoreFailure;
  Object? catalogFailure;

  @override
  Future<List<PurchaseProduct>> loadCatalog({
    required String? customerUserId,
  }) async {
    accounts.add(customerUserId);
    if (catalogFailure case final error?) throw error;
    return products;
  }

  @override
  Future<PurchaseOutcome> purchase({
    required String customerUserId,
    required String productId,
    bool Function()? isCurrent,
  }) {
    purchaseCalls++;
    accounts.add(customerUserId);
    if (isCurrent != null && !isCurrent()) {
      throw StateError('Stale purchase callback.');
    }
    final reply = Completer<PurchaseOutcome>();
    purchaseReplies.add(reply);
    return reply.future;
  }

  @override
  Future<RestoreOutcome> restore({
    required String customerUserId,
    bool Function()? isCurrent,
  }) async {
    restoreCalls++;
    accounts.add(customerUserId);
    if (restoreFailure case final error?) throw error;
    if (isCurrent != null && !isCurrent()) {
      throw StateError('Stale restore callback.');
    }
    return RestoreOutcome.restored;
  }
}

class _BillingSync implements BillingSyncGateway {
  _BillingSync(this.snapshot);

  ServerBillingSnapshot snapshot;
  Object? failure;
  Completer<ServerBillingSnapshot>? nextReply;
  var calls = 0;

  @override
  Future<ServerBillingSnapshot> sync() async {
    calls++;
    if (failure case final error?) throw error;
    final reply = nextReply;
    if (reply != null) {
      nextReply = null;
      return reply.future;
    }
    return snapshot;
  }
}

class _AccountBillingSync implements BillingSyncGateway {
  _AccountBillingSync(this.currentAccount, this.snapshots);

  final String Function() currentAccount;
  final Map<String, ServerBillingSnapshot> snapshots;
  final Map<String, Completer<ServerBillingSnapshot>> delayed = {};
  final accounts = <String>[];

  @override
  Future<ServerBillingSnapshot> sync() {
    final account = currentAccount();
    accounts.add(account);
    return delayed.remove(account)?.future ?? Future.value(snapshots[account]!);
  }
}

class _FakePurchaseClock implements PurchaseClock {
  _FakePurchaseClock(this.value);

  DateTime value;
  final timers = <_FakeTimer>[];

  @override
  DateTime now() => value;

  @override
  Timer schedule(Duration delay, void Function() callback) {
    final timer = _FakeTimer(value.add(delay), callback);
    timers.add(timer);
    return timer;
  }

  void advance(Duration duration) {
    value = value.add(duration);
    for (final timer in timers.toList()) {
      if (timer.isActive && !timer.due.isAfter(value)) timer.fire();
    }
  }
}

class _FakeTimer implements Timer {
  _FakeTimer(this.due, this.callback);

  final DateTime due;
  final void Function() callback;
  bool _isActive = true;

  void fire() {
    if (!_isActive) return;
    _isActive = false;
    callback();
  }

  @override
  bool get isActive => _isActive;
  @override
  int get tick => 0;
  @override
  void cancel() => _isActive = false;
}

BillingProfileSnapshot _profile(String? id, {bool premium = false}) => (
  customerUserId: id,
  premiumActive: premium,
  activeProductId: premium ? 'yearly' : null,
  expiresAt: premium ? DateTime.utc(2027) : null,
);

ServerBillingSnapshot _server({
  bool active = false,
  bool allowed = true,
  String environment = 'Sandbox',
  String purchaseEnvironment = 'Sandbox',
  DateTime? expiresAt,
}) => ServerBillingSnapshot(
  premiumActive: active && environment == 'Production',
  sandboxActive: active && environment == 'Sandbox',
  environment: environment,
  productId: active ? 'yearly' : null,
  expiresAt: active ? expiresAt ?? DateTime.utc(2027) : null,
  startsAt: active ? DateTime.utc(2026) : null,
  willRenew: active,
  syncedAt: DateTime.utc(2026, 10, 31),
  purchaseAllowed: allowed,
  purchaseEnvironment: purchaseEnvironment,
);

ServerBillingSnapshot _gift({DateTime? expiresAt}) => ServerBillingSnapshot(
  premiumActive: true,
  sandboxActive: false,
  environment: 'Production',
  productId: 'com.ardasayar.linglossa.premium.complimentary',
  startsAt: DateTime.utc(2026, 11),
  expiresAt: expiresAt ?? DateTime.utc(2026, 12),
  willRenew: false,
  syncedAt: DateTime.utc(2026, 11),
  purchaseAllowed: true,
  purchaseEnvironment: 'Production',
);

Future<void> _flush() => Future<void>.delayed(const Duration(milliseconds: 20));

ProviderContainer _container({
  required BillingGateway? billing,
  required PurchaseGateway? purchases,
  required BillingSyncGateway sync,
  required Stream<AccountSession?> sessions,
  PurchaseConfiguration? configuration,
  PurchaseClock? clock,
}) {
  final container = ProviderContainer(
    overrides: [
      billingGatewayProvider.overrideWithValue(billing),
      purchaseGatewayProvider.overrideWithValue(purchases),
      billingSyncGatewayProvider.overrideWithValue(sync),
      purchaseConfigurationProvider.overrideWithValue(
        configuration ??
            const PurchaseConfiguration(
              legalDocumentsApproved: true,
              sandboxPurchasesEnabled: true,
              isDebug: true,
              isProfile: false,
            ),
      ),
      if (clock != null) purchaseClockProvider.overrideWithValue(clock),
      accountSessionProvider.overrideWith((ref) => sessions),
    ],
  );
  container.listen(billingProvider, (previous, next) {});
  container.listen(purchaseProvider, (previous, next) {});
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final hasPurchaseGateway in [false, true]) {
    test(
      'Android gift loads automatically without ready billing (gateway: $hasPurchaseGateway)',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        final purchases = _PurchaseGateway();
        final sync = _BillingSync(_gift());
        final container = _container(
          billing: null,
          purchases: hasPurchaseGateway ? purchases : null,
          sync: sync,
          sessions: Stream<AccountSession?>.value((
            id: 'account-a',
            email: null,
          )),
        );
        addTearDown(container.dispose);
        await _flush();

        final initial = container.read(purchaseProvider);
        expect(container.read(billingProvider).phase, BillingPhase.disabled);
        expect(initial.premiumActive, isTrue);
        expect(
          initial.activeProductId,
          'com.ardasayar.linglossa.premium.complimentary',
        );
        expect(initial.willRenew, isFalse);
        expect(initial.purchaseAllowed, isFalse);
        expect(initial.billingReady, isFalse);
        expect(initial.phase, PurchasePhase.idle);
        expect(
          sync.calls,
          1,
          reason: 'Home access must not require loading the paywall.',
        );

        await container.read(purchaseProvider.notifier).load();
        expect(container.read(purchaseProvider).premiumActive, isTrue);
        expect(container.read(purchaseProvider).purchaseAllowed, isFalse);
        expect(
          purchases.accounts,
          isEmpty,
          reason: 'An unsupported store must not load a catalog.',
        );
        await container.read(purchaseProvider.notifier).purchaseSelected();
        await container.read(purchaseProvider.notifier).restore();
        expect(purchases.purchaseCalls, 0);
        expect(purchases.restoreCalls, 0);
        expect(container.read(purchaseProvider).premiumActive, isTrue);
      },
    );
  }

  test(
    'server gift loads while the native billing SDK is still connecting',
    () async {
      final billing = _ConnectingBillingGateway();
      final purchases = _PurchaseGateway();
      final sync = _BillingSync(_gift());
      final container = _container(
        billing: billing,
        purchases: purchases,
        sync: sync,
        sessions: Stream<AccountSession?>.value((id: 'account-a', email: null)),
      );
      addTearDown(container.dispose);
      await _flush();
      expect(container.read(billingProvider).phase, BillingPhase.connecting);
      expect(container.read(purchaseProvider).premiumActive, isTrue);
      expect(container.read(purchaseProvider).purchaseAllowed, isFalse);
      await container.read(purchaseProvider.notifier).load();
      expect(container.read(purchaseProvider).premiumActive, isTrue);
      expect(purchases.accounts, isEmpty);
    },
  );

  test('a missing account never requests or inherits server Premium without a store', () async {
    final sync = _BillingSync(_gift());
    final container = _container(
      billing: null,
      purchases: null,
      sync: sync,
      sessions: Stream<AccountSession?>.value(null),
    );
    addTearDown(container.dispose);
    await _flush();
    await container.read(purchaseProvider.notifier).load();
    expect(sync.calls, 0);
    expect(container.read(purchaseProvider).premiumActive, isNull);
    expect(container.read(purchaseProvider).hasVerifiedAccount, isFalse);
    expect(container.read(purchaseProvider).purchaseAllowed, isFalse);
  });

  test('restore without a store re-checks the account on the server', () async {
    final sync = _BillingSync(_server(environment: 'Production'));
    final container = _container(
      billing: null,
      purchases: null,
      sync: sync,
      sessions: Stream<AccountSession?>.value((id: 'account-a', email: null)),
    );
    addTearDown(container.dispose);
    await _flush();
    await container.read(purchaseProvider.notifier).load();
    expect(container.read(purchaseProvider).premiumActive, isFalse);
    final before = sync.calls;

    sync.snapshot = _gift();
    await container.read(purchaseProvider.notifier).restore();
    final state = container.read(purchaseProvider);
    expect(sync.calls, before + 1);
    expect(state.premiumActive, isTrue);
    expect(state.lastOutcome, PurchaseResult.restored);
    expect(
      state.errorMessage,
      isNull,
      reason: 'A missing store must not read as a failed restore of Premium.',
    );
  });

  test('restore without a store and without an account asks for sign-in', () async {
    final sync = _BillingSync(_gift());
    final container = _container(
      billing: null,
      purchases: null,
      sync: sync,
      sessions: Stream<AccountSession?>.value(null),
    );
    addTearDown(container.dispose);
    await _flush();
    await container.read(purchaseProvider.notifier).restore();
    expect(sync.calls, 0);
    expect(container.read(purchaseProvider).premiumActive, isNull);
    expect(
      container.read(purchaseProvider).errorMessage,
      'Bitte zuerst mit einem bestätigten Konto anmelden.',
    );
  });

  test('a failed server check stays visible next to a missing store', () async {
    final sync = _BillingSync(_gift())
      ..failure = const HttpException('Billing sync failed with HTTP 503.');
    final container = _container(
      billing: null,
      purchases: null,
      sync: sync,
      sessions: Stream<AccountSession?>.value((id: 'account-a', email: null)),
    );
    addTearDown(container.dispose);
    await _flush();
    await container.read(purchaseProvider.notifier).load();
    var state = container.read(purchaseProvider);
    expect(state.premiumActive, isNull);
    expect(state.hasPremiumUiAccess, isFalse);
    expect(state.errorMessage, 'Premium-Käufe sind auf diesem Gerät nicht verfügbar.');
    expect(state.accountSyncError, isNotNull);

    sync.failure = null;
    await container.read(purchaseProvider.notifier).load();
    state = container.read(purchaseProvider);
    expect(state.premiumActive, isTrue);
    expect(state.accountSyncError, isNull);
  });

  test('a failed store catalog still reconciles gifted Premium and keeps purchases disabled', () async {
    final billing = _BillingGateway('account-a');
    final purchases = _PurchaseGateway()
      ..catalogFailure = StateError('Catalog unavailable.');
    final sync = _BillingSync(_server());
    final container = _container(
      billing: billing,
      purchases: purchases,
      sync: sync,
      sessions: Stream<AccountSession?>.value((id: 'account-a', email: null)),
    );
    addTearDown(() async {
      container.dispose();
      await billing.updates.close();
    });
    await _flush();
    expect(container.read(purchaseProvider).premiumActive, isFalse);
    sync.snapshot = _gift();
    await container.read(purchaseProvider.notifier).load();
    final state = container.read(purchaseProvider);
    expect(state.phase, PurchasePhase.failed);
    expect(state.premiumActive, isTrue);
    expect(state.products, isEmpty);
    expect(state.purchaseAllowed, isFalse);
    expect(state.errorMessage, 'Catalog unavailable.');
    expect(sync.calls, 2);
  });

  test('initial and explicit server checks share an in-flight request without a store', () async {
    final reply = Completer<ServerBillingSnapshot>();
    final sync = _BillingSync(_server())..nextReply = reply;
    final container = _container(
      billing: null,
      purchases: null,
      sync: sync,
      sessions: Stream<AccountSession?>.value((id: 'account-a', email: null)),
    );
    addTearDown(container.dispose);
    await _flush();
    final load = container.read(purchaseProvider.notifier).load();
    await _flush();
    expect(sync.calls, 1);
    expect(container.read(purchaseProvider).isSyncing, isTrue);
    reply.complete(_gift());
    await load;
    expect(container.read(purchaseProvider).premiumActive, isTrue);
    expect(container.read(purchaseProvider).isSyncing, isFalse);
  });

  test(
    'store-independent gift expires immediately and rechecks the server',
    () async {
      final now = DateTime.utc(2026, 11, 1, 12);
      final clock = _FakePurchaseClock(now);
      final sync = _BillingSync(
        _gift(expiresAt: now.add(const Duration(hours: 1))),
      );
      final container = _container(
        billing: null,
        purchases: null,
        sync: sync,
        sessions: Stream<AccountSession?>.value((id: 'account-a', email: null)),
        clock: clock,
      );
      addTearDown(container.dispose);
      await _flush();
      expect(container.read(purchaseProvider).premiumActive, isTrue);
      final reply = Completer<ServerBillingSnapshot>();
      sync.nextReply = reply;
      clock.advance(const Duration(hours: 1));
      await _flush();
      expect(container.read(purchaseProvider).premiumActive, isFalse);
      expect(container.read(purchaseProvider).isSyncing, isTrue);
      expect(sync.calls, 2);
      reply.complete(
        _server(environment: 'Production', purchaseEnvironment: 'Production'),
      );
      await _flush();
      expect(container.read(purchaseProvider).premiumActive, isFalse);
      expect(container.read(purchaseProvider).purchaseAllowed, isFalse);
    },
  );

  test('store-independent account changes discard old gifts and late server replies', () async {
    final accountChanges = StreamController<AccountSession?>.broadcast(
      sync: true,
    );
    var currentAccount = 'account-a';
    final sessions = Stream<AccountSession?>.multi((sink) {
      sink.add((id: currentAccount, email: null));
      final sub = accountChanges.stream.listen(sink.add);
      sink.onCancel = sub.cancel;
    });
    final oldReply = Completer<ServerBillingSnapshot>();
    final sync = _AccountBillingSync(() => currentAccount, {
      'account-a': _gift(),
      'account-b': _server(
        environment: 'Production',
        purchaseEnvironment: 'Production',
      ),
    })..delayed['account-a'] = oldReply;
    final container = _container(
      billing: null,
      purchases: null,
      sync: sync,
      sessions: sessions,
    );
    addTearDown(() async {
      container.dispose();
      await accountChanges.close();
    });
    await _flush();
    expect(container.read(purchaseProvider).isSyncing, isTrue);
    currentAccount = 'account-b';
    accountChanges.add((id: 'account-b', email: null));
    await _flush();
    expect(container.read(purchaseProvider).premiumActive, isFalse);
    oldReply.complete(_gift());
    await _flush();
    expect(container.read(purchaseProvider).premiumActive, isFalse);
    expect(sync.accounts, ['account-a', 'account-b']);

    currentAccount = 'account-a';
    accountChanges.add((id: 'account-a', email: null));
    await _flush();
    expect(container.read(purchaseProvider).premiumActive, isTrue);
    accountChanges.add(null);
    await _flush();
    expect(container.read(purchaseProvider).hasVerifiedAccount, isFalse);
    expect(container.read(purchaseProvider).premiumActive, isNull);
    expect(container.read(purchaseProvider).activeProductId, isNull);
    expect(sync.accounts, ['account-a', 'account-b', 'account-a']);
  });

  test('a gift that expires in transit stays inactive without a reconciliation loop', () async {
    final now = DateTime.utc(2026, 11, 1, 12);
    final sync = _BillingSync(_gift(expiresAt: now));
    final container = _container(
      billing: null,
      purchases: null,
      sync: sync,
      sessions: Stream<AccountSession?>.value((id: 'account-a', email: null)),
      clock: _FakePurchaseClock(now),
    );
    addTearDown(container.dispose);
    await _flush();
    expect(container.read(purchaseProvider).premiumActive, isFalse);
    expect(container.read(purchaseProvider).isSyncing, isFalse);
    expect(container.read(purchaseProvider).purchaseAllowed, isFalse);
    expect(sync.calls, 1);
  });

  test(
    'sandbox test access requires build, legal, server, and expiry gates',
    () {
      final expiry = DateTime.utc(2027);
      bool allows({
        bool isDebug = true,
        bool isProfile = false,
        bool legalApproved = true,
        bool sandboxFlag = true,
        bool purchaseAllowed = true,
        String purchaseEnvironment = 'Sandbox',
        String environment = 'Sandbox',
        bool sandboxActive = true,
        DateTime? expiresAt,
        bool noExpiry = false,
      }) => sandboxTestAccessAllowed(
        isDebug: isDebug,
        isProfile: isProfile,
        legalDocumentsApproved: legalApproved,
        sandboxPurchasesEnabled: sandboxFlag,
        purchaseAllowed: purchaseAllowed,
        purchaseEnvironment: purchaseEnvironment,
        environment: environment,
        verifiedSandboxActive: sandboxActive,
        expiresAt: noExpiry ? null : expiresAt ?? expiry,
        now: DateTime.utc(2026),
      );

      expect(allows(), isTrue);
      expect(allows(isDebug: false), isTrue);
      expect(allows(isDebug: false, legalApproved: false), isFalse);
      expect(
        allows(isDebug: false, isProfile: true, legalApproved: false),
        isTrue,
      );
      expect(
        allows(
          isDebug: false,
          isProfile: true,
          legalApproved: true,
          purchaseEnvironment: 'Production',
        ),
        isFalse,
      );
      expect(allows(sandboxFlag: false), isFalse);
      expect(allows(purchaseAllowed: false), isFalse);
      expect(allows(purchaseEnvironment: 'Production'), isFalse);
      expect(allows(environment: 'Production'), isFalse);
      expect(allows(sandboxActive: false), isFalse);
      expect(allows(noExpiry: true), isFalse);
      expect(allows(expiresAt: DateTime.utc(2025)), isFalse);
    },
  );

  test(
    'store environment gate supports release Production and opted-in Sandbox',
    () {
      bool allowed({
        required bool isDebug,
        bool isProfile = false,
        bool legalApproved = true,
        bool sandboxFlag = true,
        required String environment,
      }) => storeEnvironmentAllowed(
        isDebug: isDebug,
        isProfile: isProfile,
        legalDocumentsApproved: legalApproved,
        sandboxPurchasesEnabled: sandboxFlag,
        purchaseEnvironment: environment,
      );

      expect(allowed(isDebug: false, environment: 'Production'), isTrue);
      expect(
        allowed(isDebug: false, sandboxFlag: false, environment: 'Production'),
        isTrue,
      );
      expect(allowed(isDebug: false, environment: 'Sandbox'), isTrue);
      expect(
        allowed(isDebug: false, legalApproved: false, environment: 'Sandbox'),
        isFalse,
      );
      expect(
        allowed(isDebug: false, sandboxFlag: false, environment: 'Sandbox'),
        isFalse,
      );
      expect(allowed(isDebug: true, environment: 'Sandbox'), isTrue);
      expect(allowed(isDebug: true, environment: 'Production'), isFalse);
      expect(
        allowed(isDebug: false, isProfile: true, environment: 'Sandbox'),
        isTrue,
      );
      expect(
        allowed(isDebug: false, isProfile: true, environment: 'Production'),
        isFalse,
      );
      expect(
        allowed(
          isDebug: false,
          isProfile: true,
          legalApproved: true,
          environment: 'Production',
        ),
        isFalse,
      );
      expect(
        allowed(
          isDebug: false,
          isProfile: true,
          sandboxFlag: false,
          environment: 'Sandbox',
        ),
        isFalse,
      );
      expect(
        allowed(isDebug: true, sandboxFlag: false, environment: 'Sandbox'),
        isFalse,
      );
      expect(allowed(isDebug: false, environment: 'Unknown'), isFalse);
    },
  );

  test(
    'release provider accepts server-authorized Production and Sandbox',
    () async {
      for (final environment in ['Production', 'Sandbox']) {
        final billing = _BillingGateway('account-a');
        final purchases = _PurchaseGateway();
        final sync = _BillingSync(
          _server(
            active: true,
            environment: environment,
            purchaseEnvironment: environment,
          ),
        );
        final container = _container(
          billing: billing,
          purchases: purchases,
          sync: sync,
          sessions: Stream<AccountSession?>.value((
            id: 'account-a',
            email: null,
          )),
          configuration: const PurchaseConfiguration(
            legalDocumentsApproved: true,
            sandboxPurchasesEnabled: true,
            isDebug: false,
            isProfile: false,
          ),
        );
        addTearDown(() async {
          container.dispose();
          await billing.updates.close();
        });
        await _flush();
        await container.read(purchaseProvider.notifier).load();

        final state = container.read(purchaseProvider);
        expect(state.purchaseAllowed, isTrue, reason: environment);
        expect(state.premiumActive, environment == 'Production');
        expect(state.sandboxTestActive, environment == 'Sandbox');
      }
    },
  );

  test('build purchase gate requires debug sandbox opt-in or release legal approval', () {
    bool enabled({
      required bool isDebug,
      bool isProfile = false,
      bool legalApproved = false,
      bool sandboxFlag = false,
    }) => storeOperationsEnabledForBuild(
      isDebug: isDebug,
      isProfile: isProfile,
      legalDocumentsApproved: legalApproved,
      sandboxPurchasesEnabled: sandboxFlag,
    );

    expect(enabled(isDebug: true), isFalse);
    expect(enabled(isDebug: true, sandboxFlag: true), isTrue);
    expect(enabled(isDebug: false, isProfile: true, sandboxFlag: true), isTrue);
    expect(enabled(isDebug: false, isProfile: true), isFalse);
    expect(
      enabled(isDebug: false, isProfile: true, legalApproved: true),
      isFalse,
    );
    expect(enabled(isDebug: false), isFalse);
    expect(enabled(isDebug: false, sandboxFlag: true), isFalse);
    expect(enabled(isDebug: false, legalApproved: true), isTrue);
  });

  test(
    'loads localized catalog and selects the recommended annual plan',
    () async {
      final billing = _BillingGateway(null);
      final purchases = _PurchaseGateway();
      final sync = _BillingSync(_server());
      final container = _container(
        billing: billing,
        purchases: purchases,
        sync: sync,
        sessions: Stream<AccountSession?>.value(null),
      );
      addTearDown(() async {
        container.dispose();
        await billing.updates.close();
      });
      await _flush();

      await container.read(purchaseProvider.notifier).load();
      final state = container.read(purchaseProvider);
      expect(state.phase, PurchasePhase.ready);
      expect(state.products.map((product) => product.localizedPrice), [
        '9,99 €',
        '49,99 €',
      ]);
      expect(state.selectedProductId, 'yearly');
      expect(state.hasVerifiedAccount, isFalse);
      expect(state.purchaseAllowed, isFalse);
      expect(sync.calls, 0);
    },
  );

  for (final outcome in [PurchaseOutcome.cancelled, PurchaseOutcome.pending]) {
    test(
      'purchase $outcome clears the busy state without granting premium',
      () async {
        final billing = _BillingGateway('account-a');
        final purchases = _PurchaseGateway();
        final sync = _BillingSync(_server());
        final container = _container(
          billing: billing,
          purchases: purchases,
          sync: sync,
          sessions: Stream<AccountSession?>.value((
            id: 'account-a',
            email: null,
          )),
        );
        addTearDown(() async {
          container.dispose();
          await billing.updates.close();
        });
        await _flush();
        await container.read(purchaseProvider.notifier).load();

        final pending = container
            .read(purchaseProvider.notifier)
            .purchaseSelected();
        await _flush();
        expect(
          container.read(purchaseProvider).phase,
          PurchasePhase.purchasing,
        );
        purchases.purchaseReplies.single.complete(outcome);
        await pending;

        final state = container.read(purchaseProvider);
        expect(state.phase, PurchasePhase.ready);
        expect(
          state.lastOutcome,
          outcome == PurchaseOutcome.cancelled
              ? PurchaseResult.cancelled
              : PurchaseResult.pending,
        );
        expect(state.premiumActive, isFalse);
        expect(state.clientPremiumActive, isFalse);
        expect(state.purchaseAllowed, isTrue);
        expect(
          sync.calls,
          3,
        ); // automatic account check, catalog preflight, pre-purchase policy
      },
    );
  }

  test(
    'reconciles a pending purchase when Adapty later reports activation',
    () async {
      final billing = _BillingGateway('account-a');
      final purchases = _PurchaseGateway();
      final sync = _BillingSync(_server());
      final container = _container(
        billing: billing,
        purchases: purchases,
        sync: sync,
        sessions: Stream<AccountSession?>.value((id: 'account-a', email: null)),
      );
      addTearDown(() async {
        container.dispose();
        await billing.updates.close();
      });
      await _flush();
      await container.read(purchaseProvider.notifier).load();
      final purchase = container
          .read(purchaseProvider.notifier)
          .purchaseSelected();
      await _flush();
      expect(sync.calls, 3);

      sync.snapshot = _server(
        active: true,
        environment: 'Production',
        purchaseEnvironment: 'Sandbox',
      );
      billing.updates.add(_profile('account-a', premium: true));
      await _flush();
      expect(
        sync.calls,
        3,
        reason:
            'Do not start reconciliation while the native purchase is open.',
      );

      purchases.purchaseReplies.single.complete(PurchaseOutcome.pending);
      await purchase;
      await _flush();
      final state = container.read(purchaseProvider);
      expect(state.lastOutcome, PurchaseResult.pending);
      expect(state.premiumActive, isTrue);
      expect(state.activeProductId, 'yearly');
      expect(sync.calls, 4);
    },
  );

  test(
    'profile provider accepts only explicitly authorized sandbox access',
    () async {
      final billing = _BillingGateway('account-a');
      final purchases = _PurchaseGateway();
      final sync = _BillingSync(
        _server(
          active: true,
          allowed: true,
          environment: 'Sandbox',
          purchaseEnvironment: 'Sandbox',
        ),
      );
      final container = _container(
        billing: billing,
        purchases: purchases,
        sync: sync,
        sessions: Stream<AccountSession?>.value((id: 'account-a', email: null)),
        configuration: const PurchaseConfiguration(
          legalDocumentsApproved: false,
          sandboxPurchasesEnabled: true,
          isDebug: false,
          isProfile: true,
        ),
      );
      addTearDown(() async {
        container.dispose();
        await billing.updates.close();
      });
      await _flush();
      await container.read(purchaseProvider.notifier).load();

      final state = container.read(purchaseProvider);
      expect(state.purchaseAllowed, isTrue);
      expect(state.premiumActive, isFalse);
      expect(state.sandboxTestActive, isTrue);
    },
  );

  test(
    'invalidates active premium at expiry and rechecks without restarting',
    () async {
      final now = DateTime.utc(2026, 10, 31, 12);
      final expiresAt = now.add(const Duration(days: 1));
      final clock = _FakePurchaseClock(now);
      final billing = _BillingGateway('account-a');
      final purchases = _PurchaseGateway();
      final sync = _BillingSync(
        _server(
          active: true,
          environment: 'Production',
          purchaseEnvironment: 'Sandbox',
          expiresAt: expiresAt,
        ),
      );
      final container = _container(
        billing: billing,
        purchases: purchases,
        sync: sync,
        sessions: Stream<AccountSession?>.value((id: 'account-a', email: null)),
        clock: clock,
      );
      addTearDown(() async {
        container.dispose();
        await billing.updates.close();
      });
      await _flush();
      await container.read(purchaseProvider.notifier).load();
      expect(container.read(purchaseProvider).premiumActive, isTrue);

      final serverReply = Completer<ServerBillingSnapshot>();
      sync.nextReply = serverReply;
      clock.advance(const Duration(days: 1));
      await _flush();
      expect(container.read(purchaseProvider).premiumActive, isFalse);
      expect(container.read(purchaseProvider).isSyncing, isTrue);

      serverReply.complete(_server());
      await _flush();
      expect(container.read(purchaseProvider).premiumActive, isFalse);
      expect(container.read(purchaseProvider).isSyncing, isFalse);
    },
  );

  test(
    'successful sandbox purchase syncs, but never grants production premium',
    () async {
      final billing = _BillingGateway('account-a');
      final purchases = _PurchaseGateway();
      final sync = _BillingSync(_server(active: true, environment: 'Sandbox'));
      final container = _container(
        billing: billing,
        purchases: purchases,
        sync: sync,
        sessions: Stream<AccountSession?>.value((id: 'account-a', email: null)),
      );
      addTearDown(() async {
        container.dispose();
        await billing.updates.close();
      });
      await _flush();
      await container.read(purchaseProvider.notifier).load();
      final pending = container
          .read(purchaseProvider.notifier)
          .purchaseSelected();
      await _flush();
      purchases.purchaseReplies.single.complete(PurchaseOutcome.success);
      await pending;

      final state = container.read(purchaseProvider);
      expect(state.lastOutcome, PurchaseResult.success);
      expect(state.premiumActive, isFalse);
      expect(state.sandboxTestActive, isTrue);
      expect(state.hasPremiumUiAccess, isTrue);
      expect(state.environment, 'Sandbox');
      expect(state.activeProductId, 'yearly');
      expect(
        sync.calls,
        4,
      ); // automatic account check, catalog, purchase preflight, post-purchase
    },
  );

  test('server denial keeps the store sheet closed for that account', () async {
    final billing = _BillingGateway('account-a');
    final purchases = _PurchaseGateway();
    final sync = _BillingSync(_server(allowed: false));
    final container = _container(
      billing: billing,
      purchases: purchases,
      sync: sync,
      sessions: Stream<AccountSession?>.value((id: 'account-a', email: null)),
    );
    addTearDown(() async {
      container.dispose();
      await billing.updates.close();
    });
    await _flush();
    await container.read(purchaseProvider.notifier).load();
    await container.read(purchaseProvider.notifier).purchaseSelected();

    final state = container.read(purchaseProvider);
    expect(state.purchaseAllowed, isFalse);
    expect(state.phase, PurchasePhase.failed);
    expect(purchases.purchaseCalls, 0);
  });

  test(
    'restore calls the store then synchronizes server entitlement',
    () async {
      final billing = _BillingGateway('account-a');
      final purchases = _PurchaseGateway();
      final sync = _BillingSync(
        _server(
          active: true,
          environment: 'Production',
          purchaseEnvironment: 'Sandbox',
        ),
      );
      final container = _container(
        billing: billing,
        purchases: purchases,
        sync: sync,
        sessions: Stream<AccountSession?>.value((id: 'account-a', email: null)),
      );
      addTearDown(() async {
        container.dispose();
        await billing.updates.close();
      });
      await _flush();
      await container.read(purchaseProvider.notifier).load();
      await container.read(purchaseProvider.notifier).restore();

      final state = container.read(purchaseProvider);
      expect(purchases.restoreCalls, 1);
      expect(state.lastOutcome, PurchaseResult.restored);
      // Sandbox/test environment data never unlocks production premium.
      expect(
        state.premiumActive,
        isTrue,
      ); // backend entitlement itself is Production
      expect(state.expiresAt, DateTime.utc(2027));
      expect(sync.calls, 3);
    },
  );

  test(
    'restore leaves status unknown on server failure and sanitizes diagnostics',
    () async {
      final billing = _BillingGateway('account-a');
      final purchases = _PurchaseGateway();
      final sync = _BillingSync(_server());
      sync.failure = Exception('raw upstream endpoint detail');
      final container = _container(
        billing: billing,
        purchases: purchases,
        sync: sync,
        sessions: Stream<AccountSession?>.value((id: 'account-a', email: null)),
      );
      addTearDown(() async {
        container.dispose();
        await billing.updates.close();
      });
      await _flush();
      await container.read(purchaseProvider.notifier).load();
      await container.read(purchaseProvider.notifier).restore();

      final state = container.read(purchaseProvider);
      expect(state.lastOutcome, PurchaseResult.restored);
      expect(state.premiumActive, isNull);
      expect(state.errorMessage, contains('konnte nicht abgeschlossen werden'));
      expect(state.errorMessage, isNot(contains('raw upstream')));
    },
  );

  test(
    'restore SDK failure reports the error while preserving verified premium',
    () async {
      final billing = _BillingGateway('account-a');
      final purchases = _PurchaseGateway()
        ..restoreFailure = StateError('Store restore failed.');
      final sync = _BillingSync(
        _server(
          active: true,
          environment: 'Production',
          purchaseEnvironment: 'Production',
        ),
      );
      final container = _container(
        billing: billing,
        purchases: purchases,
        sync: sync,
        sessions: Stream<AccountSession?>.value((id: 'account-a', email: null)),
      );
      addTearDown(() async {
        container.dispose();
        await billing.updates.close();
      });
      await _flush();
      await container.read(purchaseProvider.notifier).load();
      expect(container.read(purchaseProvider).premiumActive, isTrue);

      await container.read(purchaseProvider.notifier).restore();
      final state = container.read(purchaseProvider);
      expect(state.phase, PurchasePhase.failed);
      expect(state.premiumActive, isTrue);
      expect(subscriptionRestoreNotice(state), 'Store restore failed.');
    },
  );

  test('late purchase result is discarded after the authenticated account switches', () async {
    final accountChanges = StreamController<AccountSession?>.broadcast(
      sync: true,
    );
    final sessions = Stream<AccountSession?>.multi((sink) {
      sink.add((id: 'account-a', email: null));
      final sub = accountChanges.stream.listen(sink.add);
      sink.onCancel = sub.cancel;
    });
    final billing = _BillingGateway('account-a');
    final purchases = _PurchaseGateway();
    final sync = _BillingSync(_server());
    final container = _container(
      billing: billing,
      purchases: purchases,
      sync: sync,
      sessions: sessions,
    );
    addTearDown(() async {
      container.dispose();
      await accountChanges.close();
      await billing.updates.close();
    });
    await _flush();
    await container.read(purchaseProvider.notifier).load();

    final pending = container
        .read(purchaseProvider.notifier)
        .purchaseSelected();
    await _flush();
    expect(purchases.purchaseCalls, 1);
    accountChanges.add((id: 'account-b', email: null));
    await _flush();
    final callsBeforePurchaseReply = sync.calls;
    purchases.purchaseReplies.single.complete(PurchaseOutcome.success);
    await pending;

    final state = container.read(purchaseProvider);
    expect(state.hasVerifiedAccount, isTrue);
    expect(state.lastOutcome, isNull);
    expect(state.premiumActive, isFalse);
    // The new account is reconciled automatically. The old native result must
    // not send another synchronization using account B's JWT.
    expect(sync.calls, callsBeforePurchaseReply);
  });

  test('active Production entitlement follows A to B to A and ignores B stale sync', () async {
    final accountChanges = StreamController<AccountSession?>.broadcast(
      sync: true,
    );
    var currentAccount = 'account-a';
    final sessions = Stream<AccountSession?>.multi((sink) {
      sink.add((id: currentAccount, email: null));
      final sub = accountChanges.stream.listen(sink.add);
      sink.onCancel = sub.cancel;
    });
    final billing = _BillingGateway(
      'account-a',
      profileEntitlements: {'account-a': true, 'account-b': false},
    );
    final purchases = _PurchaseGateway();
    final sync = _AccountBillingSync(() => currentAccount, {
      'account-a': _server(
        active: true,
        environment: 'Production',
        purchaseEnvironment: 'Production',
      ),
      'account-b': _server(
        active: false,
        environment: 'Production',
        purchaseEnvironment: 'Production',
      ),
    });
    final container = _container(
      billing: billing,
      purchases: purchases,
      sync: sync,
      sessions: sessions,
    );
    addTearDown(() async {
      container.dispose();
      await accountChanges.close();
      await billing.updates.close();
    });
    await _flush();

    expect(container.read(purchaseProvider).premiumActive, isTrue);
    expect(sync.accounts, ['account-a']);

    final staleBReply = Completer<ServerBillingSnapshot>();
    sync.delayed['account-b'] = staleBReply;
    currentAccount = 'account-b';
    accountChanges.add((id: 'account-b', email: null));
    await _flush();
    expect(container.read(purchaseProvider).premiumActive, isNull);
    expect(container.read(purchaseProvider).clientPremiumActive, isFalse);

    final loadB = container.read(purchaseProvider.notifier).load();
    await _flush();
    expect(sync.accounts, ['account-a', 'account-b']);
    expect(container.read(purchaseProvider).premiumActive, isNull);

    currentAccount = 'account-a';
    accountChanges.add((id: 'account-a', email: null));
    await _flush();
    expect(container.read(purchaseProvider).premiumActive, isTrue);
    expect(sync.accounts, ['account-a', 'account-b', 'account-a']);

    staleBReply.complete(
      _server(
        active: false,
        environment: 'Production',
        purchaseEnvironment: 'Production',
      ),
    );
    await loadB;
    expect(container.read(purchaseProvider).premiumActive, isTrue);
    expect(container.read(purchaseProvider).clientPremiumActive, isTrue);
  });
}
