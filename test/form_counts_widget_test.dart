import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/domain/srs_state.dart';
import 'package:sprachapp/screens/home/widgets/progress_tiles.dart';

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
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: ProgressTiles(
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
      expect(find.text('Wörter geübt'), findsOneWidget);
      expect(find.text('Im Aufbau'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('Wörter geübt: 2 von 3 Wörtern')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  testWidgets('without word counts only the two exercise tiles show', (
    tester,
  ) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await tester.pumpWidget(
      const CupertinoApp(
        home: CupertinoPageScaffold(
          child: ProgressTiles(
            breakdown: VocabBreakdown(
              due: 0,
              building: 2,
              mastered: 1,
              unseen: 3,
            ),
          ),
        ),
      ),
    );
    expect(find.text('Wörter geübt'), findsNothing);
    expect(find.text('Gemeistert'), findsOneWidget);
  });
}
