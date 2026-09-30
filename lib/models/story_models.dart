/// Status marks a word can carry in running text. Words without a mark are
/// not in the learner's vocabulary (or not yet shown).
enum WordMark { active, mastered }

/// Dictionary entry for a tapped word. Language tags are explicit from day
/// one (PRODUCT.md), even while only English → German exists.
class WordEntry {
  const WordEntry({
    required this.headword,
    required this.partOfSpeech,
    required this.translation,
    this.sourceLanguage = 'en',
    this.targetLanguage = 'de',
  });

  /// Placeholder until the content pack ships real lookups.
  factory WordEntry.unknown(String surface) => WordEntry(
    headword: surface.toLowerCase(),
    partOfSpeech: 'Wortart folgt',
    translation: 'Übersetzung folgt',
  );

  /// Word-family headword (BNC/COCA), e.g. 'arrive' for 'arrived'.
  final String headword;
  final String partOfSpeech;
  final String translation;
  final String sourceLanguage;
  final String targetLanguage;
}

class StoryText {
  const StoryText({required this.storyId, required this.paragraphs});

  final String storyId;
  final List<String> paragraphs;
}

class ReadingProgress {
  const ReadingProgress({required this.storyId, required this.fraction})
    : assert(fraction >= 0 && fraction <= 1);

  final String storyId;
  final double fraction;
}
