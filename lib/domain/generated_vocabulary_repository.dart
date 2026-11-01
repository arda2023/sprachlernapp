/// Private deck IDs include language so activation never leaks across languages.
String generatedVocabularyDeckId(String lang) => 'personal:generated:$lang';

abstract interface class GeneratedVocabularyRepository {
  Future<Map<String, DateTime>> generatedVocabularyAdditions();
}
