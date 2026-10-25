# Lernalgorithmus: Ist-Zustand und Vereinfachungsvorschlag · 25.10.2026

Nur Analyse. Der Bericht ändert keinen Scheduler, keine Fälligkeiten, Queues, Tageszielzählung oder Stapelverteilung und migriert keine Lernstände. Grundlage ist der produktive Code bei `682d92c`:
- `lib/domain/leitner.dart`, `srs_state.dart`, `new_card_selection.dart`, `review_pass.dart`, `review_activity.dart`
- `lib/presentation/practice/deck_session_controller.dart`
- `lib/data/learning/practice_item_resolver.dart`
- `lib/screens/decks/deck_practice_screen.dart`

Wo `PRODUCT.md`/`docs/srs.md` und Code übereinstimmen, steht keine gesonderte Anmerkung.

## So funktioniert es heute

**Eine Karte, ein Lernstand.** Jede Karte (eine Wortform in einer Bedeutung) hat genau einen Zustand: Box 0–5 und Fälligkeit. Alle Einstiege lesen und schreiben denselben Zustand: Play, „Lerne mit diesem Stapel“, Revue und „Aus Storys“. Synonyme Lerngruppen zeigen auf ein Ziel. Story-Adds verknüpfen vorhandene Karten, seit `682d92c` auch bei abweichender Groß-/Kleinschreibung.

**Abstände.** Box 1 → 1 Tag, Box 2 → 4, Box 3 → 14, Box 4 → 40, Box 5 → 90 Tage. Gerechnet wird ab Mitternacht des Antworttags; „1 Tag“ heißt also „ab dem nächsten Kalendertag“. Wer um 23:50 übt, hat die Karte um 0:00 wieder fällig.

**Bewertung des ersten Durchgangs einer Karte in einer Sitzung:**

| Ergebnis | Neue Karte (Box 0) | Fällige Wiederholung | Vorab-Üben / Revue |
|---|---|---|---|
| Sauber (auch „Fast richtig“ → exakt, Synonym → exakt) | Box 3 (14 Tage) | eine Box höher (max. 5) | Box und Datum bleiben |
| Fehler, falsche Form oder „Wort erfahren“ | Box 1 (morgen) | Box 1 (morgen) | Box 1 (morgen) |

- **Hinweis:** `hintUsed` ist im Code immer `false`. Kein Hinweis wirkt sich auf die Box aus. Die Abschlusstexte sagen trotzdem „Fehler, Hinweise und ‚Wort erfahren‘ führen zu Stufe 1“; das ist eine Textabweichung.
- **Wiederholung in der Sitzung:** Nach Fehler oder Aufdecken kommt die Karte einmal etwa 3 Karten später zurück. Diese Wiederholung wird nicht gewertet und ändert weder Box noch Datum. Ein wiederholter Fehler in derselben Sitzung ändert nichts mehr; entscheidend ist der erste Durchgang.

**Welches Wort kommt als Nächstes?** Beim Start einer Sitzung wird die Reihenfolge eingefroren:
1. **Fällige Wiederholungen** aller Herkünfte, auch aus deaktivierten Stapeln und Storys, am längsten überfällige zuerst.
2. **Neue Wörter**, solange Platz ist:
   - zuerst gespeicherte Story-Wörter, älteste zuerst;
   - dann Wörter aller aktiven Stapel als eine Liste in Stapelreihenfolge.
   - Der Auswahlfilter verlangt pro Sitzung verschiedene Lemmata, Formen und Lerngruppen. Er hält möglichst drei andere Themen Abstand (lockert auf 2, 1, 0) und nimmt höchstens ein Funktionswort pro vier Inhaltswörter.
   - Mehrere Stapel werden also nicht reihum gemischt. Es mischt sich über Themenabstand, bei Gleichstand gewinnt die Stapelreihenfolge.
