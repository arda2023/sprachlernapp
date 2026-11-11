// Characterization tests for the session rules in DeckSessionController.start:
// session size, the Premium filter on sources and the direct-deck gate. They
// pin today's behavior before these rules move into the domain layer.
//
// Already covered elsewhere and not repeated here: explicit sizes and the
// free/paid split of due reviews and deck sources
// (premium_session_access_test), the daily remainder and the reached goal
// with goal 1 (learning_flow_rules_test, "sessions on one learning state").
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/domain/content.dart';
import 'package:sprachapp/domain/preferences.dart';
import 'package:sprachapp/domain/repositories.dart';
import 'package:sprachapp/domain/srs_state.dart';
import 'package:sprachapp/domain/story_learning.dart';
import 'package:sprachapp/presentation/practice/deck_session_controller.dart';
import 'package:sprachapp/presentation/providers/database_providers.dart';
import 'package:sprachapp/presentation/providers/premium_access_provider.dart';

import 'fixtures/deck_repositories.dart';
import 'premium_session_access_test.dart'
    show AccessContent, freeDeck, paidDeck;

/// TestUser plus the two optional capabilities the mixed queue asks for:
/// explicit story additions and the new-word rotation.
class _StoryUser extends TestUser
    implements StoryLearningRepository, NewWordRotationStore {
  final additions = <String, DateTime>{};
  String? lastSource;

  @override
  Future<Map<String, DateTime>> explicitStoryAdditions() async =>
      Map.of(additions);
  @override
  Future<Map<String, String>> identityBindings() async => {};
  @override
  Future<List<PracticeItem>> localPracticeItems() async => [];
  @override
  Future<CardSentence?> localHistoricalSentence(
    String cardId,
    String contextId,
  ) async => null;
  @override
  Future<StoryAddResult> storyLearningStatus(StoryLearningCandidate c) =>
      throw UnimplementedError();
  @override
  Future<StoryAddResult> addStoryWord(
    StoryLearningCandidate c, {
    required DateTime now,
  }) => throw UnimplementedError();
  @override
  Future<String?> lastNewWordSource() async => lastSource;
  @override
  Future<void> saveLastNewWordSource(String source) async =>
      lastSource = source;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _StoryUser user;
  late ProviderContainer container;
  late bool premium;
  final content = AccessContent();

  setUp(() {
    premium = true;
    user = _StoryUser();
    container = ProviderContainer(
      overrides: [
        premiumContentAccessProvider.overrideWith((ref) => premium),
        contentRepositoryProvider.overrideWith((ref) => content),
        userRepositoryProvider.overrideWith((ref) => user),
        appInfoProvider.overrideWith((ref) async => 'test'),
        clockProvider.overrideWithValue(() => testNow),
      ],
    );
  });
  tearDown(() async {
    container.dispose();
    await user.close();
  });

  DeckSessionState state(DeckSessionArgs args) =>
      container.read(deckSessionControllerProvider(args));

  Future<void> waitUntil(bool Function() ready) async {
    for (var i = 0; i < 200 && !ready(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    expect(ready(), isTrue);
  }

  Future<DeckSessionState> open(DeckSessionArgs args) async {
    container.listen(deckSessionControllerProvider(args), (_, _) {});
    await waitUntil(() => !state(args).loading);
    return state(args);
  }

  Future<String> answer(DeckSessionArgs args) async {
    final card = state(args).pass!.item.card;
    container
        .read(deckSessionControllerProvider(args).notifier)
        .submit(card.form);
    await waitUntil(() => state(args).saved);
    return card.id;
  }

  /// A seen card that is not due; [today] also logs a first pass at testNow.
  void seen(String id, {bool today = false}) {
    final due = testNow.add(const Duration(days: 3));
    user.states[id] = UserCardState(cardId: id, box: 2, dueAt: due);
    if (!today) return;
    user.records['today-$id'] = ReviewRecord(
      id: 'today-$id',
      cardId: id,
      createdAt: testNow,
      mode: ReviewMode.mixed,
      sentenceId: '$id/s1',
      firstAttemptCorrect: true,
      errorCount: 0,
      revealed: false,
      hintUsed: false,
      boxBefore: 0,
      boxAfter: 2,
      dueAtAfter: due,
      responseMs: 1,
      appVersion: 'test',
      deviceId: 'test',
    );
  }

  void goal(int words) => user.prefs = PracticePreferences(dailyGoal: words);

  const goalMessage = 'Tagesziel erreicht – du lernst freiwillig weiter.';

  group('session size', () {
    test('size > 0 is used as given, below and above the daily goal', () async {
      goal(3);
      seen('$freeDeck/0', today: true);
      final four = await open((
        deckId: '',
        kind: DeckSessionKind.mixed,
        size: 4,
      ));
      expect(four.error, isNull);
      expect(four.total, 4);
      expect(four.goalReached, isFalse);
      expect(four.message, isNull);
      final one = await open((
        deckId: '',
        kind: DeckSessionKind.mixed,
        size: 1,
      ));
      expect(one.total, 1);
    });

    test('size > 0 is kept when the goal is already reached', () async {
      goal(1);
      seen('$freeDeck/0', today: true);
      final s = await open((deckId: '', kind: DeckSessionKind.mixed, size: 4));
      expect(s.total, 4);
      expect(s.goalReached, isTrue);
      expect(s.message, goalMessage);
    });

    test('size 0 with a remainder: only the rest of the daily goal', () async {
      goal(3);
      seen('$freeDeck/0', today: true);
      final s = await open((deckId: '', kind: DeckSessionKind.mixed, size: 0));
      expect(s.total, 2);
      expect(s.goalReached, isFalse);
      expect(s.message, isNull);
      final deck = await open((
        deckId: freeDeck,
        kind: DeckSessionKind.learn,
        size: 0,
      ));
      expect(deck.total, 2);
    });

    test('size < 0 continues with the full daily goal', () async {
      goal(3);
      seen('$freeDeck/0', today: true);
      final s = await open((deckId: '', kind: DeckSessionKind.mixed, size: -1));
      expect(s.total, 3);
      expect(s.goalReached, isFalse);
      expect(s.message, isNull);
    });

    test('goal reached: size 0 starts a full daily goal again', () async {
      goal(2);
      seen('$freeDeck/0', today: true);
      seen('$freeDeck/1', today: true);
      // More completed than the goal still counts as "no remainder".
      seen('$freeDeck/2', today: true);
      final s = await open((deckId: '', kind: DeckSessionKind.mixed, size: 0));
      expect(s.total, 2);
      expect(s.goalReached, isTrue);
      expect(s.message, goalMessage);
    });

    for (final kind in [DeckSessionKind.revue, DeckSessionKind.early]) {
      test('${kind.name} with size 0 ignores the remainder', () async {
        goal(3);
        seen('$freeDeck/0', today: true);
        for (var i = 1; i < 4; i++) {
          seen('$freeDeck/$i');
        }
        final s = await open((deckId: freeDeck, kind: kind, size: 0));
        expect(s.error, isNull);
        expect(s.total, 3); // the full goal, not the remainder of 2
        expect(s.goalReached, isFalse);
        expect(
          s.message,
          kind == DeckSessionKind.early
              ? 'Vorab-Üben: Eine saubere Antwort lässt Stufe und Fälligkeit unverändert.'
              : isNull,
        );
      });

      test('${kind.name} with a reached goal shows no goal message', () async {
        goal(2);
        for (var i = 0; i < 4; i++) {
          seen('$freeDeck/$i', today: i < 2);
        }
        final s = await open((deckId: freeDeck, kind: kind, size: 0));
        expect(s.total, 2);
        expect(s.goalReached, isTrue);
        expect(s.message, isNot(goalMessage));
      });
    }

    test(
      'global early practice with size 0 uses the full daily goal',
      () async {
        goal(3);
        seen('$freeDeck/0', today: true);
        for (var i = 1; i < 4; i++) {
          seen('$paidDeck/$i');
        }
        final s = await open((
          deckId: '',
          kind: DeckSessionKind.early,
          size: 0,
        ));
        expect(s.total, 3);
      },
    );
  });

  group('story source and Premium', () {
    test(
      'without Premium a short session still fills after the free turn',
      () async {
        premium = false;
        user.lastSource = freeDeck;
        const one = (deckId: '', kind: DeckSessionKind.mixed, size: 1);
        final s = await open(one);
        expect(s.error, isNull);
        expect(s.total, 1);
        expect(s.finished, isFalse);
        expect(await answer(one), startsWith('$freeDeck/'));
        expect(user.lastSource, freeDeck);
      },
    );

    // Both decks are switched off, so only "Aus Storys" can offer a new word.
    void onlyStories() {
      user.active[freeDeck] = false;
      user.active[paidDeck] = false;
    }

    void added(String id, {CardOrigin origin = CardOrigin.deck}) {
      user.states[id] = UserCardState(
        cardId: id,
        box: 0,
        dueAt: null,
        origin: origin,
      );
      user.additions[id] = testNow.subtract(const Duration(days: 1));
    }

    const play = (deckId: '', kind: DeckSessionKind.mixed, size: 5);

    test(
      'with Premium an explicit story addition takes the story turn',
      () async {
        onlyStories();
        added('$paidDeck/0');
        final s = await open(play);
        expect(s.error, isNull);
        expect(s.total, 1);
        expect(await answer(play), '$paidDeck/0');
        expect(user.lastSource, storySourceId);
      },
    );

    test('with Premium decks and the story source take turns', () async {
      user.active[paidDeck] = false;
      added('$paidDeck/0');
      const two = (deckId: '', kind: DeckSessionKind.mixed, size: 2);
      await open(two);
      expect(await answer(two), startsWith('$freeDeck/'));
      expect(user.lastSource, freeDeck);
      await container.read(deckSessionControllerProvider(two).notifier).next();
      expect(await answer(two), '$paidDeck/0');
      expect(user.lastSource, storySourceId);
    });

    test('without Premium explicit story additions are not offered', () async {
      premium = false;
      onlyStories();
      added('$freeDeck/0');
      added('$paidDeck/0');
      final s = await open(play);
      expect(s.error, isNull);
      expect(s.total, 0);
      expect(s.finished, isTrue);
      expect(s.pass, isNull);
    });

    test('the same free addition is offered once Premium is active', () async {
      onlyStories();
      added('$freeDeck/0');
      final s = await open(play);
      expect(s.total, 1);
      expect(s.pass!.item.card.id, '$freeDeck/0');
    });

    test('without Premium a paid story word never enters free Play', () async {
      premium = false;
      user.active[paidDeck] = false;
      added('$paidDeck/0', origin: CardOrigin.story);
      const all = (deckId: '', kind: DeckSessionKind.mixed, size: 10);
      final s = await open(all);
      expect(s.total, 5);
      final ids = <String>[];
      while (!state(all).finished) {
        ids.add(await answer(all));
        await container
            .read(deckSessionControllerProvider(all).notifier)
            .next();
      }
      expect(ids.every((id) => id.startsWith('$freeDeck/')), isTrue);
      expect(user.lastSource, freeDeck);
      expect(user.states['$paidDeck/0']!.box, 0);
    });

    test('without Premium a story-origin card of the free deck still takes '
        'the story turn', () async {
      // Characterization: current behavior. The controller drops the story
      // source from the order and passes no explicit additions without
      // Premium, but buildMixedQueue still builds the story source from
      // cards whose saved origin is "story".
      premium = false;
      onlyStories();
      user.states['$freeDeck/0'] = const UserCardState(
        cardId: '$freeDeck/0',
        box: 0,
        dueAt: null,
        origin: CardOrigin.story,
      );
      final s = await open(play);
      expect(s.total, 1);
      expect(await answer(play), '$freeDeck/0');
      expect(user.lastSource, storySourceId);
    });
  });

  test(
    'a paid deck opened directly without Premium fails with its message',
    () async {
      premium = false;
      for (final kind in DeckSessionKind.values) {
        if (kind == DeckSessionKind.mixed) continue;
        final s = await open((deckId: paidDeck, kind: kind, size: 5));
        expect(s.error, isA<StateError>());
        expect(
          (s.error as StateError).message,
          'Für diesen Stapel brauchst du Premium.',
        );
        expect(s.pass, isNull);
        expect(s.finished, isFalse);
      }
      expect(user.states, isEmpty);
    },
  );
}
