// Explicit local install/restart probes using actual release assets.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/data/content/bundled_content_updates.dart';
import 'package:sprachapp/data/content/content_database.dart';
import 'package:sprachapp/data/content/content_install_journal.dart';
import 'package:sprachapp/data/content/content_pack_installer.dart';
import 'package:sprachapp/data/content/context_revision_validation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const multilingual = bool.fromEnvironment('VERIFY_MULTILINGUAL_COLD_START');
  test(
    'all four real releases cold install and unchanged restart',
    () async {
      const languages = ['pt-BR', 'nb', 'it', 'es'];
      final root = Directory.systemTemp.createTempSync('real-cold-start-all-');
      addTearDown(() => root.deleteSync(recursive: true));
      final reads = <String, int>{};
      Future<Uint8List?> load(String key) async {
        reads.update(key, (n) => n + 1, ifAbsent: () => 1);
        final file = File(key);
        return await file.exists() ? file.readAsBytes() : null;
      }

      for (final lang in languages) {
        for (final name in [
          'content.sqlite',
          'history_inventory.json',
          'content.manifest.json',
          'bundled-release.json',
        ]) {
          expect(File('assets/content/$lang/$name').existsSync(), true);
        }
      }
      final watch = Stopwatch()..start();
      expect(
        await applyBundledContentUpdates(
          loadAsset: load,
          supportDirectory: root,
        ),
        isEmpty,
      );
      final firstMs = watch.elapsedMilliseconds;
      final registry = await ProcessValidationRegistry.forAppSupport(root);
      final active = <String, Object?>{};
      final verified = <String, Object>{};
      for (final lang in languages) {
        final repo = await ContentPackInstaller(
          loadAsset: load,
          supportDirectory: root,
          lang: lang,
          validationRegistry: registry,
        ).open();
        try {
          final ids = await repo.allCardIds();
          final decks = await repo.decks();
          expect(ids.length, 3830, reason: lang);
          expect(decks.length, 14, reason: lang);
          expect(decks.fold(0, (n, deck) => n + deck.cardCount), 3830);
          verified[lang] = {'decks': decks.length, 'cards': ids.length};
        } finally {
          await repo.close();
        }
        active[lang] = await ContentInstallJournal(root, lang).read('active');
        expect(active[lang], isNotNull);
      }

      reads.clear();
      watch.reset();
      expect(
        await applyBundledContentUpdates(
          loadAsset: load,
          supportDirectory: root,
        ),
        isEmpty,
      );
      final restartMs = watch.elapsedMilliseconds;
      for (final lang in languages) {
        expect(
          await ContentInstallJournal(root, lang).read('active'),
          active[lang],
        );
      }
      expect(reads.keys.any((key) => key.endsWith('content.sqlite')), false);
      expect(
        reads.keys.any((key) => key.endsWith('history_inventory.json')),
        false,
      );
      final result = {
        'verified_at_utc': DateTime.now().toUtc().toIso8601String(),
        'languages': verified,
        'cold_install_ms': firstMs,
        'unchanged_restart_ms': restartMs,
        'restart_asset_reads': reads,
        'measurement_environment': 'desktop Flutter test, not device benchmark',
      };
      final output = File(
        'build/multilingual-verification/cold-start-result.json',
      );
      output.parent.createSync(recursive: true);
      output.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(result),
      );
      // ignore: avoid_print
      print(jsonEncode(result));
    },
    skip: multilingual ? false : 'Explicit real all-language install probe.',
    timeout: const Timeout(Duration(minutes: 3)),
  );
  test(
    'real release cold install and unchanged restart',
    () async {
      const source = 'editorial_review/multilingual_decks_20261027';
      const full = bool.fromEnvironment('VERIFY_PORTUGUESE_FULL_COLD_START');
      const bundle = full
          ? 'assets/content/pt-BR'
          : '$source/verification/pt-BR-262-v3-r2/bundle';
      final root = Directory.systemTemp.createTempSync('real-cold-start-');
      addTearDown(() => root.deleteSync(recursive: true));
      final cloud = (jsonDecode(
        File('$source/portuguese-cloud-base.json').readAsStringSync(),
      ) as List).single;
      final manifest = jsonDecode(
        File('$bundle/content.manifest.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      // Offline routing envelope only. Actual SQLite and inventory stay unchanged.
      manifest.addAll({
        'release_id': '204c2775-88c7-42f1-992a-1412b147902a',
        'generation': 1,
        'origin': 'bundle',
        'channel': 'internal',
        'cloud_generation': cloud['generation'],
        'cloud_manifest_sha256': cloud['manifest_sha256'],
        'parent_release_id': cloud['release_id'],
        'parent_manifest_sha256': cloud['manifest_sha256'],
        'created_at': '2026-10-27T12:00:00Z',
      });
      final bytes = <String, Uint8List>{
        for (final name in [
          'content.sqlite',
          'history_inventory.json',
          'content.manifest.json',
        ])
          name: File('$bundle/$name').readAsBytesSync(),
      };
      bytes['bundled-release.json'] = Uint8List.fromList(
        utf8.encode(
          jsonEncode({
            'manifest': manifest,
            'manifest_sha256': contextCanonicalHash(manifest),
            'objects': {
              for (final name in ['content.sqlite', 'history_inventory.json'])
                name: {
                  'sha256': sha256.convert(bytes[name]!).toString(),
                  'size_bytes': bytes[name]!.length,
                },
            },
          }),
        ),
      );
      if (full) {
        bytes['bundled-release.json'] = File('$bundle/bundled-release.json')
            .readAsBytesSync();
      }
      final reads = <String, int>{};
      Future<Uint8List?> load(String key) async {
        reads.update(key, (n) => n + 1, ifAbsent: () => 1);
        return key.startsWith('assets/content/pt-BR/')
            ? bytes[key.split('/').last]
            : null;
      }

      final watch = Stopwatch()..start();
      expect(
        await applyBundledContentUpdates(
          loadAsset: load,
          supportDirectory: root,
        ),
        isEmpty,
      );
      final firstMs = watch.elapsedMilliseconds;
      final installer = ContentPackInstaller(
        loadAsset: load,
        supportDirectory: root,
        lang: 'pt-BR',
        validationRegistry: await ProcessValidationRegistry.forAppSupport(root),
      );
      final repo = await installer.open();
      expect((await repo.allCardIds()).length, full ? 3830 : 282);
      final decks = await repo.decks();
      expect(
        decks.singleWhere((d) => d.slug == 'alltag-zuhause').cardCount,
        262,
      );
      await repo.close();
      final journal = ContentInstallJournal(root, 'pt-BR');
      final before = await journal.read('active');
      reads.clear();
      watch.reset();
      expect(
        await applyBundledContentUpdates(
          loadAsset: load,
          supportDirectory: root,
        ),
        isEmpty,
      );
      final restartMs = watch.elapsedMilliseconds;
      expect(await journal.read('active'), before);
      expect(reads.keys.any((key) => key.endsWith('content.sqlite')), false);
      expect(
        reads.keys.any((key) => key.endsWith('history_inventory.json')),
        false,
      );
      // A timeout bounds hangs; these timings are desktop test measurements, not iPhone benchmarks.
      // ignore: avoid_print
      print(
        jsonEncode({
          'real_cards': full ? 3830 : 282,
          'cold_install_ms': firstMs,
          'unchanged_restart_ms': restartMs,
          'restart_asset_reads': reads,
        }),
      );
    },
    skip:
        (const bool.fromEnvironment('VERIFY_PORTUGUESE_PARTIAL_COLD_START') ||
            const bool.fromEnvironment('VERIFY_PORTUGUESE_FULL_COLD_START'))
        ? false
        : 'Explicit real partial-release probe.',
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
