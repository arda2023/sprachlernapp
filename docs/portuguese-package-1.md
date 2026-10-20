# Portugiesisch · Paket 1

Stand 18.10.2026, Ausgangspunkt `a1f6e29`, Branch `codex/portuguese-package-1`.
Inkrement 1 des abgenommenen Plans: technische Unterstützung für `pt-BR/de`,
regulärer erster privater Kanal und eine echte basisgebundene Authoring-Vorlage.
Keine echten Lernziele, keine sprachliche Freigabe, kein Deployment/Upload/Push.
Mobile Sprachwahl und Antwortklassifikation bleiben Inkrement 2.

## Vertrag und Änderungen

- `pipeline/src/sprachpipe/language_profiles.py`: separates
  `PortugueseEditorialProfile`, exakt `pt-BR-editorial-v1`. Vorhandenes spaCy
  **3.8.16**, ausdrücklich `spacy.blank('pt')`; keine Modell-/Cloudaufrufe.
  Tokenizerbytes werden gegen
  `b528e0528ca541b2815e374dbec35bdbc4574141e7683b23b85384423e782317` geprüft.
  Manifest bindet Tokenizer, Normalisierung, strikte Akzentpolicy, manuelle
  Grammatik-/Frequenzpolicy und ordinary-Fähigkeit. Profilhash:
  `7c59364c0d1ef562ee5a6a679b7d895e0ebec6bf2ad47d8eae56afdcba87fe32`.
- Das **englische Manifest und sein Hash** bleiben unverändert:
  `59eec37d0a4f322d666701e00bc1bf4cfb44d19b183b1742d16b443989a505cf`.
  Keine englischen Frequenzschwellen, POS- oder Dependenzprüfer für BR.
  Technisch geprüft werden vollständige Tokens/Bindungen, eindeutige Lücke,
  Wortzahl und Satzende. Genau ein Satz, höchstens ein Nebensatz, BR-Gebrauch,
  Niveau/Frequenz und sprachliche Richtigkeit bleiben ausdrücklich manuell.
- `pipeline/src/sprachpipe/authoring_service.py`: `base_fingerprint` unterstützt
  registrierte Profile; unbekannte Sprachen bleiben Draft-only. `target_findings`
  prüft BR-Tokens exakt gegen den Tokenizer und verlangt bestätigte Wortbindungen;
  ein geliefertes `is_word=false` kann dies nicht umgehen. `validate_draft`
  begrenzt BR auf ordinary und verlangt einen payload-/profil-/policygebundenen
  lokalen Review. Nur der exakt leere BR-Seed ergibt in `release_parent_id`
  einen null-Parent; ein bloßes Versionspräfix genügt nicht. en-Semantik erhalten.
- `pipeline/src/sprachpipe/editor/service.py`: bestehende ausdrückliche
  Reviewaktion bindet BR-Profil/Policy; Datei-Reviewbehauptungen bleiben unwirksam.
  `publish_release` prüft eigenen BR-Kanal/Profil und bestehende Basisgleichheit.
  `editor/web/app.js::review` nennt die manuellen BR-Pflichten vor Bestätigung.
  Keine mobile UI-Änderung.
- `lib/domain/language_profile.dart`: genaue BR-Readerfähigkeit/Hash.
  `context_revision_validation.dart` benötigt keinen Sonderzweig: vorhandener
  profilgebundener Revisionscheck funktioniert unverändert.
- `supabase/functions/_shared/content_distribution.ts`: exakte Allowlist en/pt-BR,
  sprachgebundene Publisher-Kanalabfrage, null-Parent für ersten BR-Start;
  englische Sonderadoption bleibt en-only. `content_verification_steps.ts`
  prüft BR-Reviewbindung und Profil des eigenen veröffentlichten Parents.
  Authentisierung, Leserrechte, native Stufen, Run/Lease/Resume, Objekthashes,
  SQL-Transaktionen und CAS wurden nicht ersetzt oder abgeschwächt.
- `annotate.py`, `linter.py`, `editor/publisher.py`, Datenbankschema und
  Produktionsassets bleiben unverändert; bestehende Schnittstellen reichen aus.
  Kein `language_definition`, kein neuer Austauschmodus.

