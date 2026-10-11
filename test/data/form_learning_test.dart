import 'dart:io';
import 'dart:convert';

import 'package:sprachapp/data/content/content_database.dart';

import 'single_sentence_content_test.dart' show schemaTwo;

import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/data/content/drift_content_repository.dart';
import 'package:sprachapp/data/learning/practice_item_resolver.dart';
import 'package:sprachapp/data/user/user_database.dart';
import 'package:sprachapp/data/user/drift_user_repository.dart';
import 'package:sprachapp/domain/content.dart';
import 'package:sprachapp/domain/review_pass.dart';
import 'package:sprachapp/domain/srs_state.dart';
import 'package:sprachapp/domain/story_learning.dart';

import '../fixtures/form_learning.dart';
import 'support.dart';

void main() {
  late Directory dir;
  late DriftContentRepository content;
  late UserDatabase db;
  late DriftUserRepository user;
  late Map<String, ContentCard> cards;
  final now = DateTime(2026, 10, 10, 12);
  setUp(() async {
    dir = Directory.systemTemp.createTempSync('form-learning-');
    content = formContent(dir);
    db = UserDatabase.file(File('${dir.path}/synthetic-user.sqlite'));
    user = DriftUserRepository(db, lang: 'en');
    cards = {
      for (final c in await content.selectionCards(await content.allCardIds()))
        '${c.lemma}/${c.formFunction}': c,
    };
  });
  tearDown(() async {
    await user.close();
    await content.close();
    dir.deleteSync(recursive: true);
  });
  Future<PracticeItemResolver> resolver() =>
      PracticeItemResolver.load(user, content);
  Future<void> learn(String id, {DateTime? at}) async {
    await user.ensureCards([id], now: now, origin: CardOrigin.deck);
    final item = (await (await resolver()).practiceItems([id])).single;
    final state = (await user.cardStates([id]))[id]!;
    final pass = ReviewPass(
      id: 'pass-$id-${state.box}',
      item: item,
      sentence: item.practiceSentence,
      state: state,
      mode: ReviewMode.deck,
      startedAt: at ?? now,
    );
    pass.submit(item.card.form, at ?? now);
    final record = pass.complete(
      now: at ?? now,
      appVersion: 'test',
      deviceId: await user.deviceId(),
    )!;
    expect(await user.recordReview(record), isTrue);
    expect(await user.recordReview(record), isFalse);
  }

  Future<(VocabBreakdown, LexicalBreakdown)> counts() async {
    final r = await resolver();
    final active = (await r.activePrimaryIds()).toSet();
    final ids = eligiblePracticeIds(
      activeDeckCardIds: active,
      states: r.states,
      knownCardIds: r.knownIds,
      contentCards: r.cards,
      explicitStoryIds: r.additions.keys.toSet(),
      targetsResolved: true,
    );
    return (
      deriveVocabBreakdown(
        activeDeckCardIds: active,
        cards: r.states,
        knownCardIds: r.knownIds,
        contentCards: r.cards,
        explicitStoryIds: r.additions.keys.toSet(),
        targetsResolved: true,
        now: now,
      ),
      deriveLexicalBreakdown(ids, r.cards, r.states),
    );
  }

  test('nine form exercises are three words; repeated views share state, new forms inherit no box', () async {
    final r = await resolver();
    final ids = await r.activePrimaryIds();
    expect(ids.toSet(), hasLength(9));
    expect(ids, hasLength(9));
    final before = await counts();
    expect(before.$1.unseen, 9);
    expect(before.$2.total, 3);
    expect(before.$2.practiced, 0);
    final cut = cards['cut/base']!;
    await learn(cut.id);
    final after = await counts();
    expect(after.$1.building, 1);
    expect(after.$1.unseen, 8);
    expect(after.$2.total, 3);
    expect(after.$2.practiced, 1);
    expect((await user.allCardStates()).keys, [cut.id]);
    final decks = await content.decks();
    for (final slug in ['base', 'base-again']) {
      final view = await (await resolver()).deckPracticeIds(
        decks.singleWhere((d) => d.slug == slug).id,
      );
      expect(view, contains(cut.id));
    }
    final past = cards['cut/past']!;
    await user.ensureCards([past.id], now: now, origin: CardOrigin.deck);
    expect((await user.cardStates([past.id]))[past.id]!.box, 0);
    expect(await user.reviewsFor(past.id), isEmpty);
  });

  test('all due homographs survive; new segment limits lemma/surface per session only', () async {
    final r = await resolver();
    final ids = await r.activePrimaryIds();
    final q = buildMixedQueue(
      targetsResolved: true,
      activeDeckCardIds: ids,
      cards: r.cards,
      states: r.states,
      now: now,
      size: 20,
    );
    expect(q, hasLength(3));
    expect(q.map((e) => r.cards[e.cardId]!.lemma).toSet(), hasLength(3));
    for (final function in ['base', 'past', 'past_participle']) {
      await learn(
        cards['cut/$function']!.id,
        at: now.subtract(const Duration(days: 20)),
      );
    }
    final learned = await resolver();
    final mixed = buildMixedQueue(
      targetsResolved: true,
      activeDeckCardIds: [],
      cards: learned.cards,
      states: learned.states,
      now: now,
      size: 20,
    );
    expect(mixed.map((e) => e.cardId).toSet(), {
      for (final f in ['base', 'past', 'past_participle']) cards['cut/$f']!.id,
    });
    final pastDeck = (await content.decks()).singleWhere(
      (d) => d.slug == 'past',
    );
    final revue = buildDeckQueue(
      targetsResolved: true,
      deckCardIds: await learned.deckPracticeIds(pastDeck.id),
      cards: learned.cards,
      states: learned.states,
      kind: DeckSessionKind.revue,
      now: now,
    );
    expect(revue.map((e) => e.cardId), [cards['cut/past']!.id]);
  });

  test(
    'ordinary ownership does not introduce form-only; explicit Story adds do',
    () async {
      for (final d in await content.decks()) {
        await user.setDeckActive(d.id, d.practiceKind == 'ordinary', now: now);
      }
      expect(await (await resolver()).activePrimaryIds(), [
        cards['cut/base']!.id,
      ]);
      final c = formCandidate(cards['cut/past']!);
      final outcomes = await Future.wait([
        user.addStoryWord(c, now: now),
        user.addStoryWord(c, now: now),
      ]);
      expect(outcomes.map((r) => r.cardId).toSet(), {c.card!.id});
      expect(await user.reviewsFor(c.card!.id), isEmpty);
      final sum = await counts();
      expect(sum.$1.total, 2);
      expect(sum.$2.total, 1);
      expect(
        await user.activeDeckIds(
          (await content.decks())
              .where((d) => d.practiceKind != 'ordinary')
              .map((d) => d.id),
        ),
        isEmpty,
      );
      await user.setCardFlags(c.card!.id, disabled: true);
      expect(
        (await user.addStoryWord(c, now: now)).state,
        StoryAddState.disabled,
      );
      expect((await counts()).$1.total, 1);
      expect((await user.allCardStates()), hasLength(1));
    },
  );

  test('local exact form survives restart, reuses its context and preserves duplicate states', () async {
    final card = cards['run/past_participle']!;
    final local = formCandidate(card, local: true);
    final add = await user.addStoryWord(local, now: now);
    expect(add.cardId, local.identity.localId);
    final context =
        (await user.localPracticeItems()).single.practiceSentence.sentenceId;
    await learn(add.cardId!);
    await user.setCardFlags(
      add.cardId!,
      favorite: true,
      note: 'keep',
      inPlaylist: true,
    );
    final before =
        (await db.customSelect('SELECT * FROM user_cards').getSingle()).data;
    await user.close();
    db = UserDatabase.file(File('${dir.path}/synthetic-user.sqlite'));
    user = DriftUserRepository(db, lang: 'en');
    expect(
      (await user.addStoryWord(formCandidate(card), now: now)).cardId,
      add.cardId,
    );
    expect(
      (await user.localPracticeItems()).single.practiceSentence.sentenceId,
      context,
    );
    expect(
      (await db.customSelect('SELECT * FROM user_cards').getSingle()).data,
      before,
    );
    expect(await db.select(db.learningIdentityBindings).get(), isEmpty);
    expect(await db.select(db.formIdentityBindings).get(), hasLength(1));
    await learn(card.id);
    expect(
      (await user.addStoryWord(formCandidate(card), now: now)).state,
      StoryAddState.conflict,
    );
    expect(await user.allCardStates(), hasLength(2));
    final deck = (await content.decks()).singleWhere(
      (d) => d.slug == 'past_participle',
    );
    expect(
      await (await resolver()).deckPracticeIds(deck.id),
      containsAll([card.id, add.cardId]),
    );
    expect((await counts()).$2.total, 3);
  });

  test('untyped old local cannot be guessed into a function or bypassed by a third copy', () async {
    final card = cards['cut/base']!;
    final old = formCandidate(card, local: true, explicit: false);
    final added = await user.addStoryWord(old, now: now);
    expect(
      (await user.addStoryWord(formCandidate(card), now: now)).state,
      StoryAddState.conflict,
    );
    final r = await resolver();
    expect(r.notices, isNotEmpty);
    expect(await r.activePrimaryIds(), isNot(contains(cards['cut/past']!.id)));
    expect((await user.allCardStates()).keys, [added.cardId]);
  });

  test('local form needs approved complete context; disabled binding prevents bypass', () async {
    final card = cards['run/past_participle']!;
    final unapproved = formCandidate(card, local: true, approved: false);
    expect((await user.addStoryWord(unapproved, now: now)).cardId, isNull);
    final valid = formCandidate(card, local: true);
    final incomplete = StoryLearningCandidate(
      storyId: valid.storyId,
      revision: valid.revision,
      lang: valid.lang,
      sentence: StorySentence(
        id: valid.sentence.id,
        text: valid.sentence.text,
        translation: valid.sentence.translation,
        paragraph: 0,
        tokens: [valid.token],
      ),
      token: valid.token,
    );
    expect((await user.addStoryWord(incomplete, now: now)).cardId, isNull);
    expect(await user.allCardStates(), isEmpty);
    final add = await user.addStoryWord(valid, now: now);
    await user.setCardFlags(add.cardId!, disabled: true);
    expect(
      (await user.addStoryWord(formCandidate(card), now: now)).state,
      StoryAddState.disabled,
    );
    expect(await user.allCardStates(), hasLength(1));
  });

  test(
    'a preserved curated binding does not misclassify a different proven form',
    () async {
      final base = cards['cut/base']!;
      await learn(base.id);
      final identity = LearningIdentity('en', base.formNorm, base.senseId!);
      await db.customStatement(
        'INSERT INTO learning_identity_bindings VALUES (?,?,?,?,?)',
        [identity.key, 'en', base.formNorm, base.senseId!, base.id],
      );
      final result = await user.addStoryWord(
        formCandidate(cards['cut/past']!),
        now: now,
      );
      expect(result.cardId, cards['cut/past']!.id);
      expect((await user.cardStates([result.cardId!]))[result.cardId]!.box, 0);
      expect((await user.cardStates([base.id]))[base.id]!.box, 3);
    },
  );

  test(
    'typed local base is reused by its ordinary owner and form view',
    () async {
      final card = cards['cut/base']!;
      final add = await user.addStoryWord(
        formCandidate(card, local: true),
        now: now,
      );
      final owner = (await content.decks()).singleWhere(
        (d) => d.practiceKind == 'ordinary',
      );
      expect(await (await resolver()).deckPracticeIds(owner.id), [add.cardId]);
      expect(
        (await resolver()).resolveTargets([
          DeckPracticeTarget(cardId: card.id, formTarget: card.formTarget),
        ]),
        [add.cardId],
      );
      expect(await user.allCardStates(), hasLength(1));
    },
  );

  test('schema-3 fallback retains form states and exact return IDs', () async {
    final c = formCandidate(cards['run/past_participle']!);
    await user.addStoryWord(c, now: now);
    await learn(c.card!.id);
    final before =
        (await db.customSelect('SELECT * FROM user_cards').getSingle()).data;
    final oldDir = Directory('${dir.path}/old')..createSync();
    final oldFile = buildFixturePack(
      oldDir,
      tweak: (db) {
        schemaTwo(db);
        db.execute('ALTER TABLE cards ADD COLUMN learning TEXT');
        for (final row in db.select('SELECT id FROM cards')) {
          final id = row['id'];
          final head = id == 'card-gone-old' ? 'card-went' : id;
          db.execute('UPDATE cards SET learning=? WHERE id=?', [
            jsonEncode({
              'group_id': head,
              'primary_card_id': head,
              'topic': 'fixture',
              'related': [],
              'note': 'synthetic',
            }),
            id,
          ]);
        }
        db.execute('UPDATE content_releases SET schema_version=3');
      },
    );
    final old = DriftContentRepository(
      ContentDatabase.open(oldFile, lang: 'en'),
    );
    expect(old.info.schemaVersion, 3);
    final fallback = await PracticeItemResolver.load(user, old);
    expect(fallback.knownIds, isNot(contains(c.card!.id)));
    expect(fallback.notices, isNotEmpty);
    expect(
      (await db.customSelect('SELECT * FROM user_cards').getSingle()).data,
      before,
    );
    await old.close();
    expect((await resolver()).knownIds, contains(c.card!.id));
    expect((await user.reviewsFor(c.card!.id)), hasLength(1));
  });
}
