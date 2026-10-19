# Plan: Lebenszyklus der Inhaltsvalidierung

Stand: 19.10.2026. **Zur Abnahme, nicht implementiert.** Basis `0e2f890c48891d7512712a0b8ba1d8c2599d6724`, sauberer Worktree `/Users/ardasayar/.codex/worktrees/batch-content-queries/sprachapp`. Dieser Auftrag ändert ausschließlich diesen Plan und eine Statuszeile in `NEXTSTEPS.md`.

## Empfehlung und erwartbare Wirkung

**Nur A umsetzen:** innerhalb eines einzelnen Öffnungsvorgangs einmal vollständig prüfen und genau die dabei verwendete Verbindung weiterverwenden. Keine Wiederverwendung über geschlossene Reader oder Appstarts hinweg, kein Validierungsnachweis auf Platte. Der konkrete Bytevertrag verwendet eine private, kurzlebige Arbeitskopie und denselben SQLite-Handle im selben Worker-Isolate. Das ist ein temporärer Lesesnapshot, kein Cache: nach dem letzten Lease wird er geschlossen und gelöscht, niemals anhand eines früheren Prüfstatus erneut geöffnet.

Damit entfällt die zweite Vollvalidierung beim normalen Öffnen eines Downloadpacks. Der vollständige Inventarabgleich bleibt einmal je Öffnung erhalten. A ist die kleinste hier belastbar spezifizierbare Variante ohne neues persistentes Vertrauen. Sie löst **nicht** alle Wiederholungen zwischen Sprachwechseln. B wäre eine spätere, gesonderte Entscheidung; C wird nicht empfohlen. Es werden nicht drei Varianten kombiniert.

Gesicherte Gerätebasis aus dem [Messbericht](content-loading-performance.md), letzter Nachtrag: Schema 5, `chitchat_de_korrektur_v1`, 43 089 920 Byte SQLite plus 10 353 596 Byte Inventar; kein Vergleich mit dem 26 198 016 Byte großen Schema-4-Bootstrap. Median aus drei Wechseln: `selectLanguage` 4 989 ms. Home danach ca. 1 294 ms bis zum Frame und erste Übung 62 ms sind jeweils Einzelmessungen nach dem dritten Durchgang.

**Schätzung, kein neues Messergebnis:** zweite Vollvalidierung ca. 1 327 ms; darin Formen und Kontextrevisionen je einmal. A kann diesen Block vermeiden. Konservativ: `4 989 − 1 327 + C ≈ 3 662 ms + C` bis Pack/Sprachwechsel bereit. `C` ist die noch unbekannte Nettoänderung durch Arbeitskopie, Worker und Handshake; Hashen wird nicht ersatzlos gestrichen. Der zusätzliche Drift-quick_check von ca. 28 ms bleibt als Verteidigungsschicht erhalten und wird nicht als Einsparung gerechnet. Gleicher SQLite-Handle könnte IO/Cacheverhalten ändern, deshalb ist auch die Subtraktion nur eine Planungsgröße.

Home vollständig nutzbar wäre bei unveränderten Home-Kosten grob `3 662 + 1 294 + C ≈ 4 956 ms + C`, ohne manuelle Navigationspause. Das ist **keine** gemessene Ende-zu-Ende-Zeit. Selbst sofortiges Packbereit würde die derzeitigen 1,29 s Home-Arbeit nicht beseitigen. Weder für A noch für B/C wird das Ein-Sekunden-Ziel für die vollständige Home zugesagt.

## 1. Codebelege und heutiger Lebenszyklus

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
| Bootstrap | Pinned-Manifest und Asset-Bytes; keine Schema-5-Downloadinventare erfinden | Bestehender Bootstrap: Hash + `V` + Drift-quick_check. Erstinstallation prüft Kandidat vor Rename und später nochmals beim Öffnen. A lässt diesen bestehenden Pfad zunächst unverändert. |

### Warum die Doppelprüfung besteht

