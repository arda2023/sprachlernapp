import 'package:flutter/cupertino.dart';

import '../theme/app_theme.dart';

/// A list entry that opens a screen: title (Figtree 17 w600), a one-line
/// [summary], an optional [meta] line, a `textMuted` chevron and a Hairline
/// rule below. At least `72pt` tall.
class ChevronRow extends StatelessWidget {
  const ChevronRow({
    super.key,
    required this.title,
    required this.summary,
    required this.onTap,
    this.meta,
  });

  final String title;
  final String summary;
  final String? meta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: CupertinoButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        pressedOpacity: 0.7,
        minimumSize: const Size(44, 56),
        child: Semantics(
          label: [title, summary, ?meta].join(', '),
          excludeSemantics: true,
          child: Container(
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.hairline)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppType.chrome(
                          size: 17,
                          weight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        summary,
                        style: AppType.chrome(color: AppColors.textMuted),
                      ),
                      if (meta case final meta?) ...[
                        const SizedBox(height: 6),
                        Text(meta, style: AppType.meta()),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(
                  CupertinoIcons.chevron_right,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