## Synthetische technische Abnahme

`pipeline/tests/portuguese_fixture.py` erstellt ausschließlich ausdrücklich
synthetische Bindungen und Übersetzungsmarker. Der Integrationstest in
`test_editor_service.py` verwendet einen temporären Store und den echten Weg:
Sprache → ZIP/XLSX → Preview/Annahme → technische Prüfung → ausdrücklich
synthetischer Testreview → normaler Bundlebuild. Beide Builds lesen SQLite
vollständig zurück und rufen den echten Dart-Reader auf. Erster Parent null;
zweite Version erhält alten Kontext, IDs und Registry.

Die daraus gewonnenen kleinen Quellen unter `test/fixtures/portuguese_release/`
werden gemeinsam von Dart und Deno benutzt. Sie sind **keine veröffentlichbaren
redaktionellen Inhalte**. Reproduktion: den Integrationstest mit
`--basetemp build/portuguese_package_1/bundle-test` ausführen; JSON aus den beiden
synthetischen Bundleordnern, SQL via Python `sqlite3.Connection.iterdump()`.
Keine Produktionsdatei wird dazu verwendet oder ersetzt.

Goldens/Negativfälle: ã/õ/ç, Akzenterhalt, NFC/NFD-Identität, do/na, Satzzeichen,
Emoji vor Lücke, zusammenhängende Mehrwortlücke, Teilgrenzen, Wiederholungen,
fehlende/vorgeschlagene Bindungen, falsche Wortflags, Formstapel, pt/pt-PT,
sprachgetrennte IDs und eingefrorene englische ID-Vektoren. Dart prüft gültiges
BR-Angebot, falsche Sprache/Profil, aktuelle und historische Revision sowie
Codepoint→UTF-16-Offsets (5..9 → 6..10).

Deno prüft tatsächlich ersten BR-Kanal und Folgerelease, falschen en-Parent,
falsches Parentprofil, fehlende Readerrechte, Reviewbindung und Historienverlust.
Run-/Lease-/CAS-/Resumeweitergabe wird im echten Handler gegen isolierte
Backenddoubles geprüft. Das ist **kein neuer PostgreSQL-Concurrency-/Cloudnachweis**;
SQL und dessen bestehender Vertrag bleiben unverändert.

## Laufzeit und Befehle

Keine verwendbare Deno-Laufzeit auf PATH, in `~/.deno/bin`, `/opt/homebrew/bin`,
`/usr/local/bin` oder den geprüften lokalen Werkzeugverzeichnissen gefunden.
Mit erteilter Downloadfreigabe installiert: offizielles **Deno 2.5.4**,
aarch64-apple-darwin; V8 14.0.365.5-rusty, TypeScript 5.9.2.
Quelle: `https://github.com/denoland/deno/releases/download/v2.5.4/deno-aarch64-apple-darwin.zip`
plus `.sha256sum`. Archivhash geprüft:
`ff301a55e9f51306c02eb6da76ceba6ac98109fd11dbd7a1f5b71f5794ad725c`.
Nur Binary unter `build/portuguese_package_1/tools/deno`; keine PATH-/Shell- oder
Systemänderung. Keine Projektdateien/Zugangsdaten übertragen, keine npm-Downloads.

macOS, Repository-Root:

```sh
pipeline/.venv-macos/bin/python -m pytest pipeline/tests/test_language_profiles.py pipeline/tests/test_editor_exchange.py pipeline/tests/test_editor_xlsx.py pipeline/tests/test_editor_service.py pipeline/tests/test_editor_publisher.py pipeline/tests/test_ids.py -q
pipeline/.venv-macos/bin/python -m pytest pipeline/tests -q
build/portuguese_package_1/tools/deno test --no-remote --allow-read supabase/functions/_shared/content_distribution_test.ts supabase/functions/_shared/content_verification_steps_test.ts
```

Windows/PowerShell: dieselben Pythonargumente mit
`pipeline\.venv\Scripts\python.exe`; für Deno denselben Testbefehl mit einer
lokal installierten offiziellen Windows-Laufzeit `deno.exe`. Die hier geladene
Mac-Binary ist keine Windows-Laufzeit. Kein Windows-PASS behauptet.

