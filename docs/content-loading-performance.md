# Inhaltsladen: Drift-Warnung, Sprachwechsel, Home-Ladezustände, Sessionstart

> Historischer Ausgangsbericht und frühere Nachträge; der aktuelle Stand steht im letzten Abschnitt „Zielpack-Öffnung auf dem iPhone“. Frühere offene Gerätebefunde und Restkostenschätzungen sind dort ersetzt.

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

## Historische verbleibende Grenzen (vor 1145937)

- Erste Home-Projektion nach Kaltstart/Sprachwechsel bleibt der größte Rest (Host-JIT ~4,5 s nach dem Wechsel): `PracticeCatalog.load` liest `selectionCards` für alle 3 768 Karten und `deckPracticeTargets` mit einer `form_targets`-Abfrage je Formziel (402 Einzelabfragen); `decksProvider` ruft `practiceItems` je Stapel mit einer Token-Abfrage je Satz. Asynchron gestückelt (UI-Gap ≤ 122 ms JIT), aber echte Wartezeit. Nächster Schritt: gebündelte Formziel-/Tokenabfragen.
- Ein neuer Box-0-Eintrag beim ersten Anzeigen einer neuen Karte ist eine echte Änderung und löst weiterhin eine Home-Neuprojektion aus (jetzt ohne große synchrone Blöcke).
- `verifyGeneration` hasht heruntergeladene Generationen weiterhin gestreamt auf dem UI-Isolate (keine einzelne lange Blockade gemessen; mit echtem pt-BR-Pack lokal nicht messbar).
- `content_update_provider` `openReaders` ruft `resume()` vor dem Rebuild auf den neuen Key; dieselbe verspätete Wiederöffnung der alten Generation ist dort möglich (durch die neue Abbruchprüfung nur teilweise abgedeckt), nicht geändert.
- `wordListProvider` liest `reviewsFor` je Wort (N+1), nicht gemessen.
- Gerätewerte fehlen vollständig; Ziele bleiben offen bis zum manuellen Profile-Lauf.


## Historischer Nachtrag 19.10.2026: gebündelte Repository-Abfragen und echte iPhone-Messung

Dieser Nachtrag ersetzt die oben offenen Gerätebefunde. Basis: `0d5dee9`, isolierter Worktree `batch-content-queries/sprachapp`; fremde Änderungen im ursprünglichen Checkout bleiben erhalten. Vor Änderungen abgegrenzte Dateien: `lib/data/content/content_database.dart`, `lib/data/content/drift_content_repository.dart`, `lib/presentation/providers/deck_providers.dart`, neue Tests `test/data/content_batch_test.dart`, `test/home_metadata_projection_test.dart`, dieser Bericht und `NEXTSTEPS.md`. Temporäre Messsonden gehören nicht zum Commit.

### Ursache, Plan und Vertragsprüfung

`selectionCards` fragte bisher für jede Karte (auch ohne Formziel) einzeln `form_targets` ab; der Katalog wiederholte dies für Stapel. `practiceItems` lud Tokens einzeln je Satz. Home lud für die letzten fünf Wörter je Stapel komplette Übungsobjekte, obwohl nur Form und Übersetzung angezeigt werden. Die 402 dokumentierten Formmitgliedschaften waren deshalb nicht die tatsächliche SQL-Aufrufzahl.

Umgesetzt: parametrisierte IN-Abfragen in maximal 400er-Batches für Formziele und Tokens; Gruppierung nach Karten-/Satz-ID und anschließende Rekonstruktion der ursprünglichen Reihenfolge. Die zweiarmige Lemma-UNION bindet damit maximal 800 statt 1000 Parameter (auch unter SQLite-Limit 999). Aktive Filter, Mehrdeutigkeitsfehler, historische Lesefilter, UTF-16-Prüfung, Kontext-Snapshots und Formidentitäten bleiben erhalten. Home nimmt seine Wortmetadaten aus dem bereits sprach-/packgebundenen Resolver; Übungsstart lädt weiterhin vollständig geprüfte Sätze. Kein zusätzlicher Cache, keine ausgelassene Packvalidierung, keine geänderte Verbindungseigentümerschaft und keine zusätzliche Änderungsmeldung durch `ensureCards`.

`ContentDatabase.forTesting` erlaubt einen isolierten, gezählten Executor; Produktionsöffner bleiben unverändert. Tests arbeiten auf temporären Kopien bzw. synthetischen Daten. Neue Tests prüfen 805 Ziele in en und pt-BR über drei Batchgrenzen, Reihenfolge, doppelte/fehlende IDs, Form- und Tokenfelder und höchstens 999 Bindungen. Home-Metadaten stimmen mit vollständigen Übungsobjekten überein, bei null vollständigen Übungsabrufen. Bestehende Tests decken Tagesrest, Fälligkeit, Formübungen, aktive Revisionen, Historie sowie schnelle Sprachwechsel und Owner-Lifecycle ab. Keine fragilen Zeitgrenzen hinzugefügt; Realpack-Budget weiterhin 30 Sekunden.

### SQL-Zählung und Ergebnisgleichheit (Host)

