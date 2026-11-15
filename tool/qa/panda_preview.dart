// Isolated native visual QA. Uses production previews and never writes learning data.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rive/rive.dart' show RiveNative;
import 'package:sprachapp/screens/previews/screen_previews_screen.dart';
import 'package:sprachapp/theme/app_theme.dart';
import 'package:sprachapp/screens/onboarding/widgets/onboarding_art.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RiveNative.init();
  OnboardingArt.riveReady = true;
  runApp(
    ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const ScreenPreviewsScreen(),
      ),
    ),
  );
}
