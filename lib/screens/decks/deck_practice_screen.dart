import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show
        Colors,
        InputDecoration,
        Scaffold,
        ScaffoldMessenger,
        SnackBar,
        TextField,
        UnderlineInputBorder;
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../../domain/answer_check.dart';
import '../../domain/leitner.dart';
import '../../domain/word_form.dart';
import '../../models/speech_playback.dart';
import '../../models/word_list_models.dart';
import '../../models/word_list_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/hairline_track.dart';
import '../../widgets/success_feedback_card.dart';
import '../words/widgets/memory_level_indicator.dart';
import '../words/widgets/memory_level_legend_sheet.dart';
import '../words/widgets/word_details_sheet.dart';
import 'widgets/form_info_sheet.dart';

/// "Lerne mit diesem Stapel" runs a regular session; "Stapel nochmals
/// durchsehen" is early practice (PRODUCT.md, Vorab-Üben): right answers
/// keep their box, errors still reset it.
enum DeckPracticeMode { learn, review }

/// Where one card's gap stands.
enum GapState {
  /// Nothing tried yet, or a near miss ("Fast richtig") still in the field.
  initial,

  /// A wrong attempt is flashing; the field is already cleared.
  wrong,

  /// "Wort erfahren": the answer shows as a hint until the learner types.
  revealed,

  /// The exact answer stands in the gap; the field is gone.
  solved,
}

/// One card of a session: the word as it was when the session started (so
/// the memory level doesn't jump mid-card), where its form sits in the
/// sentence, and the local answer state.
class PracticeCard {
  PracticeCard(this.word, this.form);

  final VocabWord word;
  final WordForm form;

  bool revealed = false;
  bool solved = false;

  /// The attempt flashing in Muted Brick, or null.
  String? wrongAttempt;

  /// Wrong attempts so far; a near miss doesn't count (PRODUCT.md).
  int errors = 0;

  GapState get state => solved
      ? GapState.solved
      : wrongAttempt != null
      ? GapState.wrong
      : revealed
      ? GapState.revealed
      : GapState.initial;

  /// Right without a wrong attempt and without "Wort erfahren".
  bool get correct => errors == 0 && !revealed;
}

/// A simple session queue until the scheduler exists: the first [size]
/// active words whose example sentence holds the word in a form the gap can
/// find, in Wortliste order.
// TODO: due reviews first, then new words, then Vorab-Üben (PRODUCT.md).
List<PracticeCard> deckPracticeQueue(List<VocabWord> words, {int size = 5}) => [
  for (final word in words)
    if (!word.isDisabled)
      if (findWordForm(word.sentence, word.entry.headword) case final form?)
        PracticeCard(word, form),
].take(size).toList();

/// The deck practice session: one sentence card at a time with the word as
/// an inline gap, its German translation below, and a toolbar above the
/// keyboard. Only the exact word moves on (PRODUCT.md); a wrong attempt
/// flashes Muted Brick and clears, "Wort erfahren" shows the word as a hint
/// and counts as an error.
class DeckPracticeScreen extends StatefulWidget {
  const DeckPracticeScreen({
    super.key,
    required this.store,
    this.mode = DeckPracticeMode.learn,
    this.sessionSize = 5,
    this.clock = DateTime.now,
  });

  final WordListStore store;
  final DeckPracticeMode mode;
  final int sessionSize;

  /// Injected so recorded reviews are testable.
  final DateTime Function() clock;

  static Future<void> open(
    BuildContext context, {
    required WordListStore store,
    DeckPracticeMode mode = DeckPracticeMode.learn,
  }) => Navigator.of(context).push(
    CupertinoPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => DeckPracticeScreen(store: store, mode: mode),
    ),
  );

  @override
  State<DeckPracticeScreen> createState() => _DeckPracticeScreenState();
}

class _DeckPracticeScreenState extends State<DeckPracticeScreen> {
  static const _flashDuration = Duration(milliseconds: 600);
  static const _almostMessage = 'Fast richtig – prüf die Schreibweise.';
  static const _revealedMessage = 'Tippe das Wort ab, um weiterzumachen.';

  late final List<PracticeCard> _queue = deckPracticeQueue(
    widget.store.words,
    size: widget.sessionSize,
  );
  final _input = TextEditingController();
  final _focus = FocusNode();
  final _playback = SpeechPlayback();
  Timer? _flashTimer;

  int _index = 0;
  bool _finished = false;

  /// Whether the full German sentence shows; kept across cards.
  bool _translationOpen = true;

