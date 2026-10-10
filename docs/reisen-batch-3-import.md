# Reisen Batch 3 – Offline-Import und Batch-4-Übergabe

Stand: 06.10.2026. Internes Pack `reisen_batch_3_v1`, Schema 2. Keine öffentliche Freigabe.

## Ergebnis und Prüfumfang

100 neue Karten mit je einem festen Satz übernommen; keine Auswahlposition fehlt. Alle 100 englisch-deutschen Satzpaare, sämtliche 978 Tokenbindungen und alle sieben wörtlich eingesetzten Alternativen redaktionell gelesen. Keine Stichprobe. Satztexte, Übersetzungen, Zielidentitäten, Lücken, accepted und Alternativen bleiben unverändert. Fünf redundante Begleitwort-Sense-Gruppen wurden in der versionierten Arbeitskopie bereinigt (acht Tokens/Satzreviews). Danach keine offenen neuen Satz- oder Alternativfehler festgestellt. Das ist eine interne redaktionelle Prüfung, keine externe Freigabe.

564 Karten, 1.098 Satztexte (einschließlich sechs Story-Sätzen), 1.092 historische/aktuelle Karten-Satz-Verknüpfungen; 460 Primärwörter in zwei Stapeln: 160 Allgemeine Sprache und 300 Reisen. Alle 300 Reisen-Primärwörter genau einmal und mit einer festen aktiven Satzzuordnung.

## Redaktionelle Korrekturen

Originalordner `reisen_batch_3/` einschließlich beider Manifeste unverändert. Änderungen ausschließlich in `pipeline/data/curation/reisen_batch_3.editorial.json` und dem gebundenen `reisen_batch_3_display_v1.json`.

| Satz-ID / Token | Vorher → nachher | Originalsatz / Begründung / Bestandsbeleg |
|---|---|---|
| reisen-v1-013-s1 / for | `for/ADP\|for#gegenleistung` → `for/ADP\|for#fuer` | The hotel charges a fee for cancellation on the arrival day. — Bestand bindet for bereits an die bezahlte Leistung/Sache. Bestand: Did Maya just pay for all the groceries? |
| reisen-v1-040-s1 / needs | `need/VERB\|need#erfordern` → `need/VERB\|need#braucht` | The form needs your signature at the bottom. — Bereits vorhandenes need für eine benötigte Ergänzung; kein neuer Sense wegen benötigt statt braucht. Bestand: Luca thinks that the soup needs more salt. |
| reisen-v1-213-s1 / for | `for/ADP\|for#gegenleistung` → `for/ADP\|for#fuer` | The airline gave us a full refund for the cancelled flight. — Bestand bindet for bereits an die bezahlte Leistung/Sache. Bestand: Did Maya just pay for all the groceries? |
| reisen-v1-286-s1 / cafe | `cafe/NOUN\|cafe#cafe` → `café/NOUN\|café#cafe` | A sudden downpour forced us into a nearby cafe. — cafe ist die akzentlose Schreibvariante desselben Lokals; vorhandener Besitzalias cafe → café. Bestand: We sit in a café and watch people cross the square. |
| reisen-v1-339-s1 / makes | `make/VERB\|make#bewirken` → `make/VERB\|make#macht` | The pain in my ankle makes walking difficult. — Bestand verwendet bereits dasselbe kausative make mit Objekt und Adjektiv. Bestand: Light drizzle makes our jackets damp during the walk. |
| reisen-v1-340-s1 / see | `see/VERB\|see#aufsuchen` → `see/VERB\|see#sehen` | I have a fever and need to see a doctor. — Gleicher im Bestand belegter Besuch einer medizinischen Fachperson. Bestand: My tooth hurts, so I need to see a dentist. |
| reisen-v1-363-s1 / cafe | `cafe/NOUN\|cafe#cafe` → `café/NOUN\|café#cafe` | The thief took my bag from the cafe table. — cafe ist die akzentlose Schreibvariante desselben Lokals; vorhandener Besitzalias cafe → café. Bestand: We sit in a café and watch people cross the square. |
| reisen-v1-487-s1 / make | `make/VERB\|make#bewirken` → `make/VERB\|make#macht` | Strong currents make swimming here dangerous. — Bestand verwendet bereits dasselbe kausative make mit Objekt und Adjektiv. Bestand: Light drizzle makes our jackets damp during the walk. |

Entfernt: fünf unreferenzierte neue Senses, das zusätzliche Lemma cafe/NOUN und vier danach redundante Form/Sense-Paare (for, needs, makes, see). Neue Form cafe bindet an café; make bleibt als benötigte Form am vorhandenen Sense. Es entstehen 99 neue Lemmas, 119 Senses und 148 Formen. Die acht betroffenen Tokenreview-Hashes wurden neu berechnet; Satz-/Linkreviews bleiben unverändert. Der Display-Patch bindet an die tatsächlichen geänderten Create-Bytes.

