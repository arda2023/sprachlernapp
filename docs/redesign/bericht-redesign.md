> Historischer Bericht aus der isolierten Redesign-Kopie. Der tatsächliche Integrationsstand und Abweichungen stehen in [uebernahme.md](uebernahme.md). Demo-Daten und Isolationseinstellungen wurden nicht übertragen.

# Redesign-Bericht

Stand: 20.10.2026 · Arbeitskopie `sprachapp-redesign`, Branch `codex/redesign` (nichts committet)

Dieser Bericht fasst zusammen, was seit Beginn des Redesign-Chats verändert wurde, welche Designregeln daraus entstanden sind und was später ins Original übertragen werden soll (und was nicht). Die verbindlichen visuellen Regeln stehen in [`DESIGN.md`](../../DESIGN.md); die Recherche zur Home-Richtung in [`home-01-recherche.html`](home-01-recherche.html).

---

## 1. Ausgangslage und Spielregeln

- **Ziel:** Kompletter visueller Neuentwurf der App: *spielerisch, aber nicht zu sehr wie Duolingo*. Schriften dürfen sich ändern.
- **PRODUCT.md:** Visuelle bzw. Marken-Regeln daraus werden bewusst ignoriert (z. B. „keine Flammen-Icons“). **Produkt- und Lernlogik bleibt unverändert** (SRS, Boxen, Zähler, Reihenfolgen, Abtipp-Regeln).
- **Stapelnamen** bleiben unverändert.
- **Isolation:** Nur in dieser Kopie arbeiten; keine Pakete hinzufügen/aktualisieren, keine Deployments, keine Web-Unterstützung. Eigene App-IDs und der Datenordner `redesign/` bleiben.
- **Vorgehen:** Mobbin-MCP als Referenzquelle; erst Struktur/Layout, Design-Skills erst in der Schluss-Politur (noch nicht erfolgt).

## 2. Die Designsprache in Kürze

