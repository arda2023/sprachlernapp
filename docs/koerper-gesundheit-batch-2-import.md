# Körper & Gesundheit: Batch 2 offline importiert

Stand: 10.10.2026. Genau 83 weitere Lernziele mit je einem festen Satzpaar wurden geprüft, importiert und intern gestagt. Körper & Gesundheit enthält nun 166 primäre Ziele; insgesamt sind es 1546 (160/489/241/245/245/166). Keine Batch-3-Karten oder -Sätze wurden erzeugt.

## Redaktionelle Entscheidungen

Alle 83 englisch-deutschen Satzpaare, 996 Tokenpositionen (905 Worttoken, 91 Satzzeichen) und beide Alternativen wurden gelesen und gegen die importierten Annotationen abgeglichen. Die tatsächlichen Token und Lesedokumente stimmen vollständig überein.

Geprüft: strain = Muskelzerrung; oral = Einnahme über den Mund; sharp = scharfes Messer; prevent = jemanden an einer Handlung hindern. long in how long ist Adverb; last unterscheidet dauern/letzter, before Präposition/Konjunktion, left bedeutet linke. holding beim Behälter bedeutet enthaltend, beim Telefon haltend; found bei bitter/salty bedeutet empfand. letter unterscheidet Buchstabe/Brief. Die vorhandene Bein-Bedeutung deckt auch Stuhlbein ab. finish ist Nomen in finish line; training sportliches Training; sleep Nomen; carefully vorsichtig. Die vorhandene possessive their-Bindung ist ausdrücklich passend definiert.

x-ray bleibt ein einzelnes Ziel über lexical_span; Lücke 46–51. ear liegt bei 51–54 und nicht innerhalb earring.

Die Alternativen wurden wörtlich eingesetzt:

- Maya took a short snooze on the sofa after lunch.
- The doctor showed Lina a model of the small bowel.

accepted bleibt ausschließlich nap beziehungsweise intestine. snooze und bowel sind nur satzbezogene, lernstandsneutrale Alternativen.

### Eine belegte Lieferkorrektur

Im Satz „The doctor said that Emma's blood pressure was normal today.“ verwies pressure (Tokenindex 7, Offset 34–42) ursprünglich auf pressure/NOUN|pressure#druck. Diese vorhandene Bedeutung bezeichnet ausdrücklich sozialen Druck auf eine Person und passt nicht zu Blutdruck.

Die separate Importkopie unter build/koerper_batch_2_checks/reviewed_delivery/ ergänzt ausschließlich den Wörterbuch-Sense pressure/NOUN|pressure#physikalischer-druck und eine zugehörige Wörterbuchform. Definition: „Kraft pro Fläche, die auf eine Oberfläche wirkt; bei Blutdruck der vom Blut auf die Gefäßwände ausgeübte Druck.“ Genau diese Tokenbindung wurde ersetzt; keine zusätzliche Lernkarte, kein neues Lemma, keine Änderung an Zielidentität, Satz oder Übersetzung. Die alte soziale Bedeutung samt Karte bleibt erhalten.

Der betroffene Reviewhash, create_sha256 im Display-Patch sowie die betroffenen Manifesthashes wurden aktualisiert. Vorher/Nachher stehen in local_corrections.json der Importkopie. Die Original-Lieferung bleibt bytegleich. Die mechanischen Prüfungen hatten den semantischen Fehler nicht erkannt; der erste, noch nicht gestagte Probeexport wurde separat unter build/koerper_batch_2_checks/pre_correction_export/ aufbewahrt und anschließend aus der korrigierten Kopie neu exportiert. Kein historischer Pack wurde überschrieben.

Die ursprünglichen Notizen behaupteten außerdem, ward#krankenhausstation und protein#eiweiss seien noch vorhanden. Tatsächlich enthält schon die Basis die korrigierten reservierten Schlüssel ward#krankenstation und protein#eiwei; die Lieferung verwendet sie korrekt. Nur die kopierten Notizen wurden klargestellt. steady#gleichmaessig bezeichnet zeitlichen Rhythmus und ist von der später reservierten Körperbedeutung steady#sicher-und-ruhig getrennt; der neue Eintrag bleibt ausschließlich Wörterbuchkontext.

## Import, Bestandsschutz und Staging

Basisrohbytes und 95 Liefermanifestdateien wurden geprüft; Registry/Gruppen wurden kanonisch geprüft. Ausschließlich aktuelle Projektwerkzeuge wurden ausgeführt, keine Referenzquellen zurückkopiert und keine Validatoren geändert.

