import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/screens/words/word_list_screen.dart';
import 'package:sprachapp/theme/app_theme.dart';
import 'package:sprachapp/widgets/action_buttons.dart';
import 'package:sprachapp/widgets/popover_content.dart';

import '../fixtures/accessibility_fonts.dart';
import '../fixtures/deck_repositories.dart';
import 'accessibility_test_app.dart';

void main() {
  setUpAll(loadAccessibilityFonts);

  for (final brightness in Brightness.values) {
    test('${brightness.name}: small semantic text colors meet 4.5:1', () {
      final colors = AppPalette(brightness);
      for (final background in [colors.nightPage, colors.raisedInk]) {
        for (final foreground in [
          colors.textPrimary,
          colors.textMuted,
          // Orange text in light mode is a deliberate exception (user
          // decision 15.11.2026: one orange); dark mode still meets 4.5:1.
          if (!colors.light) colors.accentText,
        ]) {
          expect(
            contrastRatio(foreground, background),
            greaterThanOrEqualTo(4.5),
            reason: '$foreground on $background',
          );
        }
      }
      expect(
        contrastRatio(popoverInk, colors.popover),
        greaterThanOrEqualTo(4.5),
        reason: 'Small popover captions and selected controls use dark ink',
      );
    });

    testWidgets(
      '${brightness.name}: enabled primary action and small popover',
      (tester) async {
        usePhoneViewport(tester);
        final semantics = tester.ensureSemantics();
        try {
          await tester.pumpWidget(
            accessibilityTestApp(
              brightness: brightness,
              home: Scaffold(
                body: Builder(
                  builder: (context) => Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PrimaryActionButton(label: 'Weiter', onPressed: () {}),
                        const SizedBox(height: 24),
                        ColoredBox(
                          color: context.appColors.popover,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Text(
                                  'Kurzer Hinweis',
                                  style: PopoverText.small(),
                                ),
                                Text(
                                  'Noch einmal',
                                  style: PopoverText.caption(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await expectAccessible(tester);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          semantics.dispose();
        }
      },
    );

    testWidgets(
      '${brightness.name}: selected filter label and count contrast',
      (tester) async {
        usePhoneViewport(tester);
        final user = TestUser(library: true);
        try {
          await tester.pumpWidget(
            testScope(
              accessibilityTestApp(
                brightness: brightness,
                home: Scaffold(body: WordListScreen(clock: () => testNow)),
              ),
              user: user,
              library: true,
            ),
          );
          await tester.pumpAndSettle();
          final label = find.byWidgetPredicate(
            (widget) =>
                widget is Text &&
                (widget.textSpan?.toPlainText().startsWith('Alle  ') ?? false),
          );
          expect(label, findsOneWidget);
          final text = tester.widget<Text>(label);
          final surface = tester.widget<AnimatedContainer>(
            find
                .ancestor(of: label, matching: find.byType(AnimatedContainer))
                .first,
          );
          final background = (surface.decoration! as BoxDecoration).color!;
          final baseInk = text.style!.color!;
          // Custom button semantics combine label and count, so the generic
          // screenshot guideline cannot map this label back to one Text widget.
          for (final span
              in (text.textSpan! as TextSpan).children!.cast<TextSpan>()) {
            expect(
              contrastRatio(span.style?.color ?? baseInk, background),
              greaterThanOrEqualTo(4.5),
              reason: 'Selected filter text: ${span.text}',
            );
          }
          expect(tester.takeException(), isNull);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await user.close();
        }
      },
    );
  }
}
