import 'package:flutter/cupertino.dart';

import '../../models/home_models.dart';
import '../../models/story_models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/hairline_track.dart';
import '../../widgets/section_heading.dart';
import '../home/widgets/story_carousel.dart';

/// The Stories tab: an optional "Weiterlesen" tile, then one horizontal
/// carousel per topic, in the order topics first appear in [stories].
class StoryLibraryScreen extends StatelessWidget {
  const StoryLibraryScreen({
    super.key,
    required this.stories,
    required this.onOpenStory,
    this.continueReading,
  });

  static const _gutter = EdgeInsets.symmetric(horizontal: 20);

  final List<Story> stories;
  final ReadingProgress? continueReading;
  final ValueChanged<Story> onOpenStory;

  @override
  Widget build(BuildContext context) {
    final byTopic = <String, List<Story>>{};
    for (final story in stories) {
      (byTopic[story.topic] ??= []).add(story);
    }
    final resumed = switch (continueReading) {
      final progress? => (
        story: stories.where((s) => s.id == progress.storyId).firstOrNull,
        fraction: progress.fraction,
      ),
      null => null,
    };

    return SafeArea(
      bottom: false,
      child: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.only(top: 8, bottom: 32),
        children: [
          Padding(
            padding: _gutter,
            child: Semantics(
              header: true,
              child: Text('Stories', style: AppType.editorial(size: 32)),
            ),
          ),
          if (resumed case (story: final story?, :final fraction)) ...[
            const SizedBox(height: 28),
            const Padding(
              padding: _gutter,
              child: SectionHeading(title: 'Weiterlesen'),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: _gutter,
              child: ContinueReadingTile(
                story: story,
                fraction: fraction,
                onTap: () => onOpenStory(story),
              ),
            ),
          ],
          for (final MapEntry(key: topic, value: group) in byTopic.entries) ...[
            const SizedBox(height: 44),
            Padding(
              padding: _gutter,
              child: SectionHeading(
                title: topic,
                trailing: Text(
                  group.length == 1 ? '1 Story' : '${group.length} Stories',
                  style: AppType.meta(),
                ),
              ),
            ),
            const SizedBox(height: 10),
            StoryCarousel(stories: group, onOpen: onOpenStory),
          ],
        ],
      ),
    );
  }
}

/// Full-width tile for the story the learner left off in. Reading position
/// is not word status, so its track stays neutral.
class ContinueReadingTile extends StatelessWidget {
  const ContinueReadingTile({
    super.key,
    required this.story,
    required this.fraction,
    required this.onTap,
  });

  final Story story;
  final double fraction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final percent = (fraction * 100).round();
    return MergeSemantics(
      child: CupertinoButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        pressedOpacity: 0.7,
        minimumSize: const Size(44, 44),
        child: Semantics(
          label:
              'Weiterlesen: ${storySemanticsLabel(story)}, '
              '$percent Prozent gelesen',
          excludeSemantics: true,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.raisedInk,
              border: Border.all(color: AppColors.hairline),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(storyMetaLine(story), style: AppType.meta()),
                const SizedBox(height: 6),
                Text(
                  story.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.editorial(size: 17),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: HairlineTrack(fraction: fraction)),
                    const SizedBox(width: 12),
                    Text(
                      '$percent % gelesen',
                      style: AppType.meta().copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
