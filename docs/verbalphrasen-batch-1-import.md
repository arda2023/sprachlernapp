# Verbalphrasen: Batch 1 offline importiert und intern gestagt

Stand: **13.10.2026**. Exakt **91 aktuelle Ziele** als `verbalphrasen_batch_1_v1` importiert und intern gestagt. **13 Stapel, 3099 Karten**, neue Anzeigen **1–91**, tatsächliche App-Projektion **2985 Übungen / 2714 Wörter**. Gesamtauswahl weiterhin **181**, davon **91 importiert / 90 aktuell / 0 später**. Die Batch-2-ZIP ist geschlossen und erneut vollständig geprüft. Technische interne Abnahme ist keine öffentliche Sprach-/Gerätefreigabe.

## Verwendete Verträge und Dateien

AGENTS/CLAUDE, NEXTSTEPS, Roadmap, Verbalphrasen-Authoring-Bericht, Alltagssprache-Batch-5-Abschluss, normale Schema-4-Kompatibilität, Content-/Lerngruppenvertrag, tatsächliches V2-Schema und aktuelle Import-/Exportquellen geprüft. Bestehender normaler V2-Create-Weg auf Schema 4, explizite Registry, kein neuer Exporter, keine Implementierungs-/SRS-/Antwortlogikänderung oder Indexneubau. Die ältere Commit-Blockerbehauptung im historischen Kompatibilitätsbericht trifft hier nicht zu: die benötigte Implementierung ist auf HEAD, keine uncommittete Codeabhängigkeit.

- Original-ZIP: `/Users/ardasayar/Downloads/verbalphrasen_batch_1_lieferung.zip`.
- Bereits entpacktes Original: `verbalphrasen_batch_1/`; alle 31 Archivdateien identisch zur ZIP, CRCs und 30 Liefermanifesthashes unabhängig geprüft. Kein Original überschrieben oder ausgeführt.
- Korrigierte Importkopie: `build/verbalphrasen_batch_1_checks/corrected/editorial_content_v2.json`; Änderungen/Historie: `corrected/corrections.json`.
- Basis: `pipeline/out/alltagssprache_redewendungen_batch_5_v1/{pack.json,content.sqlite}`.
- Auswahl: `pipeline/data/selection/verbalphrasen_v1.json` und Batch-1-Kontext gleichen Namens mit `_batch_1_context_v1`.
- Tatsächliche Import-Registry: `pipeline/data/words/en.verbalphrasen_batch_1_context_v1.json`.
- Tatsächliche Ausgangsgruppen: `pipeline/data/learning_groups/en.verbalphrasen_batch_1_context_v1.json`.
- Ausgabe: `pipeline/out/verbalphrasen_batch_1_v1/{pack.json,content.sqlite,finalization_report.json}`.
- Aktuelles internes Asset/Manifest: `assets/content/en/{content.sqlite,content.manifest.json}`.
- Prüfausgaben: `build/verbalphrasen_batch_1_checks/`.

Der Basis-Pack enthält seine tatsächliche Registry als Snapshot (historische Version `alltagssprache_redewendungen_batch_5_context_v2`); für diesen Import bindet die neue Verbalphrasen-Registry genau an dessen kanonischen Digest. Die Ausgangsgruppen enthalten bereits die finalen 3008 Karten, nicht bloß den historischen Alltagssprache-Kontext mit 2921 bestehenden plus 87 damals geplanten Karten. Neue Batch-2-Gruppen werden über den bestehenden Fortsetzungsweg aus den jetzt finalen **3099 Karten / 3087 Gruppen** abgeleitet. Neue Registry weiterhin **2979 Reservierungen**: alte Besitzer, 91 importierte Verbalphrasen, 90 spätere Ziele und die geerbte obsolete Reservierung bleiben erhalten. Aktive Besitzer **2888**, keine neuen Besitzaliase, alte **37 Aliase** erhalten.

## Vollständige Lieferung und Bedeutungsprüfung

Die Quelle ist exakt Schema 4, Version `alltagssprache_redewendungen_batch_5_v1`; Basis-, SQLite-, Registry- und Gruppenhash stimmen mit dem Auftrag überein. Create-Rohhash unabhängig gegen Liefermanifest und validation_report nachgerechnet. Referenzsubset entspricht bytegleich der geprüften Batch-1-Authoring-ZIP. Liefer-In-Memory-Prüfung ist nur Vorinformation; unten ist der echte lokale CLI-Import samt neuem Export nachgewiesen.

