import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/home_models.dart';
import '../models/story_category.dart';
import '../presentation/story_cover_art.dart';
import '../theme/app_theme.dart';

/// Shared art surface for story cards, ranked lists and continue-reading tiles.
/// The main image always fits in full, even on a wide tablet card. A darkened
/// crop of the same art fills the surrounding space without letterbox bars.
class StoryCover extends StatelessWidget {
  const StoryCover({
    super.key,
    required this.story,
    required this.width,
    required this.height,
    this.radius = 18,
    this.texture = true,
    this.finished = false,
  });

  final Story story;
  final double width, height, radius;
  final bool texture, finished;

  static final _manifests = Expando<Future<Set<String>>>();

  static Future<Set<String>> _assets(AssetBundle bundle) =>
      _manifests[bundle] ??= _loadAssets(bundle);

  static Future<Set<String>> _loadAssets(AssetBundle bundle) async {
    try {
      // Cached bundles return SynchronousFuture, whose catchError does not
      // forward a successful value. Await keeps cold and cached loads alike.
      final manifest = await AssetManifest.loadFromAssetBundle(bundle);
      return manifest.listAssets().toSet();
    } catch (_) {
      return <String>{};
    }
  }

  @override
  Widget build(BuildContext context) {
    final bundle = DefaultAssetBundle.of(context);
    final asset = storyCoverAssetKey(story.id, story.topic);
    final fallback = _fallback();
    return ExcludeSemantics(
      child: SizedBox(
        width: width,
        height: height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              fallback,
              if (story.cover case final image?)
                _art(image)
              else if (asset != null)
                FutureBuilder<Set<String>>(
                  future: _assets(bundle),
                  builder: (context, snapshot) =>
                      snapshot.data?.contains(asset) == true
                      ? _art(AssetImage(asset, bundle: bundle))
                      : const SizedBox.shrink(),
                ),
              if (texture)
                const DecoratedBox(
                  key: ValueKey('story-cover-title-scrim'),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0, 0.42, 1],
                      colors: [
                        Color(0x0D000000),
                        Color(0x2E000000),
                        Color(0xEB000000),
                      ],
                    ),
                  ),
                ),
              if (finished) const ColoredBox(color: Color(0x59000000)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _art(ImageProvider image) {
    Widget picture(BoxFit fit) => Image(
      image: image,
      fit: fit,
      alignment: Alignment.center,
      excludeFromSemantics: true,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, synchronous) {
        if (!synchronous && frame == null) return const SizedBox.shrink();
        if (fit != BoxFit.contain ||
            child is! RawImage ||
            child.image == null) {
          return child;
        }
        // Feather the actual image rectangle, not the larger card bounds.
        // Decoded dimensions also keep arbitrary caller-supplied covers correct.
        final pixels = child.image!;
        return LayoutBuilder(
          builder: (context, constraints) {
            final fitted = applyBoxFit(
              BoxFit.contain,
              Size(pixels.width.toDouble(), pixels.height.toDouble()),
              constraints.biggest,
            ).destination;
            Widget feather(Widget content, Alignment begin, Alignment end) =>
                ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (bounds) => LinearGradient(
                    begin: begin,
                    end: end,
                    stops: const [0, 0.16, 0.84, 1],
                    colors: const [
                      Colors.transparent,
                      Colors.white,
                      Colors.white,
                      Colors.transparent,
                    ],
                  ).createShader(bounds),
                  child: content,
                );
            return Center(
              child: SizedBox(
                key: const ValueKey('story-cover-contained-art'),
                width: fitted.width,
                height: fitted.height,
                child: feather(
                  feather(child, Alignment.topCenter, Alignment.bottomCenter),
                  Alignment.centerLeft,
                  Alignment.centerRight,
                ),
              ),
            );
          },
        );
      },
      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        ColorFiltered(
          colorFilter: const ColorFilter.mode(
            Color(0x59000000),
            BlendMode.srcATop,
          ),
          child: picture(BoxFit.cover),
        ),
        picture(BoxFit.contain),
      ],
    );
  }

  Widget _fallback() {
    const white = Colors.white;
    final category = StoryCategory.of(story.topic);
    final word = story.title.split(RegExp(r'\s+')).first;
    final mast = math.min(height * 0.9, 150.0);
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(category.color, white, 0.14)!,
                Color.lerp(category.color, Colors.black, 0.38)!,
              ],
            ),
          ),
        ),
        if (texture)
          Positioned(
            left: -mast * 0.06,
            top: -mast * 0.12,
            child: Text(
              word,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.visible,
              textScaler: TextScaler.noScaling,
              style: AppType.editorial(
                size: mast,
                weight: FontWeight.w700,
                height: 1,
                letterSpacing: -mast / 30,
                color: white.withValues(alpha: 0.11),
              ),
            ),
          ),
        Align(
          alignment: texture ? Alignment.topLeft : Alignment.center,
          child: Padding(
            padding: EdgeInsets.all(texture ? 12 : 0),
            child: Icon(
              category.icon,
              size: texture ? 18 : 24,
              color: white.withValues(alpha: texture ? 0.75 : 0.85),
            ),
          ),
        ),
      ],
    );
  }
}
