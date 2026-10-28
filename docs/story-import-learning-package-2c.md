# Paket 2C – Abschluss des lokalen Zwischenstands c90680b

Stand: 24.10.2026. Implementierung und lokale Prüfung; **keine Cloud- oder
Gerätefreigabe**. Keine Migration, Function, Produktionspacks oder echten
Lernstände verändert; keine echten Modellaufrufe. Paket 3 nicht begonnen.

## Einwilligung und tatsächlicher Finderfehler

Unmittelbar vor der ursprünglich fehlschlagenden Assertion wurde gemessen:
`busy=true`, `error=null`, `saved=null`, Service `AsyncData`,
`transientCallbackCount=0`, `hasScheduledFrame=true`. Die UI wartete auf einen
nativen Repository-Future; es war nicht der frühere Teardown-Hänger.
Diagnoseprotokoll: `/tmp/2c-close-ui-diagnostic.log`.

Der Widgettest prüft jetzt Dialog und Abbruch mit deterministischem Store und
Service. Echte SQLite-/HTTP-/Packtests bleiben separat bestehen. Unveränderte
Assertion: genau ein Einwilligungsdialog, Abbruch, null Modellanfragen, keine
Karten. Keine zusätzlichen Wartezeiten, Timeoutänderungen oder Skips. Der
vorhandene Pump von 300 ms betrifft ausschließlich die Dialogtransition.

Der Client veröffentlicht Identitäts-/Einwilligungsänderungen. Die bereits
geöffnete Settingskachel bindet bei einem anderen Projektclient neu und lädt bei
Kontowechsel erneut. Epochenschutz verwirft verspätete Reads. Der Versand prüft
weiter Konto, Revision und gespeicherte Zustimmung unmittelbar vor dem Senden.
Ein eigener Widgettest bestätigt sichtbaren Zustand und Versandzustimmung nach
Konto-/Projektwechsel sowie Widerruf. Private Kartenerstellung hat weiterhin
eine eigene Zustimmung, getrennt von automatischer Wortübersetzung.

## Tatsächliche Referenzarchitektur

Quellen: `pipeline/src/sprachpipe/editor/publisher.py`,
`supabase/functions/_shared/content_distribution.ts`,
`content_verification_steps.ts` und Migration `20261017000002`.
Der Publisher lädt unveränderliche Releaseartefakte hoch und veröffentlicht
Katalog, Kanalzeiger und Audit. Er synchronisiert **nicht** die vorausgesetzten
`content.cards/senses/lemmas`. Die bisherige Annahme war falsch.

Neuer Erstellungskontrakt 2:

1. Die App liest das installierte Angebot aus dem Installationsjournal. Version
   und `GenerationIdentity` müssen zum geöffneten Inhaltsrepository passen.
2. Anfrage enthält Release-ID, Manifest-SHA256 und SQLite-SHA256; eine nicht
   veröffentlichte Bootstrapbasis genügt nicht. Gespeicherte Karten bleiben
   unabhängig davon offline nutzbar.
3. `personal_learning_release` prüft mit Serviceberechtigung Nutzer/Sprachfreigabe
   und exakt den unveränderlichen Katalogeintrag. Ein älterer aktiver Release ist
   zulässig. Der aktuelle Kanalzeiger ersetzt niemals dessen Version.
4. Die Function liest dessen `pack.json` aus dem privaten Releasepfad, prüft
   Bytezahl und SHA256 gegen den vertrauenswürdigen Descriptor sowie Sprache,
   Version und Schema. Daraus werden IDs nach dem eingefrorenen Pipelinevertrag
   abgeleitet (NFC, U+001F, SHA256/16 Bytes). Formfunktionen kommen aus aktiven
   Formtargets bzw. expliziter Formidentität; Tombstones bleiben sichtbar.
