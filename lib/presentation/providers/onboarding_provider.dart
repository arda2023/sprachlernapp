import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'reading_providers.dart';

/// Where "onboarding finished" is kept (`<support>/ui/onboarding.json` in the
/// app). `null` skips the onboarding: tests and previews start in the app.
final onboardingStoreProvider = Provider<JsonStore?>((ref) => null);

/// Whether the learner has finished the onboarding. UI state only; the
/// learning goal itself goes to the preferences.
class OnboardingNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final store = ref.watch(onboardingStoreProvider);
    if (store == null) return true;
    final json = await store.read();
    return json is Map && json['done'] == true;
  }

  /// [interest] is the story topic picked on the second page.
  Future<void> complete({String? interest}) async {
    state = const AsyncData(true);
    try {
      await ref.read(onboardingStoreProvider)?.write({
        'done': true,
        'interest': ?interest,
      });
    } catch (error) {
      ref.read(uiStorageErrorProvider.notifier).state = error.toString();
    }
  }
}

final onboardingProvider = AsyncNotifierProvider<OnboardingNotifier, bool>(
  OnboardingNotifier.new,
);
