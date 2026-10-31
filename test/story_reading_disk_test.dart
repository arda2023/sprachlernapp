import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/presentation/providers/reading_providers.dart';

class ObservedDiskStore implements JsonStore {
  ObservedDiskStore(String name) : disk = FileJsonStore(name);
  final FileJsonStore disk;
  final saved = Completer<void>();

  @override
  Future<Object?> read() => disk.read();

  @override
  Future<void> write(Object? value) async {
    await disk.write(value);
    if (!saved.isCompleted) saved.complete();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('reading progress survives new store and provider instances on disk', () async {
    final directory = await Directory.systemTemp.createTemp('story_reading_');
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getApplicationSupportDirectory') return directory.path;
      throw UnsupportedError(call.method);
    });
    addTearDown(() async {
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      await directory.delete(recursive: true);
    });

    final store = ObservedDiskStore('reading_progress_en');
    final first = ProviderContainer(overrides: [
      readingStoreProvider.overrideWithValue(store),
    ]);
    first.read(readingProgressProvider.notifier).report('travel_01', 0.43);
    await store.saved.future.timeout(const Duration(seconds: 5));
    first.dispose();

    expect(await File('${directory.path}/ui/reading_progress_en.json').exists(), isTrue);
    final reopened = FileJsonStore('reading_progress_en');
    final diskData = await reopened.read() as Map;
    expect(diskData['travel_01']['fraction'], 0.43);
    expect(await FileJsonStore('reading_progress_it').read(), isNull);

    final second = ProviderContainer(overrides: [
      readingStoreProvider.overrideWithValue(reopened),
    ]);
    addTearDown(second.dispose);
    second.read(readingProgressProvider);
    for (var i = 0; i < 100 && second.read(readingProgressProvider).isEmpty; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(second.read(readingProgressProvider)['travel_01']!.fraction, 0.43);
    expect(second.read(readingProgressProvider)['travel_01']!.inProgress, isTrue);
  });
}
