import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/domain/app_launch_intent.dart';
import 'package:sprachapp/presentation/providers/app_launch_intent_provider.dart';
import 'package:sprachapp/presentation/providers/database_providers.dart';
import 'package:sprachapp/screens/app_shell.dart';
import 'package:sprachapp/screens/decks/deck_practice_screen.dart';
import 'package:sprachapp/theme/app_theme.dart';

import 'fixtures/deck_repositories.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('stale consumers cannot discard a newer tap', () {
    final container = ProviderContainer.test();
    final controller = container.read(appLaunchIntentProvider.notifier);
    controller.publish(const AppLaunchIntent.practice());
    final old = container.read(appLaunchIntentProvider)!;
    controller.publish(const AppLaunchIntent.home());
    final current = container.read(appLaunchIntentProvider)!;
    expect(controller.consume(old), isFalse);
    expect(container.read(appLaunchIntentProvider), same(current));
    expect(controller.consume(current), isTrue);
    expect(container.read(appLaunchIntentProvider), isNull);
    expect(controller.consume(current), isFalse);
  });

  testWidgets(
    'a launch waits for language readiness and opens mixed practice once',
    (tester) async {
      final language = Completer<String>();
      await tester.pumpWidget(
        testScope(
          MaterialApp(theme: buildAppTheme(), home: const AppShell()),
          library: true,
          overrides: [
            selectedContentLanguageProvider.overrideWith(
              (ref) => language.future,
            ),
          ],
        ),
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(AppShell)),
      );
      container
          .read(appLaunchIntentProvider.notifier)
          .publish(const AppLaunchIntent.practice());
      await tester.pump();
      expect(find.byType(DeckPracticeScreen), findsNothing);
      expect(container.read(appLaunchIntentProvider), isNotNull);

      language.complete('en');
      await tester.pumpAndSettle();
      expect(find.byType(DeckPracticeScreen), findsOneWidget);
      expect(
        tester.widget<DeckPracticeScreen>(find.byType(DeckPracticeScreen)).mode,
        DeckPracticeMode.mixed,
      );
      expect(container.read(appLaunchIntentProvider), isNull);
      Navigator.of(tester.element(find.byType(DeckPracticeScreen))).pop();
      await tester.pumpAndSettle();
      expect(find.byType(DeckPracticeScreen), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'home fallback dismisses a foreground route without starting practice',
    (tester) async {
      await tester.pumpWidget(
        testScope(
          MaterialApp(theme: buildAppTheme(), home: const AppShell()),
          library: true,
          overrides: [
            selectedContentLanguageProvider.overrideWith((ref) async => 'en'),
          ],
        ),
      );
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(AppShell));
      final container = ProviderScope.containerOf(context);
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Other route')),
        ),
      );
      await tester.pumpAndSettle();
      container
          .read(appLaunchIntentProvider.notifier)
          .publish(const AppLaunchIntent.home());
      await tester.pumpAndSettle();
      expect(find.text('Other route'), findsNothing);
      expect(find.byType(DeckPracticeScreen), findsNothing);
      expect(container.read(appLaunchIntentProvider), isNull);
      expect(tester.takeException(), isNull);
    },
  );
}
