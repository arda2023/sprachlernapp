# Inhaltsladen: Drift-Warnung, Sprachwechsel, Home-Ladezustände, Sessionstart

Stand: 19.10.2026. Ausgang `87b76df` (Branch `codex/haiku-vertex-eu`), Arbeitsbaum sauber bis auf fremdes, unberührtes `published-baseline-transfer/`. Lokale Tests, Analyse, Packtest und Stage-Prüfung **bestanden**. Host- und Simulatormessung vorher/nachher liegen vor. **Keine iPhone-Messung, kein Geräte-PASS** (Grund siehe unten).

## Ursachen (gemessen, nicht vermutet)

Messsonde `build/content_loading_performance/perf_probe_test.dart` (lokal, nicht committed): echtes en-Pack (26 198 016 B), synthetisches pt-BR über den echten Update-Pfad, temporäre user.sqlite mit 300 synthetischen Lernständen, Settings-Statuszeilen und Home-Provider abonniert. Gemessen werden Öffnungen je Sprache, user-SQL-Abfragen, Änderungsereignisse und der größte Abstand zwischen 1-ms-Timer-Ticks auf dem UI-Isolate („UI-Gap“, zeigt synchrone Blockaden).

1. **Lifecycle-Fehler (Drift-Warnung, Ursprung `RepositoryOwner.acquire`)**: Der Sprachwechsel invalidiert `contentRepositoryProvider` vor dem Sprach-Key. Der Rebuild akquiriert den Owner der **alten** Sprache erneut, wartet auf `pause` und öffnet nach `resume()` den alten Pack mit voller Validierung, der anschließend sofort wieder geschlossen wird. Beleg: en→pt-BR zählte eine zusätzliche en-Öffnung, pt-BR→en eine pt-Öffnung; diese Instanz überlappte mit dem neuen Pack. Kein Datenverlust (schreibgeschützte Verbindung), aber volle Validierungsarbeit im Hintergrund.
2. **Doppelte Öffnung desselben Packs**: `selectLanguage` öffnete den Zielpack als Kandidat, schloss ihn, der Owner öffnete ihn erneut; danach öffnete `languageInstallationProvider(lang)` dieselbe Datei ein drittes Mal als **unverwaltete** Zweitverbindung neben der aktiven. pt-BR→en: 3–4 en-Öffnungen à ~3,5 s (Host-JIT).
3. **Doppelte Vollvalidierung je Öffnung**: `ContentDatabase.openInBackground` validierte die bereits gehashten, inhaltsadressierten Bytes zweimal vollständig (2 × ~1,55 s JIT; dominiert von Satz- und Formprüfungen, `quick_check` nur 25–160 ms).
4. **Synchrones Hashen auf dem UI-Isolate**: `ContentPackInstaller._matches` las und hashte 26 MB synchron (UI-Gap ~300 ms JIT) bei jedem Öffnen des Bootstrap-Packs.
5. **Leere Änderungsereignisse beim Sessionstart**: `ensureCards` schrieb per `insertOrIgnore` auch für vorhandene Karten; Drift meldet `user_cards` dann als geändert → `userChangesProvider` → Resolver, Stapel und Zähler werden komplett neu projiziert, genau im Fenster der Öffnungsanimation (UI-Gap 321 ms JIT).
6. **O(Ziele × Lernstände) in `LearningGroups.project`**: Je Ziel wurde ein neues `LearningGroups` gebaut und der Mitgliederindex über alle Lernstände neu erzeugt; `activePrimaryIds` läuft so für 3 654 Ziele synchron, und Vokabel- wie Lexikzähler rufen es je Änderung auf (Home-UI-Gap 363 ms JIT).
7. **Wiederkehrende Home-Ladebalken**: Commit `8b43a69` setzte `skipLoadingOnReload/Refresh: false` auf Home, Stapelbibliothek und -details, um fremdsprachige Altdaten zu verhindern. Folge: jede Nutzeränderung und jedes App-Resume (`learningNowProvider`) ersetzt sichtbare Daten durch einen Indikator.

### Drift-Warnung eingeordnet

Drift zählt offene Instanzen je **Klasse** (`ContentDatabase`), nicht je Datei. Ursprünge vorher (13 Warnungen): 6 × `languageInstallationProvider` (u. a. gleiche Datei wie aktiv: Fehler 2), 5 × Kandidatenöffnung in `selectLanguage`, 2 × verspätete Owner-Akquise (Fehler 1). Nachher 6: Zielvalidierung neben dem noch offenen alten Pack (beabsichtigt: Ziel wird geprüft, bevor der alte Reader schließt; andere Sprache, unveränderlich) und Statuszeile der nicht aktiven Sprache (eigener Owner, sofort geschlossen). Die Warnung wird nicht unterdrückt (`dontWarnAboutMultipleDatabases` unverändert). Mehrere `ContentDatabase` sind kein Fehler an sich; gleichzeitiges Öffnen derselben Datei ohne Owner und das Wiederöffnen nach Dispose waren es.

