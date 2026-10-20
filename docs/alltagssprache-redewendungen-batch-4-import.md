# Alltagssprache & Redewendungen – Batch 4: interner Import und Batch-5-Übergabe

Stand: 11.10.2026. **88 Ziele offline importiert und intern gestagt; 354 Alltagssprache-Ziele**, Anzeigen 1–354, Schema 4, zwölf Stapel und 2921 Karten. Produktive Projektion **2807 Übungen / 2536 Wörter**. Geprüfte Batch-5-ZIP mit **87 aktuellen Satzaufträgen**, Partition **354 importiert / 87 aktuell / 0 später**. Technische interne Abnahme; keine öffentliche Inhaltsfreigabe.

## Verträge, tatsächliche Eingaben und eigene Ausgaben

AGENTS.md/CLAUDE.md mit tatsächlichen lokalen GitNexus-Regeln, NEXTSTEPS, Roadmap, gemeinsamer Authoring-/Batch-3-/Auswahl-v2-/Schema-4-Kompatibilitätsbericht, Content-/Lerngruppenverträge, V2-Schema und aktuelle Auswahl-/Registry-/Gruppendateien gelesen und geprüft. Vorhandener normaler V2-Create-/Schema-4-Weg und Fortsetzungsexporter; keine erneute Implementierung, App-/Code-/Teständerung oder Indexneubau. Ältere Schemaübersichten sind keine Basis; aktuelle hashgebundene JSON-/SQLite-/Manifestdaten bestätigen Schema 4.

Tatsächliche Schnittstellen: `pipeline/scripts/import_editorial_patch.py --create --registry --display-patch` (create_content, apply_deck_display_patch, export_offline), `pack.build_rows`, `finalize_curation.check_sqlite`, `tool/stage_content_pack.dart --from/--verify` und normaler `pipeline/scripts/export_authoring_context.py --prepare-continuation`/Export/Verifier. Quelle `pipeline/out/alltagssprache_redewendungen_batch_3_v1/`; neue Ausgabe `pipeline/out/alltagssprache_redewendungen_batch_4_v1/`. Bestehende Ausgaben wurden nicht überschrieben.

Vorheraufnahme: **2782 erfasste vorbestehende Dateien**, tatsächlicher Gitstatus/leerer Index unter `build/alltagssprache_batch_4_checks/`, einschließlich aktueller Source-/Assetdateien und GitNexus-meta.json. Fremde Änderungen unverändert erhalten. Eigene Ausgaben:

- Neuer Pack: pack.json, content.sqlite, finalization_report.json unter `pipeline/out/alltagssprache_redewendungen_batch_4_v1/`.
- App-Asset und Manifest ausschließlich über autorisiertes internes Staging ersetzt.
- Neuer Bericht `docs/alltagssprache-redewendungen-batch-4-import.md`, NEXTSTEPS.md aktualisiert.
- Vor Erstellung genannte neue Batch-5-Kontexte: `pipeline/data/selection/alltagssprache_redewendungen_batch_5_context_v2.json`, `pipeline/data/words/en.alltagssprache_redewendungen_batch_5_context_v2.json`, `pipeline/data/learning_groups/en.alltagssprache_redewendungen_batch_5_context_v2.json`.
- `build/alltagssprache_redewendungen_authoring_batch_5.zip`; Liefer-/Korrektur-/Audit-/Backup-/Graphprotokolle unter `build/alltagssprache_batch_4_checks/`.

## GitNexus: vorhandener Graph zuerst, Abdeckung weiterhin offen

Weiterverwendeter Explorationsskill `.agents/skills/gitnexus-exploring/SKILL.md`; CLI-Runner `node .gitnexus/run.cjs`, gebundenes Repository sprachlernapp am tatsächlichen sprachapp-Pfad. list/status und die exakten lokalen Symbol-UIDs vor aktueller Quellprüfung benutzt. found/exact: create_content (30 eingehende/4 ausgehende Calls), apply_deck_display_patch (1/2), prepare_continuation (0/7), export (8/5). Null Caller bei prepare_continuation ist kein Unbenutztbeweis; tatsächlicher CLI-Zweig und erfolgreicher Fortsetzungsaufruf bestätigen die Verwendung.

