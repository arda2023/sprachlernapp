import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/tutor.dart';
import '../user/user_database.dart';
import 'tutor_codec.dart';

class TutorSnapshot {
  TutorSnapshot({
    required Map<String, TutorSkillState> skills,
    required List<TutorItem> items,
    required List<TutorAttempt> attempts,
    this.previousRoundId,
  }) : skills = Map.unmodifiable(skills),
       items = List.unmodifiable(items),
       attempts = List.unmodifiable(attempts);
  final Map<String, TutorSkillState> skills;
  final List<TutorItem> items;
  final List<TutorAttempt> attempts;
  final String? previousRoundId;
}

/// Account isolation is inherited from userDatabaseProvider; every query here
/// additionally binds language. Quota is the exception: it spans all languages.
class TutorStore {
  TutorStore(this.db, {required this.lang});
  final UserDatabase db;
  final String lang;

  Future<TutorSnapshot> snapshot() async {
    final rows = await (db.select(
      db.tutorSkillStates,
    )..where((t) => t.lang.equals(lang))).get();
    final items = await (db.select(
      db.tutorItems,
    )..where((t) => t.lang.equals(lang))).get();
    final byId = {for (final row in items) row.id: _item(row)};
    final attempts =
        await (db.select(db.tutorAttempts)
              ..where((t) => t.lang.equals(lang) & t.resultJson.isNotNull())
              ..orderBy([
                (t) => OrderingTerm.asc(t.createdAt),
                (t) => OrderingTerm.asc(t.attemptId),
              ]))
            .get();
    final shown =
        items
            .where((i) => i.lastRoundId != null && i.lastShownAt != null)
            .toList()
          ..sort((a, b) => b.lastShownAt!.compareTo(a.lastShownAt!));
    return TutorSnapshot(
      skills: {
        for (final s in rows)
          s.skillId: TutorSkillState(
            lang: lang,
            skillId: s.skillId,
            tested: s.tested,
            box: s.box,
            dueAt: s.dueAt?.toUtc(),
            freshStreak: s.freshStreak,
            updatedAt: s.updatedAt.toUtc(),
            lastFreshTopic: s.lastFreshTopic,
          ),
      },
      items: byId.values.toList(),
      attempts: [for (final a in attempts) _attempt(a, byId[a.itemId]!)],
      previousRoundId: shown.firstOrNull?.lastRoundId,
    );
  }

  Future<void> saveItems(List<TutorItem> items) => db.transaction(() async {
    for (final item in items) {
      if (item.lang != lang) throw StateError('Language mismatch');
      await db
          .into(db.tutorItems)
          .insert(_itemRow(item), mode: InsertMode.insertOrIgnore);
      if (item.parentItemId != null) {
        await (db.update(db.tutorItems)..where(
              (t) => t.lang.equals(lang) & t.id.equals(item.parentItemId!),
            ))
            .write(const TutorItemsCompanion(regenerationNeeded: Value(false)));
      }
    }
  });

  Future<void> markShown(
    TutorItem item,
    String roundId,
    DateTime now,
  ) => db.transaction(() async {
    // Keep membership of only the latest round. Timestamps alone cannot order
    // rounds under a fixed clock (or SQLite's second-resolution timestamps).
    await (db.update(db.tutorItems)..where(
          (t) =>
              t.lang.equals(lang) &
              t.lastRoundId.isNotNull() &
              t.lastRoundId.equals(roundId).not(),
        ))
        .write(const TutorItemsCompanion(lastRoundId: Value(null)));
    await (db.update(
      db.tutorItems,
    )..where((t) => t.lang.equals(lang) & t.id.equals(item.id))).write(
      TutorItemsCompanion(lastRoundId: Value(roundId), lastShownAt: Value(now)),
    );
  });

