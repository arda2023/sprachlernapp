# Natur & Umwelt: Batch 2 offline importiert

Stand: 10.10.2026. Genau 81 weitere Ziele mit je einem aktiven festen Satz offline importiert und intern gestagt. Jetzt 162 Natur-Ziele und insgesamt 2041 primäre Lernziele in acht Stapeln: 160/489/241/245/245/249/250/162. Roadmap mit genau 14 Stapeln beibehalten; keine weitere Kategorie oder Verbenauswahl vorbereitet.

## Redaktionelle Prüfung

Alle 81 englisch-deutschen Satzpaare, 939 Tokenpositionen (853 Worttoken, 86 Satzzeichen), 116 neuen Sensezeilen und 147 neuen Formglossen gegengelesen. Lesedokument und korrigiertes Annotationsdokument wurden vollständig gegen den tatsächlichen Import abgeglichen. Keine Alternativen freigegeben; accepted enthält ausschließlich die Zielform. Das ist keine Behauptung sprachlicher Eindeutigkeit. Aliase und Lerngruppenmitglieder erlauben keine automatische Antwortfreigabe.

Geprüfte Kontextbindungen: energy physikalische Energie, in efficiency/geothermal passend zur allgemeinen physikalischen Definition aus Batch 1; persönliche Energie bleibt getrennt. Räumliches on auf, alle fünf Batch-1-Korrekturen einschließlich horizon/on#am und solar/energy erhalten. sap/cut Nomen Schnittstelle, coral/living Adjektiv lebend. pollen/after nachdem; sawdust/after vor cutting bestehende Konjunktion für die -ing-Form. weed/filter out of räumlich heraus/aus, nicht Mengen-of. rock/from Schutz vor, dew/from Ursache; sonst räumliche Herkunft. mine Bergwerk, pass Gebirgspass, bed Beet, treat beim Hund Leckerli gegenüber wastewater/treats Aufbereitung. veins Gesteinsmaserung, fibres Textilfasern und gases gasförmige Stoffe statt Brenngas. hail/hard Adverb heftig, most Determinierer die meisten, pine/kept behielt. lawn/left liegen lassen, flood/left hinterlassen, wing/left links. noise/keep out fernhalten, kein neues Mehrwortziel. Bestehende camp/fly-Bedeutungen verwendet; keine entsprechenden Begleitwort-Dubletten. drinking water nominale Zweckangabe Trinken; fossil/of und signs of decay Zugehörigkeit/Bezug. eco-friendly ist einschließlich Bindestrich ein vollständiges Zieltoken mit exakter Lücke.

## Eine belegte Lieferkorrektur

Die Original-Lieferung bleibt bytegleich. In der separaten Importkopie build/natur_batch_2_checks/reviewed_delivery/ wurde genau ein Token geändert:

- Satz: Most deciduous trees lose their leaves in autumn.
- Vorher: in/ADP|in#in_raeumlich, Glosse ausdrücklich „innerhalb eines Ortes oder Raumes“.
- Nachher: vorhandenes in/ADP|in#in_zeitlich, zeitlicher Zeitraum.

Keine neue Bedeutung, Wörterbuchform, Zielkarte oder Lerngruppe nötig. Ein Review-tokens_sha256, create_sha256 des Display-Patches und die betroffenen Kopie-Manifesthashes erneuert; Annotationstext und lokale Notiz angepasst. local_corrections.json enthält vollständige Token-/Review-Vorher-Nachher-Werte und die ursprüngliche/neue Display-Create-Bindung. Satztext, Übersetzung, Zielidentitäten, Gruppen, Lücken, akzeptierte Formen und Displayzeilen unverändert. Keine pauschale Altglossenbereinigung oder Zeilenendennormalisierung. Lieferinterne Audits bleiben historische Zulieferungsnachweise; aktueller Projekt-Audit unten. Originaler und korrigierter Lieferverifier bestanden; die mechanische Prüfung allein beurteilt die zeitliche Bedeutung nicht.

## Bestandsschutz, Display und Export

Basis-JSON und SQLite rohbytegenau gegen beauftragte Hashes, Basis gleich zum Ausgangsasset. Registry/Gruppen kanonisch, Liefer-/Referenz-/Review-/Display-/Manifesthashes gültig. Aktuelle Projektquellen verwendet, keine Referenzquellen zurückkopiert und kein Validator gelockert.