Gleicher Test, gleiche unveränderte en-Packkopie: 3 767 Karten, 14 Stapel, 3 767 aktive Übungsobjekte und 4 297 historische Referenzen. QueryInterceptor zählt tatsächliche SELECT-Aufrufe, nicht geschätzte Schleifendurchläufe. Zeiten sind einzelne Hostläufe; parallele Xcode-Arbeit kann die Dauer beeinflussen. Abfragezahlen und Inhaltsvergleich sind davon unabhängig.

| Pfad | Form-SELECT vorher → nachher | Satz-/Token-SELECT vorher → nachher | Dauer vorher → nachher |
|---|---:|---:|---:|
| Alle selectionCards | 3 767 → 10 | 0 / 0 → 0 / 0 | 1 051 → 148 ms |
| PracticeCatalog mit Stapeln | 11 427 → 44 | 0 / 0 → 0 / 0 | 1 979 → 603 ms |
| Alle practiceItems | 3 767 → 10 | 8 / 3 767 → 10 / 10 | 1 292 → 547 ms |
| Alle historischen Einzelreferenzen | 0 → 0 | 4 297 / 4 297 unverändert | 32 492 → 32 884 ms |

Gemessene SQL-Zeit bei `all-practice`: Formen 340 743 → 4 848 µs, Satzlesen 25 009 → 29 280 µs, Tokens 431 959 → 155 362 µs. Satzlesen war bereits gebündelt; zwei zusätzliche Abfragen entstehen durch das kleinere sichere Batchlimit. Die Zahl wächst nun je begrenztem Batch statt je Formziel/Satz. Historische Einzelabrufe behalten ihren Vertrag und sind kein Home-Pfad.

SHA-256 über vollständig serialisierte Ergebnisse vor/nachher identisch (nicht nur Anzahl):
- Karten: `3d97e3407ab6d2eded25d2dbd771533ffd445112b69b45cba53e789ee0925e05`
- Stapel: `cf9a79b00a538bff698eaaf28cf4b956ebc51236313238e274718797d2f7dd3d`
- Geordnete Formziele: `674e728b54426a26c1710f6a5707c4fb5facaee5227a818e3561381b76531e39`
- Aktive Übungen inkl. Tokens/Glossen/Offsets: `4df3a14ecda894d15741648766771b1de81b9475949e7826f9f965ff371b9531`
- Historische Sätze: `edddd6e34ed119489f0e1841212acec7c4147d49c22c294a1f21b89b66e0c6eb`

Host-Home-Sonde (synthetischer Lernstand, kein echtes user.db): erster pt-BR→en insgesamt 6 873 → 7 488 ms, wiederholt 7 136 → 4 270 ms; dabei Packöffnung 1 962 → 4 088 bzw. 2 608 → 2 199 ms. Diese Streuung unter paralleler Buildlast erlaubt keine belastbare pauschale Host-Prozentverbesserung. Erste Übung 28 → 28 ms, wiederholt 21 → 31 ms; keine Verlagerung derselben Sekundenwartezeit auf den Übungsstart beobachtet.

### iPhone: nutzbare Home-Daten statt nur Sprachüberschrift

Echtes iPhone 14 Plus, iOS 18.7.2, ID `00008110-001651611E01401E`; Profile-Modus, bestehende Installation und Lernstände, gleiche Bundle-ID `com.example.sprachapp` und Signierung `W27Z6DNPT3`. Vorher und nachher derselbe manuelle Ablauf: Home vollständig laden, en→pt-BR→en, zu Home zurück, eine Übung nur öffnen. Nutzer hat keine automatisierten Reviews erhalten; keine direkte Bearbeitung oder Kopie der echten user.db. Je Variante ein gültiger Lauf, keine statistische Messreihe.

| Gerätephase | Vorher | Nachher |
|---|---:|---:|
| Kaltstart bis Home-Stapeldaten bereit | 10 502 ms | 8 330 ms |
| en→pt-BR: selectLanguage | 94 ms | 93 ms |
| pt-BR→en: selectLanguage / Zielpack bereit | 6 862 ms | 6 899 ms |
| Home-Projektion ab Rückkehr bis Stapel **und** Vokabeldaten bereit | 3 314 ms | 1 275 ms |
| darin PracticeCatalog | 1 603 ms | 571 ms |
| darin Vokabeldaten bereit (ab Home-Start) | 3 224 ms | 1 236 ms |
| Erste Übung bis Session bereit | 65 ms | 66 ms |

ProviderObserver misst die tatsächlich benötigten Daten, FrameTiming ergänzt die Darstellung. Kein bloßes Timing des Sprachlabels, aber auch kein automatisierter Pixel-Nachweis des ersten vollständig gezeichneten Frames. Der Nutzer bestätigte beide Abläufe und meldet nachher **„kaum Unterschied“**. Das passt zur unveränderten Packwartezeit. Zwischen Wechselende und manueller Home-Rückkehr lagen 957 bzw. 5 068 ms; diese Bedienpausen dürfen nicht als Code-Laufzeit verrechnet werden. Daher keine irreführende Gesamtdauer aus beiden Zeitstempeln.

