# Unregelmäßige Verben – Batch 4 und Gesamtabschluss

Stand: 10.10.2026. **Alle drei Verbenstapel sind technisch intern abgeschlossen.** `irregular_verbs_batch_4_v1` wurde exportiert, nach bestätigter Sicherung intern gestagt und verifiziert. Je 134 Übungen in Grundform, Präteritum und Partizip Perfekt; zusammen 134 lexikalische Verbidentitäten und 402/402 exakte Formziele. Über vier Batches 331 neue feste Satzpaare und 71 unveränderte Wiederverwendungen. Gemeinsame App-Projektion: **2453 Übungen / 2182 Wörter**. Kein Restziel, Batch 5 oder weitere Verben-Authoring-ZIP. Technische Abnahme ist keine unabhängige menschliche Sprach-/Inhaltsfreigabe.

## Eingaben, Sicherung und Dateiliste

Die Lieferung lag bereits entpackt unter `irregular_verbs_batch_4_lieferung/`. Gelesen/geprüft: `editorial_content_v3.json`, `README.txt`, `token_review.json`, `inherited_gloss_comparison.json`, `validation_report.json`, `satzuebersicht.html`, `manifest.json`. Alle sieben manifestierten Dateien wurden vor und nach dem Import SHA256-geprüft und sind unverändert. Der Chat-Prüfbericht wurde nicht als Repositorylauf ausgegeben.

Basis: `pipeline/out/irregular_verbs_batch_3_v1/{pack.json,content.sqlite}`, Schema 4. Kontext: `build/irregular_verbs_authoring_batch_4.zip`; ausdrücklich gebundene tatsächliche Auswahl-/Registry-/Gruppendateien: `pipeline/data/selection/irregular_verbs_batch_4_context_v1/{selection,registry,learning_groups}.json`. Quellbytes, Auswahl samt kanonischem Hash, Registry und Gruppen stimmen exakt mit lokalem/ZIP-Kontext überein. Keine Basis umgeschrieben.

**Vor dem Staging** wurden Quell-JSON, Quell-SQLite, aktuelles Asset und Asset-Manifest bytegenau nach `build/irregular_verbs_batch_4_backup/` unter Erhalt der relativen Pfade gesichert. `hashes.json` protokolliert vier Produktions-/Quellhashes; `baseline.json` erfasst 2633 vorbestehende Dateien inklusive historischer Authoring-ZIPs. Sicherung, alter Quellpack und Original-Lieferungen wurden abschließend erneut hashgeprüft.

| Ausgangsdatei | SHA256 |
|---|---|
| Batch-3-Quell-JSON | `89fffbe42331ef1283f9a3dec0ddc0ef1bbd6001846bd3636962e38db953edfe` |
| Batch-3-Quell-SQLite / vorheriges Asset | `f0adf97135225d240078cd92209a9af93597932f82c3c4dab1340e015628ddeb` |
| vorheriges Asset-Manifest | `0a19ce65d0e915ece9159750ab887b7ce864a8e1a98a25864792329cf60d35a0` |
| Original-Batch-4-Importdatei | `f9d351a93a92785f5576038626254b9f9941aa0aa6375f4950adc325f592b007` |
| Eingangs-Authoring-ZIP | `baf5148a83a4c05850561be73a55a7017b9d6773cacc0dc90a8198ee742aea55` |

Neue Ausgaben: `pipeline/out/irregular_verbs_batch_4_v1/{pack.json,content.sqlite,finalization_report.json}`, Sicherung, `build/irregular_verbs_completion_checks/{audit,hashes}.json`, dieser Bericht. Aktualisiert: Asset/Manifest durch das Staging-Werkzeug, `test/data/real_pack_test.dart`, `docs/irregular-verbs-authoring.md`, `docs/content-roadmap-v1.md`, `NEXTSTEPS.md`. Keine neue Importkorrektur oder Folgeauswahl/Registry angelegt.

## Vollständige Liefer- und Sprachprüfung

