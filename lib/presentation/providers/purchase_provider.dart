import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/billing/adapty_billing_gateway.dart';
import '../../data/billing/billing_sync_gateway.dart';
import '../../data/billing/purchase_gateway.dart';
import '../../screens/legal/legal_release_gate.dart';
import 'account_provider.dart';
import 'billing_provider.dart';
import 'content_update_provider.dart';

final purchaseGatewayProvider = Provider<PurchaseGateway?>((ref) {
  final billingGateway = ref.watch(billingGatewayProvider);
  if (billingGateway is! BillingIdentityRunner) return null;
  return AdaptyPurchaseGateway(billingGateway as BillingIdentityRunner);
});

final billingSyncGatewayProvider = Provider<BillingSyncGateway?>((ref) {
  final auth = ref.watch(contentAuthProvider);
  if (!auth.configured) return null;
  final gateway = SupabaseBillingSyncGateway(auth);
  ref.onDispose(gateway.close);
  return gateway;
});

class PurchaseConfiguration {
  const PurchaseConfiguration({
    required this.legalDocumentsApproved,
    required this.sandboxPurchasesEnabled,
    required this.isDebug,
    required this.isProfile,
  });

  final bool legalDocumentsApproved;
  final bool sandboxPurchasesEnabled;
  final bool isDebug;
  final bool isProfile;
}

final purchaseConfigurationProvider = Provider<PurchaseConfiguration>((ref) {
  return PurchaseConfiguration(
    legalDocumentsApproved: legalDocumentsApproved,
    sandboxPurchasesEnabled: legalSandboxPurchasesEnabled,
    isDebug: kDebugMode,
    isProfile: kProfileMode,
  );
});

abstract interface class PurchaseClock {
  DateTime now();
  Timer schedule(Duration delay, void Function() callback);
}

class _SystemPurchaseClock implements PurchaseClock {
  const _SystemPurchaseClock();

  @override
  DateTime now() => DateTime.now();

  @override
  Timer schedule(Duration delay, void Function() callback) =>
      Timer(delay, callback);
}

final purchaseClockProvider = Provider<PurchaseClock>(
  (ref) => const _SystemPurchaseClock(),
);

bool sandboxTestAccessAllowed({
  required bool isDebug,
  required bool isProfile,
  required bool legalDocumentsApproved,
  required bool sandboxPurchasesEnabled,
  required bool purchaseAllowed,
  required String purchaseEnvironment,
  required String environment,
  required bool verifiedSandboxActive,
  required DateTime? expiresAt,
  required DateTime now,
}) =>
    storeEnvironmentAllowed(
      isDebug: isDebug,
      isProfile: isProfile,
      legalDocumentsApproved: legalDocumentsApproved,
      sandboxPurchasesEnabled: sandboxPurchasesEnabled,
      purchaseEnvironment: purchaseEnvironment,
    ) &&
    purchaseAllowed &&
    environment == 'Sandbox' &&
    verifiedSandboxActive &&
    expiresAt != null &&
    expiresAt.isAfter(now);

class PurchaseState {
  const PurchaseState({
    this.phase = PurchasePhase.idle,
    this.products = const [],
    this.selectedProductId,
    this.errorMessage,
    this.lastOutcome,
    this.hasVerifiedAccount = false,
    this.billingReady = false,
    this.premiumActive,
    this.sandboxTestActive = false,
    this.clientPremiumActive,
    this.activeProductId,
    this.expiresAt,
    this.startsAt,
    this.willRenew,
    this.environment,
    this.purchaseEnvironment,
    this.syncedAt,
    this.isSyncing = false,
    this.serverStoreAllowed = false,
    this.purchaseAllowed = false,
    this.accountSyncError,
  });

  final PurchasePhase phase;
  final List<PurchaseProduct> products;
  final String? selectedProductId;
  final String? errorMessage;
  final PurchaseResult? lastOutcome;
  final bool hasVerifiedAccount;
  final bool billingReady;

