import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show Scaffold, ScaffoldMessenger, SnackBar;
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/answer_check.dart';
import '../../domain/grammar_hint.dart';
import '../../domain/srs_state.dart';
import '../../presentation/practice/deck_session_controller.dart';
import '../../presentation/providers/database_providers.dart';
import '../../presentation/providers/learning_providers.dart';
import '../../presentation/providers/streak_providers.dart';
import '../../presentation/providers/preferences_provider.dart';
import '../../presentation/content_unavailable_view.dart';
import '../../theme/app_theme.dart';
import 'widgets/practice_chrome.dart';
import 'widgets/translation_bubble.dart';
export 'widgets/practice_chrome.dart' show SessionTrack;
import '../../widgets/success_feedback_card.dart';
import '../words/widgets/memory_level_indicator.dart';
import '../words/widgets/memory_level_legend_sheet.dart';
import '../settings/settings_screen.dart';
import '../completion/practice_completion_screen.dart';
import '../completion/widgets/stacked_word_cards.dart';
import 'widgets/form_info_sheet.dart';
import 'widgets/practice_input.dart';
import 'widgets/practice_sentence.dart';
import 'widgets/practice_menu.dart';
import 'widgets/local_submission_sheet.dart';

enum DeckPracticeMode { learn, review, mixed }

class DeckPracticeScreen extends ConsumerStatefulWidget {
  const DeckPracticeScreen({
    super.key,
    required this.deckId,
    this.mode = DeckPracticeMode.learn,
    this.sessionSize = 0,
  });
  final String deckId;
  final DeckPracticeMode mode;
  final int sessionSize;
  static Future<void> open(
    BuildContext context, {
    required String deckId,
    DeckPracticeMode mode = DeckPracticeMode.learn,
  }) => Navigator.of(context).push(
    CupertinoPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => DeckPracticeScreen(deckId: deckId, mode: mode),
    ),
  );
  @override
  ConsumerState<DeckPracticeScreen> createState() => _DeckPracticeScreenState();
}

