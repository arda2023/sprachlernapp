import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/main.dart';
import 'package:sprachapp/presentation/providers/onboarding_provider.dart';
import 'package:sprachapp/presentation/providers/preferences_provider.dart';
import 'package:sprachapp/presentation/providers/reading_providers.dart';
import 'package:sprachapp/screens/app_shell.dart';
import 'package:sprachapp/screens/onboarding/onboarding_screen.dart';
import 'package:sprachapp/screens/onboarding/widgets/onboarding_art.dart';

import 'fixtures/deck_repositories.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Widget app(JsonStore store) => testScope(
    const SprachApp(),
    library: true,
    overrides: [onboardingStoreProvider.overrideWithValue(store)],
  );

  Future<void> next(WidgetTester tester, [String label = 'Weiter']) async {
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets('First start shows the onboarding; finishing opens the app', (
    tester,
  ) async {
    final store = MemoryJsonStore();
    await tester.pumpWidget(app(store));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);
    // Without the native runtime the animations fall back to stills.
    expect(find.byType(LingvistMark), findsOneWidget);
    expect(find.text('Lingvist'), findsOneWidget);
    expect(find.bySemanticsLabel('Schritt 1 von 5'), findsOneWidget);

    await next(tester, 'Los geht’s');
    // A topic must be picked before going on.
    final weiter = tester.widget<CupertinoButton>(
      find.ancestor(
        of: find.text('Weiter'),
        matching: find.byType(CupertinoButton),
      ),
    );
    expect(weiter.onPressed, isNull);
    await tester.tap(find.bySemanticsLabel('Reisen'));
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.bySemanticsLabel('Reisen')),
      isSemantics(isButton: true, isSelected: true, hasTapAction: true),
    );
    await next(tester);

    // Daily goal: 10 is preselected, 15 is chosen.
    expect(
      tester.getSemantics(find.bySemanticsLabel('Normal, 10 Wörter pro Tag')),
      isSemantics(isButton: true, isSelected: true, hasTapAction: true),
    );
    await tester.tap(find.bySemanticsLabel('Ernsthaft, 15 Wörter pro Tag'));
    await tester.pumpAndSettle();
    await next(tester);

    // The sample sentence comes from the picked topic; a tap shows German.
    expect(find.text('train'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('train, Übersetzung anzeigen'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('train: der Zug'), findsOneWidget);
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await next(tester);

    for (final label in [
      'Mit Apple fortfahren',
      'Mit Google fortfahren',
      'Mit E-Mail fortfahren',
    ]) {
      expect(
        tester.getSemantics(find.bySemanticsLabel(label)),
        isSemantics(isButton: true, hasTapAction: true),
      );
    }
    await tester.tap(find.bySemanticsLabel('Mit Apple fortfahren'));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byType(AppShell), findsOneWidget);
    expect(
      find.textContaining('Anmeldung mit Apple kommt bald'),
      findsOneWidget,
    );
    expect(await store.read(), {'done': true, 'interest': 'Reisen'});
    final container = ProviderScope.containerOf(
      tester.element(find.byType(AppShell)),
    );
    expect((await container.read(preferencesProvider.future)).dailyGoal, 15);
  });

  testWidgets('A finished onboarding is not shown again', (tester) async {
    final store = MemoryJsonStore()..write({'done': true});
    await tester.pumpWidget(app(store));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byType(AppShell), findsOneWidget);
  });

  testWidgets('"Ich habe schon ein Konto" jumps to sign-in; back returns', (
    tester,
  ) async {
    final store = MemoryJsonStore();
    await tester.pumpWidget(app(store));
    await tester.pumpAndSettle();
    await next(tester, 'Ich habe schon ein Konto');
    expect(find.text('Speichere deinen Fortschritt'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Zurück'));
    await tester.pumpAndSettle();
    expect(find.text('Tippe auf ein Wort'), findsOneWidget);
    await next(tester);
    await tester.tap(find.text('Ohne Konto weiter'));
    await tester.pumpAndSettle();
    expect(find.byType(AppShell), findsOneWidget);
    expect(find.textContaining('kommt bald'), findsNothing);
    expect(await store.read(), {'done': true, 'interest': 'Alltag'});
  });

  testWidgets('Onboarding survives large Dynamic Type', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(app(MemoryJsonStore()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await next(tester, 'Los geht’s');
    await tester.tap(find.bySemanticsLabel('Beruf'));
    await tester.pumpAndSettle();
    await next(tester);
    expect(tester.takeException(), isNull);
    await next(tester);
    expect(tester.takeException(), isNull);
    await next(tester);
    expect(tester.takeException(), isNull);
  });
}
