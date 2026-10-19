# Plan: Prozesslokale Wiederverwendung der Inhaltsvalidierung

Stand: 19.10.2026. **Variante B in Paket 1 und Paket 2 implementiert und auf dem iPhone gemessen.** Planbasis `e3580c3`, Produktcode `0e2f890`, Worktree `/Users/ardasayar/.codex/worktrees/batch-content-queries/sprachapp`. Ersetzt die Empfehlung „nur A“. Kein persistenter Nachweis, keine Variante C, keine Home-Optimierung. Umsetzung auf Basis `61971b7`: [Paket-2-Nachweis](content-validation-package-2.md); die folgenden ursprünglichen Kalkulationen bleiben ausdrücklich Schätzungen der Planphase.

## Entscheidung und Wirkung

Empfohlen wird ein auf **zwei abgeschlossene Identitätsnachweise** begrenzter Prozess-LRU. Nach erster vollständiger Prüfung dürfen weitere Opens derselben unveränderten Downloadgeneration die fachlichen Prüfungen wiederverwenden. Jeder neue Reader bindet seine tatsächlich verwendeten Bytes erneut an die Identität. Ein Appneustart beginnt ohne Nachweise. Es werden keine Inhalte, Home-Zähler, Lernstände oder ungeleasten Verbindungen gecacht.

Aus A bleiben ausschließlich die sichere Bytebindung und die einmalige Vollprüfung auf dem anschließend von Drift verwendeten Handle. Eine private temporäre SQLite-Kopie ist weiterhin erforderlich: Hashen eines Quellpfads und anschließendes Neuöffnen desselben Pfads beweist bei Dateiaustausch nicht dieselben Bytes. Ein SQLite-Lesesnapshot allein bindet keinen zuvor berechneten Datei-Hash. Umgesetzt mit dem vorhandenen `DriftIsolate.inCurrent` und `NativeDatabase.opened`: Ein Worker bereitet vor und wird danach zum Drift-Server (begründete Korrektur des ursprünglichen LazyDatabase-Vorschlags, siehe Paket 1); kein zusätzlicher Validierungsworker und keine neue Abhängigkeit. Der bisherige vorgeschaltete `Isolate.run` entfällt nur auf diesem neuen Download-Read-Pfad.

Messbasis bleibt der tatsächliche Gerätepack: Schema 5, `chitchat_de_korrektur_v1`, 43 089 920 Byte SQLite und 10 353 596 Byte Inventar. Nicht der kleinere Schema-4-Bootstrap. [Messbericht](content-loading-performance.md): Wechselmedian 4 989 ms; Home danach 1 294 ms und erste Übung 62 ms jeweils Einzelmessungen. Paket 2 misst inzwischen acht warme Wechsel: Median 812 ms, alle unter 1 s packbereit; Home zusätzlich Median 1 350 ms, erste Übung Median 60 ms. Kalter Prozess: ContentRepository 4 154 ms, Home-Frame 5 508 ms. Einzelwerte, Grenzen und Ressourcen im Paket-2-Nachweis.

| Ablauf | Verbleibende Arbeit | Ausschließlich geschätzte Wirkung |
|---|---|---|
| Erster Start / erste Prüfung | Journal/Manifest, Kopie und beide Hashes, einmal volle Schema-/Inhaltsprüfung und eigener Inventarabgleich, Drift-Integritätsprüfung | Gegenüber gemessenem Kaltstart 5 068 ms packbereit grob `5 068 − 1 327 + C = 3 741 ms + C`; Home-Kaltstart grob `6 435 − 1 327 + C = 5 108 ms + C`. Übertragung des Wechsel-Teilwerts auf Kaltstart ist unsicher. Erster ungecachter Wechsel grob `3 662 ms + C`. |
| Wiederholter Wechsel, gültiger Prozessnachweis | Journal/Manifest, neue gebundene Kopie, beide Bytehashes, quick_check/Release; keine fachliche Vollprüfung und kein JSON-/Tabelleninventarabgleich | Größenordnung packbereit `0,54 s Hash/Lesen + 0,03 s quick_check + ca. 0,01 s übrige Arbeit + C ≈ 0,58 s + C`. Rund 4,4 s vermeidbare Arbeit gegenüber 4,99 s, abzüglich C; keine additive exakte Medianrechnung. |
| Neue Installation / Aktivierung | Downloadprüfung und Historienvergleich, erneute Freigabe und vollständige Aktivierungsprüfung; Prepared-Open vollständig, dort nur einmal statt doppelt | Kein warmer Treffer für neue Identität/Prepared. Potenziell eine zweite Read-Vollprüfung weniger; Gesamtdauer des Updates ist nicht gemessen und wird nicht zugesagt. |

