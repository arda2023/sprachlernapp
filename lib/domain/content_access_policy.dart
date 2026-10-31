/// A local decision about whether an action can use content access right now.
///
/// This policy only resolves the current entitlement state. Product-specific
/// feature rules belong at their call sites so adding a future feature does
/// not silently create a new access restriction.
enum ContentAccessDecision { allowed, premiumRequired, statusUnknown }

class ContentAccessPolicy {
  const ContentAccessPolicy._();

  static ContentAccessDecision decide({
    required bool hasPremiumAccess,
    required bool hasVerifiedAccount,
    required bool entitlementKnown,
  }) {
    if (hasPremiumAccess) return ContentAccessDecision.allowed;
    if (!hasVerifiedAccount) return ContentAccessDecision.premiumRequired;
    if (!entitlementKnown) return ContentAccessDecision.statusUnknown;
    return ContentAccessDecision.premiumRequired;
  }
}
