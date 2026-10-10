# Arbeit & Bildung — Authoring-Vorbereitung

Stand 07.10.2026. **245 neue eigenständige Lernziele**, aufgeteilt in
**82 / 82 / 81**. Die erste Gruppe ist vollständig für die Satzredaktion
vorbereitet: `build/arbeit_bildung_authoring_batch_1.zip`.
Partition: **0 importiert / 82 aktuell / 163 später**.
Es wurden keine neuen Übungssätze erzeugt und keine Karten in das App-Pack importiert.

ZIP-SHA256: `089e38c359b927dbadcf9c055c2d859848ed42c72bda156874eae1b244f79006`.
81 Dateien, davon 80 Nutzdateien im Hashmanifest; CRC, Hashes, Kontextvertrag
und sämtliche 18 SQLite-Tabellen nach erneutem Öffnen geprüft.

## Basis und aktuelle Verträge

Basis ist `pipeline/out/alltag_zuhause_batch_3_v1/pack.json`, Schema 3:
1005 physische Karten, 890 primäre Lernziele (160 Allgemeine Sprache /
489 Reisen / 241 Alltag & Zuhause), 993 Gruppen über sämtliche Bestandskarten.

- Pack-JSON-SHA256: `bb092533f44af47f168f1b432226f4999585e8b4ad5f789ca544abe04fe32be0`.
- Quellen-SQLite und unverändertes App-Asset:
  `9fd1a5e546ba32e92bdbb519008414dc34225f76552e79d8271a71af50a1cbe3`.
- Wortregistry: tatsächlicher eingebetteter Snapshot des Basis-Packs. Er entspricht
  `pipeline/data/words/en.alltag_zuhause_batch_3_context_v1.json` mit 901 Zeilen.
  Dessen historische Quellenfelder werden nicht als aktueller Export interpretiert.
- Lerngruppen: aus den tatsächlichen `cards.learning` aller 1005 Basis-Karten
  samt stabilen Karten- und Kopf-IDs projiziert. Der frühere 927-Karten-Snapshot
  wird ausdrücklich nicht als vollständiger aktueller Bestand verwendet.

Neue Dateien:

- `pipeline/data/selection/arbeit_bildung_v1.json`
- `pipeline/data/words/en.arbeit_bildung_v1.json`
- `pipeline/data/learning_groups/en.arbeit_bildung_v1.json`

Die neue Wortregistry enthält 901 unveränderte Bestandszeilen und 245 neue
Reservierungen. Die Gruppenregistry enthält 1005 unveränderte Bestandsmitglieder
und 245 reservierte Einzelköpfe. `bind_new_pack`, `index_registry`,
`validate_selection`, `partition_selection`, `validate_learning` und
`validate_context` wurden wiederverwendet. Mit der reservierenden Registry
erzeugt `build_rows` weiterhin exakt die unveränderten Basis-Inhaltszeilen.

## Auswahl und Verteilung

256 Kandidaten geprüft, 11 bewusst ausgeschlossen. 245 statt exakt 250 ist die
redaktionelle Entscheidung gegen überschneidende Auffüllwörter. Die Mischung
umfasst 155 Substantive, 57 Verben und 33 Adjektive, mit praktisch verwendbaren
Berufs-, Büro-, Schul- und Lernbegriffen statt seltenen Spezialtermini.

| Thema | Gesamt | Batch 1 | Batch 2 | Batch 3 |
|---|---:|---:|---:|---:|
| Beruf und Arbeitsplatz | 32 | 11 | 11 | 10 |
| Büro und Organisation | 30 | 10 | 10 | 10 |
| Zusammenarbeit und Kommunikation | 30 | 10 | 10 | 10 |
| Bewerbung und Berufseinstieg | 31 | 10 | 10 | 11 |
| Schule und Unterricht | 31 | 11 | 10 | 10 |
| Ausbildung und Studium | 30 | 10 | 10 | 10 |
| Lernen und Prüfungen | 32 | 10 | 11 | 11 |
| Aufgaben, Fähigkeiten und Arbeitsabläufe | 29 | 10 | 10 | 9 |
| **Gesamt** | **245** | **82** | **82** | **81** |

