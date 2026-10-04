import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sprachapp/data/content/content_database.dart';
import 'package:sprachapp/data/content/drift_content_repository.dart';
import 'package:sprachapp/domain/content.dart';
import 'package:sprachapp/domain/srs_state.dart';

import 'support.dart';

void schemaTwo(Database db) {
  db.execute('UPDATE content_releases SET schema_version=2');
  db.execute("UPDATE card_sentences SET removed_in='v2' WHERE position != 1");
  db.execute(
    'CREATE TABLE deck_words (id TEXT,lang TEXT,form_norm TEXT,deck_id TEXT,primary_card_id TEXT,position INTEGER,removed_in TEXT)',
  );
  db.execute(
    'CREATE TABLE word_aliases (id TEXT,lang TEXT,form_norm TEXT,word_id TEXT,removed_in TEXT)',
  );
  db.execute(
    'INSERT INTO deck_words SELECT c.id,c.lang,c.form_norm,dc.deck_id,c.id,dc.position,NULL FROM cards c JOIN deck_cards dc ON dc.card_id=c.id WHERE c.removed_in IS NULL AND dc.removed_in IS NULL',
  );
}

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('one_sentence_'));
  tearDown(() => dir.deleteSync(recursive: true));

  test('schema 1 fixed sentence and schema 2 archives stay readable without writes', () async {
    for (final schema in [1, 2]) {
      final file = buildFixturePack(dir, tweak: schema == 2 ? schemaTwo : null);
      final before = sha256Of(file);
      final repo = DriftContentRepository(
        ContentDatabase.open(file, lang: 'en'),
      );
      final item = (await repo.practiceItems(['card-went'])).single;
      expect(item.sentenceForPass(0).sentenceId, 's-went-1');
      expect(item.sentenceForPass(99).sentenceId, 's-went-1');
      expect(item.sentences.length, schema == 1 ? 3 : 1);
      expect(
        (await repo.historicalSentence('card-went', 's-went-2'))?.sentenceId,
        's-went-2',
      );
      await repo.close();
      expect(sha256Of(file), before);
    }
  });

  test('schema 2 rejects zero/two/four active sentences and duplicate owners', () {
    for (final mutation in [
      "UPDATE card_sentences SET removed_in='v2' WHERE card_id='card-went'",
      "UPDATE card_sentences SET removed_in=NULL WHERE sentence_id='s-went-2'",
      "INSERT INTO card_sentences SELECT 'extra' || n, card_id, sentence_id, n+1, gap_start, gap_end, accepted, NULL, NULL, valid_alternatives FROM card_sentences CROSS JOIN (SELECT 1 n UNION SELECT 2 UNION SELECT 3) WHERE sentence_id='s-went-1'",
      'INSERT INTO deck_words SELECT * FROM deck_words LIMIT 1',
      "INSERT INTO word_aliases VALUES ('alias','en','went','card-goes',NULL)",
    ]) {
      final file = buildFixturePack(
        dir,
        tweak: (db) {
          schemaTwo(db);
          db.execute(mutation);
        },
      );
      expect(
        () => ContentDatabase.open(file, lang: 'en'),
        throwsA(isA<ContentUnavailable>()),
      );
    }
  });

  test('unknown higher schema rejected with version in message', () {
    final file = buildFixturePack(
      dir,
      tweak: (db) =>
          db.execute('UPDATE content_releases SET schema_version=77'),
    );
    expect(
      () => ContentDatabase.open(file, lang: 'en'),
      throwsA(
        isA<ContentUnavailable>().having(
          (e) => e.message,
          'version',
          contains('77'),
        ),
      ),
    );
  });

  test('learned secondary sense stays mixed; displayed box zero does not re-enter or count', () async {
    final file = buildFixturePack(dir);
    final repo = DriftContentRepository(ContentDatabase.open(file, lang: 'en'));
    final cards = {
      for (final c in await repo.selectionCards(await repo.allCardIds()))
        c.id: c,
    };
    final now = DateTime(2026, 10, 4);
    final states = {
      'card-went': UserCardState(cardId: 'card-went', box: 2, dueAt: now),
      'card-about': const UserCardState(
        cardId: 'card-about',
        box: 0,
        dueAt: null,
      ),
      'card-a': const UserCardState(
        cardId: 'card-a',
        dueAt: null,
        box: 0,
        origin: CardOrigin.story,
      ),
    };
    final mixed = buildMixedQueue(
      activeDeckCardIds: ['card-goes'],
      cards: cards,
      states: states,
      now: now,
      size: 20,
    );
    expect(
      mixed.map((e) => e.cardId),
      containsAll(['card-went', 'card-a', 'card-goes']),
    );
    expect(mixed.map((e) => e.cardId), isNot(contains('card-about')));
    for (final kind in [DeckSessionKind.learn, DeckSessionKind.revue]) {
      expect(
        buildDeckQueue(
          deckCardIds: ['card-goes'],
          cards: cards,
          states: states,
          kind: kind,
          now: now,
        ).map((e) => e.cardId),
        isNot(contains('card-went')),
      );
    }
    final counts = deriveVocabBreakdown(
      activeDeckCardIds: {'card-goes'},
      cards: states,
      knownCardIds: cards.keys.toSet(),
      now: now,
    );
    expect(counts.due, 1);
    expect(counts.unseen, 2);
    expect(counts.total, 3);
    await repo.close();
  });
}
