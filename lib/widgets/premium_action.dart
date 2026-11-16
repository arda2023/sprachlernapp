import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../presentation/providers/auth_providers.dart';
import '../presentation/providers/database_providers.dart';
import '../presentation/providers/language_selection_provider.dart';
import '../presentation/providers/premium_access_provider.dart';
import 'premium_content_gate.dart';

/// Keep the originating language, route and account while a paywall is open.
Future<bool> unlockPremiumAction(
  BuildContext context, {
  required String interest,
  bool allowGuestSignIn = false,
}) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final auth = container.read(contentAuthProvider);
  final owner = auth.localOwner;
  final revision = auth.identityRevision;
  final selected = container.read(selectedContentLanguageProvider);
  final language =
      selected.isLoading || container.read(languageSelectionProvider).switching
      ? null
      : selected.asData?.value;
  final route = ModalRoute.of(context);
  if (route?.isCurrent == false) return false;
  if (!await showPremiumContentPaywall(context, interest: interest) ||
      !context.mounted ||
      route?.isCurrent == false ||
      language == null) {
    return false;
  }
  try {
    final currentLanguage = await container.read(
      selectedContentLanguageProvider.future,
    );
    if (!context.mounted ||
        route?.isCurrent == false ||
        currentLanguage != language ||
        container.read(languageSelectionProvider).switching ||
        !container.read(premiumContentAccessProvider)) {
      return false;
    }
    final currentAuth = container.read(contentAuthProvider);
    return identical(auth, currentAuth) &&
        (auth.localOwner == owner && auth.identityRevision == revision ||
            allowGuestSignIn &&
                owner == null &&
                auth.localOwner != null &&
                auth.identityRevision == revision + 1);
  } catch (_) {
    return false;
  }
}
