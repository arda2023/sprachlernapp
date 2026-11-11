import '../../domain/content.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/srs_state.dart';
import '../../domain/review_activity.dart';
import '../../models/home_models.dart';
import '../deck_visuals.dart';
import 'database_providers.dart';
import 'premium_access_provider.dart';
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

/// Short deck names without "&" (user decision 29.10.2026). The packs keep
/// their titles; slugs are the same in every language, so one table covers
/// all of them. Unknown slugs show the pack title.
String deckDisplayName(String slug, String titleDe) => switch (slug) {
  'alltag-zuhause' => 'Zuhause',
  'alltagssprache-redewendungen' => 'Redewendungen',
  'arbeit-bildung' => 'Beruf',
  'menschen-beziehungen' => 'Beziehungen',
  'koerper-gesundheit' => 'Gesundheit',
  'essen-trinken' => 'Essen',
  'natur-umwelt' => 'Natur',
  'business-email' => 'Business',
  'irregular_verbs_base' => 'Unregelmäßige Verben',
  'irregular_verbs_past' => 'Unregelmäßiges Präteritum',
  'irregular_verbs_participle' => 'Unregelmäßige Partizipien',
  _ => titleDe,
};

/// Bolts per deck. The packs' own band is "mittel" almost everywhere (empty
/// in English), so it cannot tell decks apart. The level comes from what the
/// decks contain, checked against all five packs (29.10.2026):
/// - 1: core function words, house and household, base forms of common verbs.
/// - 2: topic vocabulary around A2–B1 (travel, work and school, body and
///   health, people and feelings, food, nature) and irregular past forms.
/// - 3: idioms, phrasal verbs and business language, mostly multiword
///   (up to 100 % of a deck) and B2 level.
/// Unknown slugs fall back to the pack's band.
DeckDifficulty deckDifficulty(String slug, String? cefrBand) => switch (slug) {
  'allgemeine-sprache' ||
  'alltag-zuhause' ||
  'irregular_verbs_base' => DeckDifficulty.beginner,
  'reisen' ||
  'arbeit-bildung' ||
  'koerper-gesundheit' ||
  'menschen-beziehungen' ||
  'essen-trinken' ||
  'natur-umwelt' ||
  'irregular_verbs_past' ||
  'irregular_verbs_participle' => DeckDifficulty.intermediate,
  'alltagssprache-redewendungen' ||
  'verbalphrasen' ||
  'business-email' => DeckDifficulty.advanced,
  _ => switch (cefrBand) {
    'mittel' => DeckDifficulty.intermediate,
    'fortgeschritten' => DeckDifficulty.advanced,
    _ => DeckDifficulty.beginner,
  },
};

