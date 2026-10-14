# Business & E-Mail – Batch 4: Offline-Import und offener Standard-Testtimeout

Stand: 14.10.2026. **96 neue /387 gesamte Business-Ziele** als `business_email_batch_4_v1` importiert und intern gestagt. Vorhandene App-Projektion: **3576 Karten, 14 Stapel, 3462 Übungen /3191 lexikalische Ziele**. **Standard-App-Testabnahme offen:** zwei isolierte Läufe scheiterten am 30-Sekunden-Timeout. Import, Staging und ZIP-Prüfung sind erfolgreich; der gesonderte Drei-Minuten-Lauf ist eine Diagnose. Technische Abnahme und öffentliche Inhaltsfreigabe bleiben getrennt. Keine Geräteabnahme oder unabhängige menschliche Sprachfreigabe, keine Cloud-/Modellaufrufe, Paketinstallationen, Produktions-/Testcodeänderungen oder echte user.db.

## Basis, Lieferung und Bestandsschutz

Originalauswahl `pipeline/data/selection/business_email_v2.json`; Kontext `pipeline/data/selection/business_email_batch_4_context_v1.json`, Registry `pipeline/data/words/en.business_email_batch_4_context_v1.json`, Lerngruppen `pipeline/data/learning_groups/en.business_email_batch_4_context_v1.json`. Auswahl-ID `business_email_v2`, historische Eintrags-IDs `business-email-v1-####` unverändert. Basis: `pipeline/out/business_email_batch_3_v1/{pack.json,content.sqlite}`, Schema 4; Asset und Manifest entsprechen der geprüften Batch-3-Basis.

Original-ZIP `/Users/ardasayar/Downloads/business_email_batch_4_lieferung.zip` erneut geöffnet: CRCs, eindeutige sichere Pfade, **33 manifestierte Dateihashes** geprüft. Vorhandene Entpackung `business_email_batch_4/` bytegleich. Erst nach erfolgreicher Lieferprüfung bytegleiche Arbeitskopie `editorial_review/business_email_batch_4/` angelegt und unverändert für den Import verwendet. Keine mitgelieferten authoring_evidence-Skripte ausgeführt.

**Manifestlücke wie in Batch 3:** `reference/manifest.json` fehlt als einzige zusätzliche Inhaltsdatei in der Lieferdateiliste. Diese Datei und alle übrigen Referenzdateien separat bytegenau an die bekannte geprüfte `build/business_email_authoring_batch_4.zip` gebunden, Gesamt-SHA256 `18798209b4029ed77a4cd8e111c154c0502dc2e6235d4170ec79e47861e8be5c`. Keine Originaldatei oder Validierungsregel geändert.

Ausgangspartition **291 importiert /96 aktuell /192 später**. Gesamtumfang **579 Ziele /43 E-Mail-Ziele**, Batches **97/97/97/96/96/96**, 278 ausgeschlossene Kandidaten unverändert. Keine Auffüllung, keine neue Kategorie. Die Fortsetzung erhält sämtliche Einträge, Definitionen und Ausschlüsse objektgleich.

Ausgangs-HEAD `eb25069eecce6e16f67c83f8fd47e458d9cb1643`, Index leer. Baseline: **3078 Dateien**, einschließlich vorbestehender untracked Lieferungen. Bereits gelesene Verträge, Importer, Exporter und Stage-Werkzeug hashgleich zum vorherigen Prüfstand; AGENTS, CLAUDE, NEXTSTEPS und Batch-3-Abnahme berücksichtigt. Vorbestehende Änderungen/Fremddateien erhalten. NEXTSTEPS war bereits geändert und bleibt außerhalb des isolierten Commits.

## Redaktionelle Prüfung

Alle **96 Satzpaare, Zieldefinitionen, 1128 Tokenpositionen** vollständig gegengelesen, einschließlich **1018 Wort-/Ausdruckstokens und 110 Satzzeichen**. Neue Begleitwortdefinitionen und 156 neue Formglossen gelesen. Keine belegte Lieferkorrektur erforderlich; Satztexte, Übersetzungen, Zielidentitäten und Reviewhashes unverändert. Exakt ein fester Satz je Ziel; alle Mehrwortziele mit zusammenhängender Lücke. `accepted` enthält ausschließlich die jeweilige Zielform. Vollständiger Einzelbeleg `editorial-review.json` mit Satzpaaren, Tokenzahlen und Hashes; redaktionelle Modellprüfung, keine menschliche Zertifizierung.

