import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/models/sample_content.dart';
import 'package:sprachapp/screens/decks/deck_practice_screen.dart';
import 'package:sprachapp/screens/home/home_screen.dart';
import 'package:sprachapp/screens/onboarding/paywall_screen.dart';
import 'package:sprachapp/screens/settings/settings_screen.dart';
import 'package:sprachapp/screens/stories/story_reader_screen.dart';
import 'package:sprachapp/screens/words/word_list_screen.dart';

import '../fixtures/accessibility_fonts.dart';
import '../fixtures/deck_repositories.dart';
import '../fixtures/practice_session.dart';
import 'accessibility_test_app.dart';

enum _Screen { home, practice, reader, words, settings, paywall }

Widget _screen(_Screen screen) => switch (screen) {
  _Screen.home => Scaffold(
    body: HomeScreen(
      onOpenStory: (_) {},
      onBrowseStories: () {},
      onOpenDeck: (_) {},
      onBrowseDecks: () {},
      onSetGoal: (_) {},
      onSettings: () {},
    ),
  ),
  _Screen.practice => const DeckPracticeScreen(
    deckId: 'deck-0',
    sessionSize: 5,
  ),
  _Screen.reader => StoryReaderScreen(
    story: sampleStories.first,
    text: sampleStoryText(sampleStories.first.id),
  ),
  _Screen.words => Scaffold(body: WordListScreen(clock: () => testNow)),
  _Screen.settings => const SettingsScreen(),
  _Screen.paywall => PaywallScreen(
    plan: (interest: 'Reisen', dailyGoal: 10),
    onContinue: () {},
  ),
};

/// Checks every vertical viewport, including controls below the first fold.
/// Inline editor scrollables are deliberately excluded: the practice tests
/// exercise those through typing and text scaling instead of moving the cursor.
Future<void> _checkScrolledContent(WidgetTester tester, _Screen screen) async {
  await expectAccessible(tester);
  if (screen == _Screen.practice) {
    await tester.tap(find.bySemanticsLabel('Mia, Übersetzung anzeigen'));
    await tester.pumpAndSettle();
    await expectAccessible(tester);
    await tester.tapAt(const Offset(4, 200));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('practice-input')),
      'walks',
    );
    await tester.pumpAndSettle();
    await expectAccessible(tester);
    return;
  }
  if (screen == _Screen.home) {
    await tester.tap(
      find.bySemanticsLabel(RegExp('^Im Aufbau:.*Erklärung öffnen')),
    );
    await tester.pumpAndSettle();
    await expectAccessible(tester);
    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();
  }
  if (screen == _Screen.words) {
    await tester.tap(find.bySemanticsLabel(RegExp('^Mehr zu ')).first);
    await tester.pumpAndSettle();
    await expectAccessible(tester);
    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();
  }
  final scrollable = find.byWidgetPredicate(
    (widget) =>
        widget is Scrollable &&
        axisDirectionToAxis(widget.axisDirection) == Axis.vertical,
  );
  expect(scrollable, findsWidgets);
  final state = tester.state<ScrollableState>(scrollable.first);
  for (var page = 0; page < 30; page++) {
    final position = state.position;
    if (position.pixels >= position.maxScrollExtent - 0.5) return;
    position.jumpTo(
      math.min(
        position.maxScrollExtent,
        position.pixels + position.viewportDimension * 0.7,
      ),
    );
    await tester.pumpAndSettle();
    await expectAccessible(tester);
  }
  fail('Fixture content did not finish scrolling');
}

void main() {
  setUpAll(loadAccessibilityFonts);

  for (final screen in _Screen.values) {
    for (final brightness in Brightness.values) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          '${screen.name}: ${brightness.name}, text $scale, all guidelines',
          (tester) async {
            usePhoneViewport(tester);
            final semantics = tester.ensureSemantics();
            final user = TestUser(library: screen != _Screen.practice);
            try {
              await tester.pumpWidget(
                testScope(
                  accessibilityTestApp(
                    home: _screen(screen),
                    brightness: brightness,
                    textScale: scale,
                  ),
                  user: user,
                  content: screen == _Screen.practice
                      ? WalksOnlyContent()
                      : null,
                  library: screen != _Screen.practice,
                  overrides: accessibilityOverrides(),
                ),
              );
              await tester.pumpAndSettle();
              await _checkScrolledContent(tester, screen);
            } finally {
              await tester.pumpWidget(const SizedBox.shrink());
              semantics.dispose();
              await user.close();
            }
          },
        );
      }
    }
  }

  for (final brightness in Brightness.values) {
    testWidgets('paywall without trial: ${brightness.name}, large text', (
      tester,
    ) async {
      usePhoneViewport(tester);
      final semantics = tester.ensureSemantics();
      final user = TestUser(library: true);
      try {
        await tester.pumpWidget(
          testScope(
            accessibilityTestApp(
              home: _screen(_Screen.paywall),
              brightness: brightness,
              textScale: 2,
            ),
            user: user,
            library: true,
            overrides: accessibilityOverrides(trialDays: 0),
          ),
        );
        await tester.pumpAndSettle();
        await _checkScrolledContent(tester, _Screen.paywall);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        semantics.dispose();
        await user.close();
      }
    });
  }
}
