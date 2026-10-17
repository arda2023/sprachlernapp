# Fehlerfeedback im Lernablauf

## Plan vor Edit

Basis: aktuelle lokale Nutzerfassung, gesichert unter build/practice_error_feedback/baseline/. Nutzeränderungen in practice_chrome.dart: Slot 40 statt 48, Container-Minimum 30 statt 48, Padding horizontal 16/vertikal 6 unverändert; außerdem lokale Formatierung. Diese Änderungen bleiben ungestagt erhalten. NEXTSTEPS und fremde Dateien ebenfalls erhalten.

Exakte geplante Dateiliste: lib/screens/decks/deck_practice_screen.dart; lib/screens/decks/widgets/practice_chrome.dart; lib/screens/decks/widgets/practice_sentence.dart; lib/screens/decks/widgets/practice_input.dart; test/practice_error_feedback_test.dart; test/learning_ui_device_fixes_test.dart (alte 48px-Erwartung auf erfasste Nutzerhöhe); docs/practice-error-feedback.md; docs/evidence/practice-error-feedback/; NEXTSTEPS.md (nicht committen).

Gemeinsamer 350ms-Controller, horizontale Amplitude 5px mit exaktem Endpunkt null; nur Button/Feld transformieren, kein Satz-/Toolbarlayout animieren. Separater 1500ms-Timer mit Generation und Passbindung. Feldfarbe bis echter Textrevision; Cursor/Fokus ignorieren. Erfolg, Reveal, Passwechsel, Rückblick, Navigation/Dispose beenden unpassendes Feedback. Submit bleibt offen, erneuter Fehler startet neu. Bestehende ordinaryErrors/Hint-/Revealhistorie bleibt. wrongForm ist laut ReviewPass ein Fehler, erhält Farbe/Schütteln, sein Formhinweis bleibt; almost/alternative bleiben neutral. Reduzierte Bewegung setzt Offset auf null. Keine Haptics/Sounds.

GitNexus impact vor Edit: alle sechs betroffenen UI-Klassen LOW; direkte Aufrufer Screen-build/Toolbar/Sentence und Tests, ein betroffener Build-Prozess bei Toolbar/Sentence. Keine Änderungen an Sessioncontroller, Klassifikation, ReviewPass, Persistenz oder Content. Index vor Commit erneuern. Impeccable-Kontextlauncher scheitert an CRLF-Shebang; Produkt/Design und Animate-/iOS-/Craft-Referenzen direkt gelesen. Nutzerauftrag hat Vorrang vor alter Höhenvorgabe.

## Abschluss der gezielten Fortsetzung (16.10.2026)

Funktional verifiziert, kein Commit und kein Push (konkreter Nutzerhunk-Blocker unten). Einzige zusätzliche Produktionsänderung dieser Fortsetzung: `mainAxisAlignment: MainAxisAlignment.end` an der inneren `Row` mit Key `practice-action`. Die äußere Row richtet nur den festen Slot aus; dessen enge SizedBox-Constraints lassen der inneren Row freie Breite, die sie zuvor rechts neben den Kindern beließ. Die neue Ausrichtung setzt die Kinder an die rechte Slotkante. Keine Koordinaten, künstlichen Spacer oder Größenänderungen in der Implementierung. Der bestehende Helper `right` mit Erwartung 378 ±1 bleibt unverändert. Wort erfahren, Eingeben und Weiter werden dort geprüft; Falsch bei 400ms sowie Weiter mit Erfolgshaken und doppelter Schriftgröße zusätzlich im Bildtest. Während des Schüttelns ist die gewollte Translation davon ausgenommen; danach ist der Offset exakt null.

Erhalten: synchrones 350ms-Schütteln bis 5px, separater 1500ms-Timer mit Generation/Pass-ID, rotes Feld bis tatsächlicher Textrevision, kein Reset durch Cursor/Fokus, erneuter Submit ohne Feedbacksperre. Erfolg, Reveal, Passwechsel, Rückblick und Dispose beenden überholtes Feedback. Reduzierte Bewegung ohne Offset. Keine Haptics/Sounds, separate Falsch-Zeile oder ausblendende alte Beschriftung. wrongForm bleibt fachlicher Fehler mit Formhinweis; almost/alternative bleiben neutral. Tests prüfen einmalige Speicherung und unveränderte Fehlerbewertung.