`recoverContentInstallation` vereint Zustandsreparatur **und** Verifikation eines normalen aktiven Packs. Der `else if (active != null)`-Zweig ist keine Crash-Recovery, führt aber absichtlich dieselben lokalen Integritäts-/Inhaltsprüfungen aus. Das schützt vor fehlenden oder beschädigten installierten Daten ohne Asset-Fallback. `verifyGeneration` verwirft den geprüften Handle und `ContentInfo`; der Installer gibt nur einen Pfad zurück. `openInBackground` muss deshalb aus seiner heutigen Sicht selbst prüfen. Sein späterer Kommentar über hashgeprüfte unveränderliche Bytes ist kein typisierter Nachweis und verbindet die drei Handles nicht miteinander.

Nicht redundant sind Transport-/Manifestbindung, Prüfung einer seit dem Download möglicherweise beschädigten Generation vor Aktivierung, Vorgängerkompatibilität bei Packupdates, Journal-Konsistenz und das Prüfen eines bislang ungeprüften Inhalts. Redundant innerhalb **eines** normalen Opens ist die zweite semantische Vollprüfung identischer Bytes. Ein anderer Pfad mit gleicher Version oder Dateigröße ist nicht dasselbe Prüfergebnis.

## 2. Vergleich A / B / C

| | A: einmaliges Open-Ergebnis | B: begrenzter Prozessnachweis | C: persistenter Nachweis |
|---|---|---|---|
| Reichweite | Nur der konkrete Öffnungsvorgang/Reader | Wiederöffnen derselben Generation innerhalb desselben Prozesses | Auch Appneustarts |
| Konkrete sichere Ausprägung | Private Arbeitskopie, ein validierter SQLite-Handle, Weitergabe an Drift | Maximal zwei LRU-Nachweise über vollständig geprüfte Hash-Tupel; keine zusätzliche dauerhaft offene Verbindung. Bei jedem neuen Open Bytes erneut an Hashes binden, z. B. gleicher Snapshotmechanismus wie A. | Versionierter, authentisierter Nachweis über dasselbe Tupel; mindestens MAC mit app-/installationsgebundenem sicher gespeichertem Schlüssel. Kein frei editierbares JSON-Flag als Autorität. |
| Verbleibende Prüfungen | Bei jedem neuen Open Hashes, Manifest/Profil, quick_check, ein `V + I`, Journal; Updates/Recovery zusätzlich wie unten | Cache-Miss wie A; Hit weiterhin Journal, Profil/Version, beide Datei-Hashes und quick_check/Release der neuen Verbindung; `V + I` nur bei identischen Bytes/Validator nicht erneut | Wie B auf gültigem Nachweis; zusätzlich Echtheit, Nachweisformat/-version, Schlüsselverfügbarkeit; Miss/Fehler volle Prüfung |
| Kaltstart | Wie normaler Open, nur zweite `V` entfällt | Miss: wie A | Kann `V + I` vermeiden; Hashen bleibt |
| Warmer Sprachwechsel | Schätzung ca. 1,33 s vermeidbar minus neue Kopier-/Handshakekosten | Zusätzlich grob die verbleibenden ca. 2,8 s aus einer `V`, Inventarzeilen und kanonischem Inventarvergleich vermeidbar; Hash/IO/quick_check bleiben. Kein gemessenes <1-s-Ergebnis. | Warm ähnlich B, kein zusätzlicher Warmvorteil gegenüber B |
| Packupdate / Crash | Neue oder wiederherzustellende Generation vollständig prüfen; keine Übernahme eines früheren Tokens | Miss bei neuer Identität; Prepared/Recovery grundsätzlich voller Pfad, unabhängig vom LRU | Neue/unsichere/Prepared-Generation voller Pfad; erst nach erfolgreichem Commit neuen Nachweis atomar speichern |
| Speicher / Komplexität | Ein Worker/Handle und temporäre Kopie je belegtem Slot, keine persistente Vertrauensdatenbank; mittlere Komplexität | A plus zwei kleine Metadateneinträge, LRU, Single-flight und Invalidierung; mittlere bis höhere Komplexität | A plus kleines Receipt je aktiver Sprache, Keystore/Backup-/Neuinstallations-/Versionsregeln; höchste Komplexität |
| Empfehlung | **Jetzt zur Abnahme** | Nicht Teil der Umsetzung; erst nach Bewertung von A | Nicht Teil der Umsetzung; Aufwand und neue Vertrauensfläche derzeit nicht gerechtfertigt |

