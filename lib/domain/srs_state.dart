import 'content.dart';
import 'learning_groups.dart';
import 'new_card_selection.dart';
// Pure Dart: no Flutter imports (see CLAUDE.md, domain layer).

import 'dart:math';

/// Where a card came from (`user_cards.origin`).
enum CardOrigin {
  deck('deck'),
  story('story');

  const CardOrigin(this.code);

  final String code;

  static CardOrigin fromCode(String code) =>
      values.firstWhere((o) => o.code == code);
}

/// Practice mode of a pass (`review_log.mode`, docs/srs.md).
enum ReviewMode {
  /// Gemischt.
  mixed('mixed'),

  /// Lerne mit diesem Stapel.
  deck('deck'),

  /// Stapel-Revue (early practice rule).
  revue('revue'),

  /// Vorab-Üben inside Gemischt (early practice rule).
  early('early');

  const ReviewMode(this.code);

  final String code;

  /// Revue and Vorab-Üben: a clean answer keeps box and due date.
  bool get isEarlyPractice => this == revue || this == early;

  static ReviewMode fromCode(String code) =>
      values.firstWhere((m) => m.code == code);
}

/// Learning state of one card (`user_cards`). [dueAt] is null only in box 0.
class UserCardState {
  const UserCardState({
    required this.cardId,
    required this.box,
    required this.dueAt,
    this.disabled = false,
    this.favorite = false,
    this.note = '',
    this.inPlaylist = false,
    this.retired = false,
    this.localOnly = false,
    this.origin = CardOrigin.deck,
    this.createdAt,
  }) : assert(box >= 0 && box <= 5);

  final String cardId;
  final int box;
  final DateTime? dueAt;
  final bool disabled;
  final bool favorite;
  final String note;
  final bool inPlaylist;
  final bool retired;

  /// A card without a content row (`u:` id); counted although unknown to the
  /// content pack.
  final bool localOnly;
  final CardOrigin origin;
  final DateTime? createdAt;

  /// In queues and counters at all (docs/srs.md: disabled and retired cards
  /// never count).
  bool get isActive => !disabled && !retired;

  bool isDue(DateTime now) =>
      box >= 1 && (dueAt == null || !dueAt!.isAfter(now));
}

/// One `review_log` row (docs/srs.md): the complete record of the first pass
/// of a card in a session. [id] is the pass id; storing the same id twice
/// is a no-op.
class ReviewRecord {
  const ReviewRecord({
    required this.id,
    required this.cardId,
    required this.createdAt,
    required this.mode,
    required this.sentenceId,
    required this.firstAttemptCorrect,
    required this.errorCount,
    required this.revealed,
    required this.hintUsed,
    required this.boxBefore,
    required this.boxAfter,
    required this.dueAtAfter,
    required this.responseMs,
    required this.appVersion,
    required this.deviceId,
  }) : assert(errorCount >= 0),
       assert(boxBefore >= 0 && boxBefore <= 5),
       assert(boxAfter >= 1 && boxAfter <= 5);

  final String id;
  final String cardId;

  /// UTC.
  final DateTime createdAt;
  final ReviewMode mode;
  final String sentenceId;
  final bool firstAttemptCorrect;
  final int errorCount;
  final bool revealed;
  final bool hintUsed;
  final int boxBefore;
  final int boxAfter;
  final DateTime dueAtAfter;
  final int? responseMs;
  final String appVersion;
  final String deviceId;
}

/// The four Lingvist categories (PRODUCT.md). Disjoint by construction, so
/// [total] always equals their sum. Derived from card state and due dates
/// ([deriveVocabBreakdown]); never persisted.
class VocabBreakdown {
  const VocabBreakdown({
    required this.due,
    required this.building,
    required this.mastered,
    required this.unseen,
  }) : assert(due >= 0 && building >= 0 && mastered >= 0 && unseen >= 0);

  /// Verfügbare Wiederholungen: seen words whose due date has passed.
  final int due;

  /// Wörter im Aufbau: box 1–4, not yet due.
  final int building;

  /// Wörter gemeistert: box 5, not yet due.
  final int mastered;

  /// Noch nicht angezeigt: never shown to the learner.
  final int unseen;

  int get total => due + building + mastered + unseen;
}

