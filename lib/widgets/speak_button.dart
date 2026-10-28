import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Pronunciation button on an orange bubble (reader word popover, practice
/// word bubble). Pre-generated audio is not in this copy yet, so pressing
/// it shows the playing state like the Wortliste does: the speaker fills
/// white and pulses gently.
class SpeakButton extends StatefulWidget {
  const SpeakButton({super.key, this.diameter = 44, this.label = 'Aussprechen'});

  /// Visible circle; the tap target stays at least 44 pt.
  final double diameter;
  final String label;

  @override
  State<SpeakButton> createState() => _SpeakButtonState();
}

class _SpeakButtonState extends State<SpeakButton>
    with SingleTickerProviderStateMixin {
  static const _white = Color(0xFFFFFFFF);

  late final _speaking = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void dispose() {
    _speaking.dispose();
    super.dispose();
  }

  void _speak() {
    HapticFeedback.selectionClick();
    _speaking.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return MergeSemantics(
      child: CupertinoButton(
        onPressed: _speak,
        padding: EdgeInsets.zero,
        minimumSize: const Size(44, 44),
        child: Semantics(
          label: widget.label,
          excludeSemantics: true,
          child: AnimatedBuilder(
            animation: _speaking,
            builder: (context, _) {
              final on = _speaking.isAnimating;
              // Gentle pulse while "playing".
              final pulse = on && !reduceMotion
                  ? 1 + 0.08 * (1 - (_speaking.value * 4 % 2 - 1).abs())
                  : 1.0;
              return Transform.scale(
                scale: pulse,
                child: Container(
                  width: widget.diameter,
                  height: widget.diameter,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: on ? _white : const Color(0x33FFFFFF),
                  ),
                  child: Icon(
                    on
                        ? CupertinoIcons.speaker_3_fill
                        : CupertinoIcons.speaker_2_fill,
                    size: widget.diameter * 0.45,
                    color: on ? context.appColors.popover : _white,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