Die 83 Mitgliedschaften wurden zunächst an 84–166 angehängt. Anschließend wurde der hashgebundene gelieferte Display-Patch angewendet: nur deck_cards.position und deck_words.position von Körper & Gesundheit wurden auf 1–166 umgeordnet. Originalpositionen in Auswahl und Registry bleiben erhalten.

Alle 1578 bisherigen Karten samt IDs, Satztexten, Annotationen, Lerngruppen, Besitz, Aliasen und Mitgliedschaften bleiben erhalten, abgesehen von dieser autorisierten Anzeigereihenfolge. Die drei Batch-1-Korrekturen (other bei kidney sowie ward/protein) bleiben erhalten. Alle 166 importierten Originalidentitäten, Definitionen, Lerngruppen und festen Sätze wurden exakt geprüft; keine künftige Kartenidentität wurde vorgezogen.

Der vollständige Abgleich aller 18 SQLite-Tabellen gegen build_rows bestand. Ergebnis: 1661 Karten, 2195 Satztexte, 2189 historische Satzverknüpfungen, 1557 Wortbesitzzeilen. Status internal/test; keine Kosten oder Modellaufrufe.

Vor Staging wurden Asset und Manifest bytegleich nach build/koerper_batch_2_checks/backup/assets/content/en/ gesichert. Aktualisiert wurden nur Asset, Manifest, die konkrete neue Versions-/Zählererwartung in test/data/real_pack_test.dart und NEXTSTEPS.md. Kein App-, Pipeline- oder SRS-Produktionscode wurde verändert. Flutter benötigte den vorhandenen SDK-Cache-Zugriff außerhalb des Repositorys.

## Neun Häufigkeitshinweise

Linter: 0 Fehler. Keine Umformulierung allein wegen der Häufigkeitsschwelle 3,5.

| Ziel | Begleitwort | Wert |
|---|---|---:|
| ear | earring | 3,08 |
| antibiotic | pharmacist | 3,34 |
| breathe | cot | 3,21 |
| capsule | pharmacist | 3,34 |
| jump | puddle | 3,26 |
| sniff | runny | 2,94 |
| protein | yoghurt | 3,01 |
| oral | pharmacist | 3,34 |
| insomnia | sleepless | 3,18 |

## Batch-3-Kontext

Der bestehende Fortsetzungs-Exporter erzeugte neue separate Snapshots koerper_gesundheit_batch_3_context_v1 in selection/, words/ und learning_groups/ aus dem tatsächlich geprüften neuen Pack. Alle 249 ursprünglichen Zielidentitäten samt Definitionen sind unverändert enthalten. Partition: 166 importiert / 83 aktuell / 0 später. Der nächste Import hängt 167–249 an und ordnet anschließend hashgebunden anhand der Originalauswahl auf 1–249 um.

Die ZIP umfasst 83 Dateien mit 82 Manifesthashes. Sie wurde geschlossen und sowohl im Stagingpfad als auch nach dem Verschieben am endgültigen Pfad neu geöffnet: CRCs, alle Hashes, Referenzen, Identitäten und sämtliche 18 SQLite-Tabellen bestanden. Vollständiger SQLite-Kontext: 1661 Karten. Keine Zugangsdaten oder Lernstände enthalten; keine neuen Batch-3-Sätze erstellt.

Absoluter ZIP-Pfad: /Users/ardasayar/Documents/FlutterProjekte/sprachapp/build/koerper_gesundheit_authoring_batch_3.zip

## Prüfungen und tatsächliche Ausgaben

Alle folgenden Protokolle liegen unter build/koerper_batch_2_checks/. Die Python-Prüfungen liefen auf macOS mit pipeline/.venv-macos/bin/python. Unter Windows PowerShell ist derselbe Aufruf mit .\pipeline\.venv\Scripts\python.exe auszuführen. Dart-, Flutter- und Git-Befehle sind auf beiden Systemen identisch. Die Importpfade beziehen sich auf die dokumentierte korrigierte Kopie.

Ausgeführte Python-Einstiegspunkte und Argumente:

```text
koerper_gesundheit_batch_2/verify_koerper_gesundheit_batch_2.py --repo .
build/koerper_batch_2_checks/reviewed_delivery/verify_koerper_gesundheit_batch_2.py --repo .
pipeline/scripts/import_editorial_patch.py --source pipeline/out/koerper_gesundheit_batch_1_v1/pack.json --create build/koerper_batch_2_checks/reviewed_delivery/koerper_gesundheit_batch_2.editorial.json --registry pipeline/data/words/en.koerper_gesundheit_batch_2_context_v1.json --display-patch build/koerper_batch_2_checks/reviewed_delivery/koerper_gesundheit_batch_2.display.json --out pipeline/out/koerper_gesundheit_batch_2_v1
build/koerper_batch_2_checks/audit_export.py
-m pytest pipeline/tests/test_editorial_import.py pipeline/tests/test_content_contract.py pipeline/tests/test_selection.py pipeline/tests/test_word_registry.py pipeline/tests/test_learning_groups.py pipeline/tests/test_authoring_context.py pipeline/tests/test_authoring_schema3.py pipeline/tests/test_authoring_continuation.py pipeline/tests/test_deck_display.py -q
pipeline/scripts/export_authoring_context.py --selection pipeline/data/selection/koerper_gesundheit_v1.json --batch 3 --prepare-continuation koerper_gesundheit_batch_3_context_v1
pipeline/scripts/export_authoring_context.py --selection pipeline/data/selection/koerper_gesundheit_batch_3_context_v1.json --batch 3 --out build/koerper_batch_2_checks/staging/koerper_gesundheit_authoring_batch_3.zip
pipeline/scripts/export_authoring_context.py --verify-zip build/koerper_batch_2_checks/staging/koerper_gesundheit_authoring_batch_3.zip
pipeline/scripts/export_authoring_context.py --verify-zip build/koerper_gesundheit_authoring_batch_3.zip
```

Staging und Flutter:

```text
dart run tool/stage_content_pack.dart --from pipeline/out/koerper_gesundheit_batch_2_v1
dart run tool/stage_content_pack.dart --verify
flutter test test/data/real_pack_test.dart
flutter analyze
```

### verifier-corrected.log

```text
PASS source/registry/groups/manifest hashes, Schema 3, context and base SQLite
PASS hash-bound display patch: append 84..166, final display 1..166; original registry positions preserved
PASS create_content/build_rows: 1661 cards; 1546 primary goals (160/489/241/245/245/166); 18 tables
PASS 83 reserved identities, display 1..166; 1578 old IDs and all historical rows preserved
PASS 996 token positions; two reviewed alternatives; linter 0 errors, 9 warnings
WARNINGS [["ear", "i+1", "'earring'/'earring' Zipf 3.08 below 3.5"], ["antibiotic", "i+1", "'pharmacist'/'pharmacist' Zipf 3.34 below 3.5"], ["breathe", "i+1", "'cot'/'cot' Zipf 3.21 below 3.5"], ["capsule", "i+1", "'pharmacist'/'pharmacist' Zipf 3.34 below 3.5"], ["jump", "i+1", "'puddle'/'puddle' Zipf 3.26 below 3.5"], ["sniff", "i+1", "'runny'/'runny' Zipf 2.94 below 3.5"], ["protein", "i+1", "'yoghurt'/'yoghurt' Zipf 3.01 below 3.5"], ["oral", "i+1", "'pharmacist'/'pharmacist' Zipf 3.34 below 3.5"], ["insomnia", "i+1", "'sleepless'/'sleepless' Zipf 3.18 below 3.5"]]
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
    "lemmas": 2773,
    "senses": 4127,
    "cards": 1661,
    "dictionary_forms": 4798,
    "decks": 6,
    "deck_cards": 1661,
    "deck_words": 1557,
    "word_aliases": 24,
    "sentences": 2195,
    "sentence_tokens": 24207,
    "card_sentences": 2189,
    "stories": 1,
    "story_sentences": 6,
    "exercises": 0,
    "grammar_rules": 0,
    "audio_assets": 0,
    "content_releases": 1
  },
  "sha256": "ed4c3b6896d02f20ab1dadaab5ebe478aee2fb95fc01ad16f92776185c308b7f"
}

Exit 0
```

### audit-export.log

