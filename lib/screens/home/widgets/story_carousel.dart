import 'package:flutter/cupertino.dart';

import '../../../models/home_models.dart';
import '../../../models/story_category.dart';
import '../../../theme/app_theme.dart';

/// Level first, genre last: at large Dynamic Type the genre truncates first.
String storyMetaLine(Story story) =>
    '${story.level} · ${story.readingMinutes} Min · ${story.topic}';

/// Spells out what [storyMetaLine] abbreviates.
String storySemanticsLabel(Story story) =>
    '${story.title}. ${story.topic}, ${story.readingMinutes} Minuten '
    'Lesezeit, Niveau ${story.level}';

/// Horizontal row of story covers. [progress] maps story ids to the reading
/// position (0–1); finished stories carry a check.
class StoryCarousel extends StatelessWidget {
  const StoryCarousel({
    super.key,
    required this.stories,
    required this.onOpen,
    this.progress = const {},
    this.finished = const {},
  });

  static const cardWidth = 150.0;
  static const cardHeight = 212.0;

  final List<Story> stories;
  final ValueChanged<Story> onOpen;
  final Map<String, double> progress;
  final Set<String> finished;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: cardHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: stories.length,
        itemBuilder: (context, i) => Padding(
          padding: EdgeInsets.only(right: i == stories.length - 1 ? 0 : 12),
          child: StoryCard(
            story: stories[i],
            progress: progress[stories[i].id],
            finished: finished.contains(stories[i].id),
            onTap: () => onOpen(stories[i]),
          ),
        ),
      ),
    );
  }
}

/// A closed, always-dark cover in the category colour with a placeholder
/// illustration (the icon) until real artwork exists. Text is fixed white,
/// so it reads in both motifs.
class StoryCard extends StatelessWidget {
  const StoryCard({
    super.key,
    required this.story,
    required this.onTap,
    this.progress,
    this.finished = false,
    this.width = StoryCarousel.cardWidth,
    this.height = StoryCarousel.cardHeight,
  });

  final Story story;
  final VoidCallback onTap;

  /// Reading position; shown as a bar when the story is started.
  final double? progress;
  final bool finished;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    const white = Color(0xFFFFFFFF);
    final category = StoryCategory.of(story.topic);
    final started = !finished && (progress ?? 0) >= 0.02;
    final percent = ((progress ?? 0) * 100).round();
    final radius = BorderRadius.circular(18);
    return MergeSemantics(
      child: CupertinoButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        pressedOpacity: 0.8,
        minimumSize: const Size(44, 44),
        child: Semantics(
          label:
              '${storySemanticsLabel(story)}'
              '${finished
                  ? ', gelesen'
                  : started
                  ? ', $percent Prozent gelesen'
                  : ''}',
          excludeSemantics: true,
          child: SizedBox(
            width: width,
            height: height,
            child: ClipRRect(
              borderRadius: radius,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (story.cover case final cover?)
                    Image(image: cover, fit: BoxFit.cover)
                  else
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.lerp(category.color, white, 0.12)!,
                            Color.lerp(
                              category.color,
                              const Color(0xFF000000),
                              0.35,
                            )!,
                          ],
                        ),
                      ),
                    ),
                  if (story.cover == null)
                    Positioned(
                      right: -18,
                      top: -10,
                      child: Icon(
                        category.icon,
                        size: width * 0.78,
                        color: white.withValues(alpha: 0.16),
                      ),
                    ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.35, 1],
                        colors: [Color(0x00000000), Color(0x99000000)],
                      ),
                    ),
                  ),
                  if (finished)
                    const Positioned(
                      top: 10,
                      right: 10,
                      child: _FinishedBadge(),
                    ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          story.title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.editorial(
                            color: white,
                            size: 17,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          started
                              ? '${story.level} · $percent %'
                              : '${story.level} · ${story.readingMinutes} Min',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.meta(
                            color: white.withValues(alpha: 0.82),
                          ),
                        ),
                        if (started) ...[
                          const SizedBox(height: 8),
                          ReadingBar(fraction: progress!, onDark: true),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FinishedBadge extends StatelessWidget {
  const _FinishedBadge();

  @override
  Widget build(BuildContext context) => Container(
    width: 26,
    height: 26,
    alignment: Alignment.center,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      color: Color(0xFFFFFFFF),
    ),
    child: Icon(
      CupertinoIcons.checkmark_alt,
      size: 16,
      color: context.appColors.progressWords,
    ),
  );
}

/// Thin rounded reading-progress bar (orange fill).
class ReadingBar extends StatelessWidget {
  const ReadingBar({
    super.key,
    required this.fraction,
    this.onDark = false,
    this.height = 4,
  });

  final double fraction;
  final bool onDark;
  final double height;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(99),
    child: SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: onDark
                ? const Color(0x40FFFFFF)
                : context.appColors.hairline,
          ),
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: fraction.clamp(0.03, 1.0),
            child: ColoredBox(color: context.appColors.active),
          ),
        ],
      ),
    ),
  );
}

/// Stand-in cover until stories and news ship with artwork: the topic set
/// as a faint serif masthead on a neutral tone.
class TypeCover extends StatelessWidget {
  const TypeCover({
    super.key,
    required this.topic,
    required this.tone,
    this.size = 52,
  });

  static const _tones = [
    Color(0xFF1A1D26),
    Color(0xFF20242F),
    Color(0xFF161922),
  ];

  final String topic;
  final int tone;

  /// Masthead size; the cover crops it, so it reads as texture.
  final double size;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _tones[tone % _tones.length],
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            left: size * 0.2,
            top: size * 0.58,
            child: Text(
              topic,
              maxLines: 1,
              softWrap: false,
              textScaler: TextScaler.noScaling,
              style: AppType.editorial(
                size: size,
                weight: FontWeight.w700,
                height: 1,
                letterSpacing: -size / 52,
                color: AppColors.textPrimary.withValues(alpha: 0.09),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
