import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/providers/premium_access_provider.dart';
import '../../widgets/premium_content_gate.dart';
import '../../widgets/speak_button.dart';
import '../../presentation/audio/speech_narration.dart';
import '../../presentation/audio/device_speech_playback.dart';

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Scaffold;
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../../models/playback_clock.dart';
import '../../models/practice_models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/action_buttons.dart';
import '../../widgets/back_bar.dart';
import '../../widgets/emphasis_text.dart';
import 'widgets/exercise_stage.dart';

/// One single-choice question on a stage of concentric discs (user request
/// 01.11.2026, after a Bubble screen). Listening: the play button a little
/// above the middle with the discs around it. Grammar: the sentence with
/// its gap under discs rising from the top. The answers sit at the bottom;
/// feedback follows the Feedback Rule (a Muted Brick flash for wrong, Quiet
/// Sage that stays for right, both announced). Once solved, the other
/// answers fold away, the German translation appears, and an explanation
/// with one orange action takes their place.
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
    if (!ProviderScope.containerOf(
      context,
      listen: false,
    ).read(premiumContentAccessProvider)) {
      return showPremiumContentPaywall(context, interest: 'Übungen');
    }
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

/// "Hören": play button, question, answers.
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

  late final _clip = SpeechNarration(
    text: widget.exercise.audioText ?? '',
    language: widget.exercise.targetLanguage,
    onError: (message) => showSpeechError(context, message),
  );

  /// Wrong options during their Muted Brick flash.
  final _flashing = <String>{};
  final _timers = <Timer>[];
  final _scroll = ScrollController();

  /// The discs centre on the play button.
  final _player = GlobalKey();
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
      HapticFeedback.errorNotification();
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
    HapticFeedback.successNotification();
    setState(() => _solved = true);
    _announce('Richtig: $option');
    widget.progress.complete(_exercise.id);
    // The explanation grows below the answer: keep the action in view.
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
    final tone = _listening
        ? ExerciseStageTone.listening(context.appColors)
        : ExerciseStageTone.grammar(context.appColors);
    final next = _solved ? _next : null;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value:
          (tone.light ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light)
              .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: tone.ground,
        body: Stack(
          children: [
            Positioned.fill(
              child: ListenableBuilder(
                listenable: _clip,
                builder: (context, _) => ExerciseStage(
                  tone: tone,
                  focus: _listening ? _player : null,
                  scroll: _scroll,
                  pulse: _listening && _clip.playing,
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  BackBar(onBack: () => Navigator.of(context).maybePop()),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, box) => SingleChildScrollView(
                        controller: _scroll,
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        child: ConstrainedBox(
                          // Fills the screen so the answers rest at the
                          // bottom; large text scrolls instead.
                          constraints: BoxConstraints(minHeight: box.maxHeight),
                          // Wide screens keep a 560pt column through side
                          // padding: a width cap inside IntrinsicHeight
                          // would measure at full width and overflow.
                          child: IntrinsicHeight(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                math.max(20, (box.maxWidth - 560) / 2),
                                4,
                                math.max(20, (box.maxWidth - 560) / 2),
                                16,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Kind, topic, level and the
                                  // instruction are self-explanatory
                                  // (user decision 29.10.2026): the
                                  // title leads.
                                  Semantics(
                                    header: true,
                                    child: Text(
                                      _exercise.title,
                                      style: AppType.editorial(
                                        color: tone.ink,
                                        size: 28,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 28),
                                  const Spacer(flex: 2),
                                  if (_listening)
                                    _ListeningFocus(
                                      playerKey: _player,
                                      clip: _clip,
                                      exercise: _exercise,
                                      solved: _solved,
                                      tone: tone,
                                    )
                                  else
                                    _GrammarFocus(
                                      exercise: _exercise,
                                      solved: _solved,
                                      tone: tone,
                                    ),
                                  const SizedBox(height: 32),
                                  const Spacer(flex: 3),
                                  for (final option in _exercise.options)
                                    _Fold(
                                      visible:
                                          !_solved ||
                                          option == _exercise.answer,
                                      reduceMotion: reduceMotion,
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: _OptionCard(
                                          label: option,
                                          tone: tone,
                                          state: _solved
                                              ? _OptionState.right
                                              : (_flashing.contains(option)
                                                    ? _OptionState.wrong
                                                    : _OptionState.idle),
                                          onPressed: () => _pick(option),
                                        ),
                                      ),
                                    ),
                                  _Fold(
                                    visible: _solved,
                                    reduceMotion: reduceMotion,
                                    child: _Explanation(
                                      text: _exercise.explanation,
                                      tone: tone,
                                      actionLabel: next == null
                                          ? 'Zurück zur Übersicht'
                                          : 'Nächste Übung',
                                      onAction: next == null
                                          ? () =>
                                                Navigator.of(context).maybePop()
                                          : () => ChoiceExerciseScreen.open(
                                              context,
                                              exercise: next,
                                              progress: widget.progress,
                                              queue: widget.queue,
                                              replace: true,
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Listening: the white play button with its progress as an open ring,
/// the question as its caption and, once solved, what was said and what it
/// means.
class _ListeningFocus extends StatelessWidget {
  const _ListeningFocus({
    required this.playerKey,
    required this.clip,
    required this.exercise,
    required this.solved,
    required this.tone,
  });

  final GlobalKey playerKey;
  final PlaybackClock clip;
  final ChoiceExercise exercise;
  final bool solved;
  final ExerciseStageTone tone;

  @override
  Widget build(BuildContext context) {
    final heard = exercise.audioText;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListenableBuilder(
          listenable: clip,
          builder: (context, _) => _StagePlayButton(
            key: playerKey,
            playing: clip.playing,
            progress: clip.progress,
            onPressed: clip.toggle,
            tone: tone,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          exercise.prompt,
          textAlign: TextAlign.center,
          style: AppType.chrome(color: tone.ink, size: 17),
        ),
        _Grow(
          child: solved && heard != null
              ? Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: _Heard(
                    text: heard,
                    translation: exercise.translation,
                    tone: tone,
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// What was said, in quotes, and its German meaning below.
class _Heard extends StatelessWidget {
  const _Heard({required this.text, required this.tone, this.translation});

  final String text;
  final String? translation;
  final ExerciseStageTone tone;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Column(
      children: [
        Text(
          'Zu hören war: „$text“',
          textAlign: TextAlign.center,
          style: AppType.editorial(
            color: tone.ink,
            size: 20,
            weight: FontWeight.w400,
            letterSpacing: 0,
          ),
        ),
        if (translation case final translation?) ...[
          const SizedBox(height: 4),
          Text(
            translation,
            textAlign: TextAlign.center,
            style: AppType.chrome(color: tone.mutedInk),
          ),
        ],
      ],
    ),
  );
}

/// A 96pt white disc like the reference's start button; the clip's
/// position runs around it as an open ring (gap at the bottom).
class _StagePlayButton extends StatelessWidget {
  const _StagePlayButton({
    super.key,
    required this.playing,
    required this.progress,
    required this.onPressed,
    required this.tone,
  });

  static const size = 96.0;

  final bool playing;
  final double progress;
  final VoidCallback onPressed;
  final ExerciseStageTone tone;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: CupertinoButton(
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      pressedOpacity: 0.85,
      minimumSize: const Size(size + 20, size + 20),
      child: Semantics(
        label: playing ? 'Pause' : 'Abspielen',
        excludeSemantics: true,
        child: SizedBox.square(
          dimension: size + 20,
          child: CustomPaint(
            painter: _OpenRingPainter(
              progress: progress,
              track: tone.ink.withValues(alpha: 0.18),
              fill: tone.ink,
            ),
            child: Center(
              child: Container(
                width: size,
                height: size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tone.light ? tone.ink : const Color(0xFFFFFFFF),
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  // The play triangle's weight sits left of its box.
                  padding: EdgeInsets.only(left: playing ? 0 : 5),
                  child: Icon(
                    playing
                        ? CupertinoIcons.pause_fill
                        : CupertinoIcons.play_fill,
                    size: 40,
                    color: tone.ground,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// The open progress ring (DESIGN.md): 110° gap at the bottom, clockwise
/// from bottom left, round ends.
class _OpenRingPainter extends CustomPainter {
  const _OpenRingPainter({
    required this.progress,
    required this.track,
    required this.fill,
  });

  final double progress;
  final Color track;
  final Color fill;

  static const _gap = 110 * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 4.0;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final start = math.pi / 2 + _gap / 2;
    const sweep = 2 * math.pi - _gap;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, start, sweep, false, paint..color = track);
    final done = progress.clamp(0.0, 1.0);
    if (done > 0) {
      canvas.drawArc(rect, start, sweep * done, false, paint..color = fill);
    }
  }

  @override
  bool shouldRepaint(_OpenRingPainter old) =>
      old.progress != progress || old.track != track || old.fill != fill;
}

/// Grammar: the sentence on a card of the stage's veil; once solved, the
/// German translation and a speaker for the whole sentence join it below a
/// hairline.
class _GrammarFocus extends StatelessWidget {
  const _GrammarFocus({
    required this.exercise,
    required this.solved,
    required this.tone,
  });

  final ChoiceExercise exercise;
  final bool solved;
  final ExerciseStageTone tone;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
    decoration: BoxDecoration(
      color: tone.surface,
      borderRadius: BorderRadius.circular(28),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _GapSentence(
          prompt: exercise.prompt,
          answer: solved ? exercise.answer : null,
          tone: tone,
        ),
        _Grow(
          child: solved
              ? Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        height: 1,
                        color: tone.ink.withValues(alpha: 0.14),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              exercise.translation ?? '',
                              style: AppType.chrome(
                                color: tone.mutedInk,
                                size: 17,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SpeakButton(
                            text: exercise.prompt.replaceAll(
                              ChoiceExercise.gap,
                              exercise.answer,
                            ),
                            language: exercise.targetLanguage,
                            label: 'Satz vorlesen',
                            ink: tone.ink,
                            fill: tone.surface,
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    ),
  );
}

/// The sentence with its gap as a soft pill; once solved, the answer
/// stands in the gap in Quiet Sage w600, like a placed chip.
class _GapSentence extends StatelessWidget {
  const _GapSentence({
    required this.prompt,
    required this.answer,
    required this.tone,
  });

  final String prompt;
  final String? answer;
  final ExerciseStageTone tone;

  @override
  Widget build(BuildContext context) {
    final parts = prompt.split(ChoiceExercise.gap);
    final style = AppType.editorial(
      color: tone.ink,
      size: 28,
      weight: FontWeight.w400,
      height: 1.45,
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
                    ? WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Container(
                          key: const ValueKey('grammar-gap'),
                          constraints: const BoxConstraints(minWidth: 72),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: tone.ink.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '…',
                            textAlign: TextAlign.center,
                            style: style.copyWith(color: tone.mutedInk),
                          ),
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

/// Grows to a new height over 260 ms; at once with reduced motion (an
/// AnimatedSize with zero duration asserts during layout).
class _Grow extends StatelessWidget {
  const _Grow({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => MediaQuery.disableAnimationsOf(context)
      ? child
      : AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: child,
        );
}

/// Folds a child away (height and opacity) instead of removing it at once.
class _Fold extends StatelessWidget {
  const _Fold({
    required this.visible,
    required this.reduceMotion,
    required this.child,
  });

  final bool visible;
  final bool reduceMotion;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 280),
    switchInCurve: Curves.easeOutCubic,
    switchOutCurve: Curves.easeInCubic,
    transitionBuilder: (child, animation) => SizeTransition(
      sizeFactor: animation,
      alignment: Alignment.topCenter,
      child: FadeTransition(opacity: animation, child: child),
    ),
    child: visible ? child : const SizedBox(width: double.infinity),
  );
}

/// The explanation under the found answer, on the stage's veil, and one
/// orange action. Replaces the former raised feedback card.
class _Explanation extends StatelessWidget {
  const _Explanation({
    required this.text,
    required this.tone,
    required this.actionLabel,
    required this.onAction,
  });

  final String text;
  final ExerciseStageTone tone;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        decoration: BoxDecoration(
          color: tone.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text.rich(
          emphasisSpan(
            text,
            AppType.editorial(
              color: tone.ink,
              size: 17,
              weight: FontWeight.w400,
              height: 1.45,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
      const SizedBox(height: 16),
      PrimaryActionButton(label: actionLabel, onPressed: onAction),
    ],
  );
}

enum _OptionState { idle, wrong, right }

/// An answer card on the stage's veil. Wrong flashes Brick Tint with a
/// Muted Brick edge; right stays Sage Tint with a Quiet Sage edge and a
/// check that pops in.
class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.label,
    required this.state,
    required this.tone,
    required this.onPressed,
  });

  final String label;
  final _OptionState state;
  final ExerciseStageTone tone;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    // The palette's tints vanish on the coloured stage; these keep right
    // and wrong apart from the resting veil.
    final (fill, edge, text) = switch (state) {
      // No outline at rest; only right/wrong get an edge.
      _OptionState.idle => (tone.surface, const Color(0x00000000), tone.ink),
      _OptionState.wrong => (
        colors.error.withValues(alpha: 0.26),
        colors.error,
        tone.ink,
      ),
      _OptionState.right => (
        colors.success.withValues(alpha: 0.24),
        colors.success,
        tone.ink,
      ),
    };
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return MergeSemantics(
      child: CupertinoButton(
        onPressed: state == _OptionState.right ? null : onPressed,
        padding: EdgeInsets.zero,
        pressedOpacity: 0.8,
        minimumSize: const Size(44, 56),
        child: Semantics(
          label: state == _OptionState.right ? '$label, richtig' : label,
          excludeSemantics: true,
          child: AnimatedContainer(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 150),
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 58),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: fill,
              border: Border.all(color: edge, width: 1.5),
              borderRadius: BorderRadius.circular(99),
            ),
            // The label stays centred; the check sits at the trailing edge.
            child: Stack(
              alignment: Alignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: AppType.chrome(
                      size: 17,
                      weight: FontWeight.w600,
                      color: text,
                    ),
                  ),
                ),
                if (state == _OptionState.right)
                  Positioned(
                    right: 0,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: reduceMotion ? 1 : 0.6, end: 1),
                      duration: reduceMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 420),
                      curve: Curves.elasticOut,
                      builder: (context, scale, child) =>
                          Transform.scale(scale: scale, child: child),
                      child: Icon(
                        CupertinoIcons.checkmark_alt,
                        size: 22,
                        color: colors.success,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
