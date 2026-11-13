import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/data/platform/json_store_base.dart';
import 'package:sprachapp/domain/streak.dart';
import 'package:sprachapp/models/home_models.dart';
import 'package:sprachapp/presentation/providers/review_request_provider.dart';
import 'package:sprachapp/presentation/review/review_request_service.dart';
import 'package:sprachapp/screens/completion/practice_completion_screen.dart';
import 'package:sprachapp/screens/completion/widgets/stacked_word_cards.dart';
import 'package:sprachapp/theme/app_theme.dart';

import 'review_request_test.dart' show FakeReviewGateway;

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  final now = DateTime(2026, 11, 13, 18);
  final streak = summarizeStreak([
    now,
    DateTime(2026, 11, 12),
    DateTime(2026, 11, 11),
  ], now);
  const words = [
    CompletionWord(
      form: 'word',
      translation: 'Wort',
      sentence: 'A word.',
      isNew: true,
    ),
  ];

  for (final reduceMotion in [false, true]) {
    testWidgets(
      'real completion calls once after settling, reduced motion $reduceMotion',
      (tester) async {
        final gateway = FakeReviewGateway();
        final store = MemoryJsonStore();
        await store.write({'completedSessions': 1});
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              reviewRequestServiceProvider.overrideWithValue(
                ReviewRequestService(
                  store: store,
                  gateway: gateway,
                  clock: () => now,
                  supported: true,
                ),
              ),
            ],
            child: MaterialApp(
              theme: buildAppTheme(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(disableAnimations: reduceMotion),
                child: child!,
              ),
              home: Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () => Navigator.of(context).push(
                      PracticeCompletionScreen.route(
                        streak: streak,
                        goal: const DailyGoal(done: 10, target: 10),
                        words: words,
                      ),
                    ),
                    child: const Text('Start'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Start'));
        await tester.pump();
        if (!reduceMotion) expect(gateway.requests, 0);
        await tester.pumpAndSettle();
        expect(gateway.requests, 1);
        await tester.pump(const Duration(seconds: 1));
        expect(gateway.requests, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('preview completion does not request a review', (tester) async {
    final gateway = FakeReviewGateway();
    final store = MemoryJsonStore();
    await store.write({'completedSessions': 10});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reviewRequestServiceProvider.overrideWithValue(
            ReviewRequestService(
              store: store,
              gateway: gateway,
              clock: () => now,
              supported: true,
            ),
          ),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: PracticeCompletionScreen(
            streak: streak,
            goal: const DailyGoal(done: 10, target: 10),
            words: words,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(gateway.checks, 0);
    expect(gateway.requests, 0);
  });
}
