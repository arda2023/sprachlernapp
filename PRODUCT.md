# Product

<!-- impeccable:product-schema 1 -->

## Platform

iOS and Android (Flutter). Targeted for release on the Apple App Store and Google Play; no web application. One unified custom design system across both platforms — the brand sets the visual language, not the OS (not Cupertino/Material-adaptive).

## Stack

- **Framework**: Flutter (SDK constraint `^3.13.2`, see `pubspec.yaml`).
- **Architecture (Planned)**: Pure Dart domain layer (`lib/domain/`) without Flutter dependencies, Riverpod for state management, local SQLite storage via Drift.
- **Runtime**: Self-contained client with local database; zero AI API calls at runtime. Content is pre-generated offline.

## Users

Serious adult German-speaking self-learners who want to actually acquire a language, not casually drill it. They find gamified, brightly-colored consumer apps (Duolingo named explicitly as the anti-reference) too childish and want something that feels substantive, focused, and respects their intelligence.

## Product Purpose

Helps adult German speakers build real vocabulary in English through connected learning loops:
1. **Stories**: Immersive reading texts with inline word lookup, where any word can be added to the learner's vocabulary queue ("zum Lernen hinzufügen").
2. **Decks (Stapel)**: Curated sentence-based practice with blanks, organized by topic.
3. **Daily Practice ("Gemischt")**: A centralized daily practice loop mixing words from active decks and story lookups.

Both stories and decks feed **one unified vocabulary and spaced-repetition system**. Success means a word genuinely progressing through structured intervals from unknown, through active practice, to mastered.

Additional target and source languages will follow in future releases; the data model enforces explicit language tags on all entities from day one.

## Positioning

Where gamified apps drill isolated vocabulary out of context, this app roots every word in something worth reading first (a story), then trains it deliberately through targeted sentence practice — a reading-led, editorial approach to vocabulary acquisition rather than a game-loop.

## Operating Context

Three core learning surfaces:

- **Themed practice decks (Aktive Stapel)**: Topic-based decks (e.g. Reisen & Unterwegs, Alltägliche Konversation, Medizin). Sentences with blanks trained through keyboard input, multiple-choice selection, or whole-sentence flashcards.
- **Story surface (Stories)**: Readable editorial stories across multiple domains. Tapping any word displays an inline translation and allows adding it to active vocabulary practice ("zum Lernen hinzufügen").
- **Central mixed session ("Gemischt")**: Accessible directly via the central Play button in the bottom navigation bar. Blends due reviews and new words across all active decks and story lookups into one seamless practice session.

## Capabilities and Constraints

- **Unified Vocabulary Model**: Decks and story-added words feed into a single spaced-repetition pool.
- **Four Derived Lingvist-Style Categories**:
  1. *Verfügbare Wiederholungen* (Available reviews / due repetitions)
  2. *Wörter im Aufbau* (Words in progress / actively learning)
  3. *Wörter gemeistert* (Mastered words)
  4. *Noch nicht angezeigt* (New words not yet seen)
  - **Assignment order** (makes the categories disjoint): never shown → *Noch nicht angezeigt*; otherwise due (`dueAt ≤ now`) → *Verfügbare Wiederholungen*; otherwise Box 5 → *Wörter gemeistert*; otherwise (Box 1–4) → *Wörter im Aufbau*. A Box-5 word that falls due therefore counts as a due repetition until reviewed, so the due count always matches the practice queue.
  - **Invariant**: The sum of these four categories always equals the total vocabulary count (all words in active decks plus story words added to learning).
  - **Dynamic Derivation**: These numbers are **always derived dynamically** from word status and scheduling timestamps; they are never stored as independent counter columns.
  - The former static "core vocabulary progress bar over 3,000 words" is discarded.
- **Spaced Repetition System (v1 Leitner)**:
  - 5-box Leitner system with default intervals of approximately 1 / 4 / 14 / 40 / 90 days (tunable).
  - Correct review advances the word by one box (+1).
  - Incorrect review resets the word to Box 1.
  - Box 5 represents "gemeistert" (mastered).
  - Encapsulated behind an interchangeable engine interface (`SpacedRepetitionEngine`) so alternative algorithms (e.g. FSRS) can be benchmarked against real learner data in later versions.
- **Answer Checking & Review Logic**:
  - Only the exact correct word allows the learner to proceed.
  - Minor typos display a "fast richtig" (almost right) hint and do not count as an incorrect attempt.
  - "Wort zeigen" (reveal word) counts as an explicit error and resets the card to Box 1.
  - In multiple choice (Lücke per Auswahl), the user keeps tapping options until the correct one is selected.
  - Contextual popups serve as hints when an answer has an incorrect grammatical inflection or is an unaccepted synonym.
