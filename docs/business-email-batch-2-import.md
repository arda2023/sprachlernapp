# Business & E-Mail – Batch 2: Offline-Import und interne Abnahme

Stand: 14.10.2026. **97 neue /194 insgesamt** Business-Ziele als `business_email_batch_2_v1` importiert und intern gestagt. **3383 Karten, 14 Stapel, 3269 Übungen /2998 Wörter** nach tatsächlicher App-Projektion. Keine öffentliche Inhaltsfreigabe, unabhängige menschliche Sprachfreigabe oder Geräteabnahme. Kein App-/Pipeline-/Testcode geändert, keine echte user.db verwendet, keine Cloud-/Modellaufrufe oder Paketinstallationen.

## Eingaben, Lieferung und Ausgangsschutz

Maßgeblich bleiben `pipeline/data/selection/business_email_v2.json` und die Fortsetzung `pipeline/data/selection/business_email_batch_2_context_v1.json`, beide selection_id `business_email_v2`. Registry `pipeline/data/words/en.business_email_batch_2_context_v1.json`; Gruppen `pipeline/data/learning_groups/en.business_email_batch_2_context_v1.json`. Historische v1-Zwischenfassungen nicht verwendet. Basis `pipeline/out/business_email_batch_1_v1/{pack.json,content.sqlite}`, Schema 4. Die gelieferte Referenz ist bytegleich zur geprüften `build/business_email_authoring_batch_2.zip`.

Original-ZIP `/Users/ardasayar/Downloads/business_email_batch_2_lieferung.zip` unverändert; CRCs und **33 Manifestdateien** geprüft. Vorhandener Ordner `business_email_batch_2/` vollständig bytegleich. Die mitgelieferten authoring_evidence-Skripte wurden nicht ausgeführt. Original-Create-Hash im Display-Patch bestätigt.

Vorher **97 importiert /97 aktuell /385 später**, danach Fortsetzung **194/97/288**. Alle **579 Ziele /43 E-Mail-Ziele**, Batches **97/97/97/96/96/96**, 278 Ausschlüsse, Originalpositionen und v2-Auswahlentscheidungen bleiben erhalten. Alle 579 Einträge der Fortsetzung sind objektgleich zur Originalauswahl; keine Auffüllung auf Richtmengen.

Ausgangs-HEAD `965d31367b6c90c8762de04e5fdac6228024048b`, Index leer. Baseline von **2968 Dateien** einschließlich vorbestehender untracked Lieferungen und Änderungen; nur autorisierte Assets und anschließend NEXTSTEPS geändert. Historische Packs, Auswahlen, Registrys, feste Sätze und Instruktionsdateien erhalten. `NEXTSTEPS.md` war bereits geändert und bleibt außerhalb des isolierten Commits.

## Vollständiges Gegenlesen und gezielte Korrekturen

Alle **97 Satzpaare /1099 Tokenpositionen**, davon **996 Wort-/Ausdruckstokens und 103 Satzzeichen**, vollständig gelesen und gegen Tokenizer, Lemma-/Sense-/Dictionary-Bindung, Lücke und Reviewhashes geprüft. Genau ein fester Übungskontext je Ziel, zusammenhängende Vollform-Lücke über lexical_spans, `accepted` exakt `[card.form]`. Englische Texte und deutsche Gesamtübersetzungen sind unverändert.

Drei belegte Wortartkorrekturen ausschließlich in `build/business_email_batch_2_checks/import_copy/editorial_content_v2.json`:

| Satz | Token | Vorher | Korrigiert | Grund |
|---|---|---|---|---|
| business-email-v1-0131-s1 (involve) | planning | planning/NOUN, planning#planung | plan/VERB, plan#planen | Gerundium mit direktem Objekt „the new service“; vorhandenen Verbsense und Formglosse wiederverwenden. |
| business-email-v1-0150-s1 (clause) | either | either/PRON, either#einer-von-beiden | either/DET, either#jeder-von-beiden-begleitend | Begleitet „party“; Determinierer statt alleinstehendem Pronomen. |
| business-email-v1-0189-s1 (dashboard) | today | today/ADV, today#heute | today/NOUN, today#heute | Genitiv „today’s sales“; vorhandenen Nominalsense und Formglosse wiederverwenden. |

