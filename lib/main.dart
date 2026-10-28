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
import 'presentation/providers/content_update_provider.dart';
import 'presentation/providers/onboarding_provider.dart';
import 'presentation/providers/preferences_provider.dart';
import 'presentation/providers/reading_providers.dart';
import 'presentation/providers/streak_providers.dart';
import 'screens/app_shell.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/onboarding/widgets/onboarding_art.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

/// Onboarding on first start, the app afterwards.
class _Start extends ConsumerWidget {
  const _Start();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        },
      ),
      _ => const Scaffold(),
    };
  }
}
