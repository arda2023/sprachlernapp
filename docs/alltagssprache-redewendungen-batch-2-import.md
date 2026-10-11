# Alltagssprache & Redewendungen – Batch 2: interner Import und Batch-3-Übergabe

Stand: 11.10.2026. **89 Batch-2-Ziele offline importiert und intern gestagt, 178 Alltagssprache-Ziele insgesamt.** Schema 4, zwölf Stapel, 2745 Karten; produktive Projektion **2631 Übungen / 2360 Wörter**. Batch-3-ZIP mit genau 88 neuen Satzaufträgen geschlossen und erneut vollständig geprüft. Keine öffentliche Inhaltsfreigabe.

## Verträge, Eingaben und eigener Umfang

Gelesen und gegen den Auftrag geprüft: AGENTS/CLAUDE/NEXTSTEPS, Roadmap, Alltagssprache-Authoring-/Batch-1-Import-/Auswahl-v2-Berichte, normaler Schema-4-Kompatibilitätsvertrag, Content-/Lerngruppenverträge, V2-Schema, Auswahl/Registry/Gruppen, Importer/Exporter, Display-Patch-Vertrag und Staging-Werkzeug. Die bestehende normale V2-Create-/Schema-4-Kompatibilität wird verwendet, nicht neu implementiert. Es wurden keine App-/Pipeline-/Schemafunktionen geändert.

Tatsächlicher Ablauf: `pipeline/scripts/import_editorial_patch.py --create --registry --display-patch` ruft `create_content`, `deck_display.apply_deck_display_patch` und `export_offline` auf. `pack.build_rows` und `finalize_curation.check_sqlite` prüfen alle 22 Tabellen. `tool/stage_content_pack.dart --from/--verify` wird erst nach bestandenen Audits und verifizierter Sicherung verwendet. Fortsetzung über den vorhandenen normalen `export_authoring_context.py --prepare-continuation` mit unveränderter Auswahl v2 und tatsächlichem gestagten Pack, anschließend Export und ZIP-Verifier.

Vorheraufnahme: 2701 erfasste vorbestehende Dateien mit SHA256, Gitstatus/leerem Index unter `build/alltagssprache_batch_2_checks/`. Bestehende gemischte V3-/Kompatibilitäts-/Dokumentänderungen erhalten. Vorherkopie des bestehenden Pack-Lesetests ebenfalls dort gesichert.

Eigene Dateien:

- Neuer Pack `pipeline/out/alltagssprache_redewendungen_batch_2_v1/`: pack.json, content.sqlite und finalization_report.json.
- App-Asset und Manifest ausschließlich über autorisiertes internes Staging aktualisiert.
- Neuer Bericht `docs/alltagssprache-redewendungen-batch-2-import.md`, NEXTSTEPS.md aktualisiert.
- Bestehender `test/data/real_pack_test.dart` nur um die Batch-2-Version, 178 Ziele/2745 Karten und konkrete Projektionszahlen erweitert; alte Versions-/Formprüfungen und Zeilenenden erhalten.
- Neue Kontextpfade, vor Erstellung genannt und mit vorhandener CLI ermittelt: `pipeline/data/selection/alltagssprache_redewendungen_batch_3_context_v2.json`, `pipeline/data/words/en.alltagssprache_redewendungen_batch_3_context_v2.json`, `pipeline/data/learning_groups/en.alltagssprache_redewendungen_batch_3_context_v2.json`.
- `build/alltagssprache_redewendungen_authoring_batch_3.zip`; Audit-/Liefer-/Korrektur-/Backup-Dateien unter `build/alltagssprache_batch_2_checks/`.

## Originallieferung, Auswahl und Satzprüfung

Original: `/Users/ardasayar/Downloads/alltagssprache_redewendungen_batch_2_lieferung.zip`. Ein eindeutiger Fund, 29 ZIP-Einträge, CRCs und sämtliche Liefermanifesthashes bestanden. Original bleibt bytegleich. Entpackung nach `build/alltagssprache_batch_2_checks/delivery/alltagssprache_redewendungen_batch_2/`.