/// The four counters (docs/srs.md, Abgeleitete Zähler). [activeDeckCardIds]:
/// distinct card ids of the active decks. [cards]: learner state by card id.
/// [knownCardIds]: all cards of the current content pack; learner rows of
/// other ids (e.g. an old VERB card) are kept in user.db but count nowhere,
/// local-only cards always count.
VocabBreakdown deriveVocabBreakdown({
  bool targetsResolved = false,
  Map<String, ContentCard> contentCards = const {},
  Set<String> explicitStoryIds = const {},
  required Set<String> activeDeckCardIds,
  required Map<String, UserCardState> cards,
  required Set<String> knownCardIds,
  required DateTime now,
}) {
  final ids = eligiblePracticeIds(activeDeckCardIds: activeDeckCardIds,
    states: cards, contentCards: contentCards, knownCardIds: knownCardIds,
    explicitStoryIds: explicitStoryIds, targetsResolved: targetsResolved);
  var due = 0, building = 0, mastered = 0, unseen = 0;
  for (final id in ids) {
    final card = cards[id];
    if (card == null || card.box == 0) { unseen++; }
    else if (card.isDue(now)) { due++; }
    else if (card.box == 5) { mastered++; }
    else { building++; }
  }
  return VocabBreakdown(due: due, building: building, mastered: mastered, unseen: unseen);
}

/// One eligible exercise inventory for state counters and lexical counts.
Set<String> eligiblePracticeIds({
  required Set<String> activeDeckCardIds,
  required Map<String, UserCardState> states,
  required Set<String> knownCardIds,
  Map<String, ContentCard> contentCards = const {},
  Set<String> explicitStoryIds = const {},
  bool targetsResolved = false,
}) {
  final story = [for (final s in states.values)
    if (s.box == 0 && (s.origin == CardOrigin.story || explicitStoryIds.contains(s.cardId))) s.cardId];
  final groups = LearningGroups(contentCards, states);
  final newIds = contentCards.isEmpty ? {...activeDeckCardIds, ...story}
      : targetsResolved ? {...activeDeckCardIds, ...groups.project(story, exactForms: true)}
      : groups.project([...activeDeckCardIds, ...story], exactForms: true).toSet();
  return {for (final id in {...newIds, ...states.values.where((s) => s.box >= 1).map((s) => s.cardId)})
    if ((knownCardIds.contains(id) || (!states.containsKey(id) && newIds.contains(id))) && (states[id]?.isActive ?? true)) id};
}

class LexicalBreakdown {
  const LexicalBreakdown({required this.total, required this.practiced});
  final int total, practiced;
}

LexicalBreakdown deriveLexicalBreakdown(Set<String> eligibleIds,
    Map<String, ContentCard> cards, Map<String, UserCardState> states) {
  final total = <String>{}, practiced = <String>{};
  final keys = lexicalCountingKeys(cards);
  for (final id in eligibleIds) {
    final c = cards[id];
    if (c == null) continue;
    total.add(keys[id]!);
    if ((states[id]?.box ?? 0) >= 1) practiced.add(keys[id]!);
  }
  return LexicalBreakdown(total: total.length, practiced: practiced.length);
}

/// Session kinds (PRODUCT.md, Practice Modes).
enum DeckSessionKind {
  /// Lerne mit diesem Stapel: due cards of the deck, then new ones.
  learn(ReviewMode.deck),

  /// Stapel-Revue: seen cards of the deck only, early practice rule.
  revue(ReviewMode.revue),
  mixed(ReviewMode.mixed),

  /// Vorab üben, chosen explicitly: seen, not yet due cards of a scope.
  early(ReviewMode.early);

  const DeckSessionKind(this.mode);

  final ReviewMode mode;
}

/// One place in a session queue. A [repeat] is the in-session repeat of a
/// card: it is practised again but never logged and never changes the box.
class SessionEntry {
  const SessionEntry(this.cardId, {this.repeat = false, this.mode, this.source});

  final String cardId;
  final bool repeat;
  final ReviewMode? mode;

  /// New-word source whose turn this entry used; null for reviews.
  final String? source;

  @override
  bool operator ==(Object other) =>
      other is SessionEntry &&
      other.cardId == cardId &&
      other.repeat == repeat &&
      other.mode == mode;

  @override
  int get hashCode => Object.hash(cardId, repeat, mode);

  @override
  String toString() =>
      repeat ? 'SessionEntry($cardId, repeat)' : 'SessionEntry($cardId)';
}

/// "Aus Storys" as a source of new targets in mixed practice.
const storySourceId = 'story';

/// One source of new targets: an active deck or [storySourceId]. [cardIds]
/// keep the source's own order (deck content order, story add date).
class NewWordSource {
  const NewWordSource(this.id, this.cardIds);
  final String id;
  final List<String> cardIds;
}

/// A selected new target and the source whose turn it filled.
typedef NewTarget = ({String cardId, String source});

