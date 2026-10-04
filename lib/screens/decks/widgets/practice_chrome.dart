import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/hairline_track.dart';

/// Home (ends the session), how many words of the session are left over a
/// neutral track with one segment per word, and the word menu.
class PracticeSessionBar extends StatelessWidget {
  const PracticeSessionBar({
    super.key,
    required this.done,
    required this.total,
    required this.onHome,
    required this.onMenu,
  });

  final int done;
  final int total;
  final VoidCallback onHome;
  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context) {
    final left = total - done;
    final label = left == 0
        ? 'Alle Wörter geübt'
        : 'Noch $left ${left == 1 ? 'Wort' : 'Wörter'}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          _BarButton(
            label: 'Session beenden',
            icon: CupertinoIcons.house,
            onPressed: onHome,
          ),
          Expanded(
            child: Semantics(
              label: left == 0
                  ? 'Alle $total Wörter geübt'
                  : 'Noch $left von $total Wörtern',
              excludeSemantics: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  // The track spans the space between the two buttons.
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.meta(color: context.appColors.textMuted)
                          .copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                    ),
                    const SizedBox(height: 6),
                    SessionTrack(done: done, total: total),
                  ],
                ),
              ),
            ),
          ),
          if (onMenu case final onMenu?)
            _BarButton(
              label: 'Mehr',
              icon: CupertinoIcons.ellipsis_vertical,
              onPressed: onMenu,
            )
          else
            const SizedBox(width: 44),
        ],
      ),
    );
  }
}

/// Neutral session progress (Neutral Progress Rule): one `3pt` segment per
/// word, `textMuted` once done, Hairline while left, so the count of words
/// left can be read off the bar. Long sessions fall back to one track.
class SessionTrack extends StatelessWidget {
  const SessionTrack({super.key, required this.done, required this.total});

  static const maxSegments = 12;

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    if (total == 0 || total > maxSegments) {
      return HairlineTrack(fraction: total == 0 ? 0 : done / total);
    }
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 3),
          Expanded(
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: i < done
                    ? context.appColors.textMuted
                    : context.appColors.hairline,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _BarButton extends StatelessWidget {
  const _BarButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: CupertinoButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        minimumSize: const Size(44, 44),
        child: Semantics(
          label: label,
          excludeSemantics: true,
          child: Icon(icon, size: 22, color: context.appColors.textPrimary),
        ),
      ),
    );
  }
}

/// The German translation of the word, and, folded out, of the sentence.
class PracticeTranslationCard extends StatelessWidget {
  const PracticeTranslationCard({
    super.key,
    required this.translation,
    required this.sentence,
    required this.open,
    required this.onToggle,
  });