Für either genau ein neuer Begleitwort-Lemma-/Sense-/Dictionary-Eintrag, **keine Lernkarte**: Definition „Begleitet ein Nomen im Singular und bezeichnet jede einzelne von zwei Personen oder Sachen, ohne Festlegung auf eine.“ Formglosse „jede (von beiden)“, Rang 2. Die Wortartunterscheidung ist grammatisch begründet; kein künstlicher Sense nur für eine Formübersetzung. Deshalb **126 statt 125 Lemmas, 147 statt 146 Senses, 178 statt 177 Dictionary-Zeilen** im Importdelta. Alle 97 Zielkarten, Satztexte, Übersetzungen und Linkzeilen unverändert.

Token- und Linkhashes mit vorhandenem `import_editorial_patch.digest` erneuert, betroffene Reviewbegründungen ergänzt. Neuer Rohbyte-Create-Hash im separaten `import_copy/deck_display_patch.json` gesetzt; alle übrigen Patchfelder einschließlich Vorherhashes unverändert. Nachweis mit Vorher-/Nachher-Tokens: `corrections.json`; ausführbarer lokaler Korrekturbeleg `correct_delivery.py`. Originale bleiben erhalten.

Bedeutungsabgrenzungen bestätigt: inventory Bestandsverzeichnis; interest Zinsen; allowance monatlicher Geldzuschuss, getrennt vom älteren Urlaubskontingent; review sachliche Durchsicht; gross vor Steuern/Abzügen; model number Produkttyp gegenüber Seriennummer des Einzelgeräts; public sector staatlich/kommunal. charges Verb „berechnen“, help Nomen, rose numerischer Anstieg, opening Betrieb eröffnen, case Vorgang, handle bearbeiten/handhaben, total Adjektiv, account Bankkonto, used gebraucht, when Frageadverb wann. Die zwei to-Tokens bei authenticate sind Empfängerpräposition und Infinitivmarker.

Beide Alternativen wörtlich eingesetzt und gelesen: **organisation → organization**, **standardise → standardize**, jeweils gleiche Aussage und passende Übersetzung. Prüfung gegen alle 579 Ziele, Reservierungen, bestehende Besitzer/Karten, Aliase und Gruppenbindungen ohne Kollision. Keine neue Besitzaliaszeile und keine automatische Antwortfreigabe. Alternativen sind satzgebunden und lernstandsneutral.

Zwei zukünftige Ziele als Begleitwörter: `salesperson/NOUN|salesperson#verkaufskraft` (business-email-v1-0501) und `deposit/NOUN|deposit#anzahlung` (business-email-v1-0299), exakt reservierte Definitionen; keine zukünftige Karte. Fortsetzung erkennt **11 insgesamt wiederverwendbare vorgeschlagene Senses**: neun aus Batch 1 plus diese zwei. Bereits vorhandene Senses gemäß sense_availability wiederverwendet, keine Neudefinition.

Sieben aktuelle Glossenvergleiche separat offen; gemeinsame Altzeilen unverändert:

| Form | Geerbte Glosse | Kontextdarstellung |
|---|---|---|
| received | erhielt | erhalten haben |
| invited | luden ein | lud ein |
| paid | bezahlte; bezahlt | bezahlt / überwiesen |
| software | Software- | Software |
| staff | Mitarbeiter- | Beschäftigte |
| training | Trainings | Schulung |
| attend | am Unterricht teilnehmen | teilnehmen |

Der attend-Sense definiert ausdrücklich Anwesenheit bei Unterricht **oder einer Veranstaltung**; der enge alte Formgloss ist ein Glossenbefund, keine neue Fehlbindung. Frühere Listen einschließlich acht Batch-1-Glossen, no-show-Personen-/Abstraktlabel, Pilotfällen und Verbalphrasen-Auswahllabel bleiben offen. Vollständiger aktueller Einzelprüfnachweis `editorial-review.json` mit 97 Satzpaaren, Tokenzahlen und Hashes; Modellprüfung, keine menschliche Freigabe.

## CLI-Import, Display-Patch und Bestandsschutz

