# Reisen Batch 5 – Abschluss des internen 500-Wörter-Stapels

Stand: 06.10.2026. `reisen_batch_5_v1`, Schema 2, vollständig offline importiert, intern gestagt und technisch abgenommen. Reisen: genau 500 unterschiedliche Primärwörter mit je einem festen Satz; Allgemeine Sprache unverändert 160. Insgesamt 764 Karten, 1298 Satztexte einschließlich sechs Story-Sätzen und 1292 aktuelle/historische Karten-Satz-Verknüpfungen in zwei Stapeln. Keine öffentliche Freigabe.

## Redaktionelle Prüfung und Korrekturen

Alle 100 neuen englisch-deutschen Satzpaare, 1021 Tokens, 142 neue Formglossen und sieben wörtlich eingesetzte Alternativen gelesen, gegen die Zielbedeutung, Wortart, Übersetzung und den vollständigen Satzanschluss geprüft. 31 vorhandene und 69 vorgeschlagene Zielbindungen exakt erhalten. Die Originallieferung `reisen_batch_5/` einschließlich beider Manifeste ist unverändert.

Gezielte Änderungen ausschließlich in den versionierten Curation-Arbeitskopien:

| Satz-ID / Token | Vorher | Nachher | Grund |
|---|---|---|---|
| reisen-v1-049-s1 / for | `for/ADP\|for#seit_lang_dauer` | `for/ADP\|for#fuer_zweck_empfaenger` | Einreise ist der Zweck der Passanforderung, keine Zeitspanne. |
| reisen-v1-074-s1 / exit | `exit/NOUN\|exit#autobahnausfahrt` | `exit/NOUN\|exit#ausgang` | Ausgang beim Gepäckband bezeichnet einen Gebäudedurchgang, keine Autobahnausfahrt. |
| reisen-v1-271-s1 / took | `nahm mit` | `nahmen mit` | Neue Formglosse an Pluralsubjekt We angeglichen; Sense und Satz bleiben unverändert. |

`for#fuer_zweck_empfaenger` ist im aktuellen Wörterbuch vorhanden und wird bereits im Satz „A valid passport is a requirement for this journey.“ verwendet. `exit#ausgang` samt Formzeile wird in derselben Lieferung für „The emergency exit is at the end of the corridor.“ eingeführt und beim Gepäckband wiederverwendet. Keine neue Dublette nötig. Im hire-Satz bleibt `for#seit_lang_dauer` korrekt: „for the weekend“ benennt die Mietdauer.

Zwei Tokenreview-Hashes neu berechnet; drei Reviewbegründungen um die lokalen Befunde ergänzt. Text, Übersetzung, Tokenisierung/Offsets, Lücken, accepted, Alternativen und sämtliche Zielidentitäten unverändert. Create-Rohbytehash im Display-Patch neu gebunden. Formglossen sind nicht Teil des Tokenhashs; die korrigierte took-Glosse ist durch den Create-Rohbytehash gebunden. Der unveränderte Lieferverifier wurde zusätzlich auf genau den importierten Arbeitskopien ausgeführt. Das dortige eigene Manifest erfasst die Arbeitsdateien und unveränderten Referenzen; Originalmanifeste nicht geändert.

Alle 47 neuen Begleitwort-Senses mit vorhandenen Wörterbuchzeilen und deren Satzbelegen abgeglichen, einschließlich Wortart- und Schreibvarianten. Kein weiterer bestätigter Dublettenbefund: work/Funktionieren unterscheidet sich von menschlichem Arbeiten; dry/trocken werden vom vorhandenen Abtrocknen mit Handtuch; turn/Drehen eines Schlüssels vom Ausschalten und Abbiegen; sign/Anzeichen vom Schild; play/Theaterstück vom Verb spielen. Keine neuen Senses allein wegen anders formulierter Glossen.

Besondere Bindungen gelesen: ride als Ziel = Mitfahren, im helmet-Satz = Fahrradfahren; cold = Kälte; entry in beiden Einreisesätzen = entry#einreise; station in petrol station = Tankstellenbestandteil; park im concert-Satz = Nomen; dry und working = Verben; right in junction = Richtung; die beiden to im theatre-Satz = Präposition und Infinitivpartikel. Formglossen asks „bittet“, threw „warf“, wheelchairs „Rollstühle“, times „Zeiten; Uhrzeiten“ geprüft. Historische Sense-Glossen wie Tomaten-, Konzert-, Durchsagen, Symptome oder geparkt unverändert; neue Karten behalten die vorgegebenen Grundformübersetzungen. Die bestehende their/PRON-Zuordnung wird als vorhandenes possessives Projektmodell verwendet, nicht global umgetaggt.

