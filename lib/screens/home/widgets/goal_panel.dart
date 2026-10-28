import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../presentation/providers/learning_providers.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/popover_content.dart';

/// Popover content behind the target icon: today's progress and the daily
/// goal choice. The goal is a recommendation, never a lockout (PRODUCT.md).
class GoalPanel extends ConsumerWidget {
  const GoalPanel({super.key, required this.onSetGoal});

  static const options = [5, 10, 15, 20, 30];

  final ValueChanged<int> onSetGoal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const white = Color(0xFFFFFFFF);
    final goal = ref.watch(learningProgressProvider).value?.goal;
    if (goal == null) return const SizedBox(height: 120);
    final base = PopoverText.body();
    final fraction = (goal.done / goal.target).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Tagesziel',
            style: AppType.chrome(
              size: 20,
              weight: FontWeight.w800,
              color: white,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text.rich(
          TextSpan(
            style: base,
            children: [
              const TextSpan(text: 'Du hast heute '),
              TextSpan(
                text: '${goal.done} von ${goal.target}',
                style: base.copyWith(fontWeight: FontWeight.w800),
              ),
              const TextSpan(text: ' Wörtern geübt.'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: SizedBox(
            height: 8,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: Color(0x4DFFFFFF)),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: fraction,
                  child: const ColoredBox(color: white),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Tagesziel anpassen',
          style: PopoverText.small(),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final target in options)
              _GoalChip(
                target: target,
                selected: target == goal.target,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onSetGoal(target);
                },
              ),
          ],
        ),
      ],
    );
  }
}

class _GoalChip extends StatelessWidget {
  const _GoalChip({
    required this.target,
    required this.selected,
    required this.onTap,
  });

  final int target;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: CupertinoButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        minimumSize: const Size(44, 44),
        child: Semantics(
          label: '$target Wörter pro Tag',
          selected: selected,
          excludeSemantics: true,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            constraints: const BoxConstraints(minWidth: 52),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFFFFFFFF)
                  : const Color(0x33FFFFFF),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              '$target',
              textAlign: TextAlign.center,
              style: AppType.chrome(
                size: 16,
                weight: FontWeight.w800,
                color: selected
                    ? context.appColors.popover
                    : const Color(0xFFFFFFFF),
                tabular: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
