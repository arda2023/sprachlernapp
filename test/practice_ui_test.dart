import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/domain/answer_check.dart';
import 'package:sprachapp/domain/preferences.dart';
import 'package:sprachapp/screens/decks/widgets/local_submission_sheet.dart';
import 'package:sprachapp/screens/settings/settings_screen.dart';
import 'package:sprachapp/main.dart';
import 'package:sprachapp/screens/decks/deck_practice_screen.dart';
import 'package:sprachapp/screens/decks/widgets/practice_input.dart';
import 'package:sprachapp/screens/decks/widgets/practice_chrome.dart';
import 'package:sprachapp/screens/decks/widgets/form_info_sheet.dart';
import 'package:sprachapp/theme/app_theme.dart';

import 'fixtures/deck_repositories.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  test(
    'Accent option changes only accent equivalence; canonical Unicode matches',
    () {
      expect(evaluateAnswer('cafe', target: 'café'), AnswerVerdict.almost);
      expect(
        evaluateAnswer('cafe', target: 'café', includeDiacritics: false),
        AnswerVerdict.target,
      );
      expect(
        evaluateAnswer('caff', target: 'café', includeDiacritics: false),
        AnswerVerdict.almost,
      );
      expect(
        evaluateAnswer('cafe\u0301', target: 'café'),
        AnswerVerdict.target,
      );
      expect(
        evaluateAnswer('strasse', target: 'straße', includeDiacritics: false),
        isNot(AnswerVerdict.target),
      );
    },
  );
  test('Prefix uses target graphemes and does not reveal short answers', () {
    expect(targetPrefix('table'), 'ta…');
    expect(targetPrefix('an'), 'a…');
    expect(targetPrefix('a'), '…');
    expect(targetPrefix('e\u0301té'), 'e\u0301t…');
  });
  test(
    'Feedback edit retains inserted text, selection, composition and paste',
    () {
      final c = PracticeInputController();
      addTearDown(c.dispose);
      c.showWrong('laterx', 'table');
      c.value = const TextEditingValue(
        text: 'laterxz',
        selection: TextSelection.collapsed(offset: 7),
      );
      expect(c.text, 'z');
      expect(c.selection.baseOffset, 1);
      expect(c.feedback, InputFeedback.typing);
      c.reset();
      c.showWrong('laterx', 'table');
      c.selection = const TextSelection(baseOffset: 2, extentOffset: 4);
      c.value = const TextEditingValue(
        text: 'laéxrx',
        selection: TextSelection.collapsed(offset: 4),
        composing: TextRange(start: 2, end: 4),
      );
      expect(c.text, 'éx');
      expect(c.value.composing, const TextRange(start: 0, end: 2));
      c.showWrong('zzzz', 'table');
      expect(c.hint, 'ta…');
      expect(c.text, isEmpty);
      c.value = const TextEditingValue(
        text: 'pasted answer',
        selection: TextSelection.collapsed(offset: 13),
      );
      expect(c.text, 'pasted answer');
      expect(c.hint, isEmpty);
    },
  );
  testWidgets(
    'First wrong answer retains all letters with occurrence colors at 50%',
    (tester) async {
      final c = PracticeInputController();
      addTearDown(c.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              c.showWrong('laterx', 'table');
              final spans = c
                  .buildTextSpan(context: context, withComposing: false)
                  .children!
                  .cast<TextSpan>();
              expect(spans.map((s) => s.text).join(), 'laterx');
              expect(
                spans.map((s) => s.style!.color).toList(),
                [
                  c.blue,
                  c.blue,
                  c.blue,
                  c.blue,
                  c.red,
                  c.red,
                ].map((v) => v.withValues(alpha: .5)).toList(),
              );
              c.reset();
              c.showWrong('wop !', 'table');
              final all = c
                  .buildTextSpan(context: context, withComposing: false)
                  .children!
                  .cast<TextSpan>()
                  .toList();
              expect(
                all
                    .take(3)
                    .every(
                      (s) => s.style!.color == c.red.withValues(alpha: .5),
                    ),
                isTrue,
              );
              expect(all.last.style!.color, c.neutral.withValues(alpha: .5));
              return const SizedBox();
            },
          ),
        ),
      );
    },
  );
  Future<void> open(WidgetTester t, TestUser user) async {
    await t.pumpWidget(
      testScope(
        MaterialApp(
          theme: buildAppTheme(),
          home: const DeckPracticeScreen(deckId: 'deck-0'),
        ),
        user: user,
      ),
    );
    await t.pumpAndSettle();
  }

  Future<void> answer(WidgetTester t, String value) async {
    await t.enterText(find.byType(TextField), value);
    await t.testTextInput.receiveAction(TextInputAction.done);
    await t.pump();
  }

  testWidgets(
    'One right action, reveal typing, stable solution box and saved-only check',
    (t) async {
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final u = TestUser()
        ..writeGate = Completer<void>()
        ..failures = 1;
      addTearDown(u.close);
      await open(t, u);
      void right(String label) => expect(
        t.getTopRight(find.bySemanticsLabel(label)).dx,
        closeTo(378, 1),
      );
      right('Wort erfahren');
      expect(find.text('Eingeben'), findsNothing);
      await t.enterText(find.byType(TextField), 'x');
      await t.pump();
      await t.pump(const Duration(milliseconds: 60));
      expect(
        find.ancestor(
          of: find.text('Wort erfahren'),
          matching: find.byType(IgnorePointer),
        ),
        findsWidgets,
      );
      await t.pumpAndSettle();
      right('Eingeben');
      expect(find.text('Wort erfahren'), findsNothing);
      await t.enterText(find.byType(TextField), '');
      await t.pumpAndSettle();
      right('Wort erfahren');
      await t.tap(find.text('Wort erfahren'));
      await t.pumpAndSettle();
      expect(find.text('Tippe das Wort ab, um weiterzumachen.'), findsNothing);
      expect(find.text('Weiter'), findsNothing);
      expect(u.records, isEmpty);
      expect(
        t.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      await t.enterText(find.byType(TextField), 'walks');
      await t.pumpAndSettle();
      final before = t.getRect(find.byType(TextField));
      await t.tap(find.text('Eingeben'));
      await t.pumpAndSettle();
      final field = t.widget<TextField>(find.byType(TextField));
      expect(field.readOnly, isTrue);
      expect(field.showCursor, isFalse);
      expect(field.controller!.text, 'walks');
      expect(
        field.decoration!.fillColor,
        AppColors.memoryLevel2.withValues(alpha: .12),
      );
      expect(t.getRect(find.byType(TextField)), before);
      expect(find.byKey(const ValueKey('practice-success')), findsNothing);
      expect(find.text('Weiter'), findsNothing);
      u.writeGate!.complete();
      await t.pumpAndSettle();
      right('Speichern wiederholen');
      expect(find.byKey(const ValueKey('practice-success')), findsNothing);
      await t.tap(find.text('Speichern wiederholen'));
      await t.pumpAndSettle();
      right('Weiter');
      final check = find.byKey(const ValueKey('practice-success'));
      expect(check, findsOneWidget);
      expect(
        t.getTopRight(check).dx,
        lessThan(t.getTopLeft(find.text('Weiter')).dx),
      );
      expect(u.records, hasLength(1));
      t.view.viewInsets = const FakeViewPadding(bottom: 300);
      await t.pumpAndSettle();
      right('Weiter');
      expect(
        t.getBottomLeft(find.bySemanticsLabel('Weiter')).dy,
        lessThanOrEqualTo(544),
      );
      expect(find.text('Aktuelle Karte'), findsNothing);
      expect(find.byTooltip('Vorheriger Durchgang'), findsNothing);
    },
  );
  testWidgets('Reduced motion changes toolbar actions immediately', (t) async {
    final u = TestUser();
    addTearDown(u.close);
    t.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await open(t, u);
    await t.enterText(find.byType(TextField), 'x');
    await t.pumpAndSettle();
    final switcher = t.widget<AnimatedSwitcher>(
      find.descendant(
        of: find.byType(PracticeAnswerToolbar),
        matching: find.byType(AnimatedSwitcher),
      ),
    );
    expect(switcher.duration, Duration.zero);
    expect(find.text('Wort erfahren'), findsNothing);
    expect(find.text('Eingeben'), findsOneWidget);
  });
  testWidgets(
    'Menu persists favorite, disables without review and stores report metadata',
    (t) async {
      final u = TestUser();
      addTearDown(u.close);
      await open(t, u);
      await t.tap(find.bySemanticsLabel('Mehr'));
      await t.pumpAndSettle();
      await t.tap(find.text('Zu Favoriten hinzufügen'));
      await t.pumpAndSettle();
      expect(u.states['deck-0/0']!.favorite, isTrue);
      await t.tap(find.bySemanticsLabel('Mehr'));
      await t.pumpAndSettle();
      expect(find.text('Aus Favoriten entfernen'), findsOneWidget);
      await t.tap(find.text('Ein Problem melden'));
      await t.pumpAndSettle();
      await t.tap(find.text('Die Grammatik ist falsch.'));
      await t.pumpAndSettle();
      expect(find.byType(LocalSubmissionSheet), findsOneWidget);
      await t.enterText(find.byType(TextField), 'Bitte prüfen.');
      await t.tap(find.text('Lokal speichern'));
      await t.pumpAndSettle();
      expect(u.localEntries.single.cardId, 'deck-0/0');
      expect(u.localEntries.single.sentenceId, 'deck-0/0/s1');
      expect(u.localEntries.single.packVersion, 'fixture');
      expect(
        find.text('Lokal gespeichert. Es wurde nichts versendet.'),
        findsOneWidget,
      );
      Navigator.pop(t.element(find.byType(LocalSubmissionSheet)));
      await t.pumpAndSettle();
      await t.tap(find.bySemanticsLabel('Mehr'));
      await t.pumpAndSettle();
      await t.tap(find.text('Wort deaktivieren'));
      await t.pumpAndSettle();
      expect(u.states['deck-0/0']!.disabled, isTrue);
      expect(u.records, isEmpty);
      expect(find.text('ungefähr'), findsOneWidget);
    },
  );
  testWidgets('Motif switches the app without remounting the settings route', (
    t,
  ) async {
    final u = TestUser();
    addTearDown(u.close);
    await t.pumpWidget(testScope(const SprachApp(), user: u));
    await t.pumpAndSettle();
    final context = t.element(find.byType(Scaffold).first);
    SettingsScreen.open(context);
    await t.pumpAndSettle();
    await t.tap(find.byType(DropdownButton<AppMotif>));
    await t.pumpAndSettle();
    await t.tap(find.text('Dunkel').last);
    await t.pumpAndSettle();
    expect(u.prefs.motif, AppMotif.dark);
    expect(
      Theme.of(t.element(find.byType(SettingsScreen))).brightness,
      Brightness.dark,
    );
    await t.tap(find.byType(DropdownButton<AppMotif>));
    await t.pumpAndSettle();
    await t.tap(find.text('Hell').last);
    await t.pumpAndSettle();
    expect(u.prefs.motif, AppMotif.light);
    expect(
      Theme.of(t.element(find.byType(SettingsScreen))).brightness,
      Brightness.light,
    );
  });

  testWidgets(
    'Feedback and settings remain usable at 320 pixels and double text size',
    (t) async {
      t.view.physicalSize = const Size(320, 760);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final u = TestUser();
      addTearDown(u.close);
      Widget host(Widget child) => testScope(
        MaterialApp(
          theme: buildAppTheme(),
          builder: (_, child) => MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 760),
              textScaler: TextScaler.linear(2),
            ),
            child: child!,
          ),
          home: child,
        ),
        user: u,
      );
      await t.pumpWidget(host(const LocalSubmissionSheet()));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      await t.tap(find.byTooltip('4 Sterne'));
      await t.scrollUntilVisible(
        find.text('Lokal speichern'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await t.pumpAndSettle();
      await t.tap(find.text('Lokal speichern'));
      await t.pumpAndSettle();
      expect(u.localEntries.single.rating, 4);
      expect(t.takeException(), isNull);
      await t.pumpWidget(host(const SettingsScreen()));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      await t.tap(find.byType(DropdownButton<AppMotif>));
      await t.pumpAndSettle();
      await t.tap(find.text('Dunkel').last);
      await t.pumpAndSettle();
      expect(u.prefs.motif, AppMotif.dark);
      expect(t.takeException(), isNull);
      await t.drag(find.byType(ListView), const Offset(0, -1500));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'Second error shows target prefix; history returns exact current editing state with no reviews',
    (t) async {
      final u = TestUser();
      addTearDown(u.close);
      await open(t, u);
      await answer(t, 'banana');
      await answer(t, 'orange');
      final c =
          t.widget<TextField>(find.byType(TextField)).controller!
              as PracticeInputController;
      expect(c.hint, 'wa…');
      expect(c.text, isEmpty);
      await answer(t, 'walks');
      await t.pumpAndSettle();
      await t.tap(find.text('Weiter'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField), 'current text');
      final current = t.widget<TextField>(find.byType(TextField)).controller!;
      current.selection = const TextSelection.collapsed(offset: 3);
      await t.fling(find.text('ungefähr'), const Offset(-240, 0), 700);
      await t.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      await t.fling(find.text('ungefähr'), const Offset(240, 0), 700);
      await t.pumpAndSettle();
      expect(find.textContaining('Rückblick · Richtig nach 2'), findsOneWidget);
      expect(t.widget<TextField>(find.byType(TextField)).readOnly, isTrue);
      expect(u.records, hasLength(1));
      final navigation = t
          .widgetList<Semantics>(find.byType(Semantics))
          .firstWhere(
            (w) =>
                w.properties.customSemanticsActions?.keys.any(
                  (a) => a.label == 'Nächster Durchgang',
                ) ??
                false,
          );
      navigation.properties.customSemanticsActions!.values.single();
      await t.pumpAndSettle();
      expect(current.text, 'current text');
      expect(current.selection.baseOffset, 3);
      expect(u.records, hasLength(1));
      await t.fling(find.text('ungefähr'), const Offset(240, 0), 700);
      await t.pumpAndSettle();
      await t.fling(
        find.textContaining('Rückblick · Richtig nach 2'),
        const Offset(-240, 0),
        700,
      );
      await t.pumpAndSettle();
      expect(current.text, 'current text');
      expect(current.selection.baseOffset, 3);
      expect(find.byType(TextField), findsOneWidget);
      expect(u.records, hasLength(1));
    },
  );
  testWidgets(
    'Long input wraps on narrow screen with large text and keyboard',
    (t) async {
      t.view.physicalSize = const Size(320, 760);
      t.view.devicePixelRatio = 1;
      t.view.viewInsets = const FakeViewPadding(bottom: 280);
      addTearDown(t.view.reset);
      final u = TestUser();
      addTearDown(u.close);
      await open(t, u);
      final long = List.filled(12, 'abcdefghij').join();
      await t.enterText(find.byType(TextField), long);
      await t.pump();
      expect(
        t.widget<TextField>(find.byType(TextField)).controller!.text,
        long,
      );
      expect(t.getSize(find.byType(TextField)).width, lessThanOrEqualTo(244));
      expect(t.getSize(find.byType(TextField)).height, greaterThan(120));
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'Tooltip outer tap consumes submission; another word changes selection',
    (t) async {
      final u = TestUser();
      addTearDown(u.close);
      await open(t, u);
      await t.enterText(find.byType(TextField), 'walks');
      await t.pumpAndSettle();
      await t.tap(find.text('Mia'));
      await t.pump();
      expect(find.text('Übersetzung nicht verfügbar'), findsOneWidget);
      await t.tap(find.text('Eingeben'), warnIfMissed: false);
      await t.pump();
      expect(find.text('Übersetzung nicht verfügbar'), findsNothing);
      expect(u.records, isEmpty);
      await t.tap(find.text('Eingeben'));
      await t.pumpAndSettle();
      expect(u.records, hasLength(1));
    },
  );
  testWidgets(
    'Auto next waits for save and grammar overlay before continuing',
    (t) async {
      final u = TestUser()
        ..prefs = const PracticePreferences(autoNext: true, showGrammar: true)
        ..writeGate = Completer<void>();
      addTearDown(u.close);
      await open(t, u);
      await answer(t, 'walks');
      await t.pump(const Duration(seconds: 3));
      expect(find.text('Wird gespeichert …'), findsWidgets);
      expect(find.text('ungefähr'), findsNothing);
      u.writeGate!.complete();
      await t.pumpAndSettle();
      expect(find.byType(FormInfoSheet), findsOneWidget);
      await t.pump(const Duration(seconds: 3));
      expect(find.text('ungefähr'), findsNothing);
      Navigator.pop(t.element(find.byType(FormInfoSheet)));
      await t.pumpAndSettle();
      await t.pump(const Duration(milliseconds: 1500));
      await t.pumpAndSettle();
      expect(find.text('ungefähr'), findsOneWidget);
      expect(u.records, hasLength(1));
    },
  );
}
