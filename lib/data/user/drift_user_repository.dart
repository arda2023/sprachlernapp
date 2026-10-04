import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/content.dart';
import '../../domain/story_learning.dart';

import 'package:characters/characters.dart';

import '../../domain/preferences.dart';

import '../../domain/repositories.dart';
import '../../domain/srs_state.dart';
import 'user_database.dart';

/// [UserRepository] on the Drift user.db of one language.
class DriftUserRepository implements UserRepository, StoryLearningRepository {
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
          _db.cardContexts,
          _db.storyLearningAdditions,
          _db.storyWordSources,
          _db.learningIdentityBindings,
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
  @override
  Future<Map<String, DateTime>> explicitStoryAdditions() async => {
    for (final row in await _db.select(_db.storyLearningAdditions).get())
      row.cardId: row.addedAt.toLocal(),
  };
  @override
  Future<Map<String, String>> identityBindings() async => {
    for (final row in await (_db.select(
      _db.learningIdentityBindings,
    )..where((t) => t.lang.equals(lang))).get())
      row.identityKey: row.cardId,
  };

  @override
  Future<StoryAddResult> storyLearningStatus(StoryLearningCandidate c) async {
    final invalid = c.validationProblem(needsContext: false);
    if (c.lang != lang || invalid != null) {
      return StoryAddResult(
        c.retired ? StoryAddState.retired : StoryAddState.unavailable,
        message: invalid ?? 'Andere Sprache',
      );
    }
    final bound = (await identityBindings())[c.identity.key];
    final states = await cardStates({
      c.identity.localId,
      if (c.card != null) c.card!.id,
      ?bound,
    });
    if (states.length > 1) {
      return const StoryAddResult(
        StoryAddState.conflict,
        message: 'Für diese genaue Bedeutung bestehen mehrere Lernstände. Beide bleiben erhalten; bitte in der Wortliste prüfen.',
      );
    }
    final id =
        bound ??
        (states.isNotEmpty
            ? states.keys.single
            : c.card?.id ?? c.identity.localId);
    final state = states[id];
    if (state?.localOnly == true &&
        !(await localPracticeItems()).any((i) => i.card.id == id)) {
      return StoryAddResult(
        StoryAddState.unavailable,
        cardId: id,
        message: 'Der gespeicherte lokale Übungskontext ist nicht verfügbar. Der Lernstand bleibt erhalten.',
      );
    }
    if (state?.retired == true) {
      return StoryAddResult(
        StoryAddState.retired,
        cardId: id,
        message: 'Diese Karte wurde zurückgezogen.',
      );
    }
    if (state?.disabled == true) {
      return StoryAddResult(StoryAddState.disabled, cardId: id);
    }
    if (state != null &&
        (state.box >= 1 ||
            state.origin == CardOrigin.story ||
            (await explicitStoryAdditions()).containsKey(id))) {
      return StoryAddResult(StoryAddState.added, cardId: id);
    }
    if (c.unavailableReason != null && state == null) {
      return StoryAddResult(
        StoryAddState.unavailable,
        message: c.unavailableReason,
      );
    }
    return StoryAddResult(StoryAddState.available, cardId: id);
  }

