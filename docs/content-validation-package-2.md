# Inhaltsvalidierung – Paket 2

Stand: 19.10.2026. Basis `61971b7`, Worktree `batch-content-queries/sprachapp`; anfangs sauber. Paket 2 auf ausdrücklichen Auftrag produktiv angebunden. Kein Push, keine Abhängigkeits-, Inhalts-, Schema-, SRS- oder Cloudänderung. Geräteinstallation ausschließlich als Update; keine Deinstallation oder automatisierten Reviews.

## Produktiver Ablauf und Schutzgrenzen

`ContentPackInstaller.forApp` bezieht genau dieselbe statische `ProcessValidationRegistry.forAppSupport` über Sprachwechsel, Providerinvalidierung und Aktivierung hinweg. Der private `content-readers/process-*`-Ordner hält eine OS-Dateisperre; Cleanup erfasst nur erkennbare, entsperrte eigene Prozessordner. Symlinks, unbekannte Ordner und lebende Prozesse bleiben erhalten. Der Lock ist kein Validierungsnachweis. Bei Appneustart sind die zwei RAM-Nachweise verloren.

Der Owner-Schlüssel enthält Sprache, Generation und Fingerprint über das gesamte kanonische Releaseangebot einschließlich Manifest, beider Objektdeskriptoren, Profil und Validierungsvertrag. `createContentOwner` verbindet den vorhandenen Single-flight-/Lease-Owner mit dem Abbruchsignal. Letzter Interessent cancelt; ein verbleibender Interessent darf fertig werden. Erfolgreich geschlossene, unbenutzte globale Owner werden entfernt; noch referenzierte alte Providerobjekte delegieren neue Leases an den kanonischen Owner. Closefehler halten die Barriere.

Download-`open` führt direkt zu `openRecoveredContent → openBoundReader → ContentDatabase.fromBoundReader`. Kein vorgeschaltetes `install/recoverContentInstallation/verifyGeneration` und kein anschließendes `openInBackground` auf diesem Pfad. Ein Miss prüft fachlich einmal; ein Hit kopiert und hasht SQLite erneut, hasht das Inventar erneut, prüft Integrität und Release und verwendet exakt den geprüften read-only Handle. Der einzelne Worker aus Paket 1 bereitet vor und wird mit `DriftIsolate.inCurrent` zum Reader. Legacy-/Tool-`install` und Bootstrap bleiben vollständig prüfend. Bootstrap belegt über `bindExternalReservation` ebenfalls einen der drei Readerplätze bis zum tatsächlichen Close.

`resolveInstalledState` liest ausschließlich Metadaten. Committed muss exakt zum aktiven Angebot passen; Prepared muss Previous oder Next entsprechen. `confirmCurrent` vergleicht Journalsnapshot, vollständige Identität, gültigen Owner/Abbruch und sprachbezogenen Invalidierungsepoch. Prepared ignoriert den Cache. Erfolgreiches Next wird nach vollständiger Prüfung und Handshake committed, danach veröffentlicht. Defektes Next wird nur bei noch unverändertem Journal und aktuellem Vorgang zurückgesetzt. `RecoveredGenerationChanged` löst genau einen neuen Owner-Key-Versuch aus. Previous wird durch Invalidierung vollständig geprüft. Zweite Änderung, fehlende oder beschädigte Dateien scheitern sichtbar; kein stiller Download-Downgrade auf Bootstrap.

Prepare und Restore invalidieren die betroffene Sprache. Download, Pending-Prüfung, `verifyGeneration(previous: ...)` mit Historienvergleich und erneute `latest`-Freigabe vor Aktivierung bleiben unabhängig vom Read-Nachweis vollständig erhalten. Der Updateprovider invalidiert den alten Scope und startet den neuen vor Resume. Vor dem abschließenden Aktivierungs-Commit vergleicht der Service den tatsächlich aktiven vollständigen Zeiger erneut mit Next; eine während des Opens erfolgte Rücksetzung auf Previous ist ein Aktivierungsfehler, kein Erfolg. Alte geleaste Reader werden weder durch LRU-Eviction noch durch Statusanzeigen geschlossen; UI-Übungen behalten das bestehende Transition-Gate.

