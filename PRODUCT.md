# Product

## Platform

iOS and Android (Flutter). Targeted for release on the Apple App Store and Google Play; no web application. One unified custom design system across both platforms — the brand sets the visual language, not the OS (not Cupertino/Material-adaptive).

## Stack

- **Framework**: Flutter (SDK constraint `^3.13.2`, see `pubspec.yaml`).
- **Layers** (see `ARCHITECTURE.md`): pure Dart domain (`lib/domain/`, no Flutter imports); data in `lib/data/` (Drift `user.db` for learner state plus a read-only `content.sqlite` per language, joined by stable IDs); presentation with Riverpod; `supabase/` (migrations, Edge Functions); `pipeline/` (Python, offline, never part of the app).
- **Runtime**: Local-first client with local databases. The client never calls AI providers directly. Curated content is generated before release; word taps follow checked context → exact private cache → a sufficiently simple general offline dictionary meaning → automatic Haiku only after versioned, account/device-specific opt-in. Opt-in is revocable in Settings; previous single requests are not durable consent. Technical storage failures stop this flow; missing/ambiguous meanings may proceed. No background word uploads, automatic retries or device-model downloads. Whole sentences retain explicit “Übersetzen”. Runtime AI only through authenticated Supabase Edge Functions calling direct Anthropic `claude-haiku-5-5`, with existing language gates, limits and private deduplication; no EU-only guarantee. Local results never establish learning identities. Current contract: [translation revision](docs/offline-translation-revision.md).

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

- **Card (the unit of learning)**: A card is one exact word form in one sense. "went" (go, past) is one card; "left" as *links* and "left" as *verließ* are two cards. The lemma or word family links cards (Word Details "Andere Formen", detection of a wrong form) and never merges their states. Separate editorial learning groups govern introduction. Every card has exactly one fixed practice sentence containing that form; repeats reuse it. Historical sentence links remain readable for reviews. A curated word (language + normalized form, independent of sense) has exactly one owner deck and one primary card. Word ownership counts describe the editorial inventory; the number of newly introduced learning targets can be smaller after grouping. Case variants and editorial spelling aliases cannot reserve a second word position.
- **Appwide learning groups (06.10.2026)**: versioned content metadata groups exact card meanings for introduction, independently of spelling aliases and word ownership. New learners receive the editorial head. Existing group state reserves the target: all learned members retain their own reviews, flags and notes; otherwise the oldest existing Box-0 member is reused. Disabled/retired state cannot be bypassed by introducing a synonym. No state merging or stored counters.
  - Deck progress, unseen counts, word list and new selection use this same projection. Learned multiple members still count individually; unseen groups count once. Deck totals therefore comprise retained active learned rows plus one eligible new representative per group, not raw ownership positions. Old packs keep singleton targets.
  - Story Add reuses an existing group target, otherwise the head. The tooltip retains the tapped word; practice uses the selected target's checked fixed sentence, never a rewritten story. Local cards join only through exact language/form/sense identity.
  - New targets are selected deterministically across topics and related concepts with three intervening new targets when possible. Relax to two, one, zero only when the available quota has no eligible candidate; input order breaks ties. A session freezes its order; due reviews and necessary repeats retain their rules. No replacement words to maintain a nominal count.
- **Activation**: A card is created at its first display in a deck session or when the learner taps "Zum Lernen hinzufügen" in a story. Decks and story-added words feed a single spaced-repetition pool.
- **Disabled cards**: A disabled card (Wortliste, practice menu) is excluded from every queue and every count.
- **Four Derived Lingvist-Style Categories**:
  1. *Verfügbare Wiederholungen* (Available reviews / due repetitions)
  2. *Übungen im Aufbau* (Words in progress / actively learning)
  3. *Gemeisterte Übungen* (Mastered words)
  4. *Noch nicht geübt* (New words not yet seen)
  - **Noch nicht geübt** are the forms of active decks that have no card yet, plus eligible Box-0 cards from active primary deck positions or explicit story learning, projected once per learning group. A displayed-only Box-0 secondary sense is preserved but excluded from automatic introduction and counts.
  - **Assignment order** (makes the categories disjoint): not yet shown → *Noch nicht geübt*; otherwise due (`dueAt ≤ now`) → *Verfügbare Wiederholungen*; otherwise Box 5 → *Gemeisterte Übungen*; otherwise (Box 1–4) → *Übungen im Aufbau*. A Box-5 card that falls due therefore counts as a due repetition until reviewed, so the due count always matches the practice queue.
  - **Invariant**: The sum of these four categories always equals the total: all resolvable non-disabled/non-retired learned cards, eligible Box-0 targets and unseen learning groups of active decks.
  - **Dynamic Derivation**: These numbers are **always derived dynamically** from card state and scheduling timestamps; they are never stored as independent counter columns. Formulas: `docs/srs.md`.
  - The former static "core vocabulary progress bar over 3,000 words" is discarded.
