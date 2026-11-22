import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../../domain/tutor.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/anchored_popover.dart';
import '../../../widgets/popover_content.dart';
import '../../../widgets/press_scale.dart';

/// The deck grammar chip's geometry, with the tutor's two information roles.
class TutorInfoChip extends StatelessWidget {
  const TutorInfoChip({super.key, required this.item});
  final TutorItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final situation = item.kind == TutorKind.situation;
    final label = situation ? 'Situation' : 'Übersetzen';
    return TutorPopoverButton(
      label: label,
      explanation: situation
          ? 'Wie würdest du in dieser Situation ${tutorInLanguage(item.lang)} antworten?'
          : 'Übersetze den Satz unten ${tutorIntoLanguage(item.lang)}.',
      color: situation ? AppColors.memoryLevel2 : colors.popover,
      builder: (context, open) => AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: open
              ? situation
                    ? AppColors.memoryLevel2
                    : colors.popover
              : situation
              ? colors.playback
              : colors.activeTint,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.info_circle,
              size: 15,
              color: open
                  ? colors.onActive
                  : situation
                  ? colors.memoryLevel2
                  : colors.active,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: AppType.chrome(
                  size: 13,
                  weight: FontWeight.w500,
                  color: open ? colors.onActive : colors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One labeled, 44 pt target; the popover points at the actual button.
class TutorPopoverButton extends StatefulWidget {
  const TutorPopoverButton({
    super.key,
    required this.label,
    required this.explanation,
    required this.builder,
    this.color,
  });
  final String label, explanation;
  final Color? color;
  final Widget Function(BuildContext, bool open) builder;

  @override
  State<TutorPopoverButton> createState() => _TutorPopoverButtonState();
}

class _TutorPopoverButtonState extends State<TutorPopoverButton> {
  final _anchor = GlobalKey();
  bool _open = false;

  Future<void> _show() async {
    if (_open) return;
    HapticFeedback.selectionClick();
    setState(() => _open = true);
    try {
      await showAnchoredPopover<void>(
        anchorContext: _anchor.currentContext!,
        color: widget.color ?? context.appColors.popover,
        builder: (_) => Text(widget.explanation, style: PopoverText.body()),
      );
    } finally {
      if (mounted) setState(() => _open = false);
    }
  }

  @override
  Widget build(BuildContext context) => PressScale(
    child: Semantics(
      key: _anchor,
      button: true,
      label: widget.label,
      hint: 'Erklärung anzeigen',
      expanded: _open,
      onTap: _show,
      excludeSemantics: true,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: const Size(44, 44),
        onPressed: _show,
        child: widget.builder(context, _open),
      ),
    ),
  );
}
