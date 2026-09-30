import 'package:flutter/widgets.dart';

import '../../../models/home_models.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/hairline_track.dart';

/// The daily goal as a quiet fraction. The fill is neutral: the goal is not a
/// word status, so it never borrows an ink.
class DailyGoalLine extends StatelessWidget {
  const DailyGoalLine({super.key, required this.goal});

  final DailyGoal goal;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Tagesziel: ${goal.done} von ${goal.target} Wörtern',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('Heute', style: AppType.meta()),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${goal.done} von ${goal.target} Wörtern',
                  textAlign: TextAlign.end,
                  style: AppType.chrome(weight: FontWeight.w600, tabular: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          HairlineTrack(fraction: goal.done / goal.target),
        ],
      ),
    );
  }
}
