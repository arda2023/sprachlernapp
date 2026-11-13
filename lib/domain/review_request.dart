/// Device-local request limits are deliberately stricter than store quotas.
const reviewRequestMinimumInterval = Duration(days: 120);
const reviewRequestWindow = Duration(days: 365);

/// A completed practice session, never a purchase or an error surface.
class ReviewOpportunity {
  const ReviewOpportunity({
    required this.successful,
    required this.activeLearningDays,
    required this.goalReached,
    required this.streakMilestone,
  });

  final bool successful;
  final int activeLearningDays;
  final bool goalReached;
  final bool streakMilestone;
}

/// Eligibility only; no UI, persistence, platform calls or sentiment filtering.
bool shouldRequestReview({
  required ReviewOpportunity opportunity,
  required DateTime now,
  required int previousCompletedSessions,
  required Iterable<DateTime> requestedAt,
  required bool supported,
}) {
  if (!supported ||
      !opportunity.successful ||
      previousCompletedSessions < 1 ||
      opportunity.activeLearningDays < 3 ||
      !(opportunity.goalReached || opportunity.streakMilestone)) {
    return false;
  }
  var recentRequests = 0;
  for (final requested in requestedAt) {
    final age = now.difference(requested);
    // A clock moving backwards must never remove a cooldown.
    if (age < reviewRequestMinimumInterval) return false;
    if (age < reviewRequestWindow) recentRequests++;
  }
  return recentRequests < 3;
}

abstract interface class ReviewGateway {
  Future<bool> isAvailable();
  Future<void> requestReview();
}
