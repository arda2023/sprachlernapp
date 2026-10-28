/// Immutable reader and answer capabilities for a content language.
class ContentLanguageProfile {
  const ContentLanguageProfile(this.lang, this.id, this.sha256);
  final String lang, id, sha256;

  String get displayName => switch (lang) {
    'en' => 'Englisch',
    'pt-BR' => 'Portugiesisch (Brasilien)',
    'nb' => 'Norwegisch (Bokmål)',
    'it' => 'Italienisch',
    'es' => 'Spanisch',
    _ => lang,
  };
  String get flag => switch (lang) {
    'en' => '🇬🇧',
    'pt-BR' => '🇧🇷',
    'nb' => '🇳🇴',
    'it' => '🇮🇹',
    'es' => '🇪🇸',
    _ => '',
  };
  bool get requiresDiacritics => lang != 'en';

  static const english = ContentLanguageProfile(
    'en',
    'en-legacy-v1',
    '59eec37d0a4f322d666701e00bc1bf4cfb44d19b183b1742d16b443989a505cf',
  );

  /// Kept immutable so installed releases and historical revisions still open.
  static const portugueseBrazilV1 = ContentLanguageProfile(
    'pt-BR',
    'pt-BR-editorial-v1',
    '7c59364c0d1ef562ee5a6a679b7d895e0ebec6bf2ad47d8eae56afdcba87fe32',
  );
  static const portugueseBrazil = ContentLanguageProfile(
    'pt-BR',
    'pt-BR-editorial-v2',
    '304d086c7d53956babe9bb27ff306de20849971670f402d07a5add9ea9c0c04b',
  );
  static const norwegian = ContentLanguageProfile(
    'nb',
    'nb-editorial-v1',
    'b8886ad2d29b0e5f437a11673cf4eafb38851e05f6add41c3e9825c65b346f85',
  );
  static const italian = ContentLanguageProfile(
    'it',
    'it-editorial-v1',
    '4b1424f02189910755ddb165b903eb8bafb9fcd637554838490620c3bb57965a',
  );
  static const spanish = ContentLanguageProfile(
    'es',
    'es-editorial-v1',
    'b5f925882e20fc15147cafbc881f2e510dcd56cb0d085eb420e6197efc97771f',
  );

  static const selectable = [
    english,
    portugueseBrazil,
    norwegian,
    italian,
    spanish,
  ];

  static ContentLanguageProfile? forLanguage(String lang) => switch (lang) {
    'en' => english,
    'pt-BR' => portugueseBrazil,
    'nb' => norwegian,
    'it' => italian,
    'es' => spanish,
    _ => null,
  };

  /// Only explicitly supported profile revisions, never arbitrary pack hashes.
  static List<ContentLanguageProfile> supportedForLanguage(String lang) {
    final current = forLanguage(lang);
    return [?current, if (lang == 'pt-BR') portugueseBrazilV1];
  }

  static ContentLanguageProfile? resolve(
    String lang,
    Object? id,
    Object? sha256,
  ) {
    for (final profile in supportedForLanguage(lang)) {
      if (profile.id == id && profile.sha256 == sha256) return profile;
    }
    return null;
  }
}
