# Chat-Sprachredaktion: Offline-Import (04.10.2026)

**Aktueller Stand – Offline-Abschluss:** `chat_editorial_finish_v1` ist vollständig exportiert und als internes App-Asset gestagt. 264 Karten / 792 Satzzuordnungen, 17 offene Tokens und sechs Linterstellen behoben, null Linterfehler / 150 Häufigkeitswarnungen. Die folgenden Abschnitte dokumentieren den unveränderten Erstlauf; der Abschluss mit Entscheidungen und Prüfbelegen steht am Ende.

**Historischer Erstlauf: gespeicherter Arbeitsstand, damals kein fertiger Export.** Alle 190 Satz- und 10 Metadatenoperationen sind angewendet. 17 Token-Zuordnungen in zehn neuen Sätzen und sechs Linterstellen verhindern die Fertigstellung. `pack.json` und `content.sqlite` wurden im neuen Ordner nicht erzeugt; nichts gestagt oder installiert.

## Quelle, Umfang und Herkunft

- Quelle: `pipeline/out/curated_everyday_v1/pack.json`, unverändert, SHA-256 `2028784d08af961a9b35769f7ab62aff4ac2bfe2b03a999dccc5a05e4786a9f9`.
- Austauschdateien: `editorial_review/corrections.json`, `reviewed_sentences.json`, Read-only-Validator und `review.html`. Das HTML ist die lesbare Darstellung, die JSON-Dateien liefern die gebundenen Operationen.
- Die gelieferte Sprachredaktion ist eine **ChatGPT-Modellprüfung**, keine menschliche Freigabe und kein Vertex-Test. Ihre dokumentierte Vollprüfung betrifft 792 EN/DE-Paare, 150 ursprüngliche Alternativen und 264 Kartenbedeutungen. Die 8.520 ursprünglichen Tokens und 2.378 Wörterbuchschlüssel waren ausdrücklich nicht vollständig sprachredigiert.
- Korpusabgleich: 137 Englisch-Ersetzungen + 48 Übersetzungsänderungen (teils mit Alternativen) + 5 reine Alternativenänderungen = 190; dazu 596 unverändert und 6 Rückstellungsempfehlungen = **792/792**. Jede Referenz ist genau einmal abgedeckt.
- Lokaler zusätzlicher Prüfumfang: alle 137 neuen EN/DE-Kontexte und ihre 1.322 Worttokens gelesen; 1.305 konkrete Entscheidungen, 17 ausdrücklich offen. Diese Annotation ist eine lokale Codex-Modellprüfung. Keine neue Vollprüfung der 655 englisch unveränderten Sätze oder aller Hintergrundbedeutungen behauptet.
- Cloud-/Vertex-Aufrufe: **0**, zusätzliche Pipeline-Kosten: **0 USD**. Generierungsmodelle, Tokenlimits, Inventar, Auswahl und ursprüngliche out-Läufe wurden nicht geändert.

## Reproduzierbarer Weg

`pipeline/scripts/import_editorial_patch.py` überprüft Roh-/kanonischen Hash, vollständige Satz-/Link-Vorbedingungen, IDs, doppelte Operationen und Korpusabdeckung. Die versionierte Adaption steht in `pipeline/data/curation/chat_editorial_v1.json` einschließlich 1.305 an neue Satz-ID und Tokenindex gebundener Entscheidungen sowie exakter offener Einträge. Keine unscharfe Zuordnung. Andere JSON-Einrückung ist nur bei identischem kanonischem Hash und identischen Einzelvorbedingungen zulässig.

`sprachpipe.curate.curate` verarbeitet die expliziten `editorial_sentence`-Operationen und Metadatenkorrekturen. Neue Lücken entstehen mit `gap_offsets`, IDs mit `ids.stable_id`, Tokens mit `annotate.tokenize`; neue explizite Formglossen verwenden `_token_rows` aus `complete_curation.py`. Wörterbuchableitung bleibt `derive_dictionary`; ein später fertiger Export verwendet `finalize`, `build_rows`, `export_sqlite` und den bestehenden Vollvergleich `check_sqlite`. Der vorhandene Vertex-Finalisierer wird nicht durch fingierte `qa_status=ok`-Urteile überlistet.

- Englisch geändert: 137 neue Satz-/Link-ID-Paare; alte Tokens entfernt, Audio des alten Satzes nur noch in der Historie, `model=null`. `qa_status=editorial_reviewed` und `qa_report.editorial` binden genau den neuen Text, die Übersetzung, Lücke und explizite Alternativenliste. Kein alter Blindtest/Bedeutungscheck wird als neuer Erfolg ausgegeben.
- Englisch unverändert: 655 Satz-IDs und ihre englischen Tokenzeilen erhalten. Bei redaktionellen Änderungen bleibt die alte Modell-QA im Änderungslog historisch; die aktuelle redaktionelle Entscheidung trägt ihre eigene Herkunft.
- 264 Karten-IDs, alle `accepted[]`-Zielformen sowie Stapelzuordnung und -reihenfolge unverändert. Drei Sätze pro Karte. 8.483 aktuelle Tokenzeilen auf Offsets/Referenzen geprüft; neue Tokens vollständig tokenisiert, unentschiedene Wortzuordnungen ausdrücklich leer und exportgesperrt.
- Die 190 alten Satz-/Linkzeilen samt QA, bei Englischänderung auch Tokens/Audio, stehen zusätzlich zur unberührten Originaldatei in `import_report.json → curation_log`. Unveränderte Karten werden nicht umnummeriert; Lernstände werden nicht geöffnet oder geschrieben.
- Finale Alternativen im Arbeitsstand: 138, davon 128 außerhalb der zwei zurückzustellenden Karten und 10 auf deren sechs unveränderten Sätzen. Empfehlungen sind noch nicht angewendet. Alte Alternativen werden nie automatisch wieder hinzugefügt.

