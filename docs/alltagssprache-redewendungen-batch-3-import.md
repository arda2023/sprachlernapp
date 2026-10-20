# Alltagssprache & Redewendungen – Batch 3: interner Import und Batch-4-Übergabe

Stand: 11.10.2026. **88 aktuelle Ziele offline importiert, intern geprüft und gestagt. 266 Alltagssprache-Ziele**, Anzeigen 1–266, Schema 4, zwölf Stapel, 2833 Karten. Tatsächliche produktive Projektion: **2719 Übungen / 2448 Wörter**. Batch-4-ZIP erneut vollständig geprüft: **266 importiert / 88 aktuell / 87 später**, weiterhin 441 Auswahlidentitäten. Keine öffentliche Freigabe.

## Verträge, Eingaben und Dateiumfang

AGENTS.md/CLAUDE.md einschließlich tatsächlicher lokaler GitNexus-Regeln, NEXTSTEPS, Roadmap, Authoring-/Batch-2-/Auswahl-v2-/Schema-4-Kompatibilitätsberichte und Content-/Lerngruppenverträge geprüft. Vorhandener V2-Create-Weg mit ausdrücklich angegebener Registry und gepaartem Display-Patch; normaler Schema-4-Fortsetzungsexporter. Die beigefügte Schema-3-Codeübersicht und die historische Importer-Docstring sind keine aktuelle Basis: hashgebundener Quell-JSON, SQLite, Manifest und tatsächlicher Schema-4-Import/Readback sind maßgeblich. Keine erneute Implementierung oder Schemaänderung.

Schnittstellen: `pipeline/scripts/import_editorial_patch.py` (`create_content`, `export_offline`), `pipeline/src/sprachpipe/deck_display.py` (`apply_deck_display_patch`), `pack.build_rows`, `finalize_curation.check_sqlite`, `export_authoring_context.py` mit `prepare_continuation/validate_context`, vorhandenes `tool/stage_content_pack.dart --from/--verify`. Quellversion `alltagssprache_redewendungen_batch_2_v1`, neue Ausgabe `pipeline/out/alltagssprache_redewendungen_batch_3_v1/`.

Vorheraufnahme: 2747 erfasste Dateien, vollständiger Arbeitsbaumstatus und leerer Index in `build/alltagssprache_batch_3_checks/`. Alle vorbestehenden gemischten Code-/Dokumentänderungen erhalten. Keine Funktion, Klasse, App-, SRS- oder Testdatei geändert. Der vorhandene `test/data/real_pack_test.dart` prüft den echten neuen Pack mit seinen allgemeinen dynamischen Inventar-/Satz-/Repository-Prüfungen; keine neue Versionserwartung oder neuer Test nötig. Die Version fällt nicht in dessen älteren Batch-1/2-spezifischen Zusatzblock; Formdaten werden zusätzlich über vollständigen Zeilenabgleich und App-Schemavalidierung abgesichert.

Eigene Ausgaben:

- Neuer Pack mit pack.json, content.sqlite und finalization_report.json unter `pipeline/out/alltagssprache_redewendungen_batch_3_v1/`.
- Asset/Manifest durch vorhandenes autorisiertes internes Staging ersetzt.
- Dieser Bericht und NEXTSTEPS.md.
- Batch-4-Kontexte nach vorhandenem Namensvertrag: `pipeline/data/selection/alltagssprache_redewendungen_batch_4_context_v2.json`, `pipeline/data/words/en.alltagssprache_redewendungen_batch_4_context_v2.json`, `pipeline/data/learning_groups/en.alltagssprache_redewendungen_batch_4_context_v2.json`.
- ZIP `build/alltagssprache_redewendungen_authoring_batch_4.zip`; Checks/Originalentpackung/Importkopie/backup unter `build/alltagssprache_batch_3_checks/`.

## GitNexus – Graph zuerst, Grenzen ausdrücklich erhalten

Skill: `.agents/skills/gitnexus-exploring/SKILL.md`. Vorhandener lokaler CLI-Runner `node .gitnexus/run.cjs`, gebundenes Repository **sprachlernapp** am tatsächlichen sprachapp-Pfad. Kein MCP-GitNexus-Tool verfügbar; autorisierter lokaler CLI-Weg verwendet. Kein Indexneubau, Paketdownload oder Analyzer-Aufruf.

`list` zeigt einen Index: 2083 Dateien, 14312 Symbole, 30786 Beziehungen, 393 Prozesse. `status`: Index/aktueller Commit 90c2930, indexedAt 2026-10-11T18:00:13.826Z; **stale: 0 changed / 24 added / 0 deleted** (neu vorhandene Lieferung). Das ist kein vollständiger aktueller Nachweis. Namensabfragen und --file lieferten mehrere historische Kopien; nach diesen zwei uneindeutigen Ansätzen wurden die tatsächlich zurückgegebenen exakten UIDs benutzt:

