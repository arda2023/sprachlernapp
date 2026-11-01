import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:sprachapp/data/user/drift_user_repository.dart';
import 'package:sprachapp/data/learning/practice_item_resolver.dart';
import 'package:sprachapp/data/user/generated_vocabulary_store.dart';
import 'package:sprachapp/data/user/user_database.dart';
import 'package:sprachapp/domain/generated_vocabulary.dart';
import 'package:sprachapp/domain/generated_vocabulary_repository.dart';

const firstRequest = '12345678-1234-4234-8234-123456789abc';
const nextRequest = '87654321-1234-4234-8234-123456789abc';
final now = DateTime.utc(2026, 10, 31, 12);

Map<String, Object?> word(String lang) {
  final (form, sentence, start) = switch (lang) {
    'es' => ('billete', 'Compra un billete hoy.', 10),
    'it' => ('biglietto', 'Compra un biglietto oggi.', 10),
    'nb' => ('billett', 'Kjøp en billett nå.', 8),
    'pt-BR' => ('bilhete', 'Compre um bilhete hoje.', 10),
    _ => ('ticket', 'Buy a ticket today.', 6),
  };
  return {
    'form': form,
    'lemma': form,
    'pos': 'NOUN',
    'gloss_de': 'Fahrkarte',
    'definition_de': 'Ein Nachweis für eine bezahlte Fahrt.',
    'form_detail': 'Singular',
    'sentence': sentence,
    'translation_de': 'Kaufe heute eine Fahrkarte.',
    'start': start,
  };
}

GeneratedVocabularyResponse response(
  String lang, {
  String requestId = firstRequest,
  Map<String, Object?> changes = const {},
  bool twoItems = false,
}) {
  final request = GeneratedVocabularyRequest(
    requestId: requestId,
    lang: lang,
    prompt: 'Reise',
    count: 5,
  );
  return GeneratedVocabularyResponse.fromJson({
    'contract': 1,
    'request_id': requestId,
    'lang': lang,
    'items': [
      {...word(lang), ...changes},
      if (twoItems)
        {
          ...word(lang),
          'form': 'hotel',
          'lemma': 'hotel',
          'gloss_de': 'Unterkunft',
          'sentence': 'Visit the hotel today.',
          'start': 10,
        },
    ],
  }, request: request);
}