Die B/C-Zeitgrößen stammen aus bestehenden Teilmessungen, nicht aus implementierten Lösungen. Sie dürfen weder mit der A-Einsparung doppelt verrechnet noch als zukünftige Mediane ausgegeben werden. Hashen allein plus Home läge schon grob bei 0,54 + 1,29 s, noch ohne andere Arbeit.

## 3. Verbindlicher Byte-, Versions- und Fehlervertrag

### Identität für jede erwogene Wiederverwendung

Unveränderliches `GenerationIdentity`-Tupel: Sprache, Release-ID, Generation, Release-Version, Schema, Manifestformat und kanonischer Manifesthash, Reader-/Featurevertrag, Sprachprofil-ID/-hash, Inhaltsdatei-SHA-256 und Bytezahl, **Inventardatei-Bytehash und Bytezahl** aus `objects`, **kanonischer Inventarhash** aus dem Manifest, `validationContractVersion`. Bei Prüfungen gegen einen Vorgänger zusätzlich dessen vollständige Identität und Prüfumfang `activationWithHistory`; normales Öffnen trägt `installedRead`. Ein Read-Nachweis darf keine Vorgängerprüfung oder Serverfreigabe ersetzen.

`validationContractVersion = 1` als neue interne Konstante, nicht identisch mit Content-Schema 5. Erhöhen bei semantischen Änderungen an Pflichtschema, Satz-/Gruppen-/Form-/Kontext-/Historienprüfung, Normalisierung/Kanonisierung oder erlaubten SQL-Objekten. A/B leben nur innerhalb des laufenden Binaries; Neustart verwirft alle Ergebnisse ohnehin. C müsste zusätzlich jede Änderung der App-Buildkennung als Miss behandeln, auch bei versehentlich nicht erhöhter Vertragsversion. Profil-/Featureänderungen invalidieren alle Varianten. Unterbrochenes Appupdate kann keinen Reader über Prozessgrenzen tragen.

### A: exakte Bytebindung ohne persistentes Vertrauen

1. Angebot/Journalsnapshot aus bekannten Journalpfaden lesen, mit `ReleaseOffer.parse` prüfen und in unveränderliche DTOs kopieren (auch verschachtelte Objektbeschreibungen; kein bloß flach unveränderliches Map). Inhaltspfad nur aus geprüftem Release-ID/Sprachpfad ableiten.
2. Im Worker einen neuen privaten Ordner unter App-Support `content-readers/<processNonce>/<openNonce>/` exklusiv erstellen. Kein Verzeichnis aus einem früheren Prozess oder Open wiederverwenden. Inhaltsdatei begrenzt streamend kopieren, bei Überschreitung der vereinbarten Größe abbrechen, flushen und Writer schließen. **Die fertige Arbeitskopie** hashen und gegen den Inhaltsdeskriptor prüfen; nicht nur die gelesene Quelle hashen. Inventar einmal begrenzt in private Bytes lesen, deren Bytehash prüfen; genau diese Bytes decodieren und im gemeinsamen Validierungskern genau einmal kanonisch hashen und vergleichen. Kein erneutes Lesen des Inventarpfads für die fachliche Prüfung.
3. Arbeitskopie `OpenMode.readOnly`, `PRAGMA query_only=ON` öffnen. Erlaubte Tabellen/Indexe, quick_check, Manifest/Release, alle Inhaltsvalidatoren und alle Inventarzeilen auf **diesem** Handle prüfen. Keine live genutzte SQLite-Instanz zwischen Isolates senden: derselbe Worker hostet danach Drift auf `NativeDatabase.opened(raw, enableMigrations:false)`.
4. Nur nach vollständigem Erfolg Handle für genau einen Drift-Client freigeben; vorhandenen zusätzlichen quick_check/Release-Abgleich auf demselben Handle beibehalten. `ContentInfo` über einen separaten Erfolgshandshake liefern; erstes SELECT und Handshake müssen beide erfolgreich sein, bevor ein Repository sichtbar wird. Keine öffentliche API `skipValidation:true` und kein Konstruktor, der fremdes `ContentInfo` als Nachweis annimmt.
5. Vor Veröffentlichung Journal-/Aktivzeiger erneut lesen und gegen den erfassten Zustand bzw. den kontrollierten Recovery-Abschluss vergleichen. Bei fremdem Wechsel Ergebnis schließen/verwerfen. Ein Fehler schreibt keine neue Sprachauswahl. Journalzustand/Generation müssen außerdem zum anfordernden Owner passen; `(lang,generation)` allein bleibt kein Vertrauensschlüssel.
6. Letzter Lease: Drift schließen, Worker beenden, dann private Kopie löschen; idempotentes Cleanup auch nach fehlgeschlagenem Connect/Validieren. Schließen fehlgeschlagen: bestehende Owner-Sperre beibehalten, keine Datei unter einem noch nutzbaren Handle löschen. Nächster Prozess entfernt ausschließlich alte `content-readers`-Arbeitsordner, nie Generationen/Journale. Ein Crashrest ist niemals ein Prüfnachweis.