3. **Vorab-Üben:** bereits gelernte, noch nicht fällige Karten, die nächstfälligen zuerst. Das geschieht nur, wenn 1 und 2 die Sitzung nicht füllen.

**Sitzungslänge und Tagesziel.**
- Das Tagesziel zählt **verschiedene Karten mit einem gewerteten Durchgang heute**: in Play, „Lerne mit diesem Stapel“ und Vorab-Üben, **nicht** in der Revue. Wiederholungen in der Sitzung zählen nicht; eine Karte zählt einmal.
- Play und „Lerne mit diesem Stapel“ dauern so lange wie der Rest des Tagesziels; heute schon geübte Karten werden ausgelassen.
- Ist das Ziel erreicht, zeigen beide eine leere Sitzung mit „Weiterlernen“. Das startet eine weitere Sitzung in Tageszielgröße mit derselben Reihenfolge (Play: fällig → neu → vorab; Stapel: fällig → neu), ohne Auslassungen.

**Die drei Einstiege:**
- **Play (Mitte):** alle Herkünfte, Reihenfolge wie oben.
- **Lerne mit diesem Stapel:** nur dieser Stapel (auch wenn er deaktiviert ist): fällige, dann neue Wörter. Keine Story-Priorität, kein Vorab. Zählt zum Tagesziel.
- **Revue:** nur bereits gesehene Karten des Stapels, nächstfällige zuerst, Sitzung in Tageszielgröße. Vorab-Regel: richtig ändert nichts, Fehler → Box 1. Zählt **nicht** zum Tagesziel.

**Aktiv und deaktiviert.**
- Der Stapelschalter steuert nur, ob **neue** Wörter des Stapels eingeführt werden.
- Bereits gelernte Wörter eines deaktivierten Stapels werden weiter wiederholt und gezählt.
- Ungesehene Wörter eines deaktivierten Stapels verschwinden aus „Noch nicht geübt“ und erscheinen wieder, sobald der Stapel aktiv ist.
- Eine einzeln deaktivierte Karte fehlt überall.

## Beispiele

1. **Zwei aktive Stapel, Ziel 10, 7 fällig.** Play: 7 fällige (älteste zuerst), danach 3 neue. Gespeicherte Story-Wörter haben Vorrang, dann Stapelwörter nach Themenabstand. Gibt es weniger als 3 neue, füllt Vorab-Üben auf. Nach 10 gezählten Karten ist das Ziel erreicht.
2. **Zwei aktive Stapel, Ziel 10, mindestens 20 fällig.** Play: die 10 ältesten fälligen, **keine** neuen. „Weiterlernen“: die nächsten 10 fälligen. Neue Wörter erscheinen erst in einer Sitzung, in der weniger als 10 fällig sind.
3. **Nichts fällig, neue Stapel- und Story-Wörter.** Play: bis zu 10 neue, gespeicherte Story-Wörter zuerst. Saubere erste Antwort → 14 Tage Pause; Fehler → morgen plus eine Wiederholung in der Sitzung. Fehlen Neue, ist der Rest Vorab-Üben.
4. **Gelernter Stapel wird deaktiviert.** Seine gelernten Wörter bleiben in Wiederholungen und Zählern, neue Wörter des Stapels kommen nicht mehr. Wer auch die Wiederholungen nicht will, muss Wörter einzeln deaktivieren.
5. **Erst Stapel direkt lernen, dann Play.** „Lerne mit diesem Stapel“ übt bis zum Rest des Tagesziels, mit denselben Box-Regeln wie Play. Play lässt danach alle heute geübten Karten aus. Ist das Ziel schon erreicht, bietet es nur „Weiterlernen“ an. Die Lernstände sind dieselben; nichts wird doppelt angelegt.

## Bewertung

**Wirklich nötig:**
- ein Lernstand je Karte;
- abgeleitete Zähler;
- Vorrang fälliger Wiederholungen;
- eine feste Übungsstelle je Karte;
- Wiederholung nach Fehlern in der Sitzung;
- Leitner mit wachsenden Abständen.