Die vollständige Auswahl speichert pro Ziel Form, Lemma/POS, natürliche deutsche
Lernübersetzung, explizite Zieldefinition, stabile Lemma-/Sense-/Karten-IDs,
Originalposition, Batch, Eigentümer, Gruppenmetadaten und einzelne Prüfentscheidungen.
Alle Bedeutungsbindungen sind entschieden. Satzbezogene Alternativen werden
erst bei der späteren Redaktion wörtlich geprüft und festgelegt.

Originalpositionen 1–256 wurden vor Ausschlüssen thematisch verschränkt;
Auswahl und Registry erhalten diese Positionen samt Ausschlusslücken.
Die Batch-Zuordnung ist getrennt gespeichert. Die vom Exporter bereitgestellten
kumulativen Anzeigemappings umfassen 1–82, 1–164 und 1–245. Sie sind keine
Lernreihenfolge. Jede Authoring-Gruppe enthält alle acht Themen; der zusätzliche
Audit findet keine direkt benachbarten gleichen Themen oder gemeinsamen
Kontrasttags innerhalb einer Gruppe.

## Wörterbuchwiederverwendung und Bedeutungsgrenzen

**48 passende bestehende Wörterbuch-Senses werden wiederverwendet**, ohne
Bestandszeilen umzuschreiben; **197 neue Bedeutungen** sind ausdrücklich mit
stabilen vorgeschlagenen Schlüsseln definiert. Die neuen Bindungen erzeugen noch
keine Wörterbuch- oder Kartenzeilen im App-Pack.

Bei mehreren alten Senses wurden Glossierung und vorhandene Satzbelege geprüft:
manager#manager statt engerer Geschäftsführer-Glosse; team#team im Arbeitskontext
statt Sportmannschaft; teacher#lehrkraft; school#schule-hier-schul;
lesson#unterrichtsstunde; notebook#hefte; pen#stift; print#druckt-aus;
digital#digitale; raise#hebt. Alle Kandidatensenses und vorhandene Belegsätze
sind in den Eintragsreviews gespeichert. Flektierte historische Glossen bleiben
erhalten; die neue Lernübersetzung ist davon getrennt.

Vorhandene allgemeine Senses werden nicht für einen engeren Kontext dupliziert:
student behält ausdrücklich Schule **und** Hochschule, pencil umfasst Stifte mit
fester Mine einschließlich Buntstiften, training bezeichnet praktische Schulung
auch über den alten Sportbeleg hinaus. Deshalb entfällt pupil als überlappendes
zweites Ziel. Es gibt keine neu erforderliche pauschale Definitionsgleichsetzung;
bestehende Sensezeilen werden exakt übernommen. Die früheren jeans-/aisle- und
wrapper-Entscheidungen im Basis-Pack bleiben unberührt.

Bewusste neue Bedeutungen bei vorhandenen Lemmas:

| Ziel | Abgrenzung zum Wörterbuchbestand |
|---|---|
| save | Daten speichern statt Ressourcen sparen. |
| goal | Angestrebter Zustand statt Fußballtor. |
| pass | Eine Prüfung bestehen statt weiterreichen/vorbeifahren. |
| strength | Persönliche besondere Stärke statt allgemeiner Kraft/Willenskraft. |
| minutes | Sitzungsprotokoll; eigener Pluralbegriff, nicht Zeitminuten unter minute. |

Gleiche deutsche Glossen wurden als Prüfsignal verwendet und anschließend präzisiert:
process → **Arbeitsablauf** statt expiry → Ablauf einer Gültigkeit;
achieve → **ein Ziel erreichen** statt reach → räumliches Erreichen (Bestandssatz:
Campingplatz erreichen); attend → **am Unterricht teilnehmen** statt visit →
Orts-/Personenbesuch (Bestandssatz: Schloss besuchen).
Auch difficult (Aufgabenschwierigkeit) bleibt vom alten hard (physische Härte)
getrennt. Keine Gleichsetzung allein nach deutscher Übersetzung.

