import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/home_models.dart';
import '../../presentation/content_unavailable_view.dart';
import '../../presentation/providers/database_providers.dart';
import '../../presentation/providers/deck_providers.dart';
import '../../domain/language_profile.dart';
import '../../presentation/providers/learning_providers.dart';
import '../../presentation/providers/reading_providers.dart';
import '../../presentation/providers/story_learning_providers.dart';
import '../../presentation/providers/streak_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/more_button.dart';
import '../../widgets/section_heading.dart';
import 'widgets/goal_panel.dart';
import 'widgets/home_deck_row.dart';
import 'widgets/home_header.dart';
import 'widgets/progress_tiles.dart';
import 'widgets/story_carousel.dart';
import 'widgets/streak_calendar.dart';
import 'widgets/streak_strip.dart';

/// Home (docs/redesign/home-01-recherche.html, DESIGN.md): daily goal and
/// streak in the header, the week box, progress tiles, stories and at most
/// three active decks. Practice starts from the Play button.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({
    super.key,
    required this.onOpenStory,
    required this.onBrowseStories,
    required this.onOpenDeck,
    required this.onBrowseDecks,
    required this.onSetGoal,
    required this.onSettings,
  });

  static const _gutter = EdgeInsets.symmetric(horizontal: 20);

  final ValueChanged<Story> onOpenStory;
  final VoidCallback onBrowseStories;
  final ValueChanged<Deck> onOpenDeck;
  final VoidCallback onBrowseDecks;
  final ValueChanged<int> onSetGoal;
  final VoidCallback onSettings;

  Widget _calendar(WidgetRef ref) {
    final streak = ref.read(streakProvider).value;
    if (streak == null) return const SizedBox(height: 120);
    return StreakCalendar(
      summary: streak,
      today: ref.read(learningNowProvider),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang =
        ref.watch(selectedContentLanguageProvider).asData?.value ?? 'en';
    final language = ContentLanguageProfile.forLanguage(lang)!;
    final streak = watchContentStable(ref, streakProvider);
    final decks = watchContentStable(ref, decksProvider);
    final breakdown = watchContentStable(ref, vocabBreakdownProvider);
    final progress = watchContentStable(ref, learningProgressProvider);

    void retry() {
      retryDatabases(ref);
      ref.invalidate(vocabBreakdownProvider);
      ref.invalidate(decksProvider);
      ref.invalidate(learningProgressProvider);
      ref.invalidate(streakProvider);
    }

    return SafeArea(
      bottom: false,
      child: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.only(top: 8, bottom: 40),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 8),
            child: HomeHeader(
              flag: language.flag,
              languageName: language.displayName,
              goal: progress.value?.goal,
              streak: streak.value?.current,
              goalPopover: (_) => GoalPanel(onSetGoal: onSetGoal),
              streakPopover: (_) => _calendar(ref),
              onSettings: onSettings,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: _gutter,
            child: streak.when(
              skipLoadingOnReload: false,
              skipLoadingOnRefresh: false,
              skipError: false,
              data: (s) => StreakStrip(
                summary: s,
                wordOfWeek: ref.watch(wordOfWeekProvider).value,
                calendar: (_) => _calendar(ref),
              ),
              loading: () => const _Loading(height: 120),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: _gutter,
            child: breakdown.when(
              skipLoadingOnReload: false,
              skipLoadingOnRefresh: false,
              skipError: false,
              data: (b) => ProgressTiles(
                breakdown: b,
                lexical: ref.watch(lexicalBreakdownProvider).value,
              ),
              loading: () => const _Loading(height: 100),
              error: (error, _) =>
                  ContentUnavailableView(error: error, onRetry: retry),
            ),
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 8),
            child: SectionHeading(
              title: 'Stories',
              trailing: MoreButton(
                label: 'Mehr entdecken',
                onPressed: onBrowseStories,
              ),
            ),
          ),
          const SizedBox(height: 10),
          ref
              .watch(libraryStoriesProvider)
              .when(
                skipLoadingOnReload: false,
                skipLoadingOnRefresh: false,
                skipError: false,
                data: (stories) {
                  if (stories.isEmpty) {
                    return Padding(
                      padding: _gutter,
                      child: Text(
                        'Für ${language.displayName} sind noch keine Stories verfügbar.',
                        style: AppType.chrome(
                          color: context.appColors.textMuted,
                        ),
                      ),
                    );
                  }
                  final reading = ref.watch(readingProgressProvider);
                  final all = stories;
                  // Started stories first; only real content from the active pack.
                  final started = [
                    for (final s in all)
                      if (reading[s.id]?.inProgress ?? false) s,
                  ];
                  final shown = [
                    ...started,
                    ...all.where((s) => !started.contains(s)),
                  ].take(6).toList();
                  return StoryCarousel(
                    stories: shown,
                    onOpen: onOpenStory,
                    progress: {
                      for (final MapEntry(:key, :value) in reading.entries)
                        if (value.inProgress) key: value.fraction,
                    },
                    finished: {
                      for (final MapEntry(:key, :value) in reading.entries)
                        if (value.finished) key,
                    },
                  );
                },
                loading: () => const _Loading(height: 200),
                error: (_, _) => CupertinoButton(
                  onPressed: () => ref.invalidate(storySummariesProvider),
                  child: const Text(
                    'Stories nicht verfügbar · Erneut versuchen',
                  ),
                ),
              ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 8),
            child: SectionHeading(
              title: 'Aktive Stapel',
              trailing: MoreButton(
                label: 'Mehr ansehen',
                onPressed: onBrowseDecks,
              ),
            ),
          ),
          const SizedBox(height: 10),
          ...decks.when(
            skipLoadingOnReload: false,
            skipLoadingOnRefresh: false,
            skipError: false,
            loading: () => [const _Loading(height: 72)],
            error: (error, _) => [
              Padding(
                padding: _gutter,
                child: ContentUnavailableView(error: error, onRetry: retry),
              ),
            ],
            data: (all) {
              final active = all.where((d) => d.isActive).take(3).toList();
              if (active.isEmpty) {
                return [
                  Padding(
                    padding: _gutter,
                    child: Text(
                      'Noch kein Stapel aktiv. Unter „Mehr ansehen“ findest '
                      'du alle Stapel.',
                      style: AppType.chrome(color: context.appColors.textMuted),
                    ),
                  ),
                ];
              }
              return [
                for (final (i, deck) in active.indexed)
                  Padding(
                    padding: _gutter.copyWith(top: i == 0 ? 0 : 10),
                    child: HomeDeckRow(
                      deck: deck,
                      onTap: () => onOpenDeck(deck),
                    ),
                  ),
              ];
            },
          ),
        ],
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: const Center(child: CupertinoActivityIndicator()),
  );
}