Die private Kopie ist nötig, weil ein Hash vom Quellpfad und ein späteres SQLite-Open desselben Pfades keinen identischen Dateiinhalt garantieren. Ein offener SQLite-Handle allein löst die Bindung an einen separat gehashten Pfad ebenfalls nicht. Das vorhandene sqlite3-API bietet `open`/`copyIntoMemory`; ein ungesicherter Pfad-zu-Handle-Hashbeweis wird hier nicht vorausgesetzt. Keine neue native Abhängigkeit erforderlich.

Dateiaustausch an der **Quelle** während des Kopierens: erzeugte Kopie muss exakt den vereinbarten Hash haben, sonst Fehler. Austausch nach Fertigstellung kann keinen neuen Inhalt in den geprüften Reader einschleusen; er liest seinen Snapshot. Die nächste Öffnung prüft die Quelle neu und weist Beschädigung zurück. Bereits validierte laufende Reader dürfen ihren alten Snapshot weiterverwenden – kein Versprechen ständiger Hintergrundprüfung der Quelle. Fehlende Quelle beim Öffnungsbeginn ist Fehler, kein Nachweis-Hit; ein bereits belegter Reader ist davon unabhängig. Änderung des aktiven Zeigers wird durch die Abschlussprüfung verworfen. Private Arbeitskopien dürfen von keinem App-Code verändert werden; Schreibversuch muss scheitern.

### Schutzgrenzen, B/C und Ressourcen

- Heute schützen App-Sandbox, authentifizierter Download/Freigabe, Manifest-/Bytehashes, unverändert behandelte Generationsdateien, atomare Journalzeiger, Gate und Reader-Ownership. Ein lokal neu berechneter Manifesthash ist keine kryptographische Herausgebersignatur. Schutz vor vollständig kompromittiertem OS/App-Prozess oder manipuliertem Validator wird nicht behauptet.
- A vertraut keinen auf Platte gespeicherten Validierungsergebnissen. B vertraut nur prozesslokalen, ausschließlich nach Vollprüfung erzeugten Einträgen. Jeder erneute Read bindet seine aktuellen Bytes erneut an das Tupel; Pfad, Größe und mtime sind niemals ein Trefferkriterium ohne Hash. Löschen/Beschädigung/anderer Hash, Profil-/Vertragswechsel oder falscher Prüfumfang bedeutet Miss bzw. Fehler, kein stilles Downgrade.
- C müsste zusätzlich Receipt-MAC, Keystore-Schlüssel und App-/Vertragsversion prüfen. Fehlender/falscher Nachweis, Restore auf anderes Gerät, Schlüsselverlust oder Appupdate: volle Prüfung und erst danach Receipt ersetzen. Keine MAC-Freigabe für neue Downloads/Prepared-Zustände; kein Receipt-Write vor Commit. Auch C kann auf kompromittiertem Gerät keine absolute Manipulationssicherheit geben.
- A konkret: maximal **zwei** gleichzeitige Snapshot-Worker im Prozess (aktiver Reader plus Ziel-/Statusreader), keine ungeleasten warmen Reader. Mehrbedarf wird vor Allokation als „Inhaltsansichten belegt“ abgewiesen, nicht durch Schließen eines belegten Readers oder unbegrenztes Warten gelöst. Derselbe Owner teilt vorhandene Leases. Fehler-/Abbruchpfade geben die Reservierung nach sicherem Close frei. Die bestehende Update-Vorprüfung bleibt im separaten bisherigen Prüfpfad, ohne Snapshot-Reservierung.
- Kopierbuffer höchstens 64 KiB; SQLite-Kopie höchstens bestehendes `maxContentDownloadBytes` (256 MiB) je Slot. Aktueller englischer Pack benötigt ca. 43,1 MB zusätzlichen temporären Speicher je Reader, maximal 512 MiB für zwei zulässige Maximalpacks. Inventarbytes/-JSON und Validatorstrukturen bleiben temporärer RAM-Aufwand; keine harte RSS-Garantie, kein Ganzpack-Bytearray auf dem UI-Isolate. Speicher-/Platzfehler schließen das Ziel sauber und lassen den alten Reader bestehen. Keine automatische Reduktion der Prüfungen bei Platzmangel.
- B als Vergleich: zusätzlich höchstens zwei kleine LRU-Identitätsnachweise, keine gecachten Inhalte oder SQLite-Verbindungen; Eviction erzwingt Vollprüfung beim nächsten Open und beeinflusst laufende Leases nicht. C: höchstens ein aktueller Receipt pro unterstützter Sprache; ersetzte Receipts werden nicht zu einer unbegrenzten Historie.