5. Client-Packreferenzen müssen in dieser Quelle existieren. Das Modell bekommt
   alle passenden Packkandidaten; manipulierte Referenzen werden nicht ignoriert.
   Private Kandidaten sind ausdrücklich private Daten, keine Redaktion.
6. Pro warmem Functionprozess werden höchstens zwei unveränderliche Projektionen
   gehalten. Authentifizierung/Katalogbindung erfolgt pro Anfrage; vollständige
   Byteprüfung und JSON-Projektion nur beim kalten Cacheeintrag. Kein erneuter
   vollständiger Editorialvalidator pro Add. Kaltstartkosten sind nicht gemessen.

SQLtests belegen den älteren Release bei inzwischen geändertem Kanal, falsche
Hashes und Sprach-/Nutzergrenzen. Backendtests belegen manipulierte Kandidaten,
Artefakttampering, deterministische IDs, Formfunktionen und Projektionsreuse.
Das sind synthetische Nachweise, kein Nachweis eines aktuell geladenen Gerätepacks.

### Rein lesende Liveabnahme

In der Prozessumgebung waren `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` und
`SUPABASE_ACCESS_TOKEN` nicht verfügbar. Ein Cloudabgleich wurde nicht ausgeführt.
Vor einer Freigabe das tatsächliche `active.json` und die aktive Generation von
`content.sqlite` vom Gerät **lesend** exportieren. Kein Reset/Bootstrapersatz.
Mit vorhandenen Zugangsdaten ausschließlich in der Prozessumgebung:

macOS (Terminal):

```sh
node --experimental-transform-types tool/audit_personal_release.ts /absoluter/pfad/active.json /absoluter/pfad/content.sqlite
```

Windows (PowerShell):

```powershell
node --experimental-transform-types tool/audit_personal_release.ts C:\Abnahme\active.json C:\Abnahme\content.sqlite
```

Das Werkzeug führt nur GETs auf exakten Katalogeintrag und privates Artefakt aus,
prüft auch den Hash der exportierten SQLite und gibt ausschließlich Release-ID,
Sprache, Hashes und Zähler aus. Keine Schlüssel oder Nutzertexte. Es setzt keine
neue Migration voraus. Den Leseberechtigungsnachweis für das konkrete Appkonto
anschließend separat prüfen; ein Servicekey ersetzt diesen Nachweis nicht.

## Rückstellungen und Bedeutungsgrenzen

Eine pauschale Vorabsperre der Oberfläche wurde entfernt. Bekannte gesperrte
oder zurückgezogene Kandidaten werden als zu unterscheidende Bedeutungen
übermittelt. Für jedes Ziel verlangt der Vertrag `independent`, `same` oder
`unclear` samt konkreter Begründung. `same`, fehlende oder unklare Abgrenzung
speichern nichts. Bekannte identische Sense-IDs überstimmen eine anderslautende
Modellbehauptung. Eine passende bestehende Karte wird weiter wiederverwendet.

Eine neue Karte trägt die geprüfte Liste unabhängiger Ziele und deren Herkunft.
Die Transaktion überprüft aktuelle gesperrte Zeilen erneut: Eine erst inzwischen
hinzugekommene Sperre ohne Beleg blockiert. Alte Flags, Reviews, Kontexte und
Quellbindungen werden nicht umgeschrieben. Tests: gleiche Oberfläche, gesperrte
Bedeutung, unabhängige Bedeutung und nachträgliche zusätzliche Sperre.

Die semantische Abgrenzung neuer Bedeutungen bleibt eine Modellentscheidung,
kein Beweis perfekter Sprachqualität. Strukturelle Tests ersetzen keine
fachliche Liveabnahme. Nicht auflösbare Referenzen bleiben Fehler.

## Private Übersetzungsteile