Besonders geprüft: business in business trip bezeichnet geschäftliche Tätigkeit; code bei invalid die Rabattkennung. charges bei small print = charge/NOUN Entgelt, bei unit = charge/VERB berechnen. made bei contribution = Beitrag leisten, bei revenue = Gewinn erzielen. group bei subsidiary = Unternehmensgruppe; groups bei pay gap = Personengruppen. recording enthält ausdrücklich job interview. settings bleibt `settings/NOUN|settings#einstellungen`, keine Umdeutung auf den älteren Begleitwort-Sense `setting/NOUN|setting#programmeinstellung`. to-Präpositionen/Infinitivmarker und Verbgerundien mit direkten Objekten geprüft. issue in statement passt zur vorhandenen Definition „Ein offizielles Dokument anfertigen und herausgeben“; careful und appear ebenfalls anhand ihrer vorhandenen Definitionen geprüft, keine globale Glossenänderung.

**pay rise → pay raise** wörtlich in „Sara requested a pay raise after accepting more responsibility at work.“ eingesetzt und gelesen: dieselbe Gehaltserhöhung, passende Übersetzung. Einzige Alternative, satzgebunden und lernstandsneutral. Gegen alle 579 Ziele, Reservierungen, Registry, Bestandskarten sowie Besitz-/Synonymaliase geprüft; keine Kollision und keine neue word_aliases-Zeile. Keine automatische Antwortfreigabe aus Gruppenaliasen.

Drei zukünftige Ziele nur als Begleitwörter, ohne vorzeitige Lernkarte; exakt reservierte Definitionen:

- `venue/NOUN|venue#veranstaltungsort`: Ort, an dem eine Veranstaltung stattfinden soll.
- `profit/NOUN|profit#gewinn`: Nach Abzug der Kosten verbleibender Überschuss.
- `browser/NOUN|browser#webbrowser`: Programm zum Aufrufen und Darstellen von Webseiten.

Vier aktuelle Altglossenvergleiche, keine abschließende Fehlerliste. Alle angegebenen Bestandszeilen exakt bestätigt und erhalten:

| Form | Bestands-Formglosse | Kontextvergleich |
|---|---|---|
| training | Trainings | Schulung |
| reduce | Einkochen | verringern |
| lower | untere; niedriger gelegene | niedriger |
| follow | folgen Sie | befolgen |

Auch sämtliche früheren Pilot-/Batch-/Label-/Glossenbefunde einschließlich no-show bleiben offen. Keine globale Korrektur.

## Import, Bestand und 22 Tabellen

Vorhandener V2-Create-Importer auf Schema-4-Basis, explizite Registry und hashgebundener Display-Patch. Neue Mitgliedschaften zunächst **292–387**, anschließend ausschließlich Business-Anzeige **1–387**. **0 alte Positionswerte geändert**; Originalpositionen, IDs, Eigentümer und Lerngruppen unverändert. Neues Ausgabeverzeichnis, kein Überschreiben und kein neuer Stapel.

Export-SQLite geschlossen und erneut schreibgeschützt geöffnet; sämtliche **22 Tabellen** vollständig gegen `build_rows`/vorhandenes `check_sqlite` verglichen. Exportgeneriertes `content_releases.created_at` gemäß bestehendem Vertrag vom exakten Wertvergleich ausgenommen; Vorhandensein geprüft. Alle Altzeilen der übrigen 21 Tabellen einschließlich Positionen erhalten: **3480 Karten, 4014 Sätze, 43678 Tokens, 7611 Dictionary-Zeilen**. Nur Release/Registry autorisiert fortgeschrieben.

| Tabelle | Gesamtzeilen |
|---|---:|
| languages | 1 |
| lemmas | 4783 |
| senses | 6487 |
| cards | 3576 |
| dictionary_forms | 7767 |
| decks | 14 |
| deck_cards | 3469 |
| deck_words | 3365 |
| word_aliases | 37 |
| sentences | 4110 |
| sentence_tokens | 44806 |
| card_sentences | 4104 |
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

