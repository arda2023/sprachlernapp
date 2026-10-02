import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart'
    show Colors, InputDecoration, Scaffold, TextField, UnderlineInputBorder;
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../../domain/answer_check.dart';
import '../../domain/sentences.dart';
import '../../models/exercise_models.dart';
import '../../models/sample_content.dart';
import '../../theme/app_theme.dart';
import '../../widgets/back_bar.dart';
import '../../widgets/reading_toolbar.dart';
import '../../widgets/sentence_translation_sheet.dart';
import '../../widgets/success_feedback_card.dart';

/// A text with gaps. Verb mode: each gap is an inline text field. Choice
/// mode: no keyboard, answer chips below the text. Feedback follows the
/// Feedback Rule: Quiet Sage for right, a short Muted Brick flash for wrong,
/// always announced as well.
class TextExerciseScreen extends StatefulWidget {
  const TextExerciseScreen({
    super.key,
    required this.text,
    required this.mode,
    this.translate = sampleTranslateSentence,
    this.chipSeed = 7,
  });

  final ExerciseText text;
  final ExerciseMode mode;
  final String Function(String sentence) translate;

  /// Seed for the chip order, so it is stable across rebuilds and in tests.
  final int chipSeed;

  static Future<void> open(
    BuildContext context,
    ExerciseText text,
    ExerciseMode mode,
  ) => Navigator.of(context).push(
    CupertinoPageRoute<void>(
      builder: (_) => TextExerciseScreen(text: text, mode: mode),
    ),
  );

  @override
  State<TextExerciseScreen> createState() => _TextExerciseScreenState();
}

class _Gap {
  _Gap(this.gap, this.number);

  final TextGap gap;

  /// 1-based position among this exercise's gaps.
  final int number;
  final controller = TextEditingController();
  final focus = FocusNode();
  final key = GlobalKey();
  bool solved = false;
  bool flashError = false;

  void dispose() {
    controller.dispose();
    focus.dispose();
  }
}

enum _ChipFlash { none, success, error }

class _Chip {
  _Chip(this.answer);

  final String answer;
  final key = GlobalKey();
  bool used = false;
  _ChipFlash flash = _ChipFlash.none;
}

class _Sentence {
  _Sentence(this.paragraph, this.range, this.recognizer);

  final int paragraph;
  final SentenceRange range;
  final TapGestureRecognizer recognizer;
}

class _TextExerciseScreenState extends State<TextExerciseScreen> {
  static const _flashDuration = Duration(milliseconds: 600);
  static const _flightDuration = Duration(milliseconds: 350);

  /// Per paragraph: plain text as [String], exercise gaps as [_Gap]. Gaps the
  /// mode skips are already filled in as text.
  late final List<List<Object>> _paragraphs;
  final _gaps = <_Gap>[];
  final _chips = <_Chip>[];
  final _sentences = <_Sentence>[];
  late final List<List<int>> _paragraphSentences;

  final _timers = <Timer>[];
  OverlayEntry? _flight;
  bool _translating = false;
  int? _selectedSentence;
  String? _feedback;

  bool get _choice => widget.mode == ExerciseMode.anyWordClass;

  _Gap? get _current => _gaps.where((g) => !g.solved).firstOrNull;

  int get _solvedCount => _gaps.where((g) => g.solved).length;