  /// Server-verified Production entitlement. Null means billing status is
  /// unknown or has not been synchronized.
  final bool? premiumActive;

  /// Test-only UI state. This never represents production entitlement and
  /// must never authorize server-side quotas or content access.
  final bool sandboxTestActive;

  /// Adapty SDK profile hint for paywall/settings display only. It never grants
  /// backend access to translations or quotas.
  final bool? clientPremiumActive;
  final String? activeProductId;
  final DateTime? expiresAt;
  final DateTime? startsAt;
  final bool? willRenew;
  final String? environment;
  final String? purchaseEnvironment;
  final DateTime? syncedAt;
  final bool isSyncing;
  final bool serverStoreAllowed;

  /// True only when the current environment, legal configuration and server
  /// policy all permit a store operation for this authenticated account.
  final bool purchaseAllowed;

  /// The last server check of this account's Premium failed. Kept apart from
  /// [errorMessage] so a missing native store cannot hide it.
  final String? accountSyncError;

  bool get hasPremiumUiAccess => premiumActive == true || sandboxTestActive;

  PurchaseState copyWith({
    PurchasePhase? phase,
    List<PurchaseProduct>? products,
    String? selectedProductId,
    bool clearSelectedProductId = false,
    String? errorMessage,
    bool clearError = false,
    PurchaseResult? lastOutcome,
    bool clearOutcome = false,
    bool? hasVerifiedAccount,
    bool? billingReady,
    bool? premiumActive,
    bool clearPremiumActive = false,
    bool? sandboxTestActive,
    bool? clientPremiumActive,
    bool clearClientPremiumActive = false,
    String? activeProductId,
    bool clearActiveProductId = false,
    DateTime? expiresAt,
    bool clearExpiresAt = false,
    DateTime? startsAt,
    bool clearStartsAt = false,
    bool? willRenew,
    bool clearWillRenew = false,
    String? environment,
    bool clearEnvironment = false,
    String? purchaseEnvironment,
    bool clearPurchaseEnvironment = false,
    DateTime? syncedAt,
    bool clearSyncedAt = false,
    bool? isSyncing,
    bool? serverStoreAllowed,
    bool? purchaseAllowed,
    String? accountSyncError,
    bool clearAccountSyncError = false,
  }) => PurchaseState(
    phase: phase ?? this.phase,
    products: products ?? this.products,
    selectedProductId: clearSelectedProductId
        ? null
        : selectedProductId ?? this.selectedProductId,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    lastOutcome: clearOutcome ? null : lastOutcome ?? this.lastOutcome,
    hasVerifiedAccount: hasVerifiedAccount ?? this.hasVerifiedAccount,
    billingReady: billingReady ?? this.billingReady,
    premiumActive: clearPremiumActive
        ? null
        : premiumActive ?? this.premiumActive,
    sandboxTestActive: sandboxTestActive ?? this.sandboxTestActive,
    clientPremiumActive: clearClientPremiumActive
        ? null
        : clientPremiumActive ?? this.clientPremiumActive,
    activeProductId: clearActiveProductId
        ? null
        : activeProductId ?? this.activeProductId,
    expiresAt: clearExpiresAt ? null : expiresAt ?? this.expiresAt,
    startsAt: clearStartsAt ? null : startsAt ?? this.startsAt,
    willRenew: clearWillRenew ? null : willRenew ?? this.willRenew,
    environment: clearEnvironment ? null : environment ?? this.environment,
    purchaseEnvironment: clearPurchaseEnvironment
        ? null
        : purchaseEnvironment ?? this.purchaseEnvironment,
    syncedAt: clearSyncedAt ? null : syncedAt ?? this.syncedAt,
    isSyncing: isSyncing ?? this.isSyncing,
    serverStoreAllowed: serverStoreAllowed ?? this.serverStoreAllowed,
    purchaseAllowed: purchaseAllowed ?? this.purchaseAllowed,
    accountSyncError: clearAccountSyncError
        ? null
        : accountSyncError ?? this.accountSyncError,
  );
}

