import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/data/platform/json_store_base.dart';
import 'package:sprachapp/domain/review_request.dart';
import 'package:sprachapp/presentation/review/review_request_service.dart';

class FakeReviewGateway implements ReviewGateway {
  int checks = 0;
  int requests = 0;
  bool available = true;
  bool fail = false;
  Completer<bool>? availability;

  @override
  Future<bool> isAvailable() async {
    checks++;
    return availability?.future ?? available;
  }

  @override
  Future<void> requestReview() async {
    requests++;
    if (fail) throw StateError('Store unavailable');
  }
}

class FailingReviewStore extends MemoryJsonStore {
  @override
  Future<void> write(Object? json) async => throw StateError('Disk full');
}

const reviewSuccess = ReviewOpportunity(
  successful: true,
  activeLearningDays: 3,
  goalReached: true,
  streakMilestone: false,
);

void main() {
  final now = DateTime.utc(2026, 11, 13, 18);

  bool eligible({
    int previous = 1,
    List<DateTime> requests = const [],
    bool supported = true,
    ReviewOpportunity opportunity = reviewSuccess,
  }) => shouldRequestReview(
    opportunity: opportunity,
    now: now,
    previousCompletedSessions: previous,
    requestedAt: requests,
    supported: supported,
  );

  test(
    'first session, unsupported platform and early learning do not qualify',
    () {
      expect(eligible(), isTrue);
      expect(eligible(previous: 0), isFalse);
      expect(eligible(supported: false), isFalse);
      expect(
        eligible(
          opportunity: const ReviewOpportunity(
            successful: true,
            activeLearningDays: 2,
            goalReached: true,
            streakMilestone: false,
          ),
        ),
        isFalse,
      );
    },
  );

  test('only successful goal or streak milestones qualify', () {
    for (final goal in [false, true]) {
      for (final star in [false, true]) {
        for (final success in [false, true]) {
          expect(
            eligible(
              opportunity: ReviewOpportunity(
                successful: success,
                activeLearningDays: 7,
                goalReached: goal,
                streakMilestone: star,
              ),
            ),
            success && (goal || star),
          );
        }
      }
    }
  });

  test('120 day cooldown, including clock rollback and time zones', () {
    expect(eligible(requests: [now]), isFalse);
    expect(eligible(requests: [now.add(const Duration(days: 1))]), isFalse);
    expect(
      eligible(requests: [now.subtract(const Duration(days: 120))]),
      isTrue,
    );
    expect(
      eligible(
        requests: [
          now
              .subtract(const Duration(days: 120))
              .add(const Duration(seconds: 1)),
        ],
      ),
      isFalse,
    );
    expect(
      eligible(requests: [DateTime.parse('2026-11-13T19:00:00+01:00')]),
      isFalse,
    );
  });

  test('at most three attempts in a rolling year', () {
    expect(
      eligible(
        requests: [
          now.subtract(const Duration(days: 120)),
          now.subtract(const Duration(days: 240)),
          now.subtract(const Duration(days: 360)),
        ],
      ),
      isFalse,
    );
    expect(
      eligible(
        requests: [
          now.subtract(const Duration(days: 120)),
          now.subtract(const Duration(days: 240)),
          now.subtract(const Duration(days: 365)),
        ],
      ),
      isTrue,
    );
  });

  late MemoryJsonStore store;
  late FakeReviewGateway gateway;
  late ReviewRequestService service;
  setUp(() {
    store = MemoryJsonStore();
    gateway = FakeReviewGateway();
    service = ReviewRequestService(
      store: store,
      gateway: gateway,
      clock: () => now,
      supported: true,
    );
  });

  Future<void> complete({
    Object? session,
    ReviewOpportunity opportunity = reviewSuccess,
  }) => service.completeSession(
    session: session ?? Object(),
    opportunity: opportunity,
    isCurrent: () => true,
  );

  test(
    'first completion records history; second makes exactly one call',
    () async {
      await complete();
      expect(gateway.requests, 0);
      await complete();
      expect(gateway.requests, 1);
      final history = await store.read() as Map;
      expect(history['completedSessions'], 2);
      expect(history['requestedAt'], [now.toIso8601String()]);
      await complete();
      expect(gateway.requests, 1);
    },
  );

  test(
    'duplicate callbacks and concurrent completions cannot duplicate requests',
    () async {
      await complete();
      final session = Object();
      await Future.wait([
        complete(session: session),
        complete(session: session),
        complete(),
      ]);
      expect(gateway.requests, 1);
      expect((await store.read() as Map)['completedSessions'], 3);
    },
  );

  test('last request survives a new service instance', () async {
    await complete();
    await complete();
    service = ReviewRequestService(
      store: store,
      gateway: gateway,
      clock: () => now,
      supported: true,
    );
    await complete();
    expect(gateway.requests, 1);
  });

  test(
    'failed session, no achievement and unavailable API never request',
    () async {
      await complete(
        opportunity: const ReviewOpportunity(
          successful: false,
          activeLearningDays: 10,
          goalReached: true,
          streakMilestone: true,
        ),
      );
      expect(await store.read(), isNull);
      await complete();
      await complete(
        opportunity: const ReviewOpportunity(
          successful: true,
          activeLearningDays: 10,
          goalReached: false,
          streakMilestone: false,
        ),
      );
      gateway.available = false;
      await complete();
      expect(gateway.requests, 0);
    },
  );

  test('web and desktop do not touch history or the native API', () async {
    service = ReviewRequestService(
      store: store,
      gateway: gateway,
      clock: () => now,
      supported: false,
    );
    await complete();
    expect(await store.read(), isNull);
    expect(gateway.checks, 0);
    expect(gateway.requests, 0);
  });

  test(
    'leaving the screen during API availability lookup cancels the request',
    () async {
      await complete();
      gateway.availability = Completer<bool>();
      var current = true;
      final request = service.completeSession(
        session: Object(),
        opportunity: reviewSuccess,
        isCurrent: () => current,
      );
      await Future<void>.delayed(Duration.zero);
      current = false;
      gateway.availability!.complete(true);
      await request;
      expect(gateway.requests, 0);
      expect((await store.read() as Map)['requestedAt'], isEmpty);
    },
  );

  test(
    'persistence failure fails closed and store failure keeps cooldown',
    () async {
      service = ReviewRequestService(
        store: FailingReviewStore(),
        gateway: gateway,
        clock: () => now,
        supported: true,
      );
      await complete();
      await complete();
      expect(gateway.requests, 0);
      service = ReviewRequestService(
        store: store,
        gateway: gateway,
        clock: () => now,
        supported: true,
      );
      gateway.fail = true;
      await complete();
      await complete();
      await complete();
      expect(gateway.requests, 1);
      expect((await store.read() as Map)['requestedAt'], hasLength(1));
    },
  );

  test('malformed history cannot trigger a native request', () async {
    await store.write({
      'completedSessions': 5,
      'requestedAt': ['not-a-date'],
    });
    await complete();
    expect(gateway.requests, 0);
  });
}
