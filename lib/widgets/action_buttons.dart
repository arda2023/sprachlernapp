import 'package:flutter/cupertino.dart';

import '../theme/app_theme.dart';

/// The one filled button: textPrimary fill, Night Page label. Neutral chrome,
/// never a status ink.
class PrimaryActionButton extends StatelessWidget {
  const PrimaryActionButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => _ActionButton(
    label: label,
    onPressed: onPressed,
    fill: context.appColors.textPrimary,
    border: context.appColors.textPrimary,
    foreground: context.appColors.nightPage,
  );
}

/// Night Page fill with a hairline edge; sits inset on Raised Ink surfaces.
class OutlineActionButton extends StatelessWidget {
  const OutlineActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => _ActionButton(
    label: label,
    icon: icon,
    onPressed: onPressed,
    fill: context.appColors.nightPage,
    border: context.appColors.hairline,
    foreground: onPressed == null
        ? context.appColors.textMuted
        : context.appColors.textPrimary,
  );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onPressed,
    required this.fill,
    required this.border,
    required this.foreground,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color fill;
  final Color border;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: CupertinoButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        pressedOpacity: 0.7,
        minimumSize: const Size(44, 52),
        child: Semantics(
          label: label,
          enabled: onPressed != null,
          excludeSemantics: true,
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: fill,
              border: Border.all(color: border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon case final icon?) ...[
                  Icon(icon, size: 18, color: foreground),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: AppType.chrome(
                      weight: FontWeight.w600,
                      color: foreground,
                    ),
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
