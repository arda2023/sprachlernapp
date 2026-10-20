import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sprachapp/data/content/content_database.dart';
import 'package:sprachapp/data/content/content_install_journal.dart';
import 'package:sprachapp/data/content/content_pack_installer.dart';
import 'package:sprachapp/data/content/content_release_client.dart';
import 'package:sprachapp/data/content/content_update_service.dart';

import 'support.dart';

import 'package:sprachapp/data/content/context_revision_validation.dart';
import 'package:sprachapp/presentation/providers/database_providers.dart';
import 'package:sprachapp/presentation/providers/language_selection_provider.dart';

import '../fixtures/language_selection.dart';
import '../fixtures/portuguese_installation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late LanguageHarness h;
  late ProviderContainer c;
  late ProcessValidationRegistry registry;
  late ContentInstallJournal journal;
  late Map<ValidationStage, int> calls;
  Future<void> Function(ValidationStage)? hook;

  Future<ReleaseOffer> english(int generation, {bool activate = true}) async {
    final dir = Directory('${h.root.path}/source-$generation')..createSync();
    final file = File('${dir.path}/content.sqlite');
    final sql = sqlite3.open(file.path);
    sql.execute(
      File('test/fixtures/private_release/content.sql').readAsStringSync(),
    );
    sql.close();
    final inventory = File(
      'test/fixtures/private_release/history_inventory.json',
    );
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
      'sha256': sha256.convert(file.readAsBytesSync()).toString(),
      'size_bytes': file.lengthSync(),
    });
    final offer = ReleaseOffer.parse({
      'manifest': manifest,
      'manifest_sha256': contextCanonicalHash(manifest),
      'objects': {
        for (final e in {
          'content.sqlite': file,
          'history_inventory.json': inventory,
        }.entries)
          e.key: {
            'sha256': sha256.convert(e.value.readAsBytesSync()).toString(),
            'size_bytes': e.value.lengthSync(),
          },
      },
    }, 'en');
    final installed = journal.generation(offer.id)..createSync(recursive: true);
    file.copySync('${installed.path}/content.sqlite');
    inventory.copySync('${installed.path}/history_inventory.json');
    File('${installed.path}/release.json')
        .writeAsStringSync(jsonEncode(offer.toJson()));
    if (activate) {
      await journal.write('active', offer.toJson());
      await journal.commit(offer);
    }
    return offer;
  }

  setUp(() async {
    h = LanguageHarness(
      Directory.systemTemp.createTempSync('validation-integration-'),
    );
    calls = {};
    hook = null;
    registry = ProcessValidationRegistry(
      Directory('${h.root.path}/readers'),
      onStage: (stage) async {
        calls.update(stage, (n) => n + 1, ifAbsent: () => 1);
        await hook?.call(stage);
      },
    );
    h.english = ContentPackInstaller(
      loadAsset: (_) async => null,
      supportDirectory: h.root,
      validationRegistry: registry,
    );
    h.portuguese = ContentPackInstaller(
      lang: 'pt-BR',
      loadAsset: (_) async => null,
      supportDirectory: h.root,
      validationRegistry: registry,
    );
    journal = ContentInstallJournal(h.root, 'en');
    await english(1);
    final pt = PortugueseTransport(
      Directory('${h.root.path}/pt-source')..createSync(),
    );
    final ptJournal = ContentInstallJournal(h.root, 'pt-BR');
    final dir = ptJournal.generation(pt.offer.id)..createSync(recursive: true);
    for (final e in pt.files.entries) {
      File('${dir.path}/${e.key}').writeAsBytesSync(e.value);
    }
    await ptJournal.write('active', pt.offer.toJson());
    await ptJournal.commit(pt.offer);
    c = h.scope();
  });
  tearDown(() async {
    c.dispose();
    for (final owner in h.owners.values) {
      owner.pause();
      await owner.closed();
    }
    expect(registry.readerReservations, 0);
    await h.close();
  });

  test(
    'activation cannot commit next after bound recovery restored previous',
    () async {
      final previous = await journal.active();
      final next = await english(2, activate: false);
      final service = ContentUpdateService(
        journal,
        _OfferTransport(next),
        currentFile: journal.currentFile,
        gate: ContentTransitionGate(),
        closeReaders: () async {
          // Candidate changes after the independent activation preflight.
          File('${journal.generation(next.id).path}/content.sqlite')
              .writeAsBytesSync([0]);
        },
        openReaders: () async => (await h.english.open()).close(),
        invalidateReadProofs: () => registry.invalidateLanguage('en'),
      );
      service.ready = next;
      await expectLater(service.activate(), throwsStateError);
      expect((await journal.active())!.id, previous!.id);
      expect((await journal.read('install-journal'))!['state'], 'recovered');
      final usable = await h.english.open();
      expect(await usable.allCardIds(), isNotEmpty);
      await usable.close();
    },
  );

  test('real app switching retains registry, hashes every open and validates each language once', () async {
    final first = await c.read(contentRepositoryProvider.future);
    final ids = await first.allCardIds();
    final decks = [
      for (final d in await first.decks())
        [d.id, await first.deckCardIds(d.id)],
    ];
    final controller = c.read(languageSelectionProvider.notifier);
    for (var i = 0; i < 3; i++) {
      expect(await controller.selectLanguage('pt-BR'), isTrue);
      expect(
        (await c.read(contentRepositoryProvider.future)).info.lang,
        'pt-BR',
      );
      expect(await controller.selectLanguage('en'), isTrue);
      final current = await c.read(contentRepositoryProvider.future);
      expect(await current.allCardIds(), ids);
      expect([
        for (final d in await current.decks())
          [d.id, await current.deckCardIds(d.id)],
      ], decks);
    }
    expect(calls[ValidationStage.fullValidation], 2);
    expect(calls[ValidationStage.contentHash], 7);
    expect(calls[ValidationStage.inventoryHash], 7);
    expect(registry.proofCount, 2);
  });

  test(
    'status queries allocate no readers and do not recover prepared journal',
    () async {
      for (var i = 0; i < 20; i++) {
        c.invalidate(languageInstallationProvider('en'));
        expect(
          await c.read(languageInstallationProvider('en').future),
          contains('Prüfung beim Öffnen'),
        );
      }
      final next = await english(2, activate: false);
      await journal.prepare(next);
      await journal.write('active', next.toJson());
      c.invalidate(languageInstallationProvider('en'));
      await c.read(languageInstallationProvider('en').future);
      expect((await journal.read('install-journal'))!['state'], 'prepared');
      expect(calls, isEmpty);
      expect(registry.readerReservations, 0);
    },
  );

  test('production owner shares open; partial release survives, last release cancels', () async {
    final owner = createContentOwner(
      await contentKeyFor(h.english),
      () async => h.english,
    );
    var entered = Completer<void>(), proceed = Completer<void>();
    hook = (stage) async {
      if (stage == ValidationStage.fullValidation) {
        entered.complete();
        await proceed.future;
      }
    };
    final one = owner.lease(), two = owner.lease();
    expect(identical(one.future, two.future), isTrue);
    await entered.future;
    one.release();
    proceed.complete();
    expect(await (await two.future).allCardIds(), isNotEmpty);
    two.release();
    await owner.closed();
    expect(calls[ValidationStage.fullValidation], 1);
    entered = Completer<void>();
    proceed = Completer<void>();
    hook = (stage) async {
      if (stage == ValidationStage.copyComplete) {
        entered.complete();
        await proceed.future;
      }
    };
    final cancelled = owner.lease();
    final failure = expectLater(cancelled.future, throwsA(anything));
    await entered.future;
    cancelled.release();
    proceed.complete();
    await failure;
    await owner.closed();
    expect(registry.readerReservations, 0);
  });

  test(
    'prepared next fully validates once before commit and then warms',
    () async {
      final next = await english(2, activate: false);
      await journal.prepare(next);
      await journal.write('active', next.toJson());
      await (await h.english.open()).close();
      expect((await journal.read('install-journal'))!['state'], 'committed');
      await (await h.english.open()).close();
      expect(calls[ValidationStage.fullValidation], 1);
    },
  );

  test('corrupt prepared next restores and re-resolves previous owner exactly once', () async {
    final previous = await journal.active();
    final next = await english(2, activate: false);
    await journal.prepare(next);
    await journal.write('active', next.toJson());
    File('${journal.generation(next.id).path}/content.sqlite')
        .writeAsBytesSync([0]);
    final repository = await c.read(contentRepositoryProvider.future);
    expect(await repository.allCardIds(), isNotEmpty);
    expect((await journal.active())!.id, previous!.id);
    expect(
      (await c.read(activeContentKeyProvider.future)).fingerprint,
      GenerationIdentity.fromOffer(previous).fingerprint,
    );
    expect(calls[ValidationStage.fullValidation], 1);
  });

  test(
    'prepared previous ignores old proof and never activates next',
    () async {
      await (await h.english.open()).close();
      final previous = await journal.active();
      final next = await english(2, activate: false);
      await journal.prepare(next);
      await (await h.english.open()).close();
      expect(calls[ValidationStage.fullValidation], 2);
      expect((await journal.active())!.id, previous!.id);
      expect((await journal.read('install-journal'))!['state'], 'prepared');
    },
  );

  test(
    'committed pointer mismatch fails instead of bootstrap fallback',
    () async {
      final next = await english(2, activate: false);
      await journal.commit(next);
      await expectLater(h.english.open(), throwsA(anything));
      expect(calls, isEmpty);
      expect(registry.proofCount, 0);
    },
  );

  test(
    'journal exchange at handshake prevents stale reader and proof',
    () async {
      final next = await english(2, activate: false);
      hook = (stage) async {
        if (stage == ValidationStage.handshake) {
          await journal.write('active', next.toJson());
          await journal.commit(next);
        }
      };
      await expectLater(h.english.open(), throwsA(anything));
      expect(registry.proofCount, 0);
    },
  );

  test(
    'rapid switch gate and corrupt target preserve usable English',
    () async {
      await c.read(contentRepositoryProvider.future);
      final entered = Completer<void>(), proceed = Completer<void>();
      hook = (stage) async {
        if (stage == ValidationStage.fullValidation) {
          entered.complete();
          await proceed.future;
        }
      };
      final controller = c.read(languageSelectionProvider.notifier);
      final pending = controller.selectLanguage('pt-BR');
      await entered.future;
      expect(await controller.selectLanguage('en'), isFalse);
      proceed.complete();
      expect(await pending, isTrue);
      hook = null;
      expect(await controller.selectLanguage('en'), isTrue);
      final ptJournal = ContentInstallJournal(h.root, 'pt-BR');
      (await ptJournal.currentFile())!.writeAsBytesSync([0]);
      expect(await controller.selectLanguage('pt-BR'), isFalse);
      expect(await c.read(selectedContentLanguageProvider.future), 'en');
      expect(
        await (await c.read(contentRepositoryProvider.future)).allCardIds(),
        isNotEmpty,
      );
    },
  );

  test('process cleanup only removes unlocked owned folders; live registry survives', () async {
    final root = Directory('${h.root.path}/processes')..createSync();
    final stale = Directory('${root.path}/process-stale')..createSync();
    File('${stale.path}/owner.lock').writeAsStringSync('');
    final unrelated = Directory('${root.path}/unrelated')..createSync();
    final one = await ProcessValidationRegistry.createProcess(root);
    final two = await ProcessValidationRegistry.createProcess(root);
    expect(stale.existsSync(), isFalse);
    expect(unrelated.existsSync(), isTrue);
    expect(root.listSync().whereType<Directory>(), hasLength(3));
    await one.closeProcess();
    await two.closeProcess();
  });

  test(
    'bootstrap occupies reservation through actual close, never creates proof',
    () async {
      final root = Directory('${h.root.path}/bootstrap')..createSync();
      final legacy = fixtureInstaller(root, root);
      final installer = ContentPackInstaller(
        loadAsset: legacy.loadAsset,
        supportDirectory: root,
        validationRegistry: registry,
      );
      final repository = await installer.open();
      expect(registry.readerReservations, 1);
      expect(registry.proofCount, 0);
      expect(await repository.allCardIds(), isNotEmpty);
      await repository.close();
      expect(registry.readerReservations, 0);
    },
  );

  test(
    'held old reader survives proof eviction and identity replacement',
    () async {
      final held = await h.english.open();
      final ids = await held.allCardIds();
      await english(2);
      await (await h.english.open()).close();
      await english(3);
      await (await h.english.open()).close();
      expect(registry.proofCount, 2);
      expect(registry.readerReservations, 1);
      expect(await held.allCardIds(), ids);
      await held.close();
    },
  );

  test(
    'proof invalidation during handshake rejects otherwise current open',
    () async {
      hook = (stage) async {
        if (stage == ValidationStage.handshake) {
          registry.invalidateLanguage('en');
        }
      };
      await expectLater(h.english.open(), throwsStateError);
      expect(registry.proofCount, 0);
    },
  );

  test(
    'activation reauthorizes and checks bytes despite installedRead proof',
    () async {
      final old = await journal.active();
      final next = await english(2);
      await (await h.english.open()).close();
      expect(registry.proofCount, 1);
      await journal.write('active', old!.toJson());
      await journal.commit(old);
      final transport = _OfferTransport(next);
      final service = ContentUpdateService(
        journal,
        transport,
        currentFile: journal.currentFile,
        gate: ContentTransitionGate(),
        closeReaders: () async {},
        openReaders: () async {},
        invalidateReadProofs: () => registry.invalidateLanguage('en'),
      );
      service.ready = next;
      transport.denied = true;
      await expectLater(service.activate(), throwsStateError);
      transport.denied = false;
      File('${journal.generation(next.id).path}/history_inventory.json')
          .writeAsStringSync('{}');
      await expectLater(service.activate(), throwsFormatException);
      expect(transport.requests, 2);
      expect((await journal.active())!.id, old.id);
      expect((await journal.read('install-journal'))!['state'], 'committed');
    },
  );
}

class _OfferTransport implements ContentReleaseTransport {
  _OfferTransport(this.offer);
  final ReleaseOffer offer;
  bool denied = false;
  int requests = 0;
  @override
  Future<ReleaseOffer?> latest(String lang, int generation) async {
    requests++;
    if (denied) throw StateError('synthetic denied');
    return offer;
  }

  @override
  Future<Map<String, Uri>> downloads(ReleaseOffer offer) async =>
      throw UnimplementedError();
  @override
  Stream<List<int>> bytes(Uri uri) => throw UnimplementedError();
}
