# Business & E-Mail – Batch 5: Offline-Import und offener Standard-Testtimeout

Stand: 14.10.2026. **96 neue /483 gesamte Business-Ziele** als `business_email_batch_5_v1` importiert und intern gestagt. Vorhandene App-Projektion: **3672 Karten, 14 Stapel, 3558 Übungen /3287 lexikalische Ziele**. **Standard-App-Testabnahme offen:** ein Standardlauf scheiterte am 30-Sekunden-Timeout. Import, Staging und ZIP-Prüfung sind erfolgreich; der gesonderte Drei-Minuten-Lauf bestand nach 124.6 Sekunden Gesamtprozesszeit (Testanzeige 02:01). Dies ist ausschließlich eine Diagnose und kein Standard-PASS. Technische Abnahme und öffentliche Inhaltsfreigabe bleiben getrennt. Keine Geräteabnahme oder unabhängige menschliche Sprachfreigabe, keine Cloud-/Modellaufrufe, Paketinstallationen, Produktions-/Testcodeänderungen oder echte user.db.

## Basis, Lieferung und Bestandsschutz

Originalauswahl `pipeline/data/selection/business_email_v2.json`; Kontext `pipeline/data/selection/business_email_batch_5_context_v1.json`, Registry `pipeline/data/words/en.business_email_batch_5_context_v1.json`, Lerngruppen `pipeline/data/learning_groups/en.business_email_batch_5_context_v1.json`. Auswahl-ID `business_email_v2`, historische Eintrags-IDs `business-email-v1-####` unverändert. Basis: `pipeline/out/business_email_batch_4_v1/{pack.json,content.sqlite}`, Schema 4; Asset und Manifest entsprechen der geprüften Batch-4-Basis.

Original-ZIP `/Users/ardasayar/Downloads/business_email_batch_5_lieferung.zip` erneut geöffnet: CRCs, eindeutige sichere Pfade, **33 manifestierte Dateihashes** geprüft. Vorhandene Entpackung `business_email_batch_5/` bytegleich. Erst nach erfolgreicher Lieferprüfung bytegleiche Arbeitskopie `editorial_review/business_email_batch_5/` angelegt und unverändert für den Import verwendet. Keine mitgelieferten authoring_evidence-Skripte ausgeführt.

**Manifestlücke wie in Batch 3:** `reference/manifest.json` fehlt als einzige zusätzliche Inhaltsdatei in der Lieferdateiliste. Diese Datei und alle übrigen Referenzdateien separat bytegenau an die bekannte geprüfte `build/business_email_authoring_batch_5.zip` gebunden, Gesamt-SHA256 `a04a6a3fa3a0f11cb8a4f32e464064ec035b080cbd655df4776aaa4397cb7156`. Keine Originaldatei oder Validierungsregel geändert.

Ausgangspartition **387 importiert /96 aktuell /96 später**. Gesamtumfang **579 Ziele /43 E-Mail-Ziele**, Batches **97/97/97/96/96/96**, 278 ausgeschlossene Kandidaten unverändert. Keine Auffüllung, keine neue Kategorie. Die Fortsetzung erhält sämtliche Einträge, Definitionen und Ausschlüsse objektgleich.

Ausgangs-HEAD `95092691b8b7c7ac22507c7632b3b4cdd3c283e4`, Index leer. Baseline: **3150 Dateien**, einschließlich vorbestehender untracked Lieferungen. Bereits gelesene Verträge, Importer, Exporter und Stage-Werkzeug hashgleich zum vorherigen Prüfstand; AGENTS, CLAUDE, NEXTSTEPS und Batch-4-Abnahme berücksichtigt. Vorbestehende Änderungen/Fremddateien erhalten. NEXTSTEPS war bereits geändert und bleibt außerhalb des isolierten Commits.

## Redaktionelle Prüfung

Alle **96 Satzpaare, Zieldefinitionen, 1127 Tokenpositionen** vollständig gegengelesen, einschließlich **1021 Wort-/Ausdruckstokens und 106 Satzzeichen**. Neue Begleitwortdefinitionen und 153 neue Formglossen gelesen. Keine belegte Lieferkorrektur erforderlich; Satztexte, Übersetzungen, Zielidentitäten und Reviewhashes unverändert. Exakt ein fester Satz je Ziel; alle Mehrwortziele mit zusammenhängender Lücke. `accepted` enthält ausschließlich die jeweilige Zielform. Vollständiger Einzelbeleg `editorial-review.json` mit Satzpaaren, Tokenzahlen und Hashes; redaktionelle Modellprüfung, keine menschliche Zertifizierung.

