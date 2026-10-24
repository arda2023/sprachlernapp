import 'package:flutter/cupertino.dart';
import 'package:rive/rive.dart' as rive;

import '../../../theme/app_theme.dart';

/// The artboards in `assets/rive/onboarding.riv`
/// (source: `tool/rive/onboarding/build_scene.py`).
enum OnboardingArtboard {
  logo('Logo', 1),
  welcome('Welcome', 400 / 320),
  goal('Goal', 1);

  const OnboardingArtboard(this.name, this.aspectRatio);

  final String name;
  final double aspectRatio;
}

/// Plays one onboarding artboard (intro, then its idle loop). Falls back to
/// a still drawn in Flutter while Rive is unavailable (widget tests, a
/// failed native init) or when the system asks for reduced motion.
class OnboardingArt extends StatefulWidget {
  const OnboardingArt(this.artboard, {super.key, required this.height});

  final OnboardingArtboard artboard;
  final double height;

  static const asset = 'assets/rive/onboarding.riv';

  /// Set by `main` once `RiveNative.init()` succeeded.
  static bool riveReady = false;

  @override
  State<OnboardingArt> createState() => _OnboardingArtState();
}

class _OnboardingArtState extends State<OnboardingArt> {
  rive.FileLoader? _loader;

  rive.FileLoader get _fileLoader => _loader ??= rive.FileLoader.fromAsset(
    OnboardingArt.asset,
    riveFactory: rive.Factory.rive,
  );

  @override
  void dispose() {
    _loader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = Size(
      widget.height * widget.artboard.aspectRatio,
      widget.height,
    );
    final still = _Still(artboard: widget.artboard, size: size);
    final animate =
        OnboardingArt.riveReady && !MediaQuery.disableAnimationsOf(context);
    return ExcludeSemantics(
      child: SizedBox.fromSize(
        size: size,
        child: !animate
            ? still
            : rive.RiveWidgetBuilder(
                fileLoader: _fileLoader,
                artboardSelector: rive.ArtboardSelector.byName(
                  widget.artboard.name,
                ),
                builder: (context, state) => switch (state) {
                  rive.RiveLoaded() => rive.RiveWidget(
                    controller: state.controller,
                    fit: rive.Fit.contain,
                  ),
                  rive.RiveFailed() => still,
                  _ => const SizedBox.shrink(),
                },
              ),
      ),
    );
  }
}

/// The resting frame of each artboard, drawn with Flutter widgets.
class _Still extends StatelessWidget {
  const _Still({required this.artboard, required this.size});

  final OnboardingArtboard artboard;
  final Size size;

  @override
  Widget build(BuildContext context) => switch (artboard) {
    OnboardingArtboard.logo => Center(
      child: LingvistMark(size: size.height * 0.7),
    ),
    OnboardingArtboard.welcome => Center(
      child: Icon(
        CupertinoIcons.book,
        size: size.height * 0.5,
        color: context.appColors.active,
      ),
    ),
    OnboardingArtboard.goal => Center(
      child: Icon(
        CupertinoIcons.flame_fill,
        size: size.height * 0.45,
        color: context.appColors.active,
      ),
    ),
  };
}

/// The Lingvist mark without animation: an orange speech bubble with a
/// white "L" and an accent dot. Same geometry as the Rive "Logo" artboard.
class LingvistMark extends StatelessWidget {
  const LingvistMark({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _MarkPainter());
}

class _MarkPainter extends CustomPainter {
  static const _orange = Color(0xFFF77F00);
  static const _white = Color(0xFFFFFFFF);

  @override
  void paint(Canvas canvas, Size size) {
    // The artboard's mark is 168 units wide; scale it to the canvas.
    final s = size.width / 168;
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(s);
    final orange = Paint()..color = _orange;
    final tail = Path()
      ..moveTo(-68, 50)
      ..lineTo(-20, 50)
      ..lineTo(-76, 96)
      ..close();
    canvas.drawPath(tail, orange);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-84, -84, 168, 168),
        const Radius.circular(48),
      ),
      orange,
    );
    final letter = Path()
      ..moveTo(-32, -44)
      ..lineTo(-32, 40)
      ..lineTo(32, 40);
    canvas.drawPath(
      letter,
      Paint()
        ..color = _white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 24
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(const Offset(40, -36), 13, Paint()..color = _white);
  }

  @override
  bool shouldRepaint(_MarkPainter oldDelegate) => false;
}
