import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/domain/preferences.dart';
import 'package:sprachapp/domain/streak.dart';
import 'package:sprachapp/models/home_models.dart';
import 'package:sprachapp/presentation/celebration_sounds.dart';
import 'package:sprachapp/presentation/providers/streak_providers.dart';
import 'package:sprachapp/screens/completion/practice_completion_screen.dart';
import 'package:sprachapp/screens/completion/widgets/stacked_word_cards.dart';
import 'package:sprachapp/screens/decks/deck_practice_screen.dart';
import 'package:sprachapp/theme/app_theme.dart';

import 'fixtures/deck_repositories.dart';

class RecordingSounds implements CelebrationSounds {
  final calls = <String>[];
  @override
  void charge() => calls.add('charge');
  @override
  void stopCharge() => calls.add('stop');
  @override
  void check() => calls.add('check');
  @override
  void star() => calls.add('star');
}

StreakSummary summary({required int days, bool star = false}) {
  final today = DateTime(2026, 10, 24);
  return StreakSummary(
    current: days,
    starDays: star ? {today} : const {},
    activeDays: {
      for (var i = 0; i < days; i++) today.subtract(Duration(days: i)),
    },
    barFilled: star ? streakBarDays : days,
    barMissed: false,
    starToday: star,
    practicedToday: true,
  );
}

final words = <CompletionWord>[
  for (final (form, de) in [
    ('walks', 'geht'),
    ('about', 'ungefähr'),
    ('went', 'ging'),
    ('window', 'Fenster'),
    ('door', 'Tür'),
  ])
    CompletionWord(
      form: form,
      translation: de,
      sentence: 'A sentence with $form in it.',
      isNew: true,
    ),
];

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  /// Haptic types sent to the platform during the test.
  List<String> recordHaptics(WidgetTester tester) {
    final haptics = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          haptics.add(call.arguments as String);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    return haptics;
  }

  Widget screen(
    StreakSummary streak, {
    CelebrationSounds sounds = const SilentCelebrationSounds(),
    CelebrationMarks? marks,
    bool reduceMotion = false,
  }) => ProviderScope(
    overrides: [
      celebrationSoundsProvider.overrideWithValue(sounds),
      if (marks != null) celebrationMarksProvider.overrideWithValue(marks),
    ],
    child: MaterialApp(
      theme: buildAppTheme(),
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(390, 844),
          disableAnimations: reduceMotion,
        ),
        child: PracticeCompletionScreen(
          streak: streak,
          goal: const DailyGoal(done: 12, target: 10),
          words: words,
        ),
      ),
    ),
  );

  testWidgets('Day 4: the bar charges, checks pop with buzz and sound, '
      'then the summary settles', (tester) async {
    final haptics = recordHaptics(tester);
    final sounds = RecordingSounds();
    await tester.pumpWidget(screen(summary(days: 4), sounds: sounds));
    // Mid-charge: the content below is still hidden, the phone buzzes.
    for (var i = 0; i < 70; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(sounds.calls.first, 'charge');
    expect(
      haptics.where((h) => h == 'HapticFeedbackType.lightImpact'),
      isNotEmpty,
    );
    final weiter = find.ancestor(
      of: find.text('Weiter'),
      matching: find.byType(Opacity),
    );
    expect(tester.widget<Opacity>(weiter.first).opacity, 0);

    await tester.pumpAndSettle();
    expect(sounds.calls, [
      'charge',
      'check',
      'check',
      'check',
      'check',
      'stop',
    ]);
    expect(
      haptics.where((h) => h == 'HapticFeedbackType.mediumImpact'),
      hasLength(4),
    );
    expect(find.text('Sehr gut!'), findsOneWidget);
    expect(
      find.text('Tag 4 in Folge. Noch 3 Tage bis zum Wochenstern.'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Streak 4 Tage, 4 von 7 Tagen dieser Woche'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Streak: 4 Tage in Folge'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Tagesziel: 12 von 10 Wörtern geübt'),
      findsOneWidget,
    );
    expect(find.text('12/10'), findsOneWidget);
    expect(find.text('Neue Wörter'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^walks, geht, neu')), findsOneWidget);
    expect(tester.widget<Opacity>(weiter.first).opacity, 1);
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
  });

  testWidgets('Day 7: the star flips and is not celebrated again on Home', (
    tester,
  ) async {
    final haptics = recordHaptics(tester);
    final sounds = RecordingSounds();
    final marks = MemoryCelebrationMarks();
    await tester.pumpWidget(
      screen(summary(days: 7, star: true), sounds: sounds, marks: marks),
    );
    await tester.pumpAndSettle();
    expect(sounds.calls.where((c) => c == 'check'), hasLength(6));
    expect(sounds.calls.last, 'star');
    expect(haptics, contains('HapticFeedbackType.heavyImpact'));
    expect(find.text('Wochenstern geholt!'), findsOneWidget);
    expect(await marks.celebrated(DateTime(2026, 10, 24)), isTrue);
  });

  testWidgets('Reduced motion shows the final state at once, silently', (
    tester,
  ) async {
    final sounds = RecordingSounds();
    await tester.pumpWidget(
      screen(summary(days: 2), sounds: sounds, reduceMotion: true),
    );
    await tester.pump();
    expect(sounds.calls, isEmpty);
    expect(find.text('Sehr gut!'), findsOneWidget);
    final weiter = find.ancestor(
      of: find.text('Weiter'),
      matching: find.byType(Opacity),
    );
    expect(tester.widget<Opacity>(weiter.first).opacity, 1);
  });

  testWidgets('Word cards stick at the top and the next one covers them', (
    tester,
  ) async {
    await tester.pumpWidget(screen(summary(days: 3)));
    await tester.pumpAndSettle();
    final walks = find.text('walks');
    final scrollable = find.byType(Scrollable).first;
    final viewportTop = tester.getTopLeft(scrollable).dy;

    await tester.drag(scrollable, const Offset(0, -900));
    await tester.pumpAndSettle();

    // The first card stays pinned near the top instead of leaving.
    expect(tester.getTopLeft(walks).dy, greaterThanOrEqualTo(viewportTop));
    expect(tester.getTopLeft(walks).dy, lessThan(viewportTop + 60));
  });

  testWidgets('Completion survives large Dynamic Type', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(screen(summary(days: 5)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Reaching the daily goal ends the session on the completion '
      'screen; "Weiter" goes back', (tester) async {
    final user = TestUser()..prefs = const PracticePreferences(dailyGoal: 2);
    addTearDown(user.close);
    await tester.pumpWidget(
      testScope(
        MaterialApp(
          theme: buildAppTheme(),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const DeckPracticeScreen(
                        deckId: 'deck-0',
                        sessionSize: 2,
                        mode: DeckPracticeMode.learn,
                      ),
                    ),
                  ),
                  child: const Text('Start'),
                ),
              ),
            ),
          ),
        ),
        user: user,
      ),
    );
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    for (final form in ['walks', 'about']) {
      await tester.enterText(find.byType(TextField), form);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Weiter'));
      await tester.pumpAndSettle();
    }
    expect(find.byType(PracticeCompletionScreen), findsOneWidget);
    expect(find.text('Neue Wörter'), findsOneWidget);
    expect(find.text('walks'), findsOneWidget);
    expect(find.text('2/2'), findsOneWidget);
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();
    expect(find.text('Start'), findsOneWidget);
  });
}
