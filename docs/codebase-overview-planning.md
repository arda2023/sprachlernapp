# PROJEKT-ARCHITEKTUR & CODEBASE ÜBERSICHT

## 1. Tech-Stack & Kernprinzipien

- **Stand:** 11.10.2026, Commit `90c2930`, Repository/GitNexus-Name `sprachlernapp`, Dart-Paket `sprachapp`. Pfade sind relativ zum Repository. Grundlage: GitNexus `clusters`, `processes`, `context`, Prozess-Traces sowie aktuelle Quelldateien und Produktdokumentation.
- **Framework:** Flutter/Dart; Zielplattformen iOS und Android. `pubspec.yaml`: Dart-SDK-Constraint `^3.13.2`, `flutter_riverpod ^3.4.3`, `drift ^2.35.1`, `sqlite3 ^3.7.0`. Dies sind deklarierte Constraints, keine Aussage über installierte Versionen.
- **State Management:** Riverpod mit `ProviderScope`, `FutureProvider`, `StreamProvider`, `AsyncNotifier` und `Notifier`. Einige Nebenbereiche verwenden weiterhin lokale `ChangeNotifier`-Stores.
- **Persistenz:** Local-first. Schreibgeschütztes `content.sqlite` je Sprache, getrennt von `user.db` für Lernstand, Einstellungen, Reviews und vollständige lokale Karten. Verbindung über stabile IDs. Content-Schema 1–4 lesbar; `user.db` Schema 5. Laut Produktvertrag bleibt der Produktionspack vorerst Schema 3.
- **Navigation:** `SprachApp` → `AppShell`; vier Tabs: Home, Stories, Wörter, Inhalte. Lokaler Tabzustand; Detailansichten über Flutter `Navigator` und Screen-`open(...)`-Schnittstellen. Kein zentraler Router-Provider bzw. Router-Paket.
- **Fachlicher Kern:** Stories, Stapel und Gemischt teilen dieselben Lernkarten und denselben SRS-Zustand. Eine Karte repräsentiert eine konkrete Form/Bedeutung; Formziele können getrennte Funktionen besitzen. Leitner mit fünf Lernboxen, Box 0 für noch nicht beantwortete Karten.
- **Invarianten:** `lib/domain/` bleibt Flutter-frei; vier SRS-Zähler werden aus Karten/Fälligkeiten abgeleitet, nie gespeichert. Lexikalische Wörterzählung ist getrennt von Übungszählung. Reviews werden append-only und zusammen mit dem Kartenfortschritt atomar gespeichert. Lerngruppen steuern Einführung, verschmelzen keine bestehenden Lernstände.
- **Backendgrenze:** `pipeline/` ist eine Offline-Python-Pipeline. Supabase und Vertex AI gehören zum dokumentierten Backend-/Inhaltsvertrag; der aktuelle Client besitzt keine direkte KI-Anbindung. Laufzeit-KI nur für nutzergenerierte Inhalte über Supabase Edge Functions → Vertex AI; keine Schlüssel im Client.
- **Ist-/Zielzustand:** Persistierte Deck-, Wort- und Story-Lernpfade sind vorhanden. News, ergänzende Text-/Hör-/Grammatikübungen und Teile des Lesefortschritts nutzen noch Beispieldaten/In-Memory-Stores. Audio-Klassen sind Simulationen, keine fertige Audioengine. Der geplante `SpacedRepetitionEngine`-Vertrag aus `ARCHITECTURE.md` ist noch kein vorhandenes Interface; aktuell bestehen Domain-Funktionen und `LeitnerSchedule`.
- **Verbindliche Quellen:** `PRODUCT.md` (Produkt), `DESIGN.md` (Design/A11y), `ARCHITECTURE.md`, `docs/srs.md`, `docs/content-schema.md`, `docs/learning-groups-v1.md`, `docs/irregular-verbs-package-b.md`. Ältere Architekturabschnitte sind teilweise Zielbild; spätere Ergänzungen und aktuelle Schnittstellen beachten.

## 2. Modul- und Ordnerstruktur (`lib/`)

