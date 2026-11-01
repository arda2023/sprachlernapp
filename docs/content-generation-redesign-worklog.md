# Inhalte: Generierung und Übungsüberarbeitung

## Auftrag und Abnahme

Quelle: Nutzerauftrag in `goal-objective.md` der Attachment-Gruppe
`5dc5acf9-9f44-41ec-9ba2-477a1e299696`. Der aktuelle Abschlussstand steht am Ende dieses Verlaufs.
Die ursprüngliche Aufgabenliste bleibt zur Nachvollziehbarkeit erhalten.

1. Oben in Inhalte ein sofort nutzbares Themenfeld, maximal zwei kurze Sätze,
   bis 50 Wörter mit festen Beispielsätzen und Übersetzungen. Authentifizierte
   serverseitige Haiku-Generierung, keine Provider-Schlüssel im Client.
   Orange Aktion oben rechts erscheint erst bei Eingabe. Beim Start neutrale
   Aktion „Wird generiert“, sanfter weißer Lichtlauf etwa alle drei Sekunden,
   orange Füllung von links. Vollständige Füllung erst bei erfolgreichem Ergebnis.
   Auswahlansicht zum Abwählen. Erst „Stapel erstellen“, später „Zum Stapel
   hinzufügen“. Ein dauerhafter sprachgebundener Stapel „Generierte Vokabeln“.
   Bestehende Lernzustände und feste Sätze erhalten, Duplikate kontrollieren.
2. Passende generierte Storybilder in einheitlicher 2D-Art. Alltag und Wirtschaft
   bleiben ohne Bilder. Hauptmotive müssen in breiten, hohen und kleinen Karten
   erkennbar bleiben. Stärkerer unterer schwarzer Verlauf für weiße Beschriftung.
3. Abschlusskarten: Überschrift „Neue Wörter“ entfernen und abrupt abgeschnittene
   Schatten durch eine ruhige Stapeldarstellung ersetzen. Alle Karten erreichbar.
4. Hörübungen gestalterisch angleichen. Standalone-Playbutton ohne Kasten,
   Zeitspur oder Sekundenangaben.
5. Erledigte Übungen in Inhalte nach hinten sortieren.
6. Grammatikregel-Karten ohne Minutenangaben, einschließlich Semantik.
7. Lückentextansicht angleichen: keine überflüssige Übungskategorie über Titel,
   oranger Fortschrittsbalken statt „0 von n“, abgerundete Lückenfelder wie
   Stapelübungen, Texte ungefähr doppelt so lang.
8. Grammatik: Satz-Audio erst nach korrekter Antwort und oben rechts am Satz.
   Gesamte Ansicht passend zum Appdesign überarbeiten.
9. Gemeinsame Umsetzung für en, es, it, nb und pt-BR; schmale/große Handys,
   Tablets, große Schrift, beide Motive und reduzierte Bewegung überprüfen.

## Gestaltungsreferenz

Verbindliche primäre Referenz: bestehendes Produktdesign in DESIGN.md und
`docs/redesign/design-system.md`. Screenshots des Nutzers belegen die konkreten
Fehler, keine abweichende neue Farbwelt. Refero-Skill gelesen; Craft-Details
zu Formularen/Zugänglichkeit als Ergänzung. Für die größeren neuen Oberflächen
und Storybilder folgt noch eine eigene Referenzrecherche und visuelle Abnahme.

Beibehalten: dunkler Seitengrund, Source Serif für Titel/Lesetext, Figtree für
Bedienung, Orange für Aktion/Fortschritt, semantische Theme-Farben, runde Flächen.
Kein zusätzlicher generischer Kartenrahmen um den Hörbutton. Lesbarkeit und
Fokus stehen über Dekoration. Fortschritt darf nicht vor Servererfolg fertig
wirken. Reduzierte Bewegung deaktiviert Lichtlauf und entbehrliche Übergänge.

