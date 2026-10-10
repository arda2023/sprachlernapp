# Wiederholungssystem (SRS)

Quelle der Regeln: `PRODUCT.md`. Code: `lib/domain/` (Interface `SpacedRepetitionEngine`). Tabellen: `docs/user-schema.md`.

## Karte und Zustand

Eine Karte ist eine exakte Wortform in einer Bedeutung. Zustand je Karte in `user_cards`: `box` (0 = noch nie beantwortet, 1–5), `due_at`, `origin` (deck / story), `disabled`, `retired`, `created_at`.

Der Kartenzustand (`box`, `due_at`) ist ein **Cache**: Er lässt sich aus der Kartenerstellung und dem `review_log` rekonstruieren (letzte Zeile je Karte: `box_after`, `due_at_after`). Das ist die Grundlage für Sync.

## Intervalle

| Box | 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|
| Tage | 1 | 4 | 14 | 40 | 90 |

Standardwerte, einstellbar. Box 5 heißt "gemeistert".

**Fälligkeit nach Kalendertag:** `due_at` = Beginn des lokalen Tages (Antwortdatum + Intervall in Tagen), nicht Uhrzeit + Intervall. Beispiel: Antwort am 3.10. um 22:40 in Box 2 → fällig ab 7.10., 00:00 Ortszeit.

Jede Box-Änderung setzt `due_at` nach der neuen Box neu.

## Erstkontakt

Eine Karte entsteht bei der ersten Anzeige in einem Stapel oder per "Zum Lernen hinzufügen" (Box 0). Der erste Versuch entscheidet:

- richtig (ohne falschen Versuch, ohne "Wort erfahren") → Box 3; ein vorheriges "Fast richtig" ändert daran nichts
- sonst → Box 1

## Danach

- **Antwort sauber** (ohne Fehler, ohne "Wort erfahren"; ein vorheriges "Fast richtig" ist erlaubt, beschlossen 04.10.2026) → Box + 1 (höchstens 5), `due_at` nach neuer Box. Die Box wird nie allein aus `first_attempt_correct` abgeleitet.
- **Fehler** (falscher Versuch, falsche Form, "Wort erfahren") → Box 1, `due_at` nach Box 1.
- Geprüfte Synonyme sind neutrale erneute Versuche ohne Box-Nachteil. Historische `hint_used=true`-Reviews bleiben unverändert; der Scheduler versteht den alten Hilfeflag weiterhin, neue Synonymversuche setzen ihn nicht.
- "Fast richtig" ist kein Fehler.
- **Vorab-Üben** und **Stapel-Revue** (Karte nicht fällig): richtig → Box und `due_at` unverändert; Fehler → Box 1, `due_at` nach Box 1.

## Neutrale Synonymversuche (06.10.2026)

Ersetzt die frühere Hinweissanktion. Ausschließlich `valid_alternatives` des konkreten Karte-Satz-Lücken-Paares gilt; Gruppenmitgliedschaft gibt keine zusätzliche Antwort frei. Normalisierung und Prüfpriorität bleiben unverändert, vollständig lokal.

- Meldung: „Das passt auch. Gesucht ist hier ein anderes Wort. Versuch es noch einmal.“ Keine Fehlerfarbe/-vibration, kein Lösungspräfix und kein Aufdecken.
- Kein `error_count`, kein `hint_used`, kein Rücksetzen und keine In-Session-Wiederholung allein durch Synonyme. Abschluss weiterhin mit exakter Zielform (auch nach Aufdecken muss sie eingegeben werden).
- `first_attempt_correct`: erste **nicht neutrale** geprüfte Eingabe exakt. Synonym → exakt und Synonym → Synonym → exakt ergeben `true`, Box 3 beim Erstkontakt. Fast richtig → exakt ergibt weiter `false` ohne Box-Strafe. Bewertungsgrundlage bleiben Fehler/Aufdecken, nicht dieses Beobachtungsfeld allein.
- Falsch → Synonym → exakt behält den Fehler, `first_attempt_correct=false`, Box 1. Synonym → Aufdecken behält `revealed=true`, `hint_used=false`, Box 1.
- `hint_used` bleibt für neue Synonymversuche false. Historische Zeilen einschließlich echter alter Hilfeflags werden nicht verändert oder neu bewertet.
- Weitere neutrale Eingaben erzeugen keine Reviewzeile. Ein erfolgreicher Erstpass wird einmal gespeichert, Wiederholung und doppeltes Speichern derselben Pass-ID erzeugen keinen zweiten Review.

