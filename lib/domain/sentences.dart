// Pure Dart: no Flutter imports (see CLAUDE.md, domain layer).

/// A sentence as a half-open character range of its paragraph.
typedef SentenceRange = ({int start, int end});

final _sentence = RegExp(r'''[^.!?]*[.!?]+["'”’)]*\s*|[^.!?]+$''');

/// Splits [paragraph] into sentence ranges that cover it completely, so the
/// pieces join back to the original text. Trailing whitespace belongs to the
/// sentence before it.
List<SentenceRange> splitSentences(String paragraph) => [
  for (final m in _sentence.allMatches(paragraph))
    if (m.end > m.start) (start: m.start, end: m.end),
];

/// Index of the sentence being read aloud at [progress] (0–1) through
/// sentences of the given character [lengths], assuming an even pace. Null
/// when there are no sentences or the end is reached.
int? sentenceAt(List<int> lengths, double progress) {
  final total = lengths.fold(0, (sum, length) => sum + length);
  if (total == 0 || progress >= 1) return null;
  final target = progress.clamp(0, 1) * total;
  var end = 0;
  for (final (i, length) in lengths.indexed) {
    end += length;
    if (target < end) return i;
  }
  return null;
}
