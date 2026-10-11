# Unregelmäßige Verben – Batch 3: Import, Staging und Übergabe

Stand: 10.10.2026. **`irregular_verbs_batch_3_v1` intern gestagt und verifiziert.** 84 neue feste Satzpaare und 15 unveränderte Wiederverwendungen ergänzen den Pack auf 2486 Karten und 303 Formziele, verteilt auf 101/101/101 Übungen. Echte gemeinsame Projektion: **2372 Übungen / 2167 Wörter**. Die geprüfte Batch-4-ZIP enthält genau 81 neue Satzaufträge und 18 Wiederverwendungen bei vollständig erhaltenem 402-Ziele-Katalog.

## Tatsächliche Eingaben und Sicherung

Die Lieferung lag bereits entpackt unter `irregular_verbs_batch_3_lieferung/`; dieser tatsächliche Ordner wurde verwendet. Gelesen/geprüft: `editorial_content_v3.json`, `README.txt`, `token_review.json`, `inherited_gloss_comparison.json`, `validation_report.json`, `satzuebersicht.html` und Manifest. Alle sieben manifestierten Lieferdateien stimmen per SHA256 und sind am Ende unverändert bestätigt. Die Begleitprüfung aus dem Chat wurde nicht als Repository-Import/Flutter-Nachweis ausgegeben.

Basis: `pipeline/out/irregular_verbs_batch_2_v1/pack.json` und `content.sqlite`, Schema 4. Kontext: `build/irregular_verbs_authoring_batch_3.zip`; tatsächliche lokale Snapshots unter `pipeline/data/selection/irregular_verbs_batch_3_context_v1/` (`selection.json`, `registry.json`, `learning_groups.json`). Basis, eingebettete Auswahl und deren Hash, Registry und Gruppen sind exakt gegen lokalen/ZIP-Kontext gebunden. Keine neue Basis oder Identität wurde passend gerechnet.

**Vor dem Staging** wurden Quell-JSON, Quell-SQLite, Produktionsasset und Asset-Manifest bytegenau nach `build/irregular_verbs_batch_3_backup/` gesichert, jeweils mit ursprünglichen relativen Pfaden. `hashes.json` protokolliert die vier Sicherungsdateien, `baseline.json` erfasst 2618 vorbestehende Dateien einschließlich historischer Authoring-ZIPs. Backup und alter Quellpack wurden vor und nach dem Staging erneut hashgeprüft.

| Ausgangsdatei | SHA256 |
|---|---|
| Batch-2-Quell-JSON | `78368d24b9a585b5d2f9cf5b1e336b2f459f3c38410fa76e02f9fe3c99ff0197` |
| Batch-2-Quell-SQLite / vorheriges Asset | `ca9256a877172cb3390e54ff8d4208fff084764239d6df7b1fcc28a80fa98758` |
| vorheriges Asset-Manifest | `2ebc89100b3129c26fe9f25099cae6bcfbacea9324cb8e269bdb0d9be656232d` |
| Eingangs-Authoring-ZIP | `5802ffb0118fad3963016766e06f5e22d55a3c6d8cf40a1f6a359c98da67bd3b` |
| Original-Batch-3-Importdatei | `1ceff314d963391fa2183b76058f130de5d40961e2796e53e90eb656d37d78b6` |

## Vollständige Lieferprüfung und gezielte Korrekturen

Alle **84 englischen/deutschen Satzpaare und 857 Tokenpositionen** wurden mit Zieldefinition, Formfunktion und konkretem Kontext gegengelesen. Die 768 Wortpositionen in `token_review.json` stimmen mit den Originalbindungen überein; 89 weitere Positionen sind Satzzeichen. Die HTML-Übersicht entspricht allen Originalsatzpaaren. Die 99 aktuellen Formziele und alle Karten-/Lexikal-/Praxis-/Besitzmetadaten sind exakt das aktuelle Auswahl-Delta: 84 neue Karten, 15 hashgebundene Wiederverwendungen, 33 zusätzliche Mitgliedschaften pro Ansicht. Spätere Metadaten wurden nicht importiert.

