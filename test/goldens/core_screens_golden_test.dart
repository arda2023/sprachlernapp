// Golden tests for the four core screens, light and dark.
//
// What these images protect: layout, spacing and colors. What they do NOT
// protect: typography. The Google Fonts are not bundled for tests and runtime
// fetching is switched off, so every text is drawn in the test fallback font
// (plain boxes instead of letters). A changed typeface, weight or letter shape
// does not show up here; a changed text length or font size usually does.
//
// macOS only: rendering differs slightly between platforms, so the images
// were created on macOS and every test is skipped elsewhere.
//
// Update after an intended visual change (same command on macOS Terminal;
// on Windows the tests are skipped):
//   flutter test --update-goldens test/goldens/
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/models/sample_content.dart';
import 'package:sprachapp/screens/decks/deck_practice_screen.dart';
import 'package:sprachapp/screens/home/home_screen.dart';
import 'package:sprachapp/screens/stories/story_reader_screen.dart';
import 'package:sprachapp/screens/words/word_list_screen.dart';
import 'package:sprachapp/theme/app_theme.dart';

import '../fixtures/deck_repositories.dart';
import '../fixtures/practice_session.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  final screens = <String, Widget Function()>{
    'home': () => Scaffold(
      body: HomeScreen(
        onOpenStory: (_) {},
        onBrowseStories: () {},
        onOpenDeck: (_) {},
        onBrowseDecks: () {},
        onSetGoal: (_) {},
        onSettings: () {},
      ),
    ),
    // One active card of the fixture deck, nothing typed yet.
    'practice': () =>
        const DeckPracticeScreen(deckId: 'deck-0', sessionSize: 5),
    'story_reader': () => StoryReaderScreen(
      story: sampleStories.first,
      text: sampleStoryText(sampleStories.first.id),
    ),
    'word_list': () => Scaffold(body: WordListScreen(clock: () => testNow)),
  };

  for (final MapEntry(key: name, value: build) in screens.entries) {
    for (final brightness in Brightness.values) {
      testWidgets('$name ${brightness.name}', (tester) async {
        // Fixed screen: a 390 x 844 phone at one pixel per point.
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        // The practice card must be new, so that fixture starts without
        // learning states; the other screens show the seeded library.
        final user = TestUser(library: name != 'practice');
        addTearDown(user.close);
        await tester.pumpWidget(
          // testScope fixes the clock (clockProvider) at testNow.
          testScope(
            MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: buildAppTheme(brightness: brightness),
              home: build(),
            ),
            user: user,
            content: name == 'practice' ? WalksOnlyContent() : null,
            library: name != 'practice',
          ),
        );
        // No running animation may be left in the picture.
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        if (name == 'practice') {
          expect(shownPracticeItem(tester).card.form, 'walks');
        }
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('images/${name}_${brightness.name}.png'),
        );
      }, skip: !Platform.isMacOS);
    }
  }
}
