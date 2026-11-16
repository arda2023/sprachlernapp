import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/generated_vocabulary_client.dart';
import '../../data/learning/generated_vocabulary_service.dart';
import '../../data/user/generated_vocabulary_store.dart';
import '../../domain/generated_vocabulary.dart';
import 'auth_providers.dart';
import 'database_providers.dart';
import 'personal_learning_provider.dart';
import 'premium_access_provider.dart';

final freeVocabularyGenerationAvailableProvider = FutureProvider<bool?>((
  ref,
) async {
  final session = ref.watch(accountSessionProvider).asData?.value;
  final auth = ref.watch(contentAuthProvider);
  if (session == null || !auth.configured) return null;
  return auth.freeVocabularyGenerationAvailable();
}, retry: (_, _) => null);

final pendingGeneratedVocabularyRequestProvider = FutureProvider.autoDispose
    .family<GeneratedVocabularyRequest?, String>((ref, lang) async {
      if (ref.watch(accountSessionProvider).asData?.value == null ||
          await ref.watch(selectedContentLanguageProvider.future) != lang) {
        return null;
      }
      final service = await ref.watch(
        generatedVocabularyServiceProvider.future,
      );
      return service.pendingFreeRequest();
    }, retry: (_, _) => null);

final generatedVocabularyServiceProvider =
    FutureProvider<GeneratedVocabularyService>((ref) async {
      var current = true;
      ref.onDispose(() => current = false);
      final lang = await ref.watch(selectedContentLanguageProvider.future);
      final db = await ref.watch(userDatabaseProvider.future);
      final access = ref.watch(personalLearningClientProvider);
      return GeneratedVocabularyService(
        client: GeneratedVocabularyClient(access: access),
        store: GeneratedVocabularyStore(db, lang: lang),
        verify: () {
          if (!current) {
            throw const GeneratedVocabularyFailure(
              'ACCESS_CHANGED',
              'Sprache oder Ansicht geändert. Bitte erneut öffnen.',
            );
          }
        },
        verifyPaid: () {
          if (current && ref.read(premiumContentAccessProvider)) return;
          throw const GeneratedVocabularyFailure(
            'PREMIUM_REQUIRED',
            'Weitere Vokabelthemen benötigen Premium.',
          );
        },
      );
    }, retry: (_, _) => null);