| UID | Ergebnis | Aufgelöste eingehende/ausgehende Calls |
|---|---|---:|
| Function:pipeline/scripts/import_editorial_patch.py:create_content | found / exact | 30 / 4 |
| Function:pipeline/src/sprachpipe/deck_display.py:apply_deck_display_patch | found / exact | 1 / 2 |
| Function:pipeline/src/sprachpipe/authoring_context.py:prepare_continuation | found / exact | 0 / 7 |
| Function:pipeline/scripts/export_authoring_context.py:export | found / exact | 8 / 5 |

Null eingehende Calls bei prepare_continuation bedeutet nicht unbenutzt: die aktuelle CLI ruft es nachweislich im --prepare-continuation-Zweig auf. Graph zuerst, danach genaue aktuelle Quellprüfung und reale CLI-Ausführung. Kein grüner Rückschluss allein aus Null/Indexstatus.

Vor Dokumentedit: upstream impact für File:NEXTSTEPS.md meldet **UNKNOWN, 0 resolved callers**, mit ausdrücklichem riskNote „absence of edges is not evidence ... unused“. Als ungelöste Graphabdeckung behandelt. Textprüfung des produktiven lib/tool/pipeline-Codes fand keine direkten NEXTSTEPS.md-Verweise; der Auftrag verändert nur das sichtbare Markdown-Statusdokument, keine Laufzeitfunktion. Impact des noch nicht existierenden neuen Berichts konnte keinen Zielknoten finden (Exit 1); keine Codeänderung oder Sicherheitsfreigabe daraus abgeleitet.

`detect-changes --scope all --repo . --limit 2000` wurde vor jedem denkbaren Commit geprüft: **No changes detected.** Dies ist angesichts des nachweislich bestehenden gemischten Git-Diffs und stale Index kein belastbarer sauberer Coverage-Nachweis. Keine partial/truncated-Angaben verfügbar, keine vollständige Abdeckung behauptet. Kein Commit erzwungen, keine identischen Wiederholungen oder Indexneubauten. Reale Inhaltsprüfung/Bestandshashes liefern den separaten Nachweis für diesen Import. Vollständige Graphausgaben und Git-Vergleichsdateiliste im checks-Ordner.

## Lieferung, Identitäten und Satz-/Tokenprüfung

Original-ZIP `/Users/ardasayar/Downloads/alltagssprache_redewendungen_batch_3_lieferung.zip` und bereits vorhandener Rootordner `alltagssprache_redewendungen_batch_3/`: alle 29 Dateien bytegleich verglichen. Originale erhalten; eigene Entpackung nach checks/delivery. ZIP-CRCs und vollständiger Liefermanifest-Dateiabgleich bestanden. Beigefügte Reference-Dateien bytegleich zur geprüften Batch-3-Authoring-ZIP; verkürzten Schemanamen gegen tatsächlichen Archivpfad `pipeline/data/curation/editorial_content_v2.schema.json` verglichen. Reference-Manifest beschreibt den vollständigen ursprünglichen Kontext, die Lieferung dessen beigefügte Teilmenge.

Erwartete Basis-/Create-Rohhashes und kanonischer Registry-Digest bestätigt; lokale Registry und reference/registry.json bytegleich. Auswahl v2 unverändert: 441 Ziele in 89/89/88/88/87; vor Import Partition 178/88/175. Exakt 88 aktuelle Ziele übernommen; 175 spätere fehlen weiterhin im Pack. Kein zukünftiges Ziel in my opinion, alte bestätigte Alternative bei to my mind erhalten, historische ungenutzte Reservierung nicht entfernt. Keine Wiederaufnahme, Neuverteilung oder neue Auswahlkorrektur.

Alle 88 englischen/deutschen Satzpaare gegen die Zieldefinitionen gegengelesen. Vollständiger Tokenbericht mit **824 Positionen / 679 Wort- oder Ausdruckstokens** mit dem Create abgeglichen, einschließlich aller Begleitwörter. Kartenformen, Sense-/Kartenidentitäten, Definitionen, Glossen, learning, Originalpositionen und Lücken exakt gegen Auswahl. Jedes Mehrwortziel bildet eine zusammenhängende Lücke/einen lexical_span, accepted exakt [card.form] inklusive großem I/Apostrophen. Bestehender Importer prüft echte Tokenisierung, alle Reviewhashes und Wörterbuch-/Sense-Abdeckung; keine Platzhalter-/Ersatzgenerierung.

