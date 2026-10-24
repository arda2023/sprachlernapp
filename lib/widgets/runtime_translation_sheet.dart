import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:device_translation/device_translation.dart';

import '../data/offline_translation/offline_dictionary.dart';
import '../presentation/providers/offline_translation_provider.dart';
import '../theme/app_theme.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show showModalBottomSheet, SelectableText;
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
    isScrollControlled: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.85,
    ),
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
  int _epoch = 0, _localEpoch = 0;
  List<DictionaryCandidate> candidates = [];
  int visibleCandidates = 3;
  DeviceModelState modelState = DeviceModelState.unsupported;
  bool localBusy = false;
  String? localText, localError;
  late final DeviceTranslation device;
  @override
  void initState() {
    super.initState();
    device = ref.read(deviceTranslationProvider);
    final client = ref.read(runtimeTranslationProvider);
    _changes = client.changes.listen((_) {
      _epoch++;
      _localEpoch++;
      unawaited(device.cancel());
      if (mounted) {
        setState(() {
          result = null;
          localText = null;
          candidates = [];
          localBusy = false;
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
        if (saved == null) await loadLocal();
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
    _localEpoch++;
    unawaited(device.cancel());
    super.dispose();
  }

  RuntimeTranslation? result;
  String? error;
  Future<void> request() async {
    if (started || checking || localBusy) return;
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

  Future<void> loadLocal() async {
    final epoch = _epoch, localEpoch = ++_localEpoch;
    try {
      if (widget.form case final form?) {
        final values = await ref
            .read(offlineDictionaryProvider)
            .lookup(widget.lang, form);
        if (mounted && epoch == _epoch && localEpoch == _localEpoch) {
          setState(() => candidates = values);
        }
      } else {
        final state = await device.status(widget.lang);
        if (mounted && epoch == _epoch && localEpoch == _localEpoch) {
          setState(() {
            modelState = state;
            localError = null;
          });
        }
      }
    } catch (_) {
      if (mounted && epoch == _epoch && localEpoch == _localEpoch) {
        setState(
          () => localError = 'Lokales Nachschlagen nicht möglich. Bitte Speicherplatz prüfen und erneut öffnen.',
        );
      }
    }
  }

  Future<void> requestLocal() async {
    if (localBusy || checking || started) return;
    final epoch = _epoch, operation = ++_localEpoch;
    setState(() {
      localBusy = true;
      localError = null;
    });
    try {
      if (modelState == DeviceModelState.supported) {
        await device.prepare(widget.lang);
        final state = await device.status(widget.lang);
        if (mounted && epoch == _epoch && operation == _localEpoch) {
          setState(() => modelState = state);
        }
      } else if (modelState == DeviceModelState.installed) {
        final value = await device.translate(widget.lang, widget.text);
        if (mounted && epoch == _epoch && operation == _localEpoch) {
          setState(() => localText = value);
        }
      }
    } on PlatformException catch (e) {
      if (mounted && epoch == _epoch && operation == _localEpoch) {
        setState(
          () => localError = switch (e.code) {
            'cancelled' => 'Abgebrochen.',
            'missing_model' =>
              'Sprachmodell fehlt. Bitte Status erneut prüfen.',
            'unsupported' =>
              'Dieses Sprachpaar wird auf deinem Gerät nicht unterstützt.',
            'storage' => 'Nicht genug Speicherplatz für das Sprachmodell.',
            _ => 'Geräteübersetzung nicht möglich. Bitte WLAN, freien Speicher und Modelldownload prüfen.',
          },
        );
      }
    } catch (_) {
      if (mounted && epoch == _epoch && operation == _localEpoch) {
        setState(
          () => localError = 'Geräteübersetzung derzeit nicht verfügbar.',
        );
      }
    } finally {
      if (mounted && epoch == _epoch && operation == _localEpoch) {
        setState(() => localBusy = false);
      }
    }
  }

  void cancelLocal() {
    _localEpoch++;
    unawaited(device.cancel());
    setState(() {
      localBusy = false;
      localError = 'Abgebrochen. Ein systemverwalteter Modelldownload kann im Hintergrund weiterlaufen.';
    });
  }

  Future<void> showSources() async {
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
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.displayText ?? widget.form ?? widget.text,
            style: AppType.editorial(
              color: context.appColors.textPrimary,
              size: 24,
            ),
          ),
          const SizedBox(height: 16),
          if (checking) const CupertinoActivityIndicator(),
          if (!started && !checking) ...[
            if (widget.form != null) ...[
              Text(
                candidates.isEmpty
                    ? 'Kein Offline-Wörterbuchtreffer.'
                    : 'Mögliche Bedeutungen · Wörterbuch',
              ),
              if (widget.lang == 'pt-BR')
                const Text(
                  'Portugiesisch: regionale Varianten sind nicht immer getrennt.',
                ),
              for (final c in candidates.take(visibleCandidates))
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${c.lemma} · ${c.pos}',
                        style: AppType.meta(color: context.appColors.textMuted),
                      ),
                      Text(c.gloss),
                      if (c.tags.isNotEmpty)
                        Text(
                          c.tags,
                          style: AppType.meta(
                            color: context.appColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
              if (candidates.length > visibleCandidates)
                CupertinoButton(
                  onPressed: () => setState(() => visibleCandidates += 5),
                  child: const Text('Weitere Bedeutungen'),
                ),
              if (candidates.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Nicht auf diesen Satz festgelegt. Kein geprüfter Lernkontext.',
                ),
                CupertinoButton(
                  onPressed: showSources,
                  child: const Text('Wiktionary · Quellen & Lizenz'),
                ),
              ],
            ] else ...[
              Text(switch (modelState) {
                DeviceModelState.installed =>
                  'Sprachmodell bereit · offline nutzbar',
                DeviceModelState.supported =>
                  'Sprachmodell muss vorbereitet werden.',
                DeviceModelState.unsupported =>
                  'Geräteübersetzung für dieses Sprachpaar nicht verfügbar.',
              }),
              if (modelState == DeviceModelState.supported)
                Text(
                  Platform.isAndroid
                      ? 'Download über WLAN: etwa 30 MB je Modell. Für Portugiesisch und Deutsch können zwei Modelle nötig sein.'
                      : 'Apple verwaltet Download und Speicherbedarf. Die Größe ist hier nicht vorab verfügbar.',
                ),
              if (widget.lang == 'pt-BR')
                const Text(
                  'Die Geräteengine garantiert keine ausschließlich brasilianische Variante.',
                ),
              if (modelState != DeviceModelState.unsupported)
                CupertinoButton(
                  onPressed: localBusy ? null : requestLocal,
                  child: Text(
                    modelState == DeviceModelState.installed
                        ? (Platform.isAndroid
                              ? 'Mit Google übersetzen · auf dem Gerät'
                              : 'Auf dem Gerät übersetzen')
                        : 'Sprachmodelle laden',
                  ),
                ),
              if (localBusy) ...[
                const CupertinoActivityIndicator(),
                CupertinoButton(
                  onPressed: cancelLocal,
                  child: const Text('Abbrechen'),
                ),
              ],
              if (localError != null ||
                  modelState == DeviceModelState.supported)
                CupertinoButton(
                  onPressed: localBusy ? null : loadLocal,
                  child: const Text('Status erneut prüfen'),
                ),
              if (localText != null) ...[
                Text(localText!),
                Text(
                  Platform.isAndroid
                      ? 'Automatisch mit Google Translate · ML Kit 17.0.3 / Vertrag 1'
                      : 'Automatisch mit Apple Translation · Vertrag 1',
                ),
                if (Platform.isAndroid)
                  Image.asset(
                    'assets/offline_dictionary/google-translate.png',
                    height: 24,
                    alignment: Alignment.centerLeft,
                  ),
                const Text(
                  'Anzeigehilfe, kein geprüfter Lernkontext. Nicht dauerhaft gespeichert.',
                ),
              ],
            ],
            if (localError != null) Text(localError!),
            const SizedBox(height: 16),
            const Text(
              'Für eine KI-Übersetzung im Kontext wird dieser Satz an Anthropic übermittelt. Keine ausschließliche EU-Verarbeitung.',
            ),
            CupertinoButton(
              onPressed: localBusy ? null : request,
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
