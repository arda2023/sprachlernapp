import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' show Colors, Scaffold;
import 'package:flutter/services.dart';

import '../../models/home_models.dart';
import '../../models/sample_content.dart';
import '../../models/story_models.dart';
import '../../theme/app_theme.dart';
import '../home/widgets/story_carousel.dart';
import 'widgets/word_lookup_sheet.dart';

/// Reading view. Every word is its own tappable span (LingQ mechanic); words
/// already in the learner's vocabulary carry their status ink as an
/// underline, directly in the text.
class StoryReaderScreen extends StatefulWidget {
  const StoryReaderScreen({
    super.key,
    required this.story,
    required this.text,
    this.lookup = sampleLookup,
    this.initialMarks = sampleWordMarks,
  });

  final Story story;
  final StoryText text;
  final WordEntry Function(String surface) lookup;

  /// Headword → mark. Placeholder until the vocabulary store exists.
  final Map<String, WordMark> initialMarks;

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

class _StoryReaderScreenState extends State<StoryReaderScreen> {
  static final _wordPattern = RegExp(r"[A-Za-z]+(?:['’][A-Za-z]+)*");

  /// Per paragraph: plain gaps as [String], words as indices into [_words].
  late final List<List<Object>> _paragraphs;
  final _words = <_Word>[];
  late final Map<String, WordMark> _marks = Map.of(widget.initialMarks);
  int? _selected;

  @override
  void initState() {
    super.initState();
    _paragraphs = [for (final p in widget.text.paragraphs) _tokenize(p)];
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
    super.dispose();
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
    final ink = switch (_marks[word.entry.headword]) {
      WordMark.active => AppColors.active,
      WordMark.mastered => AppColors.mastered,
      null => null,
    };
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
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _ReaderTopBar(onBack: () => Navigator.of(context).maybePop()),
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
                              'Tippe auf ein Wort, um es nachzuschlagen.',
                              style: AppType.chrome(
                                size: 13,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 28),
                            for (final paragraph in _paragraphs)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: Text.rich(
                                  TextSpan(
                                    style: AppType.storyBody(),
                                    children: [
                                      for (final token in paragraph)
                                        token is int
                                            ? _wordSpan(token)
                                            : TextSpan(text: token as String),
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

class _ReaderTopBar extends StatelessWidget {
  const _ReaderTopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          MergeSemantics(
            child: CupertinoButton(
              onPressed: onBack,
              padding: EdgeInsets.zero,
              minimumSize: const Size(44, 44),
              child: Semantics(
                label: 'Zurück',
                excludeSemantics: true,
                child: const Icon(
                  CupertinoIcons.chevron_left,
                  size: 24,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
