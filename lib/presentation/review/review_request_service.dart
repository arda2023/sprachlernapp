import '../../data/platform/json_store_base.dart';
import '../../domain/review_request.dart';

/// Serializes requests across screens and languages. The quota is device-wide,
/// so signing out or changing accounts cannot reset the request interval.
class ReviewRequestService {
  ReviewRequestService({
    required this.store,
    required this.gateway,
    required this.clock,
    required this.supported,
  });

  final JsonStore store;
  final ReviewGateway gateway;
  final DateTime Function() clock;
  final bool supported;
  final _completed = <Object>{};
  Future<void> _operations = Future.value();

  Future<void> completeSession({
    required Object session,
    required ReviewOpportunity opportunity,
    required bool Function() isCurrent,
  }) {
    if (!supported || !opportunity.successful || !_completed.add(session)) {
      return Future.value();
    }
    final operation = _operations.then((_) async {
      try {
        final raw = await store.read();
        final history = raw == null
            ? <String, Object?>{}
            : Map<String, Object?>.from(raw as Map);
        final previous = (history['completedSessions'] as int?) ?? 0;
        final requests = [
          for (final value in (history['requestedAt'] as List? ?? const []))
            DateTime.parse(value as String).toUtc(),
        ]..sort();
        final next = {
          'completedSessions': previous + 1,
          'requestedAt': [for (final date in requests) date.toIso8601String()],
        };
        // Failed persistence must not cause repeated native requests.
        await store.write(next);
        if (!isCurrent() ||
            !shouldRequestReview(
              opportunity: opportunity,
              now: clock().toUtc(),
              previousCompletedSessions: previous,
              requestedAt: requests,
              supported: supported,
            ) ||
            !await gateway.isAvailable() ||
            !isCurrent()) {
          return;
        }
        requests.add(clock().toUtc());
        next['requestedAt'] = [
          for (final date in requests.reversed.take(3).toList().reversed)
            date.toIso8601String(),
        ];
        // Store attempts, not displayed dialogs: neither platform reports
        // whether the system actually showed the review sheet.
        await store.write(next);
        if (isCurrent()) await gateway.requestReview();
      } catch (_) {
        // Store, filesystem and review failures must not affect practice.
      }
    });
    _operations = operation;
    return operation;
  }
}
