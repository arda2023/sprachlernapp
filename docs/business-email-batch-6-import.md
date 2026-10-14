# Business & E-Mail – Batch 6: Inhaltsabschluss der 14 Stapel

Stand: 14.10.2026. **96 neue /579 gesamte Business-Ziele**, davon **43 E-Mail-Ziele**, als `business_email_batch_6_v1` additiv importiert und intern gestagt. Die vereinbarte Inhaltslieferung der **14 Stapel** ist intern vollständig. Tatsächliche App-Projektion: **3768 Karten, 3654 Übungen /3383 lexikalische Ziele**. **Standardlauf: Exit 1, 41.19 Sekunden Gesamtprozesszeit, reguläres 30-Sekunden-Budget. Standard-Testabnahme und Timeoutursache bleiben offen. Gesonderte Drei-Minuten-Diagnose: Exit 0, 126.65 Sekunden Gesamtprozesszeit. Ein Diagnose-PASS ist kein Standard-PASS und keine Ursachenbehebung.** Öffentliche Sprachfreigabe, geerbte Glossen-/Labelbefunde und Geräteprüfung bleiben offen; Inhaltsabschluss ist keine vollständige Produktfreigabe.

## Geprüfte Basis und Lieferung

Basis `pipeline/out/business_email_batch_5_v1/{pack.json,content.sqlite}`, Schema 4. Kontext `pipeline/data/selection/business_email_batch_6_context_v1.json`, Registry `pipeline/data/words/en.business_email_batch_6_context_v1.json`, Gruppen `pipeline/data/learning_groups/en.business_email_batch_6_context_v1.json`. Alle bestehenden Auswahlen/Registrys/Gruppen erhalten. Ursprung `pipeline/data/selection/business_email_v2.json`, Auswahl-ID `business_email_v2` und historische Eintrags-IDs `business-email-v1-####` unverändert.

Original-ZIP `/Users/ardasayar/Downloads/business_email_batch_6_lieferung.zip` geschlossen und erneut geöffnet: sichere eindeutige Pfade, CRCs und **35 manifestierte Dateihashes** geprüft. `reference/manifest.json` ist diesmal vollständig im Liefermanifest enthalten; die frühere Manifestlücke besteht in dieser Lieferung nicht. Alle Referenzdateien zusätzlich bytegleich an die bekannte geprüfte `build/business_email_authoring_batch_6.zip` gebunden, Gesamt-SHA256 `977943172521f8324d4533d52d20d4227c2e412afe0d0d4ab422136e5dc796ea`. Entpackung `business_email_batch_6/` und erst nach Prüfung angelegte Arbeitskopie `editorial_review/business_email_batch_6/` bytegleich. Keine mitgelieferten authoring_evidence-Skripte ausgeführt.

Ausgangspartition **483 importiert /96 aktuell /0 später**. Asset, Manifest, Quell-JSON/SQLite, aktuelle Kontextauswahl, Registry und Lerngruppen entsprechen der geprüften Batch-5-Basis. Ausgangs-HEAD `cfbaa12e9b91e875f42e7c4b06b4ac8028f810bf`, Index leer; **3223 Dateien** vor Änderungen erfasst. AGENTS, CLAUDE, PRODUCT, Roadmap, Authoring-/Schema-/Gruppenverträge und vorhandene Werkzeuge sind hashgleich zum bereits gelesenen Prüfstand; Batch-5-Bericht und aktuelle NEXTSTEPS berücksichtigt. Vorbestehend geändertes NEXTSTEPS bleibt außerhalb des isolierten Commits.

## Vollständige Redaktion

Alle **96 Satzpaare**, Zieldefinitionen und **1149 Tokenpositionen** vollständig gegengelesen: **1042 Wort-/Ausdruckstokens und 107 Satzzeichen**. Alle neuen Begleitwortdefinitionen und 169 Formglossen gelesen. Keine belegte Lieferkorrektur nötig. Original, Arbeitskopie, Satztexte, Übersetzungen und abhängige Review-/Token-/Linkhashes bleiben identisch. Einzelbelege `editorial-review.json`; redaktionelle Modellprüfung, keine unabhängige menschliche Sprachfreigabe.

Geprüfte Bedeutungsunterscheidungen: delivery receipt bestätigt den Eingang beim Server, keine Lektüre. back order ist wegen fehlender Ware ausstehend, reorder bedeutet erneut bestellen. outstanding = offen; commission = Provision. key bei decrypt ist kryptografisch, line bei subtotal eine Textzeile und bei get through to eine Telefonleitung. working ist bei deliverable funktionsfähig, bei turnaround time ein Arbeitszeit-Adjektiv, bei concern/shift work ein Verb. supply = Vorrat beim Nachbestellen, Verb liefern bei order confirmation. field = Fachgebiet. changes ist bei contact details ein Verb, bei convene/read-only/inform ein Nomen. have bei as requested/order confirmation/margin ist AUX. Zeitangaben, to-Präpositionen/Infinitivmarker und finite Formen/Partizipien geprüft. produce umfasst laut Bestandsdefinition auch durch Arbeit erzeugte Ergebnisse; supply das Bereitstellen benötigter Ressourcen. Keine globale Umdeutung alter Senses.