/// Fair new targets (docs/srs.md, Neue Wörter): sources take turns, starting
/// with the first source after [lastSource] in [order] (all deck ids in
/// catalog order, then [storySourceId]), so short sessions continue the
/// rotation. Empty or exhausted sources are skipped; each keeps its order.
/// A target listed by several sources is offered once, by the first of them
/// in [order]. Only admissible targets take a turn: new (no row or box 0),
/// active, resolvable, and per session one per learning group, lemma and
/// surface form.
List<NewTarget> selectNewTargets({
  required List<NewWordSource> sources,
  required Map<String, ContentCard> cards,
  required Map<String, UserCardState> states,
  required int limit,
  List<String> order = const [],
  String? lastSource,
}) {
  if (limit <= 0) return [];
  int rank(String id) {
    final i = order.indexOf(id);
    return i < 0 ? order.length : i;
  }

  final ranked = [...sources]
    ..sort((a, b) {
      final r = rank(a.id).compareTo(rank(b.id));
      return r != 0 ? r : sources.indexOf(a).compareTo(sources.indexOf(b));
    });
  final owner = <String, String>{};
  for (final source in ranked) {
    for (final id in source.cardIds) {
      owner.putIfAbsent(id, () => source.id);
    }
  }
  final queues = [
    for (final source in ranked)
      (
        id: source.id,
        ids: [
          for (final id in source.cardIds)
            if (owner[id] == source.id &&
                cards.containsKey(id) &&
                (states[id]?.isActive ?? true) &&
                (states[id]?.box ?? 0) == 0)
              id,
        ],
      ),
  ];
  if (queues.isEmpty) return [];
  final last = lastSource == null ? -1 : order.indexOf(lastSource);
  var turn = last < 0 ? 0 : queues.indexWhere((q) => rank(q.id) > last);
  if (turn < 0) turn = 0;
  final cursor = List.filled(queues.length, 0);
  final groups = <String>{}, lemmas = <String>{}, surfaces = <String>{};
  final picked = <NewTarget>[];
  var idle = 0;
  while (picked.length < limit && idle < queues.length) {
    final q = queues[turn];
    String? chosen;
    while (cursor[turn] < q.ids.length && chosen == null) {
      final card = cards[q.ids[cursor[turn]++]]!;
      if (groups.contains(card.introductionKey) ||
          lemmas.contains(selectionLemma(card)) ||
          surfaces.contains(card.formNorm)) {
        continue;
      }
      chosen = card.id;
      groups.add(card.introductionKey);
      lemmas.add(selectionLemma(card));
      surfaces.add(card.formNorm);
    }
    if (chosen == null) {
      idle++;
    } else {
      idle = 0;
      picked.add((cardId: chosen, source: q.id));
    }
    turn = (turn + 1) % queues.length;
  }
  return picked;
}

/// The one rule for learning sessions (docs/srs.md, Queue je Modus): due
/// reviews among [reviewIds] first, longest overdue first, then new
/// targets from [sources] while seats remain. Due reviews are never
/// displaced and no not-yet-due card fills the session.
List<SessionEntry> buildPracticeQueue({
  required List<String> reviewIds,
  required List<NewWordSource> sources,
  required Map<String, ContentCard> cards,
  required Map<String, UserCardState> states,
  required DateTime now,
  required int size,
  required ReviewMode mode,
  List<String> order = const [],
  String? lastSource,
}) {
  final position = <String, int>{};
  for (final id in reviewIds) {
    position.putIfAbsent(id, () => position.length);
  }
  final due = [
    for (final id in position.keys)
      if (cards.containsKey(id) &&
          (states[id]?.isActive ?? false) &&
          states[id]!.isDue(now))
        id,
  ]..sort((a, b) {
      final d = states[a]!.dueAt == null || states[b]!.dueAt == null
          ? 0
          : states[a]!.dueAt!.compareTo(states[b]!.dueAt!);
      return d != 0 ? d : position[a]!.compareTo(position[b]!);
    });
  final fresh = selectNewTargets(
    sources: sources,
    cards: cards,
    states: states,
    limit: size - due.length,
    order: order,
    lastSource: lastSource,
  );
  return [
    for (final id in due) SessionEntry(id, mode: mode),
    for (final t in fresh) SessionEntry(t.cardId, mode: mode, source: t.source),
  ].take(size < 0 ? 0 : size).toList();
}

/// Vorab üben, only when chosen: seen cards of [scopeIds] that are not due
/// yet, soonest due first, under the early practice rule.
List<SessionEntry> buildEarlyQueue({
  required List<String> scopeIds,
  required Map<String, ContentCard> cards,
  required Map<String, UserCardState> states,
  required DateTime now,
  required int size,
  ReviewMode mode = ReviewMode.early,
}) {
  final ids = {
    for (final id in scopeIds)
      if (cards.containsKey(id) &&
          (states[id]?.isActive ?? false) &&
          states[id]!.box >= 1)
        id,
  }.toList();
  final order = {for (final (i, id) in ids.indexed) id: i};
  final picked = (mode == ReviewMode.early
      ? ids.where((id) => !states[id]!.isDue(now)).toList()
      : ids)
    ..sort((a, b) {
      final da = states[a]!.dueAt, db = states[b]!.dueAt;
      final c = da == null || db == null
          ? (da == null ? (db == null ? 0 : -1) : 1)
          : da.compareTo(db);
      return c != 0 ? c : order[a]!.compareTo(order[b]!);
    });
  return [for (final id in picked.take(size)) SessionEntry(id, mode: mode)];
}