Alle **91 englisch-deutschen Satzpaare und 916 Tokenpositionen** gegengelesen: **805 Wort-/Ausdruckstokens und 111 Satzzeichen**. Offsets, vollständige Tokenabdeckung mit vorhandenen `lexical_spans`, Wörterbuchschlüssel, Lemma-/Sense-Bindungen und Reviewhashes zusätzlich maschinell geprüft. Die vollständige Zielform bildet jeweils genau eine zusammenhängende Lücke und einen Token; `accepted == [card.form]`. Karten-/Sense-/Gruppenidentitäten, ursprüngliche Positionen und Definitionen entsprechen exakt der Gesamtauswahl. Keines der 90 späteren Ziele importiert; alle 123 ausgeschlossenen Kandidaten bleiben ausgeschlossen, keine Auffüllung.

Bedeutungsfokus: pick out = eine Person/Sache in einer Menge erkennen, bring up = Kinder großziehen, set off = Alarm auslösen, go out = erlöschen, turn down = leiser stellen. Die Sätze behalten diese Bedeutung; keine häufigere andere Bedeutung eingesetzt.

Begleitbindungen explizit geprüft: `lesson` Unterrichtsstunde, `lock/NOUN` Schloss, `competition` wirtschaftliche Konkurrenz, `belt` Sicherheitsgurt, `treatment` Umgang mit Menschen. Das erste `to` in narrow down ist `to/PART`, das zweite `to/ADP`. `is` in turn down ist Verlaufsform-Hilfsverb; `inside` in coming inside `inside/ADV`; `by` in by months ein Differenzmaß. Gegenlesen umfasst auch zwölf geerbte Glossenvergleiche unten. Wörterbuchzusätze erzeugen keine Lernkarten: **80 ausgewählte neue Ziel-Senses / 11 vorhandene Ziel-Senses wiederverwendet / 37 neue Begleit-Senses**, zusammen **117 neue Senses und 145 neue Formglossen**, aber nur 91 neue Karten.

Drei wörtlich geprüfte Ersetzungen, gemäß `alternative_review.json`: come round → come around; get along with → get on with; turn on → switch on. Ersatztext, Satz-/Linkhash und Begründung geprüft; keine Kollision mit 181 Zielen, aktiven/historischen Karten, Besitzreservierungen/-aliasen oder späteren Gruppen. Keine automatische Antwortfreigabe aus Gruppenmitgliedschaft. Diese Alternativen bleiben lernstandsneutral; `accepted` bleibt die exakte Zielform.

### Zwei gezielte Formglossenpräzisierungen

Die knappen Labels stammen **bereits aus der unveränderten Auswahl**, nicht erst aus der Lieferung. Die festen Definitionen sind maßgeblich. In der separaten Importkopie ausschließlich zwei neue `dictionary_forms.gloss_de` präzisiert, plus die zwei zugehörigen Reviewbegründungen:

| Form | Original-Formglosse | Import-Formglosse |
|---|---|---|
| pick out | wiedererkennen | aus einer Menge erkennen |
| pull over | rechts ranfahren | an den Straßenrand fahren und anhalten |

Sätze/Übersetzungspaare, Tokens, Links, Karten-/Sense-/Lemma-IDs, `cards.learning`, neue Sense-Zeilen und Kartenübersetzungen bleiben exakt. Die unveränderlichen Auswahl-/Sense-/Kartenlabels `wiedererkennen` und `rechts ranfahren` sind daher weiterhin **zwei separate offene Auswahlglossenbefunde**; keine stillschweigende Änderung der historischen Auswahl. Keine künstliche neue Bedeutung oder Reservierung angelegt. Diese Einträge werden nicht als erledigte globale Glossenbereinigung ausgegeben.

Die 91 `reviews.checked` wurden mit dem vorhandenen `import_editorial_patch.digest` neu gebunden. Token-/Linkbytes unverändert, daher diese Hashes identisch; nur zwei begründete Reviewtexte und deren dokumentierte kanonische Digests ändern sich. Alle übrigen Reviews exakt erhalten. Die Original-Lieferhashes beziehen sich weiterhin auf die Originaldatei; der CLI-Import verwendet den gesonderten korrigierten Create-Hash unten.

## Export, Bestandsschutz und Sicherung

