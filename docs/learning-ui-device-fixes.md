# Lernablauf: Bedienung, Tagesrest und Storyziele

## Plan vor Implementierung

Ausgangspunkt: d6a672d. Fremdänderungen in NEXTSTEPS.md sowie redaktionelle unversionierte Dateien bleiben erhalten. Keine echten Lerndaten öffnen. Pack und Pipeline bleiben unverändert.

1. Abfragen mit isolierten Fixtures zählen: Provider initial, Session öffnen/verlassen, Stapel aktivieren. Unveränderliche Pack-Metadaten pro Repository-Lebensdauer laden; abgeleitete Nutzerdaten weiterhin ereignisbasiert aktualisieren. Review-Auswertung gebündelt statt pro Karte.
2. Sessionstart einmalig; Tagesrest aus eindeutigen gespeicherten Ziel-IDs im lokalen Tag, ohne Revue. Bestehende Queueprioritäten/Fehlerwiederholungen erhalten. Bei erreichtem Ziel explizites Weiterlernen.
3. Reveal-Button bei leerem/Whitespace-Text wieder aktiv; Erfolg grün, Toolbar kompakt; Tokenblase intrinsisch breit und innerhalb nutzbarer Bildschirmgrenzen.
4. Stapelschalter optimistisch mit geordneter Persistenz und Rollback; bestehende Daten beim Refresh behalten. Story-Speicherbestätigung mit Navigation zur exakten Ziel-ID.
5. Zustands-, Repository-, Widgettests; Screenshots mit Tastaturinset/großer Schrift; vollständige Analyse/Tests und unveränderter 30s-Packtest. Graphänderungsanalyse, eigener Commit ohne Push.

## Geprüfte Dateien und Schnittstellen

- `lib/presentation/practice/deck_session_controller.dart`: Sessionargs, Start/Commit/Next und Tagesrest.
- `lib/presentation/providers/{database,deck,learning,story_learning}_providers.dart`: Repository-Lebensdauer, Änderungen, Zähler und Projektion.
- `lib/data/learning/practice_item_resolver.dart`: Pack-Metadaten und persönliche Lernidentitäten.
- `lib/data/user/drift_user_repository.dart`, `lib/domain/repositories.dart`: gebündelte Review-Lesezugriffe ohne Migration/Zählerspalte.
- `lib/domain/{review_pass,srs_state,preferences}.dart`: bestehende Bewertung, Queue und Einstellungen prüfen; Intervalle nicht verändern.
- `lib/screens/decks/{deck_practice_screen,deck_details_screen}.dart`, `widgets/{practice_chrome,practice_sentence,practice_input}.dart`: Navigation, Laden, Aktionen, Bubble.
- `lib/screens/stories/{story_reader_screen,widgets/word_lookup_sheet}.dart`, `lib/screens/words/word_list_screen.dart`: bestätigte Story-ID zur Wortliste.
- `lib/screens/settings/settings_screen.dart`, `lib/screens/home/widgets/daily_goal_sheet.dart`: vorhandene Zieleinstellungen.
- Tests: `test/{practice_ui,deck_flow,learning_integration,story_learning_flow,form_learning_flow}_test.dart`, `test/data/` und isolierte Fixtures.

## Risiken und Graphabdeckung

GitNexus vor Änderungen vollständig mit `analyze --index-only --pdg --force` erneuert. Klassen: niedrige Risiken für Session, Resolver, Drift und Widgets; mittlere Risiken für UserRepository (25 Betroffene, 6 direkt) und DeckActiveController (12, 6 direkt). Direkte Pfade betreffen Sessionstart, Stapelansicht, Story-Lookup und Wortliste. Provider-Variablen liefern UNKNOWN; deshalb Referenzen zusätzlich direkt geprüft (Riverpod-Laufzeitverkettung nicht vollständig im Graph). Kein UNKNOWN als Entwarnung behandelt.

Hauptrisiken: doppelte Speichervorgänge, verspätete Async-Antworten, Zielwechsel während aktiver Sitzung, lokale Tagesgrenzen, optimistischer Rollback bei schnellen Toggles. Tests müssen diese Übergänge statt bloßer Snapshots prüfen. CRLF bestehender Dateien erhalten.

## Gerätebasis

`xcrun xctrace list devices` erkennt „iPhone von Claus“, iOS 18.7.2. Erkennung allein belegt weder Profile-Zugriff noch Framezeiten. Keine echte user.db für Verifikation verwenden.

