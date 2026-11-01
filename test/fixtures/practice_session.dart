import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/domain/content.dart';
import 'package:sprachapp/domain/srs_state.dart';
import 'package:sprachapp/presentation/practice/deck_session_controller.dart';
import 'package:sprachapp/screens/decks/deck_practice_screen.dart';

import 'deck_repositories.dart';

/// Read the shown target instead of assuming an alphabetical introduction order.
PracticeItem shownPracticeItem(WidgetTester tester) {
  final finder = find.byType(DeckPracticeScreen);
  final screen = tester.widget<DeckPracticeScreen>(finder);
  final args = (
    deckId: screen.deckId,
    kind: switch (screen.mode) {
      DeckPracticeMode.learn => DeckSessionKind.learn,
      DeckPracticeMode.review => DeckSessionKind.revue,
      DeckPracticeMode.mixed => DeckSessionKind.mixed,
      DeckPracticeMode.early => DeckSessionKind.early,
    },
    size: screen.sessionSize,
  );
  return ProviderScope.containerOf(tester.element(finder))
      .read(deckSessionControllerProvider(args))
      .pass!
      .item;
}

/// The synonym/other-form test specifically exercises walks/strolls/walking.
class WalksOnlyContent extends TestContent {
  @override
  Future<List<String>> deckCardIds(String deckId) async => ['$deckId/0'];
}