## Metadaten – genau zehn Operationen

Geteilte Senses wurden jeweils einmal geändert. Die folgende Liste zeigt alle betroffenen Karten, ohne Form-/POS-/Sense-Key-Änderung. Metadaten werden nicht als Formübersetzung in dictionary_forms kopiert.

| Tabelle/Feld, Referenz                                     | Neuer Wert                                                               | Betroffene Karten                                                             |
| ---------------------------------------------------------- | ------------------------------------------------------------------------ | ----------------------------------------------------------------------------- |
| senses.gloss_de / have/VERB\|have#besitzen                 | besitzen oder über etwas verfügen (Vollverb)                             | has\|have/VERB\|have#besitzen; have\|have/VERB\|have#besitzen                 |
| cards.translation_de / they\|they/PRON\|they#singular_they | die Person (geschlechtsneutrales „they“)                                 | they\|they/PRON\|they#singular_they                                           |
| senses.gloss_de / more/ADV\|more#wieder_noch               | mehr in „not ... any more“ oder „no more“: nicht länger, nicht weiterhin | more\|more/ADV\|more#wieder_noch                                              |
| senses.gloss_de / be/AUX\|be#hilfsverb                     | sein/werden als Hilfsverb zur Bildung von Verlaufsformen und Passiv      | was\|be/AUX\|be#hilfsverb; be\|be/AUX\|be#hilfsverb; is\|be/AUX\|be#hilfsverb |
| senses.gloss_de / spoon/NOUN\|spoon#loeffel                | Besteck mit einer kleinen Mulde zum Essen, Schöpfen oder Umrühren        | spoon\|spoon/NOUN\|spoon#loeffel                                              |
| senses.gloss_de / drink/VERB\|drink#trinkt                 | Flüssigkeit zu sich nehmen                                               | drink\|drink/VERB\|drink#trinkt                                               |
| cards.translation_de / box\|box/NOUN\|box#schachtel        | Kiste / Schachtel / Karton                                               | box\|box/NOUN\|box#schachtel                                                  |
| senses.gloss_de / drive/VERB\|drive#faehrt                 | ein Fahrzeug steuern; jemanden mit einem Fahrzeug befördern              | drive\|drive/VERB\|drive#faehrt                                               |
| senses.gloss_de / cook/VERB\|cook#kocht                    | Speisen durch Erhitzen zubereiten                                        | cook\|cook/VERB\|cook#kocht                                                   |
| senses.gloss_de / cut/VERB\|cut#schneidet                  | etwas mit einer scharfen Klinge teilen oder einschneiden                 | cut\|cut/VERB\|cut#schneidet                                                  |

## Annotation: genaue Restliste

137 Sätze / 1.495 Tokens: 173 Satzzeichen sind vollständig; 1.305 Worttokens sind explizit zugeordnet (1.078 bestehende Formglossen, 227 neu kontextuell formulierte Annotationen). 127 Sätze sind vollständig annotiert; zehn enthalten folgende 17 offene Tokens. Keine Übernahme der ersten Wörterbuchbedeutung. Kandidaten einschließlich exakter Varianten stehen in `open_annotations.json`.

