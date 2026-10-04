import 'package:flutter/cupertino.dart';

import '../../../models/home_models.dart';
import '../../../theme/app_theme.dart';

/// Week row (Understated Streak Rule) plus today's goal with a gear to change
/// it. Everything here is neutral: neither the streak nor the goal is a word
/// status.
class WeeklyGoalCard extends StatelessWidget {
  const WeeklyGoalCard({
    super.key,
    required this.week,
    required this.goal,
    required this.onEditGoal,
  });

  static const _names = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
  static const _longNames = [
    'Montag',
    'Dienstag',
    'Mittwoch',
    'Donnerstag',
    'Freitag',
    'Samstag',
    'Sonntag',
  ];

  final WeekProgress week;
  final DailyGoal goal;
  final VoidCallback onEditGoal;

  String _weekLabel() {
    final parts = [
      for (final (i, mark) in week.days.indexed)
        '${_longNames[i]} ${switch (mark) {
          DayMark.met => 'erreicht',
          DayMark.missed => 'verfehlt',
          DayMark.today => 'heute',
          DayMark.upcoming => 'offen',
        }}',
    ];
    return 'Diese Woche: ${parts.join(', ')}';
  }

  @override
  Widget build(BuildContext context) {
    final reached = goal.done >= goal.target;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 4, 4),
      decoration: BoxDecoration(
        color: context.appColors.raisedInk,
        border: Border.all(color: context.appColors.hairline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Semantics(
              container: true,
              label: _weekLabel(),
              excludeSemantics: true,
              child: Row(
                children: [
                  for (final (i, mark) in week.days.indexed)
                    Expanded(
                      child: _DayCell(
                        name: _names[i],
                        mark: mark,
                        todayReached: reached,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: ColoredBox(
              color: context.appColors.hairline,
              child: SizedBox(height: 1),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  label: 'Tagesziel: ${goal.done} von ${goal.target} Wörtern',
                  excludeSemantics: true,
                  child: Text.rich(
                    TextSpan(
                      style: AppType.chrome(
                        color: context.appColors.textPrimary,
                        size: 17,
                      ),
                      children: [
                        TextSpan(
                          text: '${goal.done}',
                          style: AppType.chrome(
                            color: context.appColors.textPrimary,
                            size: 17,
                            weight: FontWeight.w700,
                            tabular: true,
                          ),
                        ),
                        TextSpan(text: ' von ${goal.target} Wörtern'),
                      ],
                    ),
                  ),
                ),
              ),
              MergeSemantics(
                child: CupertinoButton(
                  onPressed: onEditGoal,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(44, 44),
                  child: Semantics(
                    label: 'Tagesziel ändern',
                    excludeSemantics: true,
                    child: Icon(
                      CupertinoIcons.gear_alt,
                      size: 20,
                      color: context.appColors.textMuted,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.name,
    required this.mark,
    required this.todayReached,
  });

  final String name;
  final DayMark mark;
  final bool todayReached;

  @override
  Widget build(BuildContext context) {
    final today = mark == DayMark.today;
    final icon = switch (mark) {
      DayMark.met => Icon(
        CupertinoIcons.checkmark,
        size: 15,
        color: context.appColors.textPrimary,
      ),
      DayMark.missed => Icon(
        CupertinoIcons.xmark,
        size: 13,
        color: context.appColors.textMuted,
      ),
      DayMark.today when todayReached => Icon(
        CupertinoIcons.checkmark,
        size: 15,
        color: context.appColors.textPrimary,
      ),
      _ => null,
    };
    return Column(
      children: [
        Text(
          name,
          maxLines: 1,
          style: today
              ? AppType.chrome(
                  color: context.appColors.textPrimary,
                  size: 13,
                  weight: FontWeight.w700,
                )
              : AppType.meta(color: context.appColors.textMuted),
        ),
        const SizedBox(height: 8),
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: today
                  ? context.appColors.textPrimary
                  : context.appColors.hairline,
              width: today ? 1.5 : 1,
            ),
          ),
          child: icon,
        ),
      ],
    );
  }
}
