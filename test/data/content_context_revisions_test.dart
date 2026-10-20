import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sprachapp/data/content/content_database.dart';
import 'package:sprachapp/data/content/drift_content_repository.dart';
import 'package:sprachapp/data/content/context_revision_validation.dart';
import 'package:sprachapp/data/user/user_database.dart';
import 'package:sprachapp/data/user/drift_user_repository.dart';
import 'package:sprachapp/domain/review_pass.dart';
import 'package:sprachapp/domain/srs_state.dart';

void main() {
  late Directory dir;
  late DriftContentRepository before, after;
  setUp(() {
    dir = Directory.systemTemp.createTempSync('editor-context-test-');
    DriftContentRepository load(String name) {
      final file = File('${dir.path}/$name.sqlite');
      final db = sqlite3.open(file.path);
      db.execute(
        File('test/fixtures/editor_context_$name.sql').readAsStringSync(),
      );
      db.close();
      return DriftContentRepository(ContentDatabase.open(file, lang: 'en'));
    }

    before = load('before');
    after = load('after');
  });
  tearDown(() async {
    await before.close();
    await after.close();
    dir.deleteSync(recursive: true);
  });
  test(
    'new context and retirement preserve all old reader text, gaps and glosses',
    () async {
      final old = await before.practiceItems(
        (await before.allCardIds()).toList(),
      );
      final current = await after.practiceItems(
        (await after.allCardIds()).toList(),
      );
      expect(old, hasLength(11));
      expect(current, hasLength(10));
      for (final item in old) {
        final original = await before.historicalSentence(
          item.card.id,
          item.practiceSentence.sentenceId,
        );
        final saved = await after.historicalSentence(
          item.card.id,
          item.practiceSentence.sentenceId,
        );
        expect(saved!.text, original!.text);
        expect(saved.translationDe, original.translationDe);
        expect(saved.gapStart, original.gapStart);
        expect(saved.gapEnd, original.gapEnd);
        expect(
          saved.tokens
              .map((t) => [t.start, t.end, t.surface, t.translation])
              .toList(),
          original.tokens
              .map((t) => [t.start, t.end, t.surface, t.translation])
              .toList(),
        );
      }
      final changed = current.singleWhere(
        (i) => i.card.form == 'cut' && i.card.formFunction == 'base',
      );
      final original = old.singleWhere((i) => i.card.id == changed.card.id);
      expect(changed.practiceSentence.text, original.practiceSentence.text);
      expect(
        changed.practiceSentence.translationDe,
        'Sie schneiden das Papier.',
      );
      expect(
        changed.practiceSentence.sentenceId,
        isNot(original.practiceSentence.sentenceId),
      );
    },
  );
  test('two origin releases skip C and reach D; state, flags, reviews and old contexts survive restart', () async {
    final origins =
        (jsonDecode(
              File('test/fixtures/editor_story_origins.json')
                  .readAsStringSync(),
            ) as List)
            .map((s) => decodeStoryCandidate(s as Map<String, dynamic>))
            .toList();
    expect(origins[0].identity.key, origins[1].identity.key);
    expect(origins[0].sourceFingerprint, isNot(origins[1].sourceFingerprint));
    final corrections = await after.storyContextCorrections();
    expect(corrections, hasLength(3));
    final now = DateTime.utc(2026, 10, 16);
    for (var n = 0; n < origins.length; n++) {
      final file = File('${dir.path}/synthetic-user-$n.sqlite');
      var db = UserDatabase.file(file);
      var user = DriftUserRepository(db, lang: 'en');
      try {
        final id = (await user.addStoryWord(origins[n], now: now)).cardId!;
        final item = (await user.localPracticeItems()).single;
        final historical = item.practiceSentence;
        final pass = ReviewPass(
          id: 'review-$n',
          item: item,
          sentence: historical,
          state: (await user.allCardStates())[id],
          mode: ReviewMode.mixed,
          startedAt: now,
        );
        pass.submit('yesterday', now);
        await user.recordReview(
          pass.complete(
            now: now,
            appVersion: 'test',
            deviceId: await user.deviceId(),
          )!,
        );
        await user.setCardFlags(
          id,
          favorite: true,
          inPlaylist: true,
          note: 'Synthetic note 😀',
        );
        final state = Map<String, Object?>.from(
          (await db.customSelect('SELECT * FROM user_cards').getSingle()).data,
        )..remove('primary_context_id');
        final reviews =
            (await db.customSelect('SELECT * FROM review_log').get())
                .map((r) => r.data)
                .toList();
        final contextRows =
            (await db.customSelect('SELECT * FROM card_contexts').get())
                .map((r) => r.data)
                .toList();
        await user.applyStoryContextCorrections(corrections);
        expect(
          (await user.localPracticeItems())
              .single
              .practiceSentence
              .translationDe,
          'Geprüfte Endübersetzung D.',
        );
        expect(
          Map<String, Object?>.from(
            (await db.customSelect('SELECT * FROM user_cards').getSingle())
                .data,
          )..remove('primary_context_id'),
          state,
        );
        expect(
          (await db.customSelect('SELECT * FROM review_log').get())
              .map((r) => r.data)
              .toList(),
          reviews,
        );
        final preserved =
            (await db.customSelect('SELECT * FROM card_contexts').get())
                .map((r) => r.data)
                .toList();
        for (final row in contextRows) {
          expect(preserved.singleWhere((r) => r['id'] == row['id']), row);
        }
        await user.close();
        db = UserDatabase.file(file);
        user = DriftUserRepository(db, lang: 'en');
        await user.applyStoryContextCorrections(corrections);
        expect(
          (await db.customSelect('SELECT * FROM card_contexts').get())
              .map((r) => r.data)
              .toList(),
          preserved,
        );
      } finally {
        await user.close();
      }
    }
  });
  test('reader rejects a modified immutable snapshot', () {
    final db = sqlite3.open('${dir.path}/after.sqlite');
    db.execute(
      "UPDATE sentence_tokens SET context_gloss_de='tampered' WHERE sentence_id IN (SELECT id FROM sentences WHERE revision_sha256 IS NOT NULL)",
    );
    db.close();
    expect(
      () => ContentDatabase.open(File('${dir.path}/after.sqlite'), lang: 'en'),
      throwsA(anything),
    );
  });
}
