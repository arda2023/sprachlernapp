import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/data/offline_translation/offline_dictionary.dart';
import 'package:sprachapp/data/runtime_translation_client.dart';
import 'package:sprachapp/presentation/providers/offline_translation_provider.dart';
import 'package:sprachapp/presentation/providers/runtime_translation_provider.dart';
import 'package:sprachapp/widgets/light_sweep.dart';
import 'package:sprachapp/widgets/runtime_translation_sheet.dart';
import 'package:sprachapp/widgets/translation_paywall_card.dart';
import 'package:sprachapp/widgets/word_bubble.dart';

/// The server reports the five free translations as used up.
class _UsedUpRemote extends RuntimeTranslationClient {
  _UsedUpRemote() : super('', '', () async => 'synthetic');
  int calls = 0;

  @override
  Future<WordCloudConsent> wordCloudConsent() async => WordCloudConsent.enabled;

  @override
  Future<RuntimeTranslation?> cached({
    required String lang,
    required String text,
    String? form,
    int? start,
    String? senseRef,
    String? formRef,
  }) async => null;

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
    calls++;
    throw const TranslationFailure(
      'Die fünf kostenlosen KI-Übersetzungen sind aufgebraucht.',
      freeQuotaUsedUp: true,
    );
  }
}

class _EmptyDictionary extends OfflineDictionary {
  _EmptyDictionary()
    : super(
        directory: () async => Directory('unused'),
        asset: (_) async => throw StateError('unused'),
      );

  @override
  Future<List<DictionaryCandidate>> lookup(String lang, String form) async =>
      const [];
}

const _sentence = 'A destroyed cash machine leaves a hole in a bank wall.';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  late _UsedUpRemote remote;
  setUp(() => remote = _UsedUpRemote());

  Future<void> host(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          runtimeTranslationProvider.overrideWithValue(remote),
          offlineDictionaryProvider.overrideWithValue(_EmptyDictionary()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () => RuntimeTranslationSheet.show(
                    context,
                    anchor: const Rect.fromLTWH(20, 200, 300, 30),
                    lang: 'en',
                    text: _sentence,
                  ),
                  child: const Text('Satz'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  double bubbleWidth(WidgetTester tester) =>
      tester.getSize(find.byType(RuntimeTranslationSheet)).width;

  testWidgets('used-up sentence bubble shrinks into the Premium card', (
    tester,
  ) async {
    await host(tester);
    await tester.tap(find.text('Satz'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(remote.calls, 1);
    expect(find.text(TranslationPaywallCard.title), findsOneWidget);
    expect(find.text(TranslationPaywallCard.detail), findsOneWidget);
    expect(find.text(TranslationPaywallCard.action), findsOneWidget);
    // Neither the quota sentence nor the source text stays in the bubble.
    expect(find.textContaining('aufgebraucht'), findsNothing);
    expect(find.text(_sentence), findsNothing);
    // As small as a word bubble: half the screen, minus the inner padding.
    final context = tester.element(find.byType(RuntimeTranslationSheet));
    expect(
      bubbleWidth(tester),
      closeTo(
        wordBubbleWidth(context) - translationPaywallPadding.horizontal,
        0.5,
      ),
    );
    // The action glints.
    expect(
      find.ancestor(
        of: find.text(TranslationPaywallCard.action),
        matching: find.byType(LightSweep),
      ),
      findsOneWidget,
    );
  });

  testWidgets('next tap opens the card right away without a request', (
    tester,
  ) async {
    await host(tester);
    await tester.tap(find.text('Satz'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(remote.calls, 1);
    await tester.tapAt(const Offset(5, 800));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(find.byType(TranslationPaywallCard), findsNothing);

    await tester.tap(find.text('Satz'));
    await tester.pump();
    // Small from the first frame: the sentence never shows.
    expect(find.text(_sentence), findsNothing);
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(TranslationPaywallCard), findsOneWidget);
    expect(remote.calls, 1);
  });

  testWidgets('reduced motion shows the card without sweep or bobbing', (
    tester,
  ) async {
    await host(tester);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pump();
    await tester.tap(find.text('Satz'));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(find.byType(TranslationPaywallCard), findsOneWidget);
    expect(find.byType(ShaderMask), findsNothing);
    await tester.pump(const Duration(seconds: 1));
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
