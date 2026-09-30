import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:sprachapp/main.dart';
import 'package:sprachapp/models/home_models.dart';
import 'package:sprachapp/models/sample_content.dart';
import 'package:sprachapp/models/story_models.dart';
import 'package:sprachapp/screens/home/widgets/story_carousel.dart';
import 'package:sprachapp/screens/home/widgets/vocab_progress.dart';
import 'package:sprachapp/screens/stories/story_library_screen.dart';
import 'package:sprachapp/screens/stories/story_reader_screen.dart';
import 'package:sprachapp/screens/stories/widgets/word_lookup_sheet.dart';
import 'package:sprachapp/theme/app_theme.dart';
import 'package:sprachapp/widgets/app_bottom_bar.dart';
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

    expect(find.text('Englisch A2'), findsOneWidget);
    expect(find.bySemanticsLabel('14 Tage Lernserie'), findsOneWidget);
    expect(find.text('Aktive Stapel'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Reisen & Unterwegs, 42 Prozent')),
      findsOneWidget,
    );
    await scrollHomeTo(tester, find.text('Mehr entdecken'));
    expect(find.text('Stories'), findsWidgets);
    expect(find.text('Mehr entdecken'), findsOneWidget);
    expect(find.bySemanticsLabel('Tägliche Übung starten'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Custom-labelled controls stay activatable for VoiceOver', (
    tester,
  ) async {
    await tester.pumpWidget(const SprachApp());
    await scrollHomeTo(tester, find.byType(StoryCarousel));
    for (final label in [
      'Tägliche Übung starten',
      'Reisen & Unterwegs, 42 Prozent gemeistert',
      'The Last Train to Seville. Reisen, 4 Minuten Lesezeit, Niveau A2',
    ]) {
      expect(
        tester.getSemantics(find.bySemanticsLabel(label)),
        isSemantics(isButton: true, hasTapAction: true),
        reason: label,
      );
    }
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

  testWidgets('No flame and no status ink on the practice button', (
    tester,
  ) async {
    await tester.pumpWidget(const SprachApp());
    expect(find.byIcon(CupertinoIcons.flame_fill), findsNothing);
    final button = find.bySemanticsLabel('Tägliche Übung starten');
    final inked = find.descendant(
      of: find.ancestor(of: button, matching: find.byType(CupertinoButton)),
      matching: find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            {
              AppColors.mastered,
              AppColors.active,
            }.contains((w.decoration! as BoxDecoration).color),
      ),
    );
    expect(inked, findsNothing);
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
}
