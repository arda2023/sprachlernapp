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
  Map<String, ContentCard> contentCards = const {},
  Set<String> explicitStoryIds = const {},
  required Set<String> activeDeckCardIds,
  required Map<String, UserCardState> cards,
  required Set<String> knownCardIds,
  required DateTime now,
}) {
  final eligibleNew = contentCards.isEmpty
      ? null
      : LearningGroups(contentCards, cards).project([
          ...activeDeckCardIds,
          for (final s in cards.values)
            if (s.box == 0 &&
                (s.origin == CardOrigin.story ||
                    explicitStoryIds.contains(s.cardId)))
              s.cardId,
        ]).toSet();
  var unseen = (eligibleNew ?? activeDeckCardIds)
      .where((id) => !cards.containsKey(id))
      .length;
  var due = 0, building = 0, mastered = 0;
  for (final card in cards.values) {
    if (!card.isActive) continue;
    if (!knownCardIds.contains(card.cardId)) continue;
    if (card.box == 0) {
      if (eligibleNew?.contains(card.cardId) ??
          (activeDeckCardIds.contains(card.cardId) ||
              card.origin == CardOrigin.story ||
              explicitStoryIds.contains(card.cardId))) {
        unseen++;
      }
    } else if (card.isDue(now)) {
      due++;
    } else if (card.box == 5) {
      mastered++;
    } else {
      building++;
    }
  }
  return VocabBreakdown(
    due: due,
    building: building,
    mastered: mastered,
    unseen: unseen,
  );
}

/// The two deck sessions (PRODUCT.md, Practice Modes).
enum DeckSessionKind {
  /// Lerne mit diesem Stapel: due cards of the deck, then new ones.
  learn(ReviewMode.deck),

  /// Stapel-Revue: seen cards of the deck only, early practice rule.
  revue(ReviewMode.revue),
  mixed(ReviewMode.mixed);

  const DeckSessionKind(this.mode);

  final ReviewMode mode;
}

/// One place in a session queue. A [repeat] is the in-session repeat of a
/// card: it is practised again but never logged and never changes the box.
class SessionEntry {
  const SessionEntry(this.cardId, {this.repeat = false, this.mode});

  final String cardId;
  final bool repeat;
  final ReviewMode? mode;

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

/// Queue of a deck session (docs/srs.md, Queue je Modus). [deckCardIds] in
/// deck order. Learn: due cards (oldest due first), then new cards (no row
/// or box 0) through the shared diverse selector. Revue: seen cards (box ≥ 1), soonest due first.
/// Disabled and retired cards never appear. At most [size] entries.
List<SessionEntry> buildDeckQueue({
  required List<String> deckCardIds,
  required Map<String, ContentCard> cards,
  required Map<String, UserCardState> states,
  required DeckSessionKind kind,
  required DateTime now,
  int size = 5,
}) {
  final order = <String, int>{};
  for (final id in LearningGroups(cards, states).project(deckCardIds)) {
    order.putIfAbsent(id, () => order.length);
  }
  final ids = order.keys.where((id) => states[id]?.isActive ?? true).toList();
  int byDue(String a, String b) {
    final da = states[a]!.dueAt, db = states[b]!.dueAt;
    final c = (da == null || db == null)
        ? (da == null ? (db == null ? 0 : -1) : 1)
        : da.compareTo(db);
    return c != 0 ? c : order[a]!.compareTo(order[b]!);
  }

  final seen = ids.where((id) => (states[id]?.box ?? 0) >= 1).toList()
    ..sort(byDue);
  final List<String> picked;
  switch (kind) {
    case DeckSessionKind.learn:
      final fresh = ids.where((id) => (states[id]?.box ?? 0) == 0);
      final due = seen.where((id) => states[id]!.isDue(now)).toList();
      final newIds = selectNewCards(
        candidates: [for (final id in fresh) cards[id]!],
        knownLemmas: {
          for (final id in states.keys)
            if (cards[id] case final card?) selectionLemma(card),
        },
        limit: size - due.length,
      );
      picked = [...due, ...newIds];
    case DeckSessionKind.revue:
      picked = seen;
    case DeckSessionKind.mixed:
      throw ArgumentError('Use buildMixedQueue for all-source sessions');
  }
  return [for (final id in picked.take(size)) SessionEntry(id)];
}

/// Mixed uses only resolvable, connected content. Seen cards remain eligible
/// independently of deck activation; activation gates only new deck cards.
List<SessionEntry> buildMixedQueue({
  Map<String, DateTime> storyAdditions = const {},
  required List<String> activeDeckCardIds,
  required Map<String, ContentCard> cards,
  required Map<String, UserCardState> states,
  required DateTime now,
  int size = 10,
}) {
  final eligible = states.values
      .where((s) => s.isActive && cards.containsKey(s.cardId))
      .toList();
  int dueOrder(UserCardState a, UserCardState b) {
    final d = (a.dueAt ?? DateTime(1970)).compareTo(b.dueAt ?? DateTime(1970));
    return d != 0 ? d : a.cardId.compareTo(b.cardId);
  }

  final due = eligible.where((s) => s.isDue(now)).toList()..sort(dueOrder);
  final storyNew =
      eligible
          .where(
            (s) =>
                s.box == 0 &&
                (storyAdditions.containsKey(s.cardId) ||
                    s.origin == CardOrigin.story),
          )
          .toList()
        ..sort((a, b) {
          final d = (storyAdditions[a.cardId] ?? a.createdAt ?? DateTime(1970))
              .compareTo(
                storyAdditions[b.cardId] ?? b.createdAt ?? DateTime(1970),
              );
          return d != 0 ? d : a.cardId.compareTo(b.cardId);
        });
  final freshIds = LearningGroups(
    cards,
    states,
  ).project([...storyNew.map((s) => s.cardId), ...activeDeckCardIds]);
  final fresh = selectNewCards(
    priorityIds: storyNew.map((s) => s.cardId).toSet(),
    candidates: [
      for (final id in freshIds)
        if ((states[id]?.isActive ?? true) && (states[id]?.box ?? 0) == 0)
          cards[id]!,
    ],
    knownLemmas: {
      for (final id in states.keys)
        if (cards[id] case final c?) selectionLemma(c),
    },
    limit: size - due.length,
  );
  final early = eligible.where((s) => s.box >= 1 && !s.isDue(now)).toList()
    ..sort(dueOrder);
  return [
    for (final s in due) SessionEntry(s.cardId, mode: ReviewMode.mixed),
    for (final id in fresh) SessionEntry(id, mode: ReviewMode.mixed),
    for (final s in early) SessionEntry(s.cardId, mode: ReviewMode.early),
  ].take(size).toList();
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
