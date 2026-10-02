# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) and other agentic assistants when working with code in this repository.

## Project State

Sprachapp is an editorial, reading-first language learning application for iOS and Android built with Flutter.
The initial version targets adult German speakers learning English through contextual stories and spaced-repetition sentence decks.

The repository currently contains:
- A functional home dashboard (`HomeScreen`) with dark-mode editorial styling and placeholder data (`VocabBreakdown`, `DailyGoal`, `WeekProgress`, `Deck`, `Story`).
- A notched bottom bar (`AppBottomBar` + docked `PracticeButton` with a daily-goal ring) hosted by `AppShell`.
- Deck screens: library (`DeckLibraryScreen`) and details (`DeckDetailsScreen`), backed by an in-memory `DeckStore`.
- The deck practice session (`DeckPracticeScreen`): five-card queue from the Wortliste, inline gap with exact / "fast richtig" / wrong checking, "Wort erfahren", collapsible translation, keyboard toolbar; results move the Leitner box in `WordListStore` ("Stapel nochmals durchsehen" runs it as early practice).
- An "Inhalte" tab (`ContentDashboardScreen`, four category cards, no decks) with a text library (`TextLibraryScreen`) and gap-text exercises (`TextExerciseScreen`, typed verb gaps or answer chips).
- Listening and grammar practice: libraries (`ListeningLibraryScreen`, `GrammarLibraryScreen`, "Meine Übungen"/"Fertig") and single-choice exercises (`ListeningExerciseScreen`, `GrammarExerciseScreen`) ending in the shared `SuccessFeedbackCard`, backed by an in-memory `PracticeProgress`.
- A sentence translation mode in the reader and in text exercises (`ReadingToolbar`, `SentenceTranslationSheet`).
- Simulated story narration in the reader ("Vorlesen" toggle, `NarrationPanel`, `PlaybackClock`) that marks the sentence being read.
- Grammar rules (`GrammarRulesScreen` with a level filter, `GrammarRuleDetailScreen`), opened from the "Grammatikregeln" category.
- A "Wortliste" tab (`WordListScreen`) with search, memory level indicator, simulated audio playback, quiet toggles and two sheets (`MemoryLevelLegendSheet`, `WordDetailsSheet`), backed by an in-memory `WordListStore`.
- The first pure-Dart domain code in `lib/domain/` (answer checking, sentence splitting, `*emphasis*` markup, Leitner intervals and next box, word forms in sentences).
- A Stories section: library (`StoryLibraryScreen`, with the weekly "Nachrichten" carousel of `NewsCard`s) and reader (`StoryReaderScreen`, also for news with subheadings) with tap-to-look-up words and a placeholder dictionary.
- A bespoke design system implemented in `lib/theme/app_theme.dart` using Google Fonts (Source Serif 4 and Figtree).
- Reusable UI components and modular dashboard widgets under `lib/widgets/` and `lib/screens/home/widgets/`.
- A widget and accessibility test suite in `test/widget_test.dart` verifying tap targets, Dynamic Type scaling, semantic accessibility, and visual track segments.

Dart SDK constraint: `^3.13.2` (see `pubspec.yaml`).

## Repository Structure

