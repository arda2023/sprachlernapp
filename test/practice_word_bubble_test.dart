import 'package:flutter/cupertino.dart' show CupertinoPicker;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/domain/language_profile.dart';
import 'package:sprachapp/screens/decks/deck_practice_screen.dart';
import 'package:sprachapp/screens/decks/widgets/form_info_sheet.dart';
import 'package:sprachapp/screens/decks/widgets/translation_bubble.dart';
import 'package:sprachapp/screens/home/widgets/language_panel.dart';
import 'package:sprachapp/theme/app_theme.dart';
import 'package:sprachapp/widgets/speak_button.dart';

import 'fixtures/deck_repositories.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<List<String>> mount(WidgetTester t, TestUser user) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final calls = <String>[];
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method.startsWith('HapticFeedback')) {
          calls.add('${call.arguments}');
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
      testScope(
        MaterialApp(
          theme: buildAppTheme(),
          home: const DeckPracticeScreen(deckId: 'deck-0'),
        ),
        user: user,
      ),
    );
    await t.pumpAndSettle();
    return calls;
  }

  testWidgets(
    'a tapped word vibrates, gets the bubble with arrow and speaker, '
    'and closes on a second tap',
    (t) async {
      final user = TestUser();
      addTearDown(user.close);
      final haptics = await mount(t, user);
      final word = find.bySemanticsLabel(RegExp(r'^home\..*Übersetzung'));
      final wordRect = t.getRect(word);
      await t.tap(word);
      await t.pumpAndSettle();
      expect(haptics, contains('HapticFeedbackType.lightImpact'));
      final bubble = find.byKey(const ValueKey('translation-bubble'));
      expect(bubble, findsOneWidget);
      expect(find.byType(SpeakButton), findsOneWidget);
      // Above the word (the keyboard sits below), centred on it as far as
      // the screen allows.
      final rect = t.getRect(bubble);
      expect(rect.bottom, lessThanOrEqualTo(wordRect.top));
      expect(rect.left, lessThan(wordRect.center.dx));
      expect(rect.right, greaterThan(wordRect.center.dx));
      await t.tap(word);
      await t.pumpAndSettle();
      expect(find.byType(TranslationBubble), findsNothing);
    },
  );

  testWidgets('the exercise chip opens the form info as a popover', (t) async {
    final user = TestUser();
    addTearDown(user.close);
    await mount(t, user);
    final chip = find.bySemanticsLabel(RegExp('Erklärung anzeigen'));
    await t.tap(chip);
    await t.pumpAndSettle();
    expect(find.byType(FormInfoSheet), findsOneWidget);
    // A popover, not a sheet: it sits right under the chip.
    expect(
      t.getRect(find.byType(FormInfoSheet)).top,
      lessThan(t.getRect(chip).bottom + 60),
    );
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('the language wheel lists every supported language', (t) async {
    await t.pumpWidget(
      testScope(
        MaterialApp(
          theme: buildAppTheme(),
          home: const Scaffold(body: LanguagePanel()),
        ),
      ),
    );
    await t.pumpAndSettle();
    // The wheel builds only the rows in view: check its rows, then that the
    // last language is reachable.
    final picker = t.widget<CupertinoPicker>(find.byType(CupertinoPicker));
    expect(
      picker.childDelegate.estimatedChildCount,
      ContentLanguageProfile.selectable.length,
    );
    final last = ContentLanguageProfile.selectable.last;
    await t.drag(find.byType(CupertinoPicker), const Offset(0, -400));
    await t.pumpAndSettle();
    expect(find.text('${last.flag}  ${last.displayName}'), findsOneWidget);
  });
}