Die **27 zusätzlichen Begleitwortsenses** bleiben Wörterbuchdaten, ohne zusätzliche Lernkarten oder Wortbesitzer. Tatsächliche Lieferung: 36 Senses = neun ausgewählte Zielbedeutungen + 27 Begleitbedeutungen, 30 Lemmas und 77 Wörterbuchformzeilen. Passende Altbedeutungen werden wiederverwendet; gleiche Oberfläche entscheidet nicht über die Bedeutung. `ride` bleibt Mitfahren, `set` Abstellen, `mean` Bedeuten, `shine` Licht aussenden. `fall asleep` wird vom räumlichen Fallen getrennt; `glasses` in s064 sind Trinkgläser. Kein Eingriff in alte gemeinsame Glossen oder künstliche Tempus-Senses.

Drei neue Tokenbindungen waren nachweislich falsch: Die neue Sense `to#bedeutung_fuer_person` definiert eine Person, für die etwas eine Bedeutung oder einen Wert hat. Sie passt zu s010/s011, aber nicht zu den folgenden Bewegungszielen:

| Referenz | Tokenindex | Vorher | Nachher | Konkreter Grund |
|---|---:|---|---|---|
| irregular-v1-b3-s004 | 7 | to#bedeutung_fuer_person | to#nach_richtung | on the way to school: Zielort Schule |
| irregular-v1-b3-s037 | 8 | to#bedeutung_fuer_person | to#nach_richtung | rode the bus to school: Zielort Schule |
| irregular-v1-b3-s080 | 4 | to#bedeutung_fuer_person | to#nach_richtung | sunk to the bottom: Bewegungsziel Gewässergrund |

Die vorhandene Richtungs-Sense und ihre bestehende Formglosse wurden wiederverwendet. Die Korrektur erfolgte ausschließlich in `pipeline/data/curation/irregular_verbs_batch_3_import_v1.json`. Vollständige Vorher-/Nachher-Belege, Begründungen, Original-/Importhash und aktualisierte Reviews: `pipeline/data/curation/irregular_verbs_batch_3_corrections_v1.json`. Drei betroffene Tokenreview-Hashes wurden neu berechnet; Originalauswahl, Quellhash und Linkhashes bleiben unverändert. Keine neuen Senses, Glossen, Karten oder Besitzer durch die Korrektur. Alle 84 englischen Texte, deutschen Übersetzungen und Offsets sind unverändert.

Importkopie SHA256: `5ccf7a2ee86eecdfaeacd0e6d7c852c37694333bd2810427cca389d23f7b6139`.

Zwei Alternativen wurden wörtlich eingesetzt und in ihrem tatsächlichen Partizipkontext geprüft; `accepted` bleibt ausschließlich die Zielform:

```text
ALTERNATIVE irregular-v1-b3-s018 The gardener has mowed the grass around the apple tree.
ALTERNATIVE irregular-v1-b3-s028 The tests have proved that the water is safe to drink.
```

`mowed` in s018 und `proved` in s028 sind nur in diesen Lücken neutral. Keine weitere automatische Synonym-/Tempusfreigabe. Die 15 wiederverwendeten Karten wurden mit festen Sätzen sowie Karten-/Kontexthash geprüft; sämtliche Alt-IDs, Tokens und Übungszustandsidentitäten bleiben erhalten.

## Geerbte Glossen: weiterhin getrennt offen

Die **20 Batch-2-Befunde** in `irregular_verbs_batch_2_lieferung/inherited_gloss_findings.json` bleiben unverändert offen. Alle entsprechenden Wörterbuchwerte sind gegen Quelle und fertigen Export exakt geprüft. Dazu kommen **12 Vergleichseinträge** aus `inherited_gloss_comparison.json`; sie sind keine Mutationsoperation und nicht pauschal zwölf neue Fehler.

| Oberfläche | Geerbte Glosse | Konkrete Beurteilung für Batch 3 |
|---|---|---|
| lost | verloren | Präteritum in s004 nicht ausdrücklich abgedeckt; Partizip s005 passt. |
| make | herstellen | herstellen/anfertigen ist eine Formulierungsvariante, kein belegter Fehler. |
| made | hergestellt | Partizip s008 passt; explizite Präteritumform für s007 fehlt. |
| meant | bedeutete | Präteritum s010 passt; Partizipabdeckung s011 prüfen. |
| met | trafen | trafen passt nicht zum Singular Sara in s012; Partizip s013 nicht abgedeckt. |
| put | legen | Grundform s029 passt; Past/Partizip s030/s031 nicht ausdrücklich abgedeckt. |
| read | lesen | Grundformglosse ist erhalten; funktionsbezogene Anzeige für Past/Partizip s035/s036 prüfen. |
| rang | ertönte / klingelte | ertönte/klingelte gegenüber klingelte/läutete: passende Formulierungsvariation, kein pauschaler Fehler. |
| run | rennen | Grundform s045 passt; Partizip s047 nicht ausdrücklich abgedeckt. |
| sent | schickte | Präteritum s058 passt; Partizipabdeckung s059 prüfen. |
| sang | sangen | sangen passt nicht zum Singular Sara in s076. |
| sat | saß; saßen | Präteritum s081 passt; Partizip s082 nicht ausdrücklich abgedeckt. |

