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