Besondere Bindungen bestätigt: agreement#vereinbarung beim unterschriebenen Vertrag; lift#mitfahrgelegenheit; drown#ueberwaeltigt-sein für E-Mails; taken/ADJ#besetzt beim Sitz; build#beziehung-aufbauen für rapport; grow#zunehmen für resentment. Sämtliche vier Batch-2-Korrekturen und die drei Batch-1-Korrekturen erhalten. save#sparen im Geldsatz bleibt sinnvoll: die alte Definition beschreibt das Einsparen begrenzter Ressourcen, mit Platz als Beispiel, nicht als ausschließliche Einschränkung. Kein neuer Sense dafür erfunden.

Drei satzbezogene Alternativen mit tatsächlicher Ersetzung:

| Ziel / Alternative | Ersetzung |
|---|---|
| for instance → for example | Some herbs grow well indoors; basil, for example, likes a sunny window. |
| off the beaten track → off the beaten path | We found a quiet village off the beaten path. |
| touch wood → knock on wood | The car has never broken down, knock on wood. |

Texte entsprechen exakt alternative_review und Importreviews, Aussage/Satzanschluss im konkreten Kontext geprüft. Alle drei gegen alle 441 Ziele und den gesamten aktuellen Registry-/Alias-/Karten-/Gruppenkontext geprüft: keine konkurrierende Lernoberfläche/Reservierung. Keine Antwortfreigabe aus Gruppen-/Aliasdaten, kein neuer Vorschlag oder globale Austauschbarkeits-/Vollständigkeitsbehauptung.

## Vier minimale Korrekturen in gesonderter Importkopie

Pfad: `build/alltagssprache_batch_3_checks/import_copy/alltagssprache_redewendungen_batch_3/`. Originalbytes erhalten; keine Ziel-, Satz- oder Übersetzungsänderung.

| Satz / Token | Vorher → Nachher | Grund |
|---|---|---|
| alltagssprache-v1-0192-s1 / 0 (Some) | some/DET\|some#etwas → some/DET\|some#einige | Pluralbegleiter vor herbs: einige, nicht die unzählbare Mengenangabe etwas. |
| alltagssprache-v1-0207-s1 / 7 (things) | thing/NOUN\|thing#sache → thing/NOUN\|thing#umstaende | made things worse betrifft die Lage/Umstände, keine Gegenstände oder Besitztümer. |
| alltagssprache-v1-0230-s1 / 11 (worked) | work/VERB\|work#funktionieren → work/VERB\|work#gelingen | Der zweite Versuch gelang/klappte; kein ordnungsgemäßer Gerätebetrieb. |
| alltagssprache-v1-0259-s1 / 8 (work) | work/VERB\|work#funktionieren → work/VERB\|work#gelingen | Die Idee bewährt sich in der Praxis; kein ordnungsgemäßer Gerätebetrieb. |

Drei vorhandene passende Sinne wiederverwendet. Ein echter reiner Wörterbuchsense thing#umstaende grenzt abstrakte Umstände/Lage von der vorhandenen ausdrücklich gegenständlichen Besitzdefinition ab; keine neue Lernkarte/Reservierung und keine künstliche Umgehung einer geteilten Glosse. Zwei Dictionary-Formzeilen ergänzt (things/Umstände und worked/gelang). Alte Sinne/Formglossen unverändert.

Mit bestehender import_editorial_patch.digest Token-/Linkreviewhashes erneuert, vollständigen token_review synchronisiert und gepaarten Display-Patch allein im create_sha256 auf korrigierte Rohbytes gebunden. Mapping und expected_before_hashes unverändert; lokales Manifest vollständig erneuert. local_corrections.json dokumentiert alle vier Einzeländerungen. Originale Chat-validation_report-/authoring_evidence-Dateien bleiben historische Belege; maßgeblich sind lokale Import-/Export-/Auditberichte. Keine Prüfgrenze abgesenkt.

## Vollständiger Export, Display und Staging

89+89 vorhandene Ziele erhalten; 88 neue Mitgliedschaften zunächst **179–266** angehängt. Der gepaarte hashgebundene Patch ordnet ausschließlich die beiden Anzeigepositionsspalten dieses Stapels auf **1–266** nach unveränderten Originalpositionen. Alle 266 Zeilen, Identitäten, Original-/Vorher-/Nachherpositionen und Quell-/Create-/Registry-/Vorherzeilenhashes geprüft. Registry-/Originalpositionen bleiben erhalten, kein anderes deck umgeordnet.

Alle alten JSON-Inhaltszeilen und exportierten SQL-IDs/Nutzwerte erhalten, außer expliziten beiden Displaypositionen und Release-/Registry-Metadaten. Alle 22 SQLite-Tabellen vollständig gegen build_rows verglichen, alle Zeilen/Spalten; content_releases.created_at wie bisher exportgeneriert. Integritycheck ok, keine Foreign-Key-Verstöße; eindeutige Referenzen/Wörterbuchschlüssel/Gruppenköpfe und ein aktiver fester Satz je neuer Karte durch vorhandene Validatoren bestätigt.

