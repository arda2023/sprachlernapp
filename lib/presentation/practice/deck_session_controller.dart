import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/answer_check.dart';
import '../../domain/content.dart';
import '../../domain/repositories.dart';
import '../../domain/review_pass.dart';
import '../../domain/srs_state.dart';
import '../../domain/story_learning_diagnostics.dart';
import '../providers/database_providers.dart';
import '../providers/story_learning_providers.dart';
import '../../data/learning/practice_item_resolver.dart';
import '../../domain/review_activity.dart';
import '../providers/preferences_provider.dart';
import '../../domain/preferences.dart';

class SessionSnapshot {
  SessionSnapshot(ReviewPass pass)
    : id = pass.id,
      card = pass.item.card,
      sentence = pass.sentence,
      box = pass.boxBefore,
      repeating = !pass.logged,
      feedback = pass.errorCount > 0
          ? 'Richtig nach ${pass.errorCount} ${pass.errorCount == 1 ? 'Fehler' : 'Fehlern'}'
          : pass.revealed
          ? 'Richtig nach „Wort erfahren“'
          : 'Richtig';
  final String id, feedback;
  final ContentCard card;
  final CardSentence sentence;
  final int box;
  final bool repeating;
}

/// size 0 uses the daily remainder (the full goal once it is reached);
/// -1 explicitly continues beyond it.
/// Positive sizes retain the explicit bounded-session API used by fixtures.
typedef DeckSessionArgs = ({String deckId, DeckSessionKind kind, int size});

class DeckSessionState {
  const DeckSessionState({
    this.pass,
    this.loading = false,
    this.committing = false,
    this.saved = false,
    this.finished = false,
    this.goalReached = false,
    this.error,
    this.message,
    this.index = 0,
    this.total = 0,
    this.records = const [],
    this.snapshots = const [],
  });
  final ReviewPass? pass;
  final bool loading, committing, saved, finished, goalReached;
  final Object? error;
  final String? message;
  final int index, total;
  final List<ReviewRecord> records;
  final List<SessionSnapshot> snapshots;
  bool get saveFailed => error != null && pass?.solved == true;
  bool get canLeave => !committing && !saveFailed;
}

final deckSessionControllerProvider = NotifierProvider.autoDispose
    .family<DeckSessionController, DeckSessionState, DeckSessionArgs>(
      DeckSessionController.new,
    );

class DeckSessionController extends Notifier<DeckSessionState> {
  DeckSessionController(this.args);
  final DeckSessionArgs args;
  late PracticeItemResolver _resolver;
  late UserRepository _user;
  late String _version, _device;
  late DateTime Function() _clock;
  List<SessionEntry> _queue = [];
  final _items = <String, PracticeItem>{};
  final _records = <ReviewRecord>[];
  final _snapshots = <SessionSnapshot>[];
  PracticePreferences _preferences = const PracticePreferences();
  ReviewRecord? _pending;
  ReviewPass? _pass;
  int _index = 0;
  bool _saved = false;
  bool _busy = false;
  bool _initialized = false;
  bool _goalReached = false;
  int _sessionLimit = 0;

  @override
  DeckSessionState build() {
    final releaseContentLease = contentTransitionGate.acquire(reason: 'practice');
    ref.onDispose(releaseContentLease);
    _clock = ref.read(clockProvider);
    Future.microtask(start);
    return const DeckSessionState(loading: true);
  }

  void _emit({
    bool loading = false,
    bool committing = false,
    Object? error,
    String? message,
  }) {
    if (!ref.mounted) return;
    state = DeckSessionState(
      pass: _pass,
      loading: loading,
      committing: committing,
      saved: _saved,
      finished: _initialized && _index >= _queue.length,
      goalReached: _goalReached,
      error: error,
      message: message,
      index: _index,
      total: _queue.length,
      records: List.unmodifiable(_records),
      snapshots: List.unmodifiable(_snapshots),
    );
  }

