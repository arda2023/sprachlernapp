# Veröffentlichte Version als Bearbeitungsbasis · 18.10.2026

Ziel: Den chitchat-Entwurf R8 (`00df73b5-…`, Basis `story_single_sentence_v1`) als Folgeversion von
`story_single_sentence_v1-internal-baseline` veröffentlichen können. Dabei bleiben `PUBLISH_BASE_CHANGED`
und `PARENT_CONTENT_CHANGED` unverändert erhalten.

Keine Cloudänderung, kein Upload, keine Veröffentlichung, kein Push. Der echte Editorstore und das Asset sind per Hashvergleich unverändert.

## Was der bestehende Cloudweg liefert

| Weg | Inhalt |
|---|---|
| `content-publish` `GET channel` (Publisher-Anmeldung, lesend) | Kanalzeile (Generation, Release-ID, Manifesthash) + Endmanifest. Das Manifest bindet `sha256`/`size_bytes` (SQLite), `pack_json_sha256` (Bytes), `pack_canonical_sha256`, Registry-, Inventar- und Reviewhashes. **Keine Dateien.** |
| `content-release …/download` (Leserfreigabe) | signierte URLs nur für `content.sqlite` und `history_inventory.json` |

**`pack.json`, also die Editorbasis, liefert kein bestehender Cloudweg.**

Rekonstruktion ist ausgeschlossen und wäre auch nicht möglich: Ein Mac-Neubau der Erstübernahme scheitert am festen SQLite-Byteanker `converted_sqlite_sha256` (`ADOPTION_CONTENT_CHANGED`). Die Originaldateien müssen deshalb aus dem Windows-Editorstore kommen.

## Ablauf (implementiert)

1. **Übertragen.** Den Windows-Bundleordner mit allen 9 Dateien (`content.sqlite`, `pack.json`, `registry.json`, `history_inventory.json`, `editorial_reviews.json`, `provenance.json`, `finalization_report.json`, `content.manifest.json`, `reader_report.json`) als eigenen Unterordner nach `<Editorstore>/published-bundles/` kopieren. Der Browser setzt keinen Pfad. Die 50-MiB-Uploadgrenze greift dadurch nicht (Bundle etwa 95 MB).
2. **Vorschau** (Versionen → „Veröffentlichte Version als Bearbeitungsbasis übernehmen …“, Job `published-base-preview`):
   - Kanal lesend abfragen. Abgewiesen werden: Generation 0 (`PUBLISHED_BASE_NONE`); widersprüchliche Release-ID, Generation oder Manifesthash ≠ kanonischer Manifesthash (`PUBLISHED_CHANNEL_INVALID`); falsche Sprache, Kanal, Schema 5 oder Profil (`PROFILE_UNSUPPORTED`).
   - Passendes Bundle über Version und SQLite-Hash finden (`PUBLISHED_BUNDLE_MISSING` nennt Dateien und Zielordner) und vollständig prüfen:
     - SQLite-Hash und -Größe, `pack.json`-Bytes und kanonischer Hash;
     - Packsprache, -version und -registry;
     - Registry-, Inventar- und Reviewhashes;
     - lokales Bundlemanifest = Endmanifest ohne die Serverfelder.
   - Abweichungen ergeben `PUBLISHED_BUNDLE_MISMATCH`/`_INCOMPLETE`.
   - Die Vorschau zeigt Kanal, Generation, Bundle, bisherige Basis und betroffene Entwürfe. Sie wird hashgebunden unter `<Store>/published-bases/` abgelegt; der Head ändert sich dabei nicht.
3. **Übernahme** nur mit `preview_sha256` + `accepted:true` (Job `published-base-adoption`):
   - Bundle erneut vollständig prüfen (`PUBLISHED_BUNDLE_CHANGED`/`MISMATCH`).
   - **Unmittelbar davor** den Kanal erneut abfragen; jede Änderung führt zu `PUBLISHED_CHANNEL_CHANGED`.
   - Abbruchpunkt prüfen.
   - Unter dem Store-Mutex: Ist die Version bereits Head, ist das idempotent (`already_head`). Hat sich der lokale Head seit der Vorschau geändert, folgt `BASE_CHANGED`.
   - Inhaltsadressierte Basis schreiben und rücklesen, dann `heads/<lang>.json` als einzigen atomaren Commitpunkt setzen. Scheitert ein Schritt, bleibt die bisherige Basis.
   - Danach einen Übernahmebeleg schreiben.
4. **Entwürfe werden nie umgeschrieben.** Im Entwurf „Basis abgleichen“ (bestehender Rebase):
   - Er prüft die Hashes von Karte, Satz und Link jeder Operation gegen die neue Basis und zeigt Konflikte (`REBASE_CONFLICT`).
   - Er leert Prüfung und Bestätigungen. Danach sind erneut „Technisch prüfen“ und „Redaktionell bestätigen“ nötig.

