# Stories, Inhalte und Premium · 01.11.2026

## Ergebnis

- Wirtschaft und Alltag verwenden große Story-Cover. 14 zusätzliche, einzeln erzeugte Motive ergänzen die bisherigen 44 Bilder. Die feste ID-Zuordnung deckt alle 286 sichtbaren Story-Varianten in fünf Sprachen ab, einschließlich der englischen Packstory „The Open Pocket“.
- Texte unter Inhalte verwenden kompakte, farbige Dreier-Spalten ohne Hintergrundbilder. Kleine Hörkarten haben ein tatsächlich 17 × 17 pt großes Lautsprechersymbol; ihre Antippfläche bleibt erhalten.
- Allgemeine Sprache, Nachrichten und Grammatikregeln bleiben kostenlos. Andere Stapel, Stories, importierte Texte, Text-/Hör-/Grammatikübungen und private Themenvokabeln benötigen Premium. Lesbare Vorschauen mit Schlössern führen zur schließbaren bestehenden Paywall.
- Themenstapel zeigen passende Symbole. Übersichtszähler unter „Stapel“ und an den beiden Abschnittstiteln sind entfernt. Ein gesperrter Stapel zeigt ein Upgrade-Panel statt Aktivierung, Lernen oder Revue.
- Wortdetails enthalten Wort, Aussprache, Übersetzung, Forminformationen und Lernstatistik. Der doppelte Beispielsatz, seine Übersetzung, sein Audioknopf und die Notiz-Eingabe sind entfernt. Vorhandene Notizen werden nicht gelöscht.
- Der Sprachwechsel zeigt vier Wörter in Figtree 400: schneller Eintritt, anschließend langsame kontinuierliche Bewegung. Reduzierte Bewegung bleibt statisch.

## Zugriff und gespeicherte Daten

`premiumContentAccessProvider` übernimmt die bestehende verifizierte Zugangsentscheidung; unbekannter Status schaltet nichts frei. Die fünf kanonischen Allgemeine-Sprache-IDs bilden die kostenlose Ausnahme, nicht frei manipulierbare Anzeigenamen.

Aktivierung und direkte Lernstarts prüfen Premium zusätzlich zur Oberfläche. Gemischte und globale vorgezogene Sitzungen filtern ohne Premium sowohl neue Quellen als auch Wiederholungen auf die kostenlosen Übungsziele. Ein beantwortetes Ziel darf bei zwischenzeitlichem Ablauf noch sicher gespeichert werden; nachfolgende bezahlte Ziele werden entfernt. Karten, Historie, Fälligkeiten und Notizen bleiben gespeichert, SRS-Algorithmen und abgeleitete Zähler bleiben unverändert.

Die Generierung prüft den Zugang im Client vor Anfrage und Speicherung sowie serverseitig vor Reservierung oder Rückgabe eines gespeicherten Ergebnisses. Migration `20261101000003_generated_vocabulary_premium.sql` und ausschließlich die Edge Function `generate-vocabulary` wurden auf dem bereits verbundenen Projekt veröffentlicht. Function-Version 7 ist ACTIVE. Remote-Katalogprüfungen bestätigen Premiumprüfung sowie gesperrte RPC-Aufrufe für anon/authenticated und zugelassenen service_role. Keine Schlüssel wurden in App oder Repository eingebettet.

Die mitgelieferten Offline-Inhalte erhalten eine App-Zugriffssperre, keine neue Verschlüsselung oder DRM-Schicht. Die serverseitige Generierungssperre ist davon unabhängig.

## Design und Bilder

