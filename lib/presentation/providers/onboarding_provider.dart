import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'reading_providers.dart';

/// Where "onboarding finished" is kept (`<support>/ui/onboarding.json` in the
/// app). `null` skips the onboarding: tests and previews start in the app.
final onboardingStoreProvider = Provider<JsonStore?>((ref) => null);

/// Whether the learner has finished the onboarding. UI state only; the
/// learning goal itself goes to the preferences.
class OnboardingNotifier extends AsyncNotifier<bool> {
  Future<void> _writes = Future.value();

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
    await _write({'done': true, 'interest': ?interest});
  }

  Future<Map<String, Object?>?> readDraft() async {
    final json = await ref.read(onboardingStoreProvider)?.read();
    if (json is! Map || json['done'] == true || json['draft'] is! Map) {
      return null;
    }
    return Map<String, Object?>.from(json['draft'] as Map);
  }

  Future<void> saveDraft(Map<String, Object?> draft) async {
    if (state.asData?.value == true) return;
    await _write({'done': false, 'draft': draft});
  }

  Future<void> _write(Map<String, Object?> json) async {
    final store = ref.read(onboardingStoreProvider);
    final write = _writes.then<void>((_) async {
      await store?.write(json);
    });
    _writes = write.catchError((Object _) {});
    try {
      await write;
    } catch (error) {
      if (ref.mounted) {
        ref.read(uiStorageErrorProvider.notifier).state = error.toString();
      }
    }
  }
}

final onboardingProvider = AsyncNotifierProvider<OnboardingNotifier, bool>(
  OnboardingNotifier.new,
);
