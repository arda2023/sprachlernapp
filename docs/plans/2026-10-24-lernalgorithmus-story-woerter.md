# Lernalgorithmus, Story-Wörter und Stapel: Analyse und Zielkonzept

Stand: 24.10.2026. Auf ausdrücklichen Wunsch zunächst Analyse und konkreter Aufbau, keine Umsetzung der größeren Lernlogik. Die Tooltip-Beschriftungen „im Text: …“ und „Deutsch“ wurden bereits entfernt.

## 1. Entscheidung

**Ein gemeinsames Wiederholungssystem beibehalten. Fällige Wiederholungen haben Vorrang. Neue Wörter werden über aktive Themen fair verteilt. Story-Wörter erhalten eine automatisch entstehende Sammlung „Aus Storys“, aber keine kopierten Lernstände. Keine harte Obergrenze aktiver Stapel. KI erzeugt nur dann einen neuen Übungskontext, wenn wirklich keiner vorhanden und die Identität des Wortes ausreichend geklärt ist.**

Das ist eine Weiterentwicklung der vorhandenen Architektur. Es braucht weder einen zweiten Scheduler für Storys noch einen als „Lingvist-Algorithmus“ bezeichneten Nachbau unbekannter interner Regeln.

## 2. Warum einige Story-Wörter momentan nicht lernbar erscheinen

### Was der Screenshot tatsächlich zeigt

Bei „arrives“ stehen zwei Meldungen: fehlende geprüfte Lernreferenzen und „Storydaten konnten nicht geladen werden“. Die zweite Meldung stammt aus einem allgemeinen Fehlerfang in `StoryReaderScreen._lookUp`. Dieser umfasst nicht nur die Auflösung des Wortes, sondern auch Statusabfrage, Popover-Ablauf und anschließende Statusabfrage.

Daraus folgt: Der Screenshot beweist **nicht**, dass ein Beispielsatz fehlt. Eine Ausnahme in einem dieser Schritte kann dieselbe Meldung auslösen. Die zusätzliche allgemeine Referenzmeldung wird gezeigt, weil der Fehlerpfad `learningAvailable: false` setzt. Sie ist in diesem Fall keine unabhängige Diagnose.

### Tatsächlich geprüft

Das lokale Paket `published-baseline-transfer/content.sqlite` wurde mit dem echten `DriftContentRepository` gelesen. Anschließend wurden die Wörter mit dem echten `DriftUserRepository` in einer leeren In-Memory-Testdatenbank hinzugefügt. Kein bestehender Lernstand wurde verändert.

```text
arrives: AVAILABLE; status=StoryAddState.available; add=StoryAddState.added
early: AVAILABLE; status=StoryAddState.available; add=StoryAddState.added
pocket: AVAILABLE; status=StoryAddState.available; add=StoryAddState.added
safely: AVAILABLE; status=StoryAddState.available; add=StoryAddState.added
00:03 +1: All tests passed!
```

Für „arrives“ ist bereits dieser vollständige Übungskontext vorhanden:

- Englisch: **Maya arrives at the station early.**
- Deutsch: **Maya kommt früh am Bahnhof an.**
- Exakte Zielform: **arrives**, Bedeutung ankommen.

Es wäre hier unnötig, einen anderen Satz zu generieren. „pocket“ kann eine bereits vorhandene Karte wiederverwenden; ein Wort ohne passende Contentkarte kann dagegen als lokale Karte mit geprüftem Story-Kontext angelegt werden. Diese beiden Wege sind bereits vorhanden.

**Grenze der Diagnose:** Der Inhalt und die Benutzerdaten auf dem iPhone wurden in dieser Untersuchung nicht ausgelesen. Der Fehler lässt sich mit dem lokalen Paket und leerem Lernstand nicht reproduzieren. Ein anderer installierter Paketstand, ein bestehender lokaler Lernstand oder ein Lebenszyklus-/Providerfehler bleiben mögliche Ursachen, keine bewiesenen Ursachen.

### Nächster technischer Diagnoseschritt bei der Umsetzung

1. Appversion, Paketversion und Sprachkontext des betroffenen Geräts erfassen.
2. Den Tap auf „arrives“ dort reproduzieren; Fehlerstufe unterscheiden: Kandidat, Lernstatus, Popover oder Nachabfrage.
3. Strukturierte Diagnose mit Story-/Satz-/Token-ID und Exception-Typ, ohne private Textinhalte oder Schlüssel.
4. Den tatsächlich fehlschlagenden Fall mit dem betroffenen Schema beziehungsweise anonymisierten notwendigen Zustand als Regressionstest nachstellen.
5. Technische Ladefehler mit „Erneut versuchen“ behandeln. Nur ein nachgewiesen fehlender Kontext darf zur KI-Erstellung führen.

