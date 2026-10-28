import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/main.dart';
import 'package:sprachapp/presentation/onboarding_sounds.dart';
import 'package:sprachapp/presentation/providers/onboarding_provider.dart';
import 'package:sprachapp/presentation/providers/preferences_provider.dart';
import 'package:sprachapp/presentation/providers/reading_providers.dart';
import 'package:sprachapp/screens/app_shell.dart';
import 'package:sprachapp/screens/onboarding/onboarding_screen.dart';
import 'package:sprachapp/screens/onboarding/paywall_screen.dart';
import 'package:sprachapp/screens/onboarding/widgets/account_sheet.dart';
import 'package:sprachapp/screens/onboarding/widgets/onboarding_art.dart';

import 'fixtures/deck_repositories.dart';

class RecordingOnboardingSounds implements OnboardingSounds {
  final calls = <String>[];
  @override
  void select() => calls.add('select');
  @override
  void tick() => calls.add('tick');
  @override
  void paywall() => calls.add('paywall');
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Widget app(JsonStore store, {OnboardingSounds? sounds}) => testScope(
    const SprachApp(),
    library: true,
    overrides: [
      onboardingStoreProvider.overrideWithValue(store),
      if (sounds != null) onboardingSoundsProvider.overrideWithValue(sounds),
    ],
  );

