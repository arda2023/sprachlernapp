import 'package:flutter/cupertino.dart';

import '../theme/app_theme.dart';

/// "Mehr ansehen ›" at the right end of a section heading; opens the full
/// list. [semanticLabel] names the target when several sit on one screen.
class MoreButton extends StatelessWidget {
  const MoreButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback onPressed;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppType.chrome(
            color: context.appColors.textPrimary,
            size: 15,
            weight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 2),
        Icon(
          CupertinoIcons.chevron_right,
          size: 14,
          color: context.appColors.textMuted,
        ),
      ],
    );
    return MergeSemantics(
      child: CupertinoButton(
        onPressed: onPressed,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        minimumSize: const Size(44, 44),
        child: semanticLabel == null
            ? row
            : Semantics(
                label: semanticLabel,
                excludeSemantics: true,
                child: row,
              ),
      ),
    );
  }
}
