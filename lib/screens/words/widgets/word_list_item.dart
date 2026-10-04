import 'package:flutter/cupertino.dart';

import '../../../domain/leitner.dart';
import '../../../models/word_list_models.dart';
import '../../../theme/app_theme.dart';
import 'memory_level_indicator.dart';
import 'playback_highlight.dart';

/// One word in the Wortliste: memory level, headword and example sentence
/// (both read aloud on tap), metadata, three quiet toggles and a chevron to
/// the details sheet.
class WordListItem extends StatelessWidget {
  const WordListItem({
    super.key,
    required this.word,
    required this.now,
    required this.playingWord,
    required this.playingSentence,
    required this.onPlayWord,
    required this.onPlaySentence,
    required this.onShowLegend,
    required this.onToggleDisabled,
    required this.onTogglePlaylist,
    required this.onToggleFavorite,
    required this.onOpenDetails,
  });

  /// The list's right padding is smaller than the gutter so the chevron's
  /// glyph sits near the edge; the rule still ends at the gutter.
  static const listPadding = EdgeInsets.fromLTRB(
    20 - PlaybackHighlight.inset,
    0,
    8,
    32,
  );
  static const ruleEndInset = 20.0 - 8;

  final VocabWord word;
  final DateTime now;
  final bool playingWord;
  final bool playingSentence;
  final VoidCallback onPlayWord;
  final VoidCallback onPlaySentence;
  final VoidCallback onShowLegend;
  final VoidCallback onToggleDisabled;
  final VoidCallback onTogglePlaylist;
  final VoidCallback onToggleFavorite;
  final VoidCallback onOpenDetails;

  @override
  Widget build(BuildContext context) {
    const inset = EdgeInsets.only(left: PlaybackHighlight.inset);
    final headword = word.entry.headword;
    final meta = [
      if (word.isDisabled) 'Deaktiviert',
      'Zuletzt gesehen: ${lastSeenLabel(word.lastSeenAt, now)}',
      'Wiederholt: ${reviewCountLabel(word.reviewCount)}',
    ].join(' · ');

    // A row on the Night Page, closed by a Hairline rule. The list pads it
    // by the gutter minus the playback inset, so the text inside the mark
    // lines up with the screen gutter and the rule starts under the text.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            children: [
              Expanded(
                child: Opacity(
                  opacity: word.isDisabled ? 0.45 : 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MergeSemantics(
                        child: CupertinoButton(
                          onPressed: onShowLegend,
                          padding: inset,
                          minimumSize: const Size(44, 44),
                          alignment: Alignment.centerLeft,
                          child: Semantics(
                            label:
                                'Erinnerungsstufe ${word.box} von '
                                '$leitnerBoxCount: ${memoryLevelTitle(word.box)}',
                            excludeSemantics: true,
                            child: MemoryLevelIndicator(level: word.box),
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
                      ListenButton(
                        label: 'Satz anhören: ${word.sentence}',
                        playing: playingSentence,
                        onPressed: onPlaySentence,
                        child: Text(
                          word.sentence,
                          style: AppType.editorial(
                            color: context.appColors.textPrimary,
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
                          meta,
                          style:
                              AppType.meta(color: context.appColors.textMuted)
                                  .copyWith(
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
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
                    label: 'Deaktiviert',
                    on: word.isDisabled,
                    onPressed: onToggleDisabled,
                    icon: DisableWordIcon(filled: word.isDisabled),
                  ),
                  WordToggle(
                    label: 'In der Playlist',
                    on: word.inPlaylist,
                    onPressed: onTogglePlaylist,
                    icon: const Icon(CupertinoIcons.music_note, size: 19),
                  ),
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
                ],
              ),
              MergeSemantics(
                child: CupertinoButton(
                  onPressed: onOpenDetails,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(44, 44),
                  child: Semantics(
                    label: 'Details zu $headword',
                    excludeSemantics: true,
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Icon(
                        CupertinoIcons.chevron_right,
                        size: 18,
                        color: context.appColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 1,
          margin: const EdgeInsets.only(
            left: PlaybackHighlight.inset,
            right: WordListItem.ruleEndInset,
          ),
          color: context.appColors.hairline,
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
              color: on ? context.appColors.hairline : null,
              shape: BoxShape.circle,
            ),
            child: IconTheme.merge(
              data: IconThemeData(
                color: on
                    ? context.appColors.textPrimary
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