Alle **81 neuen Satzpaare und 820 Tokenpositionen** wurden mit Zieldefinition, Formfunktion, deutscher Übersetzung und konkreter Wortbindung gegengelesen. `token_review.json` enthält 736 Wortpositionen; sie stimmen mit den Originaltokens überein. Die übrigen 84 Positionen sind Satzzeichen. Die HTML-Übersicht entspricht allen 81 englischen/deutschen Paaren. Die vorhandenen Repository-Validatoren prüfen anschließend Tokenisierung, vollständige Offsets/Abdeckung, Sense-/Wörterbuchbindungen, Zielbelege und Review-/Linkhashes.

Die aktuellen Metadaten sind exakt das gebundene Delta: 99 Formziele, 81 neue Karten, 18 Wiederverwendungen und **100 Karten-Lexikalzuordnungen**. Die zusätzliche Zuordnung ist die bestehende `get|get/VERB|get#verstehen`-Karte zu `irregular:understand`; sie erhält die vollständige bereits entschiedene Gruppen-/Sense-Abdeckung. Sie ist keine hundertste Formübung, keine zusätzliche Karte und kein neuer Wortbesitzer. Die Zuordnung wurde weder gekürzt noch durch einen künstlichen Sense ersetzt.

Die 18 vorhandenen Übungen sind anhand tatsächlicher fester Sätze sowie Karten-/Kontexthashes geprüft und unverändert wiederverwendet. Ihre IDs und SRS-Identitäten bleiben erhalten. 16 zusätzliche Begleitwortsenses dienen ausschließlich dem Wörterbuch. Insgesamt 22 neue Senses (sechs ausgewählte Zielbedeutungen + 16 Begleitbedeutungen), 18 Lemmas, 70 Wörterbuchformzeilen. Daraus entstehen keine zusätzlichen Lernkarten/Besitzer.

Konkrete Bedeutungsprüfung:

- `spend#zeit_verbringen`: Zeit, kein Geldverbrauch; `withdraw#geld_abheben`: Geld abheben; `account#bankkonto` gegenüber digitalem Benutzerkonto.
- `wake#wecken`: jemanden wecken; `stick#anhaften`: an einer Fläche haften; `spin` und `swing`: intransitive Bewegung.
- `spread`: Butter aufstreichen, wie im erhaltenen Grundformsatz. `split`/`spread`-Funktionen sind durch Infinitiv, vergangene Erzählung bzw. Perfect-Kontext getrennt.
- `since September` als Präposition mit vorhandener Zeitpunkts-Sense; `to` in `from side to side` als Richtung, keine Infinitivpartikel; `three times` als dreimal.
- `to#haftflaeche`, `over#kommunikationsmittel`, Holzmaserung, Holzscheit und Bankkonto sind bedeutungsbezogen geprüft. Vorhandene geeignete Senses werden wiederverwendet.

**Keine Lieferkorrektur war erforderlich.** Die Original-Importdatei wurde direkt verwendet, kein Korrekturbeleg erfunden. Frühere Besuchsbindung aus Batch 1 und die drei Richtungsbindungen aus Batch 3 sind im Abschlussbestand exakt erhalten.

Neun Alternativen wurden wörtlich eingesetzt und im vollständigen Satz geprüft. `accepted` bleibt nur die Zielform; Alternativen sind ausschließlich für die jeweilige Satzlücke neutral:

```text
ALTERNATIVE irregular-v1-b4-s004 Omar smelled fresh bread as he walked past the bakery.
ALTERNATIVE irregular-v1-b4-s005 I have smelled smoke in the hallway twice today.
ALTERNATIVE irregular-v1-b4-s007 We have sowed grass seeds in the bare patch by the gate.
ALTERNATIVE irregular-v1-b4-s010 Lina spelled her surname slowly over the phone yesterday.
ALTERNATIVE irregular-v1-b4-s011 I have spelled my name aloud, but the receptionist still looks confused.
ALTERNATIVE irregular-v1-b4-s015 Emma spilled her tea on the newspaper this morning.
ALTERNATIVE irregular-v1-b4-s016 Someone has spilled milk on the kitchen floor.
ALTERNATIVE irregular-v1-b4-s026 The loud music spoiled our quiet evening in the garden.
ALTERNATIVE irregular-v1-b4-s027 The heavy rain has spoiled our picnic.
```

