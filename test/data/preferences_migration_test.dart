import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sprachapp/data/user/user_database.dart';
import 'package:sprachapp/data/user/drift_user_repository.dart';
import 'package:sprachapp/domain/preferences.dart';

void main() {
  test('v1 migration preserves reviews, flags, device and dates; settings and local reports survive restart', () async {
    final dir = Directory.systemTemp.createTempSync('practice_migration_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/user.db');
    final raw = sqlite3.open(file.path);
    raw.execute(File('test/fixtures/user_v1.sql').readAsStringSync());
    const at = '2026-10-04T12:00:00.000Z';
    raw.execute(
      "INSERT INTO user_cards VALUES ('card','en',0,3,?,?,'deck',0,0,?)",
      [at, at, at],
    );
    raw.execute("INSERT INTO settings VALUES (1,'stable-device','en',?)", [at]);
    raw.execute("INSERT INTO deck_settings VALUES ('deck',0,?)", [at]);
    raw.execute(
      "INSERT INTO review_log VALUES ('pass','card',?,'deck','sentence',1,0,0,0,0,3,?,500,'old','stable-device')",
      [at, at],
    );
    raw.close();
    var db = UserDatabase.file(file);
    var repo = DriftUserRepository(db, lang: 'en');
    expect(await repo.deviceId(), 'stable-device');
    expect((await repo.preferences()).includeDiacritics, isTrue);
    expect((await repo.preferences()).autoNext, isFalse);
    expect((await repo.reviewsFor('card')).single.id, 'pass');
    expect((await repo.cardStates(['card']))['card']!.box, 3);
    expect(await repo.activeDeckIds(['deck']), isEmpty);
    await repo.setCardFlags('card', favorite: true, disabled: true);
    await repo.savePreferences(
      const PracticePreferences(
        motif: AppMotif.light,
        includeDiacritics: false,
        autoNext: true,
        showGrammar: true,
      ),
    );
    await repo.saveSubmission(
      LocalSubmission(
        id: 'report',
        createdAt: DateTime.utc(2026, 10, 4),
        text: 'Beschreibung',
        category: 'Grammatik',
        cardId: 'card',
        sentenceId: 'sentence',
        packVersion: 'pack-v1',
      ),
    );
    await expectLater(
      db.customStatement("DELETE FROM review_log"),
      throwsA(anything),
    );
    await repo.close();
    db = UserDatabase.file(file);
    repo = DriftUserRepository(db, lang: 'en');
    addTearDown(repo.close);
    final state = (await repo.cardStates(['card']))['card']!;
    expect(state.favorite, isTrue);
    expect(state.disabled, isTrue);
    expect(state.box, 3);
    expect(await repo.deviceId(), 'stable-device');
    expect(await repo.reviewsFor('card'), hasLength(1));
    final preferences = await repo.preferences();
    expect(preferences.motif, AppMotif.light);
    expect(preferences.includeDiacritics, isFalse);
    expect(preferences.autoNext, isTrue);
    expect(preferences.showGrammar, isTrue);
    final report = (await repo.submissions()).single;
    expect(report.sentenceId, 'sentence');
    expect(report.packVersion, 'pack-v1');
    expect(report.exportText, contains('Beschreibung'));
    expect(
      (await db.customSelect('PRAGMA user_version').getSingle()).read<int>(
        'user_version',
      ),
      2,
    );
  });
}
