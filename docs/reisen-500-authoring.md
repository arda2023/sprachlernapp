# Reisen 500: Bedeutungsbindung und Satzvorbereitung

Stand: 04.10.2026. **500 Wörter, fünf Batches zu je 100; 144 vorhandene Senses wiederverwendet, 356 neue Senses vorgeschlagen, keine offene Zielbindung.** Vollständige lokale Besitzreservierung im bestehenden Format. Keine Reisesätze erzeugt, keine Reisen-Karten exportiert oder installiert.

## Ausgangsstand und Prüfumfang

- Eingang: `reisen_500_v1/reisen_500_v1.json`; alle 500 Positionen, Zielvorgaben, normalisierten Formen, Themen und Batchnummern unverändert übernommen.
- Basis: `pipeline/out/story_learning_v1/pack.json`, Version `story_learning_v1`, Schema 2. 264 Karten, 160 Eigentümerwörter, 1.184 Lemmas, 2.252 Senses, 2.331 Wörterbuchformen.
- Pack-Byte-SHA256: `3f35432275a8033804f04857240b67999a419a5e6017d47a78d17d968fd95bd1`.
- Kanonischer Pack-SHA256: `9703ccc9b7efeceead685f60b6ebb03f516018f8388025fa26c0aa035d1677f3`.
- Gestagtes SQLite nur lesend geöffnet: ebenfalls `story_learning_v1`, Schema 2, 264 Karten/160 Eigentümerwörter. Asset-SHA256: `b8231bbc7d1fe834b13ee81b901ad2d96dc06ac3dfbcdf72422718a68bb5e59b`.
- 375 Nomen, 75 Verben, 50 Adjektive. Sämtliche Zielbedeutungen, Lemma/POS-Bindungen und Formübersetzungen wurden gelesen und redaktionell festgelegt. Das ist keine Prüfung noch nicht vorhandener Übungssätze.
- Alle vorhandenen Senses zum jeweiligen Lemma/POS verglichen, auch solche, die nur an flektierten Wörterbuchformen hängen. Definitionen, Glossen und bis zu zwei gelesene annotierte Bestandskontexte je Kandidat sind in `build/reisen_authoring_v1/semantic_decisions.json` nachvollziehbar. Kein blindes Übernehmen des ersten Kandidaten.
- Bedeutungsinventar zusätzlich abgeglichen: Überschneidung bei `leave#verlassen` über `left`; kein abweichender Inventarschlüssel erforderlich. Aliasformen ergaben keine zusätzlichen Wörterbuchkandidaten.

## Tatsächliche Registry und Reservierung

Vorher existierten in `pipeline/data/words/` zwei Registry-Dateien. Beide einschließlich ihrer Aliaslisten geprüft; die ältere enthält keine zusätzlichen, im neueren Stand fehlenden Reservierungen.

| Datei | Version | Wörter | Kanonischer SHA256 |
|---|---|---:|---|
| `en.v1.json` | en.v1 | 160 | `6d1a767ef66708adac4d91ac189eaa1909b0d0a585b8b6974bf315b63423bf00` |
| `en.story_learning_v1.json` | en.v1 | 160 | `b4e56a318d5a13cf7f42b73e92b4b83067f18b5517ce3a7af68093311f84217d` |

Der zweite Stand ist mit dem aktuellen Pack verknüpft und wurde als Elternstand verwendet. Vorher gab es in diesen Registrys keine noch nicht exportierten Reservierungen. Dateidatum oder Versionsname allein waren nicht ausschlaggebend.

Neue Registry: `pipeline/data/words/en.reisen_500_v1.json`, Version `en.reisen_500_v1`, Format 1, Status `reserved_before_sentence_authoring`, **660 Wörter**. Erste 160 Einträge unverändert; 500 neue Einträge mit Eigentümer `reisen`, endgültiger `primary_card_ref`/`primary_card_id` und acht Schreibaliasen. Elternhash: aktueller Pack-Snapshot. Neuer kanonischer Registry-SHA256:

