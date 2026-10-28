# Übergabe: Story-Import → persönliche Lernkarte

Aktualisiert: 25.10.2026, Repository-HEAD `0982982`, Branch `main`.

## Aktueller Abschluss: Ursache korrigiert, Geräteweg bestätigt

**Der unten dokumentierte HTTP-400-Blocker ist behoben.** Die Abschnitte 1–13 bleiben als historischer Übergabestand bei `bfd5edb` erhalten. Ihre Aussagen „Ursache unbekannt“, „Geräte-Add offen“, Function v6 und ihr abschließender Startauftrag sind durch diesen Abschluss überholt und keine aktuellen Arbeitsanweisungen.

Nachweise: lokaler Korrekturcommit `0bfa641`, Abnahmecommit `0982982`, aktualisierte `docs/story-creation-contract-audit.md` und Nutzerbericht. Bei dieser Aktualisierung wurden Commits und Dokumentation geprüft; keine eigene erneute Cloud-/Geräteprüfung und kein weiterer Modellaufruf durchgeführt.

### Belegte Ursache und Korrektur

Anthropic lehnte die Kombination `type: ["string", "null"]` mit `null` innerhalb von `enum` ab: `Enum value None does not match declared type '['string', 'null']'`. Diese Schemaform war mit dem Vertragsabgleich in `e7b46e8` eingeführt worden. Die frühere Einschätzung, die einzelnen unterstützten Schemaelemente würden auch diese Kombination absichern, war falsch. Die damaligen lokalen Tests erkannten die Anbieterinkompatibilität nicht.

Laut dokumentierter, ausdrücklich freigegebener synthetischer Probe grenzten sechs Tokenzählanfragen ohne Generierung den Fehler ein: altes Schema angenommen, neues Schema abgelehnt, Systempromptwechsel ohne Einfluss, korrigierte `anyOf`-Form angenommen. Damit wurde die Ursache unabhängig von einer neuen generierten Antwort nachgewiesen.

`0bfa641` verwendet für `function` und `reuse_id` getrennte String-Enum-/Null-Zweige mittels `anyOf`. Ohne anbietbare Kandidaten ist `reuse_id` ausschließlich `{type: "null"}`. Zulässige Werte und fachlicher Validator bleiben unverändert; kein Eingriff in Prompt, Retry, SQL oder Client.

### Auslieferung, Prüfungen und Abnahme

- Dokumentierte Prüfungen: Backend 45 PASS, vier SQL-Suiten plus Produktionshandler-Retryprobe PASS, Flutter 32 PASS inklusive Original-Pack. Die neue Regression scheiterte vor der Korrektur.
- Ausschließlich `create-learning-card` als v7 ausgeliefert, `verify_jwt=true`; sechs ausgelieferte Quelldateien laut Abnahme bytegleich mit `0bfa641`. Keine Migration, Secretänderung oder Clientinstallation für diesen Fix.
- Dokumentierter Geräte-Trace: zuerst Ergebnis-/Ticketprüfung mit 409 ohne Modell; anschließend ausdrücklicher Retry am 25.10.2026 um 10:49:38 UTC, Diagnose-ID `3e6a9ca0-fb0a-4b9d-bb1d-0f5402545caf`. Genau ein Modellaufruf, Anbieter 200 nach 3731 ms, Validierung erfolgreich, Speicherung 85 ms, Gesamt 4817 ms.
- Gemeldete Nutzerbeobachtung auf dem iPhone: „Hinzugefügt“, Karte unter „Aus Storys“, genau ein Übungskontext, keine Antwort abgegeben, nach Neustart vorhanden. **Erfolgskriterien 1–5 sind damit durch die dokumentierte Nutzerabnahme bestätigt.**

Zwei begrenzte Prüflücken bleiben: Kriterium 6 (Erhalt des gesamten vorhandenen Bestands, gemeinsamer Lernstände, Historie und Sprachtrennung) wurde nicht separat am Gerät geprüft; zugehörige Regressionen bestehen und der Client blieb unverändert. Der `reuse_id`-Zweig mit vorhandenen Kandidaten ist lokal getestet, aber noch nicht beim Anbieter durchlaufen. Diese Prüflücken sind keine beobachteten neuen Fehler und rechtfertigen keine automatische zusätzliche Modellanfrage.

Kein Push; fremde Onboarding-Arbeit erhalten. Weitere echte Modellaufrufe sind durch diese Dokumentationsaktualisierung nicht freigegeben.

---

## Historischer Übergabebericht bei bfd5edb

Dieser Bericht übergibt die Fehlersuche an ein anderes KI-Modell mit Zugriff auf den Projektordner. Er trennt belegte Befunde, historische Fehler, Korrekturen und offene Nachweise. Er ist keine neue Freigabe für Modellaufrufe, Datenänderungen oder Deployments. Für diese Übergabe wurden Gitstand und bestehende Nachweise gelesen; Tests und Cloudabfragen wurden nicht erneut ausgeführt.

## 1. Das Problem jetzt

**Die reale Erstellung einer persönlichen Lernkarte aus einem importierten Text funktioniert auf dem iPhone weiterhin nicht.** Die Übersetzung des angeklickten Wortes funktioniert. Daraus folgt aber weder eine erstellte Lernkarte noch ein erfolgreich gespeicherter Erstellungsauftrag.

Letzte Nutzerbeobachtung:

- Englischer importierter Text auf dem Screenshot: „The hamster sleeps in the cage“.
- Zielwort: `hamster`; normale deutsche Leseübersetzung: „Hamster“.
- Nach ausdrücklichem „Erneut versuchen“: **„Lernkarte derzeit nicht verfügbar. Kein Hinzufügen bestätigt. (MODEL_FAILED)“**.
- Die Karte ist nicht als erfolgreich hinzugefügt bestätigt. Erfolgreiche Anzeige unter „Aus Storys“ und Persistenz auf diesem Gerät sind noch nicht nachgewiesen.

Der sichere Servertrace belegt für diesen Versuch:

1. Authentifizierung, Releaseprüfung, Packprüfung, Referenzprüfung und Versuchszuteilung wurden durchlaufen.
2. Die Anfrage an den Modellanbieter wurde gestellt.
3. Der Anbieter antwortete mit **HTTP 400 nach 426 ms**.
4. Die Function antwortete mit **HTTP 502 / MODEL_FAILED**, Gesamtdauer **1707 ms**.
5. `model_envelope`, Antwortvalidierung und Ergebnisspeicherung wurden nicht erreicht.

**Die konkrete Begründung für HTTP 400 ist unbekannt.** Der damalige Code las/sicherte den Anbieterfehlerbody nicht. Die vorhandenen Logs erlauben keine nachträgliche Entscheidung zwischen Anfrage-/Schemafehler, Kontoproblem oder einer anderen Anbieterablehnung. Insbesondere sind Guthabenprobleme, ein bestimmtes Schemafeld oder der frühere `ANSWER_LEAK` keine belegte Ursache dieses letzten Fehlers.

Die letzte Änderung `bfd5edb` verbessert ausschließlich die Diagnose solcher Anbieterablehnungen. Sie ist **keine belegte Korrektur der HTTP-400-Ursache**.

## 2. Ziel und verbindliche Erfolgskriterien

Ein Nutzer importiert einen geeigneten Text, tippt ein Wort an und fügt es ausdrücklich zum Lernen hinzu. Vorhandene passende Karten/Ergebnisse werden wiederverwendet. Fehlt eine passende Karte, erstellt der authentifizierte Server nach den vorhandenen Zustimmungs- und Kostenregeln eine gültige persönliche Lernkarte.

Erfolg ist erst erreicht, wenn auf dem tatsächlichen iPhone:

1. die Erstellung beziehungsweise Wiederaufnahme erfolgreich abgeschlossen ist;
2. die Karte tatsächlich gespeichert ist und unter **„Aus Storys“** erscheint;
3. ihre Übung mit **genau einem passenden Kontext** geöffnet werden kann;
4. keine Übungsantwort automatisch abgegeben wurde;
5. die Karte nach App-Neustart erhalten bleibt;
6. bestehende Karten, gemeinsame Lernstände, Historie und Sprachtrennung unverändert erhalten bleiben.

Ein erfolgreicher Build, eine Installation, eine Wortübersetzung oder eine positive Mockantwort genügt dafür nicht. Fehler dürfen keinen Hinzufügen-Erfolg anzeigen.

## 3. Umgebung und letzter Auslieferungsstand

| Gegenstand | Stand |
|---|---|
| Hauptprojekt | `/Users/ardasayar/Documents/FlutterProjekte/sprachapp` |
| Git | `main`, HEAD `bfd5edb`, kein Push der hier beschriebenen eigenen Änderungen |
| Gerät | „iPhone von Claus“, `00008110-001651611E01401E` |
| Bundle | `com.example.sprachapp` |
| Supabase | `yevntxclpchapacqdizm` |
| Function | `create-learning-card`, zuletzt Version 6 ACTIVE, `verify_jwt=true` bestätigt |
| Modell | `claude-haiku-5-5`, direkt Anthropic ausschließlich über authentifizierte Edge Function |
| iPhone-App | Zuletzt Profile-Update mit Retry-Client aus dem Arbeitsstand um `3696a3e`, bestehende Supabase-Dart-Defines beibehalten |
| Letzte Änderung | `bfd5edb` nur serverseitige Fehlerklassifikation; dafür kein neues Clientupdate nötig |
| Cloudmigrationen | `20261025000001_personal_learning_retry.sql` und `20261025000002_personal_learning_retry_retention.sql` nach separaten Diff-/Dry-run-Prüfungen angewendet |

Die Profile-Builds entstanden im Hauptarbeitsverzeichnis und enthalten auch dort vorhandene fremde UI-Arbeit. Die isolierten eigenen Commits enthalten diese fremden Änderungen nicht. Die wiederverwendete Appversionsnummer `1.0.0+1` ist kein eindeutiger Commitnachweis.

Auf diesem Mac für Supabase **`npx supabase`** verwenden. Keine anderen Functions, Secrets oder unbeteiligten Migrationen mit ausliefern. Vor einer erneuten Auslieferung aktuellen Remotezustand lesen; obige Angaben sind der zuletzt dokumentierte Stand.

## 4. Freigaben und Grenzen

**Es ist aktuell kein weiterer echter Modellaufruf freigegeben.** Der zuletzt genehmigte einzelne potenziell kostenpflichtige Geräteversuch wurde mit dem HTTP-400-Versuch verbraucht. Ob der Anbieter diesen Fehlversuch tatsächlich berechnet, ist nicht belegt und erneuert die Freigabe nicht.

- Der Nutzer führt Add-/Wiederholen-Klicks selbst aus. Nicht zur Vorbereitung klicken oder automatisiert anfragen.
- Keine automatische kostenpflichtige Wiederholung, keine Schleife zur „Reparatur“ einer Modellantwort.
- Keine Auftragssperren löschen, keine Schlüssel verändern, keinen Text zum Umgehen einer Sperre abwandeln, keine Sonderbehandlung für Konto oder `hamster`.
- Keine Deinstallation, kein Reset und keine Änderung echter Lernstände oder Reviews.
- Normale Übersetzungscaches nicht überschreiben oder in Übungshinweise umwandeln.
- Authentifizierung, Zustimmung, Kostenlimits, Release-/Hashbindung, Rückstellungsschutz und Validatoren erhalten.
- Bestehenden Supabase-Anthropic-Secret unverändert lassen. Keine Schlüssel im Chat, Repository, App oder Log.
- Keine ungeprüften Importe, CMS-/Scheduleränderungen oder neue Architektur als Ausweichlösung.
- Kein Push. Eigene künftige Codeänderungen isoliert committen, fremde Änderungen erhalten.

Frühere Freigaben erlaubten die eng begrenzte Korrektur, Retry-Migration, Function-Auslieferung und iPhone-Updates. Sie erlauben nicht beliebig viele Liveexperimente. Die aktuelle Nutzeranfrage verlangt diesen Bericht, keinen weiteren Geräteversuch.

