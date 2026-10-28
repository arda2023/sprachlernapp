import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/data/offline_translation/offline_dictionary.dart';
import 'package:sprachapp/data/runtime_translation_client.dart';
import 'package:sprachapp/presentation/providers/offline_translation_provider.dart';
import 'package:sprachapp/presentation/providers/runtime_translation_provider.dart';
import 'package:sprachapp/widgets/runtime_translation_sheet.dart';
import 'package:sprachapp/widgets/word_cloud_consent.dart';

class CountingRemote extends RuntimeTranslationClient {
  CountingRemote() : super('', '', () async => 'synthetic');
  int calls = 0;
  WordCloudConsent consent = WordCloudConsent.enabled;
  RuntimeTranslation? hit;
  bool cacheBroken = false;
  Completer<RuntimeTranslation>? pending;
  String? failure;
  @override
  Future<WordCloudConsent> wordCloudConsent() async => consent;
  @override
  Future<void> setWordCloudConsent(bool enabled) async {
    consent = enabled ? WordCloudConsent.enabled : WordCloudConsent.disabled;
  }

  @override
  Future<RuntimeTranslation?> cached({
    required String lang,
    required String text,
    String? form,
    int? start,
    String? senseRef,
    String? formRef,
  }) async {
    if (cacheBroken) throw StateError('synthetic storage failure');
    return hit;
  }

  @override
  Future<RuntimeTranslation> translateWordOnTap({
    required String lang,
    required String text,
    required String form,
    int? start,
    String? senseRef,
    String? formRef,
  }) => translate(lang: lang, text: text, form: form);
  @override
  Future<RuntimeTranslation> translate({
    required String lang,
    required String text,
    String? form,
    int? start,
    String? senseRef,
    String? formRef,
    Future<void> Function()? authorize,
  }) async {
    await authorize?.call();
    calls++;
    if (failure != null) throw TranslationFailure(failure!);
    return pending?.future ??
        const RuntimeTranslation('kommt an', 'claude-haiku-5-5', 'synthetic');
  }
}

class TestDictionary extends OfflineDictionary {
  TestDictionary()
    : super(
        directory: () async => Directory('unused'),
        asset: (_) async => throw StateError('unused'),
      );
  int lookups = 0;
  bool broken = false;
  List<DictionaryCandidate> values = const [];
  @override
  Future<List<DictionaryCandidate>> lookup(String lang, String form) async {
    lookups++;
    if (broken) throw StateError('synthetic database failure');
    return values;
  }
}

