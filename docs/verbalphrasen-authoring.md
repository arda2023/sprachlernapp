# Verbalphrasen: Auswahl und Authoring-Übergabe v1

Stand: 13.10.2026. Vorbereitungsauftrag: vollständige Mehrwortziele, noch keine Sätze oder Imports. Nach Gesamtbestands- und Vertragsprüfung bleiben 181 Ziele aus 304 Kandidaten, aufgeteilt in 91/90. 123 Ausschlüsse werden mit Gründen und Referenzen mitgeliefert. Der Richtwert von ungefähr 200 begründet keine Auffüllpflicht. 20 vorhandene Wörterbuchbedeutungen ohne Lernkarte werden wiederverwendet; 161 Bedeutungen sind vollständig definierte neue Vorschläge. Es werden keine 181 neuen Einzelwörter behauptet.

## Vor der Auswahl geprüfter Ablauf

Der normale Schema-4-/V2-Weg ist vorhanden und auf HEAD: `validate_context`, `bind_new_pack`, `export_authoring_context.py` und `import_editorial_patch.py`. Der Importvertrag bleibt V2, der vollständige Tabellenkontext Schema 4. Ein normales Ziel hat einen eigenständigen Lernkopf und eine zusammenhängende Lücke; keine Ausnahme der drei Formstapel. Trennbare Verben dürfen vor einer nachgestellten Nominalgruppe stehen. Konstruktionen mit zwingendem Zwischenobjekt bleiben außerhalb der Auswahl. Präpositionen werden nicht entfernt, keine Platzhalter reserviert.

Autorenhinweise stehen je Auswahl-ID im bestehenden Stringfeld `review.reason`: Transitivität, Objekt/Ergänzung, Trennbarkeit, Wortstellung, Register, relevante Varianten und Bedeutungsgrenzen. Das Feld ist in der Auswahl und im vollständigen Authoring-Kontext enthalten; keine unbekannten Eintragsfelder und keine zusätzliche Schnittstelle. `synonym_candidates_not_separate_targets` ist keine Antwortfreigabe.

Die Basis ist der final gestagte `alltagssprache_redewendungen_batch_5_v1` mit zwölf Ansichten, Schema 4, 3008 Karten, 441 abgeschlossenen Alltagssprache-Zielen und der tatsächlichen Projektion 2894 Übungen / 2623 Wörter. Alle 22 Tabellen einschließlich der vier Formtabellen bleiben unverändert. Bestehende IDs, Sätze, Besitzer, Aliase, Gruppen und Lernstände werden nicht geändert.


## Auswahlentscheidungen und Umfang

Die 181 akzeptierten Ziele decken unterschiedliche Handlungsabsichten ab. 304 Kandidaten wurden einzeln gegen den gesamten Pack und alle 2798 Altreservierungen geprüft, einschließlich der 441 Alltagssprache-Ziele, sämtlicher Formfunktionen, Besitzaliase, Wörterbuch-Senses, Lernkopfreferenzen und bestätigter Alternativen. Gleiche deutsche Wörter wurden als Prüfhinweis verwendet, nicht als automatischer Synonymiebeweis. Kein bloßes Verb plus beliebiges Objekt, keine Flexionsvariation oder zusätzliche Gesprächsformel wurde zum Auffüllen aufgenommen.

Der Umfang liegt 19 unter dem Richtwert 200. Bereits gelehrte Absichten und gleichbedeutende Varianten entfallen; 29 weitere Kandidaten wurden wegen enger Randbereiche, transparenter Richtungspräzisierungen oder dichter Nachbarschaft ähnlicher Handlungen zurückgestellt. Diese Priorisierung behauptet keine gemessenen Frequenzen. Die 123 konkreten Ausschlüsse stehen unten und vollständig in beiden Auswahldateien sowie `selection.json` der ZIP. Für Business wurde keine Auswahl angelegt.

Bedeutungsgrenzen sind ausdrücklich in `reason` und `review.reason` verankert: etwa Eigentum bei belong to statt sozialem Dazugehören, ungünstige Folgen bei pay for statt Geld bezahlen, Durchschauen einer Täuschung bei see through, und allgemeines Verhältnis bei get along with statt sofortiger außerordentlich guter Verständigung des alten get along like a house on fire. keep up with hält ein Tempo; catch up with schließt einen Rückstand.

### Nachweis des Vertragsfehlers und seiner Auflösung

Der erste Aufruf des temporären Metadatenaufbaus erreichte vor jeglichem Schreiben der vier Dateien den unveränderten Validator und wurde abgelehnt:

```text
pipeline/.venv-macos/bin/python /tmp/verbalphrasen-selection/build.py
ValueError: authoring: already offered word
Python-Aufruf: Exit 1; der damalige Shell-Aufruf mit nachfolgendem cat lieferte Exit 0.
```

Ursache: Die erste Oberflächenprüfung berücksichtigte aktive Alternativen; der bestehende Vertrag berücksichtigt zusätzlich historische Alternativen. `open up` ist an `open|open/VERB|open#oeffnete`, Satz `source/everyday/s153`, und `carry out` an `do|do/VERB|do#tun`, Satz `source/pilot/pilot_60_v1/s478`, bestätigt; beide Links haben `removed_in: single_sentence_v1`. Der vollständige Scan wurde erweitert, beide Kandidaten ausgeschlossen. Keine Alternative entfernt, kein Validator gelockert. Der anschließende identische Vertragslauf bestand; keine weitere Fehlerschleife.

### Batchverteilung

| Thema | Gesamt | Batch 1 | Batch 2 |
|---|---:|---:|---:|

| Kontakte und Miteinander | 48 | 24 | 24 |

| Planung, Lernen und Arbeit | 31 | 16 | 15 |

| Haushalt und Dinge | 29 | 14 | 15 |

| Körper und Alltag | 25 | 13 | 12 |

| Probleme und Entscheidungen | 24 | 12 | 12 |

| Bewegung und Veränderung | 24 | 12 | 12 |

| **Gesamt** | **181** | **91** | **90** |

Keine benachbarten Einträge desselben Themas oder Verbgrundworts innerhalb eines Batches. Themen verteilen sich aus der tatsächlichen Auswahl; keine Aufnahme schwacher Ziele für eine Quote. Originalpositionen 1–181 entsprechen `editorial_position` und bleiben reservierungsseitig fest. Batch 1 hat geplante Anzeigen 1–91; Batch 2 später 92–181. Die zukünftige Fortsetzung verwendet den bestehenden `--prepare-continuation`-/Display-Patch-Weg gegen den dann wirklich gestagten Pack. Jetzt keine Fortsetzungsdatei, kein Display-Patch und kein Import erzeugt. Anzeigen sind keine Lernreihenfolge.

### Tatsächlich wiederverwendete Wörterbuchbedeutungen

Diese 20 Sense-IDs sind vorhanden und haben im Basis-Pack keine Lernkarte. Lemma-/Sense-IDs, Altglosse und vorhandene Definition bleiben exakt erhalten. Die neue Kartenoberfläche ist jeweils der vollständige Ausdruck; keine zusätzliche Reservierung für das Grundverb. `join#mitmachen` und `wash#spuelen` besitzen keine Altdefinition: `definition_de` bleibt null, die Lernabsicht steht in `target_meaning_de`. Die alte Glosse `mithalten in keep up` wird nicht umgeschrieben; die natürliche Kartenübersetzung lautet `im Tempo mithalten`. Andere Altglossen bleiben eine separate Aufgabe.

| Auswahl-ID / Form | Sense-Referenz | Unveränderte Definition / festgelegte Absicht |
|---|---|---|

| verbalphrasen-v1-0001 / argue about | argue/VERB&#124;argue#streiten | Im Gespräch mit jemandem eine Meinungsverschiedenheit austragen. |

| verbalphrasen-v1-0002 / agree on | agree/VERB&#124;agree#vereinbaren | Gemeinsam eine Festlegung treffen, hier einen Termin. |

| verbalphrasen-v1-0012 / dry out | dry/VERB&#124;dry#trocken_werden | Feuchtigkeit verlieren und trocken werden, ohne zwingend abgewischt zu werden. |

| verbalphrasen-v1-0015 / get along with | get/VERB&#124;get#sich-verstehen | Mit along: ein gutes oder schlechtes Verhältnis zu jemandem haben. |

| verbalphrasen-v1-0022 / break out | break/VERB&#124;break#ausbrechen | Mit out: bei Streit oder einem Ereignis plötzlich beginnen. |

| verbalphrasen-v1-0023 / hear about | hear/VERB&#124;hear#erfahren | Informationen über jemanden oder etwas erhalten, hier in hear about; nicht bloße Geräuschwahrnehmung. |

| verbalphrasen-v1-0024 / break down | break/VERB&#124;break#panne-haben | Mit down: von einem Fahrzeug oder einer Maschine, nicht mehr funktionieren. |

| verbalphrasen-v1-0041 / leave out | leave/VERB&#124;leave#weglassen | Etwas bei einer Aufzählung oder Zusammenstellung nicht aufnehmen. |

| verbalphrasen-v1-0074 / take off | take/VERB&#124;take#ausziehen | Mit off: ein Kleidungsstück vom Körper entfernen. |

