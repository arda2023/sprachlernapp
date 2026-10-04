import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/data/content/content_database.dart';
import 'package:sprachapp/data/content/drift_content_repository.dart';
import 'package:sprachapp/data/user/user_database.dart';
import 'package:sprachapp/data/user/drift_user_repository.dart';
import 'package:sprachapp/domain/story_learning.dart';
import 'package:sprachapp/domain/srs_state.dart';
import 'package:sprachapp/models/home_models.dart';
import 'package:sprachapp/models/story_models.dart';
import 'package:sprachapp/presentation/providers/database_providers.dart';
import 'package:sprachapp/presentation/providers/story_learning_providers.dart';
import 'package:sprachapp/presentation/providers/learning_providers.dart';
import 'package:sprachapp/presentation/providers/deck_providers.dart';
import 'package:sprachapp/presentation/practice/deck_session_controller.dart';
import 'package:sprachapp/screens/stories/story_reader_screen.dart';
import 'package:sprachapp/screens/stories/widgets/word_lookup_sheet.dart';
import 'package:sprachapp/theme/app_theme.dart';

import 'fixtures/story_learning.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  testWidgets(
    'add waits for commit, guards double tap and reports failure honestly',
    (tester) async {
      var calls = 0;
      var pending = Completer<StoryAddResult>();
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: WordLookupSheet(
              surface: 'backpack',
              entry: const WordEntry(
                headword: 'backpack',
                partOfSpeech: 'NOUN',
                translation: 'Rucksack',
              ),
              mark: null,
              status: const StoryAddResult(StoryAddState.available),
              onAdd: () {
                calls++;
                return pending.future;
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('Zum Lernen hinzufügen'));
      await tester.pump();
      expect(find.text('Wird hinzugefügt …'), findsOneWidget);
      await tester.tap(find.text('Wird hinzugefügt …'));
      expect(calls, 1);
      pending.completeError(StateError('write failure'));
      await tester.pumpAndSettle();
      expect(
        find.text('Nicht gespeichert – erneut versuchen.'),
        findsOneWidget,
      );
      expect(find.text('Bereits hinzugefügt'), findsNothing);
      pending = Completer<StoryAddResult>();
      await tester.tap(find.text('Zum Lernen hinzufügen'));
      await tester.pump();
      pending.complete(
        const StoryAddResult(StoryAddState.added, cardId: 'saved'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Bereits hinzugefügt'), findsOneWidget);
    },
  );
  test('missing pack keeps a complete local card in list, counters and real mixed controller', () async {
    final user = DriftUserRepository(
      UserDatabase(NativeDatabase.memory()),
      lang: 'en',
    );
    final c = storyCandidate();
    await user.addStoryWord(c, now: DateTime(2026, 10, 4));
    final scope = ProviderContainer(
      overrides: [
        userRepositoryProvider.overrideWith((ref) async => user),
        contentRepositoryProvider.overrideWith(
          (ref) async => throw StateError('Missing content'),
        ),
        appInfoProvider.overrideWith((ref) async => 'test'),
      ],
    );
    addTearDown(() async {
      scope.dispose();
      await user.close();
    });
    expect((await scope.read(wordListProvider.future)).single.box, 0);
    expect((await scope.read(vocabBreakdownProvider.future)).unseen, 1);
    expect((await scope.read(learningProgressProvider.future)).goal.done, 0);
    const args = (deckId: '', kind: DeckSessionKind.mixed, size: 1);
    final provider = deckSessionControllerProvider(args);
    final sub = scope.listen(provider, (_, _) {});
    addTearDown(sub.close);
    for (var i = 0; i < 60 && scope.read(provider).loading; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(scope.read(provider).error, isNull);
    expect(scope.read(provider).pass!.item.card.id, c.identity.localId);
    scope.read(provider.notifier).submit('backpack');
    for (var i = 0; i < 60 && !scope.read(provider).saved; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect((await user.reviewsFor(c.identity.localId)).single.boxAfter, 3);
  });
  final pack = File('pipeline/out/story_learning_v1/content.sqlite');
  testWidgets(
    'real annotated Story: word tap read-only, table existing / backpack local, box zero projections',
    (tester) async {
      final content = DriftContentRepository(
        ContentDatabase.open(pack, lang: 'en'),
      );
      final user = DriftUserRepository(
        UserDatabase(NativeDatabase.memory()),
        lang: 'en',
      );
      final doc = await content.storyDocument(
        (await content.storySummaries()).single.id,
      );
      expect(doc.summary.title, 'The Open Pocket');
      expect(doc.summary.titleDe, 'Die offene Tasche');
      expect(doc.sentences.length, 6);
      for (final sentence in doc.sentences) {
        for (final token in sentence.tokens.where((t) => t.lemmaId != null)) {
          expect(token.annotated, isTrue, reason: token.surface);
        }
      }
      for (final d in await content.decks()) {
        await user.setDeckActive(d.id, false, now: DateTime.now());
      }
      final scope = ProviderContainer(
        overrides: [
          learningNowProvider.overrideWith((ref) => DateTime(2026, 10, 4)),
          userRepositoryProvider.overrideWith((ref) async => user),
          contentRepositoryProvider.overrideWith((ref) async => content),
        ],
      );
      addTearDown(() async {
        scope.dispose();
        await user.close();
        await content.close();
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: scope,
          child: MaterialApp(
            theme: buildAppTheme(),
            home: StoryReaderScreen(
              story: Story(
                id: doc.summary.id,
                title: doc.summary.title,
                topic: 'Alltag',
                level: 'A2',
                readingMinutes: 1,
              ),
              document: doc,
              text: StoryText(
                storyId: doc.summary.id,
                paragraphs: doc.sentences.map((s) => s.text).toList(),
              ),
              initialMarks: const {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> tap(String word) async {
        final f = find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().startsWith('She puts'),
        );
        final p = tester.renderObject<RenderParagraph>(f.first);
        final offset = p.text.toPlainText().indexOf(word) + 1;
        await tester.tapAt(
          p.localToGlobal(
            p
                .getBoxesForSelection(
                  TextSelection(baseOffset: offset, extentOffset: offset + 1),
                )
                .first
                .toRect()
                .center,
          ),
        );
        for (var i = 0; i < 15; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 15)),
          );
          await tester.pump();
        }
        await tester.pumpAndSettle();
      }

      await tap('table');
      expect(await user.allCardStates(), isEmpty);
      final service = scope.read(storyLearningServiceProvider);
      final s = doc.sentences[1];
      final table = await service.candidate(
        doc.summary.id,
        s.id,
        s.tokens.singleWhere((t) => t.surface == 'table').index,
      );
      expect(table.card, isNotNull);
      final original = (await content.practiceItems([table.card!.id])).single;
      await tester.tap(find.text('Zum Lernen hinzufügen'));
      for (var i = 0; i < 15; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 15)),
        );
        await tester.pump();
      }
      await tester.pumpAndSettle();
      expect(find.text('Bereits hinzugefügt'), findsOneWidget);
      Navigator.of(tester.element(find.byType(WordLookupSheet))).pop();
      await tester.pumpAndSettle();
      await tap('backpack');
      expect((await user.allCardStates()).length, 1);
      await tester.tap(find.text('Zum Lernen hinzufügen'));
      for (var i = 0; i < 15; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 15)),
        );
        await tester.pump();
      }
      await tester.pumpAndSettle();
      expect(find.text('Bereits hinzugefügt'), findsOneWidget);
      final local = (await user.localPracticeItems()).single;
      expect(local.card.form, 'backpack');
      expect(local.practiceSentence.text, s.text);
      expect((await user.explicitStoryAdditions()).length, 2);
      expect((await scope.read(wordListProvider.future)).map((w) => w.box), [
        0,
        0,
      ]);
      expect((await scope.read(vocabBreakdownProvider.future)).unseen, 2);
      expect(
        (await content.practiceItems([table.card!.id]))
            .single
            .practiceSentence
            .sentenceId,
        original.practiceSentence.sentenceId,
      );
      final platform = await content.resolveStoryWord(
        doc.summary.id,
        doc.sentences.last.id,
        doc.sentences.last.tokens
            .singleWhere((t) => t.surface == 'platform')
            .index,
      );
      expect(platform.card, isNull);
      expect(platform.token.gloss, 'Bahnsteig');
    },
    skip: !pack.existsSync(),
  );
}
