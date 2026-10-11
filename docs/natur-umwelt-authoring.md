# Natur & Umwelt: Authoring und Abschluss

## Aktueller Abschlussstatus – 10.10.2026

242/242 Originalziele sind mit je einem festen aktiven Satz in natur_umwelt_batch_3_v1 offline importiert und intern gestagt. Partition 242 importiert / 0 aktuell / 0 später. Kein Restbatch und keine Batch-4-ZIP. Alle Originalidentitäten, Definitionen, cards.learning, Besitzer, Aliase und Originalpositionen vollständig abgeglichen. Insgesamt 2121 primäre Lernziele in acht Stapeln: 160/489/241/245/245/249/250/242.

Alle 18 SQLite-Tabellen, Asset-Verifikation, Achtstapel-Lesetest, 123 Pipeline-Tests plus 19 Untertests und Flutter-Analyse bestanden. Asset und Manifest vor Staging gesichert und gegen Ausgangshashes geprüft. Alle sechs früheren Natur-Tokenkorrekturen erhalten; im letzten Batch eine weitere reine Wörterbuchbindung bei prevent erosion gezielt korrigiert. Tatsächliche Outputs, Hashes und Vorher/Nachher: [Batch-3-Abschlussbericht](natur-umwelt-batch-3-import.md).

Die [Roadmap](content-roadmap-v1.md) bleibt auf genau 14 Stapel begrenzt. Nächster Schritt ist ausschließlich der gemeinsame technische Plan für die drei Unregelmäßige-Verben-Stapel vor deren Auswahl. Keine Verbenauswahl, Reservierung, Schemaänderung oder zusätzlichen Sätze in diesem Auftrag. Internes Test-Pack; Geräteprüfung, unabhängige menschliche Sprachfreigabe und öffentliche Inhaltsfreigabe nicht durchgeführt. Bekannte Altbefunde bleiben erhalten.

## Historischer Auswahl- und Batch-1-Vorbereitungsstand

Die folgenden Angaben dokumentieren die ursprüngliche Auswahl und damalige Übergabe. Die damalige Satzredaktion und alle drei Importbatches sind inzwischen abgeschlossen; die historischen Auswahldateien und ZIPs bleiben unverändert.


Stand: 10.10.2026. 694 Kandidaten geprüft, 242 klar abgegrenzte Lernziele ausgewählt und 452 ausgeschlossen oder begründet zurückgestellt. Qualität vor Sollzahl: keine Ergänzung bloß zum Erreichen von 250. Drei Gruppen mit 81/81/80 Zielen; alle acht Themen in jeder Gruppe. 190 Substantive, 28 Verben und 24 Adjektive. 30 vorhandene Wörterbuchbedeutungen werden unverändert wiederverwendet; 212 neue Bedeutungen sind ausdrücklich definiert.

Nur Vorbereitung: keine neuen Übungssätze, Satzübersetzungen, Tokenannotationen oder Alternativantworten. Kein Import oder Staging. Basis essen_trinken_batch_3_v1, Schema 3, 1994 Karten und 1879 primäre Lernziele in sieben Stapeln bleibt unverändert.

## Auswahl und Abgrenzung

Die Auswahl wurde gegen alle aktuellen Karten, normalisierte Formen, gelernte Lemmas, Formen gelernter Senses, vorhandene Satzalternativen, 22 historische Besitzregistrys und 16 historische Lerngruppendateien geprüft. Keine Verschiebung alten Wortbesitzes. Alle 1890 bisherigen Besitzer und 1994 bestehenden Karten-Gruppenbindungen bleiben erhalten; neue Registry insgesamt 2132 reservierte Wörter, davon 242 neue Köpfe. Reservierungen erzeugen keine Inhaltszeilen.

Jedes Ziel enthält Form, Lemma/POS, kurze deutsche Anzeigeübersetzung, präzise deutsche und englische Zieldefinition, bestehenden oder neuen Sense-Key, stabile Lemma-/Sense-/Karten-IDs, cards.learning, Besitzer, Aliase, Thema und eingefrorene Originalposition. Bestehende Sensezeilen bleiben einschließlich historischer Glossen und eventuell fehlender definition_de unverändert; die zusätzliche verbindliche target_meaning_de ist für jedes Ziel vollständig. Fehlende Altdefinitionen sind keine Platzhalter für neue Bedeutungen.

Konkrete redaktionelle Entscheidungen:

- waste entfällt neben gelerntem rubbish; regulation neben rule; purify neben clean. coastline/riverbank wurden als unnötige zusätzliche Küsten-/Uferspezialisierungen zurückgestellt. daylight überschneidet sich mit gelerntem sunlight.
- toxic und poisonous erhalten keinen zweiten Kopf: ausgewählt ist poisonous. brook/creek sind Kandidatenvarianten von stream, keine eigenen Ziele. Weitere Tier-/Pflanzenarten wurden zurückgestellt, um keine Artenliste zur Mengenerfüllung zu bilden.
- pine und jaw teilen die deutsche Anzeige „Kiefer“, bezeichnen aber Baum und Körperteil. float und swim teilen „Schwimmen“: float bedeutet passiv von Wasser getragen bleiben, swim aktive Fortbewegung. Definitionen und Lernabsichten sind getrennt; keine Synonymfreigabe.
- nature bezeichnet die nicht geschaffene Welt, environment die umgebenden Bedingungen, wilderness ein wenig verändertes Gebiet, habitat den Lebensraum einer Art und ecosystem dessen Wechselwirkungen. Diese Begriffe sind keine austauschbaren Übersetzungen.
- sewage bezeichnet Abwasser mit menschlichen Ausscheidungen; wastewater auch Wasch-/Industriewasser. Spätere Sätze müssen diesen bewusst getrennten Umfang zeigen. litter ist achtlos im öffentlichen Raum zurückgelassener Müll, kein zweiter allgemeiner rubbish-Kopf.
- renewable beschreibt natürliche Erneuerbarkeit, sustainable langfristige Tragfähigkeit. Wiederverwendbar, recycelbar und biologisch abbaubar sind verschiedene Eigenschaften. Natürlich bedeutet nicht automatisch umweltfreundlich.
- harmful beschreibt schädigende Wirkung, gelerntes dangerous ein Schadensrisiko. brittle ist das Brechen statt Biegen eines Materials; fragile wird für die Störungsanfälligkeit von Systemen reserviert.
- flock wird gezielt als Vogelschwarm gewählt, swarm als Insektenschwarm und herd für größere Tiere. Keine zwei Schafherden-Köpfe. Deer ist der Familienbegriff, nicht ausschließlich ein männliches Tier.
- hill verwendet den vorhandenen NOUN-Sense, nicht den historischen PROPN-Eintrag. rock meint Fels statt Rockmusik; bark Baumrinde statt Bellen; extract ist Gewinnung als Verb statt Vanilleextrakt-Nomen. liquid nutzt das bestehende Flüssigkeitsnomen; leak den Behälterverlust-Sense.
- efficiency ist ein messbares Verhältnis als Nomen; die vorhandene Adjektivkarte efficient bleibt erhalten. electricity ist elektrischer Strom; gelerntes energy betrifft verfügbare körperliche/geistige Kraft. Neue Gruppen sind explizite Einzelköpfe, keine umgedeuteten Bestandsgruppen.
- aluminium/aluminum und fertiliser/fertilizer reservieren je einen Kopf mit orthografischem Alias. Regionale oder lexikalische Synonyme sind davon getrennt. Keine der Reservierungen erteilt eine automatische Lückenantwortfreigabe. eco-friendly ist eine gebräuchliche lexikalische Bindestricheinheit; künstliche Formen carbon-dioxide und light-pollution wurden nicht übernommen.

Die Definitions- und Bestandsbelege stehen je Eintrag unter review; 48 gemeinsame Abgrenzungsentscheidungen stehen unter semantic_decisions. Innerhalb der Auswahl gibt es keine doppelte deutsche Anzeigeübersetzung. Frequenzen sind Kontext, keine behauptete CEFR-Zertifizierung. Einige sachbezogene Wörter wie deciduous, geothermal oder estuary sind anspruchsvoller; sie benennen konkrete relevante Konzepte und dienen nicht als Mengenfüller. Die Auswahl bleibt unter 250.

## Themen und Gruppen

| Thema | Gesamt | Batch 1 | Batch 2 | Batch 3 |
|---|---:|---:|---:|---:|
| Wetter und Temperatur | 18 | 6 | 6 | 6 |
| Landschaften und Gewässer | 25 | 9 | 8 | 8 |
| Pflanzen, Bäume und Pflanzenteile | 36 | 12 | 12 | 12 |
| Tiere und ihre Lebensräume | 45 | 15 | 15 | 15 |
| Naturvorgänge und Jahreszeiten | 24 | 8 | 8 | 8 |
| Materialien und natürliche Ressourcen | 34 | 11 | 12 | 11 |
| Umwelt, Abfall und Recycling | 28 | 9 | 9 | 10 |
| Klima, Energie und Naturschutz | 32 | 11 | 11 | 10 |

Die pro Thema rotierende Zuteilung bevorzugt jeweils die kleinsten Gruppen. Die endgültige Reihenfolge mischt Themen und vermeidet benachbarte gemeinsame Kontrasttags sowohl insgesamt als auch je Batch. Diese Originalpositionen und Identitäten sind ab der Auswahl verbindlich. Die bestehende App-Lernreihenfolge bleibt unverändert.

Batch 1: 0 importiert / 81 aktuell / 161 später, Anzeige 1–81. Batch 2 hängt 82–162 an und ordnet hashgebunden auf 1–162 um. Batch 3 hängt 163–242 an und ordnet auf 1–242 um. Der vorhandene Displayvertrag wurde nur im Speicher mit Mitgliedschaftszeilen simuliert; keine neuen Karten oder Mitgliedschaften in den Basis-Pack geschrieben.

## Verbindliche Auswahl

Vollständige Definitionen, stabile Identitäten, Besitz und cards.learning befinden sich in pipeline/data/selection/natur_umwelt_v1.json sowie identisch im Batch-1-Kontext und der ZIP.

