# Alltagssprache & Redewendungen – Batch 5 und Gesamtabschluss

Stand: **13.10.2026**. Die letzten **87 Ziele offline importiert, intern geprüft und gestagt**. Vollständiger Nachweis **441/441 Zielidentitäten**, Anzeigen 1–441, Partition **441 importiert / 0 aktuell / 0 später**. Schema 4, zwölf Stapel, 3008 Karten; tatsächliche produktive Projektion **2894 Übungen / 2623 Wörter**. Kein Restbatch und keine Batch-6-ZIP. Technische interne Abnahme ist keine öffentliche Sprach-/Inhaltsfreigabe.

## Tatsächliche Dateien und Verträge

AGENTS.md/CLAUDE.md mit aktuellen GitNexus-Regeln, NEXTSTEPS, Roadmap, Authoring-/Batch-4-/Auswahl-v2-/Schema-4-Kompatibilitätsberichte, Content-/Lerngruppenregeln und tatsächliche V2-/Display-Verträge gelesen und geprüft. Verwendet: vorhandener `import_editorial_patch.py --create --registry --display-patch`, `create_content`, `apply_deck_display_patch`, `export_offline`, `pack.build_rows`, `finalize_curation.check_sqlite`, `selection.partition_selection`, produktive LearningGroups-/lexicalCountingKeys-Projektion und `stage_content_pack.dart`. Keine neue Implementierung, Code-/Test-/Schemaänderung oder Indexneubau.

Eingaben: `pipeline/out/alltagssprache_redewendungen_batch_4_v1/pack.json`/content.sqlite, unveränderte Auswahl v2, Batch-5-v2-Registry/Gruppen und Originallieferung. Ausgabe `pipeline/out/alltagssprache_redewendungen_batch_5_v1/` mit pack.json, content.sqlite und finalization_report.json. App-Asset/Manifest nur über autorisiertes internes Staging aktualisiert. Neue Checks/Entpackung/Sicherung unter `build/alltagssprache_batch_5_checks/`, dieser neue Bericht, aktualisierte Roadmap und NEXTSTEPS. Keine neue Auswahl, Registry, Kategorie, Satzlieferung oder Folge-ZIP.

Vorheraufnahme über **2820 erfasste Dateien**, tatsächlicher Gitstatus und leerer Index. Vorbestehende NEXTSTEPS-Änderungen sowie unversionierte frühere Liefer-/Berichts-/Kontextdateien erhalten. GitNexus-meta.json, historische aktuelle Quelle, Auswahl/Registry/Gruppen, Instruktionsdateien und alle Code-/Testdateien in Bestandsschutz einbezogen. Interne Pack-/Asset-/build-Ausgaben sind laut bestehendem Gitignore nicht zu versionieren; kein erzwungenes Hinzufügen.

## Lieferung, Bedeutungen und originale Bytes

Original `/Users/ardasayar/Downloads/alltagssprache_redewendungen_batch_5_lieferung.zip`, bereits entpackter Rootordner `alltagssprache_redewendungen_batch_5/`: alle 35 Dateien bytegleich zur eigenen Entpackung verglichen. ZIP-CRCs und vollständiger Liefermanifesthash-Abgleich bestanden. Alle beigefügten Reference-Dateien entsprechen der geprüften Batch-5-Authoring-ZIP; verkürzt abgelegtes V2-Schema gegen dessen echten Originalpfad verglichen. Reference-Manifest beschreibt vollständigen Authoring-Kontext, Lieferung dessen enthaltene Teilmenge. Basis-/Create-Rohhashes und kanonischer Registry-Digest exakt wie vorgegeben, Reference-Registry bytegleich zur lokalen. Keine andere Basis oder Umbasierung.

Auswahl v2: unverändert **441 Ziele in 89/89/88/88/87**, vor Import 354/87/0. Genau 87 aktuelle Identitäten übernommen. Ausgeschlossenes in my opinion bleibt ohne eigenes Lernziel; alte bestätigte neutrale Alternative bei to my mind erhalten. Historische ungenutzte Reservierung bleibt vertraglich erhalten, ist keine aktive Karte oder offener Satzauftrag.