| Entscheidung | Quelle | Rolle |
| --- | --- | --- |
| Offene Übungen vor erledigten | Nutzerauftrag Punkt 4 | Reihenfolge, kein Lernstandsreset |
| Keine Minuten auf Regelkarten | Nutzerauftrag Punkt 5 | Relevante Metadaten reduzieren |
| Hörbutton ohne Zeitspur/Kasten | Nutzerauftrag Punkt 3 | Direkte Wiedergabe |
| Grammatik-Audio erst nach Lösung | Nutzerauftrag Punkt 7 | Antwort nicht vorwegnehmen |
| Neutrale Aktion mit orangem Füllstand | Nutzerauftrag Punkt 1 | Erkennbarer laufender Vorgang |

## Verifizierter Zwischenstand

- Dashboard und vollständige Hör-/Grammatikbibliothek partitionieren stabil:
  zuerst offen, dann erledigt, innerhalb jeder Gruppe redaktionelle Reihenfolge.
  Die geteilten Inhaltslisten bleiben unverändert; Completion-Notifier löst die
  neue Darstellung aus. Vor Begrenzung auf die Dashboard-Vorschau sortieren.
- Minuten von Regelkarten und deren Screenreader-Label entfernt.
- `test/practice_order_test.dart`: 31 Tests bestanden. Abdeckung: fünf
  Sprachkennungen, beide Übungsarten, stabile Reihenfolge, keine Listenmutation,
  leere/komplett erledigte Listen, reaktive Dashboard-/Bibliotheksänderung,
  Minutenfreiheit in Text und Semantik.
- Gezieltes Flutter Analyze für die drei Anwendungsdateien und den Test:
  „No issues found“.
- GitNexus CLI mit `--repo .` auf diesem Checkout: Dashboard LOW, 2 direkte
  Aufrufer, 6 betroffene Symbole. Regelkarte LOW. Bibliothek enthält doppelte
  Index-Symbole, deshalb tatsächliche Imports und Unterklassen zusätzlich im
  Quelltext geprüft. Kein Commit durchgeführt.

Audio- und Abschlusskartenänderungen sind während dieses Eintrags in Bearbeitung.
Generierung, Bilder und Lückentexte sind noch nicht implementiert. Keine
Geräteinstallation oder vollständige visuelle Freigabe aus diesen Tests ableiten.

## Technische Anschlussstellen für Generierung (gelesen, noch nicht geändert)

`PersonalLearningService` unterstützt derzeit ein explizites Story-Wort pro
Aufruf mit Identitätsprüfung, serverseitigem Erstellungs-Claim und unverändertem
SRS. `create-learning-card` ist der bestehende authentifizierte Edge-Einstieg.
Die neue Themen-Generierung benötigt einen eigenen begrenzten Anfragevertrag,
privaten Ergebnis-/Versuchsstatus und eine Auswahl vor dem dauerhaften Speichern.
Sie darf nicht als 50 automatische Story-Add-Aufrufe samt 50 Einzelgenerierungen
gebaut werden. Eine neue Sammlung braucht echte Herkunft und Mitgliedschaft,
statt die erzeugten Inhalte fälschlich „Aus Storys“ zuzuordnen.

### Zusätzlicher Befund zur Sprachabdeckung

`AppShell.build` blendet den gesamten Inhalte-Tab für `!hasEnglishSamples` aus.
Die vorhandenen Lückentexte kommen ausschließlich aus `sampleExerciseTexts` in
`lib/models/sample_content.dart` (fünf englische Texte). `ExerciseText` besitzt
noch kein Sprachfeld und `TextExerciseScreen.open` übernimmt dadurch den
englischen Standard. Vollständige Erfüllung von Punkt 9 benötigt echte
sprachgebundene Inhaltsdaten und die Freischaltung des Tabs, nicht bloß Tests
von gemeinsamen Widgets mit verschiedenen Sprachkennungen. Dieser Befund
bleibt offen und darf nicht als bereits gelöste Mehrsprachigkeit berichtet werden.

### Audio-Zwischenstand

Hörübungen verwenden jetzt einen alleinstehenden 72px-Play/Pause-Knopf ohne
Zeitspur oder Kartenkasten. Grammatik zeigt den Vorleseknopf erst nach der
korrekten Antwort oben rechts am Satz und liest die eingesetzte Antwort.
Sechs neue Tests bestanden, darunter echte Aufrufdaten der gemockten Geräte-TTS
für alle fünf Sprachkennungen. Zwei vorhandene Listening-/Grammar-Widgettests
bestanden nach Anpassung der veralteten Zeitspur-Erwartung. Die vollständige
gestalterische Angleichung der Antwort-/Lückendarstellung bleibt noch offen.

