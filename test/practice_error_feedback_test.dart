import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sprachapp/screens/decks/widgets/practice_chrome.dart';
import 'package:sprachapp/presentation/practice/deck_session_controller.dart';
import 'package:sprachapp/domain/srs_state.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/screens/decks/deck_practice_screen.dart';
import 'package:sprachapp/theme/app_theme.dart';

import 'fixtures/deck_repositories.dart';

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    if (const bool.fromEnvironment('ERROR_SCREENSHOTS')) {
      final families = <String, String>{};
      for (final weight in FontWeight.values) {
        families[AppType.chrome(weight: weight).fontFamily!] =
            '/System/Library/Fonts/Supplemental/Arial.ttf';
        families[AppType.editorial(weight: weight).fontFamily!] =
            '/System/Library/Fonts/Supplemental/Georgia.ttf';
      }
      families['packages/cupertino_icons/CupertinoIcons'] = 'build/unit_test_assets/packages/cupertino_icons/assets/CupertinoIcons.ttf';
      families['MaterialIcons'] =
          'build/unit_test_assets/fonts/MaterialIcons-Regular.otf';
      for (final entry in families.entries) {
        final loader = FontLoader(entry.key)
          ..addFont(
            File(entry.value)
                .readAsBytes()
                .then((b) => ByteData.sublistView(b)),
          );
        await loader.load();
      }
    }
  });
  testWidgets(
    '0/400/1500ms: synchronized transforms, stable geometry, persistent field',
    (tester) async {
      final user = await mount(tester);
      await tester.enterText(find.byType(TextField), 'zzzzz');
      await tester.pumpAndSettle();
      final initialButton = tester.getRect(
        find.byKey(const ValueKey('practice-button-shake')),
      );
      final initialField = tester.getRect(
        find.byKey(const ValueKey('practice-field-shake')),
      );
      await tester.tap(find.text('Eingeben'));
      await tester.pump();
      expect(find.text('Falsch'), findsOneWidget);
      expect(toolbar(tester).error, isTrue);
      expect(fieldIsRed(tester), isTrue);
      expect(offset(tester, 'button'), 0);
      expect(
        tester.getRect(find.byKey(const ValueKey('practice-button-shake'))),
        initialButton,
      );
      await tester.pump(const Duration(milliseconds: 50));
      expect(offset(tester, 'button').abs(), greaterThan(0));
      expect(offset(tester, 'button').abs(), lessThanOrEqualTo(5));
      expect(offset(tester, 'button'), offset(tester, 'field'));
      await tester.pump(const Duration(milliseconds: 350));
      expect(offset(tester, 'button'), 0);
      expect(offset(tester, 'field'), 0);
      expect(
        tester.getRect(find.byKey(const ValueKey('practice-field-shake'))),
        initialField,
      );
      expect(
        tester.getRect(find.byKey(const ValueKey('practice-button-shake'))),
        initialButton,
      );
      await tester.pump(const Duration(milliseconds: 1099));
      expect(toolbar(tester).error, isTrue);
      await tester.pump(const Duration(milliseconds: 1));
      expect(toolbar(tester).error, isFalse);
      expect(fieldIsRed(tester), isTrue);
      expect(find.text('Falsch'), findsNothing);
      expect(user.records, isEmpty);
      await close(tester, user);
    },
  );

  testWidgets(
    'selection/focus preserves red; replace, delete, paste and whitespace end it',
    (tester) async {
      for (final replacement in ['q', '', 'pasted', '   ']) {
        final user = await mount(tester);
        await tester.enterText(find.byType(TextField), 'zzzzz');
        await tester.pump();
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();
        expect(fieldIsRed(tester), isTrue);
        final field = tester.widget<TextField>(find.byType(TextField));
        field.controller!.selection = const TextSelection.collapsed(offset: 0);
        field.focusNode!.unfocus();
        await tester.pump();
        expect(fieldIsRed(tester), isTrue);
        expect(toolbar(tester).error, isTrue);
        field.focusNode!.requestFocus();
        await tester.pump();
        await tester.enterText(find.byType(TextField), replacement);
        await tester.pump();
        expect(fieldIsRed(tester), isFalse);
        expect(toolbar(tester).error, isFalse);
        expect(toolbar(tester).hasInput, replacement.trim().isNotEmpty);
        await tester.pump(const Duration(milliseconds: 1600));
        expect(toolbar(tester).error, isFalse);
        expect(user.records, isEmpty);
        await close(tester, user);
      }
    },
  );

  testWidgets(
    'rapid second wrong submission restarts timer without locking keyboard or button',
    (tester) async {
      final user = await mount(tester);
      await tester.enterText(find.byType(TextField), 'zzzzz');
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Falsch'));
      await tester.pump();
      expect(session(tester).pass!.errorCount, 2);
      expect(toolbar(tester).error, isTrue);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField)).decoration!.hintText,
        'wa…',
      );
      await tester.pump(const Duration(milliseconds: 1100)); // old deadline
      expect(toolbar(tester).error, isTrue);
      await tester.pump(const Duration(milliseconds: 400));
      expect(toolbar(tester).error, isFalse);
      expect(fieldIsRed(tester), isTrue);
      expect(find.text('Wort erfahren'), findsOneWidget);
      expect(session(tester).pass!.errorCount, 2);
      expect(user.records, isEmpty);
      await close(tester, user);
    },
  );

  testWidgets(
    'success before timeout saves once, next card and history stay clean',
    (tester) async {
      final user = await mount(tester);
      await tester.enterText(find.byType(TextField), 'zzzzz');
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'walks');
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(user.records, hasLength(1));
      expect(user.records.values.single.errorCount, 1);
      expect(find.byKey(const ValueKey('practice-success')), findsOneWidget);
      expect(fieldIsRed(tester), isFalse);
      await tester.tap(find.text('Weiter'));
      await tester.pumpAndSettle();
      final nextId = session(tester).pass!.id;
      await tester.enterText(find.byType(TextField), 'zzzzz');
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.fling(find.text('Neues Wort'), const Offset(250, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.textContaining('Rückblick'), findsOneWidget);
      expect(fieldIsRed(tester), isFalse);
      await tester.pump(const Duration(seconds: 2));
      expect(user.records, hasLength(1));
      expect(session(tester).pass!.id, nextId);
      await close(tester, user);
    },
  );

  testWidgets(
    'neutral retries stay neutral; wrong form is red and retains its hint',
    (tester) async {
      final user = await mount(tester);
      for (final answer in ['waljs', 'strolls']) {
        await tester.enterText(find.byType(TextField), answer);
        await tester.pump();
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();
        expect(toolbar(tester).error, isFalse);
        expect(fieldIsRed(tester), isFalse);
        expect(session(tester).pass!.errorCount, 0);
      }
      await tester.enterText(find.byType(TextField), 'walking');
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(toolbar(tester).error, isTrue);
      expect(fieldIsRed(tester), isTrue);
      expect(find.textContaining('Andere Form'), findsOneWidget);
      expect(session(tester).pass!.errorCount, 1);
      await close(tester, user);
    },
  );

  testWidgets(
    'reduced motion, reveal and disposal cancel obsolete feedback without haptics',
    (tester) async {
      final calls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          calls.add(call.method);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final user = await mount(tester, reduced: true);
      await tester.enterText(find.byType(TextField), 'zzzzz');
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(offset(tester, 'button'), 0);
      expect(offset(tester, 'field'), 0);
      expect(toolbar(tester).error, isTrue);
      expect(fieldIsRed(tester), isTrue);
      toolbar(tester).onReveal();
      await tester.pump();
      expect(toolbar(tester).error, isFalse);
      expect(fieldIsRed(tester), isFalse);
      expect(session(tester).pass!.revealed, isTrue);
      await tester.enterText(find.byType(TextField), 'zzzzz');
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(toolbar(tester).error, isTrue);
      await close(tester, user);
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
      expect(
        calls.where((c) => c.contains('Haptic') || c.contains('SystemSound')),
        isEmpty,
      );
    },
  );

  testWidgets('keyboard-inset visual evidence', (tester) async {
    final user = TestUser();
    final key = GlobalKey();
    final scale = ValueNotifier<double>(1);
    addTearDown(scale.dispose);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      testScope(
        MaterialApp(
          theme: buildAppTheme(),
          home: RepaintBoundary(
            key: key,
            child: ValueListenableBuilder<double>(
              valueListenable: scale,
              builder: (context, value, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(value),
                ),
                child: child!,
              ),
              child: const DeckPracticeScreen(deckId: 'deck-0', sessionSize: 2),
            ),
          ),
        ),
        user: user,
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'zzzzz');
    await tester.pumpAndSettle();
    expect(tester.getTopRight(find.bySemanticsLabel('Eingeben')).dx, closeTo(378, 1));
    await capture(tester, key, 'ready');
    await tester.tap(find.text('Eingeben'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await capture(tester, key, 'wrong');
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.getTopRight(find.bySemanticsLabel('Falsch')).dx, closeTo(378, 1));
    await capture(tester, key, '400ms');
    await tester.pump(const Duration(milliseconds: 1100));
    expect(tester.getTopRight(find.bySemanticsLabel('Eingeben')).dx, closeTo(378, 1));
    await capture(tester, key, '1500ms');
    await tester.enterText(find.byType(TextField), 'walks');
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(user.records, hasLength(1));
    final check = find.byKey(const ValueKey('practice-success'));
    expect(check, findsOneWidget);
    expect(tester.getTopRight(find.bySemanticsLabel('Weiter')).dx, closeTo(378, 1));
    expect(tester.getTopRight(check).dx,
        lessThan(tester.getTopLeft(find.text('Weiter')).dx));
    await capture(tester, key, 'success');
    scale.value = 2;
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.getTopRight(find.bySemanticsLabel('Weiter')).dx, closeTo(378, 1));
    expect(tester.getBottomLeft(find.bySemanticsLabel('Weiter')).dy,
        lessThanOrEqualTo(544));
    await capture(tester, key, 'large-keyboard');
    await tester.pumpWidget(const SizedBox());
    await user.close();
  });
}

