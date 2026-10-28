// Pure Dart: no Flutter imports (see CLAUDE.md, domain layer).

/// German name of a Universal Dependencies word class ("NOUN" →
/// "Substantiv"). Content packs store the raw tag; learners never see it.
/// Anything that is not a known tag (e.g. an editorial label such as
/// "Verb, Vergangenheit") is returned unchanged.
String germanPartOfSpeech(String tag) => switch (tag.trim().toUpperCase()) {
  'NOUN' => 'Substantiv',
  'PROPN' => 'Eigenname',
  'VERB' => 'Verb',
  'AUX' => 'Hilfsverb',
  'ADJ' => 'Adjektiv',
  'ADV' => 'Adverb',
  'PRON' => 'Pronomen',
  'DET' => 'Begleiter',
  'ADP' => 'Präposition',
  'CCONJ' => 'Konjunktion',
  'SCONJ' => 'Subjunktion',
  'NUM' => 'Zahlwort',
  'PART' => 'Partikel',
  'INTJ' => 'Ausruf',
  _ => tag,
};

/// One sentence on what the word class does, for the form info. Null for
/// tags without a short, safe explanation.
String? partOfSpeechRole(String tag) => switch (tag.trim().toUpperCase()) {
  'NOUN' =>
    'Ein Substantiv benennt eine Person, ein Ding, einen Ort oder einen Begriff.',
  'PROPN' => 'Ein Eigenname bezeichnet eine bestimmte Person, einen Ort oder eine Marke.',
  'VERB' => 'Ein Verb beschreibt, was jemand tut oder was geschieht.',
  'AUX' =>
    'Ein Hilfsverb bildet zusammen mit einem anderen Verb Zeiten oder das Passiv.',
  'ADJ' => 'Ein Adjektiv beschreibt, wie jemand oder etwas ist.',
  'ADV' => 'Ein Adverb sagt, wie, wann, wo oder wie oft etwas geschieht.',
  'PRON' => 'Ein Pronomen steht für ein Substantiv, etwa ich, sie oder das.',
  'DET' => 'Ein Begleiter steht vor einem Substantiv, etwa ein Artikel.',
  'ADP' => 'Eine Präposition verbindet Wörter, etwa für Ort oder Zeit.',
  'CCONJ' || 'SCONJ' => 'Eine Konjunktion verbindet Wörter oder Satzteile.',
  'NUM' => 'Ein Zahlwort nennt eine Menge oder eine Reihenfolge.',
  _ => null,
};