App-Zähler tatsächlich mit `tool/report_learning_groups.dart` ermittelt: **Business 387, global 3462 Übungen /3191 Wörter**. 3576 physische Karten und 3365 Besitzzeilen sind keine alternativen Wortzähler; Formübungen zählen ein Lemma nicht dreimal.

Linter **0 Fehler /493 Hinweise**: **488 alte Befunde** unverändert plus:

- `local copy`: 'disconnect'/'disconnecting' Zipf 3.46 below 3.5.
- `help desk`: 'login'/'login' Zipf 3.49 below 3.5.
- `misleading`: 'advert'/'advert' Zipf 3.46 below 3.5.
- `ahead of schedule`: 'reopen'/'reopened' Zipf 3.49 below 3.5.
- `duplicate`: 'invoice'/'invoice' Zipf 3.27 below 3.5.

## Sicherung, Tests und Batch 5

Asset/Manifest **vor Staging** bytegleich gesichert unter `build/business_email_batch_4_checks/backup/`, UTC-Zeit `2026-10-14T08:41:28.394150+00:00`. Erst danach internes Staging und separater `--verify`; neues Asset bytegleich zur Export-SQLite. 455 Pipeline-Tests plus 19 Untertests bestanden. Flutter-Analyse ohne Paketauflösung und exakter bestehender Pack-Lesetest `test/data/real_pack_test.dart` mit tatsächlichen Outputs unten. Lesetest isoliert von anderen Dart-/Flutter-Jobs; Keine Quelldatei oder Assertion verändert; zwei Standardläufe mit 30-Sekunden-Limit scheiterten. Ein gesonderter diagnostischer Lauf verwendet ausdrücklich --timeout 3m, ohne den Standardbefund zu ersetzen. Frühere Batch-2-/Batch-3-Timeoutursachen bleiben ungeklärt; ein Wiederholungserfolg ist keine Ursachenbehebung.

Die vorhandene `--help` und Pfadbildung des Exporters wurden geprüft. Vor Erzeugung festgelegte neue Dateien, ausschließlich über vorhandenes `--prepare-continuation` aus Originalauswahl v2:

- `pipeline/data/selection/business_email_batch_5_context_v1.json`
- `pipeline/data/words/en.business_email_batch_5_context_v1.json`
- `pipeline/data/learning_groups/en.business_email_batch_5_context_v1.json`

Batch 5: **387 importiert /96 aktuell /96 später**. Geschlossene ZIP erneut geöffnet: **83 Hashdateien, CRCs, Referenzen, 22 Quelltabellen** geprüft. Eingebundene pack.json/SQLite bytegleich zu geprüftem neuem Export/Asset. Kombinierte Anzeigeabbildung **483 eindeutige Zeilen 1–483**. Keine Batch-5-Karten oder Sätze erzeugt. Alle Originalauswahlentscheidungen erhalten.

ZIP-Größe: **26946197 komprimierte /82857350 unkomprimierte Bytes**.

Pack: `/Users/ardasayar/Documents/FlutterProjekte/sprachapp/pipeline/out/business_email_batch_4_v1/`

Upload-ZIP: `/Users/ardasayar/Documents/FlutterProjekte/sprachapp/build/business_email_authoring_batch_5.zip`

## Hashnachweise

Rohbyte-SHA256, sofern nicht als kanonischer JSON-Digest bezeichnet:

| Objekt | SHA256 |
|---|---|
| Original-Liefer-ZIP | `2788d7246c70ecec1493d4e1c39db5eff019eeaf51bfe256e670f78b8ab40c44` |
| Create (Original/Arbeitskopie) | `f29724a60780d353ea3be957a8f05c93889f09f7271d355c1feda71ffe294932` |
| Basis pack.json | `08487c7c2c257a5fe25441d13fa2354d8126cefabfdc226435b52bd9ca7e9935` |
| Registry (kanonisch) | `fb86c440d375bd0d4b5df913e009725a049f2f7efdea40d9a9bb18a4dd952357` |
| Lerngruppen (kanonisch) | `76b62d32e2851ad4a2c3e0cf7a920fbb0892b9f0ec88e74b30a2c6fd3a62e34c` |
| Backup content.sqlite | `021bbc05aa8b0f283fe6b7911a3a928b5ccedf6316af397e3ddf2309afee6e52` |
| Backup content.manifest.json | `0f929a97825a86d8f9e21c514998d9ad01ba07922de567a5ec28e12b9ed48322` |
| Export pack.json | `287b99c11a55de8df5634e27e90d623eaa7655fed20d6d12ff8fa268768fcdcc` |
| Export content.sqlite | `45209632ff07df2c06a203c684bef680e7fb66d58b455f107f8745c166264ae4` |
| Export finalization_report.json | `8cc385e0e871459abb501a9ae99f6e607c3e00ae65bad92ffffca12e07fb12fd` |
| build/business_email_authoring_batch_5.zip | `a04a6a3fa3a0f11cb8a4f32e464064ec035b080cbd655df4776aaa4397cb7156` |
| assets/content/en/content.manifest.json | `ad74a809cc315d7a7d062ef3442e9db3300e9401d46fba814b901597fa0ed518` |
| pipeline/data/selection/business_email_batch_5_context_v1.json | `7e59e370f0011abb5b0864f8043f9cf864cbd5d941878c5e37cf4468185eb5e0` |
| pipeline/data/words/en.business_email_batch_5_context_v1.json | `62a4d5159a0a8440b9643a3bb9aabaec274a516225a3cbea4063cacb093635db` |
| pipeline/data/learning_groups/en.business_email_batch_5_context_v1.json | `b9de70e78a1dbf49dc17461b0d446834d2950c932fef02aa971368e3dafcd2a8` |

## Tatsächliche Befehle und Outputs

Ab Repository-Root auf macOS. Windows PowerShell: Pythonpfad `.\pipeline\.venv\Scripts\python.exe`; übrige Argumente gleich. Dart/Flutter/Git plattformgleich. Wrapper `build/business_email_batch_4_checks/run_check.py NAME BEFEHL …` speichert vollständige Ausgabe in `NAME.log` und Befehl, Exitcode, Laufzeit in `NAME.command.json`. Nachfolgende Auszüge gekürzt; vollständige Belege im Prüfverzeichnis.

```text
pipeline/.venv-macos/bin/python build/business_email_batch_4_checks/baseline.py
status-before.txt 0  M NEXTSTEPS.md
?? alltagssprache_redewendungen_batch_3/
?? alltagssprache_redewendungen_batch_4/
?? alltagssprache_redewendungen_batch_5/
?? business_email_batch_1/
?? business_email_batch_2/
?? business_email_batch_3/
?? business_email_batch_4/
?? docs/alltagssprache-redewendungen-batch-3-import.md
?? docs/alltagssprache-redewendungen-batch-4-import.md
?? docs/codebase-overview-planning.md
?? editorial_review/business_email_batch_3/
?? pipeline/data/learning_groups/en.alltagssprache_redewendungen_batch_4_context_v2.json
?? pipeline/data/learning_groups/en.alltagssprache_redewendungen_batch_5_context_v2.json
?? pipeline/data/selection/alltagssprache_redewendungen_batch_4_context_v2.json
?? pipeline/data/selection/alltagssprache_redewendungen_batch_5_context_v2.json
?? pipeline/data/words/en.alltagssprache_redewendungen_batch_4_context_v2.json
?? pipeline/data/words/en.alltagssprache_redewendungen_batch_5_context_v2.json
?? verbalphrasen_batch_1/
?? "verbalphrasen_batch_2 2/"

index-before.txt 0
head.txt 0 eb25069eecce6e16f67c83f8fd47e458d9cb1643

baseline_files 3078
EXIT 0
```