## Ursachen und Umsetzung

- `decksProvider` las auf jedes Nutzerereignis alle Stapelmetadaten, jedes Zielset und für jede gesehene Karte die gesamte Reviewhistorie. Der Resolver las zugleich erneut alle Pack-Auswahlmetadaten. `PracticeCatalog` hält nur unveränderliche Pack-Daten innerhalb der Repository-/Provider-Lebensdauer; persönliche Zustände, Storybindungen und Aktivierung bleiben frisch. Ein Repositorywechsel ersetzt auch den Katalog.
- `ReviewActivityRepository` ist eine zusätzliche optionale Leseschnittstelle. Drift liest Tages-/Wochenaktivität in einem begrenzten Zeitraum mit Sprachfilter und letzte Reviewzeitpunkte gruppiert in einer Abfrage. Keine Schemaänderung, Migration oder gespeicherten Zähler. Andere Repositoryimplementierungen behalten einen kompatiblen Fallback.
- Zusätzliche Invalidierungen nach Session-Commit, Deaktivierung, Wortänderung und Story-Add entfernt: `userChangesProvider` liefert bereits das Persistenzereignis. Home, Stapelliste und Details behalten vorhandene Daten beim Refresh. Die Wortliste behält Daten bei nachfolgenden Lesefehlern.
- Der Stapelschalter projiziert den letzten lokalen Wunsch sofort. Eine Future-Kette je Stapel persistiert jede Betätigung in Reihenfolge; Versionsnummern verhindern Rollback einer neueren Absicht durch eine ältere fehlgeschlagene Operation. Der letzte Fehler setzt auf den zuletzt bestätigten Zustand zurück und wird sichtbar.
- Sessionstart ist nach erfolgreicher Initialisierung idempotent; Mount-Prüfungen verhindern Fortsetzung der Anzeige nach Entsorgung. Bestehender Commit-/KeepAlive-/Pass-ID-Vertrag bleibt erhalten. „Übungen werden geladen …“, „Keine passenden Übungen“ und „Tagesziel erreicht“ sind getrennte Zustände; Fehlerwiederholungen sind als solche beschriftet.
- Reguläre UI-Einstiege verwenden jetzt den globalen Tagesrest statt fest 5. Gezählt werden unterschiedliche gespeicherte `card_id` pro lokalem Kalendertag, ohne Revue; Form-IDs bleiben getrennt. Bereits heute erledigte Ziele werden in dieser regulären Auswahl übersprungen. Queueprioritäten, Auswahlvielfalt und nachträgliche Fehlerwiederholungen bleiben erhalten. `size=0` steht intern für Tagesrest, `-1` für die ausdrückliche Aktion „Weiterlernen“; positive explizite Größen bleiben für bestehende begrenzte Aufrufe/Fixtures erhalten. Aktive Sitzungen beobachten das Tagesziel nicht destruktiv.
- Die frühere `revealed ? null : onReveal`-Sperre entfällt. Leerraum gilt für die Hauptaktion als leer. Der unveränderte `ReviewPass` bewahrt Hinweis-/Fehlerhistorie und idempotente Speicherung. Visueller Erfolg nutzt Sage Tint/Quiet Sage, auch im Rückblick; der Haken kommt weiterhin erst nach erfolgreichem Speichern. Standardaktionshöhe ist 48 logische Pixel, mit Wachstum für längere/große Beschriftungen.
- `TranslationBubble` misst den tatsächlich verwendeten Textstil, verwendet Textbreite plus Padding und begrenzt Position/Höhe auf Safe Area und Tastaturgrenze. Scrollgesten auf dem Hintergrund schließen die Auswahl; Fenster-/Tastaturänderungen verwerfen veraltete Anker. Token bleibt hervorgehoben, Außentap wird abgefangen. Deck und Story teilten vorher keinen Bubble-Baustein: Story verwendet weiterhin sein Wörterbuch-Sheet.
- Nach bestätigtem Story-Add erscheint „Zum Lernen hinzugefügt“ und „In Wortliste ansehen“. Die neue Wortlistenroute filtert auf die persistierte ID, nicht auf den Wortlaut. Bereits vorhandene Ziele bleiben als „Bereits hinzugefügt“ gekennzeichnet. Bestehende atomare Add-/Identitätslogik und Fehlermeldungen bleiben erhalten.
- PRODUCT, SRS und DESIGN wurden ausschließlich an die ausdrücklich genehmigte Tagesziel-/Erfolgs-/Bubble-Spezifikation angepasst.