enum PurchasePhase { idle, loading, ready, purchasing, restoring, failed }

extension PurchasePhaseStatus on PurchasePhase {
  bool get isBusy =>
      this == PurchasePhase.loading ||
      this == PurchasePhase.purchasing ||
      this == PurchasePhase.restoring;
}

enum PurchaseResult { success, cancelled, pending, restored, noPurchases }

final purchaseProvider = NotifierProvider<PurchaseController, PurchaseState>(
  PurchaseController.new,
);

class PurchaseController extends Notifier<PurchaseState> {
  int _generation = 0;
  Timer? _expiryTimer;
  late PurchaseClock _clock;
  (bool?, String?, DateTime?)? _lastObservedSdkProfile;
  bool _sdkReconciliationPending = false;
  Future<void>? _serverSyncInFlight;

  @override
  PurchaseState build() {
    _clock = ref.watch(purchaseClockProvider);
    _expiryTimer?.cancel();
    final account = ref.watch(accountSessionProvider);
    // Only billing phase is a build dependency. Profile stream updates are
    // copied into the state via listen below, so a purchase is not invalidated
    // when Adapty emits its post-transaction profile event.
    final billingPhase = ref.watch(
      billingProvider.select((value) => value.phase),
    );
    final generation = ++_generation;
    final accountId = _accountId(account);
    final billing = ref.read(billingProvider);
    _lastObservedSdkProfile = (
      billing.premiumActive,
      billing.activeProductId,
      billing.expiresAt,
    );
    _sdkReconciliationPending = false;
    _serverSyncInFlight = null;
    ref.listen(billingProvider, (previous, next) {
      if (!ref.mounted || generation != _generation) return;
      final nextSdkProfile = (
        next.premiumActive,
        next.activeProductId,
        next.expiresAt,
      );
      final sdkProfileChanged = nextSdkProfile != _lastObservedSdkProfile;
      _lastObservedSdkProfile = nextSdkProfile;
      state = state.copyWith(
        clientPremiumActive: next.premiumActive,
        clearClientPremiumActive: next.premiumActive == null,
        billingReady: next.phase == BillingPhase.ready,
      );
      if (sdkProfileChanged &&
          previous?.phase == BillingPhase.ready &&
          accountId != null &&
          next.phase == BillingPhase.ready) {
        _requestServerReconciliation(accountId, generation);
      }
    });
    ref.onDispose(() => _expiryTimer?.cancel());
    if (accountId != null) {
      // Account access is independent of native store support. Wait until the
      // provider has returned its initial state before starting reconciliation.
      unawaited(
        Future<void>(() async {
          if (_isCurrentAccount(generation, accountId) &&
              state.syncedAt == null) {
            await _syncForAccount(accountId, generation);
          }
        }),
      );
    }
    return PurchaseState(
      hasVerifiedAccount: accountId != null,
      billingReady: billingPhase == BillingPhase.ready,
      clientPremiumActive: billing.premiumActive,
    );
  }

  String? _accountId(AsyncValue<AccountSession?> value) {
    if (value.isLoading || value.hasError) return null;
    final id = value.value?.id.trim();
    return id == null || id.isEmpty ? null : id;
  }

  String _requireAccount({required bool requireReadyBilling}) {
    final account = ref.read(accountSessionProvider);
    if (account.isLoading || account.hasError) {
      throw StateError('Anmeldestatus konnte nicht bestätigt werden.');
    }
    final id = account.value?.id.trim();
    if (id == null || id.isEmpty) {
      throw StateError('Bitte zuerst mit einem bestätigten Konto anmelden.');
    }
    if (requireReadyBilling &&
        ref.read(billingProvider).phase != BillingPhase.ready) {
      throw StateError('Der Store ist noch nicht bereit.');
    }
    return id;
  }

  bool _isCurrentAccount(int generation, String? accountId) {
    if (!ref.mounted || generation != _generation) return false;
    final session = ref.read(accountSessionProvider);
    if (session.isLoading || session.hasError) return false;
    final current = _accountId(ref.read(accountSessionProvider));
    return current == accountId;
  }

