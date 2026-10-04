import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/data/content/content_database.dart';
import 'package:sprachapp/data/content/drift_content_repository.dart';

import 'support.dart';

void main() {
  test('stored token index disambiguates repeated words and converts codepoint to UTF16 after emoji', () async {
    final dir = Directory.systemTemp.createTempSync('story-offsets-');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = buildFixturePack(
      dir,
      tweak: (db) {
        db.execute(
          "INSERT INTO stories(id,lang,slug,title) VALUES ('story','en','story','Repeated')",
        );
        db.execute(
          "INSERT INTO sentences(id,lang,text,translation_de,qa_report) VALUES ('s-story','en','😀 about about.','ungefähr ungefähr.', '{}')",
        );
        db.execute(
          "INSERT INTO story_sentences(id,story_id,idx,sentence_id,paragraph_idx) VALUES ('ss','story',0,'s-story',0)",
        );
        for (final i in [0, 1]) {
          db.execute(
            "INSERT INTO sentence_tokens(id,sentence_id,idx,start_pos,end_pos,surface,lemma_id,sense_id) VALUES (?, 's-story', ?, ?, ?, 'about','lem-about','sen-about')",
            ['st$i', i, 2 + i * 6, 7 + i * 6],
          );
        }
      },
    );
    final repo = DriftContentRepository(ContentDatabase.open(file, lang: 'en'));
    addTearDown(repo.close);
    final first = await repo.resolveStoryWord('story', 's-story', 0);
    final second = await repo.resolveStoryWord('story', 's-story', 1);
    expect(first.token.start, 3);
    expect(second.token.start, 9);
    expect(
      second.sentence.text.substring(second.token.start, second.token.end),
      'about',
    );
    expect(first.identity.key, second.identity.key);
    expect(first.sourceFingerprint, isNot(second.sourceFingerprint));
    expect(second.card!.id, 'card-about');
    await expectLater(
      repo.resolveStoryWord('story', 'not-part-of-story', 1),
      throwsStateError,
    );
  });
}
