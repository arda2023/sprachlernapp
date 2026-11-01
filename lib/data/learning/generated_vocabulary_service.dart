import 'package:drift/drift.dart';

import '../../domain/generated_vocabulary.dart';
import '../generated_vocabulary_client.dart';
import '../user/generated_vocabulary_store.dart';

class GeneratedVocabularyDraft {
  GeneratedVocabularyDraft(this.response, this.existingForms, this.verify);
  final GeneratedVocabularyResponse response;
  final Set<String> existingForms;
  final void Function() verify;
}

/// Keeps a preview bound to the account, consent and language that requested it.
class GeneratedVocabularyService {
  GeneratedVocabularyService({required this.client, required this.store, required this.verify});
  final GeneratedVocabularyClient client;
  final GeneratedVocabularyStore store;
  final void Function() verify;

  Future<GeneratedVocabularyDraft> generate(GeneratedVocabularyRequest request,
      {bool statusOnly = false}) async {
    verify();
    if (request.lang != store.lang) throw StateError('Sprache geändert.');
    final access = client.access;
    final epoch = access.revision(), consentEpoch = access.consentRevision;
    void current() {
      verify();
      if (epoch != access.revision() || consentEpoch != access.consentRevision) {
        throw const GeneratedVocabularyFailure('ACCESS_CHANGED',
          'Konto oder KI-Freigabe geändert. Bitte erneut öffnen.');
      }
    }
    current();
    final response = await client.generate(request, statusOnly: statusOnly);
    current();
    final ids = (await store.additions()).keys.toSet();
    final rows = await (store.db.select(store.db.userCards)
      ..where((t) => t.lang.equals(store.lang) & t.cardId.isIn(ids))).get();
    current();
    return GeneratedVocabularyDraft(response,
      {for (final row in rows) if (row.formNorm != null) row.formNorm!}, current);
  }

  Future<bool> hasDeck() async {
    verify();
    final exists = (await store.additions()).isNotEmpty;
    verify();
    return exists;
  }

  Future<GeneratedVocabularySaveResult> save(GeneratedVocabularyDraft draft, Set<int> selected) async {
    verify();
    draft.verify();
    if (!await client.access.consent()) {
      throw const GeneratedVocabularyFailure('CONSENT_REQUIRED', 'KI-Freigabe geändert.');
    }
    draft.verify();
    return store.save(draft.response, selected: selected, now: DateTime.now(), verify: () {
      verify();
      draft.verify();
    });
  }
}
