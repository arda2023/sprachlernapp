import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/content.dart';
import '../../domain/srs_state.dart';
import '../../domain/story_learning_diagnostics.dart';
import 'story_learning_providers.dart';

class StoryCollectionWord {
  const StoryCollectionWord(this.state, this.item);
  final UserCardState state;
  final PracticeItem? item;
  String get status => state.retired
      ? 'Zurückgestellt'
      : state.disabled
      ? 'Deaktiviert'
      : item == null
      ? 'Inhalt nicht verfügbar – Lernstand erhalten'
      : 'Gemeinsamer Lernstand';
}

/// Membership does not load sentences; entry tiles can use the cached resolver.
final storyCollectionIdsProvider = Provider<AsyncValue<List<String>>>(
  (ref) =>
      ref.watch(practiceResolverProvider).whenData((r) => r.storyCollectionIds),
);

/// Load current contexts once in a batch, never reviews or per-card pack lists.
final storyCollectionProvider = FutureProvider<List<StoryCollectionWord>>((
  ref,
) async {
  try {
    final resolver = await ref.watch(practiceResolverProvider.future);
    final ids = resolver.storyCollectionIds;
    final items = {
      for (final item in await resolver.practiceItems(
        ids.where(resolver.cards.containsKey).toList(),
      ))
        item.card.id: item,
    };
    return [
      for (final id in ids)
        StoryCollectionWord(resolver.states[id]!, items[id]),
    ];
  } catch (_) {
    throw const StoryLearningFailure(StoryLearningStep.collection);
  }
}, retry: (_, _) => null);
