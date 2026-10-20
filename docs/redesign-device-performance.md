# Geräteabnahme des integrierten Redesigns · 20.10.2026

## Ergebnis

**Teilweise bestätigt, keine uneingeschränkte Performancefreigabe.** Drei Kaltstarts, vier manuelle en→pt-BR→en-Runden, Lernöffnungen/Rückwege, drei gesonderte Tabwechsel und eine Hintergrundrückkehr wurden auf dem freigegebenen iPhone im Profile-Modus geprüft. Der Nutzer bestätigte vollständig sichtbares/bedienbares Home und keine auffälligen Hänger oder falschen Sprachinhalte bei seinen Durchläufen. Die Messung zeigt dennoch einzelne langsame Frames und zwei zusätzliche portugiesische Vollprüfungen bei warmen Zugriffen.

- **Bestätigt:** englische Prozessnachweise bei allen vier warmen Wechseln; unveränderte Packversionen; schnelle erste Aufgabe; Home bleibt bei Rücknavigation/Tabwechsel/Resume erhalten; keine Readeröffnung oder Vollprüfung beim Resume. Original-Packtest besteht ohne Timeout-Erhöhung.
- **Abweichung:** „keine erneuten warmen Vollprüfungen“ ist für Portugiesisch in dieser Reihe nicht erfüllt (2 von 3 warmen Zugriffen). Ursache und Notwendigkeit dieser Prüfungen sind nicht nachgewiesen. Keine kausal belegte Redesign-Regression: die betroffenen Daten-/Sprachwechseldateien sind gegenüber `a66bab0` unverändert.
- **Noch nicht belastbar messbar:** Unterschied der Frame-Spitzen gegenüber der alten UI, vollständige physische Bildschirm-/Eingabelatenz, tatsächliche Sternfeier mit neu verdientem Stern und Verlustfreiheit sämtlicher Lernstände durch einen Datenbankvergleich. Keine Behauptung „alles flüssig“ aus grünen Tests.
- **Nächste Arbeit:** portugiesische Nachweisverwerfung gezielt mit Öffnungsmodus, anonymem Identitätsvergleich, Epoch-/Invalidierungsgrund und abgebrochenen Öffnungen nachvollziehen; separat einen Frame-Timeline-Trace der ersten Home-/Popover-Darstellung und Stapelübergänge aufzeichnen. In diesem Auftrag wurde kein Produktproblem behoben.

## Stand, Gerät und Messgrenzen

Hauptordner `/Users/ardasayar/Documents/FlutterProjekte/sprachapp`, Branch `main`, gemessener HEAD `b5a6bd3` (optimierte Basis `a66bab0` enthalten). Fremde unversionierte Ordner/Dateien `published-baseline-transfer/` und `skills-lock.json` bleiben erhalten. Kein Build aus der Redesign-Kopie oder dem früheren Worktree.

Gerät: **iPhone von Claus**, UDID `00008110-001651611E01401E`, iPhone 14 Plus (`iPhone14,8`), iOS **18.7.2 / 22H123**, Kabelverbindung. Bundle `com.example.sprachapp`, bestehende Signierung Team `W27Z6DNPT3`. Updateinstallation, keine Deinstallation. Flutter meldet Profile-Modus und Metal/Impeller. Gemeldete Displayrate **60 Hz**, daraus Budget **16,667 ms** jeweils für Build und Raster.

Alle Flutter-Starts verwendeten `flutter run --no-pub --profile -d 00008110-001651611E01401E` aus dem Hauptprojekt und unverändert beide vom Nutzer vorgegebenen `--dart-define=SUPABASE_URL=…` / `--dart-define=SUPABASE_ANON_KEY=…`. Der vollständige Befehl steht im Nutzerauftrag; der Clientkey wird hier nicht erneut abgelegt. Einstieg immer `lib/main.dart`. Keine Modellanfragen, Deployments, Pushes oder Änderung von Packs, Manifesten oder Cloudkonfiguration.

