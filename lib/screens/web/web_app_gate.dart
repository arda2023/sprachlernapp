import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/providers/account_provider.dart';
import '../../theme/app_theme.dart';
import 'web_learning_shell.dart';

/// A browser session always belongs to an account. The native app's existing
/// email-code authentication is shared, including account identity and renewal.
class WebAppGate extends ConsumerWidget {
  const WebAppGate({super.key, this.child});
  final Widget? child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(accountSessionProvider)
        .when(
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (_, _) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => ref.invalidate(accountSessionProvider),
                child: const Text('Verbindung erneut versuchen'),
              ),
            ),
          ),
          data: (session) => session == null
              ? const WebLoginScreen()
              : KeyedSubtree(
                  key: ValueKey(session.id),
                  child: child ?? const WebLearningShell(),
                ),
        );
  }
}

class WebLoginScreen extends ConsumerStatefulWidget {
  const WebLoginScreen({super.key});
  @override
  ConsumerState<WebLoginScreen> createState() => _WebLoginScreenState();
}

class _WebLoginScreenState extends ConsumerState<WebLoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _codeFocus = FocusNode();
  bool _codeSent = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final actions = ref.read(accountActionsProvider);
      if (_codeSent) {
        await actions.verifyCode(_email.text.trim(), _code.text.trim());
      } else {
        await actions.sendCode(_email.text.trim());
        if (mounted) {
          setState(() => _codeSent = true);
          _codeFocus.requestFocus();
        }
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = _codeSent
              ? 'Der Code konnte nicht bestätigt werden. Prüfe ihn oder fordere einen neuen Code an.'
              : 'Der Code konnte nicht gesendet werden. Prüfe deine E-Mail-Adresse und versuche es erneut.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.nightPage,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: AutofillGroup(
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.auto_stories_outlined,
                        color: colors.active,
                        size: 40,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Linglossa',
                        textAlign: TextAlign.center,
                        style: AppType.editorial(
                          size: 32,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 40),
                      Semantics(
                        header: true,
                        child: Text(
                          _codeSent
                              ? 'Schau in dein Postfach'
                              : 'Dein Lernen geht hier weiter',
                          style: AppType.editorial(
                            size: 28,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _codeSent
                            ? 'Gib den Anmeldecode aus deiner E-Mail ein.'
                            : 'Melde dich mit der E-Mail-Adresse deines Linglossa-Kontos an. Lies deine Texte und übe deine Stapel auch im Browser.',
                      ),
                      const SizedBox(height: 28),
                      TextFormField(
                        controller: _email,
                        enabled: !_busy && !_codeSent,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        autocorrect: false,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'E-Mail-Adresse',
                          hintText: 'name@beispiel.de',
                        ),
                        validator: (value) =>
                            value != null &&
                                RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                    .hasMatch(value.trim())
                            ? null
                            : 'Bitte gib eine gültige E-Mail-Adresse ein.',
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      if (_codeSent) ...[
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _code,
                          focusNode: _codeFocus,
                          enabled: !_busy,
                          keyboardType: TextInputType.number,
                          autofillHints: const [AutofillHints.oneTimeCode],
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            labelText: 'Anmeldecode',
                          ),
                          validator: (value) =>
                              value == null || value.trim().length < 6
                              ? 'Bitte gib den vollständigen Code ein.'
                              : null,
                          onFieldSubmitted: (_) => _submit(),
                        ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _busy ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.popover,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(44, 52),
                        ),
                        child: _busy
                            ? const SizedBox.square(
                                dimension: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _codeSent ? 'Anmelden' : 'Anmeldecode senden',
                              ),
                      ),
                      if (_codeSent)
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => setState(() {
                                  _codeSent = false;
                                  _code.clear();
                                  _error = null;
                                }),
                          child: const Text(
                            'Adresse ändern oder neuen Code anfordern',
                          ),
                        ),
                      const SizedBox(height: 20),
                      Text(
                        'Du brauchst kein Passwort. Dein Code kommt per E-Mail.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
