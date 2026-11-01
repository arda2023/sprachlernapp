import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/widgets/speak_button.dart';
import 'package:sprachapp/widgets/speaker_icon.dart';
import 'package:sprachapp/widgets/word_bubble.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<double> widthFor(
    WidgetTester tester,
    double screen,
    String word,
  ) async {
    late double width;
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(size: Size(screen, 844)),
        child: Builder(
          builder: (context) {
            width = wordBubbleWidth(context, word: word);
            return const SizedBox();
          },
        ),
      ),
    );
    return width;
  }

  testWidgets('a short word keeps half the screen width', (tester) async {
    expect(await widthFor(tester, 390, 'cat'), 208);
    expect(await widthFor(tester, 800, 'cat'), 400);
  });

  testWidgets('a long word widens the bubble up to the gutters', (
    tester,
  ) async {
    final width = await widthFor(tester, 390, 'neighbourhood');
    expect(width, greaterThan(208));
    expect(width, lessThanOrEqualTo(390 - 32));
  });

  testWidgets('the speak button draws the speaker icon', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: SpeakButton(text: 'cat')),
        ),
      ),
    );
    expect(find.byType(SpeakerIcon), findsOneWidget);
  });
}
