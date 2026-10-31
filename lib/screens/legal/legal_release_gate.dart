import 'package:flutter/foundation.dart' show kDebugMode, kProfileMode;

/// Public subscriptions remain disabled until the operator has reviewed the
/// legal copy and explicitly opts in at build time.
const legalDocumentsApproved = bool.fromEnvironment(
  'LEGAL_DOCUMENTS_APPROVED',
  defaultValue: false,
);

/// Development purchases still need the server-side sandbox tester allowlist.
const sandboxPurchasesRequested = bool.fromEnvironment(
  'ENABLE_SANDBOX_PURCHASES',
  defaultValue: false,
);

/// The build flag requests sandbox support. Runtime authorization still
/// depends on the build mode, legal approval, and the server's environment.
bool get legalSandboxPurchasesEnabled => sandboxPurchasesRequested;

bool get legalStoreOperationsEnabled => storeOperationsEnabledForBuild(
  isDebug: kDebugMode,
  isProfile: kProfileMode,
  legalDocumentsApproved: legalDocumentsApproved,
  sandboxPurchasesEnabled: legalSandboxPurchasesEnabled,
);

bool storeOperationsEnabledForBuild({
  required bool isDebug,
  required bool isProfile,
  required bool legalDocumentsApproved,
  required bool sandboxPurchasesEnabled,
}) => isDebug || isProfile ? sandboxPurchasesEnabled : legalDocumentsApproved;

/// Selects the permitted store environment for the current build. A release
/// binary can use Production normally and Sandbox only when explicitly opted
/// in and the legal release gate is also open.
bool storeEnvironmentAllowed({
  required bool isDebug,
  required bool isProfile,
  required bool legalDocumentsApproved,
  required bool sandboxPurchasesEnabled,
  required String purchaseEnvironment,
}) {
  if (isDebug || isProfile) {
    return sandboxPurchasesEnabled && purchaseEnvironment == 'Sandbox';
  }
  if (!legalDocumentsApproved) return false;
  return purchaseEnvironment == 'Production' ||
      (sandboxPurchasesEnabled && purchaseEnvironment == 'Sandbox');
}
