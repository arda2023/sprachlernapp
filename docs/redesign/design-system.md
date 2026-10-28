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

**Nachrichten-Karte:** Bild oben, darunter nur der Titel (Ressort, Niveau und Lesezeit nur im VoiceOver-Label), knapper Innenabstand.

**Stories-Tab, Reihenfolge:** Titel + „Importieren“ → Nachrichten-Karussell (endlos, links/rechts) mit „Demo“-Chip → Weiterlesen (max. 3, zuletzt gelesen zuerst) → Deine Texte → eine Karussell-Reihe pro Kategorie mit Anzahl.

| Baustein | Regel | Datei |
|---|---|---|
| Story-Karte | Geschlossenes Cover in der Kategoriefarbe mit großer, blasser Platzhalter-Illustration (Icon) oben rechts; Titel Serif weiß, darunter Niveau · Minuten. Begonnen: „A2 · 42 %“ + oranger Balken. Gelesen: weißes Häkchen-Badge. Gilt auch für Home. | `home/widgets/story_carousel.dart` |
| Kategorien | Wissenschaft, Restaurant, Englisch im Beruf, Reisen, Alltag, Gesundheit, Kultur, Technik – je Farbe + Icon (`StoryCategory`). „Küche“ → Restaurant, „Medizin“ → Gesundheit. | `models/story_category.dart` |
| Weiterlesen | Zeile mit Mini-Cover, Titel, Kategorie · Niveau, Balken + Prozent, oranger Play-Kreis. Nur begonnene, nicht beendete Stories/Texte. | `story_library_screen.dart` |
| Importieren | Pill oben rechts. Öffnet das orange Popover (Pfeil zum Knopf) mit 2×2-Raster: Text einfügen (Zwischenablage, funktioniert) · Datei (TXT, EPUB, PDF, SRT) · YouTube (Transkript per Link) · Webseite – die letzten drei als „Bald“. Max. 5.000 Wörter (PRODUCT.md). Nach dem Import öffnet sich der Text direkt. | `widgets/import_panel.dart` |
| Deine Texte | Leer: Hinweis-Karte (Titel ohne Untertitel) mit „Text importieren“. Sonst „+ Import“-Karte und papierfarbene Karten (Quelle, Titel, Wörter · Minuten, Fortschritt). Lange drücken → löschen. | `story_library_screen.dart` |
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
| Persönliche Story-Sammlung | „Aus Storys“ als eigene ruhige Zeile in Stories und Stapel, erst nach gespeicherter Lernentscheidung. Serif-Titel, gemeinsame Karten mit Übersetzung und aktuellem Satz, Status in Textform; bestehender `PrimaryActionButton` zum Lernen. Kein Aktivierungsschalter und keine Entfernen-Aktion. Schreibfreie Bildschirm-Vorschau mit Beispieldaten. | `stories/story_collection_screen.dart` |
| Wortliste | Suche + Playlist ohne Rahmen; Filter-Chips Alle · Neu · Im Aufbau · Gemeistert · Favoriten · Playlist · Deaktiviert (abgeleitet, nichts gespeichert). Jedes Wort als Karte: Stufe, Wort (anhören), Übersetzung in Orange, Satz (anhören), Metadaten; rechts nur Herz und „…“ → Popover mit Playlist, Deaktivieren, Details. Leere Liste und erfolglose Suche haben eigene Texte. | `words/word_list_screen.dart`, `words/widgets/word_list_item.dart` |
| Lernen | Oben Schließen (×), durchgehender orangefarbener Fortschrittsbalken ohne Textzeile; Fehlerwiederholungen zeichnen ab ihrem Start einen gelben Abschnitt, danach geht es orange weiter und ältere gelbe Abschnitte bleiben erhalten (Anzahl nur für VoiceOver; Sonderzustände wie „Tagesziel erreicht“ bleiben sichtbar), Menü. Satzkarte mit großem Radius, Übungsart als Chip (öffnet Grammatik). Übersetzung als Karte ohne „Deutsch“-Label. Nach einer gelösten Aufgabe bleibt die Tastatur offen (Feld behält den Fokus, Eingaben gesperrt); ihre Fertig-Taste öffnet die nächste Aufgabe. Aktionen schweben ohne Leiste: Hauptknopf orange, sonst ruhige Fläche; Erfolgshaken grün. Wort-Tooltip in Popover-Orange. Logik, Reihenfolge und Abtipp-Regeln unverändert. | `decks/deck_practice_screen.dart`, `decks/widgets/practice_chrome.dart` |
| Knöpfe allgemein | `PrimaryActionButton` orange mit weißer Schrift, `OutlineActionButton` als ruhige Fläche ohne Rahmen, beide als Pille. | `widgets/action_buttons.dart` |

