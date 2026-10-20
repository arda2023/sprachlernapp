# Aktuelles Design der Sprachapp

Stand: integriertes Redesign vom 20.10.2026. Diese Datei und die [Bildschirmregeln](docs/redesign/design-system.md) bilden die aktuelle visuelle Anleitung. Es gibt keinen ergänzenden Rückgriff auf die frühere Designfassung. Lernlogik, Inhaltsverträge und abgeleitete Zähler regelt weiterhin [PRODUCT.md](PRODUCT.md).

## Gemeinsame Gestaltung

- Dunkler Grund: `nightPage` #0D0F14, Flächen `raisedInk` #1A1D26. Automatisches, helles und dunkles Motiv bleiben erhalten; semantische Farben über das Theme auflösen. Dunkle Storycover behalten hellen Text auch im hellen Motiv.
- Orange `active` #F77F00 für Fortschritt/Markierungen, `popover` #E26C00 für Sprechblasen und Hauptaktionen. Fortschrittsrollen: Im Aufbau blau, Gemeistert violett, Wörter geübt grün. Die alte Beschränkung auf genau zwei Akzentfarben gilt nicht.
- Source Serif 4 für redaktionelle Titel und Lesetext; Figtree für Bedienung, Metadaten und Zahlen. Zahlen möglichst tabellarisch. Maßgebliche Tokens: `lib/theme/app_theme.dart`; keine pauschale Änderung bestehender Schriftgrößen durch Dokumentbereinigung.
- Große Kartenradien nach Komponente (typisch 20–24 pt), Knöpfe und Chips als Pille. Trennung durch Flächenton und Abstand. Keine pauschalen Haarlinienrahmen; Zustandsrahmen wie richtig/falsch oder „heute“ im Kalender bleiben erlaubt.
- Kleine Infos/Auswahlen als verankerte orange Popover mit Pfeil, ohne Abdunkeln. Auslöser währenddessen orange mit weißen Inhalten. Bottom Sheets ohne sichtbare Griff-Linie.
- Offener Fortschrittsring: 110° Öffnung unten, im Uhrzeigersinn ab links unten, runde Enden. Für Play-Knopf und Stapel-Icons nach den Bildschirmregeln.
- Flamme und Wochenstern gehören zur aktuellen Streak-Anzeige. Die einmalige Sternfeier und das grüne Tagesziel sind erlaubt; keine neue dauerhafte Animation oder zusätzlicher Gamification-Auftrag daraus ableiten. Animationen nur bei tatsächlich sichtbarem Home, reduzierte Bewegung beachten.

## Weiter geltende Bedien- und Barrierefreiheitsregeln

- Antippflächen mindestens 44 × 44 logische Pixel; aussagekräftige gemeinsame Semantik für Beschriftung, Aktion und Zustand. Überschriften als solche auszeichnen.
- Home muss schmale Displays und mindestens 2× Textskalierung ohne abgeschnittene Kopfaktionen oder Overflow unterstützen. Kopfzeile darf umbrechen. Bestehende Begrenzung der Navigationsbeschriftung auf 1,3× nicht auf Lesetext übertragen.
- Zustände nicht allein durch Farbe vermitteln; Text, Icon oder zugängliche Beschriftung ergänzen. Kontrast im hellen und dunklen Motiv prüfen.
- Bei reduzierter Bewegung entbehrliche Animationen überspringen; bestehende Ereignismarken verhindern wiederholte Feiern. Navigations-/Eingabezustand beim Motivwechsel erhalten.
- Bestehende Übungshöhen 40/30 und Padding 16/6 sowie Antwortfeedback bleiben im Rahmen dieser Bereinigung unverändert; keine Layoutänderung aus historischen Maßtabellen ableiten. Regeln zur Antwortprüfung und zu Formen bleiben Produkt-/SRS-Regeln.
- Bereits vorhandene simulierte Audiozustände und mit „Bald“ gekennzeichnete Importwege nicht als fertige Funktionen beschreiben. Reale Sprachwahl und Inhalte verwenden; keine Redesign-Demo-Stories oder Demo-Streaks einführen.

## Orientierung und Historie

- [Aktuelle Bildschirmregeln](docs/redesign/design-system.md): Home, Stories/Reader, Stapel, Lernen, Wortliste und gemeinsame Widgets.
- [Übernahmebericht](docs/redesign/uebernahme.md): tatsächlich integrierter Umfang und bewahrte Funktionen.
- [Geräteabnahme](docs/redesign-device-performance.md): gemessene Performance und offene Befunde; kein Auftrag zur Änderung des Designs.
- `REDESIGN_BERICHTE.md`, [Home-Recherche](docs/redesign/home-01-recherche.html) und [Redesign-Arbeitsbericht](docs/redesign/bericht-redesign.md) dokumentieren frühere Überlegungen. Ihre verworfenen Entwürfe, alten Bildschirmbeschreibungen und Platzhalter sind keine aktuellen Anforderungen.
- Die alte Designfassung ist historisch gesichert; Archiv und Wiederherstellung stehen im [Aufräumbericht](docs/repository-cleanup.md). Gültige Grundregeln sind oben ausdrücklich übernommen, widersprechende alte Verbote nicht.

Bei einem echten Code-/Regelkonflikt die Abweichung benennen und gesondert klären; diese Dokumentbereinigung erlaubt keine stillschweigende Produkt- oder UI-Korrektur.
