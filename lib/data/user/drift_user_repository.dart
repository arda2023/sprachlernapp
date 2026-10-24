import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/content.dart';
import '../../domain/learning_groups.dart';
import '../../domain/story_learning.dart';

import 'package:characters/characters.dart';

import '../../domain/preferences.dart';

import '../../domain/repositories.dart';
import '../../domain/review_activity.dart';
import '../../domain/srs_state.dart';
import 'user_database.dart';

/// [UserRepository] on the Drift user.db of one language.
class DriftUserRepository implements UserRepository, StoryLearningRepository, ReviewActivityRepository, StoryContextCorrectionStore {
  DriftUserRepository(this._db, {required this.lang, this.ownsDatabase = true, this.contentIds});
  final bool ownsDatabase;
  final Future<Set<String>> Function(String kind)? contentIds;

  final UserDatabase _db;
  final String lang;

  /// Returns the requested IDs without a row yet.
  Future<Set<String>> _guardCards(Iterable<String> ids, {bool requireExisting = false}) async {
    final requested = ids.toSet();
    final found = <String>{};
    for (final chunk in _chunks(requested)) {
      final rows = await (_db.select(_db.userCards)..where((t) => t.cardId.isIn(chunk))).get();
      for (final row in rows) {
        if (row.lang != lang) throw StateError('Karte gehört zu einer anderen Sprache.');
        found.add(row.cardId);
      }
    }
    final missing = requested.difference(found);
    if (requireExisting && missing.isNotEmpty) throw StateError('Karte nicht vorhanden.');
    if (contentIds != null && missing.isNotEmpty && !(await contentIds!('cards')).containsAll(missing)) {
      throw StateError('Karte gehört nicht zum gewählten Inhaltsbestand.');
    }
    return missing;
  }