- **Spaced Repetition System (v1 Leitner)**:
  - 5-box Leitner system with default intervals of approximately 1 / 4 / 14 / 40 / 90 days (tunable).
  - **First contact**: a clean first pass on a new card enters Box 3; an error or "Wort erfahren" gives Box 1. Neutral checked synonyms do not consume the assessed first attempt. Intervals are unchanged.
  - Afterwards, a correct review advances the card by one box (+1); an incorrect review resets it to Box 1. Checked synonyms followed by the target advance normally.
  - Box 5 represents "gemeistert" (mastered).
  - Encapsulated behind an interchangeable engine interface (`SpacedRepetitionEngine`) so alternative algorithms (e.g. FSRS) can be benchmarked against real learner data in later versions.
- **Answer Checking & Review Logic**:
  - Only the exact correct word form allows the learner to proceed (with the exception of "Wort erfahren").
  - Minor typos display a "fast richtig" (almost right) hint and do not count as an incorrect attempt. A typo is one missing, extra or substituted letter or two swapped neighbouring letters, only for target forms of four letters or more; shorter forms get no typo tolerance. Answer checking runs entirely on the device, without AI or network.
  - "Fast richtig" followed by the exact form carries no learning penalty (decided 04.10.2026): without an error or "Wort erfahren" the card enters Box 3 on first contact and is promoted regularly afterwards. `first_attempt_correct` stays a literal observation (only an exact first non-synonym checked input is `true`), so the box is never derived from that field alone.
  - **Check order**: target → checked alternative → documented other form of the same lemma → typo → wrong. Only existing content form information establishes another form; never guess by stripping endings.
  - **Wrong form**: a wrong form of the same lemma counts as an error and shows the hint `Andere Form von „<lemma>“ – gesucht: <Wortart, Form>`. The learner continues only with the exact form or "Wort erfahren". Any other answer, including a synonym that was not pre-checked for this gap, is an ordinary error.
  - **Neutral synonym retry (06.10.2026)**: only a pre-checked alternative in this exact sentence's `valid_alternatives` qualifies. Show “Das passt auch. Gesucht ist hier ein anderes Wort. Versuch es noch einmal.” with neutral text, editable input, no error haptic, no prefix and no reveal.
    - It neither increments `error_count` nor sets `hint_used`, consumes the assessed first attempt, downgrades a box or schedules an extra repeat. Synonym → exact and repeated synonyms → exact are clean: first contact Box 3; due reviews advance; early/revue keep their box/date. Prior errors and reveal remain effective.
    - `first_attempt_correct` records the first non-synonym checked input (a typo still records false, with no scheduling penalty). `hint_used` remains false for these retries; historical true values and old review rows remain unchanged. One first-pass record only.
    - Groups never imply sentence-level acceptance. Unknown/unconfirmed alternatives remain errors, and local story contexts have no checked alternatives. No runtime AI.
  - "Wort erfahren" (reveal word) counts as an explicit error and resets the card to Box 1.
  - In multiple choice (Lücke per Auswahl), the user keeps tapping options until the correct one is selected.
  - **In-session repeat**: a failed or revealed card returns once, about 3 cards later. The box is decided by the card's first pass only; the repeat changes neither box nor due date.
- **Practice Modes**:
  - **Gemischt**: (1) due cards of all origins, (2) new words from active decks up to the daily goal, (3) more new words, (4) early practice (*Vorab-Üben*). The deck toggle ("Stapel lernen") controls only new words here; seen cards are always reviewed.
  - **Lerne mit diesem Stapel**: this deck’s learning targets and their fixed sentences; existing learned group members retain reviews, including exactly mapped local story cards; works even if the deck is inactive.
  - **Stapel-Revue**: seen cards representing this deck’s learning groups, including every already learned member; a correct answer keeps the box, an error sends the card to Box 1.
  - Early practice rule (Vorab-Üben and Stapel-Revue): correct answers do not advance the box; errors reset the card to Box 1.
