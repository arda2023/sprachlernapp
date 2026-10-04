import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
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

Future<PracticeAction?> showPracticeMenu(
  BuildContext context, {
  required bool favorite,
  required bool canDisable,
}) => showModalBottomSheet<PracticeAction>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (context) => SafeArea(
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              tooltip: 'Schließen',
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          for (final item in [
            (PracticeAction.share, Icons.ios_share, 'Teilen'),
            (
              PracticeAction.disable,
              Icons.visibility_off_outlined,
              'Wort deaktivieren',
            ),
            (
              PracticeAction.favorite,
              favorite ? Icons.favorite : Icons.favorite_border,
              favorite ? 'Aus Favoriten entfernen' : 'Zu Favoriten hinzufügen',
            ),
            (PracticeAction.report, Icons.outlined_flag, 'Ein Problem melden'),
            (
              PracticeAction.feedback,
              Icons.chat_bubble_outline,
              'Feedback an Sprachapp',
            ),
            (
              PracticeAction.keyboard,
              Icons.keyboard_outlined,
              'Hilfe zur Tastatureinrichtung',
            ),
            (PracticeAction.settings, Icons.settings_outlined, 'Einstellungen'),
          ])
            ListTile(
              enabled: item.$1 != PracticeAction.disable || canDisable,
              leading: Icon(item.$2),
              title: Text(
                item.$3,
                style: AppType.chrome(
                  color: context.appColors.textPrimary,
                  size: 17,
                ),
              ),
              onTap: () => Navigator.pop(context, item.$1),
            ),
          const SizedBox(height: 16),
        ],
      ),
    ),
  ),
);

Future<String?> showProblemCategories(BuildContext context) =>
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  'Ein Problem melden',
                  style: AppType.chrome(
                    color: context.appColors.textPrimary,
                    size: 22,
                  ),
                ),
                trailing: IconButton(
                  tooltip: 'Schließen',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ),
              for (final category in problemCategories) ...[
                const Divider(height: 1),
                ListTile(
                  title: Text(category),
                  onTap: () => Navigator.pop(context, category),
                ),
              ],
            ],
          ),
        ),
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
                'Tastatur einrichten',
                style: AppType.chrome(
                  color: context.appColors.textPrimary,
                  size: 22,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tippe in die Lücke, um die Tastatur zu öffnen. Mit „Fertig“ oder „Eingeben“ prüfst du deine Antwort.\n\n'
                'Englisch hinzufügen: Unter iOS in Einstellungen → Allgemein → Tastatur → Tastaturen. Unter Android in den Einstellungen deiner Tastatur → Sprachen. Die Bezeichnungen können je nach Gerät abweichen.\n\n'
                'Halte einen Buchstaben gedrückt, um Akzente auszuwählen. Die Einstellung „Diakritische Zeichen einbeziehen“ legt fest, ob Akzente geprüft werden.\n\n'
                'Text auswählen oder einfügen: Halte die Eingabe gedrückt. Wische außerhalb des Eingabefelds nach rechts, um bearbeitete Karten anzusehen.',
              ),
            ],
          ),
        ),
      ),
    );