Create-Rohhash, Basis-JSON-/SQLitehash und Registry-Digest stimmen mit den vorgegebenen Werten. Reference-Registry ist bytegleich zur lokalen Batch-2-v2-Registry. Sämtliche beigefügten Reference-Dateien wurden gegen die tatsächlich geprüfte Batch-2-Authoring-ZIP verglichen; die verkürzt abgelegte Schema-Datei gegen deren tatsächlichen Originalpfad `pipeline/data/curation/editorial_content_v2.schema.json`. Der Reference-Manifest beschreibt den vollständigen ursprünglichen Authoring-Kontext; die Lieferung enthält dessen nachgewiesene Teilmenge.

Auswahl v2 unverändert: 441 Identitäten in Batches 89/89/88/88/87; vor Import Partition 89/89/263. Exakt die 89 aktuellen Karten übernommen, 263 spätere nicht importiert. Kein separates zukünftiges Ziel in my opinion, bestehende neutrale Alternative von to my mind erhalten, historische ungenutzte Reservierung nicht gelöscht. Keine neue Auswahlkorrektur oder Neuverteilung.

Alle 89 Satzpaare, Zieldefinitionen und sämtliche 889 Tokenpositionen (742 Wort-/Ausdruckstokens) mit token_review und Auswahl geprüft, einschließlich Begleitwörtern und deren bestehenden Definitionen/Formglossen. Alle Zielkartenformen, Sense-/Kartenidentitäten, cards.learning, Original-/Besitzpositionen und Definitionen unverändert. Whole-expression gaps bilden jeweils genau eine zusammenhängende Lücke und einen lexical_span. accepted bleibt exakt [card.form], inklusive großem I und Apostrophen. Vorhandener Importer prüft echte Tokenisierung, Reviewhashes, Referenzen und Wörterbuchabdeckung; keine Platzhalter-/Ersatzsätze.

Besondere geprüfte Bindungen: minutes → minute/NOUN|minute#minuten (Zeiteinheit); judge → judge/NOUN|judge#juror; risk → risk/VERB|risk#riskieren; missed bei deadlines → miss#frist-versaeumen, beim Urlaub → miss#vermissen; through vor door → ADP/durch, bei get through ohne Objekt → ADV/hindurch; why → ADV/warum-frage; before vor the phone rang → SCONJ/bevor; office → office#buero, nicht Postamt. hear about im thrilled-Satz nutzt die erhaltene Batch-1-Korrektur hear#erfahren.

Genau zwei neue Alternativen, wörtlich anhand alternative_review und Importreviews geprüft:

| Karte | Alternative | Tatsächliche Ersetzung |
|---|---|---|
| no offence | no offense | no offense, but this soup needs a little more salt. |
| if memory serves | if memory serves me | if memory serves me, we first met at your cousin's wedding. |

Beide Varianten erhalten im konkreten Satz Aussage und Anschluss. Vollständiger Oberflächen-/Reservierungs-/Aliasabgleich gegen alle 441 Ziele und den aktuellen Registry-/Karten-/Gruppenkontext: kein konkurrierendes Ziel/Owner/Alias. Keine globale Synonymfreigabe oder weiterer Alternativvorschlag abgeleitet. Bestehende Builder-/Gruppenvalidatoren bleiben maßgeblich. Individueller Nachweis in delivery-audit.json.

## Minimal korrigierte gesonderte Importkopie

Arbeitskopie: `build/alltagssprache_batch_2_checks/import_copy/alltagssprache_redewendungen_batch_2/`. Vier Begleitwortbindungen korrigiert; Originaldateien erhalten:

| Satz / Token | Vorher → Nachher | Befund |
|---|---|---|
| alltagssprache-v1-0096-s1 / 12 (high) | high/ADJ\|high#hoch → high/ADJ\|high#betrag | high bei rent: hoher Betrag, kein räumlicher Abstand vom Boden. |
| alltagssprache-v1-0104-s1 / 1 (cancelled) | cancel/VERB\|cancel#stornieren → cancel/VERB\|cancel#verabredung-absagen | Abgesagtes Vorhaben/Reise; keine ausdrücklich genannte Buchungsstornierung. |
| alltagssprache-v1-0134-s1 / 1 (cancelled) | cancel/VERB\|cancel#stornieren → cancel/VERB\|cancel#verabredung-absagen | Abgesagte dinner plans; bestehender Vorhabens-/Verabredungssinn statt Buchungsstornierung. |
| alltagssprache-v1-0129-s1 / 7 (made) | make/VERB\|make#veranlassen → make/VERB\|make#zustand-bewirken | made me feel welcome bewirkt einen inneren Zustand, keine ausgeführte Handlung. |

