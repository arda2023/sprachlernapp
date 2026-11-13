# Teil 5: Barrierefreiheit

Stand: 13.11.2026, integriert auf `12d1f1b`. Die sechs geforderten Screens bestehen die neuen Accessibility-Tests in Hell/Dunkel bei TextScaler 1.0 und 2.0. Geändert wurden gezielt Touchflächen, Kontrast, dekorative Semantik und reduzierte Bewegung. Das iPad wurde nicht angepasst. Live-VoiceOver und die größte iPhone-Schriftstufe bleiben Handtests.

## Audit vor der Umsetzung und Ergebnis

Das [ursprüngliche Audit](store-readiness/accessibility/audit-before.md) entstand vor den UI-Änderungen. Der erste bereinigte Diagnoselauf prüfte 24 Screenvarianten mit echten App-Schriften, darunter Home zusätzlich nach Scrollen: kein Overflow, vier Fehler in 84 Guideline-Auswertungen (Übung: Tapflächen bei 1× in beiden Motiven; Wortliste: Kontrast im hellen Motiv bei 1×/2×). Der diagnostische Runner sammelte Ergebnisse mit `.evaluate`; seine grüne Test-Schlusszeile war ausdrücklich kein bestandenes Accessibility-Audit. Die finalen Tests verwenden dagegen unverändert strenge `expectLater(meetsGuideline(...))`-Assertions.

