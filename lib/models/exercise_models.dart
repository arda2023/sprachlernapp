import 'home_models.dart';

enum WordClass { verb, noun, adjective, adverb }

class TextGap {
  const TextGap({
    required this.answer,
    required this.base,
    required this.wordClass,
  });

  /// The form that belongs in the text, e.g. 'dressed'.
  final String answer;

  /// Base word shown as a hint in the gap, e.g. 'dress'.
  final String base;
  final WordClass wordClass;
}

enum ExerciseMode {
  verbs('Lückentext-Übungen: Verben', 'Tippe die passende Verbform'),
  anyWordClass('Beliebige Wortart', 'Wähle das passende Wort aus');

  const ExerciseMode(this.title, this.description);

  final String title;
  final String description;

  bool includes(TextGap gap) =>
      this == anyWordClass || gap.wordClass == WordClass.verb;
}

/// A text with gaps. Paragraphs use a small markup so content stays readable:
/// `{answer|base|class}`, e.g. `He {dressed|dress|verb} slowly.`
class ExerciseText {
  const ExerciseText({
    required this.info,
    required this.paragraphs,
    this.sourceStoryId,
  });

  /// Title, topic, level and reading time, shared with story cards.
  final Story info;
  final List<String> paragraphs;

  /// Set when the text was built from a story ("Aus deinen Stories").
  final String? sourceStoryId;

  String get id => info.id;

  /// Per paragraph: plain text as [String], gaps as [TextGap].
  List<List<Object>> get segments => [for (final p in paragraphs) parseGaps(p)];

  int gapCount(ExerciseMode mode) => [
    for (final paragraph in segments)
      for (final s in paragraph)
        if (s is TextGap && mode.includes(s)) s,
  ].length;
}

final _gapMarkup = RegExp(r'\{([^|}]+)\|([^|}]+)\|(\w+)\}');

List<Object> parseGaps(String markup) {
  final out = <Object>[];
  var last = 0;
  for (final m in _gapMarkup.allMatches(markup)) {
    if (m.start > last) out.add(markup.substring(last, m.start));
    out.add(
      TextGap(
        answer: m[1]!,
        base: m[2]!,
        wordClass: WordClass.values.byName(m[3]!),
      ),
    );
    last = m.end;
  }
  if (last < markup.length) out.add(markup.substring(last));
  return out;
}
