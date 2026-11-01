import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/data/offline_translation/offline_dictionary.dart';
import 'package:sprachapp/data/offline_translation/dictionary_selection.dart';

void main() {
  test(
    'real corpus: safe general noun gloss, ambiguous senses and forms abstain',
    () async {
      final dir = Directory.systemTemp.createTempSync('dictionary-selection');
      addTearDown(() => dir.deleteSync(recursive: true));
      final dictionary = OfflineDictionary(
        directory: () async => dir,
        asset: (name) => File('assets/offline_dictionary/$name').readAsBytes(),
      );
      for (final row in [
        ('en', 'cat', 'Katze'),
        ('pt-BR', 'coração', 'Herz'),
        ('pt-BR', 'oxigênio', 'Sauerstoff'),
        // Dictionary first (01.11.2026): the first sense's short terms.
        ('en', 'bank', 'Bank'),
        ('en', 'arrived', 'ankommen, eintreffen'),
        ('en', 'destroyed', 'zerstören'),
        ('en', 'wall', 'die Mauer, die Wand'),
        ('en', 'glass', 'Glas'),
        ('en', 'neighbourhood', 'Nachbarschaft'),
        ('en', 'serious', 'ernst'),
        // A definition instead of a translation, a name, nothing: the AI.
        ('en', 'hole', null),
        ('en', 'machine', null),
        ('en', 'cash', null),
        ('pt-BR', 'do', null),
        ('pt-BR', 'na', null),
        ('en', 'banana', null),
        ('pt-BR', 'coracao', null),
      ]) {
        expect(
          singleDictionaryTranslation(
            row.$2,
            await dictionary.lookup(row.$1, row.$2),
          ),
          row.$3,
          reason: row.$2,
        );
      }
      expect(
        singleDictionaryTranslation(
          'corac\u0327a\u0303o',
          await dictionary.lookup('pt-BR', 'corac\u0327a\u0303o'),
        ),
        'Herz',
      );
    },
  );
  test('short leading terms only; names, restricted senses and definitions abstain', () {
    DictionaryCandidate candidate(
      String gloss, {
      String pos = 'Substantiv',
      String via = '',
      String tags = '',
    }) => DictionaryCandidate('sample', pos, gloss, tags, '', via);
    for (final item in [
      candidate('mit mehreren Bedeutungen; Bank'),
      candidate('Stelle in einer Masse, an der Substanz fehlt'),
      candidate('Katze', tags: 'slang'),
      candidate('Katze', tags: 'Kalender'),
      candidate('englischer Familienname', pos: 'Nachname'),
      candidate('3 Uhr'),
    ]) {
      expect(singleDictionaryTranslation('sample', [item]), isNull);
    }
    expect(
      singleDictionaryTranslation('sample', [candidate('Bank, Ufer')]),
      'Bank, Ufer',
    );
    expect(
      singleDictionaryTranslation('sample', [
        candidate('gehen, fahren, laufen'),
      ]),
      'gehen, fahren',
    );
    expect(
      singleDictionaryTranslation('sample', [
        candidate('Glas (das Material), Becher'),
      ]),
      'Glas, Becher',
    );
    expect(
      singleDictionaryTranslation('sample', [candidate('Katze', via: 'form')]),
      'Katze',
    );
    // The article wins over the homonymous adverb.
    expect(
      singleDictionaryTranslation('the', [
        candidate('desto, umso', pos: 'Adverb'),
        candidate('der, die, das', pos: 'Artikel'),
      ]),
      'der, die',
    );
    // A restricted first sense is skipped, the next plain one decides.
    expect(
      singleDictionaryTranslation('sample', [
        candidate('Kater', tags: 'colloquial'),
        candidate('Katze'),
      ]),
      'Katze',
    );
    final item = candidate('Katze');
    expect(
      singleDictionaryTranslation('sample', List.filled(80, item)),
      isNull,
    );
  });
}
