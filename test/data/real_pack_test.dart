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
    late int expectedLinks;
    late int expectedAlternatives;
    try {
      expectedCards =
          raw
                  .select(
                    'SELECT count(*) AS n FROM cards WHERE removed_in IS NULL',
                  )
                  .single['n']
              as int;
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
      final cardIds = await repo.deckCardIds(decks.single.id);
      final items = await repo.practiceItems(cardIds);
      final sentences = items.expand((i) => i.sentences).toList();
      final withAlternatives = sentences.where(
        (s) => s.validAlternatives.isNotEmpty,
      );

      // ignore: avoid_print
      print(
        'pack ${repo.info.version} (schema ${repo.info.schemaVersion}, '
        'internal: ${repo.info.isInternalTestPack}); deck "${decks.single.titleDe}": '
        '${cardIds.length} cards, ${sentences.length} card sentences, '
        '${withAlternatives.length} with valid_alternatives, '
        '${(await repo.allCardIds()).length} cards in the pack',
      );

      expect(decks.single.slug, 'allgemeine-sprache');
      expect(expectedCards, greaterThan(0));
      expect(expectedLinks, expectedCards * 3);
      expect(decks.single.cardCount, expectedCards);
      expect(cardIds, hasLength(expectedCards));
      expect(cardIds.toSet(), hasLength(expectedCards));
      expect(items, hasLength(expectedCards));
      expect(sentences, hasLength(expectedLinks));
      expect(
        sentences.map((s) => s.sentenceId).toSet(),
        hasLength(expectedLinks),
      );
      expect(items.every((i) => i.sentences.length == 3), isTrue);
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
