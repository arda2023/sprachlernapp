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