```text
pipeline/.venv-macos/bin/python build/business_email_batch_4_checks/delivery_audit.py
{
  "status": "PASS",
  "manifest_exception": "reference/manifest.json unlisted in delivery manifest; separately byte-identical to previous verified authoring ZIP bound by known full ZIP SHA256",
  "delivery_zip": "/Users/ardasayar/Downloads/business_email_batch_4_lieferung.zip",
  "zip_sha256": "2788d7246c70ecec1493d4e1c39db5eff019eeaf51bfe256e670f78b8ab40c44",
  "create_sha256": "f29724a60780d353ea3be957a8f05c93889f09f7271d355c1feda71ffe294932",
  "manifest_files": 33,
  "all_local_files_match_zip": true,
  "source_json_sha256": "08487c7c2c257a5fe25441d13fa2354d8126cefabfdc226435b52bd9ca7e9935",
  "registry_digest": "fb86c440d375bd0d4b5df913e009725a049f2f7efdea40d9a9bb18a4dd952357",
  "groups_digest": "76b62d32e2851ad4a2c3e0cf7a920fbb0892b9f0ec88e74b30a2c6fd3a62e34c",
  "current": 96,
  "total": 579,
  "words": 1018,
  "punctuation": 110,
  "alternatives": [
    [
      "pay rise|pay rise/NOUN|pay-rise#gehaltserhohung",
      "pay raise"
    ]
  ],
  "future_companion_senses": [
    {
      "form": "venue",
      "sense": "venue/NOUN|venue#veranstaltungsort",
      "definition_de": "Ort, an dem eine Veranstaltung stattfinden soll.",
      "card_added": false
    },
    {
      "form": "profit",
      "sense": "profit/NOUN|profit#gewinn",
      "definition_de": "Nach Abzug der Kosten verbleibender Überschuss.",
      "card_added": false
    },
    {
      "form": "browser",
      "sense": "browser/NOUN|browser#webbrowser",
      "definition_de": "Programm zum Aufrufen und Darstellen von Webseiten.",
      "card_added": false
    }
  ],
  "add_counts": {
    "lemmas": 109,
    "senses": 131,
    "cards": 96,
    "decks": 0,
    "deck_cards": 96,
    "deck_words": 96,
    "word_aliases": 0,
    "sentences": 96,
    "sentence_tokens": 1128,
    "dictionary_forms": 156,
    "card_sentences": 96
  }
}
EXIT 0
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
455 passed, 19 subtests passed in 29.36s
EXIT 0
```

```text
pipeline/.venv-macos/bin/python pipeline/scripts/import_editorial_patch.py --source pipeline/out/business_email_batch_3_v1/pack.json --create editorial_review/business_email_batch_4/editorial_content_v2.json --display-patch editorial_review/business_email_batch_4/deck_display_patch.json --registry pipeline/data/words/en.business_email_batch_4_context_v1.json --out pipeline/out/business_email_batch_4_v1
{
  "status": "ok",
  "internal_test_pack": true,
  "ai_calls": 0,
  "ai_cost_usd": 0,
  "sqlite_counts": {
    "languages": 1,
    "lemmas": 4783,
    "senses": 6487,
    "cards": 3576,
    "dictionary_forms": 7767,
    "decks": 14,
    "deck_cards": 3469,
    "deck_words": 3365,
    "word_aliases": 37,
    "sentences": 4110,
    "sentence_tokens": 44806,
    "card_sentences": 4104,
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
  "sha256": "45209632ff07df2c06a203c684bef680e7fb66d58b455f107f8745c166264ae4"
}
EXIT 0
```

```text
pipeline/.venv-macos/bin/python build/business_email_batch_4_checks/export_audit.py
PRESERVED pick out {"ref": "pick out/VERB|pick-out#wiedererkennen", "lemma": "pick out/VERB", "sense_key": "pick-out#wiedererkennen", "gloss_de": "wiedererkennen", "definition_de": "Eine bestimmte Person oder Sache in einer größeren Menge erkennen."}
PRESERVED pull over {"ref": "pull over/VERB|pull-over#rechts-ranfahren", "lemma": "pull over/VERB", "sense_key": "pull-over#rechts-ranfahren", "gloss_de": "rechts ranfahren", "definition_de": "Mit einem Fahrzeug an den Straßenrand fahren und dort anhalten."}
Business existing positions changed 0
{
  "status": "PASS",
  "old_business_positions_changed": 0,
  "tables": {
    "languages": 1,
    "lemmas": 4783,
    "senses": 6487,
    "cards": 3576,
    "dictionary_forms": 7767,
    "decks": 14,
    "deck_cards": 3469,
    "deck_words": 3365,
    "word_aliases": 37,
    "sentences": 4110,
    "sentence_tokens": 44806,
    "card_sentences": 4104,
    "stories": 1,
    "story_sentences": 6,
    "exercises": 0,
    "grammar_rules": 0,
    "audio
[gekürzt; vollständiger Output im Log]
  },
    {
      "card": "duplicate|duplicate/NOUN|duplicate#doppelte-kopie",
      "level": "warn",
      "rule": "i+1",
      "message": "'invoice'/'invoice' Zipf 3.27 below 3.5"
    }
  ],
  "errors": 0,
  "sha256": {
    "pack.json": "287b99c11a55de8df5634e27e90d623eaa7655fed20d6d12ff8fa268768fcdcc",
    "content.sqlite": "45209632ff07df2c06a203c684bef680e7fb66d58b455f107f8745c166264ae4",
    "finalization_report.json": "8cc385e0e871459abb501a9ae99f6e607c3e00ae65bad92ffffca12e07fb12fd"
  }
}
EXIT 0
```

