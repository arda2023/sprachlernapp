import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/home_models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_bottom_bar.dart';
import 'widgets/deck_tile.dart';
import 'widgets/home_header.dart';
import 'widgets/story_carousel.dart';
import 'widgets/vocab_progress.dart';

// Placeholder content until real user data and stories exist.
const _sampleStats = VocabStats(activated: 400, mastered: 180, total: 3000);

const _sampleDecks = [
  Deck(name: 'Reisen & Unterwegs', masteredFraction: 0.42),
  Deck(name: 'Alltägliche Konversation', masteredFraction: 0.17),
];

const _sampleStories = [
  Story(title: 'El último tren a Sevilla', topic: 'Reisen', difficulty: 1),
  Story(title: 'La receta de mi abuela', topic: 'Küche', difficulty: 2),
  Story(title: 'Una noche en urgencias', topic: 'Medizin', difficulty: 3),
  Story(title: 'El mercado de los sábados', topic: 'Alltag', difficulty: 1),
  Story(title: 'Cartas desde Buenos Aires', topic: 'Kultur', difficulty: 2),
];

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _gutter = EdgeInsets.symmetric(horizontal: 20);

  // TODO: route to deck, story, practice and tab screens once they exist.
  void _notYetRouted() {}

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.raisedInk,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: ListView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.only(top: 8, bottom: 32),
            children: [
              const Padding(
                padding: _gutter,
                child: HomeHeader(levelLabel: 'Spanisch A2', streakDays: 14),
              ),
              const SizedBox(height: 28),
              const Padding(
                padding: _gutter,
                child: VocabProgress(stats: _sampleStats),
              ),
              const SizedBox(height: 44),
              const Padding(
                padding: _gutter,
                child: _SectionHeading(title: 'Aktive Stapel'),
              ),
              const SizedBox(height: 14),
              for (final (i, deck) in _sampleDecks.indexed)
                Padding(
                  padding: _gutter.copyWith(top: i == 0 ? 0 : 12),
                  child: DeckTile(deck: deck, onTap: _notYetRouted),
                ),
              const SizedBox(height: 44),
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 8),
                child: _SectionHeading(
                  title: 'Stories',
                  trailing: CupertinoButton(
                    onPressed: _notYetRouted,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: const Size(44, 44),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Mehr entdecken',
                          style: AppType.chrome(
                            size: 15,
                            weight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          CupertinoIcons.chevron_right,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              StoryCarousel(
                stories: _sampleStories,
                onOpen: (_) => _notYetRouted(),
              ),
            ],
          ),
        ),
        bottomNavigationBar: AppBottomBar(
          current: AppTab.home,
          onTabSelected: (_) => _notYetRouted(),
          onStartPractice: _notYetRouted,
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(title, style: AppType.editorial(size: 24)),
          ),
        ),
        ?trailing,
      ],
    );
  }
}