void main() {
  for (final lang in GeneratedVocabularyRequest.languages) {
    test(
      '$lang saves selected words as fixed practice without story membership',
      () async {
        final db = UserDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        final store = GeneratedVocabularyStore(db, lang: lang);
        final result = await store.save(
          response(lang, twoItems: true),
          selected: {0},
          now: now,
          verify: () {},
        );
        expect(result.addedIds, hasLength(1));
        expect(result.existingIds, isEmpty);
        expect(result.blockedForms, isEmpty);
        expect(result.savedCount, 1);
        final id = result.addedIds.single;
        final row = await db.select(db.userCards).getSingle();
        expect(row.cardId, id);
        expect(row.lang, lang);
        expect(row.localOnly, isTrue);
        expect(row.origin, 'deck');
        expect(row.box, 0);
        expect(row.dueAt, isNull);
        expect(await store.additions(), {id: now.toLocal()});
        final repo = DriftUserRepository(db, lang: lang, ownsDatabase: false);
        final deckId = generatedVocabularyDeckId(lang);
        final resolver = await PracticeItemResolver.load(repo, null);
        expect(resolver.generatedDeckId, deckId);
        expect(resolver.generatedAdditions, {id: now.toLocal()});
        expect(resolver.generatedPracticeIds, [id]);
        expect(await resolver.deckPracticeIds(deckId), [id]);
        expect(await resolver.activePrimaryIds(), [id]);
        final sources = await resolver.newWordSources();
        expect(sources.order, [deckId]);
        expect(sources.active.single.id, deckId);
        expect(sources.active.single.cardIds, [id]);
        expect(resolver.storyCollectionIds, isEmpty);
        expect(resolver.storyPracticeIds, isEmpty);
        expect(
          (await resolver.practiceItems([id])).single.card.form,
          word(lang)['form'],
        );
        final practice = (await repo.localPracticeItems()).single;
        expect(practice.card.id, id);
        expect(practice.card.form, word(lang)['form']);
        final sentence = practice.sentences.single;
        expect(sentence.text, word(lang)['sentence']);
        expect(sentence.gapText, word(lang)['form']);
        expect(sentence.translationDe, word(lang)['translation_de']);
        expect(sentence.tokens, isNotEmpty);
        final context = await db.select(db.cardContexts).getSingle();
        expect(context.sourceRef, generatedVocabularyDeckId(lang));
        expect(context.sentenceRef, firstRequest);
        expect(context.provenance, 'generated_haiku_v1');
        expect(await db.select(db.storyLearningAdditions).get(), isEmpty);
        expect(await db.select(db.storyWordSources).get(), isEmpty);
        expect(await db.select(db.reviewLog).get(), isEmpty);
        expect(
          await GeneratedVocabularyStore(
            db,
            lang: lang == 'en' ? 'es' : 'en',
          ).additions(),
          isEmpty,
        );
      },
    );
  }

  test('repeat saves across request and definition changes preserve all learned state', () async {
    final db = UserDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final store = GeneratedVocabularyStore(db, lang: 'en');
    final first = await store.save(
      response('en'),
      selected: {0},
      now: now,
      verify: () {},
    );
    final id = first.addedIds.single;
    final due = now.add(const Duration(days: 7));
    await (db.update(db.userCards)..where((t) => t.cardId.equals(id))).write(
      UserCardsCompanion(
        box: const Value(3),
        dueAt: Value(due),
        favorite: const Value(true),
        inPlaylist: const Value(true),
        note: const Value('Meine Notiz'),
      ),
    );
    final before = await db.select(db.userCards).getSingle();
    final contextBefore = await db.select(db.cardContexts).getSingle();
    await db
        .into(db.reviewLog)
        .insert(
          ReviewLogCompanion.insert(
            id: 'review',
            cardId: id,
            createdAt: now,
            mode: 'deck',
            sentenceId: contextBefore.id,
            firstAttemptCorrect: true,
            errorCount: 0,
            revealed: false,
            boxBefore: 0,
            boxAfter: 3,
            dueAtAfter: due,
            appVersion: 'test',
            deviceId: 'device',
          ),
        );
    final reviewBefore = await db.select(db.reviewLog).getSingle();
    final membershipBefore = await db
        .select(db.generatedVocabularyAdditions)
        .getSingle();
    for (final next in [
      response('en'),
      response('en', requestId: nextRequest),
      response(
        'en',
        requestId: nextRequest,
        changes: {
          'definition_de': 'Ein veränderter Bedeutungstext.',
          'sentence': 'Please buy a ticket now.',
          'start': 13,
        },
      ),
    ]) {
      final result = await store.save(
        next,
        selected: {0},
        now: now.add(const Duration(days: 2)),
        verify: () {},
      );
      expect(result.addedIds, isEmpty);
      expect(result.existingIds, [id]);
      expect(await db.select(db.userCards).getSingle(), before);
      expect(await db.select(db.cardContexts).getSingle(), contextBefore);
      expect(await db.select(db.reviewLog).getSingle(), reviewBefore);
      expect(
        await db.select(db.generatedVocabularyAdditions).getSingle(),
        membershipBefore,
      );
    }
  });

  test(
    'deactivated private deck stays inactive after new and repeated saves',
    () async {
      final db = UserDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final store = GeneratedVocabularyStore(db, lang: 'en');
      final repo = DriftUserRepository(
        db,
        lang: 'en',
        ownsDatabase: false,
        contentIds: (_) async => <String>{},
      );
      final deckId = generatedVocabularyDeckId('en');
      final first = await store.save(
        response('en'),
        selected: {0},
        now: now,
        verify: () {},
      );
      expect(await repo.activeDeckIds([deckId]), [deckId]);
      await repo.setDeckActive(deckId, false, now: now);
      await store.save(response('en'), selected: {0}, now: now, verify: () {});
      await store.save(
        response('en', twoItems: true),
        selected: {1},
        now: now,
        verify: () {},
      );
      expect(await repo.activeDeckIds([deckId]), isEmpty);
      final resolver = await PracticeItemResolver.load(repo, null);
      expect(resolver.generatedPracticeIds, hasLength(2));
      expect(
        await resolver.deckPracticeIds(deckId),
        contains(first.addedIds.single),
      );
      expect((await resolver.newWordSources()).order, [deckId]);
      expect((await resolver.newWordSources()).active, isEmpty);
      expect(await resolver.activePrimaryIds(), isEmpty);
      expect(resolver.storyCollectionIds, isEmpty);
    },
  );

  for (final retired in [false, true]) {
    test(
      '${retired ? 'retired' : 'disabled'} same-form card prevents generated bypass',
      () async {
        final db = UserDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        await db
            .into(db.userCards)
            .insert(
              UserCardsCompanion.insert(
                cardId: 'blocked-pack-card',
                lang: 'en',
                box: 0,
                createdAt: now,
                origin: 'deck',
                updatedAt: now,
                form: const Value('TICKET'),
                formNorm: const Value('ticket'),
                disabled: Value(!retired),
                retired: Value(retired),
              ),
            );
        final store = GeneratedVocabularyStore(db, lang: 'en');
        final result = await store.save(
          response(
            'en',
            changes: {'definition_de': 'Ein neuer Bedeutungstext.'},
          ),
          selected: {0},
          now: now,
          verify: () {},
        );
        expect(result.blockedForms, ['ticket']);
        expect(result.savedCount, 0);
        expect(await store.additions(), isEmpty);
        expect(await db.select(db.userCards).get(), hasLength(1));
        expect(await db.select(db.cardContexts).get(), isEmpty);
      },
    );
  }

  test(
    'changed-context verification rolls back the complete selected batch',
    () async {
      final db = UserDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      var calls = 0;
      await expectLater(
        GeneratedVocabularyStore(db, lang: 'en').save(
          response('en', twoItems: true),
          selected: {0, 1},
          now: now,
          verify: () {
            if (++calls == 2) throw StateError('Account changed');
          },
        ),
        throwsStateError,
      );
      expect(calls, 2);
      expect(await db.select(db.userCards).get(), isEmpty);
      expect(await db.select(db.cardContexts).get(), isEmpty);
      expect(await db.select(db.generatedVocabularyAdditions).get(), isEmpty);
    },
  );

  test('cross-language or invalid selection writes nothing', () async {
    final db = UserDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final store = GeneratedVocabularyStore(db, lang: 'en');
    await expectLater(
      store.save(response('es'), selected: {0}, now: now, verify: () {}),
      throwsFormatException,
    );
    for (final selection in [
      <int>{},
      {-1},
      {1},
    ]) {
      await expectLater(
        store.save(
          response('en'),
          selected: selection,
          now: now,
          verify: () {},
        ),
        throwsFormatException,
      );
    }
    expect(await db.select(db.userCards).get(), isEmpty);
  });

  test(
    'v7 to v8 creates membership table and preserves the preexisting card',
    () async {
      final dir = Directory.systemTemp.createTempSync(
        'generated-v8-migration-',
      );
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/user.db');
      final original = UserDatabase(NativeDatabase(file));
      await original
          .into(original.userCards)
          .insert(
            UserCardsCompanion.insert(
              cardId: 'existing',
              lang: 'en',
              box: 3,
              createdAt: now,
              origin: 'deck',
              updatedAt: now,
              dueAt: Value(now.add(const Duration(days: 7))),
              favorite: const Value(true),
              note: const Value('Existing note'),
              inPlaylist: const Value(true),
            ),
          );
      await original.close();
      final raw = sqlite.sqlite3.open(file.path);
      raw.execute('DROP TABLE generated_vocabulary_additions');
      raw.execute('PRAGMA user_version=7');
      final before = Map<String, Object?>.from(
        raw.select('SELECT * FROM user_cards').single,
      );
      raw.close();
      final migrated = UserDatabase(NativeDatabase(file));
      addTearDown(migrated.close);
      expect(
        await migrated.select(migrated.generatedVocabularyAdditions).get(),
        isEmpty,
      );
      expect(
        (await migrated.customSelect('PRAGMA user_version').getSingle())
            .read<int>('user_version'),
        8,
      );
      expect(
        (await migrated.customSelect('SELECT * FROM user_cards').getSingle())
            .data,
        before,
      );
      final store = GeneratedVocabularyStore(migrated, lang: 'en');
      expect(
        (await store.save(
          response('en'),
          selected: {0},
          now: now,
          verify: () {},
        )).addedIds,
        hasLength(1),
      );
      expect(await migrated.select(migrated.userCards).get(), hasLength(2));
    },
  );
}