Referenzen wurden nach UI-Mustern gesucht, zuletzt ausdrücklich branchenübergreifend nach „Library with locked premium content“. Übernommen wurde die klare Trennung von lesbarer Vorschau, Schloss und Freischaltaktion, nicht fremdes Branding. Beispiele: [Suno](https://mobbin.com/screens/5cfc045d-92c3-4438-b7f4-cc491d091cc8), [Babbel](https://mobbin.com/screens/b2611ef0-5af7-43af-8d84-635a1bab17f6). Eigene Farben, Figtree und Source Serif 4 bleiben maßgeblich.

Die neuen Bilder wurden erst nach der Funktionsumsetzung mit dem eingebauten Imagegen-Werkzeug erzeugt, anhand der bevorzugten Raketenreferenz. Keine neue CLI-Bildpipeline, keine laufenden Generierungskosten in der App. Alle endgültigen Dateien liegen in `assets/story_covers/`.

- [Vollständiger Prompt-Satz](design-assets/story-cover-prompts-2026-11-01.json)
- [Inventar mit Story-IDs](design-assets/story-cover-inventory.json)
- [Geprüfte Bildschirmansichten](design-assets/premium-redesign-2026-11-01)

Die Bildschirmansichten verwenden echte App-Schriften und Iconfonts bei 390 × 844 pt, zusätzlich doppelte Textgröße. Titel und Schlösser bleiben lesbar. Eine letzte visuelle Kontrolle erkannte und korrigierte zu enge Größenbeschränkungen des Lautsprechersymbols; RenderBox-Prüfungen bestätigen anschließend 17 × 17 pt bei beiden Textgrößen.

## Nachweise

Die folgenden Gruppen überschneiden sich teilweise; ihre Zahlen sind keine additive Gesamtsumme.

- Finale Kernprüfung: **57 Tests bestanden** (Cover inklusive tatsächlich gebündelter Assets, Premium-Provider, Content-/Deck-UI, Sitzungszugriff und Generierungsoberfläche).
- Nach letzter Audiokorrektur: **40 Tests bestanden** für Content-Premium und Übungsreihenfolge; zusätzliche visuelle Größenprüfung bestanden.
- Deckpräsentation/Icons: **13 bestanden**; vollständiger Deckflow: **20 bestanden**.
- Bewegung/Details und angrenzende Praxis-/Settings-Prüfungen: **68 bestanden**, darunter Ablauf während einer Sitzung, Speicherung, kleine Displays und 2× Text.
- Backend: **24 Node-Tests** und **10 SQL-Assertiongruppen** auf PGlite bestanden, einschließlich fehlendem/abgelaufenem Premium, Sandbox, RPC-Rechten, Replay, Quoten und gleichzeitiger Verarbeitung.
- Zusätzliche Lernintegration: **47 bestanden, 2 fehlgeschlagen**. Die beiden Fehler in `test/data/learning_groups_test.dart` wurden identisch in einer isolierten Kopie von HEAD `e0a3050` reproduziert (synthetische Stapelaktivierung; erwartet 5, tatsächlich 0 bzw. 1). Ein fehlendes portugiesisches Testpaket in `language_selection_test.dart` wurde ebenfalls im unveränderten HEAD reproduziert. Diese Ergebnisse werden nicht als grüne Gesamtsuite ausgegeben.
- Der erste unbeschränkte Gesamtlauf wurde wegen hängenbleibender älterer Fixtures beendet. Betroffene Reihenfolge-/Darstellungsfixtures wurden gezielt aktualisiert und separat erneut geprüft. Ein älterer Gap-Markup-Zähltest erwartet noch 6 statt 10 Aufgaben; er gehört nicht zur finalen grünen Kernprüfung.
- `flutter analyze --no-pub lib`: **No issues found**. Die Gesamtanalyse meldet zwei bereits vorhandene `avoid_print`-Hinweise in anderen Tests.
- GitNexus: Index aktualisiert; Änderungsanalyse meldet 43 Symbole/53 Dateien und 184 betroffene Abläufe, Risiko CRITICAL, ohne `partial` oder `truncated`. Gemeinsame Navigations-/Lernkomponenten erklären den breiten Prüfbedarf; gezielte Zugriffstests ersetzen keine Behauptung eines risikolosen Diffs. Whitespacecheck mit dem vorhandenen CRLF-Format bestanden.

## iPhone-Auslieferung

`python3 tool/payment_build.py ios-profile --device 00008110-001651611E01401E` verwendete die vorhandene lokale, redigiert ausgegebene Kaufkonfiguration. Xcode-Build **39,5 s**, Installation und Start über WLAN **5,3 s**, Flutter-Exitcode **0**. Danach erneuter unabhängiger Start von `com.ardasayar.linglossa` erfolgreich. Keine Deinstallation und kein Löschen persönlicher Daten.

Buildbeleg: `build/payment/ios-profile-20261101T120335695194Z.json`. Alle 14 neuen PNGs sind im gebauten iPhone-Bundle vorhanden und stimmen per SHA-256 mit den Quellen überein; das Bundle enthält insgesamt 58 Cover.

Der Start protokollierte die bereits zuvor dokumentierten Impeller-Rendererdiagnosen (`SetInheritedOpacity`). Der Start war erfolgreich; diese Meldungen sind kein behaupteter bestandener visueller Gesamttest auf dem physischen Gerät. Die Kaufkonfiguration bleibt ein zugelassener Sandbox-Testbuild und wurde nicht zu einem Produktionsrelease umdeklariert. Android teilt die Flutter-Oberfläche und Zugriffspolitik; in dieser Auslieferung wurde kein Android-Gerät installiert oder neu getestet.


## Nachbesserung nach Gerätefeedback · 01.11.2026

- Stapelkopf: Schwierigkeitsgrad rechts am Inhaltsrand, vertikal mittig zum 84-pt-Themenicon. Beschriftung bricht innerhalb des Chips um. Der zusätzliche Werbesatz im gesperrten Stapel entfällt.
- Premium-Markierungen: einheitliches weißes Schloss auf dunklem Kreis, auch bei Stapeln, Importoptionen und der großen Hörkarte. Keine zusätzlichen Freischaltbanner unter Nachrichten oder dem Inhalte-Titel.
- Themenvokabeln: Schloss innen oben rechts in der grauen Prompt-Box. Ohne Premium öffnet der gesamte Eingabebereich die Paywall, ohne Tastatur und ohne KI-Aufruf; kein separater „Mit Premium erstellen“-Knopf. Premium behält die Eingabe und Generierung.
- Sprachwechsel: vier größere Wörter in Figtree 400; zwei davon seitlich ungefähr 30 % angeschnitten. Eintritt je Wort 650 ms, um 140 ms versetzt (gesamt 1070 ms). Fortlaufende Bewegung in einem 14-s-Zyklus statt 32 s, vertikale Amplitude bis 36 pt (auf dem geprüften Telefonformat etwa 27 pt). Bewegung reduzieren bleibt berücksichtigt.
- Prüfung: 23 Tests für Inhalte-/Generierungsoberflächen, 9 Deck-UI-Tests inklusive rechter Kante und vertikaler Zentrierung bei 390 pt sowie 320 pt/2×, 11 Animations-/Starttests bestanden. Gesamtanalyse: nur zwei bestehende `avoid_print`-Hinweise in fremden Tests, keine Fehler oder Warnungen. GitNexus nach Neuindexierung: 19 geänderte Symbole, 54 Dateien, 177 betroffene Abläufe, Risiko critical; keine Teil- oder Abschneidemarkierung. CRLF-aware Diffcheck bestanden.
- Neue Vorschau: [Sprachwechsel](design-assets/premium-redesign-2026-11-01/language-switch-v2.png), [Eintritt](design-assets/premium-redesign-2026-11-01/language-switch-entry-v2.png), [laufende Bewegung](design-assets/premium-redesign-2026-11-01/language-switch-drift-v2.png).

Auslieferung dieser Nachbesserung: Xcode-Build **39,7 s**, WLAN-Installation und Start **5,4 s**, Flutter-Exitcode **0**. Buildbeleg `build/payment/ios-profile-20261101T122304300107Z.json`; anschließender unabhängiger App-Start per `devicectl` erfolgreich. Bestehende Impeller-Rendererdiagnosen erneut sichtbar, kein neuer Fehler in der Dart-Analyse. Persönliche Daten wurden nicht gelöscht.