Alle **87 Satzpaare / 838 Tokenpositionen / 679 Wort- und Ausdruckstokens** vollständig mit token_review, reading und Zieldefinitionen geprüft; Begleitwörter ebenso. Ganze Mehrwortziele eine zusammenhängende Lücke/ein lexical_span, accepted exakt [card.form] einschließlich Großschreibung/Apostrophen. Karten-, Sense-, learning- und Originalpositionsbindungen unverändert. Tatsächlicher Importer prüft Tokenisierung, Wörterbuch-/Senseabdeckung und Reviewhashes. reading.json entspricht exakt allen Zieldefinitionen/Übersetzungen/Texten/Alternativen.

Besonderheiten geprüft: could als Möglichkeit/höfliche Bitte; performance#auftritt, reader#lesende-person, sales#verkaufszahlen, dream#sehnsuechtig-vorstellen, rise#mengenmaessig-steigen, delay#verzoegerung auch Dienstleistungswartezeit. Bei clear the air (0381) erstes 's → we#uns, zweites 's → Genitivendung. driving behält den vorhandenen Tätigkeits-Sense, die eingeschränkte alte Führerschein-Formglosse bleibt der unten getrennte Befund. **Kein belegter Lieferfehler, keine Korrekturkopie nötig: Original-Create und Display-Patch unverändert verwendet.**

Drei tatsächlich eingesetzte Alternativen:

| Ziel → Alternative | Wörtliche Ersetzung |
|---|---|
| beat around the bush → beat about the bush | Don't beat about the bush; tell me the problem. |
| skeptical → sceptical | I'm sceptical about promises of easy money. |
| you have a point → you've got a point | you've got a point about the cost. |

Texte exakt mit alternative_review und den Importreviews abgeglichen, Aussage und passender Satzanschluss geprüft. Gegen alle 441 Ziele, vollständige Reservierungen/Owner/Aliase und aktiven Karten-/Gruppenkontext geprüft: keine konkurrierende Lernoberfläche. Keine Antwortfreigabe aus Gruppenzugehörigkeit/Alias und keine vollständige globale Synonymliste behauptet. Alternativen bleiben satzbezogen und lernstandsneutral.

## Abschlussabgleich, Export und Bestandsschutz

Create hängt neue Mitgliedschaften auf **355–441** an. Gepaarter hashgebundener Display-Patch ordnet ausschließlich Anzeigepositionen dieses Stapels auf **1–441** nach unveränderten Originalpositionen. Der Ausschluss von Originalposition 377 führt nicht zu einer Neunummerierung der Auswahl/Registry: Originalpositionen gehen weiterhin bis 442, die 441 gültigen Anzeigen bleiben lückenlos. Ganze 441-Zeilen-Mapping-/Vorherhashbindung und Identitäten geprüft.

**Alle 441 Identitäten einzeln** geprüft: Karte/Sense/Definition/Glosse, learning-Gruppe und Kopf, reservierter Besitzer/Karten-ID/Originalposition, genau ein aktiver fester Satz und accepted. Vollständiges maschinenlesbares Audit `build/alltagssprache_batch_5_checks/completion-441.json`; `partition_selection` liefert 441 present / 0 missing, keinen weiteren Auftrag. Drei geeignete Wörterbuchsenses aus der ursprünglichen Auswahl behalten ihre ursprünglichen Glossen/Definitionen; keine Altglosse still geändert.

Alle alten JSON-Inhaltslisten und SQL-IDs/Nutzwerte erhalten, außer ausdrücklich erlaubten beiden Displaypositionsspalten dieses Stapels und Release-/Registry-Metadaten. Vollständiger 22-Tabellen-Abgleich mit allen Zeilen/Spalten gegen build_rows; exportgenerierter content_releases.created_at wie bisher gesondert. Integritycheck ok, keine FK-Verstöße; eindeutige Wörterbuch-/Gruppen-/Besitz-/Referenzschlüssel geprüft. Neue Ausgabe: 3008 Karten, zwölf Stapel, 441 Alltagssprache-Ziele, 87 neue Satzpaare/838 Tokens, 116 neue Wörterbuchsenses und 134 neue Dictionary-Formzeilen. 2797 aktive Besitzzeilen und 2798 historische Registry-Reservierungen sind ausdrücklich nicht die Wortzahl.