  List<String> recordHaptics(WidgetTester tester) {
    final haptics = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        // selectionClick, lightImpact and mediumImpact all arrive as
        // HapticFeedback.vibrate with their type as the argument.
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

  Future<void> tapLabel(WidgetTester tester, Pattern label) async {
    final target = find.bySemanticsLabel(label);
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  /// Welcome → Reisen → 15 words → tap "train" → plan page.
  Future<void> toPlanPage(WidgetTester tester) async {
    await tapLabel(tester, 'Los geht’s');
    await tapLabel(tester, 'Reisen');
    await tapLabel(tester, 'Weiter');
    await tapLabel(tester, 'Ernsthaft, 15 Wörter pro Tag');
    await tapLabel(tester, 'Weiter');
    await tapLabel(tester, 'train, Übersetzung anzeigen');
    await tapLabel(tester, 'Weiter');
  }

  testWidgets('Five steps, then the plan pill flies into the paywall; '
      '"Kostenlos weiterlernen" opens the app', (tester) async {
    final store = MemoryJsonStore();
    final sounds = RecordingOnboardingSounds();
    final haptics = recordHaptics(tester);
    await tester.pumpWidget(app(store, sounds: sounds));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byType(LingvistMark), findsOneWidget);
    expect(find.bySemanticsLabel('Schritt 1 von 5'), findsOneWidget);

    await tapLabel(tester, 'Los geht’s');
    expect(find.bySemanticsLabel('Schritt 2 von 5'), findsOneWidget);
    // A topic is needed before going on.
    expect(
      tester.getSemantics(find.bySemanticsLabel('Weiter')),
      isSemantics(isButton: true, isEnabled: false),
    );
    await tapLabel(tester, 'Reisen');
    expect(
      tester.getSemantics(find.bySemanticsLabel('Reisen')),
      isSemantics(isButton: true, isSelected: true, hasTapAction: true),
    );
    await tapLabel(tester, 'Weiter');
    await tapLabel(tester, 'Ernsthaft, 15 Wörter pro Tag');
    await tapLabel(tester, 'Weiter');

    // The sample sentence comes from the picked topic.
    await tapLabel(tester, 'train, Übersetzung anzeigen');
    expect(find.bySemanticsLabel('train: der Zug'), findsOneWidget);
    await tapLabel(tester, 'Weiter');

    // "Dein Start steht" ticks the answers off, then "Weiter" lights up.
    expect(find.text('Dein Start steht'), findsOneWidget);
    expect(find.bySemanticsLabel('Geschichten zu Reisen, bereit'), findsOne);
    expect(find.bySemanticsLabel('15 Wörter am Tag, bereit'), findsOne);
    expect(
      find.bySemanticsLabel('Erstes Wort: train · der Zug, bereit'),
      findsOne,
    );
    expect(sounds.calls.where((c) => c == 'tick'), hasLength(3));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));

    await tapLabel(tester, 'Weiter');
    expect(find.byType(PaywallScreen), findsOneWidget);
    expect(sounds.calls.last, 'paywall');
    expect(
      find.bySemanticsLabel('Dein Plan: Reisen, 15 Wörter am Tag'),
      findsOneWidget,
    );
    expect(find.text('Mehr lesen. Deine eigenen Wörter lernen.'), findsOne);
    expect(
      find.bySemanticsLabel(RegExp('^Lies, was dich interessiert.*Reisen')),
      findsOneWidget,
    );
    // Yearly is preselected; its terms sit under the button.
    expect(
      tester.getSemantics(find.bySemanticsLabel(RegExp('^Jährlich, 49,99 €'))),
      isSemantics(isButton: true, isSelected: true, hasTapAction: true),
    );
    expect(
      find.text(
        '49,99 € jährlich. Automatische Verlängerung, im Store kündbar.',
      ),
      findsOneWidget,
    );
    await tapLabel(tester, RegExp('^Monatlich, 9,99 €'));
    expect(
      find.text(
        '9,99 € monatlich. Automatische Verlängerung, im Store kündbar.',
      ),
      findsOneWidget,
    );
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));

    await tapLabel(tester, 'Kostenlos weiterlernen');
    expect(find.byType(PaywallScreen), findsNothing);
    expect(find.byType(AppShell), findsOneWidget);
    expect(await store.read(), {'done': true, 'interest': 'Reisen'});
    final container = ProviderScope.containerOf(
      tester.element(find.byType(AppShell)),
    );
    expect((await container.read(preferencesProvider.future)).dailyGoal, 15);
    // Every tap was felt: selections, the primary actions, the word.
    expect(haptics, contains('HapticFeedbackType.selectionClick'));
    expect(haptics, contains('HapticFeedbackType.mediumImpact'));
    expect(haptics, contains('HapticFeedbackType.lightImpact'));
  });

  testWidgets('Subscribing asks for an account first; the purchase is a '
      'placeholder and the app continues for free', (tester) async {
    final store = MemoryJsonStore();
    await tester.pumpWidget(app(store));
    await tester.pumpAndSettle();
    await toPlanPage(tester);
    await tapLabel(tester, 'Weiter');
    await tapLabel(tester, 'Premium abonnieren');
    expect(find.byType(AccountSheet), findsOneWidget);
    expect(find.text('Konto für dein Abo'), findsOneWidget);
    await tapLabel(tester, 'Mit Apple fortfahren');
    expect(find.byType(AppShell), findsOneWidget);
    expect(find.textContaining('noch nicht freigeschaltet'), findsOneWidget);
    expect(await store.read(), {'done': true, 'interest': 'Reisen'});
  });

  testWidgets('Back from the paywall returns to "Dein Start steht"', (
    tester,
  ) async {
    final store = MemoryJsonStore();
    await tester.pumpWidget(app(store));
    await tester.pumpAndSettle();
    await toPlanPage(tester);
    await tapLabel(tester, 'Weiter');
    expect(find.byType(PaywallScreen), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(PaywallScreen), findsNothing);
    expect(find.text('Dein Start steht'), findsOneWidget);
    expect(await store.read(), isNull);
    // The closing X also continues into the app.
    await tapLabel(tester, 'Weiter');
    await tapLabel(tester, 'Schließen');
    expect(find.byType(AppShell), findsOneWidget);
  });

  testWidgets('Swiping: forward is blocked until a topic is picked', (
    tester,
  ) async {
    final store = MemoryJsonStore();
    final haptics = recordHaptics(tester);
    await tester.pumpWidget(app(store));
    await tester.pumpAndSettle();
    final pages = find.byType(PageView);
    await tester.fling(pages, const Offset(-400, 0), 1200);
    await tester.pumpAndSettle();
    expect(find.text('Wofür lernst du Englisch?'), findsOneWidget);
    // A finger swipe that lands on a new page is felt once.
    expect(haptics, ['HapticFeedbackType.selectionClick']);
    await tester.fling(pages, const Offset(-400, 0), 1200);
    await tester.pumpAndSettle();
    expect(find.text('Wofür lernst du Englisch?'), findsOneWidget);
    expect(find.bySemanticsLabel('Schritt 2 von 5'), findsOneWidget);
    expect(haptics, hasLength(1));

    await tapLabel(tester, 'Alltag');
    await tester.fling(pages, const Offset(-400, 0), 1200);
    await tester.pumpAndSettle();
    expect(find.text('Wie viel möchtest du täglich üben?'), findsOneWidget);
    // Back always works.
    await tester.fling(pages, const Offset(400, 0), 1200);
    await tester.pumpAndSettle();
    expect(find.text('Wofür lernst du Englisch?'), findsOneWidget);
  });

  testWidgets('"Ich habe schon ein Konto" signs in (placeholder) and opens '
      'the app', (tester) async {
    final store = MemoryJsonStore();
    await tester.pumpWidget(app(store));
    await tester.pumpAndSettle();
    await tapLabel(tester, 'Ich habe schon ein Konto');
    expect(find.text('Willkommen zurück'), findsOneWidget);
    await tapLabel(tester, 'Mit Google fortfahren');
    expect(find.byType(AppShell), findsOneWidget);
    expect(find.textContaining('Anmeldung mit Google kommt bald'), findsOne);
  });

  testWidgets('A finished onboarding is not shown again', (tester) async {
    final store = MemoryJsonStore()..write({'done': true});
    await tester.pumpWidget(app(store));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byType(AppShell), findsOneWidget);
  });

  testWidgets('Onboarding and paywall survive large Dynamic Type', (
    tester,
  ) async {
    // iPhone 16 at the largest standard text size.
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(app(MemoryJsonStore()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await toPlanPage(tester);
    expect(tester.takeException(), isNull);
    await tapLabel(tester, 'Weiter');
    expect(find.byType(PaywallScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tapLabel(tester, 'Premium abonnieren');
    expect(find.byType(AccountSheet), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