`personalTranslationHints` liest nur `cached`, niemals `translate`. Exakter
Requestkey umfasst Sprache, Originaltext, UTF-16-Wortstelle und Vertragsversion;
Kontoskopierung und Revisionsschutz liegen im bestehenden Cacheclient. Der Adapter
validiert zusätzlich Responsevertrag, Provider, Modell, Zeitgrenze und Wortform.
Technische Speicherfehler werden weitergegeben, nicht als fachlicher Miss getarnt.

Übermittelt werden Requestkey/-ID, Vertrag, Promptversion, Datum und passende
Wortbestandteile bzw. Satzübersetzung. Im Modellprompt sind sie ausdrücklich
Daten, keine Anweisungen oder redaktionelle Freigabe. `cache_use` dokumentiert,
welche Teile tatsächlich übernommen wurden: Bei Wortübernahme müssen Lemma, POS,
Gloss und Formbeschreibung exakt übereinstimmen; bei Satzübernahme müssen Original
und deutsche Übersetzung exakt übereinstimmen. Widersprüche werden abgewiesen.
Ungeeignete Teile werden begründet nicht übernommen (`cache_note`). Fehlende
Annotationen können in demselben begrenzten Aufruf ergänzt werden. Herkunft bleibt
in der privaten Karte gespeichert. Keine gemessene Tokenersparnis behauptet.

Tests benutzen echte lokale Cache-SQLite: Konto-/Textwechsel, genaue Provenienz,
technischer Speicherfehler; Backendtests ergänzen Vertrags-/Zeit-/Keyprüfung und
widersprüchliche Übernahme. Bestehende Cachetests decken Ablauf, Löschen,
Deduplizierung und Nutzerwechsel weiter ab.

## Original und Ersatz

Geeignete längere Originale bleiben bytegenau erhalten; Pronomen oder fehlende
Annotation allein rechtfertigen keinen Ersatz. Neue Karten aus 1–2 Wörtern
benötigen Ersatz; passende Bestandskarten bleiben auch dabei verknüpfbar.

Nur neue Ersatzsätze werden zusätzlich technisch segmentiert. Gemeinsame
Dart-/TypeScriptfälle prüfen en/pt-BR-Titel, Initialen, Abkürzungen, Dezimalpunkte,
Schlusszeichen und Anführungen; mehrere interne Satzenden und unklare Ellipsen
werden abgewiesen. Abschlusszeichen ist erforderlich. Grenzen: endliche
Abkürzungsliste, mehrdeutige Initialen und ungewöhnliche Zeichensetzung sind keine
vollständig linguistisch lösbare Klassifikation. Keine globale Änderung der
redaktionellen Minidialogvalidatoren. Ungültige Ergebnisse speichern nichts;
kein automatischer kostenpflichtiger Reparaturaufruf.

## Lokale Abschlussprüfung

Alle Modelltests benutzen lokale Fetch-/HTTP-Stubs. Ausgangsstand c90680b hatte
595 PASS, sechs bestehende Skips und den einen neuen UI-FAIL; diese Zahlen sind
historisch, keine aktuelle Abnahme.

| Prüfung | Aktueller Nachweis |
|---|---|
| Flutter vollständig | 600 PASS, sechs bestehende Skips; `/tmp/2c-full-final-close.log` |
| Gezielte UI/Domain/Provider/Satzfälle | 13 PASS vor zusätzlicher Identitätsschutzprüfung; finale Gesamtsuite enthält alle |
| Cacheadapter / unabhängige Bedeutung | je 1 PASS, finale Gesamtsuite enthält beide |
| Backend Runtime/Cache/Erstellung/Release/Satz | 43 PASS; `/tmp/2c-backend-close.log` |
| SQL/PGlite | alle drei Prüfdateien PASS; `/tmp/2c-sql-close.log` |
| Function-Typecheck | Exit 0; `/tmp/2c-typecheck-close.log` (gezielte Backend-ID-Regression danach 9 PASS) |
| Original-Pack | 1 PASS, 11 s, unverändertes 30-s-Budget; `/tmp/2c-realpack-close.log` |
| Stage | 22 Tabellen stimmen, 26.198.016 Bytes; `/tmp/2c-stage-close.log` |
| Analyse | nur bestehendes `avoid_print` in `baseline_adoption_pack_test.dart:43`; `/tmp/2c-analyze-final-close.log` |

