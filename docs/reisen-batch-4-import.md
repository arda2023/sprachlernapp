# Reisen Batch 4 – Offline-Import und Batch-5-Kontext

Stand: 06.10.2026. `reisen_batch_4_v1`, Content-Schema 2, intern gestagt und geprüft. Keine öffentliche Inhaltsfreigabe.

## Inhaltliche Abnahme

Alle 100 englisch-deutschen Satzpaare gegen Zielbedeutung und Wortart gelesen, sämtliche 982 Tokenbindungen sowie alle 150 neuen Formglossen geprüft. Alle fünf Alternativen wörtlich in dieselbe Lücke eingesetzt, einschließlich Artikel und Satzanschluss. Kein zusätzlicher konkreter Lieferfehler festgestellt; keine redaktionellen Korrekturen vorgenommen. Create und Display-Patch sind bytegleiche versionierte Kopien der Lieferung. Originaldateien und beide Originalmanifeste bleiben unverändert. Keine Neugenerierung und keine unabhängige menschliche Freigabe behauptet.

Die 51 neuen Begleitwort-Senses wurden mit bestehenden Lemmas/Senses, deren Satzbelegen und den fünf Besitz-/Schreibaliasen abgeglichen. Keine erneut gelieferten redundanten need/make/for/see/cafe-Senses aus Batch 3. `cover#kosten_decken` unterscheidet sich vom physischen Bedecken; `run#betrieben_werden` von Rennen, Verkehren, Unternehmensbetrieb und Wegverlauf; `hold#veranstalten` vom Festhalten und Fassungsvermögen; `lead#strecke_fuehren` vom Begleiten von Personen. `feel like` bezeichnet Lust auf eine Tätigkeit, nicht Empfindung oder Ähnlichkeit. `inside#drinnen` bezeichnet einen Ort, bestehendes `inside#hinein` eine Bewegung. Neue Bedeutungen werden nicht allein aus anders formulierten Glossen abgeleitet.

Ausdrücklich erhalten: Ziel `nearby#nahe-gelegen` überschneidet sich mit Begleitwort `nearby#nahe_gelegen`. Keine Sense-/Karten-ID-Zusammenlegung. Neuer `lower/VERB|lower#hinunterlassen` ist grammatisch korrekt; der historische `lower/ADJ|lower#senke-dreh-herunter` in „Luca, lower the amplifier volume, or the neighbors will complain!“ bleibt als bekannter Altfehler unangetastet.

Besonders geprüft: What in duration/cost ist Fragepronomen; stops in express bezeichnet Zwischenhalte/Aufenthalte; warm in mug ist Verb (neue Formglosse „wärme“); inside/outside in warning/fire sind Adverbien; to in fly kommt getrennt als Infinitivpartikel und Richtungspräposition vor. Neue flektierte Formglossen u. a. covers „deckt ab“, costs „kostet“, kept „hielt“, woke „weckte“, nuts „Nüsse“, fields „Felder“ sind formbezogen. Historische kurze/flektierte Sense-Schlüssel werden nicht global umgeschrieben.

### Alternativen

| Satz | Alternative | Wörtlicher Ersatzsatz | Ergebnis |
|---|---|---|---|
| reisen-v1-041-s1 | expiration | Check the expiration date on your passport before booking. | Grammatik, Bedeutung, Zeit und Perspektive erhalten. |
| reisen-v1-116-s1 | gasoline | This car runs on gasoline, not diesel. | Grammatik, Bedeutung, Zeit und Perspektive erhalten. |
| reisen-v1-343-s1 | stomach ache | I have a stomach ache and do not feel like eating. | Grammatik, Bedeutung, Zeit und Perspektive erhalten. |
| reisen-v1-441-s1 | phone | Please phone the hotel to confirm our booking. | Grammatik, Bedeutung, Zeit und Perspektive erhalten. |
| reisen-v1-493-s1 | uncooked | This salad contains uncooked carrots and cucumber. | Grammatik, Bedeutung, Zeit und Perspektive erhalten. |

## Technische Abnahme