  Future<TutorAttemptRow> prepareAttempt({
    required String attemptId,
    required TutorItem item,
    required String answer,
    required DateTime now,
  }) => db.transaction(() async {
    if (item.lang != lang) throw StateError('Language mismatch');
    answer = normalizeTutorAnswer(answer);
    final existing = await (db.select(
      db.tutorAttempts,
    )..where((t) => t.attemptId.equals(attemptId))).getSingleOrNull();
    if (existing != null) {
      if (existing.lang != lang ||
          existing.itemId != item.id ||
          existing.answer != answer.trim()) {
        throw StateError('Attempt ID conflict');
      }
      return existing;
    }
    final pending =
        await (db.select(db.tutorAttempts)..where(
              (t) =>
                  t.lang.equals(lang) &
                  t.itemId.equals(item.id) &
                  t.resultJson.isNull(),
            ))
            .getSingleOrNull();
    if (pending != null) {
      if (pending.answer != answer.trim()) {
        throw StateError('Pending answer must be recovered unchanged');
      }
      return pending;
    }
    final row = TutorAttemptRow(
      attemptId: attemptId,
      lang: lang,
      itemId: item.id,
      answer: answer.trim(),
      fresh: !item.answerShown,
      createdAt: now,
    );
    await db
        .into(db.tutorAttempts)
        .insert(row, mode: InsertMode.insertOrIgnore);
    final saved = await (db.select(
      db.tutorAttempts,
    )..where((t) => t.attemptId.equals(attemptId))).getSingle();
    if (saved.lang != lang ||
        saved.itemId != item.id ||
        saved.answer != row.answer) {
      throw StateError('Attempt ID conflict');
    }
    return saved;
  });