final decksProvider = FutureProvider<List<Deck>>((ref) async {
  ref.watch(userChangesProvider);
  final user = await ref.watch(userRepositoryProvider.future);
  final resolver = await ref.watch(practiceResolverProvider.future);
  if (resolver.content == null && resolver.generatedDeckId == null) {
    throw resolver.contentError ?? StateError('Inhaltspaket fehlt');
  }
  final summaries = [
    ...(resolver.catalog?.decks ??
        await resolver.content?.decks() ??
        <DeckSummary>[]),
    if (resolver.generatedDeckId case final id?)
      DeckSummary(
        id: id,
        slug: 'generated-vocabulary',
        titleDe: 'Generierte Vokabeln',
        descriptionDe: 'Deine Themen, mit festen Beispielsätzen',
        cardCount: resolver.generatedPracticeIds.length,
      ),
  ];
  final active = await user.activeDeckIds(summaries.map((d) => d.id));
  final lastReviews = await user.lastReviewTimes();
  final result = <Deck>[];
  for (final deck in summaries) {
    final ids = await resolver.deckPracticeIds(deck.id);
    final states = {
      for (final id in ids)
        if (resolver.states.containsKey(id)) id: resolver.states[id]!,
    };
    final viaStory = states.values
        .where(
          (s) =>
              s.isActive &&
              s.box >= 1 &&
              ((s.localOnly &&
                      !resolver.generatedAdditions.containsKey(s.cardId)) ||
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
    // Home only displays card metadata already resolved for this language/pack.
    // Session start still loads and validates its full sentences and tokens.
    final words = [for (final r in recent.take(5)) resolver.cards[r.$1]!];
    result.add(
      Deck(
        id: deck.id,
        name: deckDisplayName(deck.slug, deck.titleDe),
        description:
            '${deck.descriptionDe ?? ''}${viaStory > 0 ? ' · $viaStory über Story gelernt' : ''}',
        icon: deckTopicIcon(deck.slug),
        difficulty: deckDifficulty(deck.slug, deck.cefrBand),
        totalWords: ids
            .where((id) => resolver.states[id]?.isActive ?? true)
            .length,
        seenWords: seen.length,
        masteredWords: seen.where((s) => s.box == 5).length,
        isActive: active.contains(deck.id),
        recentWords: [
          for (final item in words)
            SeenWord(word: item.form, translation: item.translationDe ?? ''),
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
    hiddenIds: await resolver.deactivatedDeckIds(),
  );
}, retry: (_, _) => null);

final lexicalBreakdownProvider = FutureProvider<LexicalBreakdown>((ref) async {
  ref.watch(userChangesProvider);
  final resolver = await ref.watch(practiceResolverProvider.future);
  final ids = eligiblePracticeIds(
    activeDeckCardIds: (await resolver.activePrimaryIds()).toSet(),
    states: resolver.states,
    contentCards: resolver.cards,
    knownCardIds: resolver.knownIds,
    explicitStoryIds: resolver.additions.keys.toSet(),
    targetsResolved: true,
    hiddenIds: await resolver.deactivatedDeckIds(),
  );
  return deriveLexicalBreakdown(ids, resolver.cards, resolver.states);
}, retry: (_, _) => null);

final deckActiveControllerProvider =
    NotifierProvider<DeckActiveController, DeckActivationState>(
      DeckActiveController.new,
    );

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
  DeckActivationState build() {
    ref.watch(selectedContentLanguageProvider);
    _tails.clear();
    _versions.clear();
    _persisted.clear();
    return const DeckActivationState();
  }

  Future<void> setActive(String id, bool active) {
    if (active &&
        !isFreeDeckId(id) &&
        !ref.read(premiumContentAccessProvider)) {
      state = DeckActivationState(
        values: state.values,
        errors: {
          ...state.errors,
          id: StateError('Dieser Stapel benötigt Premium.'),
        },
      );
      return Future<void>.value();
    }
    final release = contentTransitionGate.acquire();
    final version = (_versions[id] ?? 0) + 1;
    _versions[id] = version;
    state = DeckActivationState(
      values: {...state.values, id: active},
      errors: {...state.errors}..remove(id),
    );
    final previous = _tails[id] ?? Future<void>.value();
    final operation = previous.then((_) async {
      try {
        final user = await ref.read(userRepositoryProvider.future);
        _persisted[id] ??= (await user.activeDeckIds([id])).contains(id);
        if (active &&
            !isFreeDeckId(id) &&
            !ref.read(premiumContentAccessProvider)) {
          throw StateError('Dieser Stapel benötigt Premium.');
        }
        await user.setDeckActive(id, active, now: ref.read(clockProvider)());
        _persisted[id] = active;
      } catch (error) {
        if (ref.mounted && _versions[id] == version) {
          final values = {...state.values}..remove(id);
          if (_persisted.containsKey(id)) values[id] = _persisted[id]!;
          state = DeckActivationState(
            values: values,
            errors: {...state.errors, id: error},
          );
        }
      }
    });
    final guarded = operation.whenComplete(release);
    _tails[id] = guarded;
    return guarded;
  }
}