Keiner dieser geerbten Werte wurde geändert. Die Satzübersetzungen und Zieldefinitionen sind getrennt geprüft. Eine spätere gemeinsame Glossenbereinigung braucht eine eigene versionierte Kurationsoperation mit allen betroffenen Bestandskontexten; sie wurde hier nicht als erledigt ausgewiesen.

## Tatsächlicher Export und gemeinsame Projektion

Export in das neue Verzeichnis `pipeline/out/irregular_verbs_batch_3_v1/`; keine bestehende Ausgabe überschrieben. Alle alten JSON-Zeilen und SQL-IDs/Spaltenwerte sind unverändert erhalten, einschließlich sämtlicher Batch-1/2-Sätze, Reviews, Tokens, Besitz-/Praxispositionen, Wörterbuchzeilen und der Batch-1-Besuchsbindung. Der nullable-Definitionsfix des App-Lesers ist unverändert.

| Größe | Tatsächlicher Wert |
|---|---:|
| Karten insgesamt / aktive feste Satzbindungen | 2486 |
| Historische Karten-Satzbindungen | 3014 |
| Satztexte insgesamt | 3020 |
| Formziele / Übungsmitgliedschaften insgesamt | 303 |
| Übungen je Formansicht | 101 / 101 / 101 |
| Importierte Wiederverwendungen insgesamt | 53 = 16 + 22 + 15 |
| Lexikalanker insgesamt | 101 |
| Lexikalanker dieses Batches | 33: 15 bereits vorhandene, 18 neue Lernbedeutungen |
| Neue Oberflächenbesitzer / Besitzer insgesamt | 56 / 2299 |
| Wortaliase | 37, unverändert |
| Gemischtes Übungsinventar | 2372 |
| Gemischte lexikalische Wörter | 2167 |

Die acht normalen Ansichten bleiben bei **160 / 489 / 241 / 245 / 245 / 249 / 250 / 242 Übungen**. `form_only`-Karten gelangen über ihre Formansichten in den Übungsvorrat, auch wenn ihre Oberfläche einen Besitzer im normalen Stapel hat. Besitzerpositionen bleiben bestehen und werden angehängt; Praxispositionen sind pro Ansicht exakt 1..101.

Die Werte stammen aus dem vorhandenen Dart-Diagnosewerkzeug und dem echten App-Lesetest mit leeren synthetischen Zuständen und sämtlichen Inhaltsansichten. Ergebnis: **2372 Übungen / 2167 Wörter**, nicht aus Stapelsummen geschätzt. Der Abgleich zu Batch 2 ergibt diesmal 84 zusätzliche Übungen und 18 zusätzliche Wörter; 15 Wiederverwendungen waren bereits angeboten. Die im vorigen Batch sichtbar gewordene alte `had`-Partizipkarte bleibt erhalten. Die Rohansichtsmenge 2435 ist wegen Wiederverwendungen/Lerngruppen kein globaler Zähler. Keine echte `user.db`, Zustandsübertragung oder Rücksetzung.

## Tatsächliche Befehle, Ausgaben und Exitcodes

Ausgeführt auf macOS. Flutter-/Dart-Befehle sind unter Windows PowerShell identisch; dort für Python den aktivierten vorhandenen Projektinterpreter `python` statt `pipeline/.venv-macos/bin/python` verwenden. Lokale macOS-Prüfhilfen/Logs: `/tmp/irregular-verbs-b3/`. Keine Paketinstallation, Cloud-/Modellaufrufe, Remote-Migrationen, Commits oder Pushes.

