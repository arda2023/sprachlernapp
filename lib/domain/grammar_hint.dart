import 'content.dart';
import 'word_form.dart';

typedef GrammarHint = ({String explanation, List<String> examples});
GrammarHint grammarHint(ContentCard card, {required bool solved}) {
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