## Geerbte Glossen und Vergleichseinträge bleiben offen

Die **20 geerbten Batch-2-Befunde** und **12 Batch-3-Vergleichseinträge** bleiben unverändert separat dokumentiert. Die neue Liste enthält **14 Einträge**, ebenfalls keine Mutationsoperation. Alle alten Schlüssel/Glossen wurden gegen Quelle und Export unverändert nachgewiesen. Ein Wortlautunterschied ist kein automatisches Fehlerurteil; Satzübersetzung und Tooltip-Glosse wurden getrennt beurteilt.

| Oberfläche | Geerbte Glosse | Konkrete Einordnung für Batch 4 |
|---|---|---|
| slid | schob | Präteritum s002 passt; Partizipabdeckung s003 prüfen. |
| spoke | sprach; sprachen | sprach/sprachen enthält die passende Singularform; Kürzung auf sprach ist kein belegter Fehler. |
| spent | verbrachten | verbrachten passt nicht zum Singular Ali in s013; Partizip s014 nicht abgedeckt. |
| spread | breiten aus | Für Butteraufstreichen s028/s029 ist die Formglosse unpassend/unvollständig; Zieldefinition und Satzübersetzung stimmen. |
| stood | stand | Präteritum s030 passt; Partizipabdeckung s031 prüfen. |
| swept | fegte | Präteritum s046 passt; Partizipabdeckung s047 prüfen. |
| taught | brachte bei | brachte bei/unterrichtete ist bedeutungsnah; Partizip-/Fachunterrichtsanzeige prüfen. |
| tore | zerriss; zupfte auseinander | zerriss ist bereits vorhanden; Entfernung einer weiteren Formulierung kein automatischer Fehler. |
| told | sagte | Präteritum ist bedeutungsnah; Partizipabdeckung s062 prüfen. |
| freely | ungezwungen | Definition ohne Hemmung oder Einschränkung passt; die Anzeigeglosse ist stilistisch zu prüfen, kein automatischer Sense-Fehler. |
| opening | Öffnungs- (in opening times) | Eröffnungsereignis passt zum vorhandenen Bedeutungsumfang; Kompositumshinweis als eigenständige Anzeige unvollständig. |
| history | Geschichts- | Geschichts- ist als eigenständige Anzeige des Unterrichtsfachs unvollständig. |
| english | Englisch- | Englisch- ist als eigenständige Sprachanzeige unvollständig. |
| concert | Konzert- | Konzert- ist als eigenständige Anzeige unvollständig; bereits früher gesondert vermerkt. |

Keine dieser gemeinsam genutzten Bestandsglossen wurde geändert oder durch neue Tempus-Senses umgangen. Die Listen überschneiden sich teilweise; **20 + 12 + 14 ist keine Zahl disjunkter neuer Fehler**. Eine Bereinigung bleibt eine eigene versionierte Kurationsaufgabe über alle betroffenen Kontexte. Technische interne Abnahme beseitigt diese offenen redaktionellen Anzeigenbefunde nicht und behauptet keine unabhängige menschliche Sprachfreigabe.

## Nachweis gegen die ursprüngliche gemeinsame Auswahl

`pipeline/data/selection/irregular_verbs_v1.json` blieb unverändert. Der vollständige Bestandsabgleich prüft ihre originalen `entries`, `batches`, `editorial_catalog` und jede Formzielzeile exakt gegen die aktuelle Kontextauswahl und den fertigen Pack. Jede der 134 lexikalischen Verbidentitäten besitzt genau drei Formziele mit verschiedenen Karten und den Funktionen base/past/past_participle. Jede Formkarte hat genau einen aktiven festen Satz; neue Formkarten zusätzlich die genaue Funktionsreferenz im Zieltoken. Identische Oberflächen werden nicht zusammengelegt.