Das ist verständlich und schützt Lernstände und Historie.

**Entbehrliche Komplexität (intern):**
- Drei getrennte Warteschlangen-Funktionen (`buildMixedQueue`, `buildDeckQueue` learn/revue), dazu im Controller ein Größen-Aufschlag mit nachträglichem Ausfiltern bereits geübter Karten und eigene Sonderfälle („beyondGoal“, `sessionSize -1`).
- Zwei Eignungsberechnungen für dieselbe Menge: Zähler (`eligiblePracticeIds`) und Warteschlange (`states` + `cards`).
- `targetsResolved`-Schalter in mehreren Funktionen.

**Überraschend oder pädagogisch fragwürdig (begründete Einschätzung):**
1. **Vorab-Üben steckt still in der normalen Play-Sitzung**, sobald neue Wörter fehlen. Dort bringt eine richtige Antwort nichts, ein Fehler setzt aber auf Box 1 zurück. Wer das nicht bewusst gewählt hat, verliert eher.
2. **Uneinheitliches Tagesziel:** Vorab-Üben zählt, Revue nicht, obwohl beide dieselbe Regel haben. „10 Wörter am Tag“ im Onboarding klingt nach neuen Wörtern, gezählt werden aber alle geübten.
3. **Ein Fehler in Box 4/5 führt direkt auf Box 1.** Monate Fortschritt sind nach einem Flüchtigkeitsfehler weg.
4. **Erster sauberer Durchgang = 14 Tage.** Bei echter Vorkenntnis ist das sinnvoll; bei geratenen Kognaten (*hotel*) unkritisch; bei Zufallstreffern eher lang. Ob das ein Problem ist, lässt sich aus `review_log` messen und sollte nicht geraten werden.
5. **Großer Rückstand stoppt neue Wörter vollständig.** Das ist konsequent, kann aber nach Pausen demotivieren.
6. **Mehrere aktive Stapel:** Für Nutzer ist nicht vorhersagbar, welcher Stapel wie viele neue Wörter liefert.
7. **„1 Tag“ bedeutet nächster Kalendertag**, nicht 24 Stunden.

## Empfohlenes Zielmodell: ein Pool, eine Reihenfolge, ein Tageszähler

1. **Eine Reihenfolge überall:** fällig (am längsten überfällig zuerst) → neu (gespeicherte Story-Wörter zuerst, dann aktive Stapel) → sonst nichts. Der Einstieg bestimmt nur die Menge: Play = alles, Stapel = nur dieser Stapel, „Aus Storys“ = nur Story-Wörter.
2. **Vorab-Üben nur ausdrücklich:** Ist nichts fällig und nichts neu, endet die Sitzung mit „Heute ist alles geübt“ und einem Knopf „Vorab üben“. Die Revue ist der stapelbezogene Vorab-Einstieg.
3. **Tagesziel = heute geübte Wörter**, jede Karte einmal, über jeden Einstieg, Revue und Vorab eingeschlossen. Angezeigt wird „7 von 10 Wörtern geübt“. Das Ziel bleibt eine Empfehlung; danach setzt „Weiter üben“ dieselbe Reihenfolge fort. Den Vorrang der Wiederholungen sichert die Reihenfolge, nicht die Zählweise.
4. **Bewertung vorerst unverändert:** Leitner 1/4/14/40/90 Tage, erster sauberer Durchgang Box 3, Fehler oder Aufdecken Box 1, eine Wiederholung in der Sitzung ohne Wertung. Änderungen (erster Durchgang Box 2, sanftere Rückstufung aus Box 4/5) erst nach Auswertung vorhandener `review_log`-Daten, zum Beispiel: Wie oft scheitern Box-3-Erstkontakte bei ihrer ersten 14-Tage-Wiederholung im Vergleich zu regulär aufgestiegenen Box-3-Karten? Die früher vorgeschlagenen 4 Tage übernehme ich deshalb nicht ungeprüft.
5. **Deaktivieren:** Stapel → keine neuen Wörter, Gelerntes wird weiter wiederholt (wie heute, aber in der Oberfläche erklärt); Wort → nirgends.

