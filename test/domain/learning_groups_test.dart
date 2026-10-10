import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/domain/content.dart';
import 'package:sprachapp/domain/learning_groups.dart';
import 'package:sprachapp/domain/new_card_selection.dart';
import 'package:sprachapp/domain/srs_state.dart';

ContentCard target(
  String id, {
  String? group,
  String? head,
  String topic = 'travel',
  List<String> related = const [],
}) => ContentCard(
  id: id,
  lang: 'en',
  form: id,
  formNorm: id,
  lemmaId: id,
  lemma: id,
  pos: 'NOUN',
  senseId: 'sense-$id',
  learning: LearningTarget(
    groupId: group ?? id,
    primaryCardId: head ?? id,
    topic: topic,
    related: related,
    note: 'fixture',
  ),
);

void main() {
  final now = DateTime(2026, 10, 6);
  final cards = {
    for (final id in ['trip', 'travel', 'journey'])
      id: target(id, group: 'trip-group', head: 'trip'),
  };
  test('unseen canonical across decks; learned member suppresses canonical globally', () {
    expect(LearningGroups(cards, {}).project(['travel', 'journey', 'trip']), [
      'trip',
    ]);
    final states = {
      'journey': UserCardState(cardId: 'journey', box: 3, dueAt: now),
    };
    expect(LearningGroups(cards, states).project(['trip']), ['journey']);
    expect(
      buildDeckQueue(
        deckCardIds: ['trip'],
        cards: cards,
        states: states,
        kind: DeckSessionKind.learn,
        now: now,
      ).single.cardId,
      'journey',
    );
    final counts = deriveVocabBreakdown(
      activeDeckCardIds: cards.keys.toSet(),
      cards: states,
      knownCardIds: cards.keys.toSet(),
      contentCards: cards,
      now: now,
    );
    expect([counts.unseen, counts.due, counts.total], [0, 1, 1]);
  });
  test('all learned members retain reviews, revue and counters', () {
    final states = {
      for (final id in ['travel', 'journey'])
        id: UserCardState(cardId: id, box: 3, dueAt: now),
    };
    for (final kind in [DeckSessionKind.learn, DeckSessionKind.revue]) {
      expect(
        buildDeckQueue(
          deckCardIds: ['trip'],
          cards: cards,
          states: states,
          kind: kind,
          now: now,
        ).map((e) => e.cardId),
        unorderedEquals(['travel', 'journey']),
      );
    }
    expect(
      buildMixedQueue(
        activeDeckCardIds: ['trip'],
        cards: cards,
        states: states,
        now: now,
      ).map((e) => e.cardId),
      unorderedEquals(['travel', 'journey']),
    );
    final counts = deriveVocabBreakdown(
      activeDeckCardIds: {'trip'},
      cards: states,
      knownCardIds: cards.keys.toSet(),
      contentCards: cards,
      now: now,
    );
    expect([counts.unseen, counts.due], [0, 2]);
  });
  test('disabled member reserves group, no substitute introduction', () {
    final states = {
      'travel': UserCardState(
        cardId: 'travel',
        box: 0,
        dueAt: null,
        disabled: true,
      ),
    };
    expect(
      buildMixedQueue(
        activeDeckCardIds: cards.keys.toList(),
        cards: cards,
        states: states,
        now: now,
      ),
      isEmpty,
    );
  });
  test('local identity mapping needs exact language form AND sense', () {
    final local = ContentCard(
      id: 'u:old',
      lang: 'en',
      form: 'journey',
      formNorm: 'journey',
      lemmaId: 'journey',
      lemma: 'journey',
      pos: 'NOUN',
      senseId: 'sense-journey',
    );
    final unknown = ContentCard(
      id: 'u:other',
      lang: 'en',
      form: 'journey',
      formNorm: 'journey',
      lemmaId: 'journey',
      lemma: 'journey',
      pos: 'NOUN',
      senseId: 'other',
    );
    final merged = attachLocalLearning(cards.values, [local, unknown]);
    expect(merged['u:old']!.learningGroup, 'trip-group');
    expect(merged['u:other']!.learningGroup, 'u:other');
    expect(
      LearningGroups(merged, {
        'u:old': UserCardState(cardId: 'u:old', box: 3, dueAt: now),
      }).project(['trip']),
      ['u:old'],
    );
  });
  test('three intervening new targets for related concepts, stable and finite scarcity', () {
    final candidates = [
      target('shade', topic: 'sun', related: ['contrast']),
      target('shadow', topic: 'light', related: ['contrast']),
      target('train', topic: 'rail'),
      target('soup', topic: 'food'),
      target('bed', topic: 'room'),
    ];
    List<String> select() =>
        selectNewCards(candidates: candidates, knownLemmas: {}, limit: 30);
    expect(select(), ['shade', 'train', 'soup', 'bed', 'shadow']);
    expect(select(), select());
    expect(
      selectNewCards(
        candidates: candidates.take(2).toList(),
        knownLemmas: {},
        limit: 30,
      ),
      ['shade', 'shadow'],
    );
    final remaining = [...candidates];
    final learned = <String>[];
    while (remaining.isNotEmpty) {
      final picked = selectNewCards(
        candidates: remaining,
        knownLemmas: {},
        limit: 2,
      );
      expect(picked, isNotEmpty);
      learned.addAll(picked);
      remaining.removeWhere((c) => picked.contains(c.id));
    }
    expect(learned.toSet(), candidates.map((c) => c.id).toSet());
  });
}
