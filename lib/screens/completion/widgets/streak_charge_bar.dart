import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../../../domain/streak.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/svg_glyph.dart';

/// The week bar of the completion screen: the same six day slots plus the
/// star as on Home, but the orange pill charges from the left like a
/// battery. Each day's check pops as the pill passes it (a ring bursts, the
/// tick draws itself in, small dots fly off, after the bundled
/// `check.riv` reference); on day seven the star dips, swells and flips over
/// in the air to its filled side.
///
/// Everything is driven from outside: [days] is the charge timeline in day
/// units (the pill's right edge is `min(days, target)`), [shimmer] loops the
/// light running through the pill, [star] plays the flip (0–1).
class StreakChargeBar extends StatelessWidget {
  const StreakChargeBar({
    super.key,
    required this.target,
    required this.days,
    required this.shimmer,
    required this.star,
    required this.charging,
  });

  static const size = 32.0;
  static const starSlot = 44.0;

  /// Day the pill fills up to: 1–6 checks, 7 = the star.
  final int target;
  final Animation<double> days;
  final Animation<double> shimmer;
  final Animation<double> star;

  /// Strength of the running light (1 while charging, fades to 0).
  final Animation<double> charging;

  /// How far past a slot's centre the pill has to be before its check pops.
  static const popAt = 0.62;
  static const popSpan = 0.9;