Besonders geprüft: trainer = Schulungsleiter, account = Benutzerkonto, strong password = sicheres Passwort, handles tasks = Aufgaben bewältigen. finish bei core hours ist ein Nomen, bei clock out ein Verb. made bei profit bedeutet Gewinn erzielen, bei correction eine Änderung vornehmen; reference in future reference = Nachschlagen. As requested ist eine verkürzte passive Vergleichskonstruktion: as/SCONJ „wie“, requested/request VERB „erbitten“. put through bleibt zusammenhängend vor the caller. Die bestehende their/PRON-Possessivkonvention ist bedeutungsgerecht erhalten; include umfasst laut Bestandsdefinition auch das Einschließen als Teil eines Ganzen. spreadsheet bezeichnet ausdrücklich ein digitales Dokument.

Vier Varianten wörtlich in ihren vollständigen Sätzen gelesen: **enquiry → inquiry**, **change log → changelog**, **one-to-one → one-on-one**, **on-site → onsite**. Dieselbe Bedeutung und passende deutsche Übersetzung; regionale bzw. Schreibvarianten, satzgebunden und lernstandsneutral. Gegen alle 579 Ziele, Registry, Bestandskarten und Besitz-/Synonymaliase geprüft; keine Kollision, keine neue word_aliases-Zeile. Die vollständigen eingesetzten Sätze stehen im geprüften alternative_review.json.

Keine zukünftigen Begleitwort-Senses in dieser Lieferung und keine vorzeitige Lernkarte; reservierte Identitäten und Definitionen geprüft.


Acht aktuelle Altglossenvergleiche, keine abschließende Fehlerliste. Alle angegebenen Bestandszeilen exakt bestätigt und erhalten:

| Form | Bestands-Formglosse | Kontextvergleich |
|---|---|---|
| training | Trainings | Schulung |
| lower | untere; niedriger gelegene | niedriger |
| missing | verschwundenen | fehlend; fehlt/fehlen |
| opened | öffnete | geöffnet |
| deadline | Abgabefrist | Frist; hier Zahlungsfrist |
| arranged | vereinbarte | vereinbarten |
| left | übrig (Partizip in paper left) | übrig |
| main | Haupt- | wichtigste; Haupt- |

Auch sämtliche früheren Pilot-/Batch-/Label-/Glossenbefunde einschließlich no-show bleiben offen. Keine globale Korrektur.

## Import, Bestand und 22 Tabellen

Vorhandener V2-Create-Importer auf Schema-4-Basis, explizite Registry und hashgebundener Display-Patch. Neue Mitgliedschaften zunächst **388–483**, anschließend ausschließlich Business-Anzeige **1–483**. **0 alte Positionswerte geändert**; Originalpositionen, IDs, Eigentümer und Lerngruppen unverändert. Neues Ausgabeverzeichnis, kein Überschreiben und kein neuer Stapel.

Export-SQLite geschlossen und erneut schreibgeschützt geöffnet; sämtliche **22 Tabellen** vollständig gegen `build_rows`/vorhandenes `check_sqlite` verglichen. Exportgeneriertes `content_releases.created_at` gemäß bestehendem Vertrag vom exakten Wertvergleich ausgenommen; Vorhandensein geprüft. Alle Altzeilen der übrigen 21 Tabellen einschließlich Positionen erhalten: **3576 Karten, 4110 Sätze, 44806 Tokens, 7767 Dictionary-Zeilen**. Nur Release/Registry autorisiert fortgeschrieben.

| Tabelle | Gesamtzeilen |
|---|---:|
| languages | 1 |
| lemmas | 4897 |
| senses | 6620 |
| cards | 3672 |
| dictionary_forms | 7920 |
| decks | 14 |
| deck_cards | 3565 |
| deck_words | 3461 |
| word_aliases | 37 |
| sentences | 4206 |
| sentence_tokens | 45933 |
| card_sentences | 4200 |
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