Bei high handelt es sich um echte Polysemie: die alte Definition beschreibt räumliche Höhe, die Miete einen hohen Betrag. Ein präziser reiner Wörterbuchsense high#betrag und eine Dictionary-Form ergänzt, keine neue Lernkarte/Reservierung. Für die anderen drei Änderungen wurden bereits vorhandene passende Sinne und Dictionary-Formen wiederverwendet. Die Aussage der Sätze bleibt unverändert; keine alte Definition/Formglosse umgeschrieben. Insgesamt gegenüber Original-Lieferung: ein zusätzlicher Sense und eine zusätzliche Form, vier Sensefelder in Tokens, vier Reviewbegründungen/-Tokenbindungen.

Bestehende `import_editorial_patch.digest` für Tokens/Links verwendet, vollständigen token_review synchronisiert. `deck_display_patch.create_sha256` gegen die tatsächlich korrigierten Create-Rohbytes erneuert; alle übrigen Display-Patch-Felder und mappings unverändert. Das Arbeitskopie-Manifest enthält die neuen Dateibytehashes und local_corrections.json. Frühere validation_report-/authoring_evidence-Dateien sind historische Chatnachweise; die lokalen Import-/Auditberichte sind maßgeblich. Keine Schema-/Prüfgrenze abgesenkt.

## Display, Export und Bestandsschutz

Der vorhandene Create-Weg hängt die 89 neuen Mitgliedschaften auf 90–178 an. Der gepaarte hashgebundene Patch ordnet ausschließlich die beiden Positionsspalten in deck_cards/deck_words für Alltagssprache auf 1–178 entsprechend der unveränderten Originalauswahl. Quell-/Create-/Registry-Hashes, komplette Vorherzeilenhashes, tatsächliche Reservierungsidentitäten und alle 178 Mappingzeilen geprüft; kein neues deck und kein Registry-/Originalpositionstausch.

Alle alten JSON-Inhalte und SQL-Zeilen mit IDs/Nutzwerten erhalten, ausgenommen die ausdrücklich zugelassenen Displaypositionen dieses Stapels sowie Release-/Registry-Metadaten. Vollständiger 22-Tabellen-Abgleich gegen build_rows einschließlich aller Zeilen/Spalten; wie bisher ist content_releases.created_at exportgeneriert. Integritycheck ok, keine Foreign-Key-Verstöße, eindeutige Wörterbuchschlüssel/Referenzen und ein aktiver fester Satz pro neuer Karte durch vorhandene Builder bestätigt.

Vier Formtabellen vollständig unverändert: 134 lexikalische Anker, 406 Kartenzuordnungen, 402 Formziele/Ansichtsmitgliedschaften, je 134 Übungen. Alte 89 Alltagssprache-Sätze, deren acht Alternativen und alle drei Batch-1-Tokenkorrekturen erhalten. Alle vier aktuellen Korrekturen im tatsächlichen finalen Pack und ZIP nachgewiesen.

Ergebnis: 2745 Karten, zwölf Stapel, 178 Alltagssprache-Ziele. 89 neue Satzpaare, 889 neue Tokens, 122 neue Wörterbuchsenses und 139 neue Dictionary-Formzeilen nach Korrektur. Bestehende produktive LearningGroups-/lexicalCountingKeys-Projektion: **2631 Übungen / 2360 Wörter**, nicht aus 2534 Besitzzeilen oder Kartenzahlen abgeleitet.

Linter: **0 Fehler, 465 Warnhinweise insgesamt**. Zwei neue Hinweise: unfairly 3,36 bei eat humble pie und unfriendly 3,10 bei I wouldn't say that, jeweils unter 3,5. Die 463 älteren Hinweise bleiben getrennt offen; keine Umformulierung zur Warnungsunterdrückung.

