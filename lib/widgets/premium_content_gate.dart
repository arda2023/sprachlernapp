import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/preferences.dart';
import '../domain/premium_offer.dart';
import '../presentation/providers/premium_access_provider.dart';
import '../presentation/providers/preferences_provider.dart';
import '../screens/onboarding/paywall_screen.dart';
import '../theme/app_theme.dart';

/// The same closable offer from every locked content entry.
Future<bool> showPremiumContentPaywall(
  BuildContext context, {
  required String interest,
  PremiumOfferReason? reason,
}) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final preferences =
      container.read(preferencesProvider).asData?.value ??
      const PracticePreferences();
  var confirmed = false;
  await Navigator.of(context).push<void>(
    PaywallScreen.route(
      plan: (interest: interest, dailyGoal: preferences.dailyGoal),
      onContinue: () {},
      onUnlocked: () => confirmed = true,
      reason: reason ?? PremiumOfferReason.fromInterest(interest),
    ),
  );
  return confirmed &&
      context.mounted &&
      container.read(premiumContentAccessProvider);
}

/// Non-interactive mark. The enclosing content control names the locked state.
class PremiumLockBadge extends StatelessWidget {
  const PremiumLockBadge({super.key, this.onDark = false, this.size = 28});

  final bool onDark;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1D26),
        shape: BoxShape.circle,
      ),
      child: Icon(
        CupertinoIcons.lock_fill,
        size: size * 0.5,
        color: const Color(0xFFFFFFFF),
      ),
    ),
  );
}

/// Locked content stays visible but sinks under a dark veil; only the lock
/// (and on story covers the title) rests above it (user request 15.11.2026:
/// the small lock badge alone was too easy to miss). The last child of a
/// [Stack] that has the card's size, or between a cover and its title.
class PremiumVeil extends StatelessWidget {
  const PremiumVeil({
    super.key,
    required this.radius,
    this.lock = Alignment.center,
    this.lockSize = 40,
  });

  final BorderRadius radius;
  final AlignmentGeometry lock;
  final double lockSize;

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: IgnorePointer(
      child: ExcludeSemantics(
        child: ClipRRect(
          borderRadius: radius,
          child: ColoredBox(
            // Light cards need less black to read as clearly dimmed.
            color: Color(context.appColors.light ? 0x4D000000 : 0x66000000),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: lock,
                child: Container(
                  width: lockSize,
                  height: lockSize,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFFFFF),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Color(0x40000000), blurRadius: 12),
                    ],
                  ),
                  child: Icon(
                    CupertinoIcons.lock_fill,
                    size: lockSize * 0.45,
                    color: const Color(0xFF1A1D26),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// A single explicit unlock action beside the still-browsable content.
class PremiumUnlockCard extends StatelessWidget {
  const PremiumUnlockCard({
    super.key,
    required this.title,
    required this.detail,
    required this.onPressed,
  });

  final String title, detail;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.raisedInk,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PremiumLockBadge(),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppType.editorial(size: 20, color: colors.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(detail, style: AppType.chrome(color: colors.textMuted)),
          const SizedBox(height: 14),
          CupertinoButton(
            onPressed: onPressed,
            padding: EdgeInsets.zero,
            minimumSize: const Size(44, 44),
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              decoration: BoxDecoration(
                color: colors.popover,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                'Premium freischalten',
                style: AppType.chrome(
                  weight: FontWeight.w700,
                  color: AppColors.onActive,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
