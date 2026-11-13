import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/data/billing/purchase_gateway.dart';
import 'package:sprachapp/data/notifications/notification_gateway.dart';
import 'package:sprachapp/domain/notification_schedule.dart';
import 'package:sprachapp/domain/trial_reminder.dart';
import 'package:sprachapp/presentation/providers/notification_provider.dart';
import 'package:sprachapp/presentation/providers/purchase_provider.dart';
import 'package:sprachapp/theme/app_theme.dart';

/// The same typography, colors and German system labels as the app, with a
/// controlled viewport and accessibility settings. No global app state changes.
Widget accessibilityTestApp({
  required Widget home,
  Brightness brightness = Brightness.light,
  double textScale = 1,
  bool reduceMotion = true,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: buildAppTheme(brightness: brightness),
  locale: const Locale('de'),
  supportedLocales: const [Locale('de')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(textScale),
      disableAnimations: reduceMotion,
    ),
    child: child!,
  ),
  home: home,
);

void usePhoneViewport(WidgetTester tester, {Size size = const Size(390, 844)}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> expectAccessible(WidgetTester tester) async {
  expect(
    tester.takeException(),
    isNull,
    reason: 'No layout or rendering error',
  );
  await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));
  expect(tester.takeException(), isNull);
}

/// Purchase presentation only. No platform billing call, account or network.
class AccessibilityPurchaseController extends PurchaseController {
  AccessibilityPurchaseController({this.trialDays = 7});
  final int trialDays;

  @override
  PurchaseState build() => PurchaseState(
    phase: PurchasePhase.ready,
    billingReady: true,
    hasVerifiedAccount: true,
    purchaseAllowed: true,
    selectedProductId: 'accessibility-yearly',
    products: [
      PurchaseProduct(
        productId: 'accessibility-yearly',
        plan: PurchasePlan.yearly,
        localizedPrice: '49,99 €',
        localizedPeriod: 'pro Jahr',
        isRecommended: true,
        priceAmount: 49.99,
        trialDays: trialDays,
      ),
      const PurchaseProduct(
        productId: 'accessibility-monthly',
        plan: PurchasePlan.monthly,
        localizedPrice: '9,99 €',
        localizedPeriod: 'pro Monat',
        isRecommended: false,
        priceAmount: 9.99,
      ),
    ],
  );

  @override
  Future<void> load() async {}
}

/// Deterministic reminder presentation with no native permission or scheduling.
/// The enabled time row and an already scheduled trial reminder are visible.
class AccessibilityNotificationController extends NotificationController {
  @override
  NotificationState build() => NotificationState(
    supported: true,
    ready: true,
    permission: NotificationPermission.allowed,
    settings: const LearningReminderSettings(enabled: true),
    trialStatus: TrialReminderStatus.ready,
    scheduledTrial: TrialReminderPlan(
      productId: 'accessibility-yearly',
      expiresAt: DateTime.utc(2035, 1, 2),
      remindAt: DateTime.utc(2035, 1, 1),
      isSandbox: false,
    ),
  );

  @override
  Future<void> refresh() async {}
}

List<Override> accessibilityOverrides({int trialDays = 7}) => [
  purchaseProvider.overrideWith(
    () => AccessibilityPurchaseController(trialDays: trialDays),
  ),
  notificationProvider.overrideWith(AccessibilityNotificationController.new),
];

/// Contrast after painting foreground alpha over a solid background.
double contrastRatio(Color foreground, Color background) {
  final painted = Color.alphaBlend(foreground, background);
  final a = painted.computeLuminance();
  final b = background.computeLuminance();
  return a > b ? (a + 0.05) / (b + 0.05) : (b + 0.05) / (a + 0.05);
}
