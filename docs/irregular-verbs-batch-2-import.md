# Unregelmäßige Verben – Batch 2: Import und interne Bereitstellung

Stand: 10.10.2026. **`irregular_verbs_batch_2_v1` intern gestagt und verifiziert.** Batch 2 ergänzt 83 feste Satzpaare und 22 unveränderte Wiederverwendungen. Insgesamt 204 Formübungen, 68 pro Ansicht. Der echte Repository-Import, vollständige 22-Tabellen-Abgleich, App-Leser, gezielte Tests und Analyse sind bestanden. Die erneut geprüfte Batch-3-ZIP fordert 84 neue Satzpaare an und weist 15 Wiederverwendungen getrennt aus.

## Basis, Sicherung und unveränderte Lieferung

Verwendet wurde die tatsächlich an Batch 1 gebundene Fortsetzung `pipeline/data/selection/irregular_verbs_batch_2_context_v1/selection.json`, mit `registry.json` und `learning_groups.json` desselben Verzeichnisses. Diese drei Dateien entsprechen den Snapshotinhalten von `build/irregular_verbs_authoring_batch_2.zip`. Die Ursprungsauswahl wurde nicht als aktuelle Kontextauswahl eingesetzt.

Vor Änderungen/Staging wurden Quell-JSON, Quell-SQLite, Produktionsasset und Asset-Manifest bytegenau nach `build/irregular_verbs_batch_2_backup/` gesichert, mit ursprünglichen relativen Pfaden. `hashes.json` und `baseline.json` protokollieren vier Produktions-/Quellhashes und 2605 vorbestehende Dateien einschließlich früherer Authoring-ZIPs. Die Sicherung wurde vor dem Staging und abschließend geprüft. Alte Packs und Snapshots wurden nicht überschrieben.

| Ausgangsdatei | SHA256 |
|---|---|
| Batch-1-Quell-JSON | `23e6731e358f7e9f59a4dfa0f304ac850ef4a7abf5786649a7ca384f1c5f2a46` |
| Batch-1-Quell-SQLite / damaliges Asset | `cb719374dbd760809ab261333d7a3fbbda1373c565dec64134ac2db219298c60` |
| damaliges Asset-Manifest | `707971486442f1a4b1513f332bdaeba39349adca86f80d1b516797d0e479494e` |
| Eingangs-Authoring-ZIP | `ae8cee83cb95e20cbecf23ab6e4f7f09424a5a07c55eae50ce65c25ac427d1f0` |
| Original-Batch-2-`editorial_content_v3.json` | `6299063f695d7d3209ec4623fcf1c42acd6db9996e3ef88de5034461b3bf65cb` |

Alle sieben im Liefermanifest genannten Dateien sind hashgeprüft und am Ende erneut bytegleich bestätigt. Basis, eingebettete Auswahl, kanonischer Auswahlhash `28d30de9e6d85974f6d9ca1f635d2928edfbd3defc922e56ee6838e1582c556b`, Registry- und Gruppenhash stimmen exakt mit dem lokalen/ZIP-Kontext überein. Keine Hashbindung wurde angepasst.

Die Originaldatei wurde direkt durch den vorhandenen V3-Create-Weg importiert. **Keine neue Importkorrektur war erforderlich; keine separate Korrekturkopie erzeugt.** Die Batch-1-Korrektur `see → besuchen`, der nullable-Definitionsfix des App-Lesers, alle alten IDs und die bisherigen Sätze/Tokens bleiben unverändert.

## Redaktion und genaue Wortbindungen

Alle 83 englischen Texte, deutschen Übersetzungen, Formfunktionen und 826 Tokenpositionen wurden gelesen. `token_review.json` enthält 738 Wort-/Genitivpositionen; diese stimmen genau mit den gelieferten Tokenbindungen überein. Die übrigen 88 Positionen sind Satzzeichen. Die HTML-Übersicht wurde gegen alle 83 Satzpaare abgeglichen. Der echte Importer prüfte danach vollständige Tokenisierung/Offsets, Zielbelege, Wörterbuch- und Reviewhashbindungen.