| Operation / Originalreferenz / neue Satz-ID                                | Neuer englischer Satz                                          | Index: Token | Offener Punkt                                                                                                          |
| -------------------------------------------------------------------------- | -------------------------------------------------------------- | ------------ | ---------------------------------------------------------------------------------------------------------------------- |
| sentence-10.1 / pilot/pilot_60_v1/s28 / a8054e8137e5ed48fd1cad2fdeb06821   | With everyone else away, our house feels all the quieter.      | 0: With      | with everyone else away: adverbiale Umstandsangabe; Präpositionsglosse gegenüber deutschem Kausalsatz klären.          |
| sentence-17.1 / pilot/pilot_60_v1/s49 / 8b54a36d4250811a4a9bc0d59a121ea8   | Lina was taking a test when the school bell rang.              | 2: taking    | taking a test: kontextspezifische Formglosse und Verbkonstruktion fehlen; nicht einnehmen übernehmen.                  |
| sentence-60.1 / pilot/pilot_60_v1/s178 / ca7572aed4630fad7c04ac4e5b75451d  | Sara will time her arrival to avoid the rush hour.             | 8: rush      | rush hour: Zuordnung beider Einzelwörter zur Gesamtbedeutung Berufsverkehr/Hauptverkehrszeit klären.                   |
| sentence-60.2 / pilot/pilot_60_v1/s179 / 97a4f9e7eb9e268af4c9b9fde09eae84  | Eva will time the cooking so that everything is ready at once. | 10: at       | at once: Mehrwortbedeutung gleichzeitig ist nicht die Einzelwortbedeutung von at.                                      |
| sentence-60.2 / pilot/pilot_60_v1/s179 / 97a4f9e7eb9e268af4c9b9fde09eae84  | Eva will time the cooking so that everything is ready at once. | 11: once     | at once: gleichzeitig statt einmal; konkrete Einzelwortannotation offen.                                               |
| sentence-97.2 / pilot/pilot_60_v1/s293 / ce7b5cd8d024f281e4cac74f4f6f21fc  | Leo has been happy with his new bike so far.                   | 8: so        | so far: bisher, nicht Zielbedeutung auf diese Weise; Einzelwortannotation offen.                                       |
| sentence-97.2 / pilot/pilot_60_v1/s293 / ce7b5cd8d024f281e4cac74f4f6f21fc  | Leo has been happy with his new bike so far.                   | 9: far       | so far: bisher; bisherige weit-Glosse allein passt nicht zum Zeitkontext.                                              |
| sentence-129.3 / pilot/pilot_60_v1/s390 / 2b7ed0b22b021f6d247da3f5113097b6 | David kept walking on until he reached the station.            | 1: kept      | kept walking: Fortsetzung einer Handlung, nicht behielt; Form-/Konstruktionszuordnung offen.                           |
| sentence-152.3 / pilot/pilot_60_v1/s459 / 9cd33d1c06a8282c5659dcc1fecd6c4c | David walks so fast that I cannot keep up.                     | 8: keep      | keep up: mithalten; bestehende aufbewahrt-Glosse ist falsch, Einzelwortkonvention offen.                               |
| sentence-152.3 / pilot/pilot_60_v1/s459 / 9cd33d1c06a8282c5659dcc1fecd6c4c | David walks so fast that I cannot keep up.                     | 9: up        | keep up: Verbpartikel; räumliches hinauf/entlang ist falsch.                                                           |
| sentence-155.3 / pilot/pilot_60_v1/s468 / 0613055c02c1d6b356f216140d3481c1 | In this library, you must keep your voice down.                | 6: keep      | keep your voice down: leise sprechen; exakte tokenbezogene Glosse offen.                                               |
| sentence-155.3 / pilot/pilot_60_v1/s468 / 0613055c02c1d6b356f216140d3481c1 | In this library, you must keep your voice down.                | 9: down      | keep your voice down: down beschreibt die Lautstärke, nicht auf.                                                       |
| sentence-253.3 / missing/s6 / ea74c9984b08ed0899af0997bfc986b7             | Sara's grandfather is very old but still lives on his own.     | 9: on        | on his own: allein; eigenständige Zuordnung der Präposition ohne Satzphrasen-Fallback offen.                           |
| sentence-253.3 / missing/s6 / ea74c9984b08ed0899af0997bfc986b7             | Sara's grandfather is very old but still lives on his own.     | 10: his      | on his own: possessive/reflexive Konstruktion; nicht schlicht seine übernehmen.                                        |
| sentence-253.3 / missing/s6 / ea74c9984b08ed0899af0997bfc986b7             | Sara's grandfather is very old but still lives on his own.     | 11: own      | on his own: exakte Einzelwortbedeutung/Glosse für own offen.                                                           |
| sentence-257.2 / missing/s17 / 02efec231c11596a33ffe0d47d4b0d33            | Is Luca too young to get a driving licence?                    | 7: driving   | driving licence: Nominalattribut oder Gerundium; konkrete Zuordnung zur Fahrberechtigung offen.                        |
| sentence-257.2 / missing/s17 / 02efec231c11596a33ffe0d47d4b0d33            | Is Luca too young to get a driving licence?                    | 8: licence   | driving licence: vorhandene Einwort-Glosse fehlt; Gesamtbedeutung Führerschein nicht ungeprüft auf licence übertragen. |

## Wörterbuch

`derive_dictionary` liefert für die bereits zugeordneten Tokens **2.312 Schlüssel, 0 fehlende Formglossen, 0 ungelöste Glossenkonflikte**. Das ist ausdrücklich ein Teilstand: Die 17 offenen Tokens fehlen noch in der abschließenden Ableitung. `working_state.json.dictionary_forms` bleibt leer und `dictionary_forms` bleibt als notwendiger Schritt offen.

Zwei durch neue, konkrete Kontextglossen entstandene Konflikte wurden mit exakten Vorbedingungen versioniert gelöst; frühere Merge-Entscheidungen werden nicht wieder aus den historischen Quellläufen geöffnet:

| Form / Sense                    | Exakte Varianten                            | Entscheidung und Grund                                                                                                                                                                                             |
| ------------------------------- | ------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| safe / safe/ADJ\|safe#sicher    | Keiner konkreten Gefahr ausgesetzt / sicher | sicher: Neue Kontextannotation: sicher passt als konkrete Formübersetzung in allen sechs verbleibenden safe-Kontexten (Personen, Aufbewahrungsort und Fahrkarte). Die alte Bedeutungsbeschreibung bleibt Herkunft. |
| stone / stone/NOUN\|stone#stein | Stein- / Stein                              | Stein: Konkrete Nomenform: Stein ist als Einzelwortglosse sowohl für stone bridge als auch small stone passend. Die Kompositionsschreibweise Stein- ist im neuen eigenständigen Nomenkontext unpassend.            |

## Vollständiger Linter: sechs Fehler bleiben blockierend

Alle 792 aktuellen Sätze wurden mit dem vorhandenen spaCy-/Zipf-Linter und unveränderter Konfiguration geprüft: **6 errors, 151 warnings**. Sämtliche Warnungen sind `i+1`-Häufigkeitswarnungen; sie sind separat in `import_report.json` und im vollständigen `lint_output.txt` erhalten. Keine Warnung wird als Grammatikfehler umgedeutet.