Status nutzt `readInstallationMetadata` und optional einen nicht öffnenden `peekContentOwner`. Ohne geöffneten geprüften Reader heißt die Anzeige ausdrücklich „Prüfung beim Öffnen“; Prepared verlangt Wiederherstellung beim Öffnen. Kein Status-Hash, Reader oder Recovery. Zwei Proofs, drei Readerreservierungen, keine neue Warteschlange oder permanente Warmhalte-Lease. Private Kopien werden nach bestätigtem Worker-/Connection-Close gelöscht; Close-/Cleanupfehler geben keine unsicheren Plätze frei.

Die Bytebindung schützt innerhalb der vertrauenswürdigen App-Sandbox gegen geänderte Quelldateien, auch bei gleicher Größe/mtime. Sie behauptet keine Manipulationssicherheit gegen kompromittierten Prozess/OS und macht aus Manifesthashes keine Signaturen. Ein Prozessnachweis bestätigt ausschließlich `installedRead`, niemals Updatefreigabe oder Vorgängerkompatibilität.

## Änderungen und Tests

Produktdateien: `content_validation_session.dart`, `content_database.dart`, `content_pack_installer.dart`, `content_update_service.dart`; Provider `database_providers.dart`, `language_selection_provider.dart`, `content_update_provider.dart`. Keine Änderung an Journal-/Releaseformaten. Testanpassungen: vollständiger Owner-Key und neue Open-Signatur in `test/fixtures/language_selection.dart`, `test/data/portuguese_installation_test.dart`, `test/content_loading_performance_test.dart`.

Neu: `test/data/content_validation_integration_test.dart`, 15 Tests mit realen temporären SQLite-/Drift-Beständen. Drei en→pt-BR→en-Wechsel ergeben insgesamt zwei fachliche Vollprüfungen und sieben Prüfungen jedes Datei-Hashes; Karten und Stapelreihenfolge bleiben gleich. Weitere Fälle: viele Statusabfragen ohne Reader, Single-flight, teilweise/letzte Abmeldung, Prepared-Next/Previous/defektes Next, Committed-Widerspruch, Journaltausch am Handshake, schnelle Wechsel und beschädigtes Ziel bei weiter nutzbarem Englisch, eigenes Prozess-Cleanup, Bootstrapreservierung, gehaltene Reader bei LRU-Eviction, Invalidierung während Open und Aktivierungsprüfung trotz vorhandenem Proof.

Die 28 Paket-1-Tests ergänzen gleiche Größe/mtime, Austausch während Copy/Hash, Inventar-/Manifest-/Profilwechsel, fehlende Dateien/Proofs, neuen Prozess, drei belegte Slots, Close-/Cleanupfehler und unveränderte historische Leser. Bestehende Sprach-/Form-/Historien-/Home-Tests laufen zusätzlich in der Gesamtsuite. Normale Tests enthalten keine fragilen Millisekundengrenzen; Realpackbudget bleibt 30 s.

Drift gibt in Debugtests bei mehreren gleichzeitig lebenden `ContentDatabase`-Instanzen eine allgemeine Warnung aus. Sie wird nicht unterdrückt. Die getesteten Packs besitzen verschiedene Snapshotdateien und eigene Worker/Executor; gleiche Identität teilt einen Owner. Dies ist kein beobachteter Zugriff zweier Instanzen auf denselben Executor.

## Prüfprotokoll

Flutter-/Dart-Befehle sind unter macOS Terminal und Windows PowerShell identisch. iPhone-Build und Installation benötigen macOS. Logs liegen außerhalb Git unter `/private/tmp/package2-*.log`; die folgenden Ergebnisse bleiben hier erhalten.

