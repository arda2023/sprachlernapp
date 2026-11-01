import 'package:flutter/widgets.dart';

/// A soft band of light that glides across [child] every [period], drawn
/// only on the child's own pixels: over a button it reads as a glint, over
/// muted text it lights the letters up for a moment. Off with reduced
/// motion and while [enabled] is false.
class LightSweep extends StatefulWidget {
  const LightSweep({
    super.key,
    required this.child,
    required this.highlight,
    this.enabled = true,
    this.period = const Duration(seconds: 3),
    this.sweep = const Duration(milliseconds: 1100),
    this.delay = Duration.zero,
  });

  final Widget child;

  /// The colour at the band's centre.
  final Color highlight;
  final bool enabled;

  /// From one sweep's start to the next.
  final Duration period;

  /// How long one pass takes; the rest of [period] is still.
  final Duration sweep;

  /// Before the first pass, e.g. until an entrance animation has settled.
  final Duration delay;

  @override
  State<LightSweep> createState() => _LightSweepState();
}

class _LightSweepState extends State<LightSweep>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: widget.period,
  );
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _sync();
  }

  @override
  void didUpdateWidget(LightSweep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) _sync();
  }

  void _sync() {
    if (!widget.enabled || _reduceMotion) {
      _controller.reset();
      return;
    }
    if (_controller.isAnimating) return;
    // The first pass waits [delay]: the loop starts that far before its end
    // (no timer that could outlive the widget).
    final wait = widget.delay.inMicroseconds / widget.period.inMicroseconds;
    _controller
      ..value = wait <= 0 ? 0 : 1 - wait.clamp(0.0, 1.0)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || _reduceMotion) return widget.child;
    final share = widget.sweep.inMilliseconds / widget.period.inMilliseconds;
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = (_controller.value / share).clamp(0.0, 1.0);
        // From well left of the child to well right of it, slightly tilted;
        // between passes the band waits outside. The mask always stays in
        // the tree so a text field below keeps its state.
        final x = -1.8 + 3.6 * Curves.easeInOutSine.transform(t);
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment(x - 0.45, -0.7),
            end: Alignment(x + 0.45, 0.7),
            colors: [
              widget.highlight.withValues(alpha: 0),
              widget.highlight,
              widget.highlight.withValues(alpha: 0),
            ],
          ).createShader(bounds),
          child: child,
        );
      },
    );
  }
}
