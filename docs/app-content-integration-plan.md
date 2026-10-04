# Plan: Erster Lernablauf mit echtem content.sqlite und dauerhafter user.db (Stand 04.10.2026)

**Status: Paket A und Paket B umgesetzt (Abschnitte 12–13).** Regeln: `PRODUCT.md`, `docs/srs.md`, `DESIGN.md` (Abschnitt Deck-Übung). Schichten: `ARCHITECTURE.md`. Schemas: `docs/content-schema.md`, `docs/user-schema.md`. Eingabe: internes Test-Pack `pipeline/out/curated_test_v1/content.sqlite` (status ok; 1 Stapel `allgemeine-sprache`, 164 Karten, 492 Sätze, 88 Satzzuordnungen mit `valid_alternatives`, `content_releases` = `pilot-60-curation-v1`, `schema_version` 1, Notiz „INTERNES TEST-PACK“).

## 1. Ausgangsstand vor Paket A/B (historisch)

| Bereich | Vorhanden | Lücke für diesen Ablauf |
|---|---|---|
| `lib/domain/answer_check.dart` | `checkAnswer` (exakt / fast richtig bei 1 Edit ab 4 Buchstaben / falsch), `editDistance` | keine geprüfte Alternative, keine falsche Form desselben Lemmas, Prüfreihenfolge (1)–(5) aus `docs/srs.md` fehlt |
| `lib/domain/leitner.dart` | Intervalle 1/4/14/40/90, `nextLeitnerBox(box 1–5, correct, early)`, `calendarDaysBetween` | kein Erstkontakt (Box 0 → 3/1), keine Hinweisregel, kein `due_at` als Beginn des lokalen Tages, kein `SpacedRepetitionEngine` |
| `lib/domain/word_form.dart` | Lücke über Regex-Heuristik, `formLabel`, `formExplanation` | entfällt für Content-Karten: Lücke kommt aus `gap_start/gap_end`, Label aus `cards.form_label_de` |
| `lib/screens/decks/deck_practice_screen.dart` | Übungs-UI (Lückenfeld, Toolbar, Fast richtig, Wort erfahren, Flash, Erfolgskarte), `PracticeCard`, `deckPracticeQueue` (erste 5 Wortlistenwörter) | Antwortlogik im `State`; Review über `WordListStore.recordReview` (In-Memory, kein Log, kein Erstkontakt); keine In-Session-Wiederholung; kein Synonymhinweis |
| `lib/screens/decks/deck_details_screen.dart` | Masthead, Legende, „Stapel lernen“, „Lerne mit diesem Stapel“, „Stapel-Revue“ | Zahlen aus `Deck`-Platzhalter; Übung zieht aus der Wortliste, nicht aus dem Stapel |
| `lib/models/deck_store.dart`, `word_list_store.dart`, `home_models.dart` | `ChangeNotifier`-Stores, `Deck`, `VocabBreakdown` (vier Zähler als View-Modell) | Daten aus `sample_content.dart`; kein Riverpod, kein Drift |
| `lib/main.dart`, `lib/screens/app_shell.dart` | `MaterialApp`, Stores als Felder der Shell | kein `ProviderScope`, kein Start-/Fehlerzustand für Datenbanken |
| `pubspec.yaml` | `google_fonts`, `cupertino_icons` | keine Datenbank-, Riverpod- oder Pfadpakete; keine Assets |
| `test/widget_test.dart` | Übungs-, Antwort- und Leitner-Tests auf Platzhalterdaten | keine Persistenz-, Content- oder Synonymtests |

Bestehendes bleibt die Grundlage: `checkAnswer`/`editDistance` (Fast-richtig-Regel), Intervalle und `calendarDaysBetween`, die komplette Übungs-UI und `VocabBreakdown`. Keine zweite Lernlogik: Die Antwort- und Box-Regeln wandern aus dem Screen-State in die Domain, der Screen ruft sie nur noch auf.

## 2. Funktionsumfang des ersten Ablaufs

Enthalten:
1. Internes englisches `content.sqlite` als Entwicklungsasset bereitstellen, beim Start in das App-Support-Verzeichnis installieren und schreibgeschützt öffnen.
2. Stapel „Allgemeine Sprache“ mit echten Karten (Stapeldetails, Stapelbibliothek, Stapelkachel auf Home).
3. „Lerne mit diesem Stapel“ und „Stapel-Revue“ auf echten Sätzen: Satz, Lücke (`gap_start`–`gap_end`), deutsche Übersetzung, `form_label_de`, `valid_alternatives`.
4. Antwortprüfung in der Reihenfolge Zielform → geprüfte Alternative → nachweislich andere Form desselben Lemmas → Fast richtig → falsch; Synonymhinweis; Wort erfahren.
5. Lernstand (`user_cards`) und `review_log` (inkl. `hint_used`) in Drift-`user.db`; nach Neustart wiederhergestellt.
6. Vier Zähler auf Home und Stapelzahlen in den Stapeldetails, abgeleitet aus `user_cards`, `deck_cards`, aktiven Stapeln und `now`.
7. In-Session-Wiederholung (einmal, etwa 3 Karten später) für Karten mit Fehler oder Hinweis.

