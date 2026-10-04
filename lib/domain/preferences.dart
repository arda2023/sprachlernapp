/// Local, versioned preferences. Strict accents preserve the original checker.
enum AppMotif { automatic, light, dark }

class PracticePreferences {
  const PracticePreferences({
    this.motif = AppMotif.automatic,
    this.dailyGoal = 10,
    this.includeDiacritics = true,
    this.autoNext = false,
    this.showGrammar = false,
  });
  final AppMotif motif;
  final int dailyGoal;
  final bool includeDiacritics, autoNext, showGrammar;
  PracticePreferences copyWith({
    AppMotif? motif,
    int? dailyGoal,
    bool? includeDiacritics,
    bool? autoNext,
    bool? showGrammar,
  }) => PracticePreferences(
    motif: motif ?? this.motif,
    dailyGoal: dailyGoal ?? this.dailyGoal,
    includeDiacritics: includeDiacritics ?? this.includeDiacritics,
    autoNext: autoNext ?? this.autoNext,
    showGrammar: showGrammar ?? this.showGrammar,
  );
}

class LocalSubmission {
  const LocalSubmission({
    required this.id,
    required this.createdAt,
    required this.text,
    this.category,
    this.rating,
    this.cardId,
    this.sentenceId,
    this.packVersion,
  });
  final String id, text;
  final DateTime createdAt;
  final String? category, cardId, sentenceId, packVersion;
  final int? rating;
  String get exportText => [
    category == null ? 'Sprachapp – Feedback' : 'Sprachapp – Problembericht',
    'Lokal gespeichert: ${createdAt.toIso8601String()}',
    if (category != null) 'Kategorie: $category',
    if (rating != null) 'Bewertung: $rating/5',
    if (cardId != null) 'Karte: $cardId',
    if (sentenceId != null) 'Satz: $sentenceId',
    if (packVersion != null) 'Pack: $packVersion',
    text,
  ].join('\n');
}
