import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sprachapp/data/content/content_database.dart';
import 'package:sprachapp/data/content/content_release_client.dart';
import 'package:sprachapp/data/content/content_update_validation.dart';
import 'package:sprachapp/data/content/context_revision_validation.dart';
import 'package:sprachapp/presentation/providers/database_providers.dart';

void main() {
  late Directory temp;
  late Directory snapshots;
  late File source, inventory;
  late ReleaseOffer offer;
  late ProcessValidationRegistry registry;
  late Map<ValidationStage, int> calls;
  Future<void> Function(ValidationStage)? hook;

  ReleaseOffer makeOffer({
    int generation = 1,
    Map<String, dynamic> changes = const {},
  }) {
    final manifest = jsonDecode(
      File('test/fixtures/private_release/content.manifest.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    manifest.remove('local_only');
    manifest.addAll({
      'release_id':
          '${generation.toString().padLeft(8, '0')}-1111-4111-8111-111111111111',
      'channel': 'internal',
      'generation': generation,
      'parent_release_id': null,
      'parent_manifest_sha256': null,
      'sha256': sha256.convert(source.readAsBytesSync()).toString(),
      'size_bytes': source.lengthSync(),
      ...changes,
    });
    return ReleaseOffer.parse({
      'manifest': manifest,
      'manifest_sha256': contextCanonicalHash(manifest),
      'objects': {
        for (final entry in {
          'content.sqlite': source,
          'history_inventory.json': inventory,
        }.entries)
          entry.key: {
            'sha256': sha256.convert(entry.value.readAsBytesSync()).toString(),
            'size_bytes': entry.value.lengthSync(),
          },
      },
    }, 'en');
  }

  InstalledReadRequest request({
    ReleaseOffer? release,
    InstalledReadMode mode = InstalledReadMode.normalInstalled,
    ReadCancellation? cancellation,
    Future<bool> Function(GenerationIdentity)? confirm,
  }) => InstalledReadRequest(
    identity: GenerationIdentity.fromOffer(release ?? offer),
    contentFile: source,
    inventoryFile: inventory,
    mode: mode,
    cancellation: cancellation,
    confirmCurrent: confirm ?? (_) async => true,
  );
  Future<ContentDatabase> open({InstalledReadRequest? read}) async =>
      ContentDatabase.fromBoundReader(
        await registry.openBoundReader(read ?? request()),
      );
  Future<List<String>> ids(ContentDatabase db) async =>
      (await db.customSelect('SELECT id FROM cards ORDER BY id').get())
          .map((r) => r.read<String>('id'))
          .toList();
  Future<void> noResources() async {
    expect(registry.readerReservations, 0);
    expect(snapshots.existsSync() ? snapshots.listSync() : [], isEmpty);
  }

  void changeSameLength(File file) {
    final mtime = file.lastModifiedSync();
    final bytes = file.readAsBytesSync();
    bytes[bytes.length ~/ 2] ^= 1;
    file.writeAsBytesSync(bytes);
    file.setLastModifiedSync(mtime);
    expect(file.lengthSync(), bytes.length);
    expect(file.lastModifiedSync(), mtime);
  }

  setUp(() {
    temp = Directory.systemTemp.createTempSync('bound-reader-test-');
    snapshots = Directory('${temp.path}/readers');
    source = File('${temp.path}/content.sqlite');
    final raw = sqlite3.open(source.path);
    raw.execute(
      File('test/fixtures/private_release/content.sql').readAsStringSync(),
    );
    raw.close();
    inventory = File('test/fixtures/private_release/history_inventory.json')
        .copySync('${temp.path}/history_inventory.json');
    offer = makeOffer();
    calls = {};
    hook = null;
    registry = ProcessValidationRegistry(
      snapshots,
      onStage: (stage) async {
        calls.update(stage, (n) => n + 1, ifAbsent: () => 1);
        await hook?.call(stage);
      },
    );
  });
  tearDown(() => temp.deleteSync(recursive: true));

  test(
    'cold once, warm hashes twice, identical results and read-only connection',
    () async {
      final first = await open();
      final expected = await ids(first);
      expect(expected, isNotEmpty);
      await expectLater(
        first.customStatement('DELETE FROM cards'),
        throwsA(anything),
      );
      await first.close();
      final second = await open();
      expect(await ids(second), expected);
      expect(calls[ValidationStage.fullValidation], 1);
      expect(calls[ValidationStage.contentHash], 2);
      expect(calls[ValidationStage.inventoryHash], 2);
      expect(calls[ValidationStage.integrity], 2);
      expect(calls[ValidationStage.handshake], 2);
      expect(registry.proofCount, 1);
      await second.close();
      await second.close();
      await noResources();
    },
  );

  test(
    'caller-owned validator handle remains usable on success and failure',
    () {
      final raw = sqlite3.open(source.path);
      final data =
          jsonDecode(inventory.readAsStringSync()) as Map<String, dynamic>;
      final info = validateDownloadedDatabase(raw, offer, data);
      expect(info.version, offer.manifest['version']);
      expect(raw.select('SELECT id FROM cards'), isNotEmpty);
      expect(
        () =>
            validateDownloadedDatabase(raw, offer, {...data, 'lang': 'pt-BR'}),
        throwsFormatException,
      );
      expect(raw.select('SELECT 1').single.values.single, 1);
      raw.close();
    },
  );

  for (final name in ['SQLite', 'inventory']) {
    test(
      '$name same-size same-mtime corruption invalidates warm proof',
      () async {
        await (await open()).close();
        changeSameLength(name == 'SQLite' ? source : inventory);
        await expectLater(open(), throwsA(anything));
        expect(registry.proofCount, 0);
        await noResources();
      },
    );
  }

  test(
    'matching fresh hashes do not admit executable schema fixture',
    () async {
      final raw = sqlite3.open(source.path);
      raw.execute('CREATE VIEW unexpected AS SELECT * FROM cards');
      raw.close();
      offer = makeOffer();
      await expectLater(open(), throwsA(anything));
      expect(registry.proofCount, 0);
      await noResources();
    },
  );

  test('matching inventory bytehash does not bypass canonical inventory validation', () async {
    final data =
        jsonDecode(inventory.readAsStringSync()) as Map<String, dynamic>;
    data['lang'] = 'pt-BR';
    inventory.writeAsStringSync(jsonEncode(data));
    offer = makeOffer();
    await expectLater(open(), throwsA(anything));
    expect(registry.proofCount, 0);
    await noResources();
  });

  test(
    'source exchange after copy cannot change reader; next open fails',
    () async {
      hook = (stage) async {
        if (stage == ValidationStage.copyComplete) changeSameLength(source);
      };
      final db = await open();
      expect(await ids(db), isNotEmpty);
      hook = null;
      await db.close();
      await expectLater(open(), throwsA(anything));
      await noResources();
    },
  );

  test('hash is of destination, not only the source stream', () async {
    hook = (stage) async {
      if (stage == ValidationStage.copyComplete) {
        final folder = snapshots.listSync().single;
        changeSameLength(File('${folder.path}/content.sqlite'));
      }
    };
    await expectLater(open(), throwsA(anything));
    expect(calls[ValidationStage.fullValidation], isNull);
    expect(registry.proofCount, 0);
    await noResources();
  });

  test('inventory exchange after hash uses exactly retained bytes', () async {
    hook = (stage) async {
      if (stage == ValidationStage.inventoryHash) changeSameLength(inventory);
    };
    final db = await open();
    expect(await ids(db), isNotEmpty);
    hook = null;
    await db.close();
    await expectLater(open(), throwsA(anything));
    await noResources();
  });

  test('LRU bounded to two, eviction never closes held reader', () async {
    final first = await open();
    final expected = await ids(first);
    await (await open(read: request(release: makeOffer(generation: 2))))
        .close();
    await (await open(read: request(release: makeOffer(generation: 3))))
        .close();
    expect(registry.proofCount, 2);
    expect(await ids(first), expected);
    expect(registry.readerReservations, 1);
    await (await open()).close();
    expect(calls[ValidationStage.fullValidation], 4);
    await first.close();
    await noResources();
  });

  test('warm access touches LRU and recovery ignores a valid proof', () async {
    await (await open()).close();
    await (await open(read: request(release: makeOffer(generation: 2))))
        .close();
    await (await open()).close();
    await (await open(read: request(release: makeOffer(generation: 3))))
        .close();
    await (await open()).close();
    expect(calls[ValidationStage.fullValidation], 3);
    await (await open(read: request(mode: InstalledReadMode.recoveryFull)))
        .close();
    expect(calls[ValidationStage.fullValidation], 4);
    await noResources();
  });

  test(
    'new process registry has no receipts, language invalidation forces full',
    () async {
      await (await open()).close();
      registry.invalidateLanguage('en');
      await (await open()).close();
      expect(calls[ValidationStage.fullValidation], 2);
      registry = ProcessValidationRegistry(
        snapshots,
        onStage: (stage) async {
          calls.update(stage, (n) => n + 1, ifAbsent: () => 1);
        },
      );
      expect(registry.proofCount, 0);
      await (await open()).close();
      expect(calls[ValidationStage.fullValidation], 3);
      await noResources();
    },
  );

  test(
    'identity is deep immutable and manifest/features/profile are validated',
    () async {
      final identity = GenerationIdentity.fromOffer(offer);
      expect(identity.contractVersion, validationContractVersion);
      final exposed = identity.offer;
      (exposed.manifest['required_features'] as List)[0] = 'changed';
      expect(identity, GenerationIdentity.fromOffer(offer));
      expect(identity.offer.manifest['required_features'], [
        'immutable-contexts-v1',
      ]);
      await (await open()).close();
      await (await open(
        read: request(
          release: makeOffer(changes: {'notes': 'different manifest'}),
        ),
      )).close();
      expect(calls[ValidationStage.fullValidation], 2);
      for (final change in [
        {'profile_id': 'wrong'},
        {'profile_sha256': '0' * 64},
        {
          'required_features': ['wrong'],
        },
      ]) {
        expect(() => makeOffer(changes: change), throwsFormatException);
      }
      await noResources();
    },
  );

  test(
    'final journal/epoch rejection and cancellation cannot publish proof',
    () async {
      await expectLater(
        open(read: request(confirm: (_) async => false)),
        throwsStateError,
      );
      expect(registry.proofCount, 0);
      await noResources();
      final cancelled = ReadCancellation();
      hook = (stage) async {
        if (stage == ValidationStage.beforeHandshake) cancelled.cancel();
      };
      await expectLater(
        open(read: request(cancellation: cancelled)),
        throwsA(anything),
      );
      expect(registry.proofCount, 0);
      await noResources();
      hook = null;
      await (await open()).close();
      expect(calls[ValidationStage.fullValidation], 3);
    },
  );

  for (final stage in [
    ValidationStage.copyComplete,
    ValidationStage.beforeHandshake,
    ValidationStage.handshake,
  ]) {
    test('fault at $stage publishes no proof and releases resources', () async {
      hook = (event) async {
        if (event == stage) throw StateError('injected $stage failure');
      };
      await expectLater(open(), throwsA(anything));
      expect(registry.proofCount, 0);
      await noResources();
    });
  }

  test(
    'three reservations include external/bootstrap; fourth refused, no queue',
    () async {
      final first = await open();
      final second = await open(
        read: request(release: makeOffer(generation: 2)),
      );
      final bootstrap = registry.reserveExternalReader();
      await expectLater(
        open(read: request(release: makeOffer(generation: 3))),
        throwsStateError,
      );
      expect(registry.readerReservations, 3);
      expect(await ids(first), isNotEmpty);
      expect(await ids(second), isNotEmpty);
      await first.close();
      await second.close();
      await bootstrap.closeAfter(() async {});
      await bootstrap.closeAfter(() async => fail('must close only once'));
      await noResources();
    },
  );

  test(
    'close failure retains safety barrier, never force releases reservation',
    () async {
      final reservation = registry.reserveExternalReader();
      var attempts = 0;
      Future<void> brokenClose() async {
        attempts++;
        throw StateError('still open');
      }

      await expectLater(reservation.closeAfter(brokenClose), throwsStateError);
      await expectLater(reservation.closeAfter(brokenClose), throwsStateError);
      expect(attempts, 1);
      expect(registry.readerReservations, 1);
    },
  );

  test('snapshot cleanup failure is idempotent and holds slot', () async {
    final db = await open();
    hook = (stage) async {
      if (stage == ValidationStage.beforeCleanup) {
        throw FileSystemException('locked');
      }
    };
    await expectLater(db.close(), throwsA(isA<FileSystemException>()));
    await expectLater(db.close(), throwsA(isA<FileSystemException>()));
    expect(registry.readerReservations, 1);
    expect(snapshots.listSync(), hasLength(1));
    expect(calls[ValidationStage.beforeCleanup], 1);
  });

  test('RepositoryOwner single flight: one interested lease survives another release', () async {
    final entered = Completer<void>(), proceed = Completer<void>();
    hook = (stage) async {
      if (stage == ValidationStage.fullValidation) {
        entered.complete();
        await proceed.future;
      }
    };
    final owner = RepositoryOwner<ContentDatabase>(
      () => open(),
      (db) => db.close(),
    );
    final first = owner.lease();
    final second = owner.lease();
    expect(identical(first.future, second.future), isTrue);
    await entered.future;
    first.release();
    expect(registry.readerReservations, 1);
    proceed.complete();
    final db = await second.future;
    expect(await ids(db), isNotEmpty);
    expect(calls[ValidationStage.fullValidation], 1);
    expect(registry.proofCount, 1);
    expect(snapshots.listSync(), hasLength(1));
    second.release();
    owner.pause();
    await owner.closed();
    await noResources();
  });

  test(
    'missing input and precancelled request allocate no lasting resources',
    () async {
      source.deleteSync();
      await expectLater(open(), throwsA(anything));
      await noResources();
      final cancelled = ReadCancellation()..cancel();
      await expectLater(
        open(read: request(cancellation: cancelled)),
        throwsStateError,
      );
      expect(registry.proofCount, 0);
      await noResources();
    },
  );

  test(
    'source mutation during copy is rejected, including unchanged metadata',
    () async {
      var changed = false;
      hook = (stage) async {
        if (stage == ValidationStage.copyChunk && !changed) {
          changed = true;
          changeSameLength(source);
        }
      };
      await expectLater(open(), throwsA(anything));
      expect(changed, isTrue);
      expect(registry.proofCount, 0);
      await noResources();
    },
  );

  test(
    'source mutation during destination hash cannot alter the snapshot',
    () async {
      var changed = false;
      hook = (stage) async {
        if (stage == ValidationStage.hashChunk && !changed) {
          changed = true;
          changeSameLength(source);
        }
      };
      final db = await open();
      expect(await ids(db), isNotEmpty);
      await db.close();
      hook = null;
      await expectLater(open(), throwsA(anything));
      await noResources();
    },
  );

  test(
    'cancel after successful handshake/final await cannot publish',
    () async {
      final cancel = ReadCancellation();
      await expectLater(
        open(
          read: request(
            cancellation: cancel,
            confirm: (_) async {
              cancel.cancel();
              return true;
            },
          ),
        ),
        throwsStateError,
      );
      expect(registry.proofCount, 0);
      await noResources();
    },
  );

  test('no remaining interested lease: explicit owner cancellation publishes nothing', () async {
    final entered = Completer<void>(), proceed = Completer<void>();
    final cancel = ReadCancellation();
    hook = (stage) async {
      if (stage == ValidationStage.fullValidation) {
        entered.complete();
        await proceed.future;
      }
    };
    final owner = RepositoryOwner<ContentDatabase>(
      () => open(read: request(cancellation: cancel)),
      (db) => db.close(),
    );
    final lease = owner.lease();
    final failed = expectLater(lease.future, throwsA(anything));
    await entered.future;
    lease.release();
    // Package 2 wires this last-interest signal; no second owner is introduced.
    cancel.cancel();
    proceed.complete();
    await failed;
    owner.pause();
    await owner.closed();
    expect(registry.proofCount, 0);
    await noResources();
  });

  test(
    'unclaimed reader close is idempotent and cannot later be consumed',
    () async {
      final bound = await registry.openBoundReader(request());
      await bound.close();
      await bound.close();
      expect(() => ContentDatabase.fromBoundReader(bound), throwsStateError);
      await noResources();
    },
  );

  test('success token can only be consumed once', () async {
    final bound = await registry.openBoundReader(request());
    final db = ContentDatabase.fromBoundReader(bound);
    expect(() => ContentDatabase.fromBoundReader(bound), throwsStateError);
    expect(bound.close, throwsStateError);
    await db.close();
    await noResources();
  });
}