## In-Session-Wiederholung

Eine Karte mit Fehler oder Aufdecken kommt einmal wieder, etwa 3 Karten später. Die Box entscheidet allein der erste Durchgang; die Wiederholung ändert Box und `due_at` nicht und erzeugt keine eigene Zeile im `review_log`.

## Queue je Modus

Deaktivierte und retired Karten sind nie in einer Queue.

**Gemischt**
1. Fällige Karten aller Herkunft (`due_at ≤ jetzt`, älteste zuerst).
2. Neue Wörter bis zum Tagesziel: zuerst Story-Karten in Box 0 (älteste zuerst), danach neue Stapelwörter aktiver Stapel.
3. Weitere neue Wörter.
4. Vorab-Üben der als Nächstes fälligen Karten (`mode = early`).

Der Stapelschalter steuert nur neue Stapelwörter (Schritt 2 und 3); gesehene Karten werden immer wiederholt.

**Lerne mit diesem Stapel**: ausschließlich Primärkarten und deren feste Sätze dieses Stapels, nie reine Story-Karten, auch bei inaktivem Stapel. Reihenfolge: fällige Karten des Stapels, dann neue Wörter des Stapels.

**Stapel-Revue**: nur gesehene Primärkarten des Stapels (Box ≥ 1), als Vorab-Üben (richtig → unverändert, Fehler → Box 1).

## Abgeleitete Zähler

Nie gespeichert. Mit `A` = aktive Stapel, `C` = Karten mit `disabled = false` und `retired = false`, `now` = Abfragezeit. Formen werden **distinct über `card_id`** gezählt (eine Form in zwei aktiven Stapeln zählt einmal).

| Zähler | Definition |
|---|---|
| Noch nicht angezeigt | distinct `card_id` aus `deck_cards` von `A` ohne Zeile in `user_cards` **plus** Karten in `C` mit `box = 0`, die aktive Primärwörter oder belegte Story-Lernentscheidungen sind |
| Verfügbare Wiederholungen | Karten in `C` mit `box ≥ 1` und `due_at ≤ now` |
| Wörter gemeistert | Karten in `C` mit `box = 5` und `due_at > now` |
| Wörter im Aufbau | Karten in `C` mit `box` 1–4 und `due_at > now` |

Zuordnung in dieser Reihenfolge, damit die Zähler disjunkt sind. **Invariante:** Summe der vier = gelernte auflösbare Karten in `C` + zulässige Box-0-Karten + unbekannte Primärkarten aus `A`. Retired Karten zählen wie deaktivierte nirgends mit.

**Tagesziel** = Anzahl verschiedener `card_id` mit einer `review_log`-Zeile am heutigen lokalen Kalendertag. Der Streak entsteht ebenfalls aus `review_log`.

## review_log (nur anhängen)

Eine Zeile je Karte und Session, geschrieben nach dem ersten Durchgang der Karte. Keine Updates, keine Löschungen.

`hint_used` ist beschlossener Zielvertrag. Bestehende Zeilen erhalten bei der Migration den Standard `false`; Hinweise werden nicht nachträglich erfunden oder rekonstruiert.