  @override
  Future<StoryAddResult> addStoryWord(
    StoryLearningCandidate c, {
    required DateTime now,
  }) => _db.transaction(() async {
    if (c.validationProblem(needsContext: false) case final problem?) {
      throw StateError(problem);
    }
    final status = await storyLearningStatus(c);
    if ([
      StoryAddState.conflict,
      StoryAddState.retired,
      StoryAddState.unavailable,
      StoryAddState.disabled,
    ].contains(status.state)) {
      return status;
    }
    final id = status.cardId!;
    final existing = await (_db.select(
      _db.userCards,
    )..where((t) => t.cardId.equals(id))).getSingleOrNull();
    final local = id.startsWith('u:');
    if (existing == null && local) {
      if (!c.token.contextApproved) {
        throw StateError('Kein geprüfter lokaler Kontext');
      }
      final contextId = randomUuidV4();
      await _db
          .into(_db.userCards)
          .insert(
            UserCardsCompanion.insert(
              cardId: id,
              lang: lang,
              box: 0,
              createdAt: now.toUtc(),
              origin: CardOrigin.story.code,
              updatedAt: now.toUtc(),
              localOnly: const Value(true),
              form: Value(c.token.surface),
              formNorm: Value(c.identity.formNorm),
              glossDe: Value(c.token.gloss),
              lemma: Value(c.token.lemma),
              pos: Value(c.token.pos),
              lemmaIdentity: Value(c.token.lemmaId),
              senseIdentity: Value(c.token.senseId),
              senseKey: Value(c.token.senseKey),
              primaryContextId: Value(contextId),
            ),
          );
      await _db
          .into(_db.cardContexts)
          .insert(
            CardContextsCompanion.insert(
              id: contextId,
              cardId: id,
              textValue: c.sentence.text,
              translationDe: c.sentence.translation,
              gapStart: c.token.start,
              gapEnd: c.token.end,
              sourceRef: c.storyId,
              sentenceRef: c.sentence.id,
              tokenIndex: c.token.index,
              revision: c.revision,
              fingerprint: c.sourceFingerprint,
              lang: lang,
              provenance: 'editorial_chat_reviewed',
              createdAt: now.toUtc(),
              tokensJson: jsonEncode([
                for (final t in c.sentence.tokens)
                  {
                    'start': t.start,
                    'end': t.end,
                    'surface': t.surface,
                    'translation': t.gloss,
                  },
              ]),
              otherFormsJson: jsonEncode(c.otherForms.toList()..sort()),
            ),
          );
    } else if (existing == null) {
      await ensureCards([id], now: now, origin: CardOrigin.story);
    }
    await _db
        .into(_db.learningIdentityBindings)
        .insert(
          LearningIdentityBindingsCompanion.insert(
            identityKey: c.identity.key,
            lang: lang,
            formNorm: c.identity.formNorm,
            semanticAnchor: c.identity.semanticAnchor,
            cardId: id,
          ),
          mode: InsertMode.insertOrIgnore,
        );
    final binding = await (_db.select(
      _db.learningIdentityBindings,
    )..where((t) => t.identityKey.equals(c.identity.key))).getSingle();
    if (binding.cardId != id) {
      throw StateError(
        'Lernidentität wurde parallel anders zugeordnet; bitte erneut öffnen.',
      );
    }
    await _db
        .into(_db.storyLearningAdditions)
        .insert(
          StoryLearningAdditionsCompanion.insert(
            cardId: id,
            addedAt: now.toUtc(),
          ),
          mode: InsertMode.insertOrIgnore,
        );
    await _db
        .into(_db.storyWordSources)
        .insert(
          StoryWordSourcesCompanion.insert(
            cardId: id,
            fingerprint: c.sourceFingerprint,
            sourceRef: c.storyId,
            sentenceRef: c.sentence.id,
            tokenIndex: c.token.index,
            revision: c.revision,
            addedAt: now.toUtc(),
          ),
          mode: InsertMode.insertOrIgnore,
        );
    return StoryAddResult(StoryAddState.added, cardId: id);
  });

  CardSentence _context(CardContextRow row) => CardSentence(
    cardId: row.cardId,
    sentenceId: row.id,
    position: 1,
    text: row.textValue,
    translationDe: row.translationDe,
    gapStart: row.gapStart,
    gapEnd: row.gapEnd,
    tokens: [
      for (final t in jsonDecode(row.tokensJson) as List)
        SentenceToken(
          start: t['start'] as int,
          end: t['end'] as int,
          surface: t['surface'] as String,
          translation: t['translation'] as String?,
        ),
    ],
  );

  @override
  Future<List<PracticeItem>> localPracticeItems() async {
    final result = <PracticeItem>[];
    final rows = await (_db.select(
      _db.userCards,
    )..where((t) => t.localOnly.equals(true) & t.lang.equals(lang))).get();
    for (final r in rows) {
      if ([
        r.form,
        r.formNorm,
        r.glossDe,
        r.lemma,
        r.pos,
        r.lemmaIdentity,
        r.senseIdentity,
        r.primaryContextId,
      ].any((v) => v == null || v.isEmpty)) {
        continue;
      }
      final ctx =
          await (_db.select(_db.cardContexts)..where(
                (t) =>
                    t.id.equals(r.primaryContextId!) &
                    t.cardId.equals(r.cardId),
              ))
              .getSingleOrNull();
      if (ctx == null ||
          ctx.gapStart < 0 ||
          ctx.gapEnd > ctx.textValue.length ||
          ctx.gapStart >= ctx.gapEnd ||
          contentFormNorm(ctx.textValue.substring(ctx.gapStart, ctx.gapEnd)) !=
              r.formNorm) {
        continue;
      }
      result.add(
        PracticeItem(
          card: ContentCard(
            id: r.cardId,
            lang: r.lang,
            form: r.form!,
            formNorm: r.formNorm!,
            lemmaId: r.lemmaIdentity!,
            lemma: r.lemma!,
            pos: r.pos!,
            senseId: r.senseIdentity,
            senseKey: r.senseKey,
            translationDe: r.glossDe,
            formLabelDe: r.pos,
          ),
          sentences: [_context(ctx)],
          otherFormsOfLemma: (jsonDecode(ctx.otherFormsJson) as List)
              .cast<String>()
              .toSet(),
        ),
      );
    }
    return result;
  }

  @override
  Future<CardSentence?> localHistoricalSentence(
    String cardId,
    String contextId,
  ) async {
    final row =
        await (_db.select(_db.cardContexts)
              ..where((t) => t.id.equals(contextId) & t.cardId.equals(cardId)))
            .getSingleOrNull();
    return row == null ? null : _context(row);
  }
}
