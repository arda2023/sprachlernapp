import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:sprachapp/domain/answer_check.dart';
import 'package:sprachapp/domain/leitner.dart';
import 'package:sprachapp/domain/sentences.dart';
import 'package:sprachapp/main.dart';
import 'package:sprachapp/models/exercise_models.dart';
import 'package:sprachapp/models/grammar_models.dart';
import 'package:sprachapp/models/reading_history.dart';
import 'package:sprachapp/screens/content/content_dashboard_screen.dart';
import 'package:sprachapp/screens/content/text_exercise_screen.dart';
import 'package:sprachapp/screens/content/text_library_screen.dart';
import 'package:sprachapp/screens/content/widgets/exercise_choice_sheet.dart';
import 'package:sprachapp/screens/home/widgets/story_carousel.dart';
import 'package:sprachapp/models/home_models.dart';
import 'package:sprachapp/models/sample_content.dart';
import 'package:sprachapp/models/story_models.dart';
import 'package:sprachapp/models/story_narration.dart';
import 'package:sprachapp/models/word_list_models.dart';
import 'package:sprachapp/models/word_list_store.dart';
import 'package:sprachapp/screens/decks/deck_details_screen.dart';
import 'package:sprachapp/screens/decks/deck_library_screen.dart';
import 'package:sprachapp/screens/grammar/grammar_rule_detail_screen.dart';
import 'package:sprachapp/screens/grammar/grammar_rules_screen.dart';
import 'package:sprachapp/screens/home/widgets/deck_tile.dart';
import 'package:sprachapp/screens/home/widgets/vocab_progress.dart';
import 'package:sprachapp/screens/home/widgets/weekly_goal_card.dart';
import 'package:sprachapp/screens/stories/story_library_screen.dart';
import 'package:sprachapp/screens/stories/story_reader_screen.dart';
import 'package:sprachapp/screens/stories/widgets/narration_panel.dart';
import 'package:sprachapp/screens/stories/widgets/word_lookup_sheet.dart';
import 'package:sprachapp/screens/words/widgets/memory_level_legend_sheet.dart';
import 'package:sprachapp/screens/words/widgets/word_details_sheet.dart';
import 'package:sprachapp/screens/words/widgets/word_list_item.dart';
import 'package:sprachapp/screens/words/word_list_screen.dart';
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
      find.bySemanticsLabel('Grammatikregeln, 9 Regeln'),
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

  final wordListNow = DateTime(2026, 10, 2, 12);

  Widget wordList([WordListStore? store]) => MaterialApp(
    theme: buildAppTheme(),
    home: Scaffold(
      body: WordListScreen(
        store: store ?? WordListStore(sampleVocabulary(wordListNow)),
        clock: () => wordListNow,
      ),
    ),
  );

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
    await tester.pumpWidget(const SprachApp());
    await tester.tap(
      find.descendant(
        of: find.byType(AppBottomBar),
        matching: find.text('Wortliste'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(WordListScreen), findsOneWidget);
    expect(find.text('Wörter suchen'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^Playlist, \d+ Wörter$')), findsOne);
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

  testWidgets('Word card shows level, sentence and metadata', (tester) async {
    phoneView(tester);
    await tester.pumpWidget(wordList());
    expect(find.text('platform'), findsOneWidget);
    expect(
      find.text('Anna ran to the platform, but the doors were already closed.'),
      findsOneWidget,
    );
    expect(
      find.text('Zuletzt gesehen: vor 2 Tagen · Wiederholt: 5 Mal'),
      findsOneWidget,
    );
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
    expect(find.byIcon(CupertinoIcons.speaker_2_fill), findsNothing);

    await tester.tap(find.bySemanticsLabel('platform anhören'));
    await tester.pump();
    expect(marks(), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.speaker_2_fill), findsOneWidget);

    // Starting the sentence stops the word: one mark at a time.
    await tester.tap(find.bySemanticsLabel(RegExp('^Satz anhören: Anna ran')));
    await tester.pump();
    expect(marks(), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.speaker_2_fill), findsNothing);

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

    expect(
      tester.getSemantics(toggle('Deaktiviert')),
      isSemantics(isButton: true, hasToggledState: true, isToggled: false),
    );
    await tester.tap(toggle('Deaktiviert'));
    await tester.pump();
    expect(find.text('Wort deaktiviert'), findsOneWidget);
    expect(store.byId('platform').isDisabled, isTrue);
    expect(
      find.textContaining('Deaktiviert · Zuletzt gesehen: vor 2 Tagen'),
      findsOneWidget,
    );
    expect(
      tester.getSemantics(toggle('Deaktiviert')),
      isSemantics(isButton: true, hasToggledState: true, isToggled: true),
    );

    // Already in the playlist: tapping removes it.
    await tester.tap(toggle('In der Playlist'));
    await tester.pump();
    expect(find.text('Aus der Playlist entfernt'), findsOneWidget);

    await tester.tap(toggle('Favorit'));
    await tester.pump();
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
        RegExp('^Stufe 3 von 5: Gut verankert.*Dieses Wort'),
      ),
      findsOneWidget,
    );
    expect(find.text('Dieses Wort'), findsOneWidget);
  });

  testWidgets('Chevron opens the details sheet; notes are kept', (
    tester,
  ) async {
    phoneView(tester);
    final store = WordListStore(sampleVocabulary(wordListNow));
    await tester.pumpWidget(wordList(store));
    await tester.tap(find.bySemanticsLabel('Details zu platform'));
    await tester.pumpAndSettle();
    final sheet = find.byType(WordDetailsSheet);
    expect(sheet, findsOneWidget);
    Finder inSheet(Finder f) => find.descendant(of: sheet, matching: f);
    expect(inSheet(find.text('der Bahnsteig')), findsOneWidget);
    expect(inSheet(find.text('Substantiv')), findsOneWidget);
    expect(inSheet(find.text('vor 2 Tagen')), findsOneWidget);
    expect(inSheet(find.text('5 Mal')), findsOneWidget);
    expect(inSheet(find.text('Zeit zwischen Wiederholungen')), findsOneWidget);
    expect(inSheet(find.text('14 Tage')), findsOneWidget);
    expect(
      inSheet(
        find.text(
          'Anna rannte zum Bahnsteig, aber die Türen waren schon geschlossen.',
        ),
      ),
      findsOneWidget,
    );

    await tester.tap(inSheet(find.bySemanticsLabel('platform anhören')));
    await tester.pump();
    expect(inSheet(find.byIcon(CupertinoIcons.speaker_2_fill)), findsOneWidget);

    await tester.ensureVisible(inSheet(find.byType(TextField)));
    await tester.enterText(inSheet(find.byType(TextField)), 'Gleis = track');
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
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(
      find.bySemanticsLabel(RegExp('^Details zu')).hitTestable().first,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    Navigator.of(tester.element(find.byType(WordDetailsSheet))).pop();
    await tester.pumpAndSettle();

    await tester.tap(
      find.bySemanticsLabel(RegExp('^Erinnerungsstufe')).hitTestable().first,
    );
    await tester.pumpAndSettle();
    expect(find.byType(MemoryLevelLegendSheet), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Word rows sit on the Night Page with a Hairline rule', (
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
    // No card: nothing in the row is outlined or filled with Raised Ink.
    expect(
      boxes.where((d) => d.border is Border && d.shape != BoxShape.circle),
      isEmpty,
    );
    expect(boxes.where((d) => d.color == AppColors.raisedInk), isEmpty);
    final rule = find.descendant(
      of: find.byType(WordListItem).first,
      matching: find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.color == AppColors.hairline &&
            w.constraints?.maxHeight == 1,
      ),
    );
    expect(rule, findsOneWidget);
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
    // Clear the notched bar before tapping.
    await tester.drag(
      find.byType(ContentDashboardScreen),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Grammatikregeln, 9 Regeln'));
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
    final narration = StoryNarration.forText(['one two three']);
    expect(narration.duration, const Duration(seconds: 10));
    narration.skip(const Duration(seconds: -15));
    expect(narration.position, Duration.zero);
    narration.skip(StoryNarration.skipStep);
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
        home: Scaffold(body: SuccessFeedbackCard(total: 6, onBack: () {})),
      ),
    );
    expect(find.text('Alle 6 Lücken gelöst'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
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
}