| verbalphrasen-v1-0076 / stare at | stare/VERB&#124;stare#starren | Lange und mit festem Blick auf jemanden oder etwas schauen. |

| verbalphrasen-v1-0091 / turn into | turn/VERB&#124;turn#sich-verwandeln | Mit into: in einen anderen Zustand oder eine andere Erscheinung übergehen. |

| verbalphrasen-v1-0096 / bring together | bring/VERB&#124;bring#zusammenfuehren | Mit together: Menschen oder Dinge miteinander verbinden. |

| verbalphrasen-v1-0116 / join in | join/VERB&#124;join#mitmachen | (Altdefinition fehlt) Sich an einer bereits laufenden gemeinsamen Tätigkeit beteiligen. |

| verbalphrasen-v1-0122 / cool down | cool/VERB&#124;cool#abkuehlen | An Temperatur verlieren. |

| verbalphrasen-v1-0131 / keep up with | keep/VERB&#124;keep#keep_up | Mit up das Tempo einer anderen Person oder Entwicklung halten. |

| verbalphrasen-v1-0140 / grow up | grow/VERB&#124;grow#aufwachsen | Mit up: sich vom Kind zum Erwachsenen entwickeln. |

| verbalphrasen-v1-0150 / lead to | lead/VERB&#124;lead#ergebnis | Ein bestimmtes Ergebnis zur Folge haben, mit to. |

| verbalphrasen-v1-0160 / stand up for | stand/VERB&#124;stand#fuer_jemanden_eintreten | Mit up for: jemanden bei ungerechter Behandlung unterstützen. |

| verbalphrasen-v1-0171 / wash up | wash/VERB&#124;wash#spuelen | (Altdefinition fehlt) Benutztes Geschirr nach einer Mahlzeit reinigen. |

| verbalphrasen-v1-0176 / wake up | wake/VERB&#124;wake#aufwachen | Selbst aufhören zu schlafen, ohne Objekt. |


Die übrigen 161 Einträge sind `sense_source: proposed_new` mit genau einer ausgearbeiteten Definition, vorgeschlagenem Sense-Key und stabilen geplanten IDs. Noch keine produktiven Senses angelegt. Gesamt: 181 zukünftige normale Lernköpfe / 20 wiederverwendete Wörterbuchbedeutungen / 161 neue Bedeutungsvorschläge; kein dreifacher Form- oder Einzelwortzuwachs.

## Tatsächliche Quellen und neue Dateien

Der Basis-Pack enthält seine Registry als `word_registry.snapshot`, kanonischer SHA256 `91a731db4e21ce19103ec0c4d3fdd783c47c3b58f41662e3d564abca044b8a78`. Version `alltagssprache_redewendungen_batch_5_context_v2`; tatsächlicher Dateipfad `pipeline/data/words/en.alltagssprache_redewendungen_batch_5_context_v2.json`. Datei und Snapshot sind identisch. Die vorhandene Gruppendatei `pipeline/data/learning_groups/en.alltagssprache_redewendungen_batch_5_context_v2.json` enthält hingegen den Kontext vor dem letzten Import: 2921 bestehende Karten und 87 damals reservierte. Sie wurde nicht als aktueller Endbestand übernommen. Die neuen Altgruppen werden direkt aus den 3008 finalen `cards.learning`-Entscheidungen mit 2996 Gruppen und tatsächlichen Karten-IDs aufgebaut. Vollständige Coverage und alte Metadaten sind geprüft.

Neue Dateien:

- `pipeline/data/selection/verbalphrasen_v1.json`: unveränderlicher Gesamtkatalog.
- `pipeline/data/selection/verbalphrasen_batch_1_context_v1.json`: gleiche Einträge/Entscheidungen, eigener Kontextname.
- `pipeline/data/words/en.verbalphrasen_batch_1_context_v1.json`: exakter Altpräfix 2798 plus 181 neue Ausdrucksreservierungen = 2979.
- `pipeline/data/learning_groups/en.verbalphrasen_batch_1_context_v1.json`: 3008 unveränderte Altentscheidungen plus 181 geplante Köpfe.
- `docs/verbalphrasen-authoring.md`, `build/verbalphrasen_authoring_batch_1.zip` und Prüfnachweise unter `build/verbalphrasen_authoring_checks/`.
- NEXTSTEPS und Roadmap zeigen nur den tatsächlichen Vorbereitungsstand.

Die obsolete ungenutzte Altreservierung für in my opinion bleibt erhalten. 2798 historische Registryzeilen sind daher nicht mit 2797 aktiven Besitzern gleichzusetzen. Alle 37 alten Aliase bleiben erhalten, keine neuen Besitzaliase. Variantenkandidaten begründen keine gültige Antwort.

## Reale Prüfungen, Befehle und Exitcodes

Ab Repository-Root, macOS Terminal. Alle Logs sind tatsächliche neue Läufe. Dart benötigt Zugriff auf seinen lokalen SDK-Cache; keine Paketinstallation oder Flutter-Testausführung.

```text
dart run tool/stage_content_pack.dart --verify
Running build hooks...Running build hooks...verified assets/content/en/content.sqlite
  version alltagssprache_redewendungen_batch_5_v1, schema 4, 19193856 bytes
  sha256 afb6908df44f791b70d839dfbee0b1810c0294aec7d44bf4d0c9005ffd2c7765
  22 table counts match finalization_report.json
  INTERNES TEST-PACK: own devices and selected testers only, no public content release
Exit 0

dart run tool/report_learning_groups.dart pipeline/out/alltagssprache_redewendungen_batch_5_v1/content.sqlite
mixed: raw_words=2975; learning_targets=2894; lexical_words=2623; form_memberships=402
alltagssprache-redewendungen: raw_words=441; learning_targets=441; lexical_words=441
Exit 0
```

Vollständige Projektion: `learning-projection.log`, kompakt `learning-projection-summary.json`. Karten (3008), Besitzzeilen (2797), Übungen (2894) und Wörter (2623) sind verschiedene Größen. Zwölf Produktionsansichten, je 134 Formübungen, bleiben erhalten.

```text
pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --help
usage: export_authoring_context.py [-h] [--historical] [--selection SELECTION]
                                   [--out OUT] [--batch BATCH]
                                   [--verify-zip VERIFY_ZIP]
                                   [--prepare-continuation VERSION]
                                   [--source-pack SOURCE_PACK]
                                   [--source-sqlite SOURCE_SQLITE]
                                   [--definition-equivalences DEFINITION_EQUIVALENCES]

Export/verify an offline handoff using the Reisen context layout and import
path. Never creates content rows, practice sentences, or staged assets.

options:
  -h, --help            show this help message and exit
  --historical          Validate archived hashes/content with current
                        validators, without requiring current staged/source
                        bytes
  --selection SELECTION
  --out OUT
  --batch BATCH
  --verify-zip VERIFY_ZIP
  --prepare-continuation VERSION
                        Write fresh versioned snapshots against the staged
                        pack; requires original --selection and --batch
  --source-pack SOURCE_PACK
                        Form continuation: explicit partial-import pack.json
  --source-sqlite SOURCE_SQLITE
                        Form continuation: matching content.sqlite
  --definition-equivalences DEFINITION_EQUIVALENCES
                        Explicit hash-bound editorial decisions for equivalent
                        definition wording
Exit 0

pipeline/.venv-macos/bin/python /tmp/verbalphrasen-selection/build.py
VALIDATE_CONTEXT PASS: selected=181; excluded=123; batches=91/90; existing_senses=20; new_senses=161
existing_cards=3008; existing_groups=2996; new_groups=181; registry_words=2979
partition_selection PASS: 0 present; validate_selection/index_registry/validate_learning/build_rows PASS
Exit 0

pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --selection pipeline/data/selection/verbalphrasen_batch_1_context_v1.json --batch 1 --out build/verbalphrasen_authoring_batch_1.zip
export PASS; files=82; selected=181; excluded=123; batches=91/90
Exit 0

pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --verify-zip build/verbalphrasen_authoring_batch_1.zip
zip_verification PASS; hashed_files=81; sqlite_tables=22; sqlite_cards=3008
zip_sha256 c34e5a976bb2574773041b5648bb0a46ddc61209d3a9b7baa6a310520f8cd14a
validate_selection/index_registry/validate_learning/build_rows PASS
Exit 0

pipeline/.venv-macos/bin/python -m pytest pipeline/tests/test_selection.py pipeline/tests/test_word_registry.py pipeline/tests/test_authoring_context.py pipeline/tests/test_authoring_continuation.py pipeline/tests/test_normal_schema4_authoring.py pipeline/tests/test_learning_groups.py -q
......................................................................   [100%]
70 passed in 6.04s
Exit 0

pipeline/.venv-macos/bin/python build/verbalphrasen_authoring_checks/audit.py
PASS: CRC, 81 manifest hashes, 181 identities/hints, 123 exclusions, partition 0/91/90
PASS: source JSON/SQLite/assets/manifest byte-identical; 22 tables; old owners/groups/senses unchanged
PASS: no active or historical alternative collisions; no new sentences/tokens/valid_alternatives
Exit 0
```

