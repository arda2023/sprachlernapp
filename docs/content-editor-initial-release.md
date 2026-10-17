# Erste private Cloudversion aus dem internen App-Bestand

## Native Stufenprüfung lokal implementiert · 17.10.2026

Dieser Abschnitt ersetzt den unten historisch erhaltenen offenen Implementierungsauftrag.
Die produktive Function verwendet jetzt dauerhafte native Stufen; der vollständige
lokale Handler erreicht mit echten Auth-/DB-/Storage-Diensten `ready` und veröffentlicht
isolierte Testversionen. **Keine Cloudmigration, kein Deployment und kein Cloud-Finalize
wurden ausgeführt. Keine Cloudreserve oder Geräteabnahme ist damit belegt.**

### Implementierung und Integrität

- F0–F8 prüfen alle neun Dateien vollständig auf Größe und Bytehash. M prüft Manifest,
  Sidecars, Reviewbindung beziehungsweise den unveränderten Bestandsbeleg. P_full prüft
  Packscope und kanonischen Vollhash; P_content prüft nur bei Bestandsübernahme den
  normalisierten Inhalt, Quellenzeitstempel und SQLitepin. H prüft Registry und echte
  Parenthistorie. A liest keine Inhaltsdateien und übernimmt ausschließlich Metadaten.
- `content_verification_steps.ts` enthält die extrahierte vorhandene Fachprüfung.
  Der Referenzwrapper verwendet dieselben Funktionen; der Produktionsabschluss ruft
  keinen vollständigen `verifyBundle` auf. Jeder spätere Dateiread prüft erneut Größe
  und SHA. Es gibt weder Snapshotablage noch Streamingparser noch Inhaltscache.
- Neue Migration `20261018000001_content_verification_runs.sql` (Name vorher frei):
  Upload-/Owner-/Manifest-/Deskriptor-/Generation-/Parent-/Verifierbindung, ein aktiver
  Run, 90-Sekunden-Lease, Revision und Ergebnisfingerprint. Claim/Finish sperren zuerst
  den Upload. Gleiche Finish-Wiederholung ist idempotent; alte Leases/Runs werden
  abgewiesen. A und `ready` werden atomar geschrieben. Commit verlangt den vollständigen
  gültigen Run und erhält Generation-/Parent-CAS, Locks und Auditidempotenz.
- Jeder Aufruf authentisiert erneut und prüft Publisher/Owner. RPC ist ausschließlich
  für `service_role` ausführbar; selbst diese Rolle hat keine direkten Run-Schreibrechte.
  SECURITY DEFINER verwendet einen leeren search_path. Der neue Uploadtrigger blockiert
  auch alte Handler, die `ready` ohne vollständigen Run schreiben wollen.
- Ausdrückliches Resume startet unter derselben Upload-ID einen neuen, 24 Stunden
  gültigen Run. Actor, Zeitpunkt und Request-ID werden protokolliert, alte Ergebnisse
  verworfen und alte Worker entwertet. Das originale Upload-`expires_at` bleibt gleich;
  Finish und Commit verwenden die neue Runfrist. Abgelaufene Uploads erhalten keine
  neuen Upload-URLs. Storage-/Downloadcode und administrative Vertrauensgrenze bleiben
  wie unten beschrieben; privilegierte Inhaltsmutationen sind weiterhin ausgeschlossen.
- Editor: `service.py`, `server.py` und `web/app.js` ergänzen GET des Serverfortschritts
  und ausdrückliches Resume. Eine Aktion führt höchstens 16 sequenzielle Stufenaufrufe
  aus, stoppt bei jedem Fehler/546 und veröffentlicht niemals automatisch. Neustart
  liest den Serverstand. Veröffentlichen bleibt eine eigene bestätigte Aktion.

### Vollständiger lokaler Nachweis und Ressourcen

[Maschinenlesbare Messwerte pro Stufe](evidence/content-editor-initial-release/native-verification-v2.json).
Edge Runtime `supabase/edge-runtime:v1.77.1`, 256 MiB, CPU soft 1000/hard 2000 ms,
Wall 150000 ms; `oneshot` und `per_worker`, unveränderte Limits. Separater Stack
`sprachapp_native_v2`, API 127.0.0.1:55421, DB-Container gleichen Projektnamens,
Testgateway 127.0.0.1:54998. Der vorhandene Stack `sprachapp` wurde nicht zurückgesetzt.
Die Konfiguration wurde aus `supabase init --workdir build/native_verification/stack`
erzeugt (project_id geändert; Standardports 54320–54329 um 1100 erhöht; Inspector 8183),
Repo-Migrationen kopiert, leeres Seed verwendet und mit `supabase start --workdir
build/native_verification/stack` gestartet (Exit 0).

Originalbundle: `088f5eab-7347-406f-b9e6-cf5dbb985990`, Pack 50.083.067 Byte,
SQLite 43.085.824 Byte; vollständige Dateihashes stehen in der Evidenz. Der normale
Folgerelease ist eine isolierte Testkopie mit neuer Version, kompakter JSON-Darstellung
und **synthetischem Testreview**, keine behauptete menschliche Sprachfreigabe.
Sein Parent ist die zuvor tatsächlich lokal veröffentlichte Bestandsversion.
Beide Pfade wurden mit dem alten Validator aus `fe6e7ad` auf exakt gleiche Endmanifeste
und Manifesthashes verglichen; dieselben Uploaddaten liefern identische IDs/Zeitwerte.
Beide Workerpolitiken bestanden Übernahme → Publish → echter Parent-Folgerelease → Publish.

| Lauf | Stufen | CPU frisch, Summe | Handler-Wall, Summe | Backendbytes / Aufrufe |
| --- | ---: | ---: | ---: | ---: |
| Übernahme frisch | 14 | 1748 ms | 2968 ms | 237.027.692 / 91 |
| Normal frisch | 13 | 1252 ms | 2278 ms | 171.086.501 / 85 |
| Übernahme wiederverwendet | 14 | nur Containerdelta: 2395 ms | 2635 ms | 237.027.722 / 91 |
| Normal wiederverwendet | 13 | nur Containerdelta: 1781 ms | 2028 ms | 171.086.500 / 85 |

Diese Summen verteilen sich auf getrennte Requests; sie sind kein Einzelrequestbudget.
Frische Worker: Übernahme P_full **656 ms / 152,9 MiB**, P_content **549 ms / 152,9 MiB**;
normal P_full **590 ms / 127,6 MiB**. Wiederverwendet: entsprechende Containerdeltas
714,5 / 800,7 / 696,0 ms und beobachtete Speicherwerte 153,4 / 153,3 / 128,1 MiB.
**Die Reserveziele 500 ms/128 MiB sind teilweise verfehlt.** A benötigt frisch nur
16 ms (Übernahme) beziehungsweise 19 ms (normal), ohne Inhaltsread. Keine gesamte
Packverarbeitung im Abschluss. Alle F-/M-/H-Stufen stehen einzeln in der Evidenz.

Frische CPU-Werte stammen aus den geordneten Shutdown-Ereignissen (ein Worker pro
Request). Bei Wiederverwendung sind pro Stufe nur Container-CPU-Deltas verfügbar,
einschließlich Gateway/Messaufwand; Worker werden auch regulär recycelt. Speicher ist
`heapUsed + external` an Messpunkten, **keine garantierte Spitze**. Handler-Wall schließt
die Docker-Messkommandos des Treibers aus. Auth-/DB-/Storage-Bytes sind enthalten.
Der instrumentierte Produktionshandler benutzt echte Dienste; das lokale Gateway
ersetzt das Cloudgateway. Cloudhardware, Authlatenzen, Runtime 1.77.0 des früheren
Cloudabbruchs und tatsächliche Cloudlimits sind hiermit nicht reproduziert.

Der vollständige Negativlauf prüfte falschen Owner, unvollständigen Commit, Rechteentzug,
RPC-/Tabellenschreibverbote, parallele Claims, alte Lease, verlorene Finish-Antwort,
geänderte Wiederholung/Identität, Ablauf, explizites Resume und tatsächlichen Parent-/
Generationkonflikt. Eine ausschließlich im Testworker eingebaute CPU-Schleife brach
wirklich mit HTTP 546 ab: Event `UncaughtException`, `cpu_time_used=2015`, Zeitpunkt
2026-10-17T09:51:10.618Z (kein erfundener CPUTime-Shutdown). Fortschritt blieb unverändert;
nach Ablauf der echten 90-Sekunden-Lease gelang eine ausdrücklich ausgelöste Fortsetzung.
Ein alter Finish wurde abgewiesen. Abgelaufenes `ready` konnte nicht veröffentlichen;
Resume + vollständige Neuprüfung + isolierter Publish gelangen bei unverändertem
ursprünglichem Uploadablauf. Der Editor prüft Abbruch ohne automatische Wiederholung.
UI-Nachweis: echte JS-Funktion im DOM-Harness, keine reale Geräteabnahme.

### Tatsächliche Befehle, Outputs und Exitcodes

Aus dem Repository unter Windows PowerShell, ohne zusätzliche Geheimnisse auszugeben:

```powershell
deno test --allow-read supabase/functions/_shared/content_distribution_test.ts supabase/functions/_shared/content_baseline_adoption_test.ts supabase/functions/_shared/content_verification_steps_test.ts
# 15 passed | 0 failed (9s), Exit 0
pipeline\.venv\Scripts\python.exe -X utf8 -m pytest pipeline/tests/test_editor_publisher.py -q --tb=short
# 23 passed in 8.13s, Exit 0
pipeline\.venv\Scripts\python.exe -X utf8 -m pytest pipeline/tests/test_editor_publisher.py pipeline/tests/test_editor_http.py -q --tb=short
# 26 passed in 11.38s, Exit 0
node pipeline/tests/editor_verification_ui_test.cjs
# PASS: server progress, restart status, explicit resume, separate publish, Exit 0
node pipeline/tests/editor_password_ui_test.cjs
# PASS: masked password / autocomplete / explicit OTP / safe retry / field clear / no storage, Exit 0
node --check pipeline/src/sprachpipe/editor/web/app.js
# keine Ausgabe, Exit 0
pipeline\.venv\Scripts\python.exe -X utf8 pipeline/tests/verification_v2/native_integration.py --bundle "$env:LOCALAPPDATA/SprachappContentEditor/bundles/088f5eab-7347-406f-b9e6-cf5dbb985990"
# 17 Nachweise, 383 Treiberrequests, 179.62 s, Exit 0; integration-3.log
pipeline\.venv\Scripts\python.exe -X utf8 pipeline/tests/verification_v2/native_integration.py --flows-only --bundle "$env:LOCALAPPDATA/SprachappContentEditor/bundles/088f5eab-7347-406f-b9e6-cf5dbb985990"
# beide vollständigen Flows/Workerpolitiken, 219 Requests, 52.89 s, Exit 0; final-flows.log
pipeline\.venv\Scripts\python.exe -X utf8 pipeline/tests/verification_v2/migration_check.py
# PASS: fresh migration; client RPC denied/server RPC allowed/direct run update denied; legacy ready and commit blocked. Exit 0
```

Logs unter `build/native_verification/`; persistente bereinigte Messwerte siehe Evidenz.
Der Migrationscheck erzeugt und entfernt eine eigene temporäre Datenbank im dedizierten
Testcontainer. Auf macOS dieselben Deno-/Node-/Supabase-Befehle; Python jeweils
`pipeline/.venv-macos/bin/python -X utf8`, Bundle über `--bundle "/absoluter/Pfad/zum/Bundle"`.
Historischer `local_probe.py` benötigt nun ausdrücklich `--legacy-reference`; er ist
kein Abnahmenachweis des neuen Produktionsablaufs.

Korrigierte Testaufbaufehler: alter Finalize-Mock erwartete PATCH statt Run-RPC;
PostgREST liefert PV409 direkt als HTTP 400 (Function übersetzt 409); Neustarttest musste
die erste Editorinstanz schließen; JS-Harness musste echte konstante Helper respektieren
und den unbeteiligten Adoptionscallback bereitstellen. Der frische Migrationsharness
benötigte zusätzlich `storage.buckets.file_size_limit`. Die jeweiligen ersten Läufe
hatten Exit 1, die oben genannten korrigierten Läufe Exit 0; keine fachliche Assertion
oder Ressourcengrenze wurde zur erfolgreichen Prüfung gelockert.

### Änderungsprüfung und geschützter Bestand

`git diff --cached --check`: keine Ausgabe, Exit 0. Python-Kompilierung der drei
Mess-/Migrationsskripte: Exit 0. 37 gesicherte SHA-256-Werte unverändert (echte
Editor-Daten, Bundle, Assets, Anker und alle alten Migrationen). Fremder Diff identisch;
NEXTSTEPS bewahrt die fremden Anteile und hat 25 Zeilen. Der dedizierte Teststack wurde
mit `supabase stop --workdir build/native_verification/stack` gestoppt (Exit 0,
`project_id_filter=sprachapp_native_v2`, Backup erhalten); die zwölf vorhandenen
`sprachapp`-Container laufen weiter.

GitNexus vor Edit: Dateireferenzen Distribution → beide Function-Einstiege und Tests,
Service → Server; symbolbezogene UNKNOWN-Ergebnisse wurden durch direkte Aufrufprüfung
ergänzt. Abschließend `node .gitnexus/run.cjs analyze --index-only`: Exit 0, 19.425 Knoten,
42.577 Kanten. `detect_changes(scope=all/staged, limit=10000)` über LocalBackend:
Exit 0, jeweils partial=false/truncated=false; all 147 Symbole/36 Dateien, staged
134 Symbole/20 Dateien, 302 betroffene Prozesse, **CRITICAL**. Diese Warnung wurde
geprüft, nicht zu LOW umgedeutet. 879 gemeldete Prozessschritte tragen pauschal den
Testvariablennamen `published`, zwei `json`; die Prozesszuordnung ist daher als
Abhängigkeitsnachweis eingeschränkt. `context(publish_release)` erfasst den Service,
aber nicht den dynamischen HTTP-Aufrufer. Direkte Prüfung bestätigt Serverroute →
Service/Job → Publisher → Auth/Storage/Run-RPC; Produktions-finalize ruft nur eine
verifyStage auf, verifyBundle bleibt Referenz-/Testpfad. SQL-, HTTP-, UI- und echte
Parentintegration decken diese Grenzen gezielt ab. Graphlogs:
`build/native_verification/graph-{all,staged}.json`; kein behaupteter risikofreier Graph.

### Spätere Cloudumstellung und genaue Bedienung (hier nicht ausgeführt)

1. Gesondert die neue Migration **und** das passende `content-publish` freigeben.
   Keine Serverprüfung mit einer gemischten Version starten. Folgende CLI-Befehle sind
   auf Windows und macOS gleich; Dry-run muss ausschließlich die erwartete neue Migration
   `20261018000001_content_verification_runs.sql` zeigen, sonst anhalten:
   `supabase db push --project-ref yevntxclpchapacqdizm --dry-run --skip-vault`.
2. Erst danach `supabase db push --project-ref yevntxclpchapacqdizm --skip-vault`, dann
   `supabase functions deploy content-publish --project-ref yevntxclpchapacqdizm`.
   JWT-Prüfung beibehalten. `content-release`/Appdownloads benötigen kein Deployment.
   Migration zuerst: alter Handler kann zwischenzeitlich kein neues ready/Commit ohne
   Run erzeugen; bereits veröffentlichte Katalogdaten und Audit-Wiederholungen bleiben
   kompatibel. Function zuerst würde an fehlenden RPCs scheitern. Wartungsfenster für
   neue Prüfungen/Publikationen einhalten; ein Rückrollen nur der Function genügt nicht.
3. Editor beenden und mit vorhandener Konfiguration neu starten: Windows
   `pipeline\.venv\Scripts\python.exe -X utf8 -m sprachpipe.editor`; macOS
   `pipeline/.venv-macos/bin/python -X utf8 -m sprachpipe.editor`.
4. Anmelden → **Versionen** → vorhandene `story_single_sentence_v1-internal-baseline`.
   Serverstatus wird gelesen. Bei gültigem Run **2 · Prüfung fortsetzen** (beziehungsweise
   **2 · Serverprüfung**) einmal klicken. Bei `resume_required` **Prüfung ausdrücklich
   wiederaufnehmen → Neuen Prüflauf bestätigen**. Dies prüft denselben Upload
   `dc4eb268-b9d1-4278-839d-0176d0db2f40`; weder neue Übernahme noch **1 · Privat hochladen**.
   Bei 546/Fehler stoppen und Diagnose auswerten. **3 · Veröffentlichen** bleibt gesondert
   und wurde für die Cloud in diesem Auftrag nicht freigegeben.


## Präzisierte Entscheidung: bestehendes Storage, native Packschritte · 17.10.2026

**Dieser Abschnitt ersetzt Entscheidung B und die Snapshot-Empfehlung des
vorherigen Machbarkeitsberichts.** 500 ms CPU/128 MiB sind unsere Reserveziele,
keine nachgewiesenen harten Cloudgrenzen. Ihre Verfehlung beweist nicht, dass
eine fachliche Aufteilung unbrauchbar ist. Empfehlung: vorhandenes Storage und
Appdownloads beibehalten; native Packhashes in getrennten, serverseitig
fortsetzbaren Schritten prüfen. Den erprobten Streamingparser nicht übernehmen.
Keine zweite Dateiablage, neue Downloadarchitektur oder Produktionsmigration
wurde angelegt. Die Umsetzung des unten begrenzten Auftrags ist noch offen.

### Tatsächliche Vertrauensgrenze

| Akteur | Vorhandene Möglichkeiten / Nachweis |
| --- | --- |
| Normaler Nutzer | Keine Client-RLS-Policies für content-private; keine direkten Freigabe-/Uploadtabellenrechte. Keine erfolgreiche Änderung vorhandener Bytes nachgewiesen. |
| Authentisierter Publisher | Darf über die Function einen eigenen Upload beginnen und prüfen. Keine zusätzlichen direkten Storage-UPDATE-/DELETE-Rechte. Lokale Updateprobe HTTP 400; DELETE HTTP 200 mit leerer Liste, danach unveränderte Bytes. |
| Inhaber einer signierten Upload-URL | Darf den festgelegten Key initial befüllen. Vorhandener Key mit derselben URL HTTP 400, auch mit x-upsert:true. Lokaler Token hat 7200 s Laufzeit. |
| Regulärer Servercode | Erzeugt zufällige Upload-UUIDs, feste Dateinamen, upsert:false. Kein Anwendungs-UPDATE/DELETE oder Pfadrecycling gefunden. Verifizierte Dateien werden beim Start nicht neu signiert; ready/published erhalten keine Upload-URLs. |
| Inhaber des Service-Role-Schlüssels | Kann Storage umgehen/ändern/löschen; lokale Gegenprobe bestätigt das. Diese privilegierte Rolle kann außerdem Freigabetabellen schreiben. Sie gehört zur vertrauenswürdigen Serveradministration, nicht zum gewöhnlichen Publisher. |
| Datenbank-/Projektadministrator | Kann Rechte, Code, Anker, Katalog oder Schlüssel ändern. Nicht durch diese Inhaltsprüfung gegen einen böswilligen Administrator absicherbar. |

