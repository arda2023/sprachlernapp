import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'user_database.g.dart';

/// `user_cards` (docs/user-schema.md): learner state per card, a cache of
/// creation + `review_log`. Only ids and state, never content texts.
@DataClassName('UserCardRow')
class UserCards extends Table {
  TextColumn get cardId => text()();
  TextColumn get lang => text()();
  BoolColumn get localOnly => boolean().withDefault(const Constant(false))();
  IntColumn get box =>
      integer().check(const CustomExpression('box BETWEEN 0 AND 5'))();

  /// Start of a local day; null only in box 0.
  DateTimeColumn get dueAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get origin =>
      text().check(const CustomExpression("origin IN ('deck', 'story')"))();
  BoolColumn get disabled => boolean().withDefault(const Constant(false))();
  BoolColumn get favorite => boolean().withDefault(const Constant(false))();
  BoolColumn get retired => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {cardId};
}

/// `review_log` (docs/srs.md): append-only, one row per first pass. The
/// primary key is the pass id, so the same pass can never be booked twice.
@DataClassName('ReviewLogRow')
@TableIndex(name: 'review_log_card', columns: {#cardId})
class ReviewLog extends Table {
  TextColumn get id => text()();
  TextColumn get cardId => text()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get mode => text().check(
    const CustomExpression("mode IN ('mixed', 'deck', 'revue', 'early')"),
  )();
  TextColumn get sentenceId => text()();
  BoolColumn get firstAttemptCorrect => boolean()();
  IntColumn get errorCount =>
      integer().check(const CustomExpression('error_count >= 0'))();
  BoolColumn get revealed => boolean()();
  BoolColumn get hintUsed => boolean().withDefault(const Constant(false))();
  IntColumn get boxBefore =>
      integer().check(const CustomExpression('box_before BETWEEN 0 AND 5'))();
  IntColumn get boxAfter =>
      integer().check(const CustomExpression('box_after BETWEEN 1 AND 5'))();
  DateTimeColumn get dueAtAfter => dateTime()();
  IntColumn get responseMs => integer().nullable()();
  TextColumn get appVersion => text()();
  TextColumn get deviceId => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// `deck_settings`: the "Stapel lernen" switch; no row = active.
@DataClassName('DeckSettingRow')
class DeckSettings extends Table {
  TextColumn get deckId => text()();
  BoolColumn get active => boolean()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {deckId};
}

/// `settings`: one row (id 1) with the local device id and preferences.
@DataClassName('SettingsRow')
class Settings extends Table {
  TextColumn get motif => text().withDefault(const Constant('automatic'))();
  BoolColumn get includeDiacritics =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get autoNext => boolean().withDefault(const Constant(false))();
  BoolColumn get showGrammar => boolean().withDefault(const Constant(false))();
  IntColumn get id => integer().check(const CustomExpression('id = 1'))();
  TextColumn get deviceId => text()();
  TextColumn get targetLang => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local feedback and problem reports, exported only on explicit user action.
@DataClassName('SubmissionRow')
class LocalSubmissions extends Table {
  TextColumn get id => text()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get body => text()();
  TextColumn get category => text().nullable()();
  IntColumn get rating => integer().nullable()();
  TextColumn get cardId => text().nullable()();
  TextColumn get sentenceId => text().nullable()();
  TextColumn get packVersion => text().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

/// Learner database (schema v2). Content stays in read-only content.sqlite;
/// both databases are joined only by stable ids.
@DriftDatabase(
  tables: [UserCards, ReviewLog, DeckSettings, Settings, LocalSubmissions],
)
class UserDatabase extends _$UserDatabase {
  UserDatabase(super.executor);

  /// user.db at [file], created on first open.
  factory UserDatabase.file(File file) => UserDatabase(NativeDatabase(file));

  /// `<application support>/user.db`, opened on a background isolate.
  static Future<UserDatabase> openForApp() async {
    final dir = await getApplicationSupportDirectory();
    return UserDatabase(
      NativeDatabase.createInBackground(File(p.join(dir.path, 'user.db'))),
    );
  }

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(userCards, userCards.favorite);
        await m.addColumn(settings, settings.motif);
        await m.addColumn(settings, settings.includeDiacritics);
        await m.addColumn(settings, settings.autoNext);
        await m.addColumn(settings, settings.showGrammar);
        await m.createTable(localSubmissions);
      }
    },
    onCreate: (m) async {
      await m.createAll();
      // review_log is append-only (ARCHITECTURE.md, Regeln) – also for raw SQL.
      await customStatement(
        "CREATE TRIGGER review_log_no_update BEFORE UPDATE ON review_log "
        "BEGIN SELECT RAISE(ABORT, 'review_log is append-only'); END",
      );
      await customStatement(
        "CREATE TRIGGER review_log_no_delete BEFORE DELETE ON review_log "
        "BEGIN SELECT RAISE(ABORT, 'review_log is append-only'); END",
      );
    },
  );
}
