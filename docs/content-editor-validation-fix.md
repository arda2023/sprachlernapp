# Inhaltseditor – Prüfblockade bei Einzelkorrektur · 18.10.2026

Fall: Entwurf `00df73b5-fb6f-4b63-a5e7-53fc56f8ed0c` „Alltagssprache & Redewendungen“, 441 Ziele, R6,
Suche `chitchat`. Gewünscht: Satzübersetzung von „We enjoyed some friendly chitchat while we waited for the bus.“
→ „Wir unterhielten uns nett, während wir auf den Bus warteten.“ Nach **Technisch prüfen**: blockiert,
30× `sentence_count` „Genau ein Übungssatz ist erforderlich“ und 9× Zipf-Befunde an anderen Aufgaben.

## Sicherung und Arbeitskopie

Der Editordienst des Nutzers lief währenddessen (PID 10799); er wurde nicht beendet. Der Store schreibt
atomar (unveränderliche Revisionen, `current.json` per Rename). Die Sicherung wurde dreifach gehasht
(vorher, nachher, Kopie), 23 Dateien identisch, schreibgeschützt unter
`/tmp/sprachapp-editor-validation/backup-20261018T104921/`. Alle Schreibvorgänge erfolgten auf
`/tmp/sprachapp-editor-validation/work/` mit einer zweiten Dienstinstanz (`--data-dir`, `--test-assets`).
Abschließender Hashvergleich: echter Editorbestand unverändert; Asset-SHA256 weiterhin
`b85793932825a22e92ac744a42255e9f333acd35809aaba46edb5a395f099bdb`.

## Basis, Entwurf, Änderung

Basis `story_single_sentence_v1`, kanonisch `fd3ce96b…932fb` = Bindung des Entwurfs. Echte Inhaltsänderungen in R6:

| Operation | Ziel | Wirkung |
|---|---|---|
| `revise_context` | `chitchat\|chitchat/NOUN\|chitchat#geplauder` | gleicher Text, gleiche Lücke [25,33), gleiche 12 Token-Bindungen; nur `translation_de` „Wir plauderten nett miteinander, …“ → „Wir unterhielten uns nett, …“ |
| `set_solution_hint` | dieselbe Karte | „Geplauder“ = Basiswert, inhaltlich wirkungslos |

`target_refs` enthält alle 441 Stapelziele: Das ist der Entwurfsumfang (`new_draft(deck_ref)`), keine Änderungsliste.

## Herkunft der Blocker (reproduziert)

`/tmp/sprachapp-editor-validation/repro.py`, echter `validate_draft` auf der Kopie (`evidence/…/repro-before.txt`):

- R6: `invalid`, 30 `sentence_count`/error, 9 `i+1`/warn – identisch zum gespeicherten Bericht.
- Dieselbe Auswahl **ohne** Operationen: exakt dieselben 39 Befunde. JSON-Roundtrip identisch. chitchat: 0 Befunde.
  → Die Befunde stammen weder aus der Änderung noch aus Kopieren/Serialisieren.
- `validate_draft` prüft jede Karte in `target_refs` sprachlich (`target_findings`). Das deckt den ganzen Stapel ab.

