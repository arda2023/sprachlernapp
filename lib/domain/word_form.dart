// Pure Dart: no Flutter imports (see CLAUDE.md, domain layer).

/// Where a headword's form sits in a sentence, as a half-open range.
typedef WordForm = ({int start, int end, String text});

final _token = RegExp(r"[A-Za-z]+(?:['’][A-Za-z]+)*");

/// Endings a regular inflection may add to a stem (BNC/COCA word families:
/// plural, 3rd person, past, -ing, comparative).
const _endings = [
  '',
  's',
  'es',
  'd',
  'ed',
  'ing',
  'r',
  'er',
  'est',
  'ies',
  'ied',
];

/// Finds the first token of [sentence] that is [headword] or a regular
/// inflection of it ("neighbour" → "neighbours", "arrive" → "arrived",
/// "city" → "cities"), case-insensitive. Irregular forms ("buy" → "bought")
/// return null until the content pack marks the gap explicitly.
WordForm? findWordForm(String sentence, String headword) {
  final head = headword.toLowerCase();
  final stems = {
    head,
    if (head.length > 3 && head.endsWith('e'))
      head.substring(0, head.length - 1),
    if (head.length > 3 && head.endsWith('y'))
      head.substring(0, head.length - 1),
  };
  for (final m in _token.allMatches(sentence)) {
    final token = m[0]!.toLowerCase();
    for (final stem in stems) {
      if (token.startsWith(stem) &&
          _endings.contains(token.substring(stem.length))) {
        return (start: m.start, end: m.end, text: m[0]!);
      }
    }
  }
  return null;
}

/// The grammatical form a sentence uses, as far as regular endings tell.
enum FormKind {
  base,
  plural,
  past,
  ing,
  thirdPerson,
  comparative,
  superlative;

  /// German name, as it follows the word class ("Substantiv, Plural").
  String? get label => switch (this) {
    base => null,
    plural => 'Plural',
    past => 'Vergangenheit',
    ing => '-ing-Form',
    thirdPerson => '3. Person Singular',
    comparative => 'Komparativ',
    superlative => 'Superlativ',
  };
}

/// Which form of [headword] the sentence uses. [partOfSpeech] is the German
/// label of the entry ("Substantiv", "Verb", "Adjektiv").
FormKind formKindOf(String partOfSpeech, String headword, String form) {
  final head = headword.toLowerCase();
  final f = form.toLowerCase();
  if (f == head) return FormKind.base;
  return switch (partOfSpeech) {
    'Substantiv' when f.endsWith('s') => FormKind.plural,
    'Verb' when f.endsWith('ing') => FormKind.ing,
    'Verb' when f.endsWith('ed') || f.endsWith('ied') => FormKind.past,
    'Verb' when f.endsWith('s') => FormKind.thirdPerson,
    'Adjektiv' when f.endsWith('est') => FormKind.superlative,
    'Adjektiv' when f.endsWith('er') => FormKind.comparative,
    _ => FormKind.base,
  };
}

/// Word class plus the form the sentence uses, e.g. "Substantiv, Plural" or
/// "Verb, Vergangenheit".
String formLabel(String partOfSpeech, String headword, String form) {
  final kind = formKindOf(partOfSpeech, headword, form).label;
  return kind == null ? partOfSpeech : '$partOfSpeech, $kind';
}

/// A short German explanation of what the gap asks for. It never contains
/// the answer, so it can be shown before the word is known. Examples use
/// words outside the v1 practice list.
String formExplanation(String partOfSpeech, FormKind kind) => switch (kind) {
  FormKind.plural =>
    'Gesucht ist ein Substantiv in der Mehrzahl. Meist hängst du -s an '
        '(book → books), nach s, x, ch und sh -es (box → boxes).',
  FormKind.past =>
    'Gesucht ist ein Verb in der Vergangenheit (Simple Past). Regelmäßige '
        'Verben enden auf -ed (walk → walked).',
  FormKind.ing =>
    'Gesucht ist die -ing-Form eines Verbs, etwa für eine Handlung, die '
        'gerade läuft (she is reading).',
  FormKind.thirdPerson =>
    'Gesucht ist ein Verb in der 3. Person Singular. Im Simple Present '
        'kommt nach he, she und it ein -s dazu (she works).',
  FormKind.comparative =>
    'Gesucht ist ein Adjektiv im Komparativ. Kurze Adjektive enden auf -er '
        '(cold → colder).',
  FormKind.superlative =>
    'Gesucht ist ein Adjektiv im Superlativ. Kurze Adjektive enden auf -est '
        '(cold → the coldest).',
  FormKind.base => switch (partOfSpeech) {
    'Substantiv' => 'Gesucht ist ein Substantiv in der Einzahl.',
    'Verb' =>
      'Gesucht ist ein Verb in der Grundform, wie sie etwa nach can, will '
          'oder to steht.',
    'Adjektiv' => 'Gesucht ist ein Adjektiv in der Grundform.',
    _ => 'Gesucht ist ein Wort der Wortart „$partOfSpeech“.',
  },
};
