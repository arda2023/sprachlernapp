// Characterization tests: they pin what AppShell and WebLearningShell do
// today in _openStory, _openImported and _importText, so the two near-identical
// implementations can later be merged without a behavior change.
//
// The shells hand these methods to StoryLibraryScreen as callbacks. Several
// branches cannot be reached by tapping, because the library and the import
// panel check Premium themselves before they call back (a locked card calls
// its own upgrade action, a locked import source opens the paywall). Those
// branches are exercised by invoking the callback the shell passed down.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/models/sample_content.dart';
import 'package:sprachapp/presentation/providers/database_providers.dart';
import 'package:sprachapp/presentation/providers/learning_sync_provider.dart';
import 'package:sprachapp/presentation/providers/purchase_provider.dart';
import 'package:sprachapp/presentation/providers/reading_providers.dart';
import 'package:sprachapp/screens/app_shell.dart';
import 'package:sprachapp/screens/content/content_dashboard_screen.dart';
import 'package:sprachapp/screens/onboarding/paywall_screen.dart';
import 'package:sprachapp/screens/stories/story_library_screen.dart';
import 'package:sprachapp/screens/stories/story_reader_screen.dart';
import 'package:sprachapp/screens/stories/widgets/import_panel.dart';
import 'package:sprachapp/screens/web/web_learning_shell.dart';
import 'package:sprachapp/theme/app_theme.dart';
import 'package:sprachapp/widgets/app_bottom_bar.dart';

import 'fixtures/deck_repositories.dart';

class _FixedPurchase extends PurchaseController {
  _FixedPurchase(this.fixed);
  final PurchaseState fixed;
  @override
  PurchaseState build() => fixed;
  @override
  Future<void> load() async {}
}

class _IdleSync extends LearningSyncController {
  @override
  LearningSyncPhase build() => LearningSyncPhase.signedOut;
}

const _allowed = PurchaseState(hasVerifiedAccount: true, premiumActive: true);
const _premiumRequired = PurchaseState(
  hasVerifiedAccount: true,
  premiumActive: false,
);
const _statusUnknown = PurchaseState(hasVerifiedAccount: true);

typedef _Shell = ({String name, Widget widget, Size size, bool native});

const _shells = <_Shell>[
  (name: 'AppShell', widget: AppShell(), size: Size(390, 844), native: true),
  (
    name: 'WebLearningShell',
    widget: WebLearningShell(),
    size: Size(1200, 1000),
    native: false,
  ),
];

/// Not part of sampleReadStoryIds, so a new history entry is visible.
final _story = sampleStories.firstWhere(
  (s) => !sampleReadStoryIds.contains(s.id),
);

final _own = ImportedText(
  id: 'own-text',
  title: 'My own text',
  body: 'A short text of my own.',
  source: ImportSource.pasted,
  createdAt: DateTime(2026, 11, 1),
);