Vorhandener Importer mit expliziter Registry, separater korrigierter Create-Datei und zugehörigem Display-Patch; neues Ausgabeverzeichnis, kein Überschreiben. Kein neuer Stapel. **97 Anhänge auf 98–194**, danach vollständige hashgebundene Anzeigeabbildung 1–194. Die bisherige Reihenfolge passt bereits: **0 alte Positionswerte geändert**. Originalauswahl-/Registrypositionen und alle IDs bleiben erhalten.

Alle **22 SQLite-Tabellen** erneut vollständig zeilen-/spaltenweise mit `build_rows` / `finalize_curation.check_sqlite` abgeglichen. Exportgeneriertes `content_releases.created_at` gemäß bestehendem Vertrag von exaktem Vergleich ausgenommen, Vorhandensein bestätigt. Alle **3286 alten Karten**, 3820 Sätze, 41440 Tokens, 7258 Dictionary-Zeilen sowie alle übrigen Altzeilen der 21 Inhaltstabellen einschließlich Positionswerten vollständig erhalten; Release/Registry autorisiert fortgeschrieben.

| Tabelle | Gesamtzeilen |
|---|---:|
| languages | 1 |
| lemmas | 4544 |
| senses | 6206 |
| cards | 3383 |
| dictionary_forms | 7436 |
| decks | 14 |
| deck_cards | 3276 |
| deck_words | 3172 |
| word_aliases | 37 |
| sentences | 3917 |
| sentence_tokens | 42539 |
| card_sentences | 3911 |
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

Vier Formtabellen byte-/wertgleich: **134 Verbanker, 406 Kartenankerbindungen, 402 Formziele, 402 Formmitgliedschaften**, drei Ansichten mit **134/134/134** Übungen. Beide korrigierten Formglossen exakt erhalten: pick out „aus einer Menge erkennen“, pull over „an den Straßenrand fahren und anhalten“. Keine stillen Altänderungen.

App-Projektion über vorhandenes `tool/report_learning_groups.dart`: **3269 Übungen /2998 Wörter**, Business **194**, 14 Stapel. **3383 Karten** und **3172 Besitzzeilen** sind getrennte Mengen. Formübungen zählen ein Verb nicht dreimal als neues Wort.

Linter **0 Fehler /486 Hinweise**: **480 unveränderte Altbefunde** plus sechs erwartete neue Hinweise:

- `log in`: 'payslip'/'payslip' Zipf 1.65 below 3.5.
- `prospect`: 'salesperson'/'salesperson' Zipf 2.84 below 3.5.
- `bank transfer`: 'invoice'/'invoice' Zipf 3.27 below 3.5.
- `gross`: 'deduction'/'deductions' Zipf 3.46 below 3.5.
- `payslip`: 'deduction'/'deductions' Zipf 3.46 below 3.5.
- `column`: 'spreadsheet'/'spreadsheet' Zipf 3.31 below 3.5.

## Sicherung, Staging und Folge-ZIP

Nach bestandenem Import-/Exportaudit Asset und Manifest **vor Staging** bytegleich unter `build/business_email_batch_2_checks/backup/` gesichert; `backup-proof.json` dokumentiert UTC-Zeit und Ausgangshashes. Erst danach internes Staging und separater Asset-Verifier. Asset bytegleich zur neuen Export-SQLite. Flutter-Analyse ohne Paketauflösung bestanden. Reale Pack-Lesetestläufe und gegebenenfalls Wiederholung sind unten mit tatsächlichem Ergebnis dokumentiert; ausschließlich temporärer Test-Supportpfad, kein echter Lernstand.

Batch-3-Kontexte über vorhandenen Fortsetzungsweg aus Originalauswahl **business_email_v2**, gebunden an den tatsächlich gestagten Pack:

- `pipeline/data/selection/business_email_batch_3_context_v1.json`
- `pipeline/data/words/en.business_email_batch_3_context_v1.json`
- `pipeline/data/learning_groups/en.business_email_batch_3_context_v1.json`

