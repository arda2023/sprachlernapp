import '../domain/leitner.dart';
import 'story_models.dart';

/// A word the learner has seen at least once, as listed in the Wortliste.
/// Words never shown ("Noch nicht angezeigt") have no memory level yet and
/// don't appear here.
class VocabWord {
  const VocabWord({
    required this.id,
    required this.entry,
    required this.sentence,
    required this.sentenceTranslation,
    required this.box,
    required this.lastSeenAt,
    required this.reviewCount,
    this.isDisabled = false,
    this.isFavorite = false,
    this.inPlaylist = false,
    this.note = '',
  }) : assert(box >= 0 && box <= leitnerBoxCount),
       assert(reviewCount >= 0);

  /// Stable slug, so content-pack imports stay idempotent.
  final String id;
  final WordEntry entry;

  /// Example sentence (target language) and its pre-generated translation.
  final String sentence;
  final String sentenceTranslation;

  /// Leitner box 1–5; shown as the memory level.
  final int box;
  final DateTime lastSeenAt;

  /// Derived from the review log once Drift exists; never a stored counter.
  final int reviewCount;

  /// Excluded from practice ("Wort deaktivieren").
  final bool isDisabled;
  final bool isFavorite;
  final bool inPlaylist;
  final String note;

  Duration get reviewInterval =>
      box == 0 ? Duration.zero : leitnerInterval(box);

  VocabWord copyWith({
    int? box,
    DateTime? lastSeenAt,
    int? reviewCount,
    bool? isDisabled,
    bool? isFavorite,
    bool? inPlaylist,
    String? note,
  }) => VocabWord(
    id: id,
    entry: entry,
    sentence: sentence,
    sentenceTranslation: sentenceTranslation,
    box: box ?? this.box,
    lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    reviewCount: reviewCount ?? this.reviewCount,
    isDisabled: isDisabled ?? this.isDisabled,
    isFavorite: isFavorite ?? this.isFavorite,
    inPlaylist: inPlaylist ?? this.inPlaylist,
    note: note ?? this.note,
  );
}

/// "heute", "gestern", "vor 2 Tagen", "vor 3 Wochen", "vor 2 Monaten".
String lastSeenLabel(DateTime seenAt, DateTime now) {
  final days = calendarDaysBetween(seenAt, now);
  if (days <= 0) return 'heute';
  if (days == 1) return 'gestern';
  if (days < 14) return 'vor $days Tagen';
  if (days < 60) return 'vor ${days ~/ 7} Wochen';
  return 'vor ${days ~/ 30} Monaten';
}

/// "1 Tag", "14 Tage".
String intervalLabel(Duration interval) =>
    interval.inDays == 1 ? '1 Tag' : '${interval.inDays} Tage';

/// "1 Mal", "5 Mal".
String reviewCountLabel(int count) => '$count Mal';
