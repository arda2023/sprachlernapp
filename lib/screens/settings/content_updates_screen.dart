import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/providers/content_update_provider.dart';
import '../../presentation/providers/database_providers.dart';

class ContentUpdatesScreen extends ConsumerStatefulWidget {
  const ContentUpdatesScreen({super.key});
  @override
  ConsumerState<ContentUpdatesScreen> createState() =>
      _ContentUpdatesScreenState();
}

class _ContentUpdatesScreenState extends ConsumerState<ContentUpdatesScreen> {
  final _email = TextEditingController(), _code = TextEditingController();
  final _password = TextEditingController();
  bool _useCode = false;
  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(contentUpdateProvider),
        controller = ref.read(contentUpdateProvider.notifier);
    final info = ref.watch(contentInfoProvider).value;
    final busy = {
      'signing_in',
      'checking',
      'downloading',
      'verifying',
      'quiescing',
      'activating',
    }.contains(status.phase);
    return Scaffold(
      appBar: AppBar(title: const Text('Inhaltsupdates')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            info == null
                ? 'Inhaltsbestand nicht verfügbar'
                : 'Englisch · ${info.version}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          const Text(
            'Bestätigte Änderungen werden privat bereitgestellt. Dein Lernstand bleibt auf diesem Gerät. Eine laufende Übung behält ihren bisherigen Inhalt.',
          ),
          const SizedBox(height: 20),
          Semantics(liveRegion: true, child: Text(status.message)),
          if (status.phase == 'error' && status.diagnosis != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SelectableText(
                'Diagnose · ${status.diagnosis}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          if (busy)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: LinearProgressIndicator(),
            ),
          const SizedBox(height: 16),
          if (!status.signedIn) ...[
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              enabled: !busy,
              decoration: const InputDecoration(
                labelText: 'Eingeladene E-Mail-Adresse',
              ),
            ),
            if (!_useCode) ...[
              TextField(
                controller: _password,
                enabled: !busy,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                autofillHints: const [AutofillHints.password],
                decoration: const InputDecoration(labelText: 'Passwort'),
              ),
              FilledButton(
                onPressed: busy
                    ? null
                    : () async {
                        final success = await controller.signInWithPassword(
                          _email.text,
                          _password.text,
                        );
                        if (mounted && success) _password.clear();
                      },
                child: const Text('Mit Passwort anmelden'),
              ),
              TextButton(
                onPressed: busy
                    ? null
                    : () => setState(() {
                        _password.clear();
                        _useCode = true;
                      }),
                child: const Text('Alternativ mit E-Mail-Code'),
              ),
            ] else ...[
              const Text(
                'Nur verwenden, wenn E-Mail-Zustellung und Codevorlage eingerichtet und geprüft sind.',
              ),
              TextButton(
                onPressed: busy
                    ? null
                    : () => controller.requestCode(_email.text),
                child: const Text('Anmeldecode senden'),
              ),
              TextField(
                controller: _code,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                decoration: const InputDecoration(labelText: 'E-Mail-Code'),
              ),
              FilledButton(
                onPressed: busy
                    ? null
                    : () async {
                        await controller.verifyCode(_email.text, _code.text);
                        _code.clear();
                      },
                child: const Text('Mit Code anmelden'),
              ),
              TextButton(
                onPressed: busy
                    ? null
                    : () => setState(() {
                        _code.clear();
                        _useCode = false;
                      }),
                child: const Text('Zur Passwortanmeldung'),
              ),
            ],
          ] else
            TextButton(
              onPressed: busy ? null : controller.signOut,
              child: const Text('Abmelden'),
            ),
          OutlinedButton(
            onPressed: busy ? null : controller.check,
            child: const Text('Nach Updates suchen'),
          ),
          if (status.phase == 'available')
            FilledButton(
              onPressed: controller.download,
              child: const Text('Version herunterladen und prüfen'),
            ),
          if (status.phase == 'ready_waiting')
            FilledButton(
              onPressed: controller.activate,
              child: const Text('Geprüfte Version aktivieren'),
            ),
          if (status.phase == 'error')
            TextButton(
              onPressed: controller.check,
              child: const Text('Erneut prüfen'),
            ),
          const SizedBox(height: 16),
          const Text(
            'Weitere Sprachen benötigen ein unterstütztes Sprachprofil. Es wird kein englischer Ersatzinhalt verwendet.',
          ),
        ],
      ),
    );
  }
}