Die 6 vorhandenen Dashboard-/Bibliotheks-Regressionstests bestanden ebenfalls.
Die mehrsprachigen Widgettests beweisen die gemeinsame Mechanik, nicht die
noch fehlende Freischaltung der Inhaltsdaten in den anderen Sprachen.

### Abschlusskarten-Zwischenstand

Überschrift entfernt. Sichtbare Stapeltiefe auf zwei rückwärtige Karten
begrenzt, ältere Karten werden beim Weiterblättern ausgeblendet und beim
Zurückscrollen wieder sichtbar. Vorderste/letzte Karte bleibt voll lesbar.
Schatten verkleinert, oberer Freiraum vergrößert, Layout-Anker über Rebuilds
stabil gehalten. Sechs gezielte Tests bestanden (darunter 30-Karten-Stapel,
Rückwärtszugriff, reduzierte Bewegung, große Schrift). Analyze ohne Befunde.

Ein vorhandener End-to-End-Test in `test/practice_completion_test.dart:260`
scheitert vor dem Abschlussbildschirm: nach „walks“ fehlt „Weiter“. Identischer
Fehler gegen unverändertes HEAD in einem isolierten git-archive-Checkout
reproduziert. Kein grüner Gesamttest behauptet. Visuelle Stichprobe unter
`/tmp/completion-refined.png` nur mit Flutter-Testschrift Ahem: Ebenen und
Schatten geprüft, reale Typografie/Gerätegrößen noch nicht vollständig abgenommen.

Aktueller gezielter Umfang: 51 bestandene Tests (31 Reihenfolge + 6 bestehende
Dashboard/Bibliothek + 6 Audio + 2 bestehende Audio + 6 Abschluss). Ein
vorbestehender Integrationstest bleibt rot. Git-Diff-Prüfung unter Anerkennung
der vorhandenen CRLF-Dateien ist sauber. Kein Deployment/Commit erfolgt.

### Nutzerpriorität: Bilder zuletzt

Der Nutzer wünscht ausdrücklich zuerst ALLE Funktionen und UI-Änderungen ohne
weitere Bildgenerierung, um Usage zu sparen. Erst danach weitere Cover erzeugen.
Der ERSTE Raketenstil wurde ausdrücklich bevorzugt: malerische 2D-Illustration
mit Siebdruckstruktur, detailreicher See und Wolken, ruhiger dunkelblauer Palette
und warmen Akzenten. Gesicherte Referenz:
`docs/design-assets/story-cover-reference/rocket-preferred.png`. Die zweite,
stärker vereinfachte Variante ist nicht die Stilvorlage. Beide Generierungen
sind beendet; keine weitere Bildgenerierung gestartet. Noch keine Cover in
den App-Assets oder im Story-Provider eingebunden.

### Lückentext-Zwischenstand

Orange Fortschrittsanzeige statt sichtbarem Zahlenzähler; zugänglicher Zähler
bleibt im Semantiklabel. Überflüssige Kategoriezeile entfernt. Eingabelücken
und Auswahlplatzhalter mit runden Flächen, Fokusrahmen, Fehlerzustand.
Die fünf vorhandenen englischen Texte wurden bei stabilen IDs und erhaltenen
Originalsätzen auf 91/29/79/52/39 Wörter erweitert (vorher 46/15/41/27/20).
Alle neuen Sätze besitzen Offline-Übersetzungen. 3 Inhaltstests plus 6 neue
UI-Tests und 5 bestehende Lückentexttests bestehen; Analyze ohne Befunde.
320/820 px mit 2x Textskalierung geprüft. Sprachdatensätze/Tabfreischaltung
außer Englisch bleiben offen.

### Generierung: Vertrag, Server, Client und lokale Speicherung

Neue Dateien: `lib/domain/generated_vocabulary.dart`,
`lib/domain/generated_vocabulary_repository.dart`,
`lib/data/generated_vocabulary_client.dart`,
`lib/data/user/generated_vocabulary_store.dart`,
`supabase/functions/_shared/generated_vocabulary{,_contract}.ts`,
`supabase/functions/generate-vocabulary/index.ts` und Migration
`20261031000004_generated_vocabulary.sql`.