/// Queue of a deck session. [deckCardIds] in deck order. Learn: the shared
/// rule with this deck as the only source. Revue: seen cards, soonest due
/// first. Disabled and retired cards never appear. At most [size] entries.
List<SessionEntry> buildDeckQueue({
  bool targetsResolved = false,
  required List<String> deckCardIds,
  required Map<String, ContentCard> cards,
  required Map<String, UserCardState> states,
  required DeckSessionKind kind,
  required DateTime now,
  int size = 5,
}) {
  final ids = targetsResolved
      ? deckCardIds
      : LearningGroups(cards, states).project(deckCardIds, exactForms: true);
  return switch (kind) {
    DeckSessionKind.learn => buildPracticeQueue(
        reviewIds: ids,
        sources: [NewWordSource('deck', ids)],
        cards: cards,
        states: states,
        now: now,
        size: size,
        mode: ReviewMode.deck,
      ),
    DeckSessionKind.revue => buildEarlyQueue(scopeIds: ids, cards: cards,
        states: states, now: now, size: size, mode: ReviewMode.revue),
    DeckSessionKind.early => buildEarlyQueue(scopeIds: ids, cards: cards,
        states: states, now: now, size: size),
    DeckSessionKind.mixed =>
      throw ArgumentError('Use buildMixedQueue for all-source sessions'),
  };
}

/// Mixed: due cards of every origin (deck activation never hides seen
/// cards), then new targets taking turns between [deckSources] (active
/// decks) and "Aus Storys" (explicit story additions, oldest first).
/// Without [deckSources], [activeDeckCardIds] form one deck source.
List<SessionEntry> buildMixedQueue({
  bool targetsResolved = false,
  Map<String, DateTime> storyAdditions = const {},
  required List<String> activeDeckCardIds,
  List<NewWordSource>? deckSources,
  List<String> sourceOrder = const [],
  String? lastSource,
  required Map<String, ContentCard> cards,
  required Map<String, UserCardState> states,
  required DateTime now,
  int size = 10,
}) {
  final groups = LearningGroups(cards, states);
  final storyNew = states.values
      .where((s) =>
          s.isActive &&
          s.box == 0 &&
          (storyAdditions.containsKey(s.cardId) || s.origin == CardOrigin.story))
      .toList()
    ..sort((a, b) {
      final d = (storyAdditions[a.cardId] ?? a.createdAt ?? DateTime(1970))
          .compareTo(storyAdditions[b.cardId] ?? b.createdAt ?? DateTime(1970));
      return d != 0 ? d : a.cardId.compareTo(b.cardId);
    });
  final story = groups.project(storyNew.map((s) => s.cardId), exactForms: true);
  final decks = deckSources ??
      [
        NewWordSource(
          'decks',
          targetsResolved
              ? activeDeckCardIds
              : groups.project(activeDeckCardIds, exactForms: true),
        ),
      ];
  final reviewIds = states.keys.toList()..sort();
  return buildPracticeQueue(
    reviewIds: reviewIds,
    sources: [...decks, NewWordSource(storySourceId, story)],
    cards: cards,
    states: states,
    now: now,
    size: size,
    mode: ReviewMode.mixed,
    order: sourceOrder.isNotEmpty
        ? sourceOrder
        : [...decks.map((d) => d.id), storySourceId],
    lastSource: lastSource,
  );
}

/// Cards between a pass and its in-session repeat ("etwa 3 Karten später").
const inSessionRepeatGap = 3;

/// [queue] with the one in-session repeat of the card at [index] (docs/srs.md:
/// after an error or reveal the card returns once). Inserted after
/// [inSessionRepeatGap] further cards, or at the end of a shorter queue.
/// A repeat never schedules another one.
List<SessionEntry> withRepeat(List<SessionEntry> queue, int index) {
  final entry = queue[index];
  if (entry.repeat) return queue;
  final later = queue.skip(index + 1);
  if (later.any((e) => e.repeat && e.cardId == entry.cardId)) return queue;
  final at = min(index + 1 + inSessionRepeatGap, queue.length);
  return [...queue]
    ..insert(at, SessionEntry(entry.cardId, repeat: true, mode: entry.mode));
}

/// Random UUID version 4 (pass ids, device id); no package needed.
String randomUuidV4([Random? random]) {
  final r = random ?? Random.secure();
  final bytes = List<int>.generate(16, (_) => r.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
