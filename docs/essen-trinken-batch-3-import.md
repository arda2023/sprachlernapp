# Essen & Trinken: Abschluss Batch 3

Stand: 10.10.2026. Alle 250/250 Originalziele offline importiert und intern gestagt. Genau 83 neue Ziele und feste Satzpaare ergänzen den Bestand. Insgesamt 1879 primäre Lernziele in sieben Stapeln: 160/489/241/245/245/249/250. Partition 250 importiert / 0 aktuell / 0 später; kein Restbatch und keine Batch-4-ZIP. Keine öffentliche Inhaltsfreigabe.

## Redaktionelle Prüfung und Entscheidungen

Alle 83 englisch-deutschen Satzpaare, 948 Tokenpositionen (863 Worttoken, 85 Satzzeichen), neuen Sense-Definitionen und Wörterbuchformen gegengelesen. reading.json und annotation_review.txt stimmen exakt mit dem Import überein. Kein belegter Lieferfehler: Originalbytes unverändert importiert; keine Korrekturkopie oder allgemeine Glossenbereinigung.

Besonders geprüft: diner Essensgast statt Restaurant; mince Hackfleisch, season würzen, core entkernen. tin Konservendose einschließlich beider erhaltener Batch-1-Korrekturen. yolk/white Eiweiß als Nomen, buttermilk/sip Schluck als Nomen und took nahm. lamb/duck/gravy roast Adjektiv; mixer/beat aufschlagen. maize/grows anbauen; cranberry/found empfinden/beurteilen; tasted probierte. brew/pot Kanne gegenüber tin/pot Kochtopf; peeler/skin Gemüseschale. diner/more Mengenbestimmung; savoury/one Stellvertreter und of Teil von instead of. smoky/goes well with passt zu; tender/so derart und could konnte. container/tight fest sitzender Deckel; shell Hülle und kernel Nusskern. well-done ist exakt ein vollständiges Token und eine Lücke einschließlich Bindestrich.

Zwei Alternativen wörtlich eingesetzt und geprüft:

- Rosa chose a savory pancake with cheese instead of a sweet one.
- Omar opened a can of beans and poured them into the pot.

accepted enthält ausschließlich savoury beziehungsweise tin. Alternativen bleiben satzbezogen und lernstandsneutral; Besitzaliase sind keine automatische Antwortfreigabe.

Linter: 0 Fehler, 15 neue Häufigkeitshinweise. Keine Umformulierung allein deshalb. Betroffen: feta/cucumber 3.41, latte/oat 2.90, nutmeg/grated 3.17 und creamy 3.43, texture/blender 3.43, poach/simmering 3.27, stale/breadcrumbs 2.75, savoury/pancake 3.35, saucer/teaspoon 3.30, muffin/blueberry 3.30, flip/spatula 2.86 und pancake 3.35, straw/milkshake 3.03, batter/pancake 3.35, core/raisins 3.14.

## Bestandsschutz und Abschlussabgleich

Basis-JSON und SQLite entsprechen den beauftragten Rohbytehashes. Liefer-/Review-/Display-/Referenzmanifest sowie kanonische Registry-/Gruppenbindungen bestanden mit aktuellen Projektquellen. Keine Referenzquellen zurückkopiert.

Neue Mitgliedschaften zunächst 168–250, anschließend ausschließlich mitgelieferter hashgebundener Display-Patch auf Essen-Positionen 1–250. Originalauswahl, Registrypositionen und alte Snapshots unverändert. Alle 1911 bisherigen Karten, Satztexte, Annotationen, Lerngruppen und historischen Verknüpfungen bleiben erhalten; allein autorisierte Essen-Anzeigepositionen ändern sich.

Alle 250 Originalidentitäten vollständig mit Karten, Lemma-/Sense-IDs, Definitionen, cards.learning, Besitz, Aliaslisten und genau einem aktiven festen Satz abgeglichen. Finale Anzeige entspricht jeder Originalposition. partition_selection bestätigt alle 250 vorhanden, keine fehlend. Die Differenz zur Basis enthält exakt die letzten 83 Karten; keine weiteren Lernkarten für neue Begleitwörter.