Vier Formtabellen unverändert: 134 Lexikalanker, 406 Zuordnungen, 402 Formziele/Mitgliedschaften, **134/134/134 Verbenübungen**. Die beiden Batch-4-Korrekturen entsprechen exakt batch4_corrections_preserved.json; alle dreizehn früheren Tokenkorrekturen nochmals konkret nachgewiesen. Alte feste Sätze, IDs, Gruppenentscheidungen und historische Links erhalten.

Produktive Projektion mit vorhandenem Dart-Repository/`LearningGroups.project`/`lexicalCountingKeys`: **2894 Übungen / 2623 Wörter**, nicht aus Karten-/Besitzzeilen abgeleitet. Linter **0 Fehler / 471 Warnhinweise**, davon genau zwei neu: **tiredness 2,92** bei a vicious circle und **timetable 3,44** bei remedy, unter 3,5. 469 ältere Hinweise bleiben gesonderte Befunde; keine Umformulierung zur Warnungsunterdrückung.

App-Asset und Manifest **vor Staging** in checks/backup gesichert, bytegleich/SHA256 gegen Vorheraufnahme geprüft. Nach bestandenen Audits intern gestagt, --verify, Flutter-Analyse und unveränderten echten Zwölfstapel-Lesetest in dieser Reihenfolge ausgeführt. Testdatenbank ausschließlich temporär. Keine echte user.db geöffnet, kopiert, migriert oder verändert; kein Geräte-/Emulatorlauf, keine öffentliche oder unabhängige menschliche Sprachfreigabe.

## GitNexus und sauber begrenzter Commitumfang

Vorhandener Explorationsablauf; neu verfügbare MCP-Werkzeuge verwendet. list_repos bindet **sprachlernapp** am aktuellen Repo-Pfad; exakte UIDs für create_content, apply_deck_display_patch und prepare_continuation vor aktueller Codeprüfung, found/exact. prepare_continuation hat keine aufgelösten Caller, wird aber nachweislich von der CLI verwendet; Null ist kein Unbenutztbeweis. Keine notwendige Funktionsänderung.

Index bleibt **stale** (aktueller CLI-Status in gitnexus-status.log); keine Aktualisierung/Installation. Dokument-impact: NEXTSTEPS UNKNOWN/0 Caller, neuer Bericht nicht gefunden/UNKNOWN; keine Entwarnung daraus. Roadmap LOW für 9 erreichbare Dokumentknoten, zwei direkte Referenzen (Verben-Implementierungsplan, Natur-Authoring), 0 Prozesse. Kategorienzahl, Regeln und historische Abschnitte erhalten; diese Referenzen bleiben gültig. Literale Prüfung fand keine direkten NEXTSTEPS.md-Referenzen im produktiven Code.

MCP detect_changes(scope=all) erkennt acht Abschnittssymbole in zwei Markdown-Dateien, 0 betroffene Prozesse, low für diesen erkannten Umfang. Veralteter Index und unindexierte Liefer-/Kontextdateien bleiben eine **offene Vollabdeckungsgrenze**, nicht als sauber ausgegeben. Ein erster MCP-Aufruf enthielt den dort nicht unterstützten CLI-Parameter limit und wurde als Toolfehler abgewiesen; danach mit den tatsächlich unterstützten Feldern repo/scope ausgeführt. Kein Inhaltsfehler oder abgesenkter Validator.

Der früher genannte Schema-4-/450-Codeblocker ist **für den aktuellen HEAD nicht bestätigt**: HEAD und Arbeitsbaum unterstützen Schema 4/450, diese Codepfade und Auswahl v2 sind versioniert und unverändert. Nicht pauschal eine alte Begründung übernommen. Der eigene Dokumentationscommit umfasst nur diesen neuen Bericht und den vorher sauberen Roadmap-Diff. NEXTSTEPS bleibt wegen vorbestehender gemischter Änderungen außerhalb des Commits; frühere unversionierte Lieferungen, Berichte und Kontextsnapshots ebenso. Interne Pack-/Asset-/build-Artefakte bleiben gemäß Gitignore lokal. Vor Commit erneuter GitNexus-Check des konkreten eigenen Indexumfangs und direkte Prüfung der beiden reinen Markdown-Diffs; kein Code-/Daten-/Instruktionsfile mitgestagt, kein pauschales git add, kein Push. Offene Graphabdeckung wird dabei nicht zu einer vollständigen Codefreigabe umgedeutet. Commit-ID im abschließenden Chat/Gitnachweis.

