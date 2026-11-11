import 'presentation/audio/device_speech_playback.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'data/platform/json_store.dart';
import 'data/sync/sync_json_store.dart';
import 'presentation/providers/account_provider.dart';
import 'presentation/providers/learning_sync_provider.dart';
import 'screens/web/web_app_gate.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:rive/rive.dart' show RiveNative;

import 'domain/preferences.dart';
import 'presentation/celebration_sounds.dart';
import 'presentation/onboarding_sounds.dart';
import 'presentation/providers/personal_learning_provider.dart';
import 'presentation/providers/database_providers.dart';
import 'presentation/providers/billing_provider.dart';
import 'presentation/providers/deck_providers.dart';
import 'presentation/providers/language_selection_provider.dart';
import 'presentation/providers/learning_providers.dart';
import 'presentation/providers/content_update_provider.dart';
import 'presentation/providers/onboarding_provider.dart';
import 'presentation/providers/preferences_provider.dart';
import 'presentation/providers/purchase_provider.dart';
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
  LaunchSplash.enabled = !kIsWeb;
  // Onboarding animations only; without the native runtime they fall back
  // to stills.
  try {
    if (!kIsWeb) {
      await RiveNative.init();
      OnboardingArt.riveReady = true;
    }
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
          (ref) => platformJsonStore('onboarding'),
        ),
        celebrationMarksProvider.overrideWith(
          (ref) => FileCelebrationMarks(
            ref.watch(selectedContentLanguageProvider).asData?.value ?? 'en',
          ),
        ),
        readingStoreProvider.overrideWith(
          (ref) => _accountStore(ref, 'reading_progress'),
        ),
        importStoreProvider.overrideWith(
          (ref) => _accountStore(ref, 'imported_texts', list: true),
        ),
      ],
      child: const SprachApp(),
    ),
  );
}

JsonStore _accountStore(Ref ref, String prefix, {bool list = false}) {
  ref.watch(accountSessionProvider);
  final database = ref.watch(userDatabaseProvider.future);
  final language = ref.watch(selectedContentLanguageProvider).asData?.value ?? 'en';
  final name = '${prefix}_$language';
  final owner = ref.read(contentAuthProvider).localOwner;
  return SyncJsonStore(database, name, list: list,
      legacy: AccountLegacyJsonStore(name, owner),
      isCurrent: () => ref.mounted && ref.read(contentAuthProvider).localOwner == owner);
}

class SprachApp extends ConsumerWidget {
  const SprachApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep background sync alive without rebuilding routes/themes for status.
    ref.listen(learningSyncProvider, (_, _) {});
    final account = ref.watch(accountSessionProvider).value;
    ref.watch(billingProvider);
    ref.watch(contentUpdateProvider);
    // Keeps the account's Premium check alive from launch and after any
    // sign-in, not only while a Premium surface happens to be on screen.
    ref.listen(purchaseProvider, (_, _) {});
    final motif =
        ref.watch(preferencesProvider).value?.motif ?? AppMotif.automatic;
    return MaterialApp(
      key: ValueKey(account?.id),
      navigatorObservers: [SpeechNavigationObserver()],
      title: 'Linglossa',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(brightness: Brightness.light),
      darkTheme: buildAppTheme(),
      themeMode: switch (motif) {
        AppMotif.automatic => ThemeMode.system,
        AppMotif.light => ThemeMode.light,
        AppMotif.dark => ThemeMode.dark,
      },
      builder: kIsWeb ? (context, child) => LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth.clamp(0.0, 1440.0);
        return Center(child: SizedBox(width: width, child: MediaQuery(
          data: MediaQuery.of(context).copyWith(size: Size(width, constraints.maxHeight)),
          child: child ?? const SizedBox.shrink(),
        )));
      }) : null,
      home: kIsWeb ? const WebAppGate() : const _Start(),
    );
  }
}

/// Onboarding on first start, the app afterwards; the launch curtain stays
/// over it until Home has its data (no spinners on start), and comes back
/// while another learning language loads.
class _Start extends ConsumerWidget {
  const _Start();

  /// Settled for the current language and pack: a reload of the same pack
  /// keeps its value, another language counts as loading again.
  static bool _settled<T>(WidgetRef ref, ProviderListenable<AsyncValue<T>> p) =>
      !watchContentStable(ref, p).isLoading;

  /// The onboarding needs nothing; Home needs what its first frame shows.
  static bool _ready(WidgetRef ref) => switch (ref.watch(onboardingProvider)) {
    // The key resolves after the switch reports done; until then the views
    // still hold the previous language and would lift the curtain early.
    AsyncData(value: true) =>
      !ref.watch(languageSelectionProvider).switching &&
          !ref.watch(activeContentKeyProvider).isLoading &&
          _settled(ref, decksProvider) &&
          _settled(ref, learningProgressProvider) &&
          _settled(ref, streakProvider) &&
          _settled(ref, vocabBreakdownProvider),
    AsyncData() || AsyncError() => true,
    _ => false,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Home's data loads while the onboarding runs, so the app is ready when
    // the onboarding ends instead of showing spinners.
    if (ref.watch(onboardingProvider) case AsyncData(:final value)
        when value != true) {
      ref.listen(decksProvider, (_, _) {});
      ref.listen(learningProgressProvider, (_, _) {});
      ref.listen(streakProvider, (_, _) {});
      ref.listen(vocabBreakdownProvider, (_, _) {});
    }
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
          // Only a switched-on answer is stored; off equals undecided. The
          // one switch covers translations and private learning cards.
          if (result.aiTranslations) {
            try {
              await ref
                  .read(runtimeTranslationProvider)
                  .setOnboardingWordCloudConsent(true);
            } catch (_) {
              // Stays undecided; Settings can switch it on later.
            }
            try {
              await ref
                  .read(personalLearningClientProvider)
                  .setDeviceConsent(true);
            } catch (_) {
              // Same: Settings can switch it on later.
            }
          }
        },
      ),
      _ => const Scaffold(),
    };
  }
}
