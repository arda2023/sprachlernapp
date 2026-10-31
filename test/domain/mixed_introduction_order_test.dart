import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/domain/content.dart';
import 'package:sprachapp/domain/srs_state.dart';

void main() {
  test('related new topics are separated, unavailable cards never fill seats', () {
    final cards = <String, ContentCard>{};
    for (var topic = 0; topic < 6; topic++) {
      for (var i = 0; i < 8; i++) {
        final id = '$topic/$i';
        cards[id] = ContentCard(id: id, lang: 'en', form: id, formNorm: id,
          lemmaId: id, lemma: id, pos: 'NOUN',
          learning: LearningTarget(groupId: id, primaryCardId: id,
            topic: 'topic-$topic', note: 'test'));
      }
    }
    final selected = selectNewTargets(
      sources: [NewWordSource('general', cards.keys.toList())], cards: cards,
      states: {
        '0/0': const UserCardState(cardId: '0/0', box: 3, dueAt: null),
        '1/0': const UserCardState(cardId: '1/0', box: 0, dueAt: null, disabled: true),
      }, limit: 20);
    expect(selected, hasLength(20));
    expect(selected.map((s) => s.cardId), isNot(contains('0/0')));
    expect(selected.map((s) => s.cardId), isNot(contains('1/0')));
    for (var i = 0; i < selected.length; i++) {
      for (var gap = 1; gap <= 3 && i - gap >= 0; gap++) {
        expect(cards[selected[i].cardId]!.learning!.topic,
          isNot(cards[selected[i - gap].cardId]!.learning!.topic));
      }
    }
  });
}