Keine Batch-3-Sätze erstellt. Geschlossene ZIP erneut geöffnet und geprüft: **83 Dateihashes /84 Dateien, CRCs, 22 Quelltabellen, Partition 194/97/288**, vollständige unveränderte 579 Identitäten/Definitionen/Ausschlüsse. **291** eindeutige kombinierte Anzeigezeilen 1–291; `continuation_display_mapping.json` und Importvertrag für den folgenden hashgebundenen `--display-patch` enthalten. Vorhandene Anzeigen werden erst beim nächsten autorisierten Import gemäß Vertrag geändert.

ZIP-Größe: **26271888 komprimierte /79819274 unkomprimierte Bytes**.

Packpfad: `/Users/ardasayar/Documents/FlutterProjekte/sprachapp/pipeline/out/business_email_batch_2_v1/`

Geprüfte Upload-ZIP: `/Users/ardasayar/Documents/FlutterProjekte/sprachapp/build/business_email_authoring_batch_3.zip`

## Hashnachweise

Rohbyte-SHA256 und kanonische JSON-Digests getrennt:

| Objekt | Hash |
|---|---|
| Original-Liefer-ZIP (Rohbytes) | `83e7259fc09da30162d01053fbf9d76ba9d199366c5f15207fbad422c84b6f86` |
| Original-Create (Rohbytes) | `97846c333eff32f0130e282d20afe96bb3fb8e3fcbb6ae1a04ce7df07de1936c` |
| Korrigierter Create (Rohbytes) | `1530019310ccad64ac971175ab9b75760d98afb428234d1d765952a1ac28ad43` |
| Korrigierter Display-Patch (Rohbytes) | `42b2d76c94570645c4c7a4ece6f8af0af375c96361fdb64967518953f5eddbc5` |
| Quell-pack.json (Rohbytes) | `de3a95b42a9b9f4839cd39514fd66811afc2b78fd69967825efd62c6cec856cd` |
| Eingabe-Registry (kanonisch) | `f8ef9948f76df7db88c2c9d031392fc8222bd3c7732120c3c170e60ac97d5980` |
| Eingabe-Lerngruppen (kanonisch) | `445dca652aba12b79eefc7eceaf7a7bfeeeb3f787faab97b77b44a19280be6a1` |
| Backup content.sqlite (Rohbytes) | `e1ecd0ba870afa9a667eef648b75a38285f70ff808007dda982b02e5b93103ed` |
| Backup content.manifest.json (Rohbytes) | `a8424495737bf9fb4174eb98cc144bb85ccfefb9e1bbe336b45ed2afe4e68dc9` |
| Export pack.json (Rohbytes) | `ac413e251f3f7f0d90a3a1d274e1c7b35a6111915b873cb594d861a25783c23f` |
| Export content.sqlite (Rohbytes) | `b0be2ea5696376744a60af18a807c3d5b68591ecf8be4e42cc4300fea8520569` |
| Export finalization_report.json (Rohbytes) | `ed72a4e2a400e9d204d995311cb1472d53a8548467768765993d640376aa141e` |
| build/business_email_authoring_batch_3.zip | `9b1f6caf6465d2e910c0f9cea60293a4fac80b3a9e862e32c8e65b487db35cf8` |
| assets/content/en/content.manifest.json | `6994a984acaa7d9494ae839d058a95f5de81487a5492a175905ce2c4b2e1814e` |
| pipeline/data/selection/business_email_batch_3_context_v1.json | `c5448739963683ac42aa687868adf891cbd3091ea8378ea2bf6d6a0d47d495aa` |
| pipeline/data/words/en.business_email_batch_3_context_v1.json | `76001953fac52d0a5786363b878d3f5447adb912a14abc45fa4e57dc89d518fb` |
| pipeline/data/learning_groups/en.business_email_batch_3_context_v1.json | `b85860c8ab3f67dc711ee3125792ba408ff3a24dd5cdeba0e10f84e40abfceb9` |

## Tatsächliche Befehle, Outputs und Exitcodes

