// Pure Dart: no Flutter imports (see CLAUDE.md, domain layer).
import 'package:unorm_dart/unorm_dart.dart' as unicode;

/// Same NFC -> lowercase -> apostrophe sequence as sprachpipe.ids.form_norm.
/// Identity never strips accents or trims content forms.
String contentFormNorm(String value) =>
    unicode.nfc(value).toLowerCase().replaceAll('’', "'");

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

/// A deck with its number of editorial learning targets (without learner state).
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
    this.learning,
    this.senseKey,
    this.senseId,
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
  final LearningTarget? learning;
  String get learningGroup => learning?.groupId ?? id;
  String get learningHead => learning?.primaryCardId ?? id;
  final String? senseKey;
  final String? senseId;
  final String? formKind;

  /// "Verb, Vergangenheit": the grammar hint under the gap.
  final String? formLabelDe;
  final String? translationDe;
  final String? cefrBand;
}

/// A current or historical sentence of a card (`card_sentences` + `sentences`).
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

  /// 1 for active schema-2 practice; historical positions are retained.
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

/// Everything a pass of a card needs: the card, its sentences in
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

  /// Fixed practice sentence, including schema-1 compatibility projection.
  CardSentence get practiceSentence => sentences.first;

  /// Compatibility API: prior reviews never rotate the assigned sentence.
  CardSentence sentenceForPass(int priorReviews) => practiceSentence;
}

/// Editorial introduction metadata; never grants accepted answers or merges state.
class LearningTarget {
  const LearningTarget({
    required this.groupId,
    required this.primaryCardId,
    required this.topic,
    this.related = const [],
    required this.note,
  });
  final String groupId, primaryCardId, topic, note;
  final List<String> related;
  factory LearningTarget.fromJson(Map<String, dynamic> value) => LearningTarget(
    groupId: value['group_id'] as String,
    primaryCardId: value['primary_card_id'] as String,
    topic: value['topic'] as String,
    related: (value['related'] as List).cast<String>(),
    note: value['note'] as String,
  );
}