| Pfad | Zweck |
|---|---|
| `lib/main.dart` | Einstieg, ProviderScope, `SprachApp`, globale Darstellungseinstellung |
| `lib/domain/` | Entitäten, Repository-Verträge, Antwortprüfung, Leitner, Review-Durchgang, Lernzielprojektion, neue Kartenauswahl, Satz-/Formmetadaten |
| `lib/data/content/` | Content-Pack-Installation/-Validierung, read-only Datenbank, `DriftContentRepository`; `.g.dart` ist generiert |
| `lib/data/user/` | `UserDatabase`, Migrationen und `DriftUserRepository`; `.g.dart` ist generiert |
| `lib/data/learning/` | `PracticeItemResolver`: gemeinsames Inventar aus kuratierten und lokalen Karten samt Identitätsbindungen |
| `lib/presentation/providers/` | Repository-Lebenszyklus, Einstellungen, Decks, Wortliste, Fortschritt, Story-Lernen |
| `lib/presentation/practice/` | Sitzungszustand und `DeckSessionController` |
| `lib/presentation/content_unavailable_view.dart` | Gemeinsame Darstellung nicht verfügbarer Inhalte |
| `lib/screens/` | Tatsächliche Screens: `home/`, `decks/`, `stories/`, `words/`, `content/`, `practice/`, `grammar/`, `settings/`; `app_shell.dart` als Navigationseinstieg |
| `lib/models/` | Ansichtsmodelle, ergänzende Inhaltsmodelle, In-Memory-Fortschritt, Audio-Simulationen und `sample_content.dart`; teilweise Flutter-abhängig |
| `lib/widgets/` | Bereichsübergreifende Darstellungskomponenten; fachbezogene Komponenten zusätzlich unter `screens/*/widgets/` |
| `lib/theme/app_theme.dart` | Gemeinsames Theme, Farben und Darstellungstokens |

Außerhalb `lib/`: `test/` (Domain-, Repository-, Integrations- und UI-Tests), `pipeline/` (Inhaltserzeugung), `supabase/` (Backend), `tool/` (u. a. Pack-Staging), `assets/content/en/` (Pack-Assets), `docs/` (Verträge).

## 3. Datenmodelle & Entitäten (Domain / Models)

Zentrale Felder, bewusst ohne vollständige Konstruktoren oder Implementierungen; `?` bezeichnet nullable Typen.

