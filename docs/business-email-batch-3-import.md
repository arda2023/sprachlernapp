# Business & E-Mail – Batch 3: Offline-Import und interne Abnahme

Stand: 14.10.2026. **97 neue /291 gesamte Business-Ziele** als `business_email_batch_3_v1` importiert und intern gestagt. **3480 Karten, 14 Stapel, 3366 Übungen /3095 lexikalische Ziele** nach vorhandener App-Projektion. Technische Abnahme und öffentliche Inhaltsfreigabe bleiben getrennt. Keine Geräteabnahme, unabhängige menschliche Sprachfreigabe, Cloud-/Modellaufrufe, Paketinstallation oder Änderung am Produktions-/Testcode; keine echte user.db verwendet.

## Eingaben und Schutz des Bestands

Originalauswahl `pipeline/data/selection/business_email_v2.json`, Fortsetzung `pipeline/data/selection/business_email_batch_3_context_v1.json`, Registry `pipeline/data/words/en.business_email_batch_3_context_v1.json`, Gruppen `pipeline/data/learning_groups/en.business_email_batch_3_context_v1.json`. `selection_id` bleibt `business_email_v2`, historische Eintrags-IDs `business-email-v1-####` bleiben identisch. Basis: `pipeline/out/business_email_batch_2_v1/{pack.json,content.sqlite}`, Schema 4; Asset und Manifest vor Import gegen die geprüften Basis-Hashes abgeglichen.

Ausgangspartition **194 importiert /97 aktuell /288 später**. Gesamtumfang **579 Ziele /43 E-Mail-Ziele**, Batches **97/97/97/96/96/96**, 278 ausgeschlossene Kandidaten unverändert. Keine Auffüllung und kein neuer Stapel.

Original-ZIP `/Users/ardasayar/Downloads/business_email_batch_3_lieferung.zip` geschlossen/erneut geöffnet, CRCs, eindeutige sichere Mitgliedspfade und alle **33 manifestgebundenen Dateihashes** geprüft. Vorhandener Ordner `business_email_batch_3/` vollständig bytegleich. Danach bytegleiche Arbeitskopie unter `editorial_review/business_email_batch_3/` angelegt; Create und Display-Patch daraus unverändert verwendet. Mitgelieferte authoring_evidence-Skripte nicht ausgeführt.

**Manifestlücke:** `reference/manifest.json` ist als einzige zusätzliche Inhaltsdatei nicht im Liefermanifest gelistet. Sie und sämtliche anderen Referenzdateien wurden unabhängig bytegenau gegen die vorher geprüfte `build/business_email_authoring_batch_3.zip` mit bekanntem Gesamt-SHA256 `9b1f6caf6465d2e910c0f9cea60293a4fac80b3a9e862e32c8e65b487db35cf8` gebunden. Keine Manifestdatei geändert und kein Inhaltsvalidator gelockert. Original-/Arbeitskopie bleiben unverändert.

Ausgangs-HEAD `68c39306d5c93c6ec5ec07028144f957fca67a78`; Index leer. Baseline von **3006 Dateien** einschließlich vorbestehender untracked Lieferungen. Vorbestehende Änderungen und Fremddateien bleiben erhalten. NEXTSTEPS war bereits geändert und bleibt außerhalb des isolierten Commits. Historische Packs, Registrys, Auswahlen, Original-Lieferungen und Instruktionsdateien sind hashgleich zum Ausgangszustand.

## Vollständige redaktionelle Prüfung

Alle **97 Satzpaare, Zielbedeutungen und 1139 Tokenpositionen** vollständig gegengelesen: **1035 Wort-/Ausdruckstokens und 104 Satzzeichen**. Neue Begleitwortdefinitionen und 175 neue Formglossen zusätzlich gelesen. Keine belegte neue Bindungskorrektur erforderlich; Satztexte, Übersetzungen, IDs, Definitionen, Links und Reviewhashes unverändert. Genau ein fester Satz je neuem Ziel, zusammenhängende Vollform-Lücke, `accepted` ausschließlich `[Zielform]`. Vollständiger Einzelprüfnachweis mit allen Satzpaaren und Hashes: `build/business_email_batch_3_checks/editorial-review.json`. Redaktionelle Modellprüfung, keine menschliche Zertifizierung.

Kontextunterschiede bestätigt: checks bei proactive = check/VERB, bei quality assurance = check/NOUN; remote working = working/NOUN, working hours = working/ADJ, stopped working = work/VERB mit Bedeutung funktionieren. account in direct debit = Bankkonto, accounts bei self-employed = Buchführung. receipt bei by return email = Erhalt, receipts bei expense claim = Belege. to-Präpositionen und Infinitivmarker getrennt; overall und back-to-back als Adjektive. VAT behält Großschreibung/Identität; I look forward to hearing from you bleibt vollständiges Ziel mit einer zusammenhängenden Lücke.

Vier Varianten wörtlich im Satz eingesetzt und gelesen: **instalment → installment**, **prioritise → prioritize**, **time sheet → timesheet**, **email → e-mail**. Gleiche Bedeutung und passende Übersetzung; keine Synonyme oder weitere Lernziele. Gegen alle 579 Reservierungen, Bestandskarten, Besitz-/Synonymaliase und Registry geprüft; keine Kollision. Keine neue word_aliases-Zeile. Varianten bleiben ausschließlich satzbezogen und lernstandsneutral.

