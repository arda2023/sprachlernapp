# Alltag v1 – vollständige Auswertung des vorhandenen Laufs

Historische Erstprüfung am 04.10.2026 (aktueller Merge-Stand im Nachtrag am Ende). Quellen ausschließlich lokal; keine Generierung, keine Cloud-Prüfung, kein Export, keine Zusammenführung oder Installation. Nur dieser Bericht und NEXTSTEPS.md werden geändert.

## Ergebnis und Prüfumfang

**87/100 ausgewählte Karten liegen im Teilpack vor: 60 NOUN, 24 VERB, 3 ADJ. Alle 261 Originalsätze mit ihren deutschen Übersetzungen und alle 33 gespeicherten Alternativen wurden vollständig gelesen; jede Alternative wurde wörtlich in ihre Lücke eingesetzt und als ganzer Satz geprüft. Keine Stichprobe.**

| Abschlussstatus | Karten |
|---|---:|
| Geprüft, ohne Befund im beschriebenen Prüfumfang | 77 |
| Bestätigte Korrekturen erforderlich | 5 |
| Unklarer redaktioneller Fall | 5 |
| Nicht gepackt / technisch nicht fertig erzeugt | 13 |

Fünf bestätigte Alternativbefunde betreffen vier Karten; hinzu kommt eine fehlerhaft verkürzte Hauptglosse bei bus. Vier weitere Alternativen und vier Satz-/Zielabgrenzungen bleiben auf fünf anderen Karten redaktionell offen. Die übrigen **24/33 Alternativen** sind ohne Befund. Kein bestätigter englischer Grammatikfehler in den 261 Originalsätzen. Natürlichkeit und Aussagegleichheit sind redaktionelle Urteile, keine mathematische Fehlerfreiheitsgarantie.

Die Vollprüfung umfasst Satztexte, Satzübersetzungen, Zielform/-bedeutung und gespeicherte Alternativen. Tokenpositionen, Referenzen und Normierung wurden technisch vollständig geprüft. Keine vollständige semantische Einzelprüfung aller 998 Wörterbuch-Senses oder ihrer 2.886 Tokenzuordnungen; kein Anspruch auf Vollständigkeit der automatisch gefundenen Synonyme. Nicht gepackte Kandidaten wurden für Laufstatus/Ausschlussgründe ausgewertet, nicht als freigegebener Inhalt bewertet.

## Artefakte und technischer Abschluss

| Tatsächliche Datei | Bytes | SHA-256 |
|---|---:|---|
| `ledger.csv` | 63530 | `3357f456916c09f8697ee6be08c47e2530863df2381c95e2fbbe3b2a861b80d3` |
| `pack.json` | 1384371 | `f5d1bf2c70b9bc01dbb524e2bc862bbe7e4f63a5bd13e5eeb61e9dc6f3f31035` |
| `progress.txt` | 56 | `97606b73f079f09124fba2fa9b5163c190fe2be05a94e50fa764b6cc682b0d68` |
| `review.csv` | 177485 | `fb0580b53299828c4dae70f0d9b664640582ab4d7454af0d408c44d212f3a945` |
| `run_report.md` | 8094 | `78213865f67fcae89396311fda72061ac04c72df11f99faf0522e53aea40dbd7` |

Laufverzeichnis: `pipeline/out/everyday_v1_20261004/`. `pack.json` existiert, ist aber ein im finally-Block gespeicherter Teilstand, kein Beleg für einen erfolgreichen Gesamtlauf. Release: `0.0.0-generate`, schema_version 1.

Abbruch laut run_report.md:

```text
LlmError: meaning_check: Expecting ',' delimiter: line 4 column 25 (char 73)
(model=gemini-3.8-flash, max_output_tokens=1024, input_tokens=804,
 output_tokens=29, thinking_tokens=981, finish_reason=MAX_TOKENS)
```

**Technischer Parse-/Ausgabelimitabbruch, kein Budgetabbruch und keine inhaltliche Ablehnung der 13 fehlenden Wörter.** Das Ledger enthält den passenden meaning_check-Aufruf am 04.10.2026 um 13:26:29.152616 UTC. Eine Rohantwort oder ein Kartenbezug steht im Ledger nicht. 1024 ist das dokumentierte Aufruflimit; die Tokenzahlen werden als beobachtet wiedergegeben, nicht auf eine erfundene Aufteilung ergänzt.

progress.txt: forms 80/100, calls 781, USD 0.869814, elapsed_s 370.2. Pack: 87 fertige Karten. Kein Widerspruch: der ThreadPool wartet beim Abbruch auf bereits laufende Aufgaben; sieben weitere Karten sind vor dem finally-Packaufbau fertig, ohne dass die abgebrochene Ergebnisschleife form_done weiterzählt. Laut CLI entspricht ein zurückgemeldeter Abbruch Exitcode 3; der tatsächliche Shell-Exitcode des historischen Starts wurde nicht mitgespeichert.

## Aufrufe und tatsächliche Kosten

| Ledger-Schritt | Modell | Aufrufe | Summe gerundeter USD-Zeilen |
|---|---|---:|---:|
| alternative_check | gemini-3.8-flash | 47 | 0.058346 |
| annotate | gemini-3.8-flash | 87 | 0.355312 |
| blindtest | gemini-2.5-flash | 276 | 0.032402 |
| meaning_check | gemini-3.8-flash | 276 | 0.283178 |
| sentences | gemini-3.8-flash | 95 | 0.140562 |

**781 protokollierte Modellaufrufe; Ledger-Summe 0,869800 USD.** Token: 441.283 Input, 137.247 Output, 15.079 Thinking. Neuberechnung aus diesen Token mit den vorhandenen Preissätzen ergibt **0,869814 USD**, genau wie progress.txt. Die Differenz von 0,000014 USD entsteht durch Rundung jeder Ledger-Zeile auf sechs Dezimalstellen; keine Budgetüberschreitung. Budget 3,00 USD. Das sind die im Lauf protokollierten Kosten, keine separat abgerufene Cloud-Rechnung.

Generierung laut Laufbericht: gemini-3.8-flash/LOW; Blindtest gemini-2.5-flash/thinking_budget=0. Tatsächliche Modelle je Schritt stehen oben. Prompts laut Laufbericht: meanings-v5, sentences-v7, annotate-v2, blindtest-v3, meaning-check-v6, alternative-check-v3. meanings-v5 wird im Bericht als Promptversion aufgeführt, es gibt jedoch **keinen meanings-Aufruf** im Ledger.

435 gespeicherte Kandidaten: 261 ok, 10 failed, 164 unused; 442 Satzversuche einschließlich ersetzter Versuche. Inhaltliche Ablehnungen einzelner Versuche: Sprache 8, Übersetzung 1, Blindtest 6, Linter 1, Duplikat 2 (Gründe überlappen, nicht addieren). Alle tatsächlich gepackten Karten haben trotzdem drei ok-Sätze. 97 Alternativkandidaten geprüft, 33 bestätigt, 64 abgelehnt; die 33 übernommenen Einträge wurden hier erneut vollständig redaktionell geprüft.

## Lokale Strukturprüfung und Überschneidungen

Vorhandene Validatoren: `sprachpipe.pack.build_rows`, `finalize_curation.check_pack`, `sprachpipe.cli lint`; Tokengegenprobe über `sprachpipe.annotate.tokenize`. Ergänzend rein lesende In-Memory-Assertions zu eindeutigen IDs, [1,2,3]-Positionen, accepted, Zielformen, QA-Status und Auswahlidentitäten. Kein SQLite-Export und kein DB-Schreibzugriff. Das JSON enthält Referenzen; stabile IDs werden mit build_rows abgeleitet, nicht als bereits im JSON gespeicherte IDs ausgegeben.

Tatsächlicher Output:

```text
build_rows + check_pack: PASS; refs/schema/IDs/deck positions/dictionary ranks
Read-only assertions: PASS; 87 x 3 sentences; 261 gaps/accepted/QA; 2886 token spans; 0 duplicate IDs; 0 extra learning senses
sprachpipe.cli lint: 0 error(s)
Existing pack integrity: ok
```

Lint-Befehl, identische Argumente mit jeweiligem Python-Pfad, ab Repository-Root:

```powershell
.\pipeline\.venv\Scripts\python.exe -X utf8 -m sprachpipe.cli lint pipeline/out/everyday_v1_20261004/pack.json
```

```sh
pipeline/.venv/bin/python -X utf8 -m sprachpipe.cli lint pipeline/out/everyday_v1_20261004/pack.json
```

Windows-Befehl ausgeführt; macOS nicht ausgeführt. 58 i+1-Warnungen sind im gepackten QA-Material hinterlegt, keine Strukturfehler oder automatische Ausschlussgründe. Alle 87 Karten stimmen in Form, Lemma, POS und Sense-Key mit der Auswahl überein und haben form_kind=base. accepted enthält jeweils ausschließlich die Zielform. Alle Alternativen erfüllen Listenformat/Normalisierung/Deduplikation/Zielform-Ausschluss. Das ersetzt keine semantische Freigabe.

Keine ungefragten Lernkarten-Senses. 656 Lemmas, 998 Senses und 1021 dictionary_forms im JSON umfassen zusätzlich Satzannotation; diese sind keine 998 Lernkarten.

App-Pack ausschließlich über SQLite mode=ro gelesen. ID-Überschneidungen:

| Tabelle | gemeinsame IDs | davon abweichende Felder |
|---|---:|---|
| cards | 0 | 0 |
| sentences | 0 | 0 |
| lemmas | 437 | 0 |
| senses | 507 | 73 Glossenabweichungen |
| dictionary_forms | 495 | 230 Zeilen; 159 rank, 66 card_id, 57 gloss_de (überlappend) |
| decks | 1 | 0 |

**Keine blinde Upsert-Zusammenführung:** gemeinsame Wörterbucheinträge haben legitime neue Kartenverknüpfungen, packlokale Ränge und teils abweichende Glossen. Beispielsweise table#tisch, ID `89d9cb5191e683cdd9916b9907f8420e`: alt „Tisch“, neu die redaktionelle Definition; bandage#verband, ID `799ba526fac5191272956a6fa7871a86`: alt „Verband“, neu die explizite Wundverbanddefinition. Das sind nicht automatisch neue Bedeutungen oder Fehler. Bei bus liegt hingegen eine tatsächliche Verkürzung vor (K3 unten).

Bei 28/87 Ziel-Senses entspricht gloss_de nur einer vorher eingefügten kurzen Token-Glosse statt wortwörtlich der Auswahldefinition: leg, bed, meeting, basket, foot, bus, car, shirt, bread, computer, sleep, bag, drink, plate, drive, cook, bicycle, desk, hand, train, window, carry, ticket, clean, cut, knife, station, office. Ein zunächst strenger Gleichheitscheck der Definitionstexte schlug deshalb fehl; das wurde als Metadatenabweichung untersucht, nicht als bestandener Test ausgegeben. Die Sense-Identitäten stimmen überein. Kurze sinngleiche Glossen sind erlaubt; Zieldefinitionen wurden zusätzlich anhand der Auswahl geprüft.

## Bestätigte Korrekturen

### K1/K2 – fünf Alternativen auf vier Karten

Alle eingesetzten Sätze sind grammatisch möglich. Die Befunde betreffen Aussageumfang oder Bezugsperspektive, keine Seltenheit oder bloße Stilpräferenz. Für die nächste Freigabe diese fünf Einträge aus valid_alternatives entfernen; Originalsatz, accepted und stabile Karten-ID können bleiben. Hier wurde nichts korrigiert.

- **phone|phone/NOUN|phone#telefon** — Karten-ID `12c292f705a3be680124ab5662656a77`; Satz `s8` / `a07f6a220e98d122f6e04cdf05e24eb1`.
  Original: Can you check your phone for a message from Lina?
  Deutsch: Kannst du auf deinem Telefon nach einer Nachricht von Lina schauen?
  `cell phone` eingesetzt: Can you check your cell phone for a message from Lina?
  Befund: Verengt phone auf ein Mobiltelefon. Eine Nachricht kann auch über ein Festnetztelefon/Voicemail geprüft werden; der Originalsatz legt die Geräteart nicht fest.

- **phone|phone/NOUN|phone#telefon** — Karten-ID `12c292f705a3be680124ab5662656a77`; Satz `s8` / `a07f6a220e98d122f6e04cdf05e24eb1`.
  Original: Can you check your phone for a message from Lina?
  Deutsch: Kannst du auf deinem Telefon nach einer Nachricht von Lina schauen?
  `mobile` eingesetzt: Can you check your mobile for a message from Lina?
  Befund: Wie cell phone: das Mobiltelefon wird zusätzlich festgelegt. Grammatisch korrekt, aber ohne belegten Mobilkontext nicht bedeutungsgleich.

- **send|send/VERB|send#schicken** — Karten-ID `8e33bb3900e1cdba8463b770b9a78b77`; Satz `s146` / `2eeca48989194c550818cc608869d2a1`.
  Original: Can you send a birthday card to Rosa?
  Deutsch: Kannst du eine Geburtstagskarte an Rosa schicken?
  `mail` eingesetzt: Can you mail a birthday card to Rosa?
  Befund: Legt postalischen Versand fest; send lässt den Übermittlungsweg offen, auch bei einer Geburtstagskarte. Die allgemeinere deutsche Übersetzung beseitigt diese Einschränkung nicht.

- **bring|bring/VERB|bring#bringt** — Karten-ID `badadda5072db0c453a6aee6545a012f`; Satz `s192` / `b83df3189fdbace3a0e864e394688c0d`.
  Original: Lina will bring the documents to the office tomorrow.
  Deutsch: Lina wird die Dokumente morgen ins Büro bringen.
  `take` eingesetzt: Lina will take the documents to the office tomorrow.
  Befund: bring orientiert die Bewegung zum Sprecher/Adressaten oder übernommenen Zielstandpunkt, take typischerweise von dort weg. Gleicher Zielort macht die deiktische Perspektive nicht austauschbar.

- **receipt|receipt/NOUN|receipt#kassenbon** — Karten-ID `c4220fc1b79b75f3e194e920dcb26f5c`; Satz `s206` / `05218294a9689370661fb9ea2f05e6c3`.
  Original: Does Luis have the receipt for this blue shirt?
  Deutsch: Hat Luis den Beleg für dieses blaue Hemd?
  `proof of purchase` eingesetzt: Does Luis have the proof of purchase for this blue shirt?
  Befund: Ein Kaufnachweis kann auch ein Kontoauszug oder anderer Nachweis sein; receipt bezeichnet den konkreten Beleg. Die Frage nach irgendeinem Kaufnachweis ist weiter als die nach dem receipt.

### K3 – verkürzte Hauptglosse bus

Karte `bus|bus/NOUN|bus#bus`, ID `6622d48746ef8346cf9dc8c89e2ec925`. Sense-ID `30e0847cb1510ba218574a7bb55bb7ce`, `bus#bus`: im App-Pack „Bus“, im neuen Pack **„Bus-“**. Das ist eine aus der Kompositumsannotation übernommene gebundene Form und keine vollständige Glosse der eigenständigen Bus-Karte. Die drei Bus-Sätze s109–s111 sind sprachlich und sachlich passend; für den unabhängigen Sense die vollständige Glosse erhalten/wiederherstellen. Die card.translation_de ist bereits „Bus“; daher kein pauschaler Satzneubau nötig.

Beleg s109 / `cc9ef16a674258c066e717f09e941f4c`: „Leo looks out the window and watches the big bus arrive outside.“ — „Leo schaut aus dem Fenster und sieht den großen Bus draußen ankommen.“.

## Unklare redaktionelle Fälle

Diese Fälle werden nicht als bestätigte Sprachfehler gezählt und vorerst nicht für das befundfreie Teillos freigegeben. Kein automatischer Ersatz der ausgewählten Wörter.

- `road|road/NOUN|road#strasse` / `4a30a152f12d45bcfbf798afcb11101c`; `s79` / `c5c3ae22a17f2628f7b0b8429acd4469`.
  Original: Sara can see heavy traffic on the road from her office window. — Sara kann von ihrem Bürofenster aus dichten Verkehr auf der Straße sehen.
  `street` eingesetzt: Sara can see heavy traffic on the street from her office window.
  Einordnung: road ist allgemeiner als street. Der Kontext mit Bürofenster macht eine Stadtstraße plausibel, legt sie aber nicht fest; redaktionell über die zulässige Kontextgleichheit entscheiden.

- `road|road/NOUN|road#strasse` / `4a30a152f12d45bcfbf798afcb11101c`; `s80` / `b223945a912afc18e6be8473e63e6a5b`.
  Original: Ben walked out of the station and crossed the busy road. — Ben ging aus dem Bahnhof und überquerte die belebte Straße.
  `street` eingesetzt: Ben walked out of the station and crossed the busy street.
  Einordnung: Auch eine belebte Straße vor einem Bahnhof muss nicht als street eingeordnet sein. Häufig synonym verwendbar, deshalb kein pauschales Sprachfehlerurteil; Bedeutungsumfang redaktionell klären.

- `road|road/NOUN|road#strasse` / `4a30a152f12d45bcfbf798afcb11101c`; `s81` / `2e1b58b20bba1b3aff592e2611b7ea4c`.
  Original: Did David park his car on the other side of the road? — Hat David sein Auto auf der anderen Straßenseite geparkt?
  `street` eingesetzt: Did David park his car on the other side of the street?
  Einordnung: Straßenseite und Parken passen zu beiden Wörtern. street kann dennoch eine bebaute Straße enger festlegen; Grenzfall der geforderten Aussagegleichheit.

- `box|box/NOUN|box#schachtel` / `b546d31ecafb2804b3de1c5ec13517f8`; `s176` / `0361ac900df19f99bd320e0866bdb140`.
  Original: Luis keeps his gardening tools inside a wooden box. — Luis bewahrt seine Gartenwerkzeuge in einer Holzkiste auf.
  `crate` eingesetzt: Luis keeps his gardening tools inside a wooden crate.
  Einordnung: wooden box und wooden crate überlappen, crate bezeichnet typischerweise eine Transport-/Lagerkiste. Der Originalsatz nennt nur Material und Aufbewahrung; keine sichere Identität der Bauart.

- `key|key/NOUN|key#schluessel` / `370a358b45692dcb4810c3066bad9a1b`; `s53` / `2b2b90918d944b984fcd138035038a4d`.
  Original: Did Lina hide the key to the gift box? — Hat Lina den Schlüssel zum Geschenkkarton versteckt?
  Einordnung: gift box wird zu Geschenkkarton: Das Material Karton steht nicht im Original. Verschließbare Geschenkboxen sind möglich; vorsichtige Korrektur zu Geschenkbox erwägen, kein englischer Grammatikfehler.

- `basket|basket/NOUN|basket#korb` / `56b49b92c0c28ca1f8d906c540ee949e`; `s98` / `51728bacf7c7b1a6ed653ab842171c06`.
  Original: Did Ali carry his tennis balls to the court in a basket? — Hat Ali seine Tennisbälle in einem Korb zum Platz getragen?
  Einordnung: Tenniskorb: gleiche allgemeine Korbbedeutung, aber die explizite Auswahldefinition beschränkt sich auf das Tragen von Einkäufen. Klären, ob die Zweckangabe nur ein Beispiel sein soll; Auswahl hier nicht geändert.

- `basket|basket/NOUN|basket#korb` / `56b49b92c0c28ca1f8d906c540ee949e`; `s99` / `2fad4f8ab73703a94d7a692d4ced82e1`.
  Original: Omar takes the large laundry basket down the stairs every Saturday. — Omar bringt jeden Samstag den großen Wäschekorb die Treppe hinunter.
  Einordnung: Wäschekorb: gleiche allgemeine Korbbedeutung, aber nicht der in der Auswahl ausdrücklich genannte Einkaufszweck. Keine zusätzliche Sense-ID; redaktionelle Zielabgrenzung offen.

- `lamp|lamp/NOUN|lamp#lampen` / `6a39e160dd22cc901a4c11fd038313ee`; `s116` / `53489ff73bdebe6da16b4a4580509ef0`.
  Original: Did Luca see the bright lamp in the front garden? — Hat Luca die helle Lampe im Vorgarten gesehen?
  Einordnung: Lampe im Vorgarten statt Raumbeleuchtung der expliziten Auswahldefinition. Natürliches Englisch und passende Übersetzung; unklar ist allein die beabsichtigte Reichweite der Zieldefinition.

## Bewusst nicht beanstandet

„mend“ beim Fahrrad bzw. Stuhlbein ist seltener, aber korrekt; „pushbike“ ist eine gültige regionale Bezeichnung. „quiet table“ bezeichnet plausibel einen ruhigen Sitzplatz, anders als unsinnig „ruhige Bücher“. Bustisch, intelligentes Kopfkissen, kalter Staub, ein schwerer Brief und ein Reiseschalter im Supermarkt sind ungewöhnliche, aber mögliche Situationen. „public transport vehicle“ ist sperrig, jedoch korrekt; „cow milk“ wird nicht allein wegen der häufigeren Form „cow’s milk“ verworfen. „pc“ ist in valid_alternatives absichtlich kleingeschrieben (Schema-Normalisierung), kein Rechtschreibbefund am Originalsatz. „snip“ passt hier zum Schneiden eines Drahts mit der Schere; „jot/note/put down“ passen zur schriftlichen Namensliste.

## Fehlende Positionen: tatsächlicher Grund

Es fehlen sit (Auswahlposition 84) sowie wet, soft, hard, cheap, expensive, young, old, strong, ready, quiet, safe, heavy (89–100). Für keine dieser 13 Formen existiert eine Zeile in review.csv; run_report meldet jeweils 0/3 angenommene Sätze und keine protokollierte Verwerfung. Es wäre falsch, diese Karten als inhaltlich abgelehnt zu zählen.

