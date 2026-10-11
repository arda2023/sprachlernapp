# Essen & Trinken: Auswahl und Authoring-Gruppe 1

## Aktueller Abschlussstatus – 10.10.2026

250/250 Originalziele sind mit je einem festen aktiven Satz in essen_trinken_batch_3_v1 intern gestagt. Partition 250 importiert / 0 aktuell / 0 später; kein Restbatch und keine Batch-4-ZIP. Alle Identitäten, Definitionen, Lerngruppen, Besitzer, Aliase und Originalpositionen vollständig abgeglichen. Insgesamt 1879 primäre Lernziele in sieben Stapeln (160/489/241/245/245/249/250).

Vollständiger SQLite-Abgleich aller 18 Tabellen, Asset-Verifikation, Siebenstapel-Lesetest, 123 Pipeline-Tests plus 19 Untertests und Flutter-Analyse bestanden. Asset und Manifest wurden nachweislich vor Staging gesichert. Bericht mit Outputs/Hashes: [Batch-3-Abschluss](essen-trinken-batch-3-import.md). Keine öffentliche Inhaltsfreigabe; Geräteprüfung und bekannte Altbefunde bleiben offen.

## Historischer Vorbereitungsstand

Die folgenden Angaben dokumentieren die ursprüngliche Auswahl und die damalige Batch-1-Vorbereitung; ihre nächsten Schritte wurden durch die drei Importbatches erledigt.


Stand: 10.10.2026. 333 Kandidaten geprüft, 250 eigenständige Lernziele ausgewählt und 83 begründet ausgeschlossen. Drei Gruppen mit 84/83/83 Zielen; jede enthält alle acht Themen. 19 vorhandene Wörterbuchbedeutungen werden unverändert wiederverwendet, 231 Bedeutungen sind ausdrücklich neu redaktionell definiert. Wortarten: 190 Substantive, 37 Verben, 23 Adjektive.

Nur Vorbereitung: keine Übungssätze, keine neuen Satzalternativen, kein Import oder Staging. Die unveränderte Basis koerper_gesundheit_batch_3_v1 enthält Schema 3, 1744 Karten, 1629 primäre Ziele in sechs Stapeln. Basis-SQLite und App-Asset entsprechen exakt dem beauftragten Hash.

## Auswahl und Abgrenzung

Die Kandidaten wurden gegen sämtliche Kartenformen, Formen unterrichteter Senses, Satzalternativen und alle 19 historischen Besitzregistrys geprüft. Zusätzlich wurden 13 historische Lerngruppen-Dateien auf ausgewählte Identitätskollisionen geprüft. Bestehende Gruppen/Karten werden nicht verändert. Alle 1640 alten Besitzer und 1744 alten Karten-Gruppenbindungen bleiben erhalten; die neue Registry reserviert 250 weitere Wörter (insgesamt 1890), der neue Gruppenkontext 250 eigenständige Köpfe. Reservierungen erzeugen keine Inhaltszeilen.

Jeder Eintrag hat stabile Form-/Lemma-/POS-/Sense-/Kartenidentitäten, deutsche Zielübersetzung, präzise deutsche und englische Bedeutungsdefinition, Thema, Originalposition, Besitzer und Lerngruppe. Neue Definitionen sind als editorially_defined/proposed_new gekennzeichnet; vorhandene Sensezeilen bleiben einschließlich ihrer historischen Glossen unverändert. Ein Wörterbucheintrag ohne bisherige Karte oder Besitz ist kein bereits gelerntes Ziel.

Besonders geprüft:

- ripe und mature haben beide die deutsche Glosse „reif“. Die vorhandene mature-Definition betrifft erwachsenes Denken und Verhalten, ripe die Fruchtreife: getrennte Lernabsichten.
- clove bezeichnet hier Gewürznelke, die vorhandene Wörterbuchbedeutung ausdrücklich eine Knoblauchzehe. still bezeichnet hier ein Getränk ohne Kohlensäure; unbeweglich bleibt unverändert.
- spread wird mit dem vorhandenen Sense wiederverwendet; ein historischer Butter-Satz belegt genau diese Verwendung. reduce bleibt beim vorhandenen allgemeinen Verringern-Sense; kein künstlicher Küchen-Subsense. melt bleibt beim vorhandenen Schmelzen-Sense.
- stock ist bereits als Warenbestand gelernt. broth ist die ausgekochte Flüssigkeit und gravy die Bratensaftsoße. taste und smell sind bestehende Wahrnehmungs-/Probierhandlungen; flavour, aroma und texture benennen Eigenschaften.
- Benannte Lebensmittelarten sind keine bloßen Synonyme: etwa lentil/chickpea gegenüber bean, unterschiedliche Fischarten, pie mit Hülle/Deckel gegenüber offener tart. Küchenvorgänge unterscheiden sich in Mittel und Ergebnis: chop/dice/grate/mash sowie simmer/steam/poach/braise. Engere oder regionale Doppelköpfe wie skillet neben pan und saucepan neben pot wurden zurückgestellt.
- Britische/amerikanische Schreibungen werden nicht doppelt gezählt. Orthografische Aliasse (etwa whisky/whiskey, flavour/flavor, omelette/omelet) stehen getrennt von regionalen Benennungen (aubergine/eggplant, courgette/zucchini, maize/corn). cilantro wird nur für die Blattverwendung von coriander als nicht separat einzuführender Kandidat geführt; keine Gleichsetzung mit Koriandersamen und keine Satzfreigabe. prawn/shrimp, biscuit/cookie, icing/frosting erhalten keinen zweiten Kopf.
- scales, tongs und leftovers sind lexikalische Pluralwörter, keine zusätzliche Flexionskarte eines vorhandenen Singularziels. Künstliche Bindestrichformen rolling-pin, chopping-board und packed-lunch wurden ausgeschlossen. well-done ist dagegen ein übliches lexikalisches Adjektiv und wird als solches reserviert.