Bekannte, ausdrücklich zugelassene Überschneidung: `confirmation#buchungsbestaetigung` und bestehendes `confirmation#bestaetigung`. Ziel-/Registry-/Kartenidentitäten wurden nicht zusammengelegt.

`to` wurde je Kontext als Präposition oder Infinitivpartikel gelesen; `gate` nach Tor/Flugsteig, `stops` nach Verb/Aufenthalten und `station` im petrol-/police-station-Kontext. Hier keine weiteren bestätigten Bindungsfehler. Neue flektierte Formglossen wurden vollständig mitgelesen. Vorhandene breite Sense-Glossen wurden nicht global umgeschrieben.

### Sieben Alternativen – tatsächlicher Ersatzsatz

| Satz-ID | Alternative | Eingesetzter Satz | Urteil |
|---|---|---|---|
| reisen-v1-064-s1 | take-off | Please keep your seat belt fastened during take-off. | Korrekt; Grammatik, Perspektive und Zielaussage erhalten. |
| reisen-v1-090-s1 | elevator | Please use the elevator with your heavy suitcase. | Korrekt; Grammatik, Perspektive und Zielaussage erhalten. |
| reisen-v1-240-s1 | harbor | Small fishing boats shelter from the storm in the harbor. | Korrekt; Grammatik, Perspektive und Zielaussage erhalten. |
| reisen-v1-438-s1 | help | Airport staff can help passengers with limited mobility. | Korrekt; Grammatik, Perspektive und Zielaussage erhalten. |
| reisen-v1-463-s1 | quiet | The village is quiet after the day visitors leave. | Korrekt; Grammatik, Perspektive und Zielaussage erhalten. |
| reisen-v1-487-s1 | unsafe | Strong currents make swimming here unsafe. | Korrekt; Grammatik, Perspektive und Zielaussage erhalten. |
| reisen-v1-488-s1 | slick | These stone steps are slick after the rain. | Korrekt; Grammatik, Perspektive und Zielaussage erhalten. |

## Technische Abnahme

Liefermanifest und Referenzmanifest vollständig gegen lokale Bytes geprüft. Originalverifier und unveränderter Verifier im gesonderten Arbeitskopien-Ordner jeweils mit `--repo .` erfolgreich. Die Arbeitskopie enthält exakt die versionierten Importdateien; ihr eigenes Manifest wurde angepasst, das Originalmanifest nicht.

```text
PASS supplied JSON Schema (strict standard-library adapter)
PASS 100 sentences, 978 tokens, 6-11 words; 100 review hashes
PASS actual tokenizer and linter: 0 errors, 23 frequency warnings
PASS literal reviewed alternatives: 7
PASS in-memory 300-word display mapping; all other data unchanged
PASS current project create_content, stable IDs, display patch and build_rows: 564 cards / 1098 texts / 1092 links / 460 primary words
PASS delivery file hashes
```

Export über den bestehenden `--display-patch`-Pfad: Exit 0, status ok, internal true, ai_calls 0, ai_cost_usd 0. Vollpack-Linter: 0 Fehler, 200 Häufigkeitswarnungen = 177 vorhandene + 23 neue; keine Unterdrückung. Keine Pipeline-Codeänderung und keine neue Testsuite in diesem Auftrag.

`check_export.py` vergleicht JSON mit dem realen create_content-/Display-Ergebnis und alle Spalten aller 18 neu read-only geöffneten SQLite-Tabellen mit build_rows. integrity_check=ok, foreign_key_check leer. created_at ist die tatsächliche Laufzeit `2026-10-06T16:19:58.098474+00:00`, beim Abgleich gegen die Systemzeit geprüft.

Alle alten Zeilen erhalten; ausgenommen sind die genehmigten 190 position-Änderungen in jeweils deck_cards und deck_words sowie die neue Release-Beschreibung. Alte IDs, Satztexte, Reviews, Originalauswahlpositionen, Besitz-/Aliasregeln und alle 500 Identitäten unverändert. Reihenfolge 1–300 nach originaler Auswahl, kein Append-Zwischenexport.

| Tabelle | Zeilen |
|---|---:|
| languages | 1 |
| lemmas | 1536 |
| senses | 2653 |
| cards | 564 |
| dictionary_forms | 2832 |
| decks | 2 |
| deck_cards | 564 |
| deck_words | 460 |
| word_aliases | 5 |
| sentences | 1098 |
| sentence_tokens | 11534 |
| card_sentences | 1092 |
| stories | 1 |
| story_sentences | 6 |
| exercises | 0 |
| grammar_rules | 0 |
| audio_assets | 0 |
| content_releases | 1 |

