import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/screens/content/widgets/generation_progress_bar.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Widget host({
    bool busy = false,
    bool complete = false,
    bool reduceMotion = false,
  }) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Scaffold(
        body: Center(
          child: SizedBox(
            width: 300,
            child: GenerationProgressBar(busy: busy, complete: complete),
          ),
        ),
      ),
    ),
  );

  double fill(WidgetTester tester) => tester
      .widget<FractionallySizedBox>(
        find.byKey(const ValueKey('generation-progress-fill')),
      )
      .widthFactor!;

  double opacity(WidgetTester tester) =>
      tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity;

  testWidgets('idle bar is invisible but keeps its height', (tester) async {
    await tester.pumpWidget(host());
    expect(opacity(tester), 0);
    expect(fill(tester), 0);
    expect(
      tester.getSize(find.byType(GenerationProgressBar)).height,
      GenerationProgressBar.height,
    );
    expect(find.bySemanticsLabel('Wird generiert'), findsNothing);
  });

  testWidgets('busy announces itself and caps the estimated fill at 90 %', (
    tester,
  ) async {
    await tester.pumpWidget(host(busy: true));
    expect(opacity(tester), 1);
    expect(find.bySemanticsLabel('Wird generiert'), findsOneWidget);
    await tester.pump(const Duration(seconds: 30));
    expect(fill(tester), closeTo(0.9, 0.001));
    expect(find.textContaining('%'), findsNothing);
    await tester.pumpWidget(host());
    await tester.pumpWidget(host(busy: true));
    expect(fill(tester), 0);
  });

  testWidgets('completion fills the bar and announces ready', (tester) async {
    await tester.pumpWidget(host(busy: true));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpWidget(host(busy: true, complete: true));
    await tester.pump(const Duration(milliseconds: 240));
    expect(fill(tester), 1);
    expect(find.bySemanticsLabel('Bereit'), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('reduced motion shows a static fill', (tester) async {
    await tester.pumpWidget(host(busy: true, reduceMotion: true));
    final before = fill(tester);
    await tester.pump(const Duration(seconds: 5));
    expect(fill(tester), before);
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pumpWidget(
      host(busy: true, complete: true, reduceMotion: true),
    );
    expect(fill(tester), 1);
  });
}