  /// Hint in the toolbar ("Fast richtig", what to do after a reveal).
  String? _message;

  PracticeCard get _card => _queue[_index];
  String get _audioKey => 'practice/${_card.word.id}';

  @override
  void dispose() {
    _flashTimer?.cancel();
    _input.dispose();
    _focus.dispose();
    _playback.dispose();
    super.dispose();
  }

  void _announce(String message) => SemanticsService.sendAnnouncement(
    View.of(context),
    message,
    TextDirection.ltr,
  );

  void _toast(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );

  // ------------------------------------------------------------- answers

  void _submit() {
    final card = _card;
    final attempt = _input.text.trim();
    if (card.solved || attempt.isEmpty) return;
    switch (checkAnswer(attempt, card.form.text)) {
      case AnswerResult.correct:
        _flashTimer?.cancel();
        setState(() {
          card
            ..solved = true
            ..wrongAttempt = null;
          _message = null;
        });
        _focus.unfocus();
        widget.store.recordReview(
          card.word.id,
          correct: card.correct,
          early: widget.mode == DeckPracticeMode.review,
          now: widget.clock(),
        );
        _announce('Richtig: ${card.form.text}');
      case AnswerResult.almost:
        setState(() => _message = _almostMessage);
        _announce(_almostMessage);
        _focus.requestFocus();
      case AnswerResult.wrong:
        HapticFeedback.lightImpact();
        _input.clear();
        setState(() {
          card
            ..errors += 1
            ..wrongAttempt = attempt;
          _message = card.revealed ? _revealedMessage : null;
        });
        _announce('Falsch');
        _focus.requestFocus();
        _flashTimer?.cancel();
        _flashTimer = Timer(_flashDuration, () {
          if (mounted) setState(() => card.wrongAttempt = null);
        });
    }
  }

  void _reveal() {
    final card = _card;
    if (card.solved || card.revealed) return;
    _input.clear();
    setState(() {
      card.revealed = true;
      _message = _revealedMessage;
    });
    _announce('Das Wort lautet ${card.form.text}. $_revealedMessage');
    _focus.requestFocus();
  }

  void _next() {
    _playback.stop();
    _input.clear();
    setState(() {
      _message = null;
      if (_index == _queue.length - 1) {
        _finished = true;
      } else {
        _index += 1;
      }
    });
    if (!_finished) _focus.requestFocus();
  }

  void _speak() => _playback.play(_audioKey, _card.form.text);

  // ---------------------------------------------------------- side paths

  void _showGrammar() {
    final card = _card;
    final entry = card.word.entry;
    FormInfoSheet.show(
      context,
      label: formLabel(entry.partOfSpeech, entry.headword, card.form.text),
      explanation: formExplanation(
        entry.partOfSpeech,
        formKindOf(entry.partOfSpeech, entry.headword, card.form.text),
      ),
      // Before the word is known the details would give it away.
      onShowWord: card.solved || card.revealed ? _openDetails : null,
    );
  }

  void _openDetails() => WordDetailsSheet.show(
    context,
    store: widget.store,
    playback: _playback,
    wordId: _card.word.id,
    now: widget.clock(),
  );

