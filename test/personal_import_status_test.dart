import 'package:sprachapp/data/content/content_database.dart';
import 'package:sprachapp/data/content/drift_content_repository.dart';

import 'dart:io';
import 'dart:convert';

import 'package:sprachapp/presentation/providers/runtime_translation_provider.dart';
import 'package:sprachapp/domain/story_learning.dart';

import 'personal_learning_flow_test.dart' show EmptyTranslationCache;
import 'personal_learning_test.dart' show reply;
import 'runtime_translation_test.dart' show LoopbackClient;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sqlite3/sqlite3.dart' as sql;
import 'package:sprachapp/data/user/user_database.dart';
import 'package:sprachapp/data/user/drift_user_repository.dart';
import 'package:sprachapp/data/personal_learning_client.dart';
import 'package:sprachapp/domain/personal_learning.dart';
import 'package:sprachapp/domain/story_failure_trace.dart';
import 'package:sprachapp/domain/story_learning_diagnostics.dart';
import 'package:sprachapp/models/sample_content.dart';
import 'package:sprachapp/models/story_models.dart';
import 'package:sprachapp/presentation/providers/database_providers.dart';
import 'package:sprachapp/presentation/providers/personal_learning_provider.dart';
import 'package:sprachapp/screens/stories/story_reader_screen.dart';
import 'package:sprachapp/widgets/personal_learning_button.dart';

import 'data/support.dart';

