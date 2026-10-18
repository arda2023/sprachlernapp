import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sprachapp/data/content/content_database.dart';
import 'package:sprachapp/data/content/content_install_journal.dart';
import 'package:sprachapp/data/content/content_pack_installer.dart';
import 'package:sprachapp/data/content/content_release_client.dart';
import 'package:sprachapp/data/content/content_update_service.dart';
import 'package:sprachapp/data/content/drift_content_repository.dart';
import 'package:sprachapp/data/user/drift_user_repository.dart';
import 'package:sprachapp/data/user/user_database.dart';
import 'package:sprachapp/domain/content.dart';
import 'package:sprachapp/domain/review_pass.dart';
import 'package:sprachapp/domain/srs_state.dart';
import 'package:sprachapp/presentation/providers/database_providers.dart';
import 'package:sprachapp/presentation/providers/learning_providers.dart';
import 'package:sprachapp/presentation/providers/story_learning_providers.dart';

class _LocalRelease implements ContentReleaseTransport {
  _LocalRelease(this.offer, this.bundle);
  final ReleaseOffer offer;
  final Directory bundle;
  bool denied = false;
  @override
  Future<ReleaseOffer?> latest(String lang, int generation) async {
    if (denied) throw StateError('synthetic authorization failure');
    return generation < offer.generation ? offer : null;
  }

  @override
  Future<Map<String, Uri>> downloads(ReleaseOffer offer) async => {
    for (final name in offer.objects.keys)
      name: Uri.parse('https://local.invalid/$name'),
  };
  @override
  Stream<List<int>> bytes(Uri uri) =>
      File('${bundle.path}/${uri.pathSegments.single}').openRead();
}

/// Only the user DB and installation directory are writable temporary data.
class _Scenario {
  _Scenario(this.tmp);
  final Directory tmp;
  final now = DateTime.utc(2026, 10, 18);
  late UserDatabase db;
  late DriftUserRepository user;
  late DriftContentRepository content;
  late ProviderContainer scope;
  late PracticeItem original;
  late ReviewPass running;
  late List<Map<String, Object?>> states, reviews;

  void openUser() {
    db = UserDatabase.file(File('${tmp.path}/synthetic-user.sqlite'));
    user = DriftUserRepository(db, lang: 'en');
  }

  void openScope() {
    scope = ProviderContainer(
      overrides: [
        contentRepositoryProvider.overrideWith((ref) async => content),
        userRepositoryProvider.overrideWith((ref) async => user),
        clockProvider.overrideWithValue(() => now),
      ],
    );
  }

  Future<List<Map<String, Object?>>> rows(String table) async =>
      (await db.customSelect('SELECT * FROM $table').get())
          .map((r) => r.data)
          .toList();

  Future<void> learn(String id) async {
    original = (await content.practiceItems([id])).single;
    await user.ensureCards([id], now: now, origin: CardOrigin.deck);
    final pass = ReviewPass(
      id: 'synthetic-review',
      item: original,
      sentence: original.practiceSentence,
      state: (await user.allCardStates())[id],
      mode: ReviewMode.deck,
      startedAt: now,
    );
    pass.submit(original.card.form, now);
    await user.recordReview(
      pass.complete(now: now, appVersion: 'test', deviceId: 'synthetic')!,
    );
    await user.setCardFlags(
      id,
      favorite: true,
      inPlaylist: true,
      note: 'Keep synthetic personal data',
    );
    running = ReviewPass(
      id: 'running',
      item: original,
      sentence: original.practiceSentence,
      state: (await user.allCardStates())[id],
      mode: ReviewMode.deck,
      startedAt: now,
    );
    states = await rows('user_cards');
    reviews = await rows('review_log');
  }

