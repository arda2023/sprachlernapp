// Pure Dart: no Flutter imports (see CLAUDE.md, domain layer).

import 'answer_check.dart';
import 'content.dart';
import 'leitner.dart';
import 'srs_state.dart';

/// What one checked input did. [message] is the content-specific hint text
/// (synonym hint, wrong-form hint); the UI owns the other wording.
class PassFeedback {
  const PassFeedback(this.verdict, {this.message});

  final AnswerVerdict verdict;
  final String? message;
}

/// One pass of a card in a session (docs/srs.md): records every checked
/// input, the synonym hint and "Wort erfahren", and yields the review record
/// exactly once.
///
/// - [submit]: target form solves; a checked alternative sets [hintUsed] for
///   good (no error); "Fast richtig" changes nothing; a wrong form or wrong
///   answer counts an error. Empty input is not checked.
/// - [reveal]: sets [revealed], independent of [hintUsed]; the learner still
///   types the form to solve the gap.
/// - [complete]: once the gap is solved, returns the record the first time
///   only; afterwards [submit], [reveal] and [complete] do nothing.
/// A repeat pass ([logged] false, in-session repeat) never yields a record.
class ReviewPass {
  ReviewPass({
    required this.id,
    required this.item,
    required this.sentence,
    required UserCardState? state,
    required this.mode,
    required this.startedAt,
    this.logged = true,
  }) : boxBefore = state?.box ?? 0,
       dueAtBefore = state?.dueAt {
    if (sentence.cardId != item.card.id) {
      throw ArgumentError(
        'sentence ${sentence.sentenceId} is not a sentence '
        'of card ${item.card.id}',
      );
    }
    if (state != null && state.cardId != item.card.id) {
      throw ArgumentError('state of ${state.cardId} given for ${item.card.id}');
    }
  }

  /// Pass id, stored as `review_log.id`; storing it twice is a no-op.
  final String id;
  final PracticeItem item;
  final CardSentence sentence;
  final ReviewMode mode;
  final DateTime startedAt;
  final bool logged;
  final int boxBefore;
  final DateTime? dueAtBefore;

  bool? _firstAttemptCorrect;
  DateTime? _firstResponseAt;
  int _errorCount = 0;
  bool _revealed = false;
  bool _hintUsed = false;
  bool _solved = false;
  bool _completed = false;

  int get errorCount => _errorCount;
  bool get revealed => _revealed;
  bool get hintUsed => _hintUsed;
  bool get solved => _solved;
  bool get completed => _completed;

  /// Only an exact first checked input counts (literal observation); false
  /// after a typo, an alternative, an error or "Wort erfahren" first.
  bool get firstAttemptCorrect => _firstAttemptCorrect ?? false;

  /// An error, "Wort erfahren" or a synonym hint: the card returns once later
  /// in the session (in-session repeat). Repeat passes never repeat again.
  bool get needsRepeat => logged && (_hintUsed || _errorCount > 0 || _revealed);

  /// Checks one input. Null when nothing was checked: empty input, or the
  /// gap is already solved.
  PassFeedback? submit(
    String input,
    DateTime now, {
    bool includeDiacritics = true,
  }) {
    if (_solved || _completed) return null;
    if (normalizeAnswer(input).isEmpty) return null;
    _firstResponseAt ??= now;
    final card = item.card;
    final verdict = evaluateAnswer(
      input,
      target: card.form,
      alternatives: sentence.validAlternatives,
      otherFormsOfLemma: item.otherFormsOfLemma,
      includeDiacritics: includeDiacritics,
    );
    _firstAttemptCorrect ??= verdict == AnswerVerdict.target;
    switch (verdict) {
      case AnswerVerdict.target:
        _solved = true;
        return const PassFeedback(AnswerVerdict.target);
      case AnswerVerdict.alternative:
        _hintUsed = true;
        return PassFeedback(verdict, message: synonymHint(input, card.form));
      case AnswerVerdict.almost:
        return const PassFeedback(AnswerVerdict.almost);
      case AnswerVerdict.wrongForm:
        _errorCount++;
        return PassFeedback(
          verdict,
          message: wrongFormHint(card.lemma, card.formLabelDe),
        );
      case AnswerVerdict.wrong:
        _errorCount++;
        return const PassFeedback(AnswerVerdict.wrong);
    }
  }

  /// "Wort erfahren". False if it changed nothing (already used, or solved).
  bool reveal(DateTime now) {
    if (_solved || _completed || _revealed) return false;
    _firstResponseAt ??= now;
    // Asking for the word before any checked input: there is no unaided
    // first attempt, so a later exact input is not "first attempt correct".
    _firstAttemptCorrect ??= false;
    _revealed = true;
    return true;
  }

  /// The review record of this pass, the first time it is asked for after
  /// the gap was solved; null before, afterwards and for repeat passes.
  /// [now] is the answer time; the due date follows the local calendar day.
  ReviewRecord? complete({
    required DateTime now,
    required String appVersion,
    required String deviceId,
    LeitnerSchedule schedule = const LeitnerSchedule(),
  }) {
    if (!_solved || _completed) return null;
    _completed = true;
    if (!logged) return null;
    final next = scheduleReview(
      boxBefore: boxBefore,
      dueAtBefore: dueAtBefore,
      mode: mode,
      errorCount: _errorCount,
      revealed: _revealed,
      hintUsed: _hintUsed,
      answeredAt: now,
      schedule: schedule,
    );
    return ReviewRecord(
      id: id,
      cardId: item.card.id,
      createdAt: now.toUtc(),
      mode: mode,
      sentenceId: sentence.sentenceId,
      firstAttemptCorrect: firstAttemptCorrect,
      errorCount: _errorCount,
      revealed: _revealed,
      hintUsed: _hintUsed,
      boxBefore: boxBefore,
      boxAfter: next.boxAfter,
      dueAtAfter: next.dueAtAfter,
      responseMs: _firstResponseAt?.difference(startedAt).inMilliseconds,
      appVersion: appVersion,
      deviceId: deviceId,
    );
  }
}
