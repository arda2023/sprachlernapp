import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/data/content/content_database.dart';
import 'package:sprachapp/data/content/drift_content_repository.dart';
import 'package:sprachapp/domain/srs_state.dart';

void main() {
  for (final lang in ['en', 'es', 'it', 'nb', 'pt-BR']) {
    test('$lang real decks retain targets and mix new introductions', () async {
      final repo = DriftContentRepository(ContentDatabase.open(
        File('assets/content/$lang/content.sqlite'), lang: lang));
      try {
        final decks = await repo.decks();
        expect(decks.where((d) => d.titleDe == 'Allgemeine Sprache'), hasLength(1));
        final cards = {for (final c in await repo.selectionCards(await repo.allCardIds())) c.id: c};
        final watch = Stopwatch()..start();
        var changed = 0;
        for (final deck in decks) {
          final ids = (await repo.deckPracticeTargets(deck.id)).map((t) => t.cardId).toList();
          final queue = selectNewTargets(sources: [NewWordSource(deck.id, ids)],
            cards: cards, states: {}, limit: 20);
          expect(queue.every((t) => ids.contains(t.cardId)), isTrue);
          expect(queue.map((t) => t.cardId).toSet().length, queue.length);
          expect(queue.map((t) => cards[t.cardId]!.lemma.toLowerCase()).toSet().length, queue.length);
          if (queue.isNotEmpty && queue.first.cardId != ids.first) changed++;
        }
        expect(changed, greaterThan(decks.length ~/ 2));
        // Informational measurement across all decks, not a flaky speed gate.
        print('$lang: ${decks.length} decks checked, ${watch.elapsedMilliseconds} ms');
      } finally {
        await repo.close();
      }
    });
  }
}