Die 105 aktuellen Formziele stammen exakt aus dem aktuellen Metadatendelta, 35 pro Ansicht. 83 neue Karten erhalten je einen festen Satz. Die 22 vorhandenen Karten wurden anhand ihrer tatsächlichen festen Sätze und der Karten-/Kontexthashes geprüft und unverändert wiederverwendet. Keine späteren Batchmetadaten wurden importiert; zusätzliche Begleitwortdaten besitzen weder Lernkarten noch Wortbesitzer.

Konkrete Abgrenzungen:

- `lay#legen`: Gegenstand/Person hinlegen; `lie#liegen`: selbst liegen. Grundform `lay` und Präteritum `lay` sind unterschiedliche Lemmas/Senses/Funktionen; `lie#lugen` bleibt getrennt.
- `nail#metallstift` in s046/s048 statt Fingernagel; `ring#boxring` in s010 statt Schmuckring; `glasses#sehbrille` in s056 statt Trinkglas.
- `report#schulzeugnis` in s055 statt allgemeinem Bericht; `sink#waschbecken` in s039 statt Küchenspüle.
- s068: `has → have#hilfsverb` vor dem Partizip `leant`; erstes `to#bezug` für den Abstand zum Bildschirm, zweites `to#infinitivpartikel` vor `read`.
- s024: `me → i#mir` passt zu „Maya hat mir verziehen“. `me` nach anderen Verben bleibt entsprechend „mich“ gebunden.
- Fehlende optionale Langdefinitionen im Bestand bleiben zulässig; die vorhandene Glossen-/Referenzprüfung wird weiter ausgeführt.

17 neue Begleitbedeutungen werden ausschließlich fürs Wörterbuch ergänzt. Insgesamt 21 neue Senses (vier ausgewählte Zielbedeutungen + 17 Begleitbedeutungen), 14 Lemmas und 62 Wörterbuchformzeilen. Keine künstlichen Senses zur Tempustrennung.

Neun Alternativen wurden wörtlich eingesetzt und in genau diesen Funktionen/Sätzen geprüft. `accepted` bleibt ausschließlich die Zielform; die Alternativen sind satzgebunden und lernstandsneutral:

```text
ALTERNATIVE irregular-v1-b2-s028 Mia has finally gotten a reply from the hotel.
ALTERNATIVE irregular-v1-b2-s056 Sara kneeled beside the bed to look for her glasses.
ALTERNATIVE irregular-v1-b2-s057 The gardener has kneeled on the wet ground for hours.
ALTERNATIVE irregular-v1-b2-s067 Ali leaned forward to hear the quiet reply.
ALTERNATIVE irregular-v1-b2-s068 Leo has leaned closer to the screen to read the small text.
ALTERNATIVE irregular-v1-b2-s070 Maya leaped across the stream without getting wet.
ALTERNATIVE irregular-v1-b2-s071 The horse has leaped over every fence on the course.
ALTERNATIVE irregular-v1-b2-s072 Ben learned to swim during the summer holidays.
ALTERNATIVE irregular-v1-b2-s073 Rosa has learned three new words today.
```

## Unverändert offene geerbte Glossen

`inherited_gloss_findings.json` ist eine Befundliste, keine Mutationsoperation. Alle 20 Schlüssel wurden vor und nach dem Import gegen den tatsächlichen Wörterbuchbestand geprüft; ihre alten Werte bleiben exakt erhalten. Die vollständigen Satzübersetzungen und Zieldefinitionen wurden getrennt davon beurteilt. Vorschläge der Lieferung sind nicht angewendet oder als abschließend kuratiert ausgegeben. Eine spätere Bereinigung benötigt eine eigene versionierte Operation und Prüfung sämtlicher betroffener Bestandskontexte.