Die temporären Kuratierungsskripte bauen Metadaten mit dem bestehenden Vertrag; sie sind kein zweiter Exporter oder Importweg. Dauerhafte Read-only-Auditquelle: `build/verbalphrasen_authoring_checks/audit.py`; Outputs `metadata-build.log`, `export.log`, `verify-zip.log`, `full-audit.log/json`, `candidate-audit-final.json`, `pytest.log`.

Windows PowerShell: Dart- und Git-Befehle identisch. Für die vorhandenen Python-Kommandos lautet der Interpreter `.\pipeline\.venv\Scripts\python.exe`; zum Beispiel:

```powershell
.\pipeline\.venv\Scripts\python.exe pipeline\scripts\export_authoring_context.py --selection pipeline\data\selection\verbalphrasen_batch_1_context_v1.json --batch 1 --out build\verbalphrasen_authoring_batch_1.zip
.\pipeline\.venv\Scripts\python.exe pipeline\scripts\export_authoring_context.py --verify-zip build\verbalphrasen_authoring_batch_1.zip
.\pipeline\.venv\Scripts\python.exe -m pytest pipeline/tests/test_selection.py pipeline/tests/test_word_registry.py pipeline/tests/test_authoring_context.py pipeline/tests/test_authoring_continuation.py pipeline/tests/test_normal_schema4_authoring.py pipeline/tests/test_learning_groups.py -q
.\pipeline\.venv\Scripts\python.exe build\verbalphrasen_authoring_checks\audit.py
```

Windows-Kommandos sind Entsprechungen, keine behaupteten Windows-Testläufe.

## Hash- und Tabellenbelege

Rohbyte-SHA256 vor und nach dem Auftrag identisch:

| Datei | SHA256 |
|---|---|

| pipeline/out/alltagssprache_redewendungen_batch_5_v1/pack.json | `2f8dbf21ff2173bc29e848a97f5134e279410def703eefe565fc11e49ab708a0` |

| pipeline/out/alltagssprache_redewendungen_batch_5_v1/content.sqlite | `afb6908df44f791b70d839dfbee0b1810c0294aec7d44bf4d0c9005ffd2c7765` |

| assets/content/en/content.sqlite | `afb6908df44f791b70d839dfbee0b1810c0294aec7d44bf4d0c9005ffd2c7765` |

| assets/content/en/content.manifest.json | `a58ac7684c9e0e7b277f94219446a1e9c72b7bbc3e4100b13aa8aae470a841f4` |

| build/verbalphrasen_authoring_batch_1.zip | `c34e5a976bb2574773041b5648bb0a46ddc61209d3a9b7baa6a310520f8cd14a` |

| pipeline/data/selection/verbalphrasen_v1.json | `e72f0b16f3dbd9f96a9c52db4b8a048b680d97bc7e7e82219ace8de58f5587f5` |

| pipeline/data/selection/verbalphrasen_batch_1_context_v1.json | `059f18c1e4496234f852397c18b4b8bf175b668835292088f0863272a65f208a` |

| pipeline/data/words/en.verbalphrasen_batch_1_context_v1.json | `41b820c2c87f55e1e0ff913135d26011eea3f1905b0ed11e30e1e3281df5992c` |

| pipeline/data/learning_groups/en.verbalphrasen_batch_1_context_v1.json | `a835b11b139df06b41fa0fb4976e9ac3862098331c9dc822d86b6476318fa3f0` |


Kanonische JSON-Digests sind von Rohbytehashes getrennt:

| Gegenstand | Kanonischer SHA256 |
|---|---|

| pack | `e9e4e3148e959ad70dfc3621703beb2e049ccb31ac3f52a24c510e55264bc409` |

| source_registry | `91a731db4e21ce19103ec0c4d3fdd783c47c3b58f41662e3d564abca044b8a78` |

| selection | `5b22e83477eef081619dae8cff002fb974cad255a66e8c7845ad9f584fce0b2e` |

| context | `561cabc845f350ba4843fa3a4138a6448a03d798e169da42cb1ea35e44525908` |

| registry | `862e0e61d3579a4b32859d0a832f18755418a403a4ec1da50222058259beedc6` |

| groups | `7dd082b1e93068f1f875f90e79fbcb0c3ef0137a30f6c5e92f5bd53fcd3aab89` |


ZIP erneut geöffnet: CRCs, vollständiges Manifest, alle Identitäten/Ausschlüsse/Autorenhinweise, exakte aktuelle Einträge und Partition **0 importiert / 91 aktuell / 90 später** geprüft. Basis-JSON und SQLite stimmen bytegleich mit dem final gestagten Stand überein. Kontext: vollständiges Wörterbuch, Besitz/Altaliases, Gruppen, Formdaten, Offline-Tokenizer/Linter-Quellen und Modellgewichte sowie normale V2-Schnittstelle. Keine Generierungsfunktion ausgeführt.

| Quelltabelle | Unveränderte Zeilen |
|---|---:|

| languages | 1 |

| lemmas | 4080 |

| senses | 5673 |

| cards | 3008 |

| dictionary_forms | 6781 |

| decks | 12 |

| deck_cards | 2901 |

| deck_words | 2797 |

| word_aliases | 37 |

| sentences | 3542 |

| sentence_tokens | 38511 |

| card_sentences | 3536 |

| stories | 1 |

| story_sentences | 6 |

| exercises | 0 |

| grammar_rules | 0 |

| audio_assets | 0 |

| content_releases | 1 |

| lexical_targets | 134 |

| card_lexical_targets | 406 |

| form_targets | 402 |

| deck_practice_targets | 402 |


## Sämtliche Ausschlüsse

Jeder Eintrag steht auch im ZIP-Katalog. Referenzen können vorhandene Karten oder ausgewählte Vergleichsköpfe bezeichnen. Historische Referenzen bleiben unverändert; gleichlautende Glossen sind keine automatische allgemeine Gleichsetzung.

### accuse of

In der normalen aktiven Konstruktion muss das Personen-/Sachobjekt zwischen Verb und Präposition stehen; keine zusammenhängende Ziellücke in dieser Form. Keine Ausweichschreibweise oder Platzhalter reserviert.

### agree with

Die konkret gewählte Bedeutungsabsicht ist durch vorhandene Lernziele bereits abgedeckt; Form-/Registervariante erzeugt keinen konkurrierenden Kopf. Karten-ID 8ed330b2cb150952301f810065909926; Referenz agree|agree/VERB|agree#zustimmt. Fester Kontext arbeit-bildung-v1-131-s1: I agree with your suggestion to start the meeting earlier.


Referenzen: `agree|agree/VERB|agree#zustimmt`.

### air out

Spezifischer zusätzlicher Hausarbeitsablauf; zugunsten breiter alltagsrelevanter Handlungsbereiche zurückgestellt.

### apologise for

Die konkret gewählte Bedeutungsabsicht ist durch vorhandene Lernziele bereits abgedeckt; Form-/Registervariante erzeugt keinen konkurrierenden Kopf. Karten-ID 9e40f7bce33c9fae5d2ab97ebc7c2168; Referenz apologise|apologise/VERB|apologise#sich-entschuldigen. Fester Kontext arbeit-bildung-v1-195-s1: I need to apologise for sending you the wrong file.


Referenzen: `apologise|apologise/VERB|apologise#sich-entschuldigen`.

### apply for

Die konkret gewählte Bedeutungsabsicht ist durch vorhandene Lernziele bereits abgedeckt; Form-/Registervariante erzeugt keinen konkurrierenden Kopf. Karten-ID 30c75117278dd856aedf507649379f06; Referenz apply|apply/VERB|apply#sich-bewerben. Fester Kontext arbeit-bildung-v1-148-s1: You can apply for the job through the company website.


Referenzen: `apply|apply/VERB|apply#sich-bewerben`.

### ask for

Nach dem abschließenden Gesamtbestandsvergleich kein eigener neuer Kopf: Die festgelegte Lernabsicht ist bereits abgedeckt; eine engere Objektwahl oder Verlaufsnuance allein rechtfertigt keine Doppelreservierung. request|request/VERB|request#erbitten (Karten-ID 91bc1e2ce0494c739f54b88283d5c7d4)


Referenzen: `request|request/VERB|request#erbitten`.

### back down

Eng benachbartes Nachgebenfeld; zunächst give in ausgewählt, Rücknahme eigener Forderungen zurückgestellt, keine universelle Synonymie behauptet.

### bend down

Transparente Körper-/Richtungspräzisierung; nicht zum Erreichen einer Menge zusätzlich aufgenommen.

### blow up

Bildvergrößerung ist hier ein spezieller technischer Randbereich; nicht zur Zielmengenerfüllung aufgenommen.

### boil down to

Redaktionell bestätigte gleichbedeutende Schreib-/Regional-/Ausdrucksvariante des gewählten Kandidaten; kein separates Lernziel, keine Antwortfreigabe.


Referenzen: `come down to|come down to/VERB|come-down-to#letztlich-ankommen-auf`.

### bring about