## Tatsächliche Prüfungen und Outputs

macOS ab Repository-Root. Windows PowerShell: gleiche Python-Argumente mit `.\pipeline\.venv\Scripts\python.exe` statt `pipeline/.venv-macos/bin/python`; Dart-/Flutter-/Git-Befehle gleich. Temporäre Audithelfer /tmp/everyday-import-b5 verwenden bestehende Funktionen/Validatoren, keine neue Importarchitektur. Relevante gekürzte Outputs; vollständige Logs unter checks.

```text
GitNexus list_repos({})
1 repository: sprachlernapp; indexedAt 2026-10-11T18:00:13.826Z; lastCommit 90c2930; hasMore false
GitNexus context({repo:sprachlernapp,uid:Function:pipeline/scripts/import_editorial_patch.py:create_content,name:create_content})
found/exact
GitNexus context({repo:sprachlernapp,uid:Function:pipeline/src/sprachpipe/deck_display.py:apply_deck_display_patch,name:apply_deck_display_patch})
found/exact
GitNexus context({repo:sprachlernapp,uid:Function:pipeline/src/sprachpipe/authoring_context.py:prepare_continuation,name:prepare_continuation})
found/exact; no resolved incoming callers, no unused inference
GitNexus impact({repo:sprachlernapp,target:NEXTSTEPS.md,direction:upstream})
UNKNOWN, 0 resolved callers
GitNexus impact({repo:sprachlernapp,target:docs/content-roadmap-v1.md,direction:upstream})
LOW, 9 reachable docs /2 direct /0 processes
GitNexus impact({repo:sprachlernapp,target:docs/alltagssprache-redewendungen-batch-5-import.md,direction:upstream})
Target not found /UNKNOWN
GitNexus detect_changes({repo:sprachlernapp,scope:all})
changed_count 8; changed_files 2; affected_count 0; risk_level low (recognized subset only)
MCP tools successful responses except noted unknown target; tool API has no process exit code.
node .gitnexus/run.cjs status
Status stale; exact local output saved in gitnexus-status.log
Exit 0

pipeline/.venv-macos/bin/python /tmp/everyday-import-b5/audit_delivery.py
DISPLAY mapping fields ['card_ref', 'form_norm', 'original_position', 'append_position']
DELIVERY PASS: 35 ZIP entries/manifest hashes/reference subset/schema/source/registry; 441 identities with 87 current; 838 tokens (679 words/spans); three alternatives/no selection-owner-alias collisions; nine inherited findings unchanged
SEMANTIC/READING PASS: 87 exact reading bindings; special could/performance/reader/sales/dream/rise/delay senses checked; clear the air two apostrophe-s bindings checked; two Batch-4 corrections exact; no correction necessary.
Exit 0
pipeline/.venv-macos/bin/python pipeline/scripts/import_editorial_patch.py --source pipeline/out/alltagssprache_redewendungen_batch_4_v1/pack.json --create build/alltagssprache_batch_5_checks/delivery/alltagssprache_redewendungen_batch_5/editorial_content_v2.json --registry pipeline/data/words/en.alltagssprache_redewendungen_batch_5_context_v2.json --display-patch build/alltagssprache_batch_5_checks/delivery/alltagssprache_redewendungen_batch_5/deck_display_patch.json --out pipeline/out/alltagssprache_redewendungen_batch_5_v1
{
  "status": "ok",
  "internal_test_pack": true,
  "ai_calls": 0,
  "ai_cost_usd": 0,
  "sqlite_counts": {
    "languages": 1,
    "lemmas": 4080,
    "senses": 5673,
    "cards": 3008,
    "dictionary_forms": 6781,
    "decks": 12,
    "deck_cards": 2901,
    "deck_words": 2797,
    "word_aliases": 37,
    "sentences": 3542,
    "sentence_tokens": 38511,
    "card_sentences": 3536,
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
  "sha256": "afb6908df44f791b70d839dfbee0b1810c0294aec7d44bf4d0c9005ffd2c7765"
}
Exit 0
pipeline/.venv-macos/bin/python /tmp/everyday-import-b5/audit_pack.py
COMPLETE 441/441 identity/definition/group/ownership/original-position/fixed-sentence bindings PASS; partition 441 imported /0 current/0 future; no rest batch
PACK PASS: 3008 cards, 12 decks, 441 ordinary goals; 87 new fixed pairs/838 tokens; 0 future absent; excluded duplicate absent/old neutral alternative retained
PRESERVATION PASS: all old JSON/SQL rows/IDs preserved except two display-position columns for this deck; all 22 tables/build_rows/integrity/foreign keys PASS; four form tables unchanged, 134/134/134
DISPLAY PASS: append 355..441 then exact original-order displays 1..441; registry/original positions unchanged
ORIGINAL DELIVERY PASS: no correction; all target definitions/learning/texts/gaps/alternatives unchanged
LINTER 471 warnings total; 0 errors; NEW [{'card': 'a vicious circle|a vicious circle/NOUN|a-vicious-circle#ein-teufelskreis', 'level': 'warn', 'rule': 'i+1', 'message': "'tiredness'/'tiredness' Zipf 2.92 below 3.5"}, {'card': 'remedy|remedy/NOUN|remedy#abhilfe', 'level': 'warn', 'rule': 'i+1', 'message': "'timetable'/'timetable' Zipf 3.44 below 3.5"}]
VERIFIED BACKUP content.sqlite cde0265001925026155faa65839cdeff7745f84f237d394032bb2eef8570b5d1
VERIFIED BACKUP content.manifest.json d6682c6b74b2c653a4681eab3de530778d5809e7b37042642b2800c317334fbd
Exit 0
pipeline/.venv-macos/bin/python -m pytest pipeline/tests -q
447 passed, 19 subtests passed in 24.84s
Exit 0
dart run tool/report_learning_groups.dart pipeline/out/alltagssprache_redewendungen_batch_5_v1/content.sqlite
mixed: raw_words=2975; learning_targets=2894; lexical_words=2623; form_memberships=402
Exit 0
dart run tool/stage_content_pack.dart --from pipeline/out/alltagssprache_redewendungen_batch_5_v1
staged assets/content/en/content.sqlite
  version alltagssprache_redewendungen_batch_5_v1, schema 4, 19193856 bytes
  sha256 afb6908df44f791b70d839dfbee0b1810c0294aec7d44bf4d0c9005ffd2c7765
  22 table counts match finalization_report.json
  INTERNES TEST-PACK: own devices and selected testers only, no public content release
Exit 0
dart run tool/stage_content_pack.dart --verify
verified assets/content/en/content.sqlite
  version alltagssprache_redewendungen_batch_5_v1, schema 4, 19193856 bytes
  sha256 afb6908df44f791b70d839dfbee0b1810c0294aec7d44bf4d0c9005ffd2c7765
  22 table counts match finalization_report.json
  INTERNES TEST-PACK: own devices and selected testers only, no public content release
Exit 0
flutter analyze --no-pub
Analyzing sprachapp...
No issues found! (ran in 3.8s)
Exit 0
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
pack alltagssprache_redewendungen_batch_5_v1 (schema 4, internal: true); 12 decks: 2797 cards, 3008 card sentences, 181 with valid_alternatives, 3008 cards in the pack
01:21 +1: All tests passed!
Exit 0
pipeline/.venv-macos/bin/python /tmp/everyday-import-b5/final_audit.py
COMPLETION PASS: 441 exact identities/definitions/groups/owners/fixed contexts; 441/0/0; all 22 tables; source/asset byte-identical
PRESERVATION 2820 pre-existing files: only authorized NEXTSTEPS/Roadmap/Asset/Manifest changed; code/tests/historical input/graph metadata preserved
13 prior corrections preserved; no Batch-6 ZIP or next-category selection
Exit 0
```

