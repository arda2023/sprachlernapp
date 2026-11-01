import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/main.dart';
import 'package:sprachapp/data/billing/purchase_gateway.dart';
import 'package:sprachapp/presentation/providers/account_provider.dart';
import 'package:sprachapp/presentation/providers/purchase_provider.dart';
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

class _AccountActions implements AccountActions {
  @override
  Future<void> signIn(AccountIdentityProvider provider) async {}
  @override
  Future<void> sendCode(String email) async {}
  @override
  Future<void> verifyCode(String email, String code) async {}
  @override
  Future<void> signOut() async {}
}

class _FakePurchaseController extends PurchaseController {
  _FakePurchaseController({this.initialState, this.restoreError});

  final PurchaseState? initialState;
  final String? restoreError;

  static const _products = [
    PurchaseProduct(
      productId: 'yearly-test',
      plan: PurchasePlan.yearly,
      localizedPrice: '49,99 €',
      localizedPeriod: 'pro Jahr',
      isRecommended: true,
    ),
    PurchaseProduct(
      productId: 'monthly-test',
      plan: PurchasePlan.monthly,
      localizedPrice: '9,99 €',
      localizedPeriod: 'pro Monat',
      isRecommended: false,
    ),
  ];

  @override
  PurchaseState build() =>
      initialState ??
      const PurchaseState(
        phase: PurchasePhase.ready,
        products: _products,
        selectedProductId: 'yearly-test',
        billingReady: true,
        hasVerifiedAccount: false,
        purchaseAllowed: false,
      );

  @override
  Future<void> load() async {}

  @override
  Future<void> restore() async {
    final error = restoreError;
    if (error == null) return;
    state = state.copyWith(phase: PurchasePhase.failed, errorMessage: error);
  }