`C` ist die unbekannte Nettoänderung durch Kopieren, Flush, Hashen der Kopie statt Quelle, Workerstart und Handshake. Unter 1 s **packbereit** ist nur plausibel, wenn diese Restkosten unter etwa 0,42 s bleiben. Home vollständig nutzbar läge warm grob bei `0,58 + 1,294 + C ≈ 1,87 s + C`, ohne Bedienpause. Unter 1 s für die nutzbare Home ist mit dem verbleibenden Home-Posten nicht begründbar. Erstes Übungsöffnen wird separat nachgemessen; keine Arbeit dorthin verschieben.

## 1. Codebelege und Basislebenszyklus vor Umsetzung

Die Pfade wurden über GitNexus `query`/`context` ermittelt und im Code bestätigt. Zeilennummern beziehen sich auf die Basis oben:

| Beleg | Aussage |
|---|---|
| [content_pack_installer.dart](../lib/data/content/content_pack_installer.dart), `install` Z. 62–72, `open` Z. 148–160 | Installation/Recovery liefert nur Datei und Manifest; `open` validiert danach erneut. |
| [content_update_service.dart](../lib/data/content/content_update_service.dart), `download` Z. 132–229, `activate` Z. 230–282 | Downloadhash, Kandidaten-/Historienprüfung, Rename, Pending; vor Aktivierung erneute Autorisierung und Prüfung, dann Prepare/Active/Open/Commit. |
| Dieselbe Datei, `verifyGeneration` Z. 295–317, `_validateInIsolate` Z. 322–326, `recoverContentInstallation` Z. 330–369 | Beide Dateien erneut hashen, vollständigen Validator ausführen; auch der normale `active != null`-Zweig tut das. Rückgabetypen `void` bzw. `ReleaseOffer?` transportieren keinen geprüften Reader. |
| [content_update_validation.dart](../lib/data/content/content_update_validation.dart), `validateDownloadedContent` ab Z. 87 | Inventar lesen und kanonisch hashen, erlaubtes SQL-Schema prüfen, `validateContentSchema`, jede Inventarzeile prüfen; bei `previousPath` zusätzlich historische Identitäten/Unveränderlichkeit prüfen. Handle wird im `finally` geschlossen. |
| [content_database.dart](../lib/data/content/content_database.dart), `validateContentSchema` ab Z. 71, `openInBackground` Z. 458–483 | Vollprüfung umfasst quick_check, Pflichtspalten, Release/Sprache und je Schema Satz-, Gruppen-, Form-, Kontextvalidator. Danach neues Drift-Isolate mit neuer Verbindung, nochmals quick_check und Releasevergleich. |
| [content_install_journal.dart](../lib/data/content/content_install_journal.dart), `write`, `active`, `prepare`, `commit`, `restorePrepared` | Atomare Metadaten-Renames; Generationen werden nicht überschrieben. Prepared enthält vorherigen und nächsten Zeiger, Committed den nächsten. |
| [content_release_client.dart](../lib/data/content/content_release_client.dart), `ReleaseOffer.parse` Z. 35–146 | Manifest-Hash, Sprache/Profil, Schema/Fähigkeiten und Dateideskriptoren werden geprüft. Inhalts-Bytehash und kanonischer Inventarhash sind verschiedene Bindungen. |
| [database_providers.dart](../lib/presentation/providers/database_providers.dart), `RepositoryOwner` Z. 20–85, Schlüssel/Factory Z. 91–114 | Leases teilen Verbindung; letzter Release schließt; neuer Open wartet auf Close/Pause. Schlüssel `(lang, generation)` ist ein Routing-Schlüssel, **kein** Prüfnachweis. |
| [language_selection_provider.dart](../lib/presentation/providers/language_selection_provider.dart), Z. 57–150 | Gate, Ziel-Lease vor Änderung, alter Reader schließen, Sprache persistieren, neuer Scope, Rollback bei Fehler. |
| [content_update_provider.dart](../lib/presentation/providers/content_update_provider.dart), `_getService`/`closeReaders`/`openReaders` | Update aktiviert über dieselben Owner; Epoch schützt verspätete UI-Meldungen. Der bestehende Resume-vor-Key-Rebuild-Pfad bleibt eine gesondert zu testende Lifecycle-Grenze. |

### Prüfzweck, Eingaben und Häufigkeit

`V` bezeichnet eine volle Schema-/Inhaltsprüfung einer Kandidatendatenbank, `I` den vollständigen eigenen Inventarabgleich, `H` den Vergleich mit der vorherigen Generation. Häufigkeiten gelten je erfolgreichem Aufruf, nicht je App-Lebenszeit; Fehler/Recovery können weitere Versuche verursachen.

