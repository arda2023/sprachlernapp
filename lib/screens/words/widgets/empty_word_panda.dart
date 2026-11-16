import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:rive/rive.dart' as rive;

import '../../../theme/app_theme.dart';

class EmptyWordPanda extends StatefulWidget {
  const EmptyWordPanda({super.key});

  static const asset = 'assets/rive/panda_peek.riv';

  @override
  State<EmptyWordPanda> createState() => _EmptyWordPandaState();
}

class _EmptyWordPandaState extends State<EmptyWordPanda>
    with SingleTickerProviderStateMixin {
  static const _hint =
      'Übe einen Stapel oder füge ein Wort aus einer Story hinzu.';
  static const _aspectRatio = 420 / 640;

  // The Rive entrance settles at frame 104 (60 fps). Start this clock only
  // once the loaded Rive widget is painted, and pause alongside the panda.
  // The bubble then unfolds for 1300 ms: tail, body, then the words.
  static const _settleMs = 1733, _bubbleMs = 1300;
  late final _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: _settleMs + _bubbleMs),
  );
  late final _bubbleIn = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(_settleMs / (_settleMs + _bubbleMs), 1),
  );
  bool _painted = false;
  late final AppLifecycleListener _lifecycle;
  late AssetBundle _bundle;
  late bool _foreground;
  bool _visibleRoute = false;
  bool _reduceMotion = false;
  bool _loadStarted = false;
  rive.File? _file;
  rive.RiveWidgetController? _controller;
  rive.ViewModelInstance? _settings;
  rive.ViewModelInstanceBoolean? _reducedMotionBinding;

  bool get _visible => _foreground && _visibleRoute;

  @override
  void initState() {
    super.initState();
    final state = WidgetsBinding.instance.lifecycleState;
    _foreground = state == null || state == AppLifecycleState.resumed;
    _lifecycle = AppLifecycleListener(
      onStateChange: (state) {
        final foreground = state == AppLifecycleState.resumed;
        if (foreground == _foreground) return;
        setState(() => _foreground = foreground);
        _updatePlayback();
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bundle = DefaultAssetBundle.of(context);
    _visibleRoute =
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.isCurrentOf(context) ?? true);
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _updatePlayback();
  }

  void _updatePlayback() {
    if (_painted) {
      if (_reduceMotion) {
        _entrance.value = 1;
      } else if (_visible) {
        if (!_entrance.isCompleted && !_entrance.isAnimating) {
          _entrance.forward();
        }
      } else {
        _entrance.stop();
      }
    }
    if (_visible && !_loadStarted && rive.RiveNative.isInitialized) {
      _loadStarted = true;
      unawaited(_loadPanda());
    }
    final reduction = _reducedMotionBinding;
    if (reduction != null && reduction.value != _reduceMotion) {
      reduction.value = _reduceMotion;
    }
  }

  Future<void> _loadPanda() async {
    rive.File? file;
    rive.RiveWidgetController? controller;
    rive.ViewModelInstance? settings;
    try {
      file = await rive.File.asset(
        EmptyWordPanda.asset,
        riveFactory: rive.Factory.flutter,
        bundle: _bundle,
      );
      if (!mounted || file == null) return;

      controller = rive.RiveWidgetController(
        file,
        artboardSelector: rive.ArtboardSelector.byName('Panda Thinking'),
        stateMachineSelector: rive.StateMachineSelector.byName(
          'Panda Controller',
        ),
      );
      settings = controller.dataBind(rive.DataBind.auto());
      final reducedMotion = settings.boolean('reducedMotion');
      if (reducedMotion == null) return;
      reducedMotion.value = _reduceMotion;
      setState(() {
        _file = file;
        _controller = controller;
        _settings = settings;
        _reducedMotionBinding = reducedMotion;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _painted = true;
        _updatePlayback();
      });
    } catch (_) {
      // The hint remains available if the animation can't be loaded.
    } finally {
      if (_file == null) {
        controller?.dispose();
        settings?.dispose();
        file?.dispose();
      }
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _bubbleIn.dispose();
    _entrance.dispose();
    _controller?.dispose();
    _settings?.dispose();
    _file?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: controller == null
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  _hint,
                  style: AppType.chrome(color: context.appColors.textMuted),
                ),
              )
            : ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        constraints.maxWidth * 0.29,
                        constraints.maxHeight * 0.12,
                        28,
                        24,
                      ),
                      child: PandaHintBubble(_hint, progress: _bubbleIn),
                    ),

                    SizedBox(
                      width: math.min(constraints.maxWidth * 0.52, 260),
                      child: AspectRatio(
                        aspectRatio: _aspectRatio,
                        child: ExcludeSemantics(
                          child: TickerMode(
                            enabled: _visible,
                            child: rive.RiveWidget(
                              controller: controller,
                              fit: rive.Fit.contain,
                              alignment: Alignment.centerLeft,
                              hitTestBehavior: rive.RiveHitTestBehavior.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }
}

/// Speech bubble that unfolds from its tail: the tail grows toward the panda,
/// the body widens from the left while rising, then the words fade in one by
/// one. Layout always uses the final size, so wrapping never jumps.
class PandaHintBubble extends StatelessWidget {
  const PandaHintBubble(this.hint, {super.key, required this.progress});

  final String hint;

  /// 0 = hidden, 1 = fully shown.
  final Animation<double> progress;

  static const _ease = Cubic(0.23, 1, 0.32, 1);

  /// Fraction of [progress] mapped onto [begin]..[end] with the app curve.
  static double phase(double t, double begin, double end) =>
      _ease.transform(((t - begin) / (end - begin)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    final color = context.appColors.popover;
    final words = hint.split(' ');
    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) {
        final t = progress.value;
        final body = _BubbleShape.bodyRect;
        return CustomPaint(
          painter: _BubblePainter(color: color, t: t),
          child: ClipPath(
            clipper: _BodyClipper(t, body),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Transform.translate(
                offset: Offset(0, 4 * (1 - phase(t, 0.4, 0.85))),
                child: Text.rich(
                  TextSpan(
                    children: [
                      for (var i = 0; i < words.length; i++)
                        TextSpan(
                          text: i == words.length - 1
                              ? words[i]
                              : '${words[i]} ',
                          style: TextStyle(
                            color: AppColors.onActive.withValues(
                              alpha: phase(
                                t,
                                0.4 + i * 0.035,
                                0.64 + i * 0.035,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  semanticsLabel: hint,
                  style: AppType.chrome(
                    color: AppColors.onActive,
                    size: 15,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Animated geometry shared by painter and clipper.
abstract final class _BubbleShape {
  static const radius = 20.0, tailBase = 40.0, tailWidth = 22.0;
  static const tailDrop = 15.0, tailLean = 13.0;

  /// Body rectangle anchored bottom-left: wider first, then taller.
  static Rect bodyRect(Size size, double t) {
    final minWidth = math.min(tailBase + tailWidth + radius, size.width);
    final minHeight = math.min(radius * 1.6, size.height);
    final w =
        minWidth +
        (size.width - minWidth) * PandaHintBubble.phase(t, 0.08, 0.62);
    final h =
        minHeight +
        (size.height - minHeight) * PandaHintBubble.phase(t, 0.16, 0.66);
    return Rect.fromLTWH(0, size.height - h, w, h);
  }
}

class _BodyClipper extends CustomClipper<Path> {
  _BodyClipper(this.t, this.rect);

  final double t;
  final Rect Function(Size, double) rect;

  @override
  Path getClip(Size size) {
    final body = rect(size, t);
    return Path()..addRRect(
      RRect.fromRectAndRadius(
        body,
        Radius.circular(math.min(_BubbleShape.radius, body.height / 2)),
      ),
    );
  }

  @override
  bool shouldReclip(_BodyClipper old) => old.t != t;
}

class _BubblePainter extends CustomPainter {
  _BubblePainter({required this.color, required this.t});

  final Color color;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    final paint = Paint()
      ..color = color.withValues(
        alpha: color.a * PandaHintBubble.phase(t, 0, 0.12),
      );
    final body = _BubbleShape.bodyRect(size, t);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        body,
        Radius.circular(math.min(_BubbleShape.radius, body.height / 2)),
      ),
      paint,
    );
    // Tail leans left toward the panda and grows out of the body's lower edge.
    final grow = PandaHintBubble.phase(t, 0, 0.3);
    final left = _BubbleShape.tailBase, right = left + _BubbleShape.tailWidth;
    final base = size.height - 1;
    final tip = Offset(
      left - _BubbleShape.tailLean * grow,
      size.height + _BubbleShape.tailDrop * grow,
    );
    canvas.drawPath(
      Path()
        ..moveTo(left, base)
        ..quadraticBezierTo(left - 1, base + 7 * grow, tip.dx, tip.dy)
        ..quadraticBezierTo(left + 9, base + 9 * grow, right, base)
        ..close(),
      paint,
    );
  }

  @override
  bool shouldRepaint(_BubblePainter old) => old.t != t || old.color != color;
}
