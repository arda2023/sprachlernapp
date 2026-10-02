import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' show Colors, Scaffold;
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../../models/home_models.dart';
import '../../models/sample_content.dart';
import '../../domain/sentences.dart';
import '../../models/story_models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/back_bar.dart';
import '../../widgets/reading_toolbar.dart';
import '../../widgets/sentence_translation_sheet.dart';
import '../home/widgets/story_carousel.dart';
import 'widgets/word_lookup_sheet.dart';

/// Reading view. Every word is its own tappable span (LingQ mechanic); words
/// already in the learner's vocabulary carry their status ink as an
/// underline, directly in the text. In translation mode whole sentences
/// become the tap targets instead.
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
}

class _StoryReaderScreenState extends State<StoryReaderScreen> {
  static final _wordPattern = RegExp(r"[A-Za-z]+(?:['’][A-Za-z]+)*");

  /// Per paragraph: plain gaps as [String], words as indices into [_words].
  late final List<List<Object>> _paragraphs;
  final _words = <_Word>[];

  /// Per paragraph: indices into [_sentences].
  late final List<List<int>> _paragraphSentences;
  final _sentences = <_Sentence>[];

  late final Map<String, WordMark> _marks = Map.of(widget.initialMarks);
  int? _selected;
  int? _selectedSentence;
  bool _translating = false;

  @override
  void initState() {
    super.initState();
    _paragraphs = [for (final p in widget.text.paragraphs) _tokenize(p)];
    _paragraphSentences = [
      for (final p in widget.text.paragraphs)
        [
          for (final range in splitSentences(p))
            _addSentence(p.substring(range.start, range.end)),
        ],
    ];
  }

  int _addSentence(String text) {
    final index = _sentences.length;
    _sentences.add(
      _Sentence(text, TapGestureRecognizer()..onTap = () => _translate(index)),
    );
    return index;
  }

  List<Object> _tokenize(String paragraph) {
    final tokens = <Object>[];
    var last = 0;
    for (final match in _wordPattern.allMatches(paragraph)) {
      if (match.start > last) {
        tokens.add(paragraph.substring(last, match.start));
      }
      final index = _words.length;
      final word = match[0]!;
      _words.add(
        _Word(
          word,
          widget.lookup(word),
          TapGestureRecognizer()..onTap = () => _lookUp(index),
        ),
      );
      tokens.add(index);
      last = match.end;
    }
    if (last < paragraph.length) tokens.add(paragraph.substring(last));
    return tokens;
  }

  @override
  void dispose() {
    for (final word in _words) {
      word.recognizer.dispose();
    }
    for (final sentence in _sentences) {
      sentence.recognizer.dispose();
    }
    super.dispose();
  }

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
        WordMark.active => AppColors.active,
        WordMark.mastered => AppColors.mastered,
        null => null,
      };

  /// Translation mode: every leaf span of a sentence carries the sentence's
  /// recognizer (a parent span's recognizer doesn't reach its children);
  /// status underlines stay.
  TextSpan _sentenceSpan(int index) {
    final sentence = _sentences[index];
    final background = index == _selectedSentence ? AppColors.hairline : null;
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
      onAdd: () => setState(() => _marks[headword] ??= WordMark.active),
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
        backgroundColor: index == _selected ? AppColors.hairline : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.story;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        bottomNavigationBar: ReadingToolbar(
          translating: _translating,
          onToggleTranslate: _toggleTranslate,
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
                                style: AppType.meta(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Semantics(
                              header: true,
                              child: Text(
                                story.title,
                                style: AppType.editorial(size: 32),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _translating
                                  ? 'Übersetzungsmodus aktiv.'
                                  : 'Tippe auf ein Wort, um es nachzuschlagen.',
                              style: AppType.chrome(
                                size: 13,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 28),
                            for (final (i, paragraph) in _paragraphs.indexed)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: Text.rich(
                                  TextSpan(
                                    style: AppType.storyBody(),
                                    children: _translating
                                        ? [
                                            for (final sentence
                                                in _paragraphSentences[i])
                                              _sentenceSpan(sentence),
                                          ]
                                        : [
                                            for (final token in paragraph)
                                              token is int
                                                  ? _wordSpan(token)
                                                  : TextSpan(
                                                      text: token as String,
                                                    ),
                                          ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
