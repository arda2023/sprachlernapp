import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/generated_vocabulary.dart';
import '../../domain/generated_vocabulary_repository.dart';
import '../../domain/personal_learning.dart';
import '../../domain/story_learning.dart';
import 'user_database.dart';

class GeneratedVocabularySaveResult {
  const GeneratedVocabularySaveResult(
    this.addedIds,
    this.existingIds,
    this.blockedForms,
  );
  final List<String> addedIds, existingIds, blockedForms;
  int get savedCount => addedIds.length + existingIds.length;
}

/// One fixed local context per saved word. This collection never rewrites a
/// learned card, infers a link to a pack sense, or creates story membership.
class GeneratedVocabularyStore {
  GeneratedVocabularyStore(this.db, {required this.lang});
  final UserDatabase db;
  final String lang;

  Future<Map<String, DateTime>> additions() async => {
    for (final row
        in await (db.select(db.generatedVocabularyAdditions)
              ..where((t) => t.lang.equals(lang))
              ..orderBy([
                (t) => OrderingTerm.asc(t.addedAt),
                (t) => OrderingTerm.asc(t.cardId),
              ]))
            .get())
      row.cardId: row.addedAt.toLocal(),
  };

  Future<GeneratedVocabularySaveResult> save(
    GeneratedVocabularyResponse response, {
    required Set<int> selected,
    required DateTime now,
    required void Function() verify,
  }) => db.transaction(() async {
    verify();
    if (response.lang != lang ||
        selected.isEmpty ||
        selected.any((i) => i < 0 || i >= response.items.length)) {
      throw const FormatException('Ungültige Auswahl oder Sprache.');
    }
    final added = <String>[], existing = <String>[], blocked = <String>[];
    final memberships = await additions();
    final rows = await (db.select(
      db.userCards,
    )..where((t) => t.lang.equals(lang))).get();
    // One entry per spelling in this collection. A new model wording must not
    // silently create a second review schedule for a word already selected.
    final saved = {
      for (final row in rows)
        if (memberships.containsKey(row.cardId)) row.formNorm: row,
    };
    for (final index in selected.toList()..sort()) {
      final item = response.items[index];
      // Conservative form guard: generation cannot bypass disabled/retired
      // meanings through a new provider definition or a new request UUID.
      if (rows.any(
        (r) => r.formNorm == item.formNorm && (r.disabled || r.retired),
      )) {
        blocked.add(item.form);
        continue;
      }
      final prior = saved[item.formNorm];
      if (prior != null) {
        final context =
            await (db.select(db.cardContexts)..where(
                  (t) =>
                      t.id.equals(prior.primaryContextId ?? '') &
                      t.cardId.equals(prior.cardId) &
                      t.lang.equals(lang),
                ))
                .getSingleOrNull();
        if (context == null)
          throw StateError('Gespeicherter Übungssatz fehlt.');
        existing.add(prior.cardId);
        continue;
      }
      final lexical = item.identity(lang);
      final id = 'u:$lexical';
      final contextId = learningHash(['generated-context-v1', id]);
      // Deterministic IDs make repeated saves idempotent without replacing any
      // immutable context or resetting box/due dates, flags, notes or reviews.
      await db
          .into(db.userCards)
          .insert(
            UserCardsCompanion.insert(
              cardId: id,
              lang: lang,
              box: 0,
              createdAt: now.toUtc(),
              origin: 'deck',
              updatedAt: now.toUtc(),
              localOnly: const Value(true),
              form: Value(item.form),
              formNorm: Value(item.formNorm),
              glossDe: Value(item.glossDe),
              lemma: Value(item.lemma),
              pos: Value(item.pos),
              lemmaIdentity: Value(
                learningHash([
                  'generated-lemma-v1',
                  lang,
                  item.lemma,
                  item.pos,
                ]),
              ),
              senseIdentity: Value('generated:$lexical'),
              senseKey: Value(item.definitionDe),
              primaryContextId: Value(contextId),
            ),
          );
      await db
          .into(db.cardContexts)
          .insert(
            CardContextsCompanion.insert(
              id: contextId,
              cardId: id,
              textValue: item.sentence,
              translationDe: item.translationDe,
              gapStart: item.start,
              gapEnd: item.end,
              sourceRef: generatedVocabularyDeckId(lang),
              sentenceRef: response.requestId,
              tokenIndex: personalWords(item.sentence)
                  .toList()
                  .indexWhere((t) => t.start == item.start),
              revision: jsonEncode({
                'contract': 1,
                'form_detail': item.formDetail,
              }),
              fingerprint: learningHash([
                'generated-source-v1',
                id,
                item.sentence,
              ]),
              tokensJson: jsonEncode([
                for (final token in personalWords(item.sentence))
                  {
                    'start': token.start,
                    'end': token.end,
                    'surface': token[0],
                    'translation': token.start == item.start
                        ? item.glossDe
                        : null,
                  },
              ]),
              otherFormsJson: '[]',
              lang: lang,
              provenance: 'generated_haiku_v1',
              createdAt: now.toUtc(),
            ),
          );
      await db
          .into(db.generatedVocabularyAdditions)
          .insert(
            GeneratedVocabularyAdditionsCompanion.insert(
              cardId: id,
              lang: lang,
              addedAt: now.toUtc(),
            ),
          );
      added.add(id);
    }
    if (added.isNotEmpty) {
      // Explicit creation activates this private deck once. A later save never
      // overwrites the learner's decision to deactivate it.
      await db
          .into(db.deckSettings)
          .insert(
            DeckSettingsCompanion.insert(
              deckId: generatedVocabularyDeckId(lang),
              active: true,
              updatedAt: now.toUtc(),
            ),
            mode: InsertMode.insertOrIgnore,
          );
    }
    verify(); // A changed account, consent or language rolls back the whole batch.
    return GeneratedVocabularySaveResult(
      List.unmodifiable(added),
      List.unmodifiable(existing),
      List.unmodifiable(blocked),
    );
  });
}
