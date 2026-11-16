import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/data/learning/practice_item_resolver.dart';
import 'package:sprachapp/data/user/drift_user_repository.dart';
import 'package:sprachapp/data/user/generated_vocabulary_store.dart';
import 'package:sprachapp/data/user/user_database.dart';
import 'package:sprachapp/domain/editorial_stories.dart';
import 'package:sprachapp/models/home_models.dart';
import 'package:sprachapp/presentation/providers/learning_providers.dart';
import 'package:sprachapp/presentation/providers/practice_resolver_providers.dart';
import 'package:sprachapp/presentation/providers/premium_access_provider.dart';
import 'package:sprachapp/presentation/providers/reading_providers.dart';
import 'package:sprachapp/presentation/providers/story_learning_providers.dart';
import 'package:sprachapp/screens/home/widgets/daily_suggestion.dart';
import 'package:sprachapp/theme/app_theme.dart';

import 'data/generated_vocabulary_store_test.dart' show response;

final _date = DateTime(2026, 11, 15);
final _free = _story(freeLinglossaStoryId('en'));
const _locked = Story(
  id: 'premium',
  title: 'The Lost Ticket',
  topic: 'Reisen',
  level: 'A2',
  readingMinutes: 3,
);

Story _story(String id) => Story(
  id: id,
  title: 'Linglossa',
  topic: 'Sprachenlernen',
  level: 'A2',
  readingMinutes: 3,
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  test('skips locked reading even when it is the best progress match', () {
    final reading = {_locked.id: ReadingEntry(fraction: 0.6, updatedAt: _date)};
    expect(
      dailyReadingSuggestion(
        stories: [_locked, _free],
        reading: reading,
        premium: false,
        date: _date,
      ),
      (story: _free, started: false),
    );
    expect(
      dailyReadingSuggestion(
        stories: [_locked, _free],
        reading: reading,
        premium: true,
        date: _date,
      ),
      (story: _locked, started: true),
    );
  });

  test('hides the suggestion if all accessible stories are finished', () {
    expect(
      dailyReadingSuggestion(
        stories: [_locked, _free],
        reading: {
          _free.id: ReadingEntry(
            fraction: 0.4,
            updatedAt: _date,
            finished: true,
          ),
        },
        premium: false,
        date: _date,
      ),
      isNull,
    );
  });

  test('chooses the most recently read eligible unfinished story', () {
    final another = _story('another');
    expect(
      dailyReadingSuggestion(
        stories: [_locked, another, _free],
        reading: {
          _locked.id: ReadingEntry(
            fraction: 0.8,
            updatedAt: _date,
            finished: true,
          ),
          another.id: ReadingEntry(fraction: 0.2, updatedAt: _date),
          _free.id: ReadingEntry(
            fraction: 0.7,
            updatedAt: _date.subtract(const Duration(days: 1)),
          ),
        },
        premium: true,
        date: _date,
      ),
      (story: another, started: true),
    );
  });

  testWidgets('the one accessible suggestion opens the free story at 2x text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final opened = <Story>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          learningNowProvider.overrideWithValue(_date),
          learningProgressProvider.overrideWith(
            (ref) async => (
              goal: const DailyGoal(done: 10, target: 10),
              week: const WeekProgress([]),
            ),
          ),
          libraryStoriesProvider.overrideWithValue(AsyncData([_locked, _free])),
          premiumContentAccessProvider.overrideWithValue(false),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(body: DailySuggestionCard(onOpenStory: opened.add)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text(_locked.title), findsNothing);
    expect(find.text(_free.title), findsOneWidget);
    await tester.tap(find.text('Story lesen'));
    expect(opened, [_free]);
  });

  testWidgets('free generated words can be suggested without Premium', (
    tester,
  ) async {
    final db = UserDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final resolver = await tester.runAsync(() async {
      final store = GeneratedVocabularyStore(db, lang: 'en');
      await store.save(
        response('en', freeSample: true),
        selected: {0},
        now: _date,
        verify: () {},
      );
      return PracticeItemResolver.load(
        DriftUserRepository(db, lang: 'en', ownsDatabase: false),
        null,
      );
    });
    expect(resolver!.freeGeneratedIds, hasLength(1));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          learningNowProvider.overrideWithValue(_date),
          learningProgressProvider.overrideWith(
            (_) async => (
              goal: const DailyGoal(done: 0, target: 10),
              week: const WeekProgress([]),
            ),
          ),
          practiceResolverProvider.overrideWith((_) async => resolver),
          libraryStoriesProvider.overrideWithValue(const AsyncData([])),
          premiumContentAccessProvider.overrideWithValue(false),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(body: DailySuggestionCard(onOpenStory: (_) {})),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Neue Wörter üben'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
