import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

export 'package:sqlite3/sqlite3.dart';

Future<void> initializeSqlitePlatform() async {}

QueryExecutor openedDatabase(Database db, {bool enableMigrations = true}) =>
    NativeDatabase.opened(db, enableMigrations: enableMigrations);

QueryExecutor fileDatabase(File file) => NativeDatabase(file);

Future<bool> canMigrateLegacyJson(String? accountId) async {
  final support = await getApplicationSupportDirectory();
  return p.basename((await accountDatabaseFile(support, accountId)).path) ==
      'user.db';
}

Future<QueryExecutor> openUserExecutor({
  String? accountId,
  required void Function(File) beforeOpen,
}) async {
  final support = await getApplicationSupportDirectory();
  await support.create(recursive: true);
  final file = await accountDatabaseFile(support, accountId);
  beforeOpen(file);
  return NativeDatabase.createInBackground(file);
}

/// The first account keeps the phone's existing progress. Every subsequent
/// account, and the signed-out guest, has a separate database.
Future<void> _accountSelection = Future.value();

Future<File> accountDatabaseFile(Directory support, String? accountId) {
  final operation = _accountSelection.then(
    (_) => _selectAccountDatabaseFile(support, accountId),
  );
  _accountSelection = operation.then<void>(
    (_) {},
    onError: (Object _, StackTrace _) {},
  );
  return operation;
}

Future<File> _selectAccountDatabaseFile(
  Directory support,
  String? accountId,
) async {
  final marker = File(p.join(support.path, 'user.db.owner'));
  String? owner = await marker.exists() ? await marker.readAsString() : null;
  if (owner == null && accountId != null) {
    final temporary = File('${marker.path}.tmp');
    await temporary.writeAsString(accountId, flush: true);
    await temporary.rename(marker.path);
    owner = accountId;
  }
  final filename = owner == null || owner == accountId
      ? 'user.db'
      : accountId == null
      ? 'guest.db'
      : 'user_${sha256.convert(utf8.encode(accountId))}.db';
  return File(p.join(support.path, filename));
}

Future<Database> openPrivateDatabase(String name) async {
  final support = await getApplicationSupportDirectory();
  await support.create(recursive: true);
  return sqlite3.open(p.join(support.path, name));
}

Future<Database> openBundledDatabase(Uint8List bytes, String identity) =>
    throw UnsupportedError('Bundled browser database requested on native.');

Future<void> flushSqlitePlatform() async {}
