import 'package:flutter/cupertino.dart';

import '../../../models/news_models.dart';
import '../../../theme/app_theme.dart';
import '../../home/widgets/story_carousel.dart';

/// "Nachrichten": one large card per desk, paged without end in both
/// directions. The focused card's left edge sits on the 20pt screen gutter
/// and the next card peeks in from the right.
class NewsCarousel extends StatefulWidget {
  const NewsCarousel({super.key, required this.articles, required this.onOpen});

  static const viewportFraction = 0.9;

  /// Matches the screen gutter; also the gap between two cards.
  static const gutter = 20.0;

  /// Far enough from 0 that nobody swipes back to the start.
  static const _loops = 1000;

  final List<NewsArticle> articles;
  final ValueChanged<NewsArticle> onOpen;

  @override
  State<NewsCarousel> createState() => _NewsCarouselState();
}

class _NewsCarouselState extends State<NewsCarousel> {
  // Starts on a multiple of the article count, so the first desk shows
  // first; the page index wraps with modulo.
  late final _pages = PageController(
    viewportFraction: NewsCarousel.viewportFraction,
    initialPage: NewsCarousel._loops * widget.articles.length,
  );

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final articles = widget.articles;
    if (articles.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: NewsCard.height,
      child: PageView.builder(
        controller: _pages,
        // The focused page starts at the screen edge; each card brings its
        // own gutter on the left.
        padEnds: false,
        physics: const BouncingScrollPhysics(),
        // No itemCount: endless in both directions.
        itemBuilder: (context, page) {
          final i = page % articles.length;
          return Padding(
            padding: const EdgeInsets.only(left: NewsCarousel.gutter),
            child: NewsCard(
              article: articles[i],
              tone: i,
              onTap: () => widget.onOpen(articles[i]),
            ),
          );
        },
      ),
    );
  }
}

/// A news card: the article image on the top 60%, then on Raised Ink the
/// title, the category kicker in Newsprint Sand right under it, and under
/// that the level and reading time.
class NewsCard extends StatelessWidget {
  const NewsCard({
    super.key,
    required this.article,
    required this.onTap,
    this.tone = 0,
  });

  static const height = 340.0;
  static const imageShare = 0.6;

  final NewsArticle article;
  final VoidCallback onTap;

  /// Picks a neutral cover tone when the article has no image.
  final int tone;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);
    return MergeSemantics(
      child: CupertinoButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        pressedOpacity: 0.7,
        minimumSize: const Size(44, 44),
        child: Semantics(
          label:
              '${article.title}. Nachrichten, ${article.category.label}, '
              '${article.readingMinutes} Minuten Lesezeit, '
              'Niveau ${article.level}',
          excludeSemantics: true,
          child: Container(
            height: height,
            foregroundDecoration: BoxDecoration(
              border: Border.all(color: AppColors.hairline),
              borderRadius: radius,
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: height * imageShare,
                    child: switch (article.cover) {
                      final cover? => Image(image: cover, fit: BoxFit.cover),
                      null => TypeCover(
                        topic: article.category.label,
                        tone: tone,
                        size: 96,
                      ),
                    },
                  ),
                  Container(height: 1, color: AppColors.hairline),
                  Expanded(
                    child: ColoredBox(
                      color: AppColors.raisedInk,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Shrinks first at large Dynamic Type; the
                            // card keeps its height.
                            Flexible(
                              child: Text(
                                article.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppType.editorial(size: 22),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              article.category.kicker,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppType.chrome(
                                size: 13,
                                weight: FontWeight.w700,
                                color: AppColors.newsKicker,
                              ).copyWith(letterSpacing: 1.2),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${article.level} · '
                              '${article.readingMinutes} Min',
                              maxLines: 1,
                              style: AppType.meta(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
