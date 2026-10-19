import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sprachapp/domain/content.dart';
import 'package:sprachapp/domain/review_activity.dart';
import 'package:sprachapp/presentation/providers/database_providers.dart';
import 'package:sprachapp/presentation/providers/deck_providers.dart';
import 'package:sprachapp/presentation/providers/story_learning_providers.dart';

import 'fixtures/deck_repositories.dart';

class MetadataContent extends TestContent {
  MetadataContent() : super(library: true);
  int fullReads = 0;
  @override
  Future<List<PracticeItem>> practiceItems(List<String> ids) {
    fullReads++;
    return super.practiceItems(ids);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Home recent words exactly match full items without loading sentences',
    () async {
      final content = MetadataContent(), user = TestUser(library: true);
      final container = ProviderContainer(
        overrides: [
          contentRepositoryProvider.overrideWith((_) => content),
          userRepositoryProvider.overrideWith((_) => user),
          clockProvider.overrideWithValue(() => testNow),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await user.close();
      });
      final decks = await container.read(decksProvider.future);
      expect(content.fullReads, 0);
      final resolver = await container.read(practiceResolverProvider.future);
      final reviews = await user.lastReviewTimes();
      for (final deck in decks) {
        final ids = await resolver.deckPracticeIds(deck.id);
        final seen = [
          for (final id in ids)
            if (resolver.states[id] case final s?)
              if (s.isActive && s.box >= 1) s,
        ];
        final recent = [
          for (final s in seen)
            if (reviews[s.cardId] case final at?) (s.cardId, at),
        ]..sort((a, b) => b.$2.compareTo(a.$2));
        final previous = await resolver.practiceItems(
          recent.take(5).map((r) => r.$1).toList(),
        );
        expect(
          deck.recentWords.map((w) => (w.word, w.translation)),
          previous.map((i) => (i.card.form, i.card.translationDe ?? '')),
        );
        expect(
          deck.totalWords,
          ids.where((id) => resolver.states[id]?.isActive ?? true).length,
        );
        expect(deck.seenWords, seen.length);
        expect(deck.masteredWords, seen.where((s) => s.box == 5).length);
      }
    },
  );
}
