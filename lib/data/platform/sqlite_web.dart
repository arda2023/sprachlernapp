import 'dart:convert';
import 'dart:io' show File;

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:sqlite3/wasm.dart';

export 'package:sqlite3/common.dart';

typedef Database = CommonDatabase;

late WasmSqlite3 sqlite3;
late InMemoryFileSystem _content;
IndexedDbFileSystem? _private;
Future<IndexedDbFileSystem>? _privateOpening;
Future<void>? _opening;

Future<void> initializeSqlitePlatform() => _opening ??= (() async {
  sqlite3 = await WasmSqlite3.loadFromUrl(Uri.parse('sqlite3.wasm'));
  _content = InMemoryFileSystem(name: 'content');
  sqlite3.registerVirtualFileSystem(_content);
})();

QueryExecutor openedDatabase(Database db, {bool enableMigrations = true}) =>
    WasmDatabase.opened(db, enableMigrations: enableMigrations);

QueryExecutor fileDatabase(File file) =>
    throw UnsupportedError('Native database path in a browser.');
Future<bool> canMigrateLegacyJson(String? accountId) async => false;

Future<QueryExecutor> openUserExecutor({
  String? accountId,
  required void Function(File) beforeOpen,
}) async {
  final owner = sha256.convert(utf8.encode(accountId ?? 'guest'));
  final result = await WasmDatabase.open(
    databaseName: 'linglossa_user_$owner',
    sqlite3Uri: Uri.parse('sqlite3.wasm'),
    driftWorkerUri: Uri.parse('drift_worker.js'),
  );
  if (result.chosenImplementation == WasmStorageImplementation.inMemory) {
    await result.resolvedExecutor.close();
    throw StateError(
      'Der Browser erlaubt keinen dauerhaften Speicher. Bitte einen normalen Browser-Tab verwenden.',
    );
  }
  return result.resolvedExecutor;
}

Future<Database> openPrivateDatabase(String name) async {
  await initializeSqlitePlatform();
  final fs = await (_privateOpening ??= IndexedDbFileSystem.open(
    dbName: 'linglossa_private',
    vfsName: 'private',
  ));
  _private = fs;
  // A VFS can be reused by separate account-filtered caches.
  if (!_privateRegistered) {
    sqlite3.registerVirtualFileSystem(fs);
    _privateRegistered = true;
  }
  return sqlite3.open('/$name', vfs: 'private');
}

bool _privateRegistered = false;

Future<Database> openBundledDatabase(Uint8List bytes, String identity) async {
  await initializeSqlitePlatform();
  final path = '/$identity.sqlite';
  final handle = _content
      .xOpen(
        Sqlite3Filename(path),
        SqlFlag.SQLITE_OPEN_CREATE | SqlFlag.SQLITE_OPEN_READWRITE,
      )
      .file;
  handle.xTruncate(0);
  handle.xWrite(bytes, 0);
  handle.xClose();
  return sqlite3.open(path, mode: OpenMode.readOnly, vfs: 'content');
}

Future<void> flushSqlitePlatform() async => _private?.flush();