| Spalte | Typ | Bedeutung |
|---|---|---|
| id | uuid | Zeilen-ID |
| card_id | text | stabile Karten-ID (Content-ID oder `u:`-ID) |
| created_at | timestamp | Zeitpunkt (UTC) |
| mode | text | `mixed`, `deck`, `revue`, `early` |
| sentence_id | text | gezeigter Satz (`sentences.id` oder `card_contexts.id`) |
| first_attempt_correct | bool | erste nicht neutrale geprüfte Eingabe exakt (Synonyme übersprungen; "Fast richtig", dann exakt → `false`; Box-Regel davon unabhängig) |
| error_count | int | falsche Versuche im ersten Durchgang |
| revealed | bool | "Wort erfahren" benutzt |
| hint_used | bool | historischer Hilfeflag; neue neutrale Synonyme setzen ihn nicht; Standard `false` |
| box_before | int | Box vor der Antwort (0–5) |
| box_after | int | Box nach der Antwort (1–5) |
| due_at_after | timestamp | neue Fälligkeit |
| response_ms | int | Millisekunden bis zur ersten Antwort |
| app_version | text | App-Version |
| device_id | text | Gerät |

## Bestätigte Regeln (früher Annahmen)

- Karte in Box 0 (aus Story, noch nie beantwortet) zählt als "Noch nicht angezeigt". ✔
- Tagesziel = verschiedene Karten mit `review_log`-Zeile heute. ✔
- `mode = early` kennzeichnet Vorab-Üben innerhalb von Gemischt (Box-Regel wie Revue). ✔
- Eine `review_log`-Zeile je Karte und Session; die In-Session-Wiederholung wird nicht geloggt. ✔
- Geprüfte Alternative → neutraler erneuter Versuch; sauberer Erstkontakt nach Zielform Box 3, echte Fehler/Aufdecken bleiben wirksam (06.10.2026). ✔

### Vielfalt bei der Einführung neuer Karten (2026-10-04)

Fällige Reviews bleiben zuerst und unverändert. Nur freie neue Plätze verwenden
vier Inhaltswörter, danach höchstens ein Funktionswort. Innerhalb jeder Gruppe
bleibt die bestehende Relevanzreihenfolge erhalten; nie angezeigte Lemmas kommen
vor bereits angezeigten. Je Sitzung höchstens eine neue Karte je normalisiertem
Lemma und je normalisierter Oberfläche, auch über unterschiedliche POS hinweg.
Reichen Inhaltswörter nicht, wird die Sitzung kürzer: höchstens ein Funktionswort
pro vier Inhaltswörtern, mindestens ein verfügbarer Funktionswort-Platz bei einem
kleinen/reinen Funktionswortbestand. Keine Wiederauffüllung mit Nebenbedeutungen.
Die Begrenzung bedeutet begrenzte aktuelle Auswahl, nicht abgeschlossene Sprache.
NOUN, lexikalische VERB, ADJ und bedeutungstragende ADV sind Inhaltswörter.
Artikel, Pronomen, Präpositionen, Konjunktionen, Partikeln und AUX sind Funktion.
Sinnspezifische Grenzfälle stehen in `new_card_selection.dart`: z.B. have#muessen
und get#werden sind Funktion, be#befinden ist lexikalisch; keine Form-Blacklist.
Unbekannte ADV werden nach POS als Inhaltswort behandelt, unbekannte AUX als
Funktion. Neue Grenzfälle benötigen Bedeutungsdaten und eine explizite Zuordnung.
Deaktivierte/entfernte Karten bleiben gefiltert. Revue und In-Session-Wiederholung
ändern sich nicht. Direkter Start eines inaktiven Stapels bleibt wie bisher erlaubt.
Aktuell nutzt der echte Stapel-Lernmodus die gemeinsame Domain-Auswahl; noch nicht
migrierte Demo-Modi werden hierdurch nicht als echte Lernabläufe ausgewiesen.

### Lokaler Pack-Vergleich (04.10.2026)

Read-only-Diagnose mit der produktiven Auswahl: `tool/inspect_new_card_selection.dart`.
Windows PowerShell und macOS Terminal, ab Repository-Root (ohne Nutzerzustand):
`dart run tool/inspect_new_card_selection.dart assets/content/en/content.sqlite`.
Optional folgen Pfad einer lokalen user.db-Kopie und ISO-Referenzzeit.
Kein Schreiben ins Pack oder in Lernstände; keine Live-Session-Telemetrie.

