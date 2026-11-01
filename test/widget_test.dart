import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sprachapp/data/runtime_translation_client.dart';
import 'package:sprachapp/presentation/providers/runtime_translation_provider.dart';
import 'package:sprachapp/presentation/audio/device_speech_playback.dart';
import 'fixtures/offline_translation.dart';
import 'package:sprachapp/models/speech_playback.dart';
import 'package:sprachapp/presentation/providers/offline_translation_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'fixtures/deck_repositories.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:sprachapp/domain/answer_check.dart';
import 'package:sprachapp/domain/emphasis.dart';
import 'package:sprachapp/domain/leitner.dart';
import 'package:sprachapp/domain/sentences.dart';
import 'package:sprachapp/domain/word_form.dart';
import 'package:sprachapp/main.dart';
import 'package:sprachapp/models/exercise_models.dart';
import 'package:sprachapp/models/grammar_models.dart';
import 'package:sprachapp/models/practice_models.dart';
import 'package:sprachapp/models/reading_history.dart';
import 'package:sprachapp/screens/content/content_dashboard_screen.dart';
import 'package:sprachapp/screens/content/widgets/text_exercise_shelf.dart';
import 'package:sprachapp/screens/content/text_exercise_screen.dart';
import 'package:sprachapp/screens/content/text_library_screen.dart';
import 'package:sprachapp/screens/content/widgets/exercise_choice_sheet.dart';
import 'package:sprachapp/widgets/more_button.dart';
import 'package:sprachapp/screens/home/widgets/story_carousel.dart';
import 'package:sprachapp/models/home_models.dart';
import 'package:sprachapp/models/news_models.dart';
import 'package:sprachapp/presentation/providers/premium_access_provider.dart';
import 'package:sprachapp/models/sample_content.dart';
import 'package:sprachapp/models/story_models.dart';
import 'package:sprachapp/models/playback_clock.dart';
import 'package:sprachapp/models/word_list_models.dart';

import 'fixtures/word_list_store.dart';

import 'package:sprachapp/presentation/providers/learning_providers.dart';
import 'package:sprachapp/screens/decks/deck_details_screen.dart';
import 'package:sprachapp/screens/decks/deck_library_screen.dart';
import 'package:sprachapp/screens/grammar/grammar_rule_detail_screen.dart';
import 'package:sprachapp/screens/grammar/grammar_rules_screen.dart';
import 'package:sprachapp/screens/practice/choice_exercise_screen.dart';
import 'package:sprachapp/screens/practice/practice_library_screen.dart';
import 'package:sprachapp/screens/home/widgets/deck_tile.dart';
import 'package:sprachapp/domain/streak.dart';
import 'package:sprachapp/screens/home/widgets/home_deck_row.dart';
import 'package:sprachapp/screens/home/widgets/progress_tiles.dart';
import 'package:sprachapp/screens/home/widgets/goal_panel.dart';
import 'package:sprachapp/screens/home/widgets/home_header.dart';
import 'package:sprachapp/screens/home/widgets/streak_calendar.dart';
import 'package:sprachapp/screens/home/widgets/streak_strip.dart';
import 'package:sprachapp/widgets/count_format.dart';
import 'package:sprachapp/widgets/svg_glyph.dart';
import 'package:sprachapp/screens/stories/story_library_screen.dart';
import 'package:sprachapp/screens/stories/story_reader_screen.dart';
import 'package:sprachapp/screens/stories/widgets/narration_panel.dart';
import 'package:sprachapp/screens/stories/widgets/news_carousel.dart';
import 'package:sprachapp/screens/stories/widgets/sentence_popover.dart';
import 'package:sprachapp/screens/stories/widgets/word_popover.dart';
import 'package:sprachapp/presentation/providers/reading_providers.dart';
import 'package:sprachapp/screens/words/widgets/memory_level_legend_sheet.dart';
import 'package:sprachapp/screens/words/widgets/word_details_page.dart';
import 'package:sprachapp/screens/words/widgets/word_list_item.dart';
import 'package:sprachapp/screens/words/word_list_screen.dart';
import 'package:sprachapp/theme/app_theme.dart';
import 'package:sprachapp/widgets/success_feedback_card.dart';
import 'package:sprachapp/widgets/app_bottom_bar.dart';
import 'package:sprachapp/widgets/difficulty_bolts.dart';
import 'package:sprachapp/widgets/progress_ring.dart';
import 'package:sprachapp/widgets/reading_toolbar.dart';
import 'package:sprachapp/widgets/runtime_translation_sheet.dart';
import 'package:sprachapp/widgets/section_heading.dart';
import 'package:sprachapp/widgets/speaker_icon.dart';