Nicht enthalten (unverändert auf Platzhaltern): Gemischt (zentraler Play-Button), Wortliste, Stories, Inhalte-Tab, Audio, Tagesziel-/Streak-Anzeige aus `review_log`, Download/Sync/Release, Supabase-Migrationen. Die Wortliste zeigt bis zu ihrer Migration weiter Beispielwörter; das ist eine bekannte Inkonsistenz dieses Schritts (Abschnitt 9).

## 3. Synonym- und Hinweisregel (gemeinsam mit Persistenz)

Ein **Durchgang** ist der erste Durchgang einer Karte in einer Session. Er wird als reiner Dart-Zustand `ReviewPass` geführt und erzeugt genau **eine** `ReviewOutcome`, die genau **einmal** gespeichert wird.

| Eingabe (Reihenfolge nach `docs/srs.md`) | Wirkung im Durchgang | Anzeige |
|---|---|---|
| (1) Zielform (trim, case-insensitiv) | gelöst | Quiet Sage, „Richtig“ |
| (2) geprüfte Alternative dieser Karte-Satz-Lücke | `hintUsed = true` (bleibt), kein `errorCount`, nicht gelöst; ist es die erste Eingabe → `firstAttemptCorrect = false` | neutraler Hinweis „X passt hier auch. Gesucht ist ein anderes Wort: a…“ (bei einbuchstabiger Zielform ohne Buchstaben), Eingabe bleibt |
| (3) falsche Form desselben Lemmas | `errorCount += 1` | Flash + „Andere Form von „<lemma>“ – gesucht: <form_label_de>“ |
| (4) Fast richtig (nur gegen die Zielform) | kein Fehler | „Fast richtig – prüf die Schreibweise.“ |
| (5) sonst | `errorCount += 1` | Flash, „Falsch“ |
| „Wort erfahren“ | `revealed = true` (unabhängig von `hintUsed`) | Pale-Sky-Hinweis |

Box nach dem Durchgang (`scheduleReview`):
- `hintUsed` → Box 1, `due_at` = Beginn des nächsten lokalen Tages (Box-1-Intervall), in jedem Modus und aus jeder Box, auch beim Erstkontakt; zählt nicht als Fehler.
- sonst Fehler (`errorCount > 0` oder `revealed`) → Box 1.
- sonst sauber: Erstkontakt (Box 0) → Box 3; regulär → Box + 1 (max. 5); Revue → unverändert.
- `due_at` = Beginn des lokalen Tages (Antwortdatum + Intervall der neuen Box); bei unveränderter Box in der Revue bleibt `due_at` unverändert.

Einmaligkeit: `ReviewPass.complete()` liefert die Outcome nur beim ersten Abschluss; danach sind `submit`/`reveal` No-ops. Zusätzlich trägt die Outcome die beim Start des Durchgangs erzeugte `review_log.id` (UUID); `UserRepository.recordReview` fügt mit dieser ID ein und ist bei einem Duplikat ein No-op (Primärschlüssel). Die In-Session-Wiederholung läuft als eigener `ReviewPass` mit `logged = false` und wird nie gespeichert.

**Geklärte Regeln:**
- **W1 entschieden (04.10.2026):** „Fast richtig, dann exakt“ ist sauber (Erstkontakt Box 3, später regulärer Aufstieg); `first_attempt_correct = false`. Domain und Controller führen diese Werte getrennt.
- **W2 Hinweis in Revue bei Box 1.** Keine Abweichung, nur Bestätigung: Revue + Hinweis aus Box 1 → Box 1, `due_at` neu (nächster Tag), nicht unverändert. So umgesetzt.
- **W3 Kartenerstellung.** `docs/srs.md`: Karte entsteht „bei der ersten Anzeige“ (Box 0); `user-schema.md`: `user_cards` ist aus Erstellung + `review_log` rekonstruierbar, die Erstellung selbst wird aber nicht geloggt. Technisch unkritisch (Box 0 zählt als „Noch nicht angezeigt“); umgesetzt als `INSERT OR IGNORE` bei Anzeige.

## 4. Zielarchitektur für diesen Ablauf

```
assets/content/en/content.sqlite (gitignored, gestaged)
  └─ ContentPackInstaller → <AppSupport>/content/en/content.sqlite (read-only geöffnet)
       └─ ContentDatabase (Drift, read-only) → DriftContentRepository ┐
<AppSupport>/user.db → UserDatabase (Drift) → DriftUserRepository     ├─ Riverpod-Provider → Screens
lib/domain: AnswerEvaluator, ReviewPass, scheduleReview, deriveVocabBreakdown, buildDeckQueue ┘
```

- Beide Datenbanken laufen über **Drift + sqlite3** (eine Architektur). Content: `NativeDatabase` auf eine mit `OpenMode.readOnly` geöffnete Datei, zusätzlich `PRAGMA query_only = ON`; nur `customSelect`-Abfragen, keine Tabellendefinitionen, keine Migrationen. User: Drift-Tabellen mit `schemaVersion = 1`.
- Screens lesen nur Provider; kein SQL und kein Repository-Zugriff in Widgets.
- Domain bleibt ohne Flutter-Imports; Repositories sind dort als abstrakte Klassen definiert.