| Position | Form | POS | Anzeige | Batch | Sense |
|---:|---|---|---|---:|---|
| 1 | animal | NOUN | Tier | 2 | neu definiert |
| 2 | predator | NOUN | Raubtier | 1 | neu definiert |
| 3 | species | NOUN | Art | 3 | neu definiert |
| 4 | prey | NOUN | Beute | 2 | neu definiert |
| 5 | mammal | NOUN | Säugetier | 1 | neu definiert |
| 6 | livestock | NOUN | Nutzvieh | 3 | neu definiert |
| 7 | bird | NOUN | Vogel | 2 | bestehend |
| 8 | herd | NOUN | Herde | 1 | neu definiert |
| 9 | insect | NOUN | Insekt | 3 | neu definiert |
| 10 | plant | NOUN | Pflanze | 2 | bestehend |
| 11 | flock | NOUN | Vogelschwarm | 2 | neu definiert |
| 12 | tree | NOUN | Baum | 3 | bestehend |
| 13 | swarm | NOUN | Insektenschwarm | 3 | neu definiert |
| 14 | resource | NOUN | Ressource | 2 | neu definiert |
| 15 | hedge | NOUN | Hecke | 1 | neu definiert |
| 16 | nest | NOUN | Nest | 1 | neu definiert |
| 17 | renewable | ADJ | Erneuerbar | 3 | neu definiert |
| 18 | lawn | NOUN | Rasen | 2 | neu definiert |
| 19 | burrow | NOUN | Erdbau | 2 | neu definiert |
| 20 | electricity | NOUN | Elektrischer Strom | 1 | neu definiert |
| 21 | metal | NOUN | Metall | 1 | bestehend |
| 22 | flower | NOUN | Blüte | 3 | bestehend |
| 23 | hive | NOUN | Bienenstock | 3 | neu definiert |
| 24 | emission | NOUN | Ausstoß | 2 | neu definiert |
| 25 | ore | NOUN | Erz | 2 | neu definiert |
| 26 | petal | NOUN | Blütenblatt | 1 | neu definiert |
| 27 | habitat | NOUN | Lebensraum | 1 | neu definiert |
| 28 | carbon | NOUN | Kohlenstoff | 3 | neu definiert |
| 29 | coal | NOUN | Kohle | 3 | neu definiert |
| 30 | pollen | NOUN | Blütenstaub | 2 | neu definiert |
| 31 | feather | NOUN | Feder | 2 | neu definiert |
| 32 | greenhouse | NOUN | Gewächshaus | 1 | neu definiert |
| 33 | gas | NOUN | Gas | 1 | neu definiert |
| 34 | seed | NOUN | Samen | 3 | bestehend |
| 35 | fur | NOUN | Fell | 3 | neu definiert |
| 36 | environment | NOUN | Umwelt | 3 | neu definiert |
| 37 | conservation | NOUN | Naturschutz | 2 | neu definiert |
| 38 | timber | NOUN | Bauholz | 2 | neu definiert |
| 39 | root | NOUN | Wurzel | 1 | neu definiert |
| 40 | claw | NOUN | Kralle | 1 | neu definiert |
| 41 | pollution | NOUN | Umweltverschmutzung | 1 | neu definiert |
| 42 | sustainable | ADJ | Nachhaltig | 3 | neu definiert |
| 43 | trunk | NOUN | Baumstamm | 2 | neu definiert |
| 44 | charcoal | NOUN | Holzkohle | 3 | neu definiert |
| 45 | paw | NOUN | Pfote | 2 | neu definiert |
| 46 | litter | NOUN | Herumliegender Müll | 2 | neu definiert |
| 47 | solar | ADJ | Solar | 1 | neu definiert |
| 48 | bark | NOUN | Baumrinde | 3 | neu definiert |
| 49 | clay | NOUN | Ton | 1 | neu definiert |
| 50 | hoof | NOUN | Huf | 3 | neu definiert |
| 51 | nature | NOUN | Natur | 1 | neu definiert |
| 52 | landfill | NOUN | Mülldeponie | 3 | neu definiert |
| 53 | hydropower | NOUN | Wasserkraft | 2 | neu definiert |
| 54 | branch | NOUN | Ast | 1 | neu definiert |
| 55 | plastic | NOUN | Kunststoff | 2 | bestehend |
| 56 | beak | NOUN | Schnabel | 1 | neu definiert |
| 57 | summer | NOUN | Sommer | 2 | bestehend |
| 58 | wilderness | NOUN | Wildnis | 2 | neu definiert |
| 59 | sewage | NOUN | Abwasser | 1 | neu definiert |
| 60 | turbine | NOUN | Turbine | 3 | neu definiert |
| 61 | leaf | NOUN | Blatt | 2 | bestehend |
| 62 | limestone | NOUN | Kalkstein | 3 | neu definiert |
| 63 | wing | NOUN | Flügel | 2 | neu definiert |
| 64 | autumn | NOUN | Herbst | 3 | neu definiert |
| 65 | rainforest | NOUN | Regenwald | 3 | bestehend |
| 66 | wastewater | NOUN | Gebrauchtes Wasser | 2 | neu definiert |
| 67 | granite | NOUN | Granit | 1 | neu definiert |
| 68 | insulation | NOUN | Dämmung | 1 | neu definiert |
| 69 | needle | NOUN | Nadel | 3 | neu definiert |
| 70 | tail | NOUN | Schwanz | 3 | neu definiert |
| 71 | winter | NOUN | Winter | 1 | bestehend |
| 72 | dune | NOUN | Düne | 1 | neu definiert |
| 73 | packaging | NOUN | Verpackung | 3 | neu definiert |
| 74 | marble | NOUN | Marmor | 2 | neu definiert |
| 75 | cone | NOUN | Zapfen | 1 | neu definiert |
| 76 | efficiency | NOUN | Effizienz | 2 | neu definiert |
| 77 | fin | NOUN | Flosse | 1 | neu definiert |
| 78 | dawn | NOUN | Morgendämmerung | 2 | neu definiert |
| 79 | peninsula | NOUN | Halbinsel | 2 | neu definiert |
| 80 | carton | NOUN | Pappbehälter | 1 | neu definiert |
| 81 | consumption | NOUN | Verbrauch | 3 | neu definiert |
| 82 | copper | NOUN | Kupfer | 3 | neu definiert |
| 83 | moss | NOUN | Moos | 2 | neu definiert |
| 84 | web | NOUN | Spinnennetz | 2 | neu definiert |
| 85 | dusk | NOUN | Abenddämmerung | 3 | neu definiert |
| 86 | gravel | NOUN | Kies | 3 | neu definiert |
| 87 | reusable | ADJ | Wiederverwendbar | 2 | neu definiert |
| 88 | generate | VERB | Erzeugen | 1 | neu definiert |
| 89 | steel | NOUN | Stahl | 1 | neu definiert |
| 90 | fern | NOUN | Farn | 3 | neu definiert |
| 91 | caterpillar | NOUN | Raupe | 3 | neu definiert |
| 92 | growth | NOUN | Wachstum | 1 | bestehend |
| 93 | mainland | NOUN | Festland | 1 | neu definiert |
| 94 | disposable | ADJ | Zum Wegwerfen | 3 | neu definiert |
| 95 | fossil | NOUN | Fossil | 2 | neu definiert |
| 96 | geothermal | ADJ | Geothermisch | 2 | neu definiert |
| 97 | nettle | NOUN | Brennnessel | 1 | neu definiert |
| 98 | butterfly | NOUN | Schmetterling | 1 | neu definiert |
| 99 | sun | NOUN | Sonne | 1 | bestehend |
| 100 | decay | NOUN | Zerfall | 2 | neu definiert |
| 101 | stream | NOUN | Bach | 2 | neu definiert |
| 102 | recyclable | ADJ | Recycelbar | 1 | neu definiert |
| 103 | aluminium | NOUN | Aluminium | 3 | neu definiert |
| 104 | nuclear | ADJ | Nuklear | 3 | neu definiert |
| 105 | weed | NOUN | Unkraut | 2 | neu definiert |
| 106 | bee | NOUN | Biene | 2 | bestehend |
| 107 | moon | NOUN | Mond | 2 | neu definiert |
| 108 | erosion | NOUN | Erosion | 3 | neu definiert |
| 109 | pond | NOUN | Teich | 3 | neu definiert |
| 110 | biodegradable | ADJ | Biologisch abbaubar | 2 | neu definiert |
| 111 | radiation | NOUN | Strahlung | 1 | neu definiert |
| 112 | gold | NOUN | Gold | 1 | neu definiert |
| 113 | thorn | NOUN | Dorn | 3 | neu definiert |
| 114 | beetle | NOUN | Käfer | 3 | neu definiert |
| 115 | drought | NOUN | Dürre | 3 | neu definiert |
| 116 | gravity | NOUN | Schwerkraft | 1 | neu definiert |
| 117 | hill | NOUN | Hügel | 1 | bestehend |
| 118 | harmful | ADJ | Schädlich | 3 | neu definiert |
| 119 | oxygen | NOUN | Sauerstoff | 2 | neu definiert |
| 120 | silver | NOUN | Silber | 2 | neu definiert |
| 121 | oak | NOUN | Eiche | 1 | neu definiert |
| 122 | mosquito | NOUN | Stechmücke | 1 | neu definiert |
| 123 | thunderstorm | NOUN | Gewitter | 1 | neu definiert |
| 124 | avalanche | NOUN | Lawine | 2 | neu definiert |
| 125 | rock | NOUN | Fels | 2 | bestehend |
| 126 | atmosphere | NOUN | Atmosphäre | 3 | neu definiert |
| 127 | pine | NOUN | Kiefer | 2 | neu definiert |
| 128 | contaminate | VERB | Verunreinigen | 1 | neu definiert |
| 129 | cardboard | NOUN | Pappe | 3 | bestehend |
| 130 | spider | NOUN | Spinne | 2 | neu definiert |
| 131 | hail | NOUN | Hagel | 2 | neu definiert |
| 132 | landslide | NOUN | Erdrutsch | 3 | neu definiert |
| 133 | ozone | NOUN | Ozon | 1 | neu definiert |
| 134 | pebble | NOUN | Kieselstein | 3 | neu definiert |
| 135 | discard | VERB | Wegwerfen | 2 | neu definiert |
| 136 | leather | NOUN | Leder | 1 | bestehend |
| 137 | evergreen | ADJ | Immergrün | 1 | neu definiert |
| 138 | snail | NOUN | Schnecke | 3 | neu definiert |
| 139 | snowflake | NOUN | Schneeflocke | 3 | neu definiert |
| 140 | earthquake | NOUN | Erdbeben | 1 | neu definiert |
| 141 | biodiversity | NOUN | Artenvielfalt | 2 | neu definiert |
| 142 | slope | NOUN | Hang | 1 | neu definiert |
| 143 | sort | VERB | Sortieren | 3 | neu definiert |
| 144 | soil | NOUN | Boden | 3 | neu definiert |
| 145 | sawdust | NOUN | Sägemehl | 2 | neu definiert |
| 146 | frog | NOUN | Frosch | 1 | neu definiert |
| 147 | sleet | NOUN | Schneeregen | 1 | neu definiert |
| 148 | eruption | NOUN | Vulkanausbruch | 2 | neu definiert |
| 149 | ecosystem | NOUN | Ökosystem | 3 | neu definiert |
| 150 | separate | VERB | Trennen | 1 | bestehend |
| 151 | meadow | NOUN | Wiese | 2 | neu definiert |
| 152 | soot | NOUN | Ruß | 3 | neu definiert |
| 153 | deciduous | ADJ | Laubabwerfend | 2 | neu definiert |
| 154 | snake | NOUN | Schlange | 2 | neu definiert |
| 155 | flood | NOUN | Überschwemmung | 2 | neu definiert |
| 156 | lava | NOUN | Lava | 3 | neu definiert |
| 157 | extinction | NOUN | Aussterben | 1 | neu definiert |
| 158 | recycle | VERB | Recyceln | 2 | neu definiert |
| 159 | wetland | NOUN | Feuchtgebiet | 3 | neu definiert |
| 160 | rust | NOUN | Rost | 1 | neu definiert |
| 161 | poisonous | ADJ | Giftig | 3 | neu definiert |
| 162 | squirrel | NOUN | Eichhörnchen | 3 | neu definiert |
| 163 | freeze | VERB | Gefrieren | 3 | neu definiert |
| 164 | flame | NOUN | Flamme | 1 | neu definiert |
| 165 | sanctuary | NOUN | Schutzgebiet | 2 | neu definiert |
| 166 | reef | NOUN | Riff | 1 | neu definiert |
| 167 | solid | ADJ | Fest | 2 | neu definiert |
| 168 | smog | NOUN | Smog | 3 | neu definiert |
| 169 | prune | VERB | Zurückschneiden | 1 | neu definiert |
| 170 | hedgehog | NOUN | Igel | 1 | neu definiert |
| 171 | spark | NOUN | Funke | 2 | neu definiert |
| 172 | gust | NOUN | Windstoß | 1 | bestehend |
| 173 | ranger | NOUN | Parkwächter | 3 | neu definiert |
| 174 | coral | NOUN | Koralle | 2 | neu definiert |
| 175 | liquid | NOUN | Flüssigkeit | 3 | bestehend |
| 176 | exhaust | NOUN | Abgas | 1 | neu definiert |
| 177 | mow | VERB | Mähen | 2 | neu definiert |
| 178 | fox | NOUN | Fuchs | 2 | neu definiert |
| 179 | wildfire | NOUN | Vegetationsbrand | 3 | neu definiert |
| 180 | hurricane | NOUN | Hurrikan | 2 | neu definiert |
| 181 | poaching | NOUN | Wilderei | 1 | neu definiert |
| 182 | estuary | NOUN | Flussmündung | 3 | neu definiert |
| 183 | noise | NOUN | Lärm | 2 | bestehend |
| 184 | brittle | ADJ | Spröde | 1 | neu definiert |
| 185 | sow | VERB | Säen | 3 | neu definiert |
| 186 | deer | NOUN | Hirsch | 3 | neu definiert |
| 187 | tornado | NOUN | Tornado | 3 | neu definiert |
| 188 | flow | VERB | Fließen | 1 | bestehend |
| 189 | deforestation | NOUN | Entwaldung | 2 | neu definiert |
| 190 | iceberg | NOUN | Eisberg | 1 | neu definiert |
| 191 | transparent | ADJ | Durchsichtig | 2 | neu definiert |
| 192 | leak | VERB | Auslaufen | 3 | bestehend |
| 193 | fertile | ADJ | Fruchtbar | 1 | neu definiert |
| 194 | whale | NOUN | Wal | 1 | neu definiert |
| 195 | drip | VERB | Tropfen | 2 | bestehend |
| 196 | humid | ADJ | Feucht | 1 | neu definiert |
| 197 | survive | VERB | Überleben | 3 | neu definiert |
| 198 | crater | NOUN | Krater | 2 | neu definiert |
| 199 | absorb | VERB | Aufsaugen | 3 | neu definiert |
| 200 | overflow | VERB | Überlaufen | 1 | neu definiert |
| 201 | harvest | VERB | Ernten | 2 | neu definiert |
| 202 | dolphin | NOUN | Delfin | 2 | neu definiert |
| 203 | splash | VERB | Spritzen | 3 | bestehend |
| 204 | rainbow | NOUN | Regenbogen | 2 | neu definiert |
| 205 | canyon | NOUN | Schlucht | 3 | neu definiert |
| 206 | extract | VERB | Gewinnen | 1 | neu definiert |
| 207 | pesticide | NOUN | Pflanzenschutzmittel | 3 | neu definiert |
| 208 | shortage | NOUN | Mangel | 1 | neu definiert |
| 209 | crop | NOUN | Nutzpflanze | 3 | neu definiert |
| 210 | owl | NOUN | Eule | 3 | neu definiert |
| 211 | float | VERB | Schwimmen | 1 | neu definiert |
| 212 | overcast | ADJ | Bedeckt | 3 | neu definiert |
| 213 | filter | VERB | Filtern | 2 | neu definiert |
| 214 | quarry | NOUN | Steinbruch | 2 | neu definiert |
| 215 | horizon | NOUN | Horizont | 1 | neu definiert |
| 216 | orchard | NOUN | Obstgarten | 1 | neu definiert |
| 217 | eco-friendly | ADJ | Umweltfreundlich | 2 | neu definiert |
| 218 | graze | VERB | Grasen | 1 | neu definiert |
| 219 | drift | VERB | Treiben | 2 | neu definiert |
| 220 | blizzard | NOUN | Schneesturm | 1 | neu definiert |
| 221 | refine | VERB | Raffinieren | 3 | neu definiert |
| 222 | fertiliser | NOUN | Dünger | 1 | neu definiert |
| 223 | reservoir | NOUN | Stausee | 2 | neu definiert |
| 224 | sap | NOUN | Pflanzensaft | 2 | neu definiert |
| 225 | awareness | NOUN | Bewusstsein | 3 | neu definiert |
| 226 | hatch | VERB | Schlüpfen | 2 | neu definiert |
| 227 | pollinate | VERB | Bestäuben | 3 | neu definiert |
| 228 | dew | NOUN | Tau | 2 | neu definiert |
| 229 | compost | NOUN | Kompost | 2 | neu definiert |
| 230 | natural | ADJ | Natürlich | 1 | bestehend |
| 231 | bud | NOUN | Knospe | 3 | neu definiert |
| 232 | puddle | NOUN | Pfütze | 3 | bestehend |
| 233 | ban | NOUN | Verbot | 1 | neu definiert |
| 234 | migrate | VERB | Wandern | 3 | neu definiert |
| 235 | dormant | ADJ | Ruhend | 1 | neu definiert |
| 236 | synthetic | ADJ | Synthetisch | 2 | bestehend |
| 237 | heatwave | NOUN | Hitzewelle | 3 | neu definiert |
| 238 | footprint | NOUN | Umweltbelastung | 3 | neu definiert |
| 239 | stem | NOUN | Stängel | 1 | neu definiert |
| 240 | mud | NOUN | Schlamm | 1 | bestehend |
| 241 | fragile | ADJ | Empfindlich | 2 | neu definiert |
| 242 | hibernate | VERB | Winterschlaf halten | 1 | neu definiert |

## Ausschlüsse und Zurückstellungen

Bestandsbelege enthalten in der Originalauswahl die genaue Karte, Gruppe beziehungsweise historische Registry. Bei bereits gebundenen Formen ist der Bestandsschutz entscheidend; bei freien Formen gelten die redaktionellen Gründe. Zurückstellung ist keine Behauptung, dass alle Begriffe synonym seien.

