import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/data/sync/learning_sync.dart';
import 'package:sprachapp/data/user/user_database.dart';

class SyncQueryCounts extends QueryInterceptor {
  int selects = 0, versions = 0;
  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    selects++;
    if (statement.contains('FROM learning_sync_versions')) versions++;
    return executor.runSelect(statement, args);
  }
}

class QuietSyncCloud implements LearningSyncGateway {
  int pushed = 0;
  @override
  Future<void> push(List<LearningSyncRow> rows) async {
    pushed += rows.length;
  }

  @override
  Future<List<LearningSyncRow>> pull({String? after}) async => [];
}

void main() {
  test('periodic sync reads version metadata in bulk, independent of card count', () async {
    final queries = SyncQueryCounts();
    final database = UserDatabase(
      NativeDatabase.memory().interceptWith(queries),
    );
    addTearDown(database.close);
    final cloud = QuietSyncCloud();
    final sync = LearningSyncService(
      database,
      cloud,
      owner: 'synthetic-account',
      isCurrent: () => true,
    );
    await database.transaction(() async {
      for (var i = 0; i < 600; i++) {
        await database.customStatement(
          "INSERT INTO user_cards(card_id,lang,box,due_at,created_at,origin,updated_at) VALUES(?,'en',2,'2026-11-12T00:00:00Z','2026-11-01T00:00:00Z','deck','2026-11-07T00:00:00Z')",
          ['card-$i'],
        );
      }
    });
    await sync.synchronize();
    expect(cloud.pushed, 600);
    queries.selects = 0;
    queries.versions = 0;
    cloud.pushed = 0;
    final watch = Stopwatch()..start();
    await sync.synchronize();
    watch.stop();
    debugPrint(
      'SYNC WORK: 600 cards, version reads=${queries.versions}, all selects=${queries.selects}, elapsed=${watch.elapsedMilliseconds}ms, uploads=${cloud.pushed}',
    );
    expect(cloud.pushed, 0);
    if (!const bool.fromEnvironment('BASELINE')) {
      expect(
        queries.versions,
        2,
        reason: 'One metadata snapshot before upload and one after download; never one query per card.',
      );
      expect(queries.selects, lessThan(50));
    }
    await database.customStatement(
      "UPDATE user_cards SET box=3,updated_at='2026-11-11T12:00:00Z' WHERE card_id='card-10'",
    );
    await sync.synchronize();
    expect(
      cloud.pushed,
      1,
      reason: 'Bulk metadata must still detect a changed card.',
    );
  });
}