Die CLI verarbeitet Achterwellen. Positionen 81–88 wurden begonnen; sieben davon liegen im Pack. Damit ist sit der unterbrochene/nicht fertiggestellte Kandidat der Abbruchwelle. Die Zuordnung der konkreten fehlerhaften Modellantwort zu sit ist eine starke Ablauf-Inferenz, kein direktes Formfeld im Ledger. Positionen 89–100 wurden nach dem Abbruch nicht mehr an die Generierung übergeben. Alle 100 Kartenobjekte werden schon vorher angelegt: „100 Karten“ im Laufbericht bedeutet deshalb nicht 100 ausgeführte Kartengenerierungen. Ein möglicherweise erzeugter, nicht gespeicherter Rohsatz für sit ist aus den Artefakten nicht rekonstruierbar.

## Nutzerbeispiele einzeln

| Form | Ergebnis | Sätze | Alternativen |
|---|---|---|---|
| table = Tisch | O; Möbelbedeutung, keine Tabelle | s37–s39 | keine |
| speaker = Lautsprecher | O; Audiogerät, keine sprechende Person | s91–s93 | loudspeaker in s93 geprüft und passend |
| bandage = Verband | O; Wundverband als NOUN, kein Verb | s223–s225 | keine |

## Einziger empfohlener nächster Umsetzungsschritt

**Die Zusammenführung eines abgegrenzten Teilloses aus den 77 O-Karten vorbereiten**, mit expliziter Auflösung der gemeinsamen Sense-/Wörterbuchfelder und neuer gemeinsamer Rangfolge, ohne das bestehende Pack blind zu überschreiben. Die fünf K-Karten und fünf U-Karten bleiben dabei zurückgestellt; die 13 fehlenden Originalpositionen bleiben unverändert auf der Auswahl. Das ist ausreichend geprüfter Inhalt für eine Erweiterungsvorbereitung, keine Empfehlung für einen Komplett-Neulauf, eine Budgeterhöhung oder eine Installation. In diesem Auftrag wurde diese Vorbereitung noch nicht ausgeführt.

## Soll/Ist jeder Auswahlposition

O = geprüft ohne Befund; K = bestätigte Korrektur; U = redaktionell unklar; N = nicht gepackt. Jede gepackte Zeile hat 3/3 technisch gültige Sätze. Karten- und Satz-IDs folgen im vollständigen Prüfprotokoll; für fehlende Karten wird keine existierende Pack-ID behauptet.

| Nr. | Lemma / POS | explizite Zielbedeutung | Sense-Key | Ist / Status / Grund |
|---:|---|---|---|---|
| 1 | table / NOUN | Möbel mit waagerechter Platte zum Essen oder Arbeiten | `table#tisch` | O: 3/3; geprüft, ohne Befund |
| 2 | chair / NOUN | Sitzmöbel für eine Person mit Rückenlehne | `chair#stuhl` | O: 3/3; geprüft, ohne Befund |
| 3 | bed / NOUN | Möbel zum Schlafen | `bed#bett` | O: 3/3; geprüft, ohne Befund |
| 4 | pillow / NOUN | Weiche Unterlage für den Kopf im Bett | `pillow#kissen` | O: 3/3; geprüft, ohne Befund |
| 5 | blanket / NOUN | Textile Decke zum Zudecken | `blanket#decke` | O: 3/3; geprüft, ohne Befund |
| 6 | kitchen / NOUN | Raum zum Zubereiten von Speisen | `kitchen#kueche` | O: 3/3; geprüft, ohne Befund |
| 7 | plate / NOUN | Flaches Geschirr zum Servieren von Essen | `plate#teller` | O: 3/3; geprüft, ohne Befund |
| 8 | cup / NOUN | Trinkgefäß mit Henkel | `cup#tasse` | O: 3/3; geprüft, ohne Befund |
| 9 | spoon / NOUN | Besteck zum Essen von Suppe | `spoon#loeffel` | O: 3/3; geprüft, ohne Befund |
| 10 | fork / NOUN | Besteck mit Zinken | `fork#gabel` | O: 3/3; geprüft, ohne Befund |
| 11 | knife / NOUN | Werkzeug mit Klinge zum Schneiden | `knife#messer` | O: 3/3; geprüft, ohne Befund |
| 12 | towel / NOUN | Tuch zum Abtrocknen | `towel#handtuch` | O: 3/3; geprüft, ohne Befund |
| 13 | soap / NOUN | Mittel zum Waschen der Hände | `soap#seife` | O: 3/3; geprüft, ohne Befund |
| 14 | mirror / NOUN | Gegenstand, in dem man sein Spiegelbild sieht | `mirror#spiegel` | O: 3/3; geprüft, ohne Befund |
| 15 | window / NOUN | Verglaste Öffnung in einer Wand | `window#fenster` | O: 3/3; geprüft, ohne Befund |
| 16 | speaker / NOUN | Gerät, das elektrische Signale als hörbaren Schall wiedergibt; keine sprechende Person | `speaker#lautsprecher` | O: 3/3; geprüft, ohne Befund |
| 17 | bag / NOUN | Tragbarer Behälter für persönliche Dinge | `bag#tasche` | O: 3/3; geprüft, ohne Befund |
| 18 | key / NOUN | Gegenstand zum Öffnen eines Schlosses | `key#schluessel` | U: 3/3; unklarer redaktioneller Fall |
| 19 | phone / NOUN | Gerät zum Telefonieren | `phone#telefon` | K: 3/3; bestätigte Korrektur erforderlich |
| 20 | bottle / NOUN | Verschließbares Gefäß für Flüssigkeiten | `bottle#flasche` | O: 3/3; geprüft, ohne Befund |
| 21 | box / NOUN | Fester Behälter zum Aufbewahren von Dingen | `box#schachtel` | U: 3/3; unklarer redaktioneller Fall |
| 22 | clock / NOUN | Gerät zur Anzeige der Uhrzeit an Wand oder auf Tisch | `clock#uhr` | O: 3/3; geprüft, ohne Befund |
| 23 | lamp / NOUN | Gerät zur Beleuchtung eines Raums | `lamp#lampen` | U: 3/3; unklarer redaktioneller Fall |
| 24 | shirt / NOUN | Kleidungsstück für den Oberkörper mit Kragen und Knöpfen | `shirt#hemd` | O: 3/3; geprüft, ohne Befund |
| 25 | shoe / NOUN | Kleidungsstück für einen Fuß | `shoe#schuhe` | O: 3/3; geprüft, ohne Befund |
| 26 | shop / NOUN | Ort, an dem Waren verkauft werden | `shop#geschaeft` | O: 3/3; geprüft, ohne Befund |
| 27 | price / NOUN | Geldbetrag, den eine Ware kostet | `price#preis` | O: 3/3; geprüft, ohne Befund |
| 28 | receipt / NOUN | Beleg für einen bezahlten Einkauf | `receipt#kassenbon` | K: 3/3; bestätigte Korrektur erforderlich |
| 29 | basket / NOUN | Offener Behälter zum Tragen von Einkäufen | `basket#korb` | U: 3/3; unklarer redaktioneller Fall |
| 30 | bread / NOUN | Gebackenes Grundnahrungsmittel aus Mehl | `bread#brot` | O: 3/3; geprüft, ohne Befund |
| 31 | milk / NOUN | Flüssiges Lebensmittel von Kühen | `milk#milch` | O: 3/3; geprüft, ohne Befund |
| 32 | apple / NOUN | Runde essbare Frucht des Apfelbaums | `apple#aepfel` | O: 3/3; geprüft, ohne Befund |
| 33 | cheese / NOUN | Festes Lebensmittel aus Milch | `cheese#kase` | O: 3/3; geprüft, ohne Befund |
| 34 | egg / NOUN | Hühnerei als Lebensmittel | `egg#ei` | O: 3/3; geprüft, ohne Befund |
| 35 | money / NOUN | Zahlungsmittel für Einkäufe | `money#geld` | O: 3/3; geprüft, ohne Befund |
| 36 | office / NOUN | Raum für Schreibtischarbeit | `office#buero` | O: 3/3; geprüft, ohne Befund |
| 37 | desk / NOUN | Tisch zum Arbeiten oder Schreiben | `desk#schreibtisch` | O: 3/3; geprüft, ohne Befund |
| 38 | computer / NOUN | Elektronisches Gerät zum Verarbeiten von Daten | `computer#computer` | O: 3/3; geprüft, ohne Befund |
| 39 | meeting / NOUN | Verabredetes Gespräch mehrerer Personen bei der Arbeit | `meeting#besprechung` | O: 3/3; geprüft, ohne Befund |
| 40 | colleague / NOUN | Person, mit der man zusammenarbeitet | `colleague#kollege_oder_kollegin` | O: 3/3; geprüft, ohne Befund |
| 41 | letter / NOUN | Schriftliche Nachricht, die man an jemanden schickt; kein Buchstabe | `letter#brief` | O: 3/3; geprüft, ohne Befund |
| 42 | paper / NOUN | Dünnes Material zum Schreiben oder Drucken | `paper#papier` | O: 3/3; geprüft, ohne Befund |
| 43 | bus / NOUN | Großes Fahrzeug zur Beförderung vieler Fahrgäste | `bus#bus` | K: 3/3; bestätigte Korrektur erforderlich |
| 44 | train / NOUN | Schienenfahrzeug zur Beförderung von Reisenden | `train#zug` | O: 3/3; geprüft, ohne Befund |
| 45 | station / NOUN | Ort, an dem Züge halten und Reisende einsteigen | `station#bahnhof` | O: 3/3; geprüft, ohne Befund |
| 46 | ticket / NOUN | Beleg für die Berechtigung zu einer Fahrt | `ticket#fahrkarte` | O: 3/3; geprüft, ohne Befund |
| 47 | road / NOUN | Befestigter Verkehrsweg für Fahrzeuge | `road#strasse` | U: 3/3; unklarer redaktioneller Fall |
| 48 | bicycle / NOUN | Zweirädriges Fahrzeug mit Pedalantrieb | `bicycle#fahrrad` | O: 3/3; geprüft, ohne Befund |
| 49 | car / NOUN | Kraftfahrzeug für wenige Personen | `car#auto` | O: 3/3; geprüft, ohne Befund |
| 50 | bridge / NOUN | Bauwerk, das einen Weg über ein Hindernis führt | `bridge#brucke` | O: 3/3; geprüft, ohne Befund |
| 51 | map / NOUN | Zeichnung zur Orientierung in einem Gebiet | `map#karte` | O: 3/3; geprüft, ohne Befund |
| 52 | bandage / NOUN | Material zum Bedecken und Schützen einer Wunde; kein Verb | `bandage#verband` | O: 3/3; geprüft, ohne Befund |
| 53 | hand / NOUN | Körperteil am Ende eines Arms | `hand#hand` | O: 3/3; geprüft, ohne Befund |
| 54 | head / NOUN | Oberster Körperteil mit Gesicht und Gehirn | `head#kopf` | O: 3/3; geprüft, ohne Befund |
| 55 | eye / NOUN | Sinnesorgan zum Sehen | `eye#auge` | O: 3/3; geprüft, ohne Befund |
| 56 | foot / NOUN | Körperteil am unteren Ende eines Beins | `foot#fuss` | O: 3/3; geprüft, ohne Befund |
| 57 | arm / NOUN | Körperglied zwischen Schulter und Hand | `arm#arm` | O: 3/3; geprüft, ohne Befund |
| 58 | leg / NOUN | Körperglied zum Stehen und Gehen | `leg#bein` | O: 3/3; geprüft, ohne Befund |
| 59 | tooth / NOUN | Hartes Gebilde im Mund zum Kauen | `tooth#zahn` | O: 3/3; geprüft, ohne Befund |
| 60 | skin / NOUN | Äußere schützende Schicht des Körpers | `skin#haut` | O: 3/3; geprüft, ohne Befund |
| 61 | wash / VERB | Mit Wasser reinigen | `wash#waescht` | O: 3/3; geprüft, ohne Befund |
| 62 | cook / VERB | Essen durch Erhitzen zubereiten | `cook#kocht` | O: 3/3; geprüft, ohne Befund |
| 63 | clean / VERB | Schmutz von einem Gegenstand oder einer Fläche entfernen | `clean#putzen` | O: 3/3; geprüft, ohne Befund |
| 64 | open / VERB | Etwas bisher Geschlossenes zugänglich machen | `open#oeffnete` | O: 3/3; geprüft, ohne Befund |
| 65 | close / VERB | Etwas Offenes zumachen | `close#schliessen` | O: 3/3; geprüft, ohne Befund |
| 66 | repair / VERB | Etwas Beschädigtes wieder funktionsfähig machen | `repair#repariert` | O: 3/3; geprüft, ohne Befund |
| 67 | cut / VERB | Mit einer scharfen Klinge teilen | `cut#schneidet` | O: 3/3; geprüft, ohne Befund |
| 68 | buy / VERB | Eine Ware gegen Geld erwerben | `buy#kaufen` | O: 3/3; geprüft, ohne Befund |
| 69 | pay / VERB | Geld für eine Ware oder Leistung geben | `pay#bezahlt` | O: 3/3; geprüft, ohne Befund |
| 70 | sell / VERB | Eine Ware gegen Geld abgeben | `sell#verkaufen` | O: 3/3; geprüft, ohne Befund |
| 71 | choose / VERB | Sich zwischen mehreren Möglichkeiten entscheiden | `choose#waehlt-aus` | O: 3/3; geprüft, ohne Befund |
| 72 | drive / VERB | Ein Kraftfahrzeug steuern | `drive#faehrt` | O: 3/3; geprüft, ohne Befund |
| 73 | walk / VERB | Sich gehend fortbewegen | `walk#geht-zu-fuss` | O: 3/3; geprüft, ohne Befund |
| 74 | carry / VERB | Einen Gegenstand halten und mitnehmen | `carry#tragen` | O: 3/3; geprüft, ohne Befund |
| 75 | bring / VERB | Etwas zu einer Person oder an einen Ort tragen | `bring#bringt` | K: 3/3; bestätigte Korrektur erforderlich |
| 76 | wait / VERB | Bis zu einem erwarteten Ereignis bleiben | `wait#warten` | O: 3/3; geprüft, ohne Befund |
| 77 | read / VERB | Geschriebene Wörter erfassen | `read#lesen` | O: 3/3; geprüft, ohne Befund |
| 78 | write / VERB | Wörter schriftlich festhalten | `write#schreiben` | O: 3/3; geprüft, ohne Befund |
| 79 | send / VERB | Eine Nachricht an einen Empfänger übermitteln | `send#schicken` | K: 3/3; bestätigte Korrektur erforderlich |
| 80 | eat / VERB | Nahrung zu sich nehmen | `eat#essen` | O: 3/3; geprüft, ohne Befund |
| 81 | drink / VERB | Flüssigkeit zu sich nehmen | `drink#trinkt` | O: 3/3; geprüft, ohne Befund |
| 82 | sleep / VERB | Sich im natürlichen nächtlichen Ruhezustand befinden | `sleep#schlafen` | O: 3/3; geprüft, ohne Befund |
| 83 | stand / VERB | Mit aufrechtem Körper auf den Füßen sein | `stand#stehen` | O: 3/3; geprüft, ohne Befund |
| 84 | sit / VERB | Auf einem Sitz mit abgestütztem Gesäß ruhen | `sit#sitzen` | N: 0/3; Abbruchwelle, kein QA-Urteil |
| 85 | listen / VERB | Aufmerksam auf gehörte Sprache oder Geräusche achten | `listen#zuhoert` | O: 3/3; geprüft, ohne Befund |
| 86 | empty / ADJ | Ohne Inhalt | `empty#leer` | O: 3/3; geprüft, ohne Befund |
| 87 | full / ADJ | Bis zur verfügbaren Kapazität gefüllt | `full#vollen` | O: 3/3; geprüft, ohne Befund |
| 88 | dry / ADJ | Nicht nass | `dry#trocken` | O: 3/3; geprüft, ohne Befund |
| 89 | wet / ADJ | Mit Wasser oder anderer Flüssigkeit benetzt | `wet#nass` | N: 0/3; nach Abbruch nicht gestartet |
| 90 | soft / ADJ | Bei Druck leicht nachgebend | `soft#weiche` | N: 0/3; nach Abbruch nicht gestartet |
| 91 | hard / ADJ | Bei Druck kaum nachgebend | `hard#hart` | N: 0/3; nach Abbruch nicht gestartet |
| 92 | cheap / ADJ | Wenig Geld kostend | `cheap#billiger` | N: 0/3; nach Abbruch nicht gestartet |
| 93 | expensive / ADJ | Viel Geld kostend | `expensive#teuer` | N: 0/3; nach Abbruch nicht gestartet |
| 94 | young / ADJ | Erst wenige Lebensjahre alt | `young#jung` | N: 0/3; nach Abbruch nicht gestartet |
| 95 | old / ADJ | Schon viele Lebensjahre alt | `old#alt` | N: 0/3; nach Abbruch nicht gestartet |
| 96 | strong / ADJ | Viel körperliche Kraft besitzend | `strong#stark` | N: 0/3; nach Abbruch nicht gestartet |
| 97 | ready / ADJ | Für eine anstehende Handlung vorbereitet | `ready#bereit` | N: 0/3; nach Abbruch nicht gestartet |
| 98 | quiet / ADJ | Wenig Geräusche verursachend | `quiet#ruhig` | N: 0/3; nach Abbruch nicht gestartet |
| 99 | safe / ADJ | Keiner konkreten Gefahr ausgesetzt | `safe#sicher` | N: 0/3; nach Abbruch nicht gestartet |
| 100 | heavy / ADJ | Ein hohes Gewicht habend | `heavy#schwer` | N: 0/3; nach Abbruch nicht gestartet |

## Vollständiges Satz- und Alternativenprotokoll

Alle folgenden Texte wurden gelesen. Satzurteil „ohne Befund“ betrifft Original, deutsche Übersetzung, Zielform und Zielbedeutung; separat bezeichnete Alternativ- oder Glossbefunde bleiben wirksam. Jede Alternative wird exakt wie gespeichert, einschließlich Kleinschreibung, eingesetzt. Keine Alternativenliste wurde ergänzt.

### eat — O

Kartenreferenz `eat|eat/VERB|eat#essen`; ID `019d512cd5c76a816b21ddca06c1ed29`.

- **s1** / `79cb8f48ebb9cae27e9f061bef6684e6`; Lücke [21, 24), accepted `["eat"]`.
  EN: David, please do not eat chocolate while wearing your white shirt.
  DE: David, bitte iss keine Schokolade, während du dein weißes Hemd trägst.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s2** / `28ed88299cac6cf6173212e7d62b71ec`; Lücke [8, 11), accepted `["eat"]`.
  EN: Can Mia eat dinner with us at this Italian restaurant?
  DE: Kann Mia mit uns in diesem italienischen Restaurant zu Abend essen?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s3** / `3d7dee27dbff6f264d288b822f0f06d7`; Lücke [11, 14), accepted `["eat"]`.
  EN: You cannot eat snacks inside the quiet library, Nina.
  DE: Du darfst in der ruhigen Bibliothek keine Snacks essen, Nina.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### chair — O

Kartenreferenz `chair|chair/NOUN|chair#stuhl`; ID `0cf8270c351db5748cc41ade4e33a55c`.

- **s4** / `5221471cc8b6b0fb21d7762e202277aa`; Lücke [47, 52), accepted `["chair"]`.
  EN: Sofia put her warm jacket over the back of the chair.
  DE: Sofia legte ihre warme Jacke über die Lehne des Stuhls.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s5** / `462e6ef189508a163c462a5c2eef495a`; Lücke [14, 19), accepted `["chair"]`.
  EN: Is this empty chair for your grandfather, Luca?
  DE: Ist dieser freie Stuhl für deinen Großvater, Luca?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s6** / `2a9410784742018856ed16cac336fc94`; Lücke [32, 37), accepted `["chair"]`.
  EN: Please bring a comfortable desk chair into Elias's new office.
  DE: Bitte bringe einen bequemen Schreibtischstuhl in Elias' neues Büro.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### phone — K

Kartenreferenz `phone|phone/NOUN|phone#telefon`; ID `12c292f705a3be680124ab5662656a77`.

- **s7** / `b34332eceb3697e046b6fdaa21fd8f04`; Lücke [19, 24), accepted `["phone"]`.
  EN: Omar turns off his phone before he speaks to the doctor.
  DE: Omar schaltet sein Telefon aus, bevor er mit dem Arzt spricht.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s8** / `a07f6a220e98d122f6e04cdf05e24eb1`; Lücke [19, 24), accepted `["phone"]`.
  EN: Can you check your phone for a message from Lina?
  DE: Kannst du auf deinem Telefon nach einer Nachricht von Lina schauen?
  Satzurteil: ohne Befund.
  Alternative `cell phone` → Can you check your cell phone for a message from Lina?
  Alternativurteil: K — Verengt phone auf ein Mobiltelefon. Eine Nachricht kann auch über ein Festnetztelefon/Voicemail geprüft werden; der Originalsatz legt die Geräteart nicht fest..
  Alternative `mobile` → Can you check your mobile for a message from Lina?
  Alternativurteil: K — Wie cell phone: das Mobiltelefon wird zusätzlich festgelegt. Grammatisch korrekt, aber ohne belegten Mobilkontext nicht bedeutungsgleich..

- **s9** / `37426d44e38828d5aa04b529cbb94f7e`; Lücke [16, 21), accepted `["phone"]`.
  EN: Mia answers the phone every morning for the company.
  DE: Mia geht jeden Morgen für die Firma an das Telefon.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### cheese — O