Assets/Manifest **vor Staging** nach `build/alltagssprache_batch_2_checks/backup/` gesichert, bytegleich und per SHA256 gegen Vorheraufnahme geprüft. Erst dann internes Staging; Asset-Verifikation und tatsächlicher Installer-/Repository-Lesetest mit zwölf Stapeln bestanden. Testdatenbank ausschließlich temporär; echte user.db/Lernstände nicht geöffnet, kopiert, migriert oder verändert. Kein Gerätelauf, keine Geräteabnahme.

## Batch-3-Kontext und ZIP

Fortsetzung mit der unveränderten Auswahl v2 und tatsächlichem finalem Pack: **178 importiert / 88 aktuell / 175 später**, 441 disjunkte Identitäten. Alle alten Gruppen-/Besitzer-/Formdaten im Kontext; 2745 bestehende Kartenentscheidungen, 263 zukünftige geplante Köpfe. Der Ausschlussnachweis aus Auswahl v2 ist in selection.json/original_selection.json enthalten, die historische Reservierung bleibt erhalten. Keine neue Korrekturauswahl, keine Batch-3-Sätze.

ZIP geschlossen, erneut geöffnet und vollständig geprüft: CRCs, 83 Manifest-Dateihashes, sämtliche Referenzen/Hashbindungen, 441 exakte Identitäten und vollständige Restpartition. Alle 22 Basis-SQLite-Tabellen erneut vollständig gegen build_rows verglichen. Die enthaltene SQLite ist bytegleich zum gestagten Asset und finalen Quell-SQLite. Kein neuer Exportblocker.

## Tatsächliche Befehle, relevante Outputs und Exitcodes

Ausgeführt auf macOS ab Repository-Root; unter Windows PowerShell gleiche Python-Argumente mit `.\pipeline\.venv\Scripts\python.exe` statt `pipeline/.venv-macos/bin/python`. Dart-/Flutter-/Git-Befehle identisch. Lokale temporäre Audithelfer `/tmp/everyday-import-b2/*.py` verwenden vorhandene Funktionen, kein zweiter Importer. Gekürzte Nachweise; vollständige lokale Logs im checks-Ordner.

