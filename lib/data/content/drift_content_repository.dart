import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/content.dart';
import '../../domain/repositories.dart';
import 'content_database.dart';

/// [ContentRepository] on the read-only [ContentDatabase]. Rows with
/// `removed_in` (tombstones) are never returned; ids are passed through
/// unchanged. Content that breaks the data contract (not three sentences,
/// gap not on the form, malformed alternatives) is [ContentUnavailable].
class DriftContentRepository implements ContentRepository {
  DriftContentRepository(this._db);

  final ContentDatabase _db;

  static const _chunk = 500;

  @override
  ContentInfo get info => _db.info;

  String get _lang => _db.info.lang;

  Future<List<QueryRow>> _select(String sql, List<Object?> args) => _db
      .customSelect(sql, variables: [for (final a in args) Variable(a)])
      .get();

  String _marks(int n) => List.filled(n, '?').join(', ');

  ContentUnavailable _broken(String message) =>
      ContentUnavailable(ContentUnavailableReason.incompatible, message);

  @override
  Future<List<DeckSummary>> decks() async {
    final rows = await _select(
      'SELECT d.id, d.slug, d.title_de, d.description_de, d.cefr_band, '
      '(SELECT count(*) FROM deck_cards dc JOIN cards c ON c.id = dc.card_id '
      ' WHERE dc.deck_id = d.id AND dc.removed_in IS NULL '
      ' AND c.removed_in IS NULL) AS card_count '
      'FROM decks d WHERE d.lang = ? AND d.removed_in IS NULL '
      'ORDER BY d.sort, d.slug',
      [_lang],
    );
    return [
      for (final r in rows)
        DeckSummary(
          id: r.read<String>('id'),
          slug: r.read<String>('slug'),
          titleDe: r.read<String>('title_de'),
          descriptionDe: r.readNullable<String>('description_de'),
          cefrBand: r.readNullable<String>('cefr_band'),
          cardCount: r.read<int>('card_count'),
        ),
    ];
  }

  @override
  Future<List<String>> deckCardIds(String deckId) async {
    final rows = await _select(
      'SELECT dc.card_id FROM deck_cards dc JOIN cards c ON c.id = dc.card_id '
      'WHERE dc.deck_id = ? AND dc.removed_in IS NULL AND c.removed_in IS NULL '
      'ORDER BY dc.position, dc.card_id',
      [deckId],
    );
    return [for (final r in rows) r.read<String>('card_id')];
  }

  @override
  Future<Set<String>> allCardIds() async {
    final rows = await _select(
      'SELECT id FROM cards WHERE lang = ? AND removed_in IS NULL',
      [_lang],
    );
    return {for (final r in rows) r.read<String>('id')};
  }

  @override
  Future<List<ContentCard>> selectionCards(Iterable<String> cardIds) async {
    final ids = cardIds.toSet().toList();
    final cards = <String, ContentCard>{};
    for (var i = 0; i < ids.length; i += _chunk) {
      final chunk = ids.sublist(i, (i + _chunk).clamp(0, ids.length));
      final marks = _marks(chunk.length);
      for (final r in await _select(
        'SELECT c.id, c.lang, c.form, c.form_norm, c.lemma_id, l.lemma, c.pos, '
        'c.form_kind, c.form_label_de, c.translation_de, c.cefr_band, s.sense_key '
        'FROM cards c JOIN lemmas l ON l.id = c.lemma_id '
        'JOIN senses s ON s.id = c.sense_id '
        'WHERE c.id IN ($marks) AND c.lang = ? AND c.removed_in IS NULL',
        [...chunk, _lang],
      )) {
        final card = ContentCard(
          id: r.read<String>('id'),
          lang: r.read<String>('lang'),
          form: r.read<String>('form'),
          formNorm: r.read<String>('form_norm'),
          lemmaId: r.read<String>('lemma_id'),
          lemma: r.read<String>('lemma'),
          pos: r.read<String>('pos'),
          senseKey: r.read<String>('sense_key'),
          formKind: r.readNullable<String>('form_kind'),
          formLabelDe: r.readNullable<String>('form_label_de'),
          translationDe: r.readNullable<String>('translation_de'),
          cefrBand: r.readNullable<String>('cefr_band'),
        );
        cards[card.id] = card;
      }
    }
    return [
      for (final id in ids)
        if (cards.containsKey(id)) cards[id]!,
    ];
  }

  @override
  Future<List<PracticeItem>> practiceItems(List<String> cardIds) async {
    final ids = cardIds.toSet().toList();
    final cards = {for (final c in await selectionCards(ids)) c.id: c};
    final sentences = <String, List<CardSentence>>{};
    for (var i = 0; i < ids.length; i += _chunk) {
      final chunk = ids.sublist(i, (i + _chunk).clamp(0, ids.length));
      for (final r in await _select(
        'SELECT cs.card_id, cs.sentence_id, cs.position, cs.gap_start, '
        'cs.gap_end, cs.valid_alternatives, s.text, s.translation_de '
        'FROM card_sentences cs JOIN sentences s ON s.id = cs.sentence_id '
        'WHERE cs.card_id IN (${_marks(chunk.length)}) AND cs.removed_in IS NULL '
        'AND s.removed_in IS NULL ORDER BY cs.card_id, cs.position',
        chunk,
      )) {
        final cardId = r.read<String>('card_id');
        sentences
            .putIfAbsent(cardId, () => [])
            .add(
              CardSentence(
                cardId: cardId,
                sentenceId: r.read<String>('sentence_id'),
                position: r.read<int>('position'),
                text: r.read<String>('text'),
                tokens: await _tokens(
                  r.read<String>('sentence_id'),
                  r.read<String>('text'),
                ),
                translationDe: r.readNullable<String>('translation_de'),
                gapStart: _utf16Offset(
                  r.read<String>('text'),
                  r.read<int>('gap_start'),
                ),
                gapEnd: _utf16Offset(
                  r.read<String>('text'),
                  r.read<int>('gap_end'),
                ),
                validAlternatives: _alternatives(
                  r.readNullable<String>('valid_alternatives'),
                  cardId,
                ),
              ),
            );
      }
    }
    final unknown = ids.where((id) => !cards.containsKey(id)).toList();
    if (unknown.isNotEmpty) {
      throw ArgumentError.value(unknown, 'cardIds', 'not in the content pack');
    }
    final forms = await _lemmaForms({for (final c in cards.values) c.lemmaId});
    return [
      for (final id in ids)
        PracticeItem(
          card: cards[id]!,
          sentences: _checked(cards[id]!, sentences[id] ?? const []),
          otherFormsOfLemma: {...?forms[cards[id]!.lemmaId]}
            ..remove(cards[id]!.formNorm),
        ),
    ];
  }