Alle Mehrwortziele haben die zusammenhängende Lücke und exakt einen festen Satz. `accepted` enthält ausschließlich die Zielform. **call centre → call center**, **email address → e-mail address**, **drop-down menu → dropdown menu** wörtlich in den vollständigen Sätzen eingesetzt und gelesen; exakt mit `alternative_review.json` abgeglichen. Dieselbe Bedeutung und deutsche Übersetzung; ausschließlich diese drei satzgebundenen Schreibvarianten, lernstandsneutral. Kollisionsprüfung gegen alle 579 Auswahlidentitäten, Registry, vorhandene Karten sowie Besitzer-/Gruppen-/Synonymaliase. Keine neue word_aliases-Zeile; Aliase erlauben keine automatische Antwortfreigabe. Neue Begleitwort-Senses erzeugen keine zusätzliche Lernkarte.

Sechs kontextuelle Bestandsvergleiche, keine abschließende Fehlerliste. Alle Quellzeilen exakt bestätigt und erhalten:

| Form | Bestands-Formglosse | Kontextvergleich |
|---|---|---|
| training | Trainings | Schulungen |
| main | Haupt- | wichtigste; Haupt- |
| parking | Park- | Parken |
| december | Dezembers | Dezember |
| could | konnten | konnte |
| signed | unterschrieben | unterschrieben / unterschrieben (Verbform) |

Insbesondere signed ist **kein zwingender Formglossenfehler**: finite Vergangenheit bei attendance list und attributives Partizip bei signatory; deutsche Formen hier beide „unterschrieben“. Alle früheren Altglossen-/Labelbefunde einschließlich no-show bleiben gesondert offen.

## Import, Tabellen und Bestand

Bestehender V2-Create-Importer auf Schema-4-Basis, explizite aktuelle Registry und hashgebundener Display-Patch. Neue Mitgliedschaften zuerst **484–579**, anschließend ausschließlich Business-Anzeige **1–579**. **0 alte Positionswerte verändert**; Originalauswahlpositionen, Karten-/Sense-/Lemma-IDs, Besitzer und Lerngruppen erhalten. Kein weiterer Stapel.

Export-SQLite geschlossen und erneut schreibgeschützt geöffnet; alle **22 Tabellen** mit bestehendem `check_sqlite` vollständig gegen `build_rows` verglichen. Exportgeneriertes `content_releases.created_at` gemäß bestehendem Vertrag vom exakten Wertvergleich ausgenommen; Vorhandensein geprüft. Alle Altzeilen der anderen 21 Tabellen einschließlich Positionen erhalten: **3672 Karten, 4206 Sätze, 45933 Tokens, 7920 Dictionary-Zeilen**. JSON-Bestandslisten ebenfalls vollständig verglichen. Formtabellen unverändert **134/406/402/402**, drei Ansichten **134/134/134**.

| Tabelle | Finale Zeilen |
|---|---:|
| languages | 1 |
| lemmas | 5007 |
| senses | 6759 |
| cards | 3768 |
| dictionary_forms | 8089 |
| decks | 14 |
| deck_cards | 3661 |
| deck_words | 3557 |
| word_aliases | 37 |
| sentences | 4302 |
| sentence_tokens | 47082 |
| card_sentences | 4296 |
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

Frühere Bindungskorrekturen explizit nachgewiesen: business-email-v1-0131-s1, Index 7 → plan/VERB|plan#planen; -0150-s1, Index 3 → either/DET|either#jeder-von-beiden-begleitend; -0189-s1, Index 3 → today/NOUN|today#heute. Dictionary-Glossen pick out „aus einer Menge erkennen“ und pull over „an den Straßenrand fahren und anhalten“ erhalten.

Linter **0 Fehler /506 Hinweise**: **500 alte Befunde** identisch plus sechs neue Häufigkeitshinweise. Diese Hinweise sind keine bewiesenen Sprachfehler:

- `backlog`: 'unanswered'/'unanswered' Zipf 3.31 below 3.5.
- `response time`: 'enquiry'/'enquiry' Zipf 3.41 below 3.5.
- `due date`: 'invoice'/'invoice' Zipf 3.27 below 3.5.
- `settle`: 'invoice'/'invoice' Zipf 3.27 below 3.5.
- `incorrect`: 'invoice'/'invoice' Zipf 3.27 below 3.5.
- `payable`: 'invoice'/'invoice' Zipf 3.27 below 3.5.

## Unabhängiger Inhaltsabschluss

Alle **579 Business-Identitäten** im tatsächlichen finalen Pack mit der korrigierten v2-Ursprungsauswahl und der aktuellen Registry abgeglichen: exakte Definitionen/Glossen, stabile IDs, Formen, Labels, Gruppenentscheidungen, Besitzer, Aliase und Originalpositionen. Business-Mitgliedschaft exakt dieselbe Zielmenge. Alle **579 primären Business-Lernköpfe** besitzen genau einen aktiven festen Satz, auch schreibgeschützt aus SQLite bestätigt. **579 importiert /0 aktuell /0 später**, genau **43 E-Mail-Ziele** und dieselben elf Themen. Gesamtentscheidung **579 aus 857 Kandidaten /278 Ausschlüsse**, keine Auffüllung auf 1500/70. Batches 97/97/97/96/96/96 unverändert.

