import 'package:flutter/cupertino.dart';

import '../../../models/home_models.dart';
import '../../../theme/app_theme.dart';

class StoryCarousel extends StatelessWidget {
  const StoryCarousel({super.key, required this.stories, required this.onOpen});

  static const cardWidth = 140.0;
  static const cardHeight = 200.0;

  final List<Story> stories;
  final ValueChanged<Story> onOpen;

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
            tone: i,
            onTap: () => onOpen(stories[i]),
          ),
        ),
      ),
    );
  }
}

class StoryCard extends StatelessWidget {
  const StoryCard({
    super.key,
    required this.story,
    required this.onTap,
    this.tone = 0,
  });

  final Story story;
  final VoidCallback onTap;

  /// Picks a neutral cover tone when the story has no cover image.
  final int tone;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);
    return MergeSemantics(
      child: CupertinoButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        pressedOpacity: 0.7,
        minimumSize: const Size(44, 44),
        child: Semantics(
          label: '${story.title}, Schwierigkeit ${story.difficulty} von 3',
          excludeSemantics: true,
          child: Container(
            width: StoryCarousel.cardWidth,
            height: StoryCarousel.cardHeight,
            foregroundDecoration: BoxDecoration(
              border: Border.all(color: AppColors.hairline),
              borderRadius: radius,
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (story.cover case final cover?)
                    Image(image: cover, fit: BoxFit.cover)
                  else
                    _TypeCover(topic: story.topic, tone: tone),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.3, 1],
                        colors: [Color(0x000D0F14), Color(0xF00D0F14)],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: DifficultyBolts(level: story.difficulty),
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: Text(
                      story.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.editorial(size: 17, height: 1.2),
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

/// Stand-in cover until stories ship with artwork: the topic set as a
/// faint serif masthead on a neutral tone.
class _TypeCover extends StatelessWidget {
  const _TypeCover({required this.topic, required this.tone});

  static const _tones = [
    Color(0xFF1A1D26),
    Color(0xFF20242F),
    Color(0xFF161922),
  ];

  final String topic;
  final int tone;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _tones[tone % _tones.length],
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            left: 10,
            top: 30,
            child: Text(
              topic,
              maxLines: 1,
              softWrap: false,
              textScaler: TextScaler.noScaling,
              style: AppType.editorial(
                size: 52,
                weight: FontWeight.w700,
                height: 1,
                letterSpacing: -1,
                color: AppColors.textPrimary.withValues(alpha: 0.09),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DifficultyBolts extends StatelessWidget {
  const DifficultyBolts({super.key, required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.nightPage.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= 3; i++)
            Icon(
              CupertinoIcons.bolt_fill,
              size: 12,
              color: i <= level ? AppColors.textPrimary : AppColors.iconOff,
            ),
        ],
      ),
    );
  }
}