| Prüfung | Tatsächlicher Output | Exit |
|---|---|---:|
| `flutter test --no-pub test/data/content_validation_integration_test.dart test/data/content_validation_session_test.dart test/data/content_owner_barrier_test.dart test/language_selection_test.dart test/language_update_lifecycle_test.dart test/data/content_update_test.dart test/data/portuguese_installation_test.dart` (vor abschließender Zusatzregression) | `00:04 +68: All tests passed!` | 0 |
| `flutter test --no-pub` | `00:55 +479 ~6: All tests passed!` | 0 |
| `flutter test --no-pub test/data/real_pack_test.dart` | `00:05 +1: All tests passed!` | 0 |
| `flutter analyze --no-pub` | Nur `test/data/baseline_adoption_pack_test.dart:43:7 • avoid_print`, `1 issue found` | 1 |
| `dart run tool/stage_content_pack.dart --verify` | SHA `b85793932825a22e92ac744a42255e9f333acd35809aaba46edb5a395f099bdb`, `22 table counts match finalization_report.json` | 0 |

Frühe Korrekturen: Testfixture zunächst mit falschem Directory-Parametertyp (Compilefehler); verschachtelte Record-Listen dann auf Inhaltsvergleich umgestellt. Die erste Gesamtsuite erwartete noch den alten Status-Open und scheiterte daran; die neue Erwartung verlangt null Status-Opens. Danach obige grüne Gesamtsuite. Eine neue Test-Klammerlintstelle wurde korrigiert; erneute Analyse enthält ausschließlich den Altbefund. Keine Prüfung entfernt oder Warnung unterdrückt. Ein zsh-Hilfsbefehl verwendete versehentlich `path`, scheiterte vor Testausführung und wurde mit `task_file` korrigiert.

## iPhone-Profile-Messung

Gerät `00008110-001651611E01401E`, bestehende Signierung und Bundle-ID. Separater Prozessstart, anschließend manuell ausgelöste Wechsel; keine parallelen Builds/Tests während der Messung. Der Nutzer bestätigte die Bedienabläufe. Tatsächliches Englisch: Schema 5, `chitchat_de_korrektur_v1`, 43 089 920 Byte SQLite, nicht der Schema-4-Bootstrap. Portugiesisch: Schema 5, `ptbr_allgemeine_sprache_v1`, 311 296 Byte SQLite.

Temporäre Sonde: Stopwatch um `selectLanguage` und Bound-Open, Worker-Phasen Copy/Hash/Vollprüfung/Integrität, ProviderObserver für benötigte Home-Daten, PostFrameCallback nach Stapel- und Vokabeldaten, Session-Observer für erste Übung. Kein Inhalts-, Token-, Login- oder Lernstanddump. Phasen enthalten IO-/Scheduling-/Messkosten, nicht nur CPU. `full_validation` enthält auch SQLite-Open, `cache_hit` nur Open/Übernahme des bereits geprüften Ergebnisses. Der gemeldete Home-Frame ist ein Frame nach Datenbereitschaft, kein Pixel-/Displaylatenznachweis.

| Messgröße | Bisherige Messung | Paket 2 |
|---|---:|---:|
| Kalter Prozess: ContentRepository bereit | 5 068 ms | 4 154 ms |
| Kalter Prozess: Home-Frame | 6 435 ms | 5 508 ms |
| Warmer Wechsel pt-BR→en, erste drei Läufe | Median 4 989 ms | 824,215 / 828,750 / 825,612 ms; Median **825,612 ms** |
| Alle acht warmen pt-BR→en-Wechsel | — | **Median 812,258 ms**, Bereich 785,151–828,750 ms |
| Home-Projektion bis Stapel/Vokabeln bereit | vorher nur Einzelmessung | 1 340 / 1 356 / 1 305 ms |
| Home-Projektion bis anschließendem Frame | 1 294 ms, Einzelmessung | 1 350 / 1 357 / 1 306 ms; **Median 1 350 ms** |
| Erste Übung | 62 ms, Einzelmessung | 61 / 59 / 60 ms; **Median 60 ms** |