Vier zukünftige Ziele als Begleitwort-Senses mit exakt reservierter Definition, ohne vorzeitige Karte:

- `realistic/ADJ|realistic#realistisch`: Mit den tatsächlich vorhandenen Umständen und Möglichkeiten vereinbar.
- `warehouse/NOUN|warehouse#warenlager`: Gebäude zur Lagerung größerer Warenmengen.
- `conference/NOUN|conference#konferenz`: Organisierte größere Zusammenkunft zum fachlichen Austausch.
- `cell/NOUN|cell#tabellenzelle`: Einzelnes Feld am Schnittpunkt von Zeile und Spalte einer Tabelle.

Die 14 gelieferten kontextuellen Glossenvergleiche sind **Altbefunde**, keine abgeschlossene Fehlerliste. Alle zugrunde liegenden Bestands-Dictionary-Zeilen exakt bestätigt und unverändert erhalten:

| Form | Geerbte Glosse | Kontextvergleich |
|---|---|---|
| training | Trainings | Schulung |
| reduce | Einkochen | verringern |
| starting | anfänglich; zum Einstieg | beginnen; beim Beginnen |
| lower | untere; niedriger gelegene | niedriger |
| needed | brauchten | benötigt |
| valid | gültige | gültig |
| kept | fuhr fort (kept walking on = ging weiter) | fuhr fort; tat weiterhin |
| left | hinterlassen | ließen; hinterließen |
| died | starben | starb |
| signed | unterschrieben | unterzeichneten / unterschrieben |
| name | Namen | Name; Namens- |
| main | Haupt- | wichtigste; Haupt- |
| could | konnten | konnte |
| follow | folgen Sie | befolge |

Ältere Batch-1-/Batch-2-, Pilot-, no-show-Label- und Verbalphrasen-Glossenbefunde bleiben ebenfalls offen. Keine globale Glossenreparatur.

## Import, Display und vollständiger Tabellenabgleich

Vorhandener V2-Create-Importer auf Schema-4-Basis mit expliziter Registry und hashgebundenem Display-Patch. Anhänge zunächst **195–291**, danach ausschließlich Business-Anzeigeabbildung **1–291**. **0 alte Positionswerte geändert**; alle Originalauswahlpositionen und Identitäten erhalten. Neues Ausgabeziel ohne Überschreiben.

Nach Export SQLite geschlossen und neu schreibgeschützt geöffnet. Sämtliche **22 Tabellen** mit `build_rows` und vorhandenem `finalize_curation.check_sqlite` vollständig verglichen. Exportzeitstempel `content_releases.created_at` gemäß vorhandenem Vertrag vom exakten Wertvergleich ausgenommen, Vorhandensein geprüft. Alle Altzeilen der übrigen 21 Tabellen einschließlich Anzeigepositionen vollständig erhalten: insbesondere **3383 Karten, 3917 Sätze, 42539 Tokens, 7436 Dictionary-Zeilen**. Release und Registry autorisiert fortgeschrieben.

| Tabelle | Gesamtzeilen |
|---|---:|
| languages | 1 |
| lemmas | 4674 |
| senses | 6356 |
| cards | 3480 |
| dictionary_forms | 7611 |
| decks | 14 |
| deck_cards | 3373 |
| deck_words | 3269 |
| word_aliases | 37 |
| sentences | 4014 |
| sentence_tokens | 43678 |
| card_sentences | 4008 |
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

Vier Formtabellen wertgleich: **134 /406 /402 /402**, jeweils **134** Übungen für Infinitiv/Präsens, Präteritum und Partizip. Batch-2-Korrekturen explizit nachgeprüft: planning in business-email-v1-0131-s1 Index 7 → plan/VERB; either in -0150-s1 Index 3 → either/DET; today in -0189-s1 Index 3 → today/NOUN. Auch pick out „aus einer Menge erkennen“ und pull over „an den Straßenrand fahren und anhalten“ exakt erhalten.

Bestehende App-Projektion: **3366 Übungen /3095 Wörter**, Business **291**, 14 Stapel. 3480 physische Karten und 3269 Besitzzeilen sind getrennte Mengen; Formübungen zählen dieselben Verben nicht dreimal als neue Wörter.

Linter **0 Fehler /488 Hinweise**: **486 unveränderte Altbefunde** plus genau zwei neue Hinweise:

- log out: `'unattended'/'unattended' Zipf 3.18 below 3.5`.
- payment reference: `'invoice'/'invoice' Zipf 3.27 below 3.5`.

## Sicherung, App-Prüfung und Fortsetzung

Asset und Manifest **vor Staging** unter `build/business_email_batch_3_checks/backup/` bytegenau gesichert, UTC-Zeit `2026-10-14T08:07:28.870737+00:00`; Hashes unten. Anschließend Stage und separater `--verify` erfolgreich. Asset ist bytegleich zur Export-SQLite.

Alle 455 Pipeline-Tests plus 19 Untertests bestanden. Flutter-Analyse `--no-pub` und bestehender Pack-Lesetest `test/data/real_pack_test.dart` tatsächlich ausgeführt; vollständige Outputs und Exitcodes unten. Der reale Test läuft einzeln ohne parallele Flutter-/Dart-Prüfungen. Der Batch-2-Erstlauf mit 30-Sekunden-Timeout bleibt ein offener Laufzeitbefund; der damalige unveränderte Wiederholungserfolg beweist keine Ursachenbehebung. Keine Zeitgrenzen oder Assertions verändert.

