// tool/stage_content_pack.dart on the synthetic fixture: report checks,
// reproducible manifest, verification. No pipeline/out/.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/data/content/content_database.dart';

import '../../tool/stage_content_pack.dart';
import 'support.dart';

void main() {
  late Directory tmp;
  late Directory from;
  late Directory to;

  const counts = {
    'languages': 1,
    'lemmas': 3,
    'senses': 3,
    'cards': 5,
    'dictionary_forms': 6,
    'decks': 1,
    'deck_cards': 5,
    'sentences': 13,
    'sentence_tokens': 0,
    'card_sentences': 13,
    'stories': 0,
    'story_sentences': 0,
    'exercises': 0,
    'grammar_rules': 0,
    'audio_assets': 0,
    'content_releases': 1,
  };

  void writeReport({
    String status = 'ok',
    Map<String, int> tableCounts = counts,
  }) => File('${from.path}/finalization_report.json').writeAsStringSync(
    jsonEncode({
      'status': status,
      'internal_test_pack': true,
      'sqlite_counts': tableCounts,
    }),
  );

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('stage_');
    from = Directory('${tmp.path}/from')..createSync();
    to = Directory('${tmp.path}/assets/content/en');
    buildFixturePack(from, name: 'content.sqlite');
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  ContentManifest stage() => stageContentPack(
    from: from,
    to: to,
    lang: 'en',
    sourceLabel: 'from/content.sqlite',
  );

  test('stages a finalized pack with a verified, reproducible manifest', () {
    writeReport();
    final m = stage();
    final staged = File('${to.path}/content.sqlite');
    expect(sha256Of(staged), sha256Of(File('${from.path}/content.sqlite')));
    expect(m.sha256, sha256Of(staged));
    expect(m.version, 'mini-v1');
    expect(m.schemaVersion, 1);
    expect(m.internalTestPack, isTrue);
    expect(m.source['path'], 'from/content.sqlite');
    expect((m.source['table_counts'] as Map).length, counts.length);
    expect(File('${to.path}/content.sqlite.tmp').existsSync(), isFalse);

    final firstManifest = File('${to.path}/content.manifest.json')
        .readAsStringSync();
    stage();
    expect(
      File('${to.path}/content.manifest.json').readAsStringSync(),
      firstManifest,
    );
    expect(verifyStagedPack(to, lang: 'en').sha256, m.sha256);
  });

  test('refuses a report that is not ok', () {
    writeReport(status: 'failed');
    expect(
      stage,
      throwsA(
        isA<StageError>().having(
          (e) => e.message,
          'message',
          contains('"failed"'),
        ),
      ),
    );
    expect(File('${to.path}/content.sqlite').existsSync(), isFalse);
  });

  test('refuses table counts that differ from the report', () {
    writeReport(tableCounts: {...counts, 'cards': 164});
    expect(
      stage,
      throwsA(
        isA<StageError>().having(
          (e) => e.message,
          'message',
          contains('cards'),
        ),
      ),
    );
    writeReport(tableCounts: {...counts}..remove('audio_assets'));
    expect(stage, throwsA(isA<StageError>()));
  });

  test('refuses a pack the app could not read', () {
    writeReport();
    buildFixturePack(
      from,
      name: 'content.sqlite',
      tweak: (db) =>
          db.execute('UPDATE content_releases SET schema_version = 2'),
    );
    expect(
      stage,
      throwsA(
        isA<StageError>().having(
          (e) => e.message,
          'message',
          contains('Schema'),
        ),
      ),
    );
  });

  test('verification catches a changed asset', () {
    writeReport();
    stage();
    File('${to.path}/content.sqlite')
        .writeAsBytesSync([1, 2, 3], mode: FileMode.append);
    expect(() => verifyStagedPack(to, lang: 'en'), throwsA(isA<StageError>()));
  });
}
