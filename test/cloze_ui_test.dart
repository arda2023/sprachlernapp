import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/models/exercise_models.dart';
import 'package:sprachapp/models/home_models.dart';
import 'package:sprachapp/screens/content/text_exercise_screen.dart';
import 'package:sprachapp/theme/app_theme.dart';

const _text = ExerciseText(
  info: Story(
    id: 'synthetic-cloze-ui',
    title: 'A short journey',
    topic: 'Travel',
    level: 'A2',
    readingMinutes: 1,
  ),
  paragraphs: [
    'We {walked|walk|verb} to the station. '
        'The conductor {misunderstood|misunderstand|verb} the announcement.',
  ],
);

Widget _screen(ExerciseMode mode) => MaterialApp(
  theme: buildAppTheme(),
  home: TextExerciseScreen(text: _text, mode: mode),
);

LinearProgressIndicator _progress(WidgetTester tester) =>
    tester.widget<LinearProgressIndicator>(
      find.byKey(const ValueKey('cloze-progress')),
    );

Future<void> _answer(WidgetTester tester, String answer) async {
  await tester.enterText(find.byType(TextField).first, answer);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pump();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('Cloze progress advances only after a correct typed answer', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_screen(ExerciseMode.verbs));
    expect(_progress(tester).value, 0);
    expect(_progress(tester).color, AppColors.active);
    expect(find.bySemanticsLabel('0 von 2 Lücken gelöst'), findsOneWidget);
    expect(find.text(ExerciseMode.verbs.title), findsNothing);
    expect(find.text('0 von 2'), findsNothing);
    expect(find.text('A short journey'), findsOneWidget);

    await _answer(tester, 'xyz');
    expect(_progress(tester).value, 0);
    expect(find.byType(TextField), findsNWidgets(2));
    await tester.pump(const Duration(milliseconds: 700));
    await _answer(tester, 'walked');
    expect(_progress(tester).value, .5);
    expect(find.bySemanticsLabel('1 von 2 Lücken gelöst'), findsOneWidget);
    expect(find.text('1 von 2'), findsNothing);
    expect(find.byType(TextField), findsOneWidget);
    await _answer(tester, 'misunderstood');
    expect(_progress(tester).value, 1);
    expect(find.byType(TextField), findsNothing);
    await tester.pump(const Duration(seconds: 3));
    semantics.dispose();
  });

  testWidgets('Cloze typed fields and choice placeholders use rounded boxes', (
    tester,
  ) async {
    await tester.pumpWidget(_screen(ExerciseMode.verbs));
    for (final field in tester.widgetList<TextField>(find.byType(TextField))) {
      for (final border in [
        field.decoration!.enabledBorder,
        field.decoration!.focusedBorder,
      ]) {
        expect(border, isA<OutlineInputBorder>());
        expect(
          (border! as OutlineInputBorder).borderRadius,
          BorderRadius.circular(8),
        );
      }
    }
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(_screen(ExerciseMode.anyWordClass));
    expect(find.text(ExerciseMode.anyWordClass.title), findsNothing);
    for (var number = 1; number <= 2; number++) {
      final placeholder = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            (widget.properties.label?.startsWith('Lücke $number von 2,') ??
                false),
      );
      final box = tester.widget<Container>(
        find
            .descendant(of: placeholder, matching: find.byType(Container))
            .first,
      );
      final decoration = box.decoration! as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(8));
      expect(decoration.color, isNotNull);
    }
  });

  for (final width in [320.0, 820.0]) {
    for (final mode in ExerciseMode.values) {
      testWidgets('Cloze ${mode.name} fits ${width.toInt()}px at 2x text', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 900);
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpWidget(_screen(mode));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final bar = tester.getRect(
          find.byKey(const ValueKey('cloze-progress')),
        );
        expect(bar.left, greaterThanOrEqualTo(0));
        expect(bar.right, lessThanOrEqualTo(width));
        if (mode == ExerciseMode.verbs) {
          await tester.enterText(find.byType(TextField).last, 'misunderstood');
          await tester.pumpAndSettle();
          for (final field in find.byType(TextField).evaluate()) {
            expect(
              tester.getSize(find.byWidget(field.widget)).width,
              lessThanOrEqualTo(width - 40),
            );
          }
        }
        await tester.drag(find.byType(ListView), const Offset(0, -500));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