## Umsetzung

- `RepositoryOwner`: `lease()` ohne Provider-Scope, `acquire` nutzt sie; idempotente Freigabe. Eine Öffnung, deren Leases vor dem eigentlichen `open()` alle endeten, wird abgebrochen statt nachgeholt. Pause-/`closed()`-Barriere und Close-Fehler-Sperre unverändert.
- `selectLanguage`: Zielvalidierung über einen Owner-Lease desselben Keys (`contentKeyFor`), den der neue Scope teilt; Freigabe in jedem Pfad. Vor `resume()` wird der Reader-Scope synchron auf den neuen Key umgebaut. Reihenfolge Validierung → Pause → Close-Barriere → Persistenz → Rollback unverändert.
- `languageInstallationProvider`: aktive Sprache aus der geteilten Verbindung (`contentInfoProvider`), andere Sprache nur über ihren Owner. Fehlertexte unverändert.
- `openInBackground`: Vollvalidierung einmal; die tatsächlich genutzte Verbindung prüft `quick_check` und Release-Identität (Sprache, Version, Schema). Alle Inhalts-, Hash- und Manifestprüfungen bleiben.
- `_matches`: SHA-256 gestreamt im Hintergrundisolate.
- `ensureCards`: fügt nur fehlende Zeilen ein (aus der vorhandenen Guard-Abfrage, keine Zusatzabfrage); vorhandene Zustände unverändert, keine Leer-Änderung.
- `LearningGroups`: Mitgliederindex einmal je Instanz (Eingaben werden nach Konstruktion nicht verändert); `PracticeItemResolver` nutzt eine Instanz.
- `watchContentStable`: Home (Fortschritt, Zähler, Stapel), Stapelbibliothek und -details zeigen den bereits angezeigten Wert während einer Neuberechnung nur bei gleicher Sprache **und** Generation **und** identischem zuletzt angezeigtem Wert. Sprach-/Versionswechsel oder nie angezeigte Werte zeigen weiter den Ladezustand. Nur Keys/Referenzen je Ansicht, kein Datencache.

Keine Änderung an SRS-Regeln, Reviews, Tagesrest, Formübungen, Zählerableitung, historischen Satzreferenzen, Schema, Packs, Backend, Cloud oder generierten Dateien.

## Dateien

Geändert: `lib/presentation/providers/database_providers.dart`, `lib/presentation/providers/language_selection_provider.dart`, `lib/data/content/content_database.dart`, `lib/data/content/content_pack_installer.dart`, `lib/data/user/drift_user_repository.dart`, `lib/data/learning/practice_item_resolver.dart`, `lib/domain/learning_groups.dart`, `lib/screens/home/home_screen.dart`, `lib/screens/decks/deck_library_screen.dart`, `lib/screens/decks/deck_details_screen.dart`, `NEXTSTEPS.md`. Neu: `test/content_loading_performance_test.dart`, dieser Bericht. CRLF bestehender Dateien erhalten; `language_selection_provider.dart` war und bleibt LF.

## Messwerte vorher → nachher

### Host (`flutter test`, Debug-JIT, macOS) – keine Release-Leistung

| Ablauf | vorher | nachher |
|---|---:|---:|
| `installer.open()` en | 3 441 ms, UI-Gap 290 ms | 1 909 ms, UI-Gap 5 ms |
| `openInBackground` | 3 148 ms | 1 612 ms |
| `install()` installierter Bootstrap | 312 ms, UI-Gap 299 ms | 320 ms, UI-Gap 2 ms |
| Kaltstart: Pack bereit / Home fertig | 3 478 / 1 996 ms, UI-Gap 363 ms | 1 941 / 1 571 ms, UI-Gap 87 ms |
| Review → Home neu berechnet | 1 964 ms, UI-Gap 336 ms, Indikator sichtbar | 1 563 ms, UI-Gap 34 ms, Daten bleiben sichtbar |
| Sessionstart bis erste Übung | 39 ms | 29 ms |
| Sessionstart: Änderungsereignisse / UI-Gap im Animationsfenster | 1 / 321 ms | 0 / 2 ms |
| en→pt-BR (synthetisch klein): Wechsel; Öffnungen | 353 ms; en 1, pt 3 | 36 ms; en 0, pt 1 |
| pt-BR→en (echtes en): Wechsel / Settings-Status / Home | 6 967 / 10 563 / 12 578 ms | 1 983 / 1 984 / 6 486 ms |
| pt-BR→en: en-Öffnungen, pt-Öffnungen, UI-Gap | 3–4, 1, 648 ms | 1, 0, 122 ms |
| Drift-Warnungen gesamt | 13 | 6 |

