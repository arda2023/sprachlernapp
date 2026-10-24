import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sprachapp/data/runtime_translation_client.dart';
import 'package:sprachapp/data/translation_cache.dart';

import 'translation_cache_test.dart' show Remote, response;

void main() {
  test(
    'consent survives reopening the on-disk database, and revoke is persistent',
    () async {
      final dir = Directory.systemTemp.createTempSync('word-consent');
      addTearDown(() => dir.deleteSync(recursive: true));
      TranslationCache open() => TranslationCache(
        () async => sqlite3.open('${dir.path}/private.sqlite'),
      );
      var store = open();
      await store.writeWordConsent('project:a', true);
      await store.close();
      store = open();
      expect(
        await store.readWordConsent('project:a'),
        WordCloudConsent.enabled,
      );
      expect(
        await store.readWordConsent('project:b'),
        WordCloudConsent.unknown,
      );
      await store.writeWordConsent('project:a', false);
      await store.close();
      store = open();
      expect(
        await store.readWordConsent('project:a'),
        WordCloudConsent.disabled,
      );
      await store.close();
    },
  );
  test('failed consent write fails closed for later automatic taps', () async {
    final db = sqlite3.openInMemory();
    final remote = Remote();
    final store = TranslationCache(() async => db);
    final client = CachedRuntimeTranslationClient(
      remote: remote,
      store: store,
      owner: () async => 'a',
      revision: () => 0,
    );
    addTearDown(client.close);
    await client.setWordCloudConsent(true);
    db.execute('PRAGMA query_only=ON');
    await expectLater(
      client.setWordCloudConsent(false),
      throwsA(isA<TranslationFailure>()),
    );
    await expectLater(
      client.translateWordOnTap(lang: 'en', text: 'The cat.', form: 'cat'),
      throwsA(isA<TranslationFailure>()),
    );
    expect(remote.calls, 0);
  });

  test('consent is versioned, persistent, owner-scoped and unrelated to earlier requests', () async {
    final db = sqlite3.openInMemory();
    addTearDown(db.close);
    final store = TranslationCache(() async => db);
    final remote = Remote();
    String? owner = 'project:a';
    final client = CachedRuntimeTranslationClient(
      remote: remote,
      store: store,
      owner: () async => owner,
      revision: () => 0,
    );
    expect(await client.wordCloudConsent(), WordCloudConsent.unknown);
    await client.translate(lang: 'en', text: 'The cat.', form: 'cat');
    expect(await client.wordCloudConsent(), WordCloudConsent.unknown);
    await expectLater(
      client.translateWordOnTap(lang: 'en', text: 'The bank.', form: 'bank'),
      throwsA(isA<TranslationFailure>()),
    );
    expect(remote.calls, 1);
    await client.setWordCloudConsent(true);
    expect(
      await TranslationCache(() async => db).readWordConsent('project:a'),
      WordCloudConsent.enabled,
    );
    owner = 'project:b';
    expect(await client.wordCloudConsent(), WordCloudConsent.unknown);
    owner = null;
    expect(await client.wordCloudConsent(), WordCloudConsent.unknown);
    owner = 'project:a';
    await client.setWordCloudConsent(false);
    expect(await client.wordCloudConsent(), WordCloudConsent.disabled);
    db.execute("UPDATE word_cloud_consent SET version=99");
    expect(await client.wordCloudConsent(), WordCloudConsent.unknown);
  });
  test('eight same-word taps share one remote call; new context/offset has own identity', () async {
    final remote = Remote()..wait = Completer<void>();
    final store = TranslationCache(() async => sqlite3.openInMemory());
    final client = CachedRuntimeTranslationClient(
      remote: remote,
      store: store,
      owner: () async => 'a',
      revision: () => 0,
    );
    addTearDown(client.close);
    await client.setWordCloudConsent(true);
    final requests = List.generate(
      8,
      (_) => client.translateWordOnTap(
        lang: 'en',
        text: 'bank bank',
        form: 'bank',
        start: 5,
      ),
    );
    await remote.entered.future;
    expect(remote.calls, 1);
    remote.wait!.complete();
    await Future.wait(requests);
    expect(remote.calls, 1);
    await client.translateWordOnTap(
      lang: 'en',
      text: 'bank bank',
      form: 'bank',
      start: 5,
    );
    expect(remote.calls, 1);
    await client.translateWordOnTap(
      lang: 'en',
      text: 'bank bank',
      form: 'bank',
      start: 0,
    );
    expect(remote.calls, 2);
    await client.translateWordOnTap(
      lang: 'pt-BR',
      text: 'O coração.',
      form: 'coração',
      start: 2,
    );
    expect(remote.calls, 3);
  });
  test(
    'revocation while waiting for auth prevents HTTP client construction',
    () async {
      final token = Completer<String>(), entered = Completer<void>();
      var http = 0;
      final remote = RuntimeTranslationClient(
        'https://fixture.invalid',
        'public',
        () {
          entered.complete();
          return token.future;
        },
        createClient: () {
          http++;
          throw StateError('must not construct HTTP');
        },
      );
      final client = CachedRuntimeTranslationClient(
        remote: remote,
        store: TranslationCache(() async => sqlite3.openInMemory()),
        owner: () async => 'a',
        revision: () => 0,
      );
      addTearDown(client.close);
      await client.setWordCloudConsent(true);
      final result = client.translateWordOnTap(
        lang: 'en',
        text: 'The bank.',
        form: 'bank',
      );
      final check = expectLater(result, throwsA(isA<TranslationFailure>()));
      await entered.future;
      await client.setWordCloudConsent(false);
      token.complete('synthetic');
      await check;
      expect(http, 0);
    },
  );
  test('revocation rejects late result and does not store it', () async {
    final remote = Remote()..wait = Completer<void>();
    final store = TranslationCache(() async => sqlite3.openInMemory());
    final client = CachedRuntimeTranslationClient(
      remote: remote,
      store: store,
      owner: () async => 'a',
      revision: () => 0,
    );
    addTearDown(client.close);
    await client.setWordCloudConsent(true);
    final check = expectLater(
      client.translateWordOnTap(lang: 'en', text: 'The bank.', form: 'bank'),
      throwsA(isA<TranslationFailure>()),
    );
    await remote.entered.future;
    await client.setWordCloudConsent(false);
    remote.wait!.complete();
    await check;
    expect(
      await client.cached(lang: 'en', text: 'The bank.', form: 'bank'),
      isNull,
    );
  });
  test('corrupt cache and consent database never reach provider', () async {
    final remote = Remote();
    final db = sqlite3.openInMemory();
    final store = TranslationCache(() async => db);
    final client = CachedRuntimeTranslationClient(
      remote: remote,
      store: store,
      owner: () async => 'a',
      revision: () => 0,
    );
    addTearDown(client.close);
    await client.setWordCloudConsent(true);
    final request = TranslationRequest(
      lang: 'en',
      text: 'The bank.',
      form: 'bank',
    );
    await store.write('a', request.key, response(request));
    db.execute("UPDATE translations SET response='broken'");
    await expectLater(
      client.translateWordOnTap(lang: 'en', text: 'The bank.', form: 'bank'),
      throwsA(isA<TranslationFailure>()),
    );
    expect(remote.calls, 0);
    db.execute('DROP TABLE word_cloud_consent');
    await expectLater(
      client.translateWordOnTap(lang: 'en', text: 'The cat.', form: 'cat'),
      throwsA(isA<TranslationFailure>()),
    );
    expect(remote.calls, 0);
  });
}
