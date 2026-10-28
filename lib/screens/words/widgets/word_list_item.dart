import 'package:flutter/cupertino.dart';

import '../../../domain/leitner.dart';
import '../../../models/word_list_models.dart';
import '../../../theme/app_theme.dart';
import 'memory_level_indicator.dart';
import 'memory_level_legend_sheet.dart';
import 'playback_highlight.dart';
import '../../../widgets/popover_content.dart';
import '../../../widgets/popover_trigger.dart';

/// One word in the Wortliste (Redesign 20.10.2026): a card without outline.
/// Memory level, headword and example sentence (both read aloud on tap) and
/// metadata; on the right only the favourite heart and "Mehr", which opens
/// a popover with playlist, deactivation and details (REDESIGN_BERICHTE.md:
/// not every action permanently on every row).
class WordListItem extends StatelessWidget {
  const WordListItem({
    super.key,
    required this.word,
    required this.now,
    required this.playingWord,
    required this.playingSentence,
    required this.onPlayWord,
    required this.onPlaySentence,
    required this.onToggleDisabled,
    required this.onTogglePlaylist,
    required this.onToggleFavorite,
    required this.onOpenDetails,
  });

  static const listPadding = EdgeInsets.fromLTRB(20, 0, 20, 40);

  final VocabWord word;
  final DateTime now;
  final bool playingWord;
  final bool playingSentence;
  final VoidCallback onPlayWord;
  final VoidCallback onPlaySentence;
  final VoidCallback onToggleDisabled;
  final VoidCallback onTogglePlaylist;
  final VoidCallback onToggleFavorite;
  final VoidCallback onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    const inset = EdgeInsets.only(left: PlaybackHighlight.inset);
    final headword = word.entry.headword;
    final meta = [
      if (const [
        'Grundform',
        'Präteritum',
        'Partizip Perfekt',
      ].contains(word.entry.partOfSpeech))
        word.entry.partOfSpeech,
      if (word.isDisabled) 'Deaktiviert',
      'Zuletzt gesehen: ${lastSeenLabel(word.lastSeenAt, now)}',
      'Wiederholt: ${reviewCountLabel(word.reviewCount)}',
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          14 - PlaybackHighlight.inset,
          6,
          4,
          14,
        ),
        decoration: BoxDecoration(
          color: colors.raisedInk,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Opacity(
                opacity: word.isDisabled ? 0.45 : 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // The dashes open the level legend, pointing at them.
                    PopoverTrigger<void>(
                      popover: (_) => MemoryLevelLegendSheet(current: word.box),
                      builder: (context, open, show) => MergeSemantics(
                        child: CupertinoButton(
                          onPressed: show,
                          padding: inset,
                          minimumSize: const Size(44, 44),
                          alignment: Alignment.centerLeft,
                          child: Semantics(
                            label:
                                'Erinnerungsstufe ${word.box} von '
                                '$leitnerBoxCount: ${memoryLevelTitle(word.box)}',
                            excludeSemantics: true,
                            child: TriggerPill(
                              open: open,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              child: MemoryLevelIndicator(
                                level: word.box,
                                litColor: open ? const Color(0xFFFFFFFF) : null,
                                offColor: open ? const Color(0x59FFFFFF) : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    ListenButton(
                      label: '$headword anhören',
                      playing: playingWord,
                      onPressed: onPlayWord,
                      child: HeadwordWithSpeaker(
                        headword: headword,
                        playing: playingWord,
                      ),
                    ),
                    if (word.entry.translation.isNotEmpty)
                      Padding(
                        padding: inset.copyWith(bottom: 4),
                        child: Text(
                          word.entry.translation,
                          style: AppType.chrome(
                            size: 15,
                            weight: FontWeight.w600,
                            color: colors.active,
                          ),
                        ),
                      ),
                    ListenButton(
                      label: 'Satz anhören: ${word.sentence}',
                      playing: playingSentence,
                      onPressed: onPlaySentence,
                      child: Text(
                        word.sentence,
                        style: AppType.editorial(
                          color: colors.textPrimary,
                          size: 16,
                          weight: FontWeight.w400,
                          height: 1.45,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: inset,
                      child: Text(
                        word.box == 0
                            ? '${word.entry.partOfSpeech} · Ungelernt · '
                                  'Hinzugefügt ${lastSeenLabel(word.lastSeenAt, now)}'
                            : meta,
                        style: AppType.meta(color: colors.textMuted).copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                WordToggle(
                  label: 'Favorit',
                  on: word.isFavorite,
                  onPressed: onToggleFavorite,
                  icon: Icon(
                    word.isFavorite
                        ? CupertinoIcons.heart_fill
                        : CupertinoIcons.heart,
                    size: 19,
                  ),
                ),
                PopoverTrigger<VoidCallback>(
                  popover: (_) => _WordMenu(
                    word: word,
                    onTogglePlaylist: onTogglePlaylist,
                    onToggleDisabled: onToggleDisabled,
                    onOpenDetails: onOpenDetails,
                  ),
                  // Run the chosen action after the popover has closed.
                  onClosed: (action) => action?.call(),
                  builder: (context, open, show) => _MoreButton(
                    headword: headword,
                    open: open,
                    onPressed: show,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreButton extends StatelessWidget {
  const _MoreButton({
    required this.headword,
    required this.open,
    required this.onPressed,
  });

  final String headword;
  final bool open;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return MergeSemantics(
      child: CupertinoButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        minimumSize: const Size(44, 44),
        child: Semantics(
          label: 'Mehr zu $headword',
          excludeSemantics: true,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: open ? colors.popover : null,
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.ellipsis,
              size: 19,
              color: open ? const Color(0xFFFFFFFF) : colors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

/// "Mehr" popover: playlist and deactivation as toggles, then details. It
/// closes with the chosen action, which the row runs afterwards.
class _WordMenu extends StatelessWidget {
  const _WordMenu({
    required this.word,
    required this.onTogglePlaylist,
    required this.onToggleDisabled,
    required this.onOpenDetails,
  });

  final VocabWord word;
  final VoidCallback onTogglePlaylist;
  final VoidCallback onToggleDisabled;
  final VoidCallback onOpenDetails;

  @override
  Widget build(BuildContext context) {
    void choose(VoidCallback action) => Navigator.of(context).pop(action);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          word.entry.headword,
          style: AppType.editorial(color: const Color(0xFFFFFFFF), size: 22),
        ),
        const SizedBox(height: 8),
        PopoverMenuRow(
          label: 'In der Playlist',
          icon: CupertinoIcons.music_note,
          toggled: word.inPlaylist,
          onTap: () => choose(onTogglePlaylist),
        ),
        PopoverMenuRow(
          label: 'Deaktiviert',
          icon: CupertinoIcons.nosign,
          toggled: word.isDisabled,
          onTap: () => choose(onToggleDisabled),
        ),
        PopoverMenuRow(
          label: 'Details zu ${word.entry.headword}',
          icon: CupertinoIcons.info_circle,
          onTap: () => choose(onOpenDetails),
        ),
      ],
    );
  }
}

/// A quiet on/off action. Off: `textMuted` icon. On: `textPrimary` icon
/// (filled where a filled glyph exists) on a Hairline disc, the same grammar
/// as the "Übersetzen" toggle. Never an ink.
class WordToggle extends StatelessWidget {
  const WordToggle({
    super.key,
    required this.label,
    required this.on,
    required this.onPressed,
    required this.icon,
  });

  final String label;
  final bool on;
  final VoidCallback onPressed;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: CupertinoButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        minimumSize: const Size(44, 44),
        child: Semantics(
          label: label,
          toggled: on,
          excludeSemantics: true,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: on ? context.appColors.activeTint : null,
              shape: BoxShape.circle,
            ),
            child: IconTheme.merge(
              data: IconThemeData(
                color: on
                    ? context.appColors.active
                    : context.appColors.textMuted,
              ),
              child: Center(child: icon),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Wort deaktivieren": a document with an X. CupertinoIcons has no such
/// glyph, so the X sits on the document. Filled, the X is cut out in the
/// Hairline of the toggle's disc.
class DisableWordIcon extends StatelessWidget {
  const DisableWordIcon({super.key, required this.filled});

  final bool filled;

  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color;
    return Stack(
      alignment: const Alignment(0, 0.3),
      children: [
        Icon(filled ? CupertinoIcons.doc_fill : CupertinoIcons.doc, size: 20),
        Icon(
          CupertinoIcons.xmark,
          size: 9,
          color: filled ? context.appColors.hairline : color,
        ),
      ],
    );
  }
}
