import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/content.dart';
import '../../../domain/editorial_stories.dart';
import '../../../domain/session_rules.dart';
import '../../../domain/srs_state.dart';
import '../../../models/home_models.dart';
import '../../../presentation/providers/learning_providers.dart';
import '../../../presentation/providers/practice_resolver_providers.dart';
import '../../../presentation/providers/premium_access_provider.dart';
import '../../../presentation/providers/reading_providers.dart';
import '../../../presentation/providers/story_learning_providers.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/press_scale.dart';
import '../../decks/deck_practice_screen.dart';

enum _SuggestedPractice { review, newWord }

final _suggestedPracticeProvider = FutureProvider<_SuggestedPractice?>((
  ref,
) async {
  final premium = ref.watch(premiumContentAccessProvider);
  final now = ref.watch(learningNowProvider);
  final resolver = await ref.watch(practiceResolverProvider.future);
  final hidden = await resolver.deactivatedDeckIds();
  final decks =
      resolver.catalog?.decks ??
      await resolver.content?.decks() ??
      <DeckSummary>[];
  final freeIds = premium
      ? null
      : {
          ...resolver.freeGeneratedIds,
          for (final deck in decks)
            if (isFreeDeckId(deck.id))
              ...await resolver.deckPracticeIds(deck.id),
        };
  final sources = await resolver.newWordSources();
  final filtered = filterMixedSessionSources(
    premium: premium,
    freeIds: freeIds,
    isFreeDeck: (id) =>
        isFreeDeckId(id) ||
        (id == resolver.generatedDeckId &&
            resolver.freeGeneratedIds.isNotEmpty),
    activeSources: sources.active,
    sourceOrder: sources.order,
    storyAdditions: resolver.additions,
  );
  final queue = buildMixedQueue(
    targetsResolved: true,
    activeDeckCardIds: const [],
    deckSources: filtered.deckSources,
    sourceOrder: filtered.sourceOrder,
    storyAdditions: filtered.storyAdditions,
    cards: resolver.cards,
    states: filterSessionCardStates(resolver.states, freeIds: freeIds),
    now: now,
    hiddenIds: hidden,
    size: 1,
  );
  if (queue.isEmpty) return null;
  return queue.first.source == null
      ? _SuggestedPractice.review
      : _SuggestedPractice.newWord;
}, retry: (_, _) => null);

({Story story, bool started})? dailyReadingSuggestion({
  required List<Story> stories,
  required Map<String, ReadingEntry> reading,
  required bool premium,
  required DateTime date,
}) {
  final eligible = stories
      .where((story) => premium || isFreeStoryId(story.id))
      .where((story) => reading[story.id]?.finished != true)
      .toList();
  if (eligible.isEmpty) return null;
  final started =
      eligible.where((story) => reading[story.id]?.inProgress == true).toList()
        ..sort(
          (a, b) =>
              reading[b.id]!.updatedAt.compareTo(reading[a.id]!.updatedAt),
        );
  if (started.isNotEmpty) return (story: started.first, started: true);

  eligible.sort((a, b) {
    final order = a.readingMinutes.compareTo(b.readingMinutes);
    return order == 0 ? a.id.compareTo(b.id) : order;
  });
  final day = DateTime.utc(
    date.year,
    date.month,
    date.day,
  ).difference(DateTime.utc(1970)).inDays;
  final options = eligible.take(3).toList();
  return (story: options[day % options.length], started: false);
}

class DailySuggestionCard extends ConsumerWidget {
  const DailySuggestionCard({super.key, required this.onOpenStory});

  final ValueChanged<Story> onOpenStory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(learningNowProvider);
    final progress = ref.watch(learningProgressProvider).asData?.value;
    final goalPending =
        progress != null && progress.goal.done < progress.goal.target;
    final practice = goalPending
        ? ref.watch(_suggestedPracticeProvider).asData?.value
        : null;
    void startPractice() => DeckPracticeScreen.open(
      context,
      deckId: '',
      mode: DeckPracticeMode.mixed,
    );
    if (practice == _SuggestedPractice.review) {
      return _SuggestionRow(
        action: 'Fällige Wörter wiederholen',
        icon: CupertinoIcons.arrow_clockwise,
        onPressed: startPractice,
      );
    }

    final stories = ref.watch(libraryStoriesProvider).asData?.value;
    final readingReady = ref.watch(readingProgressReadyProvider).hasValue;
    final suggested = stories != null && readingReady
        ? dailyReadingSuggestion(
            stories: stories,
            reading: ref.watch(readingProgressProvider),
            premium: ref.watch(premiumContentAccessProvider),
            date: now,
          )
        : null;
    if (suggested != null) {
      return _SuggestionRow(
        action: suggested.started ? 'Story weiterlesen' : 'Story lesen',
        detail: suggested.story.title,
        icon: CupertinoIcons.book,
        onPressed: () {
          if (isFreeStoryId(suggested.story.id) ||
              ref.read(premiumContentAccessProvider)) {
            onOpenStory(suggested.story);
          }
        },
      );
    }
    if (practice == _SuggestedPractice.newWord) {
      return _SuggestionRow(
        action: 'Neue Wörter üben',
        icon: CupertinoIcons.text_badge_plus,
        onPressed: startPractice,
      );
    }
    return const SizedBox.shrink();
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({
    required this.action,
    required this.icon,
    required this.onPressed,
    this.detail,
  });

  final String action;
  final IconData icon;
  final VoidCallback onPressed;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: PressScale(
        child: CupertinoButton(
          padding: const EdgeInsets.all(12),
          borderRadius: BorderRadius.circular(20),
          color: colors.raisedInk,
          onPressed: onPressed,
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.active,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: colors.onActive),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Heute für dich',
                      style: AppType.chrome(size: 13, color: colors.textMuted),
                    ),
                    Text(
                      action,
                      style: AppType.chrome(
                        size: 17,
                        weight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    if (detail case final title?)
                      Text(
                        title,
                        style: AppType.editorial(
                          size: 17,
                          color: colors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                CupertinoIcons.chevron_forward,
                size: 15,
                color: colors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
