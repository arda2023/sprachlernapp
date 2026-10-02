// Pure Dart: no Flutter imports (see CLAUDE.md, domain layer).

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