Kartenreferenz `cheese|cheese/NOUN|cheese#kase`; ID `17a4dea84895e0cf93245d6e5a04e82d`.

- **s10** / `2c39881d00cf21c5b36dc4e1edc45aef`; Lücke [34, 40), accepted `["cheese"]`.
  EN: Amir cuts a small piece of yellow cheese for breakfast.
  DE: Amir schneidet ein kleines Stück gelben Käse zum Frühstück.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s11** / `f5ae0b42e58fc2bfeb30fe6695576d70`; Lücke [25, 31), accepted `["cheese"]`.
  EN: Zoe eats some bread with cheese during her picnic in the park.
  DE: Zoe isst während ihres Picknicks im Park etwas Brot mit Käse.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s12** / `b9f033284c6722c3f958fc9425051b50`; Lücke [20, 26), accepted `["cheese"]`.
  EN: Does Ali want extra cheese on his hot pasta?
  DE: Möchte Ali extra Käse auf seinen heißen Nudeln?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### pillow — O

Kartenreferenz `pillow|pillow/NOUN|pillow#kissen`; ID `1ae4248a5ab10837ed0540b216dee579`.

- **s13** / `a6252ed752cf8b5ed51101c09da605b2`; Lücke [20, 26), accepted `["pillow"]`.
  EN: Luis bought a smart pillow that tracks his sleep at night.
  DE: Luis kaufte ein intelligentes Kissen, das nachts seinen Schlaf aufzeichnet.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s14** / `a4af41fdc54758c0fa53f9f83ecbd12f`; Lücke [23, 29), accepted `["pillow"]`.
  EN: Can Luca have an extra pillow for his hotel bed?
  DE: Kann Luca ein zusätzliches Kissen für sein Hotelbett haben?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s15** / `823a4ad7967df948bc5002498007574a`; Lücke [20, 26), accepted `["pillow"]`.
  EN: Eva packed the soft pillow into a large cardboard box.
  DE: Eva packte das weiche Kissen in einen großen Karton.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### wash — O

Kartenreferenz `wash|wash/VERB|wash#waescht`; ID `1b99ac7d85eb8c5ab2134496b94a66d4`.

- **s16** / `c2c041028914df89e693e4f39e71a5a2`; Lücke [9, 13), accepted `["wash"]`.
  EN: Ben will wash the dirty garden chairs with water today.
  DE: Ben wird die schmutzigen Gartenstühle heute mit Wasser waschen.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s17** / `81f285c78779ff00289b9788a050dc8f`; Lücke [8, 12), accepted `["wash"]`.
  EN: Did Ali wash his hands before playing the piano?
  DE: Hat Ali sich vor dem Klavierspielen die Hände gewaschen?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s18** / `ff2908c37eb3d592678d788f1f61b300`; Lücke [17, 21), accepted `["wash"]`.
  EN: Please help Lina wash the muddy bicycles this afternoon.
  DE: Bitte hilf Lina heute Nachmittag, die schlammigen Fahrräder zu waschen.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### repair — O

Kartenreferenz `repair|repair/VERB|repair#repariert`; ID `1bb2600098a1ffb045fa8d3940fbb333`.

- **s19** / `0db27ed3e064a0dc59084e9ed386fa4f`; Lücke [14, 20), accepted `["repair"]`.
  EN: Maya wants to repair her broken bicycle for the busy city streets.
  DE: Maya möchte ihr kaputtes Fahrrad für die belebten Straßen der Stadt reparieren.
  Satzurteil: ohne Befund.
  Alternative `fix` → Maya wants to fix her broken bicycle for the busy city streets.
  Alternativurteil: ohne Befund: grammatisch passend, Aussage im Kontext erhalten.
  Alternative `mend` → Maya wants to mend her broken bicycle for the busy city streets.
  Alternativurteil: ohne Befund: grammatisch passend, Aussage im Kontext erhalten.

- **s20** / `12ac308000157c203669f6ab836b9911`; Lücke [12, 18), accepted `["repair"]`.
  EN: Can someone repair the ticket machine near Rosa soon?
  DE: Kann jemand bald den Fahrkartenautomaten in der Nähe von Rosa reparieren?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s21** / `f8b7df79839e7d7b34e1e7bf4dd202a5`; Lücke [7, 13), accepted `["repair"]`.
  EN: Please repair that loose chair leg quietly, Sofia.
  DE: Bitte repariere dieses lockere Stuhlbein leise, Sofia.
  Satzurteil: ohne Befund.
  Alternative `fix` → Please fix that loose chair leg quietly, Sofia.
  Alternativurteil: ohne Befund: grammatisch passend, Aussage im Kontext erhalten.
  Alternative `mend` → Please mend that loose chair leg quietly, Sofia.
  Alternativurteil: ohne Befund: grammatisch passend, Aussage im Kontext erhalten.

### shoe — O

Kartenreferenz `shoe|shoe/NOUN|shoe#schuhe`; ID `1de22c68ae13c64b606131fe81fb26cd`.

- **s22** / `39fdb16a7a368e4299ba7c0a95489b90`; Lücke [31, 35), accepted `["shoe"]`.
  EN: Maya ties the lace of her left shoe before class.
  DE: Maya bindet vor dem Unterricht den Schnürsenkel ihres linken Schuhs.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s23** / `1ab8b6165b5991afd2c1af42d119c440`; Lücke [15, 19), accepted `["shoe"]`.
  EN: Does this hard shoe hurt your foot, Emma?
  DE: Tut dieser harte Schuh deinem Fuß weh, Emma?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s24** / `db1132121d5d1570963be86bb4737264`; Lücke [19, 23), accepted `["shoe"]`.
  EN: Please remove each shoe before security, Maya.
  DE: Bitte ziehe vor der Sicherheitskontrolle jeden Schuh aus, Maya.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### leg — O

Kartenreferenz `leg|leg/NOUN|leg#bein`; ID `1de79a6ef0bc3a9e995524911c2162db`.

- **s25** / `d2a06de5150941919253418a89497ca3`; Lücke [45, 48), accepted `["leg"]`.
  EN: Lina fell on the cold ice and hurt her right leg.
  DE: Lina stürzte auf dem kalten Eis und verletzte sich ihr rechtes Bein.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s26** / `244eb0d45fcb6abca948f7c097e6504d`; Lücke [34, 37), accepted `["leg"]`.
  EN: Does Leo feel pain in his injured leg after walking the dog?
  DE: Hat Leo nach dem Gassigehen mit dem Hund Schmerzen in seinem verletzten Bein?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s27** / `7e54b7fbee2e7fed4c82214c19316a9f`; Lücke [30, 33), accepted `["leg"]`.
  EN: Elias cannot stretch his left leg under the low desk.
  DE: Elias kann sein linkes Bein unter dem niedrigen Schreibtisch nicht ausstrecken.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### bottle — O

Kartenreferenz `bottle|bottle/NOUN|bottle#flasche`; ID `1e00e17d5e790190ed95f01b5d2cb0f3`.

- **s28** / `6efe1a990c89bc2aaa7e7719d0b32d23`; Lücke [16, 22), accepted `["bottle"]`.
  EN: Leo buys a cold bottle of juice at the supermarket.
  DE: Leo kauft eine kalte Flasche Saft im Supermarkt.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s29** / `65900c025ff8dcccfa89ffba149eb542`; Lücke [25, 31), accepted `["bottle"]`.
  EN: Did David drop his water bottle on the grass?
  DE: Hat David seine Wasserflasche auf das Gras fallen lassen?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s30** / `7f126ac63b001cfd1f7d3dbc404ac3f4`; Lücke [16, 22), accepted `["bottle"]`.
  EN: Pack this empty bottle for our long flight, Luis.
  DE: Pack diese leere Flasche für unseren langen Flug ein, Luis.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### close — O

Kartenreferenz `close|close/VERB|close#schliessen`; ID `205f0f1f0f700fc4677f3d5a118d63b1`.

- **s31** / `df075e5880441b6858c2899726743dea`; Lücke [12, 17), accepted `["close"]`.
  EN: Leo, please close the front gate when you leave.
  DE: Leo, bitte schließe das Vordertor, wenn du gehst.
  Satzurteil: ohne Befund.
  Alternative `shut` → Leo, please shut the front gate when you leave.
  Alternativurteil: ohne Befund: grammatisch passend, Aussage im Kontext erhalten.

- **s32** / `576659a1c9e0fe1a1977389b0c937304`; Lücke [9, 14), accepted `["close"]`.
  EN: Can Maya close the window above her bus seat?
  DE: Kann Maya das Fenster über ihrem Bussitz schließen?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s33** / `6eb3945f7d3d6e66a88d5980690470e6`; Lücke [18, 23), accepted `["close"]`.
  EN: Amir and I always close the door behind us.
  DE: Amir und ich schließen immer die Tür hinter uns.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### buy — O

Kartenreferenz `buy|buy/VERB|buy#kaufen`; ID `211695c38c0a5270b39247c2486e0cfe`.

- **s34** / `1e83746c57a78a19d5bcab1ec3b4627f`; Lücke [14, 17), accepted `["buy"]`.
  EN: Sara wants to buy a cheap guitar for her music class.
  DE: Sara möchte eine günstige Gitarre für ihren Musikunterricht kaufen.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s35** / `aa816fa43c991c33eb7d47a0ae69881f`; Lücke [8, 11), accepted `["buy"]`.
  EN: Can Leo buy some notebooks at the school shop?
  DE: Kann Leo einige Hefte im Schulladen kaufen?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s36** / `aa4cc85cd881f7b50b7b6b71bbeac7f7`; Lücke [13, 16), accepted `["buy"]`.
  EN: Ali does not buy a bus ticket because he walks.
  DE: Ali kauft keine Busfahrkarte, weil er zu Fuß geht.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### table — O

Kartenreferenz `table|table/NOUN|table#tisch`; ID `253982ff9b64b28ab49f9ef47e56b2ff`.

- **s37** / `7d5a6e37c575acc6f3d270e26e22e29b`; Lücke [37, 42), accepted `["table"]`.
  EN: Zoe puts fresh flowers on the garden table.
  DE: Zoe stellt frische Blumen auf den Gartentisch.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s38** / `b0264ede675b95f2d3865ced7f5670ea`; Lücke [41, 46), accepted `["table"]`.
  EN: Can Luca put his bag under the small bus table?
  DE: Kann Luca seine Tasche unter den kleinen Bustisch stellen?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s39** / `355fd5d5276559f2e9ecb2fd5376137c`; Lücke [21, 26), accepted `["table"]`.
  EN: Sara sits at a quiet table in the library.
  DE: Sara sitzt an einem ruhigen Tisch in der Bibliothek.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### shop — O

Kartenreferenz `shop|shop/NOUN|shop#geschaeft`; ID `26466689d7e586f0c51b0f6e680077e0`.

- **s40** / `b9be7ebe034be74f5f4a83165c5bd502`; Lücke [39, 43), accepted `["shop"]`.
  EN: Ali asks for cold water at the airport shop.
  DE: Ali fragt am Flughafenladen nach kaltem Wasser.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s41** / `1d65cb6fd264885dca284aac7ea10616`; Lücke [23, 27), accepted `["shop"]`.
  EN: Luca visits the little shop next to the park.
  DE: Luca besucht das kleine Geschäft neben dem Park.
  Satzurteil: ohne Befund.
  Alternative `store` → Luca visits the little store next to the park.
  Alternativurteil: ohne Befund: grammatisch passend, Aussage im Kontext erhalten.

- **s42** / `b7728963b719c66d8a428b4e0751a9b5`; Lücke [30, 34), accepted `["shop"]`.
  EN: Mia walks to the local flower shop this morning.
  DE: Mia geht heute Morgen zum örtlichen Blumenladen.
  Satzurteil: ohne Befund.
  Alternative `store` → Mia walks to the local flower store this morning.
  Alternativurteil: ohne Befund: grammatisch passend, Aussage im Kontext erhalten.

### price — O

Kartenreferenz `price|price/NOUN|price#preis`; ID `2a6cbbf117832ec50f13b880ce16f902`.

- **s43** / `f6c5e6dd3202924ddcf3783f3a475c32`; Lücke [17, 22), accepted `["price"]`.
  EN: Elias thinks the price of this apple tree is very fair.
  DE: Elias findet den Preis dieses Apfelbaums sehr fair.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s44** / `2221a58ea32bd9ffd5dcbff4500e6fcb`; Lücke [29, 34), accepted `["price"]`.
  EN: Maya asked the baker for the price of the birthday cake.
  DE: Maya fragte den Bäcker nach dem Preis der Geburtstagstorte.
  Satzurteil: ohne Befund.
  Alternative `cost` → Maya asked the baker for the cost of the birthday cake.
  Alternativurteil: ohne Befund: grammatisch passend, Aussage im Kontext erhalten.

- **s45** / `a3687df54513ef8a4cccc3d5ba1c9885`; Lücke [12, 17), accepted `["price"]`.
  EN: What is the price of this medicine, Doctor Leo?
  DE: Wie hoch ist der Preis dieses Medikaments, Doktor Leo?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### write — O

Kartenreferenz `write|write/VERB|write#schreiben`; ID `32f136da7304bb82f793eeb8fdb48fd4`.

- **s46** / `bd261b3ae4da4e8c75aac79093b2cf66`; Lücke [14, 19), accepted `["write"]`.
  EN: Amir likes to write short stories on his laptop in his free time.
  DE: Amir schreibt in seiner Freizeit gerne Kurzgeschichten auf seinem Laptop.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s47** / `1aa02f3b61b87a63814f72ea43327679`; Lücke [7, 12), accepted `["write"]`.
  EN: Please write a kind postcard to Lina for her birthday.
  DE: Bitte schreibe Lina eine nette Postkarte zu ihrem Geburtstag.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s48** / `5813e714104a197073067f7de6ed3a1b`; Lücke [9, 14), accepted `["write"]`.
  EN: Can Maya write down the names of the plants in her notebook?
  DE: Kann Maya die Namen der Pflanzen in ihr Notizbuch aufschreiben?
  Satzurteil: ohne Befund.
  Alternative `jot` → Can Maya jot down the names of the plants in her notebook?
  Alternativurteil: ohne Befund: grammatisch passend, Aussage im Kontext erhalten.
  Alternative `note` → Can Maya note down the names of the plants in her notebook?
  Alternativurteil: ohne Befund: grammatisch passend, Aussage im Kontext erhalten.
  Alternative `put` → Can Maya put down the names of the plants in her notebook?
  Alternativurteil: ohne Befund: grammatisch passend, Aussage im Kontext erhalten.

### arm — O

Kartenreferenz `arm|arm/NOUN|arm#arm`; ID `3685c5177ca3849a0d68e81cd07a6815`.

- **s49** / `dbdadafec25b3b2ca30e11f4e0a0ad31`; Lücke [45, 48), accepted `["arm"]`.
  EN: Noah carries the long parcel under his right arm.
  DE: Noah trägt das lange Paket unter seinem rechten Arm.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s50** / `f977dcb85b086532fe08be248e8b5276`; Lücke [40, 43), accepted `["arm"]`.
  EN: Does Rosa wear a gold watch on her left arm?
  DE: Trägt Rosa eine goldene Uhr an ihrem linken Arm?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s51** / `d9e066edf2657f5e57c6dd6f55d0f9fc`; Lücke [11, 14), accepted `["arm"]`.
  EN: Raise your arm before throwing the ball, Leo!
  DE: Hebe deinen Arm, bevor du den Ball wirfst, Leo!
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### key — U

Kartenreferenz `key|key/NOUN|key#schluessel`; ID `370a358b45692dcb4810c3066bad9a1b`.

- **s52** / `dd3eb2206c8892669119ee8e0a55798f`; Lücke [18, 21), accepted `["key"]`.
  EN: Emma uses a metal key to open the server box.
  DE: Emma benutzt einen Metallschlüssel, um den Serverkasten zu öffnen.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s53** / `2b2b90918d944b984fcd138035038a4d`; Lücke [18, 21), accepted `["key"]`.
  EN: Did Lina hide the key to the gift box?
  DE: Hat Lina den Schlüssel zum Geschenkkarton versteckt?
  Satzurteil: U — gift box wird zu Geschenkkarton: Das Material Karton steht nicht im Original. Verschließbare Geschenkboxen sind möglich; vorsichtige Korrektur zu Geschenkbox erwägen, kein englischer Grammatikfehler..
  valid_alternatives: leer.

- **s54** / `abe28fb6d3569dcfbcd0483320468075`; Lücke [36, 39), accepted `["key"]`.
  EN: Sofia checks her jacket because the key to her house is missing.
  DE: Sofia prüft ihre Jacke, weil der Schlüssel zu ihrem Haus fehlt.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### paper — O

Kartenreferenz `paper|paper/NOUN|paper#papier`; ID `387125b38847ee46a3f5359fb9300b15`.

- **s55** / `5f7084c66c9410ac46435a1214e1b136`; Lücke [39, 44), accepted `["paper"]`.
  EN: Luca writes his symptoms on a sheet of paper.
  DE: Luca schreibt seine Symptome auf ein Blatt Papier.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s56** / `a55669e8fdfcdeecf4fc126ba13837e5`; Lücke [34, 39), accepted `["paper"]`.
  EN: Does Lina let her puppy play with paper?
  DE: Lässt Lina ihren Welpen mit Papier spielen?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s57** / `b8cc3f50fe0124139c19d4e8ef64cb79`; Lücke [20, 25), accepted `["paper"]`.
  EN: Omar folded a white paper plane for his best friend.
  DE: Omar faltete ein weißes Papierflugzeug für seinen besten Freund.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### pay — O

Kartenreferenz `pay|pay/VERB|pay#bezahlt`; ID `3a4febb432d220f62c6f1d4891e0a3ea`.

- **s58** / `fca10bea873cc67983eb429db3ed9536`; Lücke [9, 12), accepted `["pay"]`.
  EN: Luca can pay for the stamps with cash.
  DE: Luca kann die Briefmarken bar bezahlen.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s59** / `f026ec5960b3125cf011d582e5669227`; Lücke [14, 17), accepted `["pay"]`.
  EN: Amir wants to pay for his bus ticket with coins.
  DE: Amir möchte seine Busfahrkarte mit Münzen bezahlen.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s60** / `6bd9d23fa234be4026710ab2f0bc9ca5`; Lücke [9, 12), accepted `["pay"]`.
  EN: Leo will pay the bills before lunch.
  DE: Leo wird die Rechnungen vor dem Mittagessen bezahlen.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### kitchen — O

Kartenreferenz `kitchen|kitchen/NOUN|kitchen#kueche`; ID `3aae80c6c3cc7d7649c7501af614cbc2`.

- **s61** / `867a2fdd9890284f544d1eff0ebccc50`; Lücke [38, 45), accepted `["kitchen"]`.
  EN: Amir had a bad cut on his hand in the kitchen.
  DE: Amir hatte eine schlimme Schnittwunde an der Hand in der Küche.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s62** / `ce70af962b3d40cd167302ac569da27d`; Lücke [44, 51), accepted `["kitchen"]`.
  EN: Mia drinks her morning coffee in the office kitchen before working.
  DE: Mia trinkt ihren Morgenkaffee vor der Arbeit in der Büroküche.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s63** / `1e131414972e8c324d82ef5406093326`; Lücke [22, 29), accepted `["kitchen"]`.
  EN: Please help clean the kitchen floor after dinner today.
  DE: Bitte hilf heute nach dem Abendessen dabei, den Küchenboden zu putzen.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### money — O

Kartenreferenz `money|money/NOUN|money#geld`; ID `3c71a38fcd6ec62bb32d220c75ff93f3`.

- **s64** / `59cef7e69b16eac667d39f2eeebd6531`; Lücke [19, 24), accepted `["money"]`.
  EN: Sofia needs enough money to pay for her bus ticket.
  DE: Sofia braucht genug Geld, um ihre Busfahrkarte zu bezahlen.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s65** / `61b01cc120021746a4fa4a66433761e8`; Lücke [22, 27), accepted `["money"]`.
  EN: Does Omar have enough money to pay the bill?
  DE: Hat Omar genug Geld, um die Rechnung zu bezahlen?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s66** / `b68d2dfeecae9f63e7c3a07b83c1fbaa`; Lücke [18, 23), accepted `["money"]`.
  EN: Amir changed some money into local currency for the trip.
  DE: Amir wechselte für die Reise etwas Geld in die Landeswährung.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### map — O

Kartenreferenz `map|map/NOUN|map#karte`; ID `3e847869ac637857148cf0b3cb4ef7de`.

- **s67** / `1f8d73b50d6400bf12e19edfddf8d5c9`; Lücke [24, 27), accepted `["map"]`.
  EN: Ben looks at the street map to find the museum.
  DE: Ben schaut auf den Stadtplan, um das Museum zu finden.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s68** / `fab9aa6454893779283cac3315c84e71`; Lücke [39, 42), accepted `["map"]`.
  EN: Does Elias see our village on this old map?
  DE: Sieht Elias unser Dorf auf dieser alten Landkarte?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s69** / `9ee75fb25f8ed4aafc8e2620f86526aa`; Lücke [27, 30), accepted `["map"]`.
  EN: The wind blew Nina's paper map into the lake.
  DE: Der Wind wehte Ninas Papierkarte in den See.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### empty — O

Kartenreferenz `empty|empty/ADJ|empty#leer`; ID `4072954e2fdaa2585e02307a54d4d4f0`.

