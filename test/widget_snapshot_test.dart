import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/data/widgets/widget_gateway.dart';
import 'package:sprachapp/domain/srs_state.dart';
import 'package:sprachapp/domain/streak.dart';
import 'package:sprachapp/domain/widget_snapshot.dart';
import 'package:sprachapp/presentation/widgets/widget_snapshot_service.dart';

final now = DateTime(2026, 11, 13, 18);

LearningWidgetSnapshot snapshot({
  String language = 'en',
  Iterable<WidgetStory> library = const [],
  Map<String, WidgetReading> reading = const {},
}) => buildLearningWidgetSnapshot(
  now: now,
  language: language,
  goalDone: 8,
  goalTarget: 10,
  streak: summarizeStreak([
    DateTime(2026, 11, 12),
    DateTime(2026, 11, 13),
  ], now),
  eligibleCardIds: const [
    'due',
    'later',
    'disabled',
    'retired',
    'new',
    'null',
    'due',
  ],
  cards: {
    'due': UserCardState(
      cardId: 'due',
      box: 2,
      dueAt: now.subtract(const Duration(hours: 1)),
    ),
    'later': UserCardState(
      cardId: 'later',
      box: 5,
      dueAt: now.add(const Duration(hours: 2)),
    ),
    'disabled': UserCardState(
      cardId: 'disabled',
      box: 2,
      dueAt: now,
      disabled: true,
    ),
    'retired': UserCardState(
      cardId: 'retired',
      box: 2,
      dueAt: now,
      retired: true,
    ),
    'new': const UserCardState(cardId: 'new', box: 0, dueAt: null),
    'null': const UserCardState(cardId: 'null', box: 1, dueAt: null),
    'hidden': UserCardState(cardId: 'hidden', box: 2, dueAt: now),
  },
  library: library,
  reading: reading,
);

WidgetReading readingAt(
  DateTime date, {
  double fraction = 0.42,
  bool finished = false,
}) => WidgetReading(fraction: fraction, updatedAt: date, finished: finished);

void main() {
  test('projects local calendar and exact eligible due instants without stored counts', () {
    final data = snapshot().json;
    expect(data['day'], '2026-11-13');
    expect(data['streak'], 2);
    expect(data['goalDone'], 8);
    expect(data['goalTarget'], 10);
    expect(data['activeDays'], ['2026-11-12', '2026-11-13']);
    final dates = (data['dueDates'] as List)
        .cast<String>()
        .map(DateTime.parse)
        .toList();
    expect(dates.length, 3);
    expect(dates.where((date) => !date.isAfter(now)), hasLength(2));
    expect(dates.every((date) => date.isUtc), isTrue);
    expect(data.containsKey('dueCount'), isFalse);
  });

  test('only unfinished editorial stories enter the continuation snapshot', () {
    final result = snapshot(
      library: const [
        WidgetStory(id: 'older', title: 'Old'),
        WidgetStory(
          id: 'newer',
          title: 'New',
          coverAsset: 'assets/story_covers/video_01.png',
        ),
        WidgetStory(id: 'done', title: 'Finished'),
        WidgetStory(id: 'import-private', title: 'Secret import'),
      ],
      reading: {
        'older': readingAt(now.subtract(const Duration(days: 1))),
        'newer': readingAt(now),
        'done': readingAt(now.add(const Duration(minutes: 1)), finished: true),
        'import-private': readingAt(now.add(const Duration(minutes: 2))),
        'not-in-library': readingAt(now.add(const Duration(minutes: 3))),
      },
    );
    expect((result.json['story'] as Map)['id'], 'newer');
    expect((result.json['story'] as Map)['progress'], 0.42);
    expect(result.coverAsset, 'assets/story_covers/video_01.png');
    expect(jsonEncode(result.json), isNot(contains('Secret import')));
    expect(jsonEncode(result.json), isNot(contains('not-in-library')));
  });

  test(
    'invalid progress and arbitrary image paths cannot cross the bridge',
    () {
      final data = snapshot(
        library: const [
          WidgetStory(
            id: 'story',
            title: 'Title',
            coverAsset: '/private/secret.png',
          ),
        ],
        reading: {'story': readingAt(now, fraction: double.nan)},
      );
      expect(data.json['story'], isNull);
      expect(data.coverAsset, isNull);
      final valid = snapshot(
        library: const [
          WidgetStory(
            id: 'story',
            title: 'Title',
            coverAsset: 'assets/story_covers/../private.png',
          ),
        ],
        reading: {'story': readingAt(now)},
      );
      expect(valid.json['story'], isNotNull);
      expect(valid.coverAsset, isNull);
    },
  );

  test('empty or unsupported language contains no previous data', () {
    expect(const LearningWidgetSnapshot.empty().json, {
      'schemaVersion': 1,
      'available': false,
    });
    expect(
      snapshot(language: 'unknown').json,
      const LearningWidgetSnapshot.empty().json,
    );
  });

  test(
    'newest account clear is written after any in-flight prior snapshot',
    () async {
      final gate = Completer<void>();
      final gateway = FakeWidgetGateway()..gate = gate;
      final service = WidgetSnapshotService(gateway);
      final old = service.publish(snapshot());
      await Future<void>.delayed(Duration.zero);
      final clear = service.publish(const LearningWidgetSnapshot.empty());
      gate.complete();
      await Future.wait([old, clear]);
      expect(gateway.writes.last.json['available'], isFalse);
      expect(gateway.reloads, 2);
      service.dispose();
    },
  );

  test(
    'queued obsolete snapshots are discarded and failed writes can retry',
    () async {
      final gateway = FakeWidgetGateway()..fail = true;
      final service = WidgetSnapshotService(gateway);
      await service.publish(snapshot());
      gateway.fail = false;
      final one = service.publish(snapshot());
      final two = service.publish(const LearningWidgetSnapshot.empty());
      await Future.wait([one, two]);
      expect(gateway.writes, hasLength(1));
      expect(gateway.writes.single.json['available'], isFalse);
      expect(gateway.reloads, 1);
      service.dispose();
    },
  );

  test('unsupported platforms never touch the shared container', () async {
    final gateway = FakeWidgetGateway()..supported = false;
    final service = WidgetSnapshotService(gateway);
    await service.publish(snapshot());
    expect(gateway.writes, isEmpty);
    expect(gateway.reloads, 0);
    service.dispose();
  });

  test(
    'a queued logout tombstone survives a newer failed projection',
    () async {
      final gateway = FakeWidgetGateway();
      final service = WidgetSnapshotService(gateway);
      await service.publish(snapshot());
      gateway.failAvailable = true;
      final clear = service.publish(const LearningWidgetSnapshot.empty());
      final next = service.publish(snapshot());
      await Future.wait([clear, next]);
      expect(gateway.writes.last.json['available'], isFalse);
      service.dispose();
    },
  );
}

class FakeWidgetGateway implements WidgetGateway {
  @override
  bool supported = true;
  Completer<void>? gate;
  bool fail = false;
  bool failAvailable = false;
  int reloads = 0;
  final writes = <LearningWidgetSnapshot>[];
  @override
  Stream<Uri?> get launches => const Stream.empty();
  @override
  Future<Uri?> initialLaunch() async => null;
  @override
  Future<void> write(LearningWidgetSnapshot snapshot) async {
    await gate?.future;
    if (fail || (failAvailable && snapshot.json['available'] == true)) {
      throw StateError('Unavailable container');
    }
    writes.add(snapshot);
  }

  @override
  Future<void> reload() async {
    reloads++;
  }
}