## 5. Fehlerchronologie: Was tatsächlich jeweils kaputt war

### A. STORY_STATUS_01 bei vorhandenen Stories — behoben, vom Nutzer bestätigt

In „The Open Pocket“ scheiterten `arrives` und `points` mit „Lernstatus laden nicht möglich … (STORY_STATUS_01)“. `station` konnte verknüpft werden; `early` war „Bereits hinzugefügt“.

Belegte Ursache: Ein deterministischer ID-Kandidat für eine noch nicht angelegte lokale Karte wurde an den Packkarten-Guard übergeben. `DriftUserRepository._guardCards` warf `StateError`, über `cardStates` im Statuspfad. Die Kombination aus produktivem `contentIds`-Callback, tatsächlichem Gerätepack und vorhandenem Nutzerbestand war entscheidend. Einfachere Tests ohne diesen Callback hatten den Fehler nicht gezeigt.

Korrektur `1c31881`: Bei erst prospektiven lokalen IDs die Existenz berücksichtigen. Gespeicherte Bindungen und Packreferenzen weiterhin streng prüfen. Keine allgemeine Aufweichung des Guards.

Nachweis: 66 gezielte Tests bestanden, ein Skip; Gerätebestand lesend verglichen. Nutzer bestätigte ausdrücklich: **„Alle vier verhalten sich korrekt.“** Diese Gerätebestätigung gilt nur für diesen Statusfehler.

Details: `docs/story-status-device-fix.md`.

### B. Importierter Bindestrichtext — Statusfehler vor Erstellung, behoben

Reproduktion: **„I am the return-hamster“**. Der Reader selektierte `hamster` ab UTF-16-Position 16; der Lernvertrag behandelte `return-hamster` als ganzes Wort ab Position 9. `PersonalTarget.validate` warf eine `FormatException`, bevor eine Modellanfrage möglich war. UI: **„Lernstatus nicht lesbar. Bitte erneut öffnen.“**

Korrektur `c8c031a`: Readerauswahl auf die gemeinsamen Wortgrenzen von `personalWords` ausrichten. Bindestrichkomposita werden vollständig gewählt; gewöhnliches `hamster` bleibt unverändert. Gegenproben mit normalem Satz und astralen Zeichen zeigten: Dies war ein Wortgrenzenwiderspruch, nicht pauschal ein UTF-16-Zählfehler. Ein Original ohne Schlussinterpunktion ist nicht automatisch ungültig.

Dieser Fehler war vom früheren prospektiven Karten-ID-Fehler verschieden. Die spätere Auswahl `return-hamster` auf dem Screenshot ist durch den gemeinsamen Tokenvertrag erklärbar.

Details: `docs/story-import-status-hyphen-fix.md`.

### C. Erster Erstellungsauftrag endet mit 502, danach unklarer Auftrag

Der reale `return-hamster`-Versuch endete am 25.10. um **06:27:55.982 UTC** mit HTTP 502. Seine Lease lief erst um **06:28:36.361 UTC** aus. Der erste Fehler lag damit vor Leaseablauf. Ein späterer Abruf lieferte 409/pending beziehungsweise unklaren Ausgang.

UI: **„Erstellung läuft bereits oder ihr Ausgang ist unklar. Keine automatische Wiederholung.“**

Der Worker verbrauchte laut damaligem Nachweis 758 ms CPU. `EarlyDrop` war dort kein Beleg für einen CPU-/Speicherabbruch. Frühere `WORKER_RESOURCE_LIMIT`-/`CPUTime`-Probleme bei Inhaltsveröffentlichungen dürfen nicht ungeprüft auf diesen Versuch übertragen werden.

Die ursprünglichen Logs enthielten nicht die nötige Stufentrennung. Deshalb blieb die genaue damalige Ursache unbekannt. **„Auftrag abgelaufen“ beschreibt nur den späteren Zustand, nicht die Ursache der ersten 502-Antwort.**

`f8cc147` ergänzte sichere Stufen-, Dauer- und Fehlerdiagnosen. Dies war Diagnosearbeit, keine Ursachenbehebung dieses verlorenen Versuchs.

### D. Modell antwortet, eigene Validierung lehnt ab: MODEL_INVALID

Geräteversuch am 25.10. **09:13:50.854–09:13:54.438 UTC**:

- Diagnose-ID `c7ad81db-8577-41a2-a3da-a1764fe72226`.
- Auth 76 ms, Release 91 ms, Pack 998 ms, Referenzen 2 ms, Claim 69 ms, Modell 2341 ms.
- Anbieterantwort, Envelope und JSON-Verarbeitung erfolgreich.
- Danach `validation / MODEL_INVALID`, Gesamt 3584 ms; keine Speicherung.

Die konkrete Prüfregel wurde damals noch nicht geloggt; die Antwort wurde aus Datenschutzgründen nicht dauerhaft gespeichert. Deshalb ist dieser historische Fehler nicht exakt rekonstruierbar.

`bb7d3c6` ergänzte genaue sichere Prüfcodes `RULE_1` bis `RULE_21` und Textfeldcodes `RULE_100` bis `RULE_109`. Die spätere lokale `RULE_21` ist **kein rückwirkender Beweis** für die Ursache dieses Geräteversuchs.

### E. Kontrollierter synthetischer Einzelaufruf: ANSWER_LEAK / RULE_21

Ein ausdrücklich genehmigter lokaler Einzelversuch mit **„The hamster sleeps in its cage.“**, Ziel `hamster`, UTF-16-Bereich `[4, 11)`, lieferte:

```json
{"mode":"live","status":502,"error":"ANSWER_LEAK","rule":"RULE_21","modelRequests":1,"stored":false}
```

Dafür wurden der tatsächliche englische Pack und derselbe Modellauftrag/Validator verwendet; Authentifizierung und Speicherumgebung waren lokal simuliert. Die Antwort ausschließlich dieses vereinbarten synthetischen Textes wurde geschützt außerhalb des Repositorys erfasst und lokal ohne weitere Modellkosten reproduziert.

