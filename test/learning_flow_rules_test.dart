import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sqlite3/sqlite3.dart' as sql;
import 'package:sprachapp/data/user/drift_user_repository.dart';
import 'package:sprachapp/data/user/user_database.dart';
import 'package:sprachapp/domain/content.dart';
import 'package:sprachapp/domain/preferences.dart';
import 'package:sprachapp/domain/srs_state.dart';
import 'package:sprachapp/presentation/practice/deck_session_controller.dart';
import 'package:sprachapp/presentation/providers/database_providers.dart';
import 'package:sprachapp/presentation/providers/learning_providers.dart';

import 'fixtures/deck_repositories.dart';

/// Six decks of five cards; every card has its own lemma and form.
class RulesContent extends TestContent {
  RulesContent() : super(library: true);
  @override
  PracticeItem item(String id) {
    final base = super.item(id);
    return PracticeItem(
      card: ContentCard(
        id: id,
        lang: 'en',
        form: 'word-$id',
        formNorm: 'word-$id',
        lemmaId: 'unique-$id',
        lemma: 'unique-$id',
        pos: 'NOUN',
        translationDe: base.card.translationDe,
      ),
      sentences: [
        for (final s in base.sentences)
          CardSentence(
            cardId: id,
            sentenceId: s.sentenceId,
            position: s.position,
            text: 'Say word-$id now.',
            translationDe: s.translationDe,
            gapStart: 4,
            gapEnd: 4 + 'word-$id'.length,
          ),
      ],
      otherFormsOfLemma: const {},
    );
  }
}