| Phase | Zweck / Eingaben | Heutige Aufrufe |
|---|---|---|
| Versionsangebot prüfen | Freigabe über authentifizierten Transport; danach Manifestformat/-hash, Sprachprofil, Features, Dateigrößen/-hashes | Bei `latest`, beim Lesen eines aktiven/pending Angebots erneut lokales Parse; Hash allein ist keine Signatur. |
| Neuer Download | Größe und SHA-256 **beider** Streams gegen Angebot; Teilpakete abweisen | Ein Streaming-Hash pro Datei; anschließend `V + I + H` des `.part`-Kandidaten. `H` nur mit vorherigem Bestand, einschließlich dessen lesbarer Schema-Prüfung bzw. gebundenem Reparaturinventar. |
| Installation als Kandidat | `release.json`, atomarer Rename `.part → generation(id)`, `pending` | Keine weitere Vollprüfung beim Rename. Bereits existierende Generation wird stattdessen erneut mit `verifyGeneration(previous)` geprüft. |
| Pending wiederaufnehmen | Pending muss zum neuen Angebot passen | `check` ruft `verifyGeneration(previous)` auf: zwei Datei-Hashes, `V + I + H`. |
| Aktivieren | Unmittelbare erneute Freigabe, Kandidat noch unversehrt, historische Kompatibilität | Vor Close/Prepare: zwei Hashes, `V + I + H`. Danach `openReaders`: Recovery des Prepared/Next-Zeigers mit Hashes, `V + I`, dann nochmals `V` in `openInBackground` und zusätzlicher Drift-quick_check. Somit drei Kandidaten-`V` im normalen Aktivierungsablauf, nicht drei pro gewöhnlichem Sprachwechsel. |
| Normaler Appstart / neuer Ziel-Owner beim Sprachwechsel | Lokalen aktiven Bestand offline auf Schäden prüfen; keine Online-Reautorisierung installierter Inhalte | `recover… → verifyGeneration(previous:null)`: zwei Hashes, `V + I`; anschließend `openInBackground`: zweites `V`; Drift: weiterer quick_check/Release. Hier findet **kein** erneuter Vergleich gegen den Vorgänger statt. |
| Weiterer Lease desselben offenen Owners | Bereits laufende Verbindung teilen | Keine neue Prüfung, solange `_current` tatsächlich gehalten wird. Schließen und späteres Neuöffnen führt wieder zum obigen Pfad. |
| Wiederherstellung Prepared/Next | Kandidat nach Zeigerwechsel vollständig verifizieren; Erfolg committen, sonst zurückrollen | Hashes, `V + I`; bei Fehler Vorgänger ebenfalls verifizieren. Danach heutiger normaler Opener nochmals `V`. |
| Bootstrap | Pinned-Manifest und Asset-Bytes; keine Schema-5-Downloadinventare erfinden | Bestehender Bootstrap: Hash + `V` + Drift-quick_check. Erstinstallation prüft Kandidat vor Rename und später nochmals beim Öffnen. Der B-Vorschlag lässt diesen bestehenden Bootstrap-Pfad unverändert. |

### Warum die Doppelprüfung besteht

`recoverContentInstallation` vereint Zustandsreparatur **und** Verifikation eines normalen aktiven Packs. Der `else if (active != null)`-Zweig ist keine Crash-Recovery, führt aber absichtlich dieselben lokalen Integritäts-/Inhaltsprüfungen aus. Das schützt vor fehlenden oder beschädigten installierten Daten ohne Asset-Fallback. `verifyGeneration` verwirft den geprüften Handle und `ContentInfo`; der Installer gibt nur einen Pfad zurück. `openInBackground` muss deshalb aus seiner heutigen Sicht selbst prüfen. Sein späterer Kommentar über hashgeprüfte unveränderliche Bytes ist kein typisierter Nachweis und verbindet die drei Handles nicht miteinander.

Nicht redundant sind Transport-/Manifestbindung, Prüfung einer seit dem Download möglicherweise beschädigten Generation vor Aktivierung, Vorgängerkompatibilität bei Packupdates, Journal-Konsistenz und das Prüfen eines bislang ungeprüften Inhalts. Redundant innerhalb **eines** normalen Opens ist die zweite semantische Vollprüfung identischer Bytes. Ein anderer Pfad mit gleicher Version oder Dateigröße ist nicht dasselbe Prüfergebnis.

## 2. Identität und sicherer warmer Open

### Einziger wiederverwendbarer Nachweis

`GenerationIdentity` enthält Sprache, Release-ID, Generation, Release-Version, Schema, Manifestformat und kanonischen Manifesthash, Reader-/Featurevertrag, Profil-ID/-hash, Inhalts-SHA-256 und Bytezahl, Inventar-**Bytehash** und Bytezahl aus `objects`, kanonischen Inventarhash aus dem Manifest und `validationContractVersion`. Das vollständige Tupel entscheidet über Gleichheit, nicht nur `(lang, generation)`. Angebot nach `ReleaseOffer.parse` tief unveränderlich übernehmen. Nachweisumfang ausschließlich `installedRead`; Update-/Vorgängerfreigaben sind keine Cacheeinträge.