```text
pipeline/.venv-macos/bin/python /tmp/everyday-import-b2/audit_delivery.py
DELIVERY PASS: 29 ZIP entries/manifest hashes/reference subset/schema/source/registry; 441 identities with 89 current; 889 tokens (742 words/spans); two alternatives/no selection-owner-alias collisions; six inherited findings unchanged
SEMANTIC corrections required: high rent (0096), cancelled trip (0104), cancelled dinner plans (0134), made me feel welcome (0129)
Exit 0

pipeline/.venv-macos/bin/python /tmp/everyday-import-b2/correct.py
CORRECTION COPY PASS: 4 sense-only token edits, 1 real dictionary-only polysemy, 1 new dictionary form; existing reviews/display raw create binding renewed
CREATE SHA256 24a08960b714d3b70b1cde2cbfeb71b9002b237f63bfbf1fb53a0af77377413f
Exit 0

pipeline/.venv-macos/bin/python pipeline/scripts/import_editorial_patch.py --source pipeline/out/alltagssprache_redewendungen_batch_1_v1/pack.json --create build/alltagssprache_batch_2_checks/import_copy/alltagssprache_redewendungen_batch_2/editorial_content_v2.json --registry pipeline/data/words/en.alltagssprache_redewendungen_batch_2_context_v2.json --display-patch build/alltagssprache_batch_2_checks/import_copy/alltagssprache_redewendungen_batch_2/deck_display_patch.json --out pipeline/out/alltagssprache_redewendungen_batch_2_v1
{
  "status": "ok",
  "internal_test_pack": true,
  "ai_calls": 0,
  "ai_cost_usd": 0,
  "sqlite_counts": {
    "languages": 1,
    "lemmas": 3771,
    "senses": 5308,
    "cards": 2745,
    "dictionary_forms": 6366,
    "decks": 12,
    "deck_cards": 2638,
    "deck_words": 2534,
    "word_aliases": 37,
    "sentences": 3279,
    "sentence_tokens": 35977,
    "card_sentences": 3273,
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
  "sha256": "849d342fca6872b701742ff903e873944f7dc564cf7df034d64d443933fadfe2"
}
Exit 0

pipeline/.venv-macos/bin/python /tmp/everyday-import-b2/audit_pack.py
PACK PASS: 2745 cards, 12 decks, 178 ordinary goals; 89 new fixed pairs/889 tokens; 263 future absent; excluded duplicate absent/old neutral alternative retained
PRESERVATION PASS: all old JSON/SQL rows/IDs preserved except two display-position columns for this deck; all 22 tables/build_rows/integrity/foreign keys PASS; four form tables unchanged, 134/134/134
DISPLAY PASS: append 90..178 then exact original-order displays 1..178; registry/original positions unchanged
CORRECTION COPY PASS: exactly 4 sense-only token edits; one new dictionary sense/form; all target definitions/learning/texts/gaps/alternatives unchanged
LINTER 465 warnings total; 0 errors; NEW [{'card': 'eat humble pie|eat humble pie/VERB|eat-humble-pie#kleinlaut-einen-fehler-eingestehen', 'level': 'warn', 'rule': 'i+1', 'message': "'unfairly'/'unfairly' Zipf 3.36 below 3.5"}, {'card': "I wouldn't say that|I wouldn't say that/INTJ|i-wouldn-t-say-that#so-wurde-ich-das-nicht-sagen", 'level': 'warn', 'rule': 'i+1', 'message': "'unfriendly'/'unfriendly' Zipf 3.10 below 3.5"}]
VERIFIED BACKUP content.sqlite f1b4269482f8f27b2152529af13343236e51a8d1148eb0121adcf30443104802
VERIFIED BACKUP content.manifest.json 27f1cbfaf5e43c72d227ad9b6291038b40e808560dfcd5d02536e414e2083b56
Exit 0

pipeline/.venv-macos/bin/python -m pytest pipeline/tests -q
447 passed, 19 subtests passed in 24.44s
Exit 0

dart run tool/report_learning_groups.dart pipeline/out/alltagssprache_redewendungen_batch_2_v1/content.sqlite
mixed: raw_words=2712; learning_targets=2631; lexical_words=2360; form_memberships=402
Exit 0

dart run tool/stage_content_pack.dart --from pipeline/out/alltagssprache_redewendungen_batch_2_v1
staged assets/content/en/content.sqlite
  version alltagssprache_redewendungen_batch_2_v1, schema 4, 17797120 bytes
  sha256 849d342fca6872b701742ff903e873944f7dc564cf7df034d64d443933fadfe2
  22 table counts match finalization_report.json
  INTERNES TEST-PACK: own devices and selected testers only, no public content release
Exit 0

dart run tool/stage_content_pack.dart --verify
verified assets/content/en/content.sqlite
  version alltagssprache_redewendungen_batch_2_v1, schema 4, 17797120 bytes
  sha256 849d342fca6872b701742ff903e873944f7dc564cf7df034d64d443933fadfe2
  22 table counts match finalization_report.json
  INTERNES TEST-PACK: own devices and selected testers only, no public content release
Exit 0

flutter analyze --no-pub
Analyzing sprachapp...
No issues found! (ran in 3.6s)
Exit 0

flutter test --no-pub test/data/real_pack_test.dart
00:00 +0: loading /Users/ardasayar/Documents/FlutterProjekte/sprachapp/test/data/real_pack_test.dart
00:00 +0: staged pack: all cards and sentence links readable, read-only
SCHEMA4 mixed exercises=2631 lexical=2360; 402 forms / 71 reuse / cut 3 identities PASS
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
deck alltagssprache-redewendungen: 178 learning targets, 178 ownership cards, 178 fixed sentence assignments verified
pack alltagssprache_redewendungen_batch_2_v1 (schema 4, internal: true); 12 decks: 2534 cards, 2745 card sentences, 172 with valid_alternatives, 2745 cards in the pack
01:32 +1: All tests passed!
Exit 0

pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --help
CLI includes --selection, --batch, --out, --prepare-continuation VERSION, --verify-zip
Exit 0

pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --selection pipeline/data/selection/alltagssprache_redewendungen_v2.json --batch 3 --prepare-continuation alltagssprache_redewendungen_batch_3_context_v2
{
  "snapshots": "PASS",
  "paths": {
    "selection": "pipeline/data/selection/alltagssprache_redewendungen_batch_3_context_v2.json",
    "registry": "pipeline/data/words/en.alltagssprache_redewendungen_batch_3_context_v2.json",
    "groups": "pipeline/data/learning_groups/en.alltagssprache_redewendungen_batch_3_context_v2.json"
  },
  "partition_counts": {
    "imported": 178,
    "current": 88,
    "future": 175
  }
}
Exit 0

pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --selection pipeline/data/selection/alltagssprache_redewendungen_batch_3_context_v2.json --batch 3 --out build/alltagssprache_redewendungen_authoring_batch_3.zip
status PASS; selected 441; partition 178/88/175
Exit 0

pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --verify-zip build/alltagssprache_redewendungen_authoring_batch_3.zip
{
  "zip_verification": "PASS",
  "zip_sha256": "88e4b909a64a0835763b72e60895795ddebafe601645214d83903f30db376aaf",
  "hashed_files": 83,
  "sqlite_tables": 22,
  "sqlite_cards": 2745,
  "selected": 441,
  "partition_counts": {
    "imported": 178,
    "current": 88,
    "future": 175
  }
}
Exit 0

pipeline/.venv-macos/bin/python /tmp/everyday-import-b2/final_audit.py
CLOSED ZIP PASS: CRC, 83 manifest hashes, whole 441 identities/178 imported/88 current/175 future, exclusion lineage, registry/groups/source refs; all 22 tables; SQLite byte-identical staged asset
PRESERVATION 2701 pre-existing files; changed only NEXTSTEPS.md, test/data/real_pack_test.dart, assets/content/en/content.sqlite, assets/content/en/content.manifest.json; index empty; verified backup matches pre-stage hashes
3 prior and 4 current token corrections retained; 402 forms unchanged; no Batch-3 sentences created
Exit 0
```

