import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../../../theme/app_theme.dart';

/// Close (ends the session), the session's progress as orange segments
/// (the count only for screen readers), and the word menu (Redesign 20.10.2026).
class PracticeSessionBar extends StatelessWidget {
  const PracticeSessionBar({
    super.key,
    required this.done,
    required this.total,
    this.loading = false,
    this.goalReached = false,
    this.repeating = false,
    this.repeatIndices = const {},
    this.activeRepeat = false,
    required this.onHome,
    required this.onMenu,
  });

  final Set<int> repeatIndices;
  final bool activeRepeat;
  final int done;
  final int total;
  final bool loading, goalReached, repeating;
  final VoidCallback onHome;
  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context) {
    final left = total - done;
    final counting = !loading && total > 0 && !repeating && left > 0;
    final label = loading
        ? 'Übungen werden geladen …'
        : total == 0
        ? 'Nichts offen'
        : repeating
        ? 'Fehlerwiederholung'
        : left == 0
        ? 'Alle Übungen geübt'
        : 'Noch $left ${left == 1 ? 'Übung' : 'Übungen'}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          _BarButton(
            label: 'Session beenden',
            icon: CupertinoIcons.xmark,
            onPressed: onHome,
          ),
          Expanded(
            child: Semantics(
              label: label,
              excludeSemantics: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  // The track spans the space between the two buttons.
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ContinuousSessionTrack(
                      done: done, total: total,
                      repeatIndices: repeatIndices, activeRepeat: activeRepeat,
                    ),
                    // The bar shows what's left; only states it can't show
                    // get a line.
                    if (!counting) ...[
                      const SizedBox(height: 6),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.meta(color: context.appColors.textMuted),
                      ),
                    ],
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

/// A continuous timeline. Completed repeat phases keep their yellow colour.
class ContinuousSessionTrack extends StatelessWidget {
  const ContinuousSessionTrack({super.key, required this.done,
    required this.total, this.repeatIndices = const {}, this.activeRepeat = false});
  final int done, total;
  final Set<int> repeatIndices;
  final bool activeRepeat;
  static const repeatColor = Color(0xFFF2C94C);

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(99),
    child: SizedBox(height: 6, child: LayoutBuilder(
      builder: (context, constraints) => Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: context.appColors.hairline),
          for (var i = 0; i < (done + (activeRepeat ? 1 : 0)).clamp(0, total); i++)
            Positioned(left: constraints.maxWidth * i / total,
              width: constraints.maxWidth / total, top: 0, bottom: 0,
              child: ColoredBox(color: repeatIndices.contains(i)
                ? repeatColor : context.appColors.active)),
        ],
      ),
    )),
  );
}

/// Session progress: one rounded `6pt` segment per word, orange once done,
/// Hairline while left, so the words left can be read off the bar. Long
/// sessions fall back to one bar.
class SessionTrack extends StatelessWidget {
  const SessionTrack({super.key, required this.done, required this.total});

  static const maxSegments = 12;

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    if (total == 0 || total > maxSegments) {
      final fraction = total == 0 ? 0.0 : done / total;
      return ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: SizedBox(
          height: 6,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: context.appColors.hairline),
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: fraction,
                child: ColoredBox(color: context.appColors.active),
              ),
            ],
          ),
        ),
      );
    }
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 6,
              decoration: BoxDecoration(
                color: i < done
                    ? context.appColors.active
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
        borderRadius: BorderRadius.circular(20),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            translation,
                            style: AppType.editorial(
                              color: context.appColors.textPrimary,
                              size: 20,
                            ),
                          ),
                        ],
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
                      Container(
                        height: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        color: context.appColors.hairline.withValues(
                          alpha: 0.6,
                        ),
                      ),
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
    this.error = false,
    this.errorOffset = 0,
  });
  final bool speakerEnabled, playing, solved, revealed, saved, hasInput;
  final String? message;
  final String nextLabel;
  final bool error;
  final double errorOffset;
  final VoidCallback onSpeak, onReveal, onSubmit;
  final VoidCallback? onNext;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    // Same tone as the page: the actions float, no bar edge.
    decoration: BoxDecoration(color: context.appColors.nightPage),
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
                    final label = error
                        ? 'Eingeben'
                        : solved
                        ? nextLabel
                        : hasInput
                        ? 'Eingeben'
                        : 'Wort erfahren';
                    final action = solved
                        ? onNext
                        : hasInput
                        ? onSubmit
                        : onReveal;
                    var slotHeight = 40.0;
                    for (final text in [label]) {
                      final painter = TextPainter(
                        text: TextSpan(
                          text: text,
                          style: AppType.chrome(weight: FontWeight.w800),
                        ),
                        textDirection: TextDirection.ltr,
                        textScaler: MediaQuery.textScalerOf(context),
                      )..layout(maxWidth: math.max(1, slotWidth - 76));
                      slotHeight = math.max(slotHeight, painter.height + 12);
                      painter.dispose();
                    }
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: slotWidth,
                          height: slotHeight,
                          child: Row(
                            key: const ValueKey('practice-action'),
                            mainAxisAlignment: MainAxisAlignment.end,
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
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                context.appColors.progressWords,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            CupertinoIcons.check_mark,
                                            size: 20,
                                            color: Color(0xFFFFFFFF),
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                              Flexible(
                                child: Transform.translate(
                                  key: const ValueKey('practice-button-shake'),
                                  offset: Offset(errorOffset, 0),
                                  child: _ToolbarButton(
                                    error: error,
                                    label: label,
                                    primary: solved || hasInput || error,
                                    onPressed: action,
                                  ),
                                ),
                              ),
                            ],
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

/// A `52dp` pill. Primary: popover orange, white label. Otherwise a quiet
/// Hairline fill, no outline.
class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.label,
    required this.onPressed,
    this.primary = false,
    this.error = false,
  });

  final String label;
  final bool primary, error;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final foreground = error
        ? context.appColors.error
        : primary
        ? const Color(0xFFFFFFFF)
        : (enabled ? context.appColors.textPrimary : context.appColors.iconOff);
    return MergeSemantics(
      child: CupertinoButton(
        onPressed: onPressed,
        pressedOpacity: error ? 1 : .4,
        padding: EdgeInsets.zero,
        minimumSize: const Size(48, 48),
        child: Semantics(
          label: error ? 'Falsch' : label,
          enabled: enabled,
          excludeSemantics: true,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
            decoration: BoxDecoration(
              color: error
                  ? context.appColors.errorTint
                  : primary
                  ? context.appColors.popover
                  : context.appColors.raisedInk,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Opacity(
                        opacity: error ? 0 : 1,
                        child: Text(
                          label,
                          maxLines: null,
                          textAlign: TextAlign.center,
                          style: AppType.chrome(
                            weight: FontWeight.w800,
                            color: foreground,
                          ),
                        ),
                      ),
                      if (error)
                        Text(
                          'Falsch',
                          textAlign: TextAlign.center,
                          style: AppType.chrome(
                            weight: FontWeight.w600,
                            color: foreground,
                          ),
                        ),
                    ],
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
