import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme/app_theme.dart';

/// Circular progress: a hairline circle with an arc from 12 o'clock,
/// clockwise. Use a status ink only when the arc means word status (deck
/// mastery); the daily goal stays neutral.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.fraction,
    required this.size,
    this.color,
    this.strokeWidth = 3,
    this.gapDegrees = 0,
    this.trackColor,
    this.child,
  });

  final double fraction;
  final double size;
  final Color? color;
  final double strokeWidth;

  /// Opening at the bottom (0 = full circle). With a gap the ring becomes a
  /// gauge that fills clockwise from the lower left.
  final double gapDegrees;

  /// Defaults to Hairline; on coloured cards a translucent white.
  final Color? trackColor;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _RingPainter(
          fraction: fraction.clamp(0.0, 1.0),
          color: color ?? context.appColors.textMuted,
          trackColor: trackColor ?? context.appColors.hairline,
          strokeWidth: strokeWidth,
          gap: gapDegrees * math.pi / 180,
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.fraction,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
    this.gap = 0,
  });

  final double fraction;
  final Color color, trackColor;
  final double strokeWidth;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(strokeWidth / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    if (gap > 0) {
      // Gauge: from the lower left over the top to the lower right.
      final start = math.pi / 2 + gap / 2;
      final sweep = 2 * math.pi - gap;
      paint.strokeCap = StrokeCap.round;
      canvas.drawArc(rect, start, sweep, false, paint..color = trackColor);
      if (fraction > 0) {
        canvas.drawArc(
          rect,
          start,
          sweep * fraction,
          false,
          paint..color = color,
        );
      }
      return;
    }
    canvas.drawOval(rect, paint..color = trackColor);
    if (fraction > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * fraction,
        false,
        paint
          ..color = color
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.gap != gap ||
      old.fraction != fraction ||
      old.color != color ||
      old.trackColor != trackColor ||
      old.strokeWidth != strokeWidth;
}
