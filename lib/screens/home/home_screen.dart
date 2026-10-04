import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/providers/deck_providers.dart';
import '../../presentation/providers/learning_providers.dart';
import '../../presentation/providers/story_learning_providers.dart';
import '../../presentation/providers/database_providers.dart';
import '../../presentation/content_unavailable_view.dart';

import 'package:flutter/cupertino.dart';

import '../../models/home_models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/section_heading.dart';
import 'widgets/deck_tile.dart';
import 'widgets/home_header.dart';
import 'widgets/story_carousel.dart';
import 'widgets/vocab_progress.dart';
import 'widgets/weekly_goal_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({
    super.key,
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

  final DailyGoal? goal;
  final WeekProgress? week;
  final ValueChanged<Story> onOpenStory;
  final VoidCallback onBrowseStories;
  final ValueChanged<Deck> onOpenDeck;
  final VoidCallback onBrowseDecks;
  final VoidCallback onEditGoal;
  final VoidCallback onProfile;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      bottom: false,
      child: ListView(
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
            child: goal != null && week != null
                ? WeeklyGoalCard(
                    week: week!,
                    goal: goal!,
                    onEditGoal: onEditGoal,
                  )
                : ref
                      .watch(learningProgressProvider)
                      .when(
                        data: (p) => WeeklyGoalCard(
                          week: p.week,
                          goal: p.goal,
                          onEditGoal: onEditGoal,
                        ),
                        loading: () => const CupertinoActivityIndicator(),
                        error: (e, _) => ContentUnavailableView(
                          error: e,
                          onRetry: () =>
                              ref.invalidate(learningProgressProvider),
                        ),
                      ),
          ),
          const SizedBox(height: 28),
          Padding(
            padding: _gutter,
            child: ref
                .watch(vocabBreakdownProvider)
                .when(
                  loading: () => const CupertinoActivityIndicator(),
                  error: (error, _) => ContentUnavailableView(
                    error: error,
                    onRetry: () {
                      retryDatabases(ref);
                      ref.invalidate(vocabBreakdownProvider);
                      ref.invalidate(decksProvider);
                    },
                  ),
                  data: (value) => VocabProgress(breakdown: value),
                ),
          ),
          const SizedBox(height: 22),
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
          ...ref
              .watch(decksProvider)
              .when(
                loading: () => [const CupertinoActivityIndicator()],
                error: (error, _) => [
                  ContentUnavailableView(
                    error: error,
                    onRetry: () {
                      retryDatabases(ref);
                      ref.invalidate(decksProvider);
                    },
                  ),
                ],
                data: (decks) => [
                  for (final (i, deck)
                      in decks.where((d) => d.isActive).take(3).indexed)
                    Padding(
                      padding: _gutter.copyWith(top: i == 0 ? 0 : 12),
                      child: DeckTile(
                        deck: deck,
                        onTap: () => onOpenDeck(deck),
                      ),
                    ),
                  if (!decks.any((d) => d.isActive))
                    Padding(
                      padding: _gutter,
                      child: Text(
                        'Noch kein Stapel aktiv. Unter „Mehr ansehen“ findest du alle Stapel.',
                        style: AppType.chrome(
                          color: context.appColors.textMuted,
                        ),
                      ),
                    ),
                ],
              ),
          const SizedBox(height: 22),
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
          ref
              .watch(libraryStoriesProvider)
              .when(
                data: (stories) => stories.isEmpty
                    ? const Padding(
                        padding: _gutter,
                        child: Text('Noch keine Stories im Inhaltspaket.'),
                      )
                    : StoryCarousel(
                        stories: stories.take(5).toList(),
                        onOpen: onOpenStory,
                      ),
                loading: () => const CupertinoActivityIndicator(),
                error: (_, _) => CupertinoButton(
                  onPressed: () => ref.invalidate(storySummariesProvider),
                  child: const Text(
                    'Stories nicht verfügbar · Erneut versuchen',
                  ),
                ),
              ),
        ],
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
          Text(
            label,
            style: AppType.chrome(
              color: context.appColors.textPrimary,
              size: 15,
              weight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 2),
          Icon(
            CupertinoIcons.chevron_right,
            size: 14,
            color: context.appColors.textMuted,
          ),
        ],
      ),
    );
  }
}
