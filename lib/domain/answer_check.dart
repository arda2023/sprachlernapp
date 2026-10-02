// Pure Dart: no Flutter imports (see CLAUDE.md, domain layer).

enum AnswerResult { correct, almost, wrong }

/// Exact match (case-insensitive, trimmed) is correct. One edit away on a
/// word of four or more letters is "fast richtig": a hint, not an error
/// (PRODUCT.md). Everything else is wrong.
AnswerResult checkAnswer(String input, String expected) {
  final given = input.trim().toLowerCase();
  final target = expected.trim().toLowerCase();
  if (given == target) return AnswerResult.correct;
  if (target.length >= 4 &&
      given.isNotEmpty &&
      editDistance(given, target) == 1) {
    return AnswerResult.almost;
  }
  return AnswerResult.wrong;
}

/// Levenshtein distance.
int editDistance(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;
  var previous = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final current = List<int>.filled(b.length + 1, 0)..[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      current[j] = [
        previous[j] + 1,
        current[j - 1] + 1,
        previous[j - 1] + cost,
      ].reduce((x, y) => x < y ? x : y);
    }
    previous = current;
  }
  return previous[b.length];
}