| Kandidat | Grund | Erster Bestandsbeleg |
|---|---|---|
| weather | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Engere Wetterausprägung oder weniger priorisierte Bezeichnung; die ausgewählten Warnlagen und Grundbegriffe sind ausreichend, keine künstliche Mengenerfüllung. | weather / weather/NOUN / weather#wetter; en:card:c4c36e972028c6cc84a1ec9338874312 |
| landscape | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Weitere Gelände-/Gewässerunterart oder Lagebeschreibung zurückgestellt; vorhandene Begriffe und präzise ausgewählte Landschaftsformen priorisiert. | landscape / landscape/NOUN / landscape#landschaft; en:learning:landscape:v1 |
| season | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Engerer Vorgang oder Zustandsbegriff zurückgestellt; ausgewählte alltagstaugliche Naturereignisse priorisiert. | season / season/VERB / season#wurzen; en:card:d943e495508115f9c7006e04db312c82 |
| material | Zu breit für eine zusätzliche konkrete Materialabsicht; metal, plastic, cardboard und leather werden einzeln bestimmt. | — |
| climate | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Zusätzlicher Fach-, Verwaltungs- oder zusammengesetzter Energiebegriff zurückgestellt; zentrale alltagstaugliche Begriffe priorisiert. | climate / climate/NOUN / climate#klima; en:card:ea2976f8e71308dd72972aad0db647a9 |
| temperature | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Engerer Vorgang oder Zustandsbegriff zurückgestellt; ausgewählte alltagstaugliche Naturereignisse priorisiert. | temperature / temperature/NOUN / temperature#temperatur; en:card:d6b0fa3e98869d4922336d53e7adc9aa |
| scenery | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Weitere Gelände-/Gewässerunterart oder Lagebeschreibung zurückgestellt; vorhandene Begriffe und präzise ausgewählte Landschaftsformen priorisiert. | scenery / scenery/NOUN / scenery#landschaft; en:learning:landscape:v1 |
| wildlife | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Zusätzlicher Fach-, Verwaltungs- oder zusammengesetzter Energiebegriff zurückgestellt; zentrale alltagstaugliche Begriffe priorisiert. | wildlife / wildlife/NOUN / wildlife#wildtiere; en:card:1c2a14b16d1f4b3300982f4e47f6b342 |
| spring | Jahreszeit und Quelle sind verschiedene mögliche Natur-Senses; keine zusätzliche Mehrdeutigkeitsreservierung. Jahreszeitenkontext bleibt mit summer/autumn/winter abgedeckt. | — |
| energy | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Zusätzlicher Fach-, Verwaltungs- oder zusammengesetzter Energiebegriff zurückgestellt; zentrale alltagstaugliche Begriffe priorisiert. | energy / energy/NOUN / energy#energie; en:card:81b6745df03b59ad2a84e08da381dfbf |
| forecast | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Engere Wetterausprägung oder weniger priorisierte Bezeichnung; die ausgewählten Warnlagen und Grundbegriffe sind ausreichend, keine künstliche Mengenerfüllung. | forecast / forecast/NOUN / forecast#wettervorhersage; en:card:9735877defb470180af5322f5de39407 |
| countryside | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Weitere Gelände-/Gewässerunterart oder Lagebeschreibung zurückgestellt; vorhandene Begriffe und präzise ausgewählte Landschaftsformen priorisiert. | countryside / countryside/NOUN / countryside#laendliche-gegend; en:card:c95d9954f5cb9a82339bf7c1eaf32d5f |
| bush | Busch/Strauch überschneiden sich stark; statt zwei Köpfen bleiben hier plant, tree und die angelegte hedge. Nicht als Alias reserviert. | — |
| pollutant | Zusätzliche Abfallableitung, Infrastruktur oder Eigenschaft zurückgestellt; landfill, sewage/wastewater und ausdrücklich unterschiedliche reusable/recyclable/biodegradable priorisiert. | — |
| sunshine | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Engerer Vorgang oder Zustandsbegriff zurückgestellt; ausgewählte alltagstaugliche Naturereignisse priorisiert. | sunshine / sunshine/NOUN / sunshine#sonnenschein; en:card:fcc790c71bc4e60006b9fb327330efc4 |
| shrub | Busch/Strauch überschneiden sich stark; statt zwei Köpfen bleiben hier plant, tree und die angelegte hedge. Nicht als Alias reserviert. | — |
| finite | Mengen-/Verfügbarkeitsfeld wird durch resource und shortage abgedeckt; keine zusätzlichen Gegenpol- und Ableitungsköpfe. | — |
| waste | Bedeutung bereits als rubbish#mull gelernt; keine konkurrierende Abfallkarte. | — |
| power | Energieherstellung und Nutzung über electricity, generate und consumption präzisiert; power bleibt wegen breiter Mehrdeutigkeit zurückgestellt. | — |
| sunlight | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Engerer Vorgang oder Zustandsbegriff zurückgestellt; ausgewählte alltagstaugliche Naturereignisse priorisiert. | sunlight / sunlight/NOUN / sunlight#sonnenlicht; en:card:64417d856a019526b386041907eb4e69 |
| rubbish | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Bereits gelernter Wortbesitz. | rubbish / rubbish/NOUN / rubbish#mull; en:card:66759634f394611b4fef110b62694fad |
| forest | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Weitere Gelände-/Gewässerunterart oder Lagebeschreibung zurückgestellt; vorhandene Begriffe und präzise ausgewählte Landschaftsformen priorisiert. | forest / forest/NOUN / forest#wald; en:card:60529d4679518ef5cd2bc55c48c61be1 |
| grass | Zusätzlicher Bewuchs-/Flächenbegriff zurückgestellt: meadow, lawn, rainforest und wetland decken bewusst unterschiedliche Nutzung und Feuchte ab; keine Gleichsetzung aller Landschaften. | — |
| fish | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Weitere Tierart, Körperstruktur oder Verhaltensnuance zurückgestellt; häufige Tiergruppen und Lebensraumbegriffe priorisiert. | fish / fish/NOUN / fish#fisch; en:card:010bedf20cc6b515912ca4dcf80ee2d8 |
| daylight | Lichtfeld ist durch gelernte sunshine/sunlight und neue dawn/dusk abgedeckt; kein weiterer Licht-/Dunkelheitskopf. | — |
| mineral | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Zusätzliches Material, Untermerkmal oder Abbauwort zurückgestellt; gebräuchliche Materialien und grundlegende Prozesse priorisiert. | mineral / mineral/NOUN / mineral#mineralstoff; en:card:18a4110ca0de916a818c7fd7169b0716 |
| woodland | Zusätzlicher Bewuchs-/Flächenbegriff zurückgestellt: meadow, lawn, rainforest und wetland decken bewusst unterschiedliche Nutzung und Feuchte ab; keine Gleichsetzung aller Landschaften. | — |
| darkness | Lichtfeld ist durch gelernte sunshine/sunlight und neue dawn/dusk abgedeckt; kein weiterer Licht-/Dunkelheitskopf. | — |
| garbage | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Regionales Synonym des bereits gelernten rubbish. | rubbish / rubbish/NOUN / rubbish#mull |
| cloud | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Engere Wetterausprägung oder weniger priorisierte Bezeichnung; die ausgewählten Warnlagen und Grundbegriffe sind ausreichend, keine künstliche Mengenerfüllung. | cloud / cloud/NOUN / cloud#wolken; en:card:c5c575bcac10c06ea92069da2e7db9d4 |
| wood | Zusätzlicher Bewuchs-/Flächenbegriff zurückgestellt: meadow, lawn, rainforest und wetland decken bewusst unterschiedliche Nutzung und Feuchte ab; keine Gleichsetzung aller Landschaften. | — |
| reptile | Zusätzliche biologische Klassen zurückgestellt; mammal, bird und insect plus erkennbare frog/snake bieten eine begrenzte Auswahl ohne vollständige Taxonomie. | — |
| sunrise | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Engerer Vorgang oder Zustandsbegriff zurückgestellt; ausgewählte alltagstaugliche Naturereignisse priorisiert. | sunrise / sunrise/NOUN / sunrise#sonnenaufgang; en:card:0da1a0dd4529df5b8de70a580faf1541 |
| trash | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Regionales Synonym des bereits gelernten rubbish. | rubbish / rubbish/NOUN / rubbish#mull |
| warming | Weitere nominale Prozess-/Eigenschaftsableitung zurückgestellt; sustainable, conservation, survive und fragile werden mit präziser Zieldefinition verwendet. | — |
| cloudy | Bloße Wetterableitung oder enge Variante des entsprechenden Grundphänomens; kein weiteres Lernziel für diese Form. | — |
| jungle | Zusätzlicher Bewuchs-/Flächenbegriff zurückgestellt: meadow, lawn, rainforest und wetland decken bewusst unterschiedliche Nutzung und Feuchte ab; keine Gleichsetzung aller Landschaften. | — |
| flowering | Weitere Pflanzenableitung, Sammelbezeichnung oder Detailstruktur zurückgestellt; flower/leaf/seed/branch/cone bilden die gewählten Grundstrukturen, keine Gleichsetzung der Früchte. | — |
| amphibian | Zusätzliche biologische Klassen zurückgestellt; mammal, bird und insect plus erkennbare frog/snake bieten eine begrenzte Auswahl ohne vollständige Taxonomie. | — |
| sunset | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Engerer Vorgang oder Zustandsbegriff zurückgestellt; ausgewählte alltagstaugliche Naturereignisse priorisiert. | sunset / sunset/NOUN / sunset#sonnenuntergang; en:card:23e6116356359b9ba5642e6a9a736d0b |
| oil | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Zusätzliches Material, Untermerkmal oder Abbauwort zurückgestellt; gebräuchliche Materialien und grundlegende Prozesse priorisiert. | oil / oil/NOUN / oil#speiseol; en:card:400889c87c734033c3c5159fa770a6dd |
| sunny | Bloße Wetterableitung oder enge Variante des entsprechenden Grundphänomens; kein weiteres Lernziel für diese Form. | — |
| blossom | Weitere Pflanzenableitung, Sammelbezeichnung oder Detailstruktur zurückgestellt; flower/leaf/seed/branch/cone bilden die gewählten Grundstrukturen, keine Gleichsetzung der Früchte. | — |
| dump | Zusätzliche Abfallableitung, Infrastruktur oder Eigenschaft zurückgestellt; landfill, sewage/wastewater und ausdrücklich unterschiedliche reusable/recyclable/biodegradable priorisiert. | — |
| rain | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Engere Wetterausprägung oder weniger priorisierte Bezeichnung; die ausgewählten Warnlagen und Grundbegriffe sind ausreichend, keine künstliche Mengenerfüllung. | rain / rain/NOUN / rain#regen; en:card:50dadc5ae65bc0dc5ddbb31cc4003223 |
| desert | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Weitere Gelände-/Gewässerunterart oder Lagebeschreibung zurückgestellt; vorhandene Begriffe und präzise ausgewählte Landschaftsformen priorisiert. | desert / desert/NOUN / desert#wueste; en:card:bc5fcc292d4696aa54a1f4c883e48c58 |
| bloom | Weitere Pflanzenableitung, Sammelbezeichnung oder Detailstruktur zurückgestellt; flower/leaf/seed/branch/cone bilden die gewählten Grundstrukturen, keine Gleichsetzung der Früchte. | — |
| petroleum | Weiterer Brennstoff, Rohzustand oder Materialtyp zurückgestellt; coal/gas/timber sowie wenige gebräuchliche Gesteine und Metalle genügen, keine Mineralienliste. | — |
| bin | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Weitere Ableitung oder engerer Entsorgungs-/Reinigungsbegriff zurückgestellt; zentrale Begriffe priorisiert. | bin / bin/NOUN / bin#tonnen; en:card:cca2bb970605ef64d95d9eb9a2e1acee |
| protection | Weitere nominale Prozess-/Eigenschaftsableitung zurückgestellt; sustainable, conservation, survive und fragile werden mit präziser Zieldefinition verwendet. | — |
| rainy | Bloße Wetterableitung oder enge Variante des entsprechenden Grundphänomens; kein weiteres Lernziel für diese Form. | — |
| coast | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Weitere Gelände-/Gewässerunterart oder Lagebeschreibung zurückgestellt; vorhandene Begriffe und präzise ausgewählte Landschaftsformen priorisiert. | coast / coast/NOUN / coast#kueste; en:card:44855d59cf7d170c6766aebc7ee3f077 |
| pet | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Weitere Tierart, Körperstruktur oder Verhaltensnuance zurückgestellt; häufige Tiergruppen und Lebensraumbegriffe priorisiert. | pet / pet/NOUN / pet#haustiere; en:card:9f7552551fb50c0ec5aa89e62fe2aa55 |
| shadow | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Engerer Vorgang oder Zustandsbegriff zurückgestellt; ausgewählte alltagstaugliche Naturereignisse priorisiert. | shadow / shadow/NOUN / shadow#schatten; en:card:d3638318b4b2be724b1e41cc7cfe6044 |
| crude | Weiterer Brennstoff, Rohzustand oder Materialtyp zurückgestellt; coal/gas/timber sowie wenige gebräuchliche Gesteine und Metalle genügen, keine Mineralienliste. | — |
| dustbin | Zusätzliche Abfallableitung, Infrastruktur oder Eigenschaft zurückgestellt; landfill, sewage/wastewater und ausdrücklich unterschiedliche reusable/recyclable/biodegradable priorisiert. | — |
| sustainability | Weitere nominale Prozess-/Eigenschaftsableitung zurückgestellt; sustainable, conservation, survive und fragile werden mit präziser Zieldefinition verwendet. | — |
| rainfall | Bloße Wetterableitung oder enge Variante des entsprechenden Grundphänomens; kein weiteres Lernziel für diese Form. | — |
| coastline | Zu nahe am vorhandenen coast; Verlauf statt Küstenstreifen rechtfertigt hier kein zusätzliches Ziel. | — |
| shade | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Engerer Vorgang oder Zustandsbegriff zurückgestellt; ausgewählte alltagstaugliche Naturereignisse priorisiert. | shade / shade/NOUN / shade#schatten; en:card:0181a14fa51da617a7eeffe5224c710e |
| fuel | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Zusätzliches Material, Untermerkmal oder Abbauwort zurückgestellt; gebräuchliche Materialien und grundlegende Prozesse priorisiert. | fuel / fuel/NOUN / fuel#kraftstoff; en:card:7f491bfa84eb274e27d2859139bdce03 |
| recycling | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Nominalisierung von recycle; keine zusätzliche Formkarte. | recycling / recycling/NOUN / recycling#recycling; en:card:fbe330c5f3c83609a86cf06d1f1bd31d |
| drizzle | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Engere Wetterausprägung oder weniger priorisierte Bezeichnung; die ausgewählten Warnlagen und Grundbegriffe sind ausreichend, keine künstliche Mengenerfüllung. | drizzle / drizzle/NOUN / drizzle#nieselregen; en:card:7e35ba6b87df1862cc3fe47960aa03c3 |
| shore | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Weitere Gelände-/Gewässerunterart oder Lagebeschreibung zurückgestellt; vorhandene Begriffe und präzise ausgewählte Landschaftsformen priorisiert. | shore / shore/NOUN / shore#ufer; en:card:4232185f9583797e7dc46fdb98ab6845 |
| cattle | Zusätzliche Nutztier-, Behausungs-, Körper- oder Entwicklungsstruktur zurückgestellt; livestock, burrow/hive/nest und die ausgewählten Organe genügen für diesen Umfang. | — |
| shower | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Engere Wetterausprägung oder weniger priorisierte Bezeichnung; die ausgewählten Warnlagen und Grundbegriffe sind ausreichend, keine künstliche Mengenerfüllung. | shower / shower/NOUN / shower#dusche; en:card:75c0d5864076a3ca47d810be9bfaa71e |
| beach | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Weitere Gelände-/Gewässerunterart oder Lagebeschreibung zurückgestellt; vorhandene Begriffe und präzise ausgewählte Landschaftsformen priorisiert. | beach / beach/NOUN / beach#strand; en:card:aa42ba88fbbd740cc3471fd6811786ae |
| seedling | Weitere Pflanzenableitung, Sammelbezeichnung oder Detailstruktur zurückgestellt; flower/leaf/seed/branch/cone bilden die gewählten Grundstrukturen, keine Gleichsetzung der Früchte. | — |
| seasonal | Jahreszeiten und konkrete Naturvorgänge haben Vorrang vor allgemeinen Kalenderadjektiven. | — |
| downpour | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Engere Wetterausprägung oder weniger priorisierte Bezeichnung; die ausgewählten Warnlagen und Grundbegriffe sind ausreichend, keine künstliche Mengenerfüllung. | downpour / downpour/NOUN / downpour#platzregen; en:card:67cbeb59ff0929ab648686332f0613f3 |
| sand | Weitere Material-/Größenvariante zurückgestellt; Felsmasse rock, gerundeter Einzelstein pebble und loses gravel sind ausdrücklich getrennt ausgewählt. | — |
| annual | Jahreszeiten und konkrete Naturvorgänge haben Vorrang vor allgemeinen Kalenderadjektiven. | — |
| log | Weiterer Brennstoff, Rohzustand oder Materialtyp zurückgestellt; coal/gas/timber sowie wenige gebräuchliche Gesteine und Metalle genügen, keine Mineralienliste. | — |
| drain | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Weitere Ableitung oder engerer Entsorgungs-/Reinigungsbegriff zurückgestellt; zentrale Begriffe priorisiert. | drain / drain/VERB / drain#abgieen; en:card:d98c7d9e1cf9c51a558953a499b5dfdd |
| windpower | Weitere Energiequelle, technische Benennung oder Zusammensetzung zurückgestellt; solar/hydropower, turbine/insulation und wenige zentrale Stoffe werden präzise reserviert. | — |
| storm | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Engere Wetterausprägung oder weniger priorisierte Bezeichnung; die ausgewählten Warnlagen und Grundbegriffe sind ausreichend, keine künstliche Mengenerfüllung. | storm / storm/NOUN / storm#sturms; en:card:5c4db79db2c9c8841e86dcd377b87d97 |
| sandy | Weitere Material-/Größenvariante zurückgestellt; Felsmasse rock, gerundeter Einzelstein pebble und loses gravel sind ausdrücklich getrennt ausgewählt. | — |
| pack | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Weitere Tierart, Körperstruktur oder Verhaltensnuance zurückgestellt; häufige Tiergruppen und Lebensraumbegriffe priorisiert. | pack / pack/VERB / pack#packen; en:card:ddc1ba086d7b5e5f91533affc31dbfff |
| cycle | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Engerer Vorgang oder Zustandsbegriff zurückgestellt; ausgewählte alltagstaugliche Naturereignisse priorisiert. | cycle / cycle/VERB / cycle#rad-fahren; en:card:ffb7f70de957f27fc3578fc1f7a224f3 |
| drainage | Zusätzliche Abfallableitung, Infrastruktur oder Eigenschaft zurückgestellt; landfill, sewage/wastewater und ausdrücklich unterschiedliche reusable/recyclable/biodegradable priorisiert. | — |
| thunder | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Engere Wetterausprägung oder weniger priorisierte Bezeichnung; die ausgewählten Warnlagen und Grundbegriffe sind ausreichend, keine künstliche Mengenerfüllung. | thunder / thunder/NOUN / thunder#donner; en:card:d14d47eb6dc316c65a7a2c554cfe66f8 |
| sewer | Zusätzliche Abfallableitung, Infrastruktur oder Eigenschaft zurückgestellt; landfill, sewage/wastewater und ausdrücklich unterschiedliche reusable/recyclable/biodegradable priorisiert. | — |
| lightning | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Engere Wetterausprägung oder weniger priorisierte Bezeichnung; die ausgewählten Warnlagen und Grundbegriffe sind ausreichend, keine künstliche Mengenerfüllung. | lightning / lightning/NOUN / lightning#blitz; en:card:11de96fc7cea6de5fcf0d9cda72f34e4 |
| island | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Weitere Gelände-/Gewässerunterart oder Lagebeschreibung zurückgestellt; vorhandene Begriffe und präzise ausgewählte Landschaftsformen priorisiert. | island / island/NOUN / island#insel; en:card:7fe7a8c8e4fe3261fea3ba17d9d38414 |
| panel | Weitere Energiequelle, technische Benennung oder Zusammensetzung zurückgestellt; solar/hydropower, turbine/insulation und wenige zentrale Stoffe werden präzise reserviert. | — |
| twig | Weitere Pflanzenableitung, Sammelbezeichnung oder Detailstruktur zurückgestellt; flower/leaf/seed/branch/cone bilden die gewählten Grundstrukturen, keine Gleichsetzung der Früchte. | — |
| battery | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Zusätzlicher Fach-, Verwaltungs- oder zusammengesetzter Energiebegriff zurückgestellt; zentrale alltagstaugliche Begriffe priorisiert. | battery / battery/NOUN / battery#batterien; en:card:9a9f01310197a002ae2d9e07e116f854 |
| den | Zusätzliche Nutztier-, Behausungs-, Körper- oder Entwicklungsstruktur zurückgestellt; livestock, burrow/hive/nest und die ausgewählten Organe genügen für diesen Umfang. | — |
| evaporation | Weitere Naturprozess-/Zustandsableitung zurückgestellt; ausgewählte Schadereignisse, Wasserbewegungen und Entwicklungsprozesse bilden den begrenzten Kern. Keine behauptete Synonymie aller Vorgänge. | — |
| wrapper | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Weitere Ableitung oder engerer Entsorgungs-/Reinigungsbegriff zurückgestellt; zentrale Begriffe priorisiert. | wrapper / wrapper/NOUN / wrapper#verpackungshulle; en:card:903f573d654c76db71492b19ae41d4ff |
| charger | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Zusätzlicher Fach-, Verwaltungs- oder zusammengesetzter Energiebegriff zurückgestellt; zentrale alltagstaugliche Begriffe priorisiert. | charger / charger/NOUN / charger#ladegeraet; en:card:677bca9b518b68110c78079c49550995 |
| snow | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Engere Wetterausprägung oder weniger priorisierte Bezeichnung; die ausgewählten Warnlagen und Grundbegriffe sind ausreichend, keine künstliche Mengenerfüllung. | snow / snow/NOUN / snow#schnee; en:card:ca76ddd29cd02fd9e30798d1200d97c9 |
| ocean | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Weitere Gelände-/Gewässerunterart oder Lagebeschreibung zurückgestellt; vorhandene Begriffe und präzise ausgewählte Landschaftsformen priorisiert. | ocean / ocean/NOUN / ocean#ozean; en:card:03f760068119f39a13df067be122efc8 |
| foliage | Weitere Pflanzenableitung, Sammelbezeichnung oder Detailstruktur zurückgestellt; flower/leaf/seed/branch/cone bilden die gewählten Grundstrukturen, keine Gleichsetzung der Früchte. | — |
| condensation | Weitere Naturprozess-/Zustandsableitung zurückgestellt; ausgewählte Schadereignisse, Wasserbewegungen und Entwicklungsprozesse bilden den begrenzten Kern. Keine behauptete Synonymie aller Vorgänge. | — |
| snowy | Bloße Wetterableitung oder enge Variante des entsprechenden Grundphänomens; kein weiteres Lernziel für diese Form. | — |
| sea | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Weitere Gelände-/Gewässerunterart oder Lagebeschreibung zurückgestellt; vorhandene Begriffe und präzise ausgewählte Landschaftsformen priorisiert. | sea / sea/NOUN / sea#meer; en:card:daeba224058e420a102e61928e4e5137 |
| can | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Weitere Ableitung oder engerer Entsorgungs-/Reinigungsbegriff zurückgestellt; zentrale Begriffe priorisiert. | can / can/NOUN / can#dose; en:card:75085ef9b5858d30d79570f2d061de62 |
| insulate | Weitere Energiequelle, technische Benennung oder Zusammensetzung zurückgestellt; solar/hydropower, turbine/insulation und wenige zentrale Stoffe werden präzise reserviert. | — |
| snowfall | Bloße Wetterableitung oder enge Variante des entsprechenden Grundphänomens; kein weiteres Lernziel für diese Form. | — |
| seaside | Weitere Ufer-/Lage-/Gewässer- oder Geländeausprägung zurückgestellt; Bestand und ausgewählte Landformen reichen aus. Riverbank ist besonders nah am bereits gelernten shore. | — |
| slate | Weiterer Brennstoff, Rohzustand oder Materialtyp zurückgestellt; coal/gas/timber sowie wenige gebräuchliche Gesteine und Metalle genügen, keine Mineralienliste. | — |
| bottle | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Weitere Ableitung oder engerer Entsorgungs-/Reinigungsbegriff zurückgestellt; zentrale Begriffe priorisiert. | bottle / bottle/NOUN / bottle#flasche; en:card:1e00e17d5e790190ed95f01b5d2cb0f3 |
| efficient | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Bereits gelernte Karte efficient; efficiency ist das Verhältnis als Nomen, kein zweites Adjektiv. | efficient / efficient/ADJ / efficient#effizient; en:card:772b6c242a035e1bf39bc6df6bfbe44a |
| river | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Weitere Gelände-/Gewässerunterart oder Lagebeschreibung zurückgestellt; vorhandene Begriffe und präzise ausgewählte Landschaftsformen priorisiert. | river / river/NOUN / river#fluss; en:card:670450c45534dfe3d156c4d1a4ace804 |
| acorn | Weitere Pflanzenableitung, Sammelbezeichnung oder Detailstruktur zurückgestellt; flower/leaf/seed/branch/cone bilden die gewählten Grundstrukturen, keine Gleichsetzung der Früchte. | — |
| chalk | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Zusätzliches Material, Untermerkmal oder Abbauwort zurückgestellt; gebräuchliche Materialien und grundlegende Prozesse priorisiert. | chalk / chalk/NOUN / chalk#kreide; en:card:a2e2dc31e8b8e0fa157e0c2099a1c468 |
| container | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Weitere Ableitung oder engerer Entsorgungs-/Reinigungsbegriff zurückgestellt; zentrale Begriffe priorisiert. | container / container/NOUN / container#behaelter; en:card:5592e2488d6c4667f16f471e7fe76b13 |
| nut | Weitere Pflanzenableitung, Sammelbezeichnung oder Detailstruktur zurückgestellt; flower/leaf/seed/branch/cone bilden die gewählten Grundstrukturen, keine Gleichsetzung der Früchte. | — |
| wool | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Zusätzliches Material, Untermerkmal oder Abbauwort zurückgestellt; gebräuchliche Materialien und grundlegende Prozesse priorisiert. | wool / wool/NOUN / wool#wolle; en:card:7c461975bb7a3384d48e8be9444b0c28 |
| germination | Zusätzlicher Pflanzenentwicklungsprozess oder dessen Ableitung zurückgestellt; growth, decay, pollinate und dormant bilden die ausgewählten Entwicklungsabsichten. | — |
| quartz | Weiterer Brennstoff, Rohzustand oder Materialtyp zurückgestellt; coal/gas/timber sowie wenige gebräuchliche Gesteine und Metalle genügen, keine Mineralienliste. | — |
| bag | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Weitere Ableitung oder engerer Entsorgungs-/Reinigungsbegriff zurückgestellt; zentrale Begriffe priorisiert. | bag / bag/NOUN / bag#tasche; en:card:a437af62734f8b043f46262218b688e3 |
| frost | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Engere Wetterausprägung oder weniger priorisierte Bezeichnung; die ausgewählten Warnlagen und Grundbegriffe sind ausreichend, keine künstliche Mengenerfüllung. | frost / frost/NOUN / frost#frost; en:card:d278233ab74c14892d005e1904a656a2 |
| creek | Regionale Benennung eines kleinen Wasserlaufs; stream ist Ziel. | — |
| berry | Weitere Pflanzenableitung, Sammelbezeichnung oder Detailstruktur zurückgestellt; flower/leaf/seed/branch/cone bilden die gewählten Grundstrukturen, keine Gleichsetzung der Früchte. | — |
| scale | Zusätzliche Nutztier-, Behausungs-, Körper- oder Entwicklungsstruktur zurückgestellt; livestock, burrow/hive/nest und die ausgewählten Organe genügen für diesen Umfang. | — |
| moisture | Weitere Naturprozess-/Zustandsableitung zurückgestellt; ausgewählte Schadereignisse, Wasserbewegungen und Entwicklungsprozesse bilden den begrenzten Kern. Keine behauptete Synonymie aller Vorgänge. | — |
| crystal | Weiterer Brennstoff, Rohzustand oder Materialtyp zurückgestellt; coal/gas/timber sowie wenige gebräuchliche Gesteine und Metalle genügen, keine Mineralienliste. | — |
| consume | Energieherstellung und Nutzung über electricity, generate und consumption präzisiert; power bleibt wegen breiter Mehrdeutigkeit zurückgestellt. | — |
| frosty | Bloße Wetterableitung oder enge Variante des entsprechenden Grundphänomens; kein weiteres Lernziel für diese Form. | — |
| brook | Nahezu gleichbedeutend mit stream; nur ein Ziel. | — |
| fruit | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Zusätzliche Pflanzenart, Teilstruktur oder Gartenhandlung zurückgestellt; keine Artenliste zur Mengenerfüllung. | fruit / fruit/NOUN / fruit#obst; en:card:7aa22de513997b5a0c6b5f53db2d5871 |
| salt | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Zusätzliches Material, Untermerkmal oder Abbauwort zurückgestellt; gebräuchliche Materialien und grundlegende Prozesse priorisiert. | salt / salt/NOUN / salt#salz; en:card:7857ea606fffd3d009f84fa45ecb7d12 |
| ice | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Engere Wetterausprägung oder weniger priorisierte Bezeichnung; die ausgewählten Warnlagen und Grundbegriffe sind ausreichend, keine künstliche Mengenerfüllung. | ice / ice/NOUN / ice#eis; en:card:fe54cd2d3af5f0335a24b9bd236bb25f |
| lake | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Weitere Gelände-/Gewässerunterart oder Lagebeschreibung zurückgestellt; vorhandene Begriffe und präzise ausgewählte Landschaftsformen priorisiert. | lake / lake/NOUN / lake#see; en:card:1760c8d46c133446689bb40017cbd72b |
| mushroom | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Zusätzliche Pflanzenart, Teilstruktur oder Gartenhandlung zurückgestellt; keine Artenliste zur Mengenerfüllung. | mushroom / mushroom/NOUN / mushroom#pilz; en:card:6a6acc62df9d0e5f9c9e0a8fb53f0e8d |
| refillable | Zusätzliche Abfallableitung, Infrastruktur oder Eigenschaft zurückgestellt; landfill, sewage/wastewater und ausdrücklich unterschiedliche reusable/recyclable/biodegradable priorisiert. | — |
| generation | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Enge Ableitung oder Variante zu generate; keine zusätzliche Einführung dieser Form. | generation / generation/NOUN / generation#generation; en:card:dbf4308d7a2add4c33c73014f1bc6c73 |
| icy | Bloße Wetterableitung oder enge Variante des entsprechenden Grundphänomens; kein weiteres Lernziel für diese Form. | — |
| fungus | Weitere Pflanzenart zurückgestellt; mit moss, fern, nettle, oak und pine bleibt die Artenliste klein und alltagsnah. | — |
| iron | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Zusätzliches Material, Untermerkmal oder Abbauwort zurückgestellt; gebräuchliche Materialien und grundlegende Prozesse priorisiert. | iron / iron/NOUN / iron#bugeleisen; en:card:1151e33b19d03eb9d59ca0ad6cfd4d20 |
| washable | Zusätzliche Abfallableitung, Infrastruktur oder Eigenschaft zurückgestellt; landfill, sewage/wastewater und ausdrücklich unterschiedliche reusable/recyclable/biodegradable priorisiert. | — |
| source | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Zusätzlicher Fach-, Verwaltungs- oder zusammengesetzter Energiebegriff zurückgestellt; zentrale alltagstaugliche Begriffe priorisiert. | source / source/NOUN / source#informationsquelle; en:card:b0ee282842f3c661f96c916c37294539 |
| waterfall | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Weitere Gelände-/Gewässerunterart oder Lagebeschreibung zurückgestellt; vorhandene Begriffe und präzise ausgewählte Landschaftsformen priorisiert. | waterfall / waterfall/NOUN / waterfall#wasserfall; en:card:6488b90f070be81a62d3f393169e1072 |
| freezing | Bloße Wetterableitung oder enge Variante des entsprechenden Grundphänomens; kein weiteres Lernziel für diese Form. | — |
| valley | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Weitere Gelände-/Gewässerunterart oder Lagebeschreibung zurückgestellt; vorhandene Begriffe und präzise ausgewählte Landschaftsformen priorisiert. | valley / valley/NOUN / valley#tal; en:card:60504eaab398d9fcc42c0ebbe4988d4d |
| thaw | Auftauen ist bereits über defrost im Essen-Stapel eingeführt; kein konkurrierender neuer Kopf. | — |
| ivy | Weitere Pflanzenart zurückgestellt; mit moss, fern, nettle, oak und pine bleibt die Artenliste klein und alltagsnah. | — |
| tremor | Weitere Naturprozess-/Zustandsableitung zurückgestellt; ausgewählte Schadereignisse, Wasserbewegungen und Entwicklungsprozesse bilden den begrenzten Kern. Keine behauptete Synonymie aller Vorgänge. | — |
| zinc | Weiterer Brennstoff, Rohzustand oder Materialtyp zurückgestellt; coal/gas/timber sowie wenige gebräuchliche Gesteine und Metalle genügen, keine Mineralienliste. | — |
| compostable | Zusätzliche Abfallableitung, Infrastruktur oder Eigenschaft zurückgestellt; landfill, sewage/wastewater und ausdrücklich unterschiedliche reusable/recyclable/biodegradable priorisiert. | — |
| melt | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Engere Wetterausprägung oder weniger priorisierte Bezeichnung; die ausgewählten Warnlagen und Grundbegriffe sind ausreichend, keine künstliche Mengenerfüllung. | melt / melt/VERB / melt#schmelzen; en:card:feb5bd89a923a6e817e7858e2bcfb13d |
| mountain | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Weitere Gelände-/Gewässerunterart oder Lagebeschreibung zurückgestellt; vorhandene Begriffe und präzise ausgewählte Landschaftsformen priorisiert. | mountain / mountain/NOUN / mountain#berg; en:card:585f80cbf42068a38d99a4bf0b10f9a3 |
| reed | Weitere Pflanzenart zurückgestellt; mit moss, fern, nettle, oak und pine bleibt die Artenliste klein und alltagsnah. | — |
| tin | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Zusätzliches Material, Untermerkmal oder Abbauwort zurückgestellt; gebräuchliche Materialien und grundlegende Prozesse priorisiert. | tin / tin/NOUN / tin#konservendose; en:card:b2293f04aff855d2de1a48591e68692d |
| fog | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Engere Wetterausprägung oder weniger priorisierte Bezeichnung; die ausgewählten Warnlagen und Grundbegriffe sind ausreichend, keine künstliche Mengenerfüllung. | fog / fog/NOUN / fog#nebel; en:card:ebd8607fed9c8b76799caf8a0f3baf78 |
| mountainous | Weitere Ufer-/Lage-/Gewässer- oder Geländeausprägung zurückgestellt; Bestand und ausgewählte Landformen reichen aus. Riverbank ist besonders nah am bereits gelernten shore. | — |
| horn | Zusätzliche Nutztier-, Behausungs-, Körper- oder Entwicklungsstruktur zurückgestellt; livestock, burrow/hive/nest und die ausgewählten Organe genügen für diesen Umfang. | — |
| lead | Weiterer Brennstoff, Rohzustand oder Materialtyp zurückgestellt; coal/gas/timber sowie wenige gebräuchliche Gesteine und Metalle genügen, keine Mineralienliste. | — |
| toxic | Giftig überschneidet sich mit poisonous; ein gemeinsamer Lernkopf statt konkurrierender Adjektive. | — |
| foggy | Bloße Wetterableitung oder enge Variante des entsprechenden Grundphänomens; kein weiteres Lernziel für diese Form. | — |
| cliff | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Weitere Gelände-/Gewässerunterart oder Lagebeschreibung zurückgestellt; vorhandene Begriffe und präzise ausgewählte Landschaftsformen priorisiert. | cliff / cliff/NOUN / cliff#klippe; en:card:de6380da0d6100378c5e7b49829a1257 |
| antler | Zusätzliche Nutztier-, Behausungs-, Körper- oder Entwicklungsstruktur zurückgestellt; livestock, burrow/hive/nest und die ausgewählten Organe genügen für diesen Umfang. | — |
| ash | Weitere Pflanzenart zurückgestellt; mit moss, fern, nettle, oak und pine bleibt die Artenliste klein und alltagsnah. | — |
| dirty | Zusätzliche Abfallableitung, Infrastruktur oder Eigenschaft zurückgestellt; landfill, sewage/wastewater und ausdrücklich unterschiedliche reusable/recyclable/biodegradable priorisiert. | — |
| nitrogen | Weitere Energiequelle, technische Benennung oder Zusammensetzung zurückgestellt; solar/hydropower, turbine/insulation und wenige zentrale Stoffe werden präzise reserviert. | — |
| mist | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Engere Wetterausprägung oder weniger priorisierte Bezeichnung; die ausgewählten Warnlagen und Grundbegriffe sind ausreichend, keine künstliche Mengenerfüllung. | mist / mist/NOUN / mist#dunst; en:card:2a4fda0329a1e5110bf9bb652af45f2f |
| cave | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Weitere Gelände-/Gewässerunterart oder Lagebeschreibung zurückgestellt; vorhandene Begriffe und präzise ausgewählte Landschaftsformen priorisiert. | cave / cave/NOUN / cave#hoehle; en:card:4cd7aa7f5f27d0a404e582fcc8044522 |
| shell | Zusätzliche Nutztier-, Behausungs-, Körper- oder Entwicklungsstruktur zurückgestellt; livestock, burrow/hive/nest und die ausgewählten Organe genügen für diesen Umfang. | — |
| smoke | Weitere Naturprozess-/Zustandsableitung zurückgestellt; ausgewählte Schadereignisse, Wasserbewegungen und Entwicklungsprozesse bilden den begrenzten Kern. Keine behauptete Synonymie aller Vorgänge. | — |
| clean | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Weitere Ableitung oder engerer Entsorgungs-/Reinigungsbegriff zurückgestellt; zentrale Begriffe priorisiert. | clean / clean/VERB / clean#putzen; en:card:e4d7721061e4264e2dde33947b5b9d01 |
| hydrogen | Weitere Energiequelle, technische Benennung oder Zusammensetzung zurückgestellt; solar/hydropower, turbine/insulation und wenige zentrale Stoffe werden präzise reserviert. | — |
| misty | Bloße Wetterableitung oder enge Variante des entsprechenden Grundphänomens; kein weiteres Lernziel für diese Form. | — |
| thistle | Weitere Pflanzenart zurückgestellt; mit moss, fern, nettle, oak und pine bleibt die Artenliste klein und alltagsnah. | — |
| fire | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Engerer Vorgang oder Zustandsbegriff zurückgestellt; ausgewählte alltagstaugliche Naturereignisse priorisiert. | fire / fire/NOUN / fire#brand; en:card:38af5fd0f2d227245900c66b5d8558f6 |
| rubber | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Zusätzliches Material, Untermerkmal oder Abbauwort zurückgestellt; gebräuchliche Materialien und grundlegende Prozesse priorisiert. | eraser / eraser/NOUN / eraser#radiergummi |
| filthy | Zusätzliche Abfallableitung, Infrastruktur oder Eigenschaft zurückgestellt; landfill, sewage/wastewater und ausdrücklich unterschiedliche reusable/recyclable/biodegradable priorisiert. | — |
| carbon-dioxide | Schreib-/Mehrwortvariante nicht als zusätzliches Ziel reservieren; keine künstlich verbundenen Bindestrichformen für gewöhnliche Mehrwortausdrücke. | — |
| breeze | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Engere Wetterausprägung oder weniger priorisierte Bezeichnung; die ausgewählten Warnlagen und Grundbegriffe sind ausreichend, keine künstliche Mengenerfüllung. | breeze / breeze/NOUN / breeze#brise; en:card:e032d721c91a4497650dc8da81c2479e |
| rocky | Weitere Material-/Größenvariante zurückgestellt; Felsmasse rock, gerundeter Einzelstein pebble und loses gravel sind ausdrücklich getrennt ausgewählt. | — |
| egg | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Weitere Tierart, Körperstruktur oder Verhaltensnuance zurückgestellt; häufige Tiergruppen und Lebensraumbegriffe priorisiert. | egg / egg/NOUN / egg#ei; en:card:a8ba408d5d962a13b6017b444a0bba41 |
| contamination | Weitere Nominalisierung/Verbvariante zu contaminate, pollution, litter, leak oder Reinigung; keine zusätzliche Prozessfamilie. | — |
| wind | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Engere Wetterausprägung oder weniger priorisierte Bezeichnung; die ausgewählten Warnlagen und Grundbegriffe sind ausreichend, keine künstliche Mengenerfüllung. | wind / wind/NOUN / wind#wind; en:card:280ee6ea40e6d24eb3616bf62f3023f2 |
| stone | Weitere Material-/Größenvariante zurückgestellt; Felsmasse rock, gerundeter Einzelstein pebble und loses gravel sind ausdrücklich getrennt ausgewählt. | — |
| larva | Zusätzliche Nutztier-, Behausungs-, Körper- oder Entwicklungsstruktur zurückgestellt; livestock, burrow/hive/nest und die ausgewählten Organe genügen für diesen Umfang. | — |
| glass | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Zusätzliches Material, Untermerkmal oder Abbauwort zurückgestellt; gebräuchliche Materialien und grundlegende Prozesse priorisiert. | glass / glass/NOUN / glass#glas; en:card:3b4b4f5207c8422691a2821a1fb5381d |
| windy | Bloße Wetterableitung oder enge Variante des entsprechenden Grundphänomens; kein weiteres Lernziel für diese Form. | — |
| birch | Weitere Pflanzenart zurückgestellt; mit moss, fern, nettle, oak und pine bleibt die Artenliste klein und alltagsnah. | — |
| paper | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Zusätzliches Material, Untermerkmal oder Abbauwort zurückgestellt; gebräuchliche Materialien und grundlegende Prozesse priorisiert. | paper / paper/NOUN / paper#papier; en:card:387125b38847ee46a3f5359fb9300b15 |
| pollute | Weitere Nominalisierung/Verbvariante zu contaminate, pollution, litter, leak oder Reinigung; keine zusätzliche Prozessfamilie. | — |
| boulder | Weitere Material-/Größenvariante zurückgestellt; Felsmasse rock, gerundeter Einzelstein pebble und loses gravel sind ausdrücklich getrennt ausgewählt. | — |
| beech | Weitere Pflanzenart zurückgestellt; mit moss, fern, nettle, oak und pine bleibt die Artenliste klein und alltagsnah. | — |
| cocoon | Zusätzliche Nutztier-, Behausungs-, Körper- oder Entwicklungsstruktur zurückgestellt; livestock, burrow/hive/nest und die ausgewählten Organe genügen für diesen Umfang. | — |
| burn | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Engerer Vorgang oder Zustandsbegriff zurückgestellt; ausgewählte alltagstaugliche Naturereignisse priorisiert. | burn / burn/NOUN / burn#brandwunde; en:card:47e7c84907ddd0c61200fcce3094058e |
| willow | Weitere Pflanzenart zurückgestellt; mit moss, fern, nettle, oak und pine bleibt die Artenliste klein und alltagsnah. | — |
| spread | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Engerer Vorgang oder Zustandsbegriff zurückgestellt; ausgewählte alltagstaugliche Naturereignisse priorisiert. | spread / spread/VERB / spread#breitet-aus; en:card:504098b6481f91be4c2aaecd10b5c248 |
| cotton | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Zusätzliches Material, Untermerkmal oder Abbauwort zurückgestellt; gebräuchliche Materialien und grundlegende Prozesse priorisiert. | cotton / cotton/NOUN / cotton#baumwolle; en:card:d9e7434bf92e9308cee7d27f7deb5d11 |
| balance | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Zusätzlicher Fach-, Verwaltungs- oder zusammengesetzter Energiebegriff zurückgestellt; zentrale alltagstaugliche Begriffe priorisiert. | balance / balance/NOUN / balance#ausgewogenheit; en:card:c5dc1ed0400fea5bb684a54ae54ccdff |
| maple | Weitere Pflanzenart zurückgestellt; mit moss, fern, nettle, oak und pine bleibt die Artenliste klein und alltagsnah. | — |
| moth | Weitere Tierart zurückgestellt; keine Aufzählung aller vertrauten Arten zur Mengenerfüllung. Ausgewählte häufige Tierformen, Körperteile und Lebensräume haben Vorrang. | — |
| heat | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Engere Wetterausprägung oder weniger priorisierte Bezeichnung; die ausgewählten Warnlagen und Grundbegriffe sind ausreichend, keine künstliche Mengenerfüllung. | heat / heat/NOUN / heat#hitze; en:card:3d344f6051a183b40d701bbd40773a0d |
| steep | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Weitere Gelände-/Gewässerunterart oder Lagebeschreibung zurückgestellt; vorhandene Begriffe und präzise ausgewählte Landschaftsformen priorisiert. | steep / steep/ADJ / steep#steile; en:card:6a0f5571a18fcd2d51cb5c9e88090f6d |
| warmth | Zusätzliche Temperatur-/Feuchteabstufung zurückgestellt; vorhandene Wärme-/Kältebegriffe und präzises humid genügen, muggy wäre besonders nah an humid. | — |
| flat | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Weitere Gelände-/Gewässerunterart oder Lagebeschreibung zurückgestellt; vorhandene Begriffe und präzise ausgewählte Landschaftsformen priorisiert. | apartment / apartment/NOUN / apartment#wohnung |
| elm | Weitere Pflanzenart zurückgestellt; mit moss, fern, nettle, oak und pine bleibt die Artenliste klein und alltagsnah. | — |
| wasp | Weitere Tierart zurückgestellt; keine Aufzählung aller vertrauten Arten zur Mengenerfüllung. Ausgewählte häufige Tierformen, Körperteile und Lebensräume haben Vorrang. | — |
| reserve | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Zusätzlicher Fach-, Verwaltungs- oder zusammengesetzter Energiebegriff zurückgestellt; zentrale alltagstaugliche Begriffe priorisiert. | reserve / reserve/VERB / reserve#reservieren; en:learning:book:v1 |
| cold | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Engere Wetterausprägung oder weniger priorisierte Bezeichnung; die ausgewählten Warnlagen und Grundbegriffe sind ausreichend, keine künstliche Mengenerfüllung. | cold / cold/NOUN / cold#kaelte; en:card:a0fb6d0245d71e482de44efcfd04cb55 |
| field | Zusätzlicher Bewuchs-/Flächenbegriff zurückgestellt: meadow, lawn, rainforest und wetland decken bewusst unterschiedliche Nutzung und Feuchte ab; keine Gleichsetzung aller Landschaften. | — |
| chestnut | Weitere Pflanzenart zurückgestellt; mit moss, fern, nettle, oak und pine bleibt die Artenliste klein und alltagsnah. | — |
| hornet | Weitere Tierart zurückgestellt; keine Aufzählung aller vertrauten Arten zur Mengenerfüllung. Ausgewählte häufige Tierformen, Körperteile und Lebensräume haben Vorrang. | — |
| pour | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Engerer Vorgang oder Zustandsbegriff zurückgestellt; ausgewählte alltagstaugliche Naturereignisse priorisiert. | pour / pour/VERB / pour#giesst; en:card:a003da539c7245db42aac9a6cc8ad97b |
| fibre | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Zusätzliches Material, Untermerkmal oder Abbauwort zurückgestellt; gebräuchliche Materialien und grundlegende Prozesse priorisiert. | fibre / fibre/NOUN / fibre#ballaststoffe; en:card:fcc255347b52d8fdd3b5171fa4d456af |
| collect | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Weitere Ableitung oder engerer Entsorgungs-/Reinigungsbegriff zurückgestellt; zentrale Begriffe priorisiert. | collect / collect/VERB / collect#abholen; en:card:c50a0c1b905f905bd2ad1c27c137117f |
| cool | Zusätzliche Temperatur-/Feuchteabstufung zurückgestellt; vorhandene Wärme-/Kältebegriffe und präzises humid genügen, muggy wäre besonders nah an humid. | — |
| bamboo | Weitere Pflanzenart zurückgestellt; mit moss, fern, nettle, oak und pine bleibt die Artenliste klein und alltagsnah. | — |
| ant | Weitere Tierart zurückgestellt; keine Aufzählung aller vertrauten Arten zur Mengenerfüllung. Ausgewählte häufige Tierformen, Körperteile und Lebensräume haben Vorrang. | — |
| soak | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Engerer Vorgang oder Zustandsbegriff zurückgestellt; ausgewählte alltagstaugliche Naturereignisse priorisiert. | soak / soak/VERB / soak#einweichen; en:card:d5b98504d4885eecfeddb9cbb46e44de |
| fabric | Zu breit für eine zusätzliche konkrete Materialabsicht; metal, plastic, cardboard und leather werden einzeln bestimmt. | — |
| reduce | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Zusätzlicher Fach-, Verwaltungs- oder zusammengesetzter Energiebegriff zurückgestellt; zentrale alltagstaugliche Begriffe priorisiert. | reduce / reduce/VERB / reduce#verringern; en:card:726db8bc5a754e83ffab9d523ce15534 |
| preserve | Erhalten/Schützen neben gelerntem protect und neuem conservation nicht zusätzlich. | — |
| mild | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Engere Wetterausprägung oder weniger priorisierte Bezeichnung; die ausgewählten Warnlagen und Grundbegriffe sind ausreichend, keine künstliche Mengenerfüllung. | mild / mild/ADJ / mild#leichte; en:card:12722b6f42c416703c71b71e684b6999 |
| grassland | Zusätzlicher Bewuchs-/Flächenbegriff zurückgestellt: meadow, lawn, rainforest und wetland decken bewusst unterschiedliche Nutzung und Feuchte ab; keine Gleichsetzung aller Landschaften. | — |
| palm | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Zusätzliche Pflanzenart, Teilstruktur oder Gartenhandlung zurückgestellt; keine Artenliste zur Mengenerfüllung. | palm / palm/NOUN / palm#handflache; en:card:b8535295e95c15a965a4dd60e81db5da |
| sink | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Engerer Vorgang oder Zustandsbegriff zurückgestellt; ausgewählte alltagstaugliche Naturereignisse priorisiert. | sink / sink/NOUN / sink#spuelbecken; en:card:e87d164a35ccc528ae9723c22bbce8c7 |
| reuse | Wiederverwendung bereits über reusable vertreten; kein zusätzlicher Handlungskopf. | — |
| conservationist | Abgeleitete Person neben conservation; ranger als konkrete Tätigkeit gewählt. | — |
| chilly | Zusätzliche Temperatur-/Feuchteabstufung zurückgestellt; vorhandene Wärme-/Kältebegriffe und präzises humid genügen, muggy wäre besonders nah an humid. | — |
| plain | Zusätzlicher Bewuchs-/Flächenbegriff zurückgestellt: meadow, lawn, rainforest und wetland decken bewusst unterschiedliche Nutzung und Feuchte ab; keine Gleichsetzung aller Landschaften. | — |
| daisy | Weitere Pflanzenart zurückgestellt; mit moss, fern, nettle, oak und pine bleibt die Artenliste klein und alltagsnah. | — |
| ladybird | Weitere Tierart zurückgestellt; keine Aufzählung aller vertrauten Arten zur Mengenerfüllung. Ausgewählte häufige Tierformen, Körperteile und Lebensräume haben Vorrang. | — |
| peat | Weiterer Brennstoff, Rohzustand oder Materialtyp zurückgestellt; coal/gas/timber sowie wenige gebräuchliche Gesteine und Metalle genügen, keine Mineralienliste. | — |
| prairie | Zusätzlicher Bewuchs-/Flächenbegriff zurückgestellt: meadow, lawn, rainforest und wetland decken bewusst unterschiedliche Nutzung und Feuchte ab; keine Gleichsetzung aller Landschaften. | — |
| rose | Weitere Pflanzenart zurückgestellt; mit moss, fern, nettle, oak und pine bleibt die Artenliste klein und alltagsnah. | — |
| repair | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Weitere Ableitung oder engerer Entsorgungs-/Reinigungsbegriff zurückgestellt; zentrale Begriffe priorisiert. | repair / repair/VERB / repair#repariert; en:card:1bb2600098a1ffb045fa8d3940fbb333 |
| poacher | Enge Ableitung oder Variante zu poaching; keine zusätzliche Einführung dieser Form. | — |
| humidity | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Engere Wetterausprägung oder weniger priorisierte Bezeichnung; die ausgewählten Warnlagen und Grundbegriffe sind ausreichend, keine künstliche Mengenerfüllung. | humidity / humidity/NOUN / humidity#luftfeuchtigkeit; en:card:bf51a5fd7e7320c67307d93fa5296c9a |
| marsh | Zusätzlicher Bewuchs-/Flächenbegriff zurückgestellt: meadow, lawn, rainforest und wetland decken bewusst unterschiedliche Nutzung und Feuchte ab; keine Gleichsetzung aller Landschaften. | — |
| tulip | Weitere Pflanzenart zurückgestellt; mit moss, fern, nettle, oak und pine bleibt die Artenliste klein und alltagsnah. | — |
| fly | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Weitere Tierart, Körperstruktur oder Verhaltensnuance zurückgestellt; häufige Tiergruppen und Lebensraumbegriffe priorisiert. | fly / fly/VERB / fly#flugreise; en:card:6ab9ff0073a30fba1775972b5dd2a13c |
| rise | Weitere Naturprozess-/Zustandsableitung zurückgestellt; ausgewählte Schadereignisse, Wasserbewegungen und Entwicklungsprozesse bilden den begrenzten Kern. Keine behauptete Synonymie aller Vorgänge. | — |
| mend | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Weitere Ableitung oder engerer Entsorgungs-/Reinigungsbegriff zurückgestellt; zentrale Begriffe priorisiert. | repair / repair/VERB / repair#repariert |
| damp | Zusätzliche Temperatur-/Feuchteabstufung zurückgestellt; vorhandene Wärme-/Kältebegriffe und präzises humid genügen, muggy wäre besonders nah an humid. | — |
| swamp | Zusätzlicher Bewuchs-/Flächenbegriff zurückgestellt: meadow, lawn, rainforest und wetland decken bewusst unterschiedliche Nutzung und Feuchte ab; keine Gleichsetzung aller Landschaften. | — |
| sunflower | Weitere Pflanzenart zurückgestellt; mit moss, fern, nettle, oak und pine bleibt die Artenliste klein und alltagsnah. | — |
| dragonfly | Weitere Tierart zurückgestellt; keine Aufzählung aller vertrauten Arten zur Mengenerfüllung. Ausgewählte häufige Tierformen, Körperteile und Lebensräume haben Vorrang. | — |
| fall | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Als Herbst regionale Benennung von autumn; andere Fall-Bedeutungen nicht Ziel dieses Stapels. | fall / fall/VERB / fall#fallen; en:card:f20a0dbef7e41dcd9ba4e01c7a78e941 |
| refill | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Weitere Ableitung oder engerer Entsorgungs-/Reinigungsbegriff zurückgestellt; zentrale Begriffe priorisiert. | refill / refill/VERB / refill#nachfullen; en:card:73b24a1a7ffb81ec42c449dcf82e8bf6 |
| wet | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Engere Wetterausprägung oder weniger priorisierte Bezeichnung; die ausgewählten Warnlagen und Grundbegriffe sind ausreichend, keine künstliche Mengenerfüllung. | wet / wet/ADJ / wet#nass; en:card:8daa342f4f8c669d1c6de5fd2141be12 |
| lavender | Weitere Pflanzenart zurückgestellt; mit moss, fern, nettle, oak und pine bleibt die Artenliste klein und alltagsnah. | — |
| grasshopper | Weitere Tierart zurückgestellt; keine Aufzählung aller vertrauten Arten zur Mengenerfüllung. Ausgewählte häufige Tierformen, Körperteile und Lebensräume haben Vorrang. | — |
| shake | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Engerer Vorgang oder Zustandsbegriff zurückgestellt; ausgewählte alltagstaugliche Naturereignisse priorisiert. | shake / shake/VERB / shake#schuettelt; en:card:658b5fbe480bd97d682a95a237a4324a |
| grain | Weiterer Brennstoff, Rohzustand oder Materialtyp zurückgestellt; coal/gas/timber sowie wenige gebräuchliche Gesteine und Metalle genügen, keine Mineralienliste. | — |
| save | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Weitere Ableitung oder engerer Entsorgungs-/Reinigungsbegriff zurückgestellt; zentrale Begriffe priorisiert. | save / save/VERB / save#speichern; en:card:34895e72119623b1c15a28962948a5b9 |
| reforestation | Zusätzlicher forstwirtschaftlicher Prozess zurückgestellt; deforestation und conservation genügen als klarer Eingriff/Schutz-Gegensatz. | — |
| dry | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Engere Wetterausprägung oder weniger priorisierte Bezeichnung; die ausgewählten Warnlagen und Grundbegriffe sind ausreichend, keine künstliche Mengenerfüllung. | dry / dry/ADJ / dry#trocken; en:card:83733c31e4ffa7e7a8fa6f20be312cba |
| bay | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Weitere Gelände-/Gewässerunterart oder Lagebeschreibung zurückgestellt; vorhandene Begriffe und präzise ausgewählte Landschaftsformen priorisiert. | bay / bay/NOUN / bay#bucht; en:card:859259e2015f429b81a99156f858dd76 |
| dandelion | Weitere Pflanzenart zurückgestellt; mit moss, fern, nettle, oak und pine bleibt die Artenliste klein und alltagsnah. | — |
| cricket | Weitere Tierart zurückgestellt; keine Aufzählung aller vertrauten Arten zur Mengenerfüllung. Ausgewählte häufige Tierformen, Körperteile und Lebensräume haben Vorrang. | — |
| blow | Weitere Naturprozess-/Zustandsableitung zurückgestellt; ausgewählte Schadereignisse, Wasserbewegungen und Entwicklungsprozesse bilden den begrenzten Kern. Keine behauptete Synonymie aller Vorgänge. | — |
| dust | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Zusätzliches Material, Untermerkmal oder Abbauwort zurückgestellt; gebräuchliche Materialien und grundlegende Prozesse priorisiert. | dust / dust/NOUN / dust#staub; en:card:59982528c2ae8dbe290c7d49d79f7f3a |
| gulf | Weitere Ufer-/Lage-/Gewässer- oder Geländeausprägung zurückgestellt; Bestand und ausgewählte Landformen reichen aus. Riverbank ist besonders nah am bereits gelernten shore. | — |
| poppy | Weitere Pflanzenart zurückgestellt; mit moss, fern, nettle, oak und pine bleibt die Artenliste klein und alltagsnah. | — |
| shine | Weitere Naturprozess-/Zustandsableitung zurückgestellt; ausgewählte Schadereignisse, Wasserbewegungen und Entwicklungsprozesse bilden den begrenzten Kern. Keine behauptete Synonymie aller Vorgänge. | — |
| avoid | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Weitere Ableitung oder engerer Entsorgungs-/Reinigungsbegriff zurückgestellt; zentrale Begriffe priorisiert. | avoid / avoid/VERB / avoid#vermeiden; en:card:38c13ee68ed29dc2ca9dee167e02836c |
| logging | Zusätzlicher forstwirtschaftlicher Prozess zurückgestellt; deforestation und conservation genügen als klarer Eingriff/Schutz-Gegensatz. | — |
| clover | Weitere Pflanzenart zurückgestellt; mit moss, fern, nettle, oak und pine bleibt die Artenliste klein und alltagsnah. | — |
| tick | Weitere Tierart zurückgestellt; keine Aufzählung aller vertrauten Arten zur Mengenerfüllung. Ausgewählte häufige Tierformen, Körperteile und Lebensräume haben Vorrang. | — |
| glow | Weitere Naturprozess-/Zustandsableitung zurückgestellt; ausgewählte Schadereignisse, Wasserbewegungen und Entwicklungsprozesse bilden den begrenzten Kern. Keine behauptete Synonymie aller Vorgänge. | — |
| prevent | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Zusätzlicher Fach-, Verwaltungs- oder zusammengesetzter Energiebegriff zurückgestellt; zentrale alltagstaugliche Begriffe priorisiert. | prevent / prevent/VERB / prevent#hindern; en:card:e27be42b137b637ddc454693774aae48 |
| daffodil | Weitere Pflanzenart zurückgestellt; mit moss, fern, nettle, oak und pine bleibt die Artenliste klein und alltagsnah. | — |
| worm | Weitere Tierart zurückgestellt; keine Aufzählung aller vertrauten Arten zur Mengenerfüllung. Ausgewählte häufige Tierformen, Körperteile und Lebensräume haben Vorrang. | — |
| reflect | Weitere Naturprozess-/Zustandsableitung zurückgestellt; ausgewählte Schadereignisse, Wasserbewegungen und Entwicklungsprozesse bilden den begrenzten Kern. Keine behauptete Synonymie aller Vorgänge. | — |
| protect | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Zusätzlicher Fach-, Verwaltungs- oder zusammengesetzter Energiebegriff zurückgestellt; zentrale alltagstaugliche Begriffe priorisiert. | protect / protect/VERB / protect#schuetzen; en:card:0e0ff5b237950aca916a0d37c9cbb3ee |
| restoration | Weitere nominale Prozess-/Eigenschaftsableitung zurückgestellt; sustainable, conservation, survive und fragile werden mit präziser Zieldefinition verwendet. | — |
| clear | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Engere Wetterausprägung oder weniger priorisierte Bezeichnung; die ausgewählten Warnlagen und Grundbegriffe sind ausreichend, keine künstliche Mengenerfüllung. | clear / clear/ADJ / clear#klares; en:card:5fb4546300c34779e97cf95026a3f880 |
| tide | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Weitere Gelände-/Gewässerunterart oder Lagebeschreibung zurückgestellt; vorhandene Begriffe und präzise ausgewählte Landschaftsformen priorisiert. | tide / tide/NOUN / tide#gezeitenstand; en:card:38df7db55d6660d3cddf9465d35fba3a |
| snowdrop | Weitere Pflanzenart zurückgestellt; mit moss, fern, nettle, oak und pine bleibt die Artenliste klein und alltagsnah. | — |
| earthworm | Weitere Tierart zurückgestellt; keine Aufzählung aller vertrauten Arten zur Mengenerfüllung. Ausgewählte häufige Tierformen, Körperteile und Lebensräume haben Vorrang. | — |
| evaporate | Weitere Naturprozess-/Zustandsableitung zurückgestellt; ausgewählte Schadereignisse, Wasserbewegungen und Entwicklungsprozesse bilden den begrenzten Kern. Keine behauptete Synonymie aller Vorgänge. | — |
| rusty | Zusätzliche Materialableitung oder Eigenschaft zurückgestellt; rust als Stoff und solid/liquid, brittle/transparent werden gezielt eingeführt. | — |
| clean-up | Schreib-/Mehrwortvariante nicht als zusätzliches Ziel reservieren; keine künstlich verbundenen Bindestrichformen für gewöhnliche Mehrwortausdrücke. | — |
| slippery | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Engere Wetterausprägung oder weniger priorisierte Bezeichnung; die ausgewählten Warnlagen und Grundbegriffe sind ausreichend, keine künstliche Mengenerfüllung. | slippery / slippery/ADJ / slippery#rutschig; en:card:81b2a2ba4286884f51039144df381ed2 |
| wave | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Weitere Gelände-/Gewässerunterart oder Lagebeschreibung zurückgestellt; vorhandene Begriffe und präzise ausgewählte Landschaftsformen priorisiert. | wave / wave/NOUN / wave#welle; en:card:490c92b20876aa3fb2535f375a4109ca |
| condense | Weitere Naturprozess-/Zustandsableitung zurückgestellt; ausgewählte Schadereignisse, Wasserbewegungen und Entwicklungsprozesse bilden den begrenzten Kern. Keine behauptete Synonymie aller Vorgänge. | — |
| metallic | Zusätzliche Materialableitung oder Eigenschaft zurückgestellt; rust als Stoff und solid/liquid, brittle/transparent werden gezielt eingeführt. | — |
| cleanup | Schreib-/Mehrwortvariante nicht als zusätzliches Ziel reservieren; keine künstlich verbundenen Bindestrichformen für gewöhnliche Mehrwortausdrücke. | — |
| endangered | Schutzstatus-/Verlustvarianten werden hier durch conservation, extinction und survive kontextuell abgedeckt; keine zusätzlichen adjektivischen Gegenstücke. | — |
| current | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Weitere Gelände-/Gewässerunterart oder Lagebeschreibung zurückgestellt; vorhandene Begriffe und präzise ausgewählte Landschaftsformen priorisiert. | current / current/NOUN / current#wasserstroemung; en:card:92db889e36a6496d3b640051a7d5f96c |
| slug | Weitere Tierart zurückgestellt; keine Aufzählung aller vertrauten Arten zur Mengenerfüllung. Ausgewählte häufige Tierformen, Körperteile und Lebensräume haben Vorrang. | — |
| erode | Weitere Naturprozess-/Zustandsableitung zurückgestellt; ausgewählte Schadereignisse, Wasserbewegungen und Entwicklungsprozesse bilden den begrenzten Kern. Keine behauptete Synonymie aller Vorgänge. | — |
| wooden | Zusätzliche Materialableitung oder Eigenschaft zurückgestellt; rust als Stoff und solid/liquid, brittle/transparent werden gezielt eingeführt. | — |
| littering | Weitere Nominalisierung/Verbvariante zu contaminate, pollution, litter, leak oder Reinigung; keine zusätzliche Prozessfamilie. | — |
| vulnerable | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Zusätzlicher Fach-, Verwaltungs- oder zusammengesetzter Energiebegriff zurückgestellt; zentrale alltagstaugliche Begriffe priorisiert. | vulnerable / vulnerable/ADJ / vulnerable#verletzlich; en:card:cae8fb32204bfa80350049d0a099bf17 |
| flooding | Bloße Wetterableitung oder enge Variante des entsprechenden Grundphänomens; kein weiteres Lernziel für diese Form. | — |
| bank | Weitere Ufer-/Lage-/Gewässer- oder Geländeausprägung zurückgestellt; Bestand und ausgewählte Landformen reichen aus. Riverbank ist besonders nah am bereits gelernten shore. | — |
| wild | Weitere Pflanzen-/Vorkommenseigenschaft zurückgestellt; giftig, fruchtbar und saisonales Blattverhalten haben hier die klareren praktischen Lernabsichten. | — |
| decompose | Biologischer Zerfall bereits über decay als Lernabsicht vertreten; kein zweiter Prozesskopf. | — |
| microplastic | Engerer technischer Umwelt-/Entsorgungsbegriff zurückgestellt; Grundbegriffe plastic, recycle, pesticide und sewage zuerst. | — |
| threatened | Schutzstatus-/Verlustvarianten werden hier durch conservation, extinction und survive kontextuell abgedeckt; keine zusätzlichen adjektivischen Gegenstücke. | — |
| riverbank | Weitere Ufer-/Lage-/Gewässer- oder Geländeausprägung zurückgestellt; Bestand und ausgewählte Landformen reichen aus. Riverbank ist besonders nah am bereits gelernten shore. | — |
| native | Weitere Pflanzen-/Vorkommenseigenschaft zurückgestellt; giftig, fruchtbar und saisonales Blattverhalten haben hier die klareren praktischen Lernabsichten. | — |
| toad | Weitere Tierart zurückgestellt; keine Aufzählung aller vertrauten Arten zur Mengenerfüllung. Ausgewählte häufige Tierformen, Körperteile und Lebensräume haben Vorrang. | — |
| hailstone | Einzelkorn desselben Phänomens hail; kein zweiter Hagelkopf. | — |
| riverbed | Weitere Ufer-/Lage-/Gewässer- oder Geländeausprägung zurückgestellt; Bestand und ausgewählte Landformen reichen aus. Riverbank ist besonders nah am bereits gelernten shore. | — |
| reproduce | Weitere Naturprozess-/Zustandsableitung zurückgestellt; ausgewählte Schadereignisse, Wasserbewegungen und Entwicklungsprozesse bilden den begrenzten Kern. Keine behauptete Synonymie aller Vorgänge. | — |
| gaseous | Zusätzliche Materialableitung oder Eigenschaft zurückgestellt; rust als Stoff und solid/liquid, brittle/transparent werden gezielt eingeführt. | — |
| fume | Zusätzliche Abfallableitung, Infrastruktur oder Eigenschaft zurückgestellt; landfill, sewage/wastewater und ausdrücklich unterschiedliche reusable/recyclable/biodegradable priorisiert. | — |
| survival | Weitere nominale Prozess-/Eigenschaftsableitung zurückgestellt; sustainable, conservation, survive und fragile werden mit präziser Zieldefinition verwendet. | — |
| prickly | Weitere Pflanzen-/Vorkommenseigenschaft zurückgestellt; giftig, fruchtbar und saisonales Blattverhalten haben hier die klareren praktischen Lernabsichten. | — |
| lizard | Weitere Tierart zurückgestellt; keine Aufzählung aller vertrauten Arten zur Mengenerfüllung. Ausgewählte häufige Tierformen, Körperteile und Lebensräume haben Vorrang. | — |
| shed | Weitere Naturprozess-/Zustandsableitung zurückgestellt; ausgewählte Schadereignisse, Wasserbewegungen und Entwicklungsprozesse bilden den begrenzten Kern. Keine behauptete Synonymie aller Vorgänge. | — |
| porous | Zusätzliche Materialableitung oder Eigenschaft zurückgestellt; rust als Stoff und solid/liquid, brittle/transparent werden gezielt eingeführt. | — |
| adapt | Allgemeines Anpassen überschneidet sich mit vorhandenen Anpassungshandlungen; keine zusätzliche Karte. | — |
| muggy | Zusätzliche Temperatur-/Feuchteabstufung zurückgestellt; vorhandene Wärme-/Kältebegriffe und präzises humid genügen, muggy wäre besonders nah an humid. | — |
| glacier | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Weitere Gelände-/Gewässerunterart oder Lagebeschreibung zurückgestellt; vorhandene Begriffe und präzise ausgewählte Landschaftsformen priorisiert. | glacier / glacier/NOUN / glacier#gletscher; en:card:cd1790bdd1cc4f33980ba43e3e83b598 |
| grow | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Zusätzliche Pflanzenart, Teilstruktur oder Gartenhandlung zurückgestellt; keine Artenliste zur Mengenerfüllung. | get / get/VERB / get#werden |
| turtle | Weitere Tierart zurückgestellt; keine Aufzählung aller vertrauten Arten zur Mengenerfüllung. Ausgewählte häufige Tierformen, Körperteile und Lebensräume haben Vorrang. | — |
| renew | Weitere Naturprozess-/Zustandsableitung zurückgestellt; ausgewählte Schadereignisse, Wasserbewegungen und Entwicklungsprozesse bilden den begrenzten Kern. Keine behauptete Synonymie aller Vorgänge. | — |
| durable | Zusätzliche Materialableitung oder Eigenschaft zurückgestellt; rust als Stoff und solid/liquid, brittle/transparent werden gezielt eingeführt. | — |
| adaptation | Weitere nominale Prozess-/Eigenschaftsableitung zurückgestellt; sustainable, conservation, survive und fragile werden mit präziser Zieldefinition verwendet. | — |
| wintry | Bloße Wetterableitung oder enge Variante des entsprechenden Grundphänomens; kein weiteres Lernziel für diese Form. | — |
| sprout | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Zusätzliche Pflanzenart, Teilstruktur oder Gartenhandlung zurückgestellt; keine Artenliste zur Mengenerfüllung. | sprout / sprout/NOUN / sprout#spross; en:card:57e51bf4244ecc8dfcdd420dda7cc060 |
| tortoise | Weitere Tierart zurückgestellt; keine Aufzählung aller vertrauten Arten zur Mengenerfüllung. Ausgewählte häufige Tierformen, Körperteile und Lebensräume haben Vorrang. | — |
| restore | Weitere Naturprozess-/Zustandsableitung zurückgestellt; ausgewählte Schadereignisse, Wasserbewegungen und Entwicklungsprozesse bilden den begrenzten Kern. Keine behauptete Synonymie aller Vorgänge. | — |
| light-pollution | Schreib-/Mehrwortvariante nicht als zusätzliches Ziel reservieren; keine künstlich verbundenen Bindestrichformen für gewöhnliche Mehrwortausdrücke. | — |
| impact | Auswirkung überschneidet sich mit vorhandenen Wirkungsbegriffen; footprint als Umweltmaß präziser. | — |
| scorching | Zusätzliche Temperatur-/Feuchteabstufung zurückgestellt; vorhandene Wärme-/Kältebegriffe und präzises humid genügen, muggy wäre besonders nah an humid. | — |
| volcano | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Weitere Gelände-/Gewässerunterart oder Lagebeschreibung zurückgestellt; vorhandene Begriffe und präzise ausgewählte Landschaftsformen priorisiert. | volcano / volcano/NOUN / volcano#vulkan; en:card:2cd030165873b9d79f40151dfa21a852 |
| germinate | Zusätzlicher Pflanzenentwicklungsprozess oder dessen Ableitung zurückgestellt; growth, decay, pollinate und dormant bilden die ausgewählten Entwicklungsabsichten. | — |
| crocodile | Weitere Tierart zurückgestellt; keine Aufzählung aller vertrauten Arten zur Mengenerfüllung. Ausgewählte häufige Tierformen, Körperteile und Lebensräume haben Vorrang. | — |
| flexible | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Zusätzliches Material, Untermerkmal oder Abbauwort zurückgestellt; gebräuchliche Materialien und grundlegende Prozesse priorisiert. | flexible / flexible/ADJ / flexible#veraenderbar; en:card:37e700dc1a3453159d075744a011b8a1 |
| spill | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Weitere Ableitung oder engerer Entsorgungs-/Reinigungsbegriff zurückgestellt; zentrale Begriffe priorisiert. | spill / spill/VERB / spill#verschutten; en:card:2be769b2f23ff6194bf9877017f76b8f |
| consequence | Allgemeiner Handlungs-/Verwaltungs- oder Wirkungsbegriff zurückgestellt; ban, awareness, harmful und footprint sind die gewählten Natur-/Umweltabsichten. | — |
| coolness | Zusätzliche Temperatur-/Feuchteabstufung zurückgestellt; vorhandene Wärme-/Kältebegriffe und präzises humid genügen, muggy wäre besonders nah an humid. | — |
| wither | Zusätzlicher Pflanzenentwicklungsprozess oder dessen Ableitung zurückgestellt; growth, decay, pollinate und dormant bilden die ausgewählten Entwicklungsabsichten. | — |
| bat | Weitere Tierart zurückgestellt; keine Aufzählung aller vertrauten Arten zur Mengenerfüllung. Ausgewählte häufige Tierformen, Körperteile und Lebensräume haben Vorrang. | — |
| damage | Allgemeiner Handlungs-/Verwaltungs- oder Wirkungsbegriff zurückgestellt; ban, awareness, harmful und footprint sind die gewählten Natur-/Umweltabsichten. | — |
| wilt | Zusätzlicher Pflanzenentwicklungsprozess oder dessen Ableitung zurückgestellt; growth, decay, pollinate und dormant bilden die ausgewählten Entwicklungsabsichten. | — |
| mouse | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Weitere Tierart, Körperstruktur oder Verhaltensnuance zurückgestellt; häufige Tiergruppen und Lebensraumbegriffe priorisiert. | mouse / mouse/NOUN / mouse#maus; en:card:4711b6b1104c48dd05262e68ab6ba459 |
| frozen | Weitere Naturprozess-/Zustandsableitung zurückgestellt; ausgewählte Schadereignisse, Wasserbewegungen und Entwicklungsprozesse bilden den begrenzten Kern. Keine behauptete Synonymie aller Vorgänge. | — |
| opaque | Zusätzliche Materialableitung oder Eigenschaft zurückgestellt; rust als Stoff und solid/liquid, brittle/transparent werden gezielt eingeführt. | — |
| leakage | Weitere Nominalisierung/Verbvariante zu contaminate, pollution, litter, leak oder Reinigung; keine zusätzliche Prozessfamilie. | — |
| harm | Allgemeiner Handlungs-/Verwaltungs- oder Wirkungsbegriff zurückgestellt; ban, awareness, harmful und footprint sind die gewählten Natur-/Umweltabsichten. | — |
| thermometer | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Engere Wetterausprägung oder weniger priorisierte Bezeichnung; die ausgewählten Warnlagen und Grundbegriffe sind ausreichend, keine künstliche Mengenerfüllung. | thermometer / thermometer/NOUN / thermometer#thermometer; en:card:4d607ac8adef0e6886fae5e1ea9aed9d |
| ravine | Weitere Ufer-/Lage-/Gewässer- oder Geländeausprägung zurückgestellt; Bestand und ausgewählte Landformen reichen aus. Riverbank ist besonders nah am bereits gelernten shore. | — |
| ripen | Zusätzlicher Pflanzenentwicklungsprozess oder dessen Ableitung zurückgestellt; growth, decay, pollinate und dormant bilden die ausgewählten Entwicklungsabsichten. | — |
| rat | Weitere Tierart zurückgestellt; keine Aufzählung aller vertrauten Arten zur Mengenerfüllung. Ausgewählte häufige Tierformen, Körperteile und Lebensräume haben Vorrang. | — |
| molten | Weitere Naturprozess-/Zustandsableitung zurückgestellt; ausgewählte Schadereignisse, Wasserbewegungen und Entwicklungsprozesse bilden den begrenzten Kern. Keine behauptete Synonymie aller Vorgänge. | — |
| threaten | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Zusätzlicher Fach-, Verwaltungs- oder zusammengesetzter Energiebegriff zurückgestellt; zentrale alltagstaugliche Begriffe priorisiert. | threaten / threaten/VERB / threaten#drohen; en:card:2343427527144284cb32304072374557 |
| Celsius | Nach einer Person benannte Temperaturskala; Eigennamen sind nicht Ziel dieser Auswahl. | — |
| summit | Weitere Ufer-/Lage-/Gewässer- oder Geländeausprägung zurückgestellt; Bestand und ausgewählte Landformen reichen aus. Riverbank ist besonders nah am bereits gelernten shore. | — |
| rot | Zusätzlicher Pflanzenentwicklungsprozess oder dessen Ableitung zurückgestellt; growth, decay, pollinate und dormant bilden die ausgewählten Entwicklungsabsichten. | — |
| fallen | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Engerer Vorgang oder Zustandsbegriff zurückgestellt; ausgewählte alltagstaugliche Naturereignisse priorisiert. | fall/VERB / fall#fallen |
| rescue | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Zusätzlicher Fach-, Verwaltungs- oder zusammengesetzter Energiebegriff zurückgestellt; zentrale alltagstaugliche Begriffe priorisiert. | rescue / rescue/VERB / rescue#retten; en:card:c3c86d8802592d022d927899430052e8 |
| peak | Weitere Ufer-/Lage-/Gewässer- oder Geländeausprägung zurückgestellt; Bestand und ausgewählte Landformen reichen aus. Riverbank ist besonders nah am bereits gelernten shore. | — |
| budding | Zusätzlicher Pflanzenentwicklungsprozess oder dessen Ableitung zurückgestellt; growth, decay, pollinate und dormant bilden die ausgewählten Entwicklungsabsichten. | — |
| mine | Zusätzlicher Abbauort, Prozess oder Lagebegriff zurückgestellt; quarry, extract und refine decken Ort, Gewinnung und Aufbereitung ab. | — |
| purify | Reinigen überschneidet sich mit gelerntem clean; filter und refine decken konkrete Verfahren ab. | — |
| foothill | Weitere Ufer-/Lage-/Gewässer- oder Geländeausprägung zurückgestellt; Bestand und ausgewählte Landformen reichen aus. Riverbank ist besonders nah am bereits gelernten shore. | — |
| mole | Weitere Tierart zurückgestellt; keine Aufzählung aller vertrauten Arten zur Mengenerfüllung. Ausgewählte häufige Tierformen, Körperteile und Lebensräume haben Vorrang. | — |
| fading | Zusätzlicher Pflanzenentwicklungsprozess oder dessen Ableitung zurückgestellt; growth, decay, pollinate und dormant bilden die ausgewählten Entwicklungsabsichten. | — |
| purification | Weitere Nominalisierung/Verbvariante zu contaminate, pollution, litter, leak oder Reinigung; keine zusätzliche Prozessfamilie. | — |
| rake | Zusätzliche Gartenhandlung zurückgestellt; sow, prune, mow und harvest decken Aussaat, Pflege und Ernte gezielt ab. | — |
| rabbit | Weitere Tierart zurückgestellt; keine Aufzählung aller vertrauten Arten zur Mengenerfüllung. Ausgewählte häufige Tierformen, Körperteile und Lebensräume haben Vorrang. | — |
| drill | Zusätzlicher Abbauort, Prozess oder Lagebegriff zurückgestellt; quarry, extract und refine decken Ort, Gewinnung und Aufbereitung ab. | — |
| treatment | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Weitere Ableitung oder engerer Entsorgungs-/Reinigungsbegriff zurückgestellt; zentrale Begriffe priorisiert. | treatment / treatment/NOUN / treatment#behandlung; en:card:b1259dc4f124af7299d7c0b2edde1fe5 |
| inland | Weitere Ufer-/Lage-/Gewässer- oder Geländeausprägung zurückgestellt; Bestand und ausgewählte Landformen reichen aus. Riverbank ist besonders nah am bereits gelernten shore. | — |
| hare | Weitere Tierart zurückgestellt; keine Aufzählung aller vertrauten Arten zur Mengenerfüllung. Ausgewählte häufige Tierformen, Körperteile und Lebensräume haben Vorrang. | — |
| sanitation | Engerer technischer Umwelt-/Entsorgungsbegriff zurückgestellt; Grundbegriffe plastic, recycle, pesticide und sewage zuerst. | — |
| conserve | Schutz/Ressourcenschonung über conservation abgedeckt. | — |
| offshore | Weitere Ufer-/Lage-/Gewässer- oder Geländeausprägung zurückgestellt; Bestand und ausgewählte Landformen reichen aus. Riverbank ist besonders nah am bereits gelernten shore. | — |
| water | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Zusätzliche Pflanzenart, Teilstruktur oder Gartenhandlung zurückgestellt; keine Artenliste zur Mengenerfüllung. | water / water/NOUN / water#wasser; en:card:a6d3a06c4d1730345031c0b4fc6cac91 |
| detergent | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Weitere Ableitung oder engerer Entsorgungs-/Reinigungsbegriff zurückgestellt; zentrale Begriffe priorisiert. | detergent / detergent/NOUN / detergent#waschmittel; en:card:bb3009610e899a3029aa11a6a7035399 |
| upstream | Weitere Ufer-/Lage-/Gewässer- oder Geländeausprägung zurückgestellt; Bestand und ausgewählte Landformen reichen aus. Riverbank ist besonders nah am bereits gelernten shore. | — |
| downstream | Weitere Ufer-/Lage-/Gewässer- oder Geländeausprägung zurückgestellt; Bestand und ausgewählte Landformen reichen aus. Riverbank ist besonders nah am bereits gelernten shore. | — |
| uproot | Zusätzliche Gartenhandlung zurückgestellt; sow, prune, mow und harvest decken Aussaat, Pflege und Ernte gezielt ab. | — |
| badger | Weitere Tierart zurückgestellt; keine Aufzählung aller vertrauten Arten zur Mengenerfüllung. Ausgewählte häufige Tierformen, Körperteile und Lebensräume haben Vorrang. | — |
| underwater | Weitere Ufer-/Lage-/Gewässer- oder Geländeausprägung zurückgestellt; Bestand und ausgewählte Landformen reichen aus. Riverbank ist besonders nah am bereits gelernten shore. | — |
| otter | Weitere Tierart zurückgestellt; keine Aufzählung aller vertrauten Arten zur Mengenerfüllung. Ausgewählte häufige Tierformen, Körperteile und Lebensräume haben Vorrang. | — |
| herbicide | Engerer technischer Umwelt-/Entsorgungsbegriff zurückgestellt; Grundbegriffe plastic, recycle, pesticide und sewage zuerst. | — |
| scarcity | Mengen-/Verfügbarkeitsfeld wird durch resource und shortage abgedeckt; keine zusätzlichen Gegenpol- und Ableitungsköpfe. | — |
| depth | Weitere Ufer-/Lage-/Gewässer- oder Geländeausprägung zurückgestellt; Bestand und ausgewählte Landformen reichen aus. Riverbank ist besonders nah am bereits gelernten shore. | — |
| beaver | Weitere Tierart zurückgestellt; keine Aufzählung aller vertrauten Arten zur Mengenerfüllung. Ausgewählte häufige Tierformen, Körperteile und Lebensräume haben Vorrang. | — |
| shallow | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Weitere Gelände-/Gewässerunterart oder Lagebeschreibung zurückgestellt; vorhandene Begriffe und präzise ausgewählte Landschaftsformen priorisiert. | shallow / shallow/ADJ / shallow#flach; en:card:7ed60761bb57a732ecd8b813c05bbe0d |
| wolf | Weitere Tierart zurückgestellt; keine Aufzählung aller vertrauten Arten zur Mengenerfüllung. Ausgewählte häufige Tierformen, Körperteile und Lebensräume haben Vorrang. | — |
| deep | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Weitere Gelände-/Gewässerunterart oder Lagebeschreibung zurückgestellt; vorhandene Begriffe und präzise ausgewählte Landschaftsformen priorisiert. | deep / deep/ADJ / deep#gewaessertiefe; en:card:1f6a558093f3bacf259f76f367cffa6a |
| earth | Weitere Boden-/Stängel-/Wuchsbenennung zurückgestellt; soil und stem werden als genaue Grundbegriffe reserviert. Stalk kein zweiter Stängelkopf. | — |
| bear | Weitere Tierart zurückgestellt; keine Aufzählung aller vertrauten Arten zur Mengenerfüllung. Ausgewählte häufige Tierformen, Körperteile und Lebensräume haben Vorrang. | — |
| freshwater | Weitere Ufer-/Lage-/Gewässer- oder Geländeausprägung zurückgestellt; Bestand und ausgewählte Landformen reichen aus. Riverbank ist besonders nah am bereits gelernten shore. | — |
| boar | Weitere Tierart zurückgestellt; keine Aufzählung aller vertrauten Arten zur Mengenerfüllung. Ausgewählte häufige Tierformen, Körperteile und Lebensräume haben Vorrang. | — |
| underground | Zusätzlicher Abbauort, Prozess oder Lagebegriff zurückgestellt; quarry, extract und refine decken Ort, Gewinnung und Aufbereitung ab. | — |
| carbon-neutral | Weitere Energiequelle, technische Benennung oder Zusammensetzung zurückgestellt; solar/hydropower, turbine/insulation und wenige zentrale Stoffe werden präzise reserviert. | — |
| saltwater | Weitere Ufer-/Lage-/Gewässer- oder Geländeausprägung zurückgestellt; Bestand und ausgewählte Landformen reichen aus. Riverbank ist besonders nah am bereits gelernten shore. | — |
| seal | Weitere Tierart zurückgestellt; keine Aufzählung aller vertrauten Arten zur Mengenerfüllung. Ausgewählte häufige Tierformen, Körperteile und Lebensräume haben Vorrang. | — |
| deposit | Zusätzlicher Abbauort, Prozess oder Lagebegriff zurückgestellt; quarry, extract und refine decken Ort, Gewinnung und Aufbereitung ab. | — |
| upcycle | Engerer technischer Umwelt-/Entsorgungsbegriff zurückgestellt; Grundbegriffe plastic, recycle, pesticide und sewage zuerst. | — |
| carbon-free | Weitere Energiequelle, technische Benennung oder Zusammensetzung zurückgestellt; solar/hydropower, turbine/insulation und wenige zentrale Stoffe werden präzise reserviert. | — |
| surface | Weitere Ufer-/Lage-/Gewässer- oder Geländeausprägung zurückgestellt; Bestand und ausgewählte Landformen reichen aus. Riverbank ist besonders nah am bereits gelernten shore. | — |
| vein | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Zusätzliches Material, Untermerkmal oder Abbauwort zurückgestellt; gebräuchliche Materialien und grundlegende Prozesse priorisiert. | vein / vein/NOUN / vein#vene; en:card:1e1593d8d2fed6b81bd6376650d43cc6 |
| supply | Mengen-/Verfügbarkeitsfeld wird durch resource und shortage abgedeckt; keine zusätzlichen Gegenpol- und Ableitungsköpfe. | — |
| environment-friendly | Alternative Benennung zu eco-friendly; kein zweites Ziel. | — |
| shark | Weitere Tierart zurückgestellt; keine Aufzählung aller vertrauten Arten zur Mengenerfüllung. Ausgewählte häufige Tierformen, Körperteile und Lebensräume haben Vorrang. | — |
| scarce | Mengen-/Verfügbarkeitsfeld wird durch resource und shortage abgedeckt; keine zusätzlichen Gegenpol- und Ableitungsköpfe. | — |
| emission-free | Weitere Energiequelle, technische Benennung oder Zusammensetzung zurückgestellt; solar/hydropower, turbine/insulation und wenige zentrale Stoffe werden präzise reserviert. | — |
| canal | Weitere Ufer-/Lage-/Gewässer- oder Geländeausprägung zurückgestellt; Bestand und ausgewählte Landformen reichen aus. Riverbank ist besonders nah am bereits gelernten shore. | — |
| bulb | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Zusätzliche Pflanzenart, Teilstruktur oder Gartenhandlung zurückgestellt; keine Artenliste zur Mengenerfüllung. | bulb / bulb/NOUN / bulb#gluhbirne; en:card:73177afc3ed0015ceb487292579646b8 |
| duck | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Weitere Tierart, Körperstruktur oder Verhaltensnuance zurückgestellt; häufige Tiergruppen und Lebensraumbegriffe priorisiert. | duck / duck/NOUN / duck#entenfleisch; en:card:561f2dd34f1872f998dd8d59788f4d9c |
| abundant | Mengen-/Verfügbarkeitsfeld wird durch resource und shortage abgedeckt; keine zusätzlichen Gegenpol- und Ableitungsköpfe. | — |
| energy-saving | Weitere Energiequelle, technische Benennung oder Zusammensetzung zurückgestellt; solar/hydropower, turbine/insulation und wenige zentrale Stoffe werden präzise reserviert. | — |
| ditch | Weitere Ufer-/Lage-/Gewässer- oder Geländeausprägung zurückgestellt; Bestand und ausgewählte Landformen reichen aus. Riverbank ist besonders nah am bereits gelernten shore. | — |
| goose | Weitere Tierart zurückgestellt; keine Aufzählung aller vertrauten Arten zur Mengenerfüllung. Ausgewählte häufige Tierformen, Körperteile und Lebensräume haben Vorrang. | — |
| low-carbon | Weitere Energiequelle, technische Benennung oder Zusammensetzung zurückgestellt; solar/hydropower, turbine/insulation und wenige zentrale Stoffe werden präzise reserviert. | — |
| swan | Weitere Tierart zurückgestellt; keine Aufzählung aller vertrauten Arten zur Mengenerfüllung. Ausgewählte häufige Tierformen, Körperteile und Lebensräume haben Vorrang. | — |
| stalk | Weitere Boden-/Stängel-/Wuchsbenennung zurückgestellt; soil und stem werden als genaue Grundbegriffe reserviert. Stalk kein zweiter Stängelkopf. | — |
| muddy | Weitere Ufer-/Lage-/Gewässer- oder Geländeausprägung zurückgestellt; Bestand und ausgewählte Landformen reichen aus. Riverbank ist besonders nah am bereits gelernten shore. | — |
| vine | Weitere Boden-/Stängel-/Wuchsbenennung zurückgestellt; soil und stem werden als genaue Grundbegriffe reserviert. Stalk kein zweiter Stängelkopf. | — |
| eagle | Weitere Tierart zurückgestellt; keine Aufzählung aller vertrauten Arten zur Mengenerfüllung. Ausgewählte häufige Tierformen, Körperteile und Lebensräume haben Vorrang. | — |
| path | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Weitere Gelände-/Gewässerunterart oder Lagebeschreibung zurückgestellt; vorhandene Begriffe und präzise ausgewählte Landschaftsformen priorisiert. | path / path/NOUN / path#fussweg; en:card:2311ac50bc66cf1f2c7075e469a6af6d |
| hawk | Weitere Tierart zurückgestellt; keine Aufzählung aller vertrauten Arten zur Mengenerfüllung. Ausgewählte häufige Tierformen, Körperteile und Lebensräume haben Vorrang. | — |
| campaign | Allgemeiner Handlungs-/Verwaltungs- oder Wirkungsbegriff zurückgestellt; ban, awareness, harmful und footprint sind die gewählten Natur-/Umweltabsichten. | — |
| trail | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Weitere Gelände-/Gewässerunterart oder Lagebeschreibung zurückgestellt; vorhandene Begriffe und präzise ausgewählte Landschaftsformen priorisiert. | trail / trail/NOUN / trail#wanderpfad; en:card:e46e489d4aeb338449e877a9c380d42b |
| greenery | Weitere Pflanzenableitung, Sammelbezeichnung oder Detailstruktur zurückgestellt; flower/leaf/seed/branch/cone bilden die gewählten Grundstrukturen, keine Gleichsetzung der Früchte. | — |
| robin | Weitere Tierart zurückgestellt; keine Aufzählung aller vertrauten Arten zur Mengenerfüllung. Ausgewählte häufige Tierformen, Körperteile und Lebensräume haben Vorrang. | — |
| footpath | Weitere Ufer-/Lage-/Gewässer- oder Geländeausprägung zurückgestellt; Bestand und ausgewählte Landformen reichen aus. Riverbank ist besonders nah am bereits gelernten shore. | — |
| sparrow | Weitere Tierart zurückgestellt; keine Aufzählung aller vertrauten Arten zur Mengenerfüllung. Ausgewählte häufige Tierformen, Körperteile und Lebensräume haben Vorrang. | — |
| volunteer | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Zusätzlicher Fach-, Verwaltungs- oder zusammengesetzter Energiebegriff zurückgestellt; zentrale alltagstaugliche Begriffe priorisiert. | volunteer / volunteer/NOUN / volunteer#freiwilliger; en:card:59c5883de30c55713952b28ce48fe6d5 |
| pigeon | Weitere Tierart zurückgestellt; keine Aufzählung aller vertrauten Arten zur Mengenerfüllung. Ausgewählte häufige Tierformen, Körperteile und Lebensräume haben Vorrang. | — |
| regulation | Allgemeine Vorschrift/Regel überschneidet sich mit bereits gelerntem rule; kein zusätzlicher Kopf. | — |
| crow | Weitere Tierart zurückgestellt; keine Aufzählung aller vertrauten Arten zur Mengenerfüllung. Ausgewählte häufige Tierformen, Körperteile und Lebensräume haben Vorrang. | — |
| raven | Weitere Tierart zurückgestellt; keine Aufzählung aller vertrauten Arten zur Mengenerfüllung. Ausgewählte häufige Tierformen, Körperteile und Lebensräume haben Vorrang. | — |
| limit | Allgemeiner Handlungs-/Verwaltungs- oder Wirkungsbegriff zurückgestellt; ban, awareness, harmful und footprint sind die gewählten Natur-/Umweltabsichten. | — |
| woodpecker | Weitere Tierart zurückgestellt; keine Aufzählung aller vertrauten Arten zur Mengenerfüllung. Ausgewählte häufige Tierformen, Körperteile und Lebensräume haben Vorrang. | — |
| regulate | Allgemeiner Handlungs-/Verwaltungs- oder Wirkungsbegriff zurückgestellt; ban, awareness, harmful und footprint sind die gewählten Natur-/Umweltabsichten. | — |
| penguin | Weitere Tierart zurückgestellt; keine Aufzählung aller vertrauten Arten zur Mengenerfüllung. Ausgewählte häufige Tierformen, Körperteile und Lebensräume haben Vorrang. | — |
| swallow | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Weitere Tierart, Körperstruktur oder Verhaltensnuance zurückgestellt; häufige Tiergruppen und Lebensraumbegriffe priorisiert. | swallow / swallow/VERB / swallow#schlucken; en:card:012625554b43711e844ce1d4cca0e836 |
| stork | Weitere Tierart zurückgestellt; keine Aufzählung aller vertrauten Arten zur Mengenerfüllung. Ausgewählte häufige Tierformen, Körperteile und Lebensräume haben Vorrang. | — |
| resilience | Weitere nominale Prozess-/Eigenschaftsableitung zurückgestellt; sustainable, conservation, survive und fragile werden mit präziser Zieldefinition verwendet. | — |
| salmon | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Weitere Tierart, Körperstruktur oder Verhaltensnuance zurückgestellt; häufige Tiergruppen und Lebensraumbegriffe priorisiert. | salmon / salmon/NOUN / salmon#lachs; en:card:97cf7d9f934cf092abfeb8cbedc33f67 |
| resilient | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Zusätzlicher Fach-, Verwaltungs- oder zusammengesetzter Energiebegriff zurückgestellt; zentrale alltagstaugliche Begriffe priorisiert. | resilient / resilient/ADJ / resilient#widerstandsfahig; en:card:0b2f75e611fbf03ddb271dab5acbc4a5 |
| trout | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Weitere Tierart, Körperstruktur oder Verhaltensnuance zurückgestellt; häufige Tiergruppen und Lebensraumbegriffe priorisiert. | trout / trout/NOUN / trout#forelle; en:card:a99eec60a54f696ad20ad7d14f00b760 |
| crab | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Weitere Tierart, Körperstruktur oder Verhaltensnuance zurückgestellt; häufige Tiergruppen und Lebensraumbegriffe priorisiert. | crab / crab/NOUN / crab#krabbe; en:card:4397438d5f3ba6347820b48111e70451 |
| prawn | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Weitere Tierart, Körperstruktur oder Verhaltensnuance zurückgestellt; häufige Tiergruppen und Lebensraumbegriffe priorisiert. | prawn / prawn/NOUN / prawn#garnele; en:card:2b7f82a42082eb42ee0f7e7cc8a16452 |
| solar-powered | Weitere Energiequelle, technische Benennung oder Zusammensetzung zurückgestellt; solar/hydropower, turbine/insulation und wenige zentrale Stoffe werden präzise reserviert. | — |
| hunt | Weitere Tierhandlung, Laut- oder Merkmalsbezeichnung zurückgestellt; graze, hatch, migrate und hibernate sind die gewählten klar verschiedenen Vorgänge. | — |
| wind-powered | Weitere Energiequelle, technische Benennung oder Zusammensetzung zurückgestellt; solar/hydropower, turbine/insulation und wenige zentrale Stoffe werden präzise reserviert. | — |
| breed | Weitere Tierhandlung, Laut- oder Merkmalsbezeichnung zurückgestellt; graze, hatch, migrate und hibernate sind die gewählten klar verschiedenen Vorgänge. | — |
| sting | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Weitere Tierart, Körperstruktur oder Verhaltensnuance zurückgestellt; häufige Tiergruppen und Lebensraumbegriffe priorisiert. | sting / sting/VERB / sting#stechen-von-insekten; en:card:9f09788c46252a0d1b06155645fee852 |
| bite | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Weitere Tierart, Körperstruktur oder Verhaltensnuance zurückgestellt; häufige Tiergruppen und Lebensraumbegriffe priorisiert. | bite / bite/VERB / bite#beissen; en:card:361810e811f40ac1f0332d5c1da47e2d |
| crawl | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Weitere Tierart, Körperstruktur oder Verhaltensnuance zurückgestellt; häufige Tiergruppen und Lebensraumbegriffe priorisiert. | crawl / crawl/VERB / crawl#krabbeln; en:card:0dd6e90ddbbead4d42d4715b89ce4d8b |
| buzz | Weitere Tierhandlung, Laut- oder Merkmalsbezeichnung zurückgestellt; graze, hatch, migrate und hibernate sind die gewählten klar verschiedenen Vorgänge. | — |
| chirp | Weitere Tierhandlung, Laut- oder Merkmalsbezeichnung zurückgestellt; graze, hatch, migrate und hibernate sind die gewählten klar verschiedenen Vorgänge. | — |
| roar | Weitere Tierhandlung, Laut- oder Merkmalsbezeichnung zurückgestellt; graze, hatch, migrate und hibernate sind die gewählten klar verschiedenen Vorgänge. | — |
| tame | Weitere Tierhandlung, Laut- oder Merkmalsbezeichnung zurückgestellt; graze, hatch, migrate und hibernate sind die gewählten klar verschiedenen Vorgänge. | — |
| nocturnal | Weitere Tierhandlung, Laut- oder Merkmalsbezeichnung zurückgestellt; graze, hatch, migrate und hibernate sind die gewählten klar verschiedenen Vorgänge. | — |
| extinct | Schutzstatus-/Verlustvarianten werden hier durch conservation, extinction und survive kontextuell abgedeckt; keine zusätzlichen adjektivischen Gegenstücke. | — |
| venomous | Weitere Tierhandlung, Laut- oder Merkmalsbezeichnung zurückgestellt; graze, hatch, migrate und hibernate sind die gewählten klar verschiedenen Vorgänge. | — |
| furry | Weitere Tierhandlung, Laut- oder Merkmalsbezeichnung zurückgestellt; graze, hatch, migrate und hibernate sind die gewählten klar verschiedenen Vorgänge. | — |
| scaly | Weitere Tierhandlung, Laut- oder Merkmalsbezeichnung zurückgestellt; graze, hatch, migrate und hibernate sind die gewählten klar verschiedenen Vorgänge. | — |
| domestic | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. Weitere Tierart, Körperstruktur oder Verhaltensnuance zurückgestellt; häufige Tiergruppen und Lebensraumbegriffe priorisiert. | domestic / domestic/ADJ / domestic#inlaendisch; en:card:30644c5d01cb4248773c6828dedb89b5 |
| nestling | Weitere Tierhandlung, Laut- oder Merkmalsbezeichnung zurückgestellt; graze, hatch, migrate und hibernate sind die gewählten klar verschiedenen Vorgänge. | — |

