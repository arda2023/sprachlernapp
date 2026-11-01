import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/domain/content.dart';
import 'package:sprachapp/domain/sentences.dart';
import 'package:sprachapp/models/exercise_models.dart';
import 'package:sprachapp/models/localized_practice_content.dart';
import 'package:sprachapp/models/sample_content.dart';
import 'package:sprachapp/presentation/providers/database_providers.dart';
import 'package:sprachapp/screens/app_shell.dart';
import 'package:sprachapp/screens/content/content_dashboard_screen.dart';
import 'package:sprachapp/screens/content/text_exercise_screen.dart';
import 'package:sprachapp/theme/app_theme.dart';
import 'package:sprachapp/widgets/app_bottom_bar.dart';

import 'fixtures/deck_repositories.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  for (final language in ['es', 'it', 'nb', 'pt-BR']) {
    testWidgets('$language opens its authored exercise from AppShell', (
      t,
    ) async {
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final authored = localizedPracticeContent[language]!;
      await t.pumpWidget(
        testScope(
          MaterialApp(theme: buildAppTheme(), home: const AppShell()),
          overrides: [
            selectedContentLanguageProvider.overrideWith(
              (ref) async => language,
            ),
            contentInfoProvider.overrideWith(
              (ref) async => ContentInfo(
                lang: language,
                version: 'route-fixture',
                schemaVersion: 1,
                notes: 'Isolated routing fixture',
              ),
            ),
          ],
        ),
      );
      await t.pumpAndSettle();
      await t.tap(
        find.descendant(
          of: find.byType(AppBottomBar),
          matching: find.text('Inhalte'),
        ),
      );
      await t.pumpAndSettle();
      final dashboard = t.widget<ContentDashboardScreen>(
        find.byType(ContentDashboardScreen),
      );
      expect(dashboard.texts, same(authored.texts));
      expect(dashboard.listening, same(authored.listening));
      expect(dashboard.grammar, same(authored.grammar));
      expect(dashboard.rules, same(authored.rules));
      expect(dashboard.texts, isNot(same(sampleExerciseTexts)));
      expect(dashboard.listening, isNot(same(sampleListeningExercises)));
      expect(dashboard.grammar, isNot(same(sampleGrammarExercises)));
      expect(dashboard.rules, isNot(same(sampleGrammarRules)));
      final title = find.text(authored.texts.first.info.title);
      await t.ensureVisible(title);
      await t.tap(title);
      await t.pumpAndSettle();
      await t.tap(find.text(ExerciseMode.verbs.title));
      await t.pumpAndSettle();
      final screen = t.widget<TextExerciseScreen>(
        find.byType(TextExerciseScreen),
      );
      expect(screen.text, same(authored.texts.first));
      expect(screen.effectiveSourceLanguage, language);
      expect(screen.mode, ExerciseMode.verbs);
      for (final text in authored.texts) {
        for (final paragraph in text.segments) {
          final plain = paragraph
              .map((part) => part is TextGap ? part.answer : part as String)
              .join();
          for (final sentence in splitSentences(plain)) {
            final source = plain.substring(sentence.start, sentence.end).trim();
            final german = authored.translations[source];
            expect(german, isNotNull, reason: '$language: $source');
            expect(screen.translate(source), german);
            expect(screen.translate(' $source '), german);
          }
        }
      }
      expect(t.takeException(), isNull);
    });
  }
}