```text
pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --verify-zip build/irregular_verbs_authoring_batch_3.zip
zip_verification=PASS; sqlite_tables=22; exact Batch-2 source binding PASS
Exit 0

pipeline/.venv-macos/bin/python /tmp/irregular-verbs-b3/check_and_correct.py
BASIS / DELIVERY / LOCAL / ZIP source, selection, registry, groups binding PASS
BINDING_HASHES {"groups": "62573bc0f9ec257a89c6c388d0e579c78add800f2b54b63f28ce2c36d5865c9e", "registry": "c5f19d8b7f3d1b6537df96f20a3aa58ac10be0e19e04071329ee59ea046320a8", "selection": "381de31691a6739aac3055a7a63680a44628b4e1dffaebdcb04237e90609f9de"}
SELECTION {"current": 99, "future": 99, "imported": 204, "new_cards": 165, "new_form_targets": 198, "new_lexical_targets": 66, "new_surface_reservations": 0, "reused_cards": 71}
CURRENT exact metadata PASS: 99 form targets / 84 new cards / 15 unchanged reuse / 33 per view; no future delta
TOKEN_REVIEW 768 word positions and HTML 84 sentence pairs exact PASS; all 857 positions reviewed
INHERITED inherited_gloss_findings.json 20 source keys match; no mutations or automatic error verdict
INHERITED inherited_gloss_comparison.json 12 source keys match; no mutations or automatic error verdict
METADATA_PREFIX 3 PASS; forms 303 ; missing future sentences not approved
METADATA_PREFIX 4 PASS; forms 402 ; missing future sentences not approved
CORRECTION irregular-v1-b3-s004 token 7 to/ADP|to#bedeutung_fuer_person -> to/ADP|to#nach_richtung
CORRECTION irregular-v1-b3-s037 token 8 to/ADP|to#bedeutung_fuer_person -> to/ADP|to#nach_richtung
CORRECTION irregular-v1-b3-s080 token 4 to/ADP|to#bedeutung_fuer_person -> to/ADP|to#nach_richtung
IMPORT_COPY pipeline/data/curation/irregular_verbs_batch_3_import_v1.json sha256 5ccf7a2ee86eecdfaeacd0e6d7c852c37694333bd2810427cca389d23f7b6139
CORRECTIONS: 3 new token bindings and bound reviews; 0 new senses/glosses/cards/owners; English/German sentence pairs unchanged
Exit 0

pipeline/.venv-macos/bin/python pipeline/scripts/import_editorial_patch.py --source pipeline/out/irregular_verbs_batch_2_v1/pack.json --create pipeline/data/curation/irregular_verbs_batch_3_import_v1.json --registry pipeline/data/selection/irregular_verbs_batch_3_context_v1/registry.json --out pipeline/out/irregular_verbs_batch_3_v1
{
  "status": "ok",
  "internal_test_pack": true,
  "ai_calls": 0,
  "ai_cost_usd": 0,
  "sqlite_counts": {
    "languages": 1,
    "lemmas": 3541,
    "senses": 5046,
    "cards": 2486,
    "dictionary_forms": 6028,
    "decks": 11,
    "deck_cards": 2403,
    "deck_words": 2299,
    "word_aliases": 37,
    "sentences": 3020,
    "sentence_tokens": 33398,
    "card_sentences": 3014,
    "stories": 1,
    "story_sentences": 6,
    "exercises": 0,
    "grammar_rules": 0,
    "audio_assets": 0,
    "content_releases": 1,
    "lexical_targets": 101,
    "card_lexical_targets": 306,
    "form_targets": 303,
    "deck_practice_targets": 303
  },
  "sha256": "f0adf97135225d240078cd92209a9af93597932f82c3c4dab1340e015628ddeb"
}
Exit 0

pipeline/.venv-macos/bin/python /tmp/irregular-verbs-b3/verify_pack.py
PRESERVATION: every old JSON row and SQL ID/value unchanged PASS; 2402 old cards, fixed sentences, tokens, positions, dictionary and Batch-1/2 contents preserved
SQLITE_ALL_ROWS {"audio_assets": 0, "card_lexical_targets": 306, "card_sentences": 3014, "cards": 2486, "content_releases": 1, "deck_cards": 2403, "deck_practice_targets": 303, "deck_words": 2299, "decks": 11, "dictionary_forms": 6028, "exercises": 0, "form_targets": 303, "grammar_rules": 0, "languages": 1, "lemmas": 3541, "lexical_targets": 101, "senses": 5046, "sentence_tokens": 33398, "sentences": 3020, "stories": 1, "story_sentences": 6, "word_aliases": 37}
LINTER 3014 link inventory; 0 errors; 455 warnings
NEW LINT FINDINGS [{'card': 'irregular:mow:past_participle', 'level': 'warn', 'rule': 'i+1', 'message': "'gardener'/'gardener' Zipf 3.49 below 3.5"}, {'card': 'irregular:overtake:past_participle', 'level': 'warn', 'rule': 'i+1', 'message': "'motorbike'/'motorbike' Zipf 3.19 below 3.5"}, {'card': 'irregular:ride:past_participle', 'level': 'warn', 'rule': 'i+1', 'message': "'tram'/'tram' Zipf 3.46 below 3.5"}, {'card': 'irregular:ring:past_participle', 'level': 'warn', 'rule': 'i+1', 'message': "'doorbell'/'doorbell' Zipf 3.05 below 3.5"}, {'card': 'irregular:shine:base', 'level': 'warn', 'rule': 'i+1', 'message': "'brightly'/'brightly' Zipf 3.44 below 3.5"}]
PRACTICE irregular_verbs_base 101 positions 1..101 PASS
PRACTICE irregular_verbs_past 101 positions 1..101 PASS
PRACTICE irregular_verbs_participle 101 positions 1..101 PASS
OWNERS: old positions unchanged; +56 new surfaces; 2299 total; no new aliases
REUSE: all 15 Batch-3 contexts/evidence unchanged after import PASS; 53 reused form cards in imported catalogue
INHERITED 20 entries from irregular_verbs_batch_2_lieferung/inherited_gloss_findings.json unchanged PASS
INHERITED 12 entries from irregular_verbs_batch_3_lieferung/inherited_gloss_comparison.json unchanged PASS
CORRECTIONS: three direction bindings match separate import copy PASS; 0 old data mutations
BACKUP and original Batch-2 pack hashes preserved PASS
Exit 0
```