Nominale Ableitungen und Eigenschaften bleiben nur mit explizitem Funktionsunterschied
eigenständig, etwa application/applicant/apply, qualification/qualified,
experience/experienced, solution/solve oder improvement/improve. Das sind keine
Flexionskarten. Britisches practice als Tätigkeitsnomen und practise als Verb
bleiben verschiedene Ziele; die amerikanische Verbform practice wird nicht als
Schreibalias reserviert und kollidiert damit nicht mit dem Nomen.

## Verworfene Überschneidungen und Varianten

| Verworfen | Begründung / vorhandenes oder gewähltes Ziel |
|---|---|
| invoice | Zweite Rechnungsaufgabe neben bill vermieden. |
| organise | Organisieren bereits mit arrange gelernt. |
| advice | Zu starke Überschneidung mit recommendation; konservativ ausgeschlossen. |
| reply | Antworten bereits mit answer gelernt. |
| reject | Ablehnen bereits mit refuse gelernt. |
| complete | Abschließen bereits mit finish gelernt. |
| check | Form und Lernziel bereits vergeben. |
| ability | Zu nah an neuem skill; keine künstliche Bedeutungsaufspaltung. |
| pupil | Durch den bestehenden breiten student-Sense abgedeckt. |
| diploma | Überlappender Dokumentbegriff neben certificate; degree bezeichnet den Abschluss selbst. |
| compulsory | Überlappt bereits angebotene Satzalternative required. |

Varianten wie worker, boss/supervisor, personnel, firm, résumé/resume, rubber,
examination/test, lab und collaborate stehen nur als zu prüfende Synonymkandidaten
beim jeweiligen Ziel, nicht als weitere Lernkarten. Orthografisch reserviert:
apologize, enroll, analyze, memorize zu den britischen Formen.
Weder diese Aliasse noch Synonymkandidaten sind automatisch gültige Satzantworten.

Die technische Prüfung umfasst sämtliche Karten und historischen Satzalternativen,
Wörterbuchformbindungen an gelernte Senses, gelernte Lemmas, zehn historische
Wortregistrys sowie alle neuen Formen/Varianten. 262 eindeutige geplante Formen
einschließlich vier Schreibaliasen und 13 Synonymkandidaten, keine Kollisionen.
Semantische Abgrenzung bleibt eine dokumentierte redaktionelle Entscheidung,
keine Behauptung einer automatischen Synonymerkennung.

## Kleine Exporteranpassung und ZIP-Abschluss

Konkreter Befund vor Anpassung: README-Titel und neuer Stapelslug waren auf
Alltag & Zuhause festgeschrieben; Erstkontexte enthielten keine explizite Partition.
`export_authoring_context.py` verwendet jetzt Titel/Slug der Auswahl und ergänzt
die durch `partition_batches` ermittelte Erstpartition. Spätere Batches verlangen
einen Fortsetzungssnapshot. Der ZIP-Verifier prüft Erstpartition und neuen
Stapelvertrag. Die README-Prüfanweisung verwendet einen Platzhalter für den
fertigen ZIP-Pfad, damit temporäre Exportpfade nicht als Zielpfad stehen bleiben.
Keine zweite Pipeline, keine Änderung an Import-, ID-, Gruppen- oder SRS-Regeln.

Regressionstest in `pipeline/tests/test_authoring_context.py`: synthetischer
Export mit neuem Titel/Slug, echter ZIP-Roundtrip mit SQLite, Ablehnung einer
hashkonsistent manipulierten Partition und eines Erstexports von Batch 2.
Bestehende Schema-3-/Fortsetzungsprüfungen laufen weiterhin mit.

ZIP zunächst unter
`build/arbeit_bildung_checks/staging/arbeit_bildung_authoring_batch_1.zip`
geschrieben und vollständig geschlossen. Danach erneutes Öffnen mit dem
bestehenden Verifier: CRC, alle Hashes, Quellen, Wörterbuch, Identitäten,
Registry, Gruppen, Metadaten und vollständiger SQLite-Readback erfolgreich.
Erst anschließend ohne Überschreiben eines bestehenden Endexports nach
`build/arbeit_bildung_authoring_batch_1.zip` verschoben und erneut geprüft.

