import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/domain/content.dart';
import 'package:sprachapp/domain/srs_state.dart';
import 'package:sprachapp/presentation/practice/deck_session_controller.dart';
import 'package:sprachapp/presentation/providers/database_providers.dart';
import 'package:sprachapp/presentation/providers/premium_access_provider.dart';

import 'fixtures/deck_repositories.dart';

const freeDeck = '4630a4856f603afdad2f24776298c19a';
const paidDeck = 'paid-topic';

class AccessContent extends TestContent {
  @override
  Future<List<DeckSummary>> decks() async => [
    for (final id in [freeDeck, paidDeck])
      DeckSummary(
        id: id,
        slug: id,
        // A matching display name must never unlock a noncanonical deck.
        titleDe: 'Allgemeine Sprache',
        cardCount: 5,
        cefrBand: 'A1',
        descriptionDe: '',
      ),
  ];

  @override
  PracticeItem item(String id) {
    final base = super.item(id);
    final form = 'word-$id';
    return PracticeItem(
      card: ContentCard(
        id: id,
        lang: 'en',
        form: form,
        formNorm: form,
        lemmaId: id,
        lemma: id,
        pos: 'NOUN',
      ),
      sentences: [
        for (final sentence in base.sentences)
          CardSentence(
            cardId: id,
            sentenceId: sentence.sentenceId,
            position: sentence.position,
            text: 'Say $form now.',
            translationDe: sentence.translationDe,
            gapStart: 4,
            gapEnd: 4 + form.length,
          ),
      ],
      otherFormsOfLemma: const {},
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TestUser user;
  late ProviderContainer container;
  late bool premium;
  final content = AccessContent();

  setUp(() {
    premium = false;
    user = TestUser();
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
  DeckSessionController controller(DeckSessionArgs args) =>
      container.read(deckSessionControllerProvider(args).notifier);

  Future<void> waitUntil(bool Function() ready) async {
    for (var i = 0; i < 200 && !ready(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    expect(ready(), isTrue);
  }

  Future<void> open(DeckSessionArgs args) async {
    container.listen(deckSessionControllerProvider(args), (_, _) {});
    await waitUntil(() => !state(args).loading);
  }

  Future<List<String>> finish(DeckSessionArgs args) async {
    final ids = <String>[];
    while (!state(args).finished) {
      final card = state(args).pass!.item.card;
      ids.add(card.id);
      controller(args).submit(card.form);
      await waitUntil(() => state(args).saved);
      await controller(args).next();
    }
    return ids;
  }

  void expire() {
    premium = false;
    container.invalidate(premiumContentAccessProvider);
  }

  UserCardState due(String id, int days) => UserCardState(
    cardId: id,
    box: 2,
    dueAt: testNow.subtract(Duration(days: days)),
    favorite: true,
    note: 'Behalten',
  );

  test(
    'free canonical deck opens; a paid deck with the same title is denied',
    () async {
      const paid = (deckId: paidDeck, kind: DeckSessionKind.learn, size: 5);
      await open(paid);
      expect(state(paid).error.toString(), contains('Premium'));
      expect(state(paid).pass, isNull);
      expect(user.states, isEmpty);

      const free = (deckId: freeDeck, kind: DeckSessionKind.learn, size: 5);
      await open(free);
      expect(state(free).error, isNull);
      expect(await finish(free), hasLength(5));
      expect(
        user.records.values.every((r) => r.cardId.startsWith('$freeDeck/')),
        isTrue,
      );
    },
  );

  test(
    'free Play filters paid due reviews and new sources before filling seats',
    () async {
      final locked = due('$paidDeck/0', 2);
      user.states['$paidDeck/0'] = locked;
      user.states['$freeDeck/0'] = due('$freeDeck/0', 1);
      const args = (deckId: '', kind: DeckSessionKind.mixed, size: 10);
      await open(args);
      expect(state(args).total, 5);
      final ids = await finish(args);
      expect(ids.first, '$freeDeck/0');
      expect(ids.every((id) => id.startsWith('$freeDeck/')), isTrue);
      expect(user.states['$paidDeck/0'], same(locked));
      expect(
        user.records.values.any((r) => r.cardId.startsWith('$paidDeck/')),
        isFalse,
      );
    },
  );

  test('free global early practice excludes saved paid cards without deleting them', () async {
    final locked = due('$paidDeck/0', -2);
    user.states['$paidDeck/0'] = locked;
    user.states['$freeDeck/0'] = due('$freeDeck/0', -1);
    const args = (deckId: '', kind: DeckSessionKind.early, size: 10);
    await open(args);
    expect(state(args).total, 1);
    expect(await finish(args), ['$freeDeck/0']);
    expect(user.states['$paidDeck/0'], same(locked));
  });

  test(
    'Premium Play retains paid due reviews and both new-word sources',
    () async {
      premium = true;
      user.states['$paidDeck/0'] = due('$paidDeck/0', 2);
      user.states['$freeDeck/0'] = due('$freeDeck/0', 1);
      const args = (deckId: '', kind: DeckSessionKind.mixed, size: 10);
      await open(args);
      expect(state(args).total, 10);
      final ids = await finish(args);
      expect(ids.take(2), ['$paidDeck/0', '$freeDeck/0']);
      expect(ids.where((id) => id.startsWith('$freeDeck/')), hasLength(5));
      expect(ids.where((id) => id.startsWith('$paidDeck/')), hasLength(5));
    },
  );

  test(
    'expiry during a paid answer preserves its commit and stops the next card',
    () async {
      premium = true;
      const args = (deckId: paidDeck, kind: DeckSessionKind.learn, size: 3);
      await open(args);
      final card = state(args).pass!.item.card;
      user.writeGate = Completer<void>();
      controller(args).submit(card.form);
      await waitUntil(() => state(args).committing);
      expire();
      user.writeGate!.complete();
      await waitUntil(() => state(args).saved);
      expect(user.records.values.single.cardId, card.id);
      expect(user.states[card.id]!.box, 3);
      await controller(args).next();
      expect(state(args).finished, isTrue);
      expect(state(args).snapshots, hasLength(1));
      expect(user.records, hasLength(1));
      expect(user.states.keys, [card.id]);
    },
  );

  test(
    'expiry in Play keeps the answered paid card and continues with free cards',
    () async {
      premium = true;
      user.states['$paidDeck/0'] = due('$paidDeck/0', 2);
      user.states['$freeDeck/0'] = due('$freeDeck/0', 1);
      const args = (deckId: '', kind: DeckSessionKind.mixed, size: 10);
      await open(args);
      expect(state(args).pass!.item.card.id, '$paidDeck/0');
      controller(args).submit(state(args).pass!.item.card.form);
      await waitUntil(() => state(args).saved);
      expire();
      await controller(args).next();
      final rest = await finish(args);
      expect(rest, hasLength(5));
      expect(rest.every((id) => id.startsWith('$freeDeck/')), isTrue);
      expect(user.records, hasLength(6));
      expect(state(args).snapshots, hasLength(6));
    },
  );
}