Dasselbe gewählte Kausalitätsfeld wie lead to: eine Veränderung/ein Ergebnis verursachen. Für den Erstumfang nur lead to, keine zwei konkurrierenden Köpfe.


Referenzen: `lead to|lead/VERB|lead#ergebnis`.

### bring out

Produktveröffentlichung ist gegenüber alltäglichen Handlungen nachrangig; nicht als Business-Vorgriff ausgewählt.

### buy up

Aufkaufen größerer Bestände liegt näher an kommerziellen Transaktionen als am hier priorisierten Alltagsumfang; nicht vorweg für Business kuratiert.

### call on

Öffentliche formelle Aufforderung im Erstumfang nachrangig gegenüber gewöhnlichen persönlichen Kontaktformen.

### carry on

Bestehende Lernoberfläche/Besitzer/Bestätigungsvariante im vollständigen aktuellen Pack; kein neuer Lernkopf.

### carry out

Bestehender Vertrag blockiert auch historische bestätigte Alternativen an entfernten Satzverknüpfungen; keine allgemeine Bedeutungsidentität behauptet, keine Alternative entfernt. do|do/VERB|do#tun (Karten-ID fcfbb872406704d91f8cf88e4f60da63), Satz source/pilot/pilot_60_v1/s478, removed_in single_sentence_v1


Referenzen: `do|do/VERB|do#tun`.

### check up on

Verhaltenskontrolle gegenüber allgemeinem check on im Erstumfang zurückgestellt; Unterschiede der Absicht ausdrücklich beibehalten.

### chip in

Nach dem abschließenden Gesamtbestandsvergleich kein eigener neuer Kopf: Die festgelegte Lernabsicht ist bereits abgedeckt; eine engere Objektwahl oder Verlaufsnuance allein rechtfertigt keine Doppelreservierung. contribute|contribute/VERB|contribute#beitragen (Karten-ID 3b770029090c6212b97a8b1c8f904d47)


Referenzen: `contribute|contribute/VERB|contribute#beitragen`.

### clean up

Konkrete gewählte Bedeutung bereits durch den vorhandenen Lernkopf abgedeckt; kein neues Ziel für dieselbe Lernabsicht. clean|clean/VERB|clean#putzen (Karten-ID e4d7721061e4264e2dde33947b5b9d01)


Referenzen: `clean|clean/VERB|clean#putzen`.

### clear the air

Bestehende Lernoberfläche/Besitzer/Bestätigungsvariante im vollständigen aktuellen Pack; kein neuer Lernkopf. Karten-ID da2db298a29ba1581b2e1b7ca20cef48; Referenz clear the air|clear the air/VERB|clear-the-air#spannungen-ausraumen. Fester Kontext alltagssprache-v1-0381-s1: Let's talk about yesterday's argument and clear the air.


Referenzen: `clear the air|clear the air/VERB|clear-the-air#spannungen-ausraumen`, `clear the air|clear the air/VERB|clear-the-air#spannungen-ausraumen`.

### clear up

Nach dem abschließenden Gesamtbestandsvergleich kein eigener neuer Kopf: Die festgelegte Lernabsicht ist bereits abgedeckt; eine engere Objektwahl oder Verlaufsnuance allein rechtfertigt keine Doppelreservierung. clear the air|clear the air/VERB|clear-the-air#spannungen-ausraumen (Karten-ID da2db298a29ba1581b2e1b7ca20cef48)


Referenzen: `clear the air|clear the air/VERB|clear-the-air#spannungen-ausraumen`.

### come about

Konkrete gewählte Bedeutung bereits durch den vorhandenen Lernkopf abgedeckt; kein neues Ziel für dieselbe Lernabsicht. irregular:arise:base (Karten-ID 735e7104bbfe71b53f23ff8d3a537315)


Referenzen: `irregular:arise:base`.

### come around

Redaktionell bestätigte gleichbedeutende Schreib-/Regional-/Ausdrucksvariante des gewählten Kandidaten; kein separates Lernziel, keine Antwortfreigabe.


Referenzen: `come round|come round/VERB|come-round#wieder-zu-sich-kommen`.

### come back

Die konkret gewählte Bedeutungsabsicht ist durch vorhandene Lernziele bereits abgedeckt; Form-/Registervariante erzeugt keinen konkurrierenden Kopf. Karten-ID ac21325af534ca3473d4f66d3a781450; Referenz return|return/VERB|return#zurueckkehren. Fester Kontext reisen-v1-390-s1: We plan to return to this island next summer.


Referenzen: `return|return/VERB|return#zurueckkehren`.

### come in

Die konkret gewählte Bedeutungsabsicht ist durch vorhandene Lernziele bereits abgedeckt; Form-/Registervariante erzeugt keinen konkurrierenden Kopf. Karten-ID 200fbad2d0a8546592621045dfacece2; Referenz enter|enter/VERB|enter#betreten-hast. Fester Kontext reisen-v1-392-s1: Please show your ticket before you enter the museum.


Referenzen: `enter|enter/VERB|enter#betreten-hast`.

### come under

Formelle öffentliche Kritik ist gegenüber alltäglichen direkten Handlungsausdrücken nachrangig.

### come up

Konkrete gewählte Bedeutung bereits durch den vorhandenen Lernkopf abgedeckt; kein neues Ziel für dieselbe Lernabsicht. irregular:arise:base (Karten-ID 735e7104bbfe71b53f23ff8d3a537315)


Referenzen: `irregular:arise:base`.

### congratulate on

In der normalen aktiven Konstruktion muss das Personen-/Sachobjekt zwischen Verb und Präposition stehen; keine zusammenhängende Ziellücke in dieser Form. Keine Ausweichschreibweise oder Platzhalter reserviert.

### count on

Die konkret gewählte Bedeutungsabsicht ist durch vorhandene Lernziele bereits abgedeckt; Form-/Registervariante erzeugt keinen konkurrierenden Kopf. Karten-ID ab3890465578a548b9658c491e4f708f; Referenz trust|trust/VERB|trust#vertrauen. Fester Kontext arbeit-bildung-v1-211-s1: I trust my colleague to keep this information private.


Referenzen: `trust|trust/VERB|trust#vertrauen`.

### crop up

Redaktionell bestätigte gleichbedeutende Schreib-/Regional-/Ausdrucksvariante des gewählten Kandidaten; kein separates Lernziel, keine Antwortfreigabe.


Referenzen: `irregular:arise:base`.

### cut back on

Nach dem abschließenden Gesamtbestandsvergleich kein eigener neuer Kopf: Die festgelegte Lernabsicht ist bereits abgedeckt; eine engere Objektwahl oder Verlaufsnuance allein rechtfertigt keine Doppelreservierung. reduce|reduce/VERB|reduce#verringern (Karten-ID 726db8bc5a754e83ffab9d523ce15534)


Referenzen: `reduce|reduce/VERB|reduce#verringern`.

### cut in

Die konkret gewählte Bedeutungsabsicht ist durch vorhandene Lernziele bereits abgedeckt; Form-/Registervariante erzeugt keinen konkurrierenden Kopf. Karten-ID a04c3e3317bc10f97dac9fca0aa38d4a; Referenz interrupt|interrupt/VERB|interrupt#unterbrechen. Fester Kontext arbeit-bildung-v1-147-s1: Please do not interrupt me while I explain the task.


Referenzen: `interrupt|interrupt/VERB|interrupt#unterbrechen`.

### depend on

Die konkret gewählte Bedeutungsabsicht ist durch vorhandene Lernziele bereits abgedeckt; Form-/Registervariante erzeugt keinen konkurrierenden Kopf. Karten-ID b92b648003cbbef841b7f2d73d4e6a9a; Referenz depend|depend/VERB|depend#abhaengen. Fester Kontext menschen-beziehungen-v1-064-s1: My plans for tonight depend on whether my sister can watch the children.


Referenzen: `depend|depend/VERB|depend#abhaengen`.

### dream up

Redaktionell bestätigte gleichbedeutende Schreib-/Regional-/Ausdrucksvariante des gewählten Kandidaten; kein separates Lernziel, keine Antwortfreigabe.


Referenzen: `come up with|come up with/VERB|come-up-with#sich-einfallen-lassen`.

### drive away

Redaktionell bestätigte gleichbedeutende Schreib-/Regional-/Ausdrucksvariante des gewählten Kandidaten; kein separates Lernziel, keine Antwortfreigabe.


Referenzen: `drive off|drive off/VERB|drive-off#wegfahren`.

### fill in for

Redaktionell bestätigte gleichbedeutende Schreib-/Regional-/Ausdrucksvariante des gewählten Kandidaten; kein separates Lernziel, keine Antwortfreigabe.


Referenzen: `stand in for|stand in for/VERB|stand-in-for#vertreten`.

### fill out

Redaktionell bestätigte gleichbedeutende Schreib-/Regional-/Ausdrucksvariante des gewählten Kandidaten; kein separates Lernziel, keine Antwortfreigabe.


Referenzen: `fill in|fill in/VERB|fill-in#ausfullen`.

### focus on