  Future<void> verify(String translation, {bool updated = false}) async {
    final id = original.card.id;
    final words = await scope.read(wordListProvider.future);
    expect(words.single.id, id);
    expect(words.single.sentenceTranslation, translation);
    expect(words.single.reviewCount, 1);
    final resolver = await scope.read(practiceResolverProvider.future);
    final item = (await resolver.practiceItems([id])).single;
    final fresh = ReviewPass(
      id: 'fresh',
      item: item,
      sentence: item.practiceSentence,
      state: (await user.allCardStates())[id],
      mode: ReviewMode.deck,
      startedAt: now,
    );
    expect(fresh.sentence.translationDe, translation);
    expect(
      running.sentence.translationDe,
      original.practiceSentence.translationDe,
    );
    final historical = await resolver.historicalSentence(
      id,
      original.practiceSentence.sentenceId,
    );
    expect(historical!.translationDe, original.practiceSentence.translationDe);
    if (updated) {
      expect(fresh.sentence.sentenceId, isNot(historical.sentenceId));
    }
    expect(await rows('user_cards'), states);
    expect(await rows('review_log'), reviews);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('learned word details use current revision; reviews and running pass survive restart', () async {
    final tmp = Directory.systemTemp.createTempSync('active-context-');
    final s = _Scenario(tmp)..openUser();
    DriftContentRepository load(String name) {
      final file = File('${tmp.path}/$name.sqlite');
      final sql = sqlite3.open(file.path);
      sql.execute(
        File('test/fixtures/editor_context_$name.sql').readAsStringSync(),
      );
      sql.close();
      return DriftContentRepository(ContentDatabase.open(file, lang: 'en'));
    }

    s.content = load('before');
    s.openScope();
    try {
      final cards = await s.content.selectionCards(
        await s.content.allCardIds(),
      );
      final id = cards
          .singleWhere((c) => c.form == 'cut' && c.formFunction == 'base')
          .id;
      await s.learn(id);
      await s.verify(s.original.practiceSentence.translationDe!);
      await s.content.close();
      s.content = load('after');
      s.scope.invalidate(contentRepositoryProvider);
      await s.verify('Sie schneiden das Papier.', updated: true);
      s.scope.dispose();
      await s.user.close();
      await s.content.close();
      s.openUser();
      s.content = DriftContentRepository(
        ContentDatabase.open(File('${tmp.path}/after.sqlite'), lang: 'en'),
      );
      s.openScope();
      await s.verify('Sie schneiden das Papier.', updated: true);
    } finally {
      s.scope.dispose();
      await s.user.close();
      await s.content.close();
      tmp.deleteSync(recursive: true);
    }
  });

  final oldPath = Platform.environment['ACTIVE_CONTEXT_OLD_BUNDLE'];
  final newPath = Platform.environment['ACTIVE_CONTEXT_NEW_BUNDLE'];
  final publicationPath = Platform.environment['ACTIVE_CONTEXT_PUBLICATION'];
  group(
    'published packs',
    () {
      late Directory tmp;
      late _Scenario s;
      late ContentPackInstaller installer;
      late ContentInstallJournal journal;
      late _LocalRelease transport;
      late ContentTransitionGate gate;
      late ContentUpdateService service;
      late ReleaseOffer offer;
      late String oldTranslation;
      var failOpen = false;
      const expected =
          'Wir unterhielten uns nett, während wir auf den Bus warteten.';
      setUpAll(() async {
        tmp = Directory.systemTemp.createTempSync('published-active-context-');
        s = _Scenario(tmp)..openUser();
        final oldBundle = Directory(oldPath!);
        final bundle = Directory(newPath!);
        final publication =
            jsonDecode(File(publicationPath!).readAsStringSync()) as Map;
        expect(publication['status'], 'published');
        final result = publication['result'] as Map;
        offer = ReleaseOffer.parse({
          ...result,
          'objects': {
            for (final name in ['content.sqlite', 'history_inventory.json'])
              name: {
                'sha256': sha256
                    .convert(File('${bundle.path}/$name').readAsBytesSync())
                    .toString(),
                'size_bytes': File('${bundle.path}/$name').lengthSync(),
              },
          },
        }, 'en');
        installer = ContentPackInstaller(
          supportDirectory: tmp,
          loadAsset: (key) async {
            final file = File('${oldBundle.path}/${key.split('/').last}');
            if (key.endsWith('.json')) {
              // Bootstrap envelope only; original SQLite bytes/hash stay exact.
              final manifest =
                  jsonDecode(await file.readAsString()) as Map<String, dynamic>;
              return Uint8List.fromList(
                utf8.encode(jsonEncode({...manifest, 'format': 1})),
              );
            }
            return file.readAsBytes();
          },
        );
        s.content = await installer.open();
        s.openScope();
        journal = ContentInstallJournal(tmp, 'en');
        transport = _LocalRelease(offer, bundle);
        gate = ContentTransitionGate();
        service = ContentUpdateService(
          journal,
          transport,
          gate: gate,
          currentFile: journal.currentFile,
          closeReaders: () => s.content.close(),
          openReaders: () async {
            if (failOpen) {
              failOpen = false;
              throw StateError('synthetic open failure');
            }
            s.content = await installer.open();
            s.scope.invalidate(contentRepositoryProvider);
          },
        );
        final cards = await s.content.selectionCards(
          await s.content.allCardIds(),
        );
        await s.learn(cards.singleWhere((c) => c.formNorm == 'chitchat').id);
        oldTranslation = s.original.practiceSentence.translationDe!;
        await s.verify(oldTranslation);
        await service.check();
        await service.download();
      });
      tearDownAll(() async {
        s.scope.dispose();
        await s.content.close();
        await s.user.close();
        tmp.deleteSync(recursive: true);
      });
      test(
        'blocked and unauthorized activation preserve current reader',
        () async {
          final release = gate.acquire();
          await expectLater(service.activate(), throwsStateError);
          release();
          await s.verify(oldTranslation);
          transport.denied = true;
          await expectLater(service.activate(), throwsStateError);
          transport.denied = false;
        },
      );
      test('failed opening rolls back; restart keeps old context', () async {
        failOpen = true;
        await expectLater(service.activate(), throwsStateError);
        await s.verify(oldTranslation);
        // Restart after the failed activation, using only persisted pointers.
        s.scope.dispose();
        await s.content.close();
        await s.user.close();
        s.openUser();
        s.content = await installer.open();
        s.openScope();
        await s.verify(oldTranslation);
      });
      test('activation agrees with current learned word details', () async {
        await service.activate();
        expect(
          (await journal.active())!.contentManifest.version,
          s.content.info.version,
        );
        expect(s.content.info.version, 'chitchat_de_korrektur_v1');
        expect(await journal.currentFile(), isNotNull);
        expect(
          sha256
              .convert(await (await journal.currentFile())!.readAsBytes())
              .toString(),
          offer.sha,
        );
        await s.verify(expected, updated: true);
      });
      test(
        'full restart keeps active context without asset fallback',
        () async {
          s.scope.dispose();
          await s.content.close();
          await s.user.close();
          s.openUser();
          // No asset access is allowed after successful activation, even on restart.
          s.content = await ContentPackInstaller(
            supportDirectory: tmp,
            loadAsset: (_) async =>
                throw StateError('unexpected asset fallback'),
          ).open();
          s.openScope();
          expect(s.content.info.version, offer.contentManifest.version);
          await s.verify(expected, updated: true);
        },
      );
    },
    skip: oldPath == null || newPath == null || publicationPath == null
        ? 'Set ACTIVE_CONTEXT_OLD_BUNDLE, ACTIVE_CONTEXT_NEW_BUNDLE and ACTIVE_CONTEXT_PUBLICATION to read-only published artifacts.'
        : false,
  );
}
