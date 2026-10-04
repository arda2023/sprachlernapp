import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Scaffold;
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../../models/playback_clock.dart';
import '../../models/practice_models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/back_bar.dart';
import '../../widgets/playback_controls.dart';
import '../../widgets/success_feedback_card.dart';

/// One single-choice question. Listening: a clip player, then the question.
/// Grammar: a sentence with a gap. Below, the answers as cards; feedback
/// follows the Feedback Rule (a Muted Brick flash for wrong, Quiet Sage that
/// stays for right, both announced). Once solved, the Success Feedback Card
/// slides in with the explanation.
class ChoiceExerciseScreen extends StatefulWidget {
  const ChoiceExerciseScreen({
    super.key,
    required this.exercise,
    required this.progress,
    this.queue = const [],
  });

  final ChoiceExercise exercise;
  final PracticeProgress progress;

  /// The library's exercises, to offer the next open one when solved.
  final List<ChoiceExercise> queue;

  static Future<void> open(
    BuildContext context, {
    required ChoiceExercise exercise,
    required PracticeProgress progress,
    List<ChoiceExercise> queue = const [],
    bool replace = false,
  }) {
    final route = CupertinoPageRoute<void>(
      builder: (_) => switch (exercise.kind) {
        PracticeKind.listening => ListeningExerciseScreen(
          exercise: exercise,
          progress: progress,
          queue: queue,
        ),
        PracticeKind.grammar => GrammarExerciseScreen(
          exercise: exercise,
          progress: progress,
          queue: queue,
        ),
      },
    );
    final navigator = Navigator.of(context);
    return replace ? navigator.pushReplacement(route) : navigator.push(route);
  }

  @override
  State<ChoiceExerciseScreen> createState() => _ChoiceExerciseScreenState();
}

/// "Hören": clip player, question, answers.
class ListeningExerciseScreen extends ChoiceExerciseScreen {
  const ListeningExerciseScreen({
    super.key,
    required super.exercise,
    required super.progress,
    super.queue,
  });
}

/// "Grammatik": sentence with a gap, answers.
class GrammarExerciseScreen extends ChoiceExerciseScreen {
  const GrammarExerciseScreen({
    super.key,
    required super.exercise,
    required super.progress,
    super.queue,
  });
}

class _ChoiceExerciseScreenState extends State<ChoiceExerciseScreen> {
  static const _flashDuration = Duration(milliseconds: 600);

  late final _clip = PlaybackClock(
    duration: widget.exercise.audioDuration,
    tick: const Duration(milliseconds: 100),
  );

  /// Wrong options during their Muted Brick flash.
  final _flashing = <String>{};
  final _timers = <Timer>[];
  final _scroll = ScrollController();
  bool _solved = false;

  ChoiceExercise get _exercise => widget.exercise;
  bool get _listening => _exercise.kind == PracticeKind.listening;

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _clip.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _announce(String message) => SemanticsService.sendAnnouncement(
    View.of(context),
    message,
    TextDirection.ltr,
  );

