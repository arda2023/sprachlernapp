import 'repositories.dart';
import 'srs_state.dart';

/// Optional bulk read capability. No stored counters and no learning writes.
abstract interface class ReviewActivityRepository {
  Future<List<ReviewActivity>> reviewActivity(DateTime from, DateTime until);
  Future<Map<String, DateTime>> latestReviewTimes();
}

class ReviewActivity {
  const ReviewActivity(this.cardId, this.at, this.mode);
  final String cardId;
  final DateTime at;
  final ReviewMode mode;
}

extension ReviewActivityReads on UserRepository {
  Future<List<ReviewActivity>> activityBetween(
    DateTime from,
    DateTime until,
  ) async {
    if (this is ReviewActivityRepository) {
      return (this as ReviewActivityRepository).reviewActivity(from, until);
    }
    return [
      for (final id in (await allCardStates()).keys)
        for (final r in await reviewsFor(id))
          if (!r.createdAt.isBefore(from) && r.createdAt.isBefore(until))
            ReviewActivity(id, r.createdAt, r.mode),
    ];
  }

  Future<Map<String, DateTime>> lastReviewTimes() async {
    if (this is ReviewActivityRepository) {
      return (this as ReviewActivityRepository).latestReviewTimes();
    }
    final times = <String, DateTime>{};
    for (final id in (await allCardStates()).keys) {
      final reviews = await reviewsFor(id);
      if (reviews.isNotEmpty) times[id] = reviews.last.createdAt;
    }
    return times;
  }
}

/// Distinct cards with a completed (logged) first pass per local day, in every
/// mode including Revue and chosen Vorab-Üben. Display alone and in-session
/// repeats write no activity and never count.
Map<DateTime, Set<String>> completedTargetsByDay(
  Iterable<ReviewActivity> activity,
) {
  final days = <DateTime, Set<String>>{};
  for (final r in activity) {
    final at = r.at.toLocal();
    (days[DateTime(at.year, at.month, at.day)] ??= {}).add(r.cardId);
  }
  return days;
}
