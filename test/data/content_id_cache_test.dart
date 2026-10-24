import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/data/content/content_database.dart';
import 'package:sprachapp/data/content/drift_content_repository.dart';
import 'package:sprachapp/domain/content.dart';

import 'support.dart';

class IdQueryCounter extends QueryInterceptor {
  int reads = 0;
  bool failNext = false;
  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor e,
    String sql,
    List<Object?> args,
  ) {
    if (sql == 'SELECT id FROM cards WHERE lang = ? AND removed_in IS NULL') {
      reads++;
      if (failNext) {
        failNext = false;
        throw StateError('synthetic read failure');
      }
    }
    return e.runSelect(sql, args);
  }
}

void main() {
  test('pack IDs load once across parallel guards; results and repository snapshots stay isolated', () async {
    final dir = Directory.systemTemp.createTempSync('content-id-cache-');
    final file = buildFixturePack(dir);
    final counter = IdQueryCounter();
    const info = ContentInfo(lang: 'en', version: 'fixture', schemaVersion: 1);
    DriftContentRepository open() => DriftContentRepository(
      ContentDatabase.forTesting(
        NativeDatabase(
          file,
          enableMigrations: false,
          setup: (raw) => raw.execute('PRAGMA query_only=ON'),
        ).interceptWith(counter),
        info,
      ),
    );
    var repo = open();
    try {
      final values = await Future.wait(
        List.generate(8, (_) => repo.allCardIds()),
      );
      expect(counter.reads, 1);
      final original = Set<String>.of(values.first);
      expect(original, isNotEmpty);
      values.first.clear();
      expect(values.last, original);
      expect(await repo.allCardIds(), original);
      expect(counter.reads, 1);
      await repo.close();
      repo = open();
      counter.failNext = true;
      await expectLater(repo.allCardIds(), throwsStateError);
      expect(await repo.allCardIds(), original);
      expect(counter.reads, 3, reason: 'new pack handle + retry after failure');
    } finally {
      await repo.close();
      dir.deleteSync(recursive: true);
    }
  });
}
