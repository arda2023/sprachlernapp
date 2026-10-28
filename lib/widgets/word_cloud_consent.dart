import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/runtime_translation_client.dart';
import '../presentation/providers/runtime_translation_provider.dart';

const wordCloudDisclosure =
    'Wenn eine lokale Übersetzung fehlt oder unklar ist, werden beim Antippen '
    'eines Wortes das Wort und der vollständige Satzkontext über unseren '
    'Übersetzungsserver an Anthropic gesendet. Keine ausschließlich europäische '
    'Verarbeitung. Die Übersetzung wird bis zu 30 Tage privat wiederverwendet. '
    'Die Freigabe gilt für dieses Konto auf diesem Gerät und lässt sich in den '
    'Einstellungen jederzeit ausschalten. Bereits gesendete Anfragen lassen '
    'sich dadurch nicht zurückholen.';

class WordCloudConsentTile extends ConsumerStatefulWidget {
  const WordCloudConsentTile({super.key});
  @override
  ConsumerState<WordCloudConsentTile> createState() =>
      _WordCloudConsentTileState();
}

class _WordCloudConsentTileState extends ConsumerState<WordCloudConsentTile> {
  WordCloudConsent consent = WordCloudConsent.unknown;
  bool busy = true;
  String? error;
  int _epoch = 0;
  StreamSubscription<void>? _changes;
  @override
  void initState() {
    super.initState();
    _changes = ref.read(runtimeTranslationProvider).changes.listen((_) {
      _epoch++;
      if (!mounted) return;
      setState(() {
        consent = WordCloudConsent.unknown;
        busy = true;
        error = null;
      });
      _load();
    });
    _load();
  }

  Future<void> _load() async {
    final epoch = _epoch;
    try {
      final value = await ref
          .read(runtimeTranslationProvider)
          .wordCloudConsent();
      if (mounted && epoch == _epoch) setState(() => consent = value);
    } catch (_) {
      if (mounted && epoch == _epoch) {
        setState(() => error = 'Cloud-Einstellung nicht lesbar.');
      }
    } finally {
      if (mounted && epoch == _epoch) setState(() => busy = false);
    }
  }

  Future<void> _change(bool enabled) async {
    final epoch = _epoch;
    if (enabled) {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Automatische Wortübersetzung aktivieren?'),
          content: const SingleChildScrollView(
            child: Text(wordCloudDisclosure),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Aktivieren'),
            ),
          ],
        ),
      );
      if (accepted != true || !mounted || epoch != _epoch) return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ref.read(runtimeTranslationProvider).setWordCloudConsent(enabled);
      if (mounted && epoch == _epoch) {
        setState(
          () => consent = enabled
              ? WordCloudConsent.enabled
              : WordCloudConsent.disabled,
        );
      }
    } on TranslationFailure catch (e) {
      if (mounted && epoch == _epoch) setState(() => error = e.message);
    } catch (_) {
      if (mounted && epoch == _epoch) {
        setState(() => error = 'Cloud-Einstellung nicht gespeichert.');
      }
    } finally {
      if (mounted && epoch == _epoch) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    _epoch++;
    _changes?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SwitchListTile.adaptive(
    contentPadding: EdgeInsets.zero,
    title: const Text('Automatische Wortübersetzung'),
    subtitle: Text(
      error ??
          'Bei Bedarf Wort und Satz an Anthropic senden. '
              'Ohne Freigabe bleiben lokale Übersetzungen nutzbar. Ganze Sätze nur nach „Übersetzen“.',
    ),
    value: consent == WordCloudConsent.enabled,
    onChanged: busy ? null : _change,
  );
}