- Strikter Vertrag: 5 Sprachen, 1–50 Einträge, 400 UTF-16-Zeichen / höchstens
  zwei Eingabesätze, exakt gebundene UUID/Sprache, Einzelwort mit geprüftem
  UTF-16-Offset, 3–40 Wörter je Beispielsatz, deutsche Hinweise ohne Lösung.
- Ein Anthropic-Aufruf pro Anfrage; serverseitiges Modell unverändert Haiku 5.5.
  Keine automatische Wiederholung und kein neuer Provider-Aufruf bei Statusabfrage.
  Serverseitige private UUID-Zuordnung überlebt Fehler und abgelaufene Ergebnisse.
- Anfängliche Schutzgrenzen: 5 Anfragen / 250 angeforderte Einträge pro Konto in
  rollierenden 24 Stunden, global 20.000 angeforderte Einträge in 24 Stunden.
  Fehlgeschlagene/abgebrochene Versuche reservieren konservativ mit; keine
  Vermischung mit Übersetzungs- oder Aboquoten. Ein laufender Auftrag pro Konto.
- Kein Prompt in der DB, nur Hash und Ergebnis. Ergebnisse älter als 30 Tage
  werden **opportunistisch beim nächsten Claim** entfernt; keine Garantie einer
  zeitgenauen 30-Tage-Löschung. Replay-Tombstones bleiben bis Kontolöschung.
- HTTP-Client mit vorhandener Konto-/KI-Freigabe, erneuten Prüfungen nach awaits,
  120-Sekunden-Grenze, HTTPS, ohne Redirects, begrenztem Response-Body,
  festen Fehlermeldungen und ohne Provider-Key im Client.
- user.db auf Schema 8: zusätzliche sprachgebundene Mitgliedschaftstabelle.
  Generierte Karten haben Ursprung `deck`, eigene unveränderliche Kontexte und
  keine Story-Mitgliedschaft. Innerhalb der Sammlung wird dieselbe Wortform
  wiederverwendet, auch wenn eine spätere Modellantwort die Definition anders
  formuliert. Bestehende Karten/Reviews werden nicht überschrieben; deaktivierte
  oder zurückgestellte gleiche Wortformen werden nicht durch neue Karten umgangen.
  Keine ungeprüfte Bedeutungs-Zusammenführung mit redaktionellen Pack-Karten.
- Private Stapel-ID `personal:generated:<lang>`. Der Resolver kann die Sammlung
  bereits offline lesen und als neue Quelle auswählen. Erstes Speichern aktiviert
  sie, späteres Speichern überschreibt keine manuelle Deaktivierung.

Nachweise:
- 33 Flutter-Tests zusammen bestanden: 10 Vertrag, 7 HTTP-Client, 12 Store/Resolver,
  4 bestehende Migrationsfälle (v1–v4); zusätzlich v7→v8 im Store-Test enthalten.
- 19 Deno-Tests bestanden (10 Vertrag, 9 Server); Deno check sauber.
- Alle 7 SQL-Assertion-Gruppen erfolgreich auf separatem, wegwerfbarem
  PostgreSQL 17 Alpine ausgeführt (minimale Auth-/Rollenfixture, pgTAP-Ausgaben
  durch normale SELECTs ersetzt, sämtliche DO/ASSERT unverändert).
  **Keine vollständige Supabase-Migrationskette / kein Remote-Deployment getestet.**
  Container `sprachapp-generation-sql-check` danach gestoppt und automatisch gelöscht.
- Gezieltes Flutter analyze für Store/DB/Resolver sauber; Git-Diff-Whitespace sauber.
- Graph-Risiko im aktuellen Checkout: UserDatabase MEDIUM (4 direkt/56 insgesamt),
  DriftUserRepository HIGH (3 direkt/58 insgesamt, Warnung vor Änderung gegeben),
  Resolver LOW (4 direkt/26 insgesamt), _guardDecks LOW (2 direkt).
  `changes` UNKNOWN: dynamischer Caller `userChangesProvider` textuell bestätigt;
  Änderung ergänzt nur neue Tabelle in den beobachteten Tabellen.

