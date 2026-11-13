/// External entry points resolve against the current account and content.
enum AppLaunchTarget { home, practice }

class AppLaunchIntent {
  const AppLaunchIntent.home() : target = AppLaunchTarget.home;
  const AppLaunchIntent.practice() : target = AppLaunchTarget.practice;

  final AppLaunchTarget target;
}
