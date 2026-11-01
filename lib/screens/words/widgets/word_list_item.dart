import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../../domain/leitner.dart';
import '../../../models/word_list_models.dart';
import '../../../theme/app_theme.dart';
import 'memory_level_indicator.dart';
import 'memory_level_legend_sheet.dart';
import 'playback_highlight.dart';
import 'word_details_page.dart';
import '../../../widgets/anchored_popover.dart';
import '../../../widgets/popover_content.dart';
import '../../../widgets/popover_trigger.dart';

/// One word in the Wortliste (Redesign 20.10.2026): a card without outline.
/// Memory level, headword and example sentence (both read aloud on tap) and
/// metadata; on the right only the favourite heart and "Mehr", which opens
/// a popover with playlist, deactivation and the word's details as a second
/// page (REDESIGN_BERICHTE.md: not every action permanently on every row).
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

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    const inset = EdgeInsets.only(left: PlaybackHighlight.inset);
    final headword = word.entry.headword;

    // A deactivated word is dimmed; screen readers get the state in words.
    return Semantics(
      value: word.isDisabled ? 'Deaktiviert' : null,
      child: Padding(
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
                        popover: (_) =>
                            MemoryLevelLegendSheet(current: word.box),
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
                                  litColor: open
                                      ? const Color(0xFFFFFFFF)
                                      : null,
                                  offColor: open
                                      ? const Color(0x59FFFFFF)
                                      : null,
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
                    maxWidth: menuPopoverWidth,
                    popover: (_) => _WordMenu(
                      word: word,
                      now: now,
                      onTogglePlaylist: onTogglePlaylist,
                      onToggleDisabled: onToggleDisabled,
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

/// "Mehr" popover: playlist and deactivation as toggles (the popover closes
/// with the chosen action, which the row runs afterwards), then the word
/// info, which opens as a second page inside the same bubble: the bubble
/// widens while the menu slides out to the left and the details slide in
/// from the right (user request 01.11.2026).
class _WordMenu extends StatefulWidget {
  const _WordMenu({
    required this.word,
    required this.now,
    required this.onTogglePlaylist,
    required this.onToggleDisabled,
  });

  final VocabWord word;
  final DateTime now;
  final VoidCallback onTogglePlaylist;
  final VoidCallback onToggleDisabled;

  static const _detailsPadding = EdgeInsets.fromLTRB(16, 8, 18, 20);

  @override
  State<_WordMenu> createState() => _WordMenuState();
}

class _WordMenuState extends State<_WordMenu> {
  bool _details = false;

  void _show(bool details) {
    HapticFeedback.selectionClick();
    setState(() => _details = details);
    PopoverResize.to(
      context,
      maxWidth: details ? 440 : menuPopoverWidth,
      padding: details ? _WordMenu._detailsPadding : const EdgeInsets.all(20),
    );
  }

  Widget _menu(BuildContext context) {
    final word = widget.word;
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
          onTap: () => choose(widget.onTogglePlaylist),
        ),
        PopoverMenuRow(
          label: 'Deaktiviert',
          icon: CupertinoIcons.nosign,
          toggled: word.isDisabled,
          onTap: () => choose(widget.onToggleDisabled),
        ),
        PopoverMenuRow(
          label: 'Details zu ${word.entry.headword}',
          icon: CupertinoIcons.info_circle,
          onTap: () => _show(true),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final page = _details
        ? WordDetailsPage(
            key: const ValueKey('details'),
            initialWord: widget.word,
            now: widget.now,
            onBack: () => _show(false),
          )
        : KeyedSubtree(key: const ValueKey('menu'), child: _menu(context));
    final switcher = AnimatedSwitcher(
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      // The details come in from the right and leave to it, the menu
      // from and to the left: a push and a pop, both ways.
      transitionBuilder: (child, animation) {
        final details = child.key == const ValueKey('details');
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween(
              begin: Offset(details ? 0.18 : -0.18, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topLeft,
        children: [
          for (final child in previous)
            Positioned(left: 0, right: 0, top: 0, child: child),
          ?current,
        ],
      ),
      child: page,
    );
    // AnimatedSize with a zero duration re-dirties itself during layout,
    // so reduced motion simply goes without it.
    if (reduceMotion) return switcher;
    return AnimatedSize(
      duration: const Duration(milliseconds: 340),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topLeft,
      child: switcher,
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
        onPressed: () {
          // Toggles tick like a switch.
          HapticFeedback.selectionClick();
          onPressed();
        },
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
