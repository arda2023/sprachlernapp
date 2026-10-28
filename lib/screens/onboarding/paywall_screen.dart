import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show Scaffold, ScaffoldMessenger, SnackBar;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/onboarding_sounds.dart';

import '../../theme/app_theme.dart';
import 'widgets/account_sheet.dart';
import 'widgets/onboarding_motion.dart';
import 'widgets/onboarding_art.dart';

/// The two plans of the freemium plan (docs/redesign/design-system.md ›
/// Paywall): same features, yearly preselected.
enum PremiumPlan {
  yearly(
    title: 'Jährlich',
    price: '49,99 €',
    period: '/ Jahr',
    detail: 'entspricht 4,17 € / Monat',
    terms: '49,99 € jährlich. Automatische Verlängerung, im Store kündbar.',
  ),
  monthly(
    title: 'Monatlich',
    price: '9,99 €',
    period: '/ Monat',
    detail: 'monatlich kündbar',
    terms: '9,99 € monatlich. Automatische Verlängerung, im Store kündbar.',
  );

  const PremiumPlan({
    required this.title,
    required this.price,
    required this.period,
    required this.detail,
    required this.terms,
  });

  final String title, price, period, detail, terms;
}

/// What the onboarding learned, shown at the top of the paywall (the plan
/// pill flies here from the last onboarding step).
typedef PaywallContext = ({String interest, int dailyGoal});

/// Shared with the plan card on the last onboarding step.
const paywallHeroTag = 'onboarding-plan-card';

