import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/domain/streak.dart';
import 'package:sprachapp/models/home_models.dart';
import 'package:sprachapp/screens/completion/practice_completion_screen.dart';
import 'package:sprachapp/screens/completion/widgets/completion_panda.dart';
import 'package:sprachapp/screens/completion/widgets/stacked_word_cards.dart';
import 'package:sprachapp/screens/completion/widgets/streak_charge_bar.dart';
import 'package:sprachapp/theme/app_theme.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  testWidgets('panda and bar glide together without rebuilding the word stack', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildAppTheme(),
          home: PracticeCompletionScreen(
            streak: const StreakSummary(
              current: 0,
              starDays: {},
              activeDays: {},
              barFilled: 0,
              barMissed: false,
              starToday: false,
              practicedToday: false,
            ),
            goal: const DailyGoal(done: 10, target: 10),
            words: [
              for (var i = 0; i < 30; i++)
                CompletionWord(
                  form: 'word $i',
                  translation: 'Wort $i',
                  sentence: 'A sentence.',
                  isNew: false,
                ),
            ],
          ),
        ),
      ),
    );
    for (var i = 0; i < 47; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    final cards = tester.widget<StackedWordCards>(
      find.byType(StackedWordCards),
    );
    final panda = find.byType(CompletionPanda);
    final bar = find.byType(StreakChargeBar);
    final pandaBefore = tester.getTopLeft(panda).dy;
    final barBefore = tester.getTopLeft(bar).dy;
    var replaced = 0;
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      if (!identical(tester.widget(find.byType(StackedWordCards)), cards)) {
        replaced++;
      }
    }
    final pandaShift = tester.getTopLeft(panda).dy - pandaBefore;
    final barShift = tester.getTopLeft(bar).dy - barBefore;
    expect(pandaShift, isNegative);
    expect(pandaShift, closeTo(barShift, 0.01));
    expect(replaced, 0);
    debugPrint(
      'COMPLETION MOTION: 20 moving-header frames, $replaced word-stack reconstructions',
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