Genau 81 aktuelle Karten importiert, kein neuer Stapel. Zunächst Natur-Mitgliedschaften 82–162 angehängt, danach mitgelieferter hashgebundener Display-Patch auf 1–162 angewendet. Nur Natur-deck_cards.position und Natur-deck_words.position ändern sich im alten Bestand. Originalpositionen in Auswahl/Registry erhalten; keine eigene Sortierlogik.

Alle 162 importierten Originalidentitäten, Definitionen, cards.learning, Besitzer/Aliase und je ein aktiver fester Satz exakt geprüft. Alle 2075 alten Karten-IDs und historischen Zeilen erhalten, einschließlich der fünf Natur-Batch-1-Korrekturen sowie sämtlicher früherer Tokenkorrekturen. 80 spätere Karten abwesend; bereits eingeführte Begleitwort-Senses entsprechen exakt ihren späteren Reservierungen und bleiben reine Wörterbucheinträge.

Alle 18 SQLite-Tabellen vollständig gegen build_rows des tatsächlichen JSON-Exports verglichen: 2156 Karten, 2690 Satztexte, 2684 historische Satzverknüpfungen und 2052 Wortbesitzzeilen. Tatsächlicher Export: 3377 Lemmas, 4829 Senses, 5656 Wörterbuchformen. Exportstatus ok, internal_test_pack true, ai_calls 0 und Kosten 0.

Linter: 0 Fehler, vier Häufigkeitshinweise: flock/geese 3.35, avalanche/snowfall 3.22, meadow/grazing 3.49, dolphin/swam 3.34. Keine Umformulierung allein deswegen.

## Nachgewiesene Sicherung und internes Staging

Bestehendes Asset und Manifest vor Staging nach build/natur_batch_2_checks/backup/assets/content/en/ kopiert und beide Hashes gegen die Ausgangsbaseline bestätigt. backup-proof.json enthält den Zeitpunkt und Hashes. Erst nach grünen Tests, erfolgreichem SQLite-Audit und dem separaten erfolgreichen Vorbereitungsschritt mit Exit 0 wurde gestagt.

real_pack_test erhielt ausschließlich einen konkreten Versionsblock für natur_umwelt_batch_2_v1 mit acht Stapeln und den erwarteten Zählern. Asset-Verifikation, Achtstapel-Lesetest, 123 Pipeline-Tests plus 19 Untertests und Flutter-Analyse bestanden. Vorhandener SDK-Cache außerhalb des Repositorys verwendet; keine Projektplattformdateien geändert. Kein App-Einstieg oder echte user.db/review_log geöffnet.

## Batch 3 für die letzten 80 Ziele

Mit dem vorhandenen Fortsetzungs-Exporter aus dem tatsächlich geprüften neuen Pack erzeugt:

- pipeline/data/selection/natur_umwelt_batch_3_context_v1.json
- pipeline/data/words/en.natur_umwelt_batch_3_context_v1.json
- pipeline/data/learning_groups/en.natur_umwelt_batch_3_context_v1.json

Alte Dateien unverändert. Vollständiger Kontext aller 242 Originalziele, Partition 162 importiert / 80 aktuell / 0 später. Nächster Import hängt 163–242 an und ordnet ausschließlich Natur-Anzeigen anhand der Originalauswahl hashgebunden auf 1–242 um. Keine Batch-3-Sätze erzeugt.

ZIP mit 83 Dateien und 82 Manifesthashes geschlossen und erneut geöffnet: CRCs, sämtliche Hashes, Referenzen, vollständige Identitäten/Partition, Besitz/Aliase/Gruppen und alle 18 SQLite-Tabellen geprüft. Enthaltenes JSON und SQLite bytegleich zum tatsächlich geprüften neuen Pack. Danach ohne Überschreiben an den Endpfad verschoben und dort nochmals vollständig geprüft.

Absoluter ZIP-Pfad: /Users/ardasayar/Documents/FlutterProjekte/sprachapp/build/natur_umwelt_authoring_batch_3.zip

## Befehle und tatsächliche Prüfoutputs