const cat = DictionaryCandidate(
  'cat',
  'Substantiv',
  'Katze',
  '',
  'https://de.wiktionary.org/wiki/cat',
  '',
);
const ambiguous = [
  DictionaryCandidate('bank', 'Substantiv', 'Bank', '', '', ''),
  DictionaryCandidate('bank', 'Substantiv', 'Ufer', '', '', ''),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  late CountingRemote remote;
  late TestDictionary dictionary;
  setUp(() {
    remote = CountingRemote();
    dictionary = TestDictionary();
  });
  Future<void> mount(
    WidgetTester tester, {
    String? form = 'bank',
    String text = 'The bank.',
    bool tap = true,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          runtimeTranslationProvider.overrideWithValue(remote),
          offlineDictionaryProvider.overrideWithValue(dictionary),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: RuntimeTranslationSheet(
              lang: 'en',
              text: text,
              form: form,
              wordTap: tap,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'settings activation requires disclosure; disabling makes no request',
    (tester) async {
      remote.consent = WordCloudConsent.unknown;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [runtimeTranslationProvider.overrideWithValue(remote)],
          child: const MaterialApp(
            home: Scaffold(body: WordCloudConsentTile()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(find.textContaining('vollständige Satzkontext'), findsOneWidget);
      expect(remote.consent, WordCloudConsent.unknown);
      await tester.tap(find.text('Aktivieren'));
      await tester.pumpAndSettle();
      expect(remote.consent, WordCloudConsent.enabled);
      expect(remote.calls, 0);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(remote.consent, WordCloudConsent.disabled);
      expect(remote.calls, 0);
    },
  );
  testWidgets('exact cache beats dictionary and consent, no download UI', (
    tester,
  ) async {
    remote.hit = const RuntimeTranslation(
      'Genauer Kontext',
      'claude-haiku-5-5',
      'hit',
    );
    remote.consent = WordCloudConsent.disabled;
    dictionary.broken = true;
    await mount(tester);
    expect(find.text('Genauer Kontext'), findsOneWidget);
    expect(dictionary.lookups, 0);
    expect(remote.calls, 0);
    expect(find.textContaining('Sprachmodell'), findsNothing);
    expect(find.text('Auf dem Gerät übersetzen'), findsNothing);
  });
  testWidgets('single dictionary meaning stays offline and sources reachable', (
    tester,
  ) async {
    dictionary.values = [cat, cat];
    await mount(tester, form: 'cat', text: 'The cat.');
    expect(find.text('Katze'), findsOneWidget);
    expect(remote.calls, 0);
    expect(find.text('Wörterbuch · allgemeine Bedeutung'), findsOneWidget);
    await tester.tap(find.text('Wörterbuch · Quellen & Lizenz'));
    await tester.pumpAndSettle();
    expect(find.byType(SelectableText), findsOneWidget);
    expect(
      tester.widget<SelectableText>(find.byType(SelectableText)).data,
      contains('CC BY-SA 4.0'),
    );
  });
  for (final context in ['I work at the bank.', 'I walk by the bank.']) {
    testWidgets('ambiguous bank invokes one automatic request: $context', (
      tester,
    ) async {
      dictionary.values = ambiguous;
      await mount(tester, text: context);
      expect(remote.calls, 1);
      expect(find.text('Bank'), findsNothing);
      expect(find.text('Ufer'), findsNothing);
      expect(find.text('Im Kontext übersetzen'), findsNothing);
      expect(find.text('Mit KI übersetzen'), findsNothing);
      expect(find.text('kommt an'), findsOneWidget);
      await tester.pump(const Duration(seconds: 30));
      expect(remote.calls, 1);
    });
  }
  for (final consent in [WordCloudConsent.unknown, WordCloudConsent.disabled]) {
    testWidgets('no automatic upload for $consent', (tester) async {
      remote.consent = consent;
      await mount(tester);
      expect(remote.calls, 0);
      if (consent == WordCloudConsent.unknown) {
        expect(find.textContaining('vollständige Satzkontext'), findsOneWidget);
        await tester.tap(find.text('Aktivieren'));
        await tester.pumpAndSettle();
        expect(remote.calls, 1);
        expect(remote.consent, WordCloudConsent.enabled);
      } else {
        expect(find.text('Aktivieren'), findsNothing);
      }
    });
  }
  testWidgets('declining is saved without request', (tester) async {
    remote.consent = WordCloudConsent.unknown;
    await mount(tester);
    await tester.tap(find.text('Nicht jetzt'));
    await tester.pumpAndSettle();
    expect(remote.consent, WordCloudConsent.disabled);
    expect(remote.calls, 0);
  });
  testWidgets('mounting without word tap cannot start cloud', (tester) async {
    await mount(tester, tap: false);
    expect(remote.calls, 0);
  });
  for (final cacheFailure in [true, false]) {
    testWidgets(
      'technical ${cacheFailure ? 'cache' : 'dictionary'} failure is not a miss',
      (tester) async {
        remote.cacheBroken = cacheFailure;
        dictionary.broken = !cacheFailure;
        await mount(tester);
        expect(remote.calls, 0);
        expect(find.textContaining('Keine Onlineanfrage'), findsOneWidget);
      },
    );
  }
  for (final failure in [
    'Offline: Bitte verbinden.',
    'Übersetzungslimit erreicht.',
    'Übersetzung derzeit nicht verfügbar.',
  ]) {
    testWidgets('$failure never retries', (tester) async {
      remote.failure = failure;
      await mount(tester);
      expect(find.text(failure), findsOneWidget);
      expect(remote.calls, 1);
      await tester.pump(const Duration(minutes: 1));
      expect(remote.calls, 1);
    });
  }
  testWidgets(
    'sentence still requires explicit Translate action; cache does not',
    (tester) async {
      await mount(tester, form: null);
      expect(remote.calls, 0);
      expect(dictionary.lookups, 0);
      await tester.tap(find.text('Übersetzen'));
      await tester.pumpAndSettle();
      expect(remote.calls, 1);
    },
  );
  testWidgets('selection replacement cannot show stale result', (tester) async {
    final pending = Completer<RuntimeTranslation>();
    remote.pending = pending;
    final selection = ValueNotifier('bank');
    addTearDown(selection.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          runtimeTranslationProvider.overrideWithValue(remote),
          offlineDictionaryProvider.overrideWithValue(dictionary),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<String>(
              valueListenable: selection,
              builder: (_, form, _) => RuntimeTranslationSheet(
                lang: 'en',
                text: 'bank cat',
                form: form,
                start: form == 'bank' ? 0 : 5,
                wordTap: true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(remote.calls, 1);
    dictionary.values = [cat];
    selection.value = 'cat';
    await tester.pumpAndSettle();
    expect(find.text('Katze'), findsOneWidget);
    pending.complete(
      const RuntimeTranslation(
        'Falsches altes Ergebnis',
        'claude-haiku-5-5',
        'old',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Falsches altes Ergebnis'), findsNothing);
    expect(find.text('Katze'), findsOneWidget);
    expect(find.byType(CupertinoActivityIndicator), findsNothing);
  });
}