Die konkret gewählte Bedeutungsabsicht ist durch vorhandene Lernziele bereits abgedeckt; Form-/Registervariante erzeugt keinen konkurrierenden Kopf. Karten-ID 2ea4156be767cbff4eaa45810f428fde; Referenz concentrate|concentrate/VERB|concentrate#sich-konzentrieren. Fester Kontext arbeit-bildung-v1-199-s1: Please close the door so I can concentrate on this report.


Referenzen: `concentrate|concentrate/VERB|concentrate#sich-konzentrieren`.

### fork out

Die konkret gewählte Bedeutungsabsicht ist durch vorhandene Lernziele bereits abgedeckt; Form-/Registervariante erzeugt keinen konkurrierenden Kopf. Karten-ID 3a4febb432d220f62c6f1d4891e0a3ea; Referenz pay|pay/VERB|pay#bezahlt. Fester Kontext source/everyday/s58: Luca can pay for the stamps with cash.


Referenzen: `pay|pay/VERB|pay#bezahlt`.

### gang up on

Gemeinsames Bedrängen ist ein enger negativer Gruppenkontext; gegenüber breiterem Miteinander zurückgestellt.

### get across

Kommunikativer Wirkungsabschluss gegenüber direkteren Kontakt-/Erklärungsmustern nachrangig; keine behauptete universelle Gleichheit.

### get ahead

Beruflicher Aufstieg ist ein Randbereich dieses Erstumfangs; keine zusätzliche Karriereterminologie vorbereitet.

### get along like a house on fire

Bestehende Lernoberfläche/Besitzer/Bestätigungsvariante im vollständigen aktuellen Pack; kein neuer Lernkopf. Karten-ID 5b97095c73ecc50f6ab46477f05dc6f3; Referenz get along like a house on fire|get along like a house on fire/VERB|get-along-like-a-house-on-fire#sich-auf-anhieb-bestens-verstehen. Fester Kontext alltagssprache-v1-0223-s1: Our new neighbours get along like a house on fire.


Referenzen: `get along like a house on fire|get along like a house on fire/VERB|get-along-like-a-house-on-fire#sich-auf-anhieb-bestens-verstehen`, `get along like a house on fire|get along like a house on fire/VERB|get-along-like-a-house-on-fire#sich-auf-anhieb-bestens-verstehen`.

### get at

Vorwiegend indirekte Frage-/Progressivkontexte; natürlich übbar, aber gegenüber leichter eindeutig zu redigierenden Zielkontexten zurückgestellt.

### get back

Die konkret gewählte Bedeutungsabsicht ist durch vorhandene Lernziele bereits abgedeckt; Form-/Registervariante erzeugt keinen konkurrierenden Kopf. Karten-ID ac21325af534ca3473d4f66d3a781450; Referenz return|return/VERB|return#zurueckkehren. Fester Kontext reisen-v1-390-s1: We plan to return to this island next summer.


Referenzen: `return|return/VERB|return#zurueckkehren`.

### get by

Nach dem abschließenden Gesamtbestandsvergleich kein eigener neuer Kopf: Die festgelegte Lernabsicht ist bereits abgedeckt; eine engere Objektwahl oder Verlaufsnuance allein rechtfertigt keine Doppelreservierung. make ends meet|make ends meet/VERB|make-ends-meet#uber-die-runden-kommen (Karten-ID 8146a419b7d91ee78e12ed6ee1e26e68)


Referenzen: `make ends meet|make ends meet/VERB|make-ends-meet#uber-die-runden-kommen`.

### get in

Nach dem abschließenden Gesamtbestandsvergleich kein eigener neuer Kopf: Die festgelegte Lernabsicht ist bereits abgedeckt; eine engere Objektwahl oder Verlaufsnuance allein rechtfertigt keine Doppelreservierung. board|board/VERB|board#einsteigen (Karten-ID 7be9349db001a4e6af299c5490cb644f)


Referenzen: `board|board/VERB|board#einsteigen`.

### get on

Die konkret gewählte Bedeutungsabsicht ist durch vorhandene Lernziele bereits abgedeckt; Form-/Registervariante erzeugt keinen konkurrierenden Kopf. Karten-ID 7be9349db001a4e6af299c5490cb644f; Referenz board|board/VERB|board#einsteigen. Fester Kontext reisen-v1-393-s1: We can board the ferry after the cars.


Referenzen: `board|board/VERB|board#einsteigen`.

### get over

Die konkret gewählte Bedeutungsabsicht ist durch vorhandene Lernziele bereits abgedeckt; Form-/Registervariante erzeugt keinen konkurrierenden Kopf. Karten-ID 3d488122029be452a77535edd8052f3c; Referenz recover|recover/VERB|recover#sich-erholen. Fester Kontext menschen-beziehungen-v1-120-s1: She needs time to recover from the stress of the last few months.


Referenzen: `recover|recover/VERB|recover#sich-erholen`.

### give up

Nach dem abschließenden Gesamtbestandsvergleich kein eigener neuer Kopf: Die festgelegte Lernabsicht ist bereits abgedeckt; eine engere Objektwahl oder Verlaufsnuance allein rechtfertigt keine Doppelreservierung. irregular:quit:base (Karten-ID f064e4146808180694869111a07959d8)


Referenzen: `irregular:quit:base`.

### go away

Nach dem abschließenden Gesamtbestandsvergleich kein eigener neuer Kopf: Die festgelegte Lernabsicht ist bereits abgedeckt; eine engere Objektwahl oder Verlaufsnuance allein rechtfertigt keine Doppelreservierung. leave|leave/VERB|leave#verlassen (Karten-ID ec89675553e4c6fd1027c37e447072d1)


Referenzen: `leave|leave/VERB|leave#verlassen`.

### go back

Die konkret gewählte Bedeutungsabsicht ist durch vorhandene Lernziele bereits abgedeckt; Form-/Registervariante erzeugt keinen konkurrierenden Kopf. Karten-ID ac21325af534ca3473d4f66d3a781450; Referenz return|return/VERB|return#zurueckkehren. Fester Kontext reisen-v1-390-s1: We plan to return to this island next summer.


Referenzen: `return|return/VERB|return#zurueckkehren`.

### go over

Nach dem abschließenden Gesamtbestandsvergleich kein eigener neuer Kopf: Die festgelegte Lernabsicht ist bereits abgedeckt; eine engere Objektwahl oder Verlaufsnuance allein rechtfertigt keine Doppelreservierung. revise|revise/VERB|revise#lernstoff-wiederholen (Karten-ID 4620a1b0b92d48a80bf41c38395bee9f)


Referenzen: `revise|revise/VERB|revise#lernstoff-wiederholen`.

### grow into

Berufliche Rollenentwicklung gegenüber konkreten Alltagshandlungen nachrangig; kein Mengenauffüllen.

### hand over

Konkrete gewählte Bedeutung bereits durch den vorhandenen Lernkopf abgedeckt; kein neues Ziel für dieselbe Lernabsicht. irregular:give:base (Karten-ID 7ac05077ee874cc7348d8f174ed00932)


Referenzen: `irregular:give:base`.

### help out

Die konkret gewählte Bedeutungsabsicht ist durch vorhandene Lernziele bereits abgedeckt; Form-/Registervariante erzeugt keinen konkurrierenden Kopf. Karten-ID b16991ecd86dfde4c1c643fa8e3c7c7e; Referenz help|help/VERB|help#helfen. Fester Kontext reisen-v1-437-s1: Could you help me with this heavy suitcase?


Referenzen: `help|help/VERB|help#helfen`.

### help yourself

Bestehende Lernoberfläche/Besitzer/Bestätigungsvariante im vollständigen aktuellen Pack; kein neuer Lernkopf. Karten-ID 831b8e10fca9aa73bd04d4d51afe63d9; Referenz help yourself|help yourself/INTJ|help-yourself#bedien-dich. Fester Kontext alltagssprache-v1-0050-s1: Help yourself to some bread while the soup is cooking.


Referenzen: `help yourself|help yourself/INTJ|help-yourself#bedien-dich`, `help yourself|help yourself/INTJ|help-yourself#bedien-dich`.

### hold on to

Die konkret gewählte Bedeutungsabsicht ist durch vorhandene Lernziele bereits abgedeckt; Form-/Registervariante erzeugt keinen konkurrierenden Kopf. Karten-ID 15608ada9fb8a7c2d97eae22d4627d91; Referenz irregular:keep:base. Fester Kontext irregular-v1-b2-s053: You should keep your passport in a safe place.


Referenzen: `irregular:keep:base`.

### hold onto

Die konkret gewählte Bedeutungsabsicht ist durch vorhandene Lernziele bereits abgedeckt; Form-/Registervariante erzeugt keinen konkurrierenden Kopf. Karten-ID 15608ada9fb8a7c2d97eae22d4627d91; Referenz irregular:keep:base. Fester Kontext irregular-v1-b2-s053: You should keep your passport in a safe place.


Referenzen: `irregular:keep:base`.

### hold up

Beraubung unter Drohung ist ein enger Kriminalitätsbereich außerhalb dieses priorisierten Alltagsumfangs.

### insist on

