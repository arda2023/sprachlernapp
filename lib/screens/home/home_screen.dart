import 'package:flutter/cupertino.dart';

import '../../models/home_models.dart';
import '../../models/sample_content.dart';
import '../../theme/app_theme.dart';
import '../../widgets/section_heading.dart';
import 'widgets/daily_goal.dart';
import 'widgets/deck_tile.dart';
import 'widgets/home_header.dart';
import 'widgets/story_carousel.dart';
import 'widgets/vocab_progress.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onOpenStory,
    required this.onBrowseStories,
  });

  static const _gutter = EdgeInsets.symmetric(horizontal: 20);

  final ValueChanged<Story> onOpenStory;
  final VoidCallback onBrowseStories;

  // TODO: route to deck screens once they exist.
  void _notYetRouted() {}

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.only(top: 8, bottom: 32),
        children: [
          const Padding(
            padding: _gutter,
            child: HomeHeader(levelLabel: 'Englisch A2', streakDays: 14),
          ),
          const SizedBox(height: 28),
          const Padding(
            padding: _gutter,
            child: DailyGoalLine(goal: sampleGoal),
          ),
          const SizedBox(height: 28),
          const Padding(
            padding: _gutter,
            child: VocabProgress(breakdown: sampleBreakdown),
          ),
          const SizedBox(height: 44),
          const Padding(
            padding: _gutter,
            child: SectionHeading(title: 'Aktive Stapel'),
          ),
          const SizedBox(height: 14),
          for (final (i, deck) in sampleDecks.indexed)
            Padding(
              padding: _gutter.copyWith(top: i == 0 ? 0 : 12),
              child: DeckTile(deck: deck, onTap: _notYetRouted),
            ),
          const SizedBox(height: 44),
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 8),
            child: SectionHeading(
              title: 'Stories',
              trailing: CupertinoButton(
                onPressed: onBrowseStories,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(44, 44),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Mehr entdecken',
                      style: AppType.chrome(size: 15, weight: FontWeight.w600),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      CupertinoIcons.chevron_right,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          StoryCarousel(
            stories: sampleStories.take(5).toList(),
            onOpen: onOpenStory,
          ),
        ],
      ),
    );
  }
}