Enthalten: gesamte Basis einschließlich vorhandener Sätze, SQLite, Wörterbuch,
alle 245 Zielidentitäten/Definitionen, 82 aktuelle Einträge, volle Auswahl mit
Ausschlüssen und Entscheidungen, Registry, Lerngruppen, alle Anzeigemappings,
Schema, echte Import-/Validierungs-/Tokenizer-/Linterquellen, Konfiguration,
Paket-Lock und lokale spaCy-Modellgewichte. Keine Zugangsdaten oder Lernstände.

## Bestandsschutz und offene Schritte

1202 Ausgangsdateien und Git-Status erfasst. Abschlussaudit: 1199 bytegleich;
nur Exporter, sein bestehendes Testmodul und NEXTSTEPS geändert. Basis-Pack,
SQLite, Assets/Manifest, alte Auswahl-/Registrydateien und App-Einstieg unverändert.
Neue Dateien sind die drei Snapshots, dieser Bericht, ZIP und lokale Prüfnachweise.
NEXTSTEPS enthält 24 Zeilen.

97 betroffene Python-Tests plus 19 Untertests bestanden. Asset-Verifikation und
alle Vertrags-/ZIP-Prüfungen bestanden. Keine Flutter-Gesamtsuite für diese reine
Vorbereitung, keine Geräteprüfung. Keine Satzgenerierung, Cloud-/Modellaufrufe,
Paketupdates, App-/SRS-Änderungen, Supabase-Aktionen, Veröffentlichung, Commits
oder Pushes. Offen ist die Satzredaktion der 82 Ziele aus Batch 1; kein technischer
Blocker und keine offene Bedeutungsbindung.

## Tatsächliche Prüfoutputs

Ab Repository-Root ausgeführt. `PYTHON` steht unter Windows PowerShell für
`.\pipeline\.venv\Scripts\python.exe`, unter macOS Terminal für
`pipeline/.venv/bin/python`, jeweils mit denselben Argumenten.
Dart- und Git-Befehle sind auf beiden Systemen identisch.
Erstellungsbefehle dokumentieren den erfolgten Lauf, keine bestehenden Ergebnisse
erneut überschreiben. Ausgangsstatus, Einzelprotokolle und Audit liegen unter
`build/arbeit_bildung_checks/`.


```text
$ dart run tool/stage_content_pack.dart --verify
verified assets\content\en\content.sqlite
  version alltag_zuhause_batch_3_v1, schema 3, 7979008 bytes
  sha256 9fd1a5e546ba32e92bdbb519008414dc34225f76552e79d8271a71af50a1cbe3
  18 table counts match finalization_report.json
  INTERNES TEST-PACK: own devices and selected testers only, no public content release
Running build hooks...Running build hooks...
Exit: 0
```


```text
$ PYTHON -m pytest pipeline/tests/test_selection.py pipeline/tests/test_word_registry.py pipeline/tests/test_learning_groups.py pipeline/tests/test_authoring_context.py pipeline/tests/test_authoring_schema3.py pipeline/tests/test_authoring_continuation.py pipeline/tests/test_deck_display.py pipeline/tests/test_editorial_import.py -q
.................................................................................................                             [100%]
97 passed, 19 subtests passed in 2.18s
Exit: 0
```


