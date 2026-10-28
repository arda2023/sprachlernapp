import 'content.dart';
import 'word_form.dart';

typedef GrammarHint = ({String explanation, List<String> examples});
GrammarHint grammarHint(ContentCard card, {required bool solved}) {
  if (card.lang != 'en') {
    final form = switch (card.formKind) {
      'base' => 'Gesucht ist die Grundform des Verbs.',
      'past_participle' => 'Gesucht ist das Partizip der Vergangenheit.',
      'past' => switch (card.lang) {
        'it' => 'Gesucht ist eine Form des Passato remoto.',
        'es' => 'Gesucht ist eine Form des Pretérito indefinido.',
        'pt-BR' => 'Gesucht ist eine Form des Pretérito perfeito.',
        'nb' => 'Gesucht ist eine Form des Präteritums.',
        _ => 'Gesucht ist eine Vergangenheitsform.',
      },
      _ => 'Setze die gesuchte Wortform in die Lücke ein.',
    };
    return (
      explanation:
          '$form Sprachspezifische Buchstaben und Akzente sind erforderlich.',
      examples: const [],
    );
  }
  final kind = switch (card.formKind) {
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
      explanation: card.formKind == 'past_participle'
          ? 'Gesucht ist ein Partizip der Vergangenheit. Es wird zum Beispiel für Perfektformen mit have verwendet.'
          : 'Setze die angegebene Wortform in die Lücke ein. Eine genauere Erklärung ist für diese Form noch nicht verfügbar.',
      examples: const [],
    );
  }
  final pos = switch (card.pos) {
    'NOUN' => 'Substantiv',
    'VERB' => 'Verb',
    'ADJ' => 'Adjektiv',
    _ => card.pos,
  };
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
