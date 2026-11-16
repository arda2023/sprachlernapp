import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/data/content/content_auth_repository.dart';
import 'package:sprachapp/data/runtime_translation_client.dart';
import 'package:sprachapp/domain/preferences.dart';
import 'package:sprachapp/models/practice_models.dart';
import 'package:sprachapp/models/reading_history.dart';
import 'package:sprachapp/models/sample_content.dart';
import 'package:sprachapp/presentation/providers/auth_providers.dart';
import 'package:sprachapp/presentation/providers/database_providers.dart';
import 'package:sprachapp/presentation/providers/preferences_provider.dart';
import 'package:sprachapp/presentation/providers/purchase_provider.dart';
import 'package:sprachapp/presentation/providers/runtime_translation_provider.dart';
import 'package:sprachapp/screens/content/content_dashboard_screen.dart';
import 'package:sprachapp/screens/content/widgets/exercise_choice_sheet.dart';
import 'package:sprachapp/screens/decks/deck_details_screen.dart';
import 'package:sprachapp/screens/decks/deck_practice_screen.dart';
import 'package:sprachapp/screens/onboarding/paywall_screen.dart';
import 'package:sprachapp/screens/practice/choice_exercise_screen.dart';
import 'package:sprachapp/screens/stories/widgets/import_panel.dart';
import 'package:sprachapp/theme/app_theme.dart';
import 'package:sprachapp/widgets/runtime_translation_sheet.dart';

import 'fixtures/deck_repositories.dart';

class _Purchase extends PurchaseController {
  @override
  PurchaseState build() => const PurchaseState(
    phase: PurchasePhase.ready,
    billingReady: true,
    hasVerifiedAccount: true,
    premiumActive: false,
  );

  @override
  Future<void> load() async {}

  void confirm() => state = state.copyWith(
    premiumActive: true,
    lastOutcome: PurchaseResult.success,
  );
}

class _Preferences extends PreferencesController {
  @override
  Future<PracticePreferences> build() async => const PracticePreferences();
}

class _Auth extends ContentAuthRepository {
  _Auth() : super('', '');
  String? owner = 'account-a';
  @override
  String? get localOwner => owner;

  void switchOwner() {
    owner = 'account-b';
    identityRevision++;
  }
}

class _Translation extends RuntimeTranslationClient {
  _Translation() : super('', '', () async => '');
  final requests = <String>[];

  @override
  Future<WordCloudConsent> wordCloudConsent() async => WordCloudConsent.enabled;

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
    requests.add(text);
    if (requests.length == 1) {
      throw const TranslationFailure('Limit', freeQuotaUsedUp: true);
    }
    return const RuntimeTranslation('Übersetzt.', 'test', 'request');
  }
}

class _Harness {
  _Harness({RuntimeTranslationClient? translation, bool deckFixtures = false}) {
    container = ProviderContainer(
      overrides: [
        contentAuthProvider.overrideWithValue(auth),
        selectedContentLanguageProvider.overrideWith((_) async => language),
        preferencesProvider.overrideWith(_Preferences.new),
        purchaseProvider.overrideWith(() => purchase),
        if (translation != null)
          runtimeTranslationProvider.overrideWithValue(translation),
        if (deckFixtures) ...[
          contentRepositoryProvider.overrideWith(
            (_) async => TestContent(library: true),
          ),
          userRepositoryProvider.overrideWith((ref) async {
            final user = TestUser(library: true);
            ref.onDispose(user.close);
            return user;
          }),
        ],
      ],
    );
    addTearDown(() async {
      container.dispose();
      await auth.close();
    });
  }

  final auth = _Auth();
  final purchase = _Purchase();
  String language = 'en';
  late final ProviderContainer container;

  Future<void> show(WidgetTester tester, Widget child) async {
    await container.read(selectedContentLanguageProvider.future);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildAppTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: Scaffold(body: child),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> complete(WidgetTester tester, {bool settle = true}) async {
    expect(find.byType(PaywallScreen), findsOneWidget);
    purchase.confirm();
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
    }
    expect(find.byType(PaywallScreen), findsNothing);
  }
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets(
    'a guest can sign in and start the chosen bundled deck after purchase',
    (tester) async {
      final h = _Harness(deckFixtures: true);
      h.auth.owner = null;
      const deckId = 'deck-1';
      await h.show(tester, const DeckDetailsScreen(deckId: deckId));
      await tester.tap(find.text('Premium holen'));
      await tester.pumpAndSettle();
      h.auth.switchOwner();
      // Deck practice has its own loading and audio animations.
      await h.complete(tester, settle: false);
      final practice = tester.widget<DeckPracticeScreen>(
        find.byType(DeckPracticeScreen),
      );
      expect(practice.deckId, deckId);
      expect(practice.mode, DeckPracticeMode.learn);
    },
  );

