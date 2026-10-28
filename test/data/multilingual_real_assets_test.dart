// Opt-in acceptance against actual ignored release assets, never synthetic packs.
// flutter test --no-pub --dart-define=VERIFY_MULTILINGUAL_ASSETS=true test/data/multilingual_real_assets_test.dart
// PT+NB: --dart-define=VERIFY_PORTUGUESE_NORWEGIAN_ASSETS=true
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/data/content/bundled_content_updates.dart';
import 'package:sprachapp/data/content/content_database.dart';
import 'package:sprachapp/data/content/context_revision_validation.dart';
import 'package:sprachapp/data/content/content_install_journal.dart';
import 'package:sprachapp/data/content/content_pack_installer.dart';
import 'package:sprachapp/data/content/content_release_client.dart';
import 'package:sprachapp/data/user/drift_user_repository.dart';
import 'package:sprachapp/data/user/user_database.dart';
import 'package:sprachapp/domain/content.dart';
import 'package:sprachapp/domain/repositories.dart';
import 'package:sprachapp/domain/srs_state.dart';
import 'package:sprachapp/presentation/providers/database_providers.dart';
import 'package:sprachapp/presentation/providers/language_selection_provider.dart';

const corpus = 'editorial_review/multilingual_decks_20261027';
const portugueseOnly = bool.fromEnvironment('VERIFY_PORTUGUESE_ASSET');
const portugueseNorwegianOnly = bool.fromEnvironment(
  'VERIFY_PORTUGUESE_NORWEGIAN_ASSETS',
);
const enabled =
    bool.fromEnvironment('VERIFY_MULTILINGUAL_ASSETS') ||
    portugueseOnly ||
    portugueseNorwegianOnly;
