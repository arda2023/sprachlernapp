import 'package:flutter/cupertino.dart';

import '../theme/app_theme.dart';

/// Top bar of pushed screens: a 44pt back button and an optional trailing
/// widget.
class BackBar extends StatelessWidget {
  const BackBar({super.key, required this.onBack, this.trailing});

  final VoidCallback onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          MergeSemantics(
            child: CupertinoButton(
              onPressed: onBack,
              padding: EdgeInsets.zero,
              minimumSize: const Size(44, 44),
              child: Semantics(
                label: 'Zurück',
                excludeSemantics: true,
                child: const Icon(
                  CupertinoIcons.chevron_left,
                  size: 24,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const Spacer(),
          if (trailing case final trailing?)
            Padding(padding: const EdgeInsets.only(right: 12), child: trailing),
        ],
      ),
    );
  }
}