**Ungeklärte Abdeckung aus dem letzten Auftrag bleibt offen.** Aktueller Status: Index stale, 1 changed (NEXTSTEPS.md) / 49 added / 0 deleted. Keine neue Analyse/Installation, Indexmetadaten unverändert. Document-upstream-impact meldet UNKNOWN/0 aufgelöste Caller für NEXTSTEPS; neuer Bericht nicht im Graph vorhanden (UNKNOWN/Exit 1). Kein grüner Nachweis daraus. Literale Textprüfung im produktiven lib/tool/pipeline-Code fand keine direkten NEXTSTEPS.md-Verweise; autorisierte Änderungen betreffen Daten/Markdown, keine Laufzeitfunktion. Keine notwendige Funktionsänderung und deshalb kein unterlassener Funktions-impact.

Aktueller detect-changes-Lauf erkennt im Unterschied zum früheren „No changes detected“ **1 Datei / 4 Abschnittssymbole in NEXTSTEPS**, 0 betroffene Prozesse, risk low für diesen erkannten Umfang. Er liefert weiterhin keinen belastbaren Vollabdeckungsnachweis für den großen gemischten Arbeitsbaum und unindexierte Liefer-/Kontextdateien; keine partial/truncated-Angaben zur Vollständigkeitsbestätigung. Dies schließt die vorherige Abdeckungslücke ausdrücklich nicht. Kein Commit erzwungen, keine wiederholte Lockerung und kein Indexneubau. Inhalts-/Hash-/SQLite-/Lesetests liefern den eigenständigen technischen Nachweis dieses Imports.

## Originallieferung und Auswahlbindung

Original-ZIP `/Users/ardasayar/Downloads/alltagssprache_redewendungen_batch_4_lieferung.zip`; bereits vorhandener Rootordner `alltagssprache_redewendungen_batch_4/`. Alle 30 Dateien der entpackten Lieferung bytegleich mit der Rootkopie; ZIP-CRCs und vollständige Liefermanifesthashes bestanden. Originalbytes erhalten, eigene Entpackung unter checks/delivery. Reference-Dateien bytegleich zur geprüften Batch-4-Authoring-ZIP; verkürzt abgelegtes V2-Schema gegen echten Archivpfad pipeline/data/curation/editorial_content_v2.schema.json verglichen. Reference-Manifest beschreibt den vollständigen ursprünglichen Kontext, Lieferung dessen beigefügte Teilmenge.

Erwartete Basis-JSON-/SQLite-/Create-Rohhashes und Registry-Digest exakt bestätigt. reference/registry.json entspricht lokalem Batch-4-v2-Snapshot bytegleich. Tatsächliches vorgefundenes Manifest mit Version/Schema/Quelle/allen Tabellen geprüft und dessen eigener Bytehash vor Staging erfasst, keine Manifestzahl aus einem älteren Bericht übernommen.

Auswahl v2 unverändert: **441 Ziele, Batches 89/89/88/88/87**, vor Import 266/88/87. Genau 88 aktuelle Ziele, 87 spätere nicht importiert. in my opinion bleibt aus aktivem zukünftigem Katalog ausgeschlossen; bestätigte neutrale Alternative von to my mind und historische ungenutzte Reservierung erhalten. Keine Auswahlkorrektur/Wiederaufnahme/Neuordnung.

## Satz-, Token- und Alternativprüfung

Alle 88 Satzpaare gegen Definitionen/Glossen, alle **872 Tokenpositionen / 722 Wort- und Ausdruckstokens** gegen token_review geprüft, einschließlich Begleitwörter. Exakte Kartenform-/Sense-/ID-/learning-/Definitionsbindung und Originalpositionen erhalten. Vollständige Ausdrücke bilden jeweils eine zusammenhängende Lücke und einen lexical_span. accepted bleibt exakt [card.form] einschließlich großem I/Apostrophen; echte Tokenisierung, Wort-/Sense-/Dictionaryabdeckung und alle Reviewhashes vom vorhandenen Importer geprüft, keine Platzhalter-/Ersatzsätze.

Sonderbindungen: contain#gefuehl-zurueckhalten; carry#risiko-bergen; pay/NOUN#arbeitsverguetung; missing bei wedding → miss#ereignis-verpassen; missed bei words → miss#nicht-mitbekommen; sheet#blatt; building trust → build#beziehung-aufbauen; used → use/AUX#fruher-gewohnheit. Vier tatsächliche Batch-3-Korrekturen Some#einige, thing#umstaende, work#gelingen bei worked/Versuch und work/Idee sowie sieben ältere Korrekturen konkret erhalten.

Drei satzbezogene Alternativen mit wörtlichen Ersetzungstexten:

| Ziel → Alternative | Geprüfter Ersetzungstext |
|---|---|
| return the favor → return the favour | You lent me your car; now I can return the favour. |
| leave well alone → leave well enough alone | Everyone is happy, so we should leave well enough alone. |
| much appreciated → greatly appreciated | greatly appreciated! I couldn't carry that box alone. |

