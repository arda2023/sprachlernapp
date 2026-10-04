import 'package:drift/drift.dart';
import 'package:characters/characters.dart';

import '../../domain/preferences.dart';

import '../../domain/repositories.dart';
import '../../domain/srs_state.dart';
import 'user_database.dart';

/// [UserRepository] on the Drift user.db of one language.
class DriftUserRepository implements UserRepository {
  DriftUserRepository(this._db, {required this.lang});

  final UserDatabase _db;
  final String lang;

  static const _chunk = 500;

  Iterable<List<String>> _chunks(Iterable<String> ids) sync* {
    final list = ids.toSet().toList();
    for (var i = 0; i < list.length; i += _chunk) {
      yield list.sublist(
        i,
        i + _chunk > list.length ? list.length : i + _chunk,
      );
    }
  }

  UserCardState _state(UserCardRow r) => UserCardState(
    cardId: r.cardId,
    box: r.box,
    dueAt: r.dueAt?.toLocal(),
    disabled: r.disabled,
    favorite: r.favorite,
    note: r.note,
    inPlaylist: r.inPlaylist,
    retired: r.retired,
    localOnly: r.localOnly,
    origin: CardOrigin.fromCode(r.origin),
    createdAt: r.createdAt.toLocal(),
  );

  @override
  Future<Map<String, UserCardState>> cardStates(
    Iterable<String> cardIds,
  ) async {
    final out = <String, UserCardState>{};
    for (final chunk in _chunks(cardIds)) {
      final rows = await (_db.select(
        _db.userCards,
      )..where((t) => t.cardId.isIn(chunk))).get();
      for (final r in rows) {
        out[r.cardId] = _state(r);
      }
    }
    return out;
  }

  @override
  Future<Map<String, UserCardState>> allCardStates() async {
    final rows = await (_db.select(
      _db.userCards,
    )..where((t) => t.lang.equals(lang))).get();
    return {for (final r in rows) r.cardId: _state(r)};
  }

