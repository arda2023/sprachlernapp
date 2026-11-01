import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/models/home_models.dart';
import 'package:sprachapp/presentation/deck_visuals.dart';
import 'package:sprachapp/presentation/providers/deck_providers.dart';
import 'package:sprachapp/screens/decks/deck_details_screen.dart';
import 'package:sprachapp/screens/decks/deck_library_screen.dart';
import 'package:sprachapp/screens/home/widgets/deck_tile.dart';
import 'package:sprachapp/screens/home/widgets/home_deck_row.dart';
import 'package:sprachapp/screens/onboarding/paywall_screen.dart';
import 'package:sprachapp/theme/app_theme.dart';
import 'package:sprachapp/widgets/deck_premium_badge.dart';
import 'package:sprachapp/widgets/section_heading.dart';

import '../fixtures/deck_repositories.dart';

// Real English pack IDs: access never depends on a translated display name.
const _freeId = '4630a4856f603afdad2f24776298c19a';
const _travelId = '78f49ffc8943ea9e914b8195e1f6135f';

Deck _deck({bool free = false, bool active = false}) => Deck(
  id: free ? _freeId : _travelId,
  name: free ? 'Allgemeine Sprache' : 'Reisen',
  description: 'Wörter und Sätze für deinen Alltag.',
  icon: deckTopicIcon(free ? 'allgemeine-sprache' : 'reisen'),
  difficulty: DeckDifficulty.beginner,
  totalWords: 100,
  seenWords: 20,
  masteredWords: 5,
  isActive: active,
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> show(
    WidgetTester tester,
    Widget child, {
    bool premium = false,
    List<Deck>? decks,
    Brightness brightness = Brightness.dark,
  }) async {
    await tester.pumpWidget(
      testScope(
        MaterialApp(
          theme: buildAppTheme(brightness: brightness),
          home: child,
        ),
        premium: premium,
        overrides: [
          if (decks != null) decksProvider.overrideWith((ref) async => decks),
        ],
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Library has no count labels and locks every topic deck', (
    tester,
  ) async {
    final general = _deck(free: true, active: true);
    final travel = _deck(active: true);
    Deck? opened;
    await show(
      tester,
      Scaffold(body: DeckLibraryScreen(onOpenDeck: (deck) => opened = deck)),
      decks: [general, travel],
    );

    expect(find.text('1 aktiv · 2 Stapel'), findsNothing);
    expect(find.text('2 aktiv · 2 Stapel'), findsNothing);
    final headings = tester.widgetList<SectionHeading>(
      find.byType(SectionHeading),
    );
    expect(headings.map((heading) => heading.title), [
      'Aktiv',
      'Weitere Stapel',
    ]);
    expect(headings.every((heading) => heading.trailing == null), isTrue);
    expect(find.byType(DeckPremiumBadge), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('^Reisen,.*Premium erforderlich')),
      findsOneWidget,
    );
    await tester.tap(find.text('Reisen'));
    expect(opened, same(travel));
  });

  testWidgets('Home and library keep the same topic icon while locked', (
    tester,
  ) async {
    final deck = _deck();
    await show(
      tester,
      Scaffold(
        body: Column(
          children: [
            HomeDeckRow(deck: deck, onTap: () {}),
            DeckTile(deck: deck, onTap: () {}),
          ],
        ),
      ),
    );
    expect(find.byIcon(deckTopicIcon('reisen')), findsNWidgets(2));
    expect(find.byType(DeckPremiumBadge), findsNWidgets(2));
  });

  testWidgets('Locked details offer Premium with no practice or activation', (
    tester,
  ) async {
    await show(
      tester,
      const DeckDetailsScreen(deckId: _travelId),
      decks: [_deck(active: true)],
    );
    expect(find.byIcon(deckTopicIcon('reisen')), findsOneWidget);
    expect(find.text('Mit Premium freischalten'), findsOneWidget);
    expect(
      find.text('Lerne mit diesem und allen weiteren Themenstapeln.'),
      findsNothing,
    );
    expect(find.text('Mit diesem Stapel üben'), findsNothing);
    expect(find.text('Stapel aktivieren'), findsNothing);
    expect(find.byType(CupertinoSwitch), findsNothing);
    expect(find.text('Stapel-Revue'), findsNothing);

    await tester.ensureVisible(find.text('Premium holen'));
    await tester.tap(find.text('Premium holen'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(PaywallScreen), findsOneWidget);
    expect(
      tester.widget<PaywallScreen>(find.byType(PaywallScreen)).plan.interest,
      'Reisen',
    );
  });

  for (final premium in [false, true]) {
    testWidgets(
      '${premium ? 'Premium' : 'Free general'} details keep all learning actions',
      (tester) async {
        final deck = _deck(free: !premium);
        await show(
          tester,
          DeckDetailsScreen(deckId: deck.id),
          premium: premium,
          decks: [deck],
        );
        expect(find.text('Mit diesem Stapel üben'), findsOneWidget);
        expect(find.text('Stapel aktivieren'), findsOneWidget);
        expect(find.byType(CupertinoSwitch), findsOneWidget);
        expect(find.text('Stapel-Revue'), findsOneWidget);
        expect(find.text('Premium holen'), findsNothing);
      },
    );
  }

  void expectMastheadAlignment(WidgetTester tester, double width) {
    final gauge = tester.getRect(find.byType(DeckGauge));
    final difficulty = tester.getRect(
      find.byKey(const ValueKey('deck-difficulty-chip')),
    );
    expect(gauge.width, 84);
    expect(gauge.left, closeTo(20, 0.1));
    expect(difficulty.right, closeTo(width - 20, 0.1));
    expect(difficulty.left, greaterThanOrEqualTo(gauge.right + 16 - 0.1));
    expect(difficulty.center.dy, closeTo(gauge.center.dy, 0.1));
  }

  for (final brightness in Brightness.values) {
    testWidgets(
      'Difficulty aligns right and centers on ${brightness.name} details',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await show(
          tester,
          const DeckDetailsScreen(deckId: _travelId),
          decks: [_deck()],
          brightness: brightness,
        );
        expectMastheadAlignment(tester, 390);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Locked details fit narrow ${brightness.name} at 2x text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 812);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await show(
        tester,
        const DeckDetailsScreen(deckId: _travelId),
        decks: [_deck()],
        brightness: brightness,
      );
      expectMastheadAlignment(tester, 320);
      await tester.scrollUntilVisible(find.text('Premium holen'), 200);
      expect(tester.takeException(), isNull);
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    });
  }
}