## Export und ZIP-Prüfung

Unveränderter vorhandener Exporter und vorhandene Verträge verwendet. Neue getrennte Original-/Kontextauswahl, Registry und Lerngruppen angelegt. Der vorhandene einmalige Essen-Vorbereitungshelfer wurde als lokales Hilfsskript unter build/natur_umwelt_checks/ an die neue redaktionelle Auswahl angepasst; keine neue Exportpipeline oder generisches Framework.

ZIP enthält 81 Dateien mit 80 Manifesthashes: Basis-Pack und SQLite, Wörterbuch, alle 242 Identitäten, alle drei Gruppen, Positionen, Registry/Gruppen, unveränderte Validator-/Importquellen und erforderliche Offline-Ressourcen. Nur 81 aktuelle Ziele für Batch 1. Nach Schließen und erneutem Öffnen CRCs, alle Manifesthashes, Referenzen, Besitz/Aliase/Gruppen und alle 18 SQLite-Tabellen geprüft. Danach ohne Überschreiben an den Endpfad verschoben und dort erneut vollständig geprüft. Basisdateien in der ZIP sind bytegleich zum tatsächlichen aktuellen Pack.

Absoluter ZIP-Pfad: /Users/ardasayar/Documents/FlutterProjekte/sprachapp/build/natur_umwelt_authoring_batch_1.zip