| Typ | Datei | Zentrale Attribute |
|---|---|---|
| `ContentInfo` | `lib/domain/content.dart` | `lang, version: String`; `schemaVersion: int`; `notes: String?` |
| `DeckSummary` | `lib/domain/content.dart` | `id, slug, titleDe, practiceKind: String`; `descriptionDe, cefrBand: String?`; `cardCount: int` |
| `ContentCard` | `lib/domain/content.dart` | `id, lang, form, formNorm, lemmaId, lemma, pos, introductionScope: String`; `senseId, senseKey, translationDe, formKind, formLabelDe, identityFunction, lexicalTargetId: String?`; `learning: LearningTarget?`; `formTarget: FormTarget?` |
| `CardSentence` / `SentenceToken` | `lib/domain/content.dart` | Satz: `cardId, sentenceId, text: String`, `position, gapStart, gapEnd: int`, `translationDe: String?`, `validAlternatives: List<String>`, `tokens: List<SentenceToken>`; Token: `start, end: int`, `surface: String`, `translation: String?` |
| `PracticeItem` | `lib/domain/content.dart` | `card: ContentCard`; `sentences: List<CardSentence>`; `otherFormsOfLemma: Set<String>`; Zugriff auf festen `practiceSentence` |
| `LearningTarget` | `lib/domain/content.dart` | `groupId, primaryCardId, topic, note: String`; `related: List<String>` |
| `FormTarget` / `DeckPracticeTarget` | `lib/domain/content.dart` | Formziel: `id, cardId, senseId, form, function, lexicalTargetId: String`; Deckziel: `cardId: String`, `formTarget: FormTarget?` |
| `UserCardState` | `lib/domain/srs_state.dart` | `cardId: String`; `box: int`; `dueAt, createdAt: DateTime?`; `origin: CardOrigin`; `disabled, favorite, inPlaylist, retired, localOnly: bool`; `note: String` |
| `ReviewRecord` | `lib/domain/srs_state.dart` | `id, cardId, sentenceId, appVersion, deviceId: String`; `mode: ReviewMode`; `createdAt, dueAtAfter: DateTime`; `boxBefore, boxAfter, errorCount: int`; `firstAttemptCorrect, revealed, hintUsed: bool`; `responseMs: int?` |
| `VocabBreakdown` / `LexicalBreakdown` | `lib/domain/srs_state.dart` | Abgeleitete `int`: `due, building, mastered, unseen` bzw. `total, practiced` |
| `SessionEntry` | `lib/domain/srs_state.dart` | `cardId: String`; `repeat: bool`; `mode: ReviewMode?` |
| `ReviewPass` / `PassFeedback` | `lib/domain/review_pass.dart` | Durchgang: `id`, `item: PracticeItem`, `sentence: CardSentence`, `mode`, `startedAt`, `boxBefore`, `dueAtBefore`, Antwort-/Fehler-/Lösungszustand; Feedback: `verdict: AnswerVerdict`, `message: String?` |
| `PracticePreferences` | `lib/domain/preferences.dart` | `motif: AppMotif`; `dailyGoal: int`; `includeDiacritics, autoNext, showGrammar: bool` |
| `LocalSubmission` | `lib/domain/preferences.dart` | `id, text: String`; `createdAt: DateTime`; `category, cardId, sentenceId, packVersion: String?`; `rating: int?` |
| `StorySummary` / `StoryDocument` | `lib/domain/story_learning.dart` | Summary: `id, title, titleDe, level: String`, `minutes: int`; Dokument: `summary`, `revision: String`, `sentences: List<StorySentence>` |
| `StorySentence` / `StoryToken` | `lib/domain/story_learning.dart` | Satz: `id, text, translation: String`, `paragraph: int`, `tokens: List<StoryToken>`; Token: `index, start, end: int`, `surface: String`, optionale Karten-/Form-/Bedeutungsreferenzen, `contextApproved: bool` |
| `LearningIdentity` | `lib/domain/story_learning.dart` | `lang, formNorm, semanticAnchor: String`; `function: String?` |
| `StoryLearningCandidate` / `StoryAddResult` | `lib/domain/story_learning.dart` | Kandidat: Story-/Revisions-/Sprach-ID, Satz, Token, `card: ContentCard?`, `groupMembers: List<ContentCard>`, Prüfstatus; Ergebnis: `state: StoryAddState`, `cardId, message: String?` |
| `Deck`, `DailyGoal`, `WeekProgress`, `Story` | `lib/models/home_models.dart` | Deck: ID/Name, `difficulty: DeckDifficulty`, abgeleitete Zähler, `isActive`, `recentWords`; Ziel: `done, target: int`; Woche: `days: List<DayMark>`; Story: ID/Titel/Thema/Level, `readingMinutes` |
| `VocabWord` | `lib/models/word_list_models.dart` | `id`, `entry: WordEntry`, Satz/Übersetzung, `box`, `lastSeenAt`, `reviewCount`, `dueAt`, `lexicalKey`, Flags/Notiz |
| `WordEntry`, `StoryText`, `ReadingProgress` | `lib/models/story_models.dart` | Wort: `headword, partOfSpeech, translation, sourceLanguage, targetLanguage`; Text: `storyId`, Absätze/Überschriften; Fortschritt: `storyId`, `fraction: double` |
| `ChoiceExercise` | `lib/models/practice_models.dart` | `id`, `kind: PracticeKind`, Titel/Thema/Level, `prompt`, `options: List<String>`, `answer`, `explanation`, optionale Audioangaben, Sprachpaar |
| `ExerciseText` / `TextGap` | `lib/models/exercise_models.dart` | Text: `info: Story`, Absätze, `sourceStoryId: String?`; Lücke: `answer, base: String`, `wordClass: WordClass` |
| `GrammarRule` / `NewsArticle` | `lib/models/grammar_models.dart` / `lib/models/news_models.dart` | Regel: ID/Titel/Zusammenfassung, `level: GrammarLevel`, `sections: List<GrammarSection>`, Sprachpaar; News: ID/Titel, `category: NewsCategory`, Level/Lesezeit, `sections: List<NewsSection>`, Sprachpaar |

