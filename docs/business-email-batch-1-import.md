# Business & E-Mail – Batch 1: Import und interne Abnahme

Stand: 13.10.2026. **97 Ziele** der korrigierten Gesamtauswahl `business_email_v2` über den vorhandenen V2-Create-Weg für Schema 4 importiert und als **business_email_batch_1_v1** intern gestagt. Keine öffentliche Inhaltsfreigabe, unabhängige menschliche Sprachfreigabe oder Geräteabnahme. Kein App-/Pipeline-Code und kein Test geändert; keine Modellaufrufe, Paketinstallation oder Lernstandsänderung.

## Dateien und Auswahlbindung

Original: `/Users/ardasayar/Downloads/business_email_batch_1_lieferung.zip`, unverändert. Alle 31 Manifestdateien/ZIP-CRCs stimmen; der vorhandene lokale Ordner `business_email_batch_1/` ist bytegleich. Die enthaltenen `authoring_evidence`-Skripte wurden nicht ausgeführt. Importiert wurde `business_email_batch_1/editorial_content_v2.json` ohne Korrekturkopie, weil keine Satz-/Tokenkorrektur nötig war.

Maßgebliche Eingaben:

- `pipeline/data/selection/business_email_v2.json`, selection_id `business_email_v2`.
- `pipeline/data/words/en.business_email_batch_1_context_v2.json`.
- `pipeline/data/learning_groups/en.business_email_batch_1_context_v2.json`.
- `pipeline/out/verbalphrasen_batch_2_v1/pack.json` und `content.sqlite`.
- Geprüfte Authoring-Referenz `build/business_email_authoring_batch_1_v2.zip`; keine Verwendung der v1-Zwischenfassung.

579 Ziele, davon 43 E-Mail-Ziele, Batches **97/97/97/96/96/96**, elf Themen in jedem Batch. Keine Auffüllung auf 1500/70. Vor Import **0/97/482**, für Batch 2 danach **97/97/385**. Alle 579 Originaleinträge einschließlich IDs, Definitionen, Positionen, Lerngruppen, Besitzbindungen und alle 278 Ausschlüsse sind in der Fortsetzung vollständig gleich. Die stabilen Eintrags-IDs `business-email-v1-…` bleiben trotz korrigierter Auswahlversion erhalten.

Neu erzeugt:

- `pipeline/out/business_email_batch_1_v1/{pack.json,content.sqlite,finalization_report.json}`.
- `pipeline/data/selection/business_email_batch_2_context_v1.json`.
- `pipeline/data/words/en.business_email_batch_2_context_v1.json`.
- `pipeline/data/learning_groups/en.business_email_batch_2_context_v1.json`.
- `build/business_email_authoring_batch_2.zip` und `build/business_email_batch_1_checks/`.
- Dieser Bericht; `NEXTSTEPS.md` aktualisiert. Asset und Manifest ausschließlich durch das Stagingwerkzeug ersetzt.

## Redaktionelle Prüfung

Alle **97 englischen/deutschen Satzpaare und 1086 Tokenpositionen** wurden im Chat vollständig gegengelesen: **980 Wort-/Ausdruckstokens, 106 Satzzeichen**. Gegenprüfung gegen Tokenizer, Sense-/Lemma-Referenzen und sämtliche Token-/Link-Reviewhashes bestanden. Genau ein fester Übungskontext je Ziel, zusammenhängende Lücke, `accepted == [card.form]`; Mehrwortziele über lexical_spans. `resend` hat innerhalb seines einen festen Kontexts zwei zusammengehörige kurze Sätze. Keine neue Batch-2-Satzlieferung erzeugt.

Bedeutungsprüfung: benefit = Arbeitgeber-Zusatzleistung (Kinderbetreuung), net = nach Steuern/Abzügen, bounce = unzustellbare Nachricht, scope = Projekt-/Aufgabenumfang. targets bezeichnet angestrebte Ergebnisse, join die Webinarteilnahme, cancelled die Terminabsage, repairs ein Nomen, booking ein Verb, may eine Möglichkeit, rail den Schienenverkehr. `firm#unternehmen` ist ausdrücklich vom alten fehlerhaften firm-Nomen getrennt. `allowance#zuerkanntes-kontingent` bezeichnet Urlaubstage und nicht den reservierten Geldzuschuss `allowance#zuschuss`.