Plattformgleiche Befehle:

```text
flutter test --no-pub test/data/portuguese_profile_test.dart
flutter test --no-pub test/data/content_context_revisions_test.dart
flutter test --no-pub test/data/real_pack_test.dart
flutter analyze --no-pub
dart run tool/stage_content_pack.dart --verify
node --check pipeline/src/sprachpipe/editor/web/app.js
node pipeline/tests/editor_verification_ui_test.cjs
git -c core.whitespace=cr-at-eol diff --check
git -c core.whitespace=cr-at-eol diff --cached --check
```

Logs unter `build/portuguese_package_1/`; alle folgenden Exitcodes tatsächlich beobachtet.

| Prüfung | Tatsächlicher Output | Exit |
|---|---|---|
| Gezielte Python-Profil/Editor/ZIP/XLSX/Publisher/IDs | `69 passed in 27.61s` (vor zusätzlichem Wortflag-Negativtest) | 0 |
| Finale Profiltests | `8 passed in 1.38s` | 0 |
| Echte temporäre Erst-/Folgebundles + Dart-Reader | `1 passed in 11.20s` | 0 |
| Pipeline vollständig, final | `596 passed, 1 skipped, 19 subtests passed in 169.94s` | 0 |
| Deno, final | `ok | 15 passed | 0 failed (89ms)` | 0 |
| Flutter BR-Profil/Angebot/Reader | `00:00 +3: All tests passed!` | 0 |
| Flutter Kontextrevisionen | `00:01 +3: All tests passed!` | 0 |
| Echter Packtest | `00:15 +1: All tests passed!` | 0 |
| Flutter Analyse | `1 issue found` – ausschließlich bekanntes avoid_print, baseline_adoption_pack_test.dart:43:7 | 1 |
| Stage-Verifier | Schema 4, 26.198.016 Bytes, `22 table counts match finalization_report.json` | 0 |
| JS Syntax | kein Output | 0 |
| Zusätzlicher alter JS-Verifikations-UI-Test | `ReferenceError: adoptPublishedBase is not defined` | 1 |
| Derselbe JS-Test gegen unverändertes HEAD in Tempverzeichnis | derselbe ReferenceError | 1 |
| Altprofilprobe aus HEAD | `UnsupportedLanguage` für pt-BR (erwarteter Negativnachweis) | 1 |
| Temporärer Export und echte Vorlage + separater Verifier | `PASS: existing ZIP/JSON/XLSX verifier, schema, source/profile/context hashes, 20 empty refs` | 0 |
| Archiv gegen echten Seed/Head und Backup | `all 64 pre-existing files byte-identical; no words reserved` | 0 |
| CRLF-Diffcheck | kein Output | 0 |

Der Python-Skip betrifft ausschließlich die opt-in lokale Supabase-Authintegration
(`SPRACHAPP_TEST_LOCAL_AUTH` nicht gesetzt). Ein zusätzlicher Deno-Baselinelauf
meldete 12 PASS/3 ignored: drei explizite Bestandsadoptionstests benötigen ein
separat erzeugtes lokales Integrationsbundle. Der angeforderte finale Lauf der
beiden Verteilungsdateien hat **keine** Skips. Keine Cloud-/PostgreSQL-Integration
als bestanden ausgegeben. Der JS-Altfehler wurde nicht durch einen fremden Fix
verdeckt. Historientest zeigte die bestehende Drift-Debugwarnung zu mehreren
Datenbankinstanzen; Assertions bestanden. Packtestbudget unverändert bei 30 s.
Ein ungefiltertes `git diff --check` liest vorhandene CRLF als Trailing-Whitespace;
der dokumentierte Check mit `core.whitespace=cr-at-eol` erhält die Konvention.
Die Gesamtsuite wurde nach dem letzten Rohdaten-Bindungsfix erneut ausgeführt.

## Tatsächlicher Editorstore und Vorlage

Der Editor war zunächst gesperrt. Nach regulärem Beenden durch den Nutzer wurde
die freie Sperre geprüft. Unter exklusiver Prozesssperre vollständige Kopie,
Bytevergleich, danach erneute Prüfung unter Service-Lock vor jeder Anlage.
Kein laufender Job, keine Umgehung der Sperre. Sicherung:
`/Users/ardasayar/Documents/FlutterProjekte/sprachapp/build/portuguese_package_1/editor-backup-8446b1f864794e5f9c8b0b027acdac7a`.

