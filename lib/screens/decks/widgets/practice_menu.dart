import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
  keyboard,
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
        (
          PracticeAction.keyboard,
          CupertinoIcons.keyboard,
          'Hilfe zur Tastatureinrichtung',
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

Future<void> showKeyboardHelp(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: 'Schließen',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ),
              Text(
                'Tastatur und Akzente',
                style: AppType.chrome(
                  color: context.appColors.textPrimary,
                  size: 22,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Für Sprachen mit eigenen Buchstaben wie Portugiesisch sind Akzente erforderlich: Halte einen Buchstaben gedrückt, um etwa ã, õ oder ç zu wählen. Tippe in die Lücke, um die Tastatur zu öffnen. Mit „Fertig“ oder „Eingeben“ prüfst du deine Antwort.\n\n'
                'Eine Tastatur für deine Lernsprache hinzufügen: Unter iOS in Einstellungen → Allgemein → Tastatur → Tastaturen. Unter Android in den Einstellungen deiner Tastatur → Sprachen. Die Bezeichnungen können je nach Gerät abweichen.\n\n'
                'Halte einen Buchstaben gedrückt, um Akzente auszuwählen. Für Englisch legt die Einstellung „Diakritische Zeichen einbeziehen“ fest, ob Akzente geprüft werden. Für Portugiesisch bleiben sie immer erforderlich.\n\n'
                'Text auswählen oder einfügen: Halte die Eingabe gedrückt. Wische außerhalb des Eingabefelds nach rechts, um bearbeitete Karten anzusehen.',
              ),
            ],
          ),
        ),
      ),
    );
