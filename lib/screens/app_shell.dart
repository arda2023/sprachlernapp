import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/home_models.dart';
import '../models/sample_content.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_bar.dart';
import 'home/home_screen.dart';
import 'stories/story_library_screen.dart';
import 'stories/story_reader_screen.dart';

/// Hosts the tab screens under one bottom bar and keeps each tab's scroll
/// position while switching.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  AppTab _tab = AppTab.home;

  void _select(AppTab tab) {
    // TODO: Wortliste and Profil screens don't exist yet.
    if (tab == AppTab.words || tab == AppTab.profile) return;
    setState(() => _tab = tab);
  }

  void _openStory(Story story) => StoryReaderScreen.open(context, story);

  // TODO: route to the mixed practice session once it exists.
  void _startPractice() {}

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.raisedInk,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: IndexedStack(
          index: _tab == AppTab.stories ? 1 : 0,
          children: [
            HomeScreen(
              onOpenStory: _openStory,
              onBrowseStories: () => _select(AppTab.stories),
            ),
            StoryLibraryScreen(
              stories: sampleStories,
              continueReading: sampleContinueReading,
              onOpenStory: _openStory,
            ),
          ],
        ),
        bottomNavigationBar: AppBottomBar(
          current: _tab,
          onTabSelected: _select,
          onStartPractice: _startPractice,
        ),
      ),
    );
  }
}