| Batch | Formziele | Neue feste Satzpaare | Unveränderte Wiederverwendungen |
|---|---:|---:|---:|
| 1 | 99 | 83 | 16 |
| 2 | 105 | 83 | 22 |
| 3 | 99 | 84 | 15 |
| 4 | 99 | 81 | 18 |
| Gesamt | 402 | 331 | 71 |

Alle 71 Wiederverwendungsbelege sind im endgültigen Pack erneut hashvalidiert. Jede neue der 331 Formkarten ist mit korrekter Funktion und exakt einem Satz verknüpft. Alle 402 ursprünglichen Referenzen vorhanden, keine zusätzliche Formidentität und keine offene Referenz. Tatsächlicher Abschluss: **402 importiert / 0 fehlend / 0 später**. Dieser Bestandsnachweis erzeugt keine Batch-5-Auswahl und verändert keine historischen Authoring-Partitionen.

Wortbesitz, Aliase, Gruppen-Köpfe und vollständige lexikalische Gruppen-/Sense-Zuordnungen sind durch bestehende Validatoren geprüft. Alle bisherigen JSON-Zeilen und SQL-IDs/Spaltenwerte einschließlich Satztexte, Tokens, historischer Links, Besitzpositionen und früherer Korrekturen bleiben erhalten. Neue Formkarten bleiben eigene Singleton-Übungsgruppen. 406 Karten-Lexikalzuordnungen umfassen die 402 Formkarten plus vier erforderliche zusätzliche Altkarten; keine zusätzliche Wortzählung.

| Abschlussgröße | Tatsächlicher Wert |
|---|---:|
| Karten / aktive feste Satzbindungen | 2567 |
| Historische Satzbindungen | 3095 |
| Satztexte | 3101 |
| Formziele und Praxismitgliedschaften | 402 |
| Übungen je Formansicht | 134 / 134 / 134 |
| Lexikalische Verbidentitäten | 134 |
| Karten-Lexikalzuordnungen | 406 |
| Oberflächenbesitzer | 2356, davon 57 neu in Batch 4 |
| Wortaliase | 37, unverändert |
| Gemeinsames Übungsinventar | 2453 |
| Gemeinsame lexikalische Wörter | 2182 |

Die acht normalen Stapel behalten **160 / 489 / 241 / 245 / 245 / 249 / 250 / 242 Übungen**. Besitzer- und Praxispositionen bleiben getrennt; jede Formansicht hat Positionen 1..134. Der globale Vorrat wurde über den echten App-Leser mit leeren synthetischen Zuständen und allen Inhaltsansichten gelesen: **2453 Übungen / 2182 Wörter**, nicht aus Stapelsummen geschätzt. Gegen Batch 3 diesmal +81 Übungen und +15 Wörter; die 18 Wiederverwendungen waren bereits im berechtigten Vorrat. Die früher neu zugängliche alte had-Partizipkarte bleibt erhalten.

134 technische Lexikalanker bedeuten 67 bereits vorhandene und 67 neue Lernbedeutungen. Die endgültige Wortprojektion bestätigt **2121 − 6 Umklassifizierung + 67 = 2182**. Die Übungsprojektion bleibt unabhängig; eine neue Formfunktion erhöht nicht automatisch die Wortzahl. Die Rohansichtsmenge 2534 ist wegen Lerngruppen und Mehrfachansichten kein globaler Zähler.

## Tatsächliche Befehle und Prüfoutputs

Ausgeführt auf macOS. Flutter-/Dart-Befehle sind unter Windows PowerShell identisch. Für Python unter Windows den vorhandenen aktivierten Projektinterpreter `python` statt `pipeline/.venv-macos/bin/python` einsetzen. Lokale macOS-Arbeitslogs/Prüfhilfen: `/tmp/irregular-verbs-b4/`. Dauerhafter Gesamtbeleg: `build/irregular_verbs_completion_checks/audit.json`, Hashbeleg daneben `hashes.json`. Keine Paketinstallation, Modell-/Cloud-Aufrufe, Remote-Migrationen, Commits oder Pushes.

