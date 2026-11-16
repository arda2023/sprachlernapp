import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/presentation/providers/onboarding_provider.dart';
import 'package:sprachapp/presentation/providers/reading_providers.dart';

const _draft = <String, Object?>{
  'page': 4,
  'interest': 'travel',
  'dailyGoal': 15,
  'aiTranslations': false,
  'practiced': true,
};

ProviderContainer _open(JsonStore store) => ProviderContainer(
  overrides: [onboardingStoreProvider.overrideWithValue(store)],
);

class _GatedStore implements JsonStore {
  final writeStarted = Completer<void>();
  final allowFirstWrite = Completer<void>();
  final entries = <Object?>[];

  @override
  Future<Object?> read() async => entries.lastOrNull;

  @override
  Future<void> write(Object? json) async {
    if (entries.isEmpty && !writeStarted.isCompleted) {
      writeStarted.complete();
      await allowFirstWrite.future;
    }
    entries.add(json);
  }
}

void main() {
  test(
    'an unfinished draft restores the exact plan and saved practice state',
    () async {
      final store = MemoryJsonStore();
      final first = _open(store);
      addTearDown(first.dispose);
      expect(await first.read(onboardingProvider.future), isFalse);
      final notifier = first.read(onboardingProvider.notifier);
      expect(await notifier.readDraft(), isNull);
      await notifier.saveDraft(_draft);

      final resumed = _open(store);
      addTearDown(resumed.dispose);
      expect(await resumed.read(onboardingProvider.future), isFalse);
      expect(
        await resumed.read(onboardingProvider.notifier).readDraft(),
        _draft,
      );
    },
  );

  test(
    'completion is persisted after a pending draft and ignores late drafts',
    () async {
      final store = _GatedStore();
      final container = _open(store);
      addTearDown(container.dispose);
      await container.read(onboardingProvider.future);
      final notifier = container.read(onboardingProvider.notifier);

      final pending = notifier.saveDraft(_draft);
      await store.writeStarted.future;
      final complete = notifier.complete(interest: 'Reisen');
      expect(container.read(onboardingProvider).asData?.value, isTrue);
      await notifier.saveDraft({..._draft, 'page': 0});
      expect(store.entries, isEmpty);

      store.allowFirstWrite.complete();
      await Future.wait([pending, complete]);
      expect(store.entries, [
        {'done': false, 'draft': _draft},
        {'done': true, 'interest': 'Reisen'},
      ]);
      expect(await notifier.readDraft(), isNull);

      final resumed = _open(store);
      addTearDown(resumed.dispose);
      expect(await resumed.read(onboardingProvider.future), isTrue);
      expect(
        await resumed.read(onboardingProvider.notifier).readDraft(),
        isNull,
      );
    },
  );

  test(
    'malformed and completed payloads cannot restore an unfinished draft',
    () async {
      final store = MemoryJsonStore();
      for (final invalid in [
        ['not a document'],
        {'done': false, 'draft': 4},
        {'done': true, 'draft': _draft},
      ]) {
        await store.write(invalid);
        final container = _open(store);
        try {
          expect(
            await container.read(onboardingProvider.notifier).readDraft(),
            isNull,
          );
        } finally {
          container.dispose();
        }
      }
    },
  );
}