Die konkret gewählte Bedeutungsabsicht ist durch vorhandene Lernziele bereits abgedeckt; Form-/Registervariante erzeugt keinen konkurrierenden Kopf. Karten-ID 53abaee591dfa8524184e250d954c409; Referenz insist|insist/VERB|insist#beharren. Fester Kontext menschen-beziehungen-v1-165-s1: Even after hearing my objections, you insist that your plan is fair.


Referenzen: `insist|insist/VERB|insist#beharren`.

### jot down

Redaktionell bestätigte gleichbedeutende Schreib-/Regional-/Ausdrucksvariante des gewählten Kandidaten; kein separates Lernziel, keine Antwortfreigabe.


Referenzen: `write down|write down/VERB|write-down#aufschreiben`.

### keep in touch

Bestehende Lernoberfläche/Besitzer/Bestätigungsvariante im vollständigen aktuellen Pack; kein neuer Lernkopf. Karten-ID 8fa1a1ed9e4063ffcafcae239ffafad8; Referenz keep in touch|keep in touch/INTJ|keep-in-touch#bleiben-wir-in-kontakt. Fester Kontext alltagssprache-v1-0080-s1: Keep in touch, I would love to hear about your new life.


Referenzen: `keep in touch|keep in touch/INTJ|keep-in-touch#bleiben-wir-in-kontakt`, `keep in touch|keep in touch/INTJ|keep-in-touch#bleiben-wir-in-kontakt`.

### keep to

Themendisziplin im Gespräch gegenüber ausgewählten Handlungs-/Planmustern im Erstumfang nachrangig.

### kick off

Die konkret gewählte Bedeutungsabsicht ist durch vorhandene Lernziele bereits abgedeckt; Form-/Registervariante erzeugt keinen konkurrierenden Kopf. Karten-ID f8eb0d379c0b533f985dab7bd576bb22; Referenz start|start/VERB|start#beginnen. Fester Kontext alltag-zuhause-v1-247-s1: We can start cooking now; all the ingredients are ready.


Referenzen: `start|start/VERB|start#beginnen`.

### kick out

Zwangsweises Hinauswerfen ist gegenüber breit nutzbaren Kontakt-/Handlungszielen nachrangig.

### kneel down

Transparente Haltungs-/Richtungspräzisierung; außerhalb des priorisierten Erstumfangs.

### lean back

Wörtliche Körper-/Richtungspräzisierung; für diesen Erstumfang geringerer eigenständiger lexikalischer Nutzen als ausgewählte Idiom-/Partikelbedeutungen.

### lie in

Redaktionell bestätigte gleichbedeutende Schreib-/Regional-/Ausdrucksvariante des gewählten Kandidaten; kein separates Lernziel, keine Antwortfreigabe.


Referenzen: `sleep in|sleep in/VERB|sleep-in#ausschlafen`.

### listen to

Die konkret gewählte Bedeutungsabsicht ist durch vorhandene Lernziele bereits abgedeckt; Form-/Registervariante erzeugt keinen konkurrierenden Kopf. Karten-ID b578e32d44f29c98795165671a60a32a; Referenz listen|listen/VERB|listen#zuhoert. Fester Kontext source/everyday/s178: Noah, please listen carefully to the doctor.


Referenzen: `listen|listen/VERB|listen#zuhoert`.

### live through

Die konkret gewählte Bedeutungsabsicht ist durch vorhandene Lernziele bereits abgedeckt; Form-/Registervariante erzeugt keinen konkurrierenden Kopf. Karten-ID e4abdc0c817eab54d9b4820bf717a8e3; Referenz survive|survive/VERB|survive#uberleben. Fester Kontext natur-umwelt-v1-197-s1: These plants can survive for weeks without any rain.


Referenzen: `survive|survive/VERB|survive#uberleben`.

### look after

Die konkret gewählte Bedeutungsabsicht ist durch vorhandene Lernziele bereits abgedeckt; Form-/Registervariante erzeugt keinen konkurrierenden Kopf. Karten-ID 635953ef9f53b17a6d6e83f26de17f1e; Referenz care|care/VERB|care#sich-kummern. Fester Kontext menschen-beziehungen-v1-016-s1: I want to care for my father at home as he grows older.


Referenzen: `care|care/VERB|care#sich-kummern`.

### look around

Nach dem abschließenden Gesamtbestandsvergleich kein eigener neuer Kopf: Die festgelegte Lernabsicht ist bereits abgedeckt; eine engere Objektwahl oder Verlaufsnuance allein rechtfertigt keine Doppelreservierung. explore|explore/VERB|explore#erkunden (Karten-ID 4efd28dec4549ba313775cbcdbebb2c6)


Referenzen: `explore|explore/VERB|explore#erkunden`.

### look into

Die konkret gewählte Bedeutungsabsicht ist durch vorhandene Lernziele bereits abgedeckt; Form-/Registervariante erzeugt keinen konkurrierenden Kopf. Karten-ID fd11b7a59c6edea373749fe4614d51bb; Referenz investigate|investigate/VERB|investigate#untersuchen. Fester Kontext arbeit-bildung-v1-198-s1: We must investigate why the printer keeps stopping.


Referenzen: `investigate|investigate/VERB|investigate#untersuchen`.

### make up

Die konkret gewählte Bedeutungsabsicht ist durch vorhandene Lernziele bereits abgedeckt; Form-/Registervariante erzeugt keinen konkurrierenden Kopf. Karten-ID 0a40288b0e861bc0aef02cf519598840; Referenz reconcile|reconcile/VERB|reconcile#sich-versohnen. Fester Kontext menschen-beziehungen-v1-047-s1: After months of silence, both sisters want to reconcile.


Referenzen: `reconcile|reconcile/VERB|reconcile#sich-versohnen`.

### mistake for

In der normalen aktiven Konstruktion muss das Personen-/Sachobjekt zwischen Verb und Präposition stehen; keine zusammenhängende Ziellücke in dieser Form. Keine Ausweichschreibweise oder Platzhalter reserviert.

### mop up

Nahes Aufnehmen von Verschüttetem; im Erstumfang gegenüber ausgewählten Grundabläufen zurückgestellt.

### mull over

Redaktionell bestätigte gleichbedeutende Schreib-/Regional-/Ausdrucksvariante des gewählten Kandidaten; kein separates Lernziel, keine Antwortfreigabe.


Referenzen: `think over|think over/VERB|think-over#uberdenken`.

### nod off

Redaktionell bestätigte gleichbedeutende Schreib-/Regional-/Ausdrucksvariante des gewählten Kandidaten; kein separates Lernziel, keine Antwortfreigabe.


Referenzen: `doze off|doze off/VERB|doze-off#einnicken`.

### note down

Redaktionell bestätigte gleichbedeutende Schreib-/Regional-/Ausdrucksvariante des gewählten Kandidaten; kein separates Lernziel, keine Antwortfreigabe.


Referenzen: `write down|write down/VERB|write-down#aufschreiben`.

### open up

Bestehender Vertrag blockiert auch historische bestätigte Alternativen an entfernten Satzverknüpfungen; keine allgemeine Bedeutungsidentität behauptet, keine Alternative entfernt. open|open/VERB|open#oeffnete (Karten-ID 9a1a28a337cefdbf11bceb185b271668), Satz source/everyday/s153, removed_in single_sentence_v1


Referenzen: `open|open/VERB|open#oeffnete`.

### own up to

Die konkret gewählte Bedeutungsabsicht ist durch vorhandene Lernziele bereits abgedeckt; Form-/Registervariante erzeugt keinen konkurrierenden Kopf. Karten-ID 6ff97349bdb24f544338b7ee4e51ea64; Referenz admit|admit/VERB|admit#zugeben. Fester Kontext menschen-beziehungen-v1-149-s1: I must admit that I was wrong about your friend.


Referenzen: `admit|admit/VERB|admit#zugeben`.

### pay back

Nach dem abschließenden Gesamtbestandsvergleich kein eigener neuer Kopf: Die festgelegte Lernabsicht ist bereits abgedeckt; eine engere Objektwahl oder Verlaufsnuance allein rechtfertigt keine Doppelreservierung. repay|repay/VERB|repay#zuruckzahlen (Karten-ID 207e628e8ad736b9ae886eb9136ef9c9)


Referenzen: `repay|repay/VERB|repay#zuruckzahlen`.

### pick on

Nach dem abschließenden Gesamtbestandsvergleich kein eigener neuer Kopf: Die festgelegte Lernabsicht ist bereits abgedeckt; eine engere Objektwahl oder Verlaufsnuance allein rechtfertigt keine Doppelreservierung. bully|bully/VERB|bully#mobben (Karten-ID 0086a1d771a64955ca39471f531b55a9)


Referenzen: `bully|bully/VERB|bully#mobben`.

### pitch in

Nach dem abschließenden Gesamtbestandsvergleich kein eigener neuer Kopf: Die festgelegte Lernabsicht ist bereits abgedeckt; eine engere Objektwahl oder Verlaufsnuance allein rechtfertigt keine Doppelreservierung. contribute|contribute/VERB|contribute#beitragen (Karten-ID 3b770029090c6212b97a8b1c8f904d47)


Referenzen: `contribute|contribute/VERB|contribute#beitragen`.

### point to