Original-Pack unverändert:
`b85793932825a22e92ac744a42255e9f333acd35809aaba46edb5a395f099bdb`.
Produktiver contentIds-Guard, STORY_STATUS_01-Altstand, echte Provider-/Repository-
Integration, paralleles Add, atomarer Rollback, Offline-Neustart, Quellenlöschung,
Reviews und Sprachtrennung bleiben abgedeckt. Keine vorhandenen Validatoren
abgeschwächt. GitNexus-Warnung CRITICAL beim Backendvalidator wurde nicht als
Freigabe gewertet; direkte Aufrufer plus vollständige Regressionen geprüft.

## Noch ausstehend und genaue spätere Reihenfolge

1. Rein lesenden Geräte-/Katalog-/Artefaktabgleich oben ausführen. Ein gültiger
   veröffentlichter Schema-5-Pack und passende `content_readers`-Freigabe sind
   zwingende Voraussetzungen. Kein Vollimport in alte Contenttabellen.
2. Nur nach gesonderter Deploymentfreigabe Migration
   `20261024000002_personal_learning.sql` anwenden. Voraussetzungen: bestehende
   Distribution-, Runtime-Limits- und private Cachemigration. Keine zusätzliche
   Migration dieser bestehenden Strukturen in diesem Paket.
3. Danach `create-learning-card` mit JWT-Prüfung deployen. Bestehende Server-Secrets
   und Modellfreigabe beibehalten. Keine Änderungen an Übersetzungsfunctions nötig.
4. Erst anschließend passenden Appbuild mit Vertrag 2 als Update installieren,
   vorhandene dart-defines erhalten. Keine Deinstallation oder Datenlöschung.
5. Synthetische Liveabnahme mit ausdrücklicher Zustimmung zu Modellkosten:
   `She went to the bank.` / `She sat by the bank.` (Rückstellung und unabhängige
   Bedeutung), `She holds it near her lantern.` (Original/Pronomen), `coração`
   (kurzer pt-BR-Ersatz), wiederholtes Wort mit exakter Auswahlstelle; einmal
   vorhandene Packkarte, einmal neue private Karte. Anschließend Quelle/Cache
   löschen und gespeicherte Karte offline öffnen. Keine automatisierten Reviews.
6. Konto-/Projektwechsel in offener Einstellung, acht schnelle Adds, einmal
   Limit/Offline/Anbieterfehler synthetisch prüfen. Nie kostenpflichtig automatisch
   wiederholen. Alte aktive Generation nach Kanalfortschritt getrennt abnehmen.

Kein Geräte-PASS und keine Livequalität behauptet. Kein Push.

## Technische Vorabnahme 25.10.2026 — unveränderter Stand 90673bb

**Entscheidung:** Lokaler vollständiger Handler besteht die unten beschriebenen
Ressourcenfälle. Keine belegte CPU-/Memory-Hardlimitverletzung, daher keine
Produktionskorrektur. Keine Cloudfreigabe: Die aktive App-Sitzungsidentität ist
noch nicht unabhängig bestätigt, SQL/RLS und Gateway waren im Lasttest simuliert.
Der Prozesscache ist keine verlässliche Zusage warmer englischer Folgeaufrufe.

### Tatsächlicher Gerätebestand

`iPhone von Claus`, UDID `00008110-001651611E01401E`: ausschließlich lesender
Appcontainerexport von `Library/Application Support/content/{lang}/active.json`
und der darin ausgewählten `generations/{release_id}/content.sqlite`.
Kein Bootstrap als Ersatz, keine Installation, kein Reset, keine Reviews,
kein Export von user.db oder Authsitzung. Geschützte Kopien außerhalb des Repos:
`/private/tmp/sprachapp-2c-preflight-20261025` (Verzeichnis 0700, Dateien 0600).

