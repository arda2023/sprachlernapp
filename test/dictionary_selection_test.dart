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
        ('en', 'bank', null),
        ('en', 'arrives', null),
        ('en', 'went', null),
        ('pt-BR', 'fui', null),
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
  test('one entry alone is insufficient; embedded alternatives, restrictions and forms rejected', () {
    DictionaryCandidate candidate(
      String gloss, {
      String pos = 'Substantiv',
      String via = '',
      String tags = '',
    }) => DictionaryCandidate('sample', pos, gloss, tags, '', via);
    for (final item in [
      candidate('Bank, Ufer'),
      candidate('mit mehreren Bedeutungen; Bank'),
      candidate('gehen', pos: 'Verb'),
      candidate('Katze', via: 'form'),
      candidate('Katze', tags: 'slang'),
    ]) {
      expect(singleDictionaryTranslation('sample', [item]), isNull);
    }
    final item = candidate('Katze');
    expect(singleDictionaryTranslation('sample', [item, item]), 'Katze');
    expect(
      singleDictionaryTranslation('sample', List.filled(80, item)),
      isNull,
    );
  });
}
