// The Paket A data path end to end, without UI: content from the read-only
// fixture pack, passes in the domain, bookings in user.db, restart, counters.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/data/content/drift_content_repository.dart';
import 'package:sprachapp/data/user/drift_user_repository.dart';
import 'package:sprachapp/data/user/user_database.dart';
import 'package:sprachapp/domain/answer_check.dart';
import 'package:sprachapp/domain/review_pass.dart';
import 'package:sprachapp/domain/srs_state.dart';

import 'support.dart';

void main() {
  late Directory tmp;
  late Directory support;
  late DriftContentRepository content;
  late DriftUserRepository user;

  DriftUserRepository openUser() => DriftUserRepository(
    UserDatabase.file(File('${support.path}/user.db')),
    lang: 'en',
  );

  setUp(() async {
    tmp = Directory.systemTemp.createTempSync('review_flow_');
    final work = Directory('${tmp.path}/work')..createSync();
    support = Directory('${tmp.path}/support')..createSync();
    content = await fixtureInstaller(work, support).open();
    user = openUser();
  });
  tearDown(() async {
    await content.close();
    await user.close();
    tmp.deleteSync(recursive: true);
  });

  test(
    'a learn session books each first pass once and survives a restart',
    () async {
      final start = DateTime(2026, 10, 3, 20);
      final deckIds = await content.deckCardIds('deck-allg');
      final queue = buildDeckQueue(
        deckCardIds: deckIds,
        cards: {for (final c in await content.selectionCards(deckIds)) c.id: c},
        states: await user.cardStates(deckIds),
        kind: DeckSessionKind.learn,
        now: start,
        size: 3,
      );
      expect(queue.map((e) => e.cardId), ['card-went', 'card-about']);
      final items = {
        for (final i in await content.practiceItems([
          for (final e in queue) e.cardId,
          'card-a', // Introduced in a separate short session below.
        ]))
          i.card.id: i,
      };
      await user.ensureCards(items.keys, now: start, origin: CardOrigin.deck);
      final device = await user.deviceId();
      final states = await user.cardStates(items.keys);
      final counts = await user.reviewCounts(items.keys);

      ReviewPass passFor(String id, {bool logged = true}) => ReviewPass(
        id: randomUuidV4(),
        item: items[id]!,
        sentence: items[id]!.sentenceForPass(counts[id] ?? 0),
        state: states[id],
        mode: DeckSessionKind.learn.mode,
        startedAt: start,
        logged: logged,
      );
      Future<bool> book(ReviewPass p) async {
        final r = p.complete(now: start, appVersion: 'test', deviceId: device);
        return r != null && await user.recordReview(r);
      }

      // went: synonym from the pack ("walked"), then the form → box 1, repeat.
      final went = passFor('card-went');
      expect(went.submit('walked', start)!.verdict, AnswerVerdict.alternative);
      went.submit('went', start);
      expect(await book(went), isTrue);
      expect(await book(went), isFalse); // second completion: nothing
      var session = withRepeat(queue, 0);

      // about: typo, then exact → clean first contact, box 3, no repeat.
      final about = passFor('card-about');
      expect(about.submit('abuot', start)!.verdict, AnswerVerdict.almost);
      about.submit('about', start);
      expect(about.needsRepeat, isFalse);
      expect(await book(about), isTrue);

      // A separate session can introduce a: the first session is deliberately
      // short, since two function words would refill it without diversity.
      final aQueue = buildDeckQueue(
        deckCardIds: ['card-a'],
        cards: {'card-a': items['card-a']!.card},
        states: await user.allCardStates(),
        kind: DeckSessionKind.learn,
        now: start,
      );
      expect(aQueue.map((e) => e.cardId), ['card-a']);
      // a: exact → box 3.
      final a = passFor('card-a');
      a.submit('a', start);
      expect(await book(a), isTrue);

      // in-session repeat of went: practised, never booked.
      expect(session.map((e) => e.repeat ? '${e.cardId}*' : e.cardId), [
        'card-went',
        'card-about',
        'card-went*',
      ]);
      final repeat = passFor('card-went', logged: false);
      repeat.submit('went', start);
      expect(await book(repeat), isFalse);

      // restart: everything is read back from the files
      await user.close();
      user = openUser();
      final after = await user.cardStates(deckIds);
      expect(
        {for (final e in after.entries) e.key: e.value.box},
        {'card-went': 1, 'card-about': 3, 'card-a': 3},
      );
      expect(after['card-went']!.dueAt, DateTime(2026, 10, 4));
      expect(after['card-about']!.dueAt, DateTime(2026, 10, 17));
      final [wentLog] = await user.reviewsFor('card-went');
      expect(
        [
          wentLog.hintUsed,
          wentLog.errorCount,
          wentLog.revealed,
          wentLog.firstAttemptCorrect,
        ],
        [true, 0, false, false],
      );
      expect(wentLog.sentenceId, 's-went-1');
      final [aboutLog] = await user.reviewsFor('card-about');
      expect(
        [aboutLog.firstAttemptCorrect, aboutLog.errorCount, aboutLog.boxAfter],
        [false, 0, 3],
      );
      expect(await user.reviewCounts(deckIds), {
        'card-went': 1,
        'card-about': 1,
        'card-a': 1,
      });

      // counters from state and due dates only
      final active = await user.activeDeckIds(['deck-allg']);
      expect(active, {'deck-allg'});
      final breakdown = deriveVocabBreakdown(
        activeDeckCardIds: deckIds.toSet(),
        cards: await user.allCardStates(),
        knownCardIds: await content.allCardIds(),
        now: DateTime(2026, 10, 4, 8),
      );
      expect(
        [
          breakdown.unseen,
          breakdown.due,
          breakdown.building,
          breakdown.mastered,
        ],
        [1, 1, 2, 0],
      ); // goes unseen, went due, about + a building
      expect(breakdown.total, 4);

      // next day: went is due first; the next pass uses the second sentence
      final next = buildDeckQueue(
        deckCardIds: deckIds,
        cards: {for (final c in await content.selectionCards(deckIds)) c.id: c},
        states: after,
        kind: DeckSessionKind.learn,
        now: DateTime(2026, 10, 4, 8),
      );
      expect(next.map((e) => e.cardId), ['card-went', 'card-goes']);
      expect(items['card-went']!.sentenceForPass(1).sentenceId, 's-went-1');

      // A different asset version replaces only the closed content database.
      // Real learner rows and append-only reviews survive the update byte-for-byte.
      await user.close();
      final userFile = File('${support.path}/user.db');
      final savedUserBytes = userFile.readAsBytesSync();
      await content.close();
      final updateDir = Directory('${tmp.path}/update')..createSync();
      final updated = buildFixturePack(
        updateDir,
        tweak: (db) {
          db.execute("UPDATE content_releases SET version='mini-v2'");
          db.execute(
            "UPDATE cards SET translation_de='ging (aktualisiert)' WHERE id='card-went'",
          );
        },
      ).readAsBytesSync();
      content = await installerFor(
        support,
        db: updated,
        manifest: manifestFor(updated, version: 'mini-v2'),
      ).open();
      expect(content.info.version, 'mini-v2');
      expect(userFile.readAsBytesSync(), savedUserBytes);
      user = openUser();
      expect((await user.cardStates(deckIds))['card-went']!.box, 1);
      expect(await user.reviewCounts(deckIds), {
        'card-went': 1,
        'card-about': 1,
        'card-a': 1,
      });
      expect(
        (await user.reviewsFor('card-went')).single.sentenceId,
        's-went-1',
      );
    },
  );
}