| Originalreferenz       | Unverändert übernommener Ersatztext                                           | Konkreter Befund                                                                                                                                       |
| ---------------------- | ----------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| pilot/pilot_60_v1/s47  | Rosa wants to water the flowers; please bring her the watering can.           | Parser-Fehlanalyse: wants wird als ccomp von bring, can (Substantiv in watering can) als advcl erkannt. Der Semikolon-Hauptsatz wird falsch angehängt. |
| pilot/pilot_60_v1/s203 | Ali asks if the heating is on because the room feels cold.                    | Tatsächlicher Regelkonflikt: if the heating is on (ccomp) und because the room feels cold (advcl) ergeben zwei Nebensätze bei Maximum 1.               |
| pilot/pilot_60_v1/s229 | Someone left a phone here; I hope they come back for it.                      | Parser-Fehlanalyse: left vor dem Semikolon wird als ccomp von hope angehängt; come ist der tatsächliche Inhaltssatz.                                   |
| pilot/pilot_60_v1/s243 | When David was asked if he wanted more coffee, he said no.                    | Tatsächlicher Regelkonflikt: When David was asked (advcl) enthält if he wanted more coffee (ccomp); zwei gezählte Nebensätze.                          |
| pilot/pilot_60_v1/s268 | Her grandmother makes wonderful soup; Mia hopes hers will taste just as good. | Parser-Fehlanalyse: makes vor dem Semikolon wird als ccomp von hopes angehängt; taste ist der tatsächliche Inhaltssatz.                                |
| pilot/pos_check_v1/s9  | Here are two cakes; Zoe wants to know which tastes better.                    | Parser-Fehlanalyse: are im selbständigen Here-are-Hauptsatz wird als ccomp von wants angehängt; tastes ist die eingebettete Auswahlfrage.              |

Die vier Parserbefunde wurden lokal eingeordnet, aber nicht durch Ausnahmen freigeschaltet. Die zwei tatsächlichen Regelkonflikte erfordern eine gezielte redaktionelle/Regelentscheidung; die gelieferten fertigen Texte wurden nicht eigenmächtig umgeschrieben.

## Zwei Empfehlungen: vorbereitet, nicht angewendet

`hold_recommendations.json` enthält beide stabilen Karten-IDs, die exakten aktuellen Stapelzeilen und jeweils drei Satzreferenzen/-texte. Vorgeschlagene Aktion: aus dem Anfänger-Stapel nehmen, Inhalte und Lernverlauf erhalten.

| Karte                          | Karten-ID                        | Position im Stapel allgemeine-sprache | Status                                |
| ------------------------------ | -------------------------------- | ------------------------------------- | ------------------------------------- |
| so\|so/ADV\|so#auf_diese_weise | 1bbe26267773ad288ddd7bf7063c4437 | 70                                    | Empfehlung offen; keine Datenänderung |
| like\|like/ADV\|like#fuellwort | 7e36dbaded1247f91a76a6577dfe5345 | 152                                   | Empfehlung offen; keine Datenänderung |

Der bestehende Weg verlangt genau eine Stapelzuordnung pro Karte (`curate.py`); `build_rows` transportiert `removed_in/replaced_by` derzeit nicht. Eine bloße Entnahme aus `deck_cards` würde neue Auswahl und direkten Stapelablauf ändern, **bereits gesehene fällige/early Karten in Gemischt aber weiterhin zulassen**. Die globalen Zähler würden existierende aktive Kartenstände (auch Box 0) weiterhin berücksichtigen; nur noch nie angelegte Karten verlören ihre Zugehörigkeit über den aktiven Stapel. Stapelzähler würden sich dagegen an der Mitgliedschaft ändern. Nutzer-Deaktivierung oder Retirierung wäre ein Eingriff in user.db und ist nicht vorgenommen worden. Es existiert somit kein kompatibler, rein inhaltsseitiger Ausschluss für alle gewünschten Flächen. Keine neue App-/Schemafunktion nur für diese zwei Karten gebaut.

## Artefakte und tatsächliche Prüfungen

Neuer Ordner: `pipeline/out/chat_editorial_v1_working_20261004/`. Enthält `working_state.json`, `import_report.json`, `annotation_review.json`, `open_annotations.json`, `dictionary_report.json`, `hold_recommendations.json`, `lint_output.txt`. Alte out-Artefakte bleiben unverändert; lokale Zwischenstände liegen ausschließlich unter `build/editorial_import/`. Vorhandene Ausgabeordner werden vor jeder Mutation abgewiesen.

Windows PowerShell, Repository-Root – tatsächlich ausgeführt:

```powershell
.\pipeline\.venv\Scripts\python.exe -X utf8 editorial_review\verify_editorial_patch.py --source pipeline\out\curated_everyday_v1\pack.json
.\pipeline\.venv\Scripts\python.exe -X utf8 pipeline\scripts\import_editorial_patch.py --out pipeline\out\chat_editorial_v1_working_20261004
.\pipeline\.venv\Scripts\python.exe -X utf8 -m sprachpipe.cli lint pipeline\out\chat_editorial_v1_working_20261004\working_state.json
.\pipeline\.venv\Scripts\python.exe -m pytest -q pipeline\tests
git diff --check
git status --short
```

macOS Terminal – entsprechende Befehle, hier nicht ausgeführt:

```sh
./pipeline/.venv/bin/python editorial_review/verify_editorial_patch.py --source pipeline/out/curated_everyday_v1/pack.json
./pipeline/.venv/bin/python pipeline/scripts/import_editorial_patch.py --out pipeline/out/chat_editorial_v1_working_20261004
./pipeline/.venv/bin/python -m sprachpipe.cli lint pipeline/out/chat_editorial_v1_working_20261004/working_state.json
./pipeline/.venv/bin/python -m pytest -q pipeline/tests
git diff --check
git status --short
```

Der dokumentierte Ausgabeordner existiert nach diesem Lauf und wird bei erneutem Aufruf verweigert; für eine spätere konkrete Revision ist ein neuer Ordner nötig.

