import 'package:flutter/cupertino.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/anchored_popover.dart';
import '../../../widgets/popover_content.dart';
import 'local_submission_sheet.dart';

enum PracticeAction {
  share,
  disable,
  favorite,
  report,
  feedback,
  settings,
}

/// The practice menu ("Mehr"): a popover pointing at [context], the menu
/// button. It closes with the chosen action.
Future<PracticeAction?> showPracticeMenu(
  BuildContext context, {
  required bool favorite,
  required bool canDisable,
}) => showAnchoredPopover<PracticeAction>(
  anchorContext: context,
  color: context.appColors.popover,
  maxWidth: menuPopoverWidth,
  builder: (context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final item in [
        (PracticeAction.share, CupertinoIcons.share, 'Teilen'),
        (
          PracticeAction.disable,
          CupertinoIcons.eye_slash,
          'Wort deaktivieren',
        ),
        (
          PracticeAction.favorite,
          favorite ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
          favorite ? 'Aus Favoriten entfernen' : 'Zu Favoriten hinzufügen',
        ),
        (PracticeAction.report, CupertinoIcons.flag, 'Ein Problem melden'),
        (
          PracticeAction.feedback,
          CupertinoIcons.chat_bubble,
          'Feedback an Sprachapp',
        ),
        (PracticeAction.settings, CupertinoIcons.gear_alt, 'Einstellungen'),
      ])
        PopoverMenuRow(
          label: item.$3,
          icon: item.$2,
          chevron: false,
          onTap: item.$1 != PracticeAction.disable || canDisable
              ? () => Navigator.pop(context, item.$1)
              : null,
        ),
    ],
  ),
);

/// What is wrong with the exercise: a popover at the same menu button.
Future<String?> showProblemCategories(BuildContext context) =>
    showAnchoredPopover<String>(
      anchorContext: context,
      color: context.appColors.popover,
      maxWidth: menuPopoverWidth,
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const PopoverTitle('Ein Problem melden'),
          const SizedBox(height: 6),
          for (final category in problemCategories)
            PopoverMenuRow(
              label: category,
              icon: CupertinoIcons.flag,
              onTap: () => Navigator.pop(context, category),
            ),
        ],
      ),
    );
