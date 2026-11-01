import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show Scaffold, ScaffoldMessenger, SnackBar;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/billing/billing_sync_gateway.dart';
import '../../data/billing/purchase_gateway.dart'
    show PurchasePlan, PurchaseProduct;
import '../../presentation/onboarding_sounds.dart';
import '../../presentation/providers/account_provider.dart';
import '../../presentation/providers/purchase_provider.dart';
import '../legal/legal_document.dart';
import '../legal/legal_document_screen.dart';
import '../legal/legal_release_gate.dart' show legalStoreOperationsEnabled;

import '../../theme/app_theme.dart';
import '../../widgets/date_format.dart';
import '../../widgets/word_rain.dart';
import 'widgets/account_sheet.dart';
import 'widgets/onboarding_motion.dart';

bool get _purchasesEnabled => legalStoreOperationsEnabled;

/// What the onboarding learned, shown at the top of the paywall (the plan
/// pill flies here from the last onboarding step).
typedef PaywallContext = ({String interest, int dailyGoal});

/// Shared with the plan card on the last onboarding step.
const paywallHeroTag = 'onboarding-plan-card';

/// Closable premium offer. Store products, prices and outcomes come from the
/// billing provider. Two faces (user request 31.10.2026, Mobbin/Refero
/// references Unwind, Mimo, Vocabulary, Bevel, Calm): while the store still
/// offers this account a free trial, a timeline of how the trial runs;
/// afterwards (trial used) the plans side by side. Both open with "Hello"
/// in every learning language sliding in.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({
    super.key,
    required this.plan,
    required this.onContinue,
    this.onboarding = false,
  });

  final PaywallContext plan;

  /// Right after the onboarding: shows the plan pill the onboarding built.
  final bool onboarding;

  /// Finishes the onboarding; the paywall then pops itself so the app
  /// underneath is revealed.
  final VoidCallback onContinue;

  /// Fades in and rises 6 % over the receding onboarding; pops by sliding
  /// back down.
  static Route<void> route({
    required PaywallContext plan,
    required VoidCallback onContinue,
    bool onboarding = false,
  }) => PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 520),
    reverseTransitionDuration: const Duration(milliseconds: 360),
    pageBuilder: (_, _, _) => PaywallScreen(
      plan: plan,
      onContinue: onContinue,
      onboarding: onboarding,
    ),
    transitionsBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: const Interval(0, 0.6, curve: Curves.easeOut),
        ),
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _leaving = false;
  bool _actionLocked = false;
  String? _restoreFailureMessage;

  /// "Alle Pläne" on the trial face: the plans side by side instead.
  bool _showPlans = false;

  @override
  void initState() {
    super.initState();
    Future<void>(() => ref.read(purchaseProvider.notifier).load());
  }

  void _finish({String? notice}) {
    if (_leaving) return;
    _leaving = true;
    if (notice != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(notice)));
    }
    widget.onContinue();
    // Close this page itself: Premium can be found while the account sheet
    // is still above it, and popping the top route would close only that.
    final route = ModalRoute.of(context);
    if (route == null || !route.isActive) return;
    Navigator.of(context)
      ..popUntil((r) => r == route)
      ..pop();
  }

  Future<bool> _ensureVerifiedAccount() async {
    var purchase = ref.read(purchaseProvider);
    if (purchase.hasVerifiedAccount) return true;
    final provider = await AccountSheet.show(
      context,
      purchase.billingReady ? AccountReason.purchase : AccountReason.signIn,
    );
    if (provider == null || !mounted) return false;
    try {
      await ref.read(accountSessionProvider.future);
      await Future<void>.delayed(const Duration(milliseconds: 150));
    } catch (_) {
      // The purchase provider keeps the action blocked until verification.
    }
    if (!mounted) return false;
    purchase = ref.read(purchaseProvider);
    if (!purchase.hasVerifiedAccount) {
      _notice(
        'Das Konto konnte noch nicht bestätigt werden. Bitte erneut versuchen.',
      );
      return false;
    }
    return true;
  }

  Future<void> _checkAccountAccess() async {
    if (_actionLocked) return;
    setState(() => _actionLocked = true);
    try {
      if (!await _ensureVerifiedAccount() || !mounted) return;
      await ref.read(purchaseProvider.notifier).load();
    } finally {
      if (mounted) setState(() => _actionLocked = false);
    }
  }

  Future<void> _subscribe() async {
    if (_actionLocked) return;
    var purchase = ref.read(purchaseProvider);
    if (purchase.phase == PurchasePhase.purchasing ||
        purchase.phase == PurchasePhase.restoring ||
        purchase.isSyncing) {
      return;
    }
    if (!_purchasesEnabled) {
      _notice('Käufe sind in diesem Build noch nicht verfügbar.');
      return;
    }
    setState(() => _actionLocked = true);
    try {
      if (purchase.selectedProductId == null || purchase.products.isEmpty) {
        if (purchase.phase != PurchasePhase.loading) {
          await ref.read(purchaseProvider.notifier).load();
        }
        if (!mounted) return;
        purchase = ref.read(purchaseProvider);
        if (purchase.selectedProductId == null || purchase.products.isEmpty) {
          _notice(
            purchase.errorMessage ?? 'Storepreise sind gerade nicht verfügbar. Bitte erneut versuchen.',
          );
          return;
        }
      }
      if (!await _ensureVerifiedAccount() || !mounted) return;
      purchase = ref.read(purchaseProvider);
      if (!purchase.purchaseAllowed) {
        await ref.read(purchaseProvider.notifier).load();
      }
      if (!mounted) return;
      purchase = ref.read(purchaseProvider);
      if (!purchase.purchaseAllowed) {
        _notice(
          purchase.errorMessage ??
              'Käufe sind für dieses Konto derzeit nicht verfügbar.',
        );
        return;
      }
      await ref.read(purchaseProvider.notifier).purchaseSelected();
    } finally {
      if (mounted) setState(() => _actionLocked = false);
    }
  }

  Future<void> _restore() async {
    if (_actionLocked) return;
    final purchase = ref.read(purchaseProvider);
    if (purchase.phase == PurchasePhase.purchasing ||
        purchase.phase == PurchasePhase.restoring ||
        purchase.isSyncing) {
      return;
    }
    setState(() {
      _actionLocked = true;
      _restoreFailureMessage = null;
    });
    try {
      if (!await _ensureVerifiedAccount() || !mounted) return;
      await ref.read(purchaseProvider.notifier).restore();
      if (!mounted) return;
      final restored = ref.read(purchaseProvider);
      if (restored.phase == PurchasePhase.failed &&
          restored.errorMessage?.isNotEmpty == true) {
        setState(() => _restoreFailureMessage = restored.errorMessage);
      }
    } finally {
      if (mounted) setState(() => _actionLocked = false);
    }
  }

  Future<void> _manageSubscriptions() async {
    final previousError = ref.read(purchaseProvider).errorMessage;
    try {
      await ref.read(purchaseProvider.notifier).manageSubscriptions();
      if (!mounted) return;
      final error = ref.read(purchaseProvider).errorMessage;
      if (error != null && error != previousError) _notice(error);
    } catch (_) {
      if (mounted) _notice('Die Aboverwaltung konnte nicht geöffnet werden.');
    }
  }

  void _notice(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  void _openLegal(LegalDocument document) {
    Navigator.of(context).push(LegalDocumentScreen.route(document: document));
  }

  PurchaseProduct? _productFor(PurchaseState state) {
    final id = state.selectedProductId;
    if (id == null) return null;
    for (final product in state.products) {
      if (product.productId == id) return product;
    }
    return null;
  }

  String _termsFor(PurchaseProduct? product) {
    if (product == null) {
      return 'Der Preis und die Laufzeit werden vom Store geladen.';
    }
    final period =
        product.localizedPeriod ??
        (product.plan == PurchasePlan.yearly ? 'jährlich' : 'monatlich');
    if (product.trialDays case final days?) {
      return '${_days(days)} gratis, dann ${product.localizedPrice} $period. '
          'Vorher im Store kündbar.';
    }
    return '${product.localizedPrice} $period. Automatische Verlängerung, im Store kündbar.';
  }

  String? _statusMessage(PurchaseState purchase) {
    // Only an error observed directly after this screen's restore action can
    // supersede an already active Premium status.
    if (_restoreFailureMessage != null &&
        _restoreFailureMessage == purchase.errorMessage) {
      return _restoreFailureMessage;
    }
    if (purchase.sandboxTestActive) {
      final expiry = purchase.expiresAt;
      if (expiry == null) return 'Premium-Testabo aktiv (Sandbox)';
      final date = formatDateDe(expiry);
      return 'Premium-Testabo aktiv (Sandbox) bis $date.';
    }
    if (purchase.premiumActive == true) {
      final expiry = purchase.expiresAt;
      if (expiry == null) return 'Premium ist aktiv.';
      final date = formatDateDe(expiry);
      if (purchase.activeProductId ==
          ServerBillingSnapshot.complimentaryProductId) {
        return 'Premium ist kostenlos bis $date freigeschaltet und endet automatisch.';
      }
      return purchase.willRenew == false
          ? 'Premium ist bis $date aktiv. Die Verlängerung ist beendet.'
          : 'Premium ist aktiv und verlängert sich am $date.';
    }
    if (purchase.isSyncing) {
      return 'Dein Premium-Zugang wird überprüft.';
    }
    if (purchase.accountSyncError case final error?) return error;
    // Without a store the account is the only way in: name it, so a sign-in
    // with another address is visible.
    if (purchase.premiumActive == false &&
        !purchase.billingReady &&
        purchase.products.isEmpty) {
      final email = ref.read(accountSessionProvider).value?.email;
      return email == null
          ? 'Für dieses Konto ist kein Premium freigeschaltet.'
          : 'Für $email ist kein Premium freigeschaltet.';
    }
    if (purchase.clientPremiumActive == true && !purchase.hasPremiumUiAccess) {
      return 'Ein Storeabo wurde gefunden. Der Kontostatus wird abgeglichen.';
    }
    // Without products the store error card already shows this message.
    if (purchase.errorMessage case final error?
        when error.isNotEmpty && purchase.products.isNotEmpty) {
      return error;
    }
    return switch (purchase.lastOutcome) {
      PurchaseResult.cancelled =>
        'Der Kauf wurde abgebrochen. Es wurde nichts berechnet.',
      PurchaseResult.pending => 'Der Store bestätigt den Kauf noch. Premium wird nach der Bestätigung freigeschaltet.',
      PurchaseResult.restored => 'Käufe wurden geprüft; für dieses Konto wurde kein aktives Abo gefunden.',
      PurchaseResult.noPurchases =>
        'Für dieses Konto wurde kein Kauf gefunden.',
      _ => null,
    };
  }

  String? _purchaseGateMessage(PurchaseState purchase) {
    if (purchase.purchaseAllowed || purchase.hasPremiumUiAccess) return null;
    if (!_purchasesEnabled) {
      return 'Käufe sind in diesem Build noch nicht verfügbar.';
    }
    if (!purchase.billingReady) {
      return 'Der Store ist gerade nicht verfügbar. Bitte später erneut versuchen.';
    }
    if (purchase.hasVerifiedAccount) {
      return 'Käufe sind für dieses Konto derzeit nicht verfügbar.';
    }
    return null;
  }

  bool _canStartPurchase(PurchaseState purchase) =>
      purchase.purchaseAllowed ||
      (purchase.billingReady &&
          _purchasesEnabled &&
          purchase.phase == PurchasePhase.ready &&
          !purchase.hasVerifiedAccount) ||
      (purchase.billingReady &&
          _purchasesEnabled &&
          purchase.phase == PurchasePhase.failed &&
          purchase.hasVerifiedAccount);

  @override
  Widget build(BuildContext context) {
    ref.listen<PurchaseState>(purchaseProvider, (previous, next) {
      if (previous?.hasPremiumUiAccess != true && next.hasPremiumUiAccess) {
        _finish(
          notice: next.sandboxTestActive
              ? 'Premium-Testabo aktiv (Sandbox).'
              : 'Premium ist aktiv.',
        );
      }
    });
    final purchase = ref.watch(purchaseProvider);
    final selectedProduct = _productFor(purchase);
    final busy =
        _actionLocked ||
        purchase.phase == PurchasePhase.purchasing ||
        purchase.phase == PurchasePhase.restoring ||
        purchase.isSyncing;
    final colors = context.appColors;
    // The page is on screen from the first frame of the route; its parts
    // follow in a short cascade while it rises.
    const active = true;
    final products = [...purchase.products]
      ..sort(
        (a, b) => a.plan == b.plan
            ? 0
            : a.plan == PurchasePlan.yearly
            ? -1
            : 1,
      );
    // The trial face while the selected plan still carries a free trial.
    final trialDays = purchase.hasPremiumUiAccess
        ? null
        : selectedProduct?.trialDays;
    final trial = trialDays != null && !_showPlans;
    final plans =
        purchase.phase == PurchasePhase.loading ||
            purchase.phase == PurchasePhase.idle
        ? const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Center(child: CupertinoActivityIndicator()),
          )
        : products.isEmpty
        ? _StoreProductsError(
            message:
                purchase.errorMessage ??
                'Storepreise sind gerade nicht verfügbar.',
            onRetry: () => ref.read(purchaseProvider.notifier).load(),
          )
        : _PlanRow(
            products: products,
            selectedId: purchase.selectedProductId,
            enabled: !busy && purchase.phase == PurchasePhase.ready,
            onSelect: (product) {
              if (product.productId != purchase.selectedProductId) {
                ref.read(onboardingSoundsProvider).select();
                ref
                    .read(purchaseProvider.notifier)
                    .selectProduct(product.productId);
              }
            },
          );
    final needsAccount =
        !purchase.billingReady &&
        purchase.products.isEmpty &&
        !purchase.hasVerifiedAccount;
    final actions = _PaywallActions(
      active: active,
      plans: trial || needsAccount || purchase.hasPremiumUiAccess
          ? null
          : plans,
      purchase: purchase,
      selectedProduct: selectedProduct,
      busy: busy,
      trial: trial,
      canStartPurchase: _canStartPurchase(purchase),
      onContinue: _finish,
      onSubscribe: _subscribe,
      onSignIn: _checkAccountAccess,
      onManage: _manageSubscriptions,
      onAllPlans: trialDays != null && !_showPlans
          ? () => setState(() => _showPlans = true)
          : null,
      statusMessage: _statusMessage(purchase),
      terms: needsAccount
          ? 'Melde dich mit deinem Konto an, um eine vorhandene Premium-Freischaltung zu nutzen.'
          : _termsFor(selectedProduct),
      gateMessage: needsAccount ? null : _purchaseGateMessage(purchase),
      openTerms: () => _openLegal(LegalDocument.terms),
      openPrivacy: () => _openLegal(LegalDocument.privacy),
      openImprint: () => _openLegal(LegalDocument.imprint),
    );
    // Only at very large text sizes would the pinned block crowd out the
    // page; there everything scrolls together.
    final pinActions = MediaQuery.textScalerOf(context).scale(1) <= 1.35;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // "Hello" in every learning language, sliding in.
        Reveal(
          active: active,
          order: 2,
          child: WordCycle(
            words: greetings,
            height: MediaQuery.sizeOf(context).height < 700 ? 96 : 132,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.onboarding) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _PlanPill(plan: widget.plan),
                ),
              ],
              const SizedBox(height: 14),
              Reveal(
                active: active,
                order: 3,
                child: Semantics(
                  header: true,
                  child: Text(
                    trial
                        ? '${_days(trialDays)} gratis lernen'
                        : 'Mehr lesen. Deine eigenen Wörter lernen.',
                    style: AppType.editorial(
                      color: colors.textPrimary,
                      size: 28,
                      height: 1.15,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              if (trial)
                Reveal(
                  active: active,
                  order: 4,
                  child: _TrialTimeline(
                    days: trialDays,
                    price: selectedProduct!,
                  ),
                )
              else
                for (final (i, benefit) in _benefits(
                  widget.plan.interest,
                ).indexed)
                  Reveal(
                    active: active,
                    order: 4 + i,
                    child: _BenefitRow(benefit: benefit),
                  ),
            ],
          ),
        ),
      ],
    );
    return Scaffold(
      backgroundColor: colors.nightPage,
      body: Stack(
        children: [
          // A faint warm glow behind the header – the only light source.
          Positioned(
            top: -160,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: 380,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      colors.popover.withValues(alpha: 0.18),
                      colors.popover.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Chrome row: capped like the app's other bars.
                MediaQuery.withClampedTextScaling(
                  maxScaleFactor: 1.3,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(6, 2, 6, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Pressable(
                          label: 'Schließen',
                          haptic: Haptic.light,
                          onTap: _finish,
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: Icon(
                              CupertinoIcons.xmark,
                              size: 22,
                              color: colors.textMuted,
                            ),
                          ),
                        ),
                        Flexible(
                          child: TextAction(
                            label: purchase.billingReady
                                ? 'Wiederherstellen'
                                : purchase.hasVerifiedAccount
                                ? 'Zugang prüfen'
                                : 'Anmelden',
                            onTap: purchase.billingReady
                                ? _restore
                                : _checkAccountAccess,
                            size: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  // Content that continues under the pinned block fades out
                  // instead of being cut.
                  child: ShaderMask(
                    blendMode: BlendMode.dstIn,
                    shaderCallback: (rect) => LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: const [
                        Color(0xFFFFFFFF),
                        Color(0xFFFFFFFF),
                        Color(0x00FFFFFF),
                      ],
                      stops: [0, (1 - 20 / rect.height).clamp(0.0, 1.0), 1],
                    ).createShader(rect),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: pinActions
                          ? content
                          : Column(children: [content, actions]),
                    ),
                  ),
                ),
                if (pinActions) actions,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "1 Tag" / "3 Tage".
String _days(int days) => days == 1 ? '1 Tag' : '$days Tage';

class _PaywallActions extends StatelessWidget {
  const _PaywallActions({
    required this.active,
    required this.plans,
    required this.purchase,
    required this.selectedProduct,
    required this.busy,
    required this.trial,
    required this.canStartPurchase,
    required this.onContinue,
    required this.onSubscribe,
    required this.onSignIn,
    required this.onManage,
    required this.onAllPlans,
    required this.statusMessage,
    required this.terms,
    required this.gateMessage,
    required this.openTerms,
    required this.openPrivacy,
    required this.openImprint,
  });

  final bool active;

  /// The plans side by side; null on the trial face.
  final Widget? plans;
  final PurchaseState purchase;
  final PurchaseProduct? selectedProduct;
  final bool busy;
  final bool trial;
  final bool canStartPurchase;
  final VoidCallback onContinue;
  final VoidCallback onSubscribe;
  final VoidCallback onSignIn;
  final VoidCallback onManage;
  final VoidCallback? onAllPlans;
  final String? statusMessage;
  final String terms;
  final String? gateMessage;
  final VoidCallback openTerms;
  final VoidCallback openPrivacy;
  final VoidCallback openImprint;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final needsAccount =
        !purchase.billingReady &&
        purchase.products.isEmpty &&
        !purchase.hasVerifiedAccount;
    final complimentary =
        purchase.hasPremiumUiAccess &&
        purchase.activeProductId ==
            ServerBillingSnapshot.complimentaryProductId;
    return Reveal(
      active: active,
      order: 8,
      offset: 10,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (plans case final plans?) ...[
              const SizedBox(height: 12),
              plans,
              const SizedBox(height: 14),
            ],
            if (trial) ...[
              Text(
                terms,
                textAlign: TextAlign.center,
                style: AppType.chrome(
                  size: 13,
                  weight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
            ],
            GlowButton(
              label: complimentary
                  ? 'Weiterlernen'
                  : needsAccount
                  ? 'Mit Konto freischalten'
                  : purchase.hasPremiumUiAccess
                  ? 'Abo verwalten'
                  : purchase.phase == PurchasePhase.loading
                  ? 'Preise werden geladen …'
                  : purchase.phase == PurchasePhase.purchasing
                  ? 'Kauf läuft …'
                  : purchase.isSyncing
                  ? 'Wird überprüft …'
                  : purchase.phase == PurchasePhase.failed &&
                        selectedProduct != null
                  ? 'Erneut versuchen'
                  : selectedProduct?.trialDays != null
                  ? 'Kostenlos testen'
                  : 'Premium abonnieren',
              onPressed: busy
                  ? null
                  : complimentary
                  ? onContinue
                  : needsAccount
                  ? onSignIn
                  : purchase.hasPremiumUiAccess
                  ? onManage
                  : canStartPurchase &&
                        selectedProduct != null &&
                        (purchase.phase == PurchasePhase.ready ||
                            purchase.phase == PurchasePhase.failed)
                  ? onSubscribe
                  : null,
            ),
            const SizedBox(height: 8),
            if (purchase.hasPremiumUiAccess || !trial)
              Text(
                purchase.hasPremiumUiAccess
                    ? statusMessage ?? 'Premium ist aktiv.'
                    : terms,
                textAlign: TextAlign.center,
                style: AppType.meta(color: colors.textMuted),
              ),
            if (!purchase.hasPremiumUiAccess && statusMessage != null)
              Semantics(
                liveRegion: true,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    statusMessage!,
                    textAlign: TextAlign.center,
                    style: AppType.meta(color: colors.textPrimary),
                  ),
                ),
              )
            else if (gateMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  gateMessage!,
                  textAlign: TextAlign.center,
                  style: AppType.meta(color: colors.textMuted),
                ),
              ),
            if (onAllPlans case final onAllPlans?)
              TextAction(label: 'Alle Pläne', onTap: onAllPlans, strong: true),
            TextAction(
              label: 'Kostenlos weiterlernen',
              onTap: onContinue,
              strong: onAllPlans == null,
            ),
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                TextAction(
                  label: 'Nutzungsbedingungen',
                  onTap: openTerms,
                  size: 12,
                ),
                TextAction(label: 'Datenschutz', onTap: openPrivacy, size: 12),
                TextAction(label: 'Impressum', onTap: openImprint, size: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// How the free trial runs, as a vertical track: today everything opens,
/// on the shown date the plan starts (Refero: Unwind; Mobbin: Mimo,
/// Vocabulary). No reminder stop: the app sends no trial reminder yet. The track fills orange up
/// to today and fades out below the last stop.
class _TrialTimeline extends StatelessWidget {
  const _TrialTimeline({required this.days, required this.price});

  final int days;
  final PurchaseProduct price;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final start = DateTime.now().add(Duration(days: days));
    final period =
        price.localizedPeriod ??
        (price.plan == PurchasePlan.yearly ? 'pro Jahr' : 'pro Monat');
    final stops = [
      (
        icon: CupertinoIcons.lock_open_fill,
        title: 'Heute',
        detail: 'Alle Stories, eigene Texte und KI-Übersetzungen.',
      ),
      (
        icon: CupertinoIcons.star_fill,
        title: formatDateDe(start),
        detail:
            'Dein Abo startet: ${price.localizedPrice} $period. '
            'Bis dahin jederzeit kündbar.',
      ),
    ];
    return Stack(
      children: [
        // The track behind the icons: orange at today, fading out.
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: 40,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0, 0.32, 0.7, 1],
                colors: [
                  colors.popover,
                  colors.popover.withValues(alpha: 0.55),
                  colors.raisedInk,
                  colors.raisedInk.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
        Column(
          children: [
            for (final (i, stop) in stops.indexed)
              Semantics(
                container: true,
                label: '${stop.title}. ${stop.detail}',
                excludeSemantics: true,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: i == stops.length - 1 ? 28 : 22,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(
                          stop.icon,
                          size: 18,
                          color: const Color(0xFFFFFFFF),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 9),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stop.title,
                                style: AppType.chrome(
                                  size: 17,
                                  weight: FontWeight.w700,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                stop.detail,
                                style: AppType.chrome(
                                  size: 13,
                                  weight: FontWeight.w400,
                                  color: colors.textMuted,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

typedef _Benefit = ({IconData icon, String title, String detail});

/// The three arguments in the plan's fixed order; the first line picks up
/// the topic chosen in the onboarding.
List<_Benefit> _benefits(String interest) => [
  (
    icon: CupertinoIcons.book,
    title: 'Lies, was dich interessiert',
    detail: 'Alle Storys ohne Tageslimit – auch zu $interest.',
  ),
  (
    icon: CupertinoIcons.doc_text,
    title: 'Lerne mit deinen eigenen Texten',
    detail: 'Texte importieren und Wörter darin üben.',
  ),
  (
    icon: CupertinoIcons.sparkles,
    title: 'Verstehe fehlende Stellen direkt',
    detail: '500 neue KI-Übersetzungen pro Monat.',
  ),
];

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.benefit});

  final _Benefit benefit;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      container: true,
      label: '${benefit.title}. ${benefit.detail}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colors.activeTint,
                shape: BoxShape.circle,
              ),
              child: Icon(benefit.icon, size: 18, color: colors.active),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    benefit.title,
                    style: AppType.chrome(
                      size: 17,
                      weight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    benefit.detail,
                    style: AppType.chrome(
                      size: 13,
                      weight: FontWeight.w400,
                      color: colors.textMuted,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The plans as cards side by side (Mobbin: Bevel, Calm, Fixtured); stacked
/// at very large text sizes. The yearly card carries the saving against
/// twelve months, or the trial length while one is offered.
class _PlanRow extends StatelessWidget {
  const _PlanRow({
    required this.products,
    required this.selectedId,
    required this.enabled,
    required this.onSelect,
  });

  final List<PurchaseProduct> products;
  final String? selectedId;
  final bool enabled;
  final ValueChanged<PurchaseProduct> onSelect;

  /// "−58 %" for the yearly plan against twelve monthly payments.
  String? _saving(PurchaseProduct product) {
    if (product.plan != PurchasePlan.yearly) return null;
    final monthly = products
        .where((p) => p.plan == PurchasePlan.monthly)
        .firstOrNull
        ?.priceAmount;
    final yearly = product.priceAmount;
    if (monthly == null || yearly == null || monthly <= 0) return null;
    final percent = ((1 - yearly / (monthly * 12)) * 100).round();
    return percent >= 5 ? '−$percent %' : null;
  }

  @override
  Widget build(BuildContext context) {
    final stacked = MediaQuery.textScalerOf(context).scale(1) > 1.35;
    final cards = [
      for (final product in products)
        _PlanCard(
          product: product,
          badge: product.trialDays != null
              ? '${_days(product.trialDays!)} gratis'
              : _saving(product),
          selected: product.productId == selectedId,
          enabled: enabled,
          onTap: () => onSelect(product),
        ),
    ];
    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, card) in cards.indexed) ...[
            if (i > 0) const SizedBox(height: 14),
            card,
          ],
        ],
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, card) in cards.indexed) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(child: card),
          ],
        ],
      ),
    );
  }
}

/// One StoreKit/Play product as a card: title and check on top, the
/// localized price large, below it the period or the per-month equivalent.
/// Selected: orange ring (the border carries the state), faint orange tint,
/// filled check that pops in.
class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.product,
    required this.badge,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final PurchaseProduct product;
  final String? badge;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final yearly = product.plan == PurchasePlan.yearly;
    final title = yearly ? 'Jährlich' : 'Monatlich';
    final detail = yearly ? 'Jährliche Abrechnung' : 'Monatliche Abrechnung';
    final period =
        product.localizedPeriod ?? (yearly ? 'pro Jahr' : 'pro Monat');
    final perMonth = yearly && product.priceAmount != null
        ? '${product.formatLike(product.priceAmount! / 12)} / Monat'
        : period;
    return Pressable(
      label:
          '$title, ${product.localizedPrice} $period, $detail'
          '${product.isRecommended ? ', empfohlen' : ''}'
          '${badge == null ? '' : ', $badge'}',
      selected: selected,
      onTap: enabled ? onTap : null,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
            decoration: BoxDecoration(
              color: selected ? colors.activeTint : colors.raisedInk,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? colors.active : const Color(0x00000000),
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppType.chrome(
                          size: 15,
                          weight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    _PlanCheck(selected: selected),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  product.localizedPrice,
                  style: AppType.chrome(
                    size: 24,
                    weight: FontWeight.w800,
                    color: colors.textPrimary,
                    tabular: true,
                  ),
                ),
                const SizedBox(height: 2),
                Text(perMonth, style: AppType.meta(color: colors.textMuted)),
              ],
            ),
          ),
          if (badge case final badge?)
            Positioned(
              top: -10,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.active,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  badge,
                  style: AppType.chrome(
                    size: 13,
                    weight: FontWeight.w800,
                    color: const Color(0xFFFFFFFF),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StoreProductsError extends StatelessWidget {
  const _StoreProductsError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppType.meta(color: colors.textMuted),
        ),
        TextAction(label: 'Erneut versuchen', onTap: onRetry),
      ],
    );
  }
}

/// Radio-style state mark: an empty ring, or a filled orange disc whose
/// check pops in with a slight overshoot.
class _PlanCheck extends StatelessWidget {
  const _PlanCheck({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: selected ? colors.active : const Color(0x00000000),
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? colors.active : colors.textMuted,
          width: 2,
        ),
      ),
      child: AnimatedScale(
        scale: selected ? 1 : 0,
        duration: const Duration(milliseconds: 220),
        curve: selected ? Curves.easeOutBack : Curves.easeIn,
        child: const Icon(
          CupertinoIcons.checkmark_alt,
          size: 14,
          color: Color(0xFFFFFFFF),
        ),
      ),
    );
  }
}

/// The plan pill that heads the plan card on the last onboarding step.
/// Same Hero tag and widget, so it flies here during the transition.
class _PlanPill extends StatelessWidget {
  const _PlanPill({required this.plan});

  final PaywallContext plan;

  @override
  Widget build(BuildContext context) => Hero(
    tag: paywallHeroTag,
    child: PlanSummaryPill(plan: plan),
  );
}

/// Compact plan summary: "Dein Plan · Reisen · 10 Wörter / Tag".
class PlanSummaryPill extends StatelessWidget {
  const PlanSummaryPill({super.key, required this.plan});

  final PaywallContext plan;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      label: 'Dein Plan: ${plan.interest}, ${plan.dailyGoal} Wörter am Tag',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 7, 14, 7),
        decoration: BoxDecoration(
          color: colors.raisedInk,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.checkmark_seal_fill,
              size: 18,
              color: colors.progressWords,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Dein Plan · ${plan.interest} · ${plan.dailyGoal} Wörter / Tag',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppType.meta(color: colors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
