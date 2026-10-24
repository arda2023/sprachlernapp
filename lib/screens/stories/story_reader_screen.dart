import '../../data/runtime_translation_client.dart';
import '../../widgets/runtime_translation_sheet.dart';
import '../../presentation/providers/database_providers.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/story_learning.dart';
import '../../domain/story_learning_diagnostics.dart';
import '../../presentation/providers/story_learning_providers.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' show Colors, Scaffold;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../../models/home_models.dart';
import '../../models/news_models.dart';
import '../../domain/sentences.dart';
import '../../models/sample_content.dart';
import '../../models/story_category.dart';
import '../../models/story_models.dart';
import '../../models/playback_clock.dart';
import '../../theme/app_theme.dart';
import '../../widgets/back_bar.dart';
import '../../widgets/reading_toolbar.dart';
import '../home/widgets/story_carousel.dart';
import 'widgets/narration_panel.dart';
import 'widgets/sentence_popover.dart';
import 'widgets/word_popover.dart';

/// Reading view (Redesign 20.10.2026). One long page that only scrolls
/// down; a rail on the left fills with the reading position. Every word is
/// its own tappable span and opens a popover pointing at it (translation,
/// pronunciation, "Zum Lernen hinzufügen"); words already in the learner's
/// vocabulary keep their status underline. In translation mode whole
/// sentences become the tap targets. "Vorlesen" docks a player above the
/// floating dock; while it plays, the sentence being read sits on the Audio
/// Playback Highlight.
class StoryReaderScreen extends StatefulWidget {
  const StoryReaderScreen({
    super.key,
    required this.story,
    required this.text,
    this.document,
    this.sourceLanguage = 'en',
    this.lookup = sampleLookup,
    this.initialMarks = sampleWordMarks,
    this.translate = sampleTranslateSentence,
    this.initialProgress,
    this.onProgress,
  });

  final Story story;
  final String sourceLanguage;
  final StoryDocument? document;
  final StoryText text;
  final WordEntry Function(String surface) lookup;

  /// Headword → mark. Placeholder until the vocabulary store exists.
  final Map<String, WordMark> initialMarks;

  /// Pre-generated sentence translation; placeholder until the content pack.
  final String Function(String sentence) translate;

  /// Where the learner stopped last time (0–1); the page opens there.
  final double? initialProgress;

  /// Reading position whenever scrolling settles and on leaving.
  final ValueChanged<double>? onProgress;

  static Future<void> open(
    BuildContext context,
    Story story, {
    double? initialProgress,
    ValueChanged<double>? onProgress,
  }) => Navigator.of(context).push(
    CupertinoPageRoute<void>(
      builder: (_) => _StoredStoryReader(
        story: story,
        initialProgress: initialProgress,
        onProgress: onProgress,
      ),
    ),
  );

  /// An imported text without an annotated document.
  static Future<void> openText(
    BuildContext context, {
    required Story story,
    required StoryText text,
    WordEntry Function(String surface) lookup = sampleLookup,
    String sourceLanguage = 'en',
    double? initialProgress,
    ValueChanged<double>? onProgress,
  }) => Navigator.of(context).push(
    CupertinoPageRoute<void>(
      builder: (_) => StoryReaderScreen(
        story: story,
        text: text,
        lookup: lookup,
        sourceLanguage: sourceLanguage,
        initialMarks: const {},
        initialProgress: initialProgress,
        onProgress: onProgress,
      ),
    ),
  );

  /// News read like stories: same lookup, translation and narration, plus
  /// the article's subheadings.
  static Future<void> openNews(BuildContext context, NewsArticle article) =>
      Navigator.of(context).push(
        CupertinoPageRoute<void>(
          builder: (_) =>
              StoryReaderScreen(story: article.asStory, text: article.text),
        ),
      );

  @override
  State<StoryReaderScreen> createState() => _StoryReaderScreenState();
}

class _Word {
  _Word(
    this.text,
    this.entry,
    this.recognizer, {
    this.sentenceId,
    this.tokenIndex,
  });
  final String? sentenceId;
  final int? tokenIndex;

  final String text;
  final WordEntry entry;
  final TapGestureRecognizer recognizer;
}

class _Sentence {
  _Sentence(this.text, this.recognizer);

  final String text;
  final TapGestureRecognizer recognizer;