**Ziel unter einer Sekunde nicht erreicht.** Die Home-Projektion spart im beobachteten Lauf rund zwei Sekunden, aber die belegten Einzelabfragen erklären nicht die sieben Sekunden bis zum Ende von `selectLanguage`. Der nächste begrenzte Schritt ist eine getrennte Geräteinstrumentierung innerhalb des Zielpack-Öffnens (`openInBackground`: Validierungs-/Leseschritte und Übergabe), ohne Prüfungen zu entfernen oder echte Lernstände anzutasten. Der genaue Anteil einzelner Validatoren ist noch nicht gemessen. Schnelle Wechsel sind durch automatisierte Lifecycle-Tests gedeckt; eine schnelle Geräte-Wechselfolge und wiederholte Geräte-Zeitreihe stehen noch aus.

### Reproduzierbare Befehle und lokale Belege

Flutter-/Dart-Testbefehle identisch unter macOS Terminal und Windows PowerShell; iPhone-Build nur macOS. SQL-Sonde:
```
flutter test --no-pub --dart-define=BATCH_MEASURE=true test/data/content_batch_test.dart --plain-name "real pack query measurement"
```
Tatsächlich zusätzlich `--dart-define=BATCH_OUTPUT=/private/tmp/batch-before-fingerprints.json` bzw. `.../batch-after-fingerprints.json` verwendet; beide Exit 0. Dieser ausdrücklich aktivierte Vollvergleich hat ein eigenes 3-Minuten-Budget und verändert nicht den normalen 30-s-Packtest. Ohne Define wird nur die optionale Messung übersprungen.

Gerät vor/nachher: `flutter run --no-pub --profile -d 00008110-001651611E01401E -t lib/perf_measurement.dart` mit den vom Nutzer angegebenen öffentlichen `SUPABASE_URL`-/`SUPABASE_ANON_KEY`-Dart-Defines. Temporärer Einstieg initialisiert WidgetsBinding und ProviderObserver/FrameTiming vor SprachApp; keine Inhalts- oder Lernstandausgabe. Vorheriger Sondenstart ohne Binding scheiterte, nach gezielter Korrektur gültige Messung. Messsonden danach entfernt; normaler Einstieg `lib/main.dart` mit denselben Defines wieder gebaut.

Lokale Rohlogs (außerhalb Git): `/private/tmp/batch-before-queries.log`, `batch-after-queries.log`, `batch-before-home.log`, `batch-after-home.log`, `batch-device-before2.log`, `batch-device-after.log`. Die Tabellen enthalten die entscheidenden Ergebnisse dauerhaft; temporäre Logs können später verschwinden.

GitNexus vor Änderungen: HIGH für `selectionCards` (6 direkte Aufrufer, 3 Prozesse) und `_formTarget` (3 direkte Aufrufer, 3 Prozesse), insbesondere Katalog/Tools/Editorpfade; Warnung vor Bearbeitung ausgegeben. LOW für `deckPracticeTargets`, `practiceItems`, `_tokens`, `_lemmaForms`; ContentDatabase MEDIUM. `decksProvider` und Dokumentdateien UNKNOWN: durch direkte Aufrufer-/Verweissuche ergänzt, nicht als Entwarnung behandelt. Methodenauflösung des Dart-Index ist unvollständig; Ergebnisvergleich und direkte Tests ergänzen den Graphen.


Abschließende Prüfungen (tatsächliche Ausgaben, Logs `/private/tmp/batch-*-final.log` bzw. `batch-full-pass.log`):

| Befehl | Gekürzter Output | Exit |
|---|---|---:|
| `flutter test --no-pub test/data/content_batch_test.dart test/home_metadata_projection_test.dart test/content_loading_performance_test.dart test/data/form_content_test.dart test/data/content_active_context_test.dart test/data/content_context_revisions_test.dart test/form_learning_flow_test.dart test/language_selection_ui_test.dart test/language_update_lifecycle_test.dart test/data/content_owner_barrier_test.dart test/data/portuguese_installation_test.dart test/deck_flow_test.dart` | `00:11 +69 ~5: All tests passed!` | 0 |
| `flutter test --no-pub` | `01:01 +405 ~6: All tests passed!` (5 bestehende Skips + optionale SQL-Messung) | 0 |
| `flutter test --no-pub test/data/real_pack_test.dart` | `00:07 +1: All tests passed!` | 0 |
| `flutter analyze --no-pub` | `1 issue found`, ausschließlich alter `avoid_print`, `test/data/baseline_adoption_pack_test.dart:43:7` | 1 |
| `dart run tool/stage_content_pack.dart --verify` | `22 table counts match`, SHA-256 `b85793932825a22e92ac744a42255e9f333acd35809aaba46edb5a395f099bdb` | 0 |
| `git -c core.whitespace=cr-at-eol diff --cached --check` (genau sieben eigene Dateien) | kein Output | 0 |
| `node .gitnexus/run.cjs analyze --index-only` | `Repository indexed successfully`, 8 281 nodes, 19 288 edges | 0 |
| `node .gitnexus/run.cjs detect-changes --scope all --repo . --limit 5000` plus vollständiger LocalBackend-JSON-Aufruf derselben Operation | 7 Dateien, 35 Symbole, 9 Prozesse, Risiko HIGH; alle 35 Symbole vorhanden, kein `partial:true`/`truncated:true` | 0 |

