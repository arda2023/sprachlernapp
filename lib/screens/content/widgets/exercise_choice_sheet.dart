import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show showModalBottomSheet;

import '../../../models/exercise_models.dart';
import '../../../theme/app_theme.dart';
import '../../home/widgets/story_carousel.dart';

/// Picks the exercise mode for a text. Returns the chosen mode, or null when
/// dismissed.
class ExerciseChoiceSheet extends StatelessWidget {
  const ExerciseChoiceSheet({super.key, required this.text});

  final ExerciseText text;

  static Future<ExerciseMode?> show(BuildContext context, ExerciseText text) =>
      showModalBottomSheet<ExerciseMode>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => ExerciseChoiceSheet(text: text),
      );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                text.info.title,
                style: AppType.editorial(
                  color: context.appColors.textPrimary,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              storyMetaLine(text.info),
              style: AppType.meta(color: context.appColors.textMuted),
            ),
            const SizedBox(height: 16),
            for (final mode in ExerciseMode.values)
              _ModeOption(
                mode: mode,
                gaps: text.gapCount(mode),
                onTap: () => Navigator.of(context).pop(mode),
              ),
          ],
        ),
      ),
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
                top: BorderSide(color: context.appColors.hairline),
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
                          weight: FontWeight.w600,
                          color: enabled
                              ? context.appColors.textPrimary
                              : context.appColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        detail,
                        style: AppType.meta(color: context.appColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 16,
                  color: enabled
                      ? context.appColors.textMuted
                      : context.appColors.iconOff,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
