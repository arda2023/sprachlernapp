import 'package:flutter/cupertino.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/anchored_popover.dart';
import '../../../widgets/popover_content.dart';

/// Translation mode in the reader: the tapped sentence and its German
/// translation, pointing at the sentence.
class SentencePopover extends StatelessWidget {
  const SentencePopover({
    super.key,
    required this.original,
    required this.translation,
  });

  final String original;
  final String translation;

  static Future<void> show(
    BuildContext context, {
    required Rect anchor,
    required String original,
    required String translation,
  }) => showAnchoredPopoverAt<void>(
    context: context,
    anchor: anchor,
    color: context.appColors.popover,
    builder: (_) =>
        SentencePopover(original: original.trim(), translation: translation),
  );

  @override
  Widget build(BuildContext context) {
    const white = Color(0xFFFFFFFF);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          original,
          style: AppType.editorial(
            color: white,
            size: 19,
            weight: FontWeight.w600,
            height: 1.4,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 12),
        Container(height: 1, color: white.withValues(alpha: 0.25)),
        const SizedBox(height: 10),
        Text('Deutsch', style: PopoverText.caption()),
        const SizedBox(height: 2),
        Text(
          translation,
          style: AppType.editorial(
            color: white,
            size: 19,
            weight: FontWeight.w400,
            height: 1.4,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}
