import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../presentation/providers/language_selection_provider.dart';
import '../theme/app_theme.dart';
import 'word_rain.dart';

/// The launch screen while content and Home load, instead of spinners
/// (user request 29.10.2026). The Linglossa mark builds itself – bubble pops,
/// the "L" draws, the dot lands – then breathes over a soft ember glow, the
/// way the onboarding buttons glow (Refero references: centred mark on a
/// dark ground as in Matter, Revolut and the glowing icon of Kann).
///
/// One clock for the whole launch, so the startup gate and the curtain over
/// the app continue the same animation instead of restarting it.
class LaunchSplash extends StatefulWidget {
  const LaunchSplash({super.key, this.caption});

  /// A quiet line under the wordmark, e.g. while a slow install runs.
  final String? caption;

  /// Set by `main`. Widget tests never call it, so they see a still splash
  /// and no curtain (pumpAndSettle would otherwise wait for the loop).
  static bool enabled = false;

  /// Since the first splash frame.
  static final Stopwatch clock = Stopwatch()..start();

  static const intro = Duration(milliseconds: 1100);

  @override
  State<LaunchSplash> createState() => _LaunchSplashState();
}

class _LaunchSplashState extends State<LaunchSplash>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker((_) => setState(() {}));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animate =
        LaunchSplash.enabled && !MediaQuery.disableAnimationsOf(context);
    if (animate && !_ticker.isActive) _ticker.start();
    if (!animate && _ticker.isActive) _ticker.stop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final animate = _ticker.isActive;
    final ms = animate ? LaunchSplash.clock.elapsedMilliseconds : 1 << 30;
    final t = (ms / LaunchSplash.intro.inMilliseconds).clamp(0.0, 1.0);
    // After the intro the mark breathes once every 2.4 s.
    final idle = math.max(0, ms - LaunchSplash.intro.inMilliseconds) / 2400;
    final breath = animate ? math.sin(idle * 2 * math.pi) : 0.0;
    final word = Curves.easeOutCubic.transform(_phase(t, 0.55, 1));

    return ColoredBox(
      color: colors.nightPage,
      // Above the app there is no Material yet: no debug text underline.
      child: DefaultTextStyle(
        style: const TextStyle(decoration: TextDecoration.none),
        child: Semantics(
          label: 'Linglossa wird gestartet',
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 180,
                  height: 180,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Ember glow, swelling with the breath.
                      Opacity(
                        opacity: _phase(t, 0.1, 0.6),
                        child: Container(
                          width: 104,
                          height: 104,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: colors.active.withValues(
                                  alpha: 0.30 + 0.08 * breath,
                                ),
                                blurRadius: 60 + 8 * breath,
                                spreadRadius: 6 + 4 * breath,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Transform.scale(
                        scale: 1 + 0.025 * breath,
                        child: CustomPaint(
                          size: const Size.square(104),
                          painter: _MarkPainter(t),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Opacity(
                  opacity: word,
                  child: Transform.translate(
                    offset: Offset(0, 10 * (1 - word)),
                    child: MediaQuery.withClampedTextScaling(
                      maxScaleFactor: 1.3,
                      child: Text(
                        'Linglossa',
                        style: AppType.editorial(
                          color: colors.textPrimary,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
                AnimatedOpacity(
                  opacity: widget.caption == null ? 0 : 1,
                  duration: const Duration(milliseconds: 300),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Text(
                      widget.caption ?? '',
                      textAlign: TextAlign.center,
                      style: AppType.chrome(
                        size: 13,
                        weight: FontWeight.w400,
                        color: colors.textMuted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 0 → 1 while [t] runs from [from] to [to].
double _phase(double t, double from, double to) =>
    ((t - from) / (to - from)).clamp(0.0, 1.0);

/// The Linglossa mark (same geometry as `LinglossaMark`), built in three
/// beats: the bubble pops with a small overshoot, the "L" draws itself,
/// the dot lands.
class _MarkPainter extends CustomPainter {
  const _MarkPainter(this.t);

  final double t;

  static const _orange = Color(0xFFF77F00);
  static const _white = Color(0xFFFFFFFF);

  @override
  void paint(Canvas canvas, Size size) {
    final bubble = _phase(t, 0, 0.42);
    if (bubble == 0) return;
    final s = size.width / 168;
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(s * (0.55 + 0.45 * Curves.easeOutBack.transform(bubble)));
    canvas.rotate(-0.14 * (1 - Curves.easeOutCubic.transform(bubble)));
    final orange = Paint()
      ..color = _orange.withValues(alpha: _phase(t, 0, 0.15));
    canvas.drawPath(
      Path()
        ..moveTo(-68, 50)
        ..lineTo(-20, 50)
        ..lineTo(-76, 96)
        ..close(),
      orange,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-84, -84, 168, 168),
        const Radius.circular(48),
      ),
      orange,
    );
    final stroke = Curves.easeInOutCubic.transform(_phase(t, 0.32, 0.72));
    if (stroke > 0) {
      final letter = Path()
        ..moveTo(-32, -44)
        ..lineTo(-32, 40)
        ..lineTo(32, 40);
      final metric = letter.computeMetrics().first;
      canvas.drawPath(
        metric.extractPath(0, metric.length * stroke),
        Paint()
          ..color = _white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 24
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
    final dot = _phase(t, 0.68, 0.92);
    if (dot > 0) {
      canvas.drawCircle(
        Offset(40, -36 - 18 * (1 - Curves.easeOutCubic.transform(dot))),
        13 * Curves.easeOutBack.transform(dot),
        Paint()..color = _white,
      );
    }
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.t != t;
}

/// Shows the splash until [ready] holds, at least for the intro and at most
/// [maxWait]; then the app builds underneath and the splash lifts (fade, the
/// mark grows a touch) and leaves the tree. [ready] itself watches what the
/// first screen needs, so that loads meanwhile; the app's own entrances and
/// Home's one-off moments start only once it can be seen.
///
/// When [ready] turns false again later (another learning language loads),
/// the splash fades back in over the app, which keeps its state, and lifts
/// once the new content has settled.
class LaunchCurtain extends ConsumerStatefulWidget {
  const LaunchCurtain({super.key, required this.ready, required this.child});

  /// Watches whatever the first screen needs; true once it can show.
  final bool Function(WidgetRef ref) ready;
  final Widget child;

  static const maxWait = Duration(seconds: 6);

  /// Safety net for a cover that came back: a language install takes about
  /// 7 s, so this only fires when something hangs.
  static const maxCover = Duration(seconds: 30);

  @override
  ConsumerState<LaunchCurtain> createState() => _LaunchCurtainState();
}

class _LaunchCurtainState extends ConsumerState<LaunchCurtain>
    with SingleTickerProviderStateMixin {
  late final _lift = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );
  bool _lifting = false, _gone = false;
  // Keeps the app's state when the splash comes back over it.
  final _app = GlobalKey();
  Timer? _coverLimit;

  /// A cover for a language switch shows a wall of words in that language
  /// (user request 31.10.2026) and stays until the words have landed.
  String? _coverLang;
  final _coverTime = Stopwatch();

  @override
  void initState() {
    super.initState();
    _lift.addStatusListener((status) {
      // Only a lift ends the cover; a returning cover sets the value itself.
      if (status == AnimationStatus.completed && _lifting && mounted) {
        _coverLimit?.cancel();
        _coverLimit = null;
        setState(() {
          _gone = true;
          _coverLang = null;
        });
      }
    });
    Future<void>.delayed(LaunchCurtain.maxWait, () {
      if (mounted) _startLift();
    });
  }

  void _startLift() {
    if (_lifting) return;
    final wait = _coverLang != null
        ? WordWall.settle.inMilliseconds + 450 - _coverTime.elapsedMilliseconds
        : LaunchSplash.intro.inMilliseconds -
              LaunchSplash.clock.elapsedMilliseconds;
    if (wait > 0) {
      // Let the mark finish building before it lifts.
      Future<void>.delayed(Duration(milliseconds: wait), () {
        if (mounted) _startLift();
      });
      return;
    }
    _lifting = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _coverLimit?.cancel();
      _coverLimit = null;
      setState(() {
        _gone = true;
        _coverLang = null;
      });
    } else {
      _lift.forward();
      setState(() {});
    }
  }

  /// Brings the splash back over the visible app: it fades in from the
  /// lifted state and stays until [LaunchCurtain.ready] holds again.
  void _cover() {
    if (!_gone) return;
    _coverLimit?.cancel();
    _coverLimit = Timer(LaunchCurtain.maxCover, () {
      if (mounted) _startLift();
    });
    final selection = ref.read(languageSelectionProvider);
    setState(() {
      _gone = false;
      _lifting = false;
      _coverLang = selection.switching ? selection.target : null;
    });
    _coverTime
      ..reset()
      ..start();
    if (MediaQuery.disableAnimationsOf(context)) {
      _lift.value = 0;
    } else if (_coverLang != null) {
      // The words build the cover themselves; no fade in.
      _lift.value = 0;
    } else {
      _lift.value = 1;
      _lift.reverse();
    }
  }

  @override
  void dispose() {
    _coverLimit?.cancel();
    _lift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = KeyedSubtree(key: _app, child: widget.child);
    final ready = widget.ready(ref);
    if (_gone) {
      if (!ready) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _cover();
        });
      }
      return app;
    }
    if (ready) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _startLift();
      });
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        // A returning cover keeps the app mounted underneath.
        if (_lifting || _coverLimit != null) app,
        IgnorePointer(
          ignoring: _lifting,
          child: AnimatedBuilder(
            animation: _lift,
            builder: (context, child) {
              final t = Curves.easeInCubic.transform(_lift.value);
              return Opacity(
                opacity: 1 - t,
                child: Transform.scale(scale: 1 + 0.06 * t, child: child),
              );
            },
            child: _coverLang == null
                ? const LaunchSplash()
                : WordWall(key: ValueKey(_coverLang), lang: _coverLang!),
          ),
        ),
      ],
    );
  }
}