Die vollständigen Bedeutungsabgrenzungen stehen in semantic_decisions und pro Eintrag in review/learning.note. Gleiche deutsche Glossen waren Prüfsignale, keine automatische Synonymentscheidung. Die Wahl der Gesamtzahl folgt der bereinigten Auswahl; keine seltenen Marken-/Fachbegriffe zur Mengenerfüllung ergänzt. Wortfrequenz ist nur Kontext, kein automatischer Ausschluss alltäglicher Zutaten.

## Themen und Gruppen

| Thema | Gesamt | Gruppe 1 | Gruppe 2 | Gruppe 3 |
|---|---:|---:|---:|---:|
| Obst, Gemüse und Hülsenfrüchte | 40 | 14 | 13 | 13 |
| Milchprodukte, Eier, Fleisch und Fisch | 34 | 11 | 12 | 11 |
| Gewürze, Zutaten und Würzmittel | 34 | 11 | 11 | 12 |
| Kochen, Backen und Küchenhandlungen | 34 | 12 | 11 | 11 |
| Getreide, Brot und Backwaren | 33 | 11 | 11 | 11 |
| Mahlzeiten, Geschmack und Essenssituationen | 28 | 10 | 9 | 9 |
| Getränke und Getränkezubereitung | 24 | 8 | 8 | 8 |
| Küchenutensilien, Geschirr und Aufbewahrung | 23 | 7 | 8 | 8 |

Die Batch-Zuordnung verteilt jedes Thema reihum auf die jeweils kleinsten Gruppen. Die endgültige Originalreihenfolge ist deterministisch gespeichert: bei der redaktionellen Vorbereitung wurde unter zulässigen Kandidaten das Thema mit den meisten verbleibenden Zielen bevorzugt, Gleichstände nach Kandidatenposition. Weder in der Gesamtauswahl noch innerhalb einer Gruppe stehen Ziele mit gemeinsamem Kontrasttag unmittelbar nebeneinander. Die anfängliche Entwurfsreihenfolge hatte am Ende benachbarte Gemüseziele; dies wurde vor Export behoben. Originalpositionen/IDs sind ab dieser geprüften Auswahl verbindlich.

Erste Gruppe: 0 importiert / 84 aktuell / 166 später, Pack-Anzeige 1–84. Später Batch 2: 85–167 anhängen, dann hashgebunden Anzeige 1–167; Batch 3: 168–250 anhängen, dann Anzeige 1–250. Der vorhandene Displayvertrag wurde ausschließlich im Speicher mit Mitgliedschaftszeilen simuliert. Keine Mitgliedschaft wurde in das aktuelle Pack geschrieben. Die spätere App-Lernreihenfolge bleibt Sache der bestehenden Gruppen-/Themenlogik.

## Wiederverwendete Bedeutungen

herb, chop, grate, lemonade, vanilla, ripe, toast, melt, tray, biscuit, saucer, reduce, jar, sprinkle, spread, chocolate, batter, container, serve.

Die vorhandenen Definitionen und Beispiele wurden gelesen. Unter anderem sind toast ausdrücklich geröstetes Brot, batter weiche/flüssige Mehlmischung, jar ein verschließbares Weithalsglas und serve das Bereitstellen zum Verzehr. Die jeweils andere serve-Bedeutung „reichen für Personen“ wird nicht gewählt. Historische Glossen wie „Vanille-“ und „Schokolade-“ werden nicht pauschal repariert; die neue Kartenzielübersetzung ist natürlich formuliert.

## Verbindliche Auswahl

Details einschließlich beider Definitionen und sämtlicher stabiler IDs stehen in den JSON-Dateien und der ZIP.

