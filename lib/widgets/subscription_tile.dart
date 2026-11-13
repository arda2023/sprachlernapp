import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show ScaffoldMessenger, SnackBar;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/billing/billing_sync_gateway.dart';
import '../presentation/providers/purchase_provider.dart';
import '../screens/onboarding/paywall_screen.dart';
import '../screens/onboarding/widgets/account_sheet.dart';
import '../theme/app_theme.dart';
import 'date_format.dart';
import '../presentation/providers/auth_providers.dart';

String subscriptionRestoreNotice(PurchaseState state) {
  if (state.errorMessage != null &&
      (state.premiumActive == true || state.sandboxTestActive)) {
    return state.errorMessage!;
  }
  if (state.sandboxTestActive) return 'Premium-Testabo aktiv (Sandbox).';
  if (state.premiumActive == true) return 'Käufe wurden wiederhergestellt.';
  if (state.lastOutcome == PurchaseResult.restored) {
    return state.premiumActive == null
        ? 'Storekauf gefunden, Kontoabgleich noch offen.'
        : 'Storekauf gefunden, aber kein aktives Premium-Abo bestätigt.';
  }
  if (state.lastOutcome == PurchaseResult.noPurchases &&
      state.premiumActive == false) {
    return 'Für dieses Konto wurde kein Kauf gefunden.';
  }
  return 'Der Kaufstatus konnte nicht bestätigt werden.';
}

/// Premium entry point and current server-confirmed subscription status for
/// the existing grouped Settings surface.
class SubscriptionTile extends ConsumerStatefulWidget {
  const SubscriptionTile({super.key});

  @override
  ConsumerState<SubscriptionTile> createState() => _SubscriptionTileState();
}

class _SubscriptionTileState extends ConsumerState<SubscriptionTile> {
  bool _actionLocked = false;

  @override
  void initState() {
    super.initState();
    Future<void>(() => ref.read(purchaseProvider.notifier).load());
  }

  Future<bool> _ensureAccount() async {
    if (ref.read(purchaseProvider).hasVerifiedAccount) return true;
    final picked = await AccountSheet.show(context, AccountReason.purchase);
    if (picked == null || !mounted) return false;
    try {
      await ref.read(accountSessionProvider.future);
      await Future<void>.delayed(const Duration(milliseconds: 150));
    } catch (_) {
      // A failed account snapshot leaves restore disabled by the provider.
    }
    return mounted && ref.read(purchaseProvider).hasVerifiedAccount;
  }

  Future<void> _restore() async {
    if (_actionLocked) return;
    final state = ref.read(purchaseProvider);
    if (state.phase.isBusy || state.isSyncing) return;
    setState(() => _actionLocked = true);
    try {
      if (!await _ensureAccount() || !mounted) {
        if (mounted) {
          _notice(
            'Bitte melde dich mit dem Konto an, das für das Abo verwendet wurde.',
          );
        }
        return;
      }
      await ref.read(purchaseProvider.notifier).restore();
      if (!mounted) return;
      _notice(subscriptionRestoreNotice(ref.read(purchaseProvider)));
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

  void _notice(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

  void _openPaywall() {
    Navigator.of(context).push(
      PaywallScreen.route(
        plan: (interest: 'dein Thema', dailyGoal: 10),
        onContinue: () {},
      ),
    );
  }

  String _status(PurchaseState state) {
    if (state.sandboxTestActive) {
      final expiry = state.expiresAt;
      if (expiry == null) return 'Premium-Testabo aktiv (Sandbox)';
      final date = formatDateDe(expiry);
      return 'Premium-Testabo aktiv (Sandbox) bis $date';
    }
    if (state.premiumActive == true) {
      final expiry = state.expiresAt;
      if (expiry == null) return 'Premium ist aktiv.';
      final date = formatDateDe(expiry);
      if (state.activeProductId ==
          ServerBillingSnapshot.complimentaryProductId) {
        return 'Kostenlos freigeschaltet bis $date · endet automatisch';
      }
      return state.willRenew == false
          ? 'Aktiv bis $date · keine weitere Verlängerung'
          : 'Aktiv · nächste Verlängerung am $date';
    }
    if (state.clientPremiumActive == true || state.isSyncing) {
      return 'Storeabo gefunden · Kontoabgleich läuft';
    }
    if (state.premiumActive == false) return 'Kein aktives Premium-Abo';
    if (state.accountSyncError != null) return 'Premium-Status nicht geprüft';
    if (state.hasVerifiedAccount) return 'Abostatus wird geprüft';
    return 'Melde dich an, um dein Abo zu prüfen';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(purchaseProvider);
    final colors = context.appColors;
    final active = state.hasPremiumUiAccess;
    final complimentary =
        active &&
        state.activeProductId == ServerBillingSnapshot.complimentaryProductId;
    final busy = _actionLocked || state.phase.isBusy || state.isSyncing;
    final status = _status(state);
    final action = _PillButton(
      label: active ? 'Verwalten' : 'Upgrade',
      semanticsLabel: active ? 'Abo verwalten' : 'Premium ansehen',
      onPressed: active ? (busy ? null : _manageSubscriptions) : _openPaywall,
    );
    final card = Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
      decoration: BoxDecoration(
        color: colors.raisedInk,
        borderRadius: BorderRadius.circular(20),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked =
              constraints.maxWidth < 280 ||
              MediaQuery.textScalerOf(context).scale(1) > 1.3;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.popover.withValues(alpha: 0.15),
                    ),
                    child: Icon(
                      CupertinoIcons.star_fill,
                      size: 20,
                      color: colors.popover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Semantics(
                      label: 'Linglossa Premium. $status',
                      liveRegion: state.isSyncing,
                      excludeSemantics: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Linglossa Premium',
                            style: AppType.chrome(
                              size: 17,
                              weight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            status,
                            style: AppType.chrome(
                              size: 13,
                              weight: FontWeight.w500,
                              color: colors.textMuted,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!stacked && !complimentary) ...[
                    const SizedBox(width: 10),
                    action,
                  ],
                ],
              ),
              if (stacked && !complimentary)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Align(alignment: Alignment.centerRight, child: action),
                ),
            ],
          );
        },
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        card,
        // A store that this device lacks says nothing about active Premium.
        if ((state.accountSyncError ?? (active ? null : state.errorMessage))
            case final error? when error.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
            child: Semantics(
              liveRegion: true,
              child: Text(error, style: AppType.meta(color: colors.error)),
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            minimumSize: const Size(44, 44),
            onPressed: busy ? null : _restore,
            child: Text(
              state.phase == PurchasePhase.restoring
                  ? 'Wird wiederhergestellt …'
                  : 'Käufe wiederherstellen',
              style: AppType.chrome(
                size: 15,
                weight: FontWeight.w500,
                color: busy ? colors.iconOff : colors.textMuted,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Compact orange pill on the right of the plan card.
class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.semanticsLabel,
    required this.onPressed,
  });

  final String label, semanticsLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final enabled = onPressed != null;
    return MergeSemantics(
      child: CupertinoButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        minimumSize: const Size(44, 44),
        child: Semantics(
          button: true,
          label: semanticsLabel,
          enabled: enabled,
          excludeSemantics: true,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: enabled
                  ? colors.popover
                  : colors.popover.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              label,
              style: AppType.chrome(
                size: 15,
                weight: FontWeight.w700,
                color: const Color(0xFFFFFFFF),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