## Inhalte (24.10.2026)

Mobbin-Referenzen: große „Als Nächstes“-Karte mit Kachel-Reihe darunter wie [Babbel](https://mobbin.com/screens/4362b601-1544-43d7-aa4a-20a178466c8b); Sektionen mit „See all“ wie [Nibble](https://mobbin.com/screens/227d5950-a38c-4df2-a9e6-fd3ffdcd662c) und [Coursera](https://mobbin.com/screens/94c8c55f-9447-4e5d-a071-db7b6c2a055c); Spalten mit gestapelten Zeilen wie die App-Listen im [App Store](https://mobbin.com/screens/19a11986-b09c-4e5b-976c-78a23137378f).

**Reihenfolge:** Titel „Inhalte“ → Texte → Hören → Grammatik → Grammatikregeln. Jede Kategorie zeigt ihre Inhalte direkt; kein Zwischenraster mehr. Jede Sektion hat eine eigene Form, damit die Seite nicht aus vier gleichen Karussells besteht.

| Baustein | Regel | Datei |
|---|---|---|
| Sektionskopf | Serif-Überschrift, rechts „Mehr anzeigen ›“ (wie „Mehr ansehen“ auf Home) → vollständige Liste der Kategorie. Keine Meta-Zeile mit Anzahlen darunter. VoiceOver: „Alle Texte/Hörübungen/Grammatikübungen/Grammatikregeln anzeigen“. | `content/content_dashboard_screen.dart`, `widgets/more_button.dart` |
| Texte | Karussell mit denselben Covern wie Stories (`StoryCard`), Texte aus gelesenen Stories zuerst, höchstens 8. Antippen → Übungsart-Sheet → Übung. | `content_dashboard_screen.dart`, `content/text_library_screen.dart` |
| Hören | Breite Karte im Wiedergabe-Ton (`playback`) mit blassem Wellenform-Icon: „Als Nächstes“ (erste offene Übung; sind alle gelöst: „Noch einmal hören“), Serif-Titel, Untertitel, Blitze + Thema, oranger Play-Kreis. Darunter Kacheln für die übrigen Übungen: Lautsprecher-Badge, Titel, Blitze, Thema; gelöst = grüner Haken. Kein Untertitel auf den Kacheln. | `content_dashboard_screen.dart` |
| Grammatik | Horizontal scrollende Spalten mit je drei Zeilen; die nächste Spalte schaut rechts herein. Zeile: 52-pt-Feld (`activeTint` mit „Aa“, gelöst `successTint` mit Haken), Titel, Untertitel, Blitze. | `content_dashboard_screen.dart` |
| Grammatikregeln | Zweispaltiges Raster der ersten vier Regeln als Karteikarten: Blitze (Niveau) + Lesezeit, direkt darunter Serif-Titel und Kurzbeschreibung (oben bündig, kein Leerraum dazwischen). Antippen → Regel-Detail. | `content_dashboard_screen.dart` |
| Übungsliste („Mehr anzeigen“ bei Hören/Grammatik) | Keine Aufteilung in „Meine Übungen“/„Fertig“ mehr: alle Übungen in Inhaltsreihenfolge, gelöste mit grünem Haken vor dem Chevron. Keine Zeile „N Übungen · N fertig“. | `practice/practice_library_screen.dart`, `widgets/chevron_row.dart` |

**Dynamic Type:** Kachel-Reihen und Spalten haben keine feste Höhe; sie wachsen mit der höchsten Karte (`IntrinsicHeight`), statt abzuschneiden.

## Onboarding und Paywall (24.10.2026)

Herleitung: Recherche unter `aislop/onboarding` und der Freemium-Plan (Premium 9,99 €/Monat oder 49,99 €/Jahr, kein Trial, Paywall einmal nach der Wort-Demo, schließbar, kein zweites Angebot; kostenlos lernen ohne Konto, Konto erst vor einem Kauf). Refero-Referenzen:
- Ablauf: [CapWords „Photo-to-Word Onboarding“](https://refero.design/flows/6104) – personalisieren → kurze Demo → Paywall direkt nach dem Erfolgsmoment.
- Brücke vor der Paywall: [Clucky Plan-Checkliste](https://refero.design/screens/746df9c6-8e56-4b63-b4bc-791fec47a3a9).
- Paywall-Aufbau:
  - X links, „Wiederherstellen“ rechts, wenige Vorteile, Bedingungen unter dem Knopf: [Perplexity](https://refero.design/screens/4182e2ca-0000-4d6a-a477-cf89130425c3), [CapWords](https://refero.design/screens/b13c6d76-0182-4741-8226-48cfabeca7b2).
  - Tarif und Knopf unten angeheftet: [IFTTT](https://refero.design/screens/3f7373f6-512d-4ce7-9412-1d56d5ac36a3); gestapelte Tarifzeilen: [Perplexity](https://refero.design/screens/4182e2ca-0000-4d6a-a477-cf89130425c3).
  - Beruhigungszeile unter dem Knopf: [Revolut](https://refero.design/screens/f6875db2-4608-49b4-b803-9e390a1801b5).
- Stil:
  - Leitstil Chantlings: dunkle Fläche, Serif-Titel, Orange nur für gefüllte Hauptaktionen, Glut-Schein als einzige Tiefe.
  - Von Cron Calendar der weiche Glow unter dem Hauptknopf, von Pipe die Tonflächen statt Rahmen.

**Reihenfolge (5 Seiten + Paywall):** Willkommen → Thema → Tagesziel → Wort antippen → „Dein Start steht“ → Paywall. Oben Zurück und orange Schritt-Segmente wie in der Übung; unten ein oranger Hauptknopf mit Glut-Schein, abgeblendet, bis die Seite hat, was sie braucht. Vorwärts-Wischen ist bis dahin gesperrt, Zurück-Wischen geht immer. Arbeitsname „Lingvist“ (Platzhalter).

| Seite | Regel | Datei |
|---|---|---|
| Willkommen | Logo + Wortmarke (Schriftskalierung bis 1,3 wie Chrome), animiertes Buch, Serif-Titel. „Los geht’s“; „Ich habe schon ein Konto“ öffnet das Konto-Sheet (Platzhalter, startet ohne Konto). | `onboarding/onboarding_screen.dart` |
| Thema | Vier Kacheln (Reisen, Beruf, Alltag, Kultur) mit Beispielsatz. Gewählt = oranger Rand + Haken. Bestimmt Seite 4, die Plan-Zeile und den ersten Paywall-Vorteil; wird gespeichert. | `onboarding_screen.dart` |
| Tagesziel | Locker 5 · Normal 10 (vorgewählt) · Ernsthaft 15 · Intensiv 20. Gewählt in Popover-Orange; bei großer Schrift bricht die Wortzahl unter den Namen um. Wird als echtes Tagesziel gespeichert. | `onboarding_screen.dart`, `main.dart` |
| Wort antippen | Satz aus dem Thema; antippbare Wörter gepunktet, das erste pulsiert viermal. Antippen → orange Bedeutungs-Karte wie im Reader. Nur Demo, kein Lernstand. | `onboarding_screen.dart` |
| Dein Start steht | Karte mit Plan-Pille („Dein Plan · Thema · N Wörter / Tag“) und drei Zeilen, die nacheinander abgehakt werden (Thema, Tagesziel, erstes Wort). Erst nach dem letzten Haken wird „Weiter“ aktiv. | `onboarding_screen.dart` |
| Paywall | Siehe unten. | `onboarding/paywall_screen.dart` |

**Paywall:**
- **Kopf:**
  - Oben links X („Schließen“, führt direkt in die App), rechts „Wiederherstellen“; die Leiste wird bis 1,3 skaliert.
  - Darunter die Plan-Pille, dann „Lingvist Premium“ und der Serif-Titel „Mehr lesen. Deine eigenen Wörter lernen.“.
- **Vorteile** in fester Reihenfolge, je eine Zeile Detail, darunter „Alle veröffentlichten Grammatik- und Textübungen inklusive.“:
  1. „Lies, was dich interessiert“ – „Alle Storys ohne Tageslimit – auch zu {Thema}.“
  2. „Lerne mit deinen eigenen Texten“.
  3. „Verstehe fehlende Stellen direkt“ – „500 neue KI-Übersetzungen pro Monat.“
- Kopf und Vorteile scrollen; wo sie unter den angehefteten Block laufen, blenden sie auf 20 pt weich aus statt hart abgeschnitten zu werden.
- **Tarife** als gestapelte Zeilen, direkt über dem Knopf angeheftet, damit der Preis immer neben „Premium abonnieren“ steht (ab Schriftgröße 1,35 scrollen sie mit, damit der Block den Bildschirm nicht füllt):
  - Links Auswahlkreis, Titel und Zusatz, rechts Preis und Zeitraum – so bricht kein deutscher Text um.
  - Jährlich ist vorgewählt: 49,99 € / Jahr, „entspricht 4,17 € / Monat“, Plakette „58 % sparen“ neben dem Titel.
  - Monatlich: 9,99 € / Monat, monatlich kündbar.
  - Der gewählte Tarif bekommt einen orangen Rand, eine Orange-Tönung und einen gefüllten Kreis, dessen Haken mit leichtem Überschwinger einploppt; der andere zeigt nur einen leeren Ring.
- **Fuß:**
  - „Premium abonnieren“, direkt darunter die Bedingungen des gewählten Tarifs („… Automatische Verlängerung, im Store kündbar.“, wechseln weich mit).
  - Dann „Kostenlos weiterlernen“ sowie „Nutzungsbedingungen“ und „Datenschutz“ (brechen bei großer Schrift um).
- **Ehrliche Platzhalter:**
  - „Premium abonnieren“ öffnet zuerst das Konto-Sheet („Konto für dein Abo“). Nach der Wahl sagt ein Hinweis, dass Käufe in dieser Version noch nicht freigeschaltet sind, und die App startet kostenlos.
  - Wiederherstellen und Rechtslinks melden ebenfalls nur „kommt bald“.
  - Ohne echte Store-Abrechnung darf die Paywall nicht veröffentlicht werden.
- **Einmalig:** Schließen, „Kostenlos weiterlernen“ und ein Kaufversuch beenden das Onboarding. System-Zurück führt zu „Dein Start steht“ und speichert nichts.

**Bewegung:**
- **Seiten:** Seitenwechsel per Knopf in 340 ms (easeOutCubic). Beim Wischen liegt der Inhalt jeder Seite leicht zurück (35 % Parallaxe) und blendet aus.
- **Textblöcke:** Sie kommen beim ersten Besuch gestaffelt von unten (`Reveal`, 420 ms + 60 ms je Stufe).
- **Tippen:** Antippbare Elemente geben auf 97 % nach (`Pressable`).
- **Übergang Plan → Paywall:**
  - Das Onboarding tritt zurück (Skalierung 0,94, Deckkraft 0,4).
  - Die Paywall blendet ein und gleitet 6 % von unten (520 ms, zurück 360 ms).
  - Die Plan-Pille fliegt als Hero an ihren Platz oben in der Paywall.
- **Reduzierte Bewegung:** Alles steht sofort; Seiten springen.

**Haptik** (`Haptic` in `widgets/onboarding_motion.dart`):
- `selectionClick`: Auswahl, Tarif, Wischen auf eine neue Seite, jeder Plan-Haken.
- `lightImpact`: Wörter, Zurück, X, Textlinks.
- `mediumImpact`: Hauptknöpfe und Anmeldeknöpfe.

Knöpfe geben ihre Haptik selbst; das programmatische Weiterblättern löst keine zweite aus.

**Töne:**
- Epidemic Sound, ambient, also stumm bei Lautlos-Schalter (`presentation/onboarding_sounds.dart`):
  - Auswahl-Klick bei Thema, Ziel und Tarifwechsel (`onboarding_select.mp3`).
  - Häkchen-Ton je Plan-Zeile (`streak_check.mp3`).
  - Aufsteigendes „Hud“ beim Öffnen der Paywall (`onboarding_paywall.mp3`).
- Wörter, Zurück und Schließen haben nur Haptik.
- In Tests sind die Töne stumm.

**Animationen:** Rive (`assets/rive/onboarding.riv`), drei Artboards Logo · Welcome · Goal, je „Intro“ (einmal) → „Idle“ (Schleife). Quelle ist der Generator `tool/rive/onboarding/build_scene.py`; neu bauen mit `python3 tool/rive/onboarding/build_scene.py` und `rive tool/rive/onboarding --once` (Rive CLI, ohne Login, keine Skripte). Bei reduzierter Bewegung, in Widget-Tests und ohne native Rive-Runtime zeigt `OnboardingArt` ein Standbild (Logo per `CustomPaint`).

**Gespeichert:** `<support>/ui/onboarding.json` (`done`, `interest`), nur UI-Zustand; das Tagesziel in den Einstellungen. Tests und Vorschauen überspringen das Onboarding (`onboardingStoreProvider` ist dort `null`).

## Abschluss nach der Übung (24.10.2026)

Mobbin-/Video-Referenzen: Abschluss-Hierarchie wie Babbels „Gut gemacht“-Screen (Titel, zwei Kennzahl-Kästchen, Vokabeln, „Weiter“); Wortkarten als „Stacked Cards“-Scroll-Effekt (Framer-Tutorial „Stacked Cards Effect“); Häkchen-Animation nach der vom Nutzer gelieferten `check.riv` (Ring, Strich, Punkte).

**Wann:** Nach jeder Stapel-Übung (auch „Lernen“ über den Play-Knopf), sobald das Tagesziel erreicht ist. Sonst bleibt die bisherige Zusammenfassung. Ziel und Streak werden nach der letzten Antwort frisch gelesen.

**Ablauf:** (1) Die Streak-Leiste erscheint in der Bildmitte. (2) Der orange Balken lädt sich von links bis zu heute auf, mit einem nach rechts laufenden Lichtband (dunkles Orange → hell). Passiert er einen Tag, poppt dessen Häkchen (Ring platzt, Haken zeichnet sich mit Überschwinger, Punkte fliegen weg) mit kurzem Ton und mittlerer Haptik. Solange der Balken lädt, vibriert das Telefon durchgehend (leichte Impulse alle 55 ms); der Ladeton wird bei Ankunft ausgeblendet. Währenddessen blendet der Titel über der Leiste ein. (3) Am 7. Tag: Der Stern wird weiß, sobald der Balken ihn erreicht, taucht ab, schwillt an und setzt sich (weiche Ein-/Ausgänge, keine harten Knicke), dreht sich dabei in der Luft um die Hochachse und zeigt nach der Hälfte die gefüllte Seite; Glockenton, starke Haptik. Der Stern-Moment auf Home spielt danach nicht noch einmal. (4) Titel und Leiste gleiten nach oben an ihren Platz, darunter erscheinen gestaffelt die Kästchen, die Wortkarten und „Weiter“.

| Baustein | Regel | Datei |
|---|---|---|
| Titel | „Sehr gut!“ (Stern-Tag: „Wochenstern geholt!“), darunter ein Satz mit Tag und Abstand zum Wochenstern. Ohne Namen, solange es kein Profil gibt. | `completion/practice_completion_screen.dart` |
| Streak-Leiste | Gleiche Geometrie wie die Streak-Box auf Home (6 Tage + Stern), ohne Motivationssatz. | `completion/widgets/streak_charge_bar.dart` |
| Kästchen | Links animierte Rivetober-Flamme (`assets/rive/completion_flame.riv`, orange eingefärbt; Standbild bei reduzierter Bewegung) + Streak („Tage in Folge“), rechts Ziel-Icon + „erreicht/Ziel“ (darf über dem Ziel liegen, z. B. 12/10). | `practice_completion_screen.dart` |
| Wortkarten | „Neue Wörter“ (erstmals gesehen) bzw. „Heute geübt“, wenn nichts neu war. Gestapelt: Titel, Streak-Leiste, Kennzahlen und „Neue Wörter“ bleiben fest. Nur der Kartenbereich darunter scrollt: Jede Karte bleibt unterhalb der Überschrift hängen, die nächste schiebt sich darüber; kurze Auswahl-Haptik beim Ein-/Ausrasten; verdeckte Karten werden etwas kleiner und dunkler. Trennung über einen weichen Schatten, keine Umrandung. | `completion/widgets/stacked_word_cards.dart` |
| Ton | `assets/sounds/` (Epidemic Sound): Laden, Häkchen, Stern. iOS „ambient“: Stummschalter gilt, mischt sich mit anderer Wiedergabe. | `presentation/celebration_sounds.dart` |

**Reduzierte Bewegung:** sofort der Endzustand, keine Töne, ein Haptik-Impuls.
