import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/data/billing/purchase_gateway.dart';
import 'package:sprachapp/presentation/providers/purchase_provider.dart';
import 'package:sprachapp/screens/onboarding/paywall_screen.dart';
import 'package:sprachapp/screens/onboarding/widgets/learning_principles.dart';
import 'package:sprachapp/screens/onboarding/widgets/paywall_demos.dart';
import 'package:sprachapp/theme/app_theme.dart';
import 'package:sprachapp/widgets/anchored_popover.dart' show PopoverBubble;
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

  Widget paywall({
    Brightness brightness = Brightness.dark,
    double scale = 1,
    bool reduceMotion = true,
  }) => accessibilityTestApp(
    brightness: brightness,
    textScale: scale,
    reduceMotion: reduceMotion,
    home: RepaintBoundary(
      key: const Key('review-boundary'),
      child: PaywallScreen(
        plan: (interest: 'Reisen', dailyGoal: 10),
        onboarding: true,
        onContinue: () {},
      ),
    ),
  );

  Finder scrollable() => find.descendant(
    of: find.byKey(const Key('premium-details-scroll')),
    matching: find.byType(Scrollable),
  );

  /// How visible a demo currently draws [text].
  double shown(WidgetTester tester, Finder text) => tester
      .widgetList<Opacity>(
        find.ancestor(of: text, matching: find.byType(Opacity)),
      )
      .fold(1.0, (value, opacity) => value * opacity.opacity);

  for (final brightness in Brightness.values) {
    for (final width in [320.0, 390.0]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          'paywall layout and benefits ${brightness.name} $width, text $scale',
          (tester) async {
            usePhoneViewport(tester, size: Size(width, 844));
            final user = TestUser();
            await tester.pumpWidget(
              testScope(
                paywall(brightness: brightness, scale: scale),
                user: user,
                overrides: [purchaseProvider.overrideWith(_Purchases.new)],
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            final prefix = 'paywall-${brightness.name}-${width.toInt()}-$scale';
            await _snapshot(tester, '$prefix-top');

            final title = find.text('Erreiche mehr\nmit Premium');
            expect(title, findsOneWidget);
            expect(tester.widget<Text>(title).textAlign, TextAlign.center);
            for (final removed in [
              'LINGLOSSA PREMIUM',
              'Dein Tempo.\nDein Umfang.',
              'Free bleibt kostenlos. Ohne Testabo.',
              'Neue KI-Übersetzungen',
              'Kostenlos weiterlernen',
              // The period after the price names the plan.
              'Jährlich',
              'Monatlich',
              '01',
            ]) {
              expect(find.text(removed), findsNothing);
            }
            expect(find.textContaining('Lies, höre und übe'), findsNothing);
            expect(find.textContaining('Bis zu 50 Wörter pro'), findsNothing);
            expect(find.byType(CupertinoSlider), findsNothing);
            expect(find.byIcon(CupertinoIcons.xmark), findsNothing);

            // "Später" leads out at the top right, restore sits across from
            // it; nothing of the kind next to the purchase button.
            final later = tester.getRect(find.text('Später'));
            final restore = tester.getRect(find.text('Wiederherstellen'));
            for (final action in [later, restore]) {
              expect(action.top, lessThan(tester.getRect(title).top));
            }
            expect(later.center.dx, greaterThan(width / 2));
            expect(restore.center.dx, lessThan(width / 2));

            // Both plans sit right above the purchase button, with nothing
            // of the comparison in between.
            final buy = tester.getRect(find.text('Premium abonnieren'));
            final yearly = find.text('pro Jahr');
            final plans = tester
                .getRect(find.text('49,99 €'))
                .expandToInclude(tester.getRect(find.text('pro Monat')));
            expect(plans.bottom, lessThan(buy.top));
            expect(find.text('4,17 € / Monat'), findsOneWidget);
            Finder scrolled(Finder finder) => find.descendant(
              of: find.byKey(const Key('premium-details-scroll')),
              matching: finder,
            );
            if (scrolled(yearly).evaluate().isEmpty) {
              // Pinned below the details, together with the button.
              expect(scrolled(find.text('Premium abonnieren')), findsNothing);
            } else {
              expect(
                tester.getRect(find.byType(PremiumComparison)).top,
                greaterThan(buy.bottom),
              );
            }

            expect([for (final row in PremiumComparison.rows) row.$1], [
              'Stapel',
              'Stories',
              'AI-Tutor',
              'Vokabelgenerierung',
              'Eigene Texte',
              'Text-, Hör- & Grammatikübungen',
            ]);
            Finder inTable(String text) => find.descendant(
              of: find.byType(PremiumComparison),
              matching: find.text(text),
            );
            final tops = [
              for (final row in PremiumComparison.rows)
                tester.getTopLeft(inTable(row.$1)).dy,
            ];
            for (var i = 1; i < tops.length; i++) {
              expect(tops[i], greaterThan(tops[i - 1]));
            }
            expect(
              tops.first,
              greaterThan(tester.getBottomLeft(title).dy),
            );
            expect(find.textContaining('3 Sätze'), findsOneWidget);
            expect(find.text('1× im Monat'), findsOneWidget);
            expect(find.text('Unlimited'), findsNWidgets(2));
            if (scale == 1) {
              // Never broken inside the word.
              final label = tester.widget<Text>(inTable('Vokabelgenerierung'));
              expect(
                tester.getSize(inTable('Vokabelgenerierung')).height,
                lessThan(label.style!.fontSize! * 1.35 * 1.5),
              );
            }

            // Reduced motion: every benefit rests on its result.
            final colors = AppPalette(brightness);
            for (final (heading, demo, result) in [
              ('Selbst abrufen.', RecallDemo, 'drinks'),
              ('Im Satz verstehen.', GlossDemo, 'Buchhandlung'),
              (
                'Frei schreiben.',
                TutorDemo,
                'Richtig! Noch natürlicher: „I ran into my old teacher yesterday.“',
              ),
              ('Wörter zu deinem Thema.', TopicDemo, 'squirrel'),
            ]) {
              final target = find.text(result);
              await tester.scrollUntilVisible(
                find.text(heading),
                200,
                scrollable: scrollable(),
              );
              await tester.ensureVisible(find.byType(demo));
              await tester.pumpAndSettle();
              expect(target, findsOneWidget);
              expect(shown(tester, target), 1);
              expect(tester.takeException(), isNull);
              await _snapshot(tester, '$prefix-$demo');
            }
            expect(
              tester.widget<Text>(find.text('drinks')).style!.color!
                  .toARGB32(),
              colors.success.toARGB32(),
            );
            // The demo bubble lies flat on its card.
            expect(
              tester
                  .widget<PopoverBubble>(
                    find.descendant(
                      of: find.byType(GlossDemo),
                      matching: find.byType(PopoverBubble),
                    ),
                  )
                  .shadow,
              isFalse,
            );
            await tester.pumpWidget(const SizedBox.shrink());
            await user.close();
          },
        );
      }
    }
  }

  testWidgets('benefits play on screen, pause off screen, then rest', (
    tester,
  ) async {
    usePhoneViewport(tester);
    final user = TestUser();
    await tester.pumpWidget(
      testScope(
        paywall(reduceMotion: false),
        user: user,
        overrides: [purchaseProvider.overrideWith(_Purchases.new)],
      ),
    );
    await tester.pump();
    // Below the fold nothing animates.
    expect(await tester.pumpAndSettle(), lessThan(20));
    final colors = AppPalette(Brightness.dark);

    // From the top, so every demo starts over (a neighbour may already have
    // played while the previous one was shown).
    Future<void> show(Type demo) async {
      tester.state<ScrollableState>(scrollable()).position.jumpTo(0);
      await tester.pump();
      await tester.scrollUntilVisible(
        find.byType(demo),
        200,
        scrollable: scrollable(),
      );
      await tester.ensureVisible(find.byType(demo));
      await tester.pump();
    }

    // 1: the gap is typed letter by letter, then turns green.
    await show(RecallDemo);
    await tester.pump(const Duration(milliseconds: 1000));
    expect(find.text('dri'), findsOneWidget);
    await _snapshot(tester, 'paywall-motion-recall-typing');
    await tester.pump(const Duration(milliseconds: 1200));
    expect(
      tester.widget<Text>(find.text('drinks')).style!.color!.toARGB32(),
      colors.success.toARGB32(),
    );

    // Scrolled away, it stops; back on screen it plays its passes and rests.
    tester.state<ScrollableState>(scrollable()).position.jumpTo(0);
    await tester.pump();
    expect(await tester.pumpAndSettle(), lessThan(20));
    await show(RecallDemo);
    expect(find.text('drinks'), findsNothing);
    expect(await tester.pumpAndSettle(), greaterThan(50));
    expect(
      tester.widget<Text>(find.text('drinks')).style!.color!.toARGB32(),
      colors.success.toARGB32(),
    );

    // 2: a tapped word gets its orange bubble.
    await show(GlossDemo);
    expect(find.text('Buchhandlung'), findsNothing);
    await tester.pump(const Duration(milliseconds: 1000));
    expect(find.text('Buchhandlung'), findsOneWidget);

    // 3: the tutor answers only after the sentence was typed.
    const feedback =
        'Richtig! Noch natürlicher: „I ran into my old teacher yesterday.“';
    await show(TutorDemo);
    await tester.pump(const Duration(milliseconds: 2000));
    expect(shown(tester, find.text(feedback)), 0);
    await _snapshot(tester, 'paywall-motion-tutor-typing');
    await tester.pump(const Duration(milliseconds: 2200));
    await _snapshot(tester, 'paywall-motion-tutor-thinking');
    await tester.pump(const Duration(milliseconds: 1300));
    expect(shown(tester, find.text(feedback)), 1);

    // 4: generating glints over the topic, then the words appear.
    await show(TopicDemo);
    await tester.pump(const Duration(milliseconds: 3500));
    expect(
      find.descendant(
        of: find.byType(TopicDemo),
        matching: find.byType(ShaderMask),
      ),
      findsOneWidget,
    );
    await _snapshot(tester, 'paywall-motion-topic-busy');
    expect(shown(tester, find.text('fox')), 0);
    await tester.pump(const Duration(milliseconds: 3500));
    for (final word in ['fox', 'owl', 'hedgehog', 'squirrel']) {
      expect(shown(tester, find.text(word)), 1);
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await user.close();
  });

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
      await tester.tap(find.bySemanticsLabel('Später'));
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
