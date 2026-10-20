# Integriertes Design · Bildschirmregeln

Aktuelle Bildschirmregeln des am 20.10.2026 ins Hauptprojekt übernommenen Redesigns. Verbindlicher Einstieg und gemeinsame Barrierefreiheitsregeln: [DESIGN.md](../../DESIGN.md). Historische Recherche und Redesign-Berichte sind Herkunftsnachweise, keine zusätzlichen Vorgaben. Eine weitere Politur ist ein eigener Auftrag; der frühere Hinweis auf eine vorläufige Strukturphase ist keine Anweisung, die aktuelle Oberfläche zurückzubauen.

Dateiangaben in den Tabellen bezeichnen bestehende Komponenten unter `lib/screens/`, `lib/widgets/`, `lib/models/` bzw. `lib/presentation/providers/`; sie sind keine Dateien relativ zu diesem Dokument. Produktlogik und Inhaltsverträge bleiben in [PRODUCT.md](../../PRODUCT.md).

## Home (20.10.2026)

Herleitung, Mobbin-Referenzen und verworfene Richtungen: [historische Home-Recherche](home-01-recherche.html) (Richtung A „Heute-Karte“).

**Reihenfolge:** Kopfzeile → Streak-Box → Fortschritts-Kästchen → Stories → Aktive Stapel. Geübt wird über den Play-Knopf in der Leiste.