Arbeitslaufabweichungen: ein lokaler Vorprüfhelfer behandelte display_plan zunächst fälschlich als Liste (TypeError: string indices must be integers, Exit 1), dann als Objekt mit current-Feld (KeyError: current, Exit 1). Neue Hypothese nach Einsicht in tatsächliche Schlüssel/Originalfunktion: display_plan enthält existing/append/rows; für Create-Appendpositionen ist append maßgeblich. Dritter Audit mit diesem nachgewiesenen Feld bestanden; keine Datei/Schutzgrenze geändert und keine Schemaerweiterung. Der eigentliche CLI-Import, Export und Fortsetzungsexporter bestanden beim ersten Aufruf.

## Sechs geerbte Formglossenbefunde – weiterhin offen

Originale gemeinsame Wörterbuchzeilen mit Kontext geprüft und unverändert erhalten. Keine neuen Senses zur Umgehung einer alten Formglosse erzeugt; die echte high-Polysemie oben ist separat. Frühere Glossenlisten, einschließlich Batch 1, bleiben offene eigene Aufgaben.

| Schlüssel | Alte Glosse → Vorschlag | Kontext / Begründung |
|---|---|---|
| met\|meet/VERB\|meet#treffen | trafen → traf; trafen; kennengelernt | Die geerbte Formglosse trafen deckt Singular und Partizip bzw. Erstbegegnung nicht vollständig ab. a blessing in disguise: That cancelled trip was a blessing in disguise; I met my partner here.; go way back: Tom and I go way back; we met at primary school.; if memory serves: If memory serves, we first met at your cousin's wedding. |
| could\|could/AUX\|could#konnten | konnten → konnte; konnten | Die geerbte Pluralglosse konnten passt nicht zu I could. familiar: Her voice sounded familiar, but I could not remember her name. |
| name\|name/NOUN\|name#namen | Namen → Name | Die gebeugte Form Namen ist keine geeignete allgemeine Wortglosse. familiar: Her voice sounded familiar, but I could not remember her name. |
| home\|home/NOUN\|home#hause | Hause → Zuhause | In far from home bezeichnet das Nomen das Zuhause; Hause allein ist unvollständig. fancy seeing you here: Fancy seeing you here, so far from home!; can't complain: Can't complain: work is going well and everyone at home is healthy. |
| first\|first/ADJ\|first#ersten | ersten → erste; erster; erstes | Die geerbte Flexionsform ersten passt nicht zur isolierten Grundglosse. good for you: Good for you—that first swimming lesson took courage! |
| left\|leave/VERB\|leave#liess-liegen | ließ liegen → liegen gelassen; ließ liegen | Im Perfekt have left steht das Partizip; geerbt ist nur ließ liegen. what a bother: What a bother, I have left my keys at the office! |

