import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/light_sweep.dart';
import '../../../widgets/press_scale.dart';

class TutorSessionBar extends StatelessWidget {
  const TutorSessionBar({
    super.key,
    required this.done,
    required this.total,
    required this.onClose,
  });
  final int done, total;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          PressScale(
            child: MergeSemantics(
              child: CupertinoButton(
                onPressed: onClose,
                padding: EdgeInsets.zero,
                minimumSize: const Size(44, 44),
                child: Semantics(
                  label: 'Runde beenden',
                  excludeSemantics: true,
                  child: Icon(
                    CupertinoIcons.xmark,
                    size: 22,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Semantics(
                label: 'Rundenfortschritt',
                value: '$done von $total Sätzen',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: SizedBox(
                    height: 6,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(
                        end: total == 0 ? 0 : (done / total).clamp(0.0, 1.0),
                      ),
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) => Stack(
                        fit: StackFit.expand,
                        children: [
                          ColoredBox(color: colors.hairline),
                          FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: value,
                            child: ColoredBox(color: colors.active),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}

class TutorActionButton extends StatelessWidget {
  const TutorActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final active = busy || onPressed != null;
    return PressScale(
      child: MergeSemantics(
        child: CupertinoButton(
          onPressed: busy ? null : onPressed,
          padding: EdgeInsets.zero,
          minimumSize: const Size(44, 52),
          child: Semantics(
            label: busy ? 'Wird geladen' : label,
            liveRegion: busy,
            excludeSemantics: true,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LightSweep(
                enabled: busy,
                highlight: colors.raisedInk.withValues(alpha: .18),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 52),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: active ? colors.popover : colors.raisedInk,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Keep the exact same button height during loading.
                      Opacity(
                        opacity: busy ? 0 : 1,
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: AppType.chrome(
                            size: 17,
                            weight: FontWeight.w600,
                            color: active ? colors.onActive : colors.textMuted,
                          ),
                        ),
                      ),
                      if (busy) const TutorThinkingDots(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Same three dots and phase offsets as the paywall tutor demo; only the
/// pending request owns a ticker, reduced motion shows three static dots.
class TutorThinkingDots extends StatefulWidget {
  const TutorThinkingDots({super.key});
  @override
  State<TutorThinkingDots> createState() => _TutorThinkingDotsState();
}

class _TutorThinkingDotsState extends State<TutorThinkingDots>
    with SingleTickerProviderStateMixin {
  late final _clock = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _clock.stop();
      _clock.value = 1;
    } else if (!_clock.isAnimating) {
      _clock.repeat();
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _clock,
    builder: (context, _) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Container(
            width: 7,
            height: 7,
            margin: const EdgeInsets.symmetric(horizontal: 2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.appColors.onActive.withValues(
                alpha: MediaQuery.disableAnimationsOf(context)
                    ? 1
                    : .35 +
                          .65 *
                              (.5 +
                                  .5 *
                                      math.sin(
                                        _clock.value * math.pi * 4 - i * .9,
                                      )),
              ),
            ),
          ),
      ],
    ),
  );
}