Alle **22 SQLite-Tabellen** erneut zeilen-/spaltenweise mit `build_rows`/`finalize_curation.check_sqlite` abgeglichen. Ausnahme: exportgenerierter `content_releases.created_at`, gemäß bestehendem Verifier; neue Release-/Registry-Metadaten fortgeschrieben. Sämtliche alten JSON-Listen als exakte Präfixe erhalten und alle alten SQL-Zeilenwerte unverändert. Das umfasst alle zwölf alten Stapel, historische Satzlinks, QA-Metadaten und frühere gezielte Importkorrekturen, einschließlich der 13 Alltagssprache-Korrekturen. Keine alte Satz-/Wort-/Gruppenentscheidung geändert.

Vier Formtabellen `lexical_targets`, `card_lexical_targets`, `form_targets`, `deck_practice_targets` mit exakt gleichen Zeilenwerten, **134/134/134 Verbenübungen** und **402 Formziele** erhalten. Exakt ein aktiver fester Satz je neuer Karte. Neue Anzeigen 1–91 entsprechen geliefertem `combined_display_mapping.json`; neuer Stapel, kein Display-Patch nötig. Originalpositionen unverändert.

**Vor Staging** bytegleich gesichert: `build/verbalphrasen_batch_1_checks/backup/content.sqlite` und `backup/content.manifest.json`; Nachweis `backup/hashes.json`. Die ignorierten Assetpfade wurden noch vor Staging separat in die Baseline aufgenommen und gegen die zuvor verifizierte Basis bestätigt. Erst nach bestandenem Import-/22-Tabellen-Abgleich und Tests intern gestagt.

Linter **0 Fehler / 475 Hinweise**, davon **471 unveränderte Altbefunde** und exakt vier neue unter Zipf 3,5: sugary 3,13; fasten/fastened 3,02; handwritten 3,33; caterpillar/caterpillars 3,38. Kein Satz zum Unterdrücken von Hinweisen umgeschrieben. Alle vier neuen Meldungen entsprechen dem Auftrag.

Der vorhandene echte Pack-Lesetest ermittelt die Stapel-/Karteninventare dynamisch aus dem Asset und prüft sämtliche festen Zuordnungen. Er deckt automatisch die 13 Stapel ab; deshalb **keine Teständerung nötig**. Temp-Verzeichnis/Content-Installer/Produktionsrepository genutzt, keine echte user.db. Zusätzliche tatsächliche App-Projektion via vorhandenem `tool/report_learning_groups.dart`: **2985 Übungen / 2714 Wörter**, **91 Verbalphrasen**, **402 Formmitgliedschaften**. Eigentumszeilen/Karten/Übungen/Wörter werden nicht gleichgesetzt.

## Neue Batch-2-Übergabe

Originalauswahl über den vorhandenen `--prepare-continuation`-Weg an den tatsächlich gestagten neuen Pack gebunden; keine Optionen oder neue Schnittstellen erfunden. Neue Dateien:

- `pipeline/data/selection/verbalphrasen_batch_2_context_v1.json`
- `pipeline/data/words/en.verbalphrasen_batch_2_context_v1.json`
- `pipeline/data/learning_groups/en.verbalphrasen_batch_2_context_v1.json`
- `build/verbalphrasen_authoring_batch_2.zip`

Alle **181 Identitäten, Definitionen, Autorenhinweise und 123 Ausschlüsse** exakt zur Originalauswahl. Partition **91 importiert / 90 aktuell / 0 später**; neue Gruppen 90 reserviert, vorhandene 3099 Kartenentscheidungen erhalten. Aktuelle Wörterbuchdaten und alle 22 Tabellen einschließlich unveränderter Formdaten im ZIP-Kontext. Sämtliche 91 festen importierten Satzbindungen eingefroren. Drei neue Alternativen erneut gegen die 90 künftigen Ziele geprüft, keine Kollision.

Displayabbildung: **91 bestehende Positionen**, **90 künftige Anhänge 92–181**, **181 finale Zeilen**. Sie gilt beim späteren Folgeimport mit bestehendem hashgebundenem Display-Patch; jetzt keine Batch-2-Karte, kein Satz/Token und kein Display-Patch erzeugt. ZIP geschlossen, erneut geöffnet; CRCs, **83 Nutzdateihashes**, vollständige Identitäten, Referenzen, Basis-/SQLite-/Manifestbindung und alle 22 Tabellen bestanden. Kontext enthält vorhandenen Offline-Tokenizer/Linter und Modellgewichte; keine Generierungsfunktion oder Cloud aufgerufen.

## Tatsächlich ausgeführte Befehle und Outputs