Wichtige Enums: `CardOrigin {deck, story}`, `ReviewMode {mixed, deck, revue, early}`, `DeckSessionKind {learn, revue, mixed}` in `srs_state.dart`; `AppMotif {automatic, light, dark}` in `preferences.dart`.

## 4. State Management & Logik (Riverpod Provider / Services)

**Provider-Inventar.** Tabellen nennen den beim Lesen sichtbaren State. Reine Datenprovider besitzen keine eigenen Schreibmethoden; Aktualisierung erfolgt reaktiv bzw. über Riverpod-Invalidierung.

| Datei | Provider / Notifier | State-Typ / öffentliche Schnittstelle |
|---|---|---|
| `lib/presentation/providers/database_providers.dart` | `contentRepositoryProvider`, `userRepositoryProvider` | `AsyncValue<ContentRepository>` / `AsyncValue<UserRepository>`; Repository-Verträge unten |
| dieselbe Datei | `contentInfoProvider`, `appInfoProvider` | `AsyncValue<ContentInfo>` / `AsyncValue<String>` (Version+Build) |
| dieselbe Datei | `clockProvider` | `DateTime Function()`; injizierbare Uhr; `retryDatabases(WidgetRef)` für fehlgeschlagene Verbindungen |
| `lib/presentation/providers/preferences_provider.dart` | `preferencesProvider` / `PreferencesController` | `AsyncValue<PracticePreferences>`; `save(PracticePreferences): Future<void>` |
| `lib/presentation/providers/deck_providers.dart` | `userChangesProvider` | `AsyncValue<int>` aus Änderungsstream; Revisionssignal für abgeleitete Daten |
| dieselbe Datei | `decksProvider` | `AsyncValue<List<Deck>>` |
| dieselbe Datei | `vocabBreakdownProvider`, `lexicalBreakdownProvider` | `AsyncValue<VocabBreakdown>` / `AsyncValue<LexicalBreakdown>` |
| dieselbe Datei | `deckActiveControllerProvider` / `DeckActiveController` | `AsyncValue<void>`; `setActive(String id, bool active): Future<void>` |
| `lib/presentation/providers/learning_providers.dart` | `learningNowProvider` | `DateTime`; Erneuerung bei Tageswechsel/App-Rückkehr |
| dieselbe Datei | `learningProgressProvider` | `AsyncValue<({DailyGoal goal, WeekProgress week})>` |
| dieselbe Datei | `learningNoticesProvider`, `wordListProvider` | `AsyncValue<List<String>>` / `AsyncValue<List<VocabWord>>` |
| dieselbe Datei | `wordActionsProvider` / `WordActions` | Service; `save(String id, {bool? favorite, bool? disabled, bool? inPlaylist, String? note}): Future<void>` |
| `lib/presentation/providers/story_learning_providers.dart` | `practiceResolverProvider` | `AsyncValue<PracticeItemResolver>`; lokale Karten auch bei ausgefallenem Content-Pack |
| dieselbe Datei | `storySummariesProvider` | `AsyncValue<List<StorySummary>>` |
| dieselbe Datei | `storyDocumentProvider(String id)` | Family; `AsyncValue<StoryDocument>` |
| dieselbe Datei | `libraryStoriesProvider` | `AsyncValue<List<Story>>`; Projektion der Story-Summaries |
| dieselbe Datei | `storyLearningServiceProvider` / `StoryLearningService` | `candidate(String story, String sentence, int token): Future<StoryLearningCandidate>`; `status(candidate)`, `add(candidate)`, `reactivate(candidate): Future<StoryAddResult>` |
| `lib/presentation/practice/deck_session_controller.dart` | `deckSessionControllerProvider(DeckSessionArgs)` / `DeckSessionController` | Auto-dispose Family; `DeckSessionState`; `start()`, `commit()`, `next()`, `disableCurrent(): Future<void>`; `submit(String): PassFeedback?`; `reveal()`, `clearWrongFormHint(): void` |