  final String translation;
  final String sentence;
  final bool open;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Container(
      decoration: BoxDecoration(
        color: context.appColors.raisedInk,
        border: Border.all(color: context.appColors.hairline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MergeSemantics(
            child: CupertinoButton(
              onPressed: onToggle,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              minimumSize: const Size(44, 56),
              pressedOpacity: 0.7,
              child: Semantics(
                label: 'Übersetzung: $translation, ganzer Satz',
                expanded: open,
                excludeSemantics: true,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        translation,
                        style: AppType.editorial(
                          color: context.appColors.textPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      open
                          ? CupertinoIcons.chevron_up
                          : CupertinoIcons.chevron_down,
                      size: 16,
                      color: context.appColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: open
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(height: 1, color: context.appColors.hairline),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                        child: Text(
                          sentence,
                          style: AppType.editorial(
                            size: 18,
                            weight: FontWeight.w400,
                            color: context.appColors.textMuted,
                            height: 1.45,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// Sits on the bottom edge, or right above the keyboard while it is open.
/// One right-aligned action; success is separate and requires a saved review.
class PracticeAnswerToolbar extends StatelessWidget {
  const PracticeAnswerToolbar({
    super.key,
    required this.speakerEnabled,
    required this.playing,
    required this.onSpeak,
    required this.message,
    required this.solved,
    required this.saved,
    required this.hasInput,
    required this.revealed,
    required this.onReveal,
    required this.onSubmit,
    required this.onNext,
    required this.nextLabel,
  });
  final bool speakerEnabled, playing, solved, revealed, saved, hasInput;
  final String? message;
  final String nextLabel;
  final VoidCallback onSpeak, onReveal, onSubmit;
  final VoidCallback? onNext;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.appColors.raisedInk,
      border: Border(top: BorderSide(color: context.appColors.hairline)),
    ),
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        8 +
            math.max(
              MediaQuery.viewInsetsOf(context).bottom,
              MediaQuery.viewPaddingOf(context).bottom,
            ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  message!,
                  style: AppType.chrome(
                    size: 13,
                    color: context.appColors.textMuted,
                  ),
                ),
              ),
            ),
          Row(
            children: [
              Semantics(
                label: 'Aussprechen, noch nicht verfügbar',
                enabled: false,
                child: SizedBox(
                  width: 44,
                  child: Icon(
                    CupertinoIcons.speaker_2,
                    color: context.appColors.iconOff,
                  ),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final slotWidth = math.min(
                      264.0,
                      math.max(1.0, constraints.maxWidth),
                    );
                    final label = solved
                        ? nextLabel
                        : hasInput
                        ? 'Eingeben'
                        : 'Wort erfahren';
                    final action = solved
                        ? onNext
                        : hasInput
                        ? onSubmit
                        : revealed
                        ? null
                        : onReveal;
                    var slotHeight = 48.0;
                    for (final text in const [
                      'Wort erfahren',
                      'Eingeben',
                      'Weiter',
                      'Wird gespeichert …',
                      'Speichern wiederholen',
                    ]) {
                      final painter = TextPainter(
                        text: TextSpan(
                          text: text,
                          style: AppType.chrome(weight: FontWeight.w600),
                        ),
                        textDirection: TextDirection.ltr,
                        textScaler: MediaQuery.textScalerOf(context),
                      )..layout(maxWidth: math.max(1, slotWidth - 76));
                      slotHeight = math.max(slotHeight, painter.height + 20);
                      painter.dispose();
                    }
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: slotWidth,
                          height: slotHeight,
                          child: ClipRect(
                            child: AnimatedSwitcher(
                              duration: MediaQuery.disableAnimationsOf(context)
                                  ? Duration.zero
                                  : const Duration(milliseconds: 140),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              layoutBuilder: (current, previous) => Stack(
                                alignment: Alignment.centerRight,
                                children: [
                                  for (final child in previous)
                                    ExcludeSemantics(
                                      child: IgnorePointer(child: child),
                                    ),
                                  ?current,
                                ],
                              ),
                              transitionBuilder: (child, animation) =>
                                  SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(1, 0),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    ),
                                  ),
                              child: Row(
                                key: ValueKey(label),
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 44,
                                    child: saved
                                        ? Semantics(
                                            label: 'Richtig gespeichert',
                                            child: Container(
                                              key: const ValueKey(
                                                'practice-success',
                                              ),
                                              width: 28,
                                              height: 28,
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: context
                                                    .appColors
                                                    .memoryLevel2,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                CupertinoIcons.check_mark,
                                                size: 20,
                                                color:
                                                    context.appColors.nightPage,
                                              ),
                                            ),
                                          )
                                        : null,
                                  ),
                                  Flexible(
                                    child: _ToolbarButton(
                                      label: label,
                                      primary: solved || hasInput,
                                      onPressed: action,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

/// A `48dp` pill. Primary: `textPrimary` fill, Night Page label (the
/// Primary button's grammar). Otherwise a quiet Hairline fill.
class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.label,
    required this.onPressed,
    this.primary = false,
  });

  final String label;
  final bool primary;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final foreground = primary
        ? context.appColors.nightPage
        : (enabled ? context.appColors.textPrimary : context.appColors.iconOff);
    return MergeSemantics(
      child: CupertinoButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        minimumSize: const Size(48, 48),
        child: Semantics(
          label: label,
          enabled: enabled,
          excludeSemantics: true,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: primary
                  ? context.appColors.textPrimary
                  : context.appColors.hairline,
              border: primary
                  ? null
                  : Border.all(color: context.appColors.hairline),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: null,
                    textAlign: TextAlign.center,
                    style: AppType.chrome(
                      weight: FontWeight.w600,
                      color: foreground,
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