- **s70** / `b2641faac6c0b24e4b3d603d22b04d08`; Lücke [28, 33), accepted `["empty"]`.
  EN: Sara plays the guitar in an empty concert hall.
  DE: Sara spielt die Gitarre in einer leeren Konzerthalle.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s71** / `a0c02bd2b9c5bc48e5e8eb8905880552`; Lücke [29, 34), accepted `["empty"]`.
  EN: The sports bag is completely empty before the training.
  DE: Die Sporttasche ist vor dem Training völlig leer.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s72** / `491a638046dfef96f57b65f28eb27058`; Lücke [39, 44), accepted `["empty"]`.
  EN: Amir throws the dirty clothes into the empty basket.
  DE: Amir wirft die schmutzige Kleidung in den leeren Korb.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### choose — O

Kartenreferenz `choose|choose/VERB|choose#waehlt-aus`; ID `45e5fac61f28be5ea8055b1ea3b1fc4a`.

- **s73** / `97957cf10a4b0c9de511bbd9b8aaf02e`; Lücke [13, 19), accepted `["choose"]`.
  EN: Mia wants to choose a healthy snack instead of cake.
  DE: Mia möchte einen gesunden Snack anstelle von Kuchen auswählen.
  Satzurteil: ohne Befund.
  Alternative `pick` → Mia wants to pick a healthy snack instead of cake.
  Alternativurteil: ohne Befund: grammatisch passend, Aussage im Kontext erhalten.
  Alternative `select` → Mia wants to select a healthy snack instead of cake.
  Alternativurteil: ohne Befund: grammatisch passend, Aussage im Kontext erhalten.

- **s74** / `f602c91154244b0c2054dc0412351c35`; Lücke [21, 27), accepted `["choose"]`.
  EN: Which meal will Omar choose from the dinner menu?
  DE: Welches Gericht wird Omar aus der Abendkarte auswählen?
  Satzurteil: ohne Befund.
  Alternative `select` → Which meal will Omar select from the dinner menu?
  Alternativurteil: ohne Befund: grammatisch passend, Aussage im Kontext erhalten.

- **s75** / `03b0e61153785bb96b6eae33721562f0`; Lücke [7, 13), accepted `["choose"]`.
  EN: Please choose a board game for our game night, Nina.
  DE: Bitte wähle ein Brettspiel für unseren Spieleabend aus, Nina.
  Satzurteil: ohne Befund.
  Alternative `pick` → Please pick a board game for our game night, Nina.
  Alternativurteil: ohne Befund: grammatisch passend, Aussage im Kontext erhalten.
  Alternative `select` → Please select a board game for our game night, Nina.
  Alternativurteil: ohne Befund: grammatisch passend, Aussage im Kontext erhalten.

### wait — O

Kartenreferenz `wait|wait/VERB|wait#warten`; ID `47eed138e4bf09bff6135f5b3993dd1a`.

- **s76** / `1a75936d9dcd4cff5f41b50b9ac853d5`; Lücke [10, 14), accepted `["wait"]`.
  EN: David can wait for his friends in the park.
  DE: David kann im Park auf seine Freunde warten.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s77** / `f0a680c4c0f3c6e1b62afa56e3ed0587`; Lücke [7, 11), accepted `["wait"]`.
  EN: Please wait here while Emma unlocks the door.
  DE: Bitte warten Sie hier, während Emma die Tür aufschließt.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s78** / `413e91fac6d80c617590c6caed0b9b2d`; Lücke [10, 14), accepted `["wait"]`.
  EN: Does Rosa wait near the museum entrance?
  DE: Wartet Rosa in der Nähe des Museumseingangs?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### road — U

Kartenreferenz `road|road/NOUN|road#strasse`; ID `4a30a152f12d45bcfbf798afcb11101c`.

- **s79** / `c5c3ae22a17f2628f7b0b8429acd4469`; Lücke [34, 38), accepted `["road"]`.
  EN: Sara can see heavy traffic on the road from her office window.
  DE: Sara kann von ihrem Bürofenster aus dichten Verkehr auf der Straße sehen.
  Satzurteil: ohne Befund.
  Alternative `street` → Sara can see heavy traffic on the street from her office window.
  Alternativurteil: U — road ist allgemeiner als street. Der Kontext mit Bürofenster macht eine Stadtstraße plausibel, legt sie aber nicht fest; redaktionell über die zulässige Kontextgleichheit entscheiden..

- **s80** / `b223945a912afc18e6be8473e63e6a5b`; Lücke [51, 55), accepted `["road"]`.
  EN: Ben walked out of the station and crossed the busy road.
  DE: Ben ging aus dem Bahnhof und überquerte die belebte Straße.
  Satzurteil: ohne Befund.
  Alternative `street` → Ben walked out of the station and crossed the busy street.
  Alternativurteil: U — Auch eine belebte Straße vor einem Bahnhof muss nicht als street eingeordnet sein. Häufig synonym verwendbar, deshalb kein pauschales Sprachfehlerurteil; Bedeutungsumfang redaktionell klären..

- **s81** / `2e1b58b20bba1b3aff592e2611b7ea4c`; Lücke [48, 52), accepted `["road"]`.
  EN: Did David park his car on the other side of the road?
  DE: Hat David sein Auto auf der anderen Straßenseite geparkt?
  Satzurteil: ohne Befund.
  Alternative `street` → Did David park his car on the other side of the street?
  Alternativurteil: U — Straßenseite und Parken passen zu beiden Wörtern. street kann dennoch eine bebaute Straße enger festlegen; Grenzfall der geforderten Aussagegleichheit..

### towel — O

Kartenreferenz `towel|towel/NOUN|towel#handtuch`; ID `4dce0407ccf925e94e0a2a58dacb9e1e`.

- **s82** / `ec7b3d239c2e090412770863961168af`; Lücke [18, 23), accepted `["towel"]`.
  EN: Ali hangs the wet towel in the bathroom.
  DE: Ali hängt das nasse Handtuch im Badezimmer auf.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s83** / `107e531a87e9ac6d57387d9f45ceb650`; Lücke [23, 28), accepted `["towel"]`.
  EN: Can you bring me a dry towel, Zoe?
  DE: Kannst du mir ein trockenes Handtuch bringen, Zoe?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s84** / `c33b0712b7c3e2ecf15a1ba06d28140e`; Lücke [34, 39), accepted `["towel"]`.
  EN: Omar dries his hands with the red towel after washing them.
  DE: Omar trocknet seine Hände nach dem Waschen mit dem roten Handtuch ab.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### bed — O

Kartenreferenz `bed|bed/NOUN|bed#bett`; ID `4e59cd605e05b2aad64a5b565e42ce29`.

- **s85** / `b9b5909756851b5b9671fd4cd119de24`; Lücke [30, 33), accepted `["bed"]`.
  EN: Amir found a very comfortable bed in his small hotel room.
  DE: Amir fand ein sehr bequemes Bett in seinem kleinen Hotelzimmer.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s86** / `b77d476c7907865f7566dff7e24db2b4`; Lücke [29, 32), accepted `["bed"]`.
  EN: Does the cat sleep in a warm bed, Lina?
  DE: Schläft die Katze in einem warmen Bett, Lina?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s87** / `faedb2fc4c360aa2d74f04214b3085ec`; Lücke [17, 20), accepted `["bed"]`.
  EN: Leo needs a soft bed because he is tired after the long meeting.
  DE: Leo braucht ein weiches Bett, weil er nach der langen Besprechung müde ist.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### mirror — O

Kartenreferenz `mirror|mirror/NOUN|mirror#spiegel`; ID `5357749074d3de5f4542f7b15e98a1b2`.

- **s88** / `9f496e4a7a45abc306506dbc98465844`; Lücke [37, 43), accepted `["mirror"]`.
  EN: Nina checks her hair in the restroom mirror before dinner.
  DE: Nina überprüft vor dem Abendessen ihre Haare im Toilettenspiegel.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s89** / `6b33cc8541307261c3d8920a0f71b818`; Lücke [45, 51), accepted `["mirror"]`.
  EN: Does Ali's cat like to look at itself in the mirror?
  DE: Schaut sich Alis Katze gerne selbst im Spiegel an?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s90** / `8548966eed6924b9a9f8778acbd87d29`; Lücke [50, 56), accepted `["mirror"]`.
  EN: Maya receives a fragile box that contains a glass mirror.
  DE: Maya erhält ein zerbrechliches Paket, das einen Glasspiegel enthält.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### speaker — O

Kartenreferenz `speaker|speaker/NOUN|speaker#lautsprecher`; ID `5378cac79a552400aea06fd80a4ca9ac`.

- **s91** / `90a691cf55fca02d7684d1a1fce6b8e8`; Lücke [19, 26), accepted `["speaker"]`.
  EN: Sofia connects the speaker to the computer for the English listening test.
  DE: Sofia schließt den Lautsprecher für den Englisch-Hörtest an den Computer an.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s92** / `13edca299ce52539a5e958bc0e9a6ce0`; Lücke [28, 35), accepted `["speaker"]`.
  EN: Can Lina pack this wireless speaker into her suitcase?
  DE: Kann Lina diesen kabellosen Lautsprecher in ihren Koffer packen?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s93** / `9cb07f29a091a879f10c665ba6634d18`; Lücke [28, 35), accepted `["speaker"]`.
  EN: A nurse tells Sara that the speaker in the waiting room is broken.
  DE: Eine Krankenschwester sagt Sara, dass der Lautsprecher im Wartezimmer kaputt ist.
  Satzurteil: ohne Befund.
  Alternative `loudspeaker` → A nurse tells Sara that the loudspeaker in the waiting room is broken.
  Alternativurteil: ohne Befund: grammatisch passend, Aussage im Kontext erhalten.

### meeting — O

Kartenreferenz `meeting|meeting/NOUN|meeting#besprechung`; ID `5420125806d3b55a44b32bfabcc971da`.

- **s94** / `95182c3d9bf7156894a9feae4ba2777c`; Lücke [28, 35), accepted `["meeting"]`.
  EN: Noah has an important staff meeting at the clinic today.
  DE: Noah hat heute eine wichtige Teambesprechung in der Klinik.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s95** / `6f444db647e22f71f8c7d9a07c2639bd`; Lücke [23, 30), accepted `["meeting"]`.
  EN: Can Rosa join our team meeting before the football match?
  DE: Kann Rosa vor dem Fußballspiel an unserer Teambesprechung teilnehmen?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s96** / `423a58cbd28c0853d81514ba8bb6d86b`; Lücke [39, 46), accepted `["meeting"]`.
  EN: Maya prepared the room for the morning meeting with the boss.
  DE: Maya hat den Raum für die morgendliche Besprechung mit dem Chef vorbereitet.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### basket — U

Kartenreferenz `basket|basket/NOUN|basket#korb`; ID `56b49b92c0c28ca1f8d906c540ee949e`.

- **s97** / `0ff4e8aaa08e4ec3ff67e18823712d4b`; Lücke [21, 27), accepted `["basket"]`.
  EN: Noah fills the heavy basket with fresh apples on the kitchen counter.
  DE: Noah füllt den schweren Korb auf der Küchenarbeitsplatte mit frischen Äpfeln.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s98** / `51728bacf7c7b1a6ed653ab842171c06`; Lücke [49, 55), accepted `["basket"]`.
  EN: Did Ali carry his tennis balls to the court in a basket?
  DE: Hat Ali seine Tennisbälle in einem Korb zum Platz getragen?
  Satzurteil: U — Tenniskorb: gleiche allgemeine Korbbedeutung, aber die explizite Auswahldefinition beschränkt sich auf das Tragen von Einkäufen. Klären, ob die Zweckangabe nur ein Beispiel sein soll; Auswahl hier nicht geändert..
  valid_alternatives: leer.

- **s99** / `2fad4f8ab73703a94d7a692d4ced82e1`; Lücke [29, 35), accepted `["basket"]`.
  EN: Omar takes the large laundry basket down the stairs every Saturday.
  DE: Omar bringt jeden Samstag den großen Wäschekorb die Treppe hinunter.
  Satzurteil: U — Wäschekorb: gleiche allgemeine Korbbedeutung, aber nicht der in der Auswahl ausdrücklich genannte Einkaufszweck. Keine zusätzliche Sense-ID; redaktionelle Zielabgrenzung offen..
  valid_alternatives: leer.

### full — O

Kartenreferenz `full|full/ADJ|full#vollen`; ID `61ec48794256dc40ace9d3afda5f4eb4`.

- **s100** / `fbdda583b4132b0208cca03245701fb1`; Lücke [28, 32), accepted `["full"]`.
  EN: Is the birthday box already full of sweet candies, Leo?
  DE: Ist die Geburtstagskiste schon voll mit süßen Bonbons, Leo?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s101** / `396577872f595cecda14ac6a6f28caa7`; Lücke [50, 54), accepted `["full"]`.
  EN: Maya, please take out the trash can because it is full.
  DE: Maya, bring bitte den Mülleimer raus, weil er voll ist.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s102** / `9e92959ef8779ce4e923fe627908241d`; Lücke [14, 18), accepted `["full"]`.
  EN: Emma's car is full of bags for our big family picnic.
  DE: Emmas Auto ist voll mit Taschen für unser großes Familienpicknick.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### milk — O

Kartenreferenz `milk|milk/NOUN|milk#milch`; ID `63ff7ac41392c2699ac383798c93c713`.

- **s103** / `1e5a1efd217232d14112485864a5f4ac`; Lücke [17, 21), accepted `["milk"]`.
  EN: Mia drinks fresh milk before she practices the piano.
  DE: Mia trinkt frische Milch, bevor sie Klavier übt.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s104** / `c3569a22e5bbd25c71321043a1342413`; Lücke [19, 23), accepted `["milk"]`.
  EN: Does Eva drink cow milk to keep her bones strong?
  DE: Trinkt Eva Kuhmilch, um ihre Knochen stark zu halten?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s105** / `e78c29de99e6d1fc0b6748a3e8d6baf2`; Lücke [16, 20), accepted `["milk"]`.
  EN: Lina pours cold milk into the breakfast bowls for her children.
  DE: Lina gießt kalte Milch in die Frühstücksschüsseln für ihre Kinder.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### foot — O

Kartenreferenz `foot|foot/NOUN|foot#fuss`; ID `6598d23c3554d5e103e37e9dbf76c260`.

- **s106** / `8732e58b433bafb0cd2613353e69037c`; Lücke [19, 23), accepted `["foot"]`.
  EN: Luis hurt his left foot while hiking on the beach.
  DE: Luis hat sich beim Wandern am Strand den linken Fuß verletzt.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s107** / `ab1fcd38dadaef2593fdc1622cf59b6e`; Lücke [19, 23), accepted `["foot"]`.
  EN: Mia taps her right foot to the beat of the song.
  DE: Mia wippt mit ihrem rechten Fuß zum Takt des Liedes.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s108** / `e92b0495b33015e0c0f0a1a9411945e7`; Lücke [46, 50), accepted `["foot"]`.
  EN: Did Sofia drop the heavy book directly on her foot?
  DE: Hat Sofia das schwere Buch direkt auf ihren Fuß fallen lassen?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### bus — K

Kartenreferenz `bus|bus/NOUN|bus#bus`; ID `6622d48746ef8346cf9dc8c89e2ec925`.

- **s109** / `cc9ef16a674258c066e717f09e941f4c`; Lücke [45, 48), accepted `["bus"]`.
  EN: Leo looks out the window and watches the big bus arrive outside.
  DE: Leo schaut aus dem Fenster und sieht den großen Bus draußen ankommen.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s110** / `da38eaccda844e17d25cc1967397b876`; Lücke [49, 52), accepted `["bus"]`.
  EN: Ali waits near the restaurant entrance until his bus arrives.
  DE: Ali wartet in der Nähe des Restauranteingangs, bis sein Bus ankommt.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s111** / `25c8cfe5a4b06c3ad669cf82773ec4e1`; Lücke [23, 26), accepted `["bus"]`.
  EN: Can Zoe track the next bus on her mobile phone?
  DE: Kann Zoe den nächsten Bus auf ihrem Handy verfolgen?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### car — O

Kartenreferenz `car|car/NOUN|car#auto`; ID `66a5bca32470bdc87ddd6e16532db817`.

- **s112** / `50483f03a798268cef2867dcc3797bce`; Lücke [15, 18), accepted `["car"]`.
  EN: Ben drives his car to the beach for a summer holiday.
  DE: Ben fährt mit seinem Auto für einen Sommerurlaub an den Strand.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s113** / `0c47b09e2d07bdce20547f842c4c864e`; Lücke [21, 24), accepted `["car"]`.
  EN: Does Ali wait in the car outside the station entrance?
  DE: Wartet Ali im Auto vor dem Bahnhofseingang?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s114** / `c3f08bb7bc34fc989a167be0f927a2fd`; Lücke [52, 55), accepted `["car"]`.
  EN: Lina does not leave her heavy tennis bag inside the car.
  DE: Lina lässt ihre schwere Tennistasche nicht im Auto.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### lamp — U

Kartenreferenz `lamp|lamp/NOUN|lamp#lampen`; ID `6a39e160dd22cc901a4c11fd038313ee`.

- **s115** / `019cd393f273025ec805aa7920f88d58`; Lücke [21, 25), accepted `["lamp"]`.
  EN: Lina switches on the lamp above the cooking stove.
  DE: Lina schaltet die Lampe über dem Herd ein.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s116** / `53489ff73bdebe6da16b4a4580509ef0`; Lücke [24, 28), accepted `["lamp"]`.
  EN: Did Luca see the bright lamp in the front garden?
  DE: Hat Luca die helle Lampe im Vorgarten gesehen?
  Satzurteil: U — Lampe im Vorgarten statt Raumbeleuchtung der expliziten Auswahldefinition. Natürliches Englisch und passende Übersetzung; unklar ist allein die beabsichtigte Reichweite der Zieldefinition..
  valid_alternatives: leer.

- **s117** / `2b98505e63d3e076923c26d66ad8c931`; Lücke [26, 30), accepted `["lamp"]`.
  EN: Please turn off the floor lamp before leaving the house.
  DE: Bitte schalte die Stehlampe aus, bevor du das Haus verlässt.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### letter — O

Kartenreferenz `letter|letter/NOUN|letter#brief`; ID `6ad91923af7eae4a68118fe6476b72fa`.

- **s118** / `c40c0f04baafeed92c40586b6b5ca4ac`; Lücke [24, 30), accepted `["letter"]`.
  EN: Noah signs the official letter for his new boss.
  DE: Noah unterschreibt den offiziellen Brief für seinen neuen Chef.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s119** / `12e939d2fa65b0df9707cca18e56ce71`; Lücke [28, 34), accepted `["letter"]`.
  EN: Did Mia send that important letter with a stamp?
  DE: Hat Mia diesen wichtigen Brief mit einer Briefmarke verschickt?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s120** / `f7f9cf5a6017eb328386af138a36f15b`; Lücke [15, 21), accepted `["letter"]`.
  EN: Zoe prints the letter before her printer stops working.
  DE: Zoe druckt den Brief aus, bevor ihr Drucker aufhört zu funktionieren.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### shirt — O

Kartenreferenz `shirt|shirt/NOUN|shirt#hemd`; ID `6b004d82e00ace7361a157cf4a37266d`.

- **s121** / `c66f25bc5ae13f1cdd3ad82d068dc484`; Lücke [27, 32), accepted `["shirt"]`.
  EN: Noah buys an elegant white shirt with long sleeves.
  DE: Noah kauft ein elegantes weißes Hemd mit langen Ärmeln.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s122** / `9382e76d44d3c70ec48ab685bf1edfb2`; Lücke [47, 52), accepted `["shirt"]`.
  EN: The playful cat scratched the collar of Luis's shirt.
  DE: Die verspielte Katze hat den Kragen von Luis' Hemd zerkratzt.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s123** / `3f671668ed569d2c00a4e5604884fc76`; Lücke [20, 25), accepted `["shirt"]`.
  EN: Ali removes his wet shirt after the long tennis match.
  DE: Ali zieht sein nasses Hemd nach dem langen Tennisspiel aus.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### walk — O

Kartenreferenz `walk|walk/VERB|walk#geht-zu-fuss`; ID `6b2c46748fa80622ecc9ae31fe160077`.

- **s124** / `e61061e23b10d1d5ff4b8ed61fc42c8c`; Lücke [13, 17), accepted `["walk"]`.
  EN: Noah, please walk quietly inside the library.
  DE: Noah, bitte geh leise in der Bibliothek.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s125** / `4d1c172995d11fee7b8a382fc3a069f9`; Lücke [9, 13), accepted `["walk"]`.
  EN: Can Sara walk comfortably in these new shoes?
  DE: Kann Sara in diesen neuen Schuhen bequem gehen?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s126** / `5b1683602f0001dcb5dde6b1e2688c01`; Lücke [10, 14), accepted `["walk"]`.
  EN: Rosa will walk instead of driving to the post office.
  DE: Rosa wird zu Fuß zur Post gehen, anstatt mit dem Auto zu fahren.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### sell — O

Kartenreferenz `sell|sell/VERB|sell#verkaufen`; ID `736332b406fe61711b20b567c18066f7`.

- **s127** / `663a76f713552265b6507380a1ad0d18`; Lücke [29, 33), accepted `["sell"]`.
  EN: Amir and his parents want to sell their old car.
  DE: Amir und seine Eltern wollen ihr altes Auto verkaufen.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s128** / `2da3eacfddd8ff71576ca94962fe5f4d`; Lücke [21, 25), accepted `["sell"]`.
  EN: Luca and his brother sell old books to their neighbors every weekend.
  DE: Luca und sein Bruder verkaufen jedes Wochenende alte Bücher an ihre Nachbarn.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s129** / `a0cc175e081ab0bf25ae63b56202ec4a`; Lücke [13, 17), accepted `["sell"]`.
  EN: David cannot sell these computers without permission from the manager.
  DE: David kann diese Computer nicht ohne die Erlaubnis des Geschäftsführers verkaufen.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### dry — O