  @override
  void initState() {
    super.initState();
    _paragraphs = [
      for (final paragraph in widget.text.segments)
        [
          for (final segment in paragraph)
            switch (segment) {
              final TextGap gap when widget.mode.includes(gap) => _addGap(gap),
              final TextGap gap => gap.answer,
              _ => segment,
            },
        ],
    ];
    if (_choice) {
      _chips.addAll([for (final g in _gaps) _Chip(g.gap.answer)]);
      _chips.shuffle(math.Random(widget.chipSeed));
    }
    _paragraphSentences = [
      for (final (i, pieces) in _paragraphs.indexed)
        [
          for (final range in splitSentences(_fullText(pieces)))
            _addSentence(i, range),
        ],
    ];
    // Typing mode starts in the first gap, so the learner can write at once.
    if (!_choice) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _current?.focus.requestFocus();
      });
    }
  }

  _Gap _addGap(TextGap gap) {
    final g = _Gap(gap, _gaps.length + 1);
    _gaps.add(g);
    return g;
  }

  int _addSentence(int paragraph, SentenceRange range) {
    final index = _sentences.length;
    _sentences.add(
      _Sentence(
        paragraph,
        range,
        TapGestureRecognizer()..onTap = () => _translate(index),
      ),
    );
    return index;
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _flight?.remove();
    for (final g in _gaps) {
      g.dispose();
    }
    for (final s in _sentences) {
      s.recognizer.dispose();
    }
    super.dispose();
  }

  // ---------------------------------------------------------------- feedback

  void _after(Duration delay, VoidCallback action) {
    _timers.add(
      Timer(delay, () {
        if (mounted) setState(action);
      }),
    );
  }

  void _announce(String message) => SemanticsService.sendAnnouncement(
    View.of(context),
    message,
    TextDirection.ltr,
  );

  void _say(String message) {
    _feedback = message;
    _announce(message);
    _after(const Duration(seconds: 2), () {
      if (_feedback == message) _feedback = null;
    });
  }

  void _completeIfDone() {
    if (_current == null) _announce('Alle Lücken gelöst');
  }

  // --------------------------------------------------------------- verb mode

  void _submit(_Gap g) {
    switch (checkAnswer(g.controller.text, g.gap.answer)) {
      case AnswerResult.correct:
        setState(() {
          g.solved = true;
          _feedback = null;
        });
        _announce('Richtig: ${g.gap.answer}');
        final next = _current;
        if (next != null) {
          next.focus.requestFocus();
        } else {
          FocusScope.of(context).unfocus();
          _completeIfDone();
        }
      case AnswerResult.almost:
        setState(() => _say('Fast richtig – prüf die Schreibweise.'));
        g.focus.requestFocus();
      case AnswerResult.wrong:
        HapticFeedback.lightImpact();
        setState(() {
          g.controller.clear();
          g.flashError = true;
        });
        _announce('Falsch');
        g.focus.requestFocus();
        _after(_flashDuration, () => g.flashError = false);
    }
  }

  // ------------------------------------------------------------- choice mode

  Future<void> _pick(_Chip chip) async {
    final target = _current;
    if (chip.used || chip.flash != _ChipFlash.none || target == null) return;
    if (_flight != null) return;

    if (chip.answer.toLowerCase() != target.gap.answer.toLowerCase()) {
      HapticFeedback.lightImpact();
      setState(() => chip.flash = _ChipFlash.error);
      _announce('Falsch');
      _after(_flashDuration, () => chip.flash = _ChipFlash.none);
      return;
    }

    setState(() => chip.flash = _ChipFlash.success);
    _announce('Richtig: ${chip.answer}');
    await _fly(chip, target);
    if (!mounted) return;
    setState(() => target.solved = true);
    _completeIfDone();
    _after(const Duration(seconds: 1), () {
      chip.used = true;
      chip.flash = _ChipFlash.none;
    });
  }

  /// Flies a copy of the chip into the gap. Skipped when the OS asks for
  /// reduced motion or either end isn't on screen.
  Future<void> _fly(_Chip chip, _Gap gap) async {
    final from = _rectOf(chip.key);
    final to = _rectOf(gap.key);
    if (MediaQuery.disableAnimationsOf(context) || from == null || to == null) {
      return;
    }
    final done = Completer<void>();
    _flight = OverlayEntry(
      builder: (_) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: _flightDuration,
        curve: Curves.easeInOut,
        onEnd: done.complete,
        builder: (_, t, child) {
          final rect = Rect.lerp(from, to, t)!;
          return Positioned.fromRect(rect: rect, child: child!);
        },
        child: IgnorePointer(
          child: _ChipFace(answer: chip.answer, flash: _ChipFlash.success),
        ),
      ),
    );
    Overlay.of(context).insert(_flight!);
    await done.future;
    _flight?.remove();
    _flight = null;
  }

  Rect? _rectOf(GlobalKey key) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  // -------------------------------------------------------- translation mode

  void _toggleTranslate() {
    FocusScope.of(context).unfocus();
    setState(() => _translating = !_translating);
    if (_translating) _announce(ReadingToolbar.hint);
  }

  String _fullText(List<Object> pieces) =>
      [for (final p in pieces) p is _Gap ? p.gap.answer : p as String].join();

  /// The pieces of [paragraph] inside [range]; strings are clipped, gaps
  /// belong to the sentence their first character falls in.
  List<Object> _piecesIn(int paragraph, SentenceRange range) {
    final out = <Object>[];
    var offset = 0;
    for (final piece in _paragraphs[paragraph]) {
      final length = piece is _Gap
          ? piece.gap.answer.length
          : (piece as String).length;
      final start = offset;
      final end = offset + length;
      offset = end;
      if (piece is _Gap) {
        if (start >= range.start && start < range.end) out.add(piece);
        continue;
      }
      final from = math.max(start, range.start);
      final to = math.min(end, range.end);
      if (from < to) {
        out.add((piece as String).substring(from - start, to - start));
      }
    }
    return out;
  }

  Future<void> _translate(int index) async {
    final s = _sentences[index];
    final pieces = _piecesIn(s.paragraph, s.range);
    final key = [for (final p in pieces) p is _Gap ? p.gap.answer : p as String]
        .join();
    // Unsolved gaps stay hidden in the original, so the sheet never gives
    // the answer away.
    final original = [
      for (final p in pieces)
        p is _Gap ? (p.solved ? p.gap.answer : '…') : p as String,
    ].join();
    setState(() => _selectedSentence = index);
    await SentenceTranslationSheet.show(
      context,
      original: original,
      translation: widget.translate(key),
    );
    if (mounted) setState(() => _selectedSentence = null);
  }

  // ------------------------------------------------------------------ spans

  TextStyle get _body => AppType.storyBody();

  InlineSpan _solvedSpan(_Gap g, {GestureRecognizer? recognizer}) => TextSpan(
    text: g.gap.answer,
    recognizer: recognizer,
    style: const TextStyle(
      color: AppColors.success,
      fontWeight: FontWeight.w600,
    ),
  );

  InlineSpan _gapSpan(_Gap g) {
    if (g.solved) return _solvedSpan(g);
    final current = identical(g, _current);
    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: _choice
          ? _ChoiceGap(
              key: g.key,
              gap: g,
              total: _gaps.length,
              current: current,
              style: _body,
            )
          : _TypedGap(
              key: g.key,
              gap: g,
              total: _gaps.length,
              style: _body,
              onSubmit: () => _submit(g),
            ),
    );
  }

  List<InlineSpan> _paragraphSpans(int paragraph) => [
    for (final piece in _paragraphs[paragraph])
      piece is _Gap ? _gapSpan(piece) : TextSpan(text: piece as String),
  ];

  List<InlineSpan> _sentenceSpans(int paragraph) => [
    for (final index in _paragraphSentences[paragraph])
      TextSpan(
        style: TextStyle(
          backgroundColor: index == _selectedSentence
              ? AppColors.hairline
              : null,
        ),
        children: [
          for (final piece in _piecesIn(paragraph, _sentences[index].range))
            if (piece is _Gap)
              piece.solved
                  ? _solvedSpan(piece, recognizer: _sentences[index].recognizer)
                  : TextSpan(
                      text: piece.gap.base,
                      recognizer: _sentences[index].recognizer,
                      style: const TextStyle(color: AppColors.textMuted),
                    )
            else
              TextSpan(
                text: piece as String,
                recognizer: _sentences[index].recognizer,
              ),
        ],
      ),
  ];

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final info = widget.text.info;
    final done = _current == null;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        bottomNavigationBar: ReadingToolbar(
          translating: _translating,
          onToggleTranslate: _toggleTranslate,
        ),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              BackBar(
                onBack: () => Navigator.of(context).maybePop(),
                trailing: Semantics(
                  liveRegion: true,
                  label: '$_solvedCount von ${_gaps.length} Lücken gelöst',
                  excludeSemantics: true,
                  child: Text(
                    '$_solvedCount von ${_gaps.length}',
                    style: AppType.meta().copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
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
                            Text(widget.mode.title, style: AppType.meta()),
                            const SizedBox(height: 8),
                            Semantics(
                              header: true,
                              child: Text(
                                info.title,
                                style: AppType.editorial(size: 32),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _translating
                                  ? 'Übersetzungsmodus aktiv.'
                                  : widget.mode.description,
                              style: AppType.chrome(
                                size: 13,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 28),
                            for (var i = 0; i < _paragraphs.length; i++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: Text.rich(
                                  TextSpan(
                                    style: _body,
                                    children: _translating
                                        ? _sentenceSpans(i)
                                        : _paragraphSpans(i),
                                  ),
                                ),
                              ),
                            if (done) ...[
                              const SizedBox(height: 8),
                              SuccessFeedbackCard(
                                title: 'Alle ${_gaps.length} Lücken gelöst',
                                subtitle: 'Text abgeschlossen',
                                actionLabel: 'Zurück zu den Texten',
                                onAction: () =>
                                    Navigator.of(context).maybePop(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_feedback case final message?)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: Text(
                    message,
                    style: AppType.chrome(weight: FontWeight.w600),
                  ),
                ),
              if (_choice && !_translating && !done)
                _ChipPanel(chips: _chips, onPick: _pick),
            ],
          ),
        ),
      ),
    );
  }
}

