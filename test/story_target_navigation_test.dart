import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/data/user/drift_user_repository.dart';
import 'package:sprachapp/data/user/user_database.dart';
import 'package:sprachapp/data/learning/practice_item_resolver.dart';
import 'package:sprachapp/domain/content.dart';
import 'package:sprachapp/domain/story_learning.dart';
import 'package:sprachapp/domain/srs_state.dart';
import 'package:sprachapp/models/story_models.dart';
import 'package:sprachapp/models/word_list_models.dart';
import 'package:sprachapp/presentation/providers/database_providers.dart';
import 'package:sprachapp/presentation/providers/learning_providers.dart';
import 'package:sprachapp/screens/stories/widgets/word_popover.dart';
import 'package:sprachapp/screens/words/widgets/word_list_item.dart';
import 'package:sprachapp/theme/app_theme.dart';

import 'fixtures/story_learning.dart';
import 'fixtures/deck_repositories.dart';

class CuratedStoryContent extends TestContent {
  @override
  Future<Set<String>> allCardIds() async => {'curated'};
  @override
  Future<List<String>> deckCardIds(String deckId) async => ['curated'];
  @override
  PracticeItem item(String id) {
    final c = storyCandidate(card: exactCard());
    return PracticeItem(
      card: exactCard(),
      sentences: [
        CardSentence(
          cardId: 'curated',
          sentenceId: 'curated/s1',
          position: 1,
          text: c.sentence.text,
          translationDe: c.sentence.translation,
          gapStart: c.token.start,
          gapEnd: c.token.end,
        ),
      ],
      otherFormsOfLemma: {},
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  test('existing and local Story targets survive restart, lists and mixed eligibility', () async {
    final dir = Directory.systemTemp.createTempSync('story-target-isolated-');
    final file = File('${dir.path}/user.db');
    final content = CuratedStoryContent();
    var user = DriftUserRepository(UserDatabase.file(file), lang: 'en');
    final now = DateTime(2026, 10, 15, 12);
    await user.deviceId();
    final curated = storyCandidate(card: exactCard());
    final local = storyCandidate(surface: 'rucksack', sense: 'local-sense');
    final existing = await user.addStoryWord(curated, now: now);
    final added = await user.addStoryWord(local, now: now);
    expect(existing.cardId, 'curated');
    expect(added.cardId, local.identity.localId);
    await user.addStoryWord(curated, now: now);
    await user.addStoryWord(local, now: now);
    expect((await user.allCardStates()).length, 2);
    await user.close();
    user = DriftUserRepository(UserDatabase.file(file), lang: 'en');
    final scope = ProviderContainer(
      overrides: [
        contentRepositoryProvider.overrideWith((_) => content),
        userRepositoryProvider.overrideWith((_) => user),
        clockProvider.overrideWithValue(() => now),
      ],
    );
    final words = await scope.read(wordListProvider.future);
    expect(words.map((w) => w.id).toSet(), {existing.cardId, added.cardId});
    Future<Set<String>> eligible() async {
      final r = await PracticeItemResolver.load(user, content);
      return buildMixedQueue(
        targetsResolved: true,
        activeDeckCardIds: await r.activePrimaryIds(),
        storyAdditions: r.additions,
        cards: r.cards,
        states: r.states,
        now: now,
        size: 20,
      ).map((e) => e.cardId).toSet();
    }

    expect(await eligible(), contains(existing.cardId));
    await user.setCardFlags(existing.cardId!, disabled: true);
    expect(await eligible(), contains(added.cardId));
    await user.setCardFlags(added.cardId!, disabled: true);
    expect(await eligible(), isNot(contains(added.cardId)));
    await user.setCardFlags(added.cardId!, disabled: false);
    expect(await eligible(), contains(added.cardId));
    expect(await user.reviewsFor(added.cardId!), isEmpty);
    expect((await user.allCardStates()).length, 2);
    scope.dispose();
    await user.close();
    dir.deleteSync(recursive: true);
  });
  testWidgets(
    'confirmed action opens exact persisted ID among identical headwords',
    (tester) async {
      final words = [
        for (final id in ['other', 'saved'])
          VocabWord(
            id: id,
            entry: const WordEntry(
              headword: 'backpack',
              partOfSpeech: 'NOUN',
              translation: 'Rucksack',
            ),
            sentence: 'She carries a backpack.',
            sentenceTranslation: 'Sie trägt einen Rucksack.',
            box: 0,
            lastSeenAt: DateTime(2026, 10, 15),
            reviewCount: 0,
          ),
      ];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [wordListProvider.overrideWith((_) async => words)],
          child: MaterialApp(
            theme: buildAppTheme(),
            home: Scaffold(
              body: WordPopover(
                surface: 'backpack',
                entry: words.first.entry,
                mark: null,
                status: const StoryAddResult(StoryAddState.available),
                onAdd: () async =>
                    const StoryAddResult(StoryAddState.added, cardId: 'saved'),
              ),
            ),
          ),
        ),
      );
      expect(find.text('In Wortliste ansehen'), findsNothing);
      await tester.tap(find.text('Zum Lernen hinzufügen'));
      await tester.pumpAndSettle();
      expect(find.text('Zum Lernen hinzugefügt'), findsOneWidget);
      await tester.tap(find.text('In Wortliste ansehen'));
      await tester.pumpAndSettle();
      final rows = tester.widgetList<WordListItem>(find.byType(WordListItem));
      expect(rows.map((w) => w.word.id), ['saved']);
    },
  );
}