```text
$ PYTHON pipeline/scripts/export_authoring_context.py --selection pipeline/data/selection/arbeit_bildung_v1.json --batch 1 --out build/arbeit_bildung_checks/staging/arbeit_bildung_authoring_batch_1.zip
{
  "export": "PASS",
  "zip": "C:\\Users\\ardas\\Music\\sprachapp\\build\\arbeit_bildung_checks\\staging\\arbeit_bildung_authoring_batch_1.zip",
  "files": 81,
  "status": "PASS",
  "selected": 245,
  "excluded": 11,
  "batches": {
    "1": 82,
    "2": 82,
    "3": 81
  },
  "topics_per_batch": {
    "1": {
      "Beruf und Arbeitsplatz": 11,
      "Schule und Unterricht": 11,
      "Aufgaben, Fähigkeiten und Arbeitsabläufe": 10,
      "Büro und Organisation": 10,
      "Zusammenarbeit und Kommunikation": 10,
      "Bewerbung und Berufseinstieg": 10,
      "Ausbildung und Studium": 10,
      "Lernen und Prüfungen": 10
    },
    "2": {
      "Ausbildung und Studium": 10,
      "Lernen und Prüfungen": 11,
      "Beruf und Arbeitsplatz": 11,
      "Schule und Unterricht": 10,
      "Aufgaben, Fähigkeiten und Arbeitsabläufe": 10,
      "Büro und Organisation": 10,
      "Zusammenarbeit und Kommunikation": 10,
      "Bewerbung und Berufseinstieg": 10
    },
    "3": {
      "Büro und Organisation": 10,
      "Zusammenarbeit und Kommunikation": 10,
      "Bewerbung und Berufseinstieg": 11,
      "Ausbildung und Studium": 10,
      "Lernen und Prüfungen": 11,
      "Beruf und Arbeitsplatz": 10,
      "Aufgaben, Fähigkeiten und Arbeitsabläufe": 9,
      "Schule und Unterricht": 10
    }
  },
  "existing_senses": 48,
  "new_senses": 197,
  "existing_cards": 1005,
  "existing_groups": 993,
  "new_groups": 245,
  "registry_words": 1146,
  "partition_selection": "PASS: 0 present",
  "validate_selection": "PASS: parent and exact reservations",
  "index_registry": "PASS",
  "validate_learning": "PASS: existing and planned",
  "build_rows": "PASS: reservation-only rows unchanged",
  "semantic_review": "explicit editorial decisions, no automatic equivalence inference"
}
Exit: 0
```


```text
$ PYTHON pipeline/scripts/export_authoring_context.py --verify-zip build/arbeit_bildung_checks/staging/arbeit_bildung_authoring_batch_1.zip
{
  "zip_verification": "PASS",
  "zip_sha256": "089e38c359b927dbadcf9c055c2d859848ed42c72bda156874eae1b244f79006",
  "hashed_files": 80,
  "sqlite_tables": 18,
  "sqlite_cards": 1005,
  "credentials_and_learning_states": "none; explicit content/source/model whitelist",
  "status": "PASS",
  "selected": 245,
  "excluded": 11,
  "batches": {
    "1": 82,
    "2": 82,
    "3": 81
  },
  "topics_per_batch": {
    "1": {
      "Beruf und Arbeitsplatz": 11,
      "Schule und Unterricht": 11,
      "Aufgaben, Fähigkeiten und Arbeitsabläufe": 10,
      "Büro und Organisation": 10,
      "Zusammenarbeit und Kommunikation": 10,
      "Bewerbung und Berufseinstieg": 10,
      "Ausbildung und Studium": 10,
      "Lernen und Prüfungen": 10
    },
    "2": {
      "Ausbildung und Studium": 10,
      "Lernen und Prüfungen": 11,
      "Beruf und Arbeitsplatz": 11,
      "Schule und Unterricht": 10,
      "Aufgaben, Fähigkeiten und Arbeitsabläufe": 10,
      "Büro und Organisation": 10,
      "Zusammenarbeit und Kommunikation": 10,
      "Bewerbung und Berufseinstieg": 10
    },
    "3": {
      "Büro und Organisation": 10,
      "Zusammenarbeit und Kommunikation": 10,
      "Bewerbung und Berufseinstieg": 11,
      "Ausbildung und Studium": 10,
      "Lernen und Prüfungen": 11,
      "Beruf und Arbeitsplatz": 10,
      "Aufgaben, Fähigkeiten und Arbeitsabläufe": 9,
      "Schule und Unterricht": 10
    }
  },
  "existing_senses": 48,
  "new_senses": 197,
  "existing_cards": 1005,
  "existing_groups": 993,
  "new_groups": 245,
  "registry_words": 1146,
  "partition_selection": "PASS: 0 present",
  "validate_selection": "PASS: parent and exact reservations",
  "index_registry": "PASS",
  "validate_learning": "PASS: existing and planned",
  "build_rows": "PASS: reservation-only rows unchanged",
  "semantic_review": "explicit editorial decisions, no automatic equivalence inference"
}
Exit: 0
```


