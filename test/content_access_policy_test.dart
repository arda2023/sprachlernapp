import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/domain/content_access_policy.dart';
import 'package:sprachapp/presentation/providers/content_access_provider.dart';
import 'package:sprachapp/presentation/providers/purchase_provider.dart';
import 'package:sprachapp/screens/stories/widgets/import_panel.dart';
import 'package:sprachapp/theme/app_theme.dart';

class _FakePurchaseController extends PurchaseController {
  _FakePurchaseController(this.initialState);

  final PurchaseState initialState;
  int loadCount = 0;

  void grantPremium() {
    state = state.copyWith(premiumActive: true);
  }

  @override
  PurchaseState build() => initialState;

  @override
  Future<void> load() async {
    loadCount++;
    state = state.copyWith(
      hasVerifiedAccount: true,
      premiumActive: false,
      clearError: true,
    );
  }
}

void main() {
  group('ContentAccessPolicy', () {
    test('allows verified production or sandbox UI access', () {
      expect(
        ContentAccessPolicy.decide(
          hasPremiumAccess: true,
          hasVerifiedAccount: true,
          entitlementKnown: true,
        ),
        ContentAccessDecision.allowed,
      );
      expect(
        ContentAccessPolicy.decide(
          hasPremiumAccess: true,
          hasVerifiedAccount: false,
          entitlementKnown: false,
        ),
        ContentAccessDecision.allowed,
      );
    });

    test('signed-out and verified inactive accounts require Premium', () {
      expect(
        ContentAccessPolicy.decide(
          hasPremiumAccess: false,
          hasVerifiedAccount: false,
          entitlementKnown: false,
        ),
        ContentAccessDecision.premiumRequired,
      );
      expect(
        ContentAccessPolicy.decide(
          hasPremiumAccess: false,
          hasVerifiedAccount: true,
          entitlementKnown: true,
        ),
        ContentAccessDecision.premiumRequired,
      );
    });

    test('only a verified account with unknown entitlement stays unknown', () {
      expect(
        ContentAccessPolicy.decide(
          hasPremiumAccess: false,
          hasVerifiedAccount: true,
          entitlementKnown: false,
        ),
        ContentAccessDecision.statusUnknown,
      );
    });
  });

  test(
    'content access provider follows purchase state and retry sync',
    () async {
      final controller = _FakePurchaseController(
        const PurchaseState(hasVerifiedAccount: true),
      );
      final container = ProviderContainer(
        overrides: [purchaseProvider.overrideWith(() => controller)],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(contentAccessProvider, (_, _) {});

      expect(subscription.read(), ContentAccessDecision.statusUnknown);
      await container.read(purchaseProvider.notifier).load();
      expect(controller.loadCount, 1);
      expect(subscription.read(), ContentAccessDecision.premiumRequired);
    },
  );

  testWidgets(
    'without Premium every source is locked; after Premium paste imports',
    (tester) async {
      final controller = _FakePurchaseController(
        const PurchaseState(hasVerifiedAccount: true, premiumActive: false),
      );
      String? imported;
      final pushed = <Route<dynamic>>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async => call.method == 'Clipboard.getData'
            ? {'text': 'A saved draft with five words.'}
            : null,
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [purchaseProvider.overrideWith(() => controller)],
          child: MaterialApp(
            theme: buildAppTheme(),
            navigatorObservers: [_PushObserver(pushed)],
            home: Scaffold(
              body: ImportPanel(
                onImportText: (text) {
                  imported = text;
                  return null;
                },
              ),
            ),
          ),
        ),
      );
      for (final title in ['Text einfügen', 'Datei', 'YouTube', 'Webseite']) {
        expect(
          find.bySemanticsLabel(RegExp('^$title, .*mit Premium\$')),
          findsOneWidget,
          reason: title,
        );
      }
      expect(find.text('Eigene Texte importieren'), findsNothing);
      expect(find.text('Status erneut prüfen'), findsNothing);

      final before = pushed.length;
      await tester.tap(find.bySemanticsLabel(RegExp('^YouTube')));
      await tester.pump();
      expect(imported, isNull);
      expect(pushed.length, before + 1);
      // Let the paywall's start-up timer fire.
      await tester.pump(const Duration(milliseconds: 1));
    },
  );

  testWidgets('with Premium paste imports and unavailable sources say Bald', (
    tester,
  ) async {
    final controller = _FakePurchaseController(
      const PurchaseState(hasVerifiedAccount: true, premiumActive: true),
    );
    String? imported;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => call.method == 'Clipboard.getData'
          ? {'text': 'A saved draft with five words.'}
          : null,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [purchaseProvider.overrideWith(() => controller)],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => Scaffold(
                      body: ImportPanel(
                        onImportText: (text) {
                          imported = text;
                          return null;
                        },
                      ),
                    ),
                  ),
                ),
                child: const Text('Open import'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open import'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Datei, bald verfügbar'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel(RegExp('^Text einfügen')));
    await tester.pumpAndSettle();
    expect(imported, 'A saved draft with five words.');
  });
}

class _PushObserver extends NavigatorObserver {
  _PushObserver(this.pushed);

  final List<Route<dynamic>> pushed;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      pushed.add(route);
}