  @override
  void selectProduct(String productId) {
    state = state.copyWith(selectedProductId: productId);
  }
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Widget app(
    JsonStore store, {
    OnboardingSounds? sounds,
    PurchaseState? purchaseState,
    String? restoreError,
  }) => testScope(
    const SprachApp(),
    library: true,
    overrides: [
      onboardingStoreProvider.overrideWithValue(store),
      accountActionsProvider.overrideWithValue(_AccountActions()),
      purchaseProvider.overrideWith(
        () => _FakePurchaseController(
          initialState: purchaseState,
          restoreError: restoreError,
        ),
      ),
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
    expect(find.byType(LinglossaMark), findsOneWidget);
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
    // The only AI switch: shown here, on unless switched off (31.10.2026).
    expect(find.text('KI-Übersetzungen und Lernkarten'), findsOneWidget);
    expect(
      tester.widget<CupertinoSwitch>(find.byType(CupertinoSwitch)).value,
      isTrue,
    );
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
    // Yearly is preselected and uses the Store-localized price and period.
    expect(
      tester.getSemantics(
        find.bySemanticsLabel(RegExp('^Jährlich, 49,99 € pro Jahr')),
      ),
      isSemantics(isButton: true, isSelected: true, hasTapAction: true),
    );
    expect(
      find.text(
        '49,99 € pro Jahr. Automatische Verlängerung, im Store kündbar.',
      ),
      findsOneWidget,
    );
    await tapLabel(tester, RegExp('^Monatlich, 9,99 € pro Monat'));
    expect(
      find.text(
        '9,99 € pro Monat. Automatische Verlängerung, im Store kündbar.',
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

  testWidgets('Purchase stays disabled until its legal and account gates pass; '
      'restore requires a verified account', (tester) async {
    final store = MemoryJsonStore();
    await tester.pumpWidget(app(store));
    await tester.pumpAndSettle();
    await toPlanPage(tester);
    await tapLabel(tester, 'Weiter');
    expect(
      tester.getSemantics(find.bySemanticsLabel('Premium abonnieren')),
      isSemantics(isButton: true, isEnabled: false),
    );
    expect(
      find.textContaining('Käufe sind in diesem Build noch nicht verfügbar'),
      findsOneWidget,
    );
    await tapLabel(tester, 'Wiederherstellen');
    expect(find.byType(AccountSheet), findsOneWidget);
    expect(find.text('Konto für dein Abo'), findsOneWidget);
    await tapLabel(tester, 'Mit Apple fortfahren');
    expect(find.byType(PaywallScreen), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);
    expect(await store.read(), isNull);
  });

  testWidgets(
    'Android without store offers account access rather than disabled purchase',
    (tester) async {
      const state = PurchaseState(
        phase: PurchasePhase.failed,
        billingReady: false,
        errorMessage: 'Premium-Käufe sind auf diesem Gerät nicht verfügbar.',
      );
      await tester.pumpWidget(app(MemoryJsonStore(), purchaseState: state));
      await tester.pumpAndSettle();
      await toPlanPage(tester);
      await tapLabel(tester, 'Weiter');
      expect(find.text('Mit Konto freischalten'), findsOneWidget);
      expect(find.text('Premium abonnieren'), findsNothing);
      expect(
        find.text('Premium-Käufe sind auf diesem Gerät nicht verfügbar.'),
        findsNothing,
      );
      await tapLabel(tester, 'Mit Konto freischalten');
      expect(find.byType(AccountSheet), findsOneWidget);
      expect(find.text('Mit E-Mail fortfahren'), findsOneWidget);
    },
  );

  testWidgets(
    'Android without store names a signed-in account without Premium',
    (tester) async {
      const state = PurchaseState(
        phase: PurchasePhase.failed,
        billingReady: false,
        hasVerifiedAccount: true,
        premiumActive: false,
        errorMessage: 'Premium-Käufe sind auf diesem Gerät nicht verfügbar.',
      );
      await tester.pumpWidget(app(MemoryJsonStore(), purchaseState: state));
      await tester.pumpAndSettle();
      await toPlanPage(tester);
      await tapLabel(tester, 'Weiter');
      expect(
        find.text('Für dieses Konto ist kein Premium freigeschaltet.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('A failed account check is not hidden behind the store message', (
    tester,
  ) async {
    const error =
        'Dein Premium-Zugang konnte gerade nicht geprüft werden. '
        'Bitte später erneut versuchen.';
    const state = PurchaseState(
      phase: PurchasePhase.failed,
      billingReady: false,
      hasVerifiedAccount: true,
      errorMessage: 'Premium-Käufe sind auf diesem Gerät nicht verfügbar.',
      accountSyncError: error,
    );
    await tester.pumpWidget(app(MemoryJsonStore(), purchaseState: state));
    await tester.pumpAndSettle();
    await toPlanPage(tester);
    await tapLabel(tester, 'Weiter');
    expect(find.text(error), findsOneWidget);
  });

  testWidgets('A failed Store catalog shows its error once', (tester) async {
    const error =
        'Der Store konnte die Anfrage nicht abschließen. Bitte erneut versuchen.';
    final state = const PurchaseState(
      phase: PurchasePhase.failed,
      billingReady: true,
      errorMessage: error,
    );
    await tester.pumpWidget(app(MemoryJsonStore(), purchaseState: state));
    await tester.pumpAndSettle();
    await toPlanPage(tester);
    await tapLabel(tester, 'Weiter');
    expect(find.text(error), findsOneWidget);
  });

  testWidgets('Paywall reports pending and cancelled Store outcomes without '
      'granting Premium', (tester) async {
    final state = const PurchaseState(
      phase: PurchasePhase.ready,
      products: _FakePurchaseController._products,
      selectedProductId: 'yearly-test',
      billingReady: true,
      lastOutcome: PurchaseResult.pending,
    );
    await tester.pumpWidget(app(MemoryJsonStore(), purchaseState: state));
    await tester.pumpAndSettle();
    await toPlanPage(tester);
    await tapLabel(tester, 'Weiter');
    expect(
      find.text(
        'Der Store bestätigt den Kauf noch. Premium wird nach der Bestätigung freigeschaltet.',
      ),
      findsOneWidget,
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(PaywallScreen)),
    );
    final controller = container.read(purchaseProvider.notifier);
    controller.state = controller.state.copyWith(
      lastOutcome: PurchaseResult.cancelled,
    );
    await tester.pump();
    expect(
      find.text('Der Kauf wurde abgebrochen. Es wurde nichts berechnet.'),
      findsOneWidget,
    );
    expect(find.byType(AppShell), findsNothing);
  });

  testWidgets('Paywall shows the server-confirmed expiry and management '
      'action for active Premium', (tester) async {
    final state = PurchaseState(
      phase: PurchasePhase.ready,
      products: _FakePurchaseController._products,
      selectedProductId: 'yearly-test',
      billingReady: true,
      hasVerifiedAccount: true,
      premiumActive: true,
      expiresAt: DateTime(2027, 3, 12),
      willRenew: true,
    );
    await tester.pumpWidget(app(MemoryJsonStore(), purchaseState: state));
    await tester.pumpAndSettle();
    await toPlanPage(tester);
    await tapLabel(tester, 'Weiter');
    expect(
      find.text('Premium ist aktiv und verlängert sich am 12. März 2027.'),
      findsOneWidget,
    );
    expect(find.text('Abo verwalten'), findsOneWidget);
    expect(find.text('Premium abonnieren'), findsNothing);
  });

  testWidgets(
    'restore failure stays visible while verified Premium remains active',
    (tester) async {
      const error = 'Store restore failed.';
      final state = PurchaseState(
        phase: PurchasePhase.ready,
        products: _FakePurchaseController._products,
        selectedProductId: 'yearly-test',
        billingReady: true,
        hasVerifiedAccount: true,
        premiumActive: true,
        expiresAt: DateTime(2027, 3, 12),
        willRenew: true,
      );
      await tester.pumpWidget(
        app(MemoryJsonStore(), purchaseState: state, restoreError: error),
      );
      await tester.pumpAndSettle();
      await toPlanPage(tester);
      await tapLabel(tester, 'Weiter');

      await tapLabel(tester, 'Wiederherstellen');

      expect(find.byType(PaywallScreen), findsOneWidget);
      expect(find.text(error), findsOneWidget);
      expect(
        find.text(
          'Käufe wurden geprüft; für dieses Konto wurde kein aktives Abo gefunden.',
        ),
        findsNothing,
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(PaywallScreen)),
      );
      expect(container.read(purchaseProvider).premiumActive, isTrue);
      expect(container.read(purchaseProvider).phase, PurchasePhase.failed);
    },
  );

  testWidgets('Paywall unlocks only the explicitly labeled sandbox test UI', (
    tester,
  ) async {
    final state = PurchaseState(
      phase: PurchasePhase.ready,
      products: _FakePurchaseController._products,
      selectedProductId: 'yearly-test',
      billingReady: true,
      hasVerifiedAccount: true,
      premiumActive: false,
      sandboxTestActive: true,
      environment: 'Sandbox',
      purchaseEnvironment: 'Sandbox',
      expiresAt: DateTime(2027, 3, 12),
    );
    await tester.pumpWidget(app(MemoryJsonStore(), purchaseState: state));
    await tester.pumpAndSettle();
    await toPlanPage(tester);
    await tapLabel(tester, 'Weiter');

    expect(find.text('Abo verwalten'), findsOneWidget);
    expect(find.text('Premium abonnieren'), findsNothing);
    expect(
      find.text('Premium-Testabo aktiv (Sandbox) bis 12. März 2027.'),
      findsOneWidget,
    );
    expect(find.byType(AppShell), findsNothing);
  });

  testWidgets('An already active sandbox abo can still close the paywall', (
    tester,
  ) async {
    final store = MemoryJsonStore();
    final state = PurchaseState(
      phase: PurchasePhase.ready,
      products: _FakePurchaseController._products,
      selectedProductId: 'yearly-test',
      billingReady: true,
      hasVerifiedAccount: true,
      sandboxTestActive: true,
      environment: 'Sandbox',
      purchaseEnvironment: 'Sandbox',
      expiresAt: DateTime(2027, 3, 12),
    );
    await tester.pumpWidget(app(store, purchaseState: state));
    await tester.pumpAndSettle();
    await toPlanPage(tester);
    await tapLabel(tester, 'Weiter');
    expect(find.byType(PaywallScreen), findsOneWidget);
    await tapLabel(tester, 'Schließen');
    expect(find.byType(PaywallScreen), findsNothing);
    expect(find.byType(AppShell), findsOneWidget);
  });

  testWidgets('Premium found while the paywall is open closes it once', (
    tester,
  ) async {
    final store = MemoryJsonStore();
    await tester.pumpWidget(app(store));
    await tester.pumpAndSettle();
    await toPlanPage(tester);
    await tapLabel(tester, 'Weiter');
    final container = ProviderScope.containerOf(
      tester.element(find.byType(PaywallScreen)),
    );
    final controller = container.read(purchaseProvider.notifier);
    controller.state = controller.state.copyWith(
      hasVerifiedAccount: true,
      sandboxTestActive: true,
      environment: 'Sandbox',
      purchaseEnvironment: 'Sandbox',
      expiresAt: DateTime(2027, 3, 12),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PaywallScreen), findsNothing);
    expect(find.byType(AppShell), findsOneWidget);
  });

  testWidgets('Premium found during the paywall entrance still closes it', (
    tester,
  ) async {
    await tester.pumpWidget(app(MemoryJsonStore()));
    await tester.pumpAndSettle();
    await toPlanPage(tester);
    final next = find.bySemanticsLabel('Weiter');
    await tester.ensureVisible(next);
    await tester.pumpAndSettle();
    await tester.tap(next);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(PaywallScreen)),
    );
    final controller = container.read(purchaseProvider.notifier);
    controller.state = controller.state.copyWith(
      hasVerifiedAccount: true,
      sandboxTestActive: true,
      environment: 'Sandbox',
      purchaseEnvironment: 'Sandbox',
      expiresAt: DateTime(2027, 3, 12),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PaywallScreen), findsNothing);
    expect(find.byType(AppShell), findsOneWidget);
  });

