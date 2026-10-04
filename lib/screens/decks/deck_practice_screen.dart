import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show Scaffold, Material, ScaffoldMessenger, SnackBar;
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/answer_check.dart';
import '../../domain/grammar_hint.dart';
import '../../domain/srs_state.dart';
import '../../presentation/practice/deck_session_controller.dart';
import '../../presentation/providers/database_providers.dart';
import '../../presentation/providers/preferences_provider.dart';
import '../../presentation/content_unavailable_view.dart';
import '../../theme/app_theme.dart';
import 'widgets/practice_chrome.dart';
export 'widgets/practice_chrome.dart' show SessionTrack;
import '../../widgets/success_feedback_card.dart';
import '../words/widgets/memory_level_indicator.dart';
import '../words/widgets/memory_level_legend_sheet.dart';
import '../settings/settings_screen.dart';
import 'widgets/form_info_sheet.dart';
import 'widgets/practice_input.dart';
import 'widgets/practice_sentence.dart';
import 'widgets/practice_menu.dart';
import 'widgets/local_submission_sheet.dart';

enum DeckPracticeMode { learn, review }

class DeckPracticeScreen extends ConsumerStatefulWidget {
  const DeckPracticeScreen({
    super.key,
    required this.deckId,
    this.mode = DeckPracticeMode.learn,
    this.sessionSize = 5,
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
    with WidgetsBindingObserver {
  final _input = PracticeInputController();
  final _focus = FocusNode();
  final _sentenceKey = GlobalKey<PracticeSentenceState>();
  final _rootKey = GlobalKey();
  Timer? _autoTimer;
  bool _translationOpen = true,
      _overlay = false,
      _inputGesture = false,
      _foreground = true;
  int? _historyIndex;
  String? _grammarShownFor;
  WordAnchor? _word;
  DeckSessionArgs get _args => (
    deckId: widget.deckId,
    kind: widget.mode == DeckPracticeMode.learn
        ? DeckSessionKind.learn
        : DeckSessionKind.revue,
    size: widget.sessionSize,
  );
  DeckSessionController get _controller =>
      ref.read(deckSessionControllerProvider(_args).notifier);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _autoTimer?.cancel();
    if (_foreground) _schedule();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoTimer?.cancel();
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
    if (_historyIndex != null ||
        _overlay ||
        _word != null ||
        _input.feedback != InputFeedback.typing) {
      return;
    }
    final attempt = _input.text;
    final result = _controller.submit(attempt);
    if (result == null) return;
    if (result.verdict == AnswerVerdict.target) {
      _focus.unfocus();
      _announce('Richtig');
    } else if (result.verdict == AnswerVerdict.wrong) {
      final pass = ref.read(deckSessionControllerProvider(_args)).pass!;
      _input.showWrong(attempt, pass.item.card.form);
      HapticFeedback.lightImpact();
      _announce('Falsch');
    } else {
      _announce(result.message ?? 'Fast richtig – prüf die Schreibweise.');
    }
  }

  void _reveal() {
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
    _input.reset();
    await _controller.next();
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
      label: card.formLabelDe ?? card.pos,
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
      if (next.saved && previous?.saved != true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _schedule();
        });
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
                    onHome: () {
                      _autoTimer?.cancel();
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
                                              'Gerade gibt es keine Wörter zum Üben.',
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
                                                  BorderRadius.circular(14),
                                            ),
                                            padding: const EdgeInsets.fromLTRB(
                                              18,
                                              8,
                                              18,
                                              12,
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
                                                const SizedBox(height: 12),
                                                PracticeSentence(
                                                  key: _sentenceKey,
                                                  sentence: sentence,
                                                  input: _input,
                                                  focus: _focus,
                                                  solved: solved,
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
                                                CupertinoButton(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 8,
                                                      ),
                                                  onPressed: _grammar,
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          contentCard!
                                                                  .formLabelDe ??
                                                              contentCard.pos,
                                                          style: AppType.chrome(
                                                            color: context
                                                                .appColors
                                                                .textPrimary,
                                                          ),
                                                        ),
                                                      ),
                                                      Icon(
                                                        CupertinoIcons
                                                            .chevron_right,
                                                        size: 18,
                                                        color: context
                                                            .appColors
                                                            .textMuted,
                                                      ),
                                                    ],
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
                      speakerEnabled: false,
                      playing: false,
                      onSpeak: () {},
                      message:
                          state.saved ||
                              state.message ==
                                  'Tippe das Wort ab, um weiterzumachen.'
                          ? null
                          : state.message,
                      hasInput: _input.text.isNotEmpty,
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
    final width = math.min(260.0, MediaQuery.sizeOf(context).width - 32);
    return Positioned(
      left: (rect.center.dx - width / 2).clamp(
        16.0,
        MediaQuery.sizeOf(context).width - width - 16,
      ),
      top: rect.top < 110 ? rect.bottom + 8 : null,
      bottom: rect.top < 110
          ? null
          : (box?.size.height ?? MediaQuery.sizeOf(context).height) -
                rect.top +
                8,
      width: width,
      child: Material(
        color: context.appColors.nightPage,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: context.appColors.hairline),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            word.translation,
            textAlign: TextAlign.center,
            style: AppType.chrome(color: context.appColors.textPrimary),
          ),
        ),
      ),
    );
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
          '${records.length} ${records.length == 1 ? 'Wort' : 'Wörter'} geübt',
      subtitle:
          '$first auf Anhieb richtig · $reset zurück auf Stufe 1${afterTypo > 0 ? ' · $afterTypo nach Schreibkorrektur' : ''}',
      explanation: widget.mode == DeckPracticeMode.review
          ? 'In der Stapel-Revue bleiben saubere Antworten auf ihrer Stufe. Fehler, Hinweise und „Wort erfahren“ führen zu Stufe 1.'
          : 'Neue Wörter starten ohne Hilfe auf Stufe 3. Saubere Wiederholungen rücken eine Stufe auf. Fehler, Hinweise und „Wort erfahren“ führen zu Stufe 1.',
      actionLabel: 'Zurück zum Stapel',
      onAction: () => Navigator.of(context).maybePop(),
    );
  }
}