## Vergleich der Abfragearbeit

Identische Sequenz in `test/learning_query_work_test.dart`: synthetisches ContentRepository mit sechs Stapeln, echte Drift-In-Memory-Datenbank mit 18 gespeicherten Lernzielen, abonnierte Stapel-/Vokabel-/Zielansichten; initial laden, Session öffnen, schließen, Stapel deaktivieren. Ausgangscode aus `git archive d6a672d` in separatem temporären Verzeichnis, unveränderte Messdatei mit `--dart-define=BASELINE=true`. Keine echten Lerndaten.

Kumulative Zahlen, jeweils **vorher → nachher**:

| Phase | Stapelmetadaten | Auswahlmetadaten | Stapelziel-Abfragen | Einzelhistorien `reviewsFor` |
|---|---:|---:|---:|---:|
| Initial | 6 → 2 | 2 → 1 | 24 → 6 | 72 → 0 |
| Öffnen | 9 → 2 | 3 → 1 | 37 → 6 | 108 → 0 |
| Zurück | 9 → 2 | 3 → 1 | 37 → 6 | 108 → 0 |
| Schalter | 12 → 2 | 4 → 1 | 48 → 6 | 144 → 0 |

Die drei beobachteten Ansichten veröffentlichen nach beiden Varianten je einmal initial, einmal beim Öffnen (Erstkontakt) und einmal beim Schalter; Zurück allein erzeugt keine neue Veröffentlichung. Der Fix reduziert Arbeit pro Aktualisierung und vermeidet wiederholte Pack-Projektion. Die zwei initialen `decks()`-Aufrufe stammen aus Katalogladen und der expliziten Fixture-Implementierung von `allCardIds()`. Gebündelte Review-Abfragen ersetzen die Einzelhistorien; „0“ bedeutet nicht keine Datenbankarbeit. Das sind Aufrufzahlen, **keine Geräte-Framezeiten**.

## Verifikation und Grenzen

Neue Tests: `test/learning_ui_device_fixes_test.dart`, `test/learning_query_work_test.dart`, `test/story_target_navigation_test.dart`. Angepasste bestehende Erwartungen: `test/practice_ui_test.dart` (genehmigter grüner Fill), `test/story_learning_flow_test.dart` (neue bestätigte Add-Beschriftung).

Geprüft: 20−12=8; knappes Angebot=3; Dateineustart; Revue-Ausschluss; doppelte Pass-ID und wiederholte Ziel-ID; lokale Tagesgrenzen rund um Zeitumstellungstermine; Zielverkleinerung/Rest 0; unveränderter aktiver Pass nach Ziel- und Tageswechsel; mehrfach Reveal→Tippen→Leeren/Whitespace→Reveal mit genau einem unterstützten Review; geordnete schnelle Toggles und Rollback; grünes Feld/Haken erst gespeichert; 48px-Aktion; Bubblegrenzen bei 200% Schrift und 300px Tastaturinset; bestehende/lokale Storyziele in isolierter Datei nach Neustart, exakte Wortlisten-ID, Deaktivierung/Reaktivierung und passende Gemischt-Auswahl. Gleichartige neue Wörter werden weiterhin nicht künstlich gemeinsam in eine Queue gezwungen.

Frühe Prüfläufe fanden alte Blau-/„Bereits hinzugefügt“-Erwartungen sowie unpassende Testdaten (wiederholte Wortformen trotz erwarteter acht neuer Ziele). Der fehlgeschlagene Farbtest ließ seinen künstlichen Write-Gate offen; der Lauf wurde nach 4:36 abgebrochen und nicht als PASS gewertet, obwohl der abgebrochene Flutter-Prozess Exit 0 lieferte. Korrigiert wurden die genehmigten UI-Erwartungen und die Testdaten, nicht die fachliche Dublettenregel. Ein erster Screenshotlauf wartete im Fake-Async-Kontext; Rasterisierung erfolgt nun in `runAsync`. Visuelle Kontrolle entdeckte zusätzlich Textmessungsabweichung der Bubble und alte Feldbreite nach Textskalierung; beide korrigiert.

### Sichtbare Belege

Widget-Renderings mit lokalen Ersatzschriften Arial/Georgia und Original-Iconfont, keine exakte Typografie- oder iPhone-Abnahme. „Keyboard“ bezeichnet hier einen **300px simulierten Tastaturinset**, keine gerenderte iOS-Systemtastatur. Die großen Varianten verwenden 200% Textskalierung. Alle vier Bilder visuell geprüft.