Ab Repository-Root. PYTHON auf macOS Terminal: pipeline/.venv-macos/bin/python; Windows PowerShell: .\pipeline\.venv\Scripts\python.exe. Dart-/Flutter-/Git-Befehle identisch auf beiden Systemen. Logs und lokale Hilfsskripte unter build/natur_batch_2_checks/.

```text
PYTHON natur_umwelt_batch_2/verify_natur_umwelt_batch_2.py --repo .
PYTHON build/natur_batch_2_checks/correct_delivery.py
PYTHON build/natur_batch_2_checks/reviewed_delivery/verify_natur_umwelt_batch_2.py --repo .
PYTHON pipeline/scripts/import_editorial_patch.py --source pipeline/out/natur_umwelt_batch_1_v1/pack.json --create build/natur_batch_2_checks/reviewed_delivery/natur_umwelt_batch_2.editorial.json --registry pipeline/data/words/en.natur_umwelt_batch_2_context_v1.json --display-patch build/natur_batch_2_checks/reviewed_delivery/natur_umwelt_batch_2.display.json --out pipeline/out/natur_umwelt_batch_2_v1
PYTHON build/natur_batch_2_checks/audit_export.py
PYTHON -m pytest pipeline/tests/test_editorial_import.py pipeline/tests/test_content_contract.py pipeline/tests/test_selection.py pipeline/tests/test_word_registry.py pipeline/tests/test_learning_groups.py pipeline/tests/test_authoring_context.py pipeline/tests/test_authoring_schema3.py pipeline/tests/test_authoring_continuation.py pipeline/tests/test_deck_display.py -q
PYTHON build/natur_batch_2_checks/prepare_stage.py
dart run tool/stage_content_pack.dart --from pipeline/out/natur_umwelt_batch_2_v1
dart run tool/stage_content_pack.dart --verify
flutter test test/data/real_pack_test.dart
flutter analyze
PYTHON pipeline/scripts/export_authoring_context.py --help
PYTHON pipeline/scripts/export_authoring_context.py --selection pipeline/data/selection/natur_umwelt_v1.json --batch 3 --prepare-continuation natur_umwelt_batch_3_context_v1
PYTHON pipeline/scripts/export_authoring_context.py --selection pipeline/data/selection/natur_umwelt_batch_3_context_v1.json --batch 3 --out build/natur_batch_2_checks/staging/natur_umwelt_authoring_batch_3.zip
PYTHON pipeline/scripts/export_authoring_context.py --verify-zip build/natur_batch_2_checks/staging/natur_umwelt_authoring_batch_3.zip
PYTHON pipeline/scripts/export_authoring_context.py --verify-zip build/natur_umwelt_authoring_batch_3.zip
```

### verifier-corrected.log

```text
PASS source/registry/groups/manifest hashes, Schema 3, context and base SQLite
PASS hash-bound display patch: append 82..162, final display 1..162; original registry positions preserved
PASS create_content/build_rows: 2156 cards; 2041 primary goals (160/489/241/245/245/249/250/162); 18 tables
PASS 81 reserved identities, display 1..162; 2075 old IDs and all historical rows preserved
PASS 939 token positions; no alternatives released; linter 0 errors, 4 warnings
WARNINGS [["flock", "i+1", "'geese'/'geese' Zipf 3.35 below 3.5"], ["avalanche", "i+1", "'snowfall'/'snowfall' Zipf 3.22 below 3.5"], ["meadow", "i+1", "'graze'/'grazing' Zipf 3.49 below 3.5"], ["dolphin", "i+1", "'swam'/'swam' Zipf 3.34 below 3.5"]]
NOT RUN: App staging, Flutter/device tests, user database access

Exit 0
```

### correction.log

```text
PASS one temporal in-token corrected; one review hash, display create_sha256 and copy manifest renewed; sentences/cards/learning/display rows unchanged

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
    "lemmas": 3377,
    "senses": 4829,
    "cards": 2156,
    "dictionary_forms": 5656,
    "decks": 8,
    "deck_cards": 2156,
    "deck_words": 2052,
    "word_aliases": 36,
    "sentences": 2690,
    "sentence_tokens": 29982,
    "card_sentences": 2684,
    "stories": 1,
    "story_sentences": 6,
    "exercises": 0,
    "grammar_rules": 0,
    "audio_assets": 0,
    "content_releases": 1
  },
  "sha256": "19d5831aa207d305cf71a16cc4437e3dee5ec995523aa6353c100a6c77f489e9"
}

Exit 0
```