Wiederholte Wechsel liefern dieselben Werte (±2 %). user-SQL je Wechsel unverändert 25–33 Abfragen, 1 Schreibvorgang (Spracheinstellung).

### Simulator (Debug, eigens angelegter frischer „iPhone 17 Pro“-Simulator, iOS 27.0, je Variante 3 Kaltstarts, danach gelöscht)

Gleiche temporäre Instrumentierung (`ProviderObserver` + `FrameTiming`, nur in Worktrees, nicht committed). Nur Kaltstart ohne Interaktion; pt-BR dort nicht installierbar (kein Supabase-Zugang). Lauf 1 = Erstinstallation des Bootstrap-Packs.

| | vorher L1 / L2 / L3 | nachher L1 / L2 / L3 |
|---|---:|---:|
| Pack bereit ab `main` | 10 041 / 5 665 / 7 058 ms | 6 222 / 4 004 / 6 528 ms |
| Stapel auf Home fertig | 14 437 / 9 283 / 16 499 ms | 9 950 / 8 163 / 10 987 ms |

Hohe Streuung; Debug-Simulator-Frames liegen in beiden Varianten fast alle über 16,7 ms (animierter Indikator, JIT) und werden nicht als Ruckelbefund gewertet. Logs: `build/content_loading_performance/device/`.

### iPhone (00008110-001651611E01401E)

Zuordnung geprüft: `xcrun devicectl list devices` und `flutter devices` zeigen „iPhone von Claus“, iPhone 14 Plus, iOS 18.7.2, verbunden. **Nicht installiert, nicht gemessen.** Die App benötigt `SUPABASE_URL`/`SUPABASE_ANON_KEY` als `--dart-define`; beide sind in dieser Prozessumgebung nicht gesetzt (nur Vorhandensein geprüft, keine Werte gelesen oder gesucht). Ein Profile-Build ohne sie hätte die installierte App ohne Laufzeitübersetzung und Inhaltsupdates hinterlassen. Keine Zugriffsablehnung umgangen, keine Deinstallation, kein Zugriff auf die echte user.db.

Manueller Profile-Lauf (bestehende Bundle-ID `com.example.sprachapp`, Team-Signierung aus dem Projekt; installiert als Update, Lernstände bleiben):

macOS (Terminal):
```
flutter run --profile -d 00008110-001651611E01401E --dart-define="SUPABASE_URL=$SUPABASE_URL" --dart-define="SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY"
```
Windows (PowerShell) kann kein iOS bauen; nur macOS.

Prüfablauf (DevTools → Performance, Taste `v` im laufenden `flutter run` öffnet DevTools):
1. Kaltstart: Zeit bis Stapel und Wiederholungsanzeige erscheinen.
2. Einstellungen öffnen, en → pt-BR → en, danach wiederholen; Zeit bis Home nutzbar, Frames > 16 ms im Wechselzeitraum.
3. Eine Übung beantworten, zurück zu Home: kein Ladebalken unter „Aktive Stapel“/Wiederholungen.
4. „Lerne mit diesem Stapel“ zweimal: Zeit bis zur ersten Übung, Frameausreißer während der Öffnungsanimation.
Optional exakte Zeitstempel: `build/content_loading_performance/device/perf_probe.dart` nach `lib/` kopieren und in `main()` `startFrameProbe()` sowie `ProviderScope(observers: [PerfObserver()], …)` eintragen; `[perf]`-Zeilen erscheinen im `flutter run`-Log. Vor Commit wieder entfernen.

Abnahmeziele (warm < 1 s, erste Übung < 500 ms, keine wiederkehrenden Home-Ladezustände, keine datenbedingten Frameausreißer) sind damit **nicht** auf dem Gerät nachgewiesen.

## Regressionstests

`test/content_loading_performance_test.dart` (8 Tests, temporäre synthetische Bestände): verzögerter Dispose während Pause öffnet nicht neu; Lease teilt Verbindung, idempotente Freigabe, Schließen nach letztem Nutzer; je Wechsel genau eine Zielöffnung, Status ohne Zweitverbindung, nach Wechsel nur Stapel der aktiven Sprache; schneller Zweitwechsel abgelehnt, kein verspätetes Ergebnis; defekter Zielpack lässt en nutzbar und ermöglicht späteren Wechsel; Sessionstart ohne Änderungsereignis bei vorhandener Karte, Box/Erstellung/Fälligkeit unverändert; `ensureCards` fügt nur Fehlendes ein; Home behält Daten bei Review, zeigt nie Daten der anderen Sprache (auch nicht beim Rückwechsel).

