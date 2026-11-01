import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/screens/app_shell.dart';
import 'package:sprachapp/theme/app_theme.dart';
import 'package:sprachapp/widgets/app_bottom_bar.dart';

import 'fixtures/deck_repositories.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets(
    'keyboard hides learning FAB and closing restores it without losing topic',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        testScope(
          MaterialApp(theme: buildAppTheme(), home: const AppShell()),
          library: true,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AppBottomBar),
          matching: find.text('Inhalte'),
        ),
      );
      await tester.pumpAndSettle();
      final topic = find.byKey(const ValueKey('generation-topic'));
      await tester.ensureVisible(topic);
      await tester.enterText(topic, 'Medizin');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byType(PracticeButton), findsOneWidget);
      final originalPosition = tester.getRect(find.byType(PracticeButton));

      tester.view.viewInsets = const FakeViewPadding(bottom: 320);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(PracticeButton), findsNothing);
      expect(
        tester.widget<CupertinoTextField>(topic).controller!.text,
        'Medizin',
      );
      expect(tester.takeException(), isNull);

      tester.view.viewInsets = FakeViewPadding.zero;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(PracticeButton), findsOneWidget);
      expect(tester.getRect(find.byType(PracticeButton)), originalPosition);
      expect(
        tester.widget<CupertinoTextField>(topic).controller!.text,
        'Medizin',
      );
      expect(
        tester.widget<AppBottomBar>(find.byType(AppBottomBar)).current,
        AppTab.content,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