Ein KI-Fallback darf weder Datenbankfehler verschleiern noch eine deaktivierte Karte durch eine neue Kopie umgehen.

### Weitere echte Sperrgründe im heutigen Code

- Eigennamen ohne bestehendes Lernziel.
- Fehlende oder mehrdeutige Bedeutung/Übersetzung.
- Wortposition passt nicht zum gespeicherten Satz.
- Fehlende oder widersprüchliche Formfunktion bei einer Formkarte.
- Kartenreferenz gehört zu einer anderen Form oder Bedeutung.
- Zurückgezogene Karte.
- Fehlender geprüfter Kontext bei einer neuen lokalen Karte.
- Konflikt zwischen bereits existierenden lokalen und redaktionellen Lernständen.

Diese Gründe dürfen nicht alle zu „KI erzeugt irgendeinen Satz“ zusammengefasst werden.

## 3. So funktioniert dein Algorithmus heute

### 3.1 Was eine Lernkarte ist

Eine Karte bezeichnet eine konkrete Wortform in einer konkreten Bedeutung; bei Formübungen zusätzlich die belegte grammatische Funktion. Zwei gleich geschriebene Wörter mit unterschiedlichen Bedeutungen sind nicht automatisch dieselbe Karte. Mehrere Ansichten derselben Karte teilen sich dagegen denselben Lernstand.

Es gibt Gruppen und lexikalische Zuordnungen, um bei neuen Einführungen unnötige Doppelungen zu vermeiden. Bereits gelernte unterschiedliche Formen behalten ihre eigenen Wiederholungen. Ein Verb bekommt also nicht eine gemeinsame Gedächtnisstufe für sämtliche Formen.

### 3.2 Der Scheduler ist Leitner, keine gelernte Vergessenskurve

| Stufe | Nächste Wiederholung |
| --- | --- |
| Box 0 | Noch nicht beantwortet |
| Box 1 | Nach 1 Tag |
| Box 2 | Nach 4 Tagen |
| Box 3 | Nach 14 Tagen |
| Box 4 | Nach 40 Tagen |
| Box 5 | Nach 90 Tagen |

Die Fälligkeit liegt am Beginn des jeweiligen lokalen Kalendertages, nicht exakt 24 Stunden nach der letzten Antwort.

Aktuell gilt:

- Beim allerersten sauberen Durchgang springt die Karte direkt von Box 0 nach **Box 3**, also auf 14 Tage.
- Ein echter Fehler oder „Wort erfahren“ setzt sie auf **Box 1**, also auf morgen.
- Später erhöht ein sauberer regulärer Durchgang die Box um eins, höchstens auf Box 5.
- „Fast richtig“ gilt nicht als Fehler für die Box. Geprüfte Synonyme sind neutrale neue Versuche; zum Abschluss muss trotzdem die konkrete Zielform eingegeben werden.
- Sauberes Vorab-Üben und saubere Stapel-Revue lassen Box und Fälligkeit unverändert. Fehler setzen auch dort auf Box 1 zurück.
- Box 5 bedeutet eine lange Wiederholungsstufe, keine Garantie, dass ein Wort dauerhaft beherrscht wird.

Die Antwortzeit wird protokolliert, beeinflusst die Terminberechnung aber derzeit nicht. Wortlänge, persönliche Vergessenswahrscheinlichkeit und die Leistung anderer Nutzer sind ebenfalls keine Eingaben dieses Schedulers. Es gibt keine KI-Bewertung der Antworten.

### 3.3 Fehlerwiederholung in derselben Sitzung

Ein Wort mit Fehler oder aufgedeckter Lösung erscheint einmal zusätzlich, normalerweise nach drei anderen Karten; bei kurzer Restschlange am Ende. Die Wiederholung erzeugt keine weitere Wiederholungskette.

Nur der erste Durchgang verändert die Box und schreibt einen Review. Die zusätzliche Fehlerwiederholung zählt weder als neues Wort noch als zweiter Tageszielpunkt. Bei zehn unterschiedlichen Zielen und drei Fehlerwiederholungen kann man also **13 Aufgabenansichten, aber zehn Tageszielpunkte** erhalten.

### 3.4 Was „Tagesziel 10“ genau bedeutet