### Dependencies (per `flutter pub add`, aktuelle stabile Versionen beim Umsetzen)
- `flutter_riverpod` (Provider, Notifier)
- `drift`, `drift_flutter` (öffnet SQLite plattformgerecht, bündelt die sqlite3-Bibliothek)
- `sqlite3` (direkt für `OpenMode.readOnly` beim Content)
- `path_provider`, `path` (App-Support-Verzeichnis)
- `crypto` (SHA-256 des Assets für die Installation)
- `package_info_plus` (`review_log.app_version`)
- dev: `drift_dev`, `build_runner`

`device_id`: zufällige UUID-v4 aus `Random.secure()`, einmalig in `settings` gespeichert (kein `uuid`-Paket nötig). Gleiche Funktion erzeugt `review_log.id`.

### Domain-Schnittstellen (neu, pure Dart)

```dart
// lib/domain/content.dart
class ContentCard { String id; String form; String lemma; String lemmaId; String pos;
  String? formLabelDe; String? translationDe; String? cefrBand; }
class CardSentence { String cardId; String sentenceId; int position; String text;
  String? translationDe; int gapStart; int gapEnd; List<String> validAlternatives; }
class DeckSummary { String id; String slug; String titleDe; String? descriptionDe;
  String? cefrBand; int cardCount; }
class PracticeItem { ContentCard card; List<CardSentence> sentences; Set<String> otherFormsOfLemma; }
class ContentInfo { String lang; String version; int schemaVersion; String? notes; }

// lib/domain/repositories.dart
abstract class ContentRepository {
  ContentInfo info();
  Future<List<DeckSummary>> decks();
  Future<List<String>> deckCardIds(String deckId);            // nach deck_cards.position
  Future<List<PracticeItem>> practiceItems(List<String> cardIds);
}
abstract class UserRepository {
  Future<Map<String, UserCardState>> cardStates(Iterable<String> cardIds);
  Future<Map<String, UserCardState>> allActiveCardStates();   // disabled/retired = false
  Future<void> ensureCards(Iterable<String> cardIds, {required DateTime now, required String origin});
  Future<bool> recordReview(ReviewRecord record);             // false = Duplikat, nichts geändert
  Future<Set<String>> activeDeckIds(Iterable<String> deckIds); // ohne Zeile: aktiv
  Future<void> setDeckActive(String deckId, bool active);
  Stream<void> changes();                                     // für Zähler-Neuberechnung
}

// lib/domain/answer_check.dart (erweitert; checkAnswer bleibt für Textübungen)
enum AnswerVerdict { target, alternative, almost, wrongForm, wrong }
AnswerVerdict evaluateAnswer(String input, {required String target,
  required List<String> alternatives, required Set<String> otherFormsOfLemma});
String synonymHint(String input, String target); // „X passt hier auch. Gesucht ist ein anderes Wort: a…“

// lib/domain/review_pass.dart
enum ReviewMode { deck, revue, mixed, early }                  // review_log.mode
class ReviewPass { ReviewPass({required String logId, required String cardId,
  required String sentenceId, required int boxBefore, required ReviewMode mode,
  required DateTime startedAt, bool logged = true});
  AnswerVerdict? submit(String input, PracticeItem item, CardSentence s, DateTime now);
  void reveal(); bool get solved; bool get hintUsed; bool get revealed; int get errorCount;
  ReviewRecord? complete(DateTime now, LeitnerSchedule schedule); }   // nur einmal, sonst null

// lib/domain/leitner.dart (erweitert)
class LeitnerSchedule { List<int> intervalDays = [1, 4, 14, 40, 90]; }
({int boxAfter, DateTime dueAtAfter}) scheduleReview({required int boxBefore,
  required DateTime? dueAtBefore, required ReviewMode mode, required bool clean,
  required bool hintUsed, required DateTime answeredAtLocal, LeitnerSchedule schedule});
DateTime startOfLocalDay(DateTime local, {int plusDays = 0});

// lib/domain/srs_state.dart
class UserCardState { String cardId; int box; DateTime dueAt; bool disabled; bool retired; }
class ReviewRecord { /* alle review_log-Spalten aus docs/srs.md inkl. hintUsed */
  UserCardState after; }
VocabBreakdown deriveVocabBreakdown({required Set<String> activeDeckCardIds,
  required Map<String, UserCardState> cards, required DateTime now});
List<SessionEntry> buildDeckQueue({required List<String> deckCardIds,
  required Map<String, UserCardState> states, required DeckSessionKind kind,
  required DateTime now, int size = 5});        // learn: fällig (älteste) → neu; revue: Box ≥ 1
List<SessionEntry> scheduleRepeat(List<SessionEntry> queue, int index); // +3, einmal
```

`VocabBreakdown` (heute in `lib/models/home_models.dart`, importiert `flutter/widgets`) zieht nach `lib/domain/srs_state.dart` um; `home_models.dart` exportiert sie weiter, damit bestehende Imports gültig bleiben. Satzauswahl je Durchgang: der Satz mit Position `(Anzahl Logzeilen der Karte mod 3) + 1`; ohne Logzeile Position 1 (Routineentscheidung, Abschnitt 8).

