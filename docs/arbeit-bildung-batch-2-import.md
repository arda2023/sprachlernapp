# Arbeit & Bildung – Batch 2: Import und Batch-3-Kontext

Stand: 07.10.2026. `arbeit_bildung_batch_2_v1` vollständig offline importiert und intern gestagt.

## Ergebnis und Identitäten

82 neue Lernziele, 82 Satzpaare, 934 Tokenpositionen und vier wörtlich geprüfte Alternativen. Insgesamt 1169 Karten, 1703 Satztexte, 1697 Satzverknüpfungen einschließlich Historie und 1065 Wortbesitzzeilen. 1054 primäre Lernziele: 160 Allgemeine Sprache / 489 Reisen / 241 Alltag & Zuhause / 164 Arbeit & Bildung.

Alle 1087 bisherigen Karten-IDs, Sätze, Tokenbindungen, Metadaten und die front-Korrektur aus Batch 1 sind erhalten. Exakt die 164 importierten Arbeit-Identitäten entsprechen der ursprünglichen 245er-Auswahl; keine Karten oder Sätze für die letzten 81 Ziele. Alle neuen Zielübersetzungen und cards.learning unverändert, genau ein fester Satz pro neuer Karte, accepted ausschließlich Zielform. Keine Lernkarten für Begleitwörter.

Kein neuer Stapel: zunächst Mitgliedschaften 83–164 angehängt, anschließend den gelieferten separaten Display-Patch angewendet. Source-, Create-, Registry- und Vorher-Zeilenhashes geprüft. Beide Positionsspalten des Arbeit-Stapels ergeben 1–164. Nur diese alten Positionswerte dürfen sich unterscheiden; alle anderen alten Inhaltswerte und die Originalpositionen der Auswahl/Registry sind unverändert.

## Artefakte und Rohbyte-Hashes

- Pack: `pipeline/out/arbeit_bildung_batch_2_v1/pack.json`
- Pack-SHA256: `e9d2211a725565dd1a6d2214d730c525142894126273768ff3d4976e8da3085b`
- SQLite/gestagtes Asset: `3cf9f6b434f1c0b03d66164ca5db0deb88443c3c8bdf69224605696b1a73cba6`
- Basis-Pack: `ebe5fd764d290d671682cff10f55f1b06e35026b5a19b1c3216ab6dadd89b3a2`
- Basis-SQLite: `4b7a1899e9c0b9247ba3cddd153aaa56fe1a2470eb7e41c2ade31ea01656e9dd`
- ZIP: `build/arbeit_bildung_authoring_batch_3.zip`
- ZIP-SHA256: `d52925fd880edb9b3a334badfaa1882083bfe9c0cafbb38e6ca8293be9be7540`

## Redaktionelle Prüfung

Alle 82 Satzpaare und 934 Tokenpositionen gegengelesen. Keine konkret belegte Lieferkorrektur erforderlich; Create-Datei, Display-Patch, Reviewhashes, Originalmanifest und Referenzen unverändert übernommen. Keine Normalisierung unveränderter Dateien.

Die kontextbezogenen Bedeutungen sind passend getrennt: drive=Laufwerk, left=übrig, design als Entwurf bzw. entwerfen, plans als Vorhaben bzw. Baupläne sowie plan als Verb. track bezeichnet den Überblick; lessons/taught im failure-Satz Erkenntnisse aus Erfahrung. schedule/timetable sind Zeitpläne, budget ein Finanzplan, secure ein Adjektiv und store Datenspeicherung. working ist das Arbeitstag-Attribut; name und printing sind Verben. Bestehende sowie reservierte Begleitwort-Bedeutungen werden wiederverwendet, ohne Karten vorzuziehen. Historische Formglossen nicht bereinigt. Keine unabhängige menschliche Qualitätszertifizierung behauptet.

Vier Alternativen vollständig eingesetzt und geprüft:

- You can enroll on the evening course until the end of August.
- We need to analyze the results before we write our report.
- It is courteous to thank someone who has helped you.
- The first question was easy, but the last one was hard.

Diese neutralen Alternativen ändern die bestehenden Synonym-/Lernstandsregeln nicht; keine automatische Freigabe aus Alias oder Lerngruppe. Der Linter meldet 0 Fehler und vier neue Häufigkeitshinweise bei mittel/Zipf 3.5: simplify 3.46 (process), timetable 3.44 (discuss), cupboard 3.44 (stationery), trainee 3.43 (keen). Keine Umformulierungen allein wegen dieser Hinweise.

## Fortsetzung für Batch 3

Neue Snapshots: `pipeline/data/selection/arbeit_bildung_batch_3_context_v1.json`, `pipeline/data/words/en.arbeit_bildung_batch_3_context_v1.json`, `pipeline/data/learning_groups/en.arbeit_bildung_batch_3_context_v1.json`.