Liefer- und Referenzmanifest vollständig geprüft. Originalverifier und unveränderter Verifier im Arbeitskopienordner jeweils mit `--repo .` erfolgreich; die Arbeitskopien sind bytegleich zu den tatsächlich importierten Curation-Dateien. Echte Projektfunktionen create_content, build_rows, stable_id, deck_display, Tokenizer und Linter verwendet, keine Stubs und kein Cloud-Annotator.

```text
PASS supplied JSON Schema (strict standard-library adapter)
PASS 100 sentences, 982 tokens, 6-12 words; 100 review hashes
PASS actual tokenizer and linter: 0 errors, 26 frequency warnings
PASS literal reviewed alternatives: 5
PASS in-memory 400-word display mapping; all other data unchanged
PASS current project create_content, stable IDs, display patch and build_rows: 664 cards / 1198 texts / 1192 links / 560 primary words
PASS delivery file hashes
```

Importstatus ok, internal_test_pack=true, ai_calls=0, ai_cost_usd=0. Vollpack-Linter: 0 Fehler, 226 Häufigkeitswarnungen = 200 bestehende + 26 neue. Keine Unterdrückung; Einzelbefunde in `pipeline/out/reisen_batch_4_v1/finalization_report.json`, Lieferbefunde in `reisen_batch_4/linter_findings.json`.

Neuer Ausgabeordner war vor Import nicht vorhanden. Kein Zwischenexport der Append-Reihenfolge: der vorhandene --display-patch-Pfad wendet vor dem einzigen Export das vollständige Mapping an. Alle 400 Positionen entsprechen `reisen_batch_4/reference/combined_display_mapping.json`, lückenlos 1–400; 285 alte Positionen pro Mitgliedschaftstabelle verschoben. Ausschließlich position in deck_cards/deck_words verändert. Alle alten Tabellenzeilen, IDs, Texte, Token, Reviews und historischen Links erhalten, ausgenommen erlaubte Positionen und Release-Metadaten. Alle 500 reservierten Identitäten, Besitz-/Aliasregeln und Originalpositionen abgeglichen.

JSON entspricht dem echten Create-/Display-Ergebnis. Neu read-only geöffnete SQLite: integrity_check=ok, foreign_key_check leer; alle Spalten aller 18 Tabellen mit build_rows abgeglichen. Alle neuen Wörter genau einmal primär mit je einem festen Satz, Allgemeine Sprache unverändert 160, Reisen 400. Sechs Story-Sätze und sämtliche historischen Karten-Satz-Verknüpfungen erhalten.

Tatsächliches `created_at`: `2026-10-06T16:39:48.551912+00:00`; bei Readback gegen Systemzeit geprüft.

| Tabelle | Zeilen |
|---|---:|
| languages | 1 |
| lemmas | 1636 |
| senses | 2770 |
| cards | 664 |
| dictionary_forms | 2982 |
| decks | 2 |
| deck_cards | 664 |
| deck_words | 560 |
| word_aliases | 5 |
| sentences | 1198 |
| sentence_tokens | 12516 |
| card_sentences | 1192 |
| stories | 1 |
| story_sentences | 6 |
| exercises | 0 |
| grammar_rules | 0 |
| audio_assets | 0 |
| content_releases | 1 |

## Ausgeführte Befehle und Exitcodes

Windows PowerShell, Repository-Root; alle nachfolgenden Befehle Exit 0, keine fehlgeschlagenen Import-/Prüfversuche:

```powershell
$env:PYTHONPATH = 'pipeline/src'
.\pipeline\.venv\Scripts\python.exe -X utf8 reisen_batch_4/verify_reisen_batch_4.py --repo .
.\pipeline\.venv\Scripts\python.exe -X utf8 build/reisen_batch_4_checks/verified_working_delivery/verify_reisen_batch_4.py --repo .
.\pipeline\.venv\Scripts\python.exe -X utf8 pipeline/scripts/import_editorial_patch.py --source pipeline/out/reisen_batch_3_v1/pack.json --create pipeline/data/curation/reisen_batch_4.editorial.json --registry pipeline/data/words/en.reisen_batch_4_v1.json --display-patch pipeline/data/curation/reisen_batch_4_display_v1.json --out pipeline/out/reisen_batch_4_v1
.\pipeline\.venv\Scripts\python.exe -X utf8 build/reisen_batch_4_checks/check_export.py
.\pipeline\.venv\Scripts\python.exe -X utf8 build/reisen_batch_4_checks/prepare_batch_5.py
.\pipeline\.venv\Scripts\python.exe -X utf8 build/reisen_batch_4_checks/finish_report.py
```

macOS Terminal (hier nicht ausgeführt): dieselben Python-Dateien/Argumente mit `PYTHONPATH=pipeline/src pipeline/.venv/bin/python -X utf8` statt der Windows-Umgebungszuweisung und des Windows-Interpreters. Export-, Backup- und Vorbereitungsskripte verweigern vorhandene Ziele; nicht blind wiederholen.

Beide Systeme, hier unter Windows nach erfolgreicher SQLite-Abnahme und Sicherung ausgeführt, jeweils Exit 0:

```text
dart run tool/stage_content_pack.dart --from pipeline/out/reisen_batch_4_v1
dart run tool/stage_content_pack.dart --verify
flutter test test/data/real_pack_test.dart
flutter analyze
```

```text
staged / verified assets/content/en/content.sqlite
version reisen_batch_4_v1, schema 2, 6029312 bytes
18 table counts match finalization_report.json
deck allgemeine-sprache: 160 primary cards, 160 fixed sentence assignments verified
deck reisen: 400 primary cards, 400 fixed sentence assignments verified
All tests passed!
No issues found! (ran in 2.1s)
```

Der bestehende Lesetest wurde ausschließlich von Reisen-Anzahl 300 auf 400 angepasst. Keine Pipeline-Implementierungsänderung; keine neue duplizierende Testsuite. Wiederverwendete lokale Abnahmehelfer aus Batch 3 prüfen den konkreten Export und das ZIP.

## Sicherung und Hashbindungen

Beide Assets vor Staging im neuen `build/reisen_batch_4_checks/asset_backup/` gesichert und bytegeprüft; `hashes.json` protokolliert die Werte. Keine Wiederherstellung nötig.

| Gesichertes Asset | SHA256 |
|---|---|
| content.sqlite | 621f2d849074c9d8f1408fbccf42cf6558e13adb0ddcd4ee66cfe7390bd0baf9 |
| content.manifest.json | a931b9b384dd9dff3184815635daac647a1eac2e5cd45322e0a7f31e7a4d70eb |

| Datei (Rohbytes) | SHA256 |
|---|---|
| pipeline/out/reisen_batch_3_v1/pack.json | 27d2ef97c9a188e7313cdb7e12b84336f37266f0cca865d1a5c836a4dc17251f |
| pipeline/data/curation/reisen_batch_4.editorial.json | 71da79069c88bb25be5455a4100a384a52f2a39fb2f58cae6c9144d7ff73a89f |
| pipeline/data/curation/reisen_batch_4_display_v1.json | 9141179a16d61c132d4988afa53fdf6f7af7dcb118af26d471b22aa3ff32d408 |
| pipeline/out/reisen_batch_4_v1/pack.json | 97015c3c12b9f5e2fb2d900ee9544029189e1f51a3741c1a9100f206dcf5b4d3 |
| pipeline/out/reisen_batch_4_v1/content.sqlite | fc04b23eed0150e34690fc06eec7c8518bbfc85739b505d18c0d1792083040f4 |
| assets/content/en/content.manifest.json | 83083f9592fc8029e015d84e88eefbdc8f25ba8b86130bb1d1cb5225fcb94173 |
| build/reisen_authoring_batch_5.zip | 2790a292405eee6bd993452fa19ce4b456d81a63e709f05a7122f37e9f9cfdd8 |
| lib/main.dart | c7e54ec1834b4dd18c592d32a310fae25394b6e2a48307fb3162de16e9eb4edd |