| Originalposition | Ziel | Wortart | Zielübersetzung | Gruppe | Sense |
|---:|---|---|---|---:|---|
| 1 | pear | NOUN | Birne | 1 | neu definiert |
| 2 | raspberry | NOUN | Himbeere | 3 | neu definiert |
| 3 | peach | NOUN | Pfirsich | 2 | neu definiert |
| 4 | blueberry | NOUN | Heidelbeere | 1 | neu definiert |
| 5 | apricot | NOUN | Aprikose | 3 | neu definiert |
| 6 | blackberry | NOUN | Brombeere | 2 | neu definiert |
| 7 | curd | NOUN | Käsebruch | 2 | neu definiert |
| 8 | herb | NOUN | Küchenkraut | 3 | bestehend |
| 9 | chop | VERB | Hacken | 1 | bestehend |
| 10 | plum | NOUN | Pflaume | 1 | neu definiert |
| 11 | wheat | NOUN | Weizen | 2 | neu definiert |
| 12 | buttermilk | NOUN | Buttermilch | 3 | neu definiert |
| 13 | spice | NOUN | Gewürz | 1 | neu definiert |
| 14 | dice | VERB | Würfeln | 2 | neu definiert |
| 15 | cherry | NOUN | Kirsche | 2 | neu definiert |
| 16 | rye | NOUN | Roggen | 3 | neu definiert |
| 17 | margarine | NOUN | Margarine | 1 | neu definiert |
| 18 | basil | NOUN | Basilikum | 2 | neu definiert |
| 19 | grate | VERB | Reiben | 3 | bestehend |
| 20 | cranberry | NOUN | Cranberry | 3 | neu definiert |
| 21 | barley | NOUN | Gerste | 1 | neu definiert |
| 22 | mozzarella | NOUN | Mozzarella | 2 | neu definiert |
| 23 | parsley | NOUN | Petersilie | 3 | neu definiert |
| 24 | whisk | VERB | Verquirlen | 1 | neu definiert |
| 25 | grapefruit | NOUN | Grapefruit | 1 | neu definiert |
| 26 | oat | NOUN | Hafer | 2 | neu definiert |
| 27 | feta | NOUN | Feta | 3 | neu definiert |
| 28 | thyme | NOUN | Thymian | 1 | neu definiert |
| 29 | knead | VERB | Kneten | 2 | neu definiert |
| 30 | lime | NOUN | Limette | 2 | neu definiert |
| 31 | maize | NOUN | Mais | 3 | neu definiert |
| 32 | cheddar | NOUN | Cheddar | 1 | neu definiert |
| 33 | rosemary | NOUN | Rosmarin | 2 | neu definiert |
| 34 | sift | VERB | Sieben | 3 | neu definiert |
| 35 | mandarin | NOUN | Mandarine | 3 | neu definiert |
| 36 | brunch | NOUN | Brunch | 1 | neu definiert |
| 37 | couscous | NOUN | Couscous | 1 | neu definiert |
| 38 | whey | NOUN | Molke | 2 | neu definiert |
| 39 | oregano | NOUN | Oregano | 3 | neu definiert |
| 40 | blend | VERB | Mixen | 1 | neu definiert |
| 41 | pineapple | NOUN | Ananas | 1 | neu definiert |
| 42 | leftovers | NOUN | Essensreste | 2 | neu definiert |
| 43 | quinoa | NOUN | Quinoa | 2 | neu definiert |
| 44 | yolk | NOUN | Eigelb | 3 | neu definiert |
| 45 | dill | NOUN | Dill | 1 | neu definiert |
| 46 | mash | VERB | Zerdrücken | 2 | neu definiert |
| 47 | mango | NOUN | Mango | 2 | neu definiert |
| 48 | feast | NOUN | Festmahl | 3 | neu definiert |
| 49 | semolina | NOUN | Grieß | 3 | neu definiert |
| 50 | eggshell | NOUN | Eierschale | 1 | neu definiert |
| 51 | mint | NOUN | Minze | 2 | neu definiert |
| 52 | season | VERB | Würzen | 3 | neu definiert |
| 53 | melon | NOUN | Melone | 3 | neu definiert |
| 54 | takeaway | NOUN | Essen zum Mitnehmen | 1 | neu definiert |
| 55 | bran | NOUN | Kleie | 1 | neu definiert |
| 56 | omelette | NOUN | Omelett | 2 | neu definiert |
| 57 | coriander | NOUN | Koriander | 3 | neu definiert |
| 58 | marinate | VERB | Marinieren | 1 | neu definiert |
| 59 | watermelon | NOUN | Wassermelone | 1 | neu definiert |
| 60 | espresso | NOUN | Espresso | 1 | neu definiert |
| 61 | canteen | NOUN | Kantine | 2 | neu definiert |
| 62 | yeast | NOUN | Hefe | 2 | neu definiert |
| 63 | sausage | NOUN | Wurst | 3 | neu definiert |
| 64 | cumin | NOUN | Kreuzkümmel | 1 | neu definiert |
| 65 | simmer | VERB | Köcheln | 2 | neu definiert |
| 66 | kiwi | NOUN | Kiwi | 2 | neu definiert |
| 67 | cappuccino | NOUN | Cappuccino | 2 | neu definiert |
| 68 | wok | NOUN | Wok | 2 | neu definiert |
| 69 | diner | NOUN | Essensgast | 3 | neu definiert |
| 70 | loaf | NOUN | Brotlaib | 3 | neu definiert |
| 71 | bacon | NOUN | Speck | 1 | neu definiert |
| 72 | cinnamon | NOUN | Zimt | 2 | neu definiert |
| 73 | steam | VERB | Dämpfen | 3 | neu definiert |
| 74 | coconut | NOUN | Kokosnuss | 3 | neu definiert |
| 75 | latte | NOUN | Milchkaffee | 3 | neu definiert |
| 76 | colander | NOUN | Durchschlag | 3 | neu definiert |
| 77 | crust | NOUN | Kruste | 1 | neu definiert |
| 78 | flavour | NOUN | Geschmack | 1 | neu definiert |
| 79 | ham | NOUN | Schinken | 2 | neu definiert |
| 80 | nutmeg | NOUN | Muskatnuss | 3 | neu definiert |
| 81 | roast | VERB | Im Ofen braten | 1 | neu definiert |
| 82 | avocado | NOUN | Avocado | 1 | neu definiert |
| 83 | lemonade | NOUN | Zitronenlimonade | 1 | bestehend |
| 84 | sieve | NOUN | Sieb | 1 | neu definiert |
| 85 | crumb | NOUN | Krümel | 2 | neu definiert |
| 86 | aroma | NOUN | Aroma | 2 | neu definiert |
| 87 | lamb | NOUN | Lammfleisch | 3 | neu definiert |
| 88 | clove | NOUN | Gewürznelke | 1 | neu definiert |
| 89 | grill | VERB | Grillen | 2 | neu definiert |
| 90 | fig | NOUN | Feige | 2 | neu definiert |
| 91 | smoothie | NOUN | Smoothie | 2 | neu definiert |
| 92 | grater | NOUN | Reibe | 2 | neu definiert |
| 93 | bun | NOUN | Brötchen | 3 | neu definiert |
| 94 | texture | NOUN | Konsistenz | 3 | neu definiert |
| 95 | veal | NOUN | Kalbfleisch | 1 | neu definiert |
| 96 | ginger | NOUN | Ingwer | 2 | neu definiert |
| 97 | poach | VERB | Pochieren | 3 | neu definiert |
| 98 | pomegranate | NOUN | Granatapfel | 3 | neu definiert |
| 99 | milkshake | NOUN | Milchshake | 3 | neu definiert |
| 100 | peeler | NOUN | Sparschäler | 3 | neu definiert |
| 101 | bagel | NOUN | Bagel | 1 | neu definiert |
| 102 | turkey | NOUN | Putenfleisch | 2 | neu definiert |
| 103 | turmeric | NOUN | Kurkuma | 3 | neu definiert |
| 104 | braise | VERB | Schmoren | 1 | neu definiert |
| 105 | crunchy | ADJ | Knusprig | 1 | neu definiert |
| 106 | cabbage | NOUN | Kohl | 1 | neu definiert |
| 107 | cider | NOUN | Apfelwein | 1 | neu definiert |
| 108 | ladle | NOUN | Schöpfkelle | 1 | neu definiert |
| 109 | baguette | NOUN | Baguette | 2 | neu definiert |
| 110 | duck | NOUN | Entenfleisch | 3 | neu definiert |
| 111 | paprika | NOUN | Paprikapulver | 1 | neu definiert |
| 112 | chewy | ADJ | Zäh beim Kauen | 2 | neu definiert |
| 113 | preheat | VERB | Vorheizen | 2 | neu definiert |
| 114 | cauliflower | NOUN | Blumenkohl | 2 | neu definiert |
| 115 | cocktail | NOUN | Cocktail | 2 | neu definiert |
| 116 | spatula | NOUN | Pfannenwender | 2 | neu definiert |
| 117 | flatbread | NOUN | Fladenbrot | 3 | neu definiert |
| 118 | venison | NOUN | Hirschfleisch | 1 | neu definiert |
| 119 | chilli | NOUN | Chili | 2 | neu definiert |
| 120 | tender | ADJ | Zart | 3 | neu definiert |
| 121 | defrost | VERB | Auftauen | 3 | neu definiert |
| 122 | broccoli | NOUN | Brokkoli | 3 | neu definiert |
| 123 | mocktail | NOUN | Alkoholfreier Cocktail | 3 | neu definiert |
| 124 | tongs | NOUN | Küchenzange | 3 | neu definiert |
| 125 | sourdough | NOUN | Sauerteig | 1 | neu definiert |
| 126 | steak | NOUN | Steak | 2 | neu definiert |
| 127 | vanilla | NOUN | Vanille | 3 | bestehend |
| 128 | juicy | ADJ | Saftig | 1 | neu definiert |
| 129 | reheat | VERB | Aufwärmen | 1 | neu definiert |
| 130 | spinach | NOUN | Spinat | 1 | neu definiert |
| 131 | whisky | NOUN | Whisky | 1 | neu definiert |
| 132 | skewer | NOUN | Spieß | 1 | neu definiert |
| 133 | wholemeal | ADJ | Vollkorn- | 2 | neu definiert |
| 134 | mince | NOUN | Hackfleisch | 3 | neu definiert |
| 135 | mustard | NOUN | Senf | 1 | neu definiert |
| 136 | ripe | ADJ | Reif | 2 | bestehend |
| 137 | drain | VERB | Abgießen | 2 | neu definiert |
| 138 | kale | NOUN | Grünkohl | 2 | neu definiert |
| 139 | rum | NOUN | Rum | 2 | neu definiert |
| 140 | blender | NOUN | Standmixer | 2 | neu definiert |
| 141 | crispbread | NOUN | Knäckebrot | 3 | neu definiert |
| 142 | fillet | NOUN | Filet | 1 | neu definiert |
| 143 | ketchup | NOUN | Ketchup | 2 | neu definiert |
| 144 | stale | ADJ | Altbacken | 3 | neu definiert |
| 145 | soak | VERB | Einweichen | 3 | neu definiert |
| 146 | leek | NOUN | Lauch | 3 | neu definiert |
| 147 | gin | NOUN | Gin | 3 | neu definiert |
| 148 | mixer | NOUN | Rührgerät | 3 | neu definiert |
| 149 | toast | NOUN | Toast | 1 | bestehend |
| 150 | meatball | NOUN | Fleischbällchen | 2 | neu definiert |
| 151 | mayonnaise | NOUN | Mayonnaise | 3 | neu definiert |
| 152 | rancid | ADJ | Ranzig | 1 | neu definiert |
| 153 | melt | VERB | Schmelzen | 1 | bestehend |
| 154 | celery | NOUN | Stangensellerie | 1 | neu definiert |
| 155 | vodka | NOUN | Wodka | 1 | neu definiert |
| 156 | scales | NOUN | Küchenwaage | 1 | neu definiert |
| 157 | cracker | NOUN | Cracker | 2 | neu definiert |
| 158 | salmon | NOUN | Lachs | 3 | neu definiert |
| 159 | pesto | NOUN | Pesto | 1 | neu definiert |
| 160 | bland | ADJ | Fade | 2 | neu definiert |
| 161 | caramelise | VERB | Karamellisieren | 2 | neu definiert |
| 162 | radish | NOUN | Radieschen | 2 | neu definiert |
| 163 | liqueur | NOUN | Likör | 2 | neu definiert |
| 164 | tray | NOUN | Tablett | 2 | bestehend |
| 165 | biscuit | NOUN | Keks | 3 | bestehend |
| 166 | tuna | NOUN | Thunfisch | 1 | neu definiert |
| 167 | chutney | NOUN | Chutney | 2 | neu definiert |
| 168 | savoury | ADJ | Herzhaft | 3 | neu definiert |
| 169 | thicken | VERB | Andicken | 3 | neu definiert |
| 170 | beetroot | NOUN | Rote Bete | 3 | neu definiert |
| 171 | decaffeinated | ADJ | Entkoffeiniert | 3 | neu definiert |
| 172 | saucer | NOUN | Untertasse | 3 | bestehend |
| 173 | pastry | NOUN | Gebäckteig | 1 | neu definiert |
| 174 | cod | NOUN | Kabeljau | 2 | neu definiert |
| 175 | gravy | NOUN | Bratensoße | 3 | neu definiert |
| 176 | rich | ADJ | Gehaltvoll | 1 | neu definiert |
| 177 | reduce | VERB | Einkochen | 1 | bestehend |
| 178 | turnip | NOUN | Speiserübe | 1 | neu definiert |
| 179 | fizzy | ADJ | Sprudelnd | 1 | neu definiert |
| 180 | platter | NOUN | Servierplatte | 1 | neu definiert |
| 181 | croissant | NOUN | Croissant | 2 | neu definiert |
| 182 | trout | NOUN | Forelle | 3 | neu definiert |
| 183 | broth | NOUN | Brühe | 1 | neu definiert |
| 184 | creamy | ADJ | Cremig | 2 | neu definiert |
| 185 | garnish | VERB | Garnieren | 2 | neu definiert |
| 186 | parsnip | NOUN | Pastinake | 2 | neu definiert |
| 187 | still | ADJ | Ohne Kohlensäure | 2 | neu definiert |
| 188 | jar | NOUN | Glasgefäß | 2 | bestehend |
| 189 | muffin | NOUN | Muffin | 3 | neu definiert |
| 190 | herring | NOUN | Hering | 1 | neu definiert |
| 191 | syrup | NOUN | Sirup | 2 | neu definiert |
| 192 | smoky | ADJ | Rauchig | 3 | neu definiert |
| 193 | sprinkle | VERB | Bestreuen | 3 | bestehend |
| 194 | asparagus | NOUN | Spargel | 3 | neu definiert |
| 195 | brew | VERB | Aufbrühen | 3 | neu definiert |
| 196 | tin | NOUN | Konservendose | 3 | neu definiert |
| 197 | pancake | NOUN | Pfannkuchen | 1 | neu definiert |
| 198 | sardine | NOUN | Sardine | 2 | neu definiert |
| 199 | cocoa | NOUN | Kakaopulver | 3 | neu definiert |
| 200 | edible | ADJ | Essbar | 1 | neu definiert |
| 201 | spread | VERB | Bestreichen | 1 | bestehend |
| 202 | aubergine | NOUN | Aubergine | 1 | neu definiert |
| 203 | sip | VERB | Nippen | 1 | neu definiert |
| 204 | foil | NOUN | Alufolie | 1 | neu definiert |
| 205 | waffle | NOUN | Waffel | 2 | neu definiert |
| 206 | prawn | NOUN | Garnele | 3 | neu definiert |
| 207 | chocolate | NOUN | Schokolade | 1 | bestehend |
| 208 | homemade | ADJ | Hausgemacht | 2 | neu definiert |
| 209 | stuff | VERB | Füllen | 2 | neu definiert |
| 210 | courgette | NOUN | Zucchini | 2 | neu definiert |
| 211 | refill | VERB | Nachfüllen | 2 | neu definiert |
| 212 | parchment | NOUN | Backpapier | 2 | neu definiert |
| 213 | pie | NOUN | Pastete | 3 | neu definiert |
| 214 | mussel | NOUN | Miesmuschel | 1 | neu definiert |
| 215 | almond | NOUN | Mandel | 2 | neu definiert |
| 216 | organic | ADJ | Bio- | 3 | neu definiert |
| 217 | flip | VERB | Wenden | 3 | neu definiert |
| 218 | pumpkin | NOUN | Kürbis | 3 | neu definiert |
| 219 | straw | NOUN | Trinkhalm | 3 | neu definiert |
| 220 | corkscrew | NOUN | Korkenzieher | 3 | neu definiert |
| 221 | tart | NOUN | Tarte | 1 | neu definiert |
| 222 | oyster | NOUN | Auster | 2 | neu definiert |
| 223 | walnut | NOUN | Walnuss | 3 | neu definiert |
| 224 | boneless | ADJ | Ohne Knochen | 1 | neu definiert |
| 225 | crack | VERB | Aufschlagen | 1 | neu definiert |
| 226 | lentil | NOUN | Linse | 1 | neu definiert |
| 227 | coaster | NOUN | Glasuntersetzer | 1 | neu definiert |
| 228 | stopper | NOUN | Flaschenverschluss | 1 | neu definiert |
| 229 | icing | NOUN | Zuckerguss | 2 | neu definiert |
| 230 | crab | NOUN | Krabbe | 3 | neu definiert |
| 231 | hazelnut | NOUN | Haselnuss | 1 | neu definiert |
| 232 | undercooked | ADJ | Nicht durchgegart | 2 | neu definiert |
| 233 | pit | VERB | Entsteinen | 2 | neu definiert |
| 234 | chickpea | NOUN | Kichererbse | 2 | neu definiert |
| 235 | flask | NOUN | Thermosflasche | 2 | neu definiert |
| 236 | funnel | NOUN | Trichter | 2 | neu definiert |
| 237 | batter | NOUN | Flüssiger Teig | 3 | bestehend |
| 238 | squid | NOUN | Tintenfisch | 1 | neu definiert |
| 239 | peanut | NOUN | Erdnuss | 2 | neu definiert |
| 240 | well-done | ADJ | Durchgebraten | 3 | neu definiert |
| 241 | core | VERB | Entkernen | 3 | neu definiert |
| 242 | sprout | NOUN | Spross | 3 | neu definiert |
| 243 | teabag | NOUN | Teebeutel | 3 | neu definiert |
| 244 | container | NOUN | Behälter | 3 | bestehend |
| 245 | porridge | NOUN | Haferbrei | 1 | neu definiert |
| 246 | tofu | NOUN | Tofu | 2 | neu definiert |
| 247 | sesame | NOUN | Sesam | 3 | neu definiert |
| 248 | rare | ADJ | Blutig gebraten | 1 | neu definiert |
| 249 | serve | VERB | Servieren | 1 | bestehend |
| 250 | olive | NOUN | Olive | 1 | neu definiert |