Neue Konstante `validationContractVersion = 1`: bei Änderungen an Pflichtschema, SQL-Allowlist, Kanonisierung, Satz-/Gruppen-/Form-/Kontext-/Inventarregeln erhöhen. Profil-/Featureänderungen ändern die Identität. Neustart und Appupdate verlieren den gesamten RAM-Nachweis ohnehin; kein Deserialisieren oder Wiederannehmen von Dateien aus einem früheren Prozess.

Ein privater `InstalledReadProof` enthält nur Identität und `ContentInfo`. Nur der erfolgreiche vollständige Validator liefert das interne Vollprüfergebnis, aus dem der Koordinator nach erfolgreichem Reader-Handshake und aktueller Journal-/Epoch-Prüfung einen Eintrag veröffentlicht. Kein öffentlicher Konstruktor, `validated: true` oder optionaler Bypass am Legacy-Opener. Ein Treffer erzeugt keinen neuen Vollprüfnachweis, sondern verwendet den bestehenden.

### Ablauf pro neuem Reader

1. Journalzustand und aktives Angebot prüfen; erwartete Identität festlegen. Nur stabiler normaler Installed-Zustand ist hitfähig. Prepared/Recovery erzwingt Vollprüfung. Quellpfade ausschließlich aus geprüfter Sprache/Release-ID ableiten.
2. Einen exklusiven Ordner `content-readers/<processNonce>/<openNonce>/` anlegen. SQLite begrenzt streamend kopieren (64-KiB-Puffer, maximal deklarierte Größe und 256 MiB), Writer flushen und schließen. Die **fertige Kopie** vollständig hashen und gegen das Angebot vergleichen. Inventar bei Hit streamend vollständig hashen; bei Miss dieselben begrenzt gelesenen Bytes für Hash, JSON und kanonischen Abgleich verwenden. Ein Miss darf nach einem vorgezogenen Inventarhash nicht später ungeprüft andere Inventarbytes decodieren.
3. Auf derselben privaten Kopie im Drift-Worker read-only SQLite öffnen, `query_only=ON`. Bei passendem Prozessnachweis fachliche Validatoren auslassen; bei Miss genau einmal SQL-Allowlist, `validateContentSchema`, kanonischen Inventarhash und sämtliche Inventarzeilen prüfen. Beide Pfade behalten den zusätzlichen quick_check und den exakten Release-/Sprachvergleich der Drift-Verbindung. Der geprüfte Handle geht direkt an `NativeDatabase.opened`, nicht zurück in einen anderen Isolate und nicht erneut über einen Dateipfad.
4. Vor Veröffentlichung Journal/aktiven Manifestfingerprint, Anforderungsidentität und Provider-Epoch nochmals prüfen. Änderung: Ziel schließen, keinen Nachweis erzeugen und keine Sprache persistieren. Erfolgreiches `SELECT 1` bestätigt den Drift-Handshake. Erst jetzt Read-Lease und gegebenenfalls neuen Nachweis veröffentlichen.
5. Nach letztem Lease Drift schließen, Worker beenden, erst dann Kopie löschen und Slot freigeben. Teilkopie, Hashfehler, SQL-/Handshakefehler und Abbruch laufen durch denselben idempotenten Cleanup. Closefehler halten die bestehende Sicherheitsbarriere; keinen möglicherweise lebenden Handle als frei zählen. Beim nächsten Prozessstart ausschließlich verwaiste eigene Snapshotordner entfernen, niemals als Nachweis übernehmen.

Ein Quelltausch während Copy/Read scheitert am erwarteten Hash, sofern andere Bytes entstehen. Nach erfolgreicher Copy kann Quelltausch den gehaltenen privaten Reader nicht verändern. Das nächste Öffnen prüft die dann aktuellen Dateien erneut. Größe und mtime allein geben niemals frei. Der Snapshot wird von keinem App-Schreibpfad verändert; Generationen bleiben unveränderlich, SQLite-Sidecars werden nicht aus der Quelle mitkopiert. Arbeitskopie und Hashes schützen im Rahmen der App-Sandbox und vertrauenswürdiger App-Schreibpfade. Keine absolute Sicherheit gegen kompromittiertes OS, Prozess oder Validator; Manifesthash ist keine Herausgebersignatur.

## 3. Begrenzung, gemeinsame Prüfung und Status