Alle 18 SQLite-Tabellen vollständig gegen build_rows des tatsächlichen JSON-Exports geprüft: 1994 Karten, 2528 Satztexte, 2522 Satzverknüpfungen einschließlich Historie, 1890 Wortbesitzzeilen. Exportstatus ok, internal_test_pack true, ai_calls 0 und Kosten 0.

Der erste zusätzliche Audit verwendete fälschlich ein eingebettetes aliases-Feld in deck_words. Das Schema speichert Aliase separat in word_aliases. Der Audit wurde auf diese tatsächlichen Zeilen korrigiert und bestand anschließend vollständig; keine Inhaltsänderung oder Validatorlockerung. Erstversuch unter audit-first-attempt.log erhalten.

## Sicherung vor Staging und App-Prüfung

Vor Staging wurden bestehendes Asset und Manifest nach build/essen_batch_3_checks/backup/assets/content/en/ kopiert und gegen die Ausgangsbaseline hashgeprüft. backup-proof.json enthält Zeitstempel und beide Hashes. Erst nach erfolgreichem Audit, grünen Tests und separatem Vorbereitungsschritt mit Exit 0 wurde das Staging gestartet.

Im real_pack_test ausschließlich einen konkreten Versionsblock für essen_trinken_batch_3_v1 ergänzt. Asset-Verifikation, Siebenstapel-Lesetest und Flutter-Analyse bestanden. Keine App-Einstiege oder echten user.db/review_log geöffnet. Flutter verwendete seinen vorhandenen SDK-Cache außerhalb des Repositorys.

## Befehle und tatsächliche Outputs

Ab Repository-Root. PYTHON auf macOS Terminal: pipeline/.venv-macos/bin/python. Windows PowerShell: .\pipeline\.venv\Scripts\python.exe. Dart-/Flutter-/Git-Befehle sind auf beiden Systemen identisch.

```text
PYTHON essen_trinken_batch_3/verify_essen_trinken_batch_3.py --repo .
PYTHON pipeline/scripts/import_editorial_patch.py --source pipeline/out/essen_trinken_batch_2_v1/pack.json --create essen_trinken_batch_3/essen_trinken_batch_3.editorial.json --registry pipeline/data/words/en.essen_trinken_batch_3_context_v1.json --display-patch essen_trinken_batch_3/essen_trinken_batch_3.display.json --out pipeline/out/essen_trinken_batch_3_v1
PYTHON build/essen_batch_3_checks/audit_export.py
PYTHON -m pytest pipeline/tests/test_editorial_import.py pipeline/tests/test_content_contract.py pipeline/tests/test_selection.py pipeline/tests/test_word_registry.py pipeline/tests/test_learning_groups.py pipeline/tests/test_authoring_context.py pipeline/tests/test_authoring_schema3.py pipeline/tests/test_authoring_continuation.py pipeline/tests/test_deck_display.py -q
PYTHON build/essen_batch_3_checks/prepare_stage.py
dart run tool/stage_content_pack.dart --from pipeline/out/essen_trinken_batch_3_v1
dart run tool/stage_content_pack.dart --verify
flutter test test/data/real_pack_test.dart
flutter analyze
git diff --check
git status --short
```

### verifier.log

