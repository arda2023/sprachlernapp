import '../../domain/content.dart';
import '../../domain/learning_groups.dart';
import '../../domain/repositories.dart';
import '../../domain/story_learning.dart';
import '../../domain/srs_state.dart';

/// One projection over the two existing repositories; owns no database.
class PracticeItemResolver {
  PracticeItemResolver._(
    this.content,
    this.user,
    this.cards,
    this.locals,
    this.additions,
    this.bindings,
    this.states,
    this.contentError,
  );
  final ContentRepository? content;
  final UserRepository user;
  final Map<String, ContentCard> cards;
  final Map<String, PracticeItem> locals;
  final Map<String, DateTime> additions;
  final Map<String, String> bindings;
  final Map<String, UserCardState> states;
  final Object? contentError;
  static Future<PracticeItemResolver> load(
    UserRepository user,
    ContentRepository? content, {
    Object? contentError,
  }) async {
    final story = user is StoryLearningRepository
        ? user as StoryLearningRepository
        : null;
    final locals = {
      for (final i in await story?.localPracticeItems() ?? <PracticeItem>[])
        i.card.id: i,
    };
    final cards = attachLocalLearning(
      content == null
          ? <ContentCard>[]
          : await content.selectionCards(await content.allCardIds()),
      locals.values.map((i) => i.card),
    );
    return PracticeItemResolver._(
      content,
      user,
      cards,
      locals,
      await story?.explicitStoryAdditions() ?? {},
      await story?.identityBindings() ?? {},
      await user.allCardStates(),
      contentError,
    );
  }

  bool hasUnclassifiedBinding(ContentCard c) {
    final old = bindingFor(c, form: false) ?? (c.senseId == null ? null : LearningIdentity(c.lang, c.formNorm, c.senseId!).localId);
    return c.formFunction != null && old != null && old != c.id && states.containsKey(old) && cards[old]?.formFunction == null;
  }
  List<String> get notices => [
    for (final c in cards.values)
      if (hasUnclassifiedBinding(c))
        '${c.form}: Ein älterer Lernstand hat keine belegte Form. Er bleibt erhalten; eine automatische Zuordnung ist nicht möglich.',

    for (final s in states.values)
      if (!cards.containsKey(s.cardId))
        'Lernstand ${s.cardId}: Inhalt nicht verfügbar. Der gespeicherte Stand bleibt erhalten.',
    for (final c in cards.values)
      if (states.containsKey(c.id) &&
          bindingFor(c) != null &&
          bindingFor(c) != c.id &&
          states.containsKey(bindingFor(c)))
        '${c.form} (${c.translationDe ?? c.senseKey ?? c.id}): Zwei Lernstände für dieselbe Bedeutung vorhanden. Beide bleiben getrennt erhalten.',
  ];
  Set<String> get knownIds => cards.keys.toSet();
  String? bindingFor(ContentCard card, {bool? form}) => card.senseId == null
      ? null
      : bindings[LearningIdentity(card.lang, card.formNorm, card.senseId!,
          function: (form ?? card.formFunction != null) ? card.formFunction : null).key];
  List<String> eligiblePrimaries(Iterable<String> ids) =>
      LearningGroups(cards, states).project([
        for (final id in ids)
          if (cards.containsKey(id)) states.containsKey(id) ? id : bindingFor(cards[id]!, form: false) ?? bindingFor(cards[id]!, form: true) ?? id,
      ]);
  String? storyStateId(String lang, StoryToken token) {
    if (token.senseId == null) return null;
    final identity = LearningIdentity(lang, contentFormNorm(token.surface), token.senseId!, function: token.function);
    final bound = bindings[identity.key];
    if (bound != null && cards.containsKey(bound)) return bound;
    if (token.formTarget != null) return cards.containsKey(token.formTarget!.cardId) ? token.formTarget!.cardId : null;
    if (token.cardId != null && cards[token.cardId]?.introductionScope == 'ordinary') return token.cardId;
    final matches = cards.values.where((c) => c.lang == lang && c.formNorm == identity.formNorm && c.senseId == identity.semanticAnchor && c.formFunction == null).toList();
    return matches.length == 1 ? matches.single.id : null;
  }

  List<String> projectExisting(Iterable<String> ids) =>
      LearningGroups(cards, states).project(ids, exactForms: true);

  List<String> resolveTargets(Iterable<DeckPracticeTarget> targets) {
    final result = <String>[];
    for (final target in targets) {
      final card = cards[target.cardId];
      if (card == null) continue;
      if (!target.isForm) {
        result.addAll(eligiblePrimaries([target.cardId]));
        continue;
      }
      if (hasUnclassifiedBinding(card)) {
        // Unknown old function: keep its reviews, never create a third copy.
        continue;
      }
      final bound = bindingFor(card, form: true);
      final exact = {card.id, if (bound != null && cards.containsKey(bound)) bound};
      final existing = exact.where(states.containsKey).toList();
      result.addAll(existing.isNotEmpty ? existing : [card.id]);
    }
    return result.toSet().toList();
  }

  Future<List<String>> deckPracticeIds(String deckId) async =>
      resolveTargets(await content!.deckPracticeTargets(deckId));

  Future<List<String>> activePrimaryIds() async {
    if (content == null) return [];
    final decks = await content!.decks();
    final active = await user.activeDeckIds(decks.map((d) => d.id));
    return resolveTargets([
      for (final d in decks)
        if (active.contains(d.id)) ...await content!.deckPracticeTargets(d.id),
    ]);
  }

  Future<List<PracticeItem>> practiceItems(List<String> ids) async {
    final remote = ids.where((id) => !locals.containsKey(id)).toList();
    if (remote.isNotEmpty && content == null) {
      throw contentError ?? StateError('Inhaltspaket fehlt');
    }
    final values = {
      ...locals,
      for (final i
          in remote.isEmpty
              ? <PracticeItem>[]
              : await content!.practiceItems(remote))
        i.card.id: i,
    };
    return [
      for (final id in ids)
        if (values.containsKey(id))
          values[id]!
        else
          throw StateError('Inhaltsdaten für $id fehlen'),
    ];
  }

  Future<CardSentence?> historicalSentence(
    String cardId,
    String sentenceId,
  ) async {
    if (user is StoryLearningRepository) {
      final local = await (user as StoryLearningRepository)
          .localHistoricalSentence(cardId, sentenceId);
      if (local != null) return local;
    }
    return content?.historicalSentence(cardId, sentenceId);
  }
}
