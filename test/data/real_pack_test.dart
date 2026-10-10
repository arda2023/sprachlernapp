// Data-access check of the real staged pack (assets/content/en/), through the
// production installer and repository. Skipped when no pack is staged, so the
// suite never depends on it; stage first with
//   dart run tool/stage_content_pack.dart --from <verified-pack-directory>

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sprachapp/data/content/content_pack_installer.dart';

import 'support.dart';

void main() {
  final asset = File('assets/content/en/content.sqlite');
  final manifest = File('assets/content/en/content.manifest.json');
  final staged = asset.existsSync() && manifest.existsSync();

  test('staged pack: all cards and sentence links readable, read-only', () async {
    final tmp = Directory.systemTemp.createTempSync('real_pack_');
    addTearDown(() => tmp.deleteSync(recursive: true));
    final before = sha256Of(asset);
    final raw = sqlite3.open(asset.path, mode: OpenMode.readOnly);
    late int expectedCards;
    late int expectedPrimary;
    late int expectedLearningTargets;
    late int expectedLinks;
    late int expectedAlternatives;
    final expectedDeckCardIds = <String, List<String>>{};
    final expectedSentenceIds = <String, String>{};
    try {
      expectedCards =
          raw
                  .select(
                    'SELECT count(*) AS n FROM cards WHERE removed_in IS NULL',
                  )
                  .single['n']
              as int;
      expectedPrimary =
          raw
                  .select(
                    'SELECT count(DISTINCT c.form_norm) AS n FROM deck_cards dc JOIN cards c ON c.id=dc.card_id WHERE dc.removed_in IS NULL AND c.removed_in IS NULL',
                  )
                  .single['n']
              as int;
      final schema =
          raw
                  .select('SELECT schema_version FROM content_releases')
                  .single['schema_version']
              as int;
      expectedLearningTargets = schema >= 3
          ? raw
                    .select(
                      "SELECT count(DISTINCT json_extract(c.learning, '\$.group_id')) n FROM deck_words w JOIN cards c ON c.id=w.primary_card_id WHERE w.removed_in IS NULL",
                    )
                    .single['n']
                as int
          : expectedPrimary;
      expectedLinks =
          raw
                  .select(
                    'SELECT count(*) AS n FROM card_sentences WHERE removed_in IS NULL',
                  )
                  .single['n']
              as int;
      expectedAlternatives =
          raw
                  .select(
                    "SELECT count(*) AS n FROM card_sentences WHERE removed_in IS NULL AND valid_alternatives != '[]'",
                  )
                  .single['n']
              as int;
      for (final deck in raw.select(
        'SELECT id, slug FROM decks WHERE removed_in IS NULL',
      )) {
        expectedDeckCardIds[deck['slug'] as String] = [
          for (final row in raw.select(
            'SELECT primary_card_id FROM deck_words WHERE deck_id = ? '
            'AND removed_in IS NULL ORDER BY position',
            [deck['id']],
          ))
            row['primary_card_id'] as String,
        ];
      }
      for (final row in raw.select(
        'SELECT card_id, sentence_id FROM card_sentences WHERE removed_in IS NULL',
      )) {
        expectedSentenceIds[row['card_id'] as String] =
            row['sentence_id'] as String;
      }
    } finally {
      raw.close();
    }
    final installer = ContentPackInstaller(
      supportDirectory: tmp,
      loadAsset: (key) async {
        final file = File(key);
        return file.existsSync()
            ? Uint8List.fromList(file.readAsBytesSync())
            : null;
      },
    );
    final repo = await installer.open();
    try {
      final decks = await repo.decks();
      final bySlug = {for (final deck in decks) deck.slug: deck};
      expect(bySlug.keys, unorderedEquals(expectedDeckCardIds.keys));
      expect(bySlug['allgemeine-sprache']!.cardCount, 160);
      expect(
        bySlug['reisen']!.cardCount,
        repo.info.schemaVersion >= 3 ? 489 : 500,
      );
      if (repo.info.version == 'alltag_zuhause_batch_1_v1') {
        expect(bySlug.keys, hasLength(3));
        expect(bySlug['alltag-zuhause']!.cardCount, 83);
      }
      if (repo.info.version == 'alltag_zuhause_batch_2_v1') {
        expect(bySlug.keys, hasLength(3));
        expect(bySlug['alltag-zuhause']!.cardCount, 163);
        expect(expectedCards, 927);
        expect(expectedPrimary, 823);
        expect(expectedLearningTargets, 812);
      }
      if (repo.info.version == 'alltag_zuhause_batch_3_v1') {
        expect(bySlug.keys, hasLength(3));
        expect(bySlug['alltag-zuhause']!.cardCount, 241);
        expect(expectedCards, 1005);
        expect(expectedPrimary, 901);
        expect(expectedLearningTargets, 890);
      }
      if (repo.info.version == 'arbeit_bildung_batch_1_v1') {
        expect(bySlug.keys, hasLength(4));
        expect(bySlug['alltag-zuhause']!.cardCount, 241);
        expect(bySlug['arbeit-bildung']!.cardCount, 82);
        expect(expectedCards, 1087);
        expect(expectedPrimary, 983);
        expect(expectedLearningTargets, 972);
      }
      if (repo.info.version == 'arbeit_bildung_batch_2_v1') {
        expect(bySlug.keys, hasLength(4));
        expect(bySlug['alltag-zuhause']!.cardCount, 241);
        expect(bySlug['arbeit-bildung']!.cardCount, 164);
        expect(expectedCards, 1169);
        expect(expectedPrimary, 1065);
        expect(expectedLearningTargets, 1054);
      }
      final cardIds = <String>[];
      for (final slug in expectedDeckCardIds.keys) {
        final deck = bySlug[slug]!;
        final ids = await repo.deckCardIds(deck.id);
        expect(ids, orderedEquals(expectedDeckCardIds[slug]!));
        expect(
          (await repo.selectionCards(ids)).map((c) => c.learningGroup).toSet(),
          hasLength(deck.cardCount),
        );
        final deckItems = await repo.practiceItems(ids);
        expect(deckItems, hasLength(ids.length));
        for (final item in deckItems) {
          expect(item.sentences, hasLength(1));
        }
        expect(
          deckItems.expand((item) => item.sentences).map((s) => s.sentenceId),
          unorderedEquals(ids.map((id) => expectedSentenceIds[id])),
        );
        cardIds.addAll(ids);
        // ignore: avoid_print
        print(
          'deck $slug: ${deck.cardCount} learning targets, ${ids.length} ownership cards, ${deckItems.length} fixed sentence assignments verified',
        );
      }
      final items = await repo.practiceItems(
        (await repo.allCardIds()).toList(),
      );
      final sentences = items.expand((i) => i.sentences).toList();
      final withAlternatives = sentences.where(
        (s) => s.validAlternatives.isNotEmpty,
      );

      // ignore: avoid_print
      print(
        'pack ${repo.info.version} (schema ${repo.info.schemaVersion}, '
        'internal: ${repo.info.isInternalTestPack}); ${decks.length} decks: '
        '${cardIds.length} cards, ${sentences.length} card sentences, '
        '${withAlternatives.length} with valid_alternatives, '
        '${(await repo.allCardIds()).length} cards in the pack',
      );

      expect(expectedCards, greaterThan(0));
      expect(
        expectedLinks,
        expectedCards * (repo.info.schemaVersion == 1 ? 3 : 1),
      );
      expect(
        decks.fold<int>(0, (sum, deck) => sum + deck.cardCount),
        expectedLearningTargets,
      );
      expect(cardIds, hasLength(expectedPrimary));
      expect(cardIds.toSet(), hasLength(expectedPrimary));
      expect(items, hasLength(expectedCards));
      expect(sentences, hasLength(expectedLinks));
      expect(
        sentences.map((s) => s.sentenceId).toSet(),
        hasLength(expectedLinks),
      );
      expect(
        items.every(
          (i) => i.sentences.length == (repo.info.schemaVersion == 1 ? 3 : 1),
        ),
        isTrue,
      );
      expect(withAlternatives, hasLength(expectedAlternatives));
      expect(repo.info.isInternalTestPack, isTrue);
      // ids are the 32-hex content ids, unchanged
      expect(
        cardIds.every((id) => RegExp(r'^[0-9a-f]{32}$').hasMatch(id)),
        isTrue,
      );
    } finally {
      await repo.close();
    }
    expect(sha256Of(asset), before);
  }, skip: staged ? false : 'no staged pack in assets/content/en/');
}