Es bedeutet zehn verschiedene abgeschlossene und gespeicherte Übungsziele am lokalen Tag innerhalb des jeweiligen Lernbestands. Wiederholungen und neue Ziele zählen. Unterschiedliche Formkarten können getrennt zählen, auch wenn sie umgangssprachlich zum selben Wort gehören.

Es bedeutet nicht zehn neue Wörter und nicht zehn Wörter je Stapel. Der verbleibende Tagesrest gilt gemeinsam über die regulären Stapel- und gemischten Sitzungen. Wenn morgens sechs Ziele abgeschlossen wurden, startet die nächste reguläre Sitzung mit höchstens vier weiteren noch nicht heute gezählten Zielen.

Revue zählt nicht zum Tagesziel. In-Session-Wiederholungen zählen nicht zusätzlich. Das bloße Hinzufügen eines Story-Wortes zählt ebenfalls noch nicht. Bei erreichtem Ziel ist weiteres Lernen bewusst möglich; das Ziel ist keine Sperre.

## 4. Play-Button und einzelner Stapel

| Frage | Mittlerer Play-Button | „Lerne mit diesem Stapel“ |
| --- | --- | --- |
| Welcher Modus? | Gemischt | Gewählter Stapel |
| Fällige Karten | Bereits gelernte, auflösbare Karten aller Herkunft | Nur Lernziele des gewählten Stapels |
| Neue Story-Karten | Ausdrücklich hinzugefügte Story-Ziele | Nicht automatisch; nur wenn dasselbe Ziel zum Stapel gehört |
| Neue Themenwörter | Aus aktiven Stapeln | Aus dem gewählten Stapel |
| Stapel muss aktiv sein? | Für automatische neue Themenwörter ja | Nein |
| Was bei fehlendem neuen Stoff? | Kann anschließend noch nicht fällige bekannte Karten vorab üben | Füllt nicht automatisch mit anderen Stapeln oder Vorab-Üben auf |
| Tagesziel | Gemeinsamer verbleibender Tagesrest | Derselbe Tagesrest |

**Wichtiger Punkt:** Einen Stapel zu deaktivieren stoppt heute nur dessen automatische neue Einführungen im gemischten Lernen. Bereits gelernte Wörter daraus bleiben fällig und werden weiter wiederholt. Wer ein einzelnes Wort gar nicht mehr üben möchte, deaktiviert dieses Wort.

Das ist sinnvoll und sollte mit einer kurzen Erklärung am Schalter sichtbar werden: „Neue Wörter im Tagesmix. Bereits gelernte Wörter werden weiter wiederholt.“

## 5. Wie zehn Plätze aktuell aufgeteilt werden

Gemischt baut die Auswahl grundsätzlich so auf:

1. Fällige bekannte Karten, nach ältester Fälligkeit.
2. Neue Karten: ausdrücklich hinzugefügte Story-Ziele bevorzugt, danach neue Ziele aktiver Stapel.
3. Falls noch Plätze frei sind: bekannte, noch nicht fällige Karten als Vorab-Üben.

Es gibt **keine feste Prozentquote** zwischen Wiederholungen und neuen Wörtern.

| Zustand vor der Sitzung, Tagesrest 10 | Mögliche Auswahl heute |
| --- | --- |
| 10 oder mehr fällige Karten | 10 fällige Karten, 0 neue |
| 7 fällige, genug zulässige neue Ziele | 7 fällige + 3 neue |
| 3 fällige, 2 passende Story-Ziele, genug Themenwörter | Typischerweise 3 fällige + 2 Story-Ziele + 5 Themenziele; Auswahlregeln können die genaue Zusammensetzung verändern |
| Keine fälligen, genügend neue Ziele | Bis zu 10 neue |
| 4 fällige, nur 2 zulässige neue Ziele, genügend bekannte Karten | 4 fällige + 2 neue + bis zu 4 Vorab-Übungen |

Die aktuellen Auswahlregeln für neue Ziele sorgen zusätzlich dafür, dass pro Sitzung nicht ständig Varianten desselben Wortes erscheinen:

- Höchstens eine neue Form je normalisiertem Lemma und Oberfläche.
- Nicht mehrfach dieselbe Einführungsgruppe.
- Bei automatischen Einführungen ungefähr vier Inhaltswörter vor einem Funktionswort; knapper Bestand kann die Sitzung verkürzen.
- Explizite Story-Wünsche werden bevorzugt und unterliegen nicht derselben einfachen automatischen Quote.
- Thematisch verwandte neue Ziele sollen drei andere neue Ziele Abstand haben; bei zu wenig Auswahl wird kontrolliert auf zwei, einen oder keinen Abstand reduziert.
- Noch nie gezeigte Lemmas werden gegenüber bereits gezeigten bevorzugt.

