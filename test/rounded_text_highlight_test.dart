import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/widgets/rounded_text_highlight.dart';

void main() {
  testWidgets(
    'rounded selection preserves text layout and supports wrapped lines',
    (tester) async {
      if (Platform.environment['STORY_PREVIEW_FONT'] case final path?) {
        await tester.runAsync(() async {
          final loader = FontLoader('PreviewSerif');
          loader.addFont(
            Future.value(ByteData.sublistView(await File(path).readAsBytes())),
          );
          await loader.load();
        });
      }
      const text =
          'A long sentence wraps across several lines without moving when selected.';
      const orange = Color(0xFFE26C00);
      final boundary = GlobalKey();
      Future<void> show(TextSelection? selection) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              backgroundColor: const Color(0xFF0D0F14),
              body: Center(
                child: RepaintBoundary(
                  key: boundary,
                  child: Container(
                    color: const Color(0xFF0D0F14),
                    padding: const EdgeInsets.all(20),
                    width: 300,
                    child: RoundedTextHighlight(
                      selection: selection,
                      color: orange,
                      child: const Text(
                        text,
                        style: TextStyle(
                          fontFamily: 'PreviewSerif',
                          fontSize: 20,
                          height: 1.6,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }

      await show(null);
      final paragraphFinder = find.descendant(
        of: find.byType(RoundedTextHighlight),
        matching: find.byType(RichText),
      );
      final before = tester.getRect(paragraphFinder);
      await show(const TextSelection(baseOffset: 2, extentOffset: 6));
      expect(tester.getRect(paragraphFinder), before);
      expect(
        tester.renderObject(find.byType(RoundedTextHighlight)),
        paints..rrect(color: orange),
      );
      await show(const TextSelection(baseOffset: 0, extentOffset: text.length));
      expect(tester.getRect(paragraphFinder), before);
      final paragraph = tester.renderObject<RenderParagraph>(paragraphFinder);
      expect(
        paragraph
            .getBoxesForSelection(
              const TextSelection(baseOffset: 0, extentOffset: text.length),
            )
            .length,
        greaterThan(1),
      );
      expect(
        tester.renderObject(find.byType(RoundedTextHighlight)),
        paints
          ..rrect(color: orange)
          ..rrect(color: orange),
      );
      expect(tester.takeException(), isNull);
      // Optional local visual evidence, not a brittle pixel golden.
      if (Platform.environment['STORY_HIGHLIGHT_PREVIEW'] case final path?) {
        final render =
            boundary.currentContext!.findRenderObject()
                as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await render.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(path).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
    },
  );
}
