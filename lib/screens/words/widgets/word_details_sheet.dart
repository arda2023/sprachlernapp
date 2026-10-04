import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show InputDecoration, OutlineInputBorder, TextField, showModalBottomSheet;

import '../../../domain/leitner.dart';
import '../../../models/speech_playback.dart';
import '../../../models/word_list_models.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../presentation/providers/learning_providers.dart';
import '../../../presentation/content_unavailable_view.dart';
import '../../../theme/app_theme.dart';
import 'memory_level_indicator.dart';
import 'playback_highlight.dart';

/// Everything about one word: level, headword (read aloud on tap), word
/// class, translation, review metadata, the example sentence with its
/// translation, and the learner's own notes.
class WordDetailsSheet extends ConsumerStatefulWidget {
  const WordDetailsSheet({
    super.key,
    required this.initialWord,
    required this.playback,
    required this.now,
  });

  final VocabWord initialWord;
  final SpeechPlayback playback;
  final DateTime now;

  static Future<void> show(
    BuildContext context, {
    required VocabWord initialWord,
    required SpeechPlayback playback,
    required DateTime now,
  }) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => WordDetailsSheet(
      initialWord: initialWord,
      playback: playback,
      now: now,
    ),
  );

  @override
  ConsumerState<WordDetailsSheet> createState() => _WordDetailsSheetState();
}

class _WordDetailsSheetState extends ConsumerState<WordDetailsSheet> {
  late final _note = TextEditingController(text: widget.initialWord.note);

  Future<void> _pending = Future.value();
  bool _noteError = false;
  void _saveNote(String text) {
    final actions = ref.read(wordActionsProvider);
    _pending = _pending.then((_) async {
      try {
        await actions.save(widget.initialWord.id, note: text);
        if (mounted) setState(() => _noteError = false);
      } catch (_) {
        if (mounted) setState(() => _noteError = true);
      }
    });
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(wordListProvider);
    if (result.hasError) {
      return ContentUnavailableView(
        error: result.error!,
        onRetry: () => ref.invalidate(wordListProvider),
      );
    }
    final word =
        result.value?.where((w) => w.id == widget.initialWord.id).firstOrNull ??
        widget.initialWord;
    final body = AppType.editorial(
      color: context.appColors.textPrimary,
      size: 20,
      weight: FontWeight.w400,
      height: 1.4,
      letterSpacing: 0,
    );
    const inset = EdgeInsets.only(left: PlaybackHighlight.inset);

    return Padding(
      // Keeps the notes field above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ListenableBuilder(
        listenable: widget.playback,
        builder: (context, _) {
          final entry = word.entry;
          final playingWord = widget.playback.isPlaying(wordAudioKey(word.id));
          final playingSentence = widget.playback.isPlaying(
            sentenceAudioKey(word.id),
          );

          return SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                20 - PlaybackHighlight.inset,
                0,
                20,
                20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: inset,
                    child: Semantics(
                      label:
                          'Erinnerungsstufe ${word.box} von $leitnerBoxCount: '
                          '${memoryLevelTitle(word.box)}',
                      excludeSemantics: true,
                      child: Row(
                        children: [
                          MemoryLevelIndicator(level: word.box),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              memoryLevelTitle(word.box),
                              style: AppType.meta(
                                color: context.appColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ListenButton(
                      label: '${entry.headword} anhören',
                      playing: playingWord,
                      onPressed: () => widget.playback.play(
                        wordAudioKey(word.id),
                        entry.headword,
                      ),
                      child: HeadwordWithSpeaker(
                        headword: entry.headword,
                        playing: playingWord,
                        size: 28,
                      ),
                    ),
                  ),
                  Padding(
                    padding: inset,
                    child: Text(
                      entry.partOfSpeech,
                      style: AppType.meta(color: context.appColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _Indented(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _Rule(),
                        const SizedBox(height: 16),
                        Text(
                          'Deutsch',
                          style: AppType.meta(
                            color: context.appColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry.translation,
                          style: AppType.editorial(
                            color: context.appColors.textPrimary,
                            size: 22,
                            weight: FontWeight.w400,
                            height: 1.3,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _LedgerRow(
                          label: 'Zuletzt gesehen',
                          value: lastSeenLabel(word.lastSeenAt, widget.now),
                        ),
                        _LedgerRow(
                          label: 'Wiederholt',
                          value: reviewCountLabel(word.reviewCount),
                        ),
                        _LedgerRow(
                          label: 'Zeit zwischen Wiederholungen',
                          value: intervalLabel(word.reviewInterval),
                        ),
                        const _Rule(),
                        const SizedBox(height: 16),
                        Text(
                          'Beispielsatz',
                          style: AppType.meta(
                            color: context.appColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ListenButton(
                    label: 'Satz anhören: ${word.sentence}',
                    playing: playingSentence,
                    onPressed: () => widget.playback.play(
                      sentenceAudioKey(word.id),
                      word.sentence,
                    ),
                    child: Text(word.sentence, style: body),
                  ),
                  const SizedBox(height: 12),
                  _Indented(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Deutsch',
                          style: AppType.meta(
                            color: context.appColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(word.sentenceTranslation, style: body),
                        const SizedBox(height: 24),
                        Text(
                          'Notizen',
                          style: AppType.meta(
                            color: context.appColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_noteError)
                          CupertinoButton(
                            onPressed: () => _saveNote(_note.text),
                            child: const Text(
                              'Notiz nicht gespeichert. Erneut versuchen',
                            ),
                          ),
                        _NoteField(controller: _note, onChanged: _saveNote),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Lines plain content up with the text inside a playback mark.
class _Indented extends StatelessWidget {
  const _Indented({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: PlaybackHighlight.inset),
    child: child,
  );
}

class _Rule extends StatelessWidget {
  const _Rule();

  @override
  Widget build(BuildContext context) =>
      ColoredBox(color: context.appColors.hairline, child: SizedBox(height: 1));
}

/// Label left, value right, Hairline above; like the vocabulary ledger.
class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: context.appColors.hairline)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppType.chrome(color: context.appColors.textMuted),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              value,
              style: AppType.chrome(
                color: context.appColors.textPrimary,
                weight: FontWeight.w600,
                tabular: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteField extends StatelessWidget {
  const _NoteField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color),
    );
    return TextField(
      controller: controller,
      onChanged: onChanged,
      minLines: 3,
      maxLines: 6,
      textCapitalization: TextCapitalization.sentences,
      style: AppType.chrome(color: context.appColors.textPrimary, height: 1.4),
      cursorColor: context.appColors.textPrimary,
      decoration: InputDecoration(
        hintText: 'Füge eigene Notizen hinzu …',
        hintStyle: AppType.chrome(color: context.appColors.textMuted),
        filled: true,
        fillColor: context.appColors.nightPage,
        contentPadding: const EdgeInsets.all(14),
        enabledBorder: border(context.appColors.hairline),
        focusedBorder: border(context.appColors.textMuted),
      ),
    );
  }
}
