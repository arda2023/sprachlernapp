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
| Popover | Sprechblase mit abgerundetem Pfeil zum Auslöser, Farbe `popover` (#E26C00), kein Abdunkeln, Tippen daneben schließt. Unter dem Auslöser, bei Platzmangel darüber. Der Pfeil sitzt immer auf der geraden Kante, nie auf einer Ecke. Info-Blasen bis 440 pt breit, Menüs höchstens 300 pt (`menuPopoverWidth`). Weiße Schrift erreicht auf #E26C00 3,3:1: Text auf dem Popover ist deshalb fett oder mindestens 18 pt und immer voll weiß, Hierarchie über Größe und Gewicht statt über transparentes Weiß (HIG › Accessibility › Kontrast). Genutzt von Kästchen, Flamme, Ziel-Icon, Streak-Box und allen weiteren kleinen Infos (siehe Overlay-Regel). Gemeinsame Bausteine: `widgets/popover_content.dart`. | `widgets/anchored_popover.dart` |
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

**Popover-Auslöser werden orange.** Alles, was eine Sprechblase öffnet (Sprache, Tagesziel, Flamme, Streak-Box, Importieren, Fortschritts-Kästchen, „Mehr“ und Erinnerungsstufe in der Wortliste, Wortart-Chip, Erinnerungsstufe und Menü „⋮“ beim Lernen, das getippte Wort, „Tagesziel“ in den Einstellungen), nimmt solange die Popover-Farbe an; Inhalte werden weiß. Umsetzung: `widgets/popover_trigger.dart`; Beschriftungen ohne eigene Pille erhalten sie über `TriggerPill`.

**Overlay-Regel (28.10.2026).** Eine Sache, ein Muster: Kurze Infos und Auswahlen, die von einem Element ausgehen, sind immer das orange Popover mit Pfeil auf dieses Element – Wortart-Info, Erinnerungsstufen, Übungsmenü und „Ein Problem melden“, Übungsart eines Textes (Pfeil aufs Cover), Satz- und KI-Übersetzung in Reader und Textübung. Ein Bottom Sheet bleibt nur für lange Inhalte oder Formulare: Wort-Details (Notiz), Bericht/Feedback, Tastaturhilfe. Löschen bestätigt ein Cupertino-Aktionsblatt (destruktiv, HIG › Action sheets).

**Haptik (28.10.2026).** Systemmuster in ihrer dokumentierten Bedeutung (HIG › Playing haptics): Popover öffnen und Schalter = Auswahl-Tick; Wort antippen (Lernen, Reader, Textübung, Onboarding) = leichter Impuls; gelöste Lücke = Erfolg; falsche Antwort oder falsche Form = Fehler (auch bei reduzierter Bewegung, Haptik ist keine Bewegung); „Fast richtig“ = Warnung; neutrales Synonym = keine Haptik (PRODUCT.md). Gilt für Lernen, Textübungen und Hören. Tagesziel-Chips und Wortlisten-Schalter (Favorit) ticken wie Schalter.

**Mikrointeraktionen (28.10.2026).** Story-Cover und Stapel-Karten sinken unter dem Finger auf 97 % und federn zurück (`widgets/press_scale.dart`; ein Scrollen löst sofort, reduzierte Bewegung: kein Skalieren). Der grüne Erfolgshaken beim Lernen ploppt mit kleinem Überschwinger auf, gleichzeitig mit der Erfolgs-Haptik. Neue Popovers wachsen aus ihrem Pfeil (Skalierung 0,9 → 1).

| Baustein | Regel | Datei |
|---|---|---|
| Sprachauswahl | Sprach-Pille mit Pfeil nach unten → Popover mit Cupertino-Rad (Flagge + Sprache) und „Auswählen“. Rad und Einstellungen listen genau `ContentLanguageProfile.supported` (Flagge und Name kommen vom Profil); eine neue Sprache wird nur dort ergänzt. Alle verwenden denselben geprüften Sprachwechsel. Noch nicht installierte Inhalte zeigen den bestehenden Leerzustand. | `home/widgets/language_panel.dart`, `domain/language_profile.dart` |
| Stapel-Karte | Links das Stapel-Icon im Fortschritts-Halbkreis wie der Play-Knopf (Anteil geübter Übungen, orange), daneben Name, Blitze statt Niveau-Text und Wortzahl. In der Stapelübersicht sind aktive Stapel komplett orange (weiße Inhalte, „Aktiv“-Chip); auf Home bleiben sie neutral. | `home/widgets/deck_tile.dart` |
| Stapel-Details | Großes Icon im Halbkreis (84 pt), Niveau-Chip mit Blitzen, Serif-Titel, Beschreibung; Kennzahlen „Geübt / Gemeistert / Noch neu“ nebeneinander über einem Balken; oranger Knopf „Mit diesem Stapel üben“; Schalter „In die tägliche Übung“ (orange); Stapel-Revue als eine Zeile; zuletzt geübte Formen. Ohne „Mehr davon“-Überschrift. | `decks/deck_details_screen.dart` |
| Wortliste | Suche + Playlist ohne Rahmen; Filter-Chips Alle · Neu · Im Aufbau · Gemeistert · Favoriten · Playlist · Deaktiviert (abgeleitet, nichts gespeichert). Jedes Wort als Karte: Stufe, Wort (anhören), Übersetzung in Orange, Satz (anhören), Metadaten; rechts nur Herz und „…“ → Popover mit Playlist, Deaktivieren, Details. Leere Liste und erfolglose Suche haben eigene Texte. | `words/word_list_screen.dart`, `words/widgets/word_list_item.dart` |
| Lernen | Oben Schließen (×), durchgehender orangefarbener Fortschrittsbalken ohne Textzeile; Fehlerwiederholungen zeichnen ab ihrem Start einen gelben Abschnitt, danach geht es orange weiter und ältere gelbe Abschnitte bleiben erhalten (Anzahl nur für VoiceOver; Sonderzustände wie „Tagesziel erreicht“ bleiben sichtbar), Menü. Satzkarte mit großem Radius, Übungsart als Chip mit deutscher Wortart („Substantiv“, nie das rohe UD-Tag „NOUN“; `domain/part_of_speech.dart`), öffnet die Forminfo als Popover. Sprachen ohne ausgearbeitete Formerklärung erhalten eine aus der Karte gebaute Erklärung (Wortart, Form, Rolle der Wortart, Sonderzeichen der Sprache, nach dem Lösen die Grundform; `domain/grammar_hint.dart`). Übersetzung als Karte ohne „Deutsch“-Label. Nach einer gelösten Aufgabe bleibt die Tastatur offen (Feld behält den Fokus, Eingaben gesperrt); ihre Fertig-Taste öffnet die nächste Aufgabe. Aktionen schweben ohne Leiste: Hauptknopf orange, sonst ruhige Fläche; Erfolgshaken grün. Wort antippen: leichter Haptik-Impuls, das Wort erhält eine abgerundete Fläche in Popover-Orange mit weißer Schrift (Satzzeichen bleiben außen vor), die Übersetzung erscheint als inhaltsgroße orange Sprechblase (Radius 14) mit Pfeil auf das Wort und Lautsprecher-Knopf (simulierter Abspielzustand wie im Reader); erneutes Tippen auf das Wort oder daneben schließt. Logik, Reihenfolge und Abtipp-Regeln unverändert. | `decks/deck_practice_screen.dart`, `decks/widgets/practice_chrome.dart` |
| Knöpfe allgemein | `PrimaryActionButton` orange mit weißer Schrift, `OutlineActionButton` als ruhige Fläche ohne Rahmen, beide als Pille. | `widgets/action_buttons.dart` |

## Einstellungen (28.10.2026)

Referenzen (Mobbin; der gewünschte Refero-Zugang war in dieser Umgebung nicht verfügbar): gruppierte, abgerundete Abschnitte mit Icons wie [CapWords](https://mobbin.com/screens/0dddf71e-4bfc-4e81-b3c2-3194e475be15) und [Uxcel Go](https://mobbin.com/screens/0299b341-cb0a-4a7f-8f64-db443510df66); Abschnittsüberschriften und Werte rechts wie [Character AI](https://mobbin.com/screens/0a65f4fd-71b8-4fdd-9572-b088b0568e5e) und [ChatGPT](https://mobbin.com/screens/5f9685b3-ed4e-4f86-96b0-4d75dd301859); Motiv-Vorschauen wie [Claude](https://mobbin.com/screens/664bd952-7201-4889-988e-7b6302ec7637).

**Aufbau:** Zurück · großer Serif-Titel (verschwindet beim Scrollen in einen kleinen Titel in der Leiste) → Lernsprache → Darstellung → Üben → Audio und Erinnerungen → Inhalte und Hilfe → Version.

| Baustein | Regel | Datei |
|---|---|---|
| Abschnitt | Überschrift (Figtree 14, gedämpft), eine abgerundete Gruppe (20 pt) auf `raisedInk`, Zeilen getrennt durch eingerückte schwache Linie, optionale Fußnote. Kein Rahmen. | `settings/settings_screen.dart` |
| Lernsprache | Flagge, Name, Installationsstand; aktuelle Sprache mit orangem Haken. Alle Profile aus `ContentLanguageProfile.supported`. | `settings_screen.dart` |
| Darstellung | Drei Mini-Vorschauen (Automatisch diagonal geteilt, Hell, Dunkel), gewählte mit orangem Zustandsring. Schmal oder große Schrift: eine Zeile je Motiv. Das App-eigene Motiv ist eine bewusste Produktentscheidung (DESIGN.md) gegen HIG › Dark Mode; Standard bleibt „Automatisch“. | `settings_screen.dart` |
| Üben | Tagesziel mit Wert-Pille → Tagesziel-Popover (Pfeil auf die Pille); orange Schalter für Akzente, automatisch weiter, Grammatiktabellen. Ganze Zeile schaltet. | `settings_screen.dart` |
| Noch nicht verfügbar | Benachrichtigungen, Ton aus, Audiogeschwindigkeit, Spracheingabe gedämpft mit „Bald“-Chip; Fußnote „Noch nicht verfügbar – …“, VoiceOver-Hinweis je Zeile. | `settings_screen.dart` |
| Inhalte und Hilfe | Inhaltsupdates, Lokale Berichte und Feedback, Bildschirm-Vorschauen (Entwicklerwerkzeug, daher zuletzt). | `settings_screen.dart` |

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

## Onboarding (24.10.2026)

Herleitung: Recherche unter `aislop/onboarding` (Reddit-Threads, YouTube-Transkripte). Kernpunkte: erst Wert zeigen, dann nach dem Konto fragen (Duolingo); jede Frage muss den nächsten Screen sichtbar verändern; Fortschritt zeigen, Zurück erlauben; Social Login (Apple zuerst) plus Weg ohne Konto. Mobbin-Referenzen: Illustration + „Weiter“ + „Ich habe schon ein Konto“ wie [Nibble](https://mobbin.com/screens/43b10bcd-05d6-496b-a3ae-051f56687de5) und [Headway](https://mobbin.com/screens/35d60dff-8ff0-4748-83f0-915d87faf1ed); Anmeldeknöpfe wie [Me+](https://mobbin.com/screens/66b2668a-f0e0-451a-a7de-993c9efb2e7f) und [Uxcel Go](https://mobbin.com/screens/8ea4e776-8f94-45eb-befa-5fa3ca08a590).

**Reihenfolge (5 Seiten):** Willkommen → Thema → Tagesziel → Wort antippen → Konto. Oben Zurück und orange Schritt-Segmente wie in der Übung; unten ein oranger Hauptknopf, der abgeblendet bleibt, bis die Seite hat, was sie braucht. Arbeitsname „Lingvist“ (Platzhalter).

| Seite | Regel | Datei |
|---|---|---|
| Willkommen | Logo + Wortmarke, animiertes Buch mit Wort-Blasen, Serif-Titel, ein Satz. „Los geht’s“; „Ich habe schon ein Konto“ springt zur Konto-Seite. | `onboarding/onboarding_screen.dart` |
| Thema | Vier Kacheln in den Story-Farben (Reisen, Beruf, Alltag, Kultur). Gewählt = oranger Rand + Haken. Bestimmt den Beispielsatz auf Seite 4 und wird gespeichert. | `onboarding_screen.dart` |
| Tagesziel | Animierter Ring mit Flamme; Locker 5 · Normal 10 (vorgewählt) · Ernsthaft 15 · Intensiv 20 Wörter. Gewählt in Popover-Orange. Wird als echtes Tagesziel gespeichert. | `onboarding_screen.dart`, `main.dart` |
| Wort antippen | Beispielsatz aus dem gewählten Thema; antippbare Wörter gepunktet unterstrichen, das erste pulsiert ein paar Mal. Antippen → Wort orange, darunter die orange Bedeutungs-Karte wie im Reader. Nur Onboarding-Demo, kein Inhaltspaket, kein Lernstand. | `onboarding_screen.dart` |
| Konto | Animiertes Logo, „Speichere deinen Fortschritt“; „Mit Apple fortfahren“ (weiß), „Mit Google fortfahren“, „Mit E-Mail fortfahren“, „Ohne Konto weiter“. Anmeldung ist Platzhalter: jede Option beendet das Onboarding, Konto-Optionen sagen per Hinweis, dass die Anmeldung bald kommt und bis dahin lokal gelernt wird. | `onboarding_screen.dart` |

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