Story-Priorität ist dabei kein absoluter Anspruch auf die direkt nächste Position: Die Abstandssuche kann zunächst ein besser passendes anderes Ziel wählen.

### Zwei aktive Stapel A und B

Wiederholungen werden nach Fälligkeit sortiert, nicht nach dem Stapel. Acht dringende Karten aus A und zwei aus B können alle zehn Plätze belegen. Das ist richtig; künstliches 5:5 würde dringende Wiederholungen verdrängen.

Bei **neuen** Wörtern gibt es jedoch eine Schwäche: `activePrimaryIds()` hängt die Ziele in der vorhandenen Stapelreihenfolge aneinander. Der gemeinsame Selector schafft zwar Vielfalt und Themenabstand, besitzt aber keine explizite Fairnessregel zwischen Stapeln. Deshalb ist weder 5:5 garantiert noch eine gerechte Verteilung über mehrere Sitzungen zugesichert. Frühe Stapel können bevorzugt werden.

Wenn du direkt A übst, bleibt die Sitzung in A. Sind dort nur vier zulässige Ziele vorhanden, werden nicht heimlich sechs aus B hinzugefügt. Die nächste bewusst gestartete Sitzung in B verwendet den verbleibenden Tagesrest.

## 6. Mein konkreter Vorschlag für die verbesserte Auswahl

### Beibehalten

- Ein gemeinsamer Kartenbestand und Scheduler.
- Fällige Wiederholungen vor neuen Zielen, ohne starre 70:30- oder 50:50-Quote.
- Ein gemeinsames Tagesziel und explizites Weiterlernen.
- Bestehende Identitäts-, Gruppen-, Form- und Antwortregeln.
- Unveränderte aktive Sitzungen auch bei Änderungen an Einstellungen oder Inhaltspaketen.
- Fehlerwiederholung genau einmal, ohne zusätzliche Tageszielpunkte.

### Ändern: Fairness nur bei neuen Themenwörtern

Nach fälligen Wiederholungen und passenden ausdrücklich hinzugefügten Story-Zielen werden die verbleibenden neuen Plätze möglichst abwechselnd aus den aktiven Themenstapeln belegt.

Festgelegte Auswahl:

1. Pro aktivem Stapel zulässige neue Kandidaten nach bisheriger redaktioneller Reihenfolge aufbauen.
2. Bereits ausgewählte IDs, Gruppen, Oberflächen und Lemmas ausschließen.
3. Innerhalb der aktuell erfüllbaren Inhalts-/Funktionswort- und Abstandsstufe den Stapel bevorzugen, der zuletzt einen späteren Einführungszug hatte: persistierte Round-Robin-Reihenfolge je Sprache.
4. Aus diesem Stapel den ersten passenden Kandidaten wählen; bei keinem passenden Kandidaten zum nächsten Stapel gehen.
5. Den ausgewählten Stapel ans Ende der Rotation stellen. Ein bloßer Abbruch vor tatsächlicher Anzeige soll keinen Einführungszug verbrauchen.
6. Wenn kein Kandidat den Themenabstand erfüllt, wie bisher kontrolliert lockern; Fairness nie durch doppelte Karten oder unpassende Bedeutungen erzwingen.

Gemeinsame Form-/Übungsmitgliedschaften werden vor der Auswahl nach Karten-ID dedupliziert. Eine Karte mit mehreren Stapelzugehörigkeiten bekommt für die Rotation genau eine deterministisch gewählte Auswahlquelle, keinen zweiten Lernstand.

Ergebnis bei zwei vollen Stapeln und zehn ausschließlich neuen Themenzielen: meist ungefähr 5:5. Bei sieben Wiederholungen und drei neuen Themenplätzen: ungefähr 2:1; der andere Stapel beginnt beim nächsten Mal bevorzugt. Bei ungleichem Bestand oder Form-/Themenkonflikten darf die Verteilung abweichen. **Faire neue Einführungen, keine feste Tagesquote pro Stapel.**

Story-Ziele bleiben bewusste Nutzerentscheidungen und kommen vor automatisch vorgeschlagenen Themenwörtern. Wenn viele Story-Ziele warten, wird das vor dem Start sichtbar gemacht; sie werden nicht heimlich zugunsten einer Themenquote verdrängt.

### Ändern: Vorab-Üben ausdrücklich machen