`888632469bbf306e85bbe42de93082362af24a37be84f6a3c82e2258581d3a90`

Der bestehende Weg unterstützt Reservierungen vor Satzproduktion: `index_registry` prüft vollständige normalisierte Besitz-/Aliasbelegung; `validate_selection(..., allow_reserved=True)` verlangt dieselbe Eigentümer- und Karten-ID; `build_rows` akzeptiert nicht exportierte Reservierungen. An einer reinen Speicherkopie des Basispacks geprüft: **alle Tabellenzeilen identisch**. Keine Platzhalterkarten, kein neuer Stapel im App-Pack, keine neue Reservierungsarchitektur.

**Geltungsgrenze:** Der CLI-Standard bleibt `en.v1.json`. Neue Reisen-Importe müssen `--registry pipeline/data/words/en.reisen_500_v1.json` ausdrücklich verwenden. Keine automatische Auswahl der neuesten Datei. Nach einem ersten Import brauchen weitere Batches einen fortgeschriebenen Registry-Elternhash und den tatsächlichen neuen Basis-Packhash; die reservierten Identitäten bleiben gleich.

`train`, `ticket`, `bus`, `station`, `table`, `bag` und `map` bleiben in `allgemeine-sprache`. Sie sind keine Reisen-Auswahlpositionen; Verwendung als Begleitwort verschiebt keinen Besitz.

## Bedeutungsentscheidungen

Jedes Wort hat genau eine Bindung mit `sense_ref`, stabilem `sense_id`, `lemma_ref`, Lemma/POS, Formübersetzung, endgültiger Karten-ID und Batch. Bestehende Senses haben `sense_key`; neue Vorschläge haben `proposed_sense_key` und eine konkrete deutsche Definition. Neue Schlüssel sind noch nicht importiert.

Nur drei der 144 wiederverwendeten Senses besitzen eine gespeicherte Definition (`licence`, `café`, `backpack`). Bei den anderen 141 bleiben `definition_de=null` und `definition_status=existing_unmodified`. Bindungsentscheidungen beruhen dort auf gelesenen Glossen und Bestandskontexten, nicht auf erfundenen alten Definitionen. Keine Bestandsglossen oder Definitionen überschrieben.

| Fall | Entscheidung |
|---|---|
| backpack | `backpack/NOUN\|backpack#rucksack` samt Definition und stabiler Story-Kartenidentität erhalten. |
| platform | `platform/NOUN\|platform#bahnsteig` aus der Story erhalten, nicht `platform#gleis`. Auch beim Bahnsteig fehlt eine gespeicherte Definition. |
| licence | `licence#erlaubnis`: Definition und vorhandener driving-licence-Kontext decken Fahrerlaubnis ab. Keine neue Bedeutung wegen präziserer Übersetzung. |
| tablet | `tablet#tablette`: Medikament im Kopfschmerz-Kontext; kein Gerät. |
| subway / pavement | Neue Definitionen ausdrücklich US-U-Bahn bzw. UK-Gehweg; keine Fußgängerunterführung bzw. Fahrbahnbelag. |
| document, announcement, coin, cloud, emergency, symptom | Vorhandene Senses mit pluralischen Glossen wiederverwendet; Singularübersetzungen nur an der neuen Kartenplanung. |
| book, prepare, cross, deliver | Bedeutung trotz flektierter Bestandsglosse erhalten; keine neuen Senses allein für die Grundform. |
| tour / laundry | Je ein erlaubter Zielgebrauch: Besichtigung bzw. Wäsche/Reinigung; keine zusätzliche Tournee- oder Betriebsbedeutung. |
| cough | `cough/NOUN\|cough#husten` für das Symptom wiederverwendet. Kleingeschriebene alte Glosse und Verbtoken in „Did Rosa cough from the spicy pepper in her soup?“ sind ein POS-Annotationsfehler, kein gültiger Nomenbeleg. Neuer Satz muss das Nomen verwenden; Altbestand bleibt unverändert. |
| ice | Gefrorenes Wasser, belegt durch den Ausrutsch-Kontext. Ein anderer alter ice-cream-Kontext erlaubt keine Speiseeis-Nebenbedeutung. |