Gegenprobe in einem separaten Worktree auf `87b76df`: alle sechs ursachenbezogenen Tests scheitern dort (`emitted <2>`, `(2, 1)`, `Expected <1> Actual <2>`, Home zeigt Indikator statt Daten); der Lease-Test kompiliert dort nicht (API neu); der Fehlerpfadtest besteht auf beiden Ständen (Schutztest). Bestehende Form-, Historien-, Tagesrest-, Owner- und Sprachwechseltests unverändert und grün.

## Prüfungen

Befehle ab Repository-Root, Flutter/Dart identisch unter Windows (PowerShell) und macOS (Terminal). Logs: `build/content_loading_performance/`.

| Befehl | gekürzter Output | Exit |
|---|---|---:|
| `flutter test --no-pub test/content_loading_performance_test.dart` | `00:02 +8: All tests passed!` | 0 |
| `flutter test --no-pub` + betroffene Gruppe (12 Dateien/Ordner: Sprache, pt-Installation, Lifecycle, Owner, Deck-Flow, Abfragearbeit, Lern-UI, Lerngruppen, Domain, UserRepository, Sprach-UI, neu) | `00:14 +151: All tests passed!` | 0 |
| `flutter test --no-pub` | `01:02 +402 ~5: All tests passed!` | 0 |
| `flutter test --no-pub test/data/real_pack_test.dart` | `00:09 +1: All tests passed!` (30-s-Budget unverändert) | 0 |
| `flutter analyze --no-pub` | `1 issue found`: nur bekanntes `avoid_print` in `test/data/baseline_adoption_pack_test.dart:43:7` | 1 |
| `dart run tool/stage_content_pack.dart --verify` | sha256 `b85793932825a22e92ac744a42255e9f333acd35809aaba46edb5a395f099bdb`, `22 table counts match` | 0 |
| `git diff --check` | meldet CR-Zeilenenden bestehender CRLF-Dateien | 2 |
| `git -c core.whitespace=cr-at-eol diff --check` | kein Output; neue Testdatei ohne CR/Leerzeichenreste | 0 |

Erster Analyselauf meldete zusätzlich einen ungenutzten Import und zwei `if` ohne Block in der neuen Testdatei; korrigiert, danach nur der Altbefund. Sondenfehlversuche (falscher Import, dynamisch typierter Listener, stdout statt Unified Log im Simulator) betrafen nur die Messwerkzeuge.

GitNexus: Impact vor Änderungen – **HIGH** für `RepositoryOwner` (24/20 direkt), `openInBackground` (6), `_matches` (5), `LearningGroups` (61/14 direkt; Sessionstart, Tools); **UNKNOWN** für `selectLanguage` (21 untypisierte Aufrufstellen, per Textsuche und Tests ergänzt); LOW für `ensureCards`, `PracticeItemResolver`, `HomeScreen`. Nach Reindex `detect_changes(scope: all)`: 10 Dateien, 19 Symbole, Risiko medium, weder `partial` noch `truncated`; Prozesse Sessionstart→`project`, Owner→Installer, Sprachwechsel→`contentKeyFor`. Dart-Methodenkörper erscheinen teils nur als „Klasse berührt“ (bekannte Indexgrenze); Diff manuell abgegrenzt.

## Verbleibende Grenzen

- Erste Home-Projektion nach Kaltstart/Sprachwechsel bleibt der größte Rest (Host-JIT ~4,5 s nach dem Wechsel): `PracticeCatalog.load` liest `selectionCards` für alle 3 768 Karten und `deckPracticeTargets` mit einer `form_targets`-Abfrage je Formziel (402 Einzelabfragen); `decksProvider` ruft `practiceItems` je Stapel mit einer Token-Abfrage je Satz. Asynchron gestückelt (UI-Gap ≤ 122 ms JIT), aber echte Wartezeit. Nächster Schritt: gebündelte Formziel-/Tokenabfragen.
- Ein neuer Box-0-Eintrag beim ersten Anzeigen einer neuen Karte ist eine echte Änderung und löst weiterhin eine Home-Neuprojektion aus (jetzt ohne große synchrone Blöcke).
- `verifyGeneration` hasht heruntergeladene Generationen weiterhin gestreamt auf dem UI-Isolate (keine einzelne lange Blockade gemessen; mit echtem pt-BR-Pack lokal nicht messbar).
- `content_update_provider` `openReaders` ruft `resume()` vor dem Rebuild auf den neuen Key; dieselbe verspätete Wiederöffnung der alten Generation ist dort möglich (durch die neue Abbruchprüfung nur teilweise abgedeckt), nicht geändert.
- `wordListProvider` liest `reviewsFor` je Wort (N+1), nicht gemessen.
- Gerätewerte fehlen vollständig; Ziele bleiben offen bis zum manuellen Profile-Lauf.