### Sieben geprüfte Alternativen

| Satz-ID | Alternative | Wörtlicher Ersatzsatz | Ergebnis |
|---|---|---|---|
| reisen-v1-021-s1 | traveler | The traveler beside me is visiting Japan for the first time. | Grammatik, Bedeutung, Zeit und Perspektive erhalten. |
| reisen-v1-072-s1 | luggage | Please do not leave your luggage unattended at the station. | Grammatik, Bedeutung, Zeit und Perspektive erhalten. |
| reisen-v1-121-s1 | license | Please show your driving license before collecting the rental car. | Grammatik, Bedeutung, Zeit und Perspektive erhalten. |
| reisen-v1-123-s1 | seat belt | Please wear your seat belt throughout the bus journey. | Grammatik, Bedeutung, Zeit und Perspektive erhalten. |
| reisen-v1-246-s1 | theater | We are going to the theater to watch a play. | Grammatik, Bedeutung, Zeit und Perspektive erhalten. |
| reisen-v1-398-s1 | rent | We want to rent a car for the weekend. | Grammatik, Bedeutung, Zeit und Perspektive erhalten. |
| reisen-v1-448-s1 | buckle | Please buckle your seatbelt before the bus leaves. | Grammatik, Bedeutung, Zeit und Perspektive erhalten. |

Besitzaliase allein geben keine Antworten frei. traveler/license/theater wurden zusätzlich konkret als Alternativen geprüft; accepted bleibt ausschließlich die Zielform. Leere Alternativlisten behaupten keine Eindeutigkeit.

## Technische Abnahme

Liefer- und Referenzmanifest vollständig gegen lokale Bytes geprüft. Tatsächliche Quelle und kanonische Registry stimmen mit den Auftragshashes überein; kein Austausch gegen ein Referenzpack, keine deaktivierte Prüfung. Vorhandener Ausgabeordner ausgeschlossen. Echte Projektfunktionen create_content, stable_id, deck_display und build_rows sowie spaCy-Tokenizer und vollständiger Linter benutzt. Keine Stubs oder Cloud-Annotation.

Original und korrigierte Arbeitskopien, jeweils --repo . und Exit 0:

```text
PASS supplied JSON Schema (strict standard-library adapter)
PASS 100 sentences, 1021 tokens, 7-11 words; 100 review hashes
PASS actual tokenizer and linter: 0 errors, 38 frequency warnings
PASS literal reviewed alternatives: 7
PASS in-memory 500-word display mapping; all other data unchanged
PASS current project create_content, stable IDs, display patch and build_rows: 764 cards / 1298 texts / 1292 links / 660 primary words
PASS delivery file hashes
```

Exportstatus ok, internal_test_pack=true, ai_calls=0, ai_cost_usd=0. Vollpack-Linter: 0 Fehler, **264 Häufigkeitswarnungen = 226 bestehende + 38 neue**. Keine Unterdrückung; vollständige Befunde in `pipeline/out/reisen_batch_5_v1/finalization_report.json`. Der vorhandene --display-patch-Pfad sortiert vor dem einzigen Export; kein Append-Zwischenexport. Genau 380 alte position-Werte je deck_cards/deck_words verändert. Auswahl-/Registry-Originalpositionen unverändert.

JSON entspricht dem tatsächlichen Create-/Display-Ergebnis. SQLite neu read-only geöffnet: integrity_check=ok, foreign_key_check leer, jede Spalte jeder Zeile aller 18 Tabellen mit build_rows verglichen. Alte Daten/IDs/Texte/Reviews/Links erhalten; nur genehmigte Reisen-Anzeigepositionen und Release-Metadaten geändert.

Gesamtprüfung `build/reisen_batch_5_checks/full_500_verification.json`: alle 500 Identitäten gegen all_500_identities, Auswahl, Registry und tatsächliche Pack-/SQLite-Zeilen abgeglichen. Form, Lemma, POS, Sense-ID, Karten-ID und Kartenübersetzung stimmen; IDs neu mit stable_id berechnet. Je genau ein primäres Wort, ein aktiver fester Satz und genau accepted=[form]; Positionen 1–500 in originaler Auswahlreihenfolge. Keine fehlenden/zusätzlichen Ziele. 160 allgemeine Primärwörter unverändert. Alle acht Besitzaliase konfliktfrei, die drei neuen genau traveler→traveller, license→licence, theater→theatre. Historische Mehrfachverknüpfungen im allgemeinen Bestand erhalten.