HIGH bleibt als Warnung bestehen: insbesondere Editor-Inspektion und Toolpfade erreichen `_formTargets`. Ganze Ergebnismengen, Form-/Historientests und vollständige Suite wurden dagegen geprüft; der Editorbestand selbst wurde nicht verändert. Nach dem abschließenden Prüfprotokoll folgt nochmals die Graphanalyse vor Commit.

Fehlversuche transparent: erster gezielter Testlauf Exit 1 wegen fehlendem Extension-Import im neuen Home-Test (behoben); erster Gesamtlauf Exit 1 wegen dieses Imports und fehlender ignorierter historischer Packdateien im frischen Worktree. Die vorhandenen Dateien wurden unverändert kopiert. Zweiter Gesamtlauf Exit 1 wegen sechs Schreibfehlern in den bestehenden Storytests (`build/story_single_sentence` fehlte); Ausgabeordner angelegt, danach vollständiger Lauf grün. Erster Analyselauf Exit 1 mit drei neuen Klammerhinweisen; behoben, keine Unterdrückung. Bestehende Google-Fonts-/Drift-Testwarnungen unverändert sichtbar. Kein Test entfernt, keine Prüfung abgeschwächt.

Normaler Profile-Build ohne Messsonde erfolgreich installiert und gestartet, danach Flutter mit `q` beendet (Exit 0); App bleibt installiert und ist normal startbar. Keine Deinstallation, kein Deployment von Cloudfunktionen, keine Modellanfrage, kein Push.

## Aktueller Nachtrag 19.10.2026: Zielpack-Öffnung auf dem iPhone

Basis ist `11459374a5dd9a76a991b0b852ab79e82cc74f5d` im sauberen Worktree `/Users/ardasayar/.codex/worktrees/batch-content-queries/sprachapp`, ausdrücklich nicht der ältere Hauptcheckout. Die vorherigen Batch-, Home- und Lifecycle-Änderungen bleiben erhalten. Endgültige Änderungsdateien, vor Reparatur abgegrenzt: `lib/data/content/content_database.dart`, neu `test/data/single_sentence_validation_batch_test.dart`, dieser Bericht und `NEXTSTEPS.md`.

**Ergebnis:** Median `selectLanguage(pt-BR→en)` 7 021 → 4 989 ms, rund 2 032 ms bzw. 29 % weniger. Das Ein-Sekunden-Ziel ist weiterhin verfehlt. Erste Übung 63 → 62 ms; keine Verlagerung der gesparten Sekunden auf den Übungsstart beobachtet.

### Messaufbau und tatsächlich aktiver Pack

Gleiches iPhone 14 Plus, iOS 18.7.2, Geräte-ID `00008110-001651611E01401E`, Profile-Modus, Bundle-ID `com.example.sprachapp`, Signierung `W27Z6DNPT3`. Je Variante ein Kaltstart und danach drei manuelle en→pt-BR→en-Zyklen; während beider Reihen keine parallelen Tests oder Builds. Der Nutzer bestätigte jeweils drei Durchgänge. Keine automatisierten Reviews, keine direkte Bearbeitung/Kopie der echten user.db, keine Modellanfrage oder Cloudänderung. Eine subjektive Nachher-Bewertung wurde diesmal nicht mitgeteilt.

| Bestand | Bytes | Schema | Version |
|---|---:|---:|---|
| Auf dem Gerät geöffnetes Englisch (Downloadgeneration) | 43 089 920 | 5 | `chitchat_de_korrektur_v1` |
| Zugehöriges Historieninventar | 10 353 596 | – | an Downloadmanifest gebunden |
| Lokales Bootstrap-Asset, **nicht** der Geräte-Messbestand | 26 198 016 | 4 | `story_single_sentence_v1` |

Temporäre Instrumentierung in `language_selection_provider.dart`, `database_providers.dart`, `content_pack_installer.dart`, `content_database.dart`, `form_content_validation.dart`, `content_update_service.dart` und `content_update_validation.dart`; zusätzliche temporäre Dateien `open_probe.dart`, `perf_probe.dart`, `perf_measurement.dart`. Nur Dauer, SQL-Anzahl, Bytezahl und öffentliche Packmetadaten protokolliert, keine Inhalte, Lernstände, Pfade aus dem App-Sandboxbestand, Tokens oder Schlüssel. Alle Sonden anschließend entfernt; nur die Validatoroptimierung verbleibt im Produktionscode.