Vier Formtabellen identisch: 134 Lexikalanker, 406 Zuordnungen, 402 Formziele/Ansichten, 134/134/134 Übungen. Neue Ausgabe hat 2833 Karten, zwölf Stapel, 266 Alltagssprache-Ziele, 88 neue Satzpaare/824 Tokens, nach Korrektur 133 neue Wörterbuchsenses und 148 Dictionary-Formzeilen. Tatsächliche LearningGroups-/lexicalCountingKeys-Projektion **2719 Übungen / 2448 Wörter**; 2622 Besitzzeilen sind keine Wortzählung.

Linter: **0 Fehler, 466 Warnhinweise insgesamt**, davon genau ein neuer Hinweis: quieter 3,34 unter Zipf 3,5 im Satz von that's more like it. 465 geerbte Hinweise gesondert erhalten, keine Warnungsunterdrückung.

Vor Staging App-Asset/Manifest nach `build/alltagssprache_batch_3_checks/backup/` gesichert, bytegleich und per SHA256 gegen Vorheraufnahme geprüft. Erst dann internes Staging und Asset-Verifikation. Unveränderter echter Installer-/Repository-Lesetest mit allen zwölf tatsächlichen Stapeln, 266 Alltagssprache-Zielen und 2833 festen Karten-Satzpaaren bestanden. Echte user.db/Lernstände nicht geöffnet, kopiert oder verändert; Testdatenbank ausschließlich temporär. Kein Gerätelauf oder öffentliche Sprachfreigabe.

## Batch 4 und Bestandserhaltung

Fortsetzung aus unveränderter Auswahl v2 und tatsächlich finalem gestagtem Pack: **266 importiert / 88 aktuell / 87 später**, alle 441 Identitäten disjunkt vollständig. 2833 bestehende Karten-/Gruppenentscheidungen und 175 noch nicht importierte geplante Köpfe; nur 88 aktuelle Satzaufträge. Historische Reservierungen, alle Wörterbuch-/Gruppen-/Formdaten und expliziter Ausschlussnachweis in Auswahl/original_selection mitgegeben. Keine Batch-4-Sätze.

ZIP geschlossen, erneut geöffnet: CRCs, sämtliche **83 manifestierten Dateihashes**, Referenzen, Registry-/Gruppen-/Sourcebindungen, 441 exakte Auswahlidentitäten und gesamte Restpartition geprüft. Alle 22 Quelltabellen erneut gegen build_rows. ZIP-SQLite bytegleich mit finaler Quelle und gestagtem Asset. Sieben frühere und vier aktuelle Tokenkorrekturen im echten Pack konkret nachgewiesen. Kein neuer Identitäts-/Bedeutungsblocker.

## Tatsächliche Prüfkommandos und Exitcodes

macOS ab Repository-Root. Windows PowerShell verwendet dieselben Python-Argumente mit `.\pipeline\.venv\Scripts\python.exe` statt `pipeline/.venv-macos/bin/python`; Node/Dart/Flutter/Git identisch. Temporäre Audits `/tmp/everyday-import-b3/*.py` verwenden vorhandene Funktionen, keine neue Repo-Importlogik. Relevante gekürzte Outputs; vollständige Logs im checks-Ordner.