Formtabellen unverändert **134/406/402/402**, Ansichten **134/134/134**. Frühere Bindungskorrekturen explizit erhalten: planning (business-email-v1-0131-s1, Index 7) → plan/VERB; either (-0150-s1, Index 3) → either/DET; today (-0189-s1, Index 3) → today/NOUN. Formglossen pick out „aus einer Menge erkennen“ und pull over „an den Straßenrand fahren und anhalten“ unverändert.

App-Zähler tatsächlich mit `tool/report_learning_groups.dart` ermittelt: **Business 483, global 3558 Übungen /3287 Wörter**. 3672 physische Karten und 3461 Besitzzeilen sind keine alternativen Wortzähler; Formübungen zählen ein Lemma nicht dreimal.

Linter **0 Fehler /500 Hinweise**: **493 alte Befunde** unverändert plus:

- `late fee`: 'invoice'/'invoice' Zipf 3.27 below 3.5.
- `payer`: 'invoice'/'invoice' Zipf 3.27 below 3.5.
- `apologetic`: 'receptionist'/'receptionist' Zipf 3.26 below 3.5.
- `appendix`: 'questionnaire'/'questionnaire' Zipf 3.44 below 3.5.
- `escalate`: 'unresolved'/'unresolved' Zipf 3.30 below 3.5.
- `overdue`: 'invoice'/'invoice' Zipf 3.27 below 3.5.
- `worksheet`: 'spreadsheet'/'spreadsheet' Zipf 3.31 below 3.5.

## Sicherung, Tests und Batch 6

Asset/Manifest **vor Staging** bytegleich gesichert unter `build/business_email_batch_5_checks/backup/`, UTC-Zeit `2026-10-14T09:52:26.566986+00:00`. Erst danach internes Staging und separater `--verify`; neues Asset bytegleich zur Export-SQLite. 455 Pipeline-Tests plus 19 Untertests bestanden. Flutter-Analyse ohne Paketauflösung und exakter bestehender Pack-Lesetest `test/data/real_pack_test.dart` mit tatsächlichen Outputs unten. Lesetest isoliert von anderen Dart-/Flutter-Jobs; keine Quelldatei oder Assertion verändert; ein Standardlauf mit 30-Sekunden-Limit scheiterte. Ein gesonderter diagnostischer Lauf verwendet ausdrücklich --timeout 3m, ohne den Standardbefund zu ersetzen. Frühere Batch-2-/Batch-3-/Batch-4-Timeoutursachen bleiben ungeklärt; ein Wiederholungserfolg ist keine Ursachenbehebung.

Die vorhandene `--help` und Pfadbildung des Exporters wurden geprüft. Vor Erzeugung festgelegte neue Dateien, ausschließlich über vorhandenes `--prepare-continuation` aus Originalauswahl v2:

- `pipeline/data/selection/business_email_batch_6_context_v1.json`
- `pipeline/data/words/en.business_email_batch_6_context_v1.json`
- `pipeline/data/learning_groups/en.business_email_batch_6_context_v1.json`

Batch 6: **483 importiert /96 aktuell /0 später**. Geschlossene ZIP erneut geöffnet: **83 Hashdateien, CRCs, Referenzen, 22 Quelltabellen** geprüft. Eingebundene pack.json/SQLite bytegleich zu geprüftem neuem Export/Asset. Kombinierte Anzeigeabbildung **579 eindeutige Zeilen 1–579**. Keine Batch-6-Karten oder Sätze erzeugt. Batch 6 ist der letzte geplante Business-Batch; kein zusätzlicher Stapel außerhalb der Roadmap. Alle Originalauswahlentscheidungen erhalten.

ZIP-Größe: **27287798 komprimierte /84384893 unkomprimierte Bytes**.

Pack: `/Users/ardasayar/Documents/FlutterProjekte/sprachapp/pipeline/out/business_email_batch_5_v1/`

Upload-ZIP: `/Users/ardasayar/Documents/FlutterProjekte/sprachapp/build/business_email_authoring_batch_6.zip`

## Hashnachweise

Rohbyte-SHA256, sofern nicht als kanonischer JSON-Digest bezeichnet:

| Objekt | SHA256 |
|---|---|
| Original-Liefer-ZIP | `a73a74dc9e0bb4e3b1a8561056377e5b71dcde0b62792f81e6bcdf57456f148d` |
| Create (Original/Arbeitskopie) | `91f94ca1838c27f17a5a7bcd761b18707fbb4206c98cf22f33ca64ce0c9200d1` |
| Basis pack.json | `287b99c11a55de8df5634e27e90d623eaa7655fed20d6d12ff8fa268768fcdcc` |
| Registry (kanonisch) | `d4f11ae23cfdf57704b791a0f89221511f524abf7e877b5f7b835bdf56ed8326` |
| Lerngruppen (kanonisch) | `96a60ec4d86af312bdb261543f0e9b03447a59944785843339790b57f0d56226` |
| Backup content.sqlite | `45209632ff07df2c06a203c684bef680e7fb66d58b455f107f8745c166264ae4` |
| Backup content.manifest.json | `ad74a809cc315d7a7d062ef3442e9db3300e9401d46fba814b901597fa0ed518` |
| Export pack.json | `065a2826e1c612f21bd1dc8d3e1d0dc0251a6e092f5a6e874c20f6ec697c4800` |
| Export content.sqlite | `41ea3bc7fc79674f33e5caef09d22a56fb1163ff66d743c3555fcf86d21a35a3` |
| Export finalization_report.json | `ada063866c60de037e6098c9e096906ae89d6693017eb99de9e55bed9a9234ec` |
| build/business_email_authoring_batch_6.zip | `977943172521f8324d4533d52d20d4227c2e412afe0d0d4ab422136e5dc796ea` |
| assets/content/en/content.manifest.json | `9ea5c73a0d57168ff55dd6fed6455890e2efa673db77ea40fabf97279909cb4e` |
| pipeline/data/selection/business_email_batch_6_context_v1.json | `a68da9f1708c687f50f80d6d0496f7b00d2b8d8a38b2b0715c29ecf5c6bd6922` |
| pipeline/data/words/en.business_email_batch_6_context_v1.json | `5d2bf5aff2666af3ef46f54b0829aae1ff6d9f66a43eddca81e6398016858824` |
| pipeline/data/learning_groups/en.business_email_batch_6_context_v1.json | `34439979dbefced068d9a7d05b01ba3ad2813b4ab8e30a2f4e7ef511c7a1c12e` |

## Tatsächliche Befehle und Outputs

Ab Repository-Root auf macOS. Windows PowerShell: Pythonpfad `.\pipeline\.venv\Scripts\python.exe`; übrige Argumente gleich. Dart/Flutter/Git plattformgleich. Wrapper `build/business_email_batch_5_checks/run_check.py NAME BEFEHL …` speichert vollständige Ausgabe in `NAME.log` und Befehl, Exitcode, Laufzeit in `NAME.command.json`. Nachfolgende Auszüge gekürzt; vollständige Belege im Prüfverzeichnis.

```text
python3 build/business_email_batch_5_checks/baseline.py
status-before.txt 0  M NEXTSTEPS.md
?? alltagssprache_redewendungen_batch_3/
?? alltagssprache_redewendungen_batch_4/
?? alltagssprache_redewendungen_batch_5/
?? business_email_batch_1/
?? business_email_batch_2/
?? business_email_batch_3/
?? business_email_batch_4/
?? business_email_batch_5/
?? docs/alltagssprache-redewendungen-batch-3-import.md
?? docs/alltagssprache-redewendungen-batch-4-import.md
?? docs/codebase-overview-planning.md
?? editorial_review/business_email_batch_3/
?? editorial_review/business_email_batch_4/
?? pipeline/data/learning_groups/en.alltagssprache_redewendungen_batch_4_context_v2.json
?? pipeline/data/learning_groups/en.alltagssprache_redewendungen_batch_5_context_v2.json
?? pipeline/data/selection/alltagssprache_redewendungen_batch_4_context_v2.json
?? pipeline/data/selection/alltagssprache_redewendungen_batch_5_context_v2.json
?? pipeline/data/words/en.alltagssprache_redewendungen_batch_4_context_v2.json
?? pipeline/data/words/en.alltagssprache_redewendungen_batch_5_context_v2.json
?? verbalphrasen_batch_1/
?? "verbalphrasen_batch_2 2/"

index-before.txt 0
head.txt 0 95092691b8b7c7ac22507c7632b3b4cdd3c283e4

baseline_files 3150
EXIT 0; Laufzeit 1.93 s
```

