import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/domain/app_launch_intent.dart';
import 'package:sprachapp/domain/widget_snapshot.dart';
import 'package:sprachapp/presentation/providers/app_launch_intent_provider.dart';
import 'package:sprachapp/presentation/providers/auth_providers.dart';
import 'package:sprachapp/presentation/providers/database_providers.dart';
import 'package:sprachapp/presentation/providers/widget_provider.dart';

import 'widget_snapshot_test.dart' show FakeWidgetGateway, snapshot;

Future<void> flush() async {
  for (var i = 0; i < 8; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'logout clears a prior account while a new projection is still loading',
    () async {
      final gateway = LaunchGateway();
      final sessions = StreamController<AccountSession?>.broadcast();
      final delayed = Completer<LearningWidgetSnapshot>();
      final container = ProviderContainer(
        overrides: [
          widgetGatewayProvider.overrideWithValue(gateway),
          selectedContentLanguageProvider.overrideWith((ref) async => 'en'),
          accountSessionProvider.overrideWith((ref) => sessions.stream),
          learningWidgetSnapshotProvider.overrideWith((ref) async {
            final account = ref.watch(accountSessionProvider).value;
            if (account?.id == 'a') return delayed.future;
            return const LearningWidgetSnapshot.empty();
          }),
        ],
      );
      final subscription = container.listen(widgetSyncProvider, (_, _) {});
      await flush();
      sessions.add((id: 'a', email: null));
      await flush();
      sessions.add(null);
      await flush();
      delayed.complete(snapshot());
      await flush();
      expect(gateway.writes.last.json['available'], isFalse);
      expect(
        gateway.writes.any((value) => value.json['available'] == true),
        isFalse,
      );
      subscription.close();
      container.dispose();
      await sessions.close();
      await gateway.links.close();
    },
  );

  test(
    'cold and live callbacks for the same widget tap publish once',
    () async {
      final gateway = LaunchGateway()
        ..cold = Uri.parse('linglossa://practice?homeWidget=1');
      final container = ProviderContainer(
        overrides: [
          widgetGatewayProvider.overrideWithValue(gateway),
          accountSessionProvider.overrideWith((ref) => Stream.value(null)),
          selectedContentLanguageProvider.overrideWith((ref) async => 'en'),
          learningWidgetSnapshotProvider.overrideWith(
            (ref) async => const LearningWidgetSnapshot.empty(),
          ),
        ],
      );
      final subscription = container.listen(widgetSyncProvider, (_, _) {});
      await flush();
      final first = container.read(appLaunchIntentProvider)!;
      expect(first.intent.target, AppLaunchTarget.practice);
      gateway.links.add(gateway.cold);
      await flush();
      expect(container.read(appLaunchIntentProvider), same(first));
      subscription.close();
      container.dispose();
      await gateway.links.close();
    },
  );
}

class LaunchGateway extends FakeWidgetGateway {
  final links = StreamController<Uri?>.broadcast();
  Uri? cold;
  @override
  Stream<Uri?> get launches => links.stream;
  @override
  Future<Uri?> initialLaunch() async => cold;
}