## Neun geerbte Formglossen-Vergleiche – offen, nicht zurückgeschrieben

Die Liste ersetzt keine frühere Befundliste. Alle source-Zeilen aus inherited_gloss_comparison.json unverändert mitgeführt, kein künstlicher Ersatzsense. Vergleiche mit tatsächlichem Satzkontext:

| Form / Sense | Alte Glosse → Kontextvergleich | Kontext / Grund |
|---|---|---|
| instead / instead/ADV\|instead#anstatt | anstatt → stattdessen | Zielwort adverbial statt Präposition. alltagssprache-v1-0361-s1: The café was closed, so we went to the park instead. |
| driving / driving/NOUN\|driving#autofahren | hier Teil von driving licence (= Führerschein / Fahrerlaubnis) → Autofahren | Formglosse nennt weiterhin nur driving licence; Aktivität im neuen Satz. alltagssprache-v1-0379-s1: Cycling is a cheaper alternative to driving. |
| tomato / tomato/NOUN\|tomato#tomaten | Tomaten- → Tomate | Alte Formglosse ist die gebundene Form Tomaten-. alltagssprache-v1-0441-s1: Strictly speaking, a tomato is a fruit. |
| fruit / fruit/NOUN\|fruit#frucht | Frucht- → Frucht | Alte Formglosse ist die gebundene Form Frucht-. alltagssprache-v1-0441-s1: Strictly speaking, a tomato is a fruit. |
| abroad / abroad/ADV\|abroad#im_ausland | im Ausland → ins Ausland | Neue Richtungsverwendung mit move statt Ortsangabe. alltagssprache-v1-0387-s1: After years of dreaming, Ali decided to take the plunge and move abroad. |
| used / use/VERB\|use#benutzen | benutzte → benutzt | Im Present Perfect Partizip statt alter Präteritumglosse. alltagssprache-v1-0430-s1: As far as I can tell, nobody has used this room. |
| did / do/AUX\|do#hilfsverb | Hilfsverb für die Frage in der Vergangenheit → Hilfsverb der Vergangenheit, hier Verneinung | Alte Formglosse beschränkt sich auf Fragen. alltagssprache-v1-0442-s1: You didn't win today, but better luck next time! |
| disappeared / disappear/VERB\|disappear#verschwunden | verschwunden → verschwand | Finite Vergangenheitsform im neuen Satz; alte Glosse nur Partizip. alltagssprache-v1-0405-s1: He disappeared during my troubles: a fair-weather friend. |
| soap / soap/NOUN\|soap#seife | Mittel zum Waschen der Hände → Seife | Alte Formglosse nennt nur Händewaschen, der Satz Fleckentfernung. alltagssprache-v1-0365-s1: The stain might come out with soap; it's worth a try. |

