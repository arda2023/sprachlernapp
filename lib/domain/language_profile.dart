/// Immutable reader and answer capabilities for a content language.
class ContentLanguageProfile {
  const ContentLanguageProfile(this.lang, this.id, this.sha256);
  final String lang, id, sha256;

  String get displayName => switch (lang) {
    'pt-BR' => 'Portugiesisch (Brasilien)',
    'en' => 'Englisch',
    _ => lang,
  };

  /// Shown before the name in the language pill and picker.
  String get flag => switch (lang) {
    'pt-BR' => '🇧🇷',
    'en' => '🇬🇧',
    _ => '🏳️',
  };

  bool get requiresDiacritics => lang == 'pt-BR';

  static const english = ContentLanguageProfile(
    'en',
    'en-legacy-v1',
    '59eec37d0a4f322d666701e00bc1bf4cfb44d19b183b1742d16b443989a505cf',
  );

  static const portugueseBrazil = ContentLanguageProfile(
    'pt-BR',
    'pt-BR-editorial-v1',
    '7c59364c0d1ef562ee5a6a679b7d895e0ebec6bf2ad47d8eae56afdcba87fe32',
  );

  /// Every selectable learning language, in picker order. Home's language
  /// pill and Settings both list exactly these, so a new profile only has
  /// to be added here.
  static const supported = [english, portugueseBrazil];

  static ContentLanguageProfile? forLanguage(String lang) {
    for (final profile in supported) {
      if (profile.lang == lang) return profile;
    }
    return null;
  }
}
