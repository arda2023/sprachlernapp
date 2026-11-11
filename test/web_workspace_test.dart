import 'dart:io';

import 'package:flutter/cupertino.dart' show CupertinoPicker;
import 'package:sprachapp/presentation/providers/database_providers.dart';
import 'package:sprachapp/presentation/providers/deck_providers.dart';
import 'package:sprachapp/presentation/providers/story_learning_providers.dart';
import 'package:sprachapp/data/content/content_install_journal.dart';
import 'package:sprachapp/data/content/content_update_service.dart';

import 'fixtures/language_selection.dart';
import 'fixtures/portuguese_installation.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/presentation/providers/account_provider.dart';
import 'package:sprachapp/screens/web/web_app_gate.dart';
import 'package:sprachapp/screens/web/web_learning_shell.dart';
import 'package:sprachapp/theme/app_theme.dart';

class _Actions implements AccountActions {
  String? sentEmail;
  String? verifiedCode;
  @override
  Future<void> sendCode(String email) async => sentEmail = email;
  @override
  Future<void> verifyCode(String email, String code) async =>
      verifiedCode = code;
  @override
  Future<void> signIn(AccountIdentityProvider provider) async {}
  @override
  Future<void> signOut() async {}
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets(
    'web language picker changes Reader and Decks and persists across scopes',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final harness = LanguageHarness(
        Directory.systemTemp.createTempSync('web-language-'),
      );
      var container = harness.scope();
      Future<void> settle() async {
        for (var i = 0; i < 160; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 25)),
          );
          await tester.pump(const Duration(milliseconds: 10));
        }
        await tester.pump(const Duration(milliseconds: 500));
      }

      await tester.runAsync(() async {
        final transport = PortugueseTransport(harness.root);
        final journal = ContentInstallJournal(harness.root, 'pt-BR');
        final service = ContentUpdateService(
          journal,
          transport,
          currentFile: journal.currentFile,
          gate: ContentTransitionGate(),
          closeReaders: () async {},
          openReaders: () async {},
        );
        await service.check();
        await service.download();
        await service.activate();
        await container.read(userRepositoryProvider.future);
        await container.read(contentInfoProvider.future);
        await container.read(decksProvider.future);
        await container.read(storySummariesProvider.future);
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: buildAppTheme(),
            home: const WebLearningShell(),
          ),
        ),
      );
      await settle();
      expect(find.text('Englisch'), findsOneWidget);
      final englishDecks = await tester.runAsync(
        () => container.read(decksProvider.future),
      );
      await tester.tap(find.byType(WebLanguageSelector));
      await tester.pumpAndSettle();
      final picker = tester.widget<CupertinoPicker>(
        find.byType(CupertinoPicker),
      );
      picker.scrollController!.jumpToItem(1);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Auswählen'));
      await settle();
      expect(
        await tester.runAsync(
          () => container.read(selectedContentLanguageProvider.future),
        ),
        'pt-BR',
      );
      expect(find.text('Portugiesisch (Brasilien)'), findsOneWidget);
      expect(
        (await tester.runAsync(
          () => container.read(contentInfoProvider.future),
        ))!.lang,
        'pt-BR',
      );
      expect(
        await tester.runAsync(
          () => container.read(storySummariesProvider.future),
        ),
        isEmpty,
      );

      final portugueseDecks = await tester.runAsync(
        () => container.read(decksProvider.future),
      );
      expect(portugueseDecks, isNotEmpty);
      expect(
        portugueseDecks!.map((d) => d.id),
        isNot(englishDecks!.map((d) => d.id)),
      );
      await tester.tap(find.widgetWithText(TextButton, 'Stapel').first);
      await settle();
      expect(find.text(portugueseDecks.first.name), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      container.dispose();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      container = harness.scope();
      expect(
        await tester.runAsync(
          () => container.read(selectedContentLanguageProvider.future),
        ),
        'pt-BR',
      );
      container.dispose();
      await tester.runAsync(harness.close);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'long current language remains readable on narrow web header at 2x text',
    (tester) async {
      tester.view.physicalSize = const Size(360, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedContentLanguageProvider.overrideWith(
              (ref) async => 'pt-BR',
            ),
          ],
          child: MaterialApp(
            theme: buildAppTheme(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: WebWorkspaceFrame(
              selectedIndex: 0,
              onSelect: (_) {},
              onSettings: () {},
              languageSelector: const WebLanguageSelector(),
              child: const SizedBox(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Portugiesisch (Brasilien)'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          'Zielsprache: Portugiesisch (Brasilien). Sprache wählen',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [360.0, 768.0, 1440.0]) {
    testWidgets('web workspace navigation at $width px and large text', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var selected = 0;
      var practiceStarts = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: WebWorkspaceFrame(
            selectedIndex: 0,
            onSelect: (index) => selected = index,
            onPractice: () => practiceStarts++,
            onSettings: () {},
            child: const Center(child: Text('Bibliothek')),
          ),
        ),
      );
      expect(find.text('Lesemodus'), findsOneWidget);
      expect(find.text('Stapel'), findsOneWidget);
      expect(find.text('Inhalte'), findsNothing);
      expect(find.text('Wortliste'), findsNothing);
      expect(
        find.byKey(
          ValueKey(width >= 900 ? 'web-sidebar' : 'web-bottom-navigation'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Stapel'));
      await tester.pump();
      expect(selected, 1);
      await tester.tap(
        width >= 900
            ? find.text('Alle aktiven Stapel üben')
            : find.byTooltip('Alle aktiven Stapel üben'),
      );
      await tester.pump();
      expect(practiceStarts, 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'email code login validates and verifies the same account email',
    (tester) async {
      final actions = _Actions();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [accountActionsProvider.overrideWithValue(actions)],
          child: MaterialApp(
            theme: buildAppTheme(),
            home: const WebLoginScreen(),
          ),
        ),
      );
      await tester.tap(find.text('Anmeldecode senden'));
      await tester.pumpAndSettle();
      expect(actions.sentEmail, isNull);
      await tester.enterText(
        find.byType(TextFormField).first,
        'reader@example.org',
      );
      await tester.tap(find.text('Anmeldecode senden'));
      await tester.pumpAndSettle();
      expect(actions.sentEmail, 'reader@example.org');
      await tester.enterText(find.byType(TextFormField).last, '123456');
      await tester.ensureVisible(find.text('Anmelden'));
      await tester.tap(find.text('Anmelden'));
      await tester.pumpAndSettle();
      expect(actions.verifiedCode, '123456');
      expect(tester.takeException(), isNull);
    },
  );
}