  /// Pop progress of day [i] for a timeline value in days.
  static double popProgress(double days, int i) =>
      ((days - (i + popAt)) / popSpan).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SizedBox(
      height: size,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final slot = (width - starSlot) / streakBarDays;
          final starCentre = slot * streakBarDays + starSlot / 2;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: Listenable.merge([days, shimmer, charging]),
                  builder: (context, _) => CustomPaint(
                    painter: _BarPainter(
                      target: target,
                      days: days.value,
                      shimmer: shimmer.value,
                      charging: charging.value,
                      slot: slot,
                      track: colors.hairline,
                      pill: colors.active,
                      deep: colors.popover,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: starCentre - starSlot / 2,
                top: 0,
                width: starSlot,
                height: size,
                child: AnimatedBuilder(
                  animation: Listenable.merge([days, star]),
                  builder: (context, _) => _FlippingStar(
                    // How far the pill has run under the star (0–1).
                    covered: target > streakBarDays
                        ? (days.value - streakBarDays).clamp(0.0, 1.0)
                        : 0,
                    flip: star.value,
                    lit: target > streakBarDays,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({
    required this.target,
    required this.days,
    required this.shimmer,
    required this.charging,
    required this.slot,
    required this.track,
    required this.pill,
    required this.deep,
  });

  final int target;
  final double days, shimmer, charging, slot;
  final Color track, pill, deep;

  static const _white = Color(0xFFFFFFFF);
  static const _r = StreakChargeBar.size / 2;

  double _centre(int i) => slot * (i + 0.5);

  /// Right edge of the pill in pixels for a fill in days.
  double _edge(double fill) => fill <= streakBarDays
      ? fill * slot
      : slot * streakBarDays +
            (fill - streakBarDays) * StreakChargeBar.starSlot;

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final trackPaint = Paint()..color = track;
    for (var i = 0; i < streakBarDays; i++) {
      canvas.drawCircle(Offset(_centre(i), cy), _r, trackPaint);
    }

    final fill = math.min(days, target.toDouble());
    final pillWidth = _edge(fill) - 4;
    if (pillWidth > 0) {
      final rect = pillWidth >= StreakChargeBar.size
          ? Rect.fromLTWH(2, 0, pillWidth, size.height)
          // Grows in as a dot on the first slot until it is a full circle.
          : Rect.fromCircle(
              center: Offset(_centre(0), cy),
              radius: _r * pillWidth / StreakChargeBar.size,
            );
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(_r));
      // Deep orange at the start, bright at the charging head, with a band
      // of light that keeps running right like a battery filling up.
      final head = Color.lerp(pill, const Color(0xFFFFB347), 0.35 * charging)!;
      final light = Color.lerp(pill, _white, 0.5 * charging)!;
      final band = rect.left + rect.width * (shimmer * 1.6 - 0.3);
      double stop(double x) =>
          ((x - rect.left) / rect.width).clamp(0.0, 1.0).toDouble();
      final stops = [0.0, stop(band - 40), stop(band), stop(band + 40), 1.0];
      canvas.drawRRect(
        rrect,
        Paint()
          ..shader = LinearGradient(
            colors: [
              Color.lerp(pill, deep, charging)!,
              Color.lerp(pill, deep, 0.4 * charging)!,
              light,
              Color.lerp(pill, head, 0.6)!,
              head,
            ],
            stops: _monotonic(stops),
          ).createShader(rect),
      );
    }

    for (var i = 0; i < math.min(target, streakBarDays); i++) {
      final t = StreakChargeBar.popProgress(days, i);
      if (t > 0) _drawCheck(canvas, Offset(_centre(i), cy), t);
    }
  }

  /// Gradient stops must not decrease.
  static List<double> _monotonic(List<double> stops) {
    final out = <double>[];
    var last = 0.0;
    for (final s in stops) {
      last = math.max(last, s);
      out.add(last);
    }
    return out;
  }

  static double _seg(double t, double from, double to) =>
      ((t - from) / (to - from)).clamp(0.0, 1.0);

  void _drawCheck(Canvas canvas, Offset c, double t) {
    // Ring burst.
    final ring = _seg(t, 0, 0.6);
    if (ring < 1) {
      canvas.drawCircle(
        c,
        7 + 15 * Curves.easeOutCubic.transform(ring),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 * (1 - ring) + 0.5
          ..color = _white.withValues(alpha: 0.6 * (1 - ring)),
      );
    }
    // Dots flying off.
    final fly = _seg(t, 0.15, 0.8);
    if (fly > 0 && fly < 1) {
      final paint = Paint()..color = _white.withValues(alpha: 1 - fly);
      final dist = 13 + 11 * Curves.easeOutCubic.transform(fly);
      for (var k = 0; k < 6; k++) {
        final a = -math.pi / 2 + k * math.pi / 3 + math.pi / 6;
        canvas.drawCircle(
          c + Offset(math.cos(a), math.sin(a)) * dist,
          1.8 * (1 - fly) + 0.4,
          paint,
        );
      }
    }
    // The tick: pops with a little overshoot while it draws itself in.
    final scale = 0.55 + 0.45 * Curves.easeOutBack.transform(_seg(t, 0, 0.7));
    final draw = Curves.easeOutCubic.transform(_seg(t, 0.05, 0.5));
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(scale);
    final path = Path()
      ..moveTo(-5.5, 0.2)
      ..lineTo(-1.6, 4)
      ..lineTo(5.8, -4.2);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * draw),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = _white,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.days != days ||
      old.shimmer != shimmer ||
      old.charging != charging ||
      old.slot != slot ||
      old.track != track ||
      old.pill != pill;
}

/// Open: outline (orange, turning white as the pill runs under it). On day
/// seven it dips, swells and turns over in the air; past the edge-on moment
/// the filled side shows.
class _FlippingStar extends StatelessWidget {
  const _FlippingStar({
    required this.covered,
    required this.flip,
    required this.lit,
  });

  final double covered;
  final double flip;
  final bool lit;

  /// Dip, swell, settle – each leg eased in and out so the motion has no
  /// hard corners (like rounded keyframes in After Effects).
  static final _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 0.72,
      ).chain(CurveTween(curve: Curves.easeInOutSine)),
      weight: 22,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 0.72,
        end: 1.45,
      ).chain(CurveTween(curve: Curves.easeInOutCubic)),
      weight: 33,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.45,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeInOutSine)),
      weight: 45,
    ),
  ]);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    const white = Color(0xFFFFFFFF);
    final outline = Color.lerp(colors.active, white, covered)!;
    final turn = Curves.easeInOutCubic.transform(
      ((flip - 0.25) / 0.5).clamp(0.0, 1.0),
    );
    final angle = turn * math.pi;
    final showSolid = lit && angle > math.pi / 2;
    final lift = math.sin(((flip - 0.15) / 0.7).clamp(0.0, 1.0) * math.pi);
    final glow = math.sin(((flip - 0.6) / 0.4).clamp(0.0, 1.0) * math.pi);
    final transform = Matrix4.identity()
      ..setEntry(3, 2, 0.002)
      ..translateByDouble(0, -12 * lift, 0, 1)
      ..rotateY(showSolid ? angle - math.pi : angle)
      ..scaleByDouble(
        flip > 0 ? _scale.transform(flip) : 1,
        flip > 0 ? _scale.transform(flip) : 1,
        1,
        1,
      );
    return Center(
      child: Transform(
        alignment: Alignment.center,
        transform: transform,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              if (glow > 0)
                BoxShadow(
                  color: const Color(0xFFFFE2A8).withValues(alpha: 0.8 * glow),
                  blurRadius: 18 * glow,
                  spreadRadius: 4 * glow,
                ),
            ],
          ),
          child: showSolid
              ? const GlyphIcon(AppGlyphs.starSolid, size: 24, color: white)
              : GlyphIcon(AppGlyphs.starOutline, size: 30, color: outline),
        ),
      ),
    );
  }
}