- **Nachweise:** genau zwei abgeschlossene LRU-Einträge, passend zu en/pt-BR; keine Inventar-Maps oder Bytearrays darin. Eviction entfernt nur Metadaten. Gehaltene Reader laufen weiter; nächstes Öffnen eines verdrängten Nachweises prüft vollständig.
- **Single-flight:** alle App-Read-Aufrufer laufen über dieselbe Owner-Registry und vollständige Identität. Ein Owner hält genau ein Open-Future, einen Worker und dessen Reader; gleichzeitige Leases derselben Identität teilen Copy, Prüfung und Ergebnis. Kein zweiter unowned Aufruf des neuen Openers. Registryeinträge ohne Leases werden nach vollständigem Close entfernt; bestehende Providerreferenzen dürfen nicht einen zweiten Owner für dieselbe Identität erzeugen (Provider invalidieren bzw. Auflösung über Registry bei jedem Lease). Ein eigener Proof-Future pro Aufrufer ist unnötig.
- **Readerbudget:** maximal drei lebende oder schließende Download-Reader, einschließlich im Aufbau befindlicher Snapshots. Zwei reguläre Plätze für aktuellen und nächsten Reader; ein reservierter Vordergrundplatz für einen noch gehaltenen/auslaufenden alten Reader während eines Übergangs. Keine Status- oder Hintergrundvorwärmung darf Plätze beanspruchen. Ein normaler Wechsel bei aktuellem plus einem auslaufenden Reader hat damit einen Zielplatz. Bootstrap-Reader sind in derselben Owner-Aufnahme mitzuzählen, auch ohne Kopie; damit wird das Limit nicht über Legacy-Pfade umgangen.
- **Priorität und Rückstau:** vorhandenes `ContentTransitionGate` serialisiert unterschiedliche Wechsel/Aktivierungen. Weitere unterschiedliche Übergänge werden wie heute sofort als beschäftigt zurückgewiesen, nicht eingereiht. Gleiche Identität teilt den bestehenden Future. Kein spekulatives Öffnen und keine Warteschlange. Bei drei tatsächlich geleasten/fehlgeschlagen schließenden Readern wird ein vierter vor Kopie abgewiesen; dies ist ein echter Nutzungs-/Closekonflikt, niemals durch reine Statusabfrage verursacht. Keine aktive Übung oder belegter Reader wird zur Platzbeschaffung geschlossen. Practice-Gate bleibt unverändert.
- **Abbruch:** letzter Interessent vor Veröffentlichung weg oder Epoch veraltet: Ergebnis nicht veröffentlichen, keinen neuen Nachweis eintragen, Cleanup abwarten. Gemeinsame Prüfung läuft weiter, solange mindestens ein gültiger Interessent bleibt. Synchronous Validatorarbeit darf bis zur Rückkehr laufen; danach Ergebnis verwerfen, keinen ungeprüften Slot vorzeitig freigeben. Hash-/Kopierschleifen prüfen Abbruch zwischen Blöcken. Kein neuer Worker, während dessen Platz noch schließt.
- **Speicher:** höchstens drei SQLite-Kopien à maximal 256 MiB = 768 MiB temporäre Obergrenze; beim gemessenen Pack ca. 43,1 MB je Kopie. Kein Pack-Bytearray im UI-Isolate. Eine neue Vollprüfung im Vordergrund gleichzeitig; vorhandener Updateprüfpfad bleibt über Gate serialisiert. Inventarbytes/JSON/Validatorstrukturen sind temporär und durch Eingabedateigrenzen begrenzt, aber keine harte RSS-Garantie. Platzmangel ist sauberer Fehler, kein Grund Prüfungen zu reduzieren.

`languageInstallationProvider` bekommt einen **metadatenbasierten** Statuspfad: Manifest/Journal parsen und erforderliche Dateien auf Existenz prüfen, keine Hashes, Recovery, Installation, `contentInfoProvider.future` oder Owner-Lease auslösen. Ausgabe ohne aktuellen Reader: „Installiert · <Version> · Prüfung beim Öffnen“. Prepared: „Wiederherstellung beim Öffnen erforderlich“; fehlende Datei/ungültige Metadaten entsprechend melden. Nur ein bereits veröffentlichter, identitätsgleicher Reader darf über einen nicht öffnenden Peek als aktuell geprüft gelten. Ein Cacheeintrag allein beweist keine Nutzbarkeit heutiger Quelldateien. Parallele Statusaufrufe teilen pro unterstützter Sprache ein Metadaten-Future; keine Polling-/Jobwarteschlange, Invalidierung nach Update/Sprachwechsel. Damit kann Status keinen Readerplatz besetzen.

## 4. Invalidierung, Update und Recovery