Zeitnull der Kaltmessung ist die erste Anweisung in `main()`. Native Prozessinitialisierung, Tap auf das App-Symbol, Build und Installation sind ausgeschlossen. Jeder gültige Kaltlauf hat einen neuen Prozess, eigene Stoppuhr und einen neuen englischen Vollprüfungsnachweis. Die vorherigen Flutter-Prozesse wurden mit `q` beendet. Ein zusätzlicher direkter `devicectl --terminate-existing --console`-Start zeigte laut Nutzer Home, lieferte aber keine Flutter-Messausgabe; er wurde verworfen und einmal über Flutter wiederholt. Keine Debug- oder Simulatorzeiten. Während der Gerätezeitmessungen liefen keine Builds, Tests oder Indexierung parallel.

„Home-Frame“ bezeichnet einen **Flutter-PostFrame-Messpunkt**, ergänzt durch Nutzerbestätigung der sichtbaren Oberfläche, keine optische Messung der Displayausgabe. Das erste Home ist zunächst ein Gerüst mit Ladezuständen. „Vollständig“ umfasst die beobachteten Daten für Stapel, Vokabelzahlen, Fortschritt, Streak, lexikalische Zahlen, Storyliste und Wort der Woche. Das Ende der privaten JSON-Lesestand-Lesung hat keinen eigenen Abschlussmesspunkt; deshalb ist dies keine Garantie, dass jedes interne asynchrone Detail bereits beendet ist. Die Hauptaktion wurde anschließend durch echte Lernöffnungen funktional geprüft, nicht durch automatisierte Eingaben beim Start.

## Aktive Packs

| Sprache | Version | Schema | SQLite-Bytes |
| --- | --- | ---: | ---: |
| Englisch | chitchat_de_korrektur_v1 | 5 | 43.089.920 |
| Portugiesisch | ptbr_allgemeine_sprache_v1 | 5 | 311.296 |

Beide entsprechen den früheren Geräte-Vergleichspaketen. Die lokale Stage-Prüfung prüft hingegen das gebündelte Bootstrap-Testpaket `story_single_sentence_v1`, Schema 4, 26.198.016 Bytes; diese Dateien sind nicht mit den aktiven Gerätepaketen zu verwechseln. Keine Lerninhalte, Wörter, Sätze, Karten-/Stapel-IDs oder persönlichen Daten wurden durch die Sonde ausgegeben.

## A · Drei Kaltstarts

Alle Zeiten ab `main()`, Millisekunden:

| Lauf | Content-Provider bereit | erster Home-PostFrame (Gerüst) | vollständiger gemessener Home-PostFrame |
| --- | ---: | ---: | ---: |
| 1 | 4.028,7 | 47,1 | 5.546,9 |
| 2 | 4.442,2 | 29,8 | 5.966,5 |
| 3 | 3.869,0 | 29,8 | 5.429,9 |
| Median | **4.028,7** | **29,8** | **5.546,9** |
| Spannweite | 3.869,0–4.442,2 | 29,8–47,1 | 5.429,9–5.966,5 |

Die anfänglichen Ladezustände für Vokabel-/Stapeldaten verschwanden bei ca. 5.325/5.349, 5.727/5.751 und 5.190/5.214 ms. Das entspricht ungefähr 5.302, 5.721 und 5.184 ms vom ersten Home-Gerüst bis zum letzten dieser Ladeblöcke. Lexikalische Zusatzdaten folgen danach bis zum vollständigen Messpunkt. Der Nutzer bestätigte jeden Kaltstart separat als vollständig sichtbar und bedienbar; genaue sichtbare Ladebalkendauern sind aus UI-Zuständen abgeleitet, nicht videografisch gemessen.

Vorwert: Content 4.154 ms, Home 5.508 ms (damals jeweils ein kalter Prozess, keine gleich große Reihe). Neue Mediane ca. −3,0 % / +0,7 %. **Keine belastbare Regression oder Beschleunigung daraus ableiten.** In den drei neuen Läufen entfielen ca. 3,03–3,37 s auf den Abschnitt zwischen Inventory-Hash-Ende und Ende der fachlichen englischen Vollprüfung. Danach bleiben ca. 1,52–1,56 s zwischen Content-Bereitschaft und vollständigem gemessenem Home. Diese Restarbeit ist weiterhin vorhanden.

## B · Sprachwechsel im selben Prozess

Beginn: `LanguageSelectionState.switching=true`, nach Bestätigung der Sprachauswahl. Ende Pack: Content-Provider der Zielansicht bereit. Ende Home: vollständiger gemessener Ziel-Home-PostFrame. Die Auswahl erfolgte im Home-Popover; keine zusätzliche Navigation zu Home und keine eingerechnete Bedienpause. Die Pause beim Auswählen im Popover liegt vor dem Messbeginn.