Alle 22 Tabellen wurden mit ihren Spalten und allen Nutzwerten vollständig gegen `build_rows` abgeglichen. Der reguläre Satzlinter lief im bestehenden Export: null Fehler und 455 Hinweise über das gesamte Linkinventar. Genau fünf neue Frequenzhinweise, wie angekündigt:

| Satz | Wort | Tatsächlicher Zipf-Wert |
|---|---|---:|
| s018 | gardener | 3,49 |
| s024 | motorbike | 3,19 |
| s038 | tram | 3,46 |
| s041 | doorbell | 3,05 |
| s065 | brightly | 3,44 |

Keine Umformulierung zur Warnungsbeseitigung. Metadatenpräfixe 3/4 mit 303/402 Formzielen wurden zusätzlich durch vorhandene Form-, Gruppen- und Registryvalidatoren geprüft; die fehlenden Batch-4-Sätze sind nicht vorab freigegeben.

```text
pipeline/.venv-macos/bin/python -m pytest pipeline/tests/test_form_targets.py pipeline/tests/test_form_authoring_details.py pipeline/tests/test_word_registry.py pipeline/tests/test_authoring_context.py pipeline/tests/test_authoring_continuation.py pipeline/tests/test_editorial_import.py -q
........................................................................ [ 75%]
........................                                                 [100%]
96 passed in 18.10s
Exit 0

flutter test --no-pub test/data/form_content_test.dart test/data/form_learning_test.dart test/domain/form_projection_test.dart test/form_learning_flow_test.dart test/form_counts_widget_test.dart
00:08 +27: All tests passed!
Exit 0

dart run tool/report_learning_groups.dart pipeline/out/irregular_verbs_batch_3_v1/content.sqlite
mixed: raw_words=2435; learning_targets=2372; lexical_words=2167; form_memberships=303
Exit 0

dart run tool/stage_content_pack.dart --from pipeline/out/irregular_verbs_batch_3_v1
staged assets/content/en/content.sqlite
  version irregular_verbs_batch_3_v1, schema 4, 16429056 bytes
  sha256 f0adf97135225d240078cd92209a9af93597932f82c3c4dab1340e015628ddeb
  22 table counts match finalization_report.json
  INTERNES TEST-PACK: own devices and selected testers only, no public content release
Exit 0

dart run tool/stage_content_pack.dart --verify
verified assets/content/en/content.sqlite
  version irregular_verbs_batch_3_v1, schema 4, 16429056 bytes
  sha256 f0adf97135225d240078cd92209a9af93597932f82c3c4dab1340e015628ddeb
  22 table counts match finalization_report.json
  INTERNES TEST-PACK: own devices and selected testers only, no public content release
Exit 0

flutter test --no-pub test/data/real_pack_test.dart
00:00 +0: loading /Users/ardasayar/Documents/FlutterProjekte/sprachapp/test/data/real_pack_test.dart
00:00 +0: staged pack: all cards and sentence links readable, read-only
SCHEMA4 mixed exercises=2372 lexical=2167; 303 forms / 53 reuse / cut 3 identities PASS
deck allgemeine-sprache: 160 learning targets, 178 ownership cards, 178 fixed sentence assignments verified
deck reisen: 489 learning targets, 514 ownership cards, 514 fixed sentence assignments verified
deck alltag-zuhause: 241 learning targets, 253 ownership cards, 253 fixed sentence assignments verified
deck arbeit-bildung: 245 learning targets, 250 ownership cards, 250 fixed sentence assignments verified
deck menschen-beziehungen: 245 learning targets, 251 ownership cards, 251 fixed sentence assignments verified
deck koerper-gesundheit: 249 learning targets, 260 ownership cards, 260 fixed sentence assignments verified
deck essen-trinken: 250 learning targets, 250 ownership cards, 250 fixed sentence assignments verified
deck natur-umwelt: 242 learning targets, 246 ownership cards, 246 fixed sentence assignments verified
deck irregular_verbs_base: 101 learning targets, 97 ownership cards, 97 fixed sentence assignments verified
deck irregular_verbs_past: 101 learning targets, 0 ownership cards, 0 fixed sentence assignments verified
deck irregular_verbs_participle: 101 learning targets, 0 ownership cards, 0 fixed sentence assignments verified
pack irregular_verbs_batch_3_v1 (schema 4, internal: true); 11 decks: 2299 cards, 2486 card sentences, 153 with valid_alternatives, 2486 cards in the pack
01:08 +1: All tests passed!
Exit 0

flutter analyze --no-pub
Analyzing sprachapp...
No issues found! (ran in 3.7s)
Exit 0
```

