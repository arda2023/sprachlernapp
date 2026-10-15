import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/srs_state.dart';
import '../../domain/review_activity.dart';
import '../../models/home_models.dart';
import 'database_providers.dart';
import 'learning_providers.dart';
import 'story_learning_providers.dart';

final userChangesProvider = StreamProvider<int>((ref) async* {
  final user = await ref.watch(userRepositoryProvider.future);
  var revision = 0;
  // Every event needs a distinct value: repeated AsyncData<void>(null) can
  // otherwise be coalesced and leave derived progress stale.
  await for (final _ in user.changes()) {
    yield ++revision;
  }
});

final decksProvider = FutureProvider<List<Deck>>((ref) async {
  ref.watch(userChangesProvider);
  final user = await ref.watch(userRepositoryProvider.future);
  final summaries = (await ref.watch(practiceCatalogProvider.future)).decks;
  final resolver = await ref.watch(practiceResolverProvider.future);
  final active = await user.activeDeckIds(summaries.map((d) => d.id));
  final lastReviews = await user.lastReviewTimes();
  final result = <Deck>[];
  for (final deck in summaries) {
    final ids = await resolver.deckPracticeIds(deck.id);
    final states = {for (final id in ids) if (resolver.states.containsKey(id)) id: resolver.states[id]!};
    final viaStory = states.values
        .where(
          (s) =>
              s.isActive &&
              s.box >= 1 &&
              (s.localOnly ||
                  s.origin == CardOrigin.story ||
                  resolver.additions.containsKey(s.cardId)),
        )
        .length;
    final seen = states.values.where((s) => s.isActive && s.box >= 1);
    final recent = <(String, DateTime)>[];
    for (final state in seen) {
      final at = lastReviews[state.cardId];
      if (at != null) recent.add((state.cardId, at));
    }
    recent.sort((a, b) => b.$2.compareTo(a.$2));
    final words = await resolver.practiceItems(
      recent.take(5).map((r) => r.$1).toList(),
    );
    result.add(
      Deck(
        id: deck.id,
        name: deck.titleDe,
        description:
            '${deck.descriptionDe ?? ''}${viaStory > 0 ? ' · $viaStory über Story gelernt' : ''}',
        icon: CupertinoIcons.square_stack,
        difficulty: switch (deck.cefrBand) {
          'mittel' => DeckDifficulty.intermediate,
          'fortgeschritten' => DeckDifficulty.advanced,
          _ => DeckDifficulty.beginner,
        },
        totalWords: ids
            .where((id) => resolver.states[id]?.isActive ?? true)
            .length,
        seenWords: seen.length,
        masteredWords: seen.where((s) => s.box == 5).length,
        isActive: active.contains(deck.id),
        recentWords: [
          for (final item in words)
            SeenWord(
              word: item.card.form,
              translation: item.card.translationDe ?? '',
            ),
        ],
      ),
    );
  }
  return result;
}, retry: (_, _) => null);

final vocabBreakdownProvider = FutureProvider<VocabBreakdown>((ref) async {
  ref.watch(userChangesProvider);
  final now = ref.watch(learningNowProvider);
  final resolver = await ref.watch(practiceResolverProvider.future);
  return deriveVocabBreakdown(
    targetsResolved: true,
    activeDeckCardIds: (await resolver.activePrimaryIds()).toSet(),
    cards: resolver.states,
    contentCards: resolver.cards,
    knownCardIds: resolver.knownIds,
    explicitStoryIds: resolver.additions.keys.toSet(),
    now: now,
  );
}, retry: (_, _) => null);

final lexicalBreakdownProvider = FutureProvider<LexicalBreakdown>((ref) async {
  ref.watch(userChangesProvider);
  final resolver = await ref.watch(practiceResolverProvider.future);
  final ids = eligiblePracticeIds(activeDeckCardIds: (await resolver.activePrimaryIds()).toSet(),
    states: resolver.states, contentCards: resolver.cards, knownCardIds: resolver.knownIds,
    explicitStoryIds: resolver.additions.keys.toSet(), targetsResolved: true);
  return deriveLexicalBreakdown(ids, resolver.cards, resolver.states);
}, retry: (_, _) => null);

final deckActiveControllerProvider =
    NotifierProvider<DeckActiveController, DeckActivationState>(DeckActiveController.new);

class DeckActivationState {
  const DeckActivationState({this.values = const {}, this.errors = const {}});
  final Map<String, bool> values;
  final Map<String, Object> errors;
}

class DeckActiveController extends Notifier<DeckActivationState> {
  final _tails = <String, Future<void>>{};
  final _versions = <String, int>{};
  final _persisted = <String, bool>{};
  @override
  DeckActivationState build() => const DeckActivationState();

  Future<void> setActive(String id, bool active) {
    final version = (_versions[id] ?? 0) + 1;
    _versions[id] = version;
    state = DeckActivationState(values: {...state.values, id: active},
      errors: {...state.errors}..remove(id));
    final previous = _tails[id] ?? Future<void>.value();
    final operation = previous.then((_) async {
      try {
        final user = await ref.read(userRepositoryProvider.future);
        _persisted[id] ??= (await user.activeDeckIds([id])).contains(id);
        await user.setDeckActive(id, active, now: ref.read(clockProvider)());
        _persisted[id] = active;
      } catch (error) {
        if (ref.mounted && _versions[id] == version) {
          final values = {...state.values}..remove(id);
          if (_persisted.containsKey(id)) values[id] = _persisted[id]!;
          state = DeckActivationState(values: values, errors: {...state.errors, id: error});
        }
      }
    });
    _tails[id] = operation;
    return operation;
  }
}
