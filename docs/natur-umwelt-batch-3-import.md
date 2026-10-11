# Natur & Umwelt: Abschluss Batch 3

Stand: 10.10.2026. Letzte 80 Ziele mit je einem aktiven festen Satz offline importiert und intern gestagt. Alle 242/242 Originalziele abgeschlossen; Partition 242 importiert / 0 aktuell / 0 später. Kein Restbatch und keine Batch-4-ZIP. Insgesamt 2121 primäre Lernziele in acht Stapeln: 160/489/241/245/245/249/250/242. Technische Abnahme als internes Test-Pack, keine öffentliche Inhaltsfreigabe.

## Redaktionelle Prüfung

Alle 80 englisch-deutschen Satzpaare, 882 Tokenpositionen (799 Worttoken, 83 Satzzeichen), neuen Sense-Definitionen und Formglossen gegengelesen. Lesedokument und korrigiertes Annotationsdokument vollständig gegen den tatsächlichen Import abgeglichen. Satzzeichen ohne Wortbedeutung, Lemma oder Karte.

Besonders geprüft: in autumn zeitlich, alte Batch-2-Korrektur erhalten und aktuelle autumn-Karte passend. rare selten statt Gargrad, rough raue Oberfläche statt Überfahrt. refine/plant Industrieanlage, oil Erdöl, heat thermische Energie. Earth Planet gegenüber earth Bodenmaterial. canyon/winds Verb sich schlängeln gegenüber wildfire/winds Nomen Winde. power station Kraftwerk und blades Rotorblätter; leak/tank Wasserbehälter statt Kraftstofftank. carbon/take in Aufnahme und grow Pflanzenwachstum; hive/grew Zustandswechsel, crop/grown Anbau. turbine/made Bewegung bewirken, gravel/made Geräusch erzeugen, aluminium/made herstellen. snail/trail Spur statt Wanderpfad; snail/drought left Verben. at dusk/low tide Zeitangabe, by colour Sortierkriterium, for weeks Dauer. rose aufsteigen, owl/calling rufen, dark Dunkelheit. bud/had Vollverb im Simple Past gegenüber caterpillar/soot had Perfect-Hilfsverb. Verbindungen take in, knock down, at once und on the way bleiben kontextbezogen verständlich.

Zwei regionale Alternativen wörtlich eingesetzt:

- We often walk through the colourful woods in fall.
- The lightweight frame is made of aluminum rather than steel.

Im konkreten Satz ist fall dieselbe Jahreszeit wie autumn, aluminum dieselbe Metallbedeutung wie aluminium. accepted bleibt ausschließlich autumn beziehungsweise aluminium. Alternativen bleiben satzbezogen und lernstandsneutral. Besitzaliase allein erlauben keine Freigabe. Keine Vollständigkeits- oder Eindeutigkeitsgarantie.

Linter: 0 Fehler, fünf Hinweise: flower/petals 3.46, tail/wagged 3.03, harmful/wastewater 3.36, deer/antlers 2.95 und absorb/rainwater 3.00. Keine Umformulierung allein deswegen.

## Eine belegte Bindungskorrektur

Original-Lieferung bytegleich erhalten. Separate Importkopie: build/natur_batch_3_checks/reviewed_delivery/. Im Satz „The roots help prevent erosion by holding the soil in place.“ war prevent an prevent#hindern gebunden. Die vorhandene Definition lautet ausdrücklich „Bewirken, dass eine Person etwas nicht tun kann.“ Erosion ist ein Vorgang, keine Handlung einer gehinderten Person.

Genau dieser Token erhält prevent/VERB|prevent#vorgang-verhindern mit expliziter Definition „Bewirken, dass ein Ereignis oder Vorgang nicht eintritt; hier Bodenerosion.“ Ein reiner Wörterbuch-Sense und eine passende Formglosse ohne Lernkarte ergänzt; keine zusätzliche Wortbesitzposition. Die bestehende prevent-Karte und deren Sense/Definition bleiben unverändert.