Stopwatch umfasst jedes äußere async-Intervall. Ein delegierender SQLite-Wrapper misst pro Validator die `select`-Aufrufe einschließlich ResultSet-Erstellung; Restzeit umfasst Dart-Prüfungen, Row-Zugriff und Map-Aufbau. Gestreamtes Hashen trennt Zeit in `sink.add/close` von verbleibender Lese-/Wartezeit; Letztere ist **keine reine physische Datenträgerzeit**, sondern enthält Scheduling. Isolate-Startlatenz wird über Zeitstempel erfasst. ProviderObserver plus PostFrameCallback markieren Home erst nach Vokabel- und Stapeldaten und dem anschließenden Frame. FrameTiming erfasst auffällige UI-Frames. Dieselbe Sonde vor/nachher; geringe Messkosten sind in beiden Reihen enthalten.

### Messreihe: Gesamtzeiten und nutzbare Ansicht

Alle Werte in Millisekunden. Median jeweils aus drei tatsächlich gemessenen Wechseln, keine Schätzung aus Teilzeiten.

| Phase | Vorher 1 / 2 / 3 | Median vorher | Nachher 1 / 2 / 3 | Median nachher |
|---|---:|---:|---:|---:|
| selectLanguage pt-BR→en insgesamt | 6 888 / 7 021 / 7 068 | 7 021 | 4 899 / 4 989 / 5 082 | 4 989 |
| Zielpack-Owner öffnen (inkl. Installation/Prüfung) | 6 876 / 7 008 / 7 053 | 7 008 | 4 887 / 4 976 / 5 070 | 4 976 |
| Installer: Journal, Hash, Downloadprüfung, Historie | 4 536 / 4 609 / 4 617 | 4 609 | 3 547 / 3 618 / 3 667 | 3 618 |
| Anschließendes openInBackground inkl. zweiter Vollprüfung | 2 338 / 2 398 / 2 434 | 2 398 | 1 339 / 1 357 / 1 401 | 1 357 |
| Gegenrichtung en→pt-BR (Provider-Zeit) | 103 / 96 / 94 | 96 | 93 / 98 / 89 | 93 |

Die Owner-Zeile enthält die beiden darunterliegenden Phasen und darf nicht nochmals dazu addiert werden. Mediane verschiedener Zeilen sind ebenfalls keine exakt additive Gesamtrechnung. Die folgenden Innenphasen sind innerhalb der jeweiligen äußeren Intervalle gemessen.

| Weitere Messung | Vorher | Nachher |
|---|---:|---:|
| Kaltstart bis englischer Content-Provider bereit | 7 164 | 5 068 |
| Kaltstart bis Home-Frame mit benötigten Daten | 8 521 | 6 435 |
| Home-Projektion nach drittem Wechsel bis Daten | 1 332 | 1 293 |
| Home-Projektion bis anschließender Frame | 1 333 | 1 294 |
| Erste Übung nach drittem Wechsel | 63 | 62 |
| Größter protokollierter Frame im gesamten Ablauf | 30 | 30 |
| Größte Build-Dauer eines protokollierten Frames | 27 | 27 |

**Prüflücke:** In beiden Reihen wurde nur nach dem dritten Wechsel eine neue Home-Projektion samt Frame protokolliert, trotz der Bitte um Home-Rückkehr pro Durchgang. Daher sind Home und Übung Einzelmessungen und haben keinen Drei-Läufe-Median. Vorher lagen zwischen drittem Wechselende und Home-Projektionsbeginn 1 803 ms, nachher 8 653 ms manuelle Bedienpause. Diese Pausen werden nicht als Code-Laufzeit verrechnet. Ein durchgehend automatisiert gemessener Tap→sichtbare-Home-Endpunkt ohne Bedienpause liegt nicht vor. Die gemessenen Öffnungskosten allein schließen das Ein-Sekunden-Ziel bereits aus. Keine sekundenlange UI-Blockade in den Frame-Daten belegt; der asynchrone Wartezustand bleibt trotzdem sichtbar.

### Aufschlüsselung der Packöffnung

Validatorwerte unten sind je Wechsel über **beide** Vollvalidierungen summiert. Die drei Einzelwerte stehen in zeitlicher Reihenfolge; Zeilen mit einem Gesamtvalidator enthalten dessen SQL- und Dart-Arbeit.

| Innenphase | Vorher 1 / 2 / 3 | Nachher 1 / 2 / 3 |
|---|---:|---:|
| Inhaltsdatei lesen + SHA-256 | 455,05 / 436,82 / 442,53 | 432,85 / 452,27 / 444,77 |
| Inventardatei lesen + SHA-256 | 97,89 / 102,11 / 98,09 | 96,77 / 98,66 / 98,61 |
| Inventar JSON lesen/decodieren + kanonischer Hash | 247,31 / 254,43 / 255,37 | 245,56 / 250,27 / 253,95 |
| Historieninventar: jede Tabellenzeile kanonisch abgleichen | 1 446,19 / 1 480,20 / 1 499,36 | 1 437,75 / 1 483,95 / 1 478,37 |
| quick_check der beiden Vollprüfungen zusammen | 55,49 / 55,32 / 56,14 | 54,09 / 54,87 / 59,54 |
| Pflichtspalten/Release der beiden Vollprüfungen | 1,03 / 1,16 / 1,09 | 1,02 / 1,02 / 1,07 |
| Satz-/Wortbesitzvalidator | 2 016,35 / 2 080,83 / 2 112,43 | 109,75 / 108,01 / 127,43 |
| Lerngruppenvalidator | 26,08 / 27,07 / 27,31 | 29,01 / 33,64 / 26,75 |
| Formvalidator | 1 422,19 / 1 412,98 / 1 418,54 | 1 391,21 / 1 397,24 / 1 430,48 |
| Kontext-/Revisionsvalidator (Schema 5) | 1 066,17 / 1 113,67 / 1 097,65 | 1 046,69 / 1 054,30 / 1 105,21 |
| Zusätzlicher quick_check der Drift-Verbindung | 27,53 / 29,29 / 30,52 | 27,99 / 27,15 / 28,83 |

