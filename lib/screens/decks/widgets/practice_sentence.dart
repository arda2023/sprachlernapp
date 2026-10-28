import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/content.dart';
import '../../../theme/app_theme.dart';
import 'practice_input.dart';

class WordAnchor {
  const WordAnchor(this.start, this.rect, this.translation);
  final int start;
  final Rect rect;
  final String translation;
}

/// One flowing paragraph, with an editor that occupies at most a whole line.
/// Annotated words are matched by their exact sentence offsets, never spelling.
class PracticeSentence extends StatefulWidget {
  const PracticeSentence({
    super.key,
    required this.sentence,
    required this.input,
    required this.focus,
    required this.solved,
    required this.onSubmit,
    required this.onChanged,
    required this.onWord,
    this.selectedStart,
    this.keepFocus = false,
    this.error = false,
    this.errorOffset = 0,
  });
  final CardSentence sentence;
  final PracticeInputController input;
  final FocusNode focus;
  final bool solved;
  final VoidCallback onSubmit, onChanged;
  final ValueChanged<WordAnchor> onWord;
  final int? selectedStart;

  /// The current exercise: once solved it keeps focus (and the keyboard)
  /// and refuses edits. Past exercises in the history are read-only.
  final bool keepFocus;
  final bool error;
  final double errorOffset;
  @override
  State<PracticeSentence> createState() => PracticeSentenceState();
}