Ab Repository-Root, macOS Terminal. Vollständige Logs unter `build/verbalphrasen_batch_1_checks/`; nachfolgend relevante tatsächliche Outputs, alle angegebenen Läufe neu durchgeführt. Windows-Python: `.\pipeline\.venv\Scripts\python.exe` statt `pipeline/.venv-macos/bin/python`; Dart-/Flutter-/Git-Befehle identisch auf beiden Systemen. Keine Windows-Ausführung behauptet.

```text
pipeline/.venv-macos/bin/python build/verbalphrasen_batch_1_checks/check_delivery.py

DELIVERY PASS: 31 ZIP entries; 30 manifest hashes; all extracted bytes/reference subset identical; 91 identities/pairs, 916 tokens (805 words,111 punctuation), 3 alternatives; partition 0/91/90; 12 inherited comparisons retained
CREATE SHA256 f6d9b6ef84228d4f4590be98ce66db123bcf17e84d5fc379849dd53f65e4f34e
DELIVERY ZIP SHA256 32e318a8e07b250faa8b36d560781bd0e12a49ecf652960522765a5fed5f91cc

Exit 0

pipeline/.venv-macos/bin/python pipeline/scripts/import_editorial_patch.py --source pipeline/out/alltagssprache_redewendungen_batch_5_v1/pack.json --create build/verbalphrasen_batch_1_checks/corrected/editorial_content_v2.json --registry pipeline/data/words/en.verbalphrasen_batch_1_context_v1.json --out pipeline/out/verbalphrasen_batch_1_v1
status ok; internal_test_pack true; ai_calls 0; ai_cost_usd 0
sqlite_counts: 22 Tabellen, cards=3099, decks=13, sentences=3633, sentence_tokens=39427
sha256 b8a482b09351025886188d705b8203b2391c9a45042d706b983d094ecfbe90fb
Exit 0

pipeline/.venv-macos/bin/python build/verbalphrasen_batch_1_checks/check_import.py

IMPORT AUDIT PASS: all 22 SQLite tables/old JSON+SQLite rows/4 form tables/134x3 preserved; 3099 cards,13 decks,91 new fixed sentences,916 tokens,displays1..91; partition91/90/0; linter0 errors, 475 hints; 4 new
NEW LINTER [{"card": "cut out|cut out/VERB|cut-out#weglassen", "level": "warn", "rule": "i+1", "message": "'sugary'/'sugary' Zipf 3.13 below 3.5"}, {"card": "drive off|drive off/VERB|drive-off#wegfahren", "level": "warn", "rule": "i+1", "message": "'fasten'/'fastened' Zipf 3.02 below 3.5"}, {"card": "make do with|make do with/VERB|make-do-with#sich-behelfen-mit", "level": "warn", "rule": "i+1", "message": "'handwritten'/'handwritten' Zipf 3.33 below 3.5"}, {"card": "turn into|turn/VERB|turn#sich-verwandeln", "level": "warn", "rule": "i+1", "message": "'caterpillar'/'caterpillars' Zipf 3.38 below 3.5"}]
PACK SHA 6bf01b919a800c61332ce13a4c5092d448a32524da1c0021f696652e8b5414ed
SQLITE SHA b8a482b09351025886188d705b8203b2391c9a45042d706b983d094ecfbe90fb

Exit 0

pipeline/.venv-macos/bin/python -m pytest pipeline/tests -q

........................................................................ [ 16%]
........................................................................ [ 32%]
..................................................... [ 44%]
........................................................................ [ 60%]
........................................................................ [ 76%]
........................................................................ [ 92%]
..................................                                       [100%]
447 passed, 19 subtests passed in 24.45s

Exit 0

dart run tool/report_learning_groups.dart pipeline/out/verbalphrasen_batch_1_v1/content.sqlite
mixed: raw_words=3066; learning_targets=2985; lexical_words=2714; form_memberships=402
verbalphrasen: raw_words=91; learning_targets=91; lexical_words=91
Exit 0

# Erst nach Prüfabnahme und nachweislicher Sicherung:
dart run tool/stage_content_pack.dart --from pipeline/out/verbalphrasen_batch_1_v1

Running build hooks...Running build hooks...staged assets/content/en/content.sqlite
  version verbalphrasen_batch_1_v1, schema 4, 19681280 bytes
  sha256 b8a482b09351025886188d705b8203b2391c9a45042d706b983d094ecfbe90fb
  22 table counts match finalization_report.json
  INTERNES TEST-PACK: own devices and selected testers only, no public content release

Exit 0

dart run tool/stage_content_pack.dart --verify

Running build hooks...Running build hooks...verified assets/content/en/content.sqlite
  version verbalphrasen_batch_1_v1, schema 4, 19681280 bytes
  sha256 b8a482b09351025886188d705b8203b2391c9a45042d706b983d094ecfbe90fb
  22 table counts match finalization_report.json
  INTERNES TEST-PACK: own devices and selected testers only, no public content release

Exit 0

flutter analyze --no-pub

Analyzing sprachapp...
No issues found! (ran in 4.6s)

Exit 0

flutter test --no-pub test/data/real_pack_test.dart

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
deck verbalphrasen: 91 learning targets, 91 ownership cards, 91 fixed sentence assignments verified
pack verbalphrasen_batch_1_v1 (schema 4, internal: true); 13 decks: 2888 cards, 3099 card sentences, 184 with valid_alternatives, 3099 cards in the pack
01:26 +1: All tests passed!

Exit 0
```

