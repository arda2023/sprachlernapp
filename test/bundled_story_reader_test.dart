import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/presentation/providers/bundled_stories_provider.dart';
import 'package:sprachapp/screens/stories/story_reader_screen.dart';
import 'package:sprachapp/theme/app_theme.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  for (final lang in ['en', 'es', 'it', 'nb', 'pt-BR']) {
    testWidgets('$lang bundled story opens through the library route', (tester) async {
      final stories = BundledStory.decode(
        File('assets/content/$lang/stories.json').readAsStringSync(), lang);
      final item = stories.firstWhere((s) => s.story.id.endsWith('everyday_01'));
      await tester.pumpWidget(ProviderScope(
        overrides: [bundledStoriesProvider.overrideWith((ref) async => stories)],
        child: MaterialApp(theme: buildAppTheme(), home: Builder(builder: (context) =>
          TextButton(onPressed: () => StoryReaderScreen.open(context, item.story),
            child: const Text('Open')))),
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final reader = tester.widget<StoryReaderScreen>(find.byType(StoryReaderScreen));
      expect(reader.sourceLanguage, lang);
      expect(reader.text.paragraphs, item.text.paragraphs);
      expect(reader.document, isNull);
      expect(reader.lookup('test').translation, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
