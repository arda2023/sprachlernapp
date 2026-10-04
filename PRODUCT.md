# Product

<!-- impeccable:product-schema 1 -->

## Platform

iOS and Android (Flutter). Targeted for release on the Apple App Store and Google Play; no web application. One unified custom design system across both platforms — the brand sets the visual language, not the OS (not Cupertino/Material-adaptive).

## Stack

- **Framework**: Flutter (SDK constraint `^3.13.2`, see `pubspec.yaml`).
- **Layers** (see `ARCHITECTURE.md`): pure Dart domain (`lib/domain/`, no Flutter imports); data in `lib/data/` (Drift `user.db` for learner state plus a read-only `content.sqlite` per language, joined by stable IDs); presentation with Riverpod; `supabase/` (migrations, Edge Functions); `pipeline/` (Python, offline, never part of the app).
- **Runtime**: Local-first client with local databases. The client never calls AI providers directly. Curated content is generated before release; runtime AI only via Supabase Edge Functions that call Vertex AI (project `sprachlernapp-510508`).

## Users

Serious adult German-speaking self-learners who want to actually acquire a language, not casually drill it. They find gamified, brightly-colored consumer apps (Duolingo named explicitly as the anti-reference) too childish and want something that feels substantive, focused, and respects their intelligence.

## Product Purpose

Helps adult German speakers build real vocabulary in English through connected learning loops:
1. **Stories**: Immersive reading texts with inline word lookup, where any word can be added to the learner's vocabulary queue ("Zum Lernen hinzufügen").
2. **Decks (Stapel)**: Curated sentence-based practice with blanks, organized by topic.
3. **Daily Practice ("Gemischt")**: A centralized daily practice loop mixing cards from decks and story lookups.

Both stories and decks feed **one unified vocabulary and spaced-repetition system**. Success means a card genuinely progressing through structured intervals from unknown, through active practice, to mastered.

v1 is English for German speakers. Spanish, French and Italian follow as updates. The data model is multilingual from day one: every entity carries explicit language tags.

## Positioning

Where gamified apps drill isolated vocabulary out of context, this app roots every word in something worth reading first (a story), then trains it deliberately through targeted sentence practice — a reading-led, editorial approach to vocabulary acquisition rather than a game-loop.

## Operating Context

Three core learning surfaces:

- **Themed practice decks (Aktive Stapel)**: Topic-based decks (e.g. Reisen & Unterwegs, Alltägliche Konversation, Medizin). Sentences with blanks trained through keyboard input, multiple-choice selection, or whole-sentence flashcards.
- **Story surface (Stories)**: Readable editorial stories across multiple domains. Tapping any word displays an inline translation and allows adding it to active vocabulary practice ("Zum Lernen hinzufügen").
- **Central mixed session ("Gemischt")**: Accessible directly via the central Play button in the bottom navigation bar. Blends due reviews and new words across all origins into one seamless practice session.

## Capabilities and Constraints

- **Card (the unit of learning)**: A card is one exact word form in one sense. "went" (go, past) is one card; "left" as *links* and "left" as *verließ* are two cards. The lemma or word family only links cards (Word Details "Andere Formen", detection of a wrong form) and never merges them. Every card has three example sentences, each containing exactly that form.
- **Activation**: A card is created at its first display in a deck session or when the learner taps "Zum Lernen hinzufügen" in a story. Decks and story-added words feed a single spaced-repetition pool.
- **Disabled cards**: A disabled card (Wortliste, practice menu) is excluded from every queue and every count.
- **Four Derived Lingvist-Style Categories**:
  1. *Verfügbare Wiederholungen* (Available reviews / due repetitions)
  2. *Wörter im Aufbau* (Words in progress / actively learning)
  3. *Wörter gemeistert* (Mastered words)
  4. *Noch nicht angezeigt* (New words not yet seen)
  - **Noch nicht angezeigt** are the forms of active decks that have no card yet, plus cards that have not been answered once (e.g. just added from a story).
  - **Assignment order** (makes the categories disjoint): not yet shown → *Noch nicht angezeigt*; otherwise due (`dueAt ≤ now`) → *Verfügbare Wiederholungen*; otherwise Box 5 → *Wörter gemeistert*; otherwise (Box 1–4) → *Wörter im Aufbau*. A Box-5 card that falls due therefore counts as a due repetition until reviewed, so the due count always matches the practice queue.
  - **Invariant**: The sum of these four categories always equals the total: all non-disabled cards plus the unseen forms of active decks.
  - **Dynamic Derivation**: These numbers are **always derived dynamically** from card state and scheduling timestamps; they are never stored as independent counter columns. Formulas: `docs/srs.md`.
  - The former static "core vocabulary progress bar over 3,000 words" is discarded.