## Hashes und nächste Aufgabe

| Datei | SHA256 |
|---|---|
| `/Users/ardasayar/Downloads/alltagssprache_redewendungen_batch_5_lieferung.zip` | `fa38c6b7a33930ce0f1dcc004b5eb3b6c66ffe72c5463e339c703239faa04ac5` |
| `build/alltagssprache_batch_5_checks/delivery/alltagssprache_redewendungen_batch_5/editorial_content_v2.json` | `de757d496a5364c13240850a4f07e78993b56be6d9dedc66bec6cb2c1b490e03` |
| `build/alltagssprache_batch_5_checks/delivery/alltagssprache_redewendungen_batch_5/deck_display_patch.json` | `3abb45faffa052a48e9f2bbe8b8f1c24a5ecf4aeef9c77fdd6e5d625efa7c1d3` |
| `pipeline/out/alltagssprache_redewendungen_batch_4_v1/pack.json` | `42de21e3962fee724e1fda42c77f71a59042bca212ed84b709d0aa834f0b7761` |
| `pipeline/out/alltagssprache_redewendungen_batch_4_v1/content.sqlite` | `cde0265001925026155faa65839cdeff7745f84f237d394032bb2eef8570b5d1` |
| `build/alltagssprache_batch_5_checks/backup/content.manifest.json` | `d6682c6b74b2c653a4681eab3de530778d5809e7b37042642b2800c317334fbd` |
| `pipeline/data/selection/alltagssprache_redewendungen_v2.json` | `27e52591e0dd98df0510204664c03467c49347151398e1caef4538887751c71d` |
| `pipeline/data/words/en.alltagssprache_redewendungen_batch_5_context_v2.json` | `040ac9e61c3eeace461229ceccdbe7feb9ac2a5c2362b1818764f0ee57234ed2` |
| `pipeline/out/alltagssprache_redewendungen_batch_5_v1/pack.json` | `2f8dbf21ff2173bc29e848a97f5134e279410def703eefe565fc11e49ab708a0` |
| `pipeline/out/alltagssprache_redewendungen_batch_5_v1/content.sqlite` | `afb6908df44f791b70d839dfbee0b1810c0294aec7d44bf4d0c9005ffd2c7765` |
| `assets/content/en/content.manifest.json` | `a58ac7684c9e0e7b277f94219446a1e9c72b7bbc3e4100b13aa8aae470a841f4` |

