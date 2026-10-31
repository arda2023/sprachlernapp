import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../domain/story_failure_trace.dart';
import '../domain/story_learning_diagnostics.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/personal_learning_client.dart';
import '../domain/personal_learning.dart';
import '../domain/story_learning.dart';
import '../presentation/providers/personal_learning_provider.dart';
import '../presentation/providers/database_providers.dart';
import '../screens/words/word_list_screen.dart';
import 'word_bubble.dart';

/// What the AI learning cards send, for the legal texts and Settings. The
/// app no longer asks in a dialog (user decision 31.10.2026): the AI switch
/// in the onboarding and in Settings covers it.
const personalLearningDisclosure =
    'Beim Hinzufügen dürfen das gewählte Wort, sein Satz und nötige '
    'Karten-Vergleichskontexte über unseren Server an Anthropic übertragen werden, um eine passende Karte zuzuordnen '
    'oder eine private Übung zu erstellen. Keine ausschließliche EU-Verarbeitung.';

class PersonalLearningButton extends ConsumerStatefulWidget {
  const PersonalLearningButton({
    super.key,
    required this.target,
    this.foregroundColor,
    this.compact = false,
    this.onMessage,
  });
  final PersonalTarget target;
  final Color? foregroundColor;

  /// A round icon button for the word bubble ([AddWordButton]); messages
  /// go to [onMessage] instead of below the button.
  final bool compact;
  final ValueChanged<String?>? onMessage;
  @override
  ConsumerState<PersonalLearningButton> createState() =>
      _PersonalLearningButtonState();
}

class _PersonalLearningButtonState
    extends ConsumerState<PersonalLearningButton> {
  bool busy = false;
  bool retryable = false;
  String? error;
  StoryAddResult? saved;
  int epoch = 0;

  /// False once the AI switch is known to be off for a signed-in account:
  /// the button then stays hidden instead of asking.
  bool aiEnabled = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _report() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    final message = error ?? saved?.message;
    widget.onMessage?.call(message);
    LearningMessageNotification(message).dispatch(context);
  });

  @override
  void didUpdateWidget(covariant PersonalLearningButton old) {
    super.didUpdateWidget(old);
    if (old.target.key != widget.target.key) {
      epoch++;
      saved = null;
      retryable = false;
      error = null;
      busy = false;
      _load();
    }
  }

  Future<void> _load() async {
    final current = epoch;
    try {
      widget.target.validate();
    } on FormatException catch (e, stack) {
      if (!kReleaseMode) {
        debugPrint(storyFailureTrace(StoryLearningStep.status, e, stack));
      }
      if (mounted && epoch == current) {
        setState(
          () => error = 'Diese Wortstelle eignet sich nicht als Lernziel. Bitte ein vollständiges Wort in einem kürzeren Satz wählen.',
        );
        if (widget.compact) _report();
      }
      return;
    }
    try {
      final client = ref.read(personalLearningClientProvider);
      if (await client.owner() != null && !await client.consent()) {
        if (mounted && epoch == current) setState(() => aiEnabled = false);
        return;
      }
      final service = await ref.read(personalLearningServiceProvider.future);
      final value = await service.saved(widget.target);
      if (mounted && epoch == current) setState(() => saved = value);
    } catch (e, stack) {
      if (!kReleaseMode) {
        debugPrint(storyFailureTrace(StoryLearningStep.status, e, stack));
      }
      if (mounted && epoch == current) {
        setState(() => error = 'Lernstatus nicht lesbar. Bitte erneut öffnen.');
        if (widget.compact) _report();
      }
    }
  }

  Future<void> add() async {
    if (busy) return;
    final current = epoch, target = widget.target;
    final release = contentTransitionGate.acquire();
    setState(() {
      busy = true;
      retryable = false;
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
      if (await client.owner() == null) {
        throw const PersonalLearningFailure(
          'Zum Hinzufügen bitte zuerst anmelden.',
        );
      }
      // No dialog any more: the AI switch decides (onboarding, Settings).
      if (!await client.consent()) {
        if (mounted && epoch == current) setState(() => aiEnabled = false);
        return;
      }
      if (!mounted || epoch != current) return;
      final value = await service.add(target);
      if (mounted && epoch == current) setState(() => saved = value);
    } catch (e) {
      if (mounted && epoch == current) {
        setState(() {
          retryable = e is PersonalLearningFailure && e.retryable;
          error = e is PersonalLearningFailure ? e.message : 'Lernkarte nicht gespeichert. Bitte Eingabe oder Verbindung prüfen.';
        });
      }
    } finally {
      release();
      if (mounted && epoch == current) setState(() => busy = false);
      if (widget.compact) _report();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!aiEnabled) return const SizedBox.shrink();
    if (widget.compact) {
      final added = saved?.state == StoryAddState.added;
      return AddWordButton(
        busy: busy,
        done: added,
        label: added
            ? 'Hinzugefügt, in Wortliste ansehen'
            : retryable
            ? 'Erneut versuchen'
            : saved?.label ?? 'Zum Lernen hinzufügen',
        onPressed: added && saved?.cardId != null
            ? () => WordListScreen.openTarget(context, saved!.cardId!)
            : saved != null || (error != null && !retryable)
            ? null
            : add,
      );
    }
    return _full(context);
  }

  Widget _full(BuildContext context) => Column(
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
      if (retryable)
        const Text(
          'Zuerst wird ein vorhandenes Ergebnis gesucht. Ein neuer Versuch kann erneut KI-Kosten verursachen.',
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
        onPressed: busy || saved != null || (error != null && !retryable)
            ? null
            : add,
        child: Text(
          busy
              ? 'Wird hinzugefügt …'
              : saved?.state == StoryAddState.added
              ? 'Hinzugefügt'
              : retryable
              ? 'Erneut versuchen'
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
  int epoch = 0;
  StreamSubscription<void>? subscription;
  late PersonalLearningClient client;
  @override
  void initState() {
    super.initState();
    bind(ref.read(personalLearningClientProvider));
  }

  void bind(PersonalLearningClient next) {
    subscription?.cancel();
    client = next;
    subscription = client.changes.listen((_) => reload());
    reload();
  }

  void reload() {
    epoch++;
    setState(() {
      enabled = false;
      busy = true;
      error = null;
    });
    load();
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  Future<void> load() async {
    final generation = epoch;
    try {
      final value = await client.consent();
      if (mounted && generation == epoch) setState(() => enabled = value);
    } catch (_) {
      if (mounted && generation == epoch) {
        setState(() => error = 'Freigabe nicht lesbar.');
      }
    } finally {
      if (mounted && generation == epoch) setState(() => busy = false);
    }
  }

  Future<void> change(bool value) async {
    final selected = client, generation = epoch;
    setState(() => busy = true);
    try {
      await selected.owner();
      final identity = selected.revision();
      if (!mounted || generation != epoch) return;
      if (!mounted ||
          generation != epoch ||
          identity != selected.revision() ||
          !identical(client, selected)) {
        return;
      }
      await selected.setConsent(value);
    } catch (_) {
      if (mounted && generation == epoch) {
        setState(() => error = 'Freigabe nicht gespeichert.');
      }
    } finally {
      if (mounted && generation == epoch) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(personalLearningClientProvider, (_, next) => bind(next));
    return SwitchListTile(
      title: const Text('Private Lernkarten mit KI'),
      subtitle: error == null ? null : Text(error!),
      value: enabled,
      onChanged: busy ? null : change,
    );
  }
}
