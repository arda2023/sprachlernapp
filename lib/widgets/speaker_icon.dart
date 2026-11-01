import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Speaker with two sound waves, drawn so the waves have the same visual
/// weight as the body (like SF Symbol `speaker.wave.2(.fill)`). The
/// Cupertino glyph renders a heavy body with hairline waves on device.
/// Carries no semantics; callers label it.
class SpeakerIcon extends StatelessWidget {
  const SpeakerIcon({
    super.key,
    this.size = 24,
    required this.color,
    this.filled = true,
  });

  final double size;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _SpeakerPainter(color: color, filled: filled),
      ),
    ),
  );
}

class _SpeakerPainter extends CustomPainter {
  const _SpeakerPainter({required this.color, required this.filled});
  final Color color;
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final stroke = s * 0.09;
    // Glyph spans x 0.08..0.92 of the box; centred vertically.
    final ox = (size.width - s) / 2, oy = (size.height - s) / 2;
    Offset p(double x, double y) => Offset(ox + x * s, oy + y * s);

    final body = Path()
      ..moveTo(p(0.08, 0.38).dx, p(0.08, 0.38).dy)
      ..lineTo(p(0.24, 0.38).dx, p(0.24, 0.38).dy)
      ..lineTo(p(0.46, 0.18).dx, p(0.46, 0.18).dy)
      ..lineTo(p(0.46, 0.82).dx, p(0.46, 0.82).dy)
      ..lineTo(p(0.24, 0.62).dx, p(0.24, 0.62).dy)
      ..lineTo(p(0.08, 0.62).dx, p(0.08, 0.62).dy)
      ..close();
    final bodyPaint = Paint()
      ..color = color
      ..isAntiAlias = true
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = stroke * 0.85
      ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke;
    if (filled) {
      // A thin round stroke softens the corners of the filled body.
      canvas.drawPath(body, bodyPaint);
      canvas.drawPath(
        body,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = stroke * 0.6,
      );
    } else {
      canvas.drawPath(body, bodyPaint);
    }

    final wave = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke;
    final c = p(0.46, 0.5);
    const sweep = math.pi * 0.5;
    for (final r in [0.2, 0.4]) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r * s),
        -sweep / 2,
        sweep,
        false,
        wave,
      );
    }
  }

  @override
  bool shouldRepaint(_SpeakerPainter old) =>
      old.color != color || old.filled != filled;
}
