import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show RoundSliderThumbShape, Slider, SliderTheme, SliderThemeData;

import '../models/playback_clock.dart';
import '../theme/app_theme.dart';

/// The one filled control of a player, like the Primary button: a
/// `textPrimary` disc with a Night Page play/pause glyph.
class PlayPauseButton extends StatelessWidget {
  const PlayPauseButton({
    super.key,
    required this.playing,
    required this.onPressed,
    this.size = 56,
  });

  final bool playing;
  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: CupertinoButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        minimumSize: Size(size, size),
        child: Semantics(
          label: playing ? 'Pause' : 'Abspielen',
          excludeSemantics: true,
          child: Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              color: AppColors.textPrimary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              playing ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill,
              size: size * 0.46,
              color: AppColors.nightPage,
            ),
          ),
        ),
      ),
    );
  }
}

/// Position of [clock] on a neutral `44pt` slider, with elapsed and total
/// time (`m:ss`) flush with the track ends. Dragging seeks.
class PlaybackTrack extends StatelessWidget {
  const PlaybackTrack({super.key, required this.clock});

  final PlaybackClock clock;

  /// The slider's side padding; the time labels sit flush with the track.
  static const _trackInset = 8.0;

  @override
  Widget build(BuildContext context) {
    final total = clock.duration;
    final times = AppType.meta().copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SliderTheme(
          // Neutral Progress Rule: textMuted fill on a Hairline groove,
          // never an ink; no overlay glow (Flat Ground).
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
                value: clock.progress,
                padding: const EdgeInsets.symmetric(horizontal: _trackInset),
                semanticFormatterCallback: (_) =>
                    '${clockLabel(clock.position)} von ${clockLabel(total)}',
                onChanged: (value) => clock.seek(total * value),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _trackInset),
          child: ExcludeSemantics(
            child: Row(
              children: [
                Text(clockLabel(clock.position), style: times),
                const Spacer(),
                Text(clockLabel(total), style: times),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
