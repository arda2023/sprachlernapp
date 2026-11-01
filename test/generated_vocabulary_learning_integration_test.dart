import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sprachapp/data/user/drift_user_repository.dart';
import 'package:sprachapp/data/user/generated_vocabulary_store.dart';
import 'package:sprachapp/data/user/user_database.dart';
import 'package:sprachapp/domain/content.dart';
import 'package:sprachapp/domain/generated_vocabulary.dart';
import 'package:sprachapp/domain/generated_vocabulary_repository.dart';
import 'package:sprachapp/domain/srs_state.dart';
import 'package:sprachapp/presentation/practice/deck_session_controller.dart';
import 'package:sprachapp/presentation/providers/database_providers.dart';
import 'package:sprachapp/presentation/providers/deck_providers.dart';
import 'package:sprachapp/presentation/providers/learning_providers.dart';
import 'package:sprachapp/presentation/providers/story_learning_providers.dart';

import 'data/generated_vocabulary_store_test.dart' show response, word;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 20));

  for (final lang in GeneratedVocabularyRequest.languages) {
    test(
      '$lang generated vocabulary learns offline through shared providers and survives restart',
      () async {
        final dir = Directory.systemTemp.createTempSync(
          'generated-learning-$lang-',
        );
        final file = File('${dir.path}/user.db');
        final now = DateTime(2026, 10, 31, 12);
        var db = UserDatabase.file(file);
        var user = DriftUserRepository(
          db,
          lang: lang,
          contentIds: (_) async => <String>{},
        );
        ProviderContainer scope() => ProviderContainer(
          overrides: [
            contentRepositoryProvider.overrideWith(
              (ref) async => throw const ContentUnavailable(
                ContentUnavailableReason.missing,
                'Offline: kein Pack',
              ),
            ),
            selectedContentLanguageProvider.overrideWith((ref) async => lang),
            userRepositoryProvider.overrideWith((ref) async => user),
            clockProvider.overrideWithValue(() => now),
            appInfoProvider.overrideWith((ref) async => 'test'),
          ],
        );
        var container = scope();
        addTearDown(() async {
          container.dispose();
          await user.close();
          dir.deleteSync(recursive: true);
        });
        final saved = await GeneratedVocabularyStore(
          db,
          lang: lang,
        ).save(response(lang), selected: {0}, now: now, verify: () {});
        final cardId = saved.addedIds.single;
        final deckId = generatedVocabularyDeckId(lang);
        container.listen(decksProvider, (_, _) {});
        container.listen(wordListProvider, (_, _) {});
        container.listen(vocabBreakdownProvider, (_, _) {});
        final deck = (await container.read(decksProvider.future)).single;
        expect(deck.id, deckId);
        expect(deck.name, 'Generierte Vokabeln');
        expect(deck.totalWords, 1);
        expect(deck.seenWords, 0);
        expect(deck.masteredWords, 0);
        expect(deck.isActive, isTrue);
        expect(deck.description, isNot(contains('Story')));
        final initialWord = (await container.read(wordListProvider.future))
            .single;
        expect(initialWord.id, cardId);
        expect(initialWord.entry.headword, word(lang)['form']);
        expect(initialWord.entry.translation, word(lang)['gloss_de']);
        expect(initialWord.box, 0);
        expect(initialWord.reviewCount, 0);
        expect((await container.read(vocabBreakdownProvider.future)).unseen, 1);

        // The same activation switch controls mixed introduction while an
        // explicit deck session remains tied to its own fixed context.
        final activation = container.read(
          deckActiveControllerProvider.notifier,
        );
        await activation.setActive(deckId, false);
        await settle();
        expect(
          (await container.read(decksProvider.future)).single.isActive,
          isFalse,
        );
        const mixedArgs = (deckId: '', kind: DeckSessionKind.mixed, size: 5);
        final mixed = deckSessionControllerProvider(mixedArgs);
        var mixedSubscription = container.listen(mixed, (_, _) {});
        for (var i = 0; i < 50 && container.read(mixed).loading; i++) {
          await settle();
        }
        expect(container.read(mixed).error, isNull);
        expect(container.read(mixed).total, 0);
        expect(container.read(mixed).pass, isNull);
        mixedSubscription.close();
        container.invalidate(mixed);
        await activation.setActive(deckId, true);
        await settle();
        mixedSubscription = container.listen(mixed, (_, _) {});
        for (var i = 0; i < 50 && container.read(mixed).loading; i++) {
          await settle();
        }
        expect(container.read(mixed).error, isNull);
        expect(container.read(mixed).pass?.item.card.id, cardId);
        mixedSubscription.close();
        container.invalidate(mixed);

        final args = (deckId: deckId, kind: DeckSessionKind.learn, size: 1);
        final session = deckSessionControllerProvider(args);
        final subscription = container.listen(session, (_, _) {});
        for (var i = 0; i < 50 && container.read(session).loading; i++) {
          await settle();
        }
        final pass = container.read(session).pass;
        expect(container.read(session).error, isNull);
        expect(pass, isNotNull);
        expect(pass!.item.card.id, cardId);
        expect(pass.sentence.text, word(lang)['sentence']);
        expect(pass.sentence.gapText, word(lang)['form']);
        container.read(session.notifier).submit(pass.item.card.form);
        for (var i = 0; i < 50 && !container.read(session).saved; i++) {
          await settle();
        }
        expect(container.read(session).error, isNull);
        expect(container.read(session).saved, isTrue);
        await settle();
        final learned = (await container.read(wordListProvider.future)).single;
        expect([learned.id, learned.box, learned.reviewCount], [cardId, 3, 1]);
        expect(learned.dueAt, isNotNull);
        expect(learned.sentence, word(lang)['sentence']);
        final state = (await user.cardStates([cardId]))[cardId]!;
        expect(state.box, learned.box);
        expect(state.dueAt, learned.dueAt);
        expect((await user.reviewsFor(cardId)).single.boxAfter, learned.box);
        final after = (await container.read(decksProvider.future)).single;
        expect(after.seenWords, 1);
        expect(after.masteredWords, 0);
        expect(after.description, isNot(contains('Story')));
        final counts = await container.read(vocabBreakdownProvider.future);
        expect(counts.building, 1);
        expect(counts.unseen, 0);
        final resolver = await container.read(practiceResolverProvider.future);
        expect(resolver.storyCollectionIds, isEmpty);
        expect(await db.select(db.storyLearningAdditions).get(), isEmpty);
        subscription.close();

        container.dispose();
        await user.close();
        db = UserDatabase.file(file);
        user = DriftUserRepository(
          db,
          lang: lang,
          contentIds: (_) async => <String>{},
        );
        container = scope();
        final restarted = (await container.read(wordListProvider.future))
            .single;
        expect(
          [restarted.id, restarted.box, restarted.reviewCount],
          [cardId, 3, 1],
        );
        expect(restarted.dueAt, learned.dueAt);
        expect(restarted.sentence, learned.sentence);
        expect(restarted.entry.translation, word(lang)['gloss_de']);
        expect(
          (await container.read(decksProvider.future)).single.isActive,
          isTrue,
        );
        expect(await user.reviewsFor(cardId), hasLength(1));
      },
    );
  }
}
