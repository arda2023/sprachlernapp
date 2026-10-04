import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sprachapp/data/content/drift_content_repository.dart';
import 'package:sprachapp/data/user/drift_user_repository.dart';
import 'package:sprachapp/data/user/user_database.dart';
import 'package:sprachapp/domain/srs_state.dart';
import 'package:sprachapp/domain/content.dart';
import 'package:sprachapp/presentation/providers/database_providers.dart';
import 'package:sprachapp/presentation/providers/deck_providers.dart';
import 'package:sprachapp/presentation/providers/learning_providers.dart';
import 'package:sprachapp/presentation/practice/deck_session_controller.dart';

import 'data/support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;
  late DriftContentRepository content;
  late DriftUserRepository user;
  late ProviderContainer container;
  late DateTime now;
  ProviderContainer scope() => ProviderContainer(
    overrides: [
      contentRepositoryProvider.overrideWith((ref) async => content),
      userRepositoryProvider.overrideWith((ref) async => user),
      clockProvider.overrideWithValue(() => now),
      appInfoProvider.overrideWith((ref) async => 'test'),
    ],
  );
  Future<void> settle() async {
    await Future<void>.delayed(const Duration(milliseconds: 30));
  }

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('learning_integration');
    final work = Directory('${dir.path}/work')..createSync();
    final support = Directory('${dir.path}/support')..createSync();
    final bytes = buildFixturePack(
      work,
      tweak: (db) {
        db.execute(
          "INSERT INTO decks SELECT 'deck-copy',lang,'copy',title_de,description_de,cefr_band,icon,2,removed_in,replaced_by FROM decks WHERE id='deck-allg'",
        );
        db.execute(
          "INSERT INTO deck_cards SELECT 'duplicate-'||id,'deck-copy',card_id,position,removed_in,replaced_by FROM deck_cards WHERE deck_id='deck-allg'",
        );
      },
    ).readAsBytesSync();
    content = await installerFor(
      support,
      db: bytes,
      manifest: manifestFor(bytes),
    ).open();
    user = DriftUserRepository(
      UserDatabase.file(File('${dir.path}/user.db')),
      lang: 'en',
    );
    now = DateTime(2026, 10, 4, 12);
    container = scope();
  });
  tearDown(() async {
    container.dispose();
    await user.close();
    await content.close();
    dir.deleteSync(recursive: true);
  });

  test('deck review updates global progress and words; mixed uses same state; flags and restart persist', () async {
    container.listen(vocabBreakdownProvider, (_, _) {});
    container.listen(wordListProvider, (_, _) {});
    expect(
      (await container.read(vocabBreakdownProvider.future)).unseen,
      4,
    ); // not eight
    expect(await container.read(wordListProvider.future), isEmpty);
    const args = (deckId: 'deck-allg', kind: DeckSessionKind.learn, size: 1);
    final provider = deckSessionControllerProvider(args);
    final sub = container.listen(provider, (_, _) {});
    for (var i = 0; i < 30 && container.read(provider).pass == null; i++) {
      await settle();
    }
    final controller = container.read(provider.notifier);
    expect(container.read(provider).pass!.item.card.id, 'card-went');
    controller.submit('went');
    for (var i = 0; i < 30 && !container.read(provider).saved; i++) {
      await settle();
    }
    expect(container.read(provider).saved, isTrue);
    await settle();
    expect((await container.read(vocabBreakdownProvider.future)).building, 1);
    final word = (await container.read(wordListProvider.future)).single;
    expect([word.id, word.box, word.reviewCount], ['card-went', 3, 1]);
    expect(
      (await container.read(learningProgressProvider.future)).goal.done,
      1,
    );
    await user.setDeckActive('deck-allg', false, now: now);
    await user.setDeckActive('deck-copy', false, now: now);
    const mixedArgs = (deckId: '', kind: DeckSessionKind.mixed, size: 5);
    final mixed = deckSessionControllerProvider(mixedArgs);
    final msub = container.listen(mixed, (_, _) {});
    for (var i = 0; i < 30 && container.read(mixed).pass == null; i++) {
      await settle();
    }
    final pass = container.read(mixed).pass!;
    expect(pass.item.card.id, 'card-went');
    expect(pass.boxBefore, 3);
    expect(pass.mode, ReviewMode.early);
    await container
        .read(wordActionsProvider)
        .save(
          word.id,
          favorite: true,
          disabled: true,
          note: 'Meine Notiz',
          inPlaylist: true,
        );
    await settle();
    final flags = (await container.read(wordListProvider.future)).single;
    expect(flags.isFavorite && flags.isDisabled && flags.inPlaylist, isTrue);
    expect(flags.note, 'Meine Notiz');
    expect((await container.read(vocabBreakdownProvider.future)).total, 0);
    sub.close();
    msub.close();
    container.dispose();
    await user.close();
    user = DriftUserRepository(
      UserDatabase.file(File('${dir.path}/user.db')),
      lang: 'en',
    );
    container = scope();
    final restarted = (await container.read(wordListProvider.future)).single;
    expect(restarted.note, 'Meine Notiz');
    expect(restarted.isFavorite, isTrue);
    expect(await user.activeDeckIds(['deck-allg', 'deck-copy']), isEmpty);
    expect((await user.reviewsFor(word.id)).length, 1);
  });

  test('midnight/resume refresh, unknown IDs preserved, empty and missing content honest', () async {
    await user.ensureCards(
      ['card-went', 'legacy-missing'],
      now: now,
      origin: CardOrigin.deck,
    );
    await user.recordReview(
      ReviewRecord(
        id: 'seed',
        cardId: 'card-went',
        createdAt: now,
        mode: ReviewMode.deck,
        sentenceId: 's-went-1',
        firstAttemptCorrect: false,
        errorCount: 1,
        revealed: false,
        hintUsed: false,
        boxBefore: 0,
        boxAfter: 1,
        dueAtAfter: DateTime(2026, 10, 5),
        responseMs: 1,
        appVersion: 'test',
        deviceId: 'test',
      ),
    );
    container.listen(vocabBreakdownProvider, (_, _) {});
    expect((await container.read(vocabBreakdownProvider.future)).due, 0);
    now = DateTime(2026, 10, 5);
    WidgetsBinding.instance.handleAppLifecycleStateChanged(
      AppLifecycleState.resumed,
    );
    await settle();
    expect((await container.read(vocabBreakdownProvider.future)).due, 1);
    expect((await container.read(wordListProvider.future)).length, 1);
    expect((await user.allCardStates()).containsKey('legacy-missing'), isTrue);
    final failed = ProviderContainer(
      overrides: [
        userRepositoryProvider.overrideWith((ref) async => user),
        contentRepositoryProvider.overrideWith(
          (ref) async => throw const ContentUnavailable(
            ContentUnavailableReason.missing,
            'Kein Pack',
          ),
        ),
      ],
    );
    await expectLater(
      failed.read(wordListProvider.future),
      throwsA(isA<ContentUnavailable>()),
    );
    await expectLater(
      failed.read(vocabBreakdownProvider.future),
      throwsA(isA<ContentUnavailable>()),
    );
    failed.dispose();
  });

  test(
    'empty mixed queue and database opening errors have no fallback data',
    () async {
      await user.setDeckActive('deck-allg', false, now: now);
      await user.setDeckActive('deck-copy', false, now: now);
      const args = (deckId: '', kind: DeckSessionKind.mixed, size: 5);
      final provider = deckSessionControllerProvider(args);
      final subscription = container.listen(provider, (_, _) {});
      for (var i = 0; i < 30 && container.read(provider).loading; i++) {
        await settle();
      }
      expect(container.read(provider).finished, isTrue);
      expect(container.read(provider).total, 0);
      expect(container.read(provider).pass, isNull);
      expect(await container.read(wordListProvider.future), isEmpty);
      subscription.close();
      final failed = ProviderContainer(
        overrides: [
          contentRepositoryProvider.overrideWith((ref) async => content),
          userRepositoryProvider.overrideWith(
            (ref) async => throw StateError('DB unavailable'),
          ),
        ],
      );
      for (final provider in [
        wordListProvider,
        learningProgressProvider,
        vocabBreakdownProvider,
      ]) {
        await expectLater(
          failed.read(provider.future),
          throwsA(isA<StateError>()),
        );
      }
      final failedSubscription = failed.listen(
        deckSessionControllerProvider(args),
        (_, _) {},
      );
      for (
        var i = 0;
        i < 30 && failed.read(deckSessionControllerProvider(args)).loading;
        i++
      ) {
        await settle();
      }
      expect(
        failed.read(deckSessionControllerProvider(args)).error,
        isA<StateError>(),
      );
      expect(failed.read(deckSessionControllerProvider(args)).pass, isNull);
      failedSubscription.close();
      failed.dispose();
    },
  );

  testWidgets(
    'clock provider schedules local midnight without a database write',
    (tester) async {
      // Exercise the shared timer rather than manually invalidating its provider.
      now = DateTime(2026, 10, 4, 23, 59, 59);
      container.listen(learningNowProvider, (_, _) {});
      expect(container.read(learningNowProvider).day, 4);
      now = DateTime(2026, 10, 5);
      await tester.pump(const Duration(seconds: 1));
      expect(container.read(learningNowProvider).day, 5);
      container.dispose();
      container = scope();
    },
  );
}
