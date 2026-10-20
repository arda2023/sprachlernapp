import 'package:sprachapp/data/user/user_database.dart';
import 'package:sprachapp/data/user/drift_user_repository.dart';
import 'package:sprachapp/domain/srs_state.dart';

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sprachapp/data/content/content_database.dart';
import 'package:sprachapp/data/content/content_install_journal.dart';
import 'package:sprachapp/data/content/content_pack_installer.dart';
import 'package:sprachapp/data/content/content_release_client.dart';
import 'package:sprachapp/data/content/content_update_service.dart';
import 'package:sprachapp/data/content/context_revision_validation.dart';

class _Transport implements ContentReleaseTransport {
  _Transport(this.offer, this.files);
  ReleaseOffer offer;
  Map<String, List<int>> files;
  bool interrupted = false, denied = false;
  @override
  Future<ReleaseOffer?> latest(String lang, int generation) async {
    if (denied) throw StateError('401');
    return generation >= offer.generation ? null : offer;
  }

  @override
  Future<Map<String, Uri>> downloads(ReleaseOffer offer) async => {
    for (final name in files.keys)
      name: Uri.parse('https://synthetic.invalid/$name'),
  };
  @override
  Stream<List<int>> bytes(Uri uri) async* {
    final data = files[uri.path.substring(1)]!;
    for (var n = 0; n < data.length; n += 4096) {
      yield data.sublist(n, (n + 4096).clamp(0, data.length));
      if (interrupted) throw StateError('network interrupted');
    }
  }
}