### Data (neu)
- `lib/data/content/content_pack_installer.dart`: liest `assets/content/<lang>/content.sqlite` über `rootBundle`; fehlt das Asset → `ContentUnavailable.missing`. Kopiert nach `<AppSupport>/content/<lang>/content.sqlite`, wenn Datei fehlt oder SHA-256 abweicht (temporäre Datei, dann `rename`), merkt Hash in `<…>/content.sha256`.
- `lib/data/content/content_database.dart`: öffnet read-only, prüft `content_releases` (genau eine Zeile, `lang` passt, `schema_version == 1`), Pflichttabellen und -spalten (`decks`, `deck_cards`, `cards`, `senses`, `lemmas`, `sentences`, `card_sentences.valid_alternatives`, `dictionary_forms`). Fehler → `ContentUnavailable.corrupt` bzw. `.incompatible` mit Klartext.
- `lib/data/content/drift_content_repository.dart`: `ContentRepository`; `valid_alternatives` aus JSON-Text, ungültiges JSON → `incompatible`; `otherFormsOfLemma` aus `dictionary_forms` ⋈ `senses` (gleiche `lemma_id`, ohne Zielform).
- `lib/data/user/user_database.dart` (+ generiert `user_database.g.dart`): Tabellen `UserCards` (Spalten aus `user-schema.md`), `ReviewLog` (Spalten aus `docs/srs.md` inkl. `hint_used` default false, `id` Primärschlüssel), `DeckSettings`, `Settings` (`daily_goal`, `target_lang`, `device_id`, `updated_at`). Datei `<AppSupport>/user.db`.
- `lib/data/user/drift_user_repository.dart`: `recordReview` in **einer Transaktion**: `INSERT` in `review_log` (Konflikt auf `id` → Rollback, `false`), dann `UPDATE user_cards SET box, due_at, updated_at`. Keine Updates/Deletes auf `review_log`.

### Presentation (neu bzw. geändert)
- `lib/presentation/providers/database_providers.dart`: `contentRepositoryProvider` (`FutureProvider<ContentRepository>`, wirft `ContentUnavailable`), `userRepositoryProvider`, `clockProvider`, `appInfoProvider`.
- `lib/presentation/providers/deck_providers.dart`: `decksProvider` (Content + aktive Stapel + abgeleitete Zahlen → bestehendes View-Modell `Deck`), `vocabBreakdownProvider`, `deckActiveController`.
- `lib/presentation/practice/deck_session_controller.dart`: `NotifierProvider.family<DeckSessionController, DeckSessionState, DeckSessionArgs>`; hält Queue, aktuellen `ReviewPass`, Meldungstext, `committing`-Flag; `submit`, `reveal`, `next`; ruft `recordReview` genau einmal je geloggtem Durchgang, `ensureCards` beim Anzeigen.
- `lib/presentation/content_unavailable_view.dart`: ruhiger Zustand „Inhalte nicht verfügbar“ mit Ursache (fehlt / beschädigt / inkompatibel) im Stapelbereich; keine Platzhalterstapel.
- Geändert: `lib/main.dart` (`ProviderScope`), `lib/screens/app_shell.dart` (Stapel aus `decksProvider` statt `DeckStore(sampleDecks)`), `lib/screens/home/home_screen.dart` (Zähler und Stapelkacheln aus Providern), `lib/screens/decks/deck_library_screen.dart`, `lib/screens/decks/deck_details_screen.dart` (Consumer statt `DeckStore`/`WordListStore`), `lib/screens/decks/deck_practice_screen.dart` (rendert `DeckSessionState`; Antwortlogik raus aus dem State; Synonymhinweis in der vorhandenen Toolbar-Live-Region; Details-Button für Content-Karten vorerst ausgeblendet, da `WordDetailsSheet` `VocabWord` erwartet).
- Screens bleiben an ihren Pfaden unter `lib/screens/`; die Verschiebung nach `lib/presentation/` gehört zur späteren Gesamtmigration. `DeckStore` wird nach der Umstellung nicht mehr benutzt und entfernt; `WordListStore` bleibt für die Wortliste.

## 5. Bereitstellung des internen Packs