alternative_review entspricht exakt den Importreviews. Aussage und Anschluss im konkreten Satz geprüft. Alle drei ganzen Oberflächen erneut gegen alle 441 Ziele, komplette Reservierungen/Owner/Aliase und aktiven Karten-/Gruppenkontext geprüft: kein konkurrierendes Ziel oder Besitzer. Einzelbestandteile von Mehrwortausdrücken werden nicht neu reserviert. Keine Antwortfreigabe aus Gruppenzugehörigkeit/Alias, keine globale Synonymie oder zusätzliche Vollständigkeitsbehauptung.

## Minimale gesonderte Importkopie

`build/alltagssprache_batch_4_checks/import_copy/alltagssprache_redewendungen_batch_4/`; zwei neue Begleitwortfehlbindungen getrennt von Altglossen behandelt:

| Satz / Token | Vorher → Nachher | Grund |
|---|---|---|
| alltagssprache-v1-0290-s1 / 7 (between) | between/ADP\|between#zwischen → between/ADP\|between#beteiligte | Streit zwischen meinen Freunden: Beteiligtenbeziehung statt räumlich begrenztem Raum. |
| alltagssprache-v1-0309-s1 / 5 (real) | real/ADJ\|real#echt → real/ADJ\|real#verstaerkend | a real nuisance verstärkt die Bewertung als wirklich lästig; alter Sense beschreibt Echtheit/Nutzbarkeit statt Bewertungsstärke. |

Zwei präzise reine Wörterbuchsenses/Formen ergänzt: Beteiligtenrelation statt räumlicher Lage; verstärkende Bewertung statt Echtheit/Nutzbarkeit. Keine zusätzlichen Lernkarten/Owner und keine alte Glosse geändert. Dies sind kontextuelle Bedeutungsabgrenzungen, keine neuen Senses allein zur Umgehung einer geteilten Formglosse. Ziele, Satztexte/Übersetzungen, Lücken, accepted/Alternativen, learning und Mitgliedschaften unverändert.

Bestehende import_editorial_patch.digest für Token-/Linkreviewhashes; vollständigen token_review synchronisiert. Display-Patch ausschließlich in create_sha256 an korrigierte Create-Rohbytes neu gebunden; übrige Hashes/Mappings unverändert. Arbeitskopie-Manifest erneuert, local_corrections.json enthält Vorher/Nachher/Gründe. Originale authoring_evidence-/validation_report-Dateien bleiben historische Chatbelege; maßgeblich sind lokale Import-/Audit-/Finalisierungsberichte. Keine abgeschwächte Prüfung.

## Display, vollständiger Export und internes Staging

Create hängt neue Mitgliedschaften auf **267–354** an; gepaarter hashgebundener Patch ordnet nur die beiden Displaypositionen dieses Stapels auf **1–354** nach unveränderten Originalpositionen. Alle 354 Mappingzeilen, Identitäten/Positionen und Quell-/Create-/Registry-/Vorherzeilenhashes geprüft. Original-/Registrypositionen bleiben unverändert; keine andere Kategorie umgeordnet.

Alle alten JSON-Inhaltszeilen und SQL-IDs/Nutzwerte erhalten, außer ausdrücklich erlaubten beiden Anzeigepositionen dieses Stapels und Release-/Registry-Metadaten. Alle 22 SQLite-Tabellen vollständig zeilen-/spaltenweise gegen build_rows; content_releases.created_at wie bisher exportgeneriert. Integritycheck ok, keine FK-Verstöße; eindeutige Wörterbuch-/Gruppen-/Referenzschlüssel und ein aktiver fester Satz je neuer Karte vom bestehenden Builder geprüft.

Vier Formtabellen identisch: 134 Lexikalanker, 406 Zuordnungen, 402 Formziele/Mitgliedschaften, 134/134/134 Übungen. Final 2921 Karten, zwölf Stapel, 354 Alltagssprache-Ziele; 88 neue Satzpaare/872 Tokens und nach Korrektur 116 neue Wörterbuchsenses/133 Dictionary-Formzeilen. Produktive LearningGroups-/lexicalCountingKeys-Projektion **2807 Übungen / 2536 Wörter**, nicht aus 2710 Besitzzeilen abgeleitet.

Linter **0 Fehler / 469 Warnhinweise**, davon drei neu: setback 3,37 bei resolve, doorbell 3,05 bei nuisance, tiring 3,37 bei to sum up, jeweils unter 3,5. 466 geerbte Hinweise getrennt erhalten; keine Warnungsunterdrückung.