Ein Review-tokens_sha256, create_sha256 im Display-Patch und alle betroffenen Kopie-Manifesthashes erneuert. Annotationsdokument und lokale Notiz angepasst. local_corrections.json enthält Token/Review vor und nach Korrektur, hinzugefügte Sense-/Formzeilen sowie alte/neue Create-Bindung. Satztext, Übersetzung, Zielkarten, Definitionen der reservierten Ziele, Gruppen, Lücken, Alternativen und Displayzeilen unverändert. Keine pauschale Altglossenbereinigung oder Zeilenendennormalisierung. Originaler und korrigierter Lieferverifier bestanden; mechanische Strukturprüfung allein beurteilt diese Bedeutungsgrenze nicht.

## Abschluss- und Bestandsschutz

Basis-JSON und SQLite rohbytegenau gegen die beauftragten Hashes und das Ausgangsasset geprüft. Registry/Gruppen kanonisch, Source-/Review-/Display-/Manifestbindungen gültig. Aktuelle Projektquellen verwendet, keine Referenzquellen zurückkopiert, keine Validatorlockerung.

Genau 80 aktuelle Karten importiert, kein neuer Stapel. Natur-Mitgliedschaften zuerst 163–242 angehängt, danach mitgelieferter hashgebundener Display-Patch auf 1–242 angewendet. Im alten Bestand ausschließlich Natur-deck_cards.position und Natur-deck_words.position geändert. Originalauswahl und Registrypositionen unverändert; keine eigene Sortierlogik.

Alle 242 Originalidentitäten, Lemma-/Sense-/Karten-IDs, Definitionen, cards.learning, Besitzer/Aliase und je ein aktiver fester Satz vollständig gegen Ursprungsauswahl und Gesamtkontext geprüft. Endanzeige entspricht jeder Originalposition. partition_selection bestätigt 242 vorhanden und keine fehlend. Die Kartendifferenz zur Basis ist exakt die letzten 80 Originalziele; neue Begleitwort-Senses bleiben Wörterbucheinträge ohne zusätzliche Lernkarten.

Alle 2156 bisherigen Karten und historischen Inhalte erhalten, einschließlich der fünf Natur-Batch-1-Korrekturen und in-autumn aus Batch 2 sowie sämtlicher früherer Tokenkorrekturen. Nur erlaubte Natur-Anzeigepositionen neu geordnet. Alle 18 SQLite-Tabellen vollständig gegen build_rows des tatsächlichen JSON-Exports verglichen: 2236 Karten, 2770 Satztexte, 2764 historische Satzverknüpfungen und 2132 Wortbesitzzeilen. Tatsächlicher Export durch die lokale Wörterbuchergänzung: 3469 Lemmas, 4946 Senses und 5807 Formzeilen. Exportstatus ok, internal_test_pack true, ai_calls 0, Kosten 0.

## Sicherung vor Staging und App-Abnahme

Bestehendes Asset und Manifest vor Staging in neuen Ordner build/natur_batch_3_checks/backup/assets/content/en/ kopiert und beide Hashes gegen die Ausgangsbaseline bestätigt. backup-proof.json enthält UTC-Zeitstempel und Hashes. Erst nach grünem SQLite-Audit und Pipeline-Tests wurde der separate Vorbereitungsschritt ausgeführt; erst nach dessen Exit 0 das interne Staging gestartet.

real_pack_test ausschließlich um einen konkreten Versionsblock für natur_umwelt_batch_3_v1 mit acht Stapeln und Zählern ergänzt. Asset-Verifikation, Achtstapel-Lesetest, 123 Pipeline-Tests plus 19 Untertests und Flutter-Analyse bestanden. Vorhandener SDK-Cache außerhalb des Repositorys verwendet; keine Projektplattformdateien geändert. Kein App-Einstieg oder echte user.db/review_log geöffnet.

## Dokumentierter Abschluss und nächster Schritt

