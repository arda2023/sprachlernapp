// Read-only content pack: install, schema check, repository, typed failures.
// Synthetic fixture only (test/fixtures/content_mini.sql).

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/data/content/content_database.dart';
import 'package:sprachapp/data/content/drift_content_repository.dart';
import 'package:sprachapp/domain/content.dart';

import 'support.dart';

void main() {
  late Directory tmp;
  late Directory work;
  late Directory support;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('content_repo_');
    work = Directory('${tmp.path}/work')..createSync();
    support = Directory('${tmp.path}/support')..createSync();
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  Future<DriftContentRepository> openFixture() async {
    final repo = await fixtureInstaller(work, support).open();
    addTearDown(repo.close);
    return repo;
  }

  Matcher unavailable(ContentUnavailableReason reason) =>
      isA<ContentUnavailable>()
          .having((e) => e.reason, 'reason', reason)
          .having((e) => e.message, 'message', isNotEmpty);

  group('reading', () {
    test('tokens use exact sense/form links and Unicode offsets, missing remains missing', () async {
      final bytes = buildFixturePack(
        work,
        tweak: (db) {
          db.execute(
            "UPDATE sentences SET text = '😀 Mia went home after work.' WHERE id='s-went-1'",
          );
          db.execute(
            "UPDATE card_sentences SET gap_start=6, gap_end=10 WHERE sentence_id='s-went-1'",
          );
          db.execute(
            "INSERT INTO sentence_tokens VALUES ('t1','s-went-1',0,6,10,'went','lem-go','sen-go','card-went',NULL,NULL)",
          );
          db.execute(
            "INSERT INTO sentence_tokens VALUES ('t2','s-went-1',1,11,15,'home',NULL,NULL,NULL,NULL,NULL)",
          );
          // A same-spelling dictionary entry for an unrelated sense must not leak.
          db.execute(
            "INSERT INTO dictionary_forms VALUES ('unrelated','en','home','different',NULL,'falsche Bedeutung',1,NULL,NULL)",
          );
        },
      ).readAsBytesSync();
      final repo = await installerFor(
        support,
        db: bytes,
        manifest: manifestFor(bytes),
      ).open();
      addTearDown(repo.close);
      final sentence = (await repo.practiceItems(['card-went']))
          .single
          .sentences
          .first;
      expect(sentence.gapText, 'went');
      expect(sentence.gapStart, 7);
      expect(sentence.tokens.first.start, 7);
      expect(sentence.tokens.first.translation, 'ging');
      expect(sentence.tokens.last.translation, isNull);
    });
    test('release info, decks and deck order', () async {
      final repo = await openFixture();
      expect(repo.info.lang, 'en');
      expect(repo.info.version, 'mini-v1');
      expect(repo.info.schemaVersion, 1);
      expect(repo.info.isInternalTestPack, isTrue);

      final decks = await repo.decks();
      expect(decks, hasLength(1));
      expect(decks.single.id, 'deck-allg');
      expect(decks.single.titleDe, 'Allgemeine Sprache');
      expect(decks.single.cardCount, 4); // tombstoned card not counted

      expect(await repo.deckCardIds('deck-allg'), [
        'card-went',
        'card-about',
        'card-a',
        'card-goes',
      ]);
      expect(await repo.allCardIds(), {
        'card-went',
        'card-about',
        'card-a',
        'card-goes',
      });
    });

    test(
      'cards with three sentences, gaps, translations and alternatives',
      () async {
        final repo = await openFixture();
        final items = await repo.practiceItems([
          'card-about',
          'card-went',
          'card-a',
        ]);
        expect(
          [for (final i in items) i.card.id],
          ['card-about', 'card-went', 'card-a'],
        );

        final went = items[1];
        expect(went.card.form, 'went');
        expect(went.card.lemma, 'go');
        expect(went.card.lemmaId, 'lem-go');
        expect(went.card.formLabelDe, 'Verb, Vergangenheit');
        expect(went.card.translationDe, 'ging');
        expect(
          [for (final s in went.sentences) s.sentenceId],
          ['s-went-1', 's-went-2', 's-went-3'],
        ); // by position, not storage
        expect(
          [for (final s in went.sentences) s.gapText],
          ['went', 'went', 'went'],
        );
        expect(went.sentences.first.text, 'Mia went home after work.');
        expect(
          went.sentences.first.translationDe,
          'Mia ging nach der Arbeit nach Hause.',
        );
        expect(went.sentences.first.validAlternatives, ['walked']);
        expect(went.sentences[1].validAlternatives, isEmpty);
        // dictionary forms of the lemma, without the card's own form; the
        // dictionary entry "gone" counts although its card is tombstoned
        expect(went.otherFormsOfLemma, {'go', 'goes', 'gone'});

        expect(items[0].sentences.first.validAlternatives, [
          'around',
          'approximately',
        ]);
        expect(items[0].otherFormsOfLemma, isEmpty);
        // NULL alternatives (old packs) read as the empty list
        expect(items[2].sentences[2].validAlternatives, isEmpty);
        expect(items[2].sentences.first.gapText, 'a');
      },
    );

    test('unknown and tombstoned ids are rejected, not replaced', () async {
      final repo = await openFixture();
      expect(() => repo.practiceItems(['card-gone-old']), throwsArgumentError);
      expect(() => repo.practiceItems(['nope']), throwsArgumentError);
    });
  });

  group('read-only', () {
    test('writes fail and the file stays byte-identical', () async {
      final file = buildFixturePack(work);
      final before = sha256Of(file);
      final db = ContentDatabase.open(file, lang: 'en');
      final readOnly = throwsA(
        predicate(
          (e) =>
              e.toString().contains('readonly') ||
              e.toString().contains('read-only'),
          'read-only error',
        ),
      );
      await expectLater(
        db.customStatement(
          "INSERT INTO languages VALUES ('de', 'Deutsch', 'Deutsch', 'de')",
        ),
        readOnly,
      );
      await expectLater(db.customStatement('CREATE TABLE x (a)'), readOnly);
      await expectLater(
        db.customStatement("UPDATE cards SET form = 'x'"),
        readOnly,
      );
      final repo = DriftContentRepository(db);
      await repo.practiceItems(['card-went']);
      await repo.close();
      expect(sha256Of(file), before);
    });

    test(
      'the installed copy keeps the manifest checksum after a session',
      () async {
        final installer = fixtureInstaller(work, support);
        final repo = await installer.open();
        await repo.practiceItems(await repo.deckCardIds('deck-allg'));
        await repo.close();
        final installed = await installer.install();
        expect(sha256Of(installed.file), installed.manifest.sha256);
      },
    );
  });

  group('typed failures, no placeholder fallback', () {
    test('missing manifest or database → missing', () async {
      final bytes = buildFixturePack(work).readAsBytesSync();
      await expectLater(
        installerFor(support, db: bytes).open(),
        throwsA(unavailable(ContentUnavailableReason.missing)),
      );
      await expectLater(
        installerFor(support, manifest: manifestFor(bytes)).open(),
        throwsA(unavailable(ContentUnavailableReason.missing)),
      );
      expect(
        () =>
            ContentDatabase.open(File('${work.path}/none.sqlite'), lang: 'en'),
        throwsA(unavailable(ContentUnavailableReason.missing)),
      );
    });

    test('checksum mismatch → corrupt', () async {
      final bytes = buildFixturePack(work).readAsBytesSync();
      final other = buildFixturePack(
        work,
        name: 'other.sqlite',
        tweak: (db) => db.execute("UPDATE cards SET translation_de = 'x'"),
      ).readAsBytesSync();
      await expectLater(
        installerFor(support, db: bytes, manifest: manifestFor(other)).open(),
        throwsA(unavailable(ContentUnavailableReason.corrupt)),
      );
    });

    test('a file that is not SQLite → corrupt', () async {
      final garbage = File('${work.path}/garbage.sqlite')
        ..writeAsBytesSync(List.generate(4096, (i) => i % 251));
      final bytes = garbage.readAsBytesSync();
      await expectLater(
        installerFor(support, db: bytes, manifest: manifestFor(bytes)).open(),
        throwsA(unavailable(ContentUnavailableReason.corrupt)),
      );
    });

    test('malformed manifest → corrupt', () async {
      final bytes = buildFixturePack(work).readAsBytesSync();
      await expectLater(
        installerFor(support, db: bytes, manifest: '{"format": 1').open(),
        throwsA(unavailable(ContentUnavailableReason.corrupt)),
      );
    });

    Future<void> expectIncompatible(
      void Function(dynamic db) tweak, {
      String version = 'mini-v1',
    }) async {
      final bytes = buildFixturePack(
        work,
        name: 'tweaked.sqlite',
        tweak: tweak,
      ).readAsBytesSync();
      await expectLater(
        installerFor(
          support,
          db: bytes,
          manifest: manifestFor(bytes, version: version),
        ).open(),
        throwsA(unavailable(ContentUnavailableReason.incompatible)),
      );
    }

    test(
      'other schema version → incompatible',
      () => expectIncompatible(
        (db) => db.execute('UPDATE content_releases SET schema_version = 2'),
      ),
    );

    test(
      'missing column → incompatible',
      () => expectIncompatible(
        (db) => db.execute(
          'ALTER TABLE card_sentences DROP COLUMN valid_alternatives',
        ),
      ),
    );

    test(
      'missing table → incompatible',
      () =>
          expectIncompatible((db) => db.execute('DROP TABLE dictionary_forms')),
    );

    test(
      'other language in the pack → incompatible',
      () => expectIncompatible(
        (db) => db.execute("UPDATE content_releases SET lang = 'es'"),
      ),
    );

    test(
      'manifest version differs from the pack → incompatible',
      () => expectIncompatible((_) {}, version: 'mini-v2'),
    );

    test('manifest for another language or schema → incompatible', () async {
      final bytes = buildFixturePack(work).readAsBytesSync();
      await expectLater(
        installerFor(
          support,
          db: bytes,
          manifest: manifestFor(bytes, lang: 'es'),
        ).open(),
        throwsA(unavailable(ContentUnavailableReason.incompatible)),
      );
    });

    Future<void> expectBrokenItems(void Function(dynamic db) tweak) async {
      final bytes = buildFixturePack(
        work,
        name: 'broken.sqlite',
        tweak: tweak,
      ).readAsBytesSync();
      final repo = await installerFor(
        support,
        db: bytes,
        manifest: manifestFor(bytes),
      ).open();
      try {
        await expectLater(
          repo.practiceItems(['card-went']),
          throwsA(unavailable(ContentUnavailableReason.incompatible)),
        );
      } finally {
        await repo.close(); // an open pack can't be replaced on Windows
      }
    }

    test(
      'alternatives that are not a JSON list of texts → incompatible',
      () async {
        await expectBrokenItems(
          (db) => db.execute(
            "UPDATE card_sentences SET valid_alternatives = '[\"x\"' WHERE id = 'cs-went-1'",
          ),
        );
        await expectBrokenItems(
          (db) => db.execute(
            "UPDATE card_sentences SET valid_alternatives = '[1]' WHERE id = 'cs-went-1'",
          ),
        );
      },
    );

    test(
      'gap not on the form → incompatible',
      () => expectBrokenItems(
        (db) => db.execute(
          "UPDATE card_sentences SET gap_start = 0 WHERE id = 'cs-went-2'",
        ),
      ),
    );

    test(
      'not exactly three sentences → incompatible',
      () => expectBrokenItems(
        (db) => db.execute("DELETE FROM card_sentences WHERE id = 'cs-went-3'"),
      ),
    );
  });

  group('installation lifecycle', () {
    test(
      'reinstalling never touches user.db and skips an identical copy',
      () async {
        final userDb = File('${support.path}/user.db')
          ..writeAsStringSync('learner state');
        final installer = fixtureInstaller(work, support);
        final first = await installer.install();
        final stamp = first.file.lastModifiedSync();
        await Future<void>.delayed(const Duration(milliseconds: 20));
        final second = await installer.install();
        expect(second.file.path, first.file.path);
        expect(second.file.lastModifiedSync(), stamp); // not rewritten
        expect(userDb.readAsStringSync(), 'learner state');
        expect(
          first.file.path,
          endsWith(
            ['content', 'en', 'content.sqlite'].join(Platform.pathSeparator),
          ),
        );
      },
    );

    test('a damaged installed copy is replaced from the asset', () async {
      final installer = fixtureInstaller(work, support);
      final installed = await installer.install();
      installed.file.writeAsStringSync('damaged');
      final again = await installer.install();
      expect(sha256Of(again.file), again.manifest.sha256);
      expect(File('${again.file.path}.tmp').existsSync(), isFalse);
      final repo = await installer.open();
      expect(await repo.allCardIds(), hasLength(4));
      await repo.close();
    });
  });
}