Ab Repository-Root auf macOS. Windows PowerShell: Pythonpfad durch `.\pipeline\.venv\Scripts\python.exe` ersetzen; Dart-, Flutter- und Git-Argumente identisch. Lokaler Wrapper `run_check.py` speichert komplette Ausgaben ohne ANSI-Codes in `<Name>.log` sowie Befehl/Exitcode in `<Name>.command.json` unter `build/business_email_batch_2_checks/`. Hier relevante Auszüge; keine Prüfung durch gelieferten In-Memory-Bericht ersetzt.

### delivery-audit

```text
pipeline/.venv-macos/bin/python build/business_email_batch_2_checks/delivery_audit.py
{
  "status": "PASS",
  "delivery_zip": "/Users/ardasayar/Downloads/business_email_batch_2_lieferung.zip",
  "zip_sha256": "83e7259fc09da30162d01053fbf9d76ba9d199366c5f15207fbad422c84b6f86",
  "create_sha256": "97846c333eff32f0130e282d20afe96bb3fb8e3fcbb6ae1a04ce7df07de1936c",
  "manifest_files": 33,
  "all_local_files_match_zip": true,
  "source_json_sha256": "de3a95b42a9b9f4839cd39514fd66811afc2b78fd69967825efd62c6cec856cd",
  "registry_digest": "f8ef9948f76df7db88c2c9d031392fc8222bd3c7732120c3c170e60ac97d5980",
  "groups_digest": "445dca652aba12b79eefc7eceaf7a7bfeeeb3f787faab97b77b44a19280be6a1",
  "current": 97,
  "total": 579,
  "words": 996,
  "punctuation": 103,
  "alternatives": [
    [
      "organisation|organisation/NOUN|organisation#organisation",
      "organization"
    ],
    [
      "standardise|standardise/VERB|standardise#vereinheitlichen",
      "standardize"
    ]
[gekürzt; vollständiger Nachweis im gleichnamigen Log/JSON]
EXIT 0
```

### corrections

```text
pipeline/.venv-macos/bin/python build/business_email_batch_2_checks/correct_delivery.py
PASS: 3 token bindings; unchanged sentences/cards/links; corrected create 1530019310ccad64ac971175ab9b75760d98afb428234d1d765952a1ac28ad43
EXIT 0
```

### editorial-review

```text
pipeline/.venv-macos/bin/python build/business_email_batch_2_checks/review_record.py
PASS 97 pairs /1099 tokens; 3 binding corrections; 2 literal alternatives; 7 inherited gloss comparisons; all old SQL rows including positions unchanged.
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
455 passed, 19 subtests passed in 30.05s
EXIT 0
```

### import

```text
pipeline/.venv-macos/bin/python pipeline/scripts/import_editorial_patch.py --source pipeline/out/business_email_batch_1_v1/pack.json --create build/business_email_batch_2_checks/import_copy/editorial_content_v2.json --registry pipeline/data/words/en.business_email_batch_2_context_v1.json --display-patch build/business_email_batch_2_checks/import_copy/deck_display_patch.json --out pipeline/out/business_email_batch_2_v1
{
  "status": "ok",
  "internal_test_pack": true,
  "ai_calls": 0,
  "ai_cost_usd": 0,
  "sqlite_counts": {
    "languages": 1,
    "lemmas": 4544,
    "senses": 6206,
    "cards": 3383,
    "dictionary_forms": 7436,
    "decks": 14,
    "deck_cards": 3276,
    "deck_words": 3172,
    "word_aliases": 37,
    "sentences": 3917,
    "sentence_tokens": 42539,
    "card_sentences": 3911,
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
  "sha256": "b0be2ea5696376744a60af18a807c3d5b68591ecf8be4e42cc4300fea8520569"
}
EXIT 0
```

### export-audit