docs/natur-umwelt-authoring.md zeigt den Abschluss 242/242 und kennzeichnet die bisherige Vorbereitung als historischen Stand. docs/content-roadmap-v1.md zählt nun acht intern gestagte Stapel und insgesamt 2121 Lernziele; exakt 14 Stapel bleiben geplant. Historische Prüfoutputs und bestehende Altbefunde bleiben erhalten.

Nächster Schritt ausschließlich: gemeinsamer technischer Plan für die drei Unregelmäßige-Verben-Stapel, vor einer Auswahl. Formbezogenes Üben desselben Lemmas, bestehende IDs/Lernstände und transparente Zählweise ohne dreifache Ausweisung als neue Wörter müssen geklärt werden. Keine Verbenauswahl, Reservierung, Schemaänderung oder neuen Verben-Sätze erstellt. Kein Restbatch oder neuer ZIP-Export nötig.

## Befehle und tatsächliche Prüfoutputs

Ab Repository-Root. PYTHON auf macOS Terminal: pipeline/.venv-macos/bin/python; Windows PowerShell: .\pipeline\.venv\Scripts\python.exe. Dart-/Flutter-/Git-Befehle identisch auf beiden Systemen. Logs und lokale Hilfsskripte: build/natur_batch_3_checks/.

```text
PYTHON natur_umwelt_batch_3/verify_natur_umwelt_batch_3.py --repo .
PYTHON build/natur_batch_3_checks/correct_delivery.py
PYTHON build/natur_batch_3_checks/reviewed_delivery/verify_natur_umwelt_batch_3.py --repo .
PYTHON pipeline/scripts/import_editorial_patch.py --source pipeline/out/natur_umwelt_batch_2_v1/pack.json --create build/natur_batch_3_checks/reviewed_delivery/natur_umwelt_batch_3.editorial.json --registry pipeline/data/words/en.natur_umwelt_batch_3_context_v1.json --display-patch build/natur_batch_3_checks/reviewed_delivery/natur_umwelt_batch_3.display.json --out pipeline/out/natur_umwelt_batch_3_v1
PYTHON build/natur_batch_3_checks/audit_export.py
PYTHON -m pytest pipeline/tests/test_editorial_import.py pipeline/tests/test_content_contract.py pipeline/tests/test_selection.py pipeline/tests/test_word_registry.py pipeline/tests/test_learning_groups.py pipeline/tests/test_authoring_context.py pipeline/tests/test_authoring_schema3.py pipeline/tests/test_authoring_continuation.py pipeline/tests/test_deck_display.py -q
PYTHON build/natur_batch_3_checks/prepare_stage.py
dart run tool/stage_content_pack.dart --from pipeline/out/natur_umwelt_batch_3_v1
dart run tool/stage_content_pack.dart --verify
flutter test test/data/real_pack_test.dart
flutter analyze
PYTHON build/natur_batch_3_checks/update_status.py
```

### verifier-corrected.log

```text
PASS source/registry/groups/manifest hashes, Schema 3, context and base SQLite
PASS hash-bound display patch: append 163..242, final display 1..242; original registry positions preserved
PASS create_content/build_rows: 2236 cards; 2121 primary goals (160/489/241/245/245/249/250/242); 18 tables
PASS 80 reserved identities, display 1..242; 2156 old IDs and all historical rows preserved
PASS 882 token positions; two reviewed regional alternatives; linter 0 errors, 5 warnings
WARNINGS [["flower", "i+1", "'petal'/'petals' Zipf 3.46 below 3.5"], ["tail", "i+1", "'wag'/'wagged' Zipf 3.03 below 3.5"], ["harmful", "i+1", "'wastewater'/'wastewater' Zipf 3.36 below 3.5"], ["deer", "i+1", "'antler'/'antlers' Zipf 2.95 below 3.5"], ["absorb", "i+1", "'rainwater'/'rainwater' Zipf 3.00 below 3.5"]]
NOT RUN: App staging, Flutter/device tests, user database access

Exit 0
```

### correction.log