  bool _isCurrent(int generation, String? accountId) =>
      _isCurrentAccount(generation, accountId) &&
      ref.read(billingProvider).phase == BillingPhase.ready;

  Future<void> load() async {
    final gateway = ref.read(purchaseGatewayProvider);
    late final String? accountId;
    try {
      final session = ref.read(accountSessionProvider);
      if (session.isLoading || session.hasError) {
        throw StateError('Anmeldestatus konnte nicht bestätigt werden.');
      }
      accountId = _accountId(session);
    } catch (error) {
      _fail(error);
      return;
    }
    if (state.phase.isBusy) return;
    final generation = _generation;
    state = state.copyWith(
      phase: PurchasePhase.loading,
      clearError: true,
      clearOutcome: true,
      hasVerifiedAccount: accountId != null,
      billingReady: ref.read(billingProvider).phase == BillingPhase.ready,
      purchaseAllowed: false,
    );
    if (gateway == null || !state.billingReady) {
      _fail(
        StateError(
          gateway == null
              ? 'Premium-Käufe sind auf diesem Gerät nicht verfügbar.'
              : 'Der Store ist noch nicht bereit.',
        ),
        products: const [],
      );
      if (accountId != null) {
        await _syncForAccount(accountId, generation, keepCatalogError: true);
        _flushPendingSdkReconciliation(accountId, generation);
      }
      return;
    }
    try {
      final products = await gateway.loadCatalog(customerUserId: accountId);
      if (!_isCurrent(generation, accountId)) return;
      state = state.copyWith(
        phase: PurchasePhase.ready,
        products: products,
        selectedProductId:
            products.any(
              (product) => product.productId == state.selectedProductId,
            )
            ? state.selectedProductId
            : products.isEmpty
            ? null
            : (products.where((product) => product.isRecommended).isEmpty
                  ? products.first.productId
                  : products
                        .where((product) => product.isRecommended)
                        .first
                        .productId),
        clearSelectedProductId: products.isEmpty,
      );
    } catch (error) {
      if (_isCurrent(generation, accountId)) _fail(error, products: const []);
    }
    // A catalog failure cannot prevent a server-verified gift or subscription
    // from restoring access. Store operations still require a ready catalog.
    if (accountId != null) {
      await _syncForAccount(accountId, generation, keepCatalogError: true);
      _flushPendingSdkReconciliation(accountId, generation);
    }
  }

  void selectProduct(String productId) {
    if (!state.products.any((product) => product.productId == productId)) {
      return;
    }
    state = state.copyWith(
      selectedProductId: productId,
      clearError: true,
      clearOutcome: true,
    );
  }

  Future<void> purchaseSelected() async {
    final gateway = ref.read(purchaseGatewayProvider);
    if (gateway == null) {
      _fail(StateError('Premium-Käufe sind auf diesem Gerät nicht verfügbar.'));
      return;
    }
    late final String accountId;
    try {
      accountId = _requireAccount(requireReadyBilling: true);
      if (!state.products.any(
        (product) => product.productId == state.selectedProductId,
      )) {
        throw StateError('Bitte wähle ein verfügbares Abo aus.');
      }
      if (state.phase.isBusy) return;
      if (!_purchaseConfigurationAllowsAttempt) {
        throw StateError(
          'Käufe sind erst verfügbar, wenn die Store- und Rechtshinweise eingerichtet sind.',
        );
      }
    } catch (error) {
      _fail(error);
      return;
    }
    final generation = _generation;
    final productId = state.selectedProductId!;
    state = state.copyWith(
      phase: PurchasePhase.purchasing,
      clearError: true,
      clearOutcome: true,
      purchaseAllowed: false,
    );
    try {
      await _syncForAccount(accountId, generation);
      if (!_isCurrent(generation, accountId)) return;
      if (!_serverAllowsCurrentStoreOperation) {
        throw StateError(
          'Der Store erlaubt diesen Kauf für dieses Konto nicht.',
        );
      }
      final result = await gateway.purchase(
        customerUserId: accountId,
        productId: productId,
        isCurrent: () => _isCurrent(generation, accountId),
      );
      if (!_isCurrent(generation, accountId)) return;
      final outcome = switch (result) {
        PurchaseOutcome.success => PurchaseResult.success,
        PurchaseOutcome.cancelled => PurchaseResult.cancelled,
        PurchaseOutcome.pending => PurchaseResult.pending,
      };
      state = state.copyWith(
        phase: PurchasePhase.ready,
        lastOutcome: outcome,
        purchaseAllowed:
            _purchaseConfigurationAllowsAttempt && state.serverStoreAllowed,
      );
      if (result == PurchaseOutcome.success) {
        _sdkReconciliationPending = false;
        await _syncForAccount(accountId, generation);
      } else {
        _flushPendingSdkReconciliation(accountId, generation);
      }
    } catch (error) {
      if (_isCurrent(generation, accountId)) _fail(error);
    }
  }