- **Story Words (Package B, locally implemented)**: tapping only opens the translation; the explicit Add button persists a learning decision. Existing sense-specific state and its fixed sentence remain unchanged. An explicitly selected own context is separate, needs complete annotation/translation and editorial validation (≤20 words, ≤1 subordinate clause), and may be local-only. No mandatory cloud check or automatic fallback. "Inhalte" exercises never add words.
- **Text Exercises (Inhalte → Texte)**:
  - Whole texts with gaps, offered in two modes: *Lückentext-Übungen: Verben* (only verb gaps; the learner types the inflected form, e.g. "dressed" for base "dress") and *Beliebige Wortart* (all gaps; the learner picks from answer chips, no keyboard).
  - Each gap shows its base word as a hint. Typed answers follow the general answer rules: exact match (case-insensitive, trimmed) solves the gap; a near miss (one edit, words of four letters or more) shows "Fast richtig", keeps the input and is not an error; anything else is an error and clears the input.
  - "Aus deinen Stories" offers exercise texts built from stories the learner has opened.
  - Pre-generated by the offline pipeline like all other content.
- **Translations (three pre-generated layers in `content.sqlite`)**: (1) dictionary: form → senses with a German gloss; (2) token annotation: each token → the sense it has in context; (3) sentence translations. In the reader and in text exercises a translation mode makes whole sentences tappable; a sheet shows the sentence and its German translation. For missing translations in the reader or text exercises, tapping opens an explicit AI action; only confirming it sends one sentence and optional word form through an authenticated Supabase Edge Function to direct Anthropic `claude-haiku-5-5` (en/pt-BR → de). Existing pack translations remain first and local; validated display translations are reused from a private account-scoped cache before offering another explicit online request. Exact context, word occurrence, language, sense/form references and contract version define matches. Cached answers do not become reviewed learning content. Cache deletion preserves cards, stories and reviews; see `docs/story-translation-cache.md`.
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
  - Visual presentation follows `DESIGN.md`, including the derived streak display; no changes to scheduling or stored learning state.
- **Audio & Pronunciation**:
  - Words and sentences are pronounced from pre-generated audio, produced with the Cloud Text-to-Speech API (model Gemini 2.5 Flash TTS, ADC login, no API key). Full-story continuous narration is deferred to post-v1.
- **Content Pipeline & Runtime AI Boundary**:
  - Content is produced offline through the existing pipeline, either with optional AI or a fully annotated, reviewed editorial Create import. Gemini/ADC is not required for editorial production.
  - Sentences are AI-generated with automated QA (linter, blind gap test by a second model, 5 % manual sample). Alternatives proposed by the blind test are only candidates; each must pass a full-sentence check in the gap before it becomes a valid alternative (`docs/pipeline.md`). Frequency comes from the wordfreq word forms; BNC/COCA serves only as an English cross-check.
  - The client never calls AI providers directly. Curated content is generated before release. Runtime translation uses direct Anthropic `claude-haiku-5-5` only through authenticated Supabase Edge Functions with server-only Secrets and explicit opt-in for missing word/sentence translations. No EU-only guarantee or Gemini/Vertex fallback. Package 2C adds private learning-card creation only after explicit Add and separate revocable consent, through `create-learning-card`: reuse an exact existing meaning/form, otherwise preserve the original exercise sentence, with justified replacement for unsuitable contexts (mandatory for new cards from 1–2 words). Private AI provenance never counts as editorial approval. No AI for SRS, grading or public content generation. Deployment and device/linguistic acceptance are separate; see `docs/story-import-learning-package-2c.md`.
- **Accounts**: Learning works offline without an account. An email account is needed only for online features (import, AI checks); Google/Apple sign-in before release.
- **Storage**:
  - Local-first (Drift SQLite `user.db`, read-only `content.sqlite`). Cross-device synchronization is deferred; its timing is an open decision.
  - **Internal test pack** (decided 04.10.2026): a technically finalized internal content pack may run on the developer's own devices and for selected testers, release builds included; there is no blanket release-build lock. It is not a public content release.

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

