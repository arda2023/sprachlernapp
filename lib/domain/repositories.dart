// Pure Dart: no Flutter imports (see CLAUDE.md, domain layer).

import 'content.dart';
import 'srs_state.dart';
import 'preferences.dart';

/// Read-only access to the content pack of one language. Failures are
/// [ContentUnavailable]; there is no placeholder fallback.
abstract interface class ContentRepository {
  ContentInfo get info;

  /// Decks of the pack, by `sort`.
  Future<List<DeckSummary>> decks();

  /// Raw ownership card ids in deck order (`deck_cards.position`).
  /// Project through LearningGroups for introduction/progress; retain all for reviews.
  Future<List<String>> deckCardIds(String deckId);

  /// Every card id of the pack (to tell learner rows of removed or foreign
  /// cards apart, docs/srs.md counters).
  Future<Set<String>> allCardIds();

  /// Cards with their fixed practice sentence and lemma forms, in the order of
  /// [cardIds]. Unknown ids are an [ArgumentError].
  /// Lightweight metadata for new-card selection, without sentence loading.
  Future<List<ContentCard>> selectionCards(Iterable<String> cardIds);

  Future<List<PracticeItem>> practiceItems(List<String> cardIds);

  /// Read a review sentence even when its card-sentence link is archived.
  Future<CardSentence?> historicalSentence(String cardId, String sentenceId);

  Future<void> close();
}

/// Learner state in user.db: card state, the append-only review log and
/// deck settings. Never stores content texts.
abstract interface class UserRepository {
  Future<PracticePreferences> preferences();
  Future<void> savePreferences(PracticePreferences value);
  Future<void> setCardFlags(
    String cardId, {
    bool? favorite,
    bool? disabled,
    bool? inPlaylist,
    String? note,
  });
  Future<void> saveSubmission(LocalSubmission submission);
  Future<List<LocalSubmission>> submissions();

  /// States of the given cards that have a row.
  Future<Map<String, UserCardState>> cardStates(Iterable<String> cardIds);

  /// All card rows of the language, disabled and retired ones included
  /// ([deriveVocabBreakdown] filters them).
  Future<Map<String, UserCardState>> allCardStates();

  /// Creates box-0 rows at the first display (docs/srs.md, Erstkontakt);
  /// existing rows stay unchanged.
  Future<void> ensureCards(
    Iterable<String> cardIds, {
    required DateTime now,
    required CardOrigin origin,
  });

  /// Appends [record] to the review log and sets the card's box and due date
  /// in one transaction. Returns false and changes nothing if a record with
  /// the same pass id exists. Throws (and changes nothing) if the card has no
  /// row or its box is no longer `record.boxBefore`.
  Future<bool> recordReview(ReviewRecord record);

  /// Logged reviews per card (statistics only).
  Future<Map<String, int>> reviewCounts(Iterable<String> cardIds);

  /// Review log of one card, oldest first.
  Future<List<ReviewRecord>> reviewsFor(String cardId);

  /// The ids among [deckIds] that are active; a deck without a setting row
  /// is active.
  Future<Set<String>> activeDeckIds(Iterable<String> deckIds);

  Future<void> setDeckActive(
    String deckId,
    bool active, {
    required DateTime now,
  });

  /// The device id for `review_log.device_id`, created once.
  Future<String> deviceId();

  /// Fires after card states, reviews or deck settings changed.
  Stream<void> changes();

  Future<void> close();
}
