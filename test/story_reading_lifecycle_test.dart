import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/models/sample_content.dart';
import 'package:sprachapp/screens/stories/story_reader_screen.dart';
import 'package:sprachapp/theme/app_theme.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('background saves the current position before scrolling ends', (
    tester,
  ) async {
    final reported = <double>[];
    await tester.pumpWidget(MaterialApp(
      theme: buildAppTheme(),
      home: StoryReaderScreen(
        story: sampleStories.first,
        text: sampleStoryText(sampleStories.first.id),
        onProgress: reported.add,
      ),
    ));
    await tester.pumpAndSettle();
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(ListView)),
    );
    await gesture.moveBy(const Offset(0, -30));
    await tester.pump();
    await gesture.moveBy(const Offset(0, -220));
    await tester.pump();
    expect(reported, isEmpty);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    expect(reported, hasLength(1));
    expect(reported.single, greaterThan(0));
    expect(reported.single, lessThan(1));
    await gesture.up();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
  });

  testWidgets('background does not overwrite a restored but untouched position', (
    tester,
  ) async {
    final reported = <double>[];
    await tester.pumpWidget(MaterialApp(
      theme: buildAppTheme(),
      home: StoryReaderScreen(
        story: sampleStories.first,
        text: sampleStoryText(sampleStories.first.id),
        initialProgress: 0.5,
        onProgress: reported.add,
      ),
    ));
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    expect(reported, isEmpty);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });
}
