import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:sprachapp/data/user/user_database.dart';
import 'package:sprachapp/data/user/drift_user_repository.dart';
import 'package:sprachapp/domain/personal_learning.dart';
import 'package:sprachapp/domain/story_learning.dart';

import 'personal_learning_test.dart' show target, reply;

void main() {
  test('same surface: deferred sense protected; independent meaning saved; race fails closed', () async {
    final repo = DriftUserRepository(
      UserDatabase(NativeDatabase.memory()),
      lang: 'en',
    );
    addTearDown(repo.close);
    final old = target(text: 'I went to the bank.', form: 'bank');
    final a = {
      ...reply(old),
      'lemma': 'bank',
      'definition_de': 'Geldinstitut',
      'gloss_de': 'Bank',
      'translation_de': 'Ich ging zum Geldinstitut.',
    };
    // The German cue must not literally reveal the English answer.
    a['gloss_de'] = 'Geldinstitut';
    final saved = await repo.savePersonalLearning(
      PersonalLearningCandidate.parse(old, a),
      now: DateTime.now(),
      source: old,
      verify: () {},
    );
    await repo.setCardFlags(saved.cardId!, disabled: true);
    final next = target(text: 'She sat by the bank.', form: 'bank');
    final p = {
      ...reply(next),
      'lemma': 'bank',
      'definition_de': 'Ufer eines Flusses',
      'gloss_de': 'Ufer',
      'translation_de': 'Sie saß am Ufer.',
    };
    expect(
      (await repo.savePersonalLearning(
        PersonalLearningCandidate.parse(next, p),
        now: DateTime.now(),
        source: next,
        verify: () {},
      )).state,
      StoryAddState.unavailable,
    );
    expect(
      () => PersonalLearningCandidate.parse(
        next,
        p,
        independentOf: {saved.cardId!},
      ),
      throwsFormatException,
    );
    p['distinctions'] = {
      saved.cardId!: {
        'relation': 'independent',
        'reason': 'Ufer statt Geldinstitut.',
      },
    };
    final independent = PersonalLearningCandidate.parse(
      next,
      p,
      independentOf: {saved.cardId!},
    );
    final added = await repo.savePersonalLearning(
      independent,
      now: DateTime.now(),
      source: next,
      verify: () {},
    );
    expect(added.state, StoryAddState.added);
    expect(added.cardId, isNot(saved.cardId));
    expect(
      (await repo.cardStates([saved.cardId!]))[saved.cardId]!.disabled,
      isTrue,
    );
    await repo.setCardFlags(added.cardId!, disabled: true);
    final third = target(text: 'They stood near the bank.', form: 'bank');
    final stale = {...p, 'sentence': third.text, 'start': third.start};
    expect(
      (await repo.savePersonalLearning(
        PersonalLearningCandidate.parse(
          third,
          stale,
          independentOf: {saved.cardId!},
        ),
        now: DateTime.now(),
        source: third,
        verify: () {},
      )).state,
      StoryAddState.unavailable,
    );
    expect((await repo.allCardStates()).length, 2);
  });
}
