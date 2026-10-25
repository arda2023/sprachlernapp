import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/data/learning/practice_item_resolver.dart';
import 'package:sprachapp/data/user/drift_user_repository.dart';
import 'package:sprachapp/data/user/user_database.dart';
import 'package:sprachapp/domain/personal_learning.dart';

import 'personal_learning_test.dart' show target, reply;

void main() {
  test('identical spelling: reject leaking sentence, save safe cue once in story collection', () async {
    final t = target(text: 'The robot waits beside the door.', form: 'robot');
    final p = {
      ...reply(t),
      'gloss_de': 'automatische Maschine',
      'translation_de': 'Die automatische Maschine wartet neben der Tür.',
    };
    expect(
      () => PersonalLearningCandidate.parse(t, {
        ...p,
        'translation_de': 'Der Robot wartet neben der Tür.',
      }),
      throwsFormatException,
    );
    final db = UserDatabase(NativeDatabase.memory());
    final user = DriftUserRepository(
      db,
      lang: 'en',
      contentIds: (_) async => {},
    );
    addTearDown(user.close);
    final candidate = PersonalLearningCandidate.parse(t, p);
    final ids = await Future.wait(
      List.generate(
        3,
        (_) async => (await user.savePersonalLearning(
          candidate,
          now: DateTime(2026),
          source: t,
          verify: () {},
        )).cardId,
      ),
    );
    expect(ids.toSet(), {t.identity.localId});
    expect(await db.select(db.userCards).get(), hasLength(1));
    expect(await db.select(db.reviewLog).get(), isEmpty);
    final resolver = await PracticeItemResolver.load(user, null);
    expect(resolver.storyCollectionIds, [t.identity.localId]);
    final item = (await resolver.practiceItems([t.identity.localId])).single;
    expect(item.practiceSentence.text, t.text);
    expect(item.practiceSentence.translationDe, p['translation_de']);
  });
}