- **Asset-Pfad:** `assets/content/en/content.sqlite`, in `.gitignore`; im Repo nur `assets/content/en/README.md` (Herkunft, Hinweis „internes Testmaterial, nicht veröffentlichen“). `pubspec.yaml` deklariert das Verzeichnis `assets/content/en/`, damit der Build auch ohne Pack läuft.
- **Reproduzierbar stagen:** `tool/stage_content_pack.dart --from pipeline/out/curated_test_v1` kopiert `content.sqlite`, prüft vorher `finalization_report.json` (`status == ok`, SHA-256 der Datei, `schema_version`) und schreibt `assets/content/en/content.manifest.json` (Version, SHA-256, Quelle). Aufruf auf Windows (PowerShell) und macOS (Terminal) gleich: `dart run tool/stage_content_pack.dart --from pipeline/out/curated_test_v1`. Die App liest nie `pipeline/out/`.
- **Fehlerzustände:** Asset fehlt → „Inhalte nicht verfügbar: Kein Inhaltspaket installiert.“; Datei nicht als SQLite lesbar → „beschädigt“; `schema_version`/Pflichtspalten/`lang` passen nicht → „inkompatibel (gefunden …, erwartet 1)“. Home-Zähler und Stapelbereich zeigen dann denselben Zustand statt Zahlen; die übrige App (Stories, Inhalte, Wortliste auf Platzhaltern) bleibt bedienbar.
- **Internes Material:** Die Notiz aus `content_releases.notes` (`ContentInfo.isInternalTestPack`) wird im Stapeldetail-Footer angezeigt („Internes Test-Pack“), in allen Builds; keine Release-Sperre (E2).

## 6. Speicherung und Lebenszyklus

- **Neuinstallation:** Installer kopiert das Asset; `user.db` wird mit Schema v1 angelegt, `device_id` erzeugt. Keine Karten in `user_cards` → alle 164 Karten „Noch nicht angezeigt“.
- **Wiederöffnen:** Hash gleich → keine Kopie; `user.db` unverändert geöffnet. Neues Asset (anderer Hash) → Content-Datei ersetzt, `user.db` unberührt.
- **Atomar:** Review und Kartenstatus in einer Drift-Transaktion (Abschnitt 4); Absturz dazwischen hinterlässt beides oder nichts.
- **Abgebrochene Session:** Gespeichert sind nur abgeschlossene erste Durchgänge; ein offener Durchgang erzeugt nichts. Bei Anzeige angelegte Box-0-Karten bleiben „Noch nicht angezeigt“. Neustart baut die Queue neu aus `user_cards` und `due_at`.
- **IDs:** `user_cards.card_id` = `cards.id` aus `content.sqlite`; `review_log.sentence_id` = `sentences.id`. `user.db` speichert keine Inhaltstexte.
- **Unbekannte IDs:** `user_cards`-Zeilen ohne passende Karte im aktuellen Pack werden in Queues und Zählern ignoriert, nie gelöscht und nie umgeschrieben. Keine Übertragung von `be|be/VERB|be#befinden` auf die AUX-ID; Tombstones/`replaced_by` werden in diesem Schritt nicht ausgewertet (das Pack enthält keine).
- Nicht gebaut: Download, Update-Prüfung, Sync, Release-Kanal, Supabase-`hint_used`-Migration.

## 7. Umsetzungspakete

**Paket A – Domain und Daten (ohne UI-Änderung).** Begründung für die Trennung: Dependency- und Codegen-Einrichtung (Drift, build_runner, native sqlite3 in `flutter test` auf Windows und macOS) ist ein eigenes technisches Risiko und soll vor der UI-Umstellung grün sein.
- Domain: `content.dart`, `repositories.dart`, `review_pass.dart`, `srs_state.dart`, Erweiterungen in `answer_check.dart`, `leitner.dart`.
- Data: Installer, `ContentDatabase`, `DriftContentRepository`, `UserDatabase`, `DriftUserRepository`.
- `tool/stage_content_pack.dart`, `assets/content/en/README.md`, `.gitignore`, `pubspec.yaml` (Dependencies, Asset-Verzeichnis).
- Tests: `test/domain/review_pass_test.dart`, `test/domain/schedule_test.dart`, `test/domain/vocab_breakdown_test.dart`, `test/data/content_repository_test.dart`, `test/data/user_repository_test.dart`, Fixture `test/fixtures/content_mini.sql`.
- Abschluss: `flutter analyze`, `flutter test`, optionaler Smoke-Test gegen das gestagte echte Pack (überspringt sichtbar, wenn nicht gestagt).

**Paket B – Durchgängiger Lernablauf in der App.**
- Provider, `DeckSessionController`, `ContentUnavailableView`; Umstellung von `main.dart`, `app_shell.dart`, `home_screen.dart`, `deck_library_screen.dart`, `deck_details_screen.dart`, `deck_practice_screen.dart`; `DeckStore` entfernen.
- Tests: `test/deck_flow_test.dart` (Widget-Tests mit Fixture-Content und Datei-`user.db` im Temp-Verzeichnis); bestehende Deck-Tests in `test/widget_test.dart` auf Provider-Overrides umstellen.
- Abschluss: `flutter analyze`, `flutter test`, manueller Lauf auf Gerät/Simulator mit gestagtem Pack.

## 8. Routineentscheidungen (ohne Rückfrage festgelegt)

- Session-Größe „Lerne mit diesem Stapel“: wie heute 5 Karten; Revue ebenfalls 5.
- Satzwahl: rotierend über Position 1–3 nach Anzahl bisheriger Logzeilen der Karte.
- Stapel ohne `deck_settings`-Zeile gilt als aktiv.
- Stapelzahlen in den Details: `totalWords` = Karten im Stapel, `seenWords` = Box ≥ 1, `masteredWords` = Box 5 (wie heutiges View-Modell); keine gespeicherten Zähler.
- `response_ms` = Zeit von Kartenanzeige bis zur ersten Eingabe; `app_version` aus `package_info_plus`; Zeiten in UTC gespeichert, Tagesgrenzen in Ortszeit berechnet.
- Erfolgskarte: Hinweis-Karten zählen als „zurück auf Stufe 1“ (`DESIGN.md`).

