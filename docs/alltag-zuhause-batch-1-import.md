# Alltag & Zuhause — Batch 1, 07.10.2026

## Aktueller Stand nach Folgeauftrag

Batch 1 ist intern gestagt; Lieferverifier und Dreistapel-Lesetest bestehen.
Der Fortsetzungs-Exporter und die Batch-2-ZIP mit 80 Zielen sind geprüft.
Details, Sicherungen, erlaubte Zeilenendennormalisierung und aktuelle Befehle:
[Staging- und Fortsetzungsbericht](alltag-zuhause-continuation.md).

## Historischer Importstand vor dem Folgeauftrag

83 reservierte Lernziele und 83 Satzpaare offline geprüft und mit dem bestehenden
Schema-3-Importer nach `pipeline/out/alltag_zuhause_batch_1_v1/` exportiert.
Die bereits vorhandene Lieferung `alltag_zuhause_batch_1/` wurde nicht überschrieben.
Alle gelieferten Originaldateien und Referenzquellen bleiben unverändert.

Basis-Rohbytehash:
`d0976e3db100638f3712c919501c6f8009a7a9b73d80d7e61549376bfaf299c0`.
Neuer SQLite-SHA256:
`f2439e023c2f835477c0a806b9a72fc495313bfefb7ef32fe0272f0b8b63c9ca`.

## Inhaltsprüfung

Alle 83 englischen/deutschen Satzpaare gegen Zieldefinition, Lücke und sämtliche
Worttokenbindungen gelesen. Alle neun Alternativen wörtlich eingesetzt und
geprüft: neighbor, faucet, adhesive, pants, sweater, pajamas, line, movie, soccer.
`accepted` enthält jeweils ausschließlich die Zielform; keine automatische
Freigabe durch Gruppen oder Schreibaliase. Zwei neue Besitzaliase, neun geprüfte
Satzalternativen. Keine zusätzlichen Begleitwort-Karten.

Kein eindeutig belegter Lieferfehler, daher keine Inhaltskorrektur oder Neugenerierung.
91 neue Lemmas, 105 neue Senses (davon 60 Begleitwort-Senses), 147 neue Wörterbuchformen.
Prüfentscheidungen: `build/alltag_zuhause_batch_1_checks/editorial_review.json`.
Wörtliche Alternativsätze: `build/alltag_zuhause_batch_1_checks/alternative_substitutions.json`.

Mehrdeutigkeiten ausdrücklich geprüft: `pot#blumentopf` ist kein Kochgefäß;
`bath#baden` ist die Tätigkeit, nicht die Badewanne; `shopping#einkaeufe` sind Waren,
nicht das attributive Einkaufs-. `one#stellvertreter` ist referentenunabhängig;
die alten keys/Glossen nennen konkret Reisepass, Stuhl oder Kissen und bleiben
unverändert. Keine neue Lernkarte für diese allgemeine Pronomenbedeutung.
Reservierte spätere Senses wie sofa, toy, wipe, fit, jeans, flour, fry und lid
werden bereits als Wörterbuch-Kontext aufgenommen, nicht vorzeitig als Lernziel.

## Export und Erhaltung

| Bestand nach Import | Anzahl |
|---|---:|
| Physische Karten | 847 |
| Satztexte | 1381 |
| Satzverknüpfungen einschließlich Historie | 1375 |
| Wortbesitzzeilen | 743 |
| Lemmas / Senses / Wörterbuchformen | 1834 / 2991 / 3271 |
| Primäre Einführungsziele | 732 |
| Allgemeine Sprache / Reisen / Alltag & Zuhause | 160 / 489 / 83 |

Alle 18 SQLite-Tabellen gegen `build_rows` rückgelesen. Alle 764 alten Karten-IDs
und sämtliche alten Listenzeilen einschließlich Metadaten, Reihenfolgen,
Wörterbuch, Sätzen und Story erhalten. Alle 83 neuen `learning`-Werte entsprechen
exakt der Auswahl. Dichte neue Anzeigepositionen 1–83; Registry-Originalpositionen
unverändert. 335 vorab erfasste Dateien (App-Code, alte Packs/Registrys/Auswahl und
Lieferung) hashgleich. Linter: 0 Fehler, 290 Häufigkeitswarnungen insgesamt,
26 davon neu. Keine Warnung durch wiederholte Satzänderung unterdrückt.

