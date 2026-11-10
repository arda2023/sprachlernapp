import 'dart:async';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/data/sync/learning_sync.dart';
import 'package:sprachapp/data/sync/sync_json_store.dart';
import 'package:sprachapp/data/user/user_database.dart';

class MemorySync implements LearningSyncGateway {
  final rows = <String, LearningSyncRow>{};
  Future<void> Function()? beforePull;
  @override
  Future<void> push(List<LearningSyncRow> incoming) async {
    for (final row in incoming) {
      final key = '${row.table}:${row.key}';
      final old = rows[key];
      if (old == null ||
          row.changedAt > old.changedAt ||
          (row.changedAt == old.changedAt &&
              row.hash.compareTo(old.hash) > 0)) {
        rows[key] = row;
      }
    }
  }

  @override
  Future<List<LearningSyncRow>> pull({String? after}) async {
    await beforePull?.call();
    beforePull = null;
    return rows.values.toList();
  }
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late UserDatabase phone, web;
  late MemorySync cloud;
  const owner = 'example.supabase.co:account-a';
  LearningSyncService service(
    UserDatabase db, {
    String identity = owner,
    bool Function()? current,
  }) => LearningSyncService(
    db,
    cloud,
    owner: identity,
    isCurrent: current ?? () => true,
  );
  Future<void> card(UserDatabase db, {int box = 2, int at = 1800000000}) =>
      db.customStatement(
        "INSERT INTO user_cards(card_id,lang,box,due_at,created_at,origin,updated_at) VALUES('card-a','en',?,'2027-01-15T10:00:00Z','2023-11-14T10:00:00Z','deck',?)",
        [
          box,
          DateTime.fromMillisecondsSinceEpoch(at * 1000)
              .toUtc()
              .toIso8601String(),
        ],
      );
  setUp(() {
    phone = UserDatabase(NativeDatabase.memory());
    web = UserDatabase(NativeDatabase.memory());
    cloud = MemorySync();
  });
  tearDown(() async {
    await phone.close();
    await web.close();
  });

  test(
    'phone learning state reaches browser and later browser review returns',
    () async {
      await card(phone);
      expect(await service(phone).synchronize(), isFalse);
      expect(await service(web).synchronize(), isTrue);
      expect((await web.select(web.userCards).getSingle()).box, 2);
      await web.customStatement(
        "UPDATE user_cards SET box=4,updated_at='2030-03-17T00:00:00Z' WHERE card_id='card-a'",
      );
      await service(web).synchronize();
      await service(phone).synchronize();
      expect((await phone.select(phone.userCards).getSingle()).box, 4);
      expect(await service(phone).synchronize(), isFalse);
    },
  );

  test(
    'persisted database binding prevents upload under another account',
    () async {
      await card(phone);
      await service(phone).synchronize();
      final count = cloud.rows.length;
      await expectLater(
        service(phone, identity: 'different-account').synchronize(),
        throwsA(isA<LearningSyncAccountMismatch>()),
      );
      expect(cloud.rows.length, count);
    },
  );

  test('account switch during download never applies remote state', () async {
    await card(phone);
    await service(phone).synchronize();
    var current = true;
    cloud.beforePull = () async {
      current = false;
    };
    await expectLater(
      service(web, current: () => current).synchronize(),
      throwsStateError,
    );
    expect(await web.select(web.userCards).get(), isEmpty);
  });

  test(
    'edits made during network request survive older remote response',
    () async {
      await card(phone);
      await service(phone).synchronize();
      await service(web).synchronize();
      cloud.beforePull = () async {
        await web.customStatement(
          "UPDATE user_cards SET box=5,updated_at='2033-05-18T00:00:00Z' WHERE card_id='card-a'",
        );
      };
      await service(web).synchronize();
      expect((await web.select(web.userCards).getSingle()).box, 5);
      await service(web).synchronize();
      await service(phone).synchronize();
      expect((await phone.select(phone.userCards).getSingle()).box, 5);
    },
  );

