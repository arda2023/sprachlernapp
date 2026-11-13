import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/domain/content.dart';
import 'package:sprachapp/models/home_models.dart';
import 'package:sprachapp/screens/decks/widgets/practice_input.dart';
import 'package:sprachapp/screens/decks/widgets/practice_sentence.dart';
import 'package:sprachapp/screens/home/widgets/story_carousel.dart';

import '../fixtures/accessibility_fonts.dart';
import 'accessibility_test_app.dart';

Future<void> _practice(
  WidgetTester tester, {
  required PracticeInputController input,
  required FocusNode focus,
  double scale = 1,
  String sentence = 'Mia walks home.',
  String answer = 'walks',
  int? selectedStart,
  ValueChanged<WordAnchor>? onWord,
}) async {
  final start = sentence.indexOf(answer);
  await tester.pumpWidget(
    accessibilityTestApp(
      textScale: scale,
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: PracticeSentence(
            sentence: CardSentence(
              cardId: 'accessibility-card',
              sentenceId: sentence,
              position: 1,
              text: sentence,
              gapStart: start,
              gapEnd: start + answer.length,
            ),
            input: input,
            focus: focus,
            solved: false,
            selectedStart: selectedStart,
            onSubmit: () {},
            onChanged: () {},
            onWord: onWord ?? (_) {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAccessibilityFonts);

  testWidgets('practice words and editor scale exactly once', (tester) async {
    usePhoneViewport(tester);
    final input = PracticeInputController()..text = 'walks';
    final focus = FocusNode();
    try {
      await _practice(tester, input: input, focus: focus);
      final wordAtOne = tester.getSize(find.text('Mia'));
      final fieldAtOne = tester
          .state<EditableTextState>(find.byType(EditableText))
          .renderEditable
          .size;
      await _practice(tester, input: input, focus: focus, scale: 2);
      final wordAtTwo = tester.getSize(find.text('Mia'));
      final fieldAtTwo = tester
          .state<EditableTextState>(find.byType(EditableText))
          .renderEditable
          .size;
      expect(wordAtTwo.width, closeTo(wordAtOne.width * 2, 0.1));
      expect(wordAtTwo.height, closeTo(wordAtOne.height * 2, 0.1));
      expect(fieldAtTwo.height, closeTo(fieldAtOne.height * 2, 0.1));
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      input.dispose();
      focus.dispose();
    }
  });

  testWidgets('expanded word hit area works outside the glyphs', (
    tester,
  ) async {
    usePhoneViewport(tester);
    final semantics = tester.ensureSemantics();
    final input = PracticeInputController();
    final focus = FocusNode();
    final anchors = <WordAnchor>[];
    try {
      await _practice(
        tester,
        input: input,
        focus: focus,
        sentence: 'I walk home.',
        answer: 'walk',
        onWord: anchors.add,
      );
      final target = tester.getRect(
        find.bySemanticsLabel('I, Übersetzung anzeigen'),
      );
      final glyph = tester.getRect(find.text('I'));
      expect(target.width, greaterThanOrEqualTo(44));
      expect(target.height, greaterThanOrEqualTo(44));
      final point = target.bottomRight - const Offset(1, 1);
      expect(glyph.contains(point), isFalse);
      await tester.tapAt(point);
      await tester.pump();
      expect(anchors, hasLength(1));
      expect(anchors.single.start, 0);
      expect(anchors.single.rect, glyph);
      await expectAccessible(tester);
      await _practice(
        tester,
        input: input,
        focus: focus,
        sentence: 'I walk home.',
        answer: 'walk',
        selectedStart: 0,
      );
      final remainingWord = find.text('home');
      final color = tester.widget<Text>(remainingWord).style!.color!;
      expect(
        contrastRatio(
          color,
          Theme.of(tester.element(remainingWord)).scaffoldBackgroundColor,
        ),
        greaterThanOrEqualTo(3),
        reason:
            'Other tappable 24 pt words remain readable while one is selected',
      );
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      semantics.dispose();
      input.dispose();
      focus.dispose();
    }
  });

  testWidgets('a long unbroken practice word wraps at large text', (
    tester,
  ) async {
    usePhoneViewport(tester, size: const Size(320, 760));
    final input = PracticeInputController();
    final focus = FocusNode();
    try {
      await _practice(
        tester,
        input: input,
        focus: focus,
        scale: 2,
        sentence: 'A supercalifragilisticexpialidocious friend walks home.',
      );
      expect(tester.takeException(), isNull);
      final word = tester.getSize(
        find.text('supercalifragilisticexpialidocious'),
      );
      expect(word.width, lessThanOrEqualTo(280));
      expect(word.height, greaterThan(72));
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      input.dispose();
      focus.dispose();
    }
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('ghost and typed prefix stay aligned at $scale', (
      tester,
    ) async {
      usePhoneViewport(tester);
      final input = PracticeInputController();
      final focus = FocusNode();
      for (var attempt = 0; attempt < 4; attempt++) {
        input.showWrong('x', 'walks');
      }
      input.value = const TextEditingValue(
        text: 'wa',
        selection: TextSelection.collapsed(offset: 2),
      );
      try {
        await _practice(tester, input: input, focus: focus, scale: scale);
        final editable = tester
            .state<EditableTextState>(find.byType(EditableText))
            .renderEditable;
        final ghost = tester.renderObject<RenderParagraph>(
          find.byKey(const ValueKey('practice-ghost')),
        );
        expect(
          editable.localToGlobal(Offset.zero),
          ghost.localToGlobal(Offset.zero),
        );
        expect(
          editable.getLocalRectForCaret(const TextPosition(offset: 2)).left,
          closeTo(
            ghost
                .getOffsetForCaret(const TextPosition(offset: 2), Rect.zero)
                .dx,
            1,
          ),
        );
        final ghostText = tester.widget<Text>(
          find.byKey(const ValueKey('practice-ghost')),
        );
        final suffix =
            (ghostText.textSpan! as TextSpan).children!.last as TextSpan;
        final field = tester.widget<TextField>(find.byType(TextField));
        final page = Theme.of(tester.element(find.byType(TextField)))
            .scaffoldBackgroundColor;
        expect(
          contrastRatio(
            suffix.style!.color!,
            Color.alphaBlend(field.decoration!.fillColor!, page),
          ),
          greaterThanOrEqualTo(3),
          reason: 'A 24 pt answer hint remains legible on its input fill',
        );
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        input.dispose();
        focus.dispose();
      }
    });
  }

  testWidgets('story title scales while decorative topic stays hidden', (
    tester,
  ) async {
    usePhoneViewport(tester);
    final semantics = tester.ensureSemantics();
    const story = Story(
      id: 'accessibility-story',
      title: 'Mia',
      topic: 'Reisen',
      level: 'A2',
      readingMinutes: 4,
    );
    try {
      Future<void> pump(double scale) => tester.pumpWidget(
        accessibilityTestApp(
          textScale: scale,
          home: Scaffold(
            body: StoryCarousel(stories: const [story], onOpen: (_) {}),
          ),
        ),
      );
      await pump(1);
      await tester.pumpAndSettle();
      final title = find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.data == 'Mia' &&
            widget.style?.fontSize == 17,
      );
      final normal = tester.getSize(title);
      await pump(2);
      await tester.pumpAndSettle();
      final large = tester.getSize(title);
      final text = tester.widget<Text>(title);
      final paragraph = tester.renderObject<RenderParagraph>(title);
      expect(paragraph.textScaler.scale(text.style!.fontSize!), 34);
      // Letter spacing is a fixed logical value; font line heights round.
      expect(large.width, closeTo(normal.width * 2, 1));
      expect(large.height, closeTo(normal.height * 2, 1));
      expect(find.bySemanticsLabel(storySemanticsLabel(story)), findsOneWidget);
      await expectAccessible(tester);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      semantics.dispose();
    }
  });

  testWidgets('two title lines and reading progress fit a large shelf row', (
    tester,
  ) async {
    usePhoneViewport(tester);
    final semantics = tester.ensureSemantics();
    const story = Story(
      id: 'long-story',
      title: 'Ein langer Titel\nmit einer Fortsetzung',
      topic: 'Reisen',
      level: 'A2',
      readingMinutes: 4,
    );
    try {
      await tester.pumpWidget(
        accessibilityTestApp(
          textScale: 2,
          home: Scaffold(
            body: StoryListShelf(
              stories: const [story],
              progress: const {'long-story': 0.4},
              onOpen: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final title = tester.getRect(find.text(story.title));
      final progress = tester.getRect(find.byType(ReadingBar));
      expect(title.height, greaterThan(80));
      expect(title.bottom, lessThanOrEqualTo(progress.top));
      await expectAccessible(tester);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      semantics.dispose();
    }
  });
}
