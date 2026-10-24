import 'dart:async';
import 'dart:io';
import 'package:device_translation/device_translation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/data/offline_translation/offline_dictionary.dart';
import 'package:sprachapp/data/runtime_translation_client.dart';
import 'package:sprachapp/presentation/providers/offline_translation_provider.dart';
import 'package:sprachapp/presentation/providers/runtime_translation_provider.dart';
import 'package:sprachapp/widgets/runtime_translation_sheet.dart';

class CountingRemote extends RuntimeTranslationClient {
  CountingRemote() : super('', '', () async => 'synthetic');
  int calls = 0;
  RuntimeTranslation? hit;
  @override
  Future<RuntimeTranslation?> cached({required String lang, required String text,
      String? form, int? start, String? senseRef, String? formRef}) async => hit;
  @override
  Future<RuntimeTranslation> translate({required String lang, required String text,
      String? form, int? start, String? senseRef, String? formRef}) async {
    calls++;
    return const RuntimeTranslation('KI-Ergebnis', 'claude-haiku-5-5', 'test');
  }
}
class TestDictionary extends OfflineDictionary {
  TestDictionary() : super(directory: () async => Directory('unused'), asset: (_) async => throw StateError('unused'));
  int lookups = 0;
  @override
  Future<List<DictionaryCandidate>> lookup(String lang, String form) async {
    lookups++;
    return const [DictionaryCandidate('bank', 'Substantiv', 'Geldinstitut', '', 'https://de.wiktionary.org/wiki/bank', ''),
      DictionaryCandidate('bank', 'Substantiv', 'Ufer', '', 'https://de.wiktionary.org/wiki/bank', '')];
  }
}
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  late CountingRemote remote;
  late TestDictionary dictionary;
  final methods = <String>[];
  setUp(() { remote = CountingRemote(); dictionary = TestDictionary(); methods.clear(); });
  tearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(DeviceTranslation.channel, null));
  Future<void> mount(WidgetTester tester, {String? form, String lang = 'en'}) async {
    await tester.pumpWidget(ProviderScope(overrides: [
      runtimeTranslationProvider.overrideWithValue(remote),
      offlineDictionaryProvider.overrideWithValue(dictionary),
    ], child: MaterialApp(home: Scaffold(body: RuntimeTranslationSheet(lang: lang,
      text: 'The bank is by the bank.', form: form, start: form == null ? null : 19)))));
    await tester.pumpAndSettle();
  }
  testWidgets('exact private hit precedes dictionary; ambiguity stays display-only', (tester) async {
    remote.hit = const RuntimeTranslation('Genauer gespeicherter Kontext', 'claude-haiku-5-5', 'hit');
    await mount(tester, form: 'bank');
    expect(find.text('Genauer gespeicherter Kontext'), findsOneWidget);
    expect(dictionary.lookups, 0); expect(remote.calls, 0);
    await tester.pumpWidget(const SizedBox());
    remote.hit = null;
    await mount(tester, form: 'bank');
    expect(find.text('Geldinstitut'), findsOneWidget); expect(find.text('Ufer'), findsOneWidget);
    expect(find.text('Zum Lernen hinzufügen'), findsNothing);
    expect(remote.calls, 0);
  });
  for (final error in ['missing_model','unsupported','storage','cancelled','download_failed']) {
    testWidgets('local $error never starts Haiku', (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(DeviceTranslation.channel, (call) async {
        methods.add(call.method);
        if (call.method == 'status') return error == 'download_failed' ? 'supported' : 'installed';
        if (call.method == 'cancel') return null;
        throw PlatformException(code: error);
      });
      await mount(tester);
      await tester.tap(find.text(error == 'download_failed' ? 'Sprachmodelle laden' : 'Auf dem Gerät übersetzen'));
      await tester.pumpAndSettle();
      expect(remote.calls, 0);
      expect(find.text('Mit KI übersetzen'), findsOneWidget);
    });
  }
  testWidgets('prepare sends no text; installed model translates with separate provenance', (tester) async {
    bool installed = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(DeviceTranslation.channel, (call) async {
      methods.add(call.method);
      if (call.method == 'status') return installed ? 'installed' : 'supported';
      if (call.method == 'prepare') { expect((call.arguments as Map).containsKey('text'), isFalse); installed = true; return null; }
      if (call.method == 'translate') return 'Die Bank ist am Ufer.';
      return null;
    });
    await mount(tester, lang: 'pt-BR');
    await tester.tap(find.text('Sprachmodelle laden')); await tester.pumpAndSettle();
    expect(methods, isNot(contains('translate')));
    await tester.tap(find.text('Auf dem Gerät übersetzen')); await tester.pumpAndSettle();
    expect(find.text('Die Bank ist am Ufer.'), findsOneWidget);
    expect(find.textContaining('Apple Translation · Vertrag 1'), findsOneWidget);
    expect(remote.calls, 0);
  });
  testWidgets('cancel discards late result and does not use online fallback', (tester) async {
    final pending = Completer<String>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(DeviceTranslation.channel, (call) async {
      methods.add(call.method);
      if (call.method == 'status') return 'installed';
      if (call.method == 'translate') return pending.future;
      return null;
    });
    await mount(tester);
    await tester.tap(find.text('Auf dem Gerät übersetzen')); await tester.pump();
    await tester.tap(find.text('Abbrechen')); await tester.pump();
    pending.complete('Late private result'); await tester.pumpAndSettle();
    expect(find.text('Late private result'), findsNothing);
    expect(methods, contains('cancel')); expect(remote.calls, 0);
  });
  test('unsupported host is a normal state', () async {
    expect(await DeviceTranslation().status('en'), DeviceModelState.unsupported);
    expect(await DeviceTranslation().status('fr'), DeviceModelState.unsupported);
  });
}