```text
pipeline/.venv-macos/bin/python build/business_email_batch_4_checks/review_record.py
PASS 96 pairs /1128 tokens; 0 binding corrections; 1 literal alternative; 4 inherited gloss comparisons; all old SQL rows including positions unchanged.
EXIT 0
```

```text
pipeline/.venv-macos/bin/python build/business_email_batch_4_checks/backup_before_stage.py
{
  "status": "PASS",
  "time_utc": "2026-10-14T08:41:28.394150+00:00",
  "hashes": {
    "content.sqlite": "021bbc05aa8b0f283fe6b7911a3a928b5ccedf6316af397e3ddf2309afee6e52",
    "content.manifest.json": "0f929a97825a86d8f9e21c514998d9ad01ba07922de567a5ec28e12b9ed48322"
  },
  "before_staging": true
}
EXIT 0
```

```text
dart run tool/stage_content_pack.dart --from pipeline/out/business_email_batch_4_v1
staged assets/content/en/content.sqlite
  version business_email_batch_4_v1, schema 4, 22282240 bytes
  sha256 45209632ff07df2c06a203c684bef680e7fb66d58b455f107f8745c166264ae4
  22 table counts match finalization_report.json
  INTERNES TEST-PACK: own devices and selected testers only, no public content release
Running build hooks...Running build hooks...
EXIT 0
```

```text
dart run tool/stage_content_pack.dart --verify
verified assets/content/en/content.sqlite
  version business_email_batch_4_v1, schema 4, 22282240 bytes
  sha256 45209632ff07df2c06a203c684bef680e7fb66d58b455f107f8745c166264ae4
  22 table counts match finalization_report.json
  INTERNES TEST-PACK: own devices and selected testers only, no public content release
Running build hooks...Running build hooks...
EXIT 0
```

```text
dart run tool/report_learning_groups.dart pipeline/out/business_email_batch_4_v1/content.sqlite
{
  "business-email": {
    "raw_words": 387,
    "learning_targets": 387,
    "lexical_words": 387,
    "form_memberships": 0
  },
  "mixed": {
    "raw_words": 3543,
    "learning_targets": 3462,
    "lexical_words": 3191,
    "form_memberships": 402
  }
}
EXIT 0
```

```text
flutter analyze --no-pub
Analyzing sprachapp...
No issues found! (ran in 3.8s)
EXIT 0
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
EXIT 1
```

```text
flutter test --no-pub test/data/real_pack_test.dart
00:00 +0: loading /Users/ardasayar/Documents/FlutterProjekte/sprachapp/test/data/real_pack_test.dart
00:00 +0: staged pack: all cards and sentence links readable, read-only
00:32 +0 -1: staged pack: all cards and sentence links readable, read-only [E]
  TimeoutException after 0:00:30.000000: Test timed out after 30 seconds. See https://pub.dev/packages/test#timeouts
  dart:isolate  _RawReceivePort._handleMessage

00:32 +0 -1: Some tests failed.

Failing tests:
  /Users/ardasayar/Documents/FlutterProjekte/sprachapp/test/data/real_pack_test.dart: staged pack: all cards and sentence links readable, read-only
EXIT 1
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
deck business-email: 387 learning targets, 387 ownership cards, 387 fixed sentence assignments verified
pack business_email_batch_4_v1 (schema 4, internal: true); 14 decks: 3365 cards, 3576 card sentences, 197 with valid_alternatives, 3576 cards in the pack
01:55 +1: All tests passed!
EXIT 0
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
EXIT 0
```

