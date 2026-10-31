import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/content_access_policy.dart';
import 'purchase_provider.dart';

/// Current local entitlement decision. Callers apply this only to the feature
/// action they explicitly gate; this provider does not assign feature rules.
final contentAccessProvider = Provider<ContentAccessDecision>((ref) {
  final purchase = ref.watch(purchaseProvider);
  return ContentAccessPolicy.decide(
    hasPremiumAccess: purchase.hasPremiumUiAccess,
    hasVerifiedAccount: purchase.hasVerifiedAccount,
    entitlementKnown: purchase.premiumActive != null,
  );
});
