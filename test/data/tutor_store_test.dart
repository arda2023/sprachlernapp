import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:sprachapp/data/tutor/tutor_store.dart';
import 'package:sprachapp/data/tutor/tutor_codec.dart';
import 'package:sprachapp/data/user/user_database.dart';
import 'package:sprachapp/domain/tutor.dart';

import '../fixtures/tutor.dart';

void main() {
  late UserDatabase db;
  late TutorStore store;
  setUp(() {
    db = UserDatabase(NativeDatabase.memory());
    store = TutorStore(db, lang: 'en');
  });
  tearDown(() => db.close());
  test(
    'latest-round membership is deterministic even with a fixed clock',
    () async {
      final first = tutorTestItem(),
          second = tutorTestItem(id: 2, skill: 'word_order');
      await store.saveItems([first, second]);
      await store.markShown(first, 'first', tutorTestNow);
      await store.markShown(second, 'second', tutorTestNow);
      var snapshot = await store.snapshot();
      expect(snapshot.previousRoundId, 'second');
      expect(
        snapshot.items.firstWhere((i) => i.id == first.id).lastRoundId,
        isNull,
      );
      await store.markShown(first, 'second', tutorTestNow);
      snapshot = await store.snapshot();
      expect(snapshot.items.every((i) => i.lastRoundId == 'second'), true);
    },
  );
  test(
    'attempt transition atomic, replay idempotent, data scoped by language',
    () async {
      final item = tutorTestItem();
      await store.saveItems([item]);
      await store.markShown(item, 'round', tutorTestNow);
      final pending = await store.prepareAttempt(
        attemptId: tutorTestId(2),
        item: item,
        answer: '  answer  ',
        now: tutorTestNow,
      );
      expect((await store.pendingAttempts()).single.answer, 'answer');
      expect(
        (await store.prepareAttempt(
          attemptId: tutorTestId(3),
          item: item,
          answer: 'answer',
          now: tutorTestNow,
        )).attemptId,
        pending.attemptId,
      );
      await expectLater(
        store.prepareAttempt(
          attemptId: tutorTestId(4),
          item: item,
          answer: 'changed',
          now: tutorTestNow,
        ),
        throwsStateError,
      );
      await expectLater(
        store.completeAttempt(
          pending,
          tutorTestGrade(),
          now: tutorTestNow,
          verify: () => throw StateError('revoked'),
        ),
        throwsStateError,
      );
      expect((await store.snapshot()).skills, isEmpty);
      expect(await store.pendingAttempts(), hasLength(1));
      await store.completeAttempt(pending, tutorTestGrade(), now: tutorTestNow);
      await store.completeAttempt(pending, tutorTestGrade(), now: tutorTestNow);
      final snapshot = await store.snapshot();
      expect(snapshot.attempts, hasLength(1));
      expect(snapshot.skills['present_simple']!.box, 3);
      expect(snapshot.items.single.status, TutorItemStatus.retired);
      expect(snapshot.previousRoundId, 'round');
      expect(await store.pendingAttempts(), isEmpty);
      expect((await TutorStore(db, lang: 'es').snapshot()).items, isEmpty);
      expect((await TutorStore(db, lang: 'es').snapshot()).skills, isEmpty);
    },
  );
  test(
    'rollback at final verification undoes attempt, item and skill writes',
    () async {
      final item = tutorTestItem();
      await store.saveItems([item]);
      final pending = await store.prepareAttempt(
        attemptId: tutorTestId(2),
        item: item,
        answer: 'answer',
        now: tutorTestNow,
      );
      var checks = 0;
      await expectLater(
        store.completeAttempt(
          pending,
          tutorTestGrade(),
          now: tutorTestNow,
          verify: () {
            if (++checks == 2) throw StateError('revoked');
          },
        ),
        throwsStateError,
      );
      final snapshot = await store.snapshot();
      expect(snapshot.skills, isEmpty);
      expect(snapshot.attempts, isEmpty);
      expect(snapshot.items.single.answerShown, false);
      expect(await store.pendingAttempts(), hasLength(1));
    },
  );
  test('quota spans languages, uses server observations, resets at Berlin midnight', () async {
    final es = TutorStore(db, lang: 'es');
    final item = tutorTestItem(lang: 'es');
    await es.saveItems([item]);
    final at = DateTime.utc(2026, 11, 22, 22, 59);
    final pending = await es.prepareAttempt(
      attemptId: tutorTestId(2),
      item: item,
      answer: 'answer',
      now: at,
    );
    await es.completeAttempt(pending, tutorTestGrade(used: 2), now: at);
    expect(await store.remainingFreeToday(at), 1);
    expect(await store.remainingFreeToday(DateTime.utc(2026, 11, 22, 23)), 3);
    expect(tutorBerlinDay(DateTime.utc(2026, 7, 1, 22)), '2026-7-2');
    expect(
      tutorBerlinDay(DateTime.utc(2026, 10, 25, 0, 30)),
      tutorBerlinDay(DateTime.utc(2026, 10, 25, 1, 30)),
    );
  });
  test(
    'generation payload survives, same ID cannot mutate; completion atomic',
    () async {
      final request = TutorGenerationRequest(
        requestId: tutorTestId(99),
        lang: 'en',
        items: [
          TutorItemRequest(
            skills: ['present_simple'],
            origin: TutorOrigin.diagnostic,
          ),
        ],
        avoidTopics: ['reisen'],
      );
      await store.prepareGeneration(request);
      expect(
        (await store.pendingGenerations()).single.toStorageJson(),
        request.toStorageJson(),
      );
      await expectLater(
        store.prepareGeneration(
          TutorGenerationRequest(
            requestId: request.requestId,
            lang: 'en',
            items: [
              TutorItemRequest(skills: ['word_order']),
            ],
          ),
        ),
        throwsStateError,
      );
      var checks = 0;
      await expectLater(
        store.completeGeneration(
          request,
          [tutorTestItem()],
          verify: () {
            if (++checks == 2) throw StateError('changed');
          },
        ),
        throwsStateError,
      );
      expect((await store.snapshot()).items, isEmpty);
      expect(await store.pendingGenerations(), hasLength(1));
      await store.completeGeneration(request, [tutorTestItem()]);
      expect(await store.pendingGenerations(), isEmpty);
      expect((await store.snapshot()).items, hasLength(1));
    },
  );
  test(
    'v9 to v10 preserves every old table value, settings, reviews and triggers',
    () async {
      final dir = Directory.systemTemp.createTempSync('tutor-v10-');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/user.db');
      final original = UserDatabase(NativeDatabase(file));
      await original.customStatement(
        "INSERT INTO settings(id,device_id,target_lang,updated_at) VALUES(1,'device','en',1)",
      );
      await original.customStatement(
        "INSERT INTO user_cards(card_id,lang,box,created_at,origin,updated_at,note) VALUES('card','en',3,1,'deck',1,'keep')",
      );
      await original.customStatement(
        "INSERT INTO review_log(id,card_id,created_at,mode,sentence_id,first_attempt_correct,error_count,revealed,hint_used,box_before,box_after,due_at_after,app_version,device_id) VALUES('review','card',1,'deck','sentence',1,0,0,0,1,3,2,'old','device')",
      );
      await original.close();
      final raw = sqlite.sqlite3.open(file.path);
      for (final name in [
        'tutor_attempts',
        'tutor_items',
        'tutor_skill_states',
        'tutor_generations',
      ]) {
        raw.execute('DROP TABLE $name');
      }
      raw.execute('PRAGMA user_version=9');
      final before = {
        for (final row in raw.select(
          "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
        ))
          row['name'] as String: raw
              .select('SELECT * FROM "${row['name']}"')
              .map((r) => Map<String, Object?>.from(r))
              .toList(),
      };
      raw.close();
      final migrated = UserDatabase(NativeDatabase(file));
      final migratedStore = TutorStore(migrated, lang: 'en');
      expect((await migratedStore.snapshot()).items, isEmpty);
      expect(
        (await migrated.customSelect('PRAGMA user_version').getSingle())
            .read<int>('user_version'),
        10,
      );
      for (final entry in before.entries) {
        expect(
          (await migrated.customSelect('SELECT * FROM "${entry.key}"').get())
              .map((r) => r.data)
              .toList(),
          entry.value,
          reason: entry.key,
        );
      }
      await expectLater(
        migrated.customStatement("DELETE FROM review_log"),
        throwsA(anything),
      );
      final item = tutorTestItem();
      await migratedStore.saveItems([item]);
      await migratedStore.prepareAttempt(
        attemptId: tutorTestId(2),
        item: item,
        answer: 'answer',
        now: tutorTestNow,
      );
      await migrated.close();
      final reopened = UserDatabase(NativeDatabase(file));
      addTearDown(reopened.close);
      expect(
        (await TutorStore(
          reopened,
          lang: 'en',
        ).pendingAttempts()).single.attemptId,
        tutorTestId(2),
      );
      expect(
        (await TutorStore(reopened, lang: 'en').snapshot()).items.single.id,
        item.id,
      );
    },
  );
}
