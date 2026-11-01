import 'package:flutter/cupertino.dart';

import '../../../models/news_models.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/press_scale.dart';

/// "Nachrichten" by desk (user request 01.11.2026): every desk with news
/// gets its own heading and a sideways row of its 3 to 6 articles, most
/// important first. Desks without articles are left out.
class NewsDesks extends StatelessWidget {
  const NewsDesks({super.key, required this.articles, required this.onOpen});

  /// Matches the screen gutter; also the gap between two cards.
  static const gutter = 20.0;

  final List<NewsArticle> articles;
  final ValueChanged<NewsArticle> onOpen;

  @override
  Widget build(BuildContext context) {
    final desks = <NewsCategory, List<NewsArticle>>{
      for (final category in NewsCategory.values)
        category: [
          for (final a in articles)
            if (a.category == category) a,
        ],
    }..removeWhere((_, list) => list.isEmpty);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, MapEntry(key: desk, value: list))
            in desks.entries.indexed) ...[
          if (i > 0) const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: gutter),
            child: Semantics(
              header: true,
              child: Text(
                desk.label,
                style: AppType.editorial(
                  color: context.appColors.textPrimary,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: NewsCard.height,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: gutter),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) => NewsCard(
                article: list[index],
                onTap: () => onOpen(list[index]),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// A news card set like a newspaper column: the source site as a small
/// kicker (daily articles only), the serif title, and the reading time. No image: daily articles
/// carry none, and a stock picture would say nothing.
class NewsCard extends StatelessWidget {
  const NewsCard({super.key, required this.article, required this.onTap});

  static const height = 140.0;
  static const width = 264.0;

  final NewsArticle article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final source = article.sources.firstOrNull?.site;
    return MergeSemantics(
      child: PressScale(
        child: CupertinoButton(
          onPressed: onTap,
          padding: EdgeInsets.zero,
          pressedOpacity: 0.85,
          minimumSize: const Size(44, 44),
          child: Semantics(
            label:
                '${article.title}. Nachrichten, ${article.category.label}, '
                '${article.readingMinutes} Minuten Lesezeit, '
                'Niveau ${article.level}'
                '${source == null ? '' : ', Quelle $source'}',
            excludeSemantics: true,
            child: Container(
              width: width,
              height: height,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: colors.raisedInk,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (source != null) ...[
                    Text(
                      source.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.chrome(
                        size: 11,
                        weight: FontWeight.w700,
                        color: colors.newsKicker,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  // Shrinks first at large Dynamic Type; the card keeps
                  // its height.
                  Flexible(
                    child: Text(
                      article.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.editorial(
                        color: colors.textPrimary,
                        size: 20,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${article.readingMinutes} Min.',
                    maxLines: 1,
                    style: AppType.meta(color: colors.textMuted),
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