### audit.log

```text
SQLITE_FULL_ROWS {'languages': 1, 'lemmas': 3377, 'senses': 4829, 'cards': 2156, 'dictionary_forms': 5656, 'decks': 8, 'deck_cards': 2156, 'deck_words': 2052, 'word_aliases': 36, 'sentences': 2690, 'sentence_tokens': 29982, 'card_sentences': 2684, 'stories': 1, 'story_sentences': 6, 'exercises': 0, 'grammar_rules': 0, 'audio_assets': 0, 'content_releases': 1}
PASS 162 original identities, definitions, learning groups, owners and fixed sentences; partition 162/80/0
PASS 2075 historical cards and all old content preserved, except authorized Natur display positions; all Batch-1 corrections retained
PASS reviewed reading/annotation documents exactly match all 81 sentences and 939 imported token positions
DECK allgemeine-sprache 160
DECK reisen 489
DECK alltag-zuhause 241
DECK arbeit-bildung 245
DECK menschen-beziehungen 245
DECK koerper-gesundheit 249
DECK essen-trinken 250
DECK natur-umwelt 162
PACK_SHA256 c936b0359a1f87a30f1ad2715552362cc34a6447a61d7685adc723fa21799932
SQLITE_SHA256 19d5831aa207d305cf71a16cc4437e3dee5ec995523aa6353c100a6c77f489e9
PASS all 162 ownership aliases exact; 80 future cards absent; reserved helper senses exact; five old corrections retained; temporal in correction exact; zero released alternatives
NEW_TOKEN_COUNTS 853 word tokens 86 punctuation

Exit 0
```

### pytest.log

```text
........................................................................ [ 58%]
...................................................   [100%]
123 passed, 19 subtests passed in 1.73s

Exit 0
```

### prepare-stage.log

```text
PASS backup BEFORE staging: {"verified_before_staging_utc": "2026-10-10T13:26:32.789460+00:00", "files": {"assets/content/en/content.sqlite": "3136cdbbcf5c9b71d2afd36b3614caf25e6cf29f3dbd8903bff0347ff194d84f", "assets/content/en/content.manifest.json": "b299d46849b39a998f07a7188263de239f04631ab16c93b6a76a70cc27443dc8"}}
PASS exact eight-deck test expectations added; existing bytes preserved

Exit 0
```

### stage.log

```text
Running build hooks...Running build hooks...staged assets/content/en/content.sqlite
  version natur_umwelt_batch_2_v1, schema 3, 14594048 bytes
  sha256 19d5831aa207d305cf71a16cc4437e3dee5ec995523aa6353c100a6c77f489e9
  18 table counts match finalization_report.json
  INTERNES TEST-PACK: own devices and selected testers only, no public content release

Exit 0
```

### stage-verify.log

```text
Running build hooks...Running build hooks...verified assets/content/en/content.sqlite
  version natur_umwelt_batch_2_v1, schema 3, 14594048 bytes
  sha256 19d5831aa207d305cf71a16cc4437e3dee5ec995523aa6353c100a6c77f489e9
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
deck natur-umwelt: 162 learning targets, 162 ownership cards, 162 fixed sentence assignments verified
pack natur_umwelt_batch_2_v1 (schema 3, internal: true); 8 decks: 2052 cards, 2156 card sentences, 136 with valid_alternatives, 2156 cards in the pack
00:21 +1: All tests passed!

Exit 0
```

### flutter-analyze.log

```text
Analyzing sprachapp...
No issues found! (ran in 3.2s)

Exit 0
```

### continuation.log

```text
{
  "snapshots": "PASS",
  "paths": {
    "selection": "pipeline/data/selection/natur_umwelt_batch_3_context_v1.json",
    "registry": "pipeline/data/words/en.natur_umwelt_batch_3_context_v1.json",
    "groups": "pipeline/data/learning_groups/en.natur_umwelt_batch_3_context_v1.json"
  },
  "partition_counts": {
    "imported": 162,
    "current": 80,
    "future": 0
  }
}

Exit 0
```

### verify-batch-3-final.log

