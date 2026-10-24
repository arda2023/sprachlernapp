import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show showModalBottomSheet;
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
    this.start,
    this.senseRef,
    this.formRef,
  });
  final String lang, text;
  final String? form, displayText, senseRef, formRef;
  final int? start;
  static Future<void> show(
    BuildContext context, {
    required String lang,
    required String text,
    String? form,
    String? displayText,
    int? start,
    String? senseRef,
    String? formRef,
  }) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: false,
    useSafeArea: true,
    builder: (_) => RuntimeTranslationSheet(
      lang: lang,
      text: text,
      form: form,
      displayText: displayText,
      start: start,
      senseRef: senseRef,
      formRef: formRef,
    ),
  );
  @override
  ConsumerState<RuntimeTranslationSheet> createState() =>
      _RuntimeTranslationSheetState();
}

class _RuntimeTranslationSheetState
    extends ConsumerState<RuntimeTranslationSheet> {
  bool started = false, loading = false, checking = true;
  StreamSubscription<void>? _changes;
  int _epoch = 0;
  @override
  void initState() {
    super.initState();
    final client = ref.read(runtimeTranslationProvider);
    _changes = client.changes.listen((_) {
      _epoch++;
      if (mounted) {
        setState(() {
          result = null;
          started = true;
          loading = false;
          checking = false;
          error =
              'Konto oder Übersetzungsspeicher geändert. Bitte erneut öffnen.';
        });
      }
    });
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final epoch = _epoch;
    try {
      final saved = await ref
          .read(runtimeTranslationProvider)
          .cached(
            lang: widget.lang,
            text: widget.text,
            form: widget.form,
            start: widget.start,
            senseRef: widget.senseRef,
            formRef: widget.formRef,
          );
      if (mounted && epoch == _epoch) {
        setState(() {
          result = saved;
          started = saved != null;
        });
      }
    } on TranslationFailure catch (e) {
      if (mounted && epoch == _epoch) {
        setState(() {
          error = e.message;
          started = true;
        });
      }
    } catch (_) {
      if (mounted && epoch == _epoch) {
        setState(() {
          error = 'Übersetzungsspeicher konnte nicht gelesen werden.';
          started = true;
        });
      }
    } finally {
      if (mounted && epoch == _epoch) setState(() => checking = false);
    }
  }

  @override
  void dispose() {
    _changes?.cancel();
    super.dispose();
  }

  RuntimeTranslation? result;
  String? error;
  Future<void> request() async {
    if (started || checking) return;
    final epoch = _epoch;
    setState(() {
      started = true;
      loading = true;
    });
    try {
      final value = await ref
          .read(runtimeTranslationProvider)
          .translate(
            lang: widget.lang,
            text: widget.text,
            form: widget.form,
            start: widget.start,
            senseRef: widget.senseRef,
            formRef: widget.formRef,
          );
      if (mounted && epoch == _epoch) setState(() => result = value);
    } on TranslationFailure catch (e) {
      if (mounted && epoch == _epoch) setState(() => error = e.message);
    } catch (_) {
      if (mounted && epoch == _epoch) {
        setState(() => error = 'Übersetzung derzeit nicht verfügbar.');
      }
    } finally {
      if (mounted && epoch == _epoch) setState(() => loading = false);
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
          if (!started && !checking) ...[
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
            if (value.storageWarning != null) Text(value.storageWarning!),
          ],
        ],
      ),
    ),
  );
}
