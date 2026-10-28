import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/streak.dart';
import '../../domain/content.dart';
import '../../domain/srs_state.dart';
import '../../presentation/providers/story_collection_provider.dart';
import '../stories/story_collection_screen.dart';
import '../../models/home_models.dart';
import '../../presentation/providers/streak_providers.dart';
import '../../theme/app_theme.dart';
import '../completion/practice_completion_screen.dart';
import '../completion/widgets/stacked_word_cards.dart';
import '../onboarding/onboarding_screen.dart';

/// Manually replayable screens with presentation-only sample data.
class ScreenPreviewsScreen extends StatelessWidget {
  const ScreenPreviewsScreen({super.key});

  // ANWEISUNG FÜR KI-AGENTEN: Immer wenn ein neuer vergleichbarer Screen
  // (z. B. Onboarding, Abschluss, Meilenstein oder besondere Animation) erstellt
  // wird, hier automatisch einen passenden Vorschau-Button ergänzen.
  // Den echten Screen mit isolierten Beispieldaten öffnen; niemals Lernstand,
  // Einstellungen, Onboarding-Abschluss oder Feier-Markierungen speichern.
  // Jeder Vorschau-Screen muss jederzeit wieder geschlossen werden können.
  static final _previews =
      <({String title, String detail, WidgetBuilder build})>[
        (
          title: 'Aus Storys',
          detail: 'Persönliche Sammlung · Vorschau ohne Speicherung',
          build: (_) => StoryCollectionScreen(preview: [
            StoryCollectionWord(
              const UserCardState(cardId: 'preview', box: 0, dueAt: null),
              PracticeItem(otherFormsOfLemma: const {}, card: const ContentCard(
                id: 'preview', lang: 'en', form: 'pocket', formNorm: 'pocket',
                lemmaId: 'pocket', lemma: 'pocket', pos: 'NOUN', translationDe: 'Tasche',
              ), sentences: const [CardSentence(
                cardId: 'preview', position: 1, sentenceId: 'preview', text: 'My keys are in my pocket.',
                translationDe: 'Meine Schlüssel sind in meiner Tasche.',
                gapStart: 18, gapEnd: 24,
              )]),
            ),
          ]),
        ),
        (
          title: 'Onboarding',
          detail: 'Alle fünf Schritte ab dem Willkommen-Bildschirm',
          build: (context) =>
              OnboardingScreen(onDone: (_) => Navigator.of(context).pop()),
        ),
        (
          title: 'Übungsabschluss',
          detail: 'Sehr gut! · Tag 4 · animierte Flamme und Wortkarten',
          build: (_) => _completion(4),
        ),
        (
          title: 'Abschluss nach 6 Tagen',
          detail: 'Volle Häkchen-Leiste · noch ein Tag bis zum Stern',
          build: (_) => _completion(6),
        ),
        (
          title: 'Wochenstern',
          detail: 'Tag 7 · vollständige Stern-Animation mit Ton und Haptik',
          build: (_) => _completion(7),
        ),
      ];

  static Widget _completion(int days) {
    final now = DateTime.now();
    return PracticeCompletionScreen(
      streak: summarizeStreak({
        for (var i = 0; i < days; i++)
          DateTime(now.year, now.month, now.day - i),
      }, now),
      goal: const DailyGoal(done: 5, target: 5),
      words: const [
        CompletionWord(
          form: 'journey',
          translation: 'Reise',
          sentence: 'The journey begins today.',
          isNew: true,
        ),
        CompletionWord(
          form: 'window',
          translation: 'Fenster',
          sentence: 'She opens the window.',
          isNew: true,
        ),
        CompletionWord(
          form: 'garden',
          translation: 'Garten',
          sentence: 'We are sitting in the garden.',
          isNew: true,
        ),
        CompletionWord(
          form: 'arrive',
          translation: 'ankommen',
          sentence: 'They arrive in the morning.',
          isNew: true,
        ),
        CompletionWord(
          form: 'quiet',
          translation: 'ruhig',
          sentence: 'It is quiet here.',
          isNew: true,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Bildschirm-Vorschauen')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Bildschirme und Animationen jederzeit ausprobieren.',
          style: AppType.chrome(color: context.appColors.textMuted),
        ),
        const SizedBox(height: 16),
        for (final preview in _previews)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            title: Text(preview.title),
            subtitle: Text(preview.detail),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ProviderScope(
                  overrides: [
                    celebrationMarksProvider.overrideWith(
                      (ref) => MemoryCelebrationMarks(),
                    ),
                  ],
                  child: Scaffold(
                    appBar: AppBar(title: Text('Vorschau: ${preview.title}')),
                    body: Builder(builder: preview.build),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