## 4. Normaler Open und Recovery getrennt

Die logische Klassifikation wird vom teuren Öffnen getrennt, nicht die Prüfung entfernt:

| Journal-/Zeigerzustand | Vorgeschriebener Ablauf von A |
|---|---|
| Gültig committed / recovered / kein Installationsjournal, aktive Downloadgeneration | Konsistenz prüfen; einmal `openValidatedGeneration`; kein Commit/Restore und kein zusätzliches `verifyGeneration` davor. |
| committed widerspricht aktivem Manifest | Fehler wie heute, weder Asset-Fallback noch neues Commit. |
| prepared, aktiver Zeiger entspricht next | Next einmal vollständig im Snapshot öffnen. Erst nach Erfolg Journal committen; exakt diesen Reader zurückgeben. Kein erneutes Öffnen nach Commit. |
| prepared/next, Kandidat ungültig | Kandidat schließen/aufräumen, `restorePrepared`; Vorgänger frisch vollständig öffnen (oder bestehenden Bootstrappfad), dessen Fehler weiterreichen. Keine Wiederverwendung des Kandidatenergebnisses. |
| prepared, Zeiger entspricht previous | Vorherige Generation vollständig öffnen; keine Aktivierung von next. Bestehende Journalbehandlung erhalten, kein erfundener Erfolg für next. |
| prepared, Zeiger entspricht weder previous noch next | Fehler; keine heuristische Auswahl anhand Dateigröße/Version. |
| pending oder `.part`, active unverändert | Aktiven Pack normal öffnen; Pending/Teilpaket nicht still aktivieren. Download-/Aktivierungsvorprüfung bleibt bestehen. |
| Absturz während Snapshotprüfung | Kein veröffentlichter Reader und kein Receipt; nach Neustart volle Prüfung, Arbeitsreste entsorgen. |
| Absturz nach erfolgreicher Next-Prüfung, vor Commit | Prepared/Next beim Neustart erneut vollständig prüfen. Prozesslokaler Erfolg darf keinen Neustart überleben. |

Wird bei Recovery auf eine andere Generation zurückgestellt, darf ein Reader nicht unter dem zuvor angefragten Owner-Key veröffentlicht werden. Festgelegtes Verhalten: `RecoveredGenerationChanged` mit neuer Identität nach sicherem Cleanup; Provider bzw. Sprachwechsel-Helfer liest Key neu und versucht **genau einmal** erneut, sofern Sprache/Epoch noch passen. Zweite Änderung oder unpassende Sprache: abbrechen, alte nutzbare Sprache erhalten. Das ist kein unbeschränkter Retry und kein Cache-Hit. Der zusätzliche Vollprüflauf ist nur dieser Recovery-Randfall, nicht der Normalpfad.

