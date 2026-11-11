import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../../theme/app_theme.dart';

/// The colours of one exercise kind's stage: a deep ground with lighter
/// concentric discs (user request 01.11.2026, after a Bubble screen). Text
/// on any disc keeps at least 4.5:1.
class ExerciseStageTone {
  const ExerciseStageTone._({
    required this.ground,
    required this.glow,
    required this.ink,
    required this.mutedInk,
    required this.surface,
    required this.light,
  });

  /// Hören: deep indigo violet.
  factory ExerciseStageTone.listening(AppPalette colors) => colors.light
      ? const ExerciseStageTone._(
          ground: Color(0xFFF1EEFA),
          glow: Color(0xFFDCD3F6),
          ink: Color(0xFF1C1733),
          mutedInk: Color(0xFF575073),
          surface: Color(0x14251B5C),
          light: true,
        )
      : const ExerciseStageTone._(
          ground: Color(0xFF130E29),
          glow: Color(0xFF3A2B78),
          ink: Color(0xFFF4F2FB),
          mutedInk: Color(0xFFC3BCE3),
          surface: Color(0x1FFFFFFF),
          light: false,
        );

  /// Grammatik: plum, the pink-violet of the reference.
  factory ExerciseStageTone.grammar(AppPalette colors) => colors.light
      ? const ExerciseStageTone._(
          ground: Color(0xFFF8EFF6),
          glow: Color(0xFFEDD3EA),
          ink: Color(0xFF2B1428),
          mutedInk: Color(0xFF6B4E66),
          surface: Color(0x14501946),
          light: true,
        )
      : const ExerciseStageTone._(
          ground: Color(0xFF1A0D20),
          glow: Color(0xFF55215C),
          ink: Color(0xFFFBF2F9),
          mutedInk: Color(0xFFE0C3DA),
          surface: Color(0x1FFFFFFF),
          light: false,
        );

  final Color ground;

  /// The innermost disc; outer discs step back towards [ground].
  final Color glow;
  final Color ink;
  final Color mutedInk;

  /// Answer cards and the explanation: a veil of ink over the discs.
  final Color surface;
  final bool light;
}

/// Paints the stage behind a whole screen: the ground and five concentric
/// discs. They centre on [focus] (the play button) wherever it is laid out
/// and scrolled to, else they rise from above the top edge. The discs
/// always drift a little, each on its own slow path (user request
/// 01.11.2026: alive, not busy); while [pulse] runs they also breathe
/// outwards like sound. Reduced motion: still.
class ExerciseStage extends StatefulWidget {
  const ExerciseStage({
    super.key,
    required this.tone,
    this.focus,
    this.scroll,
    this.pulse = false,
  });

  final ExerciseStageTone tone;
  final GlobalKey? focus;

  /// Repaints while the content moves the [focus].
  final ScrollController? scroll;
  final bool pulse;

  @override
  State<ExerciseStage> createState() => _ExerciseStageState();
}

class _ExerciseStageState extends State<ExerciseStage>
    with TickerProviderStateMixin {
  late final _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  /// The slow drift that never stops while the screen is visible.
  late final _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 11),
  );

  /// How strongly the discs breathe: eases in and out with [pulse].
  late final _level =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      )..addStatusListener((status) {
        if (status == AnimationStatus.dismissed) _breath.stop();
      });
  final _self = GlobalKey();
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) {
      _entrance.value = 1;
      _drift.stop();
    } else {
      if (_entrance.isDismissed) _entrance.forward();
      if (!_drift.isAnimating) _drift.repeat();
    }
    _syncPulse();
  }

  @override
  void didUpdateWidget(ExerciseStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pulse != widget.pulse) _syncPulse();
  }

  void _syncPulse() {
    if (widget.pulse && !_reduceMotion) {
      if (!_breath.isAnimating) _breath.repeat();
      _level.forward();
    } else {
      _level.reverse();
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    _drift.dispose();
    _breath.dispose();
    _level.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      key: _self,
      painter: _StagePainter(
        tone: widget.tone,
        focus: widget.focus,
        self: _self,
        entrance: _entrance,
        drift: _drift,
        breath: _breath,
        level: _level,
        repaint: Listenable.merge([
          _entrance,
          _drift,
          _breath,
          _level,
          ?widget.scroll,
        ]),
      ),
      child: const SizedBox.expand(),
    ),
  );
}

class _StagePainter extends CustomPainter {
  _StagePainter({
    required this.tone,
    required this.focus,
    required this.self,
    required this.entrance,
    required this.drift,
    required this.breath,
    required this.level,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final ExerciseStageTone tone;
  final GlobalKey? focus;
  final GlobalKey self;
  final Animation<double> entrance;
  final Animation<double> drift;
  final Animation<double> breath;
  final Animation<double> level;

  /// Where [focus] sits in this painter's own coordinates. Layout is done
  /// before anything paints, so this frame's position is already known.
  Offset? _focusCentre() {
    final target = focus?.currentContext?.findRenderObject();
    final me = self.currentContext?.findRenderObject();
    if (target is! RenderBox || me is! RenderBox) return null;
    if (!target.hasSize || !target.attached || !me.attached) return null;
    return target.localToGlobal(target.size.center(Offset.zero)) -
        me.localToGlobal(Offset.zero);
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = tone.ground);
    final focused = _focusCentre();
    final centre = focused ?? Offset(size.width / 2, -size.height * 0.06);
    // Around a button the discs start just outside it; from above the top
    // edge they reach well into the screen.
    final unit = math.min(size.width, 430.0);
    final radii = focused != null
        ? [unit * 0.31, unit * 0.48, unit * 0.68, unit * 0.92, unit * 1.22]
        : [
            size.height * 0.26,
            size.height * 0.36,
            size.height * 0.47,
            size.height * 0.6,
            size.height * 0.76,
          ];
    final grow = Curves.easeOutCubic.transform(entrance.value);
    final turn = drift.value * 2 * math.pi;
    final paint = Paint()..isAntiAlias = true;
    // Outermost first, each disc a step closer to the glow.
    for (var i = radii.length - 1; i >= 0; i--) {
      final step = (radii.length - i) / radii.length;
      // Drift: outer discs wander a few points further than inner ones and
      // swell by about 2 %, each out of phase with its neighbours.
      final reach = 2.0 + 1.6 * i;
      final wander = Offset(
        reach * math.sin(turn + i * 1.1),
        reach * 0.8 * math.cos(turn * 2 + i * 0.7),
      );
      final swell = 1 + 0.018 * math.sin(turn + i * 1.4);
      // A ripple: inner discs lead, outer ones follow.
      final ripple = math.sin(breath.value * 2 * math.pi - i * 0.7);
      final r =
          radii[i] *
          (0.82 + 0.18 * grow) *
          swell *
          (1 + 0.035 * level.value * ripple);
      paint.color = Color.lerp(tone.ground, tone.glow, step * grow)!;
      canvas.drawCircle(centre + wander, r, paint);
    }
  }

  @override
  bool shouldRepaint(_StagePainter old) => true;
}
