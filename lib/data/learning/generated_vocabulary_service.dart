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
  GeneratedVocabularyService({
    required this.client,
    required this.store,
    required this.verify,
    this.verifyPaid,
  });
  final GeneratedVocabularyClient client;
  final GeneratedVocabularyStore store;
  final void Function() verify;
  final void Function()? verifyPaid;

  Future<T?> _forPendingOwner<T>(
    Future<T?> Function(String owner, void Function() verify) action,
  ) async {
    final access = client.access;
    final revision = access.revision();
    void current() {
      verify();
      if (revision != access.revision()) {
        throw const GeneratedVocabularyFailure(
          'ACCESS_CHANGED',
          'Konto geändert. Bitte erneut öffnen.',
        );
      }
    }

    current();
    final owner = await access.owner();
    current();
    if (owner == null) return null;
    final result = await action(owner, current);
    current();
    return result;
  }

  Future<GeneratedVocabularyRequest?> pendingFreeRequest() =>
      _forPendingOwner<GeneratedVocabularyRequest>(
        (owner, _) => store.pendingRequest(owner),
      );

  Future<GeneratedVocabularyRequest> stageFreeRequest(
    GeneratedVocabularyRequest request,
  ) async =>
      await _forPendingOwner(
        (owner, current) =>
            store.stagePendingRequest(owner, request, verify: current),
      ) ??
      request;

  Future<void> clearFreeRequest(String requestId) async {
    await _forPendingOwner(
      (owner, _) => store.clearPendingRequest(owner, requestId),
    );
  }

  Future<GeneratedVocabularyDraft> generate(
    GeneratedVocabularyRequest request, {
    bool statusOnly = false,
  }) async {
    verify();
    if (request.lang != store.lang) throw StateError('Sprache geändert.');
    final access = client.access;
    final epoch = access.revision(), consentEpoch = access.consentRevision;
    void current() {
      verify();
      if (epoch != access.revision() ||
          consentEpoch != access.consentRevision) {
        throw const GeneratedVocabularyFailure(
          'ACCESS_CHANGED',
          'Konto oder KI-Freigabe geändert. Bitte erneut öffnen.',
        );
      }
    }

    current();
    final response = await client.generate(request, statusOnly: statusOnly);
    void verifyDraft() {
      current();
      if (!response.freeSample) verifyPaid?.call();
    }

    verifyDraft();
    final ids = response.freeSample
        ? await store.freeIds()
        : (await store.additions()).keys.toSet();
    final rows = await (store.db.select(
      store.db.userCards,
    )..where((t) => t.lang.equals(store.lang) & t.cardId.isIn(ids))).get();
    verifyDraft();
    return GeneratedVocabularyDraft(response, {
      for (final row in rows)
        if (row.formNorm != null) row.formNorm!,
    }, verifyDraft);
  }

  Future<bool> hasDeck() async {
    verify();
    final exists = (await store.additions()).isNotEmpty;
    verify();
    return exists;
  }

  Future<GeneratedVocabularySaveResult> save(
    GeneratedVocabularyDraft draft,
    Set<int> selected,
  ) async {
    verify();
    draft.verify();
    if (!await client.access.consent()) {
      throw const GeneratedVocabularyFailure(
        'CONSENT_REQUIRED',
        'KI-Freigabe geändert.',
      );
    }
    draft.verify();
    return store.save(
      draft.response,
      selected: selected,
      now: DateTime.now(),
      verify: () {
        verify();
        draft.verify();
      },
    );
  }
}