  testWidgets('the selected locked text opens its own exercise choices', (
    tester,
  ) async {
    final h = _Harness();
    final history = ReadingHistory(const []);
    final progress = PracticeProgress(const []);
    addTearDown(history.dispose);
    addTearDown(progress.dispose);
    final selected = sampleExerciseTexts[1];
    await h.show(
      tester,
      ContentDashboardScreen(
        texts: sampleExerciseTexts.take(2).toList(),
        history: history,
        listening: const [],
        grammar: const [],
        progress: progress,
        rules: const [],
      ),
    );
    await tester.tap(find.text(selected.info.title));
    await tester.pumpAndSettle();
    await h.complete(tester);
    expect(
      tester.widget<ExerciseChoiceSheet>(find.byType(ExerciseChoiceSheet)).text,
      same(selected),
    );
  });

  testWidgets(
    'cancel leaves the selected exercise unopened; confirmation opens it',
    (tester) async {
      final h = _Harness();
      final progress = PracticeProgress(const []);
      addTearDown(progress.dispose);
      final exercise = sampleGrammarExercises[1];
      await h.show(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => ChoiceExerciseScreen.open(
              context,
              exercise: exercise,
              progress: progress,
            ),
            child: const Text('Übung aufrufen'),
          ),
        ),
      );
      final open = find.text('Übung aufrufen');
      await tester.tap(open);
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Schließen'));
      await tester.pumpAndSettle();
      expect(find.byType(GrammarExerciseScreen), findsNothing);

      await tester.tap(open);
      await tester.pumpAndSettle();
      await h.complete(tester);
      expect(
        tester
            .widget<GrammarExerciseScreen>(find.byType(GrammarExerciseScreen))
            .exercise,
        same(exercise),
      );
    },
  );

  for (final changeAccount in [true, false]) {
    testWidgets(
      'a changed ${changeAccount ? 'account' : 'language'} invalidates the pending exercise',
      (tester) async {
        final h = _Harness();
        final progress = PracticeProgress(const []);
        addTearDown(progress.dispose);
        await h.show(
          tester,
          Builder(
            builder: (context) => TextButton(
              onPressed: () => ChoiceExerciseScreen.open(
                context,
                exercise: sampleGrammarExercises.first,
                progress: progress,
              ),
              child: const Text('Übung aufrufen'),
            ),
          ),
        );
        await tester.tap(find.text('Übung aufrufen'));
        await tester.pumpAndSettle();
        if (changeAccount) {
          h.auth.switchOwner();
        } else {
          h.language = 'it';
          h.container.invalidate(selectedContentLanguageProvider);
        }
        await h.complete(tester);
        expect(find.byType(GrammarExerciseScreen), findsNothing);
      },
    );
  }

  testWidgets(
    'the chosen paste action reads the clipboard once after confirmation',
    (tester) async {
      final h = _Harness();
      var reads = 0;
      final texts = <String>[];
      final messenger = tester.binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method != 'Clipboard.getData') return null;
        reads++;
        return {'text': 'This is the original clipboard text.'};
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
      );
      await h.show(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => Scaffold(
                  body: ImportPanel(
                    onImportText: (text) {
                      texts.add(text);
                      return null;
                    },
                  ),
                ),
              ),
            ),
            child: const Text('Import öffnen'),
          ),
        ),
      );
      await tester.tap(find.text('Import öffnen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Text einfügen'));
      await tester.pumpAndSettle();
      expect(reads, 0);
      await h.complete(tester);
      expect(texts, ['This is the original clipboard text.']);
      expect(reads, 1);
      expect(find.byType(ImportPanel), findsNothing);
    },
  );

  testWidgets('translation returns to the same sentence and retries once', (
    tester,
  ) async {
    final translation = _Translation();
    final h = _Harness(translation: translation);
    const sentence = 'I close the door.';
    await h.show(
      tester,
      const RuntimeTranslationSheet(lang: 'en', text: sentence),
    );
    expect(translation.requests, [sentence]);
    await tester.tap(find.text('Premium holen'));
    await tester.pumpAndSettle();
    expect(translation.requests, [sentence]);
    await h.complete(tester);
    expect(translation.requests, [sentence, sentence]);
    expect(find.text('Übersetzt.'), findsOneWidget);
  });
}