Future<void> capture(WidgetTester tester, GlobalKey key, String state) async {
  if (!const bool.fromEnvironment('ERROR_SCREENSHOTS')) return;
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    const phase = String.fromEnvironment('ERROR_PHASE', defaultValue: 'after');
    final dir = Directory('docs/evidence/practice-error-feedback')
      ..createSync(recursive: true);
    File('${dir.path}/$phase-$state.png')
        .writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

Future<TestUser> mount(WidgetTester tester, {bool reduced = false}) async {
  final user = TestUser();
  await tester.pumpWidget(
    testScope(
      MaterialApp(
        theme: buildAppTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
          child: child!,
        ),
        home: const DeckPracticeScreen(deckId: 'deck-0', sessionSize: 2),
      ),
      user: user,
    ),
  );
  await tester.pumpAndSettle();
  return user;
}

Future<void> close(WidgetTester tester, TestUser user) async {
  await tester.pumpWidget(const SizedBox());
  await user.close();
}

PracticeAnswerToolbar toolbar(WidgetTester tester) =>
    tester.widget<PracticeAnswerToolbar>(find.byType(PracticeAnswerToolbar));
bool fieldIsRed(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField)).decoration!.fillColor ==
    tester.element(find.byType(TextField)).appColors.errorTint;
double offset(WidgetTester tester, String part) => tester
    .widget<Transform>(find.byKey(ValueKey('practice-$part-shake')))
    .transform
    .storage[12];
DeckSessionState session(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(DeckPracticeScreen)))
        .read(
          deckSessionControllerProvider((
            deckId: 'deck-0',
            kind: DeckSessionKind.learn,
            size: 2,
          )),
        );