| Oberfläche | Sense | Unverändert geerbte Glosse | Batch-2-Leselabel |
|---|---|---|---|
| fell | fall/VERB|fall#fallen | fiel; gefallen | s003 |
| felt | feel/VERB|feel#fuehlen | fühlte sich | s007, s008 |
| found | find/VERB|find#finden | gefunden | s011, s012 |
| got | get/VERB|get#bekommen | bekam | s027, s028 |
| heard | hear/VERB|hear#hoeren | hörten | s041, s042 |
| hid | hide/VERB|hide#verstecken | versteckte sich | s044 |
| hit | hit/VERB|hit#schlagen | schlug; schlugen | s046, s047, s048 |
| held | hold/VERB|hold#haelt | hielt | s049, s050 |
| hurt | hurt/VERB|hurt#verletzte | verletzte | s051, s052 |
| keep | keep/VERB|keep#aufbewahrt | aufbewahrt | s053 |
| kept | keep/VERB|keep#aufbewahrt | hielt bereit | s054, s055 |
| knelt | kneel/VERB|kneel#knien | kniete | s056, s057 |
| left | leave/VERB|leave#verlassen | verließ | s074, s075 |
| concert | concert/NOUN|concert#konzert | Konzert- | s031 |
| summer | summer/NOUN|summer#sommer | Sommer- | s036, s072 |
| home | home/NOUN|home#heim-zu-hause | Heim- / zu Hause | s013 |
| spread | spread/VERB|spread#breitet-aus | breiten aus | s014 |
| wall | wall/NOUN|wall#wand | Wand | s037, s049 |
| words | word/NOUN|word#wort | Wörter; Liedtext | s051, s073 |
| sleeping | sleep/VERB|sleep#schlafen | schlafen | s062 |

## Export, Besitz, Wörter und Übungen

Neuer Export: `pipeline/out/irregular_verbs_batch_2_v1/`. Alle alten JSON-Zeilen und SQL-Zeilen einschließlich IDs, Spaltenwerten, Besitz-/Praxispositionen, Definitionen/Glossen, Sätzen, Tokens, Links und Reviews sind unverändert. Die 22 aktuellen Wiederverwendungsbelege wurden auch gegen den fertigen Export erneut geprüft. Im gesamten importierten Formkatalog gibt es 38 Wiederverwendungen: 16 aus Batch 1 plus 22 aus Batch 2.

| Größe | Tatsächlicher Wert |
|---|---:|
| Karten insgesamt | 2402 = 2319 + 83 |
| Aktive feste Karten-Satzbindungen | 2402 |
| Historische Karten-Satzbindungen | 2930 |
| Satztexte insgesamt | 2936 = 2853 + 83 |
| Formziele / Praxismitgliedschaften insgesamt | 204 |
| Formübungen je Ansicht | 68 / 68 / 68 |
| Lexikalanker insgesamt | 68 |
| Lexikalanker in Batch 2 | 35: 20 bereits vorhandene, 15 neue Lernbedeutungen |
| Neue Oberflächenbesitzer in Batch 2 | 57 |
| Oberflächenbesitzer insgesamt | 2243 |
| Wortaliase | 37, unverändert |
| Gemischtes Übungsinventar | 2288 |
| Gemischte lexikalische Wörter | 2149 |

Die acht normalen Ansichten behalten **160 / 489 / 241 / 245 / 245 / 249 / 250 / 242 Übungen**. Zusätzliche Formkarten können denselben Besitzerstapel verwenden, werden dort durch `form_only` nicht als normale Übungen eingeführt. Besitzpositionen bleiben erhalten und werden für neue Oberflächen angehängt; Praxispositionen reichen je Formansicht lückenlos von 1 bis 68.

Die tatsächliche App-Projektion mit leeren synthetischen Zuständen und allen Inhaltsansichten liefert **2288 Übungen**, also 2204 + 83 neue Karten + **eine zusätzlich zugängliche Altkarte**: `had|have/VERB|have#besitzen_partizip`. Diese bestehende Karte war zuvor kein eigenständig angebotenes Besitzer-Primärziel; die Formansicht bindet jetzt genau dieselbe Identität und denselben Satz ein. Ihr Lernstand wird nicht neu angelegt oder geändert.

Die Wortzahl ergibt sich aus **2136 + 15 − 2 = 2149**. Bei Besitz-`have` werden drei bisher besitzgebunden gezählte Gruppen einem ausdrücklich belegten Konzept zugeordnet. Die zusätzliche vierte Altgruppe ist die eben genannte Partizipkarte; sie erzeugt durch denselben Lexikalanker kein neues Wort. IDs, Übungsgruppen und Zustände werden dabei nicht zusammengelegt. Die Rohmitgliedschaften aller Ansichten (2336) und die Stapelsummen sind keine globalen Wort-/Übungszahlen. Die Diagnose über das vorhandene Dart-Werkzeug und der Lesetest bestätigen die implementierte Projektion.