void main() {
  setUp(
    () =>
        TestWidgetsFlutterBinding.ensureInitialized()
                .platformDispatcher
                .platformBrightnessTestValue =
            Brightness.dark,
  );
  tearDown(
    () => TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher
        .clearPlatformBrightnessTestValue(),
  );
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> mockNativeSpeech(WidgetTester tester) async {
    await DeviceSpeechPlayback.resetForTest();
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('flutter_tts'), (call) async => call.method == 'getVoices'
        ? [{'identifier': 'test.en', 'locale': 'en-US', 'gender': 'female', 'quality': 'default'}] : 1);
    addTearDown(() async {
      debugDefaultTargetPlatformOverride = null;
      await tester.runAsync(DeviceSpeechPlayback.resetForTest);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('flutter_tts'), null);
    });
  }
  Future<void> completeSpeech() async {
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
      'flutter_tts', const StandardMethodCodec().encodeMethodCall(const MethodCall('speak.onComplete')), (_) {});
  }

  Future<void> scrollHomeTo(WidgetTester tester, Finder target) =>
      tester.scrollUntilVisible(
        target,
        200,
        scrollable: find.byType(Scrollable).first,
      );

  Future<void> openStoriesTab(WidgetTester tester) async {
    await tester.tap(
      find.descendant(
        of: find.byType(AppBottomBar),
        matching: find.text('Stories'),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('HomeScreen renders every section', (tester) async {
    await tester.pumpWidget(testScope(const SprachApp(), library: true));
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel('Zielsprache: Englisch. Sprache wählen'),
      findsOneWidget,
    );
    expect(find.byType(GoalBadge), findsOneWidget);
    expect(find.byType(StreakStrip), findsOneWidget);
    expect(find.byType(ProgressTiles), findsOneWidget);
    // The week box leads, the statistics follow.
    expect(
      tester.getTopLeft(find.byType(StreakStrip)).dy,
      lessThan(tester.getTopLeft(find.byType(ProgressTiles)).dy),
    );
    await scrollHomeTo(tester, find.text('Mehr entdecken'));
    expect(find.text('Stories'), findsWidgets);
    expect(find.text('Mehr entdecken'), findsOneWidget);
    final reisen = find.bySemanticsLabel(
      RegExp('^Reisen & Unterwegs, .*Schwierigkeit Einsteiger'),
    );
    await scrollHomeTo(tester, reisen);
    expect(find.text('Aktive Stapel'), findsOneWidget);
    expect(reisen, findsOneWidget);
    // Home's deck rows carry the progress gauge around the icon, bolts
    // instead of the level name, and stay neutral (not orange).
    expect(
      find.descendant(
        of: find.byType(HomeDeckRow),
        matching: find.byType(ProgressRing),
      ),
      findsWidgets,
    );
    expect(
      find.descendant(
        of: find.byType(HomeDeckRow),
        matching: find.byType(DifficultyBolts),
      ),
      findsWidgets,
    );
    expect(
      find.bySemanticsLabel('Lernen, Tagesziel 0 von 10 Wörtern geübt'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Custom-labelled controls stay activatable for VoiceOver', (
    tester,
  ) async {
    await tester.pumpWidget(testScope(const SprachApp(), library: true));
    await tester.pumpAndSettle();
    void expectButton(String label) => expect(
      tester.getSemantics(find.bySemanticsLabel(label)),
      isSemantics(isButton: true, hasTapAction: true),
      reason: label,
    );
    for (final label in [
      'Lernen, Tagesziel 0 von 10 Wörtern geübt',
      'Einstellungen',
    ]) {
      expectButton(label);
    }
    expect(find.bySemanticsLabel('Profil'), findsNothing);
    for (final pattern in [
      '^Tagesziel: ',
      '^Streak: ',
      '^Streak .*Kalender öffnen',
    ]) {
      expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp(pattern))),
        isSemantics(isButton: true, hasTapAction: true),
        reason: pattern,
      );
    }
    const story =
        'The Last Train to Seville. Reisen, 4 Minuten Lesezeit, Niveau A2';
    await scrollHomeTo(tester, find.bySemanticsLabel(story));
    expectButton(story);
    final reisen = find.bySemanticsLabel(
      RegExp('^Reisen & Unterwegs, .*Schwierigkeit Einsteiger'),
    );
    await scrollHomeTo(tester, reisen);
    expect(
      tester.getSemantics(reisen),
      isSemantics(isButton: true, hasTapAction: true),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Home')),
      isSemantics(isButton: true, isSelected: true, hasTapAction: true),
    );
  });

  testWidgets('Tappable controls meet the 44pt minimum', (tester) async {
    await tester.pumpWidget(testScope(const SprachApp(), library: true));
    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
  });

  testWidgets('Layout survives large Dynamic Type', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(testScope(const SprachApp(), library: true));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Progress tiles explain themselves in a sheet', (tester) async {
    await tester.pumpWidget(testScope(const SprachApp(), library: true));
    await tester.pumpAndSettle();
    for (final title in ['Im Aufbau', 'Gemeistert', 'Wörter geübt']) {
      expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp('^$title: '))),
        isSemantics(isButton: true, hasTapAction: true),
        reason: title,
      );
    }
    // Each tile opens a popover pointing at it; all three have one size.
    final sizes = <Size>[];
    for (final title in ['Im Aufbau', 'Gemeistert', 'Wörter geübt']) {
      await tester.tap(find.bySemanticsLabel(RegExp('^$title: ')));
      await tester.pumpAndSettle();
      final popover = find.byType(SingleChildScrollView).last;
      sizes.add(tester.getSize(popover));
      // The tile names the measure; the popover leads with the count.
      expect(
        find.descendant(of: popover, matching: find.textContaining(' von ')),
        findsWidgets,
      );
      expect(
        find.descendant(of: popover, matching: find.text(title)),
        findsNothing,
      );
      await tester.tapAt(const Offset(4, 4)); // outside closes it
      await tester.pumpAndSettle();
    }
    expect(sizes.toSet(), hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Flame opens the streak calendar with days and week stars', (
    tester,
  ) async {
    await tester.pumpWidget(testScope(const SprachApp(), library: true));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(RegExp('^Streak: ')));
    await tester.pumpAndSettle();
    expect(find.byType(StreakCalendar), findsOneWidget);
    expect(find.text('Aktueller Streak'), findsOneWidget);
    expect(find.text('Wochensterne'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('German thousands separator', () {
    expect(formatCountDe(3000), '3.000');
    expect(formatCountDe(180), '180');
    expect(formatCountDe(1234567), '1.234.567');
  });

  testWidgets('Notched bar docks a neutral practice button with goal ring', (
    tester,
  ) async {
    await tester.pumpWidget(testScope(const SprachApp(), library: true));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(PracticeButton),
        matching: find.byIcon(CupertinoIcons.flame_fill),
      ),
      findsNothing,
    );

    final bar = tester.widget<BottomAppBar>(find.byType(BottomAppBar));
    expect(bar.shape, isA<CircularNotchedRectangle>());
    expect(bar.elevation, 0);
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(
      scaffold.floatingActionButtonLocation,
      FloatingActionButtonLocation.centerDocked,
    );

    final fab = tester.widget<FloatingActionButton>(
      find.byType(FloatingActionButton),
    );
    expect(fab.backgroundColor, AppColors.raisedInk);
    expect(fab.elevation, 0);
    // Rises above the bar.
    expect(
      tester.getRect(find.byType(PracticeButton)).top,
      lessThan(tester.getRect(find.byType(BottomAppBar)).top),
    );

    final ring = tester.widget<ProgressRing>(
      find.descendant(
        of: find.byType(PracticeButton),
        matching: find.byType(ProgressRing),
      ),
    );
    expect(ring.color, AppColors.active);
    expect(ring.gapDegrees, greaterThan(0)); // gauge open at the bottom
    expect(ring.fraction, 0);

    final tabs = find.byType(AppBottomBar);
    expect(find.descendant(of: tabs, matching: find.text('Lernen')), findsOne);
    expect(find.descendant(of: tabs, matching: find.text('Inhalte')), findsOne);
    expect(
      find.descendant(of: tabs, matching: find.text('Profil')),
      findsNothing,
    );
  });

  testWidgets('Streak bar: checks, a crossed missed day, then the star', (
    tester,
  ) async {
    final now = DateTime(2026, 10, 20, 12);
    Future<void> pumpStrip(List<DateTime> days) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: buildAppTheme(),
            home: Scaffold(
              body: StreakStrip(
                summary: summarizeStreak(days, now),
                calendar: (_) => const SizedBox(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Finder glyph(SvgGlyph g) => find.descendant(
      of: find.byType(StreakStrip),
      matching: find.byWidgetPredicate((w) => w is GlyphIcon && w.glyph == g),
    );

    // Four days in a row, today included: open orange star, no plain hint.
    await pumpStrip([for (var i = 0; i < 4; i++) DateTime(2026, 10, 20 - i)]);
    expect(glyph(AppGlyphs.check), findsNWidgets(4));
    expect(glyph(AppGlyphs.cross), findsNothing);
    expect(glyph(AppGlyphs.starOutline), findsOneWidget);
    expect(find.textContaining('Noch'), findsNothing);
    expect(find.textContaining('Wochenstern'), findsOneWidget);

    // Three days, then two days missed: the cross stays until next practice.
    await pumpStrip([for (var i = 3; i < 6; i++) DateTime(2026, 10, 20 - i)]);
    expect(glyph(AppGlyphs.check), findsNWidgets(3));
    expect(glyph(AppGlyphs.cross), findsOneWidget);
    expect(find.textContaining('Neuer Anlauf'), findsOneWidget);

    // Seven days: the star turns solid white inside the pill.
    await pumpStrip([for (var i = 0; i < 7; i++) DateTime(2026, 10, 20 - i)]);
    expect(glyph(AppGlyphs.starSolid), findsOneWidget);
    expect(glyph(AppGlyphs.starOutline), findsNothing);
    expect(find.textContaining('geholt'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Gear changes the daily goal everywhere', (tester) async {
    await tester.pumpWidget(testScope(const SprachApp(), library: true));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(RegExp('^Tagesziel: ')));
    await tester.pumpAndSettle();
    expect(find.byType(GoalPanel), findsOneWidget);
    expect(find.textContaining('Du hast heute'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('20 Wörter pro Tag'));
    await tester.pumpAndSettle();
    expect(find.text('0/20'), findsOneWidget);
    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel(
        'Tagesziel: 0 von 20 Wörtern geübt. Details öffnen',
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Lernen, Tagesziel 0 von 20 Wörtern geübt'),
      findsOneWidget,
    );
  });

  /// Home → "Mehr ansehen" → the deck library, scrolled to [deck].
  Future<void> openDeckLibraryAt(WidgetTester tester, String deck) async {
    await tester.pumpWidget(testScope(const SprachApp(), library: true));
    await tester.pumpAndSettle();
    await scrollHomeTo(tester, find.text('Mehr ansehen'));
    // Clear of the notched bar, also at large Dynamic Type.
    await tester.ensureVisible(find.text('Mehr ansehen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mehr ansehen'));
    await tester.pumpAndSettle();
    expect(find.byType(DeckLibraryScreen), findsOneWidget);
    final tile = find.bySemanticsLabel(RegExp('^$deck,'));
    await tester.scrollUntilVisible(
      tile,
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
  }

  testWidgets('Deck tiles show ring, bolts and active state', (tester) async {
    await tester.pumpWidget(testScope(const SprachApp(), library: true));
    await tester.pumpAndSettle();
    // Home: active decks only, as plain rows.
    await scrollHomeTo(
      tester,
      find.widgetWithText(HomeDeckRow, 'Alltägliche Konversation'),
    );
    expect(find.widgetWithText(HomeDeckRow, 'Reisen & Unterwegs'), findsOne);
    expect(find.widgetWithText(HomeDeckRow, 'Medizin'), findsNothing);

    BoxDecoration tileBox(String name) =>
        tester
                .widget<Container>(
                  find
                      .descendant(
                        of: find.widgetWithText(DeckTile, name),
                        matching: find.byType(Container),
                      )
                      .first,
                )
                .decoration!
            as BoxDecoration;

    // The library keeps the full tiles.
    await tester.tap(find.text('Mehr ansehen'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.widgetWithText(DeckTile, 'Reisen & Unterwegs'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    // Active decks are filled orange in the library, no outline.
    final active = tileBox('Reisen & Unterwegs');
    expect(active.color, AppPalette(Brightness.dark).popover);
    expect(active.border, isNull);

    // Inactive decks show up in the library.
    await tester.scrollUntilVisible(
      find.bySemanticsLabel(RegExp('^Medizin,')),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    final inactive = tileBox('Medizin');
    expect(inactive.color, AppColors.raisedInk);
    expect(inactive.border, isNull);

    expect(
      find.bySemanticsLabel(
        'Medizin, 60 Prozent geübt, Schwierigkeit Fortgeschritten, 5 Wörter',
      ),
      findsOneWidget,
    );
    // Bolts instead of the level name; word count beside them.
    expect(
      find.descendant(
        of: find.widgetWithText(DeckTile, 'Medizin'),
        matching: find.text('5 Wörter'),
      ),
      findsOneWidget,
    );
    final medizin = find.widgetWithText(DeckTile, 'Medizin');
    // Progress gauge like the Play button: open at the bottom, orange arc.
    final ring = tester.widget<ProgressRing>(
      find.descendant(of: medizin, matching: find.byType(ProgressRing)),
    );
    expect(ring.color, AppColors.active);
    expect(ring.gapDegrees, greaterThan(0));
    expect(ring.fraction, closeTo(0.6, 0.001));
    final bolts = tester
        .widgetList<Icon>(
          find.descendant(
            of: find.descendant(
              of: medizin,
              matching: find.byType(DifficultyBolts),
            ),
            matching: find.byType(Icon),
          ),
        )
        .map((i) => i.color);
    expect(bolts, everyElement(AppColors.textPrimary));
  });

  testWidgets('"Mehr ansehen" opens the deck library', (tester) async {
    await tester.pumpWidget(testScope(const SprachApp(), library: true));
    await tester.pumpAndSettle();
    await scrollHomeTo(tester, find.text('Mehr ansehen'));
    await tester.tap(find.text('Mehr ansehen'));
    await tester.pumpAndSettle();
    expect(find.byType(DeckLibraryScreen), findsOneWidget);
    expect(find.text('2 aktiv · 6 Stapel'), findsNothing);
    expect(find.widgetWithText(SectionHeading, 'Aktiv'), findsOneWidget);
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
  });

  Future<void> openMedizin(WidgetTester tester) async {
    await openDeckLibraryAt(tester, 'Medizin');
    await tester.tap(find.bySemanticsLabel(RegExp('^Medizin,')));
    await tester.pumpAndSettle();
    expect(find.byType(DeckDetailsScreen), findsOneWidget);
  }

  testWidgets('Deck details orient first, then act', (tester) async {
    await openMedizin(tester);
    expect(find.byType(DeckDetailsScreen), findsOneWidget);
    expect(
      find.bySemanticsLabel('3 von 5 Übungen gesehen, 1 Übungen gemeistert'),
      findsOneWidget,
    );
    expect(find.text('Fortgeschritten'), findsOneWidget);
    for (final label in [
      'Mit diesem Stapel üben',
      'Stapel-Revue: Stapel nochmals durchsehen',
      'Deine letzten 3 geübten Formen',
    ]) {
      await tester.scrollUntilVisible(
        find.bySemanticsLabel(label),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel(label)),
        isSemantics(isButton: true, hasTapAction: true),
        reason: label,
      );
    }
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));

    await tester.ensureVisible(find.text('Deine letzten 3 geübten Formen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deine letzten 3 geübten Formen'));
    await tester.pumpAndSettle();
    // The shorter "Stapel aktivieren" row leaves the forms below the fold.
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.text('walks'), findsOneWidget);
    expect(find.text('geht'), findsOneWidget);

    expect(find.text('Stapel-Revue'), findsOneWidget);
    expect(find.text('Mehr davon'), findsNothing);
    // The icon carries the deck's progress gauge (scrolled above by now).
    final gauge = tester.widget<ProgressRing>(
      find.byType(ProgressRing, skipOffstage: false).first,
    );
    expect(gauge.gapDegrees, greaterThan(0));
  });

  testWidgets('"Stapel lernen" toggles the deck on every screen', (
    tester,
  ) async {
    await openMedizin(tester);
    final toggle = tester.widget<CupertinoSwitch>(find.byType(CupertinoSwitch));
    expect(toggle.value, isFalse);
    expect(toggle.activeTrackColor, AppColors.active);
    expect(find.text('Stapel aktivieren'), findsOneWidget);

    await tester.tap(find.byType(CupertinoSwitch));
    await tester.pumpAndSettle();
    expect(
      tester.widget<CupertinoSwitch>(find.byType(CupertinoSwitch)).value,
      isTrue,
    );

    // Library, then Home: once active, the deck is on both.
    await tester.tap(find.bySemanticsLabel('Zurück'));
    await tester.pumpAndSettle();
    const medizinActive =
        'Medizin, 60 Prozent geübt, Schwierigkeit Fortgeschritten, '
        '5 Wörter, aktiv';
    expect(find.bySemanticsLabel(medizinActive), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Zurück'));
    await tester.pumpAndSettle();
    final medizinHome = find.bySemanticsLabel(
      RegExp('^Medizin, .*Fortgeschritten'),
    );
    await scrollHomeTo(tester, medizinHome);
    expect(medizinHome, findsOneWidget);
  });

  testWidgets('Deck details survive large Dynamic Type', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await openMedizin(tester);
    final recent = find.bySemanticsLabel(RegExp('^Deine letzten'));
    await tester.scrollUntilVisible(
      recent,
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.ensureVisible(recent);
    await tester.pumpAndSettle();
    await tester.tap(recent);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home shows the four derived categories and the daily goal', (
    tester,
  ) async {
    await tester.pumpWidget(testScope(const SprachApp(), library: true));
    await tester.pumpAndSettle();
    expect(find.text('0/10'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'Tagesziel: 0 von 10 Wörtern geübt. Details öffnen',
      ),
      findsOneWidget,
    );
  });

  test('Vocabulary categories always sum to the total', () {
    const b = VocabBreakdown(due: 3, building: 5, mastered: 7, unseen: 11);
    expect(b.total, 26);
  });

  testWidgets('Stories tab groups carousels by topic', (tester) async {
    await tester.pumpWidget(testScope(const SprachApp(), library: true));
    await tester.pumpAndSettle();
    await scrollHomeTo(tester, find.text('Mehr entdecken'));
    await tester.tap(find.text('Mehr entdecken'));
    await tester.pumpAndSettle();
    expect(find.byType(StoryLibraryScreen), findsOneWidget);
    expect(
      find.text('Weiterlesen'),
      findsNothing,
    ); // No invented persisted reading progress.
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await tester.scrollUntilVisible(
      find.widgetWithText(SectionHeading, 'Reisen'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(StoryLibraryScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.widgetWithText(SectionHeading, 'Reisen'), findsOneWidget);
    // Only the three real pack stories; no redesign demo catalogue.
    expect(find.text('3 Stories'), findsWidgets);
  });

  testWidgets('Stories tab survives large Dynamic Type', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(testScope(const SprachApp(), library: true));
    await tester.pumpAndSettle();
    await openStoriesTab(tester);
    expect(find.byType(StoryLibraryScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  StoryReaderScreen readerScreen() => StoryReaderScreen(
    narrationFactory: () => PlaybackClock.forText(sampleStoryText(sampleStories.first.id).paragraphs),
    story: sampleStories.first,
    text: sampleStoryText(sampleStories.first.id),
  );

  Widget reader() => MaterialApp(theme: buildAppTheme(), home: readerScreen());

  /// Taps the first occurrence of [word] inside the story body.
  Future<void> tapWord(WidgetTester tester, String word) async {
    final body = find.byWidgetPredicate(
      (w) => w is RichText && w.text.toPlainText().contains(word),
    );
    final paragraph = tester.renderObject<RenderParagraph>(body.first);
    final text = paragraph.text.toPlainText();
    final offset = text.indexOf(word) + 1;
    final box = paragraph.getBoxesForSelection(
      TextSelection(baseOffset: offset, extentOffset: offset + 1),
    );
    await tester.tapAt(paragraph.localToGlobal(box.first.toRect().center));
    await tester.pumpAndSettle();
  }

  testWidgets('Story body is set in the editorial serif', (tester) async {
    await tester.pumpWidget(reader());
    final body = tester.widget<RichText>(
      find
          .byWidgetPredicate(
            (w) =>
                w is RichText && w.text.toPlainText().startsWith('The station'),
          )
          .first,
    );
    // Text.rich wraps our span in the ambient default style.
    final story = (body.text as TextSpan).children!.single as TextSpan;
    expect(story.style?.fontFamily, AppType.storyBody().fontFamily);
    expect(story.style?.fontFamily, contains('SourceSerif4'));
  });

  testWidgets(
    'Story lookup explicitly does not pretend to save a learning card',
    (tester) async {
      await tester.pumpWidget(reader());
      await tapWord(tester, 'arrived');

      expect(find.byType(WordPopover), findsOneWidget);
      expect(find.text('ankommen'), findsOneWidget);
      expect(find.text('im Text: arrived'), findsNothing);
      expect(find.text('Deutsch'), findsNothing);
      expect(find.textContaining('Verb', findRichText: true), findsWidgets);

      expect(
        find.text(
          'Lernstatus nicht lesbar. Bitte erneut öffnen.',
        ),
        findsOneWidget,
      );
      expect(
        tester.getSemantics(
          find.bySemanticsLabel('Zum Lernen hinzufügen'),
        ),
        isSemantics(isButton: true, isEnabled: false),
      );
      expect(find.bySemanticsLabel('Wird gelernt'), findsNothing);
    },
  );

  testWidgets('Word popover points at the word and can pronounce it', (
    tester,
  ) async {
    await mockNativeSpeech(tester);
    await tester.pumpWidget(reader());
    await tapWord(tester, 'clock');

    final popover = find.ancestor(
      of: find.byType(WordPopover),
      matching: find.byWidgetPredicate(
        (w) =>
            w is DecoratedBox &&
            w.decoration is ShapeDecoration &&
            (w.decoration as ShapeDecoration).color ==
                AppPalette(Brightness.dark).popover,
      ),
    );
    expect(popover, findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Aussprechen')),
      isSemantics(isButton: true, hasTapAction: true),
    );
    await tester.tap(find.bySemanticsLabel('Aussprechen'));
    Finder inPopover(IconData icon) => find.descendant(
      of: find.byType(WordPopover),
      matching: find.byIcon(icon),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(inPopover(CupertinoIcons.stop_fill), findsOneWidget);
    await completeSpeech();
    debugDefaultTargetPlatformOverride = null;
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(WordPopover),
        matching: find.byType(SpeakerIcon),
      ),
      findsOneWidget,
    );

    // Tapping outside closes it.
    await tester.tapAt(const Offset(5, 400));
    await tester.pumpAndSettle();
    expect(find.byType(WordPopover), findsNothing);
  });

  testWidgets('Known words keep their status without a downgrade', (
    tester,
  ) async {
    await tester.pumpWidget(reader());
    await tapWord(tester, 'station');
    expect(find.bySemanticsLabel('Zum Lernen hinzufügen'), findsOneWidget);
    // Demo has no repository: Add fails closed; marks never claim a saved card.
    expect(find.text('Hinzugefügt'), findsNothing);
    expect(sampleWordMarks['station'], WordMark.mastered);
  });

  // ------------------------------------------------------ domain + models

  test('Answer check: exact, almost, wrong', () {
    expect(checkAnswer(' Dressed ', 'dressed'), AnswerResult.correct);
    expect(checkAnswer('dresed', 'dressed'), AnswerResult.almost);
    expect(checkAnswer('dress', 'dressed'), AnswerResult.wrong);
    // Short words get no typo tolerance.
    expect(checkAnswer('rn', 'ran'), AnswerResult.wrong);
    expect(editDistance('kitten', 'sitting'), 3);
  });

  test('Sentences cover the paragraph exactly', () {
    const p = 'The train left. "Wait!" she said? Yes… and then';
    final ranges = splitSentences(p);
    expect(ranges.map((r) => p.substring(r.start, r.end)).join(), p);
    expect(
      p.substring(ranges.first.start, ranges.first.end),
      'The train left. ',
    );
    expect(ranges, hasLength(4));
  });

  test('Gap markup parses answers, bases and word classes', () {
    final segments = parseGaps('He {dressed|dress|verb} and {tea|tea|noun}.');
    expect(segments, hasLength(5));
    final gap = segments[1] as TextGap;
    expect(gap.answer, 'dressed');
    expect(gap.base, 'dress');
    expect(gap.wordClass, WordClass.verb);
    final text = sampleExerciseTexts.firstWhere(
      (t) => t.id == 'text-slow-morning',
    );
    expect(text.gapCount(ExerciseMode.verbs), 6);
    expect(text.gapCount(ExerciseMode.anyWordClass), 9);
  });

  // ------------------------------------------------------- content dashboard

  Future<void> openContentTab(WidgetTester tester) async {
    await tester.pumpWidget(testScope(const SprachApp(), library: true));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AppBottomBar),
        matching: find.text('Inhalte'),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder dashboardScrollable() => find
      .descendant(
        of: find.byType(ContentDashboardScreen),
        matching: find.byType(Scrollable),
      )
      .first;

  /// Scrolls [finder] into view and clear of the notched bar.
  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: dashboardScrollable(),
    );
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('Inhalte shows every category with its content, no decks', (
    tester,
  ) async {
    await openContentTab(tester);
    expect(find.byType(ContentDashboardScreen), findsOneWidget);
    final dashboard = find.byType(ContentDashboardScreen);
    expect(
      find.descendant(of: dashboard, matching: find.byType(DeckTile)),
      findsNothing,
    );
    expect(
      find.descendant(of: dashboard, matching: find.textContaining('Stapel')),
      findsNothing,
    );
    expect(find.textContaining('Bald verfügbar'), findsNothing);

    // Texte: compact numbered rows, without image backgrounds.
    expect(find.text('Texte'), findsOneWidget);
    expect(
      find.descendant(of: dashboard, matching: find.byType(TextExerciseShelf)),
      findsOneWidget,
    );
    expect(tester.getTopLeft(find.byType(TextExerciseShelf)).dy, lessThan(600));

    // Hören: the first open exercise as a wide card, the rest as tiles.
    final feature = find.bySemanticsLabel(
      RegExp('^Als Nächstes: Das th in „think“'),
    );
    await reveal(tester, feature);
    expect(
      tester.getSemantics(feature),
      isSemantics(isButton: true, hasTapAction: true),
    );
    expect(tester.getSize(feature).width, greaterThan(300));
    final solved = find.bySemanticsLabel(RegExp(r'^w oder v\..*, fertig$'));
    await reveal(tester, solved);
    expect(solved, findsOne);
    expect(find.text('Meine Übungen'), findsNothing);

    // Grammatik: rows with title and summary.
    await tester.scrollUntilVisible(
      find.text('Das -s in der 3. Person'),
      200,
      scrollable: dashboardScrollable(),
    );
    expect(find.text('Simple Present mit he, she und it'), findsOneWidget);

    // Grammatikregeln: rule cards in two columns.
    final artikel = find.bySemanticsLabel(RegExp('^Artikel, a, an und the'));
    await reveal(tester, artikel);
    final plural = find.bySemanticsLabel(RegExp('^Pluralbildung, '));
    expect(tester.getSize(artikel).width, tester.getSize(plural).width);
    expect(tester.getTopLeft(artikel).dy, tester.getTopLeft(plural).dy);

    // Every section has its "Mehr anzeigen", named for VoiceOver.
    await tester.drag(dashboard, const Offset(0, 4000));
    await tester.pumpAndSettle();
    for (final label in [
      'Alle Texte anzeigen',
      'Alle Hörübungen anzeigen',
      'Alle Grammatikübungen anzeigen',
      'Alle Grammatikregeln anzeigen',
    ]) {
      final more = find.bySemanticsLabel(label);
      await tester.scrollUntilVisible(
        more,
        200,
        scrollable: dashboardScrollable(),
      );
      expect(
        tester.getSemantics(more),
        isSemantics(isButton: true, hasTapAction: true),
      );
      expect(
        find.descendant(
          of: find.ancestor(of: more, matching: find.byType(MoreButton)),
          matching: find.text('Mehr anzeigen'),
        ),
        findsOneWidget,
      );
    }
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
  });

  testWidgets('Dashboard survives large Dynamic Type', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await openContentTab(tester);
    for (var i = 0; i < 6; i++) {
      await tester.drag(
        find.byType(ContentDashboardScreen),
        const Offset(0, -600),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Dashboard cards open their exercise directly', (tester) async {
    stillStage(tester);
    await openContentTab(tester);
    final slowMorning = find.bySemanticsLabel(RegExp(r'^A Slow Morning\.'));
    await tester.ensureVisible(slowMorning);
    await tester.pumpAndSettle();
    await tester.tap(slowMorning);
    await tester.pumpAndSettle();
    expect(find.byType(ExerciseChoiceSheet), findsOneWidget);
    await tester.tapAt(const Offset(20, 40));
    await tester.pumpAndSettle();

    final feature = find.bySemanticsLabel(
      RegExp('^Als Nächstes: Das th in „think“'),
    );
    expect(find.byType(ExerciseChoiceSheet), findsNothing);
    await reveal(tester, feature);
    await tester.tap(feature);
    await tester.pumpAndSettle();
    expect(find.byType(ListeningExerciseScreen), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Zurück'));
    await tester.pumpAndSettle();

    final artikel = find.bySemanticsLabel(RegExp('^Artikel, a, an und the'));
    await reveal(tester, artikel);
    await tester.tap(artikel);
    await tester.pumpAndSettle();
    expect(find.byType(GrammarRuleDetailScreen), findsOneWidget);
  });

  // ----------------------------------------------------------- text library

  Widget textLibrary(ReadingHistory history) => testScope(MaterialApp(
    theme: buildAppTheme(),
    home: TextLibraryScreen(texts: sampleExerciseTexts, history: history),
  ));

  testWidgets('"Aus deinen Stories" follows the reading history', (
    tester,
  ) async {
    final history = ReadingHistory();
    await tester.pumpWidget(textLibrary(history));
    expect(find.text('Aus deinen Stories'), findsNothing);

    history.markRead('saturday-market');
    await tester.pumpAndSettle();
    expect(find.text('Aus deinen Stories'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp(r'^The Saturday Market\.')),
      findsWidgets,
    );
  });

  testWidgets('Opening the story marks it read for the text library', (
    tester,
  ) async {
    await tester.pumpWidget(testScope(const SprachApp(), library: true));
    await tester.pumpAndSettle();
    final market = find.bySemanticsLabel(RegExp(r'^The Saturday Market\.'));
    await tester.scrollUntilVisible(
      market,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(StoryCarousel).first, const Offset(-300, 0));
    await tester.pumpAndSettle();
    await tester.tap(market.first);
    await tester.pumpAndSettle();
    expect(find.byType(StoryReaderScreen), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Zurück'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(AppBottomBar),
        matching: find.text('Inhalte'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Alle Texte anzeigen'));
    await tester.pumpAndSettle();
    final fromStories = find.ancestor(
      of: find.text('Aus deinen Stories'),
      matching: find.byType(SectionHeading),
    );
    expect(
      find.descendant(of: fromStories, matching: find.text('2')),
      findsOneWidget,
    );
  });

  testWidgets('A text card opens the exercise choice sheet', (tester) async {
    await tester.pumpWidget(textLibrary(ReadingHistory()));
    final slowMorning = find.bySemanticsLabel(RegExp(r'^A Slow Morning\.'));
    await tester.ensureVisible(slowMorning);
    await tester.pumpAndSettle();
    await tester.tap(slowMorning);
    await tester.pumpAndSettle();
    expect(find.byType(ExerciseChoiceSheet), findsOneWidget);
    expect(
      find.bySemanticsLabel('Lückentext-Übungen: Verben'),
      findsOneWidget,
    );
    // The popover below the cover scrolls on the short test window.
    await tester.ensureVisible(find.text('Beliebige Wortart'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Beliebige Wortart'));
    await tester.pumpAndSettle();
    expect(find.byType(TextExerciseScreen), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(
            find.byKey(const ValueKey('cloze-progress')),
          )
          .value,
      0,
    );
  });

  // ------------------------------------------------------------- exercises

  ExerciseText exerciseText(String id) =>
      sampleExerciseTexts.firstWhere((t) => t.id == 'text-$id');

  Widget exercise(String id, ExerciseMode mode) => MaterialApp(
    theme: buildAppTheme(),
    home: TextExerciseScreen(text: exerciseText(id), mode: mode),
  );

  Future<void> typeAnswer(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField).first, text);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
  }

  Color? hintColor(WidgetTester tester) => tester
      .widget<TextField>(find.byType(TextField).first)
      .decoration
      ?.hintStyle
      ?.color;

  testWidgets('Verb gap: wrong clears and flashes, almost keeps, right locks', (
    tester,
  ) async {
    await tester.pumpWidget(exercise('slow-morning', ExerciseMode.verbs));
    final total = exerciseText('slow-morning').gapCount(ExerciseMode.verbs);
    expect(find.byType(TextField), findsNWidgets(total));
    expect(hintColor(tester), AppColors.textMuted);

    await typeAnswer(tester, 'xyz');
    final field = tester.widget<TextField>(find.byType(TextField).first);
    expect(field.controller!.text, isEmpty);
    expect(hintColor(tester), AppColors.error);
    await tester.pump(const Duration(milliseconds: 700));
    expect(hintColor(tester), AppColors.textMuted);

    // A wrong attempt keeps the keyboard on the same gap.
    expect(
      tester
          .widget<TextField>(find.byType(TextField).first)
          .focusNode!
          .hasFocus,
      isTrue,
    );

    await typeAnswer(tester, 'wokee');
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      'wokee',
    );
    expect(find.textContaining('Fast richtig'), findsOneWidget);

    await typeAnswer(tester, 'woke');
    expect(find.byType(TextField), findsNWidgets(total - 1));
    expect(
      tester
          .widget<LinearProgressIndicator>(
            find.byKey(const ValueKey('cloze-progress')),
          )
          .value,
      1 / total,
    );
    final solved = tester
        .widgetList<RichText>(find.byType(RichText))
        .expand((r) => [r.text])
        .whereType<TextSpan>()
        .expand((s) {
          final out = <TextSpan>[];
          s.visitChildren((c) {
            if (c is TextSpan && c.text == 'woke') out.add(c);
            return true;
          });
          return out;
        });
    expect(solved.single.style?.color, AppColors.success);
    await tester.pump(const Duration(seconds: 3));
  });

  Finder chip(String answer) =>
      find.descendant(of: find.byType(Wrap), matching: find.text(answer));

  BoxDecoration chipBox(WidgetTester tester, String answer) =>
      tester
              .widget<AnimatedContainer>(
                find.ancestor(
                  of: chip(answer),
                  matching: find.byType(AnimatedContainer),
                ),
              )
              .decoration!
          as BoxDecoration;

  testWidgets('Answer chips: wrong flashes red, right flies in and greys out', (
    tester,
  ) async {
    await tester.pumpWidget(
      exercise('at-the-station', ExerciseMode.anyWordClass),
    );
    final total = exerciseText(
      'at-the-station',
    ).gapCount(ExerciseMode.anyWordClass);
    expect(find.byType(TextField), findsNothing);
    // Chips hug their word instead of stretching across the panel.
    final panel = tester.getSize(find.byType(Wrap)).width;
    expect(
      tester
          .getSize(
            find.ancestor(
              of: chip('ran'),
              matching: find.byType(AnimatedContainer),
            ),
          )
          .width,
      lessThan(panel / 2),
    );
    // Resting chips: Raised Ink fill, no outline (Redesign).
    expect(chipBox(tester, 'left').color, AppColors.raisedInk);

    await tester.tap(chip('ran'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(chipBox(tester, 'ran').color, AppColors.errorTint);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(chipBox(tester, 'ran').color, AppColors.raisedInk);

    await tester.tap(chip('left'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(chipBox(tester, 'left').color, AppColors.successTint);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<LinearProgressIndicator>(
            find.byKey(const ValueKey('cloze-progress')),
          )
          .value,
      1 / total,
    );

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(chipBox(tester, 'left').color, isNull);
    final label = tester.widget<Text>(chip('left'));
    expect(label.style?.color, AppColors.iconOff);
    expect(
      tester.getSemantics(find.bySemanticsLabel('left')),
      isSemantics(isButton: true, isEnabled: false),
    );
  });

  testWidgets('Exercise screen survives large Dynamic Type', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      exercise('visit-to-the-doctor', ExerciseMode.anyWordClass),
    );
    await tester.pumpWidget(
      exercise('visit-to-the-doctor', ExerciseMode.verbs),
    );
    expect(tester.takeException(), isNull);
  });

  // --------------------------------------------------------- translation

  testWidgets('Reader translation mode makes sentences the tap targets', (
    tester,
  ) async {
    await tester.pumpWidget(reader());
    await tester.tap(find.bySemanticsLabel('Übersetzen'));
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.bySemanticsLabel('Übersetzen')),
      isSemantics(
        isButton: true,
        isToggled: true,
        hasToggledState: true,
        hasTapAction: true,
      ),
    );
    expect(find.text(ReadingToolbar.hint), findsOneWidget);

    await tapWord(tester, 'arrived');
    expect(find.byType(WordPopover), findsNothing);
    expect(find.byType(SentencePopover), findsOneWidget);
    expect(
      find.text('The station was almost empty when Clara arrived.'),
      findsOneWidget,
    );
    expect(
      find.text('Der Bahnhof war fast leer, als Clara ankam.'),
      findsOneWidget,
    );
    // The hint has done its job once a sentence was tapped.
    expect(find.text(ReadingToolbar.hint), findsNothing);
  });

  testWidgets('Exercise translation hides unsolved answers', (tester) async {
    await tester.pumpWidget(exercise('slow-morning', ExerciseMode.verbs));
    await tester.tap(find.bySemanticsLabel('Übersetzen'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);

    expect(find.text(ReadingToolbar.hint), findsOneWidget);
    await tapWord(tester, 'Sunday');
    expect(find.text(ReadingToolbar.hint), findsNothing);
    expect(find.text('Tom … up late on Sunday.'), findsOneWidget);
    expect(find.text('Tom wachte am Sonntag spät auf.'), findsOneWidget);
  });

  final wordListNow = DateTime(2026, 10, 2, 12);

  Widget wordList([WordListStore? store]) {
    final fixture = store ?? WordListStore(sampleVocabulary(wordListNow));
    return ProviderScope(
      overrides: [
        wordListProvider.overrideWith((ref) {
          fixture.addListener(ref.invalidateSelf);
          ref.onDispose(() => fixture.removeListener(ref.invalidateSelf));
          return fixture.words;
        }),
        wordActionsProvider.overrideWith(
          (ref) => FixtureWordActions(ref, fixture),
        ),
      ],
      child: MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(body: WordListScreen(clock: () => wordListNow, playbackFactory: SpeechPlayback.new)),
      ),
    );
  }

  /// Phone width; tall enough that every sample card is built.
  void phoneView(WidgetTester tester, {double height = 2600}) {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = Size(390 * 3, height * 3);
    addTearDown(tester.view.reset);
  }

  /// [finder] inside the card of [headword].
  Finder inCard(String headword, Finder finder) => find.descendant(
    of: find.byWidgetPredicate(
      (w) => w is WordListItem && w.word.entry.headword == headword,
    ),
    matching: finder,
  );

  /// Lets the simulated playback and any snack bar run out.
  Future<void> drainTimers(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }

  test('Leitner intervals and "Zuletzt gesehen" labels', () {
    expect(leitnerInterval(1), const Duration(days: 1));
    expect(leitnerInterval(5), const Duration(days: 90));
    expect(() => leitnerInterval(6), throwsRangeError);
    final now = DateTime(2026, 10, 2, 0, 30);
    expect(lastSeenLabel(DateTime(2026, 10, 2, 0, 5), now), 'heute');
    expect(lastSeenLabel(DateTime(2026, 10, 1, 23, 50), now), 'gestern');
    expect(lastSeenLabel(DateTime(2026, 9, 30), now), 'vor 2 Tagen');
    expect(lastSeenLabel(DateTime(2026, 9, 11), now), 'vor 3 Wochen');
    expect(lastSeenLabel(DateTime(2026, 7, 30), now), 'vor 2 Monaten');
    expect(intervalLabel(const Duration(days: 1)), '1 Tag');
    expect(intervalLabel(const Duration(days: 14)), '14 Tage');
  });

  testWidgets('Wortliste tab lists seen words with search and playlist', (
    tester,
  ) async {
    await tester.pumpWidget(testScope(const SprachApp(), library: true));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AppBottomBar),
        matching: find.text('Wortliste'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(WordListScreen), findsOneWidget);
    expect(find.text('Wörter suchen'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^Playlist, \d+ Übungen$')), findsOne);
    expect(
      tester.getSemantics(
        find.descendant(
          of: find.byType(AppBottomBar),
          matching: find.bySemanticsLabel('Wortliste'),
        ),
      ),
      isSemantics(isButton: true, isSelected: true, hasTapAction: true),
    );
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
  });

  testWidgets('Word card shows level and sentence, no metadata line', (
    tester,
  ) async {
    phoneView(tester);
    await tester.pumpWidget(wordList());
    expect(find.text('platform'), findsOneWidget);
    expect(
      find.text('Anna ran to the platform, but the doors were already closed.'),
      findsOneWidget,
    );
    // Last seen and review count left the card (29.10.2026).
    expect(find.textContaining('Zuletzt gesehen'), findsNothing);
    expect(find.textContaining('Wiederholt:'), findsNothing);
    expect(
      tester.getSemantics(
        inCard(
          'platform',
          find.bySemanticsLabel('Erinnerungsstufe 3 von 5: Gut verankert'),
        ),
      ),
      isSemantics(isButton: true, hasTapAction: true),
    );
    // Level 3: three lit dashes in the level-3 green, two Hairline.
    final dashes = tester
        .widgetList<Container>(
          find.descendant(
            of: inCard(
              'platform',
              find.bySemanticsLabel('Erinnerungsstufe 3 von 5: Gut verankert'),
            ),
            matching: find.byType(Container),
          ),
        )
        .map((c) => (c.decoration! as BoxDecoration).color)
        .toList();
    expect(dashes, [
      AppColors.memoryLevel3,
      AppColors.memoryLevel3,
      AppColors.memoryLevel3,
      AppColors.hairline,
      AppColors.hairline,
    ]);
    expect(AppColors.memoryLevel(1), AppColors.active);
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
  });

  testWidgets('Search matches headword and translation', (tester) async {
    phoneView(tester);
    await tester.pumpWidget(wordList());
    await tester.enterText(find.byType(CupertinoSearchTextField), 'bahn');
    await tester.pumpAndSettle();
    expect(find.text('platform'), findsOneWidget);
    expect(find.text('station'), findsOneWidget);
    expect(find.text('journey'), findsNothing);

    await tester.enterText(find.byType(CupertinoSearchTextField), 'xyz');
    await tester.pumpAndSettle();
    expect(find.text('Keine Wörter für „xyz“'), findsOneWidget);
  });

  testWidgets('Tapping the word or sentence marks it while it plays', (
    tester,
  ) async {
    phoneView(tester);
    await tester.pumpWidget(wordList());
    Finder marks() => find.byWidgetPredicate(
      (w) =>
          w is AnimatedContainer &&
          (w.decoration as BoxDecoration?)?.color == AppColors.playback,
    );
    expect(marks(), findsNothing);
    expect(find.byWidgetPredicate((w) => w is SpeakerIcon && w.filled), findsNothing);

    await tester.tap(find.bySemanticsLabel('platform anhören'));
    await tester.pump();
    expect(marks(), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is SpeakerIcon && w.filled), findsOneWidget);

    // Starting the sentence stops the word: one mark at a time.
    await tester.tap(find.bySemanticsLabel(RegExp('^Satz anhören: Anna ran')));
    await tester.pump();
    expect(marks(), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is SpeakerIcon && w.filled), findsNothing);

    await drainTimers(tester);
    expect(marks(), findsNothing);
  });

  testWidgets('Quiet toggles flip state and confirm with a snack bar', (
    tester,
  ) async {
    phoneView(tester);
    final store = WordListStore(sampleVocabulary(wordListNow));
    await tester.pumpWidget(wordList(store));
    Finder toggle(String label) =>
        inCard('platform', find.bySemanticsLabel(label));
    Finder menu(String label) => find.bySemanticsLabel(label);
    Future<void> openMenu() async {
      await tester.tap(toggle('Mehr zu platform'));
      await tester.pumpAndSettle();
    }

    // Only the heart stays on the card; the rest lives in "Mehr".
    expect(toggle('Deaktiviert'), findsNothing);
    await openMenu();
    expect(
      tester.getSemantics(menu('Deaktiviert')),
      isSemantics(isButton: true, hasToggledState: true, isToggled: false),
    );
    await tester.tap(menu('Deaktiviert'));
    await tester.pumpAndSettle();
    expect(find.text('Wort deaktiviert'), findsOneWidget);
    expect(store.byId('platform').isDisabled, isTrue);
    // The card dims; no "Deaktiviert" text, only for screen readers.
    expect(find.textContaining('Deaktiviert ·'), findsNothing);
    expect(
      find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.value == 'Deaktiviert',
      ),
      findsOneWidget,
    );
    await openMenu();
    expect(
      tester.getSemantics(menu('Deaktiviert')),
      isSemantics(isButton: true, hasToggledState: true, isToggled: true),
    );

    // Already in the playlist: tapping removes it.
    await tester.tap(menu('In der Playlist'));
    await tester.pumpAndSettle();
    expect(find.text('Aus der Playlist entfernt'), findsOneWidget);

    await tester.tap(toggle('Favorit'));
    await tester.pumpAndSettle();
    expect(find.text('Zu Favoriten hinzugefügt'), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.heart_fill), findsWidgets);
    await drainTimers(tester);
  });

  testWidgets('The dashes open the legend with the word\'s level marked', (
    tester,
  ) async {
    phoneView(tester);
    await tester.pumpWidget(wordList());
    await tester.tap(
      inCard(
        'platform',
        find.bySemanticsLabel('Erinnerungsstufe 3 von 5: Gut verankert'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(MemoryLevelLegendSheet), findsOneWidget);
    expect(find.text('Neues Wort'), findsOneWidget);
    expect(find.text('Maximales Erinnerungsvermögen'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        RegExp('^Stufe 3 von 5: Gut verankert.*Aktuelle Stufe'),
      ),
      findsOneWidget,
    );
    // Marked by a band, not by text; the intro sentence is gone too.
    expect(find.text('Dieses Wort'), findsNothing);
    expect(find.textContaining('Jede richtige Wiederholung'), findsNothing);
  });

  testWidgets('Details keep review facts without duplicate sentence or note', (
    tester,
  ) async {
    phoneView(tester);
    final store = WordListStore(sampleVocabulary(wordListNow));
    store.setNote('platform', 'Gleis = track');
    await tester.pumpWidget(wordList(store));
    await tester.tap(find.bySemanticsLabel('Mehr zu platform'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Details zu platform'));
    await tester.pumpAndSettle();
    // No bottom sheet: the menu slid away inside the same bubble.
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.bySemanticsLabel('Details zu platform'), findsNothing);
    final page = find.byType(WordDetailsPage);
    expect(page, findsOneWidget);
    Finder inPage(Finder f) => find.descendant(of: page, matching: f);
    expect(inPage(find.text('der Bahnsteig')), findsOneWidget);
    expect(inPage(find.text('Substantiv')), findsOneWidget);
    expect(inPage(find.text('vor 2 Tagen')), findsOneWidget);
    expect(inPage(find.text('5 Mal')), findsOneWidget);
    // Less text: no heading, no field labels, no interval row.
    expect(inPage(find.text('Wortinfos')), findsNothing);
    expect(inPage(find.text('Deutsch')), findsNothing);
    expect(inPage(find.text('Beispielsatz')), findsNothing);
    expect(inPage(find.text('Zeit zwischen Wiederholungen')), findsNothing);
    expect(
      inPage(
        find.text(
          'Anna rannte zum Bahnsteig, aber die Türen waren schon geschlossen.',
        ),
      ),
      findsNothing,
    );
    expect(inPage(find.bySemanticsLabel('platform anhören')), findsOneWidget);
    expect(inPage(find.text(store.byId('platform').sentence)), findsNothing);
    expect(
      inPage(find.bySemanticsLabel(RegExp('^Satz anhören:'))),
      findsNothing,
    );
    expect(inPage(find.byType(CupertinoTextField)), findsNothing);
    expect(store.byId('platform').note, 'Gleis = track');

    await tester.tap(inPage(find.bySemanticsLabel('Zurück')));
    await tester.pumpAndSettle();
    expect(find.byType(WordDetailsPage), findsNothing);
    expect(find.bySemanticsLabel('Details zu platform'), findsOneWidget);
    expect(store.byId('platform').note, 'Gleis = track');
    await drainTimers(tester);
  });

  testWidgets('Wortliste and sheets survive large Dynamic Type', (
    tester,
  ) async {
    phoneView(tester, height: 844);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(wordList());
    // Cards are shorter without the metadata line: scroll less far so a
    // card's "Mehr" stays in view.
    await tester.drag(find.byType(ListView).last, const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(
      find.bySemanticsLabel(RegExp('^Mehr zu')).hitTestable().first,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.bySemanticsLabel(RegExp('^Details zu')).first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    Navigator.of(tester.element(find.byType(WordDetailsPage))).pop();
    await tester.pumpAndSettle();

    await tester.tap(
      find.bySemanticsLabel(RegExp('^Erinnerungsstufe')).hitTestable().first,
    );
    await tester.pumpAndSettle();
    expect(find.byType(MemoryLevelLegendSheet), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Word cards: filled, no outline; status filters narrow it', (
    tester,
  ) async {
    phoneView(tester);
    await tester.pumpWidget(wordList());
    final boxes = tester
        .widgetList<Container>(
          find.descendant(
            of: find.byType(WordListItem).first,
            matching: find.byType(Container),
          ),
        )
        .map((c) => c.decoration)
        .whereType<BoxDecoration>();
    expect(boxes.where((d) => d.border != null), isEmpty);
    expect(boxes.where((d) => d.color == AppColors.raisedInk), isNotEmpty);

    final all = tester.widgetList(find.byType(WordListItem)).length;
    final chip = find.textContaining('Gemeistert  ', findRichText: true);
    await tester.scrollUntilVisible(
      chip,
      120,
      scrollable: find
          .descendant(
            of: find.byType(ListView).first,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(chip);
    await tester.pumpAndSettle();
    expect(tester.widgetList(find.byType(WordListItem)).length, lessThan(all));
    for (final item in tester.widgetList<WordListItem>(
      find.byType(WordListItem),
    )) {
      expect(item.word.box, 5);
    }
  });

  // ------------------------------------------------------------- grammar

  test('Emphasis markup splits forms from prose', () {
    expect(parseEmphasis('Vor Vokalen *an*: *an hour*.'), [
      (text: 'Vor Vokalen ', emphasis: false),
      (text: 'an', emphasis: true),
      (text: ': ', emphasis: false),
      (text: 'an hour', emphasis: true),
      (text: '.', emphasis: false),
    ]);
    expect(parseEmphasis('2 * 3'), [(text: '2 * 3', emphasis: false)]);
    for (final level in GrammarLevel.values) {
      expect(sampleGrammarRules.where((r) => r.level == level), isNotEmpty);
    }
    expect(
      sampleGrammarRules.map((r) => r.id).toSet(),
      hasLength(sampleGrammarRules.length),
    );
  });

  Widget grammar() => MaterialApp(
    theme: buildAppTheme(),
    home: GrammarRulesScreen(rules: sampleGrammarRules),
  );

  testWidgets('Grammatikregeln filters rules by level', (tester) async {
    await tester.pumpWidget(grammar());
    expect(
      find.byType(CupertinoSlidingSegmentedControl<GrammarLevel>),
      findsOneWidget,
    );
    expect(find.text('Artikel'), findsOneWidget);
    expect(find.text('Pluralbildung'), findsOneWidget);
    expect(find.text('Present Perfect'), findsNothing);
    expect(
      tester.getSemantics(
        find.bySemanticsLabel(RegExp('^Artikel, a, an und the')),
      ),
      isSemantics(isButton: true, hasTapAction: true),
    );

    await tester.tap(find.text('Mittleres Niveau'));
    await tester.pumpAndSettle();
    expect(find.text('Present Perfect'), findsOneWidget);
    expect(find.text('Artikel'), findsNothing);

    await tester.tap(find.text('Fortgeschrittene'));
    await tester.pumpAndSettle();
    expect(find.text('Passiv'), findsOneWidget);
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
  });

  testWidgets('Grammatikregeln opens from the dashboard', (tester) async {
    await openContentTab(tester);
    final more = find.bySemanticsLabel('Alle Grammatikregeln anzeigen');
    await tester.scrollUntilVisible(
      more,
      200,
      scrollable: dashboardScrollable(),
    );
    await tester.ensureVisible(more);
    await tester.pumpAndSettle();
    await tester.tap(more);
    await tester.pumpAndSettle();
    expect(find.byType(GrammarRulesScreen), findsOneWidget);
  });

  testWidgets('Rule detail reads on the Night Page, forms set apart', (
    tester,
  ) async {
    await tester.pumpWidget(grammar());
    await tester.tap(find.text('Artikel'));
    await tester.pumpAndSettle();
    expect(find.byType(GrammarRuleDetailScreen), findsOneWidget);
    expect(
      tester
          .widget<Scaffold>(
            find.descendant(
              of: find.byType(GrammarRuleDetailScreen),
              matching: find.byType(Scaffold),
            ),
          )
          .backgroundColor,
      AppColors.nightPage,
    );
    expect(find.text('Anfänger · 1 Min'), findsOneWidget);

    final example = tester
        .widget<RichText>(
          find
              .byWidgetPredicate(
                (w) =>
                    w is RichText &&
                    w.text.toPlainText() == 'She is a teacher.',
              )
              .first,
        )
        .text;
    TextStyle? styleOf(String piece) {
      TextStyle? found;
      example.visitChildren((span) {
        if (span is TextSpan && span.text == piece) found = span.style;
        return found == null;
      });
      return found;
    }

    // English forms: italic w600 in textPrimary, never a status ink.
    expect(styleOf('a')?.fontStyle, FontStyle.italic);
    expect(styleOf('a')?.fontWeight, FontWeight.w600);
    expect(styleOf('a')?.color, AppColors.textPrimary);
    expect(find.text('Sie ist Lehrerin.'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Sondern'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(GrammarRuleDetailScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Typischer Fehler'), findsWidgets);
    expect(
      find.bySemanticsLabel(RegExp('Nicht\nFalsch: She is teacher.')),
      findsOneWidget,
    );
    for (final text in tester.widgetList<RichText>(find.byType(RichText))) {
      text.text.visitChildren((span) {
        expect(span.style?.color, isNot(AppColors.active));
        expect(span.style?.color, isNot(AppColors.mastered));
        return true;
      });
    }
  });

  testWidgets('Grammar screens survive large Dynamic Type', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(grammar());
    await tester.tap(find.text('Fortgeschrittene'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Bedingungssätze'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).last, const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  // ----------------------------------------------------------- narration

  test('Narration clock: duration, skip, seek and the sentence being read', () {
    final narration = PlaybackClock.forText(['one two three']);
    expect(narration.duration, const Duration(seconds: 10));
    narration.skip(const Duration(seconds: -15));
    expect(narration.position, Duration.zero);
    narration.skip(PlaybackClock.skipStep);
    expect(narration.position, narration.duration);
    narration.dispose();

    expect(clockLabel(const Duration(minutes: 5, seconds: 56)), '5:56');
    expect(clockLabel(const Duration(seconds: 7)), '0:07');
    expect(sentenceAt([10, 30], 0), 0);
    expect(sentenceAt([10, 30], 0.3), 1);
    expect(sentenceAt([10, 30], 1), isNull);
    expect(sentenceAt([], 0), isNull);
  });

  /// Plain text of every span in the story body on [color].
  List<String> spansOn(WidgetTester tester, Color color) {
    final found = <String>[];
    // visitChildren skips spans without text, so walk the tree by hand.
    void walk(InlineSpan span) {
      if (span.style?.backgroundColor == color) {
        found.add(span.toPlainText());
      } else if (span is TextSpan) {
        span.children?.forEach(walk);
      }
    }

    for (final text in tester.widgetList<RichText>(find.byType(RichText))) {
      walk(text.text);
    }
    return found;
  }

  testWidgets('Vorlesen docks a player and marks the sentence being read', (
    tester,
  ) async {
    await tester.pumpWidget(reader());
    expect(find.byType(NarrationPanel), findsNothing);
    expect(spansOn(tester, AppColors.playback), isEmpty);

    await tester.tap(find.bySemanticsLabel('Vorlesen'));
    await tester.pump();
    expect(
      tester.getSemantics(find.bySemanticsLabel('Vorlesen')),
      isSemantics(
        isButton: true,
        isToggled: true,
        hasToggledState: true,
        hasTapAction: true,
      ),
    );
    expect(find.byType(NarrationPanel), findsOneWidget);
    expect(find.bySemanticsLabel('Pause'), findsOneWidget);
    expect(find.text('0:00'), findsOneWidget);
    expect(spansOn(tester, AppColors.playback), [
      'The station was almost empty when Clara arrived. ',
    ]);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('0:01'), findsOneWidget);

    // Further along, the mark moves on; a tapped word still opens its sheet.
    await tester.tap(find.bySemanticsLabel('15 Sekunden vor'));
    await tester.pump();
    expect(
      spansOn(tester, AppColors.playback).single,
      isNot(startsWith('The station')),
    );

    // Paused: no mark.
    await tester.tap(find.bySemanticsLabel('Pause'));
    await tester.pump();
    expect(find.bySemanticsLabel('Abspielen'), findsOneWidget);
    expect(spansOn(tester, AppColors.playback), isEmpty);
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));

    // Translation mode keeps the mark on the sentence.
    await tester.tap(find.bySemanticsLabel('Abspielen'));
    await tester.tap(find.bySemanticsLabel('Übersetzen'));
    await tester.pump();
    expect(spansOn(tester, AppColors.playback), hasLength(1));

    await tester.tap(find.bySemanticsLabel('Vorlesen'));
    await tester.pump();
    expect(find.byType(NarrationPanel), findsNothing);
    expect(spansOn(tester, AppColors.playback), isEmpty);
  });

  testWidgets('Reader with player survives large Dynamic Type', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(reader());
    await tester.tap(find.bySemanticsLabel('Vorlesen'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  // ------------------------------------------------------------- success

  testWidgets('Success card shows a quiet thumbs-up, no illustration', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: SuccessFeedbackCard(
            title: 'Alle 6 Lücken gelöst',
            subtitle: 'Text abgeschlossen',
            explanation: 'Mit *since* steht das Present Perfect.',
            actionLabel: 'Zurück zu den Texten',
            onAction: () {},
          ),
        ),
      ),
    );
    expect(find.text('Alle 6 Lücken gelöst'), findsOneWidget);
    expect(find.text('Text abgeschlossen'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    // The explanation sets English forms apart, like the grammar rules.
    final explanation = find.byWidgetPredicate(
      (w) =>
          w is RichText &&
          w.text.toPlainText() == 'Mit since steht das Present Perfect.',
    );
    expect(explanation, findsOneWidget);
    final icon = tester.widget<Icon>(
      find.byIcon(CupertinoIcons.hand_thumbsup_fill),
    );
    expect(icon.color, AppColors.success);
    final disc = tester.widget<Container>(
      find
          .ancestor(
            of: find.byIcon(CupertinoIcons.hand_thumbsup_fill),
            matching: find.byType(Container),
          )
          .first,
    );
    expect((disc.decoration! as BoxDecoration).color, AppColors.successTint);
    final card = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('Alle 6 Lücken gelöst'),
            matching: find.byType(Container),
          )
          .last,
    );
    expect((card.decoration! as BoxDecoration).color, AppColors.raisedInk);
  });

  // -------------------------------------------------- listening & grammar

  test('Sample exercises are well formed', () {
    for (final e in [...sampleListeningExercises, ...sampleGrammarExercises]) {
      expect(e.options, contains(e.answer), reason: e.id);
      expect(e.options.toSet(), hasLength(e.options.length), reason: e.id);
      if (e.kind == PracticeKind.grammar) {
        expect(e.prompt.split(ChoiceExercise.gap), hasLength(2), reason: e.id);
      } else {
        expect(e.audioText, isNotNull, reason: e.id);
      }
    }
    final ids = [
      for (final e in [...sampleListeningExercises, ...sampleGrammarExercises])
        e.id,
    ];
    expect(ids.toSet(), hasLength(ids.length));
  });

  // Exercises are Premium content: opening one checks access.
  Widget practiceLibrary(PracticeKind kind, PracticeProgress progress) =>
      ProviderScope(
        overrides: [premiumContentAccessProvider.overrideWithValue(true)],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: kind == PracticeKind.listening
              ? ListeningLibraryScreen(
                  exercises: sampleListeningExercises,
                  progress: progress,
                )
              : GrammarLibraryScreen(
                  exercises: sampleGrammarExercises,
                  progress: progress,
                ),
        ),
      );

  testWidgets('Practice library lists every exercise, solved ones marked', (
    tester,
  ) async {
    final progress = PracticeProgress({'listen-w-v'});
    addTearDown(progress.dispose);
    await tester.pumpWidget(practiceLibrary(PracticeKind.listening, progress));
    expect(find.text('Hören'), findsOneWidget);
    expect(find.textContaining('fertig'), findsNothing);
    expect(find.text('Meine Übungen'), findsNothing);
    expect(find.text('Fertig'), findsNothing);
    expect(find.text('Das th in „think“'), findsOneWidget);
    expect(find.text('w oder v'), findsOneWidget);
    expect(
      tester.getSemantics(
        find.bySemanticsLabel(
          RegExp('^Das th in „think“, .*, Aussprache · Level 1\$'),
        ),
      ),
      isSemantics(isButton: true, hasTapAction: true),
    );
    expect(
      find.bySemanticsLabel(RegExp(r'^w oder v, .*, fertig$')),
      findsOneWidget,
    );
    expect(find.byIcon(CupertinoIcons.checkmark_alt_circle_fill), findsOne);
    expect(find.byIcon(CupertinoIcons.chevron_right), findsWidgets);
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));

    progress.complete('listen-th-think');
    await tester.pumpAndSettle();
    expect(
      find.byIcon(CupertinoIcons.checkmark_alt_circle_fill),
      findsNWidgets(2),
    );
  });

  /// The answer card labelled [option].
  Finder option(String option) => find
      .ancestor(of: find.text(option), matching: find.byType(AnimatedContainer))
      .first;

  BoxDecoration optionBox(WidgetTester tester, String label) =>
      tester.widget<AnimatedContainer>(option(label)).decoration!
          as BoxDecoration;

  testWidgets('Listening: wrong flashes, right stays sage and slides in', (
    tester,
  ) async {
    await mockNativeSpeech(tester);
    stillStage(tester);
    final progress = PracticeProgress();
    addTearDown(progress.dispose);
    await tester.pumpWidget(practiceLibrary(PracticeKind.listening, progress));
    await tester.tap(find.text('Das th in „think“'));
    await tester.pumpAndSettle();
    expect(find.byType(ListeningExerciseScreen), findsOneWidget);
    // The instruction is self-explanatory and left the screen.
    expect(
      find.text('Hör zu und wähle die Antwort, die du hörst.'),
      findsNothing,
    );
    expect(find.text('0:00'), findsNothing);
    expect(find.textContaining('ca. '), findsNothing);
    // Answers rest on the stage's veil (user request 01.11.2026).
    final idle = optionBox(tester, 'sink').color;
    expect(idle!.a, lessThan(0.2));

    // The native completion event, not elapsed wall time, ends playback.
    await tester.tap(find.bySemanticsLabel('Abspielen'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.bySemanticsLabel('Pause'), findsOneWidget);
    await completeSpeech();
    debugDefaultTargetPlatformOverride = null;
    await tester.pump(const Duration(seconds: 2));
    expect(find.bySemanticsLabel('Abspielen'), findsOneWidget);

    await tester.tap(find.text('sink'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      optionBox(tester, 'sink').color,
      AppColors.error.withValues(alpha: 0.26),
    );
    expect(
      (optionBox(tester, 'sink').border! as Border).top.color,
      AppColors.error,
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(optionBox(tester, 'sink').color, idle);
    expect(find.text('Nächste Übung'), findsNothing);
    expect(progress.isDone('listen-th-think'), isFalse);

    await tester.tap(find.text('think'));
    await tester.pumpAndSettle();
    expect(
      optionBox(tester, 'think').color,
      AppColors.success.withValues(alpha: 0.24),
    );
    expect(
      (optionBox(tester, 'think').border! as Border).top.color,
      AppColors.success,
    );
    expect(find.byIcon(CupertinoIcons.checkmark_alt), findsOneWidget);
    expect(
      find.byIcon(CupertinoIcons.checkmark_alt).hitTestable(),
      findsOneWidget,
    );
    // What was said, with its meaning; the other answers fold away.
    expect(find.text('Zu hören war: „think“'), findsOneWidget);
    expect(find.text('denken'), findsOneWidget);
    expect(progress.isDone('listen-th-think'), isTrue);
    expect(find.text('fink'), findsNothing);
    expect(find.text('sink'), findsNothing);
    expect(find.textContaining('Zungenspitze', findRichText: true), findsOneWidget);
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));

    // "Nächste Übung" replaces the screen with the next open exercise.
    await tester.tap(find.text('Nächste Übung'));
    await tester.pumpAndSettle();
    expect(find.text('w oder v'), findsWidgets);
    expect(find.text('Nächste Übung'), findsNothing);
    await tester.tap(find.bySemanticsLabel('Zurück'));
    await tester.pumpAndSettle();
    expect(find.byType(ListeningLibraryScreen), findsOneWidget);
  });

  testWidgets('Grammar: no player, the answer fills the gap', (tester) async {
    stillStage(tester);
    final progress = PracticeProgress();
    addTearDown(progress.dispose);
    final exercise = sampleGrammarExercises.firstWhere(
      (e) => e.id == 'grammar-since-present-perfect',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: ProviderScope(
          child: GrammarExerciseScreen(exercise: exercise, progress: progress),
        ),
      ),
    );
    expect(find.byType(Slider), findsNothing);
    expect(find.bySemanticsLabel('Abspielen'), findsNothing);
    expect(
      find.bySemanticsLabel('I Lücke in Hamburg since 2010.'),
      findsOneWidget,
    );

    await tester.tap(find.text('live'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      optionBox(tester, 'live').color,
      AppColors.error.withValues(alpha: 0.26),
    );
    await tester.pump(const Duration(milliseconds: 600));

    await tester.tap(find.text('have lived'));
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel('I have lived in Hamburg since 2010.'),
      findsOneWidget,
    );
    // German translation under the sentence, then the explanation.
    expect(find.text('Ich wohne seit 2010 in Hamburg.'), findsOneWidget);
    expect(
      find.textContaining('Present Perfect', findRichText: true),
      findsWidgets,
    );
    // No next exercise in an empty queue: back to the overview.
    expect(find.text('Zurück zur Übersicht'), findsOneWidget);
  });

  testWidgets('Hören and Grammatik open from the dashboard', (tester) async {
    await openContentTab(tester);
    final listening = find.bySemanticsLabel('Alle Hörübungen anzeigen');
    await tester.scrollUntilVisible(
      listening,
      200,
      scrollable: dashboardScrollable(),
    );
    await tester.tap(listening);
    await tester.pumpAndSettle();
    expect(find.byType(ListeningLibraryScreen), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Zurück'));
    await tester.pumpAndSettle();
    final grammar = find.bySemanticsLabel('Alle Grammatikübungen anzeigen');
    await tester.scrollUntilVisible(
      grammar,
      200,
      scrollable: dashboardScrollable(),
    );
    await tester.tap(grammar);
    await tester.pumpAndSettle();
    expect(find.byType(GrammarLibraryScreen), findsOneWidget);
  });

  testWidgets('Practice screens survive large Dynamic Type', (tester) async {
    stillStage(tester);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final progress = PracticeProgress();
    addTearDown(progress.dispose);
    await tester.pumpWidget(practiceLibrary(PracticeKind.listening, progress));
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.text('-teen oder -ty'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('-teen oder -ty'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // Large text scrolls the stage instead of overflowing it.
    await tester.dragUntilVisible(
      find.text('15'),
      find.byType(SingleChildScrollView).last,
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('15'));
    await tester.pumpAndSettle();
    expect(find.text('Nächste Übung'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  // ------------------------------------------------------- deck practice

  test('Word forms, form labels and the next Leitner box', () {
    expect(
      findWordForm('People talk with their neighbours.', 'neighbour')?.text,
      'neighbours',
    );
    expect(findWordForm('Clara arrived late.', 'arrive')?.text, 'arrived');
    expect(findWordForm('Two cities, one river.', 'city')?.text, 'cities');
    expect(findWordForm('The station was empty.', 'station'), (
      start: 4,
      end: 11,
      text: 'station',
    ));
    expect(findWordForm('Station closed.', 'station')?.text, 'Station');
    expect(findWordForm('She bought bread.', 'buy'), isNull);
    expect(findWordForm('A stationary bike.', 'station'), isNull);

    expect(
      formLabel('Substantiv', 'neighbour', 'neighbours'),
      'Substantiv, Plural',
    );
    expect(formLabel('Substantiv', 'ticket', 'ticket'), 'Substantiv');
    expect(formLabel('Verb', 'arrive', 'arrived'), 'Verb, Vergangenheit');
    expect(formLabel('Verb', 'borrow', 'borrowing'), 'Verb, -ing-Form');
    expect(formLabel('Adjektiv', 'quiet', 'quieter'), 'Adjektiv, Komparativ');

    expect(
      formKindOf('Substantiv', 'neighbour', 'neighbours'),
      FormKind.plural,
    );
    expect(formKindOf('Verb', 'borrow', 'borrow'), FormKind.base);
    // Explanations never name a word the learner may be asked for.
    final answers = [
      for (final w in sampleVocabulary(DateTime(2026))) w.entry.headword,
    ];
    for (final pos in ['Substantiv', 'Verb', 'Adjektiv', 'Adverb']) {
      for (final kind in FormKind.values) {
        final text = formExplanation(pos, kind);
        expect(text, startsWith('Gesucht ist'));
        for (final answer in answers) {
          expect(text, isNot(contains(answer)), reason: '$pos $kind');
        }
      }
    }

    expect(nextLeitnerBox(2, correct: true), 3);
    expect(nextLeitnerBox(5, correct: true), 5);
    expect(nextLeitnerBox(4, correct: false), 1);
    expect(nextLeitnerBox(3, correct: true, early: true), 3);
    expect(nextLeitnerBox(3, correct: false, early: true), 1);
  });

  // Repository-backed practice and its visual regressions: deck_flow_test.dart.

  // -------------------------------------------------------------- news

  test('Sample news: one article per desk, every sentence translated', () {
    expect(
      sampleNews.map((a) => a.category),
      unorderedEquals(NewsCategory.values),
    );
    expect(sampleNews.map((a) => a.id).toSet(), hasLength(sampleNews.length));
    for (final article in sampleNews) {
      final text = article.text;
      expect(text.paragraphs, hasLength(article.sections.length));
      for (final (i, section) in article.sections.indexed) {
        expect(text.headingBefore(i), section.heading);
        for (final range in splitSentences(section.paragraph)) {
          final sentence = section.paragraph.substring(range.start, range.end);
          expect(
            sampleTranslateSentence(sentence),
            isNot('Übersetzung folgt.'),
            reason: sentence,
          );
        }
      }
      expect(article.asStory.topic, article.category.label);
    }
    expect(NewsCategory.economy.kicker, 'WIRTSCHAFT');
    expect(sampleStoryText('last-train-to-seville').headingBefore(0), isNull);
  });

  Widget storyLibrary() => testScope(MaterialApp(
    theme: buildAppTheme(),
    home: Scaffold(
      body: StoryLibraryScreen(
        stories: sampleStories,
        progress: {
          sampleContinueReading.storyId: ReadingEntry(
            fraction: sampleContinueReading.fraction,
            updatedAt: DateTime(2026, 10, 20),
          ),
        },
        onOpenStory: (_) {},
        news: sampleNews,
        onOpenNews: (_) {},
      ),
    ),
  ));

  testWidgets('Nachrichten lead, then "Weiterlesen", own texts, categories', (
    tester,
  ) async {
    phoneView(tester);
    await tester.pumpWidget(storyLibrary());
    final news = find.widgetWithText(SectionHeading, 'Nachrichten');
    expect(news, findsOneWidget);
    expect(find.text('Demo'), findsOneWidget);
    expect(find.text(StoryLibraryScreen.newsSubheading), findsOneWidget);
    expect(find.textContaining('Zuletzt aktualisiert'), findsNothing);
    double top(Finder f) => tester.getTopLeft(f).dy;
    final resume = find.widgetWithText(SectionHeading, 'Weiterlesen');
    final own = find.widgetWithText(SectionHeading, 'Deine Texte');
    expect(top(news), lessThan(top(resume)));
    expect(top(resume), lessThan(top(own)));
    expect(
      top(own),
      lessThan(top(find.widgetWithText(SectionHeading, 'Reisen'))),
    );
    // The started story shows its position.
    expect(
      find.bySemanticsLabel(
        RegExp(r'^Weiterlesen: The Last Train to Seville, .*40 Prozent'),
      ),
      findsOneWidget,
    );

    // One heading and one sideways row per desk (user request 01.11.2026);
    // the first card starts on the 20pt gutter.
    for (final desk in NewsCategory.values) {
      expect(find.text(desk.label), findsWidgets);
    }
    final first = find.widgetWithText(NewsCard, 'Politik in 100 Sekunden');
    expect(tester.getTopLeft(first).dx, 20);
    expect(
      tester.getTopLeft(first).dx,
      tester.getTopLeft(find.text(StoryLibraryScreen.newsSubheading)).dx,
    );
    expect(tester.getSize(first), const Size(NewsCard.width, NewsCard.height));
    final second = find.widgetWithText(NewsCard, 'Wirtschaft in 100 Sekunden');
    expect(
      tester.getTopLeft(second).dy,
      greaterThan(tester.getBottomLeft(first).dy),
    );
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
  });

  NewsArticle daily(NewsCategory desk, int rank, String site) => NewsArticle(
    id: '2026-11-01-en-${desk.name}-$rank',
    category: desk,
    title: '${desk.label} $rank',
    level: 'B1',
    readingMinutes: 2,
    edition: DateTime.now(),
    sections: const [
      NewsSection(heading: 'First', paragraph: 'One thing. Two things.'),
    ],
    sources: [NewsSource(title: 'Report', url: Uri.parse('https://www.$site/a'))],
  );

  testWidgets('Daily news: desks with several articles, source as kicker', (
    tester,
  ) async {
    phoneView(tester);
    await tester.pumpWidget(testScope(MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(
        body: StoryLibraryScreen(
          stories: sampleStories,
          onOpenStory: (_) {},
          news: [
            for (var rank = 1; rank <= 4; rank++)
              daily(NewsCategory.politics, rank, 'reuters.com'),
            for (var rank = 1; rank <= 3; rank++)
              daily(NewsCategory.medicine, rank, 'bbc.com'),
          ],
          onOpenNews: (_) {},
        ),
      ),
    )));
    // Real news need no demo label; the day stands beside the heading.
    expect(find.text('Demo'), findsNothing);
    expect(find.text(StoryLibraryScreen.newsSubheading), findsNothing);
    expect(find.text('Heute'), findsOneWidget);
    expect(find.text('Wirtschaft'), findsNothing);
    final first = find.widgetWithText(NewsCard, 'Politik 1');
    final second = find.widgetWithText(NewsCard, 'Politik 2');
    expect(tester.getTopLeft(second).dy, tester.getTopLeft(first).dy);
    expect(tester.getTopLeft(second).dx, tester.getTopRight(first).dx + 12);
    expect(
      find.descendant(of: first, matching: find.text('REUTERS.COM')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        'Politik 1. Nachrichten, Politik, 2 Minuten Lesezeit, Niveau B1, '
        'Quelle reuters.com',
      ),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(find.widgetWithText(NewsCard, 'Medizin 1')).dy,
      greaterThan(tester.getBottomLeft(first).dy),
    );
  });

  testWidgets('News card: title and reading time, no image', (tester) async {
    phoneView(tester);
    await tester.pumpWidget(storyLibrary());
    final card = find.widgetWithText(NewsCard, 'Politik in 100 Sekunden');
    expect(card, findsOneWidget);
    expect(find.descendant(of: card, matching: find.byType(Image)), findsNothing);
    // Samples have no source: no kicker repeating the desk.
    expect(find.descendant(of: card, matching: find.text('POLITIK')), findsNothing);
    expect(find.descendant(of: card, matching: find.text('2 Min.')), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'Politik in 100 Sekunden. Nachrichten, Politik, 2 Minuten '
        'Lesezeit, Niveau A2',
      ),
      findsOneWidget,
    );
  });

  Widget newsReader() {
    final article = sampleNews.first;
    return ProviderScope(
      overrides: [
        offlineDictionaryProvider.overrideWithValue(EmptyDictionary()),
        // No account and no consent; keeps the private store off disk.
        runtimeTranslationProvider.overrideWithValue(
          RuntimeTranslationClient(
            'https://unused.invalid',
            'public',
            () async => 'synthetic',
          ),
        ),
      ],
      child: MaterialApp(
        theme: buildAppTheme(),
        home: StoryReaderScreen(story: article.asStory, text: article.text, narrationFactory: () => PlaybackClock.forText(article.text.paragraphs)),
      ),
    );
  }

  testWidgets('News read like stories, with bold subheadings', (tester) async {
    await tester.pumpWidget(newsReader());
    expect(find.text('Politik in 100 Sekunden'), findsOneWidget);
    // Only the topic shows; level and minutes stay in the semantics label.
    expect(find.text('Politik'), findsOneWidget);
    expect(find.text('A2 · 2 Min · Politik'), findsNothing);
    final heading = tester.widget<Text>(find.text('A new plan for city buses'));
    expect(heading.style?.fontWeight, FontWeight.w700);
    expect(heading.style?.fontSize, greaterThan(AppType.storyBody().fontSize!));
    expect(
      tester.getSemantics(find.text('Who pays for it?')),
      isSemantics(isHeader: true, label: 'Who pays for it?'),
    );

    // Missing word without consent: no opt-in text, no request on tap
    // (consent is asked in the onboarding).
    await tapWord(tester, 'council');
    expect(find.byType(RuntimeTranslationSheet), findsOneWidget);
    expect(find.text('Automatische Wortübersetzung aktivieren?'), findsNothing);
    expect(find.text('Wörterbuch · Quellen & Lizenz'), findsNothing);
    expect(find.textContaining('KI ·'), findsNothing);
    Navigator.of(tester.element(find.byType(RuntimeTranslationSheet))).pop();
    await tester.pumpAndSettle();

    // Sentence translation.
    await tester.tap(find.bySemanticsLabel('Übersetzen'));
    await tester.pumpAndSettle();
    await tapWord(tester, 'council');
    expect(find.byType(SentencePopover), findsOneWidget);
    expect(
      find.text(
        'Der Stadtrat hat am Dienstag für einen neuen Busplan gestimmt.',
      ),
      findsOneWidget,
    );
    Navigator.of(tester.element(find.byType(SentencePopover))).pop();
    await tester.pumpAndSettle();

    // Narration marks the first sentence, not the subheading.
    await tester.tap(find.bySemanticsLabel('Vorlesen'));
    await tester.pump();
    expect(spansOn(tester, AppColors.playback), [
      'The city council voted for a new bus plan on Tuesday. ',
    ]);
    await tester.tap(find.bySemanticsLabel('Vorlesen'));
    await tester.pump();
  });

  testWidgets('Daily news read with their own translations and sources', (
    tester,
  ) async {
    final article = NewsArticle.fromJson({
      'id': '2026-11-01-en-politics-1',
      'edition': '2026-11-01',
      'category': 'politics',
      'rank': 1,
      'title': 'Talks in Geneva',
      'level': 'B1',
      'reading_minutes': 1,
      'sections': [
        {
          'heading': 'The meeting',
          'sentences': [
            {'text': 'Leaders meet today.', 'de': 'Die Spitzen treffen sich heute.'},
            {'text': 'They talk about trade.', 'de': 'Sie sprechen über Handel.'},
          ],
        },
      ],
      'sources': [
        {'title': 'Talks open', 'url': 'https://www.reuters.com/world/talks'},
      ],
    }, 'en');
    expect(article.text.paragraphs, ['Leaders meet today. They talk about trade.']);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        offlineDictionaryProvider.overrideWithValue(EmptyDictionary()),
        runtimeTranslationProvider.overrideWithValue(
          RuntimeTranslationClient(
            'https://unused.invalid',
            'public',
            () async => 'synthetic',
          ),
        ),
      ],
      child: MaterialApp(
        theme: buildAppTheme(),
        home: Builder(
          builder: (context) => CupertinoButton(
            onPressed: () => StoryReaderScreen.openNews(context, article),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Übersetzen'));
    await tester.pumpAndSettle();
    await tapWord(tester, 'trade');
    // The stored German sentence, no AI request.
    expect(find.byType(SentencePopover), findsOneWidget);
    expect(find.text('Sie sprechen über Handel.'), findsOneWidget);
    Navigator.of(tester.element(find.byType(SentencePopover))).pop();
    await tester.pumpAndSettle();
    final sources = find.text('Quellen');
    await tester.scrollUntilVisible(sources, 200,
        scrollable: find.byType(Scrollable).first);
    expect(sources, findsOneWidget);
    expect(find.bySemanticsLabel('Talks open, reuters.com'), findsOneWidget);
  });

  testWidgets('The app shows no "Nachrichten" until the daily news return', (
    tester,
  ) async {
    // User decision 01.11.2026: hidden for now, back later with real news.
    await tester.pumpWidget(testScope(const SprachApp(), library: true));
    await tester.pumpAndSettle();
    await openStoriesTab(tester);
    expect(find.widgetWithText(SectionHeading, 'Nachrichten'), findsNothing);
    expect(find.byType(NewsCard), findsNothing);
    expect(find.text('Demo'), findsNothing);
  });

  testWidgets('Stories tab with news survives large Dynamic Type', (
    tester,
  ) async {
    phoneView(tester, height: 844);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(storyLibrary());
    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(newsReader());
    expect(tester.takeException(), isNull);
  });
}

/// The exercise stage drifts while open; settling needs reduced motion.
void stillStage(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}