```text
pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --verify-zip build/irregular_verbs_authoring_batch_4.zip
zip_verification=PASS; sqlite_tables=22; exact source binding PASS
Exit 0

pipeline/.venv-macos/bin/python /tmp/irregular-verbs-b4/check_delivery.py
BASE / DELIVERY / LOCAL / ZIP source, selection, registry, groups binding PASS
BINDING_HASHES {"groups": "8eb024fdc554c1da4cba69c65b3d8fb8f0c6f805c8eb06ae60ddadf7ee94e006", "registry": "2f8a18cce84d782026ebf3787204b6c4bd70726038ed137eefe70863bba5b164", "selection": "55738c219196c03342d6f8e5688f1132a5d0ed58a5234bfbad19bd982de02e6b"}
SELECTION {"current": 99, "future": 0, "imported": 303, "new_cards": 81, "new_form_targets": 99, "new_lexical_targets": 33, "new_surface_reservations": 0, "reused_cards": 71}
EXTRA_LEXICAL_MAPPING {"card": "get|get/VERB|get#verstehen", "lexical_target": "irregular:understand", "note": "Den Sinn einer Äußerung erfassen. Gleiche belegte Bedeutung; Formfunktionen sind eigene Übungen."}
CURRENT exact metadata PASS: 99 forms / 81 new cards / 18 reuse / 100 card_lexical mappings / 33 additions per view
TOKEN_REVIEW 736 word positions and HTML 81 sentence pairs match; all 820 positions reviewed PASS
INHERITED irregular_verbs_batch_2_lieferung/inherited_gloss_findings.json 20 source keys match; no mutations or automatic error verdict
INHERITED irregular_verbs_batch_3_lieferung/inherited_gloss_comparison.json 12 source keys match; no mutations or automatic error verdict
INHERITED irregular_verbs_batch_4_lieferung/inherited_gloss_comparison.json 14 source keys match; no mutations or automatic error verdict
FINAL METADATA PREFIX PASS: 402 forms, 134 lexical identities; actual missing current sentences still require importer
EDITORIAL RESULT: no correction necessary; original Batch-4 delivery used unchanged
Exit 0

pipeline/.venv-macos/bin/python pipeline/scripts/import_editorial_patch.py --source pipeline/out/irregular_verbs_batch_3_v1/pack.json --create irregular_verbs_batch_4_lieferung/editorial_content_v3.json --registry pipeline/data/selection/irregular_verbs_batch_4_context_v1/registry.json --out pipeline/out/irregular_verbs_batch_4_v1
{
  "status": "ok",
  "internal_test_pack": true,
  "ai_calls": 0,
  "ai_cost_usd": 0,
  "sqlite_counts": {
    "languages": 1,
    "lemmas": 3559,
    "senses": 5068,
    "cards": 2567,
    "dictionary_forms": 6098,
    "decks": 11,
    "deck_cards": 2460,
    "deck_words": 2356,
    "word_aliases": 37,
    "sentences": 3101,
    "sentence_tokens": 34218,
    "card_sentences": 3095,
    "stories": 1,
    "story_sentences": 6,
    "exercises": 0,
    "grammar_rules": 0,
    "audio_assets": 0,
    "content_releases": 1,
    "lexical_targets": 134,
    "card_lexical_targets": 406,
    "form_targets": 402,
    "deck_practice_targets": 402
  },
  "sha256": "e99074c535015c7875a5c8ac5e4c68e318ab4d569825db488e01dd4947bdcde3"
}
Exit 0

pipeline/.venv-macos/bin/python /tmp/irregular-verbs-b4/verify_completion.py
PRESERVATION: all old JSON rows and SQL IDs/values unchanged PASS; 2486 old cards, sentences, tokens, links, groups, ownership and Batch-1/3 corrections preserved
SQLITE_ALL_ROWS {"audio_assets": 0, "card_lexical_targets": 406, "card_sentences": 3095, "cards": 2567, "content_releases": 1, "deck_cards": 2460, "deck_practice_targets": 402, "deck_words": 2356, "decks": 11, "dictionary_forms": 6098, "exercises": 0, "form_targets": 402, "grammar_rules": 0, "languages": 1, "lemmas": 3559, "lexical_targets": 134, "senses": 5068, "sentence_tokens": 34218, "sentences": 3101, "stories": 1, "story_sentences": 6, "word_aliases": 37}
VIEW irregular_verbs_base 134 positions/functions/fixed contexts PASS
VIEW irregular_verbs_past 134 positions/functions/fixed contexts PASS
VIEW irregular_verbs_participle 134 positions/functions/fixed contexts PASS
BATCH 1 form goals 99 new pairs 83 reuse 16
BATCH 2 form goals 105 new pairs 83 reuse 22
BATCH 3 form goals 99 new pairs 84 reuse 15
BATCH 4 form goals 99 new pairs 81 reuse 18
COMPLETE ORIGINAL CATALOGUE: 134 lexical identities / 402 exact form refs / 331 new fixed sentence pairs / 71 hash-bound reused contexts PASS
ACTUAL COVERAGE: 402 imported / 0 missing / 0 future; no Batch 5 or new authoring selection needed
CARD_LEXICAL: 406 total; Batch-4 delta 100 retained, including get#verstehen mapping to understand
LINTER 3095 link inventory; 0 errors; 462 warnings
NEW LINT FINDINGS [{"card": "irregular:spell:past_participle", "level": "warn", "rule": "i+1", "message": "'receptionist'/'receptionist' Zipf 3.26 below 3.5"}, {"card": "irregular:spit:past_participle", "level": "warn", "rule": "i+1", "message": "'toothpaste'/'toothpaste' Zipf 3.37 below 3.5"}, {"card": "irregular:sting:past", "level": "warn", "rule": "i+1", "message": "'wasp'/'wasp' Zipf 3.35 below 3.5"}, {"card": "irregular:take:base", "level": "warn", "rule": "i+1", "message": "'biscuit'/'biscuit' Zipf 3.45 below 3.5"}, {"card": "irregular:take:past_participle", "level": "warn", "rule": "i+1", "message": "'biscuit'/'biscuit' Zipf 3.45 below 3.5"}, {"card": "irregular:tell:past_participle", "level": "warn", "rule": "i+1", "message": "'receptionist'/'receptionist' Zipf 3.26 below 3.5"}, {"card": "irregular:wake:past_participle", "level": "warn", "rule": "i+1", "message": "'doorbell'/'doorbell' Zipf 3.05 below 3.5"}]
INHERITED 20 entries from irregular_verbs_batch_2_lieferung/inherited_gloss_findings.json unchanged PASS
INHERITED 12 entries from irregular_verbs_batch_3_lieferung/inherited_gloss_comparison.json unchanged PASS
INHERITED 14 entries from irregular_verbs_batch_4_lieferung/inherited_gloss_comparison.json unchanged PASS
ALL documented Batch-1 and Batch-3 corrections preserved PASS
BACKUP and original Batch-3 source hashes preserved PASS
Exit 0
```