| Situation | Verbindliche Reaktion |
|---|---|
| Stabiler aktiver Download, gültiges Journal | Manifest und Bytes binden; Treffer nutzt V/I-Ergebnis, Miss führt V/I einmal aus. Kein vorgeschaltetes `verifyGeneration` zusätzlich. |
| Fehlender Nachweis, LRU-Eviction, App-/Validatorupdate | Vollprüfung; kein gespeichertes Receipt. Andere Vertragsversion ist Miss. |
| Gleiche Größe/mtime, anderer Inhalt oder Inventar | Hashfehler, betroffenen Nachweis entfernen, keinen Reader freigeben; alte nutzbare Auswahl erhalten. |
| Neues korrekt gehashtes Manifest/Profil/Generation | Andere Identität: vollständiger Pfad. Gleichbleibende Release-ID mit widersprüchlichem Angebot bleibt gemäß bestehendem Releasevertrag Fehler. |
| Fehlende Datei, ungültige Hashes oder fachlicher Fehler | Kein Nachweis; kein Asset-Downgrade eines beschädigten aktiven Downloads. Reparaturfehler weiterreichen. |
| Committed-Zeiger widerspricht Journal | Fehler wie bisher, keine Cacheausnahme. |
| Prepared/Next | Cache grundsätzlich ignorieren; Next vollständig auf dem später verwendeten Handle prüfen, danach committen und denselben Reader übernehmen. Nachweis erst nach Commit/Handshake. |
| Prepared/Next ungültig | Kandidat schließen, `restorePrepared`, Vorgänger vollständig prüfen; kein Kandidatennachweis. Bootstrap gegebenenfalls über bestehenden Pfad. |
| Prepared/Previous | Previous vollständig prüfen, Next nicht aktivieren; bisherige Journalbehandlung erhalten. |
| Prepared-Zeiger weder Next noch Previous | Fehler, keine heuristische Auswahl. |
| Pending/.part bei stabilem Active | Nicht aktivieren. Normalen Active-Read zulassen; Updateprüfungen bleiben getrennt. |
| Crash vor/nach Prüfung oder vor Commit | Prozessnachweise weg; Journalzustand entscheidet, Prepared vollständig prüfen/rollbacken, temporäre Reste entsorgen. |
| Packaktivierung / Rollback | Nachweise der betroffenen Sprache bei Prepare/Restore invalidieren; laufende Reader nicht schließen, solange geleast. Erst erfolgreicher neuer Read kann wieder eintragen. |

`installedRead` ersetzt **nie** `verifyGeneration(previous: ...)`, die historischen Identitäts-/Unveränderlichkeitsprüfungen oder `latest`-Freigabe vor Aktivierung. Download, Wiederaufnahme von Pending und Aktivierungsvorprüfung bleiben vollständig. Diese getrennten Transaktionsphasen sind nicht „doppelt innerhalb eines Opens“; der anschließend notwendige Prepared-Read prüft einmal vollständig, nicht zweimal. Kein Übertragen eines bloßen Downloadnachweises auf eine inzwischen austauschbare Datei.

Recovery mit geändertem Owner-Key meldet `RecoveredGenerationChanged`, räumt den alten Versuch auf und lässt den Provider genau einmal den aktuellen Schlüssel neu auflösen, sofern Epoch/Sprache passen. Zweite Änderung: abbrechen. Alter Reader bleibt bis Lease-Ende nutzbar. UI-Übung hält das vorhandene Gate; eine direkte Repository-Übung darf ihre historische Generation weiter lesen, ohne dass ihr Reader durch LRU-Eviction oder Aktivierung ersetzt wird. Update-`openReaders` muss neuen Key/Scope aufbauen, bevor alte pausierte Owner wieder freigegeben werden.

## 5. Zwei Umsetzungspakete nach Abnahme

Die folgenden Schnittstellen sind inzwischen umgesetzt; tatsächliche Signaturen und Integration stehen in [Paket 1](content-validation-package-1.md) und [Paket 2](content-validation-package-2.md). Kein unlösbarer Vertragskonflikt im gelesenen Code; der heutige Pfad-/Void-Rückgabevertrag transportiert allerdings keinen sicheren Nachweis und muss für den neuen Read-Pfad ergänzt werden.

### Paket 1: Einmaliger Validator und begrenzter Prozessnachweis