  testWidgets('Premium found under an open sheet closes the paywall too', (
    tester,
  ) async {
    await tester.pumpWidget(app(MemoryJsonStore()));
    await tester.pumpAndSettle();
    await toPlanPage(tester);
    await tapLabel(tester, 'Weiter');
    final paywall = tester.element(find.byType(PaywallScreen));
    unawaited(
      showCupertinoModalPopup<void>(
        context: paywall,
        builder: (_) => const SizedBox(height: 200, child: Text('Sheet')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sheet'), findsOneWidget);
    final controller = ProviderScope.containerOf(paywall)
        .read(purchaseProvider.notifier);
    controller.state = controller.state.copyWith(
      hasVerifiedAccount: true,
      sandboxTestActive: true,
      environment: 'Sandbox',
      purchaseEnvironment: 'Sandbox',
      expiresAt: DateTime(2027, 3, 12),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sheet'), findsNothing);
    expect(find.byType(PaywallScreen), findsNothing);
    expect(find.byType(AppShell), findsOneWidget);
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

  testWidgets('"Ich habe schon ein Konto" confirms sign in and opens '
      'the app', (tester) async {
    final store = MemoryJsonStore();
    await tester.pumpWidget(app(store));
    await tester.pumpAndSettle();
    await tapLabel(tester, 'Ich habe schon ein Konto');
    expect(find.text('Willkommen zurück'), findsOneWidget);
    await tapLabel(tester, 'Mit Google fortfahren');
    expect(find.byType(AppShell), findsOneWidget);
    expect(find.textContaining('Du bist angemeldet.'), findsOne);
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
    expect(
      tester.getSemantics(find.bySemanticsLabel('Premium abonnieren')),
      isSemantics(isButton: true, isEnabled: false),
    );
    expect(tester.takeException(), isNull);
  });
}
