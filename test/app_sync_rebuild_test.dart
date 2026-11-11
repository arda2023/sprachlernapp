import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/main.dart';
import 'package:sprachapp/presentation/providers/learning_sync_provider.dart';

import 'fixtures/deck_repositories.dart';

class ObservableSync extends LearningSyncController {
  int starts = 0;
  @override
  LearningSyncPhase build() {
    starts++;
    return LearningSyncPhase.current;
  }

  void publish(LearningSyncPhase phase) {
    state = phase;
  }
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  testWidgets(
    'app keeps sync active without rebuilding MaterialApp on status',
    (tester) async {
      final sync = ObservableSync();
      await tester.pumpWidget(
        testScope(
          const SprachApp(),
          library: true,
          overrides: [learningSyncProvider.overrideWith(() => sync)],
        ),
      );
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(sync.starts, 1);
      final before = tester.widget<MaterialApp>(find.byType(MaterialApp));
      sync.publish(LearningSyncPhase.syncing);
      await tester.pump();
      expect(
        identical(tester.widget(find.byType(MaterialApp)), before),
        isTrue,
      );
      sync.publish(LearningSyncPhase.current);
      await tester.pump();
      expect(
        identical(tester.widget(find.byType(MaterialApp)), before),
        isTrue,
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(SprachApp)),
      );
      expect(container.read(learningSyncProvider), LearningSyncPhase.current);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