```text
pipeline/.venv-macos/bin/python build/business_email_batch_5_checks/delivery_audit.py
{
  "status": "PASS",
  "manifest_exception": "reference/manifest.json unlisted in delivery manifest; separately byte-identical to previous verified authoring ZIP bound by known full ZIP SHA256",
  "delivery_zip": "/Users/ardasayar/Downloads/business_email_batch_5_lieferung.zip",
  "zip_sha256": "a73a74dc9e0bb4e3b1a8561056377e5b71dcde0b62792f81e6bcdf57456f148d",
  "create_sha256": "91f94ca1838c27f17a5a7bcd761b18707fbb4206c98cf22f33ca64ce0c9200d1",
  "manifest_files": 33,
  "all_local_files_match_zip": true,
  "source_json_sha256": "287b99c11a55de8df5634e27e90d623eaa7655fed20d6d12ff8fa268768fcdcc",
  "registry_digest": "d4f11ae23cfdf57704b791a0f89221511f524abf7e877b5f7b835bdf56ed8326",
  "groups_digest": "96a60ec4d86af312bdb261543f0e9b03447a59944785843339790b57f0d56226",
  "current": 96,
  "total": 579,
  "words": 1021,
  "punctuation": 106,
  "alternatives": [
    [
      "enquiry|enquiry/NOUN|enquiry#anfrage",
      "inquiry"
    ],
    [
      "change log|change log/NOUN|change-log#anderungsprotokoll",
      "changelog"
    ],
    [
      "one-to-one|one-to-one/NOUN|one-to-one#einzelgesprach",
      "one-on-one"
    ],
    [
      "on-site|on-site/ADJ|on-site#vor-ort",
      "onsite"
    ]
  ],
  "future_companion_senses": [],
  "add_counts": {
    "lemmas": 114,
    "senses": 133,
    "cards": 96,
    "decks": 0,
    "deck_cards": 96,
    "deck_words": 96,
    "word_aliases": 0,
    "sentences": 96,
    "sentence_tokens": 1127,
    "dictionary_forms": 153,
    "card_sentences": 96
  }
}
EXIT 0; Laufzeit 8.83 s
```

```text
pipeline/.venv-macos/bin/python -m pytest pipeline/tests -q
........................................................................ [ 15%]
........................................................................ [ 31%]
..................................................... [ 43%]
........................................................................ [ 59%]
........................................................................ [ 74%]
........................................................................ [ 90%]
..........................................                               [100%]
455 passed, 19 subtests passed in 27.93s
EXIT 0; Laufzeit 28.53 s
```

```text
pipeline/.venv-macos/bin/python pipeline/scripts/import_editorial_patch.py --source pipeline/out/business_email_batch_4_v1/pack.json --create editorial_review/business_email_batch_5/editorial_content_v2.json --display-patch editorial_review/business_email_batch_5/deck_display_patch.json --registry pipeline/data/words/en.business_email_batch_5_context_v1.json --out pipeline/out/business_email_batch_5_v1
{
  "status": "ok",
  "internal_test_pack": true,
  "ai_calls": 0,
  "ai_cost_usd": 0,
  "sqlite_counts": {
    "languages": 1,
    "lemmas": 4897,
    "senses": 6620,
    "cards": 3672,
    "dictionary_forms": 7920,
    "decks": 14,
    "deck_cards": 3565,
    "deck_words": 3461,
    "word_aliases": 37,
    "sentences": 4206,
    "sentence_tokens": 45933,
    "card_sentences": 4200,
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
  "sha256": "41ea3bc7fc79674f33e5caef09d22a56fb1163ff66d743c3555fcf86d21a35a3"
}
EXIT 0; Laufzeit 18.51 s
```

