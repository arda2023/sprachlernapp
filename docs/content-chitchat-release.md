# chitchat-Korrektur als Folgeversion · 18.10.2026

Ausgangslage:
- Echter Entwurf `00df73b5-fb6f-4b63-a5e7-53fc56f8ed0c`, R8, 441 Ziele. Prüfbericht von R7: `valid`/`approved`, 0 Fehler, 9 Hinweise. Bestätigung „Arda“ exakt an den Inhaltshash von R8 gebunden. Nur chitchat geändert.
- Veröffentlicht und auf dem iPhone aktiv: `story_single_sentence_v1-internal-baseline`.
- Keine Cloudänderung, kein Upload, kein Push.

## Austausch-ZIP vs. Inhaltsversion (Code)

| | Austausch | Installierbare Inhaltsversion |
|---|---|---|
| UI bisher | Inhalte → **Exportieren** → Auswahl voreingestellt „Redaktionelles ZIP · vollständiger Austausch“ | dieselbe Auswahl, vierte Option „Neue lokale Releaseversion · mit Dart-Prüfung“ |
| API | `POST /drafts/{id}/exchange` (`zip`/`xlsx`/`json`) → `EditorService.exchange` | `POST /drafts/{id}/releases` (`version`, `validation_sha256`) → `EditorService.release` → `build_release` |
| Ergebnis | `redaktion-en.zip` (delivery.json, FORMAT.md, …), keine Version, kein Eintrag unter „Versionen“ | 9-Dateien-Bundle mit SQLite-Readback und Dart-Reader, Eintrag unter „Versionen“, lokaler Head = neues Pack |

Ihr bisheriger Download war also der Austauschweg. Der Releaseweg war erreichbar, aber in der Auswahl versteckt.

**Änderung** (`pipeline/src/sprachpipe/editor/web/app.js`, nur Texte und Voreinstellung):
- Die Auswahl heißt jetzt „Was soll entstehen?“.
- Erste Option: „Installierbare Inhaltsversion (Release) · erscheint unter „Versionen““. Sie ist vorausgewählt, wenn der Entwurf technisch gültig und redaktionell bestätigt ist.
- Austauschoptionen heißen „Austausch-ZIP/-XLSX/-JSON … · keine Inhaltsversion“.
- Das Versionsfeld ist nur beim Release sichtbar; ein Hinweistext erklärt den Unterschied.
- Der Leerhinweis unter „Versionen“ nennt den genauen Klickweg ([Dialog](evidence/content-chitchat-release/export-dialog.png)).

## Vorgänger: konkreter Blocker

| Prüfstelle | Regel | Ergebnis für R8 |
|---|---|---|
| `service.publish_release` (`service.py:519`) | Kanal-Generation 0 **oder** Kanalmanifest `version` und `pack_canonical_sha256` = Entwurfsbasis | Kanal: `story_single_sentence_v1-internal-baseline`. Basis: `story_single_sentence_v1` (`fd3ce96b…`) → `PUBLISH_BASE_CHANGED` |
| Server Stufe H (`content_verification_steps.ts:43`) | `validation.base_sha256 == parent.manifest.pack_canonical_sha256` | Der Parent-Hash ist der Hash des konvertierten Schema-5-`pack.json` der Erstübernahme (`P_full`), nicht `fd3ce96b…` → `PARENT_CONTENT_CHANGED` |

Die Erstübernahme ist an dieselbe Quelle `fd3ce96b…` gebunden. Veröffentlicht wurde aber deren konvertiertes Pack mit eigener Version und eigenem kanonischem Hash.

Im Code gibt es keinen Weg, eine veröffentlichte oder lokal übernommene Erstversion als Editorbasis zu setzen:
- `adopt_baseline` registriert die Erstversion nur, ohne den Head umzustellen.
- `rebase` gleicht nur gegen den lokalen Head ab.

Auf diesem Mac fehlt außerdem das Bundle der Erstübernahme: kein `releases/`, kein `bundles/`, keine passende `content.manifest.json` gefunden.

Deshalb **kein Build im echten Store**. Er hätte:
- ein nicht veröffentlichbares Release registriert,
- den Head auf `chitchat_de_korrektur_v1` (Basis `fd3ce96b…`) umgestellt,
- den gewünschten Namen dauerhaft belegt (`VERSION_EXISTS`).

Eine zweite Erstübernahme wurde nicht erzeugt.

## Nachweis auf einer Kopie

Echter Store per dreifachem Hashvergleich konsistent nach `/tmp/sprachapp-release-chitchat/` kopiert (28 Dateien). Zweite Editorinstanz ohne Cloudvariablen.

