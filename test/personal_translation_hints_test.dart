import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sprachapp/data/translation_cache.dart';
import 'package:sprachapp/data/runtime_translation_client.dart';
import 'package:sprachapp/data/learning/personal_translation_hints.dart';

import 'personal_learning_test.dart' show target;

void main() {
  test('adapter reads exact owner/span/language/contract only; storage failures stay errors', () async {
    final db = sqlite3.openInMemory(), store = TranslationCache(() async => db);
    var owner = 'a', revision = 0;
    final cache = CachedRuntimeTranslationClient(
      remote: RuntimeTranslationClient(
        'https://no-network.invalid',
        'synthetic',
        () async => throw StateError('No network'),
      ),
      store: store,
      owner: () async => owner,
      revision: () => revision,
    );
    addTearDown(cache.close);
    final t = target();
    final request = TranslationRequest(
      lang: t.lang,
      text: t.text,
      form: t.form,
      start: t.start,
    );
    final payload = <String, dynamic>{
      'provider': 'anthropic',
      'model': translationModel,
      'contract': translationContract,
      'prompt': translationPrompt,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'request_id': 'synthetic',
      'cached': true,
      'usage': {'input_tokens': 1, 'output_tokens': 1},
      'form': t.form,
      'senses': [
        {
          'lemma': 'zorb',
          'pos': 'NOUN',
          'form_label': 'Substantiv',
          'gloss_de': 'Kugel',
        },
      ],
    };
    await store.write('a', request.key, payload);
    final hints = await personalTranslationHints(cache, t);
    expect(hints['word']['request_key'], request.key);
    expect(hints['word']['value']['gloss_de'], 'Kugel');
    expect(hints.containsKey('sentence'), false);
    expect(
      await personalTranslationHints(cache, target(text: 'A zorb is here.')),
      isEmpty,
    );
    owner = 'b';
    revision++;
    expect(await personalTranslationHints(cache, t), isEmpty);
    owner = 'a';
    revision++;
    expect((await personalTranslationHints(cache, t)).keys, ['word']);
    db.execute('DROP TABLE translations');
    await expectLater(personalTranslationHints(cache, t), throwsA(anything));
  });
}