Heute kann Gemischt mit noch nicht fälligen Karten auffüllen. Künftig beendet es die reguläre Runde, wenn keine fälligen und keine zulässigen neuen Ziele mehr vorhanden sind. Danach: „Für jetzt erledigt“ mit freiwilligem „Vorab üben“ und „Weitere Inhalte wählen“.

So wird niemand zum künstlichen Auffüllen des Tagesziels mit verfrühten Wiederholungen gedrängt. Wer bewusst vorab übt, behält die existierenden SRS-Regeln. Die Oberfläche muss deutlich sagen, wenn der aktuelle Bestand weniger Ziele als das persönliche Tagesziel hergibt.

### Ändern: Erster sauberer Durchgang weniger aggressiv

Die aktuelle direkte Einstufung nach 14 Tagen setzt viel Vertrauen in eine einzelne richtige Antwort. Meine Empfehlung für diesen Produktstand: **Erster sauberer Durchgang → Box 2 / vier Tage**, statt Box 3 / 14 Tage. Bei Fehler oder Aufdecken weiterhin morgen. Danach bleiben 14, 40 und 90 Tage als weitere Stufen erhalten.

Vier Tage sind eine vorsichtigere Produktentscheidung, keine wissenschaftlich universell optimale Zahl. Die Änderung gilt nur für zukünftige Bewertungen; bestehende Fälligkeiten werden nicht nachträglich umgeschrieben. Ein vollständiges probabilistisches Modell wie eine individuelle Vergessenskurve würde ich jetzt nicht vortäuschen oder ohne Lernverlaufsdaten einführen. Zunächst werden Wiedererkennungsquote nach Intervall, Fehlerquote und Überfälligkeit gemessen.

### Vor dem Start verständlich darstellen

Die gemischte Runde zeigt beispielsweise: **„Heute: 7 Wiederholungen · 3 neue Übungen“**. Wenn 25 Wiederholungen warten und das Ziel zehn beträgt: „10 von 25 fälligen Übungen“. Nach Abschluss kann man bewusst die nächsten bearbeiten.

Die Bezeichnung „Übungen“ ist genauer als „neue Wörter“, weil auch Wiederholungen und verschiedene Verbformen zählen. Nutzer sollen verstehen, weshalb ein Tag ohne neues Wort trotzdem ein erfolgreicher Lerntag ist.

## 7. Maximale Anzahl aktiver Stapel

**Keine harte Obergrenze.** Mehr aktive Stapel erhöhen bei einem begrenzten Tagesziel nicht automatisch die Zahl neuer Karten pro Tag; sie vergrößern zunächst die Auswahl. Eine künstliche Grenze löst deshalb das eigentliche Verteilungsproblem nicht.

Stattdessen empfiehlt die App **ein bis drei Schwerpunkte**. Beim Aktivieren eines vierten Stapels reicht ein einmaliger, nicht blockierender Hinweis: „Mit wenigen Schwerpunkten kommst du in jedem Thema schneller voran.“ Nicht bei jedem weiteren Toggle wiederholen.

Die Auslastung wird über tatsächlich fällige und neu eingeführte Karten erklärt. Wer 30 Wiederholungen offen hat, braucht eine transparente Wiederholungsrunde, keine Aufforderung, einen Stapel zu löschen. Ein deaktivierter Stapel lässt vorhandene Wiederholungen nicht verschwinden.

## 8. Die Sammlung „Aus Storys“

### Sichtbar wie ein Stapel, technisch eine Sammlung

Beim ersten erfolgreich gespeicherten Story-Lernziel entsteht automatisch **„Aus Storys“**, je Sprache eine Sammlung. Sie enthält alle ausdrücklich aus Storys gespeicherten Lernziele, unabhängig davon, ob die Karte bereits in einem Themenstapel existierte oder neu angelegt wurde.

Das ist die verständlichste Regel: „Hier finde ich alles, was ich beim Lesen gespeichert habe.“ Würden nur unbekannte Wörter aufgenommen, fehlten darin gerade Wörter, die der Nutzer sichtbar aus einer Story hinzugefügt hat, nur weil sie intern bereits existierten.

Ein neuer Lernstand wird trotzdem ausschließlich erzeugt, wenn kein passender vorhanden ist. Ein gespeichertes „pocket“ kann auf dieselbe Karte wie ein Themenstapel zeigen. Ein neues „arrives“ kann eine lokale Karte mit dem Story-Satz erhalten. Das Lesen desselben Wortes in einer zweiten Story ergänzt die Herkunft, nicht eine zweite Box.