  @override
  Future<void> ensureCards(
    Iterable<String> cardIds, {
    required DateTime now,
    required CardOrigin origin,
  }) async {
    final at = now.toUtc();
    await _db.batch((b) {
      for (final id in cardIds.toSet()) {
        b.insert(
          _db.userCards,
          UserCardsCompanion.insert(
            cardId: id,
            lang: lang,
            box: 0,
            createdAt: at,
            origin: origin.code,
            updatedAt: at,
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
  }

  @override
  Future<bool> recordReview(ReviewRecord r) => _db.transaction(() async {
    final existing = await (_db.select(
      _db.reviewLog,
    )..where((t) => t.id.equals(r.id))).getSingleOrNull();
    if (existing != null) return false;
    // The primary key on review_log.id guards duplicates at database level;
    // the check above turns a repeated call into a quiet no-op.
    await _db
        .into(_db.reviewLog)
        .insert(
          ReviewLogCompanion.insert(
            id: r.id,
            cardId: r.cardId,
            createdAt: r.createdAt.toUtc(),
            mode: r.mode.code,
            sentenceId: r.sentenceId,
            firstAttemptCorrect: r.firstAttemptCorrect,
            errorCount: r.errorCount,
            revealed: r.revealed,
            hintUsed: Value(r.hintUsed),
            boxBefore: r.boxBefore,
            boxAfter: r.boxAfter,
            dueAtAfter: r.dueAtAfter.toUtc(),
            responseMs: Value(r.responseMs),
            appVersion: r.appVersion,
            deviceId: r.deviceId,
          ),
        );
    final card = await (_db.select(
      _db.userCards,
    )..where((t) => t.cardId.equals(r.cardId))).getSingleOrNull();
    if (card == null) {
      throw StateError(
        'card ${r.cardId} has no user_cards row; '
        'ensureCards must run at its first display',
      );
    }
    if (card.box != r.boxBefore) {
      throw StateError(
        'card ${r.cardId} is in box ${card.box}, the review '
        'expects box ${r.boxBefore}',
      );
    }
    await (_db.update(
      _db.userCards,
    )..where((t) => t.cardId.equals(r.cardId))).write(
      UserCardsCompanion(
        box: Value(r.boxAfter),
        dueAt: Value(r.dueAtAfter.toUtc()),
        updatedAt: Value(r.createdAt.toUtc()),
      ),
    );
    return true;
  });

  @override
  Future<Map<String, int>> reviewCounts(Iterable<String> cardIds) async {
    final out = <String, int>{};
    final count = _db.reviewLog.id.count();
    for (final chunk in _chunks(cardIds)) {
      final query = _db.selectOnly(_db.reviewLog)
        ..addColumns([_db.reviewLog.cardId, count])
        ..where(_db.reviewLog.cardId.isIn(chunk))
        ..groupBy([_db.reviewLog.cardId]);
      for (final row in await query.get()) {
        out[row.read(_db.reviewLog.cardId)!] = row.read(count)!;
      }
    }
    return out;
  }

  @override
  Future<List<ReviewRecord>> reviewsFor(String cardId) async {
    final rows =
        await (_db.select(_db.reviewLog)
              ..where((t) => t.cardId.equals(cardId))
              ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
            .get();
    return [
      for (final r in rows)
        ReviewRecord(
          id: r.id,
          cardId: r.cardId,
          createdAt: r.createdAt.toUtc(),
          mode: ReviewMode.fromCode(r.mode),
          sentenceId: r.sentenceId,
          firstAttemptCorrect: r.firstAttemptCorrect,
          errorCount: r.errorCount,
          revealed: r.revealed,
          hintUsed: r.hintUsed,
          boxBefore: r.boxBefore,
          boxAfter: r.boxAfter,
          dueAtAfter: r.dueAtAfter.toLocal(),
          responseMs: r.responseMs,
          appVersion: r.appVersion,
          deviceId: r.deviceId,
        ),
    ];
  }

  @override
  Future<Set<String>> activeDeckIds(Iterable<String> deckIds) async {
    final ids = deckIds.toSet();
    final off = await (_db.select(
      _db.deckSettings,
    )..where((t) => t.deckId.isIn(ids) & t.active.equals(false))).get();
    return ids.difference({for (final r in off) r.deckId});
  }

  @override
  Future<void> setDeckActive(
    String deckId,
    bool active, {
    required DateTime now,
  }) => _db
      .into(_db.deckSettings)
      .insertOnConflictUpdate(
        DeckSettingsCompanion.insert(
          deckId: deckId,
          active: active,
          updatedAt: now.toUtc(),
        ),
      );

  @override
  Future<String> deviceId() => _db.transaction(() async {
    final row = await (_db.select(
      _db.settings,
    )..where((t) => t.id.equals(1))).getSingleOrNull();
    if (row != null) return row.deviceId;
    final id = randomUuidV4();
    await _db
        .into(_db.settings)
        .insert(
          SettingsCompanion.insert(
            id: const Value(1),
            deviceId: id,
            targetLang: lang,
            updatedAt: DateTime.now().toUtc(),
          ),
        );
    return id;
  });

  @override
  Stream<void> changes() => _db
      .tableUpdates(
        TableUpdateQuery.onAllTables([
          _db.userCards,
          _db.reviewLog,
          _db.deckSettings,
          _db.settings,
        ]),
      )
      .map((_) {});

  @override
  Future<void> close() => _db.close();

  @override
  Future<PracticePreferences> preferences() async {
    await deviceId();
    final r = await _db.select(_db.settings).getSingle();
    return PracticePreferences(
      motif: AppMotif.values.byName(r.motif),
      dailyGoal: r.dailyGoal,
      includeDiacritics: r.includeDiacritics,
      autoNext: r.autoNext,
      showGrammar: r.showGrammar,
    );
  }

  @override
  Future<void> savePreferences(PracticePreferences value) async {
    await deviceId();
    await (_db.update(_db.settings)..where((t) => t.id.equals(1))).write(
      SettingsCompanion(
        motif: Value(value.motif.name),
        dailyGoal: Value(value.dailyGoal),
        includeDiacritics: Value(value.includeDiacritics),
        autoNext: Value(value.autoNext),
        showGrammar: Value(value.showGrammar),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  @override
  Future<void> setCardFlags(
    String cardId, {
    bool? favorite,
    bool? disabled,
    bool? inPlaylist,
    String? note,
  }) async {
    final changed =
        await (_db.update(
          _db.userCards,
        )..where((t) => t.cardId.equals(cardId))).write(
          UserCardsCompanion(
            favorite: favorite == null ? const Value.absent() : Value(favorite),
            inPlaylist: inPlaylist == null
                ? const Value.absent()
                : Value(inPlaylist),
            note: note == null ? const Value.absent() : Value(note),
            disabled: disabled == null ? const Value.absent() : Value(disabled),
            updatedAt: Value(DateTime.now().toUtc()),
          ),
        );
    if (changed != 1) throw StateError('Karte nicht vorhanden');
  }

  @override
  Future<void> saveSubmission(LocalSubmission s) async {
    if (s.text.characters.length > 2000 ||
        (s.rating != null && (s.rating! < 1 || s.rating! > 5)) ||
        (s.category == null && s.rating == null)) {
      throw ArgumentError('Ungültiger Bericht');
    }
    await _db
        .into(_db.localSubmissions)
        .insert(
          LocalSubmissionsCompanion.insert(
            id: s.id,
            createdAt: s.createdAt.toUtc(),
            body: s.text,
            category: Value(s.category),
            rating: Value(s.rating),
            cardId: Value(s.cardId),
            sentenceId: Value(s.sentenceId),
            packVersion: Value(s.packVersion),
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  @override
  Future<List<LocalSubmission>> submissions() async => [
    for (final s in await (_db.select(
      _db.localSubmissions,
    )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get())
      LocalSubmission(
        id: s.id,
        createdAt: s.createdAt,
        text: s.body,
        category: s.category,
        rating: s.rating,
        cardId: s.cardId,
        sentenceId: s.sentenceId,
        packVersion: s.packVersion,
      ),
  ];
}
