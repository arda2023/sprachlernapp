import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth/account_deletion_gateway.dart';
import '../presentation/providers/account_provider.dart'
    hide AccountSession, accountSessionProvider;
import '../screens/onboarding/widgets/account_sheet.dart';
import '../theme/app_theme.dart';
import '../presentation/providers/auth_providers.dart';

final accountDeletionGatewayProvider = Provider<AccountDeletionGateway>((ref) {
  final gateway = SupabaseAccountDeletionGateway(
    ref.watch(contentAuthProvider),
  );
  ref.onDispose(gateway.close);
  return gateway;
});

class AccountTile extends ConsumerStatefulWidget {
  const AccountTile({super.key});
  @override
  ConsumerState<AccountTile> createState() => _AccountTileState();
}

class _AccountTileState extends ConsumerState<AccountTile> {
  _AccountOperation? _operation;
  String? _error;

  bool get _busy => _operation != null;

  Future<void> _logout() async {
    setState(() {
      _operation = _AccountOperation.signingOut;
      _error = null;
    });
    try {
      await ref.read(accountActionsProvider).signOut();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Abmelden hat nicht geklappt. Bitte erneut versuchen.',
        );
      }
    } finally {
      if (mounted) setState(() => _operation = null);
    }
  }

  Future<bool> _confirmDeletion() async {
    final text = TextEditingController();
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => CupertinoAlertDialog(
          title: const Text('Konto dauerhaft löschen?'),
          content: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              children: [
                const Text(
                  'Dein Konto und serverseitig gespeicherte Daten werden gelöscht. Dein lokaler Lernstand auf diesem Gerät bleibt erhalten. Ein laufendes Abo musst du separat kündigen: iOS unter Einstellungen > Apple Account > Abonnements, Android im Play Store unter Zahlungen und Abos. Bei Apple-Anmeldung musst du Linglossa danach zusätzlich unter account.apple.com > Mit Apple anmelden entfernen; die Schritte erscheinen nach dem Löschen.',
                ),
                const SizedBox(height: 14),
                CupertinoTextField(
                  autofocus: true,
                  placeholder: 'LÖSCHEN eingeben',
                  onChanged: (_) => setDialogState(() {}),
                  controller: text,
                  textCapitalization: TextCapitalization.characters,
                  autocorrect: false,
                ),
              ],
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Abbrechen'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: text.text.trim() == 'LÖSCHEN'
                  ? () => Navigator.of(dialogContext).pop(true)
                  : null,
              child: const Text('Konto löschen'),
            ),
          ],
        ),
      ),
    );
    text.dispose();
    return confirmed == true;
  }

  Future<void> _deleteAccount(String expectedUserId) async {
    if (!await _confirmDeletion() || !mounted) return;
    if (!await _identityStillMatches(expectedUserId)) {
      _showIdentityChanged();
      return;
    }
    setState(() {
      _operation = _AccountOperation.deleting;
      _error = null;
    });
    final gateway = ref.read(accountDeletionGatewayProvider);
    var deletionCompleted = false;
    try {
      AccountDeletionResult result;
      try {
        result = await gateway.deleteAccount(expectedUserId: expectedUserId);
      } on AccountDeletionException catch (error) {
        if (error.code != 'RECENT_AUTH_REQUIRED') rethrow;
        if (!await _identityStillMatches(expectedUserId)) {
          _showIdentityChanged();
          return;
        }
        if (!mounted) return;
        setState(() => _operation = _AccountOperation.reauthenticating);
        final provider = await AccountSheet.show(
          context,
          AccountReason.reauthenticate,
          expectedAccountId: expectedUserId,
        );
        if (!mounted || provider == null) return;
        if (!await _identityStillMatches(expectedUserId)) {
          _showIdentityChanged();
          return;
        }
        setState(() => _operation = _AccountOperation.deleting);
        result = await gateway.deleteAccount(expectedUserId: expectedUserId);
      }
      deletionCompleted = true;
      await ref.read(accountActionsProvider).signOut();
      if (mounted) {
        await showCupertinoDialog<void>(
          context: context,
          builder: (dialogContext) => CupertinoAlertDialog(
            title: Text(
              result.appleManualRevocationRequired
                  ? 'Apple-Zugriff noch widerrufen'
                  : 'Konto gelöscht',
            ),
            content: Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                result.appleManualRevocationRequired
                    ? 'Dein Linglossa-Konto wurde gelöscht. Öffne anschließend account.apple.com, melde dich an und entferne Linglossa unter „Mit Apple anmelden“, damit Apple den Zugriff ebenfalls beendet.'
                    : 'Dein Linglossa-Konto wurde gelöscht. Dein lokaler Lernstand auf diesem Gerät bleibt erhalten.',
              ),
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Fertig'),
              ),
            ],
          ),
        );
      }
    } on AccountDeletionException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = deletionCompleted
              ? 'Dein Konto wurde bereits gelöscht, aber die lokale Abmeldung ist fehlgeschlagen. Bitte starte die App neu und wähle anschließend „Abmelden“, um die lokale Anmeldung erneut zu bereinigen.'
              : 'Das Konto konnte nicht gelöscht werden. Bitte erneut versuchen.',
        );
      }
    } finally {
      if (mounted) setState(() => _operation = null);
    }
  }

  Future<bool> _identityStillMatches(String expectedUserId) async {
    final currentId = await ref.read(accountIdentityReaderProvider)();
    final sessionId = ref.read(accountSessionProvider).asData?.value?.id;
    return currentId == expectedUserId && sessionId == expectedUserId;
  }

  void _showIdentityChanged() {
    if (mounted) {
      setState(
        () => _error = 'Das angemeldete Konto hat sich geändert. Bitte starte das Löschen für das aktuell angezeigte Konto erneut.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(accountSessionProvider);
    final account = session.asData?.value;
    final accountStatus = session.hasError
        ? 'Kontostatus unbekannt'
        : session.isLoading
        ? 'Kontostatus wird geladen …'
        : account == null
        ? 'Ohne Konto'
        : 'Angemeldet';
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            accountStatus,
            style: AppType.chrome(
              color: colors.textPrimary,
              weight: FontWeight.w600,
            ),
          ),
          if (account?.email != null)
            Text(account!.email!, style: AppType.meta(color: colors.textMuted)),
          Text(
            'Dein Lernstand wird auf diesem Gerät gespeichert.',
            style: AppType.meta(color: colors.textMuted),
          ),
          if (session.hasError)
            Text(
              'Der Kontostatus konnte nicht geladen werden.',
              style: AppType.meta(color: colors.error),
            ),
          if (_error != null)
            Semantics(
              liveRegion: true,
              child: Text(_error!, style: AppType.meta(color: colors.error)),
            ),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(vertical: 12),
            onPressed: _busy || session.isLoading || session.hasError
                ? null
                : account == null
                ? () async {
                    await AccountSheet.show(context, AccountReason.signIn);
                  }
                : _logout,
            child: Text(
              _operation == _AccountOperation.deleting
                  ? 'Konto wird gelöscht …'
                  : _operation == _AccountOperation.reauthenticating
                  ? 'Anmeldung wird bestätigt …'
                  : _operation == _AccountOperation.signingOut
                  ? 'Abmelden …'
                  : account == null
                  ? 'Anmelden oder Konto anlegen'
                  : 'Abmelden',
            ),
          ),
          if (account != null)
            CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 8),
              onPressed: _busy || session.isLoading || session.hasError
                  ? null
                  : () => _deleteAccount(account.id),
              child: Text(
                _busy ? 'Konto wird gelöscht …' : 'Konto dauerhaft löschen',
                style: TextStyle(color: colors.error),
              ),
            ),
        ],
      ),
    );
  }
}

enum _AccountOperation { signingOut, deleting, reauthenticating }