/// Closable premium offer after the word demo. Purchase and restore are
/// placeholders until billing exists: every way out continues into the
/// free app via [onContinue] (with an honest notice where needed).
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({
    super.key,
    required this.plan,
    required this.onContinue,
  });

  final PaywallContext plan;

  /// Finishes the onboarding; the paywall then pops itself so the app
  /// underneath is revealed.
  final VoidCallback onContinue;

  /// Fades in and rises 6 % over the receding onboarding; pops by sliding
  /// back down.
  static Route<void> route({
    required PaywallContext plan,
    required VoidCallback onContinue,
  }) => PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 520),
    reverseTransitionDuration: const Duration(milliseconds: 360),
    pageBuilder: (_, _, _) => PaywallScreen(plan: plan, onContinue: onContinue),
    transitionsBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: const Interval(0, 0.6, curve: Curves.easeOut),
        ),
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  PremiumPlan _plan = PremiumPlan.yearly;
  bool _leaving = false;

  void _finish({String? notice}) {
    if (_leaving) return;
    _leaving = true;
    if (notice != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(notice)));
    }
    widget.onContinue();
    Navigator.of(context).maybePop();
  }

  Future<void> _subscribe() async {
    final provider = await AccountSheet.show(context, AccountReason.purchase);
    if (provider == null || !mounted) return;
    _finish(
      notice:
          'Käufe sind in dieser Version noch nicht freigeschaltet. '
          'Du lernst kostenlos weiter.',
    );
  }

  void _notice(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  void _restore() =>
      _notice('Käufe wiederherstellen kommt mit dem Premium-Start.');

  void _legal() => _notice('Die Rechtstexte folgen vor dem Premium-Start.');

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    // The page is on screen from the first frame of the route; its parts
    // follow in a short cascade while it rises.
    const active = true;
    // Prices stay next to the button. Only at very large text sizes would
    // the pinned block crowd out the page, so the plans scroll there.
    final pinPlans = MediaQuery.textScalerOf(context).scale(1) <= 1.35;
    final plans = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, plan) in PremiumPlan.values.indexed) ...[
          if (i > 0) const SizedBox(height: 10),
          _PlanCard(
            plan: plan,
            selected: plan == _plan,
            onTap: () {
              if (plan != _plan) {
                ref.read(onboardingSoundsProvider).select();
              }
              setState(() => _plan = plan);
            },
          ),
        ],
      ],
    );
    return Scaffold(
      backgroundColor: colors.nightPage,
      body: Stack(
        children: [
          // A faint warm glow behind the header – the only light source.
          Positioned(
            top: -160,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: 380,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      colors.popover.withValues(alpha: 0.22),
                      colors.popover.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Chrome row: capped like the app's other bars.
                MediaQuery.withClampedTextScaling(
                  maxScaleFactor: 1.3,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(6, 2, 6, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Pressable(
                          label: 'Schließen',
                          haptic: Haptic.light,
                          onTap: _finish,
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: Icon(
                              CupertinoIcons.xmark,
                              size: 22,
                              color: colors.textMuted,
                            ),
                          ),
                        ),
                        Flexible(
                          child: TextAction(
                            label: 'Wiederherstellen',
                            onTap: _restore,
                            size: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  // Content that continues under the pinned block fades out
                  // instead of being cut.
                  child: ShaderMask(
                    blendMode: BlendMode.dstIn,
                    shaderCallback: (rect) => LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: const [
                        Color(0xFFFFFFFF),
                        Color(0xFFFFFFFF),
                        Color(0x00FFFFFF),
                      ],
                      stops: [0, (1 - 20 / rect.height).clamp(0.0, 1.0), 1],
                    ).createShader(rect),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(child: _PlanPill(plan: widget.plan)),
                          const SizedBox(height: 16),
                          Reveal(
                            active: active,
                            order: 3,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const OnboardingArt(
                                  OnboardingArtboard.logo,
                                  height: 30,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'Lingvist Premium',
                                    style: AppType.chrome(
                                      size: 15,
                                      weight: FontWeight.w700,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Reveal(
                            active: active,
                            order: 4,
                            child: Semantics(
                              header: true,
                              child: Text(
                                'Mehr lesen. Deine eigenen Wörter lernen.',
                                textAlign: TextAlign.center,
                                style: AppType.editorial(
                                  color: colors.textPrimary,
                                  size: 30,
                                  height: 1.15,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          for (final (i, benefit) in _benefits(
                            widget.plan.interest,
                          ).indexed)
                            Reveal(
                              active: active,
                              order: 5 + i,
                              child: _BenefitRow(benefit: benefit),
                            ),
                          Reveal(
                            active: active,
                            order: 8,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 50, top: 2),
                              child: Text(
                                'Alle veröffentlichten Grammatik- und '
                                'Textübungen inklusive.',
                                style: AppType.meta(color: colors.textMuted),
                              ),
                            ),
                          ),
                          if (!pinPlans) ...[
                            const SizedBox(height: 28),
                            Reveal(active: active, order: 9, child: plans),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                Reveal(
                  active: active,
                  order: 10,
                  offset: 10,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (pinPlans) ...[
                          const SizedBox(height: 6),
                          plans,
                          const SizedBox(height: 14),
                        ],
                        GlowButton(
                          label: 'Premium abonnieren',
                          onPressed: _subscribe,
                        ),
                        const SizedBox(height: 8),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            _plan.terms,
                            key: ValueKey(_plan),
                            textAlign: TextAlign.center,
                            style: AppType.meta(color: colors.textMuted),
                          ),
                        ),
                        TextAction(
                          label: 'Kostenlos weiterlernen',
                          onTap: _finish,
                          strong: true,
                        ),
                        Wrap(
                          alignment: WrapAlignment.center,
                          children: [
                            TextAction(
                              label: 'Nutzungsbedingungen',
                              onTap: _legal,
                              size: 12,
                            ),
                            TextAction(
                              label: 'Datenschutz',
                              onTap: _legal,
                              size: 12,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

typedef _Benefit = ({IconData icon, String title, String detail});

/// The three arguments in the plan's fixed order; the first line picks up
/// the topic chosen in the onboarding.
List<_Benefit> _benefits(String interest) => [
  (
    icon: CupertinoIcons.book,
    title: 'Lies, was dich interessiert',
    detail: 'Alle Storys ohne Tageslimit – auch zu $interest.',
  ),
  (
    icon: CupertinoIcons.doc_text,
    title: 'Lerne mit deinen eigenen Texten',
    detail: 'Texte importieren und Wörter darin üben.',
  ),
  (
    icon: CupertinoIcons.sparkles,
    title: 'Verstehe fehlende Stellen direkt',
    detail: '500 neue KI-Übersetzungen pro Monat.',
  ),
];

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.benefit});

  final _Benefit benefit;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      container: true,
      label: '${benefit.title}. ${benefit.detail}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colors.activeTint,
                shape: BoxShape.circle,
              ),
              child: Icon(benefit.icon, size: 18, color: colors.active),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    benefit.title,
                    style: AppType.chrome(
                      size: 17,
                      weight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    benefit.detail,
                    style: AppType.chrome(
                      size: 14,
                      color: colors.textMuted,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One plan as a full-width row: check, title and monthly equivalent on
/// the left, price and period on the right, so German copy never wraps.
/// Selected: orange ring (the border carries the state), faint orange tint,
/// filled check that pops in.
class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  final PremiumPlan plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final yearly = plan == PremiumPlan.yearly;
    // Very large text: the price moves under the title instead of beside it.
    final stacked = MediaQuery.textScalerOf(context).scale(1) > 1.35;
    final price = Text(
      plan.price,
      style: AppType.chrome(
        size: 20,
        weight: FontWeight.w800,
        color: colors.textPrimary,
        tabular: true,
      ),
    );
    final period = Text(
      plan.period,
      style: AppType.meta(color: colors.textMuted),
    );
    return Pressable(
      label:
          '${plan.title}, ${plan.price} ${plan.period}, ${plan.detail}'
          '${yearly ? ', 58 Prozent gegenüber monatlicher Zahlung sparen' : ''}',
      selected: selected,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
        decoration: BoxDecoration(
          color: selected ? colors.activeTint : colors.raisedInk,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? colors.active : const Color(0x00000000),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            _PlanCheck(selected: selected),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        plan.title,
                        style: AppType.chrome(
                          size: 16,
                          weight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      if (yearly)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colors.active,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            '58 % sparen',
                            style: AppType.meta(color: const Color(0xFFFFFFFF)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    plan.detail,
                    style: AppType.meta(color: colors.textMuted),
                  ),
                  if (stacked) ...[const SizedBox(height: 6), price, period],
                ],
              ),
            ),
            if (!stacked) ...[
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [price, period],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Radio-style state mark: an empty ring, or a filled orange disc whose
/// check pops in with a slight overshoot.
class _PlanCheck extends StatelessWidget {
  const _PlanCheck({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: selected ? colors.active : const Color(0x00000000),
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? colors.active : colors.textMuted,
          width: 2,
        ),
      ),
      child: AnimatedScale(
        scale: selected ? 1 : 0,
        duration: const Duration(milliseconds: 220),
        curve: selected ? Curves.easeOutBack : Curves.easeIn,
        child: const Icon(
          CupertinoIcons.checkmark_alt,
          size: 14,
          color: Color(0xFFFFFFFF),
        ),
      ),
    );
  }
}

/// The plan pill that heads the plan card on the last onboarding step.
/// Same Hero tag and widget, so it flies here during the transition.
class _PlanPill extends StatelessWidget {
  const _PlanPill({required this.plan});

  final PaywallContext plan;

  @override
  Widget build(BuildContext context) => Hero(
    tag: paywallHeroTag,
    child: PlanSummaryPill(plan: plan),
  );
}

/// Compact plan summary: "Dein Plan · Reisen · 10 Wörter / Tag".
class PlanSummaryPill extends StatelessWidget {
  const PlanSummaryPill({super.key, required this.plan});

  final PaywallContext plan;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      label: 'Dein Plan: ${plan.interest}, ${plan.dailyGoal} Wörter am Tag',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 7, 14, 7),
        decoration: BoxDecoration(
          color: colors.raisedInk,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.checkmark_seal_fill,
              size: 18,
              color: colors.progressWords,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Dein Plan · ${plan.interest} · ${plan.dailyGoal} Wörter / Tag',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppType.meta(color: colors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