Belegte Ursache: Der Modellvertrag bezeichnete `translation_de` nicht hinreichend klar als vor der Lösung sichtbaren, lösungsfreien Satzhinweis. Die Antwort enthielt dort „Hamster“. Der Validator untersagte die Lösung in diesem Übungshinweis zu Recht. Nur `gloss_de` war zuvor ausreichend deutlich als lösungsfrei beschrieben.

`d8a60b0` präzisierte Modellauftrag und Schema für beide Übungsfelder. Keine Validatorlockerung und keine nachträgliche semantische Umschreibung einer ungültigen Antwort.

**Wichtige Trennung:** Die normale Leseübersetzung darf selbstverständlich „Hamster“ enthalten. Nur der vor der Lösung sichtbare Übungshinweis muss die Antwort vermeiden. Eine bedeutungstreue Umschreibung gehört in den separaten Übungshinweis, nicht in den vorhandenen Leseübersetzungscache.

Die ursprünglich aufgezeichnete negative Antwort bleibt auch nach der Korrektur ungültig. Eine lokal positiv veränderte Fixture ist kein zweiter Modellnachweis.

### F. Weitere Vertragslücken lokal abgeglichen

`e7b46e8` glich Modellauftrag, Antwortschema und bestehende Validatorbedingungen ab:

- alle 15 Pflichtfelder und verschachtelten Objekte, keine zusätzlichen Felder;
- dieselben 13 POS-Werte, Funktionen `null`/`base`/`past`/`past_participle` und Gründe `original`/`too_short`/`unusable_target`;
- `reuse_id` nur null oder eine angebotene, geeignete, nicht zurückgestellte aktive Referenz;
- nichtleere Texte ohne U+0000–001F; bestehende UTF-16-Grenzen von 200, Satz 600, Satzhinweis 1200 Einheiten;
- nullbasierte UTF-16-Offsets, astrale Zeichen zählen zwei Einheiten, exakte ganze Zielform;
- bestehende 3–40-Wort-Grenze auch für Originale, begründeter Ersatz bei ungeeignetem Original;
- Original unverändert, auch ohne Schlusszeichen; Ersatz genau ein Satz mit Endzeichen;
- `cache_note` immer nichtleer, auch bei Vollübernahme;
- Cacheübernahme nur mit passender Form/Bedeutung, kanonischem POS, zulässigen Längen und lösungsfreien Übungsfeldern.

Nicht vom Anbieter unterstützte Schema-Längenkeywords wurden nicht als vermeintliche Garantie eingebaut; Grenzen stehen in Auftrag/Feldbeschreibungen und bleiben lokal validiert. Die spätere Prüfung der offiziellen Structured-Output-Dokumentation ergab keinen belegten Grund, primitive/null-Enums oder Typ-Arrays pauschal als Ursache der aktuellen 400 zu verwerfen.

Referenz der bisherigen Prüfung: https://platform.claude.com/docs/en/build-with-claude/structured-outputs . Bei erneutem Abgleich den aktuellen Anbieterstand prüfen, statt Vermutungen zu übernehmen.

### G. 24-Stunden-Fehlersperre durch regulären expliziten Retry ersetzt

Die bisherige Auftragsaufbewahrung führte nach Fehlern zu einer unerwünschten 24-Stunden-Wartefrist. Der Nutzer änderte ausdrücklich das Produktverhalten. `3696a3e` implementierte einen atomaren Retry mit Versuchsgeneration, ohne bestehende Aufträge zu löschen oder ihre Identität zu ändern.

Die zuerst dokumentierten Wartezeiten bis 26.10. sind damit **überholt**. Nicht aus älteren Berichtskapiteln erneut als aktuelle Anweisung übernehmen.

### H. Letzter Geräte-Retry: MODEL_FAILED durch Anbieter-HTTP400 — offen

Am 25.10. **10:04:50 UTC / 11:04:50 MEZ** endete zunächst die Ergebnis-/Auftragsprüfung mit `claim / REQUEST_UNCERTAIN /409`, ohne Modellaufruf.

Der anschließende ausdrückliche Retry um **10:05:02 UTC / 11:05:02 MEZ**, Diagnose-ID **`b8057299-4b95-4ef3-a225-9f1d063c6805`**, führte genau einen neuen beobachteten `model_request` aus und erhielt Anbieter-HTTP400. Details stehen am Anfang dieses Berichts.

Damit ist belegt, dass der reguläre Retry den Anbieter erreicht. Nicht belegt ist eine erfolgreiche Erstellung. Dieser Fehler entsteht früher als `MODEL_INVALID`/`ANSWER_LEAK`: Es gibt noch keine zu validierende Modellantwort.

`bfd5edb`, deployed als Function v6, liest Fehlerantworten begrenzt auf 8192 Bytes und gibt ausschließlich feste Kategorien aus:

`PROVIDER_ERROR_UNCLASSIFIED`, `PROVIDER_INVALID_REQUEST`, `PROVIDER_CREDIT`, `PROVIDER_SCHEMA_COMPLEXITY`, `PROVIDER_SCHEMA`, `PROVIDER_AUTH`, `PROVIDER_PERMISSION`, `PROVIDER_NOT_FOUND`, `PROVIDER_RATE_LIMIT`, `PROVIDER_OVERLOADED`, `PROVIDER_API`.

Keine rohen Anbietertexte, IDs, Schlüssel, Schemawerte oder Nutzertexte werden geloggt. Die Klassifikation kann auch weiterhin nur „invalid request“ oder „unclassified“ liefern. Sie garantiert keine vollständige Ursachenklärung. Der ursprüngliche Fehler, die Retry-Sicherung und das Verbot automatischer Wiederholungen bleiben unverändert.

## 6. Aktueller Erstellungs- und Wiederaufnahmeweg

Serverpfad:

```text
Authentifizierung
→ Release-/Sprachbindung
→ tatsächliches Pack laden und Hash/Referenzen prüfen
→ atomaren Auftrag prüfen/zuteilen
→ vorhandenes gültiges Ergebnis übernehmen ODER Modell einmal aufrufen
→ Envelope/JSON prüfen
→ fachliche Antwort validieren
→ Ergebnis mit aktueller Versuchsgeneration speichern
→ Clientantwort validieren
→ lokale Karte/Bindung atomar anlegen
→ Sammlung und Übung lesen
```

Wiederholungsregeln:

- Laufendes `pending` mit aktiver 45-Sekunden-Lease: blockiert parallele Generierung, keine neue Modell-/Quotenreservierung.
- `ready` innerhalb der bestehenden 30-Tage-Aufbewahrung: Ergebnis wiederverwenden, keine Neugenerierung.
- Eindeutiger Fehler vor Speicherung: mit aktueller Versuch-ID als `failed` markieren.
- Timeout/unklarer Speichererfolg: Ausgang offen lassen; beim nächsten ausdrücklichen Zugriff zuerst gespeichertes Ergebnis suchen.
- Fehlgeschlagen oder Lease abgelaufen: beobachtete Versuch-ID zurückgeben; erst ein weiterer bewusster Retry sendet dieses Ticket zurück.
- SQL prüft unter dem bestehenden Transaktionslock die Generation, reserviert die unveränderte Quote und vergibt atomar eine neue UUID-Versuchsgeneration.
- Konkurrierende/veraltete Retry-Anfragen mit demselben alten Ticket können nicht noch einen Versuch beginnen.
- Finish/Fail sind an das aktuelle Ticket gebunden; Finish zusätzlich an eine gültige Lease. Ein alter Worker darf keinen neueren Versuch überschreiben.
- Abgelaufene Ergebnis-Payloads werden weiterhin entfernt; die Versuchsgeneration bleibt als Schutz gegen implizite Neugenerierung bestehen.
- Der Request-Identitätsschlüssel bleibt unverändert. `retry_ticket` ist Kontrollmetadatum und kein Bestandteil des Modellauftrags oder Identitätshashes.
- Client hält Tickets kontogebunden im Prozess, dedupliziert parallele Klicks und sendet erst nach ausdrücklicher Aktion erneut. Nach Neustart wird der Serverzustand erneut geprüft.

Bestehende Limits: 20 Reservierungen pro Nutzer/Tag, 5 pro Minute, global 1000 pro Tag. Fehlversuche können Reservierungen verbrauchen. Die lokale Reservierung ist keine garantierte Rechnungsobergrenze des Anbieters.

## 7. Relevante Dateien und Commits

| Datei | Aufgabe |
|---|---|
| `supabase/functions/create-learning-card/index.ts` | Function-Einstieg |
| `supabase/functions/_shared/personal_learning.ts` | Input, Modellauftrag, Schema, Validator, Backendablauf und Handler |
| `supabase/functions/_shared/personal_trace.ts` | Sichere Stufen-/Regel-/Anbieterdiagnosen |
| `supabase/functions/_shared/personal_release.ts` | Release-/Hashbindung, tatsächliche Packprojektion und Prozesscache |
| `supabase/functions/_shared/personal_sentence.ts` | Ersatzsatzprüfung |
| `supabase/functions/_shared/runtime_translation.ts` | Gemeinsame Modell-/Runtimegrundlagen; normale Übersetzung gesondert beachten |
| `lib/domain/personal_learning.dart` | Ziel-/Antwortvertrag und Identität |
| `lib/data/personal_learning_client.dart` | Auth, Zustimmung, HTTP, Deduplizierung und Retryticket |
| `lib/data/learning/personal_learning_service.dart` | Status, Kandidaten, Cachehinweise, explizite Erstellung und Save |
| `lib/widgets/personal_learning_button.dart` | Add-/Retry-UI, kein Erfolg vor Speicherung |
| `lib/data/user/drift_user_repository.dart` | Lokale atomare Anlage, Bindungen und Lernbestand |
| `lib/data/learning/practice_item_resolver.dart` | Sammlung/Übungskontext; `storyCollectionIds` ist ein Getter |
| `tool/test_personal_learning_sql.mjs` | SQL-Regressionssuiten |
| `tool/personal_retry_probe.mjs` | Produktionshandler mit echten lokalen SQL-RPCs und simulierten Diensten |

Commitfolge, neu nach alt:

```text
bfd5edb  Anbieterablehnungen sicher klassifizieren; Diagnose, nicht Ursachenfix
3696a3e  Explizite atomar abgesicherte Retries
e7b46e8  Vollständiger Vertragsabgleich mit vorhandener Validierung
d8a60b0  Lösungsfreie Satzhinweise klar vom Lesetext unterscheiden
bb7d3c6  Exakte sichere Validierungs-Prüfcodes
f8cc147  Sichere Erstellungsdiagnosen
c8c031a  Gemeinsame Wortgrenzen bei importierten Texten
51f842a  Gerätepack-/Edge-Vorabnahme dokumentiert
90673bb  Paket 2C Releasebindung und Regressionen
c90680b  Früher Zwischenstand mit offenen Abnahmebefunden
1c31881  Früher separater Statusfix für prospektive lokale Karten
```

Weitere Berichte in sinnvoller Reihenfolge:

1. `docs/story-creation-contract-audit.md` — neueste angehängte Befunde bis Anbieter400/v6.
2. `docs/story-creation-failure-diagnostics.md` — ursprüngliche 502 und schrittweise Diagnose.
3. `docs/story-import-status-hyphen-fix.md`.
4. `docs/story-status-device-fix.md`.
5. `docs/story-import-learning-package-2c.md` — Gerätepack-/Runtime-Vorabnahme und Grenzen.
6. `NEXTSTEPS.md`, `PRODUCT.md`, `ARCHITECTURE.md`, `AGENTS.md`/`CLAUDE.md`.

Ältere Zwischenüberschriften wie „noch nicht deployed“, frühere Sperrfristen und noch verfügbares Versuchsbudget sind durch spätere Einträge überholt. Historische Testzahlen nicht als Testlauf des jetzigen HEAD ausgeben.

## 8. Tatsächlicher Pack und Edge-Grenzen

Der heruntergeladene aktive Gerätepack ist nicht das Bootstrap-Asset.

