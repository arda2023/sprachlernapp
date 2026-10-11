# Alltagssprache & Redewendungen – Auswahl v2 und geprüfte Batch-2-ZIP

Stand: 11.10.2026. **441 aktive Auswahlziele; Batches 89/89/88/88/87. Batch-2-Partition 89 importiert / 89 aktuell / 263 später.** Ein genehmigtes zukünftiges Doppelziel ausgeschlossen, keine Ersatzvokabel. Batch-2-ZIP geschlossen, wieder geöffnet und vollständig geprüft. Kein Import, kein Staging, keine neuen Sätze.

## Tatsächliche Basis und vorheriger Fehler

Ausgangslage lesend bestätigt: `alltagssprache_redewendungen_batch_1_v1`, Schema 4, zwölf Stapel, 2656 Karten und 89 bereits importierte Alltagssprache-Ziele. Aktuelle produktive Projektion: **2542 Übungen / 2271 lexikalische Wörter**, 402 Verbenform-Mitgliedschaften, je 134 Übungen. Quell-SQLite und gestagtes Asset bytegleich; drei Begleitwortkorrekturen des Batch-1-Imports erhalten. Der unveränderte aktuelle Pack ist alleinige Fortsetzungsbasis, keine ältere Lieferung oder Ersatzbasis.

Der vorherige tatsächliche Fehler aus `build/alltagssprache_batch_1_checks/continuation.log`:

```text
prepare_continuation -> validate_context
require(e['form_norm'] not in existing_forms | alternatives, 'already offered word')
ValueError: authoring: already offered word
Exit 1 (vorheriger Importauftrag)
```

Keine Wiederholung dieses bekannten Fehlversuchs nötig. Gelesen: AGENTS/CLAUDE/NEXTSTEPS, Roadmap, Authoring-/Import-/Schema-4-Kompatibilitätsberichte, Content-/Lerngruppenverträge und vorhandene Auswahl-/Registry-/Gruppendateien. Verwendet: `ids.form_norm`, `word_registry.index_registry/validate_selection`, `selection.partition_selection`, `pack.build_rows`, `learning_groups.validate_learning`, `authoring_context.prepare_continuation/validate_context`, normaler CLI-Exporter und `finalize_curation.check_sqlite`. Importvertrag nur gelesen; keine Schema-/Codeänderung.

Vorheraufnahme über 2667 Dateien; Gitstatus in `build/alltagssprache_selection_v2_checks/status-before.txt`, Index leer. Fremde uncommittete V3-/Kompatibilitäts-/Dokumentanteile unverändert erhalten.

## Vollständiger Konfliktdurchgang und Entscheidung

Alle **353 noch nicht importierten ursprünglichen Ziele** gegen sämtliche aktiven Kartenoberflächen, Sense-/Karten-/Gruppenidentitäten, bestätigten aktiven Satzalternativen, Wortbesitzer/Aliase und alle 402 Formziele/406 lexikalischen Zuordnungen geprüft. Normalisierung ausschließlich mit vorhandenem `form_norm` (NFC, Kleinschreibung, Apostroph); keine Gleichsetzung allein nach deutscher Glosse und keine neue globale Synonymieentscheidung.

Vollständiger Einzelprüfnachweis mit allen 353 Zielidentitäten, Batch/Originalposition, Definition, Besitzerreservierung sowie jedem Alternativ-/Karten-/Gruppen-/Form-/Lexikaltreffer: `pipeline/data/selection/alltagssprache_redewendungen_v2_decisions.json`, `all_open_target_checks`. Zusätzlich alle acht neuen Alternativen gegen die vollständige **442er-Ursprungsauswahl** in `batch_1_eight_alternatives_against_all_442`. Die Entscheidungsdatei ist ein separates Prüfprotokoll, keine neue Importschnittstelle.

**Genau ein Konflikttreffer**, semantisch anhand beider Definitionen und des tatsächlichen Satzes bestätigt:

| Feld | Wert |
|---|---|
| Ausgeschlossenes Ziel | alltagssprache-v1-0377 |
| Originalposition / Batch | 377 / 5 |
| Form | in my opinion |
| Kartenreferenz | in my opinion\|in my opinion/ADV\|in-my-opinion#meiner-meinung-nach |
| Karten-ID | 394f40fe4c8b44dde3e746bb43b8359f |
| Sense-Referenz / ID | in my opinion/ADV\|in-my-opinion#meiner-meinung-nach / 42a7aab91bf8eabf9355dfd8807dc642 |
| Zieldefinition | Kennzeichnung einer folgenden Aussage als persönliche Einschätzung. |
| Erhaltene Karte | to my mind\|to my mind/ADV\|to-my-mind#nach-meinem-dafurhalten |
| Karten-ID | d7ce8f43b508b8ecf00251660bac9db4 |
| Sense-Definition | Kennzeichnung einer Aussage als eigenes Urteil. |
| Fester Satz / ID | alltagssprache-v1-0020-s1 / 44d8dc4a3e83819a07cfd6f376c2ad62 |
| Satz | To my mind, this plan is much too risky. |
| Deutsche Übersetzung | Meiner Meinung nach ist dieser Plan viel zu riskant. |
| Gespeicherte Alternative | in my opinion |
| Tatsächliche Ersetzung | in my opinion, this plan is much too risky. |

Entscheidung: genehmigtes noch nicht importiertes Batch-5-Doppelziel entfernen; bestätigte lernstandsneutrale Alternative im bestehenden Satz bleibt unverändert. Die Definitionen bezeichnen hier dieselbe persönliche Einschätzung. Dies beweist keine allgemeine Austauschbarkeit in allen Kontexten.

| Batch-1-Alternative | Treffer in allen 442 ursprünglichen Identitäten | Entscheidung |
|---|---|---|
| nonetheless | kein Treffer | Alternative unverändert erhalten; kein Auswahlziel betroffen. |
| a breeze | kein Treffer | Alternative unverändert erhalten; kein Auswahlziel betroffen. |
| in my opinion | alltagssprache-v1-0377 (Batch 5) | Zukünftiges Doppelziel ausgeschlossen; Alternative erhalten. |
| on second thought | kein Treffer | Alternative unverändert erhalten; kein Auswahlziel betroffen. |
| occasionally | kein Treffer | Alternative unverändert erhalten; kein Auswahlziel betroffen. |
| verbatim | kein Treffer | Alternative unverändert erhalten; kein Auswahlziel betroffen. |
| cry over spilled milk | kein Treffer | Alternative unverändert erhalten; kein Auswahlziel betroffen. |
| honestly | kein Treffer | Alternative unverändert erhalten; kein Auswahlziel betroffen. |

Alle anderen offenen Ziele: keine Alternativ-/aktiven Karten-/Gruppen-/Formkonflikte; Besitzerprüfung ergibt jeweils die eigene exakte historische Reservierung, keinen konkurrierenden Besitzer oder Alias. Es gab keinen unklaren oder andersbedeutenden Oberflächentreffer, der eine weitere Vertragsentscheidung verlangt. Zusätzlich prüft der vorhandene Gesamtkontextvalidator sämtliche verbliebenen Definitionen/Sense-Verwendungen, Gruppenreferenzen und Besitzer, nicht nur Batch 2. Kein weiterer Ausschluss.

## Versionierung und historische Reservierung

Neue Auswahl `pipeline/data/selection/alltagssprache_redewendungen_v2.json`: vorhandene Felder `version`/`selection_id` aktualisiert, exakt Ziel 0377 aus `entries` und `editorial_candidates` entfernt, vorhandenes `excluded` um einen begründeten Eintrag ergänzt (81 statt 80 Ausschlüsse). Alle übrigen 441 Einträge mit Identitäten, Bedeutungsdefinitionen, learning, Originalpositionen und Batch-Zugehörigkeit exakt beibehalten. Originalposition 377 bleibt frei; keine Neuverteilung und keine Neunummerierung.

Der vorhandene Ausschlussgrund trägt Vorgängerpfad/-SHA256, ausgeschlossene Identität/Karten-ID/Position/Batch sowie erhaltene Karte und Satzreferenz. Diese Angaben stehen durch `selection.json` und `original_selection.json` in der ZIP. Separate Entscheidungsliste enthält zusätzlich vollständige ausgeschlossene Identität, Quellhashes und Treffertexte. Keine zusätzlichen Felder in Auswahl-/Import-/Kontextvertrag eingeführt.

Auswahl v1 und sämtliche Batch-1-Kontexte bleiben bytegleich. Die v2-Auswahl ist die neue unveränderte Originalauswahl der Fortsetzung. Ihre historischen Quell-/Reservierungsverweise werden bewahrt; erst `prepare_continuation` bindet den aktuellen Pack und die tatsächliche SQLite. Kein falscher initialer Neu-Reservierungsdelta behauptet.

