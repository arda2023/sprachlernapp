import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../../domain/story_learning.dart';
import '../../../presentation/providers/database_providers.dart';
import '../../words/word_list_screen.dart';
import '../../../models/story_models.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/anchored_popover.dart';

/// Tapped word in the reader: popover pointing at the word with headword,
/// word class, German translation, pronunciation and "Zum Lernen
/// hinzufügen". The learning action keeps the existing story-add rules.
class WordPopover extends StatefulWidget {
  const WordPopover({
    super.key,
    required this.surface,
    required this.entry,
    required this.mark,
    required this.onAdd,
    this.status,
    this.onReactivate,
    this.learningAvailable = true,
  });

  /// The word as it appears in the text, e.g. 'arrived'.
  final String surface;
  final WordEntry entry;
  final WordMark? mark;
  final Future<StoryAddResult> Function() onAdd;
  final StoryAddResult? status;
  final Future<StoryAddResult> Function()? onReactivate;
  final bool learningAvailable;

  static Future<void> show(
    BuildContext context, {
    required Rect anchor,
    required String surface,
    required WordEntry entry,
    required WordMark? mark,
    required Future<StoryAddResult> Function() onAdd,
    StoryAddResult? status,
    Future<StoryAddResult> Function()? onReactivate,
    bool learningAvailable = true,
  }) => showAnchoredPopoverAt<void>(
    context: context,
    anchor: anchor,
    color: context.appColors.popover,
    builder: (_) => WordPopover(
      surface: surface,
      entry: entry,
      mark: mark,
      onAdd: onAdd,
      status: status,
      onReactivate: onReactivate,
      learningAvailable: learningAvailable,
    ),
  );

  @override
  State<WordPopover> createState() => _WordPopoverState();
}

class _WordPopoverState extends State<WordPopover>
    with SingleTickerProviderStateMixin {
  static const _white = Color(0xFFFFFFFF);

  late WordMark? _mark = widget.mark;
  late StoryAddResult _status =
      widget.status ?? const StoryAddResult(StoryAddState.unavailable);
  bool _saving = false;
  bool _addedNow = false;
  late final void Function() _releaseContent;
  @override
  void initState() {
    super.initState();
    _releaseContent = contentTransitionGate.acquire();
  }

  String? _error;

  /// Pronunciation: pre-generated audio is not in this copy yet, so the
  /// button shows its playing state like the Wortliste does.
  late final _speaking = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void dispose() {
    _releaseContent();
    _speaking.dispose();
    super.dispose();
  }

  Future<void> _add({bool reactivate = false}) async {
    if (_saving) return;
    final releaseWrite = contentTransitionGate.acquire();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final result = await (reactivate
          ? widget.onReactivate!()
          : widget.onAdd());
      if (mounted) {
        setState(() {
          _status = result;
          _addedNow = result.state == StoryAddState.added;
          if (result.state == StoryAddState.added) {
            _mark = WordMark.active;
            HapticFeedback.lightImpact();
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Nicht gespeichert – erneut versuchen.');
      }
    } finally {
      releaseWrite();
      if (mounted) setState(() => _saving = false);
    }
  }

  void _speak() {
    HapticFeedback.selectionClick();
    _speaking.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final inflected = widget.surface.toLowerCase() != entry.headword;
    // The real save status decides, never a display mark alone.
    final label = _saving
        ? 'Wird hinzugefügt …'
        : _addedNow
        ? 'Zum Lernen hinzugefügt'
        : _status.label;
    final added = _status.state == StoryAddState.added;
    final canAdd = widget.learningAvailable && _status.canAdd && !_saving;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: entry.headword,
                          // Known words keep their underline, like in the text.
                          style: AppType.editorial(color: _white, size: 28)
                              .copyWith(
                                decoration: _mark == null
                                    ? null
                                    : TextDecoration.underline,
                                decorationColor: _white,
                                decorationThickness: 2,
                              ),
                        ),
                        const TextSpan(text: '   '),
                        TextSpan(
                          text: entry.partOfSpeech,
                          style: AppType.meta(
                            color: _white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (inflected) ...[
                    const SizedBox(height: 2),
                    Text(
                      'im Text: ${widget.surface}',
                      style: AppType.meta(color: _white.withValues(alpha: 0.8)),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            _SpeakButton(speaking: _speaking, onPressed: _speak),
          ],
        ),
        const SizedBox(height: 14),
        Container(height: 1, color: _white.withValues(alpha: 0.25)),
        const SizedBox(height: 12),
        Text(
          'Deutsch',
          style: AppType.meta(color: _white.withValues(alpha: 0.8)),
        ),
        const SizedBox(height: 2),
        Text(
          entry.translation,
          style: AppType.editorial(
            color: _white,
            size: 22,
            weight: FontWeight.w400,
            height: 1.3,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 18),
        if (!widget.learningAvailable)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'Für diesen Text sind keine geprüften Lernreferenzen vorhanden.',
              style: AppType.chrome(
                size: 13,
                color: _white.withValues(alpha: 0.85),
              ),
            ),
          ),
        if (_error != null || _status.message != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Semantics(
              liveRegion: true,
              child: Text(
                _error ?? _status.message!,
                style: AppType.chrome(size: 13, color: _white),
              ),
            ),
          ),
        Semantics(
          liveRegion: true,
          child: _LearnButton(
            label: label,
            done: added,
            onPressed: canAdd ? () => _add() : null,
          ),
        ),
        if (_status.state == StoryAddState.added && _status.cardId != null)
          CupertinoButton(
            onPressed: () =>
                WordListScreen.openTarget(context, _status.cardId!),
            child: Text(
              'In Wortliste ansehen',
              style: AppType.chrome(color: _white),
            ),
          ),
        if (_status.state == StoryAddState.disabled &&
            widget.onReactivate != null)
          CupertinoButton(
            onPressed: _saving ? null : () => _add(reactivate: true),
            child: Text(
              'Wort reaktivieren',
              style: AppType.chrome(weight: FontWeight.w700, color: _white),
            ),
          ),
      ],
    );
  }
}