| Bildschirm | Problem vor dem Fix | Fix und Nachweis |
|---|---|---|
| P1 · Übung | Wortbuttons und Editor nur 36 pt hoch. „Mia“ maß mit echter Schrift 43,3 × 36 pt, Antwortfeld 64 × 36 pt. | `practice_sentence.dart`: mindestens 44 × 44 pt für Wortaktionen, echte transparente Hitfläche und vertikale Editorpolsterung. Glyphen/Bubble-Anker bleiben unverändert. Guideline in beiden Motiven grün; Tap außerhalb eines kurzen Wortes löst dieselbe Wortaktion aus. |
| P1 · Wortliste, hell | Übersetzung in #F77F00 auf Weiß: 2,63:1 bei 15 pt. | `AppPalette.accentText` = #A94E00 im hellen Motiv (5,56:1 auf Weiß; 5,10:1 auf der Seitenfläche). Wortlisten-Übersetzung verwendet diesen Token; dunkler Textakzent bleibt unverändert. Screen- und Token-Kontrasttests grün. |
| P1 · Gemeinsame orange Flächen | Weiß auf altem Popover-Orange #E26C00: 3,29:1, zu wenig für kleine Labels, Filterzähler und Aktionsknöpfe. Teilweise kam 0,8-Alpha auf weißem Text hinzu. | `AppPalette.popover` = #BC5800: Weiß erreicht 4,63:1. Filterzähler und selektierte Streak-Texte deckend weiß; kleine Paywall-Tarifbadge ebenfalls auf diesem Füllton. `DESIGN.md` und aktuelle Designsystem-Tabelle aktualisiert. Token-, tatsächliche RichText- und Button-/Popover-Tests ergänzen den Screen-Matcher. |
| P2 · Home, hell | Hervorgehobene Streak-Motivation mit altem hellem Orange nur 2,63:1. | `streak_strip.dart` nutzt für den Text `accentText`. Fortschrittsflächen und Flammen behalten ihre Farbrolle. Vorher/Nachher zeigt nur den Textteil „Tag 4“. Große Fortschrittszahlen waren bereits `textPrimary` und wurden nicht verändert. |
| P2 · Übung, offenes Wort-Popover | Andere noch bedienbare Wörter wurden auf 0,5 Alpha gedimmt: etwa 2,09:1 hell bzw. 2,94:1 dunkel. Antwort-Hinweise verwendeten ebenfalls halbtransparentes Blau. | Fokusdimmung 0,8, Antwort-/Ghost-Hinweise in `textMuted`. Das verbleibende 24-pt-Wort und der Ghost-Hinweis erreichen mindestens 3:1. Caret und Ghost bleiben bei 1×/2× ausgerichtet. |
| P2 · Paywall | Aktionsleiste „Wiederherstellen“/„Zugang prüfen“/„Anmelden“ auf maximal 1,3× begrenzt. | Clamp entfernt; Flexible und Umbruch bleiben. Regression misst tatsächlich 2× für „Wiederherstellen“. Kaufbare Trial- und Nicht-Trial-Varianten bestehen die Guidelines auch bei 2×. Benachrichtigungs- und Kaufregeln aus Teil 3 bleiben erhalten. |
| P2 · Paywall / Onboarding | Paywall-Route blendete/schob trotz Reduced Motion. `Pressable` skalierte auf 0,97; `GlowButton` hatte feste Übergangszeiten. | Bei `disableAnimations` Route direkt zeigen, Pressable-Skala 1, eigene Übergangszeiten null. Tests prüfen gehaltenen Pointer mit und ohne Reduced Motion sowie Paywall ohne SlideTransition. |
| P2 · Reader | Übersetzungsmodus-Hinweis animierte seine Höhe trotz Reduced Motion. | `_translationModeHint` zeigt bei Reduced Motion den fertigen Inhalt direkt; kein `AnimatedSize(Duration.zero)`, das erneut Layout anstoßen kann. Regression prüft sofortige, danach unveränderte Höhe und Header-Semantik. Eigene Toolbar-Übergänge ebenfalls ohne Animation. |
| P2 · Einstellungen / Wortliste / Home | Kleine feste Opacity-/Container-/Switcher-Zeiten ignorierten Reduced Motion. | Einstellungen-Titel, Wertpille und Motivvorschau; Wortlistenfilter und Mehr-Menü; Streak-Fläche respektieren `disableAnimations`. Bestehende `PressScale`-/Feier-/Reveal-Logik bleibt bestehen. |
| P2 · StoryListShelf | Feste 84-pt-Zeile kann zwei 2×-Titelzeilen plus Lesefortschritt nicht aufnehmen. Die Basisscreen-Matrix erreicht diese Variante nicht. | Zeilen-/Shelf-Höhe wächst mit der Schrift; Text-Höhe wird vor dem Fortschrittsabstand auf volle Punkte aufgerundet. Der gezielte Zweizeiler-Test reproduzierte noch 0,4 pt Rundungsüberlauf; mit 94 pt bei 2× passt die Variante ohne Überlappung. |
| P3 · Story-Cover | `TypeCover` verwendete `noScaling` für eine dekorative Textur, schloss Semantik aber nur über übliche Aufrufer aus. | Eigenständiges `ExcludeSemantics`. Lesbarer Storytitel skaliert weiter vollständig. Regression misst 34 pt statt 17 pt bei 2×; feste Buchstabenabstände und gerundete Zeilenhöhe werden bei den Pixelmaßen berücksichtigt. |
| P3 · LaunchSplash | Wortmarke konnte neben „Linglossa wird gestartet“ noch einmal vorgelesen werden. Caption-Fade hatte feste 300 ms. | Nur Wortmarke aus Semantik ausgeschlossen; Status-Caption bleibt hörbar und skalierend. Reduced Motion unterbindet den Fade. Test zählt Markennennung einmal und prüft Caption sowie fehlende laufende Animationen. |
| OK · Onboarding / WordRain | 1,3×-Clamps betreffen nur Logozeilen. WordCycle ist dekorativ; WordWall fasst Dekoration in ein Statuslabel zusammen. | Logo-Clamps bleiben, echte Titel skalieren. WordRain bleibt unverändert: dekorative Wörter fehlen in der Semantik, Status bleibt erhalten; reduzierte Bewegung wird bereits unterstützt und ist nun regressionsgeprüft. |
| P2 · Übung, ergänzender Interaktionsbefund | Geöffnetes Wort-Popover erzeugte über einen bildschirmgroßen GestureDetector einen unbeschrifteten Tap-/Scroll-Knoten. Im ursprünglichen Initialzustands-Audit war dieses Overlay nicht geöffnet. | `deck_practice_screen.dart`: explizite Button-Semantik „Übersetzung schließen“ mit Aktion; der rohe GestureDetector erzeugt keine eigene Semantik. Der geöffnete Zustand besteht jetzt alle drei Guidelines bei beiden Motiven und Schriftgrößen. |

