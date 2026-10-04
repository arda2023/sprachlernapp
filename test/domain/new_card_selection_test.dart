import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/domain/content.dart';
import 'package:sprachapp/domain/new_card_selection.dart';
import 'package:sprachapp/domain/srs_state.dart';

ContentCard c(
  String id, {
  String? lemma,
  String? form,
  String pos = 'NOUN',
  String? sense,
}) => ContentCard(
  id: id,
  lang: 'en',
  form: form ?? id,
  formNorm: form ?? id,
  lemmaId: 'lemma-$id',
  lemma: lemma ?? id,
  pos: pos,
  senseKey: sense,
);

void main() {
  test('mixed keeps due reviews ahead of diverse new cards, merges decks, filters disabled, then early', () {
    final now = DateTime(2026, 10, 4);
    final cards = [
      c('due1', lemma: 'same'),
      c('due2', lemma: 'same'),
      for (var i = 0; i < 5; i++) c('n$i'),
      c('function', pos: 'ADP'),
      c('disabled'),
      c('early'),
    ];
    final states = {
      'due1': UserCardState(
        cardId: 'due1',
        box: 2,
        dueAt: now.subtract(const Duration(days: 2)),
      ),
      'due2': UserCardState(cardId: 'due2', box: 5, dueAt: now),
      'disabled': UserCardState(
        cardId: 'disabled',
        box: 1,
        dueAt: now,
        disabled: true,
      ),
      'early': UserCardState(
        cardId: 'early',
        box: 3,
        dueAt: now.add(const Duration(days: 2)),
      ),
    };
    final queue = buildMixedQueue(
      activeDeckCardIds: [
        'function',
        'n0',
        'n1',
        'n0',
        'disabled',
        'n2',
        'n3',
        'n4',
      ],
      cards: {for (final c in cards) c.id: c},
      states: states,
      now: now,
      size: 10,
    );
    expect(queue.map((e) => e.cardId), [
      'due1',
      'due2',
      'n0',
      'n1',
      'n2',
      'n3',
      'function',
      'n4',
      'early',
    ]);
    expect(queue.last.mode, ReviewMode.early);
    expect(queue.take(2).every((e) => e.mode == ReviewMode.mixed), isTrue);
    final repeated = withRepeat(queue, 0);
    expect(repeated.where((e) => e.repeat).single.mode, ReviewMode.mixed);
    expect(withRepeat(repeated, 4), repeated);
    expect(
      buildMixedQueue(
        activeDeckCardIds: [],
        cards: {},
        states: states,
        now: now,
      ),
      isEmpty,
    );
  });

  List<String> pick(
    List<ContentCard> cards, {
    int limit = 10,
    Set<String> known = const {},
  }) => selectNewCards(candidates: cards, knownLemmas: known, limit: limit);

  test(
    'four content then one function, ranked within groups and deterministic',
    () {
      final cards = [
        for (var i = 0; i < 4; i++) c('f$i', pos: 'ADP'),
        for (var i = 0; i < 9; i++) c('c$i'),
      ];
      final expected = [
        'c0',
        'c1',
        'c2',
        'c3',
        'f0',
        'c4',
        'c5',
        'c6',
        'c7',
        'f1',
      ];
      expect(pick(cards), expected);
      expect(pick(cards), expected);
    },
  );

  test('one lemma across forms/POS and one surface across lemmas', () {
    expect(
      pick([
        c('went', lemma: 'go'),
        c('goes', lemma: 'go'),
        c('go-noun', lemma: 'go'),
        c('lead-metal', form: 'lead'),
        c('lead-verb', form: 'lead', pos: 'VERB'),
        c('chair'),
      ]),
      ['went', 'lead-metal', 'chair'],
    );
  });

  test(
    'never displayed lemmas first; short queues do not refill functions',
    () {
      expect(pick([c('known'), c('new1'), c('new2')], known: {'known'}), [
        'new1',
        'new2',
        'known',
      ]);
      final functions = [
        for (var i = 0; i < 6; i++) c('of$i', lemma: 'of', pos: 'ADP'),
      ];
      expect(pick(functions), ['of0']);
      expect(pick([c('table'), ...functions]), ['table', 'of0']);
      expect(pick([]), isEmpty);
      expect(pick([c('table')], limit: 0), isEmpty);
    },
  );

  test('sense exceptions never exclude all uses of a surface', () {
    expect(
      isContentWord(
        c('have-lexical', form: 'have', pos: 'VERB', sense: 'have#haben'),
      ),
      isTrue,
    );
    expect(
      isContentWord(
        c('have-modal', form: 'have', pos: 'VERB', sense: 'have#muessen'),
      ),
      isFalse,
    );
    expect(isContentWord(c('be', pos: 'AUX', sense: 'be#befinden')), isTrue);
    expect(isContentWord(c('be', pos: 'AUX', sense: 'be#passiv')), isFalse);
    expect(isContentWord(c('quickly', pos: 'ADV')), isTrue);
    expect(
      isContentWord(c('about', pos: 'ADV', sense: 'about#ungefaehr')),
      isFalse,
    );
  });

  test('due function senses survive duplicates; disabled/retired stay out; revue unchanged', () {
    final cards = [
      c('of1', lemma: 'of', pos: 'ADP'),
      c('of2', lemma: 'of', pos: 'ADP'),
      c('disabled'),
      c('retired'),
      c('table'),
    ];
    final now = DateTime(2026, 10, 4);
    final states = {
      for (final id in ['of1', 'of2'])
        id: UserCardState(cardId: id, box: 2, dueAt: now),
      'disabled': const UserCardState(
        cardId: 'disabled',
        box: 0,
        dueAt: null,
        disabled: true,
      ),
      'retired': UserCardState(
        cardId: 'retired',
        box: 2,
        dueAt: now,
        retired: true,
      ),
    };
    List<SessionEntry> queue(DeckSessionKind kind) => buildDeckQueue(
      deckCardIds: cards.map((c) => c.id).toList(),
      cards: {for (final card in cards) card.id: card},
      states: states,
      kind: kind,
      now: now,
    );
    final learn = queue(DeckSessionKind.learn);
    expect(learn.map((e) => e.cardId), ['of1', 'of2', 'table']);
    expect(queue(DeckSessionKind.revue).map((e) => e.cardId), ['of1', 'of2']);
    final repeat = withRepeat(learn, 0);
    expect(repeat.where((e) => e.repeat).single.cardId, 'of1');
    expect(withRepeat(repeat, repeat.length - 1), repeat);
  });
}