  void _pick(String option) {
    if (_solved || _flashing.contains(option)) return;
    if (option != _exercise.answer) {
      HapticFeedback.lightImpact();
      setState(() => _flashing.add(option));
      _announce('Falsch');
      _timers.add(
        Timer(_flashDuration, () {
          if (mounted) setState(() => _flashing.remove(option));
        }),
      );
      return;
    }
    _clip.pause();
    setState(() => _solved = true);
    _announce('Richtig: $option');
    widget.progress.complete(_exercise.id);
    // The card takes room from the list: keep the answers in view.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final end = _scroll.position.maxScrollExtent;
      MediaQuery.disableAnimationsOf(context)
          ? _scroll.jumpTo(end)
          : _scroll.animateTo(
              end,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
            );
    });
  }

  ChoiceExercise? get _next => widget.queue
      .where((e) => e.id != _exercise.id && !widget.progress.isDone(e.id))
      .firstOrNull;

  @override
  Widget build(BuildContext context) {
    final next = _solved ? _next : null;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value:
          (context.appColors.light
                  ? SystemUiOverlayStyle.dark
                  : SystemUiOverlayStyle.light)
              .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              BackBar(
                onBack: () => Navigator.of(context).maybePop(),
                trailing: Text(
                  _exercise.meta,
                  style: AppType.meta(color: context.appColors.textMuted),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: _scroll,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _exercise.kind.title,
                              style: AppType.meta(
                                color: context.appColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Semantics(
                              header: true,
                              child: Text(
                                _exercise.title,
                                style: AppType.editorial(
                                  color: context.appColors.textPrimary,
                                  size: 28,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _exercise.kind.instruction,
                              style: AppType.chrome(
                                size: 13,
                                color: context.appColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 28),
                            if (_listening) ...[
                              _ClipPlayer(clip: _clip),
                              const SizedBox(height: 28),
                              Text(
                                _exercise.prompt,
                                style: AppType.editorial(
                                  color: context.appColors.textPrimary,
                                  size: 22,
                                ),
                              ),
                            ] else
                              _GapSentence(
                                prompt: _exercise.prompt,
                                answer: _solved ? _exercise.answer : null,
                              ),
                            const SizedBox(height: 24),
                            for (final option in _exercise.options) ...[
                              _OptionCard(
                                label: option,
                                state: _solved
                                    ? (option == _exercise.answer
                                          ? _OptionState.right
                                          : _OptionState.retired)
                                    : (_flashing.contains(option)
                                          ? _OptionState.wrong
                                          : _OptionState.idle),
                                onPressed: () => _pick(option),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_solved)
                _SlideIn(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: ConstrainedBox(
                      // Large Dynamic Type: the card scrolls instead of
                      // pushing the answers off screen.
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(context).height * 0.5,
                        maxWidth: 600,
                      ),
                      child: SingleChildScrollView(
                        child: SuccessFeedbackCard(
                          title: 'Richtig',
                          subtitle: _listening && _exercise.audioText != null
                              ? 'Zu hören war: „${_exercise.audioText}“'
                              : null,
                          explanation: _exercise.explanation,
                          actionLabel: next == null
                              ? 'Zurück zur Übersicht'
                              : 'Nächste Übung',
                          onAction: next == null
                              ? () => Navigator.of(context).maybePop()
                              : () => ChoiceExerciseScreen.open(
                                  context,
                                  exercise: next,
                                  progress: widget.progress,
                                  queue: widget.queue,
                                  replace: true,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Placeholder for the clip: a large play button over the position track.
/// The clock runs, nothing sounds yet (TTS comes with the audio layer).
class _ClipPlayer extends StatelessWidget {
  const _ClipPlayer({required this.clip});

  final PlaybackClock clip;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: clip,
      builder: (context, _) => Container(
        padding: const EdgeInsets.fromLTRB(12, 20, 12, 8),
        decoration: BoxDecoration(
          color: context.appColors.raisedInk,
          border: Border.all(color: context.appColors.hairline),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            PlayPauseButton(
              playing: clip.playing,
              onPressed: clip.toggle,
              size: 72,
            ),
            const SizedBox(height: 12),
            PlaybackTrack(clock: clip),
          ],
        ),
      ),
    );
  }
}

/// The sentence with its gap as a muted underline; once solved, the answer
/// stands in the gap in Quiet Sage w600, like a placed chip.
class _GapSentence extends StatelessWidget {
  const _GapSentence({required this.prompt, required this.answer});

  /// Non-breaking spaces, so the underline keeps its length.
  static final _blank = '\u00A0' * 10;

  final String prompt;
  final String? answer;

  @override
  Widget build(BuildContext context) {
    final parts = prompt.split(ChoiceExercise.gap);
    final style = AppType.editorial(
      color: context.appColors.textPrimary,
      size: 24,
      weight: FontWeight.w400,
      height: 1.5,
      letterSpacing: 0,
    );
    final spoken = parts.join(answer ?? 'Lücke');
    return Semantics(
      container: true,
      label: spoken,
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(
          style: style,
          children: [
            for (final (i, part) in parts.indexed) ...[
              if (i > 0)
                answer == null
                    ? TextSpan(
                        text: _blank,
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                          decorationColor: context.appColors.textMuted,
                          decorationThickness: 2,
                        ),
                      )
                    : TextSpan(
                        text: answer,
                        style: TextStyle(
                          color: context.appColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              TextSpan(text: part),
            ],
          ],
        ),
      ),
    );
  }
}

enum _OptionState { idle, wrong, right, retired }

/// An answer card: Raised Ink, Hairline, `12pt` radius. Wrong flashes Brick
/// Tint with a Muted Brick edge; right stays Sage Tint with a Quiet Sage
/// edge and a check; the others retire to a muted label.
class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.label,
    required this.state,
    required this.onPressed,
  });

  final String label;
  final _OptionState state;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final (fill, edge, text) = switch (state) {
      _OptionState.idle => (
        context.appColors.raisedInk,
        context.appColors.hairline,
        context.appColors.textPrimary,
      ),
      _OptionState.wrong => (
        context.appColors.errorTint,
        context.appColors.error,
        context.appColors.textPrimary,
      ),
      _OptionState.right => (
        context.appColors.successTint,
        context.appColors.success,
        context.appColors.success,
      ),
      _OptionState.retired => (
        context.appColors.raisedInk,
        context.appColors.hairline,
        context.appColors.textMuted,
      ),
    };
    final enabled = state == _OptionState.idle || state == _OptionState.wrong;
    return MergeSemantics(
      child: CupertinoButton(
        onPressed: enabled ? onPressed : null,
        padding: EdgeInsets.zero,
        pressedOpacity: 0.8,
        minimumSize: const Size(44, 56),
        child: Semantics(
          label: state == _OptionState.right ? '$label, richtig' : label,
          excludeSemantics: true,
          child: AnimatedContainer(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 150),
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: fill,
              border: Border.all(color: edge),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: AppType.chrome(
                      size: 17,
                      weight: FontWeight.w600,
                      color: text,
                    ),
                  ),
                ),
                if (state == _OptionState.right) ...[
                  const SizedBox(width: 12),
                  Icon(
                    CupertinoIcons.checkmark_alt,
                    size: 22,
                    color: context.appColors.success,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Slides its child up from below the screen edge once; no motion when the
/// OS asks for reduced motion.
class _SlideIn extends StatelessWidget {
  const _SlideIn({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1, end: 0),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) =>
          FractionalTranslation(translation: Offset(0, t), child: child),
      child: child,
    );
  }
}