Die drei tatsächlichen neuen Pfade wurden **vor dem Schreiben** aus dem vorhandenen Exporter und seiner `--help` ermittelt, anschließend ausschließlich über `--prepare-continuation` aus der Original-v2-Auswahl erzeugt:

- `pipeline/data/selection/business_email_batch_4_context_v1.json`
- `pipeline/data/words/en.business_email_batch_4_context_v1.json`
- `pipeline/data/learning_groups/en.business_email_batch_4_context_v1.json`

Der Verifier ermittelt **12 wiederverwendbare vorgeschlagene Senses** in der Fortsetzung.

Batch 4: **291 importiert /96 aktuell /192 später**; alle 579 Originaleinträge, Definitionen, Reservierungen und Ausschlüsse objektgleich. Die geschlossene ZIP erneut geöffnet: **83 Dateihashes, CRCs und 22 Quelltabellen** geprüft. Eingebundene pack.json bytegleich zum neuen Export, SQLite bytegleich zum neuen Asset. Kombinierte Anzeigeabbildung hat **387 eindeutige Zeilen 1–387**; keine Karten oder Sätze für spätere Ziele erzeugt. Keine neue Kategorie.

ZIP: **26620446 komprimierte /81371077 unkomprimierte Bytes**.

Pack: `/Users/ardasayar/Documents/FlutterProjekte/sprachapp/pipeline/out/business_email_batch_3_v1/`

Upload: `/Users/ardasayar/Documents/FlutterProjekte/sprachapp/build/business_email_authoring_batch_4.zip`

## Hashnachweise

Rohbyte-SHA256, sofern nicht ausdrücklich als kanonischer JSON-Digest bezeichnet:

| Objekt | SHA256 |
|---|---|
| Liefer-ZIP | `c6fa1a86606b8ecaf4ce4815557674d64bbd7a638325d123a16852ba87e9d3c1` |
| Create (Original und Arbeitskopie) | `434fd0755e945e7a19c0ff2a4bbd8c90d8ba6b329f6b210bc4da0e752d4b77e8` |
| Basis pack.json | `ac413e251f3f7f0d90a3a1d274e1c7b35a6111915b873cb594d861a25783c23f` |
| Eingabe-Registry (kanonisch) | `49240c7232edf588e355e9222d687bbdbaecfde996149e99f30961b072b2ad7c` |
| Eingabe-Gruppen (kanonisch) | `3c4884b75f3f12aca32b204574f13b076c8dd7fb7f8f28cc8097cea12f950310` |
| Backup content.sqlite | `b0be2ea5696376744a60af18a807c3d5b68591ecf8be4e42cc4300fea8520569` |
| Backup content.manifest.json | `6994a984acaa7d9494ae839d058a95f5de81487a5492a175905ce2c4b2e1814e` |
| Export pack.json | `08487c7c2c257a5fe25441d13fa2354d8126cefabfdc226435b52bd9ca7e9935` |
| Export content.sqlite | `021bbc05aa8b0f283fe6b7911a3a928b5ccedf6316af397e3ddf2309afee6e52` |
| Export finalization_report.json | `99af178613dadb6df26dd13b3de0117d8097f6822534be0e325559acf5559505` |
| build/business_email_authoring_batch_4.zip | `18798209b4029ed77a4cd8e111c154c0502dc2e6235d4170ec79e47861e8be5c` |
| assets/content/en/content.manifest.json | `0f929a97825a86d8f9e21c514998d9ad01ba07922de567a5ec28e12b9ed48322` |
| pipeline/data/selection/business_email_batch_4_context_v1.json | `dc07c99889587d3181cf1635959d32abcb6a92ad8cb4ee0e58c62c5077f70d05` |
| pipeline/data/words/en.business_email_batch_4_context_v1.json | `8d3934383a7dbad72f6803fe145ccd1959b4f8132c21ec969a64b703c7d6f01f` |
| pipeline/data/learning_groups/en.business_email_batch_4_context_v1.json | `23babef402095dc9344c18d9caa2ce402b54af39738a81a41a624f481c893a33` |

## Ausgeführte Befehle, tatsächliche Outputs und Exitcodes

Ab Repository-Root auf macOS. Windows PowerShell: Pythonpfad durch `.\pipeline\.venv\Scripts\python.exe` ersetzen; Dart-/Flutter-/Git-Argumente identisch. Lokaler Wrapper `build/business_email_batch_3_checks/run_check.py NAME BEFEHL …` speichert den vollständig ausgeführten Befehl, Exitcode und Laufzeit in `NAME.command.json`, Ausgabe in `NAME.log`. Nachfolgend relevante tatsächliche Ausschnitte; ungekürzte Logs im genannten Verzeichnis.

### baseline

```text
pipeline/.venv-macos/bin/python build/business_email_batch_3_checks/baseline.py
status-before.txt 0  M NEXTSTEPS.md
?? alltagssprache_redewendungen_batch_3/
?? alltagssprache_redewendungen_batch_4/
?? alltagssprache_redewendungen_batch_5/
?? business_email_batch_1/
?? business_email_batch_2/
?? business_email_batch_3/
?? docs/alltagssprache-redewendungen-batch-3-import.md
?? docs/alltagssprache-redewendungen-batch-4-import.md
?? docs/codebase-overview-planning.md
?? pipeline/data/learning_groups/en.alltagssprache_redewendungen_batch_4_context_v2.json
?? pipeline/data/learning_groups/en.alltagssprache_redewendungen_batch_5_context_v2.json
?? pipeline/data/selection/alltagssprache_redewendungen_batch_4_context_v2.json
?? pipeline/data/selection/alltagssprache_redewendungen_batch_5_context_v2.json
?? pipeline/data/words/en.alltagssprache_redewendungen_batch_4_context_v2.json
?? pipeline/data/words/en.alltagssprache_redewendungen_batch_5_context_v2.json
?? verbalphrasen_batch_1/
?? "verbalphrasen_batch_2 2/"

index-before.txt 0
head.txt 0 68c39306d5c93c6ec5ec07028144f957fca67a78

baseline_files 3006
EXIT 0
```