Batch-4-Registry kanonisch: `8f1e9307f30639616ba4e1ac757b7e1f5eeeeb72aa1c2c75ec13d791ba3edb33`. Batch-5-Registry kanonisch: `4148c720b983fe66c01683db760208c7b85cb0a59f98bb5a40ae7d049198f2b4`.

Before-Hashes (Append-Zustand im Speicher): deck_cards `f2ad22a66942bf8c2f347fcaed72b4d8c575c1458c90af44b75aab4e9b345289`, deck_words `d7835dfe05e2e95adb3c0f5df64909a14cb9df6d1ec3b8f45eb02df6accfb5c4`. Create-Rohbytehash, Source-Rohbytehash, Registryhash und alle 100 Token-/Linkreview-Hashes gegen importierte Bytes geprüft. Historische source_sqlite_sha256-Metadaten unverändert.

## Batch 5 und Erhalt

`build/reisen_authoring_batch_5/` und `build/reisen_authoring_batch_5.zip`: genau authoring_batch=5, nicht IDs 401–500. 100 unveränderte Zielidentitäten/Glossen/Definitionen, 31 vorhandene und 69 vorgeschlagene Ziel-Senses. Neu als vorhanden erkannt: traveller, trolley, junction, payment, souvenir, hike, sunset, rent. Historische Auswahlbegründungen bleiben erhalten; den aktuellen Existenzstatus geben sense_source/lemma_status und das Wörterbuch des neuen Packs an.

Enthalten: tatsächlicher Batch-4-Pack, aktueller Wörterbuchkontext, neue Registry samt 660 unveränderten Besitzzeilen/Aliassen, alle 500 Identitäten, vollständiges finales 500er-Mapping, aktuelles Create-v2-Schema, echte annotate.py/linter.py/deck_display.py, Tokenizerumgebung, README, Validierung und Hashmanifest. Modellbinaries sind wie beim bisherigen Kontextverfahren nicht im ZIP; spaCy 3.8.16 und en_core_web_sm 3.8.0 sind in der vorhandenen Pipelineumgebung verfügbar. Keine Batch-5-Sätze erstellt.

ZIP separat erneut geöffnet: exakt 14 erlaubte Dateien, CRC und alle 13 Manifest-Dateihashes geprüft; Zieldefinitionen gegen Auswahl, Pack/Registry/Code gegen aktuelle Projektbytes, Wörterbuch gegen neuen Pack und sämtliche Mappingpositionen unabhängig abgeglichen. Keine Zugangsdaten oder Lernstände aufgenommen. Registry en.reisen_batch_5_v1 bindet über source_pack_sha256 an den neuen Pack und über parent_sha256 an dessen tatsächlichen Snapshot; alte Registrys unverändert.

Baseline: 708 vorhandene Dateien; alle außer autorisierten Assets, NEXTSTEPS und Lesetest unverändert. Normaler App-Einstieg lib/main.dart unverändert (Hash oben); keine Änderung an lib/, UI, SRS, Antwortlogik, Modellen, Limits, Backend/Migrationen oder bisherigen out-Packs. Bestehende Arbeitsbaumänderungen erhalten. Kein Zugriff auf user.db, keine Emulator-/iOS-/Android-Tests, keine Commits/Pushes, keine Cloud-/Vertex-/Gemini-Aufrufe. Redaktionelle Prüfung betrifft die 100 neuen Sätze; Altbestand technisch auf Erhalt geprüft, nicht vollständig neu redigiert.

Keine offenen technischen Blocker. Nächster Schritt: Batch 5 anhand des geprüften Kontext-ZIP redigieren und anschließend Create plus 500er-Display-Patch gemeinsam offline prüfen/importieren.

## Vollständige Satzpaar-Leseliste

Alle Paare und die jeweils vollständigen Wortbindungen aus `reisen_batch_4/annotation_review.txt` gelesen; keine Stichprobe. Die unveränderten Create-Reviews binden Text, Übersetzung, Token und Links kryptografisch. Für alle Zeilen: Zielbedeutung/Wortart/Übersetzung und Bindungen geprüft, kein zusätzlicher Korrekturbefund; erlaubte nearby-Überschneidung siehe oben.