Alle 22 exportierten SQLite-Tabellen, ihre Spalten und alle Nutzwerte wurden vollständig mit `build_rows` abgeglichen. Regulärer Satzlinter: null Fehler, 462 Warnhinweise im Gesamtbestand. Genau sieben neue Frequenzhinweise an fünf Wörtern: receptionist s011/s062 (3,26), toothpaste s021 (3,37), wasp s038 (3,35), biscuit s053/s055 (3,45), doorbell s071 (3,05). Keine Umformulierung zur Warnungsbeseitigung.

```text
pipeline/.venv-macos/bin/python -m pytest pipeline/tests/test_form_targets.py pipeline/tests/test_form_authoring_details.py pipeline/tests/test_word_registry.py pipeline/tests/test_authoring_context.py pipeline/tests/test_authoring_continuation.py pipeline/tests/test_editorial_import.py -q
........................................................................ [ 75%]
........................                                                 [100%]
96 passed in 17.83s
Exit 0

flutter test --no-pub test/data/form_content_test.dart test/data/form_learning_test.dart test/domain/form_projection_test.dart test/form_learning_flow_test.dart test/form_counts_widget_test.dart
00:08 +27: All tests passed!
Exit 0

dart run tool/report_learning_groups.dart pipeline/out/irregular_verbs_batch_4_v1/content.sqlite
mixed: raw_words=2534; learning_targets=2453; lexical_words=2182; form_memberships=402
Exit 0

dart run tool/stage_content_pack.dart --from pipeline/out/irregular_verbs_batch_4_v1
staged assets/content/en/content.sqlite
  version irregular_verbs_batch_4_v1, schema 4, 16863232 bytes
  sha256 e99074c535015c7875a5c8ac5e4c68e318ab4d569825db488e01dd4947bdcde3
  22 table counts match finalization_report.json
  INTERNES TEST-PACK: own devices and selected testers only, no public content release
Exit 0

dart run tool/stage_content_pack.dart --verify
verified assets/content/en/content.sqlite
  version irregular_verbs_batch_4_v1, schema 4, 16863232 bytes
  sha256 e99074c535015c7875a5c8ac5e4c68e318ab4d569825db488e01dd4947bdcde3
  22 table counts match finalization_report.json
  INTERNES TEST-PACK: own devices and selected testers only, no public content release
Exit 0

flutter test --no-pub test/data/real_pack_test.dart
00:00 +0: loading /Users/ardasayar/Documents/FlutterProjekte/sprachapp/test/data/real_pack_test.dart
00:00 +0: staged pack: all cards and sentence links readable, read-only
SCHEMA4 mixed exercises=2453 lexical=2182; 402 forms / 71 reuse / cut 3 identities PASS
deck allgemeine-sprache: 160 learning targets, 181 ownership cards, 181 fixed sentence assignments verified
deck reisen: 489 learning targets, 519 ownership cards, 519 fixed sentence assignments verified
deck alltag-zuhause: 241 learning targets, 262 ownership cards, 262 fixed sentence assignments verified
deck arbeit-bildung: 245 learning targets, 252 ownership cards, 252 fixed sentence assignments verified
deck menschen-beziehungen: 245 learning targets, 251 ownership cards, 251 fixed sentence assignments verified
deck koerper-gesundheit: 249 learning targets, 264 ownership cards, 264 fixed sentence assignments verified
deck essen-trinken: 250 learning targets, 250 ownership cards, 250 fixed sentence assignments verified
deck natur-umwelt: 242 learning targets, 248 ownership cards, 248 fixed sentence assignments verified
deck irregular_verbs_base: 134 learning targets, 129 ownership cards, 129 fixed sentence assignments verified
deck irregular_verbs_past: 134 learning targets, 0 ownership cards, 0 fixed sentence assignments verified
deck irregular_verbs_participle: 134 learning targets, 0 ownership cards, 0 fixed sentence assignments verified
pack irregular_verbs_batch_4_v1 (schema 4, internal: true); 11 decks: 2356 cards, 2567 card sentences, 162 with valid_alternatives, 2567 cards in the pack
01:09 +1: All tests passed!
Exit 0

flutter analyze --no-pub
Analyzing sprachapp...
No issues found! (ran in 3.9s)
Exit 0
```