  Future<void> _guardDecks(Iterable<String> ids) async {
    if (contentIds != null && !(await contentIds!('decks')).containsAll(ids)) {
      throw StateError('Stapel gehört nicht zur gewählten Sprache.');
    }
  }

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
    await _guardCards(cardIds);
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
  }) => _db.transaction(() async {
    // Existing rows stay untouched. Skipping the no-op insert also avoids a
    // change event that would re-project every derived view.
    final missing = await _guardCards(cardIds);
    if (missing.isEmpty) return;
    final at = now.toUtc();
    await _db.batch((b) {
      for (final id in missing) {
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
  });

  @override
  Future<bool> recordReview(ReviewRecord r) => _db.transaction(() async {
    await _guardCards([r.cardId], requireExisting: true);
    final existing = await (_db.select(
      _db.reviewLog,
    )..where((t) => t.id.equals(r.id))).getSingleOrNull();
    if (existing != null) {
      await _guardCards([existing.cardId], requireExisting: true);
      if (existing.cardId != r.cardId) throw StateError('Review-ID bereits anders gebunden.');
      return false;
    }
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
    await _guardCards(cardIds);
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
    await _guardCards([cardId]);
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
  Future<List<ReviewActivity>> reviewActivity(DateTime from, DateTime until) async {
    final r = _db.reviewLog;
    final c = _db.userCards;
    final query = _db.select(r).join([innerJoin(c, c.cardId.equalsExp(r.cardId))])
      ..where(c.lang.equals(lang) & r.createdAt.isBiggerOrEqualValue(from.toUtc()) &
          r.createdAt.isSmallerThanValue(until.toUtc()));
    return [for (final row in await query.get())
      ReviewActivity(row.readTable(r).cardId, row.readTable(r).createdAt,
          ReviewMode.fromCode(row.readTable(r).mode))];
  }

  @override
  Future<Map<String, DateTime>> latestReviewTimes() async {
    final r = _db.reviewLog;
    final c = _db.userCards;
    final latest = r.createdAt.max();
    final query = _db.selectOnly(r)
      ..join([innerJoin(c, c.cardId.equalsExp(r.cardId))])
      ..addColumns([r.cardId, latest])
      ..where(c.lang.equals(lang))
      ..groupBy([r.cardId]);
    return {for (final row in await query.get()) row.read(r.cardId)!: row.read(latest)!};
  }

  @override
  Future<Set<String>> activeDeckIds(Iterable<String> deckIds) async {
    await _guardDecks(deckIds);
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
  }) async {
    await _guardDecks([deckId]);
    await _db.into(_db.deckSettings)
      .insertOnConflictUpdate(
        DeckSettingsCompanion.insert(
          deckId: deckId,
          active: active,
          updatedAt: now.toUtc(),
        ),
      );

  }

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
          _db.languageLearningPreferences,
          _db.cardContexts,
          _db.storyLearningAdditions,
          _db.storyWordSources,
          _db.learningIdentityBindings,
          _db.formIdentityBindings,
        ]),
      )
      .map((_) {});

  @override
  Future<void> close() async { if (ownsDatabase) await _db.close(); }

  @override
  Future<PracticePreferences> preferences() async {
    await deviceId();
    final r = await _db.select(_db.settings).getSingle();
    final local = await (_db.select(_db.languageLearningPreferences)..where((t) => t.lang.equals(lang))).getSingleOrNull();
    return PracticePreferences(
      motif: AppMotif.values.byName(r.motif),
      dailyGoal: local?.dailyGoal ?? 10,
      includeDiacritics: local?.includeDiacritics ?? true,
      autoNext: r.autoNext,
      showGrammar: local?.showGrammar ?? false,
    );
  }

  @override
  Future<void> savePreferences(PracticePreferences value) async {
    await deviceId();
    await _db.transaction(() async {
    await _db.into(_db.languageLearningPreferences).insertOnConflictUpdate(LanguageLearningPreferencesCompanion.insert(
      lang: lang, dailyGoal: Value(value.dailyGoal), includeDiacritics: Value(value.includeDiacritics), showGrammar: Value(value.showGrammar)));
    await (_db.update(_db.settings)..where((t) => t.id.equals(1))).write(
      SettingsCompanion(
        motif: Value(value.motif.name),
        autoNext: Value(value.autoNext),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
    });
  }

  @override
  Future<void> setCardFlags(
    String cardId, {
    bool? favorite,
    bool? disabled,
    bool? inPlaylist,
    String? note,
  }) async {
    await _guardCards([cardId], requireExisting: true);
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
    if (s.cardId != null) await _guardCards([s.cardId!]);
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
  Future<Map<String, DateTime>> explicitStoryAdditions() async {
    final rows = await _db.customSelect(
      'SELECT a.card_id, MIN(a.added_at) AS added_at FROM ('
      'SELECT card_id, added_at FROM story_learning_additions UNION ALL '
      'SELECT card_id, added_at FROM story_word_sources) a '
      'JOIN user_cards u ON u.card_id = a.card_id WHERE u.lang = ? GROUP BY a.card_id',
      variables: [Variable(lang)], readsFrom: {_db.storyLearningAdditions, _db.storyWordSources, _db.userCards},
    ).get();
    return {for (final r in rows) r.read<String>('card_id'): r.read<DateTime>('added_at').toLocal()};
  }
  @override
  Future<Map<String, String>> identityBindings() async => {
    for (final row in await (_db.select(
      _db.learningIdentityBindings,
    )..where((t) => t.lang.equals(lang))).get())
      row.identityKey: row.cardId,
    for (final row in await (_db.select(_db.formIdentityBindings)..where((t) => t.lang.equals(lang))).get())
      row.identityKey: row.cardId,
  };

  Future<bool> _hasStoryAddition(String id) async =>
      (await (_db.select(_db.storyLearningAdditions)..where((t) => t.cardId.equals(id))).getSingleOrNull()) != null ||
      (await (_db.select(_db.storyWordSources)..where((t) => t.cardId.equals(id))..limit(1)).getSingleOrNull()) != null;

  @override
  Future<StoryAddResult> storyLearningStatus(StoryLearningCandidate c) async {
    final invalid = c.validationProblem(needsContext: false);
    if (c.lang != lang || invalid != null) {
      return StoryAddResult(
        c.retired ? StoryAddState.retired : StoryAddState.unavailable,
        message: invalid ?? 'Andere Sprache',
      );
    }
    if (c.token.function == null && c.groupMembers.isNotEmpty && c.card?.learning != null) {
      final bindings = await identityBindings();
      final localIds = <String>{
        for (final member in c.groupMembers)
          if (member.senseId != null)
            ...[
              LearningIdentity(lang, member.formNorm, member.senseId!).localId,
              ?bindings[LearningIdentity(lang, member.formNorm, member.senseId!).key],
            ],
      };
      final members = attachLocalLearning(
        c.groupMembers,
        (await _localPracticeItems(ids: localIds)).map((i) => i.card),
      );
      final states = await cardStates(members.keys);
      final selected = LearningGroups(members, states).project([c.card!.id]);
      if (selected.isNotEmpty) {
        // Prefer an active existing member, retaining every other learned row.
        final id = selected.firstWhere(
          (id) => states[id]?.isActive ?? true,
          orElse: () => selected.first,
        );
        final state = states[id];
        if (state?.retired == true) {
          return StoryAddResult(StoryAddState.retired, cardId: id);
        }
        if (state?.disabled == true) {
          return StoryAddResult(StoryAddState.disabled, cardId: id);
        }
        return StoryAddResult(
          state != null &&
                  (state.origin == CardOrigin.story ||
                      await _hasStoryAddition(id))
              ? StoryAddState.added
              : StoryAddState.available,
          cardId: id,
        );
      }
    }
    final bindings = await identityBindings();
    if (c.token.function != null) {
      final oldIdentity = LearningIdentity(c.lang, c.identity.formNorm, c.identity.semanticAnchor);
      final old = bindings[oldIdentity.key] ?? oldIdentity.localId;
      final row = await (_db.select(_db.userCards)..where((t) => t.cardId.equals(old))).getSingleOrNull();
      if (row != null && row.localOnly && old != c.card?.id && row.formFunction == null) {
        return const StoryAddResult(StoryAddState.conflict,
          message: 'Ein älterer Lernstand hat keine belegte Form. Er bleibt erhalten; bitte die Zuordnung klären.');
      }
    }
    final bound = bindings[c.identity.key];
    // A candidate's deterministic local ID is a creation proposal, not a pack
    // reference. Only request its state when a row exists. Bound/pack IDs still
    // go through cardStates and its strict language/content checks unchanged.
    final localRow = await (_db.select(_db.userCards)
      ..where((t) => t.cardId.equals(c.identity.localId))).getSingleOrNull();
    final states = await cardStates({
      if (localRow != null) c.identity.localId,
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
        !(await _localPracticeItems(ids: {id})).any((i) => i.card.id == id)) {
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
        (state.origin == CardOrigin.story ||
            await _hasStoryAddition(id))) {
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
    if (!id.startsWith('u:')) await _guardCards([id]);
    final existing = await (_db.select(
      _db.userCards,
    )..where((t) => t.cardId.equals(id))).getSingleOrNull();
    final local = id.startsWith('u:');
    if (existing == null && local) {
      if (c.validationProblem() != null ||
          (!c.token.contextApproved && c.practiceContext == null)) {
        throw StateError('Kein geprüfter lokaler Kontext');
      }
      final contextId = c.practiceContext == null
          ? randomUuidV4()
          : learningHash(['story-practice-context-v1', id, c.practiceContext!.fingerprint]);
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
              formFunction: Value(c.token.function),
              lexicalTargetId: Value(c.token.lexicalId),
            ),
          );
      await _db
          .into(_db.cardContexts)
          .insert(
            CardContextsCompanion.insert(
              id: contextId,
              cardId: id,
              textValue: c.practiceSentence.text,
              translationDe: c.practiceSentence.translation,
              gapStart: c.practiceToken.start,
              gapEnd: c.practiceToken.end,
              sourceRef: c.storyId,
              sentenceRef: c.sentence.id,
              tokenIndex: c.token.index,
              revision: c.revision,
              fingerprint: c.sourceFingerprint,
              lang: lang,
              provenance: 'editorial_chat_reviewed',
              createdAt: now.toUtc(),
              tokensJson: jsonEncode([
                for (final t in c.practiceSentence.tokens)
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
    // A group redirect is not an exact spelling/sense identity binding.
    if (c.token.function != null) {
      await _db.into(_db.formIdentityBindings).insert(
        FormIdentityBindingsCompanion.insert(identityKey: c.identity.key, lang: lang,
          formNorm: c.identity.formNorm, semanticAnchor: c.identity.semanticAnchor,
          function: c.token.function!, cardId: id), mode: InsertMode.insertOrIgnore);
      final binding = await (_db.select(_db.formIdentityBindings)..where((t) => t.identityKey.equals(c.identity.key))).getSingle();
      if (binding.cardId != id) throw StateError('Form wurde parallel anders zugeordnet; bitte erneut öffnen.');
    } else if (c.groupMembers.isEmpty ||
        id == c.card?.id ||
        id == c.identity.localId) {
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

  @override
  Future<void> applyStoryContextCorrections(List<StoryContextCorrection> corrections) async {
    if (corrections.isEmpty) return;
    await _db.transaction(() async {
      for (final correction in corrections) {
        final old = correction.previous, next = correction.current;
        if (correction.version.isEmpty || old.lang != lang ||
            old.card != null || next.card != null ||
            old.validationProblem() != null || next.validationProblem() != null ||
            old.practiceContext == null || next.practiceContext == null ||
            old.identity.key != next.identity.key || old.storyId != next.storyId ||
            old.sentence.id != next.sentence.id || old.token.index != next.token.index) {
          continue;
        }
        final id = old.identity.localId;
        final oldId = learningHash(['story-practice-context-v1', id, old.practiceContext!.fingerprint]);
        final newId = learningHash(['story-practice-context-v1', id, next.practiceContext!.fingerprint]);
        if (oldId == newId) continue;
        final card = await (_db.select(_db.userCards)..where((t) => t.cardId.equals(id))).getSingleOrNull();
        if (card == null || !card.localOnly || card.lang != lang || card.retired ||
            card.primaryContextId != oldId || card.formNorm != old.identity.formNorm ||
            card.senseIdentity != old.identity.semanticAnchor || card.formFunction != old.token.function) {
          continue;
        }
        final context = await (_db.select(_db.cardContexts)..where((t) => t.id.equals(oldId))).getSingleOrNull();
        String tokens(StoryLearningCandidate c) => jsonEncode([
          for (final t in c.practiceSentence.tokens)
            {'start':t.start, 'end':t.end, 'surface':t.surface, 'translation':t.gloss},
        ]);
        if (context == null || context.cardId != id || context.lang != lang ||
            context.sourceRef != old.storyId || context.sentenceRef != old.sentence.id ||
            context.tokenIndex != old.token.index || context.revision != old.revision ||
            context.fingerprint != old.sourceFingerprint ||
            context.provenance != 'editorial_chat_reviewed' ||
            context.textValue != old.practiceSentence.text ||
            context.translationDe != old.practiceSentence.translation ||
            context.gapStart != old.practiceToken.start || context.gapEnd != old.practiceToken.end ||
            context.tokensJson != tokens(old)) {
          continue;
        }
        final origin = await (_db.select(_db.storyWordSources)..where((t) =>
          t.cardId.equals(id) & t.fingerprint.equals(old.sourceFingerprint))).getSingleOrNull();
        if (origin == null || origin.sourceRef != old.storyId ||
            origin.sentenceRef != old.sentence.id || origin.tokenIndex != old.token.index ||
            origin.revision != old.revision) {
          continue;
        }
        await _db.into(_db.cardContexts).insert(CardContextsCompanion.insert(
          id: newId, cardId: id, textValue: next.practiceSentence.text,
          translationDe: next.practiceSentence.translation,
          gapStart: next.practiceToken.start, gapEnd: next.practiceToken.end,
          sourceRef: next.storyId, sentenceRef: next.sentence.id, tokenIndex: next.token.index,
          revision: next.revision, fingerprint: next.sourceFingerprint, lang: lang,
          provenance: 'editorial_chat_reviewed', createdAt: DateTime.now().toUtc(),
          tokensJson: tokens(next), otherFormsJson: context.otherFormsJson));
        await _db.into(_db.storyWordSources).insert(StoryWordSourcesCompanion.insert(
          cardId: id, fingerprint: next.sourceFingerprint, sourceRef: next.storyId,
          sentenceRef: next.sentence.id, tokenIndex: next.token.index,
          revision: next.revision, addedAt: DateTime.now().toUtc()),
          mode: InsertMode.insertOrIgnore);
        // Append-only history stays intact; no SRS/flag/note timestamp is changed.
        await (_db.update(_db.userCards)..where((t) =>
          t.cardId.equals(id) & t.primaryContextId.equals(oldId)))
          .write(UserCardsCompanion(primaryContextId: Value(newId)));
      }
    });
  }

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
  Future<List<PracticeItem>> localPracticeItems() => _localPracticeItems();

  Future<List<PracticeItem>> _localPracticeItems({Set<String>? ids}) async {
    final result = <PracticeItem>[];
    if (ids?.isEmpty == true) return result;
    final query = _db.select(_db.userCards).join([
      innerJoin(_db.cardContexts,
        _db.cardContexts.id.equalsExp(_db.userCards.primaryContextId) &
        _db.cardContexts.cardId.equalsExp(_db.userCards.cardId) &
        _db.cardContexts.lang.equals(lang)),
    ])..where(_db.userCards.localOnly.equals(true) & _db.userCards.lang.equals(lang));
    if (ids != null) query.where(_db.userCards.cardId.isIn(ids));
    for (final row in await query.get()) {
      final r = row.readTable(_db.userCards);
      final ctx = row.readTable(_db.cardContexts);
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
      if (ctx.gapStart < 0 ||
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
            identityFunction: r.formFunction,
            introductionScope: r.formFunction == null ? 'ordinary' : 'form_only',
            lexicalTargetId: r.lexicalTargetId,
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
              ..where((t) => t.id.equals(contextId) & t.cardId.equals(cardId) & t.lang.equals(lang)))
            .getSingleOrNull();
    return row == null ? null : _context(row);
  }
}