## Befehle und tatsächliche Outputs

Ab Repository-Root. PYTHON bedeutet auf macOS Terminal pipeline/.venv-macos/bin/python, unter Windows PowerShell .\pipeline\.venv\Scripts\python.exe. Git-Befehle identisch auf beiden Systemen. Logs und Hilfsskripte: build/natur_umwelt_checks/.

```text
PYTHON pipeline/scripts/export_authoring_context.py --help
PYTHON build/natur_umwelt_checks/prepare.py
PYTHON build/natur_umwelt_checks/audit.py
PYTHON build/natur_umwelt_checks/final_review.py
PYTHON -m pytest pipeline/tests/test_selection.py pipeline/tests/test_word_registry.py pipeline/tests/test_learning_groups.py pipeline/tests/test_authoring_context.py pipeline/tests/test_authoring_schema3.py pipeline/tests/test_authoring_continuation.py -q
PYTHON pipeline/scripts/export_authoring_context.py --selection pipeline/data/selection/natur_umwelt_batch_1_context_v1.json --batch 1 --out build/natur_umwelt_checks/staging/natur_umwelt_authoring_batch_1.zip
PYTHON pipeline/scripts/export_authoring_context.py --verify-zip build/natur_umwelt_checks/staging/natur_umwelt_authoring_batch_1.zip
PYTHON pipeline/scripts/export_authoring_context.py --verify-zip build/natur_umwelt_authoring_batch_1.zip
git status --short
git diff --check -- pipeline/data/selection/natur_umwelt_v1.json pipeline/data/selection/natur_umwelt_batch_1_context_v1.json pipeline/data/words/en.natur_umwelt_batch_1_context_v1.json pipeline/data/learning_groups/en.natur_umwelt_batch_1_context_v1.json docs/natur-umwelt-authoring.md NEXTSTEPS.md
```