### Keine automatische thematische Umsortierung

„bank“ kann je Kontext Bankinstitut oder Sitzbank sein; ein einzelnes Thema ist außerdem oft willkürlich. Deshalb werden neue persönliche Karten nicht per KI in redaktionelle Themenstapel geschrieben. Diese bleiben kuratierte Sammlungen.

Wenn später eine exakte redaktionelle Entsprechung erscheint, kann die vorhandene Identitätsbindung verwendet werden. Bereits bestehende doppelte Lernstände werden nicht ohne Prüfung zusammengeführt. Die persönliche Herkunft „aus Story X gespeichert“ bleibt erhalten.

### Bedienung

- Sammlung erst nach erfolgreichem Speichern zeigen, nicht bereits beim Tap.
- Sortierbar nach zuletzt hinzugefügt, Story und Fälligkeit.
- „Diese Sammlung üben“ verwendet dieselbe Engine, beschränkt auf ihre Mitglieder.
- Gemischt berücksichtigt die Ziele automatisch; kein zusätzlicher Aktivierungsschalter nötig, weil das Hinzufügen bereits eine bewusste Lernentscheidung ist.
- „Aus Sammlung entfernen“ entfernt nur die Verknüpfung; „Nicht mehr üben“ deaktiviert ausdrücklich die gemeinsame Karte. Diese Aktionen dürfen nicht verwechselt werden.
- Bereits bekannte Karte: „In Aus Storys gespeichert“ statt so zu tun, als sei ein völlig neues Wort erzeugt worden.
- Für denselben Kartenstand gibt es keine unterschiedlichen Fälligkeiten je Herkunft.

## 9. KI-Fallback: genau wann und wie

Die bisherige Produktregel erlaubt Laufzeit-KI nur für fehlende Übersetzungen; Satzgenerierung ist ausdrücklich noch nicht implementiert. Deine neue Anfrage ist eine gewünschte Erweiterung dieses Vertrags. Bei Umsetzung werden die Produkt-/Backendregeln gezielt ergänzt; SRS und Antwortprüfung bleiben lokal und ohne KI.

### Entscheidungsbaum

1. **Bestehende exakte Karte vorhanden?** Wiederverwenden, keine KI.
2. **Vollständiger geeigneter Story-Satz mit Übersetzung und geprüfter Lücke vorhanden?** Daraus lokale Karte speichern, keine KI.
3. **Nur ein geeigneter Kontext fehlt, Identität ist belegt?** Auf bewussten Wunsch serverseitig einen kurzen Satz erzeugen.
4. **Bedeutung/Form mehrdeutig?** Nicht raten. Kontextauflösung und nötigenfalls eine verständliche Bedeutungsbestätigung vor der Erstellung.
5. **Ladefehler, veraltete Referenz, zurückgezogene oder deaktivierte Karte?** Passenden Fehler-/Reaktivierungsweg nutzen, nicht generieren.

### Nutzerablauf

Bei tatsächlich fehlendem Kontext lautet die Aktion „Lernkarte erstellen“. Ein kurzer Hinweis erklärt beim ersten Mal: Der ausgewählte Satz und das Wort werden zur Erstellung verarbeitet. Nach Bestätigung entsteht ein fester Übungssatz. Anschließend „In Aus Storys gespeichert“ und ein Link zur Sammlung.

Der Leseort und die Auswahl bleiben erhalten. Bei Fehler bleibt die Übersetzung lesbar, ohne leere Karte oder falsche Erfolgsmeldung. Wiederholtes Tippen startet nicht mehrere Generierungen. Offline gibt es eine klare Information; keine nachträgliche unbemerkte Übertragung privater Texte.

### Anforderungen an das Ergebnis

- Genau ein verständlicher Satz mit drei bis zwanzig Wörtern.
- Exakte Zielwortform und Bedeutung aus dem ausgewählten Kontext.
- Genau eine eindeutige Lücke; keine automatische Umformung von „arrives“ zu „arrive“.
- Natürliche deutsche Satzübersetzung und passende Wortübersetzung.
- Vollständige, maschinenprüfbare Token-/Positionsdaten für die vorhandene Kartenarchitektur.
- Keine ungeprüften Synonyme als akzeptierte Antworten.
- Kein Versprechen menschlicher redaktioneller Prüfung: Herkunft als KI-generiert speichern und kenntlich machen.
- Nach Erzeugung stabiler Satz; nicht bei jeder Übung neu generieren.