Kartenreferenz `dry|dry/ADJ|dry#trocken`; ID `83733c31e4ffa7e7a8fa6f20be312cba`.

- **s130** / `2341d8b24296470dde78ef959b1d24e0`; Lücke [33, 36), accepted `["dry"]`.
  EN: Maya hopes the weather will stay dry during her trip.
  DE: Maya hofft, dass das Wetter während ihrer Reise trocken bleibt.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s131** / `0cdec451613984e7e2cf8cec2e995709`; Lücke [46, 49), accepted `["dry"]`.
  EN: The streets in the city center are completely dry after the rain.
  DE: Die Straßen im Stadtzentrum sind nach dem Regen völlig trocken.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s132** / `a6753819b2cdde6c3dfc2ab4f35f4c80`; Lücke [35, 38), accepted `["dry"]`.
  EN: Sara wants to know if her shirt is dry yet.
  DE: Sara möchte wissen, ob ihr Hemd schon trocken ist.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### skin — O

Kartenreferenz `skin|skin/NOUN|skin#haut`; ID `83c4f79765c71b622fe3fc2aaaf8fa24`.

- **s133** / `16e6f9fa66ef2805f618ea6bb9d2626c`; Lücke [20, 24), accepted `["skin"]`.
  EN: Cold wind makes the skin on Ali's face very dry.
  DE: Kalter Wind macht die Haut in Alis Gesicht sehr trocken.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s134** / `215750c7f4bbab15b15fb91d893dc52c`; Lücke [41, 45), accepted `["skin"]`.
  EN: Cardboard packages scratch the sensitive skin on Sofia's hands.
  DE: Papppakete zerkratzen die empfindliche Haut an Sofias Händen.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s135** / `ccf7d5bb8f655d2da81aeec711412c98`; Lücke [45, 49), accepted `["skin"]`.
  EN: Does Sara wear gloves at work to protect her skin?
  DE: Trägt Sara bei der Arbeit Handschuhe, um ihre Haut zu schützen?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### bread — O

Kartenreferenz `bread|bread/NOUN|bread#brot`; ID `841bdc788655fc1ee5de13aba07090e3`.

- **s136** / `c70274cfb0c148e5a245b17a1db883fb`; Lücke [42, 47), accepted `["bread"]`.
  EN: Maya asks the doctor if she can eat white bread.
  DE: Maya fragt den Arzt, ob sie Weißbrot essen darf.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s137** / `89014fbe3abda2057851926be5fdfa9a`; Lücke [16, 21), accepted `["bread"]`.
  EN: Eva bakes fresh bread for the family picnic on Sunday.
  DE: Eva backt frisches Brot für das Familienpicknick am Sonntag.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s138** / `cf13abd5d49b079cc0e4b0698689145a`; Lücke [24, 29), accepted `["bread"]`.
  EN: Did Leo taste the local bread in France during his trip?
  DE: Hat Leo während seiner Reise das einheimische Brot in Frankreich probiert?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### blanket — O

Kartenreferenz `blanket|blanket/NOUN|blanket#decke`; ID `8758fb0569b8bbbb4f59edb34ee08b93`.

- **s139** / `0aaeb9083d15d693d71e0e318d7ee7fd`; Lücke [17, 24), accepted `["blanket"]`.
  EN: Rosa puts a warm blanket over her sleeping daughter.
  DE: Rosa legt eine warme Decke über ihre schlafende Tochter.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s140** / `35704b8b1a0b29b920f1d52ea247056f`; Lücke [40, 47), accepted `["blanket"]`.
  EN: Can Amir ask the flight attendant for a blanket?
  DE: Kann Amir die Flugbegleiterin nach einer Decke fragen?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s141** / `06969cb629e98e2b33c671c4e98717d5`; Lücke [20, 27), accepted `["blanket"]`.
  EN: Luca spreads a soft blanket on the green grass.
  DE: Luca breitet eine weiche Decke auf dem grünen Gras aus.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### cup — O

Kartenreferenz `cup|cup/NOUN|cup#tasse`; ID `89cfa341419a35011a272d57fa5d27ed`.

- **s142** / `b6338c97174b150c3e87b1fbae72f222`; Lücke [18, 21), accepted `["cup"]`.
  EN: Lina sets a clean cup and saucer on her dining table.
  DE: Lina stellt eine saubere Tasse und Untertasse auf ihren Esstisch.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s143** / `bda67ba9d7db42862bd8c50a7273db8d`; Lücke [23, 26), accepted `["cup"]`.
  EN: Can Luis carry his hot cup of coffee onto the bus?
  DE: Kann Luis seine heiße Tasse Kaffee mit in den Bus nehmen?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s144** / `0c415fc41215a72cad44035f0ac22917`; Lücke [24, 27), accepted `["cup"]`.
  EN: Noah washed every dirty cup and plate after breakfast.
  DE: Noah hat nach dem Frühstück jede schmutzige Tasse und jeden Teller abgewaschen.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### send — K

Kartenreferenz `send|send/VERB|send#schicken`; ID `8e33bb3900e1cdba8463b770b9a78b77`.

- **s145** / `efdb7f0904555d57603d77f65d096cc3`; Lücke [10, 14), accepted `["send"]`.
  EN: Rosa will send an email about the tennis match.
  DE: Rosa wird eine E-Mail über das Tennisspiel schicken.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s146** / `2eeca48989194c550818cc608869d2a1`; Lücke [8, 12), accepted `["send"]`.
  EN: Can you send a birthday card to Rosa?
  DE: Kannst du eine Geburtstagskarte an Rosa schicken?
  Satzurteil: ohne Befund.
  Alternative `mail` → Can you mail a birthday card to Rosa?
  Alternativurteil: K — Legt postalischen Versand fest; send lässt den Übermittlungsweg offen, auch bei einer Geburtstagskarte. Die allgemeinere deutsche Übersetzung beseitigt diese Einschränkung nicht..

- **s147** / `10687466c7d128c260bb4a511df16a1c`; Lücke [13, 17), accepted `["send"]`.
  EN: Amir did not send the message about his new jacket.
  DE: Amir hat die Nachricht über seine neue Jacke nicht geschickt.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### spoon — O

Kartenreferenz `spoon|spoon/NOUN|spoon#loeffel`; ID `947e1ddef2e388db4b92194cc85598f4`.

- **s148** / `d4b6ee0b9bd825fb61971f3c87fe0c0a`; Lücke [44, 49), accepted `["spoon"]`.
  EN: David eats his vegetable soup with a silver spoon.
  DE: David isst seine Gemüsesuppe mit einem Silberlöffel.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s149** / `623c02dc73062b5691d7515c47a233d3`; Lücke [22, 27), accepted `["spoon"]`.
  EN: Elias drops his metal spoon onto the grass.
  DE: Elias lässt seinen Metalllöffel auf das Gras fallen.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s150** / `c3e893be0af777a5e480b7a6b5ae099c`; Lücke [13, 18), accepted `["spoon"]`.
  EN: Lina needs a spoon for her fruit yogurt today.
  DE: Lina braucht heute einen Löffel für ihren Fruchtjoghurt.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### open — O

Kartenreferenz `open|open/VERB|open#oeffnete`; ID `9a1a28a337cefdbf11bceb185b271668`.

- **s151** / `37040d66709db38364b17a7963e20bc1`; Lücke [9, 13), accepted `["open"]`.
  EN: Luca can open the computer case with a screwdriver.
  DE: Luca kann das Computergehäuse mit einem Schraubenzieher öffnen.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s152** / `510262439ac42552d9e590b21b5bc8d4`; Lücke [12, 16), accepted `["open"]`.
  EN: Zoe, please open the wine bottle for our guests.
  DE: Zoe, bitte öffne die Weinflasche für unsere Gäste.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s153** / `51531d1e27427009a5174af71fa2bbd4`; Lücke [11, 15), accepted `["open"]`.
  EN: Elias must open his mouth so the doctor can check his throat.
  DE: Elias muss den Mund aufmachen, damit der Arzt seinen Hals untersuchen kann.
  Satzurteil: ohne Befund.
  Alternative `open up` → Elias must open up his mouth so the doctor can check his throat.
  Alternativurteil: ohne Befund: grammatisch passend, Aussage im Kontext erhalten.

### computer — O

Kartenreferenz `computer|computer/NOUN|computer#computer`; ID `9f7e09b6c7a04b306115db9d439e33af`.

- **s154** / `ef54f583a56f60795e4f9e3d398e3560`; Lücke [32, 40), accepted `["computer"]`.
  EN: Rosa reads health advice on her computer every morning.
  DE: Rosa liest jeden Morgen Gesundheitstipps auf ihrem Computer.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s155** / `8e3a2bd21fccff4f91fb308995cf4807`; Lücke [23, 31), accepted `["computer"]`.
  EN: Can Leo use the public computer to search for books?
  DE: Kann Leo den öffentlichen Computer benutzen, um nach Büchern zu suchen?
  Satzurteil: ohne Befund.
  Alternative `pc` → Can Leo use the public pc to search for books?
  Alternativurteil: ohne Befund: grammatisch passend, Aussage im Kontext erhalten.

- **s156** / `78284e52ef8ed53ea4210c3a97bb8346`; Lücke [20, 28), accepted `["computer"]`.
  EN: Please turn off the computer before dinner.
  DE: Bitte schalte den Computer vor dem Abendessen aus.
  Satzurteil: ohne Befund.
  Alternative `pc` → Please turn off the pc before dinner.
  Alternativurteil: ohne Befund: grammatisch passend, Aussage im Kontext erhalten.

### sleep — O

Kartenreferenz `sleep|sleep/VERB|sleep#schlafen`; ID `9fdfb975a144f6c9dca10aed52e2485b`.

- **s157** / `c50790c92beaea3eed82eec8bd6bff04`; Lücke [14, 19), accepted `["sleep"]`.
  EN: Athletes must sleep well before a big match, Rosa.
  DE: Sportler müssen vor einem großen Spiel gut schlafen, Rosa.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s158** / `e3104bcae6da2ca04e1b27487a11d97d`; Lücke [9, 14), accepted `["sleep"]`.
  EN: Lina can sleep in the guest room tonight.
  DE: Lina kann heute Nacht im Gästezimmer schlafen.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s159** / `60f386655fed57ff442d40dec717c871`; Lücke [14, 19), accepted `["sleep"]`.
  EN: Do you always sleep in this warm shirt, Lina?
  DE: Schläfst du immer in diesem warmen Hemd, Lina?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### bag — O

Kartenreferenz `bag|bag/NOUN|bag#tasche`; ID `a437af62734f8b043f46262218b688e3`.

- **s160** / `7f8b6ce4cfedb54de1d1c1ed00ebed5e`; Lücke [29, 32), accepted `["bag"]`.
  EN: Leo carries a heavy shopping bag for his mother.
  DE: Leo trägt eine schwere Einkaufstasche für seine Mutter.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s161** / `8e487d11acafc2cd452b4459c4abdce5`; Lücke [29, 32), accepted `["bag"]`.
  EN: Zoe forgot her brown leather bag on the grass.
  DE: Zoe hat ihre braune Ledertasche auf dem Gras vergessen.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s162** / `306c15db8d52d63306bd29ef5c0c388d`; Lücke [15, 18), accepted `["bag"]`.
  EN: Is this travel bag too big for the flight, Rosa?
  DE: Ist diese Reisetasche zu groß für den Flug, Rosa?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### drink — O

Kartenreferenz `drink|drink/VERB|drink#trinkt`; ID `a584ea54dc4f089c70f5958e6670f123`.

- **s163** / `fad21aea64d8f3e40a2e6a0607c1f96f`; Lücke [11, 16), accepted `["drink"]`.
  EN: Rosa and I drink sweet juice in the park every weekend.
  DE: Rosa und ich trinken jedes Wochenende süßen Saft im Park.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s164** / `1f7f6cffb4e96d7da3838fc1aa2a8e9f`; Lücke [23, 28), accepted `["drink"]`.
  EN: Do Nina and her sister drink warm milk before bed?
  DE: Trinken Nina und ihre Schwester vor dem Schlafengehen warme Milch?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s165** / `a2bd22e0663e5e36eb990d7abf433322`; Lücke [20, 25), accepted `["drink"]`.
  EN: Noah, please do not drink your coffee near the computer.
  DE: Noah, bitte trink deinen Kaffee nicht in der Nähe des Computers.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### egg — O

Kartenreferenz `egg|egg/NOUN|egg#ei`; ID `a8ba408d5d962a13b6017b444a0bba41`.

- **s166** / `e7f1bc557d842802b0095ec9f23ccbac`; Lücke [14, 17), accepted `["egg"]`.
  EN: Rosa cooks an egg for her breakfast on Sunday.
  DE: Rosa kocht sich am Sonntag ein Ei zum Frühstück.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s167** / `6f0736b74f38c45729f8999bf8cc0729`; Lücke [14, 17), accepted `["egg"]`.
  EN: Ben drops one egg on the supermarket floor by mistake.
  DE: Ben lässt aus Versehen ein Ei auf den Supermarktboden fallen.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s168** / `a1897d06886ab681c3d4a5e003896648`; Lücke [23, 26), accepted `["egg"]`.
  EN: Would you like a fried egg with your rice, Ben?
  DE: Möchtest du ein Spiegelei zu deinem Reis, Ben?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### plate — O

Kartenreferenz `plate|plate/NOUN|plate#teller`; ID `a8f7e7920f3776c26a6a5b85876a491c`.

- **s169** / `51c91ea4aec74ba7d19080aaca72bada`; Lücke [20, 25), accepted `["plate"]`.
  EN: Lina buys a ceramic plate at the market in the city.
  DE: Lina kauft auf dem Markt in der Stadt einen Keramikteller.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s170** / `5a7a2f40005c0e0bfe9108c178b05923`; Lücke [45, 50), accepted `["plate"]`.
  EN: Can Elias put his hot sandwich on this clean plate?
  DE: Kann Elias sein warmes Sandwich auf diesen sauberen Teller legen?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s171** / `f65255a41150519854106a25b004f77b`; Lücke [43, 48), accepted `["plate"]`.
  EN: Carefully place the dog food onto the blue plate, Ben.
  DE: Lege das Hundefutter vorsichtig auf den blauen Teller, Ben.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### drive — O

Kartenreferenz `drive|drive/VERB|drive#faehrt`; ID `ab787b789606405ab7b32d81c872ceba`.

- **s172** / `e67006780e5ff6b8298a93f14e216c1c`; Lücke [10, 15), accepted `["drive"]`.
  EN: Sofia can drive us to the library later.
  DE: Sofia kann uns später zur Bibliothek fahren.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s173** / `eba582cafc9a5204c0578d3b73d0caa2`; Lücke [9, 14), accepted `["drive"]`.
  EN: Noah can drive a big bus very well.
  DE: Noah kann sehr gut einen großen Bus fahren.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s174** / `30d9ba25d1669607b95146bd62ed3788`; Lücke [26, 31), accepted `["drive"]`.
  EN: Listen to music while you drive home.
  DE: Höre Musik, während du nach Hause fährst.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### box — U

Kartenreferenz `box|box/NOUN|box#schachtel`; ID `b546d31ecafb2804b3de1c5ec13517f8`.

- **s175** / `18da2c745e2ca2a804f8cba1db1904b5`; Lücke [28, 31), accepted `["box"]`.
  EN: Emma buys a large cardboard box at the store.
  DE: Emma kauft einen großen Pappkarton im Geschäft.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s176** / `0361ac900df19f99bd320e0866bdb140`; Lücke [47, 50), accepted `["box"]`.
  EN: Luis keeps his gardening tools inside a wooden box.
  DE: Luis bewahrt seine Gartenwerkzeuge in einer Holzkiste auf.
  Satzurteil: ohne Befund.
  Alternative `crate` → Luis keeps his gardening tools inside a wooden crate.
  Alternativurteil: U — wooden box und wooden crate überlappen, crate bezeichnet typischerweise eine Transport-/Lagerkiste. Der Originalsatz nennt nur Material und Aufbewahrung; keine sichere Identität der Bauart..

- **s177** / `77b7737395c1e7e3b1a83b2c880cd83f`; Lücke [33, 36), accepted `["box"]`.
  EN: Can Luca open that heavy plastic box for the games?
  DE: Kann Luca diese schwere Plastikbox für die Spiele öffnen?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### listen — O

Kartenreferenz `listen|listen/VERB|listen#zuhoert`; ID `b578e32d44f29c98795165671a60a32a`.

- **s178** / `c18dc398d32a65280d69de270224e304`; Lücke [13, 19), accepted `["listen"]`.
  EN: Noah, please listen carefully to the doctor.
  DE: Noah, bitte hör dem Arzt aufmerksam zu.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s179** / `9b59aed5b0e07c45511d7f5409d41b5e`; Lücke [15, 21), accepted `["listen"]`.
  EN: Do you want to listen to this song with Ben?
  DE: Möchtest du dieses Lied mit Ben anhören?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s180** / `ae920b0c1ca401dd33e9f87896a946a1`; Lücke [18, 24), accepted `["listen"]`.
  EN: Passengers should listen to the driver's announcements.
  DE: Fahrgäste sollten den Durchsagen des Fahrers zuhören.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### cook — O

Kartenreferenz `cook|cook/VERB|cook#kocht`; ID `b66fb3986641d2d60613eecfe0b383b7`.

- **s181** / `52228e007cd34d77259f151361ff3081`; Lücke [14, 18), accepted `["cook"]`.
  EN: Omar does not cook dinner at home during the busy workweek.
  DE: Omar kocht während der arbeitsreichen Arbeitswoche kein Abendessen zu Hause.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s182** / `68c1c8256949a9334df95acecdb3946d`; Lücke [8, 12), accepted `["cook"]`.
  EN: Can you cook simple meals with Noah on weekends?
  DE: Kannst du am Wochenende mit Noah einfache Mahlzeiten kochen?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s183** / `ad9941516b063e251a95c6d6abd008eb`; Lücke [7, 11), accepted `["cook"]`.
  EN: Please cook a hot meal for Omar on his birthday.
  DE: Bitte koche eine warme Mahlzeit für Omar an seinem Geburtstag.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### stand — O

Kartenreferenz `stand|stand/VERB|stand#stehen`; ID `b71527ecca7221880ba43d13d442def0`.

- **s184** / `706ee638e2a2422a6005533ec9016574`; Lücke [9, 14), accepted `["stand"]`.
  EN: Zoe must stand in the train because there are no free seats.
  DE: Zoe muss im Zug stehen, weil es keine freien Plätze gibt.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s185** / `d2bd556533057d490ca503bfc27a0b7b`; Lücke [10, 15), accepted `["stand"]`.
  EN: Do people stand near the station entrance every evening?
  DE: Stehen jeden Abend Leute in der Nähe des Bahnhofseingangs?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s186** / `099303f6dcb1fbdb90c0c3b5f5c1b704`; Lücke [7, 12), accepted `["stand"]`.
  EN: Please stand behind the yellow line at the supermarket checkout, Ben.
  DE: Bitte stehe hinter der gelben Linie an der Supermarktkasse, Ben.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### clock — O

Kartenreferenz `clock|clock/NOUN|clock#uhr`; ID `b7d0befbc2629a3ce5a369d7688ac0c7`.

- **s187** / `c82fdd03031cac08c84398de1be0d339`; Lücke [18, 23), accepted `["clock"]`.
  EN: Maya hangs an old clock on the wall above the table.
  DE: Maya hängt eine alte Uhr an die Wand über dem Tisch.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s188** / `2ddd1292adfef2bfdddff1536b4d248c`; Lücke [9, 14), accepted `["clock"]`.
  EN: Does the clock in the hotel lobby show the right time, Elias?
  DE: Zeigt die Uhr in der Hotellobby die richtige Zeit, Elias?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s189** / `8e503f9848584d2ba49dd0a671fef2cf`; Lücke [48, 53), accepted `["clock"]`.
  EN: Amir notices that his cat is afraid of the loud clock.
  DE: Amir bemerkt, dass seine Katze Angst vor der lauten Uhr hat.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### bring — K

Kartenreferenz `bring|bring/VERB|bring#bringt`; ID `badadda5072db0c453a6aee6545a012f`.

- **s190** / `1fee8c741346d414037836ecc0b85dc8`; Lücke [10, 15), accepted `["bring"]`.
  EN: Could you bring the bill to our table, Leo?
  DE: Könntest du die Rechnung an unseren Tisch bringen, Leo?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s191** / `31de4ce750575bfdeb3f514c6e814b7b`; Lücke [7, 12), accepted `["bring"]`.
  EN: Please bring your passport to the airport, Elias.
  DE: Bitte bring deinen Reisepass zum Flughafen mit, Elias.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s192** / `b83df3189fdbace3a0e864e394688c0d`; Lücke [10, 15), accepted `["bring"]`.
  EN: Lina will bring the documents to the office tomorrow.
  DE: Lina wird die Dokumente morgen ins Büro bringen.
  Satzurteil: ohne Befund.
  Alternative `take` → Lina will take the documents to the office tomorrow.
  Alternativurteil: K — bring orientiert die Bewegung zum Sprecher/Adressaten oder übernommenen Zielstandpunkt, take typischerweise von dort weg. Gleicher Zielort macht die deiktische Perspektive nicht austauschbar..

### bicycle — O

Kartenreferenz `bicycle|bicycle/NOUN|bicycle#fahrrad`; ID `bb703fc94d2138d9bfe4c86e5a831827`.