```text
pipeline/.venv-macos/bin/python build/business_email_batch_2_checks/export_audit.py
PRESERVED pick out {"ref": "pick out/VERB|pick-out#wiedererkennen", "lemma": "pick out/VERB", "sense_key": "pick-out#wiedererkennen", "gloss_de": "wiedererkennen", "definition_de": "Eine bestimmte Person oder Sache in einer größeren Menge erkennen."}
PRESERVED pull over {"ref": "pull over/VERB|pull-over#rechts-ranfahren", "lemma": "pull over/VERB", "sense_key": "pull-over#rechts-ranfahren", "gloss_de": "rechts ranfahren", "definition_de": "Mit einem Fahrzeug an den Straßenrand fahren und dort anhalten."}
Business existing positions changed 0
{
  "status": "PASS",
  "old_business_positions_changed": 0,
  "tables": {
    "languages": 1,
    "lemmas": 4544,
    "senses": 6206,
    "cards": 3383,
    "dictionary_forms": 7436,
    "decks": 14,
    "deck_cards": 3276,
    "deck_words": 3172,
    "word_aliases": 37,
    "sentences": 3917,
    "sentence_tokens": 42539,
    "card_sentences": 3911,
    "stories": 1,
    "story_sentences": 6,
    "exercises": 0,
    "grammar_rules": 0,
[gekürzt; vollständiger Nachweis im gleichnamigen Log/JSON]
EXIT 0
```

### backup

```text
pipeline/.venv-macos/bin/python build/business_email_batch_2_checks/backup_before_stage.py
{
  "status": "PASS",
  "time_utc": "2026-10-14T06:05:54.829114+00:00",
  "hashes": {
    "content.sqlite": "e1ecd0ba870afa9a667eef648b75a38285f70ff808007dda982b02e5b93103ed",
    "content.manifest.json": "a8424495737bf9fb4174eb98cc144bb85ccfefb9e1bbe336b45ed2afe4e68dc9"
  },
  "before_staging": true
}
EXIT 0
```

### stage

```text
dart run tool/stage_content_pack.dart --from pipeline/out/business_email_batch_2_v1
staged assets/content/en/content.sqlite
  version business_email_batch_2_v1, schema 4, 21233664 bytes
  sha256 b0be2ea5696376744a60af18a807c3d5b68591ecf8be4e42cc4300fea8520569
  22 table counts match finalization_report.json
  INTERNES TEST-PACK: own devices and selected testers only, no public content release
Running build hooks...Running build hooks...
EXIT 0
```

### stage-verify

```text
dart run tool/stage_content_pack.dart --verify
verified assets/content/en/content.sqlite
  version business_email_batch_2_v1, schema 4, 21233664 bytes
  sha256 b0be2ea5696376744a60af18a807c3d5b68591ecf8be4e42cc4300fea8520569
  22 table counts match finalization_report.json
  INTERNES TEST-PACK: own devices and selected testers only, no public content release
Running build hooks...Running build hooks...
EXIT 0
```

### app-projection

```text
dart run tool/report_learning_groups.dart pipeline/out/business_email_batch_2_v1/content.sqlite
{
  "business-email": {
    "raw_words": 194,
    "learning_targets": 194,
    "lexical_words": 194,
    "form_memberships": 0
  },
  "mixed": {
    "raw_words": 3350,
    "learning_targets": 3269,
    "lexical_words": 2998,
    "form_memberships": 402
  }
}
EXIT 0
```

### flutter-analyze

```text
flutter analyze --no-pub
Analyzing sprachapp...
No issues found! (ran in 5.3s)
EXIT 0
```

### real-pack-test

```text
flutter test --no-pub test/data/real_pack_test.dart
00:00 +0: loading /Users/ardasayar/Documents/FlutterProjekte/sprachapp/test/data/real_pack_test.dart
00:00 +0: staged pack: all cards and sentence links readable, read-only
00:30 +0 -1: staged pack: all cards and sentence links readable, read-only [E]
  TimeoutException after 0:00:30.000000: Test timed out after 30 seconds. See https://pub.dev/packages/test#timeouts
  dart:isolate  _RawReceivePort._handleMessage

00:30 +0 -1: Some tests failed.

Failing tests:
  /Users/ardasayar/Documents/FlutterProjekte/sprachapp/test/data/real_pack_test.dart: staged pack: all cards and sentence links readable, read-only
EXIT 1
```