/// Verb mode gap: an inline field sized to the longer of base word and
/// answer, with the base word as hint. The hint flashes Muted Brick after a
/// wrong answer.
class _TypedGap extends StatelessWidget {
  const _TypedGap({
    super.key,
    required this.gap,
    required this.total,
    required this.style,
    required this.onSubmit,
  });

  final _Gap gap;
  final int total;
  final TextStyle style;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final longest = gap.gap.base.length > gap.gap.answer.length
        ? gap.gap.base
        : gap.gap.answer;
    final painter = TextPainter(
      text: TextSpan(text: longest, style: style),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final width = math.max(48.0, painter.width + 16);
    painter.dispose();

    return Semantics(
      label: 'Lücke ${gap.number} von $total, Grundform ${gap.gap.base}',
      child: SizedBox(
        width: width,
        child: TextField(
          controller: gap.controller,
          focusNode: gap.focus,
          style: style,
          textAlign: TextAlign.center,
          cursorColor: AppColors.textPrimary,
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: TextInputAction.done,
          // Replaces the default "done" behaviour, which would drop focus
          // and close the keyboard after every attempt.
          onEditingComplete: onSubmit,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 2),
            hintText: gap.gap.base,
            hintStyle: style.copyWith(
              color: gap.flashError ? AppColors.error : AppColors.textMuted,
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: gap.flashError ? AppColors.error : AppColors.hairline,
              ),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: gap.flashError ? AppColors.error : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Choice mode gap: the base word over an underline; the active gap's
/// underline is textPrimary.
class _ChoiceGap extends StatelessWidget {
  const _ChoiceGap({
    super.key,
    required this.gap,
    required this.total,
    required this.current,
    required this.style,
  });

  final _Gap gap;
  final int total;
  final bool current;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'Lücke ${gap.number} von $total, Grundform ${gap.gap.base}'
          '${current ? ', aktuelle Lücke' : ''}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: current ? AppColors.textPrimary : AppColors.hairline,
              width: current ? 1.5 : 1,
            ),
          ),
        ),
        child: Text(
          gap.gap.base,
          style: style.copyWith(color: AppColors.textMuted),
        ),
      ),
    );
  }
}