- EN-Release: `510c6685-f0ea-4002-9c7c-a09f0bf8212b`.
- Version: `chitchat_de_korrektur_v1`, Schema 5.
- Aktive `content.sqlite`: 43.089.920 Bytes, SHA256 `30cfd77190e8985dac0c058fa3504c3bf20c792ea8830adec2a48b185dda46be`.
- Bootstrap: 26.198.016 Bytes, SHA256 `b85793932825a22e92ac744a42255e9f333acd35809aaba46edb5a395f099bdb`.
- Veröffentlichtes `pack.json`: 50.282.981 Bytes, SHA256 `92c44ef9f163e213cf9a44e6e23a264de6bfb11f6d233a1b8c5c8f676704f37c`.

Die Vorabnahme verglich die tatsächlichen Gerätepack-Kataloge/Hashes. Das vom Nutzer vermutete Appkonto hatte laut Prüfung Leserechte für en/pt-BR; seine Identität als tatsächlich aktive iOS-Schlüsselbundsitzung war damals nicht unabhängig bestätigt. Beim letzten fehlgeschlagenen Erstellungsversuch wurde Authentifizierung tatsächlich bestanden. Das ersetzt keine allgemeine Aussage über alle Konten/Sprachen.

Lokale Vollhandlerproben verwendeten echte veröffentlichte Packbytes in Supabase Edge Runtime ARM64 v1.77.1: 256-MB-Isolate, CPU soft 1000/hard 2000 ms, Wall 150 s. Auth/RPC/Storagetransport waren in diesen Proben simuliert; Modellantworten waren Replay beziehungsweise ausdrücklich synthetische Fixtures.

Beim abschließenden Vertragsreplay: negative Antwort 502 `ANSWER_LEAK`, danach 409, kein Finish; positive synthetische Antwort 200/200, ein Finish, ein Modellstub. Laufzeiten negativ 1167,5/666,5 ms, positiv 1145,6/625,8 ms; CPU 629/573 beziehungsweise 545/537 ms. Maximal beobachteter Isolate-Speicher beim Shutdown 166.440.659 Bytes.

**Messgrenze:** Shutdown-Speicher ist kein kontinuierlich gemessener Peak. Gesamtprozess-RSS umfasst weitere Runtimekomponenten. Positive lokale Laufzeiten beweisen weder Anbieterakzeptanz des Requests noch einen erfolgreichen Cloud-/Geräte-Add. Frühere Parallelproben zeigten mehrere Projektionen über Worker; einen prozessübergreifend geteilten Cache nicht voraussetzen.

## 9. Tests: vorhanden, bestanden und ihre Grenzen

Zuletzt dokumentiert für `bfd5edb`:

- Backend/Trace: **20 PASS**, einschließlich geschützter Sentinel-Inhalte, sicherer Kategorien und ausbleibender Speicherung/automatischer Wiederholung bei Anbieterfehlern.
- Vier PostgreSQL/PGlite-Suiten: **PASS** für Runtime-Limits, Übersetzungscache, persönliche Erstellung und Retry.
- Zusätzliche Produktionshandler-/SQL-Probe: **PASS** für Fehler → ausdrücklichen Retry, acht konkurrierende Anfragen mit einem neuen Modellstub, verlorene Finish-Antwort → gespeichertes Ergebnis ohne weiteren Modellstub.

Vor der letzten ausschließlich serverseitigen Diagnoseänderung:

- **32 gezielte Fluttertests PASS** einschließlich Original-Packtest, SQLite-Speicher-/Sammlungsweg, Persistenz nach Schließen/Öffnen, separatem Lesecache, Wiederaufnahme und Client-/Widget-Retry.
- Analyse: nur bestehender `avoid_print`-Hinweis in `test/data/baseline_adoption_pack_test.dart:43`; kein behaupteter vollständig warnungsfreier Gesamtlauf.
- SQL prüft alte Finish-/Fail-Tickets, Leaseablauf, Ergebnisaufbewahrung, Rechte und unveränderte Quoten.
- Clienttest simuliert verlorene HTTP-Verbindung nach Serversave und führt die Wiederaufnahme bis zur echten lokalen SQLite-Karte fort: eine Karte/ein Kontext, keine Reviews.

Wichtige Testdateien:

```text
supabase/functions/_shared/personal_learning_test.ts
supabase/functions/_shared/personal_trace_test.ts
test/personal_learning_test.dart
test/personal_learning_flow_test.dart
test/personal_retry_client_test.dart
test/personal_retry_test.dart
test/personal_reading_cache_preservation_test.dart
test/personal_sentence_cue_test.dart
test/story_collection_test.dart
test/data/real_pack_test.dart
```

Node-Testbefehl (auf Windows/PowerShell und macOS/Terminal gleiche Syntax, Node 24 vorausgesetzt):

```text
node --experimental-transform-types --test supabase/functions/_shared/personal_learning_test.ts supabase/functions/_shared/personal_trace_test.ts
```

Flutterbefehle sind ebenfalls plattformgleich; lokaler Mac-SDK-Pfad: `/Users/ardasayar/dokumente/flutter/bin/flutter`. Für SQL benötigt der lokale Runner PGlite; bisheriger Mac-Pfad `/private/tmp/sprachapp-cache-sql/node_modules/@electric-sql/pglite/dist/index.js` ist temporär und nicht als portable Projektabhängigkeit zu behandeln.

**Nicht bewiesen:** echte Anbieterannahme des aktuellen Produktionsrequests, erfolgreiche Livegenerierung nach Vertragskorrektur, reale Cloudkonkurrenz unter Last und vollständige Geräteabnahme. PGlite serialisiert SQL-Aufrufe; acht konkurrierende JavaScript-Anfragen sind kein Cloud-Mehrverbindungs-Lasttest. Mock-Provider akzeptieren Requests, die der echte Anbieter ablehnen kann. Genau diese Testlücke ist aktuell relevant.

## 10. Sichere Nachweise und praktische Zugriffshürden