  Future<void> _openMenu() async {
    final word = widget.store.byId(_card.word.id);
    final action = await showCupertinoModalPopup<VoidCallback>(
      context: context,
      builder: (context) {
        Widget item(String label, VoidCallback onChosen) =>
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(context).pop(onChosen),
              child: Text(label, style: AppType.chrome(size: 17)),
            );
        return CupertinoActionSheet(
          title: Text(word.entry.headword, style: AppType.meta()),
          actions: [
            item(
              word.isDisabled ? 'Wort wieder aktivieren' : 'Wort deaktivieren',
              () => _toast(
                widget.store.toggleDisabled(word.id)
                    ? 'Wort deaktiviert'
                    : 'Wort wieder aktiviert',
              ),
            ),
            item(
              word.isFavorite
                  ? 'Aus Favoriten entfernen'
                  : 'Zu Favoriten hinzufügen',
              () => _toast(
                widget.store.toggleFavorite(word.id)
                    ? 'Zu Favoriten hinzugefügt'
                    : 'Aus Favoriten entfernt',
              ),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Abbrechen',
              style: AppType.chrome(size: 17, weight: FontWeight.w600),
            ),
          ),
        );
      },
    );
    if (mounted) action?.call();
  }

  // --------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final total = _queue.length;
    final done = _finished ? total : _index + (_card.solved ? 1 : 0);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        // The toolbar follows the keyboard itself (see _AnswerToolbar).
        resizeToAvoidBottomInset: false,
        body: ListenableBuilder(
          listenable: _playback,
          builder: (context, _) => Column(
            children: [
              SafeArea(
                bottom: false,
                child: _SessionBar(
                  done: done,
                  total: total,
                  onHome: () => Navigator.of(context).maybePop(),
                  onMenu: _finished || total == 0 ? null : _openMenu,
                ),
              ),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.manual,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: total == 0
                            ? Text(
                                'Gerade gibt es keine Wörter zum Üben.',
                                style: AppType.chrome(
                                  color: AppColors.textMuted,
                                ),
                              )
                            : _finished
                            ? _summary()
                            : _cards(),
                      ),
                    ),
                  ],
                ),
              ),
              if (!_finished && total > 0)
                _AnswerToolbar(
                  speakerEnabled: _card.solved || _card.revealed,
                  playing: _playback.isPlaying(_audioKey),
                  onSpeak: _speak,
                  message: _message,
                  solved: _card.solved,
                  revealed: _card.revealed,
                  onReveal: _reveal,
                  onNext: _next,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cards() {
    final card = _card;
    final entry = card.word.entry;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ExerciseCard(
          key: ValueKey(card.word.id),
          card: card,
          input: _input,
          focus: _focus,
          playing: _playback.isPlaying(_audioKey),
          onSubmit: _submit,
          onShowLegend: () =>
              MemoryLevelLegendSheet.show(context, current: card.word.box),
          onShowGrammar: _showGrammar,
          formLabel: formLabel(
            entry.partOfSpeech,
            entry.headword,
            card.form.text,
          ),
        ),
        const SizedBox(height: 12),
        _TranslationCard(
          translation: entry.translation,
          sentence: card.word.sentenceTranslation,
          open: _translationOpen,
          onToggle: () => setState(() => _translationOpen = !_translationOpen),
        ),
      ],
    );
  }

  Widget _summary() {
    final total = _queue.length;
    final right = _queue.where((c) => c.correct).length;
    final review = widget.mode == DeckPracticeMode.review;
    return SuccessFeedbackCard(
      title: '$total ${total == 1 ? 'Wort' : 'Wörter'} geübt',
      subtitle:
          '$right auf Anhieb richtig · ${total - right} zurück auf Stufe 1',
      explanation: review
          ? 'In der Stapel-Revue bleiben richtige Antworten auf ihrer Stufe. '
                'Fehler und „Wort erfahren“ setzen ein Wort auf Stufe 1 zurück.'
          : 'Richtige Antworten rücken eine Stufe auf. Fehler und „Wort '
                'erfahren“ setzen ein Wort auf Stufe 1 zurück.',
      actionLabel: 'Zurück zum Stapel',
      onAction: () => Navigator.of(context).maybePop(),
    );
  }
}

/// Home (ends the session), how many words of the session are left over a
/// neutral track with one segment per word, and the word menu.
class _SessionBar extends StatelessWidget {
  const _SessionBar({
    required this.done,
    required this.total,
    required this.onHome,
    required this.onMenu,
  });

  final int done;
  final int total;
  final VoidCallback onHome;
  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context) {
    final left = total - done;
    final label = left == 0
        ? 'Alle Wörter geübt'
        : 'Noch $left ${left == 1 ? 'Wort' : 'Wörter'}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          _BarButton(
            label: 'Session beenden',
            icon: CupertinoIcons.house,
            onPressed: onHome,
          ),
          Expanded(
            child: Semantics(
              label: left == 0
                  ? 'Alle $total Wörter geübt'
                  : 'Noch $left von $total Wörtern',
              excludeSemantics: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  // The track spans the space between the two buttons.
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.meta().copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 6),
                    SessionTrack(done: done, total: total),
                  ],
                ),
              ),
            ),
          ),
          if (onMenu case final onMenu?)
            _BarButton(
              label: 'Mehr',
              icon: CupertinoIcons.ellipsis_vertical,
              onPressed: onMenu,
            )
          else
            const SizedBox(width: 44),
        ],
      ),
    );
  }
}

/// Neutral session progress (Neutral Progress Rule): one `3pt` segment per
/// word, `textMuted` once done, Hairline while left, so the count of words
/// left can be read off the bar. Long sessions fall back to one track.
class SessionTrack extends StatelessWidget {
  const SessionTrack({super.key, required this.done, required this.total});