- **s193** / `cbc07968a54ab5a105f82cfe04742d50`; Lücke [19, 26), accepted `["bicycle"]`.
  EN: Rosa rides her new bicycle together with her best friend.
  DE: Rosa fährt zusammen mit ihrer besten Freundin mit ihrem neuen Fahrrad.
  Satzurteil: ohne Befund.
  Alternative `bike` → Rosa rides her new bike together with her best friend.
  Alternativurteil: ohne Befund: grammatisch passend, Aussage im Kontext erhalten.
  Alternative `pushbike` → Rosa rides her new pushbike together with her best friend.
  Alternativurteil: ohne Befund: grammatisch passend, Aussage im Kontext erhalten.

- **s194** / `db62902d819ef473d14de5ded79a610b`; Lücke [17, 24), accepted `["bicycle"]`.
  EN: Can Mia take her bicycle on the public transport vehicle?
  DE: Kann Mia ihr Fahrrad im öffentlichen Verkehrsmittel mitnehmen?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s195** / `18ac81c58e01c20cd820058a619cb584`; Lücke [35, 42), accepted `["bicycle"]`.
  EN: Noah fixes the broken chain of the bicycle with a tool.
  DE: Noah repariert die kaputte Kette des Fahrrads mit einem Werkzeug.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### head — O

Kartenreferenz `head|head/NOUN|head#kopf`; ID `bdf9a1aa29a3ccd1959fbc96871c0761`.

- **s196** / `b072c2c4bf55982823b6374e4f33af59`; Lücke [38, 42), accepted `["head"]`.
  EN: During the ride, Luca rests his tired head against the window.
  DE: Während der Fahrt lehnt Luca seinen müden Kopf an das Fenster.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s197** / `ab6cb3e914e3f19d909091250de32897`; Lücke [15, 19), accepted `["head"]`.
  EN: David nods his head quietly to agree with the librarian.
  DE: David nickt leise mit dem Kopf, um der Bibliothekarin zuzustimmen.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s198** / `4978c15935bb87d07c2f48c5b40478f0`; Lücke [17, 21), accepted `["head"]`.
  EN: Elias shakes his head because he disagrees with his best friend.
  DE: Elias schüttelt den Kopf, weil er nicht mit seinem besten Freund übereinstimmt.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### apple — O

Kartenreferenz `apple|apple/NOUN|apple#aepfel`; ID `c00e3410e81e5d7d88d32d85bfc87a0c`.

- **s199** / `5e1edf9a5467c484cac5229596a4543c`; Lücke [37, 42), accepted `["apple"]`.
  EN: Rosa baked a sweet cake with a fresh apple for her birthday party.
  DE: Rosa backte einen süßen Kuchen mit einem frischen Apfel für ihre Geburtstagsparty.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s200** / `f838bd6680ac978d84651a00ffe5b9e3`; Lücke [38, 43), accepted `["apple"]`.
  EN: Our kind neighbor Elias gave me a red apple from his garden.
  DE: Unser netter Nachbar Elias gab mir einen roten Apfel aus seinem Garten.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s201** / `f44e7f3fc584b82a3640c01e74159d49`; Lücke [18, 23), accepted `["apple"]`.
  EN: Can a fresh green apple help Rosa stay healthy this winter?
  DE: Kann ein frischer grüner Apfel Rosa helfen, diesen Winter gesund zu bleiben?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### desk — O

Kartenreferenz `desk|desk/NOUN|desk#schreibtisch`; ID `c0270742454943e7a01361147887a6d6`.

- **s202** / `61d5fd35eac1e36e83417b5b29308be0`; Lücke [28, 32), accepted `["desk"]`.
  EN: Sofia shares a small wooden desk with her brother at home.
  DE: Sofia teilt sich zu Hause einen kleinen Holzschreibtisch mit ihrem Bruder.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s203** / `c6fdc218c879919e81e03eeb89d3df63`; Lücke [45, 49), accepted `["desk"]`.
  EN: Luis stretches his back after sitting at his desk all afternoon.
  DE: Luis dehnt seinen Rücken, nachdem er den ganzen Nachmittag am Schreibtisch gesessen hat.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s204** / `63a4fe77ce3a350a62580d10b4efecf2`; Lücke [19, 23), accepted `["desk"]`.
  EN: Do not sit at your desk without taking short walking breaks.
  DE: Sitzen Sie nicht an Ihrem Schreibtisch, ohne kurze Gehpausen einzulegen.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### receipt — K

Kartenreferenz `receipt|receipt/NOUN|receipt#kassenbon`; ID `c4220fc1b79b75f3e194e920dcb26f5c`.

- **s205** / `9cbae75c6307b041833b7c92aaa35938`; Lücke [13, 20), accepted `["receipt"]`.
  EN: Zoe kept the receipt for the birthday cake.
  DE: Zoe hat den Kassenbon für den Geburtstagskuchen behalten.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s206** / `05218294a9689370661fb9ea2f05e6c3`; Lücke [19, 26), accepted `["receipt"]`.
  EN: Does Luis have the receipt for this blue shirt?
  DE: Hat Luis den Beleg für dieses blaue Hemd?
  Satzurteil: ohne Befund.
  Alternative `proof of purchase` → Does Luis have the proof of purchase for this blue shirt?
  Alternativurteil: K — Ein Kaufnachweis kann auch ein Kontoauszug oder anderer Nachweis sein; receipt bezeichnet den konkreten Beleg. Die Frage nach irgendeinem Kaufnachweis ist weiter als die nach dem receipt..

- **s207** / `f3f8bf282a7fcc246dcc7427bcb117fb`; Lücke [13, 20), accepted `["receipt"]`.
  EN: Mia lost the receipt after paying for ice cream near the park.
  DE: Mia verlor den Kassenbon, nachdem sie beim Park für Eis bezahlt hatte.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### hand — O

Kartenreferenz `hand|hand/NOUN|hand#hand`; ID `cd767d1d713076842de381082551c9c8`.

- **s208** / `d2f7e6aad141a386ceaac5f3edeebac8`; Lücke [41, 45), accepted `["hand"]`.
  EN: Leo holds the heavy letter with his left hand.
  DE: Leo hält den schweren Brief mit seiner linken Hand.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s209** / `21c95889f4e76a52fc7618726083646e`; Lücke [15, 19), accepted `["hand"]`.
  EN: Ben raises his hand to stop a taxi in the street.
  DE: Ben hebt seine Hand, um ein Taxi auf der Straße anzuhalten.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s210** / `b5f011c8d3d939fc2061c84552abb9e3`; Lücke [18, 22), accepted `["hand"]`.
  EN: Did Omar hurt his hand on the rough beach rocks?
  DE: Hat sich Omar an den rauen Strandfelsen an der Hand verletzt?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### soap — O

Kartenreferenz `soap|soap/NOUN|soap#seife`; ID `d06d6cfed8c6b9ff2459264a11ed4333`.

- **s211** / `de5bd78fa48d7e60324d18e4ce073ac6`; Lücke [35, 39), accepted `["soap"]`.
  EN: Excuse me, Mia, there is no liquid soap in this restaurant restroom.
  DE: Entschuldige, Mia, es gibt keine Flüssigseife in dieser Restauranttoilette.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s212** / `449b2f07499f11b2e56294e770b94a67`; Lücke [18, 22), accepted `["soap"]`.
  EN: Did Luca find any soap in the station washroom?
  DE: Hat Luca Seife im Bahnhofs-Waschraum gefunden?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s213** / `97d94212af1ad505450c16f7978f6dfc`; Lücke [24, 28), accepted `["soap"]`.
  EN: Amir tests an automatic soap dispenser with a new digital sensor.
  DE: Amir testet einen automatischen Seifenspender mit einem neuen digitalen Sensor.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### train — O

Kartenreferenz `train|train/NOUN|train#zug`; ID `d0a8d9bc00ccffed5f69d58553dbba65`.

- **s214** / `bd14585a75626c94b0d2ffa244490431`; Lücke [15, 20), accepted `["train"]`.
  EN: Noah takes the train to his football match.
  DE: Noah nimmt den Zug zu seinem Fußballspiel.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s215** / `50df56e62a6eb2be13d24004a9d2e450`; Lücke [15, 20), accepted `["train"]`.
  EN: Mia travels by train to the beach for her holiday.
  DE: Mia fährt für ihren Urlaub mit dem Zug an den Strand.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s216** / `7d05c1137f8439682c272cb65f60cbf9`; Lücke [26, 31), accepted `["train"]`.
  EN: Does Zoe live near a busy train station?
  DE: Wohnt Zoe in der Nähe eines belebten Bahnhofs?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### window — O

Kartenreferenz `window|window/NOUN|window#fenster`; ID `d1937efcda74ffee6e336acfc7f92980`.

- **s217** / `1a91b5ed94994c6776a5da5c18ff57e5`; Lücke [36, 42), accepted `["window"]`.
  EN: David looks through the living room window to see the street.
  DE: David schaut durch das Wohnzimmerfenster, um die Straße zu sehen.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s218** / `be1d1f185b9a8ccf42bc8985eb77cc4e`; Lücke [25, 31), accepted `["window"]`.
  EN: Can you open the kitchen window, Eva?
  DE: Kannst du das Küchenfenster öffnen, Eva?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s219** / `b931ec11714b743ce27e732d8995c2ce`; Lücke [38, 44), accepted `["window"]`.
  EN: Lina plays her flute next to the open window.
  DE: Lina spielt ihre Flöte neben dem offenen Fenster.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### eye — O

Kartenreferenz `eye|eye/NOUN|eye#auge`; ID `d1bfa0fe377b0a7a99df52b21e3ef00b`.

- **s220** / `87ddfae8fb9b7e5f07587225f5ccbb71`; Lücke [27, 30), accepted `["eye"]`.
  EN: Lina got sand in her right eye at the beach.
  DE: Lina bekam am Strand Sand in ihr rechtes Auge.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s221** / `690d4171a99ae7fc67eb0402f4f9140f`; Lücke [16, 19), accepted `["eye"]`.
  EN: Luis closed one eye to aim at the target.
  DE: Luis schloss ein Auge, um auf das Ziel zu zielen.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s222** / `421f17fca8a26270ec3729a044810ec9`; Lücke [53, 56), accepted `["eye"]`.
  EN: Strong wind blew cold dust directly into Amir's left eye.
  DE: Starker Wind wehte kalten Staub direkt in Amirs linkes Auge.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### bandage — O

Kartenreferenz `bandage|bandage/NOUN|bandage#verband`; ID `d65bc850e1059c326d4c1bb023cb46e5`.

- **s223** / `fd18f7ba944428559abc5b177e7e96bf`; Lücke [54, 61), accepted `["bandage"]`.
  EN: David hurt his knee during football and needs a clean bandage.
  DE: David hat sich beim Fußball am Knie verletzt und braucht einen sauberen Verband.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s224** / `7c71146bb86c3fb1bb60ea3277a5f1e4`; Lücke [25, 32), accepted `["bandage"]`.
  EN: Can Eva change the white bandage on her foot at the beach?
  DE: Kann Eva den weißen Verband an ihrem Fuß am Strand wechseln?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s225** / `1f88a727a156483f97a65d1a9eddd62c`; Lücke [21, 28), accepted `["bandage"]`.
  EN: Omar keeps a sterile bandage in the bathroom cabinet for emergencies.
  DE: Omar bewahrt einen sterilen Verband für Notfälle im Badezimmerschrank auf.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### bridge — O

Kartenreferenz `bridge|bridge/NOUN|bridge#brucke`; ID `d6dc9bc537245af0f84f65f06cdd896e`.

- **s226** / `6242be92b850d47a438c2261a8effa89`; Lücke [28, 34), accepted `["bridge"]`.
  EN: Maya walks across the stone bridge over the river.
  DE: Maya geht über die Steinbrücke über dem Fluss.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s227** / `c52b2a19ee9dd5ea3179f7d46fcf6395`; Lücke [26, 32), accepted `["bridge"]`.
  EN: Can David see the railway bridge from platform two?
  DE: Kann David die Eisenbahnbrücke von Gleis zwei aus sehen?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s228** / `f0beb26247404be4e3628abe30a10661`; Lücke [21, 27), accepted `["bridge"]`.
  EN: Turn left at the old bridge to reach the clinic, Maya.
  DE: Biege an der alten Brücke links ab, um die Klinik zu erreichen, Maya.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### carry — O

Kartenreferenz `carry|carry/VERB|carry#tragen`; ID `d966e92a8730c27fcd5ab097004d509e`.

- **s229** / `d69188c5d042330880ff1694112be689`; Lücke [10, 15), accepted `["carry"]`.
  EN: Elias can carry the paper bags from the supermarket.
  DE: Elias kann die Papiertüten aus dem Supermarkt tragen.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s230** / `7420b566d421a7aaf22724f9fa672c2d`; Lücke [7, 12), accepted `["carry"]`.
  EN: Please carry the small cat into the garden, Noah.
  DE: Bitte trage die kleine Katze in den Garten, Noah.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s231** / `921f749073348cc29ee65b6d8fcfebe2`; Lücke [14, 19), accepted `["carry"]`.
  EN: Noah, can you carry these two boxes into the office?
  DE: Noah, kannst du diese zwei Kisten ins Büro tragen?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### ticket — O

Kartenreferenz `ticket|ticket/NOUN|ticket#fahrkarte`; ID `e4b05d00f7a0804f7f5e700cb1aea1cc`.

- **s232** / `109ceece72bb9d8caaeff56d49d40c17`; Lücke [33, 39), accepted `["ticket"]`.
  EN: Maya downloads her digital train ticket on her new mobile phone.
  DE: Maya lädt ihre digitale Fahrkarte auf ihr neues Handy herunter.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s233** / `c359d667033166dba6afa9a216ca0b17`; Lücke [34, 40), accepted `["ticket"]`.
  EN: Did David forget his return train ticket outside on the garden bench?
  DE: Hat David seine Zugrückfahrkarte draußen auf der Gartenbank vergessen?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s234** / `49ecf203dfaab288ad95ac6d880f30d7`; Lücke [29, 35), accepted `["ticket"]`.
  EN: Mia pays for her cheap train ticket at the supermarket travel counter.
  DE: Mia bezahlt ihre günstige Fahrkarte am Reiseschalter im Supermarkt.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### clean — O

Kartenreferenz `clean|clean/VERB|clean#putzen`; ID `e4d7721061e4264e2dde33947b5b9d01`.

- **s235** / `c6d3e70ded0c2c925047786d44e2ea0d`; Lücke [10, 15), accepted `["clean"]`.
  EN: Amir must clean the office desk today.
  DE: Amir muss heute den Schreibtisch im Büro putzen.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s236** / `049e0e68db3f003676e1dfcad1897e7c`; Lücke [7, 12), accepted `["clean"]`.
  EN: Do you clean the cat bed every week, Omar?
  DE: Machst du das Katzenbett jede Woche sauber, Omar?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s237** / `7253623b1fafc0a2d1e7fa27bf8d0dca`; Lücke [7, 12), accepted `["clean"]`.
  EN: Please clean this table before the guests arrive, Sara.
  DE: Bitte putze diesen Tisch, bevor die Gäste ankommen, Sara.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### cut — O

Kartenreferenz `cut|cut/VERB|cut#schneidet`; ID `e613a6a71f931236cb6157e48dda7b52`.

- **s238** / `997048e96592930f2f91aa441f2beecd`; Lücke [10, 13), accepted `["cut"]`.
  EN: Omar must cut the long wire with scissors.
  DE: Omar muss den langen Draht mit einer Schere schneiden.
  Satzurteil: ohne Befund.
  Alternative `snip` → Omar must snip the long wire with scissors.
  Alternativurteil: ohne Befund: grammatisch passend, Aussage im Kontext erhalten.

- **s239** / `fff9b08b88ceb5f361892e763f7092ae`; Lücke [8, 11), accepted `["cut"]`.
  EN: Can you cut this paper ticket for Noah?
  DE: Kannst du dieses Papierticket für Noah schneiden?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s240** / `1933c7287349877b16f7c9a840746012`; Lücke [14, 17), accepted `["cut"]`.
  EN: Please do not cut the bandage with this knife, Luis.
  DE: Bitte schneide den Verband nicht mit diesem Messer, Luis.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### fork — O

Kartenreferenz `fork|fork/NOUN|fork#gabel`; ID `e6fb24eb3e75fd9052c1b60f115d3c86`.

- **s241** / `1333834979786e3b68146afa510e8378`; Lücke [43, 47), accepted `["fork"]`.
  EN: Sofia eats her picnic salad with a plastic fork.
  DE: Sofia isst ihren Picknick-Salat mit einer Plastikgabel.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s242** / `19f8fb1e719077770cdf002900efaf93`; Lücke [28, 32), accepted `["fork"]`.
  EN: Can Zoe pass me that silver fork from the drawer?
  DE: Kann Zoe mir diese Silbergabel aus der Schublade reichen?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s243** / `7a6815d7d913e8033f99a25ff86086fb`; Lücke [26, 30), accepted `["fork"]`.
  EN: Did Omar choose a dessert fork in the kitchen shop?
  DE: Hat Omar im Küchengeschäft eine Dessertgabel ausgewählt?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### knife — O

Kartenreferenz `knife|knife/NOUN|knife#messer`; ID `eac1e93b65e51055b6123e99510acd66`.

- **s244** / `b7afe1e19105c6507586c98bc39d368f`; Lücke [38, 43), accepted `["knife"]`.
  EN: Nina asks the clerk for a sharp bread knife.
  DE: Nina fragt den Verkäufer nach einem scharfen Brotmesser.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s245** / `f868a7b2a0b2709459a5e4c2d3a4e3df`; Lücke [23, 28), accepted `["knife"]`.
  EN: Sofia uses the kitchen knife to slice the red apple.
  DE: Sofia benutzt das Küchenmesser, um den roten Apfel zu schneiden.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s246** / `c681ce42ef95ddcc299e074da70e1fc1`; Lücke [31, 36), accepted `["knife"]`.
  EN: Noah finds a picture of an old knife in this history book.
  DE: Noah findet in diesem Geschichtsbuch ein Bild von einem alten Messer.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### station — O

Kartenreferenz `station|station/NOUN|station#bahnhof`; ID `f44ab874cc11564009cc1a2f754ae7a3`.

- **s247** / `130838d7035690a393d0b8736693a457`; Lücke [53, 60), accepted `["station"]`.
  EN: Leo mails a letter at the post office near the train station.
  DE: Leo gibt einen Brief bei der Post in der Nähe des Bahnhofs auf.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s248** / `854c114ae6b6578fd9c32fa257bf33a2`; Lücke [21, 28), accepted `["station"]`.
  EN: Is the central train station far from this street, Lina?
  DE: Ist der Hauptbahnhof weit von dieser Straße entfernt, Lina?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s249** / `af4c8afa30d98aaacdd0f1563baef5f0`; Lücke [54, 61), accepted `["station"]`.
  EN: Can Elias sweep the floor before his train leaves the station?
  DE: Kann Elias den Boden fegen, bevor sein Zug den Bahnhof verlässt?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### colleague — O

Kartenreferenz `colleague|colleague/NOUN|colleague#kollege_oder_kollegin`; ID `f45144ec526dc34aeb44d614d4fad4cb`.

- **s250** / `3b248b6f99684f476ed8baac21dca578`; Lücke [24, 33), accepted `["colleague"]`.
  EN: Emma meets her friendly colleague on the morning bus every day.
  DE: Emma trifft jeden Tag im morgendlichen Bus ihren freundlichen Kollegen.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s251** / `fe572836efef692df5a2b6756e16c891`; Lücke [41, 50), accepted `["colleague"]`.
  EN: Is this smart blue shirt a gift for your colleague, Lina?
  DE: Ist dieses schicke blaue Hemd ein Geschenk für deinen Kollegen, Lina?
  Satzurteil: ohne Befund.
  Alternative `co-worker` → Is this smart blue shirt a gift for your co-worker, Lina?
  Alternativurteil: ohne Befund: grammatisch passend, Aussage im Kontext erhalten.

- **s252** / `79855735e8da5f1f0fd7879c05cbeef1`; Lücke [21, 30), accepted `["colleague"]`.
  EN: Maya drives her sick colleague to the doctor today.
  DE: Maya fährt heute ihre kranke Kollegin zum Arzt.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### office — O

Kartenreferenz `office|office/NOUN|office#buero`; ID `f9dcf6497687431647832b5f7e04247b`.

- **s253** / `4d6b04df32ff0f7ce8bb7c65bf5b49e5`; Lücke [39, 45), accepted `["office"]`.
  EN: Nina walks from her house to the small office across the street.
  DE: Nina geht von ihrem Haus zu dem kleinen Büro auf der anderen Straßenseite.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s254** / `bf146d643b01ee2f013cba746e937b90`; Lücke [57, 63), accepted `["office"]`.
  EN: Mia works on the restaurant computer inside a quiet back office.
  DE: Mia arbeitet am Restaurantcomputer in einem ruhigen Hinterbüro.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s255** / `9c65f1e9ab35862cda92a6f554ddf8cd`; Lücke [43, 49), accepted `["office"]`.
  EN: Does David really work in that modern park office every afternoon?
  DE: Arbeitet David wirklich jeden Nachmittag in diesem modernen Parkbüro?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### read — O

Kartenreferenz `read|read/VERB|read#lesen`; ID `fa82bc4e41ba46a0a1187a6b519c2235`.

