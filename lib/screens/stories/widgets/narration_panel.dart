import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show RoundSliderThumbShape, Slider, SliderTheme, SliderThemeData;

import '../../../models/story_narration.dart';
import '../../../theme/app_theme.dart';

/// Player docked above the reading toolbar while "Vorlesen" is on: skip
/// back, play/pause, skip ahead, then the position on a neutral track with
/// elapsed and total time.
class NarrationPanel extends StatelessWidget {
  const NarrationPanel({super.key, required this.narration});

  final StoryNarration narration;

  /// The slider's side padding; the time labels sit flush with the track.
  static const _trackInset = 8.0;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: narration,
      builder: (context, _) {
        final total = narration.duration;
        return DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.raisedInk,
            border: Border(top: BorderSide(color: AppColors.hairline)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _SkipButton(
                      label: '15 Sekunden zurück',
                      icon: CupertinoIcons.gobackward_15,
                      onPressed: () => narration.skip(-StoryNarration.skipStep),
                    ),
                    const SizedBox(width: 28),
                    _PlayButton(
                      playing: narration.playing,
                      onPressed: narration.toggle,
                    ),
                    const SizedBox(width: 28),
                    _SkipButton(
                      label: '15 Sekunden vor',
                      icon: CupertinoIcons.goforward_15,
                      onPressed: () => narration.skip(StoryNarration.skipStep),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SliderTheme(
                  // Neutral Progress Rule: textMuted fill on a Hairline
                  // groove, never an ink; no overlay glow (Flat Ground).
                  data: const SliderThemeData(
                    trackHeight: 3,
                    activeTrackColor: AppColors.textMuted,
                    inactiveTrackColor: AppColors.hairline,
                    thumbColor: AppColors.textPrimary,
                    overlayColor: Color(0x00000000),
                    thumbShape: RoundSliderThumbShape(
                      enabledThumbRadius: 7,
                      elevation: 0,
                      pressedElevation: 0,
                    ),
                  ),
                  child: SizedBox(
                    height: 44,
                    child: Semantics(
                      label: 'Position',
                      child: Slider(
                        value: narration.progress,
                        padding: const EdgeInsets.symmetric(
                          horizontal: _trackInset,
                        ),
                        semanticFormatterCallback: (_) =>
                            '${clockLabel(narration.position)} von '
                            '${clockLabel(total)}',
                        onChanged: (value) => narration.seek(total * value),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: _trackInset),
                  child: ExcludeSemantics(
                    child: Row(
                      children: [
                        Text(
                          clockLabel(narration.position),
                          style: AppType.meta().copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          clockLabel(total),
                          style: AppType.meta().copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The panel's one filled control, like the Primary button: `textPrimary`
/// disc, Night Page glyph.
class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.playing, required this.onPressed});

  final bool playing;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: CupertinoButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        minimumSize: const Size(56, 56),
        child: Semantics(
          label: playing ? 'Pause' : 'Abspielen',
          excludeSemantics: true,
          child: Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.textPrimary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              playing ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill,
              size: 26,
              color: AppColors.nightPage,
            ),
          ),
        ),
      ),
    );
  }
}

class _SkipButton extends StatelessWidget {
  const _SkipButton({
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
        minimumSize: const Size(48, 48),
        child: Semantics(
          label: label,
          excludeSemantics: true,
          child: Icon(icon, size: 28, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
