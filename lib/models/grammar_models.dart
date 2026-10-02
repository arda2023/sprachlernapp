/// Level filter on the Grammatikregeln screen.
enum GrammarLevel {
  beginner('Anfänger'),
  intermediate('Mittleres Niveau'),
  advanced('Fortgeschrittene');

  const GrammarLevel(this.label);

  final String label;
}

/// An English sentence with its German translation. In [english], the form
/// the rule is about is wrapped in `*…*`, e.g. `I *have lived* here.`
class GrammarExample {
  const GrammarExample(this.english, this.german);

  final String english;
  final String german;
}

/// A common mistake for German speakers: the wrong form, then the right one.
/// Same `*…*` markup as [GrammarExample].
class GrammarPitfall {
  const GrammarPitfall({required this.wrong, required this.right});

  final String wrong;
  final String right;
}

/// One part of a rule. Paragraphs are German prose; English forms inside
/// them are wrapped in `*…*` so the detail screen can set them apart.
class GrammarSection {
  const GrammarSection({
    required this.heading,
    required this.paragraphs,
    this.examples = const [],
    this.pitfall,
  });

  final String heading;
  final List<String> paragraphs;
  final List<GrammarExample> examples;
  final GrammarPitfall? pitfall;
}

/// A grammar rule of the target language, explained in the source language.
/// Language tags are explicit from day one (PRODUCT.md).
class GrammarRule {
  const GrammarRule({
    required this.id,
    required this.title,
    required this.summary,
    required this.level,
    required this.sections,
    this.sourceLanguage = 'de',
    this.targetLanguage = 'en',
  });

  /// Stable slug, so content pack imports stay idempotent.
  final String id;
  final String title;

  /// One line for the list row.
  final String summary;
  final GrammarLevel level;
  final List<GrammarSection> sections;
  final String sourceLanguage;
  final String targetLanguage;

  /// Rough reading time, at least one minute.
  int get minutes {
    final words = sections
        .expand((s) => [...s.paragraphs, for (final e in s.examples) e.english])
        .fold(0, (sum, text) => sum + text.split(' ').length);
    return (words / 120).ceil().clamp(1, 99);
  }
}

/// Splits `*…*` markup into plain and emphasised pieces, in order. An
/// unclosed `*` is kept as plain text.
List<({String text, bool emphasis})> parseEmphasis(String source) {
  final pieces = <({String text, bool emphasis})>[];
  var last = 0;
  for (final m in RegExp(r'\*([^*]+)\*').allMatches(source)) {
    if (m.start > last) {
      pieces.add((text: source.substring(last, m.start), emphasis: false));
    }
    pieces.add((text: m[1]!, emphasis: true));
    last = m.end;
  }
  if (last < source.length) {
    pieces.add((text: source.substring(last), emphasis: false));
  }
  return pieces;
}
