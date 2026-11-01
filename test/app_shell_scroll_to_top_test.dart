import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/screens/app_shell.dart';
import 'package:sprachapp/screens/content/content_dashboard_screen.dart';
import 'package:sprachapp/screens/stories/story_library_screen.dart';
import 'package:sprachapp/theme/app_theme.dart';
import 'package:sprachapp/widgets/app_bottom_bar.dart';

import 'fixtures/deck_repositories.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Finder tab(String label) => find.descendant(
    of: find.byType(AppBottomBar),
    matching: find.text(label),
  );

  ScrollPosition position(WidgetTester tester, Type screen) => tester
      .state<ScrollableState>(
        find
            .descendant(
              of: find.byType(screen),
              matching: find.byType(Scrollable),
            )
            .first,
      )
      .position;

  testWidgets('re-tapping the active tab scrolls it to the top', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      testScope(
        MaterialApp(theme: buildAppTheme(), home: const AppShell()),
        library: true,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(tab('Stories'));
    await tester.pumpAndSettle();
    position(tester, StoryLibraryScreen).jumpTo(300);
    await tester.pump();

    await tester.tap(tab('Inhalte'));
    await tester.pumpAndSettle();
    final content = position(tester, ContentDashboardScreen);
    content.jumpTo(600);
    await tester.pump();
    expect(content.pixels, 600);

    await tester.tap(tab('Inhalte'));
    await tester.pumpAndSettle();
    expect(content.pixels, 0);

    // Switching tabs keeps the other tab's position.
    await tester.tap(tab('Stories'));
    await tester.pumpAndSettle();
    expect(position(tester, StoryLibraryScreen).pixels, 300);
    expect(tester.takeException(), isNull);
  });
}