**Sichtbarer Labelbefund no-show:** „The client was a no-show“ bezeichnet den nicht erschienenen Kunden; der Folgesatz erläutert, dass er weder kam noch absagte. Die deutsche Gesamtübersetzung gibt dieses Fernbleiben wieder. Die unveränderte Auswahlglosse lautet dagegen „unangekündigtes Fernbleiben“, die Definition beschreibt das Nichtwahrnehmen eines Termins. Personenverwendung und abstraktes Auswahllabel bleiben als redaktioneller Unterschied dokumentiert; Definition und Identität wurden nicht still umgeschrieben.

Neun zukünftige Begleitwort-Senses sind bereits vorhanden, jeweils mit **exakt reservierter Definition**, aber ohne zukünftige Lernkarte: complaint, approve, supplier, expense, recipient, version, approval, maintenance, demand. Der Fortsetzungsverifier bestätigt `reused_proposed_senses: 9`. Insgesamt ergänzt der Import 131 Lemmas, 153 Senses und 191 Wörterbuchformen; Begleitwörter werden nicht als zusätzliche Lernziele gezählt.

Drei wörtliche Alternativsubstitutionen vollständig gelesen: `emphasise → emphasize`, `synchronise → synchronize`, `resend → re-send`. Die englischen Ersatzkontexte erhalten Bedeutung und deutsche Übersetzung. Gegen 579 Auswahlziele, Reservierungen, bestehende Karten, Besitzaliase und Gruppenbindungen geprüft; keine Kollision und keine neuen Besitzaliase. Alternativen bleiben satzgebunden und lernstandsneutral, `accepted` enthält ausschließlich die Zielform. Keine automatische Freigabe aus Gruppen-/Aliasmitgliedschaft.

Acht geerbte Formglossenvergleiche bleiben erhalten:

| Form | Geerbte Glosse | Kontextdarstellung |
|---|---|---|
| helped | half | halfen |
| client | Kunden | Kunde |
| software | Software- | Software |
| staff | Mitarbeiter- | Beschäftigte |
| health | Gesundheits- | Gesundheit |
| offered | anbot | angeboten |
| caused | verursachte | verursacht |
| is | sein (als Vollverb oder Kopula zur Angabe von Zustand, Identität oder Eigenschaft) | ist |

Die geerbten gemeinsamen Wörterbuchzeilen sind unverändert. Frühere Listen und offene Pilotfälle werden dadurch nicht ersetzt. Kein künstlicher Sense allein für eine andere Flexionsübersetzung. Vollständiger Einzelprüfnachweis: `build/business_email_batch_1_checks/editorial-review.json`, gebunden an Satzhashes und je Satz gezählte Tokenpositionen; Modellprüfung, keine menschliche Freigabe.

## Bestandsschutz, Tabellen und App-Projektion

Alle 22 exportierten Tabellen mit `build_rows` und `finalize_curation.check_sqlite` zeilen-/spaltenweise erneut geprüft. `content_releases.created_at` wird nach bestehendem Vertrag nicht exakt verglichen; Vorhandensein separat bestätigt. Alle alten JSON-Listen sind unveränderte Präfixe; alle alten Zeilen der übrigen 21 SQL-Tabellen sind vollständig erhalten, einschließlich IDs, Satzbindungen, Glossen, Gruppen, Besitz, Alternativen und historischer Zeilen. Release-/Registry-Fortschreibung ist autorisiert. Batch 1 benötigt keinen Display-Patch: genau Anzeigen 1–97 in beiden Mitgliedschaftstabellen.

| Tabelle | Exportierte Zeilen |
|---|---:|
| languages | 1 |
| lemmas | 4418 |
| senses | 6059 |
| cards | 3286 |
| dictionary_forms | 7258 |
| decks | 14 |
| deck_cards | 3179 |
| deck_words | 3075 |
| word_aliases | 37 |
| sentences | 3820 |
| sentence_tokens | 41440 |
| card_sentences | 3814 |
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