96 Pipeline-Tests und 28 gezielte Flutter-Tests bestanden (27 Formtests plus Elf-Stapel-Lesetest). Der bestehende Lesetest wurde um den letzten Batch, 134 Lexikalanker und getrennte split/spread-Karten erweitert; die bestehenden cut/hit/lay/read/run/put/set-Prüfungen bleiben aktiv. Alte Schema-Kompatibilität bleibt über die vorhandenen Regressionen erhalten. Keine neue Importarchitektur oder App-/SRS-/Synonymlogik. Eine bestehende Drift-Debugwarnung zu mehreren synthetischen Testdatenbanken tritt auf; die Tests bestehen. Keine vollständige Flutter-Suite oder Geräteprüfung behauptet.

## Abschlusshashes und Bestandsschutz

| Datei | SHA256 |
|---|---|
| finaler Pack-JSON | `bf13af162d0cd12122665f9f8dc2edfd57daaf38c9e2a6ee58125452c3a267dc` |
| finale SQLite / internes Asset | `e99074c535015c7875a5c8ac5e4c68e318ab4d569825db488e01dd4947bdcde3` |
| finales Asset-Manifest | `88e460403aeb0733cec65bf7fe74d1e5d5d7062b6d1e27fb0f5db2923f70a9c5` |