## Ausgeschlossene Kandidaten

| Kandidat | Begründung |
|---|---|
| saucepan | Stieltopf ist hier eine enge Topfvariante; vorhandenes pot genügt für diesen Grundbestand. |
| skillet | Regionale bzw. weitgehend gleichbedeutende Benennung der vorhandenen pan-Bratpfanne. |
| supper | Abendmahlzeit bereits durch dinner vertreten. |
| helping | Bereits vertretene Portionsbedeutung/Variante; kein weiterer Kopf neben portion. |
| packed-lunch | Keine künstliche Einzelwortform für die Phrase packed lunch. |
| cafeteria | Kantinen-/Selbstbedienungsbereich durch canteen abgedeckt; kein weiterer naher Einrichtungskopf. |
| appetiser | Vorspeise bereits durch starter vertreten. |
| rolling-pin | Keine künstlich durch Bindestriche zusammengezogene Mehrwortform; rolling pin später separat prüfen. |
| chopping-board | Keine künstliche Einzelwortform für die Phrase chopping board. |
| crisp | Für knackige/knusprige Beschaffenheit nur crunchy als neuer Kopf; kein paralleles nahes Synonym. |
| saute | Engere Brattechnik neben fry; Schreibungsfrage sauté/saute nicht für die Grundauswahl priorisiert. |
| steep | Form bereits als Lernziel steil belegt; keine zweite Wortposition für Ziehenlassen. |
| unripe | Bloße Gegenpol-Erweiterung zu ripe zurückgestellt; keine Mengenauffüllung. |
| strain | Form bereits als Muskelzerrung belegt; keine zweite Wortposition für Abseihen. |
| water | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| juice | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| coffee | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| pan | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| tea | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| pot | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| beer | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| bowl | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| wine | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| cup | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| plate | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| noodle | Überlappung mit vorhandenem pasta; keine enge Formvariante als neuer Kopf. |
| spoon | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| knife | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| bread | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| milk | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| salt | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| kettle | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| flour | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| cheese | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| pepper | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| meal | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| dough | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| egg | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| sugar | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| cook | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| breakfast | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| rice | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| cream | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| oil | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| bake | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| lunch | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| pasta | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| chicken | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| vinegar | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| fry | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| dinner | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| beef | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| honey | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| boil | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| starter | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| apple | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| pork | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| garlic | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| stir | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| dessert | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| carrot | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| fish | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| sauce | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| peel | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| sweet | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| bean | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| yoghurt | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| pour | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| sour | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| pea | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| rinse | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| bitter | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| lemon | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| squeeze | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| salty | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| orange | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| diet | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| potato | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| nutrition | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| tomato | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| protein | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| onion | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |
| fibre | Bereits vorhandenes Lernziel oder dessen reservierte Form; Besitzer und Lerngruppe bleiben unverändert. Kein zweiter Zielkopf im Essen-Stapel. |