Die Bestandszahlen im Test wurden nicht verändert. `--no-pub` verwendet die vorhandenen Abhängigkeiten ohne Paketauflösung. SDK-Cachezugriff lokal, keine Paketinstallation, App-/Model-Konfigurationsänderung oder komplette Flutter-Suite. Reale Testdauer 1:26; kein Geräte-/Emulatortest.

```text
pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --help
--selection --out --batch --verify-zip --prepare-continuation VERSION
--source-pack/--source-sqlite nur für Formfortsetzung; im normalen Weg nicht verwendet
Exit 0; vollständige Ausgabe: export-help.log

pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --selection pipeline/data/selection/verbalphrasen_v1.json --batch 2 --prepare-continuation verbalphrasen_batch_2_context_v1
snapshots PASS; paths: neue Auswahl/Registry/Gruppen, jeweils verbalphrasen_batch_2_context_v1
partition_counts imported=91/current=90/future=0
Exit 0

pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --selection pipeline/data/selection/verbalphrasen_batch_2_context_v1.json --batch 2 --out build/verbalphrasen_authoring_batch_2.zip
export PASS; files=84; selected=181; excluded=123; partition91/90/0
Exit 0

pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --verify-zip build/verbalphrasen_authoring_batch_2.zip
zip_verification PASS; hashed_files=83; sqlite_tables=22; sqlite_cards=3099

zip_sha256 362a1e02d335d4b83b0c6fa2c4d7119b017311b824b6272fa0190d4c2ef53386

validate_selection/index_registry/validate_learning/build_rows PASS
Exit 0

pipeline/.venv-macos/bin/python build/verbalphrasen_batch_1_checks/check_handoff.py

HANDOFF PASS: CRC/ 83 hashes;181 exact identities/123 exclusions;partition91/90/0;90 current targets not yet imported;22 tables/402 form targets;display91 existing+90 append92..181;3 alternatives safe
PROTECTION 2855 old files; only changed ['assets/content/en/content.sqlite', 'assets/content/en/content.manifest.json']
ZIP SHA256 362a1e02d335d4b83b0c6fa2c4d7119b017311b824b6272fa0190d4c2ef53386

Exit 0
```

Windows PowerShell, tatsächliche Import-/Exportkommandos entsprechen:

```powershell
.\pipeline\.venv\Scripts\python.exe pipeline/scripts/import_editorial_patch.py --source pipeline/out/alltagssprache_redewendungen_batch_5_v1/pack.json --create build/verbalphrasen_batch_1_checks/corrected/editorial_content_v2.json --registry pipeline/data/words/en.verbalphrasen_batch_1_context_v1.json --out pipeline/out/verbalphrasen_batch_1_v1
.\pipeline\.venv\Scripts\python.exe pipeline/scripts/export_authoring_context.py --selection pipeline/data/selection/verbalphrasen_v1.json --batch 2 --prepare-continuation verbalphrasen_batch_2_context_v1
.\pipeline\.venv\Scripts\python.exe pipeline/scripts/export_authoring_context.py --selection pipeline/data/selection/verbalphrasen_batch_2_context_v1.json --batch 2 --out build/verbalphrasen_authoring_batch_2.zip
.\pipeline\.venv\Scripts\python.exe pipeline/scripts/export_authoring_context.py --verify-zip build/verbalphrasen_authoring_batch_2.zip
.\pipeline\.venv\Scripts\python.exe -m pytest pipeline/tests -q
```