App-Asset und Manifest nachweislich **vor Staging** unter checks/backup gesichert, bytegleich und per Vorherhash geprüft. Erst nach Import-/Audits internes Staging und --verify. Angeforderte abschließende Reihenfolge Asset-Verifier → Flutter-Analyse → echter Pack-Lesetest eingehalten; ein früher unabhängiger Analyse-/Leseprecheck war bereits bestanden, die finale Abnahme wurde für diese Reihenfolge wiederholt. Vorhandener unveränderter test/data/real_pack_test.dart nutzt allgemeine dynamische Inventar-/Repository-/Satzprüfungen und liest alle zwölf Stapel, 354 Ziele und 2921 feste Karten-Satzpaare. Keine Code-/Teständerung, kein Gerätelauf; Testdatenbank ausschließlich temporär. Echte user.db/Lernstände nicht geöffnet, kopiert oder verändert.

## Batch 5: vollständiger letzter Kontext

Fortsetzung aus echter finaler gestagter Basis und unveränderter Auswahl v2: **354 importiert / 87 aktuell / 0 später**; alle 441 Identitäten disjunkt vollständig. 2921 bestehende Gruppenentscheidungen und 87 geplante Köpfe; keine späteren Satzaufträge. Alle 22 Tabellen, Wörterbuch-/Besitzer-/Gruppen-/Formdaten und versionierter Ausschlussnachweis enthalten. Alte inaktive Reservierung nicht entfernt, keine Batch-5-Sätze erstellt.

ZIP geschlossen/erneut geöffnet: CRCs, **83 manifestierte Dateihashes**, sämtliche Referenzen/Hashbindungen, 441 exakte Identitäten und gesamte Partition. Alle 22 Quelltabellen nochmals gegen build_rows, ZIP-SQLite bytegleich mit Quelle und gestagtem Asset. Elf frühere und zwei aktuelle Tokenkorrekturen im tatsächlichen Pack konkret nachgewiesen. Kein neuer Fortsetzungsblocker.

## Tatsächliche Befehle, Output und Exitcodes

Ausgeführt auf macOS ab Repository-Root. Windows PowerShell: identische Python-Argumente mit `.\pipeline\.venv\Scripts\python.exe` statt `pipeline/.venv-macos/bin/python`; Node/Dart/Flutter/Git plattformgleich. Temporäre Audits /tmp/everyday-import-b4 verwenden vorhandene Validatoren/Funktionen; kein zweiter Importer. Gekürzte Outputs; vollständige Logs im checks-Ordner.