### Reale Befehle und Exitcodes

PowerShell (ausgeführt, jeweils Exit 0; bei Fehlern wurde nicht weitergearbeitet):

```powershell
$env:PYTHONPATH = 'pipeline/src'
.\pipeline\.venv\Scripts\python.exe -X utf8 reisen_batch_3/verify_reisen_batch_3.py --repo .
.\pipeline\.venv\Scripts\python.exe -X utf8 build/reisen_batch_3_checks/verified_working_delivery/verify_reisen_batch_3.py --repo .
.\pipeline\.venv\Scripts\python.exe -X utf8 pipeline/scripts/import_editorial_patch.py --source pipeline/out/reisen_batch_2_v1/pack.json --create pipeline/data/curation/reisen_batch_3.editorial.json --registry pipeline/data/words/en.reisen_batch_3_v1.json --display-patch pipeline/data/curation/reisen_batch_3_display_v1.json --out pipeline/out/reisen_batch_3_v1
.\pipeline\.venv\Scripts\python.exe -X utf8 build/reisen_batch_3_checks/check_export.py
.\pipeline\.venv\Scripts\python.exe -X utf8 build/reisen_batch_3_checks/prepare_batch_4.py
```

Der erste Aufruf des neuen Batch-4-Helfers endete vor Schreibzugriffen mit Exit 1: eine zusätzliche Assertion verwendete das nicht vorhandene Feld target_meaning. Auf das reale sense_ref korrigiert; zweiter Aufruf Exit 0. Ein übernommener README-Verweis auf die Batch-2-Alternativfehler wurde berichtigt, ZIP und Manifest anschließend neu erstellt und geprüft.

macOS-Entsprechung (hier nicht ausgeführt): dieselben Argumente mit `PYTHONPATH=pipeline/src pipeline/.venv/bin/python -X utf8` statt PowerShell-Umgebungszuweisung und Windows-Interpreter. Bestehenden Export nicht erneut überschreiben; Abnahmehelfer sichert in einem neuen Ordner und ist absichtlich nicht blind wiederholbar.

Beide Systeme, tatsächlich unter Windows nach Abnahme und Backup ausgeführt, jeweils Exit 0:

```text
dart run tool/stage_content_pack.dart --from pipeline/out/reisen_batch_3_v1
dart run tool/stage_content_pack.dart --verify
flutter test test/data/real_pack_test.dart
flutter analyze
```

```text
deck allgemeine-sprache: 160 primary cards, 160 fixed sentence assignments verified
deck reisen: 300 primary cards, 300 fixed sentence assignments verified
All tests passed!
No issues found! (ran in 26.6s)
```

Beide alten Assets vor Staging gesichert: `build/reisen_batch_3_checks/asset_backup/`, Hashprotokoll hashes.json. Alter SQLite-Hash e6ea7ee8e77b88e6f6ca3f823d1d947bb9156bd30f7b7ef4fc5f2413a7867281; altes Manifest 2601e9366fa93e2581b9cc08200bcb85bee36180fca29ae43c919eaafce54031. Neuer SQLite-Umfang: 5.591.040 Bytes.

## Bindungen und Hashes

| Datei / Bedeutung | SHA256 |
|---|---|
| pipeline/out/reisen_batch_2_v1/pack.json (Rohbytes) | 4871da0f7e94c0401de2a4dd1b11d0229a6c610723ad3823acfef29cb1d06d1c |
| pipeline/data/curation/reisen_batch_3.editorial.json (Rohbytes) | 2c0a7a5688cc756f7dd50e4f09c90e820811654b0bb6976677ddd73ccfae7aa3 |
| pipeline/data/curation/reisen_batch_3_display_v1.json (Rohbytes) | 8c201fe590de0102442fa538b50438a32553b149009a38d5af2baa067c3fb354 |
| pipeline/out/reisen_batch_3_v1/pack.json (Rohbytes) | 27d2ef97c9a188e7313cdb7e12b84336f37266f0cca865d1a5c836a4dc17251f |
| pipeline/out/reisen_batch_3_v1/content.sqlite (Rohbytes) | 621f2d849074c9d8f1408fbccf42cf6558e13adb0ddcd4ee66cfe7390bd0baf9 |
| build/reisen_authoring_batch_4.zip (Rohbytes) | b7a8e6a9e90b1552106b9b9934bb2961103d695ef5cc75fdecc4b5ce853636bc |
| Batch-3-Registry (kanonisch) | f0b92c6b7952ab7a4f782c9a0ccd81192f41150f1d16dcb3719055c2842666f1 |
| Batch-4-Registry (kanonisch) | 8f1e9307f30639616ba4e1ac757b7e1f5eeeeb72aa1c2c75ec13d791ba3edb33 |

