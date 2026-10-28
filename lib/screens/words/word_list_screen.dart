import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show Scaffold, ScaffoldMessenger, SnackBar;

import '../../models/speech_playback.dart';
import '../../domain/leitner.dart';
import '../../models/word_list_models.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/providers/learning_providers.dart';
import '../../presentation/providers/database_providers.dart';
import '../../presentation/content_unavailable_view.dart';
import '../../theme/app_theme.dart';
import '../../widgets/back_bar.dart';
import 'widgets/playback_highlight.dart';
import 'widgets/word_details_sheet.dart';
import 'widgets/word_list_item.dart';

/// The Wortliste tab: every word the learner has seen, most recent first,
/// with search, status filters (derived from the card state, nothing stored)
/// and a playlist entry point.
class WordListScreen extends ConsumerStatefulWidget {
  const WordListScreen({
    super.key,
    this.clock = DateTime.now,
    this.targetCardId,
  });
  final String? targetCardId;

  static Future<void> openTarget(BuildContext context, String cardId) =>
      Navigator.of(context).push(
        CupertinoPageRoute<void>(
          builder: (context) => Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  BackBar(onBack: () => Navigator.of(context).maybePop()),
                  Expanded(child: WordListScreen(targetCardId: cardId)),
                ],
              ),
            ),
          ),
        ),
      );

  /// Injected so "Zuletzt gesehen" is testable.
  final DateTime Function() clock;

  @override
  ConsumerState<WordListScreen> createState() => _WordListScreenState();
}

class _WordListScreenState extends ConsumerState<WordListScreen> {
  static const _gutter = EdgeInsets.symmetric(horizontal: 20);

  final _query = TextEditingController();
  final _playback = SpeechPlayback();
  _Filter _filter = _Filter.all;

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
                '${count == 1 ? 'Übung' : 'Übungen'})',
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
    if (result.hasError && !result.hasValue) {
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
    final all = result.requireValue
        .where(
          (w) => widget.targetCardId == null || w.id == widget.targetCardId,
        )
        .toList();
    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: Listenable.merge([_playback, _query]),
        builder: (context, _) {
          final q = _query.text.trim().toLowerCase();
          final filtered = all.where(_filter.matches).toList();
          final words = filtered
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
                  _summary(all, playlistCount),
                  style: AppType.meta(color: context.appColors.textMuted),
                ),
              ),
              for (final notice
                  in ref.watch(learningNoticesProvider).value ?? <String>[])
                Padding(
                  padding: _gutter.copyWith(top: 8),
                  child: Text(
                    notice,
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
              const SizedBox(height: 12),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: _gutter,
                  children: [
                    for (final f in _Filter.values) ...[
                      if (f != _Filter.values.first) const SizedBox(width: 8),
                      _FilterChip(
                        label: f.label,
                        count: all.where(f.matches).length,
                        selected: f == _filter,
                        onTap: () => setState(() => _filter = f),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: words.isEmpty
                    ? Padding(
                        padding: _gutter,
                        child: Text(
                          all.isEmpty
                              ? 'Noch keine Wörter. Übe einen Stapel oder füge '
                                    'in einer Story ein Wort zum Lernen hinzu.'
                              : _query.text.trim().isNotEmpty
                              ? 'Keine Wörter für „${_query.text.trim()}“'
                              : 'Keine Wörter unter „${_filter.label}“.',
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
        borderRadius: BorderRadius.circular(14),
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
          label: 'Playlist, $count ${count == 1 ? 'Übung' : 'Übungen'}',
          excludeSemantics: true,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: context.appColors.raisedInk,
              borderRadius: BorderRadius.circular(14),
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

/// Status filters, derived from box and flags like the four categories.
enum _Filter {
  all('Alle'),
  fresh('Neu'),
  building('Im Aufbau'),
  mastered('Gemeistert'),
  favorites('Favoriten'),
  playlist('Playlist'),
  disabled('Deaktiviert');

  const _Filter(this.label);
  final String label;

  bool matches(VocabWord w) => switch (this) {
    all => true,
    fresh => w.box == 0,
    building => w.box > 0 && w.box < leitnerBoxCount,
    mastered => w.box == leitnerBoxCount,
    favorites => w.isFavorite,
    playlist => w.inPlaylist,
    disabled => w.isDisabled,
  };
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    const white = Color(0xFFFFFFFF);
    return MergeSemantics(
      child: CupertinoButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        minimumSize: const Size(44, 44),
        child: Semantics(
          label: '$label, $count',
          selected: selected,
          excludeSemantics: true,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? colors.popover : colors.raisedInk,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: label),
                  TextSpan(
                    text: '  $count',
                    style: TextStyle(
                      color: selected
                          ? white.withValues(alpha: 0.8)
                          : colors.textMuted,
                    ),
                  ),
                ],
              ),
              style: AppType.chrome(
                size: 14,
                weight: FontWeight.w700,
                color: selected ? white : colors.textPrimary,
                tabular: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "3 Wörter · 4 Übungen · 2 in der Playlist", singular where it is one.
String _summary(List<VocabWord> all, int playlistCount) {
  final words = all.map((w) => w.lexicalKey ?? w.id).toSet().length;
  final forms = all.length;
  return '$words ${words == 1 ? 'Wort' : 'Wörter'} · '
      '$forms ${forms == 1 ? 'Übung' : 'Übungen'} · '
      '$playlistCount in der Playlist';
}
