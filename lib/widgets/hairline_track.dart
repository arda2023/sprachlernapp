import 'package:flutter/widgets.dart';

import '../theme/app_theme.dart';

/// A thin pill track: hairline groove with a left-aligned fill.
/// Pass a status ink only when the fill means word status; progress that is
/// not word status (daily goal, reading position) stays neutral.
class HairlineTrack extends StatelessWidget {
  const HairlineTrack({
    super.key,
    required this.fraction,
    this.color,
    this.height = 3,
  });

  final double fraction;
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: height,
        child: ColoredBox(
          color: context.appColors.hairline,
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: fraction.clamp(0.0, 1.0),
            child: ColoredBox(color: color ?? context.appColors.textMuted),
          ),
        ),
      ),
    );
  }
}