class _DeckPracticeScreenState extends ConsumerState<DeckPracticeScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final _input = PracticeInputController();
  final _focus = FocusNode();
  bool _completing = false;
  final _sentenceKey = GlobalKey<PracticeSentenceState>();
  final _rootKey = GlobalKey();
  Timer? _autoTimer, _errorTimer;
  late final AnimationController _errorShake;
  bool _buttonError = false, _fieldError = false;
  int _errorGeneration = 0, _textRevision = 0;
  double get _errorOffset {
    if (MediaQuery.disableAnimationsOf(context)) return 0;
    final t = _errorShake.value;
    return t == 0 || t == 1 ? 0 : 5 * math.sin(t * math.pi * 6) * (1 - t);
  }

  void _clearError({bool clearField = true}) {
    _errorTimer?.cancel();
    _errorGeneration++;
    _errorShake.stop();
    _errorShake.value = 0;
    if (mounted) {
      setState(() {
        _buttonError = false;
        if (clearField) _fieldError = false;
      });
    }
  }

  void _showError() {
    _clearError();
    final generation = _errorGeneration;
    final passId = ref.read(deckSessionControllerProvider(_args)).pass?.id;
    setState(() {
      _buttonError = true;
      _fieldError = true;
    });
    if (!MediaQuery.disableAnimationsOf(context)) {
      _errorShake.forward(from: 0);
    }
    _errorTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted ||
          generation != _errorGeneration ||
          ref.read(deckSessionControllerProvider(_args)).pass?.id != passId) {
        return;
      }
      setState(() => _buttonError = false);
    });
  }

  void _inputEdited() {
    if (_textRevision == _input.textRevision) return;
    _textRevision = _input.textRevision;
    _clearError();
  }

  bool _translationOpen = true,
      _overlay = false,
      _inputGesture = false,
      _foreground = true;
  int? _historyIndex;
  String? _grammarShownFor;
  WordAnchor? _word;
  DeckSessionArgs get _args => (
    deckId: widget.deckId,
    kind: switch (widget.mode) {
      DeckPracticeMode.learn => DeckSessionKind.learn,
      DeckPracticeMode.review => DeckSessionKind.revue,
      DeckPracticeMode.mixed => DeckSessionKind.mixed,
    },
    size: widget.sessionSize,
  );
  DeckSessionController get _controller =>
      ref.read(deckSessionControllerProvider(_args).notifier);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _errorShake =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 350),
        )..addListener(() {
          if (mounted) setState(() {});
        });
    _input.addListener(_inputEdited);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _autoTimer?.cancel();
    if (!_foreground) _clearError(clearField: false);
    if (_foreground) _schedule();
  }

  @override
  void didChangeMetrics() {
    if (mounted && _word != null) setState(() => _word = null);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoTimer?.cancel();
    _errorTimer?.cancel();
    _errorShake.dispose();
    _input.removeListener(_inputEdited);
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _announce(String text) => SemanticsService.sendAnnouncement(
    View.of(context),
    text,
    TextDirection.ltr,
  );
  void _submit() {
    if (_historyIndex != null || _overlay || _word != null) {
      return;
    }
    final attempt = _input.text;
    // Solved: the keyboard stays up and its Done key moves on.
    if (ref.read(deckSessionControllerProvider(_args)).pass?.solved == true) {
      _next();
      return;
    }
    final result = _controller.submit(attempt);
    if (result == null) return;
    _clearError();
    if (result.verdict == AnswerVerdict.target) {
      _announce('Richtig');
    } else if (result.verdict == AnswerVerdict.wrong) {
      final pass = ref.read(deckSessionControllerProvider(_args)).pass!;
      _input.showWrong(attempt, pass.item.card.form);
      _showError();
      _announce('Falsch');
    } else {
      if (result.verdict == AnswerVerdict.wrongForm) _showError();
      _announce(result.message ?? 'Fast richtig – prüf die Schreibweise.');
    }
  }

  void _reveal() {
    _clearError();
    _controller.reveal();
    final pass = ref.read(deckSessionControllerProvider(_args)).pass!;
    _input.showReveal(pass.item.card.form);
    _announce('Das Wort lautet ${pass.item.card.form}. Tippe es ab.');
    _focus.requestFocus();
  }

  Future<void> _next() async {
    if (_overlay || _word != null || _historyIndex != null) return;
    final s = ref.read(deckSessionControllerProvider(_args));
    if (!s.saved || s.committing) return;
    _autoTimer?.cancel();
    _clearError();
    await _controller.next();
    if (!mounted) return;
    _input.reset();
    if (mounted && !ref.read(deckSessionControllerProvider(_args)).finished) {
      _focus.requestFocus();
    }
  }

  void _schedule() {
    _autoTimer?.cancel();
    if (!mounted ||
        _overlay ||
        _word != null ||
        _historyIndex != null ||
        !_foreground ||
        ModalRoute.of(context)?.isCurrent == false) {
      return;
    }
    final s = ref.read(deckSessionControllerProvider(_args));
    final prefs = ref.read(preferencesProvider).value;
    if (!s.saved || s.committing || s.error != null || s.finished) return;
    if (prefs?.showGrammar == true && _grammarShownFor != s.pass!.id) {
      _grammarShownFor = s.pass!.id;
      _grammar();
    } else if (prefs?.autoNext == true) {
      final id = s.pass!.id;
      _autoTimer = Timer(const Duration(milliseconds: 1400), () {
        if (mounted &&
            ref.read(deckSessionControllerProvider(_args)).pass?.id == id) {
          _next();
        }
      });
    }
  }

  Future<void> _withOverlay(Future<void> Function() action) async {
    _autoTimer?.cancel();
    _clearError(clearField: false);
    final hadFocus = _focus.hasFocus;
    setState(() {
      _overlay = true;
      _word = null;
    });
    _focus.unfocus();
    try {
      await action();
    } finally {
      if (mounted) {
        setState(() => _overlay = false);
        if (hadFocus &&
            _historyIndex == null &&
            ref.read(deckSessionControllerProvider(_args)).pass?.solved ==
                false) {
          _focus.requestFocus();
        }
        _schedule();
      }
    }
  }

  List<SessionSnapshot> _past(DeckSessionState state) => state.snapshots
      .where((s) => state.finished || s.id != state.pass?.id)
      .toList();
  void _history(int direction) {
    if (_overlay || _word != null) return;
    final s = ref.read(deckSessionControllerProvider(_args));
    final past = _past(s);
    final index = _historyIndex ?? past.length;
    final next = (index + direction).clamp(0, past.length);
    if (next == index) return;
    _clearError();
    _autoTimer?.cancel();
    _focus.unfocus();
    setState(() => _historyIndex = next == past.length ? null : next);
    if (_historyIndex == null) {
      if (s.pass?.solved == false) _focus.requestFocus();
      _schedule();
    }
  }

  Future<void> _grammar() => _withOverlay(() async {
    final s = ref.read(deckSessionControllerProvider(_args));
    final snapshot = _historyIndex == null ? null : _past(s)[_historyIndex!];
    final card = snapshot?.card ?? s.pass!.item.card;
    final solved = snapshot != null || s.pass!.solved;
    final hint = grammarHint(card, solved: solved);
    await FormInfoSheet.show(
      context,
      label: card.exerciseLabel,
      explanation: hint.explanation,
      examples: hint.examples,
      forms: solved && snapshot == null
          ? ([card.form, ...s.pass!.item.otherFormsOfLemma]..sort())
          : const [],
    );
  });
  Future<void> _menu() => _withOverlay(() async {
    final s = ref.read(deckSessionControllerProvider(_args));
    final snapshot = _historyIndex == null ? null : _past(s)[_historyIndex!];
    final card = snapshot?.card ?? s.pass!.item.card;
    final sentence = snapshot?.sentence ?? s.pass!.sentence;
    try {
      final user = await ref.read(userRepositoryProvider.future);
      final flags = (await user.cardStates([card.id]))[card.id];
      if (!mounted) return;
      final action = await showPracticeMenu(
        context,
        favorite: flags?.favorite ?? false,
        canDisable: snapshot == null && s.canLeave,
      );
      if (!mounted || action == null) return;
      switch (action) {
        case PracticeAction.share:
          await sharePracticeText(
            context,
            '${card.form} – ${card.translationDe ?? ''}\n${sentence.text}',
          );
        case PracticeAction.disable:
          await _controller.disableCurrent();
          _input.reset();
        case PracticeAction.favorite:
          await user.setCardFlags(
            card.id,
            favorite: !(flags?.favorite ?? false),
          );
        case PracticeAction.report:
          final category = await showProblemCategories(context);
          if (!mounted || category == null) return;
          final pack = (await ref.read(contentRepositoryProvider.future))
              .info
              .version;
          if (!mounted) return;
          await LocalSubmissionSheet.open(
            context,
            category: category,
            cardId: card.id,
            sentenceId: sentence.sentenceId,
            packVersion: pack,
          );
        case PracticeAction.feedback:
          await LocalSubmissionSheet.open(context);
        case PracticeAction.keyboard:
          await showKeyboardHelp(context);
        case PracticeAction.settings:
          await SettingsScreen.open(context);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Änderung nicht gespeichert. Bitte erneut versuchen.',
            ),
          ),
        );
      }
    }
  });

  @override
  Widget build(BuildContext context) {
    final provider = deckSessionControllerProvider(_args);
    final state = ref.watch(provider);
    ref.watch(preferencesProvider);
    ref.listen(provider, (previous, next) {
      if (previous?.pass?.id != next.pass?.id ||
          next.pass?.solved == true ||
          next.finished) {
        _clearError();
      }
      if (next.saved && previous?.saved != true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _schedule();
        });
      }
      if (next.finished && previous?.finished != true) {
        unawaited(_maybeComplete(next));
      }
    });
    final past = _past(state);
    final snapshot = _historyIndex != null && _historyIndex! < past.length
        ? past[_historyIndex!]
        : null;
    final pass = state.pass;
    final contentCard = snapshot?.card ?? pass?.item.card;
    final sentence = snapshot?.sentence ?? pass?.sentence;
    final solved = snapshot != null || pass?.solved == true;
    final canShow =
        sentence != null &&
        (!state.finished || snapshot != null) &&
        !state.loading;
    return PopScope(
      canPop: state.canLeave,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          key: _rootKey,
          children: [
            Column(
              children: [
                SafeArea(
                  bottom: false,
                  child: PracticeSessionBar(
                    done: state.finished
                        ? state.total
                        : state.index + (state.saved ? 1 : 0),
                    total: state.total,
                    repeatIndices: {
                      for (final (i, snapshot) in state.snapshots.indexed)
                        if (snapshot.repeating) i,
                      if (state.pass?.logged == false) state.index,
                    },
                    activeRepeat: state.pass?.logged == false && !state.saved,
                    loading: state.loading,
                    goalReached: state.goalReached,
                    repeating: state.pass?.logged == false,
                    onHome: () {
                      _autoTimer?.cancel();
                      _clearError();
                      if (state.canLeave) Navigator.of(context).maybePop();
                    },
                    onMenu: canShow ? _menu : null,
                  ),
                ),
                Expanded(
                  child: Semantics(
                    container: true,
                    customSemanticsActions: {
                      if ((_historyIndex ?? past.length) > 0)
                        const CustomSemanticsAction(
                          label: 'Vorheriger Durchgang',
                        ): () =>
                            _history(-1),
                      if (snapshot != null)
                        const CustomSemanticsAction(
                          label: 'Nächster Durchgang',
                        ): () =>
                            _history(1),
                    },
                    child: Listener(
                      onPointerDown: (e) => _inputGesture =
                          _sentenceKey.currentState?.containsInput(
                            e.position,
                          ) ??
                          false,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onHorizontalDragEnd: (d) {
                          if (!_inputGesture &&
                              (d.primaryVelocity ?? 0).abs() > 100) {
                            _history((d.primaryVelocity ?? 0) > 0 ? -1 : 1);
                          }
                        },
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                          children: [
                            if (state.goalReached &&
                                state.total == 0 &&
                                !state.loading)
                              CupertinoButton(
                                onPressed: () =>
                                    Navigator.of(context).pushReplacement(
                                      CupertinoPageRoute<void>(
                                        builder: (_) => DeckPracticeScreen(
                                          deckId: widget.deckId,
                                          mode: widget.mode,
                                          sessionSize: -1,
                                        ),
                                      ),
                                    ),
                                child: const Text('Weiterlernen'),
                              ),
                            Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 600,
                                ),
                                child: state.loading
                                    ? const CupertinoActivityIndicator()
                                    : state.error != null && !state.saveFailed
                                    ? ContentUnavailableView(
                                        error: state.error!,
                                        onRetry: () {
                                          retryDatabases(ref);
                                          _controller.start();
                                        },
                                      )
                                    : !canShow
                                    ? state.total == 0
                                          ? Text(
                                              state.goalReached
                                                  ? 'Tagesziel erreicht'
                                                  : 'Gerade gibt es keine Übungen.',
                                              style: AppType.chrome(
                                                color: context
                                                    .appColors
                                                    .textPrimary,
                                              ),
                                            )
                                          : _summary(state)
                                    : Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          if (snapshot != null)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 12,
                                              ),
                                              child: Text(
                                                'Rückblick · ${snapshot.feedback}',
                                                style: AppType.chrome(
                                                  color: context
                                                      .appColors
                                                      .textPrimary,
                                                ),
                                              ),
                                            ),
                                          Container(
                                            decoration: BoxDecoration(
                                              color:
                                                  context.appColors.raisedInk,
                                              borderRadius:
                                                  BorderRadius.circular(24),
                                            ),
                                            padding: const EdgeInsets.fromLTRB(
                                              20,
                                              10,
                                              20,
                                              14,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: CupertinoButton(
                                                    padding: EdgeInsets.zero,
                                                    onPressed: () => _withOverlay(
                                                      () =>
                                                          MemoryLevelLegendSheet.show(
                                                            context,
                                                            current: math.max(
                                                              1,
                                                              snapshot?.box ??
                                                                  pass!
                                                                      .boxBefore,
                                                            ),
                                                          ),
                                                    ),
                                                    child:
                                                        (snapshot?.box ??
                                                                pass!
                                                                    .boxBefore) ==
                                                            0
                                                        ? Text(
                                                            'Neues Wort',
                                                            style: AppType.meta(
                                                              color: context
                                                                  .appColors
                                                                  .textMuted,
                                                            ),
                                                          )
                                                        : MemoryLevelIndicator(
                                                            level:
                                                                snapshot?.box ??
                                                                pass!.boxBefore,
                                                          ),
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                PracticeSentence(
                                                  key: _sentenceKey,
                                                  sentence: sentence,
                                                  input: _input,
                                                  focus: _focus,
                                                  solved: solved,
                                                  keepFocus: snapshot == null,
                                                  error:
                                                      snapshot == null &&
                                                      _fieldError,
                                                  errorOffset: snapshot == null
                                                      ? _errorOffset
                                                      : 0,
                                                  selectedStart: _word?.start,
                                                  onSubmit: _submit,
                                                  onChanged: _controller
                                                      .clearWrongFormHint,
                                                  onWord: (word) {
                                                    _autoTimer?.cancel();
                                                    setState(
                                                      () => _word = word,
                                                    );
                                                  },
                                                ),
                                                const SizedBox(height: 18),
                                                // Exercise label as a chip that
                                                // opens the grammar note.
                                                Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: CupertinoButton(
                                                    padding: EdgeInsets.zero,
                                                    minimumSize: const Size(
                                                      44,
                                                      44,
                                                    ),
                                                    onPressed: _grammar,
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 12,
                                                            vertical: 7,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: context
                                                            .appColors
                                                            .activeTint,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              99,
                                                            ),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            CupertinoIcons
                                                                .info_circle,
                                                            size: 16,
                                                            color: context
                                                                .appColors
                                                                .active,
                                                          ),
                                                          const SizedBox(
                                                            width: 6,
                                                          ),
                                                          Flexible(
                                                            child: Text(
                                                              contentCard!
                                                                  .exerciseLabel,
                                                              style: AppType.chrome(
                                                                size: 14,
                                                                weight:
                                                                    FontWeight
                                                                        .w700,
                                                                color: context
                                                                    .appColors
                                                                    .textPrimary,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          PracticeTranslationCard(
                                            translation:
                                                contentCard.translationDe ?? '',
                                            sentence:
                                                sentence.translationDe ?? '',
                                            open: _translationOpen,
                                            onToggle: () => setState(
                                              () => _translationOpen =
                                                  !_translationOpen,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (canShow && snapshot == null)
                  ListenableBuilder(
                    listenable: _input,
                    builder: (context, _) => PracticeAnswerToolbar(
                      error: _buttonError,
                      errorOffset: _errorOffset,
                      speakerEnabled: false,
                      playing: false,
                      onSpeak: () {},
                      message:
                          state.saved ||
                              state.message == 'Falsch' ||
                              state.message ==
                                  'Tippe das Wort ab, um weiterzumachen.'
                          ? null
                          : state.message,
                      hasInput: _input.text.trim().isNotEmpty,
                      saved: state.saved,
                      solved: solved,
                      revealed: pass!.revealed,
                      onReveal: _reveal,
                      onSubmit: _submit,
                      onNext: state.saveFailed
                          ? _controller.commit
                          : state.saved
                          ? _next
                          : null,
                      nextLabel: state.saveFailed
                          ? 'Speichern wiederholen'
                          : state.committing
                          ? 'Wird gespeichert …'
                          : 'Weiter',
                    ),
                  ),
                if (snapshot != null)
                  const SafeArea(top: false, child: SizedBox(height: 12)),
              ],
            ),
            if (_word case final word?) ...[
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (_) => setState(() => _word = null),
                  onTapDown: (e) {
                    if (!(_sentenceKey.currentState?.selectAt(
                          e.globalPosition,
                        ) ??
                        false)) {
                      setState(() => _word = null);
                      _schedule();
                    }
                  },
                ),
              ),
              _tooltip(word),
            ],
          ],
        ),
      ),
    );
  }

  Widget _tooltip(WordAnchor word) {
    final box = _rootKey.currentContext?.findRenderObject() as RenderBox?;
    final rect = box == null
        ? word.rect
        : word.rect.shift(-box.localToGlobal(Offset.zero));
    return TranslationBubble(anchor: rect, text: word.translation);
  }

  /// A finished session that reached the daily goal ends on the completion
  /// screen instead of the summary (docs/redesign/design-system.md ›
  /// Abschluss). Goal and streak are read fresh, after the last review.
  Future<void> _maybeComplete(DeckSessionState state) async {
    if (_completing || state.records.isEmpty) return;
    _completing = true;
    try {
      ref.invalidate(learningProgressProvider);
      ref.invalidate(streakProvider);
      final progress = await ref.read(learningProgressProvider.future);
      if (!mounted || progress.goal.done < progress.goal.target) return;
      final streak = await ref.read(streakProvider.future);
      if (!mounted) return;
      final seen = <String>{};
      final words = [
        for (final s in state.snapshots)
          if (seen.add(s.card.id))
            CompletionWord(
              form: s.card.form,
              translation: s.card.translationDe ?? '',
              sentence: s.sentence.text,
              isNew: s.box == 0,
            ),
      ];
      final fresh = words.where((w) => w.isNew).toList();
      await Navigator.of(context).pushReplacement(
        PracticeCompletionScreen.route(
          streak: streak,
          goal: progress.goal,
          words: fresh.isNotEmpty ? fresh : words,
        ),
      );
    } catch (_) {
      // The summary stays; the completion screen is a bonus.
    } finally {
      _completing = false;
    }
  }

  Widget _summary(DeckSessionState state) {
    final records = state.records;
    final first = records.where((r) => r.firstAttemptCorrect).length;
    final reset = records
        .where((r) => r.hintUsed || r.revealed || r.errorCount > 0)
        .length;
    final afterTypo = records.length - first - reset;
    return SuccessFeedbackCard(
      title:
          '${records.length} ${records.length == 1 ? 'Übung' : 'Übungen'} geübt',
      subtitle:
          '$first auf Anhieb richtig · $reset zurück auf Stufe 1${afterTypo > 0 ? ' · $afterTypo nach Schreibkorrektur' : ''}',
      explanation: widget.mode == DeckPracticeMode.review
          ? 'In der Stapel-Revue bleiben saubere Antworten auf ihrer Stufe. Fehler, Hinweise und „Wort erfahren“ führen zu Stufe 1.'
          : widget.mode == DeckPracticeMode.mixed
          ? 'Fällige Karten werden zuerst geübt. Neue Übungen starten ohne Hilfe auf Stufe 3. Beim Vorab-Üben bleiben saubere Antworten auf ihrer Stufe.'
          : 'Neue Übungen starten ohne Hilfe auf Stufe 3. Saubere Wiederholungen rücken eine Stufe auf. Fehler, Hinweise und „Wort erfahren“ führen zu Stufe 1.',
      actionLabel: widget.mode == DeckPracticeMode.mixed
          ? 'Zurück zur Startseite'
          : 'Zurück zum Stapel',
      onAction: () => Navigator.of(context).maybePop(),
    );
  }
}