| Baustein | Regel | Datei |
|---|---|---|
| Kopfzeile | Sprache · Ziel-Icon mit „2/10“ (heute geübt / Tagesziel) · Flamme mit Streak-Zahl · Einstellungen. Kein Profilknopf, solange es kein Profil gibt. | `home/widgets/home_header.dart` |
| Ziel-Icon | `target-fill`, grau. Beim ersten Sehen von Home nach Erreichen des Tagesziels: kurzer Pop und Wechsel in die Farbe von „Wörter geübt“ (Grün); danach dauerhaft grün. Antippen → Popover „Du hast heute **2 von 10** Wörtern geübt“ + Auswahl 5/10/15/20/30. | `home_header.dart`, `goal_panel.dart` |
| Streak-Box | Wie `streak4`: Kasten mit 6 Tagesplätzen + Stern; darunter eine sehr schwache Linie und genau ein Motivationssatz, wichtige Wörter fett in Orange. Kein „Noch X Tage …“. Antippen → Kalender-Popover. | `streak_strip.dart` |
| Streak-Icons | Erledigte Tage verschmelzen zu einem orangen Balken mit weißen `check-mark`. Offene Tage leere Kreise. Verpasster Tag: grauer Kreis mit weißem `cross-mark`. Stern offen: `star-1-remix` in Orange. Stern geholt: Balken läuft bis zum Stern, `star-1-solid` in Weiß. | `streak_strip.dart`, `widgets/svg_glyph.dart` |
| Stern-Moment | Einmal pro Stern-Tag, beim ersten tatsächlichen Sehen von Home (nicht unter einer laufenden Sitzung): wachsen, drehen, aufleuchten, mittlere Haptik. Reduzierte Bewegung: keine Animation. | `streak_strip.dart` |
| Wort der Woche | Nach einem Stern sieben Tage lang ein eigenes, am besten gelerntes Wort. | `streak_providers.dart` |
| Fortschritts-Kästchen | Im Aufbau (Blau) · Gemeistert (Violett) · Wörter geübt (Grün); ohne Wortzahlen nur zwei. Titel, Zahl, Balken – keine Beschriftung darunter. Antippen: Kästchen wächst leicht und wird orange, Balken weiß; darunter erscheint ein gleichfarbiges Popover, dessen Pfeil mittig auf das Kästchen zeigt. Alle drei Popovers sind gleich groß (Inhalte werden übereinander gemessen). | `progress_tiles.dart` |
| Popover | Sprechblase mit abgerundetem Pfeil zum Auslöser, Farbe `popover` (#E26C00, tief genug für weiße Schrift), kein Abdunkeln, Tippen daneben schließt. Unter dem Auslöser, bei Platzmangel darüber. Genutzt von Kästchen, Flamme, Ziel-Icon und Streak-Box. | `widgets/anchored_popover.dart` |
| Kalender-Popover | Links „Aktueller Streak“, rechts „Wochensterne“. Streak-Tage als durchgehendes helles Band, Stern-Tage weiß gefüllt mit Stern-Badge, heute weiß umrandet. | `streak_calendar.dart` |
| Play-Knopf | Fortschritts-Halbkreis (Tagesziel) statt Vollkreis: unten offen (110°), beginnt unten links, füllt im Uhrzeigersinn, runde Enden, Orange. | `widgets/app_bottom_bar.dart`, `widgets/progress_ring.dart` |
| Bottom Sheets | Keine sichtbare Griff-Linie mehr (Farbe transparent, Abstand bleibt). | `theme/app_theme.dart` |
| Aktive Stapel | Höchstens 3. Neutrale Stapel-Karten mit Icon im offenen Fortschrittsring, Name, Blitzen und Wortzahl (siehe Stapel-Karte unten). | `home_deck_row.dart` |
| Story-Karten | Cover bleibt immer dunkel, Text daher fest hell (behebt den Kontrastfehler im hellen Modus). Später mit Illustrationen. | `story_carousel.dart` |

**Icons:** Die SVGs (`target-fill`, `star-1-solid`, `star-1-remix`, `check-mark`, `cross-mark`) werden ohne zusätzliches Paket gezeichnet: Pfaddaten stehen in `AppGlyphs`, `GlyphIcon` rendert sie.

**Echte Daten:** Streaks stammen ausschließlich aus dem Übungsprotokoll. Es gibt keinen Demo-Schalter.

**Streak-Regeln** (abgeleitet aus dem Review-Log, nichts gespeichert, `lib/domain/streak.dart`): Ein Tag zählt ab der ersten Übung. Eine Lücke setzt den Streak auf 0; geholte Sterne bleiben. Jeder 7. Tag einer ununterbrochenen Serie ist ein Stern. Nach einer Lücke bleibt das × sichtbar, bis wieder geübt wird; dann beginnt die Leiste links. Am Tag nach einem Stern ist die Leiste leer.

**Barrierefreiheit:** Jede Antippfläche ≥ 44 pt; eigene Beschriftungen nach dem Muster `MergeSemantics → Button → Semantics(label, excludeSemantics)`, damit VoiceOver Beschriftung und Aktion gemeinsam erhält.

## Stories & Reader (20.10.2026)

Mobbin-Referenzen: Import-Raster wie [ElevenReader](https://mobbin.com/screens/499ce035-77a7-4fa7-9254-e3f3db60c2d5) und [Speechify](https://mobbin.com/screens/50a3b7f2-1361-47df-8f77-398102fbebaa); „Continue“-Zeile wie [Apple Books](https://mobbin.com/screens/38f5b90d-0d5b-467f-9e2d-7155ba17a3ea) und [Blinkist](https://mobbin.com/screens/7cec730b-97f5-48c2-9ccb-4846a2d8ef69); Kategorie-Karussells mit Anzahl wie [Life Reset](https://mobbin.com/screens/c68ed0a3-309b-4e13-acfa-44f65e4246c1); markiertes Wort im Lesetext wie [ElevenReader](https://mobbin.com/screens/812faffb-b3bf-40d1-8992-b01bc23ca873).

**Stories-Tab, Reihenfolge:** Titel + „Importieren“ → Nachrichten-Karussell (endlos, links/rechts) mit „Demo“-Chip → Weiterlesen (max. 3, zuletzt gelesen zuerst) → Deine Texte → eine Karussell-Reihe pro Kategorie mit Anzahl.

| Baustein | Regel | Datei |
|---|---|---|
| Story-Karte | Geschlossenes Cover in der Kategoriefarbe mit großer, blasser Platzhalter-Illustration (Icon) oben rechts; Titel Serif weiß, darunter Niveau · Minuten. Begonnen: „A2 · 42 %“ + oranger Balken. Gelesen: weißes Häkchen-Badge. Gilt auch für Home. | `home/widgets/story_carousel.dart` |
| Kategorien | Wissenschaft, Restaurant, Englisch im Beruf, Reisen, Alltag, Gesundheit, Kultur, Technik – je Farbe + Icon (`StoryCategory`). „Küche“ → Restaurant, „Medizin“ → Gesundheit. | `models/story_category.dart` |
| Weiterlesen | Zeile mit Mini-Cover, Titel, Kategorie · Niveau, Balken + Prozent, oranger Play-Kreis. Nur begonnene, nicht beendete Stories/Texte. | `story_library_screen.dart` |
| Importieren | Pill oben rechts. Öffnet das orange Popover (Pfeil zum Knopf) mit 2×2-Raster: Text einfügen (Zwischenablage, funktioniert) · Datei (TXT, EPUB, PDF, SRT) · YouTube (Transkript per Link) · Webseite – die letzten drei als „Bald“. Max. 5.000 Wörter (PRODUCT.md). Nach dem Import öffnet sich der Text direkt. | `widgets/import_panel.dart` |
| Deine Texte | Leer: Hinweis-Karte mit „Text importieren“. Sonst „+ Import“-Karte und papierfarbene Karten (Quelle, Titel, Wörter · Minuten, Fortschritt). Lange drücken → löschen. | `story_library_screen.dart` |
| Reader | Eine lange Seite, nur nach unten. Oben: Zurück · Titel (erscheint beim Scrollen) · Prozent. Links eine 4-pt-Leiste, die sich beim Scrollen orange füllt. Kopf: Kategorie-Symbol, Meta, Serif-Titel, Hinweis. Ende: „Geschafft!“-Karte. Schwebendes Dock unten: Vorlesen · Übersetzen. Öffnet an der zuletzt gelesenen Stelle. | `stories/story_reader_screen.dart` |
| Wort-Popover | Orange Sprechblase mit Pfeil auf die Tippstelle: Grundform (Serif), Wortart, „im Text: …“, Lautsprecher-Knopf (Aussprechen), Deutsch, weißer Knopf „Zum Lernen hinzufügen“ (echter Speicherstatus entscheidet). Das getippte Wort ist orange hinterlegt. | `widgets/word_popover.dart` |
| Satz-Popover | Übersetzungsmodus: Satz + Deutsch in derselben Sprechblase. | `widgets/sentence_popover.dart` |

**Gespeichert (nur UI-Zustand, `<support>/ui/`):** Leseposition je Story (`reading_progress_<lang>.json`) und importierte Texte (`imported_texts_<lang>.json`). Lernstände bleiben ausschließlich in `user.db`.

**Nicht übernommen:** Die 32 Redesign-Demo-Stories und ihr Demo-Glossar. Die Aussprache ist bis zu echten Audiodateien nur ein sichtbarer Abspielzustand (wie in der Wortliste).

## Querschnitt, Stapel, Wortliste, Lernen (20.10.2026)

Mobbin-Referenzen: Wortliste wie [Preply](https://mobbin.com/screens/a839b88a-b538-45da-b6b3-6ea5ae43b30c) (Status-Chips), [Quizlet](https://mobbin.com/screens/ca3b6042-3294-4b83-a1ab-725d0d158ce4) und [Babbel](https://mobbin.com/screens/bde86591-6531-4fdf-9a8d-d5cba3de2bfc); Stapel-Details wie [Acorns](https://mobbin.com/screens/e0c4b9aa-f8b1-410c-8f1c-5f5319711073) (Titel, Start-Knopf, Kennzahlen nebeneinander); Lernen wie [Speak](https://mobbin.com/screens/2c36516e-5c7c-4ceb-8bd1-a3f104323bcf) und [Vocabulary](https://mobbin.com/screens/ee92742d-dbac-4963-8afc-63f7cfd1ea41) (Schließen, dünner Fortschritt, Satzkarte, großer Knopf unten).

**Keine Umrandungen.** Karten, Eingabefelder, Knöpfe, Sheets und Leisten trennen sich nur über Flächenton (`raisedInk` auf `nightPage`) und Abstand. Rahmen bleiben nur, wo sie einen Zustand tragen (richtig/falsch, „heute“ im Kalender).

**Popover-Auslöser werden orange.** Alles, was eine Sprechblase öffnet (Sprache, Tagesziel, Flamme, Streak-Box, Importieren, Fortschritts-Kästchen, „Mehr“ in der Wortliste), nimmt solange die Popover-Farbe an; Inhalte werden weiß. Umsetzung: `widgets/popover_trigger.dart`.

| Baustein | Regel | Datei |
|---|---|---|
| Sprachauswahl | Sprach-Pille mit Pfeil nach unten → Popover mit Cupertino-Rad (Flagge + Sprache) und „Auswählen“. Englisch und Portugiesisch (Brasilien) verwenden denselben geprüften Sprachwechsel wie die Einstellungen. Noch nicht installierte Inhalte zeigen den bestehenden Leerzustand. | `home/widgets/language_panel.dart` |
| Stapel-Karte | Links das Stapel-Icon im Fortschritts-Halbkreis wie der Play-Knopf (Anteil geübter Übungen, orange), daneben Name, Blitze statt Niveau-Text und Wortzahl. In der Stapelübersicht sind aktive Stapel komplett orange (weiße Inhalte, „Aktiv“-Chip); auf Home bleiben sie neutral. | `home/widgets/deck_tile.dart` |
| Stapel-Details | Großes Icon im Halbkreis (84 pt), Niveau-Chip mit Blitzen, Serif-Titel, Beschreibung; Kennzahlen „Geübt / Gemeistert / Noch neu“ nebeneinander über einem Balken; oranger Knopf „Mit diesem Stapel üben“; Schalter „In die tägliche Übung“ (orange); Stapel-Revue als eine Zeile; zuletzt geübte Formen. Ohne „Mehr davon“-Überschrift. | `decks/deck_details_screen.dart` |
| Wortliste | Suche + Playlist ohne Rahmen; Filter-Chips Alle · Neu · Im Aufbau · Gemeistert · Favoriten · Playlist · Deaktiviert (abgeleitet, nichts gespeichert). Jedes Wort als Karte: Stufe, Wort (anhören), Übersetzung in Orange, Satz (anhören), Metadaten; rechts nur Herz und „…“ → Popover mit Playlist, Deaktivieren, Details. Leere Liste und erfolglose Suche haben eigene Texte. | `words/word_list_screen.dart`, `words/widgets/word_list_item.dart` |
| Lernen | Oben Schließen (×), orange Segment-Fortschritt mit „Noch N Übungen“, Menü. Satzkarte mit großem Radius, Übungsart als Chip (öffnet Grammatik). Übersetzung als Karte mit „Deutsch“-Label. Aktionen schweben ohne Leiste: Hauptknopf orange, sonst ruhige Fläche; Erfolgshaken grün. Wort-Tooltip in Popover-Orange. Logik, Reihenfolge und Abtipp-Regeln unverändert. | `decks/deck_practice_screen.dart`, `decks/widgets/practice_chrome.dart` |
| Knöpfe allgemein | `PrimaryActionButton` orange mit weißer Schrift, `OutlineActionButton` als ruhige Fläche ohne Rahmen, beide als Pille. | `widgets/action_buttons.dart` |