### delivery-audit

```text
pipeline/.venv-macos/bin/python build/business_email_batch_3_checks/delivery_audit.py
Traceback (most recent call last):
  File "/Users/ardasayar/Documents/FlutterProjekte/sprachapp/build/business_email_batch_3_checks/delivery_audit.py", line 15, in <module>
    assert set(names)=={'business_email_batch_3/'+n for n in manifest['files']}|{'business_email_batch_3/manifest.json'}
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
AssertionError
EXIT 1
```

### delivery-audit-reference-bound

```text
pipeline/.venv-macos/bin/python build/business_email_batch_3_checks/delivery_audit.py
Traceback (most recent call last):
  File "/Users/ardasayar/Documents/FlutterProjekte/sprachapp/build/business_email_batch_3_checks/delivery_audit.py", line 51, in <module>
    e=next(e for e in s['entries'] if e['selection_id']==f['selection_id']);assert e['authoring_batch']>3 and e['sense_ref']==f['sense'];assert senses[f['sense']]['definition_de']==e['definition_de'];assert e['card_ref'] not in cards
  File "/Users/ardasayar/Documents/FlutterProjekte/sprachapp/build/business_email_batch_3_checks/delivery_audit.py", line 51, in <genexpr>
    e=next(e for e in s['entries'] if e['selection_id']==f['selection_id']);assert e['authoring_batch']>3 and e['sense_ref']==f['sense'];assert senses[f['sense']]['definition_de']==e['definition_de'];assert e['card_ref'] not in cards
                                                         ~^^^^^^^^^^^^^^^^
KeyError: 'selection_id'
EXIT 1
```

### delivery-audit-final

```text
pipeline/.venv-macos/bin/python build/business_email_batch_3_checks/delivery_audit.py
{
  "status": "PASS",
  "manifest_exception": "reference/manifest.json unlisted in delivery manifest; separately byte-identical to previous verified authoring ZIP bound by known full ZIP SHA256",
  "delivery_zip": "/Users/ardasayar/Downloads/business_email_batch_3_lieferung.zip",
  "zip_sha256": "c6fa1a86606b8ecaf4ce4815557674d64bbd7a638325d123a16852ba87e9d3c1",
  "create_sha256": "434fd0755e945e7a19c0ff2a4bbd8c90d8ba6b329f6b210bc4da0e752d4b77e8",
  "manifest_files": 33,
  "all_local_files_match_zip": true,
  "source_json_sha256": "ac413e251f3f7f0d90a3a1d274e1c7b35a6111915b873cb594d861a25783c23f",
  "registry_digest": "49240c7232edf588e355e9222d687bbdbaecfde996149e99f30961b072b2ad7c",
  "groups_digest": "3c4884b75f3f12aca32b204574f13b076c8dd7fb7f8f28cc8097cea12f950310",
  "current": 97,
  "total": 579,
  "words": 1035,
  "punctuation": 104,
  "alternatives": [
    [
      "instalment|instalment/NOUN|instalment#rate",
      "installment"
    ],
    [
      "email|email/NOUN|email#e-mail",
      "e-mail"
    ],
    [
      "prioritise|prioritise/VERB|prioritise#nach-wichtigkeit-ordnen",
      "prioritize"
    ],
    [
      "time sheet|time sheet/NOUN|time-sheet#arbeitszeitnachweis",
      "timesheet"
    ]
  ],
  "future_companion_senses": [
    {
      "form": "realistic",
      "sense": "realistic/ADJ|realistic#realistisch",
      "definition_de": "Mit den tatsächlich vorhandenen Umständen und Möglichkeiten vereinbar.",
      "card_added": false
    },
    {
      "form": "warehouse",
      "sense": "warehouse/NOUN|warehouse#warenlager",
      "definition_de": "Gebäude zur Lagerung größerer Warenmengen.",
      "card_added": false
    },
    {
      "form": "conference",
      "sense": "conference/NOUN|conference#konferenz",
      "definition_de": "Organisierte größere Zusammenkunft zum fachlichen Austausch.",
      "card_added": false
    },
    {
      "form": "cell",
      "sense": "cell/NOUN|cell#tabellenzelle",
      "definition_de": "Einzelnes Feld am Schnittpunkt von Zeile und Spalte einer Tabelle.",
      "card_added": false
    }
  ],
  "add_counts": {
    "lemmas": 130,
    "senses": 150,
    "cards": 97,
    "decks": 0,
    "deck_cards": 97,
    "deck_words": 97,
    "word_aliases": 0,
    "sentences": 97,
    "sentence_tokens": 1139,
    "dictionary_forms": 175,
    "card_sentences": 97
  }
}
EXIT 0
```

### pipeline-tests

