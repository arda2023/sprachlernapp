// Device-only preview: six virtual days, then a three-word real exercise.
// Run explicitly with -t lib/main_completion_preview.dart --profile.
// No synthetic review history or permanent preference changes.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rive/rive.dart' show RiveNative;

import 'domain/streak.dart';
import 'models/home_models.dart';
import 'presentation/celebration_sounds.dart';
import 'presentation/providers/streak_providers.dart';
import 'presentation/providers/learning_providers.dart';
import 'screens/decks/deck_practice_screen.dart';
import 'screens/onboarding/widgets/onboarding_art.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RiveNative.init();
  OnboardingArt.riveReady = true;
  final now = DateTime.now();
  final days = {
    for (var i = 1; i <= 6; i++) DateTime(now.year, now.month, now.day - i),
  };
  runApp(
    ProviderScope(
      overrides: [
        celebrationSoundsProvider.overrideWith(
          (ref) => AudioCelebrationSounds(),
        ),
        // This provider is read by the completion screen after the exercise.
        streakProvider.overrideWith(
          (ref) async => summarizeStreak({...days, calendarDay(now)}, now),
        ),
        learningProgressProvider.overrideWith(
          (ref) async => (
            goal: const DailyGoal(done: 3, target: 3),
            week: WeekProgress(const [
              DayMark.met,
              DayMark.met,
              DayMark.met,
              DayMark.met,
              DayMark.met,
              DayMark.met,
              DayMark.met,
            ]),
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(brightness: Brightness.light),
        darkTheme: buildAppTheme(),
        home: Builder(
          builder: (context) => Scaffold(
            body: SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '6 Tage erreicht',
                      style: AppType.editorial(
                        color: context.appColors.textPrimary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Vorschau · 3 Wörter bis zum Wochenstern'),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const DeckPracticeScreen(
                            deckId: '',
                            mode: DeckPracticeMode.mixed,
                            sessionSize: 3,
                          ),
                        ),
                      ),
                      child: const Text('Übung starten'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