```text
PASS one prevent-erosion token corrected; one dictionary sense/form, review hash, display create_sha256 and copy manifest renewed; no sentence/card/group/position changes

Exit 0
```

### import.log

```text
{
  "status": "ok",
  "internal_test_pack": true,
  "ai_calls": 0,
  "ai_cost_usd": 0,
  "sqlite_counts": {
    "languages": 1,
    "lemmas": 3469,
    "senses": 4946,
    "cards": 2236,
    "dictionary_forms": 5807,
    "decks": 8,
    "deck_cards": 2236,
    "deck_words": 2132,
    "word_aliases": 37,
    "sentences": 2770,
    "sentence_tokens": 30864,
    "card_sentences": 2764,
    "stories": 1,
    "story_sentences": 6,
    "exercises": 0,
    "grammar_rules": 0,
    "audio_assets": 0,
    "content_releases": 1
  },
  "sha256": "34b7edc0b66cf66933183d29ad505afd0bb4c67ed8570b7b3bdf0d50ffe4aee7"
}

Exit 0
```

### audit.log

```text
SQLITE_FULL_ROWS {'languages': 1, 'lemmas': 3469, 'senses': 4946, 'cards': 2236, 'dictionary_forms': 5807, 'decks': 8, 'deck_cards': 2236, 'deck_words': 2132, 'word_aliases': 37, 'sentences': 2770, 'sentence_tokens': 30864, 'card_sentences': 2764, 'stories': 1, 'story_sentences': 6, 'exercises': 0, 'grammar_rules': 0, 'audio_assets': 0, 'content_releases': 1}
PASS 242 original identities, definitions, learning groups, owners and fixed sentences; partition 242/0/0
PASS 2156 historical cards and all old content preserved, except authorized Natur display positions; all Batch-1 corrections retained
ALTERNATIVE We often walk through the colourful woods in fall.
ALTERNATIVE The lightweight frame is made of aluminum rather than steel.
PASS reviewed reading/annotation documents exactly match all 80 sentences and 882 imported token positions
DECK allgemeine-sprache 160
DECK reisen 489
DECK alltag-zuhause 241
DECK arbeit-bildung 245
DECK menschen-beziehungen 245
DECK koerper-gesundheit 249
DECK essen-trinken 250
DECK natur-umwelt 242
PACK_SHA256 7d1b7a48fc1ec3799d0216b6a89b012de1e02064e8e84b310c11815dbae77a8e
SQLITE_SHA256 34b7edc0b66cf66933183d29ad505afd0bb4c67ed8570b7b3bdf0d50ffe4aee7
PASS 242/0/0 partition; all original aliases/display positions exact; exactly 80 new cards; six earlier corrections preserved; prevent correction dictionary-only
NEW_TOKEN_COUNTS 799 word tokens 83 punctuation

Exit 0
```

### pytest.log

```text
........................................................................ [ 58%]
...................................................   [100%]
123 passed, 19 subtests passed in 1.71s

Exit 0
```

### prepare-stage.log

```text
PASS backup BEFORE staging: {"verified_before_staging_utc": "2026-10-10T13:44:27.865537+00:00", "files": {"assets/content/en/content.sqlite": "19d5831aa207d305cf71a16cc4437e3dee5ec995523aa6353c100a6c77f489e9", "assets/content/en/content.manifest.json": "3ace9567532887c1baeaa9479372276a0c152d9606fca2139f25d09656f42696"}}
PASS exact eight-deck test expectations added; existing bytes preserved

Exit 0
```

### stage.log

```text
Running build hooks...Running build hooks...staged assets/content/en/content.sqlite
  version natur_umwelt_batch_3_v1, schema 3, 15024128 bytes
  sha256 34b7edc0b66cf66933183d29ad505afd0bb4c67ed8570b7b3bdf0d50ffe4aee7
  18 table counts match finalization_report.json
  INTERNES TEST-PACK: own devices and selected testers only, no public content release

Exit 0
```

### stage-verify.log

