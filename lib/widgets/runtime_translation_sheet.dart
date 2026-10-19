import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show showModalBottomSheet, SelectableText;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/runtime_translation_client.dart';
import '../presentation/providers/runtime_translation_provider.dart';

/// Missing translations only. No network until the explicit button is tapped.
class RuntimeTranslationSheet extends ConsumerStatefulWidget {
  const RuntimeTranslationSheet({
    super.key,
    required this.lang,
    required this.text,
    this.form,
    this.displayText,
  });
  final String lang, text;
  final String? form, displayText;
  static Future<void> show(
    BuildContext context, {
    required String lang,
    required String text,
    String? form,
    String? displayText,
  }) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => RuntimeTranslationSheet(
      lang: lang,
      text: text,
      form: form,
      displayText: displayText,
    ),
  );
  @override
  ConsumerState<RuntimeTranslationSheet> createState() =>
      _RuntimeTranslationSheetState();
}

class _RuntimeTranslationSheetState
    extends ConsumerState<RuntimeTranslationSheet> {
  bool started = false, loading = false;
  RuntimeTranslation? result;
  String? error;
  Future<void> request() async {
    if (started) return;
    setState(() {
      started = true;
      loading = true;
    });
    try {
      final value = await ref
          .read(runtimeTranslationProvider)
          .translate(lang: widget.lang, text: widget.text, form: widget.form);
      if (mounted) setState(() => result = value);
    } on TranslationFailure catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Übersetzung derzeit nicht verfügbar.');
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.displayText ?? widget.form ?? widget.text),
          if (widget.form != null) Text(widget.text),
          const SizedBox(height: 16),
          if (!started) ...[
            const Text(
              'Keine gespeicherte Übersetzung. Für eine KI-Übersetzung wird dieser Satz an Anthropic übermittelt. Keine ausschließliche EU-Verarbeitung.',
            ),
            CupertinoButton(
              onPressed: request,
              child: const Text('Mit KI übersetzen'),
            ),
          ],
          if (loading) const CupertinoActivityIndicator(),
          if (error != null) Text(error!, semanticsLabel: error),
          if (result case final value?) ...[
            Text(value.text),
            const SizedBox(height: 12),
            Text('KI · ${value.model}'),
            SelectableText('Anfrage: ${value.requestId}'),
          ],
        ],
      ),
    ),
  );
}
