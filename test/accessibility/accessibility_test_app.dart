import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/data/billing/purchase_gateway.dart';
import 'package:sprachapp/data/notifications/notification_gateway.dart';
import 'package:sprachapp/domain/notification_schedule.dart';
import 'package:sprachapp/domain/trial_reminder.dart';
import 'package:sprachapp/presentation/providers/notification_provider.dart';
import 'package:sprachapp/presentation/providers/purchase_provider.dart';
import 'package:sprachapp/screens/decks/widgets/practice_sentence.dart';
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
  await expectLater(
    tester,
    meetsGuideline(
      _InlineAwareTapTargetGuideline(
        _inlineSentences(tester),
        _clippedFullSizeTargets(tester),
      ),
    ),
  );
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(
    tester,
    meetsGuideline(
      _OrangeAwareTextContrastGuideline(
        _orangeTextOnLight(tester),
        _clippedShortTextLabels(tester),
      ),
    ),
  );
  expect(tester.takeException(), isNull);
}

/// Orange text on a light background (word translations, accents): a
/// deliberate design decision (user, 15.11.2026: one orange, no darker text
/// variant), 2.6:1 instead of 4.5:1. Only exactly these labels are exempt;
/// every other text, and all orange text in dark mode, is still checked.
Set<String> _orangeTextOnLight(WidgetTester tester) {
  final texts = find.byType(Text).evaluate().toList();
  if (texts.isEmpty || Theme.of(texts.first).brightness != Brightness.light) {
    return const {};
  }
  return {
    for (final element in texts)
      if (element.widget case Text(:final data?, :final style?)
          when style.color == AppColors.active)
        data.trim(),
  };
}

class _OrangeAwareTextContrastGuideline extends MinimumTextContrastGuideline {
  const _OrangeAwareTextContrastGuideline(
    this.orangeLabels,
    this.clippedLabels,
  );

  final Set<String> orangeLabels;
  final Set<String> clippedLabels;

  @override
  bool shouldSkipNode(SemanticsData data) =>
      super.shouldSkipNode(data) ||
      orangeLabels.contains(data.label.trim()) ||
      clippedLabels.contains(data.label.trim());
}

/// The contrast sampler inflates text bounds by 4 px. At a scroll edge this
/// samples the pinned footer or a cut glyph instead of its real text color.
/// Short labels are checked when fully visible: the screen walker overlaps
/// successive viewports by 30%, so a label shorter than that fits in one pass.
/// Long paragraphs are not exempted by this rule.
Set<String> _clippedShortTextLabels(WidgetTester tester) {
  final labels = <String>{};
  for (final element in find.byType(Text).evaluate()) {
    final text = (element.widget as Text).data;
    final box = element.renderObject;
    if (text == null || box is! RenderBox || !box.hasSize) continue;
    final Object? viewport = RenderAbstractViewport.maybeOf(box);
    if (viewport is! RenderBox ||
        !viewport.hasSize ||
        box.size.height >= viewport.size.height * 0.3) {
      continue;
    }
    final full = box.localToGlobal(Offset.zero) & box.size;
    final visible = viewport.localToGlobal(Offset.zero) & viewport.size;
    if (full.overlaps(visible) &&
        full.intersect(visible).height < full.height - 0.5) {
      labels.add(text.trim());
    }
  }
  return labels;
}

/// Exercise sentences, in physical pixels like the semantics tree.
List<Rect> _inlineSentences(WidgetTester tester) {
  final ratio = tester.view.devicePixelRatio;
  return [
    for (final element in find.byType(PracticeSentence).evaluate())
      if (element.renderObject case final RenderBox box when box.hasSize)
        (box.localToGlobal(Offset.zero) & box.size).inflate(1) * ratio,
  ];
}

extension on Rect {
  Rect operator *(double f) =>
      Rect.fromLTRB(left * f, top * f, right * f, bottom * f);
}

/// iOS 44 pt targets, except words and the gap field inside a running
/// exercise sentence: WCAG 2.5.8 exempts inline targets, and a 44 pt
/// minimum there spreads short words ("a", "to") visibly apart.
/// Scroll clipping shortens a semantics node, not the actual touch target.
/// Exempt only labels whose real render box is at least 44×44 and is currently
/// cut by its scroll viewport. Small controls receive no such exemption.
Set<String> _clippedFullSizeTargets(WidgetTester tester) {
  final labels = <String>{};
  for (final element in find.byType(Semantics).evaluate()) {
    final semantics = element.widget as Semantics;
    final label = semantics.properties.label;
    if (label == null || semantics.properties.onTap == null) continue;
    final box = element.renderObject;
    if (box is! RenderBox ||
        !box.hasSize ||
        box.size.width < 44 ||
        box.size.height < 44) {
      continue;
    }
    final Object? viewport = RenderAbstractViewport.maybeOf(box);
    if (viewport is! RenderBox || !viewport.hasSize) continue;
    final full = box.localToGlobal(Offset.zero) & box.size;
    final visible = viewport.localToGlobal(Offset.zero) & viewport.size;
    if (full.overlaps(visible) &&
        full.intersect(visible).height < full.height - 0.5) {
      labels.add(label);
    }
  }
  return labels;
}

class _InlineAwareTapTargetGuideline extends MinimumTapTargetGuideline {
  _InlineAwareTapTargetGuideline(this.sentences, this.clippedFullSizeLabels)
    : super(
        size: const Size(44, 44),
        link: 'https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum',
      );

  final List<Rect> sentences;
  final Set<String> clippedFullSizeLabels;

  @override
  bool shouldSkipNode(SemanticsNode node) {
    if (super.shouldSkipNode(node)) return true;
    if (clippedFullSizeLabels.contains(node.getSemanticsData().label)) {
      return true;
    }
    var rect = node.rect;
    for (SemanticsNode? n = node; n != null; n = n.parent) {
      if (n.transform case final transform?) {
        rect = MatrixUtils.transformRect(transform, rect);
      }
    }
    return sentences.any((s) => s.contains(rect.center));
  }
}

/// Purchase presentation only. No platform billing call, account or network.
class AccessibilityPurchaseController extends PurchaseController {
  AccessibilityPurchaseController({this.trialDays = 0});
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
        trialDays: trialDays > 0 ? trialDays : null,
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

List<Override> accessibilityOverrides({int trialDays = 0}) => [
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