Laufende Übungen: Das heutige `ContentTransitionGate` blockiert Sprachwechsel/Aktivierung bei Practice-Lease. A ändert diese Produktregel nicht und ermöglicht keinen erzwungenen Wechsel mitten in einer Übung. Auf Repository-Ebene bleiben bereits belegte alte Reader/Snapshots bis zum letzten Lease nutzbar. Zielprüfung schlägt fehl, während alte Übung läuft: keine vorzeitige Schließung, kein Umschreiben der Reviewreferenz. Verspätete Zielergebnisse werden bei veralteter Sprache/Generation/Epoch geschlossen, nie veröffentlicht.

## 5. Umsetzung in höchstens zwei Schritten

Die folgenden Schnittstellen sind **Vorschläge für die abgenommene Umsetzung**, heute nicht vorhanden. Keine spätere Auswahl zwischen A/B/C innerhalb dieser Schritte.

### Schritt 1 – Gebundenen Open auf derselben Verbindung bereitstellen

Dateien und exakte Zuständigkeiten:

- Neu `lib/data/content/content_validation_session.dart`: `const validationContractVersion = 1`; unveränderliche `GenerationIdentity`, `InstalledReadRequest` (Identität, überprüfte Quellpfade, Journalsnapshot); privater Snapshot-/Slot-Lebenszyklus. `Future<ValidatedReader> openValidatedGeneration(InstalledReadRequest request)` erzeugt ausschließlich nach kompletter Prüfung einen konsumierbaren Reader. `ValidatedReader` liefert `ContentInfo`, Identität und einen einmalig beanspruchbaren Drift-Verbindungsendpunkt, plus idempotentes `close`; Konstruktion nur innerhalb dieser Bibliothek. Kein extern konstruierbarer „validated“-Token.
- `lib/data/content/content_update_validation.dart`: bestehenden Prüfcode in `ContentInfo validateDownloadedDatabase(Database db, ReleaseOffer offer, Map<String,dynamic> inventory, {String? previousPath})` extrahieren; dieser Kern schließt **nicht** den übergebenen Handle. Bestehendes `validateDownloadedContent(path, offerJson, previousPath)` bleibt als vollständiger Wrapper für Download-/Aktivierungsprüfungen erhalten und besitzt/öffnet/schließt seinen eigenen Handle. Keine inhaltliche Lockerung von `_matchesInventory`, SQL-Allowlist oder Historienprüfung; genau ein `validateContentSchema` im Kern.
- `lib/data/content/content_database.dart`: `ContentDatabase.fromValidatedReader(ValidatedReader reader)` als Adapter ergänzen: den nur intern erzeugbaren Reader genau einmal konsumieren, Identität/Vertragsversion prüfen und Worker-Endpunkt samt Cleanup übernehmen. Kein zweites `Isolate.run` und kein zweites SQLite-Open für A. `openInBackground(File, lang)` bleibt ein voll prüfender öffentlicher Legacy-/Bootstrap-Opener, keine optionalen Bypass-Parameter. `ContentDatabase.open` für Tools unverändert. Fehler im Handshake/ersten SELECT beendet Worker und löscht Snapshot nach Close.
- Neu `test/data/content_validation_session_test.dart`: Bytebindung, Worker-Ownership, Fehler und Prüfaufrufzahlen ohne Millisekundengrenzen. Bestehende Validator-/Manipulationsfixtures direkt wiederverwenden.

Abschluss dieses Schritts: neuer Pfad noch nicht im App-Standard verdrahtet; gültige Generation wird auf demselben Handle vollständig geprüft und gelesen, alle manipulierten Varianten werden wie zuvor abgewiesen. Keine B/C-Caches, keine neuen Abhängigkeiten, kein Trust-Receipt.

### Schritt 2 – Installer/Recovery integrieren und Wirkung nachweisen

