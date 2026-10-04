import 'package:sprachapp/domain/content.dart';
// Derived counters, deck queues and the in-session repeat (docs/srs.md).

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/domain/srs_state.dart';

void main() {
  final now = DateTime(2026, 10, 10, 12);
  final past = DateTime(2026, 10, 9);
  final future = DateTime(2026, 10, 20);

  UserCardState card(
    String id,
    int box,
    DateTime? due, {
    bool disabled = false,
    bool retired = false,
    bool localOnly = false,
  }) => UserCardState(
    cardId: id,
    box: box,
    dueAt: due,
    disabled: disabled,
    retired: retired,
    localOnly: localOnly,
  );

  group('deriveVocabBreakdown', () {
    final known = {'c1', 'c2', 'c3', 'c4', 'c5', 'c6', 'c7', 'c8', 'u:own'};
    final cards = {
      'c1': card('c1', 0, null), // added, never answered → unseen
      'c2': card('c2', 2, past), // due
      'c3': card('c3', 5, past), // box 5 but due → due, not mastered
      'c4': card('c4', 5, future), // mastered
      'c5': card('c5', 3, future), // building
      'c6': card('c6', 1, now), // due exactly now → due
      'c7': card('c7', 4, future, disabled: true), // nowhere
      'c8': card('c8', 2, past, retired: true), // nowhere
      'old-verb': card('old-verb', 4, future), // not in the pack → nowhere
      'u:own': card('u:own', 1, future, localOnly: true), // local card counts
    };
    final active = {'c1', 'c2', 'c7', 'n1', 'n2'}; // n1, n2: no card yet

    test('assigns every card to exactly one category', () {
      final b = deriveVocabBreakdown(
        activeDeckCardIds: active,
        cards: cards,
        knownCardIds: known,
        now: now,
      );
      expect([b.unseen, b.due, b.mastered, b.building], [3, 3, 1, 2]);
    });

    test('invariant: sum = |C| + deck cards without a card', () {
      final b = deriveVocabBreakdown(
        activeDeckCardIds: active,
        cards: cards,
        knownCardIds: known,
        now: now,
      );
      final c = cards.values.where(
        (s) => s.isActive && (s.localOnly || known.contains(s.cardId)),
      );
      final withoutCard = active.where((id) => !cards.containsKey(id));
      expect(b.total, c.length + withoutCard.length);
    });

    test('a review moves a card between categories, never adds one', () {
      final before = deriveVocabBreakdown(
        activeDeckCardIds: active,
        cards: cards,
        knownCardIds: known,
        now: now,
      );
      final after = deriveVocabBreakdown(
        activeDeckCardIds: active,
        cards: {...cards, 'c2': card('c2', 3, future)},
        knownCardIds: known,
        now: now,
      );
      expect(after.total, before.total);
      expect(after.due, before.due - 1);
      expect(after.building, before.building + 1);
    });

    test('a later "now" turns building cards into due ones', () {
      final later = deriveVocabBreakdown(
        activeDeckCardIds: active,
        cards: cards,
        knownCardIds: known,
        now: DateTime(2026, 10, 25),
      );
      expect([later.due, later.mastered, later.building], [6, 0, 0]);
    });

    test('an old VERB row stays out; the new AUX card counts as unseen', () {
      final b = deriveVocabBreakdown(
        activeDeckCardIds: {'aux-befinden'},
        cards: {'verb-befinden': card('verb-befinden', 5, future)},
        knownCardIds: {'aux-befinden'},
        now: now,
      );
      expect([b.unseen, b.due, b.building, b.mastered], [1, 0, 0, 0]);
    });
  });

  group('buildDeckQueue', () {
    final deck = ['a', 'b', 'c', 'd', 'e', 'f', 'g'];
    final states = {
      'a': card('a', 2, future), // seen, not due
      'b': card('b', 3, DateTime(2026, 10, 8)), // due, older
      'c': card('c', 0, null), // created, unanswered → new
      'd': card('d', 1, DateTime(2026, 10, 9)), // due, newer
      'e': card('e', 0, null, disabled: true), // never
      // f, g: no row → new
    };

    test('learn: due cards oldest first, then new cards in deck order', () {
      final q = buildDeckQueue(
        deckCardIds: deck,
        cards: {
          for (final id in deck)
            id: ContentCard(
              id: id,
              lang: "en",
              form: id,
              formNorm: id,
              lemmaId: id,
              lemma: id,
              pos: "NOUN",
            ),
        },
        states: states,
        kind: DeckSessionKind.learn,
        now: now,
      );
      expect(q.map((e) => e.cardId), ['b', 'd', 'f', 'g', 'c']);
      expect(q.every((e) => !e.repeat), isTrue);
    });

    test('learn respects the session size', () {
      final q = buildDeckQueue(
        deckCardIds: deck,
        cards: {
          for (final id in deck)
            id: ContentCard(
              id: id,
              lang: "en",
              form: id,
              formNorm: id,
              lemmaId: id,
              lemma: id,
              pos: "NOUN",
            ),
        },
        states: states,
        kind: DeckSessionKind.learn,
        now: now,
        size: 3,
      );
      expect(q.map((e) => e.cardId), ['b', 'd', 'f']);
    });

    test('revue: seen cards only, soonest due first', () {
      final q = buildDeckQueue(
        deckCardIds: deck,
        cards: {
          for (final id in deck)
            id: ContentCard(
              id: id,
              lang: "en",
              form: id,
              formNorm: id,
              lemmaId: id,
              lemma: id,
              pos: "NOUN",
            ),
        },
        states: states,
        kind: DeckSessionKind.revue,
        now: now,
      );
      expect(q.map((e) => e.cardId), ['b', 'd', 'a']);
      expect(DeckSessionKind.revue.mode, ReviewMode.revue);
      expect(DeckSessionKind.learn.mode, ReviewMode.deck);
    });

    test('retired cards and duplicate deck entries never appear twice', () {
      final q = buildDeckQueue(
        deckCardIds: ['x', 'x', 'y'],
        cards: {
          for (final id in ['x', 'y'])
            id: ContentCard(
              id: id,
              lang: 'en',
              form: id,
              formNorm: id,
              lemmaId: id,
              lemma: id,
              pos: 'NOUN',
            ),
        },
        states: {'y': card('y', 2, past, retired: true)},
        kind: DeckSessionKind.learn,
        now: now,
      );
      expect(q.map((e) => e.cardId), ['x']);
    });
  });

  group('withRepeat (in-session repeat)', () {
    final queue = [
      for (final id in ['a', 'b', 'c', 'd', 'e', 'f']) SessionEntry(id),
    ];

    test('the card returns once, three cards later', () {
      final q = withRepeat(queue, 0);
      expect(q.map((e) => e.repeat ? '${e.cardId}*' : e.cardId), [
        'a',
        'b',
        'c',
        'd',
        'a*',
        'e',
        'f',
      ]);
    });

    test('near the end it goes last', () {
      final q = withRepeat(queue, 4);
      expect(q.last, const SessionEntry('e', repeat: true));
    });

    test('only once, and a repeat never schedules another', () {
      final once = withRepeat(queue, 0);
      expect(withRepeat(once, 0), same(once));
      final repeatIndex = once.indexWhere((e) => e.repeat);
      expect(withRepeat(once, repeatIndex), same(once));
    });
  });

  test('randomUuidV4 is a version-4 UUID', () {
    final id = randomUuidV4(Random(1));
    expect(
      id,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
    expect(randomUuidV4(), isNot(randomUuidV4()));
  });
}