```text
VALIDATION OK; source_sha256_exact: true; cards: 264; sentences: 792
sentence_operations: 190; metadata_operations: 10; unchanged_source: true
status working_state: 264 cards, 792 sentence pairs; 190 sentence / 10 metadata operations
annotation: 137 changed English sentences; 1495 tokens; 1305 resolved words; 17 open words; 173 punctuation
lint: 792 sentences, 6 errors, 151 warnings
dictionary: 2312 resolved keys, 0 missing, 0 conflicts; complete=False
cloud calls 0; cost 0 USD
Adapter exit 1 (Arbeitsstand); vollständiger CLI-Linter: 6 error(s), exit 1
301 passed in 10.28s
```

Der mitgelieferte Read-only-Validator meldet weiterhin `new_english_annotation_status: not_done` und `spacy_zipf_and_runtime_tests: not_run`: Das sind feste Scope-Angaben dieses Quellvalidators, keine Auswertung des neuen Arbeitsstands. Den tatsächlichen Stand liefern die Adapter-/Linterberichte oben.

Gezielte neue Tests sichern Quellbindung, kanonische Neuformatierung, doppelte Operationen, Korpuslücken, historische QA/Audio, unveränderte Token/IDs, fehlende Annotation trotz eindeutiger Oberflächenkandidaten, stale Tokenentscheidungen, den vorhandenen Formglossen-Konstruktor und einen gesperrten Export aus Teilständen ab. Kleine synthetische Daten, keine Testabhängigkeit vom großen out-Pack.

App-Asset SHA-256 unverändert: `ebc12c0d0ba4909cc070e7f1d2e9c27c08fc3744bb7317d781c8af4b1d1df9a5`. Flutter/UI, user.db, Reviews, SRS, Modelle und Secrets unangetastet; keine Flutter-Tests, Cloud-Aufrufe, Commits oder Pushes. Bestehende gestagte/ungestagte Änderungen aus vorherigen Aufgaben erhalten.

## Damals nächster gebündelter Schritt (inzwischen ausgeführt)

Gezielt die **17 gelisteten Token-Konventionen und sechs Linterstellen** entscheiden, anschließend denselben Offline-Adapter mit ergänzten exakten Entscheidungen in einen neuen Ordner ausführen. Keine Vollgenerierung, kein Budgetanstieg. Die zwei Kartenempfehlungen bleiben eine getrennte offene Produkt-/Kompatibilitätsentscheidung. Staging/Installation ist erst nach einem tatsächlich vollständigen, validierten Export sinnvoll; dieser liegt noch nicht vor.

## Offline-Abschluss mit chat_editorial_finish_v1 (04.10.2026)

Der Folgeauftrag wurde vollständig offline auf den gespeicherten Erstlauf angewandt. Dessen **264 Karten, 792 Satzzuordnungen, 17 offene Tokens in zehn Sätzen und sechs Linterfehler** wurden vorab bestätigt. Keine neue Vollredaktion, Generierung oder Pipeline-Modellprüfung. Alle 17 geschützten Quelldateien in `editorial_review/`, `pipeline/out/curated_everyday_v1/` und `pipeline/out/chat_editorial_v1_working_20261004/` sind per SHA-256 bytegleich zum Ausgangssnapshot.

### Reproduzierbarkeit und Herkunft

`pipeline/data/curation/chat_editorial_finish_v1.json` bindet den unveränderten Basisplan und alten Arbeitsstand jeweils per kanonischem SHA-256. Jede der sechs Ersetzungen prüft zusätzlich Quellreferenz, vorherige stabile Satz-ID sowie sämtliche erwarteten Text-/Lücken-/Antwortfelder. Die 17 früher offenen Entscheidungen sind vollständig erfasst; eine zusätzliche explizite Ersetzung korrigiert `hour`. Die sechs neuen Fassungen haben **64 frisch gelesene Worttokens**, zusammen mit den 17 offenen Tokens **81 neue Entscheidungen**. Hinzu kommt die gebundene hour-Korrektur. Entscheidungen der sechs vorherigen Fassungen werden vollständig verworfen, auch bei gleicher Wortoberfläche. Alte Text-/Token-/QA-Zeilen bleiben nur unter `finish.superseded_editorial_history` im Bericht; die ursprüngliche Modellhistorie bleibt im Curation-Log.

Der Adapter baut die Operationen erneut aus den Originalquellen auf und nutzt weiterhin `curate`, `tokenize`, `gap_offsets`, `stable_id`, `derive_dictionary`, `finalize`, `build_rows`, `export_sqlite` und `check_sqlite`. Kein zweites ID-System, keine wiederverwendete aktuelle Modell-QA. Provenienz: gelieferte ChatGPT-Redaktion, explizite Nutzerentscheidungen und lokale Codex-Annotation; **keine menschliche Gesamtfreigabe, keine neue Vertex-Prüfung**. Null Cloud-/Vertex-Aufrufe, zusätzliche Pipeline-Kosten **0 USD**.

### Kontextentscheidungen

Neue Wörterbuch-Senses speichern `definition_de` getrennt von `senses.gloss_de` und der konkreten Formglosse in `dictionary_forms.gloss_de`. Alle 16 neuen Definitionen sind im Pack und SQLite erhalten. Bestehende passende Senses werden wiederverwendet; keine geteilte Bedeutung wird überschrieben, keine Lernkarte angelegt. Wendungsglossen erklären ausdrücklich ihre kontextuelle Verwendung.