```text
pipeline/.venv-macos/bin/python build/business_email_batch_5_checks/export_audit.py
PRESERVED pick out {"ref": "pick out/VERB|pick-out#wiedererkennen", "lemma": "pick out/VERB", "sense_key": "pick-out#wiedererkennen", "gloss_de": "wiedererkennen", "definition_de": "Eine bestimmte Person oder Sache in einer größeren Menge erkennen."}
PRESERVED pull over {"ref": "pull over/VERB|pull-over#rechts-ranfahren", "lemma": "pull over/VERB", "sense_key": "pull-over#rechts-ranfahren", "gloss_de": "rechts ranfahren", "definition_de": "Mit einem Fahrzeug an den Straßenrand fahren und dort anhalten."}
Business existing positions changed 0
{
  "status": "PASS",
  "old_business_positions_changed": 0,
  "tables": {
    "languages": 1,
    "lemmas": 4897,
    "senses": 6620,
    "cards": 3672,
    "dictionary_forms": 7920,
    "decks": 14,
    "deck_cards": 3565,
    "deck_words": 3461,
    "word_aliases": 37,
    "sentences": 4206,
    "sentence_tokens": 45933,
    "card_sentences": 4200,
    "stories": 1,
    "story_sentences": 6,
    "exercises": 0,
    "grammar_rules": 0,
    "audio
[gekürzt; vollständiger Output im Log]
  {
      "card": "worksheet|worksheet/NOUN|worksheet#tabellenblatt",
      "level": "warn",
      "rule": "i+1",
      "message": "'spreadsheet'/'spreadsheet' Zipf 3.31 below 3.5"
    }
  ],
  "errors": 0,
  "sha256": {
    "pack.json": "065a2826e1c612f21bd1dc8d3e1d0dc0251a6e092f5a6e874c20f6ec697c4800",
    "content.sqlite": "41ea3bc7fc79674f33e5caef09d22a56fb1163ff66d743c3555fcf86d21a35a3",
    "finalization_report.json": "ada063866c60de037e6098c9e096906ae89d6693017eb99de9e55bed9a9234ec"
  }
}
EXIT 0; Laufzeit 2.8 s
```

```text
pipeline/.venv-macos/bin/python build/business_email_batch_5_checks/review_record.py
PASS 96 pairs /1127 tokens; 0 binding corrections; 4 literal alternatives; 8 inherited gloss comparisons; all old SQL rows including positions unchanged.
EXIT 0; Laufzeit 0.57 s
```

```text
python3 build/business_email_batch_5_checks/backup_before_stage.py
{
  "status": "PASS",
  "time_utc": "2026-10-14T09:52:26.566986+00:00",
  "hashes": {
    "content.sqlite": "45209632ff07df2c06a203c684bef680e7fb66d58b455f107f8745c166264ae4",
    "content.manifest.json": "ad74a809cc315d7a7d062ef3442e9db3300e9401d46fba814b901597fa0ed518"
  },
  "before_staging": true
}
EXIT 0; Laufzeit 0.07 s
```

```text
dart run tool/stage_content_pack.dart --from pipeline/out/business_email_batch_5_v1
staged assets/content/en/content.sqlite
  version business_email_batch_5_v1, schema 4, 22831104 bytes
  sha256 41ea3bc7fc79674f33e5caef09d22a56fb1163ff66d743c3555fcf86d21a35a3
  22 table counts match finalization_report.json
  INTERNES TEST-PACK: own devices and selected testers only, no public content release
Running build hooks...Running build hooks...
EXIT 0; Laufzeit 68.21 s
```

```text
dart run tool/stage_content_pack.dart --verify
verified assets/content/en/content.sqlite
  version business_email_batch_5_v1, schema 4, 22831104 bytes
  sha256 41ea3bc7fc79674f33e5caef09d22a56fb1163ff66d743c3555fcf86d21a35a3
  22 table counts match finalization_report.json
  INTERNES TEST-PACK: own devices and selected testers only, no public content release
Running build hooks...Running build hooks...
EXIT 0; Laufzeit 35.37 s
```

```text
dart run tool/report_learning_groups.dart pipeline/out/business_email_batch_5_v1/content.sqlite
{
  "business-email": {
    "raw_words": 483,
    "learning_targets": 483,
    "lexical_words": 483,
    "form_memberships": 0
  },
  "mixed": {
    "raw_words": 3639,
    "learning_targets": 3558,
    "lexical_words": 3287,
    "form_memberships": 402
  }
}
EXIT 0; Laufzeit 39.93 s
```

```text
flutter analyze --no-pub
Analyzing sprachapp...
No issues found! (ran in 3.9s)
EXIT 0; Laufzeit 4.81 s
```

