import 'srs_state.dart';

/// Resolves the requested session size against today's completed targets.
({int limit, bool goalReached}) resolveSessionSize({
  required int requestedSize,
  required DeckSessionKind kind,
  required int dailyGoal,
  required int completedToday,
}) {
  final remaining = (dailyGoal - completedToday).clamp(0, dailyGoal);
  final goalReached = remaining == 0;
  // The goal is a recommendation: once reached, a normal start is the
  // voluntary continuation. Cards done today are not due or new any
  // more; Revue/Vorab keep due dates, so such cards stay due.
  final limit = requestedSize > 0
      ? requestedSize
      : requestedSize < 0 ||
            remaining == 0 ||
            kind == DeckSessionKind.revue ||
            kind == DeckSessionKind.early
      ? dailyGoal
      : remaining;
  return (limit: limit, goalReached: goalReached);
}

/// Keeps the original map for unrestricted access and card order when filtered.
Map<String, UserCardState> filterSessionCardStates(
  Map<String, UserCardState> allStates, {
  required Set<String>? freeIds,
}) => freeIds == null
    ? allStates
    : {
        for (final entry in allStates.entries)
          if (freeIds.contains(entry.key)) entry.key: entry.value,
      };

/// Preserves deck/card order and adds the story source only for Premium.
({
  List<NewWordSource> deckSources,
  List<String> sourceOrder,
  Map<String, DateTime> storyAdditions,
})
filterMixedSessionSources({
  required bool premium,
  required Set<String>? freeIds,
  required bool Function(String deckId) isFreeDeck,
  required List<NewWordSource> activeSources,
  required List<String> sourceOrder,
  required Map<String, DateTime> storyAdditions,
}) => (
  deckSources: freeIds == null
      ? activeSources
      : [
          for (final source in activeSources)
            if (isFreeDeck(source.id))
              NewWordSource(
                source.id,
                source.cardIds.where(freeIds.contains).toList(),
              ),
        ],
  sourceOrder: [
    for (final id in sourceOrder)
      if (premium || isFreeDeck(id)) id,
    if (premium) storySourceId,
  ],
  storyAdditions: premium ? storyAdditions : const {},
);