Zwölf Wörter haben gleichlautende Lemma/POS-Kandidaten, deren gelesener Gebrauch nicht die ausgewählte Bedeutung belegt. Abgrenzung nach Inhalt, nicht bloß deutscher Glossenform:

| Wort | Vorhandener Gebrauch | Neuer vorgeschlagener Schlüssel |
|---|---|---|
| package | versandtes Paket | `package#pauschalreiseangebot` |
| stamp | Briefmarke | `stamp#stempelabdruck` |
| gate | Grundstückstor | `gate#flugsteig` |
| service | Restaurantbedienung | `service#verkehrsverbindung` |
| course | Unterrichtskurs | `course#menuegang` |
| return | Gegenstand zurückgeben | `return#zurueckkehren` |
| fly | eigenständiger Vogelflug | `fly#flugreise` als Reisender im Luftfahrzeug |
| ride | selbst Fahrrad fahren | `ride#mitfahren` als Fahrgast |
| answer | Telefonanruf annehmen | `answer#antworten` auf eine sprachliche Frage |
| turn | ausschalten | `turn#abbiegen` |
| central | funktional Haupt- im Hauptbahnhof | `central#zentral-gelegen` für räumliche Zentrumsnähe |
| deep | intensiv Luft holen | `deep#gewaessertiefe` für räumliche Wassertiefe |

Pluralformen unverändert: `chopsticks → chopstick`, `ruins → ruin`, `toiletries → toiletry`, mit Formkind `plural` und Pluralübersetzung. `customs`, `crossroads` und `police` nicht mechanisch singularisiert; `police` als Sammelbegriff mit Pluralkongruenz gekennzeichnet. Synonyme wie backpack/rucksack bleiben verschiedene ausgewählte Wörter, keine Besitzaliase.

Alle acht Vorschläge sind im festgelegten Sinn Schreibvarianten: traveller/traveler, aeroplane/airplane, takeoff/take-off, kerb/curb, licence/license (Nomen), café/cafe, harbour/harbor und theatre/theater. Null Kollisionen untereinander oder mit dem Bestand. **Nur Besitzaliase:** `accepted` muss exakt `[form]` sein; `valid_alternatives` erfordert später eine konkrete Einsetzprüfung.

## Format und Austausch

- Auswahl: `pipeline/data/selection/reisen_500_v1.json`, bestehende Version-1-Entries-Struktur plus explizite Identitäts-/Reservierungsfelder.
- Der alte `plan_selection`-Generierungseinstieg fordert ausschließlich Grundformen und zusätzliche Generierungsfelder. Er ist für diese gemischte Formauswahl nicht der Importweg. Keine Ersetzung der Pluralwörter, keine Pipeline-Codeänderung. Genutzt: bestehende allgemeine Auswahl-/Registry-Prüfungen und Offline-Create-Vertrag.
- Austausch: `build/reisen_authoring_v1/authoring_context.json`, Schema, unveränderte Create-Fixture samt eigener Basis/Registry, Wörterbuchkatalog, Entscheidungsprotokoll, Registry-Kopie, Prüfskript/-output und README mit Windows-/macOS-Importbefehlen.
- ZIP: `build/reisen_authoring_v1.zip`. Ausschließlich ausdrücklich aufgelistete Text-/JSON-/Python-Dateien; keine SQLite-Datei, Lernstände, Credentials oder Binärartefakte. `manifest.json` bindet die Austauschdateien an Byte-Hashes.
- Batch 1 braucht keine neue Identitäts- oder Formatplanung. Satzredaktion, Übersetzungen, Tokenbezüge, Reviews, inhaltliches CEFR-Band und alternative Lückenantworten stehen noch aus. Keine vorgetäuschte Satzfreigabe.

## Lokale Verifikation

Aus dem Repository, Windows / PowerShell:

```powershell
.\pipeline\.venv\Scripts\python.exe -X utf8 build/reisen_authoring_v1/verify.py --repo .
```

