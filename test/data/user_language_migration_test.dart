import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sprachapp/data/user/user_database.dart';
import 'package:sprachapp/data/user/drift_user_repository.dart';
import 'package:sprachapp/domain/preferences.dart';
import 'package:sprachapp/domain/srs_state.dart';

import '../fixtures/story_learning.dart';
import '../fixtures/form_learning.dart';

Map<String, List<Map<String, Object?>>> snapshot(Database db) => {
  for (final t in db.select(
    "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
  ))
    t['name'] as String: [
      for (final row in db.select(
        'SELECT * FROM "${t['name']}" ORDER BY rowid',
      ))
        Map<String, Object?>.from(row),
    ],
};
void main() {
  test('v5 to v6 preserves every actual table, backs up, keeps triggers and scopes preferences', () async {
    final dir = Directory.systemTemp.createTempSync('user-v6-test-');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/user.sqlite');
    var db = UserDatabase.file(file);
    var en = DriftUserRepository(db, lang: 'en', ownsDatabase: false);
    final now = DateTime.utc(2026, 10, 16);
    await en.deviceId();
    await en.ensureCards(['en-card'], now: now, origin: CardOrigin.deck);
    await en.setCardFlags(
      'en-card',
      favorite: true,
      disabled: true,
      note: 'Unveränderte Notiz',
      inPlaylist: true,
    );
    await en.setDeckActive('en-deck', false, now: now);
    await en.addStoryWord(storyCandidate(), now: now);
    await en.recordReview(
      ReviewRecord(
        id: 'review',
        cardId: 'en-card',
        createdAt: now,
        mode: ReviewMode.deck,
        sentenceId: 'historical-sentence',
        firstAttemptCorrect: true,
        errorCount: 0,
        revealed: false,
        hintUsed: false,
        boxBefore: 0,
        boxAfter: 3,
        dueAtAfter: now.add(const Duration(days: 7)),
        responseMs: 10,
        appVersion: 'synthetic',
        deviceId: 'synthetic',
      ),
    );
    await en.saveSubmission(
      LocalSubmission(
        id: 'report',
        createdAt: now,
        text: 'Synthetischer Bericht',
        category: 'Grammatik',
        cardId: 'en-card',
        sentenceId: 'historical-sentence',
        packVersion: 'synthetic',
      ),
    );
    final content = formContent(dir);
    final forms = await content.selectionCards(await content.allCardIds());
    await en.addStoryWord(
      formCandidate(
        forms.firstWhere((c) => c.formFunction == 'past'),
        local: true,
      ),
      now: now,
    );
    await content.close();
    await db.close();
    final raw = sqlite3.open(file.path);
    raw.execute('DROP TABLE language_learning_preferences');
    raw.execute(
      'UPDATE settings SET daily_goal=27, include_diacritics=0, show_grammar=1, auto_next=1',
    );
    // Reconstruct the real schema-5 constraints; all row values remain intact.
    for (final table in ['user_cards', 'form_identity_bindings']) {
      final sql =
          raw.select(
                "SELECT sql FROM sqlite_master WHERE type='table' AND name=?",
                [table],
              ).single['sql']
              as String;
      final old = sql
          .replaceFirst('CREATE TABLE "$table"', 'CREATE TABLE "old_$table"')
          .replaceAll(
            'length(trim(form_function)) > 0',
            "form_function IN ('base','past','past_participle')",
          )
          .replaceAll(
            'length(trim(function)) > 0',
            "function IN ('base','past','past_participle')",
          );
      raw.execute(old);
      raw.execute('INSERT INTO old_$table SELECT * FROM $table');
      raw.execute('DROP TABLE $table');
      raw.execute('ALTER TABLE old_$table RENAME TO $table');
    }
    raw.execute('PRAGMA user_version=5');
    final before = snapshot(raw);
    raw.close();
    db = UserDatabase.file(file);
    en = DriftUserRepository(db, lang: 'en', ownsDatabase: false);
    final other = DriftUserRepository(db, lang: 'qaa', ownsDatabase: false);
    final preferences = await en.preferences();
    expect(preferences.dailyGoal, 27);
    expect(preferences.includeDiacritics, isFalse);
    expect(preferences.showGrammar, isTrue);
    expect((await other.preferences()).dailyGoal, 10);
    expect((await other.preferences()).autoNext, isTrue);
    await en.close();
    expect(
      await other.deviceId(),
      isNotEmpty,
    ); // facade never owns shared physical DB
    final read = sqlite3.open(file.path, mode: OpenMode.readOnly);
    final after = snapshot(read);
    read.close();
    for (final e in before.entries) {
      expect(after[e.key], e.value, reason: e.key);
    }
    expect(after.keys.toSet().difference(before.keys.toSet()), {
      'language_learning_preferences',
    });
    final backup = sqlite3.open(
      '${file.path}.pre-v6.sqlite',
      mode: OpenMode.readOnly,
    );
    expect(snapshot(backup), before);
    expect(backup.select('PRAGMA user_version').single.values.first, 5);
    backup.close();
    await expectLater(
      db.customStatement("UPDATE review_log SET app_version='changed'"),
      throwsA(anything),
    );
    await expectLater(
      db.customStatement('DELETE FROM card_contexts'),
      throwsA(anything),
    );
    await other.savePreferences(const PracticePreferences(dailyGoal: 19));
    expect((await en.preferences()).dailyGoal, 27);
    expect((await other.preferences()).dailyGoal, 19);
    await other.ensureCards(['qaa-card'], now: now, origin: CardOrigin.deck);
    for (final action in [
      () => en.ensureCards(['qaa-card'], now: now, origin: CardOrigin.deck),
      () => en.setCardFlags('qaa-card', favorite: true),
      () => en.reviewsFor('qaa-card'),
      () => en.cardStates(['qaa-card']),
      () => en.reviewCounts(['qaa-card']),
    ]) {
      await expectLater(action(), throwsStateError);
    }
    expect((await en.allCardStates()).containsKey('qaa-card'), isFalse);
    expect(await other.explicitStoryAdditions(), isEmpty);
    await db.close();
    final broken = File('${dir.path}/synthetic-failed-migration.sqlite');
    await File('${file.path}.pre-v6.sqlite').copy(broken.path);
    final invalid = sqlite3.open(broken.path);
    invalid.execute(
      "INSERT INTO form_identity_bindings VALUES ('invalid-binding','en','cut','anchor','past','missing-card')",
    );
    final invalidBefore = snapshot(invalid);
    invalid.close();
    final failed = UserDatabase.file(broken);
    await expectLater(
      failed.customSelect('SELECT * FROM settings').get(),
      throwsStateError,
    );
    await failed.close();
    final preserved = sqlite3.open(broken.path);
    expect(preserved.select('PRAGMA user_version').single.values.first, 5);
    expect(snapshot(preserved), invalidBefore);
    preserved.close();
  });
}