```text
pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --selection pipeline/data/selection/business_email_v2.json --batch 5 --prepare-continuation business_email_batch_5_context_v1
{
  "snapshots": "PASS",
  "paths": {
    "selection": "pipeline/data/selection/business_email_batch_5_context_v1.json",
    "registry": "pipeline/data/words/en.business_email_batch_5_context_v1.json",
    "groups": "pipeline/data/learning_groups/en.business_email_batch_5_context_v1.json"
  },
  "partition_counts": {
    "imported": 387,
    "current": 96,
    "future": 96
  }
}
EXIT 0
```

```text
pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --selection pipeline/data/selection/business_email_batch_5_context_v1.json --batch 5 --out build/business_email_authoring_batch_5.zip
{
  "export": "PASS",
  "selected": 579,
  "excluded": 278,
  "partition_counts": {
    "imported": 387,
    "current": 96,
    "future": 96
  },
  "reused_proposed_senses": 9
}
EXIT 0
```

```text
pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --verify-zip build/business_email_authoring_batch_5.zip
{
  "zip_verification": "PASS",
  "zip_sha256": "a04a6a3fa3a0f11cb8a4f32e464064ec035b080cbd655df4776aaa4397cb7156",
  "hashed_files": 83,
  "sqlite_tables": 22,
  "sqlite_cards": 3576,
  "selected": 579,
  "excluded": 278,
  "partition_counts": {
    "imported": 387,
    "current": 96,
    "future": 96
  },
  "reused_proposed_senses": 9
}
EXIT 0
```

```text
pipeline/.venv-macos/bin/python build/business_email_batch_4_checks/final_audit.py
{
  "status": "PASS",
  "baseline_files": 3078,
  "changed_existing_files": [
    "assets/content/en/content.manifest.json",
    "assets/content/en/content.sqlite"
  ],
  "all_original_selection_entries_and_exclusions_equal": true,
  "batch_5": {
    "partition": {
      "imported": 387,
      "current": 96,
      "future": 96
    },
    "display_rows": 483,
    "zip_bytes": 26946197,
    "uncompressed_bytes": 82857350,
    "hashed_files": 83
  },
  "hashes": {
    "build/business_email_authoring_batch_5.zip": "a04a6a3fa3a0f11cb8a4f32e464064ec035b080cbd655df4776aaa4397cb7156",
    "assets/content/en/content.manifest.json": "ad74a809cc315d7a7d062ef3442e9db3300e9401d46fba814b901597fa0ed518",
    "pipeline/data/selection/business_email_batch_5_context_v1.json": "7e59e370f0011abb5b0864f8043f9cf864cbd5d941878c5e37cf4468185eb5e0",
    "pipeline/data/words/en.business_email_batch_5_context_v1.json": "62a4d5159a0a8440b9643a3bb9aabaec274a516225a3cbea4063cacb093635db",
    "pipeline/data/learning_groups/en.business_email_batch_5_context_v1.json": "b9de70e78a1dbf49dc17461b0d446834d2950c932fef02aa971368e3dafcd2a8"
  }
}
EXIT 0
```

```text
git diff --check
[keine Ausgabe]
EXIT 0
```

## Grenzen, Altbefunde und Isolation

Die erste Pfadsondierung fand Original-ZIP und vorhandene Root-Entpackung; Exit 1 bezog sich auf die noch nicht vorhandene Arbeitskopie. Keine fehlgeschlagene Import-/ZIP-Inhaltsvalidierung; die Standard-Pack-Lesetests scheiterten jedoch zweimal am Timeout. Der gesonderte Lauf mit erweitertem Zeitbudget ist ausschließlich diagnostisch. Die bekannte Manifestlücke ist unabhängig abgesichert, ohne Lieferdateien zu ändern.

GitNexus-Index acht Commits hinter Ausgangs-HEAD. Impact vor Änderungen: NEXTSTEPS null aufgelöste Caller/Prozesse und **UNKNOWN**; neue Dokument-/Kontextdateien sowie Asset nicht indexiert, ebenfalls **UNKNOWN**. Keine HIGH/CRITICAL-Warnung. UNKNOWN ist keine Freigabe; aktuelle unveränderte Quellverträge und vollständige Inhalts-/Bestands-/App-Prüfungen ergänzen die begrenzte Graphsicht. Kein Produktionssymbol editiert. Rohbeleg `gitnexus-preflight.json`; Änderungsprüfung vor Commit separat protokolliert.