Über vorhandenen `EditorService.create_language` wurde pt-BR/de mit den bestätigten
Anzeigenamen angelegt, anschließend neuer leerer Vorbereitungentwurf
`4040a010-b37e-4132-b9ca-f14a2a63046b` mit genau einer create_deck-Operation „Allgemeine Sprache“.
Keine Zielkarten, Sätze, Wortbesitzreservierungen oder Reviews im echten Store.
**Alle 64 zuvor vorhandenen Dateien** (einschließlich englischer Heads, Entwürfe,
Veröffentlichungsbelege und Bundles) bleiben bytegleich; acht neue Dateien,
keine bestehende Inhaltsdatei ersetzt. `process.lock` ist nur Prozesskoordination
und vom Inhaltsvergleich ausgenommen. Assets und vorhandener Transferordner
zusätzlich über 12 Dateihashes unverändert nachgewiesen.

Aus `EditorService.template` kamen die 20 neuen Zielrefs und der aktuelle
Basis-/Profilkontext. Ergänzt wurden nur vorhandene create_deck/create_target-
Operationen mit leeren Inhaltsfeldern, vollständiger Sourcepack und Vertrag im
freien Kontextobjekt; keine Formatänderung. Archiv neu durch vorhandenen
write_zip/read_delivery/XLSX-/Schema-/Hashpfad geprüft.

- Vorlage: `build/portuguese_authoring_batch_1.zip`.
- SHA256: `8ce10e8edd19d7af39b780b03bceef183722c3cf44a151b973e4ff71848116bd`.
- Tatsächlicher Seed: `empty-pt-BR`, canonical/bytes SHA256
  `5fe98c7c183552e5e6ae708bbb765f75dcef21be41f71d094fac806c25d8f554`.
- Leere Registry SHA256: `629c6f805448faa443955b6fa87880cdc21347d5663e630d9a5ab6cf32063347`.
- Beleg: `build/portuguese_authoring_batch_1.receipt.json` (lokal, nicht committed).
- Status: **gültige Authoring-Vorlage, keine Satzlieferung, kein Lernpack**.

macOS-Ausführung nach Gates (bereits erfolgt, nicht blind erneut ausführen):

```sh
pipeline/.venv-macos/bin/python docs/portuguese-authoring-contract-v1/export_batch.py --prepare
pipeline/.venv-macos/bin/python docs/portuguese-authoring-contract-v1/export_batch.py --verify build/portuguese_authoring_batch_1.zip
```

Windows/PowerShell: identische Argumente mit
`pipeline\.venv\Scripts\python.exe`; nicht auf Windows ausgeführt.
`--prepare` legt einen neuen leeren Vorbereitungentwurf an; zur bloßen erneuten
Prüfung ausschließlich `--verify` verwenden. Bestehendes pt-BR wird nur bei exakt
gleichem leerem Seed, Metadaten und Fingerprint verwendet, sonst Konflikt.
Der alte Planexport wurde nicht als Basis wiederverwendet und nicht ersetzt.

## Übergabe an Redaktion und Inkrement 2

Geltender Liefervertrag: [FORMAT.md](portuguese-authoring-contract-v1/FORMAT.md),
maschinenlesbar `contract.json`; unverändertes v4-Schema im Archiv.
20 Zielrefs sind leere Arbeitsreferenzen, keine Wortreservierungen. Redaktion
liefert später ausschließlich selbst erstellte BR-Texte, deutsche Glossen,
explizite Lemma-/Sense-Refs und Bindungen. Keine IDs raten.

Text zuerst mit `canonical_text` normalisieren, dann genaue Codepointlücke
bestimmen und mit `get_profile('pt-BR').gap` prüfen. Tokens deterministisch mit
`get_profile('pt-BR').tokenize(text,(start,end))` erzeugen. Erst danach manuelle
Semantik ergänzen. Das Profil vergleicht die vollständige Tokenliste; keine
NFD-Offsets auf NFC-Text übertragen. Keine automatische Satz-/Sensegenerierung.