- **s256** / `515f9245f04fe5126e1a11f93a9f73ac`; Lücke [9, 13), accepted `["read"]`.
  EN: Lina can read the short report before the meeting.
  DE: Lina kann den kurzen Bericht vor der Besprechung lesen.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s257** / `1ae8c4476e4d08c68eed00f22b789afd`; Lücke [10, 14), accepted `["read"]`.
  EN: Does Nina read the city map carefully?
  DE: Liest Nina den Stadtplan aufmerksam?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s258** / `22024d30d1c155bff02f1f36295086a5`; Lücke [31, 35), accepted `["read"]`.
  EN: During the ride, Sara likes to read magazines.
  DE: Während der Fahrt liest Sara gerne Zeitschriften.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

### tooth — O

Kartenreferenz `tooth|tooth/NOUN|tooth#zahn`; ID `fc712c6bd26473094dce17fbba0fba8b`.

- **s259** / `986893c992dd70b96a190a28c5bdfe16`; Lücke [34, 39), accepted `["tooth"]`.
  EN: At the station, Sofia lost a baby tooth while eating an apple.
  DE: Am Bahnhof verlor Sofia einen Milchzahn, während sie einen Apfel aß.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s260** / `0eb0ac041f318807b068b16f03839d13`; Lücke [10, 15), accepted `["tooth"]`.
  EN: One front tooth hurts whenever cold water touches it.
  DE: Ein Vorderzahn schmerzt, wann immer kaltes Wasser ihn berührt.
  Satzurteil: ohne Befund.
  valid_alternatives: leer.

- **s261** / `46f76d316ff0094162f70569feea69ef`; Lücke [16, 21), accepted `["tooth"]`.
  EN: Did Mia break a tooth on that hard bread during her trip?
  DE: Hat sich Mia während ihrer Reise an diesem harten Brot einen Zahn abgebrochen?
  Satzurteil: ohne Befund.
  valid_alternatives: leer.


## Abschlussnachweise

`git diff --check`: Exit 0. `git status --short`:

```text
 M NEXTSTEPS.md
?? docs/everyday-v1-review.md
```

SHA-256-Gegenprüfung vor/nach der Auswertung: 164 geschützte Dateien unverändert,
darunter sämtliche fünf Laufartefakte, das bestehende App-Pack, Auswahl, Inventar,
Modellkonfiguration, App-/Pipeline-Code und Tests. NEXTSTEPS.md hat 21 Zeilen.
Keine vollständige Testsuite gestartet; für diese reine Auswertung nur die oben
benannten lokalen Validatoren und lesenden Prüfungen ausgeführt.

## Nachtrag: geprüfte Zusammenführung vom 04.10.2026

Dieser Nachtrag ersetzt die frühere Abschlussentscheidung. Die ursprüngliche 87-Karten-Auswertung oben bleibt als historischer Prüfbeleg erhalten; keine erneute allgemeine Vollprüfung ihrer 261 Sätze.

**Vollständigkeit:** Beide Quellpacks decken exakt 100/100 Auswahlpositionen ab (Form, Lemma/POS, Sense-Key); 87 + 13, keine Überschneidung, keine ungefragte zusätzliche Zielkarte. Keine Karte zurückgestellt. Das interne Ergebnis enthält 164 bestehende + 100 neue = 264 Karten und 792 Satzzuordnungen/792 eindeutige Sätze.

**Qualität:** Alle 39 gepackten Nachhol-Sätze und ihre fünf Alternativen sind redaktionell vollständig geprüft. Die übrigen 26 ungenutzten Kandidaten sind nicht Teil dieser Inhaltsfreigabe. 12 Nachhol-Karten ohne erforderliche Satz-/Alternativkorrektur, quiet nach Entfernung von peaceful aufgenommen. Keine englischen Sätze geändert. Seltenere korrekte Formulierungen wurden nicht pauschal abgelehnt. Dies ist keine vollständige semantische Neubegutachtung aller Wörterbuch-Senses und Tokenannotation des alten Packs.

### Tatsächliche Läufe und Kosten

| Quelle | Karten / Sätze | Modellaufrufe | Ledger USD | Status |
|---|---:|---:|---:|---|
| everyday | 87 / 261 | 781 | 0.869800 | MAX_TOKENS meaning_check JSON abort; packed cards retained; not budget exhaustion |
| missing | 13 / 39 | 113 | 0.118054 | 13/13 forms complete, 13 cards packed; no abort reported |

Ledger-Summe **0,987854 USD** (894 Aufrufe). Die ungerundeten Fortschrittsanzeigen summieren sich zu 0,987875 USD; 0,000021 USD Differenz durch Rundung je Ledgerzeile. Offline-Zusammenführung: 0 neue Modellaufrufe, 0 USD. Nachholbericht: 13/13 Formen, 0 nicht gepackt, 39 ok/0 failed/26 ungenutzt, 38 exakte Blindtests + 1 bestätigte Alternative, kein Abbruch gemeldet. Exitcode des früheren externen Starts nicht nachträglich behauptet. Erster Lauf: technischer MAX_TOKENS/JSON-Abbruch, kein Budget- oder Inhaltsabbruch.

Tatsächliche Artefakte jeweils: `pack.json`, `ledger.csv`, `progress.txt`, `review.csv`, `run_report.md`. Quell-Hashes stehen in der versionierten Kurationsliste und werden vor dem Merge geprüft.

### Vollständige Nachhol-Prüfung (39/39, Alternativen 5/5)

Zielform und genaue Zielbedeutung stehen je Karte in der abschließenden 100er-Liste. Sämtliche nachfolgenden Originalsätze erfüllen diese Form und Bedeutung; alle Übersetzungen wurden gelesen.

#### strong|strong/ADJ|strong#stark — `067512cff1d073634236792dd096a597`

- `s1` / `ab576ff3574ccde26cb66c106a8bcbef`: Sara lifts the heavy table alone because she is strong.
  Deutsch: Sara hebt den schweren Tisch alleine hoch, weil sie kräftig ist.
  Urteil: Ohne erforderliche Korrektur: Grammatik, natürliche Lesart, Übersetzung und Zielbedeutung passen.
- `s2` / `595169daf33ae9c2304da7f9c40852d2`: Is David strong enough to carry that big box?
  Deutsch: Ist David kräftig genug, um diesen großen Karton zu tragen?
  Urteil: Ohne erforderliche Korrektur: Grammatik, natürliche Lesart, Übersetzung und Zielbedeutung passen.
- `s3` / `f471dbc8d5e298cb10615388aec500a9`: Leo needs strong arms to climb the wall.
  Deutsch: Leo braucht kräftige Arme, um die Wand hochzuklettern.
  Urteil: Ohne erforderliche Korrektur: Grammatik, natürliche Lesart, Übersetzung und Zielbedeutung passen.

#### old|old/ADJ|old#alt — `0b22b7e132d111536d3516884f74ab19`

- `s4` / `43ab66ffb9083f66b07aa777cfdb600b`: Noah has an old dog that sleeps almost all day.
  Deutsch: Noah hat einen alten Hund, der fast den ganzen Tag schläft.
  Urteil: Ohne erforderliche Korrektur: Grammatik, natürliche Lesart, Übersetzung und Zielbedeutung passen.
- `s5` / `07a95e69a6f8797bdecfd1003ccbdcf4`: At the station, Nina helps an old man carry his heavy suitcase.
  Deutsch: Am Bahnhof hilft Nina einem alten Mann, seinen schweren Koffer zu tragen.
  Urteil: Ohne erforderliche Korrektur: Grammatik, natürliche Lesart, Übersetzung und Zielbedeutung passen.
- `s6` / `bf4ffe9fb720f21727a907bc2cd876cb`: The doctor asks Sara about her old grandmother's health.
  Deutsch: Der Arzt befragt Sara über die Gesundheit ihrer betagten Großmutter.
  Urteil: aged und elderly bezeichnen das hohe Lebensalter passend; aged ist formeller, aber korrekt. „befragt … über“ ist weniger idiomatisch als „fragt … nach“, kein zwingender Bedeutungsfehler.
  Wörtlich eingesetzt `aged`: The doctor asks Sara about her aged grandmother's health. — Grammatik und Aussage erhalten; bleibt.
  Wörtlich eingesetzt `elderly`: The doctor asks Sara about her elderly grandmother's health. — Grammatik und Aussage erhalten; bleibt.

#### cheap|cheap/ADJ|cheap#billiger — `1bcb8de177dee1cacde6d93c41a3b9ca`

- `s7` / `58ef716fbe301b3e206df861e57b7ef8`: Omar bought a cheap gift for the birthday party.
  Deutsch: Omar hat ein günstiges Geschenk für die Geburtstagsfeier gekauft.
  Urteil: Ohne erforderliche Korrektur: Grammatik, natürliche Lesart, Übersetzung und Zielbedeutung passen.
- `s8` / `84e9ebe0299adfb62fcaf2d20718c0f2`: Is the bus ticket cheap or expensive, Luis?
  Deutsch: Ist das Busticket billig oder teuer, Luis?
  Urteil: Ohne erforderliche Korrektur: Grammatik, natürliche Lesart, Übersetzung und Zielbedeutung passen.
- `s9` / `2c302cf755ec5e532f27cf6f903d34ba`: Nina bought a cheap umbrella because of the sudden rain.
  Deutsch: Nina kaufte wegen des plötzlichen Regens einen billigen Regenschirm.
  Urteil: Ohne erforderliche Korrektur: Grammatik, natürliche Lesart, Übersetzung und Zielbedeutung passen.
  Wörtlich eingesetzt `low-cost`: Nina bought a low-cost umbrella because of the sudden rain. — Grammatik und Aussage erhalten; bleibt.

#### expensive|expensive/ADJ|expensive#teuer — `1be7c9b4139271e54557f008b8197e32`

- `s10` / `a39f93b861ae5a7952d84c8dcb1ce54c`: Amir thinks this hotel is very expensive for a holiday.
  Deutsch: Amir findet, dass dieses Hotel für einen Urlaub sehr teuer ist.
  Urteil: Ohne erforderliche Korrektur: Grammatik, natürliche Lesart, Übersetzung und Zielbedeutung passen.
  Wörtlich eingesetzt `pricey`: Amir thinks this hotel is very pricey for a holiday. — Grammatik und Aussage erhalten; bleibt.
- `s11` / `909274e005d57ff17995ffce3f7933bb`: Is food for Maya's cat really that expensive?
  Deutsch: Ist das Futter für Mayas Katze wirklich so teuer?
  Urteil: Ohne erforderliche Korrektur: Grammatik, natürliche Lesart, Übersetzung und Zielbedeutung passen.
- `s12` / `2b3e3808a3002bf90e379b512a893064`: Lina does not buy the expensive apples at the supermarket.
  Deutsch: Lina kauft die teuren Äpfel im Supermarkt nicht.
  Urteil: Ohne erforderliche Korrektur: Grammatik, natürliche Lesart, Übersetzung und Zielbedeutung passen.

#### hard|hard/ADJ|hard#hart — `678c782d556383c3a35e851b93a548c0`

- `s13` / `b1f5b37a0a1ecc425b1ed02a25ae57d2`: Rosa bought a hard plastic case for her new phone.
  Deutsch: Rosa kaufte eine Hülle aus hartem Kunststoff für ihr neues Telefon.
  Urteil: Ohne erforderliche Korrektur: Grammatik, natürliche Lesart, Übersetzung und Zielbedeutung passen.
- `s14` / `6219221e172fac48b86eb15589fec241`: David cannot walk comfortably because these shoes have a hard sole.
  Deutsch: David kann nicht bequem gehen, weil diese Schuhe eine harte Sohle haben.
  Urteil: Ohne erforderliche Korrektur: Grammatik, natürliche Lesart, Übersetzung und Zielbedeutung passen.
- `s15` / `9a9cde9720a4537718aab41d12af5779`: Please pack the glass in a hard cardboard box, Luca.
  Deutsch: Bitte packe das Glas in einen harten Pappkarton, Luca.
  Urteil: hard cardboard ist verständlich als festes/hartes Kartonmaterial; rigid/sturdy wäre eine Stilpräferenz, kein Satzersatz.

#### young|young/ADJ|young#jung — `692abd8adb6a6c591b20e32a6b3e3e53`

- `s16` / `496b09ee48d6f1f64c2a2d05b24eb85c`: Amir sees a young dog playing happily in the park.
  Deutsch: Amir sieht einen jungen Hund fröhlich im Park spielen.
  Urteil: Ohne erforderliche Korrektur: Grammatik, natürliche Lesart, Übersetzung und Zielbedeutung passen.
- `s17` / `37f42e5f14877b6f283d6a650151e9d5`: Is Luca too young to drive a car on his birthday?
  Deutsch: Ist Luca an seinem Geburtstag zu jung, um Auto zu fahren?
  Urteil: Der Geburtstag ist als Altersgrenzen-Kontext möglich; keine Grammatik- oder Bedeutungsabweichung.
- `s18` / `498f0de50a1ff385220d471188a6b735`: Rosa smiles at the young waiter who brings the food.
  Deutsch: Rosa lächelt den jungen Kellner an, der das Essen bringt.
  Urteil: Ohne erforderliche Korrektur: Grammatik, natürliche Lesart, Übersetzung und Zielbedeutung passen.

#### ready|ready/ADJ|ready#bereit — `8bc52012a2d0ee4eaf469e64b0cd3fcc`

- `s19` / `0381ab31dbb50660af0e15c9b73bc78b`: Ali packed his bags and is ready for the trip.
  Deutsch: Ali hat seine Taschen gepackt und ist bereit für die Reise.
  Urteil: Ohne erforderliche Korrektur: Grammatik, natürliche Lesart, Übersetzung und Zielbedeutung passen.
- `s20` / `21722b257740258cf319473de1c9c9d3`: Are you ready to pay for your groceries, Elias?
  Deutsch: Bist du bereit, deine Einkäufe zu bezahlen, Elias?
  Urteil: Ohne erforderliche Korrektur: Grammatik, natürliche Lesart, Übersetzung und Zielbedeutung passen.
- `s21` / `ac1e66f151d64a98f59694a5c2f4845c`: Nina is not ready to leave the house yet.
  Deutsch: Nina ist noch nicht bereit, das Haus zu verlassen.
  Urteil: Ohne erforderliche Korrektur: Grammatik, natürliche Lesart, Übersetzung und Zielbedeutung passen.

#### wet|wet/ADJ|wet#nass — `8daa342f4f8c669d1c6de5fd2141be12`

- `s22` / `89a8480b549f0de4ca28b14e558847d3`: Sofia shares her umbrella because my jacket is completely wet.
  Deutsch: Sofia teilt ihren Regenschirm, weil meine Jacke völlig nass ist.
  Urteil: Das Teilen des Schirms trotz bereits nasser Jacke ist plausibel; verhindert weiteres Nasswerden.
- `s23` / `a55d3fe0d6cd5ca8c34a8b2cce4412d5`: Do not sit on the wet bench in the park, Sara!
  Deutsch: Setz dich nicht auf die nasse Bank im Park, Sara!
  Urteil: Ohne erforderliche Korrektur: Grammatik, natürliche Lesart, Übersetzung und Zielbedeutung passen.
- `s24` / `b8c198c42c80df11f82402c16de4ea1f`: Sara plays with water balloons at the birthday party and gets wet.
  Deutsch: Sara spielt auf der Geburtstagsparty mit Wasserballons und wird nass.
  Urteil: Ohne erforderliche Korrektur: Grammatik, natürliche Lesart, Übersetzung und Zielbedeutung passen.

#### quiet|quiet/ADJ|quiet#ruhig — `8ff35160016cdbbe1b0794327afe2200`

- `s25` / `501c3a14a16c8dcbde0953ff2b3ea8bf`: Zoe lives on a quiet street near the city center.
  Deutsch: Zoe wohnt in einer ruhigen Straße nahe dem Stadtzentrum.
  Urteil: peaceful entfernt: friedlich/ruhig im sozialen Sinn garantiert die ausgewählte Geräuscharmut nicht. Originalsatz korrekt.
  Wörtlich eingesetzt `peaceful`: Zoe lives on a peaceful street near the city center. — entfernt aus obigem Bedeutungsgrund.
- `s26` / `7e52ca0618a2901facd1b5e1031cb5a1`: Is David on a quiet bus right now?
  Deutsch: Ist David gerade in einem ruhigen Bus?
  Urteil: quiet bus kann einen wenig lauten Innenraum bezeichnen; Formulierung weniger häufig, aber korrekt.
- `s27` / `afaa50d84e2581e8ac55558e03c5e603`: Rosa needs a quiet computer for her office work.
  Deutsch: Rosa braucht einen leisen Computer für ihre Büroarbeit.
  Urteil: Ohne erforderliche Korrektur: Grammatik, natürliche Lesart, Übersetzung und Zielbedeutung passen.

#### soft|soft/ADJ|soft#weiche — `d3283b97f5551644a4c6fd847e5039c1`

- `s28` / `5c9632592e104272f8d1e23abc1b990b`: Maya sits on the soft grass under a big tree.
  Deutsch: Maya sitzt auf dem weichen Gras unter einem großen Baum.
  Urteil: Ohne erforderliche Korrektur: Grammatik, natürliche Lesart, Übersetzung und Zielbedeutung passen.
- `s29` / `6dc85b349d4088be0e46740626d3071b`: David gave his best friend a soft pillow as a gift.
  Deutsch: David schenkte seinem besten Freund ein weiches Kissen.
  Urteil: Ohne erforderliche Korrektur: Grammatik, natürliche Lesart, Übersetzung und Zielbedeutung passen.
- `s30` / `05c17d0128f59d999888f372d60a266b`: Is the new office chair soft enough for Sofia?
  Deutsch: Ist der neue Bürostuhl weich genug für Sofia?
  Urteil: Ohne erforderliche Korrektur: Grammatik, natürliche Lesart, Übersetzung und Zielbedeutung passen.

#### sit|sit/VERB|sit#sitzen — `e40df1c1a5c0e85f3f57310a0403f23c`

- `s31` / `daa740c74247c8e1bd389fbe4dd96c1b`: Lina, please sit on this chair for the lesson.
  Deutsch: Lina, bitte setz dich für den Unterricht auf diesen Stuhl.
  Urteil: Imperativ sit fordert das Einnehmen der Sitzhaltung auf; deutsche Übersetzung setz dich ist passend.
- `s32` / `95c5662e6fec279934e73ae552caa608`: Luca and I often sit in the warm sun.
  Deutsch: Luca und ich sitzen oft in der warmen Sonne.
  Urteil: Ohne erforderliche Korrektur: Grammatik, natürliche Lesart, Übersetzung und Zielbedeutung passen.
- `s33` / `f1c4b00b981c5ed96adaf073f6182295`: Can Leo sit next to his sister at the party?
  Deutsch: Kann Leo auf der Feier neben seiner Schwester sitzen?
  Urteil: Ohne erforderliche Korrektur: Grammatik, natürliche Lesart, Übersetzung und Zielbedeutung passen.

#### heavy|heavy/ADJ|heavy#schwer — `e460f9ece1ea19fb736f42f25be70df8`

- `s34` / `7205aafcba7e8da79880c40daf9cd0fb`: Ali cannot lift the heavy tool box alone at work.
  Deutsch: Ali kann den schweren Werkzeugkasten bei der Arbeit nicht alleine heben.
  Urteil: Ohne erforderliche Korrektur: Grammatik, natürliche Lesart, Übersetzung und Zielbedeutung passen.
- `s35` / `800af824820bb0771d45728ddb12998d`: Is this big bag of cat litter too heavy for Ali?
  Deutsch: Ist dieser große Sack Katzenstreu zu schwer für Ali?
  Urteil: Ohne erforderliche Korrektur: Grammatik, natürliche Lesart, Übersetzung und Zielbedeutung passen.
- `s36` / `690bbc37c017d3cd840d49129c9e1444`: Please help Sofia with this heavy wooden table.
  Deutsch: Bitte hilf Sofia mit diesem schweren Holztisch.
  Urteil: Ohne erforderliche Korrektur: Grammatik, natürliche Lesart, Übersetzung und Zielbedeutung passen.

#### safe|safe/ADJ|safe#sicher — `eea254cdc9526712ece4523500018555`

- `s37` / `fc488f2369c17b62579814ae1191beab`: Luis feels safe in the quiet music hall.
  Deutsch: Luis fühlt sich im ruhigen Konzertsaal sicher.
  Urteil: Ohne erforderliche Korrektur: Grammatik, natürliche Lesart, Übersetzung und Zielbedeutung passen.
- `s38` / `e3bbbc57f7eddbd69fbe33618ada21d4`: Is Zoe safe at work during the storm?
  Deutsch: Ist Zoe während des Sturms bei der Arbeit sicher?
  Urteil: Ohne erforderliche Korrektur: Grammatik, natürliche Lesart, Übersetzung und Zielbedeutung passen.
- `s39` / `dc445cf5bc836bebb3ac3524eea873ba`: Sara walks on the busy street because it is safe.
  Deutsch: Sara geht auf der belebten Straße, weil sie sicher ist.
  Urteil: Belebtheit schließt Sicherheit nicht aus; keine logische Unmöglichkeit. Straße ist hier die Ortsangabe, keine Aufforderung zur Fahrbahnbenutzung.

### Reproduzierbare Entscheidungen

`pipeline/data/curation/everyday_merge_v1.json` enthält exakte Quellen, Kartenrefs, Satz-IDs/Labels, englischen Originaltext und ursprüngliche Übersetzung. Metadata-Vorbedingungen umfassen vollständige Quellzeilen; Wörterbuchentscheidungen die vollständige Variantenmenge. Unbekannte bzw. geänderte Konflikte brechen ab.

