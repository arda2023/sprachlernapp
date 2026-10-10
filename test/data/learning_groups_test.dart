import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sql;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sprachapp/data/content/content_database.dart';
import 'package:sprachapp/data/content/drift_content_repository.dart';
import 'package:sprachapp/data/learning/practice_item_resolver.dart';
import 'package:sprachapp/data/user/drift_user_repository.dart';
import 'package:sprachapp/data/user/user_database.dart';
import 'package:sprachapp/domain/content.dart';
import 'package:sprachapp/domain/review_pass.dart';
import 'package:sprachapp/domain/story_learning.dart';
import 'package:sprachapp/domain/srs_state.dart';
import 'package:sprachapp/presentation/providers/database_providers.dart';
import 'package:sprachapp/presentation/providers/deck_providers.dart';
import 'package:sprachapp/presentation/providers/learning_providers.dart';
import 'package:sprachapp/presentation/providers/story_learning_providers.dart';
import 'package:sprachapp/presentation/practice/deck_session_controller.dart';

import 'support.dart';
import 'single_sentence_content_test.dart' show schemaTwo;
import '../fixtures/story_learning.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 10, 6);
  late Directory tmp;
  late DriftContentRepository content;
  late DriftUserRepository user;
  late ProviderContainer scope;
  DriftUserRepository openUser() => DriftUserRepository(
    UserDatabase.file(File('${tmp.path}/test-user.sqlite')),
    lang: 'en',
  );
  setUp(() async {
    tmp = Directory.systemTemp.createTempSync('learning-groups-test-');
    final file = buildFixturePack(
      tmp,
      tweak: (db) {
        schemaTwo(db);
        db.execute('ALTER TABLE cards ADD COLUMN learning TEXT');
        // Existing fixture tombstone has a live head, retained as a historical row.
        for (final r in db.select('SELECT id FROM cards')) {
          final id = r['id'] as String;
          db.execute('UPDATE cards SET learning=? WHERE id=?', [
            jsonEncode({
              'group_id': id == 'card-gone-old' ? 'card-went' : id,
              'primary_card_id': id == 'card-gone-old' ? 'card-went' : id,
              'topic': 'fixture',
              'related': [],
              'note': 'synthetic fixture',
            }),
            id,
          ]);
        }
        for (final form in ['trip', 'journey', 'travel']) {
          db.execute('INSERT INTO lemmas(id,lang,lemma,pos) VALUES(?,?,?,?)', [
            form,
            'en',
            form,
            'NOUN',
          ]);
          db.execute(
            'INSERT INTO senses(id,lang,lemma_id,sense_key,gloss_de) VALUES(?,?,?,?,?)',
            ['sense-$form', 'en', form, '$form#reise', 'Reise'],
          );
          db.execute(
            'INSERT INTO cards(id,lang,form,form_norm,lemma_id,sense_id,pos,form_kind,translation_de,learning) VALUES(?,?,?,?,?,?,?,?,?,?)',
            [
              form,
              'en',
              form,
              form,
              form,
              'sense-$form',
              'NOUN',
              'base',
              'Reise',
              jsonEncode({
                'group_id': 'travel-group',
                'primary_card_id': 'trip',
                'topic': 'travel',
                'related': [],
                'note': 'synthetic travel group',
              }),
            ],
          );
          final n = ['trip', 'journey', 'travel'].indexOf(form) + 5;
          db.execute(
            'INSERT INTO deck_cards(id,deck_id,card_id,position) VALUES(?,?,?,?)',
            ['dc-$form', 'deck-allg', form, n],
          );
          db.execute(
            'INSERT INTO deck_words(id,lang,form_norm,deck_id,primary_card_id,position) VALUES(?,?,?,?,?,?)',
            [form, 'en', form, 'deck-allg', form, n],
          );
          db.execute(
            'INSERT INTO sentences(id,lang,text,translation_de) VALUES(?,?,?,?)',
            ['s-$form', 'en', 'A $form is planned.', 'Eine Reise ist geplant.'],
          );
          db.execute(
            'INSERT INTO card_sentences(id,card_id,sentence_id,position,gap_start,gap_end,accepted,valid_alternatives) VALUES(?,?,?,?,?,?,?,?)',
            [
              'cs-$form',
              form,
              's-$form',
              1,
              2,
              2 + form.length,
              jsonEncode([form]),
              jsonEncode(form == 'trip' ? ['journey'] : []),
            ],
          );
        }
        db.execute('UPDATE content_releases SET schema_version=3');
      },
    );
    content = DriftContentRepository(ContentDatabase.open(file, lang: 'en'));
    user = openUser();
    scope = ProviderContainer(
      overrides: [
        contentRepositoryProvider.overrideWith((ref) async => content),
        userRepositoryProvider.overrideWith((ref) async => user),
        clockProvider.overrideWithValue(() => now),
        appInfoProvider.overrideWith((ref) async => 'test'),
      ],
    );
  });
  tearDown(() async {
    scope.dispose();
    await user.close();
    await content.close();
    tmp.deleteSync(recursive: true);
  });
  Future<ReviewRecord> review(
    String id,
    String passId, {
    List<String> attempts = const [],
    bool reveal = false,
  }) async {
    await user.ensureCards([id], now: now, origin: CardOrigin.deck);
    final item = (await content.practiceItems([id])).single;
    final pass = ReviewPass(
      id: passId,
      item: item,
      sentence: item.practiceSentence,
      state: (await user.cardStates([id]))[id],
      mode: ReviewMode.deck,
      startedAt: now,
    );
    for (final input in attempts) {
      pass.submit(input, now);
    }
    if (reveal) pass.reveal(now);
    pass.submit(item.card.form, now);
    final record = pass.complete(
      now: now,
      appVersion: 'test',
      deviceId: 'fixture',
    )!;
    expect(await user.recordReview(record), isTrue);
    expect(await user.recordReview(record), isFalse);
    expect(
      pass.complete(now: now, appVersion: 'test', deviceId: 'fixture'),
      isNull,
    );
    return record;
  }

  Future<StoryLearningCandidate> candidate(String form) async {
    final members = await content.selectionCards(['trip', 'journey', 'travel']);
    final card = members.singleWhere((c) => c.id == form);
    final original = storyCandidate(
      surface: form,
      sense: card.senseId!,
      card: card,
    );
    return StoryLearningCandidate(
      storyId: original.storyId,
      revision: original.revision,
      lang: 'en',
      sentence: original.sentence,
      token: original.token,
      card: card,
      groupMembers: members,
    );
  }

  test(
    'new user: counts, deck, mixed and provider recomputation agree',
    () async {
      scope.listen(decksProvider, (_, _) {});
      scope.listen(practiceResolverProvider, (_, _) {});
      expect((await content.decks()).single.cardCount, 5);
      expect((await scope.read(decksProvider.future)).single.totalWords, 5);
      expect((await scope.read(vocabBreakdownProvider.future)).unseen, 5);
      final resolver = await PracticeItemResolver.load(user, content);
      final ids = await resolver.activePrimaryIds();
      expect(ids.where(['trip', 'journey', 'travel'].contains), ['trip']);
      const args = (deckId: 'deck-allg', kind: DeckSessionKind.learn, size: 5);
      final provider = deckSessionControllerProvider(args);
      final sub = scope.listen(provider, (_, _) {});
      for (var i = 0; i < 100 && scope.read(provider).pass == null; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      final pass = scope.read(provider).pass!;
      scope.invalidate(practiceResolverProvider);
      scope.invalidate(decksProvider);
      await scope.pump();
      await scope
          .read(decksProvider.future)
          .timeout(const Duration(seconds: 5));
      expect(identical(scope.read(provider).pass, pass), isTrue);
      sub.close();
    },
  );
  test('learned secondary and multiple learned members survive with flags, logs, revue and restart', () async {
    await review('journey', 'old-journey');
    await user.setCardFlags(
      'journey',
      favorite: true,
      note: 'keep',
      inPlaylist: true,
    );
    var resolver = await PracticeItemResolver.load(user, content);
    expect((await resolver.activePrimaryIds()).contains('trip'), isFalse);
    final c = await candidate('travel');
    expect((await user.addStoryWord(c, now: now)).cardId, 'journey');
    await review('travel', 'old-travel');
    final before = (await user.reviewsFor('journey')).single;
    await user.close();
    user = openUser();
    resolver = await PracticeItemResolver.load(user, content);
    final queue = buildDeckQueue(
      deckCardIds: await content.deckCardIds('deck-allg'),
      cards: resolver.cards,
      states: resolver.states,
      kind: DeckSessionKind.revue,
      now: now.add(const Duration(days: 30)),
    );
    expect(queue.map((e) => e.cardId), unorderedEquals(['journey', 'travel']));
    expect(resolver.states['journey']!.note, 'keep');
    expect(resolver.states['journey']!.favorite, isTrue);
    expect((await user.reviewsFor('journey')).single.id, before.id);
    expect(await user.reviewCounts(['journey', 'travel']), {
      'journey': 1,
      'travel': 1,
    });
    expect((await user.allCardStates()).containsKey('trip'), isFalse);
  });
  test('story synonym adds canonical fixed sentence once, keeps clicked surface and no cross-identity binding', () async {
    final c = await candidate('journey');
    final results = await Future.wait([
      user.addStoryWord(c, now: now),
      user.addStoryWord(c, now: now),
    ]);
    expect(results.map((r) => r.cardId).toSet(), {'trip'});
    expect(c.token.surface, 'journey');
    expect(c.sentence.text, contains('journey'));
    expect(
      (await content.practiceItems(['trip'])).single.practiceSentence.text,
      'A trip is planned.',
    );
    expect(await user.identityBindings(), isEmpty);
    expect((await user.allCardStates()).keys, ['trip']);
    expect((await scope.read(wordListProvider.future)).single.id, 'trip');
    expect((await scope.read(vocabBreakdownProvider.future)).unseen, 5);
  });
  test(
    'local exact member from an older story is reused, never replaced',
    () async {
      final old = storyCandidate(surface: 'journey', sense: 'sense-journey');
      final local = (await user.addStoryWord(old, now: now)).cardId!;
      final c = await candidate('travel');
      expect((await user.addStoryWord(c, now: now)).cardId, local);
      final resolver = await PracticeItemResolver.load(user, content);
      expect((await resolver.activePrimaryIds()).contains('trip'), isFalse);
      expect(
        (await resolver.practiceItems([local])).single.practiceSentence.text,
        old.sentence.text,
      );
      expect((await user.allCardStates()).length, 1);
    },
  );
  test('neutral repeated synonym, wrong then synonym, persisted once and read back after restart', () async {
    final clean = await review(
      'trip',
      'clean',
      attempts: ['journey', 'journey'],
    );
    expect(
      [
        clean.boxAfter,
        clean.errorCount,
        clean.hintUsed,
        clean.firstAttemptCorrect,
      ],
      [3, 0, false, true],
    );
    final wrong = await review(
      'trip',
      'wrong',
      attempts: ['banana', 'journey'],
    );
    expect(
      [
        wrong.boxAfter,
        wrong.errorCount,
        wrong.hintUsed,
        wrong.firstAttemptCorrect,
      ],
      [1, 1, false, false],
    );
    final shown = await review(
      'trip',
      'reveal',
      attempts: ['journey'],
      reveal: true,
    );
    expect([shown.revealed, shown.hintUsed, shown.boxAfter], [true, false, 1]);
    await user.close();
    user = openUser();
    expect((await user.reviewsFor('trip')).map((r) => r.id), [
      'clean',
      'wrong',
      'reveal',
    ]);
    expect((await user.cardStates(['trip']))['trip']!.box, 1);
  });
  test('schema 3 rejects missing metadata, invalid head and duplicate contrast tags', () {
    for (final payload in [
      null,
      jsonEncode({
        'group_id': 'travel-group',
        'primary_card_id': 'missing',
        'topic': 'travel',
        'related': [],
        'note': 'fixture',
      }),
      jsonEncode({
        'group_id': 'travel-group',
        'primary_card_id': 'trip',
        'topic': 'travel',
        'related': ['x', 'x'],
        'note': 'fixture',
      }),
    ]) {
      final bad = File('${tmp.path}/fixture.sqlite')
          .copySync('${tmp.path}/bad.sqlite');
      final raw = sql.sqlite3.open(bad.path);
      raw.execute('UPDATE cards SET learning=? WHERE id=?', [payload, 'trip']);
      raw.close();
      expect(
        () => ContentDatabase.open(bad, lang: 'en'),
        throwsA(isA<ContentUnavailable>()),
      );
    }
  });
}
