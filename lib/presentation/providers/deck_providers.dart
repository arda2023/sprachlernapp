import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/srs_state.dart';
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
  final content = await ref.watch(contentRepositoryProvider.future);
  final user = await ref.watch(userRepositoryProvider.future);
  final summaries = await content.decks();
  final resolver = await ref.watch(practiceResolverProvider.future);
  final active = await user.activeDeckIds(summaries.map((d) => d.id));
  final result = <Deck>[];
  for (final deck in summaries) {
    final ids = await content.deckCardIds(deck.id);
    final states = await user.cardStates(ids);
    var viaStory = 0;
    for (final id in ids) {
      if (states.containsKey(id)) continue;
      final bound = resolver.bindingFor(resolver.cards[id]!);
      final local = resolver.states[bound];
      if (local != null) {
        states[id] = local;
        if (local.box >= 1 && local.isActive) viaStory++;
      }
    }
    final seen = states.values.where((s) => s.isActive && s.box >= 1);
    final recent = <(String, DateTime)>[];
    for (final state in seen) {
      final reviews = await user.reviewsFor(state.cardId);
      if (reviews.isNotEmpty) {
        recent.add((state.cardId, reviews.last.createdAt));
      }
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
        totalWords: ids.length,
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
    activeDeckCardIds: (await resolver.activePrimaryIds()).toSet(),
    cards: resolver.states,
    knownCardIds: resolver.knownIds,
    explicitStoryIds: resolver.additions.keys.toSet(),
    now: now,
  );
}, retry: (_, _) => null);

final deckActiveControllerProvider =
    AsyncNotifierProvider<DeckActiveController, void>(DeckActiveController.new);

class DeckActiveController extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<void> setActive(String id, bool active) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = await ref.read(userRepositoryProvider.future);
      await user.setDeckActive(id, active, now: ref.read(clockProvider)());
      ref.invalidate(decksProvider);
      ref.invalidate(vocabBreakdownProvider);
    });
  }
}
