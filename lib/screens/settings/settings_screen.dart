import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/preferences.dart';
import '../../presentation/providers/preferences_provider.dart';
import '../../theme/app_theme.dart';
import '../decks/widgets/local_submission_sheet.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  static Future<void> open(BuildContext context) => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen()));
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _saving = false;
  String? _error;
  Future<void> _save(PracticePreferences value) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(preferencesProvider.notifier).save(value);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Nicht gespeichert. Bitte erneut versuchen.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(preferencesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(preferencesProvider),
            child: const Text('Einstellungen erneut laden'),
          ),
        ),
        data: (p) => ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final compact =
                    constraints.maxWidth <
                    360 * MediaQuery.textScalerOf(context).scale(16) / 16;
                final selector = DropdownButton<AppMotif>(
                  isExpanded: compact,
                  value: p.motif,
                  onChanged: _saving
                      ? null
                      : (v) => _save(p.copyWith(motif: v)),
                  items: [
                    for (final m in AppMotif.values)
                      DropdownMenuItem(
                        value: m,
                        child: Text(switch (m) {
                          AppMotif.automatic => 'Automatisch',
                          AppMotif.light => 'Hell',
                          AppMotif.dark => 'Dunkel',
                        }),
                      ),
                  ],
                );
                final description = ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Motiv',
                    style: AppType.chrome(
                      color: context.appColors.textPrimary,
                      size: 18,
                    ),
                  ),
                  subtitle: const Text(
                    'Wähle ein helles oder dunkles Farbschema.',
                  ),
                  trailing: compact ? null : selector,
                );
                return compact
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [description, selector],
                      )
                    : description;
              },
            ),
            const Divider(),
            for (final entry in const [
              ('Lern-Benachrichtigungen', 'Lernerinnerungen'),
              (
                'Ton aus',
                'Automatische Audioinhalte stummschalten; manuelles Abspielen bleibt möglich.',
              ),
              ('Audiogeschwindigkeit', 'Geschwindigkeit der Audiowiedergabe'),
              (
                'Spracheingabe aktivieren',
                'Mit geräteinterner Spracherkennung antworten.',
              ),
            ]) ...[
              ListTile(
                enabled: false,
                contentPadding: EdgeInsets.zero,
                title: Text(entry.$1),
                subtitle: Text('${entry.$2}\nNoch nicht verfügbar'),
              ),
              const Divider(),
            ],
            _toggle(
              'Diakritische Zeichen einbeziehen',
              'Akzente sind bei der Antwort erforderlich. Standardmäßig eingeschaltet.',
              p.includeDiacritics,
              (v) => p.copyWith(includeDiacritics: v),
            ),
            _toggle(
              'Automatisch nächste Karte anzeigen',
              'Nach dem Speichern und einer kurzen Rückmeldung weitergehen.',
              p.autoNext,
              (v) => p.copyWith(autoNext: v),
            ),
            _toggle(
              'Grammatiktabellen anzeigen',
              'Vorhandene Forminformationen nach der richtigen Antwort öffnen.',
              p.showGrammar,
              (v) => p.copyWith(showGrammar: v),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Lokale Berichte und Feedback'),
              subtitle: const Text('Gespeicherte Einträge ansehen und teilen.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => LocalSubmissionSheet.openSaved(context),
            ),
            if (_saving) const LinearProgressIndicator(),
            if (_error != null)
              Text(_error!, style: TextStyle(color: context.appColors.error)),
          ],
        ),
      ),
    );
  }

  Widget _toggle(
    String title,
    String subtitle,
    bool value,
    PracticePreferences Function(bool) update,
  ) => Column(
    children: [
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: _saving ? null : (v) => _save(update(v)),
      ),
      const Divider(),
    ],
  );
}