const releaseLanguages = portugueseNorwegianOnly
    ? ['pt-BR', 'nb']
    : portugueseOnly
    ? ['pt-BR']
    : ['pt-BR', 'nb', 'it', 'es'];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'real releases: complete lookup, language switching and PT20 history',
    () async {
      final root = Directory.systemTemp.createTempSync('real-multilingual-');
      final db = UserDatabase.file(File('${root.path}/user.sqlite'));
      ProviderContainer? scope;
      addTearDown(() async {
        scope?.dispose();
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await db.close();
        await root.delete(recursive: true);
      });
      Future<Uint8List?> load(String key) async {
        final file = File(key);
        return await file.exists() ? file.readAsBytes() : null;
      }

      final registry = await ProcessValidationRegistry.forAppSupport(root);
      ContentPackInstaller installer(String lang) => ContentPackInstaller(
        loadAsset: load,
        supportDirectory: root,
        lang: lang,
        validationRegistry: registry,
      );
      final inventory = jsonDecode(
        File('$corpus/inventory.json').readAsStringSync(),
      );
      final expected = <String, int>{
        for (final deck in inventory['decks'])
          deck['slug'] as String: deck['target_count'] as int,
      };
      expect(expected.length, 14);
      expect(expected.values.reduce((a, b) => a + b), 3830);
      for (final lang in releaseLanguages) {
        for (final name in [
          'content.sqlite',
          'content.manifest.json',
          'history_inventory.json',
          'bundled-release.json',
        ]) {
          expect(
            File('assets/content/$lang/$name').existsSync(),
            true,
            reason: 'Explicit real-asset verification requires $lang/$name',
          );
        }
      }

      // Reconstruct an actual installed cloud release using its original bytes.
      final original = File('$corpus/portuguese-original-cloud.sqlite');
      final history = File(
        '$corpus/portuguese-original-history_inventory.json',
      );
      final cloud =
          (jsonDecode(
                File('$corpus/portuguese-cloud-base.json').readAsStringSync(),
              ) as List).single
              as Map<String, dynamic>;
      final manifest = cloud['manifest'] as Map<String, dynamic>;
      expect(
        sha256.convert(original.readAsBytesSync()).toString(),
        manifest['sha256'],
      );
      expect(
        contextCanonicalHash(jsonDecode(history.readAsStringSync())),
        manifest['history_inventory_sha256'],
      );
      final oldOffer = ReleaseOffer.parse(
        jsonDecode(
          File('$corpus/portuguese-original-release-offer.json')
              .readAsStringSync(),
        ) as Map<String, dynamic>,
        'pt-BR',
      );
      expect(oldOffer.manifest, manifest);
      expect(
        sha256.convert(history.readAsBytesSync()).toString(),
        oldOffer.objects['history_inventory.json']['sha256'],
      );
      final journal = ContentInstallJournal(root, 'pt-BR');
      final generation = journal.generation(oldOffer.id)
        ..createSync(recursive: true);
      original.copySync('${generation.path}/content.sqlite');
      history.copySync('${generation.path}/history_inventory.json');
      File('${generation.path}/release.json')
          .writeAsStringSync(jsonEncode(oldOffer.toJson()));
      await journal.write('active', oldOffer.toJson());
      final before = await installer('pt-BR').open();
      final oldIds = await before.allCardIds();
      expect(oldIds.length, 20);
      final oldItems = await before.practiceItems(oldIds.toList());
      final oldSentences = {
        for (final item in oldItems) item.card.id: item.practiceSentence,
      };
      final user = DriftUserRepository(db, lang: 'pt-BR', ownsDatabase: false);
      final now = DateTime.utc(2026, 10, 27);
      await user.ensureCards(oldIds, now: now, origin: CardOrigin.deck);
      for (final item in oldItems) {
        await user.setCardFlags(
          item.card.id,
          favorite: true,
          inPlaylist: true,
          note: 'Erhaltener Lernstand',
        );
        expect(
          await user.recordReview(
            ReviewRecord(
              id: 'real-upgrade-${item.card.id}',
              cardId: item.card.id,
              createdAt: now,
              mode: ReviewMode.deck,
              sentenceId: item.practiceSentence.sentenceId,
              firstAttemptCorrect: true,
              errorCount: 0,
              revealed: false,
              hintUsed: false,
              boxBefore: 0,
              boxAfter: 3,
              dueAtAfter: now.add(const Duration(days: 7)),
              responseMs: 1234,
              appVersion: 'real-asset-verification',
              deviceId: 'verification',
            ),
          ),
          true,
        );
      }
      Future<Map<String, Object>> snapshot() async => {
        for (final table in db.allTables)
          table.actualTableName:
              (await db
                      .customSelect(
                        'SELECT * FROM "${table.actualTableName}" ORDER BY rowid',
                      )
                      .get())
                  .map((row) => row.data)
                  .toList(),
      };
      final learnerBefore = await snapshot();
      await before.close();
      expect(
        await applyBundledContentUpdates(
          loadAsset: load,
          supportDirectory: root,
        ),
        isEmpty,
      );
      expect(
        await snapshot(),
        learnerBefore,
        reason: 'Offline upgrade must not change any learner table',
      );
      final after = await installer('pt-BR').open();
      for (final entry in oldSentences.entries) {
        final retained = await after.historicalSentence(
          entry.key,
          entry.value.sentenceId,
        );
        expect(retained, isNotNull);
        expect(sentenceSnapshot(retained!), sentenceSnapshot(entry.value));
        final reviews = await user.reviewsFor(entry.key);
        expect(reviews.single.id, 'real-upgrade-${entry.key}');
        expect(reviews.single.sentenceId, entry.value.sentenceId);
      }
      await after.close();

      final owners =
          <ContentRepositoryKey, RepositoryOwner<ContentRepository>>{};
      scope = ProviderContainer(
        overrides: [
          userDatabaseProvider.overrideWith((ref) async => db),
          contentInstallerProvider.overrideWith(
            (ref, lang) async => installer(lang),
          ),
          activeContentKeyProvider.overrideWith(
            (ref) async => contentKeyFor(
              installer(
                await ref.watch(selectedContentLanguageProvider.future),
              ),
            ),
          ),
          contentOwnerProvider.overrideWith(
            (ref, key) => owners.putIfAbsent(
              key,
              () => createContentOwner(key, () async => installer(key.lang)),
            ),
          ),
          appInfoProvider.overrideWith(
            (ref) async => 'real-asset-verification',
          ),
        ],
      );
      final report = <String, Object>{};
      for (final lang in [...releaseLanguages, 'en', 'pt-BR']) {
        expect(
          await scope
              .read(languageSelectionProvider.notifier)
              .selectLanguage(lang),
          true,
        );
        expect(await scope.read(selectedContentLanguageProvider.future), lang);
        final repo = await scope.read(contentRepositoryProvider.future);
        expect(repo.info.lang, lang);
        if (lang == 'en' || report.containsKey(lang)) continue;
        final decks = await repo.decks();
        expect(
          {for (final deck in decks) deck.slug: deck.cardCount},
          expected,
          reason: lang,
        );
        var targets = 0;
        var tokenCount = 0;
        final checked = <String>{};
        for (final deck in decks) {
          final refs = await repo.deckPracticeTargets(deck.id);
          expect(
            refs.length,
            expected[deck.slug],
            reason: '$lang/${deck.slug}',
          );
          targets += refs.length;
          final items = await repo.practiceItems(
            refs.map((r) => r.cardId).toSet().toList(),
          );
          for (final item in items) {
            if (!checked.add(item.card.id)) continue;
            final sentence = item.practiceSentence;
            expect(contentFormNorm(sentence.gapText), item.card.formNorm);
            expect(sentence.translationDe?.trim(), isNotEmpty);
            final covered = <int>{};
            for (final token in sentence.tokens) {
              expect(
                sentence.text.substring(token.start, token.end),
                token.surface,
              );
              if (RegExp(r'\p{L}', unicode: true).hasMatch(token.surface)) {
                expect(
                  token.translation?.trim(),
                  isNotEmpty,
                  reason: '$lang ${sentence.sentenceId} ${token.surface}',
                );
              }
              covered.addAll(
                List.generate(token.end - token.start, (i) => token.start + i),
              );
              tokenCount++;
            }
            for (final letter in RegExp(
              r'\p{L}',
              unicode: true,
            ).allMatches(sentence.text)) {
              expect(
                covered.contains(letter.start),
                true,
                reason:
                    '$lang ${sentence.sentenceId}: missing lookup at ${letter.start}',
              );
            }
          }
        }
        expect(targets, 3830);
        report[lang] = {
          'decks': decks.length,
          'targets': targets,
          'cards_read': checked.length,
          'tokens_checked': tokenCount,
          'version': repo.info.version,
        };
      }
      for (final id in oldIds) {
        expect((await user.reviewsFor(id)).single.id, 'real-upgrade-$id');
      }
      final output = File('build/multilingual-verification/result.json');
      output.parent.createSync(recursive: true);
      output.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert({
          'verified_at_utc': DateTime.now().toUtc().toIso8601String(),
          'languages': report,
          'historical_cards_and_reviews_preserved': oldIds.length,
          'baseline_sqlite_sha256': manifest['sha256'],
          'all_user_tables_unchanged_during_upgrade': true,
        }),
      );
      // ignore: avoid_print
      print(output.readAsStringSync());
    },
    skip: enabled
        ? false
        : 'Enable VERIFY_MULTILINGUAL_ASSETS=true after all real assets exist.',
    timeout: const Timeout(Duration(minutes: 15)),
  );
}

Map<String, Object?> sentenceSnapshot(CardSentence sentence) => {
  'id': sentence.sentenceId,
  'text': sentence.text,
  'translation': sentence.translationDe,
  'start': sentence.gapStart,
  'end': sentence.gapEnd,
  'tokens': [
    for (final token in sentence.tokens)
      [token.start, token.end, token.surface, token.translation],
  ],
};