```text
node .gitnexus/run.cjs list
sprachlernapp; 2083 files / 14312 symbols / 30786 edges / 393 processes
Exit 0
node .gitnexus/run.cjs status
Index content: 0 changed, 24 added, 0 deleted; Status: stale
Exit 0
node .gitnexus/run.cjs context --uid 'Function:pipeline/scripts/import_editorial_patch.py:create_content' --repo .
found / exact; incoming calls 30, outgoing calls 4
Exit 0
node .gitnexus/run.cjs context --uid 'Function:pipeline/src/sprachpipe/deck_display.py:apply_deck_display_patch' --repo .
found / exact; incoming calls 1, outgoing calls 2
Exit 0
node .gitnexus/run.cjs context --uid 'Function:pipeline/src/sprachpipe/authoring_context.py:prepare_continuation' --repo .
found / exact; incoming calls 0, outgoing calls 7 (not unused; current CLI call confirmed)
Exit 0
node .gitnexus/run.cjs context --uid 'Function:pipeline/scripts/export_authoring_context.py:export' --repo .
found / exact; incoming calls 8, outgoing calls 5
Exit 0
node .gitnexus/run.cjs query 'offline editorial import export stage content pack' --repo .
Flow/candidate output saved in gitnexus-query.log; advisory on stale index
Exit 0
node .gitnexus/run.cjs impact --uid 'File:NEXTSTEPS.md' --direction upstream --repo .
risk UNKNOWN; impactedCount 0; absence of edges not evidence of unused
Exit 0
node .gitnexus/run.cjs impact --uid 'File:docs/alltagssprache-redewendungen-batch-3-import.md' --direction upstream --repo .
No target node found for the not-yet-existing new document
Exit 1
node .gitnexus/run.cjs detect-changes --scope all --repo . --limit 2000
No changes detected. (Not a clean coverage claim; stale index/mixed git diff retained.)
Exit 0

pipeline/.venv-macos/bin/python /tmp/everyday-import-b3/audit_delivery.py
DISPLAY mapping fields ['card_ref', 'form_norm', 'original_position', 'append_position']
DELIVERY PASS: 29 ZIP entries/manifest hashes/reference subset/schema/source/registry; 441 identities with 88 current; 824 tokens (679 words/spans); three alternatives/no selection-owner-alias collisions; ten inherited findings unchanged
SEMANTIC review: work/worked concern idea/attempt rather than device; Some herbs requires plural determiner; things worse concerns circumstances rather than possessions.
Exit 0
pipeline/.venv-macos/bin/python /tmp/everyday-import-b3/correct.py
CORRECTION COPY PASS: build/alltagssprache_batch_3_checks/import_copy/alltagssprache_redewendungen_batch_3 ; 4 sense-only token edits, 1 real dictionary-only polysemy, 2 new dictionary forms; existing reviews/display raw create binding renewed
CREATE SHA256 5db6d5a98e9e16711c2e26017438d10728cb1d358a24f896f4f09292e4df46f7
Exit 0

pipeline/.venv-macos/bin/python pipeline/scripts/import_editorial_patch.py --source pipeline/out/alltagssprache_redewendungen_batch_2_v1/pack.json --create build/alltagssprache_batch_3_checks/import_copy/alltagssprache_redewendungen_batch_3/editorial_content_v2.json --registry pipeline/data/words/en.alltagssprache_redewendungen_batch_3_context_v2.json --display-patch build/alltagssprache_batch_3_checks/import_copy/alltagssprache_redewendungen_batch_3/deck_display_patch.json --out pipeline/out/alltagssprache_redewendungen_batch_3_v1
{
  "status": "ok",
  "internal_test_pack": true,
  "ai_calls": 0,
  "ai_cost_usd": 0,
  "sqlite_counts": {
    "languages": 1,
    "lemmas": 3882,
    "senses": 5441,
    "cards": 2833,
    "dictionary_forms": 6514,
    "decks": 12,
    "deck_cards": 2726,
    "deck_words": 2622,
    "word_aliases": 37,
    "sentences": 3367,
    "sentence_tokens": 36801,
    "card_sentences": 3361,
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
  "sha256": "97a7b185dc5fa1e0085a8e461a3d54ce9afff7f855b418bb5a1f231c283e6e98"
}
Exit 0
pipeline/.venv-macos/bin/python /tmp/everyday-import-b3/audit_pack.py
PACK PASS: 2833 cards, 12 decks, 266 ordinary goals; 88 new fixed pairs/824 tokens; 175 future absent; excluded duplicate absent/old neutral alternative retained
PRESERVATION PASS: all old JSON/SQL rows/IDs preserved except two display-position columns for this deck; all 22 tables/build_rows/integrity/foreign keys PASS; four form tables unchanged, 134/134/134
DISPLAY PASS: append 179..266 then exact original-order displays 1..266; registry/original positions unchanged
CORRECTION COPY PASS: exactly 4 sense-only token edits; one new dictionary sense/two forms; all target definitions/learning/texts/gaps/alternatives unchanged
LINTER 466 warnings total; 0 errors; NEW [{'card': "that's more like it|that's more like it/INTJ|that-s-more-like-it#so-ist-es-besser", 'level': 'warn', 'rule': 'i+1', 'message': "'quieter'/'quieter' Zipf 3.34 below 3.5"}]
VERIFIED BACKUP content.sqlite 849d342fca6872b701742ff903e873944f7dc564cf7df034d64d443933fadfe2
VERIFIED BACKUP content.manifest.json d815d232720f9d9a2a49b64a9f77d551d55206529c741d5b0997a0c720ab95d5
Exit 0

pipeline/.venv-macos/bin/python -m pytest pipeline/tests -q
447 passed, 19 subtests passed in 24.38s
Exit 0
dart run tool/report_learning_groups.dart pipeline/out/alltagssprache_redewendungen_batch_3_v1/content.sqlite
mixed: raw_words=2800; learning_targets=2719; lexical_words=2448; form_memberships=402
Exit 0
dart run tool/stage_content_pack.dart --from pipeline/out/alltagssprache_redewendungen_batch_3_v1
staged assets/content/en/content.sqlite
  version alltagssprache_redewendungen_batch_3_v1, schema 4, 18259968 bytes
  sha256 97a7b185dc5fa1e0085a8e461a3d54ce9afff7f855b418bb5a1f231c283e6e98
  22 table counts match finalization_report.json
  INTERNES TEST-PACK: own devices and selected testers only, no public content release
Exit 0
dart run tool/stage_content_pack.dart --verify
verified assets/content/en/content.sqlite
  version alltagssprache_redewendungen_batch_3_v1, schema 4, 18259968 bytes
  sha256 97a7b185dc5fa1e0085a8e461a3d54ce9afff7f855b418bb5a1f231c283e6e98
  22 table counts match finalization_report.json
  INTERNES TEST-PACK: own devices and selected testers only, no public content release
Exit 0
flutter analyze --no-pub
Analyzing sprachapp... No issues found! (ran in 4.0s)
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
deck alltagssprache-redewendungen: 266 learning targets, 266 ownership cards, 266 fixed sentence assignments verified
pack alltagssprache_redewendungen_batch_3_v1 (schema 4, internal: true); 12 decks: 2622 cards, 2833 card sentences, 175 with valid_alternatives, 2833 cards in the pack
01:18 +1: All tests passed!
Exit 0

pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --help
CLI includes --selection/--batch/--out/--prepare-continuation/--verify-zip
Exit 0
pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --selection pipeline/data/selection/alltagssprache_redewendungen_v2.json --batch 4 --prepare-continuation alltagssprache_redewendungen_batch_4_context_v2
{
  "snapshots": "PASS",
  "paths": {
    "selection": "pipeline/data/selection/alltagssprache_redewendungen_batch_4_context_v2.json",
    "registry": "pipeline/data/words/en.alltagssprache_redewendungen_batch_4_context_v2.json",
    "groups": "pipeline/data/learning_groups/en.alltagssprache_redewendungen_batch_4_context_v2.json"
  },
  "partition_counts": {
    "imported": 266,
    "current": 88,
    "future": 87
  }
}
Exit 0
pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --selection pipeline/data/selection/alltagssprache_redewendungen_batch_4_context_v2.json --batch 4 --out build/alltagssprache_redewendungen_authoring_batch_4.zip
status PASS; selected 441; partition 266/88/87
Exit 0
pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --verify-zip build/alltagssprache_redewendungen_authoring_batch_4.zip
{
  "zip_verification": "PASS",
  "zip_sha256": "c937a27fc833192bd7f4da4b39910b9ba4e4f63faea9e5868cd3aaf0ed0229cf",
  "hashed_files": 83,
  "sqlite_tables": 22,
  "sqlite_cards": 2833,
  "selected": 441,
  "partition_counts": {
    "imported": 266,
    "current": 88,
    "future": 87
  }
}
Exit 0
pipeline/.venv-macos/bin/python /tmp/everyday-import-b3/final_audit.py
CLOSED ZIP PASS: CRC/83 file hashes/441 exact identities/266 imported/88 current/87 future; all 22 tables; source/asset byte-identical
2747-file preservation audit: only authorized NEXTSTEPS/Asset/Manifest changed; code/tests/historical inputs unchanged; index empty
Exit 0
```