- Visual rules are defined in `DESIGN.md` (redesign adopted 2026-10-20). Product and learning rules in this document remain binding.
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
7. **Controlled runtime AI**: The client holds no AI keys and calls no provider; missing translations run only in authenticated Edge Functions after explicit confirmation, while curated content stays pre-generated for speed, privacy and pedagogical quality.

## Übungsoberfläche und lokale Einstellungen (2026-10-04)
- Eingabe, letzte geprüfte Antwort und nicht editierbarer Hinweis sind getrennte Zustände. Erster gewöhnlicher Fehler bleibt vollständig sichtbar: Buchstaben nach Vorkommen im Ziel (nicht Position), 50 % Deckkraft; weitere Fehler zeigen zwei Ziel-Grapheme + … (bei zwei Zeichen nur eines, bei einem keines). Die erste Änderung startet einen neuen Versuch und erhält den neu eingegebenen Text. Fast richtig, falsche Form und Synonyme behalten ihre SRS-Regeln.
- Rückblick zeigt unveränderliche abgeschlossene Durchgänge, ohne erneute Prüfung/Buchung; die aktuelle Eingabe bleibt erhalten. Keine Vorschau zukünftiger Karten.
- Wort-Tooltips verwenden ausschließlich Satz-Tokenoffsets und verknüpfte Bedeutungen/Formen des Packs. Fehlende Annotation ist nicht verfügbar. Grammatik nutzt bekannte Formkennzeichen; vor Lösung werden weder Zielform noch Formenliste verraten.
- Favoriten und Deaktivierung sind lokale Zustände an stabilen Karten-IDs. Deaktivierung erhält Lernstand/Reviews und entfernt weitere Auswahl. Berichte (Kategorie, Karten-/Satz-ID, Packversion) und Feedback (1–5 Sterne), jeweils optional 2000 Zeichen, werden lokal gespeichert und nur auf ausdrücklichen Tap nativ geteilt; kein Versandziel.
- Motiv Automatisch/Hell/Dunkel gilt für die App. Diakritika einbeziehen ist standardmäßig an (bisherige strikte Prüfung); ausgeschaltet werden nur Akzentunterschiede ignoriert. Auto-Weiter und Grammatikformen sind standardmäßig aus. Auto-Weiter erfolgt erst nach Speicherung und sichtbarer Rückmeldung; Overlays/Rückblick/Navigation pausieren es, geöffnete Grammatik hat Vorrang.
- Gerätefunktionen ohne Implementierung (Benachrichtigungen, Audio, Spracherkennung) sind deaktiviert als „Noch nicht verfügbar“ sichtbar.

## Lösungsfeld und Aktionsleiste (2026-10-04)
- Auch gelöst und im Rückblick bleibt die Zielform hellblau im getönten Eingabekästchen, ohne Cursor oder Bearbeitung und mit gleicher Feldgeometrie.
- Genau eine rechte Hauptaktion: echte Eingabe leer → Wort erfahren; Text vorhanden → Eingeben; erfolgreich gespeichert → Weiter mit separatem hellblauem Haken links daneben. Hinweise zählen nicht als Eingabe; Aufdecken behält die Abtippregel. Speichern und Speicherfehler behalten ihre Sperren bzw. Wiederholungsaktion.
- Aktionswechsel dauern 140 ms, bleiben geclippt und rechts ausgerichtet, ausgehende Aktionen sind nicht bedienbar; reduzierte Animationen wechseln sofort. Die Leiste liegt über der Tastatur bzw. in der unteren SafeArea.
- Die sichtbare Abtipp-Erklärung und die Navigationszeile Aktuelle Karte samt Pfeilen entfallen; Rückblick bleibt per Wischen und Screenreader-Aktionen erreichbar.

Neue Karten werden vielfältig eingeführt: vier Inhaltswörter, dann höchstens ein
Funktionswort; pro Sitzung nur eine neue Karte je Lemma und Oberfläche. Bekannte
Lemmas folgen innerhalb ihrer Gruppe auf ungesehene. Bei kleinem Angebot kürzere
Sitzung statt Nebenbedeutungs-Refill (Details und Grenzfälle: `docs/srs.md`).
Fällige Reviews, SRS und In-Session-Wiederholungen behalten ihre bisherigen Regeln.

