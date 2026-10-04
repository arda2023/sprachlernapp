import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:sprachapp/data/user/user_database.dart';
import 'package:sprachapp/data/user/drift_user_repository.dart';
import 'package:sprachapp/data/learning/practice_item_resolver.dart';
import 'package:sprachapp/domain/story_learning.dart';
import 'package:sprachapp/domain/srs_state.dart';
import 'package:sprachapp/domain/review_pass.dart';

import '../fixtures/story_learning.dart';

void main() {
  final now = DateTime(2026, 10, 4, 12);
  late UserDatabase db;
  late DriftUserRepository repo;
  setUp(() {
    db = UserDatabase(NativeDatabase.memory());
    repo = DriftUserRepository(db, lang: 'en');
  });
  tearDown(() async => repo.close());
  test('lookup has no writes; concurrent adds are atomic, idempotent and review-free', () async {
    final c = storyCandidate();
    expect((await repo.storyLearningStatus(c)).state, StoryAddState.available);
    expect(await repo.allCardStates(), isEmpty);
    final results = await Future.wait([
      repo.addStoryWord(c, now: now),
      repo.addStoryWord(c, now: now),
    ]);
    expect(results.map((r) => r.cardId).toSet(), {c.identity.localId});
    await repo.addStoryWord(storyCandidate(story: 'other'), now: now);
    expect((await repo.allCardStates()).length, 1);
    expect(
      (await repo.localPracticeItems()).single.practiceSentence.sentenceId,
      (await db.select(db.cardContexts).get()).single.id,
    );
    expect((await repo.explicitStoryAdditions()).length, 1);
    expect(await repo.reviewsFor(c.identity.localId), isEmpty);
    expect((await db.select(db.cardContexts).get()).length, 1);
    expect((await db.select(db.storyWordSources).get()).length, 2);
  });
  test(
    'write failure rolls back metadata/context/decision/binding together',
    () async {
      await db.customStatement(
        "CREATE TRIGGER injected_failure BEFORE INSERT ON story_learning_additions BEGIN SELECT RAISE(ABORT,'disk test'); END",
      );
      await expectLater(
        repo.addStoryWord(storyCandidate(), now: now),
        throwsA(anything),
      );
      expect(await repo.allCardStates(), isEmpty);
      expect(await db.select(db.cardContexts).get(), isEmpty);
      expect(await repo.identityBindings(), isEmpty);
    },
  );
  test('existing display state keeps origin, flags and sentence; explicit decision is separate', () async {
    final c = storyCandidate(card: exactCard());
    await repo.ensureCards(['curated'], now: now, origin: CardOrigin.deck);
    await repo.setCardFlags(
      'curated',
      favorite: true,
      note: 'keep',
      inPlaylist: true,
    );
    final before = await db
        .customSelect('SELECT * FROM user_cards')
        .getSingle();
    await repo.addStoryWord(c, now: now.add(const Duration(days: 1)));
    expect(
      (await db.customSelect('SELECT * FROM user_cards').getSingle()).data,
      before.data,
    );
    expect((await repo.explicitStoryAdditions()).keys, contains('curated'));
    expect(await repo.localPracticeItems(), isEmpty);
    await repo.setCardFlags('curated', disabled: true);
    expect(
      (await repo.addStoryWord(c, now: now)).state,
      StoryAddState.disabled,
    );
    expect((await repo.cardStates(['curated']))['curated']!.disabled, isTrue);
  });
  test(
    'retired targets and unapproved contexts never create a local workaround',
    () async {
      expect(
        (await repo.storyLearningStatus(storyCandidate(retired: true))).state,
        StoryAddState.retired,
      );
      expect(
        (await repo.addStoryWord(
          storyCandidate(approved: false),
          now: now,
        )).state,
        StoryAddState.unavailable,
      );
      expect(await repo.allCardStates(), isEmpty);
    },
  );
  test('local card without content uses existing answer/ReviewPass logic; typo then correct enters box 3', () async {
    final c = storyCandidate();
    await repo.addStoryWord(c, now: now);
    final resolver = await PracticeItemResolver.load(repo, null);
    final item = (await resolver.practiceItems([c.identity.localId])).single;
    final pass = ReviewPass(
      id: 'pass',
      item: item,
      sentence: item.practiceSentence,
      state: resolver.states[item.card.id],
      mode: ReviewMode.mixed,
      startedAt: now,
    );
    pass.submit('backpak', now);
    expect(pass.errorCount, 0);
    expect(pass.solved, isFalse);
    pass.submit('backpack', now);
    final review = pass.complete(
      now: now,
      appVersion: 'test',
      deviceId: 'device',
    )!;
    expect(review.boxAfter, 3);
    expect(review.firstAttemptCorrect, isFalse);
    await repo.recordReview(review);
    await repo.recordReview(review);
    expect((await repo.reviewsFor(item.card.id)).length, 1);
    expect(review.sentenceId, item.practiceSentence.sentenceId);
    await expectLater(
      db.customStatement('UPDATE card_contexts SET text_value=\'wrong\''),
      throwsA(anything),
    );
    await expectLater(
      db.customStatement('DELETE FROM review_log'),
      throwsA(anything),
    );
  });
  test('different senses stay distinct; later exact content counterpart reuses local binding and exposes conflicts', () async {
    final c = storyCandidate();
    final r = await repo.addStoryWord(c, now: now);
    await repo.addStoryWord(storyCandidate(sense: 'different'), now: now);
    final later = storyCandidate(card: exactCard());
    expect((await repo.addStoryWord(later, now: now)).cardId, r.cardId);
    expect((await repo.allCardStates()).length, 2);
    await repo.ensureCards(['curated'], now: now, origin: CardOrigin.deck);
    expect(
      (await repo.storyLearningStatus(later)).state,
      StoryAddState.conflict,
    );
  });
  test(
    'file restart keeps exact local context and metadata without content',
    () async {
      await repo.close();
      final dir = Directory.systemTemp.createTempSync('story-restart');
      try {
        final file = File('${dir.path}/user.db');
        var user = DriftUserRepository(UserDatabase.file(file), lang: 'en');
        final c = storyCandidate();
        await user.addStoryWord(c, now: now);
        final before = (await user.localPracticeItems()).single;
        await user.close();
        user = DriftUserRepository(UserDatabase.file(file), lang: 'en');
        final after = (await user.localPracticeItems()).single;
        expect(after.card.id, before.card.id);
        expect(
          after.practiceSentence.sentenceId,
          before.practiceSentence.sentenceId,
        );
        expect(after.practiceSentence.text, before.practiceSentence.text);
        expect((await user.storyLearningStatus(c)).state, StoryAddState.added);
        await user.close();
      } finally {
        dir.deleteSync(recursive: true);
        db = UserDatabase(NativeDatabase.memory());
        repo = DriftUserRepository(db, lang: 'en');
      }
    },
  );
}
