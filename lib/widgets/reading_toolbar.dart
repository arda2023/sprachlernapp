import 'package:flutter/cupertino.dart';

import '../theme/app_theme.dart';

/// Bottom toolbar of the reader and text exercises. Holds the translation
/// toggle and, while it is on, the hint telling the learner what to do.
class ReadingToolbar extends StatelessWidget {
  const ReadingToolbar({
    super.key,
    required this.translating,
    required this.onToggleTranslate,
  });

  static const hint = 'Tippe auf einen Satz, um ihn zu übersetzen';

  final bool translating;
  final VoidCallback onToggleTranslate;

  @override
  Widget build(BuildContext context) {
    final color = translating ? AppColors.textPrimary : AppColors.textMuted;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.raisedInk,
        border: Border(top: BorderSide(color: AppColors.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: translating
                      ? Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            hint,
                            style: AppType.chrome(
                              size: 13,
                              color: AppColors.textMuted,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(width: 8),
                MergeSemantics(
                  child: CupertinoButton(
                    onPressed: onToggleTranslate,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(44, 44),
                    child: Semantics(
                      label: 'Übersetzen',
                      toggled: translating,
                      excludeSemantics: true,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: translating ? AppColors.hairline : null,
                          border: Border.all(color: AppColors.hairline),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.textformat_abc,
                              size: 20,
                              color: color,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Übersetzen',
                              style: AppType.chrome(
                                weight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
