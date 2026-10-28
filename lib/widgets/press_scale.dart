import 'package:flutter/widgets.dart';

/// Press feedback for large tappable surfaces (covers, deck cards): the
/// child sinks to [pressedScale] while a finger rests on it and springs back
/// on release. A drag (scrolling a carousel) releases it at once, so the
/// feedback never lags behind a scroll. Purely visual; the child keeps its
/// own gesture handling. Reduced motion: no scaling.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, this.pressedScale = 0.97});

  final Widget child;
  final double pressedScale;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  static const _slop = 8.0;
  Offset? _down;
  bool _pressed = false;

  void _set(bool pressed) {
    if (_pressed != pressed) setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Listener(
      onPointerDown: (e) {
        _down = e.position;
        _set(true);
      },
      onPointerMove: (e) {
        if (_down != null && (e.position - _down!).distance > _slop) {
          _set(false);
        }
      },
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _pressed && !reduceMotion ? widget.pressedScale : 1,
        // Quick to sink, a little softer coming back.
        duration: Duration(milliseconds: _pressed ? 100 : 180),
        curve: _pressed ? Curves.easeOut : Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}