```text
PASS source/registry/groups/manifest hashes, Schema 3, context and base SQLite
PASS hash-bound display patch: append 168..250, final display 1..250; original registry positions preserved
PASS create_content/build_rows: 1994 cards; 1879 primary goals (160/489/241/245/245/249/250); 18 tables
PASS 83 reserved identities, display 1..250; 1911 old IDs and all historical rows preserved
PASS 948 token positions; two reviewed alternatives; linter 0 errors, 15 warnings
WARNINGS [["feta", "i+1", "'cucumber'/'cucumber' Zipf 3.41 below 3.5"], ["latte", "i+1", "'oat'/'oat' Zipf 2.90 below 3.5"], ["nutmeg", "i+1", "'grate'/'grated' Zipf 3.17 below 3.5"], ["nutmeg", "i+1", "'creamy'/'creamy' Zipf 3.43 below 3.5"], ["texture", "i+1", "'blender'/'blender' Zipf 3.43 below 3.5"], ["poach", "i+1", "'simmer'/'simmering' Zipf 3.27 below 3.5"], ["stale", "i+1", "'breadcrumb'/'breadcrumbs' Zipf 2.75 below 3.5"], ["savoury", "i+1", "'pancake'/'pancake' Zipf 3.35 below 3.5"], ["saucer", "i+1", "'teaspoon'/'teaspoon' Zipf 3.30 below 3.5"], ["muffin", "i+1", "'blueberry'/'blueberry' Zipf 3.30 below 3.5"], ["flip", "i+1", "'spatula'/'spatula' Zipf 2.86 below 3.5"], ["flip", "i+1", "'pancake'/'pancake' Zipf 3.35 below 3.5"], ["straw", "i+1", "'milkshake'/'milkshake' Zipf 3.03 below 3.5"], ["batter", "i+1", "'pancake'/'pancake' Zipf 3.35 below 3.5"], ["core", "i+1", "'raisin'/'raisins' Zipf 3.14 below 3.5"]]
NOT RUN: App staging, Flutter/device tests, user database access

Exit 0
```

### import.log

```text
{
  "status": "ok",
  "internal_test_pack": true,
  "ai_calls": 0,
  "ai_cost_usd": 0,
  "sqlite_counts": {
    "languages": 1,
    "lemmas": 3160,
    "senses": 4571,
    "cards": 1994,
    "dictionary_forms": 5338,
    "decks": 7,
    "deck_cards": 1994,
    "deck_words": 1890,
    "word_aliases": 35,
    "sentences": 2528,
    "sentence_tokens": 28128,
    "card_sentences": 2522,
    "stories": 1,
    "story_sentences": 6,
    "exercises": 0,
    "grammar_rules": 0,
    "audio_assets": 0,
    "content_releases": 1
  },
  "sha256": "cffc9e4529ada7f61e0bbf7e2e1e7d7d0926f68957b616f2497e38234405d2ce"
}

Exit 0
```

### audit.log

```text
SQLITE_FULL_ROWS {'languages': 1, 'lemmas': 3160, 'senses': 4571, 'cards': 1994, 'dictionary_forms': 5338, 'decks': 7, 'deck_cards': 1994, 'deck_words': 1890, 'word_aliases': 35, 'sentences': 2528, 'sentence_tokens': 28128, 'card_sentences': 2522, 'stories': 1, 'story_sentences': 6, 'exercises': 0, 'grammar_rules': 0, 'audio_assets': 0, 'content_releases': 1}
PASS 250 original identities, definitions, learning groups, owners and fixed sentences; partition 250/0/0
PASS 1911 historical cards and all old content preserved, except authorized Essen display positions; all Batch-1 corrections retained
ALTERNATIVE Rosa chose a savory pancake with cheese instead of a sweet one.
ALTERNATIVE Omar opened a can of beans and poured them into the pot.
PASS reviewed reading/annotation documents exactly match all 83 sentences and 948 imported token positions
DECK allgemeine-sprache 160
DECK reisen 489
DECK alltag-zuhause 241
DECK arbeit-bildung 245
DECK menschen-beziehungen 245
DECK koerper-gesundheit 249
DECK essen-trinken 250
PACK_SHA256 0a7a73b424f1625f71a2af892ff2a610f6103aef263d210bdcc3fc528d0ce521
SQLITE_SHA256 cffc9e4529ada7f61e0bbf7e2e1e7d7d0926f68957b616f2497e38234405d2ce
PASS 250/0/0 partition; all original ownership aliases and positions exact; no extra cards; both old tin corrections preserved; exact well-done token/gap
NEW_TOKEN_COUNTS 863 word tokens 85 punctuation

Exit 0
```

### pytest.log

```text
........................................................................ [ 58%]
...................................................   [100%]
123 passed, 19 subtests passed in 0.91s

Exit 0
```

### prepare-stage.log