Hash-Rechenzeit für beide Dateien: Median 471,61 → 473,17 ms; übrige Lese-/Wartezeit 69,43 → 67,09 ms. Hashen ist damit gemessen, aber nicht der dominante behobene Engpass. Der Downloadpfad hasht weiterhin gestreamt auf dem UI-Isolate; eine Änderung daran ist nicht Teil dieses Fixes.

| Validator, beide Aufrufe zusammen | SELECT-Anzahl vorher → nachher | Median SQL vorher → nachher | Median Dart vorher → nachher |
|---|---:|---:|---:|
| Satz-/Wortbesitz | 21 774 → 16 | 2 007,38 → 44,32 | 73,45 → 67,97 |
| Lerngruppen | 4 → 4 | 9,35 → 9,52 | 17,38 → 19,50 |
| Formen | 42 → 42 | 407,18 → 397,20 | 1 011,36 → 1 013,85 |
| Kontextrevisionen | 14 → 14 | 369,61 → 356,18 | 728,04 → 698,71 |

Formvalidator, zur weiteren Einordnung (Median vorher; jeweils beide Aufrufe): Tabellenlesen/Map-Aufbau 704,88 ms, Lookup-Indizes 28,89 ms, lexikalische Gruppen 38,35 ms, Formziele 1,92 ms, konkurrierende Karten/Stapel 256,95 ms, Tokens 143,24 ms, Satzlinks 38,74 ms, Satzabdeckung/Wörterbuchbindung 181,74 ms, Storylinks 0,02 ms, Wörterbuchabschluss 16,39 ms. Diese Unterphasen sind in der Formvalidator-Zeit enthalten, nicht zusätzliche Kosten.

Weitere kleine Phasen:
- Owner wartet auf vorheriges Schließen/Pause: 0,289 / 0,344 / 0,241 → 0,281 / 0,286 / 0,259 ms.
- Zielinstaller und Generation-Key bis Lease: 3,909 / 4,241 / 5,608 → 3,955 / 4,046 / 4,191 ms. Journal-Aktivprüfung liegt zusätzlich innerhalb der Installerphase (vorher 1,69 / 1,58 / 1,29 ms).
- Start des zweiten Validierungsisolates: 0,237 / 0,201 / 0,250 → 0,217 / 0,209 / 0,512 ms. Dessen gesamter Roundtrip enthält die komplette zweite Prüfung; er ist keine zusätzliche Validierung.
- SQLite-Öffnung für Validierungs- und Drift-Verbindung zusammen: 1,144 / 1,363 / 1,208 → 1,125 / 1,309 / 1,204 ms; erste Download-SQLite-Öffnung vorher etwa 0,61 ms.
- Drift-Start bis Lazy-Opener: 0,431 / 0,427 / 0,398 → 0,428 / 0,583 / 0,369 ms; connect-Roundtrip 0,073 / 0,108 / 0,119 → 0,104 / 0,135 / 0,091 ms. Diese Intervalle überlappen.
- Erste Drift-Abfrage inklusive Lazy-Öffnung, zusätzlichem quick_check und Übergabe: 28,58 / 30,68 / 31,64 → 29,06 / 28,50 / 30,05 ms. Nicht nochmals zur enthaltenen Integritätsprüfung addieren.
- Alten Owner schließen: 0,292 / 0,222 / 0,335 → 0,252 / 0,305 / 0,294 ms.
- Sprache persistieren: 5,542 / 5,499 / 5,475 → 5,208 / 5,326 / 5,517 ms.
- Neuen Provider-Scope bereitstellen: 1,219 / 1,194 / 1,751 → 0,988 / 1,158 / 0,969 ms.

### Ursache, minimale Reparatur und erhaltene Garantien

`validateSingleSentenceContent` fragte pro aktivem Wort Primärkarte und Eigentümerstapel ab und pro aktiver Karte ihre Satzverknüpfung. Auf dem tatsächlichen Gerätepack waren das 10 887 SELECTs je Validierung. Der Installer ruft zunächst `recoverContentInstallation → verifyGeneration → validateDownloadedContent → validateContentSchema` auf. Danach ruft `openInBackground` erneut `validateContentSchema` auf; die Drift-Verbindung macht zusätzlich quick_check/Release-Abgleich. Dadurch entstanden 21 774 Abfragen für diesen einen Validator pro Wechsel. Messung, nicht Vermutung: etwa 2,01 Sekunden SQL-Zeit im Vorher-Median.

