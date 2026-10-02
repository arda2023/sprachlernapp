import 'package:flutter/cupertino.dart';

import '../theme/app_theme.dart';

/// Neutral segmented control: Raised Ink groove, Hairline thumb, `44pt`
/// segments, labels in `textMuted` and `textPrimary` when selected. Text
/// scaling is clamped like the tab labels, since the segments share one row.
class SegmentedTabs<T extends Object> extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.values,
    required this.labelOf,
    required this.selected,
    required this.onChanged,
  });

  final List<T> values;
  final String Function(T value) labelOf;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: CupertinoSlidingSegmentedControl<T>(
        groupValue: selected,
        backgroundColor: AppColors.raisedInk,
        thumbColor: AppColors.hairline,
        padding: const EdgeInsets.all(2),
        onValueChanged: (value) {
          if (value != null) onChanged(value);
        },
        children: {
          for (final value in values)
            value: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Center(
                child: Text(
                  labelOf(value),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: AppType.chrome(
                    size: 13,
                    weight: FontWeight.w600,
                    color: value == selected
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                  ),
                ),
              ),
            ),
        },
      ),
    );
  }
}
