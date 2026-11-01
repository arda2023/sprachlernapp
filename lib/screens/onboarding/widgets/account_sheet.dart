import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, showModalBottomSheet;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import '../../../presentation/providers/account_provider.dart';
import '../../../presentation/providers/content_update_provider.dart';
import '../../../theme/app_theme.dart';
import 'onboarding_motion.dart';

/// A provider is returned only after Supabase confirms a session.
enum AccountProvider {
  apple('Apple'),
  google('Google'),
  email('E-Mail');

  const AccountProvider(this.label);

  final String label;
}

/// Why the sheet opens: an existing account, or the account a purchase
/// needs (docs: free learning needs no account; buying does).
enum AccountReason { signIn, purchase, reauthenticate }

/// Bottom sheet with Apple, Google and e-mail. Returns the picked
/// provider, or null when dismissed.
class AccountSheet extends ConsumerStatefulWidget {
  const AccountSheet({super.key, required this.reason, this.expectedAccountId});

  final AccountReason reason;
  final String? expectedAccountId;

  static Future<AccountProvider?> show(
    BuildContext context,
    AccountReason reason, {
    String? expectedAccountId,
  }) => showModalBottomSheet<AccountProvider>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) =>
        AccountSheet(reason: reason, expectedAccountId: expectedAccountId),
  );

  @override
  ConsumerState<AccountSheet> createState() => _AccountSheetState();
}

