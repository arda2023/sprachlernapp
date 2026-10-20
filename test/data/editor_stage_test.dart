import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../tool/stage_content_pack.dart';
import '../../tool/editor_content_pack.dart';

void main() {
  test(
    'schema5 export uses actual Dart reader and explicit temporary staging',
    () async {
      final dir = Directory.systemTemp.createTempSync('editor-stage-test-');
      try {
        final bundle = Directory('${dir.path}/bundle')..createSync();
        final db = sqlite3.open('${bundle.path}/content.sqlite');
        db.execute(
          File('test/fixtures/editor_context_after.sql').readAsStringSync(),
        );
        final names = db
            .select("SELECT name FROM sqlite_master WHERE type='table'")
            .map((r) => r['name'] as String)
            .toList();
        final counts = {
          for (final name in names)
            name: db.select('SELECT COUNT(*) AS n FROM "$name"').single['n'],
        };
        db.close();
        expect(counts, hasLength(23));
        File('${bundle.path}/finalization_report.json').writeAsStringSync(
          jsonEncode({
            'status': 'ok',
            'internal_test_pack': true,
            'sqlite_counts': counts,
          }),
        );
        final report = await inspectEditorPack(
          File('${bundle.path}/content.sqlite'),
          'en',
        );
        expect(report['schema_version'], 5);
        expect(report['story_corrections'], hasLength(3));
        final asset = Directory('${dir.path}/assets');
        expect(asset.existsSync(), isFalse);
        final manifest = stageContentPack(
          from: bundle,
          to: asset,
          lang: 'en',
          sourceLabel: 'synthetic-editor-test',
        );
        expect(manifest.schemaVersion, 5);
        expect(verifyStagedPack(asset, lang: 'en').sha256, manifest.sha256);
        expect(
          (await inspectEditorPack(
            File('${asset.path}/content.sqlite'),
            'en',
          ))['historical'],
          report['historical'],
        );
      } finally {
        dir.deleteSync(recursive: true);
      }
    },
  );
}
