import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/domain/editorial_stories.dart';
import 'package:sprachapp/domain/sentences.dart';
import 'package:sprachapp/presentation/providers/bundled_stories_provider.dart';
import 'package:sprachapp/presentation/providers/premium_access_provider.dart';
import 'package:sprachapp/screens/stories/story_reader_screen.dart';
import 'package:sprachapp/theme/app_theme.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  for (final lang in ['en', 'es', 'it', 'nb', 'pt-BR']) {
    testWidgets('$lang bundled story opens through the library route', (
      tester,
    ) async {
      final stories = BundledStory.decode(
        File('assets/content/$lang/stories.json').readAsStringSync(),
        lang,
      );
      final item = stories.firstWhere(
        (s) => s.story.id.endsWith('everyday_01'),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bundledStoriesProvider.overrideWith((ref) async => stories),
            premiumContentAccessProvider.overrideWithValue(true),
          ],
          child: MaterialApp(
            theme: buildAppTheme(),
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () => StoryReaderScreen.open(context, item.story),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final reader = tester.widget<StoryReaderScreen>(
        find.byType(StoryReaderScreen),
      );
      expect(reader.sourceLanguage, lang);
      expect(reader.text.paragraphs, item.text.paragraphs);
      expect(reader.document, isNull);
      expect(reader.lookup('test').translation, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  for (final (lang, word) in [
    ('en', 'day'),
    ('es', 'día'),
    ('it', 'giornata'),
    ('nb', 'dagen'),
    ('pt-BR', 'dia'),
  ]) {
    testWidgets('$lang only Linglossa opens without Premium', (tester) async {
      final stories = BundledStory.decode(
        File('assets/content/$lang/learning-stories.json').readAsStringSync(),
        lang,
      );
      final free = stories.singleWhere((item) => isFreeStoryId(item.story.id));
      final paid = stories.firstWhere((item) => !isFreeStoryId(item.story.id));
      expect(free.story.id, freeLinglossaStoryId(lang));
      expect(stories, hasLength(4));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bundledStoriesProvider.overrideWith((ref) async => stories),
            premiumContentAccessProvider.overrideWithValue(false),
          ],
          child: MaterialApp(
            theme: buildAppTheme(),
            home: Builder(
              builder: (context) => Scaffold(
                body: Column(
                  children: [
                    TextButton(
                      onPressed: () =>
                          StoryReaderScreen.open(context, free.story),
                      child: const Text('Gratis'),
                    ),
                    TextButton(
                      onPressed: () =>
                          StoryReaderScreen.open(context, paid.story),
                      child: const Text('Premium'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Gratis'));
      await tester.pumpAndSettle();
      final reader = tester.widget<StoryReaderScreen>(
        find.byType(StoryReaderScreen),
      );
      expect(reader.lookup(word).translation, 'Tag');
      expect(reader.sources, isNotEmpty);
      for (final paragraph in reader.text.paragraphs) {
        for (final segment in splitSentences(paragraph)) {
          expect(
            reader.translate(paragraph.substring(segment.start, segment.end)),
            isNotEmpty,
          );
        }
      }
      Navigator.of(tester.element(find.byType(StoryReaderScreen))).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Premium'));
      await tester.pumpAndSettle();
      expect(find.byType(StoryReaderScreen), findsNothing);
      expect(find.text('Diese Story kannst du mit Premium lesen.'), findsOne);
    });
  }
}
