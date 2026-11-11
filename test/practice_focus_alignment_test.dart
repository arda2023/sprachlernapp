import 'dart:ui' show ViewFocusDirection, ViewFocusEvent, ViewFocusState;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/screens/decks/deck_practice_screen.dart';
import 'package:sprachapp/theme/app_theme.dart';

import 'fixtures/deck_repositories.dart';
import 'fixtures/practice_session.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> open(WidgetTester t) async {
    final user = TestUser();
    addTearDown(user.close);
    await t.pumpWidget(
      testScope(
        MaterialApp(
          theme: buildAppTheme(),
          home: const DeckPracticeScreen(deckId: 'deck-0', sessionSize: 3),
        ),
        user: user,
        content: WalksOnlyContent(),
      ),
    );
    await t.pumpAndSettle();
  }

  void window(WidgetTester t, ViewFocusState state) {
    t.binding.handleViewFocusChanged(
      ViewFocusEvent(
        viewId: t.view.viewId,
        state: state,
        direction: ViewFocusDirection.undefined,
      ),
    );
  }

  testWidgets('Returning to app restores answer focus and input connection', (
    t,
  ) async {
    await open(t);
    await t.enterText(find.byType(TextField), 'wal');
    final field = t.widget<TextField>(find.byType(TextField));
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    field.focusNode!.unfocus();
    await t.pump();
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await t.pump();
    expect(field.focusNode!.hasFocus, isTrue);
    expect(t.testTextInput.isVisible, isTrue);
    expect(field.controller!.text, 'wal');
  });

  testWidgets('Window return reconnects already focused editor immediately', (
    t,
  ) async {
    await open(t);
    await t.enterText(find.byType(TextField), 'wal');
    window(t, ViewFocusState.unfocused);
    t.testTextInput.hide();
    expect(t.testTextInput.isVisible, isFalse);
    window(t, ViewFocusState.focused);
    await t.pump();
    expect(t.testTextInput.isVisible, isTrue);
    expect(t.widget<TextField>(find.byType(TextField)).controller!.text, 'wal');
  });

  testWidgets('Returning does not take focus from a dialog editor', (t) async {
    await open(t);
    final practice = t.widget<TextField>(find.byType(TextField));
    final other = FocusNode();
    addTearDown(other.dispose);
    showDialog<void>(
      context: t.element(find.byType(DeckPracticeScreen)),
      builder: (_) => AlertDialog(
        content: TextField(
          key: const ValueKey('other'),
          focusNode: other,
          autofocus: true,
        ),
      ),
    );
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const ValueKey('other')), 'a note');
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    window(t, ViewFocusState.unfocused);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    window(t, ViewFocusState.focused);
    await t.pump();
    expect(other.hasFocus, isTrue);
    expect(practice.focusNode!.hasFocus, isFalse);
    expect(
      t.widget<TextField>(find.byKey(const ValueKey('other'))).controller,
      isNull,
    );
  });

  testWidgets('Window return respects another editor on the same route', (
    t,
  ) async {
    await open(t);
    final practice = t.widget<TextField>(find.byType(TextField));
    final other = FocusNode();
    final entry = OverlayEntry(
      builder: (_) => Positioned(
        left: 0,
        top: 0,
        width: 200,
        child: Material(child: TextField(focusNode: other)),
      ),
    );
    Overlay.of(t.element(find.byType(DeckPracticeScreen))).insert(entry);
    await t.pump();
    other.requestFocus();
    await t.pump();
    window(t, ViewFocusState.unfocused);
    window(t, ViewFocusState.focused);
    await t.pump();
    expect(other.hasFocus, isTrue);
    expect(practice.focusNode!.hasFocus, isFalse);
    entry.remove();
    await t.pump();
    entry.dispose();
    other.dispose();
  });

  testWidgets('Typed and solved words stay centered without a caret', (
    t,
  ) async {
    await open(t);
    await t.enterText(find.byType(TextField), 'walks');
    await t.pump();
    void check() {
      final field = t.widget<TextField>(find.byType(TextField));
      expect(field.showCursor, isFalse);
      final editable = t
          .state<EditableTextState>(find.byType(EditableText))
          .renderEditable;
      final boxes = editable.getBoxesForSelection(
        const TextSelection(baseOffset: 0, extentOffset: 5),
      );
      expect(boxes, hasLength(1));
      expect(
        (boxes.single.left + boxes.single.right) / 2,
        closeTo(editable.size.width / 2, 1),
      );
    }

    check();
    await t.testTextInput.receiveAction(TextInputAction.done);
    await t.pumpAndSettle();
    check();
  });
}