Der gestagte Registry-Snapshot hat weiterhin **2798 Reservierungszeilen**. Auch die alte ungenutzte Reservierung von in my opinion bleibt mit alter Besitzer-/Karten-ID und Position erhalten, wie der Importschutz verlangt. **Historische Reservierung ist keine aktive Lernkarte:** für das ausgeschlossene Ziel gibt es keine Packkarte, keinen neuen Lernkopf, keinen aktiven Auswahleintrag, keinen geplanten Gruppeneintrag und keinen Satzauftrag. Alte Gruppen-Snapshots werden als historische Vorgänger erhalten, nicht als neue geplante Lernziele ausgegeben. Keine Alternative als neuer Besitzeralias eingetragen. Normalisierung/Antwort-/Gruppen-/Formlogik unverändert.

## Tatsächlich verwendete neue Pfade

Vor Schreiben genannt, vorher auf Nichtvorhandensein geprüft, keine vorhandene abweichende Datei ersetzt:

- `pipeline/data/selection/alltagssprache_redewendungen_v2.json`
- `pipeline/data/selection/alltagssprache_redewendungen_v2_decisions.json`
- `pipeline/data/selection/alltagssprache_redewendungen_batch_2_context_v2.json`
- `pipeline/data/words/en.alltagssprache_redewendungen_batch_2_context_v2.json`
- `pipeline/data/learning_groups/en.alltagssprache_redewendungen_batch_2_context_v2.json`
- Dieser Bericht `docs/alltagssprache-redewendungen-selection-v2.md`; NEXTSTEPS.md aktualisiert.
- ZIP `build/alltagssprache_redewendungen_authoring_batch_2.zip`; Protokolle `build/alltagssprache_selection_v2_checks/`.

Der normale Fortsetzungsvertrag erzeugt 2656 bestehende Karten-/Gruppenentscheidungen und 352 noch nicht importierte geplante Köpfe. Nur 89 Batch-2-Ziele erhalten einen aktuellen Satzauftrag; 263 bleiben später. Lückenlose Anzeige- und Append-Positionen stammen vom vorhandenen `continuation_display_mapping.json`/Displayplan und bleiben getrennt von Original-/Besitzpositionen.

## Prüfläufe, tatsächlicher Output und Exitcodes

Ausgeführt auf macOS ab Repository-Root. Windows PowerShell: dieselben Python-Argumente mit `.\pipeline\.venv\Scripts\python.exe` statt `pipeline/.venv-macos/bin/python`; Dart-/Git-Befehle identisch. Temporäre Audits unter `/tmp/everyday-selection-v2/` lesen/prüfen mit den bestehenden Funktionen, keine zweite Importlogik.

```text
dart run tool/stage_content_pack.dart --verify
verified assets/content/en/content.sqlite
  version alltagssprache_redewendungen_batch_1_v1, schema 4, 17309696 bytes
  sha256 f1b4269482f8f27b2152529af13343236e51a8d1148eb0121adcf30443104802
  22 table counts match finalization_report.json
  INTERNES TEST-PACK: own devices and selected testers only, no public content release
Exit 0

pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --help
CLI enthält --selection, --out, --batch, --verify-zip und --prepare-continuation VERSION.
Exit 0

pipeline/.venv-macos/bin/python /tmp/everyday-selection-v2/prepare.py
FULL AUDIT: 353 open targets vs active cards/senses/IDs/groups, ownership/aliases and all 402 form targets/406 lexical mappings; exactly 1 semantic duplicate
BATCH-1 ALTERNATIVES: all 8 vs all 442 identities; only in my opinion matches (target 0377, batch 5, original position 377)
Existing continuation validation PASS before publication: 441 identities; batches 89/89/88/88/87; partition 89/89/263
Historical reservation retained among 2798 words; excluded target absent from active selection/planned groups/requests; original identity positions retained
Exit 0

pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --selection pipeline/data/selection/alltagssprache_redewendungen_v2.json --batch 2 --prepare-continuation alltagssprache_redewendungen_batch_2_context_v2
{
  "snapshots": "PASS",
  "paths": {
    "selection": "pipeline/data/selection/alltagssprache_redewendungen_batch_2_context_v2.json",
    "registry": "pipeline/data/words/en.alltagssprache_redewendungen_batch_2_context_v2.json",
    "groups": "pipeline/data/learning_groups/en.alltagssprache_redewendungen_batch_2_context_v2.json"
  },
  "partition_counts": {
    "imported": 89,
    "current": 89,
    "future": 263
  }
}
Exit 0

pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --selection pipeline/data/selection/alltagssprache_redewendungen_batch_2_context_v2.json --batch 2 --out build/alltagssprache_redewendungen_authoring_batch_2.zip
status: PASS; selected: 441; excluded: 81; partition_counts: imported 89 / current 89 / future 263
Exit 0

pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --verify-zip build/alltagssprache_redewendungen_authoring_batch_2.zip
{
  "zip_verification": "PASS",
  "zip_sha256": "c3c5988f5f1b00a9dc9307dfee42e33f8e3876f56bbebc7fc6c99b4ca03ca088",
  "hashed_files": 83,
  "sqlite_tables": 22,
  "sqlite_cards": 2656,
  "status": "PASS",
  "selected": 441,
  "excluded": 81,
  "partition_counts": {
    "imported": 89,
    "current": 89,
    "future": 263
  }
}
Exit 0

pipeline/.venv-macos/bin/python -m pytest pipeline/tests/test_selection.py pipeline/tests/test_word_registry.py pipeline/tests/test_authoring_context.py pipeline/tests/test_authoring_continuation.py pipeline/tests/test_normal_schema4_authoring.py pipeline/tests/test_learning_groups.py -q
70 passed in 5.86s
Exit 0

dart run tool/report_learning_groups.dart pipeline/out/alltagssprache_redewendungen_batch_1_v1/content.sqlite
mixed: raw_words=2623; learning_targets=2542; lexical_words=2271; form_memberships=402
Exit 0

pipeline/.venv-macos/bin/python /tmp/everyday-selection-v2/final_audit.py
ZIP CRC/full manifest/441 exact identities/89 current/89 imported/263 future/exclusion lineage PASS; SQLite byte-identical staged asset; source 22 tables PASS
Imported 89 fixed sentences/8 alternatives/3 prior token corrections and four form tables retained; no new sentences or staging
PRESERVATION 2667 pre-existing files; changed only NEXTSTEPS.md; production/source/asset/manifest/historical contexts/App/SRS/V3/compatibility unchanged; index empty
Exit 0
```