Die benannten Header und Icon-Labels waren im Bestand überwiegend korrekt. Es wurden keine globalen SortKeys oder pauschalen Designänderungen eingeführt.

## Warum `noScaling` an zwei Stellen bestehen bleibt

`PracticeSentence` skaliert seine äußere TextSpan-Schrift bereits explizit. Die eingebetteten Text- und TextField-Widgets übernehmen den MediaQuery-Scaler. Das äußere `Text.rich(textScaler: TextScaler.noScaling)` verhindert eine zweite Multiplikation; sein bloßes Entfernen wäre eine Regression. Die echten Glyphen messen vor und nach der Änderung für „Mia“ 43,3 × 36 pt bei 1× und 86,6 × 72 pt bei 2×. Neu ist die umgebende mindestens 44-pt-Hitfläche. Der normale Satzblock wächst dadurch von 36 auf 44 pt; die 2×-Variante bricht passend um. Separate Tests prüfen tatsächliche RenderParagraph-/EditableText-Metriken, Ghost-Caret und ein langes untrennbares Wort bei 320 pt Breite.

Im Carousel betrifft `noScaling` nur die blasse dekorative TypeCover-Textur. Der lesbare Titel skaliert regulär; die Textur ist nun eigenständig aus Semantik ausgeschlossen. Logozeilen in Onboarding und LaunchSplash bleiben bewusst auf 1,3× begrenzt, Aktions- und Inhaltstexte nicht.

## Vorher/Nachher

Die Bilder verwenden Figtree/Source Serif 4 und echte Iconfonts, ausschließlich synthetische Testdaten, 390 × 844 logische Punkte und PNGs mit 780 × 1688 Pixeln. Vorher: `c97a1f3`; Nachher: Teil-5-Arbeitsstand auf `12d1f1b`. [Manifest mit SHA-256](store-readiness/accessibility/manifest.json).

| Ansicht | Vorher | Nachher |
|---|---|---|
| Home hell | [Bild](store-readiness/accessibility/before/home_light.png) | [Bild](store-readiness/accessibility/after/home_light.png) |
| Home dunkel | [Bild](store-readiness/accessibility/before/home_dark.png) | [Bild](store-readiness/accessibility/after/home_dark.png) |
| Home-Popover hell | [Bild](store-readiness/accessibility/before/home_light_popover.png) | [Bild](store-readiness/accessibility/after/home_light_popover.png) |
| Home-Popover dunkel | [Bild](store-readiness/accessibility/before/home_dark_popover.png) | [Bild](store-readiness/accessibility/after/home_dark_popover.png) |
| Übung hell | [Bild](store-readiness/accessibility/before/practice_light.png) | [Bild](store-readiness/accessibility/after/practice_light.png) |
| Übung dunkel | [Bild](store-readiness/accessibility/before/practice_dark.png) | [Bild](store-readiness/accessibility/after/practice_dark.png) |
| Wort-Popover hell | [Bild](store-readiness/accessibility/before/practice_light_popover.png) | [Bild](store-readiness/accessibility/after/practice_light_popover.png) |
| Wort-Popover dunkel | [Bild](store-readiness/accessibility/before/practice_dark_popover.png) | [Bild](store-readiness/accessibility/after/practice_dark_popover.png) |
| Wortliste hell | [Bild](store-readiness/accessibility/before/word_list_light.png) | [Bild](store-readiness/accessibility/after/word_list_light.png) |
| Wortliste dunkel | [Bild](store-readiness/accessibility/before/word_list_dark.png) | [Bild](store-readiness/accessibility/after/word_list_dark.png) |

Home dunkel ist im Initialzustand pixelgleich. Beide echten Übungsbilder haben im unteren Bereich y=1400…1688 identische Pixel; die größere Satzzeile verschiebt nur ihren oberen Inhaltsbereich. Fehlende Länderflaggen-Glyphen im Home-Testbild sind eine Desktop-Fixture-Grenze.

## Neue Tests und Fonts