`DeckSessionArgs = ({String deckId, DeckSessionKind kind, int size})`. `DeckSessionState`: `pass: ReviewPass?`, `loading/committing/saved/finished: bool`, `error: Object?`, `message: String?`, `index/total: int`, `records: List<ReviewRecord>`, `snapshots: List<SessionSnapshot>`; abgeleitete `saveFailed` und `canLeave`.

**Repository- und Service-Verträge:**

| Schnittstelle / Datei | Wesentliche Operationen |
|---|---|
| `ContentRepository` — `lib/domain/repositories.dart` | `info: ContentInfo`; `decks(): Future<List<DeckSummary>>`; `deckCardIds(String): Future<List<String>>`; `deckPracticeTargets(String): Future<List<DeckPracticeTarget>>`; `allCardIds(): Future<Set<String>>`; `selectionCards(Iterable<String>): Future<List<ContentCard>>`; `practiceItems(List<String>): Future<List<PracticeItem>>`; `historicalSentence(String, String): Future<CardSentence?>`; `close()` |
| `UserRepository` — `lib/domain/repositories.dart` | `preferences()`, `savePreferences(...)`; `cardStates(...)`, `allCardStates(): Future<Map<String, UserCardState>>`; `ensureCards(..., now, origin)`; `recordReview(ReviewRecord): Future<bool>` (idempotent); `reviewsFor(String): Future<List<ReviewRecord>>`; `reviewCounts(...)`; `activeDeckIds(...)`, `setDeckActive(...)`; `setCardFlags(...)`; `saveSubmission(...)`, `submissions()`; `deviceId()`; `changes(): Stream<void>`; `close()` |
| `StoryContentRepository` — `lib/domain/story_learning.dart` | `storySummaries(): Future<List<StorySummary>>`; `storyDocument(String): Future<StoryDocument>`; `resolveStoryWord(String storyId, String sentenceId, int tokenIndex): Future<StoryLearningCandidate>` |
| `StoryLearningRepository` — `lib/domain/story_learning.dart` | `storyLearningStatus(...)`, `addStoryWord(..., now): Future<StoryAddResult>`; `explicitStoryAdditions(): Future<Map<String, DateTime>>`; `identityBindings(): Future<Map<String, String>>`; `localPracticeItems(): Future<List<PracticeItem>>`; `localHistoricalSentence(...): Future<CardSentence?>` |
| Implementierungen | `lib/data/content/drift_content_repository.dart`: `DriftContentRepository` implementiert Content- und Story-Content-Verträge. `lib/data/user/drift_user_repository.dart`: `DriftUserRepository` implementiert User- und Story-Learning-Verträge. |
| `PracticeItemResolver` — `lib/data/learning/practice_item_resolver.dart` | `load(UserRepository, ContentRepository?, {contentError})`; `deckPracticeIds`, `activePrimaryIds`, `practiceItems`, `historicalSentence`; synchrone `resolveTargets`, `projectExisting`, `eligiblePrimaries`, `bindingFor`, `storyStateId`; Inventar `cards`, `states`, `locals`, `additions`, `bindings`, `knownIds`, `notices` |
| `ContentPackInstaller` — `lib/data/content/content_pack_installer.dart` | `forApp`, `install`, `open`; prüft Kandidaten vor Pack-Austausch. `RepositoryOwner<T>` in `database_providers.dart` koordiniert Verbindungsbesitz/-schließung. |

**Domain-Logik:** `learning_groups.dart` (`LearningGroups.project`, Identitäts-/Wortprojektion); `new_card_selection.dart` (neue Ziele); `srs_state.dart` (`buildDeckQueue`, `buildMixedQueue`, `withRepeat`, abgeleitete Zähler); `review_pass.dart` (`ReviewPass.submit/reveal/complete`); `answer_check.dart` (Antwortklassifikation); `leitner.dart` (Box/Fälligkeit, `LeitnerSchedule`).

