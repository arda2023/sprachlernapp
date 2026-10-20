# Inhaltseditor – Paket 2

Stand 16.10.2026. Lokaler Editor implementiert, auf macOS im echten Browser und über die echten Export-/Readerpfade geprüft. Windows-Geräte-/Browserabnahme bleibt offen. Paket 3 wurde nicht begonnen. Ausgangspunkt `5fda70df6b61bc7207477deed6ca1f0ffbabcd8d`, Implementierungsbranch `codex/content-editor-package-2`.

Arbeitsfolge: Verträge/Revisionen → gemeinsamer Authoring-Service → Import/Entwürfe → Browsereditor → Reader/Export → vollständige Abnahme.

## Start und Bedienung

Ab Repository-Root, mit der eingerichteten Pipeline-Umgebung und verfügbarem Dart/Flutter-SDK:

macOS (Terminal):

```sh
pipeline/.venv-macos/bin/python -m sprachpipe.editor
```

Windows (PowerShell):

```powershell
pipeline\.venv\Scripts\python.exe -m sprachpipe.editor
```

Der Dienst öffnet den Browser auf einem freien Loopback-Port. Der einmalige Starttoken wird gegen eine lokale Session getauscht. Beenden mit Ctrl+C. Entwürfe liegen auf macOS unter `~/Library/Application Support/SprachappContentEditor/`, auf Windows unter `%LOCALAPPDATA%\SprachappContentEditor\`. Beim ersten Start wird `pipeline/out/story_single_sentence_v1/pack.json` als unveränderliche Basis kopiert. Folgestarts verwenden den lokalen Stand und wiederhergestellte Entwürfe.

1. **Inhalte** öffnen, Englisch und einen vorhandenen Stapel auswählen. Über die Entwurfsaktion eine bearbeitbare Kopie anlegen; der Quellpack bleibt unangetastet.
2. Ziel suchen und **Details** öffnen. Satz, deutsche Übersetzung und Lösungshinweis bearbeiten. Nach einer Satzänderung **Tokenisieren**, Lücke auswählen und die Wortbindungen ausdrücklich bestätigen. Token anklicken, um vorhandene Bedeutung/Formglosse und lokale Kontextübersetzung getrennt zu bearbeiten. Neue Begleitbedeutungen werden bewusst angelegt.
3. Alternativen als vollständigen eingesetzten Satz prüfen. Speichern; technische Prüfung starten. Fehler bleiben als bearbeitbarer Entwurf erhalten. Danach redaktionelle Prüfpunkte bestätigen.
4. Lokalen Release mit neuem Versionsnamen bauen. **Versionen → Bundle herunterladen** liefert Pack, SQLite, Registry, Historieninventar, Reviews, Provenienz, Prüfbericht und Manifestentwurf.
5. **Assetübernahme prüfen …** ist eine getrennte Aktion mit Auswirkungsvorschau und Sicherung. Sie ist für die reine Bearbeitung/Versionserstellung nicht erforderlich. In dieser Abnahme wurde sie ausschließlich gegen temporäre Testassets ausgeführt.

**Lieferungen** bietet ZIP-/JSON-/XLSX-Import, vollständige Vorschau und Übernahme. Vollständiges XLSX enthält Detailblätter; einfache Tabellen dürfen zunächst unvollständig sein. Fehlendes Zielwort und Stapelzuordnung lassen sich im Detail ergänzen. **Sprachentwurf** speichert eine synthetische oder später unterstützte Sprache getrennt; ohne registriertes Profil zeigt die Prüfung „Profil fehlt“ und verhindert einen Release. Nur Englisch ist produktiv registriert.

## Umsetzung und Dateigrenze

| Bereich | Dateien / Ergebnis |
|---|---|
| Fachlicher Kern | `pipeline/src/sprachpipe/authoring_service.py`: Normalisierung, Vorschau, atomare Operationen, bestehende Validatoren/Linter, Reviewbindung, Build, vollständiger Readback |
| Historie | `context_revisions.py`, `schema.py`, `ids.py`, `pack.py`, `content_contract.py`: additives Schema 5, unveränderliche Satzrevisionen, eingefrorene Tokenanzeigen, kumulative Storykanten |
| Lokaler Dienst | `editor/__main__.py`, `server.py`, `store.py`, `jobs.py`, `service.py`: Loopback, Prozesslock, CAS/ETags, atomare Revisionen, Journal, serieller Worker, Recovery und Konflikte |
| Transport | `editor/exchange.py`, `editor/xlsx.py`, `editorial_content_v4.schema.json`: v2/v3/v4, ZIP, vollständiges/einfaches XLSX, Quarantäne, Größen- und Pfadgrenzen |
| Oberfläche | `editor/web/index.html`, `app.js`, `style.css`: deutsche Tabelle, Detaildialog, Tokenbearbeitung, Sprachen, Lieferungen, Prüfungen, Versionen und gesonderte Übernahme |
| Profile | `language_profiles.py`, `lib/domain/language_profile.dart`: eingefrorenes Englischprofil, unbekannte Profile ohne Fallback |
| Dart | `content_database.dart`, `drift_content_repository.dart`, neue `context_revision_validation.dart`: Schema 1–5, tatsächliche historische Anzeigen, Storykorrekturketten |
| Abnahmeadapter | `tool/editor_content_pack.dart`: tatsächlicher Repository-Reader und Aufruf des unveränderten Stagingwerkzeugs |
| SQL / Abhängigkeiten | `supabase/migrations/20261017000001_content_context_revisions.sql` nur lokal; `openpyxl==3.1.5` und `et-xmlfile==2.0.0` im Lockfile; Webdateien als Paketdaten |
| Regressionen | sechs neue Python-Testdateien, `test/data/content_context_revisions_test.dart`, `editor_stage_test.dart`, drei synthetische Fixtures `test/fixtures/editor_*` |

Zusätzliche Adapter-/Fixturepfade wurden vor Bearbeitung begründet: echte Readervergleiche, zwei unterschiedliche Storyherkünfte und temporäres Staging benötigen reproduzierbare Dateien. Die historischen CLI-Importer, Userrepository, Antwortprüfung, SRS und vorhandenen UI-Dateien wurden nicht umgebaut. Der lokale Dienst verwendet dieselben fachlichen Build-/Registry-/Form-/Linter-/Exportfunktionen; HTTP und XLSX bekommen keine alternative fachliche Freigabe.

Sicherheitsgrenzen: `127.0.0.1`, exakter Host/Origin, einmaliger Starttoken, HttpOnly/SameSite-Session, CSRF und Requestkeys, kein Browser-Dateipfad und kein Shellstring. Uploadbytes werden vor dem Parsen gesichert. ZIP-Pfade, Expansion/Kompressionsverhältnis, Makros, externe Objekte, Formeln und unzulässige JSON-Felder werden abgewiesen. Importierte Freigabebehauptungen werden nicht zu lokalen Reviews. Langläufer laufen als Jobs; Abbruch während eines Dart-Schrittes wird als angefordert angezeigt und nach dem Schritt verarbeitet.

## Browserabnahme A1–A8

Echte Bedienung im Codex-Browser auf macOS, keine ersatzweise als Browserprüfung ausgegebenen HTTP-Tests. Mutationen ausschließlich mit synthetischen Quellen, temporären Stores und Testassets unter `/tmp/sprachapp-editor-package2/`.

| Kriterium | Konkreter Nachweis |
|---|---|
| A1 | 250 Zielzeilen vollständig importiert, Verarbeitung 100/100/50. Zwei Sätze geändert: „They cut paper daily.“ und „They cut paper yesterday.“; passende deutsche Übersetzungen, Hinweis „Testhinweis 000 korrigiert“. Token `paper` lokal auf „Papier im Testsatz“ korrigiert. Stapel „Browser-Abnahme“ und Aufgabe `paper` über die UI ergänzt. Technisch gültig, lokal bestätigt, echtes Bundle `browser-acceptance-v1`; 262 aktive Aufgaben einschließlich 11 Basisaufgaben. Alle 23 Tabellen geprüft, echter Dart-Reader, separate Testasset-Übernahme `verified`. |
| A2 | Originale 250er-Lieferung nach Neustart und Release erneut importiert: vorhandener Importbeleg, Draft R13, weiterhin 262 Ziele und erhaltene Satzkorrektur. Gleiche Liefer-ID mit anderem Inhalt wird im Regressionstest als Konflikt abgewiesen. |
| A3 | Synthetischer Sprachcode `qaa`, Stapel „Sprachtrennung“, Aufgabe `cut` und manuelle Texte gespeichert. Keine englischen Bedeutungen in der Auswahl; „Profil fehlt“ blockiert technische Freigabe. Kein neues echtes Sprachprofil registriert. |
| A4 | Unvollständige Aufgabe im Browser gespeichert; Prüfung meldet `FIELD_REQUIRED`. Einfach-XLSX-Fehler nennen Blatt/Zeile/Feld. Fehlendes Zielwort/Stapel und neue Begleitbedeutung können atomar vervollständigt werden; Regressionstests bestanden. |
| A5 | ZIP und vollständiges XLSX tatsächlich im Browser heruntergeladen und mit den Transportadaptern eingelesen: kanonisch identisch, 251 erwartete Ziele, 250 additive Karten plus `create_target`, 1.002 Tokens, zwei Operationen. Referenzen, Bindungen, Gap, Alternativen und Herkunft bleiben erhalten. |
| A6 | Dienst neu gestartet, Draft/Belege erhalten. Zwei echte Tabs: Tab A speichert R2; Tab B mit R1 erhält sichtbaren Konflikt, überschreibt A nicht. Unit-/Integrationstests decken Basis-/Operationskonflikte, Unicode/Lücken, Locks und Job-Recovery ab. |
| A7 | Tatsächliche Dart-Reader-/Userrepository-Tests mit synthetischer Nutzerdatei: Satz-/Tokenrevision und Rückstellung erhalten historische Texte, Boxen/Fälligkeit/Flags/Notizen/Reviews. Gleicher Kontext aus zwei Herkunftsreleases wird über kumulative Kanten zur gleichen Endrevision geführt; Neustart idempotent, Manipulation abgewiesen. Zusätzlich Storykontext `yesterday` im Browser korrigiert, geprüft und als `synthetic-story-browser-v1` gebaut. |
| A8 | macOS-Browser mit echten Fehlern, Konfliktmeldung, Detail-/Import-/Releaseablauf und schmaler 390-px-Ansicht. HTTP-Sicherheitsregressionen bestanden. Windows-Geräte-/Browserabnahme ausdrücklich offen; keine iPhone- oder Screenreader-Gerätefreigabe behauptet. |

Produktionsbestand separat **nur lesend** im Browser geöffnet: 14 Stapel, Suche `bread` mit 44 Treffern. Produktionsquelle und Asset wurden weder zur Browserbearbeitung noch als Stagingziel verwendet.

Screenshots: [Import](evidence/content-editor-package-2/import.jpg), [Tabelle](evidence/content-editor-package-2/table.jpg), [Token-Detail](evidence/content-editor-package-2/detail.jpg), [Fehler](evidence/content-editor-package-2/errors.jpg), [Tabkonflikt](evidence/content-editor-package-2/tab-conflict.jpg), [Sprachentwurf](evidence/content-editor-package-2/language-draft.jpg), [Storyrelease](evidence/content-editor-package-2/story-release.jpg), [Produktionssuche](evidence/content-editor-package-2/production-readonly.jpg), [schmale Versionsansicht](evidence/content-editor-package-2/narrow.jpg).

## Schemawechsel und Altbestand

Produktionsbasis `story_single_sentence_v1`, Schema 4, 22 Tabellen. SHA-256 des unveränderten Assets: `b85793932825a22e92ac744a42255e9f333acd35809aaba46edb5a395f099bdb`.

Auf einer temporären Kopie wurden alle 23 Schema-5-Tabellen vollständig gegen erwartete Rows verglichen. Der tatsächliche Reader liefert vor/nach Migration:

| Inventar | Anzahl | Ergebnis |
|---|---:|---|
| Aktive Darstellungen | 3.767 | identisch |
| Historische Karten-Satzdarstellungen | 4.297 | identisch |
| Storysatzanzeigen | 6 | identisch |
| Storyherkunftssnapshots | 14 | identisch |
| Bestehende Storykorrekturen | 8 | identische Kanten; neue topologische Reihenfolge |

Beleg: [production-comparison.json](evidence/content-editor-package-2/production-comparison.json). Die bereits dokumentierten **137 Provenienzlücken** bleiben offen. Zusätzlich zeigt der exakte Reader-Snapshot drei bereits vorher fehlende Story-Tokenübersetzungen für `so`; sie wurden weder erfunden noch als neue Regression ausgegeben:

- Token `76ee8fc2dde17fa5a4c237f4e7f0f4cf`, Satz `6b16d298c448ea845b600cfd8eb27637`.
- Token `552521148887ec119486cab8f59f2754`, Satz `1e047de6e0a0f09136a14753a634cb52`.
- Token `cd641063c5d4edf59d443b08153c0544`, Satz `d35bd278154554f67175421eda5326d1`.

Neue Kontexte müssen vollständig sein und dürfen sich nicht als Legacy-Lücke deklarieren. Vorhandene IDs bleiben erhalten. Profilfingerprint Englisch: `59eec37d0a4f322d666701e00bc1bf4cfb44d19b183b1742d16b443989a505cf`.

## Prüfkommandos und tatsächliche Ergebnisse

Alle Pfade vor Ausführung bestätigt. Flutter-Prüfungen sequenziell, ursprüngliches 30-Sekunden-Packtestbudget unverändert. Die folgenden Kommandos liefen mit Exit 0; Auszüge liegen in [verification.txt](evidence/content-editor-package-2/verification.txt).

macOS Python:

```sh
pipeline/.venv-macos/bin/python -m pytest pipeline/tests/test_editor_service.py pipeline/tests/test_editor_exchange.py pipeline/tests/test_editor_xlsx.py pipeline/tests/test_editor_http.py pipeline/tests/test_language_profiles.py pipeline/tests/test_context_revisions.py -q
pipeline/.venv-macos/bin/python -m pytest pipeline/tests -q
```

Windows-Äquivalent, auf diesem Rechner nicht ausgeführt:

```powershell
pipeline\.venv\Scripts\python.exe -m pytest pipeline/tests/test_editor_service.py pipeline/tests/test_editor_exchange.py pipeline/tests/test_editor_xlsx.py pipeline/tests/test_editor_http.py pipeline/tests/test_language_profiles.py pipeline/tests/test_context_revisions.py -q
pipeline\.venv\Scripts\python.exe -m pytest pipeline/tests -q
```

Beide Plattformen, hier auf macOS ausgeführt:

```text
flutter test --no-pub test/data/content_context_revisions_test.dart test/data/editor_stage_test.dart test/data/stage_content_pack_test.dart test/data/targeted_curation_test.dart test/story_single_sentence_test.dart
flutter test --no-pub
flutter test --no-pub test/data/real_pack_test.dart
flutter analyze --no-pub
dart run tool/stage_content_pack.dart --verify
```

| Prüfung | Finaler Output |
|---|---|
| Neue Python-Regressionen | 32 passed in 17.83s |
| Vollständige Python-Suite | 542 passed, 19 subtests passed in 128.84s |
| Gezielte Flutter-Regressionen | 22: All tests passed! |
| Vollständige Flutter-Suite | 330: All tests passed! (1:00) |
| Echter Produktionspack | 1: All tests passed! (9s) |
| Analyse | No issues found! |
| Assetverify | version story_single_sentence_v1, schema 4; 22 table counts match finalization_report.json |

Konkreter lesender Readeraufruf (Dart auf beiden Plattformen gleich; temporären Zielpfad jeweils passend wählen):

```text
dart run tool/editor_content_pack.dart --from assets/content/en/content.sqlite --out <temporärer-Pfad>/reader.json --lang en
```

Der Browser-Releasejob ruft `authoring_service.build_release` auf: `export_sqlite` → `sqlite_readback` für sämtliche Rows der 23 Tabellen → obiger Dart-Reader für Basis und Kandidat → Historienvergleich. Die temporären Browserbundles enthalten jeweils `reader_report.json` und `finalization_report.json`; kompakte Ergebnisse und Hashes sind in `evidence/content-editor-package-2/bundles.json` gesichert. `editor_stage_test.dart` und der echte Browserjob verwenden den bestehenden Stagingpfad mit temporärem Ziel.

## Abweichungen und behobene Abnahmefehler

- Dateien pragmatisch zusammengefasst: `xlsx.py`, `app.js`, `style.css`; API-/Projektionsdetails liegen im bestehenden Servicezuschnitt. Präzise Ergänzungen stehen am Ende beider Plandokumente.
- Registryformat 1 bleibt erhalten. Ungeteilte Singleton-Rückstellung funktioniert; Owner-/Form-/Gruppen-/fremde Kontextabhängigkeiten zeigen erforderliche Folgeentscheidungen und blockieren ohne konsistente Lösung. Generelle Registryformat-2-Neuzuordnung wird nicht behauptet.
- Eine neue UI-Aufgabe bleibt im vollständigen Austausch als `create_target` im Blatt `Operationen`; beide Darstellungsarten zählen vollständig. Nichtinhaltliche Suchvorschläge werden nicht als Inhaltsdaten exportiert.
- XLSX-Zellen dürfen maximal 32.767 Zeichen enthalten. Fehler wird sichtbar; ZIP kann die optionale XLSX weglassen, behält aber das vollständige JSON. Kein stilles Kürzen.
- Der erste Releaseversuch deckte einen nichtdeterministischen `created_at`-Readback auf. Neue Releases setzen den Zeitpunkt vor beiden Builds explizit; Legacyexport bleibt unverändert. Echter Browser-Release danach bestanden.
- Der erste ZIP-Versuch deckte überlange Zellen durch mitgespeicherte Suchvorschläge auf. Vorschläge sind jetzt reine UI-Daten; vollständiger ZIP-/XLSX-Roundtrip danach identisch.
- Eine anfängliche Dart-Testassertion verglich Maps per Identität; sie wurde auf inhaltliche Gleichheit korrigiert. Analyzer-Hinweise wurden behoben. Kein Timeout angehoben und keine fachliche Assertion abgeschwächt.
- Impeccable-Kontextlauncher scheiterte am vorhandenen CRLF-Shebang; PRODUCT.md/DESIGN.md direkt gelesen, Skill unverändert. Der GitNexus-MCP-Transport war geschlossen; CLI-Fallback verwendet. SDK-Cachezugriffe benötigten die lokale Sandboxfreigabe.

## Schutz und Commitprüfung

[protected-hashes.json](evidence/content-editor-package-2/protected-hashes.json) belegt 15 identische Ausgangs-/Endhashes vor der eigenen NEXTSTEPS-Ergänzung: Produktionsquelle, beide SQLite-Dateien, Manifest, Kuration, pubspec, Antwortprüfung und vorhandene UI-/Teständerungen. NEXTSTEPS erhält ausschließlich einen angehängten Statussatz in der vorhandenen Standzeile, bleibt 25 Zeilen; alte Nutzerinformationen werden erhalten. Für den Commit wird nur dieser eigene Zusatz auf die HEAD-Fassung gestagt, ohne fremde NEXTSTEPS-Hunks.

GitNexus-Impact vor Symboländerungen durchgeführt; HIGH/CRITICAL bei zentralem Build-/Validierungskern gemeldet. UNKNOWN-Ergebnisse durch konkrete Aufrufer-/Quellprüfung ergänzt. Vollständiger Indexneuaufbau erforderlich, da inkrementelle Indexstände zuvor Pfade falsch zuordneten. Graphgrenzen: begrenzte Prozess-/Callable-Erfassung, dynamische und sprachübergreifende Zugriffe. Ein leerer Graphpfad wurde nicht als Unbenutztheitsbeweis behandelt. Abschließende Änderungsanalyse: Scope `all` 364 Symbole/89 Prozesse, Scope `staged` 336 Symbole/89 Prozesse, jeweils CRITICAL ohne `partial`/`truncated`. Vollständige strukturierte Ergebnisse liegen in `graph-all.json` und `graph-staged.json`; das CLI verkürzt lediglich die Bildschirmdarstellung. Betroffen sind unter anderem `build_release`, `apply_operations` und die weiterverwendeten Legacy-Pfade `apply_targeted_patch`/`prepare_continuation`. Vollständige Suiten und echte Reader-/Stageprüfungen ergänzen diese Graphgrenzen. Isolierte Commitprüfung siehe `verification.txt`.

Keine echte `user.db`, keine Cloudmigration, KI-Aufrufe, Veröffentlichung oder Push. Produktionsinhalte, Asset und Manifest unverändert. Die vorhandenen UI-/SRS-/Antwortlogikänderungen des Nutzers bleiben außerhalb dieses Commits. Windows-Abnahme und Paket 3 bleiben offen.
