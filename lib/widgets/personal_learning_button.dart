import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/personal_learning_client.dart';
import '../domain/personal_learning.dart';
import '../domain/story_learning.dart';
import '../presentation/providers/personal_learning_provider.dart';
import '../presentation/providers/database_providers.dart';
import '../screens/words/word_list_screen.dart';

const personalLearningDisclosure =
    'Beim Hinzufügen dürfen das gewählte Wort, sein Satz und nötige '
    'Karten-Vergleichskontexte über unseren Server an Anthropic übertragen werden, um eine passende Karte zuzuordnen '
    'oder eine private Übung zu erstellen. Der Originalsatz bleibt möglichst erhalten; ungeeignete kurze '
    'Kontexte können ersetzt werden. Keine ausschließliche EU-Verarbeitung. Antworten werden bis zu 30 Tage '
    'privat zur Wiederverwendung gespeichert; hinzugefügte Lernkarten bleiben dauerhaft auf diesem Gerät. '
    'KI-Inhalte sind nicht redaktionell geprüft. Diese gesonderte Freigabe gilt für dein Konto auf diesem '
    'Gerät und ist in Einstellungen abschaltbar. Bereits gesendete Anfragen können nicht zurückgeholt werden.';
Future<bool> confirmPersonalLearning(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Private Lernkarten ermöglichen?'),
        content: const SingleChildScrollView(
          child: Text(personalLearningDisclosure),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Erlauben'),
          ),
        ],
      ),
    ) ??
    false;

class PersonalLearningButton extends ConsumerStatefulWidget {
  const PersonalLearningButton({
    super.key,
    required this.target,
    this.foregroundColor,
  });
  final PersonalTarget target;
  final Color? foregroundColor;
  @override
  ConsumerState<PersonalLearningButton> createState() =>
      _PersonalLearningButtonState();
}

class _PersonalLearningButtonState
    extends ConsumerState<PersonalLearningButton> {
  bool busy = false;
  String? error;
  StoryAddResult? saved;
  int epoch = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant PersonalLearningButton old) {
    super.didUpdateWidget(old);
    if (old.target.key != widget.target.key) {
      epoch++;
      saved = null;
      error = null;
      busy = false;
      _load();
    }
  }

  Future<void> _load() async {
    final current = epoch;
    try {
      widget.target.validate();
      final service = await ref.read(personalLearningServiceProvider.future);
      final value = await service.saved(widget.target);
      if (mounted && epoch == current) setState(() => saved = value);
    } catch (_) {
      if (mounted && epoch == current) {
        setState(() => error = 'Lernstatus nicht lesbar. Bitte erneut öffnen.');
      }
    }
  }

  Future<void> add() async {
    if (busy) return;
    final current = epoch, target = widget.target;
    final release = contentTransitionGate.acquire();
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final service = await ref.read(personalLearningServiceProvider.future);
      final prior = await service.saved(target);
      if (prior != null) {
        if (mounted && epoch == current) setState(() => saved = prior);
        return;
      }
      final client = ref.read(personalLearningClientProvider);
      await client.owner();
      final identity = client.revision();
      if (!await client.consent()) {
        if (!mounted || epoch != current) return;
        if (!await confirmPersonalLearning(context)) return;
        if (!mounted || epoch != current || identity != client.revision()) {
          return;
        }
        await client.setConsent(true);
      }
      if (!mounted || epoch != current) return;
      final value = await service.add(target);
      if (mounted && epoch == current) setState(() => saved = value);
    } catch (e) {
      if (mounted && epoch == current) {
        setState(
          () => error = e is PersonalLearningFailure ? e.message : 'Lernkarte nicht gespeichert. Bitte Eingabe oder Verbindung prüfen.',
        );
      }
    } finally {
      release();
      if (mounted && epoch == current) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (busy)
        const Padding(
          padding: EdgeInsets.all(8),
          child: CircularProgressIndicator(),
        ),
      if (error != null)
        Semantics(
          liveRegion: true,
          child: Text(error!, style: TextStyle(color: widget.foregroundColor)),
        ),
      if (saved?.message != null)
        Text(saved!.message!, style: TextStyle(color: widget.foregroundColor)),
      TextButton(
        style: TextButton.styleFrom(
          foregroundColor: widget.foregroundColor,
          disabledForegroundColor: widget.foregroundColor?.withValues(
            alpha: 0.7,
          ),
          minimumSize: const Size(44, 48),
        ),
        onPressed: busy || saved != null || error != null ? null : add,
        child: Text(
          busy
              ? 'Wird hinzugefügt …'
              : saved?.state == StoryAddState.added
              ? 'Hinzugefügt'
              : saved?.label ?? 'Zum Lernen hinzufügen',
        ),
      ),
      if (saved?.state == StoryAddState.added && saved?.cardId != null)
        TextButton(
          style: TextButton.styleFrom(foregroundColor: widget.foregroundColor),
          onPressed: () => WordListScreen.openTarget(context, saved!.cardId!),
          child: const Text('In Wortliste ansehen'),
        ),
    ],
  );
}

class PersonalLearningConsentTile extends ConsumerStatefulWidget {
  const PersonalLearningConsentTile({super.key});
  @override
  ConsumerState<PersonalLearningConsentTile> createState() =>
      _PersonalLearningConsentTileState();
}

class _PersonalLearningConsentTileState
    extends ConsumerState<PersonalLearningConsentTile> {
  bool enabled = false, busy = true;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final v = await ref.read(personalLearningClientProvider).consent();
      if (mounted) setState(() => enabled = v);
    } catch (_) {
      if (mounted) setState(() => error = 'Freigabe nicht lesbar.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> change(bool value) async {
    setState(() => busy = true);
    try {
      final client = ref.read(personalLearningClientProvider);
      await client.owner();
      final epoch = client.revision();
      if (!mounted) return;
      if (value && !await confirmPersonalLearning(context)) return;
      if (!mounted || epoch != client.revision()) return;
      await client.setConsent(value);
      if (mounted) {
        setState(() {
          enabled = value;
          error = null;
        });
      }
    } catch (_) {
      if (mounted) setState(() => error = 'Freigabe nicht gespeichert.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SwitchListTile(
    title: const Text('Private Lernkarten mit KI'),
    subtitle: Text(
      error ?? 'Nur nach „Zum Lernen hinzufügen“. Gesonderte Freigabe.',
    ),
    value: enabled,
    onChanged: busy ? null : change,
  );
}