Für R8 belegt: Alle drei Hashes der chitchat-Operationen stimmen im konvertierten Pack exakt. Der Abgleich ist konfliktfrei.

Geänderte Dateien:
- `pipeline/src/sprachpipe/editor/published_base.py` (neu)
- `editor/service.py` (`published_base_preview`, `adopt_published_base`)
- `editor/server.py` (`POST /published-base/preview`, `POST /published-base/adopt`)
- `editor/web/app.js` (Button + Dialog `adoptPublishedBase`)
- Tests: `pipeline/tests/test_editor_published_base.py`

Publisher, Verifier, Rebase und Serverfunktionen sind unverändert.

## Nachweise

Lokale Simulation, nicht Cloud: Kanalantwort per Stub, nach dem Muster von `finalManifest` erzeugt. Als Windows-Bundle diente ein **Testfixture**: auf dem Mac gebaut, Inhaltsanker `converted_content_sha256` geprüft, SQLite-Byteanker übersprungen. Es ist nicht für den echten Einsatz bestimmt.

Kompletter Folgeweg auf einer konsistenten Kopie des echten Stores ([Protokoll](evidence/content-published-base/e2e-copy-simulation.txt)):

1. R8 `approved`, Basis `story_single_sentence_v1`.
2. Vorschau: Generation 1, 9 Dateien, 3 bestehende Entwürfe gelistet.
3. Übernahme: Head = `internal-baseline` (`0bce823c…` = Kanal-`pack_canonical_sha256`), R8 bytegleich.
4. Abgleich → R9: Operationen identisch, Prüfung `None`, Reviews `[]`.
5. Technisch `valid`/`open`, 0 Fehler, 9 Hinweise, nur chitchat geändert.
6. Bestätigung ausdrücklich als „TEST (lokale Simulation, keine Sprachfreigabe)“.
7. Release `chitchat_de_korrektur_v1` `verified`.
8. `inspect_bundle` OK.
9. Editor-Vorprüfung bestanden: Beleg mit `expected_generation 1` und korrektem Parent. Der Stub bricht beim ersten Cloudaufruf ab.
10. Python-Port der Serverstufen `P_full` und `H` bestanden (Packscope, `base_sha256` = Parent-Packhash, Registry- und Kontexthistorie, Storysnapshots).

Diff gegen die veröffentlichte Basis:
- `sentences` +1: „Wir unterhielten uns nett, während wir auf den Bus warteten.“;
- `sentence_tokens` +12;
- `card_sentences` +1, alter Link nur `removed_in`/`replaced_by`;
- `content_releases`: Versionszeile.
- Sonst nichts.

Browser (zweite Kopie, Stub-Publisher): Versionen → Button → Vorschau ([Bild](evidence/content-published-base/preview-dialog.png)) → „Als Bearbeitungsbasis übernehmen“ → Jobs `succeeded`, Head = `internal-baseline`.

| Befehl (macOS) | Ergebnis | Exit |
|---|---|---|
| `pipeline/.venv-macos/bin/python -m pytest pipeline/tests/test_editor_published_base.py -q` | 4 passed | 0 |
| `… -m pytest pipeline/tests/test_editor_published_base.py pipeline/tests/test_editor_service.py pipeline/tests/test_editor_publisher.py pipeline/tests/test_editor_http.py pipeline/tests/test_editor_validation_scope.py pipeline/tests/test_baseline_adoption.py pipeline/tests/test_editor_workspace.py -q` | 51 passed | 0 |
| `node --test pipeline/tests/editor_ui_test.cjs` | pass 1 | 0 |
| `pipeline/.venv-macos/bin/python -m pytest pipeline/tests -q` | 589 passed, 1 skipped | 0 |
| `git -c core.whitespace=cr-at-eol diff --check` | ohne Befund | 0 |

Unter Windows laufen die Python-Tests mit `pipeline\.venv\Scripts\python.exe` und denselben Argumenten.

Die Regressionstests decken ab:
- Vorschau ohne Headwechsel, Bestätigungspflicht, Übernahme, unveränderte Entwurfsbytes, Idempotenz;
- Rebase erhält die Operation und leert Prüfung und Review;
- Ablehnung bei fehlender Anmeldung, leerem Kanal, gefälschtem Manifesthash, falschem Profil, veränderten `pack.json`-Bytes, fehlender Datei und fehlendem Bundle;
- Abbruch bei neuer Kanalgeneration, veränderter Registry, Schreibfehler am Head-Commit und geändertem lokalem Head. Die Basis bleibt in allen Fällen erhalten.