Diagnoseabweichungen: zwei uneindeutige Graph-Namens-/File-Abfragen mit historischen Kopien wurden durch nachgewiesene UID-Abfragen ersetzt; kein Graphindex geändert. Ein JSON-Parseversuch der reinen Textmeldung No changes detected ergab ValueError: substring not found (Exit 1); danach tatsächlichen Textbefund ohne Coveragebehauptung erfasst. Zwei separate lokale Auditübertragungen enthielten zunächst die alte Batch-2-Alternativzahl 2 statt 3 bzw. den alten Current-Batchfilter 3 statt 4 (AssertionError, jeweils Exit 1). Gegen tatsächliche Liefer-/Kontextfelder korrigiert, keine Inhalte oder Validatorgrenzen angepasst. Reale CLI-Import-/Display-/Fortsetzungs-/Export-/ZIP-Verifier-Läufe jeweils beim ersten Aufruf erfolgreich.

## Zehn geerbte Formglossen-Vergleiche – nicht zurückgeschrieben

Alle originalen Dictionary-Zeilen mit Kontext geprüft und unverändert erhalten. Früheren Listen nicht als erledigt erklärt. Neue Zuordnungsfehler oben gesondert korrigiert.

| Schlüssel | Alte Glosse → Vorschlag | Kontext / Befund |
|---|---|---|
| cooked\|cook/VERB\|cook#kocht | garte → kochte; gekocht | Altglosse garte ist für dinner zubereiten unnötig eng. meanwhile: Maya cooked dinner; meanwhile, Ben set the table. |
| lend\|lend/VERB\|lend#geliehen-leihen | geliehen (leihen) → leihen; verleihen | Altglosse geliehen (leihen) vermischt Partizip und Infinitiv. reluctant: She was reluctant to lend her new bike to a stranger. |
| worked\|work/VERB\|work#arbeiten | arbeiteten → gearbeitet; arbeitete; arbeiteten | Altglosse arbeiteten deckt das Partizip im Satz nicht ab. previously: I had previously worked in a bakery, so early mornings were familiar.; after all: He deserves a rest; after all, he has worked all night. |
| guest\|guest/NOUN\|guest#gaeste | Gäste- → Gast | Gebundene/plurale Altglosse Gäste- bei eigenständigem Singular guest. bend over backwards: Our hosts bend over backwards for every guest. |
| changed\|change/VERB\|change#verandern | änderte sich → änderte; verändert | Reflexive Altglosse änderte sich passt nicht zu changed her stance. stance: The council changed its stance on cars in the town centre. |
| name\|name/NOUN\|name#namen | Namen → Name | Altglosse Namen ist flektiert. oversight: Leaving your name off the list was an oversight, not a deliberate insult.; ring a bell: Does the name Rosa Miller ring a bell? |
| staff\|staff/NOUN\|staff#mitarbeiter | Mitarbeiter- → Personal; Mitarbeiter | Gebundene Altglosse Mitarbeiter- bei eigenständigem Kollektivnomen. resentment: Being excluded from every meeting caused growing resentment among the staff. |
| signed\|sign/VERB\|sign#unterschreibt | unterschrieben → unterschrieb; unterschrieben | Altglosse unterschrieben deckt das finite Präteritum nicht ausdrücklich ab. in good faith: She signed the agreement in good faith, unaware of the hidden fees. |
| concert\|concert/NOUN\|concert#konzert | Konzert- → Konzert | Gebundene Altglosse Konzert- bei eigenständigem Nomen. enjoy yourself: Enjoy yourself at the concert tonight! |
| clear\|clear/ADJ\|clear#klares | klares → klar | Altglosse klares ist flektiert; hier prädikatives Adjektiv. straightforward: The instructions are clear, so the repair should be straightforward. |