Die vorige Kombination „Service-Role löscht, alte URL legt neu an“ setzt zuerst
einen **privilegierten Eingriff** voraus. Sie ist kein nachgewiesener normaler
Nutzerangriff. Ein neuer Snapshot in derselben administrierten Datenbank würde
diese umfassende Administrator-Vertrauensgrenze ebenfalls nicht beseitigen.
Der Schutzvertrag lautet deshalb: keine administrativen Inhaltsmutationen an
aktiven Upload-/Releasepfaden, keine Wiederverwendung dieser UUID-Pfade, keine
neuen regulären Schreib-/Cleanupwege an versiegelten oder als Parent benötigten
Objekten. Die serverseitigen Schlüssel bleiben ausschließlich im vertrauenswürdigen
Backend. Diese Grenze muss bei künftigen Wartungsfunktionen erneut geprüft werden.

Storage-URLs sind laut [Supabase für zwei Stunden gültig](https://supabase.com/docs/reference/javascript/storage-from-createsigneduploadurl).
Die lokale Tokenlaufzeit wurde ohne Ausgabe des Tokens ausgewertet. Der Ablauf
wurde nicht durch zweistündiges Warten getestet. Upsert-Verweigerung schützt
bereits während dieser Zeit; Ablauf allein wäre kein Schutz vor anderen
Schreibrechten. Der bestehende Start prüft vor dem erneuten Signieren noch
nicht `expires_at`; das hebt weder das Überschreibverbot noch die spätere
Finalize-Ablaufsperre auf. Der neue Ablauf soll für abgelaufene Uploads keine
neuen Uploadrechte ausstellen und Resume ausdrücklich trennen.

Prüfgrundlage: `20261017000002_content_distribution.sql` (Clientrechte,
Storage ohne Clientpolicies, unveränderliche Uploadidentität und Katalog),
`content_distribution.ts::publish/object/release` und Publishertransport.
Die Suche nach `content-private`, `/storage/v1/object` und `storage.from`
in Pipeline/Functions/App fand keine zusätzlichen Schreibpfade. Die bestehende
Migration wurde gelesen und bleibt unverändert. Ein Hash oder ein hashhaltiger
Dateiname allein wird ausdrücklich nicht als Schreibschutz bezeichnet.

### Integrität, Veröffentlichung und Verfügbarkeit sind getrennt

- **Zwischen Prüfschritten:** kein erfolgreicher Austausch durch einen
  nicht privilegierten Akteur unter dem vorhandenen Schreibvertrag. Jeder
  erneute Objektread kontrolliert außerdem die immutable Uploaddeskriptoren
  (vollständige Größe/SHA). Ergebnisse binden Upload, Manifest, Deskriptoren,
  Parent und Prüfer-Version. Parentdateien liegen unter eigenen Release-UUIDs
  und werden ebenfalls vollständig gegen ihre Katalogdeskriptoren gelesen.
- **Nach Prüfung:** normale Akteure können die Dateien nicht überschreiben.
  Ein privilegierter Austausch bei unverändertem Katalog führt zu einem
  Hashfehler bzw. fehlendem Download, nicht zu einer gültigen neuen Freigabe.
- **Ungeprüfte Veröffentlichung:** darf nur der bestehende Commit-CAS nach
  vollständigen serverseitigen Ergebnissen erlauben. Der neue Runabschluss
  muss insbesondere ein leeres/teilweises Ergebnis und veraltete Leases sperren.
  Keine lokale Prüfung ersetzt den Serverlauf.
- **Appaktivierung:** `content_release_client.dart` bindet Manifesthash,
  Scope/Schema/Profil/Generation und SQLitegröße/-SHA. `content_update_service.dart`
  hasht den Downloadstream, begrenzt und vergleicht die Bytezahl, prüft anschließend
  Inhalt/Historie und kontrolliert persistierte Dateien vor Nutzung erneut.
  Abweichende Bytes werden nicht aktiviert. Das schützt Integrität, garantiert
  aber keine Verfügbarkeit bei Löschung oder administrativer Beschädigung.

Damit besteht **kein belegter Bedarf für eine zweite Byteablage** innerhalb
dieser Vertrauensgrenze. Administrativ austauschbare Objekte werden nicht als
physisch unveränderlich behauptet. Wenn künftig ein regulärer Delete/Upsert-
oder Recyclingpfad eingeführt wird, ist diese Begründung neu zu führen.

### Begrenzter Streamingversuch: Hashgleichheit, aber Vertragslücke und mehr CPU

Neue isolierte Dateien: `pipeline/tests/verification_v2/stream_pack_probe.ts`,
`stream_pack_probe_test.ts`, `deno.json`, `deno.lock`. Testabhängigkeit
`stream-json@1.9.1`, transitiv `stream-chain@2.2.5`, beide **BSD-3-Clause**;
Versionen/Integrität im Lockfile. Paketmetadaten und die mitgelieferte Lizenz
wurden gelesen. Keine Produktionsabhängigkeit installiert. Der Testtreiber
verwendet in der Edge-Runtime die expliziten npm-1.9.1-Importe; das lokale
Deno-2.9.7-Lockformat 5 wird nicht als von Edge-Deno-2.1 unterstütztes Lockformat
ausgegeben. Parser/Assembler selbst importieren kein stream-chain; ihr tatsächlich
ausgeführter Code liegt in der exakt adressierten stream-json-Version.

Der Versuch verwendet den vorhandenen Tokenparser und Assembler; keine eigene
JSON-Grammatik, kanonische Neuimplementierung oder persistierbare SHA entwickelt.
Die Hashes berechnet unverändert das bestehende `digest`. Ein kleiner Adapter
definiert `__proto__` als eigene Datenproperty, bevor der Assembler zuweist;
ohne das würde dessen normale Objektzuweisung von JSON.parse abweichen.
19 Tests vergleichen vollständigen und normalisierten Hash: Schlüsselsortierung
(einschließlich numerischer Keys/UTF-16), Arrayreihenfolge, doppelte Schlüssel
mit letztem Wert, Exponenten/Rundung/-0/Overflow, Escapes, Unicode und Surrogates,
gezieltes Entfernen nur von `release.created_at`, ungültiges JSON und striktes
UTF-8 über Byte-Chunkgrenzen. Zwei zusätzliche Gegenproben zeigen allerdings
eine Vertragslücke: NBSP vor `{}` und U+2028 vor einer Zahl werden akzeptiert,
obwohl `JSON.parse` sie außerhalb von Strings ablehnt. `Parser.js` verwendet
dort das breitere JavaScript-Whitespace-Muster `\s`. Die zwei Tests sind
ausdrücklich Charakterisierung dieser **Blocker**, keine erfolgreiche
Kompatibilitätsabnahme. Kein eigener Vorparser oder stilles Akzeptieren solcher
Sonderfälle; die Übernahme endet hier. Gleichheit der echten Bundlehashes
beweist nicht vollständige Gleichheit der akzeptierten Eingabesprache.

Echte Bundlehashes stimmen in frischen und wiederverwendeten Edge-Workern:

```text
vollständig: 0bce823cbe7f6e1abeb114489a3536659b9bca6ed3ec451fa5692924465bda64
ohne release.created_at: aa2eaf04dceed03c3941dfefc18f09dbc0d5318fd53958a024636e6ac6295a23
```

Der Assembler hält das vollständige Objekt. Das ist **keine allgemein
speicherbegrenzte Kanonisierung**. Beliebig geordnete und doppelte Keys verbieten
es, endgültige Hashbytes vorschnell beim ersten Token auszugeben. Alle Objekte
als sortiert anzunehmen oder Duplikate abzulehnen würde den bisherigen Vertrag
ändern. Ein neuer Sortier-/Checkpointmechanismus wird deshalb nicht begonnen.

### Messung mit echtem Bundle und realem lokalem Backend

Bereinigte Einzelwerte einschließlich beider Workerarten:
[verification-streaming-evaluation.json](evidence/content-editor-initial-release/verification-streaming-evaluation.json).
Abschlusslauf `eba7f36273224026980dbbd5d79f163a`, echte unveränderte Bundlebytes,
GoTrue/PostgREST/Storage/Postgres; Runtime v1.77.1, 256 MiB, CPU soft/hard
1000/2000 ms, Wall 150000 ms. Keine Limits erhöht. Frische Isolates bzw.
Wiederverwendung über per_worker; Cloud-Hardware/Last/Gateway und v1.77.0
bleiben verschieden. Lokales Windows-Deno 2.9.7 dient nur den Vertragstests.

| Frischer Worker | Isolate-CPU ms | Beobachteter Speicher B | Bytes / Backendrequests | Wall ms |
| --- | ---: | ---: | ---: | ---: |
| Native Packparse | 310 | 160.187.317 | 50.089.185 / 4 | 515 |
| Native Strukturprüfung inkl. Lesen/Parsen | 244 | 160.186.861 | 50.089.185 / 4 | 422 |
| Vollständiger nativer Hash + Struktur | 526 | 160.188.869 | 50.089.185 / 4 | 703 |
| Normalisierter nativer Hash + Struktur | 569 | 160.187.349 | 50.089.185 / 4 | 766 |
| Beide nativen Hashes + Struktur | 828 | 160.187.037 | 50.089.185 / 4 | 1000 |
| Streaming nur Tokens | 887 | 19.075.000 | 50.089.185 / 4 | 1078 |
| Streaming plus Assembler | 1256 | 120.682.152 | 50.089.185 / 4 | 1422 |
| Streaming plus beide Hashes | 1845 | 122.456.849 | 50.089.185 / 4 | 2032 |
| Manifest/Sidecars | 137 | 48.026.077 | 11.244.298 / 9 | 250 |
| Registry/Historie | 200 | 63.632.941 | 22.471.534 / 7 | 500 |

CPU stammt aus Supervisor-Shutdown, Speicher aus expliziten Stichproben
heapUsed+external, **nicht Peak**. Bytes enthalten Auth-/Uploadmetadaten.
Reused: native Einzelhashes 719/750 ms Wall, 161.024.477/160.186.469 B beobachtet;
Streaming beide Hashes 2094 ms Wall/128.221.353 B. Reused-CPU pro Request ist nur
als Containerdifferenz messbar (805,2/774,1 bzw. 2883,6 ms), einschließlich
Main-/Messaufwand; keinesfalls als Isolate-CPU oder Beweis eines Limitverstoßes
ausgeben. Worker-Gesamtereignisse stehen separat im Evidenz-JSON.

Vorheriger erfolgreicher Vergleichslauf `645e19a5cf2c4de290b4d10511b0d975`:
native Einzelhashes 548/526 ms, Streaming beide 1948 ms Isolate-CPU. Der
Abschlusslauf ergänzt die Strukturbedingungen auch in den nativen Hashschritten.
Keine fehlgeschlagenen Optimierungsrunden. Schon Tokenisierung allein benötigt
mehr CPU als ein vollständiger nativer Einzelhash. Deshalb endet der
Streamingversuch hier trotz korrekter Bundlehashes und geringerem Speicher.
Die zusätzlichen Whitespace-Gegenproben schließen eine unveränderte Übernahme
auch unabhängig von der Laufzeit aus.

Vollständiger **Originalhandler** mit allen bestehenden Checks: zweimal ready;
letzter frischer Worker 979 ms CPU/1234 ms Wall, wiederverwendeter gesamter Worker
1107 ms CPU (inklusive vorheriger Aufrufe)/letzter Request 1187 ms Wall. Kein
Publish. Vorgeschlagene native Arbeitslastfolge F0–F8/M/P_full/P_content/H:
3999 ms Wall frisch, 3409 ms reused, jeweils 248.164.854 gelesene Backendbytes
und 60 Backendrequests. Darin ist bewusst erneutes Packlesen enthalten; nicht
das ganze Bundle je Schritt. Der spätere kleine Metadatenabschluss ist noch
nicht implementiert und nicht in dieser Summe. Die Sidecar-/Historienproben
sind Arbeitslasten; Historie verwendet echte Daten auf beiden Vergleichsseiten.
**Dies ist noch kein vollständiger neuer gestufter Validator oder normaler
Parent-End-to-End-Lauf.** Die uneingeschränkte fachliche Prüfung dieses Bundles
lief separat im unveränderten Originalhandler, nicht in einer vorgetäuschten
neuen Ready-Freigabe. Diese Implementierungsgrenze bleibt Abnahmebedingung des
konkreten Folgeauftrags.

Gesamter Abschlussversuch inklusive Setup/Originalhandler/Arbeitslasten/17
Zustandsnachweisen/Cleanup: 68,14 s, 180 direkte Treiber-HTTP-Requests; interne
Backendrequests der Arbeitslasten werden zusätzlich separat ausgewiesen.
Alle eigenen lokalen Testobjekte/-nutzer/-zeilen entfernt. 12 vorhandene lokale
Supabase-Container plus jeweils ein Test-Edge-Container; keine Cloudoperation.

Ausgeführt unter PowerShell, Repositorywurzel:

```powershell
npm view stream-json@1.9.1 version license dependencies --json
npm view stream-chain@2.2.5 version license --json
deno test --allow-read --config pipeline/tests/verification_v2/deno.json pipeline/tests/verification_v2/stream_pack_probe_test.ts
pipeline/.venv/Scripts/python.exe -X utf8 pipeline/tests/verification_v2/local_probe.py --streaming --bundle "$env:LOCALAPPDATA/SprachappContentEditor/bundles/088f5eab-7347-406f-b9e6-cf5dbb985990"
pipeline/.venv/Scripts/python.exe -X utf8 pipeline/tests/verification_v2/local_probe.py --storage-only --bundle "$env:LOCALAPPDATA/SprachappContentEditor/bundles/088f5eab-7347-406f-b9e6-cf5dbb985990"
deno test --allow-read supabase/functions/_shared/content_distribution_test.ts supabase/functions/_shared/content_baseline_adoption_test.ts
pipeline/.venv/Scripts/python.exe -X utf8 -m pytest pipeline/tests/test_editor_publisher.py -q --tb=short
```

Relevante Outputs: npm Version/Lizenz wie oben; zunächst Parser `19 passed | 0 failed
(38ms)`, abschließend 21 bestandene Tests einschließlich zweier dokumentierter
Kompatibilitätsblocker; Integration zweimal ready, sämtliche Streamingaufrufe HTTP 200,
`State probes: 16 passed; no publication.` plus anschließender Original-Ablauftest
= 17 Nachweise; `Own fixtures removed`. Storage meldet nicht privilegierten
Austausch abgewiesen, privilegierten Austausch möglich. Deno `12 passed |
0 failed (7s)`; Pytest `21 passed in 5.36s`. **Alle Exit 0**. Diagnose-Exit 0
bedeutet weder erreichte Reserveziele noch Cloudfreigabe. Logs:
`build/verification_stream/{parser-tests,parser-tests-final,final,storage,deno,pytest}.log`.
macOS (nicht ausgeführt): `pipeline/.venv/bin/python -X utf8` und expliziter
absoluter Bundlepfad statt `$env:LOCALAPPDATA/...`; npm/Deno identisch.

Abschluss: `git diff --cached --check` und gezieltes `git diff --check` ohne
Befund, Exit 0; 55 geschützte Dateien hashgleich, fremder Diff/Text erhalten,
NEXTSTEPS 25 Zeilen. GitNexus-Dateiimpact: Bericht LOW/3 Bezüge;
Testtreiber/Worker UNKNOWN, zusätzlich per Textprüfung keine Produktionsimporte.
Graph nach Reindex (`analyze --index-only`, Exit 0): `detect_changes` all/staged
ohne partial/truncated-Antwort, Exit 0, aber **CRITICAL**; staged neun Dateien,
18 Symbole/303 gemeldete Prozesse. Alle betroffenen Prozessschritte heißen
`tokens`, ein generischer Name des neuen lokalen Zählers. Diese breit
zugeordneten Graphbezüge und die bekannten Index-Erfassungsgrenzen sind keine
Produktionsrisikofreigabe. Die Abgrenzung beruht zusätzlich auf unveränderten
Produktionshashes, fehlenden Produktionsimports und den lokalen Tests.

### Konkreter nächster Implementierungsauftrag

**Native fachliche Stufen mit bestehendem Storage implementieren.** Kein
Streamingparser und keine Snapshotablage im Produktionspfad. Die vollständige
Prüfzuordnung im vorigen Abschnitt bleibt verbindlich; keine fachliche Prüfung
entfällt. Aus `verifyBundle` dieselben Bedingungen extrahieren, nicht eine
zweite unabhängige Validierungslogik neben ihr pflegen.

Dateien: `supabase/functions/_shared/content_verification_steps.ts` (neu),
`supabase/functions/_shared/content_distribution.ts`, `content-publish/index.ts`,
neue additive Migration `supabase/migrations/20261018000001_content_verification_runs.sql`,
`pipeline/src/sprachpipe/editor/publisher.py`; gezielte Tests in
`content_distribution_test.ts`, `content_baseline_adoption_test.ts`, neuer
`content_verification_steps_test.ts` und `pipeline/tests/test_editor_publisher.py`.
Appdownloadcode, Quellenanker, Bundleformat und bestehende Migration bleiben
unverändert. Kein `content_verification_storage.ts` und keine Byte-Snapshottabelle.

1. `pending → verifying`: autorisierter Start friert Runidentität ein:
   Upload-ID/Owner/Manifesthash/Deskriptorhash/Generation/Parents/Prüferversion.
   UUID-Pfade werden nicht recycelt. Bereits vorhandenes `verified_objects`
   wird nur nach expliziter Bindungsprüfung übernommen; konservativ erneut
   hashprüfen ist erlaubt, Neu-Upload nicht erforderlich.
2. `F0…F8`: vorhandene begrenzte Datei-Hashprüfungen. Danach `M` für
   Manifest/Sidecars/Review/Adoptionsbeleg; `P_full` für Packscope/Struktur und
   vollständigen kanonischen Hash; `P_content` für den normalisierten
   Adoptionshash samt exakt festem Zeitstempel/Quellenvergleich (bei normalen
   Releases explizit nicht erforderlich); `H` für Registry/Parenthistorie.
   P_full und P_content laden jeweils nur das Pack, nicht die Sidecars erneut.
   Keine gleichzeitigen großen Reads. Normaler Parentpfad bleibt Pflichtabnahme.
3. Jeder Aufruf authentisiert/autorisiert erneut, claimt genau einen Schritt
   mit Revision/Lease und schließt ihn atomar mit Ergebnisfingerprint ab.
   Workerabbruch lässt den Schritt offen. Wiederholung desselben Finish ist
   idempotent; alte Lease oder anderes Ergebnis wird abgewiesen. Keine Rekursion
   oder automatische 546-Wiederholung; UI führt kontrolliert fort.
4. `verifying → ready`: kleiner Abschluss liest nur Metadaten und vollständig
   gebundene Schrittresultate, erzeugt finales Manifest/Hash und setzt ready
   atomar. Fehler → failed; Ablauf → ausdrücklicher Resume erforderlich.
   Kein nochmaliges vollständiges `verifyBundle` in diesem Abschluss.
5. Resume unter derselben Upload-ID: eigene autorisierte/auditierte Runfrist,
   unverändertes ursprüngliches expires_at. Rechte, Identität und Verifier neu
   prüfen; konservativ neuer Run ohne alte Teilresultate. Migration ergänzt
   den Commitvertrag gezielt um gültige Resume-Autorisierung; niemals pauschal
   Ablaufprüfungen entfernen. Ready allein reicht nicht ohne vollständigen Run.
6. `ready → published`: bestehende Owner-/Publisher-/Generation-/Parent-CAS,
   Kanal-/Uploadlocks, Auditidempotenz und Katalogschutz unverändert plus Bindung
   an genau den vollständig abgeschlossenen, gültigen Prüflauf. Keine normale
   SQL-Schreibmöglichkeit für Clients; nur eng begrenzte serverseitige RPCs.

Abnahme dieses einen Auftrags: sämtliche bisherigen Vertrags-/Negativtests,
native/gestufte identische Endmanifeste für Adoption **und echten normalen
Parentlauf**, echte Bundlebytes mit realem lokalem Auth/DB/Storage, frische und
wiederverwendete Worker, Crash/Parallelität/Lease/Antwortverlust/Rechteentzug,
24-h-Resume und kein Commit mit unvollständigen Ergebnissen. Reserveziele weiter
als Ziele messen und Abweichungen begründen; weder auf 500 ms als Plattformgrenze
bestehen noch einen neuen Cloud-PASS behaupten. Die spätere Cloudabnahme bleibt
ein gesondert autorisierter Vorgang. Vor ihrer erfolgreichen Durchführung gibt
es keine belegte Cloudreserve.

## verification-v2: lokaler Machbarkeitsnachweis · 17.10.2026

**Entscheidung B: Die fachliche Aufteilung allein reicht nicht.** Der echte
Pack benötigt schon beim vollständigen JSON-Parsen rund 153 MiB beobachteten
Speicher. Die getrennten Packhash-Schritte benötigen einschließlich Laden und
Parsen 543 bzw. 519 ms CPU; beide zusammen 820 ms. Damit sind die Zielwerte
500 ms/128 MiB nicht eingehalten. Das beweist keine isolierte SHA-Überlastung.
Zusätzlich fehlt eine dauerhafte Bindung an unveränderliche Storage-Bytes.
Kein Produktionscode, bestehendes Bundle, echter Upload oder Cloudzustand wurde
geändert. Der folgende Prototyp ist keine neue Veröffentlichungsarchitektur.

### Ausführbare, ausschließlich lokale Erprobung

Die vor dem Edit festgelegten Dateien sind:

- `pipeline/tests/verification_v2/local_probe.py`: lokaler Testtreiber und Cleanup.
- `pipeline/tests/verification_v2/main.ts`: Edge-Supervisor für Originalhandler/Proben.
- `pipeline/tests/verification_v2/worker.ts`: getrennte Arbeitslasten und Zustandsproben.
- `pipeline/tests/verification_v2/state.sql`: temporäres Schema und namensisolierte RPC.

Messdaten ohne Zugangsdaten: [verification-v2-feasibility.json](evidence/content-editor-initial-release/verification-v2-feasibility.json).
Der Treiber erzwingt `http://127.0.0.1:54321`; keine Cloud-Ausweichadresse.
Er verwendet tatsächliches lokales GoTrue, PostgREST, PostgreSQL und Storage,
Testnutzer mit echten JWTs sowie zufällige lokale Uploadspiegel. Nur diese eigenen
Nutzer, Objekte, Uploadzeilen und das Testschema werden anschließend entfernt.
Es werden keine `storage.objects`-Zeilen direkt geändert. Die bestehenden
Migrationen bleiben unverändert; das SQL ist ausdrücklich keine Migration.
Die unveränderten Originaldateien `content-publish/index.ts`,
`_shared/content_distribution.ts` und `_shared/internal_baseline_source.json`
werden für den vollständigen Handlerlauf in ein lokales Scratch-Verzeichnis kopiert.

Konfiguration: `public.ecr.aws/supabase/edge-runtime:v1.77.1`, 256 MiB,
CPU soft/hard 1000/2000 ms, Wall-Limit 150000 ms; Docker-Netz
`supabase_network_sprachapp`, Kong intern `http://kong:8000`, Testgateway
`127.0.0.1:54999`. `oneshot` erzwingt frische Worker, `per_worker` erlaubt
Wiederverwendung. Secrets bleiben im Prozessumfeld, nicht in Dateien/Logs.
Die Cloud lief mit Runtime 1.77.0; Hardware, Last, Netzwerk, Gateway, Workerpool
und Scheduling sind nicht identisch. Die Prüfungen hier ersetzen keinen Cloudnachweis.

### Messungen: echtes Bundle, unveränderter vollständiger Handler

Bundle: `088f5eab-7347-406f-b9e6-cf5dbb985990`, 9 Dateien,
114.215.590 Bytes; Pack 50.083.067 Bytes, SQLite 43.085.824 Bytes.
Originalhashes stehen im Evidenz-JSON. Beide vollständigen Durchläufe haben
Start, abgewiesenen vorzeitigen Commit, neun lokale Dateiübertragungen und zehn
Finalize-Aufrufe; beide endeten in `ready`, ohne Veröffentlichung.

| Originalhandler | Summe Finalize-Wall | Letzter Finalize-Wall | Supervisor-CPU | Speicher beim Shutdown |
| --- | ---: | ---: | ---: | ---: |
| Frischer Worker je Aufruf | 2565 ms | 1203 ms | 950 ms letzter Worker | 78.449.789 B |
| Wiederverwendeter Worker | 2234 ms | 1250 ms | 1114 ms gesamter Worker | 11.275.099 B |

Der wiederverwendete Workerwert umfasst auch Start/vorzeitigen Commit; er ist
kein isolierter CPU-Wert des letzten Finalize. Shutdown-Speicher ist **kein Peak**.
Der Originalhandler liest zunächst alle Dateibytes für Einzelhashes und im
abschließenden `verifyBundle` erneut 61.321.247 JSON-Bytes; SQLite und Readerreport
werden dabei nicht erneut geladen. Im Produktionscode wurde nichts instrumentiert.

Für jede getrennte Arbeitslast wurden echter JWT/Publisher/Owner und reale
Storage-Lesezugriffe verwendet. Die CPU-Spalte ist der Supervisorwert eines
frischen Workers. Speicher ist das Maximum der expliziten Stichproben
`heapUsed + external` (vor/nach Reads bzw. Ende), **kein absoluter Peak**.
Bytes enthalten auch Auth-/Uploadmetadaten; Requests zählen die Backendaufrufe
der Arbeitslast. Detaillierte Werte für wiederverwendete Worker stehen im JSON.

| Arbeitsschritt | CPU ms | Beobachteter Speicher B | Gelesene Bytes | Requests |
| --- | ---: | ---: | ---: | ---: |
| Datei SQLite | 62 | 18.061.837 | 43.091.940 | 4 |
| Datei Pack | 69 | 13.734.325 | 50.089.183 | 4 |
| Datei Registry | 16 | 11.841.432 | 1.069.160 | 4 |
| Datei Historie | 29 | 12.179.505 | 10.175.780 | 4 |
| Datei Reviews | 14 | 12.069.801 | 6.119 | 4 |
| Datei Provenienz | 13 | 12.288.458 | 8.691 | 4 |
| Datei Prüfbericht | 13 | 12.179.515 | 7.955 | 4 |
| Datei Manifest | 13 | 12.179.504 | 7.171 | 4 |
| Datei Readerreport | 28 | 19.116.125 | 9.814.635 | 4 |
| Manifest/Sidecars | 132 | 47.898.445 | 11.244.296 | 9 |
| Pack nur parsen | 288 | 160.182.893 | 50.089.183 | 4 |
| Pack vollständiger kanonischer Hash | 543 | 160.183.885 | 50.089.183 | 4 |
| Pack normalisierter Inhaltshash | 519 | 160.182.149 | 50.089.183 | 4 |
| Pack beide Hashes | 820 | 160.183.917 | 50.089.183 | 4 |
| Registry/Historie | 201 | 62.673.037 | 22.471.532 | 7 |

Die Packproben laden nur das Pack, nicht jedes Mal das gesamte Bundle. Der
Historientest verwendet echte Registry/Inventar zweimal als Alt-/Neudaten;
das ist kein vollständiger normaler Release mit echtem veröffentlichtem Parent.
Sidecar-/Historienproben messen repräsentative Arbeit, nicht bereits sämtliche
zukünftigen Stage-Verträge. Sämtliche bisherigen Prüfungen laufen dagegen im
unveränderten Originalhandler und in den bestehenden Vertragstests.
Reused: größter beobachteter Speicher 161.022.781 B; Supervisor-CPU der drei
Arbeitslast-Worker 1029/1295/204 ms. Per-Request-CPU dort nur als Container-
cgroup-Differenz verfügbar, einschließlich Main-/Messaufwand, nicht Isolate-CPU.

Gesamtlauf: 53,91 s, mit Cleanup 54,61 s; 143 direkte Treiber-HTTP-Requests,
mit Cleanup 170. Dazu 68 Backendrequests je Arbeitslastserie (136 insgesamt).
Dies sind getrennte Zähler, keine vollständige Zählung aller dienstinternen
Netzwerkrequests. Zwei lokale Bundleübertragungen à 114.215.590 Bytes;
12 bereits laufende Supabase-Container plus zeitweise ein Test-Edge-Container.

### Vollständige Zuordnung bestehender Prüfungen zum Zielablauf

Diese Tabelle ist der Umsetzungsvertrag, keine Behauptung, dass der Probe-Worker
bereits alle Prüfungen implementiert. F = Datei, M = Manifest/Sidecars,
P = Pack, H = Historie, A = Abschluss. Alle Ergebnisse müssen später dieselbe
versiegelte Snapshotidentität und Prüfer-Version tragen.

| Bestehender Vertrag | Zielschritt, unverändert zu erhalten |
| --- | --- |
| Backend-URL HTTPS bzw. explizit lokal; keine Redirects; Bearer/GoTrue, gültige Actor-UUID, Publisherrecht, Upload-UUID/eindeutiger Eigentümer | Jeder Aufruf, auch Fortschritt/Resume/Commit |
| HTTP-Methode/Route; Body höchstens 1 MiB, striktes UTF-8 und JSON-Objekt | Jeder entsprechender Aufruf |
| Request-UUID, en/internal, ganzzahlige Generation >= 0, Parent-UUID/SHA oder null, bekannte Publikationsart; Adoption nur Generation 0 ohne Parent | Start und Identitätsbindung |
| Manifestformat 2, en/de, Schema 5, Profil-ID/-Hash, internal_test, min_reader 5, erforderliche immutable-contexts-Features, Versionssyntax | Start/M |
| Genau neun Deskriptoren, SHA, positive ganzzahlige Größe, SQLite <= 256 MiB, JSON <= 64 MiB; SQLite-/Packdeskriptoren stimmen mit Manifest überein | Start/F/M |
| Idempotenter Start bindet Objekte, Manifest, Generation, Parent und Scope; Adoption erfordert leeren Kanal; signiert nur fehlende Dateien ohne Upsert | Start |
| Jeder Dateiname/Objektpfad vorhanden, vollständige Bytezahl und SHA stimmen; Größenlimit, JSON strikt UTF-8/parst innerhalb Limit | F0–F8; spätere Leser müssen exakt diese Bytes verwenden |
| Manifest entspricht Uploadentwurf; Report ok/history_superset/internal_test_pack und validation.technical = valid; normal editorial approved, Adoption existing-evidence-only; gültiger Contenthash; findings Array ohne error; Hash der unsignierten validation | M |
| Normal: freigegebene, an Contenthash gebundene Reviews; Adoption: leere neue Reviews; kanonische Review-/Inventar-/Registryhashes; Inventarformat 1/lang/tables | M |
| Adoption-Provenienzformat 1, vollständige erwartete Quelle/Version/Counts/existing_evidence/open_findings/notice/cloud_state/Hash; bestätigter Scope/accepted/Zeitstempel; Adoptionhash in Manifest/Report; Content-/Basishash und SQLitecounts am Quellenanker, findings leer | M-Adoption |
| Packlang, Releaseversion, Schema, Registryhash, Coverage erwartet/verarbeitet und keine widersprüchlichen Referenzen | P |
| Adoption: normalisierter vollständiger Packhash ohne release.created_at am festen Anker; created_at exakt gleich baseline.converted_created_at; SQLite-SHA/-Größe am Anker; Generation 0, en/internal, kein Parent/leerer Kanal | P-Adoption/A |
| Genau ein Parentkatalogeintrag passenden Scopes und Manifesthashes; validation.base_sha256 entspricht kanonischem Parent-Pack | H mit genauso versiegelten Parentbytes |
| pack.word_registry.snapshot.words vorhanden; Alt-/Neuwörter Arrays, neue lang/form_norm eindeutig, jedes alte Wort kanonisch unverändert | P/H |
| Alle alten Inventar-IDs erhalten; vier immutable Tabellen exakt gleiche Rowhashes; Storysnapshots kanonische Obermenge | H |
| Vollständiger kanonischer Packhash einschließlich created_at; endgültiges Manifest entfernt lokale Felder, setzt Release-ID/Kanal/Generation/Parents/created_at und erhält finalen Hash | P → A |
| Alle Prüfungen bestanden, Ablauf/failed-Sperre; vollständiger versionsgebundener Lauf, atomarer Abschluss mit geprüftem Updateergebnis; Adoptionkanal nochmals leer | A |
| Commit: aktuelle Publisher-/Ownerrechte, ready/nicht abgelaufen/verified_objects = objects; idempotente Auditrequest an Actor/Upload; erwartete Generation/Parenthash; Upload-/Kanallocks, aktuelle Generation/Hash/Parent-ID; Manifest-Scope/-ID/-Generation/-Parents stimmen; atomare Katalog/Kanal/Audit/published-Änderung und Unveränderlichkeitsschutz | Bestehender Commit-CAS, erweitert um vollständig versiegelten Prüflauf |
| Reader- und Downloadberechtigungen | Erhalten; Downloads müssen später dieselben unveränderlichen geprüften Bytes liefern |

### Storage: Gegenprobe widerlegt die benötigte Garantie

Für getrennte Upload- und Parent-artige Testobjekte im echten lokalen
`content-private`-Bucket: alter Signed-Upload auf vorhandenen Key HTTP 400,
auch mit `x-upsert:true`; normales Nutzerupdate HTTP 400. Nutzer-DELETE liefert
HTTP 200 mit leerer Ergebnisliste, verändert aber nachweislich keine Bytes.
Das ist **kein erfolgreicher Delete**. Dagegen: Service-Role-Update HTTP 200
und veränderte Bytes; Service-Role-Delete HTTP 200; anschließend erzeugt die
alte signierte Upload-URL unter demselben Key neue Bytes (HTTP 200).
Parent-artig bedeutet hier gleicher Bucket/Schreibschutz, kein neu publizierter
Parentkatalogeintrag. Der Storagezugriff prüft den Katalogstatus nicht.

Anwendungsschreibpfade wurden auf `content-private`, `/storage/v1/object` und
`storage.from` in `pipeline/src`, `supabase/functions`, `lib` geprüft: der
Publisher benutzt den festen Uploadpräfix ohne Upsert; die Function signiert
fehlende Uploads, liest Dateien und signiert Downloads; Flutter liest Downloads.
Kein weiterer Anwendungs-UPDATE/DELETE gefunden. Die privilegierte tatsächliche
Schreibfähigkeit bleibt trotzdem vorhanden. HEAD/ETag/erneutes Hashen vor einem
späteren Read beseitigt diese Austauschlücke nicht.
Das entspricht dem dokumentierten [Service-Key-Bypass von Storage-RLS](https://supabase.com/docs/guides/storage/security/access-control).
[S3-Bucketversionierung ist bei Supabase nicht verfügbar](https://supabase.com/docs/guides/storage/s3/compatibility).
**Dieser Teil stoppt am nachgewiesenen Blocker; keine Storage-Umgehung implementiert.**

### Minimaler Zustand: bewiesen und ausdrücklich nicht bewiesen

Die temporäre RPC bindet Upload, vollständiges Manifest/Deskriptoren,
Generation/Parents und `probe-v1`. Rowlocks, Revision und 2-s-Lease erlauben
genau einen konkurrierenden Claim. Finish akzeptiert nur passende aktive
Lease/Revision; identische Wiederholung nach verlorener Antwort ist idempotent,
veränderte Wiederholung und veraltetes Ergebnis werden abgelehnt. Rechte werden
bei jedem HTTP-/SQL-Aufruf neu geprüft. Ungültiger JWT/falscher Owner/falsche
Prüferversion, Rechteentzug und unversiegelter Abschluss sind negative Tests.

Ein tatsächlicher CPU-Workerabbruch nach dauerhaftem Claim ergab HTTP 546,
ohne weiteren Fortschritt. Nach Leaseablauf war erneuter Claim möglich.
Supervisor meldete CPUTime 3043 ms beim Shutdown; das ist die beobachtete
Durchsetzungslatenz, keine Erhöhung des konfigurierten 2000-ms-Limits.
Vorzeitiger Commit erzeugte keinen Katalogeintrag. Insgesamt 17 benannte
Zustandsnachweise im Evidenz-JSON, zusätzlich Finish-ohne-Lease abgeprüft.

Der **diagnostische** Finish übernimmt Testresultate; er stellt keine
serverseitig versiegelte Inhaltsfreigabe aus. Completion bleibt absichtlich
gesperrt, weil die Storagegarantie fehlt. Dies ist kein produktiver Ersatz-CAS.

24-h-Ablauf: normaler Start mit abgelaufenem Testupload wird abgelehnt.
Explizites `resume_start` benötigt Zustimmung/Scope/eindeutige Request-ID,
protokolliert Actor/Zeit/Anfrage und erzeugt unter derselben Upload-ID einen
neuen diagnostischen Lauf mit eigener einstündiger Testfrist. Wiederholung ist
idempotent. Resume setzt diagnostische Ergebnisse/Leases zurück; ursprüngliches
`upload.expires_at` bleibt unverändert. Auch nach diagnostischem Resume lehnt
der Originalhandler das abgelaufene Uploadobjekt weiterhin ab. Ein produktiver
Resume-Vertrag samt Commitintegration ist somit noch umzusetzen, nicht umgangen.

### Kleinster begrenzter Folgeauftrag, noch nicht implementiert

Zwei voneinander getrennte lokale Proben sind zuerst nötig:

1. **Unveränderliche Bytequelle:** als konkrete Alternative zum nicht
   versionierbaren Storage eine private PostgreSQL-Snapshotablage mit begrenzten
   Bytechunks erproben. Bestehender Upload/Keys bleiben erhalten. Ein Snapshot
   wird erst nach vollständigem rohem Dateihash versiegelt; Update/Delete der
   versiegelten Chunks auch für Anwendung-Service-Rollen durch Rechte/Trigger
   verweigern, nur eng begrenzte Owner-RPCs. Prüfergebnisse und Parentdaten
   binden Snapshot-ID, Dateihash, Manifesthash und Prüfer-Version. Auch spätere
   Downloads müssen aus genau dieser Bytequelle kommen; mutable Storage-URLs
   daneben weiterzuverwenden wäre unzureichend. DBA/Superuser bleiben außerhalb
   dieser Anwendungsintegritätsgrenze. Kosten: weitere 114 MB je Bundle plus
   WAL/Backups und neue Downloadintegration; deshalb erst Gegenproben/Messung,
   keine Produktionsentscheidung. Dateien: `pipeline/tests/verification_v2/immutable_snapshot.sql`
   und `pipeline/tests/verification_v2/immutable_snapshot_test.py`.
2. **Begrenztes Packlesen:** vorhandenen Tokenparser
   [stream-json](https://github.com/uhop/stream-json) mit Runtime-Hash zunächst
   in einem einzelnen begrenzten Schritt testen, nicht einen eigenen Parser
   oder persistierbaren SHA-Zustand bauen. Dateien:
   `pipeline/tests/verification_v2/stream_pack_probe.ts` und
   `pipeline/tests/verification_v2/stream_pack_probe_test.ts`. Zwei Hashes aus
   einem Tokenstrom, nur `release.created_at` für den Quellenhash auslassen;
   UTF-8, Escape-/Zahlendarstellung, UTF-16-Keysortierung, doppelte Schlüssel,
   ungültige Werte und alle referenzierten Teilstrukturen gegen den bisherigen
   Vertrag testen. [Parser-Tokens](https://github.com/uhop/stream-json/wiki/Parser)
   sind keine fertige kanonische Serialisierung; Bibliotheksausgabe nicht blind
   als unseren Hashvertrag übernehmen. Das echte Pack hat 158.348 Objekte,
   keinen unsortierten/nicht-ASCII-Key, maximal 23 Keys, keine Floats und
   Arrays bis 47.089 Einträge. Das erleichtert den Versuch, ersetzt aber keine
   allgemeine Vertragsprüfung oder Behandlung anders geordneter gültiger JSONs.

Keine dieser vier Folgedateien ist in diesem Auftrag angelegt. Eine eigene
Checkpoint-JSON-/SHA-Implementierung bleibt gesondert freigabepflichtig.
[hash-wasm bietet gespeicherte Hashzustände](https://github.com/Daninet/hash-wasm#resumable-hashing),
aber Format-/Versionsbindung und sensible Klartextreste im Zustand erfordern
einen eigenen Vertrag; keine Library wurde hier installiert oder als kompatibel
nachgewiesen. Erst bei gemessenem Scheitern des begrenzten Einzelschritts darüber
entscheiden. Keine Unicode-Normalisierung gegenüber dem bestehenden Hashvertrag.

Erst nach erfolgreichen Gegenproben und <= 500 ms CPU/128 MiB beobachtetem
Speicher pro Schritt kann ein Produktionsauftrag abgegrenzt werden:
`_shared/content_verification_steps.ts`, `_shared/content_verification_storage.ts`,
neue Migration `supabase/migrations/20261018000001_content_verification_runs.sql`
(nur vorgeschlagener Name), Dispatch in `content-publish`, Publisher-Fortschritt
und passende Reader-/Downloadintegration. Schnittstelle: autorisierte
start/progress/claim/step/resume/complete-Aufrufe mit Upload-/Run-ID,
Prüferversion und Revision; Ergebnis ausschließlich serverseitig aus versiegelten
Bytes. Keine rekursive Function-Kette; jeder Aufruf begrenzt, idempotent und
unterbrechbar, Generation-/Parent-CAS weiterhin am endgültigen Commit.

### Ausgeführte Befehle, Outputs und Grenzen

PowerShell, Repositorywurzel (lokaler Stack/Docker bereits vorhanden):

```powershell
pipeline/.venv/Scripts/python.exe -X utf8 pipeline/tests/verification_v2/local_probe.py --bundle "$env:LOCALAPPDATA/SprachappContentEditor/bundles/088f5eab-7347-406f-b9e6-cf5dbb985990"
pipeline/.venv/Scripts/python.exe -X utf8 pipeline/tests/verification_v2/local_probe.py --storage-only --bundle "$env:LOCALAPPDATA/SprachappContentEditor/bundles/088f5eab-7347-406f-b9e6-cf5dbb985990"
deno test --allow-read supabase/functions/_shared/content_distribution_test.ts supabase/functions/_shared/content_baseline_adoption_test.ts
pipeline/.venv/Scripts/python.exe -X utf8 -m pytest pipeline/tests/test_editor_publisher.py -q --tb=short
```

Outputs: vollständiger Lauf zweimal `ready`, `State probes: 16 passed; no publication.`
(anschließend zusätzlicher Originalhandler-Ablauftest = 17 Nachweise), Cleanup
erfolgreich, Exit 0. Storage-Nachprobe: die oben genannten Gegenbeispiele, Exit 0.
**Probe-Exit 0 bedeutet ausgeführte Diagnose, nicht erreichte Ressourcenziele
oder bewiesene Unveränderlichkeit.** Deno: `12 passed | 0 failed (8s)`, Exit 0.
Pytest: `21 passed in 7.44s`, Exit 0. Lokale Logs:
`build/verification_v2/{final,storage-final,deno,pytest}.log`; Messlauf
`8621ef09a1c6494592d7920b821e900f`, Storage-Nachprobe
`f62cdf7970c04f4bb5855c5f06437d3d`. Persistente bereinigte Ergebnisse im Evidenz-JSON.

macOS-Entsprechung (nicht ausgeführt): `pipeline/.venv/bin/python -X utf8`
statt Windows-Python, `--bundle /absoluter/pfad/zum/bestehenden/bundle` statt
`$env:LOCALAPPDATA/...`; Deno-Befehl identisch. Lokales Docker-Netz/Stack müssen
dieselben Testendpunkte bereitstellen; keine automatischen Cloudzugriffe.

Zwei frühere Proben endeten mit Exit 1: zuerst erwartete der Test bei einer
SQL-Rechteverweigerung HTTP 403, der bestehende Backendadapter liefert 503;
anschließend scheiterte explizites Resume. Nach zwei Fehlschlägen wurde gezielt
SQL-Namensauflösung geprüft: `upload_id` war im ON-CONFLICT-Ziel mehrdeutig
(isolierter Transaktionsrepro Exit 1). Nur das Test-SQL wurde auf benannten
Constraint umgestellt. Danach Zustandsproben und vollständiger Lauf Exit 0.
Kein weiterer Cloud-Finalize und keine blinden Optimierungsrunden.

Abschlusskontrolle: `git diff --cached --check` und gezieltes `git diff --check`
ohne Befund, Exit 0. Hashvergleich aller 55 geschützten Dateien unverändert;
fremder getrackter Diff unverändert, NEXTSTEPS behält dessen Text und 25 Zeilen.
GitNexus `analyze --index-only`, danach `detect_changes` für `all` und `staged`
(lokaler Backendaufruf mit `limit:10000`): Exit 0, keine partial/truncated-
Antwort. **Risiko CRITICAL**, auch für die sieben eigenen Dateien: 31 Symbole,
250 betroffene Prozesse. Alle gemeldeten Prozessschritte heißen `ok`; Context
verknüpft die neue lokale Literal-Property `{ok:true}` mit vielen fremden
`main`-Zugriffen. Textprüfung findet keine Produktionsimporte des Prototyps;
der Testtreiber ist nur explizit per CLI aufrufbar. Datei-Impact ist UNKNOWN,
nicht niedrig. Der Index warnt zusätzlich vor begrenzter Prozesserfassung.
Diese Graphgrenzen werden nicht als saubere Risikofreigabe ausgegeben;
die Abgrenzung stützt sich auf Imports, unveränderte Produktionshashes und
die tatsächlich ausgeführten isolierten Tests. Keine Produktionsänderung folgt
aus der Graphprüfung. Logs liegen unter `build/verification_v2/graph-*.json`.

**Nächste Aktion:** die beiden begrenzten Folgeproben für unveränderliche
Snapshots und vorhandenen Streamingparser freigeben. Jetzt weder neu deployen
noch „2 · Serverprüfung“ wiederholen. Der bestehende echte Upload bleibt
erhalten; produktive Wiederaufnahme ist mit diesem Diagnoseprototyp noch nicht
möglich. Die unten dokumentierte AGENTS-Regel bleibt ein Vorschlag.

## Erneuter Cloudabbruch: CPUTime belegt; Architekturfreigabe erforderlich · 17.10.2026

**Dieser Abschnitt ersetzt die frühere Handlungsempfehlung, erneut zu deployen
und die Serverprüfung zu wiederholen.** Kein weiterer Finalize-Aufruf erfolgte.
Der vorhandene Upload `dc4eb268-b9d1-4278-839d-0176d0db2f40` zur lokalen Version
`088f5eab-7347-406f-b9e6-cf5dbb985990` bleibt erhalten. Der Laufzeitcode wurde in
diesem Auftrag nicht verändert. Eine kleine Optimierung mit nachgewiesener
Cloudreserve liegt nicht vor; der unten stehende Architekturwechsel ist **nur
vorgeschlagen, nicht implementiert oder freigegeben**.

### Tatsächliche Cloudbelege und Bereitstellung

Ausschließlich lesende Management-API-Zugriffe mit bestehender CLI-Anmeldung:
Functionliste, Download des bereitgestellten Quellcodes in `build/cloud_546_audit/download`
und zwei eng begrenzte Logabfragen für **16.10.2026 18:57–19:03 UTC** (20:57–21:03
Europe/Berlin). Das Browser-Dashboard verlangte Anmeldung und wurde nicht benutzt.
Der CLI-Token blieb im Prozessspeicher; keine Secrets, Header, URLs mit Signaturen
oder Inhaltszeilen wurden gespeichert. Selektierte strukturierte Felder stehen in
[evidence/content-editor-initial-release/cloud-546-audit.json](evidence/content-editor-initial-release/cloud-546-audit.json).

- Function `content-publish`, ID `1f2df8a3-bde4-47e2-b394-09b60cb839b5`, **Version 3**, ACTIVE,
  `verify_jwt=true`, ESZIP-SHA256 `ac61671216c92fa18ff5fe2950aeaadead01f6226ddb6e3c1c76dbac9edc8237`.
- Download enthält `digest` mit 16-KiB-Blöcken, strikten Streamingdecoder ohne
  Rohchunkliste und kleine `release`-Kopie anstelle `structuredClone(pack)`.
  Quellenanker ist nach Zeilenendennormalisierung identisch. Der Download ist
  transpiliertes JavaScript in `.ts`-Dateien, daher kein behaupteter TypeScript-
  Bytevergleich/Commitattest. Entry-Point und drei konkrete Optimierungen wurden
  am gelieferten Code geprüft; der neue Lauf verwendet genau diese Dateien.
- Boot **18:59:30.778 UTC**, HTTP-546-Ereignis **18:59:34.841 UTC**, Shutdown
  **18:59:34.858 UTC**: alle haben Execution-ID
  `a01dba54-62ef-45de-8602-1204d1548da3` und Deployment-ID
  `yevntxclpchapacqdizm_1f2df8a3-bde4-47e2-b394-09b60cb839b5_3`.
- **Shutdown reason `CPUTime`, cpu_time_used=2441 ms**; Speicher beim Shutdown
  **79.508.379 Bytes** (Heap 76.409.720, extern 3.098.659), Invocationdauer 4572 ms.
  Diese Speicherzahl ist kein Peak. Region `eu-central-1`,
  `supabase-edge-runtime-1.77.0 (compatible with Deno v2.1.4)`.
- Im Zeitfenster ist genau eine Invocation ausgewiesen. Lokaler Job begann
  **18:59:31.212095 UTC**, fehlgeschlagen mit `PUBLISH_HTTP_546` und
  `WORKER_RESOURCE_LIMIT`, processed=0/10. Das ist der Fortschritt dieses neuen
  lokalen Jobs, kein Beweis, dass die früher geprüften neun Cloudobjekte verloren
  sind. Die vorherige Ausführung stand bei 9/10. Die Zuordnung zum Nutzerfehler
  beruht auf Zeit/Function/Status; `request.path` ist im Cloudlog leer.

**Belegte Ursache dieses Cloudabbruches: CPU-Budget überschritten.** Eine weitere
Speicherursache wird für diese Invocation nicht behauptet. Die 2441 ms sind ein
Supervisorwert bei Abschaltung, kein zulässiges neues Limit. Warum dieselbe
Arbeit auf dem lokalen Rechner schneller ist, lässt sich nicht quantitativ auf
Hardware, Runtimepatch, Transport/GC oder andere Anteile verteilen. Es fehlen
Cloud-Phasenprofile, nicht mehr der Shutdown-Grund. Kein Beleg für konkurrierende
Aufrufe oder angesammelte CPU früherer Requests dieses Workers: der Boot gehört
zum selben kurzen Zeitfenster.

### Messlücke und vollständiger lokaler Anwendungshandler

| Aspekt | Helfer aus e09f665 | Neuer lokaler Kontrolllauf | Cloudbeleg / verbleibende Grenze |
|---|---|---|---|
| Runtime | Image v1.77.1, Deno 2.1.4 | gleiches bereits installiertes Image | v1.77.0, Deno 2.1.4; Cloudimage lokal nicht vorhanden |
| Pfad | instrumentierter Worker ruft `publish()` direkt auf | heruntergeladene `content-publish/index.ts` → `handler()` → `publish()` unverändert | gleiche drei Optimierungen im Download belegt |
| Anfrage | Wrapper liest Upload-JSON und baut zweite Request | originaler POST-Pfad mit `{}` und Bearerheader | Gateway/JWT-Prüfung außerhalb des lokalen Workers fehlt |
| Backend | lokale Auth-/DB-/Storage-HTTP-Fixtures | dieselben Fixtures, echte Backendmethoden/fetch/Parse/PATCH | kein echtes GoTrue, SQL/RLS, Storage-Service, TLS oder Cloudnetz |
| Worker | `oneshot`, `forceCreate=true`, soft/hard 2000/2000 ms | `oneshot` sowie `per_worker`, soft/hard 1000/2000 ms | tatsächlich wirksame Soft-Konfiguration nicht im Log ausgewiesen |
| Speicher / Wandzeit | 256 MiB / 150000 ms | unverändert 256 MiB / 150000 ms | Cloud-Hardwerte nicht aus Shutdownmetadaten ableitbar |
| Wiederverwendung | zehn frische Worker | zehn frische bzw. ein wiederverwendeter Worker (Boot-/Shutdownereignisse) | Cloudlog zeigt einen Boot und eine Invocation |
| Parallelität | sequenziell | sequenziell wie der Publisherjob | konkurrierende Clients nicht getestet; kein Parallelitätsnachweis |
| Umfang | alle neun Bytehashes und abschließende Bestandsprüfung | dieselben neun Dateien plus vollständiger Anwendungshandler | normale Parent-Releases nur Regressionstests, keine Lastabnahme |

Die früheren 1086 ms schlossen weder den äußeren Handler noch echte externe
Dienste/Gateway ein. Andererseits gehörten Auth-/Rechte-/Storage-/DB-**Methoden**
bereits dazu; sie waren nicht vollständig ausgelassen. Der alte Wrapper fügte
selbst JSON- und Mess-HTTP-Arbeit hinzu. Der Unterschied ist deshalb kein
pauschaler Beweis, dass allein der fehlende Handler den Cloudabbruch verursacht.
Storagezugriffe sind sequenziell, doch geparste Registry/Inventar/Packstrukturen
bleiben im letzten Aufruf gleichzeitig erreichbar. SQLite wird separat gestreamt;
die zwei verschiedenen kanonischen Packhashes bleiben CPU-Arbeit im letzten Aufruf.

| Lauf | Ergebnis | CPU laut Supervisor | Speicher beim Shutdown | Wandzeit letzter Request |
|---|---|---:|---:|---:|
| historischer lokaler Fixlauf | ready | 1086 ms | 78.485.951 B | 1375 ms |
| alter Helfer erneut, optimiert | ready | 1090 ms | 78.685.000 B | 1344 ms |
| heruntergeladener Handler, frisch | ready | 1083 ms (letzter Worker) | 78.518.173 B | 1375 ms |
| heruntergeladener Handler, wiederverwendet | ready | 1326 ms (**ganzer Worker mit zehn Requests**) | 78.862.791 B | 1343 ms |
| tatsächliche Cloudinvocation Version 3 | **546 / CPUTime** | **2441 ms** | **79.508.379 B** | **4572 ms** |

Kein vollständiger Produktionsinfrastrukturtest: Die lokale Messung umfasst den
vollständigen Anwendungshandler mit echten Bundlebytes, aber synthetische Dienste.
Sie ist insbesondere **keine Cloudabnahme und kein Peak-Speicher-/Reservenachweis**.
Der etwa 2,25-fache Unterschied der CPUwerte ist eine Beobachtung, kein allgemeiner
Umrechnungsfaktor. Es gibt keinen gerechtfertigten kleinen Fix mit ausreichender
Reserve. Daher keine weitere blinde Hashoptimierung, kein höheres Timeout.

### Konkreter Vorschlag: `verification-v2`, serverseitig begrenzt und fortsetzbar

**Freizugebender Umfang:** neue private Prüftabellen/RPCs, Storage-Versionsbindung,
begrenzt fortsetzbarer Parser/Hasher, Änderungen in `content-publish` und Publisher-
Fortschritt sowie zugehörige Tests. Bestehende Inhaltsbytes, Upload-ID und Quellenanker
bleiben erhalten. Keine neue Infrastruktur, rekursive Function-Kette oder Hintergrundprüfung.
Dies ist ein Architekturwechsel; vor dessen Umsetzung wird hier gestoppt.

1. **Identität versiegeln:** ein autorisierter `prepare-verification`-Schritt liest
   den bestehenden Upload und alle neun Storageobjekt-Identitäten. Er legt einen
   Run mit `(upload_id, manifest_sha256, descriptor_set_sha256, verifier_version,
   object_version_set_sha256, parent_release_id, parent_manifest_sha256)` an.
   Manifesthash wird serverseitig berechnet, nicht vom Client als Wahrheit übernommen.
   Für jedes Objekt werden Bucket/Key, Storage-ID und unveränderliche Versionskennung,
   erwartete Größe und SHA gespeichert. Bestehende `verified_objects` allein sind
   **kein v2-Nachweis**; sie haben noch keine solche Versionsbindung.
2. **Unveränderlichkeit ist Voraussetzung, kein ETag-Versprechen:** vor Nutzung von
   Teilresultaten muss ein nachgewiesener Storage-Vertrag Update/Delete/Recreate des
   versiegelten Keys verhindern (auch über alte signierte URLs/alle Anwendungs-
   Schreibpfade); `upsert:false` bleibt. Alternativ benötigt jeder Zugriff eine
   tatsächlich adressierbare unveränderliche Objektversion. Bloße HEAD-Prüfung vor
   und nach einem GET reicht wegen des Austauschrennens nicht. Versionwechsel,
   fehlendes Objekt oder nicht durchsetzbare Unveränderlichkeit ⇒ Run `invalidated`,
   kein ready/commit. Implementierung zuerst gegen lokalen Storage beweisen; wenn
   dessen unterstützte API diese Garantie nicht erlaubt, Plan erneut vorlegen,
   nicht improvisiert `storage.objects` verändern. Kein Neu-Upload als stiller Ausweg.
3. **Zustand:** private Tabellen `content_verification_runs`, `..._steps` und
   `..._checkpoints`. Runzustände `prepared → verifying → ready`, alternativ
   `invalidated` oder `failed`; Schrittzustände `pending → running → passed`,
   alternativ `failed`. `running` enthält Lease-ID, Ablauf, Attempt und Revision.
   Ein Transport-/Workerabbruch lässt die Lease auslaufen; keine fachliche
   Fehlerfreigabe und kein automatisches Umschalten auf Erfolg. Fachlicher 422
   bleibt dauerhaft fehlgeschlagen. Prüferwechsel invalidiert alte Checkpoints.
4. **Ein Aufruf, ein begrenzter Arbeitsschritt:** `advance-verification` prüft pro
   Request Actor, Publisherrecht, Uploadowner, Scope, Laufzeit und Runidentität.
   RPC beansprucht mit Zeilensperre/CAS genau einen nächsten Schritt. Konkurrenz
   bekommt dessen Status/409 busy; keine doppelte Fortschrittsaddition. Abschluss
   erfolgt nur bei passender Lease/Revision/Identität; verlorene Antworten sind
   durch denselben Idempotenzschlüssel wiederholbar. Abgelaufene Worker dürfen
   Ergebnisse einer neu vergebenen Lease nicht überschreiben.
5. **Arbeitsbudget nicht durch vollständiges Neuladen verstecken:** zunächst
   höchstens **256 KiB Eingangsdaten bzw. 128 vollständige Datensätze** pro Teilstück
   (jeweils frühere Grenze), persistenter Offset/Parserstack/UTF-8-Rest und serverseitiger
   Hashzustand. Größere Werte werden in Fragmenten fortgesetzt; kein stilles Auslassen.
   Rangeantwort muss exakte Position/Länge und versiegelte Version liefern; ohne
   funktionierenden Rangevertrag bleibt dieser Entwurf blockiert. Keine Wiederholung
   des gesamten 50-MB-JSON pro Teilschritt, kein Hashen von Hashes als Ersatz für SHA256.
6. **Serverseitiger Index und kanonischer Durchlauf:** begrenzter Streamingparser
   indiziert JSON-Werte/Arrayordnungen/Objektschlüssel samt Bytebereichen in privaten
   Prüftabellen. Große Strings/Arrays dürfen nicht vollständig materialisiert werden.
   Ein zweiter begrenzter Durchlauf produziert exakt die bisherigen kanonischen
   Bytes (UTF-16-Schlüsselsortierung wie JS, JSON.stringify-Zahlen/Escapes, identische
   Arrayreihenfolge und JSON.parse-Semantik). Für Packinhalt entstehen zwei separat
   gebundene SHA-Zustände: gesamtes Pack und normalisiertes Pack ohne
   `release.created_at`; der Zeitstempel wird weiterhin eigenständig geprüft.
   `node:crypto`-Hashobjekte sind kein portables DB-Checkpointformat: eine versionierte,
   überprüfte SHA256-Zustandsimplementierung und Parserkonformität sind vorab zu
   prototypisieren. Abbruch mitten im Token/UTF-8/SHA-Block muss exakt fortsetzbar sein.
7. **Prüf-DAG:** neun vollständige Byte-/Größenhashes → Manifest-/Report-/Review-
   Bindung und Sidecarhashes → Packscope/Registrybindung und kanonische Packhashes →
   Bestandsbeleg/Quellen-/SQLitepins/keine neue Sprachfreigabe **oder** normaler Review-
   und Parentpfad → begrenzte Registry-/Historien-/Story-Supersetvergleiche gegen
   ebenfalls versionsgebundene Parentdaten → Abschluss. Jeder bisherige Fehlercode
   wird einer Stufe zugeordnet; kein Review-, Rechte-, Quellen- oder Inhaltscheck
   fällt weg. Readerreport bleibt wie bisher bytegebunden; SQLite ebenfalls vollständig
   gehasht, bei Bestandsübernahme zusätzlich gegen den bestehenden Quellenanker.
8. **Atomarer Abschluss/Commit:** ein RPC prüft vollständige verpflichtende Stufen,
   gleiche Run-/Objektidentität und ausstehende Leases, berechnet/bindet den finalen
   Manifesthash und setzt erst dann ready. `publish_content_release` muss zusätzlich
   genau diesen vollständigen v2-Run prüfen. Die bestehende Transaktion mit Upload- und
   Channelsperre, Publisherrecht/Owner, Generation **und** Parent-ID/-Hash sowie
   idempotentem Publishrequest bleibt erhalten. Kein Endpoint darf vorzeitig
   allein durch `status=ready` oder einen lokalen Bericht veröffentlichen.
9. **Fortsetzen im Editor:** derselbe vorhandene Releaseeintrag; begrenzte Serie
   expliziter authentisierter Requests mit serverseitig geliefertem Fortschritt.
   Höchstens festgelegte Anzahl pro Nutzeraktion, danach „Prüfung fortsetzen“;
   Fehler/546 stoppt sofort. Kein Autoretry, kein Selbstaufruf, kein Endlosloop.
   Nach Prozessneustart wird nur der Serverzustand gelesen. Fehlende Rechte stoppen
   auch eine bereits begonnene Prüfung. Der aktuelle 24h-Ablauf bleibt wirksam:
   für später abgelaufene Uploads braucht die Umsetzung einen gesonderten auditierten
   Owner-/Publisher-Resume-Vertrag mit erneuter Identitätsprüfung und neuem Run unter
   derselben Upload-ID. Die heutige unveränderliche `expires_at` wird weder manuell
   umgeschrieben noch ignoriert; erforderliche Guard-/RPC-Anpassung gehört zur Freigabe.

**Abnahmeschranken vor einer späteren Freigabe:** exakter alter/neuer Hashvertrag
für echtes Bundle sowie Unicode, Zahlen, Reihenfolge, große Werte und Tokenkanten;
Ausfall vor/nach jedem Checkpoint; zwei parallele Clients, Leaseübernahme und verlorene
Antwort; Austausch/Delete/Recreate zwischen Schritten und vor Commit; Rechteentzug,
normaler Reviewpfad, Bestandsübernahme und Parent-/Generationkonflikt. Reale lokale
Supabase-Dienste zusätzlich zu Fixtures, Originalhandler, frische und wiederverwendete
Worker, echte Bundlebytes. Ziel: pro Schritt höchstens **500 ms CPU und 128 MiB
beobachteter Speicher** in der repräsentativen Edgeprüfung, zusätzlich Test unter
CPU-Drosselung und später echter Cloudmetrik; das sind vorgeschlagene Abnahmegrenzen,
keine heute erfüllten Messwerte. Peaks/Überwachungslücken explizit berichten.
Erst ein separat autorisierter Cloudlauf kann Cloudreserve belegen. Wenn Streaming-
Parser/Range-/Speicherversiegelung diese Grenzen nicht erreichen, **stoppen und
überarbeiteten Plan vorlegen**, keine neue Infrastruktur nebenbei einführen.

### Befehle, Outputs und Exitcodes dieses Auftrags

Windows PowerShell und macOS Terminal (identische Befehle):

```text
supabase functions list --project-ref yevntxclpchapacqdizm
supabase functions download content-publish --project-ref yevntxclpchapacqdizm --workdir build/cloud_546_audit/download
# ACTIVE, version 3, verify_jwt=true / Downloaded Edge Function source. Je Exit 0.
deno test --allow-read supabase/functions/_shared/content_distribution_test.ts supabase/functions/_shared/content_baseline_adoption_test.ts
# ok | 12 passed | 0 failed (9s). Exit 0.
```

Windows PowerShell, tatsächlich ausgeführt:

```powershell
pipeline/.venv/Scripts/python.exe -X utf8 -m pytest pipeline/tests/test_editor_publisher.py -q --tb=short
# 21 passed in 6.18s. Exit 0.
pipeline/.venv/Scripts/python.exe -X utf8 pipeline/tests/check_content_edge_resources.py --bundle "$env:LOCALAPPDATA/SprachappContentEditor/bundles/088f5eab-7347-406f-b9e6-cf5dbb985990"
# before HTTP546/Memory; after call10 HTTP200/ready, CPU1090ms. Exit 0.
pipeline/.venv/Scripts/python.exe -X utf8 pipeline/tests/check_content_edge_handler_resources.py --bundle "$env:LOCALAPPDATA/SprachappContentEditor/bundles/088f5eab-7347-406f-b9e6-cf5dbb985990" --functions build/cloud_546_audit/download/supabase/functions
# oneshot und per_worker: 10x HTTP200, letzter Status ready. Bundle unchanged. Exit 0.
```

macOS Terminal, entsprechende Wiederholung (hier nicht ausgeführt):

```sh
pipeline/.venv-macos/bin/python -X utf8 -m pytest pipeline/tests/test_editor_publisher.py -q --tb=short
pipeline/.venv-macos/bin/python -X utf8 pipeline/tests/check_content_edge_resources.py --bundle '/absoluter/Pfad/zum/bestehenden/Bundle'
pipeline/.venv-macos/bin/python -X utf8 pipeline/tests/check_content_edge_handler_resources.py --bundle '/absoluter/Pfad/zum/bestehenden/Bundle' --functions build/cloud_546_audit/download/supabase/functions
```

Die beiden Logabfragen: GET `/v1/projects/yevntxclpchapacqdizm/analytics/endpoints/logs`,
`iso_timestamp_start=2026-10-16T18:57:00Z`, `iso_timestamp_end=2026-10-16T19:03:00Z`,
SQL `SELECT timestamp,source,log_attributes['<Feld>'] AS <Feld> FROM logs WHERE source
IN ('function_logs','function_edge_logs') ORDER BY timestamp DESC LIMIT 100`;
Felder sind genau die Schlüssel im versionierten bereinigten Beleg, keine Wildcard
auf Inhalte/Header. Zweite Abfrage ergänzt nur request.method/path. Je **HTTP200,
Exit0**, vier Ereignisse. Hilfsskript `build/cloud_546_audit/read_logs.py` nutzt den
bestehenden CLI-Keyring nur im Speicher. Kein Finalize-/Testbutton in der Cloud.

Lokale Rohmessungen: `build/content_edge_handler_resources/92322069d0c74b07957f6876f85edee9/`
und `build/content_edge_resources/9560850d6e7f4f8fa05e08c3ef7cba83/`; Tests unter
`build/cloud_546_audit/{deno,pytest,handler,previous-harness}.log`. Keine Secrets
in den versionierten Messdaten. Der neue Helfer ist ein zusätzlicher Kontrolllauf,
kein Ersatz des alten Vorher/Nachher-Tests. Er verändert nur isolierte Fixturezustände.

### Änderungs- und Graphprüfung

Repo/Worktree `C:/Users/ardas/Music/sprachapp`, GitNexus `sprachlernapp`, neu auf
Basis `e09f665` indiziert: 19.189 Knoten, 41.423 Kanten, 374 erfasste Flows. Die
Indexerwarnung über nicht vollständig erfasste dynamische Flows bleibt bestehen;
`context(verifyBundle)` lieferte zudem unpassende Namenszuordnungen. Deshalb
Quellpfad direkt nachgelesen. Impact des Berichts LOW (Contract/Paket 3 direkt,
Plan indirekt); NEXTSTEPS und bisheriger Testhelfer UNKNOWN, per Textnachweisen
als Statusdokument bzw. expliziter CLI-Test bestätigt, kein Produktionsaufrufer.

`node build/cloud_546_audit/graph-check.mjs` ruft `detect_changes(scope=all)` und
`scope=staged` mit explizitem Repo auf: **all 20 Dateien/30 Symbole/303 betroffene
Prozesszuordnungen, CRITICAL; staged 4 Dateien/16 Symbole/0 Prozesse, LOW**.
Je `partial=false`, `truncated=false`, kein Fehler, Exit0. Der Gesamtrisiko-
Hinweis wurde ausdrücklich gemeldet; fremde UI-Änderungen bleiben unangetastet.
Ein vorheriger Zugriff während der laufenden Neuindizierung scheiterte mit
Dateisperre/Exit1; erst nach Indexabschluss wurde erfolgreich erneut geprüft.
Die erste CLI-Flowquery mit Leerzeichen scheiterte an Argumentweitergabe/Exit1;
Query mit einem Begriff sowie benannte Context-/File-Impact-Prüfungen folgten.

`git diff --check -- docs/content-editor-initial-release.md NEXTSTEPS.md pipeline/tests/check_content_edge_handler_resources.py docs/evidence/content-editor-initial-release/cloud-546-audit.json`
und `git diff --cached --check`: keine Befunde, Exit0. Nach den Messläufen vor der
Dokumentationsänderung gesicherte 26 lokale Schutzdateien abschließend hashgleich;
beide Bundlehelfer prüfen zusätzlich ihre Originalbytes vor/nach jedem Test.
Fremder getrackter Diff identisch, NEXTSTEPS nur ergänzend/25 Zeilen, kein
Produktionscode-/Quellenankerwechsel, keine Cloudschreibaktion und kein Push.
Alle isolierten Testcontainer entfernt; vorhandener Supabase-Stack erhalten.

### Vorgeschlagene AGENTS.md-Regel und nächste Aktion

Als Regel **vorgeschlagen**, AGENTS.md selbst nicht geändert:

> WENN ein Release in einer ressourcenbegrenzten Edge-Runtime geprüft wird → NIE
> erfolgreiche Unit-Tests oder einen Teilpfad als Nachweis für den vollständigen
> Cloudablauf ausgeben.

**Nächste Aktion: den oben abgegrenzten `verification-v2`-Architekturplan zur lokalen
Implementierung freigeben.** Jetzt kein erneuter Klick auf „2 · Serverprüfung“,
kein Deployment und kein Neu-Upload. Nach Implementierung und lokaler Abnahme
müssten die ausdrücklich geprüfte Migration und `content-publish` gesondert zum
Deployment freigegeben werden; erst danach derselbe Releaseeintrag fortgesetzt
werden. Die vorhandenen Logs reichen für die CPU-Diagnose, ein weiterer
Cloudversuch zur bloßen Bestätigung ist nicht erforderlich.

---

## Historischer Stand: HTTP 546 lokal reduziert · 16.10.2026

**Damals gemessener lokaler Stand (Folgebefund oben beachten):** Der echte Bestand wurde in einer isolierten Supabase Edge
Runtime vollständig geprüft. Vorher bricht der zehnte Finalize-Aufruf am
Speicherlimit ab; mit der begrenzten Optimierung erreicht er `ready`.
**Keine Cloudprüfung, kein Deployment und keine Veröffentlichung durchgeführt.**
Der vorhandene lokale Beleg bleibt mit derselben Upload-ID auf `verifying`.
Der konkrete Shutdown-Grund der gemeldeten Cloudinvocation ist weiterhin
unbekannt; der Speicherengpass ist lokal reproduziert, CPU als Cloudursache nicht
behauptet.

### Ablauf, Daten und Ursache

Der aktuelle lokale 546-Job steht bei **processed=9 / total=10**. Die erste
Finalize-Stufe streamt bereits je Aufruf genau eine der neun Dateien und prüft
Bytes, Größe und Hash. Erst der zehnte Aufruf führt `verifyBundle` aus.
Die Bestandsübernahme hat keinen Parent, deshalb werden hier keine früheren
Registry-/Inventardateien nachgeladen. Normale Folge-Releases behalten ihre
zusätzlichen Parent-/Registry-/Historienvergleiche.

| Datei | Bytes | Verarbeitung in der abschließenden Prüfung |
|---|---:|---|
| `pack.json` | 50.083.067 | UTF-8/JSON, Scope/Registrybindung, kompletter normalisierter Inhaltshash und abschließender Packhash |
| `content.sqlite` | 43.085.824 | Bytes vorher separat gestreamt/gehasht; abschließend gebundener SQLitehash/Größe geprüft, kein SQLite-JSON-Parse |
| `history_inventory.json` | 10.169.664 | JSON/kanonischer Sidecarhash, Sprache/Format/Tabellen, gegebenenfalls Parentvergleich |
| `reader_report.json` | 9.808.519 | Byte-/Größen-/Hashprüfung als eine der neun Dateien; kein zusätzlicher JSON-Parse in `verifyBundle` |
| `registry.json` | 1.063.044 | JSON/kanonischer Sidecarhash, Packbindung, gegebenenfalls bisherige Wörter |
| Manifest / Report / Reviews / Provenienz | 1.055 / 1.839 / 3 / 2.575 | JSON, Manifestgleichheit, technische Zulassung, Review- oder Übernahmevertrag, Beleg-/Quellenbindung |

Bisher sammelte `DistributionBackend.object(read=true)` alle rohen Streamchunks
in einer Liste, kopierte sie in einen zweiten Gesamtpuffer und dekodierte diesen
zu einem Gesamtstring vor dem Parse. Das hält zusätzlich die Backingbuffer der
Chunkansichten fest. Inventar, Registry und weitere bereits geparste Dateien
bleiben währenddessen erreichbar. Im isolierten Packtest wurden bereits
253.903.605 externe Bytes gemeldet und `Array buffer allocation failed`
ausgelöst. Die komplette Prüfung überschreitet anschließend das lokale
256-MiB-Limit. Dies ist ein gemessener Speicherabbruch, kein Zeitlimitnachweis.

Weitere unnötige Allokationen im selben Pfad waren die rekursive Bildung eines
großen kanonischen Gesamtstrings je Hash sowie `structuredClone(pack)` nur zum
Weglassen von `release.created_at`. Der Inhalt wird für zwei verschiedene
Prüfzwecke gehasht; beide Bindungen bleiben erhalten.

### Begrenzter Fix und unveränderte Integrität

- Rohbytes werden weiterhin vollständig gehasht und gezählt. JSON wird mit
  einem strikten, zustandsbehafteten UTF-8-Decoder während des Streams dekodiert.
  Es gibt keine Liste festgehaltener Rohchunks und keinen zweiten Gesamtbuffer.
  Parse/Annahme erfolgen nach korrekter Größe und korrektem Bytehash. Das
  bisherige 64-MiB-JSON-Limit bleibt bestehen.
- `digest` produziert dieselbe kanonische Bytefolge mit sortierten Schlüsseln,
  sammelt kleine Schreibteile und übergibt sie in etwa 16-KiB-Blöcken an SHA-256.
  Die großen rekursiven Gesamtstrings entfallen. Einzelne skalare JSON-Werte
  werden weiterhin regulär serialisiert; es wird kein neuer Hashvertrag erfunden.
- Für den normalisierten Packhash werden nur der äußere Container und das
  kleine `release`-Objekt kopiert. Alle Inhaltsdaten bleiben in einer einzigen
  geparsten Struktur; der ursprüngliche Zeitstempel wird separat geprüft und
  bleibt im abschließenden kanonischen Packhash enthalten.
- Alle neun Dateiprüfungen, Übernahme-/Quellen-/Inhalts-/SQLitepins, Registry,
  Reviews, Rechte, Parent-/Generationprüfung und atomarer Commit bleiben erhalten.
  `internal_baseline_source.json` wurde **nicht geändert**. Kein lokaler Bericht
  ersetzt die Serverprüfung. Kein neuer Status und keine verteilte Prüfung nötig.
- HTTP 546 wird im Editor jetzt als Ressourcenabbruch mit offenem konkreten
  Limit erklärt. Bekannte `WORKER_LIMIT`-/`WORKER_RESOURCE_LIMIT`-Codes sind sicher
  lesbar. Ein Abbruch stoppt den Job; der Regressionstest belegt genau einen
  Versuch und Fortsetzbarkeit derselben Upload-ID, keine automatische Wiederholung.

### Reproduzierbare lokale Edge-Messung

Versionierter Helfer: `pipeline/tests/check_content_edge_resources.py`.
Er verwendet das bereits installierte Image
`public.ecr.aws/supabase/edge-runtime:v1.77.1` (Deno 2.1.4), zieht kein Image nach,
kopiert die neun Eingabedateien unverändert in ein eigenes Testverzeichnis und
vergleicht den Gitstand `0670076` mit dem aktuellen Prüfmodul. Gemessen wird der
**tatsächliche `publish`-/Finalize-Pfad**, einschließlich der vollständigen
Byteprüfungen und abschließenden Bundleprüfung, über zehn getrennte Aufrufe.

Userworker-Limits in beiden Läufen identisch: **256 MiB Speicher**, **2.000 ms
CPU soft/hard**, **150.000 ms Wandzeit**, `oneshot`/frischer Worker pro Aufruf.
Keine Limits oder Timeouts wurden zur Abnahme erhöht. Nur isolierte lokale
Auth-/Storage-/DB-Adapter sind synthetisch; die Prüfimplementierung ist echt.
Der Test erzeugt keine Veröffentlichung und ruft kein Cloudprojekt auf.

| Reproduzierter voller Ablauf | Vorher (`0670076`) | Nachher |
|---|---:|---:|
| Aufrufe 1–9, Byte-/Hashprüfung | jeweils HTTP 200 / `verifying` | jeweils HTTP 200 / `verifying` |
| Aufruf 10, Gesamtprüfung | HTTP 546 / Supervisorabbruch | HTTP 200 / `ready` |
| Wandzeit Aufruf 10 | 656.0 ms bis Abbruch | 1375.0 ms vollständig |
| CPU laut Shutdown-Event | 383 ms bis Abbruch | 1.086 ms vollständig |
| Shutdown-Grund | `Memory`, `exceeded=true` | `EarlyDrop`, `exceeded=false` |
| Speicher laut Shutdown | 268.563.353 Bytes, davon 241.320.697 extern | 78.485.951 Bytes, davon 3.038.103 extern |
| Größter erfasster Heap+External-Phasensnapshot | 99.539.369 Bytes **vor** dem fatalen Packladen | 178.106.849 Bytes nach Packparse |

Die Snapshots sind **kein absoluter Peakwert**. Vorher zeigt erst das
Supervisorereignis die Überschreitung; der kleinere vorherige Snapshot wäre kein
Beleg geringeren Verbrauchs. Die CPUwerte sind ebenfalls nicht als Beschleunigung
vergleichbar: vorher wurde früh abgebrochen, nachher vollständig geprüft.
Die `node:process.cpuUsage()`-Stubwerte der ersten Erkundung wurden verworfen;
maßgeblich sind die echten Runtime-Shutdown-Events. Die Daten liegen kompakt in
[resources-546.json](evidence/content-editor-initial-release/resources-546.json).
Die finale Messung benötigt nach Inventar-/Registryparse etwa 528 ms für
Packladen/Decode/Parse; die verbleibende Gesamtprüfung führt die gebundenen
kanonischen Vergleiche vollständig aus. Rohlogs enthalten die Phasensnapshots.

Lokale Grenzen gegenüber der Cloud: andere Hardware/Runtimeversion möglich,
Loopback-I/O, synthetische Auth-/Storage-/DB-Antworten, frische Testworker statt
eines möglicherweise wiederverwendeten Cloudpools. Reale JWT-/RLS-/TLS- und
Cloudlatenzen sind damit nicht abgenommen. Cloud-HTTP-546 allein unterscheidet
CPU/Speicher/Wandzeit nicht; dessen Shutdownmetadaten wurden nicht abgefragt.
Referenz: [Supabase-Limits](https://supabase.com/docs/guides/functions/limits),
[546-Diagnose](https://supabase.com/docs/guides/troubleshooting/edge-function-546-error-response),
[Shutdown-Metriken](https://supabase.com/docs/guides/troubleshooting/edge-function-shutdown-reasons-explained).

Tatsächlich ausgeführt, Windows (PowerShell), aus dem Repository:
```powershell
pipeline\.venv\Scripts\python.exe -X utf8 pipeline/tests/check_content_edge_resources.py --bundle "$env:LOCALAPPDATA\SprachappContentEditor\bundles\088f5eab-7347-406f-b9e6-cf5dbb985990"
```
macOS (Terminal), mit dem dort tatsächlich vorhandenen Bundleverzeichnis:
```sh
pipeline/.venv-macos/bin/python -X utf8 pipeline/tests/check_content_edge_resources.py --bundle '/absoluter/Pfad/zum/bestehenden/Bundle'
```
Output: `before ... call 10 ... http_status: 546`; `after ... call 10 ...
http_status: 200, state: ready`; `Real bundle preserved; local verification passed
at 256 MiB / 2000ms CPU.` **Exit 0.** Messartefakte unter
`build/content_edge_resources/f9098493c2c94587beea72560b6e26a2/`, erste isolierte
Phasenmessungen unter `build/finalize_546/`. Testcontainer wurden entfernt.
Der Helfer bindet nur sein Testverzeichnis read-only und lauscht nur auf
`127.0.0.1:54999`; der echte Editor wird nicht gestartet oder umkonfiguriert.

### Regressionen und geklärte Testfehler

- `deno test --allow-read supabase/functions/_shared/content_distribution_test.ts supabase/functions/_shared/content_baseline_adoption_test.ts`:
  **12 passed / 0 failed (7s), Exit 0**. Kanonische Gleichheit gegen den bisherigen
  Algorithmus inklusive Unicode/großer Felder, split UTF-8, Hash/Größe, beide
  Releasearten und vorhandene Negativprüfungen; echter Packhash unabhängig gegen
  die bisherige kanonische Darstellung verglichen.
- `pipeline/.venv/Scripts/python.exe -X utf8 -m pytest pipeline/tests/test_editor_publisher.py -q --tb=short`:
  **21 passed in 4.98s, Exit 0**. Sichere 546-Meldung, kein automatischer Retry,
  persistierter Fehler und Fortsetzung derselben Upload-ID.
- Die ersten beiden Pythonläufe waren nicht erfolgreich: einmal Jobtesttimeout,
  einmal `PermissionError` beim Jobpolling. Gezielte Reproduktion belegt unter
  Windows: offener Python-Leser blockiert `atomic_json`/`os.replace` mit WinError 5.
  Der Publisher-Testleser nutzt jetzt denselben bereits vorhandenen Schreibmutex;
  die ursprüngliche 90-Sekunden-Grenze bleibt unverändert. Keine produktive
  Store-/Jobimplementierung wurde hierfür geändert. Der grüne Lauf wird deshalb
  nicht als bloße unerklärte Wiederholung gewertet.
- Im ersten Messaufbau verlor eine künstlich neu erzeugte Requestinstanz das
  Runtime-Tag (`streamRid`). Vor der gültigen Messreihe wurde die eingehende
  Requestinstanz direkt weitergeleitet. Dieser Harnessfehler ist kein Bundlefehler.

Pythonpfad für macOS bei gleichem Testbefehl durch
`pipeline/.venv-macos/bin/python` ersetzen; Deno-Befehl identisch.

### Schutz- und Änderungsprüfung

30 vorab gehashte Produktions-/Editor-Dateien einschließlich bestehendem Bundle,
Uploadbeleg und Jobs sowie die Editor-Dateiliste sind unverändert. Der
Bestandsanker ist bytegleich zur zu Beginn angelegten Kopie; der Gitvergleich
bestätigt unveränderten Inhalt (Arbeitsbaum-CRLF separat berücksichtigt).
Neun eigene Dateien werden isoliert committed; fremde Diffabschnitte bleiben
bytegleich und ungestagt. `NEXTSTEPS.md` hat im Arbeitsbaum und Index 25 Zeilen;
nur der eigene Folgestatus wird dem Index hinzugefügt. Eigene und gestagte
`git diff --check` ohne Ausgabe, jeweils Exit 0.

GitNexus für `sprachlernapp` / `C:\Users\ardas\Music\sprachapp`, Basis `0670076`,
aktualisiert: 19.168 Knoten, 41.393 Kanten, 374 erfasste Flows. Datei-Impacts des
Verteilungsvertrags und Publishers LOW; direkte Function-/Testimporte bzw.
Service-/Editorstart betroffen. Die Konzeptabfrage lieferte keinen brauchbaren
Finalize-Flow; direkte Quellen ergänzen diese Graphgrenze. Testdatei-Impact
UNKNOWN wurde über die tatsächlichen pytest-Aufrufe und Testimporte ergänzt.
`detect_changes(scope=all)` vor Commit: 25 Dateien/22 Symbole/303 Prozesszuordnungen;
`scope=staged`: neun eigene Dateien/12 Symbole/303 Zuordnungen. Beide **CRITICAL**,
ohne `error`, `partial` oder `truncated`. Risiko ausdrücklich gemeldet; keine
vollständige statische Ablaufabdeckung oder Cloudfreigabe daraus abgeleitet.

### Jetzt genau fortsetzen

1. Nach gesonderter Deploymentfreigabe ausschließlich **content-publish** neu
   bereitstellen (identisch in PowerShell und macOS-Terminal):
   `supabase functions deploy content-publish --project-ref yevntxclpchapacqdizm`.
   JWT-Verifikation bleibt aktiv. `content-release` verwendet den geänderten
   Hash-/Bundlepfad im Lesehandler nicht; dessen Deployment ist hier nicht nötig.
2. Editor im Startterminal mit **Ctrl+C** beenden und mit aktualisiertem Code,
   derselben Datenablage und bisherigen Authumgebung neu starten. Bei Bedarf
   erneut anmelden. Der Neustart lädt auch die verständliche 546-Meldung.
3. Unter **Versionen** beim bestehenden `story_single_sentence_v1-internal-baseline`
   genau einmal **2 · Serverprüfung** klicken. **Keine neue Bestandsübernahme**,
   **kein erneuter Upload**, **keine Veröffentlichung**.
4. Erst ein tatsächliches `ready` zeigt **Servergeprüft · Veröffentlichung
   ausstehend**. Bei erneutem 546 stoppen und die passenden Shutdownfelder
   `reason`, `cpu_time_used`, `memory_used` einschließlich Ausführungszeitpunkt
   ermitteln; keine Wiederholungsschleife und keine weiteren hypothetischen Fixes.


## HTTP 400 bei „2 · Serverprüfung“ · 16.10.2026

**Ein reproduzierbarer Requestfehler ist lokal behoben; eine erneute Cloudprüfung
wurde nicht ausgeführt.** Der vorhandene Upload bleibt fortsetzbar. Für diesen
Fix ist **kein Function-Deployment erforderlich**: Es ändern sich ausschließlich
der Python-Publisher, Tests und Dokumentation. Der vom Nutzer gemeldete erfolgreiche
Deploy von `content-publish` gehört zum Zustand nach dem vorigen Auftrag.

### Befund und konkrete Ursache

Lesend gefunden: lokales Release `088f5eab-7347-406f-b9e6-cf5dbb985990`, Version
`story_single_sentence_v1-internal-baseline`, Publicationstatus `uploaded`, Upload
`dc4eb268-b9d1-4278-839d-0176d0db2f40`, erwartete Generation 0 und beide Parents null.
Drei vorhandene `private-finalize`-Jobs sind mit `PUBLISH_HTTP_400`, `result=null`,
`processed=0`, `total=10` gescheitert. Das bestehende Neun-Dateien-Bundle besteht
auch jetzt `inspect_bundle` einschließlich Quellen-/Inhaltspins. Keine neue
Bestandsübernahme, kein Umschreiben der tatsächlichen Statusdaten.

Der konkrete Aufrufpfad ist:
`EditorService.publish_release(..., 'finalize')` →
`Publisher.call(upload_id + '/finalize')` → `Publisher._http` →
`content-publish/index.ts` → `handler('publish', ...)` → `publish()`.
Bisher blieb `body=None`; urllib erzeugte somit einen POST ohne JSON-Body.
`publish()` authentisiert zunächst JWT/Publisher und parst danach **für jeden
POST** den Body mit `JSON.parse`. Ein leerer Body löst einen Syntaxfehler aus;
`handler` antwortet darauf mit HTTP 400 / `{"code":"REQUEST_FAILED"}`.
Dieser Fehler liegt vor `backend.upload()` und vor jeder Datei-/Hashprüfung.

Die lokale Reproduktion mit demselben Handler zeigt für normalen Release und
Bestandsübernahme: leerer POST → **400 / REQUEST_FAILED**, null Upload-/Dateizugriffe;
POST mit `{}` → **200 / verifying**, genau die erste Dateiprüfung. `null` und `[]`
bleiben als unerlaubte Anfrageobjekte gesperrt. Der Vertrag wird nicht gelockert.
Die echte Wire-Serialisierung ist zusätzlich in Python geprüft (`data == b'{}'`,
`Content-Type: application/json`). GET bleibt ohne Body; Start-/Commitdaten werden
unverändert übertragen.

Damit ist ein stets fehlschlagender Request im lokalen Code belegt und behoben.
Die **historische Cloudantwort** lässt sich aus den vorhandenen Belegen nicht
rekonstruieren: `_http` hatte ihren Body verworfen, und `handler` übermittelt bei
unbekannten Fehlern ohnehin nur `REQUEST_FAILED`. Ob beim damaligen Cloudaufruf
zusätzlich ein Gateway-/Backendproblem bestand, ist damit nicht behauptet.
Leere Invocations oder Boot-/Shutdownlogs beweisen keine bestimmte Fehlerursache.

### Sichere Diagnose

`PublicationHTTPError.finding()` enthält jetzt zusätzlich `diagnostic` mit
`step`, `http_status`, `server_code` und `reason`. Diese Struktur erreicht über den
bestehenden Servicepfad sowohl den fehlgeschlagenen Job als auch `last_error` am
Publicationbeleg. Der sichtbare Meldungstext enthält dieselben sicheren Angaben,
beispielsweise `Serverprüfung: HTTP 400 · REQUEST_FAILED. Server konnte die
Anfrage nicht verarbeiten.` Der Releasezustand wird dadurch nicht aufgewertet.

Es werden höchstens **16.385 Bytes** gelesen, höchstens **16.384 Bytes** als JSON
akzeptiert. Nur fest freigegebene Vertragscodes oder numerische Fehlercodes
400–599 werden übernommen. Begründungen sind lokale Texte; zwei bekannte
Gatewaymeldungen werden ebenfalls auf lokale Texte abgebildet. Unbekannter
Freitext, fremde Codezeichenfolgen, HTML, fehlerhaftes UTF-8, übergroße Antworten,
Header, Cookies, JWTs, Schlüssel, Pfade und signierte URLs werden nicht reflektiert.
Die vorhandene UI verwendet Textdarstellung, keinen HTML-Import. Die separate
Passwortfehlerbehandlung bleibt erhalten. Fehler bleiben Fehler; eine Testantwort
`ready` wird nicht als erfolgreiche Cloudprüfung ausgegeben.

### Jetzt genau einmal fortsetzen

1. Alten Editor im Startterminal mit **Ctrl+C** beenden. Mit demselben
   Arbeitsverzeichnis und der bisherigen Umgebung neu starten; keinen zweiten
   Editor auf derselben Datenablage öffnen.
2. Windows (PowerShell): `pipeline\.venv\Scripts\python.exe -X utf8 -m sprachpipe.editor`.
   macOS (Terminal): `pipeline/.venv-macos/bin/python -X utf8 -m sprachpipe.editor`.
   Bisherige `--data-dir`-Argumente gegebenenfalls beibehalten.
3. Unter **Versionen** gegebenenfalls erneut mit Passwort anmelden, dann beim
   **bestehenden** `story_single_sentence_v1-internal-baseline` genau einmal
   **2 · Serverprüfung** klicken. Weder erneut übernehmen noch **1 · Privat
   hochladen** oder **3 · Veröffentlichen** anklicken.
4. Bei Erfolg steht **Servergeprüft · Veröffentlichung ausstehend**. Dieser
   Zustand ist hier noch nicht für die Cloud nachgewiesen.
5. Falls es erneut scheitert, den vollständigen **neuen sichtbaren Fehlertext**
   bzw. nur `error.code` und `error.diagnostic` des neuen Jobs mitteilen.
   Benötigt werden Schritt, HTTP-Status, vorhandener sicherer Servercode und
   Begründung. Keine Authdaten oder vollständigen Cloudantworten senden.
   Bei weiterhin bloßem `REQUEST_FAILED` fehlt die interne Exception-Kategorie
   der passenden Invocation; dieser Clientfix allein kann sie nicht ermitteln.
   Das wäre ein neuer, gezielter Diagnoseauftrag, kein Anlass für weitere
   hypothetische Änderungen oder erneute Uploads.

### Tatsächliche lokale Prüfungen dieses Fixes

| Befehl / Prüfung | Relevanter Output | Exit |
|---|---|---|
| `pipeline/.venv/Scripts/python.exe -X utf8 -m pytest pipeline/tests/test_editor_publisher.py -q --tb=short` | `20 passed in 4.38s`; echte urllib-Serialisierung, begrenzte sichere Diagnose, Job-/Belegfortsetzung mit derselben Upload-ID, normale Review-/Bundleprüfungen | 0 |
| `deno test --allow-read supabase/functions/_shared/content_distribution_test.ts supabase/functions/_shared/content_baseline_adoption_test.ts` | `10 passed`, `0 failed (7s)`; leerer Body reproduziert 400, `{}` erreicht Prüfung für beide Arten; Rechte-/Hash-/Review-/Quellen-/Generationtests erhalten | 0 |
| Bestehendes lokales Bundle `inspect_bundle` ausschließlich lesend | `9 files; source/content pins accepted`, weiterhin `uploaded`, ursprüngliche Upload-ID | 0 |

Pythonpfade oben sind Windows-spezifisch; auf macOS
`pipeline/.venv-macos/bin/python` mit denselben Argumenten verwenden.
Rohlogs und Schutzsnapshot liegen unter `build/finalize_http400/`.
Keine Cloudanfrage, Statusmutation, Veröffentlichung, SQL-Änderung oder Deployment
für diese Diagnose ausgeführt; kein Push.


Abschlusskontrolle dieses Fixes: **29** vorab gehashte Produktions-/Editor-Dateien
(einschließlich vorhandenem Bundle, Uploadbeleg und Jobs) unverändert. Die
Editor-Dateiliste wurde nicht erweitert. `git diff --check` für eigene Dateien
und `git diff --cached --check` jeweils ohne Befund, Exit 0; NEXTSTEPS im
Arbeitsbaum und Index jeweils 25 Zeilen. Fünf eigene Dateien isoliert gestagt;
fremde Diffabschnitte unverändert und ungestagt.

GitNexus ist an `sprachlernapp`, `C:\Users\ardas\Music\sprachapp`, Basis `5ec01f8`
gebunden und wurde aktualisiert. Die Konzeptabfrage löste den konkreten Finalize-
Aufruf nicht vollständig auf; direkte Quellen ergänzen diese bekannte Graphgrenze.
Datei-Impact Publisher: LOW, direkter Serviceimport und indirekter Editorstart.
Strukturierte Änderungsprüfung vor Commit: `scope=all` 21 Dateien/24 Symbole/303
Prozesszuordnungen, `scope=staged` fünf eigene Dateien/12 Symbole/243 Zuordnungen,
beide **CRITICAL**, ohne `error`, `partial` oder `truncated`. Die Risikomeldung
wurde ausdrücklich gemeldet und nicht als Low umgedeutet. Keine vollständige
statische Ablaufabdeckung oder erfolgreiche Cloudprüfung daraus abgeleitet.

## Implementiert und lokal geprüft · 16.10.2026

Der genehmigte Erstübernahmeweg `internal-baseline-adoption-v1` ist implementiert.
Er erzeugt nach ausdrücklicher Nutzerbestätigung ein eigenes lokales Release,
ohne `draft_id`, ohne neue Sprachfreigabe und ohne Umschalten von Editorhead oder
Produktionsasset. **In diesem Auftrag entstand nur ein synthetisch bestätigtes
Testrelease in einem isolierten Arbeitsverzeichnis.** Der echte Editor enthält
weiterhin keine von uns registrierte Bestandsübernahme. Keine Cloudaufrufe,
Deployments, Uploads, Veröffentlichungen, Passwortänderungen oder Pushes.

### Jetzt genau klicken

1. Den bisher laufenden Editor in seinem Startterminal mit **Ctrl+C** beenden und
   mit dem aktualisierten Code neu starten. Keinen zweiten Prozess auf demselben
   Arbeitsverzeichnis starten. Die bisherige Datenablage beibehalten.
2. **Versionen** → **Vorhandenes App-Pack als erste interne Version übernehmen**.
3. Quelle `story_single_sentence_v1`, 3.768 Karten, 14 Stapel, 402 Formziele,
   vorhandene Nachweise und offene Befunde lesen. Unter **Gebundene Quelle und
   Nachweishashes** stehen die exakten Bindungen.
4. Nur wenn diese interne Bestandsübernahme gewollt ist: **Diesen internen Bestand
   übernehmen**. **Abbrechen** erzeugt kein Release. Der Hinweis lautet:
   „Übernimmt den bereits verwendeten internen Bestand. Damit bestätigst du keine
   neue sprachliche Gesamtprüfung.“
5. Nach Abschluss steht `story_single_sentence_v1-internal-baseline` in der Liste:
   **Interne Bestandsübernahme · keine neue Sprachprüfung**, Status
   **Lokal vorbereitet · noch nicht hochgeladen**. Bei einem Fehler gibt es
   keinen gültigen Releaseeintrag; die Vorschau kann erneut geöffnet werden.
   Wiederholte Bestätigung derselben gebundenen Quelle liefert das vorhandene,
   erneut geprüfte lokale Bundle statt einer zweiten Version.

Editorstart aus dem Repository, falls bisher der direkte Modulstart verwendet wurde:

Windows (PowerShell):
```powershell
pipeline\.venv\Scripts\python.exe -X utf8 -m sprachpipe.editor
```
macOS (Terminal):
```sh
pipeline/.venv-macos/bin/python -X utf8 -m sprachpipe.editor
```
Die bereits verwendeten Auth-Umgebungsvariablen und gegebenenfalls bisherigen
`--data-dir`-Parameter beibehalten. Für die lokale Übernahme ist kein Login nötig.
Den vorhandenen 181-Ziele-Entwurf weder bestätigen noch exportieren.

### Späteres Deployment und Veröffentlichung – nicht ausgeführt

Nur die schreibende Function **content-publish** braucht für diesen neuen Pfad
neu bereitgestellt zu werden. Beide Einstiege importieren den gemeinsamen Vertrag,
aber `content-release` ruft nur `release()` auf; dessen Reader-/Downloadverhalten
ist unverändert. Der neue JSON-Quellenanker wird statisch aus dem gemeinsamen
Modul importiert und mit der Function gebündelt. Keine SQL-Migration erforderlich:
Die bestehende RPC sperrt den Kanal und vergleicht Generation und beide Parents.

Nach gesonderter Deploymentfreigabe, identisch in PowerShell und macOS-Terminal:
```text
supabase functions deploy content-publish --project-ref yevntxclpchapacqdizm
```
JWT-Verifikation bleibt eingeschaltet; keinen `--no-verify-jwt`-Schalter ergänzen.
Danach im Editor anmelden und beim lokal vorbereiteten Bundle getrennt klicken:

1. **1 · Privat hochladen** → erst nach vollständigem Upload **Hochgeladen ·
   serverseitige Prüfung fehlt**. Der Server muss den leeren Kanal nachweisen.
2. **2 · Serverprüfung** → erst nach vollständiger Prüfung **Servergeprüft ·
   Veröffentlichung ausstehend**.
3. **3 · Veröffentlichen** → Bestätigungsdialog **Jetzt veröffentlichen**.
   Erst erfolgreicher atomarer Commit ergibt **Privat veröffentlicht**.

Ist der Kanal inzwischen belegt, stoppt die Bestandsübernahme mit Konflikt.
Sie ist ausschließlich für Englisch/internal, `internal_test_pack=true`,
Generation 0 und zwei null-Parents zulässig. Hier wurde kein Cloudkanal abgefragt.

### Vertrag und enge Grenzen

- `baseline_adoption.py` löst die Quelle ausschließlich aus dem serverseitigen
  App-Manifest auf. Die HTTP-Anfrage enthält genau `preview_sha256` und
  `accepted=true`; Browser-Dateipfade und zusätzliche Felder werden abgewiesen.
- Der versionierte Anker `supabase/functions/_shared/internal_baseline_source.json`
  wurde aus der aktuellen Manifestquelle und deren echter Schema-5-Konvertierung
  gewonnen. Er bindet Manifest-, Quell-SQLite-, Asset-, Pack-Byte-/kanonischen,
  Registry-, Finalisierungs- und historische QA-Payload-Hashes sowie den gesamten
  konvertierten Inhalt und die SQLite-Bytes. Kein veralteter Versionspfad wird
  vom Browser ausgewählt. Eine neue Manifestquelle oder abweichender Exporter
  sperrt diesen engen v1-Pfad und benötigt eine gesondert geprüfte Ankeränderung;
  es gibt keine automatische Neuberechnung vertrauenswürdiger Hashes im Betrieb.
- Der konvertierte Inhaltsdigest umfasst alle fachlichen Felder, IDs, QA-Payloads,
  Lernbarkeit, Formfunktionen, Wortbesitz, Zuordnungen und technischen Snapshots
  einschließlich Historie. Nur `release.created_at` wird getrennt auf den festen
  technischen Reproduzierbarkeitswert `2026-10-16T00:00:00Z` geprüft. Dieser Wert
  bezeichnet keine tatsächliche Prüfung oder Nutzerbestätigung. Der echte lokale
  Bestätigungs- und Registrierungszeitpunkt wird separat erfasst.
- Die Bytebindung wurde unter Python/SQLite **3.40.1** geprüft. Ein anderer
  SQLite-/Exporterstand kann andere Bytes erzeugen und wird dann ausdrücklich
  blockiert. macOS-Ausführung dieses neuen Builds wurde nicht behauptet.
- `editorial_reviews.json` bleibt leer. Die Validierung lautet
  `technical=valid`, `editorial=existing-evidence-only`. `provenance.json`
  enthält den hashgebundenen Übernahmebeleg mit ausdrücklicher Bestätigung,
  vorhandenen Nachweisen und offenen Befunden. Kein erfundener Reviewer,
  keine `scope=draft`-Sprachfreigabe und kein `editorial=approved`.
- Gemeinsame Bundlemechanik wurde aus `build_release` extrahiert; dessen normale
  Zulassung bleibt technisch gültig **und** redaktionell bestätigt. Die eigene
  Übernahmefunktion verwendet dieselbe Konvertierung, 23-Tabellen-Readback,
  Dart-Reader-/Historienprüfung und das bestehende Neun-Dateien-Bundle.
- Lokale Registrierung erfolgt erst nach vollständiger Prüfung; Stagingreste
  werden bei Fehlern entfernt. Entwürfe/Reviews/Editorhead werden nicht angepasst.
  Der neue Releaseeintrag führt seine Art statt einer fingierten `draft_id`.
- Serverstart und Finalisierung prüfen den leeren Kanal. Beim Commit bleibt die
  bestehende SQL-Transaktion mit Kanalzeilensperre und CAS maßgeblich; ein paralleler
  Gewinner macht den anderen Versuch zum Konflikt. JWT, Rechte, RLS, Dateisatz,
  Größen-/Hashprüfung und normaler Reviewvertrag bleiben erhalten.
- Geprüfte Zustände sind getrennt: Ein lokales Bundle behauptet **keinen** leeren
  Cloudkanal. Das Verhalten wurde mit injizierten Testtransporten und einer
  wegwerfbaren lokalen SQL-Datenbank geprüft, ohne Cloudzugriff.

### Tatsächliche Abnahme

Befehle aus dem Repository; Pythonpfad hier Windows. Unter macOS durch
`pipeline/.venv-macos/bin/python` ersetzen; Dart/Deno/Flutter sind identisch.
Dart-basierte Prüfungen unter Windows **nacheinander** ausführen, da deren
Native-Asset-Buildhook dieselbe `sqlite3.dll` verwendet. Keine Timeouts erhöht.

| Tatsächlicher Befehl | Relevanter Output | Exit |
|---|---|---|
| `pipeline/.venv/Scripts/python.exe -X utf8 -m pytest pipeline/tests/test_editor_service.py pipeline/tests/test_editor_publisher.py pipeline/tests/test_baseline_adoption.py -q --tb=short` | `24 passed in 42.10s` | 0 |
| `pipeline/.venv/Scripts/python.exe -X utf8 -m pytest pipeline/tests/test_baseline_adoption_http.py -q --tb=short` | `1 passed in 3.19s`; Authpflicht, Vorschau, keine freien Pfade/implizite Bestätigung | 0 |
| `pipeline/.venv/Scripts/python.exe -X utf8 build/baseline_adoption/real_build.py` | Vollständiger finaler Realbuild; 23 Tabellen; unveränderter Testentwurf und Testhead; synthetische Bestätigung | 0 |
| `deno test --allow-read supabase/functions/_shared/content_distribution_test.ts supabase/functions/_shared/content_baseline_adoption_test.ts` | `9 passed`, `0 failed`; echte Quelle, Inhalts-/Beleg-/SQLite-Manipulation, Kanalgrenze | 0 |
| `pipeline/.venv/Scripts/python.exe -X utf8 pipeline/tests/check_baseline_adoption_cas.py` | `2 concurrent generation-0 commits; 1 winner, 1 conflict; generation=1; catalog=1; retry idempotent`; Rechte/Parents/Generation abgewiesen, Testdatenbank entfernt | 0 |
| `flutter test --no-pub test/data/real_pack_test.dart` | `+1: All tests passed!`; 14 Stapel, 3.767 Karten, 203 Alternativen | 0 |
| `dart run tool/stage_content_pack.dart --verify` | `verified assets\content\en\content.sqlite`; Schema 4, 26.198.016 Bytes, `22 table counts match finalization_report.json` | 0 |
| `flutter test --no-pub test/data/baseline_adoption_pack_test.dart` | `+1: All tests passed!`; neues Manifest/23-Tabellen-Inventar und Schema-4-Historie akzeptiert; Asset unverändert | 0 |
| `node --check pipeline/src/sprachpipe/editor/web/app.js` | Keine Syntaxfehler | 0 |
| `pipeline/.venv/Scripts/python.exe -X utf8 build/content_initial_release/verify_protection.py` | 13 geschützte Dateien, davon acht echte Editor-Datendateien, unverändert; Editor-Dateiliste identisch; NEXTSTEPS 25 Zeilen | 0 |

Nach Ergänzung der getrennten Zeitstempel-/SQLite- und Validierungsbindung erneut gezielt geprüft:
`pipeline/.venv/Scripts/python.exe -X utf8 -m pytest pipeline/tests/test_baseline_adoption.py pipeline/tests/test_baseline_adoption_http.py -q --tb=short`: **5 passed in 30.44s**, Exit 0.
Der Deno-Gegencheck erneut **9 passed / 0 failed (8s)**, Exit 0.

Der reproduzierbare Realbuild-Helfer liegt jetzt unter
`pipeline/tests/check_baseline_adoption_real.py`: Jeder Lauf erzeugt ein neues
isoliertes Testarbeitsverzeichnis und schreibt `build/baseline_adoption/real-result.json`
für den expliziten Deno- und Flutter-Integrationstest. Diese beiden Integrationstests werden ohne erzeugtes Testbundle ausdrücklich übersprungen; bei dieser Abnahme liefen sie vollständig. Niemals dessen synthetisches Testrelease
in den echten Editor kopieren. Rohlogs liegen in `build/baseline_adoption/`.

Aufgetretene Fehler wurden geklärt: Der erste unabhängige Referenzexport hatte
unterschiedliche automatisch erzeugte `content_releases.created_at`-Werte;
der feste technische Zeitpunkt behebt diese Metadatenabweichung. Der erste
parallele Pythonlauf ergab 22 PASS/2 Setupfehler wegen der offenen Windows-DLL
(`PathAccessException`, Zugriff verweigert); nach Ende des anderen Dart-Readers
bestand der sequenzielle Lauf. Der neue HTTP-Test benötigte noch den expliziten
Import seiner `setup`-Fixture; danach bestand er. Kein Timeout wurde erhöht.

Die reale Konvertierung liest 3.767 aktive Ziele und 4.297 historische Kontexte;
402 Formziele/Formmitgliedschaften und acht aus bestehenden QA-Nachweisen
übernommene Storykorrekturen sind erhalten. 137 alte Provenienzlücken, 506 alte
`i+1`-Warnungen, die zwei Maya-Stellen und weitere Sprach-/Glossengrenzfälle bleiben
sichtbar offen; sie werden weder als neue Verluste noch als behoben ausgewiesen.

Browserprüfung im separaten synthetischen Editor: Vorschau mobil und 1280px Desktop,
Quellenbindung/Altbefunde/Bestätigungstext sichtbar, Abbrechen ohne Release.
![Desktopvorschau](evidence/content-editor-initial-release/adoption-desktop.png)

### Abschließende Änderungsprüfung und Isolation

GitNexus für `sprachlernapp` / `C:\Users\ardas\Music\sprachapp`, Basis `848986c`:
Reindex erfolgreich (19.102 Knoten, 40.736 Kanten, 374 erfasste Flows).
Exakte Datei-Impacts: Autorendienst MEDIUM, Editorservice/Server/Publisher und
Distribution LOW; reine Symbolnamen lieferten falsche Referenzkopien bzw. UNKNOWN.
Die erste Namensabfrage `build_release` meldete HIGH und wurde ausdrücklich
gewarnt. UNKNOWN wurde anhand konkreter Service-/HTTP-/JS-/Function-Aufrufe
aufgelöst. Der Index meldet weiterhin begrenzte dynamische/cross-language
Auflösung und ausgelassene Flows; eine leere Kante gilt nicht als unbenutzt.

Strukturierte `detect_changes(scope=all)` vor Commit: 38 Dateien, 48 Symbole,
303 zugeordnete Prozesse, **CRITICAL**. `scope=staged`: genau 22 eigene Dateien,
38 Symbole, 303 Prozesse, ebenfalls **CRITICAL**. Beide Abfragen ohne `error`,
`partial` oder `truncated`; die eigenständigen Index-Abdeckungsgrenzen bleiben.
Das Integrationsrisiko wurde ausdrücklich gemeldet und nicht heruntergestuft.

`git diff --cached --check`: Exit 0 nach Entfernen einer zusätzlichen Leerzeile
am Ende des neuen Testhelfers. 16 fremde Diffabschnitte sind bytegleich erhalten.
NEXTSTEPS enthält im Arbeitsbaum und Index jeweils 25 Zeilen. Sein fremder
Arbeitsbaumanteil bleibt ungestagt; der Index erhält alle bisherigen HEAD-Fakten,
verlustfrei zusammengerückt, sowie die drei eigenen Erstübernahmezeilen.

Zusätzlicher Vergleich der tatsächlichen Readerberichte:
`current identical: True`, `historical identical: True`,
`story_display identical: True`. Die Übernahme prüft aktive Readeransichten auch
im Build ausdrücklich. Der Stand von 13 geschützten Dateien einschließlich acht
echter Editor-Datendateien und deren Dateiliste blieb unverändert.

## Archiv: rein lesende Voruntersuchung vor der Implementierung

Die folgenden Befunde und damaligen Handlungsempfehlungen dokumentieren den
Ausgangszustand. Der oben beschriebene implementierte Weg ersetzt den damaligen
Vorschlag; die Inhaltsbefunde und der Nachweis der 181 Ziele gelten weiter.


Stand: 16.10.2026, Checkout `C:\Users\ardas\Music\sprachapp`, Commit `848986c`.
**Ergebnis: Für diesen unveränderten internen Schema-4-Bestand gibt es noch keinen
unterstützten Erstübernahmeweg ohne neue lokale redaktionelle Freigabe.**
Generation 1 ist serverseitig vorgesehen, setzt aber bereits ein gültiges
Schema-5-Releasebundle voraus. Deshalb wurde kein Bundle durch eine erfundene
Bestätigung erzeugt und nichts hochgeladen. Dieser Bericht enthält einen
Änderungsvorschlag, keine implementierte oder freigegebene neue Funktion.

## Was jetzt konkret zu tun ist

1. Im Dialog **Redaktionell bestätigen** auf **Abbrechen** gehen, solange die
   dort behauptete Prüfung nicht tatsächlich stattgefunden hat. Keine Prüfperson
   oder Prüfnotiz ersatzweise eintragen. Der vorhandene Entwurf bleibt erhalten.
2. **Versionen** kann geöffnet und die vorhandene Anmeldung weiterverwendet werden.
   Die leere Liste bedeutet: Es existiert kein registriertes lokales Releasebundle.
   Anmeldung oder **Nach Updates suchen** in der App erzeugen keine erste Version.
3. Zuerst den unten abgegrenzten Auftrag **„Interne Bestandsübernahme als
   Erstversion implementieren, ohne neue Sprachfreigabe“** freigeben.
   Einen passenden Übernahmebutton oder CLI-Befehl gibt es derzeit nicht.
   Nach Implementierung und lokaler Prüfung wäre das neue Bundle separat
   hochzuladen, serverseitig zu prüfen und ausdrücklich zu veröffentlichen.

Insbesondere jetzt nicht **Prüfung bestätigen**, **Export starten** mit dem
Releaseformat, **Asset gesichert übernehmen** oder einen manuellen Datei-/SQL-Import
als Ersatz für diese fehlende Funktion verwenden. Die normale Entwurfsfreigabe
bleibt für tatsächlich redigierte Inhalte weiterhin der richtige Weg.

## Die 181 Ziele: konkrete Daten statt vermuteter Änderungen

Es wurde ausschließlich der bestehende Dateistand gelesen. Kein zweiter
`EditorService`/`EditorStore` wurde auf dem Arbeitsverzeichnis gestartet; solche
Starts könnten Sperrdatei, Jobs oder Wiederherstellungsbelege verändern.
Keine Browsernavigation wurde automatisiert, weil sie die Auswahl speichern kann.

Arbeitsverzeichnis: `%LOCALAPPDATA%\SprachappContentEditor`.
`workspace-view.json` wählt Englisch, Stapel `allgemeine-sprache`, Entwurf
`2139ad7f-d6f1-4787-9fff-146cf050c509`. `current.json` verweist auf Revision 2.

| Prüfung | Gelesener Befund |
|---|---|
| Stapel | „Allgemeine Sprache“, Anfänger, Positionen 1–181 |
| `target_refs` | 181 Einträge, 181 verschiedene Referenzen; exakt alle aktiven `deck_cards` dieses Stapels, in derselben Reihenfolge |
| Inhaltliche Änderungen | `operations=[]`, `add={}`, `delivery_ids=[]`, `provenance=[]`; keine Ergänzung und kein Import |
| Lokale Freigaben | `reviews=[]` |
| Revision 1 → 2 | Nur `revision`, `updated_at`, `validation` geändert; keine fachlichen Felder |
| Inhaltshash beider Revisionen | `cd1904b28f2e9f202e91012d096d7bd8403187a192ecb319ebc550f5f81323fd` |
| Gespeicherte Validierung | `technical=valid`, `editorial=open`, 40 `i+1`-Warnungen, keine Fehler |
| Bindung des Prüfberichts | Eigener Berichtshash und Inhaltshash nachgerechnet, beide stimmen |
| Basis und Quelle | Gespeicherter Basispack ist strukturell identisch mit dem manifestgebundenen `pack.json`; Rohdateihash und lokaler Head stimmen ebenfalls |
| Lokale Veröffentlichung | 0 Einträge unter `releases/`; kein `bundles/`-Verzeichnis |

Beispiele aus der vollständigen Liste:

| Position | Form | Exakte Referenz |
|---|---|---|
| 1 | the | `the\|the/DET\|the#bestimmter_artikel` |
| 2 | to | `to\|to/ADP\|to#nach_richtung` |
| 3 | and | `and\|and/CCONJ\|and#und` |
| 181 | written | `irregular:write:past_participle` |

Alle 181 Referenzen mit Position, Form, Hinweis, aktivem Satz und bestehenden
QA-Metadaten stehen in [draft-audit.json](evidence/content-editor-initial-release/draft-audit.json).
Die Zahl bezeichnet den ausgewählten Reviewumfang, **nicht 181 neue oder fehlerhafte
Aufgaben**. Der gespeicherte Bericht nennt `draft_revision=1`, weil die damalige
technische Validierung erst anschließend als Revision 2 gespeichert wurde.
Der identische Inhaltshash belegt hier keinen zwischenzeitlichen Inhaltswechsel.

### Weshalb die Bestätigung verlangt wird

- `EditorService.new_draft` (`pipeline/src/sprachpipe/editor/service.py:105`)
  übernimmt beim Kopieren eines Stapels alle aktiven Mitgliedschaften in
  `target_refs` und setzt `reviews` leer. Es filtert dort nicht nach Änderungen.
- `review()` in `editor/web/app.js:130` nennt unmittelbar die Länge von
  `target_refs` und fordert Satz, Übersetzung, Lücke, Bedeutungen, Kontextglossen
  und Alternativen zu prüfen. Der Dialog trifft keine Aussage aus einem Diff.
- `validate_draft` (`authoring_service.py:462`) behandelt technische Befunde und
  redaktionelle Entscheidung getrennt. `editorial=approved` entsteht nur durch
  einen vorhandenen `decision=approved` mit passendem `draft_content_hash`.
  QA-Metadaten in alten Sätzen werden nicht automatisch zu einer neuen
  `scope=draft`-Bestätigung des aktuellen Entwurfs.
- `EditorService.review` bindet eine ausdrücklich eingegebene Prüfperson/Notiz an
  den aktuellen Inhaltshash. `build_release` (`authoring_service.py:530`) fordert
  danach ausdrücklich technisch gültig **und** redaktionell bestätigt;
  sonst `RELEASE_BLOCKED`. Auch ein neuer Entwurf ohne Stapel/mit null Zielen
  ersetzt diese Freigabeanforderung nicht.

Das entspricht der Trennung im [Editorvertrag](content-editor-contract.md),
Abschnitte 3 und 10. Es liegt hier keine neue Bearbeitung vor, sondern eine
fehlende eigene Workflowart für die Übernahme eines bereits intern verwendeten
Bestands. Die bestehende Prüfung wird deshalb nicht ausgeschaltet.

## Maßgebliche Quelle und vorhandene Nachweise

Die Quelle wurde aus `assets/content/en/content.manifest.json` aufgelöst,
nicht aus einem Versionsnamen geraten oder aus dem älteren Paketbericht übernommen.

| Bindung | Aktueller Wert |
|---|---|
| Version / Assetformat / Schema | `story_single_sentence_v1` / 1 / 4 |
| SQLitequelle | `pipeline/out/story_single_sentence_v1/content.sqlite` |
| SQLitegröße | 26.198.016 Bytes |
| SQLite-SHA256, Quelle und Asset identisch | `b85793932825a22e92ac744a42255e9f333acd35809aaba46edb5a395f099bdb` |
| Assetmanifest-SHA256 | `74a0bce4d16bb3084f762dd6afc69accc44c80db545dba9871b21d0b8c7adbfe` |
| Quell-`pack.json`, Bytehash | `313ea762423478c932cb3c92a512ffd07281afed9028a17b9f6ec3a00b7a9aa5` |
| Quell-`pack.json`, kanonischer Hash | `fd3ce96b3472d083ca07d7adbcfed5ec82975db1a451a967073510e9a01932fb` |
| Registryhash | `4736bf4819a17cdabd5f57a60f08f53760ade24ef45e87464e1fcbeaa39dc97e` |

Der Quellordner enthält genau `content.sqlite`, `pack.json` und
`finalization_report.json`. Der Releasehinweis lautet bereits ausdrücklich:
`INTERNES TEST-PACK: targeted offline curation; unchanged rows not newly reviewed; no AI QA.`

Die Nachweise haben unterschiedliche Geltungsbereiche:

1. **Technische Finalisierung:** vorhandener Bericht `status=ok`, Linter
   0 Fehler/506 `i+1`-Warnungen, 22 Tabellen, `ai_calls=0`. Dies ist keine
   sprachliche Gesamtfreigabe. Zwei dokumentierte Storystellen „Maya“ bleiben
   als Eigennamen von der Lernaufnahme ausgenommen.
2. **Bestehende Satznachweise:** im Gesamtpack 602 Sätze mit `qa_status=ok` und
   3701 mit `editorial_reviewed`; alte/historische Sätze sind darin enthalten.
   Für die 181 aktiven ausgewählten Aufgaben sind es 131 `ok` und 50
   `editorial_reviewed`. Bei den 50 stehen 29 `editorial`- und 21
   `editorial_create`-Nachweise. Diese Metadaten werden hier gezählt und erhalten,
   nicht erneut inhaltlich bewertet oder zu menschlichen Zertifikaten umbenannt.
   Beispielsweise grenzt ein vorhandener `editorial`-Nachweis seine Herkunft
   ausdrücklich als Chat-Modellreview mit `human_approval=false`,
   `vertex_validation=false` und `public_release=false` ab.
3. **Gezielte historische Änderungen:**
   [Kontextkorrekturen](context-quality-applied-v1.md) dokumentieren genau ihre
   drei Operationen und die weiter offenen Befunde;
   [Story-Einzelsätze](story-single-sentence-v1.md) dokumentiert 14 damalige
   Wortstellen/acht geänderte Kontexte. Die Ein-Satz-Lieferung liegt unter
   `pipeline/data/curation/story_single_sentence_v1.json`; sie ist keine
   Freigabe aller Stapel.
4. **Offene Altbefunde:** 137 bereits vorhandene fehlende Provenienz-Satz-IDs
   und die früher dokumentierten Sprach-/Glossengrenzfälle bleiben offen.
   Der bestehende Read-only-Audit wurde erneut ausgeführt und bestätigt
   unverändert 137 Lücken, 530 historische Links und 402 Formmitgliedschaften.
   Eine interne Übernahme muss das sichtbar mitführen; technische Gültigkeit
   darf diese Befunde nicht verschwinden lassen.

## Unterstützter Weg und konkrete Lücke

| Stufe | Bestehendes Verhalten | Konsequenz für dieses Pack |
|---|---|---|
| Editorstart | `install_base` registriert nur Basis und Sprachhead | Keine automatische lokale Releaseversion aus dem App-Asset |
| Versionsliste | `GET /api/v1/releases` liest `EditorStore.list('releases')` | `pipeline/out/` und Assets werden nicht als Releases aufgelistet |
| Releaseexport | `POST /drafts/{id}/releases` → `EditorService.release` → `build_release` | Gebundene Entwurfsfreigabe, Schema-5-Konvertierung, Reader-/Historienprüfung und neun Dateien erforderlich |
| Lokales Hochladen | `publish_release` lädt `draft_id`, prüft exportierte Revision und `inspect_bundle` | Keine Registrierung eines unabhängigen Bestandsbundles ohne Entwurf unterstützt |
| Cloudstart | `validateStart` in `_shared/content_distribution.ts:23` | Manifestformat 2, Schema 5, englisches Profil, internes Pack und exaktes Neun-Dateien-Set erforderlich |
| Cloudfinalisierung | `verifyBundle` in `_shared/content_distribution.ts:94` | `validation.editorial=approved` und an den Inhaltshash gebundener Review erforderlich |
| Erste Generation | Erwartete Generation 0 und null Parent werden akzeptiert | Dies ermöglicht die erste Veröffentlichung eines **schon vertragsgültigen** Bundles, keinen Legacy-/Review-Sonderfall |

`supabase/functions/content-publish/index.ts` ist nur der Einstieg; die tatsächlichen
Prüfungen stehen im gemeinsam verwendeten `_shared/content_distribution.ts`.
Die neun Dateien sind: `content.sqlite`, `pack.json`, `registry.json`,
`history_inventory.json`, `editorial_reviews.json`, `provenance.json`,
`finalization_report.json`, `content.manifest.json`, `reader_report.json`.
Sechs davon fehlen als eigenständige Dateien im Quellordner; die vorhandenen drei
haben zudem den alten Vertrag. Registrydaten und QA-Nachweise sind teilweise im
Quellpack enthalten, aber kein Ersatz für die gebundenen Release-Sidecars.

Weder ein ZIP-/XLSX-Austauschexport noch das technische Assetstaging registriert
dieses Cloudbundle. Die ältere CLI `upsert --publish` schreibt Tabellenzeilen;
sie ist kein privater Release-/Storage-/Kanalweg und wurde nicht ausgeführt.
Manuelles Anlegen von Release-JSONs oder Revieweinträgen wäre eine Umgehung.
Cloudkanal/Generation wurden in diesem Auftrag nicht abgefragt; der spätere
Erstübernahmeweg muss Generation 0 serverseitig beweisen und bei einem inzwischen
belegten Kanal abbrechen.

## Kleinster konkreter Änderungsvorschlag — noch freizugeben

**Eine gesonderte interne Erstübernahmeart ergänzen; den normalen
Entwurfs-Reviewvertrag unverändert lassen.** Keine neue Autharchitektur,
kein Direktzugriff auf private Cloudtabellen, keine neue Sprachprüfung.

1. Eine lokale Aktion unter **Versionen**, beispielsweise **Internes App-Pack als
   Erstversion vorbereiten** (Vorschlagsname, heute nicht vorhanden). Der Dienst
   löst die Quelle ausschließlich aus dem vertrauenswürdigen App-Manifest auf
   und zeigt Version, Quellhashes, bestehende Nachweise und offene Befunde.
   Der Browser liefert keinen freien Dateipfad. Bei fehlender Quelle, Hashabweichung
   oder unvollständigen Nachweisen abbrechen, nicht auf einen anderen Pack raten.
2. Ein ausdrücklich eigener Übernahmebeleg: Art
   `internal-baseline-adoption-v1`, Quelle/Manifest/Pack-/Registryhashes,
   vorhandene Nachweisdateien mit Hash und tatsächlichem Prüfumfang, offene
   Befunde sowie später eine **wirklich vom Nutzer eingegebene** Bestätigung
   „diesen bereits verwendeten internen Bestand übernehmen“. Keine Prüfperson,
   Notiz oder sprachliche Entscheidung automatisch erzeugen. Keine neue
   `scope=draft`-Freigabe; bestehende Entwürfe und deren Reviews bleiben unangetastet.
3. Bestehende Schema-4→5-Konvertierung, SQLite-Readback, Dartreader und
   Historienvergleich wiederverwenden. Neues unveränderliches Bundle nur in
   einem eigenen temporären/lokalen Releaseverzeichnis erzeugen, ohne
   Produktionsasset oder aktuellen Editorhead umzuschalten. Identitäten,
   Lernbarkeit, aktive/historische Anzeigen und QA-Payloads müssen erhalten
   bleiben. Neue technische Snapshotspalten und Release-Metadaten sind separat
   auszuweisen; der Schema-5-SQLitehash wird sich ändern. Bei irgendeiner
   fachlichen Abweichung den Übernahmeweg sperren und zum normalen Reviewweg führen.
4. Bestehendes Neun-Dateien-Bundle behalten. Quellenbindung, Hashes und der
   ehrliche Übernahmebeleg gehören in `provenance.json`/Finalisierungsbericht und
   werden im Manifest gebunden. Historische Satznachweise bleiben unverändert
   im Pack. `editorial_reviews.json` enthält keine neu erfundene Freigabe;
   der neue Bericht muss „vorhandene Nachweise/keine neue Sprachprüfung“
   ausdrücklich von `technical=valid` unterscheiden. Keine Umdeutung zu
   `editorial=approved`. Den genauen additiven Belegvertrag vor Implementierung
   mit Positiv-/Negativfixtures festlegen.
5. Lokalen Release-Datensatz eindeutig als Bestandsübernahme kennzeichnen.
   `publish_release`/`inspect_bundle` prüfen dafür den unveränderlichen
   Übernahmebeleg statt einen fingierten `draft_id` zu verlangen. Normale
   Datensätze behalten exakt ihre bisherigen Revisions-/Reviewprüfungen.
6. Cloudprüfung nur für diese deklarierte Art additiv erweitern: englischer
   `internal`-Kanal, `internal_test_pack=true`, Generation 0, beide Parents null,
   vollständige Quellen-/Nachweisbindung und expliziter Übernahmebeleg zwingend.
   JWT, Publisher-/Reader-Allowlist, Hash-/Größen-/Dateisatzprüfung,
   Finalize/Commit-CAS und RLS unverändert. Nach belegtem Kanal darf dieser
   Sonderweg nicht erneut funktionieren; normale Folgeversionen brauchen
   weiterhin ihre bisherige Freigabe. Das erfordert eine spätere gezielte
   Anpassung/erneute Bereitstellung von `content-publish`, keinen heutigen
   Cloudzugriff und voraussichtlich keine SQL-Migration (Beleg in vorhandenen JSON-Feldern).

Gezielt betroffene Implementierungsdateien eines späteren Auftrags:
`editor/service.py`, `editor/server.py`, `editor/publisher.py`, `editor/web/app.js`,
`authoring_service.py` für getrennte Buildvoraussetzungen,
`functions/_shared/content_distribution.ts` für den tatsächlichen Cloudvertrag
sowie zugehörige Tests/Vertragsdokumentation. `EditorStore.put/list` kann den
typisierten Record voraussichtlich im vorhandenen `releases`-Bereich halten;
`store.py` braucht dann keine neue Speicherarchitektur. Flutter versteht das
bestehende Schema-5-Inhaltsformat; ein zusätzliches Manifestmerkmal müsste
gezielt auf Readerkompatibilität getestet werden, statt eine Appänderung
oder neue Protokollfähigkeit ungeprüft zu behaupten.

Lokale Abnahme des späteren Auftrags: Quellenhashänderung sperrt; kein neuer
Review entsteht; bestehende Entwürfe bleiben bytegleich; 23-Tabellen-Readback,
Reader-/Historienvergleich und festgehaltene Altbefunde; Generation 0 erlaubt,
Generation >0 und falsche Parents sperren; unbekannte Übernahmeart sperrt;
normaler Release ohne Review bleibt gesperrt; parallele Erstveröffentlichungen
verlieren sauber per CAS. Ein Umsetzen dieses Vorschlags erlaubt noch keinen
Upload oder Commit der Inhalte ohne einen gesonderten Auftrag.

## Tatsächliche Prüfungen dieses Auftrags

| Befehl / Prüfung | Relevanter Output | Exit |
|---|---|---|
| `dart run tool/stage_content_pack.dart --verify` | `verified assets\content\en\content.sqlite`; Version `story_single_sentence_v1`, Schema 4, 26198016 Bytes; SHA wie oben; `22 table counts match finalization_report.json` | 0 |
| `pipeline/.venv/Scripts/python.exe -X utf8 build/content_initial_release/audit_current.py` | 181 verschiedene aktive Stapelziele; keine fachliche Änderung; Basis exakt gleich Quellpack; Berichtshashes stimmen; 0 lokale Releases | 0 |
| `pipeline/.venv/Scripts/python.exe -X utf8 docs/evidence/story-single-sentence-v1/audit.py` | 22 Tabellen verglichen; unverändert 137 Provenienzlücken, 530 historische Links, 402 Formmitgliedschaften; Packhash wie oben | 0 |
| `pipeline/.venv/Scripts/python.exe -X utf8 -m pytest pipeline/tests/test_editor_service.py::test_supported_validation_and_unsupported_language_draft pipeline/tests/test_editor_publisher.py::test_changed_bytes_and_unapproved_export_are_rejected -q --tb=short` | `2 passed in 3.15s` | 0 |
| `deno test --allow-read supabase/functions/_shared/content_distribution_test.ts` | `5 passed`, `0 failed`; Rollen, Reviewbindung, Dateihashes, Scope und erste Generation synthetisch geprüft | 0 |

Pythonbefehle sind oben für Windows (PowerShell) angegeben. Auf macOS (Terminal)
denselben Argumenten `pipeline/.venv-macos/bin/python` voranstellen. `-X utf8`
gilt auf beiden Plattformen. Dart-/Deno-Befehle sind identisch. Die beiden
vorhandenen Audits verwenden die tatsächlich aufgelöste aktuelle Quelle;
der Scratch-Audit und Rohlogs liegen unter `build/content_initial_release/`.
Der versionierte JSON-Nachweis enthält die vollständige Liste und Messwerte.
Keine vollständige Testsuite und keine neue linguistische Abnahme durchgeführt.

GitNexus wurde für `sprachlernapp`/diesen Windows-Checkout auf `848986c`
aktualisiert (18.995 Symbole/381 erfasste Flows). Kontext für `new_draft`,
`release`, `publish_release` ist aufgelöst. Die Kernfunktionen in
`authoring_service.py` wurden vom Index nicht aufgelöst; eine CLI-Abfrage zu
`cmd_upsert` lieferte einen fremden Lieferungs-Referenzpfad und wurde verworfen.
Die direkten Quellen am expliziten Pfad wurden ergänzend gelesen.
Impact für `NEXTSTEPS.md` und `EditorService.release`: **UNKNOWN**, keine
Entwarnung. Textprüfung bestätigt NEXTSTEPS als Statusdokument sowie den
HTTP-Aufruf von `release` und den Aufruf im Browser. Es werden keine
Runtimefunktionen verändert. Der Graph ersetzt die obigen konkreten Belege nicht.

Abschließende Schutzkontrolle:
`pipeline/.venv/Scripts/python.exe -X utf8 build/content_initial_release/verify_protection.py`
meldet **13 Dateien hash- und größengleich**, darunter alle **acht
Editor-Datendateien**; auch deren Dateiliste ist identisch. Die aktive
Windows-Sperrdatei `process.lock` wurde nicht angefasst und vom Hashvergleich
ausgenommen. Exit 0. `NEXTSTEPS.md` hat jetzt genau **25 Zeilen**; sechs benachbarte
Faktenpaare wurden ohne Inhaltsverlust zusammengezogen, der laut Nutzer
funktionierende Passwortlogin aktualisiert und der neue Befund ergänzt.
Der vorhandene Fremdstand blieb erhalten.

`git diff --check -- NEXTSTEPS.md docs/content-editor-initial-release.md
docs/evidence/content-editor-initial-release/draft-audit.json`: keine Ausgabe,
Exit 0 für verfolgte Dateien. Die beiden neuen Dateien zusätzlich mit
`git diff --no-index --no-exit-code --check -- NUL <Datei>` unter Windows
geprüft (auf macOS `/dev/null` statt `NUL`); jeweils keine Fehlerausgabe,
aber Exit 1 wegen des Neudatei-Diffs, auch mit `--no-exit-code`.
Diese Neudatei-Diffs werden ausdrücklich nicht als Exit-0-Prüfung gewertet.
Der zusätzliche Python-Schutzcheck prüft beide neuen Dateien auf nachlaufende
Leerzeichen und besteht mit Exit 0.

Geändert wurden nur dieser Bericht, sein JSON-Nachweis und `NEXTSTEPS.md`.
Keine Runtimeimplementierung, keine neue Freigabe, kein Releasebundle und kein
Commit erstellt. Cloudkonto, Cloudschema, Uploads, Veröffentlichungen, Passwort,
Geräteinstallation, Produktionsasset und bestehende Entwürfe blieben unangetastet;
kein Push.