Die vier Formtabellen sind vollständig unverändert: 134 Verbanker, 406 Kartenankerbindungen, 402 Formziele und 402 Formmitgliedschaften; **134/134/134** Übungen in den drei Verbenansichten. Die korrigierten Formglossen **pick out = aus einer Menge erkennen** und **pull over = an den Straßenrand fahren und anhalten** bleiben exakt erhalten. Die davon abweichenden älteren Karten-/Sense-Labels bleiben separat offen.

Reale App-Projektion durch `tool/report_learning_groups.dart`: **14 Stapel, 3172 Übungen / 2901 Wörter**, Business 97/97; insgesamt 3286 physische Karten, 3075 Besitzzeilen. Die Zahlen bezeichnen unterschiedliche Mengen. Formübungen zählen das gleiche Verb nicht dreifach als neue Wörter.

Linter **0 Fehler / 480 Hinweise**: 476 byte-/wertgleich übernommene Altbefunde plus genau vier neue Hinweise:

- `benefit`: 'childcare'/'childcare' Zipf 3.40 below 3.5.
- `net`: 'deduction'/'deductions' Zipf 3.46 below 3.5.
- `payroll`: 'deduction'/'deductions' Zipf 3.46 below 3.5.
- `row`: 'spreadsheet'/'spreadsheet' Zipf 3.31 below 3.5.

## Sicherung, Staging und Batch 2

Nach bestandenem Importaudit und **vor** Staging wurden Asset und Manifest bytegleich unter `build/business_email_batch_1_checks/backup/` gesichert. `backup/backup-proof.json` dokumentiert Zeitpunkt und Ausgangshashes. Danach Staging und separater Asset-Verifier erfolgreich; Asset bytegleich zur Export-SQLite. Der echte Pack-Lesetest nutzt ein temporäres Supportverzeichnis und liest alle 14 Stapel sowie 3286 feste aktive Satzzuordnungen. Keine echte user.db geöffnet, keine Geräteprüfung behauptet. Flutter-Analyse und kompletter Pipeline-Testlauf bestanden.

Fortsetzung über den bestehenden `--prepare-continuation`-Weg aus der Original-v2-Auswahl, gebunden an den tatsächlich gestagten Pack. Drei neue versionierte Kontexte; keine historische Datei überschrieben. ZIP geschlossen, erneut geöffnet und separat verifiziert: **83 Dateihashes, CRCs, 22 vollständige Quelltabellen, 579 Ziele, 97/97/385**. Kombinierte Anzeigeabbildung mit **194** eindeutigen Zeilen/Positionen 1–194; `continuation_display_mapping.json` trennt bisherige Anzeigen, Anhänge und endgültige Positionen. Der enthaltene Vertrag verlangt für den späteren Batch-2-Import einen hashgebundenen `--display-patch`; jetzt nicht angewendet.

ZIP: **25929625 komprimierte / 78277276 unkomprimierte Bytes**. Uploadpfad:
`/Users/ardasayar/Documents/FlutterProjekte/sprachapp/build/business_email_authoring_batch_2.zip`

## Hashes

Rohbyte-SHA256 und kanonische JSON-Digests sind getrennt angegeben.