**Verbleibende lokale Stores:** `ReadingHistory` in `lib/models/reading_history.dart`: `Set<String> storyIds`, `markRead(String)`; `PracticeProgress` in `lib/models/practice_models.dart`: Abschluss-IDs, `isDone(String)`, `complete(String)`; beide nur In-Memory. `SpeechPlayback` in `lib/models/speech_playback.dart`: `String? playing`, `play/stop/isPlaying`; `PlaybackClock` in `lib/models/playback_clock.dart`: Position/Dauer/Status, `play/pause/toggle/stop/seek/skip`; beide Timer-Simulationen. Privater `_submissionsProvider` in `lib/screens/decks/widgets/local_submission_sheet.dart`: `AsyncValue<List<LocalSubmission>>`.

## 5. UI & Screens (Presentation)

Providerangaben umfassen Lesen und Schreiben; Übergabe durch Eltern ist ausdrücklich markiert.

| Screen / Datei | Konsumierte Provider bzw. Eingabeschnittstelle |
|---|---|
| `SprachApp` — `lib/main.dart` | `preferencesProvider` |
| `AppShell` — `lib/screens/app_shell.dart` | `preferencesProvider`, `libraryStoriesProvider`, `learningProgressProvider`; lokale `ReadingHistory`, `PracticeProgress`; Beispieldaten für Nebenbereiche |
| `HomeScreen` — `lib/screens/home/home_screen.dart` | `learningProgressProvider`, `vocabBreakdownProvider`, `lexicalBreakdownProvider`, `decksProvider`, `libraryStoriesProvider` |
| `DeckLibraryScreen` — `lib/screens/decks/deck_library_screen.dart` | `decksProvider`; Callback zum Öffnen eines Decks |
| `DeckDetailsScreen` — `lib/screens/decks/deck_details_screen.dart` | `decksProvider`, `deckActiveControllerProvider`, `contentInfoProvider`; Eingabe: Deck-ID |
| `DeckPracticeScreen` — `lib/screens/decks/deck_practice_screen.dart` | `deckSessionControllerProvider(args)`, `preferencesProvider`; zusätzlich `userRepositoryProvider`, `contentRepositoryProvider` für Begleitaktionen; Eingabe: Deck-ID/Übungsmodus |
| `WordListScreen` — `lib/screens/words/word_list_screen.dart` | `wordListProvider`, `wordActionsProvider`, `learningNoticesProvider` |
| `WordDetailsSheet` — `lib/screens/words/widgets/word_details_sheet.dart` | `wordListProvider`, `wordActionsProvider` |
| `StoryLibraryScreen` — `lib/screens/stories/story_library_screen.dart` | Keine direkten Riverpod-Zugriffe; `List<Story>` aus `AppShell`/`libraryStoriesProvider`, News und Öffnungs-Callbacks |
| `StoryReaderScreen` — `lib/screens/stories/story_reader_screen.dart` | Pack-Lesepfad: `storyDocumentProvider(id)`, `practiceResolverProvider`; Wortaktionen: `storyLearningServiceProvider`; alternative News-/Beispielpfade |
| `SettingsScreen` — `lib/screens/settings/settings_screen.dart` | `preferencesProvider` / `PreferencesController.save(...)` |
| `ContentDashboardScreen` — `lib/screens/content/content_dashboard_screen.dart` | Übergebene Inhaltskategorien/Öffnungs-Callbacks; keine eigenen Provider |
| `TextLibraryScreen`, `TextExerciseScreen` — `lib/screens/content/text_library_screen.dart`, `lib/screens/content/text_exercise_screen.dart` | Übergebene `ExerciseText`-Daten, `ReadingHistory`, Übungsmodus; keine zentralen Riverpod-Provider |
| `PracticeLibraryScreen`, `ChoiceExerciseScreen` — `lib/screens/practice/practice_library_screen.dart`, `lib/screens/practice/choice_exercise_screen.dart` | `ChoiceExercise`-Daten, `PracticeKind`, `PracticeProgress`; keine zentralen Riverpod-Provider |
| `GrammarRulesScreen`, `GrammarRuleDetailScreen` — `lib/screens/grammar/grammar_rules_screen.dart`, `lib/screens/grammar/grammar_rule_detail_screen.dart` | Übergebene `GrammarRule`-Daten; keine zentralen Riverpod-Provider |