Aktueller Pack: 164 Karten, 60 Oberflächen, 52 normalisierte Lemmas (POS-übergreifend).
Getrennte Ursachen:
- 53 Oberflächen mit mehreren Bedeutungen, insgesamt 104 zusätzliche Bedeutungen.
- 5 Lemmas mit mehreren Formen, insgesamt 10 zusätzliche Formen. Überlappt die
  erste Kategorie und darf nicht mit ihr zu einer Wiederholungszahl addiert werden.
- Emulator-Snapshot vom 04.10.2026 15:12:28: 20 Lernstände, 19 Erstpass-Reviews,
  **0** aktive fällige Karten zum selben Zeitpunkt.
- 3 persistierte Erstpässe mit Fehler/Hinweis/Aufdecken. Tatsächlich ausgeführte
  In-Session-Wiederholungen werden absichtlich nicht protokolliert: ihre Anzahl
  ist daraus nicht rekonstruierbar. Neue Queue enthält 0 Wiederholungsdurchgänge;
  kontrolliertes Fehlerbeispiel fügt genau 1 hinzu, ohne Wiederholungskette.

Snapshot-Queue vorher: you/du, it/es, it/unpersönlich, on/auf, on/zeitlich.
Danach: on/eingeschaltet (ADJ), have/besitzen (VERB), so/auf diese Weise (ADV),
can/Dose (NOUN), it/es (PRON). Gründe: neue Lemmas, eindeutige Oberflächen,
Rangfolge innerhalb der Inhalts-/Funktionsgruppe, 4:1-Mix.
Der Pack hat nur 38 Inhaltswortkarten und 126 Funktionswortkarten nach expliziter
Sinnzuordnung; mit Vielfalt bleiben maximal 20 neue Plätze (16+4) pro Sitzung.
Auch diese Auswahl besteht noch aus dem kleinen häufigkeitsbasierten Pilotbestand;
Alltagswörter aus dem neuen Los werden dadurch nicht vorgetäuscht.
Vollständige Vorher/Nachher-Zeilen mit Form, Lemma, Sense, Klasse und Grund:
`build/selection_queue_report.txt` (lokaler Nachweis, nicht versioniert).

## Anbindung Gemischt (04.10.2026)
Gemischt verwendet jetzt `buildMixedQueue` im gemeinsamen `DeckSessionController`: fällige aktive bekannte Karten aller Quellen, neue Karten aktivierter Stapel über den unveränderten `selectNewCards`, anschließend Vorab-Üben mit `mode=early`. Bereits gesehene Karten bleiben bei deaktiviertem Stapel erreichbar; deaktivierte/retirierte Karten entfallen. Wiederholungen verwenden weiterhin `withRepeat`, Antworten `ReviewPass` und Termine `scheduleReview`. Nicht annotierte Story-/News-Demos erzeugen keine Lernstände. Der oben dokumentierte Pilot-Snapshot bleibt ein historischer Vergleich, keine Aussage über das heutige 264-Karten-Pack.

## Ein-Satz-Vertrag und Altstände (Paket A, 04.10.2026)
`practiceSentence` ist fest; Schema 1 projiziert Position 1, Schema 2 hat genau einen aktiven Link auf Position 1. In-Session-Wiederholungen verwenden denselben Satz. `historicalSentence(cardId, sentenceId)` löst auch archivierte Links auf; Archivierung einer Verknüpfung ist keine Karten-Retirierung.
Direkte Stapelübungen und Revue enthalten ausschließlich Primärkarten. Gelernte Nebenbedeutungen bleiben in Gemischt fällig/vorab übbar und in der Wortliste. Bloß angezeigte Box-0-Nebenbedeutungen werden nicht fortgesetzt und nicht als neue verfügbare Wörter gezählt. Vorhandenes `origin=story` ist ein belegter Altvertrag; Paket B speichert zusätzlich separate explizite Add-Entscheidungen in Schema 4. Intervalle/Antwortregeln/Reviewbuchung unverändert.