Noch offen: Provider/Generierungs-UI/Auswahlscreen, private Deckanzeige in der
Stapelübersicht, Sitzungscontroller-Offlinefreigabe für den privaten Stapel,
Wortliste für neu gespeicherte Box-0-Einträge, Kontext-/Kontowechsel-Gesamttests,
Mehrsprachige Inhaltsdaten und noch offene Grammatikgestaltung. Erst anschließend
Bilder. Kein Live-Provider-Aufruf, kein Backend-Deployment, keine Appinstallation
in diesem Abschnitt. Umfang noch NICHT abgeschlossen.

### Gestaltungsbindung für Generierung

Direkte Umsetzung am bestehenden Designsystem (DESIGN.md, Figtree/Source Serif,
orange Pille und ruhige Flächen), ergänzt um die vom Nutzer gezeigte Jenzi-Abfolge
Eingabe → Wortauswahl → Stapel. Die Screenshots dienen nur für diese Abfolge und
abwählbare Wörter; Farbwelt/Comic-Maskottchen werden nicht übernommen.
Refero-Craft-Regeln für Formulare und Bewegung: sichtbare Eingabe, klare Labels,
Fehler am Feld, große Trefferflächen, reduzierte Bewegung ohne Schleifen.
Die ausdrücklich gewünschte Ladepille bleibt die einzige neue Daueranimation.

### Generierung: sichtbarer Ablauf und Lernsystem integriert

`TopicVocabularyComposer` über optionalen Dashboard-Slot im AppShell für alle
fünf Sprachen eingebunden. Direkte Eingabe oben, 10/25/50 Wörter, maximal
400 Zeichen / zwei Sätze, kurze Anthropic-Offenlegung, keine Dialogschleife.
Neue Ladepille: neutraler Start, orange geschätzte Füllung bis maximal 90 %,
3-Sekunden-Lichtsweep, erst bei erfolgreicher Antwort vollständig orange/Bereit.
250 ms Übergang zur Auswahl; reduzierte Bewegung ohne Warteschleife/Animation.
Fehler navigieren nicht weiter. Statusprüfung verwendet dieselbe Anfrage-ID;
auch ein Status-Miss behält sie für den expliziten erneuten Start. Eingabe ändern
ist nach ungewissem Ergebnis explizit möglich, niemals automatischer Neuversuch.

Auswahlscreen zeigt Wort, deutsche Bedeutung, Beispielsatz und Übersetzung,
Native-TTS-Knopf mit tatsächlicher Sprache, Abwahl, Erstellen/Hinzufügen-CTA.
Bereits in der Sammlung gespeicherte Wortformen sind gekennzeichnet und nicht
noch einmal ausgewählt. Speichern ist explizit, keine Writes durch Vorschau.
`GeneratedVocabularyService` hält Vorschau/Save an Konto-, Consent- und
Sprachrevision gebunden. Bei späterem Widerruf/Sprachwechsel wird nichts gespeichert.

Resolver, Deck-Provider, Wortliste und Sitzungscontroller angebunden:
Generierte Vokabeln erscheinen nach erstem Save in Stapeln; Box-0-Mitgliedschaften
in Wortliste sichtbar; eigenständiger aktiver/deaktivierbarer Stapel und gemischte
Neuwortquelle. Offline-Freigabe des Controllers auch für generierten Stapel.
Keine Story-Herkunftsbeschriftung für generierte Karten.

Nachweise dieser Etappe:
- 6 Ladebutton-Widgettests, 8 echte Composer-/Auswahlscreen-Tests bestanden,
  inklusive 320/820 px, 2× Schrift und reduzierter Bewegung.
- 5 neue Integrationstests (jede Sprache): realer SQLite-Save → sichtbarer Deck-
  Provider/Wortliste → tatsächlicher Sitzungscontroller/Antwort → gemeinsame
  SRS-Zähler → Datenbank schließen/neu öffnen. Content-Provider absichtlich
  nicht verfügbar: Offlinepfad geprüft. Aktivierung/Gemischt enthalten.
