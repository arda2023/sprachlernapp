import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/presentation/practice/deck_session_controller.dart';
import 'package:sprachapp/screens/decks/deck_practice_screen.dart';
import 'package:sprachapp/theme/app_theme.dart';
import 'package:sprachapp/domain/srs_state.dart';

import 'fixtures/deck_repositories.dart';

class _Content extends TestContent {
  @override
  Future<List<String>> deckCardIds(String deckId) async => ['deck-0/0'];
}

const _args = (deckId: 'deck-0', kind: DeckSessionKind.learn, size: 1);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  late TestUser user;
  setUp(() => user = TestUser());
  tearDown(() => user.close());

  Future<ProviderContainer> open(WidgetTester tester) async {
    await tester.pumpWidget(
      testScope(
        MaterialApp(
          theme: buildAppTheme(),
          home: const DeckPracticeScreen(deckId: 'deck-0', sessionSize: 1),
        ),
        user: user,
        content: _Content(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextField));
    return ProviderScope.containerOf(
      tester.element(find.byType(DeckPracticeScreen)),
    );
  }

  Future<void> reveal(WidgetTester tester, LogicalKeyboardKey key) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(key);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
  }

  for (final key in [
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.numpadEnter,
  ]) {
    for (final text in ['', 'unfinished answer']) {
      testWidgets('Shift+${key.keyLabel} reveals with focused input "$text"', (
        tester,
      ) async {
        final container = await open(tester);
        await tester.enterText(find.byType(TextField), text);
        await reveal(tester, key);
        final pass = container.read(deckSessionControllerProvider(_args)).pass!;
        expect(pass.revealed, isTrue);
        expect(pass.solved, isFalse);
        final field = tester.widget<TextField>(find.byType(TextField));
        expect(field.controller!.text, isEmpty);
        expect(field.decoration!.hintText, 'walks');
        expect(field.focusNode!.hasFocus, isTrue);
        expect(user.attempts, isEmpty);
        // Already revealed: the shortcut must preserve the user's copying.
        await tester.enterText(find.byType(TextField), 'wal');
        await reveal(tester, key);
        expect(field.controller!.text, 'wal');
      });
    }
  }

  testWidgets('Shift+Enter autorepeat does not reveal; normal Enter submits', (
    tester,
  ) async {
    final container = await open(tester);
    await tester.enterText(find.byType(TextField), 'walks');
    // Holding the shortcut must not erase text entered after the reveal.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.enterText(find.byType(TextField), 'wal');
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'wal',
    );
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.enterText(find.byType(TextField), 'walks');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    // The platform text input delivers the unmodified Enter as done.
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(
      container.read(deckSessionControllerProvider(_args)).pass!.solved,
      isTrue,
    );
    expect(user.attempts, hasLength(1));
  });

  testWidgets(
    'Shift+Enter does not advance or repeat a saving or solved card',
    (tester) async {
      user.writeGate = Completer<void>();
      addTearDown(() {
        if (!user.writeGate!.isCompleted) user.writeGate!.complete();
      });
      final container = await open(tester);
      await tester.enterText(find.byType(TextField), 'walks');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      // The platform text input delivers the unmodified Enter as done.
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      final before = container.read(deckSessionControllerProvider(_args));
      expect(before.committing, isTrue);
      await reveal(tester, LogicalKeyboardKey.enter);
      expect(
        container.read(deckSessionControllerProvider(_args)).pass!.id,
        before.pass!.id,
      );
      expect(user.attempts, hasLength(1));
      user.writeGate!.complete();
      await tester.pumpAndSettle();
      await reveal(tester, LogicalKeyboardKey.numpadEnter);
      final after = container.read(deckSessionControllerProvider(_args));
      expect(after.pass!.id, before.pass!.id);
      expect(after.pass!.revealed, isFalse);
      expect(after.finished, isFalse);
      expect(user.attempts, hasLength(1));
    },
  );
}
