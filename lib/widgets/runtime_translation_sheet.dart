import '../domain/personal_learning.dart';
import 'personal_learning_button.dart';

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show showModalBottomSheet, SelectableText;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/offline_translation/offline_dictionary.dart';
import '../data/offline_translation/dictionary_selection.dart';
import '../data/runtime_translation_client.dart';
import '../presentation/providers/offline_translation_provider.dart';
import '../presentation/providers/runtime_translation_provider.dart';
import '../theme/app_theme.dart';
import 'anchored_popover.dart';
import 'popover_content.dart';
import 'word_cloud_consent.dart';

/// The reader has already checked its exact pack/context translation.
/// Only a word tap can opt into automatic cloud lookup; mounting alone cannot.
/// Shown as the orange popover pointing at the tapped word or sentence, like
/// a stored translation (design-system.md › Overlay-Regel).
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
    this.wordTap = false,
    this.learningTarget,
  });
  final PersonalTarget? learningTarget;
  final String lang, text;
  final String? form, displayText, senseRef, formRef;
  final int? start;
  final bool wordTap;
  static Future<void> show(
    BuildContext context, {
    required Rect anchor,
    required String lang,
    required String text,
    String? form,
    String? displayText,
    int? start,
    String? senseRef,
    String? formRef,
    bool wordTap = false,
    PersonalTarget? learningTarget,
  }) => showAnchoredPopoverAt<void>(
    context: context,
    anchor: anchor,
    color: context.appColors.popover,
    builder: (_) => RuntimeTranslationSheet(
      lang: lang,
      text: text,
      form: form,
      displayText: displayText,
      start: start,
      senseRef: senseRef,
      formRef: formRef,
      wordTap: wordTap,
      learningTarget: learningTarget,
    ),
  );
  @override
  ConsumerState<RuntimeTranslationSheet> createState() =>
      _RuntimeTranslationSheetState();
}

