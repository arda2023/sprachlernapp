import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../../../theme/app_theme.dart';

/// A word from the finished session.
class CompletionWord {
  const CompletionWord({
    required this.form,
    required this.translation,
    required this.sentence,
    required this.isNew,
  });

  final String form;
  final String translation;
  final String sentence;

  /// First time the learner saw it (box 0 before this session).
  final bool isNew;
}

/// Stacked cards (like Framer's "stacked cards" scroll effect): while the
/// list scrolls, each card sticks near the top of the viewport and the next
/// one slides up over it; a covered card shrinks a little and dims, so the
/// pile reads as a stack rather than a plain list. Needs an enclosing
/// [Scrollable].
class StackedWordCards extends StatefulWidget {
  const StackedWordCards({super.key, required this.words, this.stickyTop = 32});

  final List<CompletionWord> words;

  /// Where the first card sticks, from the top of the viewport.
  final double stickyTop;

  /// How much of each card below stays visible at the top of the pile.
  static const peek = 8.0;
  static const gap = 14.0;

  @override
  State<StackedWordCards> createState() => _StackedWordCardsState();
}

class _StackedWordCardsState extends State<StackedWordCards> {
  final _anchors = <GlobalKey>[];

  @override
  Widget build(BuildContext context) {
    while (_anchors.length < widget.words.length) {
      _anchors.add(GlobalKey());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, word) in widget.words.indexed)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : StackedWordCards.gap),
            child: _StickyCard(
              stickyTop: widget.stickyTop,
              anchor: _anchors[i],
              following: _anchors.skip(i + 1).take(3).toList(),
              child: _WordCard(word: word),
            ),
          ),
      ],
    );
  }
}

class _StickyCard extends StatefulWidget {
  const _StickyCard({
    required this.stickyTop,
    required this.anchor,
    required this.following,
    required this.child,
  });

  final double stickyTop;
  final GlobalKey anchor;
  final List<GlobalKey> following;
  final Widget child;

  @override
  State<_StickyCard> createState() => _StickyCardState();
}

class _StickyCardState extends State<_StickyCard> {
  ScrollPosition? _position;
  bool _pinned = false;

  void _onScroll() {
    final pinned = _shift() > 0;
    if (pinned != _pinned) {
      _pinned = pinned;
      HapticFeedback.selectionClick();
    }
  }

  @override
  void dispose() {
    _position?.removeListener(_onScroll);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _position?.removeListener(_onScroll);
    _position = Scrollable.maybeOf(context)?.position;
    _position?.addListener(_onScroll);
  }

  /// How far the card has to be pushed down to stay at its sticky line,
  /// from its layout (paint transforms don't move layout, so this is
  /// stable while the card itself is translated).
  double _shift() {
    final box = widget.anchor.currentContext?.findRenderObject() as RenderBox?;
    final position = _position;
    if (box == null || !box.hasSize || !box.attached || position == null) {
      return 0;
    }
    final viewport = RenderAbstractViewport.maybeOf(box);
    if (viewport == null) return 0;
    final reveal = viewport.getOffsetToReveal(box, 0).offset;
    final top = reveal - position.pixels;
    return math.max(0, widget.stickyTop - top);
  }

  @override
  Widget build(BuildContext context) {
    final position = _position;
    if (position == null) return widget.child;
    final colors = context.appColors;
    return SizedBox(
      key: widget.anchor,
      child: AnimatedBuilder(
        animation: position,
        builder: (context, child) {
          final shift = _shift();
          // Measure the incoming cards, rather than darkening a card merely
          // because it is pinned. In particular, the final card stays readable.
          var depth = 0.0;
          for (final anchor in widget.following) {
            final box = anchor.currentContext?.findRenderObject() as RenderBox?;
            if (box == null ||
                !box.hasSize ||
                !box.attached ||
                box.size.height <= 0) {
              continue;
            }
            final viewport = RenderAbstractViewport.maybeOf(box);
            if (viewport == null) continue;
            final top =
                viewport.getOffsetToReveal(box, 0).offset - position.pixels;
            depth +=
                ((widget.stickyTop + box.size.height - top) / box.size.height)
                    .clamp(0.0, 1.0);
          }
          final covered = depth.clamp(0.0, 1.0);
          final visibleDepth = depth.clamp(0.0, 2.0);
          return Transform.translate(
            offset: Offset(0, shift - visibleDepth * StackedWordCards.peek),
            child: Transform.scale(
              scale: 1 - 0.025 * visibleDepth,
              alignment: Alignment.topCenter,
              child: Opacity(
                opacity: (3 - depth).clamp(0.0, 1.0),
                child: Stack(
                  children: [
                    child!,
                    if (covered > 0)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: colors.nightPage.withValues(
                                alpha: 0.45 * covered,
                              ),
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}

class _WordCard extends StatelessWidget {
  const _WordCard({required this.word});

  final CompletionWord word;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      container: true,
      label: [
        word.form,
        if (word.translation.isNotEmpty) word.translation,
        if (word.isNew) 'neu',
        if (word.sentence.isNotEmpty) word.sentence,
      ].join(', '),
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 116),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
        decoration: BoxDecoration(
          color: colors.raisedInk,
          borderRadius: BorderRadius.circular(22),
          // A soft shadow upwards separates a card from the one it covers
          // (no outlines, DESIGN.md).
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000)
                  .withValues(alpha: colors.light ? 0.08 : 0.18),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    word.form,
                    style: AppType.editorial(
                      color: colors.textPrimary,
                      size: 24,
                    ),
                  ),
                ),
                if (word.isNew)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.activeTint,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      'Neu',
                      style: AppType.meta(color: colors.active),
                    ),
                  ),
              ],
            ),
            if (word.translation.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                word.translation,
                style: AppType.chrome(
                  size: 17,
                  weight: FontWeight.w600,
                  color: colors.active,
                ),
              ),
            ],
            if (word.sentence.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                word.sentence,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppType.chrome(color: colors.textMuted, height: 1.35),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
