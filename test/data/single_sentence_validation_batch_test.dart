import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sprachapp/data/content/content_database.dart';
import 'package:sprachapp/domain/content.dart';

class CountingValidationDatabase implements Database {
  CountingValidationDatabase(this.inner);
  final Database inner;
  int selects = 0;
  @override
  ResultSet select(String sql, [List<Object?> parameters = const []]) {
    selects++;
    return inner.select(sql, parameters);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Database fixture(int count, String lang) {
  final db = sqlite3.openInMemory();
  // Deliberately no unique constraints: validation must detect duplicate rows.
  db.execute('''
CREATE TABLE decks(id TEXT,lang TEXT,removed_in TEXT);
CREATE TABLE cards(id TEXT,lang TEXT,form TEXT,form_norm TEXT,introduction_scope TEXT,removed_in TEXT);
CREATE TABLE deck_words(id TEXT,lang TEXT,form_norm TEXT,deck_id TEXT,primary_card_id TEXT,position INTEGER,removed_in TEXT);
CREATE TABLE word_aliases(id TEXT,lang TEXT,form_norm TEXT,word_id TEXT,removed_in TEXT);
CREATE TABLE deck_cards(id TEXT,deck_id TEXT,card_id TEXT,position INTEGER,removed_in TEXT);
CREATE TABLE sentences(id TEXT,removed_in TEXT);
CREATE TABLE card_sentences(card_id TEXT,sentence_id TEXT,position INTEGER,removed_in TEXT);
''');
  db.execute('INSERT INTO decks VALUES(?,?,NULL)', ['deck', lang]);
  for (var i = 0; i < count; i++) {
    db.execute("INSERT INTO cards VALUES(?,?,?,?,'ordinary',NULL)", [
      'c$i',
      lang,
      'word$i',
      'word$i',
    ]);
    db.execute('INSERT INTO deck_words VALUES(?,?,?,?,?,?,NULL)', [
      'w$i',
      lang,
      'word$i',
      'deck',
      'c$i',
      i + 1,
    ]);
    db.execute('INSERT INTO word_aliases VALUES(?,?,?,?,NULL)', [
      'a$i',
      lang,
      'alias$i',
      'w$i',
    ]);
    db.execute('INSERT INTO deck_cards VALUES(?,?,?,?,NULL)', [
      'm$i',
      'deck',
      'c$i',
      i + 1,
    ]);
    db.execute('INSERT INTO sentences VALUES(?,NULL)', ['s$i']);
    db.execute('INSERT INTO card_sentences VALUES(?,?,1,NULL)', ['c$i', 's$i']);
  }
  return db;
}

void main() {
  for (final lang in ['en', 'pt-BR']) {
    test('$lang validation SELECT count stays eight as pack grows', () {
      for (final size in [1, 40, 805]) {
        final db = fixture(size, lang);
        try {
          final measured = CountingValidationDatabase(db);
          validateSingleSentenceContent(measured);
          expect(measured.selects, 8, reason: '$size cards/words/aliases');
        } finally {
          db.close();
        }
      }
    });
  }

  const invalid = {
    'duplicate primary card': 'INSERT INTO cards SELECT * FROM cards LIMIT 1',
    'duplicate owner deck': 'INSERT INTO decks SELECT * FROM decks',
    'duplicate active link':
        'INSERT INTO card_sentences SELECT * FROM card_sentences LIMIT 1',
    'duplicate sentence identity':
        'INSERT INTO sentences SELECT * FROM sentences LIMIT 1',
    'null primary identity': "UPDATE cards SET id=NULL WHERE id='c0'; UPDATE deck_words SET primary_card_id=NULL WHERE id='w0'",
    'null deck identity':
        'UPDATE decks SET id=NULL; UPDATE deck_words SET deck_id=NULL',
    'missing primary':
        "UPDATE deck_words SET primary_card_id='missing' WHERE id='w0'",
    'inactive primary': "UPDATE cards SET removed_in='old' WHERE id='c0'",
    'wrong primary language': "UPDATE cards SET lang='other' WHERE id='c0'",
    'wrong primary form':
        "UPDATE cards SET form_norm='different' WHERE id='c0'",
    'inactive deck': "UPDATE decks SET removed_in='old'",
    'wrong deck language': "UPDATE decks SET lang='other'",
    'duplicate word ownership':
        'INSERT INTO deck_words SELECT * FROM deck_words LIMIT 1',
    'missing alias word':
        "UPDATE word_aliases SET word_id='missing' WHERE id='a0'",
    'wrong alias language':
        "UPDATE word_aliases SET lang='other' WHERE id='a0'",
    'duplicate alias spelling':
        'INSERT INTO word_aliases SELECT * FROM word_aliases LIMIT 1',
    'alias collides with word':
        "UPDATE word_aliases SET form_norm='word0' WHERE id='a0'",
    'unnormalized word':
        "UPDATE deck_words SET form_norm='WORD0' WHERE id='w0'",
    'unnormalized alias':
        "UPDATE word_aliases SET form_norm='ALIAS0' WHERE id='a0'",
    'missing membership': "DELETE FROM deck_cards WHERE card_id='c0'",
    'wrong membership position':
        'UPDATE deck_cards SET position=10 WHERE position=1',
    'gapped word positions':
        'UPDATE deck_words SET position=10 WHERE position=1',
    'unnormalized card': "UPDATE cards SET form=' word0 ' WHERE id='c0'",
    'missing sentence': "DELETE FROM sentences WHERE id='s0'",
    'inactive sentence': "UPDATE sentences SET removed_in='old' WHERE id='s0'",
    'inactive link':
        "UPDATE card_sentences SET removed_in='old' WHERE card_id='c0'",
    'wrong sentence position':
        'UPDATE card_sentences SET position=2 WHERE position=1',
  };
  for (final entry in invalid.entries) {
    test('still rejects ${entry.key}', () {
      final db = fixture(2, 'en');
      try {
        db.execute(entry.value);
        expect(
          () => validateSingleSentenceContent(db),
          throwsA(isA<ContentUnavailable>()),
        );
      } finally {
        db.close();
      }
    });
  }

  test('retired duplicate rows do not shadow active references', () {
    final db = fixture(2, 'en');
    try {
      db.execute('''
INSERT INTO cards SELECT id,lang,form,form_norm,introduction_scope,'old' FROM cards;
INSERT INTO decks SELECT id,lang,'old' FROM decks;
INSERT INTO card_sentences SELECT card_id,sentence_id,position,'old' FROM card_sentences;
INSERT INTO word_aliases SELECT id,lang,form_norm,'missing','old' FROM word_aliases;
''');
      validateSingleSentenceContent(db);
    } finally {
      db.close();
    }
  });

  test('schema 4 form-only alias exception stays bounded to schema 4', () {
    final db = fixture(1, 'en');
    try {
      db.execute("""
INSERT INTO cards VALUES('form','en','alias0','alias0','form_only',NULL);
INSERT INTO card_sentences VALUES('form','s0',1,NULL);
""");
      validateSingleSentenceContent(db, schemaVersion: 4);
      expect(
        () => validateSingleSentenceContent(db, schemaVersion: 3),
        throwsA(isA<ContentUnavailable>()),
      );
    } finally {
      db.close();
    }
  });
}
