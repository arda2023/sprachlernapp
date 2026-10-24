import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/presentation/providers/streak_providers.dart';
import 'package:sprachapp/screens/previews/screen_previews_screen.dart';
import 'package:sprachapp/screens/onboarding/onboarding_screen.dart';
import 'package:sprachapp/screens/completion/practice_completion_screen.dart';
import 'package:sprachapp/screens/settings/settings_screen.dart';
import 'package:sprachapp/theme/app_theme.dart';

import 'fixtures/deck_repositories.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  testWidgets('Settings opens previews', (t) async {
    final user = TestUser();
    addTearDown(user.close);
    await t.pumpWidget(
      testScope(
        MaterialApp(theme: buildAppTheme(), home: const SettingsScreen()),
        user: user,
      ),
    );
    await t.pumpAndSettle();
    await t.tap(find.text('Bildschirm-Vorschauen'));
    await t.pumpAndSettle();
    expect(find.byType(ScreenPreviewsScreen), findsOneWidget);
  });
  testWidgets('All previews open and close without persisting star marks', (
    t,
  ) async {
    final marks = MemoryCelebrationMarks();
    await t.pumpWidget(
      ProviderScope(
        overrides: [celebrationMarksProvider.overrideWithValue(marks)],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const ScreenPreviewsScreen(),
        ),
      ),
    );
    for (final title in [
      'Onboarding',
      'Übungsabschluss',
      'Abschluss nach 6 Tagen',
      'Wochenstern',
    ]) {
      await t.tap(find.text(title));
      await t.pumpAndSettle();
      expect(
        find.byType(
          title == 'Onboarding' ? OnboardingScreen : PracticeCompletionScreen,
        ),
        findsOneWidget,
      );
      if (title == 'Wochenstern') {
        expect(find.text('Wochenstern geholt!'), findsOneWidget);
        final now = DateTime.now();
        expect(
          await marks.celebrated(DateTime(now.year, now.month, now.day)),
          isFalse,
        );
      }
      expect(t.takeException(), isNull);
      await t.tap(find.byType(BackButton).last);
      await t.pumpAndSettle();
      expect(find.text('Bildschirm-Vorschauen'), findsOneWidget);
    }
  });
}