Alle 14 Stapel gegen Roadmap und tatsächlich ausgeführte App-Projektion geprüft:

| Stapel | Tatsächliche App-Übungen |
|---|---:|
| allgemeine-sprache | 160 |
| reisen | 489 |
| alltag-zuhause | 241 |
| arbeit-bildung | 245 |
| menschen-beziehungen | 245 |
| koerper-gesundheit | 249 |
| essen-trinken | 250 |
| natur-umwelt | 242 |
| irregular_verbs_base | 134 |
| irregular_verbs_past | 134 |
| irregular_verbs_participle | 134 |
| alltagssprache-redewendungen | 441 |
| verbalphrasen | 181 |
| business-email | 579 |

Globale Werte aus der vorhandenen App-Projektion `tool/report_learning_groups.dart`, **3654 Übungen /3383 lexikalische Ziele**; keine Addition der Stapelzahlen. 3768 physische Karten und 3557 Besitzerzeilen sind keine Wortzähler. Dasselbe Verb-Lemma wird durch drei Formansichten nicht dreimal als neues Wort ausgewiesen.

**Abweichung des mitgelieferten completion_audit.json:** globale Werte 3654/3383 und Business 579/43 bestätigt. Seine einzelnen `decks[].practice_targets` zählen Gruppen-IDs aus der Vereinigung aller Eigentümer- und Formkarten. Die mitgelieferte finish.py (Zeilen 31–36, nur gelesen) verwendet dabei weder die normale Einführungsbeschränkung noch die App-Projektion. Deshalb sind diese Werte bei folgenden Stapeln keine aktuellen App-Übungszahlen. Original-Lieferung unverändert; lokale App-Projektion ist maßgeblich:

| Stapel | Liefer-Audit practice_targets | App-Projektion |
|---|---:|---:|
| allgemeine-sprache | 181 | 160 |
| reisen | 508 | 489 |
| alltag-zuhause | 262 | 241 |
| arbeit-bildung | 252 | 245 |
| menschen-beziehungen | 251 | 245 |
| koerper-gesundheit | 264 | 249 |
| natur-umwelt | 248 | 242 |
| irregular_verbs_base | 203 | 134 |

Lokaler Nachweis `completion-audit.json`; keine neue Auswahl/Registry/Gruppendatei und kein Fortsetzungsexport. Keine Batch-7-ZIP, kein Restbatch, keine zusätzliche Kategorie.

## Sicherung und technische Testlücke

Asset und Manifest **vor Staging** bytegleich gesichert unter `build/business_email_batch_6_checks/backup/`, UTC `2026-10-14T10:22:49.400609+00:00`. Danach internes Staging und separater `--verify`: 22 Tabellen, Export/Asset bytegleich. 455 Pipeline-Tests plus 19 Untertests und Flutter-Analyse bestanden. Exakter bestehender Pack-Lesetest `test/data/real_pack_test.dart`, reguläres Budget unverändert. Standardlauf: Exit 1, 41.19 Sekunden Gesamtprozesszeit, reguläres 30-Sekunden-Budget. Standard-Testabnahme und Timeoutursache bleiben offen. Gesonderte Drei-Minuten-Diagnose: Exit 0, 126.65 Sekunden Gesamtprozesszeit. Ein Diagnose-PASS ist kein Standard-PASS und keine Ursachenbehebung.

Der Batch-5-Langlauf mit 124,60s ist ausschließlich ein historischer Beleg. Die neue Diagnose dieses Auftrags prüft den **anderen finalen Batch-6-Pack** vollständig über den vorhandenen Installer/Repository-Leser und alle festen Satzzuordnungen; das frühere Ergebnis bestätigt dieses neue Asset nicht. Einmaliger diagnostischer CLI-Budgetwert 3m nach erneutem Standard-Timeout, anhand des bisherigen Laufzeitbelegs begründet. Keine unveränderte Standard-Wiederholung, keine allgemeine Performance-Reparatur. Testdatei, Installer und ContentDatabase hashgleich zur Ausgangsbasis; kein Testtimeout im Repository geändert.

Regelvorschlag, ohne Änderung von AGENTS.md: **WENN ein Standard-Pack-Test wiederholt ausläuft → NIE einen Lauf mit erhöhtem Zeitbudget als Behebung oder Standard-PASS ausgeben.**

## Hashnachweise

Rohbyte-SHA256, sofern nicht als kanonischer JSON-Digest bezeichnet:

| Objekt | SHA256 |
|---|---|
| Original-Liefer-ZIP | `a6ac2d1794f752c81c25187f72ab2242de72955ae5dc0b06ed3316ae4a8e8e1c` |
| Create (Original/Arbeitskopie) | `2c583016a34615ab637bde5fee9c8a82f84df193fcddd865a06c56b9ee41dfc3` |
| Basis pack.json | `065a2826e1c612f21bd1dc8d3e1d0dc0251a6e092f5a6e874c20f6ec697c4800` |
| Registry (kanonisch) | `4736bf4819a17cdabd5f57a60f08f53760ade24ef45e87464e1fcbeaa39dc97e` |
| Lerngruppen (kanonisch) | `d193c1a0f074e311244f3b4d7a18544e38a4fae0dba1f9fda9f8e26a2e7ae02a` |
| Finales Asset-Manifest | `e7d08191f670df2b96d4401ac0891b2f49412661f106ba930de4f831f86b0abf` |
| Backup content.sqlite | `41ea3bc7fc79674f33e5caef09d22a56fb1163ff66d743c3555fcf86d21a35a3` |
| Backup content.manifest.json | `9ea5c73a0d57168ff55dd6fed6455890e2efa673db77ea40fabf97279909cb4e` |
| Export pack.json | `48f8c3037e37cf8aaa83188c868af6706fd7f749592785433ee30b74070800d4` |
| Export content.sqlite | `843c127e2e4cdd0d0efd5c52f648db30adcb3a477e0bfd3f9a66eed869dfb1f9` |
| Export finalization_report.json | `ce36f83af221e81c431b1a95e2fba86f00bfd6c81e2b75fcd3d8fbfe34ba618f` |

Finales internes Pack: `/Users/ardasayar/Documents/FlutterProjekte/sprachapp/pipeline/out/business_email_batch_6_v1/`.

## Tatsächlich ausgeführte Befehle und Outputs

Ab Repository-Root auf macOS. Windows PowerShell: Pythonpfad `.\pipeline\.venv\Scripts\python.exe`; sonstige Argumente gleich. Dart/Flutter/Git plattformgleich. Wrapper `build/business_email_batch_6_checks/run_check.py NAME BEFEHL …` speichert vollständige Outputs, Exitcodes und Laufzeiten als `NAME.log`/`NAME.command.json`. Auszüge unten gekürzt, vollständige Logs im Prüfverzeichnis. Die Diagnose ist gesondert gekennzeichnet.

```text
python3 build/business_email_batch_6_checks/baseline.py
status-before.txt 0  M NEXTSTEPS.md
?? alltagssprache_redewendungen_batch_3/
?? alltagssprache_redewendungen_batch_4/
?? alltagssprache_redewendungen_batch_5/
?? business_email_batch_1/
?? business_email_batch_2/
?? business_email_batch_3/
?? business_email_batch_4/
?? business_email_batch_5/
?? business_email_batch_6/
?? docs/alltagssprache-redewendungen-batch-3-import.md
?? docs/alltagssprache-redewendungen-batch-4-import.md
?? docs/codebase-overview-planning.md
?? editorial_review/business_email_batch_3/
?? editorial_review/business_email_batch_4/
?? editorial_review/business_email_batch_5/
?? pipeline/data/learning_groups/en.alltagssprache_redewendungen_batch_4_context_v2.json
?? pipeline/data/learning_groups/en.alltagssprache_redewendungen_batch_5_context_v2.json
?? pipeline/data/selection/alltagssprache_redewendungen_batch_4_context_v2.json
?? pipeline/data/selection/alltagssprache_redewendungen_batch_5_context_v2.json
?? pipeline/data/words/en.alltagssprache_redewendungen_batch_4_context_v2.json
?? pipeline/data/words/en.alltagssprache_redewendungen_batch_5_context_v2.json
?? verbalphrasen_batch_1/
?? "verbalphrasen_batch_2 2/"

index-before.txt 0
head.txt 0 cfbaa12e9b91e875f42e7c4b06b4ac8028f810bf

baseline_files 3223
EXIT 0; Laufzeit 2.17 s
```

```text
pipeline/.venv-macos/bin/python build/business_email_batch_6_checks/delivery_audit.py
Traceback (most recent call last):
  File "/Users/ardasayar/Documents/FlutterProjekte/sprachapp/build/business_email_batch_6_checks/delivery_audit.py", line 26, in <module>
    current=[e for e in s['entries'] if e['authoring_batch']==6];assert len(current)==96 and len(s['entries'])==679
                                                                        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
AssertionError
EXIT 1; Laufzeit 7.65 s
```