  Future<void> restore() async {
    final gateway = ref.read(purchaseGatewayProvider);
    if (gateway == null) {
      await _restoreAccountAccess();
      return;
    }
    late final String accountId;
    try {
      accountId = _requireAccount(requireReadyBilling: true);
      if (state.phase.isBusy) return;
    } catch (error) {
      _fail(error);
      return;
    }
    final generation = _generation;
    state = state.copyWith(
      phase: PurchasePhase.restoring,
      clearError: true,
      clearOutcome: true,
      purchaseAllowed: false,
    );
    try {
      final result = await gateway.restore(
        customerUserId: accountId,
        isCurrent: () => _isCurrent(generation, accountId),
      );
      if (!_isCurrent(generation, accountId)) return;
      state = state.copyWith(
        phase: PurchasePhase.ready,
        lastOutcome: result == RestoreOutcome.restored
            ? PurchaseResult.restored
            : PurchaseResult.noPurchases,
      );
      _sdkReconciliationPending = false;
      await _syncForAccount(accountId, generation);
      _flushPendingSdkReconciliation(accountId, generation);
    } catch (error) {
      if (_isCurrent(generation, accountId)) _fail(error);
    }
  }

  /// Without a native store there are no store purchases to restore; the
  /// account's server-verified access is all "Wiederherstellen" can check.
  Future<void> _restoreAccountAccess() async {
    late final String accountId;
    try {
      accountId = _requireAccount(requireReadyBilling: false);
      if (state.phase.isBusy) return;
    } catch (error) {
      _fail(error);
      return;
    }
    final generation = _generation;
    await _syncForAccount(accountId, generation);
    if (!_isCurrentAccount(generation, accountId)) return;
    final active = state.hasPremiumUiAccess;
    state = state.copyWith(
      lastOutcome: active
          ? PurchaseResult.restored
          : PurchaseResult.noPurchases,
      clearError: active,
    );
  }

