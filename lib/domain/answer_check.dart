// Pure Dart: no Flutter imports (see CLAUDE.md, domain layer).

import 'package:unorm_dart/unorm_dart.dart' as unicode;

enum AnswerResult { correct, almost, wrong }

/// Exact match (case-insensitive, trimmed) is correct. A near miss on a
/// word of four or more letters is "fast richtig": a hint, not an error
/// (PRODUCT.md, see [isNearMiss]). Everything else is wrong.
AnswerResult checkAnswer(String input, String expected) {
  final given = normalizeAnswer(input);
  final target = normalizeAnswer(expected);
  if (given == target) return AnswerResult.correct;
  if (isNearMiss(given, target)) return AnswerResult.almost;
  return AnswerResult.wrong;
}

/// The comparison form of an answer: trimmed, lower case, and the
/// typographic apostrophe as `'`, like `form_norm` in the content schema
/// (docs/content-schema.md), so "don’t" from a smart keyboard matches.
String normalizeAnswer(String value, {bool includeDiacritics = true}) {
  final normalized = unicode.nfd(
    value.trim().toLowerCase().replaceAll('’', "'"),
  );
  return unicode.nfc(
    includeDiacritics
        ? normalized
        : normalized.replaceAll(RegExp(r'\p{M}', unicode: true), ''),
  );
}

/// Shortest target form that gets typo tolerance; shorter forms ("the",
/// "an") are checked strictly, since one edit there is usually another word.
const nearMissMinLength = 4;

/// "Fast richtig" (docs/srs.md): [given] differs from [target] by one
/// missing, extra or substituted letter, or by two swapped neighbouring
/// letters, and [target] has at least [nearMissMinLength] letters. Both
/// values are compared as given; normalize them first.
bool isNearMiss(String given, String target) {
  if (given.isEmpty || given == target) return false;
  if (target.length < nearMissMinLength) return false;
  if ((given.length - target.length).abs() > 1) return false;
  return editDistance(given, target) == 1 || _isAdjacentSwap(given, target);
}

bool _isAdjacentSwap(String a, String b) {
  if (a.length != b.length) return false;
  final diff = [
    for (var i = 0; i < a.length; i++)
      if (a[i] != b[i]) i,
  ];
  return diff.length == 2 &&
      diff[1] == diff[0] + 1 &&
      a[diff[0]] == b[diff[1]] &&
      a[diff[1]] == b[diff[0]];
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

/// Verdict for one typed answer on a content card (docs/srs.md,
/// Prüfreihenfolge).
enum AnswerVerdict {
  /// (1) The target form: the gap is solved.
  target,

  /// (2) An alternative pre-checked for exactly this card, sentence and gap:
  /// synonym hint, not solved, not an error.
  alternative,

  /// (3) Another documented form of the same lemma: an error with the lemma hint.
  wrongForm,

  /// (4) A typo of the target form: "Fast richtig", not an error.
  almost,

  /// (5) Anything else: an error.
  wrong,
}

/// Checks [input] locally in the documented order: target form, checked
/// alternative ([alternatives], `card_sentences.valid_alternatives`), another
/// documented form of the same lemma ([otherFormsOfLemma]), typo of the target,
/// anything else. Every comparison uses [normalizeAnswer]; a typo of an
/// alternative is not an alternative.
AnswerVerdict evaluateAnswer(
  String input, {
  required String target,
  Iterable<String> alternatives = const [],
  Iterable<String> otherFormsOfLemma = const [],
  bool includeDiacritics = true,
}) {
  String normalize(String value) =>
      normalizeAnswer(value, includeDiacritics: includeDiacritics);
  final given = normalize(input);
  final goal = normalize(target);
  if (given == goal) return AnswerVerdict.target;
  if (given.isEmpty) return AnswerVerdict.wrong;
  if (alternatives.any((a) => normalize(a) == given)) {
    return AnswerVerdict.alternative;
  }
  if (otherFormsOfLemma.any((f) => normalize(f) == given)) {
    return AnswerVerdict.wrongForm;
  }
  if (isNearMiss(given, goal)) return AnswerVerdict.almost;
  return AnswerVerdict.wrong;
}

/// The neutral synonym hint (PRODUCT.md): the input with a capital first
/// letter, then the first letter of the target form. A one-letter target
/// gives no letter away.
String synonymHint(String input, String target) {
  final shown = input.trim();
  final word = shown.isEmpty
      ? shown
      : shown.substring(0, 1).toUpperCase() + shown.substring(1);
  final goal = target.trim();
  if (goal.runes.length <= 1) {
    return '$word passt hier auch. Gesucht ist ein anderes Wort.';
  }
  final first = String.fromCharCode(goal.runes.first);
  return '$word passt hier auch. Gesucht ist ein anderes Wort: $first…';
}

/// The wrong-form hint (PRODUCT.md): „Andere Form von „go“ – gesucht: Verb,
/// Vergangenheit“. Without a form label only the lemma is named.
String wrongFormHint(String lemma, String? formLabel) =>
    formLabel == null || formLabel.trim().isEmpty
    ? 'Andere Form von „$lemma“'
    : 'Andere Form von „$lemma“ – gesucht: ${formLabel.trim()}';
