// Data-access check of the real staged pack (assets/content/en/), through the
// production installer and repository. Skipped when no pack is staged, so the
// suite never depends on it; stage first with
//   dart run tool/stage_content_pack.dart --from <verified-pack-directory>

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sprachapp/data/content/content_pack_installer.dart';

import 'package:sprachapp/domain/learning_groups.dart';

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
                      "SELECT count(DISTINCT json_extract(c.learning, '\$.group_id')) n FROM deck_words w JOIN cards c ON c.id=w.primary_card_id WHERE w.removed_in IS NULL ${schema >= 4 ? "AND c.introduction_scope='ordinary'" : ''}",
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
      if (repo.info.version == 'arbeit_bildung_batch_3_v1') {
        expect(bySlug.keys, hasLength(4));
        expect(bySlug['alltag-zuhause']!.cardCount, 241);
        expect(bySlug['arbeit-bildung']!.cardCount, 245);
        expect(expectedCards, 1250);
        expect(expectedPrimary, 1146);
        expect(expectedLearningTargets, 1135);
      }
      if (repo.info.version == 'menschen_beziehungen_batch_1_v1') {
        expect(bySlug.keys, hasLength(5));
        expect(bySlug['alltag-zuhause']!.cardCount, 241);
        expect(bySlug['arbeit-bildung']!.cardCount, 245);
        expect(bySlug['menschen-beziehungen']!.cardCount, 82);
        expect(expectedCards, 1332);
        expect(expectedPrimary, 1228);
        expect(expectedLearningTargets, 1217);
      }
      if (repo.info.version == 'menschen_beziehungen_batch_2_v1') {
        expect(bySlug.keys, hasLength(5));
        expect(bySlug['alltag-zuhause']!.cardCount, 241);
        expect(bySlug['arbeit-bildung']!.cardCount, 245);
        expect(bySlug['menschen-beziehungen']!.cardCount, 164);
        expect(expectedCards, 1414);
        expect(expectedPrimary, 1310);
        expect(expectedLearningTargets, 1299);
      }
      if (repo.info.version == 'menschen_beziehungen_batch_3_v1') {
        expect(bySlug.keys, hasLength(5));
        expect(bySlug['alltag-zuhause']!.cardCount, 241);
        expect(bySlug['arbeit-bildung']!.cardCount, 245);
        expect(bySlug['menschen-beziehungen']!.cardCount, 245);
        expect(expectedCards, 1495);
        expect(expectedPrimary, 1391);
        expect(expectedLearningTargets, 1380);
      }
      if (repo.info.version == 'koerper_gesundheit_batch_1_v1') {
        expect(bySlug.keys, hasLength(6));
        expect(bySlug['alltag-zuhause']!.cardCount, 241);
        expect(bySlug['arbeit-bildung']!.cardCount, 245);
        expect(bySlug['menschen-beziehungen']!.cardCount, 245);
        expect(bySlug['koerper-gesundheit']!.cardCount, 83);
        expect(expectedCards, 1578);
        expect(expectedPrimary, 1474);
        expect(expectedLearningTargets, 1463);
      }
      if (repo.info.version == 'koerper_gesundheit_batch_2_v1') {
        expect(bySlug.keys, hasLength(6));
        expect(bySlug['alltag-zuhause']!.cardCount, 241);
        expect(bySlug['arbeit-bildung']!.cardCount, 245);
        expect(bySlug['menschen-beziehungen']!.cardCount, 245);
        expect(bySlug['koerper-gesundheit']!.cardCount, 166);
        expect(expectedCards, 1661);
        expect(expectedPrimary, 1557);
        expect(expectedLearningTargets, 1546);
      }
      if (repo.info.version == 'koerper_gesundheit_batch_3_v1') {
        expect(bySlug.keys, hasLength(6));
        expect(bySlug['alltag-zuhause']!.cardCount, 241);
        expect(bySlug['arbeit-bildung']!.cardCount, 245);
        expect(bySlug['menschen-beziehungen']!.cardCount, 245);
        expect(bySlug['koerper-gesundheit']!.cardCount, 249);
        expect(expectedCards, 1744);
        expect(expectedPrimary, 1640);
        expect(expectedLearningTargets, 1629);
      }
      if (repo.info.version == 'essen_trinken_batch_1_v1') {
        expect(bySlug.keys, hasLength(7));
        expect(bySlug['allgemeine-sprache']!.cardCount, 160);
        expect(bySlug['reisen']!.cardCount, 489);
        expect(bySlug['alltag-zuhause']!.cardCount, 241);
        expect(bySlug['arbeit-bildung']!.cardCount, 245);
        expect(bySlug['menschen-beziehungen']!.cardCount, 245);
        expect(bySlug['koerper-gesundheit']!.cardCount, 249);
        expect(bySlug['essen-trinken']!.cardCount, 84);
        expect(expectedCards, 1828);
        expect(expectedPrimary, 1724);
        expect(expectedLearningTargets, 1713);
      }
      if (repo.info.version == 'essen_trinken_batch_2_v1') {
        expect(bySlug.keys, hasLength(7));
        expect(bySlug['allgemeine-sprache']!.cardCount, 160);
        expect(bySlug['reisen']!.cardCount, 489);
        expect(bySlug['alltag-zuhause']!.cardCount, 241);
        expect(bySlug['arbeit-bildung']!.cardCount, 245);
        expect(bySlug['menschen-beziehungen']!.cardCount, 245);
        expect(bySlug['koerper-gesundheit']!.cardCount, 249);
        expect(bySlug['essen-trinken']!.cardCount, 167);
        expect(expectedCards, 1911);
        expect(expectedPrimary, 1807);
        expect(expectedLearningTargets, 1796);
      }
      if (repo.info.version == 'essen_trinken_batch_3_v1') {
        expect(bySlug.keys, hasLength(7));
        expect(bySlug['allgemeine-sprache']!.cardCount, 160);
        expect(bySlug['reisen']!.cardCount, 489);
        expect(bySlug['alltag-zuhause']!.cardCount, 241);
        expect(bySlug['arbeit-bildung']!.cardCount, 245);
        expect(bySlug['menschen-beziehungen']!.cardCount, 245);
        expect(bySlug['koerper-gesundheit']!.cardCount, 249);
        expect(bySlug['essen-trinken']!.cardCount, 250);
        expect(expectedCards, 1994);
        expect(expectedPrimary, 1890);
        expect(expectedLearningTargets, 1879);
      }
      if (repo.info.version == 'natur_umwelt_batch_1_v1') {
        expect(bySlug.keys, hasLength(8));
        expect(bySlug['allgemeine-sprache']!.cardCount, 160);
        expect(bySlug['reisen']!.cardCount, 489);
        expect(bySlug['alltag-zuhause']!.cardCount, 241);
        expect(bySlug['arbeit-bildung']!.cardCount, 245);
        expect(bySlug['menschen-beziehungen']!.cardCount, 245);
        expect(bySlug['koerper-gesundheit']!.cardCount, 249);
        expect(bySlug['essen-trinken']!.cardCount, 250);
        expect(bySlug['natur-umwelt']!.cardCount, 81);
        expect(expectedCards, 2075);
        expect(expectedPrimary, 1971);
        expect(expectedLearningTargets, 1960);
      }
      if (repo.info.version == 'natur_umwelt_batch_2_v1') {
        expect(bySlug.keys, hasLength(8));
        expect(bySlug['allgemeine-sprache']!.cardCount, 160);
        expect(bySlug['reisen']!.cardCount, 489);
        expect(bySlug['alltag-zuhause']!.cardCount, 241);
        expect(bySlug['arbeit-bildung']!.cardCount, 245);
        expect(bySlug['menschen-beziehungen']!.cardCount, 245);
        expect(bySlug['koerper-gesundheit']!.cardCount, 249);
        expect(bySlug['essen-trinken']!.cardCount, 250);
        expect(bySlug['natur-umwelt']!.cardCount, 162);
        expect(expectedCards, 2156);
        expect(expectedPrimary, 2052);
        expect(expectedLearningTargets, 2041);
      }
      if (repo.info.version == 'natur_umwelt_batch_3_v1') {
        expect(bySlug.keys, hasLength(8));
        expect(bySlug['allgemeine-sprache']!.cardCount, 160);
        expect(bySlug['reisen']!.cardCount, 489);
        expect(bySlug['alltag-zuhause']!.cardCount, 241);
        expect(bySlug['arbeit-bildung']!.cardCount, 245);
        expect(bySlug['menschen-beziehungen']!.cardCount, 245);
        expect(bySlug['koerper-gesundheit']!.cardCount, 249);
        expect(bySlug['essen-trinken']!.cardCount, 250);
        expect(bySlug['natur-umwelt']!.cardCount, 242);
        expect(expectedCards, 2236);
        expect(expectedPrimary, 2132);
        expect(expectedLearningTargets, 2121);
      }
      if (repo.info.version == 'irregular_verbs_batch_1_v1' ||
          repo.info.version == 'irregular_verbs_batch_2_v1' ||
          repo.info.version == 'irregular_verbs_batch_3_v1' ||
          repo.info.version == 'irregular_verbs_batch_4_v1' ||
          repo.info.version == 'alltagssprache_redewendungen_batch_1_v1' ||
          repo.info.version == 'alltagssprache_redewendungen_batch_2_v1') {
        final batch2 = repo.info.version == 'irregular_verbs_batch_2_v1';
        final batch3 = repo.info.version == 'irregular_verbs_batch_3_v1';
        final everyday2 = repo.info.version == 'alltagssprache_redewendungen_batch_2_v1';
        final everyday = repo.info.version == 'alltagssprache_redewendungen_batch_1_v1' || everyday2;
        final batch4 = repo.info.version == 'irregular_verbs_batch_4_v1' || everyday;
        final formsPerView = batch4 ? 134 : batch3 ? 101 : batch2 ? 68 : 33;
        expect(bySlug.keys, hasLength(everyday ? 12 : 11));
        const ordinaryCounts = {
          'allgemeine-sprache':160, 'reisen':489, 'alltag-zuhause':241,
          'arbeit-bildung':245, 'menschen-beziehungen':245,
          'koerper-gesundheit':249, 'essen-trinken':250, 'natur-umwelt':242,
        };
        for (final entry in ordinaryCounts.entries) {
          expect(bySlug[entry.key]!.cardCount, entry.value);
        }
        if (everyday) {
          expect(bySlug['alltagssprache-redewendungen']!.cardCount, everyday2 ? 178 : 89);
        }
        expect(expectedCards, everyday2 ? 2745 : everyday ? 2656 : batch4 ? 2567 : batch3 ? 2486 : batch2 ? 2402 : 2319);
        expect(expectedPrimary, everyday2 ? 2534 : everyday ? 2445 : batch4 ? 2356 : batch3 ? 2299 : batch2 ? 2243 : 2186);
        expect(expectedLearningTargets, everyday2 ? 2299 : everyday ? 2210 : 2121);
        final allCards = {for (final c in await repo.selectionCards(await repo.allCardIds())) c.id:c};
        final projection = LearningGroups(allCards, {});
        final eligible = <String>{};
        var memberships = 0;
        var reuse = 0;
        final cutIds = <String>{};
        final cutSentences = <String>{};
        final hitIds = <String>{};
        final layIds = <String>{};
        final layLemmas = <String>{};
        final readIds = <String>{};
        final readSentences = <String>{};
        final putIds = <String>{};
        final setIds = <String>{};
        final runIds = <String>{};
        final runHomographIds = <String>{};
        final splitIds = <String>{};
        final spreadIds = <String>{};
        for (final deck in decks) {
          final targets = await repo.deckPracticeTargets(deck.id);
          for (final target in targets) {
            eligible.addAll(projection.project([target.cardId], exactForms:target.isForm));
          }
          if (deck.practiceKind == 'ordinary') continue;
          expect(targets, hasLength(formsPerView));
          expect(deck.cardCount, formsPerView);
          for (final target in targets) {
            memberships++;
            expect(target.isForm, isTrue);
            final card = allCards[target.cardId]!;
            if (card.introductionScope == 'ordinary') reuse++;
            final item = (await repo.practiceItems([card.id])).single;
            expect(item.sentences, hasLength(1));
            expect(item.sentences.single.sentenceId, expectedSentenceIds[card.id]);
            if (card.form == 'read') {
              readIds.add(card.id);
              readSentences.add(item.sentences.single.sentenceId);
            }
            if (card.form == 'put') putIds.add(card.id);
            if (card.form == 'set') setIds.add(card.id);
            if (card.lemma == 'run') runIds.add(card.id);
            if (card.form == 'run') runHomographIds.add(card.id);
            if (card.form == 'split') splitIds.add(card.id);
            if (card.form == 'spread') spreadIds.add(card.id);
            if (card.form == 'hit') hitIds.add(card.id);
            if (card.form == 'lay') {
              layIds.add(card.id);
              layLemmas.add(card.lemma);
            }
            if (card.form == 'cut') {
              cutIds.add(card.id);
              cutSentences.add(item.sentences.single.sentenceId);
            }
          }
        }
        expect(memberships, batch4 ? 402 : batch3 ? 303 : batch2 ? 204 : 99);
        expect(reuse, batch4 ? 71 : batch3 ? 53 : batch2 ? 38 : 16);
        expect(cutIds, hasLength(3));
        expect(cutSentences, hasLength(3));
        if (batch2 || batch3 || batch4) {
          expect(hitIds, hasLength(3));
          expect(layIds, hasLength(2));
          expect(layLemmas, unorderedEquals(['lay', 'lie']));
        }
        if (batch3 || batch4) {
          expect(readIds, hasLength(3));
          expect(readSentences, hasLength(3));
          expect(putIds, hasLength(3));
          expect(setIds, hasLength(3));
          expect(runIds, hasLength(3));
          expect(runHomographIds, hasLength(2));
        }
        if (batch4) {
          expect(splitIds, hasLength(3));
          expect(spreadIds, hasLength(3));
          final lexicalForms = allCards.values
              .where((c) => c.formFunction != null)
              .map((c) => c.lexicalTargetId).toSet();
          expect(lexicalForms, hasLength(134));
          expect(lexicalForms, isNot(contains(null)));
        }
        final keys = lexicalCountingKeys(allCards);
        expect(eligible, hasLength(everyday2 ? 2631 : everyday ? 2542 : batch4 ? 2453 : batch3 ? 2372 : batch2 ? 2288 : 2204));
        expect(eligible.map((id)=>keys[id]).toSet(), hasLength(everyday2 ? 2360 : everyday ? 2271 : batch4 ? 2182 : batch3 ? 2167 : batch2 ? 2149 : 2136));
        // Concrete lexical count checked against the repository diagnostic.
        // ignore: avoid_print
        print('SCHEMA4 mixed exercises=${eligible.length} lexical=${eligible.map((id)=>keys[id]).toSet().length}; $memberships forms / $reuse reuse / cut 3 identities PASS');
      }
      final cardIds = <String>[];
      for (final slug in expectedDeckCardIds.keys) {
        final deck = bySlug[slug]!;
        final ids = await repo.deckCardIds(deck.id);
        expect(ids, orderedEquals(expectedDeckCardIds[slug]!));
        if (deck.practiceKind == 'ordinary') {
        expect(
          (await repo.selectionCards(ids))
              .where((c) => c.introductionScope == 'ordinary')
              .map((c) => c.learningGroup).toSet(),
          hasLength(deck.cardCount),
        );
        }
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
        decks.where((d) => d.practiceKind == 'ordinary')
            .fold<int>(0, (sum, deck) => sum + deck.cardCount),
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
