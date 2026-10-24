import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sqlite3/sqlite3.dart' as sql;
import 'package:sprachapp/data/personal_learning_client.dart';
import 'package:sprachapp/data/translation_cache.dart';
import 'package:sprachapp/data/user/user_database.dart';
import 'package:sprachapp/data/user/drift_user_repository.dart';
import 'package:sprachapp/domain/personal_learning.dart';
import 'package:sprachapp/domain/story_learning.dart';
import 'package:sprachapp/domain/srs_state.dart';
import 'package:sprachapp/domain/review_pass.dart';
import 'package:sprachapp/presentation/providers/database_providers.dart';
import 'package:sprachapp/presentation/providers/personal_learning_provider.dart';
import 'package:sprachapp/widgets/personal_learning_button.dart';

import 'package:sprachapp/presentation/providers/reading_providers.dart';

import 'data/support.dart';
import 'personal_learning_test.dart' show target, reply;
import 'runtime_translation_test.dart' show LoopbackClient;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  test('production provider + real pack guard, reused card unchanged; created card survives cache removal', () async {
    HttpOverrides.global = null;
    final dir = Directory.systemTemp.createTempSync('personal-flow');
    addTearDown(() => dir.deleteSync(recursive: true));
    final content = await fixtureInstaller(
      dir,
      Directory('${dir.path}/support'),
    ).open();
    addTearDown(content.close);
    final db = UserDatabase(NativeDatabase.memory());
    final user = DriftUserRepository(
      db,
      lang: 'en',
      contentIds: (_) => content.allCardIds(),
    );
    addTearDown(user.close);
    final consent = PersonalConsentStore(
      () async => sql.sqlite3.open('${dir.path}/consent.db'),
    );
    addTearDown(consent.close);
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    var calls = 0;
    final inputs = <Map<String, dynamic>>[];
    server.listen((request) async {
      calls++;
      final b = jsonDecode(
        await utf8.decoder.bind(request).join(),
      ) as Map<String, dynamic>;
      inputs.add(b);
      expect(request.uri.path, '/functions/v1/create-learning-card');
      expect(request.headers.value('authorization'), 'Bearer synthetic');
      final t = PersonalTarget(
        lang: b['lang'],
        text: b['text'],
        form: b['form'],
        start: b['start'],
        source: 'test',
      );
      final locals = b['local_candidates'] as List;
      final p = locals.isNotEmpty
          ? {
              ...reply(t),
              'reuse_id': locals.single['id'],
              'lemma': locals.single['lemma'],
              'pos': locals.single['pos'],
              'function': locals.single['function'],
            }
          : t.form == 'went'
          ? {...reply(t), 'reuse_id': 'card-went', 'lemma': 'go', 'pos': 'VERB'}
          : reply(t);
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode(p));
      await request.response.close();
    });
    var revision = 0;
    final client = PersonalLearningClient(
      url: 'https://synthetic.invalid',
      publicKey: 'public',
      token: () async => 'synthetic',
      owner: () async => 'owner',
      revision: () => revision,
      store: consent,
      createClient: () => LoopbackClient(server.port),
    );
    await client.setConsent(true);
    final scope = ProviderContainer(
      overrides: [
        contentRepositoryProvider.overrideWith((_) => content),
        userRepositoryProvider.overrideWith((_) => user),
        personalLearningClientProvider.overrideWithValue(client),
      ],
    );
    addTearDown(scope.dispose);
    final service = await scope.read(personalLearningServiceProvider.future);
    await user.ensureCards(
      ['card-went'],
      now: DateTime(2026),
      origin: CardOrigin.deck,
    );
    await user.setCardFlags('card-went', favorite: true, note: 'preserve');
    final item = (await content.practiceItems(['card-went'])).single;
    final pass = ReviewPass(
      id: 'existing-review',
      item: item,
      sentence: item.practiceSentence,
      state: (await user.cardStates(['card-went']))['card-went'],
      mode: ReviewMode.mixed,
      startedAt: DateTime(2026),
    );
    pass.submit('went', DateTime(2026));
    await user.recordReview(
      pass.complete(
        now: DateTime(2026),
        appVersion: 'test',
        deviceId: 'fixture',
      )!,
    );
    final oldReviews = (await db.select(db.reviewLog).get())
        .map((r) => r.toJson())
        .toList();
    final before = (await db.select(db.userCards).getSingle()).toJson();
    final t = target(text: 'She went to the bank.', form: 'went');
    final added = await service.add(t);
    expect(added.cardId, 'card-went');
    expect(inputs.single['candidates'], ['card-went']);
    expect((await db.select(db.userCards).getSingle()).toJson(), before);
    expect((await user.explicitStoryAdditions()).keys, contains('card-went'));
    expect((await service.add(t)).cardId, 'card-went');
    expect(calls, 1);
    final imported = scope
        .read(importedTextsProvider.notifier)
        .add(target().text);
    final baseTarget = target();
    final newTarget = PersonalTarget(
      lang: baseTarget.lang,
      text: baseTarget.text,
      form: baseTarget.form,
      start: baseTarget.start,
      source: imported.id,
    );
    final results = await Future.wait(
      List.generate(8, (_) => service.add(newTarget)),
    );
    expect(results.map((r) => r.cardId).toSet(), {newTarget.identity.localId});
    expect(calls, 2);
    final localBefore = (await db.select(db.userCards).get())
        .map((r) => r.toJson())
        .toList();
    final localAgain = await service.add(
      target(text: 'I put the zorb on the table.'),
    );
    expect(localAgain.cardId, newTarget.identity.localId);
    expect(calls, 3);
    expect(inputs.last['local_candidates'], hasLength(1));
    expect(
      (await db.select(db.userCards).get()).map((r) => r.toJson()).toList(),
      localBefore,
    );
    scope.read(importedTextsProvider.notifier).remove(imported.id);
    expect(scope.read(importedTextsProvider), isEmpty);
    final cacheDb = sql.sqlite3.openInMemory();
    final cache = TranslationCache(() async => cacheDb);
    await cache.write('owner', newTarget.key, {
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'translation_de': 'Synthetischer Hinweis',
    });
    cacheDb.execute('UPDATE translations SET expires=0');
    expect(await cache.read('owner', newTarget.key), isNull);
    await cache.markDeletion('owner');
    await cache.close();
    expect(
      (await user.localPracticeItems()).single.practiceSentence.text,
      newTarget.text,
    );
    expect((await service.saved(newTarget))!.state, StoryAddState.added);
    await expectLater(user.cardStates(['invented']), throwsStateError);
    expect(
      (await db.select(db.reviewLog).get()).map((r) => r.toJson()).toList(),
      oldReviews,
    );
    revision++;
  });
  test('consent separate, owner scoped, fail closed, revocation before token prevents HTTP', () async {
    final db = sql.sqlite3.openInMemory(),
        store = PersonalConsentStore(() async => db);
    addTearDown(store.close);
    var owner = 'a', revision = 0, http = 0;
    final gate = Completer<String>(), entered = Completer<void>();
    final client = PersonalLearningClient(
      url: 'https://fixture.invalid',
      publicKey: 'public',
      token: () {
        entered.complete();
        return gate.future;
      },
      owner: () async => owner,
      revision: () => revision,
      store: store,
      createClient: () {
        http++;
        throw StateError('must not send');
      },
    );
    expect(await client.consent(), isFalse);
    await expectLater(
      client.create(target(), []),
      throwsA(isA<PersonalLearningFailure>()),
    );
    expect(http, 0);
    await client.setConsent(true);
    owner = 'b';
    revision++;
    expect(await client.consent(), isFalse);
    owner = 'a';
    revision++;
    expect(await client.consent(), isTrue);
    final pending = client.create(target(), []);
    final check = expectLater(pending, throwsA(isA<PersonalLearningFailure>()));
    await entered.future;
    await client.setConsent(false);
    gate.complete('synthetic');
    await check;
    expect(http, 0);
    await client.setConsent(true);
    db.execute('PRAGMA query_only=ON');
    await expectLater(client.setConsent(false), throwsA(anything));
    expect(await client.consent(), isFalse);
    await expectLater(client.create(target(), []), throwsA(anything));
    expect(http, 0);
  });
  test('HTTP errors and malformed payload never save; account/scope switch rejects late result', () async {
    HttpOverrides.global = null;
    final dir = Directory.systemTemp.createTempSync('personal-fail');
    addTearDown(() => dir.deleteSync(recursive: true));
    final content = await fixtureInstaller(
      dir,
      Directory('${dir.path}/support'),
    ).open();
    addTearDown(content.close);
    final user = DriftUserRepository(
      UserDatabase(NativeDatabase.memory()),
      lang: 'en',
    );
    addTearDown(user.close);
    final store = PersonalConsentStore(() async => sql.sqlite3.openInMemory());
    addTearDown(store.close);
    var status = 429, calls = 0, revision = 0;
    bool malformed = false;
    Completer<void>? wait;
    Completer<void>? entered;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((r) async {
      calls++;
      await utf8.decoder.bind(r).join();
      entered?.complete();
      await wait?.future;
      r.response.statusCode = status;
      r.response.write(
        jsonEncode(malformed ? {'invented': true} : reply(target())),
      );
      await r.response.close();
    });
    final client = PersonalLearningClient(
      url: 'https://fixture.invalid',
      publicKey: 'public',
      token: () async => 'synthetic',
      owner: () async => 'a',
      revision: () => revision,
      store: store,
      createClient: () => LoopbackClient(server.port),
    );
    await client.setConsent(true);
    final scope = ProviderContainer(
      overrides: [
        contentRepositoryProvider.overrideWith((_) => content),
        userRepositoryProvider.overrideWith((_) => user),
        personalLearningClientProvider.overrideWithValue(client),
      ],
    );
    addTearDown(scope.dispose);
    final service = await scope.read(personalLearningServiceProvider.future);
    for (final code in [429, 504, 503, 409]) {
      status = code;
      await expectLater(
        service.add(target()),
        throwsA(isA<PersonalLearningFailure>()),
      );
    }
    expect(calls, 4);
    expect(await user.allCardStates(), isEmpty);
    status = 200;
    malformed = true;
    await expectLater(service.add(target()), throwsFormatException);
    expect(await user.allCardStates(), isEmpty);
    malformed = false;
    wait = Completer<void>();
    entered = Completer<void>();
    final pending = service.add(target());
    final check = expectLater(pending, throwsA(isA<PersonalLearningFailure>()));
    await entered.future;
    revision++;
    wait.complete();
    await check;
    expect(await user.allCardStates(), isEmpty);
    // Same response arriving after provider/language disposal cannot save.
    wait = Completer<void>();
    entered = Completer<void>();
    final changedScope = service.add(target());
    final checkedScope = expectLater(
      changedScope,
      throwsA(isA<PersonalLearningFailure>()),
    );
    await entered.future;
    scope.invalidate(personalLearningServiceProvider);
    wait.complete();
    await checkedScope;
    expect(await user.allCardStates(), isEmpty);
  });
  testWidgets(
    'mount does not create; Add requests separate consent; decline makes zero requests',
    (tester) async {
      final dir = Directory.systemTemp.createTempSync('personal-ui');
      addTearDown(() => dir.deleteSync(recursive: true));
      final content = (await tester.runAsync(
        () => fixtureInstaller(dir, Directory('${dir.path}/support')).open(),
      ))!;
      addTearDown(content.close);
      final user = DriftUserRepository(
        UserDatabase(NativeDatabase.memory()),
        lang: 'en',
        contentIds: (_) => content.allCardIds(),
      );
      addTearDown(user.close);
      final store = PersonalConsentStore(
        () async => sql.sqlite3.openInMemory(),
      );
      // Teardown runs outside FakeAsync: create the memoized Future there too.
      await tester.runAsync(store.db);
      addTearDown(store.close);
      var calls = 0;
      final client = PersonalLearningClient(
        url: 'https://fixture.invalid',
        publicKey: 'public',
        token: () async {
          calls++;
          throw StateError('no request');
        },
        owner: () async => 'a',
        revision: () => 0,
        store: store,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            contentRepositoryProvider.overrideWith((_) => content),
            userRepositoryProvider.overrideWith((_) => user),
            personalLearningClientProvider.overrideWithValue(client),
          ],
          child: MaterialApp(
            home: Scaffold(body: PersonalLearningButton(target: target())),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(calls, 0);
      await tester.runAsync(() async {
        await tester.tap(find.text('Zum Lernen hinzufügen'));
        // Consent storage was opened in the real async zone. Drain its I/O.
        await Future<void>.delayed(Duration.zero);
      });
      // Add intentionally stays busy while the consent dialog awaits input.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Private Lernkarten ermöglichen?'), findsOneWidget);
      expect(calls, 0);

      await tester.tap(find.text('Abbrechen'));

      await tester.pumpAndSettle();

      expect(calls, 0);

      expect(await tester.runAsync(user.allCardStates), isEmpty);
    },
  );
}