Reales `created_at`: `2026-10-06T17:00:15.999899+00:00`, beim Readback gegen Systemzeit geprüft.

| Tabelle | Zeilen |
|---|---:|
| languages | 1 |
| lemmas | 1743 |
| senses | 2886 |
| cards | 764 |
| dictionary_forms | 3124 |
| decks | 2 |
| deck_cards | 764 |
| deck_words | 660 |
| word_aliases | 8 |
| sentences | 1298 |
| sentence_tokens | 13537 |
| card_sentences | 1292 |
| stories | 1 |
| story_sentences | 6 |
| exercises | 0 |
| grammar_rules | 0 |
| audio_assets | 0 |
| content_releases | 1 |

## Tatsächliche Befehle und Exitcodes

Windows PowerShell, Repository-Root, nacheinander; alle folgenden Befehle Exit 0. Keine fehlgeschlagenen Import-/Prüfversuche:

```powershell
$env:PYTHONPATH = 'pipeline/src'
.\pipeline\.venv\Scripts\python.exe -X utf8 reisen_batch_5/verify_reisen_batch_5.py --repo .
.\pipeline\.venv\Scripts\python.exe -X utf8 build/reisen_batch_5_checks/verified_working_delivery/verify_reisen_batch_5.py --repo .
.\pipeline\.venv\Scripts\python.exe -X utf8 pipeline/scripts/import_editorial_patch.py --source pipeline/out/reisen_batch_4_v1/pack.json --create pipeline/data/curation/reisen_batch_5.editorial.json --registry pipeline/data/words/en.reisen_batch_5_v1.json --display-patch pipeline/data/curation/reisen_batch_5_display_v1.json --out pipeline/out/reisen_batch_5_v1
.\pipeline\.venv\Scripts\python.exe -X utf8 build/reisen_batch_5_checks/check_export.py
.\pipeline\.venv\Scripts\python.exe -X utf8 build/reisen_batch_5_checks/write_report.py
```

macOS Terminal (hier nicht ausgeführt): dieselben Python-Dateien/Argumente mit `PYTHONPATH=pipeline/src pipeline/.venv/bin/python -X utf8` statt PowerShell-Umgebungszuweisung und Windows-Interpreter. Vorhandene Export-/Backupordner nicht erneut verwenden.

Beide Systeme; tatsächlich unter Windows nach Import-/SQLite-Abnahme und Asset-Sicherung, jeweils Exit 0:

```text
dart run tool/stage_content_pack.dart --from pipeline/out/reisen_batch_5_v1
dart run tool/stage_content_pack.dart --verify
flutter test test/data/real_pack_test.dart
flutter analyze
```

```text
PASS FINAL 500: exact forms/lemma/POS/sense/card IDs, unique primary membership and fixed sentence per target, positions 1..500; 160 general words; 8 conflict-free aliases
PASS JSON equals actual Create/Display result; integrity_check ok; foreign_key_check []; all 18 tables/columns match
staged / verified assets/content/en/content.sqlite
version reisen_batch_5_v1, schema 2, 6483968 bytes
18 table counts match finalization_report.json
deck allgemeine-sprache: 160 primary cards, 160 fixed sentence assignments verified
deck reisen: 500 primary cards, 500 fixed sentence assignments verified
All tests passed!
No issues found! (ran in 2.3s)
```

Vorhandener realer Lesetest nur von 400 auf 500 Reisewörter angepasst; feste 160 allgemeine Wörter beibehalten. Keine Pipeline-Codeänderung und keine neue duplizierende Testsuite. Export-Abnahmehelfer aus Batch 4 wiederverwendet und um den vollständigen 500er-Identitätsnachweis ergänzt.

## Sicherung und SHA256

Beide bestehenden Assets vor Staging in neuem `build/reisen_batch_5_checks/asset_backup/` gesichert und bytegeprüft; Hashes in hashes.json. Keine Wiederherstellung nötig.