```text
flutter test --no-pub test/data/real_pack_test.dart
00:00 +0: loading /Users/ardasayar/Documents/FlutterProjekte/sprachapp/test/data/real_pack_test.dart
00:00 +0: staged pack: all cards and sentence links readable, read-only
00:34 +0 -1: staged pack: all cards and sentence links readable, read-only [E]
  TimeoutException after 0:00:30.000000: Test timed out after 30 seconds. See https://pub.dev/packages/test#timeouts
  dart:isolate  _RawReceivePort._handleMessage

00:34 +0 -1: Some tests failed.

Failing tests:
  /Users/ardasayar/Documents/FlutterProjekte/sprachapp/test/data/real_pack_test.dart: staged pack: all cards and sentence links readable, read-only
EXIT 1; Laufzeit 37.45 s
```

```text
flutter test --no-pub --timeout 3m test/data/real_pack_test.dart
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
deck business-email: 483 learning targets, 483 ownership cards, 483 fixed sentence assignments verified
pack business_email_batch_5_v1 (schema 4, internal: true); 14 decks: 3461 cards, 3672 card sentences, 201 with valid_alternatives, 3672 cards in the pack
02:01 +1: All tests passed!
EXIT 0; Laufzeit 124.6 s
```

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
EXIT 0; Laufzeit 0.1 s
```

```text
pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --selection pipeline/data/selection/business_email_v2.json --batch 6 --prepare-continuation business_email_batch_6_context_v1
{
  "snapshots": "PASS",
  "paths": {
    "selection": "pipeline/data/selection/business_email_batch_6_context_v1.json",
    "registry": "pipeline/data/words/en.business_email_batch_6_context_v1.json",
    "groups": "pipeline/data/learning_groups/en.business_email_batch_6_context_v1.json"
  },
  "partition_counts": {
    "imported": 483,
    "current": 96,
    "future": 0
  }
}
EXIT 0; Laufzeit 11.82 s
```

```text
pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --selection pipeline/data/selection/business_email_batch_6_context_v1.json --batch 6 --out build/business_email_authoring_batch_6.zip
{
  "export": "PASS",
  "selected": 579,
  "excluded": 278,
  "partition_counts": {
    "imported": 483,
    "current": 96,
    "future": 0
  },
  "reused_proposed_senses": 6
}
EXIT 0; Laufzeit 11.98 s
```

```text
pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --verify-zip build/business_email_authoring_batch_6.zip
{
  "zip_verification": "PASS",
  "zip_sha256": "977943172521f8324d4533d52d20d4227c2e412afe0d0d4ab422136e5dc796ea",
  "hashed_files": 83,
  "sqlite_tables": 22,
  "sqlite_cards": 3672,
  "selected": 579,
  "excluded": 278,
  "partition_counts": {
    "imported": 483,
    "current": 96,
    "future": 0
  },
  "reused_proposed_senses": 6
}
EXIT 0; Laufzeit 9.89 s
```

```text
python3 build/business_email_batch_5_checks/final_audit.py
{
  "status": "PASS",
  "baseline_files": 3150,
  "changed_existing_files": [
    "assets/content/en/content.manifest.json",
    "assets/content/en/content.sqlite"
  ],
  "all_original_selection_entries_and_exclusions_equal": true,
  "batch_6": {
    "partition": {
      "imported": 483,
      "current": 96,
      "future": 0
    },
    "display_rows": 579,
    "zip_bytes": 27287798,
    "uncompressed_bytes": 84384893,
    "hashed_files": 83
  },
  "hashes": {
    "build/business_email_authoring_batch_6.zip": "977943172521f8324d4533d52d20d4227c2e412afe0d0d4ab422136e5dc796ea",
    "assets/content/en/content.manifest.json": "9ea5c73a0d57168ff55dd6fed6455890e2efa673db77ea40fabf97279909cb4e",
    "pipeline/data/selection/business_email_batch_6_context_v1.json": "a68da9f1708c687f50f80d6d0496f7b00d2b8d8a38b2b0715c29ecf5c6bd6922",
    "pipeline/data/words/en.business_email_batch_6_context_v1.json": "5d2bf5aff2666af3ef46f54b0829aae1ff6d9f66a43eddca81e6398016858824",
    "pipeline/data/learning_groups/en.business_email_batch_6_context_v1.json": "34439979dbefced068d9a7d05b01ba3ad2813b4ab8e30a2f4e7ef511c7a1c12e"
  }
}
EXIT 0; Laufzeit 2.76 s
```

```text
git diff --check
[keine Ausgabe]
EXIT 0; Laufzeit 0.03 s
```

## Grenzen, Altbefunde und Isolation

Keine fehlgeschlagene Import-/ZIP-Inhaltsvalidierung. Eine read-only Prozessstatussondierung mit ps wurde von der Sandbox verweigert (Exit 1); die anschließend erlaubte Statusabfrage hatte Exit 0. Kein Stage-Abbruch und keine Änderung von Prüfregeln. Der Standard-Pack-Lesetest scheiterte am Timeout; keine unveränderte Wiederholung. Der gesonderte Lauf mit erweitertem Zeitbudget ist ausschließlich diagnostisch. Die bekannte Manifestlücke ist unabhängig abgesichert, ohne Lieferdateien zu ändern.

Regelvorschlag, ohne Änderung von AGENTS.md: **WENN ein Standard-Pack-Test wiederholt ausläuft → NIE einen Lauf mit erhöhtem Zeitbudget als Behebung oder Standard-PASS ausgeben.**

GitNexus-Index neun Commits hinter Ausgangs-HEAD. Impact vor Änderungen: NEXTSTEPS null aufgelöste Caller/Prozesse und **UNKNOWN**; neue Dokument-/Kontextdateien sowie Asset nicht indexiert, ebenfalls **UNKNOWN**. Keine HIGH/CRITICAL-Warnung. UNKNOWN ist keine Freigabe; aktuelle unveränderte Quellverträge und vollständige Inhalts-/Bestands-/App-Prüfungen ergänzen die begrenzte Graphsicht. Kein Produktionssymbol editiert. Rohbeleg `gitnexus-preflight.json`; Änderungsprüfung vor Commit separat protokolliert.

Repositoryweiter Whitespacecheck siehe tatsächliches Ergebnis oben. Historische Altbefunde in DESIGN.md:162–164 und älteren Alltag-Zuhause-/Arbeit-Bildung-Berichten bleiben getrennt; keine pauschale Whitespace-/CRLF-Bereinigung. Eigene Dateien zusätzlich direkt und über gezielten Git-Diff geprüft.

Isolierter Commit ausschließlich neuer Bericht und drei Batch-6-Kontexte. Vorbestehend geändertes NEXTSTEPS und die neue bytegleiche Liefer-Arbeitskopie bleiben lokal. Pack/Assets/ZIP/Prüfbelege gemäß Repository-Konvention gitignoriert, keine erzwungene Aufnahme. Keine fremden Anteile oder historischen Lieferungen gestagt, kein Push.

Nächste Aktion: **96 aktuelle Business-Batch-6-Ziele anhand der geprüften ZIP im Chat redigieren.** Altglossen/Labelbefunde, frühere Timeoutursachen und öffentliche Inhaltsfreigabe bleiben offen.

## Ergänzende Abnahme

Der diagnostische Drei-Minuten-Lauf bestätigt alle 14 Stapel, 3672 feste Satzzuordnungen und 201 Verknüpfungen mit geprüften Alternativen. Keine Assertion schlug fehl. Der Standardlauf dauerte 37,45 Sekunden insgesamt und scheiterte am internen 30-Sekunden-Budget; keine unveränderte Wiederholung. Testdatei, Installer und ContentDatabase sind hashgleich zur Ausgangsbasis. Die Timeoutursache bleibt ungelöst; keine Performance-Reparatur vorgenommen.

GitNexus `detect_changes(scope="all")`: 4 indexierte NEXTSTEPS-Abschnitte, 0 ermittelte Prozesse. `scope="staged"`: exakt 4 neue Dateien, 0 zugeordnete Symbole/Prozesse; keine partial-/truncated-Markierung. Das ist fehlende Symbolabdeckung der neuen Inhaltsdateien, keine Graph-Freigabe. Aktuelle Verträge, vollständiger Bestands-/Tabellenabgleich und ZIP-Verifier liefern die konkrete Inhaltsprüfung. Ausgangsindex leer; ausschließlich Bericht und die drei neuen Kontexte vorgemerkt. Direkter Whitespacecheck der vier neuen Dateien und gezielter git diff --check: PASS, Exit 0.