| Ziel / Zugriff | Pack bereit | anschließend bis Home-Frame | direkt gemessen: Wechsel bis Home | Vollprüfung |
| --- | ---: | ---: | ---: | --- |
| pt-BR, erster Prozesszugriff | 84,8 | 48,2 | 133,0 | ja |
| en, warm 1 | 838,5 | 1.288,7 | 2.127,2 | nein |
| pt-BR, warm 1 | 83,7 | 49,3 | 133,1 | **ja** |
| en, warm 2 | 869,4 | 1.351,0 | 2.220,4 | nein |
| pt-BR, warm 2 | 87,7 | 44,8 | 132,5 | **ja** |
| en, warm 3 | 785,5 | 1.290,7 | 2.076,2 | nein |
| pt-BR, warm 3 | 62,0 | 54,3 | 116,3 | nein |
| en, warm 4 | 857,5 | 1.281,3 | 2.138,8 | nein |

| Warme Reihe | n | Pack-Median (Spannweite) | Home danach, Median (Spannweite) | direkt gemessener Gesamtmedian (Spannweite) |
| --- | ---: | ---: | ---: | ---: |
| pt-BR→en | 4 | **848,0** (785,5–869,4) | **1.289,7** (1.281,3–1.351,0) | **2.133,0** (2.076,2–2.220,4) |
| en→pt-BR | 3 | **83,7** (62,0–87,7) | **49,3** (44,8–54,3) | **132,5** (116,3–133,1) |

Gesamtzeiten stammen aus jedem tatsächlichen Durchlauf, nicht aus addierten unabhängigen Medianen. Der erste portugiesische Zugriff ist ausgeschlossen. „Warm“ bedeutet wiederholter Sprachzugriff im selben Prozess; wegen der zwei Vollprüfungen ist die portugiesische Reihe **keine reine Cachetreffer-Reihe**.

Vorher pt-BR→en: 812 ms (n=8), Home danach separat 1.350 ms. Neu Pack ca. +4,4 %, Home-Intervall ca. −4,5 %; unterschiedliche Stichproben und teils andere UI-Endpunkte, keine sichere Verschlechterung. Der erste englische Zugriff des Prozesses steht in A.

Readerzählung im dritten Prozess: **9 erfolgreiche Öffnungen**, davon **4 Vollprüfungen** (en einmal, pt-BR dreimal) und **5 Nachweistreffer** (en viermal, pt-BR einmal). Nach Erwerb beider Sprachen wurden jeweils zwei Nachweise gemeldet. Bei warmen englischen Readern entfielen weiterhin Copy/Hash/Inventory/Integritätsprüfung, aber keine fachliche Vollprüfung. Die zusätzliche portugiesische fachliche Prüfung dauerte jeweils nur ca. 26–30 ms; klein, aber dennoch ein nicht erfülltes Nachweis-Kriterium.

Die Sonde zählt erfolgreiche Reader/Prüfungen, nicht jeden möglicherweise vor dem Handshake abgebrochenen Öffnungsversuch. Sie protokolliert weder vollständigen Fingerprint noch Invalidierungsgrund. Damit lassen sich Recovery-Modus, geänderte Angebotsidentität oder ein Nachweisverlust nach abgebrochenem Öffnen nicht unterscheiden. Genau diese Pfade sind die begrenzte nächste Untersuchung. Zusätzlich stand beim ersten portugiesischen Zugriff einmal `Inhaltsupdate fehlgeschlagen: Schritt: setup · Lokal: STATE` im normalen App-Log. Keine Zuordnung dieser Meldung zur Nachweisverwerfung bewiesen; der aktive Inhalt blieb benutzbar.

## C · Stapel, erste Aufgabe und Rückwege

Der Nutzer bestätigte drei gleiche Abläufe ohne Antwort/Reveal/Review. Das Log enthält insgesamt **fünf** erfolgreiche Aufgabenöffnungen; alle werden ausgewiesen, keine stille Auswahl der besten drei:

| Öffnung | Provider: erste Aufgabe bereit | nächster UI-PostFrame ab Ladebeginn |
| --- | ---: | ---: |
| 1 | 66,0 ms | 88,9 ms |
| 2 | 63,5 ms | 70,6 ms |
| 3 | 60,2 ms | 70,8 ms |
| 4 | 66,7 ms | 87,6 ms |
| 5 | 59,7 ms | 70,1 ms |
| Median / Spannweite | **63,5 / 59,7–66,7 ms** | **70,8 / 70,1–88,9 ms** |

Nur die ersten drei: Provider-Median ebenfalls 63,5 ms, Spannweite 60,2–66,0; Frame-Median 70,8 ms, Spannweite 70,6–88,9. Vorher Provider-Median 60 ms. Öffnung heißt Messbeginn der Session, nicht physischer Tap. Die reine Stapeldetail-Bereitschaft hat keinen separaten Daten-Ready-Messpunkt; Route-Push und Nutzerbestätigung belegen die Öffnung, keine eigenständige Detail-Latenzzahl.

Jede Aufgabenöffnung: **+9 User-SELECTs, +5 Content-SELECTs**, kein zusätzlicher instrumentierter Schreibaufruf. Rückwege bis Home: **keine zusätzlichen SQL-Aufrufe**, kein Reader, kein erneutes Loading der beobachteten Home-Daten. Die erfassten Rückwege schließen erst die Übungsroute und dann die Stapeldetails. Die Route-zu-Home-PostFrame-Zeit beträgt ca. 520–538 ms einschließlich Navigation/Übergang; das ist keine Home-Daten-Neuberechnungszeit und keine Bestätigung eines bestimmten getippten Buttons.

Drei gesonderte Stories→Home-Tabwechsel sind im Log vorhanden: vom Home-Tab-Build zum vollständigen Home-PostFrame **10,3 / 11,7 / 11,6 ms**, Median 11,6 ms. Keine zusätzlichen SQL-Aufrufe, kein Datenladeblock. Tatsächliche Aufenthalte im Stories-Tab ca. 4,55 / 0,88 / 0,80 s; die beiden letzten sind kürzer als angefordert. Kein anhaltender Frame-Strom in der längsten Ruhephase; dies plus bestehendes `TickerMode` und Tests stützt die Begrenzung inaktiver Home-Animationen, ersetzt aber keinen langen Energie-/CPU-Test oder eine echte Sternfeier.

Streak wurde früh unabhängig vom großen Inhaltsreader fertig. Das Wort der Woche erzeugte in diesem beobachteten Zustand keinen erkennbaren zusätzlichen SQL-Anstieg bei seiner Bereitschaft; die aktive „verdienter Wochenstern“-Variante ist damit nicht geprüft. Quellprüfung: Streak nutzt eine Sammelabfrage, Wort der Woche vorhandene Resolver-/Zustandsdaten und höchstens eine ausgewählte Einzelhistorie. Der synthetische Test belegt eine Streak-Sammelabfrage ohne Kartenhistorien-Schleife. Abfragezahlen sind gemeinsame Zähler, keine exklusive kausale Zuordnung gleichzeitig laufender Provider.

## D · Hintergrundrückkehr

Gleicher dritter Prozess, `paused` bei 207.765,5 ms, `resumed` bei 221.589,1 ms: **13,82 s pausiert**. Keine erneute `main()`-Ausgabe, Readeröffnung oder Vollprüfung. Keine instrumentierten Writes.

Home verwendet während der Aktualisierung weiterhin vorhandene Stapel-/Vokabel-/Fortschritts-/Streak-Daten. Wort-der-Woche-Provider ca. 24 ms, Streak ca. 25 ms, Fortschritt ca. 28 ms, Vokabelzahlen ca. 279 ms neu berechnet. Nach ca. 39 ms wurde wieder ein vollständig belegter Home-Zustand gemeldet, wobei Vokabelwerte zunächst aus dem stabilen Cache stammen. **Das ist keine vollständig abgeschlossene Neuberechnung nach 39 ms.** Bis Ende der Hintergrundauffrischung kamen +71 User-SELECTs und +54 Content-SELECTs hinzu. Keine vollständige Inhaltsneuladung; ebenso wenig „null Arbeit beim Resume“. Nutzer: Home sofort wieder da.

## Abfragen, Sprache und Lernstände