Alle acht Wechselzeiten in Reihenfolge (ms): 824,215; 828,750; 825,612; 796,203; 794,571; 785,151; 800,301; 827,868. Die zusätzlichen Durchgänge dienten den zunächst fehlenden Home-/Übungsendpunkten; keine Auswahl nur schneller Läufe. Die vollständigen Home-/Übungspaare gehören zu Wechsel 3, 5 und 8. Der Nutzer führte zunächst mehrere Wechsel in den Einstellungen aus; nach gezielter Rückfrage liegen drei vollständige Endpunkte vor. Ein zusätzlicher Vokabelrefresh ohne neuen Sprachwechsel zählt nicht als neuer Home-Lauf.

Zwischen diesen Wechselenden und Home-Ladebeginn lagen rund 1 442 / 6 274 / 3 274 ms Bedienpause. Diese Pausen werden nicht als Rechenzeit gerechnet. Home-Dauer basiert auf dem gemeinsamen Stapel-/Vokabel-Ladebeginn; Catalog/Resolver starten teilweise 1 ms früher (Observerauflösung). **Kein kontinuierlicher Tap→Home-Wert ohne Bedienpause** wird behauptet. Rechnerisch sind die getrennten Mediananteile etwa `0,812 + 1,350 = 2,162 s`; dies ist eine Addition gemessener Teilwerte, keine gemessene durchgehende Gesamtdauer.

| Englisch-Open-Phase | Erste Prüfung | Warme Opens, Median über 8 |
|---|---:|---:|
| Private Kopie inkl. Flush | 270,185 ms | 168,303 ms |
| SQLite-Hash/Lese-/Checkpointzeit | 477,460 ms | 456,996 ms |
| Inventar-Hash/Lesezeit | 115,252 ms | 111,928 ms |
| Fachliche Vollprüfung inkl. SQLite-Open | 3 185,028 ms | **0 Aufrufe** |
| quick_check und Release | 27,416 ms | 27,532 ms |
| Worker-Vorbereitung gesamt | 4 075,737 ms | 774,568 ms |
| BoundReader fertig | 4 078,538 ms | 787,429 ms |

Englisch und Portugiesisch wurden jeweils genau einmal fachlich vollständig geprüft; alle späteren Opens waren Hits mit erneuten beiden Hashprüfungen. Die erste portugiesische Auswahl dauerte 89,458 ms inklusive Vollprüfung; folgende Wechsel lagen bei etwa 60–71 ms. Die App-Prozessnachweise überleben damit die tatsächlichen Sprachwechsel. Maximal **2 Readerreservierungen**, nach Wechsel wieder **1**. Höchstens **43 401 216 Byte** temporäre SQLite-Kopien (EN + PT, etwa 41,39 MiB), über Dateilängen im Prozessordner am Open-Endpunkt erfasst. Keine Aussage über gesamten App-RAM oder physisch belegte APFS-Blöcke. Tests bestätigen Freigabe nach letztem Close; die Messung beendet anschließend den Prozess.

Größter protokollierter Frame im Ablauf: 31 ms, maximale Build-Dauer 29 ms. Keine sekundenlange synchrone UI-Blockade beobachtet. Warmes Packbereit ist in allen acht Läufen unter 1 s, gegenüber dem bisherigen Median ungefähr 84 % kürzer. Kalte erste Prüfung bleibt teuer. Home ist unverändert ein eigener Restposten; die neue Home-Messreihe belegt keine Home-Beschleunigung. Die erste Übung bleibt schnell, keine beobachtete Verschiebung der eingesparten Vollprüfung dorthin. Installation/Aktivierung einer neuen Generation wurde ausschließlich synthetisch getestet, nicht auf echten Inhalten zeitlich vermessen.

Auf macOS tatsächlich ausgeführt:

```text
flutter run --no-pub --profile -d 00008110-001651611E01401E -t lib/perf_measurement.dart --dart-define=SUPABASE_URL=https://yevntxclpchapacqdizm.supabase.co --dart-define=SUPABASE_ANON_KEY=sb_publishable_L5eGU_WxPDiIO07xvilfNQ_xYgIQ0Wr
flutter run --no-pub --profile -d 00008110-001651611E01401E -t lib/main.dart --dart-define=SUPABASE_URL=https://yevntxclpchapacqdizm.supabase.co --dart-define=SUPABASE_ANON_KEY=sb_publishable_L5eGU_WxPDiIO07xvilfNQ_xYgIQ0Wr
```