Geschützte temporäre Verzeichnisse außerhalb des Repositorys, zuletzt mit Verzeichnismodus 700:

### `/private/tmp/sprachapp-2c-single-experiment`

- `response.json` / `response.raw`: ausschließlich die vereinbarte synthetische Modellantwort, geschützt; nicht in allgemeine Logs oder Commits kopieren.
- `request.json`, `live-result.json`, `live-trace.json`, `replay-result.json`, `replay-trace.json`, `source-hashes.json`.
- `run_once.py`: verdeckte Schlüsseleingabe im Nutzerterminal, Schlüssel nur im Kindprozess; keine Produktionsdatenbankänderung.
- `run.mts`: enthält unterschiedliche Modi. Vor jeder Nutzung lesen und sicherstellen, dass nur modellfreies Replay läuft.
- **`ATTEMPT_USED` existiert. Nicht löschen und keinen erneuten Liveaufruf damit erzwingen.**
- `edge_replay.py`, `edge-main.ts` und Replayausgaben: lokale Runtimeproben, keine neue Anbieteranfrage nötig.

### Weitere temporäre Nachweise

- `/private/tmp/sprachapp-2c-preflight-20261025`: Pack-/Gerätevorabnahme; private Exporte ausschließlich geschützt außerhalb des Repositorys belassen.
- `/private/tmp/2c-observe-creation.py`: sicherer lesender Management-API-Logabruf, feste Feld-Allowlist, zuletzt 30-Minuten-Fenster. Ein leeres späteres Zeitfenster widerlegt keinen historischen Request.
- `/private/tmp/2c-check-job-expiry.py`, `/private/tmp/2c-check-retry-ready.py`: private lokale Kontofilter; Quelltext/Ergebnisse nicht unredigiert ausgeben.
- `/private/tmp/2c-provider-tests.log`, `/private/tmp/2c-provider-sql.log`, `/private/tmp/2c-provider-functions.json`, GitNexus-Prüflogs und ältere `/private/tmp/2c-retry-*.log`.

Temporärdateien können nach Neustart/Bereinigung verschwinden. Ihr Fehlen nicht durch erfundene Nachweise ersetzen. Sie sind keine Buildabhängigkeit.

Zugangshürden während der Arbeit:

- iPhone-Dateizugriff brach zeitweise mit „Connection reset by peer“ ab. Entsperren/Kabel/Vertrauen war nötig; kein Reset.
- Supabase-CLI-Anmeldung liegt im macOS-Schlüsselbund. Wiederholte lesende Zugriffe lösten Freigabedialoge aus. Zugangsdaten nur im Prozess erfassen, niemals ausgeben.
- Der bestehende Anthropic-Schlüssel liegt als Supabase-Secret vor und lässt sich nicht als normaler Secret-Read zurückholen. Lokal war kein Schlüssel in Prozessumgebung oder `pipeline/.env` verfügbar.
- Ein Export im separaten Nutzerterminal wird nicht automatisch im Agentenprozess sichtbar. Deshalb wurde für den einmaligen synthetischen Versuch ein kontrollierter TTY-Eingabeweg erstellt.
- Der einmalige Testschlüssel kann widerrufen werden; es besteht keine Freigabe, ihn erneut zu verwenden.
- Beim Management-Logabruf musste das UTC-Zeitformat mit Millisekunden/`Z` stimmen; eine vorherige API400 war ein Diagnoseabfrageproblem und ist vom aktuellen **Anbieter400** zu unterscheiden.
- Ein Beobachtungshelfer las zunächst `status` statt `http_status`; das wurde korrigiert. Fehlende Felder in alten Helferausgaben nicht als fehlende Serverevents interpretieren.

## 11. Weitere Schwierigkeiten und Grenzen der bisherigen Arbeit

Diese Punkte sollen verhindern, dass die nächste KI dieselben Umwege wiederholt:

1. **Mehrere unabhängige Fehler wurden nacheinander sichtbar.** Status-ID, Tokenauswahl, Antwortvertrag, Retryregel und Anbieter400 sind nicht dieselbe Ursache. Eine Korrektur in einem Teil bewies nie den vollständigen Weg.
2. **Zu grobe historische Diagnosen.** Die erste 502 und spätere MODEL_INVALID-Antwort waren nicht vollständig rekonstruierbar. Nachträglich ergänzte Prüfcodes liefern keine verlorenen Antworten zurück.
3. **Der entscheidende Produktionsnachweis fehlt trotz vieler grüner Tests.** Die Tests decken Speicher-/Retrylogik ab, ersetzen aber den Anbieter nicht. Der echte Anbieter lehnt aktuell den Request ab. Weitere reine Mock-PASS sind keine Lösung dafür.
4. **Diagnosefortschritt wurde wiederholt ausgeliefert, ohne den gesamten Nutzerweg zu schließen.** Der Nutzer erwartet zu Recht eine belegte Korrektur und eine Karte auf seinem Gerät. Der Bericht darf diesen Zustand nicht beschönigen.
5. **Retry-Aufbewahrung brauchte eine zweite SQL-Korrektur.** Beim Entfernen der alten pauschalen Bereinigung musste die bisherige 30-Tage-Aufbewahrung gespeicherter Antworten erhalten bleiben. Deshalb zweite eng begrenzte Migration, jeweils separater Dry-run; keine stillschweigende unbegrenzte Payloadspeicherung.
6. **Node strip-only genügte nicht.** TypeScript-Parameterproperties erfordern hier `--experimental-transform-types`.
7. **Flutter-Widgetbinding verfälschte einen Netzwerktest.** Es erzwingt HTTP400 für echte Netzwerkanfragen. Client-/Netzwerktest wurde vom Widgettest getrennt. Dieser Test-Harness-400 ist nicht der aktuelle Anthropic400.
8. **Kleinere lokale Testfehler wurden behoben:** `storyCollectionIds` zunächst fälschlich wie Methode aufgerufen; Null-aware-/Klammer-Lints korrigiert. Keine offenen Ursachen des Gerätefehlers.
9. **GitNexus-MCP war zeitweise nicht erreichbar.** CLI-Fallback funktioniert. Graphprüfungen meldeten teils sehr breite/critical Auswirkungen über gemeinsame Symbole; das nicht als low risk umdeuten. Letzte Diagnoseänderung blieb inhaltlich eng begrenzt.
10. **Fremde CRLF-/UI-Diffs erschweren globale Checks.** `git diff --check` für den gesamten Arbeitsbaum meldete fremde Zeilenendefunde in `lib/main.dart`; eigene gestagte Diffs waren sauber. Fremde Dateien nicht pauschal formatieren.