## Hashes, Commitgrenze und nächste Aktion

| Datei | SHA256 |
|---|---|
| `/Users/ardasayar/Downloads/alltagssprache_redewendungen_batch_3_lieferung.zip` | `3084697a5c23bda643efdaf14fc53944af303fad048f734b67053b0f1bacef2e` |
| `build/alltagssprache_batch_3_checks/delivery/alltagssprache_redewendungen_batch_3/editorial_content_v2.json` | `37a7157509124bd80a21fbc0dafd0c0f2c8493f2ffff9128e501ed379c1cc08f` |
| `build/alltagssprache_batch_3_checks/import_copy/alltagssprache_redewendungen_batch_3/editorial_content_v2.json` | `5db6d5a98e9e16711c2e26017438d10728cb1d358a24f896f4f09292e4df46f7` |
| `build/alltagssprache_batch_3_checks/import_copy/alltagssprache_redewendungen_batch_3/deck_display_patch.json` | `7db970ddfd33141df659abf1d528407fa747f076253b001ae6d28cabee87a141` |
| `pipeline/out/alltagssprache_redewendungen_batch_2_v1/pack.json` | `aa2ac7e95344b4741280cdefa8f38dc9272f655a26f8230f1b47c1aa6365b2fa` |
| `pipeline/out/alltagssprache_redewendungen_batch_2_v1/content.sqlite` | `849d342fca6872b701742ff903e873944f7dc564cf7df034d64d443933fadfe2` |
| `build/alltagssprache_batch_3_checks/backup/content.manifest.json` | `d815d232720f9d9a2a49b64a9f77d551d55206529c741d5b0997a0c720ab95d5` |
| `pipeline/data/selection/alltagssprache_redewendungen_v2.json` | `27e52591e0dd98df0510204664c03467c49347151398e1caef4538887751c71d` |
| `pipeline/data/words/en.alltagssprache_redewendungen_batch_3_context_v2.json` | `53a4898bae3d712aa24f97dd887a52168fdf6cc6c53b4d3bef51dcebe973a47d` |
| `pipeline/out/alltagssprache_redewendungen_batch_3_v1/pack.json` | `33e0a22d82a20f06e9c2f7a58eccd61a4709148c03c998aaea0c8b894f59a503` |
| `pipeline/out/alltagssprache_redewendungen_batch_3_v1/content.sqlite` | `97a7b185dc5fa1e0085a8e461a3d54ce9afff7f855b418bb5a1f231c283e6e98` |
| `assets/content/en/content.manifest.json` | `d89b5893459e0df865d878c66955d95635f2580730dee88ea0ec51dd62cbe64b` |
| `pipeline/data/selection/alltagssprache_redewendungen_batch_4_context_v2.json` | `307efe0bede4e0b86cb6dd4b8f12e2b355f09f73f158f2dc45e176d483600a3e` |
| `pipeline/data/words/en.alltagssprache_redewendungen_batch_4_context_v2.json` | `c223229705030354b73d63fb2d9d300260a1b807a6b8c5a382fa148ec18883c2` |
| `pipeline/data/learning_groups/en.alltagssprache_redewendungen_batch_4_context_v2.json` | `2dd2b758ed49d377d0cafe1ce0efc7cd383404cdd8417752f2eec57e77e86d9c` |
| `build/alltagssprache_redewendungen_authoring_batch_4.zip` | `c937a27fc833192bd7f4da4b39910b9ba4e4f63faea9e5868cd3aaf0ed0229cf` |