| Objekt | SHA256 / Digest |
|---|---|
| Original-Liefer-ZIP (Rohbytes) | `56ab88e6948b850b653b59301a06766e6cdba294879eb17b297efbe54f41b061` |
| Create-Datei (Rohbytes) | `4a4cdc5506a1df3b8d41da3c649db4120145d2b1fed7fa5f29caaeb27418ec0c` |
| Quell-pack.json (Rohbytes) | `308171f13f4ee479f80f4dfc5667cde63ece850fb2b813d1825f9b22c4715e56` |
| Quell-/Backup-SQLite (Rohbytes) | `f1a25d32fb18f4b6640628576b79f2d5577b2b0b2253b15517259f25c6204eb6` |
| Backup-Manifest (Rohbytes) | `748852813e408a2950bbf07bb8e3e79888f6bdeaa33effbd193a861358ea34b3` |
| Eingabe-Registry (kanonisch) | `7ab3dd9e0c0b6c50f5e98270f6fdc2206ecbaec7720e07bae5f7d4a6679ad8a7` |
| Eingabe-Lerngruppen (kanonisch) | `ed45ed388501783071873a1650f160a33340b3d0c0cb90b1cfd54785a1252874` |
| Export pack.json (Rohbytes) | `de3a95b42a9b9f4839cd39514fd66811afc2b78fd69967825efd62c6cec856cd` |
| Export content.sqlite (Rohbytes) | `e1ecd0ba870afa9a667eef648b75a38285f70ff808007dda982b02e5b93103ed` |
| Export finalization_report.json (Rohbytes) | `0bf9c85b20ec781e25f577401e7bdfd8687bc60085f9ec762e6d166cc9809dc3` |
| build/business_email_authoring_batch_2.zip (Rohbytes) | `88370ebbc61ea2e288d1d24fc250d6529fcdf589dca7f28fad1bd333cb57b581` |
| assets/content/en/content.manifest.json (Rohbytes) | `a8424495737bf9fb4174eb98cc144bb85ccfefb9e1bbe336b45ed2afe4e68dc9` |
| pipeline/data/selection/business_email_batch_2_context_v1.json (Rohbytes) | `6f0ec116f86dba55e80b7eab22ee2828f8dda19ce1ad17e8639d356e8dd59cf8` |
| pipeline/data/words/en.business_email_batch_2_context_v1.json (Rohbytes) | `a63643d2e97403ea543d82cf061baeac26c5e0a5494a63b5fcbfa7826019e6e2` |
| pipeline/data/learning_groups/en.business_email_batch_2_context_v1.json (Rohbytes) | `3433d8b138d19f2665349fba3ecdeff07ac67949a5b7b6959e3502574cf709b5` |

## Tatsächliche Befehle, Outputs und Exitcodes

Aus Repository-Root auf macOS. Der lokale Wrapper speichert unveränderte relevante Ausgaben ohne ANSI-Codes in `<Name>.log` und Befehl/Exitcode in `<Name>.command.json` unter `build/business_email_batch_1_checks/`. Pythonpfad auf macOS `pipeline/.venv-macos/bin/python`; in Windows PowerShell die vorhandene Pipeline-Umgebung aktivieren und `python` verwenden. Dart-/Flutter-/Git-Argumente sind plattformgleich. Keine Bash-exklusiven Befehle erforderlich.

### delivery-audit-final

```text
pipeline/.venv-macos/bin/python build/business_email_batch_1_checks/delivery_audit.py
{
  "status": "PASS",
  "delivery_zip": "/Users/ardasayar/Downloads/business_email_batch_1_lieferung.zip",
  "zip_sha256": "56ab88e6948b850b653b59301a06766e6cdba294879eb17b297efbe54f41b061",
  "create_sha256": "4a4cdc5506a1df3b8d41da3c649db4120145d2b1fed7fa5f29caaeb27418ec0c",
  "manifest_files": 31,
  "all_local_files_match_zip": true,
  "source_json_sha256": "308171f13f4ee479f80f4dfc5667cde63ece850fb2b813d1825f9b22c4715e56",
  "registry_digest": "7ab3dd9e0c0b6c50f5e98270f6fdc2206ecbaec7720e07bae5f7d4a6679ad8a7",
  "groups_digest": "ed45ed388501783071873a1650f160a33340b3d0c0cb90b1cfd54785a1252874",
  "current": 97,
  "total": 579,
  "words": 980,
  "punctuation": 106,
  "alternatives": [
    [
      "resend|resend/VERB|resend#erneut-senden",
      "re-send"
    ],
    [
      "emphasise|emphasise/VERB|emphasise#betonen",
      "emphasize"
    ],
    [
[gekürzt; vollständiger Nachweis im gleichnamigen Log/JSON]
EXIT 0
```

### editorial-review

```text
pipeline/.venv-macos/bin/python build/business_email_batch_1_checks/review_record.py
BATCHES Counter({1: 97, 2: 97, 3: 97, 4: 96, 5: 96, 6: 96})
TOPICS Counter({'IT und digitale Zusammenarbeit': 70, 'Projekte und Arbeitsabläufe': 62, 'Personal, Bewerbung und Arbeitsbedingungen': 61, 'Vertrieb, Einkauf und Bestellungen': 57, 'Verträge und Organisation': 51, 'Berufliche Kommunikation': 48, 'Termine und Besprechungen': 48, 'Geld, Rechnungen und Zahlungen': 48, 'Zusammenarbeit und Aufgabenverteilung': 46, 'Kundenservice und Problemlösung': 45, 'E-Mail-Verkehr': 43})
REVIEW RECORD: 97 pairs / 1086 token positions; original unchanged; 3 literal substitutions; 8 inherited gloss comparisons.
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
455 passed, 19 subtests passed in 14.41s
EXIT 0
```