Weitere geerbte Formglossen bleiben erhalten (z. B. had/mussten oder storm/Sturms); die sechs gelieferten Fälle werden nicht als vollständige Altglossenbereinigung bezeichnet. Neue Zuordnungsfehler wurden ausdrücklich getrennt korrigiert.

## Quell-/Ausgabehashes und Commitstatus

| Datei | SHA256 |
|---|---|
| `/Users/ardasayar/Downloads/alltagssprache_redewendungen_batch_2_lieferung.zip` | `e1e1e7e87fad94e6b04a6128bd0187984e88ea12016d1a4482b0fe40fbc8da61` |
| `build/alltagssprache_batch_2_checks/delivery/alltagssprache_redewendungen_batch_2/editorial_content_v2.json` | `c8aafda9fa387a62043a9b7af539ed2f99a4164151625f327ad6021c3b1c0909` |
| `build/alltagssprache_batch_2_checks/delivery/alltagssprache_redewendungen_batch_2/deck_display_patch.json` | `2cf9b5a9cbea8c562d173c3075e7250fc21a01de41f06127f538593b80a06c9f` |
| `build/alltagssprache_batch_2_checks/import_copy/alltagssprache_redewendungen_batch_2/editorial_content_v2.json` | `24a08960b714d3b70b1cde2cbfeb71b9002b237f63bfbf1fb53a0af77377413f` |
| `build/alltagssprache_batch_2_checks/import_copy/alltagssprache_redewendungen_batch_2/deck_display_patch.json` | `d18e33301a94ef24d49410bf6404c3bc4cc20366117650d1b2a1ff8a7aee10a9` |
| `pipeline/out/alltagssprache_redewendungen_batch_1_v1/pack.json` | `109fed4daf499923b41147f75352dcaf30e5b7d109bc6a1b3dbd838163fc5b5b` |
| `pipeline/out/alltagssprache_redewendungen_batch_1_v1/content.sqlite` | `f1b4269482f8f27b2152529af13343236e51a8d1148eb0121adcf30443104802` |
| `build/alltagssprache_batch_2_checks/backup/content.manifest.json` | `27f1cbfaf5e43c72d227ad9b6291038b40e808560dfcd5d02536e414e2083b56` |
| `pipeline/data/selection/alltagssprache_redewendungen_v2.json` | `27e52591e0dd98df0510204664c03467c49347151398e1caef4538887751c71d` |
| `pipeline/data/words/en.alltagssprache_redewendungen_batch_2_context_v2.json` | `d65736d8d11c47ba15a61b8be8484a43ef01d3d7827121885b8a9c39d0475612` |
| `pipeline/out/alltagssprache_redewendungen_batch_2_v1/pack.json` | `aa2ac7e95344b4741280cdefa8f38dc9272f655a26f8230f1b47c1aa6365b2fa` |
| `pipeline/out/alltagssprache_redewendungen_batch_2_v1/content.sqlite` | `849d342fca6872b701742ff903e873944f7dc564cf7df034d64d443933fadfe2` |
| `assets/content/en/content.manifest.json` | `d815d232720f9d9a2a49b64a9f77d551d55206529c741d5b0997a0c720ab95d5` |
| `pipeline/data/selection/alltagssprache_redewendungen_batch_3_context_v2.json` | `22375c2c96b501244cc9b808fc0c2d16138079cb70dda1656d8dd9aa53df7267` |
| `pipeline/data/words/en.alltagssprache_redewendungen_batch_3_context_v2.json` | `53a4898bae3d712aa24f97dd887a52168fdf6cc6c53b4d3bef51dcebe973a47d` |
| `pipeline/data/learning_groups/en.alltagssprache_redewendungen_batch_3_context_v2.json` | `beb968788a663a2928d112174483f1886136bbae937bf2d05eb35e2f2639f84f` |
| `build/alltagssprache_redewendungen_authoring_batch_3.zip` | `88e4b909a64a0835763b72e60895795ddebafe601645214d83903f30db376aaf` |