```text
SQLITE_FULL_ROWS {'languages': 1, 'lemmas': 2773, 'senses': 4127, 'cards': 1661, 'dictionary_forms': 4798, 'decks': 6, 'deck_cards': 1661, 'deck_words': 1557, 'word_aliases': 24, 'sentences': 2195, 'sentence_tokens': 24207, 'card_sentences': 2189, 'stories': 1, 'story_sentences': 6, 'exercises': 0, 'grammar_rules': 0, 'audio_assets': 0, 'content_releases': 1}
PASS 166 original identities, definitions, learning groups, owners and fixed sentences; partition 166/83/0
PASS 1578 historical cards and all old content preserved, except authorized Körper display positions; all Batch-1 corrections retained
ALTERNATIVE Maya took a short snooze on the sofa after lunch.
ALTERNATIVE The doctor showed Lina a model of the small bowel.
PASS reviewed reading/annotation documents exactly match all 83 sentences and 996 imported token positions
DECK allgemeine-sprache 160
DECK reisen 489
DECK alltag-zuhause 241
DECK arbeit-bildung 245
DECK menschen-beziehungen 245
DECK koerper-gesundheit 166
PACK_SHA256 2d14e22abb6c3e89b5a6a3ac1fdec11312ec78bae5b9bce497b9e4061110f49c
SQLITE_SHA256 ed4c3b6896d02f20ab1dadaab5ebe478aee2fb95fc01ad16f92776185c308b7f
PASS future identities not introduced; ward/protein exact reserved senses ready for reuse; old reciprocal bindings unchanged
PASS exact target token and gap ear 51 54
PASS exact target token and gap x-ray 46 51
NEW_TOKEN_COUNTS 905 word tokens 91 punctuation
PASS blood pressure uses explicit physical sense; social-pressure sense/card preserved; no additional learning card

Exit 0
```

### pytest.log

```text
........................................................................ [ 58%]
...................................................   [100%]
123 passed, 19 subtests passed in 1.67s

Exit 0
```

### stage-verify.log

```text
Running build hooks...Running build hooks...verified assets/content/en/content.sqlite
  version koerper_gesundheit_batch_2_v1, schema 3, 11751424 bytes
  sha256 ed4c3b6896d02f20ab1dadaab5ebe478aee2fb95fc01ad16f92776185c308b7f
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
deck koerper-gesundheit: 166 learning targets, 166 ownership cards, 166 fixed sentence assignments verified
pack koerper_gesundheit_batch_2_v1 (schema 3, internal: true); 6 decks: 1557 cards, 1661 card sentences, 123 with valid_alternatives, 1661 cards in the pack
00:14 +1: All tests passed!

Exit 0
```

### flutter-analyze.log

```text
Analyzing sprachapp...
No issues found! (ran in 2.8s)

Exit 0
```

### verify-batch-3-final.log

```text
{
  "zip_verification": "PASS",
  "zip_sha256": "ae0049833f6bfa4040983ae3cd531580346fed2792bd52f7f5064dd95e3c36de",
  "hashed_files": 82,
  "sqlite_tables": 18,
  "sqlite_cards": 1661,
  "credentials_and_learning_states": "none; explicit content/source/model whitelist",
  "status": "PASS",
  "selected": 249,
  "excluded": 178,
  "partition_counts": {
    "imported": 166,
    "current": 83,
    "future": 0
  },
  "reused_proposed_senses": 3,
  "batches": {
    "1": 83,
    "2": 83,
    "3": 83
  },
  "topics_per_batch": {
    "1": {
      "Bewegung und körperliche Fähigkeiten": 11,
      "Sinne und körperliche Wahrnehmung": 10,
      "Beschwerden und häufige Erkrankungen": 10,
      "Arztbesuch und Untersuchung": 10,
      "Schlaf, Erholung und Wohlbefinden": 8,
      "Verletzungen, Erste Hilfe und Hilfsmittel": 8,
      "Körperteile und Organe": 17,
      "Behandlung, Pflege und Genesung": 9
    },
    "2": {
      "Beschwerden und häufige Erkrankungen": 11,
      "Behandlung, Pflege und Genesung": 9,
      "Sinne und körperliche Wahrnehmung": 11,
      "Bewegung und körperliche Fähigkeiten": 10,
      "Schlaf, Erholung und Wohlbefinden": 9,
      "Arztbesuch und Untersuchung": 9,
      "Verletzungen, Erste Hilfe und Hilfsmittel": 8,
      "Körperteile und Organe": 16
    },
    "3": {
      "Sinne und körperliche Wahrnehmung": 11,
      "Bewegung und körperliche Fähigkeiten": 10,
      "Arztbesuch und Untersuchung": 10,
      "Behandlung, Pflege und Genesung": 9,
      "Beschwerden und häufige Erkrankungen": 10,
      "Schlaf, Erholung und Wohlbefinden": 8,
      "Verletzungen, Erste Hilfe und Hilfsmittel": 9,
      "Körperteile und Organe": 16
    }
  },
  "existing_senses": 42,
  "new_senses": 207,
  "existing_cards": 1661,
  "existing_groups": 1649,
  "new_groups": 83,
  "registry_words": 1640,
  "partition_selection": "PASS: 166 present",
  "validate_selection": "PASS: parent and exact reservations",
  "index_registry": "PASS",
  "validate_learning": "PASS: existing and planned",
  "build_rows": "PASS: reservation-only rows unchanged",
  "semantic_review": "explicit editorial decisions, no automatic equivalence inference"
}

Exit 0
```