```text
Running build hooks...Running build hooks...verified assets/content/en/content.sqlite
  version natur_umwelt_batch_3_v1, schema 3, 15024128 bytes
  sha256 34b7edc0b66cf66933183d29ad505afd0bb4c67ed8570b7b3bdf0d50ffe4aee7
  18 table counts match finalization_report.json
  INTERNES TEST-PACK: own devices and selected testers only, no public content release

Exit 0
```

### flutter-test.log

```text
00:00 +0: loading /Users/ardasayar/Documents/FlutterProjekte/sprachapp/test/data/real_pack_test.dart
00:00 +0: staged pack: all cards and sentence links readable, read-only
deck allgemeine-sprache: 160 learning targets, 160 ownership cards, 160 fixed sentence assignments verified
deck reisen: 489 learning targets, 500 ownership cards, 500 fixed sentence assignments verified
deck alltag-zuhause: 241 learning targets, 241 ownership cards, 241 fixed sentence assignments verified
deck arbeit-bildung: 245 learning targets, 245 ownership cards, 245 fixed sentence assignments verified
deck menschen-beziehungen: 245 learning targets, 245 ownership cards, 245 fixed sentence assignments verified
deck koerper-gesundheit: 249 learning targets, 249 ownership cards, 249 fixed sentence assignments verified
deck essen-trinken: 250 learning targets, 250 ownership cards, 250 fixed sentence assignments verified
deck natur-umwelt: 242 learning targets, 242 ownership cards, 242 fixed sentence assignments verified
pack natur_umwelt_batch_3_v1 (schema 3, internal: true); 8 decks: 2132 cards, 2236 card sentences, 138 with valid_alternatives, 2236 cards in the pack
00:23 +1: All tests passed!

Exit 0
```

### flutter-analyze.log

```text
Analyzing sprachapp...
No issues found! (ran in 3.7s)

Exit 0
```

## SHA256 (Rohbytes)

| Datei | SHA256 |
|---|---|
| pipeline/out/natur_umwelt_batch_2_v1/pack.json | `c936b0359a1f87a30f1ad2715552362cc34a6447a61d7685adc723fa21799932` |
| pipeline/out/natur_umwelt_batch_2_v1/content.sqlite | `19d5831aa207d305cf71a16cc4437e3dee5ec995523aa6353c100a6c77f489e9` |
| natur_umwelt_batch_3/natur_umwelt_batch_3.editorial.json | `280c8d43878375adbd79375c1b822ce4500119ff8754ff0c55552d4aab971d57` |
| natur_umwelt_batch_3/natur_umwelt_batch_3.display.json | `c5505c08fa4b6ed3e9c2e8c2dcd42955c1ea3139f1770676245361637200ed7b` |
| natur_umwelt_batch_3/manifest.json | `e15d71cd040eca2de5900985c8379487ee2b6e90fafa719f5dfbb5f47d9348b4` |
| build/natur_batch_3_checks/reviewed_delivery/natur_umwelt_batch_3.editorial.json | `2ab608315e16c9f9d863d1431a83941586fdf2f0030fcd771e33149003fc630e` |
| build/natur_batch_3_checks/reviewed_delivery/natur_umwelt_batch_3.display.json | `458678e424a25529b25a387102623de29c9c3bcdfcd73c885adec68dbea6f563` |
| build/natur_batch_3_checks/reviewed_delivery/manifest.json | `bd85bcfa93d2e73aa95ab066e0aab6bb1b97eee5bfac213ad186a6895be29a0e` |
| pipeline/out/natur_umwelt_batch_3_v1/pack.json | `7d1b7a48fc1ec3799d0216b6a89b012de1e02064e8e84b310c11815dbae77a8e` |
| pipeline/out/natur_umwelt_batch_3_v1/content.sqlite | `34b7edc0b66cf66933183d29ad505afd0bb4c67ed8570b7b3bdf0d50ffe4aee7` |
| assets/content/en/content.sqlite | `34b7edc0b66cf66933183d29ad505afd0bb4c67ed8570b7b3bdf0d50ffe4aee7` |
| assets/content/en/content.manifest.json | `e316e78d1a4bb35347d703a618577d08476c929f8ace1d00f0c3f1ac260adc3b` |
| pipeline/data/selection/natur_umwelt_v1.json | `344f4b562855584acf8c3290ff2c8b5c7f4a6b400b937cd7f166cd0671ee0c21` |
| pipeline/data/selection/natur_umwelt_batch_3_context_v1.json | `d5ae9b2909fa27a17306842bc70a52cb324663ed5ff450d69c32ae5d119d6058` |
| pipeline/data/words/en.natur_umwelt_batch_3_context_v1.json | `64917e02425a5f06ad80394722da175ca5ab0db573e0fb7dda86736a5e46e318` |
| pipeline/data/learning_groups/en.natur_umwelt_batch_3_context_v1.json | `ed3edcc49fbd6b69f962fee4fc5edb77271cdf593e0bdd1fc231956cbdff9177` |

