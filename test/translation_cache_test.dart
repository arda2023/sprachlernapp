import 'fixtures/offline_translation.dart';
import 'package:sprachapp/presentation/providers/offline_translation_provider.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sprachapp/data/runtime_translation_client.dart';
import 'package:sprachapp/data/translation_cache.dart';
import 'package:sprachapp/presentation/providers/runtime_translation_provider.dart';
import 'package:sprachapp/widgets/runtime_translation_sheet.dart';

Map<String, dynamic> response(TranslationRequest request) => {
  'provider': 'anthropic',
  'model': translationModel,
  'contract': 2,
  'prompt': translationPrompt,
  'request_id': 'synthetic-result',
  'created_at': DateTime.now().toUtc().toIso8601String(),
  'cached': false,
  'usage': {'input_tokens': 20, 'output_tokens': 8},
  if (request.form == null) 'translation_de': 'Ein synthetischer Satz.',
  if (request.form != null) ...{
    'form': request.form,
    'senses': [
      {
        'lemma': request.form,
        'pos': 'noun',
        'form_label': 'Singular',
        'gloss_de': 'Synthetische Bedeutung',
      },
    ],
  },
};

class Remote extends RuntimeTranslationClient {
  Remote()
    : super('https://fixture.invalid', 'public', () async => 'synthetic');
  int calls = 0, deletions = 0;
  bool offline = false, invalid = false, timeout = false;
  Completer<void>? wait;
  final entered = Completer<void>();
  @override
  Future<RuntimeTranslation> translate({
    required String lang,
    required String text,
    String? form,
    int? start,
    String? senseRef,
    String? formRef,
  }) async {
    calls++;
    if (!entered.isCompleted) entered.complete();
    if (offline) throw const TranslationFailure('Offline');
    if (timeout) throw TimeoutException('synthetic');
    await wait?.future;
    final req = TranslationRequest(
      lang: lang,
      text: text,
      form: form,
      start: start,
      senseRef: senseRef,
      formRef: formRef,
    );
    final value = response(req);
    if (invalid) value['senses'] = [];
    return RuntimeTranslation(
      'Synthetische Bedeutung',
      translationModel,
      'synthetic-result',
      payload: value,
    );
  }

  @override
  Future<void> clearSaved() async {
    deletions++;
    if (offline) throw const TranslationFailure('Offline');
  }
}