```text
$ PYTHON pipeline/scripts/export_authoring_context.py --verify-zip build/arbeit_bildung_authoring_batch_1.zip
{
  "zip_verification": "PASS",
  "zip_sha256": "089e38c359b927dbadcf9c055c2d859848ed42c72bda156874eae1b244f79006",
  "hashed_files": 80,
  "sqlite_tables": 18,
  "sqlite_cards": 1005,
  "credentials_and_learning_states": "none; explicit content/source/model whitelist",
  "status": "PASS",
  "selected": 245,
  "excluded": 11,
  "batches": {
    "1": 82,
    "2": 82,
    "3": 81
  },
  "topics_per_batch": {
    "1": {
      "Beruf und Arbeitsplatz": 11,
      "Schule und Unterricht": 11,
      "Aufgaben, Fähigkeiten und Arbeitsabläufe": 10,
      "Büro und Organisation": 10,
      "Zusammenarbeit und Kommunikation": 10,
      "Bewerbung und Berufseinstieg": 10,
      "Ausbildung und Studium": 10,
      "Lernen und Prüfungen": 10
    },
    "2": {
      "Ausbildung und Studium": 10,
      "Lernen und Prüfungen": 11,
      "Beruf und Arbeitsplatz": 11,
      "Schule und Unterricht": 10,
      "Aufgaben, Fähigkeiten und Arbeitsabläufe": 10,
      "Büro und Organisation": 10,
      "Zusammenarbeit und Kommunikation": 10,
      "Bewerbung und Berufseinstieg": 10
    },
    "3": {
      "Büro und Organisation": 10,
      "Zusammenarbeit und Kommunikation": 10,
      "Bewerbung und Berufseinstieg": 11,
      "Ausbildung und Studium": 10,
      "Lernen und Prüfungen": 11,
      "Beruf und Arbeitsplatz": 10,
      "Aufgaben, Fähigkeiten und Arbeitsabläufe": 9,
      "Schule und Unterricht": 10
    }
  },
  "existing_senses": 48,
  "new_senses": 197,
  "existing_cards": 1005,
  "existing_groups": 993,
  "new_groups": 245,
  "registry_words": 1146,
  "partition_selection": "PASS: 0 present",
  "validate_selection": "PASS: parent and exact reservations",
  "index_registry": "PASS",
  "validate_learning": "PASS: existing and planned",
  "build_rows": "PASS: reservation-only rows unchanged",
  "semantic_review": "explicit editorial decisions, no automatic equivalence inference"
}
Exit: 0
```