### Diagnoseabweichungen, ohne gelockerte Verträge

Ein erster zusätzlicher Bestandsschutzcheck endete vor Staging mit `KeyError: 'assets/content/en/content.sqlite'` (Exit 1): `git ls-files` berücksichtigt ignorierte Assets nicht. Neue Hypothese: fehlende Baselinepfade, kein Importfehler. Asset/Manifest vor Staging explizit ergänzt, gegen verifizierte Originalhashes geprüft, identischer Check anschließend Exit 0. Ein früher Projektionslog-Ausleseversuch erfolgte vor Jobende (`ValueError: substring not found`, Exit 1); nach abgeschlossenem Dart-Lauf vollständig gelesen, 2985/2714 bestätigt. Keine Validatoränderung oder erneuter Import nötig. Keine erfolglose Importschleife.

## Rohbytehashes und kanonische Digests

| Gegenstand | SHA256 / Scope |
|---|---|

| Original-Liefer-ZIP | `32e318a8e07b250faa8b36d560781bd0e12a49ecf652960522765a5fed5f91cc` |
| Original Create JSON, Rohbyte | `f6d9b6ef84228d4f4590be98ce66db123bcf17e84d5fc379849dd53f65e4f34e` |
| Korrigierte Create-Kopie, Rohbyte | `6a9ba9cb86632cfa551eedb0860430700d394d92f7073377d3882c5b37a0faf7` |
| Unverändertes Basis-JSON, Rohbyte | `2f8dbf21ff2173bc29e848a97f5134e279410def703eefe565fc11e49ab708a0` |
| Unveränderte Basis-SQLite/Asset vor Staging/Backup | `afb6908df44f791b70d839dfbee0b1810c0294aec7d44bf4d0c9005ffd2c7765` |
| Manifest vor Staging/Backup | `a58ac7684c9e0e7b277f94219446a1e9c72b7bbc3e4100b13aa8aae470a841f4` |
| Import-Registry, kanonisch | `862e0e61d3579a4b32859d0a832f18755418a403a4ec1da50222058259beedc6` |
| Ausgangsgruppen, kanonisch | `7dd082b1e93068f1f875f90e79fbcb0c3ef0137a30f6c5e92f5bd53fcd3aab89` |
| Neuer Pack, Rohbyte | `6bf01b919a800c61332ce13a4c5092d448a32524da1c0021f696652e8b5414ed` |
| Neuer SQLite/App-Asset, Rohbyte | `b8a482b09351025886188d705b8203b2391c9a45042d706b983d094ecfbe90fb` |
| Neues Asset-Manifest, Rohbyte | `ebc62c901723e8a699475a3eeab1f04f406a9c3d3f0ce59ddc508769cf677471` |
| Batch-2-ZIP, Rohbyte | `362a1e02d335d4b83b0c6fa2c4d7119b017311b824b6272fa0190d4c2ef53386` |
| pipeline/data/selection/verbalphrasen_batch_2_context_v1.json | `93ec2b96b9821c1cb647f94d98494745dbabf1eb495b10dc9554cf756d8a657f` |
| pipeline/data/words/en.verbalphrasen_batch_2_context_v1.json | `270741fc9f3cba6e2387cb4a2a5161e4a251a87b3cea995c504a348a8a5f7c18` |
| pipeline/data/learning_groups/en.verbalphrasen_batch_2_context_v1.json | `a8e16b3cddf7d55db9b97e46d34450060cbe2024fea4dea48b2106ab47fc52c0` |
| Batch-2-Kontext, kanonisch | `4083de6fdcac965e7f77e25b2f35cfd12d3cf5dd8a576a4bb5e9750cdb66d1b4` |
| Batch-2-Registry, kanonisch | `bf311a26def8442871fbafa688b230af0456a9d462cf8c843997785e537b3ff8` |
| Batch-2-Gruppen, kanonisch | `70cce1d99c8377f256a4129e3164badfc98639e74683acac23ab5cade5598b1b` |

Rohbytehashes und kanonische JSON-Digests werden nicht vertauscht. Historische Quellen/Auswahlen/Registry-/Gruppendateien sowie die Original-Lieferung sind bytegleich geblieben; die neue Kontextbasis ist bewusst der geprüfte Import-Pack.

## Zwölf geerbte Glossenvergleiche – weiterhin offen