```text
node .gitnexus/run.cjs list
sprachlernapp; existing local repository/index
Exit 0
node .gitnexus/run.cjs status
Index content: 1 changed, 49 added, 0 deleted; Status stale
Exit 0
node .gitnexus/run.cjs context --uid 'Function:pipeline/scripts/import_editorial_patch.py:create_content' --repo .
found/exact; incoming 30, outgoing 4
Exit 0
node .gitnexus/run.cjs context --uid 'Function:pipeline/src/sprachpipe/deck_display.py:apply_deck_display_patch' --repo .
found/exact; incoming 1, outgoing 2
Exit 0
node .gitnexus/run.cjs context --uid 'Function:pipeline/src/sprachpipe/authoring_context.py:prepare_continuation' --repo .
found/exact; incoming 0, outgoing 7 (not unused)
Exit 0
node .gitnexus/run.cjs context --uid 'Function:pipeline/scripts/export_authoring_context.py:export' --repo .
found/exact; incoming 8, outgoing 5
Exit 0
node .gitnexus/run.cjs impact --uid 'File:NEXTSTEPS.md' --direction upstream --repo .
UNKNOWN; 0 callers resolved; not a green safety proof
Exit 0
node .gitnexus/run.cjs impact --uid 'File:docs/alltagssprache-redewendungen-batch-4-import.md' --direction upstream --repo .
Target not found; new unindexed report; risk UNKNOWN
Exit 1
node .gitnexus/run.cjs detect-changes --scope all --repo . --limit 2000

  GitNexus Detect Changes (1.6.12)
Changes: 1 files, 4 symbols
Affected processes: 0
Risk level: low

Changed symbols:
  Section NEXTSTEPS → NEXTSTEPS.md
  Section Erledigt → NEXTSTEPS.md
  Section Dateien und Prüfungen → NEXTSTEPS.md
  Section Abweichungen und offen → NEXTSTEPS.md
Exit 0 (only recognized scope; complete coverage remains open)

pipeline/.venv-macos/bin/python /tmp/everyday-import-b4/audit_delivery.py
DISPLAY mapping fields ['card_ref', 'form_norm', 'original_position', 'append_position']
DELIVERY PASS: 30 ZIP entries/manifest hashes/reference subset/schema/source/registry; 441 identities with 88 current; 872 tokens (722 words/spans); three alternatives/no selection-owner-alias collisions; ten inherited findings unchanged
SEMANTIC review: between in argument refers to participants; real nuisance is emphatic, not ordinary-use authenticity.
Exit 0
pipeline/.venv-macos/bin/python /tmp/everyday-import-b4/correct.py
CORRECTION COPY PASS: build/alltagssprache_batch_4_checks/import_copy/alltagssprache_redewendungen_batch_4 ; 2 sense-only token edits, 2 dictionary-only senses and forms; existing reviews/display raw create binding renewed
CREATE SHA256 6dde58bff269595457be184f87d506adb883a57f7be92804167917994e918907
Exit 0
pipeline/.venv-macos/bin/python pipeline/scripts/import_editorial_patch.py --source pipeline/out/alltagssprache_redewendungen_batch_3_v1/pack.json --create build/alltagssprache_batch_4_checks/import_copy/alltagssprache_redewendungen_batch_4/editorial_content_v2.json --registry pipeline/data/words/en.alltagssprache_redewendungen_batch_4_context_v2.json --display-patch build/alltagssprache_batch_4_checks/import_copy/alltagssprache_redewendungen_batch_4/deck_display_patch.json --out pipeline/out/alltagssprache_redewendungen_batch_4_v1
{
  "status": "ok",
  "internal_test_pack": true,
  "ai_calls": 0,
  "ai_cost_usd": 0,
  "sqlite_counts": {
    "languages": 1,
    "lemmas": 3981,
    "senses": 5557,
    "cards": 2921,
    "dictionary_forms": 6647,
    "decks": 12,
    "deck_cards": 2814,
    "deck_words": 2710,
    "word_aliases": 37,
    "sentences": 3455,
    "sentence_tokens": 37673,
    "card_sentences": 3449,
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
  "sha256": "cde0265001925026155faa65839cdeff7745f84f237d394032bb2eef8570b5d1"
}
Exit 0
pipeline/.venv-macos/bin/python /tmp/everyday-import-b4/audit_pack.py
PACK PASS: 2921 cards, 12 decks, 354 ordinary goals; 88 new fixed pairs/872 tokens; 87 future absent; excluded duplicate absent/old neutral alternative retained
PRESERVATION PASS: all old JSON/SQL rows/IDs preserved except two display-position columns for this deck; all 22 tables/build_rows/integrity/foreign keys PASS; four form tables unchanged, 134/134/134
DISPLAY PASS: append 267..354 then exact original-order displays 1..354; registry/original positions unchanged
CORRECTION COPY PASS: exactly 2 sense-only token edits; two new dictionary senses/forms; all target definitions/learning/texts/gaps/alternatives unchanged
LINTER 469 warnings total; 0 errors; NEW [{'card': 'resolve|resolve/NOUN|resolve#entschlossenheit', 'level': 'warn', 'rule': 'i+1', 'message': "'setback'/'setback' Zipf 3.37 below 3.5"}, {'card': 'nuisance|nuisance/NOUN|nuisance#argernis', 'level': 'warn', 'rule': 'i+1', 'message': "'doorbell'/'doorbell' Zipf 3.05 below 3.5"}, {'card': 'to sum up|to sum up/ADV|to-sum-up#zusammenfassend', 'level': 'warn', 'rule': 'i+1', 'message': "'tiring'/'tiring' Zipf 3.37 below 3.5"}]
VERIFIED BACKUP content.sqlite 97a7b185dc5fa1e0085a8e461a3d54ce9afff7f855b418bb5a1f231c283e6e98
VERIFIED BACKUP content.manifest.json d89b5893459e0df865d878c66955d95635f2580730dee88ea0ec51dd62cbe64b
Exit 0
pipeline/.venv-macos/bin/python -m pytest pipeline/tests -q
447 passed, 19 subtests passed in 12.96s
Exit 0
dart run tool/report_learning_groups.dart pipeline/out/alltagssprache_redewendungen_batch_4_v1/content.sqlite
mixed: raw_words=2888; learning_targets=2807; lexical_words=2536; form_memberships=402
Exit 0
dart run tool/stage_content_pack.dart --from pipeline/out/alltagssprache_redewendungen_batch_4_v1
staged assets/content/en/content.sqlite
  version alltagssprache_redewendungen_batch_4_v1, schema 4, 18726912 bytes
  sha256 cde0265001925026155faa65839cdeff7745f84f237d394032bb2eef8570b5d1
  22 table counts match finalization_report.json
  INTERNES TEST-PACK: own devices and selected testers only, no public content release
Exit 0
dart run tool/stage_content_pack.dart --verify
verified assets/content/en/content.sqlite
  version alltagssprache_redewendungen_batch_4_v1, schema 4, 18726912 bytes
  sha256 cde0265001925026155faa65839cdeff7745f84f237d394032bb2eef8570b5d1
  22 table counts match finalization_report.json
  INTERNES TEST-PACK: own devices and selected testers only, no public content release
Exit 0
flutter analyze --no-pub
Analyzing sprachapp...
No issues found! (ran in 2.2s)
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
deck alltagssprache-redewendungen: 354 learning targets, 354 ownership cards, 354 fixed sentence assignments verified
pack alltagssprache_redewendungen_batch_4_v1 (schema 4, internal: true); 12 decks: 2710 cards, 2921 card sentences, 178 with valid_alternatives, 2921 cards in the pack
00:40 +1: All tests passed!
Exit 0
pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --help
CLI includes selection/batch/out/prepare-continuation/verify-zip
Exit 0
pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --selection pipeline/data/selection/alltagssprache_redewendungen_v2.json --batch 5 --prepare-continuation alltagssprache_redewendungen_batch_5_context_v2
{
  "snapshots": "PASS",
  "paths": {
    "selection": "pipeline/data/selection/alltagssprache_redewendungen_batch_5_context_v2.json",
    "registry": "pipeline/data/words/en.alltagssprache_redewendungen_batch_5_context_v2.json",
    "groups": "pipeline/data/learning_groups/en.alltagssprache_redewendungen_batch_5_context_v2.json"
  },
  "partition_counts": {
    "imported": 354,
    "current": 87,
    "future": 0
  }
}
Exit 0
pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --selection pipeline/data/selection/alltagssprache_redewendungen_batch_5_context_v2.json --batch 5 --out build/alltagssprache_redewendungen_authoring_batch_5.zip
status PASS; selected 441; partition 354/87/0
Exit 0
pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --verify-zip build/alltagssprache_redewendungen_authoring_batch_5.zip
{
  "zip_verification": "PASS",
  "zip_sha256": "67b816d784d0e7777b61582d452fa60c6e00a9c7072887b59fb95b59ae452eea",
  "hashed_files": 83,
  "sqlite_tables": 22,
  "sqlite_cards": 2921,
  "selected": 441,
  "partition_counts": {
    "imported": 354,
    "current": 87,
    "future": 0
  }
}
Exit 0
pipeline/.venv-macos/bin/python /tmp/everyday-import-b4/final_audit.py
CLOSED ZIP PASS: CRC/83 hashes/441 exact identities/354 imported/87 current/0 future; all 22 tables; source/asset byte-identical
2782-file preservation audit: only authorized NEXTSTEPS/Asset/Manifest changed; old source/code/tests/index/graph metadata preserved
Exit 0
```