```text
pipeline/.venv-macos/bin/python build/business_email_batch_6_checks/delivery_audit.py
{
  "status": "PASS",
  "manifest_exception": null,
  "delivery_zip": "/Users/ardasayar/Downloads/business_email_batch_6_lieferung.zip",
  "zip_sha256": "a6ac2d1794f752c81c25187f72ab2242de72955ae5dc0b06ed3316ae4a8e8e1c",
  "create_sha256": "2c583016a34615ab637bde5fee9c8a82f84df193fcddd865a06c56b9ee41dfc3",
  "manifest_files": 35,
  "all_local_files_match_zip": true,
  "source_json_sha256": "065a2826e1c612f21bd1dc8d3e1d0dc0251a6e092f5a6e874c20f6ec697c4800",
  "registry_digest": "4736bf4819a17cdabd5f57a60f08f53760ade24ef45e87464e1fcbeaa39dc97e",
  "groups_digest": "d193c1a0f074e311244f3b4d7a18544e38a4fae0dba1f9fda9f8e26a2e7ae02a",
  "current": 96,
  "total": 579,
  "words": 1042,
  "punctuation": 107,
  "alternatives": [
    [
      "email address|email address/NOUN|email-address#e-mail-adresse",
      "e-mail address"
    ],
    [
      "call centre|call centre/NOUN|call-centre#telefonservicezentrum",
      "call center"
    ],
    [
      "drop-down menu|drop-down menu/NOUN|drop-down-menu#auswahlliste",
      "dropdown menu"
    ]
  ],
  "future_companion_senses": [],
  "add_counts": {
    "lemmas": 110,
    "senses": 139,
    "cards": 96,
    "decks": 0,
    "deck_cards": 96,
    "deck_words": 96,
    "word_aliases": 0,
    "sentences": 96,
    "sentence_tokens": 1149,
    "dictionary_forms": 169,
    "card_sentences": 96
  }
}
EXIT 0; Laufzeit 10.04 s
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
455 passed, 19 subtests passed in 28.57s
EXIT 0; Laufzeit 29.1 s
```

```text
pipeline/.venv-macos/bin/python pipeline/scripts/import_editorial_patch.py --source pipeline/out/business_email_batch_5_v1/pack.json --create editorial_review/business_email_batch_6/editorial_content_v2.json --display-patch editorial_review/business_email_batch_6/deck_display_patch.json --registry pipeline/data/words/en.business_email_batch_6_context_v1.json --out pipeline/out/business_email_batch_6_v1
{
  "status": "ok",
  "internal_test_pack": true,
  "ai_calls": 0,
  "ai_cost_usd": 0,
  "sqlite_counts": {
    "languages": 1,
    "lemmas": 5007,
    "senses": 6759,
    "cards": 3768,
    "dictionary_forms": 8089,
    "decks": 14,
    "deck_cards": 3661,
    "deck_words": 3557,
    "word_aliases": 37,
    "sentences": 4302,
    "sentence_tokens": 47082,
    "card_sentences": 4296,
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
  "sha256": "843c127e2e4cdd0d0efd5c52f648db30adcb3a477e0bfd3f9a66eed869dfb1f9"
}
EXIT 0; Laufzeit 19.68 s
```

```text
pipeline/.venv-macos/bin/python build/business_email_batch_6_checks/export_audit.py
PRESERVED pick out {"ref": "pick out/VERB|pick-out#wiedererkennen", "lemma": "pick out/VERB", "sense_key": "pick-out#wiedererkennen", "gloss_de": "wiedererkennen", "definition_de": "Eine bestimmte Person oder Sache in einer größeren Menge erkennen."}
PRESERVED pull over {"ref": "pull over/VERB|pull-over#rechts-ranfahren", "lemma": "pull over/VERB", "sense_key": "pull-over#rechts-ranfahren", "gloss_de": "rechts ranfahren", "definition_de": "Mit einem Fahrzeug an den Straßenrand fahren und dort anhalten."}
Business existing positions changed 0
{
  "status": "PASS",
  "old_business_positions_changed": 0,
  "tables": {
    "languages": 1,
    "lemmas": 5007,
    "senses": 6759,
    "cards": 3768,
    "dictionary_forms": 8089,
    "decks": 14,
    "deck_cards": 3661,
    "deck_words": 3557,
    "word_aliases": 37,
    "sentences": 4302,
    "sentence_tokens": 47082,
    "card_sentences": 4296,
    "stories": 1,
    "story_sentences": 6,
    "exercises": 0,
    "grammar_rules": 0,
    "audio_assets": 0,
    "content_releases": 1,
    "lexical_targets": 134,
    "card_lexical_targets": 406,
[gekürzt; vollständiger Output im Log]
arn",
      "rule": "i+1",
      "message": "'invoice'/'invoice' Zipf 3.27 below 3.5"
    },
    {
      "card": "incorrect|incorrect/ADJ|incorrect#falsch",
      "level": "warn",
      "rule": "i+1",
      "message": "'invoice'/'invoice' Zipf 3.27 below 3.5"
    },
    {
      "card": "payable|payable/ADJ|payable#zu-zahlen",
      "level": "warn",
      "rule": "i+1",
      "message": "'invoice'/'invoice' Zipf 3.27 below 3.5"
    }
  ],
  "errors": 0,
  "sha256": {
    "pack.json": "48f8c3037e37cf8aaa83188c868af6706fd7f749592785433ee30b74070800d4",
    "content.sqlite": "843c127e2e4cdd0d0efd5c52f648db30adcb3a477e0bfd3f9a66eed869dfb1f9",
    "finalization_report.json": "ce36f83af221e81c431b1a95e2fba86f00bfd6c81e2b75fcd3d8fbfe34ba618f"
  }
}
EXIT 0; Laufzeit 2.97 s
```

```text
pipeline/.venv-macos/bin/python build/business_email_batch_6_checks/review_record.py
PASS 96 pairs /1149 tokens; 0 binding corrections; 3 literal alternatives; 6 inherited gloss comparisons; all old SQL rows including positions unchanged.
EXIT 0; Laufzeit 0.64 s
```