  Future<List<TutorAttemptRow>> pendingAttempts() =>
      (db.select(db.tutorAttempts)
            ..where((t) => t.lang.equals(lang) & t.resultJson.isNull())
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .get();

  /// Only for a confirmed terminal server failure, never a timeout/lost reply.
  Future<void> discardFailedAttempt(String attemptId) async {
    await (db.delete(db.tutorAttempts)..where(
          (t) =>
              t.lang.equals(lang) &
              t.attemptId.equals(attemptId) &
              t.resultJson.isNull(),
        ))
        .go();
  }

  Future<void> discardFailedGeneration(String requestId) async {
    await (db.delete(
      db.tutorGenerations,
    )..where((t) => t.lang.equals(lang) & t.requestId.equals(requestId))).go();
  }

  Future<void> retireExpiredItem(String itemId, DateTime now) =>
      db.transaction(() async {
        await (db.delete(db.tutorAttempts)..where(
              (row) =>
                  row.lang.equals(lang) &
                  row.itemId.equals(itemId) &
                  row.resultJson.isNull(),
            ))
            .go();
        await (db.update(
          db.tutorItems,
        )..where((row) => row.lang.equals(lang) & row.id.equals(itemId))).write(
          TutorItemsCompanion(
            status: const Value('retired'),
            regenerationNeeded: const Value(false),
            expiresAt: Value(now),
          ),
        );
      });

  /// Attempt result, item transition and all skill updates commit together.
  /// Replaying an attempt never applies its learning transition twice.
  Future<TutorAttempt> completeAttempt(
    TutorAttemptRow pending,
    TutorGrade grade, {
    required DateTime now,
    void Function()? verify,
  }) => db.transaction(() async {
    verify?.call();
    final row =
        await (db.select(db.tutorAttempts)..where(
              (t) =>
                  t.attemptId.equals(pending.attemptId) & t.lang.equals(lang),
            ))
            .getSingle();
    final itemRow = await (db.select(
      db.tutorItems,
    )..where((t) => t.id.equals(row.itemId) & t.lang.equals(lang))).getSingle();
    final item = _item(itemRow);
    if (row.resultJson != null) return _attempt(row, item);
    final attempt = TutorAttempt(
      attemptId: row.attemptId,
      itemId: row.itemId,
      answer: row.answer,
      scores: grade.scores,
      outcome: grade.outcome,
      errors: grade.errors,
      feedbackDe: grade.feedbackDe,
      idealAnswer: grade.idealAnswer,
      fresh: row.fresh,
      createdAt: row.createdAt.toUtc(),
      quotaUsed: grade.used,
      quotaLimit: grade.limit,
    );
    final update = applyTutorAttempt(
      item: item,
      attempt: attempt,
      states: (await snapshot()).skills,
      now: now,
    );
    await (db.update(
      db.tutorAttempts,
    )..where((t) => t.attemptId.equals(row.attemptId))).write(
      TutorAttemptsCompanion(resultJson: Value(jsonEncode(grade.toJson()))),
    );
    await db.update(db.tutorItems).replace(_itemRow(update.item));
    for (final s in update.states.values) {
      await db
          .into(db.tutorSkillStates)
          .insertOnConflictUpdate(
            TutorSkillRow(
              lang: lang,
              skillId: s.skillId,
              tested: s.tested,
              box: s.box,
              dueAt: s.dueAt,
              freshStreak: s.freshStreak,
              updatedAt: s.updatedAt,
              lastFreshTopic: s.lastFreshTopic,
            ),
          );
    }
    verify?.call();
    return attempt;
  });

  Future<List<TutorGenerationRequest>> pendingGenerations() async => [
    for (final r in await (db.select(
      db.tutorGenerations,
    )..where((t) => t.lang.equals(lang))).get())
      TutorGenerationRequest.fromStorageJson(
        jsonDecode(r.payloadJson) as Map<String, dynamic>,
      ),
  ];
  Future<void> prepareGeneration(TutorGenerationRequest request) async {
    if (request.lang != lang) throw StateError('Language mismatch');
    request.validate();
    final payload = jsonEncode(request.toStorageJson());
    await db
        .into(db.tutorGenerations)
        .insert(
          TutorGenerationRow(
            requestId: request.requestId,
            lang: lang,
            payloadJson: payload,
          ),
          mode: InsertMode.insertOrIgnore,
        );
    final row = await (db.select(
      db.tutorGenerations,
    )..where((t) => t.requestId.equals(request.requestId))).getSingle();
    if (row.payloadJson != payload) throw StateError('Generation ID conflict');
  }

  Future<void> completeGeneration(
    TutorGenerationRequest request,
    List<TutorItem> items, {
    void Function()? verify,
  }) => db.transaction(() async {
    verify?.call();
    await saveItems(items);
    await (db.delete(db.tutorGenerations)..where(
          (t) => t.lang.equals(lang) & t.requestId.equals(request.requestId),
        ))
        .go();
    verify?.call();
  });

  /// Derived from successful attempts and server quota observations, across
  /// languages. The server remains authoritative for other devices.
  Future<int> remainingFreeToday(DateTime now) async {
    final today = tutorBerlinDay(now);
    final rows =
        await (db.select(db.tutorAttempts)
              ..where((t) => t.resultJson.isNotNull())
              ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
            .get();
    var successful = 0, observed = 0;
    for (final row in rows) {
      final quota = (jsonDecode(row.resultJson!) as Map)['quota'] as Map;
      if (quota['quota_day'] != today) continue;
      successful++;
      final server = quota['used'] as int;
      if (server > observed) observed = server;
    }
    final used = successful > observed ? successful : observed;
    return (3 - used).clamp(0, 3);
  }
}

bool _zonesReady = false;
String tutorBerlinDay(DateTime time) {
  if (!_zonesReady) {
    tzdata.initializeTimeZones();
    _zonesReady = true;
  }
  final local = tz.TZDateTime.from(time, tz.getLocation('Europe/Berlin'));
  return '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}

TutorItem _item(TutorItemRow row) => TutorItem(
  id: row.id,
  lang: row.lang,
  kind: TutorKind.values.byName(row.kind),
  promptDe: row.promptDe,
  referenceAnswer: row.referenceAnswer,
  skills: List<String>.from(jsonDecode(row.skillsJson) as List),
  topic: row.topic,
  origin: TutorOrigin.values.byName(row.origin),
  expiresAt: row.expiresAt.toUtc(),
  parentItemId: row.parentItemId,
  failures: row.failures,
  answerShown: row.answerShown,
  status: row.status == 'new'
      ? TutorItemStatus.fresh
      : TutorItemStatus.values.byName(row.status),
  lastShownAt: row.lastShownAt?.toUtc(),
  lastRoundId: row.lastRoundId,
  regenerationNeeded: row.regenerationNeeded,
);
TutorItemRow _itemRow(TutorItem i) => TutorItemRow(
  id: i.id,
  lang: i.lang,
  kind: i.kind.name,
  promptDe: i.promptDe,
  referenceAnswer: i.referenceAnswer,
  skillsJson: jsonEncode(i.skills),
  topic: i.topic,
  origin: i.origin.name,
  expiresAt: i.expiresAt,
  parentItemId: i.parentItemId,
  failures: i.failures,
  answerShown: i.answerShown,
  status: i.status == TutorItemStatus.fresh ? 'new' : i.status.name,
  lastShownAt: i.lastShownAt,
  lastRoundId: i.lastRoundId,
  regenerationNeeded: i.regenerationNeeded,
);
TutorAttempt _attempt(TutorAttemptRow row, TutorItem item) {
  final grade = decodeTutorGrade(jsonDecode(row.resultJson!), item);
  return TutorAttempt(
    attemptId: row.attemptId,
    itemId: row.itemId,
    answer: row.answer,
    scores: grade.scores,
    outcome: grade.outcome,
    errors: grade.errors,
    feedbackDe: grade.feedbackDe,
    idealAnswer: grade.idealAnswer,
    fresh: row.fresh,
    createdAt: row.createdAt.toUtc(),
    quotaUsed: grade.used,
    quotaLimit: grade.limit,
  );
}
