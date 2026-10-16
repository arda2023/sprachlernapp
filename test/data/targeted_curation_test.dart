import 'dart:io';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sprachapp/data/content/content_database.dart';
import 'package:sprachapp/data/content/drift_content_repository.dart';
import 'package:sprachapp/data/learning/practice_item_resolver.dart';
import 'package:sprachapp/data/user/user_database.dart';
import 'package:sprachapp/data/user/drift_user_repository.dart';
import 'package:sprachapp/domain/content.dart';
import 'package:sprachapp/domain/review_pass.dart';
import 'package:sprachapp/domain/review_activity.dart';
import 'package:sprachapp/domain/srs_state.dart';
import 'package:sprachapp/domain/story_learning.dart';
import 'package:sprachapp/presentation/providers/database_providers.dart';
import 'package:sprachapp/presentation/providers/story_learning_providers.dart';
import '../fixtures/story_learning.dart';
import 'support.dart';

void main() {
  // Separate fixture files/executors are intentionally open side by side.
  final warn = driftRuntimeOptions.dontWarnAboutMultipleDatabases;
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);
  tearDownAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = warn);
  late Directory dir;
  late File beforeFile, afterFile;
  late DriftContentRepository before, after;
  final now = DateTime.utc(2026, 10, 16);
  setUp(() {
    dir = Directory.systemTemp.createTempSync('targeted-curation-');
    File build(String name) {
      final f = File('${dir.path}/$name.sqlite');
      final db = sqlite3.open(f.path);
      db.execute(File('test/fixtures/targeted_curation_$name.sql').readAsStringSync());
      db.close();
      return f;
    }
    beforeFile = build('before'); afterFile = build('after');
    before = DriftContentRepository(ContentDatabase.open(beforeFile, lang: 'en'));
    after = DriftContentRepository(ContentDatabase.open(afterFile, lang: 'en'));
  });
  tearDown(() async {
    await before.close(); await after.close();
    dir.deleteSync(recursive: true);
  });

  test('Python delta preserves shared history, form functions, gloss identity and old tokens', () async {
    final old = await before.practiceItems((await before.allCardIds()).toList());
    final active = await after.practiceItems((await after.allCardIds()).toList());
    expect(old.length, 11); expect(active.length, 10);
    for (final item in old) {
      final historical = await after.historicalSentence(item.card.id, item.practiceSentence.sentenceId);
      expect(historical, isNotNull);
      expect(historical!.text, item.practiceSentence.text);
      expect(historical.validAlternatives, item.practiceSentence.validAlternatives);
      expect(historical.tokens.map((t) => t.surface), item.practiceSentence.tokens.map((t) => t.surface));
      expect(historical.tokens.where((t) => t.surface == 'cut').every((t) => t.translation != null), isTrue);
    }
    final shared = active.singleWhere((i) => i.card.form == 'they');
    expect(shared.practiceSentence.text, 'They cut paper.');
    final cut = active.where((i) => i.card.form == 'cut').toList();
    expect(cut.map((i) => i.card.formFunction).toSet(), {'base','past','past_participle'});
    expect(cut.singleWhere((i) => i.card.formFunction == 'base').practiceSentence.text, 'They cut paper daily.');
    expect(cut.singleWhere((i) => i.card.formFunction == 'past').practiceSentence.text, 'They cut paper yesterday.');
    final gloss = active.singleWhere((i) => i.card.form == 'run' && i.card.formFunction == 'past_participle');
    expect(gloss.card.translationDe, 'gelaufen');
    expect(old.any((i) => i.card.id == gloss.card.id), isTrue);
  });

  test('due state, local alias and reviews stay byte-identical while all projections exclude retirement', () async {
    final old = await before.practiceItems((await before.allCardIds()).toList());
    final item = old.singleWhere((i) => i.card.translationDe == 'kürzen');
    final id = item.card.id;
    final userFile = File('${dir.path}/synthetic-user.sqlite');
    var db = UserDatabase.file(userFile);
    var user = DriftUserRepository(db, lang: 'en');
    await user.ensureCards([id], now: now.subtract(const Duration(days: 20)), origin: CardOrigin.deck);
    final pass = ReviewPass(id: 'retirement-review', item: item, sentence: item.practiceSentence,
      state: (await user.cardStates([id]))[id]!, mode: ReviewMode.mixed, startedAt: now.subtract(const Duration(days: 19)));
    pass.submit('cut', now.subtract(const Duration(days: 19)));
    await user.recordReview(pass.complete(now: now.subtract(const Duration(days: 19)), appVersion: 'test', deviceId: await user.deviceId())!);
    final local = storyCandidate(surface: 'cut', sense: item.card.senseId!);
    await user.addStoryWord(local, now: now.subtract(const Duration(days: 8)));
    final localId = local.identity.localId;
    expect((await user.localPracticeItems()).single.card.id, localId);
    final stateRows = [for (final r in await db.customSelect('SELECT * FROM user_cards ORDER BY card_id').get()) r.data];
    final reviewRows = [for (final r in await db.customSelect('SELECT * FROM review_log ORDER BY id').get()) r.data];
    await user.close();
    final bytes = userFile.readAsBytesSync();
    db = UserDatabase.file(userFile); user = DriftUserRepository(db, lang: 'en');
    addTearDown(() => user.close());
    final catalog = await PracticeCatalog.load(after);
    final r = await PracticeItemResolver.load(user, after, catalog: catalog);
    expect(r.states[id]!.isDue(now), isTrue);
    expect(r.knownIds, isNot(contains(id))); expect(r.knownIds, isNot(contains(localId)));
    expect(r.notices.any((n) => n.contains(id) && n.contains('erhalten')), isTrue);
    expect(r.projectExisting([id,localId]), isEmpty); // restored/repeat ID projection
    expect(r.eligiblePrimaries([id,localId]), isEmpty);
    await expectLater(r.practiceItems([id]), throwsA(anything));
    await expectLater(r.practiceItems([localId]), throwsA(anything));
    for (final kind in [DeckSessionKind.learn, DeckSessionKind.revue]) {
      expect(buildDeckQueue(deckCardIds: [id, localId], cards: r.cards,
        states: r.states, kind: kind, now: now, targetsResolved: true), isEmpty);
    }
    expect(buildMixedQueue(activeDeckCardIds: [id, localId], cards: r.cards,
      states: r.states, now: now, targetsResolved: true), isEmpty);
    final ids = await r.activePrimaryIds();
    expect(buildMixedQueue(activeDeckCardIds: ids, cards: r.cards, states: r.states, now: now, size: 50, targetsResolved: true).map((e) => e.cardId), isNot(contains(id)));
    for (final deck in await after.decks()) {
      final selected = await r.deckPracticeIds(deck.id);
      for (final kind in [DeckSessionKind.learn, DeckSessionKind.revue]) {
        final queue = buildDeckQueue(deckCardIds: selected, cards: r.cards, states: r.states, kind: kind, now: now, size: 50, targetsResolved: true);
        expect(queue.map((e) => e.cardId), isNot(contains(id)));
        expect(queue.map((e) => e.cardId), isNot(contains(localId)));
      }
    }
    expect(deriveVocabBreakdown(activeDeckCardIds: ids.toSet(), cards: r.states, knownCardIds: r.knownIds, contentCards: r.cards, now: now, targetsResolved: true).due, 0);
    expect((await r.historicalSentence(id, item.practiceSentence.sentenceId))!.text, item.practiceSentence.text);
    expect(await user.reviewsFor(id), hasLength(1));
    expect(await user.activityBetween(now.subtract(const Duration(days: 20)), now), hasLength(1));
    final story = (await after.storySummaries()).singleWhere((s) => s.title == 'Retirement fixture');
    final doc = await after.storyDocument(story.id);
    final sentence = doc.sentences.single;
    final token = sentence.tokens.singleWhere((t) => t.surface == 'cut');
    final candidate = await after.resolveStoryWord(story.id, sentence.id, token.index);
    expect(candidate.retired, isTrue);
    expect((await user.storyLearningStatus(candidate)).state, StoryAddState.retired);
    await expectLater(user.addStoryWord(candidate, now: now), throwsStateError);
    expect([for (final r in await db.customSelect('SELECT * FROM user_cards ORDER BY card_id').get()) r.data], stateRows);
    expect([for (final r in await db.customSelect('SELECT * FROM review_log ORDER BY id').get()) r.data], reviewRows);
    await user.close();
    expect(userFile.readAsBytesSync(), bytes);
  });

  test('stale Story reactivation rechecks content before any learner write', () async {
    final story = (await before.storySummaries()).singleWhere((s) => s.title == 'Retirement fixture');
    final s = (await before.storyDocument(story.id)).sentences.single;
    final old = await before.resolveStoryWord(story.id, s.id, s.tokens.singleWhere((t) => t.surface == 'cut').index);
    final db = UserDatabase.file(File('${dir.path}/reactivate-user.sqlite'));
    final user = DriftUserRepository(db, lang: 'en');
    addTearDown(user.close);
    await user.addStoryWord(old, now: now);
    await user.setCardFlags(old.card!.id, disabled: true);
    final rows = [for (final r in await db.customSelect('SELECT * FROM user_cards').get()) r.data];
    final container = ProviderContainer(overrides: [
      userRepositoryProvider.overrideWith((ref) async => user),
      contentRepositoryProvider.overrideWith((ref) async => after),
    ]);
    addTearDown(container.dispose);
    final service = container.read(storyLearningServiceProvider);
    try {
      expect((await service.reactivate(old)).state, StoryAddState.retired);
    } on StateError catch (e) {
      expect(e.message, contains('geändert'));
    }
    expect([for (final r in await db.customSelect('SELECT * FROM user_cards').get()) r.data], rows);
  });

  test('invalid historical groups and active references fail the real Dart opener', () {
    final raw = sqlite3.open(afterFile.path);
    final retired = raw.select('SELECT id,learning FROM cards WHERE removed_in IS NOT NULL').single;
    final id = retired['id'] as String;
    raw.execute("UPDATE cards SET replaced_by='other' WHERE id=?", [id]);
    expect(() => validateContentSchema(raw, lang: 'en'), throwsA(isA<ContentUnavailable>()));
    raw.execute('UPDATE cards SET replaced_by=NULL WHERE id=?', [id]);
    final other = raw.select('SELECT id,learning FROM cards WHERE removed_in IS NULL LIMIT 1').single;
    raw.execute('UPDATE cards SET learning=? WHERE id=?', [retired['learning'], other['id']]);
    expect(() => validateContentSchema(raw, lang: 'en'), throwsA(isA<ContentUnavailable>()));
    raw.execute('UPDATE cards SET learning=? WHERE id=?', [other['learning'], other['id']]);
    raw.execute('UPDATE card_sentences SET removed_in=NULL WHERE card_id=?', [id]);
    expect(() => validateContentSchema(raw, lang: 'en'), throwsA(isA<ContentUnavailable>()));
    raw.close();
  });
  test('historical reader includes tombstoned token, sense and contextual dictionary gloss', () async {
    final raw = sqlite3.open(afterFile.path);
    final row = raw.select("SELECT t.id,t.lemma_id,t.sentence_id,cs.card_id FROM sentence_tokens t JOIN card_sentences cs ON cs.sentence_id=t.sentence_id WHERE t.removed_in IS NOT NULL AND t.surface='daily'").single;
    raw.execute("INSERT INTO senses(id,lang,lemma_id,sense_key,gloss_de,removed_in) VALUES ('historical-sense','en',?,'daily#history','fallback','old')", [row['lemma_id']]);
    raw.execute("INSERT INTO dictionary_forms(id,lang,form_norm,sense_id,gloss_de,rank,removed_in) VALUES ('historical-dictionary','en','daily','historical-sense','historische Kontextglosse',1,'old')");
    raw.execute("UPDATE sentence_tokens SET sense_id='historical-sense' WHERE id=?", [row['id']]);
    validateContentSchema(raw, lang: 'en');
    final historical = await after.historicalSentence(row['card_id'] as String, row['sentence_id'] as String);
    expect(historical!.tokens.singleWhere((t) => t.surface == 'daily').translation, 'historische Kontextglosse');
    raw.close();
  });

  test('existing installer accepts targeted pack and preserves good database on invalid successor', () async {
    final support = Directory('${dir.path}/installed-fixture');
    String manifest() => ContentManifest(lang: 'en', version: 'synthetic-targeted-v1',
      schemaVersion: 4, sha256: sha256Of(afterFile), sizeBytes: afterFile.lengthSync(),
      internalTestPack: true).toJson();
    final installer = installerFor(support, db: afterFile.readAsBytesSync(), manifest: manifest());
    final installed = await installer.install();
    final hash = sha256Of(installed.file);
    final repo = await installer.open();
    expect(await repo.allCardIds(), hasLength(10));
    await repo.close();
    final raw = sqlite3.open(afterFile.path);
    raw.execute("UPDATE cards SET replaced_by='invalid' WHERE removed_in IS NOT NULL");
    raw.close();
    final pinned = await installerFor(support, db: afterFile.readAsBytesSync(), manifest: manifest()).install();
    expect(pinned.file.path, installed.file.path);
    await expectLater(installerFor(Directory('${dir.path}/invalid-fresh'), db: afterFile.readAsBytesSync(), manifest: manifest()).install(), throwsA(isA<ContentUnavailable>()));
    expect(sha256Of(installed.file), hash);
  });

  test('another meaning of the same surface still resolves and adds its exact curated card', () async {
    final raw = sqlite3.open(afterFile.path);
    final target = raw.select("SELECT f.id form_id,f.card_id,cs.sentence_id FROM form_targets f JOIN card_sentences cs ON cs.card_id=f.card_id JOIN cards c ON c.id=f.card_id WHERE f.form='cut' AND f.function='base' AND cs.removed_in IS NOT NULL").single;
    final story = (await after.storySummaries()).singleWhere((s) => s.title == 'Retirement fixture');
    raw.execute("UPDATE sentence_tokens SET form_target_id=? WHERE sentence_id=? AND card_id=?", [target['form_id'],target['sentence_id'],target['card_id']]);
    raw.execute("INSERT INTO story_sentences(id,story_id,sentence_id,idx,paragraph_idx) VALUES ('other-meaning-link',?,?,1,0)", [story.id,target['sentence_id']]);
    validateContentSchema(raw, lang: 'en');
    raw.close();
    final sentence = (await after.storyDocument(story.id)).sentences.last;
    final token = sentence.tokens.singleWhere((t) => t.surface == 'cut');
    final candidate = await after.resolveStoryWord(story.id, sentence.id, token.index);
    expect(candidate.retired, isFalse);
    expect(candidate.card!.id, target['card_id']);
    final user = DriftUserRepository(UserDatabase.file(File('${dir.path}/other-meaning-user.sqlite')), lang: 'en');
    addTearDown(user.close);
    expect((await user.addStoryWord(candidate, now: now)).cardId, target['card_id']);
    expect(await user.localPracticeItems(), isEmpty);
  });

  test('a saved review resolves the old sentence after replacement', () async {
    final item = (await before.practiceItems((await before.allCardIds()).toList()))
      .singleWhere((i) => i.card.form == 'cut' && i.card.formFunction == 'past');
    final user = DriftUserRepository(UserDatabase.file(File('${dir.path}/replacement-user.sqlite')), lang: 'en');
    addTearDown(user.close);
    await user.ensureCards([item.card.id], now: now, origin: CardOrigin.deck);
    final pass = ReviewPass(id: 'old-sentence-review', item: item, sentence: item.practiceSentence,
      state: (await user.cardStates([item.card.id]))[item.card.id]!, mode: ReviewMode.deck, startedAt: now);
    pass.submit(item.card.form, now);
    await user.recordReview(pass.complete(now: now, appVersion: 'test', deviceId: await user.deviceId())!);
    final review = (await user.reviewsFor(item.card.id)).single;
    final resolver = await PracticeItemResolver.load(user, after);
    expect((await resolver.historicalSentence(review.cardId, review.sentenceId))!.text, item.practiceSentence.text);
    expect((await resolver.practiceItems([item.card.id])).single.practiceSentence.sentenceId, isNot(review.sentenceId));
  });

  test('read-only production: 402 memberships, 530 historical links and pre-existing provenance gaps', () async {
    final file = File('assets/content/en/content.sqlite');
    final hash = sha256Of(file);
    final raw = sqlite3.open(file.path, mode: OpenMode.readOnly);
    final repo = DriftContentRepository(ContentDatabase.open(file, lang: 'en'));
    try {
      final expected = raw.select('SELECT * FROM deck_practice_targets WHERE removed_in IS NULL');
      expect(expected, hasLength(402));
      var count = 0;
      for (final deck in await repo.decks()) {
        final targets = (await repo.deckPracticeTargets(deck.id)).where((t) => t.isForm).toList();
        final members = expected.where((m) => m['deck_id'] == deck.id).toList();
        expect(targets.map((t) => t.formTarget!.id).toSet(), members.map((m) => m['form_target_id']).toSet());
        count += targets.length;
      }
      expect(count, 402);
      final tokenCounts = {for (final r in raw.select('SELECT sentence_id, count(*) n FROM sentence_tokens GROUP BY sentence_id')) r['sentence_id']: r['n']};
      final links = raw.select('SELECT cs.card_id,cs.sentence_id,s.text FROM card_sentences cs JOIN sentences s ON s.id=cs.sentence_id WHERE cs.removed_in IS NOT NULL');
      expect(links, hasLength(530));
      for (final link in links) {
        final h = await repo.historicalSentence(link['card_id'] as String, link['sentence_id'] as String);
        expect(h, isNotNull);
        expect(h!.text, link['text']);
        expect(h.tokens.length, tokenCounts[link['sentence_id']]);
      }
      final sentenceIds = raw.select('SELECT id FROM sentences').map((r) => r['id']).toSet();
      var gaps = 0;
      for (final row in raw.select("SELECT cs.card_id,s.qa_report FROM sentences s JOIN card_sentences cs ON cs.sentence_id=s.id WHERE s.qa_report LIKE '%historical_source_sentence_id%'")) {
        final oldId = (jsonDecode(row['qa_report'] as String) as Map)['historical_source_sentence_id'];
        if (oldId is String && !sentenceIds.contains(oldId)) {
          gaps++;
          expect(await repo.historicalSentence(row['card_id'] as String, oldId), isNull);
        }
      }
      expect(gaps, 137);
      // Explicitly report existing gaps, not a claim that all past releases exist.
      // ignore: avoid_print
      print('READ-ONLY: 402 form memberships; 530 historical readers OK; 137 pre-existing provenance gaps');
    } finally {
      await repo.close(); raw.close();
    }
    expect(sha256Of(file), hash);
  });

}