- Regressionlauf Store + Reihenfolge + bestehende Learningintegration +
  Storycollection: 61 Tests bestanden. Drift meldet in vorhandenen Storytests
  eine Debug-Warnung über mehrere ContentDatabase-Instanzen; keine Testfehler.
- Gezielte Analyze-Läufe ohne Befunde. Kein Deployment/Live-Provideraufruf
  oder Geräteinstallation. Sichtprüfung mit echten Schriftarten bleibt offen.
- Graph: Dashboard LOW, SessionController LOW. Deck-/Wortlisten-Provider UNKNOWN
  wegen dynamischer Riverpod-Referenzen; Caller textuell bestätigt (Home,
  Deckbibliothek/-details, Wortliste/-details). AppShell.build UNKNOWN als
  Framework-Lifecycle; tatsächlicher AppShell-Einstieg in main.dart bestätigt.

Weiterhin offen: vollständige Sprachdatensätze der sonstigen Inhalte, finale
Grammatikgestaltung, Rendering-/Gerätetest, Backendbereitstellung samt Liveprobe,
abschließende Gesamtabnahme. Erst danach die Coverbilder im ersten Raketenstil.


### Livebackend und Simulatorabnahme (Fortsetzung 31.10.)

Migration `20261031000004_generated_vocabulary.sql` remote erfolgreich angewandt;
Function `generate-vocabulary` bereitgestellt. Ausschließlich diese neue Function
und Migration betroffen. Die vorherige Aussage „kein Deployment“ beschreibt den
vorherigen Zwischenstand.

Echte synthetische Proben fanden zwei Modellfehler: unzutreffende selbstgezählte
UTF-16-Offsets und einzelne Form-/Satz-Abweichungen in größeren Listen. Der
Provider liefert nun acht Textfelder ohne Offset. Der Server bestimmt die erste
exakte, case-sensitive Ganzwortstelle. Alle übrigen strengen Prüfungen bleiben
bestehen. Aus einer begrenzten Providerliste werden nur vollständig validierte,
untereinander eindeutige Karten übernommen, höchstens die angefragte Zahl. Fehler-
hafte Einträge werden verworfen, niemals durch erfundene Inhalte repariert. Bei
keiner gültigen Karte scheitert die Anfrage. Die Auswahl nennt die tatsächliche
Anzahl. Keine kostenpflichtigen automatischen Nachgenerierungen. Der äußere
Wirevertrag bleibt unverändert. Ein Versuch mit JSON-Schema maxItems wurde vom
Provider abgewiesen und wieder entfernt.

23 Backend-/Vertragstests bestanden (`node --experimental-transform-types --test`),
inklusive astraler Zeichen, wiederholter Wörter, fehlender/substringleicher Wörter,
Teilbatchfilter, Duplikate, angefragtes Maximum und Status-Replay. Ein einzelnes
Wort live: HTTP200, 4,2s, identisches Status-Replay; temporäres Konto gelöscht200.
Fünfsprachige 50er-Liveprobe läuft noch; erste Ergebnisse en39/es49 Karten,
HTTP200 und identisches Replay. Alle Testkonten werden in finally gelöscht;
Schlüssel nur im Prozess, keine Inhalts- oder Tokenlogs.

UI-Tests erweitert: nun13 Composer-/Auswahltests bestanden, darunter gleiche UUID
nach Status-Miss sowie Konto-/Consentwechsel während Antwort und vor Save. Analyzer
ohne Befund. PRODUCT/backend/user-schema dokumentieren die neue ausdrückliche
Generierungsfreigabe und DB8; Übersetzungsbudgets unverändert.

Flutter-iOS-Simulatorbuild erfolgreich (Xcode32,6s). Device Hub zeigt reale Fonts,
Inhalte-Composer, dynamisch eingeblendeten orangen Button, Anmeldepflicht ohne
Modellaufruf und Lückentext mit gerundeten Feldern/semantischem Fortschritt ohne
sichtbare Zahlüberschrift. In der Sichtprüfung erschien der globale Lern-FAB über
der offenen Tastatur und verdeckte den KI-Hinweis. AppShell blendet ihn nun bei
viewInsets.bottom>0 aus. Regression erst rot, dann grün; Eingabe/Tab und Position
nach Schließen erhalten. Benachbarter FAB-Test ebenfalls bestanden. Erneuter
Simulatorbuild für diese letzte Korrektur und weitere Sprach-/Übungssichtprüfung
stehen noch aus. Bilder nach wie vor nicht begonnen.