- `lib/data/content/content_update_service.dart`: Journalentscheidung in `resolveInstalledState(journal)` aufteilen (keine Aussage „validiert“), und neuen `openRecoveredContent(journal)`-Ablauf gemäß Zustandstabelle bereitstellen. Bestehende `verifyGeneration` und der öffentliche `recoverContentInstallation`-Prüfvertrag für sonstige Aufrufer/Tests bleiben vollständig prüfend. Der neue normale Read-Pfad ruft sie nicht zusätzlich auf; Prepared/Next wird erst nach Erfolg desselben Snapshot-Readers committed. `download`, `check` und Aktivierungsvorprüfung behalten ihre Freigabe-/Historienprüfungen.
- `lib/data/content/content_pack_installer.dart`: `open()` für aktive Downloadgenerationen zu `openRecoveredContent` führen und **dessen** Reader übernehmen. Nicht erst `install()` inklusive `recover…` aufrufen und anschließend neu öffnen. `install()` als Dateivertrag für andere Aufrufer und vorhandene Bootstrapinstallation erhalten. Für Bootstrap/fehlende Installation auf bisherigen vollständigen Pfad verzweigen; kein stiller Asset-Fallback nach einem Downloadfehler.
- `lib/presentation/providers/database_providers.dart`: Factory nimmt gebundenen Reader unter dem passenden Owner-Key auf; einmalige Key-Neuauflösung bei `RecoveredGenerationChanged`, klare Reservierungs-/Cleanup-Verantwortung. Bestehendes Close/Pause/Lease-Verhalten und keine Wiederöffnung veralteter Scopes beibehalten; keine dauerhafte zusätzliche Lease als versteckter Cache.
- `lib/presentation/providers/language_selection_provider.dart`: Ziel-Lease über denselben eng begrenzten Recovery-Retry beziehen, Epoch/Key vor Persistierung prüfen; sonst bestehende Gate-/Rollback-Reihenfolge unverändert. `lib/presentation/providers/content_update_provider.dart`: `openReaders` muss Recovery-Keywechsel berücksichtigen und alten Owner nicht versehentlich wiederöffnen; kein zusätzlicher Vollvalidator nach erfolgreichem A-Open.
- Tests erweitern: `test/data/content_update_test.dart`, `test/data/content_owner_barrier_test.dart`, `test/content_loading_performance_test.dart`, `test/language_update_lifecycle_test.dart`, `test/language_selection_test.dart`. Doku: diesen Plan als umgesetzt/abgewichen markieren, Messbericht und NEXTSTEPS aktualisieren. `content_install_journal.dart` und `content_release_client.dart` sind Vertragsreferenzen; Journalformat, Releaseformat, Packs und user.db nicht ändern.

### Abnahmetests der späteren Umsetzung

| Fall | Verlangter Nachweis |
|---|---|
| Gültiger Schema-5-Download | Ein Satz-/Gruppen-/Form-/Kontext-/Inventarlauf pro normalem Open, dieselbe SQLite-Verbindung danach nutzbar; zusätzlicher quick_check bleibt. |
| Manipulierte SQLite-/Inventarbytes bei gleicher Größe/mtime | Hashfehler; keine Freigabe aufgrund Dateiname/Metadaten; alte Sprache unverändert. |
| Inhalt fachlich ungültig, aber passende neue Hashes | Vollvalidator weist Fehler weiterhin ab. Lokaler Hash ist kein Ersatz für Inhaltsprüfung. |
| Quelle zwischen Copy/Hash/SQLite-Open austauschen | Nie ungeprüfte neue Bytes lesen: falsche Kopie scheitert, nach erfolgreicher Kopie wird ausschließlich der geprüfte Snapshot gelesen. |
| Snapshot-Schreibversuch, Fehler nach Validation vor Connect | Read-only erzwingt Fehler bzw. Handshakefehler schließt Handle, Worker und Kopie genau einmal. |
| Manifest-/Inventarhash/Profile/Schema/Validatorversion geändert | Identität nicht kompatibel; kein alter Reader als neues Ergebnis. Appneustart erzeugt volle Prüfung. Fehlender Nachweis ist bei A immer Normalfall, niemals Grund zum Überspringen. |
| Alle Prepared-/Committed-/Previous-Kombinationen und Crashpunkte | Zustandstabelle, Commit nur nach Erfolg, Rollback bewahrt Historie; kein Bootstrap-Downgrade eines beschädigten aktiven Downloads. |
| Volles Dateisystem / fehlende Quelle / Inventar abgeschnitten | Sauberer Fehler ohne Pointer-/Sprachänderung; kein geleakter Slot, keine Warnungsunterdrückung. |
| Drei gleichzeitige neue Snapshot-Reader | Zwei Slots eingehalten; dritter kontrolliert abgewiesen, belegte Reader bleiben offen; kein Deadlock. |
| Schnelle en→pt-BR→en-Anforderungen / verspäteter Worker | Gate/Key/Epoch halten Sprache und Generation getrennt; abgebrochene Ziele werden aufgeräumt. |
| Alte Übung mit gehaltenem Reader | Wechsel bleibt durch Gate blockiert; auf Owner-Ebene bleibt alte Übung bis Lease-Ende nutzbar und Historienreferenz unverändert. Keine automatisierten Reviews echter Daten. |
| Bootstrap und Schema 1–4 | Bisherige Prüfung und Fehlermeldungspfade bleiben funktionsfähig; keine erfundenen Inventarhashes. |

