import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/domain/streak.dart';
import 'package:sprachapp/domain/srs_state.dart';
import 'package:sprachapp/models/home_models.dart';
import 'package:sprachapp/screens/completion/practice_completion_screen.dart';
import 'package:sprachapp/screens/completion/widgets/stacked_word_cards.dart';
import 'package:sprachapp/screens/decks/deck_practice_screen.dart';
import 'package:sprachapp/screens/decks/widgets/practice_chrome.dart';
import 'package:sprachapp/theme/app_theme.dart';

import 'fixtures/deck_repositories.dart';

class SlowNextUser extends TestUser {
  Completer<void>? gate;
  @override
  Future<void> ensureCards(
    Iterable<String> ids, {
    required DateTime now,
    required CardOrigin origin,
  }) async {
    await gate?.future;
    await super.ensureCards(ids, now: now, origin: origin);
  }
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('A slow next sentence preserves the editor and keyboard', (
    t,
  ) async {
    final user = SlowNextUser();
    addTearDown(user.close);
    await t.pumpWidget(
      testScope(
        MaterialApp(
          theme: buildAppTheme(),
          home: const DeckPracticeScreen(deckId: 'deck-0', sessionSize: 3),
        ),
        user: user,
      ),
    );
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField), 'walks');
    await t.testTextInput.receiveAction(TextInputAction.done);
    await t.pumpAndSettle();
    final editor = t.state(find.byType(EditableText));
    user.gate = Completer<void>();
    await t.tap(find.text('Weiter'));
    await t.pump(const Duration(milliseconds: 80));
    expect(t.state(find.byType(EditableText)), same(editor));
    expect(
      t.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus,
      isTrue,
    );
    expect(t.testTextInput.isVisible, isTrue);
    user.gate!.complete();
    await t.pumpAndSettle();
    expect(t.state(find.byType(EditableText)), same(editor));
    expect(
      t.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    expect(
      t.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus,
      isTrue,
    );
  });

  testWidgets(
    'Continuous progress retains yellow history between orange phases',
    (t) async {
      Future<void> show(int done, {bool repeating = false}) async {
        await t.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(),
            home: Scaffold(
              body: SizedBox(
                width: 300,
                child: ContinuousSessionTrack(
                  done: done,
                  total: 6,
                  repeatIndices: const {2},
                  activeRepeat: repeating,
                ),
              ),
            ),
          ),
        );
      }

      List<Color> colors() => t
          .widgetList<ColoredBox>(
            find.descendant(
              of: find.byType(ContinuousSessionTrack),
              matching: find.byType(ColoredBox),
            ),
          )
          .map((box) => box.color)
          .toList();
      await show(2);
      expect(colors(), isNot(contains(ContinuousSessionTrack.repeatColor)));
      await show(2, repeating: true);
      expect(colors().last, ContinuousSessionTrack.repeatColor);
      await show(4);
      expect(colors().skip(1), [
        AppColors.active,
        AppColors.active,
        ContinuousSessionTrack.repeatColor,
        AppColors.active,
      ]);
    },
  );

  testWidgets('Scrolling words keeps the entire header fixed and clicks', (
    t,
  ) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final haptics = <Object?>[];
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          haptics.add(call.arguments);
        }
        return null;
      },
    );
    addTearDown(
      () => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await t.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildAppTheme(),
          home: PracticeCompletionScreen(
            streak: summarizeStreak([
              DateTime(2026, 10, 24),
            ], DateTime(2026, 10, 24)),
            goal: const DailyGoal(done: 5, target: 5),
            words: [
              for (var i = 0; i < 5; i++)
                CompletionWord(
                  form: 'word $i',
                  translation: 'Wort $i',
                  sentence: 'This is word $i.',
                  isNew: true,
                ),
            ],
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    final title = t.getTopLeft(find.text('Sehr gut!'));
    final heading = t.getTopLeft(find.text('Neue Wörter'));
    haptics.clear();
    await t.drag(
      find.byKey(const ValueKey('completion-word-scroll')),
      const Offset(0, -350),
    );
    await t.pumpAndSettle();
    expect(t.getTopLeft(find.text('Sehr gut!')), title);
    expect(t.getTopLeft(find.text('Neue Wörter')), heading);
    expect(t.getTopLeft(find.text('word 0')).dy, greaterThan(heading.dy));
    expect(haptics, contains('HapticFeedbackType.selectionClick'));
    expect(t.takeException(), isNull);
  });
}