## Batch 4

`build/reisen_authoring_batch_4.zip`: 14 Dateien, CRC und 13 Manifest-Dateihashes geprüft. Kontexthelfer aus Batch 3 wiederverwendet. Exakt authoring_batch=4, 100 Ziele; keine Auswahl nach IDs 301–400. Zielidentitäten, Glossen und Definitionen bleiben aus der Auswahl unverändert. 34 Ziel-Senses vorhanden, 66 vorgeschlagen. Neu als vorhanden erkannt: route, petrol, shower, toilet, fish, fee, path, sail, board, land, replace. Bestandsdefinitionen separat im aktuellen dictionary_context.

Enthalten: realer neuer Pack (bytegleich), Wörterbuch, Registry mit unveränderten 660 Besitzzeilen/Aliassen, alle 500 Identitäten, finales 400er-Mapping, reales Create-v2-Schema, annotate.py, linter.py, deck_display.py, Tokenizerumgebung, Prüfprotokoll, README und Manifest. Neue Registry en.reisen_batch_4_v1 hat den tatsächlichen Batch-3-Snapshot als Parent und dessen Pack-Rohbytehash als Quelle. Historische source_sqlite_sha256-Metadaten unverändert. Keine neuen Batch-4-Sätze erzeugt.

## Erhalt und Grenzen

Baselinevergleich: 677 vorhandene Dateien; alle außer den autorisierten Assets, NEXTSTEPS und der Reisen-Erwartung im Lesetest unverändert. Normaler App-Einstieg lib/main.dart unverändert, SHA256 `c7e54ec1834b4dd18c592d32a310fae25394b6e2a48307fb3162de16e9eb4edd`. Keine Änderungen an lib/, Pipeline-Implementierung, SRS, Antwort-/UI-Logik oder vorherigen Registrys. Vorherige Arbeitsbaumänderungen erhalten.

Keine Cloud-/Modellaufrufe, Kosten 0 USD, keine Installation, keine Zugriffe auf user.db/Lernstände, keine Emulator-/iOS-/Android-Läufe, keine Commits/Pushes. Redaktionelle Prüfung betrifft die 100 neuen Sätze; der gesamte Altbestand wurde technisch auf Erhalt geprüft, nicht nochmals sprachlich vollständig redigiert.

Nächster gebündelter Schritt: Batch 4 anhand des geprüften ZIP redigieren und anschließend Create plus finales 400er-Display-Patch gemeinsam offline prüfen/importieren.

## Vollständige Satzpaar-Leseliste

Alle folgenden Paare wurden gelesen; „ohne weiteren Befund“ schließt die oben separat dokumentierte, erlaubte confirmation-Überschneidung ein. Sämtliche Tokenbindungen wurden vollständig gelesen; Struktur und Hashes zusätzlich maschinell geprüft.