```text
$ PYTHON build/arbeit_bildung_checks/audit.py
{
  "status": "PASS",
  "selected": 245,
  "excluded": 11,
  "batches": {
    "1": 82,
    "2": 82,
    "3": 81
  },
  "topics_per_batch": {
    "1": {
      "Beruf und Arbeitsplatz": 11,
      "Schule und Unterricht": 11,
      "Aufgaben, Fähigkeiten und Arbeitsabläufe": 10,
      "Büro und Organisation": 10,
      "Zusammenarbeit und Kommunikation": 10,
      "Bewerbung und Berufseinstieg": 10,
      "Ausbildung und Studium": 10,
      "Lernen und Prüfungen": 10
    },
    "2": {
      "Ausbildung und Studium": 10,
      "Lernen und Prüfungen": 11,
      "Beruf und Arbeitsplatz": 11,
      "Schule und Unterricht": 10,
      "Aufgaben, Fähigkeiten und Arbeitsabläufe": 10,
      "Büro und Organisation": 10,
      "Zusammenarbeit und Kommunikation": 10,
      "Bewerbung und Berufseinstieg": 10
    },
    "3": {
      "Büro und Organisation": 10,
      "Zusammenarbeit und Kommunikation": 10,
      "Bewerbung und Berufseinstieg": 11,
      "Ausbildung und Studium": 10,
      "Lernen und Prüfungen": 11,
      "Beruf und Arbeitsplatz": 10,
      "Aufgaben, Fähigkeiten und Arbeitsabläufe": 9,
      "Schule und Unterricht": 10
    }
  },
  "existing_senses": 48,
  "new_senses": 197,
  "existing_cards": 1005,
  "existing_groups": 993,
  "new_groups": 245,
  "registry_words": 1146,
  "partition_selection": "PASS: 0 present",
  "validate_selection": "PASS: parent and exact reservations",
  "index_registry": "PASS",
  "validate_learning": "PASS: existing and planned",
  "build_rows": "PASS: reservation-only rows unchanged",
  "semantic_review": "explicit editorial decisions, no automatic equivalence inference",
  "base_sqlite_tables": 18,
  "base_learning_targets": {
    "allgemeine-sprache": 160,
    "reisen": 489,
    "alltag-zuhause": 241
  },
  "old_registry_versions_checked": {
    "en.alltag_zuhause_batch_2_context_v1.json": 901,
    "en.alltag_zuhause_batch_3_context_v1.json": 901,
    "en.alltag_zuhause_v1.json": 901,
    "en.reisen_500_v1.json": 660,
    "en.reisen_batch_2_v1.json": 660,
    "en.reisen_batch_3_v1.json": 660,
    "en.reisen_batch_4_v1.json": 660,
    "en.reisen_batch_5_v1.json": 660,
    "en.story_learning_v1.json": 160,
    "en.v1.json": 160
  },
  "planned_variants_unique": 262,
  "topic_or_contrast_adjacent_pairs": 0,
  "baseline_files": 1202,
  "protected_files_byte_identical": 1199,
  "changed_existing_files": [
    "NEXTSTEPS.md",
    "pipeline/scripts/export_authoring_context.py",
    "pipeline/tests/test_authoring_context.py"
  ],
  "asset_sha256": "9fd1a5e546ba32e92bdbb519008414dc34225f76552e79d8271a71af50a1cbe3",
  "new_sentences": 0
}
Exit: 0
```


```text
$ git diff --check
warning: in the working copy of 'docs/pipeline.md', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'pipeline/pyproject.toml', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'pipeline/scripts/import_editorial_patch.py', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'test/data/real_pack_test.dart', LF will be replaced by CRLF the next time Git touches it
Exit: 0
```


```text
$ git status --short
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
 M pipeline/pyproject.toml
 M pipeline/requirements.lock
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
?? alltag_zuhause_batch_2/
?? alltag_zuhause_batch_3/
?? docs/alltag-zuhause-authoring.md
?? docs/alltag-zuhause-batch-1-import.md
?? docs/alltag-zuhause-batch-2-import.md
?? docs/alltag-zuhause-batch-3-import.md
?? docs/alltag-zuhause-continuation.md
?? docs/arbeit-bildung-authoring.md
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
?? pipeline/data/selection/alltag_zuhause_batch_2_context_v1.json
?? pipeline/data/selection/alltag_zuhause_batch_3_context_v1.json
?? pipeline/data/selection/alltag_zuhause_definition_equivalences_v1.json
?? pipeline/data/selection/alltag_zuhause_v1.json
?? pipeline/data/selection/arbeit_bildung_v1.json
?? pipeline/data/words/en.alltag_zuhause_batch_2_context_v1.json
?? pipeline/data/words/en.alltag_zuhause_batch_3_context_v1.json
?? pipeline/data/words/en.alltag_zuhause_v1.json
?? pipeline/data/words/en.arbeit_bildung_v1.json
?? pipeline/data/words/en.reisen_batch_3_v1.json
?? pipeline/data/words/en.reisen_batch_4_v1.json
?? pipeline/data/words/en.reisen_batch_5_v1.json
?? pipeline/scripts/export_authoring_context.py
?? pipeline/scripts/export_learning_groups.py
?? pipeline/src/sprachpipe/authoring_context.py
?? pipeline/src/sprachpipe/deck_display.py
?? pipeline/src/sprachpipe/learning_groups.py
?? pipeline/tests/test_authoring_context.py
?? pipeline/tests/test_authoring_continuation.py
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
Exit: 0
```