ZIP geschlossen und erneut geöffnet, CRCs und **83 vollständige Manifest-Dateihashes** verifiziert. Quell-JSON und SQLite entsprechen exakt den aktuellen Dateien. Alle 22 Quelltabellen vollständig zeilen-/spaltenweise mit `build_rows` verglichen, Referenzen, Gruppen/Registry und sämtliche 441 Identitäten exakt gegen v2. Die disjunkte Gesamtpartition wurde geprüft, einschließlich aller späteren Ziele und des expliziten Ausschlussnachweises. Kein Batch-2-/Folgesatz erstellt. Drei frühere Begleitwortkorrekturen (hear about zweimal, work beim Plan) konkret im neuen ZIP-Pack bestätigt; sämtliche 89 bisherigen Satzpaare/Alternativen und vier Formtabellen unverändert durch Quellbytebindung.

## Quell- und Ergebnishashes

| Datei | SHA256 |
|---|---|
| `pipeline/out/alltagssprache_redewendungen_batch_1_v1/pack.json` | `109fed4daf499923b41147f75352dcaf30e5b7d109bc6a1b3dbd838163fc5b5b` |
| `pipeline/out/alltagssprache_redewendungen_batch_1_v1/content.sqlite` | `f1b4269482f8f27b2152529af13343236e51a8d1148eb0121adcf30443104802` |
| `assets/content/en/content.sqlite` | `f1b4269482f8f27b2152529af13343236e51a8d1148eb0121adcf30443104802` |
| `assets/content/en/content.manifest.json` | `27f1cbfaf5e43c72d227ad9b6291038b40e808560dfcd5d02536e414e2083b56` |
| `pipeline/data/selection/alltagssprache_redewendungen_v1.json` | `fef6e572248adff37e2ec6996f84244212fb078a22933526ad5a694ca91be349` |
| `pipeline/data/selection/alltagssprache_redewendungen_batch_1_context_v1.json` | `12779941a0cd3aad7954652f75d293a315a7ca69c71d56839730790413c4b416` |
| `pipeline/data/words/en.alltagssprache_redewendungen_batch_1_context_v1.json` | `51d19fc324afed93c74dc8a4918797977bc35da797f78b8816a7da0d6da6cc1b` |
| `pipeline/data/learning_groups/en.alltagssprache_redewendungen_batch_1_context_v1.json` | `bf2cf6ac5e6403615043fe5f84dc0e418f367c06d9e733feac3e1a4e81156f25` |
| `pipeline/data/selection/alltagssprache_redewendungen_v2.json` | `27e52591e0dd98df0510204664c03467c49347151398e1caef4538887751c71d` |
| `pipeline/data/selection/alltagssprache_redewendungen_v2_decisions.json` | `7262ed2acaca30458d005edff6940abf2cf4111a4f39277bebd9064f4bf177cb` |
| `pipeline/data/selection/alltagssprache_redewendungen_batch_2_context_v2.json` | `e660adea60ad0aabe4c3c74175f32c684c815f989f8dd76d2861bba93e5662d9` |
| `pipeline/data/words/en.alltagssprache_redewendungen_batch_2_context_v2.json` | `d65736d8d11c47ba15a61b8be8484a43ef01d3d7827121885b8a9c39d0475612` |
| `pipeline/data/learning_groups/en.alltagssprache_redewendungen_batch_2_context_v2.json` | `b5ed69f515ba6a0a79bac29dcb58830b1e9d8c81d6e72b97ce2e51c9c93b3098` |
| `build/alltagssprache_redewendungen_authoring_batch_2.zip` | `c3c5988f5f1b00a9dc9307dfee42e33f8e3876f56bbebc7fc6c99b4ca03ca088` |

