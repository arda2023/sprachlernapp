import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/data/runtime_translation_client.dart';
import 'package:sprachapp/domain/story_learning.dart';
import 'package:sprachapp/models/sample_content.dart';
import 'package:sprachapp/models/story_models.dart';
import 'package:sprachapp/presentation/providers/runtime_translation_provider.dart';
import 'package:sprachapp/screens/stories/story_reader_screen.dart';
import 'package:sprachapp/widgets/runtime_translation_sheet.dart';
import 'package:sprachapp/screens/stories/widgets/sentence_popover.dart';
import 'package:sprachapp/theme/app_theme.dart';

class LoopbackClient implements HttpClient {
  LoopbackClient(this.port);
  final int port;
  final HttpClient inner = HttpClient();
  @override
  set connectionTimeout(Duration? value) {
    inner.connectionTimeout = value;
  }

  @override
  Future<HttpClientRequest> postUrl(Uri url) =>
      inner.postUrl(Uri.parse('http://127.0.0.1:$port${url.path}'));
  @override
  void close({bool force = false}) => inner.close(force: force);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeTranslations extends RuntimeTranslationClient {
  FakeTranslations()
    : super('https://unused.invalid', 'public', () async => 'synthetic');
  final List<Map<String, Object?>> calls = [];
  bool fail = false;
  @override
  Future<RuntimeTranslation> translate({
    required String lang,
    required String text,
    String? form,
  }) async {
    calls.add({'lang': lang, 'text': text, 'form': form});
    if (fail) throw const TranslationFailure('Übersetzungslimit erreicht.');
    return const RuntimeTranslation(
      'Die Bank.',
      'claude-haiku-5-5',
      'synthetic-request',
    );
  }
}

Future<void> tapWord(WidgetTester tester, String word) async {
  final body = find.byWidgetPredicate(
    (w) => w is RichText && w.text.toPlainText().contains(word),
  );
  final p = tester.renderObject<RenderParagraph>(body.first);
  final offset = p.text.toPlainText().indexOf(word) + 1;
  final boxes = p.getBoxesForSelection(
    TextSelection(baseOffset: offset, extentOffset: offset + 1),
  );
  await tester.tapAt(p.localToGlobal(boxes.first.toRect().center));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  test('placeholder classification keeps genuine pack translations', () {
    expect(hasStoredTranslation('Die Bank.'), isTrue);
    for (final value in [
      '',
      '  ',
      'Übersetzung folgt',
      'Übersetzung folgt.',
      'Übersetzung nicht verfügbar',
    ]) {
      expect(hasStoredTranslation(value), isFalse);
    }
  });
  for (final lang in ['en', 'pt-BR']) {
    test('HTTP client sends only context and languages ($lang)', () async {
      HttpOverrides.global = null;
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      final calls = <Map<String, dynamic>>[];
      server.listen((request) async {
        expect(request.uri.path, '/functions/v1/lookup-word');
        expect(request.headers.value('authorization'), 'Bearer synthetic-jwt');
        expect(request.headers.value('apikey'), 'public-test');
        calls.add(
          jsonDecode(await utf8.decoder.bind(request).join())
              as Map<String, dynamic>,
        );
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode({
            'provider': 'anthropic',
            'model': 'claude-haiku-5-5',
            'request_id': 'test-id',
            'form': 'banco',
            'senses': [
              {'gloss_de': 'Bank'},
            ],
          }),
        );
        await request.response.close();
      });
      final client = RuntimeTranslationClient(
        'https://project.invalid',
        'public-test',
        () async => 'synthetic-jwt',
        createClient: () => LoopbackClient(server.port),
      );
      expect(
        (await client.translate(
          lang: lang,
          text: 'O banco.',
          form: 'banco',
        )).text,
        'Bank',
      );
      expect(calls.single, {
        'lang': lang,
        'target_lang': 'de',
        'form': 'banco',
        'sentence': 'O banco.',
      });
    });
    testWidgets(
      'missing word requires explicit action and sends full context ($lang)',
      (tester) async {
        final fake = FakeTranslations();
        final text = lang == 'en' ? 'The bank.' : 'O banco.';
        final word = lang == 'en' ? 'bank' : 'banco';
        await tester.pumpWidget(
          ProviderScope(
            overrides: [runtimeTranslationProvider.overrideWithValue(fake)],
            child: MaterialApp(
              theme: buildAppTheme(),
              home: StoryReaderScreen(
                story: sampleStories.first,
                text: StoryText(storyId: 'test', paragraphs: [text]),
                sourceLanguage: lang,
                lookup: WordEntry.unknown,
              ),
            ),
          ),
        );
        await tapWord(tester, word);
        expect(find.byType(RuntimeTranslationSheet), findsOneWidget);
        expect(fake.calls, isEmpty);
        await tester.tap(find.text('Mit KI übersetzen'));
        await tester.pumpAndSettle();
        expect(fake.calls.single, {'lang': lang, 'text': text, 'form': word});
        expect(find.text('Die Bank.'), findsOneWidget);
        expect(find.text('KI · claude-haiku-5-5'), findsOneWidget);
      },
    );
  }
  for (final status in [401, 403, 429, 504, 200]) {
    test(
      'HTTP failure $status never invents a translation or retries',
      () async {
        HttpOverrides.global = null;
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(() => server.close(force: true));
        var count = 0;
        server.listen((request) async {
          count++;
          await request.drain<void>();
          request.response.statusCode = status;
          request.response.write(
            jsonEncode({
              'provider': 'gemini',
              'model': 'wrong',
              'raw': 'must not appear',
            }),
          );
          await request.response.close();
        });
        final client = RuntimeTranslationClient(
          'https://project.invalid',
          'public',
          () async => 'synthetic',
          createClient: () => LoopbackClient(server.port),
        );
        await expectLater(
          client.translate(lang: 'en', text: 'The bank.'),
          throwsA(
            isA<TranslationFailure>().having(
              (e) => e.message,
              'safe message',
              isNot(contains('must not appear')),
            ),
          ),
        );
        expect(count, 1);
      },
    );
  }
  test('missing local login fails before HTTP construction', () async {
    final client = RuntimeTranslationClient(
      'https://project.invalid',
      'public',
      () async => throw StateError('private'),
      createClient: () => throw StateError('network must not run'),
    );
    await expectLater(
      client.translate(lang: 'en', text: 'The bank.'),
      throwsA(
        isA<TranslationFailure>().having(
          (e) => e.message,
          'login',
          'Bitte zuerst in den Einstellungen anmelden.',
        ),
      ),
    );
  });
  testWidgets('stored sentence never resolves translation provider', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          runtimeTranslationProvider.overrideWith(
            (ref) => throw StateError('network must not be used'),
          ),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: StoryReaderScreen(
            story: sampleStories.first,
            text: sampleStoryText(sampleStories.first.id),
            document: const StoryDocument(
              StorySummary(
                id: 'test',
                title: 'Test',
                titleDe: 'Test',
                level: 'A2',
                minutes: 1,
              ),
              'fixture',
              [
                StorySentence(
                  id: 's1',
                  text: 'Clara arrived.',
                  translation: 'Clara kam an.',
                  paragraph: 0,
                  tokens: [
                    StoryToken(index: 0, start: 0, end: 5, surface: 'Clara'),
                    StoryToken(
                      index: 1,
                      start: 6,
                      end: 13,
                      surface: 'arrived',
                      lemmaId: 'arrive',
                      gloss: 'kam an',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.bySemanticsLabel('Übersetzen'));
    await tester.pumpAndSettle();
    await tapWord(tester, 'arrived');
    expect(find.byType(SentencePopover), findsOneWidget);
    expect(find.byType(RuntimeTranslationSheet), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('missing sentence invokes backend once after explicit action', (
    tester,
  ) async {
    final fake = FakeTranslations();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [runtimeTranslationProvider.overrideWithValue(fake)],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: StoryReaderScreen(
            story: sampleStories.first,
            text: const StoryText(storyId: 'test', paragraphs: ['The bank.']),
            translate: (_) => 'Übersetzung folgt.',
          ),
        ),
      ),
    );
    await tester.tap(find.bySemanticsLabel('Übersetzen'));
    await tester.pumpAndSettle();
    await tapWord(tester, 'bank');
    expect(fake.calls, isEmpty);
    await tester.tap(find.text('Mit KI übersetzen'));
    await tester.pumpAndSettle();
    expect(fake.calls.single, {
      'lang': 'en',
      'text': 'The bank.',
      'form': null,
    });
    expect(find.text('Mit KI übersetzen'), findsNothing);
  });
  testWidgets(
    'failure shows no invented translation and masked exercise stays masked',
    (tester) async {
      final fake = FakeTranslations()..fail = true;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [runtimeTranslationProvider.overrideWithValue(fake)],
          child: const MaterialApp(
            home: Scaffold(
              body: RuntimeTranslationSheet(
                lang: 'en',
                text: 'Tom woke up.',
                displayText: 'Tom … up.',
              ),
            ),
          ),
        ),
      );
      expect(find.text('Tom woke up.'), findsNothing);
      expect(find.text('Tom … up.'), findsOneWidget);
      await tester.tap(find.text('Mit KI übersetzen'));
      await tester.pumpAndSettle();
      expect(find.text('Übersetzungslimit erreicht.'), findsOneWidget);
      expect(find.text('Die Bank.'), findsNothing);
      expect(fake.calls.length, 1);
    },
  );
}