Abstrakte Belegfolgerung gegenüber direktem point out im Erstumfang zurückgestellt; keine allgemeine Synonymie behauptet.

### prevent from

In der normalen aktiven Konstruktion muss das Personen-/Sachobjekt zwischen Verb und Präposition stehen; keine zusammenhängende Ziellücke in dieser Form. Keine Ausweichschreibweise oder Platzhalter reserviert.

### pull through

Die konkret gewählte Bedeutungsabsicht ist durch vorhandene Lernziele bereits abgedeckt; Form-/Registervariante erzeugt keinen konkurrierenden Kopf. Karten-ID 3d488122029be452a77535edd8052f3c; Referenz recover|recover/VERB|recover#sich-erholen. Fester Kontext menschen-beziehungen-v1-120-s1: She needs time to recover from the stress of the last few months.


Referenzen: `recover|recover/VERB|recover#sich-erholen`.

### put away

Nach dem abschließenden Gesamtbestandsvergleich kein eigener neuer Kopf: Die festgelegte Lernabsicht ist bereits abgedeckt; eine engere Objektwahl oder Verlaufsnuance allein rechtfertigt keine Doppelreservierung. tidy|tidy/VERB|tidy#aufraumen (Karten-ID 8591fd87d2364a2368fda89ac52a9b95)


Referenzen: `tidy|tidy/VERB|tidy#aufraumen`.

### put up with

Die konkret gewählte Bedeutungsabsicht ist durch vorhandene Lernziele bereits abgedeckt; Form-/Registervariante erzeugt keinen konkurrierenden Kopf. Karten-ID d0722033fba9e2e57e3eb5bc06258d50; Referenz irregular:bear:base. Fester Kontext irregular-v1-b1-s004: I cannot bear the noise from the building site.


Referenzen: `irregular:bear:base`.

### reach out to

Nach dem abschließenden Gesamtbestandsvergleich kein eigener neuer Kopf: Die festgelegte Lernabsicht ist bereits abgedeckt; eine engere Objektwahl oder Verlaufsnuance allein rechtfertigt keine Doppelreservierung. contact|contact/VERB|contact#kontakt-aufnehmen (Karten-ID 1bf388493c5e2c3531c6c7f566248316)


Referenzen: `contact|contact/VERB|contact#kontakt-aufnehmen`.

### recover from

Die konkret gewählte Bedeutungsabsicht ist durch vorhandene Lernziele bereits abgedeckt; Form-/Registervariante erzeugt keinen konkurrierenden Kopf. Karten-ID 3d488122029be452a77535edd8052f3c; Referenz recover|recover/VERB|recover#sich-erholen. Fester Kontext menschen-beziehungen-v1-120-s1: She needs time to recover from the stress of the last few months.


Referenzen: `recover|recover/VERB|recover#sich-erholen`.

### refer to

Die konkret gewählte Bedeutungsabsicht ist durch vorhandene Lernziele bereits abgedeckt; Form-/Registervariante erzeugt keinen konkurrierenden Kopf. Karten-ID e99b822cc8189a3c8eab22c7497c996f; Referenz mention|mention/VERB|mention#erwahnen. Fester Kontext arbeit-bildung-v1-163-s1: Please mention your experience with children during the interview.


Referenzen: `mention|mention/VERB|mention#erwahnen`.

### remind of

In der normalen aktiven Konstruktion muss das Personen-/Sachobjekt zwischen Verb und Präposition stehen; keine zusammenhängende Ziellücke in dieser Form. Keine Ausweichschreibweise oder Platzhalter reserviert.

### result in

Redaktionell bestätigte gleichbedeutende Schreib-/Regional-/Ausdrucksvariante des gewählten Kandidaten; kein separates Lernziel, keine Antwortfreigabe.


Referenzen: `lead to|lead/VERB|lead#ergebnis`.

### ring back

Redaktionell bestätigte gleichbedeutende Schreib-/Regional-/Ausdrucksvariante des gewählten Kandidaten; kein separates Lernziel, keine Antwortfreigabe.


Referenzen: `call back|call back/VERB|call-back#zuruckrufen`.

### run over

Spezifische Verkehrsunfallhandlung gegenüber gewöhnlichen Bewegungs-/Reisehandlungen nachrangig.

### search for

Die konkret gewählte Bedeutungsabsicht ist durch vorhandene Lernziele bereits abgedeckt; Form-/Registervariante erzeugt keinen konkurrierenden Kopf. Karten-ID 9b6710a03038172d8a20f5afd0eef6ec; Referenz search|search/VERB|search#suchen. Fester Kontext reisen-v1-431-s1: We search our bags for the missing ticket.


Referenzen: `search|search/VERB|search#suchen`.

### sit down

Die konkret gewählte Bedeutungsabsicht ist durch vorhandene Lernziele bereits abgedeckt; Form-/Registervariante erzeugt keinen konkurrierenden Kopf. Karten-ID e40df1c1a5c0e85f3f57310a0403f23c; Referenz sit|sit/VERB|sit#sitzen. Fester Kontext source/missing/s31: Lina, please sit on this chair for the lesson.


Referenzen: `sit|sit/VERB|sit#sitzen`.

### soak up

Nahes Aufnehmen von Flüssigkeit; Erstauswahl soll keine dichte Gruppe ähnlicher Reinigungsmethoden bilden.

### split up

Redaktionell bestätigte gleichbedeutende Schreib-/Regional-/Ausdrucksvariante des gewählten Kandidaten; kein separates Lernziel, keine Antwortfreigabe.


Referenzen: `break up|break up/VERB|break-up#sich-trennen`.

### start over

Die konkret gewählte Bedeutungsabsicht ist durch vorhandene Lernziele bereits abgedeckt; Form-/Registervariante erzeugt keinen konkurrierenden Kopf. Karten-ID 17c2d0481f499ae8c010ba7b183c1100; Referenz let's start again|let's start again/INTJ|let-s-start-again#fangen-wir-noch-einmal-an. Fester Kontext alltagssprache-v1-0349-s1: Let's start again with a clean sheet of paper.


Referenzen: `let's start again|let's start again/INTJ|let-s-start-again#fangen-wir-noch-einmal-an`.

### stay away from

Redaktionell bestätigte gleichbedeutende Schreib-/Regional-/Ausdrucksvariante des gewählten Kandidaten; kein separates Lernziel, keine Antwortfreigabe.


Referenzen: `keep away from|keep away from/VERB|keep-away-from#abstand-halten-von`.

### step down

Leitungsamt abgeben ist ein enger organisatorischer Randbereich, im Erstumfang zurückgestellt.

### stretch out

Wörtliche Körperteil-Verlängerung; im begrenzten Erstumfang nicht zusätzlich benötigt.

### sum up

Die konkret gewählte Bedeutungsabsicht ist durch vorhandene Lernziele bereits abgedeckt; Form-/Registervariante erzeugt keinen konkurrierenden Kopf. Karten-ID ab1387f58b9637a055abfc2fb0ac62a7; Referenz to sum up|to sum up/ADV|to-sum-up#zusammenfassend. Fester Kontext alltagssprache-v1-0327-s1: To sum up, the trip was tiring but well worth it.


Referenzen: `to sum up|to sum up/ADV|to-sum-up#zusammenfassend`.

### sweep up

Zusätzliches nahes Reinigungsverfahren; nicht als Mengenfüller zwischen ähnlichen Hausarbeitszielen aufgenommen.

### switch off

Redaktionell bestätigte gleichbedeutende Schreib-/Regional-/Ausdrucksvariante des gewählten Kandidaten; kein separates Lernziel, keine Antwortfreigabe.


Referenzen: `turn off|turn off/VERB|turn-off#ausschalten`.

### switch on

Redaktionell bestätigte gleichbedeutende Schreib-/Regional-/Ausdrucksvariante des gewählten Kandidaten; kein separates Lernziel, keine Antwortfreigabe.


Referenzen: `turn on|turn on/VERB|turn-on#einschalten`.

### take in

Die noch nicht abgedeckte Schneiderbedeutung ist für diesen Erstumfang zu eng; keine seltenere Bedeutung allein für die Menge ausgewählt.

### talk into

In der normalen aktiven Konstruktion muss das Personen-/Sachobjekt zwischen Verb und Präposition stehen; keine zusammenhängende Ziellücke in dieser Form. Keine Ausweichschreibweise oder Platzhalter reserviert.

### talk out of

In der normalen aktiven Konstruktion muss das Personen-/Sachobjekt zwischen Verb und Präposition stehen; keine zusammenhängende Ziellücke in dieser Form. Keine Ausweichschreibweise oder Platzhalter reserviert.

### talk over

Die konkret gewählte Bedeutungsabsicht ist durch vorhandene Lernziele bereits abgedeckt; Form-/Registervariante erzeugt keinen konkurrierenden Kopf. Karten-ID c0241c28b9b024e9c9f488ca73bfcc57; Referenz discuss|discuss/VERB|discuss#besprechen. Fester Kontext arbeit-bildung-v1-123-s1: We will discuss the new timetable at our meeting on Friday.


Referenzen: `discuss|discuss/VERB|discuss#besprechen`.

### think up

