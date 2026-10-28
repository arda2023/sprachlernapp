import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, showModalBottomSheet;

import '../../../theme/app_theme.dart';
import 'onboarding_motion.dart';

/// Sign-in options. Placeholder: no provider is wired up yet; the caller
/// says so honestly and carries on without an account.
enum AccountProvider {
  apple('Apple'),
  google('Google'),
  email('E-Mail');

  const AccountProvider(this.label);

  final String label;
}

/// Why the sheet opens: an existing account, or the account a purchase
/// needs (docs: free learning needs no account; buying does).
enum AccountReason { signIn, purchase }

/// Bottom sheet with Apple, Google and e-mail. Returns the picked
/// provider, or null when dismissed.
class AccountSheet extends StatelessWidget {
  const AccountSheet({super.key, required this.reason});

  final AccountReason reason;

  static Future<AccountProvider?> show(
    BuildContext context,
    AccountReason reason,
  ) => showModalBottomSheet<AccountProvider>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => AccountSheet(reason: reason),
  );

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final (title, subtitle) = switch (reason) {
      AccountReason.signIn => (
        'Willkommen zurück',
        'Melde dich an, um deinen Fortschritt zu laden.',
      ),
      AccountReason.purchase => (
        'Konto für dein Abo',
        'Damit Premium auf allen deinen Geräten gilt.',
      ),
    };
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                title,
                style: AppType.editorial(color: colors.textPrimary, size: 26),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: AppType.chrome(size: 15, color: colors.textMuted),
            ),
            const SizedBox(height: 22),
            _ProviderButton(
              provider: AccountProvider.apple,
              icon: const Icon(Icons.apple, size: 22, color: Color(0xFF000000)),
              fill: const Color(0xFFFFFFFF),
              foreground: const Color(0xFF000000),
            ),
            const SizedBox(height: 10),
            _ProviderButton(
              provider: AccountProvider.google,
              icon: Text(
                'G',
                style: AppType.chrome(
                  size: 19,
                  weight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
              fill: colors.nightPage,
              foreground: colors.textPrimary,
            ),
            const SizedBox(height: 10),
            _ProviderButton(
              provider: AccountProvider.email,
              icon: Icon(
                CupertinoIcons.mail,
                size: 20,
                color: colors.textPrimary,
              ),
              fill: colors.nightPage,
              foreground: colors.textPrimary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderButton extends StatelessWidget {
  const _ProviderButton({
    required this.provider,
    required this.icon,
    required this.fill,
    required this.foreground,
  });

  final AccountProvider provider;
  final Widget icon;
  final Color fill, foreground;

  @override
  Widget build(BuildContext context) {
    final label = 'Mit ${provider.label} fortfahren';
    return Pressable(
      label: label,
      haptic: Haptic.primary,
      minSize: const Size(44, 54),
      onTap: () => Navigator.of(context).pop(provider),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 54),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 24, child: Center(child: icon)),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: AppType.chrome(
                  size: 17,
                  weight: FontWeight.w600,
                  color: foreground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
