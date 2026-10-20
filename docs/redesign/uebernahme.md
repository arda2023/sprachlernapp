# Übernahme des Redesigns – 20.10.2026

## Basis und Umfang

Auf ausdrücklichen Wunsch wird der optimierte Entwicklungsstand `a66bab0` in den Hauptordner integriert. Der vorherige `main`-Stand `893afd2` ist unter `codex/before-redesign-20261020` gesichert. Die Redesign-Quelle bleibt unverändert im separaten Ordner `sprachapp-redesign` (Setup-Basis `4492743`, anschließend uncommittete Designänderungen).

Die Übernahme wurde als Dreiwege-Zusammenführung vorbereitet. Übernommen wurden Theme, Home, Stapel, Lernoberflächen, Stories/Reader, Wortliste, gemeinsame Widgets, abgeleitete Streak-Anzeige, lokale Leseposition/Clipboard-Texte und die Design-Dokumentation. Die bisherige Produktlogik wurde mit den neuen Oberflächen verbunden.

Nicht übernommen wurden die 32 Demo-Stories, Demo-Glossar/Routing, der Demo-Streak-Schalter, App-IDs der Kopie und deren Datenordner `redesign/`. `StoryCategory` enthält ausschließlich Farben, Icons und Themenzuordnung. Die bereits zuvor vorhandenen Beispielnachrichten bleiben als Demo gekennzeichnet und werden nicht für Portugiesisch angezeigt.

## Bewahrte Funktionen und Schutzmaßnahmen

- Inhaltspakete, Datenbankcode, Content-Reader, Prozessvalidierung, SQL-Sammelabfragen und Lerncontroller entsprechen weiterhin der optimierten Basis. Das Redesign ersetzt keine Inhaltsdatenbank und keine Lernstände.
- Home behält die Zwischenspeicherung innerhalb derselben Inhaltsgeneration. Beim Sprachwechsel werden keine Werte der vorherigen Sprache angezeigt.
- Der Streak liest Übungsaktivitäten gebündelt; die neue Anzeige fragt nicht jede Karte einzeln ab. Das Wort der Woche lädt nicht die gesamte Wortliste mit allen Historien.
- Englisch und Portugiesisch (Brasilien) nutzen die bestehende validierte Sprachauswahl. Fehler bleiben sichtbar. Laufende Reader/Lernaktionen behalten ihre Übergangssperren.
- Echte Story-Referenzen, Reaktivierung, Navigation zur tatsächlich gespeicherten Karte und die bestehenden Laufzeitübersetzungen bleiben erhalten. Der Reader verarbeitet weiterhin Unicode-Wörter.
- Lesefortschritt und importierte Texte liegen sprachgetrennt unter `<support>/ui/`. Schreibvorgänge warten auf die erste Lesung, sind serialisiert und ersetzen Dateien über temporäre Dateien. Löschen während des Ladens lässt Texte nicht wieder erscheinen; abgeschlossene Stories bleiben abgeschlossen.
- Die vollständige Kopfzeile wechselt bei wenig Platz/großer Schrift in mehrere Zeilen. Sternanimationen laufen nur auf dem sichtbaren Home-Tab.
- Datei-, YouTube- und Webseitenimport bleiben als „Bald“ gekennzeichnet. Die bereits simulierte Aussprache wurde nicht zu einer Audiofunktion ausgebaut.

## Prüfung

- `flutter test --timeout 5m`: **507 bestanden, 6 übersprungen, kein Fehler**. Darunter Inhalts-/Sprachwechseltests, Lernzustände, Story-Zielnavigation, echte Inhaltspakete und Layouttests.
- Neue Tests: verzögerte Lesungen/Schreibvorgänge, Löschen während des Ladens, Sprachtrennung, dauerhaft abgeschlossene Stories und vollständige portugiesische Kopfzeile bei 320 pt / zweifacher Schriftgröße.
- Abfragemessung: Öffnen, Zurückkehren und Stapel-Umschalten halten die Inhaltsabfragen unverändert (`decks: 2, selection: 1, targets: 6`), `histories=0`. Streak: eine Sammelabfrage, keine Einzelhistorien.
- `flutter analyze`: keine Fehler oder Warnungen; ein bereits in der optimierten Basis vorhandener Info-Hinweis (`avoid_print` in `test/data/baseline_adoption_pack_test.dart:43`).
- Der reguläre macOS-Build benötigt ein konfiguriertes Entwicklungszertifikat. Der zusätzliche unsignierte Build (`xcodebuild … CODE_SIGNING_ALLOWED=NO build`) meldet **BUILD SUCCEEDED**; App-Kennungen und Signaturkonfiguration wurden dafür nicht geändert.
- Testlogs enthalten bereits bestehende Hinweise auf nicht gebündelte Google-Fonts bei deaktiviertem Netzwerkabruf. Die Tests belegen keine vollständige visuelle Geräteabnahme; das Redesign wurde hier nicht erneut auf einem physischen iPhone/Android-Gerät durchgeklickt.

- GitNexus nach Neuindex: Der Gesamtdiff einschließlich der bestehenden Entwicklungsbasis wurde als kritisch eingestuft; seine Symbolauflistung ist bei 1.000 Einträgen begrenzt. Die gesonderte Prüfung gegen `a66bab0` liefert 407 geänderte Symbole und 23 betroffene Abläufe ohne gekürzte Symbolauflistung. Die Reichweite des gemeinsamen Themes bleibt kritisch; Tests und gezielte Quellprüfung ergänzen die statische Analyse, deren dynamische Aufrufe und Ablaufbudget keine vollständige Abdeckung garantieren.

Keine Veröffentlichung, kein Push und kein Deployment. Die bestehende Web-/Backend-Veröffentlichung wird durch diese lokalen Änderungen nicht aktualisiert.
