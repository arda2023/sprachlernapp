import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show InputDecoration, OutlineInputBorder, TextField, showModalBottomSheet;

import '../../../domain/leitner.dart';
import '../../../models/speech_playback.dart';
import '../../../models/word_list_models.dart';
import '../../../models/word_list_store.dart';
import '../../../theme/app_theme.dart';
import 'memory_level_indicator.dart';
import 'playback_highlight.dart';

/// Everything about one word: level, headword (read aloud on tap), word
/// class, translation, review metadata, the example sentence with its
/// translation, and the learner's own notes.
class WordDetailsSheet extends StatefulWidget {
  const WordDetailsSheet({
    super.key,
    required this.store,
    required this.playback,
    required this.wordId,
    required this.now,
  });

  final WordListStore store;
  final SpeechPlayback playback;
  final String wordId;
  final DateTime now;

  static Future<void> show(
    BuildContext context, {
    required WordListStore store,
    required SpeechPlayback playback,
    required String wordId,
    required DateTime now,
  }) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => WordDetailsSheet(
      store: store,
      playback: playback,
      wordId: wordId,
      now: now,
    ),
  );

  @override
  State<WordDetailsSheet> createState() => _WordDetailsSheetState();
}

class _WordDetailsSheetState extends State<WordDetailsSheet> {
  late final _note = TextEditingController(
    text: widget.store.byId(widget.wordId).note,
  );

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = AppType.editorial(
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
        listenable: Listenable.merge([widget.store, widget.playback]),
        builder: (context, _) {
          final word = widget.store.byId(widget.wordId);
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
                              style: AppType.meta(),
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
                    child: Text(entry.partOfSpeech, style: AppType.meta()),
                  ),
                  const SizedBox(height: 20),
                  _Indented(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _Rule(),
                        const SizedBox(height: 16),
                        Text('Deutsch', style: AppType.meta()),
                        const SizedBox(height: 4),
                        Text(
                          entry.translation,
                          style: AppType.editorial(
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
                        Text('Beispielsatz', style: AppType.meta()),
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
                        Text('Deutsch', style: AppType.meta()),
                        const SizedBox(height: 4),
                        Text(word.sentenceTranslation, style: body),
                        const SizedBox(height: 24),
                        Text('Notizen', style: AppType.meta()),
                        const SizedBox(height: 8),
                        _NoteField(
                          controller: _note,
                          onChanged: (text) =>
                              widget.store.setNote(word.id, text),
                        ),
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
      const ColoredBox(color: AppColors.hairline, child: SizedBox(height: 1));
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
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.hairline)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppType.chrome(color: AppColors.textMuted),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              value,
              style: AppType.chrome(weight: FontWeight.w600, tabular: true),
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
      style: AppType.chrome(height: 1.4),
      cursorColor: AppColors.textPrimary,
      decoration: InputDecoration(
        hintText: 'Füge eigene Notizen hinzu …',
        hintStyle: AppType.chrome(color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.nightPage,
        contentPadding: const EdgeInsets.all(14),
        enabledBorder: border(AppColors.hairline),
        focusedBorder: border(AppColors.textMuted),
      ),
    );
  }
}