| Sprache | Aktiver Release | SQLite-Bytes | Referenzkarten / retired | Publizierte pack.json-Bytes |
|---|---|---:|---:|---:|
| en | 510c6685-f0ea-4002-9c7c-a09f0bf8212b | 43.089.920 | 3.768 / 1 | 50.282.981 |
| pt-BR | 4213d487-044d-45b9-ae95-e14a7c3c0d35 | 311.296 | 20 / 0 | 124.750 |

`tool/audit_personal_release.ts` lief erfolgreich gegen **beide exakten Exporte**
und den veröffentlichten Katalog. Manifest-, SQLite- und veröffentlichte
Packobjekt-Hashes stimmen; vollständige Hashwerte im verlinkten Nachweis.
Die englische aktive SQLite ist ausdrücklich nicht der bisher getestete
26.198.016-Byte-Originalpack. Zugang über vorhandene Supabase-CLI-Anmeldung im
macOS-Schlüsselbund; Management-/Servicezugang nur im Prozessspeicher bzw.
Kindprozess-Environment. Keine Schlüssel gespeichert, ausgegeben oder committed.

Zusätzliche Kontoprüfung: Das vom Nutzer vermutete Konto existiert, ist nicht
anonym und hat `content_readers` für **en und pt-BR**. Das ist mehr als ein
Service-Role-Downloadnachweis, aber **kein Beleg der aktiven iPhone-Sitzung**:
Die Kontoadresse ist in der App nicht sichtbar, der Nutzer nennt sie mit
Unsicherheit, die Sitzung liegt im iOS-Schlüsselbund. Fehlende Voraussetzung ist
nur die sichere Zuordnung der bestehenden App-Sitzung zu diesem Konto, etwa durch
eine spätere authentifizierte Diagnose der eigenen Readerfreigaben. Kein neuer
Schlüssel erforderlich, keine Authänderung im Rahmen dieser Vorabnahme.

### Vollhandler unter Edge-Limits

Reproduzierbare Sonde: `tool/check_personal_edge_resources.py` und
`tool/personal_edge_probe/`. Fünf Produktionsmodule werden per `git show 90673bb`
unverändert kopiert; ihre SHA256 stehen im Nachweis. Tatsächliche Packbytes werden
vorher gegen die Kataloghashes geprüft. Keine Geräte-SQLite oder Zugangsdaten im
Container. Synthetische Wortstelle `zorb`, unterschiedliche Requesttexte;
keine privaten Storytexte, keine bezahlten Modellaufrufe.