| Gesichertes Asset | SHA256 |
|---|---|
| content.sqlite | fc04b23eed0150e34690fc06eec7c8518bbfc85739b505d18c0d1792083040f4 |
| content.manifest.json | 83083f9592fc8029e015d84e88eefbdc8f25ba8b86130bb1d1cb5225fcb94173 |

| Datei (Rohbytes) | SHA256 |
|---|---|
| pipeline/out/reisen_batch_4_v1/pack.json | 97015c3c12b9f5e2fb2d900ee9544029189e1f51a3741c1a9100f206dcf5b4d3 |
| reisen_batch_5/reisen_batch_5.editorial.json | a4b04234766e953727bc3d137f103305568ca7b8e2933a88214f427ec5314c8e |
| pipeline/data/curation/reisen_batch_5.editorial.json | d17efe235cc753961a4247b48f3ba79187197f893fafccd1938fc4c528e2c426 |
| pipeline/data/curation/reisen_batch_5_display_v1.json | 613b536d921162c5480fcafedbba843ab1b60a2b38654310cd2d7680fd3e15b2 |
| pipeline/out/reisen_batch_5_v1/pack.json | e93bbf7991b00e54bb60e3f0d3a3832509e5d6a83faad1352d38cb91518c7d39 |
| pipeline/out/reisen_batch_5_v1/content.sqlite | 5921e5f481d6a1ee78ee20041405803d2610b539ecf781a0c160ead7baafd1dd |
| assets/content/en/content.manifest.json | 5d3c072e98a4b369e98a102f803751be3d9e1dfcc4b261b9a7baf1385e1a0921 |
| lib/main.dart | c7e54ec1834b4dd18c592d32a310fae25394b6e2a48307fb3162de16e9eb4edd |

Registry kanonisch: `4148c720b983fe66c01683db760208c7b85cb0a59f98bb5a40ae7d049198f2b4`. Historische source_sqlite_sha256-Metadaten unverändert. Before-Hashes: deck_cards `58723eb0a7e8337eb07ffd403b8b91b6b32091a9572807948dc5f813a13b30a2`, deck_words `04cea3265ed16afb10af60a1963e39133d37121d8635b271d24eb40c8fc296e5`. Alle Source/Create/Registry/Before-/Reviewbindungen entsprechen den tatsächlich importierten Dateien.

## Abschluss, offene Themen und Grenzen

Technisch vollständiger interner 500-Wörter-Reisen-Stapel. Die strukturelle Gesamtprüfung ist keine erneute vollständige redaktionelle Prüfung der 400 alten Reisesätze und keine öffentliche oder unabhängige menschliche Freigabe. Bestehende Glossenthemen/POS-Altfehler (unter anderem lower/ADJ) und bewusst erhaltene Ziel-Sense-Überschneidungen (nearby, confirmation) bleiben getrennte offene Aufgaben; keine pauschale Altdatenbereinigung.

738 vorhandene Dateien als Baseline erfasst. Keine unerwarteten Änderungen; erlaubte Änderungen nur Assets, Lesetest, NEXTSTEPS und Abschlussstatus im Authoring-Bericht. Normaler App-Einstieg lib/main.dart hashgleich: ProviderScope → SprachApp → AppShell. Vorhandene Arbeitsbaumänderungen, alte out-Packs, Registrys und Originallieferung erhalten. Kein Zugriff auf user.db oder echte Lernstände, keine SRS-/Antwort-/UI-Änderung, keine Cloud-/Vertex-/Gemini-Aufrufe, keine neuen Modellkosten, keine Emulator-/iOS-/Android-Tests, keine Commits/Pushes/Veröffentlichung. Kein Batch 6 und kein neuer Themenstapel.

### Manueller iPhone-Prüfweg (nicht ausgeführt)

Bei vorhandener Syncthing-Synchronisierung zunächst deren Abschluss auf dem Mac abwarten. Im Repository `dart run tool/stage_content_pack.dart --verify` ausführen: Version reisen_batch_5_v1 und SQLite-Hash oben müssen stimmen. Dann die App mit den neuen eingebetteten Assets über den bisherigen Entwicklungsweg neu bauen/installieren und neu starten; beispielsweise unter macOS `flutter run -d <iPhone-Geräte-ID>`. Nur ein Neustart eines unveränderten alten App-Builds übernimmt keine neuen Build-Assets. Keine Deinstallation oder Lernstandrücksetzung.