- **Spaced Repetition System (v1 Leitner)**:
  - 5-box Leitner system with default intervals of approximately 1 / 4 / 14 / 40 / 90 days (tunable).
  - **First contact**: if the first attempt on a new card is correct, the card enters Box 3; otherwise (error, "Wort erfahren" or a synonym hint) Box 1. Intervals are unchanged.
  - Afterwards, a correct review advances the card by one box (+1); an incorrect review or a review solved after a synonym hint resets it to Box 1.
  - Box 5 represents "gemeistert" (mastered).
  - Encapsulated behind an interchangeable engine interface (`SpacedRepetitionEngine`) so alternative algorithms (e.g. FSRS) can be benchmarked against real learner data in later versions.
- **Answer Checking & Review Logic**:
  - Only the exact correct word form allows the learner to proceed (with the exception of "Wort erfahren").
  - Minor typos display a "fast richtig" (almost right) hint and do not count as an incorrect attempt.
  - **Wrong form**: a wrong form of the same lemma counts as an error and shows the hint `Andere Form von „<lemma>“ – gesucht: <Wortart, Form>`. The learner continues only with the exact form or "Wort erfahren". Any other answer, including a synonym that was not pre-checked for this gap, is an ordinary error.
  - **Synonym hint** (decided rule; pipeline, schema and app not implemented yet, see `NEXTSTEPS.md`): a fitting answer is distinguished from the target form the learner knew unaided. Only the target form completes the card regularly.
    - A typed answer that matches an alternative pre-checked offline for exactly this card, sentence and gap (`card_sentences.valid_alternatives`, `docs/content-schema.md`) is not "Falsch". It shows a neutral hint, e.g. target *about*, input *approximately*: „Approximately passt hier auch. Gesucht ist ein anderes Wort: a…“. For a one-letter target form the hint gives no letter: „… passt hier auch. Gesucht ist ein anderes Wort.“
    - The learner must then type the target form or use "Wort erfahren". The card counts as solved with help: Box 1, also on first contact and from any higher box, due at the start of the next local day with the default Box-1 interval (a configured interval applies instead). Further inputs in the same pass of the card neither reset it again nor add a log line. Bookkeeping: `docs/srs.md`.
    - The comparison is the same as for the target form (case-insensitive, trimmed). Unknown or unconfirmed alternatives stay ordinary errors; there is no runtime AI check of learner input. Own story contexts have no checked alternatives.
    - "Fast richtig" for typos is unchanged: it never shows a synonym hint and gets no new reset rule.
  - "Wort erfahren" (reveal word) counts as an explicit error and resets the card to Box 1.
  - In multiple choice (Lücke per Auswahl), the user keeps tapping options until the correct one is selected.
  - **In-session repeat**: a failed card, or a card solved with a synonym hint, returns once, about 3 cards later. The box is decided by the card's first pass only; the repeat changes neither box nor due date.
- **Practice Modes**:
  - **Gemischt**: (1) due cards of all origins, (2) new words from active decks up to the daily goal, (3) more new words, (4) early practice (*Vorab-Üben*). The deck toggle ("Stapel lernen") controls only new words here; seen cards are always reviewed.
  - **Lerne mit diesem Stapel**: only this deck's forms and sentences, never story-only cards; works even if the deck is inactive.
  - **Stapel-Revue**: seen cards only; a correct answer keeps the box, an error or a synonym hint sends the card to Box 1.
  - Early practice rule (Vorab-Üben and Stapel-Revue): correct answers do not advance the box; errors and synonym hints reset the card to Box 1.
- **Story Words**: The story sentence is the main context for the card in Gemischt. A local pre-check runs first (≤ 20 words, ≤ 1 subordinate clause, the word is present). A server-side AI check then decides whether the sentence is understandable without context; if not, the AI rewrites a sentence with the same form and sense. Until that is done the original sentence is used. "Inhalte" exercises never add words.
- **Text Exercises (Inhalte → Texte)**:
  - Whole texts with gaps, offered in two modes: *Lückentext-Übungen: Verben* (only verb gaps; the learner types the inflected form, e.g. "dressed" for base "dress") and *Beliebige Wortart* (all gaps; the learner picks from answer chips, no keyboard).
  - Each gap shows its base word as a hint. Typed answers follow the general answer rules: exact match (case-insensitive, trimmed) solves the gap; a near miss (one edit, words of four letters or more) shows "Fast richtig", keeps the input and is not an error; anything else is an error and clears the input.
  - "Aus deinen Stories" offers exercise texts built from stories the learner has opened.
  - Pre-generated by the offline pipeline like all other content.
- **Translations (three pre-generated layers in `content.sqlite`)**: (1) dictionary: form → senses with a German gloss; (2) token annotation: each token → the sense it has in context; (3) sentence translations. In the reader and in text exercises a translation mode makes whole sentences tappable; a sheet shows the sentence and its German translation. For imported texts, a missing dictionary entry or a sentence translation is requested on tap via a Supabase Edge Function that calls Vertex AI.
- **Text Import**: The learner pastes a text and a title (max. 5,000 words); the language is checked. Sentences are split on the device; word lookups that miss the dictionary and sentence translations are fetched on demand through Edge Functions (see `docs/backend.md`).
- **Exercise Types**:
  - Fill-in-the-blank via keyboard input (*Lücke per Tastatur*).
  - Fill-in-the-blank via multiple choice (*Lücke per Auswahl*).
  - Flashcard with the complete sentence (*Karteikarte mit ganzem Satz*).