| Operation / Tokenindex              | Form    | Zugeordnete Bedeutung              | Konkrete Formglosse                                               |
| ----------------------------------- | ------- | ---------------------------------- | ----------------------------------------------------------------- |
| sentence-10.1 / 0                   | With    | `with/ADP\|with#umstand`           | hier: weil alle anderen weg sind (With everyone else away)        |
| sentence-17.1 / 2                   | taking  | `take/VERB\|take#pruefung_ablegen` | einen Test schreibend (taking a test)                             |
| sentence-60.1 / 8                   | rush    | `rush/NOUN\|rush#andrang`          | hier Teil von rush hour (= Hauptverkehrszeit)                     |
| sentence-60.2 / 10                  | at      | `at/ADP\|at#at_once`               | hier Teil von at once (= gleichzeitig)                            |
| sentence-60.2 / 11                  | once    | `once/ADV\|once#gleichzeitig`      | hier Teil von at once (= gleichzeitig)                            |
| sentence-97.2 / 8                   | so      | `so/ADV\|so#so_far_zeit`           | hier Teil von so far (= bisher / bis jetzt)                       |
| sentence-97.2 / 9                   | far     | `far/ADV\|far#so_far_zeit`         | hier Teil von so far (= bisher / bis jetzt)                       |
| sentence-129.3 / 1                  | kept    | `keep/VERB\|keep#fortsetzen`       | fuhr fort (kept walking on = ging weiter)                         |
| sentence-152.3 / 8                  | keep    | `keep/VERB\|keep#keep_up`          | hier Teil von keep up (= mithalten)                               |
| sentence-152.3 / 9                  | up      | `up/ADV\|up#keep_up`               | hier Teil von keep up (= mithalten)                               |
| sentence-155.3 / 6                  | keep    | `keep/VERB\|keep#halten`           | halten                                                            |
| sentence-155.3 / 9                  | down    | `down/ADV\|down#leise`             | hier Teil von keep your voice down (= leise sprechen)             |
| sentence-253.3 / 9                  | on      | `on/ADP\|on#on_own`                | hier Teil von on his own (= allein)                               |
| sentence-253.3 / 10                 | his     | `his/DET\|his#sein`                | Possessivartikel (gehört einer männlichen Person oder einem Tier) |
| sentence-253.3 / 11                 | own     | `own/ADJ\|own#on_own`              | hier Teil von on his own (= allein)                               |
| sentence-257.2 / 7                  | driving | `driving/NOUN\|driving#autofahren` | hier Teil von driving licence (= Führerschein / Fahrerlaubnis)    |
| sentence-257.2 / 8                  | licence | `licence/NOUN\|licence#erlaubnis`  | hier Teil von driving licence (= Führerschein / Fahrerlaubnis)    |
| sentence-60.1 / 9 (Zusatzkorrektur) | hour    | `hour/NOUN\|hour#tageszeit`        | hier Teil von rush hour (= Hauptverkehrszeit)                     |

`keep` in `keep your voice down` verwendet die bestehende Bedeutung `keep#halten`. `your` (eigene bei unpersönlichem you) und `voice` (Stimme) sind konsistent und bleiben erhalten. `his#sein` ist der vorhandene maskuline Possessivbegleiter; sein Bezugswort ist ausdrücklich Saras Großvater. `walking` (gehend) und `on#weiter` passen zu `kept walking on`. `hour` wurde von der einzelnen Stunde auf einen charakteristischen Tageszeitabschnitt präzisiert. `driving` bleibt Autofahren als nominaler Bestimmungsbestandteil, kein eigenständiges Synonym für Führerschein.

In den neuen sechs Sätzen wurden alle Wortarten kontextuell gelesen: `tastes` bleibt auch nach `grandmother's` ein Verb (Parser schlägt dort NOUN vor); `better` nach `tastes` ist der prädikative Komparativ von `good` (ADJ). Die passende vorhandene Sense `good#gut` bekommt die zusätzliche Formglosse `better → besser`. `left`, `may` und `back` verwenden dieselben passenden Wörterbuch-IDs wie andere bereits annotierte Redaktionskontexte. Keine automatische Auswahl nach Parserlabel oder erster Wörterbuchvariante.

### Sechs Ersatzfassungen

Alle sechs **exakt vorgegebenen** Fassungen bestehen den Linter. Keine zusätzliche Vereinfachung oder Regeländerung nötig. `accepted` enthält jeweils allein die Zielform; `valid_alternatives` ist bei diesen sechs Sätzen leer. Satz-, Link- und Token-IDs werden über die bestehenden Funktionen neu berechnet.

- `pilot/pilot_60_v1/s47` / `sentence-16.2`: `33e8c32907dd3a0c719eb73b9686cf6a` → `618e9cfe6d4d6a61b866bfea16cd8d49`.
  - EN: Rosa is in the garden, so please bring her some water.
  - DE: Rosa ist im Garten, also bring ihr bitte etwas Wasser.
  - Lücke [39, 42): `her`.
- `pilot/pilot_60_v1/s203` / `sentence-67.2`: `24b64544b03a67c04bbc1f5b44177393` → `23952665d725b8b44173f6202d522c46`.
  - EN: The room feels cold, but the heating is on.
  - DE: Im Zimmer fühlt es sich kalt an, aber die Heizung ist an.
  - Lücke [40, 42): `on`.
- `pilot/pilot_60_v1/s229` / `sentence-76.1`: `56c54f084a365e5270e134770783172e` → `3fb5289da8fd75df33c39330f38cf6b1`.
  - EN: Someone left a phone here, but they may come back for it.
  - DE: Jemand hat hier ein Handy liegen lassen, kommt aber vielleicht zurück, um es abzuholen.
  - Lücke [31, 35): `they`.
- `pilot/pilot_60_v1/s243` / `sentence-80.3`: `11a462e361601415f6acaab7c80caa80` → `3b4e90310fcc778f3b410e77d88ba2de`.
  - EN: David said no when I offered him more coffee.
  - DE: David sagte nein, als ich ihm noch Kaffee anbot.
  - Lücke [11, 13): `no`.