| Typ | Regel/Quelle | Bewertung |
|---|---|---|
| `i+1` (reopen 3.42, unfairly 3.36, unfriendly 3.10 …) | `linter.lint_sentence`, Level `warn`; `docs/pipeline.md`: „i+1 ist eine reine Warnung“ | Korrekt **nicht blockierend**: `technical` zählte nur `error`. Die Oberfläche zeigte Warnungen aber ununterscheidbar unter „Prüfbericht“ wie Blocker. |
| `sentence_count` (30 Karten) | `LanguageProfile.validate_sentence`: spaCy-`sents == 1` | **Fehlerhafte Regel für Stapelkontexte.** Alle 30 haben genau **einen** aktiven Link, `qa_status=editorial_reviewed`, bewusst zweiteilige Minidialoge („Why not? A walk sounds lovely.“, „The kitchen is clean. Let's keep it that way.“). Bestand: 40 von 3.767 aktiven Kontexten so. |

Vertragslage: `content_contract.sentence_count` = Anzahl aktiver Übungskontexte je Karte (1).
`docs/pipeline.md:7`: „genau einen aktiven Satz je Karte“, `:223`: Linter höchstens 14 Wörter / 1 Nebensatz.
PRODUCT „Ein-Satz-Stapel“ = ein fester Kontext statt früher drei. Die grammatische Ein-Satz-Pflicht gilt nur
der Story-Policy v2 (`docs/content-editor-contract.md` Storypolicy; `curate.py:829`;
`context_revisions.revise_story_context` nutzt dieselbe Profilfunktion).

Antworten auf die Prüffragen:
- Warnungen als Fehler? Im Status nein. In der Anzeige ja: keine Trennung, Aufgabenstatus siehe unten.
- Fester Kontext ≠ grammatischer Satz? **Ja, verwechselt** (Ursache der 30 Fehler).
- Historische/inaktive Links mitgezählt? Nein. `target_view` nimmt den aktiven Link; alle 30 haben genau einen.
- Erst beim Kopieren/Serialisieren? Nein (siehe Reproduktion).
- Aufgabenstatus: `catalog` setzte `edited = ref in target_refs` und gab allen 441 den **entwurfsweiten** Status.
  Dadurch erschien chitchat ohne eigenen Befund als „Blockiert“.
- Bestätigung: `service.review` schrieb `record_refs = target_refs` (441). `editorial_reviews.json` im Bundle hätte
  damit 440 unveränderte Ziele als lokal neu sprachgeprüft ausgewiesen.

## Fix (kleinster belegter Eingriff)

| Datei | Änderung |
|---|---|
| `pipeline/src/sprachpipe/language_profiles.py` | `validate_sentence(..., single_sentence=True)`. Story bleibt beim Default (unverändert streng). |
| `pipeline/src/sprachpipe/authoring_service.py` | `target_findings` übergibt für Stapelziele `single_sentence=False`; neuer `changed_refs(draft)` (Operations-Ziele + hinzugefügte Karten); Prüfbericht enthält `changed_refs`. |
| `pipeline/src/sprachpipe/editor/service.py` | Aufgabenstatus aus **eigenen** Befunden (`invalid` nur bei eigenem Fehler; unverändert = `Bestand`, Hinweisanzahl separat). Review `record_refs = changed_refs`. |
| `pipeline/src/sprachpipe/editor/web/app.js`, `style.css` | Prüfbericht: „Technische Fehler · blockieren Prüfung und Export“ und „Hinweise · blockieren nicht“. Jede Zeile nennt „In diesem Entwurf geänderte Aufgabe“ / „Unveränderte Aufgabe aus dem Bestand · nicht Teil dieser Änderung“ / „Gesamter Entwurf“. Bestätigungsdialog listet nur die geänderten Datensätze und sagt ausdrücklich, dass die übrigen nicht neu freigegeben werden. |

Unverändert erhalten:
- Alle Lintfehler (Länge, Nebensätze, Satzende, Lücke, Wiederholung).
- `build_rows`, Historien-, Registry- und Inventarprüfung über den gesamten Entwurf.
- Prüfung **aller** Ziele im Entwurfsumfang. Es gibt keine Altbestandsausnahme: Ein echter Fehler an einer unveränderten Aufgabe blockiert weiter, wird aber dieser Aufgabe zugeordnet.
- Release-/Serververtrag: Warnungen erlaubt, Fehler verboten, Review über `payload_sha256`.

Nach dem Fix auf der Kopie (`repro-after.txt`): R6 `valid`, nur 9 `i+1`-Hinweise, chitchat befundfrei.

## Nachweis Einzelkorrektur auf der Kopie (echter Browser)

Ablauf im In-App-Browser gegen die Kopie: R6 (vom Nutzer gespeichert) → **Technisch prüfen** → R7 `Gültig`,
9 Hinweise an unveränderten Aufgaben ([Bild](evidence/content-editor-validation-fix/report-after-fix.png))
→ **Redaktionell bestätigen**: Dialog listet nur chitchat, „440 weitere … nicht neu sprachlich freigegeben“
([Bild](evidence/content-editor-validation-fix/review-scope.png)). Prüfperson ausdrücklich „Testlauf auf Kopie“.
→ **Exportieren → Neue lokale Releaseversion** `chitchat-copy-test-2026-10-18`: Job `succeeded`, Status `verified`
(SQLite-Readback, Dart-Reader Basis/Kandidat, Historienvergleich).

Zeilenvergleich Basis ↔ Release-`pack.json` (`evidence/…/bundle-diff.txt`):

| Tabelle | Ergebnis |
|---|---|
| `cards` | unverändert: keine Änderung, Karten-ID `24aafe51…` erhalten |
| `sentences` | +1 Revision `b7b51ca2…`: gleicher Text, neue `translation_de`, `root_sentence_id` = alter Satz `43d1a0bb…`, `qa_report={'editor_revision':…}`. Alte Zeile unverändert, behält ihre ursprüngliche Redaktionsherkunft. |
| `sentence_tokens` | +12, Oberfläche/Offsets/Lemma/Sense/Karte/Glosse identisch zu den alten 12 |
| `card_sentences` | alter Link nur `removed_in`/`replaced_by` ergänzt; neuer aktiver Link Position 1, Lücke 25–33 |
| `content_releases` | Releasezeile der neuen Version (übliche Versionsmetadaten) |
| `story_context_corrections` | +8 = die bestehenden 8 Reader-Korrekturkanten (bekannt aus Paket 2), keine neue Story |
| alle übrigen | ohne Änderung, nichts entfernt |

Weitere Ergebnisse des Exports:
- `finalization_report`: `status=ok`, `history_superset=true`, `valid/approved`, 0 Fehler, 9 Hinweise.
- `editorial_reviews.json`: genau `record_refs=["chitchat|…"]`.

Kein verbleibender Inhalts- oder Vertragskonflikt.

## Tests

Neu: `pipeline/tests/test_editor_validation_scope.py` (4 Tests):
- Profiltrennung: Story-Default blockiert; Stapel-Dialog wird akzeptiert; Satzende, Länge und Lücke werden weiter erkannt.
- Echte Storykorrektur mit zwei Sätzen bleibt „Genau ein Übungssatz“.
- `revise_context` mit zweiteiligem Kontext ergibt `valid`; derselbe Kontext ohne Satzende bleibt blockiert.
- Katalogstatus je Aufgabe und Review-Umfang nur für das geänderte Ziel.

Gegenprobe: Mit der alten Stapelregel scheitert der Kontexttest an „Genau ein Übungssatz ist erforderlich.“.

| Befehl (macOS; Windows: `pipeline\.venv\Scripts\python.exe` mit gleichen Argumenten) | Ergebnis | Exit |
|---|---|---|
| `pipeline/.venv-macos/bin/python -m pytest pipeline/tests/test_editor_validation_scope.py -q` | 4 passed | 0 |
| `pipeline/.venv-macos/bin/python -m pytest pipeline/tests/test_editor_validation_scope.py pipeline/tests/test_editor_service.py pipeline/tests/test_editor_exchange.py pipeline/tests/test_editor_xlsx.py pipeline/tests/test_editor_http.py pipeline/tests/test_editor_workspace.py pipeline/tests/test_editor_publisher.py pipeline/tests/test_language_profiles.py pipeline/tests/test_context_revisions.py -q` | 62 passed in 25.00s | 0 |
| `node --test pipeline/tests/editor_ui_test.cjs` (beide Plattformen) | pass 1, fail 0 | 0 |
| `pipeline/.venv-macos/bin/python -m pytest pipeline/tests -q` | 585 passed, 1 skipped, 19 subtests passed (2:32) | 0 |
| `git -c core.whitespace=cr-at-eol diff --check` | ohne Befund. Ohne Option meldet git nur die CRLF-Zeilenenden der CRLF-Datei `app.js`. | 0 |

Keine bestehenden Tests verändert oder gelockert. GitNexus-Impact vor Edits:
- `target_findings` **CRITICAL** (apply_operations, materialize_draft, Editorjobs, review, accept_import).
- `validate_draft` **HIGH**, `renderValidation` **HIGH**.
- `validate_sentence`/`catalog`/`review` UNKNOWN; per Textsuche bestätigt: Story-Pfad, `target_findings`, Serverrouten.

Diese Risiken sind durch die vollständige Suite abgedeckt, aber nicht aufgehoben.

`detect_changes(scope=all)` vor dem Commit: **CRITICAL**, 16 Symbole, 6 Dateien, 29 Prozesse (Export/Import/Neu/Review/Katalog/Validierung), weder `partial` noch `truncated`. `target`, `exchange`, `run_dart` und `draft_content_hash` sind nur durch Zeilenverschiebung als berührt markiert; ihre Logik ist unverändert.

## Bedienung für die echte Korrektur

1. Laufenden Editordienst mit Ctrl+C beenden. Er hat noch den alten Code geladen.
2. Neu starten, aus dem Repository-Root:
   macOS (Terminal): `pipeline/.venv-macos/bin/python -X utf8 -m sprachpipe.editor`
   Windows (PowerShell): `pipeline\.venv\Scripts\python.exe -X utf8 -m sprachpipe.editor`
3. **Inhalte** → Stapel „Alltagssprache & Redewendungen“ → Arbeitsstand „Entwurf 2026-10-18 · 441 Ziele · R6“, Suche `chitchat`. Satzübersetzung prüfen (bereits gespeichert).
4. **Technisch prüfen**. Erwartet: „Technisch: Gültig“, „Keine technischen Blocker“, 9 Hinweise an unveränderten Aufgaben.
5. **Redaktionell bestätigen**. Der Dialog nennt nur chitchat. Satz, Übersetzung, Lücke und Bindungen tatsächlich prüfen, Prüfperson/Notiz eintragen.
6. **Exportieren → Neue lokale Releaseversion · mit Dart-Prüfung**, neues Versionslabel. Upload/Veröffentlichung sind getrennte, bewusst auszulösende Schritte.