Der vorhandene Pack-Lesetest wurde auf den dritten Stapel erweitert; keine neue
generische Testsuite. Normaler App-Einstieg, SRS-, Gruppen- und Synonymregeln
unverändert. Keine echte user.db geöffnet oder kopiert; kein Gerätetest.

## Historischer Blocker — im Folgeauftrag behoben: Abhängigkeit

Der erste exakte Lieferverifier-Aufruf scheitert vor Inhaltsprüfung mit
`ModuleNotFoundError: No module named 'jsonschema'` (Exit 1).
Auch System-/gebündelte Python-Umgebung und lokaler pip-Cache enthalten das Paket
nicht. Keine Validatorprüfung übersprungen, keine Lieferquelle verändert.
Die Frage nach einem reinen Abhängigkeitsdownload ist offen. Der eigenständige
Projektimport und Readback sind bereits erfolgreich; internes Staging wartet auf
den vollständigen Lieferverifier.

## Historischer Blocker — im Folgeauftrag behoben: Batch-2-Vertrag

Das aktuelle Kontextwerkzeug unterstützt eine teilweise importierte Auswahl noch
nicht. `authoring_context.validate_context` verlangt für **alle** Auswahlziele
`partition_selection: 0 present`, prüft alle Ziele als neu gegen den Basissnapshot
und verlangt `len(registry.words) == len(parent.words) + len(entries)`.
Nach Batch 1 sind bereits 83 der 241 Ziele importiert und alle 241 im neuen
Pack-Snapshot reserviert. Auch `groups.existing` deckt bislang nur die 764 Karten
der alten Basis ab; 83 reservierte Köpfe sind inzwischen echte Bestandskarten.
Die Auswahl ist unveränderlich an die alte Basis gebunden.

Für Batch 2 fehlt ein expliziter Fortsetzungsvertrag: 83 bestehende, 80 aktuelle
und 78 spätere Identitäten getrennt validieren; vorhandene Begleitwort-Senses
ohne ID-/Definitionsänderung übernehmen; neue hashgebundene Registry-/Gruppen-
und Kontext-Snapshots; bestehende Anzeigepositionen 1–83 von kommenden 84–163
und anschließender gemeinsamer Zuordnung unterscheiden. Nur den Packpfad oder
Hash zu ersetzen wäre falsch. Gemäß Auftrag kein großer Umbau, keine alte
Auswahl-/Registryversion geändert und keine irreführende Batch-2-ZIP erstellt.

## Historische Befehle und Ergebnisse des ersten Importauftrags

Repository-Stamm, Windows PowerShell: `pipeline/.venv/Scripts/python.exe`.
macOS Terminal: denselben Aufruf mit `pipeline/.venv/bin/python` verwenden.
`dart`, `flutter` und `git` sind plattformgleich.

```text
pipeline/.venv/Scripts/python.exe alltag_zuhause_batch_1/verify_alltag_zuhause_batch_1.py --repo .
ModuleNotFoundError: No module named 'jsonschema'
Exit 1

pipeline/.venv/Scripts/python.exe pipeline/scripts/import_editorial_patch.py --source pipeline/out/learning_groups_v1/pack.json --create alltag_zuhause_batch_1/alltag_zuhause_batch_1.editorial.json --registry pipeline/data/words/en.alltag_zuhause_v1.json --out pipeline/out/alltag_zuhause_batch_1_v1
status: ok; internal_test_pack: true; ai_calls: 0; ai_cost_usd: 0
sqlite_counts: languages 1, lemmas 1834, senses 2991, cards 847,
dictionary_forms 3271, decks 3, deck_cards 847, deck_words 743,
word_aliases 10, sentences 1381, sentence_tokens 14468, card_sentences 1375,
stories 1, story_sentences 6, exercises 0, grammar_rules 0,
audio_assets 0, content_releases 1
sha256: f2439e023c2f835477c0a806b9a72fc495313bfefb7ef32fe0272f0b8b63c9ca
Exit 0

pipeline/.venv/Scripts/python.exe build/alltag_zuhause_batch_1_checks/audit.py
PASS: 18 tables; 764 old IDs; 335 protected files unchanged;
learning_targets 160/489/83; new_targets 83; alternatives 9;
linter_errors 0; warnings_total 290; warnings_new 26
Exit 0

pipeline/.venv/Scripts/python.exe -m pytest pipeline/tests/test_authoring_context.py pipeline/tests/test_authoring_schema3.py pipeline/tests/test_content_contract.py pipeline/tests/test_editorial_import.py pipeline/tests/test_learning_groups.py pipeline/tests/test_word_registry.py pipeline/tests/test_selection.py pipeline/tests/test_deck_display.py -q
107 passed, 19 subtests passed in 2.27s
Exit 0

dart format test/data/real_pack_test.dart
Formatted 1 file (1 changed) in 0.03 seconds.
Exit 0

flutter analyze
No issues found! (ran in 32.6s)
Exit 0
```

