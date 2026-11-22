import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/domain/tutor.dart';
import 'package:sprachapp/presentation/providers/tutor_providers.dart';
import 'package:sprachapp/screens/home/widgets/tutor_entry_card.dart';
import 'package:sprachapp/screens/tutor/widgets/tutor_feedback.dart';
import 'package:sprachapp/screens/tutor/widgets/tutor_info_chip.dart';
import 'package:sprachapp/theme/app_theme.dart';

import '../fixtures/accessibility_fonts.dart';
import '../fixtures/tutor_ui.dart';
import 'accessibility_test_app.dart';

void main() {
  setUpAll(loadAccessibilityFonts);

  test('blue information colors meet small-text contrast in both themes', () {
    for (final brightness in Brightness.values) {
      final colors = AppPalette(brightness);
      expect(
        contrastRatio(colors.memoryLevel2, colors.playback),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrastRatio(colors.onActive, AppColors.memoryLevel2),
        greaterThanOrEqualTo(4.5),
      );
    }
  });

  for (final brightness in Brightness.values) {
    for (final width in [320.0, 390.0]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('tutor accessible ${brightness.name} $width text $scale', (
          tester,
        ) async {
          final semantics = tester.ensureSemantics();
          try {
            tutorViewport(tester, width: width);
            final harness = TutorUiHarness();
            await tester.pumpWidget(
              harness.app(brightness: brightness, scale: scale),
            );
            await tester.pumpAndSettle();
            await expectAccessible(tester);
            expect(find.bySemanticsLabel('Übersetzen'), findsOneWidget);
            await tester.tap(find.byType(TutorInfoChip));
            await tester.pumpAndSettle();
            await expectAccessible(tester);
            await tester.tapAt(const Offset(4, 4));
            await tester.pumpAndSettle();
            await tester.enterText(
              find.byType(CupertinoTextField),
              'Yesterday I meet my old teacher.',
            );
            await tester.pump();
            await tester.tap(find.text('Prüfen'));
            await tester.pumpAndSettle();
            expect(
              find.bySemanticsLabel('Grammatik: kleiner Fehler'),
              findsOneWidget,
            );
            final position = tutorScroll(tester).position;
            // Test both ends; no short clipped label is the only observation.
            position.jumpTo(0);
            await tester.pumpAndSettle();
            await expectAccessible(tester);
            position.jumpTo(position.maxScrollExtent);
            await tester.pumpAndSettle();
            await expectAccessible(tester);
            await tester.ensureVisible(
              find.byKey(const ValueKey('tutor-score-grammar')),
            );
            await tester.pumpAndSettle();
            await tester.tap(find.byKey(const ValueKey('tutor-score-grammar')));
            await tester.pumpAndSettle();
            await expectAccessible(tester);
            expect(
              find.text(TutorDimension.grammar.explanation(1)),
              findsOneWidget,
            );
          } finally {
            semantics.dispose();
          }
        });
      }
    }

    testWidgets(
      'home, blue chip and completion accessible ${brightness.name}',
      (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          tutorViewport(tester);
          final harness = TutorUiHarness(
            controller: FakeTutorSessionController(
              item: tutorUiItem(kind: TutorKind.situation),
            ),
          );
          await tester.pumpWidget(
            harness.app(
              home: const Scaffold(body: SafeArea(child: TutorEntryCard())),
              brightness: brightness,
            ),
          );
          await tester.pumpAndSettle();
          await expectAccessible(tester);
          await tester.tap(find.byKey(const Key('tutor-entry')));
          await tester.pumpAndSettle();
          await tester.tap(find.byType(TutorInfoChip));
          await tester.pumpAndSettle();
          await expectAccessible(tester);
          await tester.tapAt(const Offset(4, 4));
          await tester.pumpAndSettle();
          harness.controller.emit(
            harness.controller.session(status: TutorSessionStatus.completed),
          );
          await tester.pumpAndSettle();
          await expectAccessible(tester);
        } finally {
          semantics.dispose();
        }
      },
    );
  }
}
