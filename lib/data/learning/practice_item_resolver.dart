import '../../domain/content.dart';
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
    final cards = {
      for (final c
          in content == null
              ? <ContentCard>[]
              : await content.selectionCards(await content.allCardIds()))
        c.id: c,
      for (final i in locals.values) i.card.id: i.card,
    };
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

  List<String> get notices => [
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
  String? bindingFor(ContentCard card) => card.senseId == null
      ? null
      : bindings[LearningIdentity(card.lang, card.formNorm, card.senseId!).key];
  List<String> eligiblePrimaries(Iterable<String> ids) => [
    for (final id in ids)
      if (states.containsKey(id) ||
          bindingFor(cards[id]!) == null ||
          bindingFor(cards[id]!) == id)
        id,
  ];
  Future<List<String>> activePrimaryIds() async {
    if (content == null) return [];
    final decks = await content!.decks();
    final active = await user.activeDeckIds(decks.map((d) => d.id));
    return eligiblePrimaries([
      for (final d in decks)
        if (active.contains(d.id)) ...await content!.deckCardIds(d.id),
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
