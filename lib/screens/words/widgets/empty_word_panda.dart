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
  late final _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2113),
  );
  late final _bubbleIn = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(
      1733 / 2113,
      2033 / 2113,
      curve: Cubic(0.23, 1, 0.32, 1),
    ),
  );
  late final _textIn = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(1813 / 2113, 1, curve: Cubic(0.23, 1, 0.32, 1)),
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
    _textIn.dispose();
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
                      child: FadeTransition(
                        opacity: _bubbleIn,
                        child: ScaleTransition(
                          alignment: Alignment.bottomLeft,
                          scale: Tween(
                            begin: 0.94,
                            end: 1.0,
                          ).animate(_bubbleIn),
                          child: _HintBubble(_hint, textIn: _textIn),
                        ),
                      ),
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

class _HintBubble extends StatelessWidget {
  const _HintBubble(this.hint, {required this.textIn});

  final Animation<double> textIn;

  final String hint;

  @override
  Widget build(BuildContext context) {
    final color = context.appColors.popover;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 70,
          bottom: -12,
          child: Transform.rotate(
            angle: math.pi / 4,
            child: SizedBox.square(
              dimension: 26,
              child: ColoredBox(color: color),
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: FadeTransition(
              opacity: textIn,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, 0.08),
                  end: Offset.zero,
                ).animate(textIn),
                child: Text(
                  hint,
                  style: AppType.chrome(
                    color: const Color(0xFFFFFFFF),
                    size: 15,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