Vorgänger- und aktuelle Sourcehashes stehen zusätzlich in der Entscheidungsliste; v2 ist kanonisch im Fortsetzungssnapshot gebunden. Registry-Dateibytehash und kanonischer Digest getrennt; keine Verwechslung der Hasharten.

## Bestandsschutz, Commit und offene Punkte

Vorher-/Nachheraudit über 2667 vorbestehende Dateien: einzig NEXTSTEPS.md erlaubt verändert. Aktueller Produktionspack, Quell-SQLite, App-Asset/Manifest, v1-Auswahl und historische Batch-1-Kontexte/Registry/Gruppen sowie fremde Code-/Dokumentänderungen bleiben hashgleich. Keine echte user.db geöffnet oder verändert. Keine Modell-/Cloud-/Supabase-Aufrufe, Paketinstallation, Sätze, Import/Staging oder neue Kategorie. Keine Flutter-Volltests für diese reine Auswahlkorrektur.

Kein Commit: die neuen 441er-Schema-4-Kontexte hängen von der vorbestehenden uncommitteten normalen Schema-4-/450-Kompatibilität in Importer, Authoring-Validator und ZIP-Exporter sowie uncommitteter Formbasis/v1-Auswahl ab. HEAD unterstützt diese Auswahl nicht eigenständig (noch Schema-3-/300-Grenze); deren Mitaufnahme wäre ausdrücklich fremder Umfang. NEXTSTEPS enthält gemischte vorbestehende Änderungen. Index leer erhalten, kein pauschales Staging/Push.

Offen: Chat-Satzredaktion der 89 aktuellen Batch-2-Ziele, späterer geprüfter Import, weitere Batches 3–5 sowie bestehende Altglossen-/öffentliche Freigabefragen. Die aktuelle Korrektur und Übergabe sind technisch abgenommen; keine unabhängige Sprachfreigabe daraus abgeleitet.

Geprüfte lokale ZIP:
`/Users/ardasayar/Documents/FlutterProjekte/sprachapp/build/alltagssprache_redewendungen_authoring_batch_2.zip`

## Abschließende Git-/Whitespaceprüfung

```text
git diff --check -- NEXTSTEPS.md docs/alltagssprache-redewendungen-selection-v2.md pipeline/data/selection/alltagssprache_redewendungen_v2.json pipeline/data/selection/alltagssprache_redewendungen_v2_decisions.json pipeline/data/selection/alltagssprache_redewendungen_batch_2_context_v2.json pipeline/data/words/en.alltagssprache_redewendungen_batch_2_context_v2.json pipeline/data/learning_groups/en.alltagssprache_redewendungen_batch_2_context_v2.json
Output: leer
Exit 0

git -c core.whitespace=cr-at-eol diff --check -- NEXTSTEPS.md docs/alltagssprache-redewendungen-selection-v2.md pipeline/data/selection/alltagssprache_redewendungen_v2.json pipeline/data/selection/alltagssprache_redewendungen_v2_decisions.json pipeline/data/selection/alltagssprache_redewendungen_batch_2_context_v2.json pipeline/data/words/en.alltagssprache_redewendungen_batch_2_context_v2.json pipeline/data/learning_groups/en.alltagssprache_redewendungen_batch_2_context_v2.json
Output: leer
Exit 0

Direct whitespace scan PASS: 7 own JSON/Markdown files; NEXTSTEPS 25 lines
Exit 0

git status --short
Komplette tatsächliche Ausgabe: build/alltagssprache_selection_v2_checks/status-after.txt.
Vorbestehender gemischter Arbeitsbaum erhalten; Index leer.
Exit 0
```

Bekannte repositoryweite CRLF-/Whitespace-Altbefunde bleiben unangetastet; die gezielten Checks dieses Inkrements sind bestanden. Keine pauschale Bereinigung oder vollständige Repository-Diffprüfung behauptet.