  Future<void> _syncForAccount(
    String accountId,
    int generation, {
    bool keepCatalogError = false,
  }) async {
    if (!_isCurrentAccount(generation, accountId)) return;
    final inFlight = _serverSyncInFlight;
    if (inFlight != null) {
      state = state.copyWith(isSyncing: true, purchaseAllowed: false);
      await inFlight;
      return;
    }
    final completion = Completer<void>();
    final pending = completion.future;
    _serverSyncInFlight = pending;
    try {
      final gateway = ref.read(billingSyncGatewayProvider);
      if (gateway == null) {
        if (_isCurrentAccount(generation, accountId)) {
          state = state.copyWith(
            clearPremiumActive: true,
            sandboxTestActive: false,
            clearActiveProductId: true,
            clearExpiresAt: true,
            clearStartsAt: true,
            clearWillRenew: true,
            clearEnvironment: true,
            clearPurchaseEnvironment: true,
            clearSyncedAt: true,
            serverStoreAllowed: false,
            purchaseAllowed: false,
            isSyncing: false,
          );
        }
        return;
      }
      if (!_isCurrentAccount(generation, accountId)) return;
      state = state.copyWith(
        isSyncing: true,
        purchaseAllowed: false,
        clearAccountSyncError: true,
      );
      try {
        final result = await gateway.sync();
        if (!_isCurrentAccount(generation, accountId)) return;
        state = state.copyWith(
          premiumActive: result.premiumActive,
          sandboxTestActive: sandboxTestAccessAllowed(
            isDebug: ref.read(purchaseConfigurationProvider).isDebug,
            isProfile: ref.read(purchaseConfigurationProvider).isProfile,
            legalDocumentsApproved: ref
                .read(purchaseConfigurationProvider)
                .legalDocumentsApproved,
            sandboxPurchasesEnabled: ref
                .read(purchaseConfigurationProvider)
                .sandboxPurchasesEnabled,
            purchaseAllowed: result.purchaseAllowed,
            purchaseEnvironment: result.purchaseEnvironment,
            environment: result.environment,
            verifiedSandboxActive: result.sandboxActive,
            expiresAt: result.expiresAt,
            now: _clock.now(),
          ),
          activeProductId: result.productId,
          clearActiveProductId: result.productId == null,
          expiresAt: result.expiresAt,
          clearExpiresAt: result.expiresAt == null,
          startsAt: result.startsAt,
          clearStartsAt: result.startsAt == null,
          willRenew: result.willRenew,
          clearWillRenew: result.willRenew == null,
          environment: result.environment,
          purchaseEnvironment: result.purchaseEnvironment,
          syncedAt: result.syncedAt,
          isSyncing: false,
          serverStoreAllowed: _serverAllows(result),
          purchaseAllowed:
              _storeReadyForPurchase &&
              _purchaseConfigurationAllowsAttempt &&
              _serverAllows(result),
        );
        _scheduleExpiryReconciliation(accountId, generation, result);
      } catch (error) {
        if (!_isCurrentAccount(generation, accountId)) return;
        state = state.copyWith(
          clearPremiumActive: true,
          sandboxTestActive: false,
          clearActiveProductId: true,
          clearExpiresAt: true,
          clearStartsAt: true,
          clearWillRenew: true,
          clearEnvironment: true,
          clearPurchaseEnvironment: true,
          clearSyncedAt: true,
          isSyncing: false,
          serverStoreAllowed: false,
          purchaseAllowed: false,
          errorMessage: keepCatalogError ? null : _message(error),
          accountSyncError:
              'Dein Premium-Zugang konnte gerade nicht geprüft werden. '
              'Bitte später erneut versuchen.',
        );
      }
    } finally {
      if (identical(_serverSyncInFlight, pending)) {
        _serverSyncInFlight = null;
      }
      completion.complete();
      _flushPendingSdkReconciliation(accountId, generation);
    }
  }

  void _requestServerReconciliation(String accountId, int generation) {
    if (!_isCurrentAccount(generation, accountId)) return;
    if (state.phase.isBusy || state.isSyncing) {
      _sdkReconciliationPending = true;
      return;
    }
    _sdkReconciliationPending = false;
    unawaited(_syncForAccount(accountId, generation));
  }

  void _flushPendingSdkReconciliation(String accountId, int generation) {
    if (!_sdkReconciliationPending ||
        state.phase.isBusy ||
        state.isSyncing ||
        !_isCurrentAccount(generation, accountId)) {
      return;
    }
    _sdkReconciliationPending = false;
    unawaited(_syncForAccount(accountId, generation));
  }