Die angegebenen Dart-Defines sind öffentliche Clientkonfiguration, kein Anthropic-Secret. Messbuild: `Xcode build done. 49,9s`, erfolgreich installiert/gestartet, mit `q` beendet, Exit 0. Danach sämtliche instrumentierten Produktdateien bytegleich aus der Sicherung zurückgespielt, beide temporären Dart-Dateien entfernt. Rohlog `/private/tmp/package2-device.log`; normale Installation `/private/tmp/package2-normal-device.log`. Keine Sonde gehört zum Commit.

Normaler Profile-Build: `Xcode build done`, `Installing and launching... 3,4s`, erfolgreich gestartet und mit `q` beendet (Exit 0). Keine `[bound]`-/`[perf]`-Ausgaben im normalen Log. Eine native malloc-Diagnose beim Start wurde nicht unterdrückt; Build, Start und Flutter-Session liefen erfolgreich.

Abschließende Aktivierungsregression: Nach bestandener Vorprüfung wurde der synthetische Kandidat im Close-Hook beschädigt. Der gebundene Open stellte Previous wieder her. Vor dem Fix meldete `activate` dennoch Erfolg (gezielter Test Exit 1, `Expected: throws StateError; ... emitted null`). Nach dem vollständigen Zeigervergleich: `flutter test --no-pub test/data/content_validation_integration_test.dart test/data/content_update_test.dart test/language_update_lifecycle_test.dart` → `00:06 +29: All tests passed!`, Exit 0. Anschließend nochmals gesamte Suite/Analyse und finaler normaler Profile-Build. Die nachgemessenen normalen Read-/Sprachwechselpfade wurden durch diese Aktivierungsabsicherung nicht geändert; keine weitere Live-Messreihe nötig.

## Abschlusskontrolle

GitNexus vor Produktänderungen: RepositoryOwner, Installer und Updateservice CRITICAL (betroffene direkte Aufrufer und Prozesse vorab gewarnt), Controller/Registry LOW. Beim abschließenden Aktivierungsfix Updateservice HIGH, fünf direkte Abhängigkeiten/drei Prozesse; ebenfalls vorab gewarnt. UNKNOWN/Dart-Dispatch und Dokumentreferenzen wurden direkt am Quelltext ergänzt. Der Index bildet Dart-Körper und generierte Prozesszuordnungen teilweise unvollständig ab; fehlende Graphpfade wurden nicht als Sicherheitsnachweis gewertet. Finaler Index über `node .gitnexus/run.cjs analyze --index-only`; vollständige `detect_changes(scope: all, limit: 5000)`- und Staged-Prüfung vor Commit, keine abgeschnittene oder partielle Änderungsliste.

Gezielter Check: `git -c core.whitespace=cr-at-eol diff --cached --check`; zusätzlich ursprüngliche CRLF-Konventionen und NEXTSTEPS mit 25 Zeilen geprüft. Nur die genannten Produkt-/Testdateien und drei Dokumentberichte plus NEXTSTEPS werden committed. Temporäre Sonden fehlen, normale Produktdateien wurden bytegleich restauriert; keine Pack-, Signierungs-, Abhängigkeits- oder echten Lernstandsdateien im Diff. Kein Push.

Finaler normaler Gerätebuild einschließlich Aktivierungsabsicherung: `Installing and launching... 3,6s`, gestartet, ohne Sonden-Ausgaben, mit `q` beendet (`NORMAL_PROFILE_EXIT=0`). Finales Log `/private/tmp/package2-normal-final-device.log`. Graphprüfung: 15 geänderte Dateien, 55/55 Symbole, 12 betroffene Abläufe, Risiko HIGH, `partial:false`, `truncated:false` (Exit 0). Betroffen sind die erwarteten Sprachwahl-, Metadaten-/Recovery- und Updateservice-Pfade; `VerifyCode → ContentUpdateService` entsteht aus der bestehenden Serviceinitialisierung, nicht aus einer Authentifizierungsänderung.