Routineprüfungen und realer Import/Display/Export/Fortsetzung/ZIP-Verifier jeweils beim ersten Aufruf bestanden. Textsuche nach NEXTSTEPS im produktiven Code hatte erwartungsgemäß keine Treffer (rg Exit 1); kein Inhaltstestfehler. Graph-Report-impact Exit 1 betrifft den neuen nicht indexierten Markdown-Bericht, keine gelockerte Inhaltsprüfung. Bekannte Graphgrenzen ausdrücklich offen, keine Behauptung vollständiger Abdeckung.

## Zehn geerbte Formglossen-Befunde – weiterhin offen

Originale gemeinsame Dictionary-Zeilen erhalten; Kontexte und Vorschläge nur dokumentiert. Frühere Listen bleiben offen; neue Zuordnungsfehler oben getrennt korrigiert.

| Schlüssel | Alte Glosse → Vorschlag | Kontext / Grund |
|---|---|---|
| lovely\|lovely/ADJ\|lovely#schoene | schöne → schön | Flektierte Altglosse schöne bei prädikativem Gebrauch. why not: Why not? A walk sounds lovely. |
| concert\|concert/NOUN\|concert#konzert | Konzert- → Konzert | Gebundene Altglosse Konzert- bei eigenständigem Nomen. what a shame: What a shame! The concert has been cancelled. |
| cancelled\|cancel/VERB\|cancel#verabredung-absagen | sagte ab → abgesagt; sagte ab | Im Passiv steht das Partizip; die geerbte Formglosse enthält nur sagte ab. what a shame: What a shame! The concert has been cancelled. |
| talking\|talk/VERB\|talk#sprechend-redet | sprechend / redet → sprechen; sprach | Die Altglosse sprechend / redet ist für was talking unpassend formuliert. I didn't mean it that way: I didn't mean it that way; I was talking about the noise. |
| needed\|need/VERB\|need#brauchen | brauchten → brauchte; brauchten | Altglosse nur im Plural, Satzsubjekt ist she. a shoulder to cry on: After the breakup, she needed a shoulder to cry on. |
| home\|home/NOUN\|home#hause | Hause → Zuhause | Hause allein ist eine unvollständige Glosse für das eigenständige Nomen. just my luck: Just my luck! It started raining as soon as I left home.; whatever happens: Whatever happens, you will always have a home here. |
| leaving\|leave/VERB\|leave#gehen | Abschied (in leaving present) → gehen; weggehen | Altglosse Abschied (in leaving present) gehört zu einem anderen syntaktischen Gebrauch derselben Form. burn bridges: I don't want to burn bridges by leaving without a word. |
| second\|second/ADJ\|second#zweiten | zweiten → zweite; zweiter; zweites | Flektierte Altglosse zweiten ist für a second car zu eng. the bottom line: The bottom line is that we cannot afford a second car. |
| myself\|myself/PRON\|myself#mich-selbst | mich selbst → selbst; mich selbst | Bei do something myself wird die selbstständige Durchführung betont, kein Akkusativobjekt. here goes nothing: Here goes nothing! I'll try to fix the tap myself. |
| missing\|missing/ADJ\|missing#verschwundenen | verschwundenen → fehlend; verschwunden | Die Altglosse ist flektiert; Wortbedeutung ist korrekt. sooner or later: Sooner or later, someone will notice the missing key. |

