import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sprachapp/data/user/user_database.dart';
import 'package:sprachapp/data/user/drift_user_repository.dart';
import 'package:sprachapp/domain/srs_state.dart';

import '../fixtures/story_learning.dart';

void main() {
  for (final version in [2, 3]) {
    test(
      'v$version to v4 preserves all prior column values and append-only triggers',
      () async {
        final dir = Directory.systemTemp.createTempSync('story-migrate-');
        addTearDown(() => dir.deleteSync(recursive: true));
        final file = File('${dir.path}/user.db');
        var repo = DriftUserRepository(UserDatabase.file(file), lang: 'en');
        final now = DateTime(2026, 10, 4);
        await repo.deviceId();
        await repo.ensureCards(['existing'], now: now, origin: CardOrigin.deck);
        await repo.setCardFlags(
          'existing',
          favorite: true,
          disabled: true,
          note: 'unchanged',
          inPlaylist: true,
        );
        await repo.setDeckActive('deck', false, now: now);
        await repo.close();
        final raw = sqlite3.open(file.path);
        for (final table in [
          'story_word_sources',
          'learning_identity_bindings',
          'story_learning_additions',
          'card_contexts',
        ]) {
          raw.execute('DROP TABLE $table');
        }
        for (final col in [
          'form',
          'form_norm',
          'gloss_de',
          'lemma',
          'pos',
          'lemma_identity',
          'sense_identity',
          'sense_key',
          'primary_context_id',
        ]) {
          raw.execute('ALTER TABLE user_cards DROP COLUMN $col');
        }
        if (version == 2) {
          raw.execute('ALTER TABLE user_cards DROP COLUMN note');
          raw.execute('ALTER TABLE user_cards DROP COLUMN in_playlist');
          raw.execute('ALTER TABLE settings DROP COLUMN daily_goal');
        }
        raw.execute(
          "INSERT INTO review_log VALUES ('old-review','existing','2026-10-04T00:00:00.000Z','deck','old-sentence',1,0,0,0,0,3,'2026-10-05T00:00:00.000Z',500,'old','device')",
        );
        raw.execute('PRAGMA user_version=$version');
        final columns = <String, List<String>>{};
        final before = <String, List<Map<String, Object?>>>{};
        for (final table in [
          'user_cards',
          'settings',
          'deck_settings',
          'review_log',
          'local_submissions',
        ]) {
          columns[table] = raw
              .select('PRAGMA table_info($table)')
              .map((r) => r['name'] as String)
              .toList();
          before[table] = raw
              .select('SELECT * FROM $table')
              .map((r) => Map<String, Object?>.from(r))
              .toList();
        }
        raw.close();
        repo = DriftUserRepository(UserDatabase.file(file), lang: 'en');
        await repo.deviceId();
        await repo.addStoryWord(storyCandidate(), now: now);
        await repo.close();
        final migrated = sqlite3.open(file.path);
        addTearDown(migrated.close);
        expect(migrated.select('PRAGMA user_version').single.values.first, 4);
        for (final table in columns.keys) {
          final where = table == 'user_cards'
              ? " WHERE card_id='existing'"
              : '';
          expect(
            migrated
                .select('SELECT ${columns[table]!.join(',')} FROM $table$where')
                .map((r) => Map<String, Object?>.from(r))
                .toList(),
            before[table],
          );
        }
        expect(
          () => migrated.execute('DELETE FROM review_log'),
          throwsA(anything),
        );
        expect(
          () => migrated.execute(
            'UPDATE card_contexts SET text_value=\'changed\'',
          ),
          throwsA(anything),
        );
      },
    );
  }
}