### audit.log

```text
BASE PASS: schema 3 / essen_trinken_batch_3_v1 / 1994 cards / 1879 primary targets / 7 decks
SQLITE_FULL_ROWS {'languages': 1, 'lemmas': 3160, 'senses': 4571, 'cards': 1994, 'dictionary_forms': 5338, 'decks': 7, 'deck_cards': 1994, 'deck_words': 1890, 'word_aliases': 35, 'sentences': 2528, 'sentence_tokens': 28128, 'card_sentences': 2522, 'stories': 1, 'story_sentences': 6, 'exercises': 0, 'grammar_rules': 0, 'audio_assets': 0, 'content_releases': 1}
BATCH 1 partitions {'imported': 0, 'current': 81, 'future': 161} display 1..81 topics 8
BATCH 2 partitions {'imported': 81, 'current': 81, 'future': 80} display 1..162 topics 8
BATCH 3 partitions {'imported': 162, 'current': 80, 'future': 0} display 1..242 topics 8
PASS membership-only display simulation batch 2 append 82..162 display 1..162
PASS membership-only display simulation batch 3 append 163..242 display 1..242
PASS 694 candidates / 242 selected / 452 excluded; 1890 old owners and 1994 old group members preserved; zero generated sentences
PASS original identities, positions and definitions immutable across all 3 batches; base SQLite and asset hash unchanged
PASS initial selection and Batch-1 snapshot identical

Exit 0
```