Der Hashaudit über 2633 vorbestehende Dateien weist nur die genehmigten Dokument-/Teständerungen aus: `NEXTSTEPS.md`, Roadmap, gemeinsamer Authoring-Bericht und Pack-Lesetest. Historische Packs, Original-Lieferungen, Auswahl-/Registry-/Gruppensnapshots, frühere Korrekturbelege, Leserfix und alle vier bisherigen Authoring-ZIPs bleiben unverändert. Asset/Manifest wurden ausschließlich mit dem bestehenden Staging-Werkzeug ersetzt. Keine echte `user.db`, keine Lernstandsübertragung/-rücksetzung, keine App-Deinstallation. Normaler App-Einstieg bleibt bytegleich.

Eigene Diffprüfung: `git -c core.whitespace=cr-at-eol diff --check -- NEXTSTEPS.md docs/content-roadmap-v1.md docs/irregular-verbs-authoring.md docs/irregular-verbs-batch-4-import.md test/data/real_pack_test.dart`: keine Ausgabe, Exit 0. Neue Markdown-/JSON-Nachweise zusätzlich direkt auf nachgestellte Leerzeichen geprüft. Bekannte CRLF-/Whitespace-Altbefunde bleiben getrennt offen; keine globale Bereinigung.

## Kurze iPhone-Aktualisierung ohne Deinstallation

Kein Gerätetest wurde in diesem Auftrag ausgeführt. Anleitung für **macOS Terminal** mit dem bisherigen Projekt, unveränderter Bundle-ID und bisheriger Signierung:

1. Lokal `dart run tool/stage_content_pack.dart --verify` ausführen; erwartet `irregular_verbs_batch_4_v1`, Schema 4 und den oben genannten Assethash.
2. iPhone anschließen und entsperren; mit `flutter devices` die tatsächliche Geräte-ID ermitteln.
3. `flutter run --no-pub -d "IPHONE-ID"` ausführen, wobei IPHONE-ID durch diese Geräte-ID ersetzt wird. Die vorhandene App aktualisieren und ihre Daten behalten; keine Deinstallation oder Datenrücksetzung.
4. Nach dem Start drei Verbenansichten mit je 134 Übungen prüfen; vorhandene Favoriten/Notizen/Lernstände kontrollieren. Bei unveränderten Daten und allen freigegebenen Ansichten entspricht das Inhaltsinventar 2453 Übungen / 2182 Wörtern; persönliche Filter/Lernstände können sichtbare Werte beeinflussen.

Der bestehende `ContentPackInstaller` prüft Asset/Manifest und ersetzt ausschließlich die Inhaltsdatei in seinem Content-Verzeichnis atomar; `user.db` liegt außerhalb dieses Austauschs. Diese Anleitung ist kein bereits ausgeführter iPhone-Nachweis.

## Roadmap und verbleibende Aufgaben

Der gemeinsame Authoring-Bericht und die Roadmap sind nach den bestandenen Prüfungen auf den technischen internen Abschluss aktualisiert: elf abgeschlossene Stapel, weiterhin exakt 14 geplante Kategorien. Nächster Inhaltsschritt ist **Alltagssprache & Redewendungen, ca. 450 nach Dublettenprüfung**, danach Verbalphrasen (ca. 200), zuletzt Business & E-Mail (ca. 1500 einschließlich ca. 70 E-Mail-Zielen). In diesem Auftrag keine neue Auswahl, Reservierung oder Satzlieferung dafür angelegt.

Offen bleiben die gesonderten geerbten Glossenbefunde, tatsächliche Geräteabnahme und öffentliche Sprach-/Inhaltsfreigabe. Keine Batch-5-Auswahl und keine zusätzliche Verben-Authoring-ZIP. NEXTSTEPS umfasst höchstens 25 sachliche Zeilen.