### Paket B: gemeinsame auflösbare Lernmenge
`PracticeItemResolver` liefert kuratierte und vollständige lokale Karten. Zähler berücksichtigen nur diesen auflösbaren Bestand; fehlende alte IDs bleiben gespeichert und werden in der Wortliste als Inhaltsbefund ausgewiesen. Explizite Story-Box-0-Karten sind sofort „Ungelernt“ in der Wortliste; kein Tagesziel-/Wochenfortschritt ohne Review.
Gemischt reserviert nach fälligen Karten zuerst Slots für explizite Story-Box-0-Karten (älteste Entscheidung zuerst), dann automatische Primärwörter, zuletzt Vorab-Üben. Die 4:1-Auswahl betrifft nur automatische neue Karten und kann Story-Slots nicht verdrängen. Vielfalt bei neuen Karten gilt pro Sitzung; vorhandene Box-0-Zustände bleiben spätere Kandidaten. Gelernte unterschiedliche Bedeutungen werden nach Karten-ID getrennt behandelt.
Exakte Bindungen einer lokalen Karte an spätere Content-Entsprechungen verhindern einen zweiten automatischen Erstkontakt. Der lokale Stand kann einen Primärplatz als „über Story gelernt“ abdecken; Besitz/Deckgröße ändern sich nicht. Haben beide IDs bereits Zustände, bleiben beide erreichbar und der Konflikt sichtbar. Keine automatische Verschmelzung.

## Gruppenprojektion und Reihenfolge v1 (06.10.2026)
`LearningGroups.project` ist die gemeinsame Regel: genaue Gruppe der relevanten Primär-/Storykarte ermitteln; alle bereits gelernten Mitglieder erhalten, andernfalls ältesten vorhandenen Box-0-Stand (Zeitpunkt, dann ID) oder redaktionellen Kopf auswählen. Inaktive Zustände reservieren die Gruppe, erscheinen aber nicht in Queue/Zählern. Bereits gelernte mehrere Mitglieder behalten einzeln fällige Reviews und Revueplätze. Auch Kopf außerhalb des gewählten Stapels wird appweit wiederverwendet. Einzelne historische Nebenbedeutungen ohne explizite Gruppe bleiben getrennt.
Die vier Zähler verwenden diese Projektion nur für neue Ziele; die disjunkten Kategorien der gelernten Karten bleiben unverändert. Stapelfortschritt hat dieselbe abgeleitete Menge, keine gespeicherten Zähler. Die Wortliste erhält alle gelernten Zeilen und nur einen unbewerteten Gruppenvertreter; deaktivierte Zeilen bleiben dort bedienbar.
`selectNewCards` verwendet Themen und explizite Kontrasttags aus Content. Verwandt bedeutet gleiches Thema oder gemeinsames Kontrasttag. Drei andere neue Ziele dazwischen; falls kein Kandidat die Inhalts-/Funktionswortquote erfüllt, kontrolliert 2/1/0. Unbekannte Lemmas, stabile Eingangsreihenfolge und die bestehende 4:1-Regel bleiben; explizite Storyziele haben Vorrang innerhalb der Abstandsstufe. Jede Auswahl verbraucht einen Kandidaten; bei späteren Sessions rücken übrig gebliebene Wörter nach, ohne Zufallsneusortierung. Ein einmal aufgebauter Controller behält seine Session über Provider-Neuberechnungen. Reviews und In-Session-Wiederholungen unterliegen nicht dem Themenabstand.
Die vorherigen Paket-A/B-Abschnitte beschreiben den historischen Stand; für gruppierte Schema-3-Inhalte gelten die hier beschriebenen Ergänzungen. Quelle, Vorher/Nachher-Auswahl und Bestandsprüfungen: `docs/learning-groups-v1.md`.