class _ChipPanel extends StatelessWidget {
  const _ChipPanel({required this.chips, required this.onPick});

  final List<_Chip> chips;
  final ValueChanged<_Chip> onPick;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.4,
      ),
      decoration: const BoxDecoration(
        color: AppColors.raisedInk,
        border: Border(top: BorderSide(color: AppColors.hairline)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final chip in chips)
              _AnswerChip(key: chip.key, chip: chip, onTap: () => onPick(chip)),
          ],
        ),
      ),
    );
  }
}

class _AnswerChip extends StatelessWidget {
  const _AnswerChip({super.key, required this.chip, required this.onTap});

  final _Chip chip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: CupertinoButton(
        onPressed: chip.used ? null : onTap,
        padding: EdgeInsets.zero,
        pressedOpacity: 0.7,
        minimumSize: const Size(44, 44),
        child: Semantics(
          label: chip.answer,
          enabled: !chip.used,
          excludeSemantics: true,
          child: _ChipFace(
            answer: chip.answer,
            flash: chip.flash,
            used: chip.used,
          ),
        ),
      ),
    );
  }
}

class _ChipFace extends StatelessWidget {
  const _ChipFace({
    required this.answer,
    required this.flash,
    this.used = false,
  });

  final String answer;
  final _ChipFlash flash;
  final bool used;

  @override
  Widget build(BuildContext context) {
    final (fill, border, label) = switch (flash) {
      _ChipFlash.success => (
        AppColors.successTint,
        AppColors.success,
        AppColors.success,
      ),
      _ChipFlash.error => (
        AppColors.errorTint,
        AppColors.error,
        AppColors.error,
      ),
      _ChipFlash.none when used => (
        null,
        AppColors.hairline,
        AppColors.iconOff,
      ),
      _ChipFlash.none => (
        AppColors.nightPage,
        AppColors.hairline,
        AppColors.textPrimary,
      ),
    };
    // No container alignment: that would stretch the chip to the full row.
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: fill,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        answer,
        maxLines: 1,
        textHeightBehavior: const TextHeightBehavior(
          applyHeightToFirstAscent: false,
          applyHeightToLastDescent: false,
        ),
        style: AppType.chrome(weight: FontWeight.w600, color: label),
      ),
    );
  }
}