class PracticeSentenceState extends State<PracticeSentence> {
  final _words = <int, ({GlobalKey key, String? translation})>{};
  final _field = GlobalKey();
  final _solution = TextEditingController();
  double? _editingWidth, _editingScale, _editingAvailableWidth;
  @override
  void dispose() {
    _solution.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PracticeSentence oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sentence.sentenceId != widget.sentence.sentenceId) {
      _words.clear();
      _editingWidth = null;
    }
  }

  bool containsInput(Offset global) => _rect(_field)?.contains(global) ?? false;
  Rect? _rect(GlobalKey key) {
    final box = key.currentContext?.findRenderObject();
    return box is RenderBox && box.hasSize
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
  }

  bool selectAt(Offset global) {
    for (final entry in _words.entries) {
      if (_rect(entry.value.key)?.contains(global) ?? false) {
        _select(entry.key);
        return true;
      }
    }
    return false;
  }

  void _select(int start) {
    final word = _words[start]!;
    final rect = _rect(word.key);
    if (rect != null) {
      HapticFeedback.lightImpact();
      widget.onWord(
        WordAnchor(
          start,
          rect,
          word.translation?.trim().isNotEmpty == true
              ? word.translation!
              : 'Übersetzung nicht verfügbar',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.input,
    builder: (context, _) => LayoutBuilder(
      builder: (context, constraints) {
        final colors = context.appColors;
        final style = AppType.editorial(
          size: 26,
          weight: FontWeight.w400,
          height: 1.5,
          letterSpacing: 0,
          color: colors.memoryLevel2,
        );
        widget.input.blue = colors.memoryLevel2;
        widget.input.red = colors.error;
        widget.input.neutral = colors.textMuted;
        final s = widget.sentence;
        final children = <InlineSpan>[];
        void append(int start, int end) {
          if (start >= end) return;
          final piece = s.text.substring(start, end);
          // Segmentation is only for layout. Translation requires the annotation
          // at this very offset, including its exact sense/card linkage.
          for (final match in RegExp(
            r"[\p{L}\p{M}\p{N}]+(?:['’\-][\p{L}\p{M}\p{N}]+)*[.,!?;:]*|[^\p{L}\p{M}\p{N}]+",
            unicode: true,
          ).allMatches(piece)) {
            final text = match[0]!;
            if (!RegExp(r'[\p{L}\p{N}]', unicode: true).hasMatch(text)) {
              children.add(TextSpan(text: text));
              continue;
            }
            final offset = start + match.start;
            final wordLength = text
                .replaceFirst(RegExp(r'[.,!?;:]+$'), '')
                .length;
            final annotated = s.tokens
                .where((t) => t.start == offset && t.end == offset + wordLength)
                .firstOrNull;
            final item = _words.putIfAbsent(
              offset,
              () => (key: GlobalKey(), translation: annotated?.translation),
            );
            final selected = widget.selectedStart == offset;
            final word = text.substring(0, wordLength);
            final wordStyle = selected
                // Like every popover trigger: popover orange, white ink.
                ? style.copyWith(color: const Color(0xFFFFFFFF))
                : style.copyWith(
                    color: colors.memoryLevel2.withValues(
                      alpha: widget.selectedStart == null ? 1 : .5,
                    ),
                    decoration: TextDecoration.underline,
                    decorationStyle: TextDecorationStyle.dotted,
                    decorationColor: colors.textMuted.withValues(alpha: .45),
                  );
            children.add(
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: GestureDetector(
                  onTap: () => _select(offset),
                  child: Semantics(
                    button: true,
                    selected: selected,
                    label: '$text, Übersetzung anzeigen',
                    excludeSemantics: true,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        // The bubble's arrow points at the word itself, not
                        // at its trailing punctuation.
                        _WordHighlight(
                          key: item.key,
                          on: selected,
                          color: colors.popover,
                          child: Text(word, style: wordStyle),
                        ),
                        if (wordLength < text.length)
                          Text(
                            text.substring(wordLength),
                            style: style.copyWith(
                              color: colors.memoryLevel2.withValues(
                                alpha: widget.selectedStart == null ? 1 : .5,
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

        append(0, s.gapStart);
        final punctuation =
            RegExp(r'^[.,!?;:]+').firstMatch(s.text.substring(s.gapEnd))?[0] ??
            '';
        {
          final input = widget.input;
          final shown = widget.solved
              ? s.gapText
              : input.text.isEmpty
              ? input.hint
              : input.text;
          if (_solution.text != s.gapText) _solution.text = s.gapText;
          final punctuationPainter = TextPainter(
            text: TextSpan(text: punctuation, style: style),
            textDirection: TextDirection.ltr,
            textScaler: MediaQuery.textScalerOf(context),
          )..layout();
          final punctuationWidth = punctuationPainter.width;
          punctuationPainter.dispose();
          final painter = TextPainter(
            text: TextSpan(text: shown, style: style),
            textDirection: TextDirection.ltr,
            textScaler: MediaQuery.textScalerOf(context),
          )..layout();
          final scale = MediaQuery.textScalerOf(context).scale(style.fontSize!);
          final width = math.min(
            math.max(1.0, constraints.maxWidth - punctuationWidth),
            (widget.solved || widget.error) && _editingWidth != null &&
                _editingScale == scale && _editingAvailableWidth == constraints.maxWidth
                ? _editingWidth!
                : math.max(64.0, painter.width + 22),
          );
          painter.dispose();
          if (!widget.solved) {
            _editingWidth = width;
            _editingScale = scale;
            _editingAvailableWidth = constraints.maxWidth;
          }
          children.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: Opacity(
                opacity: widget.selectedStart == null ? 1 : .5,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    SizedBox(
                      key: _field,
                      width: width,
                      child: Transform.translate(
                        key: const ValueKey('practice-field-shake'),
                        offset: Offset(widget.errorOffset, 0),
                        child: TextField(
                        key: const ValueKey('practice-input'),
                        controller: widget.solved ? _solution : input,
                        focusNode: widget.solved && !widget.keepFocus
                            ? null
                            : widget.focus,
                        readOnly: widget.solved && !widget.keepFocus,
                        canRequestFocus: !widget.solved || widget.keepFocus,
                        inputFormatters: widget.solved ? const [_Locked()] : null,
                        showCursor: !widget.solved,
                        enableInteractiveSelection: !widget.solved,
                        autofocus: !widget.solved,
                        maxLines: null,
                        keyboardType: TextInputType.text,
                        style: widget.solved ? style.copyWith(color: colors.success) : style,
                        cursorColor: colors.memoryLevel2,
                        autocorrect: false,
                        enableSuggestions: false,
                        textInputAction: TextInputAction.done,
                        onEditingComplete: widget.onSubmit,
                        onChanged: (_) => widget.onChanged(),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 0,
                          ),
                          filled: true,
                          fillColor: widget.solved ? colors.successTint : widget.error ? colors.errorTint : colors.memoryLevel2.withValues(alpha: .12),
                          hintText: widget.solved || input.hint.isEmpty
                              ? null
                              : input.hint,
                          hintStyle: style.copyWith(
                            color: colors.memoryLevel2.withValues(alpha: .5),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    ),
                    if (punctuation.isNotEmpty) Text(punctuation, style: style),
                  ],
                ),
              ),
            ),
          );
        }
        append(s.gapEnd + punctuation.length, s.text.length);
        // WidgetSpan otherwise scales its child a second time: these Text and
        // TextField widgets already use MediaQuery's text scaler themselves.
        return Text.rich(
          TextSpan(
            style: style.copyWith(
              fontSize: MediaQuery.textScalerOf(context).scale(style.fontSize!),
            ),
            children: children,
          ),
          textScaler: TextScaler.noScaling,
        );
      },
    ),
  );
}

/// The tapped word while its bubble shows: a rounded popover-orange plate
/// behind the glyphs, painted outside the word's box so the sentence
/// never reflows.
class _WordHighlight extends StatelessWidget {
  const _WordHighlight({
    super.key,
    required this.on,
    required this.color,
    required this.child,
  });

  final bool on;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(end: on ? 1 : 0),
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 140),
    curve: Curves.easeOut,
    builder: (context, t, child) => CustomPaint(
      painter: t == 0 ? null : _PlatePainter(color.withValues(alpha: t)),
      child: child,
    ),
    child: child,
  );
}

class _PlatePainter extends CustomPainter {
  const _PlatePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // The line box is taller than the glyphs (line height 1.5).
    final plate = Rect.fromLTRB(
      -5,
      size.height * 0.12,
      size.width + 5,
      size.height * 0.94,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(plate, const Radius.circular(8)),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_PlatePainter old) => old.color != color;
}

/// Keeps the solved answer as it is while the keyboard stays open.
class _Locked extends TextInputFormatter {
  const _Locked();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => oldValue;
}
