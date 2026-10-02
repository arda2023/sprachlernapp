import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:sprachapp/domain/answer_check.dart';
import 'package:sprachapp/domain/sentences.dart';
import 'package:sprachapp/main.dart';
import 'package:sprachapp/models/exercise_models.dart';
import 'package:sprachapp/models/reading_history.dart';
import 'package:sprachapp/screens/content/content_dashboard_screen.dart';
import 'package:sprachapp/screens/content/text_exercise_screen.dart';
import 'package:sprachapp/screens/content/text_library_screen.dart';
import 'package:sprachapp/screens/content/widgets/exercise_choice_sheet.dart';
import 'package:sprachapp/screens/home/widgets/story_carousel.dart';
import 'package:sprachapp/models/home_models.dart';
import 'package:sprachapp/models/sample_content.dart';
import 'package:sprachapp/models/story_models.dart';
import 'package:sprachapp/screens/decks/deck_details_screen.dart';
import 'package:sprachapp/screens/decks/deck_library_screen.dart';
import 'package:sprachapp/screens/home/widgets/deck_tile.dart';
import 'package:sprachapp/screens/home/widgets/vocab_progress.dart';
import 'package:sprachapp/screens/home/widgets/weekly_goal_card.dart';
import 'package:sprachapp/screens/stories/story_library_screen.dart';
import 'package:sprachapp/screens/stories/story_reader_screen.dart';
import 'package:sprachapp/screens/stories/widgets/word_lookup_sheet.dart';
import 'package:sprachapp/theme/app_theme.dart';
import 'package:sprachapp/widgets/app_bottom_bar.dart';
import 'package:sprachapp/widgets/difficulty_bolts.dart';
import 'package:sprachapp/widgets/progress_ring.dart';
import 'package:sprachapp/widgets/reading_toolbar.dart';
import 'package:sprachapp/widgets/sentence_translation_sheet.dart';
import 'package:sprachapp/widgets/section_heading.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

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
    await tester.pumpWidget(const SprachApp());

    expect(find.bySemanticsLabel('Zielsprache: Englisch'), findsOneWidget);
    expect(find.textContaining('A2'), findsNothing);
    expect(find.textContaining('Tage'), findsNothing);
    final reisen = find.bySemanticsLabel(
      RegExp('Reisen & Unterwegs, 42 Prozent'),
    );
    await scrollHomeTo(tester, reisen);
    expect(find.text('Aktive Stapel'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Reisen & Unterwegs, 42 Prozent')),
      findsOneWidget,
    );
    await scrollHomeTo(tester, find.text('Mehr entdecken'));
    expect(find.text('Stories'), findsWidgets);
    expect(find.text('Mehr entdecken'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Lernen, Tagesziel 4 von 10 Wörtern'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Custom-labelled controls stay activatable for VoiceOver', (
    tester,
  ) async {
    await tester.pumpWidget(const SprachApp());
    void expectButton(String label) => expect(
      tester.getSemantics(find.bySemanticsLabel(label)),
      isSemantics(isButton: true, hasTapAction: true),
      reason: label,
    );
    for (final label in [
      'Lernen, Tagesziel 4 von 10 Wörtern',
      'Profil',
      'Einstellungen',
      'Tagesziel ändern',
    ]) {
      expectButton(label);
    }
    const reisen =
        'Reisen & Unterwegs, 42 Prozent gemeistert, '
        'Schwierigkeit Einsteiger, aktiv';
    await scrollHomeTo(tester, find.bySemanticsLabel(reisen));
    expectButton(reisen);
    const story =
        'The Last Train to Seville. Reisen, 4 Minuten Lesezeit, Niveau A2';
    await scrollHomeTo(tester, find.bySemanticsLabel(story));
    expectButton(story);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Home')),
      isSemantics(isButton: true, isSelected: true, hasTapAction: true),
    );
  });

  testWidgets('Tappable controls meet the 44pt minimum', (tester) async {
    await tester.pumpWidget(const SprachApp());
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
  });

  testWidgets('Layout survives large Dynamic Type', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const SprachApp());
    expect(tester.takeException(), isNull);
  });

  testWidgets('Vocab track paints mastered and active segments', (
    tester,
  ) async {
    await tester.pumpWidget(const SprachApp());
    for (final color in [AppColors.mastered, AppColors.active]) {
      final segment = find.byWidgetPredicate(
        (w) => w is ColoredBox && w.color == color && w.child == null,
      );
      final size = tester.getSize(segment.first);
      expect(size.height, 8, reason: '$color segment height');
      expect(size.width, greaterThan(0), reason: '$color segment width');
    }
  });

  test('German thousands separator', () {
    expect(formatCountDe(3000), '3.000');
    expect(formatCountDe(180), '180');
    expect(formatCountDe(1234567), '1.234.567');
  });

  testWidgets('Notched bar docks a neutral practice button with goal ring', (
    tester,
  ) async {
    await tester.pumpWidget(const SprachApp());
    expect(find.byIcon(CupertinoIcons.flame_fill), findsNothing);

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
    expect(ring.color, AppColors.textMuted);
    expect(ring.fraction, 0.4);

    final tabs = find.byType(AppBottomBar);
    expect(find.descendant(of: tabs, matching: find.text('Lernen')), findsOne);
    expect(find.descendant(of: tabs, matching: find.text('Inhalte')), findsOne);
    expect(
      find.descendant(of: tabs, matching: find.text('Profil')),
      findsNothing,
    );
  });

  testWidgets('Week row shows met, missed and today without a count', (
    tester,
  ) async {
    await tester.pumpWidget(const SprachApp());
    final card = find.byType(WeeklyGoalCard);
    expect(
      find.bySemanticsLabel(
        'Diese Woche: Montag erreicht, Dienstag erreicht, Mittwoch verfehlt, '
        'Donnerstag erreicht, Freitag heute, Samstag offen, Sonntag offen',
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: card,
        matching: find.byIcon(CupertinoIcons.checkmark),
      ),
      findsNWidgets(3),
    );
    expect(
      find.descendant(of: card, matching: find.byIcon(CupertinoIcons.xmark)),
      findsOneWidget,
    );
    final inked = find.descendant(
      of: card,
      matching: find.byWidgetPredicate(
        (w) =>
            (w is Icon &&
                {AppColors.active, AppColors.mastered}.contains(w.color)) ||
            (w is Text &&
                {
                  AppColors.active,
                  AppColors.mastered,
                }.contains(w.style?.color)),
      ),
    );
    expect(inked, findsNothing);
  });

  testWidgets('Gear changes the daily goal everywhere', (tester) async {
    await tester.pumpWidget(const SprachApp());
    await tester.tap(find.bySemanticsLabel('Tagesziel ändern'));
    await tester.pumpAndSettle();
    expect(find.text('Tagesziel'), findsOneWidget);
    await tester.tap(find.text('20 Wörter pro Tag'));
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel('Tagesziel: 4 von 20 Wörtern'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Lernen, Tagesziel 4 von 20 Wörtern'),
      findsOneWidget,
    );
  });

  testWidgets('Deck tiles show ring, bolts and active state', (tester) async {
    await tester.pumpWidget(const SprachApp());
    await scrollHomeTo(tester, find.bySemanticsLabel(RegExp('^Medizin,')));

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

    final active = tileBox('Reisen & Unterwegs');
    expect(active.color, AppColors.activeTint);
    expect((active.border! as Border).top.color, AppColors.active);
    final inactive = tileBox('Medizin');
    expect(inactive.color, AppColors.raisedInk);
    expect((inactive.border! as Border).top.color, AppColors.hairline);

    expect(
      find.bySemanticsLabel(
        'Medizin, 6 Prozent gemeistert, Schwierigkeit Fortgeschritten',
      ),
      findsOneWidget,
    );
    expect(find.text('6% gemeistert'), findsOneWidget);
    final medizin = find.widgetWithText(DeckTile, 'Medizin');
    final ring = tester.widget<ProgressRing>(
      find.descendant(of: medizin, matching: find.byType(ProgressRing)),
    );
    expect(ring.color, AppColors.mastered);
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
    await tester.pumpWidget(const SprachApp());
    await scrollHomeTo(tester, find.text('Mehr ansehen'));
    await tester.tap(find.text('Mehr ansehen'));
    await tester.pumpAndSettle();
    expect(find.byType(DeckLibraryScreen), findsOneWidget);
    expect(find.text('2 aktiv · 6 Stapel'), findsOneWidget);
    expect(find.widgetWithText(SectionHeading, 'Aktiv'), findsOneWidget);
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
  });

  Future<void> openMedizin(WidgetTester tester) async {
    await tester.pumpWidget(const SprachApp());
    final tile = find.bySemanticsLabel(RegExp('^Medizin,'));
    await scrollHomeTo(tester, tile);
    await tester.tap(tile);
    await tester.pumpAndSettle();
  }

  testWidgets('Deck details orient first, then act', (tester) async {
    await openMedizin(tester);
    expect(find.byType(DeckDetailsScreen), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        '53 von 532 neuen Wörtern gesehen, 30 Wörter gelernt',
      ),
      findsOneWidget,
    );
    expect(find.text('Fortgeschritten'), findsOneWidget);
    for (final label in [
      'Lerne mit diesem Stapel',
      'Deine letzten 5 gesehenen Wörter',
    ]) {
      expect(
        tester.getSemantics(find.bySemanticsLabel(label)),
        isSemantics(isButton: true, hasTapAction: true),
        reason: label,
      );
    }
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));

    await tester.tap(find.text('Deine letzten 5 gesehenen Wörter'));
    await tester.pumpAndSettle();
    expect(find.text('prescription'), findsOneWidget);
    expect(find.text('das Rezept'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Stapel nochmals durchsehen'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Stapel-Revue'), findsOneWidget);
  });

  testWidgets('"Stapel lernen" toggles the deck on every screen', (
    tester,
  ) async {
    await openMedizin(tester);
    final toggle = tester.widget<CupertinoSwitch>(find.byType(CupertinoSwitch));
    expect(toggle.value, isFalse);
    expect(toggle.activeTrackColor, AppColors.textMuted);

    await tester.tap(find.byType(CupertinoSwitch));
    await tester.pumpAndSettle();
    expect(
      tester.widget<CupertinoSwitch>(find.byType(CupertinoSwitch)).value,
      isTrue,
    );

    await tester.tap(find.bySemanticsLabel('Zurück'));
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel(
        'Medizin, 6 Prozent gemeistert, Schwierigkeit Fortgeschritten, aktiv',
      ),
      findsOneWidget,
    );
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
    await tester.tap(recent);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home shows the four derived categories and the daily goal', (
    tester,
  ) async {
    await tester.pumpWidget(const SprachApp());
    expect(
      find.bySemanticsLabel(RegExp('12 Wiederholungen verfügbar')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Tagesziel: 4 von 10 Wörtern'),
      findsOneWidget,
    );
  });

  test('Vocabulary categories always sum to the total', () {
    const b = VocabBreakdown(due: 3, building: 5, mastered: 7, unseen: 11);
    expect(b.total, 26);
  });

  testWidgets('Stories tab groups carousels by topic', (tester) async {
    await tester.pumpWidget(const SprachApp());
    await scrollHomeTo(tester, find.text('Mehr entdecken'));
    await tester.tap(find.text('Mehr entdecken'));
    await tester.pumpAndSettle();
    expect(find.byType(StoryLibraryScreen), findsOneWidget);
    expect(find.text('Weiterlesen'), findsOneWidget);
    expect(find.widgetWithText(SectionHeading, 'Reisen'), findsOneWidget);
    expect(find.text('3 Stories'), findsWidgets);
    expect(
      find.bySemanticsLabel(RegExp('^Weiterlesen: The Last Train')),
      findsOneWidget,
    );
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
  });

  testWidgets('Stories tab survives large Dynamic Type', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const SprachApp());
    await openStoriesTab(tester);
    expect(find.byType(StoryLibraryScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  StoryReaderScreen readerScreen() => StoryReaderScreen(
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

  testWidgets('Tapping a word opens the lookup sheet and adds it', (
    tester,
  ) async {
    await tester.pumpWidget(reader());
    await tapWord(tester, 'arrived');

    expect(find.byType(WordLookupSheet), findsOneWidget);
    expect(find.text('ankommen'), findsOneWidget);
    expect(find.text('im Text: arrived'), findsOneWidget);
    expect(find.textContaining('Verb', findRichText: true), findsWidgets);

    final add = find.bySemanticsLabel('Zum Lernen hinzufügen');
    expect(
      tester.getSemantics(add),
      isSemantics(isButton: true, hasTapAction: true, isEnabled: true),
    );
    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Wird gelernt'), findsOneWidget);
  });

  testWidgets('Lookup sheet uses neutral chrome and no shadow', (tester) async {
    await tester.pumpWidget(reader());
    await tapWord(tester, 'clock');

    final sheet = tester.widget<Material>(
      find
          .ancestor(
            of: find.byType(WordLookupSheet),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(sheet.color, AppColors.raisedInk);
    expect(sheet.elevation, 0);

    final button = find.byType(AddToLearningButton);
    final decorations = tester
        .widgetList<Container>(
          find.descendant(of: button, matching: find.byType(Container)),
        )
        .map((c) => c.decoration)
        .whereType<BoxDecoration>();
    for (final d in decorations) {
      expect(d.color, isNot(anyOf(AppColors.mastered, AppColors.active)));
      expect(d.boxShadow, isNull);
    }
    final icon = tester.widget<Icon>(
      find.descendant(of: button, matching: find.byType(Icon)),
    );
    expect(icon.color, AppColors.textPrimary);
  });

  testWidgets('Known words keep their status without a downgrade', (
    tester,
  ) async {
    await tester.pumpWidget(reader());
    await tapWord(tester, 'station');
    expect(find.bySemanticsLabel('Bereits gemeistert'), findsOneWidget);
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
    await tester.pumpWidget(const SprachApp());
    await tester.tap(
      find.descendant(
        of: find.byType(AppBottomBar),
        matching: find.text('Inhalte'),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Inhalte tab is a dashboard with decks and a category grid', (
    tester,
  ) async {
    await openContentTab(tester);
    expect(find.byType(ContentDashboardScreen), findsOneWidget);
    expect(find.widgetWithText(SectionHeading, 'Stapel'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Grammatikregeln'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(ContentDashboardScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Texte, 5 Texte')),
      isSemantics(isButton: true, hasTapAction: true, isEnabled: true),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Hören, Bald verfügbar')),
      isSemantics(isButton: true, isEnabled: false),
    );
    // Cards fill their grid column, whatever their text length.
    final texte = tester.getSize(find.bySemanticsLabel('Texte, 5 Texte'));
    final regeln = tester.getSize(
      find.bySemanticsLabel('Grammatikregeln, Bald verfügbar'),
    );
    expect(texte.width, regeln.width);
    expect(texte.width, greaterThan(150));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
  });

  testWidgets('Dashboard survives large Dynamic Type', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await openContentTab(tester);
    await tester.drag(
      find.byType(ContentDashboardScreen),
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('"Alle Stapel" pushes the deck library with a back bar', (
    tester,
  ) async {
    await openContentTab(tester);
    await tester.tap(find.bySemanticsLabel(RegExp('^Alle Stapel')));
    await tester.pumpAndSettle();
    expect(find.byType(DeckLibraryScreen), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Zurück'));
    await tester.pumpAndSettle();
    expect(find.byType(DeckLibraryScreen), findsNothing);
  });

  // ----------------------------------------------------------- text library

  Widget textLibrary(ReadingHistory history) => MaterialApp(
    theme: buildAppTheme(),
    home: TextLibraryScreen(texts: sampleExerciseTexts, history: history),
  );

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
    await tester.pumpWidget(const SprachApp());
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
    final texte = find.bySemanticsLabel('Texte, 5 Texte');
    await tester.scrollUntilVisible(
      texte,
      200,
      scrollable: find
          .descendant(
            of: find.byType(ContentDashboardScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(texte);
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
    await tester.tap(find.bySemanticsLabel(RegExp(r'^A Slow Morning\.')));
    await tester.pumpAndSettle();
    expect(find.byType(ExerciseChoiceSheet), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'Lückentext-Übungen: Verben. Tippe die passende Verbform · 6 Lücken',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Beliebige Wortart'));
    await tester.pumpAndSettle();
    expect(find.byType(TextExerciseScreen), findsOneWidget);
    expect(find.text('0 von 9'), findsOneWidget);
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
    expect(find.byType(TextField), findsNWidgets(6));
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
    expect(find.byType(TextField), findsNWidgets(5));
    expect(find.text('1 von 6'), findsOneWidget);
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
    expect(chipBox(tester, 'left').color, AppColors.nightPage);

    await tester.tap(chip('ran'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(chipBox(tester, 'ran').color, AppColors.errorTint);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(chipBox(tester, 'ran').color, AppColors.nightPage);

    await tester.tap(chip('left'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(chipBox(tester, 'left').color, AppColors.successTint);
    await tester.pumpAndSettle();
    expect(find.text('1 von 6'), findsOneWidget);

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
    expect(find.byType(WordLookupSheet), findsNothing);
    expect(find.byType(SentenceTranslationSheet), findsOneWidget);
    expect(
      find.text('The station was almost empty when Clara arrived.'),
      findsOneWidget,
    );
    expect(
      find.text('Der Bahnhof war fast leer, als Clara ankam.'),
      findsOneWidget,
    );
  });

  testWidgets('Exercise translation hides unsolved answers', (tester) async {
    await tester.pumpWidget(exercise('slow-morning', ExerciseMode.verbs));
    await tester.tap(find.bySemanticsLabel('Übersetzen'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);

    await tapWord(tester, 'Sunday');
    expect(find.text('Tom … up late on Sunday.'), findsOneWidget);
    expect(find.text('Tom wachte am Sonntag spät auf.'), findsOneWidget);
  });
}