- `pilot/pilot_60_v1/s268` / `sentence-89.1`: `6c3dcc97d32e5db94920853bcb0bdcd1` → `e35bc358ebd891732c69daa54f5e659e`.
  - EN: Mia makes wonderful soup, and her grandmother's tastes just as good.
  - DE: Mia kocht wunderbare Suppe, und die ihrer Großmutter schmeckt genauso gut.
  - Lücke [60, 62): `as`.
- `pilot/pos_check_v1/s9` / `sentence-163.3`: `ecbc39906048ffd9736e830d02ed2920` → `cfb0fc0b9b56d7630ee43912ff7df883`.
  - EN: Zoe has two cakes but cannot decide which tastes better.
  - DE: Zoe hat zwei Kuchen, kann sich aber nicht entscheiden, welcher besser schmeckt.
  - Lücke [36, 41): `which`.

### Vollständige technische Prüfung und Export

- Neuer Ausgabeordner: `pipeline/out/chat_editorial_finish_v1/`; vorhandene Ausgabeordner werden abgewiesen.
- 264 eindeutige Karten, **alle Karten-IDs und Stapelpositionen unverändert**, 792 eindeutige Sätze/Satzzuordnungen, genau drei je Karte.
- 137 gegenüber dem Quellpack neue Satz-/Link-IDs, 655 erhaltene Satz-IDs. Die sechs Folgekorrekturen liegen innerhalb dieser 137.
- 8.474 Token-Spans und Referenzen geprüft. Zusätzlicher vollständiger Abgleich aller Worttokens: **0 fehlende Sense-Zuordnungen**.
- Annotation der 137 geänderten englischen Sätze: 1.486 Tokens = 1.314 zugeordnete Wörter + 172 Satzzeichen; 0 offen.
- Wörterbuch: **2.323 Schlüssel**, 0 fehlende Glossen, 0 Konflikte. Die vorherigen expliziten Entscheidungen für safe und stone bleiben erhalten. Keine weiteren Glosskonflikte entstanden.
- Vollständiger Linter: **792 Sätze, 0 errors, 150 i+1 warnings**. Warnungen betreffen Worthäufigkeit, keine gezählten Grammatikfehler; alle in `import_report.json`, vollständiger CLI-Output in `build/editorial_finish/lint_output.txt`.
- SQLite nach Export erneut geöffnet und alle fachlichen Spalten sämtlicher Tabellen mit `build_rows` verglichen. Wie beim bestehenden Validator wird nur das exportseitig erzeugte `created_at` aus diesem Inhaltsvergleich ausgenommen.
- Export enthält `pack.json`, `content.sqlite`, `finalization_report.json` (status ok / internal_test_pack true), Arbeitsstand und vollständige Import-/Annotations-/Wörterbuchberichte.

| SQLite-Tabelle   | Zeilen (= build_rows) |
| ---------------- | --------------------: |
| languages        |                     1 |
| lemmas           |                  1178 |
| senses           |                  2244 |
| cards            |                   264 |
| dictionary_forms |                  2323 |
| decks            |                     1 |
| deck_cards       |                   264 |
| sentences        |                   792 |
| sentence_tokens  |                  8474 |
| card_sentences   |                   792 |
| stories          |                     0 |
| story_sentences  |                     0 |
| exercises        |                     0 |
| grammar_rules    |                     0 |
| audio_assets     |                     0 |
| content_releases |                     1 |

### Staging und Tests

Wiederherstellbare Sicherung beider alter Assets: `build/editorial_finish/rollback/content.sqlite` und `content.manifest.json`. Alter SQLite-SHA-256: `ebc12c0d0ba4909cc070e7f1d2e9c27c08fc3744bb7317d781c8af4b1d1df9a5`.

Jetzt gestagtes Asset: `assets/content/en/content.sqlite`, Manifest daneben. Version **chat_editorial_finish_v1**, Schema 1, 4.112.384 Bytes, SHA-256 **bb71bd0ec9466e931500678b98c6838cf5208f67d82c6cd2cbd6f6fe3fcedf29**. Stage-Werkzeug und anschließendes `--verify` bestätigen Hash, interne Kennzeichnung und alle 16 Tabellenzahlen. Der Repository-Lesetest liest 264 Karten, 792 Satzzuordnungen und 99 Zuordnungen mit Alternativen.

Tatsächlich ausgeführt unter Windows PowerShell ab Repository-Root (jeweils **Exit 0**):

```powershell
# Ein Import führt vollständigen Lint, finalize, Export und SQLite-Readback aus.
.\pipeline\.venv\Scripts\python.exe -X utf8 pipeline/scripts/import_editorial_patch.py --finish pipeline/data/curation/chat_editorial_finish_v1.json --out pipeline/out/chat_editorial_finish_v1
.\pipeline\.venv\Scripts\python.exe -X utf8 -m sprachpipe.cli lint pipeline/out/chat_editorial_finish_v1/pack.json
.\pipeline\.venv\Scripts\python.exe -X utf8 -m pytest -q pipeline/tests
dart run tool/stage_content_pack.dart --from pipeline/out/chat_editorial_finish_v1
dart run tool/stage_content_pack.dart --verify
flutter analyze
flutter test
```

macOS Terminal, entsprechende Befehle (hier **nicht ausgeführt**; für Wiederholung einen noch nicht vorhandenen Ausgabeordner wählen):

