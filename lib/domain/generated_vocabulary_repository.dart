/// Private deck IDs include language so activation never leaks across languages.
String generatedVocabularyDeckId(String lang) => 'personal:generated:$lang';

bool isGeneratedVocabularyDeckId(String id) =>
    id.startsWith('personal:generated:');

abstract interface class GeneratedVocabularyRepository {
  Future<Map<String, DateTime>> generatedVocabularyAdditions();
  Future<Set<String>> freeGeneratedVocabularyIds();
}