Strukturelle Validierung allein beweist noch keine sprachliche Richtigkeit. Der Erzeugungsdienst benötigt zusätzlich eine getrennte Qualitätsprüfung und einen Meldeweg. Schlägt die Prüfung fehl, wird kein Lernziel freigegeben. Reparaturversuche werden begrenzt, nicht unbegrenzt wiederholt.

### Technische Umsetzungsvorgabe

Authentifizierte Supabase Edge Function, serverseitige Provider-Secrets, dasselbe freigegebene Anthropic-Backend. Keine direkten KI-Aufrufe aus Flutter. Quota, Eingabegrenzen, Anfrage-ID, Persistenz und serverseitige Validierung vor Veröffentlichung.

Cacheidentität enthält Sprache, Form, belegte Bedeutung/Funktion und Versionsstand. Private importierte Texte bleiben kontogebunden. Ein erzeugter Satz wird atomar zusammen mit Karte, Kontext, Identitätsbindung und Sammlungsmitgliedschaft gespeichert. Ein Abbruch darf keinen halben Datensatz hinterlassen.

Die neue Aktion ist teurer und komplexer als eine kurze Übersetzung. Sie erhält ein eigenes Kontingent: **vorläufiger Produktvorschlag fünf kostenlose erfolgreiche Kartenerstellungen einmalig, Premium 100 je Abo-Monat**. Kein Verbrauch für vorhandene Karten oder geprüfte lokale Story-Sätze. Das ist eine Ergänzung zum Freemium-Plan, dessen 500 Übersetzungsanfragen nicht stillschweigend in „500 vollständige Kartengenerierungen“ umgedeutet werden. Vor Verkauf müssen reale Kosten für Erzeugung plus Qualitätsprüfung gemessen werden; bis dahin keine wirtschaftliche Garantie für diese Zahl.

## 10. Was von Lingvist belastbar übernommen werden kann

Die Screenshots ab IMG_8633 zeigen eine Google-Antwort über Lingvist, keine Spezifikation des Lingvist-Quellcodes. Ihre Aussagen sind deshalb Hinweise für die Recherche, keine verbindliche Implementierungsanleitung.

