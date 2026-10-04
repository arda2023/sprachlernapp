import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/answer_check.dart';
import '../../domain/content.dart';
import '../../domain/repositories.dart';
import '../../domain/review_pass.dart';
import '../../domain/srs_state.dart';
import '../providers/database_providers.dart';
import '../providers/deck_providers.dart';
import '../providers/preferences_provider.dart';
import '../../domain/preferences.dart';

class SessionSnapshot {
  SessionSnapshot(ReviewPass pass)
    : id = pass.id,
      card = pass.item.card,
      sentence = pass.sentence,
      box = pass.boxBefore,
      feedback = pass.errorCount > 0
          ? 'Richtig nach ${pass.errorCount} ${pass.errorCount == 1 ? 'Fehler' : 'Fehlern'}'
          : pass.revealed || pass.hintUsed
          ? 'Richtig mit Hinweis'
          : 'Richtig';
  final String id, feedback;
  final ContentCard card;
  final CardSentence sentence;
  final int box;
}

typedef DeckSessionArgs = ({String deckId, DeckSessionKind kind, int size});

class DeckSessionState {
  const DeckSessionState({
    this.pass,
    this.loading = false,
    this.committing = false,
    this.saved = false,
    this.finished = false,
    this.error,
    this.message,
    this.index = 0,
    this.total = 0,
    this.records = const [],
    this.snapshots = const [],
  });
  final ReviewPass? pass;
  final bool loading, committing, saved, finished;
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
  late ContentRepository _content;
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

  @override
  DeckSessionState build() {
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
      error: error,
      message: message,
      index: _index,
      total: _queue.length,
      records: List.unmodifiable(_records),
      snapshots: List.unmodifiable(_snapshots),
    );
  }

  Future<void> start() async {
    if (_busy || !ref.mounted) return;
    _busy = true;
    _emit(loading: true);
    try {
      if (!_initialized) {
        _content = await ref.read(contentRepositoryProvider.future);
        if (!ref.mounted) return;
        _user = await ref.read(userRepositoryProvider.future);
        if (!ref.mounted) return;
        _version = await ref.read(appInfoProvider.future);
        _device = await _user.deviceId();
        _preferences = await _user.preferences();
        final ids = await _content.deckCardIds(args.deckId);
        final states = await _user.allCardStates();
        final cards = {
          for (final c in await _content.selectionCards({
            ...ids,
            ...states.keys,
          }))
            c.id: c,
        };
        _queue = buildDeckQueue(
          deckCardIds: ids,
          states: states,
          cards: cards,
          kind: args.kind,
          now: _clock(),
          size: args.size,
        );
        for (final item in await _content.practiceItems(
          _queue.map((e) => e.cardId).toList(),
        )) {
          _items[item.card.id] = item;
        }
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
    final entry = _queue[_index];
    await _user.ensureCards(
      [entry.cardId],
      now: _clock(),
      origin: CardOrigin.deck,
    );
    final states = await _user.cardStates([entry.cardId]);
    if (states[entry.cardId]?.isActive == false) {
      _queue.removeAt(_index);
      return _showCurrent();
    }
    final counts = await _user.reviewCounts([entry.cardId]);
    if (!ref.mounted) return;
    final item = _items[entry.cardId]!;
    _pass = ReviewPass(
      id: randomUuidV4(),
      item: item,
      sentence: item.sentenceForPass(counts[entry.cardId] ?? 0),
      state: states[entry.cardId],
      mode: args.kind.mode,
      startedAt: _clock(),
      logged: !entry.repeat,
    );
    _pending = null;
    _saved = false;
    _emit(
      message:
          _index == 0 &&
              args.kind == DeckSessionKind.learn &&
              _queue.length < args.size
          ? 'Für diese Sitzung sind ${_queue.length} unterschiedliche Karten verfügbar.'
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
      }
      _saved = true;
      _snapshots.add(SessionSnapshot(_pass!));
      if (_pass!.needsRepeat) _queue = withRepeat(_queue, _index);
      if (ref.mounted) {
        ref.invalidate(decksProvider);
        ref.invalidate(vocabBreakdownProvider);
      }
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
    _saved = false;
    _pass = null;
    _emit(loading: true);
    try {
      await _showCurrent();
    } catch (error) {
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
      ref.invalidate(decksProvider);
      ref.invalidate(vocabBreakdownProvider);
    } finally {
      _busy = false;
    }
  }
}
