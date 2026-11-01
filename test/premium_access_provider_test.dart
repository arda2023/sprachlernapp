import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/domain/content_access_policy.dart';
import 'package:sprachapp/presentation/providers/content_access_provider.dart';
import 'package:sprachapp/presentation/providers/database_providers.dart';
import 'package:sprachapp/presentation/providers/deck_providers.dart';
import 'package:sprachapp/presentation/providers/premium_access_provider.dart';

import 'fixtures/deck_repositories.dart';

void main() {
  for (final decision in ContentAccessDecision.values) {
    test('premium content derives $decision without granting unknown access', () {
      final scope = ProviderContainer(overrides: [
        contentAccessProvider.overrideWithValue(decision),
      ]);
      addTearDown(scope.dispose);
      expect(scope.read(premiumContentAccessProvider),
          decision == ContentAccessDecision.allowed);
    });
  }

  test('free activation cannot persist a paid deck but can deactivate it', () async {
    final user = TestUser();
    final scope = ProviderContainer(overrides: [
      premiumContentAccessProvider.overrideWithValue(false),
      userRepositoryProvider.overrideWith((_) => user),
      selectedContentLanguageProvider.overrideWith((_) async => 'en'),
      clockProvider.overrideWithValue(() => testNow),
    ]);
    addTearDown(() async { scope.dispose(); await user.close(); });
    await scope.read(selectedContentLanguageProvider.future);
    final controller = scope.read(deckActiveControllerProvider.notifier);
    await controller.setActive('paid-deck', true);
    expect(user.active['paid-deck'], isNot(true));
    expect(scope.read(deckActiveControllerProvider).errors['paid-deck'], isA<StateError>());
    await controller.setActive('4630a4856f603afdad2f24776298c19a', true);
    expect(user.active['4630a4856f603afdad2f24776298c19a'], isTrue);
    user.active['paid-deck'] = true;
    await controller.setActive('paid-deck', false);
    expect(user.active['paid-deck'], isFalse);
  });
}