```text
{
  "zip_verification": "PASS",
  "zip_sha256": "a06984d08bb50530fcc812fb39123545b5307c684c12038c01e8996c07602956",
  "hashed_files": 82,
  "sqlite_tables": 18,
  "sqlite_cards": 2156,
  "credentials_and_learning_states": "none; explicit content/source/model whitelist",
  "status": "PASS",
  "selected": 242,
  "excluded": 452,
  "partition_counts": {
    "imported": 162,
    "current": 80,
    "future": 0
  },
  "reused_proposed_senses": 10,
  "batches": {
    "1": 81,
    "2": 81,
    "3": 80
  },
  "topics_per_batch": {
    "1": {
      "Tiere und ihre Lebensräume": 15,
      "Pflanzen, Bäume und Pflanzenteile": 12,
      "Klima, Energie und Naturschutz": 11,
      "Materialien und natürliche Ressourcen": 11,
      "Umwelt, Abfall und Recycling": 9,
      "Landschaften und Gewässer": 9,
      "Naturvorgänge und Jahreszeiten": 8,
      "Wetter und Temperatur": 6
    },
    "2": {
      "Tiere und ihre Lebensräume": 15,
      "Pflanzen, Bäume und Pflanzenteile": 12,
      "Materialien und natürliche Ressourcen": 12,
      "Klima, Energie und Naturschutz": 11,
      "Umwelt, Abfall und Recycling": 9,
      "Naturvorgänge und Jahreszeiten": 8,
      "Landschaften und Gewässer": 8,
      "Wetter und Temperatur": 6
    },
    "3": {
      "Tiere und ihre Lebensräume": 15,
      "Pflanzen, Bäume und Pflanzenteile": 12,
      "Materialien und natürliche Ressourcen": 11,
      "Klima, Energie und Naturschutz": 10,
      "Umwelt, Abfall und Recycling": 10,
      "Naturvorgänge und Jahreszeiten": 8,
      "Landschaften und Gewässer": 8,
      "Wetter und Temperatur": 6
    }
  },
  "existing_senses": 30,
  "new_senses": 212,
  "existing_cards": 2156,
  "existing_groups": 2144,
  "new_groups": 80,
  "registry_words": 2132,
  "partition_selection": "PASS: 162 present",
  "validate_selection": "PASS: parent and exact reservations",
  "index_registry": "PASS",
  "validate_learning": "PASS: existing and planned",
  "build_rows": "PASS: reservation-only rows unchanged",
  "semantic_review": "explicit editorial decisions, no automatic equivalence inference"
}

Exit 0
```

## SHA256 (Rohbytes)

| Datei | SHA256 |
|---|---|
| pipeline/out/natur_umwelt_batch_1_v1/pack.json | `0238ba53db979fb9c54483ee6c9ba7e0794bec30f7a506c1d0b237e2383a0767` |
| pipeline/out/natur_umwelt_batch_1_v1/content.sqlite | `3136cdbbcf5c9b71d2afd36b3614caf25e6cf29f3dbd8903bff0347ff194d84f` |
| natur_umwelt_batch_2/natur_umwelt_batch_2.editorial.json | `92e68bc4319a648b0c8040b9645c746dc62afd0dfb56344b1c67b05820374e3b` |
| natur_umwelt_batch_2/natur_umwelt_batch_2.display.json | `0284d37ca115804136070a72c4c829ebae49791bc7336a8bdfc66bac61c47588` |
| natur_umwelt_batch_2/manifest.json | `62088b0b7338152ee062d65a190fc64dcaa04e89b842b7e48d1846c6b6621a55` |
| build/natur_batch_2_checks/reviewed_delivery/natur_umwelt_batch_2.editorial.json | `973ff3030d478e5e7b2f60d2695c332c0452c60ca3ea7bb2996c4faf77a55f9b` |
| build/natur_batch_2_checks/reviewed_delivery/natur_umwelt_batch_2.display.json | `6262e1a8bcab58196820bec82df96f371a42218949a965df5328fe2772a7f220` |
| build/natur_batch_2_checks/reviewed_delivery/manifest.json | `92e4f730911b4dfca15ffc9e7ca9f3cb68055202dd7d863661bc52cc29c6fa0b` |
| pipeline/out/natur_umwelt_batch_2_v1/pack.json | `c936b0359a1f87a30f1ad2715552362cc34a6447a61d7685adc723fa21799932` |
| pipeline/out/natur_umwelt_batch_2_v1/content.sqlite | `19d5831aa207d305cf71a16cc4437e3dee5ec995523aa6353c100a6c77f489e9` |
| assets/content/en/content.sqlite | `19d5831aa207d305cf71a16cc4437e3dee5ec995523aa6353c100a6c77f489e9` |
| assets/content/en/content.manifest.json | `3ace9567532887c1baeaa9479372276a0c152d9606fca2139f25d09656f42696` |
| pipeline/data/selection/natur_umwelt_v1.json | `344f4b562855584acf8c3290ff2c8b5c7f4a6b400b937cd7f166cd0671ee0c21` |
| pipeline/data/selection/natur_umwelt_batch_3_context_v1.json | `d5ae9b2909fa27a17306842bc70a52cb324663ed5ff450d69c32ae5d119d6058` |
| pipeline/data/words/en.natur_umwelt_batch_3_context_v1.json | `64917e02425a5f06ad80394722da175ca5ab0db573e0fb7dda86736a5e46e318` |
| pipeline/data/learning_groups/en.natur_umwelt_batch_3_context_v1.json | `ed3edcc49fbd6b69f962fee4fc5edb77271cdf593e0bdd1fc231956cbdff9177` |
| build/natur_umwelt_authoring_batch_3.zip | `a06984d08bb50530fcc812fb39123545b5307c684c12038c01e8996c07602956` |