Alle drei Kaltstarts bis vollständiges gemessenes Home: je **102 User-SELECTs / 894 Content-SELECTs**. Jeder warme Wechsel nach en bis Home: **97 / 845**, nach pt-BR **22 / 27**, jeweils zusätzlich ein durch den Nutzer ausgelöstes Settings-Update für die Sprache. Gesamter dritter Prozess einschließlich fünf Aufgabenöffnungen und Resume: **694 User-SELECTs / 4.461 Content-SELECTs / 8 User-Updates**, keine anderen erfassten Schreiboperationen.

Zählbereich: weitergeleitete Drift-Aufrufe der App, nicht die SQL-Anweisungen im rohen SQLite-Validator, keine Gewichtung nach gelesenen Zeilen und keine exklusiven Home-Kosten. Batchaufrufe würden als Batch, nicht als einzelne SQL-Anweisungen zählen. Daher nicht direkt mit anders instrumentierten alten Repository-Abfragezählern vergleichen. Die 8 Updates entsprechen den 8 bewusst ausgeführten Sprachwechseln. Keine echten Reviews oder Stapelaktivierungen automatisiert. Stapel-Umschalten ausschließlich in den bereits bestehenden synthetischen Tests geprüft.

Beobachtete Zielsprachen und Packmetadaten passen zueinander; der Nutzer meldete keine falschen Inhalte. Sprach-/Generationsisolation wird zusätzlich von den gezielten Tests geprüft. Die Sonde überprüft jedoch nicht jede dargestellte Kartenidentität gegen einen Fingerprint. Keine Lernstandsverluste beobachtet, aber keine persönliche `user.db` kopiert oder vor/nachher inhaltlich verglichen: vollständige Verlustfreiheit ist daraus nicht bewiesen.

## Frame-Zeiten

Emittierte Messfenster bei 60 Hz; Build und Raster getrennt, keine Verwendung der gesamten Pipeline-Zeit als 16-ms-Grenze:

| Log | erfasste Frames | Build >16,667 ms / Maximum | Raster >16,667 ms / Maximum |
| --- | ---: | ---: | ---: |
| Kaltstart 1 | 295 | 0 / 13,1 ms | 2 / **192,3 ms** |
| Kaltstart 2 | 293 | 0 / 11,4 ms | 1 / 18,1 ms |
| Prozess 3 mit allen Abläufen | 3.155 | 10 / **28,3 ms** | 1 / **328,5 ms** |

Fenster werden beim nächsten Frame nach mindestens einer Sekunde ausgegeben; ein ruhender Rest am Prozessende wird nicht separat geleert. Zahlen sind deshalb keine lückenlose Frame-Inventur. Der 328,5-ms-Rasterframe liegt im gemeldeten Sammelfenster 5,229–29,833 s (letzte Startframes und erstes Sprachpopover enthalten); eine eindeutige Zuordnung zu genau einem Element ist daraus nicht möglich. Die Build-Spitzen liegen in Fenstern der Stapel-/Übungsübergänge und Rücknavigation. Keine vergleichbare Frame-Baseline der alten UI vorhanden: auffällig, aber **keine nachgewiesene Redesign-Ursache**.

Fenster-p95 wurden aufgezeichnet, jedoch nicht zu einem falschen globalen p95 aus Medianen zusammengefasst. Höchstes Build-Fenster-p95 in Prozess 3: 22,79 ms; höchstes Raster-Fenster-p95: 328,48 ms in einem kleinen Fenster mit fünf Frames. Für die genaue Ursache ist ein gezielter Frame-Trace sinnvoll. Die subjektiv unauffälligen Durchläufe heben diese Messbefunde nicht auf.

## Sicherung, Wiederherstellung und Prüfungen

Vor Änderungen dokumentiert in `/private/tmp/redesign-device-performance/instrumentation-plan.json`, Originalbytes und SHA-256 gesichert. Sechs temporär bearbeitete Dateien:

- `lib/main.dart`
- `lib/screens/home/home_screen.dart`
- `lib/screens/app_shell.dart`
- `lib/data/content/content_database.dart`
- `lib/data/content/content_validation_session.dart`
- `lib/data/user/user_database.dart`