class _SpeakButton extends StatelessWidget {
  const _SpeakButton({required this.speaking, required this.onPressed});

  final Animation<double> speaking;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: CupertinoButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        minimumSize: const Size(44, 44),
        child: Semantics(
          label: 'Aussprechen',
          excludeSemantics: true,
          child: AnimatedBuilder(
            animation: speaking,
            builder: (context, _) {
              final on = speaking.isAnimating;
              // Gentle pulse while "playing".
              final pulse = on
                  ? 1 + 0.08 * (1 - (speaking.value * 4 % 2 - 1).abs())
                  : 1.0;
              return Transform.scale(
                scale: pulse,
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: on
                        ? const Color(0xFFFFFFFF)
                        : const Color(0x33FFFFFF),
                  ),
                  child: Icon(
                    on
                        ? CupertinoIcons.speaker_3_fill
                        : CupertinoIcons.speaker_2_fill,
                    size: 20,
                    color: on
                        ? context.appColors.popover
                        : const Color(0xFFFFFFFF),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// White pill on the coloured popover; outlined once the word is learned.
class _LearnButton extends StatelessWidget {
  const _LearnButton({
    required this.label,
    required this.done,
    required this.onPressed,
  });

  final String label;
  final bool done;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    const white = Color(0xFFFFFFFF);
    final enabled = onPressed != null;
    final filled = enabled;
    final ink = filled ? context.appColors.popover : white;
    return MergeSemantics(
      child: CupertinoButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        minimumSize: const Size(44, 50),
        child: Semantics(
          label: label,
          excludeSemantics: true,
          child: Container(
            constraints: const BoxConstraints(minHeight: 50),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              // Soft white fill instead of an outline (no-outline rule).
              color: filled ? white : white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  done ? CupertinoIcons.checkmark_alt : CupertinoIcons.plus,
                  size: 18,
                  color: enabled || done ? ink : white.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: AppType.chrome(
                      weight: FontWeight.w800,
                      color: enabled || done
                          ? ink
                          : white.withValues(alpha: 0.7),
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