| Satz-ID | Englisch | Deutsch | Ergebnis |
|---|---|---|---|
| reisen-v1-011-s1 | We have a reservation for two nights at this hotel. | Wir haben in diesem Hotel für zwei Nächte reserviert. | Geprüft, ohne weiteren Befund |
| reisen-v1-012-s1 | The hotel sent our booking confirmation by email. | Das Hotel hat uns die Buchungsbestätigung per E-Mail geschickt. | Geprüft, ohne weiteren Befund |
| reisen-v1-013-s1 | The hotel charges a fee for cancellation on the arrival day. | Das Hotel berechnet eine Gebühr für eine Stornierung am Anreisetag. | Begleitwortbindung korrigiert, danach ohne weiteren Befund |
| reisen-v1-014-s1 | Please check room availability before you book your flight. | Bitte prüfe vor der Flugbuchung, ob Zimmer verfügbar sind. | Geprüft, ohne weiteren Befund |
| reisen-v1-015-s1 | Please write your arrival date on this form. | Bitte schreib dein Anreisedatum auf dieses Formular. | Geprüft, ohne weiteren Befund |
| reisen-v1-036-s1 | Our taxi stops outside the German embassy. | Unser Taxi hält vor der deutschen Botschaft. | Geprüft, ohne weiteren Befund |
| reisen-v1-037-s1 | I need a new passport from the consulate. | Ich brauche einen neuen Reisepass vom Konsulat. | Geprüft, ohne weiteren Befund |
| reisen-v1-038-s1 | An official at the border checks our passports. | Eine Amtsperson an der Grenze kontrolliert unsere Reisepässe. | Geprüft, ohne weiteren Befund |
| reisen-v1-039-s1 | There is a new stamp in my passport. | In meinem Reisepass ist ein neuer Stempelabdruck. | Geprüft, ohne weiteren Befund |
| reisen-v1-040-s1 | The form needs your signature at the bottom. | Das Formular braucht unten deine Unterschrift. | Begleitwortbindung korrigiert, danach ohne weiteren Befund |
| reisen-v1-061-s1 | Our flight leaves from gate twelve. | Unser Flug geht von Flugsteig zwölf ab. | Geprüft, ohne weiteren Befund |
| reisen-v1-062-s1 | Please have your passport ready for boarding. | Bitte halte deinen Reisepass für das Einsteigen bereit. | Geprüft, ohne weiteren Befund |
| reisen-v1-063-s1 | The pilot made a smooth landing despite the strong wind. | Trotz des starken Windes gelang dem Piloten eine sanfte Landung. | Geprüft, ohne weiteren Befund |
| reisen-v1-064-s1 | Please keep your seat belt fastened during takeoff. | Bitte lass deinen Sicherheitsgurt während des Starts angelegt. | Geprüft, ohne weiteren Befund |
| reisen-v1-065-s1 | We have a three-hour layover between our flights. | Wir haben zwischen unseren Flügen einen dreistündigen Zwischenaufenthalt. | Geprüft, ohne weiteren Befund |
| reisen-v1-086-s1 | An old steam locomotive pulls the train through the valley. | Eine alte Dampflokomotive zieht den Zug durch das Tal. | Geprüft, ohne weiteren Befund |
| reisen-v1-087-s1 | We take the subway from the airport to our hotel. | Wir fahren mit der U-Bahn vom Flughafen zu unserem Hotel. | Geprüft, ohne weiteren Befund |
| reisen-v1-088-s1 | This tram stops outside the museum. | Diese Straßenbahn hält vor dem Museum. | Geprüft, ohne weiteren Befund |
| reisen-v1-089-s1 | The escalator takes us down to the platform. | Die Rolltreppe bringt uns hinunter zum Bahnsteig. | Geprüft, ohne weiteren Befund |
| reisen-v1-090-s1 | Please use the lift with your heavy suitcase. | Bitte benutze mit deinem schweren Koffer den Aufzug. | Geprüft, ohne weiteren Befund |
| reisen-v1-111-s1 | Take the second exit at the roundabout. | Nimm am Kreisverkehr die zweite Ausfahrt. | Geprüft, ohne weiteren Befund |
| reisen-v1-112-s1 | Turn left at the crossroads after the petrol station. | Biege an der Kreuzung hinter der Tankstelle links ab. | Geprüft, ohne weiteren Befund |
| reisen-v1-113-s1 | The road goes through a long tunnel under the mountain. | Die Straße führt durch einen langen Tunnel unter dem Berg. | Geprüft, ohne weiteren Befund |
| reisen-v1-114-s1 | We must pay a toll to use this bridge. | Wir müssen Maut bezahlen, um diese Brücke zu benutzen. | Geprüft, ohne weiteren Befund |
| reisen-v1-115-s1 | Overnight parking is free for hotel guests. | Das Parken über Nacht ist für Hotelgäste kostenlos. | Geprüft, ohne weiteren Befund |
| reisen-v1-136-s1 | The receptionist gives us our room key. | Die Person an der Rezeption gibt uns unseren Zimmerschlüssel. | Geprüft, ohne weiteren Befund |
| reisen-v1-137-s1 | We wait for our taxi in the hotel lobby. | Wir warten in der Hotellobby auf unser Taxi. | Geprüft, ohne weiteren Befund |
| reisen-v1-138-s1 | Our room is at the end of this corridor. | Unser Zimmer liegt am Ende dieses Flurs. | Geprüft, ohne weiteren Befund |
| reisen-v1-139-s1 | Our room is on the third floor. | Unser Zimmer liegt im dritten Stock. | Geprüft, ohne weiteren Befund |
| reisen-v1-140-s1 | We can see the sea from our balcony. | Von unserem Balkon aus können wir das Meer sehen. | Geprüft, ohne weiteren Befund |
| reisen-v1-161-s1 | I bought a small snack for the train journey. | Ich habe eine kleine Zwischenmahlzeit für die Zugfahrt gekauft. | Geprüft, ohne weiteren Befund |
| reisen-v1-162-s1 | I would like the soup as a starter. | Ich hätte gern die Suppe als Vorspeise. | Geprüft, ohne weiteren Befund |
| reisen-v1-163-s1 | The next course is fish with vegetables. | Als nächsten Gang gibt es Fisch mit Gemüse. | Geprüft, ohne weiteren Befund |
| reisen-v1-164-s1 | Would you like fruit or ice cream for dessert? | Möchtest du Obst oder Eis zum Nachtisch? | Geprüft, ohne weiteren Befund |
| reisen-v1-165-s1 | Guests can choose their breakfast from the buffet. | Die Gäste können sich ihr Frühstück am Büfett zusammenstellen. | Geprüft, ohne weiteren Befund |
| reisen-v1-186-s1 | The restaurant serves fresh pasta with tomato sauce. | Das Restaurant serviert frische Nudeln mit Tomatensoße. | Geprüft, ohne weiteren Befund |
| reisen-v1-187-s1 | We shared a large pizza after our long walk. | Nach unserem langen Spaziergang haben wir uns eine große Pizza geteilt. | Geprüft, ohne weiteren Befund |
| reisen-v1-188-s1 | I ordered grilled chicken with rice and vegetables. | Ich habe gegrilltes Hähnchenfleisch mit Reis und Gemüse bestellt. | Geprüft, ohne weiteren Befund |
| reisen-v1-189-s1 | Does this soup contain beef or only vegetables? | Enthält diese Suppe Rindfleisch oder nur Gemüse? | Geprüft, ohne weiteren Befund |
| reisen-v1-190-s1 | I do not eat pork, so I chose the fish. | Ich esse kein Schweinefleisch, deshalb habe ich mich für den Fisch entschieden. | Geprüft, ohne weiteren Befund |
| reisen-v1-211-s1 | We left a tip for the waiter after dinner. | Nach dem Abendessen haben wir dem Kellner Trinkgeld gegeben. | Geprüft, ohne weiteren Befund |
| reisen-v1-212-s1 | There is a surcharge for a room with a balcony. | Für ein Zimmer mit Balkon fällt ein Aufpreis an. | Geprüft, ohne weiteren Befund |
| reisen-v1-213-s1 | The airline gave us a full refund for the cancelled flight. | Die Fluggesellschaft hat uns den ausgefallenen Flug vollständig erstattet. | Begleitwortbindung korrigiert, danach ohne weiteren Befund |
| reisen-v1-214-s1 | Students get a discount on tickets to this museum. | Schüler und Studierende bekommen die Eintrittskarten für dieses Museum günstiger. | Geprüft, ohne weiteren Befund |
| reisen-v1-215-s1 | This suitcase was a bargain at half the usual price. | Dieser Koffer war zum halben üblichen Preis ein Schnäppchen. | Geprüft, ohne weiteren Befund |
| reisen-v1-236-s1 | We met our guide in the main square. | Wir haben unseren Reiseleiter auf dem Hauptplatz getroffen. | Geprüft, ohne weiteren Befund |
| reisen-v1-237-s1 | Water splashes from the fountain in the town square. | Auf dem Stadtplatz spritzt Wasser aus dem Springbrunnen. | Geprüft, ohne weiteren Befund |
| reisen-v1-238-s1 | There is a statue of a horse outside the palace. | Vor dem Palast steht die Statue eines Pferdes. | Geprüft, ohne weiteren Befund |
| reisen-v1-239-s1 | We walked among the ruins of an old castle. | Wir sind zwischen den Ruinen einer alten Burg spazieren gegangen. | Geprüft, ohne weiteren Befund |
| reisen-v1-240-s1 | Small fishing boats shelter from the storm in the harbour. | Kleine Fischerboote suchen im Hafen Schutz vor dem Sturm. | Geprüft, ohne weiteren Befund |
| reisen-v1-261-s1 | The path runs along the top of the cliff. | Der Weg verläuft oben an der Klippe entlang. | Geprüft, ohne weiteren Befund |
| reisen-v1-262-s1 | We needed a torch inside the dark cave. | In der dunklen Höhle brauchten wir eine Taschenlampe. | Geprüft, ohne weiteren Befund |
| reisen-v1-263-s1 | Our guide carries extra water for the journey across the desert. | Unser Reiseleiter nimmt zusätzliches Wasser für die Reise durch die Wüste mit. | Geprüft, ohne weiteren Befund |
| reisen-v1-264-s1 | We could see smoke rising from the volcano. | Wir konnten Rauch aus dem Vulkan aufsteigen sehen. | Geprüft, ohne weiteren Befund |
| reisen-v1-265-s1 | A guide leads our group across the glacier. | Ein Guide führt unsere Gruppe über den Gletscher. | Geprüft, ohne weiteren Befund |
| reisen-v1-286-s1 | A sudden downpour forced us into a nearby cafe. | Ein plötzlicher Platzregen zwang uns in ein nahe gelegenes Café. | Begleitwortbindung korrigiert, danach ohne weiteren Befund |
| reisen-v1-287-s1 | Fresh snow covered the road to our mountain hotel. | Frischer Schnee bedeckte die Straße zu unserem Berghotel. | Geprüft, ohne weiteren Befund |
| reisen-v1-288-s1 | The weather forecast warns of frost tonight. | Die Wettervorhersage warnt für heute Nacht vor Frost. | Geprüft, ohne weiteren Befund |
| reisen-v1-289-s1 | Be careful on the ice outside the hotel. | Sei auf dem Eis vor dem Hotel vorsichtig. | Geprüft, ohne weiteren Befund |
| reisen-v1-290-s1 | The strong wind blew my hat into the sea. | Der starke Wind hat meinen Hut ins Meer geweht. | Geprüft, ohne weiteren Befund |
| reisen-v1-311-s1 | The ferry carries cars and passengers to the island. | Die Fähre bringt Autos und Fahrgäste zur Insel. | Geprüft, ohne weiteren Befund |
| reisen-v1-312-s1 | We rented a small boat for a trip on the lake. | Wir haben für einen Ausflug auf dem See ein kleines Boot gemietet. | Geprüft, ohne weiteren Befund |
| reisen-v1-313-s1 | The large ship carries goods across the ocean. | Das große Schiff transportiert Waren über den Ozean. | Geprüft, ohne weiteren Befund |
| reisen-v1-314-s1 | A white yacht with two sails enters the harbour. | Eine weiße Jacht mit zwei Segeln läuft in den Hafen ein. | Geprüft, ohne weiteren Befund |
| reisen-v1-315-s1 | Our cruise includes stops at three islands. | Unsere Kreuzfahrt umfasst Aufenthalte auf drei Inseln. | Geprüft, ohne weiteren Befund |
| reisen-v1-336-s1 | Hot tea left a small burn on my hand. | Heißer Tee hat eine kleine Brandwunde an meiner Hand verursacht. | Geprüft, ohne weiteren Befund |
| reisen-v1-337-s1 | My new walking shoes gave me a blister on my heel. | Meine neuen Wanderschuhe haben mir eine Blase an der Ferse verursacht. | Geprüft, ohne weiteren Befund |
| reisen-v1-338-s1 | I have a large bruise on my leg after that fall. | Nach diesem Sturz habe ich einen großen blauen Fleck am Bein. | Geprüft, ohne weiteren Befund |
| reisen-v1-339-s1 | The pain in my ankle makes walking difficult. | Wegen der Schmerzen im Knöchel fällt mir das Gehen schwer. | Begleitwortbindung korrigiert, danach ohne weiteren Befund |
| reisen-v1-340-s1 | I have a fever and need to see a doctor. | Ich habe Fieber und muss zum Arzt. | Begleitwortbindung korrigiert, danach ohne weiteren Befund |
| reisen-v1-361-s1 | We called the police after someone stole our luggage. | Wir haben die Polizei gerufen, nachdem jemand unser Gepäck gestohlen hatte. | Geprüft, ohne weiteren Befund |
| reisen-v1-362-s1 | I reported the theft of my wallet at the police station. | Ich habe den Diebstahl meiner Brieftasche auf der Polizeiwache angezeigt. | Geprüft, ohne weiteren Befund |
| reisen-v1-363-s1 | The thief took my bag from the cafe table. | Der Dieb hat meine Tasche vom Tisch im Café genommen. | Begleitwortbindung korrigiert, danach ohne weiteren Befund |
| reisen-v1-364-s1 | A pickpocket stole my wallet on the crowded bus. | Ein Taschendieb hat mir im überfüllten Bus die Brieftasche gestohlen. | Geprüft, ohne weiteren Befund |
| reisen-v1-365-s1 | The cheap holiday offer was a scam; the hotel never existed. | Das günstige Urlaubsangebot war eine Betrugsmasche; das Hotel hat nie existiert. | Geprüft, ohne weiteren Befund |
| reisen-v1-386-s1 | We need to prepare our travel documents before departure. | Wir müssen vor der Abreise unsere Reiseunterlagen vorbereiten. | Geprüft, ohne weiteren Befund |
| reisen-v1-387-s1 | Please pack your warm jacket for the mountain trip. | Bitte pack deine warme Jacke für den Ausflug in die Berge ein. | Geprüft, ohne weiteren Befund |
| reisen-v1-388-s1 | We can unpack our suitcases after we reach the hotel. | Wir können unsere Koffer auspacken, sobald wir im Hotel sind. | Geprüft, ohne weiteren Befund |
| reisen-v1-389-s1 | We must leave the hotel before ten tomorrow morning. | Wir müssen morgen früh vor zehn das Hotel verlassen. | Geprüft, ohne weiteren Befund |
| reisen-v1-390-s1 | We plan to return to this island next summer. | Wir wollen nächsten Sommer auf diese Insel zurückkehren. | Geprüft, ohne weiteren Befund |
| reisen-v1-411-s1 | Please tell the driver our hotel address. | Bitte nenne dem Fahrer unsere Hoteladresse. | Geprüft, ohne weiteren Befund |
| reisen-v1-412-s1 | Can you show me the station on this map? | Kannst du mir den Bahnhof auf dieser Karte zeigen? | Geprüft, ohne weiteren Befund |
| reisen-v1-413-s1 | Can you describe your missing suitcase to the airport staff? | Kannst du dem Flughafenpersonal deinen verschwundenen Koffer beschreiben? | Geprüft, ohne weiteren Befund |
| reisen-v1-414-s1 | Can you recommend a quiet restaurant near the harbour? | Kannst du ein ruhiges Restaurant in der Nähe des Hafens empfehlen? | Geprüft, ohne weiteren Befund |
| reisen-v1-415-s1 | Could you suggest a good place for lunch? | Könntest du einen guten Ort zum Mittagessen vorschlagen? | Geprüft, ohne weiteren Befund |
| reisen-v1-436-s1 | Do you remember the name of our hotel? | Erinnerst du dich an den Namen unseres Hotels? | Geprüft, ohne weiteren Befund |
| reisen-v1-437-s1 | Could you help me with this heavy suitcase? | Könntest du mir mit diesem schweren Koffer helfen? | Geprüft, ohne weiteren Befund |
| reisen-v1-438-s1 | Airport staff can assist passengers with limited mobility. | Das Flughafenpersonal kann Fluggäste mit eingeschränkter Mobilität unterstützen. | Geprüft, ohne weiteren Befund |
| reisen-v1-439-s1 | Please report any stolen luggage to the police. | Bitte melde gestohlenes Gepäck der Polizei. | Geprüft, ohne weiteren Befund |
| reisen-v1-440-s1 | Please contact the hotel directly about your reservation. | Bitte wende dich wegen deiner Reservierung direkt an das Hotel. | Geprüft, ohne weiteren Befund |
| reisen-v1-461-s1 | The bus was so crowded that we had to stand. | Der Bus war so überfüllt, dass wir stehen mussten. | Geprüft, ohne weiteren Befund |
| reisen-v1-462-s1 | Our hotel is on a busy street near the station. | Unser Hotel liegt an einer belebten Straße in der Nähe des Bahnhofs. | Geprüft, ohne weiteren Befund |
| reisen-v1-463-s1 | The village is peaceful after the day visitors leave. | Im Dorf ist es ruhig, wenn die Tagesgäste weg sind. | Geprüft, ohne weiteren Befund |
| reisen-v1-464-s1 | These seats are comfortable enough for a long journey. | Diese Sitze sind bequem genug für eine lange Reise. | Geprüft, ohne weiteren Befund |
| reisen-v1-465-s1 | This hotel is convenient for the station, just two minutes away. | Dieses Hotel liegt günstig zum Bahnhof, nur zwei Minuten entfernt. | Geprüft, ohne weiteren Befund |
| reisen-v1-486-s1 | Our bicycles are secure behind the locked gate. | Unsere Fahrräder sind hinter dem verschlossenen Tor gesichert. | Geprüft, ohne weiteren Befund |
| reisen-v1-487-s1 | Strong currents make swimming here dangerous. | Wegen der starken Strömungen ist Schwimmen hier gefährlich. | Begleitwortbindung korrigiert, danach ohne weiteren Befund |
| reisen-v1-488-s1 | These stone steps are slippery after the rain. | Diese Steinstufen sind nach dem Regen rutschig. | Geprüft, ohne weiteren Befund |
| reisen-v1-489-s1 | The path to the castle is very steep. | Der Weg zur Burg ist sehr steil. | Geprüft, ohne weiteren Befund |
| reisen-v1-490-s1 | The water is shallow near this part of the beach. | An diesem Strandabschnitt ist das Wasser flach. | Geprüft, ohne weiteren Befund |

## Abschließender Git-Abgleich

`git diff --check`: Exit 0, keine Whitespacefehler; Git meldet lediglich die konfigurierte spätere LF→CRLF-Umsetzung von NEXTSTEPS.md. `git status --short`: Exit 0. Vorhandene Änderungen an Importer/Pipeline-Tests/deck_display stammen aus Batch 2 und sind laut Baseline unverändert. Neu in diesem Auftrag: Batch-3-Bericht, beide Batch-3-Curation-Dateien, Batch-4-Registry; außerdem NEXTSTEPS und Reisen-Anzahl im bestehenden Lesetest aktualisiert. Build-/out-/Assetdateien sind lokal vorhanden, werden im kurzen Git-Status nicht aufgeführt. Abschließender unabhängiger ZIP-Abgleich bestätigt unveränderte 100 Zieldefinitionen/Identitäten, aktuelle Quell-/Registry-/Codebytes, 400 Positionen, CRC und sämtliche Manifest-Hashes.
