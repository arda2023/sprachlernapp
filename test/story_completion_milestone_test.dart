import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/domain/editorial_stories.dart';
import 'package:sprachapp/models/home_models.dart';
import 'package:sprachapp/models/story_models.dart';
import 'package:sprachapp/presentation/providers/bundled_stories_provider.dart';
import 'package:sprachapp/presentation/providers/premium_access_provider.dart';
import 'package:sprachapp/screens/stories/story_reader_screen.dart';
import 'package:sprachapp/theme/app_theme.dart';
import 'package:sprachapp/presentation/providers/reading_providers.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  test('completion persists once and leaves imported reading out', () async {
    final store = MemoryJsonStore();
    await store.write({
      'import-1': ReadingEntry(
        fraction: 1,
        updatedAt: DateTime(2026, 11, 14),
        finished: true,
      ).toJson(),
    });
    ProviderContainer open() => ProviderContainer(
      overrides: [readingStoreProvider.overrideWithValue(store)],
    );
    final first = open();
    final notifier = first.read(readingProgressProvider.notifier);
    expect(await notifier.finishStory('first-story'), isTrue);
    expect(await notifier.finishStory('first-story'), isFalse);
    first.dispose();

    final next = open();
    addTearDown(next.dispose);
    final reloaded = next.read(readingProgressProvider.notifier);
    await reloaded.ready;
    expect(next.read(readingProgressProvider)['first-story']?.finished, isTrue);
    expect(await reloaded.finishStory('first-story'), isFalse);
    expect(await reloaded.finishStory('second-story'), isFalse);
    expect(
      next.read(readingProgressProvider)['second-story']?.finished,
      isTrue,
    );
  });

  testWidgets('merely opening the reader never awards the story milestone', (
    tester,
  ) async {
    final story = Story(
      id: freeLinglossaStoryId('en'),
      title: 'Linglossa',
      topic: 'Sprachenlernen',
      level: 'A2',
      readingMinutes: 2,
    );
    final item = BundledStory(
      story,
      StoryText(
        storyId: story.id,
        paragraphs: List.filled(
          8,
          'Every morning she read a few pages and learned another word.',
        ),
      ),
      'en',
    );
    var completions = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bundledStoriesProvider.overrideWith((_) async => [item]),
          premiumContentAccessProvider.overrideWithValue(true),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => StoryReaderScreen.open(
                context,
                story,
                initialProgress: 0.975,
                onFinished: () async {
                  completions++;
                  return true;
                },
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(completions, 0);
    expect(find.text('Deine erste Story!'), findsNothing);
    final done = find.text('Fertig');
    await tester.ensureVisible(done);
    await tester.pumpAndSettle();
    expect(completions, 0);
    await tester.tap(done);
    await tester.pumpAndSettle();
    expect(completions, 1);
    expect(find.text('Deine erste Story!'), findsOneWidget);
    await tester.ensureVisible(done);
    await tester.pumpAndSettle();
    await tester.tap(done);
    await tester.pumpAndSettle();
    expect(completions, 1);
    expect(find.text('Open'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