void main() {
  late Directory tmp;
  late ContentInstallJournal journal;
  late _Transport transport;
  late ContentUpdateService service;
  late ContentTransitionGate gate;
  var closes = 0, opens = 0;
  bool closeFails = false, openFails = false;
  setUp(() async {
    tmp = Directory.systemTemp.createTempSync('private-content-test-');
    journal = ContentInstallJournal(tmp, 'en');
    gate = ContentTransitionGate();
    closes = 0;
    opens = 0;
    closeFails = false;
    openFails = false;
    final file = File('${tmp.path}/fixture.sqlite');
    final db = sqlite3.open(file.path);
    db.execute(
      File('test/fixtures/private_release/content.sql').readAsStringSync(),
    );
    db.close();
    final files = {
      'content.sqlite': file.readAsBytesSync(),
      'history_inventory.json': File(
        'test/fixtures/private_release/history_inventory.json',
      ).readAsBytesSync(),
    };
    final m = jsonDecode(
      File('test/fixtures/private_release/content.manifest.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    m.remove('local_only');
    m.addAll({
      'release_id': '11111111-1111-4111-8111-111111111111',
      'channel': 'internal',
      'generation': 1,
      'parent_release_id': null,
      'parent_manifest_sha256': null,
      'sha256': sha256.convert(files['content.sqlite']!).toString(),
      'size_bytes': files['content.sqlite']!.length,
    });
    transport = _Transport(
      ReleaseOffer.parse({
        'manifest': m,
        'manifest_sha256': contextCanonicalHash(m),
        'objects': {
          for (final e in files.entries)
            e.key: {
              'sha256': sha256.convert(e.value).toString(),
              'size_bytes': e.value.length,
            },
        },
      }, 'en'),
      files,
    );
    service = ContentUpdateService(
      journal,
      transport,
      gate: gate,
      currentFile: () async => null,
      closeReaders: () async {
        closes++;
        if (closeFails) throw StateError('locked');
      },
      openReaders: () async {
        opens++;
        if (openFails) throw StateError('cannot open');
      },
    );
  });
  tearDown(() => tmp.deleteSync(recursive: true));
  test('streaming, full SQL inventory, session barrier, activation and offline restart', () async {
    final userFile = File('${tmp.path}/user.db');
    final user = DriftUserRepository(UserDatabase.file(userFile), lang: 'en');
    final now = DateTime.utc(2026, 10, 16);
    await user.ensureCards(
      ['historical-card'],
      now: now,
      origin: CardOrigin.deck,
    );
    await user.setCardFlags(
      'historical-card',
      favorite: true,
      note: 'Keep note',
      inPlaylist: true,
    );
    await user.recordReview(
      ReviewRecord(
        id: 'historical-review',
        cardId: 'historical-card',
        createdAt: now,
        mode: ReviewMode.deck,
        sentenceId: 'immutable-sentence-revision',
        firstAttemptCorrect: true,
        errorCount: 0,
        revealed: false,
        hintUsed: false,
        boxBefore: 0,
        boxAfter: 3,
        dueAtAfter: now.add(const Duration(days: 7)),
        responseMs: 10,
        appVersion: 'synthetic',
        deviceId: 'synthetic',
      ),
    );
    await user.close();
    final userBefore = await userFile.readAsBytes();
    await service.check();
    await service.download();
    expect(await journal.active(), isNull);
    final release = gate.acquire();
    await expectLater(service.activate(), throwsStateError);
    expect(closes, 0);
    release();
    await service.activate();
    expect(closes, 1);
    expect(opens, 1);
    final installer = ContentPackInstaller(
      loadAsset: (_) async => throw StateError('asset must not be read'),
      supportDirectory: tmp,
    );
    final reopened = await installer.install();
    expect(reopened.manifest.version, transport.offer.manifest['version']);
    expect((await journal.read('install-journal'))!['state'], 'committed');
    final repository = await installer.open();
    expect(await repository.allCardIds(), isNotEmpty);
    await repository.close();
    expect(await userFile.readAsBytes(), userBefore);
    final reopenedUser = DriftUserRepository(
      UserDatabase.file(userFile),
      lang: 'en',
    );
    expect(
      (await reopenedUser.reviewsFor('historical-card')).single.sentenceId,
      'immutable-sentence-revision',
    );
    expect(
      (await reopenedUser.cardStates([
        'historical-card',
      ]))['historical-card']!.box,
      3,
    );
    await reopenedUser.close();
  });
  test('interrupted/hash mismatched download never creates active or ready generation', () async {
    await service.check();
    transport.interrupted = true;
    await expectLater(service.download(), throwsStateError);
    expect(await journal.active(), isNull);
    expect(await journal.generation(transport.offer.id).exists(), isFalse);
    transport.interrupted = false;
    transport.files['content.sqlite']![100] ^= 1;
    await expectLater(service.download(), throwsFormatException);
    expect(await journal.active(), isNull);
  });
  test(
    'unsupported profile/schema and manifest changes rejected before transfer',
    () {
      for (final change in [
        {'schema_version': 6},
        {'profile_id': 'not-supported'},
        {'lang': 'qaa'},
      ]) {
        final m = {...transport.offer.manifest, ...change};
        expect(
          () => ReleaseOffer.parse({
            ...transport.offer.toJson(),
            'manifest': m,
            'manifest_sha256': contextCanonicalHash(m),
          }, 'en'),
          throwsFormatException,
        );
      }
      expect(
        () => ReleaseOffer.parse({
          ...transport.offer.toJson(),
          'manifest_sha256': '0' * 64,
        }, 'en'),
        throwsFormatException,
      );
    },
  );
  test(
    'close failure and expired authorization leave pointer untouched',
    () async {
      await service.check();
      await service.download();
      closeFails = true;
      await expectLater(service.activate(), throwsStateError);
      expect(await journal.active(), isNull);
      closeFails = false;
      transport.denied = true;
      await expectLater(service.activate(), throwsStateError);
      expect(await journal.active(), isNull);
    },
  );
  test('crash before/after pointer swap and committed corruption have distinct recovery', () async {
    await service.check();
    await service.download();
    await journal.prepare(transport.offer);
    expect(await recoverContentInstallation(journal), isNull);
    await journal.write('active', transport.offer.toJson());
    expect((await recoverContentInstallation(journal))!.id, transport.offer.id);
    expect((await journal.read('install-journal'))!['state'], 'committed');
    await File('${journal.generation(transport.offer.id).path}/content.sqlite')
        .writeAsBytes([1, 2]);
    await expectLater(
      recoverContentInstallation(journal),
      throwsFormatException,
    );
    expect(await journal.named('active').exists(), isTrue);
  });
  test('uncommitted broken candidate restores previous pointer, no user data touched', () async {
    await service.check();
    await service.download();
    await journal.prepare(transport.offer);
    await journal.write('active', transport.offer.toJson());
    await File('${journal.generation(transport.offer.id).path}/content.sqlite')
        .writeAsBytes([0]);
    expect(await recoverContentInstallation(journal), isNull);
    expect(await journal.active(), isNull);
  });
  test('forward repair uses authenticated inventory and never downgrades committed state', () async {
    await service.check();
    await service.download();
    await service.activate();
    final first = transport.offer;
    final userFile = File('${tmp.path}/user.db')
      ..writeAsStringSync('untouched learner state');
    final path = File('${journal.generation(first.id).path}/content.sqlite');
    await path.writeAsBytes([1, 2]);
    final source = File('${tmp.path}/fixture.sqlite');
    final raw = sqlite3.open(source.path);
    raw.execute("UPDATE content_releases SET version='synthetic-repair-v2'");
    raw.close();
    transport.files['content.sqlite'] = source.readAsBytesSync();
    final m = {
      ...first.manifest,
      'version': 'synthetic-repair-v2',
      'generation': 2,
      'release_id': '33333333-3333-4333-8333-333333333333',
      'sha256': sha256.convert(transport.files['content.sqlite']!).toString(),
      'size_bytes': transport.files['content.sqlite']!.length,
      'parent_release_id': first.id,
      'parent_manifest_sha256': first.manifestHash,
    };
    transport.offer = ReleaseOffer.parse({
      'manifest': m,
      'manifest_sha256': contextCanonicalHash(m),
      'objects': {
        for (final e in transport.files.entries)
          e.key: {
            'sha256': sha256.convert(e.value).toString(),
            'size_bytes': e.value.length,
          },
      },
    }, 'en');
    final repair = ContentUpdateService(
      journal,
      transport,
      currentFile: journal.currentFile,
      gate: gate,
      closeReaders: () async {},
      openReaders: () async {},
    );
    await repair.check();
    await repair.download();
    await repair.activate();
    expect((await recoverContentInstallation(journal))!.generation, 2);
    expect(userFile.readAsStringSync(), 'untouched learner state');
    await journal.write('active', first.toJson());
    await expectLater(
      recoverContentInstallation(journal),
      throwsFormatException,
    );
  });
  test(
    'open failure before user access restores old pointer and can retry',
    () async {
      await service.check();
      await service.download();
      openFails = true;
      await expectLater(service.activate(), throwsStateError);
      expect(await journal.active(), isNull);
      openFails = false;
      await service.activate();
      expect((await journal.active())!.generation, 1);
    },
  );
  test('journal write failure reopens previous readers without changing active pointer', () async {
    await service.check();
    await service.download();
    final obstruction = Directory(
      '${journal.named('install-journal').path}.tmp',
    );
    await obstruction.create();
    await expectLater(service.activate(), throwsA(isA<FileSystemException>()));
    expect(closes, 1);
    expect(opens, 1);
    expect(await journal.active(), isNull);
    await obstruction.delete();
    await service.activate();
    expect((await journal.active())!.generation, 1);
  });
  test('historical identity loss and executable SQLite objects are rejected even with matching byte hashes', () async {
    final old = File('${tmp.path}/old.sqlite');
    await File('${tmp.path}/fixture.sqlite').copy(old.path);
    final raw = sqlite3.open(old.path);
    raw.execute(
      "INSERT INTO audio_assets (id,lang,owner_kind,owner_id) VALUES ('historical-audio','en','card','historical-card')",
    );
    raw.close();
    final guarded = ContentUpdateService(
      journal,
      transport,
      currentFile: () async => old,
      gate: gate,
      closeReaders: () async {},
      openReaders: () async {},
    );
    await guarded.check();
    await expectLater(guarded.download(), throwsFormatException);
    expect(await journal.active(), isNull);
    final source = File('${tmp.path}/fixture.sqlite');
    final malicious = sqlite3.open(source.path);
    malicious.execute('CREATE VIEW unexpected AS SELECT * FROM cards');
    malicious.close();
    transport.files['content.sqlite'] = source.readAsBytesSync();
    final m = {
      ...transport.offer.manifest,
      'sha256': sha256.convert(transport.files['content.sqlite']!).toString(),
      'size_bytes': transport.files['content.sqlite']!.length,
    };
    transport.offer = ReleaseOffer.parse({
      'manifest': m,
      'manifest_sha256': contextCanonicalHash(m),
      'objects': {
        for (final e in transport.files.entries)
          e.key: {
            'sha256': sha256.convert(e.value).toString(),
            'size_bytes': e.value.length,
          },
      },
    }, 'en');
    await service.check();
    await expectLater(service.download(), throwsFormatException);
    expect(await journal.active(), isNull);
  });
  test('offline bootstrap remains usable', () async {
    final file = File('${tmp.path}/legacy.sqlite');
    final db = sqlite3.open(file.path);
    db.execute(
      File('test/fixtures/editor_context_before.sql').readAsStringSync(),
    );
    db.close();
    final raw = file.readAsBytesSync();
    final db2 = sqlite3.open(file.path, mode: OpenMode.readOnly);
    final info = validateContentSchema(db2, lang: 'en');
    db2.close();
    final manifest = jsonEncode({
      'format': 1,
      'lang': 'en',
      'version': info.version,
      'schema_version': info.schemaVersion,
      'sha256': sha256.convert(raw).toString(),
      'size_bytes': raw.length,
      'internal_test_pack': true,
    });
    final installer = ContentPackInstaller(
      supportDirectory: tmp,
      loadAsset: (name) async => name.endsWith('.sqlite')
          ? raw
          : Uint8List.fromList(utf8.encode(manifest)),
    );
    expect((await installer.install()).manifest.version, info.version);
  });
}