```
lib/
├── main.dart                      # Application entry point (SprachApp widget, ThemeData)
├── domain/                        # Pure Dart, no Flutter imports
│   ├── answer_check.dart          # Exact / "fast richtig" / wrong, edit distance
│   ├── emphasis.dart              # `*…*` markup for English forms in German prose
│   ├── leitner.dart               # Box count, intervals, next box, calendar-day diff
│   ├── sentences.dart             # Sentence ranges (translation mode, narration)
│   └── word_form.dart             # Word form in a sentence, form kind, labels, explanations
├── models/
│   ├── deck_store.dart            # In-memory deck state (ChangeNotifier) until Riverpod/Drift
│   ├── exercise_models.dart       # ExerciseText (gap markup), TextGap, ExerciseMode
│   ├── grammar_models.dart        # GrammarRule, sections, examples, pitfalls
│   ├── home_models.dart           # UI data models (VocabBreakdown, DailyGoal, WeekProgress, Deck, Story)
│   ├── news_models.dart           # NewsArticle (sections: heading + paragraph), NewsCategory
│   ├── practice_models.dart       # ChoiceExercise, PracticeKind, PracticeProgress
│   ├── reading_history.dart       # Stories the learner opened (feeds "Aus deinen Stories")
│   ├── story_models.dart          # WordEntry, WordMark, StoryText (+ headings), ReadingProgress
│   ├── sample_content.dart        # Synthetic placeholder content (until the content pack exists)
│   ├── speech_playback.dart       # Simulated TTS: which word/sentence is "playing"
│   ├── playback_clock.dart        # Simulated audio clock: narration, clips (play, skip, seek)
│   ├── word_list_models.dart      # VocabWord + "Zuletzt gesehen"/interval labels
│   └── word_list_store.dart       # In-memory Wortliste state, recordReview (ChangeNotifier)
├── screens/
│   ├── app_shell.dart             # Tab host (IndexedStack), notched bar, docked practice button
│   ├── content/
│   │   ├── content_dashboard_screen.dart # "Inhalte" tab: category grid
│   │   ├── text_library_screen.dart      # Exercise text carousels
│   │   ├── text_exercise_screen.dart     # Gap text: typed verbs or answer chips
│   │   └── widgets/
│   │       └── exercise_choice_sheet.dart # Picks the exercise mode
│   ├── decks/
│   │   ├── deck_library_screen.dart  # All decks, active first (pushed route)
│   │   ├── deck_details_screen.dart  # Progress, toggle, recent words, Stapel-Revue
│   │   ├── deck_practice_screen.dart # Practice session: gap card, translation, toolbar
│   │   └── widgets/
│   │       └── form_info_sheet.dart  # Grammar sheet for the gap's word class and form
│   ├── home/
│   │   ├── home_screen.dart       # Main dashboard layout (ListView, sections)
│   │   └── widgets/
│   │       ├── daily_goal_sheet.dart # Bottom sheet to pick the daily goal
│   │       ├── deck_tile.dart     # Deck card: icon in mastery ring, bolts, active state
│   │       ├── home_header.dart   # Language chip, Profil and Einstellungen buttons
│   │       ├── story_carousel.dart# Story card carousel, TypeCover, meta line helpers
│   │       ├── vocab_progress.dart# Four derived categories, segmented track, ledger
│   │       └── weekly_goal_card.dart # Week row (streak) + daily goal with gear
│   ├── grammar/
│   │   ├── grammar_rules_screen.dart       # Level filter + rule rows
│   │   └── grammar_rule_detail_screen.dart # Night Page rule reader
│   ├── practice/
│   │   ├── practice_library_screen.dart # Hören/Grammatik libraries: tabs + rows
│   │   └── choice_exercise_screen.dart  # Clip player or gap sentence, answer cards
│   ├── stories/
│   │   ├── story_library_screen.dart # Weiterlesen tile, Nachrichten, one carousel per topic
│   │   ├── story_reader_screen.dart  # Reader with per-word tap targets (stories and news)
│   │   └── widgets/
│   │       ├── narration_panel.dart   # Docked player: skip, play/pause, slider
│   │       ├── news_carousel.dart     # Endless paged news carousel + NewsCard
│   │       └── word_lookup_sheet.dart # Dictionary bottom sheet + neutral add button
│   └── words/
│       ├── word_list_screen.dart  # Wortliste tab: title, search + playlist button, rows
│       └── widgets/
│           ├── memory_level_indicator.dart    # Five dashes + level titles
│           ├── memory_level_legend_sheet.dart # Legend for the five levels
│           ├── playback_highlight.dart        # Playback mark, ListenButton, headword + speaker
│           ├── word_details_sheet.dart        # Translation, ledger, sentence, notes
│           └── word_list_item.dart            # Word row + WordToggle
├── theme/
│   └── app_theme.dart             # Color tokens (AppColors), typography (AppType), ThemeData
└── widgets/
    ├── action_buttons.dart        # PrimaryActionButton, OutlineActionButton
    ├── app_bottom_bar.dart        # Notched BottomAppBar, tabs, PracticeButton (FAB + ring)
    ├── back_bar.dart              # Back button bar for pushed screens
    ├── chevron_row.dart           # List row: title, summary, meta, chevron
    ├── difficulty_bolts.dart      # Three-bolt difficulty indicator
    ├── emphasis_text.dart         # TextSpan for `*…*` markup (italic w600)
    ├── hairline_track.dart        # Thin pill progress track
    ├── playback_controls.dart     # PlayPauseButton, PlaybackTrack (slider + times)
    ├── progress_ring.dart         # Circular progress ring (CustomPainter)
    ├── reading_toolbar.dart       # Bottom toolbar: "Vorlesen" and "Übersetzen" toggles
    ├── sentence_translation_sheet.dart # Sentence + German translation sheet
    ├── section_heading.dart       # Serif section heading with optional trailing widget
    ├── segmented_tabs.dart        # Neutral CupertinoSlidingSegmentedControl
    └── success_feedback_card.dart # Thumbs-up card closing every exercise

test/
└── widget_test.dart               # Component, accessibility, and unit tests
```