  void _scheduleExpiryReconciliation(
    String accountId,
    int generation,
    ServerBillingSnapshot result,
  ) {
    _expiryTimer?.cancel();
    final expiresAt = result.expiresAt;
    if ((!result.premiumActive && !state.sandboxTestActive) ||
        expiresAt == null) {
      return;
    }
    final delay = expiresAt.difference(_clock.now());
    if (delay <= Duration.zero) {
      if (_isCurrentAccount(generation, accountId)) {
        state = state.copyWith(
          premiumActive: false,
          sandboxTestActive: false,
          purchaseAllowed: false,
        );
        // This response has already expired in transit. Keep access closed;
        // immediately retrying the same server check can loop indefinitely.
      }
      return;
    }
    _expiryTimer = _clock.schedule(delay, () {
      if (!_isCurrentAccount(generation, accountId) ||
          state.expiresAt != expiresAt ||
          !state.hasPremiumUiAccess) {
        return;
      }
      // Fail closed at the verified expiry even if the app stays open and the
      // next server check is temporarily unavailable.
      state = state.copyWith(
        premiumActive: false,
        sandboxTestActive: false,
        purchaseAllowed: false,
      );
      _requestServerReconciliation(accountId, generation);
    });
  }

  bool get _storeReadyForPurchase =>
      ref.read(purchaseGatewayProvider) != null &&
      ref.read(billingProvider).phase == BillingPhase.ready &&
      state.products.isNotEmpty;

  bool get _purchaseConfigurationAllowsAttempt {
    final config = ref.read(purchaseConfigurationProvider);
    return storeOperationsEnabledForBuild(
      isDebug: config.isDebug,
      isProfile: config.isProfile,
      legalDocumentsApproved: config.legalDocumentsApproved,
      sandboxPurchasesEnabled: config.sandboxPurchasesEnabled,
    );
  }

  bool get _serverAllowsCurrentStoreOperation {
    final config = ref.read(purchaseConfigurationProvider);
    return storeEnvironmentAllowed(
          isDebug: config.isDebug,
          isProfile: config.isProfile,
          legalDocumentsApproved: config.legalDocumentsApproved,
          sandboxPurchasesEnabled: config.sandboxPurchasesEnabled,
          purchaseEnvironment: state.purchaseEnvironment ?? '',
        ) &&
        state.serverStoreAllowed;
  }

  bool _serverAllows(ServerBillingSnapshot snapshot) {
    final config = ref.read(purchaseConfigurationProvider);
    return storeEnvironmentAllowed(
          isDebug: config.isDebug,
          isProfile: config.isProfile,
          legalDocumentsApproved: config.legalDocumentsApproved,
          sandboxPurchasesEnabled: config.sandboxPurchasesEnabled,
          purchaseEnvironment: snapshot.purchaseEnvironment,
        ) &&
        snapshot.purchaseAllowed;
  }

  Future<void> manageSubscriptions() async {
    try {
      final uri = switch (defaultTargetPlatform) {
        TargetPlatform.iOS || TargetPlatform.macOS => Uri.parse(
          'https://apps.apple.com/account/subscriptions',
        ),
        TargetPlatform.android => Uri.parse(
          'https://play.google.com/store/account/subscriptions',
        ),
        _ => null,
      };
      if (uri == null ||
          !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw StateError('Store-Abonnements konnten nicht geöffnet werden.');
      }
    } catch (error) {
      _fail(error);
    }
  }

  void _fail(Object error, {List<PurchaseProduct>? products}) {
    if (!ref.mounted) return;
    state = state.copyWith(
      phase: PurchasePhase.failed,
      products: products,
      errorMessage: _message(error),
      purchaseAllowed: false,
      isSyncing: false,
    );
  }

  String _message(Object error) {
    if (error is StateError) return error.message.toString();
    if (error is TimeoutException ||
        error is HttpException ||
        error is SocketException ||
        error is FormatException) {
      return 'Der Store- oder Kontostatus konnte nicht geprüft werden. Bitte später erneut versuchen.';
    }
    if (error.runtimeType.toString().toLowerCase().contains('adapty')) {
      return 'Der Store konnte die Anfrage nicht abschließen. Bitte erneut versuchen.';
    }
    return 'Der Vorgang konnte nicht abgeschlossen werden. Bitte erneut versuchen.';
  }
}
