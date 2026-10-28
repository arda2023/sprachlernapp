import 'package:flutter/cupertino.dart';

import '../theme/app_theme.dart';

/// Building blocks for content on the orange popover (white ink), so every
/// bubble – language, goal, import, word menu, practice menu, form info –
/// reads the same.
const popoverInk = Color(0xFFFFFFFF);

/// Text on the popover. White on #E26C00 reaches 3.3:1, which HIG ›
/// Accessibility accepts only for bold text or text of 18 pt and more:
/// body copy is 18 pt, small print bold, and nothing is translucent.
/// Hierarchy comes from size and weight.
abstract final class PopoverText {
  static TextStyle body({FontWeight weight = FontWeight.w500}) =>
      AppType.chrome(size: 18, weight: weight, color: popoverInk, height: 1.35);

  /// Short notes (14 pt, bold).
  static TextStyle small() => AppType.chrome(
    size: 14,
    weight: FontWeight.w700,
    color: popoverInk,
    height: 1.35,
  );

  /// Labels and metadata (13 pt, bold).
  static TextStyle caption() =>
      AppType.chrome(size: 13, weight: FontWeight.w700, color: popoverInk);
}

/// Width of menu popovers: only as wide as their rows need (HIG › Popovers:
/// "Avoid making a popover too big").
const menuPopoverWidth = 300.0;

/// Bold popover heading ("Sprache wählen", "Tagesziel").
class PopoverTitle extends StatelessWidget {
  const PopoverTitle(this.text, {super.key, this.editorial = false});

  final String text;

  /// Serif for content (a word, a form), sans for interface headings.
  final bool editorial;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(
      text,
      style: editorial
          ? AppType.editorial(color: popoverInk, size: 24)
          : AppType.chrome(size: 20, weight: FontWeight.w800, color: popoverInk),
    ),
  );
}

/// A thin white rule between popover sections.
class PopoverDivider extends StatelessWidget {
  const PopoverDivider({super.key});

  @override
  Widget build(BuildContext context) => Container(
    height: 1,
    color: popoverInk.withValues(alpha: 0.25),
  );
}

/// One row in a popover menu: white icon, label and a chevron, or a round
/// check when the row toggles something ([toggled] not null).
class PopoverMenuRow extends StatelessWidget {
  const PopoverMenuRow({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.toggled,
    this.chevron = true,
  });

  final String label;
  final IconData icon;

  /// Null: shown dimmed, not available here.
  final VoidCallback? onTap;

  /// Null: a plain action, no switch.
  final bool? toggled;
  final bool chevron;

  @override
  Widget build(BuildContext context) {
    final on = toggled;
    final enabled = onTap != null;
    final ink = enabled ? popoverInk : popoverInk.withValues(alpha: 0.5);
    return MergeSemantics(
      child: CupertinoButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        minimumSize: const Size(44, 48),
        child: Semantics(
          label: label,
          toggled: on,
          enabled: enabled,
          excludeSemantics: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Icon(icon, size: 20, color: ink),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: AppType.chrome(weight: FontWeight.w700, color: ink),
                  ),
                ),
                if (on != null)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: on ? popoverInk : const Color(0x33FFFFFF),
                    ),
                    child: on
                        ? Icon(
                            CupertinoIcons.checkmark_alt,
                            size: 16,
                            color: context.appColors.popover,
                          )
                        : null,
                  )
                else if (chevron)
                  Icon(CupertinoIcons.chevron_right, size: 16, color: ink),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The popover's main action: a white pill with popover-orange text, like
/// "Auswählen" in the language picker.
class PopoverPillButton extends StatelessWidget {
  const PopoverPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final ink = enabled ? context.appColors.popover : popoverInk;
    return MergeSemantics(
      child: CupertinoButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        minimumSize: const Size(44, 50),
        child: Semantics(
          label: label,
          enabled: enabled,
          excludeSemantics: true,
          child: Container(
            constraints: const BoxConstraints(minHeight: 50),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: enabled ? popoverInk : popoverInk.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon case final icon?) ...[
                  Icon(icon, size: 18, color: ink),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: AppType.chrome(weight: FontWeight.w800, color: ink),
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

/// A popover trigger that is not a pill itself (a label, the level
/// dashes): while its popover shows it sits on a popover-orange pill.
/// [shift] pulls the pill's inset back so the content keeps its place.
class TriggerPill extends StatelessWidget {
  const TriggerPill({
    super.key,
    required this.open,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
  });

  final bool open;
  final EdgeInsets padding;
  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(end: open ? 1 : 0),
    duration: const Duration(milliseconds: 160),
    curve: Curves.easeOut,
    builder: (context, t, child) => Transform.translate(
      offset: Offset(-padding.left, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.appColors.popover.withValues(alpha: t),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Padding(padding: padding, child: child),
      ),
    ),
    child: child,
  );
}