  /// `valid_alternatives` is JSON text in content.sqlite; a missing value in
  /// old packs is the empty list (docs/content-schema.md).
  List<String> _alternatives(String? raw, String cardId) {
    if (raw == null) return const [];
    Object? value;
    try {
      value = jsonDecode(raw);
    } on FormatException {
      throw _broken('valid_alternatives von $cardId ist kein JSON');
    }
    if (value is! List || value.any((v) => v is! String)) {
      throw _broken(
        'valid_alternatives von $cardId ist keine Liste von Texten',
      );
    }
    return List.unmodifiable(value.cast<String>());
  }

  Future<List<SentenceToken>> _tokens(String id, String text) async {
    final rows = await _select(
      'SELECT t.start_pos, t.end_pos, t.surface, '
      'COALESCE(c.translation_de, (SELECT df.gloss_de FROM dictionary_forms df '
      'WHERE df.sense_id = t.sense_id AND df.form_norm = lower(t.surface) '
      'AND s.id IS NOT NULL AND df.removed_in IS NULL ORDER BY df.rank, df.id LIMIT 1), s.gloss_de) AS gloss '
      'FROM sentence_tokens t '
      'LEFT JOIN senses s ON s.id = t.sense_id AND s.removed_in IS NULL '
      'LEFT JOIN cards c ON c.id = t.card_id AND c.sense_id = s.id AND c.form_norm = lower(t.surface) AND c.removed_in IS NULL '
      'WHERE t.sentence_id = ? AND t.removed_in IS NULL ORDER BY t.idx',
      [id],
    );
    final result = <SentenceToken>[];
    var lastEnd = 0;
    for (final r in rows) {
      // Packs use Unicode code-point offsets (Python), Flutter uses UTF-16.
      final startPoint = r.read<int>('start_pos'),
          endPoint = r.read<int>('end_pos');
      if (startPoint < 0 ||
          endPoint <= startPoint ||
          endPoint > text.runes.length) {
        continue;
      }
      final start = String.fromCharCodes(text.runes.take(startPoint)).length;
      final end = String.fromCharCodes(text.runes.take(endPoint)).length;
      final surface = r.read<String>('surface');
      if (start < lastEnd || text.substring(start, end) != surface) continue;
      result.add(
        SentenceToken(
          start: start,
          end: end,
          surface: surface,
          translation: r.readNullable<String>('gloss'),
        ),
      );
      lastEnd = end;
    }
    return List.unmodifiable(result);
  }

  int _utf16Offset(String text, int point) => point < 0
      ? point
      : point > text.runes.length
      ? text.length + 1
      : String.fromCharCodes(text.runes.take(point)).length;

  /// Exactly three sentences at positions 1–3, each with the form in its gap.
  List<CardSentence> _checked(ContentCard card, List<CardSentence> list) {
    if (list.length != 3 ||
        [for (final s in list) s.position].join(',') != '1,2,3') {
      throw _broken('Karte ${card.id} hat nicht genau drei Sätze (1–3)');
    }
    for (final s in list) {
      final ok =
          s.gapStart >= 0 &&
          s.gapEnd <= s.text.length &&
          s.gapStart < s.gapEnd &&
          s.gapText.toLowerCase() == card.form.toLowerCase();
      if (!ok) {
        throw _broken(
          'Lücke von Satz ${s.sentenceId} trifft nicht '
          '„${card.form}“',
        );
      }
    }
    return List.unmodifiable(list);
  }

  /// Normalized forms per lemma: dictionary forms of its senses and the
  /// forms of its cards (wrong-form check).
  Future<Map<String, Set<String>>> _lemmaForms(Set<String> lemmaIds) async {
    final out = <String, Set<String>>{};
    final ids = lemmaIds.toList();
    for (var i = 0; i < ids.length; i += _chunk) {
      final chunk = ids.sublist(i, (i + _chunk).clamp(0, ids.length));
      final marks = _marks(chunk.length);
      for (final r in await _select(
        'SELECT s.lemma_id, df.form_norm FROM dictionary_forms df '
        'JOIN senses s ON s.id = df.sense_id '
        'WHERE s.lemma_id IN ($marks) AND df.removed_in IS NULL '
        'AND s.removed_in IS NULL '
        'UNION SELECT lemma_id, form_norm FROM cards '
        'WHERE lemma_id IN ($marks) AND removed_in IS NULL',
        [...chunk, ...chunk],
      )) {
        out
            .putIfAbsent(r.read<String>('lemma_id'), () => {})
            .add(r.read<String>('form_norm'));
      }
    }
    return out;
  }

  @override
  Future<void> close() => _db.close();
}
