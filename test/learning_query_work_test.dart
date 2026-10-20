import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sprachapp/data/user/user_database.dart';
import 'package:sprachapp/data/user/drift_user_repository.dart';
import 'package:sprachapp/domain/content.dart';
import 'package:sprachapp/domain/review_activity.dart';
import 'package:sprachapp/presentation/providers/streak_providers.dart';
import 'package:sprachapp/domain/srs_state.dart';
import 'package:sprachapp/presentation/providers/database_providers.dart';
import 'package:sprachapp/presentation/providers/deck_providers.dart';
import 'package:sprachapp/presentation/providers/learning_providers.dart';
import 'package:sprachapp/presentation/practice/deck_session_controller.dart';

import 'fixtures/deck_repositories.dart';

class MeasuredContent extends TestContent {
  MeasuredContent() : super(library: true);
  final counts = <String, int>{};
  void hit(String name) => counts.update(name, (n) => n + 1, ifAbsent: () => 1);
  @override
  Future<List<DeckSummary>> decks() {
    hit('decks');
    return super.decks();
  }

  @override
  Future<List<ContentCard>> selectionCards(Iterable<String> ids) {
    hit('selection');
    return super.selectionCards(ids);
  }

  @override
  Future<List<DeckPracticeTarget>> deckPracticeTargets(String id) {
    hit('targets');
    return super.deckPracticeTargets(id);
  }
}

class MeasuredUser extends DriftUserRepository {
  MeasuredUser() : super(UserDatabase(NativeDatabase.memory()), lang: 'en');
  int histories = 0;
  int activityReads = 0;
  @override
  Future<List<ReviewActivity>> reviewActivity(DateTime from, DateTime until) {
    activityReads++;
    return super.reviewActivity(from, until);
  }

  @override
  Future<List<ReviewRecord>> reviewsFor(String id) {
    histories++;
    return super.reviewsFor(id);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'redesign streak uses one bulk read and never per-card histories',
    () async {
      final user = MeasuredUser();
      final seed = TestUser(library: true);
      for (final review in seed.records.values) {
        await user.ensureCards(
          [review.cardId],
          now: testNow,
          origin: CardOrigin.deck,
        );
        await user.recordReview(review);
      }
      await seed.close();
      final c = ProviderContainer(
        overrides: [
          userRepositoryProvider.overrideWith((_) => user),
          clockProvider.overrideWithValue(() => testNow),
        ],
      );
      addTearDown(() async {
        c.dispose();
        await user.close();
      });
      final streak = await c.read(streakProvider.future);
      expect(streak.activeDays, isNotEmpty);
      expect(user.activityReads, 1);
      expect(user.histories, 0);
    },
  );
  test('open back and toggle reuse pack metadata and use bulk review reads', () async {
    final content = MeasuredContent(), user = MeasuredUser();
    final seed = TestUser(library: true);
    for (final r in seed.records.values) {
      await user.ensureCards([r.cardId], now: testNow, origin: CardOrigin.deck);
      await user.recordReview(r);
    }
    await seed.close();
    final c = ProviderContainer(
      overrides: [
        contentRepositoryProvider.overrideWith((_) => content),
        userRepositoryProvider.overrideWith((_) => user),
        clockProvider.overrideWithValue(() => testNow),
        appInfoProvider.overrideWith((_) async => 'test'),
      ],
    );
    addTearDown(() async {
      c.dispose();
      await user.close();
    });
    final builds = <String, int>{};
    void hit(String s) => builds.update(s, (n) => n + 1, ifAbsent: () => 1);
    c.listen(decksProvider, (_, next) {
      if (next.hasValue && !next.isLoading) hit('decks');
    });
    c.listen(vocabBreakdownProvider, (_, next) {
      if (next.hasValue && !next.isLoading) hit('vocab');
    });
    c.listen(learningProgressProvider, (_, next) {
      if (next.hasValue && !next.isLoading) hit('goal');
    });
    Future<void> settle() async {
      for (var i = 0; i < 30; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
    }

    await settle();
    debugPrint(
      'INITIAL queries=${content.counts} histories=${user.histories} publications=$builds',
    );
    final before = Map<String, int>.of(content.counts);
    final p = deckSessionControllerProvider((
      deckId: 'deck-0',
      kind: DeckSessionKind.learn,
      size: 5,
    ));
    final session = c.listen(p, (_, _) {});
    await settle();
    expect(c.read(p).error, isNull);
    debugPrint(
      'OPEN queries=${content.counts} histories=${user.histories} publications=$builds',
    );
    session.close();
    await settle();
    debugPrint(
      'BACK queries=${content.counts} histories=${user.histories} publications=$builds',
    );
    await c
        .read(deckActiveControllerProvider.notifier)
        .setActive('deck-0', false);
    await settle();
    debugPrint(
      'TOGGLE queries=${content.counts} histories=${user.histories} publications=$builds',
    );
    if (!const bool.fromEnvironment('BASELINE')) {
      expect(content.counts, before);
      expect(user.histories, 0);
    }
  });
}
