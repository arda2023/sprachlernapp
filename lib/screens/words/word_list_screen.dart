import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show ScaffoldMessenger, SnackBar;

import '../../models/speech_playback.dart';
import '../../models/word_list_models.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/providers/learning_providers.dart';
import '../../presentation/providers/database_providers.dart';
import '../../presentation/content_unavailable_view.dart';
import '../../theme/app_theme.dart';
import 'widgets/memory_level_legend_sheet.dart';
import 'widgets/playback_highlight.dart';
import 'widgets/word_details_sheet.dart';
import 'widgets/word_list_item.dart';

/// The Wortliste tab: every word the learner has seen, most recent first,
/// with search and a playlist entry point.
class WordListScreen extends ConsumerStatefulWidget {
  const WordListScreen({super.key, this.clock = DateTime.now});

  /// Injected so "Zuletzt gesehen" is testable.
  final DateTime Function() clock;

  @override
  ConsumerState<WordListScreen> createState() => _WordListScreenState();
}

class _WordListScreenState extends ConsumerState<WordListScreen> {
  static const _gutter = EdgeInsets.symmetric(horizontal: 20);

  final _query = TextEditingController();
  final _playback = SpeechPlayback();

  @override
  void dispose() {
    _query.dispose();
    _playback.dispose();
    super.dispose();
  }

  void _toast(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );

  final _saving = <String>{};
  Future<void> _save(
    VocabWord word, {
    bool? disabled,
    bool? favorite,
    bool? inPlaylist,
    required String message,
  }) async {
    if (!_saving.add(word.id)) return;
    try {
      await ref
          .read(wordActionsProvider)
          .save(
            word.id,
            disabled: disabled,
            favorite: favorite,
            inPlaylist: inPlaylist,
          );
      if (mounted) _toast(message);
    } catch (_) {
      if (mounted) {
        _toast('Änderung nicht gespeichert. Bitte erneut versuchen.');
      }
    } finally {
      _saving.remove(word.id);
    }
  }

  void _toggleDisabled(VocabWord word) => _save(
    word,
    disabled: !word.isDisabled,
    message: word.isDisabled ? 'Wort wieder aktiviert' : 'Wort deaktiviert',
  );
  void _toggleFavorite(VocabWord word) => _save(
    word,
    favorite: !word.isFavorite,
    message: word.isFavorite
        ? 'Aus Favoriten entfernt'
        : 'Zu Favoriten hinzugefügt',
  );
  void _togglePlaylist(VocabWord word) => _save(
    word,
    inPlaylist: !word.inPlaylist,
    message: word.inPlaylist
        ? 'Aus der Playlist entfernt'
        : 'Zur Playlist hinzugefügt',
  );

  // TODO: play the playlist through TTS once the audio layer exists.
  void _openPlaylist() {
    final count = (ref.read(wordListProvider).value ?? [])
        .where((w) => w.inPlaylist)
        .length;
    _toast(
      count == 0
          ? 'Deine Playlist ist noch leer'
          : 'Playlist-Modus folgt bald ($count '
                '${count == 1 ? 'Wort' : 'Wörter'})',
    );
  }

  void _openDetails(VocabWord word) => WordDetailsSheet.show(
    context,
    initialWord: word,
    playback: _playback,
    now: widget.clock(),
  );

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(wordListProvider);
    if (result.hasError) {
      return SafeArea(
        child: ContentUnavailableView(
          error: result.error!,
          onRetry: () {
            retryDatabases(ref);
            ref.invalidate(wordListProvider);
          },
        ),
      );
    }
    if (!result.hasValue) {
      return const SafeArea(child: Center(child: CupertinoActivityIndicator()));
    }
    final all = result.requireValue;
    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: Listenable.merge([_playback, _query]),
        builder: (context, _) {
          final q = _query.text.trim().toLowerCase();
          final words = all
              .where(
                (w) =>
                    w.entry.headword.toLowerCase().contains(q) ||
                    w.entry.translation.toLowerCase().contains(q),
              )
              .toList();
          final now = widget.clock();
          final playlistCount = (ref.read(wordListProvider).value ?? [])
              .where((w) => w.inPlaylist)
              .length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Padding(
                padding: _gutter,
                child: Semantics(
                  header: true,
                  child: Text(
                    'Wortliste',
                    style: AppType.editorial(
                      color: context.appColors.textPrimary,
                      size: 32,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: _gutter,
                child: Text(
                  '${all.length} Wörter · $playlistCount in der Playlist',
                  style: AppType.meta(color: context.appColors.textMuted),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: _gutter,
                child: Row(
                  children: [
                    Expanded(child: _SearchField(controller: _query)),
                    const SizedBox(width: 12),
                    _PlaylistButton(
                      count: playlistCount,
                      onPressed: _openPlaylist,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: words.isEmpty
                    ? Padding(
                        padding: _gutter,
                        child: Text(
                          'Keine Wörter für „${_query.text.trim()}“',
                          style: AppType.chrome(
                            color: context.appColors.textMuted,
                          ),
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: WordListItem.listPadding,
                        itemCount: words.length,
                        itemBuilder: (context, i) {
                          final word = words[i];
                          return WordListItem(
                            key: ValueKey(word.id),
                            word: word,
                            now: now,
                            playingWord: _playback.isPlaying(
                              wordAudioKey(word.id),
                            ),
                            playingSentence: _playback.isPlaying(
                              sentenceAudioKey(word.id),
                            ),
                            onPlayWord: () => _playback.play(
                              wordAudioKey(word.id),
                              word.entry.headword,
                            ),
                            onPlaySentence: () => _playback.play(
                              sentenceAudioKey(word.id),
                              word.sentence,
                            ),
                            onShowLegend: () => MemoryLevelLegendSheet.show(
                              context,
                              current: word.box,
                            ),
                            onToggleDisabled: () => _toggleDisabled(word),
                            onTogglePlaylist: () => _togglePlaylist(word),
                            onToggleFavorite: () => _toggleFavorite(word),
                            onOpenDetails: () => _openDetails(word),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return CupertinoSearchTextField(
      controller: controller,
      placeholder: 'Wörter suchen',
      style: AppType.chrome(color: context.appColors.textPrimary, size: 16),
      placeholderStyle: AppType.chrome(
        size: 16,
        color: context.appColors.textMuted,
      ),
      itemColor: context.appColors.textMuted,
      padding: const EdgeInsetsDirectional.fromSTEB(6, 14, 8, 14),
      decoration: BoxDecoration(
        color: context.appColors.raisedInk,
        border: Border.all(color: context.appColors.hairline),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

/// Square entry to the playlist mode, matching the search field's chrome.
class _PlaylistButton extends StatelessWidget {
  const _PlaylistButton({required this.count, required this.onPressed});

  static const size = 48.0;

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: CupertinoButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        minimumSize: const Size(size, size),
        child: Semantics(
          label: 'Playlist, $count ${count == 1 ? 'Wort' : 'Wörter'}',
          excludeSemantics: true,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: context.appColors.raisedInk,
              border: Border.all(color: context.appColors.hairline),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              CupertinoIcons.music_note_list,
              size: 22,
              color: context.appColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