| Thema | Regel |
|---|---|
| Grundton | Dunkel: Seite `nightPage` (#0D0F14), Flächen `raisedInk` (#1A1D26). Trennung über Flächenton und Abstand. |
| Akzent | Orange: `active` (#F77F00) für Fortschritt/Marken, `popover` (#E26C00) für Sprechblasen, aktive Flächen und Hauptknöpfe. |
| Fortschrittsfarben | Im Aufbau = Blau, Gemeistert = Violett, Wörter geübt = Grün (neu in `AppPalette`: `progressBuilding`, `progressMastered`, `progressWords`). |
| Schrift | Source Serif 4 für Titel und Lesetext (redaktionell), Figtree für Bedienelemente und Zahlen. |
| Formen | Große Radien (Karten 20–24 pt), Knöpfe und Chips als Pille. |
| **Keine Umrandungen** | Karten, Suchfelder, Knöpfe, Sheets, Leisten haben keine Rahmen. Rahmen nur, wo sie einen Zustand zeigen (richtig/falsch, „heute“ im Kalender). Sheets ohne Zieh-Strich. |
| **Popover statt Sheet** | Kleine Infos und Auswahlen öffnen eine orange Sprechblase mit Pfeil, die am Auslöser verankert ist (oben oder unten, je nach Platz), ohne Abdunkelung. |
| **Auslöser wird orange** | Solange ein Popover offen ist, färbt sich sein Auslöser orange, Icons und Text darin werden weiß (Sprache, Tagesziel, Flamme, Streak-Box, Kästchen, Importieren, „…“). |
| Fortschritts-Halbkreis | Wie der Play-Knopf der Navigationsleiste: Kreis unten offen (110°), füllt im Uhrzeigersinn von links unten, runde Enden. Auch um Stapel-Icons. |
| Eigene Icons | Ziel, Stern (voll/Umriss), Häkchen, Kreuz als eigene SVG-Pfade (ohne Paket). |
| Mikro-Interaktionen | Stern-Feier beim 7. Streak-Tag, Ziel-Symbol wird grün bei erreichtem Tagesziel; laufen nur, wenn Home sichtbar ist, einmalig pro Ereignis (mit Haptik). |

## 3. Was sich pro Bereich geändert hat

### Home
- **Kopfzeile:** Sprach-Chip „Englisch“ (öffnet Sprachauswahl), Tagesziel-Symbol mit „2/10“, Flamme mit Streak-Zahl, Einstellungen.
- **Sprachauswahl:** Popover mit Cupertino-Rad (10 Sprachen alphabetisch, Englisch in der Mitte) und „Auswählen“. *Platzhalter:* andere Sprachen melden „folgt bald“.
- **Tagesziel:** Popover mit Stand („Du hast heute X von Y Wörtern geübt“) und Ziel-Chips 5/10/15/20/30. Ziel erreicht → Symbol wird animiert grün.
- **Streak-Box:** Wochenleiste mit 6 Tagen + Stern. Geübte Tage als orange Pille mit Häkchen, verpasster Tag als grauer Kreis mit ×, am 7. Tag leuchtet der Stern. Darunter feine Linie und ein Motivationssatz mit fetten Akzentwörtern. Tippen → Kalender-Popover („Aktueller Streak“, „Wochensterne“).
- **Streak-Logik (abgeleitet, nichts gespeichert):** Ein Tag zählt ab der ersten Übung. Eine Lücke setzt den Streak auf 0, verdiente Sterne bleiben. Jeder 7. Tag einer Serie ist ein Stern.
- **Drei Fortschritts-Kästchen:** Im Aufbau / Gemeistert / Wörter geübt mit farbigem Balken, ohne Untertitel. Tippen → Kästchen wächst, wird orange, Popover mit Erklärung (alle Popover gleich groß).
- **Entfernt:** „Heute“-Karte, Wochenziel-Karte, „Noch X Tage“, Hinweis „Deine erste Übung…“, alte Vokabel-Fortschrittsleiste.
- **Stories-Karussell:** Begonnene Stories zuerst, Karten mit Kategorie-Farbverlauf, Icon, Fortschrittsbalken oder „Fertig“.
- **Aktive Stapel:** max. 3, als Stapel-Karte (siehe unten).
- **Navigationsleiste:** Play-Knopf mit Fortschritts-Halbkreis statt Ring.

### Stories
- **Kopf:** Titel + „Importieren“ (rechts, wird beim Öffnen orange).
- **Nachrichten-Karussell** ganz oben (große Karten ohne Rahmen/Trennlinie, „Demo“-Chip).
- **Weiterlesen:** zuletzt begonnene Story mit Fortschritt in % und Play-Knopf.
- **Deine Texte:** importierte Texte; Langdruck löscht. Import-Popover mit 4 Kacheln: *Text einfügen* (aus Zwischenablage, funktioniert), *Datei*, *YouTube*, *Webseite* („Bald“). Max. 5.000 Wörter, bleibt auf dem Gerät.
- **Kategorien** als Karussells: u. a. Wissenschaft, Restaurant, Englisch im Beruf, Reisen, Gesundheit … mit 32 Demo-Stories.

### Reader
- Links eine **vertikale Fortschrittsleiste**; es wird nur nach unten gescrollt.
- Kopfzeile: Zurück, Titel erscheint erst beim Scrollen, Prozentanzeige.
- **Wort antippen** → Popover mit Pfeil genau am Wort: Wort, Wortart, Form im Text, **Aussprechen** (Lautsprecher-Icon, derzeit simuliert), Deutsch, **„Zum Lernen hinzufügen“**.
- Satz-Übersetzung ebenfalls als Popover.
- Unten Dock mit „Vorlesen“ / „Übersetzen“, am Ende Karte „Geschafft!“. Lesefortschritt wird gespeichert (ab 98 % „fertig“).

### Stapel
- **Stapel-Karte (Home + Übersicht):** links Stapel-Icon im Fortschritts-Halbkreis (Anteil geübter Übungen), daneben Name, **Blitze statt „Einsteiger“**, Wortzahl.
- **Stapelübersicht:** aktive Stapel **komplett orange** mit weißen Inhalten und „Aktiv“-Chip; auf Home bleiben sie neutral.
- **Stapel-Details:** großes Icon im Halbkreis, Niveau-Chip mit Blitzen, Serif-Titel, Beschreibung; Kennzahlen „Geübt / Gemeistert / Noch neu“ nebeneinander über einem Balken; oranger Knopf **„Mit diesem Stapel üben“**; Schalter „In die tägliche Übung“; Stapel-Revue als eine Zeile; zuletzt geübte Formen (aufklappbar).

### Lernen (Stapel-Übung)
- Oben **×** zum Beenden, orange Segment-Fortschrittsleiste mit „Noch N Übungen“, Menü.
- Satzkarte mit großem Radius, Übungsart als Chip (öffnet Grammatik).
- Übersetzung als eigene Karte mit „Deutsch“-Label.
- Aktionen schweben ohne Leiste: Hauptknopf orange, sonst ruhige Fläche; Erfolgshaken grün; Wort-Tooltip orange.

### Wortliste
- Suchfeld + Playlist-Knopf ohne Rahmen.
- **Filter-Chips:** Alle · Neu · Im Aufbau · Gemeistert · Favoriten · Playlist · Deaktiviert (mit Anzahl, abgeleitet).
- **Wort-Karten:** Stufenanzeige, Wort mit Lautsprecher, Übersetzung in Orange, Beispielsatz, „Zuletzt gesehen / Wiederholt“. Rechts Herz und **„…“** → Popover mit „In der Playlist“, „Deaktiviert“, „Details zu …“.
- Eigene Leerzustände (keine Wörter / Suche ohne Treffer / Filter leer); korrekte Einzahl („1 Wort · 1 Übung“).

### Querschnitt
- Primärknopf orange mit weißer Schrift, Sekundärknopf als ruhige Fläche (beide Pille, ohne Rahmen).
- Rahmen entfernt in: Inhalte-Übersicht, Grammatikregel, Auswahl- und Lückentext-Übungen, Lese-Werkzeugleiste, Vorlese-Panel, Erfolgskarte, Snackbars, Sheets.

## 4. Neue technische Bausteine

| Datei | Zweck |
|---|---|
| `lib/widgets/anchored_popover.dart` | Verankerte Sprechblase mit Pfeil (eigene `PopupRoute`). |
| `lib/widgets/popover_trigger.dart` | Hülle, die den Auslöser während des offenen Popovers orange färbt. |
| `lib/widgets/svg_glyph.dart` | Eigene SVG-Icons (Ziel, Stern, Häkchen, Kreuz) ohne Paket. |
| `lib/widgets/progress_ring.dart` | Neu: `gapDegrees` für den offenen Halbkreis. |
| `lib/domain/streak.dart` | Reine Dart-Logik für Streak und Sterne (aus dem Übungsprotokoll abgeleitet). |
| `lib/presentation/providers/streak_providers.dart` | Streak, Wort der Woche, „Feier schon gezeigt“-Marken. |
| `lib/presentation/providers/reading_providers.dart` | Lesefortschritt und importierte Texte (lokale JSON-Dateien). |
| `lib/screens/home/widgets/*` | Neue Home-Bausteine: Streak-Leiste, Kalender, Fortschritts-Kästchen, Ziel- und Sprach-Panel, Stapel-Karte. |
| `lib/screens/stories/widgets/*` | Import-Panel, Wort- und Satz-Popover. |

Entfernt: `today_card`, `vocab_progress`, `weekly_goal_card`, `daily_goal_sheet`, `streak_calendar_sheet`, `word_lookup_sheet`.

## 5. Hinweise für die spätere Übertragung ins Original

**Übernehmen:** geprüfte UI-Dateien, Theme-Änderungen, neue Widgets, Domain-Streak-Logik samt Tests, `DESIGN.md`.

**Nicht übernehmen:**
- `lib/models/story_catalog.dart`: 32 Demo-Stories und Demo-Glossar, nur zum Zeigen des Layouts.
- Die Nachrichten sind Beispielinhalte („Demo“-Chip).
- `DEMO_STREAK` (nur Debug-Schalter für Vorführungen).
- App-Kennungen und der Datenunterordner `redesign/` (Isolation dieser Kopie).

**Bewusste Platzhalter:** Sprachwechsel, Datei-/YouTube-/Webseiten-Import und die Aussprache sind nur angedeutet; die Logik dahinter fehlt bewusst.

## 6. Prüfung

- `flutter analyze` → *No issues found!*
- `flutter test` → *+300: All tests passed!* (neu: `test/domain/streak_test.dart`, `test/home_streak_test.dart`, `test/stories_redesign_test.dart`; angepasst: Widget-, Stapel-, Story- und Zähler-Tests)
- Alle Bildschirme im iOS-Simulator (iPhone 17 Pro) durchgeklickt.

## 7. Offene Punkte

1. **Datei-Import:** Paket `file_picker` hinzufügen? (Entscheidung offen; bisher nur Zwischenablage.)
2. **Politur-Phase:** Design-Skills (Animation, UX-Texte, Apple-Design) erst jetzt am Ende einsetzen.
3. Noch nicht neu gestaltet: Bereich **Inhalte** (nur Rahmen entfernt), Einstellungen, Grammatik-Detail im Detail.
4. Commit und GitNexus-Neuindex der Kopie, sobald gewünscht.