### import

```text
pipeline/.venv-macos/bin/python pipeline/scripts/import_editorial_patch.py --source pipeline/out/verbalphrasen_batch_2_v1/pack.json --create business_email_batch_1/editorial_content_v2.json --registry pipeline/data/words/en.business_email_batch_1_context_v2.json --out pipeline/out/business_email_batch_1_v1
{
  "status": "ok",
  "internal_test_pack": true,
  "ai_calls": 0,
  "ai_cost_usd": 0,
  "sqlite_counts": {
    "languages": 1,
    "lemmas": 4418,
    "senses": 6059,
    "cards": 3286,
    "dictionary_forms": 7258,
    "decks": 14,
    "deck_cards": 3179,
    "deck_words": 3075,
    "word_aliases": 37,
    "sentences": 3820,
    "sentence_tokens": 41440,
    "card_sentences": 3814,
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
  "sha256": "e1ecd0ba870afa9a667eef648b75a38285f70ff808007dda982b02e5b93103ed"
}
EXIT 0
```

### export-audit-final

```text
pipeline/.venv-macos/bin/python build/business_email_batch_1_checks/export_audit.py
PRESERVED pick out {"ref": "pick out/VERB|pick-out#wiedererkennen", "lemma": "pick out/VERB", "sense_key": "pick-out#wiedererkennen", "gloss_de": "wiedererkennen", "definition_de": "Eine bestimmte Person oder Sache in einer größeren Menge erkennen."}
PRESERVED pull over {"ref": "pull over/VERB|pull-over#rechts-ranfahren", "lemma": "pull over/VERB", "sense_key": "pull-over#rechts-ranfahren", "gloss_de": "rechts ranfahren", "definition_de": "Mit einem Fahrzeug an den Straßenrand fahren und dort anhalten."}
{
  "status": "PASS",
  "tables": {
    "languages": 1,
    "lemmas": 4418,
    "senses": 6059,
    "cards": 3286,
    "dictionary_forms": 7258,
    "decks": 14,
    "deck_cards": 3179,
    "deck_words": 3075,
    "word_aliases": 37,
    "sentences": 3820,
    "sentence_tokens": 41440,
    "card_sentences": 3814,
    "stories": 1,
    "story_sentences": 6,
    "exercises": 0,
    "grammar_rules": 0,
    "audio_assets": 0,
    "content_releases": 1,
    "lexical_targets": 134,
[gekürzt; vollständiger Nachweis im gleichnamigen Log/JSON]
EXIT 0
```

### backup

```text
pipeline/.venv-macos/bin/python build/business_email_batch_1_checks/backup_before_stage.py
{
  "status": "PASS",
  "time_utc": "2026-10-13T19:17:46.074608+00:00",
  "hashes": {
    "content.sqlite": "f1a25d32fb18f4b6640628576b79f2d5577b2b0b2253b15517259f25c6204eb6",
    "content.manifest.json": "748852813e408a2950bbf07bb8e3e79888f6bdeaa33effbd193a861358ea34b3"
  },
  "before_staging": true
}
EXIT 0
```

### stage-authorized

```text
dart run tool/stage_content_pack.dart --from pipeline/out/business_email_batch_1_v1
staged assets/content/en/content.sqlite
  version business_email_batch_1_v1, schema 4, 20688896 bytes
  sha256 e1ecd0ba870afa9a667eef648b75a38285f70ff808007dda982b02e5b93103ed
  22 table counts match finalization_report.json
  INTERNES TEST-PACK: own devices and selected testers only, no public content release
Running build hooks...Running build hooks...
EXIT 0
```

### stage-verify

```text
dart run tool/stage_content_pack.dart --verify
verified assets/content/en/content.sqlite
  version business_email_batch_1_v1, schema 4, 20688896 bytes
  sha256 e1ecd0ba870afa9a667eef648b75a38285f70ff808007dda982b02e5b93103ed
  22 table counts match finalization_report.json
  INTERNES TEST-PACK: own devices and selected testers only, no public content release
Running build hooks...Running build hooks...
EXIT 0
```

