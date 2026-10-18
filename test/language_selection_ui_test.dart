import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoButton;
import 'package:sprachapp/screens/home/widgets/home_header.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/screens/app_shell.dart';
import 'package:sprachapp/screens/settings/settings_screen.dart';
import 'package:sprachapp/presentation/providers/database_providers.dart';
import 'package:sprachapp/presentation/providers/learning_providers.dart';
import 'package:sprachapp/presentation/providers/deck_providers.dart';
import 'package:sprachapp/presentation/providers/story_learning_providers.dart';
import 'package:sprachapp/presentation/providers/language_selection_provider.dart';
import 'package:sprachapp/data/content/content_install_journal.dart';
import 'package:sprachapp/data/content/content_update_service.dart';
import 'package:sprachapp/theme/app_theme.dart';

import 'fixtures/language_selection.dart';
import 'fixtures/portuguese_installation.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  testWidgets(
    'Portuguese header fits 320pt at double text size and keeps both 44pt buttons',
    (t) async {
      t.view.physicalSize = const Size(320, 760);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 760),
              textScaler: TextScaler.linear(2),
            ),
            child: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(20),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: HomeHeader(
                    flag: '🇧🇷',
                    languageName: 'Portugiesisch (Brasilien)',
                    onProfile: () {},
                    onSettings: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(
        find.bySemanticsLabel('Zielsprache: Portugiesisch (Brasilien)'),
        findsOneWidget,
      );
      final text = find.text('🇧🇷  Portugiesisch (Brasilien)');
      expect(text, findsOneWidget);
      expect(t.getRect(text).left, greaterThanOrEqualTo(20));
      expect(t.getRect(text).right, lessThanOrEqualTo(300));
      expect(find.byType(CupertinoButton), findsNWidgets(2));
      for (final button in find.byType(CupertinoButton).evaluate()) {
        final size = t.getSize(find.byWidget(button.widget));
        expect(size.width, 44);
        expect(size.height, 44);
      }
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'visible language selection, absent language, updates, installed test deck, empty stories and English return',
    (t) async {
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final h = LanguageHarness(
        Directory.systemTemp.createTempSync('language-ui-'),
      );
      var c = h.scope();
      await t.runAsync(() async {
        await c.read(userRepositoryProvider.future);
        await c.read(contentRepositoryProvider.future);
      });
      final boundary = GlobalKey();
      Future<void> settleIo() async {
        for (var i = 0; i < 20; i++) {
          await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 25)),
          );
          await t.pump(const Duration(milliseconds: 10));
        }
        await t.pumpAndSettle();
      }

      Future<void> show(Widget screen) async {
        await t.pumpWidget(
          UncontrolledProviderScope(
            container: c,
            child: RepaintBoundary(
              key: boundary,
              child: MaterialApp(theme: buildAppTheme(), home: screen),
            ),
          ),
        );
        await settleIo();
      }

      Future<void> capture(String name) async {
        await t.runAsync(() async {
          final image =
              await (boundary.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage();
          final bytes = (await image.toByteData(
            format: ui.ImageByteFormat.png,
          ))!;
          image.dispose();
          final file = File('build/portuguese_package_2/ui/$name.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes.buffer.asUint8List());
        });
      }

      await show(const SettingsScreen());
      expect(find.text('Lernsprache'), findsOneWidget);
      expect(find.text('Portugiesisch (Brasilien)'), findsOneWidget);
      await capture('settings');
      await t.tap(find.text('Portugiesisch (Brasilien)'));
      await settleIo();
      expect(
        await t.runAsync(() => c.read(selectedContentLanguageProvider.future)),
        'pt-BR',
      );
      await t.scrollUntilVisible(
        find.text('Akzente sind für Portugiesisch erforderlich'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.text('Akzente sind für Portugiesisch erforderlich'),
        findsOneWidget,
      );
      await show(const AppShell());
      expect(find.text('Kein Inhaltspaket installiert.'), findsOneWidget);
      expect(find.text('Zu Inhaltsupdates'), findsOneWidget);
      expect(find.text('Aktive Stapel'), findsNothing);
      await capture('not-installed');
      await t.tap(find.text('Zu Inhaltsupdates'));
      await settleIo();
      expect(
        find.text('Portugiesisch (Brasilien) · Noch nicht installiert'),
        findsOneWidget,
      );
      await capture('updates');
      await t.runAsync(() async {
        final transport = PortugueseTransport(h.root);
        final journal = ContentInstallJournal(h.root, 'pt-BR');
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
      });
      // Restart the isolated provider scope after the external synthetic install.
      // Service/provider activation itself is covered in language_update_lifecycle_test.
      await t.pumpWidget(const SizedBox());
      c.dispose();
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      c = h.scope();
      await t.runAsync(() async {
        await c.read(contentInfoProvider.future);
        await c.read(learningProgressProvider.future);
        await c.read(decksProvider.future);
        await c.read(wordListProvider.future);
        await c.read(vocabBreakdownProvider.future);
        await c.read(storySummariesProvider.future);
      });
      await show(const AppShell());
      await settleIo();
      expect(
        find.bySemanticsLabel('Zielsprache: Portugiesisch (Brasilien)'),
        findsOneWidget,
      );
      expect(find.text('🇧🇷  Portugiesisch (Brasilien)'), findsOneWidget);
      expect(t.takeException(), isNull);
      await capture('installed');
      await t.scrollUntilVisible(
        find.text('SYNTHETISCH – NICHT VERÖFFENTLICHEN'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('SYNTHETISCH – NICHT VERÖFFENTLICHEN'), findsWidgets);
      await t.scrollUntilVisible(
        find.text(
          'Für Portugiesisch (Brasilien) sind noch keine Stories verfügbar.',
        ),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.text(
          'Für Portugiesisch (Brasilien) sind noch keine Stories verfügbar.',
        ),
        findsWidgets,
      );
      await capture('empty-stories');
      final returning = c
          .read(languageSelectionProvider.notifier)
          .selectLanguage('en');
      await settleIo();
      expect(await returning, true);
      expect(find.bySemanticsLabel('Zielsprache: Englisch'), findsOneWidget);
      expect(find.text('SYNTHETISCH – NICHT VERÖFFENTLICHEN'), findsNothing);
      await capture('returned-english');
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      c.dispose();
      await t.runAsync(h.close);
    },
  );
}