Repositoryweiter Whitespacecheck siehe tatsächliches Ergebnis oben. Historische Altbefunde in DESIGN.md:162–164 und älteren Alltag-Zuhause-/Arbeit-Bildung-Berichten bleiben getrennt; keine pauschale Whitespace-/CRLF-Bereinigung. Eigene Dateien zusätzlich direkt und über gezielten Git-Diff geprüft.

Isolierter Commit ausschließlich neuer Bericht und drei Batch-5-Kontexte. Vorbestehend geändertes NEXTSTEPS und die neue bytegleiche Liefer-Arbeitskopie bleiben lokal. Pack/Assets/ZIP/Prüfbelege gemäß Repository-Konvention gitignoriert, keine erzwungene Aufnahme. Keine fremden Anteile oder historischen Lieferungen gestagt, kein Push.

Nächste Aktion: **96 aktuelle Business-Batch-5-Ziele anhand der geprüften ZIP im Chat redigieren.** Altglossen/Labelbefunde, frühere Timeoutursachen und öffentliche Inhaltsfreigabe bleiben offen.

## Aktueller Testbefund und Abweichung von der Standardabnahme

Zwei isolierte Standardläufe `flutter test --no-pub test/data/real_pack_test.dart` scheiterten mit **Exit 1**, jeweils `TimeoutException after 0:00:30.000000`, ohne gemeldete Inhalts-Assertion. Test, Installer und ContentDatabase sind hashgleich zum vorher geprüften Stand. Nach diesen zwei Fehlversuchen neue Hypothese: die vollständige Packvalidierung überschreitet das Standardzeitbudget. Der bekannte zweifache Öffnungs-/Validierungspfad ist ein möglicher Faktor, aber keine bewiesene Ursache.

Ein gesonderter diagnostischer Lauf desselben Tests mit **`--timeout 3m`** besteht: **`01:55 +1: All tests passed!`, Exit 0**, 14 Stapel, 387 Business-Ziele, 3576 feste aktive Satzzuordnungen, 197 Zuordnungen mit Alternativen. Nur das Zeitbudget dieses CLI-Laufs wurde erweitert; sämtliche Assertions und Quelldateien unverändert. Das ist **kein bestandener Standardlauf und keine Ursachenbehebung**. Die Akzeptanz des App-Lesetests unter Standardzeitlimit bleibt somit offen; erfolgreiche Lieferung, Import, Staging und ZIP-Verifikation bleiben davon getrennt. Kein weiterer Wiederholungslauf.

## Abschließende Änderungsprüfung

GitNexus `detect_changes({repo:"sprachlernapp",scope:"all"})`: fünf Dateien, vier indexierte NEXTSTEPS-Abschnitte, null betroffene Prozesse. `scope:"staged"`: vier neue Dateien, null indexierte Symbole/Prozesse. Gemeldetes Risiko low; keine partial-/truncated-Meldung. Neue Daten/Dokumente sind nicht indexiert; null Symbole bedeutet keine vollständige Graphabdeckung. Rohbeleg `gitnexus-changes.json`.

```text
git diff --check -- NEXTSTEPS.md docs/business-email-batch-4-import.md pipeline/data/selection/business_email_batch_5_context_v1.json pipeline/data/words/en.business_email_batch_5_context_v1.json pipeline/data/learning_groups/en.business_email_batch_5_context_v1.json
[keine Ausgabe]
EXIT 0

git diff --cached --check
[keine Ausgabe]
EXIT 0

git status --short
 M NEXTSTEPS.md
A  docs/business-email-batch-4-import.md
A  pipeline/data/learning_groups/en.business_email_batch_5_context_v1.json
A  pipeline/data/selection/business_email_batch_5_context_v1.json
A  pipeline/data/words/en.business_email_batch_5_context_v1.json
[vorbestehende untracked Dateien unverändert; neue Liefer-Arbeitskopie lokal]
EXIT 0
```

Vollständiger Status in `status-precommit.log`. Zusätzlicher direkter Whitespacecheck aller fünf eigenen Dateien: PASS, LF, keine nachgestellten Leerzeichen; NEXTSTEPS 25 Zeilen. Baseline-Abgleich nach Dokumentänderung: PASS, von 3078 Ausgangsdateien ausschließlich NEXTSTEPS, Asset und Manifest verändert (`final-audit-after-docs.log`). Der Index enthält ausschließlich die vier genannten neuen eigenen Dateien.