## Export und geschlossene ZIP-Prüfung

Der unveränderte bestehende Exporter wurde anhand seiner tatsächlichen --help-Ausgabe verwendet. Keine neue Exportarchitektur, Pipeline- oder Validatoränderung. Die vier neuen Kontext-/Auswahldateien nutzen dieselben Verträge wie Körper & Gesundheit; Originalauswahl und Batch-1-Snapshot haben exakt gleiche Einträge und Inhalte.

Die ZIP enthält 81 Dateien einschließlich Manifest mit 80 Dateihashes: vollständigen Basis-Pack und SQLite, Wörterbuchkontext, Auswahl und alle 250 Identitäten/Definitionen, Besitzregistry, Gruppen, neue Stapeldefinition essen-trinken, alle Batch-Anzeigemappings, README mit relativen Projektpfaden und späterem Importablauf, Schemas, unveränderte Quellen und Offline-Tokenizer-Modell. Keine Zugangsdaten, user.db, Lernstände oder persönlichen Dateien. Python-Pakete müssen lokal vorhanden sein; keine Venv und kein Download erforderlich.

Die Datei wurde geschlossen und erneut geöffnet; CRCs, Hashes, Quellen, Referenzen, Partition und alle 18 SQLite-Tabellen wurden geprüft. Danach ohne Überschreiben an den endgültigen Ort verschoben und dort erneut vollständig geprüft. Kein absoluter lokaler Pfad im README als Importvoraussetzung.

