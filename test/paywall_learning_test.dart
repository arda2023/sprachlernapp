import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/data/billing/purchase_gateway.dart';
import 'package:sprachapp/presentation/providers/purchase_provider.dart';
import 'package:sprachapp/screens/onboarding/paywall_screen.dart';
import 'package:sprachapp/widgets/premium_content_gate.dart';

import 'accessibility/accessibility_test_app.dart';
import 'fixtures/accessibility_fonts.dart';
import 'fixtures/deck_repositories.dart';

class _Purchases extends PurchaseController {
  @override
  PurchaseState build() => const PurchaseState(
    phase: PurchasePhase.ready,
    billingReady: true,
    hasVerifiedAccount: true,
    purchaseAllowed: true,
    premiumActive: false,
    selectedProductId: 'year',
    products: [
      PurchaseProduct(
        productId: 'year',
        plan: PurchasePlan.yearly,
        localizedPrice: '49,99 €',
        localizedPeriod: 'pro Jahr',
        priceAmount: 49.99,
        isRecommended: true,
      ),
      PurchaseProduct(
        productId: 'month',
        plan: PurchasePlan.monthly,
        localizedPrice: '9,99 €',
        localizedPeriod: 'pro Monat',
        priceAmount: 9.99,
        isRecommended: false,
      ),
    ],
  );
  @override
  Future<void> load() async {}
  void sdkHint() => state = state.copyWith(clientPremiumActive: true);
  void confirmed() => state = state.copyWith(premiumActive: true);
}

Future<void> _snapshot(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('REVIEW_SCREENSHOTS')) return;
  // Capture the app's root layer, matching Flutter's golden matcher.
  RenderObject boundary = tester
      .element(find.byType(MaterialApp))
      .renderObject!;
  while (!boundary.isRepaintBoundary) {
    boundary = boundary.parent!;
  }
  await tester.runAsync(() async {
    final image = await (boundary.debugLayer! as OffsetLayer).toImage(
      boundary.paintBounds,
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final directory = await Directory('/tmp/linglossa-review')
        .create(recursive: true);
    await File('${directory.path}/$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(loadAccessibilityFonts);

  for (final brightness in Brightness.values) {
    for (final width in [320.0, 390.0]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          'paywall interactions ${brightness.name} $width, text $scale',
          (tester) async {
            usePhoneViewport(tester, size: Size(width, 844));
            final user = TestUser();
            await tester.pumpWidget(
              testScope(
                accessibilityTestApp(
                  brightness: brightness,
                  textScale: scale,
                  home: RepaintBoundary(
                    key: const Key('review-boundary'),
                    child: PaywallScreen(
                      plan: (interest: 'Reisen', dailyGoal: 10),
                      onboarding: true,
                      onContinue: () {},
                    ),
                  ),
                ),
                user: user,
                overrides: [purchaseProvider.overrideWith(_Purchases.new)],
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            final prefix = 'paywall-${brightness.name}-${width.toInt()}-$scale';
            await _snapshot(tester, '$prefix-top');
            final scroll = find.descendant(
              of: find.byKey(const Key('premium-details-scroll')),
              matching: find.byType(Scrollable),
            );
            final slider = find.byKey(const Key('context-words-slider'));
            await tester.scrollUntilVisible(slider, 300, scrollable: scroll);
            await tester.ensureVisible(slider);
            await tester.pumpAndSettle();
            final previous = tester.widget<CupertinoSlider>(slider).value;
            await tester.drag(slider, const Offset(140, 0));
            await tester.pumpAndSettle();
            expect(
              tester.widget<CupertinoSlider>(slider).value,
              greaterThan(previous),
            );
            expect(tester.takeException(), isNull);
            await tester.ensureVisible(find.text('Im Satz verstehen.'));
            await tester.pumpAndSettle();
            await _snapshot(tester, '$prefix-words');
            final reveal = find.byKey(const Key('retrieval-reveal'));
            await tester.scrollUntilVisible(reveal, 200, scrollable: scroll);
            await tester.ensureVisible(reveal);
            await tester.pumpAndSettle();
            await tester.tap(reveal);
            await tester.pumpAndSettle();
            expect(find.text('I open the door.'), findsOneWidget);
            final repeat = find.byKey(const Key('spaced-visit-2'));
            await tester.scrollUntilVisible(repeat, 200, scrollable: scroll);
            await tester.ensureVisible(repeat);
            await tester.pumpAndSettle();
            await tester.tap(repeat);
            await tester.pumpAndSettle();
            expect(find.text('Erneut festigen'), findsOneWidget);
            expect(tester.takeException(), isNull);
            await _snapshot(tester, '$prefix-repeat');
            await tester.pumpWidget(const SizedBox.shrink());
            await user.close();
          },
        );
      }
    }
  }

  testWidgets(
    'gate resumes only after verified unlock, never SDK hint or cancel',
    (tester) async {
      usePhoneViewport(tester);
      final purchases = _Purchases();
      final results = <bool>[];
      await tester.pumpWidget(
        testScope(
          accessibilityTestApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () async => results.add(
                    await showPremiumContentPaywall(
                      context,
                      interest: 'Stories',
                    ),
                  ),
                  child: const Text('Story öffnen'),
                ),
              ),
            ),
          ),
          overrides: [purchaseProvider.overrideWith(() => purchases)],
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Story öffnen'));
      await tester.pumpAndSettle();
      purchases.sdkHint();
      await tester.pumpAndSettle();
      expect(find.byType(PaywallScreen), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Schließen'));
      await tester.pumpAndSettle();
      expect(results, [false]);
      await tester.tap(find.text('Story öffnen'));
      await tester.pumpAndSettle();
      purchases.confirmed();
      await tester.pumpAndSettle();
      expect(find.byType(PaywallScreen), findsNothing);
      expect(results, [false, true]);
      expect(tester.takeException(), isNull);
    },
  );
}