## Tatsächliche Prüfungen und Befehle

Ausgeführt auf macOS. Flutter-/Dart-Befehle sind unter Windows PowerShell identisch. Für Python verwendet Windows den aktivierten vorhandenen Projektinterpreter `python` statt `pipeline/.venv-macos/bin/python`. Temporäre macOS-Prüfhilfen/Logs liegen unter `/tmp/irregular-verbs-b2/`; Sicherung und die gelieferten Originalbefunde bleiben zusätzlich im Projekt. Keine Installation oder Modell-/Cloud-Generierung.

```text
pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --verify-zip build/irregular_verbs_authoring_batch_2.zip
zip_verification=PASS; sqlite_tables=22; source binding to Batch 1 PASS
Exit 0

pipeline/.venv-macos/bin/python /tmp/irregular-verbs-b2/check_delivery.py
BASE / DELIVERY / LOCAL / ZIP source, selection, registry, groups binding PASS
BINDING_HASHES {"groups": "40bae40bb6c6954fc804530ea510ae4219bdfed2ae1816a0f6ff252e12cba14e", "registry": "b573a7972056e775139916db874a53351e7009929c231d16e43db3883e7f9dbc", "selection": "28d30de9e6d85974f6d9ca1f635d2928edfbd3defc922e56ee6838e1582c556b"}
SELECTION {"current": 105, "future": 198, "imported": 99, "new_cards": 248, "new_form_targets": 303, "new_lexical_targets": 101, "new_surface_reservations": 0, "reused_cards": 71}
CURRENT exact metadata PASS: 105 form targets / 83 new cards / 22 unchanged reuse / 35 per view; no future delta
TOKEN_REVIEW 738 lexical positions and HTML 83 sentence pairs exact PASS; all 826 positions passed to importer
INHERITED_GLOSSES: 20 findings match source, no mutations applied
METADATA_PREFIX 2 PASS; forms 204 ; missing future sentences not approved
METADATA_PREFIX 3 PASS; forms 303 ; missing future sentences not approved
METADATA_PREFIX 4 PASS; forms 402 ; missing future sentences not approved
EDITORIAL RESULT: 83 sentence pairs and 826 positions reviewed; no new correction necessary; original delivery used unchanged
Exit 0
```

Die Metadatenpräfixe 2/3/4 wurden zusätzlich mit Form-, Gruppen- und Registryvalidatoren geprüft (204/303/402 Formziele). Fehlende zukünftige Sätze wurden dabei ausdrücklich nicht als geprüft behandelt.