## Hashes, Erhaltung und Commitgrenze

| Datei | SHA256 |
|---|---|
| `/Users/ardasayar/Downloads/alltagssprache_redewendungen_batch_4_lieferung.zip` | `c2d924bef3ab122f74a0facc3019c8d0a10f8c5edf6cf91ae7cdbed0306192c3` |
| `build/alltagssprache_batch_4_checks/delivery/alltagssprache_redewendungen_batch_4/editorial_content_v2.json` | `83986559f63bb9084e92389629f9df00c680c1d5f328650216d05486dfe314a6` |
| `build/alltagssprache_batch_4_checks/import_copy/alltagssprache_redewendungen_batch_4/editorial_content_v2.json` | `6dde58bff269595457be184f87d506adb883a57f7be92804167917994e918907` |
| `build/alltagssprache_batch_4_checks/import_copy/alltagssprache_redewendungen_batch_4/deck_display_patch.json` | `9e4cad6290a39d8e083db9b7d1036d6d5b0cc338680f24a5242cd424df3a87c9` |
| `pipeline/out/alltagssprache_redewendungen_batch_3_v1/pack.json` | `33e0a22d82a20f06e9c2f7a58eccd61a4709148c03c998aaea0c8b894f59a503` |
| `pipeline/out/alltagssprache_redewendungen_batch_3_v1/content.sqlite` | `97a7b185dc5fa1e0085a8e461a3d54ce9afff7f855b418bb5a1f231c283e6e98` |
| `build/alltagssprache_batch_4_checks/backup/content.manifest.json` | `d89b5893459e0df865d878c66955d95635f2580730dee88ea0ec51dd62cbe64b` |
| `pipeline/data/selection/alltagssprache_redewendungen_v2.json` | `27e52591e0dd98df0510204664c03467c49347151398e1caef4538887751c71d` |
| `pipeline/data/words/en.alltagssprache_redewendungen_batch_4_context_v2.json` | `c223229705030354b73d63fb2d9d300260a1b807a6b8c5a382fa148ec18883c2` |
| `pipeline/out/alltagssprache_redewendungen_batch_4_v1/pack.json` | `42de21e3962fee724e1fda42c77f71a59042bca212ed84b709d0aa834f0b7761` |
| `pipeline/out/alltagssprache_redewendungen_batch_4_v1/content.sqlite` | `cde0265001925026155faa65839cdeff7745f84f237d394032bb2eef8570b5d1` |
| `assets/content/en/content.manifest.json` | `d6682c6b74b2c653a4681eab3de530778d5809e7b37042642b2800c317334fbd` |
| `pipeline/data/selection/alltagssprache_redewendungen_batch_5_context_v2.json` | `9e6abe319d613b71da10ad4ad5aa03e59638fe1b79fb23b62f1c4bfebe00a238` |
| `pipeline/data/words/en.alltagssprache_redewendungen_batch_5_context_v2.json` | `040ac9e61c3eeace461229ceccdbe7feb9ac2a5c2362b1818764f0ee57234ed2` |
| `pipeline/data/learning_groups/en.alltagssprache_redewendungen_batch_5_context_v2.json` | `14d28de56e1047c058973fa62e4cc457a4dff4544037597bc3cea7da4af85373` |
| `build/alltagssprache_redewendungen_authoring_batch_5.zip` | `67b816d784d0e7777b61582d452fa60c6e00a9c7072887b59fb95b59ae452eea` |