| Satz-ID | Englisch | Deutsch |
|---|---|---|
| reisen-v1-016-s1 | What is the duration of the boat trip? | Wie lange dauert die Bootsfahrt? |
| reisen-v1-017-s1 | Our budget covers the flights, hotel and meals. | Unser Reisebudget deckt die Flüge, das Hotel und die Mahlzeiten ab. |
| reisen-v1-018-s1 | This holiday package includes flights and seven nights at a hotel. | Dieses Pauschalreiseangebot umfasst Flüge und sieben Übernachtungen in einem Hotel. |
| reisen-v1-019-s1 | The travel agency booked our flights and hotel. | Die Reiseagentur hat unsere Flüge und unser Hotel gebucht. |
| reisen-v1-020-s1 | Our travel agent found a cheaper flight for us. | Unser Reisevermittler hat einen günstigeren Flug für uns gefunden. |
| reisen-v1-041-s1 | Check the expiry date on your passport before booking. | Prüfe vor der Buchung das Ablaufdatum in deinem Reisepass. |
| reisen-v1-042-s1 | The official checks the validity of my passport. | Die Amtsperson prüft, ob mein Reisepass gültig ist. |
| reisen-v1-043-s1 | Please bring a photocopy of your passport to the appointment. | Bitte bring eine Fotokopie deines Reisepasses zum Termin mit. |
| reisen-v1-044-s1 | A valid passport is a requirement for this journey. | Ein gültiger Reisepass ist für diese Reise erforderlich. |
| reisen-v1-045-s1 | Please list these goods on your customs declaration. | Bitte führe diese Waren in deiner Zollerklärung auf. |
| reisen-v1-066-s1 | We planned a two-day stopover to explore the city. | Wir haben einen zweitägigen Zwischenaufenthalt geplant, um die Stadt zu erkunden. |
| reisen-v1-067-s1 | Our first flight was late, so we missed our connection. | Unser erster Flug war verspätet, deshalb haben wir unseren Anschluss verpasst. |
| reisen-v1-068-s1 | The hotel provides a free transfer from the airport. | Das Hotel bietet einen kostenlosen Transfer vom Flughafen an. |
| reisen-v1-069-s1 | We felt some turbulence during the flight over the mountains. | Beim Flug über die Berge haben wir Turbulenzen gespürt. |
| reisen-v1-070-s1 | The screen shows a delay of twenty minutes for our train. | Die Anzeige meldet für unseren Zug zwanzig Minuten Verspätung. |
| reisen-v1-091-s1 | The car waits at the railway crossing while a train passes. | Das Auto wartet am Bahnübergang, während ein Zug vorbeifährt. |
| reisen-v1-092-s1 | Workers are repairing the track, so our train must wait. | Arbeiter reparieren gerade das Gleis, deshalb muss unser Zug warten. |
| reisen-v1-093-s1 | This bus route connects the station with the beach. | Diese Buslinie verbindet den Bahnhof mit dem Strand. |
| reisen-v1-094-s1 | There is a regular bus service between the airport and the city. | Zwischen dem Flughafen und der Stadt gibt es eine regelmäßige Busverbindung. |
| reisen-v1-095-s1 | The morning express reaches the city without any stops. | Der morgendliche Expresszug erreicht die Stadt ohne Zwischenhalt. |
| reisen-v1-116-s1 | This car runs on petrol, not diesel. | Dieses Auto fährt mit Benzin, nicht mit Diesel. |
| reisen-v1-117-s1 | Please fill the tank with diesel. | Bitte fülle den Tank mit Diesel. |
| reisen-v1-118-s1 | We need more fuel before the long drive across the desert. | Vor der langen Fahrt durch die Wüste brauchen wir mehr Kraftstoff. |
| reisen-v1-119-s1 | The mechanic at the garage is repairing our car. | Der Mechaniker in der Autowerkstatt repariert unser Auto. |
| reisen-v1-120-s1 | Bicycle rental costs ten euros per day. | Ein Fahrrad zu mieten kostet zehn Euro pro Tag. |
| reisen-v1-141-s1 | We have breakfast on the hotel terrace every morning. | Wir frühstücken jeden Morgen auf der Hotelterrasse. |
| reisen-v1-142-s1 | Our apartment has a bedroom with two single beds. | Unsere Wohnung hat ein Schlafzimmer mit zwei Einzelbetten. |
| reisen-v1-143-s1 | There are clean towels in the bathroom. | Im Badezimmer liegen saubere Handtücher. |
| reisen-v1-144-s1 | The shower in our room has no hot water. | Aus der Dusche in unserem Zimmer kommt kein warmes Wasser. |
| reisen-v1-145-s1 | The toilet in our room does not flush. | Die Toilettenspülung in unserem Zimmer funktioniert nicht. |
| reisen-v1-166-s1 | I would like a smaller portion of rice, please. | Ich hätte bitte gern eine kleinere Portion Reis. |
| reisen-v1-167-s1 | Can you recommend a local dish without meat? | Kannst du ein Gericht aus der Region ohne Fleisch empfehlen? |
| reisen-v1-168-s1 | The waiter brings our soup in a large bowl. | Der Kellner bringt unsere Suppe in einer großen Schüssel. |
| reisen-v1-169-s1 | Could I have a glass of water, please? | Könnte ich bitte ein Glas Wasser bekommen? |
| reisen-v1-170-s1 | I warm my hands around a mug of tea. | Ich wärme meine Hände an einem Becher Tee. |
| reisen-v1-191-s1 | The grilled fish comes with rice and a salad. | Zum gegrillten Fisch gibt es Reis und einen Salat. |
| reisen-v1-192-s1 | This restaurant serves fresh seafood from the nearby harbour. | Dieses Restaurant serviert frische Meeresfrüchte aus dem nahe gelegenen Hafen. |
| reisen-v1-193-s1 | Which vegetable would you like with your fish? | Welches Gemüse möchtest du zu deinem Fisch? |
| reisen-v1-194-s1 | We bought some fresh fruit at the market. | Wir haben auf dem Markt frisches Obst gekauft. |
| reisen-v1-195-s1 | I baked a potato for dinner. | Ich habe zum Abendessen eine Kartoffel gebacken. |
| reisen-v1-216-s1 | Does the bus fare include the journey back? | Ist die Rückfahrt im Busfahrpreis enthalten? |
| reisen-v1-217-s1 | The museum charges an entry fee of five euros. | Das Museum verlangt fünf Euro Eintritt. |
| reisen-v1-218-s1 | There is an extra charge for breakfast at this hotel. | In diesem Hotel kostet das Frühstück extra. |
| reisen-v1-219-s1 | What is the cost of a taxi to the airport? | Wie viel kostet ein Taxi zum Flughafen? |
| reisen-v1-220-s1 | Please check the total on the bill before you pay. | Bitte prüfe vor dem Bezahlen den Gesamtbetrag auf der Rechnung. |
| reisen-v1-241-s1 | We walked through the gardens around the Buddhist temple. | Wir sind durch die Gärten rund um den buddhistischen Tempel spaziert. |
| reisen-v1-242-s1 | The guide explains the history of this mosque. | Der Reiseleiter erklärt die Geschichte dieser Moschee. |
| reisen-v1-243-s1 | We buy bread and cheese at the local market. | Wir kaufen Brot und Käse auf dem örtlichen Markt. |
| reisen-v1-244-s1 | The town holds a music festival every summer. | Die Stadt veranstaltet jeden Sommer ein Musikfestival. |
| reisen-v1-245-s1 | The museum has an exhibition of old travel photos. | Im Museum gibt es eine Ausstellung mit alten Reisefotografien. |
| reisen-v1-266-s1 | We watched the wildlife from a safe distance. | Wir haben die Wildtiere aus sicherer Entfernung beobachtet. |
| reisen-v1-267-s1 | We stopped several times to enjoy the mountain scenery. | Wir haben mehrmals angehalten, um die Berglandschaft zu genießen. |
| reisen-v1-268-s1 | Small farms and fields shape the rural landscape. | Kleine Bauernhöfe und Felder prägen die ländliche Landschaft. |
| reisen-v1-269-s1 | A narrow path leads from the village to the beach. | Ein schmaler Fußweg führt vom Dorf zum Strand. |
| reisen-v1-270-s1 | This hiking trail goes through the forest to a waterfall. | Dieser Wanderpfad führt durch den Wald zu einem Wasserfall. |
| reisen-v1-291-s1 | A cool breeze comes through the open window. | Eine kühle Brise weht durch das offene Fenster. |
| reisen-v1-292-s1 | The storm forced all the fishing boats back into the harbour. | Der Sturm zwang alle Fischerboote zurück in den Hafen. |
| reisen-v1-293-s1 | We heard loud thunder during the night. | In der Nacht haben wir lauten Donner gehört. |
| reisen-v1-294-s1 | A flash of lightning lit up the mountains. | Ein Blitz erhellte die Berge. |
| reisen-v1-295-s1 | A dark cloud is moving across the sky. | Eine dunkle Wolke zieht über den Himmel. |
| reisen-v1-316-s1 | We rented an open canoe for a trip along the river. | Wir haben für eine Fahrt auf dem Fluss ein offenes Kanu gemietet. |
| reisen-v1-317-s1 | I paddle my kayak across the calm lake. | Ich paddle mit meinem Kajak über den ruhigen See. |
| reisen-v1-318-s1 | Please hold your paddle firmly with both hands. | Bitte halte dein Paddel mit beiden Händen gut fest. |
| reisen-v1-319-s1 | The wind fills the sail and moves the boat forward. | Der Wind füllt das Segel und treibt das Boot vorwärts. |
| reisen-v1-320-s1 | The crew lowers the anchor near the island. | Die Besatzung lässt in der Nähe der Insel den Anker hinunter. |
| reisen-v1-341-s1 | This cough kept me awake all night. | Dieser Husten hat mich die ganze Nacht wach gehalten. |
| reisen-v1-342-s1 | I have a headache and need a quiet room. | Ich habe Kopfschmerzen und brauche ein ruhiges Zimmer. |
| reisen-v1-343-s1 | I have a stomachache and do not feel like eating. | Ich habe Bauchschmerzen und keine Lust zu essen. |
| reisen-v1-344-s1 | Please tell the waiter about your allergy to nuts. | Bitte sag dem Kellner, dass du eine Nussallergie hast. |
| reisen-v1-345-s1 | I keep my medicine in my hand luggage. | Ich bewahre mein Medikament im Handgepäck auf. |
| reisen-v1-366-s1 | The sign warns of danger near the edge of the cliff. | Das Schild warnt vor Gefahr nahe am Rand der Klippe. |
| reisen-v1-367-s1 | We stayed inside after the storm warning. | Nach der Sturmwarnung sind wir drinnen geblieben. |
| reisen-v1-368-s1 | The fire alarm woke everyone in the hotel. | Der Feueralarm hat alle im Hotel geweckt. |
| reisen-v1-369-s1 | A fire in the hotel kitchen forced everyone outside. | Ein Brand in der Hotelküche zwang alle nach draußen. |
| reisen-v1-370-s1 | The hotel staff organised an evacuation after the fire alarm. | Nach dem Feueralarm organisierte das Hotelpersonal eine Evakuierung. |
| reisen-v1-391-s1 | We hope to reach the campsite before dark. | Wir hoffen, den Campingplatz noch vor Einbruch der Dunkelheit zu erreichen. |
| reisen-v1-392-s1 | Please show your ticket before you enter the museum. | Bitte zeige deine Eintrittskarte, bevor du das Museum betrittst. |
| reisen-v1-393-s1 | We can board the ferry after the cars. | Wir können nach den Autos an Bord der Fähre gehen. |
| reisen-v1-394-s1 | Our plane will land in about twenty minutes. | Unser Flugzeug wird in etwa zwanzig Minuten landen. |
| reisen-v1-395-s1 | We plan to fly to Rome next spring. | Wir wollen nächsten Frühling nach Rom fliegen. |
| reisen-v1-416-s1 | You can request a room with a balcony. | Du kannst um ein Zimmer mit Balkon bitten. |
| reisen-v1-417-s1 | Can we order some water before choosing our food? | Können wir vor der Essensauswahl schon Wasser bestellen? |
| reisen-v1-418-s1 | Does the hotel offer a free airport transfer? | Bietet das Hotel einen kostenlosen Flughafentransfer an? |
| reisen-v1-419-s1 | Do you accept payment by card? | Akzeptieren Sie Kartenzahlung? |
| reisen-v1-420-s1 | You can refuse the upgrade and keep your original booking. | Du kannst das Upgrade ablehnen und deine ursprüngliche Buchung behalten. |
| reisen-v1-441-s1 | Please call the hotel to confirm our booking. | Bitte ruf im Hotel an, um unsere Buchung zu bestätigen. |
| reisen-v1-442-s1 | Can you replace the broken lamp in our room? | Kannst du die kaputte Lampe in unserem Zimmer ersetzen? |
| reisen-v1-443-s1 | Could I borrow an umbrella from reception? | Könnte ich mir an der Rezeption einen Regenschirm ausleihen? |
| reisen-v1-444-s1 | Could you lend me a pen for this form? | Könntest du mir einen Stift für dieses Formular leihen? |
| reisen-v1-445-s1 | We must collect our luggage before leaving the airport. | Wir müssen unser Gepäck abholen, bevor wir den Flughafen verlassen. |
| reisen-v1-466-s1 | Our hotel is central, just beside the main square. | Unser Hotel liegt zentral, direkt neben dem Hauptplatz. |
| reisen-v1-467-s1 | We can buy medicine at a nearby pharmacy. | Wir können in einer nahe gelegenen Apotheke Medikamente kaufen. |
| reisen-v1-468-s1 | We spent a week in a remote village in the mountains. | Wir haben eine Woche in einem abgelegenen Bergdorf verbracht. |
| reisen-v1-469-s1 | We chose a rural campsite surrounded by fields. | Wir haben einen ländlichen Campingplatz gewählt, der von Feldern umgeben ist. |
| reisen-v1-470-s1 | Our guide explains the different types of urban transport. | Unser Reiseleiter erklärt die verschiedenen Arten städtischer Verkehrsmittel. |
| reisen-v1-491-s1 | The lake is too deep to stand in here. | Der See ist hier zu tief, um darin stehen zu können. |
| reisen-v1-492-s1 | The market sells fresh bread every morning. | Auf dem Markt wird jeden Morgen frisches Brot verkauft. |
| reisen-v1-493-s1 | This salad contains raw carrots and cucumber. | Dieser Salat enthält rohe Karotten und Gurke. |
| reisen-v1-494-s1 | Is this curry very spicy or fairly mild? | Ist dieses Curry sehr scharf oder eher mild? |
| reisen-v1-495-s1 | Do you have a vegetarian dish without meat or fish? | Haben Sie ein vegetarisches Gericht ohne Fleisch oder Fisch? |

## Abschließender Arbeitsbaum-Abgleich

`git diff --check`: Exit 0; keine Whitespacefehler. Lediglich Hinweis auf die konfigurierte spätere LF→CRLF-Umsetzung von test/data/real_pack_test.dart. `git status --short`: Exit 0. Vorherige Änderungen an Importer, Pipeline-Tests und deck_display bleiben laut Baseline bytegleich. In diesem Auftrag hinzugekommen: Batch-4-Bericht, beide Batch-4-Curation-Dateien und Batch-5-Registry; geändert: NEXTSTEPS und Reisen-Anzahl im vorhandenen Lesetest. Lokale out-/build-/Assetdateien werden im kurzen Git-Status nicht aufgeführt. Keine Commits oder Pushes.