Temporär hinzugefügt: `lib/device_perf_trace.dart`, `lib/device_perf_probe.dart`. Beide entfernt, alle sechs Originaldateien **bytegenau wiederhergestellt**, SHA-256-Vergleich bestanden. Keine dauerhafte Telemetrie oder Produktcodeänderung. Sonde und lokale Rohlogs liegen nur unter `/private/tmp/redesign-device-performance/`, nicht im Commit; temporäre Dateien können vom Betriebssystem gelöscht werden.

GitNexus vor Eingriffen auf den Hauptordner und HEAD gebunden, Index erneuert. Aktuell Datenbankklassen MEDIUM, UI/Registry LOW; ein älterer Index hatte UserDatabase CRITICAL gemeldet und wurde nicht als Freigabe benutzt. `main`/`SprachApp` UNKNOWN wurde durch tatsächlichen Einstieg/`runApp`/Tests quellengeprüft. Messzähler leiteten unveränderte Abfragen weiter, Ressourcenlimits und Validatorbedingungen blieben unverändert.

Exakte Prüfungen (Windows PowerShell und macOS Terminal: dieselben Flutter-/Dart-Befehle; iOS-Gerätebau hier auf macOS):

```text
flutter test --no-pub test/data/real_pack_test.dart
flutter test --no-pub test/content_loading_performance_test.dart test/learning_query_work_test.dart test/language_selection_test.dart test/language_update_lifecycle_test.dart test/data/content_validation_integration_test.dart test/data/content_validation_session_test.dart test/home_streak_test.dart
flutter analyze --no-pub
dart run tool/stage_content_pack.dart --verify
git -c core.whitespace=cr-at-eol diff --check
```

- Realpack vorher und nach Wiederherstellung: **Exit 0, `00:03 +1: All tests passed!`**. Originaldatei gegenüber optimierter Basis unverändert. Kein `--timeout`, keine neue globale Testkonfiguration; installierte Testbibliothek `test_api 0.7.12`, `invoker.dart` verwendet `Duration(seconds: 30)`, Runner-Default `30s`. Der frühere `--timeout 5m`-Lauf wird nicht als Nachweis benutzt.
- Gezielte Gruppe: **Exit 0, 66 bestanden**, sowohl ohne als auch mit Sonde. Synthetisches Open/Back/Toggle behält Metadatenabfragen bei und `histories=0`. Keine Vollsuite: keine dauerhafte Codeänderung; das Nachweisproblem wird als begrenzte offene Geräteabweichung dokumentiert.
- Analyse nach Wiederherstellung: **Exit 1**, genau ein bestehender Info-Befund `avoid_print` in `test/data/baseline_adoption_pack_test.dart:43:7`; keine neuen Fehler/Warnungen.
- Stage-Verifikation nach Wiederherstellung: **Exit 0**, 22 Tabellenzählungen stimmen; Bootstrap-SHA256 `b85793932825a22e92ac744a42255e9f333acd35809aaba46edb5a395f099bdb`.
- Whitespace-Prüfung: **Exit 0**. Nicht versionierte Fremddateien bleiben unberührt.

Normaler abschließender Profile-Build aus dem wiederhergestellten `lib/main.dart`: **`Xcode build done. 25,4s`**, **`Installing and launching... 3,3s`**, erfolgreich gestartet, keine `[rdp]`-Ausgabe; Flutter-Session mit `q` beendet, **Exit 0**. Anschließend normale App auf derselben UDID mit `xcrun devicectl device process launch --device 00008110-001651611E01401E --activate com.example.sprachapp` wieder geöffnet: **Exit 0**, `Launched application with com.example.sprachapp bundle identifier.` Die App bleibt ohne Sonde geöffnet. Native malloc-Diagnose wie bereits bei früheren Builds vorhanden; keine daraus belegte Produktregression. Nur dieser Bericht und die gezielte NEXTSTEPS-Aktualisierung werden dauerhaft übernommen; kein Push.

Abschließende GitNexus-Änderungsanalyse am expliziten Hauptordner: 2 Dokumentdateien, 2 zugeordnete bestehende Markdown-Symbole, 0 betroffene Ausführungsabläufe, Risiko niedrig; keine gemeldete Kürzung/Teilfehlermeldung. Der neue Bericht ist nicht als Runtime-Symbol indexiert. Ergänzend bestätigt der Git-Diff: ausschließlich die zwei genannten Dokumentdateien, kein Produktcode.