## 9. Prüffälle

| Risiko | Test | Ebene |
|---|---|---|
| Echte Inhalte | Stapel „Allgemeine Sprache“ mit Kartenzahl aus Fixture; erste Karte zeigt Text, Lücke an `gap_start`, Übersetzung, `form_label_de` | Widget (B), Repository (A) |
| Zielform | exakt (andere Groß-/Kleinschreibung, Leerzeichen) → gelöst; Erstkontakt → Box 3; Box 2 → 3; Revue → unverändert | Domain (A), Widget (B) |
| Geprüfte Alternative | Hinweistext mit Anfangsbuchstabe, einbuchstabige Zielform ohne Buchstabe, Eingabe bleibt, nicht gelöst, `errorCount` 0 | Domain, Widget |
| Hinweis → Zielform | Box 1 aus Box 4 und beim Erstkontakt, `due_at` = nächster lokaler Tag, `hint_used` true, `first_attempt_correct` false, `revealed` false | Domain, Repository |
| Hinweis → Wort erfahren | `hint_used` und `revealed` true, Box 1, `error_count` unverändert durch die Alternative | Domain |
| Tippfehler | Fast richtig, kein Fehler, kein Hinweis; Alternative mit Tippfehler ist kein Hinweis | Domain |
| Falsche Form / falsch | `wrongForm` mit Lemma-Hinweis bzw. `wrong`; `errorCount` +1; Box 1 | Domain, Widget |
| Keine Doppelverbuchung | zweites `complete()` → null; doppelter `recordReview` mit gleicher ID → eine Logzeile, Box unverändert; Doppeltipp auf Enter/„Weiter“ im Widget → eine Zeile; In-Session-Wiederholung → keine Zeile | Domain, Repository, Widget |
| Neustart | Review speichern, Datenbank schließen, neu öffnen (neuer `ProviderContainer`) → Box, `due_at`, Logzeile und Zähler gleich | Repository, Widget |
| Abbruch | Session nach 2 von 5 Karten verlassen → 2 Logzeilen, angezeigte dritte Karte Box 0 | Widget |
| Schreibschutz | Schreibversuch auf Content-Verbindung schlägt fehl; Content-Datei-Hash vor/nach Session gleich | Repository |
| Pack fehlt/defekt/inkompatibel | jeweils Klartextzustand, keine Platzhalterstapel | Repository, Widget |
| Zähler | Invariante Summe = |C| + ungesehene Karten aktiver Stapel; Box-5-Karte fällig zählt als Wiederholung | Domain |

Alle Tests ohne Netzwerk und ohne `pipeline/out/`; Widget-Tests mit `GoogleFonts.config.allowRuntimeFetching = false`.

## 10. Offene Produktentscheidungen

- **E1 entschieden (04.10.2026):** „Fast richtig, dann exakt“ ist sauber (Erstkontakt Box 3, sonst Box + 1); `first_attempt_correct` bleibt wörtlich (`false`). Festgehalten in `PRODUCT.md` und `docs/srs.md`.
- **E2 entschieden (04.10.2026):** Internes Test-Pack auf eigenen Geräten und bei ausgewählten Testpersonen erlaubt, auch im Release-Build; keine Release-Sperre, keine öffentliche Freigabe (`PRODUCT.md`, Storage).
- Nicht blockierend, bleiben offen: Abschnitt-4-Fälle des Kurationsplans (Inhalt), Veröffentlichungsstatus alter IDs, Sync-Zeitpunkt (`PRODUCT.md`).

## 11. Akzeptanzkriterien

- Nach frischer Installation mit gestagtem Pack zeigt die App den Stapel „Allgemeine Sprache“ mit 164 Karten; ohne Pack einen verständlichen Zustand.
- Eine Session speichert je erstem Durchgang genau eine `review_log`-Zeile und aktualisiert `user_cards` in derselben Transaktion; nach Neustart sind Box, `due_at`, Zähler und Log unverändert.
- Synonymhinweis, Fast richtig, falsche Form, falsch und Wort erfahren verhalten sich nach Abschnitt 3; `hint_used` und `revealed` sind getrennt gespeichert.
- Kein SQL in Screens; `lib/domain/` ohne Flutter-Imports; Content-Datei wird nie beschrieben.
- `flutter analyze` ohne Befund, `flutter test` grün auf Windows und macOS.

## 12. Umsetzungsstand Paket A (04.10.2026)