Kanonischer Input-Registry-Digest: c5ff39e7af844ddfc56305e8e26b6537800bc13b0a4d78691dd66986550b8eab, separat vom Dateibytehash. Backup-SQLite entspricht der unveränderten alten Quelle; finales Asset exakt dem neuen SQLite. Alle 2782 erfassten historischen Eingangsdateien außer erlaubten NEXTSTEPS-/Asset-/Manifeständerungen erhalten. Auswahl v2/Entscheidungen/Registrys/Gruppen, Original-ZIP/Rootlieferung, Code/Test/AGENTS/CLAUDE/GitNexus-Metadaten hashgleich. Keine echten Lernstände, Cloud-/Modell-/Supabase-Aufrufe, Installationen, neue Kategorien oder öffentlichen Freigaben.

Kein Commit: vorbestehende uncommittete Schema-4-/450-/V3-Abhängigkeiten und gemischte NEXTSTEPS-Hunks verhindern eigenständigen geprüften Commit auf HEAD. Zusätzlich bleibt die zuletzt ungeklärte GitNexus-Vollabdeckung ungelöst; niedrige Teilrisikoanzeige ist kein Ersatz. Index leer erhalten, kein pauschales git add/Push. Autorisierte technische Übergabe davon unabhängig bestanden.

Nächste Aktion: geprüfte ZIP im Chat hochladen und die letzten **87 aktuellen Batch-5-Ziele** redigieren. Späterer Import/Abschluss, Altglossen und öffentliche Sprach-/Geräteabnahme bleiben offen.

Geprüfte ZIP: `/Users/ardasayar/Documents/FlutterProjekte/sprachapp/build/alltagssprache_redewendungen_authoring_batch_5.zip`

## Abschließende Datei-/Whitespaceprüfung

```text
git diff --check -- NEXTSTEPS.md docs/alltagssprache-redewendungen-batch-4-import.md pipeline/data/selection/alltagssprache_redewendungen_batch_5_context_v2.json pipeline/data/words/en.alltagssprache_redewendungen_batch_5_context_v2.json pipeline/data/learning_groups/en.alltagssprache_redewendungen_batch_5_context_v2.json
Output: leer
Exit 0

git -c core.whitespace=cr-at-eol diff --check -- NEXTSTEPS.md docs/alltagssprache-redewendungen-batch-4-import.md pipeline/data/selection/alltagssprache_redewendungen_batch_5_context_v2.json pipeline/data/words/en.alltagssprache_redewendungen_batch_5_context_v2.json pipeline/data/learning_groups/en.alltagssprache_redewendungen_batch_5_context_v2.json
Output: leer
Exit 0

DIRECT whitespace PASS: 10 own document/context/correction files; NEXTSTEPS 25 lines
Paired display mapping and expected_before hashes unchanged; only create_sha256 renewed
Exit 0

git status --short
Vollständiger tatsächlicher Output: build/alltagssprache_batch_4_checks/status-after.txt.
Vorbestehender gemischter Arbeitsbaum erhalten; Index leer.
Exit 0
```

Ein direkter Scan der neuen unversionierten Dateien fand zunächst von Flutter-stdout kopierte Abschlussleerzeichen in einer Analysezeile des eigenen Berichts (AssertionError, Exit 1); ausschließlich diesen neuen Bericht bereinigt, Rohlog unverändert, danach direkter Scan bestanden. Kein globaler Whitespaceeingriff. Bekannte repositoryweite Altbefunde bleiben gesondert offen. Der Schlussaudit über 2782 erfasste Dateien bestätigt nur NEXTSTEPS.md, App-Asset und Manifest als erlaubte Änderungen unter vorbestehenden Dateien; neue Kontext-/Berichtsdateien kommen hinzu. Code/Test/AGENTS/CLAUDE/GitNexus-Metadaten und historische erfasste Eingangsdateien hashgleich erhalten.