### final-review.log

```text
PASS 242 explicit EN/DE definitions; 30 reused senses / 212 explicit new definitions; 452 exclusions with reasons
PASS no adjacent related goals in complete order or any of three authoring batches
PASS historical learning group snapshots 16 no selected identity collision
PASS no sentence alternatives authored; aliases do not grant answers
POS {'NOUN': 190, 'ADJ': 24, 'VERB': 28}

Exit 0
```

### pytest.log

```text
............................................................             [100%]
60 passed in 0.92s

Exit 0
```

### verify-final.log

```text
{
  "zip_verification": "PASS",
  "zip_sha256": "3ba7db8d373b402aca01437b3a301c8b19b39a57d0bee5a06013b69afec949a6",
  "hashed_files": 80,
  "sqlite_tables": 18,
  "sqlite_cards": 1994,
  "credentials_and_learning_states": "none; explicit content/source/model whitelist",
  "status": "PASS",
  "selected": 242,
  "excluded": 452,
  "batches": {
    "1": 81,
    "2": 81,
    "3": 80
  },
  "topics_per_batch": {
    "1": {
      "Tiere und ihre Lebensräume": 15,
      "Pflanzen, Bäume und Pflanzenteile": 12,
      "Klima, Energie und Naturschutz": 11,
      "Materialien und natürliche Ressourcen": 11,
      "Umwelt, Abfall und Recycling": 9,
      "Landschaften und Gewässer": 9,
      "Naturvorgänge und Jahreszeiten": 8,
      "Wetter und Temperatur": 6
    },
    "2": {
      "Tiere und ihre Lebensräume": 15,
      "Pflanzen, Bäume und Pflanzenteile": 12,
      "Materialien und natürliche Ressourcen": 12,
      "Klima, Energie und Naturschutz": 11,
      "Umwelt, Abfall und Recycling": 9,
      "Naturvorgänge und Jahreszeiten": 8,
      "Landschaften und Gewässer": 8,
      "Wetter und Temperatur": 6
    },
    "3": {
      "Tiere und ihre Lebensräume": 15,
      "Pflanzen, Bäume und Pflanzenteile": 12,
      "Materialien und natürliche Ressourcen": 11,
      "Klima, Energie und Naturschutz": 10,
      "Umwelt, Abfall und Recycling": 10,
      "Naturvorgänge und Jahreszeiten": 8,
      "Landschaften und Gewässer": 8,
      "Wetter und Temperatur": 6
    }
  },
  "existing_senses": 30,
  "new_senses": 212,
  "existing_cards": 1994,
  "existing_groups": 1982,
  "new_groups": 242,
  "registry_words": 2132,
  "partition_selection": "PASS: 0 present",
  "validate_selection": "PASS: parent and exact reservations",
  "index_registry": "PASS",
  "validate_learning": "PASS: existing and planned",
  "build_rows": "PASS: reservation-only rows unchanged",
  "semantic_review": "explicit editorial decisions, no automatic equivalence inference"
}

Exit 0
```