```text
python3 build/business_email_batch_6_checks/backup_before_stage.py
{
  "status": "PASS",
  "time_utc": "2026-10-14T10:22:49.400609+00:00",
  "hashes": {
    "content.sqlite": "41ea3bc7fc79674f33e5caef09d22a56fb1163ff66d743c3555fcf86d21a35a3",
    "content.manifest.json": "9ea5c73a0d57168ff55dd6fed6455890e2efa673db77ea40fabf97279909cb4e"
  },
  "before_staging": true
}
EXIT 0; Laufzeit 0.08 s
```

```text
dart run tool/stage_content_pack.dart --from pipeline/out/business_email_batch_6_v1
staged assets/content/en/content.sqlite
  version business_email_batch_6_v1, schema 4, 23408640 bytes
  sha256 843c127e2e4cdd0d0efd5c52f648db30adcb3a477e0bfd3f9a66eed869dfb1f9
  22 table counts match finalization_report.json
  INTERNES TEST-PACK: own devices and selected testers only, no public content release
Running build hooks...Running build hooks...
EXIT 0; Laufzeit 73.11 s
```

```text
dart run tool/stage_content_pack.dart --verify
verified assets/content/en/content.sqlite
  version business_email_batch_6_v1, schema 4, 23408640 bytes
  sha256 843c127e2e4cdd0d0efd5c52f648db30adcb3a477e0bfd3f9a66eed869dfb1f9
  22 table counts match finalization_report.json
  INTERNES TEST-PACK: own devices and selected testers only, no public content release
Running build hooks...Running build hooks...
EXIT 0; Laufzeit 40.15 s
```

```text
dart run tool/report_learning_groups.dart pipeline/out/business_email_batch_6_v1/content.sqlite
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
    "raw_words": 579,
    "learning_targets": 579,
    "lexical_words": 579,
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
    "raw_words": 3735,
    "learning_targets": 3654,
    "lexical_words": 3383,
    "form_memberships": 402
  }
}
EXIT 0; Laufzeit 35.6 s
```

```text
pipeline/.venv-macos/bin/python build/business_email_batch_6_checks/completion_audit.py
{
  "status": "PASS",
  "business_targets": 579,
  "email_targets": 43,
  "partition": {
    "imported": 579,
    "current": 0,
    "future": 0
  },
  "all_579_ids_definitions_learning_owners_aliases_matched": true,
  "all_primary_business_heads_one_active_fixed_sentence": true,
  "planned_decks": 14,
  "app_learning_targets": {
    "allgemeine-sprache": 160,
    "reisen": 489,
    "alltag-zuhause": 241,
    "arbeit-bildung": 245,
    "menschen-beziehungen": 245,
    "koerper-gesundheit": 249,
    "essen-trinken": 250,
    "natur-umwelt": 242,
    "irregular_verbs_base": 134,
    "irregular_verbs_past": 134,
    "irregular_verbs_participle": 134,
    "alltagssprache-redewendungen": 441,
    "verbalphrasen": 181,
    "business-email": 579
  },
  "global_exercises": 3654,
  "global_lexical_targets": 3383,
  "cards": 3768,
  "supplier_projection_differences": [
    {
      "deck": "allgemeine-sprache",
      "supplier_practice_targets": 181,
      "actual_app_learning_targets": 160
    },
    {
      "deck": "reisen",
      "supplier_practice_targets": 508,
      "actual_app_learning_targets": 489
    },
    {
      "deck": "alltag-zuhause",
      "supplier_practice_targets": 262,
      "actual_app_learning_targets": 241
    },
    {
      "deck": "arbeit-bildung",
      "supplier_practice_targets": 252,
      "actual_app_learning_targets": 245
    },
    {
      "deck": "menschen-beziehungen",
      "supplier_practice_targets": 251,
      "actual_app_learning_targets": 245
    },
    {
      "deck": "koerper-gesundheit",
      "supplier_practice_targets": 264,
      "actual_app_learning_targets": 249
    },
    {
      "deck": "natur-umwelt",
      "supplier_practice_targets": 248,
      "actual_app_learning_targets": 242
    },
    {
      "deck": "irregular_verbs_base",
      "supplier_practice_targets": 203,
      "actual_app_learning_targets": 134
    }
  ],
  "no_next_authoring_zip": true,
  "pack_sha256": "48f8c3037e37cf8aaa83188c868af6706fd7f749592785433ee30b74070800d4",
  "sqlite_sha256": "843c127e2e4cdd0d0efd5c52f648db30adcb3a477e0bfd3f9a66eed869dfb1f9"
}
EXIT 0; Laufzeit 2.12 s
```

```text
flutter analyze --no-pub
Analyzing sprachapp...
No issues found! (ran in 4.4s)
EXIT 0; Laufzeit 5.35 s
```