```text
PASS backup BEFORE staging: {"verified_before_staging_utc": "2026-10-10T12:12:28.727803+00:00", "files": {"assets/content/en/content.sqlite": "d785cfb50faed8fe66227efad8b4c0a7e6e9ba41d486988f18aae0531a96684e", "assets/content/en/content.manifest.json": "90b28e6d45d2737635d9f7f1ab0952b36136bd8e5e5bd0179693e370266aa2d4"}}
PASS exact seven-deck test expectations added; existing bytes preserved

Exit 0
```

### stage.log

```text
Running build hooks...Running build hooks...staged assets/content/en/content.sqlite
  version essen_trinken_batch_3_v1, schema 3, 13680640 bytes
  sha256 cffc9e4529ada7f61e0bbf7e2e1e7d7d0926f68957b616f2497e38234405d2ce
  18 table counts match finalization_report.json
  INTERNES TEST-PACK: own devices and selected testers only, no public content release

Exit 0
```

### stage-verify.log

```text
Running build hooks...Running build hooks...verified assets/content/en/content.sqlite
  version essen_trinken_batch_3_v1, schema 3, 13680640 bytes
  sha256 cffc9e4529ada7f61e0bbf7e2e1e7d7d0926f68957b616f2497e38234405d2ce
  18 table counts match finalization_report.json
  INTERNES TEST-PACK: own devices and selected testers only, no public content release

Exit 0
```

### flutter-test.log

```text
00:00 +0: loading /Users/ardasayar/Documents/FlutterProjekte/sprachapp/test/data/real_pack_test.dart
00:00 +0: staged pack: all cards and sentence links readable, read-only
deck allgemeine-sprache: 160 learning targets, 160 ownership cards, 160 fixed sentence assignments verified
deck reisen: 489 learning targets, 500 ownership cards, 500 fixed sentence assignments verified
deck alltag-zuhause: 241 learning targets, 241 ownership cards, 241 fixed sentence assignments verified
deck arbeit-bildung: 245 learning targets, 245 ownership cards, 245 fixed sentence assignments verified
deck menschen-beziehungen: 245 learning targets, 245 ownership cards, 245 fixed sentence assignments verified
deck koerper-gesundheit: 249 learning targets, 249 ownership cards, 249 fixed sentence assignments verified
deck essen-trinken: 250 learning targets, 250 ownership cards, 250 fixed sentence assignments verified
pack essen_trinken_batch_3_v1 (schema 3, internal: true); 7 decks: 1890 cards, 1994 card sentences, 135 with valid_alternatives, 1994 cards in the pack
00:10 +1: All tests passed!

Exit 0
```

### flutter-analyze.log

```text
Analyzing sprachapp...
No issues found! (ran in 2.0s)

Exit 0
```

## SHA256 (Rohbytes)

| Datei | SHA256 |
|---|---|
| pipeline/out/essen_trinken_batch_2_v1/pack.json | `ea3e5521b179a5b412ceefdbc80a71a739becf513b1c3edb04c565715d006adc` |
| pipeline/out/essen_trinken_batch_2_v1/content.sqlite | `d785cfb50faed8fe66227efad8b4c0a7e6e9ba41d486988f18aae0531a96684e` |
| essen_trinken_batch_3/essen_trinken_batch_3.editorial.json | `e420e25c931cf8e1bb18759325973ca90c7d049b15a512854dfdc0c7cb950078` |
| essen_trinken_batch_3/essen_trinken_batch_3.display.json | `1bcabab134eba9fbba7a786bde5b7c8137f2adde040b9f94769a6c1c9c660d22` |
| essen_trinken_batch_3/manifest.json | `5889296da3087e752f46ac2b00699e5aeaf6984fd9260d5d558c68e46a481b48` |
| pipeline/out/essen_trinken_batch_3_v1/pack.json | `0a7a73b424f1625f71a2af892ff2a610f6103aef263d210bdcc3fc528d0ce521` |
| pipeline/out/essen_trinken_batch_3_v1/content.sqlite | `cffc9e4529ada7f61e0bbf7e2e1e7d7d0926f68957b616f2497e38234405d2ce` |
| assets/content/en/content.sqlite | `cffc9e4529ada7f61e0bbf7e2e1e7d7d0926f68957b616f2497e38234405d2ce` |
| assets/content/en/content.manifest.json | `3edb2db9a0a549521956ebf2f8ff9014574b46b95f04e5be39a48e9091436248` |
| pipeline/data/selection/essen_trinken_v1.json | `80dfefb693085faff9776d5b9efabe4a65709d53a2d9e9b574e0c93cf9e7d239` |
| pipeline/data/selection/essen_trinken_batch_3_context_v1.json | `5542ba3b73d533938cde2c52cebe84c8eaa787f7005ee897e49709ee35a2db53` |
| pipeline/data/words/en.essen_trinken_batch_3_context_v1.json | `3066fa03d197135855ed1d7aa2a61e6dcd3991ebd626f3a3cfd698c6ec8bb07f` |
| pipeline/data/learning_groups/en.essen_trinken_batch_3_context_v1.json | `a36ff7d622afcc428fbc36cd4877aff680cf9cb7ebc3e8413c40231147d73dbe` |