Reparatur erst nach der Vorher-Reihe: acht feste SELECTs lesen aktive Karten, Deckreferenzen und gejointe Satzlinks einmalig; lokale Maps gruppieren sie innerhalb genau dieses Validatoraufrufs. Alias-Wortzuordnungen verwenden ebenfalls einen einmalig gebildeten Satz von Identitäten statt wiederholtem `words.any`. Keine Speicherung über Aufrufe, Packversionen oder Sprachen hinweg. Karten-/Satzduplikate bleiben als Listen erhalten, Deckduplikate als Anzahl; sie werden weiterhin abgewiesen und nicht durch Map-Überschreiben versteckt. NULL-Schlüssel werden wie zuvor bei SQL-`= NULL` nicht als gültige Referenz behandelt. Filter, Positionen, Sprachtrennung, Normalisierung, Schema-4-Formausnahme und Fehlermeldungen bleiben bestehen.

Hash-, Schema-, quick_check-, Gruppen-, Form-, Kontext- und Historienprüfungen werden weiterhin vollständig ausgeführt. Es wurde insbesondere **keine** Prüfung wiederverwendet oder durch ein „bereits geprüft“-Flag ersetzt. Laufende Reader/Leases, Rollback, Persistierung, Gate und Home/ensureCards sind im Enddiff unverändert. Das bestehende Verhalten fehlerhafter Wechsel bleibt durch Owner-/Sprachwechseltests geschützt.

Restkosten des Nachher-Medians: rund 1,48 s vollständiger Inventarzeilenabgleich, 1,40 s Formvalidierung, 1,05 s Kontextrevisionen, 0,54 s Datei-Hash/Lesezeit, 0,25 s Inventardecodierung/-hash, plus verbliebene Satz-/Gruppen-/Integritätsprüfungen. Beide Vollvalidierungen sind weiterhin nachweisbar. Nächster begrenzter Untersuchungsgegenstand wäre der kanonische Inventarabgleich; eine alternative Wiederverwendung validierter Verbindungen/Resultate müsste zuerst die Bindung an identische unveränderliche Bytes und den Validierungsvertrag nachweisen. Ein neuer Vertrauens-/Cachevertrag bedürfte einer gesonderten Nutzerentscheidung und wird hier nicht eingeführt. Keine Aussage, dass eine dieser Folgearbeiten allein das Ein-Sekunden-Ziel erreicht.

### Regression, Befehle und unveränderte Bytes

31 neue Tests: feste acht SELECTs für 1/40/805 Karten einschließlich Aliasen in en und pt-BR; 27 ungültige Varianten (Dubletten, NULL-/fehlende/inaktive/fremdsprachige Referenzen, fehlende/mehrfache Sätze, Positionen, Normalisierung, Aliasbindung), inaktive Dubletten als gültiger Fall und begrenzte Schema-4-Formausnahme. Gegenprobe am unveränderten `1145937`: 29 fachliche Tests bestehen, ausschließlich zwei Abfragezahltests scheitern (`Expected: <8>, Actual: <9>` bereits beim kleinsten Bestand). Danach Fix wiederhergestellt. Keine Testzeitgrenze ersetzt eine fachliche Prüfung.

Lokales Asset und Manifest vor/nachher byteidentisch (SHA-256):
- `content.sqlite`: `b85793932825a22e92ac744a42255e9f333acd35809aaba46edb5a395f099bdb`
- `content.manifest.json`: `74a0bce4d16bb3084f762dd6afc69accc44c80db545dba9871b21d0b8c7adbfe`

Die Downloadgeneration auf dem Gerät wurde in beiden Reihen erfolgreich gegen ihre Manifest-/Inventarhashes geprüft; kein Packupdate oder Inhalts-Schreibpfad ausgeführt. Der lokale Bytevergleich betrifft ausdrücklich das lokale Asset, nicht eine exportierte Kopie des Gerätebestands.

Flutter-/Dart-Testbefehle identisch unter Windows PowerShell und macOS Terminal. iPhone-Build/-Installation nur macOS. Tatsächlicher Messstart jeweils `flutter run --no-pub --profile -d 00008110-001651611E01401E -t lib/perf_measurement.dart`, mit den vom Nutzer angegebenen öffentlichen `SUPABASE_URL`- und `SUPABASE_ANON_KEY`-Dart-Defines. Kein Anthropic-Schlüssel. Vorab `flutter build ios --no-pub --profile -t lib/perf_measurement.dart` mit denselben Defines (Exit 0, `Built ... Runner.app`); nach Ergänzung der Hash-/Frame-Messpunkte neu gebaut. Beide Messläufe mit `q` beendet, Exit 0. Abschließend normaler `flutter run --no-pub --profile -d 00008110-001651611E01401E` mit denselben Defines erfolgreich installiert/gestartet und mit `q` beendet (Exit 0); App bleibt normal startbar, ohne Sonde. Keine Deinstallation.