Der bestehende Elf-Stapel-Lesetest wurde ausschließlich um Batch-3-Erwartungen und die konkreten neuen Homographen erweitert: drei `read`-IDs mit drei festen Sätzen, drei `put`-IDs, drei `set`-IDs sowie drei `run`-Familienkarten (davon zwei gleich geschriebene run-Funktionen). Vorhandene cut/hit/lay-Prüfungen, acht normale Stapel und exakte Reuse-/Wort-/Übungszahlen bleiben geprüft. 96 Pipeline-Tests, 27 gezielte Flutter-Formtests und ein Pack-Lesetest bestanden; keine vollständige Flutter-Suite. Die bestehenden Formtests geben eine Drift-Debugwarnung zu mehreren Testdatenbanken aus und bestehen. Kein Geräte-/Simulatortest ausgeführt; normale App-Einstiegsdatei unverändert, keine öffentliche Freigabe behauptet.

## Batch-4-Übergabe mit vollständigem Kontext

```text
pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --selection pipeline/data/selection/irregular_verbs_batch_3_context_v1/selection.json --prepare-continuation irregular_verbs_batch_4_context_v1 --batch 4 --source-pack pipeline/out/irregular_verbs_batch_3_v1/pack.json --source-sqlite pipeline/out/irregular_verbs_batch_3_v1/content.sqlite --out pipeline/data/selection/irregular_verbs_batch_4_context_v1
{
  "snapshots": "PASS",
  "selection": "pipeline/data/selection/irregular_verbs_batch_4_context_v1/selection.json",
  "registry": "pipeline/data/selection/irregular_verbs_batch_4_context_v1/registry.json",
  "partition_counts": {
    "imported": 303,
    "current": 99,
    "future": 0
  }
}
Exit 0

pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --selection pipeline/data/selection/irregular_verbs_batch_4_context_v1/selection.json --batch 4 --out build/irregular_verbs_authoring_batch_4.zip
Exit 0
pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --verify-zip build/irregular_verbs_authoring_batch_4.zip
Exit 0
```

Neue Snapshots: `pipeline/data/selection/irregular_verbs_batch_4_context_v1/{selection,registry,learning_groups}.json`. Die Fortsetzungsmetadaten wurden an den tatsächlich validierten Export gebunden und nach bestandenem Staging nochmals bytegenau gegen Export/Asset bestätigt; die ZIP wurde anschließend über den bestehenden Exporter veröffentlicht. Keine alte Auswahl/Registry oder ZIP umbenannt bzw. überschrieben. Alle 402 Ziele bleiben im Kontext; aktuelle Auftragssätze werden nicht vorweg erzeugt.

