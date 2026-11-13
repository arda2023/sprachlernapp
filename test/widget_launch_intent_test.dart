import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/domain/app_launch_intent.dart';
import 'package:sprachapp/domain/widget_launch_intent.dart';

void main() {
  test('routes only explicitly marked widget URLs', () {
    expect(
      appLaunchIntentFromWidget(Uri.parse('linglossa://practice?homeWidget=1'))
          ?.target,
      AppLaunchTarget.practice,
    );
    expect(
      appLaunchIntentFromWidget(Uri.parse('linglossa://home?homeWidget=1'))
          ?.target,
      AppLaunchTarget.home,
    );
    for (final url in [
      'https://practice?homeWidget=1',
      'linglossa://login-callback?code=secret',
      'linglossa://practice',
      'linglossa://practice/path?homeWidget=1',
      'linglossa://user@practice?homeWidget=1',
      'linglossa://practice:80?homeWidget=1',
    ]) {
      expect(appLaunchIntentFromWidget(Uri.parse(url)), isNull);
    }
  });
  test(
    'preserves encoded editorial IDs and falls back for invalid stories',
    () {
      final intent = appLaunchIntentFromWidget(
        Uri.parse(
          'linglossa://story?homeWidget=1&id=library%3Apt-BR%3Atravel_01&language=pt-BR',
        ),
      )!;
      expect(intent.target, AppLaunchTarget.story);
      expect(intent.storyId, 'library:pt-BR:travel_01');
      expect(intent.language, 'pt-BR');
      for (final query in [
        'id=import-private&language=en',
        'id=&language=en',
        'id=story&language=unknown',
      ]) {
        expect(
          appLaunchIntentFromWidget(
            Uri.parse('linglossa://story?homeWidget=1&$query'),
          )?.target,
          AppLaunchTarget.home,
        );
      }
    },
  );
}