- Neu `lib/data/content/content_validation_session.dart`: `GenerationIdentity`, `validationContractVersion`, `InstalledReadRequest(identity, journalSnapshot, sourcePaths, mode)` mit Modi `normalInstalled`/`recoveryFull`; privater `InstalledReadProof`; `ProcessValidationRegistry` mit zwei LRU-Einträgen, drei Readerreservierungen und idempotentem Cleanup. `openBoundReader(request)` wird produktiv ausschließlich über die Owner-Factory verwendet und liefert einen einmal konsumierbaren `BoundReader` mit Identität, ContentInfo, Drift-Endpunkt und Close. Interne Nachrichten zwischen Koordinator und Drift-Worker sind DTOs; kein SQLite-Handle wird gesendet. Der Worker bekommt einen passenden internen RAM-Proof nur für normalInstalled; Full-Erfolg wird als internes Ergebnis zurückgemeldet, erst nach finaler Veröffentlichung in den LRU aufgenommen.
- `lib/data/content/content_update_validation.dart`: `ContentInfo validateDownloadedDatabase(Database db, ReleaseOffer offer, Map<String,dynamic> inventory, {String? previousPath})` aus bestehendem Vollvalidator extrahieren. Übergebenen Handle nicht schließen; genau ein `validateContentSchema`. Bestehender `validateDownloadedContent` bleibt vollständig prüfender Wrapper mit eigener Handle-Verantwortung und unveränderten Historienregeln.
- `lib/data/content/content_database.dart`: `ContentDatabase.fromBoundReader` konsumiert den internen Endpunkt, übernimmt dessen Cleanup. Bestehenden Drift-Workermechanismus verwenden; kein vorgeschalteter zweiter Validierungsworker. Öffentliche Legacy-/Bootstrap-/Tool-Opener bleiben vollständig prüfend ohne Skip-Parameter.
- Neu `test/data/content_validation_session_test.dart`: Vollprüf- und Hashzähler, gleiche Bytes, Hit/Miss, Manipulation, Single-flight, Abbruch, LRU/Slot/Cleanup und Workerfehler mit synthetischen Fixtures. Das neue API ist erst mit Paket 2 produktiv erreichbar.

### Paket 2: Read-/Recovery-Pfade und Status integrieren, Wirkung prüfen

- `lib/data/content/content_update_service.dart`: `resolveInstalledState(journal)` klassifiziert Metadaten ohne Validierungsbehauptung; `openRecoveredContent` setzt Tabelle oben mit BoundReader um. Legacy `recoverContentInstallation`/`verifyGeneration` bleiben vollständig für bestehende Aufrufer/Tests. Download-/Aktivierungshistorie und Freigabe nicht ändern.
- `lib/data/content/content_pack_installer.dart`: Download-`open` verwendet den neuen Ablauf direkt, nicht erst `install → recover → verify` und danach `openInBackground`. Dateivertrag `install` und Bootstrap-Verhalten bleiben erhalten. `readInstallationMetadata` stellt Status ohne Öffnung/Recovery bereit.
- `lib/presentation/providers/database_providers.dart`: vollständigen Manifest-/Vertragsfingerprint in Download-Owner-Schlüssel aufnehmen; `activeContentKeyProvider`/`contentKeyFor` identisch auflösen, tatsächliche Byteprüfung erst beim Open. Single-flight über vorhandenen `RepositoryOwner` erhalten, Null-Lease-Close und Registryentfernung koordinieren, drei Aufnahmeplätze einschließlich Legacy-Reader durchsetzen. Keine permanente Lease zum Warmhalten. Einmaliger Recovery-Retry; alle Key-Aufrufer und Tests entsprechend typisieren.
- `lib/presentation/providers/language_selection_provider.dart`: Status auf Metadaten/Peek umstellen; Ziel-Lease, Gate, Epoch, alte Sprache und Rollback erhalten. `lib/presentation/providers/content_update_provider.dart`: Key-Neuaufbau vor Resume, sprachbezogene Proofinvalidierung bei Prepare/Restore und keine veraltete Ergebnisveröffentlichung. `content_install_journal.dart`/`content_release_client.dart` bleiben Vertragsreferenzen; keine Formatänderung.
- Tests erweitern: `test/data/content_update_test.dart`, `test/data/content_owner_barrier_test.dart`, `test/content_loading_performance_test.dart`, `test/language_update_lifecycle_test.dart`, `test/language_selection_test.dart`. Danach Messbericht/Plan/NEXTSTEPS aktualisieren.

### Verbindliche Regressionen und Messabnahme