Vorhandene historische Prüfberichte: docs/release-security-audit.md (30.10.,
Releasevorbehalte), docs/story-creation-contract-audit.md (25.10., frühere
Kartenerstellung; keine Abnahme der neuen Topic-Generierung).


Fünfsprachige Liveprobe abgeschlossen: angefragt je50, akzeptiert en39 (24,8s),
es49 (28,3s), it41 (26,8s), nb22 (28,3s), pt-BR50 (28,3s). Jede Antwort HTTP200,
jeder Statusabruf HTTP200 mit exakt identischem Resultat. Temporäres Testkonto
anschließend DELETE200. Weniger als50 ist ein validierter Teilstapel, keine Zusage
auf genau50; insbesondere cognate deutsche Hinweise können Kandidaten ausschließen.
Reale Inhaltsqualität bleibt KI-fehleranfällig und ist als solche in der Auswahl
zu prüfen; Strukturvalidierung ist keine sprachwissenschaftliche Abnahme.


### Bilderphase gestartet (01.11.)

Alle Nicht-Bildteile vorgezogen. Gemeinsamer Regressionlauf69/69 bestanden,
zusätzliche4 Sprachroutentests+Datentest5/5: AppShell→Inhalte→Textübung, echte
Offline-Übersetzungs-Callbacks für96 Sätze. Vollanalyse nur2 bestehende avoid_print
Infos in test/bundled_deck_mixing_test.dart:29 und test/data/baseline_adoption_pack_test.dart:43.
Simulatorneubuild mit Tastaturfix erfolgreich21,4s; letzte Sichtabnahme noch offen.
Release-/Securitynachtrag ohne Codefixes: docs/generated-vocabulary-release-security-addendum.md.

Inventar:44Motivbilder für220Storyvarianten. 65Alltag/Wirtschaft-Varianten sowie
zusätzlicheEN-Legacystory ausgenommen. 43neueBilder+bestehendeRakete(video_05).
Promptset docs/design-assets/story-cover-prompts.json, Quellen/IDs im Inventar.
Built-in image_gen mit bevorzugterRakete alsStilreferenz. Runtimeassets unter
assets/story_covers/, pubspec registriert. Aktuell16/44Bilder vorhanden, nächster
Promptindex15 (video_25). Ein sachlicherFehler bei video_23 wurde gezielt korrigiert:
historischesPiratenboot→modernesMotorboot. Keine zusätzlichenStilvarianten.

ZentraleStoryCover-Einbindung über expliziteID-Whitelist; contain-Vordergrund
bewahrt ganzesMotiv, dunklerCrop derselbenKunst fülltRänder, untererScrim92%schwarz.
Home/Stories/ContinueReading gemeinsam; News/TypeCover unverändert. 8Covertests
und3Nachbarchecks bestanden, Analyzer ohneBefund. Vollständigkeitsprüfung aller44
Assets, Endrendering, endgültigerBuild und WiFi-iPhoneinstallation folgen erst
nach dem restlichenBilderlauf. Noch keine fertigeGesamtabnahme.


### Abschließende Bild- und Buildprüfung (01.11.)

Alle 44 Motive liegen jetzt als Projektassets vor (43 neu generiert plus die
bevorzugte erste Rakete). Der vollständige Promptkatalog bleibt unter
docs/design-assets/story-cover-prompts.json erhalten. Gesamtgröße der PNGs
ca.118 MiB; keine zusätzlichen Stilvarianten erzeugt. Neun Covertests bestanden:
alle44 echten Manifestassets decodiert, alle220 Sprachzuordnungen sowie65
Alltag/Wirtschaft-Ausschlüsse und die zusätzliche Legacy-Alltagsstory geprüft.
Portrait160×220, breit340×128 und Tablet1024×196 erhalten das vollständige Motiv.
Gezielte Dart-Analyse ohne Befund; CRLF-bewusster git diff --check ohne Befund.