## 6. Aktive GitNexus-Cluster & Datenflüsse

GitNexus-Cluster sind automatisch erkannte Symbolgruppen und überschreiten Ordnergrenzen. Die folgenden fünf sind für Architekturplanung besonders relevant; sie sind keine formalen Paketgrenzen.

| Cluster | Fachliche Rolle / typische Pfade |
|---|---|
| `Domain` | Lernzustände, Zielauflösung und Integration; umfasst auch Resolver-/Installer-Symbole aus `lib/data/` |
| `Content` | Pack-Schema, Validierung, Karten-/Satz-/Story-Zugriff; `lib/data/content/` und verbundene Inhaltsfunktionen |
| `User` | Lokale Persistenz: Karten, Reviewlog, Einstellungen, Storyentscheidungen, Kontexte, Lern-/Formbindungen; `lib/data/user/` |
| `Decks` | Einstieg in Stapel/Gemischt, Session-Ansichten und Form-/Grammatikhinweise; `lib/screens/decks/`, Teile von `lib/domain/` |
| `Sprachpipe` | Offline-Erzeugung, Annotation und Qualitätsprüfung der Inhalte; `pipeline/src/sprachpipe/` sowie indexierte Batch-Referenzkopien; kein Client-Laufzeitmodul |

**Typische Datenflüsse:**

1. **Inhalte lesen:** Pack-Asset → `ContentPackInstaller` → `ContentDatabase`/`DriftContentRepository` → `contentRepositoryProvider` → fachliche Provider → Screens. Lokaler Lernstand kommt separat aus `UserDatabase`/`DriftUserRepository`.
2. **Session starten:** `DeckPracticeScreen` → `DeckSessionController.start` → `PracticeItemResolver` → konkrete `DeckPracticeTarget`-/lokale IDs → `buildDeckQueue` oder `buildMixedQueue` → `PracticeItem`/`ReviewPass` → `DeckSessionState`. Die initiale Auswahl bleibt innerhalb der Sitzung stabil.
3. **Antwort speichern:** `submit` → `ReviewPass.submit`/Antwortprüfung → `commit` → `ReviewPass.complete` → `UserRepository.recordReview` → atomar Reviewlog + Kartenbox/Fälligkeit → `userChangesProvider` → erneuerte Deck-/Wort-/Fortschrittsansichten. GitNexus-Trace bestätigt `Submit → RecordReview`: Controller-`submit` → Controller-`commit` → Repository-Vertrag `recordReview`.
4. **Storywort lernen:** Story-ID/Satz-ID/Tokenindex → `StoryLearningService.candidate` → `StoryContentRepository.resolveStoryWord` → `status`/explizites `add` → `StoryLearningRepository.addStoryWord` → persistierte Entscheidung und gegebenenfalls lokale Karte/Kontext/Identitätsbindung → Resolver → Wortliste und Gemischt. Hinzufügen allein erzeugt keinen Review.
5. **Fortschritt/Einstellungen:** Karten + Reviewlog + aktive Decks + Lerngruppen/Formziele + Uhr → abgeleitete SRS-/Wort-/Tageswerte. `PreferencesController.save` → `UserRepository.savePreferences` → `preferencesProvider` → Appdarstellung/Übungseinstellungen.

**Prüfstand und Grenzen:** Indexaktualisierung erfolgreich auf `90c2930`; CLI-Ausgabe: `14,312 nodes | 30,786 edges | 701 clusters | 393 flows`. Ressourcen zeigen begrenzte bzw. zusammengefasste Cluster-/Prozesslisten; diese Zahlen sind nicht direkt mit CLI-Clusterzahlen vergleichbar. Einzelne MCP-Antworten meldeten nach Aktualisierung noch den vorherigen Stand. Der Analyzer meldet begrenzte Prozessabdeckung und nicht aufgelöste Aufrufe; beim Controller-`submit` ausdrücklich `lower-bound`. Daher wurden Schnittstellen, Provider und Screen-Zuordnungen zusätzlich am aktuellen Quelltext geprüft. Diese Übersicht ist eine Planungsgrundlage, kein vollständiger Callgraph.