```text
pipeline/.venv-macos/bin/python -m pytest pipeline/tests -q
........................................................................ [ 15%]
........................................................................ [ 31%]
..................................................... [ 43%]
........................................................................ [ 59%]
........................................................................ [ 74%]
........................................................................ [ 90%]
..........................................                               [100%]
455 passed, 19 subtests passed in 28.69s
EXIT 0
```

### import

```text
pipeline/.venv-macos/bin/python pipeline/scripts/import_editorial_patch.py --source pipeline/out/business_email_batch_2_v1/pack.json --create editorial_review/business_email_batch_3/editorial_content_v2.json --display-patch editorial_review/business_email_batch_3/deck_display_patch.json --registry pipeline/data/words/en.business_email_batch_3_context_v1.json --out pipeline/out/business_email_batch_3_v1
{
  "status": "ok",
  "internal_test_pack": true,
  "ai_calls": 0,
  "ai_cost_usd": 0,
  "sqlite_counts": {
    "languages": 1,
    "lemmas": 4674,
    "senses": 6356,
    "cards": 3480,
    "dictionary_forms": 7611,
    "decks": 14,
    "deck_cards": 3373,
    "deck_words": 3269,
    "word_aliases": 37,
    "sentences": 4014,
    "sentence_tokens": 43678,
    "card_sentences": 4008,
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
  "sha256": "021bbc05aa8b0f283fe6b7911a3a928b5ccedf6316af397e3ddf2309afee6e52"
}
EXIT 0
```

### export-audit

```text
pipeline/.venv-macos/bin/python build/business_email_batch_3_checks/export_audit.py
PRESERVED pick out {"ref": "pick out/VERB|pick-out#wiedererkennen", "lemma": "pick out/VERB", "sense_key": "pick-out#wiedererkennen", "gloss_de": "wiedererkennen", "definition_de": "Eine bestimmte Person oder Sache in einer größeren Menge erkennen."}
PRESERVED pull over {"ref": "pull over/VERB|pull-over#rechts-ranfahren", "lemma": "pull over/VERB", "sense_key": "pull-over#rechts-ranfahren", "gloss_de": "rechts ranfahren", "definition_de": "Mit einem Fahrzeug an den Straßenrand fahren und dort anhalten."}
Business existing positions changed 0
{
  "status": "PASS",
  "old_business_positions_changed": 0,
  "tables": {
    "languages": 1,
    "lemmas": 4674,
    "senses": 6356,
    "cards": 3480,
    "dictionary_forms": 7611,
    "decks": 14,
    "deck_cards": 3373,
    "deck_words": 3269,
    "word_aliases": 37,
    "sentences": 4014,
    "sentence_tokens": 43678,
    "card_sentences": 4008,
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
  "old_json_lists_unchanged": {
    "languages": 1,
    "lemmas": 4544,
    "senses": 6206,
    "cards": 3383,
    "decks": 14,
    "deck_cards": 3276,
    "dictionary_forms": 7436,
    "sentences": 3917,
    "sentence_tokens": 42539,
    "card_sentences": 3911,
    "deck_words": 3172,
    "word_aliases": 37,
    "stories": 1,
    "story_sentences": 6,
    "lexical_targets": 134,
    "card_lexical_targets": 406,
    "form_targets":
[gekürzt; vollständiger Output im gleichnamigen Log]

      "rule": "i+1",
      "message": "'invoice'/'invoice' Zipf 3.27 below 3.5"
    }
  ],
  "errors": 0,
  "sha256": {
    "pack.json": "08487c7c2c257a5fe25441d13fa2354d8126cefabfdc226435b52bd9ca7e9935",
    "content.sqlite": "021bbc05aa8b0f283fe6b7911a3a928b5ccedf6316af397e3ddf2309afee6e52",
    "finalization_report.json": "99af178613dadb6df26dd13b3de0117d8097f6822534be0e325559acf5559505"
  }
}
EXIT 0
```

### editorial-review

```text
pipeline/.venv-macos/bin/python build/business_email_batch_3_checks/review_record.py
PASS 97 pairs /1139 tokens; 0 binding corrections; 4 literal alternatives; 14 inherited gloss comparisons; all old SQL rows including positions unchanged.
EXIT 0
```

### backup

```text
pipeline/.venv-macos/bin/python build/business_email_batch_3_checks/backup_before_stage.py
{
  "status": "PASS",
  "time_utc": "2026-10-14T08:07:28.870737+00:00",
  "hashes": {
    "content.sqlite": "b0be2ea5696376744a60af18a807c3d5b68591ecf8be4e42cc4300fea8520569",
    "content.manifest.json": "6994a984acaa7d9494ae839d058a95f5de81487a5492a175905ce2c4b2e1814e"
  },
  "before_staging": true
}
EXIT 0
```

### stage

```text
dart run tool/stage_content_pack.dart --from pipeline/out/business_email_batch_3_v1
staged assets/content/en/content.sqlite
  version business_email_batch_3_v1, schema 4, 21774336 bytes
  sha256 021bbc05aa8b0f283fe6b7911a3a928b5ccedf6316af397e3ddf2309afee6e52
  22 table counts match finalization_report.json
  INTERNES TEST-PACK: own devices and selected testers only, no public content release
Running build hooks...Running build hooks...
EXIT 0
```

### stage-verify

