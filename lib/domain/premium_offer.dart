/// The learner's explicit reason for opening an offer; no billing authority.
enum PremiumOfferReason {
  general,
  onboarding,
  stories,
  ownTexts,
  vocabulary,
  translations,
  tutor,
  exercises;

  static PremiumOfferReason fromInterest(String interest) {
    final text = interest.toLowerCase();
    if (text.contains('übersetz')) return translations;
    if (text.contains('eigen') || text.contains('import')) return ownTexts;
    if (text.contains('vokabel') ||
        text.contains('thema') ||
        text.contains('stapel')) {
      return vocabulary;
    }
    if (text.contains('stor') || text.contains('lesen')) return stories;
    if (text.contains('übung') ||
        text.contains('grammatik') ||
        text.contains('hören')) {
      return exercises;
    }
    return general;
  }

  /// The paywall's only headline; no subline (user request 21.11.2026).
  String get title => switch (this) {
    onboarding || general => 'Erreiche mehr\nmit Premium',
    stories => 'Deine nächste\nGeschichte wartet.',
    ownTexts => 'Deine Texte.\nDeine Wörter.',
    vocabulary => 'Wörter für\ndeine Themen.',
    translations => 'Lies weiter.\nVerstehe mehr.',
    tutor => 'Mehr Sätze\nmit Premium',
    exercises => 'Mehr Wege,\nWörter zu üben.',
  };
}
