import 'package:flutter/cupertino.dart';

import '../../../models/playback_clock.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/playback_controls.dart';

/// Player docked above the reading toolbar while "Vorlesen" is on: skip
/// back, play/pause, skip ahead, then the position on a neutral track with
/// elapsed and total time.
class NarrationPanel extends StatelessWidget {
  const NarrationPanel({super.key, required this.narration});

  final PlaybackClock narration;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: narration,
      builder: (context, _) => DecoratedBox(
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
                    onPressed: () => narration.skip(-PlaybackClock.skipStep),
                  ),
                  const SizedBox(width: 28),
                  PlayPauseButton(
                    playing: narration.playing,
                    onPressed: narration.toggle,
                  ),
                  const SizedBox(width: 28),
                  _SkipButton(
                    label: '15 Sekunden vor',
                    icon: CupertinoIcons.goforward_15,
                    onPressed: () => narration.skip(PlaybackClock.skipStep),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              PlaybackTrack(clock: narration),
            ],
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
