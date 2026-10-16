/// Reader capability declaration. It does not change answer classification.
class ContentLanguageProfile {
  const ContentLanguageProfile(this.lang, this.id, this.sha256);
  final String lang, id, sha256;

  static const english = ContentLanguageProfile(
    'en',
    'en-legacy-v1',
    '59eec37d0a4f322d666701e00bc1bf4cfb44d19b183b1742d16b443989a505cf',
  );

  static ContentLanguageProfile? forLanguage(String lang) =>
      lang == 'en' ? english : null;
}
