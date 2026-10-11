import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sprachapp/data/user/user_database.dart';
import 'package:sprachapp/data/user/drift_user_repository.dart';
import 'package:sprachapp/domain/srs_state.dart';
import 'package:sprachapp/presentation/providers/database_providers.dart';
import 'package:sprachapp/presentation/providers/deck_providers.dart';
import 'package:sprachapp/presentation/providers/learning_providers.dart';
import 'package:sprachapp/presentation/practice/deck_session_controller.dart';

import 'fixtures/form_learning.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('form sessions, reactive providers, flags and restart share exact identities', () async {
    final dir = Directory.systemTemp.createTempSync('form-flow-');
    final content = formContent(dir);
    var user = DriftUserRepository(
      UserDatabase.file(File('${dir.path}/synthetic.sqlite')),
      lang: 'en',
    );
    final now = DateTime(2026, 10, 10, 12);
    ProviderContainer scope() => ProviderContainer(
      overrides: [
        contentRepositoryProvider.overrideWith((ref) async => content),
        userRepositoryProvider.overrideWith((ref) async => user),
        clockProvider.overrideWithValue(() => now),
        appInfoProvider.overrideWith((ref) async => 'test'),
      ],
    );
    var container = scope();
    addTearDown(() async {
      container.dispose();
      await user.close();
      await content.close();
      dir.deleteSync(recursive: true);
    });
    Future<void> settle() async =>
        Future<void>.delayed(const Duration(milliseconds: 50));
    container.listen(vocabBreakdownProvider, (_, _) {});
    container.listen(lexicalBreakdownProvider, (_, _) {});
    container.listen(wordListProvider, (_, _) {});
    container.listen(decksProvider, (_, _) {});
    expect((await container.read(vocabBreakdownProvider.future)).unseen, 9);
    expect((await container.read(lexicalBreakdownProvider.future)).total, 3);
    await settle();
    final decks = await content.decks();
    final cards = await content.selectionCards(await content.allCardIds());
    final base = decks.singleWhere((d) => d.slug == 'base');
    final past = decks.singleWhere((d) => d.slug == 'past');
    Future<String> session(String deckId) async {
      final provider = deckSessionControllerProvider((
        deckId: deckId,
        kind: DeckSessionKind.learn,
        size: 3,
      ));
      final subscription = container.listen(provider, (_, _) {});
      for (var i = 0; i < 60 && container.read(provider).pass == null; i++) {
        await settle();
      }
      expect(container.read(provider).error, isNull);
      final first = container.read(provider).pass!;
      expect(first.boxBefore, 0);
      final id = first.item.card.id;
      // Live provider changes must not replace the frozen current pass/context.
      await user.setDeckActive(deckId, false, now: now);
      await settle();
      expect(identical(container.read(provider).pass, first), isTrue);
      final controller = container.read(provider.notifier);
      controller.submit(first.item.card.form);
      controller.submit(first.item.card.form);
      for (var i = 0; i < 60 && !container.read(provider).saved; i++) {
        await settle();
      }
      expect(container.read(provider).saved, isTrue);
      await controller.commit();
      expect(await user.reviewsFor(id), hasLength(1));
      subscription.close();
      await settle();
      return id;
    }

    final baseId = await session(base.id);
    final pastId = await session(past.id);
    expect(baseId, isNot(pastId));
    expect(cards.singleWhere((c) => c.id == baseId).formFunction, 'base');
    expect(cards.singleWhere((c) => c.id == pastId).formFunction, 'past');
    await settle();
    expect(
      (await container.read(learningProgressProvider.future)).goal.done,
      2,
    );
    expect(await container.read(wordListProvider.future), hasLength(2));
    final pp = cards.singleWhere(
      (c) => c.lemma == 'run' && c.formFunction == 'past_participle',
    );
    final add = await user.addStoryWord(
      formCandidate(pp, local: true),
      now: now,
    );
    await settle();
    final words = await container.read(wordListProvider.future);
    expect(words, hasLength(3));
    expect(
      words.singleWhere((w) => w.id == add.cardId).entry.partOfSpeech,
      'Partizip Perfekt',
    );
    final before = (await container.read(vocabBreakdownProvider.future)).total;
    await container
        .read(wordActionsProvider)
        .save(
          add.cardId!,
          favorite: true,
          disabled: true,
          note: 'nur diese Form',
        );
    await settle();
    expect(
      (await container.read(vocabBreakdownProvider.future)).total,
      before - 1,
    );
    expect(
      (await container.read(wordListProvider.future))
          .singleWhere((w) => w.id == add.cardId)
          .note,
      'nur diese Form',
    );
    expect((await user.cardStates([baseId]))[baseId]!.note, isEmpty);
    // A duplicate view retains precisely the same state and progress.
    final duplicate = (await container.read(decksProvider.future)).singleWhere(
      (d) => d.id == decks.singleWhere((d) => d.slug == 'base-again').id,
    );
    expect(duplicate.seenWords, 1);
    container.dispose();
    await user.close();
    user = DriftUserRepository(
      UserDatabase.file(File('${dir.path}/synthetic.sqlite')),
      lang: 'en',
    );
    container = scope();
    final restored = await container.read(wordListProvider.future);
    expect(restored, hasLength(3));
    expect(restored.singleWhere((w) => w.id == add.cardId).isDisabled, isTrue);
    expect(
      (await container.read(learningProgressProvider.future)).goal.done,
      2,
    );
    expect(
      (await user.addStoryWord(formCandidate(pp), now: now)).cardId,
      add.cardId,
    );
    expect(await user.allCardStates(), hasLength(3));
  });
}
