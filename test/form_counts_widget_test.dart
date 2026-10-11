import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/domain/srs_state.dart';
import 'package:sprachapp/screens/home/widgets/vocab_progress.dart';

void main() {
  testWidgets(
    'words and independent exercise counts remain readable at narrow width',
    (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        const CupertinoApp(
          home: CupertinoPageScaffold(
            child: SingleChildScrollView(
              child: VocabProgress(
                breakdown: VocabBreakdown(
                  due: 1,
                  building: 1,
                  mastered: 1,
                  unseen: 6,
                ),
                lexical: LexicalBreakdown(total: 3, practiced: 2),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Wörter'), findsOneWidget);
      expect(find.text('Übungen im Aufbau'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('3 Wörter, davon 2 bereits geübt')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );
}
