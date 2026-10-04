import 'package:flutter/cupertino.dart';

import '../theme/app_theme.dart';
import 'action_buttons.dart';
import 'emphasis_text.dart';

/// Closes a solved exercise: a quiet thumbs-up in Quiet Sage on a Sage Tint
/// disc (Feedback Rule: a right answer, inside an exercise), a [title], an
/// optional metadata [subtitle], an optional [explanation] in the editorial
/// serif (English forms in `*…*` set in italic w600), and one action. No
/// illustration, no confetti.
class SuccessFeedbackCard extends StatelessWidget {
  const SuccessFeedbackCard({
    super.key,
    required this.title,
    required this.actionLabel,
    required this.onAction,
    this.subtitle,
    this.explanation,
  });

  final String title;
  final String? subtitle;
  final String? explanation;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.appColors.raisedInk,
        border: Border.all(color: context.appColors.hairline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: context.appColors.successTint,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  CupertinoIcons.hand_thumbsup_fill,
                  size: 24,
                  color: context.appColors.success,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppType.chrome(
                        color: context.appColors.textPrimary,
                        size: 17,
                        weight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle case final subtitle?) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppType.meta(color: context.appColors.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (explanation case final explanation?) ...[
            const SizedBox(height: 14),
            Text.rich(
              emphasisSpan(
                explanation,
                AppType.editorial(
                  color: context.appColors.textPrimary,
                  size: 17,
                  weight: FontWeight.w400,
                  height: 1.45,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          OutlineActionButton(label: actionLabel, onPressed: onAction),
        ],
      ),
    );
  }
}