| Heute | Empfehlung | Nutzen / Nachteil | Art |
|---|---|---|---|
| Vorab-Üben füllt Play still auf | nur ausdrücklich nach „Heute ist alles geübt“ | keine ungewollten Rückstufungen, klares Ende / an leeren Tagen ein Tipp mehr | sichtbar |
| Vorab zählt, Revue nicht | alles Geübte zählt einmal | eine Regel statt Ausnahme / Ziel auch ohne fällige Arbeit erreichbar (Reihenfolge priorisiert weiterhin Fälliges) | sichtbar |
| „Hinweise führen zu Stufe 1“ im Text | Text an Code angleichen | Vertrauen in die Anzeige / keiner | sichtbar (nur Text) |
| drei Queue-Funktionen, Größenaufschlag, Sonderfälle | eine Funktion mit Mengenfilter und Ausschlussliste | weniger Fehlerquellen, gleiche Regeln je Einstieg / Testumbau | intern |
| zwei Eignungsberechnungen | eine gemeinsame | Zähler und Queue können nicht auseinanderlaufen / Testumbau | intern |
| Intervalle und Box 3 beim Erstkontakt | unverändert, erst messen | keine Lernstandsänderung / Fragen 3–4 bleiben vorerst offen | – |

**Größter Nutzen bei kleinstem Umbau:** Vorab-Üben aus der Play-Sitzung nehmen und das Tagesziel einheitlich zählen. Beides betrifft nur Warteschlangenaufbau und Zählung, keine gespeicherten Daten und keine Fälligkeiten.

**Mögliche spätere Umsetzung (2 Schritte):**
1. **Sichtbar:** Play ohne stilles Vorab-Üben; Zählung und Texte („x von y Wörtern geübt“, Hinweis-Text) vereinheitlichen; Tests der Beispiele 1–5 als Regressionen.
2. **Intern:** eine Warteschlangenfunktion mit Filter (alle / Stapel / Story / Revue) und expliziter Ausschlussliste; eine gemeinsame Eignungsfunktion für Zähler und Queue. Keine Datenmigration; Historie und Lernstände bleiben unverändert.

## Belegte Aussagen und Einschätzungen

Belegt (Primärquellen):
- **Abruf statt Wiederlesen:** Abrufübungen stärken das Behalten deutlich mehr als erneutes Lesen. Roediger & Karpicke (2006), *Test-enhanced learning*, Psychological Science 17(3), 249–255. Das stützt Eintippen statt Wiedererkennen und auch das Zählen von Vorab-/Revue-Abrufen als Übung.
- **Verteilt statt geballt:** Verteiltes Üben schlägt geballtes; der günstige Abstand wächst mit der gewünschten Behaltensdauer. Cepeda, Pashler, Vul, Wixted & Rohrer (2006), Psychological Bulletin 132(3), 354–380; Cepeda, Vul, Rohrer, Wixted & Pashler (2008), Psychological Science 19(11), 1095–1102. Das stützt wachsende Abstände allgemein, aber nicht die konkreten 1/4/14/40/90 Tage.
- **Wachsende vs. gleiche Abstände:** Expandierende Abstände sind für langfristiges Behalten nicht überlegen. Karpicke & Roediger (2007), Journal of Experimental Psychology: Learning, Memory, and Cognition 33(4), 704–719. Daraus folgt: Die genaue Intervallfolge ist weniger entscheidend als regelmäßiges verteiltes Abrufen; eine neue SRS-Engine oder FSRS ist dafür keine Voraussetzung.

Einschätzung (nicht belegt): die Bewertung der Punkte 1–7, der Nutzen eines einheitlichen Tageszählers und die vorgeschlagene Messung vor jeder Intervalländerung.
