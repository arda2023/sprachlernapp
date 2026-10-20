import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;
import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/presentation/providers/reading_providers.dart';

class DelayedStore implements JsonStore {
  final loaded = Completer<Object?>();
  Object? saved;
  @override
  Future<Object?> read() => loaded.future;
  @override
  Future<void> write(Object? json) async => saved = json;
}

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  test(
    'a reading update before loading retains previously saved stories',
    () async {
      final store = DelayedStore();
      final c = ProviderContainer(
        overrides: [readingStoreProvider.overrideWithValue(store)],
      );
      addTearDown(c.dispose);
      c.read(readingProgressProvider.notifier).report('new', .4);
      expect(store.saved, isNull);
      store.loaded.complete({
        'old': ReadingEntry(fraction: .8, updatedAt: DateTime(2026)).toJson(),
      });
      await settle();
      expect((store.saved as Map).keys, containsAll(['old', 'new']));
      expect(c.read(readingProgressProvider)['old']!.fraction, .8);
    },
  );

  test(
    'a finished story stays finished when its position changes during loading',
    () async {
      final store = DelayedStore();
      final c = ProviderContainer(
        overrides: [readingStoreProvider.overrideWithValue(store)],
      );
      addTearDown(c.dispose);
      c.read(readingProgressProvider.notifier).report('same', .3);
      store.loaded.complete({
        'same': ReadingEntry(
          fraction: 1,
          finished: true,
          updatedAt: DateTime(2026),
        ).toJson(),
      });
      await settle();
      expect(c.read(readingProgressProvider)['same']!.fraction, .3);
      expect(c.read(readingProgressProvider)['same']!.finished, isTrue);
      expect((store.saved as Map)['same']['finished'], isTrue);
    },
  );

  test(
    'imports added or deleted during loading survive the delayed read',
    () async {
      final store = DelayedStore();
      final c = ProviderContainer(
        overrides: [importStoreProvider.overrideWithValue(store)],
      );
      addTearDown(c.dispose);
      final n = c.read(importedTextsProvider.notifier);
      final added = n.add('A new text.');
      n.remove('deleted');
      final old = ImportedText(
        id: 'old',
        title: 'old',
        body: 'Old text.',
        source: ImportSource.pasted,
        createdAt: DateTime(2026),
      );
      store.loaded.complete([
        old.toJson(),
        {...old.toJson(), 'id': 'deleted'},
      ]);
      await settle();
      expect(c.read(importedTextsProvider).map((t) => t.id), [added.id, 'old']);
      expect((store.saved as List).map((t) => (t as Map)['id']), [
        added.id,
        'old',
      ]);
    },
  );

  test(
    'a late previous-language read cannot overwrite the new language',
    () async {
      final english = DelayedStore(), portuguese = MemoryJsonStore();
      final language = StateProvider((ref) => 'en');
      final c = ProviderContainer(
        overrides: [
          readingStoreProvider.overrideWith(
            (ref) => ref.watch(language) == 'en' ? english : portuguese,
          ),
        ],
      );
      addTearDown(c.dispose);
      c.read(readingProgressProvider.notifier).report('shared-id', .7);
      c.read(language.notifier).state = 'pt-BR';
      c.read(readingProgressProvider.notifier).report('shared-id', .2);
      english.loaded.complete({
        'shared-id': ReadingEntry(
          fraction: .9,
          updatedAt: DateTime(2026),
        ).toJson(),
      });
      await settle();
      expect(c.read(readingProgressProvider)['shared-id']!.fraction, .2);
      expect(((await portuguese.read()) as Map)['shared-id']['fraction'], .2);
    },
  );
}