Unveränderte gemeinsame Quelleinträge, keine neuen Fehlbindungen unter diesem Etikett verborgen. Die Liste ergänzt die älteren Befundlisten einschließlich des Alltagssprache-Abschlusses; sie ersetzt diese nicht.

| Form / Sense | Altglosse | Kontextdarstellung / Grund |
|---|---|---|

| decided / decide/VERB&#124;decide#entscheiden | beschloss | beschlossen — break up / give away: Pluralsubjekt; Altglosse nur Singular. |
| worked / work/VERB&#124;work#arbeiten | arbeiteten | arbeitete — catch up with: I worked, Altglosse nur Plural. |
| hard / hard/ADV&#124;hard#heftig | heftig | intensiv; fleißig — catch up with: Definition Intensität passt; heftig ist hier unidiomatisch. |
| needed / need/VERB&#124;need#brauchen | brauchten | brauchte — calm down: I needed, Altglosse nur Plural. |
| school / school/NOUN&#124;school#schule-hier-schul | Schule (hier: Schul-) | Schule — hang out: eigenständiges Wort, nicht Kompositumsanfang. |
| spread / spread/VERB&#124;spread#breitet-aus | breiten aus | sich ausbreitete — put out: intransitive Vergangenheitsform, geerbte Glosse passt morphologisch nicht. |
| fastened / fasten/VERB&#124;fasten#befestigen | befestigte | angeschnallt; befestigt — drive off: Partizip nach has, nicht Präteritum. |
| on / on/ADP&#124;on#on_own | hier Teil von on his own (= allein) | allein (in on your own) — bring up: Altglosse nennt his statt your. |
| own / own/ADJ&#124;own#on_own | hier Teil von on his own (= allein) | allein (in on your own) — bring up: Altglosse nennt his statt your. |
| words / word/NOUN&#124;word#wort | Wörter; Liedtext | Wörter — look up: Liedtext ist hier nicht gemeint. |
| is / be/AUX&#124;be#sein_vollverb | sein (als Vollverb oder Kopula zur Angabe von Zustand, Identität oder Eigenschaft) | ist — Geerbter Wörterbucheintrag zeigt die Bedeutungsbeschreibung statt der Formübersetzung. |
| was / be/AUX&#124;be#sein_vollverb | sein (Zustand, Eigenschaft oder Identität in der Vergangenheit) | war — tell off: geerbter Eintrag beschreibt die Bedeutung statt die Form. |

Hinzu kommen die zwei bereits in der Auswahl enthaltenen zu engen Labels für pick out und pull over. Nur neue Formglossen präzisiert, IDs/Definitionen/Karten-/Sense-Glossen unverändert. Keine globale Glossen-, Zeilenenden- oder Whitespacebereinigung.

## GitNexus, Änderungsscope und Commitgrenze

Graph zuerst für die Import-/Fortsetzungs-/Exportpfade verwendet, Namensmehrdeutigkeit über konkrete UIDs aufgelöst. Index `sprachlernapp`, Stand 11.10.2026, Commit 90c2930, **zwei Commits hinter dem Start-HEAD 50f925c**. Begrenzte Kontextausgaben sind kein vollständiger Abdeckungsnachweis. Code-/Test-/Pipelinefunktionen unverändert. Read-only-Verträge zusätzlich an tatsächlichen Quellen und mit unveränderten Tests geprüft. Impact: Roadmap LOW, neun Dokumentabhängigkeiten, zwei direkt, keine erfassten Prozesse; neue Kontexte/Importbericht und Assets nicht indexiert, NEXTSTEPS und Pack-Lesetest mit null aufgelösten Callern **UNKNOWN**, keine Sicherheitsfreigabe daraus abgeleitet. Literal-Referenzen, dynamische Inventarprüfung und vollständige Datenvalidierung ergänzen diese Grenzen. Keine HIGH/CRITICAL-Warnung, kein Reindex.

Vorher Index leer, NEXTSTEPS mit vorbestehenden Anteilen und fremde untracked Alltagssprache-/Verbalphrasen-Lieferungen erhalten. Neue eigene Commitdateien: drei Batch-2-Kontexte, dieser Bericht und begrenzte Roadmap-Statusfortschreibung. NEXTSTEPS bleibt wegen seiner Altanteile außerhalb des Inkrements. Packs/Assets/build-Ausgaben sind bewusst gitignored; `git check-ignore` bestätigt dies. Keine interne Binärdatei zwangsweise hinzugefügt, kein pauschales git add, keine fremde Lieferung eingesammelt, kein Push. Tatsächliche Graph-Änderungsanalyse und gezielte Diff-Ausgaben unten bzw. im Prüfverzeichnis.

