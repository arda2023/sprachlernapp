import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sprachapp/data/content/content_database.dart';
import 'package:sprachapp/data/content/content_release_client.dart';
import 'package:sprachapp/data/content/context_revision_validation.dart';
import 'package:sprachapp/data/content/drift_content_repository.dart';
import 'package:sprachapp/domain/language_profile.dart';

void main() {
  test(
    'exact BR profile agrees with Python manifest; English stays frozen',
    () {
      final manifest = jsonDecode(
        File('test/fixtures/portuguese_release/profile.json')
            .readAsStringSync(),
      );
      expect(
        contextCanonicalHash(manifest),
        ContentLanguageProfile.portugueseBrazil.sha256,
      );
      expect(ContentLanguageProfile.forLanguage('pt-BR')!.id, manifest['id']);
      for (final lang in ['pt', 'pt-PT', 'pt-br']) {
        expect(ContentLanguageProfile.forLanguage(lang), isNull);
      }
      expect(
        ContentLanguageProfile.english.sha256,
        '59eec37d0a4f322d666701e00bc1bf4cfb44d19b183b1742d16b443989a505cf',
      );
    },
  );
  test('release offers reject another language or a mismatched profile', () {
    final m = jsonDecode(
      File('test/fixtures/portuguese_release/first/content.manifest.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    m.addAll({
      'release_id': '11111111-1111-4111-8111-111111111111',
      'channel': 'internal',
      'generation': 1,
    });
    Map<String, dynamic> offer() => {
      'manifest': m,
      'manifest_sha256': contextCanonicalHash(m),
      'objects': {
        for (final name in ['content.sqlite', 'history_inventory.json'])
          name: {'sha256': m['sha256'], 'size_bytes': m['size_bytes']},
      },
    };
    expect(ReleaseOffer.parse(offer(), 'pt-BR').lang, 'pt-BR');
    expect(() => ReleaseOffer.parse(offer(), 'en'), throwsFormatException);
    m['profile_sha256'] = ContentLanguageProfile.english.sha256;
    expect(() => ReleaseOffer.parse(offer(), 'pt-BR'), throwsFormatException);
  });
  test(
    'real BR Reader preserves historical context and converts Unicode offsets',
    () async {
      final dir = Directory.systemTemp.createTempSync('ptbr-reader-');
      final file = File('${dir.path}/content.sqlite');
      final raw = sqlite3.open(file.path);
      raw.execute(
        File('test/fixtures/portuguese_release/second.sql').readAsStringSync(),
      );
      validateContextRevisions(raw, lang: 'pt-BR');
      raw.close();
      final repo = DriftContentRepository(
        ContentDatabase.open(file, lang: 'pt-BR'),
      );
      try {
        final ids = await repo.allCardIds();
        final current = (await repo.practiceItems(ids.toList())).single;
        expect(current.card.form, 'ação');
        expect(current.practiceSentence.gapStart, 6);
        expect(current.practiceSentence.gapEnd, 10);
        expect(
          current.practiceSentence.translationDe,
          'Zweite synthetische Testrevision.',
        );
        final first = jsonDecode(
          File('test/fixtures/portuguese_release/first/reader_report.json')
              .readAsStringSync(),
        );
        final old = await repo.historicalSentence(
          current.card.id,
          first['current'][0]['sentence']['sentence_id'] as String,
        );
        expect(
          old!.translationDe,
          'Synthetischer Test, keine Übersetzungsfreigabe.',
        );
        expect(old.tokens.map((t) => t.surface), [
          '😀',
          'Na',
          'ação',
          'do',
          'teste',
          '.',
        ]);
      } finally {
        await repo.close();
        dir.deleteSync(recursive: true);
      }
    },
  );
}
