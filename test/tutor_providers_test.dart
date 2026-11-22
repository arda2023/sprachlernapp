import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/data/tutor/tutor_client.dart';
import 'package:sprachapp/data/tutor/tutor_store.dart';
import 'package:sprachapp/data/user/user_database.dart';
import 'package:sprachapp/domain/tutor.dart';
import 'package:sprachapp/presentation/providers/tutor_providers.dart';
import 'package:sprachapp/presentation/providers/auth_providers.dart';
import 'package:sprachapp/presentation/providers/database_providers.dart';
import 'package:sprachapp/presentation/providers/personal_learning_provider.dart';

import 'fixtures/tutor.dart';

void main() {
  late UserDatabase db;
  late TutorStore store;
  late FakeTutorClient client;
  late ProviderContainer container;
  late TutorSessionController controller;
  bool premium = false, active = true;
  int ids = 1;
  setUp(() async {
    premium = false;
    active = true;
    ids = 1;
    db = UserDatabase(NativeDatabase.memory());
    store = TutorStore(db, lang: 'en');
    client = FakeTutorClient();
    container = ProviderContainer(
      overrides: [
        tutorDependenciesProvider.overrideWith(
          (ref) async => TutorDependencies(
            store: store,
            client: client,
            verify: () async {
              if (!active) {
                throw const TutorFailure('ACCESS_CHANGED', 'Changed');
              }
            },
            premium: () => premium,
            now: () => tutorTestNow,
            newId: () => tutorTestId(ids++),
          ),
        ),
      ],
    );
    await container.read(tutorDependenciesProvider.future);
    controller = container.read(tutorSessionControllerProvider.notifier);
  });
  tearDown(() async {
    container.dispose();
    await client.access.close();
    await db.close();
  });
  TutorSessionState state() => container.read(tutorSessionControllerProvider);

  for (final code in [
    'INPUT_INVALID',
    'MODEL_INVALID',
    'MODEL_UNAVAILABLE',
    'REQUEST_FAILED',
    'CONFLICT',
  ]) {
    test('terminal $code discards pending grade and unlocks editing', () async {
      await controller.startRound();
      client.gradeFailure = TutorFailure(code, 'terminal');
      await controller.submitAnswer('First answer.');
      final failedId = client.gradeRequests.last.id;
      expect(await store.pendingAttempts(), isEmpty);
      expect(state().pendingAnswer, isNull);
      expect(state().status, TutorSessionStatus.answering);
      client.gradeFailure = null;
      await controller.submitAnswer('Edited answer.');
      expect(client.gradeRequests.last.id, isNot(failedId));
      expect(client.gradeRequests.last.answer, 'Edited answer.');
      expect(state().status, TutorSessionStatus.feedback);
    });
    test('terminal $code generation is discarded across restart', () async {
      client.generateFailure = TutorFailure(code, 'terminal');
      await controller.startRound();
      final failedId = client.generationRequests.last.requestId;
      expect(await store.pendingGenerations(), isEmpty);
      controller.endRound();
      client.generateFailure = null;
      await controller.startRound();
      expect(client.generationRequests.last.requestId, isNot(failedId));
      expect(state().status, TutorSessionStatus.answering);
    });
  }
  test(
    'ITEM_EXPIRED retires item and explicit retry replaces without parent',
    () async {
      await controller.startRound();
      final expired = state().currentItem!;
      client.gradeFailure = const TutorFailure(
        'ITEM_EXPIRED',
        'expired',
        status: 410,
      );
      await controller.submitAnswer('My answer.');
      expect(await store.pendingAttempts(), isEmpty);
      final saved = (await store.snapshot()).items.firstWhere(
        (item) => item.id == expired.id,
      );
      expect(saved.status, TutorItemStatus.retired);
      client.gradeFailure = null;
      await controller.retry();
      expect(state().status, TutorSessionStatus.answering);
      expect(state().currentItem!.id, isNot(expired.id));
      expect(client.generationRequests.last.items.single.parentItemId, isNull);
      expect(
        client.generationRequests.last.items.single.skills,
        expired.skills,
      );
    },
  );

  test('availability reuses account, consent and selected language', () async {
    final access = tutorTestAccess();
    var lang = 'en';
    AccountSession? session;
    final availability = ProviderContainer(
      overrides: [
        personalLearningClientProvider.overrideWithValue(access),
        selectedContentLanguageProvider.overrideWith((ref) async => lang),
        accountSessionProvider.overrideWith((ref) => Stream.value(session)),
      ],
    );
    final subscription = availability.listen(
      tutorAvailabilityProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(() async {
      subscription.close();
      availability.dispose();
      await access.close();
    });
    await availability.read(accountSessionProvider.future);
    expect(
      await availability.read(tutorAvailabilityProvider.future),
      TutorAvailability.accountRequired,
    );
    session = (id: 'owner', email: 'fixture@example.invalid');
    availability.invalidate(accountSessionProvider);
    await availability.read(accountSessionProvider.future);
    expect(
      await availability.read(tutorAvailabilityProvider.future),
      TutorAvailability.available,
    );
    await access.setConsent(false);
    await availability.pump();
    expect(
      await availability.read(tutorAvailabilityProvider.future),
      TutorAvailability.consentRequired,
    );
    lang = 'unsupported';
    availability.invalidate(selectedContentLanguageProvider);
    expect(
      await availability.read(tutorAvailabilityProvider.future),
      TutorAvailability.unsupportedLanguage,
    );
  });

  test('dependency change discards a stale generation response', () async {
    final gate = Completer<void>();
    client.beforeGenerate = () => gate.future;
    final start = controller.startRound();
    while (client.generationRequests.isEmpty) {
      await Future<void>.delayed(Duration.zero);
    }
    container.invalidate(tutorDependenciesProvider);
    await container.read(tutorDependenciesProvider.future);
    await container.pump();
    gate.complete();
    await start;
    expect(state().status, TutorSessionStatus.idle);
    expect((await store.snapshot()).items, isEmpty);
  });

  test('MODEL_INVALID prefetch never retries on next; explicit retry starts a new request', () async {
    premium = true;
    client.beforeGenerate = () async {
      if (client.generationRequests.length == 2) {
        client.generateFailure = const TutorFailure('MODEL_INVALID', 'Invalid');
      }
    };
    await controller.startRound();
    for (var n = 0; n < 5; n++) {
      await controller.submitAnswer('answer');
      await controller.next();
    }
    expect(state().status, TutorSessionStatus.error);
    expect(client.generationRequests, hasLength(2));
    final failedId = client.generationRequests.last.requestId;
    client.generateFailure = null;
    await controller.retry();
    expect(state().status, TutorSessionStatus.answering);
    expect(state().index, 5);
    expect(client.generationRequests, hasLength(3));
    expect(client.generationRequests.last.requestId, isNot(failedId));
  });

  test(
    'free round is frozen at three; submit/next persists and derives summary',
    () async {
      await controller.startRound();
      expect(state().status, TutorSessionStatus.answering);
      expect(state().total, 3);
      premium = true;
      await controller.startRound();
      expect(state().total, 3);
      for (var n = 0; n < 3; n++) {
        await controller.submitAnswer('answer');
        expect(state().status, TutorSessionStatus.feedback);
        await controller.submitAnswer('duplicate');
        expect(client.gradeRequests, hasLength(n + 1));
        await controller.next();
      }
      expect(state().status, TutorSessionStatus.completed);
      expect(state().summary!.correct, 3);
      expect(state().summary!.total, 3);
      expect((await store.snapshot()).attempts, hasLength(3));
      expect(await store.remainingFreeToday(tutorTestNow), 0);
      premium = false;
      await controller.startRound();
      expect(state().status, TutorSessionStatus.limitReached);
      expect(state().premiumRequired, true);
    },
  );
  test('premium loads first batch and prefetches next five while answering', () async {
    premium = true;
    final gate = Completer<void>();
    client.beforeGenerate = () async {
      if (client.generationRequests.length == 2) await gate.future;
    };
    await controller.startRound();
    expect(state().status, TutorSessionStatus.answering);
    expect(state().total, 10);
    await controller.submitAnswer('answer');
    expect(state().status, TutorSessionStatus.feedback);
    gate.complete();
    await controller.next();
    // Wait for the queued database transaction, not arbitrary wall-clock time.
    await Future<void>.delayed(Duration.zero);
    expect(client.generationRequests.map((r) => r.items.length), [5, 5]);
    expect(state().total, 10);
  });
  test(
    'offline recovery reuses exact attempt ID and answer, books once',
    () async {
      await controller.startRound();
      client.gradeFailure = const TutorFailure(
        'NETWORK_UNAVAILABLE',
        'Offline',
        uncertain: true,
      );
      await controller.submitAnswer('my answer');
      expect(state().status, TutorSessionStatus.offline);
      expect(state().pendingAnswer, 'my answer');
      final originalId = client.gradeRequests.single.id;
      client.gradeFailure = null;
      await controller.retry();
      expect(state().status, TutorSessionStatus.feedback);
      expect(client.gradeRequests.last.id, originalId);
      expect(client.gradeRequests.last.answer, 'my answer');
      expect((await store.snapshot()).attempts, hasLength(1));
    },
  );
  test(
    'reopening recovers a durable pending answer instead of spending a new ID',
    () async {
      await controller.startRound();
      client.gradeFailure = const TutorFailure(
        'NETWORK_UNAVAILABLE',
        'Offline',
      );
      await controller.submitAnswer('saved answer');
      final id = client.gradeRequests.single.id;
      controller.endRound();
      client.gradeFailure = null;
      await controller.startRound();
      expect(state().total, 1);
      expect(state().pendingAnswer, 'saved answer');
      await controller.submitAnswer(state().pendingAnswer!);
      expect(client.gradeRequests.last.id, id);
    },
  );
  test('failed generation persists ID and explicit retry uses it', () async {
    client.generateFailure = const TutorFailure(
      'NETWORK_UNAVAILABLE',
      'Offline',
    );
    await controller.startRound();
    expect(state().status, TutorSessionStatus.offline);
    final id = client.generationRequests.single.requestId;
    client.generateFailure = null;
    await controller.retry();
    expect(client.generationRequests.last.requestId, id);
    expect(state().status, TutorSessionStatus.answering);
  });
  test('double submit cannot send two grading calls', () async {
    await controller.startRound();
    final gate = Completer<void>();
    client.beforeGrade = () => gate.future;
    final first = controller.submitAnswer('answer');
    await controller.submitAnswer('second');
    gate.complete();
    await first;
    expect(client.gradeRequests, hasLength(1));
  });
  test('revocation after response prevents learning persistence', () async {
    await controller.startRound();
    client.beforeGrade = () async => active = false;
    await controller.submitAnswer('answer');
    expect(state().status, TutorSessionStatus.unavailable);
    expect((await store.snapshot()).attempts, isEmpty);
    expect((await store.snapshot()).skills, isEmpty);
  });
  test('end round during generation ignores stale response', () async {
    final gate = Completer<void>();
    client.beforeGenerate = () => gate.future;
    final start = controller.startRound();
    while (client.generationRequests.isEmpty) {
      await Future<void>.delayed(Duration.zero);
    }
    controller.endRound();
    gate.complete();
    await start;
    expect(state().status, TutorSessionStatus.idle);
    expect((await store.snapshot()).items, isEmpty);
    expect(await store.pendingGenerations(), hasLength(1));
  });
  test('daily-limit response exposes paywall flag; model-invalid does not retry itself', () async {
    await controller.startRound();
    client.gradeFailure = const TutorFailure(
      'TUTOR_DAILY_LIMIT',
      'Limit',
      premiumRequired: true,
    );
    await controller.submitAnswer('answer');
    expect(state().status, TutorSessionStatus.limitReached);
    expect(state().premiumRequired, true);
    client.gradeFailure = const TutorFailure('MODEL_INVALID', 'Invalid');
    await controller.retry();
    expect(state().status, TutorSessionStatus.answering);
    expect(client.gradeRequests, hasLength(2));
  });
}