  Future<void> start() async {
    if (_busy || !ref.mounted || (_initialized && state.error == null)) return;
    _busy = true;
    _emit(loading: true);
    try {
      if (!_initialized) {
        _resolver = await ref.read(practiceResolverProvider.future);
        if (!ref.mounted) return;
        _user = await ref.read(userRepositoryProvider.future);
        if (!ref.mounted) return;
        _version = await ref.read(appInfoProvider.future);
        _device = await _user.deviceId();
        _preferences = await _user.preferences();
        final now = _clock().toLocal();
        final today = DateTime(now.year, now.month, now.day);
        final completed = completedTargetsByDay(await _user.activityBetween(
          today, DateTime(now.year, now.month, now.day + 1),
        ))[today] ?? <String>{};
        final remaining = (_preferences.dailyGoal - completed.length).clamp(0, _preferences.dailyGoal);
        _goalReached = remaining == 0;
        // The goal is a recommendation: once reached, a normal start is the
        // voluntary continuation. Cards done today are not due or new any
        // more; Revue/Vorab keep due dates, so such cards stay due.
        _sessionLimit = args.size > 0 ? args.size
            : args.size < 0 || remaining == 0 || args.kind == DeckSessionKind.revue ||
                    args.kind == DeckSessionKind.early
                ? _preferences.dailyGoal
                : remaining;
        if (args.kind != DeckSessionKind.mixed &&
            _resolver.content == null && args.deckId != storyCollectionId &&
            args.deckId.isNotEmpty) {
          throw _resolver.contentError ?? StateError('Inhaltspaket fehlt');
        }
        final scope = args.deckId == storyCollectionId
            ? _resolver.storyPracticeIds
            : args.deckId.isEmpty ? null : await _resolver.deckPracticeIds(args.deckId);
        final states = await _user.allCardStates();
        final cards = _resolver.cards;
        if (args.kind == DeckSessionKind.mixed) {
          final sources = await _resolver.newWordSources();
          final rotation = _user is NewWordRotationStore
              ? await (_user as NewWordRotationStore).lastNewWordSource()
              : null;
          _queue = buildMixedQueue(
            targetsResolved: true,
            activeDeckCardIds: const [],
            deckSources: sources.active,
            sourceOrder: [...sources.order, storySourceId],
            lastSource: rotation,
            storyAdditions: _resolver.additions,
            cards: cards,
            states: states,
            now: _clock(),
            size: _sessionLimit,
          );
        } else if (args.kind == DeckSessionKind.early && scope == null) {
          _queue = buildEarlyQueue(scopeIds: states.keys.toList()..sort(),
              cards: cards, states: states, now: _clock(), size: _sessionLimit);
        } else {
          _queue = buildDeckQueue(
            targetsResolved: true,
            deckCardIds: scope ?? const [],
            states: states,
            cards: cards,
            kind: args.kind,
            now: _clock(),
            size: _sessionLimit,
          );
        }
        for (final item in await _resolver.practiceItems(
          _queue.map((e) => e.cardId).toList(),
        )) {
          _items[item.card.id] = item;
        }
        if (!ref.mounted) return;
        _initialized = true;
      }
      if (ref.mounted) await _showCurrent();
    } catch (error) {
      _emit(error: error);
    } finally {
      _busy = false;
    }
  }

  Future<void> _showCurrent() async {
    if (_index >= _queue.length) {
      _emit();
      return;
    }
    if (!ref.mounted) return;
    final entry = _queue[_index];
    await _user.ensureCards(
      [entry.cardId],
      now: _clock(),
      origin: CardOrigin.deck,
    );
    if (!ref.mounted) return;
    final states = await _user.cardStates([entry.cardId]);
    if (states[entry.cardId]?.isActive == false) {
      _queue.removeAt(_index);
      return _showCurrent();
    }
    if (!ref.mounted) return;
    final item = _items[entry.cardId]!;
    _pass = ReviewPass(
      id: randomUuidV4(),
      item: item,
      sentence: item.practiceSentence,
      state: states[entry.cardId],
      mode: entry.mode ?? args.kind.mode,
      startedAt: _clock(),
      logged: !entry.repeat,
    );
    _pending = null;
    _saved = false;
    _emit(
      message:
          _index == 0 && _goalReached && args.kind != DeckSessionKind.revue &&
              args.kind != DeckSessionKind.early
          ? 'Tagesziel erreicht – du lernst freiwillig weiter.'
          : _index == 0 &&
              args.kind == DeckSessionKind.learn &&
              _queue.length < _sessionLimit
          ? 'Für diese Sitzung sind ${_queue.length} unterschiedliche Karten verfügbar.'
          : entry.mode == ReviewMode.early
          ? 'Vorab-Üben: Eine saubere Antwort lässt Stufe und Fälligkeit unverändert.'
          : null,
    );
  }

