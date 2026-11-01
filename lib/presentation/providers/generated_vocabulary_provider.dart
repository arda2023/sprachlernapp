import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/generated_vocabulary_client.dart';
import '../../data/learning/generated_vocabulary_service.dart';
import '../../data/user/generated_vocabulary_store.dart';
import 'database_providers.dart';
import 'personal_learning_provider.dart';

final generatedVocabularyServiceProvider = FutureProvider<GeneratedVocabularyService>((ref) async {
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
        throw const GeneratedVocabularyFailure('ACCESS_CHANGED',
          'Sprache oder Ansicht geändert. Bitte erneut öffnen.');
      }
    },
  );
}, retry: (_, _) => null);