- [Grüner Erfolg, kompakte Aktion](evidence/learning-ui-device-fixes/success-compact.png)
- [Erfolg bei großer Schrift und Tastaturinset](evidence/learning-ui-device-fixes/success-large-keyboard.png)
- [Kurze textbreite Blase](evidence/learning-ui-device-fixes/bubble-short.png)
- [Lange Blase bei großer Schrift und Tastaturinset](evidence/learning-ui-device-fixes/bubble-large-keyboard.png)

Reproduzierbar auf macOS mit lokal vorhandenen Ersatzschriften: `flutter test --no-pub --dart-define=UI_SCREENSHOTS=true test/learning_ui_device_fixes_test.dart test/story_target_navigation_test.dart`. Normale Tests benötigen diese Fonts und Option nicht; Flutter-/Dart-Prüfbefehle sind unter PowerShell und macOS identisch.

### Physisches Gerät: externer Freigabeblocker

`xcrun devicectl list devices --timeout 20` und `device info details` bestätigten ein verbundenes physisches iPhone 14 Plus („iPhone von Claus“), iOS 18.7.2, Developer Mode aktiviert. Ein erster sandboxbeschränkter Aufruf scheiterte am CoreDeviceService; der erlaubte lesende Aufruf funktionierte.

Separate Mess-App unter `/private/tmp/learning_ui_profile_probe`, eigene Bundle-ID `de.sprachapp.learningProbe`, Produktionspack nur lesend, synthetische Nutzerreviews ausschließlich in `NativeDatabase.memory()`. Lokaler Build: `flutter build ios --profile --no-codesign --no-pub --target lib/profile_probe.dart` → erfolgreich, 55,8 MB, Xcode 54,1s. Diese Buildzeit ist kein Performancebefund.

Die automatische Freigabeprüfung **lehnte Installation und Start** auf dem physischen Gerät ab: möglicherweise fremdes iPhone; Zielgerät und Übertragung interner App-Inhalte seien nicht eindeutig autorisiert. Kein Umgehungsversuch, keine Installation/Deinstallation, kein Zugriff auf die echte App oder deren user.db. **Keine Vorher-/Nachher-Framezeiten und kein iPhone-Performance-PASS.** Fortsetzung benötigt ausdrückliche Erlaubnis für dieses Gerät und diese separate App. Der vorbereitete Probe misst drei Durchläufe Öffnen/Zurück/Schalter mit Flutter FrameTiming; nach Erlaubnis identisch mit Ausgangs- und Endcode ausführen, Build-/Raster-p50/p95/max und Frames über 16,67ms vergleichen. Auch das bleibt eine isolierte synthetische Last, keine Messung eines realen Nutzerprofils.

## Manuelle Abnahme

1. Separates Testprofil: Ziel 20, zwölf unterschiedliche gespeicherte heutige Abschlüsse. Stapel/Gemischt starten: maximal acht zusätzliche Ziele; bei drei geeigneten Zielen drei. Revue und erneute Speicherung desselben Ziels erhöhen den regulären Tageszähler nicht.
2. Während einer Antwort Ziel ändern und lokalen Tageswechsel abwarten: Eingabe/Pass bleiben erhalten. Nächsten Start prüfen; bei Rest 0 „Tagesziel erreicht“, explizites Weiterlernen und Revue verfügbar.
3. Leer → Reveal → tippen → löschen/Leerraum → Reveal mehrfach. Korrekt abschließen, speichern, Rückblick öffnen: grün und unveränderlich; kein zusätzlicher Review durch Reveal/Rückblick.
4. Details scrollen, Schalter schnell aus/an/aus, Home und zurück. Inhalt und Scrollposition erhalten; bei provoziertem Schreibfehler Rollback/Fehlermeldung, bei Laden kein falscher Abschluss.
5. Kurze/lange Tokenübersetzung an allen Bildschirmrändern mit echter Tastatur, großer Schrift, Rotation und Scrollen prüfen. Erster Außentap schließt ausschließlich die Blase.
6. Storyziel hinzufügen, exakte Wortliste öffnen, App neu starten, deaktivieren/reaktivieren und Gemischt prüfen. Keine Zusage „sofort als Nächstes“; fällige Ziele, Vielfalt und Tagesrest gelten weiter.

## Abschließende Befehle und Output

