import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/preferences.dart';
import '../presentation/providers/preferences_provider.dart';
import '../screens/onboarding/paywall_screen.dart';
import '../theme/app_theme.dart';
import 'light_sweep.dart';
import 'popover_content.dart';

/// Inner padding of the bubble while it shows [TranslationPaywallCard].
const translationPaywallPadding = EdgeInsets.fromLTRB(16, 14, 14, 16);

/// Shown in the word or sentence bubble once the free AI translations are
/// used up (user request 01.11.2026, like Duolingo's streak widgets): "Ups!"
/// top left, a worried speech bubble top right, the Premium button below
/// with a glint every three seconds. No source text, no quota sentence.
class TranslationPaywallCard extends ConsumerStatefulWidget {
  const TranslationPaywallCard({super.key});

  static const title = 'Ups!';
  static const detail = 'Deine Übersetzungen sind alle.';
  static const action = 'Premium holen';

  @override
  ConsumerState<TranslationPaywallCard> createState() =>
      _TranslationPaywallCardState();
}

class _TranslationPaywallCardState extends ConsumerState<TranslationPaywallCard>
    with SingleTickerProviderStateMixin {
  late final _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 720),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _entrance.value = 1;
    } else if (_entrance.isDismissed) {
      _entrance.forward();
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  void _openPaywall() {
    HapticFeedback.selectionClick();
    final navigator = Navigator.of(context);
    final goal =
        (ref.read(preferencesProvider).asData?.value ??
                const PracticePreferences())
            .dailyGoal;
    navigator.pop();
    navigator.push(
      PaywallScreen.route(
        plan: (interest: 'deinen Themen', dailyGoal: goal),
        onContinue: () {},
      ),
    );
  }

  /// Rises 8 pt and fades in between [start] and [end] of the entrance.
  Widget _rise(double start, double end, Widget child) {
    final curve = CurvedAnimation(
      parent: _entrance,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.25),
          end: Offset.zero,
        ).animate(curve),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _rise(
                  0,
                  0.5,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          TranslationPaywallCard.title,
                          style: AppType.chrome(
                            size: 24,
                            weight: FontWeight.w800,
                            color: popoverInk,
                            height: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        TranslationPaywallCard.detail,
                        style: PopoverText.small(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ScaleTransition(
                scale: CurvedAnimation(
                  parent: _entrance,
                  curve: const Interval(0.15, 0.85, curve: Curves.easeOutBack),
                ),
                child: const ExcludeSemantics(child: _WorriedBubble()),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _rise(
            0.35,
            0.9,
            _PremiumButton(
              label: TranslationPaywallCard.action,
              onPressed: _openPaywall,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dark pill on the orange bubble so the glint can show; white label.
class _PremiumButton extends StatelessWidget {
  const _PremiumButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: CupertinoButton(
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      minimumSize: const Size(44, 46),
      child: Semantics(
        label: label,
        button: true,
        excludeSemantics: true,
        child: LightSweep(
          highlight: const Color(0x66FFFFFF),
          delay: const Duration(milliseconds: 700),
          child: Container(
            constraints: const BoxConstraints(minHeight: 46),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.nightPage,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppType.chrome(
                size: 17,
                weight: FontWeight.w800,
                color: popoverInk,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// A white speech bubble with eyes that has run dry: it bobs, blinks and
/// sweats a drop now and then. Still with reduced motion.
class _WorriedBubble extends StatefulWidget {
  const _WorriedBubble();

  static const size = Size(60, 56);

  @override
  State<_WorriedBubble> createState() => _WorriedBubbleState();
}

class _WorriedBubbleState extends State<_WorriedBubble>
    with SingleTickerProviderStateMixin {
  late final _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _loop
        ..stop()
        ..value = 0;
    } else if (!_loop.isAnimating) {
      _loop.repeat();
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      size: _WorriedBubble.size,
      painter: _WorriedBubblePainter(_loop, ink: context.appColors.popover),
    ),
  );
}

class _WorriedBubblePainter extends CustomPainter {
  _WorriedBubblePainter(this.loop, {required this.ink}) : super(repaint: loop);

  final Animation<double> loop;
  final Color ink;

  static const _white = Color(0xFFFFFFFF);
  static const _face = Color(0xFF5C2600);
  static const _drop = Color(0xFFCFEBFF);

  @override
  void paint(Canvas canvas, Size size) {
    final t = loop.value;
    final bob = math.sin(t * 2 * math.pi) * 1.6;
    canvas.save();
    canvas.translate(0, bob);

    // Body: rounded bubble with a tail at the bottom left.
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(4, 8, size.width - 12, size.height - 22),
      const Radius.circular(14),
    );
    final tail = Path()
      ..moveTo(body.left + 12, body.bottom - 2)
      ..quadraticBezierTo(
        body.left + 8,
        body.bottom + 9,
        body.left + 3,
        body.bottom + 11,
      )
      ..quadraticBezierTo(
        body.left + 15,
        body.bottom + 9,
        body.left + 22,
        body.bottom - 2,
      )
      ..close();
    final fill = Paint()..color = _white;
    canvas
      ..drawRRect(body, fill)
      ..drawPath(tail, fill);

    // Eyes glance down and blink once per loop.
    final blink = t > 0.62 && t < 0.69 ? 0.15 : 1.0;
    final eyeY = body.center.dy - 1;
    final face = Paint()..color = _face;
    for (final dx in [-8.0, 8.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(body.center.dx + dx, eyeY),
          width: 6.5,
          height: 9 * blink,
        ),
        face,
      );
    }
    // Worried brows.
    final brow = Paint()
      ..color = _face
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(
        Offset(body.center.dx - 12, eyeY - 8),
        Offset(body.center.dx - 5, eyeY - 10),
        brow,
      )
      ..drawLine(
        Offset(body.center.dx + 5, eyeY - 10),
        Offset(body.center.dx + 12, eyeY - 8),
        brow,
      );
    // Small "o" mouth.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(body.center.dx, eyeY + 9),
        width: 5,
        height: 4,
      ),
      face,
    );
    canvas.restore();

    // A sweat drop slides off the top right corner and fades.
    final dropT = ((t - 0.08) / 0.5).clamp(0.0, 1.0);
    if (dropT > 0 && dropT < 1) {
      final opacity = dropT < 0.2 ? dropT / 0.2 : 1 - (dropT - 0.2) / 0.8;
      final center = Offset(
        size.width - 6,
        6 + Curves.easeIn.transform(dropT) * 12 + bob,
      );
      final drop = Path()
        ..moveTo(center.dx, center.dy - 6)
        ..quadraticBezierTo(
          center.dx + 4.5,
          center.dy + 0.5,
          center.dx,
          center.dy + 3.5,
        )
        ..quadraticBezierTo(
          center.dx - 4.5,
          center.dy + 0.5,
          center.dx,
          center.dy - 6,
        )
        ..close();
      canvas.drawPath(
        drop,
        Paint()..color = _drop.withValues(alpha: opacity.clamp(0.0, 1.0)),
      );
    }
  }

  @override
  bool shouldRepaint(_WorriedBubblePainter oldDelegate) =>
      oldDelegate.loop != loop || oldDelegate.ink != ink;
}