| Test | Erwartung |
|---|---|
| Vollprüfung → Close → gleicher Pack | Erstes Open V/I genau einmal; zweites V/I null, beide Hashes erneut, quick_check/Release vorhanden; gleiche fachliche Ergebnisse. |
| Parallele gleiche Identität | Eine Copy/Vollprüfung/Verbindung; alle Leases gleiches Ergebnis, Close erst beim letzten Lease. |
| Eine/alle Anfragen abgebrochen; Fehler vor Connect | Ein verbliebener gültiger Interessent kann fertig werden; ohne Interessenten kein neuer Proof. Fehler/Teilerfolg ohne Eintrag; Slots nach Close frei. |
| Dateiwechsel gleicher Größe/mtime, Copy/Hash/Open-Rennen | Nur erwartete Snapshotbytes werden gelesen oder sauberer Fehler; niemals ungeprüfte Ersatzbytes. |
| Inventar-/Manifest-/Profil-/Vertragsänderung | Kein Hit; korrekt neu gehashter, fachlich defekter Pack scheitert am Vollvalidator. |
| Appneustart, fehlender Proof, dritte LRU-Identität | Vollprüfung; Eviction verändert gehaltene Reader nicht. |
| Viele Statusaufrufe während en→pt-BR→en | Null zusätzliche Reader/Vollprüfungen; keine Belegung durch Status; ehrliche ungeprüfte Anzeige. |
| Aktuell + alter Reader + neues Ziel | Dritter Platz ermöglicht Ziel; vierter echter Reader kontrolliert abgewiesen, keine Zwangsschließung und keine Warteschlange. |
| Schnelle Wechsel, spätes Ergebnis, Closefehler | Gate/Key/Epoch verhindern Vermischung; saubere Abbrüche/Barrieren, keine Hintergrund-Wiederöffnung. |
| Alle Journalzustände, Crashpunkte, Aktivierung trotz vorhandenem Read-Proof | Recovery vollständig; Vorgängerprüfung und erneute Freigabe aufgerufen; Commit erst nach Erfolg, Rollback/alte Historien erhalten. |
| Alte Übung mit Lease, Proofeviction/anderer Pack | Alte Daten/Revisionsreferenzen bleiben lesbar; UI-Practice-Gate unverändert. Keine Reviews echter Lernstände. |
| Fehlende Datei, voller Speicher, Legacy/Bootstrap | Fehler ohne unsicheren Fallback; keine Leaks; Schema-1–4-Verträge unverändert. |

Spätere Implementierungsprüfung: gezielte Tests, `flutter test --no-pub`, `flutter test --no-pub test/data/real_pack_test.dart`, `flutter analyze --no-pub`, `dart run tool/stage_content_pack.dart --verify`, CRLF-konformer Diffcheck; 30-s-Packtestbudget unverändert, bestehendes avoid_print separat. Befehle auf Windows (PowerShell) und macOS (Terminal) identisch.

Erst nach Umsetzung gezielte Profile-Frage am bekannten iPhone: Wie groß sind C und warme Packbereit-Zeit bei echtem Schema-5-Pack? Unter gleichen Bedingungen separater Prozessneustart, erste Prüfung, drei warme en→pt-BR→en-Wechsel, jeweils nutzbarer Home-Frame und erste Übung ohne Antwort. Hash/Copy/V/I/Worker/Packbereit/Home/Übung sowie Peak-Reader und Temp-Speicher getrennt protokollieren. Keine Überschriftenzeit als Home-Abnahme; manuelle Pausen getrennt ausweisen. Update/Crash mit synthetischen Fixtures, keine Änderung echter Lernstände. Zielerreichung erst nach Messung; Home-Restposten außerhalb dieses Plans.

## 6. Dokumentationsprüfung und Abnahme

Codeabgleich auf `e3580c3`: GitNexus query/context für Recovery/Opener/Status, anschließend direkte Funktionskörper gelesen; Graph bildet Dart-Körper teilweise nur einzeilig ab. Index aktualisiert (`analyze --index-only`, Exit 0). Dokument-Impact jeweils UNKNOWN, keine auflösbaren Aufrufer/Prozesse; nicht als Unbenutztheit gewertet. Textreferenzen in NEXTSTEPS und AGENTS/CLAUDE berücksichtigt. Produktcode und Messbericht unverändert.

Ausgeführt für diese Revision: `git -c core.whitespace=cr-at-eol diff --check` ohne Befund (Exit 0); relative Linkprüfung 10/10, NEXTSTEPS 25 Zeilen und durchgehend CRLF (Exit 0). `detect_changes(scope: all, limit: 5000)` meldet zwei Dateien, 16/16 Symbole, null betroffene Prozesse, LOW, `partial:false`, `truncated:false` (Exit 0; `/private/tmp/validation-b-graph.json`). Das bewertet die Dokumentänderung, nicht die noch ausstehende Implementierung. Keine Testsuite oder Live-Messung ausgeführt.

**Ursprünglicher Abnahmegegenstand (inzwischen ausdrücklich beauftragt und umgesetzt):** Variante B mit zwei Prozessnachweisen, erneuter Bytebindung je neuem Reader, einmaliger Vollprüfung bei Miss/Recovery, metadatenbasiertem Status und begrenztem Reader-Lifecycle in genau zwei Paketen. Paket 1 und 2 sind umgesetzt; persistente Receipts und zusätzliche Home-Optimierung bleiben ausgeschlossen. Die Dokumentationsprüfung oben beschreibt die frühere Planrevision; aktuelle Tests, Graphprüfung und Gerätedaten stehen im Paket-2-Nachweis.