Absoluter ZIP-Pfad: /Users/ardasayar/Documents/FlutterProjekte/sprachapp/build/essen_trinken_authoring_batch_1.zip

## Tatsächliche Befehle und Outputs

Ab Repository-Root. PYTHON steht auf macOS Terminal für pipeline/.venv-macos/bin/python, unter Windows PowerShell für .\pipeline\.venv\Scripts\python.exe. Git-Befehle sind identisch. Die Vorbereitungsskripte unter build/essen_trinken_checks/ sind einmalige auftragsspezifische Hilfen; keine neue Pipeline-API.

```text
PYTHON pipeline/scripts/export_authoring_context.py --help
PYTHON build/essen_trinken_checks/prepare.py
PYTHON build/essen_trinken_checks/final_review.py
PYTHON build/essen_trinken_checks/audit.py
PYTHON -m pytest pipeline/tests/test_selection.py pipeline/tests/test_word_registry.py pipeline/tests/test_learning_groups.py pipeline/tests/test_authoring_context.py pipeline/tests/test_authoring_schema3.py pipeline/tests/test_authoring_continuation.py pipeline/tests/test_deck_display.py -q
PYTHON pipeline/scripts/export_authoring_context.py --selection pipeline/data/selection/essen_trinken_batch_1_context_v1.json --batch 1 --out build/essen_trinken_checks/staging/essen_trinken_authoring_batch_1.zip
PYTHON pipeline/scripts/export_authoring_context.py --verify-zip build/essen_trinken_checks/staging/essen_trinken_authoring_batch_1.zip
PYTHON pipeline/scripts/export_authoring_context.py --verify-zip build/essen_trinken_authoring_batch_1.zip
git diff --check
git -c core.whitespace=cr-at-eol diff --check
git status --short
```