```text
pipeline/.venv-macos/bin/python pipeline/scripts/import_editorial_patch.py --source pipeline/out/irregular_verbs_batch_1_v1/pack.json --create irregular_verbs_batch_2_lieferung/editorial_content_v3.json --registry pipeline/data/selection/irregular_verbs_batch_2_context_v1/registry.json --out pipeline/out/irregular_verbs_batch_2_v1
{
  "status": "ok",
  "internal_test_pack": true,
  "ai_calls": 0,
  "ai_cost_usd": 0,
  "sqlite_counts": {
    "languages": 1,
    "lemmas": 3511,
    "senses": 5010,
    "cards": 2402,
    "dictionary_forms": 5951,
    "decks": 11,
    "deck_cards": 2347,
    "deck_words": 2243,
    "word_aliases": 37,
    "sentences": 2936,
    "sentence_tokens": 32541,
    "card_sentences": 2930,
    "stories": 1,
    "story_sentences": 6,
    "exercises": 0,
    "grammar_rules": 0,
    "audio_assets": 0,
    "content_releases": 1,
    "lexical_targets": 68,
    "card_lexical_targets": 207,
    "form_targets": 204,
    "deck_practice_targets": 204
  },
  "sha256": "ca9256a877172cb3390e54ff8d4208fff084764239d6df7b1fcc28a80fa98758"
}
Exit 0

pipeline/.venv-macos/bin/python /tmp/irregular-verbs-b2/verify_pack.py
PRESERVATION: every old JSON row and SQL ID/value unchanged PASS; 2319 old cards, fixed sentences, tokens, positions, dictionary and Batch-1 see/besuchen correction preserved
SQLITE_ALL_ROWS {"audio_assets": 0, "card_lexical_targets": 207, "card_sentences": 2930, "cards": 2402, "content_releases": 1, "deck_cards": 2347, "deck_practice_targets": 204, "deck_words": 2243, "decks": 11, "dictionary_forms": 5951, "exercises": 0, "form_targets": 204, "grammar_rules": 0, "languages": 1, "lemmas": 3511, "lexical_targets": 68, "senses": 5010, "sentence_tokens": 32541, "sentences": 2936, "stories": 1, "story_sentences": 6, "word_aliases": 37}
LINTER 2930 link inventory; 0 errors; 450 warnings
NEW LINT FINDINGS [{'card': 'irregular:hurt:past', 'level': 'warn', 'rule': 'i+1', 'message': "'unkind'/'unkind' Zipf 2.99 below 3.5"}, {'card': 'irregular:kneel:past_participle', 'level': 'warn', 'rule': 'i+1', 'message': "'gardener'/'gardener' Zipf 3.49 below 3.5"}]
PRACTICE irregular_verbs_base 68 positions 1..68 PASS
PRACTICE irregular_verbs_past 68 positions 1..68 PASS
PRACTICE irregular_verbs_participle 68 positions 1..68 PASS
OWNERS: old positions unchanged; +57 new surfaces; 2243 total; no new aliases
REUSE: all 22 Batch-2 contexts/evidence unchanged after import PASS; 38 reused form cards in imported catalogue
INHERITED 20 GLOSSES unchanged, remain open PASS
BACKUP and original Batch-1 pack hashes preserved PASS
Exit 0
```

Alle 22 SQLite-Tabellen, Spalten und Nutzwerte wurden mit `build_rows` vollständig abgeglichen, nicht nur gezählt. Der vollständige Satzlinter lief im vorhandenen Export: null Fehler, 450 Warnhinweise insgesamt. Genau zwei neue Hinweise: `unkind` in s051, Zipf 2,99; `gardener` in s057, Zipf 3,49. Die bekannten Frequenzhinweise lösten keine Umformulierung aus.

```text
pipeline/.venv-macos/bin/python -m pytest pipeline/tests/test_form_targets.py pipeline/tests/test_form_authoring_details.py pipeline/tests/test_word_registry.py pipeline/tests/test_authoring_context.py pipeline/tests/test_authoring_continuation.py pipeline/tests/test_editorial_import.py -q
........................................................................ [ 75%]
........................                                                 [100%]
96 passed in 17.43s
Exit 0

flutter test --no-pub test/data/form_content_test.dart test/data/form_learning_test.dart test/domain/form_projection_test.dart test/form_learning_flow_test.dart test/form_counts_widget_test.dart
00:07 +27: All tests passed!
Exit 0

dart run tool/report_learning_groups.dart pipeline/out/irregular_verbs_batch_2_v1/content.sqlite
mixed: raw_words=2336; learning_targets=2288; lexical_words=2149; form_memberships=204
Exit 0

dart run tool/stage_content_pack.dart --from pipeline/out/irregular_verbs_batch_2_v1
staged assets/content/en/content.sqlite
  version irregular_verbs_batch_2_v1, schema 4, 16023552 bytes
  sha256 ca9256a877172cb3390e54ff8d4208fff084764239d6df7b1fcc28a80fa98758
  22 table counts match finalization_report.json
  INTERNES TEST-PACK: own devices and selected testers only, no public content release
Exit 0

dart run tool/stage_content_pack.dart --verify
verified assets/content/en/content.sqlite
  version irregular_verbs_batch_2_v1, schema 4, 16023552 bytes
  sha256 ca9256a877172cb3390e54ff8d4208fff084764239d6df7b1fcc28a80fa98758
  22 table counts match finalization_report.json
  INTERNES TEST-PACK: own devices and selected testers only, no public content release
Exit 0

flutter test --no-pub test/data/real_pack_test.dart
00:00 +0: loading /Users/ardasayar/Documents/FlutterProjekte/sprachapp/test/data/real_pack_test.dart
00:00 +0: staged pack: all cards and sentence links readable, read-only
SCHEMA4 mixed exercises=2288 lexical=2149; 204 forms / 38 reuse / cut 3 identities PASS
deck allgemeine-sprache: 160 learning targets, 173 ownership cards, 173 fixed sentence assignments verified
deck reisen: 489 learning targets, 508 ownership cards, 508 fixed sentence assignments verified
deck alltag-zuhause: 241 learning targets, 249 ownership cards, 249 fixed sentence assignments verified
deck arbeit-bildung: 245 learning targets, 246 ownership cards, 246 fixed sentence assignments verified
deck menschen-beziehungen: 245 learning targets, 250 ownership cards, 250 fixed sentence assignments verified
deck koerper-gesundheit: 249 learning targets, 258 ownership cards, 258 fixed sentence assignments verified
deck essen-trinken: 250 learning targets, 250 ownership cards, 250 fixed sentence assignments verified
deck natur-umwelt: 242 learning targets, 244 ownership cards, 244 fixed sentence assignments verified
deck irregular_verbs_base: 68 learning targets, 65 ownership cards, 65 fixed sentence assignments verified
deck irregular_verbs_past: 68 learning targets, 0 ownership cards, 0 fixed sentence assignments verified
deck irregular_verbs_participle: 68 learning targets, 0 ownership cards, 0 fixed sentence assignments verified
pack irregular_verbs_batch_2_v1 (schema 4, internal: true); 11 decks: 2243 cards, 2402 card sentences, 151 with valid_alternatives, 2402 cards in the pack
00:58 +1: All tests passed!
Exit 0

flutter analyze --no-pub
Analyzing sprachapp...
No issues found! (ran in 2.8s)
Exit 0
```