```text
flutter test --no-pub test/data/real_pack_test.dart
00:00 +0: loading /Users/ardasayar/Documents/FlutterProjekte/sprachapp/test/data/real_pack_test.dart
00:00 +0: staged pack: all cards and sentence links readable, read-only
00:38 +0 -1: staged pack: all cards and sentence links readable, read-only [E]
  TimeoutException after 0:00:30.000000: Test timed out after 30 seconds. See https://pub.dev/packages/test#timeouts
  dart:isolate  _RawReceivePort._handleMessage

00:38 +0 -1: Some tests failed.

Failing tests:
  /Users/ardasayar/Documents/FlutterProjekte/sprachapp/test/data/real_pack_test.dart: staged pack: all cards and sentence links readable, read-only
EXIT 1; Laufzeit 41.19 s
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
deck business-email: 579 learning targets, 579 ownership cards, 579 fixed sentence assignments verified
pack business_email_batch_6_v1 (schema 4, internal: true); 14 decks: 3557 cards, 3768 card sentences, 204 with valid_alternatives, 3768 cards in the pack
02:04 +1: All tests passed!
EXIT 0; Laufzeit 126.65 s
```

```text
git diff --check
[keine Ausgabe]
EXIT 0; Laufzeit 0.03 s
```

```text
python3 build/business_email_batch_6_checks/final_audit.py
Traceback (most recent call last):
  File "/Users/ardasayar/Documents/FlutterProjekte/sprachapp/build/business_email_batch_6_checks/final_audit.py", line 11, in <module>
    files=subprocess.check_output(['git','ls-files','--cached','--others','--exclude-standard','-z']).decode().split('\0');new=[f for f in files if f and f not in base];assert all(f=='docs/business-email-batch-6-import.md' or f.startswith('editorial_review/business_email_batch_6/') for f in new),new
                                                                                                                                                                                ~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
AssertionError: ['editorial_review/business_email_batch_6/LESEN.md', 'editorial_review/business_email_batch_6/Prompt_Business_Email_Batch_6_Import.txt', 'editorial_review/business_email_batch_6/README.txt', 'editorial_review/business_email_batch_6/alternative_review.json', 'editorial_review/business_email_batch_6/authoring_evidenc
[gekürzt; vollständiger Output im Log]
il_batch_6/reference/continuation_display_mapping.json', 'editorial_review/business_email_batch_6/reference/editorial_content_v2.schema.json', 'editorial_review/business_email_batch_6/reference/learning_groups.json', 'editorial_review/business_email_batch_6/reference/manifest.json', 'editorial_review/business_email_batch_6/reference/original_selection.json', 'editorial_review/business_email_batch_6/reference/registry.json', 'editorial_review/business_email_batch_6/reference/selection.json', 'editorial_review/business_email_batch_6/reference/tokenizer_linter_environment.json', 'editorial_review/business_email_batch_6/token_review.json', 'editorial_review/business_email_batch_6/validation_report.json', '.env.example', 'pipeline/.env.example']
EXIT 1; Laufzeit 2.0 s
```

```text
python3 build/business_email_batch_6_checks/final_audit.py
{
  "status": "PASS",
  "baseline_files": 3223,
  "changed_existing_files": [
    "assets/content/en/content.manifest.json",
    "assets/content/en/content.sqlite",
    "docs/content-roadmap-v1.md"
  ],
  "new_git_visible_files": [
    "editorial_review/business_email_batch_6/LESEN.md",
    "editorial_review/business_email_batch_6/Prompt_Business_Email_Batch_6_Import.txt",
    "editorial_review/business_email_batch_6/README.txt",
    "editorial_review/business_email_batch_6/alternative_review.json",
    "editorial_review/business_email_batch_6/authoring_evidence/analyze.py",
    "editorial_review/business_email_batch_6/authoring_evidence/base_bindings.json",
    "editorial_review/business_email_batch_6/authoring_evidence/build.py",
    "editorial_review/business_email_batch_6/authoring_evidence/decisions.py",
    "editorial_review/business_email_batch_6/authoring_evidence/finish.py",
    "editorial_review/business_email_batch_6/authoring_evidence/form_glosses.json",
    "editorial_review/business_email_batch_6/authoring_evidence/linter.json",
    "editorial_review/business_email_batc
[gekürzt; vollständiger Output im Log]
review/business_email_batch_6/reference/tokenizer_linter_environment.json",
    "editorial_review/business_email_batch_6/token_review.json",
    "editorial_review/business_email_batch_6/validation_report.json"
  ],
  "original_delivery_and_working_copy_identical": true,
  "historic_sources_reservations_and_foreign_files_unchanged": true,
  "backup_hashes_unchanged": true,
  "no_batch_7_or_new_selection": true,
  "production_and_test_code_unchanged": true,
  "hashes": {
    "pack.json": "48f8c3037e37cf8aaa83188c868af6706fd7f749592785433ee30b74070800d4",
    "content.sqlite": "843c127e2e4cdd0d0efd5c52f648db30adcb3a477e0bfd3f9a66eed869dfb1f9",
    "content.manifest.json": "e7d08191f670df2b96d4401ac0891b2f49412661f106ba930de4f831f86b0abf"
  }
}
EXIT 0; Laufzeit 1.93 s
```

## Abweichungen, Isolation und offene Aufgaben

