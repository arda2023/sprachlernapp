import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/domain/streak.dart';
import 'package:sprachapp/models/home_models.dart';
import 'package:sprachapp/screens/home/widgets/home_header.dart';
import 'package:sprachapp/presentation/providers/streak_providers.dart';
import 'package:sprachapp/screens/home/widgets/streak_strip.dart';
import 'package:sprachapp/theme/app_theme.dart';
import 'package:sprachapp/widgets/svg_glyph.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('full header fits Portuguese and large text on a narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 760),
              textScaler: TextScaler.linear(2),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: HomeHeader(
                flag: '🇧🇷',
                languageName: 'Portugiesisch (Brasilien)',
                goal: const DailyGoal(done: 123, target: 30),
                streak: 123,
                goalPopover: (_) => const SizedBox(),
                streakPopover: (_) => const SizedBox(),
                onSettings: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  final now = DateTime(2026, 10, 20, 12);
  final week = summarizeStreak([
    for (var i = 0; i < 7; i++) DateTime(2026, 10, 20 - i),
  ], now);

  Widget strip(CelebrationMarks marks, {bool visible = true}) => ProviderScope(
    overrides: [celebrationMarksProvider.overrideWithValue(marks)],
    child: MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(
        body: TickerMode(
          enabled: visible,
          child: StreakStrip(summary: week, calendar: (_) => const SizedBox()),
        ),
      ),
    ),
  );

  Transform starScale(WidgetTester tester) => tester
      .widgetList<Transform>(
        find.ancestor(
          of: find.byWidgetPredicate(
            (w) => w is GlyphIcon && w.glyph == AppGlyphs.starSolid,
          ),
          matching: find.byType(Transform),
        ),
      )
      .first;

  testWidgets('the star celebrates once, the first time Home is seen', (
    tester,
  ) async {
    final marks = MemoryCelebrationMarks();
    await tester.pumpWidget(strip(marks));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    // Mid-animation: grown beyond its resting size.
    expect(starScale(tester).transform.getMaxScaleOnAxis(), greaterThan(1.2));
    await tester.pumpAndSettle();
    expect(await marks.celebrated(DateTime(2026, 10, 20)), isTrue);

    // Seen again: no second celebration.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(strip(marks));
    await tester.pump(const Duration(milliseconds: 300));
    expect(starScale(tester).transform.getMaxScaleOnAxis(), closeTo(1, 0.01));
  });

  testWidgets('no celebration while Home is covered', (tester) async {
    final marks = MemoryCelebrationMarks();
    await tester.pumpWidget(strip(marks, visible: false));
    await tester.pumpAndSettle();
    expect(await marks.celebrated(DateTime(2026, 10, 20)), isFalse);

    // Back on Home: now it plays.
    await tester.pumpWidget(strip(marks));
    await tester.pumpAndSettle();
    expect(await marks.celebrated(DateTime(2026, 10, 20)), isTrue);
  });

  testWidgets('reduced motion skips the animation but still marks it', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final marks = MemoryCelebrationMarks();
    await tester.pumpWidget(strip(marks));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(starScale(tester).transform.getMaxScaleOnAxis(), closeTo(1, 0.01));
    expect(await marks.celebrated(DateTime(2026, 10, 20)), isTrue);
  });

  testWidgets('the goal icon turns green once the daily goal is reached', (
    tester,
  ) async {
    Widget badge(int done) => MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(
        body: Center(
          child: GoalBadge(
            goal: DailyGoal(done: done, target: 10),
            onTap: () {},
          ),
        ),
      ),
    );
    Color targetColor() => tester
        .widget<GlyphIcon>(
          find.byWidgetPredicate(
            (w) => w is GlyphIcon && w.glyph == AppGlyphs.target,
          ),
        )
        .color!;
    final green = AppPalette(Brightness.dark).progressWords;

    await tester.pumpWidget(badge(9));
    expect(targetColor(), isNot(green));
    expect(find.text('9/10'), findsOneWidget);

    await tester.pumpWidget(badge(10));
    await tester.pump(const Duration(milliseconds: 200));
    expect(targetColor(), isNot(green)); // still animating
    await tester.pumpAndSettle();
    expect(targetColor(), green);
  });
}
