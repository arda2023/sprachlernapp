import 'package:flutter/foundation.dart';

/// The two practice categories built on single-choice questions.
enum PracticeKind {
  listening('Hören', 'Hör zu und wähle die Antwort, die du hörst.'),
  grammar('Grammatik', 'Wähle die Form, die in die Lücke passt.');

  const PracticeKind(this.title, this.instruction);

  final String title;

  /// Shown under the title of every exercise of this kind.
  final String instruction;
}

/// One single-choice exercise. Listening: [audioText] is what the clip says
/// (read by TTS later), [prompt] the question. Grammar: [prompt] is a
/// sentence whose gap is written as `___`. Language tags are explicit from
/// day one (PRODUCT.md).
class ChoiceExercise {
  const ChoiceExercise({
    required this.id,
    required this.kind,
    required this.title,
    required this.summary,
    required this.topic,
    required this.level,
    required this.prompt,
    required this.options,
    required this.answer,
    required this.explanation,
    this.audioText,
    this.audioDuration = const Duration(seconds: 2),
    this.sourceLanguage = 'de',
    this.targetLanguage = 'en',
  }) : assert(level >= 1 && level <= 3);

  /// Stable slug, so content pack imports stay idempotent.
  final String id;
  final PracticeKind kind;
  final String title;
  final String summary;

  /// Area of the exercise, e.g. "Aussprache" or "Zeitformen".
  final String topic;

  /// 1–3, matching the deck difficulty levels.
  final int level;
  final String prompt;
  final List<String> options;

  /// Must be one of [options].
  final String answer;

  /// Why the answer is right; shown once it is chosen. English forms in
  /// `*…*`, like the grammar rules.
  final String explanation;
  final String? audioText;
  final Duration audioDuration;
  final String sourceLanguage;
  final String targetLanguage;

  /// Metadata line, e.g. "Zeitformen · Level 2".
  String get meta => '$topic · Level $level';

  static const gap = '___';
}

/// Which practice exercises the learner has solved, in memory until the
/// Drift layer exists. Splits a library into "Meine Übungen" and "Fertig".
class PracticeProgress extends ChangeNotifier {
  PracticeProgress([Iterable<String> doneIds = const []])
    : _done = {...doneIds};

  final Set<String> _done;

  bool isDone(String id) => _done.contains(id);

  void complete(String id) {
    if (_done.add(id)) notifyListeners();
  }
}
