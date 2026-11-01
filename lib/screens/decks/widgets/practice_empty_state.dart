import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/action_buttons.dart';

/// Nothing to practise in this scope: a sleepy card stack that bobs while
/// little "z"s drift up, a serif title, one quiet line and at most one
/// action (Refero references: illustration, title and calm subtext as in
/// UNHINGED's empty archive). Reduced motion shows the still stack.
class PracticeEmptyState extends StatelessWidget {
  const PracticeEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final still = MediaQuery.disableAnimationsOf(context);
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SleepyCardStack(),
        const SizedBox(height: 28),
        Semantics(
          header: true,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: AppType.editorial(color: colors.textPrimary, size: 24),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppType.chrome(
            size: 15,
            weight: FontWeight.w400,
            color: colors.textMuted,
            height: 1.4,
          ),
        ),
        if (actionLabel case final label?) ...[
          const SizedBox(height: 28),
          PrimaryActionButton(label: label, onPressed: onAction),
        ],
      ],
    );
    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.sizeOf(context).height * 0.1,
        left: 12,
        right: 12,
      ),
      child: still
          ? content
          : TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 480),
              curve: Curves.easeOutCubic,
              builder: (context, t, child) => Opacity(
                opacity: t,
                child: Transform.translate(
                  offset: Offset(0, 16 * (1 - t)),
                  child: child,
                ),
              ),
              child: content,
            ),
    );
  }
}

/// Three fanned cards; the front one in popover orange has a sleeping face.
/// The stack breathes and three "z" rise and fade in a loop.
class SleepyCardStack extends StatefulWidget {
  const SleepyCardStack({super.key});

  static const size = Size(180, 150);

  @override
  State<SleepyCardStack> createState() => _SleepyCardStackState();
}

class _SleepyCardStackState extends State<SleepyCardStack>
    with SingleTickerProviderStateMixin {
  late final _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.disableAnimationsOf(context);
    if (still) {
      _loop.value = 0;
      _loop.stop();
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
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return ExcludeSemantics(
      child: SizedBox.fromSize(
        size: SleepyCardStack.size,
        child: AnimatedBuilder(
          animation: _loop,
          builder: (context, _) {
            final t = _loop.value;
            final breath = math.sin(t * 2 * math.pi);
            Widget card(
              double angle,
              double dx,
              double dy,
              Color color, {
              Widget? child,
            }) => Positioned(
              left: 40 + dx,
              top: 30 + dy,
              child: Transform.rotate(
                angle: angle,
                child: Container(
                  width: 100,
                  height: 76,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: child,
                ),
              ),
            );
            return Stack(
              clipBehavior: Clip.none,
              children: [
                // Soft glow under the stack, like the onboarding buttons.
                Positioned(
                  left: 30,
                  right: 30,
                  bottom: 6,
                  child: Container(
                    height: 18,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      boxShadow: [
                        BoxShadow(
                          color: colors.active.withValues(
                            alpha: 0.18 + 0.06 * breath,
                          ),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                card(-0.20, -14, 10 + 2 * breath, colors.hairline),
                card(0.14, 16, 4 + 3 * breath, colors.raisedInk),
                card(
                  -0.03,
                  0,
                  12 + 4 * breath,
                  colors.popover,
                  child: CustomPaint(painter: _SleepyFace(breath)),
                ),
                for (var i = 0; i < 3; i++) _z(t, i, colors.textMuted),
              ],
            );
          },
        ),
      ),
    );
  }

  /// One "z": rises from the card's corner, drifts right and fades; the
  /// three are staggered by a third of the loop.
  Widget _z(double t, int i, Color color) {
    final p = (t + i / 3) % 1;
    final opacity = p < 0.15
        ? p / 0.15
        : p > 0.7
        ? (1 - p) / 0.3
        : 1.0;
    return Positioned(
      left: 128 + 18 * p + 4 * math.sin(p * 2 * math.pi),
      top: 30 - 34 * p,
      child: Opacity(
        opacity: opacity.clamp(0, 1),
        child: Text(
          'z',
          style: AppType.editorial(
            color: color,
            size: 17 + 8 * p,
            weight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Closed eyes as two arcs and a small round mouth that breathes.
class _SleepyFace extends CustomPainter {
  const _SleepyFace(this.breath);

  final double breath;

  @override
  void paint(Canvas canvas, Size size) {
    final ink = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    final eyeY = size.height * 0.44;
    for (final x in [size.width * 0.34, size.width * 0.66]) {
      canvas.drawArc(
        Rect.fromCenter(center: Offset(x, eyeY), width: 16, height: 10),
        0.15,
        math.pi - 0.3,
        false,
        ink,
      );
    }
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.7),
        width: 8 + breath,
        height: 6 + 1.5 * breath,
      ),
      Paint()..color = const Color(0xFFFFFFFF),
    );
  }

  @override
  bool shouldRepaint(_SleepyFace old) => old.breath != breath;
}