## 12. Fremde Änderungen erhalten

Beim Erstellen dieses Berichts waren folgende bereits vorhandene Änderungen offen; sie gehören nicht zum Diagnosefix:

```text
 M docs/redesign/design-system.md
 M lib/main.dart
 M lib/presentation/celebration_sounds.dart
 M lib/screens/onboarding/onboarding_screen.dart
 M skills-lock.json
 M test/onboarding_test.dart
?? .agents/skills/refero-design/
?? .claude/skills/refero-design
?? assets/sounds/onboarding_paywall.mp3
?? assets/sounds/onboarding_select.mp3
?? lib/presentation/onboarding_sounds.dart
?? lib/screens/onboarding/paywall_screen.dart
?? lib/screens/onboarding/widgets/account_sheet.dart
?? lib/screens/onboarding/widgets/onboarding_motion.dart
```

Kein Reset, kein pauschales `git add .`, keine Wiederherstellung dieser Dateien aus HEAD. Dieser Übergabebericht kommt als neue Dokumentationsdatei hinzu.

## 13. Konkreter Auftrag an das nächste Modell

1. Zuerst `AGENTS.md`, Produktregeln, diesen Bericht, den aktuellen Gitstatus und den aktuellen Code lesen. Die Dokumentation beschreibt mehrere Zeitstände; letzten Befund als Ausgangspunkt nehmen.
2. Den tatsächlich an Anthropic gesendeten HTTP-Vertrag einschließlich Modell, Headern, Body, Structured-Output-Schema und dessen Verschachtelung vollständig nachvollziehen. Graph zuerst; vor Symboländerungen GitNexus-Impact, vor Commit `detect_changes --scope all`. `UNKNOWN` ist keine Entwarnung.
3. Vorhandene lokale Requests/Fixtures, sichere Logs und Anbieterregeln vergleichen. Keine spekulative Schemaänderung und keine fachliche Validatorlockerung. Prüfen, was sich zwischen erfolgreichem lokalen Modellaufruf und dem späteren produktiven HTTP400 tatsächlich geändert hat. Unterschiede zunächst belegen, nicht zur Ursache erklären.
4. Wenn eine konkrete Ursache lokal nachweisbar ist: minimal korrigieren, eine zuvor scheiternde Regression ergänzen und Speicher-/Wiederaufnahmeweg erhalten. Wenn keine Ursache belegbar ist: exakt benennen, welche Anbieterinformation fehlt. Der vorhandene Kategorienlogger kann zu grob bleiben.
5. Keine weitere echte Anbieteranfrage ohne neue ausdrückliche Freigabe. Falls sie unvermeidbar ist, zuerst einen konkreten sicheren Einzelversuch vorbereiten, der den fehlenden Nachweis wirklich liefert und eine lokale Reproduktion ermöglicht. Keine rohen Antworten echter Nutzer in Cloudlogs; keine dauerhafte Produktionsantwortsammlung.
6. Eindeutig zwischen Anfrageablehnung, unbrauchbarer Modellantwort, Validatorfehler und Speicherfehler unterscheiden. Unbrauchbare Antworten dürfen weiterhin keine Karte erzeugen. Nur eindeutig verlustfreie technische Normalisierung ist zulässig.
7. Relevante Backend-, SQL-, Flutter-, Original-Packtests und Analyse ausführen. Reale Packbytes und produktive Repositorybindungen berücksichtigen. Teststubs und Messgrenzen offen nennen.
8. Vor erforderlicher Cloudänderung konkreten Diff/Stand prüfen; ausschließlich die freigegebene eng begrenzte Änderung ausliefern. Appupdate mit vorhandenen Defines, niemals deinstallieren. Kein Push.
9. Für eine erneute Geräteabnahme sichere Beobachtung bereitstellen und dem Nutzer den einen konkreten Klick nennen. Bei erstem Fehler den zugehörigen Code/Trace auswerten, keinen weiteren Modellaufruf automatisch starten.
10. Abschluss getrennt berichten: **Diagnose verbessert / belegte Ursache korrigiert / lokal geprüft / ausgeliefert / auf dem Gerät tatsächlich bestätigt**.

### Kopierbarer Startauftrag

> Arbeite im Hauptprojekt `/Users/ardasayar/Documents/FlutterProjekte/sprachapp`. Lies zuerst `docs/HANDOFF-story-card-creation-2026-10-25.md` und `AGENTS.md`. Übernimm die Fehlersuche am Story-Import→Lernkarte-Weg. Aktueller belegter Blocker ist eine Anthropic-HTTP400-Ablehnung vor Antwortvalidierung und Speicherung, nicht der bereits behobene Wortauswahlfehler und nicht nachgewiesenermaßen der frühere ANSWER_LEAK. HEAD ist beim Übergabestand bfd5edb; Function v6 verbessert nur die Diagnose. Prüfe zuerst lokal den tatsächlichen Requestvertrag und die vorhandenen Nachweise und arbeite bis zu einer belegten minimalen Korrektur, soweit ohne neue Modellanfrage möglich. Es ist kein weiterer echter Modellaufruf freigegeben. Keine Sperren umgehen, keine Lernstände verändern, keine fremden Änderungen überschreiben und kein Push. Frage erst dann nach einer neuen begrenzten Freigabe, wenn der dafür notwendige konkrete Versuch vorbereitet ist und der fehlende Nachweis feststeht. Ziel ist eine tatsächlich gespeicherte Karte unter „Aus Storys“, genau ein Übungskontext und Erhalt nach App-Neustart; eine Installation ist keine Geräteabnahme.