Umgesetzt wie in Abschnitt 4/7, mit diesen Abweichungen vom Entwurf:
- `finalization_report.json` enthält keinen SHA-256 (und `content_releases.sha256` ist leer). `tool/stage_content_pack.dart` prüft deshalb Status `ok`, Schema und alle Tabellenzahlen gegen den Bericht und erzeugt den Hash erst im Manifest; Installer und `--verify` prüfen gegen das Manifest.
- `ContentManifest` und `validateContentSchema` liegen ohne Flutter-Import in `content_database.dart`, damit das Werkzeug sie mitbenutzt.
- Schnittstellen ergänzt: `ContentRepository.allCardIds()`, `UserRepository.reviewCounts()`, `reviewsFor()`, `deviceId()`, `close()`. `scheduleReview` nimmt `errorCount`, `revealed`, `hintUsed` statt `clean`; `ReviewPass` bindet Karte und Satz im Konstruktor (`submit(input, now)`); `scheduleRepeat` heißt `withRepeat`.
- Tippfehler („Fast richtig“) erkennt zusätzlich vertauschte Nachbarbuchstaben; `’` gilt wie in `form_norm` als `'` (auch in `checkAnswer` der Textübungen).
- „Wort erfahren“ vor der ersten Eingabe setzt `first_attempt_correct = false`.
- `recordReview` verlangt eine `user_cards`-Zeile (Anlage bei Anzeige) und die erwartete `box_before`, sonst Abbruch ohne Teiländerung. `review_log` per Trigger gegen `UPDATE`/`DELETE` gesperrt.
- Drift: `build.yaml` mit `store_date_time_values_as_text` und `generate_manager: false`. `ContentDatabase.close()` schließt das Roh-Handle auch, wenn Drift die Verbindung nie geöffnet hat.
- Randbedingung für Paket B: Vor einer Neuinstallation des Packs das offene Repository schließen (Windows ersetzt keine geöffnete Datei).


Antwortreihenfolge (Paket B): Zielform → geprüfte Alternative → nachweislich andere Form desselben Lemmas → fast richtig → falsch. Bekannte Formen kommen ausschließlich aus Content-Forminformationen; keine Endungsheuristik. Eine bekannte andere Form darf trotz geringer Zeichenentfernung kein Tippfehler sein.

## 13. Umsetzungsstand Paket B (04.10.2026)

- Riverpod-Provider besitzen Content-/User-Repositories; geteilte Verbindungen werden erst nach der letzten Freigabe geschlossen. Öffnen wartet auf das Schließen; ein fehlgeschlagenes Schließen sperrt eine Neuinstallation bis zum App-Neustart. Fehler beim Öffnen lassen sich explizit wiederholen.
- Bestehende Home-, Bibliotheks-, Detail- und Übungsscreens verwenden Provider/Controller. DeckStore ist ohne verbleibende Nutzer entfernt. Aktivierung, Statistiken und letzte Wörter kommen aus Repositories; Home-Zähler werden auch nach Resume/Datumswechsel neu abgeleitet.
- ReviewPass, buildDeckQueue, withRepeat und scheduleReview bleiben die einzige Antwort-/SRS-Logik. Der Controller speichert sofort nach korrekter Eingabe; Weiter wird erst danach freigegeben. ID und vollständiger ReviewRecord bleiben für Schreibwiederholungen erhalten. Abbruch ist während des Schreibens und nach einem Schreibfehler gesperrt; offene, ungelöste Durchgänge können ohne Log verlassen werden.
- Bekannte andere Lemmaformen werden vor Tippfehlern geprüft (Regressionsbeispiel walk/walks); keine geratenen Formen. Hinweise bleiben neutral und editierbar. Lange Hinweise stehen bei Bedarf vollständig über den Toolbar-Aktionen.
- Box 0 erscheint als „Neues Wort“. Wort-Details und Wortlisten-Menü sind für Content-Karten ausgeblendet; Audio bleibt deaktiviert, da es nicht Teil dieses Pakets ist. Internes-Test-Pack-Kennzeichen steht im Detail-Footer.
- Zusammenfassung zählt ausschließlich gespeicherte erste Durchgänge. Saubere Tippfehlerkorrekturen werden separat ausgewiesen; Hinweise zählen zu Stufe 1. Wiederholungen erzeugen keine weitere Logzeile.
- test/deck_flow_test.dart enthält Repository-Overrides, Controller-/Widget-Abläufe, Schreibfehler vor/nach Commit, Doppeltipps, Persistenz durch erneutes Öffnen einer echten user.db und Provider-Lebenszyklus. Bestehende Übungstests wurden von Wortlisten-Platzhaltern auf diesen Ablauf umgestellt.
- „Deck tiles show ring, bolts and active state“ erwartete zwei gleichzeitig gebaute Kacheln, obwohl eine außerhalb des lazy ListView-Bereichs lag (Expected 2, Actual 1). Der Test scrollt nun zu beiden aktiven Kacheln und prüft die inaktive Kachel samt Ring/Blitzen gezielt mit kontrollierten Repository-Daten.
- Android-Emulator API 36: echtes Pack mit 164 Karten geöffnet, fünf Karten korrekt geübt, Abschluss gesehen. Nach force-stop/Neustart: fünf eindeutige Reviews, fünf Karten in Box 3; UI zeigt 5 im Aufbau / 159 ungesehen. Keine macOS-/iOS-Prüfung.
- Unverändert außerhalb dieses Schritts: Gemischt, Wortliste, Stories, Tagesziel/Streak (weiter Beispielzustand), Cloud-Schema, Sync, Downloads, Audio und Pack-Inhalte.