ContentCard card(String id, {String? lemma, String? group}) => ContentCard(
  id: id,
  lang: 'en',
  form: 'f-$id',
  formNorm: 'f-$id',
  lemmaId: lemma ?? id,
  lemma: lemma ?? id,
  pos: 'NOUN',
  learning: group == null
      ? null
      : LearningTarget(groupId: group, primaryCardId: id, topic: 't', note: ''),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  final now = DateTime(2026, 10, 25, 12);

  group('one queue rule', () {
    final cards = {
      for (final id in [
        for (var i = 0; i < 12; i++) 'due$i',
        for (var i = 0; i < 6; i++) 'a$i',
        for (var i = 0; i < 6; i++) 'b$i',
        for (var i = 0; i < 3; i++) 's$i',
      ])
        id: card(id),
    };
    UserCardState due(String id, int daysAgo) => UserCardState(
      cardId: id,
      box: 2,
      dueAt: now.subtract(Duration(days: daysAgo)),
    );

    test('goal 10 with seven due: seven reviews, then three new', () {
      final states = {for (var i = 0; i < 7; i++) 'due$i': due('due$i', i)};
      final q = buildMixedQueue(
        activeDeckCardIds: const [],
        deckSources: [NewWordSource('A', [for (var i = 0; i < 6; i++) 'a$i'])],
        cards: cards,
        states: states,
        now: now,
        size: 10,
      );
      expect(q.map((e) => e.cardId), [
        for (var i = 6; i >= 0; i--) 'due$i', // longest overdue first
        'a0', 'a1', 'a2',
      ]);
      expect(q.take(7).every((e) => e.source == null), isTrue);
    });

    test('at least ten due: no new target inside those ten seats', () {
      final states = {for (var i = 0; i < 12; i++) 'due$i': due('due$i', i)};
      final q = buildMixedQueue(
        activeDeckCardIds: const [],
        deckSources: [NewWordSource('A', ['a0', 'a1'])],
        cards: cards,
        states: states,
        now: now,
        size: 10,
      );
      expect(q, hasLength(10));
      expect(q.every((e) => e.cardId.startsWith('due')), isTrue);
    });

    test('nothing due or new: empty, never silent early; Vorab only explicitly', () {
      final states = {
        'a0': UserCardState(cardId: 'a0', box: 3, dueAt: now.add(const Duration(days: 3))),
        'a1': UserCardState(cardId: 'a1', box: 1, dueAt: now.add(const Duration(days: 1))),
      };
      expect(
        buildMixedQueue(
          activeDeckCardIds: const [],
          deckSources: [NewWordSource('A', ['a0', 'a1'])],
          cards: cards,
          states: states,
          now: now,
        ),
        isEmpty,
      );
      final early = buildEarlyQueue(scopeIds: ['a0', 'a1'], cards: cards, states: states, now: now, size: 10);
      expect(early.map((e) => e.cardId), ['a1', 'a0']); // soonest due first
      expect(early.every((e) => e.mode == ReviewMode.early), isTrue);
    });

    test('two decks plus stories take turns, keep their own order, continue after lastSource', () {
      final sources = [
        NewWordSource('A', [for (var i = 0; i < 6; i++) 'a$i']),
        NewWordSource('B', [for (var i = 0; i < 6; i++) 'b$i']),
        NewWordSource(storySourceId, ['s0', 's1', 's2']),
      ];
      const order = ['A', 'B', storySourceId];
      List<String> pick(int limit, String? last) => [
        for (final t in selectNewTargets(sources: sources, cards: cards, states: const {},
            limit: limit, order: order, lastSource: last))
          t.cardId,
      ];
      expect(pick(6, null), ['a0', 'b0', 's0', 'a1', 'b1', 's1']);
      // Small sessions do not restart at the first deck.
      expect(pick(2, 'A'), ['b0', 's0']);
      expect(pick(2, storySourceId), ['a0', 'b0']);
      // A deactivated last source: continue with the next source in order.
      expect(
        [for (final t in selectNewTargets(sources: sources.skip(1).toList(), cards: cards,
            states: const {}, limit: 2, order: const ['A', 'X', 'B', storySourceId], lastSource: 'X')) t.cardId],
        ['b0', 's0'],
      );
    });

    test('empty source skipped; shared target once, no extra weight; inadmissible skipped', () {
      final states = {
        'a0': UserCardState(cardId: 'a0', box: 0, dueAt: null, disabled: true),
        'b0': UserCardState(cardId: 'b0', box: 0, dueAt: null, retired: true),
      };
      final grouped = {
        ...cards,
        'a1': card('a1', group: 'g'),
        'b1': card('b1', group: 'g'), // same learning group as a1
      };
      final picked = selectNewTargets(
        sources: [
          NewWordSource('A', ['a0', 'a1', 'a2', 'shared']),
          NewWordSource('Empty', const []),
          NewWordSource('B', ['b0', 'shared', 'b1', 'b2']),
        ],
        cards: {...grouped, 'shared': card('shared')},
        states: states,
        limit: 6,
        order: const ['A', 'Empty', 'B'],
      );
      expect(picked.map((t) => '${t.source}:${t.cardId}'), [
        'A:a1', // a0 disabled
        'B:b2', // b0 retired, shared belongs to A, b1 shares a1's group
        'A:a2',
        'A:shared', // B has nothing admissible left; shared counted once
      ]);
    });
  });

  group('sessions on one learning state', () {
    late Directory dir;
    late File file;
    late DriftUserRepository user;
    late ProviderContainer c;
    final content = RulesContent();
    ProviderContainer scope() => ProviderContainer(
      overrides: [
        contentRepositoryProvider.overrideWith((_) => content),
        userRepositoryProvider.overrideWith((_) => user),
        clockProvider.overrideWithValue(() => now),
        appInfoProvider.overrideWith((_) async => 'test'),
      ],
    );
    setUp(() async {
      dir = Directory.systemTemp.createTempSync('flow-rules-');
      file = File('${dir.path}/user.db');
      user = DriftUserRepository(UserDatabase.file(file), lang: 'en');
      for (var i = 2; i < 6; i++) {
        await user.setDeckActive('deck-$i', false, now: now);
      }
      // A saved story word from an inactive deck: only "Aus Storys" offers it.
      await user.ensureCards(['deck-3/0'], now: now, origin: CardOrigin.story);
      // Saved from a story, also in active deck-0: offered once, by deck-0.
      await user.ensureCards(['deck-0/1'], now: now, origin: CardOrigin.story);
      await user.savePreferences(const PracticePreferences(dailyGoal: 4));
      c = scope();
    });
    tearDown(() async {
      c.dispose();
      await user.close();
      dir.deleteSync(recursive: true);
    });

    Future<DeckSessionController> open(DeckSessionArgs args) async {
      final p = deckSessionControllerProvider(args);
      c.listen(p, (_, _) {});
      for (var i = 0; i < 200 && c.read(p).loading; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      expect(c.read(p).error, isNull);
      return c.read(p.notifier);
    }

    DeckSessionState read(DeckSessionArgs args) => c.read(deckSessionControllerProvider(args));

    Future<String> answer(DeckSessionArgs args) async {
      final id = read(args).pass!.item.card.id;
      c.read(deckSessionControllerProvider(args).notifier).submit('word-$id');
      for (var i = 0; i < 200 && !read(args).saved; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      expect(read(args).saved, isTrue);
      return id;
    }

    Future<void> restart() async {
      c.dispose();
      await user.close();
      user = DriftUserRepository(UserDatabase.file(file), lang: 'en');
      c = scope();
    }

    Future<int> done() async => (await c.read(learningProgressProvider.future)).goal.done;

    test('rotation over small sessions survives restart and moves only on completion', () async {
      const one = (deckId: '', kind: DeckSessionKind.mixed, size: 1);
      final firsts = <String>[];
      // Opening without answering never moves the rotation.
      await open(one);
      expect(read(one).pass!.item.card.id, 'deck-0/0');
      await restart();
      for (var round = 0; round < 4; round++) {
        await open(one);
        firsts.add(await answer(one));
        await restart();
      }
      // deck-0 → deck-1 → Aus Storys (inactive decks skipped) → deck-0 again;
      // deck-0/1 belongs to deck-0 once, it is never offered twice.
      expect(firsts, ['deck-0/0', 'deck-1/0', 'deck-3/0', 'deck-0/1']);
      expect(await user.lastNewWordSource(), 'deck-0');
      expect(await done(), 4);
    });

    test('aborted session: unanswered targets are not counted and come back', () async {
      const three = (deckId: '', kind: DeckSessionKind.mixed, size: 3);
      await open(three);
      expect(await answer(three), 'deck-0/0');
      await c.read(deckSessionControllerProvider(three).notifier).next();
      final shown = read(three).pass!.item.card.id; // displayed, never answered
      expect((await user.cardStates([shown]))[shown]!.box, 0);
      await restart();
      expect(await done(), 1);
      await open(three);
      expect(read(three).pass!.item.card.id, shown);
    });

    test('direct deck learning, then Play: one state, correct daily rest', () async {
      const deck = (deckId: 'deck-1', kind: DeckSessionKind.learn, size: 0);
      await open(deck);
      final learned = [await answer(deck)];
      await c.read(deckSessionControllerProvider(deck).notifier).next();
      learned.add(await answer(deck));
      expect(learned, ['deck-1/0', 'deck-1/1']);
      await restart();
      const play = (deckId: '', kind: DeckSessionKind.mixed, size: 0);
      await open(play);
      expect(read(play).total, 2); // goal 4 minus 2 done today
      expect(read(play).goalReached, isFalse);
      expect(learned, isNot(contains(read(play).pass!.item.card.id)));
      final states = await user.cardStates(learned);
      expect(states.values.map((s) => s.box), [3, 3]);
    });

    test('goal reached: Play continues voluntarily, no empty session, no repeats of today', () async {
      await user.savePreferences(const PracticePreferences(dailyGoal: 1));
      await restart();
      const play = (deckId: '', kind: DeckSessionKind.mixed, size: 0);
      await open(play);
      final first = await answer(play);
      await restart();
      await open(play);
      expect(read(play).goalReached, isTrue);
      expect(read(play).total, 1);
      expect(read(play).message, 'Tagesziel erreicht – du lernst freiwillig weiter.');
      expect(read(play).pass!.item.card.id, isNot(first));
    });

    test('Revue and Vorab count a target once; repeated practice does not', () async {
      const play = (deckId: '', kind: DeckSessionKind.mixed, size: 2);
      await open(play);
      final a = await answer(play);
      await c.read(deckSessionControllerProvider(play).notifier).next();
      final b = await answer(play);
      await restart();
      expect(await done(), 2);
      const revue = (deckId: 'deck-0', kind: DeckSessionKind.revue, size: 0);
      await open(revue);
      expect(read(revue).pass!.item.card.id, a);
      await answer(revue); // the same target again
      await restart();
      expect(await done(), 2);
      const early = (deckId: '', kind: DeckSessionKind.early, size: 0);
      await open(early);
      expect({a, b}, contains(read(early).pass!.item.card.id));
      await answer(early);
      await restart();
      expect(await done(), 2);
    });

    test('a due card practised only in Revue stays due and returns in Play once counted', () async {
      await user.ensureCards(['deck-1/4'], now: now, origin: CardOrigin.deck);
      final due = now.subtract(const Duration(days: 2));
      expect(await user.recordReview(ReviewRecord(
        id: 'old', cardId: 'deck-1/4', createdAt: now.subtract(const Duration(days: 6)),
        mode: ReviewMode.deck, sentenceId: 'deck-1/4/s1', firstAttemptCorrect: true, errorCount: 0,
        revealed: false, hintUsed: false, boxBefore: 0, boxAfter: 2, dueAtAfter: due, responseMs: 1,
        appVersion: 'test', deviceId: 'fixture')), isTrue);
      await restart();
      const revue = (deckId: 'deck-1', kind: DeckSessionKind.revue, size: 0);
      await open(revue);
      expect(await answer(revue), 'deck-1/4');
      final kept = (await user.cardStates(['deck-1/4']))['deck-1/4']!;
      expect([kept.box, kept.dueAt], [2, due]); // early rule keeps box and date
      await restart();
      expect(await done(), 1);
      const play = (deckId: '', kind: DeckSessionKind.mixed, size: 0);
      await open(play);
      expect(read(play).pass!.item.card.id, 'deck-1/4');
      expect(read(play).pass!.mode, ReviewMode.mixed);
    });

    test('opening sessions never changes learned states before an answer', () async {
      await user.ensureCards(['deck-1/4'], now: now, origin: CardOrigin.deck);
      final due = now.subtract(const Duration(days: 2));
      final r = ReviewRecord(
        id: 'old-pass', cardId: 'deck-1/4', createdAt: now.subtract(const Duration(days: 6)),
        mode: ReviewMode.deck, sentenceId: 'deck-1/4/s1', firstAttemptCorrect: true, errorCount: 0,
        revealed: false, hintUsed: false, boxBefore: 0, boxAfter: 2, dueAtAfter: due, responseMs: 1,
        appVersion: 'test', deviceId: 'fixture');
      expect(await user.recordReview(r), isTrue);
      final before = (await user.cardStates(['deck-1/4']))['deck-1/4']!;
      await restart();
      const play = (deckId: '', kind: DeckSessionKind.mixed, size: 0);
      await open(play);
      expect(read(play).pass!.item.card.id, 'deck-1/4'); // due before new
      await restart();
      final after = (await user.cardStates(['deck-1/4']))['deck-1/4']!;
      expect([after.box, after.dueAt], [before.box, before.dueAt]);
      expect(await user.reviewsFor('deck-1/4'), hasLength(1));
    });

    test('rotation metadata is language-separated and leaves preferences alone', () async {
      await user.saveLastNewWordSource('deck-1');
      final pt = DriftUserRepository(UserDatabase.file(file), lang: 'pt-BR');
      addTearDown(pt.close);
      expect(await pt.lastNewWordSource(), isNull);
      expect(await user.lastNewWordSource(), 'deck-1');
      expect((await user.preferences()).dailyGoal, 4);
    });
  });

  test('v6 database gains only the nullable rotation column', () async {
    final dir = Directory.systemTemp.createTempSync('rotation-migration-');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/user.db');
    var repo = DriftUserRepository(UserDatabase.file(file), lang: 'en');
    await repo.savePreferences(const PracticePreferences(dailyGoal: 17));
    await repo.close();
    final raw = sql.sqlite3.open(file.path);
    raw.execute('ALTER TABLE language_learning_preferences DROP COLUMN new_word_source');
    raw.execute('PRAGMA user_version = 6');
    raw.close();
    repo = DriftUserRepository(UserDatabase.file(file), lang: 'en');
    expect((await repo.preferences()).dailyGoal, 17);
    expect(await repo.lastNewWordSource(), isNull);
    await repo.saveLastNewWordSource(storySourceId);
    expect(await repo.lastNewWordSource(), storySourceId);
    expect((await repo.preferences()).dailyGoal, 17);
    await repo.close();
  });
}