Simulatorbuild mit vollständigem Bildpaket erfolgreich (Xcode21,9s). Der Mac
war danach gesperrt, sodass die abschließende direkte CUA-Sichtprüfung nicht
möglich war. Kein Versuch, die Sperre zu umgehen. Releasebuild/Installation
auf dem weiterhin drahtlos erkannten iPhone von Claus gestartet. Ergebnis folgt.

Bestehende Einschränkung der Appfonts: Figtree und SourceSerif4 werden über
google_fonts zur Laufzeit bzw. aus dem Plattformcache geladen; im Repository
liegen keine gebündelten TTF/OTF-Dateien. Beim frischen Offline-Erststart ist
daher der Systemfontfallback möglich. Das wurde dokumentiert, nicht im Rahmen
der Coveränderung umgebaut. Die Testwarnung ist durch korrektes Vorladen des
Testbilds vor Widgetmount behoben, ohne Logfilter oder Fehlerunterdrückung.


### Letzter Layout- und Regressionstand

Gemeinsamer Lauf der Generierungs-UI, Buttonzustände, Offline-Lernintegration,
Tastatur-FAB, Audio, Lückentexte, Sprachrouten, Textdaten, Reihenfolge und Cover:
85/85 bestanden. Zusätzlicher Flutter-Renderexport zeigte zunächst harte Ränder
der enthaltenen Bildfläche. Diese wurden ohne neue Bildgenerierung durch
16%-Randüberblendung am tatsächlichen Bildrechteck geglättet. Hintergrund nur
noch35% abgedunkelt; Titelverlauf unverändert. Alle Hauptmotive bleiben enthalten,
auch bei externen nichtquadratischen ImageProvidern. Nach Änderung10/10
Covertests,1/1 Renderexport und gezielte Dart-Analyse ohne Befund.

Sichtgeprüfter Export: docs/design-assets/story-cover-render-check.png.
Er zeigt echte Flutter-StoryCover mit Rakete, Reise- und Arbeitsmotiv in drei
Formaten. Titeloverlays nutzen für diesen isolierten Export lokaleGeorgia;
dies ist keine vollständige Geräte-/App-Typografieabnahme. Der temporäre
Rendertest wurde anschließend entfernt.

Erster Releasebuild erfolgreich82,5s. Flutter meldete beim kombinierten
Installieren/Starten Fehler; der anschließende explizite devicectl-Install
bestätigte App installed für com.ardasayar.linglossa. Der separate Startversuch
scheiterte an Failed to allocate RSD device. Nach der letzten Randkorrektur
wird der Releasebuild nochmals erstellt und installiert; keine Deinstallation
und kein Löschen von Nutzerdaten.


### Lieferung auf das iPhone

Finaler iOS-Releasebuild nach Randüberblendung erfolgreich: Xcode35,6s,
Runner.app317,0MB. Alle44 Cover im gebauten App.framework geprüft und per
SHA-256 identisch mit den Projektassets. Explizite WLAN-Installation über
Apples devicectl bestätigt erneut `App installed`, Bundle
com.ardasayar.linglossa, Datenbanksequenz16740. Bestehende App aktualisiert;
keine Nutzerdaten gelöscht.

Alle angeforderten Funktions-/Inhalts-/Designänderungen sind umgesetzt und
gezielt verifiziert. Dies ist keine uneingeschränkte App-Store-Releasefreigabe:
Die vorhandenen Prüfberichte docs/release-security-audit.md und
docs/generated-vocabulary-release-security-addendum.md dokumentieren Risiken
und offene Nachweise ohne deren Behebung. Außerdem bestehen die schon vor
dieser Änderung reproduzierte Completion-Testabweichung und zwei avoid_print
Analyseinfos weiter. Die gezielten aktuellen Tests sind grün; eine grüne
Gesamtsuite wird nicht behauptet. Direkte Endbedienung am gesperrten Gerät und
Akustikprüfung aller TTS-Stimmen konnten nachts nicht erfolgen.

Letzter Startversuch nach erfolgreicher Installation: Apple meldet ausdrücklich
`Locked: Unable to launch ... because the device was not, or could not be,
unlocked`. Installation ist bestätigt; automatischer Start wegen Gerätesperre
nicht möglich. Nutzer kann die aktualisierte App nach Entsperren normal öffnen.
