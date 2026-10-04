// Pure Dart: no Flutter imports (see CLAUDE.md, domain layer).

/// Why the content pack can't be used. The app shows a clear state instead
/// of placeholder data (docs/app-content-integration-plan.md, Abschnitt 5).
enum ContentUnavailableReason {
  /// No pack installed or bundled.
  missing,

  /// Not readable as a pack (not SQLite, damaged, checksum mismatch).
  corrupt,

  /// Readable, but not the expected schema, version or language.
  incompatible,
}

/// Typed failure of the content pack; [message] names the concrete cause.
class ContentUnavailable implements Exception {
  const ContentUnavailable(this.reason, this.message);

  final ContentUnavailableReason reason;
  final String message;

  @override
  String toString() => 'ContentUnavailable(${reason.name}): $message';
}

/// The release row of a content pack (`content_releases`).
class ContentInfo {
  const ContentInfo({
    required this.lang,
    required this.version,
    required this.schemaVersion,
    this.notes,
  });

  final String lang;
  final String version;
  final int schemaVersion;
  final String? notes;

  /// Internal test material (PRODUCT.md, Storage): usable on own devices and
  /// by selected testers, never a public content release.
  bool get isInternalTestPack =>
      notes?.startsWith('INTERNES TEST-PACK') ?? false;
}

/// A deck (`decks`) with the number of its cards.
class DeckSummary {
  const DeckSummary({
    required this.id,
    required this.slug,
    required this.titleDe,
    required this.cardCount,
    this.descriptionDe,
    this.cefrBand,
  });

  final String id;
  final String slug;
  final String titleDe;
  final String? descriptionDe;

  /// `anfaenger`, `mittel` or `fortgeschritten`.
  final String? cefrBand;
  final int cardCount;
}

/// One card (`cards`): an exact form in one sense. [id] is the stable
/// content id, also used as `user_cards.card_id`.
class ContentCard {
  const ContentCard({
    required this.id,
    required this.lang,
    required this.form,
    required this.formNorm,
    required this.lemmaId,
    required this.lemma,
    required this.pos,
    this.senseKey,
    this.formKind,
    this.formLabelDe,
    this.translationDe,
    this.cefrBand,
  });

  final String id;
  final String lang;
  final String form;
  final String formNorm;
  final String lemmaId;

  /// Lemma text, for the wrong-form hint.
  final String lemma;
  final String pos;
  final String? senseKey;
  final String? formKind;

  /// "Verb, Vergangenheit": the grammar hint under the gap.
  final String? formLabelDe;
  final String? translationDe;
  final String? cefrBand;
}

/// One of the three sentences of a card (`card_sentences` + `sentences`).
/// The gap is `text[gapStart, gapEnd)`; [validAlternatives] hold only for
/// this card, sentence and gap.
class CardSentence {
  const CardSentence({
    required this.cardId,
    required this.sentenceId,
    required this.position,
    required this.text,
    required this.gapStart,
    required this.gapEnd,
    this.translationDe,
    this.validAlternatives = const [],
    this.tokens = const [],
  });

  final String cardId;

  /// Stable `sentences.id`, logged as `review_log.sentence_id`.
  final String sentenceId;

  /// 1–3.
  final int position;
  final String text;
  final String? translationDe;
  final int gapStart;
  final int gapEnd;
  final List<String> validAlternatives;
  final List<SentenceToken> tokens;

  String get gapText => text.substring(gapStart, gapEnd);
}

/// Exact sentence annotation, offsets are UTF-16 for Dart text layout.
class SentenceToken {
  const SentenceToken({
    required this.start,
    required this.end,
    required this.surface,
    this.translation,
  });
  final int start, end;
  final String surface;
  final String? translation;
}

/// Everything a pass of a card needs: the card, its three sentences in
/// position order and the other forms of its lemma (wrong-form check).
class PracticeItem {
  const PracticeItem({
    required this.card,
    required this.sentences,
    required this.otherFormsOfLemma,
  });

  final ContentCard card;
  final List<CardSentence> sentences;

  /// Normalized forms of the same lemma (dictionary and cards), without the
  /// card's own form.
  final Set<String> otherFormsOfLemma;

  /// The sentence of the next pass: rotates through positions 1–3 by the
  /// number of earlier logged reviews of the card.
  CardSentence sentenceForPass(int priorReviews) =>
      sentences[priorReviews % sentences.length];
}
