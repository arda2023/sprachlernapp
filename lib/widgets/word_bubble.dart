import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../theme/app_theme.dart';
import 'popover_content.dart';
import 'speak_button.dart';

/// The orange word bubble in the reader covers at most half the screen
/// width (user request 31.10.2026); long translations wrap instead. A
/// headword that does not fit on one line widens the bubble just enough,
/// up to the screen width minus the 16 pt gutters (user request 01.11.2026).
double wordBubbleWidth(BuildContext context, {String? word}) {
  final screen = MediaQuery.sizeOf(context).width;
  final base = math.max(208.0, screen * 0.5);
  if (word == null || word.isEmpty) return base;
  final painter = TextPainter(
    text: TextSpan(text: word, style: wordBubbleHeadword()),
    textDirection: TextDirection.ltr,
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: 1,
  )..layout();
  final needed = painter.width + 44 + 44 + wordBubblePadding.horizontal + 4;
  painter.dispose();
  return math.min(math.max(base, needed), math.max(base, screen - 32));
}

/// The headword style of [WordBubbleHeader].
TextStyle wordBubbleHeadword() => AppType.editorial(
  color: popoverInk,
  size: 21,
  weight: FontWeight.w600,
  height: 1.2,
  letterSpacing: 0,
);

/// Tighter than the info bubbles, so the word stays the main thing.
const wordBubblePadding = EdgeInsets.fromLTRB(16, 12, 10, 14);

/// Headword with the speaker right beside it.
class WordBubbleHeader extends StatelessWidget {
  const WordBubbleHeader({
    super.key,
    required this.word,
    required this.speak,
    this.language,
    this.underline = false,
    this.trailing,
  });

  final String word;

  /// E.g. the add button, after the speaker.
  final Widget? trailing;

  /// The exact form to pronounce.
  final String speak;
  final String? language;

  /// Known words keep their underline, like in the text.
  final bool underline;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Expanded(
        child: Text(
          word,
          style: wordBubbleHeadword().copyWith(
            decoration: underline ? TextDecoration.underline : null,
            decorationColor: popoverInk,
            decorationThickness: 2,
          ),
        ),
      ),
      SpeakButton(text: speak, language: language, diameter: 32),
      ?trailing,
    ],
  );
}

/// The translation line under the header.
TextStyle wordBubbleTranslation() => AppType.editorial(
  color: popoverInk,
  size: 18,
  weight: FontWeight.w400,
  height: 1.3,
  letterSpacing: 0,
);

/// "Zum Lernen hinzufügen" as a round icon button: white with an orange
/// plus, a check once the word is in the learning list.
class AddWordButton extends StatelessWidget {
  const AddWordButton({
    super.key,
    required this.onPressed,
    this.done = false,
    this.busy = false,
    this.label = 'Zum Lernen hinzufügen',
  });

  final VoidCallback? onPressed;
  final bool done;
  final bool busy;
  final String label;

  @override
  Widget build(BuildContext context) {
    final orange = context.appColors.popover;
    final enabled = onPressed != null && !busy;
    return MergeSemantics(
      child: CupertinoButton(
        onPressed: enabled ? onPressed : null,
        padding: EdgeInsets.zero,
        minimumSize: const Size(44, 44),
        child: Semantics(
          label: busy ? 'Wird hinzugefügt' : label,
          button: true,
          excludeSemantics: true,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done || !enabled && !busy
                  ? popoverInk.withValues(alpha: 0.22)
                  : popoverInk,
            ),
            child: busy
                ? CupertinoActivityIndicator(radius: 8, color: orange)
                : Icon(
                    done ? CupertinoIcons.checkmark_alt : CupertinoIcons.plus,
                    size: 20,
                    color: done || !enabled ? popoverInk : orange,
                  ),
          ),
        ),
      ),
    );
  }
}

/// The add button's status or error, sent up to the bubble around it so the
/// message can show under the translation, not inside the header row.
class LearningMessageNotification extends Notification {
  const LearningMessageNotification(this.message);

  final String? message;
}