Future<MemoryJsonStore> _storedProgress(String id, double fraction) async {
  final store = MemoryJsonStore();
  await store.write({
    id: ReadingEntry(
      fraction: fraction,
      updatedAt: DateTime(2026, 11, 1),
    ).toJson(),
  });
  return store;
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  for (final shell in _shells) {
    Future<void> pumpShell(
      WidgetTester tester, {
      required PurchaseState purchase,
      String Function()? language,
      List<Override> overrides = const [],
    }) async {
      tester.view.physicalSize = shell.size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        testScope(
          MaterialApp(theme: buildAppTheme(), home: shell.widget),
          library: true,
          premium: purchase.hasPremiumUiAccess,
          overrides: [
            purchaseProvider.overrideWith(() => _FixedPurchase(purchase)),
            learningSyncProvider.overrideWith(_IdleSync.new),
            selectedContentLanguageProvider.overrideWith(
              (ref) async => language?.call() ?? 'en',
            ),
            ...overrides,
          ],
        ),
      );
      await tester.pumpAndSettle();
    }

    StoryLibraryScreen library(WidgetTester tester) =>
        tester.widget<StoryLibraryScreen>(
          find.byType(StoryLibraryScreen, skipOffstage: false),
        );

    ProviderContainer container(WidgetTester tester) =>
        ProviderScope.containerOf(
          tester.element(find.byWidget(shell.widget, skipOffstage: false)),
        );

    Future<void> settleRoute(WidgetTester tester) async {
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
    }

    Set<String> history(WidgetTester tester) => tester
        .widget<ContentDashboardScreen>(
          find.byType(ContentDashboardScreen, skipOffstage: false),
        )
        .history
        .storyIds;

    Future<void> showStories(WidgetTester tester) async {
      if (!shell.native) return;
      await tester.tap(
        find.descendant(
          of: find.byType(AppBottomBar),
          matching: find.text('Stories'),
        ),
      );
      await tester.pumpAndSettle();
    }

    void mockClipboard(WidgetTester tester, String text) {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async =>
            call.method == 'Clipboard.getData' ? {'text': text} : null,
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
    }

    Future<void> pasteThroughPanel(WidgetTester tester) async {
      await showStories(tester);
      await tester.tap(find.bySemanticsLabel('Text importieren').first);
      await tester.pumpAndSettle();
      expect(find.byType(ImportPanel), findsOneWidget);
      await tester.tap(find.bySemanticsLabel(RegExp('^Text einfügen')));
      await settleRoute(tester);
    }

    group(shell.name, () {
      testWidgets('story without Premium: Stories paywall, no reader', (
        tester,
      ) async {
        await pumpShell(tester, purchase: _premiumRequired);
        library(tester).onOpenStory(_story);
        await settleRoute(tester);
        expect(
          tester
              .widget<PaywallScreen>(find.byType(PaywallScreen))
              .plan
              .interest,
          'Stories',
        );
        expect(find.byType(StoryReaderScreen), findsNothing);
        if (shell.native) {
          // The paywall branch returns before the history is touched.
          expect(history(tester), isNot(contains(_story.id)));
        }
        expect(tester.takeException(), isNull);
      });

      testWidgets('story with Premium: reader opens at the stored position', (
        tester,
      ) async {
        final store = await _storedProgress(_story.id, 0.5);
        await pumpShell(
          tester,
          purchase: _allowed,
          overrides: [readingStoreProvider.overrideWithValue(store)],
        );
        if (shell.native) expect(history(tester), sampleReadStoryIds);
        library(tester).onOpenStory(_story);
        await settleRoute(tester);
        final reader = tester.widget<StoryReaderScreen>(
          find.byType(StoryReaderScreen),
        );
        expect(reader.story.id, _story.id);
        expect(reader.initialProgress, 0.5);
        expect(reader.onProgress, isNotNull);
        expect(find.byType(PaywallScreen), findsNothing);
        if (shell.native) {
          // Native only: the web shell keeps no reading history.
          expect(history(tester), {...sampleReadStoryIds, _story.id});
        }
        expect(tester.takeException(), isNull);
      });

      testWidgets('story never opened before: reader starts without position', (
        tester,
      ) async {
        await pumpShell(tester, purchase: _allowed);
        library(tester).onOpenStory(_story);
        await settleRoute(tester);
        expect(
          tester
              .widget<StoryReaderScreen>(find.byType(StoryReaderScreen))
              .initialProgress,
          isNull,
        );
      });

      testWidgets('own text without Premium: Eigene Texte paywall', (
        tester,
      ) async {
        await pumpShell(tester, purchase: _premiumRequired);
        library(tester).onOpenImported!(_own);
        await settleRoute(tester);
        expect(
          tester
              .widget<PaywallScreen>(find.byType(PaywallScreen))
              .plan
              .interest,
          'Eigene Texte',
        );
        expect(find.byType(StoryReaderScreen), findsNothing);
        expect(tester.takeException(), isNull);
      });

      testWidgets(
        'own text with Premium: plain reader at the stored position',
        (tester) async {
          final store = await _storedProgress(_own.id, 0.25);
          await pumpShell(
            tester,
            purchase: _allowed,
            overrides: [readingStoreProvider.overrideWithValue(store)],
          );
          library(tester).onOpenImported!(_own);
          await settleRoute(tester);
          final reader = tester.widget<StoryReaderScreen>(
            find.byType(StoryReaderScreen),
          );
          expect(reader.story.id, _own.id);
          expect(reader.story.title, _own.title);
          expect(reader.story.topic, 'Import');
          expect(reader.story.level, 'Eigener Text');
          expect(reader.story.readingMinutes, _own.readingMinutes);
          expect(reader.text.paragraphs, _own.paragraphs);
          expect(reader.document, isNull);
          expect(reader.sourceLanguage, 'en');
          expect(reader.initialMarks, isEmpty);
          // No curated dictionary for own texts: the placeholder entry.
          expect(reader.lookup('Text').headword, 'text');
          expect(reader.lookup('Text').translation, 'Übersetzung folgt');
          expect(reader.initialProgress, 0.25);
          if (shell.native) {
            // Characterization: current behavior. Own texts never enter the
            // reading history.
            expect(history(tester), sampleReadStoryIds);
          }
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets('import with unknown Premium status returns its message', (
        tester,
      ) async {
        await pumpShell(tester, purchase: _statusUnknown);
        expect(
          library(tester).onImportText!('A new text.'),
          'Dein Premium-Zugang konnte noch nicht geprüft werden. '
          'Bitte prüfe ihn erneut.',
        );
        expect(container(tester).read(importedTextsProvider), isEmpty);
      });

      testWidgets('import without Premium returns its message', (tester) async {
        await pumpShell(tester, purchase: _premiumRequired);
        expect(
          library(tester).onImportText!('A new text.'),
          'Neue eigene Texte kannst du mit Premium importieren. '
          'Dein Text bleibt hier vorgemerkt.',
        );
        // Characterization: current behavior. Nothing is stored although the
        // message says the text stays reserved.
        expect(container(tester).read(importedTextsProvider), isEmpty);
      });

      testWidgets('import returns the FormatException message, else adds', (
        tester,
      ) async {
        await pumpShell(tester, purchase: _allowed);
        expect(library(tester).onImportText!('   '), 'Der Text ist leer.');
        expect(container(tester).read(importedTextsProvider), isEmpty);
        expect(library(tester).onImportText!('A new text.\n\nMore.'), isNull);
        final texts = container(tester).read(importedTextsProvider);
        expect(texts.single.body, 'A new text.\n\nMore.');
        expect(texts.single.title, 'A new text.');
        expect(texts.single.source, ImportSource.pasted);
        await tester.pump();
      });

      testWidgets('pasting a too long text shows the error in the panel', (
        tester,
      ) async {
        await pumpShell(tester, purchase: _allowed);
        mockClipboard(tester, List.filled(5001, 'word').join(' '));
        await pasteThroughPanel(tester);
        expect(
          find.text('Der Text ist zu lang – höchstens 5.000 Wörter.'),
          findsOneWidget,
        );
        expect(find.byType(ImportPanel), findsOneWidget);
        expect(container(tester).read(importedTextsProvider), isEmpty);
        expect(find.byType(StoryReaderScreen), findsNothing);
        expect(tester.takeException(), isNull);
      });

      testWidgets('pasting a text adds it and opens it in the reader', (
        tester,
      ) async {
        await pumpShell(tester, purchase: _allowed);
        mockClipboard(tester, 'A pasted text.\n\nIts second paragraph.');
        await pasteThroughPanel(tester);
        final text = container(tester).read(importedTextsProvider).single;
        expect(text.body, 'A pasted text.\n\nIts second paragraph.');
        expect(find.byType(ImportPanel), findsNothing);
        final reader = tester.widget<StoryReaderScreen>(
          find.byType(StoryReaderScreen),
        );
        expect(reader.story.id, text.id);
        expect(reader.text.paragraphs, [
          'A pasted text.',
          'Its second paragraph.',
        ]);
        expect(tester.takeException(), isNull);
      });

      for (final own in [false, true]) {
        testWidgets(
          '${own ? 'own text' : 'story'} progress is saved only while the '
          'learning language is unchanged',
          (tester) async {
            var language = 'en';
            await pumpShell(
              tester,
              purchase: _allowed,
              language: () => language,
            );
            final id = own ? _own.id : _story.id;
            if (own) {
              library(tester).onOpenImported!(_own);
            } else {
              library(tester).onOpenStory(_story);
            }
            await settleRoute(tester);
            final report = tester
                .widget<StoryReaderScreen>(find.byType(StoryReaderScreen))
                .onProgress!;
            final scope = container(tester);
            // The shell is covered by the reader route and its provider
            // subscriptions are paused; this listener keeps the language
            // provider recomputing as it would for a visible screen.
            final active = scope.listen(
              selectedContentLanguageProvider,
              (_, _) {},
            );
            addTearDown(active.close);
            expect(scope.read(readingProgressProvider)[id], isNull);

            report(0.4);
            await tester.pump();
            expect(scope.read(readingProgressProvider)[id]!.fraction, 0.4);

            language = 'pt-BR';
            scope.invalidate(selectedContentLanguageProvider);
            await settleRoute(tester);
            expect(
              scope.read(selectedContentLanguageProvider).asData?.value,
              'pt-BR',
            );
            report(0.8);
            await tester.pump();
            expect(scope.read(readingProgressProvider)[id]!.fraction, 0.4);

            // Back on the language the text was opened in, it is saved again.
            language = 'en';
            scope.invalidate(selectedContentLanguageProvider);
            await settleRoute(tester);
            report(0.8);
            await tester.pump();
            expect(scope.read(readingProgressProvider)[id]!.fraction, 0.8);
            expect(tester.takeException(), isNull);
          },
        );
      }
    });
  }
}
