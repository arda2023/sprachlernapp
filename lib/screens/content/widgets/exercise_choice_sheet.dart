import 'package:flutter/cupertino.dart';

import '../../../models/exercise_models.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/anchored_popover.dart';
import '../../../widgets/popover_content.dart';
import '../../home/widgets/story_carousel.dart';

/// Picks the exercise mode for a text, as the orange popover pointing at
/// the tapped cover. Returns the chosen mode, or null when dismissed.
class ExerciseChoiceSheet extends StatelessWidget {
  const ExerciseChoiceSheet({super.key, required this.text});

  final ExerciseText text;

  /// [context] is the tapped card; the arrow points there.
  static Future<ExerciseMode?> show(BuildContext context, ExerciseText text) =>
      showAnchoredPopover<ExerciseMode>(
        anchorContext: context,
        color: context.appColors.popover,
        builder: (_) => ExerciseChoiceSheet(text: text),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PopoverTitle(text.info.title, editorial: true),
        const SizedBox(height: 4),
        Text(
          storyMetaLine(text.info),
          style: AppType.meta(color: popoverInk.withValues(alpha: 0.85)),
        ),
        const SizedBox(height: 10),
        for (final mode in ExerciseMode.values)
          _ModeOption(
            mode: mode,
            gaps: text.gapCount(mode),
            onTap: () => Navigator.of(context).pop(mode),
          ),
      ],
    );
  }
}

class _ModeOption extends StatelessWidget {
  const _ModeOption({
    required this.mode,
    required this.gaps,
    required this.onTap,
  });

  final ExerciseMode mode;
  final int gaps;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = gaps > 0;
    final detail = enabled
        ? '${mode.description} · $gaps ${gaps == 1 ? 'Lücke' : 'Lücken'}'
        : 'In diesem Text nicht verfügbar';
    return MergeSemantics(
      child: CupertinoButton(
        onPressed: enabled ? onTap : null,
        padding: EdgeInsets.zero,
        pressedOpacity: 0.7,
        minimumSize: const Size(44, 56),
        child: Semantics(
          label: '${mode.title}. $detail',
          enabled: enabled,
          excludeSemantics: true,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: popoverInk.withValues(alpha: 0.25)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mode.title,
                        style: AppType.chrome(
                          size: 17,
                          weight: FontWeight.w700,
                          color: enabled
                              ? popoverInk
                              : popoverInk.withValues(alpha: 0.55),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        detail,
                        style: AppType.meta(
                          color: popoverInk.withValues(
                            alpha: enabled ? 0.85 : 0.55,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 16,
                  color: popoverInk.withValues(alpha: enabled ? 1 : 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