Platform runner projects (`android/`, `ios/`, `macos/`, `linux/`, `windows/`) are generated by Flutter tooling; do not hand-edit them unless configuring platform-specific build settings.

## Commands

Run all commands from the repository root:

```bash
flutter pub get                      # Install/update dependencies after editing pubspec.yaml
flutter run                          # Run on connected device or simulator (hot reload with 'r')
flutter analyze                      # Static analysis (flutter_lints rules, see analysis_options.yaml)
flutter test                         # Run all tests under test/
flutter test test/widget_test.dart   # Run the primary widget and accessibility test suite
flutter build apk|ios                # Platform release builds
```

> **Testing Note:** Widget tests must disable Google Fonts network requests to prevent flaky execution in offline or sandboxed environments:
> ```dart
> setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
> ```

## Planned Architecture (Not Yet Implemented)

The upcoming architectural migration will establish the following layers:

1. **Pure Dart Domain Layer (`lib/domain/`)**:
   - Zero Flutter imports (`dart:ui` or `package:flutter/...` prohibited).
   - Core domain models with explicit language indicators (`sourceLanguage`, `targetLanguage`) on all vocabulary entities.
   - Abstract `SpacedRepetitionEngine` interface supporting the 5-box Leitner system in v1 and enabling future FSRS comparison.
   - Pure review logic: exact answer evaluation, typo detection ("fast richtig"), error handling, and contextual hint dispatch.
2. **Local Persistence with Drift (`lib/data/`)**:
   - Local-first SQLite database using `drift`.
   - **Append-only Review Log**: The `review_log` table stores raw review events immutably.
   - **Derived Metrics**: The four Lingvist-style categories (*Verfügbare Wiederholungen*, *Wörter im Aufbau*, *Wörter gemeistert*, *Noch nicht angezeigt*) are calculated on demand from card status and due timestamps. They are never stored as static counter fields.
   - **Idempotent Content Import**: Content pack imports must be idempotent using stable, deterministic entity identifiers (slugs/UUIDs).
3. **State Management with Riverpod (`lib/presentation/`)**:
   - Manages practice session queues (due reviews first, then new words, then overflow practice), audio playback state, and navigation.
4. **Offline Content Pipeline (`tools/content_pipeline/`)**:
   - Standalone Dart CLI script (not executed inside the mobile app).
   - Ingests the BNC/COCA word frequency list (Excel/CSV) and generates a canonical, versioned `content_pack.json`.
   - Pre-generates sentences, blanks, distractors, and story texts offline via AI.

## Mandatory Development Rules

1. **No API Keys**: Never commit API keys or secrets to the repository or embed them in the client mobile app. Pipeline tools must consume keys via local environment variables. Future online features will communicate through a dedicated backend.
2. **Derived Vocabulary Counters**: The four vocabulary counts (*Verfügbare Wiederholungen*, *Wörter im Aufbau*, *Wörter gemeistert*, *Noch nicht angezeigt*) must **always be derived dynamically** from card state and scheduling dates. Never store them as persistent columns.
3. **Zero Runtime AI in v1**: The app executes entirely offline at runtime. No OpenAI, Anthropic, or Gemini calls may occur within the mobile client.
4. **Source of Truth Hierarchy**:
   - Product requirements and business logic are governed by `PRODUCT.md`.
   - Visual tokens, styling, layout grammar, and accessibility are governed by `DESIGN.md`.
   - Where code contradicts `PRODUCT.md` or `DESIGN.md`, the documentation wins. Do not update documentation to match accidental code regressions; record the discrepancy and align code to documentation.

## BNC/COCA Data Nuances & Edge Cases

When developing the content pipeline or parsing word frequency data:
- **Word Families vs. Lemmas**: BNC/COCA entries represent headwords accompanied by inflected forms (word families). Within each 1,000-word list (e.g. the 1k list), entries are ordered **alphabetically**, not by individual frequency rank. The pipeline must preserve headword association and map rank correctly.
- **Literal Value Collisions**: The headwords `"null"`, `"true"`, and `"false"` occur in frequency lists and are frequently misparsed by YAML, JSON, or Excel parsers as booleans or null values. Ensure explicit string type casting during data ingestion.
