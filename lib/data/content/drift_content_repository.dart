import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/content.dart';
import '../../domain/story_learning.dart';
import '../../domain/repositories.dart';
import 'content_database.dart';
import 'context_revision_validation.dart';

/// [ContentRepository] on the read-only [ContentDatabase]. Rows with
/// `removed_in` (tombstones) are never returned; ids are passed through
/// unchanged. Content that breaks the data contract (wrong active sentence count,
/// gap not on the form, malformed alternatives) is [ContentUnavailable].
class DriftContentRepository
    implements ContentRepository, StoryContentRepository, RetiredLearningContentRepository, StoryContextCorrectionSource {
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
      '${info.schemaVersion >= 4 ? 'd.practice_kind' : "'ordinary'"} AS practice_kind, '
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
          practiceKind: r.read<String>('practice_kind'),
          slug: r.read<String>('slug'),
          titleDe: r.read<String>('title_de'),
          descriptionDe: r.readNullable<String>('description_de'),
          cefrBand: r.readNullable<String>('cefr_band'),
          cardCount: r.read<String>('practice_kind') == 'ordinary'
              ? (await selectionCards(await deckCardIds(r.read<String>('id')))).where((c)=>c.introductionScope=='ordinary').map((c)=>c.learningGroup).toSet().length
              : (await deckPracticeTargets(r.read<String>('id'))).length,
        ),
    ];
  }

  @override
  Future<List<String>> deckCardIds(String deckId) async {
    final rows = await _select(
      'SELECT dc.card_id, dc.deck_id, c.form_norm, c.form FROM deck_cards dc '
      'JOIN cards c ON c.id = dc.card_id JOIN decks d ON d.id = dc.deck_id '
      'WHERE dc.removed_in IS NULL AND c.removed_in IS NULL AND d.removed_in IS NULL '
      'AND c.lang = ? ORDER BY d.sort, d.slug, dc.position, dc.card_id',
      [_lang],
    );
    // Schema 1 has no ownership table: deterministic read-only projection.
    final seen = <String>{};
    return [
      for (final r in rows)
        if ((_db.info.schemaVersion >= 2 ||
                seen.add(contentFormNorm(r.read<String>('form')))) &&
            r.read<String>('deck_id') == deckId)
          r.read<String>('card_id'),
    ];
  }

  Future<FormTarget?> _formTarget(String cardId) async {
    if (info.schemaVersion < 4) return null;
    final rows = await _select('SELECT * FROM form_targets WHERE card_id=? AND removed_in IS NULL', [cardId]);
    if (rows.isEmpty) return null;
    if (rows.length != 1) throw _broken('Mehrdeutige Formkarte');
    final r = rows.single;
    return FormTarget(id:r.read<String>('id'),cardId:cardId,senseId:r.read<String>('sense_id'),
      form:r.read<String>('form'),function:r.read<String>('function'),lexicalTargetId:r.read<String>('lexical_target_id'));
  }

  @override
  Future<List<DeckPracticeTarget>> deckPracticeTargets(String deckId) async {
    if (info.schemaVersion >= 4) {
      final decks = await _select('SELECT practice_kind FROM decks WHERE id=? AND removed_in IS NULL', [deckId]);
      if (decks.isNotEmpty && decks.single.read<String>('practice_kind') != 'ordinary') {
        final rows=await _select('SELECT f.card_id FROM deck_practice_targets d JOIN form_targets f ON f.id=d.form_target_id WHERE d.deck_id=? AND d.removed_in IS NULL AND f.removed_in IS NULL ORDER BY d.position', [deckId]);
        return [for (final r in rows) DeckPracticeTarget(cardId:r.read<String>('card_id'),formTarget:await _formTarget(r.read<String>('card_id')))];
      }
    }
    final cards = await selectionCards(await deckCardIds(deckId));
    return [for (final c in cards) if(c.introductionScope == 'ordinary') DeckPracticeTarget(cardId:c.id)];
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
        'c.form_kind, c.form_label_de, c.translation_de, c.cefr_band, c.sense_id, s.sense_key, '
        '${info.schemaVersion >= 3 ? 'c.learning' : 'NULL'} AS learning, '
        '${info.schemaVersion >= 4 ? 'c.identity_function' : 'NULL'} AS identity_function, '
        '${info.schemaVersion >= 4 ? 'c.introduction_scope' : "'ordinary'"} AS introduction_scope, '
        '${info.schemaVersion >= 4 ? '(SELECT lexical_target_id FROM card_lexical_targets WHERE card_id=c.id AND removed_in IS NULL)' : 'NULL'} AS lexical_target_id '
        'FROM cards c JOIN lemmas l ON l.id = c.lemma_id '
        'JOIN senses s ON s.id = c.sense_id '
        'WHERE c.id IN ($marks) AND c.lang = ? AND c.removed_in IS NULL',
        [...chunk, _lang],
      )) {
        final card = ContentCard(
          formTarget: await _formTarget(r.read<String>('id')),
          identityFunction: r.readNullable<String>('identity_function'),
          introductionScope: r.read<String>('introduction_scope'),
          lexicalTargetId: r.readNullable<String>('lexical_target_id'),
          learning: r.readNullable<String>('learning') == null
              ? null
              : LearningTarget.fromJson(
                  jsonDecode(r.read<String>('learning'))
                      as Map<String, dynamic>,
                ),
          id: r.read<String>('id'),
          lang: r.read<String>('lang'),
          form: r.read<String>('form'),
          formNorm: r.read<String>('form_norm'),
          lemmaId: r.read<String>('lemma_id'),
          lemma: r.read<String>('lemma'),
          pos: r.read<String>('pos'),
          senseKey: r.read<String>('sense_key'),
          senseId: r.read<String>('sense_id'),
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

  Future<List<SentenceToken>> _tokens(String id, String text, {bool historical = false}) async {
    String active(String alias) => historical ? '' : 'AND $alias.removed_in IS NULL';
    final rows = await _select(
      'SELECT t.start_pos, t.end_pos, t.surface, '
      '${info.schemaVersion >= 5 ? 't.context_gloss_de, t.context_snapshot,' : ''} '
      'COALESCE(c.translation_de, (SELECT df.gloss_de FROM dictionary_forms df '
      'WHERE df.sense_id = t.sense_id AND df.form_norm = lower(t.surface) '
      'AND s.id IS NOT NULL ${active('df')} ORDER BY df.rank, df.id LIMIT 1), s.gloss_de) AS gloss '
      'FROM sentence_tokens t '
      'LEFT JOIN senses s ON s.id = t.sense_id ${active('s')} '
      'LEFT JOIN cards c ON c.id = t.card_id AND c.sense_id = s.id AND c.form_norm = lower(t.surface) ${active('c')} '
      'WHERE t.sentence_id = ? ${active('t')} ORDER BY t.idx',
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
          translation: info.schemaVersion >= 5
              ? _contextGloss(r, historical: historical)
              : r.readNullable<String>('gloss'),
        ),
      );
      lastEnd = end;
    }
    return List.unmodifiable(result);
  }

  String? _contextGloss(QueryRow row, {required bool historical}) {
    final snapshot = jsonDecode(row.read<String>('context_snapshot')) as Map<String, dynamic>;
    return snapshot['legacy'] == true
        ? snapshot[historical ? 'legacy_historical_gloss' : 'legacy_active_gloss'] as String?
        : row.readNullable<String>('context_gloss_de');
  }

  int _utf16Offset(String text, int point) => point < 0
      ? point
      : point > text.runes.length
      ? text.length + 1
      : String.fromCharCodes(text.runes.take(point)).length;

  /// Strict per-version active cardinality; legacy practice always uses first.
  List<CardSentence> _checked(ContentCard card, List<CardSentence> list) {
    final expected = _db.info.schemaVersion == 1 ? '1,2,3' : '1';
    if ([for (final s in list) s.position].join(',') != expected) {
      throw _broken(
        'Karte ${card.id}: aktive Satzpositionen müssen $expected sein',
      );
    }
    for (final s in list) {
      final ok =
          s.gapStart >= 0 &&
          s.gapEnd <= s.text.length &&
          s.gapStart < s.gapEnd &&
          contentFormNorm(s.gapText) == contentFormNorm(card.form);
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
  Future<CardSentence?> historicalSentence(
    String cardId,
    String sentenceId,
  ) async {
    final rows = await _select(
      'SELECT cs.*, s.text, s.translation_de FROM card_sentences cs '
      'JOIN sentences s ON s.id = cs.sentence_id '
      'WHERE cs.card_id = ? AND cs.sentence_id = ?',
      [cardId, sentenceId],
    );
    if (rows.isEmpty) return null;
    final r = rows.single;
    final text = r.read<String>('text');
    return CardSentence(
      cardId: cardId,
      sentenceId: sentenceId,
      position: r.read<int>('position'),
      text: text,
      translationDe: r.readNullable<String>('translation_de'),
      gapStart: _utf16Offset(text, r.read<int>('gap_start')),
      gapEnd: _utf16Offset(text, r.read<int>('gap_end')),
      validAlternatives: _alternatives(
        r.readNullable<String>('valid_alternatives'),
        cardId,
      ),
      tokens: await _tokens(sentenceId, text, historical: true),
    );
  }

  @override
  Future<Map<String, LearningIdentity>> retiredLearningIdentities() async => {
    for (final r in await _select(
      'SELECT id, lang, form_norm, sense_id, '
      '${_db.info.schemaVersion >= 4 ? 'identity_function' : 'NULL'} AS function '
      'FROM cards WHERE removed_in IS NOT NULL AND lang = ?', [_lang]))
      r.read<String>('id'): LearningIdentity(r.read<String>('lang'),
        r.read<String>('form_norm'), r.read<String>('sense_id'),
        function: r.readNullable<String>('function')),
  };

  @override
  Future<void> close() => _db.close();
  @override
  Future<List<StorySummary>> storySummaries() async => [
    for (final r in await _select(
      r"SELECT st.*,json_extract(s.qa_report, '$.editorial_create.story_title_de') AS title_de FROM stories st LEFT JOIN story_sentences ss ON ss.story_id=st.id AND ss.idx=0 LEFT JOIN sentences s ON s.id=ss.sentence_id WHERE st.lang=? AND st.removed_in IS NULL ORDER BY st.slug",
      [_lang],
    ))
      StorySummary(
        id: r.read<String>('id'),
        title: r.read<String>('title'),
        titleDe: r.readNullable<String>('title_de') ?? '',
        level: r.readNullable<String>('cefr_band') ?? 'anfaenger',
        minutes: r.readNullable<int>('minutes') ?? 1,
      ),
  ];

  @override
  Future<StoryDocument> storyDocument(String id) async {
    final summary = (await storySummaries()).where((s) => s.id == id).single;
    final rows = await _select(
      'SELECT s.*,ss.paragraph_idx FROM story_sentences ss JOIN sentences s ON s.id=ss.sentence_id WHERE ss.story_id=? AND ss.removed_in IS NULL AND s.removed_in IS NULL ORDER BY ss.idx',
      [id],
    );
    final sentences = <StorySentence>[];
    for (final r in rows) {
      final sid = r.read<String>('id'), text = r.read<String>('text');
      final qa = jsonDecode(
        r.readNullable<String>('qa_report') ?? '{}',
      ) as Map<String, dynamic>;
      final reviewed =
          (qa['editorial_create']
                  as Map<String, dynamic>?)?['learning_contexts']
              as List? ??
          [];
      final approved = {
        for (final x in reviewed)
          if (x['approved'] == true) x['token_index'] as int,
      };
      final tokens = <StoryToken>[];
      for (final t in await _select(
        'SELECT t.*,l.lemma,l.pos,s.sense_key,s.gloss_de AS sense_gloss,s.definition_de FROM sentence_tokens t LEFT JOIN lemmas l ON l.id=t.lemma_id AND l.removed_in IS NULL LEFT JOIN senses s ON s.id=t.sense_id AND s.lemma_id=t.lemma_id AND s.removed_in IS NULL WHERE t.sentence_id=? AND t.removed_in IS NULL ORDER BY t.idx',
        [sid],
      )) {
        final surface = t.read<String>('surface');
        final start = _utf16Offset(text, t.read<int>('start_pos')),
            end = _utf16Offset(text, t.read<int>('end_pos'));
        if (start < 0 ||
            end > text.length ||
            start >= end ||
            text.substring(start, end) != surface) {
          throw _broken('Ungültige Story-Wortstelle');
        }
        final sense = t.readNullable<String>('sense_id');
        final gloss = await _select(
          'SELECT gloss_de FROM dictionary_forms WHERE lang=? AND form_norm=? AND sense_id=? AND removed_in IS NULL',
          [_lang, contentFormNorm(surface), sense],
        );
        final snapshot = info.schemaVersion >= 5
            ? jsonDecode(t.read<String>('context_snapshot')) as Map<String, dynamic>
            : null;
        tokens.add(
          StoryToken(
            index: t.read<int>('idx'),
            start: start,
            end: end,
            surface: surface,
            cardId: t.readNullable<String>('card_id'),
            formTarget: info.schemaVersion >= 4 && t.readNullable<String>('form_target_id') != null
                ? await _formTarget(t.read<String>('card_id')) : null,
            lemmaId: t.readNullable<String>('lemma_id'),
            lemma: snapshot != null ? snapshot['lemma'] as String? : t.readNullable<String>('lemma'),
            pos: snapshot != null ? snapshot['pos'] as String? : t.readNullable<String>('pos'),
            senseId: sense,
            senseKey: snapshot != null ? snapshot['sense_key'] as String? : t.readNullable<String>('sense_key'),
            gloss: snapshot != null
                ? snapshot['legacy'] == true ? snapshot['story_gloss'] as String? : t.readNullable<String>('context_gloss_de')
                : gloss.length == 1
                ? gloss.single.read<String>('gloss_de')
                : null,
            definition: snapshot != null ? snapshot['definition_de'] as String? :
                t.readNullable<String>('definition_de') ??
                t.readNullable<String>('sense_gloss'),
            contextApproved: approved.contains(t.read<int>('idx')),
          ),
        );
      }
      sentences.add(
        StorySentence(
          id: sid,
          text: text,
          translation: r.readNullable<String>('translation_de') ?? '',
          paragraph: r.read<int>('paragraph_idx'),
          tokens: tokens,
        ),
      );
    }
    return StoryDocument(summary, info.version, sentences);
  }

  @override
  Future<StoryLearningCandidate> resolveStoryWord(
    String storyId,
    String sentenceId,
    int tokenIndex,
  ) async {
    final doc = await storyDocument(storyId);
    final sentence = doc.sentences.singleWhere((s) => s.id == sentenceId);
    final token = sentence.tokens.singleWhere((t) => t.index == tokenIndex);
    final candidates = await _select(
      'SELECT id,removed_in FROM cards WHERE lang=? AND form_norm=? AND sense_id=?',
      [_lang, contentFormNorm(token.surface), token.senseId],
    );
    final matches = token.formTarget == null ? candidates : candidates.where((r) => r.read<String>('id') == token.formTarget!.cardId).toList();
    ContentCard? card;
    final retired = matches.any(
      (r) => r.readNullable<String>('removed_in') != null,
    );
    String? problem;
    if (token.cardId != null &&
        !matches.any((r) => r.read<String>('id') == token.cardId)) {
      problem =
          'Die gespeicherte Kartenreferenz passt nicht zur Wortbedeutung.';
    }
    if (matches.length > 1) {
      problem = 'Mehrere Karten passen zur genauen Bedeutung.';
    }
    if (matches.length == 1 && !retired) {
      final items = await practiceItems([matches.single.read<String>('id')]);
      card = items.single.card;
      if (token.formTarget == null && card.introductionScope == 'form_only') {
        problem = 'Die Form ist im Satz nicht eindeutig belegt. Die Übersetzung bleibt verfügbar.';
      }
    }
    StoryPracticeContext? practiceContext;
    final sourceRows = await _select('SELECT qa_report FROM sentences WHERE id=?', [sentenceId]);
    final qa = jsonDecode(sourceRows.single.readNullable<String>('qa_report') ?? '{}') as Map<String, dynamic>;
    final review = qa['story_practice_contexts'] as Map<String, dynamic>?;
    if (review != null) {
      final bindings = (review['bindings'] as List).where((b) => b['token_index'] == tokenIndex).toList();
      if (bindings.isNotEmpty) {
        final b = bindings.single;
        if (!{1, 2}.contains(review['format_version']) || (review['reviewer'] as String? ?? '').isEmpty ||
            b['surface'] != token.surface || b['sense_id'] != token.senseId ||
            _utf16Offset(sentence.text, b['source_start'] as int) != token.start ||
            _utf16Offset(sentence.text, b['source_end'] as int) != token.end) {
          problem = 'Die geprüfte Kontextbindung passt nicht zur Story-Wortstelle.';
        } else {
          practiceContext = _readStoryContext(b['context'] as Map<String, dynamic>, token);
          if (review['format_version'] == 2) {
            final policy = b['sentence_policy'] as Map<String, dynamic>?;
            if (policy == null || policy['sentence_count'] != 1 ||
                (policy['exercise_word_count'] as int? ?? 0) < 3 ||
                (policy['exercise_word_count'] as int? ?? 21) > 20 ||
                ((policy['source_word_count'] as int? ?? 0) <= 2 && policy['replacement'] != true) ||
                (policy['replacement'] != true &&
                  (practiceContext.sentence.text != sentence.text ||
                   practiceContext.sentence.translation != sentence.translation))) {
              problem = 'Der geprüfte Kontext erfüllt den Ein-Satz-Vertrag nicht.';
            }
          }
        }
      }
    }
    if (info.schemaVersion >= 5 && card == null && !retired && problem == null) {
      final identity = LearningIdentity(_lang, contentFormNorm(token.surface), token.senseId ?? '', function: token.function);
      final sourceKey = learningHash([storyId, sentenceId, tokenIndex, identity.key]);
      final edges = await _select('SELECT previous_fingerprint,next_fingerprint,next_context FROM story_context_corrections WHERE source_key=?', [sourceKey]);
      final predecessors = edges.map((e) => e.read<String>('previous_fingerprint')).toSet();
      final terminals = edges.where((e) => !predecessors.contains(e.read<String>('next_fingerprint')));
      StoryLearningCandidate? latest;
      for (final edge in terminals) {
        final candidate = decodeStoryCandidate(jsonDecode(edge.read<String>('next_context')) as Map<String,dynamic>);
        if (latest != null && latest.practiceContext?.fingerprint != candidate.practiceContext?.fingerprint) {
          throw _broken('Storykorrekturen haben widersprüchliche Endkontexte.');
        }
        latest = candidate;
      }
      if (latest != null) practiceContext = latest.practiceContext;
    }
    final forms = token.lemmaId == null
        ? <String>{}
        : (await _lemmaForms({token.lemmaId!}))[token.lemmaId!] ?? <String>{};
    return StoryLearningCandidate(
      storyId: storyId,
      revision: doc.revision,
      lang: _lang,
      sentence: sentence,
      token: token,
      card: card,
      retired: retired,
      problem: problem,
      practiceContext: practiceContext,
      otherForms: {...forms}..remove(contentFormNorm(token.surface)),
      groupMembers: card?.learning == null
          ? const []
          : (await selectionCards(await allCardIds()))
                .where((c) => c.learningGroup == card!.learningGroup)
                .toList(),
    );
  }

  StoryPracticeContext _readStoryContext(Map<String, dynamic> context, StoryToken source) {
    final text = context['text'] as String;
    final targetIndex = context['target_index'] as int;
    final tokens = <StoryToken>[
      for (final t in context['tokens'])
        StoryToken(index: t['idx'] as int,
          start: _utf16Offset(text, t['start_pos'] as int),
          end: _utf16Offset(text, t['end_pos'] as int), surface: t['surface'] as String,
          lemmaId: t['lemma_id'] as String?, lemma: t['lemma'] as String?,
          pos: t['pos'] as String?, senseId: t['sense_id'] as String?,
          senseKey: t['sense_key'] as String?, gloss: t['gloss'] as String?,
          definition: t['definition'] as String?,
          formFunction: t['idx'] == targetIndex ? source.function : null,
          lexicalTargetId: t['idx'] == targetIndex ? source.lexicalId : null),
    ];
    if (targetIndex < 0 || targetIndex >= tokens.length) {
      throw _broken('Die geprüfte Kontextbindung enthält keine eindeutige Ziellücke.');
    }
    return StoryPracticeContext(StorySentence(id: context['id'] as String,
      text: text, translation: context['translation'] as String,
      paragraph: 0, tokens: tokens), tokens[targetIndex]);
  }

  Future<List<StoryContextCorrection>>? _corrections;

  @override
  Future<List<StoryContextCorrection>> storyContextCorrections() =>
      _corrections ??= _loadStoryContextCorrections();

  Future<List<StoryContextCorrection>> _loadStoryContextCorrections() async {
    final result = <StoryContextCorrection>[];
    final coveredSources = <String>{};
    if (info.schemaVersion >= 5) {
      final edges = await _select('SELECT * FROM story_context_corrections ORDER BY id', []);
      final pending = <StoryContextCorrection>[];
      for (final e in edges) {
        coveredSources.add(e.read<String>('source_key'));
        pending.add(StoryContextCorrection(e.read<String>('introduced_in'),
          decodeStoryCandidate(jsonDecode(e.read<String>('previous_context')) as Map<String,dynamic>),
          decodeStoryCandidate(jsonDecode(e.read<String>('next_context')) as Map<String,dynamic>)));
      }
      // Predecessor edges must be applied before their successors, including
      // branches from identical contexts created in different release versions.
      while (pending.isNotEmpty) {
        final next = pending.where((c) => !pending.any((p) => p.current.sourceFingerprint == c.previous.sourceFingerprint)).toList();
        if (next.isEmpty) throw _broken('Zyklische Storykorrektur.');
        result.addAll(next);pending.removeWhere(next.contains);
      }
    }
    final rows = await _select(
      'SELECT ss.story_id, s.id, s.qa_report FROM story_sentences ss '
      'JOIN sentences s ON s.id=ss.sentence_id JOIN stories st ON st.id=ss.story_id '
      'WHERE s.removed_in IS NULL AND ss.removed_in IS NULL AND st.removed_in IS NULL', []);
    for (final row in rows) {
      final qa = jsonDecode(row.readNullable<String>('qa_report') ?? '{}');
      final review = qa['story_practice_contexts'];
      if (review == null || review['format_version'] != 2) continue;
      for (final b in review['bindings']) {
        final correction = b['correction'];
        if (correction == null) continue;
        final current = await resolveStoryWord(row.read<String>('story_id'),
          row.read<String>('id'), b['token_index'] as int);
        // A correction never converts a global or retired target into a local one.
        if (current.card != null || current.validationProblem() != null) continue;
        if (coveredSources.contains(encodeStoryCandidate(current)['source_key'])) continue;
        if ((correction['version'] as String).isEmpty ||
            (correction['revision'] as String).isEmpty) {
          throw _broken('Ungültige Storykontext-Korrekturversion.');
        }
        final previous = StoryLearningCandidate(storyId: current.storyId,
          revision: correction['revision'] as String, lang: current.lang,
          sentence: current.sentence, token: current.token,
          practiceContext: _readStoryContext(correction['context'] as Map<String, dynamic>, current.token),
          otherForms: current.otherForms);
        if (previous.validationProblem() != null) {
          throw _broken('Ungültiger historischer Storykontext.');
        }
        result.add(StoryContextCorrection(correction['version'] as String, previous, current));
      }
    }
    return List.unmodifiable(result);
  }

}