## Ein-Satz-Stapel: Bestandsübergang (04.10.2026)
160 reguläre Lernwörter im bestehenden Stapel, 264 erhaltene Karten-IDs. Die 53 mehrdeutigen Formgruppen haben ausdrücklich redaktionell gewählte Primärbedeutungen. 104 zusätzliche Senses bleiben getrennte Lernidentitäten: gelernte Karten weiter in Wortliste/Gemischt, bloß angezeigte Box-0-Zeilen ohne Storyentscheidung nicht neu einführen. Keine Lernstands- oder Reviewzusammenführung. Paket B ergänzt explizites Story-Hinzufügen und vollständige lokale Kontexte; Eigentümerstapel und 160 Primärplätze bleiben unverändert.

### Story learning — local Package B (04.10.2026)
The real annotated story library, Home and reader share the content repository. A word tap only reads its exact sentence/token/sense reference. Add awaits an atomic commit; new decisions start in box 0 without reviews or daily-goal progress. Existing state, flags, origin and curated context remain unchanged. Disabled cards require explicit reactivation; retired cards cannot be bypassed by local duplicates.
Explicit story additions appear immediately as “Ungelernt” in the word list and take priority after due cards in Mixed, independently of deck activation and the automatic 4:1 mix. Complete local cards remain available without a content pack. Exact later content counterparts do not create a second first encounter; existing conflicting states remain separate and visible. No context-selection UI or sync is included.

### Persönliche Sammlung „Aus Storys“ (24.10.2026)
Erst eine erfolgreich gespeicherte Story-Lernentscheidung macht die Sammlung sichtbar. Sie ist je Sprache aus `storyLearningAdditions`, historischen `storyWordSources` und Story-Ursprüngen abgeleitet, kein redaktioneller Content-Stapel. Bestehende Themenkarten werden über dieselbe ID verknüpft, auch wenn sie bereits gelernt wurden; wiederholtes Hinzufügen bleibt idempotent. Box, Fälligkeit, Flags und Historie werden dabei nicht zurückgesetzt. Deaktivierte/zurückgestellte Einträge bleiben sichtbar; die Übung verwendet nur die bisher zulässigen Ziele und unverändert Tagesrest, Fälligkeiten und Zählregeln. Aktuelle Sätze erscheinen in der Sammlung, historische Sätze bleiben an Reviews gebunden. In diesem Paket gibt es keine neue Entfernen-/Deaktivieren-Aktion in der Sammlung. Technische Lade-/Status-/Speicherfehler sind keine fehlende Lernannotation und lösen keine Generierung aus; ein bestätigter Save hängt nicht von einer nachträglichen Statusabfrage ab.

### Ausdrückliche Wiederholung privater Kartenerstellung (25.10.2026)
Ein laufender Erstellungsversuch wird durch eine Lease gegen parallele Aufrufe geschützt. Ein gespeichertes Ergebnis wird ohne neue Generierung übernommen. Nach einem bestätigten Fehlschlag darf der Nutzer ausdrücklich „Erneut versuchen“ wählen; bei unklarem Ausgang wird zuerst nach dem Ergebnis gesucht und erst nach Leaseablauf eine bewusste Wiederholung angeboten. Jede neue Generierung benötigt eine atomar zugeteilte neue Versuch-ID und die bestehenden Kostenlimits; veraltete Worker dürfen keinen neueren Versuch verändern. Keine automatische kostenpflichtige Wiederholung und keine pauschale 24-Stunden-Fehlersperre. Normale Übersetzungscaches und bestehende Lernstände bleiben unverändert.

## Formübungen: Inhaltsvertrag, Paket A (10.10.2026)
Die drei geplanten Verbenstapel verwenden Grundform (`base`, kein vollständiges Präsensparadigma), Präteritum (`past`) und Partizip (`past_participle`). Explizite Formziele referenzieren vorhandene oder neue Karten in derselben Karten-/SRS-Struktur. Wiederverwendung erhält ID, Gruppe und festen Satz; eine neue Funktion darf bei gleicher Schreibweise eine eigene Karte erhalten. Wortbesitz bleibt je Sprache/Oberfläche eindeutig. Lexikalische Begriffe und Übungen sind verschiedene Mengen; Mengenrichtwerte sind keine Zusage neuer Wörter.
Verben-Pakete A und B implementieren Content-Schema 4, Offline-Import, gemeinsame Formauflösung und lokale Formbindung. Schema-4-Staging und -Installation sind nach synthetischer Integrationsprüfung freigegeben; der Produktionspack bleibt Schema 3. user.db v5 erhält vorhandene Zustände und ergänzt nullable lokale Formmetadaten sowie getrennte Formbindungen. Ein festes Übungsziel behält genau einen Satz; geprüfte Alternativen bleiben lernstandsneutral. Technische Abnahme ist keine öffentliche Inhaltsfreigabe. Tatsächlicher Vertrag und Übergabe: [Verben-Paket A](docs/irregular-verbs-package-a.md).