  /// Plain gaps as [String], words as indices into [_StoryReaderScreenState._words].
  final tokens = <Object>[];
}

class _StoryReaderScreenState extends State<StoryReaderScreen> {
  late final void Function() _releaseContent;
  static final _wordPattern = RegExp(
    r"[\p{L}\p{M}]+(?:['’][\p{L}\p{M}]+)*",
    unicode: true,
  );

  final _words = <_Word>[];

  /// Per paragraph: indices into [_sentences]. Words never cross a sentence
  /// boundary, so each sentence holds its own tokens.
  late final List<List<int>> _paragraphSentences;
  final _sentences = <_Sentence>[];

  late final Map<String, WordMark> _marks = Map.of(widget.initialMarks);
  late final _narration = PlaybackClock.forText(widget.text.paragraphs);
  int? _selected;
  int? _selectedSentence;
  bool _translating = false;
  bool _listening = false;

  final _scroll = ScrollController();

  /// Reading position 0–1; drives the rail and the percent in the top bar
  /// without rebuilding the text.
  final _progress = ValueNotifier<double>(0);
  final _scrolled = ValueNotifier<bool>(false);
  bool _moved = false;

  /// Where the last tap landed, so popovers can point at the word.
  Offset? _tapAt;

  TapGestureRecognizer _recognizer(VoidCallback onTap) => TapGestureRecognizer()
    ..onTapUp = ((details) => _tapAt = details.globalPosition)
    ..onTap = onTap;

  /// One key per paragraph, to measure the tapped word for the popover.
  late final _paragraphKeys = [
    for (var i = 0; i < _paragraphSentences.length; i++) GlobalKey(),
  ];

  /// The tapped word's box on screen; the popover's arrow points at it.
  Rect get _anchor {
    final at = _tapAt ?? MediaQuery.sizeOf(context).center(Offset.zero);
    for (final key in _paragraphKeys) {
      final box = key.currentContext?.findRenderObject();
      if (box is! RenderParagraph || !box.hasSize) continue;
      final local = box.globalToLocal(at);
      if (!(Offset.zero & box.size).contains(local)) continue;
      final word = box.getWordBoundary(box.getPositionForOffset(local));
      final rects = box.getBoxesForSelection(
        TextSelection(baseOffset: word.start, extentOffset: word.end),
      );
      if (rects.isEmpty) break;
      final rect = rects.first.toRect();
      return box.localToGlobal(rect.topLeft) & rect.size;
    }
    // Fallback: one text line around the tap (story body: 19 pt × 1.6).
    return Rect.fromCenter(center: at, width: 2, height: 30);
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    final max = position.maxScrollExtent;
    _progress.value = max <= 0 ? 1 : (position.pixels / max).clamp(0.0, 1.0);
    _scrolled.value = position.pixels > 120;
  }

  void _report() {
    if (!_moved) return;
    widget.onProgress?.call(_progress.value);
  }