- `test/accessibility/core_screens_accessibility_test.dart`: 26 Fälle. Sechs echte Screens × zwei Motive × TextScaler 1/2; zusätzlich Paywall ohne Trial bei 2× in beiden Motiven. Jeder Fall prüft alle drei Guidelines, weitere vertikale Ansichten bis zum Listenende und keinen Overflow. Home-Popover, Übungswort-Popover/aktivierte Eingabe und Wortlisten-Menü werden in bestehenden Fällen geöffnet.
- `text_scaling_regressions_test.dart`: sieben gezielte Fälle für tatsächliche Skalierung, echte Hitflächen, lange Wörter, Ghost/Caret und StoryShelf.
- `contrast_regressions_test.dart`: sechs Fälle für reale Tokenpaare, aktivierte Buttons/Popover und den tatsächlichen RichText-Filterzähler.
- `semantics_motion_regressions_test.dart`: sechs Fälle für Pressable, dekorative Texte, Launch-Status, Paywall-Route/-Schrift und Reader-Hinweis/-Header.
- `accessibility_test_app.dart`: Theme, deutsche Lokalisierung, Viewport und MediaQuery; synthetische Kauf-/Benachrichtigungszustände ohne SDK-/Netzzugriff. Keine neue Runtime-Abhängigkeit.
- `test/fixtures/accessibility_fonts.dart` und `test/fixtures/fonts/`: acht lokal vorliegende OFL-Fonts mit URLs, SHA-256, Bytezahlen und Original-Lizenztexten. Bytes entsprechen den Deskriptoren von google_fonts 9.0.0. Die Lizenztexte enthalten lediglich normalisierte Zeilenend-Leerzeichen. Loading ist auf diese Test-Isolate beschränkt; kein globales Pubspec-Fontbundling, keine Systemfont-/Netz-/`/tmp`-Abhängigkeit der finalen Tests.

Der Kontrast-Matcher ordnet Semantiklabels sichtbaren Textwidgets zu. Zusammengefasste Labels oder mehrfarbiger RichText können dabei übersprungen werden. Deshalb ergänzen die konkreten Farb- und Filterspan-Assertions die Screen-Guidelines. Die bisherige Golden-Suite behält ihre Ahem-Ersatzschrift und wird nicht unbemerkt auf die neuen Testfonts umgestellt.

## Bestehende Tests und Goldens

Zwei bestehende Testdateien wurden angepasst:

- `test/goldens/core_screens_golden_test.dart` entfernt den gemounteten Widgetbaum, bevor `TestUser.close()` den Stream schließt. Ohne diesen Cleanup hing der Fehlerpfad nach einer fehlgeschlagenen Golden-Assertion. Renderingumgebung, Screen-Fixtures und Assertions bleiben unverändert.
- `test/deck_flow_test.dart`: Der anschließende Gesamtlauf fand die alte Erwartung für den aufgedeckten Antwort-Hinweis. Genau diese visuelle Assertion erwartet nun `AppColors.textMuted` statt halbtransparentem Blau. Der gezielte Nachlauf bestand mit `00:02 +20: All tests passed!`; Lern-, Wiederholungs- und Speicherassertions bleiben erhalten. Weitere Diffzeilen sind ausschließlich Formatierung.

Keine bestehende fachliche Assertion wurde abgeschwächt oder entfernt.

Nur diese fünf Golden-Dateien wurden nach visueller Prüfung aktualisiert; [Originale](store-readiness/accessibility/goldens-before/) und [aktualisierte Bilder](store-readiness/accessibility/goldens-after/) sind gesichert:

| Golden | Beabsichtigte Änderung |
|---|---|
| `home_light.png` | Lesbarer dunklerer Streak-Textakzent. |
| `practice_dark.png`, `practice_light.png` | 44-pt-Wort-/Editorfläche statt 36 pt; folgende Karte rückt um 8 pt nach unten. |
| `word_list_dark.png` | Dunklerer selektierter Filter und deckend weißer Zähler. |
| `word_list_light.png` | Filter wie dunkel; zusätzlich kontrastreicher Übersetzungstext. |

`home_dark.png`, `story_reader_dark.png` und `story_reader_light.png` bleiben bytegleich.