Im Browser: Inhalte → Exportieren → „Installierbare Inhaltsversion“ → `chitchat_de_korrektur_v1` → Job `succeeded`, unter „Versionen“ registriert ([Bild](evidence/content-chitchat-release/versions-copy.png)). Prüfprotokoll: [verify-copy.txt](evidence/content-chitchat-release/verify-copy.txt).

**Vorhandener Bundleverifier** `publisher.inspect_bundle`: OK.
- 9 Dateien, SQLite `a92c11db…`, 43.089.920 Byte.
- Review „Arda“ an Inhaltshash gebunden; ETag von R8 passt.
- Bericht `ok`, `history_superset`, `valid/approved`, 0 Fehler.

**Fachliche Änderungen gegenüber der Basis:**
- `sentences` +1: gleicher Text, „Wir unterhielten uns nett, während wir auf den Bus warteten.“, Wurzel = alter Satz.
- `sentence_tokens` +12: identische Bindungen.
- `card_sentences`: alter Link nur `removed_in`/`replaced_by`, dazu ein neuer aktiver Link.
- `content_releases`: Versionszeile.
- `story_context_corrections` +8: die bestehenden Reader-Kanten.
- Keine Karten-, ID- oder Löschänderungen.

**Vorgängerprüfung (Simulation, ohne Cloud):** Publisher-Stub mit Kanalzustand „Generation 1, `story_single_sentence_v1-internal-baseline`“ → `publish_release(upload)` endet mit `PUBLISH_BASE_CHANGED`. Kein Upload-Beleg wurde angelegt.

Danach: echter Store per Hashvergleich unverändert, Asset `b8579393…` unverändert, Testassetziel leer.

## Prüfungen

| Befehl | Ergebnis | Exit |
|---|---|---|
| `node --test pipeline/tests/editor_ui_test.cjs` | pass 1, fail 0 | 0 |
| `pipeline/.venv-macos/bin/python -m pytest pipeline/tests/test_editor_http.py pipeline/tests/test_editor_service.py pipeline/tests/test_editor_publisher.py pipeline/tests/test_editor_validation_scope.py pipeline/tests/test_baseline_adoption.py -q` | 45 passed | 0 |
| `pipeline/.venv-macos/bin/python /tmp/sprachapp-release-chitchat/verify.py` (Kopie) | siehe Protokoll | 0 |
| `git -c core.whitespace=cr-at-eol diff --check` | ohne Befund | 0 |

Unter Windows: `pipeline\.venv\Scripts\python.exe` mit gleichen Argumenten.

## Editorstart (macOS, Terminal, Repository-Root)

Variablennamen laut `publisher.py`: `SPRACHAPP_SUPABASE_URL`, `SPRACHAPP_SUPABASE_ANON_KEY`. `sb_publishable_…` ist erlaubt; `sb_secret_…`/Service-Role werden abgewiesen.

```sh
cd /Users/ardasayar/Documents/FlutterProjekte/sprachapp
export SPRACHAPP_SUPABASE_URL='https://yevntxclpchapacqdizm.supabase.co'
printf 'Publishable Key: '; read -r SPRACHAPP_SUPABASE_ANON_KEY; export SPRACHAPP_SUPABASE_ANON_KEY
pipeline/.venv-macos/bin/python -X utf8 -m sprachpipe.editor
```

Laufenden Editordienst vorher mit Ctrl+C beenden. Danach erscheint unter „Versionen“ die Anmeldung statt „Privater Inhaltsserver noch nicht eingerichtet“.

## Fehlende Voraussetzung und nächste Schritte

1. **Bundle der veröffentlichten Erstübernahme bereitstellen**, und zwar genau die veröffentlichten Bytes.
   - Herkunft: der Editorstore, in dem „Vorhandenes App-Pack … übernehmen“ und der Upload ausgeführt wurden, z. B. Windows `%LOCALAPPDATA%\SprachappContentEditor\` (`releases\<id>.json` und `bundles\<id>\`).
   - Kein neuer Erstübernahme-Klick.
2. **Neuer, separat freizugebender Codeschritt:** „Veröffentlichte Version als Bearbeitungsbasis übernehmen“.
   - Prüft das Bundle mit `inspect_bundle`.
   - Prüft gegen den angemeldeten Kanal: Generation, Release-ID, Manifesthash, `pack_canonical_sha256`.
   - Setzt erst dann den lokalen Head auf dieses Pack.
3. Im Entwurf **Basis abgleichen**, danach **Technisch prüfen**. Die Bestätigung ist an die alte Basis gebunden, deshalb ist **Redaktionell bestätigen** durch die Redaktion erneut nötig.
4. Exportieren → „Installierbare Inhaltsversion (Release)“ → `chitchat_de_korrektur_v1` → unter Versionen „1 · Privat hochladen“ → „2 · Serverprüfung“ → „3 · Veröffentlichen“.