```text
dart run tool/stage_content_pack.dart --verify
verified assets/content/en/content.sqlite
  version business_email_batch_3_v1, schema 4, 21774336 bytes
  sha256 021bbc05aa8b0f283fe6b7911a3a928b5ccedf6316af397e3ddf2309afee6e52
  22 table counts match finalization_report.json
  INTERNES TEST-PACK: own devices and selected testers only, no public content release
Running build hooks...Running build hooks...
EXIT 0
```

### app-projection

```text
dart run tool/report_learning_groups.dart pipeline/out/business_email_batch_3_v1/content.sqlite
{
  "business-email": {
    "raw_words": 291,
    "learning_targets": 291,
    "lexical_words": 291,
    "form_memberships": 0
  },
  "mixed": {
    "raw_words": 3447,
    "learning_targets": 3366,
    "lexical_words": 3095,
    "form_memberships": 402
  }
}
EXIT 0
```

### flutter-analyze

```text
flutter analyze --no-pub
Analyzing sprachapp...
No issues found! (ran in 3.9s)
EXIT 0
```

### real-pack-test

```text
flutter test --no-pub test/data/real_pack_test.dart
00:00 +0: loading /Users/ardasayar/Documents/FlutterProjekte/sprachapp/test/data/real_pack_test.dart
00:00 +0: staged pack: all cards and sentence links readable, read-only
00:31 +0 -1: staged pack: all cards and sentence links readable, read-only [E]
  TimeoutException after 0:00:30.000000: Test timed out after 30 seconds. See https://pub.dev/packages/test#timeouts
  dart:isolate  _RawReceivePort._handleMessage

00:32 +0 -1: Some tests failed.

Failing tests:
  /Users/ardasayar/Documents/FlutterProjekte/sprachapp/test/data/real_pack_test.dart: staged pack: all cards and sentence links readable, read-only
EXIT 1
```

### real-pack-test-repeat

```text
flutter test --no-pub test/data/real_pack_test.dart
00:00 +0: loading /Users/ardasayar/Documents/FlutterProjekte/sprachapp/test/data/real_pack_test.dart
00:00 +0: staged pack: all cards and sentence links readable, read-only
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
deck alltagssprache-redewendungen: 441 learning targets, 441 ownership cards, 441 fixed sentence assignments verified
deck verbalphrasen: 181 learning targets, 181 ownership cards, 181 fixed sentence assignments verified
deck business-email: 291 learning targets, 291 ownership cards, 291 fixed sentence assignments verified
pack business_email_batch_3_v1 (schema 4, internal: true); 14 decks: 3269 cards, 3480 card sentences, 196 with valid_alternatives, 3480 cards in the pack
01:45 +1: All tests passed!
EXIT 0
```