Partition 164 importiert / 81 aktuell / 0 später. Alle ursprünglichen 245 Einträge, Positionen, Definitionen und Identitäten exakt erhalten; alle 1146 Registry-Wörter unverändert. Elf vorgeschlagene Bedeutungen werden im Fortsetzungskontext bereits als vorhanden wiederverwendet. Keine neue Definitionsäquivalenz-Ausnahme. Anhängepositionen 165–245 und gemeinsamer Display-Plan 1–245 sind vorbereitet, jetzt nicht angewendet. Keine Batch-3-Sätze erzeugt.

Der erste Fortsetzungsaufruf mit dem Batch-2-Snapshot wurde korrekt mit `use immutable initial selection` abgelehnt (Exit 1, keine Snapshots geschrieben). Danach mit `arbeit_bildung_v1.json`, Batch 3 und demselben Zielnamen erfolgreich ausgeführt. Es wurde keine Vertragsprüfung umgangen und kein Werkzeug geändert.

Die ZIP enthält 83 Dateien, einschließlich Manifest mit 82 Nutzdateihashes: tatsächlicher neuer Basis-Pack/SQLite, Wörterbuch, alle Identitäten, ursprüngliche und fortgesetzte Auswahl, Registry/Gruppen, Schema, relevante Quellen, lokale Sprachmodelldateien und Fortsetzungszuordnung. Temporär unter `build/arbeit_batch_2_checks/staging/` geschrieben, vollständig geschlossen, erneut geöffnet und CRCs/Hashes geprüft. Erst anschließend auf den endgültigen Pfad verschoben und mit dem bestehenden ZIP-Verifier erneut geprüft. Auch alle 18 SQLite-Tabellen werden dabei vollständig gelesen und verglichen.

## Prüfungen und tatsächliche Ausgaben

Die folgenden abschließenden Prüfungen haben Exit 0. `audit_export.py` ist ein auftragsspezifisches Audit unter build: wiederholt die Lieferprüfungen, vergleicht den tatsächlichen Export exakt mit dem validierten Create-/Display-Ergebnis und alle 18 SQLite-Tabellen zeilenweise gegen build_rows. Keine neue generische Testsuite.

Bestehende Python-Testpfade unter `pipeline/tests/`: `test_editorial_import.py`, `test_word_registry.py`, `test_selection.py`, `test_learning_groups.py`, `test_deck_display.py`, `test_authoring_context.py`, `test_authoring_schema3.py`, `test_authoring_continuation.py`.

### verifier.log

```text
PASS source/registry/groups/manifest hashes, Schema 3, context and base SQLite
PASS hash-bound display patch: append 83..164, final display 1..164; original registry positions preserved
PASS create_content/build_rows: 1169 cards; 1054 primary goals (160/489/241/164); 18 tables
PASS 82 reserved identities, display 1..164; 1087 old IDs and all historical rows preserved
PASS 934 token positions; four reviewed alternatives; linter 0 errors, 4 warnings
WARNINGS [["process", "i+1", "'simplify'/'simplify' Zipf 3.46 below 3.5"], ["discuss", "i+1", "'timetable'/'timetable' Zipf 3.44 below 3.5"], ["stationery", "i+1", "'cupboard'/'cupboard' Zipf 3.44 below 3.5"], ["keen", "i+1", "'trainee'/'trainee' Zipf 3.43 below 3.5"]]
NOT RUN: App staging, Flutter/device tests, user database access
Exit: 0
```

### audit.log

```text
PASS source/registry/groups/manifest hashes, Schema 3, context and base SQLite
PASS hash-bound display patch: append 83..164, final display 1..164; original registry positions preserved
PASS create_content/build_rows: 1169 cards; 1054 primary goals (160/489/241/164); 18 tables
PASS 82 reserved identities, display 1..164; 1087 old IDs and all historical rows preserved
PASS 934 token positions; four reviewed alternatives; linter 0 errors, 4 warnings
WARNINGS [["process", "i+1", "'simplify'/'simplify' Zipf 3.46 below 3.5"], ["discuss", "i+1", "'timetable'/'timetable' Zipf 3.44 below 3.5"], ["stationery", "i+1", "'cupboard'/'cupboard' Zipf 3.44 below 3.5"], ["keen", "i+1", "'trainee'/'trainee' Zipf 3.43 below 3.5"]]
SQLITE_FULL_ROWS {'languages': 1, 'lemmas': 2171, 'senses': 3401, 'cards': 1169, 'dictionary_forms': 3844, 'decks': 4, 'deck_cards': 1169, 'deck_words': 1065, 'word_aliases': 15, 'sentences': 1703, 'sentence_tokens': 18206, 'card_sentences': 1697, 'stories': 1, 'story_sentences': 6, 'exercises': 0, 'grammar_rules': 0, 'audio_assets': 0, 'content_releases': 1}
PASS historical front correction retained
PACK_SHA256 e9d2211a725565dd1a6d2214d730c525142894126273768ff3d4976e8da3085b
SQLITE_SHA256 3cf9f6b434f1c0b03d66164ca5db0deb88443c3c8bdf69224605696b1a73cba6
Exit: 0
```