## 14. Startseite, Gemischt und Wortliste (04.10.2026)

Die in Abschnitt 13 noch offenen drei Bereiche sind angebunden. `database_providers` besitzt weiterhin die gemeinsamen Repositories; `deck_providers` und `learning_providers` leiten Ansichten daraus ab. Screens führen kein SQL aus. `WordListStore` ist aus der App entfernt; eine kontrollierte Test-Fixture bleibt erhalten.

- Startseite: globale Zähler aus stabilen Karten-IDs gemäß bestehendem SRS-Vertrag; aktive Stapel bestimmen nur ungesehene Karten. Stapel-Fortschritt bleibt deckbezogen. Tagesziel zählt eindeutige tatsächlich reviewte Karten pro lokalem Tag, Woche zeigt dieselben Reviewdaten. Zielwert wird in `settings.daily_goal` gespeichert. Gemeinsamer Mitternachtstimer und Resume-Beobachter aktualisieren abgeleitete Ansichten auch ohne Datenbankschreiben. Fehler bleiben sichtbare Fehler, keine Nullwerte.
- Gemischt: fällige Karten zuerst, neue Karten über die unveränderte 4:1-/Lemma-/Formauswahl, anschließend Vorab-Üben. Der bestehende Controller übernimmt Antwortprüfung, sofortiges Speichern, Satzrotation und Sitzungswiederholungen. Keine alternative SRS-Implementierung oder Ersatzkarten bei leerer Queue.
- Wortliste: bekannte, nicht retirierte Karten ab Box 1; Box 0 ist noch nicht beantwortet. Deaktivierte Wörter bleiben zur Reaktivierung sichtbar. Form, Übersetzung und Beispielsatz stammen aus Content; Reviewanzahl und Reihenfolge aus echten Reviews (neueste zuerst), Suche bleibt erhalten. Favorit, Deaktivierung, Notiz und Playlist-Auswahl werden in user.db gespeichert. Unbekannte alte IDs bleiben gespeichert und werden nicht als erfundene Wörter angezeigt.
- Story-Lookup kennzeichnet seinen Prototypstatus und deaktiviert „Zum Lernen hinzufügen“. Keine Story-Migration. Bestehende Audio-Platzhalter sind weiterhin keine implementierte Audioinfrastruktur.
- Schema v3 ergänzt ausschließlich Notiz, Playlist-Auswahl und Tagesziel; siehe `docs/user-schema.md`. Keine Pack-, Auswahlregel-, Pipeline- oder SRS-Intervalländerung in diesem Schritt.

### Verifikation
Kleine SQLite-Fixtures in `test/learning_integration_test.dart` prüfen gemeinsame Reviewzustände, Doppelzuordnung, Aktivierung, Flags/Notizen/Playlist, Neustart, unbekannte IDs, Mitternacht/Resume, fehlendes Pack, DB-Fehler und leere Gemischt-Queue. Domain-Test prüft fällige Reviews vor neuen Karten, Vielfalt und erhaltenen Wiederholungsmodus. Migrationstest prüft v1 → v3 inklusive bestehender Werte; Android prüfte v2 → v3.

Android-Emulator API 36, echter UI-Ablauf auf **isolierter Kopie** unter `files/integration_smoke/user.db`: Home (19/10, 245 ungesehen, 19 im Aufbau) → Gemischt → „The computer in the classroom is already on.“ korrekt mit `on` beantwortet → Wortliste (20 beantwortete Wörter, on Stufe 3, 1 Review) → Favorit → force-stop/Neustart → Wort und Favorit erhalten. Kopie danach 21 Kartenstände/20 Reviews. Screenshots und DB-Vergleich liegen lokal unter `build/repository_integration/`.

Normale APK anschließend wieder installiert, ohne Deinstallation oder Datenreset. Original-DB: 20 Kartenstände, 19 Reviews, 0 Deck-Settings, 1 Settings-Zeile und 0 lokale Meldungen; **alle bisherigen Spalten und Zeilen identisch**, Schema 2 → 3. Asset-SHA256 weiterhin `ebc12c0d0ba4909cc070e7f1d2e9c27c08fc3744bb7317d781c8af4b1d1df9a5`. Keine iOS-Prüfung. Die neun redaktionellen Alt-Pilot-Fallgruppen bleiben unverändert offen (siehe `docs/everyday-v1-review.md`).

Ausgeführte Befehle (identisch in Windows PowerShell und macOS Terminal): `dart run build_runner build` erfolgreich nach Schemaänderung; `flutter analyze` → `No issues found! (ran in 2.0s)`; `flutter test --reporter expanded` → `00:16 +215: All tests passed!`; `flutter build apk --debug` → `Built build\app\outputs\flutter-apk\app-debug.apk`. `git diff --check` Exit 0, `git status --short` geprüft. Keine Pipeline-Tests, kein pub get, keine Commits/Pushes. Vorhandene Änderungen aus der vorigen Pack-Aufgabe bleiben erhalten.
