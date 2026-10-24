import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/data/user/drift_user_repository.dart';
import 'package:sprachapp/data/user/user_database.dart';
import 'package:sprachapp/domain/story_learning.dart';

import '../fixtures/story_learning.dart';

void main() {
  test('prospective local ID is not a pack reference; persisted references stay strict', () async {
    final db = UserDatabase(NativeDatabase.memory());
    // Seed an earlier saved context before enabling the production pack guard.
    final seed = DriftUserRepository(db, lang: 'en', ownsDatabase: false);
    final saved = storyCandidate(surface: 'early', story: 'old-revision');
    await seed.addStoryWord(saved, now: DateTime(2026, 10, 20));
    final user = DriftUserRepository(
      db,
      lang: 'en',
      ownsDatabase: false,
      contentIds: (_) async => {'curated'},
    );
    addTearDown(db.close);
    final before = await db.customSelect('SELECT * FROM user_cards').get();
    final contexts = await db.customSelect('SELECT * FROM card_contexts').get();
    for (final word in ['arrives', 'points']) {
      expect(
        (await user.storyLearningStatus(storyCandidate(surface: word))).state,
        StoryAddState.available,
      );
    }
    expect(
      (await user.storyLearningStatus(storyCandidate(card: exactCard()))).state,
      StoryAddState.available,
    );
    expect((await user.storyLearningStatus(saved)).state, StoryAddState.added);
    expect(
      await db
          .customSelect('SELECT * FROM user_cards')
          .get()
          .then((r) => r.map((e) => e.data).toList()),
      before.map((e) => e.data).toList(),
    );
    expect(
      await db
          .customSelect('SELECT * FROM card_contexts')
          .get()
          .then((r) => r.map((e) => e.data).toList()),
      contexts.map((e) => e.data).toList(),
    );
    // Neither arbitrary missing IDs nor invalid pack references get exempted.
    await expectLater(user.cardStates(['u:missing']), throwsStateError);
    await expectLater(
      user.storyLearningStatus(
        storyCandidate(card: exactCard(id: 'invalid-pack')),
      ),
      throwsStateError,
    );
    final otherLanguage = DriftUserRepository(
      db,
      lang: 'pt-BR',
      ownsDatabase: false,
    );
    await expectLater(
      otherLanguage.cardStates([saved.identity.localId]),
      throwsStateError,
    );
  });
}
