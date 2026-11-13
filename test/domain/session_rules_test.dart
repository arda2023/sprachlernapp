import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/domain/session_rules.dart';
import 'package:sprachapp/domain/srs_state.dart';

void main() {
  group('session size', () {
    for (final kind in DeckSessionKind.values) {
      test('${kind.name}: explicit positive sizes are kept', () {
        for (final size in [1, 12]) {
          for (final completed in [3, 10, 13]) {
            expect(
              resolveSessionSize(
                requestedSize: size,
                kind: kind,
                dailyGoal: 10,
                completedToday: completed,
              ),
              (limit: size, goalReached: completed >= 10),
            );
          }
        }
      });

      test('${kind.name}: negative size continues with the full goal', () {
        expect(
          resolveSessionSize(
            requestedSize: -1,
            kind: kind,
            dailyGoal: 10,
            completedToday: 3,
          ),
          (limit: 10, goalReached: false),
        );
      });

      test('${kind.name}: zero size with a remainder', () {
        expect(
          resolveSessionSize(
            requestedSize: 0,
            kind: kind,
            dailyGoal: 10,
            completedToday: 3,
          ),
          (
            limit:
                kind == DeckSessionKind.revue || kind == DeckSessionKind.early
                ? 10
                : 7,
            goalReached: false,
          ),
        );
      });

      test('${kind.name}: exactly reached and exceeded goal', () {
        for (final completed in [10, 13]) {
          expect(
            resolveSessionSize(
              requestedSize: 0,
              kind: kind,
              dailyGoal: 10,
              completedToday: completed,
            ),
            (limit: 10, goalReached: true),
          );
        }
      });
    }

    test('negative completed count preserves the upper clamp', () {
      expect(
        resolveSessionSize(
          requestedSize: 0,
          kind: DeckSessionKind.mixed,
          dailyGoal: 10,
          completedToday: -3,
        ),
        (limit: 10, goalReached: false),
      );
    });

    test('zero daily goal is reached and positive size still wins', () {
      for (final size in [-1, 0, 2]) {
        expect(
          resolveSessionSize(
            requestedSize: size,
            kind: DeckSessionKind.learn,
            dailyGoal: 0,
            completedToday: 0,
          ),
          (limit: size > 0 ? size : 0, goalReached: true),
        );
      }
    });

    test('negative daily goal retains the clamp argument error', () {
      expect(
        () => resolveSessionSize(
          requestedSize: 2,
          kind: DeckSessionKind.mixed,
          dailyGoal: -1,
          completedToday: 0,
        ),
        throwsArgumentError,
      );
    });
  });

  group('Premium card filter', () {
    final states = {
      'b': const UserCardState(cardId: 'b', box: 0, dueAt: null),
      'paid': const UserCardState(cardId: 'paid', box: 0, dueAt: null),
      'a': const UserCardState(cardId: 'a', box: 1, dueAt: null),
    };

    test('Premium keeps the same map and state objects', () {
      expect(filterSessionCardStates(states, freeIds: null), same(states));
    });

    test('free IDs restrict cards while preserving map order and values', () {
      final filtered = filterSessionCardStates(states, freeIds: {'a', 'b'});
      expect(filtered.keys, ['b', 'a']);
      expect(filtered['a'], same(states['a']));
      expect(filtered['b'], same(states['b']));
      expect(states.keys, ['b', 'paid', 'a']);
    });

    test('no free IDs leaves no states', () {
      expect(filterSessionCardStates(states, freeIds: {}), isEmpty);
    });
  });

  group('Premium mixed sources', () {
    const sources = [
      NewWordSource('paid-deck', ['paid', 'a']),
      NewWordSource('free-b', ['b', 'paid', 'a', 'b']),
      NewWordSource('free-a', ['a', 'paid']),
      NewWordSource('free-empty', ['paid']),
    ];
    const order = ['paid-deck', 'free-a', 'free-b', 'free-empty'];
    final additions = {
      'story-second': DateTime(2026, 11, 2),
      'story-first': DateTime(2026, 11, 1),
    };
    bool isFreeDeck(String id) => id.startsWith('free-');

    test('Premium keeps decks and additions and appends the story source', () {
      final result = filterMixedSessionSources(
        premium: true,
        freeIds: null,
        isFreeDeck: (_) => throw StateError('Premium must not ask this'),
        activeSources: sources,
        sourceOrder: order,
        storyAdditions: additions,
      );
      expect(result.deckSources, same(sources));
      expect(result.storyAdditions, same(additions));
      expect(result.storyAdditions.keys, ['story-second', 'story-first']);
      expect(result.sourceOrder, [...order, storySourceId]);
      expect(order, ['paid-deck', 'free-a', 'free-b', 'free-empty']);
    });

    test('without Premium filters decks and cards in their original order', () {
      final predicateCalls = <String>[];
      final result = filterMixedSessionSources(
        premium: false,
        freeIds: {'a', 'b'},
        isFreeDeck: (id) {
          predicateCalls.add(id);
          return isFreeDeck(id);
        },
        activeSources: sources,
        sourceOrder: order,
        storyAdditions: additions,
      );
      expect(result.deckSources.map((s) => s.id), [
        'free-b',
        'free-a',
        'free-empty',
      ]);
      expect(result.deckSources.map((s) => s.cardIds), [
        ['b', 'a', 'b'],
        ['a'],
        <String>[],
      ]);
      expect(result.sourceOrder, ['free-a', 'free-b', 'free-empty']);
      expect(result.sourceOrder, isNot(contains(storySourceId)));
      expect(result.storyAdditions, isEmpty);
      expect(predicateCalls, [...sources.map((s) => s.id), ...order]);
      expect(sources[1].cardIds, ['b', 'paid', 'a', 'b']);
      expect(additions.keys, ['story-second', 'story-first']);
    });

    test('an empty free set keeps free deck sources with empty card lists', () {
      final result = filterMixedSessionSources(
        premium: false,
        freeIds: {},
        isFreeDeck: isFreeDeck,
        activeSources: sources,
        sourceOrder: order,
        storyAdditions: additions,
      );
      expect(result.deckSources.map((s) => s.id), [
        'free-b',
        'free-a',
        'free-empty',
      ]);
      expect(result.deckSources.every((s) => s.cardIds.isEmpty), isTrue);
      expect(result.sourceOrder, ['free-a', 'free-b', 'free-empty']);
      expect(result.storyAdditions, isEmpty);
    });

    test('without decks only Premium receives the story source', () {
      for (final premium in [false, true]) {
        final result = filterMixedSessionSources(
          premium: premium,
          freeIds: premium ? null : {},
          isFreeDeck: isFreeDeck,
          activeSources: const [],
          sourceOrder: const [],
          storyAdditions: additions,
        );
        expect(result.deckSources, isEmpty);
        expect(result.sourceOrder, premium ? [storySourceId] : <String>[]);
        expect(result.storyAdditions, premium ? additions : isEmpty);
      }
    });
  });
}
