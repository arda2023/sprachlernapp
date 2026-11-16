import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/data/user/learning_milestone_store.dart';
import 'package:sprachapp/data/user/user_database.dart';
import 'package:sprachapp/domain/learning_milestone.dart';

final _now = DateTime.utc(2026, 11, 15, 9);

Future<void> _savePass(
  UserDatabase db, {
  required String id,
  String cardId = 'ticket',
  int before = 0,
  int after = 1,
  bool revealed = false,
  DateTime? at,
}) async {
  await db
      .into(db.reviewLog)
      .insert(
        ReviewLogCompanion.insert(
          id: id,
          cardId: cardId,
          createdAt: at ?? _now,
          mode: 'deck',
          sentenceId: 'fixed-sentence',
          firstAttemptCorrect: !revealed,
          errorCount: 0,
          revealed: revealed,
          boxBefore: before,
          boxAfter: after,
          dueAtAfter: _now,
          appVersion: 'test',
          deviceId: 'device',
        ),
      );
}

Future<void> _saveTopicCard(UserDatabase db) async {
  await db
      .into(db.userCards)
      .insert(
        UserCardsCompanion.insert(
          cardId: 'ticket',
          lang: 'en',
          box: 0,
          createdAt: _now,
          updatedAt: _now,
          origin: 'deck',
        ),
      );
  await db
      .into(db.generatedVocabularyAdditions)
      .insert(
        GeneratedVocabularyAdditionsCompanion.insert(
          cardId: 'ticket',
          lang: 'en',
          addedAt: _now,
        ),
      );
}

void main() {
  test(
    'milestone is claimed once across concurrent requests and a reopen',
    () async {
      final dir = await Directory.systemTemp.createTemp('milestone-test-');
      addTearDown(() => dir.delete(recursive: true));
      final firstAccount = File('${dir.path}/one.sqlite');
      final secondAccount = File('${dir.path}/two.sqlite');
      final db = UserDatabase(NativeDatabase(firstAccount));
      final store = LearningMilestoneStore(db);
      const story = LearningMilestone.firstStory;
      final won = await Future.wait([store.claim(story), store.claim(story)]);
      expect(won, unorderedEquals([true, false]));
      await db.close();
      final reopened = UserDatabase(NativeDatabase(firstAccount));
      try {
        expect(await LearningMilestoneStore(reopened).claim(story), isFalse);
      } finally {
        await reopened.close();
      }
      final other = UserDatabase(NativeDatabase(secondAccount));
      addTearDown(other.close);
      expect(await LearningMilestoneStore(other).claim(story), isTrue);
    },
  );

  test(
    'only a persisted, genuinely answered topic pass and real promotion count',
    () async {
      final db = UserDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final store = LearningMilestoneStore(db);
      await _savePass(
        db,
        id: 'older-curated',
        at: _now.subtract(const Duration(days: 1)),
      );
      await _saveTopicCard(db);
      expect((await store.practice({'missing-id'})).successful, isFalse);
      expect((await store.practice({'older-curated'})).milestones, isEmpty);
      await _savePass(db, id: 'revealed', revealed: true);
      expect((await store.practice({'revealed'})).successful, isFalse);
      await _savePass(db, id: 'answered');
      final answered = await store.practice({'answered'});
      expect(answered.successful, isTrue);
      expect(answered.milestones, [LearningMilestone.firstTopicPractice]);
      expect((await store.practice({'answered'})).milestones, isEmpty);

      await _savePass(db, id: 'building', before: 3, after: 4);
      expect((await store.practice({'building'})).milestones, isEmpty);
      await _savePass(db, id: 'mastered', before: 4, after: 5);
      expect((await store.practice({'mastered'})).milestones, [
        LearningMilestone.firstMasteredWord,
      ]);
      await _savePass(db, id: 'mastered-review', before: 5, after: 5);
      expect((await store.practice({'mastered-review'})).milestones, isEmpty);
    },
  );

  test(
    'a milestone reached in an earlier session is never awarded retroactively',
    () async {
      final db = UserDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final store = LearningMilestoneStore(db);
      await _savePass(db, id: 'old', before: 4, after: 5);
      await _savePass(db, id: 'new', before: 4, after: 5);
      expect((await store.practice({'new'})).milestones, isEmpty);
    },
  );
}