  PassFeedback? submit(String input) {
    if (_busy || state.loading || state.error != null) return null;
    final preferences = ref.read(preferencesProvider).value ?? _preferences;
    final feedback = _pass?.submit(
      input,
      _clock(),
      includeDiacritics: preferences.includeDiacritics,
    );
    if (feedback == null) return null;
    final message = switch (feedback.verdict) {
      AnswerVerdict.almost => 'Fast richtig – prüf die Schreibweise.',
      AnswerVerdict.wrong => 'Falsch',
      _ => feedback.message,
    };
    _emit(message: message);
    if (_pass!.solved) unawaited(commit());
    return feedback;
  }

  void reveal() {
    if (_busy || state.loading || state.error != null) return;
    if (_pass?.reveal(_clock()) ?? false) {
      _emit(message: 'Tippe das Wort ab, um weiterzumachen.');
    }
  }

  void clearWrongFormHint() {
    if (!_busy && state.message?.startsWith('Andere Form') == true) _emit();
  }

  Future<void> commit() async {
    if (_busy || _saved || _pass?.solved != true) return;
    _busy = true;
    final keepAlive = ref.keepAlive();
    _emit(committing: true, message: 'Wird gespeichert …');
    try {
      _pending ??= _pass!.complete(
        now: _clock(),
        appVersion: _version,
        deviceId: _device,
      );
      if (_pending case final record?) {
        // false means this exact pass was already persisted (e.g. ambiguous
        // previous write response). It is still a successful completion.
        await _user.recordReview(record);
        _records.add(record);
        final source = _queue[_index].source;
        if (args.kind == DeckSessionKind.mixed && record.boxBefore == 0 && source != null &&
            _user is NewWordRotationStore) {
          // Only a completed new target moves the rotation. It is advisory
          // metadata: a failed write must not undo or hide the saved review.
          try {
            await (_user as NewWordRotationStore).saveLastNewWordSource(source);
          } catch (_) {}
        }
      }
      _saved = true;
      _snapshots.add(SessionSnapshot(_pass!));
      if (_pass!.needsRepeat) _queue = withRepeat(_queue, _index);
      _emit();
    } catch (error) {
      _emit(
        error: error,
        message: 'Nicht gespeichert. Bitte erneut versuchen.',
      );
    } finally {
      _busy = false;
      keepAlive.close();
    }
  }

  Future<void> next() async {
    if (_busy || !_saved || state.finished) return;
    _busy = true;
    _index++;
    // Keep the solved pass mounted until its replacement is ready.
    // Removing it here closes the native text input connection.
    try {
      await _showCurrent();
    } catch (error) {
      _pass = null;
      _saved = false;
      _emit(error: error);
    } finally {
      _busy = false;
    }
  }

  Future<void> disableCurrent() async {
    if (_busy || _pass == null || state.saveFailed) return;
    _busy = true;
    try {
      final id = _pass!.item.card.id;
      await _user.setCardFlags(id, disabled: true);
      // Remove current/future occurrences only. Historical snapshots remain.
      _queue = [
        ..._queue.take(_index),
        ..._queue.skip(_index).where((e) => e.cardId != id),
      ];
      _pass = null;
      _saved = false;
      _emit(loading: true);
      await _showCurrent();
    } finally {
      _busy = false;
    }
  }
}