Nach dem ersten erfolgreichen Einzeltest belegte der gemeinsame Lauf eine weitere veraltete Testannahme: `Reduced motion changes toolbar actions immediately` suchte einen entfernten AnimatedSwitcher (`Bad state: No element`). Er prüft nun nach genau einem `pump` die sofortige sichtbare Aktion und das Fehlen des alten Labels; keine Wartezeit oder Assertion gelockert. Der künstliche Write-Gate-Test gibt sein Gate im Teardown frei und entfernt vor dem Repository-Schließen den Widgetbaum. Ein dadurch unbenutzter Import wurde nach Analysebefund entfernt. Keine weitere Produktionsänderung.

Zusätzliche Dateien gegenüber dem ursprünglichen Plan: `test/practice_ui_test.dart` (sofortiger Aktionswechsel, verlässlicher Teardown), `test/deck_flow_test.dart` (bereits vorher angepasste wrongForm-Farbe). Die vorhandenen Speicher-, Buchstaben- und Ausrichtungsassertions bleiben erhalten. GitNexus-impact für Test-main war UNKNOWN; Textsuche und Quelllektüre bestätigen Flutter-Testeinstiege, keine Aussage „unbenutzt“.

## Aktuelle Prüfnachweise

Befehle ab Repository-Root. Flutter-Befehle identisch unter macOS Terminal und Windows PowerShell. Lokale vollständige Logs und Argumente/Exitcodes unter `build/practice_error_feedback/completion-*.log` bzw. `.command.json`.

| Befehl | Kurzer tatsächlicher Output | Exit / Log |
|---|---|---|
| `flutter test --no-pub test/practice_ui_test.dart --plain-name "One right action, reveal typing, stable solution box and saved-only check"` | `00:01 +1: All tests passed!` | 0 / completion-regression |
| `flutter test --no-pub test/practice_ui_test.dart test/learning_ui_device_fixes_test.dart test/deck_flow_test.dart test/practice_error_feedback_test.dart` | `00:06 +46: All tests passed!` | 0 / completion-four-fixed |
| `flutter test --no-pub` | `00:33 +309: All tests passed!` | 0 / completion-all-final |
| `flutter analyze --no-pub` | `No issues found! (ran in 7.0s)` | 0 / completion-analyze-final |
| `flutter test --no-pub --dart-define=ERROR_SCREENSHOTS=true --dart-define=ERROR_PHASE=final test/practice_error_feedback_test.dart` | `00:04 +7: All tests passed!` | 0 / completion-visual |

Fehlversuche transparent: erster gemeinsamer Lauf 38 bestanden/1 alte Switcher-Annahme, Bereinigung hing, Abbruch Exit 130. Erste Analyse meldete einen nach Teständerung unbenutzten Import (Exit 1), entfernt. Erster Gesamtlauf 308 bestanden/1 fehlende lokale `build/native_assets/macos/libsqlite3.dylib` (Exit 1) bei parallel gestartetem Screenshot-Test; nach dessen Abschluss lag die Bibliothek wieder vor. Ein anschließender alleiniger Gesamtlauf bestand ohne Codeänderung. Ein Konflikt der nativen Buildartefakte ist damit plausibel, nicht als sicher bewiesene Ursache ausgegeben. Frühere fehlgeschlagene/abgebrochene Läufe bleiben in den lokalen Logs; sie zählen nicht als Abschlussnachweis.

## Aktuelle visuelle Belege

Alle sechs `final-*`-Bilder wurden nach der endgültigen Layoutänderung erzeugt und einzeln angesehen:

- [Normalzustand](evidence/practice-error-feedback/final-ready.png): Eingeben an der rechten Kante.
- [100ms](evidence/practice-error-feedback/final-wrong.png): Feld und Falsch-Button gemeinsam verschoben, Satz bleibt stehen.
- [400ms](evidence/practice-error-feedback/final-400ms.png): beide wieder an Ausgangsposition, Button/Feld rot.
- [1500ms](evidence/practice-error-feedback/final-1500ms.png): Eingeben normal, unverändertes Feld weiterhin rot.
- [Erfolg](evidence/practice-error-feedback/final-success.png): Haken links von Weiter, ein gespeicherter Review.
- [Große Schrift und Tastaturinset](evidence/practice-error-feedback/final-large-keyboard.png): Textskalierung 2, rechter Button sichtbar oberhalb des Insets; Inhalt scrollbar.