  test('reader progress and import deletion tombstones converge', () async {
    final a = SyncJsonStore(Future.value(phone), 'reading_progress_en');
    final b = SyncJsonStore(Future.value(web), 'reading_progress_en');
    await a.write({
      'story': {
        'fraction': .7,
        'finished': false,
        'updatedAt': '2026-11-07T10:00:00Z',
      },
    });
    await service(phone).synchronize();
    await service(web).synchronize();
    expect((await b.read() as Map)['story']['fraction'], .7);
    final importsA = SyncJsonStore(
      Future.value(phone),
      'imported_texts_en',
      list: true,
    );
    final importsB = SyncJsonStore(
      Future.value(web),
      'imported_texts_en',
      list: true,
    );
    await importsA.write([
      {'id': 'private', 'body': 'Hello', 'createdAt': '2026-11-07T10:00:00Z'},
    ]);
    await service(phone).synchronize();
    await service(web).synchronize();
    expect(await importsB.read(), hasLength(1));
    await importsB.write([]);
    await service(web).synchronize();
    await service(phone).synchronize();
    expect(await importsA.read(), isEmpty);
    await service(phone).synchronize();
    await service(web).synchronize();
    expect(await importsB.read(), isEmpty);
  });
  test(
    'a stale reader/import writer cannot delete an unseen remote entry',
    () async {
      final a = SyncJsonStore(
        Future.value(phone),
        'imported_texts_en',
        list: true,
      );
      final b = SyncJsonStore(
        Future.value(web),
        'imported_texts_en',
        list: true,
      );
      await b.read(); // Browser has not seen the phone's new import.
      await a.write([
        {'id': 'phone', 'body': 'hello'},
      ]);
      await service(phone).synchronize();
      await service(web).synchronize();
      await b.write([
        {'id': 'web', 'body': 'world'},
      ]);
      expect(await b.read(), hasLength(2));
    },
  );

  test(
    'finished stories stay finished when another device scrolls earlier',
    () async {
      final a = SyncJsonStore(Future.value(phone), 'reading_progress_en');
      final b = SyncJsonStore(Future.value(web), 'reading_progress_en');
      await a.write({
        'story': {
          'fraction': 1.0,
          'finished': true,
          'updatedAt': '2026-11-07T10:00:00Z',
        },
      });
      await b.write({
        'story': {
          'fraction': .2,
          'finished': false,
          'updatedAt': '2026-11-07T11:00:00Z',
        },
      });
      await service(phone).synchronize();
      await service(web).synchronize();
      await service(phone).synchronize();
      expect((await a.read() as Map)['story']['finished'], isTrue);
      expect((await a.read() as Map)['story']['fraction'], .2);
      await service(phone).synchronize();
      await service(web).synchronize();
      expect((await b.read() as Map)['story']['finished'], isTrue);
    },
  );

  test('review history is append-only and survives a second device', () async {
    await card(phone);
    await phone.customStatement(
      "INSERT INTO review_log(id,card_id,created_at,mode,sentence_id,first_attempt_correct,error_count,revealed,box_before,box_after,due_at_after,app_version,device_id) VALUES('pass-a','card-a','2026-11-07T10:00:00Z','deck','sentence',1,0,0,1,2,'2026-11-08T00:00:00Z','1','phone')",
    );
    await service(phone).synchronize();
    await service(web).synchronize();
    expect((await web.select(web.reviewLog).getSingle()).id, 'pass-a');
    await expectLater(
      web.customStatement(
        "UPDATE review_log SET box_after=5 WHERE id='pass-a'",
      ),
      throwsA(anything),
    );
    await service(web).synchronize();
    expect(await phone.select(phone.reviewLog).get(), hasLength(1));
  });
  test(
    'disposed store cannot mark another account migration complete',
    () async {
      final opening = Completer<UserDatabase>();
      var current = true;
      final store = SyncJsonStore(
        opening.future,
        'reading_progress_en',
        isCurrent: () => current,
      );
      final pending = store.read();
      current = false;
      opening.complete(web);
      expect(await pending, isNull);
      await prepareLearningSync(web);
      expect(
        await web
            .customSelect('SELECT * FROM learning_sync_document_imports')
            .get(),
        isEmpty,
      );
    },
  );
}