Offizielle Hilfeseiten bestätigen: Wiederholungen haben Vorrang vor neuen Wörtern; mehrere Stapel und das Stummschalten einzelner Wörter werden unterstützt. Eine exakte 5:5-Verteilung wird damit nicht belegt. Quelle: [Lingvist: zu viele Wiederholungen](https://lingvist.io/help/i-have-too-many-words-to-review-can-i-switch-them-off/).

Lingvist beschreibt eine persönliche Anpassung an Lernverlauf und Fehler. Daraus folgt nicht, dass deine derzeitige feste Leitner-Tabelle dieselbe Technologie verwendet. Quelle: [Lingvist: wiederkehrende Wörter](https://lingvist.io/help/why-do-i-see-the-same-words/).

Ein älterer offizieller Blogbeitrag nennt ein Gedächtniskurvenmodell, eine 80-%-Zielgröße sowie die 100-20-1-Empfehlung. Das ist eine historische Anbieterbeschreibung, keine universelle pädagogische Vorgabe und keine vollständige aktuelle Algorithmusspezifikation. Aktuelle Hilfetexte nennen auch 50 Karten als Praxisempfehlung. Deshalb wird dein Tagesziel nicht auf 100/20/1 umgestellt. [Blog zu Spaced Repetition](https://lingvist.io/blog/spaced-repetition-in-learning/), [offizielle Lernempfehlung](https://lingvist.io/help/how-should-i-learn-with-lingvist-and-why-does-it-work/).

Die konkrete ACT-R-/KME-Zuordnung, Gewichtung der Wortlänge und mathematische Formel aus den Screenshots wurden durch die hier verwendeten Primärquellen nicht ausreichend belegt. Sie werden nicht als Fakten über die aktuelle Lingvist-Implementierung übernommen.

## 11. Umsetzungsreihenfolge nach Entscheidung

1. **Gerätefehler isolieren:** tatsächliche Ausnahme statt generischer Sammelmeldung, passenden Regressionstest schreiben und Ursache beheben.
2. **Sammlung „Aus Storys“:** vorhandene Story-Add-Entscheidungen als Mitgliedschaften verwenden, Bestandsdaten ohne neue Reviews migrieren, gleiche Karte überall wiederverwenden.
3. **Sitzungsübersicht und Bezeichnungen:** Tagesziel als Übungen erklären, erwartete Wiederholungen/neue Ziele anzeigen, freien Stapelschalter erläutern.
4. **Fairness der neuen Themenziele:** persistierte Rotation, ID-Deduplizierung, bestehende Form-/Gruppenregeln erhalten.
5. **Geänderte Erstbewertung und freiwilliges Vorab-Üben:** prospektive Regeln; keine Neuberechnung alter Lernstände.
6. **Serverseitige Kartenerstellung:** gesonderte Qualitäts-, Quoten-, Datenschutz- und Kostenabnahme; erst danach den fehlenden Kontext im Reader damit ergänzen.

Abnahmeszenarien: zwei aktive Stapel bei null/sieben/zwanzig fälligen Karten; gleiche Karte in mehreren Ansichten; Story-Ziel schon im Themenstapel; erstes lokales Story-Ziel; zwei parallele Adds; Neustart; deaktivierte Karte; unklare Form; kaputter Paketverweis; Wechsel von Monat/Tag/Sprache; Abbruch vor Anzeige; fehlender KI-Zugang; fehlgeschlagene Qualitätsprüfung; Erhalt aller alten Boxen/Fälligkeiten bei Einführung der neuen Regel.

## 12. Codebelege und Prüfung dieser Analyse

- [Gemischter Einstieg](../../lib/screens/app_shell.dart), [direkter Stapelstart](../../lib/screens/decks/deck_details_screen.dart).
- [Sitzung, Tagesrest und Speicherung](../../lib/presentation/practice/deck_session_controller.dart).
- [Gemischte und Stapel-Queue, Fehlerwiederholung](../../lib/domain/srs_state.dart).
- [Auswahl neuer Wörter](../../lib/domain/new_card_selection.dart), [Intervalle und Einstufung](../../lib/domain/leitner.dart).
- [Aktive Stapel und gemeinsame Kartenauflösung](../../lib/data/learning/practice_item_resolver.dart).
- [Story-Service](../../lib/presentation/providers/story_learning_providers.dart), [Reader-Fehlerpfad](../../lib/screens/stories/story_reader_screen.dart).
- [Inhaltsauflösung](../../lib/data/content/drift_content_repository.dart), [Story-Identität und Validierung](../../lib/domain/story_learning.dart), [Status und Speichern](../../lib/data/user/drift_user_repository.dart).
- [Bestehende SRS-Regeln](../srs.md), [Produktvertrag](../../PRODUCT.md), [bereits geprüfte Story-Sätze](../story-single-sentence-v1.md).

GitNexus wurde explizit gegen diesen Checkout verwendet, nicht gegen das ebenfalls registrierte ältere Worktree. Indexstand 24.10.2026 11:30 UTC, Commit `7e401a43`; aktuelle Implementierungen zusätzlich direkt gelesen. Der Index ersetzt keinen Nachweis für spätere uncommittete Änderungen oder den Gerätestand.

Vor Tooltip-Änderung: Impact `_WordPopoverState` LOW, direkter Import im Reader, transitiv AppShell/Main; keine ausgewiesenen Prozesse. Der Testeinstieg `main` hat graphseitig UNKNOWN; als vom Flutter-Testläufer erreichbarer Einstieg per Quelldatei bestätigt. Bestehenden Test auf die ausdrücklich entfernten Beschriftungen angepasst.

Ausgeführt: `flutter test --no-pub test/domain/schedule_test.dart test/domain/new_card_selection_test.dart test/domain/vocab_breakdown_test.dart test/story_learning_flow_test.dart test/widget_test.dart --reporter compact` → **105 Tests bestanden**. Zusätzlich lokaler Paket-/Speichertest für die vier genannten Wörter → **1 Test bestanden**. Der Paket-/Speichertest verwendet eine leere Testdatenbank, kein iPhone-Profil. Ein erster Versuch dieses erweiterten Tests mit reinem Dart statt Flutter war wegen `dart:ui` nicht ausführbar; der anschließende Flutter-Test lief erfolgreich.

Statische Analyse: `flutter analyze --no-pub` meldet einen `avoid_print`-Infohinweis in der hier nicht bearbeiteten Datei `test/data/baseline_adoption_pack_test.dart:43`. Keine weiteren Befunde; deshalb kein vollständig grüner Gesamtanalyse-Status behauptet. Alle lokalen Dokumentverweise wurden auf Existenz geprüft.

Die größere Lernlogik, Sammlung und KI-Erstellung sind hier bewusst als Zielkonzept dokumentiert und noch nicht implementiert. Die bestehende App benötigt für „arrives“ im geprüften Paket bereits heute keinen KI-generierten Satz.
