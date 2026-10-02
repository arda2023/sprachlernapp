import 'package:flutter/cupertino.dart';

import '../../../theme/app_theme.dart';

/// Audio Playback Exception (DESIGN.md): a slate-blue background behind text
/// while it is read aloud. The horizontal [inset] pads the text inside the
/// mark; callers indent neighbouring text by the same amount so everything
/// stays left-aligned.
class PlaybackHighlight extends StatelessWidget {
  const PlaybackHighlight({
    super.key,
    required this.active,
    required this.child,
  });

  static const inset = 6.0;

  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return AnimatedContainer(
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: inset, vertical: 2),
      decoration: BoxDecoration(
        color: active
            ? AppColors.playback
            : AppColors.playback.withValues(alpha: 0),
        borderRadius: BorderRadius.circular(6),
      ),
      child: child,
    );
  }
}

/// Playback keys, so the list and the details sheet mark the same item.
String wordAudioKey(String wordId) => '$wordId/word';
String sentenceAudioKey(String wordId) => '$wordId/sentence';

/// Tap target that reads [child] aloud: at least 44pt tall, left-aligned,
/// highlighted while [playing].
class ListenButton extends StatelessWidget {
  const ListenButton({
    super.key,
    required this.label,
    required this.playing,
    required this.onPressed,
    required this.child,
  });

  final String label;
  final bool playing;
  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: CupertinoButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        minimumSize: const Size(44, 44),
        pressedOpacity: 0.8,
        alignment: Alignment.centerLeft,
        child: Semantics(
          label: label,
          excludeSemantics: true,
          child: PlaybackHighlight(active: playing, child: child),
        ),
      ),
    );
  }
}

/// Headword in the editorial serif with a speaker that fills while playing.
class HeadwordWithSpeaker extends StatelessWidget {
  const HeadwordWithSpeaker({
    super.key,
    required this.headword,
    required this.playing,
    this.size = 22,
  });

  final String headword;
  final bool playing;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(headword, style: AppType.editorial(size: size)),
        ),
        const SizedBox(width: 8),
        Icon(
          playing ? CupertinoIcons.speaker_2_fill : CupertinoIcons.speaker_2,
          size: size * 0.85,
          color: playing ? AppColors.textPrimary : AppColors.textMuted,
        ),
      ],
    );
  }
}