| Prüfung | Tatsächlicher gekürzter Output | Exit |
|---|---|---:|
| `flutter test --no-pub test/data/single_sentence_validation_batch_test.dart test/data/single_sentence_content_test.dart test/data/form_content_test.dart test/data/content_context_revisions_test.dart` | `00:01 +59: All tests passed!` | 0 |
| Gegenprobe neue Testdatei auf `1145937` | `+29 -2`, nur die zwei Abfragezahltests rot | 1 (erwartet) |
| `flutter test --no-pub test/data/single_sentence_validation_batch_test.dart test/data/single_sentence_content_test.dart test/data/learning_groups_test.dart test/data/form_content_test.dart test/data/content_context_revisions_test.dart test/data/content_update_test.dart test/data/content_owner_barrier_test.dart test/content_loading_performance_test.dart test/language_update_lifecycle_test.dart test/language_selection_test.dart` | `00:07 +93: All tests passed!` | 0 |
| `flutter test --no-pub` | `01:07 +436 ~6: All tests passed!` | 0 |
| `flutter test --no-pub test/data/real_pack_test.dart` | `00:07 +1: All tests passed!`, originales 30-s-Budget unverändert | 0 |
| `flutter analyze --no-pub` | `1 issue found`: nur bekannter `avoid_print` in `test/data/baseline_adoption_pack_test.dart:43:7` | 1 |
| `dart run tool/stage_content_pack.dart --verify` | `22 table counts match`, obiger Asset-SHA-256 | 0 |
| Python-SHA-256-Vergleich Asset/Manifest vorher/nachher | `Protected asset+manifest bytes unchanged` | 0 |

Bestehende Google-Fonts-/Drift-Testwarnungen unverändert sichtbar, keine Unterdrückung. Sechs Skips entsprechen den fünf bestehenden plus der nur per Define aktivierten Vollvergleichssonde. Keine ungeklärten fehlgeschlagenen Tests dieses Fixes.

Rohlogs lokal außerhalb Git: `/private/tmp/open-device-before.log`, `open-device-after.log`, `open-device-normal.log`, `open-before-phases.json`, `open-after-phases.json`, `open-validator-tests.log`, `open-regression-before.log`, `open-targeted.log`, `open-full.log`, `open-realpack.log`, `open-analyze.log`, `open-stage.log`. Die obigen Einzelwerte bleiben im Bericht erhalten, auch wenn temporäre Logs später gelöscht werden.

GitNexus: vor Messänderungen und Reparatur HIGH für `RepositoryOwner`, `validateContentSchema`, `validateSingleSentenceContent`, `validateLearningGroups`, `validateFormContent`; betroffene Aufrufer sind Download-/Öffnungspfad, Staging und Editorprüfung. Warnung vor Bearbeitung mitgeteilt. `selectLanguage` UNKNOWN, direkte Settings- und Testaufrufe ergänzend gesucht; UNKNOWN nicht als Entwarnung gewertet. Dokumente ebenfalls UNKNOWN, Verweise in AGENTS/CLAUDE/NEXTSTEPS geprüft. Keine fremden Dateien in den Enddiff übernommen.

Ergänzender vollständiger Ergebnisvergleich: `flutter test --no-pub --dart-define=BATCH_MEASURE=true --dart-define=BATCH_OUTPUT=/private/tmp/open-after-fingerprints.json test/data/content_batch_test.dart --plain-name "real pack query measurement"` → `00:35 +1: All tests passed!`, Exit 0. Alle fünf vollständigen Fingerprints (Karten, Stapel, geordnete Formziele, aktive Übungen, 4 297 historische Satzreferenzen) identisch zum Stand 1145937; Hashwerte im vorherigen Nachtrag. Dieser ausdrücklich aktivierte Vollvergleich hat weiterhin sein separates 3-Minuten-Budget; der normale Packtest bleibt bei 30 Sekunden. Log: `/private/tmp/open-fingerprints.log`.


Abschließender Graph-/Diffcheck: `node .gitnexus/run.cjs analyze --index-only` Exit 0; danach `detect_changes(scope: all, limit: 5000)` über LocalBackend, Exit 0: vier Dateien, alle 20 gemeldeten Symbole, `partial:false`, `truncated:false`. **Indexgrenze:** Der Funktionskörper von `validateSingleSentenceContent` wird nicht auf einen geänderten Symbolbereich abgebildet; die gemeldeten null Prozesse/LOW sind deshalb keine Entwarnung. Ergänzendes explizites `impact validateSingleSentenceContent --direction upstream --repo .` ergibt weiterhin HIGH, 13 betroffene Symbole, vier Prozesse (Staging, Kartenauswahl, Gruppenbericht, Editorprüfung). Der Enddiff wurde auf genau diese eine Produktionsfunktion abgegrenzt; gezielte Tests, vollständige Suite, Staging und Ergebnisvergleich ergänzen die unvollständige Änderungszuordnung. Vollständige Graphausgaben: `/private/tmp/open-graph-final.json`, `open-validator-impact-final.log`.

`git -c core.whitespace=cr-at-eol diff --cached --check` für die vier eigenen Dateien: kein Output, Exit 0. NEXTSTEPS bleibt bei 25 Zeilen. Keine Änderungen am Hauptcheckout oder fremden Dateien, kein Push.