Redaktionell bestätigte gleichbedeutende Schreib-/Regional-/Ausdrucksvariante des gewählten Kandidaten; kein separates Lernziel, keine Antwortfreigabe.


Referenzen: `come up with|come up with/VERB|come-up-with#sich-einfallen-lassen`.

### throw away

Die konkret gewählte Bedeutungsabsicht ist durch vorhandene Lernziele bereits abgedeckt; Form-/Registervariante erzeugt keinen konkurrierenden Kopf. Karten-ID f87842e7f4ff38d68833c9ef49ddd9cb; Referenz discard|discard/VERB|discard#wegwerfen. Fester Kontext natur-umwelt-v1-135-s1: Please discard any broken glass in the marked container.


Referenzen: `discard|discard/VERB|discard#wegwerfen`.

### tidy up

Die konkret gewählte Bedeutungsabsicht ist durch vorhandene Lernziele bereits abgedeckt; Form-/Registervariante erzeugt keinen konkurrierenden Kopf. Karten-ID 8591fd87d2364a2368fda89ac52a9b95; Referenz tidy|tidy/VERB|tidy#aufraumen. Fester Kontext alltag-zuhause-v1-220-s1: I need to tidy my room before my friends come over.


Referenzen: `tidy|tidy/VERB|tidy#aufraumen`.

### wait for

Die konkret gewählte Bedeutungsabsicht ist durch vorhandene Lernziele bereits abgedeckt; Form-/Registervariante erzeugt keinen konkurrierenden Kopf. Karten-ID 47eed138e4bf09bff6135f5b3993dd1a; Referenz wait|wait/VERB|wait#warten. Fester Kontext source/everyday/s76: David can wait for his friends in the park.


Referenzen: `wait|wait/VERB|wait#warten`.

### walk away from

Beenden einer Verpflichtung/Bindung gegenüber ausgewählten klareren Beendigungs- und Beziehungskontexten zurückgestellt.

### watch out for

Redaktionell bestätigte gleichbedeutende Schreib-/Regional-/Ausdrucksvariante des gewählten Kandidaten; kein separates Lernziel, keine Antwortfreigabe.


Referenzen: `look out for|look out for/VERB|look-out-for#ausschau-halten-nach`.

### wind down

Nach dem abschließenden Gesamtbestandsvergleich kein eigener neuer Kopf: Die festgelegte Lernabsicht ist bereits abgedeckt; eine engere Objektwahl oder Verlaufsnuance allein rechtfertigt keine Doppelreservierung. relax|relax/VERB|relax#sich-entspannen (Karten-ID 2d8309fbb2f13d238398df47e2ca7a55)


Referenzen: `relax|relax/VERB|relax#sich-entspannen`.

### wipe down

Weiteres nahes Reinigungsverfahren; Erstumfang priorisiert klar verschiedene Abläufe statt vieler ähnlicher Oberflächenreinigungen.

### work out

Die konkret gewählte Bedeutungsabsicht ist durch vorhandene Lernziele bereits abgedeckt; Form-/Registervariante erzeugt keinen konkurrierenden Kopf. Karten-ID fc64117c8b00bb01a9657249d5f13ddf; Referenz exercise|exercise/VERB|exercise#trainieren. Fester Kontext alltag-zuhause-v1-242-s1: I exercise three times a week to stay fit.


Referenzen: `exercise|exercise/VERB|exercise#trainieren`.

### wrap up

Die konkret gewählte Bedeutungsabsicht ist durch vorhandene Lernziele bereits abgedeckt; Form-/Registervariante erzeugt keinen konkurrierenden Kopf. Karten-ID 7532fadd05e291ccf9c9da028701fec4; Referenz finish|finish/VERB|finish#beenden. Fester Kontext alltag-zuhause-v1-246-s1: Can you finish your homework before we leave for the cinema?


Referenzen: `finish|finish/VERB|finish#beenden`.


## Grenzen, GitNexus und nächste Übergabe

GitNexus zuerst für `validate_context`, `export`, `verify_zip` und `bind_new_pack` verwendet, danach gezielt Quellen geprüft. Index: `sprachlernapp`, Stand 11.10.2026, indexierter Commit 90c2930, vor Beginn ein Commit hinter HEAD c428c9f. Begrenzte Kontextausgabe und UNKNOWN bei neuen Metadaten/NEXTSTEPS sind keine vollständige Abdeckung oder Sicherheitsfreigabe. Roadmap-Impact LOW: neun Dokumentabhängigkeiten, zwei direkt, keine erfassten Prozesse. Neue Dokument-/JSON-Ziele waren nicht indexiert. Die wörtlichen Referenzen und bestehenden Datenverträge wurden ergänzend vollständig geprüft; keine Funktion geändert, kein Indexneubau. Rohbelege: `gitnexus-preflight.json`; Änderungsanalyse vor Commit separat in `gitnexus-detect-*.json`.

Der Index war vor Beginn leer. Vorbestehende Änderungen in NEXTSTEPS und fremde untracked Lieferungen/Batch-3-/Batch-4-Berichte sowie Batch-4-/Batch-5-Kontexte bleiben außerhalb des Commitumfangs. Das eigene Inkrement umfasst nur die vier neuen JSON-Dateien, den neuen Authoring-Bericht und die begrenzte Roadmap-Aktualisierung; kein pauschales git add, kein Push. ZIP und Prüfartefakte liegen wie etabliert im ignorierten build-Verzeichnis. Git-Ausgaben werden dort dokumentiert.

Bekannte Altbefunde bleiben getrennt: alte Glossen-/Formvergleichslisten, Linterhinweise und historische Whitespace-Befunde (DESIGN.md:162–164; docs/alltag-zuhause-continuation.md:148/153; Arbeit-Bildung-Batch-1/-2-Berichte). Keine pauschale Bereinigung. Kein user.db-/Reviewzugriff, keine Cloud-/Modellaufrufe, keine Code-/Test-/Produktionsänderung, keine öffentliche Sprachfreigabe. Auswahlbedeutungen und Hinweise sind redaktionelle Entscheidungen, keine unabhängige sprachwissenschaftliche Abnahme und noch keine Satzfreigabe.

Nächster Schritt: **Verbalphrasen: 91 aktuelle Batch-1-Ziele anhand der geprüften ZIP im Chat redigieren.** Nur `authoring_context.json.entries` redigieren, weitere 90 Ziele später.

Vollständiger lokaler Uploadpfad:

`/Users/ardasayar/Documents/FlutterProjekte/sprachapp/build/verbalphrasen_authoring_batch_1.zip`

## Gezielte Dokument- und Commitprüfung

Tatsächlich ausgeführt (macOS; Git-Befehle identisch unter Windows):

```text
git diff --check -- NEXTSTEPS.md docs/content-roadmap-v1.md docs/verbalphrasen-authoring.md pipeline/data/selection/verbalphrasen_v1.json pipeline/data/selection/verbalphrasen_batch_1_context_v1.json pipeline/data/words/en.verbalphrasen_batch_1_context_v1.json pipeline/data/learning_groups/en.verbalphrasen_batch_1_context_v1.json
Keine Ausgabe; Exit 0

git diff --cached --check -- docs/content-roadmap-v1.md docs/verbalphrasen-authoring.md pipeline/data/selection/verbalphrasen_v1.json pipeline/data/selection/verbalphrasen_batch_1_context_v1.json pipeline/data/words/en.verbalphrasen_batch_1_context_v1.json pipeline/data/learning_groups/en.verbalphrasen_batch_1_context_v1.json
Keine Ausgabe; Exit 0
```

Der gestagte Check erfasst zusätzlich die fünf zuvor untracked Dateien; der gewöhnliche Worktree-Check allein tut das nicht. Die eigenen Dokumente haben LF, kein CRLF-Erhaltungsfall dieses Auftrags. Logs: `diff-check.log`, `staged-diff-check.log`.

MCP `detect_changes({repo: "sprachlernapp", scope: "all"})`: sieben erfasste Dokumentabschnitte / sieben geänderte Dateien, null erfasste Prozesse, risk_level low. `scope: "staged"`: drei erfasste Roadmap-Abschnitte / sechs gestagte Dateien, null erfasste Prozesse, risk_level low. Beide Antworten ohne partial/truncated-Markierung; die neue JSON-/Berichtsabdeckung bleibt dennoch mangels Indexierung UNKNOWN. Kein vollständiger Graphnachweis für die neuen Dateien behauptet. Datenidentitäten und vorhandene Import-/Exportverträge wurden durch die tatsächlichen Validatoren und Offline-Tests geprüft. Es gibt keine uncommittete Codeabhängigkeit im Inkrement.

`git diff --cached --name-only` bestätigt ausschließlich die vier neuen Verbalphrasen-JSONs, `docs/verbalphrasen-authoring.md` und `docs/content-roadmap-v1.md`. NEXTSTEPS und vorbestehende fremde Dateien sind ausgeschlossen. Der lokale Commit und abschließende Status werden unter `build/verbalphrasen_authoring_checks/commit.log` und `status-final.txt` festgehalten; kein Push. ZIP unverändert nach erfolgreicher Prüfung.