class BrokenWrite extends TranslationCache {
  BrokenWrite() : super(() async => sqlite3.openInMemory());
  @override
  Future<void> write(
    String owner,
    String key,
    Map<String, dynamic> response,
  ) async => throw StateError('synthetic');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;
  late Remote remote;
  String? owner;
  int revision = 0;
  late StreamController<void> changes;
  late CachedRuntimeTranslationClient client;
  CachedRuntimeTranslationClient make({TranslationCache? store}) =>
      CachedRuntimeTranslationClient(
        remote: remote,
        store:
            store ??
            TranslationCache(
              () async => sqlite3.open('${dir.path}/private.sqlite'),
            ),
        owner: () async => owner,
        revision: () => revision,
        identityChanges: changes.stream,
      );
  Future<RuntimeTranslation> fetch() =>
      client.translate(lang: 'en', text: 'The bank.', form: 'bank', start: 4);
  Future<RuntimeTranslation?> hit() =>
      client.cached(lang: 'en', text: 'The bank.', form: 'bank', start: 4);
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('synthetic-translations-');
    remote = Remote();
    owner = 'project:owner-a';
    revision = 0;
    changes = StreamController<void>.broadcast(sync: true);
    client = make();
  });
  tearDown(() async {
    await client.close();
    await changes.close();
    await dir.delete(recursive: true);
  });
  test(
    'first success, repeated and restarted offline hit use one model call',
    () async {
      await fetch();
      await fetch();
      expect(remote.calls, 1);
      await client.close();
      client = make();
      remote.offline = true;
      expect((await hit())!.text, 'Synthetische Bedeutung');
      await fetch();
      expect(remote.calls, 1);
    },
  );
  test('eight simultaneous requests share one operation', () async {
    remote.wait = Completer();
    final all = Future.wait(List.generate(8, (_) => fetch()));
    await remote.entered.future;
    expect(remote.calls, 1);
    remote.wait!.complete();
    expect((await all).length, 8);
    expect(remote.calls, 1);
  });
  test('exact identity separates context, senses, forms, occurrences, accents, languages and operations', () {
    final requests = [
      TranslationRequest(lang: 'en', text: 'bank bank', form: 'bank', start: 0),
      TranslationRequest(lang: 'en', text: 'bank bank', form: 'bank', start: 5),
      TranslationRequest(
        lang: 'en',
        text: 'bank bank',
        form: 'bank',
        start: 0,
        senseRef: 'river',
      ),
      TranslationRequest(
        lang: 'en',
        text: 'bank bank',
        form: 'bank',
        start: 0,
        senseRef: 'finance',
      ),
      TranslationRequest(
        lang: 'en',
        text: 'bank bank',
        form: 'bank',
        start: 0,
        formRef: 'noun',
      ),
      TranslationRequest(
        lang: 'en',
        text: 'bank bank!',
        form: 'bank',
        start: 0,
      ),
      TranslationRequest(
        lang: 'pt-BR',
        text: 'bank bank',
        form: 'bank',
        start: 0,
      ),
      TranslationRequest(lang: 'pt-BR', text: 'avó', form: 'avó'),
      TranslationRequest(lang: 'pt-BR', text: 'avo', form: 'avo'),
      TranslationRequest(lang: 'pt-BR', text: 'avo\u0301', form: 'avo\u0301'),
      TranslationRequest(lang: 'en', text: 'bank bank'),
    ];
    expect(requests.map((r) => r.key).toSet().length, requests.length);
    expect(
      () => TranslationRequest(lang: 'en', text: 'bank bank', form: 'bank'),
      throwsFormatException,
    );
    expect(
      () => TranslationRequest(lang: 'en', text: 'Bank', form: 'bank'),
      throwsFormatException,
    );
    expect(
      () =>
          TranslationRequest(lang: 'pt-BR', text: 'avó', form: 'avó', start: 1),
      throwsFormatException,
    );
  });
  test(
    'different context/sense or position cannot read saved result',
    () async {
      await fetch();
      for (final request in [
        TranslationRequest(
          lang: 'en',
          text: 'The bank!',
          form: 'bank',
          start: 4,
        ),
        TranslationRequest(
          lang: 'en',
          text: 'The bank.',
          form: 'bank',
          start: 4,
          senseRef: 'river',
        ),
        TranslationRequest(
          lang: 'en',
          text: 'The bank bank.',
          form: 'bank',
          start: 9,
        ),
      ]) {
        expect(
          await client.cached(
            lang: request.lang,
            text: request.text,
            form: request.form,
            start: request.wordStart,
            senseRef: request.senseRef,
          ),
          isNull,
        );
      }
      expect(remote.calls, 1);
    },
  );
  test('account switch/logout isolates persistent records', () async {
    await fetch();
    owner = 'project:owner-b';
    revision++;
    changes.add(null);
    expect(await hit(), isNull);
    await fetch();
    expect(remote.calls, 2);
    owner = null;
    revision++;
    changes.add(null);
    expect(await hit(), isNull);
    await expectLater(fetch(), throwsA(isA<TranslationFailure>()));
    owner = 'project:owner-a';
    revision++;
    changes.add(null);
    expect(await hit(), isNotNull);
    expect(remote.calls, 2);
  });
  test(
    'logout discards in-flight result even when same account returns',
    () async {
      remote.wait = Completer();
      final pending = fetch();
      final rejected = expectLater(pending, throwsA(isA<TranslationFailure>()));
      await remote.entered.future;
      owner = null;
      revision++;
      changes.add(null);
      owner = 'project:owner-a';
      revision++;
      changes.add(null);
      remote.wait!.complete();
      await rejected;
      expect(await hit(), isNull);
    },
  );
  test('delete account A preserves B, and restart keeps deletion', () async {
    await fetch();
    owner = 'project:owner-b';
    await fetch();
    owner = 'project:owner-a';
    await client.clearSaved();
    expect(await hit(), isNull);
    expect(remote.deletions, 1);
    await client.close();
    client = make();
    expect(await hit(), isNull);
    owner = 'project:owner-b';
    expect(await hit(), isNotNull);
  });
  test(
    'offline deletion persists across restart; flush precedes new translation',
    () async {
      await fetch();
      remote.offline = true;
      await expectLater(
        client.clearSaved(),
        throwsA(isA<TranslationFailure>()),
      );
      expect(await hit(), isNull);
      await client.close();
      client = make();
      await expectLater(fetch(), throwsA(isA<TranslationFailure>()));
      expect(remote.calls, 1);
      remote.offline = false;
      await fetch();
      expect(remote.calls, 2);
      expect(await hit(), isNotNull);
      expect(await client.store.deletionPending(owner!), isFalse);
    },
  );
  test('delete during paid request prevents late local resurrection', () async {
    remote.wait = Completer();
    final pending = fetch();
    final rejected = expectLater(pending, throwsA(isA<TranslationFailure>()));
    await remote.entered.future;
    await client.clearSaved();
    remote.wait!.complete();
    await rejected;
    expect(await hit(), isNull);
  });
  test(
    'invalid response and timeout are not cached, no internal retry',
    () async {
      remote.invalid = true;
      await expectLater(fetch(), throwsFormatException);
      expect(await hit(), isNull);
      expect(remote.calls, 1);
      remote.invalid = false;
      remote.timeout = true;
      await expectLater(fetch(), throwsA(isA<TimeoutException>()));
      expect(await hit(), isNull);
      expect(remote.calls, 2);
    },
  );
  test(
    'write failure preserves valid displayed answer with honest notice',
    () async {
      await client.close();
      client = make(store: BrokenWrite());
      final value = await fetch();
      expect(value.storageWarning, isNotNull);
      expect(await hit(), isNull);
      expect(remote.calls, 1);
    },
  );
  test('read failure is not treated as cache miss and never spends', () async {
    await client.close();
    client = make(
      store: TranslationCache(() async => throw StateError('synthetic')),
    );
    await expectLater(fetch(), throwsA(isA<TranslationFailure>()));
    expect(remote.calls, 0);
    // Failed opener also fails close; avoid replacing the original failure.
    await client.close().catchError((_) {});
    client = make();
  });
  test(
    'parallel requests flush one pending deletion before new work',
    () async {
      await fetch();
      remote.offline = true;
      await expectLater(
        client.clearSaved(),
        throwsA(isA<TranslationFailure>()),
      );
      remote.offline = false;
      final deletionsBefore = remote.deletions;
      await Future.wait([
        fetch(),
        client.translate(
          lang: 'en',
          text: 'Another bank.',
          form: 'bank',
          start: 8,
        ),
      ]);
      expect(remote.deletions - deletionsBefore, 1);
      expect(await hit(), isNotNull);
      expect(
        await client.cached(
          lang: 'en',
          text: 'Another bank.',
          form: 'bank',
          start: 8,
        ),
        isNotNull,
      );
    },
  );
  test('token acquisition cannot send text under a changed account', () async {
    var sessionRevision = 0;
    final transport = RuntimeTranslationClient(
      'https://fixture.invalid',
      'public',
      () async {
        sessionRevision++;
        return 'other-account-token';
      },
      identityRevision: () => sessionRevision,
      createClient: () => throw StateError('must not create HTTP client'),
    );
    await expectLater(
      transport.translate(lang: 'en', text: 'Synthetic sentence.'),
      throwsA(
        isA<TranslationFailure>().having(
          (e) => e.message,
          'reason',
          contains('Konto geändert'),
        ),
      ),
    );
  });
  test('invalid provenance, incomplete sense and expired results rejected', () {
    final req = TranslationRequest(lang: 'en', text: 'The bank.', form: 'bank');
    for (final edit in <Map<String, dynamic>>[
      {'prompt': 'old'},
      {'contract': 1},
      {'provider': 'other'},
      {'model': 'other'},
      {
        'created_at': DateTime.now()
            .subtract(const Duration(days: 31))
            .toIso8601String(),
      },
      {
        'senses': [
          {'gloss_de': 'only'},
        ],
      },
      {
        'usage': {'input_tokens': 2, 'output_tokens': 385},
      },
    ]) {
      expect(
        () => RuntimeTranslation.parse({...response(req), ...edit}, req),
        throwsFormatException,
      );
    }
  });
  testWidgets(
    'local hit shows without consent; account change removes answer',
    (tester) async {
      await tester.runAsync(() => fetch());
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
          offlineDictionaryProvider.overrideWithValue(EmptyDictionary()),
          deviceTranslationProvider.overrideWithValue(UnsupportedDeviceTranslation()),runtimeTranslationProvider.overrideWithValue(client)],
          child: const MaterialApp(
            home: Scaffold(
              body: RuntimeTranslationSheet(
                lang: 'en',
                text: 'The bank.',
                form: 'bank',
                start: 4,
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(() async {
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pumpAndSettle();
      expect(find.text('Synthetische Bedeutung'), findsOneWidget);
      expect(find.text('Mit KI übersetzen'), findsNothing);
      owner = null;
      revision++;
      changes.add(null);
      await tester.pump();
      expect(find.text('Synthetische Bedeutung'), findsNothing);
      expect(remote.calls, 1);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