Besonderheit der Ahem-Practice-Goldens: Der alte Master zeigte den gesamten unteren Sitzungs-/Toolbarbereich nicht, obwohl er schon im echten Vorherbild vorhanden war. Mit dem neuen Inline-Layout wird er auch im Ahem-Golden sichtbar. Ein isolierter Lauf mit nur `PracticeSentence` auf Originalstand reproduzierte beide alten Goldens; ein zusätzlicher Frame oder erzwungenes Root-Repaint änderte das nicht. Der integrierte Stand wurde danach bytegleich wiederhergestellt. Echte Font-Bilder belegen den unveränderten unteren Bereich. Deshalb wurde keine Produktlogik am Footer geändert und keine wirkungslose Capture-Umgehung eingebaut. Diese Ersatzschrift-Bildwirkung ist ausdrücklich von der beabsichtigten Touchhöhenänderung zu unterscheiden.

## Verifikation

Die folgenden Flutter-Befehle gelten identisch in macOS Terminal und Windows PowerShell; die bestehende Golden-Suite überspringt Windows wegen plattformspezifischer Rasterung.

```text
flutter test --no-pub test/accessibility/ --reporter expanded
00:03 +45: All tests passed!
```

Die 14 ausgewählten Bestandsdateien (`practice_ui`, `practice_focus_alignment`, `practice_word_bubble`, `practice_error_feedback`, `practice_polish`, `practice_fixes_04_11`, `deck_practice_shortcuts`, `reader_lookup_characterization`, `bundled_story_reader`, `onboarding`, `notification_ui`, `home_streak`, `launch_curtain`, `learning_ui_device_fixes`) bestanden unverändert ihre fachlichen Assertions:

```text
00:10 +102: All tests passed!
```

Der abschließende Vergleich prüfte alle acht Goldens, nicht nur die aktualisierten fünf:

```text
flutter test --no-pub test/goldens/core_screens_golden_test.dart --reporter expanded
00:01 +8: All tests passed!

dart format [13 geänderte UI-Dateien, 6 neue Test-/Helperdateien, 1 Golden-Testdatei]
Formatted 20 files (0 changed) in 0.14 seconds.
```

Generierte Golden-Fehlerbilder wurden nach dem Vergleich aus dem Repository in das temporäre Arbeitsarchiv verschoben, nicht gelöscht. Vorhandene CRLF-Zeilenenden sind erhalten; `git -c core.whitespace=cr-at-eol diff --check` war ohne Ausgabe erfolgreich. Fontdateien wurden erneut gegen alle acht Manifest-Hashes geprüft.

Der externe Nachher-Capture bestand sechs Diagnosefälle; er ersetzt keine der 45 strengen Regressionen. Für Analyzer, volle Suite, abschließende Formatierung und den Teil-5-Commit gilt der übergeordnete [Store-Readiness-Bericht](store-readiness.md). Die vollständigen Protokolle der isolierten Läufe und der Golden-Nachlauf liegen unter [logs](store-readiness/accessibility/logs/); nur Zeilenend-Leerzeichen der Konsolenausgabe sind normalisiert.

## Grenzen und iPhone-Handtest

Keine WCAG-Zertifizierung und kein Beleg für getestetes Live-VoiceOver: automatische Widgettests bewerten konkrete synthetische Zustände und Telefonviewports. Nicht jede mögliche Inhaltslänge und nicht jede Systemeinstellung wurde durchlaufen. Reader-Inline-Links sind vom Flutter-44-pt-Matcher ausgenommen; die Übungsbuttons ausdrücklich nicht. Alte Golden-/Bestandstests protokollieren weiterhin die bekannten fehlenden Google-Fonts bei deaktiviertem Runtime-Fetching; die neuen Accessibility-Tests laden echte lokale Fonts.

Auf dem iPhone prüfen: VoiceOver-Fokusfolge und Überschriften auf Home, Übung und Reader; Wortübersetzung öffnen und mit „Übersetzung schließen“ verlassen; größte Textgröße einschließlich Paywall-Wiederherstellen und langer Storytitel; reduzierte Bewegung bei gehaltenem Onboarding-Knopf, Paywall-Wechsel und Reader-Übersetzungsmodus; lesbare helle Übersetzungstexte und kleine weiße Popoverlabels. Die tatsächliche Bedienbarkeit dieser Gerätefälle wird hier nicht als erledigt behauptet.