### final-review.log

```text
PASS 250 explicit EN/DE definitions; 19 reused senses / 231 explicit new definitions; 83 justified exclusions
PASS no adjacent related goals in complete order or any of three authoring batches
PASS historical learning group snapshots 13 no selected identity collision
PASS same-gloss mature/ripe distinguished; stock/broth, clove, still, spread and reduce resolved from definitions and old examples
PASS spelling aliases separate from regional vocabulary; no sentence-level alternatives or sentences authored
POS {'NOUN': 190, 'VERB': 37, 'ADJ': 23}

Exit 0
```

### audit.log

```text
BASE PASS: schema 3 / koerper_gesundheit_batch_3_v1 / 1744 cards / 1629 primary targets / 6 decks
SQLITE_FULL_ROWS {'languages': 1, 'lemmas': 2873, 'senses': 4254, 'cards': 1744, 'dictionary_forms': 4966, 'decks': 6, 'deck_cards': 1744, 'deck_words': 1640, 'word_aliases': 28, 'sentences': 2278, 'sentence_tokens': 25249, 'card_sentences': 2272, 'stories': 1, 'story_sentences': 6, 'exercises': 0, 'grammar_rules': 0, 'audio_assets': 0, 'content_releases': 1}
BATCH 1 partitions {'imported': 0, 'current': 84, 'future': 166} display 1..84 topics 8
BATCH 2 partitions {'imported': 84, 'current': 83, 'future': 83} display 1..167 topics 8
BATCH 3 partitions {'imported': 167, 'current': 83, 'future': 0} display 1..250 topics 8
PASS membership-only display simulation batch 2 append 85..167 display 1..167
PASS membership-only display simulation batch 3 append 168..250 display 1..250
PASS 333 candidates / 250 selected / 83 excluded; 1640 old owners and 1744 old group members preserved; zero generated sentences
PASS original identities, positions and definitions immutable across all 3 batches; base SQLite and asset hash unchanged
PASS initial selection and Batch-1 snapshot identical

Exit 0
```

### pytest.log

```text
....................................................................                                                          [100%]
68 passed, 19 subtests passed in 0.92s

Exit 0
```

### verify-final.log