Future<DriftContentRepository> openContent(Directory dir) async {
  final path = Platform.environment['STORY_STATUS_PACK'];
  if (path != null)
    return DriftContentRepository(ContentDatabase.open(File(path), lang: 'en'));
  return fixtureInstaller(dir, Directory('${dir.path}/support')).open();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  test('explicit Add persists both import targets; status is read-only and offline', () async {
    HttpOverrides.global = null;
    final dir = Directory.systemTemp.createTempSync('import-add');
    addTearDown(() => dir.deleteSync(recursive: true));
    final content = await openContent(dir);
    addTearDown(content.close);
    final db = UserDatabase(NativeDatabase.memory());
    final user = DriftUserRepository(
      db,
      lang: 'en',
      contentIds: (_) => content.allCardIds(),
    );
    addTearDown(user.close);
    var calls = 0;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((r) async {
      calls++;
      final b = jsonDecode(await utf8.decoder.bind(r).join());
      final t = PersonalTarget(
        lang: b['lang'],
        text: b['text'],
        form: b['form'],
        start: b['start'],
        source: 'synthetic',
      );
      r.response.headers.contentType = ContentType.json;
      r.response.write(jsonEncode(reply(t)));
      await r.response.close();
    });
    final client = PersonalLearningClient(
      url: 'https://synthetic.invalid',
      publicKey: 'public',
      token: () async => 'synthetic',
      owner: () async => 'synthetic',
      revision: () => 0,
      store: PersonalConsentStore(() async => sql.sqlite3.openInMemory()),
      createClient: () => LoopbackClient(server.port),
    );
    addTearDown(client.close);
    final scope = ProviderContainer(
      overrides: [
        contentRepositoryProvider.overrideWith((_) => content),
        userRepositoryProvider.overrideWith((_) => user),
        personalLearningClientProvider.overrideWithValue(client),
        runtimeTranslationProvider.overrideWithValue(EmptyTranslationCache()),
        personalReleaseReferenceProvider.overrideWith(
          (_) async => {
            'release_id': '12345678-1234-4234-8234-123456789abc',
            'manifest_sha256': 'a' * 64,
            'sqlite_sha256': 'b' * 64,
          },
        ),
      ],
    );
    addTearDown(scope.dispose);
    final service = await scope.read(personalLearningServiceProvider.future);
    for (final text in [
      'I am the return-hamster',
      'The hamster sleeps in its cage.',
    ]) {
      final m = personalWords(text)
          .singleWhere((m) => m[0]!.contains('hamster'));
      final t = PersonalTarget(
        lang: 'en',
        text: text,
        form: m[0]!,
        start: m.start,
        source: 'synthetic-import',
      );
      t.validate();
      final before = calls;
      expect(await service.saved(t), isNull);
      expect(calls, before);
      await client.setConsent(false);
      await expectLater(
        service.add(t),
        throwsA(isA<PersonalLearningFailure>()),
      );
      expect(calls, before);
      await client.setConsent(true);
      final added = await service.add(t);
      expect(added.state, StoryAddState.added);
      expect(
        (await user.explicitStoryAdditions()).keys,
        contains(added.cardId),
      );
      expect((await service.saved(t))!.cardId, added.cardId);
      expect((await service.add(t)).cardId, added.cardId);
      expect(calls, before + 1);
    }
    expect(await user.localPracticeItems(), hasLength(2));
    expect(await db.select(db.reviewLog).get(), isEmpty);
    await expectLater(user.cardStates(['invalid-reference']), throwsStateError);
  });
  for (final invalidTarget in [true, false]) {
    testWidgets(
      'invalid selection and technical repository error stay distinct: $invalidTarget',
      (tester) async {
        const text = 'I am the return-hamster';
        final form = invalidTarget ? 'hamster' : 'return-hamster';
        var reads = 0;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              personalLearningServiceProvider.overrideWith((_) {
                reads++;
                throw StateError('synthetic storage failure');
              }),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: PersonalLearningButton(
                  target: PersonalTarget(
                    lang: 'en',
                    text: text,
                    form: form,
                    start: text.indexOf(form),
                    source: 'synthetic',
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.textContaining(
            invalidTarget
                ? 'Diese Wortstelle eignet sich nicht'
                : 'Lernstatus nicht lesbar',
          ),
          findsOneWidget,
        );
        expect(reads, invalidTarget ? 0 : 1);
        expect(
          tester
              .widget<TextButton>(
                find.widgetWithText(TextButton, 'Zum Lernen hinzufügen'),
              )
              .onPressed,
          isNull,
        );
      },
    );
  }
  for (final text in [
    'I am the return-hamster',
    'The hamster sleeps in its cage.',
    '😀 I am the return-hamster',
    'First sentence. The hamster sleeps in its cage.',
  ]) {
    testWidgets(
      'import selection preserves complete validated occurrence: $text',
      (tester) async {
        final dir = Directory.systemTemp.createTempSync('import-status');
        addTearDown(() => dir.deleteSync(recursive: true));
        final content = (await tester.runAsync(() => openContent(dir)))!;
        addTearDown(content.close);
        final db = UserDatabase(NativeDatabase.memory());
        final user = DriftUserRepository(
          db,
          lang: 'en',
          contentIds: (_) => content.allCardIds(),
        );
        addTearDown(user.close);
        var requests = 0;
        final client = PersonalLearningClient(
          url: 'https://synthetic.invalid',
          publicKey: 'public',
          owner: () async => 'synthetic',
          revision: () => 0,
          token: () async {
            requests++;
            throw StateError('Status must not request a token');
          },
          store: PersonalConsentStore(() async => sql.sqlite3.openInMemory()),
        );
        addTearDown(client.close);
        final scope = ProviderContainer(
          overrides: [
            contentRepositoryProvider.overrideWith((_) => content),
            userRepositoryProvider.overrideWith((_) => user),
            personalLearningClientProvider.overrideWithValue(client),
          ],
        );
        addTearDown(scope.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: scope,
            child: MaterialApp(
              home: StoryReaderScreen(
                story: sampleStories.first,
                text: StoryText(
                  storyId: 'synthetic-import',
                  paragraphs: [text],
                ),
                lookup: (word) => WordEntry(
                  headword: word,
                  partOfSpeech: 'NOUN',
                  translation: 'Nagetiere',
                ),
                initialMarks: const {},
              ),
            ),
          ),
        );
        final body = find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('hamster'),
        );
        final paragraph = tester.renderObject<RenderParagraph>(body.first);
        final offset = paragraph.text.toPlainText().indexOf('hamster') + 1;
        final box = paragraph
            .getBoxesForSelection(
              TextSelection(baseOffset: offset, extentOffset: offset + 1),
            )
            .first;
        await tester.tapAt(paragraph.localToGlobal(box.toRect().center));
        await tester.pump();
        final button = tester.widget<PersonalLearningButton>(
          find.byType(PersonalLearningButton),
        );
        // Captures the actual reader selection, not a separately invented target.
        final target = button.target;
        try {
          target.validate();
        } catch (e, s) {
          // Only class/source positions, never the error message or private data.
          debugPrint(storyFailureTrace(StoryLearningStep.status, e, s));
          rethrow;
        }
        expect(target.form, text.contains('-') ? 'return-hamster' : 'hamster');
        expect(target.text.substring(target.start, target.end), target.form);
        final service = (await tester.runAsync(
          () => scope.read(personalLearningServiceProvider.future),
        ))!;
        expect(await tester.runAsync(() => service.saved(target)), isNull);
        expect(await tester.runAsync(user.allCardStates), isEmpty);
        expect(requests, 0);
        await tester.pumpAndSettle();
        expect(
          find.text('Lernstatus nicht lesbar. Bitte erneut öffnen.'),
          findsNothing,
        );
        expect(
          tester
              .widget<TextButton>(
                find.widgetWithText(TextButton, 'Zum Lernen hinzufügen'),
              )
              .onPressed,
          isNotNull,
        );
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