- **Text Exercises (Inhalte → Texte)**:
  - Whole texts with gaps, offered in two modes: *Lückentext-Übungen: Verben* (only verb gaps; the learner types the inflected form, e.g. "dressed" for base "dress") and *Beliebige Wortart* (all gaps; the learner picks from answer chips, no keyboard).
  - Each gap shows its base word as a hint. Typed answers follow the general answer rules: exact match (case-insensitive, trimmed) solves the gap; a near miss (one edit, words of four letters or more) shows "Fast richtig", keeps the input and is not an error; anything else is an error and clears the input.
  - "Aus deinen Stories" offers exercise texts built from stories the learner has opened.
  - Pre-generated by the offline pipeline like all other content.
- **Sentence Translation**: In the reader and in text exercises a translation mode makes whole sentences tappable; a sheet shows the sentence and its German translation. Translations are pre-generated in the content pack; there is no runtime machine translation.
- **Exercise Types**:
  - Fill-in-the-blank via keyboard input (*Lücke per Tastatur*).
  - Fill-in-the-blank via multiple choice (*Lücke per Auswahl*).
  - Flashcard with the complete sentence (*Karteikarte mit ganzem Satz*).
- **Daily Goal & Queue Logic**:
  - The daily goal (e.g. 10 words) is a guiding recommendation, never a hard lockout.
  - Practice queue priority: (1) Due repetitions first (*Verfügbare Wiederholungen*), (2) New words second (*Neue Wörter*).
  - Continuing after goal completion: The learner is free to keep practicing. The queue serves remaining new words first, followed by early practice of upcoming due words (*Vorab-Üben*).
  - Early practice rule: Correct answers in early review do not advance the box; errors reset the word to Box 1.
- **Streak**:
  - Retained but quiet and understated.
  - Derived dynamically from the local review log based on local calendar dates (midnight rollover).
  - Rendered in neutral typography without cartoon flame graphics or high-pressure gamification.
- **Audio & Pronunciation**:
  - Words and sentences pronounced via platform native Text-to-Speech (TTS). Full-story continuous narration is deferred to post-v1.
- **Content Pipeline & Zero Runtime AI**:
  - Content is generated offline in advance via an automated AI pipeline (external script, not in the app).
  - Vocabulary selection and progression order are driven by the BNC/COCA frequency lists (List "1k" for v1, ~1,000 headwords).
  - The client application executes zero AI calls at runtime.
  - User text uploads with automated sentence extraction will be handled post-v1 via a dedicated backend service.
- **Storage**:
  - Strictly local-first in v1 (Drift SQLite database). Cross-device cloud synchronization is deferred post-v1.

## Open Decisions

- **Pricing Model**: Subscription, one-time purchase, or tiered access.
- **BNC/COCA Commercial Licensing**: Clarification of commercial usage rights for BNC/COCA word frequency data prior to public release.
- **FSRS Algorithm Adoption**: Evaluating FSRS against the 5-box Leitner system once empirical review logs exist.
- **Cloud Synchronization**: Backend architecture and conflict resolution strategy for multi-device sync.
- **User Text Uploads**: Ingestion pipeline and automated AI blanks/validation for user-provided texts.
- **Language Portfolio**: Selection of subsequent target/source language pairs and acquisition of corresponding frequency corpora.

## Brand Commitments

- Explicit anti-reference: must not resemble Duolingo's playful, saturated, gamified visual style.
- Dark mode as the exclusive foundation; no light theme.
- Named typefaces: Figtree (UI chrome/labels), Source Serif 4 (stories/editorial headlines/content).
- Named colors: near-black background tones (#0D0F14 / #1A1D26); Editorial Violet (#7B2CBF) strictly marks mastered words; Field Orange (#F77F00) strictly marks active/in-progress words.
- Chrome and interactive controls remain neutral; no decorative use of status inks.

## Evidence on Hand

- Word frequency list: BNC/COCA 1k list chosen as the canonical vocabulary foundation for English v1.
- Existing story and sentence content in the current codebase is synthetic placeholder data until the offline pipeline generates the v1 content pack.

## Product Principles

1. **Reading comes first**: Vocabulary is acquired in meaningful context, not drilled as an isolated list.
2. **Word state is always legible**: The progression from active to mastered is the app's central feedback loop.
3. **Respect the learner's intelligence**: No juvenile gamification, no cartoon mascots, and no high-pressure streak manipulation.
4. **One consistent design language**: The brand sets the visual rules across iOS and Android, not the platform OS conventions.
5. **Calm, editorial density**: Prioritize sustained reading comfort and quiet typography over high-stimulus UI elements.
6. **Vocabulary metrics are derived, never stored**: The four category counts reflect actual card states and review logs at all times.
7. **Predictable offline runtime**: Zero runtime AI dependencies in v1 ensure speed, privacy, and curated pedagogical quality.
