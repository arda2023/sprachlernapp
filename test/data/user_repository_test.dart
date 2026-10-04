// user.db (Drift): card state, append-only review_log, one booking per pass,
// atomic writes, restart. Files in a temp folder; no network.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/data/user/drift_user_repository.dart';
import 'package:sprachapp/data/user/user_database.dart';
import 'package:sprachapp/domain/srs_state.dart';

void main() {
  late Directory tmp;
  late File file;
  late UserDatabase db;
  late DriftUserRepository repo;

  final now = DateTime(2026, 10, 3, 22, 40);

  DriftUserRepository open() {
    db = UserDatabase.file(file);
    return repo = DriftUserRepository(db, lang: 'en');
  }

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('user_repo_');
    file = File('${tmp.path}/user.db');
    open();
  });
  tearDown(() async {
    await repo.close();
    tmp.deleteSync(recursive: true);
  });

  ReviewRecord record({
    String id = 'pass-1',
    String cardId = 'card-went',
    int boxBefore = 0,
    int boxAfter = 3,
    bool hintUsed = false,
    bool revealed = false,
    int errorCount = 0,
    bool firstAttemptCorrect = true,
  }) => ReviewRecord(
    id: id,
    cardId: cardId,
    createdAt: now.toUtc(),
    mode: ReviewMode.deck,
    sentenceId: 's-went-1',
    firstAttemptCorrect: firstAttemptCorrect,
    errorCount: errorCount,
    revealed: revealed,
    hintUsed: hintUsed,
    boxBefore: boxBefore,
    boxAfter: boxAfter,
    dueAtAfter: DateTime(2026, 10, 17),
    responseMs: 4200,
    appVersion: '1.0.0+1',
    deviceId: 'dev-1',
  );

  Matcher sqlError(String text) => throwsA(
    predicate((e) => e.toString().contains(text), 'error containing "$text"'),
  );

  Future<int> logRows() async =>
      (await db
              .customSelect('SELECT count(*) AS n FROM review_log')
              .getSingle())
          .read<int>('n');

  test('cards are created at first display in box 0, once', () async {
    await repo.ensureCards(
      ['card-went', 'card-about', 'card-went'],
      now: now,
      origin: CardOrigin.deck,
    );
    final states = await repo.cardStates(['card-went', 'card-about', 'card-x']);
    expect(states.keys, unorderedEquals(['card-went', 'card-about']));
    expect(states['card-went']!.box, 0);
    expect(states['card-went']!.dueAt, isNull);
    expect(states['card-went']!.origin, CardOrigin.deck);

    await repo.recordReview(record());
    await repo.ensureCards(['card-went'], now: now, origin: CardOrigin.story);
    final again = (await repo.cardStates(['card-went']))['card-went']!;
    expect(again.box, 3); // an existing card is never reset
    expect(again.origin, CardOrigin.deck);
  });

  test('a review stores the log row and the card state together', () async {
    await repo.ensureCards(['card-went'], now: now, origin: CardOrigin.deck);
    expect(
      await repo.recordReview(
        record(hintUsed: true, boxAfter: 1, firstAttemptCorrect: false),
      ),
      isTrue,
    );
    final state = (await repo.cardStates(['card-went']))['card-went']!;
    expect(state.box, 1);
    expect(state.dueAt!.isAtSameMomentAs(DateTime(2026, 10, 17)), isTrue);

    final [log] = await repo.reviewsFor('card-went');
    expect(log.id, 'pass-1');
    expect(log.hintUsed, isTrue);
    expect(log.revealed, isFalse);
    expect(log.firstAttemptCorrect, isFalse);
    expect(log.errorCount, 0);
    expect([log.boxBefore, log.boxAfter], [0, 1]);
    expect(log.mode, ReviewMode.deck);
    expect(log.sentenceId, 's-went-1');
    expect(log.responseMs, 4200);
    expect(log.createdAt.isAtSameMomentAs(now), isTrue);
    expect(log.createdAt.millisecond, now.millisecond);
    expect([log.appVersion, log.deviceId], ['1.0.0+1', 'dev-1']);
  });

  test('hint_used and revealed are stored independently', () async {
    await repo.ensureCards(['a', 'b'], now: now, origin: CardOrigin.deck);
    await repo.recordReview(
      record(
        id: 'p-a',
        cardId: 'a',
        hintUsed: true,
        revealed: true,
        boxAfter: 1,
      ),
    );
    await repo.recordReview(
      record(id: 'p-b', cardId: 'b', revealed: true, boxAfter: 1),
    );
    expect(
      (await repo.reviewsFor('a')).single,
      isA<ReviewRecord>()
          .having((r) => r.hintUsed, 'hintUsed', isTrue)
          .having((r) => r.revealed, 'revealed', isTrue),
    );
    expect(
      (await repo.reviewsFor('b')).single,
      isA<ReviewRecord>()
          .having((r) => r.hintUsed, 'hintUsed', isFalse)
          .having((r) => r.revealed, 'revealed', isTrue),
    );
  });

  group('one booking per pass', () {
    setUp(
      () => repo.ensureCards(['card-went'], now: now, origin: CardOrigin.deck),
    );

    test('the same pass id again is a no-op, also for the card state', () async {
      expect(await repo.recordReview(record()), isTrue);
      expect(await repo.recordReview(record()), isFalse);
      // A different outcome under the same id must not change anything either.
      expect(
        await repo.recordReview(record(boxBefore: 3, boxAfter: 4)),
        isFalse,
      );
      expect(await logRows(), 1);
      expect((await repo.cardStates(['card-went']))['card-went']!.box, 3);
    });

    test('concurrent bookings of one pass write one row', () async {
      final results = await Future.wait([
        repo.recordReview(record()),
        repo.recordReview(record()),
        repo.recordReview(record()),
      ]);
      expect(results.where((r) => r), hasLength(1));
      expect(await logRows(), 1);
      expect((await repo.cardStates(['card-went']))['card-went']!.box, 3);
    });

    test('the primary key rejects a duplicate id at database level', () async {
      await repo.recordReview(record());
      await expectLater(
        db.customStatement(
          "INSERT INTO review_log (id, card_id, created_at, mode, sentence_id, "
          "first_attempt_correct, error_count, revealed, hint_used, box_before, "
          "box_after, due_at_after, response_ms, app_version, device_id) "
          "VALUES ('pass-1', 'card-went', '2026-10-03T20:40:00.000Z', 'deck', "
          "'s', 1, 0, 0, 0, 0, 3, '2026-10-17T00:00:00.000Z', 1, 'v', 'd')",
        ),
        sqlError('UNIQUE constraint failed: review_log.id'),
      );
      expect(await logRows(), 1);
    });

    test('review_log is append-only, also for raw SQL', () async {
      await repo.recordReview(record());
      await expectLater(
        db.customStatement('UPDATE review_log SET error_count = 5'),
        sqlError('review_log is append-only'),
      );
      await expectLater(
        db.customStatement('DELETE FROM review_log'),
        sqlError('review_log is append-only'),
      );
      expect(await logRows(), 1);
      expect((await repo.reviewsFor('card-went')).single.errorCount, 0);
    });

    test('check constraints guard boxes and modes', () async {
      await expectLater(
        db.customStatement("UPDATE user_cards SET box = 7"),
        sqlError('CHECK constraint failed'),
      );
      await expectLater(
        db.customStatement(
          "INSERT INTO user_cards (card_id, lang, box, created_at, origin, updated_at) "
          "VALUES ('x', 'en', 1, '2026-10-03T00:00:00.000Z', 'import', '2026-10-03T00:00:00.000Z')",
        ),
        sqlError('CHECK constraint failed'),
      );
    });
  });

  group('failed transactions leave no half review', () {
    test('a card without a row: no log row', () async {
      await expectLater(
        repo.recordReview(record(cardId: 'card-unseen')),
        throwsStateError,
      );
      expect(await logRows(), 0);
    });

    test('a stale box: neither log row nor state change', () async {
      await repo.ensureCards(['card-went'], now: now, origin: CardOrigin.deck);
      await repo.recordReview(record()); // box 0 → 3
      await expectLater(
        repo.recordReview(record(id: 'pass-2', boxBefore: 0, boxAfter: 1)),
        throwsStateError,
      );
      expect(await logRows(), 1);
      expect((await repo.cardStates(['card-went']))['card-went']!.box, 3);
      // the failed id was rolled back and is still free
      expect(
        await repo.recordReview(
          record(id: 'pass-2', boxBefore: 3, boxAfter: 4),
        ),
        isTrue,
      );
    });
  });

  test(
    'state, log, settings and device id survive closing and reopening',
    () async {
      await repo.ensureCards(
        ['card-went', 'card-about'],
        now: now,
        origin: CardOrigin.deck,
      );
      await repo.recordReview(
        record(hintUsed: true, boxAfter: 1, firstAttemptCorrect: false),
      );
      await repo.setDeckActive('deck-allg', false, now: now);
      final device = await repo.deviceId();
      await repo.close();

      open();
      final states = await repo.allCardStates();
      expect(states.keys, unorderedEquals(['card-went', 'card-about']));
      expect(states['card-went']!.box, 1);
      expect(
        states['card-went']!.dueAt!.isAtSameMomentAs(DateTime(2026, 10, 17)),
        isTrue,
      );
      expect(states['card-about']!.box, 0);
      final [log] = await repo.reviewsFor('card-went');
      expect([log.id, log.hintUsed, log.boxAfter], ['pass-1', true, 1]);
      expect(await repo.activeDeckIds(['deck-allg']), isEmpty);
      expect(await repo.deviceId(), device);
      // the old pass id is still booked after the restart
      expect(
        await repo.recordReview(record(hintUsed: true, boxAfter: 1)),
        isFalse,
      );
    },
  );

  test('unknown card ids are kept, never rewritten to new ids', () async {
    // An old VERB card from an earlier pack and the new AUX card.
    await repo.ensureCards(
      ['verb-befinden'],
      now: now,
      origin: CardOrigin.deck,
    );
    await repo.recordReview(
      record(id: 'old', cardId: 'verb-befinden', boxAfter: 3),
    );
    final states = await repo.allCardStates();
    expect(states.keys, ['verb-befinden']);
    final counts = deriveVocabBreakdown(
      activeDeckCardIds: {'aux-befinden'},
      cards: states,
      knownCardIds: {'aux-befinden'},
      now: now,
    );
    expect(
      [counts.unseen, counts.due, counts.building, counts.mastered],
      [1, 0, 0, 0],
    );
    expect((await repo.cardStates(['aux-befinden'])), isEmpty);
    expect((await repo.allCardStates())['verb-befinden']!.box, 3);
  });

  test('decks are active until switched off', () async {
    expect(await repo.activeDeckIds(['d1', 'd2']), {'d1', 'd2'});
    await repo.setDeckActive('d2', false, now: now);
    expect(await repo.activeDeckIds(['d1', 'd2']), {'d1'});
    await repo.setDeckActive('d2', true, now: now);
    expect(await repo.activeDeckIds(['d1', 'd2']), {'d1', 'd2'});
  });

  test('review counts per card and change notifications', () async {
    await repo.ensureCards(['a', 'b'], now: now, origin: CardOrigin.deck);
    final events = <void>[];
    final sub = repo.changes().listen(events.add);
    addTearDown(sub.cancel);
    await repo.recordReview(record(id: 'p1', cardId: 'a', boxAfter: 3));
    await repo.recordReview(
      record(id: 'p2', cardId: 'a', boxBefore: 3, boxAfter: 4),
    );
    expect(await repo.reviewCounts(['a', 'b']), {'a': 2});
    await pumpEventQueue();
    expect(events, isNotEmpty);
  });
}
