import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../presentation/audio/device_speech_playback.dart';
import '../presentation/providers/database_providers.dart';
import '../theme/app_theme.dart';
import 'speaker_icon.dart';

/// Native pronunciation, shared with the other speech surfaces.
class SpeakButton extends ConsumerStatefulWidget {
  const SpeakButton({
    super.key,
    this.diameter = 44,
    this.label = 'Aussprechen',
    this.text = '',
    this.language,
    this.ink = const Color(0xFFFFFFFF),
    this.fill = const Color(0x33FFFFFF),
  });
  final double diameter;
  final String label, text;
  final String? language;

  /// Symbol and, while speaking, the disc. White on the orange bubbles by
  /// default; exercises pass their stage's ink.
  final Color ink;

  /// The resting disc behind the symbol.
  final Color fill;
  @override
  ConsumerState<SpeakButton> createState() => _SpeakButtonState();
}

class _SpeakButtonState extends ConsumerState<SpeakButton> {
  late final _speech = DeviceSpeechPlayback(
    language: () =>
        widget.language ??
        ref.read(selectedContentLanguageProvider).asData?.value,
    onError: (message) => showSpeechError(context, message),
  );
  @override
  void didUpdateWidget(SpeakButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.language != widget.language) {
      _speech.stop();
    }
  }

  @override
  void dispose() {
    _speech.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _speech,
    builder: (context, _) {
      final on = _speech.playing != null;
      return MergeSemantics(
        child: CupertinoButton(
          onPressed: widget.text.trim().isEmpty
              ? null
              : () => _speech.play('word', widget.text),
          padding: EdgeInsets.zero,
          minimumSize: const Size(44, 44),
          child: Semantics(
            label: on ? 'Vorlesen stoppen' : widget.label,
            excludeSemantics: true,
            child: Container(
              width: widget.diameter,
              height: widget.diameter,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: on ? widget.ink : widget.fill,
              ),
              child: on
                  ? Icon(
                      CupertinoIcons.stop_fill,
                      size: widget.diameter * 0.45,
                      color: context.appColors.popover,
                    )
                  : SpeakerIcon(size: widget.diameter * 0.5, color: widget.ink),
            ),
          ),
        ),
      );
    },
  );
}