Widgetsimulation 390×844 logische Pixel, 300px Tastaturinset, PNGs mit Pixelfaktor 2. Keine gezeichnete Tastatur oder Geräteaufnahme. Lokale Arial-/Georgia-Ersatzschriften und echte Iconassets; Google-Fonts-Hinweise auf fehlende Originalfonts sind im Log sichtbar, Runtime-Fetching deaktiviert. Keine Geräte-, Originalfont- oder Screenreader-Praxisabnahme. Ältere `before-*`/`after-*`-Bilder bleiben historische Belege und gelten nicht als Nachweis des Endstands.

## Schutz lokaler Änderungen und Commitblocker

Slot 40, Container-Minimum 30, Padding 16/6 gegen die gesicherte Nutzerfassung geprüft. Ihre Formatierungen bleiben erhalten. SHA-256 von Content-SQLite, Manifest, ReviewPass, Sessioncontroller und fremder `devtools_options.yaml` unverändert gegenüber Beginn der Fortsetzung (`completion/protected.json`). Keine Content-/Pipeline-/SRS-/Persistenzänderung, keine echte Nutzerdatenbank geöffnet, keine Geräteinstallation, Cloud-Aufrufe oder Dependency-Upgrades. Tests verwenden ihre isolierten Fixtures und temporären Datenbanken.

**Kein isolierter konsistenter Commit:** HEAD enthält in `practice_chrome.dart` noch Slot 48 und Container-Minimum 48, die Nutzerarbeitskopie 40/30. `test/learning_ui_device_fixes_test.dart` prüft den autorisierten tatsächlichen 40px-Stand. Ein Commit einschließlich des getesteten Produktionsstands würde die Nutzerhunks mitnehmen; ihr Ausschluss bei mitgenommener Höhenassertion erzeugte einen inkonsistenten Commit. Entsprechend dem Auftrag keine künstliche Trennung, kein Staging, kein Commit/Push. NEXTSTEPS und fremde Dateien bleiben ebenfalls ungestagt. Der gesamte funktional geprüfte Stand bleibt in der Arbeitskopie; die Entscheidung über die gemeinsame Aufnahme der Nutzerhöhe ist offen.

## Graph- und Diffprüfung

Impact vor der Ausrichtungsänderung: PracticeAnswerToolbar LOW, zwei direkte Aufrufer, fünf betroffene Symbole und ein Build-Prozess. Für Testeinstiege UNKNOWN, durch direkte Quellprüfung eingeordnet.

`node .gitnexus/run.cjs analyze --index-only --force` zweimal ausgeführt (completion-index / completion-index-retry), beide formal Exit 0, aber interne `Invalid transaction type to rollback`-, FTS- und Zählfehler; Ausgabe `0 nodes | 0 edges` ist kein gültiger Nachweis eines leeren Graphen. Wiederholung hat die Einschränkung nicht beseitigt. Zusätzlich meldet der Index begrenzte Flow-Erfassung (2213 nicht ausgewählte Einstiegskandidaten, 1040 ausgelassene Callees, drei durch Budget begrenzte Walks) sowie Dart-/Sprachgrenzen. Keine vollständige Graphabdeckung behauptet.

`detect_changes({scope: "all"})` und CLI `node .gitnexus/run.cjs detect-changes --scope all --repo .` liefern 8 geänderte getrackte Dateien, 29 Symbole, 0 Prozesse, Risiko low (CLI Exit 0, completion-graph). MCP meldet keine partial-/truncated-Flags; aufgrund der Indexfehler und fehlender neuer ungetrackter Dateien ist dies dennoch **keine vollständige Entwarnung**. Relevante Produktions-/Testdiffs sowie die neue Testdatei wurden direkt gelesen; vollständige Flutter-Verifikation oben. Graphindex-Reparatur bleibt zusätzlich offen und wird nicht durch Änderungen an Anwendungslogik umgangen.

Diffcheck mit ausschließlich eigenen Pfaden und auf diesen Aufruf beschränkter CRLF-Behandlung: `git -c core.whitespace=blank-at-eol,blank-at-eof,space-before-tab,cr-at-eol diff --check -- lib/screens/decks/deck_practice_screen.dart lib/screens/decks/widgets/practice_chrome.dart lib/screens/decks/widgets/practice_input.dart lib/screens/decks/widgets/practice_sentence.dart test/practice_ui_test.dart test/learning_ui_device_fixes_test.dart test/deck_flow_test.dart test/practice_error_feedback_test.dart docs/practice-error-feedback.md docs/evidence/practice-error-feedback NEXTSTEPS.md`. Kein globales Git-Setting und keine globale Formatierung. Ungetrackte neue Textdateien zusätzlich auf nachlaufende Leerzeichen geprüft.
