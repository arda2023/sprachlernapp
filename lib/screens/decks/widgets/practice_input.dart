import 'package:flutter/material.dart';

import '../../../domain/answer_check.dart';

/// After a wrong answer: [firstWrong] keeps the letters, [prefix] shows the
/// start (2nd) or the whole word (3rd) until typing starts, [ghost] keeps
/// the whole word faintly behind what is typed (4th on, user request
/// 31.10.2026).
enum InputFeedback { typing, firstWrong, prefix, ghost, revealed }

String targetPrefix(String target) {
  final letters = target.characters;
  return '${letters.take(letters.length > 2
      ? 2
      : letters.length == 2
      ? 1
      : 0)}…';
}

/// Keeps the submitted answer separate from a non-editable hint. On the first
/// IME edit after feedback only the edit's replacement survives, with selection
/// and composing offsets translated into the new attempt.
class PracticeInputController extends TextEditingController {
  InputFeedback feedback = InputFeedback.typing;
  String lastChecked = '', hint = '', target = '';
  int ordinaryErrors = 0;
  int textRevision = 0;
  Color blue = const Color(0xFF7DB2E0),
      red = const Color(0xFFD9726B),
      neutral = const Color(0xFF8E95A5);

  void showWrong(String answer, String goal) {
    lastChecked = answer;
    target = goal;
    ordinaryErrors++;
    feedback = switch (ordinaryErrors) {
      1 => InputFeedback.firstWrong,
      2 || 3 => InputFeedback.prefix,
      _ => InputFeedback.ghost,
    };
    hint = switch (ordinaryErrors) {
      1 => '',
      2 => targetPrefix(goal),
      _ => goal,
    };
    super.value = TextEditingValue(
      text: ordinaryErrors == 1 ? answer : '',
      selection: TextSelection.collapsed(
        offset: ordinaryErrors == 1 ? answer.length : 0,
      ),
    );
    notifyListeners();
  }

  void showReveal(String goal) {
    feedback = InputFeedback.revealed;
    hint = goal;
    super.value = TextEditingValue.empty;
    notifyListeners();
  }

  /// The faint word behind the field in [InputFeedback.ghost].
  String get ghost => feedback == InputFeedback.ghost ? hint : '';

  void reset() {
    feedback = InputFeedback.typing;
    lastChecked = hint = target = '';
    ordinaryErrors = 0;
    super.value = TextEditingValue.empty;
    notifyListeners();
  }

  /// A recognizer replaces the whole answer, rather than applying an IME diff.
  /// In particular, repeated letters after a wrong answer must not be stripped.
  void replaceFromDictation(String text) {
    if (feedback != InputFeedback.ghost) {
      feedback = InputFeedback.typing;
      hint = '';
    }
    textRevision++;
    final previous = super.value;
    super.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    if (super.value == previous) notifyListeners();
  }

  @override
  set value(TextEditingValue next) {
    final previous = super.value;
    final edited = next.text != previous.text;
    if (edited) textRevision++;
    // The ghost word stays while typing; every other hint goes.
    if (feedback != InputFeedback.typing &&
        feedback != InputFeedback.ghost &&
        next.text != previous.text) {
      if (feedback == InputFeedback.firstWrong) {
        var start = 0;
        // Prefer the actual selection boundary, preserving repeated letters.
        final selection = previous.selection;
        if (selection.isValid &&
            next.text.startsWith(previous.text.substring(0, selection.start)) &&
            next.text.endsWith(previous.text.substring(selection.end)) &&
            next.text.length >=
                selection.start + previous.text.length - selection.end) {
          start = selection.start;
          final end = next.text.length - (previous.text.length - selection.end);
          next = _replacement(next, start, end);
        } else {
          final before = previous.text.characters.toList();
          final after = next.text.characters.toList();
          var prefix = 0;
          while (prefix < before.length &&
              prefix < after.length &&
              before[prefix] == after[prefix]) {
            start += after[prefix++].length;
          }
          var oldEnd = before.length,
              newEnd = after.length,
              end = next.text.length;
          while (oldEnd > prefix &&
              newEnd > prefix &&
              before[oldEnd - 1] == after[newEnd - 1]) {
            oldEnd--;
            newEnd--;
            end -= after[newEnd].length;
          }
          next = _replacement(next, start, end);
        }
      }
      feedback = InputFeedback.typing;
      hint = '';
    }
    super.value = next;
    // An IME edit can normalize back to the same text; it is still an edit.
    if (edited && next == previous) notifyListeners();
  }

  TextEditingValue _replacement(TextEditingValue next, int start, int end) {
    final text = next.text.substring(start, end);
    int offset(int x) => (x - start).clamp(0, text.length);
    return TextEditingValue(
      text: text,
      selection: TextSelection(
        baseOffset: offset(next.selection.baseOffset),
        extentOffset: offset(next.selection.extentOffset),
      ),
      composing: next.composing.isValid && !next.composing.isCollapsed
          ? TextRange(
              start: offset(next.composing.start),
              end: offset(next.composing.end),
            )
          : TextRange.empty,
    );
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (feedback != InputFeedback.firstWrong) {
      return super.buildTextSpan(
        context: context,
        style: style?.copyWith(color: blue),
        withComposing: withComposing,
      );
    }
    final goal = normalizeAnswer(target).characters.toSet();
    final letter = RegExp(r'\p{L}', unicode: true);
    return TextSpan(
      style: style,
      children: [
        for (final char in text.characters)
          TextSpan(
            text: char,
            style: TextStyle(
              color:
                  (letter.hasMatch(char)
                          ? goal.contains(normalizeAnswer(char))
                                ? blue
                                : red
                          : neutral)
                      .withValues(alpha: .5),
            ),
          ),
      ],
    );
  }
}