Alle Befehle ab Repository-Root; Flutter-/Dart-Befehle identisch unter Windows (PowerShell) und macOS (Terminal). Vollständige Logs/Exitcodes/Laufzeiten liegen lokal unter `build/learning_ui_device_fixes/`.

| Befehl | gekürzter tatsächlicher Output | Exit / Prozesszeit |
|---|---|---|
| `flutter analyze --no-pub` | `No issues found! (ran in 3.3s)` | 0 |
| `flutter test --no-pub` | `00:22 +291: All tests passed!` | 0 / 30,05s |
| `flutter test --no-pub test/data/real_pack_test.dart` | `00:08 +1: All tests passed!` | 0 / 11,32s |
| `dart run tool/stage_content_pack.dart --verify` | `verified ... content.sqlite`; `22 table counts match` | 0 |
| `flutter test --no-pub --dart-define=UI_SCREENSHOTS=true test/learning_ui_device_fixes_test.dart test/story_target_navigation_test.dart` | `00:02 +8: All tests passed!` | 0 |
| `flutter test --no-pub test/learning_query_work_test.dart` | `00:01 +1: All tests passed!` und Abfragezahlen oben | 0 |
| `git diff --check -- <eigene Dateiliste>` | CRLF-Zeilen als `trailing whitespace` gemeldet | 2 |
| `git -c core.whitespace=cr-at-eol diff --check -- <eigene Dateiliste>` | kein Output | 0 |

Die genaue eigene Dateiliste ist lokal in `build/learning_ui_device_fixes/own-files.json` gespeichert und wird durch den isolierten Commit ausgewiesen. Rohes diff-check hatte 462 Ausgabezeilen zu CR-Endzeichen. Separater Bytevergleich bestätigt: alle geänderten bestehenden Dateien behielten CRLF ohne neu eingeführte nackte LF; keine globale Normalisierung. Neue Dart-Dateien separat formatiert. Asset-SHA bleibt `4861110b1e0ab90b2487db79e47afbe9581f54b6cab3987c1a6d9e9fdd7e64b6`; unveränderter Packtest-SHA `1e26c91844fcc7692f08c279b085dc4a66aeb11b4014ce841377ea2ce1358551`.

## Graphprüfung und Commitgrenzen

Zusätzliche Einzelmethoden-Prüfung meldete `StoryLearningService.add` **CRITICAL**, 33 betroffene Symbole/10 direkte. Warnung berücksichtigt und direkte Aufrufer gelesen: Story-Reader-Callback → Service → atomarer Repository-Add, plus Reaktivierung. Der Graph verbindet außerdem gleichnamige Collection-`add`-Aufrufe; solche Kanten sind keine belastbare exakte Aufrufkette. UNKNOWN bei Widget-build/Provider-/Callback-Aufrufen wurde mit direkten Referenzen und betroffenen Widget-/Integrationstests ergänzt. Keine Änderung der atomaren Story-Persistenz.

NEXTSTEPS wurde auf 25 Faktenzeilen aktualisiert, bleibt wegen bereits vorbestehender, überlappender Änderungen vollständig ungestaged. Redaktionelle unversionierte Verzeichnisse bleiben unberührt und außerhalb des Commits. Keine Pipeline-/Pack-/Manifest-/ID-Änderung, keine realen user.db-Zugriffe und kein Push.

Finale Graphprüfung nach vollständigem Reindex: `detect_changes(scope: all)` meldet **125 Symbole / 30 Dateien / Risiko medium**, vollständige Liste mit 125 Einträgen, weder `partial` noch `truncated` gesetzt. Ein gemeldeter Prozess: `DisableCurrent → DeckSessionState`; dessen Flags-/Queue-/Anzeigepfad wurde direkt gelesen und durch die bestehenden Deck-/Integrationsprüfungen ausgeführt. Die 30 Dateien enthalten NEXTSTEPS; der Commit enthält nur die 29 eigenen Dateien. Der Index selbst warnt über begrenzte globale Prozess-Erkundung (2208 nicht aufgenommene Einstiegskandidaten, 1029 übersprungene Callees): die eine gemeldete Prozesskette ist daher keine Behauptung, dass andere UI-Pfade unbetroffen seien. Diese wurden direkt und durch die vollständigen Tests geprüft. Letzte Analyse nach Formatierung: `No issues found! (ran in 3.4s)`, Exit 0; vorgemerkter CRLF-bewusster Diffcheck ebenfalls ohne Output, Exit 0.