### app-projection

```text
dart run tool/report_learning_groups.dart pipeline/out/business_email_batch_1_v1/content.sqlite
{
  "alltag-zuhause": {
    "raw_words": 241,
    "learning_targets": 241,
    "lexical_words": 241,
    "form_memberships": 0
  },
  "alltagssprache-redewendungen": {
    "raw_words": 441,
    "learning_targets": 441,
    "lexical_words": 441,
    "form_memberships": 0
  },
  "arbeit-bildung": {
    "raw_words": 245,
    "learning_targets": 245,
    "lexical_words": 245,
    "form_memberships": 0
  },
  "business-email": {
    "raw_words": 97,
    "learning_targets": 97,
    "lexical_words": 97,
    "form_memberships": 0
  },
  "essen-trinken": {
    "raw_words": 250,
    "learning_targets": 250,
    "lexical_words": 250,
    "form_memberships": 0
  },
  "koerper-gesundheit": {
    "raw_words": 249,
    "learning_targets": 249,
    "lexical_words": 249,
    "form_memberships": 0
  },
  "menschen-beziehungen": {
    "raw_words": 245,
    "learning_targets": 245,
    "lexical_words": 245,
    "form_memberships": 0
  },
  "natur-umwelt": {
    "raw_words": 242,
    "learning_targets": 242,
    "lexical_words": 242,
    "form_memberships": 0
  },
  "verbalphrasen": {
    "raw_words": 181,
    "learning_targets": 181,
    "lexical_words": 181,
    "form_memberships": 0
  },
  "allgemeine-sprache": {
    "raw_words": 160,
    "learning_targets": 160,
    "lexical_words": 154,
    "form_memberships": 0
  },
  "reisen": {
    "raw_words": 500,
    "learning_targets": 489,
    "lexical_words": 489,
    "form_memberships": 0
  },
  "irregular_verbs_base": {
    "raw_words": 134,
    "learning_targets": 134,
    "lexical_words": 134,
    "form_memberships": 134
  },
  "irregular_verbs_past": {
    "raw_words": 134,
    "learning_targets": 134,
    "lexical_words": 134,
    "form_memberships": 134
  },
  "irregular_verbs_participle": {
    "raw_words": 134,
    "learning_targets": 134,
    "lexical_words": 134,
    "form_memberships": 134
  },
  "mixed": {
    "raw_words": 3253,
    "learning_targets": 3172,
    "lexical_words": 2901,
    "form_memberships": 402
  }
}
EXIT 0
```

### flutter-analyze

```text
flutter analyze --no-pub
┌─────────────────────────────────────────────────────────┐
│ A new version of Flutter is available!                  │
│                                                         │
│ To update to the latest version, run "flutter upgrade". │
└─────────────────────────────────────────────────────────┘
Analyzing sprachapp...
No issues found! (ran in 2.3s)
EXIT 0
```