Die anfängliche Pfadsondierung hatte Exit 1, weil Arbeitskopie/Prüf- und Ausgabeordner noch nicht existierten; Original-ZIP und Root-Entpackung vorhanden. Der erste lokale Auditlauf hatte Exit 1: bei der Anpassung des eigenen Prüfscripts wurde die erwartete Gesamtzahl versehentlich 679 statt 579. Assertion im lokalen Script korrigiert, danach vollständiger Liefercheck PASS. Ein eigener Bestandsaudit hatte ebenfalls Exit 1: die Baseline ließ .env-Pfade aus, die Schlussliste behandelte deshalb die bereits getrackten .env.example-Dateien irrtümlich als neu. Hypothese durch den identischen Baseline-Filter und separaten Git-Diff dieser Beispieldateien geprüft; kein Inhalts-/Lieferfehler. Kein Liefer-/Vertragsfehler, keine Lieferkorrektur oder Produktionsvalidatoränderung. Liefer-Audit-Zählabweichungen oben sachlich ausgewiesen.

GitNexus-Index **zehn Commits hinter Ausgangs-HEAD**. Impact vor Bearbeitung: Roadmap **LOW**, zwei direkte Dokumentreferenzen (Natur-Authoring und Verbenplan), neun insgesamt erreichte Dokumente, null indexierte Prozesse. NEXTSTEPS ohne aufgelöste Caller/Prozesse **UNKNOWN**; neuer Bericht und Asset nicht indexiert, ebenfalls UNKNOWN. Keine HIGH/CRITICAL-Warnung. UNKNOWN/fehlende Abdeckung ist keine Freigabe; aktuelle Quellverträge, vollständiger Bestands-/Tabellenabgleich, App-Projektion und tatsächlicher Lesetest bilden die Inhaltsprüfung. Keine Produktionssymbole editiert. Rohbeleg `gitnexus-preflight.json`; Graph-Änderungsprüfung vor Commit separat gespeichert.

Repositoryweiter und eigener Whitespacecheck mit tatsächlichem Output; historische DESIGN-/Alltag-Zuhause-/Arbeit-Bildung-Befunde separat erhalten, keine globale CRLF-/Whitespacebereinigung. Roadmap nur um nachgewiesene aktuelle Abschlussangaben aktualisiert, historische Prüfstände erhalten. Isolierter Commit ausschließlich neuer Bericht und aktuelle Roadmap; vorbestehend geändertes NEXTSTEPS und bytegleiche Liefer-Arbeitskopie bleiben lokal. Pack, Asset, Sicherung und Checks gemäß vorhandener Repository-Konvention gitignoriert. Keine fremden Dateien oder historischen Auswahlen im Commit.

Geplante Inhaltslieferung der 14 Stapel intern abgeschlossen. Nächste technische Aufgabe: **Ursache des Standard-Pack-Test-Timeouts untersuchen und die reguläre Testabnahme herstellen**. Öffentliche Sprachfreigabe, Altglossen-/Labelredaktion und Geräteprüfung sind eigene offene Punkte. Keine echte user.db oder Lernstände geöffnet/verändert; keine Cloud-/Modellaufrufe, Paketinstallation, automatische Satzgenerierung, öffentliche Freigabe oder Push.

## Abschließende Prüfungen

Neue Drei-Minuten-Diagnose: **PASS, Exit 0, 126,65 Sekunden Gesamtprozesszeit**, Testanzeige 02:04. Alle 14 Stapel, 3768 feste Satzzuordnungen und 204 Verknüpfungen mit geprüften Alternativen lesbar; keine Assertion fehlgeschlagen. Der reguläre Lauf bleibt mit 30-Sekunden-Timeout offen (41,19 Sekunden Gesamtprozess). Nach Dokumentaktualisierung wurden sämtliche 14 Roadmap-Titel und Mengen exakt gegen die App-Projektion geprüft. Repositoryweiter und eigener `git diff --check`: keine Ausgabe, Exit 0. NEXTSTEPS hat 25 Zeilen. Vollständiger abschließender Bestandsschutz unter `final-audit-after-docs.log`; Original, historische Quellen und Reservierungen erhalten.

GitNexus `detect_changes(scope="all")`: neun indexierte Dokumentabschnitte in NEXTSTEPS/Roadmap, keine ermittelten Prozesse. `scope="staged"`: exakt zwei Dateien, fünf indexierte Roadmap-Abschnitte, keine ermittelten Prozesse; keine partial-/truncated-Markierung. Neuer Bericht und Inhaltsassets haben keine Symbolabdeckung. Das ist keine Graph-Freigabe für diese Dateien; die vollständigen Inhalts- und Bestandsschutzprüfungen liefern den konkreten Nachweis. Rohresultate: `gitnexus-changes.json`.

Geänderte Dateien/Artefakte: neuer `docs/business-email-batch-6-import.md`, aktualisierte `docs/content-roadmap-v1.md` und `NEXTSTEPS.md`, neue bytegleiche `editorial_review/business_email_batch_6/`, neuer `pipeline/out/business_email_batch_6_v1/`, intern aktualisierte `assets/content/en/content.sqlite` und `assets/content/en/content.manifest.json`. Keine Auswahl-/Registry-/Gruppendatei geändert. Commitumfang exakt Bericht und Roadmap; Ausgangsindex leer, vorbestehende Anteile ausgeschlossen.