## Arbeitsbaum und Grenzen

Baseline: 2436 vorhandene Dateien. Erlaubte Änderungen: Asset/Manifest, konkrete real_pack_test-Erwartung, docs/essen-trinken-authoring.md und NEXTSTEPS.md. Neu: Pack-Ausgabe und dieser Bericht; Prüfprotokolle und Sicherung unter build/essen_batch_3_checks/. Original-Lieferung, historische Packs, Originalauswahl, alte Registrys und Gruppen bleiben bytegleich. final-protection.json und Git-Status vor/nachher dokumentieren den Schlussvergleich.

Bekannte sieben Whitespace-Altstellen: DESIGN.md:162–164, docs/alltag-zuhause-continuation.md:148/153, docs/arbeit-bildung-batch-1-import.md:127, docs/arbeit-bildung-batch-2-import.md:121. Keine globale Bereinigung; eigene Änderungen gesondert prüfen. Umfangreiche Rohoutputs gzip-komprimiert.

Keine echte user.db/review_log oder Lernstände verändert, keine App-/SRS-/Synonym-/Modell-/Budget-/Supabase-/Plattformänderung, Cloud-/Modellaufrufe, Veröffentlichung, Commits oder Pushes. Keine Geräteprüfung und keine unabhängige menschliche Sprachfreigabe behauptet. Bekannte Altbefunde bleiben eigene Aufgaben. Essen-Authoring abgeschlossen, kein Restbatch.

## Abschließender Arbeitsbaumvergleich

```text
BASELINE 2436 UNCHANGED 2431 CHANGED ['NEXTSTEPS.md', 'assets/content/en/content.manifest.json', 'assets/content/en/content.sqlite', 'docs/essen-trinken-authoring.md', 'test/data/real_pack_test.dart']
git-diff-check Exit 2 bytes 322643448 lines 6399216
git-diff-check-crlf Exit 2 bytes 717 lines 14
DESIGN.md:162: trailing whitespace.
+**Display/Headline Font:** Source Serif 4 (serif fallback)
DESIGN.md:163: trailing whitespace.
+**Body Font (stories/sentences):** Source Serif 4
DESIGN.md:164: trailing whitespace.
+**UI/Label Font (chrome/navigation/stats):** Figtree (sans-serif fallback)
docs/alltag-zuhause-continuation.md:148: trailing whitespace.
+Author:
docs/alltag-zuhause-continuation.md:153: trailing whitespace.
+Required-by:
docs/arbeit-bildung-batch-1-import.md:127: trailing whitespace.
+Analyzing sprachapp...
docs/arbeit-bildung-batch-2-import.md:121: trailing whitespace.
+Analyzing sprachapp...
git status --short Exit 0
PASS own whitespace checks (wrapper Exit 0)
PASS original delivery, historical packs, original selections/registries/groups and app/pipeline code unchanged

Exit 0
```

2431 von 2436 Ausgangsdateien unverändert; ausschließlich die fünf beauftragten Bestandsdateien verändert. Eigene Whitespace-Prüfung bestanden, git diff --check wegen dokumentierter Altbefunde Exit 2.