### real-pack-test-isolated

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
deck business-email: 194 learning targets, 194 ownership cards, 194 fixed sentence assignments verified
pack business_email_batch_2_v1 (schema 4, internal: true); 14 decks: 3172 cards, 3383 card sentences, 192 with valid_alternatives, 3383 cards in the pack
01:38 +1: All tests passed!
EXIT 0
```

### continuation

```text
pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --selection pipeline/data/selection/business_email_v2.json --batch 3 --prepare-continuation business_email_batch_3_context_v1
{
  "snapshots": "PASS",
  "paths": {
    "selection": "pipeline/data/selection/business_email_batch_3_context_v1.json",
    "registry": "pipeline/data/words/en.business_email_batch_3_context_v1.json",
    "groups": "pipeline/data/learning_groups/en.business_email_batch_3_context_v1.json"
  },
  "partition_counts": {
    "imported": 194,
    "current": 97,
    "future": 288
  }
}
EXIT 0
```

### zip-export

```text
pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --selection pipeline/data/selection/business_email_batch_3_context_v1.json --batch 3 --out build/business_email_authoring_batch_3.zip
{
  "export": "PASS",
  "partition_counts": {
    "imported": 194,
    "current": 97,
    "future": 288
  },
  "reused_proposed_senses": 11
}
EXIT 0
```

### zip-verify

```text
pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --verify-zip build/business_email_authoring_batch_3.zip
{
  "zip_verification": "PASS",
  "zip_sha256": "9b1f6caf6465d2e910c0f9cea60293a4fac80b3a9e862e32c8e65b487db35cf8",
  "hashed_files": 83,
  "sqlite_tables": 22,
  "sqlite_cards": 3383,
  "partition_counts": {
    "imported": 194,
    "current": 97,
    "future": 288
  },
  "reused_proposed_senses": 11
}
EXIT 0
```

### final-audit

```text
pipeline/.venv-macos/bin/python build/business_email_batch_2_checks/final_audit.py
{
  "status": "PASS",
  "baseline_files": 2968,
  "changed_existing_files": [
    "assets/content/en/content.manifest.json",
    "assets/content/en/content.sqlite"
  ],
  "all_original_selection_entries_and_exclusions_equal": true,
  "batch_3": {
    "partition": {
      "imported": 194,
      "current": 97,
      "future": 288
    },
    "display_rows": 291,
    "zip_bytes": 26271888,
    "uncompressed_bytes": 79819274,
    "hashed_files": 83
  },
  "hashes": {
    "build/business_email_authoring_batch_3.zip": "9b1f6caf6465d2e910c0f9cea60293a4fac80b3a9e862e32c8e65b487db35cf8",
    "assets/content/en/content.manifest.json": "6994a984acaa7d9494ae839d058a95f5de81487a5492a175905ce2c4b2e1814e",
    "pipeline/data/selection/business_email_batch_3_context_v1.json": "c5448739963683ac42aa687868adf891cbd3091ea8378ea2bf6d6a0d47d495aa",
[gekürzt; vollständiger Nachweis im gleichnamigen Log/JSON]
EXIT 0
```

## Abweichungen, offene Punkte und Isolation

Drei neue Tokenbindungsfehler gezielt behoben, ohne Satzumformulierung. Zusätzlicher either-Determiner verändert nur Begleitwörterbuchzahlen, nicht die 97 Lernziele. Alle sieben aktuellen und sämtliche älteren Glossen-/Labelbefunde sowie öffentliche Sprachfreigabe bleiben separat offen. Keine Geräteabnahme.

Erster echter Pack-Lesetest: nach 30 Sekunden Timeout, Exit 1, keine gemeldete inhaltliche Assertion. Unverändert und ohne parallele Flutter-/Dart-Prüfungen erneut ausgeführt; tatsächlicher Folgebefund siehe Logabschnitt. Kein Produktions-/Testcode zur Umgehung geändert. GitNexus-Abfrage zunächst ohne Treffer für den verkürzten Namen apply_display_patch; tatsächlicher Name aus Quelle apply_deck_display_patch, Mehrdeutigkeiten historischer Kopien berücksichtigt. Kein fehlgeschlagener CLI-Import oder gelockerter Inhaltsvalidator.

Bekannte repositoryweite Whitespace-Altbefunde (DESIGN.md:162–164, ältere Alltag-Zuhause-/Arbeit-Bildung-Berichte) nicht bereinigt. Eigene neue Dateien LF; NEXTSTEPS maximal 25 Zeilen. Roadmap/Authoring-Bericht enthalten historisch den Vorbereitungsstand; aktueller Importstand steht in den Batchberichten und NEXTSTEPS. Keine ungefragte globale Dokumentbereinigung.

GitNexus: Repository `sprachlernapp`, Checkout `/Users/ardasayar/Documents/FlutterProjekte/sprachapp`, Index sechs Commits hinter Ausgangs-HEAD. Impact vor Daten-/Dokumentänderung: NEXTSTEPS null aufgelöste Caller **UNKNOWN**; neuer Bericht, Asset und Fortsetzung nicht indexiert **UNKNOWN**. Keine HIGH/CRITICAL-Warnung; UNKNOWN nicht als all-clear behandelt. Literal-/Quelldurchsicht plus vollständige Inhalts-/Bestands-/App-Prüfungen ergänzen die begrenzte Graphsicht. Keine Code-Symbole editiert. Rohbeleg `gitnexus-preflight.json`; Änderungsprüfung vor Commit separat protokolliert.

Pack, Assets, ZIP und Prüfbelege bleiben gemäß bestehendem Vertrag gitignorierte lokale Artefakte. Commit ausschließlich eigener Bericht und drei neue Fortsetzungskontexte; NEXTSTEPS wegen vorbestehender Änderungen nicht gestagt. Fremde Dateien/Änderungen erhalten, kein Push.

Abschließender Lesetest: der **unveränderte isolierte Wiederholungslauf besteht**, Exit 0, „All tests passed!“; 14 Stapel, 194 Business-Ziele und 3383 feste aktive Satzzuordnungen. Die 30-Sekunden-Testgrenze und alle Assertions wurden unverändert belassen. Ein einzelner erster Timeout wird als Laufzeitbefund dokumentiert, nicht als bestandener Test umgedeutet.

```text
pipeline/.venv-macos/bin/python build/business_email_batch_2_checks/final_audit.py
status: PASS; baseline_files: 2968
changed_existing_files: NEXTSTEPS.md, assets/content/en/content.manifest.json, assets/content/en/content.sqlite
all_original_selection_entries_and_exclusions_equal: true
EXIT 0

git diff --check -- NEXTSTEPS.md docs/business-email-batch-2-import.md pipeline/data/selection/business_email_batch_3_context_v1.json pipeline/data/words/en.business_email_batch_3_context_v1.json pipeline/data/learning_groups/en.business_email_batch_3_context_v1.json
[keine Ausgabe]
EXIT 0
```

Direkter Whitespacecheck auch der neuen Dateien: PASS, LF; NEXTSTEPS 25 Zeilen. Kein erhaltener CRLF-Fall, kein zusätzlicher cr-at-eol-Lauf erforderlich. Nächste Aktion: 97 aktuelle Batch-3-Ziele anhand der geprüften ZIP im Chat redigieren.

GitNexus-Änderungsprüfung vor Commit: `detect_changes({repo:"sprachlernapp",scope:"all"})`: fünf Dateien, vier indexierte NEXTSTEPS-Abschnitte, null Prozesse; gemeldetes Risiko low. `scope:"staged"`: vier neue Dateien, null indexierte Symbole, null Prozesse. Keine partial-/truncated-Meldung. Neue Daten/Dokumente sind nicht indexiert; null Symbole bedeutet hier keine vollständige Graphabdeckung. Rohbeleg `build/business_email_batch_2_checks/gitnexus-changes.json`.

```text
git diff --cached --check
[keine Ausgabe]
EXIT 0

git status --short
 M NEXTSTEPS.md
A  docs/business-email-batch-2-import.md
A  pipeline/data/learning_groups/en.business_email_batch_3_context_v1.json
A  pipeline/data/selection/business_email_batch_3_context_v1.json
A  pipeline/data/words/en.business_email_batch_3_context_v1.json
[vorbestehende untracked Lieferungen, fremde Berichte und Alltag-Kontexte unverändert]
EXIT 0
```

Der Index enthält ausschließlich diese vier neuen eigenen Dateien. Vollständiger Status einschließlich fremder Pfade: `status-precommit.log`. Kein pauschales Staging und keine fremden Abhängigkeiten in den Commit übernommen.
