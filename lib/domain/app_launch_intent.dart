/// External entry points resolve against the current account and content.
enum AppLaunchTarget { home, practice, story }

class AppLaunchIntent {
  const AppLaunchIntent.home()
    : target = AppLaunchTarget.home,
      storyId = null,
      language = null;
  const AppLaunchIntent.practice()
    : target = AppLaunchTarget.practice,
      storyId = null,
      language = null;
  const AppLaunchIntent.story(this.storyId, this.language)
    : target = AppLaunchTarget.story;

  final AppLaunchTarget target;
  final String? storyId;
  final String? language;
}