Registry-Digest des Batch-2-Inputs (kanonisch): `fc17d7c2a424ee168e4c12c875bfaad9964de29108d5c7463766e200be110ec9`. Dateibytehash separat oben. Finaler Quell-SQLitehash entspricht exakt dem App-Asset; Sicherungshashes entsprechen dem Stand vor Staging.

Abschließender Bestandsschutz über alle 2701 erfassten vorbestehenden Dateien: ausschließlich erlaubte NEXTSTEPS-/Pack-Lesetest-/Asset-/Manifeständerungen. Alte Quelle, Original-Lieferung, Auswahl v2/Entscheidungen, historische Kontexte/Registrys/Gruppen, App-Einstieg, SRS-/Synonym-/Form-/V3-/Kompatibilitätscode erhalten. Echte Lernstände nicht berührt, kein Gerätetest, kein Cloud-/Modell-/Supabase-Aufruf, keine Paketinstallation oder öffentliche Freigabe.

Kein Commit: neuer Pack und Batch-3-Kontexte benötigen vorhandene uncommittete normale Schema-4-/450-Kompatibilität und Form-V3-Basis. HEAD trägt noch Schema-3-/300-Grenzen; deren Mitaufnahme wäre fremder Umfang. NEXTSTEPS und bestehender Pack-Lesetest enthalten gemischte vorbestehende Hunks. Index leer erhalten; kein pauschales git add und kein Push. Technische Abnahme/Übergabe trotzdem abgeschlossen.

Nächste Aktion: geprüfte ZIP im Chat hochladen und 88 aktuelle Batch-3-Ziele redigieren. Altglossen, folgende Inhaltsimports sowie Geräte-/öffentliche Sprachfreigabe bleiben offen.

Geprüfte ZIP: `/Users/ardasayar/Documents/FlutterProjekte/sprachapp/build/alltagssprache_redewendungen_authoring_batch_3.zip`

## Abschließende Datei-/Whitespaceprüfung

```text
git diff --check -- NEXTSTEPS.md docs/alltagssprache-redewendungen-batch-2-import.md test/data/real_pack_test.dart pipeline/data/selection/alltagssprache_redewendungen_batch_3_context_v2.json pipeline/data/words/en.alltagssprache_redewendungen_batch_3_context_v2.json pipeline/data/learning_groups/en.alltagssprache_redewendungen_batch_3_context_v2.json
189 trailing-whitespace findings in inherited CRLF portions of the existing mixed test diff; first at test/data/real_pack_test.dart:1. Full output: whitespace-default.log.
Exit 2

git -c core.whitespace=cr-at-eol diff --check -- NEXTSTEPS.md docs/alltagssprache-redewendungen-batch-2-import.md test/data/real_pack_test.dart pipeline/data/selection/alltagssprache_redewendungen_batch_3_context_v2.json pipeline/data/words/en.alltagssprache_redewendungen_batch_3_context_v2.json pipeline/data/learning_groups/en.alltagssprache_redewendungen_batch_3_context_v2.json
Output: leer
Exit 0

DIRECT Whitespace PASS: 11 own document/context/correction files; NEXTSTEPS 25 lines
DISPLAY PATCH identity/mapping/before-hash preservation PASS
Exit 0

git status --short
Vollständige tatsächliche Ausgabe: build/alltagssprache_batch_2_checks/status-after.txt.
Vorbestehender großer gemischter Arbeitsbaum erhalten; Index leer.
Exit 0
```

Standard-Git-Befunde betreffen erhaltene CRLF-Zeilen im vorbestehenden Testdiff. Konfigurierter Check und direkter Scan bestehen; globale Altbefunde bleiben gesondert offen. Abschließender 2701-Dateien-Audit bestätigt nur NEXTSTEPS, bestehenden Pack-Lesetest, Asset und Manifest als erlaubte Änderungen unter vorher erfassten Dateien; alle historischen erfassten Quellen/Registry-/Gruppendateien und App-/V3-/Kompatibilitätscode unverändert. Keine pauschale Bereinigung.
