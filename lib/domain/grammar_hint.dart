import 'content.dart';
import 'language_profile.dart';
import 'part_of_speech.dart';
import 'word_form.dart';

typedef GrammarHint = ({String explanation, List<String> examples});
GrammarHint grammarHint(ContentCard card, {required bool solved}) {
  final kind = card.lang != 'en'
      ? null
      : switch (card.formKind) {
          'base' => FormKind.base,
          'plural' => FormKind.plural,
          'past' => FormKind.past,
          'present_participle' => FormKind.ing,
          'third_person' => FormKind.thirdPerson,
          'comparative' => FormKind.comparative,
          'superlative' => FormKind.superlative,
          _ => null,
        };
  if (kind == null) {
    return (
      explanation: card.lang == 'en' && card.formKind == 'past_participle'
          ? 'Gesucht ist ein Partizip der Vergangenheit. Es wird zum Beispiel für Perfektformen mit have verwendet.'
          // Other languages, and English forms without a worked
          // explanation, get the description built from the card itself.
          : _cardHint(card, solved: solved),
      examples: const <String>[],
    );
  }
  final pos = germanPartOfSpeech(card.pos);
  final full = kind == FormKind.thirdPerson
      ? 'Gesucht ist ein Verb in der 3. Person Singular: die Form für he, she oder it. Regelmäßige Verben erhalten meist -s (she works).'
      : formExplanation(pos, kind);
  final examples = RegExp(r'\(([^)]+)\)')
      .allMatches(full)
      .map((m) => m[1]!)
      .where(
        (s) =>
            s != 'Simple Past' &&
            (solved || !s.toLowerCase().contains(card.form.toLowerCase())),
      )
      .toList();
  return (
    explanation: full.replaceAll(RegExp(r'\s*\([^)]+\)'), ''),
    examples: examples,
  );
}

/// What the gap asks for, from the card's word class, form and language:
/// "Gesucht ist ein Substantiv in der Einzahl." plus what the word class
/// does and the letters the language needs. It never names the answer;
/// once solved it adds the dictionary form.
String _cardHint(ContentCard card, {required bool solved}) {
  final pos = germanPartOfSpeech(card.pos);
  final known = pos != card.pos;
  final function = card.formFunction ?? card.formKind;
  final base = function == 'base' ||
      (function == null && contentFormNorm(card.form) == contentFormNorm(card.lemma));
  final form = switch (function) {
    'plural' => ' in der Mehrzahl',
    'past' => ' in der Vergangenheit',
    'past_participle' => ' als Partizip Perfekt',
    'present_participle' => ' als Partizip Präsens',
    'third_person' => ' in der 3. Person Singular',
    'comparative' => ' im Komparativ',
    'superlative' => ' im Superlativ',
    _ when base => switch (card.pos.toUpperCase()) {
      'NOUN' => ' in der Einzahl',
      'VERB' || 'AUX' => ' in der Grundform (Infinitiv)',
      _ => ' in der Grundform',
    },
    _ => ', aber nicht in der Grundform',
  };
  final article = const {'Präposition', 'Konjunktion', 'Subjunktion', 'Partikel'}.contains(pos)
      ? 'eine'
      : 'ein';
  final label = card.formLabelDe;
  final parts = [
    known ? 'Gesucht ist $article $pos$form.' : 'Gesucht ist ein Wort$form.',
    ?partOfSpeechRole(card.pos),
    if (label != null && label != card.pos && germanPartOfSpeech(label) != pos)
      'Form: $label.',
    ?_letters(card.lang),
    if (solved && !base) 'Grundform: „${card.lemma}“.',
  ];
  return parts.join(' ');
}

/// The language's own letters, which belong to a correct answer.
String? _letters(String lang) {
  final letters = switch (lang.split('-').first.toLowerCase()) {
    'pt' => 'ã, õ, ç, á, â, é, ê, í, ó, ô, ú',
    'it' => 'à, è, é, ì, ò, ù',
    'es' => 'á, é, í, ó, ú, ñ, ü',
    'fr' => 'à, â, ç, é, è, ê, ë, î, ï, ô, ù, û',
    'nb' || 'nn' || 'no' || 'da' => 'æ, ø, å',
    'sv' => 'å, ä, ö',
    'de' => 'ä, ö, ü, ß',
    _ => null,
  };
  if (letters == null) return null;
  final required = ContentLanguageProfile.forLanguage(lang)?.requiresDiacritics ?? true;
  return required
      ? 'Akzente und Sonderzeichen gehören zur richtigen Antwort: $letters.'
      : 'Achte auf Akzente und Sonderzeichen: $letters.';
}