```text
{
  "zip_verification": "PASS",
  "zip_sha256": "1e8f42dd92f8babc685d870d247d277132a07df598df83f2aee9e8139d278470",
  "hashed_files": 80,
  "sqlite_tables": 18,
  "sqlite_cards": 1744,
  "credentials_and_learning_states": "none; explicit content/source/model whitelist",
  "status": "PASS",
  "selected": 250,
  "excluded": 83,
  "batches": {
    "1": 84,
    "2": 83,
    "3": 83
  },
  "topics_per_batch": {
    "1": {
      "Obst, Gemüse und Hülsenfrüchte": 14,
      "Kochen, Backen und Küchenhandlungen": 12,
      "Gewürze, Zutaten und Würzmittel": 11,
      "Milchprodukte, Eier, Fleisch und Fisch": 11,
      "Getreide, Brot und Backwaren": 11,
      "Mahlzeiten, Geschmack und Essenssituationen": 10,
      "Getränke und Getränkezubereitung": 8,
      "Küchenutensilien, Geschirr und Aufbewahrung": 7
    },
    "2": {
      "Obst, Gemüse und Hülsenfrüchte": 13,
      "Milchprodukte, Eier, Fleisch und Fisch": 12,
      "Getreide, Brot und Backwaren": 11,
      "Kochen, Backen und Küchenhandlungen": 11,
      "Gewürze, Zutaten und Würzmittel": 11,
      "Mahlzeiten, Geschmack und Essenssituationen": 9,
      "Getränke und Getränkezubereitung": 8,
      "Küchenutensilien, Geschirr und Aufbewahrung": 8
    },
    "3": {
      "Obst, Gemüse und Hülsenfrüchte": 13,
      "Gewürze, Zutaten und Würzmittel": 12,
      "Milchprodukte, Eier, Fleisch und Fisch": 11,
      "Getreide, Brot und Backwaren": 11,
      "Kochen, Backen und Küchenhandlungen": 11,
      "Mahlzeiten, Geschmack und Essenssituationen": 9,
      "Getränke und Getränkezubereitung": 8,
      "Küchenutensilien, Geschirr und Aufbewahrung": 8
    }
  },
  "existing_senses": 19,
  "new_senses": 231,
  "existing_cards": 1744,
  "existing_groups": 1732,
  "new_groups": 250,
  "registry_words": 1890,
  "partition_selection": "PASS: 0 present",
  "validate_selection": "PASS: parent and exact reservations",
  "index_registry": "PASS",
  "validate_learning": "PASS: existing and planned",
  "build_rows": "PASS: reservation-only rows unchanged",
  "semantic_review": "explicit editorial decisions, no automatic equivalence inference"
}

Exit 0
```

## Hashes

| Datei | SHA256 roh |
|---|---|
| pipeline/out/koerper_gesundheit_batch_3_v1/pack.json | `c03047452c197a5bd4985af0faf64fb1e0614765a8a7c3f475f8c088a595f457` |
| pipeline/out/koerper_gesundheit_batch_3_v1/content.sqlite | `98aaf290c04d7f5305b607ebe9a4c5233f0a1a0eb88271acd90af37af9ffac04` |
| assets/content/en/content.sqlite | `98aaf290c04d7f5305b607ebe9a4c5233f0a1a0eb88271acd90af37af9ffac04` |
| assets/content/en/content.manifest.json | `a3c692f8662ef680e14f6285f405cb68cb74c1fa1861ac463caf458c585df3c0` |
| pipeline/data/selection/essen_trinken_v1.json | `80dfefb693085faff9776d5b9efabe4a65709d53a2d9e9b574e0c93cf9e7d239` |
| pipeline/data/selection/essen_trinken_batch_1_context_v1.json | `80dfefb693085faff9776d5b9efabe4a65709d53a2d9e9b574e0c93cf9e7d239` |
| pipeline/data/words/en.essen_trinken_batch_1_context_v1.json | `c38f22da7ca22bea64db00d1b8fd40ca2850725d9874e9d67a6b23ba9d2fc831` |
| pipeline/data/learning_groups/en.essen_trinken_batch_1_context_v1.json | `2ba4f9cb63292ff1ad301f0cb75da9118a5945f3fc692bcf7934f730e1eac381` |
| build/essen_trinken_authoring_batch_1.zip | `1e8f42dd92f8babc685d870d247d277132a07df598df83f2aee9e8139d278470` |

Registry kanonisch: `acbecaec233d49badda7f1c5b3ed5c98585fa47cdd08054795065dfad677ba1d`. Gruppen kanonisch: `15d65aeb1d16e00a3bcd197e9ea8b1b2a7e288ccce29463400cb27383e375e18`.

## Bestandsschutz und offene Punkte

2131 von 2132 vorab erfassten Dateien bleiben bytegleich; einzig NEXTSTEPS.md wurde beauftragt geändert. Neue Dateien: zwei Auswahl-Snapshots, neue Registry, neue Gruppen, dieser Bericht und die ZIP. Historische Packs, App-Assets samt Manifest, ursprüngliche Auswahlen/Registrys/Gruppen und App-/Pipeline-/Plattformcode unverändert. Baseline, Status vorher/nachher, finale Hashliste und Prüfprotokolle liegen unter build/essen_trinken_checks/.

git diff --check liefert Exit 2 wegen vorhandener CRLF-/Whitespace-Befunde; der CRLF-tolerante Check meldet dieselben sieben Altstellen: DESIGN.md:162–164, docs/alltag-zuhause-continuation.md:148/153, docs/arbeit-bildung-batch-1-import.md:127, docs/arbeit-bildung-batch-2-import.md:121. Keine globale Bereinigung. Eigene Dateien und NEXTSTEPS gegen Sicherung separat ohne Whitespace-Diagnostik geprüft (Wrapper Exit 0); git status --short: Exit 0. Große Rohoutputs sind gzip-komprimiert gespeichert.

Keine ungeklärten Bedeutungs- oder Besitzbindungen. Redaktionelle Entwürfe wurden vor der verbindlichen ZIP hinsichtlich Aliasart und Reihenfolge präzisiert; keine fehlgeschlagene Vertragsprüfung und kein gelockerter Validator. Kein Cloud-/Modellaufruf, Download, Import, Staging, Commit oder Push. Keine Flutter-Tests nötig für diese reine Vorbereitung; keine Geräteprüfung behauptet.

Nächster Schritt: ZIP im Chat zur Satzredaktion verwenden, ausschließlich die 84 aktuellen Einträge aus authoring_context.json. Später genau ein fester Satz pro Ziel, vollständige Annotation und einzeln geprüfte Alternativen. Die übrigen 166 Ziele bleiben reserviert.
