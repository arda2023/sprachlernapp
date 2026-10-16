import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/domain/content.dart';
import 'package:sprachapp/presentation/providers/database_providers.dart';
import 'package:sprachapp/screens/settings/content_updates_screen.dart';
import 'package:sprachapp/theme/app_theme.dart';

void main() {
  testWidgets(
    'update login and offline state remain usable at 320 pixels and double text size',
    (t) async {
      t.view.physicalSize = const Size(320, 760);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            contentInfoProvider.overrideWith(
              (ref) async => const ContentInfo(
                lang: 'en',
                version: 'synthetic-v1',
                schemaVersion: 5,
              ),
            ),
          ],
          child: MaterialApp(
            theme: buildAppTheme(),
            builder: (_, child) => MediaQuery(
              data: const MediaQueryData(
                size: Size(320, 760),
                textScaler: TextScaler.linear(2),
              ),
              child: child!,
            ),
            home: const ContentUpdatesScreen(),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      expect(find.text('Englisch · synthetic-v1'), findsOneWidget);
      await t.scrollUntilVisible(
        find.text('Nach Updates suchen'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await t.tap(find.text('Nach Updates suchen'));
      await t.pumpAndSettle();
      await t.scrollUntilVisible(
        find.text('Privater Inhaltsserver noch nicht eingerichtet.'),
        -150,
        scrollable: find.byType(Scrollable).first,
      );
      await t.pumpAndSettle();
      expect(
        find.text('Privater Inhaltsserver noch nicht eingerichtet.'),
        findsOneWidget,
      );
      expect(t.takeException(), isNull);
    },
  );
}
