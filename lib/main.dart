import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'domain/preferences.dart';
import 'presentation/providers/preferences_provider.dart';
import 'screens/app_shell.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: SprachApp()));
}

class SprachApp extends ConsumerWidget {
  const SprachApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