Kanonischer Input-Registry-Digest: `ed27b007e78feac886af101b9629f2e59f0a97751c410bdf1fddb75fd00d11ee`, getrennt vom Dateibytehash. Finaler SQLitehash entspricht exakt dem App-Asset; Backup entspricht dem Stand vor Staging. Original-ZIP/Rootlieferung, alte Quelle, Auswahl v2 samt Ausschluss, Batch-3-Registry/Gruppen und erfasste historische Kontexte hashgleich. Keine App-/SRS-/Test-/Form-/Kompatibilitäts-/GitNexus-Regeländerung, kein echter Lernstandzugriff, Cloud-/Modell-/Supabase-Aufruf oder Paketupdate.

Kein Commit: vorhandene uncommittete Schema-4-/450-/V3-Abhängigkeiten und gemischte NEXTSTEPS-Hunks verhindern einen eigenständig auf HEAD prüfbaren Datencommit. Zusätzlich GitNexus-detect-changes hier ohne belastbare vollständige Abdeckung; kein grüner Commitnachweis behauptet. Index leer erhalten, kein Sammelstaging/Push. Die autorisierte technische Abnahme und ZIP-Übergabe sind davon unabhängig bestanden.

Nächste Aktion: geprüfte ZIP hochladen und die 88 aktuellen Batch-4-Ziele im Chat redigieren. Altglossen, spätere Imports und öffentliche Sprach-/Geräteabnahme bleiben offen.

Geprüfte ZIP: `/Users/ardasayar/Documents/FlutterProjekte/sprachapp/build/alltagssprache_redewendungen_authoring_batch_4.zip`

## Abschließende Git-/Whitespaceprüfung

```text
git diff --check -- NEXTSTEPS.md docs/alltagssprache-redewendungen-batch-3-import.md pipeline/data/selection/alltagssprache_redewendungen_batch_4_context_v2.json pipeline/data/words/en.alltagssprache_redewendungen_batch_4_context_v2.json pipeline/data/learning_groups/en.alltagssprache_redewendungen_batch_4_context_v2.json
Output: leer
Exit 0

git -c core.whitespace=cr-at-eol diff --check -- NEXTSTEPS.md docs/alltagssprache-redewendungen-batch-3-import.md pipeline/data/selection/alltagssprache_redewendungen_batch_4_context_v2.json pipeline/data/words/en.alltagssprache_redewendungen_batch_4_context_v2.json pipeline/data/learning_groups/en.alltagssprache_redewendungen_batch_4_context_v2.json
Output: leer
Exit 0

DIRECT Whitespace PASS: 10 own document/context/correction files; NEXTSTEPS 25 lines
Existing actual Pack test byte-identical: True
Exit 0

git status --short
Vollständiger tatsächlicher Output in build/alltagssprache_batch_3_checks/status-after.txt.
Vorbestehender gemischter Arbeitsbaum erhalten; Index leer.
Exit 0
```

2747-Dateien-Schlussaudit nach Dokumentaktualisierung: ausschließlich NEXTSTEPS.md, App-Asset und Manifest als erlaubte Änderungen unter vorher erfassten Dateien. Historische erfasste Quellen/Auswahlen/Registrys/Gruppen sowie sämtliche Code-/Test-/AGENTS-/CLAUDE-Dateien unverändert. Der neue Bericht und die drei neuen Kontextdateien kommen hinzu. Bekannte globale CRLF-/Whitespace-Altbefunde getrennt erhalten; keine pauschale Bereinigung oder Erfolgsaussage für einen repositoryweiten Check.
