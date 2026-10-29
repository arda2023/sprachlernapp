import 'presentation/audio/device_speech_playback.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

import 'data/content/bundled_content_updates.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rive/rive.dart' show RiveNative;

import 'domain/preferences.dart';
import 'presentation/celebration_sounds.dart';
import 'presentation/content_startup_gate.dart';
import 'presentation/onboarding_sounds.dart';
import 'presentation/providers/database_providers.dart';
import 'presentation/providers/deck_providers.dart';
import 'presentation/providers/learning_providers.dart';
import 'presentation/providers/content_update_provider.dart';
import 'presentation/providers/onboarding_provider.dart';
import 'presentation/providers/preferences_provider.dart';
import 'presentation/providers/reading_providers.dart';
import 'presentation/providers/runtime_translation_provider.dart';
import 'presentation/providers/streak_providers.dart';
import 'screens/app_shell.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/onboarding/widgets/onboarding_art.dart';
import 'theme/app_theme.dart';
import 'widgets/launch_splash.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The animated launch screen and the curtain over the first screen.
  LaunchSplash.enabled = true;
  // Onboarding animations only; without the native runtime they fall back
  // to stills.
  try {
    await RiveNative.init();
    OnboardingArt.riveReady = true;
  } catch (_) {}
  runApp(
    ProviderScope(
      overrides: [
        celebrationSoundsProvider.overrideWith(
          (ref) => AudioCelebrationSounds(),
        ),
        onboardingSoundsProvider.overrideWith(
          (ref) => AudioOnboardingSounds(),
        ),
        onboardingStoreProvider.overrideWith(
          (ref) => FileJsonStore('onboarding'),
        ),
        celebrationMarksProvider.overrideWith(
          (ref) => FileCelebrationMarks(
            ref.watch(selectedContentLanguageProvider).asData?.value ?? 'en',
          ),
        ),
        readingStoreProvider.overrideWith(
          (ref) => FileJsonStore(
            'reading_progress_${ref.watch(selectedContentLanguageProvider).asData?.value ?? 'en'}',
          ),
        ),
        importStoreProvider.overrideWith(
          (ref) => FileJsonStore(
            'imported_texts_${ref.watch(selectedContentLanguageProvider).asData?.value ?? 'en'}',
          ),
        ),
      ],
      child: ContentStartupGate(
        initialize: () async {
          final bundledUpdateFailures = await applyBundledContentUpdates(
            supportDirectory: await getApplicationSupportDirectory(),
            loadAsset: (key) async {
              try {
                final data = await rootBundle.load(key);
                return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
              } on FlutterError {
                return null;
              }
            },
          );
          for (final failure in bundledUpdateFailures.entries) {
            debugPrint('Gebündeltes Inhaltsupdate ${failure.key}: ${failure.value}');
          }
        },
        child: const SprachApp(),
      ),
    ),
  );
}

class SprachApp extends ConsumerWidget {
  const SprachApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(contentUpdateProvider);
    final motif =
        ref.watch(preferencesProvider).value?.motif ?? AppMotif.automatic;
    return MaterialApp(
      navigatorObservers: [SpeechNavigationObserver()],
      title: 'Sprachapp',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(brightness: Brightness.light),
      darkTheme: buildAppTheme(),
      themeMode: switch (motif) {
        AppMotif.automatic => ThemeMode.system,
        AppMotif.light => ThemeMode.light,
        AppMotif.dark => ThemeMode.dark,
      },
      home: const _Start(),
    );
  }
}

/// Onboarding on first start, the app afterwards; the launch curtain stays
/// over it until Home has its data (no spinners on start).
class _Start extends ConsumerWidget {
  const _Start();

  static bool _settled(AsyncValue<Object?> value) =>
      value.hasValue || value.hasError;

  /// The onboarding needs nothing; Home needs what its first frame shows.
  static bool _ready(WidgetRef ref) => switch (ref.watch(onboardingProvider)) {
    AsyncData(value: true) =>
      _settled(ref.watch(decksProvider)) &&
          _settled(ref.watch(learningProgressProvider)) &&
          _settled(ref.watch(streakProvider)) &&
          _settled(ref.watch(vocabBreakdownProvider)),
    AsyncData() || AsyncError() => true,
    _ => false,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screen = _screen(ref);
    return LaunchSplash.enabled
        ? LaunchCurtain(ready: _ready, child: screen)
        : screen;
  }

  Widget _screen(WidgetRef ref) {
    final done = ref.watch(onboardingProvider);
    return switch (done) {
      AsyncData(value: true) || AsyncError() => const AppShell(),
      AsyncData() => OnboardingScreen(
        onDone: (result) async {
          ref
              .read(onboardingProvider.notifier)
              .complete(interest: result.interest);
          try {
            final preferences = await ref.read(preferencesProvider.future);
            if (preferences.dailyGoal != result.dailyGoal) {
              await ref
                  .read(preferencesProvider.notifier)
                  .save(preferences.copyWith(dailyGoal: result.dailyGoal));
            }
          } catch (_) {
            // The goal stays at its default; it can be changed on Home.
          }
          // Only a switched-on answer is stored; off equals undecided.
          if (result.aiTranslations) {
            try {
              await ref
                  .read(runtimeTranslationProvider)
                  .setOnboardingWordCloudConsent(true);
            } catch (_) {
              // Stays undecided; Settings can switch it on later.
            }
          }
        },
      ),
      _ => const Scaffold(),
    };
  }
}