Der vorhandene Elf-Stapel-Lesetest wurde um Batch-2-Erwartungen erweitert. Er prüft acht unveränderte normale Ansichten, 68/68/68 Formübungen, 38 Wiederverwendungen insgesamt, getrennte `cut/cut/cut`- und `hit/hit/hit`-Identitäten sowie `lay` als Grundform von legen gegenüber `lay` als Vergangenheit von liegen. Alle Formkarten haben genau einen festen Satz. Es wurden keine App-, SRS- oder Synonymlogik und keine Produktverträge geändert.

Ein erster Analyse-Lauf meldete eine unnötige Nullassertion bei `card.lemma` im neuen Test (Exit 1). Sie wurde entfernt; der Abschlusslauf ist ohne Befund. Die bestehenden Formtests geben eine Drift-Debugwarnung zu mehreren Testdatenbanken aus und bestanden vollständig. Keine vollständige Flutter-Suite und kein Geräte-/Simulatortest ausgeführt; keine öffentliche Inhaltsfreigabe behauptet. Echte `user.db` und Lernstände wurden nicht geöffnet. `lib/main.dart` und der Batch-1-Leserfix sind bytegleich.

## Batch-3-Fortsetzung und ZIP

```text
pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --selection pipeline/data/selection/irregular_verbs_batch_2_context_v1/selection.json --prepare-continuation irregular_verbs_batch_3_context_v1 --batch 3 --source-pack pipeline/out/irregular_verbs_batch_2_v1/pack.json --source-sqlite pipeline/out/irregular_verbs_batch_2_v1/content.sqlite --out pipeline/data/selection/irregular_verbs_batch_3_context_v1
{
  "snapshots": "PASS",
  "selection": "pipeline/data/selection/irregular_verbs_batch_3_context_v1/selection.json",
  "registry": "pipeline/data/selection/irregular_verbs_batch_3_context_v1/registry.json",
  "partition_counts": {
    "imported": 204,
    "current": 99,
    "future": 99
  }
}
Exit 0

pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --selection pipeline/data/selection/irregular_verbs_batch_3_context_v1/selection.json --batch 3 --out build/irregular_verbs_authoring_batch_3.zip
Exit 0
pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --verify-zip build/irregular_verbs_authoring_batch_3.zip
Exit 0
```

Neue, nicht überschriebene Snapshots im Verzeichnis `pipeline/data/selection/irregular_verbs_batch_3_context_v1/`: `selection.json`, `registry.json`, `learning_groups.json`. Die vorhandene Continuation-Funktion bindet die tatsächlichen Exportpfade/-hashes. Zusammenfassung der echten Verifier-Ausgabe (Referenzlisten als Partitionslängen dargestellt):