## SHA256 der geprüften Dateien

| Datei | SHA256 |
|---|---|
| pipeline/out/koerper_gesundheit_batch_1_v1/pack.json | `da7a6890241f4ae6db2ca225d7eb8c2a3fe4cbfbdd40ef17a697dce47dd7d9b3` |
| pipeline/out/koerper_gesundheit_batch_1_v1/content.sqlite | `42dc059df3425b80eda702339de079aacd0fbc5c543c52626a547c74c05f7182` |
| koerper_gesundheit_batch_2/koerper_gesundheit_batch_2.editorial.json | `691632160edde04da5f6bf66dac06cf2041076f750476f29a78b4548a6032cc9` |
| koerper_gesundheit_batch_2/koerper_gesundheit_batch_2.display.json | `e0b28d0292318e8e7e7ca1e621e4827e2f4e46fbf9163064d4ea00e3775dd9a4` |
| build/koerper_batch_2_checks/reviewed_delivery/koerper_gesundheit_batch_2.editorial.json | `8a43a5c78203773a8975937a1269a37eea3c6ea9d2967673da0ddb0aa50ad74b` |
| build/koerper_batch_2_checks/reviewed_delivery/koerper_gesundheit_batch_2.display.json | `fc0cc9e79851acf63603f02758ad78984b127327aa453ca64eec85924e3ba5fe` |
| pipeline/out/koerper_gesundheit_batch_2_v1/pack.json | `2d14e22abb6c3e89b5a6a3ac1fdec11312ec78bae5b9bce497b9e4061110f49c` |
| pipeline/out/koerper_gesundheit_batch_2_v1/content.sqlite | `ed4c3b6896d02f20ab1dadaab5ebe478aee2fb95fc01ad16f92776185c308b7f` |
| assets/content/en/content.sqlite | `ed4c3b6896d02f20ab1dadaab5ebe478aee2fb95fc01ad16f92776185c308b7f` |
| assets/content/en/content.manifest.json | `07b5f2da5b2fd3aab129761d8f8905e7c0d0db7492ca7e4d1b1a0e852b1ab08a` |
| build/koerper_gesundheit_authoring_batch_3.zip | `ae0049833f6bfa4040983ae3cd531580346fed2792bd52f7f5064dd95e3c36de` |
| pipeline/data/selection/koerper_gesundheit_batch_3_context_v1.json | `cdf74b497e41b3e47f3bf4f6649492d55f0563968fb24d39ba76fd4ce81a81c9` |
| pipeline/data/words/en.koerper_gesundheit_batch_3_context_v1.json | `dfea18cd93a72a484f0d7ebca3d501f7880e99e4ddddf1cbc32931bab4f9493b` |
| pipeline/data/learning_groups/en.koerper_gesundheit_batch_3_context_v1.json | `fd6cf73f4dcf1bed8ad22f5c09b7c4ae11451d80faa98f5182dd50ecbd33fdd9` |

## Arbeitsbaum und Grenzen

Der Arbeitsbaum war bereits umfangreich verändert. Der abschließende Bytevergleich dokumentiert 2021 von 2025 Ausgangsdateien unverändert; die vier oben genannten Änderungen sind beauftragt. Details und Hashes: build/koerper_batch_2_checks/final-protection.json. Original-Lieferung, historische Packs, ursprüngliche Auswahl und alte Kontextdateien bleiben bytegleich.

git diff --check meldet Exit 2 aufgrund vorhandener CRLF-/Whitespace-Befunde. Mit core.whitespace=cr-at-eol verbleiben sieben alte Befunde: DESIGN.md:162–164; docs/alltag-zuhause-continuation.md:148,153; docs/arbeit-bildung-batch-1-import.md:127; docs/arbeit-bildung-batch-2-import.md:121. Keine globale Bereinigung. Die eigenen Änderungen werden separat gegen den Ausgangsstand ohne Whitespace-Befund geprüft (Wrapper Exit 0); git status --short liefert Exit 0. Rohprotokolle sind wegen ihres Umfangs gzip-komprimiert, Status vorher/nachher separat gespeichert.

Keine echte user.db oder review_log geöffnet, keine Geräteprüfung, Cloud-/Modellaufrufe, Supabase-Änderungen, Veröffentlichung, Commits oder Pushes. Offen bleiben die Redaktion der letzten 83 Ziele, die bekannten sieben Whitespace-Altbefunde und eine Geräteprüfung; keine ungeklärte Inhaltsbindung dieses Imports.
