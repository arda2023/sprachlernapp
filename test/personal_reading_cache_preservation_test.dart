import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sql;
import 'package:sprachapp/data/translation_cache.dart';
import 'package:sprachapp/data/runtime_translation_client.dart';
import 'package:sprachapp/data/learning/personal_translation_hints.dart';
import 'package:sprachapp/data/learning/practice_item_resolver.dart';
import 'package:sprachapp/data/user/user_database.dart';
import 'package:sprachapp/data/user/drift_user_repository.dart';
import 'package:sprachapp/domain/personal_learning.dart';

import 'personal_learning_test.dart' show target, reply;

void main() {
  test('reading Hamster stays in cache; separate practice cue survives user database restart', () async {
    final dir = Directory.systemTemp.createTempSync(
      'reading-practice-contract',
    );
    addTearDown(() => dir.deleteSync(recursive: true));
    final cacheStore = TranslationCache(
      () async => sql.sqlite3.open('${dir.path}/cache.db'),
    );
    final reader = CachedRuntimeTranslationClient(
      remote: RuntimeTranslationClient(
        'https://no-network.invalid',
        'public',
        () async => throw StateError('No network'),
      ),
      store: cacheStore,
      owner: () async => 'owner',
      revision: () => 0,
    );
    addTearDown(reader.close);
    final t = target(text: 'The hamster sleeps in its cage.', form: 'hamster');
    final request = TranslationRequest(lang: t.lang, text: t.text);
    final reading = <String, dynamic>{
      'provider': 'anthropic',
      'model': translationModel,
      'contract': translationContract,
      'prompt': translationPrompt,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'request_id': 'synthetic',
      'cached': true,
      'usage': {'input_tokens': 1, 'output_tokens': 1},
      'translation_de': 'Der Hamster schläft in seinem Käfig.',
    };
    await cacheStore.write('owner', request.key, reading);
    final before = await cacheStore.read('owner', request.key);
    final hints = await personalTranslationHints(reader, t);
    expect(hints['sentence']['value'], reading['translation_de']);
    final p = {
      ...reply(t),
      'lemma': 'hamster',
      'gloss_de': 'kleines Nagetier',
      'translation_de': 'Das kleine Nagetier schläft in seinem Käfig.',
      'cache_note':
          'Leseübersetzung verrät die Lösung; separater Übungshinweis.',
    };
    final candidate = PersonalLearningCandidate.parse(t, p, hints: hints);
    final file = File('${dir.path}/user.db');
    var user = DriftUserRepository(
      UserDatabase(NativeDatabase(file)),
      lang: 'en',
      contentIds: (_) async => {},
    );
    for (var n = 0; n < 3; n++) {
      await user.savePersonalLearning(
        candidate,
        now: DateTime(2026),
        source: t,
        verify: () {},
      );
    }
    await user.close();
    user = DriftUserRepository(
      UserDatabase(NativeDatabase(file)),
      lang: 'en',
      contentIds: (_) async => {},
    );
    addTearDown(user.close);
    final resolver = await PracticeItemResolver.load(user, null);
    expect(resolver.storyCollectionIds, [t.identity.localId]);
    final items = await resolver.practiceItems(resolver.storyCollectionIds);
    expect(items, hasLength(1));
    expect(items.single.practiceSentence.text, t.text);
    expect(items.single.practiceSentence.translationDe, p['translation_de']);
    expect(await user.reviewsFor(t.identity.localId), isEmpty);
    expect(await cacheStore.read('owner', request.key), before);
    expect(
      (await personalTranslationHints(reader, t))['sentence']['value'],
      reading['translation_de'],
    );
  });
}