## Arbeitsbaum und Grenzen

Baseline mit 2749 Dateien. Sechs beauftragte Bestandsdateien dürfen sich ändern: Assets/Manifest, test/data/real_pack_test.dart, docs/natur-umwelt-authoring.md, docs/content-roadmap-v1.md und NEXTSTEPS.md. Neu: Pack und dieser Bericht. Original-Lieferung, historische Packs, Originalauswahl, alte Registrys/Gruppen und alte ZIP bleiben bytegleich. Schlussnachweise unter final-protection.json, final-checks.log und Git-Status vorher/nachher.

Gezielte git diff --check-Prüfung, zusätzlicher CRLF-toleranter Check und eigene Änderungen separat gegen Ausgangskopien; neuer unversionierter Bericht gegen /dev/null. Keine riesige repositoryweite Diff-Ausgabe. Bekannte sieben Altstellen erhalten: DESIGN.md:162–164, docs/alltag-zuhause-continuation.md:148/153, docs/arbeit-bildung-batch-1-import.md:127 und docs/arbeit-bildung-batch-2-import.md:121. Keine globale Bereinigung.

Keine echte user.db/review_log oder Lernstände verändert; keine App-/SRS-/Synonym-/Modell-/Budget-/Supabase-/Plattformänderung, Cloud-/Modellaufrufe, Veröffentlichung, Commits oder Pushes. Keine Geräteprüfung oder unabhängige menschliche Sprachfreigabe behauptet. Bekannte Altbefunde, Geräteprüfung und öffentliche Inhaltsfreigabe bleiben getrennte Aufgaben. Natur-Authoring vollständig abgeschlossen; keine ungeklärte Inhaltsbindung des aktuellen Imports.

## Abschließender Nachweis

```text
BASELINE 2749 UNCHANGED 2743 CHANGED ['NEXTSTEPS.md', 'assets/content/en/content.manifest.json', 'assets/content/en/content.sqlite', 'docs/content-roadmap-v1.md', 'docs/natur-umwelt-authoring.md', 'test/data/real_pack_test.dart']
git-diff-check-targeted Exit 2 output bytes 20337
git-diff-check-targeted-crlf Exit 0 output bytes 0
PASS new untracked files, NEXTSTEPS and exact test change separately checked; own whitespace Exit 0
git status --short Exit 0; saved to git-status-after.txt
PASS all historical selections/registries/groups, historical packs/deliveries and app/pipeline code unchanged; only authorized assets/manifest/test and completion documents changed; no repository-wide diff generated

Exit 0
```

2743 von 2749 Ausgangsdateien bytegleich; genau die sechs beauftragten Bestandsdateien geändert. Normaler gezielter Diff-Check Exit 2 wegen erhaltener CRLF-Konvention in NEXTSTEPS/Test; CRLF-tolerant keine Befunde. Neue unversionierte Texte und eigene Dokument-/Teständerungen separat gegen Ausgangskopien ohne Whitespace-Diagnostik geprüft. NEXTSTEPS: 25 Zeilen.
