import 'package:flutter/cupertino.dart';

import '../../models/deck_store.dart';
import '../../models/home_models.dart';
import '../../models/sample_content.dart';
import '../../theme/app_theme.dart';
import '../../widgets/section_heading.dart';
import 'widgets/deck_tile.dart';
import 'widgets/home_header.dart';
import 'widgets/story_carousel.dart';
import 'widgets/vocab_progress.dart';
import 'widgets/weekly_goal_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.decks,
    required this.goal,
    required this.week,
    required this.onOpenStory,
    required this.onBrowseStories,
    required this.onOpenDeck,
    required this.onBrowseDecks,
    required this.onEditGoal,
    required this.onProfile,
    required this.onSettings,
  });

  static const _gutter = EdgeInsets.symmetric(horizontal: 20);

  final DeckStore decks;
  final DailyGoal goal;
  final WeekProgress week;
  final ValueChanged<Story> onOpenStory;
  final VoidCallback onBrowseStories;
  final ValueChanged<Deck> onOpenDeck;
  final VoidCallback onBrowseDecks;
  final VoidCallback onEditGoal;
  final VoidCallback onProfile;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: decks,
        builder: (context, _) => ListView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.only(top: 8, bottom: 32),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 8),
              child: HomeHeader(
                flag: '🇬🇧',
                languageName: 'Englisch',
                onProfile: onProfile,
                onSettings: onSettings,
              ),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: _gutter,
              child: WeeklyGoalCard(
                week: week,
                goal: goal,
                onEditGoal: onEditGoal,
              ),
            ),
            const SizedBox(height: 28),
            const Padding(
              padding: _gutter,
              child: VocabProgress(breakdown: sampleBreakdown),
            ),
            const SizedBox(height: 44),
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 8),
              child: SectionHeading(
                title: 'Aktive Stapel',
                trailing: _MoreButton(
                  label: 'Mehr ansehen',
                  onPressed: onBrowseDecks,
                ),
              ),
            ),
            const SizedBox(height: 14),
            for (final (i, deck) in decks.homeDecks().indexed)
              Padding(
                padding: _gutter.copyWith(top: i == 0 ? 0 : 12),
                child: DeckTile(deck: deck, onTap: () => onOpenDeck(deck)),
              ),
            const SizedBox(height: 44),
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 8),
              child: SectionHeading(
                title: 'Stories',
                trailing: _MoreButton(
                  label: 'Mehr entdecken',
                  onPressed: onBrowseStories,
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
      ),
    );
  }
}

class _MoreButton extends StatelessWidget {
  const _MoreButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      onPressed: onPressed,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      minimumSize: const Size(44, 44),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: AppType.chrome(size: 15, weight: FontWeight.w600)),
          const SizedBox(width: 2),
          const Icon(
            CupertinoIcons.chevron_right,
            size: 14,
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}
