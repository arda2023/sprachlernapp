import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../../domain/story_learning.dart';
import '../../../domain/story_learning_diagnostics.dart';
import '../../../presentation/providers/database_providers.dart';
import '../../words/word_list_screen.dart';
import '../../../models/story_models.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/anchored_popover.dart';
import '../../../widgets/popover_content.dart';
import '../../../widgets/word_bubble.dart';

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
    this.onSaved,
    this.failure,
    this.onReactivate,
    this.learningAvailable = true,
    this.personalAction,
    this.language,
  });

  /// The word as it appears in the text, e.g. 'arrived'.
  final String surface;
  final String? language;
  final WordEntry entry;
  final WordMark? mark;
  final Future<StoryAddResult> Function() onAdd;
  final StoryAddResult? status;
  final ValueChanged<StoryAddResult>? onSaved;
  final StoryLearningFailure? failure;
  final Future<StoryAddResult> Function()? onReactivate;
  final bool learningAvailable;
  final Widget? personalAction;

  static Future<void> show(
    BuildContext context, {
    required Rect anchor,
    required String surface,
    required WordEntry entry,
    required WordMark? mark,
    required Future<StoryAddResult> Function() onAdd,
    StoryAddResult? status,
    ValueChanged<StoryAddResult>? onSaved,
    StoryLearningFailure? failure,
    Future<StoryAddResult> Function()? onReactivate,
    bool learningAvailable = true,
    Widget? personalAction,
    String? language,
  }) => showAnchoredPopoverAt<void>(
    context: context,
    anchor: anchor,
    color: context.appColors.popover,
    maxWidth: wordBubbleWidth(context, word: entry.headword),
    padding: wordBubblePadding,
    builder: (_) => WordPopover(
      surface: surface,
      language: language,
      entry: entry,
      mark: mark,
      onAdd: onAdd,
      status: status,
      onSaved: onSaved,
      failure: failure,
      onReactivate: onReactivate,
      learningAvailable: learningAvailable,
      personalAction: personalAction,
    ),
  );

  @override
  State<WordPopover> createState() => _WordPopoverState();
}

class _WordPopoverState extends State<WordPopover> {
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

  /// What a personal add button reported ([LearningMessageNotification]).
  String? _learningMessage;

  @override
  void dispose() {
    _releaseContent();
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
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is StoryLearningFailure
              ? error.message
              : 'Nicht gespeichert – erneut versuchen.',
        );
      }
    } finally {
      releaseWrite();
      if (mounted) setState(() => _saving = false);
    }
    if (_addedNow) widget.onSaved?.call(_status);
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    // The real save status decides, never a display mark alone.
    final added = _status.state == StoryAddState.added;
    final reactivate =
        _status.state == StoryAddState.disabled && widget.onReactivate != null;
    final canAdd = widget.learningAvailable && _status.canAdd && !_saving;
    final Widget? action = switch (widget.personalAction) {
      final personal? => personal,
      null when added && _status.cardId != null => AddWordButton(
        done: true,
        label: 'Hinzugefügt, in Wortliste ansehen',
        onPressed: () => WordListScreen.openTarget(context, _status.cardId!),
      ),
      null when reactivate => AddWordButton(
        busy: _saving,
        label: 'Wort reaktivieren',
        onPressed: () => _add(reactivate: true),
      ),
      null when widget.learningAvailable => AddWordButton(
        busy: _saving,
        done: added,
        label: _addedNow ? 'Zum Lernen hinzugefügt' : _status.label,
        onPressed: canAdd && widget.failure == null ? () => _add() : null,
      ),
      _ => null,
    };
    final message =
        _error ??
        widget.failure?.message ??
        _status.message ??
        _learningMessage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        NotificationListener<LearningMessageNotification>(
          onNotification: (note) {
            if (note.message != _learningMessage) {
              setState(() => _learningMessage = note.message);
            }
            return true;
          },
          child: WordBubbleHeader(
            word: entry.headword,
            // Pronounce the exact form shown in the source text.
            speak: widget.surface,
            language: widget.language,
            underline: _mark != null,
            trailing: action,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 2, right: 6),
          child: Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              Text(entry.translation, style: wordBubbleTranslation()),
              if (entry.partOfSpeech.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(entry.partOfSpeech, style: PopoverText.caption()),
                ),
            ],
          ),
        ),
        if (message != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 6),
            child: Semantics(
              liveRegion: true,
              child: Text(message, style: PopoverText.caption()),
            ),
          ),
      ],
    );
  }
}