## SHA256 (Rohbytes)

| Datei | SHA256 |
|---|---|
| pipeline/out/essen_trinken_batch_3_v1/pack.json | `0a7a73b424f1625f71a2af892ff2a610f6103aef263d210bdcc3fc528d0ce521` |
| pipeline/out/essen_trinken_batch_3_v1/content.sqlite | `cffc9e4529ada7f61e0bbf7e2e1e7d7d0926f68957b616f2497e38234405d2ce` |
| assets/content/en/content.sqlite | `cffc9e4529ada7f61e0bbf7e2e1e7d7d0926f68957b616f2497e38234405d2ce` |
| assets/content/en/content.manifest.json | `3edb2db9a0a549521956ebf2f8ff9014574b46b95f04e5be39a48e9091436248` |
| pipeline/data/selection/natur_umwelt_v1.json | `344f4b562855584acf8c3290ff2c8b5c7f4a6b400b937cd7f166cd0671ee0c21` |
| pipeline/data/selection/natur_umwelt_batch_1_context_v1.json | `344f4b562855584acf8c3290ff2c8b5c7f4a6b400b937cd7f166cd0671ee0c21` |
| pipeline/data/words/en.natur_umwelt_batch_1_context_v1.json | `4554d0a7cefb12232cb1551e8f9112e0fbf10f82af8f7c1750dc0c6c421bb2b2` |
| pipeline/data/learning_groups/en.natur_umwelt_batch_1_context_v1.json | `5e91c2acda7ef6a048136889f261998f61eebc8977353d5487ce4cc52c8beeab` |
| build/natur_umwelt_authoring_batch_1.zip | `3ba7db8d373b402aca01437b3a301c8b19b39a57d0bee5a06013b69afec949a6` |

Registry kanonisch: `e48eeec73e894e8569c437a36f591642e91b4fc8add564fd22a201b3c9a969d6`. Gruppen kanonisch: `b2c7059d1372ecf1e483ebc8e07f7e72aa6d634336e512ccea70df850da2a8a8`.

## Bestandsschutz und Grenzen

Vor Beginn 2440 vorhandene Dateien erfasst. Ausschließlich NEXTSTEPS.md darf sich unter den Bestandsdateien ändern. Neue Dateien: Original-/Kontextauswahl, Registry, Gruppen, dieser Bericht und ZIP. Schlussnachweis in final-protection.json und final-checks.log; Git-Status vor/nachher gespeichert.

Die sieben bekannten Whitespace-Altstellen bleiben unangetastet: DESIGN.md:162–164, docs/alltag-zuhause-continuation.md:148/153, docs/arbeit-bildung-batch-1-import.md:127 und docs/arbeit-bildung-batch-2-import.md:121. Nur beauftragte Pfade geprüft; keine riesige repositoryweite Diff-Ausgabe. Unversionierte neue Dateien zusätzlich separat gegen /dev/null geprüft. NEXTSTEPS behält CRLF und wird zusätzlich CRLF-tolerant gegen die Ausgangskopie geprüft.

Keine ungeklärte ausgewählte Bedeutungsbindung. Ausschlussbegründungen wurden vor ZIP-Abschluss präzisiert, ohne gewählte Identitäten oder Positionen zu verändern; der Vorentwurf bleibt unter build/natur_umwelt_checks/draft_before_exclusion_review/. Alle Vertragsprüfungen bestanden ohne Validatorlockerung. Der Berichtsentwurf enthielt zunächst eine falsche Anzahl der Abgrenzungsnotizen (47 statt tatsächlich 48); die Assertion stoppte vor Dateiausgabe. Der unmittelbar folgende Bestandsschutzcheck fand entsprechend noch keine NEXTSTEPS-Änderung. Beide lokalen Berichtsschritte wurden nach Korrektur erneut ausgeführt; Auswahl und ZIP waren unverändert. Keine Cloud-/Modellaufrufe, neuen Sätze, App-/Pipelineänderung, Staging, Veröffentlichung, Commits oder Pushes. Keine echte user.db/review_log geöffnet; keine Flutter- oder Gerätetests für reine Auswahlvorbereitung.

Nächster Schritt: ausschließlich die 81 aktuellen Ziele aus authoring_context.json redigieren. Die übrigen 161 Ziele bleiben reserviert. Später je ein fester Satz mit deutscher Übersetzung, vollständiger Annotation und einzeln geprüften neutralen Alternativen.

## Abschließender Nachweis

```text
BASELINE 2440 UNCHANGED 2439 CHANGED ['NEXTSTEPS.md']
git-diff-check-targeted Exit 2 output bytes 2227
git-diff-check-targeted-crlf Exit 0 output bytes 0
PASS new untracked files and NEXTSTEPS separately checked; own whitespace Exit 0
git status --short Exit 0; saved to git-status-after.txt
PASS all historical selections/registries/groups, packs, deliveries, assets and app/pipeline code unchanged; no repository-wide diff generated

Exit 0
```

2439 von 2440 Ausgangsdateien bytegleich; nur NEXTSTEPS.md geändert. Der normale gezielte Diff-Check meldet die erhaltenen CRLF-Zeilen von NEXTSTEPS als Whitespace (Exit 2); CRLF-tolerant und separat gegen die Ausgangskopie keine Befunde. Alle neuen unversionierten Dateien zusätzlich geprüft.