## Arbeitsbaum und Grenzen

Baseline mit 2645 Dateien. Ausschließlich vier Bestandsdateien dürfen geändert sein: Assets/Manifest, test/data/real_pack_test.dart und NEXTSTEPS.md. Neu: Pack, drei Batch-3-Kontextsnapshots, dieser Bericht und ZIP. Original-Lieferung, historische Packs, Originalauswahl, alte Registrys/Gruppen, alte ZIP und Roadmap bleiben bytegleich. Schlussnachweis unter final-protection.json, final-checks.log und Git-Status vorher/nachher.

Gezielte git diff --check-Prüfung, zusätzlicher CRLF-toleranter Check sowie separate Prüfung unversionierter Textdateien gegen /dev/null und test/NEXTSTEPS gegen Ausgangskopien. Keine riesige repositoryweite Diff-Ausgabe. Bekannte sieben Altstellen separat erhalten: DESIGN.md:162–164, docs/alltag-zuhause-continuation.md:148/153, docs/arbeit-bildung-batch-1-import.md:127 und docs/arbeit-bildung-batch-2-import.md:121. Keine globale Bereinigung.

Keine echte user.db/review_log oder Lernstände verändert; keine App-/SRS-/Synonym-/Modell-/Budget-/Supabase-/Plattformänderung, Cloud-/Modellaufrufe, Veröffentlichung, Commits oder Pushes. Keine Geräteprüfung oder unabhängige menschliche Sprachfreigabe behauptet. Offen: Satzredaktion der letzten 80 Natur-Ziele, Geräteprüfung und bekannte Altbefunde. Keine ungeklärte Inhaltsbindung des aktuellen Imports.

## Abschließender Nachweis

```text
BASELINE 2645 UNCHANGED 2641 CHANGED ['NEXTSTEPS.md', 'assets/content/en/content.manifest.json', 'assets/content/en/content.sqlite', 'test/data/real_pack_test.dart']
git-diff-check-targeted Exit 2 output bytes 20363
git-diff-check-targeted-crlf Exit 0 output bytes 0
PASS new untracked files, NEXTSTEPS and exact test change separately checked; own whitespace Exit 0
git status --short Exit 0; saved to git-status-after.txt
PASS all historical selections/registries/groups, historical packs/deliveries and app/pipeline code unchanged; only authorized assets/manifest/test/NEXTSTEPS changed; no repository-wide diff generated

Exit 0
```

2641 von 2645 Ausgangsdateien bytegleich; genau vier beauftragte Bestandsdateien geändert. Normaler gezielter Diff-Check Exit 2 wegen erhaltener CRLF-Konvention in NEXTSTEPS/Test; CRLF-tolerant keine Befunde. Neue unversionierte Dateien und eigene Änderungen separat ohne Whitespace-Diagnostik geprüft. NEXTSTEPS: 25 Zeilen.