```sh
pipeline/.venv/bin/python pipeline/scripts/import_editorial_patch.py --finish pipeline/data/curation/chat_editorial_finish_v1.json --out pipeline/out/chat_editorial_finish_v1
pipeline/.venv/bin/python -m sprachpipe.cli lint pipeline/out/chat_editorial_finish_v1/pack.json
pipeline/.venv/bin/python -m pytest -q pipeline/tests
dart run tool/stage_content_pack.dart --from pipeline/out/chat_editorial_finish_v1
dart run tool/stage_content_pack.dart --verify
flutter analyze
flutter test
```

Tatsächlicher kompakter Output:

```text
status ok: 264 cards, 792 sentence pairs; 190 sentence / 10 metadata operations
annotation: 137 changed English sentences; 1486 tokens; 1314 resolved words; 0 open words; 172 punctuation
lint: 792 sentences, 0 errors, 150 warnings
dictionary: 2323 resolved keys, 0 missing, 0 conflicts; complete=True
cloud calls 0; cost 0 USD
310 passed in 11.12s
No issues found! (ran in 2.4s)
00:14 +215: All tests passed!
pack chat_editorial_finish_v1 (schema 1, internal: true); deck "Allgemeine Sprache":
264 cards, 792 card sentences, 99 with valid_alternatives, 264 cards in the pack
```

Neun zusätzliche Regressionstests (22 Adaptertests insgesamt) sichern hashgebundene Ergänzungen, erwarteten Text/stabile ID, vollständige neue Annotation, abgewiesene veraltete Tokenentscheidungen, abgewiesenes Überschreiben geteilter Senses, vollständige Abdeckung offener Tokens, getrennte Definition/Formglosse, unveränderte Quellen sowie vollständigen Offline-Export mit SQLite-Readback. Ein Test-Fixture-Zugriff wurde vor dem grünen Lauf korrigiert (Tuple statt Dictionary); keine Produktprüfung wurde abgeschaltet. Erster lokaler Entwurf unter `build/editorial_finish/draft_01` war bereits technisch vollständig.

### Android-Integration und Lernstandsschutz

Emulator `emulator-5554` verfügbar. Vor Test App gestoppt, `user.db` binär gesichert und read-only geprüft: bereits Schema **3**, **20 user_cards / 19 review_log**. Keine Migration ausgeführt. Temporärer Einstieg ausschließlich unter `build/editorial_finish/emulator_smoke.dart`; die App-Quellen bleiben unverändert. Er verwendet eine neue Kopie unter `files/editorial_finish_smoke/user.db` und den echten Content-Installer / das echte Repository.

```text
EDITORIAL_FINISH_SMOKE PASS version=chat_editorial_finish_v1 cards=264 sentences=792
replacements=6 tokens=8474 rush_hour=ok clone_states=20 reviews=19
original_sha256=8bed6d7f0d05f65874c300fc90257a670bab75cbc757e93ed629d32723c3c0ad
```

Alle Sätze und Token-Spans über das Android-Repository gelesen, die sechs Ersatztexte mit leeren Alternativen und beide rush-hour-Glossen zusätzlich geprüft. App-Pack im Emulator hat denselben SHA-256 wie das gestagte Asset. Build und datenbewahrendes `adb install -r` bestanden; kein Uninstall, kein Zurücksetzen und keine Löschung von Lernständen. Log: `build/editorial_finish/device_smoke.log`. iOS wurde nicht ausgeführt.

### Offen geblieben

**so#auf_diese_weise** (`1bbe26267773ad288ddd7bf7063c4437`, Stapelposition 70) und **like#fuellwort** (`7e36dbaded1247f91a76a6577dfe5345`, Position 152) bleiben mit je drei Sätzen im Pack. Ihre Rückstellung ist weiterhin nur eine Empfehlung. Keine Nutzer-Deaktivierung, keine neue Ausschlusslogik. Das Ergebnis bleibt ausdrücklich ein **internes Test-Pack**, keine öffentliche Inhaltsfreigabe. Der gezielte Offline-Abschluss benötigt keinen weiteren Generierungs- oder Korrekturlauf.

Die normale Debug-App wurde anschließend neu gebaut und mit `adb install -r` wiederhergestellt; nicht der temporäre Test-Einstieg. Abschließende Binärprüfung von `files/user.db`: **bytegleich**, SHA-256 `8bed6d7f0d05f65874c300fc90257a670bab75cbc757e93ed629d32723c3c0ad`, weiterhin Schema 3 / 20 Kartenstände / 19 Reviews. Belege: `build/editorial_finish/user_before.json`, `user_after.json`, binäre Kopien daneben. Die App wurde danach gestoppt.

Gerätebefehle, identisch unter Windows PowerShell und macOS Terminal; tatsächlich unter Windows ausgeführt, jeweils **Exit 0**:

```text
flutter build apk --debug --target build/editorial_finish/emulator_smoke.dart --no-pub
adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb shell am start -n com.example.sprachapp/.MainActivity
adb shell am force-stop com.example.sprachapp
flutter build apk --debug --no-pub
adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb shell am force-stop com.example.sprachapp
git diff --check
git status --short
```

`git status --short` enthält die bereits vorhandenen gestagten/ungestagten Änderungen sowie die neuen Redaktionsdateien; nichts gestagt, zurückgesetzt, committed oder gepusht. In diesem Abschluss geändert: Adapter, dessen Regressionstests, neue versionierte Ergänzung, dieser Bericht und NEXTSTEPS; hinzu kommen das ausdrücklich angeforderte interne Asset-Staging und neue lokale Ausgabe-/Prüfartefakte. Keine Änderungen an App-Code, SRS, Lintergrenzen, Auswahl, Modellen oder Budgets.