Im normalen App-Einstieg den Reisen-Stapel öffnen: 500 Primärwörter, Allgemeine Sprache weiterhin 160. Eine Reisen-Übung öffnen und Satz/Übersetzung/Wort-Tooltip kontrollieren; bestehende Lernstände müssen erhalten bleiben. Dieser manuelle Gerätetest ist noch offen und war für die Offline-Abnahme nicht erforderlich.

## Vollständige Satzpaar-Leseliste

Alle folgenden Paare einschließlich sämtlicher Worttokenbindungen gelesen. Unveränderte Original-Annotation in reisen_batch_5/annotation_review.txt, zwei lokale Tokenkorrekturen und eine Formglosse oben dokumentiert; verbindlicher Importstand in pipeline/data/curation/reisen_batch_5.editorial.json.

| Satz-ID | Englisch | Deutsch |
|---|---|---|
| reisen-v1-021-s1 | The traveller beside me is visiting Japan for the first time. | Der Reisende neben mir besucht Japan zum ersten Mal. |
| reisen-v1-022-s1 | My travel companion prefers a quiet hotel near the beach. | Meine Reisebegleitung bevorzugt ein ruhiges Hotel in Strandnähe. |
| reisen-v1-023-s1 | Our group is travelling together by train. | Unsere Gruppe reist gemeinsam mit dem Zug. |
| reisen-v1-024-s1 | Do you have a recommendation for a local restaurant? | Hast du eine Empfehlung für ein Restaurant in der Nähe? |
| reisen-v1-025-s1 | Please tell us your preference for a window or aisle seat. | Bitte sag uns, ob du lieber am Fenster oder am Gang sitzt. |
| reisen-v1-046-s1 | Hand luggage has a weight restriction on this flight. | Auf diesem Flug gilt eine Gewichtsbeschränkung für Handgepäck. |
| reisen-v1-047-s1 | Please open your suitcase for a customs inspection. | Bitte öffne deinen Koffer für eine Zollkontrolle. |
| reisen-v1-048-s1 | Keep your passport ready at the border checkpoint. | Halte deinen Reisepass an der Grenzkontrollstelle bereit. |
| reisen-v1-049-s1 | You need a valid passport for entry into this country. | Für die Einreise in dieses Land brauchst du einen gültigen Reisepass. |
| reisen-v1-050-s1 | The emergency exit is at the end of the corridor. | Der Notausgang ist am Ende des Flurs. |
| reisen-v1-071-s1 | Please listen to the announcement about our delayed flight. | Bitte hör dir die Durchsage zu unserem verspäteten Flug an. |
| reisen-v1-072-s1 | Please do not leave your baggage unattended at the station. | Bitte lass dein Gepäck am Bahnhof nicht unbeaufsichtigt stehen. |
| reisen-v1-073-s1 | My suitcase is too heavy to carry upstairs. | Mein Koffer ist zu schwer, um ihn nach oben zu tragen. |
| reisen-v1-074-s1 | Please collect your bags from the carousel near the exit. | Bitte hole deine Taschen vom Gepäckband in der Nähe des Ausgangs ab. |
| reisen-v1-075-s1 | We put our heavy suitcases on a luggage trolley. | Wir haben unsere schweren Koffer auf einen Gepäckwagen gestellt. |
| reisen-v1-096-s1 | The commuter beside me takes this train every morning. | Der Pendler neben mir nimmt jeden Morgen diesen Zug. |
| reisen-v1-097-s1 | A free shuttle runs between the airport and our hotel. | Zwischen dem Flughafen und unserem Hotel fährt ein kostenloser Shuttle. |
| reisen-v1-098-s1 | Scan your ticket to open the barrier at the station. | Scanne deine Fahrkarte, um die Zugangssperre am Bahnhof zu öffnen. |
| reisen-v1-099-s1 | Turn right at the next junction after the petrol station. | Biege an der nächsten Kreuzung nach der Tankstelle rechts ab. |
| reisen-v1-100-s1 | The airport is outside the central fare zone. | Der Flughafen liegt außerhalb der zentralen Tarifzone. |
| reisen-v1-121-s1 | Please show your driving licence before collecting the rental car. | Bitte zeige deinen Führerschein vor der Abholung des Mietwagens. |
| reisen-v1-122-s1 | The mechanic checks the steering before our long drive. | Der Mechaniker prüft vor unserer langen Fahrt die Lenkung. |
| reisen-v1-123-s1 | Please wear your seatbelt throughout the bus journey. | Bitte bleibe während der gesamten Busfahrt angeschnallt. |
| reisen-v1-124-s1 | Wear a helmet when you ride a bicycle. | Trag einen Helm, wenn du Fahrrad fährst. |
| reisen-v1-125-s1 | We stopped to repair a puncture in the bicycle tyre. | Wir haben angehalten, um ein Loch im Fahrradreifen zu flicken. |
| reisen-v1-146-s1 | Hold your keycard against the reader to unlock the door. | Halte deine Schlüsselkarte an das Lesegerät, um die Tür aufzuschließen. |
| reisen-v1-147-s1 | There is an electrical socket beside the bed. | Neben dem Bett gibt es eine Steckdose. |
| reisen-v1-148-s1 | I need an adapter for my British plug in Germany. | Ich brauche in Deutschland einen Adapter für meinen britischen Stecker. |
| reisen-v1-149-s1 | The heating in our room is not working. | Die Heizung in unserem Zimmer funktioniert nicht. |
| reisen-v1-150-s1 | Is there somewhere to wash our dirty laundry? | Gibt es hier eine Möglichkeit, unsere schmutzige Wäsche zu waschen? |
| reisen-v1-171-s1 | Could you bring a jug of water for the table? | Könnten Sie einen Krug Wasser für den Tisch bringen? |
| reisen-v1-172-s1 | The waiter put a clean napkin beside my plate. | Der Kellner hat eine saubere Serviette neben meinen Teller gelegt. |
| reisen-v1-173-s1 | Our table has plates but no cutlery. | Auf unserem Tisch stehen Teller, aber es gibt kein Besteck. |
| reisen-v1-174-s1 | Could you show me how to eat noodles with chopsticks? | Könntest du mir zeigen, wie man Nudeln mit Stäbchen isst? |
| reisen-v1-175-s1 | There is enough tea in the teapot for two cups. | In der Teekanne ist genug Tee für zwei Tassen. |
| reisen-v1-196-s1 | Could you add a sliced tomato to my sandwich? | Könnten Sie mein Sandwich zusätzlich mit einer aufgeschnittenen Tomate belegen? |
| reisen-v1-197-s1 | This soup contains onion, garlic and potato. | Diese Suppe enthält Zwiebeln, Knoblauch und Kartoffeln. |
| reisen-v1-198-s1 | Please pass the salt at your end of the table. | Bitte reich mir das Salz an deinem Ende des Tisches. |
| reisen-v1-199-s1 | Would you like some black pepper on your soup? | Möchten Sie etwas schwarzen Pfeffer auf Ihre Suppe? |
| reisen-v1-200-s1 | I drink my coffee with milk but no sugar. | Ich trinke meinen Kaffee mit Milch, aber ohne Zucker. |
| reisen-v1-221-s1 | Please check the amount before you enter your PIN. | Bitte prüfe den Betrag, bevor du deine PIN eingibst. |
| reisen-v1-222-s1 | I paid with a banknote and received five euros in change. | Ich habe mit einem Geldschein bezahlt und fünf Euro Wechselgeld bekommen. |
| reisen-v1-223-s1 | The hotel requires payment before we leave. | Das Hotel verlangt die Bezahlung vor unserer Abreise. |
| reisen-v1-224-s1 | Please keep the receipt as proof of your purchase. | Bitte bewahre den Beleg als Nachweis für deinen Kauf auf. |
| reisen-v1-225-s1 | The bank charged a fee for this card transaction. | Die Bank hat für diese Kartenzahlung eine Gebühr berechnet. |
| reisen-v1-246-s1 | We are going to the theatre to watch a play. | Wir gehen ins Theater, um uns ein Theaterstück anzusehen. |
| reisen-v1-247-s1 | We bought tickets for a jazz concert in the park. | Wir haben Karten für ein Jazzkonzert im Park gekauft. |
| reisen-v1-248-s1 | I bought this little wooden boat as a souvenir. | Ich habe dieses kleine Holzboot als Andenken gekauft. |
| reisen-v1-249-s1 | I sent my sister a postcard from the coast. | Ich habe meiner Schwester eine Postkarte von der Küste geschickt. |
| reisen-v1-250-s1 | This brochure shows the main sights and their opening times. | Diese Broschüre zeigt die wichtigsten Sehenswürdigkeiten und ihre Öffnungszeiten. |
| reisen-v1-271-s1 | We took plenty of water on our hike through the mountains. | Wir haben auf unsere Wanderung durch die Berge reichlich Wasser mitgenommen. |
| reisen-v1-272-s1 | We bought bread and cheese for a picnic by the lake. | Wir haben Brot und Käse für ein Picknick am See gekauft. |
| reisen-v1-273-s1 | Our journey through the rainforest was an unforgettable adventure. | Unsere Reise durch den Regenwald war ein unvergessliches Abenteuer. |
| reisen-v1-274-s1 | We watched the sunset from a quiet beach. | Wir haben uns den Sonnenuntergang an einem ruhigen Strand angesehen. |
| reisen-v1-275-s1 | We watched the sunrise from our hotel balcony. | Wir haben uns den Sonnenaufgang von unserem Hotelbalkon aus angesehen. |
| reisen-v1-296-s1 | Thick fog covered the road during our drive. | Während unserer Fahrt lag dichter Nebel über der Straße. |
| reisen-v1-297-s1 | There was a thin mist over the lake this morning. | Heute Morgen lag leichter Dunst über dem See. |
| reisen-v1-298-s1 | The high humidity makes our towels dry very slowly. | Durch die hohe Luftfeuchtigkeit trocknen unsere Handtücher sehr langsam. |
| reisen-v1-299-s1 | We stayed in the shade during the afternoon heat. | Während der Nachmittagshitze sind wir im Schatten geblieben. |
| reisen-v1-300-s1 | I wore gloves to protect my hands from the cold. | Ich habe Handschuhe getragen, um meine Hände vor der Kälte zu schützen. |
| reisen-v1-321-s1 | The captain welcomes us aboard the ship. | Der Kapitän heißt uns an Bord des Schiffes willkommen. |
| reisen-v1-322-s1 | A sailor helped us carry our bags onto the ship. | Ein Seemann hat uns geholfen, unsere Taschen auf das Schiff zu tragen. |
| reisen-v1-323-s1 | Ask the lifeguard whether it is safe to swim here. | Frag den Rettungsschwimmer, ob man hier sicher schwimmen kann. |
| reisen-v1-324-s1 | I breathe through a snorkel with my face in the water. | Ich atme durch einen Schnorchel, während mein Gesicht im Wasser ist. |
| reisen-v1-325-s1 | The crew threw a lifebuoy to the person in the water. | Die Besatzung hat der Person im Wasser einen Rettungsring zugeworfen. |
| reisen-v1-346-s1 | The pharmacist asks to see my prescription for this medicine. | Der Apotheker möchte mein Rezept für dieses Medikament sehen. |
| reisen-v1-347-s1 | The pharmacist explains how to take this tablet. | Der Apotheker erklärt, wie ich diese Tablette einnehmen soll. |
| reisen-v1-348-s1 | The nurse gave me an injection in my arm. | Die Pflegekraft hat mir eine Spritze in den Arm gegeben. |
| reisen-v1-349-s1 | The doctor examined my cut for signs of infection. | Der Arzt hat meine Schnittwunde auf Anzeichen einer Infektion untersucht. |
| reisen-v1-350-s1 | Please describe each symptom to the doctor. | Bitte beschreibe dem Arzt jedes Symptom. |
| reisen-v1-371-s1 | Please ask the station staff for assistance with your luggage. | Bitte das Bahnhofspersonal um Hilfe mit deinem Gepäck. |
| reisen-v1-372-s1 | Check whether your travel insurance covers medical treatment abroad. | Prüfe, ob deine Reiseversicherung medizinische Behandlungen im Ausland abdeckt. |
| reisen-v1-373-s1 | Read the policy to check your coverage for lost luggage. | Lies die Versicherungsbedingungen, um deinen Versicherungsschutz bei verlorenem Gepäck zu prüfen. |
| reisen-v1-374-s1 | I submitted a claim to my insurer for the stolen suitcase. | Ich habe wegen des gestohlenen Koffers einen Leistungsantrag bei meiner Versicherung eingereicht. |
| reisen-v1-375-s1 | Please report the loss of your passport to the police. | Bitte melde den Verlust deines Reisepasses bei der Polizei. |
| reisen-v1-396-s1 | We can ride the bus from the station to our hotel. | Wir können mit dem Bus vom Bahnhof zu unserem Hotel fahren. |
| reisen-v1-397-s1 | Can we rent a small apartment near the beach? | Können wir eine kleine Wohnung in Strandnähe mieten? |
| reisen-v1-398-s1 | We want to hire a car for the weekend. | Wir wollen für das Wochenende ein Auto mieten. |
| reisen-v1-399-s1 | You can park your car behind the hotel. | Du kannst dein Auto hinter dem Hotel parken. |
| reisen-v1-400-s1 | We must cross the road to reach the museum. | Wir müssen die Straße überqueren, um zum Museum zu gelangen. |
| reisen-v1-421-s1 | Do you prefer a window seat or an aisle seat? | Sitzt du lieber am Fenster oder am Gang? |
| reisen-v1-422-s1 | You need a ticket before you board this train. | Du brauchst eine Fahrkarte, bevor du in diesen Zug steigst. |
| reisen-v1-423-s1 | Do you want a room with a balcony? | Möchtest du ein Zimmer mit Balkon? |
| reisen-v1-424-s1 | Some countries require a visa for entry. | Für die Einreise in manche Länder ist ein Visum erforderlich. |
| reisen-v1-425-s1 | Can the hotel arrange a taxi for tomorrow morning? | Kann das Hotel für morgen früh ein Taxi organisieren? |
| reisen-v1-446-s1 | Can you deliver our luggage to the hotel? | Können Sie unser Gepäck zum Hotel liefern? |
| reisen-v1-447-s1 | Please weigh your suitcase on these scales. | Bitte wiege deinen Koffer auf dieser Waage. |
| reisen-v1-448-s1 | Please fasten your seatbelt before the bus leaves. | Bitte schnall dich an, bevor der Bus losfährt. |
| reisen-v1-449-s1 | Remember to lock the door before leaving your room. | Denk daran, die Tür abzuschließen, bevor du dein Zimmer verlässt. |
| reisen-v1-450-s1 | Turn the key to unlock the door. | Dreh den Schlüssel, um die Tür aufzuschließen. |
| reisen-v1-471-s1 | We spent three nights in a small coastal village. | Wir haben drei Nächte in einem kleinen Küstendorf verbracht. |
| reisen-v1-472-s1 | We chose a scenic route through the mountains. | Wir haben eine landschaftlich reizvolle Strecke durch die Berge gewählt. |
| reisen-v1-473-s1 | This historic building hosted the first meeting of our parliament. | In diesem historisch bedeutsamen Gebäude fand die erste Sitzung unseres Parlaments statt. |
| reisen-v1-474-s1 | The guide explains the cultural importance of this local festival. | Der Reiseleiter erklärt die kulturelle Bedeutung dieses örtlichen Festivals. |
| reisen-v1-475-s1 | Is the museum accessible to visitors who use wheelchairs? | Ist das Museum für Menschen im Rollstuhl barrierefrei zugänglich? |
| reisen-v1-496-s1 | Do you have a vegan dessert without milk, eggs or honey? | Haben Sie einen veganen Nachtisch ohne Milch, Eier oder Honig? |
| reisen-v1-497-s1 | I am allergic to nuts, so please check the ingredients. | Ich bin allergisch gegen Nüsse, bitte prüfe deshalb die Zutaten. |
| reisen-v1-498-s1 | My son is sick, so we cannot travel today. | Mein Sohn ist krank, deshalb können wir heute nicht reisen. |
| reisen-v1-499-s1 | We were thirsty after our long walk in the sun. | Nach unserem langen Spaziergang in der Sonne hatten wir Durst. |
| reisen-v1-500-s1 | I am hungry after our long walk through town. | Nach unserem langen Spaziergang durch die Stadt habe ich Hunger. |

## Abschließender Git-Abgleich

`git diff --check`: Exit 0, keine Whitespacefehler; ausschließlich Hinweis auf die konfigurierte spätere LF→CRLF-Umsetzung des Lesetests. `git status --short`: Exit 0. Vorhandene Importer-/Pipeline-Test-/deck_display-Änderungen stammen aus früheren Aufträgen und sind laut 738-Dateien-Baseline unverändert. Neu in diesem Auftrag: beide Batch-5-Curation-Dateien und Batch-5-Bericht; geändert: NEXTSTEPS, Authoring-Abschlussstatus und ausschließlich die Lesetest-Erwartung 400→500 (Bytevergleich gegen Baseline bestätigt). out-/build-/Assetdateien sind lokal vorhanden und ignoriert. Kein Commit oder Push.
