# Stories und Stapelmischung, 31.10.2026

## Umsetzung

285 vorhandene redaktionelle Texte sind als 57 Stories pro Sprache (en, es, it, nb, pt-BR) in `assets/content/<lang>/stories.json` enthalten. `tool/export_story_library.py` erzeugt diese Dateien erneut aus `story_library`. Stabile sprachgebundene Story-IDs erhalten die Zuordnung des Lesefortschritts. Die Bibliothek zeigt die redaktionellen Kategorien und öffnet die Texte über den bestehenden Reader einschließlich Geräte-TTS. Die Texte behaupten keine geprüften Wörterbuchbindungen: Wort- und Satzabfragen verwenden den bestehenden Pfad für nicht annotierte Texte, einschließlich Offline-Wörterbuch und erlaubter Laufzeitübersetzungen.

Neue Stapelziele werden unabhängig von alphabetischen Paketpositionen stabil gemischt. Verfügbare Themenmetadaten und Anfangsbuchstaben werden mit Abstand verteilt, soweit Alternativen vorhanden sind. Gruppen-, Lemma- und Oberflächenausschlüsse bleiben erhalten. Das ist keine vollständige semantische Klassifikation aller Wörter. Wiederholungen nach Fehlern und fällige Reviews bleiben nach den bestehenden Lernregeln erreichbar. Nur Allgemeine Sprache ist ohne gespeicherte Auswahl aktiv. Explizite manuelle Schalterstellungen bleiben erhalten, auch nach Neustart.

## Nachweise

- 149 gezielte Tests für Domain, Repository, Lernabläufe, Lesefortschritt und Story-Dateien bestanden.
- Fünf zusätzliche Reader-Routentests: neue Stories in jeder Sprache geöffnet, Sprache und vollständiger Text geprüft, keine Demoübersetzung.
- Fünf Tests mit echten Inhaltspaketen: jeweils 14 Stapel, eindeutige verfügbare Ziele und veränderte Reihenfolge. Messung aller Stapel einer Sprache im Test: 143 bis 325 ms.
- Statische Analyse der acht geprüften Implementierungs-/Testdateien: No issues found.
- iPhone von Claus über WLAN: Profile-Build erfolgreich (37,2 s), Installation und Start erfolgreich (8,2 s), Flutter exit code 0. Bestehende lokale Buildkonfiguration verwendet, App nicht deinstalliert.
- Laufzeit meldete Impeller-Opacity-Warnungen beim Start. Keine visuelle Geräteabnahme behauptet. Warnung unverändert dokumentiert.

## Abgrenzung zum früheren Gesamtauftrag

Zehn noch nicht geschriebene Texte und die dokumentierten Längenkonflikte sind durch diese Einbindung nicht gelöst. Die Einbindung ist kein neuer sprachlicher oder faktischer Freigabenachweis. Weitere offene Arbeiten des früheren Gesamtauftrags bleiben in `story_library/work_state.json` dokumentiert.
