import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' show Colors, Scaffold;
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../../models/home_models.dart';
import '../../models/news_models.dart';
import '../../domain/sentences.dart';
import '../../models/sample_content.dart';
import '../../models/story_models.dart';
import '../../models/playback_clock.dart';
import '../../theme/app_theme.dart';
import '../../widgets/back_bar.dart';
import '../../widgets/reading_toolbar.dart';
import '../../widgets/sentence_translation_sheet.dart';
import '../home/widgets/story_carousel.dart';
import 'widgets/narration_panel.dart';
import 'widgets/word_lookup_sheet.dart';

/// Reading view. Every word is its own tappable span (LingQ mechanic); words
/// already in the learner's vocabulary carry their status ink as an
/// underline, directly in the text. In translation mode whole sentences
/// become the tap targets instead. "Vorlesen" docks a player above the
/// toolbar; while it plays, the sentence being read sits on the Audio
/// Playback Highlight.
class StoryReaderScreen extends StatefulWidget {
  const StoryReaderScreen({
    super.key,
    required this.story,
    required this.text,
    this.lookup = sampleLookup,
    this.initialMarks = sampleWordMarks,
    this.translate = sampleTranslateSentence,
  });

  final Story story;
  final StoryText text;
  final WordEntry Function(String surface) lookup;

  /// Headword → mark. Placeholder until the vocabulary store exists.
  final Map<String, WordMark> initialMarks;

  /// Pre-generated sentence translation; placeholder until the content pack.
  final String Function(String sentence) translate;

  static Future<void> open(BuildContext context, Story story) =>
      Navigator.of(context).push(
        CupertinoPageRoute<void>(
          builder: (_) =>
              StoryReaderScreen(story: story, text: sampleStoryText(story.id)),
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
  _Word(this.text, this.entry, this.recognizer);

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
  static final _wordPattern = RegExp(r"[A-Za-z]+(?:['’][A-Za-z]+)*");

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

  @override
  void initState() {
    super.initState();
    _paragraphSentences = [
      for (final p in widget.text.paragraphs)
        [
          for (final range in splitSentences(p))
            _addSentence(p.substring(range.start, range.end)),
        ],
    ];
    _narration.addListener(_onNarration);
  }

  int _addSentence(String text) {
    final index = _sentences.length;
    final sentence = _Sentence(
      text,
      TapGestureRecognizer()..onTap = () => _translate(index),
    );
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
          TapGestureRecognizer()..onTap = () => _lookUp(word),
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
  void dispose() {
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
    await SentenceTranslationSheet.show(
      context,
      original: sentence,
      translation: widget.translate(sentence),
    );
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
        ? context.appColors.hairline
        : (narrated ? context.appColors.playback : null);
    final children = <InlineSpan>[];
    var last = 0;
    for (final match in _wordPattern.allMatches(sentence.text)) {
      if (match.start > last) {
        children.add(
          TextSpan(
            text: sentence.text.substring(last, match.start),
            recognizer: sentence.recognizer,
          ),
        );
      }
      final ink = _inkFor(match[0]!);
      children.add(
        TextSpan(
          text: match[0],
          recognizer: sentence.recognizer,
          style: TextStyle(
            decoration: ink == null ? null : TextDecoration.underline,
            decorationColor: ink,
            decorationThickness: 2,
          ),
        ),
      );
      last = match.end;
    }
    if (last < sentence.text.length) {
      children.add(
        TextSpan(
          text: sentence.text.substring(last),
          recognizer: sentence.recognizer,
        ),
      );
    }
    return TextSpan(
      style: TextStyle(backgroundColor: background),
      children: children,
    );
  }

  Future<void> _lookUp(int index) async {
    final word = _words[index];
    final headword = word.entry.headword;
    setState(() => _selected = index);
    await WordLookupSheet.show(
      context,
      surface: word.text,
      entry: word.entry,
      mark: _marks[headword],
      // TODO: write to the vocabulary store once the Drift layer exists.
      learningAvailable: false,
      onAdd: () {},
    );
    if (mounted) setState(() => _selected = null);
  }

  TextSpan _wordSpan(int index) {
    final word = _words[index];
    final ink = _inkFor(word.text);
    return TextSpan(
      text: word.text,
      recognizer: word.recognizer,
      style: TextStyle(
        decoration: ink == null ? null : TextDecoration.underline,
        decorationColor: ink,
        decorationThickness: 2,
        backgroundColor: index == _selected ? context.appColors.hairline : null,
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value:
          (context.appColors.light
                  ? SystemUiOverlayStyle.dark
                  : SystemUiOverlayStyle.light)
              .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        bottomNavigationBar: ReadingToolbar(
          translating: _translating,
          onToggleTranslate: _toggleTranslate,
          listening: _listening,
          onToggleListen: _toggleListen,
        ),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              BackBar(onBack: () => Navigator.of(context).maybePop()),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 48),
                  children: [
                    Center(
                      // Keeps a readable measure on tablets.
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Semantics(
                              label: storySemanticsLabel(story),
                              excludeSemantics: true,
                              child: Text(
                                storyMetaLine(story),
                                style: AppType.meta(
                                  color: context.appColors.textMuted,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Semantics(
                              header: true,
                              child: Text(
                                story.title,
                                style: AppType.editorial(
                                  color: context.appColors.textPrimary,
                                  size: 32,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _translating
                                  ? 'Übersetzungsmodus aktiv.'
                                  : 'Tippe auf ein Wort, um es nachzuschlagen.',
                              style: AppType.chrome(
                                size: 13,
                                color: context.appColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 28),
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
                                        color: context.appColors.textPrimary,
                                        size: 22,
                                        weight: FontWeight.w700,
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: Text.rich(
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
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_listening) NarrationPanel(narration: _narration),
            ],
          ),
        ),
      ),
    );
  }
}
