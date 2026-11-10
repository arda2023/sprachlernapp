import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sprachapp/data/platform/json_store.dart';
import 'package:sprachapp/data/platform/sqlite_native.dart';
import 'package:sprachapp/presentation/providers/reading_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('account_isolation_');
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getApplicationSupportDirectory') {
            return directory.path;
          }
          throw UnsupportedError(call.method);
        });
  });
  tearDown(() async {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    await directory.delete(recursive: true);
  });

  test('first account retains legacy data, other account and signed-out guest are isolated', () async {
    final legacy = await accountDatabaseFile(directory, null);
    await legacy.writeAsString('existing learning data');
    final first = await accountDatabaseFile(directory, 'project:alice');
    expect(first.path, legacy.path);
    expect(await first.readAsString(), 'existing learning data');
    final second = await accountDatabaseFile(directory, 'project:bob');
    final guest = await accountDatabaseFile(directory, null);
    expect(second.path, isNot(first.path));
    expect(p.basename(guest.path), 'guest.db');
    expect(second.path, isNot(guest.path));
    expect(
      (await accountDatabaseFile(directory, 'project:alice')).path,
      first.path,
    );
    expect(
      (await accountDatabaseFile(directory, 'other-project:alice')).path,
      isNot(first.path),
    );
  });

  test(
    'concurrent account selection claims legacy database exactly once',
    () async {
      final files = await Future.wait([
        accountDatabaseFile(directory, 'project:alice'),
        accountDatabaseFile(directory, 'project:bob'),
        accountDatabaseFile(directory, 'project:alice'),
      ]);
      expect(p.basename(files.first.path), 'user.db');
      expect(files[1].path, isNot(files.first.path));
      expect(files[2].path, files.first.path);
      expect(
        await File(p.join(directory.path, 'user.db.owner')).readAsString(),
        'project:alice',
      );
    },
  );

  test(
    'legacy imported text is available only to its original owner',
    () async {
      await FileJsonStore('imported_texts_en').write([
        {'id': 'private', 'body': 'original owner'},
      ]);
      await accountDatabaseFile(directory, 'project:alice');
      expect(
        await AccountLegacyJsonStore(
          'imported_texts_en',
          'project:alice',
        ).read(),
        hasLength(1),
      );
      expect(
        await AccountLegacyJsonStore('imported_texts_en', 'project:bob').read(),
        isNull,
      );
      expect(
        await AccountLegacyJsonStore('imported_texts_en', null).read(),
        isNull,
      );
    },
  );
}