  static const maxSegments = 12;

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    if (total == 0 || total > maxSegments) {
      return HairlineTrack(fraction: total == 0 ? 0 : done / total);
    }
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 3),
          Expanded(
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: i < done ? AppColors.textMuted : AppColors.hairline,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _BarButton extends StatelessWidget {
  const _BarButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: CupertinoButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        minimumSize: const Size(44, 44),
        child: Semantics(
          label: label,
          excludeSemantics: true,
          child: Icon(icon, size: 22, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

/// The sentence card: memory level, the English sentence with the word as
/// an inline gap, and right under it the word class and form, which opens
/// the grammar sheet.
class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    super.key,
    required this.card,
    required this.input,
    required this.focus,
    required this.playing,
    required this.onSubmit,
    required this.onShowLegend,
    required this.onShowGrammar,
    required this.formLabel,
  });

  final PracticeCard card;
  final TextEditingController input;
  final FocusNode focus;
  final bool playing;
  final VoidCallback onSubmit;
  final VoidCallback onShowLegend;
  final VoidCallback onShowGrammar;
  final String formLabel;

  static TextStyle get sentenceStyle => AppType.editorial(
    size: 26,
    weight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0,
  );

  @override
  Widget build(BuildContext context) {
    final sentence = card.word.sentence;
    final form = card.form;
    final style = sentenceStyle;
    final box = card.word.box;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.raisedInk,
        border: Border.all(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MergeSemantics(
                  child: CupertinoButton(
                    onPressed: onShowLegend,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(44, 44),
                    alignment: Alignment.centerLeft,
                    child: Semantics(
                      label:
                          'Erinnerungsstufe $box von $leitnerBoxCount: '
                          '${memoryLevelTitle(box)}',
                      excludeSemantics: true,
                      child: MemoryLevelIndicator(level: box),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    style: style,
                    children: [
                      TextSpan(text: sentence.substring(0, form.start)),
                      if (card.solved)
                        TextSpan(
                          text: form.text,
                          semanticsLabel: '${form.text}, richtig',
                          style: TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                            // Audio Playback Highlight while it is spoken.
                            backgroundColor: playing
                                ? AppColors.playback
                                : null,
                          ),
                        )
                      else
                        WidgetSpan(
                          alignment: PlaceholderAlignment.baseline,
                          baseline: TextBaseline.alphabetic,
                          child: _GapField(
                            card: card,
                            input: input,
                            focus: focus,
                            style: style,
                            onSubmit: onSubmit,
                          ),
                        ),
                      TextSpan(text: sentence.substring(form.end)),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                MergeSemantics(
                  child: CupertinoButton(
                    onPressed: onShowGrammar,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(44, 44),
                    pressedOpacity: 0.7,
                    alignment: Alignment.centerLeft,
                    child: Semantics(
                      label: '$formLabel, Grammatik-Hinweis',
                      excludeSemantics: true,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              formLabel,
                              style: AppType.chrome(
                                weight: FontWeight.w600,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            CupertinoIcons.info_circle,
                            size: 17,
                            color: AppColors.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The inline field. A wrong attempt flashes as its hint in Muted Brick on
/// Brick Tint; a revealed word shows as the hint in Pale Sky. Typing hides
/// either.
class _GapField extends StatelessWidget {
  const _GapField({
    required this.card,
    required this.input,
    required this.focus,
    required this.style,
    required this.onSubmit,
  });

  final PracticeCard card;
  final TextEditingController input;
  final FocusNode focus;
  final TextStyle style;
  final VoidCallback onSubmit;

  static final _revealColor = AppColors.memoryLevel2.withValues(alpha: 0.6);
  static final _wrongColor = AppColors.error.withValues(alpha: 0.75);

  @override
  Widget build(BuildContext context) {
    final state = card.state;
    final painter = TextPainter(
      text: TextSpan(text: card.form.text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final width = math.max(64.0, painter.width + 20);
    painter.dispose();

    final (hint, hintColor) = switch (state) {
      GapState.wrong => (card.wrongAttempt, _wrongColor),
      GapState.revealed => (card.form.text, _revealColor),
      _ => (null, null),
    };
    final line = state == GapState.wrong
        ? AppColors.error
        : AppColors.textMuted;

    return Semantics(
      label: state == GapState.revealed
          ? 'Lücke, Lösung: ${card.form.text}'
          : 'Lücke',
      child: SizedBox(
        width: width,
        child: TextField(
          controller: input,
          focusNode: focus,
          autofocus: true,
          style: style,
          // Typing starts where the gap starts, like running text.
          textAlign: TextAlign.start,
          cursorColor: AppColors.textPrimary,
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: TextInputAction.done,
          // Keeps the keyboard open after every attempt.
          onEditingComplete: onSubmit,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 2),
            // A wrong attempt flashes on Brick Tint (Feedback Rule).
            filled: state == GapState.wrong,
            fillColor: AppColors.errorTint,
            hintText: hint,
            hintStyle: style.copyWith(color: hintColor),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: line, width: 2),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: state == GapState.wrong
                    ? AppColors.error
                    : AppColors.textPrimary,
                width: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The German translation of the word, and, folded out, of the sentence.
class _TranslationCard extends StatelessWidget {
  const _TranslationCard({
    required this.translation,
    required this.sentence,
    required this.open,
    required this.onToggle,
  });

  final String translation;
  final String sentence;
  final bool open;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.raisedInk,
        border: Border.all(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MergeSemantics(
            child: CupertinoButton(
              onPressed: onToggle,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              minimumSize: const Size(44, 56),
              pressedOpacity: 0.7,
              child: Semantics(
                label: 'Übersetzung: $translation, ganzer Satz',
                expanded: open,
                excludeSemantics: true,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        translation,
                        style: AppType.editorial(size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      open
                          ? CupertinoIcons.chevron_up
                          : CupertinoIcons.chevron_down,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: open
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(height: 1, color: AppColors.hairline),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                        child: Text(
                          sentence,
                          style: AppType.editorial(
                            size: 18,
                            weight: FontWeight.w400,
                            color: AppColors.textMuted,
                            height: 1.45,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// Sits on the bottom edge, or right above the keyboard while it is open.
/// Left: "Aussprechen", unlit until the word is known. Middle: a hint.
/// Right: "Wort erfahren", or "Weiter" once solved.
class _AnswerToolbar extends StatelessWidget {
  const _AnswerToolbar({
    required this.speakerEnabled,
    required this.playing,
    required this.onSpeak,
    required this.message,
    required this.solved,
    required this.revealed,
    required this.onReveal,
    required this.onNext,
  });

  final bool speakerEnabled;
  final bool playing;
  final VoidCallback onSpeak;
  final String? message;
  final bool solved;
  final bool revealed;
  final VoidCallback onReveal;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final safeArea = MediaQuery.viewPaddingOf(context).bottom;
    final speakerColor = !speakerEnabled
        ? AppColors.iconOff
        : AppColors.textPrimary;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.raisedInk,
        border: Border(top: BorderSide(color: AppColors.hairline)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          8,
          6,
          12,
          6 + (keyboard > 0 ? keyboard : safeArea),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) => ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Row(
              children: [
                MergeSemantics(
                  child: CupertinoButton(
                    onPressed: speakerEnabled ? onSpeak : null,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(44, 44),
                    child: Semantics(
                      label: 'Aussprechen',
                      enabled: speakerEnabled,
                      excludeSemantics: true,
                      child: Icon(
                        playing
                            ? CupertinoIcons.speaker_2_fill
                            : CupertinoIcons.speaker_2,
                        size: 22,
                        color: speakerColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Takes all free space (the spacer), so the action button
                // sits flush right, with or without a hint.
                Expanded(
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      message ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.chrome(
                        size: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ConstrainedBox(
                  // Large Dynamic Type wraps the label instead of pushing
                  // the speaker off screen.
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth * 0.6,
                  ),
                  child: solved
                      ? _ToolbarButton(
                          label: 'Weiter',
                          icon: CupertinoIcons.checkmark_alt,
                          primary: true,
                          onPressed: onNext,
                        )
                      : _ToolbarButton(
                          label: 'Wort erfahren',
                          onPressed: revealed ? null : onReveal,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A `44pt` pill. Primary: `textPrimary` fill, Night Page label (the
/// Primary button's grammar). Otherwise an outline on Hairline.
class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.primary = false,
  });

  final String label;
  final IconData? icon;
  final bool primary;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final foreground = primary
        ? AppColors.nightPage
        : (enabled ? AppColors.textPrimary : AppColors.iconOff);
    return MergeSemantics(
      child: CupertinoButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        minimumSize: const Size(44, 44),
        child: Semantics(
          label: label,
          enabled: enabled,
          excludeSemantics: true,
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: primary ? AppColors.textPrimary : null,
              border: primary ? null : Border.all(color: AppColors.hairline),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon case final icon?) ...[
                  Icon(icon, size: 18, color: foreground),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    style: AppType.chrome(
                      weight: FontWeight.w600,
                      color: foreground,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