Neue/geänderte Arbeitsdateien: eigener Importbericht, NEXTSTEPS/Roadmap, neue drei Kontextdateien, neues internes Pack, Asset/Manifest, Sicherung und Prüfprotokolle, korrigierte separate Create-Kopie und Batch-2-ZIP. Kein App-Einstieg, SRS, Modell, API, Supabase, echtes user.db/Review, alte feste Sätze/IDs oder Formdaten geändert. Kein unabhängiger menschlicher Sprach-/Gerätelauf und keine öffentliche Freigabe.

## Nächste Aktion

**Verbalphrasen: 90 aktuelle Batch-2-Ziele anhand der geprüften ZIP im Chat redigieren.** Business & E-Mail bleibt danach; keine neue Kategorie vorbereitet.

Vollständiger lokaler Uploadpfad:

`/Users/ardasayar/Documents/FlutterProjekte/sprachapp/build/verbalphrasen_authoring_batch_2.zip`

## Abschließende Dokument- und Indexprüfung

Tatsächlich ausgeführt, Git-Befehle auf macOS und Windows identisch:

```text
git diff --check -- NEXTSTEPS.md docs/content-roadmap-v1.md docs/verbalphrasen-batch-1-import.md pipeline/data/selection/verbalphrasen_batch_2_context_v1.json pipeline/data/words/en.verbalphrasen_batch_2_context_v1.json pipeline/data/learning_groups/en.verbalphrasen_batch_2_context_v1.json
Keine Ausgabe; Exit 0

git diff --cached --check -- docs/content-roadmap-v1.md docs/verbalphrasen-batch-1-import.md pipeline/data/selection/verbalphrasen_batch_2_context_v1.json pipeline/data/words/en.verbalphrasen_batch_2_context_v1.json pipeline/data/learning_groups/en.verbalphrasen_batch_2_context_v1.json
Erster Lauf Exit 2: übernommene Terminal-Leerzeichen im neuen Bericht und neue Leerzeile am EOF.
Nur diese beiden eigenen Berichtsbefunde behoben; Original-Logs und Altdateien unverändert.
Endgültiger Lauf: keine Ausgabe; Exit 0

git diff --cached --name-only
Nur fünf eigene Pfade: Importbericht, Roadmap und drei Batch-2-Kontexte.
Exit 0
```

Eigene Dokumente und neue Kontexte mit LF; kein CRLF-Erhaltungsfall, kein zusätzlicher cr-at-eol-Lauf nötig. Bekannte repositoryweite Altbefunde (u. a. DESIGN.md:162–164, Alltag-Zuhause-/Arbeit-Bildung-Berichte) bleiben separat, keine globale Diff-Bereinigung. Gezielte Logs: `diff-check-final.log`, `staged-diff-check-final.log`; anfängliche eigene Diagnose `staged-diff-check.log`.

MCP `detect_changes({repo: "sprachlernapp", scope: "all"})`: sieben erfasste Dokumentabschnitte / sechs geänderte Dateien, null erfasste Prozesse, risk_level low. `scope: "staged"`: drei erfasste Roadmapabschnitte / fünf gestagte Dateien, null erfasste Prozesse, risk_level low. Antworten ohne partial/truncated-Markierung; neue Metadaten/Importbericht dennoch nicht indexiert, keine vollständige Graphabdeckung behauptet. Die ignoredbasierten Pack-/Assetänderungen sind nicht Teil der Git-Diff-Analyse; ihre tatsächliche Abnahme erfolgt durch Tabellen-, Hash-, Bestands-, Schema- und App-Checks.

Endabgleich von 2855 erfassten vorbestehenden Dateien: ausschließlich Asset, Manifest, NEXTSTEPS und Roadmap wie autorisiert geändert; Original-Lieferung, historische Quellen/Kontexte, App-/Test-/Instruktionsdateien bytegleich. Neues Pack/ZIP/Korrekturkopie/Kontexte kommen zusätzlich hinzu. Nachweis `handoff-audit.json`, graphische Rohantworten `gitnexus-detect-*.json`. Index vor Beginn leer, vor Commit nur fünf eigene Dokument-/Kontextdateien. Lokaler Commitoutput und Endstatus: `commit.log`, `status-final.txt`; kein Push. NEXTSTEPS hat 25 Zeilen und bleibt wegen seiner vorbestehenden Anteile uncommittet.