- 9 im Auftrag benannte Alternativen entfernt; zusätzlich missing/s25 peaceful: insgesamt 10. Historische Modellurteile unverändert. Redaktionelle Eingrenzung, kein Urteil über die allgemeine Grammatik dieser Ausdrücke.
- everyday/s53: Geschenkkarton → Geschenkbox. Englischer Text, Satz-ID, Tokens unverändert; editorial_reviews nennt explizit model_check=false.
- bus#bus eigenständig Bus- → Bus. Keine pauschale Korrektur anderer Kompositumsglossen.
- basket und lamp: allgemeiner Behälter bzw. Beleuchtungsgerät innen/außen. Tennis-/Wäschekorb und Gartenlampe behalten. Historische Auswahl unverändert.
- 92 explizite Sense-Metadatenentscheidungen, darunter Definitions-/Kurzglossen, Großschreibung und die zwei Präzisierungen. 75 konkrete Wörterbuchentscheidungen mit Quellen/verworfenen Varianten, darunter die Formkorrekturen bring→bringen, full→voll, pay→bezahlen, soft→weich, wash→waschen, station→Bahnhof. Keine neuen Sense-IDs.
- Wörterbuch aus sämtlichen 8.520 Tokens neu abgeleitet: 2.378 Form/Sense-Schlüssel; alle Herkunftseinträge stehen im finalization_report. Deckpositionen verwenden die bestehende Rangregel; Alltag hat jeweils genau eine ausgewählte Hauptbedeutung.
- Alte Pilot-Fragen bleiben offen: neun Gruppen aus finalize_curation.OPEN_EDITORIAL (u. a. your, singular they, like-Füllwort, will-Testament, bezeichnete Alt-Sätze/-Alternativen). Keine öffentliche Inhaltsfreigabe.

### Abschließender Status aller 100 Auswahlpositionen

O = geprüft übernommen; K = nach dokumentierter Korrektur übernommen; E = nach expliziter redaktioneller Entscheidung übernommen. Kein fehlender oder zurückgestellter Eintrag. Die ursprüngliche Zieldefinition bleibt hier absichtlich unverändert; Präzisierungen für basket/lamp siehe oben.

| Kartenreferenz | Ursprüngliche Zieldefinition | Quelle | Status |
|---|---|---|---|
| `table / table/NOUN / table#tisch` | Möbel mit waagerechter Platte zum Essen oder Arbeiten | everyday | O; 3/3 |
| `chair / chair/NOUN / chair#stuhl` | Sitzmöbel für eine Person mit Rückenlehne | everyday | O; 3/3 |
| `bed / bed/NOUN / bed#bett` | Möbel zum Schlafen | everyday | O; 3/3 |
| `pillow / pillow/NOUN / pillow#kissen` | Weiche Unterlage für den Kopf im Bett | everyday | O; 3/3 |
| `blanket / blanket/NOUN / blanket#decke` | Textile Decke zum Zudecken | everyday | O; 3/3 |
| `kitchen / kitchen/NOUN / kitchen#kueche` | Raum zum Zubereiten von Speisen | everyday | O; 3/3 |
| `plate / plate/NOUN / plate#teller` | Flaches Geschirr zum Servieren von Essen | everyday | O; 3/3 |
| `cup / cup/NOUN / cup#tasse` | Trinkgefäß mit Henkel | everyday | O; 3/3 |
| `spoon / spoon/NOUN / spoon#loeffel` | Besteck zum Essen von Suppe | everyday | O; 3/3 |
| `fork / fork/NOUN / fork#gabel` | Besteck mit Zinken | everyday | O; 3/3 |
| `knife / knife/NOUN / knife#messer` | Werkzeug mit Klinge zum Schneiden | everyday | O; 3/3 |
| `towel / towel/NOUN / towel#handtuch` | Tuch zum Abtrocknen | everyday | O; 3/3 |
| `soap / soap/NOUN / soap#seife` | Mittel zum Waschen der Hände | everyday | O; 3/3 |
| `mirror / mirror/NOUN / mirror#spiegel` | Gegenstand, in dem man sein Spiegelbild sieht | everyday | O; 3/3 |
| `window / window/NOUN / window#fenster` | Verglaste Öffnung in einer Wand | everyday | O; 3/3 |
| `speaker / speaker/NOUN / speaker#lautsprecher` | Gerät, das elektrische Signale als hörbaren Schall wiedergibt; keine sprechende Person | everyday | O; 3/3 |
| `bag / bag/NOUN / bag#tasche` | Tragbarer Behälter für persönliche Dinge | everyday | O; 3/3 |
| `key / key/NOUN / key#schluessel` | Gegenstand zum Öffnen eines Schlosses | everyday | E; 3/3 |
| `phone / phone/NOUN / phone#telefon` | Gerät zum Telefonieren | everyday | K; 3/3 |
| `bottle / bottle/NOUN / bottle#flasche` | Verschließbares Gefäß für Flüssigkeiten | everyday | O; 3/3 |
| `box / box/NOUN / box#schachtel` | Fester Behälter zum Aufbewahren von Dingen | everyday | E; 3/3 |
| `clock / clock/NOUN / clock#uhr` | Gerät zur Anzeige der Uhrzeit an Wand oder auf Tisch | everyday | O; 3/3 |
| `lamp / lamp/NOUN / lamp#lampen` | Gerät zur Beleuchtung eines Raums | everyday | E; 3/3 |
| `shirt / shirt/NOUN / shirt#hemd` | Kleidungsstück für den Oberkörper mit Kragen und Knöpfen | everyday | O; 3/3 |
| `shoe / shoe/NOUN / shoe#schuhe` | Kleidungsstück für einen Fuß | everyday | O; 3/3 |
| `shop / shop/NOUN / shop#geschaeft` | Ort, an dem Waren verkauft werden | everyday | O; 3/3 |
| `price / price/NOUN / price#preis` | Geldbetrag, den eine Ware kostet | everyday | O; 3/3 |
| `receipt / receipt/NOUN / receipt#kassenbon` | Beleg für einen bezahlten Einkauf | everyday | K; 3/3 |
| `basket / basket/NOUN / basket#korb` | Offener Behälter zum Tragen von Einkäufen | everyday | E; 3/3 |
| `bread / bread/NOUN / bread#brot` | Gebackenes Grundnahrungsmittel aus Mehl | everyday | O; 3/3 |
| `milk / milk/NOUN / milk#milch` | Flüssiges Lebensmittel von Kühen | everyday | O; 3/3 |
| `apple / apple/NOUN / apple#aepfel` | Runde essbare Frucht des Apfelbaums | everyday | O; 3/3 |
| `cheese / cheese/NOUN / cheese#kase` | Festes Lebensmittel aus Milch | everyday | O; 3/3 |
| `egg / egg/NOUN / egg#ei` | Hühnerei als Lebensmittel | everyday | O; 3/3 |
| `money / money/NOUN / money#geld` | Zahlungsmittel für Einkäufe | everyday | O; 3/3 |
| `office / office/NOUN / office#buero` | Raum für Schreibtischarbeit | everyday | O; 3/3 |
| `desk / desk/NOUN / desk#schreibtisch` | Tisch zum Arbeiten oder Schreiben | everyday | O; 3/3 |
| `computer / computer/NOUN / computer#computer` | Elektronisches Gerät zum Verarbeiten von Daten | everyday | O; 3/3 |
| `meeting / meeting/NOUN / meeting#besprechung` | Verabredetes Gespräch mehrerer Personen bei der Arbeit | everyday | O; 3/3 |
| `colleague / colleague/NOUN / colleague#kollege_oder_kollegin` | Person, mit der man zusammenarbeitet | everyday | O; 3/3 |
| `letter / letter/NOUN / letter#brief` | Schriftliche Nachricht, die man an jemanden schickt; kein Buchstabe | everyday | O; 3/3 |
| `paper / paper/NOUN / paper#papier` | Dünnes Material zum Schreiben oder Drucken | everyday | O; 3/3 |
| `bus / bus/NOUN / bus#bus` | Großes Fahrzeug zur Beförderung vieler Fahrgäste | everyday | K; 3/3 |
| `train / train/NOUN / train#zug` | Schienenfahrzeug zur Beförderung von Reisenden | everyday | O; 3/3 |
| `station / station/NOUN / station#bahnhof` | Ort, an dem Züge halten und Reisende einsteigen | everyday | O; 3/3 |
| `ticket / ticket/NOUN / ticket#fahrkarte` | Beleg für die Berechtigung zu einer Fahrt | everyday | O; 3/3 |
| `road / road/NOUN / road#strasse` | Befestigter Verkehrsweg für Fahrzeuge | everyday | E; 3/3 |
| `bicycle / bicycle/NOUN / bicycle#fahrrad` | Zweirädriges Fahrzeug mit Pedalantrieb | everyday | O; 3/3 |
| `car / car/NOUN / car#auto` | Kraftfahrzeug für wenige Personen | everyday | O; 3/3 |
| `bridge / bridge/NOUN / bridge#brucke` | Bauwerk, das einen Weg über ein Hindernis führt | everyday | O; 3/3 |
| `map / map/NOUN / map#karte` | Zeichnung zur Orientierung in einem Gebiet | everyday | O; 3/3 |
| `bandage / bandage/NOUN / bandage#verband` | Material zum Bedecken und Schützen einer Wunde; kein Verb | everyday | O; 3/3 |
| `hand / hand/NOUN / hand#hand` | Körperteil am Ende eines Arms | everyday | O; 3/3 |
| `head / head/NOUN / head#kopf` | Oberster Körperteil mit Gesicht und Gehirn | everyday | O; 3/3 |
| `eye / eye/NOUN / eye#auge` | Sinnesorgan zum Sehen | everyday | O; 3/3 |
| `foot / foot/NOUN / foot#fuss` | Körperteil am unteren Ende eines Beins | everyday | O; 3/3 |
| `arm / arm/NOUN / arm#arm` | Körperglied zwischen Schulter und Hand | everyday | O; 3/3 |
| `leg / leg/NOUN / leg#bein` | Körperglied zum Stehen und Gehen | everyday | O; 3/3 |
| `tooth / tooth/NOUN / tooth#zahn` | Hartes Gebilde im Mund zum Kauen | everyday | O; 3/3 |
| `skin / skin/NOUN / skin#haut` | Äußere schützende Schicht des Körpers | everyday | O; 3/3 |
| `wash / wash/VERB / wash#waescht` | Mit Wasser reinigen | everyday | O; 3/3 |
| `cook / cook/VERB / cook#kocht` | Essen durch Erhitzen zubereiten | everyday | O; 3/3 |
| `clean / clean/VERB / clean#putzen` | Schmutz von einem Gegenstand oder einer Fläche entfernen | everyday | O; 3/3 |
| `open / open/VERB / open#oeffnete` | Etwas bisher Geschlossenes zugänglich machen | everyday | O; 3/3 |
| `close / close/VERB / close#schliessen` | Etwas Offenes zumachen | everyday | O; 3/3 |
| `repair / repair/VERB / repair#repariert` | Etwas Beschädigtes wieder funktionsfähig machen | everyday | O; 3/3 |
| `cut / cut/VERB / cut#schneidet` | Mit einer scharfen Klinge teilen | everyday | O; 3/3 |
| `buy / buy/VERB / buy#kaufen` | Eine Ware gegen Geld erwerben | everyday | O; 3/3 |
| `pay / pay/VERB / pay#bezahlt` | Geld für eine Ware oder Leistung geben | everyday | O; 3/3 |
| `sell / sell/VERB / sell#verkaufen` | Eine Ware gegen Geld abgeben | everyday | O; 3/3 |
| `choose / choose/VERB / choose#waehlt-aus` | Sich zwischen mehreren Möglichkeiten entscheiden | everyday | O; 3/3 |
| `drive / drive/VERB / drive#faehrt` | Ein Kraftfahrzeug steuern | everyday | O; 3/3 |
| `walk / walk/VERB / walk#geht-zu-fuss` | Sich gehend fortbewegen | everyday | O; 3/3 |
| `carry / carry/VERB / carry#tragen` | Einen Gegenstand halten und mitnehmen | everyday | O; 3/3 |
| `bring / bring/VERB / bring#bringt` | Etwas zu einer Person oder an einen Ort tragen | everyday | K; 3/3 |
| `wait / wait/VERB / wait#warten` | Bis zu einem erwarteten Ereignis bleiben | everyday | O; 3/3 |
| `read / read/VERB / read#lesen` | Geschriebene Wörter erfassen | everyday | O; 3/3 |
| `write / write/VERB / write#schreiben` | Wörter schriftlich festhalten | everyday | O; 3/3 |
| `send / send/VERB / send#schicken` | Eine Nachricht an einen Empfänger übermitteln | everyday | K; 3/3 |
| `eat / eat/VERB / eat#essen` | Nahrung zu sich nehmen | everyday | O; 3/3 |
| `drink / drink/VERB / drink#trinkt` | Flüssigkeit zu sich nehmen | everyday | O; 3/3 |
| `sleep / sleep/VERB / sleep#schlafen` | Sich im natürlichen nächtlichen Ruhezustand befinden | everyday | O; 3/3 |
| `stand / stand/VERB / stand#stehen` | Mit aufrechtem Körper auf den Füßen sein | everyday | O; 3/3 |
| `sit / sit/VERB / sit#sitzen` | Auf einem Sitz mit abgestütztem Gesäß ruhen | missing | O; 3/3 |
| `listen / listen/VERB / listen#zuhoert` | Aufmerksam auf gehörte Sprache oder Geräusche achten | everyday | O; 3/3 |
| `empty / empty/ADJ / empty#leer` | Ohne Inhalt | everyday | O; 3/3 |
| `full / full/ADJ / full#vollen` | Bis zur verfügbaren Kapazität gefüllt | everyday | O; 3/3 |
| `dry / dry/ADJ / dry#trocken` | Nicht nass | everyday | O; 3/3 |
| `wet / wet/ADJ / wet#nass` | Mit Wasser oder anderer Flüssigkeit benetzt | missing | O; 3/3 |
| `soft / soft/ADJ / soft#weiche` | Bei Druck leicht nachgebend | missing | O; 3/3 |
| `hard / hard/ADJ / hard#hart` | Bei Druck kaum nachgebend | missing | O; 3/3 |
| `cheap / cheap/ADJ / cheap#billiger` | Wenig Geld kostend | missing | O; 3/3 |
| `expensive / expensive/ADJ / expensive#teuer` | Viel Geld kostend | missing | O; 3/3 |
| `young / young/ADJ / young#jung` | Erst wenige Lebensjahre alt | missing | O; 3/3 |
| `old / old/ADJ / old#alt` | Schon viele Lebensjahre alt | missing | O; 3/3 |
| `strong / strong/ADJ / strong#stark` | Viel körperliche Kraft besitzend | missing | O; 3/3 |
| `ready / ready/ADJ / ready#bereit` | Für eine anstehende Handlung vorbereitet | missing | O; 3/3 |
| `quiet / quiet/ADJ / quiet#ruhig` | Wenig Geräusche verursachend | missing | K; 3/3 |
| `safe / safe/ADJ / safe#sicher` | Keiner konkreten Gefahr ausgesetzt | missing | O; 3/3 |
| `heavy / heavy/ADJ / heavy#schwer` | Ein hohes Gewicht habend | missing | O; 3/3 |

table, speaker und bandage: jeweils unveränderte Zielkarte aus everyday, 3/3 geprüfte Sätze, übernommen.

### Technische Bereitstellung

Merge (Windows PowerShell, Repository-Root):
```powershell
pipeline/.venv/Scripts/python.exe -X utf8 pipeline/scripts/merge_everyday.py --out pipeline/out/curated_everyday_v1
```
macOS Terminal:
```bash
pipeline/.venv/bin/python -X utf8 pipeline/scripts/merge_everyday.py --out pipeline/out/curated_everyday_v1
```
Beide Systeme:
```text
dart run tool/stage_content_pack.dart --from pipeline/out/curated_everyday_v1
dart run build/everyday_review/read_asset.dart
dart run tool/inspect_new_card_selection.dart assets/content/en/content.sqlite build/everyday_review/user_before.db
```
Der Repository-Lesetest ist ein lokaler Prüfeinstieg unter build/, keine out-Abhängigkeit der Testsuite. Er öffnet ContentDatabase read-only, liest alle practiceItems, prüft 264/792 und schließt im finally.

Gezeigter Output: `status ok: 264 cards, 792 sentences, 792 links; all source card IDs retained`; alle 16 SQLite-Tabellen nach erneutem Öffnen vollständig mit build_rows verglichen. 1.199 Lemmas, 2.297 Senses, 2.378 Wörterbucheinträge, 8.520 Tokens. Neues Asset: 4.157.440 Bytes, SHA-256 `ebc12c0d0ba4909cc070e7f1d2e9c27c08fc3744bb7317d781c8af4b1d1df9a5`.

App-Repository: `REAL ASSET REPOSITORY: curated_everyday_v1; 264 cards; 792 sentences; 264 deck cards; all practice items readable`, danach `Repository closed`. Rollback-Dateien: `build/everyday_review/rollback/content.sqlite` und `content.manifest.json`; ursprünglicher Emulator-Lernstand: `build/everyday_review/user_before.db` (20 Karten, 19 Reviews).

Echte Auswahl: 264 Karten, 160 Formen, 152 normalisierte Lemmas, 138 Inhalts-/126 Funktionskarten. Unberührtes Profil, Größe 20: 16 unterschiedliche Inhaltswort-Lemmas und vier Funktionswörter; darunter neue old und money. Das bestehende Profil startet Größe 5 mit on/have/so/can/it, ohne of/in-Dopplungen. Reihenfolge der ersten noch ungesehenen Wörter bleibt rangbasiert, nicht künstlich auf neue Pack-Karten umsortiert.


### Abschließende Verifikation und Emulator

- Pipeline: `288 passed in 10.51s` (vollständige Offline-Suite).
- Flutter: `00:13 +210: All tests passed!`; Log `build/everyday_review/flutter-test.log`.
- Analyse nach den letzten Teständerungen: `No issues found! (ran in 2.1s)`.
- Neue synthetische Tests: explizite/unerwartete Metadatenkonflikte und genaue Vorbedingungen, redaktionelle Übersetzung ohne neue Modell-QA und mit unveränderten Text-IDs/Tokens, Formglosskorrektur mit sämtlichen Quellvarianten. Bestehende Merge-/Queue-Tests prüfen kollidierende Satzrefs, gemeinsame Wörterbuchquellen, stabile IDs und 4:1/Lemma-Vielfalt.
- Update-Test erweitert: echte synthetische user.db mit drei gebuchten Reviews bleibt beim Versionswechsel mini-v1→mini-v2 bytegleich; Content-Repository zuvor geschlossen.
- Der erste Flutter-Lauf fand genau einen veralteten Test: feste Erwartung 164/492 im optionalen Asset-Test. Er vergleicht jetzt unabhängig gelesene SQLite-Zahlen mit dem Repository und prüft weiterhin drei Sätze/Karte, IDs, Alternativen und unveränderten Asset-Hash; zweiter Gesamtlauf erfolgreich.
- Android emulator-5554: normale Debug-App per `adb install -r` aktualisiert, keine Deinstallation/kein Data Clear. Installierter Bestand `curated_everyday_v1`, 264 Karten. Home: 245 noch nicht angezeigt, 19 im Aufbau, 0 gemeistert, 0 fällig. Screenshot `build/everyday_review/home.png`.
- Neue Karte im Übungsablauf: temporärer Debug-Prüfeinstieg `build/everyday_review/emulator_smoke.dart` verwendet dieselben Produktions-Repositories, Queue und DeckSessionController. Er kopiert die vorhandene user.db in ein separates temporäres Verzeichnis und richtet nur seinen User-Provider auf diese Kopie. Testantworten ändern ausschließlich die Kopie. In einer regulär aufgebauten 30er-Queue wurde bis zur ersten neuen Alltag-Karte weitergeübt.
- Android-Log: `EVERYDAY_SMOKE NEW_CARD old 0b22b7e132d111536d3516884f74ab19 sentence=43ab66ffb9083f66b07aa777cfdb600b position=16/30`. Sichtbarer Satz: „Noah has an ___ dog that sleeps almost all day.“ / „Noah hat einen alten Hund, der fast den ganzen Tag schläft.“ Screenshot `build/everyday_review/new_card_android.png`.
- Danach normale Debug-APK wieder per `adb install -r` installiert und gestartet; auch `build/app/outputs/flutter-apk/app-debug.apk` enthält wieder den normalen Einstieg. Test-Kopie wurde nicht zurückgespielt.
- Nach normalem Update und nochmals nach dem Emulator-Smoke: alle Zeilen aller fünf fachlichen User-Tabellen exakt wie zuvor: user_cards 20, review_log 19, deck_settings 0, settings 1, local_submissions 0. Protokoll `build/everyday_review/userstate_check.json`. Keine Testantwort im echten Verlauf.
- 15 historische Quelldateien/Auswahlen per SHA-256 unverändert (inklusive aller drei Quellpacks und vorhandener Laufberichte). Alte Assets für Rückkehr unter `build/everyday_review/rollback/`; nicht als dauerhafte Datensicherung außerhalb des build-Verzeichnisses verstehen.
- iOS nicht ausgeführt. Keine Cloud-Aufrufe, Remote-Migrationen, Commits oder Pushes.

**Einziger nächster gebündelter Schritt:** Die neun dokumentierten Alt-Pilot-Fallgruppen redaktionell entscheiden, bevor eine öffentliche Inhaltsfreigabe erwogen wird. Für die 100er-Alltag-Auswahl ist weder Nachgenerierung noch Budgeterhöhung erforderlich.

Abschluss: `git diff --check` Exit 0; `git status --short` geprüft (vorbestehende Änderungen erhalten). Schutzprüfung: erneuter Merge auf bestehenden Zielordner mit Exit 2 verweigert, sämtliche drei Ausgabe-Hashes unverändert. NEXTSTEPS.md: 25 Zeilen.