```text
git diff --check
warning: in the working copy of 'NEXTSTEPS.md', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'docs/pipeline.md', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'pipeline/scripts/import_editorial_patch.py', LF will be replaced by CRLF the next time Git touches it
Exit 0
```

```text
git status --short
 M ARCHITECTURE.md
 M DESIGN.md
 M NEXTSTEPS.md
 M PRODUCT.md
 M docs/content-schema.md
 M docs/decks-and-story-learning-plan.md
 M docs/pipeline.md
 M docs/reisen-500-authoring.md
 M docs/srs.md
 M docs/user-schema.md
 M lib/data/content/content_database.dart
 M lib/data/content/drift_content_repository.dart
 M lib/data/learning/practice_item_resolver.dart
 M lib/data/user/drift_user_repository.dart
 M lib/domain/answer_check.dart
 M lib/domain/content.dart
 M lib/domain/leitner.dart
 M lib/domain/new_card_selection.dart
 M lib/domain/repositories.dart
 M lib/domain/review_pass.dart
 M lib/domain/srs_state.dart
 M lib/domain/story_learning.dart
 M lib/presentation/providers/deck_providers.dart
 M lib/presentation/providers/learning_providers.dart
 M pipeline/data/curation/editorial_content_v2.schema.json
 M pipeline/scripts/import_editorial_patch.py
 M pipeline/src/sprachpipe/content_contract.py
 M pipeline/src/sprachpipe/pack.py
 M pipeline/src/sprachpipe/schema.py
 M pipeline/tests/test_editorial_import.py
 M test/data/real_pack_test.dart
 M test/data/review_flow_test.dart
 M test/deck_flow_test.dart
 M test/domain/answer_check_test.dart
 M test/domain/review_pass_test.dart
?? alltag_zuhause_batch_1/
?? docs/alltag-zuhause-authoring.md
?? docs/alltag-zuhause-batch-1-import.md
?? docs/learning-groups-v1.md
?? docs/reisen-batch-2-import.md
?? docs/reisen-batch-3-import.md
?? docs/reisen-batch-4-import.md
?? docs/reisen-batch-5-import.md
?? lib/domain/learning_groups.dart
?? pipeline/data/curation/reisen_batch_2.editorial.json
?? pipeline/data/curation/reisen_batch_2_display_v1.json
?? pipeline/data/curation/reisen_batch_3.editorial.json
?? pipeline/data/curation/reisen_batch_3_display_v1.json
?? pipeline/data/curation/reisen_batch_4.editorial.json
?? pipeline/data/curation/reisen_batch_4_display_v1.json
?? pipeline/data/curation/reisen_batch_5.editorial.json
?? pipeline/data/curation/reisen_batch_5_display_v1.json
?? pipeline/data/learning_groups/
?? pipeline/data/selection/alltag_zuhause_v1.json
?? pipeline/data/words/en.alltag_zuhause_v1.json
?? pipeline/data/words/en.reisen_batch_3_v1.json
?? pipeline/data/words/en.reisen_batch_4_v1.json
?? pipeline/data/words/en.reisen_batch_5_v1.json
?? pipeline/scripts/export_authoring_context.py
?? pipeline/scripts/export_learning_groups.py
?? pipeline/src/sprachpipe/authoring_context.py
?? pipeline/src/sprachpipe/deck_display.py
?? pipeline/src/sprachpipe/learning_groups.py
?? pipeline/tests/test_authoring_context.py
?? pipeline/tests/test_authoring_schema3.py
?? pipeline/tests/test_deck_display.py
?? pipeline/tests/test_learning_groups.py
?? reisen_batch_2/
?? reisen_batch_3/
?? reisen_batch_4/
?? reisen_batch_5/
?? supabase/migrations/20261006000001_learning_groups.sql
?? test/data/learning_groups_test.dart
?? test/domain/learning_groups_test.dart
?? tool/report_learning_groups.dart
Exit 0
```
