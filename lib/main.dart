import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'domain/preferences.dart';
import 'presentation/providers/database_providers.dart';
import 'presentation/providers/content_update_provider.dart';
import 'presentation/providers/preferences_provider.dart';
import 'presentation/providers/reading_providers.dart';
import 'presentation/providers/streak_providers.dart';
import 'screens/app_shell.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(
    ProviderScope(
      overrides: [
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
      child: const SprachApp(),
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
      home: const AppShell(),
    );
  }
}