  @override
  void initState() {
    super.initState();
    _releaseContent = contentTransitionGate.acquire();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final start = widget.initialProgress ?? 0;
      if (!mounted || !_scroll.hasClients || start < 0.02 || start > 0.98) {
        return;
      }
      _scroll.jumpTo(start * _scroll.position.maxScrollExtent);
    });
    _paragraphSentences = widget.document != null
        ? [
            for (final sentence in widget.document!.sentences)
              [_addAnnotated(sentence)],
          ]
        : [
            for (final p in widget.text.paragraphs)
              [
                for (final range in splitSentences(p))
                  _addSentence(p.substring(range.start, range.end)),
              ],
          ];
    _narration.addListener(_onNarration);
  }

  int _addAnnotated(StorySentence source) {
    final index = _sentences.length;
    final sentence = _Sentence(
      source.text,
      _recognizer(() => _translate(index)),
    );
    var cursor = 0;
    for (final t in source.tokens) {
      if (t.start > cursor) {
        sentence.tokens.add(source.text.substring(cursor, t.start));
      }
      if (t.lemmaId == null) {
        sentence.tokens.add(t.surface);
      } else {
        final word = _words.length;
        _words.add(
          _Word(
            t.surface,
            WordEntry(
              headword: t.lemma ?? t.surface,
              partOfSpeech: t.pos ?? '',
              translation: t.gloss ?? 'Übersetzung nicht verfügbar',
            ),
            _recognizer(() => _lookUp(word)),
            sentenceId: source.id,
            tokenIndex: t.index,
          ),
        );
        sentence.tokens.add(word);
      }
      cursor = t.end;
    }
    if (cursor < source.text.length) {
      sentence.tokens.add(source.text.substring(cursor));
    }
    _sentences.add(sentence);
    return index;
  }

  int _addSentence(String text) {
    final index = _sentences.length;
    final sentence = _Sentence(text, _recognizer(() => _translate(index)));
    var last = 0;
    for (final match in _wordPattern.allMatches(text)) {
      if (match.start > last) {
        sentence.tokens.add(text.substring(last, match.start));
      }
      final word = _words.length;
      _words.add(
        _Word(
          match[0]!,
          widget.lookup(match[0]!),
          _recognizer(() => _lookUp(word)),
        ),
      );
      sentence.tokens.add(word);
      last = match.end;
    }
    if (last < text.length) sentence.tokens.add(text.substring(last));
    _sentences.add(sentence);
    return index;
  }

  @override
  void didUpdateWidget(covariant StoryReaderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.document != null) {
      _marks
        ..clear()
        ..addAll(widget.initialMarks);
    }
  }

  @override
  void dispose() {
    _releaseContent();
    // Riverpod state must not change while the tree is being torn down.
    final last = _progress.value;
    final report = _moved ? widget.onProgress : null;
    if (report != null) Future.microtask(() => report(last));
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    _progress.dispose();
    _scrolled.dispose();
    _narration.dispose();
    for (final word in _words) {
      word.recognizer.dispose();
    }
    for (final sentence in _sentences) {
      sentence.recognizer.dispose();
    }
    super.dispose();
  }

  void _onNarration() => setState(() {});

  void _toggleListen() {
    setState(() => _listening = !_listening);
    _listening ? _narration.play() : _narration.stop();
  }

  /// The sentence being read aloud, only while playback runs.
  int? get _narrated => _narration.playing
      ? sentenceAt([
          for (final s in _sentences) s.text.length,
        ], _narration.progress)
      : null;

  void _toggleTranslate() {
    setState(() => _translating = !_translating);
    if (_translating) {
      SemanticsService.sendAnnouncement(
        View.of(context),
        ReadingToolbar.hint,
        TextDirection.ltr,
      );
    }
  }

  Future<void> _translate(int index) async {
    final sentence = _sentences[index].text;
    setState(() => _selectedSentence = index);
    final translation =
        widget.document?.sentences[index].translation ??
        widget.translate(sentence);
    if (hasStoredTranslation(translation)) {
      await SentencePopover.show(
        context,
        anchor: _anchor,
        original: sentence,
        translation: translation,
      );
    } else {
      await RuntimeTranslationSheet.show(
        context,
        lang: widget.sourceLanguage,
        text: sentence,
      );
    }
    if (mounted) setState(() => _selectedSentence = null);
  }

  Color? _inkFor(String surface) =>
      switch (_marks[widget.lookup(surface).headword]) {
        WordMark.active => context.appColors.active,
        WordMark.mastered => context.appColors.mastered,
        null => null,
      };

  /// Translation mode: every leaf span of a sentence carries the sentence's
  /// recognizer (a parent span's recognizer doesn't reach its children);
  /// status underlines stay.
  TextSpan _sentenceSpan(int index, {required bool narrated}) {
    final sentence = _sentences[index];
    final background = index == _selectedSentence
        ? context.appColors.popover.withValues(alpha: 0.28)
        : (narrated ? context.appColors.playback : null);
    final children = <InlineSpan>[
      for (final token in sentence.tokens)
        if (token is String)
          TextSpan(text: token, recognizer: sentence.recognizer)
        else
          TextSpan(
            text: _words[token as int].text,
            recognizer: sentence.recognizer,
            style: _wordSpan(token).style
                ?.copyWith(backgroundColor: background),
          ),
    ];
    return TextSpan(
      style: TextStyle(backgroundColor: background),
      children: children,
    );
  }

  Future<void> _lookUp(int index) async {
    final word = _words[index];
    if (!hasStoredTranslation(word.entry.translation)) {
      final sentence = _sentences
          .firstWhere((s) => s.tokens.contains(index))
          .text;
      await RuntimeTranslationSheet.show(
        context,
        lang: widget.sourceLanguage,
        text: sentence,
        form: word.text,
      );
      return;
    }
    final headword = word.entry.headword;
    setState(() => _selected = index);
    if (widget.document != null && word.sentenceId != null) {
      try {
        final service = ProviderScope.containerOf(
          context,
          listen: false,
        ).read(storyLearningServiceProvider);
        final candidate = await service.candidate(
          widget.story.id,
          word.sentenceId!,
          word.tokenIndex!,
        );
        final status = await service.status(candidate);
        if (!mounted) return;
        await WordPopover.show(
          context,
          anchor: _anchor,
          surface: word.text,
          entry: word.entry,
          mark: status.state == StoryAddState.added ? WordMark.active : null,
          status: status,
          onAdd: () => service.add(candidate),
          onReactivate: () => service.reactivate(candidate),
          onSaved: (result) {
            if (mounted && result.state == StoryAddState.added) {
              setState(() => _marks['${word.sentenceId}/${word.tokenIndex}'] = WordMark.active);
            }
          },
        );
      } catch (error) {
        if (mounted) {
          await WordPopover.show(
            context,
            anchor: _anchor,
            surface: word.text,
            entry: word.entry,
            mark: null,
            learningAvailable: false,
            failure: error is StoryLearningFailure
                ? error : const StoryLearningFailure(StoryLearningStep.context),
            onAdd: () async => const StoryAddResult(StoryAddState.unavailable),
          );
        }
      }
    } else {
      await WordPopover.show(
        context,
        anchor: _anchor,
        surface: word.text,
        entry: word.entry,
        mark: _marks[headword],
        learningAvailable: false,
        onAdd: () async => const StoryAddResult(StoryAddState.unavailable),
      );
    }
    if (mounted) setState(() => _selected = null);
  }

  TextSpan _wordSpan(int index) {
    final word = _words[index];
    final ink = widget.document == null
        ? _inkFor(word.text)
        : (_marks['${word.sentenceId}/${word.tokenIndex}'] == null
              ? null
              : _marks['${word.sentenceId}/${word.tokenIndex}'] ==
                    WordMark.mastered
              ? context.appColors.mastered
              : context.appColors.active);
    return TextSpan(
      text: word.text,
      recognizer: word.recognizer,
      style: TextStyle(
        decoration: ink == null ? null : TextDecoration.underline,
        decorationColor: ink,
        decorationThickness: 2,
        backgroundColor: index == _selected
            ? context.appColors.popover.withValues(alpha: 0.28)
            : null,
      ),
    );
  }

  /// Word mode: the sentence's words keep their own recognizers; the
  /// playback mark sits on the sentence and a tapped word's Hairline
  /// background wins over it.
  TextSpan _wordModeSentenceSpan(int index, {required bool narrated}) =>
      TextSpan(
        style: TextStyle(
          backgroundColor: narrated ? context.appColors.playback : null,
        ),
        children: [
          for (final token in _sentences[index].tokens)
            token is int ? _wordSpan(token) : TextSpan(text: token as String),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final story = widget.story;
    final narrated = _narrated;
    final colors = context.appColors;
    final padding = MediaQuery.paddingOf(context);
    final category = StoryCategory.of(story.topic);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value:
          (colors.light
                  ? SystemUiOverlayStyle.dark
                  : SystemUiOverlayStyle.light)
              .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        body: Stack(
          children: [
            NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n is UserScrollNotification) _moved = true;
                if (n is ScrollEndNotification) _report();
                return false;
              },
              child: ListView(
                controller: _scroll,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: EdgeInsets.fromLTRB(
                  36,
                  padding.top + _TopBar.height + 16,
                  24,
                  padding.bottom + 150,
                ),
                children: [
                  Center(
                    // Keeps a readable measure on tablets.
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: category.color,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  category.icon,
                                  size: 16,
                                  color: const Color(0xFFFFFFFF),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Semantics(
                                  label: storySemanticsLabel(story),
                                  excludeSemantics: true,
                                  child: Text(
                                    storyMetaLine(story),
                                    style: AppType.meta(
                                      color: colors.textMuted,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Semantics(
                            header: true,
                            child: Text(
                              story.title,
                              style: AppType.editorial(
                                color: colors.textPrimary,
                                size: 32,
                                height: 1.15,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Icon(
                                _translating
                                    ? CupertinoIcons.textformat_abc
                                    : CupertinoIcons.hand_point_right,
                                size: 16,
                                color: colors.active,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _translating
                                      ? 'Übersetzungsmodus: Tippe auf einen Satz.'
                                      : 'Tippe auf ein Wort, um es nachzuschlagen.',
                                  style: AppType.chrome(
                                    size: 13,
                                    color: colors.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          Container(
                            height: 1,
                            color: colors.hairline.withValues(alpha: 0.6),
                          ),
                          const SizedBox(height: 24),
                          for (final (i, sentences)
                              in _paragraphSentences.indexed) ...[
                            if (widget.text.headingBefore(i)
                                case final heading?)
                              Padding(
                                padding: EdgeInsets.only(
                                  top: i == 0 ? 0 : 8,
                                  bottom: 8,
                                ),
                                child: Semantics(
                                  header: true,
                                  child: Text(
                                    heading,
                                    style: AppType.editorial(
                                      color: colors.textPrimary,
                                      size: 22,
                                      weight: FontWeight.w700,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 22),
                              child: Text.rich(
                                key: _paragraphKeys[i],
                                TextSpan(
                                  style: AppType.storyBody(),
                                  children: [
                                    for (final s in sentences)
                                      _translating
                                          ? _sentenceSpan(
                                              s,
                                              narrated: s == narrated,
                                            )
                                          : _wordModeSentenceSpan(
                                              s,
                                              narrated: s == narrated,
                                            ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          _EndCard(
                            title: story.title,
                            onDone: () => Navigator.of(context).maybePop(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _TopBar(
                title: story.title,
                progress: _progress,
                scrolled: _scrolled,
                onBack: () => Navigator.of(context).maybePop(),
              ),
            ),
            Positioned(
              left: 14,
              top: padding.top + _TopBar.height + 20,
              bottom: padding.bottom + 112,
              child: _ProgressRail(progress: _progress),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_translating)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _HintChip(text: ReadingToolbar.hint),
                    ),
                  if (_listening)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: NarrationPanel(narration: _narration),
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.only(bottom: padding.bottom + 12),
                    child: _ReaderDock(
                      listening: _listening,
                      translating: _translating,
                      onToggleListen: _toggleListen,
                      onToggleTranslate: _toggleTranslate,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Back, the title once the heading has scrolled away, and the position.
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.progress,
    required this.scrolled,
    required this.onBack,
  });

  static const height = 52.0;

  final String title;
  final ValueListenable<double> progress;
  final ValueListenable<bool> scrolled;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return ValueListenableBuilder<bool>(
      valueListenable: scrolled,
      builder: (context, isScrolled, _) => AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
        decoration: BoxDecoration(
          color: colors.nightPage.withValues(alpha: isScrolled ? 0.96 : 0),
        ),
        child: SizedBox(
          height: height,
          child: Row(
            children: [
              const SizedBox(width: 4),
              MergeSemantics(
                child: CupertinoButton(
                  onPressed: onBack,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(44, 44),
                  child: Semantics(
                    label: 'Zurück',
                    excludeSemantics: true,
                    child: Icon(
                      CupertinoIcons.chevron_left,
                      size: 24,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: isScrolled
                      ? Text(
                          title,
                          key: const ValueKey('title'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: AppType.chrome(
                            size: 15,
                            weight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
              SizedBox(
                width: 60,
                child: ValueListenableBuilder<double>(
                  valueListenable: progress,
                  builder: (context, value, _) => Semantics(
                    label: '${(value * 100).round()} Prozent gelesen',
                    excludeSemantics: true,
                    child: Text(
                      '${(value * 100).round()} %',
                      textAlign: TextAlign.center,
                      style: AppType.chrome(
                        size: 13,
                        weight: FontWeight.w800,
                        color: colors.textMuted,
                        tabular: true,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Thin vertical track on the left; fills from the top as the learner
/// scrolls down.
class _ProgressRail extends StatelessWidget {
  const _ProgressRail({required this.progress});

  final ValueListenable<double> progress;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return ExcludeSemantics(
      child: SizedBox(
        width: 4,
        child: LayoutBuilder(
          builder: (context, constraints) => ValueListenableBuilder<double>(
            valueListenable: progress,
            builder: (context, value, _) => Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.hairline.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: constraints.maxHeight * value,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.active,
                      borderRadius: BorderRadius.circular(4),
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

class _HintChip extends StatelessWidget {
  const _HintChip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 24),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: context.appColors.raisedInk,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: AppType.chrome(size: 13, color: context.appColors.textMuted),
    ),
  );
}

/// Floating capsule with the two reading tools.
class _ReaderDock extends StatelessWidget {
  const _ReaderDock({
    required this.listening,
    required this.translating,
    required this.onToggleListen,
    required this.onToggleTranslate,
  });

  final bool listening;
  final bool translating;
  final VoidCallback onToggleListen;
  final VoidCallback onToggleTranslate;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        // A step lighter than cards, so it floats above the page.
        color: Color.lerp(colors.raisedInk, colors.textPrimary, 0.07),
        borderRadius: BorderRadius.circular(99),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Large Dynamic Type shortens the labels instead of overflowing;
          // the semantics labels stay whole.
          Flexible(
            child: _DockToggle(
              label: 'Vorlesen',
              icon: CupertinoIcons.speaker_2_fill,
              on: listening,
              onPressed: onToggleListen,
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: _DockToggle(
              label: 'Übersetzen',
              icon: CupertinoIcons.textformat_abc,
              on: translating,
              onPressed: onToggleTranslate,
            ),
          ),
        ],
      ),
    );
  }
}

class _DockToggle extends StatelessWidget {
  const _DockToggle({
    required this.label,
    required this.icon,
    required this.on,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool on;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final ink = on ? const Color(0xFFFFFFFF) : colors.textPrimary;
    return MergeSemantics(
      child: CupertinoButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        minimumSize: const Size(44, 44),
        child: Semantics(
          label: label,
          toggled: on,
          excludeSemantics: true,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              color: on ? colors.popover : null,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: ink),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.chrome(weight: FontWeight.w700, color: ink),
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

/// Bottom of the page: the story is done.
class _EndCard extends StatelessWidget {
  const _EndCard({required this.title, required this.onDone});

  final String title;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.raisedInk,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            CupertinoIcons.checkmark_seal_fill,
            size: 40,
            color: colors.progressWords,
          ),
          const SizedBox(height: 10),
          Text(
            'Geschafft!',
            style: AppType.chrome(
              size: 20,
              weight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Du hast „$title“ zu Ende gelesen.',
            textAlign: TextAlign.center,
            style: AppType.chrome(color: colors.textMuted),
          ),
          const SizedBox(height: 14),
          CupertinoButton(
            onPressed: onDone,
            color: colors.active,
            borderRadius: BorderRadius.circular(99),
            minimumSize: const Size(44, 48),
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Text(
              'Fertig',
              style: AppType.chrome(
                weight: FontWeight.w800,
                color: const Color(0xFF1A1206),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoredStoryReader extends ConsumerWidget {
  const _StoredStoryReader({
    required this.story,
    this.initialProgress,
    this.onProgress,
  });
  final Story story;
  final double? initialProgress;
  final ValueChanged<double>? onProgress;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(storyDocumentProvider(story.id))
      .when(
        data: (doc) => StoryReaderScreen(
          story: story,
          document: doc,
          sourceLanguage: ref
              .watch(contentRepositoryProvider)
              .requireValue
              .info
              .lang,
          initialProgress: initialProgress,
          onProgress: onProgress,
          text: StoryText(
            storyId: story.id,
            paragraphs: doc.sentences.map((s) => s.text).toList(),
          ),
          initialMarks: {
            for (final sentence in doc.sentences)
              for (final token in sentence.tokens)
                if (token.senseId != null)
                  if (ref.watch(practiceResolverProvider).value
                      case final resolver?)
                    if (resolver.storyStateId(ref.watch(contentRepositoryProvider).requireValue.info.lang, token) case final id?)
                      if (resolver.states[id] case final state?)
                        if (state.box > 0 || resolver.additions.containsKey(id))
                          '${sentence.id}/${token.index}': state.box == 5
                              ? WordMark.mastered
                              : WordMark.active,
          },
        ),
        loading: () =>
            const Scaffold(body: Center(child: CupertinoActivityIndicator())),
        error: (_, _) => Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                BackBar(onBack: () => Navigator.of(context).maybePop()),
                const Text('Story-Inhalt nicht verfügbar.'),
                CupertinoButton(
                  onPressed: () =>
                      ref.invalidate(storyDocumentProvider(story.id)),
                  child: const Text('Erneut versuchen'),
                ),
              ],
            ),
          ),
        ),
      );
}
