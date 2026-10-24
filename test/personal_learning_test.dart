import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:sprachapp/domain/personal_learning.dart';
import 'package:sprachapp/domain/story_learning.dart';
import 'package:sprachapp/data/user/user_database.dart';
import 'package:sprachapp/data/user/drift_user_repository.dart';
import 'package:sprachapp/data/learning/practice_item_resolver.dart';

import 'fixtures/story_learning.dart';

PersonalTarget target({
  String text = 'She puts a zorb on the table.',
  String form = 'zorb',
  String lang = 'en',
  int? start,
}) => PersonalTarget(
  lang: lang,
  text: text,
  form: form,
  start: start ?? text.indexOf(form),
  source: 'import:test',
);
Map<String, dynamic> reply(PersonalTarget t) => {
  'reuse_id': null,
  'lemma': t.form,
  'pos': 'NOUN',
  'definition_de': 'Ein Gegenstand.',
  'gloss_de': 'Kugel',
  'form_detail': 'Substantiv, Singular',
  'function': null,
  'sentence': t.text,
  'translation_de': 'Sie stellt eine Kugel auf den Tisch.',
  'start': t.start,
  'reason': 'original',
  'reason_detail': 'Original geeignet.',
};
void main() {
  test(
    'original, pronoun, repeated Unicode word and pt-BR retain exact spans',
    () {
      for (final t in [
        target(),
        target(text: 'She holds it near her zorb.'),
        target(text: '😀 zorb and zorb are here.', start: 12),
        target(text: 'O coração é importante.', form: 'coração', lang: 'pt-BR'),
      ]) {
        final c = PersonalLearningCandidate.parse(t, reply(t));
        expect(c.validationProblem(), isNull);
        expect(c.practiceSentence.text, t.text);
        expect(c.practiceToken.start, t.start);
        expect(c.token.contextApproved, isFalse);
        expect(c.provenance, contains('private_haiku_v1'));
      }
    },
  );
  test(
    'private inflection function is retained independently of pack senses',
    () {
      final t = target(text: 'She went to the bank.', form: 'went');
      final c = PersonalLearningCandidate.parse(t, {
        ...reply(t),
        'lemma': 'go',
        'pos': 'VERB',
        'function': 'past',
        'form_detail': 'Präteritum von gehen',
      });
      expect(c.token.function, 'past');
      expect(c.token.lexicalId, startsWith('private:'));
      expect(c.validationProblem(), isNull);
    },
  );
  test('one/two words require replacement, missing annotation does not', () {
    for (final text in ['Zorb.', 'A zorb.']) {
      final t = target(
        text: text,
        form: text.startsWith('Z') ? 'Zorb' : 'zorb',
      );
      expect(
        () => PersonalLearningCandidate.parse(t, reply(t)),
        throwsFormatException,
      );
      final p = {
        ...reply(t),
        'sentence': 'I see a ${t.form} here.',
        'start': 8,
        'reason': 'too_short',
        'reason_detail': 'Nur ein oder zwei Wörter.',
      };
      expect(
        PersonalLearningCandidate.parse(t, p).practiceSentence.text,
        p['sentence'],
      );
    }
    final t = target();
    expect(
      PersonalLearningCandidate.parse(t, reply(t)).practiceSentence.text,
      t.text,
    );
  });
  test('different senses/context, language, accent and repeated occurrence stay separate', () {
    expect(
      target().identity.key,
      isNot(target(text: 'The zorb floats on water.').identity.key),
    );
    expect(
      target(text: 'zorb zorb', start: 0).key,
      isNot(target(text: 'zorb zorb', start: 5).key),
    );
    expect(target(lang: 'pt-BR').key, isNot(target().key));
    expect(
      target(text: 'O coração é importante.', form: 'coração').key,
      isNot(target(text: 'O coracao é importante.', form: 'coracao').key),
    );
  });
  test('invalid output, solution leak, forged extra fields and altered original rejected', () {
    final t = target();
    for (final change in [
      <String, dynamic>{'start': 0},
      {'gloss_de': 'zorb'},
      {'sense_id': 'invented'},
      {'sentence': 'She sees a zorb here.'},
      {'pos': 'PROPN'},
      {'reason': 'pronoun'},
      {'translation_de': 'Die zorb liegt hier.'},
    ]) {
      expect(
        () => PersonalLearningCandidate.parse(t, {...reply(t), ...change}),
        throwsFormatException,
      );
    }
  });
  test('real guard, old state, parallel atomic save, immutable offline restart and source independence', () async {
    final dir = Directory.systemTemp.createTempSync('personal-test');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/user.db');
    var db = UserDatabase(NativeDatabase(file));
    var repo = DriftUserRepository(
      db,
      lang: 'en',
      contentIds: (_) async => {'curated'},
    );
    final old = storyCandidate(surface: 'early');
    await repo.addStoryWord(old, now: DateTime(2026));
    final before =
        (await db.customSelect('SELECT * FROM user_cards').getSingle()).data;
    final t = target(),
        c = PersonalLearningCandidate.parse(target(), reply(target()));
    Future<StoryAddResult> save() => repo.savePersonalLearning(
      c,
      now: DateTime(2026),
      source: t,
      verify: () {},
    );
    final results = await Future.wait([save(), save(), save()]);
    expect(results.map((r) => r.cardId).toSet(), {t.identity.localId});
    expect((await repo.allCardStates()).length, 2);
    final rows = await db.select(db.userCards).get();
    expect(rows.length, 2);
    expect(
      (await db.customSelect('SELECT * FROM user_cards').get()).first.data,
      before,
    );
    expect(await repo.reviewsFor(t.identity.localId), isEmpty);
    expect(
      (await repo.localPracticeItems()).last.practiceSentence.text,
      t.text,
    );
    await repo.close();
    db = UserDatabase(NativeDatabase(file));
    repo = DriftUserRepository(
      db,
      lang: 'en',
      contentIds: (_) async => {'curated'},
    );
    final resolver = await PracticeItemResolver.load(repo, null);
    expect(resolver.storyCollectionIds, contains(t.identity.localId));
    expect(
      (await resolver.practiceItems([t.identity.localId]))
          .single
          .practiceSentence
          .text,
      t.text,
    );
    expect(
      await resolver.historicalSentence(
        t.identity.localId,
        (await resolver.practiceItems([t.identity.localId]))
            .single
            .practiceSentence
            .sentenceId,
      ),
      isNotNull,
    );
    await repo.setCardFlags(t.identity.localId, disabled: true);
    final alias = target(text: 'The zorb floats on water.');
    expect(
      (await repo.savePersonalLearning(
        PersonalLearningCandidate.parse(alias, reply(alias)),
        now: DateTime.now(),
        source: alias,
        verify: () {},
      )).state,
      StoryAddState.unavailable,
    );
    expect((await repo.allCardStates()).length, 2);
    await repo.close();
  });
  test(
    'failed transaction and late account switch leave no partial card',
    () async {
      final db = UserDatabase(NativeDatabase.memory()), t = target();
      final repo = DriftUserRepository(
        db,
        lang: 'en',
        contentIds: (_) async => {},
      );
      addTearDown(repo.close);
      final c = PersonalLearningCandidate.parse(t, reply(t));
      var calls = 0;
      await expectLater(
        repo.savePersonalLearning(
          c,
          now: DateTime.now(),
          source: t,
          verify: () {
            if (++calls == 2) throw StateError('account changed');
          },
        ),
        throwsStateError,
      );
      expect(await repo.allCardStates(), isEmpty);
      expect(await repo.identityBindings(), isEmpty);
      expect(await db.select(db.cardContexts).get(), isEmpty);
      await db.customStatement(
        "CREATE TRIGGER fail_add BEFORE INSERT ON story_learning_additions BEGIN SELECT RAISE(ABORT,'synthetic'); END",
      );
      await expectLater(
        repo.savePersonalLearning(
          c,
          now: DateTime.now(),
          source: t,
          verify: () {},
        ),
        throwsA(anything),
      );
      expect(await repo.allCardStates(), isEmpty);
      expect(await db.select(db.cardContexts).get(), isEmpty);
    },
  );
}