## Formübungen und Wortzählung (Verben-Paket B, 10.10.2026)
`deckPracticeTargets` bestimmt alle Stapelansichten. Ordinary-Mitgliedschaften behalten die Lerngruppenregel; explizite Formziele bleiben die konkrete Karte und werden danach nicht erneut auf einen Gruppenkopf abgebildet. Dieselbe Karte wird global nur einmal gezählt; unterschiedliche Funktionen behalten unabhängige Boxen, Fälligkeiten, Flags, Notizen und Reviews.
Die vier SRS-Zahlen zählen **Übungen**. Daneben stehen **Wörter** und **Davon bereits geübt**, abgeleitet aus derselben berechtigten Kartenmenge. Explizite lexikalische Anker gelten für ihre gesamte belegte Sense-/Gruppenkomponente; ohne Anker bleibt der Altgruppen-Fallback. Kein Begriff zählt zugleich explizit und als Fallback. Bereits geübt heißt mindestens eine beantwortete Form, nicht Beherrschung aller Formen. Stapelfortschritt und Tagesziel zählen Übungen beziehungsweise unterschiedliche abgeschlossene, gespeicherte Übungsziele pro lokalem Tag, ohne Revue; globale Werte sind keine Summe der Stapel. Neue reguläre Sitzungen sind durch den globalen Tagesrest begrenzt; bei erreichtem Ziel bleiben explizites Weiterlernen und Revue möglich. Bereits aktive Sitzungen werden durch Zieländerungen oder Tageswechsel nicht ersetzt.
Neue Sitzungssegmente wählen höchstens eine Form je normalisiertem Lemma und Oberfläche. Bekannte Lemmas sind nur nachrangig, nicht gesperrt; fällige Formen bleiben unabhängig erreichbar. `form_only` wird durch Formansicht oder explizites Story-Add eingeführt. Feste Sätze, Sessionfreeze, bestehende Antwortprüfung und Leitner bleiben erhalten.
Story-Add bindet Sprache, Oberfläche, Sense und belegte Formfunktion. Fehlende/mehrdeutige Funktion erlaubt kein Raten über Wörterbuch-card_id; Übersetzung bleibt sichtbar. Eine deaktivierte oder bereits gebundene Form wird nicht durch eine Kopie umgangen. Alte lokale Identitäten ohne Funktion werden nicht automatisch migriert. Prüfnachweise und Auswahlvoraussetzungen: [Verben-Paket B](docs/irregular-verbs-package-b.md).

## Brasilianisches Portugiesisch: redaktionelles Paket 1 (18.10.2026)
- Zusätzliche Inhaltskennung ausschließlich `pt-BR`, deutsche Oberfläche und Übersetzungen. Englisch, seine IDs und Lernstände bleiben erhalten.
- Profil `pt-BR-editorial-v1`: modellfreier portugiesischer Tokenizer; keine automatische Satzgenerierung, Grammatik- oder Frequenzfreigabe. Brasilianischer Gebrauch, genau ein Satz, maximal ein Nebensatz, Niveau und Bindungen werden ausdrücklich redaktionell geprüft; technische Tests sind keine Sprachfreigabe.
- „Allgemeine Sprache“ beginnt später mit 20 redigierten Zielen; nach Abnahme ungefähr 160 ohne Auffüllpflicht. Dieses Paket liefert nur technische Fähigkeiten und eine leere Authoring-Vorlage, keine echten Lerninhalte.
- Erster privater pt-BR-Kanal hat keinen englischen Vorgänger. Mobile Sprachwahl und profilabhängige Antwortprüfung sind Inkrement 2; noch keine portugiesische Geräte-/Lernfreigabe.