```json
{
  "zip_verification": "PASS",
  "zip_sha256": "5802ffb0118fad3963016766e06f5e22d55a3c6d8cf40a1f6a359c98da67bd3b",
  "content_schema_version": 4,
  "sqlite_tables": 22,
  "counts": {
    "imported": 204,
    "current": 99,
    "future": 99,
    "reused_cards": 71,
    "new_form_targets": 198,
    "new_lexical_targets": 66,
    "new_surface_reservations": 0,
    "new_cards": 165
  },
  "partition_counts": {
    "imported": 204,
    "current": 99,
    "future": 99
  }
}
```

Die ZIP wurde geschlossen, erneut geöffnet und vollständig geprüft: CRCs, 77 manifestierte Dateihashes, Basisbindung, Referenzen, Wiederverwendungsbelege, Metadatenpräfixe, Partition und alle Zeilen aller 22 Quelltabellen. JSON-/SQLite-Basis und Auswahl-/Registry-/Gruppensnapshots entsprechen zusätzlich bytegenau den tatsächlichen lokalen Dateien.

`current_authoring_tasks.json` enthält **84 neue Satzaufträge und 15 unveränderte Wiederverwendungen**. Partition **204 importiert / 99 aktuell / 99 später**. Der Gesamtwert 71 Wiederverwendungen bleibt katalogweit; `new_surface_reservations: 0` bedeutet keine erneute Reservierung gegenüber dem bereits gebundenen vollständigen Oberflächenkatalog. Keine Batch-3-Sätze erstellt.

| Abschlusshash | SHA256 |
|---|---|
| Export-JSON | `78368d24b9a585b5d2f9cf5b1e336b2f459f3c38410fa76e02f9fe3c99ff0197` |
| Export-SQLite / gestagtes Asset | `ca9256a877172cb3390e54ff8d4208fff084764239d6df7b1fcc28a80fa98758` |
| neues Asset-Manifest | `2ebc89100b3129c26fe9f25099cae6bcfbacea9324cb8e269bdb0d9be656232d` |
| Batch-3-ZIP | `5802ffb0118fad3963016766e06f5e22d55a3c6d8cf40a1f6a359c98da67bd3b` |

## Dateiabgleich und offener Schritt

Vor dem Schreiben dieses Berichts ergab der Hashaudit über 2605 vorbestehende Dateien ausschließlich eine Änderung an `test/data/real_pack_test.dart`. Abschließend kommt `NEXTSTEPS.md` hinzu. Neue Auftragsdateien sind dieser Bericht, der neue Export, Sicherung, Fortsetzung und ZIP. Original-Lieferungen, Batch-1-Korrektur, Leserfix, bisherige Auswahlen/Registrys, historische Packs und Authoring-ZIPs bleiben unverändert. Asset und Manifest wurden ausschließlich durch das bestehende Staging-Werkzeug aktualisiert.

Eigene Diffprüfung: `git -c core.whitespace=cr-at-eol diff --check -- NEXTSTEPS.md docs/irregular-verbs-batch-2-import.md test/data/real_pack_test.dart pipeline/data/selection/irregular_verbs_batch_3_context_v1`: keine Ausgabe, Exit 0. Neue Markdown-/JSON-Dateien sind zusätzlich direkt auf nachgestellte Leerzeichen geprüft. Die dokumentierten CRLF-/Whitespace-Altbefunde bleiben offen; keine pauschale Bereinigung oder erneut erzeugte riesige Gesamtausgabe.

Nächste Aktion: **84 neue Batch-3-Satzpaare anhand der geprüften ZIP im Chat redigieren**; 15 Wiederverwendungen erhalten. Die 20 geerbten Wörterbuchbefunde bleiben eine eigenständige offene Kurationsaufgabe. Kein Modell-/Cloud-Aufruf, keine Remote-Migration, Paketinstallation, Commit oder Push.

Vollständiger ZIP-Pfad: `/Users/ardasayar/Documents/FlutterProjekte/sprachapp/build/irregular_verbs_authoring_batch_3.zip`.