class _RuntimeTranslationSheetState
    extends ConsumerState<RuntimeTranslationSheet> {
  StreamSubscription<void>? _changes;
  int _epoch = 0;
  bool checking = true, loading = false, started = false;
  WordCloudConsent? consent;
  RuntimeTranslation? result;
  String? dictionaryText, error;
  List<DictionaryCandidate> candidates = [];
  bool _current(int epoch) => mounted && epoch == _epoch;

  @override
  void initState() {
    super.initState();
    _changes = ref.read(runtimeTranslationProvider).changes.listen((_) {
      _epoch++;
      if (!mounted) return;
      setState(() {
        result = null;
        dictionaryText = null;
        candidates = [];
        consent = null;
        started = true;
        loading = false;
        checking = false;
        error =
            'Konto oder Übersetzungsspeicher geändert. Bitte erneut öffnen.';
      });
    });
    _load();
  }

  @override
  void didUpdateWidget(covariant RuntimeTranslationSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lang == widget.lang &&
        oldWidget.text == widget.text &&
        oldWidget.form == widget.form &&
        oldWidget.start == widget.start &&
        oldWidget.senseRef == widget.senseRef &&
        oldWidget.formRef == widget.formRef &&
        oldWidget.wordTap == widget.wordTap) {
      return;
    }
    _epoch++;
    result = null;
    dictionaryText = null;
    candidates = [];
    consent = null;
    started = false;
    loading = false;
    checking = true;
    error = null;
    _load();
  }

  Future<void> _load() async {
    final epoch = _epoch;
    final client = ref.read(runtimeTranslationProvider);
    try {
      final saved = await client.cached(
        lang: widget.lang,
        text: widget.text,
        form: widget.form,
        start: widget.start,
        senseRef: widget.senseRef,
        formRef: widget.formRef,
      );
      if (!_current(epoch)) return;
      if (saved != null) {
        setState(() {
          result = saved;
          checking = false;
        });
        return;
      }
      final form = widget.form;
      if (form != null) {
        final values = await ref
            .read(offlineDictionaryProvider)
            .lookup(widget.lang, form);
        if (!_current(epoch)) return;
        candidates = values;
        dictionaryText = singleDictionaryTranslation(form, values);
        if (dictionaryText == null && widget.wordTap) {
          consent = await client.wordCloudConsent();
          if (!_current(epoch)) return;
        }
      }
      setState(() => checking = false);
      if (widget.form != null &&
          widget.wordTap &&
          dictionaryText == null &&
          consent == WordCloudConsent.enabled) {
        await request();
      }
    } on TranslationFailure catch (e) {
      if (_current(epoch)) {
        setState(() {
          error = e.message;
          started = true;
          checking = false;
        });
      }
    } catch (_) {
      if (_current(epoch)) {
        setState(() {
          error = 'Lokaler Übersetzungsspeicher nicht lesbar. Keine Onlineanfrage gestartet.';
          started = true;
          checking = false;
        });
      }
    }
  }

  Future<void> decideConsent(bool enabled) async {
    if (loading || checking || started) return;
    final epoch = _epoch;
    setState(() => loading = true);
    try {
      await ref.read(runtimeTranslationProvider).setWordCloudConsent(enabled);
      if (!_current(epoch)) return;
      setState(() {
        consent = enabled
            ? WordCloudConsent.enabled
            : WordCloudConsent.disabled;
        loading = false;
      });
      if (enabled && widget.wordTap) await request();
    } on TranslationFailure catch (e) {
      if (_current(epoch)) {
        setState(() {
          error = e.message;
          started = true;
        });
      }
    } catch (_) {
      if (_current(epoch)) {
        setState(() {
          error =
              'Cloud-Einstellung nicht gespeichert. Keine Anfrage gestartet.';
          started = true;
        });
      }
    } finally {
      if (_current(epoch)) setState(() => loading = false);
    }
  }

  Future<void> request() async {
    if (started || checking || loading) return;
    if (widget.form != null &&
        (!widget.wordTap || consent != WordCloudConsent.enabled)) {
      return;
    }
    final epoch = _epoch;
    setState(() {
      started = true;
      loading = true;
    });
    try {
      final client = ref.read(runtimeTranslationProvider);
      final value = widget.form == null
          ? await client.translate(lang: widget.lang, text: widget.text)
          : await client.translateWordOnTap(
              lang: widget.lang,
              text: widget.text,
              form: widget.form!,
              start: widget.start,
              senseRef: widget.senseRef,
              formRef: widget.formRef,
            );
      if (_current(epoch)) setState(() => result = value);
    } on TranslationFailure catch (e) {
      if (_current(epoch)) setState(() => error = e.message);
    } catch (_) {
      if (_current(epoch)) {
        setState(() => error = 'Übersetzung derzeit nicht verfügbar.');
      }
    } finally {
      if (_current(epoch)) setState(() => loading = false);
    }
  }

  Future<void> showSources() async {
    try {
      final notice = await rootBundle.loadString(
        'assets/offline_dictionary/ATTRIBUTION.txt',
      );
      final license = await rootBundle.loadString(
        'assets/offline_dictionary/CC-BY-SA-4.0.txt',
      );
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.7,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: SelectableText(
              '$notice\n${candidates.map((c) => '${c.lemma}: ${c.source}${c.formSource.isEmpty ? '' : '\nForm: ${c.formSource}'}').toSet().join('\n')}\n\n$license',
            ),
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Quelleninformationen derzeit nicht lesbar.');
      }
    }
  }

  @override
  void dispose() {
    _epoch++;
    _changes?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final serif = AppType.editorial(
      color: popoverInk,
      size: 20,
      weight: FontWeight.w400,
      height: 1.4,
      letterSpacing: 0,
    );
    Widget action(String label, VoidCallback onPressed) => Padding(
      padding: const EdgeInsets.only(top: 10),
      child: PopoverPillButton(label: label, onPressed: onPressed),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.displayText ?? widget.form ?? widget.text,
          style: AppType.editorial(
            color: popoverInk,
            size: widget.form != null ? 26 : 19,
            weight: FontWeight.w600,
            height: 1.35,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 12),
        const PopoverDivider(),
        const SizedBox(height: 12),
        if (checking || loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: CupertinoActivityIndicator(color: popoverInk),
          ),
        if (result case final value?) ...[
          Text(value.text, style: serif),
          if (value.storageWarning != null) ...[
            const SizedBox(height: 6),
            Text(value.storageWarning!, style: PopoverText.small()),
          ],
        ] else if (dictionaryText != null) ...[
          Text(dictionaryText!, style: serif),
          const SizedBox(height: 8),
          Text(
            'Wörterbuch · allgemeine Bedeutung',
            style: PopoverText.caption(),
          ),
        ] else if (!checking && !loading && !started) ...[
          if (widget.form == null) ...[
            Text(
              'Für eine neue Übersetzung wird dieser Satz an Anthropic übermittelt. Keine ausschließliche EU-Verarbeitung.',
              style: PopoverText.small(),
            ),
            action('Übersetzen', request),
          ] else if (consent == WordCloudConsent.unknown &&
              widget.wordTap) ...[
            Text(
              'Automatische Wortübersetzung aktivieren?',
              style: PopoverText.body(weight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(wordCloudDisclosure, style: PopoverText.small()),
            action('Aktivieren', () => decideConsent(true)),
            CupertinoButton(
              onPressed: () => decideConsent(false),
              child: Text('Nicht jetzt', style: PopoverText.small()),
            ),
          ] else
            Text(
              'Keine eindeutige lokale Übersetzung. Automatische Wortübersetzung kannst du in den Einstellungen aktivieren.',
              style: PopoverText.small(),
            ),
        ],
        if (widget.learningTarget case final target?)
          PersonalLearningButton(
            key: ValueKey(target.key),
            target: target,
            foregroundColor: popoverInk,
          ),
        if (error != null)
          Semantics(
            liveRegion: true,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(error!, style: PopoverText.small()),
            ),
          ),
        if (widget.form != null && !checking && !loading)
          CupertinoButton(
            onPressed: showSources,
            child: Text(
              'Wörterbuch · Quellen & Lizenz',
              style: PopoverText.caption(),
            ),
          ),
      ],
    );
  }
}
