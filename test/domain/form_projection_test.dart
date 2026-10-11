import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/domain/content.dart';
import 'package:sprachapp/domain/learning_groups.dart';
import 'package:sprachapp/domain/srs_state.dart';

void main() {
  test('ordinary group head and exact form remain separate through queue and counts', () {
    ContentCard c(String id, {String? function, String? lexical}) =>
        ContentCard(
          id: id,
          lang: 'en',
          form: id,
          formNorm: id,
          lemmaId: 'verb',
          lemma: 'verb',
          pos: 'VERB',
          senseId: 'sense',
          identityFunction: function,
          lexicalTargetId: lexical,
          learning: const LearningTarget(
            groupId: 'group',
            primaryCardId: 'head',
            topic: 'test',
            note: 'synthetic',
          ),
        );
    final cards = {
      'head': c('head'),
      'form': c('form', function: 'past', lexical: 'L'),
    };
    final groups = LearningGroups(cards, {});
    expect(groups.project(['form']), ['head']);
    expect(groups.project(['form'], exactForms: true), ['form']);
    final ids = [
      ...groups.project(['head']),
      ...groups.project(['form'], exactForms: true),
    ];
    final q = buildDeckQueue(
      deckCardIds: ['form'],
      cards: cards,
      states: {},
      kind: DeckSessionKind.learn,
      now: DateTime(2026),
      targetsResolved: true,
    );
    expect(q.single.cardId, 'form');
    final counts = deriveVocabBreakdown(
      activeDeckCardIds: ids.toSet(),
      cards: {},
      knownCardIds: cards.keys.toSet(),
      contentCards: cards,
      targetsResolved: true,
      now: DateTime(2026),
    );
    expect(counts.unseen, 2);
    expect(deriveLexicalBreakdown(ids.toSet(), cards, {}).total, 1);
  });
}