Spätere Verifikation: gezielte Tests, komplette Suite, Realpack-Test mit unverändertem 30-s-Budget, Analyse (Alt-avoid_print separat), Stage-Verify und CRLF-Diffcheck. Erst nach Implementierung ist die konkrete offene Gerätefrage „spart A nach Kopierkosten tatsächlich Zeit, bei welchem Peak-RAM/Temp-Speicher?“ zu messen: drei vergleichbare Profile-Wechsel, separater Kaltstart, Home-Frame und erste Übung; keine parallelen Builds/Tests. Für Packupdate nur synthetische lokale Generationen oder ausdrücklich freigegebene Testbestände, keine Veröffentlichung. Danach normalen Build ohne Sonde installieren. **In diesem Planungsauftrag keine Testsuite, Geräteinstallation oder neue Live-Messung.**

## 6. Prüfung dieses Dokumentationsauftrags

- `pwd`, `git rev-parse HEAD`, `git status --short`: richtiger Worktree, Basis `0e2f890…`, Arbeitsbaum vor Änderungen leer; Exit 0.
- `rg --files lib/data/content` mit gezieltem Dateinamenfilter: beide tatsächlichen Dateien `content_update_service.dart` und `content_update_validation.dart` unter diesem Pfad gefunden; Exit 0.
- GitNexus-Index auf Basis aktualisiert (`analyze --index-only`, Exit 0); `query` und `context` für Recovery, Downloadvalidator und Opener mit direkter Source-Prüfung ergänzt. Dart-Funktionskörper sind im Graph teils nur als einzeilige Symbole erfasst; die Tabellen beruhen deshalb auf gelesenen Funktionskörpern, nicht einem vermeintlich vollständigen Graphen.
- Impact für NEXTSTEPS: UNKNOWN/keine auflösbaren Aufrufer; Referenzen in AGENTS/CLAUDE direkt bestätigt. Neuer Plan hat noch keinen Graphknoten, nicht als „unbenutzt“ gedeutet. Änderungen sind auf genau zwei Dokumente begrenzt.
- Ausgeführt: `git -c core.whitespace=cr-at-eol diff --cached --check` → kein Output, Exit 0; Linkprüfung → alle 10 relativen Quellen-/Dokumentlinks vorhanden, Exit 0; NEXTSTEPS → 25 Zeilen. `analyze --index-only` → 8 313 Knoten, 19 340 Kanten, Exit 0. Vollständiges `detect_changes(scope: all, limit: 5000)` → zwei Dateien, alle 18 Symbole, null betroffene Prozesse, LOW, `partial:false`, `truncated:false`, Exit 0. Nur Dokumente geändert; keine Aussage über die Sicherheit einer noch nicht implementierten Codeänderung. Keine Produkttests für diesen reinen Plan. Lokale Graphausgabe: `/private/tmp/lifecycle-graph-final.json`.

**Abnahmegegenstand:** ausschließlich A mit zwei Umsetzungsschritten, temporärem Snapshot und Übergabe desselben geprüften Handles; zusätzlicher temporärer Speicher und noch zu messende Kopierkosten sind Teil dieser Entscheidung. B/C, persistente Nachweise und Änderungen am Lern-/Inhaltsvertrag sind nicht mit freigegeben.