Erneute Verifier-Ausgabe, Referenzlisten hier als Partitionslängen dargestellt:

```json
{
  "zip_verification": "PASS",
  "zip_sha256": "baf5148a83a4c05850561be73a55a7017b9d6773cacc0dc90a8198ee742aea55",
  "content_schema_version": 4,
  "sqlite_tables": 22,
  "counts": {
    "imported": 303,
    "current": 99,
    "future": 0,
    "reused_cards": 71,
    "new_form_targets": 99,
    "new_lexical_targets": 33,
    "new_surface_reservations": 0,
    "new_cards": 81
  },
  "partition_counts": {
    "imported": 303,
    "current": 99,
    "future": 0
  }
}
```

ZIP geschlossen, erneut geöffnet und vollständig geprüft: CRCs, 77 Manifest-Dateihashes, tatsächliche Basisbindung, alle Referenzen, exakte Identitäten, Wiederverwendungsbelege, Metadatenpräfixe, Partition und alle Zeilen aller 22 Quelltabellen. Pack, SQLite und lokale Auswahl-/Registry-/Gruppensnapshots sind zusätzlich bytegleich mit den ZIP-Einträgen.

Partition: **303 importiert / 99 aktuell / 0 später**. `current_authoring_tasks.json` enthält **81 neue Satzaufträge und 18 Wiederverwendungen**. Der Gesamtzähler 71 Reuse-Belege bleibt katalogweit. Kein neuer Oberflächenkatalog wurde reserviert; neue Karten/Sätze für Batch 4 fehlen ausdrücklich weiterhin.

| Abschlusshash | SHA256 |
|---|---|
| Batch-3-Export-JSON | `89fffbe42331ef1283f9a3dec0ddc0ef1bbd6001846bd3636962e38db953edfe` |
| Export-SQLite / gestagtes Asset | `f0adf97135225d240078cd92209a9af93597932f82c3c4dab1340e015628ddeb` |
| neues Asset-Manifest | `0a19ce65d0e915ece9159750ab887b7ce864a8e1a98a25864792329cf60d35a0` |
| Batch-4-ZIP | `baf5148a83a4c05850561be73a55a7017b9d6773cacc0dc90a8198ee742aea55` |

## Dateiabgleich, Whitespace und nächster Schritt

Der Hashaudit über 2618 vorbestehende Dateien ergab vor dem Bericht ausschließlich Änderungen an `test/data/real_pack_test.dart`; abschließend kommt `NEXTSTEPS.md` hinzu. Original-Lieferungen aller drei Batches, Batch-1-Korrektur, Leserfix, historische Packs, Snapshots und frühere Authoring-ZIPs bleiben unverändert. Die gesicherten Produktionsdateien sind bytegleich mit ihrem Ausgangsstand; das aktuelle Asset/Manifest wurde ausschließlich durch das Staging-Werkzeug ersetzt. Neue Dateien: Importkopie/Korrekturbeleg, Export, Sicherung, Fortsetzung, ZIP und dieser Bericht.

Eigene Diffprüfung: `git -c core.whitespace=cr-at-eol diff --check -- NEXTSTEPS.md docs/irregular-verbs-batch-3-import.md test/data/real_pack_test.dart pipeline/data/curation/irregular_verbs_batch_3_import_v1.json pipeline/data/curation/irregular_verbs_batch_3_corrections_v1.json pipeline/data/selection/irregular_verbs_batch_4_context_v1`: keine Ausgabe, Exit 0. Neue Markdown-/JSON-Dateien zusätzlich direkt auf nachgestellte Leerzeichen geprüft. Bekannte CRLF-/Whitespace-Altbefunde bleiben getrennt offen, keine globale Bereinigung.

Nächste Aktion: **81 neue Batch-4-Satzpaare anhand der geprüften ZIP im Chat redigieren**; 18 Wiederverwendungen erhalten. Die 20 früheren Glossenbefunde und die zwölf neuen Vergleichseinträge bleiben eine eigenständige Kurationsaufgabe.

Vollständiger ZIP-Pfad: `/Users/ardasayar/Documents/FlutterProjekte/sprachapp/build/irregular_verbs_authoring_batch_4.zip`.
