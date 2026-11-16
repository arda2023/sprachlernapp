/// The learner's explicit reason for opening an offer; no billing authority.
enum PremiumOfferReason {
  general,
  onboarding,
  stories,
  ownTexts,
  vocabulary,
  translations,
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

  String get title => switch (this) {
    onboarding || general => 'Mach mehr aus\ndeinen Wörtern.',
    stories => 'Deine nächste\nGeschichte wartet.',
    ownTexts => 'Deine Texte.\nDeine Wörter.',
    vocabulary => 'Wörter für\ndeine Themen.',
    translations => 'Lies weiter.\nVerstehe mehr.',
    exercises => 'Mehr Wege,\nWörter zu üben.',
  };

  String get detail => switch (this) {
    onboarding || general => 'Mehr Stories. Eigene Themen. Lernen im Kontext.',
    stories => 'Entdecke die ganze Bibliothek und lerne beim Lesen.',
    ownTexts => 'Importiere Texte und übe Wörter, die dir begegnen.',
    vocabulary => 'Erstelle weiteren Wortschatz zu dem, was dich interessiert.',
    translations =>
      '500 neue KI-Übersetzungen pro Monat. Packübersetzungen bleiben offline.',
    exercises => 'Lies, höre und übe mit dem vollständigen Angebot.',
  };
}