class _AccountSheetState extends ConsumerState<AccountSheet> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  bool _busy = false, _emailMode = false;
  String? _sentTo, _error;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  String _message(Object error) {
    if (error is AuthException) {
      return switch (error.code) {
        'otp_expired' =>
          'Der Code ist ungültig oder abgelaufen. Fordere einen neuen an.',
        'over_email_send_rate_limit' || 'over_request_rate_limit' =>
          'Bitte warte kurz, bevor du es erneut versuchst.',
        'signup_disabled' => 'Neue Konten sind noch nicht freigeschaltet.',
        _ => 'Die Anmeldung konnte nicht bestätigt werden. Bitte erneut versuchen.',
      };
    }
    if (error is StateError &&
        error.message.contains('noch nicht eingerichtet')) {
      return 'Diese Anmeldung ist in diesem Build noch nicht eingerichtet.';
    }
    return 'Die Anmeldung hat nicht geklappt. Prüfe deine Verbindung und versuche es erneut.';
  }

  Future<void> _perform(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on AccountLoginCancelled {
      // Dismissing the system sheet keeps this sheet open without an error.
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _social(AccountProvider provider) => _perform(() async {
    await ref.read(accountActionsProvider).signIn(switch (provider) {
      AccountProvider.apple => AccountIdentityProvider.apple,
      AccountProvider.google => AccountIdentityProvider.google,
      AccountProvider.email => throw StateError('E-Mail-Code erforderlich.'),
    });
    if (!await _matchesExpectedAccount()) return;
    if (mounted) Navigator.of(context).pop(provider);
  });

  Future<void> _sendCode() async {
    final address = _email.text.trim();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(address)) {
      setState(() => _error = 'Gib eine gültige E-Mail-Adresse ein.');
      return;
    }
    await _perform(() async {
      if (widget.expectedAccountId != null) {
        // Reauthentication must never create a new account as a side effect.
        await ref.read(contentAuthProvider).requestCode(address);
      } else {
        await ref.read(accountActionsProvider).sendCode(address);
      }
      if (mounted) setState(() => _sentTo = address);
    });
  }

  Future<void> _verifyCode() async {
    final code = _code.text.trim();
    if (!RegExp(r'^\d{6,10}$').hasMatch(code)) {
      setState(
        () => _error = 'Gib den vollständigen Code aus deiner E-Mail ein.',
      );
      return;
    }
    final address = _sentTo;
    if (address == null) return;
    await _perform(() async {
      await ref.read(accountActionsProvider).verifyCode(address, code);
      if (!await _matchesExpectedAccount()) return;
      if (mounted) Navigator.of(context).pop(AccountProvider.email);
    });
  }

  Future<bool> _matchesExpectedAccount() async {
    final expectedId = widget.expectedAccountId;
    if (expectedId == null) return true;
    final currentId = await ref.read(accountIdentityReaderProvider)();
    if (currentId == expectedId) return true;
    // A social or e-mail flow may have replaced the current session. Sign out
    // the unexpected account so it cannot be mistaken for a successful reauth.
    try {
      await ref.read(accountActionsProvider).signOut();
    } catch (_) {
      // The mismatch still blocks deletion; do not report it as successful.
    }
    if (mounted) {
      setState(
        () => _error = 'Das bestätigte Konto ist ein anderes Konto. Das Löschen wurde abgebrochen.',
      );
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final (title, subtitle) = switch (widget.reason) {
      AccountReason.signIn => (
        'Willkommen zurück',
        'Melde dich an. Dein bisheriger Lernstand bleibt auf diesem Gerät.',
      ),
      AccountReason.purchase => (
        'Konto für dein Abo',
        'Damit Premium auf allen deinen Geräten gilt.',
      ),
      AccountReason.reauthenticate => (
        'Erneut anmelden',
        'Melde dich mit demselben Konto erneut an. Bei einem anderen Konto wird das Löschen abgebrochen.',
      ),
    };
    return PopScope(
      canPop: !_busy,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            16 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: AppType.editorial(color: colors.textPrimary, size: 24),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: AppType.chrome(size: 15, color: colors.textMuted),
              ),
              const SizedBox(height: 22),
              if (!_emailMode) ...[
                _ProviderButton(
                  provider: AccountProvider.apple,
                  icon: const Icon(
                    Icons.apple,
                    size: 22,
                    color: Color(0xFF000000),
                  ),
                  fill: const Color(0xFFFFFFFF),
                  foreground: const Color(0xFF000000),
                  onTap: _busy ? null : () => _social(AccountProvider.apple),
                ),
                const SizedBox(height: 10),
                _ProviderButton(
                  provider: AccountProvider.google,
                  icon: Text(
                    'G',
                    style: AppType.chrome(
                      size: 20,
                      weight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                  fill: colors.nightPage,
                  foreground: colors.textPrimary,
                  onTap: _busy ? null : () => _social(AccountProvider.google),
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
                  onTap: _busy ? null : () => setState(() => _emailMode = true),
                ),
              ] else ...[
                Text(
                  'E-Mail-Adresse',
                  style: AppType.chrome(color: colors.textPrimary),
                ),
                const SizedBox(height: 6),
                CupertinoTextField(
                  controller: _email,
                  enabled: !_busy && _sentTo == null,
                  placeholder: 'E-Mail-Adresse',
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  autocorrect: false,
                  padding: const EdgeInsets.all(16),
                  style: AppType.chrome(color: colors.textPrimary),
                  decoration: BoxDecoration(
                    color: colors.raisedInk,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                const SizedBox(height: 12),
                if (_sentTo != null) ...[
                  Text(
                    'Wir haben einen Code an $_sentTo gesendet. Prüfe auch den Spamordner.',
                    style: AppType.chrome(color: colors.textMuted),
                  ),
                  const SizedBox(height: 12),
                  CupertinoTextField(
                    controller: _code,
                    enabled: !_busy,
                    placeholder: 'E-Mail-Code',
                    keyboardType: TextInputType.number,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    autocorrect: false,
                    maxLength: 10,
                    padding: const EdgeInsets.all(16),
                    style: AppType.chrome(color: colors.textPrimary),
                    decoration: BoxDecoration(
                      color: colors.raisedInk,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  Text(
                    widget.expectedAccountId == null
                        ? 'Du bekommst einen Anmeldecode. Falls du noch kein Konto hast, wird eines angelegt.'
                        : 'Du bekommst einen Code für ein bestehendes Konto. Es wird kein neues Konto angelegt.',
                    style: AppType.chrome(color: colors.textMuted),
                  ),
                  const SizedBox(height: 12),
                ],
                GlowButton(
                  label: _sentTo == null ? 'Code senden' : 'Code bestätigen',
                  onPressed: _busy
                      ? null
                      : _sentTo == null
                      ? _sendCode
                      : _verifyCode,
                ),
                if (_sentTo != null)
                  CupertinoButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                            _sentTo = null;
                            _code.clear();
                            _error = null;
                          }),
                    child: const Text(
                      'Andere Adresse oder neuen Code verwenden',
                    ),
                  ),
                CupertinoButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                          _emailMode = false;
                          _error = null;
                        }),
                  child: const Text('Zurück zur Kontoauswahl'),
                ),
              ],
              if (_busy)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(child: CupertinoActivityIndicator()),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      _error!,
                      style: AppType.chrome(color: colors.error),
                    ),
                  ),
                ),
            ],
          ),
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
    required this.onTap,
  });

  final AccountProvider provider;
  final Widget icon;
  final Color fill, foreground;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final label = 'Mit ${provider.label} fortfahren';
    return Pressable(
      label: label,
      haptic: Haptic.primary,
      minSize: const Size(44, 54),
      onTap: onTap,
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
