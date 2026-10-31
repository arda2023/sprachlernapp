import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/models/sample_content.dart';
import 'package:sprachapp/screens/stories/story_reader_screen.dart';
import 'package:sprachapp/theme/app_theme.dart';
import 'package:sprachapp/widgets/rounded_text_highlight.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  testWidgets('word and sentence taps select the exact laid-out text range', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: StoryReaderScreen(
          story: sampleStories.first,
          text: sampleStoryText(sampleStories.first.id),
        ),
      ),
    );
    final body = find.byWidgetPredicate(
      (widget) =>
          widget is RichText &&
          widget.text.toPlainText().startsWith('The station'),
    );
    final paragraph = tester.renderObject<RenderParagraph>(body.first);
    final fullText = paragraph.text.toPlainText();
    final start = fullText.indexOf('station');
    final before = tester.getRect(body.first);
    Future<void> tapStation() async {
      final boxes = paragraph.getBoxesForSelection(
        TextSelection(baseOffset: start, extentOffset: start + 7),
      );
      await tester.tapAt(paragraph.localToGlobal(boxes.first.toRect().center));
      await tester.pumpAndSettle();
    }

    String selectedText() {
      final highlight = tester
          .widgetList<RoundedTextHighlight>(find.byType(RoundedTextHighlight))
          .singleWhere((widget) => widget.selection != null);
      final selection = highlight.selection!;
      expect(highlight.color, AppPalette(Brightness.dark).popover);
      return fullText.substring(selection.start, selection.end);
    }

    await tapStation();
    expect(selectedText(), 'station');
    expect(tester.getRect(body.first), before);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(
      tester
          .widgetList<RoundedTextHighlight>(find.byType(RoundedTextHighlight))
          .every((widget) => widget.selection == null),
      isTrue,
    );
    await tester.tap(find.text('Übersetzen'));
    await tester.pumpAndSettle();
    await tapStation();
    expect(selectedText().trim(), startsWith('The station'));
    expect(selectedText().trim(), endsWith('.'));
    expect(selectedText().length, greaterThan(7));
    expect(tester.takeException(), isNull);
  });
}
