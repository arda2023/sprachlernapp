import 'language_profile.dart';
import 'app_launch_intent.dart';

/// Reject unrelated auth URLs and malformed destinations before navigation.
AppLaunchIntent? appLaunchIntentFromWidget(Uri uri) {
  if (uri.scheme != 'linglossa' ||
      uri.userInfo.isNotEmpty ||
      uri.hasPort ||
      uri.path.isNotEmpty ||
      uri.fragment.isNotEmpty ||
      uri.queryParameters['homeWidget'] != '1') {
    return null;
  }
  switch (uri.host) {
    case 'home':
      return const AppLaunchIntent.home();
    case 'practice':
      return const AppLaunchIntent.practice();
    case 'story':
      final id = uri.queryParameters['id'];
      final language = uri.queryParameters['language'];
      if (id == null ||
          id.isEmpty ||
          id.length > 256 ||
          id.startsWith('import-') ||
          ContentLanguageProfile.forLanguage(language ?? '') == null) {
        return const AppLaunchIntent.home();
      }
      return AppLaunchIntent.story(id, language!);
    default:
      return const AppLaunchIntent.home();
  }
}