- **Daily Goal**:
  - The daily goal (e.g. 10 words) is a guiding recommendation, never a hard lockout.
  - After the goal the learner may keep practicing: remaining new words first, then early practice (*Vorab-Üben*).
- **Difficulty**: One scale, `CefrBand`: Anfänger ⚡ (A1–A2), Mittleres Niveau ⚡⚡ (B1–B2), Fortgeschritten ⚡⚡⚡ (C1–C2).
- **News**: v1 ships timeless short texts. Weekly news is an open decision.
- **Streak**:
  - Retained but quiet and understated.
  - Derived dynamically from the local review log based on local calendar dates (midnight rollover).
  - Rendered in neutral typography without cartoon flame graphics or high-pressure gamification.
- **Audio & Pronunciation**:
  - Words and sentences are pronounced from pre-generated audio, produced with the Cloud Text-to-Speech API (model Gemini 2.5 Flash TTS, ADC login, no API key). Full-story continuous narration is deferred to post-v1.
- **Content Pipeline & Runtime AI Boundary**:
  - Content is generated offline in advance via an automated AI pipeline (external script, not in the app).
  - Sentences are AI-generated with automated QA (linter, blind gap test by a second model, 5 % manual sample). Alternatives proposed by the blind test are only candidates; each must pass a full-sentence check in the gap before it becomes a valid alternative (`docs/pipeline.md`). Frequency comes from the wordfreq word forms; BNC/COCA serves only as an English cross-check.
  - The client never calls AI providers directly. Curated content is generated before release. Runtime AI only via Supabase Edge Functions that call Vertex AI (project `sprachlernapp-510508`) for user-generated content: dictionary miss lookup, sentence translation on tap in imported texts, story-word sentence check/rewrite.
- **Accounts**: Learning works offline without an account. An email account is needed only for online features (import, AI checks); Google/Apple sign-in before release.
- **Storage**:
  - Local-first (Drift SQLite `user.db`, read-only `content.sqlite`). Cross-device synchronization is deferred; its timing is an open decision.

## Open Decisions

- **Pricing Model**: Subscription, one-time purchase, or tiered access.
- **Runtime AI free vs. premium**: Which Edge Function features are free, which premium, and the daily limits.
- **Voice for imported stories**: device TTS vs. online TTS.
- **Sync timing**: When cross-device sync arrives; backend and conflict resolution strategy.
- **Licences**: wordfreq (CC BY-SA) and BNC/COCA — commercial usage rights to be clarified before public release.
- **FSRS Algorithm Adoption**: Evaluating FSRS against the 5-box Leitner system once empirical review logs exist.
- **Weekly news**: Whether and how the weekly "Nachrichten" return after v1.
- **Language order**: Release order and corpora for Spanish, French and Italian.
- **Testguthaben endet ca. 22.11.2026**: EN-Hauptlauf und Audio vorher erzeugen (siehe `docs/pipeline.md`).

## Brand Commitments

- Explicit anti-reference: must not resemble Duolingo's playful, saturated, gamified visual style.
- Dark mode as the exclusive foundation; no light theme.
- Named typefaces: Figtree (UI chrome/labels), Source Serif 4 (stories/editorial headlines/content).
- Named colors: near-black background tones (#0D0F14 / #1A1D26); Editorial Violet (#7B2CBF) strictly marks mastered words; Field Orange (#F77F00) strictly marks active/in-progress words.
- Chrome and interactive controls remain neutral; no decorative use of status inks.

## Evidence on Hand

- Word frequency: wordfreq word forms are the basis for English v1; BNC/COCA 1k is kept as a cross-check.
- Existing story and sentence content in the current codebase is synthetic placeholder data until the offline pipeline generates the v1 content pack.

## Product Principles

1. **Reading comes first**: Vocabulary is acquired in meaningful context, not drilled as an isolated list.
2. **Word state is always legible**: The progression from active to mastered is the app's central feedback loop.
3. **Respect the learner's intelligence**: No juvenile gamification, no cartoon mascots, and no high-pressure streak manipulation.
4. **One consistent design language**: The brand sets the visual rules across iOS and Android, not the platform OS conventions.
5. **Calm, editorial density**: Prioritize sustained reading comfort and quiet typography over high-stimulus UI elements.
6. **Vocabulary metrics are derived, never stored**: The four category counts reflect actual card states and review logs at all times.
7. **Controlled runtime AI**: The client holds no AI keys and calls no provider; AI runs only in Edge Functions for user-generated content, while curated content stays pre-generated for speed, privacy and pedagogical quality.
