import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/preferences.dart';
import '../presentation/providers/preferences_provider.dart';
import '../screens/onboarding/paywall_screen.dart';
import '../theme/app_theme.dart';

/// The same closable offer from every locked content entry.
Future<void> showPremiumContentPaywall(
  BuildContext context, {
  required String interest,
}) {
  final container = ProviderScope.containerOf(context, listen: false);
  final preferences =
      container.read(preferencesProvider).asData?.value ??
      const PracticePreferences();
  return Navigator.of(context).push<void>(
    PaywallScreen.route(
      plan: (interest: interest, dailyGoal: preferences.dailyGoal),
      onContinue: () {},
    ),
  );
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