Offizielles ARM64-Image `public.ecr.aws/supabase/edge-runtime:v1.77.1`,
Deno-kompatibel 2.1.4, Image-ID
`sha256:645d0e45446181f3e9d87efeef637b494615f32365befff00e2d2b0fe8535fef`.
Dedizierte lokale Colima-VM, 2 CPU / 4 GiB, normaler `per_worker`-Pool.
Erzwungen pro Userworker: **256 MB, 2.000 ms CPU hart, 150.000 ms Wall**;
zusätzlich 1.000 ms CPU weich als lokale Retirement-Einstellung, nicht als
behauptetes Plattform-Hardlimit. Die aktuellen [Supabase-Limits](https://supabase.com/docs/guides/functions/limits)
nennen 256 MB, 2 s CPU pro Request, 150 s Free bzw. 400 s Paid Wall.
Der lokale per-worker-Zähler ist kumulativ und damit für mehrere Anfragen strenger;
er ist kein isolierter CPU-Zähler pro HTTP-Anfrage. Keine internen Reserveziele
als Plattformlimits verwendet.

Simuliert: GoTrue-Antwort, PostgREST Release-/Claim-/Finish-RPC (keine SQL/RLS,
keine echte Quotenbuchung), Storage-Transport mit exakten veröffentlichten Bytes,
Anthropic-Antwort. Der Handler führt seine unveränderten Prüfungen aus;
JWT-Gatewayprüfung und Dienstimplementierungen sind damit nicht live abgenommen.
Alle ausgehenden Fetches werden auf lokale Fixtures umgebogen, fremde Ziele
abgewiesen. Der Modellstub ist ausdrücklich kein Sprachqualitätsnachweis.

| Fall | HTTP | End-to-End ms | CPU ms je beendetem Worker | Downloads en / pt | Prozess-RSS-Spitze MiB |
|---|---|---|---|---|---:|
| Kalt en | 200 | 957,7 | 314 | 1 / 0 | 292,1 |
| en, Folgeaufruf | 2 × 200 | 803,6 / 322,9 | 298 / 278 | 2 / 0 | 301,1 |
| en → pt-BR → en | 3 × 200 | 686,5 / 27,7 / 296,9 | 295 / 278 | 2 / 1 | 302,1 |
| 8 parallel en, leerer Pool | 8 × 200 | 1.130,1–1.475,2 | 317 / 279 / 345 | 3 / 0 | 484,0 |
| 8 parallel en/pt-BR, leerer Pool | 8 × 200 | 885,0–1.639,0 | 300 / 297 / 295 / 287 / 12 | 4 / 3 | 493,2 |

**Messgrenzen:** CPU stammt aus Runtime-Shutdown-Ereignissen, nicht Wallzeit.
`VmHWM` ist die Kernel-RSS-Spitze des gesamten Runtimeprozesses einschließlich
Main-/Eventworker und mehrerer Userisolate; sie darf nicht gegen das
256-MB-Userworkerlimit gerechnet werden. Cgroup-Highwater separat im JSON.
Instrumentiertes `heapUsed + external` beobachtet beim englischen Kaltlauf
166.340.538 Bytes; Shutdown meldet 166.384.212 Bytes und `exceeded:false`.
Weder Shutdownspeicher noch das 2-ms-Sampling sind eine garantierte
Isolat-Speicherspitze: synchrone Zwischenstände können fehlen. Die Runtime
überwachte das konfigurierte Limit tatsächlich; kein `Memory`, `CPUTime` oder
`WORKER_RESOURCE_LIMIT` in diesen Läufen. Einzelmessungen, keine Lastkapazitäts-
oder Cloudhardwaregarantie.

**Warm-/Parallelbefund:** Der sequenzielle englische Folgeaufruf war erneut kalt:
`EarlyDrop`, neuer Worker, zweiter Download/Parse. Im parallelen englischen Lauf
wurden dagegen fünf Anfragen aus einem erhaltenen Cache bedient (kein weiterer
Parse, 1,12–3,17 ms Handlerzeit). Bei 8 Anfragen entstanden drei englische
Projektionen in drei Workern. Die Deduplizierung ist also workerlokal, nicht
pool-/prozessübergreifend; mehrere große JSON-Strukturen existieren gleichzeitig.
Bei zwei Sprachen entstanden vier EN- und drei PT-Downloads in fünf Workern.
Eine PT-Projektion und anschließend EN wurden im selben Worker aufgebaut.

Der [Quellcode dieser Runtimeversion](https://github.com/supabase/edge-runtime/blob/v1.77.1/crates/base/src/worker/supervisor/strategy_per_worker.rs)
führt u. a. das Erreichen der halben Speichergrenze als EarlyDrop-Bedingung nach
abgeschlossenen Aufgaben. Das passt zum gemessenen EN-Speicher; der genaue
interne Trigger ist im Shutdownereignis nicht separat ausgewiesen. EarlyDrop
ist hier **kein fehlgeschlagener Request**. Ein erster verworfener Messaufbau
hielt den inzwischen beendeten Workerhandle fest und produzierte deshalb 546
beim Folgeaufruf. Die Tabelle enthält ausschließlich den korrigierten normalen
Pool, nicht diese Harnessfehler.

Historischer Vergleich: `docs/content-editor-initial-release.md` dokumentiert
Cloud v1.77.0 mit 546/CPUTime 2.441 ms, 4.572 ms Wall und 79.508.379 Bytes
**Shutdownspeicher**, nicht Peak. Der damalige lokale PASS widerlegte den
Cloudfehler nicht. Auch die jetzigen lokalen 278–345 ms für EN-Worker sind kein
Cloud-PASS; tatsächlich eingesetzte Cloudruntime/Hardware noch nicht verifiziert.

### Konsequenz und verbleibende Abnahme

Kein nachgewiesener Hardlimitengpass verlangt eine Sofortkorrektur. Die begrenzte
Architekturoption, falls Cloudmessungen Kaltkosten problematisch machen: eine
redaktionell erzeugte, unveränderliche lernrelevante Projektion pro Release mit
eigenem Kataloghash veröffentlichen; serverseitig weiterhin Release-, Hash- und
sämtliche Referenzprüfungen. Ziel wäre, das vollständige 50,3-MB-JSON samt Parsing
zu vermeiden. Das erfordert einen versionierten Publikationsvertrag und einen
separaten Auftrag, keine spontane Cache-/Validator-Abschwächung. Keine solche
Änderung implementiert und keine ungemessene Einsparung versprochen.

Vor Deployment fehlen die eindeutige aktive Kontozuordnung; danach gesonderte
Freigabe für Migration/Deployment. Anschließend echte JWT/RLS-/Quoten-/Storage-
Integration, Cloudkaltstart und synthetische Livequalität nach Kostenfreigabe
prüfen. Keine exakten Deploymentbefehle vor Klärung dieser Voraussetzungen.
Die oben dokumentierten früheren Tests bleiben historische Nachweise; keine
neue Flutter-/Geräte-Funktionsabnahme aus diesem reinen Serverprobe-Lauf.

Nachweise: [sanitisierte Messdaten](evidence/package-2c-preflight-20261025.json),
Python-Syntaxprüfung Exit 0, vollständige Edge-Ausführung **22/22 HTTP 200**.
Private Rohdaten/Logs bleiben außerhalb des Repos; keine Produktdatei verändert.

Abschluss: `git diff --cached --check` Exit 0; GitNexus nach erfolgreicher
Neuindizierung `detect_changes(all)` und `detect_changes(staged)` ohne
partial/truncated, eigener Stage 7 Dateien / 48 Symbole / 0 erkannte Prozesse,
Risiko low. Das ersetzt nicht die Prüfung dynamischer Fixture-Callbacks; diese
wurden durch die vollständigen Edge-Läufe ausgeführt. Fremde Onboardingänderungen
bleiben außerhalb des Commits. Dedizierte Colima-VM nach Messung gestoppt;
lokal installierte Docker-/Colima-Werkzeuge bleiben verfügbar.

Reproduktion auf macOS (Terminal, vorhandene private Fixtures und gestarteter
Docker-Kontext vorausgesetzt):

```sh
python3 tool/check_personal_edge_resources.py --private-input /private/tmp/sprachapp-2c-preflight-20261025 --output /private/tmp/sprachapp-2c-preflight-20261025/repeat --context colima-sprachapp-2c --ref 90673bb
```

Windows (PowerShell): Diese Hostsonde wurde dort nicht validiert. Sie verwendet
bewusst den macOS-Mountpfad `~/Library/Caches` und den lokalen Colima-Kontext;
keine unveränderte Windows-Ausführbarkeit behauptet. Edge-Fixtures sind unabhängig
vom Host, ein Windows-Runner benötigt einen explizit freigegebenen privaten
Mountpfad und seinen eigenen Docker-Kontext. Kein Cloud-Deploymentbefehl.