Kanonischer Input-Registry-Digest: `91a731db4e21ce19103ec0c4d3fdd783c47c3b58f41662e3d564abca044b8a78`, getrennt vom Dateibytehash. Finale SQLite und App-Asset bytegleich; Backup entspricht Vorherstand. Auswahl v2, alle historischen erfassten Lieferungen/Packs/Registry-/Gruppensnapshots, Code/Test/Instruktionsdateien und GitNexus-Metadaten hashgleich. Keine Modell-/Cloud-/Supabase-Aufrufe, Paketinstallation, Lernstandzugriffe, Geräteabnahme oder öffentliche Freigabe.

Roadmap: zwölf Stapel technisch intern abgeschlossen, Gesamtplan weiter exakt 14. Als nächste Aufgabe ausschließlich **Verbalphrasen, ca. 200 nach Dublettenprüfung; danach Business & E-Mail** dokumentiert. Keine entsprechende Auswahl/Reservierung/Satzlieferung, keine Batch-6-ZIP. Geerbte Sprachbefunde und unabhängige öffentliche Sprach-/Geräteprüfung bleiben offen.

## Abschließender Dokument-/Whitespacecheck

```text
git diff --check -- NEXTSTEPS.md docs/content-roadmap-v1.md docs/alltagssprache-redewendungen-batch-5-import.md
Output: leer
Exit 0

git -c core.whitespace=cr-at-eol diff --check -- NEXTSTEPS.md docs/content-roadmap-v1.md docs/alltagssprache-redewendungen-batch-5-import.md
Output: leer
Exit 0

Direkter Scan aller drei eigenen Markdown-Dateien: nachgestellte Leerzeichen nicht vorhanden; NEXTSTEPS 24 Zeilen.
Exit 0
```

Vorbestehende repositoryweite CRLF-/Whitespacebefunde bleiben gesondert erhalten; keine globale Bereinigung oder Erfolgsaussage für repositoryweiten Check. Neuer Report und Roadmap sind die einzigen für den lokalen Dokumentationscommit vorgesehenen Dateien; reine Markdown-Diffs nach allen Inhaltsprüfungen direkt gegengelesen. NEXTSTEPS/Fremddateien werden nicht mitgestagt. Interne Daten/Assets bleiben lokal und gemäß Gitignore unverändert vom Git-Index getrennt.

## Konkrete Commitprüfung

```text
git add -- docs/content-roadmap-v1.md docs/alltagssprache-redewendungen-batch-5-import.md
Output: leer
Exit 0

git diff --cached --name-only
docs/alltagssprache-redewendungen-batch-5-import.md
docs/content-roadmap-v1.md
Exit 0

git diff --cached --check
Output: leer
Exit 0

GitNexus detect_changes({repo:sprachlernapp,scope:staged})
changed_files 2; changed_count 4; affected_count 0; risk_level low
Vier erkannte Roadmap-Abschnitte, keine betroffenen Prozesse.
Neuer Bericht nicht indexiert; daher kein vollständiger Graph-Grünnachweis, stattdessen direkte Prüfung des reinen Markdown-Inhalts. Keine Codeänderung.
```

Genau zwei eigene Markdown-Dateien für den Dokumentationscommit isoliert; keine fremde NEXTSTEPS-Hunk, Lieferung, Registry oder Inhaltsdatei aufgenommen. Der reine Dokumentationsumfang ist durch konkrete Diff-/Whitespace-/Inhaltsprüfung abgesichert, die globale GitNexus-Abdeckung bleibt ausdrücklich offen.
