/// A single SDK profile's access level and matching store subscription.
/// This hint never grants Premium access.
typedef TrialSubscription = ({
  String productId,
  String? introductoryOfferType,
  DateTime? expiresAt,
  bool willRenew,
  bool? isSandbox,
  bool isRefunded,
  bool isInGracePeriod,
  bool isLifetime,
  bool dataConsistent,
});

enum TrialReminderStatus { inactive, unavailable, tooLate, ready }

class TrialReminderPlan {
  const TrialReminderPlan({
    required this.productId,
    required this.expiresAt,
    required this.remindAt,
    required this.isSandbox,
  });

  final String productId;
  final DateTime expiresAt;
  final DateTime remindAt;
  final bool isSandbox;

  String get identity => '$productId:${expiresAt.toUtc().toIso8601String()}';
}

class TrialReminderDecision {
  const TrialReminderDecision(this.status, [this.plan]);
  final TrialReminderStatus status;
  final TrialReminderPlan? plan;
}

/// Require the active SDK trial and the current account's server confirmation
/// to agree. Catalog eligibility and marketing trial lengths are not evidence
/// of an active trial or its billing deadline.
TrialReminderDecision trialReminderDecision({
  required DateTime now,
  required TrialSubscription? subscription,
  required bool purchaseActive,
  required String? purchaseProductId,
  required DateTime? purchaseExpiresAt,
  required bool? purchaseWillRenew,
  required String? purchaseEnvironment,
}) {
  const inactive = TrialReminderDecision(TrialReminderStatus.inactive);
  const unavailable = TrialReminderDecision(TrialReminderStatus.unavailable);
  if (subscription == null ||
      subscription.introductoryOfferType != 'free_trial' ||
      !subscription.willRenew ||
      subscription.isRefunded ||
      subscription.isLifetime ||
      subscription.isInGracePeriod ||
      purchaseWillRenew == false) {
    return inactive;
  }
  final end = subscription.expiresAt;
  final sandbox = subscription.isSandbox;
  if (!subscription.dataConsistent || end == null || sandbox == null) {
    return unavailable;
  }
  if (!end.isAfter(now)) return inactive;
  if (!purchaseActive ||
      purchaseProductId != subscription.productId ||
      purchaseExpiresAt == null ||
      !purchaseExpiresAt.isAtSameMomentAs(end) ||
      purchaseWillRenew != true ||
      purchaseEnvironment != (sandbox ? 'Sandbox' : 'Production')) {
    return unavailable;
  }
  final remindAt = end.toUtc().subtract(
    sandbox ? const Duration(seconds: 30) : const Duration(days: 1),
  );
  if (!remindAt.isAfter(now)) {
    return const TrialReminderDecision(TrialReminderStatus.tooLate);
  }
  return TrialReminderDecision(
    TrialReminderStatus.ready,
    TrialReminderPlan(
      productId: subscription.productId,
      expiresAt: end.toUtc(),
      remindAt: remindAt,
      isSandbox: sandbox,
    ),
  );
}