GitNexus: `route` LOW, `EditorService` LOW (nur neue Methoden); `releases()` und `publisherControls` **HIGH**. Daher nur ein zusätzlicher Button, `publisherControls` unverändert.

`detect_changes(staged)` vor dem Commit: **CRITICAL**, 18 Symbole, 10 Dateien, 18 Prozesse, ohne `partial`/`truncated`.
- `publish_release`, `publication_status`, `inspect`/`save`/`perform` gelten nur durch Zeilenverschiebung als berührt; `service.py`/`server.py` enthalten keine entfernten Zeilen.
- `adoptBaseline` und `releases` sind durch die eingefügte Nachbarfunktion bzw. den Button berührt.

Das Risiko bleibt durch die Gesamtsuite abgedeckt, ist aber nicht aufgehoben.

## Grenzen
- Cloudseitig ist nichts nachgewiesen. Kanalantwort und Bundle des echten Laufs sind noch ungeprüft.
- Der Server läuft im Test nicht nativ (kein Deno installiert); die Stufen `P_full`/`H` wurden in Python portiert.
- Die Übernahme erfordert eine gültige Publisher-Anmeldung im Editor. Ohne sie gibt es `AUTH_REQUIRED`.
- Mehrere passende Bundleordner: Der erste vollständig verifizierte wird verwendet; der erste konkrete Fehler wird gemeldet.

## Echter Ablauf

### 1. Windows (PowerShell): Bundle finden (nur lesend)

Storepfad laut `store.default_directory`: `%LOCALAPPDATA%\SprachappContentEditor`.

```powershell
$store = Join-Path $env:LOCALAPPDATA 'SprachappContentEditor'
Get-ChildItem -LiteralPath (Join-Path $store 'releases') -Filter *.json | ForEach-Object {
  $r = Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
  if ($r.publication_kind -eq 'internal-baseline-adoption-v1') {
    $dir = Join-Path $store ($r.path -replace '/', '\')
    [pscustomobject]@{ Version = $r.version; ReleaseId = $r.release_id; Status = $r.publication.status; Ordner = $dir }
    Get-ChildItem -LiteralPath $dir -File | Select-Object Name, Length
    'pack.json SHA256: ' + (Get-FileHash -LiteralPath (Join-Path $dir 'pack.json') -Algorithm SHA256).Hash.ToLower()
  }
}
```

Erwartet: Version `story_single_sentence_v1-internal-baseline`, Status `published`, 9 Dateien. Den gesamten Ordner `Ordner` unverändert auf den Mac übertragen (z. B. USB-Stick); nichts umbenennen oder bearbeiten.

### 2. macOS (Terminal): einsortieren

```sh
mkdir -p "$HOME/Library/Application Support/SprachappContentEditor/published-bundles"
cp -R "/Volumes/<STICK>/<BUNDLE-ORDNER>" "$HOME/Library/Application Support/SprachappContentEditor/published-bundles/"
```

### 3. Editor starten

Laufenden Dienst mit Ctrl+C beenden, dann:

```sh
cd /Users/ardasayar/Documents/FlutterProjekte/sprachapp
export SPRACHAPP_SUPABASE_URL='https://yevntxclpchapacqdizm.supabase.co'
printf 'Publishable Key: '; read -r SPRACHAPP_SUPABASE_ANON_KEY; export SPRACHAPP_SUPABASE_ANON_KEY
pipeline/.venv-macos/bin/python -X utf8 -m sprachpipe.editor
```

### 4. Klicks

1. **Versionen** → mit bestehender E-Mail und Passwort anmelden.
2. **Veröffentlichte Version als Bearbeitungsbasis übernehmen …**
3. Vorschau prüfen: `story_single_sentence_v1-internal-baseline · Generation 1`, 9 Dateien, Entwürfe gelistet.
4. **Als Bearbeitungsbasis übernehmen**.
5. **Inhalte** → Entwurf „Alltagssprache & Redewendungen · R8“ → **Basis abgleichen** (erwartet: keine Konflikte, neue Revision).
6. **Technisch prüfen** → „Gültig“.
7. **Redaktionell bestätigen**: chitchat erneut prüfen, eigener Name und Notiz.
8. **Exportieren** → „Installierbare Inhaltsversion (Release)“ → Versionsname `chitchat_de_korrektur_v1` → **Export starten**.
9. **Versionen** → `chitchat_de_korrektur_v1` → „1 · Privat hochladen“ → „2 · Serverprüfung“ → „3 · Veröffentlichen“. Dies ist ein gesonderter, bewusst auszulösender Cloudschritt.