### real-pack-test

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
deck business-email: 97 learning targets, 97 ownership cards, 97 fixed sentence assignments verified
pack business_email_batch_1_v1 (schema 4, internal: true); 14 decks: 3075 cards, 3286 card sentences, 190 with valid_alternatives, 3286 cards in the pack
00:48 +1: All tests passed!
EXIT 0
```

### continuation

```text
pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --selection pipeline/data/selection/business_email_v2.json --batch 2 --prepare-continuation business_email_batch_2_context_v1
{
  "snapshots": "PASS",
  "paths": {
    "selection": "pipeline/data/selection/business_email_batch_2_context_v1.json",
    "registry": "pipeline/data/words/en.business_email_batch_2_context_v1.json",
    "groups": "pipeline/data/learning_groups/en.business_email_batch_2_context_v1.json"
  },
  "partition_counts": {
    "imported": 97,
    "current": 97,
    "future": 385
  }
}
EXIT 0
```

### zip-export

```text
pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --selection pipeline/data/selection/business_email_batch_2_context_v1.json --batch 2 --out build/business_email_authoring_batch_2.zip
{
  "export": "PASS",
  "partition_counts": {
    "imported": 97,
    "current": 97,
    "future": 385
  },
  "reused_proposed_senses": 9
}
EXIT 0
```

### zip-verify

```text
pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --verify-zip build/business_email_authoring_batch_2.zip
{
  "zip_verification": "PASS",
  "zip_sha256": "88370ebbc61ea2e288d1d24fc250d6529fcdf589dca7f28fad1bd333cb57b581",
  "hashed_files": 83,
  "sqlite_tables": 22,
  "sqlite_cards": 3286,
  "partition_counts": {
    "imported": 97,
    "current": 97,
    "future": 385
  },
  "reused_proposed_senses": 9
}
EXIT 0
```

### final-audit

```text
pipeline/.venv-macos/bin/python build/business_email_batch_1_checks/final_audit.py
{
  "status": "PASS",
  "baseline_files": 2931,
  "changed_existing_files": [
    "assets/content/en/content.manifest.json",
    "assets/content/en/content.sqlite"
  ],
  "all_original_selection_entries_and_exclusions_equal": true,
  "batch_2": {
    "partition": {
      "imported": 97,
      "current": 97,
      "future": 385
    },
    "display_rows": 194,
    "zip_bytes": 25929625,
    "uncompressed_bytes": 78277276,
    "hashed_files": 83
  },
  "hashes": {
    "build/business_email_authoring_batch_2.zip": "88370ebbc61ea2e288d1d24fc250d6529fcdf589dca7f28fad1bd333cb57b581",
    "assets/content/en/content.manifest.json": "a8424495737bf9fb4174eb98cc144bb85ccfefb9e1bbe336b45ed2afe4e68dc9",
    "pipeline/data/selection/business_email_batch_2_context_v1.json": "6f0ec116f86dba55e80b7eab22ee2828f8dda19ce1ad17e8639d356e8dd59cf8",
    "pipeline/data/words/en.business_email_batch_2_context_v1.json": "a63643d2e97403ea543d82cf061baeac26c5e0a5494a63b5fcbfa7826019e6e2",
[gekürzt; vollständiger Nachweis im gleichnamigen Log/JSON]
EXIT 0
```

## Fehlversuche und offene Altbefunde

- Zusätzliches lokales Prüfskript: zuerst falscher Tokenizer-Import (`sprachpipe.linter` statt `sprachpipe.annotate`), dann falscher angenommener ZIP-Wurzelpfad für das Schema. Tatsächlicher Pfad `pipeline/data/curation/editorial_content_v2.schema.json`. Beide Exit 1, danach vollständiger Audit Exit 0. Keine Liefer-/Pipelineänderung.
- Exportaudit: `form_function` als SQL-Spalte war falsch; Schema abgefragt und tatsächliche Spalte `function` verwendet. Exit 1, danach vollständiger Audit Exit 0. Kein Export geändert.
- Erster Dart-Stagingaufruf: Sandbox verweigerte Schreiben von `engine.stamp.tmp`/`engine.realm` im lokalen Flutter-SDK-Cache, Exit 1. Derselbe autorisierte Stagingauftrag mit Cachezugriff Exit 0. Keine Paketinstallation/SDK-Aktualisierung. Eine zusätzliche Prozessabfrage wurde von der Sandbox verweigert; ohne Einfluss auf die Prüfungen.
- Keine Wiederholung desselben Fehlers über die Schleifenbremse; keine Prüfung gelockert. Fehlversuchslogs liegen neben den erfolgreichen Logs.
- 476 ältere Linterhinweise, frühere Pilot-/Alternativen-/Formglossenbefunde und die zwei Verbalphrasen-Auswahllabel bleiben offen; acht aktuelle Glossenvergleiche und no-show-Labelbefund sind dokumentiert. Öffentliche Sprachfreigabe und Geräteabnahme bleiben ausstehend.
- Bekannte repositoryweite Whitespace-Altbefunde in DESIGN.md:162–164 sowie Alltag-Zuhause-/Arbeit-Bildung-Berichten wurden nicht bereinigt. Nur eigene Dokumente/Kontexte geprüft; keine globale Zeilenendennormalisierung.

## GitNexus, Isolation und Commit

Gebundenes Repository `sprachlernapp`, Checkout `/Users/ardasayar/Documents/FlutterProjekte/sprachapp`. Index fünf Commits hinter Ausgangs-HEAD `7d3caa7ec7d74fc969e7ae9933915900d3254f55`; aktuelle Quellen und ausführbare Verträge zusätzlich gelesen. Graph-Query/Context für Import/Fortsetzung ausgeführt. Impact vor Dokument-/Datenänderung: NEXTSTEPS ohne aufgelöste Caller **UNKNOWN**, neuer Bericht, Asset und neuer Fortsetzungskontext nicht indexiert **UNKNOWN**. Keine HIGH/CRITICAL-Warnung; UNKNOWN ist keine Freigabe durch einen leeren Graphen. Literalprüfung und tatsächlicher 22-Tabellen-/Identitäts-/Hash-/App-Test begrenzen die Änderung. Keine Code-Symbole editiert. Rohbeleg `gitnexus-preflight.json`.

2931 vorbestehende Dateien erfasst: unverändert außer autorisiertem Asset/Manifest und anschließend NEXTSTEPS. Historische Packs, Lieferung, Auswahlen/Registrys, Instruktionen und fremde Änderungen bleiben erhalten. Ausgangsindex leer. NEXTSTEPS war vorbestehend geändert und wird nicht mit fremden Hunks gestagt. Ausgaben unter build/, pipeline/out/ und Assets sind nach vorhandenen Regeln gitignoriert, lokal erhalten und per Hash dokumentiert. Eigener Commit umfasst ausschließlich diesen Bericht und die drei neuen Fortsetzungskontexte; kein Push.

Änderungsprüfung unmittelbar vor Commit: `detect_changes({repo:"sprachlernapp",scope:"all"})` erfasst fünf Dateien / vier NEXTSTEPS-Abschnitte / null Prozesse, gemeldetes Risiko low. `scope:"staged"` erfasst vier neue Dateien / null indexierte Symbole / null Prozesse. Keine partial-/truncated-Meldung; null Symbole ist bei diesen nicht indexierten neuen Daten/Dokumenten **keine vollständige Graphabdeckung**. Rohbeleg `build/business_email_batch_1_checks/gitnexus-changes.json`. Inhaltliche Abdeckung liefern die oben protokollierten Prüfungen.

Eigener Whitespacecheck: einmal nachlaufende Leerzeichen aus dem kopierten Flutter-Analyseoutput im neuen Bericht entdeckt und nur dort entfernt; Rohlog unverändert. Anschließende eigene Checks bestanden. Keine Änderung an CRLF-Bestandsdateien.

```text
pipeline/.venv-macos/bin/python build/business_email_batch_1_checks/final_audit.py
status: PASS; baseline_files: 2931
changed_existing_files: NEXTSTEPS.md, assets/content/en/content.manifest.json, assets/content/en/content.sqlite
all_original_selection_entries_and_exclusions_equal: true
EXIT 0

git diff --check -- NEXTSTEPS.md docs/business-email-batch-1-import.md pipeline/data/selection/business_email_batch_2_context_v1.json pipeline/data/words/en.business_email_batch_2_context_v1.json pipeline/data/learning_groups/en.business_email_batch_2_context_v1.json
[keine Ausgabe]
EXIT 0
```

Nächste Aktion: 97 aktuelle Business-Batch-2-Ziele anhand der geprüften ZIP im Chat redigieren. Das interne Batch-1-Pack befindet sich unter `/Users/ardasayar/Documents/FlutterProjekte/sprachapp/pipeline/out/business_email_batch_1_v1/`.

```text
git diff --cached --check
[keine Ausgabe]
EXIT 0

git diff --cached --stat
4 files changed: Importbericht und drei versionierte Business-Batch-2-Kontexte
EXIT 0

git status --short
 M NEXTSTEPS.md
A  docs/business-email-batch-1-import.md
A  pipeline/data/learning_groups/en.business_email_batch_2_context_v1.json
A  pipeline/data/selection/business_email_batch_2_context_v1.json
A  pipeline/data/words/en.business_email_batch_2_context_v1.json
[vorbestehende untracked Lieferungen, Alltag-Kontexte und fremde Berichte unverändert erhalten]
EXIT 0
```