Die vollständige spätere Lieferung als **neuen Entwurf** importieren, nicht an
den leeren Vorbereitungentwurf anhängen (doppelte create_deck-Operation).
Vorbereitungentwurf und vorhandene Entwürfe bleiben dabei erhalten. Erst
technische Prüfung, dann echter manueller Review. Ein Release benötigt weder
englischen Parent noch englische Bestandsadoption. Veröffentlichung/Leserfreigabe
und Deployment erfordern spätere gesonderte Betriebsaktionen.

Inkrement 2 bleibt vollständig offen: sichtbare persistente Sprachwahl,
sprachgebundener Provider-/Updatelebenszyklus, ehrliche Leerzustände,
profilgebundene Antwortprüfung mit erhaltenen Akzenten und Geräteabnahme auf
bestehender Installation. Bis dahin kein portugiesisches Geräte-PASS.

## Zusätzliche Schlussprüfung: beide Importwege

Der empfohlene Operationsweg und der ebenfalls vorhandene v4-Rohtabellenweg
müssen beide eine explizite Wortbindungsbestätigung verlangen. Ein neuer
Negativtest für Rohdaten zeigte zunächst `1 failed in 0.97s`, Exit 1: fehlendes
binding_status wurde durch die bestehende Anzeigeprojektion als bestätigt
behandelt. Die BR-spezifische Prüfung in `materialize_draft` findet jetzt vor dieser
Projektion statt; englische Legacybehandlung bleibt unverändert. Danach acht
Profiltests PASS/Exit 0 und die vollständige Suite 596 PASS/Exit 0 (siehe Tabelle).
Die bereits exportierte Vorlage enthält keinerlei Tokens oder Inhalte und ist
von diesem Negativfall nicht betroffen; Archivbytes und Bindungen unverändert.

Graph-/Commitprüfung: `node .gitnexus/run.cjs analyze --index-only --pdg --force`
Exit 0, GitNexus 1.6.12, Runneridentität Schema 4/current, Index auf
`a1f6e2931ba76584f252329c654bec3b3eedf96d`, keine incompleteReasons.
Pre-Edit-Impacts: Fingerprint/Zielprüfung/Materialisierung CRITICAL,
Validierung/Bundle/Readerprofil HIGH; direkte Import-/Review-/Buildabhängigkeiten
wurden vor Änderungen geprüft und gewarnt. Dynamische Handler mit UNKNOWN wurden
zusätzlich anhand ihrer tatsächlichen Aufrufstellen geprüft.

`detect-changes --scope all --repo sprachlernapp`: 40 Dateien, 131 Symbole,
38 Abläufe, risk critical. Vollständiges Ergebnis aus demselben LocalBackend wie
der CLI: partial=false, truncated=false; Rohdaten unter
`build/portuguese_package_1/graph-changes.json`. Betroffen sind erwartete
Import-/Materialisierungs-/Review-/Publikations-/Readerpfade und der neue
Vorlagenhelfer, keine mobile Sprachwahl. Die Pipeline-, Historien- und
Verteilungstests sichern diese gemeinsamen Pfade ab. Der Index selbst nennt
weiter begrenzte dynamische Property-/Flowauflösung; dies ist kein Beweis einer
vollständigen Laufzeitanalyse.

Ein inkrementeller PDG-Lauf blieb über drei Minuten in der Importeraktualisierung
bei hoher CPU-Last stehen. Parallel abgefragtes MCP meldete Transport closed,
CLI-Fallback einmal Exit 1 und direkter CLI einmal Exit 139. Nur den eigenen
Indexprozess beendet; vollständiger `--force`-Neuaufbau war danach erfolgreich.
Die abschließende Abfrage nutzt den identischen installierten CLI/LocalBackend,
keinen älteren Graph. Keine Änderung am GitNexus-Produkt oder Installation.

Nur eigene 40 Quell-/Test-/Vertragsdateien werden isoliert committed. Build-ZIP,
Sicherung und Belege bleiben lokal; der fremde untracked Ordner
`published-baseline-transfer/` bleibt unberührt und ungestagt. Kein Push.