### pytest.log

```text
.......................................................... [ 59%]
.......................................                             [100%]
97 passed, 19 subtests passed in 2.30s
Exit: 0
```

### stage-verify.log

```text
verified assets\content\en\content.sqlite
  version arbeit_bildung_batch_2_v1, schema 3, 8863744 bytes
  sha256 3cf9f6b434f1c0b03d66164ca5db0deb88443c3c8bdf69224605696b1a73cba6
  18 table counts match finalization_report.json
  INTERNES TEST-PACK: own devices and selected testers only, no public content release
Running build hooks...Running build hooks...
Exit: 0
```

### flutter-test.log

```text
00:00 +0: loading C:/Users/ardas/Music/sprachapp/test/data/real_pack_test.dart
00:00 +0: staged pack: all cards and sentence links readable, read-only
deck allgemeine-sprache: 160 learning targets, 160 ownership cards, 160 fixed sentence assignments verified
deck reisen: 489 learning targets, 500 ownership cards, 500 fixed sentence assignments verified
deck alltag-zuhause: 241 learning targets, 241 ownership cards, 241 fixed sentence assignments verified
deck arbeit-bildung: 164 learning targets, 164 ownership cards, 164 fixed sentence assignments verified
pack arbeit_bildung_batch_2_v1 (schema 3, internal: true); 4 decks: 1065 cards, 1169 card sentences, 108 with valid_alternatives, 1169 cards in the pack
00:07 +1: All tests passed!
Exit: 0
```

### flutter-analyze.log

```text
Analyzing sprachapp...                                          
No issues found! (ran in 2.2s)
Exit: 0
```

### continuation-final.log

```text
{
  "snapshots": "PASS",
  "paths": {
    "selection": "pipeline/data/selection/arbeit_bildung_batch_3_context_v1.json",
    "registry": "pipeline/data/words/en.arbeit_bildung_batch_3_context_v1.json",
    "groups": "pipeline/data/learning_groups/en.arbeit_bildung_batch_3_context_v1.json"
  },
  "partition_counts": {
    "imported": 164,
    "current": 81,
    "future": 0
  }
}
Exit: 0
```

### continuation-audit.log

```text
PASS 245 entries and all registry words unchanged; partition 164/81/0
PASS append 165..245; future combined display 1..245; no Batch-3 cards
PASS 82 sentence pairs, 934 token positions reviewed; literal alternatives:
You can enroll on the evening course until the end of August.
We need to analyze the results before we write our report.
It is courteous to thank someone who has helped you.
The first question was easy, but the last one was hard.
Exit: 0
```

### ZIP-Abschlussprüfung

```json
{
  "zip_verification": "PASS",
  "zip_sha256": "d52925fd880edb9b3a334badfaa1882083bfe9c0cafbb38e6ca8293be9be7540",
  "hashed_files": 82,
  "sqlite_tables": 18,
  "sqlite_cards": 1169,
  "partition_counts": {
    "imported": 164,
    "current": 81,
    "future": 0
  },
  "reused_proposed_senses": 11
}
```

Exit: 0. Vollständige Ausgabe: `build/arbeit_batch_2_checks/zip-final-verify.log`.

## Schutzumfang und nächster Schritt

Vor Änderungen wurden Git-Status und 1405 Ausgangshashes gesichert. Asset/Manifest, real_pack_test.dart und NEXTSTEPS.md sind unter `build/arbeit_batch_2_checks/backup/` gesichert. Geänderte Bestandsdateien: nur Asset, Manifest, konkrete Batch-2-Erwartungen im vorhandenen real_pack_test.dart und NEXTSTEPS.md. Neue Dateien: neuer Export, drei Fortsetzungssnapshots, dieser Bericht sowie Prüf-/ZIP-Artefakte. Bestehende Änderungen nicht zurückgesetzt. Original-Lieferung, historische Packs, Registrys und Auswahlen unverändert; Referenzquellen nicht über Projektcode kopiert.

App-Einstieg, App-/SRS-/Synonymlogik, Modelle, Budgets, Supabase und Plattformdateien unverändert. Keine echte user.db geöffnet oder Lernstände verändert; der Lesetest arbeitet in einem temporären Testverzeichnis. Keine Cloud-/Modellaufrufe, Veröffentlichung, Commits oder Pushes. Keine Geräteprüfung ausgeführt. Keine offenen Import-/ZIP-Vertragsfehler. Nächster Schritt: die letzten 81 Ziele anhand der Batch-3-ZIP redigieren.

Abschließender Rohbytevergleich: 1401 von 1405 Ausgangsdateien byteidentisch; exakt die vier autorisierten Bestandsdateien verändert. Nachweis: `build/arbeit_batch_2_checks/preservation.json`.
