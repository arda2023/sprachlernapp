import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sprachapp/data/content/bundled_content_updates.dart';
import 'package:sprachapp/data/content/content_database.dart';
import 'package:sprachapp/data/content/content_install_journal.dart';
import 'package:sprachapp/data/content/content_pack_installer.dart';
import 'package:sprachapp/data/content/context_revision_validation.dart';
import 'package:sprachapp/data/content/content_release_client.dart';
import 'package:sprachapp/data/content/content_update_service.dart';
import 'package:sprachapp/data/content/content_update_validation.dart';

import '../fixtures/portuguese_installation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late ContentInstallJournal journal;
  late Map<String, Uint8List> assets;
  late File previous;
  late List<int> previousBytes;

  Future<Map<String, Object>> update() => applyBundledContentUpdates(
    loadAsset: (key) async => assets[key],
    supportDirectory: root,
    languages: ['pt-BR'],
  );

  setUp(() async {
    root = Directory.systemTemp.createTempSync('bundled-update-');
    journal = ContentInstallJournal(root, 'pt-BR');
    final old = File('${root.path}/old.sqlite');
    final raw = sqlite3.open(old.path);
    raw.execute(
      File('test/fixtures/portuguese_release/first.sql').readAsStringSync(),
    );
    raw.execute("UPDATE content_releases SET version='synthetic_ptbr_1'");
    raw.close();
    previousBytes = old.readAsBytesSync();
    final manifest = ContentManifest(
      lang: 'pt-BR',
      version: 'synthetic_ptbr_1',
      schemaVersion: 5,
      sha256: sha256.convert(previousBytes).toString(),
      sizeBytes: previousBytes.length,
      internalTestPack: true,
    );
    previous = journal.bootstrapFile(manifest);
    await previous.parent.create(recursive: true);
    await old.copy(previous.path);
    await journal.write('active', {
      'bootstrap': true,
      'generation': 0,
      'manifest': jsonDecode(manifest.toJson()),
    });
    final release = PortugueseTransport(root);
    final bundle = release.offer.toJson();
    bundle['manifest'] = {
      ...release.offer.manifest,
      'origin': 'bundle',
      'cloud_generation': 0,
      'cloud_manifest_sha256': null,
    };
    bundle['manifest_sha256'] = contextCanonicalHash(bundle['manifest']);
    assets = {
      'assets/content/pt-BR/bundled-release.json': Uint8List.fromList(
        utf8.encode(jsonEncode(bundle)),
      ),
      for (final entry in release.files.entries)
        'assets/content/pt-BR/${entry.key}': Uint8List.fromList(entry.value),
    };
  });
  tearDown(() => root.deleteSync(recursive: true));

  test('offline bootstrap update retains historical rows and user data across restart', () async {
    final user = File('${root.path}/user.db')
      ..writeAsStringSync('opaque learner database is never opened');
    expect(await update(), isEmpty);
    expect((await journal.active())!.generation, 1);
    expect((await journal.read('install-journal'))!['state'], 'committed');
    expect(previous.readAsBytesSync(), previousBytes);
    expect(user.readAsStringSync(), 'opaque learner database is never opened');
    final installer = ContentPackInstaller(
      loadAsset: (key) async => assets[key],
      supportDirectory: root,
      lang: 'pt-BR',
      validationRegistry: await ProcessValidationRegistry.forAppSupport(root),
    );
    final repo = await installer.open();
    expect(repo.info.version, 'synthetic_ptbr_2');
    final old = sqlite3.open(previous.path, mode: OpenMode.readOnly);
    final now = sqlite3.open(
      (await journal.currentFile())!.path,
      mode: OpenMode.readOnly,
    );
    for (final table in [
      'cards',
      'sentences',
      'sentence_tokens',
      'card_sentences',
    ]) {
      final before = old
          .select('SELECT id FROM $table')
          .map((r) => r['id'])
          .toSet();
      final after = now
          .select('SELECT id FROM $table')
          .map((r) => r['id'])
          .toSet();
      expect(after.containsAll(before), true, reason: table);
    }
    old.close();
    now.close();
    await repo.close();
    final pointer = await journal.read('active');
    expect(await update(), isEmpty);
    expect(await journal.read('active'), pointer);
  });

  test('corrupt bundle leaves bootstrap and learner database intact', () async {
    assets['assets/content/pt-BR/content.sqlite'] = Uint8List.fromList([
      1,
      2,
      3,
    ]);
    final before = await journal.read('active');
    expect((await update()).keys, ['pt-BR']);
    expect(await journal.read('active'), before);
    expect(previous.readAsBytesSync(), previousBytes);
    expect(await journal.read('pending'), isNull);
  });

  test('missing history refuses offline activation', () async {
    assets.remove('assets/content/pt-BR/history_inventory.json');
    final before = await journal.read('active');
    expect((await update()).keys, ['pt-BR']);
    expect(await journal.read('active'), before);
  });

  test(
    'older app bundle does not downgrade a newer installed generation',
    () async {
      final key = 'assets/content/pt-BR/bundled-release.json';
      final original = assets[key]!;
      final envelope =
          jsonDecode(utf8.decode(original)) as Map<String, dynamic>;
      envelope['manifest']['generation'] = 2;
      envelope['manifest_sha256'] = contextCanonicalHash(envelope['manifest']);
      assets[key] = Uint8List.fromList(utf8.encode(jsonEncode(envelope)));
      expect(await update(), isEmpty);
      assets[key] = original;
      expect(await update(), isEmpty);
      expect((await journal.active())!.generation, 2);
    },
  );
  test(
    'valid cloud pack missing installed bundle history is rejected',
    () async {
      expect(await update(), isEmpty);
      final before = await journal.read('active');
      final candidate = Directory('${root.path}/earlier')..createSync();
      final file = File('${candidate.path}/content.sqlite');
      final raw = sqlite3.open(file.path);
      raw.execute(
        File('test/fixtures/portuguese_release/first.sql').readAsStringSync(),
      );
      raw.close();
      final inventoryFile = File(
        'test/fixtures/portuguese_release/first/history_inventory.json',
      ).copySync('${candidate.path}/history_inventory.json');
      final files = {
        'content.sqlite': file.readAsBytesSync(),
        'history_inventory.json': inventoryFile.readAsBytesSync(),
      };
      final manifest = jsonDecode(
        File('test/fixtures/portuguese_release/first/content.manifest.json')
            .readAsStringSync(),
      ) as Map<String, dynamic>;
      manifest.addAll({
        'generation': 1,
        'channel': 'internal',
        'release_id': '33333333-3333-4333-8333-333333333333',
        'sha256': sha256.convert(files['content.sqlite']!).toString(),
        'size_bytes': files['content.sqlite']!.length,
      });
      final remote = ReleaseOffer.parse({
        'manifest': manifest,
        'manifest_sha256': contextCanonicalHash(manifest),
        'objects': {
          for (final e in files.entries)
            e.key: {
              'sha256': sha256.convert(e.value).toString(),
              'size_bytes': e.value.length,
            },
        },
      }, 'pt-BR');
      // Candidate itself is valid: rejection below must come from missing history.
      validateDownloadedContent(file.path, remote.toJson(), null);
      final transport = _CloudTransport(remote, {
        for (final e in files.entries) 'assets/content/pt-BR/${e.key}': e.value,
      });
      final service = ContentUpdateService(
        journal,
        transport,
        currentFile: journal.currentFile,
        gate: ContentTransitionGate(),
        closeReaders: () async {},
        openReaders: () async {},
      );
      await service.check();
      await expectLater(
        service.download(),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'history rejection',
            contains('Historische Identitäten fehlen'),
          ),
        ),
      );
      expect(await journal.read('active'), before);
    },
  );

  test('remote parsing refuses bundled origin unless explicitly loading local state', () {
    final envelope = jsonDecode(
      utf8.decode(assets['assets/content/pt-BR/bundled-release.json']!),
    ) as Map<String, dynamic>;
    expect(() => ReleaseOffer.parse(envelope, 'pt-BR'), throwsFormatException);
    expect(
      ReleaseOffer.parse(envelope, 'pt-BR', allowBundled: true).isBundled,
      true,
    );
  });

  test(
    'cloud generation two follows bundle generation two using cloud cursor one',
    () async {
      const key = 'assets/content/pt-BR/bundled-release.json';
      final envelope =
          jsonDecode(utf8.decode(assets[key]!)) as Map<String, dynamic>;
      final baseManifest = {...(envelope['manifest'] as Map<String, dynamic>)}
        ..remove('origin')
        ..remove('cloud_generation')
        ..remove('cloud_manifest_sha256');
      final baseHash = contextCanonicalHash(baseManifest);
      envelope['manifest'] = {
        ...envelope['manifest'] as Map<String, dynamic>,
        'generation': 2,
        'cloud_generation': 1,
        'cloud_manifest_sha256': baseHash,
      };
      envelope['manifest_sha256'] = contextCanonicalHash(envelope['manifest']);
      assets[key] = Uint8List.fromList(utf8.encode(jsonEncode(envelope)));
      expect(await update(), isEmpty);
      final local = (await journal.active())!;
      expect(local.generation, 2);
      expect(local.cloudGeneration, 1);
      final remoteManifest = {
        ...baseManifest,
        'generation': 2,
        'release_id': '22222222-2222-4222-8222-222222222222',
      };
      final remote = ReleaseOffer.parse({
        ...envelope,
        'manifest': remoteManifest,
        'manifest_sha256': contextCanonicalHash(remoteManifest),
      }, 'pt-BR');
      final transport = _CloudTransport(remote, assets);
      final service = ContentUpdateService(
        journal,
        transport,
        currentFile: journal.currentFile,
        gate: ContentTransitionGate(),
        closeReaders: () async {},
        openReaders: () async {},
      );
      await service.check();
      expect(transport.cursors, [1]);
      expect(service.available!.id, remote.id);
      await service.download();
      await service.activate();
      expect(transport.cursors, [1, 1]);
      expect((await journal.active())!.isBundled, false);
      expect((await journal.active())!.generation, 2);
      // An older app bundle cannot replace the later cloud release.
      expect(await update(), isEmpty);
      expect((await journal.active())!.id, remote.id);
    },
  );

  test(
    'cloud check preserves same-generation hash gate after a bundle',
    () async {
      const key = 'assets/content/pt-BR/bundled-release.json';
      final envelope =
          jsonDecode(utf8.decode(assets[key]!)) as Map<String, dynamic>;
      envelope['manifest']['cloud_generation'] = 1;
      envelope['manifest']['cloud_manifest_sha256'] = 'a' * 64;
      envelope['manifest_sha256'] = contextCanonicalHash(envelope['manifest']);
      assets[key] = Uint8List.fromList(utf8.encode(jsonEncode(envelope)));
      expect(await update(), isEmpty);
      final cloudManifest = {...envelope['manifest'] as Map<String, dynamic>}
        ..remove('origin')
        ..remove('cloud_generation')
        ..remove('cloud_manifest_sha256');
      final remote = ReleaseOffer.parse({
        ...envelope,
        'manifest': cloudManifest,
        'manifest_sha256': contextCanonicalHash(cloudManifest),
      }, 'pt-BR');
      final transport = _CloudTransport(remote, assets);
      final service = ContentUpdateService(
        journal,
        transport,
        currentFile: journal.currentFile,
        gate: ContentTransitionGate(),
        closeReaders: () async {},
        openReaders: () async {},
      );
      await expectLater(service.check(), throwsFormatException);
      expect((await journal.active())!.isBundled, true);
      transport.offer = ReleaseOffer.parse(
        envelope,
        'pt-BR',
        allowBundled: true,
      );
      await expectLater(service.check(), throwsFormatException);
    },
  );
}

class _CloudTransport implements ContentReleaseTransport {
  _CloudTransport(this.offer, this.assets);
  ReleaseOffer offer;
  final Map<String, Uint8List> assets;
  final cursors = <int>[];
  @override
  Future<ReleaseOffer?> latest(String lang, int generation) async {
    cursors.add(generation);
    return offer;
  }

  @override
  Future<Map<String, Uri>> downloads(ReleaseOffer offer) async => {
    for (final name in ['content.sqlite', 'history_inventory.json'])
      name: Uri.parse('https://synthetic.invalid/$name'),
  };
  @override
  Stream<List<int>> bytes(Uri uri) async* {
    yield assets['assets/content/pt-BR/${uri.path.substring(1)}']!;
  }
}
