import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/models/home_models.dart';
import 'package:sprachapp/models/sample_content.dart';
import 'package:sprachapp/presentation/providers/reading_providers.dart';
import 'package:sprachapp/screens/stories/story_library_screen.dart';
import 'package:sprachapp/screens/stories/story_reader_screen.dart';
import 'package:sprachapp/screens/stories/widgets/import_panel.dart';
import 'package:sprachapp/theme/app_theme.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  void phone(WidgetTester tester) {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    addTearDown(tester.view.reset);
  }

  group('reading progress', () {
    test('keeps the latest position and remembers a finished story', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final progress = container.read(readingProgressProvider.notifier);

      progress.report('a', 0.4);
      expect(container.read(readingProgressProvider)['a']!.inProgress, isTrue);

      progress.report('a', 1);
      expect(container.read(readingProgressProvider)['a']!.finished, isTrue);

      // Scrolling back up does not "unfinish" it.
      progress.report('a', 0.2);
      final entry = container.read(readingProgressProvider)['a']!;
      expect(entry.fraction, 0.2);
      expect(entry.finished, isTrue);
      expect(entry.inProgress, isFalse);
    });

    test('is stored and loaded again', () async {
      final store = MemoryJsonStore();
      final first = ProviderContainer(
        overrides: [readingStoreProvider.overrideWithValue(store)],
      );
      first.read(readingProgressProvider.notifier).report('story', 0.55);
      await Future<void>.delayed(Duration.zero);
      first.dispose();

      final second = ProviderContainer(
        overrides: [readingStoreProvider.overrideWithValue(store)],
      );
      addTearDown(second.dispose);
      second.read(readingProgressProvider);
      await Future<void>.delayed(Duration.zero);
      expect(second.read(readingProgressProvider)['story']!.fraction, 0.55);
    });
  });

  group('imported texts', () {
    test('title from the first line, paragraphs from blank lines', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final text = container
          .read(importedTextsProvider.notifier)
          .add('How to Make Tea\n\nBoil the water.\nWait.\n\nPour it.');
      expect(text.title, 'How to Make Tea');
      expect(text.paragraphs, [
        'How to Make Tea',
        'Boil the water. Wait.',
        'Pour it.',
      ]);
      expect(container.read(importedTextsProvider), [text]);
    });

    test('refuses empty and over-long texts (5,000 words)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(importedTextsProvider.notifier);
      expect(() => notifier.add('   '), throwsFormatException);
      expect(
        () => notifier.add(List.filled(5001, 'word').join(' ')),
        throwsFormatException,
      );
      expect(container.read(importedTextsProvider), isEmpty);
    });
  });

  testWidgets('import popover pastes the clipboard into "Deine Texte"', (
    tester,
  ) async {
    phone(tester);
    String? imported;
    var done = false;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => call.method == 'Clipboard.getData'
          ? {'text': 'A short transcript about coffee.'}
          : null,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: StoryLibraryScreen(
            stories: sampleStories,
            onOpenStory: (_) {},
            onImportText: (text) {
              imported = text;
              return null;
            },
            onImported: () => done = true,
          ),
        ),
      ),
    );
    expect(find.text('Lies, was dich interessiert'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Eigene Texte importieren'));
    await tester.pumpAndSettle();
    expect(find.byType(ImportPanel), findsOneWidget);
    // Sources that need a picker or backend say so.
    expect(find.bySemanticsLabel('Datei, bald verfügbar'), findsOneWidget);
    expect(find.bySemanticsLabel('YouTube, bald verfügbar'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel(RegExp('^Text einfügen')));
    await tester.pumpAndSettle();
    expect(imported, 'A short transcript about coffee.');
    expect(done, isTrue);
    expect(find.byType(ImportPanel), findsNothing);
  });

  testWidgets('started stories show their progress on the card', (
    tester,
  ) async {
    phone(tester);
    final story = sampleStories.first;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: StoryLibraryScreen(
            stories: sampleStories,
            onOpenStory: (_) {},
            progress: {
              story.id: ReadingEntry(
                fraction: 0.42,
                updatedAt: DateTime(2026, 10, 20),
              ),
            },
          ),
        ),
      ),
    );
    expect(
      find.bySemanticsLabel(RegExp('^Weiterlesen: ${story.title}.*42 Prozent')),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.bySemanticsLabel(RegExp('^${story.title}\\..*42 Prozent gelesen')),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.bySemanticsLabel(RegExp('^${story.title}\\..*42 Prozent gelesen')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the reader reports its position and fills the rail', (
    tester,
  ) async {
    phone(tester);
    final reported = <double>[];
    final story = sampleStories.first;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: StoryReaderScreen(
          story: story,
          text: sampleStoryText(sampleStories.first.id),
          onProgress: reported.add,
        ),
      ),
    );
    expect(find.text('0 %'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -5000));
    await tester.pumpAndSettle();
    expect(find.text('100 %'), findsOneWidget);
    expect(reported.last, 1);
    expect(find.text('Geschafft!'), findsOneWidget);
  });

  testWidgets('the reader opens where the learner stopped', (tester) async {
    phone(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: StoryReaderScreen(
          story: const Story(
            id: 'x',
            title: 'Long',
            topic: 'Reisen',
            level: 'A2',
            readingMinutes: 4,
          ),
          text: sampleStoryText(sampleStories.first.id),
          initialProgress: 0.5,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('50 %'), findsOneWidget);
  });
}