macOS / Terminal:

```sh
pipeline/.venv/bin/python build/reisen_authoring_v1/verify.py --repo .
```

Bestehende Validatoren: `word_registry.index_registry`, `word_registry.validate_selection` vor/nach Reservierung, `selection.partition_selection`, `pack.build_rows`, `import_editorial_patch.create_content` für die unveränderte synthetische Fixture. Keine vollständigen Testsuiten; keine Produkt-Codeänderungen.

Prüfausgang:

```text
PASS: 500 original targets; batches 1..5 = 100 each; all stable IDs recomputed
PASS: 144 existing / 356 proposed / 0 open senses; existing glosses and definitions unchanged
PASS: ownership and aliases; 160 existing + 500 reserved = 660 words, 8 new spelling aliases
PASS: partition_selection present=0 missing=500; no travel cards exported
PASS: build_rows accepts future reservations; all base pack rows identical
PASS: existing Create fixture -> 1 card / 1 sentence / 3 tokens; schema and fixture byte-identical
```

Git-Abschlussprüfung (Windows/macOS identisch): `git diff --check`, `git diff --stat`, `git status --short`. Bereits bestehende Paket-A/B-Änderungen sind Ausgangszustand; der gesamte Git-Diff ist nicht dieser Datenvorbereitung zuzurechnen. Diese Aufgabe ergänzt Auswahl, Registry und Bericht sowie Austauschdateien im ignorierten `build/`; aktualisiert wird außerdem `NEXTSTEPS.md`. Keine Änderungen an App-Code, Content-Asset, alten out-Artefakten oder Lernständen.

Abschlussausgabe: `git diff --check` ohne Whitespace-Befund; Git meldet nur bestehende LF/CRLF-Hinweise. Gesamt-Diff einschließlich Paket A/B: 62 Dateien, 4.205 Einfügungen, 356 Löschungen; neue ungetrackte Daten-/Berichtsdateien sind darin nicht enthalten und wurden mit `git status --short` ausgewiesen. Hashvergleich: 592 geschützte Ausgangsdateien unverändert. `NEXTSTEPS.md`: 24 Zeilen. ZIP: 12 Dateien, 305.248 Bytes; CRC-Prüfung erfolgreich. ZIP-SHA256: `d30220887b6a170a5c98f3768c6468cb2e3a8aad0e9b77419ae09b20742535ee`.

**Nächster gebündelter Schritt:** Im Chat die 100 Sätze für `authoring_batch=1` anhand dieses ZIP redigieren und als vollständiges Editorial-Create-v2-Delta liefern; danach lokal gegen die angegebenen Hashes und Reservierungen prüfen. Noch kein Import oder Packwechsel.


## Präzisierung der Positionen für Teilbatches

Nach ausdrücklicher Freigabe bleiben Auswahl- und Registry-Originalpositionen
unverändert. Die Pack-Anzeigeposition wird ausschließlich aus den tatsächlich
enthaltenen Reisen-Karten durch Sortieren nach Originalposition und Nummerieren
ab 1 abgeleitet. Batch 1 enthält die Originalpositionen 1–5,26–30,...476–480,
nicht die ersten 100 IDs; nur cafe → café gehört als Alias dazu.
Für folgende Batches werden alle dann enthaltenen Reisen-Karten gemeinsam
geordnet. Nur deren Anzeigepositionen dürfen sich verschieben; andere Stapel,
IDs, Besitz und Lernstände bleiben unverändert. Der Packvertrag 1..n bleibt bestehen.
Das Mapping und die 100-/200-Positionsprüfung liegen unter build/reisen_batch_1_checks/.
Der bestehende Create-Importer setzt Registry-Originalpositionen nicht mit der
Anzeige gleich und benötigt für Batch 1 keine Produktionscodeänderung. Eine spätere
Lieferung muss die gemeinsame Neupositionierung bestehender Reisen-Zeilen ausdrücklich
berücksichtigen; bloßes Anhängen eines weiteren unveränderten 100er-Deltas reicht nicht.