### exporter-help

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
EXIT 0
```

### continuation

```text
pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --selection pipeline/data/selection/business_email_v2.json --batch 4 --prepare-continuation business_email_batch_4_context_v1
{
  "snapshots": "PASS",
  "paths": {
    "selection": "pipeline/data/selection/business_email_batch_4_context_v1.json",
    "registry": "pipeline/data/words/en.business_email_batch_4_context_v1.json",
    "groups": "pipeline/data/learning_groups/en.business_email_batch_4_context_v1.json"
  },
  "partition_counts": {
    "imported": 291,
    "current": 96,
    "future": 192
  }
}
EXIT 0
```

### zip-export

```text
pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --selection pipeline/data/selection/business_email_batch_4_context_v1.json --batch 4 --out build/business_email_authoring_batch_4.zip
{
  "export": "PASS",
  "zip": "/Users/ardasayar/Documents/FlutterProjekte/sprachapp/build/business_email_authoring_batch_4.zip",
  "files": 84,
  "status": "PASS",
  "selected": 579,
  "excluded": 278,
  "partition_counts": {
    "imported": 291,
    "current": 96,
    "future": 192
  },
  "reused_proposed_senses": 12,
  "batches": {
    "1": 97,
    "2": 97,
    "3": 97,
    "4": 96,
    "5": 96,
    "6": 96
  },
  "topics_per_batch": {
    "1": {
      "Zusammenarbeit und Aufgabenverteilung": 8,
      "Berufliche Kommunikation": 8,
      "Termine und Besprechungen": 8,
      "Projekte und Arbeitsabläufe": 10,
      "Personal, Bewerbung und Arbeitsbedingungen": 11,
      "Kundenservice und Problemlösung": 7,
      "Vertrieb, Einkauf und Bestellungen": 10,
      "Geld, Rechnungen und Zahlungen": 8,
      "Verträge und Organisation": 8,
      "IT und digitale Zusammenarbeit": 12,
      "E-Mail-Verkehr": 7
    },
    "2": {
      "Zusammenarbeit und Aufgabenverteilung": 8,
      "Berufliche Kommunikation": 8,
      "Termine und Besprechungen": 8,
      "Projekte und Arbeitsabläufe": 10,
      "Personal, Bewerbung und Arbeitsbedingungen": 10,
      "Kundenservice und Problemlösung": 8,
      "Vertrieb, Einkauf und Bestellungen": 9,
      "Geld, Rechnungen und Zahlungen": 8,
      "Verträge und Organisation": 9,
      "IT und digitale Zusammenarbeit": 12,
      "E-Mail-Verkehr": 7
    },
    "3": {
      "Zusammenarbeit und Aufgabenverteilung": 8,
      "Berufliche Kommunikation": 8,
      "Termine und Besprechungen": 8,
      "Projekte und Arbeitsabläufe": 10,
      "Personal
[gekürzt; vollständiger Output im gleichnamigen Log]
g_groups": 3468,
  "new_groups": 288,
  "registry_words": 3558,
  "partition_selection": "PASS: 291 present",
  "validate_selection": "PASS: parent and exact reservations",
  "index_registry": "PASS",
  "validate_learning": "PASS: existing and planned",
  "build_rows": "PASS: reservation-only rows unchanged",
  "semantic_review": "explicit editorial decisions, no automatic equivalence inference"
}
EXIT 0
```

### zip-verify

```text
pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --verify-zip build/business_email_authoring_batch_4.zip
{
  "zip_verification": "PASS",
  "zip_sha256": "18798209b4029ed77a4cd8e111c154c0502dc2e6235d4170ec79e47861e8be5c",
  "hashed_files": 83,
  "sqlite_tables": 22,
  "sqlite_cards": 3480,
  "credentials_and_learning_states": "none; explicit content/source/model whitelist",
  "status": "PASS",
  "selected": 579,
  "excluded": 278,
  "partition_counts": {
    "imported": 291,
    "current": 96,
    "future": 192
  },
  "reused_proposed_senses": 12,
  "batches": {
    "1": 97,
    "2": 97,
    "3": 97,
    "4": 96,
    "5": 96,
    "6": 96
  },
  "topics_per_batch": {
    "1": {
      "Zusammenarbeit und Aufgabenverteilung": 8,
      "Berufliche Kommunikation": 8,
      "Termine und Besprechungen": 8,
      "Projekte und Arbeitsabläufe": 10,
      "Personal, Bewerbung und Arbeitsbedingungen": 11,
      "Kundenservice und Problemlösung": 7,
      "Vertrieb, Einkauf und Bestellungen": 10,
      "Geld, Rechnungen und Zahlungen": 8,
      "Verträge und Organisation": 8,
      "IT und digitale Zusammenarbeit": 12,
      "E-Mail-Verkehr": 7
    },
    "2": {
      "Zusammenarbeit und Aufgabenverteilung": 8,
      "Berufliche Kommunikation": 8,
      "Termine und Besprechungen": 8,
      "Projekte und Arbeitsabläufe": 10,
      "Personal, Bewerbung und Arbeitsbedingungen": 10,
      "Kundenservice und Problemlösung": 8,
      "Vertrieb, Einkauf und Bestellungen": 9,
      "Geld, Rechnungen und Zahlungen": 8,
      "Verträge und Organisation": 9,
      "IT und digitale Zusammenarbeit": 12,
      "E-Mail-Verkehr": 7
    },
    "3": {
      "Zusammenarbeit und Aufgabenverteilung": 8,

[gekürzt; vollständiger Output im gleichnamigen Log]
g_groups": 3468,
  "new_groups": 288,
  "registry_words": 3558,
  "partition_selection": "PASS: 291 present",
  "validate_selection": "PASS: parent and exact reservations",
  "index_registry": "PASS",
  "validate_learning": "PASS: existing and planned",
  "build_rows": "PASS: reservation-only rows unchanged",
  "semantic_review": "explicit editorial decisions, no automatic equivalence inference"
}
EXIT 0
```

### final-audit

```text
pipeline/.venv-macos/bin/python build/business_email_batch_3_checks/final_audit.py
{
  "status": "PASS",
  "baseline_files": 3006,
  "changed_existing_files": [
    "assets/content/en/content.manifest.json",
    "assets/content/en/content.sqlite"
  ],
  "all_original_selection_entries_and_exclusions_equal": true,
  "batch_4": {
    "partition": {
      "imported": 291,
      "current": 96,
      "future": 192
    },
    "display_rows": 387,
    "zip_bytes": 26620446,
    "uncompressed_bytes": 81371077,
    "hashed_files": 83
  },
  "hashes": {
    "build/business_email_authoring_batch_4.zip": "18798209b4029ed77a4cd8e111c154c0502dc2e6235d4170ec79e47861e8be5c",
    "assets/content/en/content.manifest.json": "0f929a97825a86d8f9e21c514998d9ad01ba07922de567a5ec28e12b9ed48322",
    "pipeline/data/selection/business_email_batch_4_context_v1.json": "dc07c99889587d3181cf1635959d32abcb6a92ad8cb4ee0e58c62c5077f70d05",
    "pipeline/data/words/en.business_email_batch_4_context_v1.json": "8d3934383a7dbad72f6803fe145ccd1959b4f8132c21ec969a64b703c7d6f01f",
    "pipeline/data/learning_groups/en.business_email_batch_4_context_v1.json": "23babef402095dc9344c18d9caa2ce402b54af39738a81a41a624f481c893a33"
  }
}
EXIT 0
```

### whitespace-repository

```text
git diff --check
[keine Ausgabe]
EXIT 0
```

## Abweichungen, Grenzen und Commit-Isolation

Die wiederverwendete lokale Lieferprüfung scheiterte zunächst an der nicht gelisteten Referenzmanifestdatei (Exit 1). Neue Hypothese und konkrete Prüfung: Datei stammt unverändert aus der bekannten Authoring-ZIP; unabhängig über deren bekannten Gesamt-Hash und Bytevergleich abgesichert. Im zweiten Lauf scheiterte eine aus Batch 2 übernommene Prüferannahme `future_companion_senses.selection_id` mit KeyError (Exit 1); diese Lieferung verwendet Form/Sense/Definition. Tatsächliche Struktur gelesen und stattdessen Form **und** Sense gegen die unveränderte Auswahl geprüft. Dritter Auditlauf PASS. Keine Inhaltskorrektur, kein fehlgeschlagener CLI-Import und keine abgeschwächten Produktionsvalidatoren. Ein optionaler `ps`-Statusabruf war im Sandbox-Kontext nicht erlaubt (Exit 1); keine Auswirkung auf die Prüfjobs.

Repositoryweiter `git diff --check` in diesem Auftrag: Exit 0, keine Ausgabe. In älteren Berichten dokumentierte Whitespace-Altbefunde (DESIGN.md:162–164 sowie ältere Alltag-Zuhause-/Arbeit-Bildung-Berichte) sind davon getrennte historische Hinweise; keine pauschale Bereinigung vorgenommen. Eigene neue Dateien und NEXTSTEPS zusätzlich gezielt geprüft.

GitNexus-Index sieben Commits hinter Ausgangs-HEAD. Pre-Edit-Impact: NEXTSTEPS keine aufgelösten Caller/Prozesse, **UNKNOWN**; neuer Bericht, Asset und Fortsetzung nicht indexiert, **UNKNOWN**. Keine HIGH/CRITICAL-Warnung; UNKNOWN ist keine Freigabe. Quellen-/Literalprüfung sowie vollständige Inhalts-, Bestands- und App-Checks ergänzen die unvollständige Graphsicht. Kein Code-Symbol geändert. Rohbeleg `gitnexus-preflight.json`; Änderungsanalyse vor Commit separat dokumentiert.

Commitumfang ausschließlich neuer Bericht und drei neue Batch-4-Kontextdateien. NEXTSTEPS wegen vorbestehender Änderungen außerhalb des Commits; neue bytegleiche Liefer-Arbeitskopie ebenfalls lokal, Originaldaten bleiben erhalten. Pack/Assets/ZIP/Prüfbelege sind gemäß vorhandener Repository-Regeln gitignorierte lokale Artefakte; keine erzwungene Aufnahme und kein Push. Kein fremder Anteil oder historische Lieferung gestagt.

Nächster Schritt: **96 aktuelle Business-Batch-4-Ziele anhand der geprüften ZIP im Chat redigieren.** Alle erwähnten Altglossen/Labelbefunde, die ungeklärte Batch-2-Timeoutursache und die öffentliche Sprachfreigabe bleiben offen.

## Aktueller Pack-Lesetest: Laufzeitbefund bleibt offen

Erster bereits isolierter Lauf: Timeout nach 30 Sekunden, Exit 1, keine gemeldete Inhalts-Assertion. Quelldurchsicht bestätigt zwei vollständige Öffnungs-/Validierungsschritte im Installer; die Kartenprüfung führt einzelne Satzlinkabfragen je Karte aus. Das ist nur ein möglicher Laufzeitfaktor, keine bewiesene Ursache. GitNexus liefert dazu eine veraltete lower-bound-Sicht; der aktuelle Quelltext wurde direkt bestätigt. Rohbeleg: `timeout-investigation.json`.

Ein einzelner **unveränderter, ebenfalls isolierter Wiederholungslauf** besteht: `01:45 +1: All tests passed!`, Exit 0, 14 Stapel, 291 Business-Ziele, 3480 feste aktive Satzzuordnungen und 196 Zuordnungen mit Alternativen. Keine Testgrenze und keine Assertion geändert. Dieser Erfolg ist **keine Ursachenbehebung** und keine Zusage stabiler Laufzeit. Keine zusätzliche Wiederholung nach dem erfolgreichen Lauf.

## Abschließende Änderungsprüfung

`detect_changes({repo:"sprachlernapp",scope:"all"})`: fünf Dateien, vier indexierte NEXTSTEPS-Abschnitte, null betroffene Prozesse; gemeldetes Risiko low. `scope:"staged"`: vier neue Dateien, null indexierte Symbole/Prozesse. Keine partial-/truncated-Meldung. Null Symbole für neue Daten/Dokumente ist keine vollständige Graphabdeckung; die Grenzen und ergänzenden Inhaltsprüfungen bleiben maßgeblich. Rohbeleg `build/business_email_batch_3_checks/gitnexus-changes.json`.

```text
git diff --check -- NEXTSTEPS.md docs/business-email-batch-3-import.md pipeline/data/selection/business_email_batch_4_context_v1.json pipeline/data/words/en.business_email_batch_4_context_v1.json pipeline/data/learning_groups/en.business_email_batch_4_context_v1.json
[keine Ausgabe]
EXIT 0

git diff --cached --check
[keine Ausgabe]
EXIT 0

git status --short
 M NEXTSTEPS.md
A  docs/business-email-batch-3-import.md
A  pipeline/data/learning_groups/en.business_email_batch_4_context_v1.json
A  pipeline/data/selection/business_email_batch_4_context_v1.json
A  pipeline/data/words/en.business_email_batch_4_context_v1.json
[vorbestehende untracked Dateien unverändert; neue bytegleiche Arbeitskopie lokal]
EXIT 0
```

Vollständiger Status: `status-precommit.log`. Zusätzlicher direkter Whitespacecheck aller fünf eigenen Dateien: PASS, LF und abschließender Zeilenumbruch; NEXTSTEPS **25 Zeilen**. Abschließender Baseline-Abgleich nach Dokumentänderung: PASS; ausschließlich NEXTSTEPS, Asset und Manifest unter den 3006 Ausgangsdateien geändert (`final-audit-after-docs.log`).
