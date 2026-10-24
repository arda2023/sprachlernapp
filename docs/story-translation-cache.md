# Privater Übersetzungsspeicher · Paket 2A

## Vertrag vor Implementierung

Reihenfolge: geprüfter Inhalt → privater lokaler Treffer → ausdrückliche Onlineanfrage (serverseitiger Treffer vor Generierungsbudget). Keine Karten-/Satzgenerierung, keine Änderungen an Packs, SRS oder Story-Identitäten.

Identität: Konto + Supabase-Projekt, Operation, en/pt-BR → de, exakter vollständiger Satz, exakte Wortform und UTF-16-Start/Ende, optionale Sense-/Formreferenzen, Vertragsversion 2. Keine Unicode-/Case-/Whitespace-Normalisierung. Promptversion `translation-v2`, Anbieter Anthropic, Modell `claude-haiku-5-5` als Herkunft. Vertrags-/Promptänderung invalidiert gezielt; Neustart/Refresh nicht.

Lokaler separater SQLite-Speicher im Application-Support-Verzeichnis; maximal 30 Tage ab ursprünglichem Servererfolg. Kein Zugriff ohne lokal wiederhergestellte nicht-anonyme Sitzung; keine Tokenauffrischung für Offline-Treffer. Kontowechsel/Abmeldung invalidieren laufende Anzeigen. Serverzugriff ausschließlich nach JWT-Prüfung und privater Owner-Zuordnung; Service-only RPCs und RLS ohne Clientpolicies.

Atomare Serverreservierung vor Modellaufruf, vorhandene Generierungslimits unverändert. Gleichzeitige Misses erhalten einen begrenzten Busy-Status, keine wartenden Jobs. Unklarer Ausgang bleibt 24 Stunden gesperrt, danach nur neuer ausdrücklicher Versuch. Keine Exactly-once-Zusage. Löschung entfernt Ergebnisse und verhindert späte Speicherung; Unsicherheitsmarker ohne Originaltext bleiben bis zum Ablauf bestehen.

Löschung: Einstellungen → gespeicherte Übersetzungen löschen, lokal sofort; bei fehlender Verbindung persistente ausstehende Cloudlöschung. Vor nächster Onlineübersetzung zuerst Löschung abschließen. Andere bereits offline befindliche Geräte können ihre lokale Kopie bis zur lokalen Löschung/30-Tage-Frist behalten; kein Versprechen einer Fernlöschung ohne Verbindung.

## Umsetzung und Nachweise

Lokal implementiert und mit synthetischen Antworten geprüft. Kein Push, Deployment, Geräteupdate oder kostenpflichtiger Liveaufruf.

## Tatsächliche Speicher- und Aufrufwege

- `TranslationRequest` vereinheitlicht die Identität; Dart und JavaScript benutzen UTF-16-Offsets. Wiederholte Wörter erfordern einen expliziten Start. Ältere Clients ohne Offset werden ausschließlich bei einem eindeutigen, exakt geschriebenen Vorkommen angenommen. Ein ungültiger Offset ist kein Anlass zu raten.
- `RuntimeTranslationClient` bleibt der HTTP-Transport; `CachedRuntimeTranslationClient` erweitert diesen vorhandenen Pfad. Reader und Textübung prüfen weiterhin zuerst ihre gespeicherte Übersetzung; erst der bestehende Runtime-Dialog liest den privaten Cache. Bis zum Knopfdruck erfolgt keine Netzwerkanfrage. Auch ein nicht lokaler Serverhit benötigt diese Onlinefreigabe; das vermeidet einen zusätzlichen stillen Textupload.
- Lokal: `<ApplicationSupport>/private_translations.sqlite`, Tabellen `translations` und `deletion`, keine Änderung der Drift-Lerndatenbank. Die DB enthält Kontokennung mit Projekthost, Anfragehash, validierte Antwort und Ablaufzeit; keine JWTs und keinen Anthropic-Schlüssel. Zugriff im App-Sandboxspeicher, keine zusätzlich behauptete Dateiverschlüsselung. `secure_delete=ON`; Gerätesicherungen und Anbieter-Backups sind davon nicht automatisch gelöscht.
- Konto wird aus der vorhandenen lokal wiederhergestellten Supabase-Sitzung bestimmt. Offline-Treffer brauchen keine Tokenauffrischung; anonym/abgemeldet liefert keinen Treffer. Konto-/Löschrevisionen sperren späte Ergebnisse und entfernen offene Ergebnisanzeigen. Tokenbeschaffung prüft ebenfalls einen zwischenzeitlichen Kontowechsel.
- Server: `app.translation_cache` mit `(user_id,request_key)` als Primärschlüssel. Originalsatz und Wortreferenzen werden gehasht, nicht dauerhaft auf dem Server abgelegt; der Antworttext ist weiterhin privat. Keine Public-/Anon-/Authenticated-Tabellenrechte, RLS aktiv ohne Clientpolicies. Nur Service-only RPCs; die Function nimmt die Identität aus `/auth/v1/user`, niemals aus Clientfeldern.
- `claim_translation` prüft die Sprachfreigabe, nimmt den bestehenden globalen Transaktionslock und liest zuerst den Treffer. Nur ein echter neuer Claim reserviert die bisherigen 5/Minute, 20/Tag/Nutzer, 1000/Tag global. Die Transaktion endet vor dem Modellaufruf. Lock-Wartezeit höchstens zwei Sekunden; bestehende Function-Deadline 25 Sekunden bleibt.
- `pending` hat eine 45-Sekunden-Fertigstellungsfrist. Ein zweiter Aufrufer erhält sofort 409 statt eines Warteloops. Nach Fristablauf wird weiterhin kein neuer Modellaufruf erlaubt: der unsichere Marker gilt 24 Stunden ab Reservierung. Erst nach Ablauf kann eine neue ausdrückliche Anfrage neu reservieren. Auch ein abgebrochener Client kann serverseitig noch fertig werden; dann wird das validierte Ergebnis beim nächsten Abruf wiederverwendet. Kein automatischer Retry, auch nicht nach einem fehlgeschlagenen Cache-Write.
- Nur eine vollständig validierte Antwort wird mit passendem Ticket rechtzeitig `ready`. Löschung entfernt fertige Antworten; laufende Tickets werden zu `uncertain` ohne Text, sodass ein später Erfolg sie nicht wiederherstellt. Fehlerantworten sind niemals Translationseinträge. Ein lokaler Writefehler lässt eine validierte Übersetzung sichtbar, zeigt aber ehrlich an, dass sie auf diesem Gerät nicht gespeichert ist. Ein lokaler Lesefehler startet keine neue kostenpflichtige Anfrage.

## Aufbewahrung und Invalidierung

30 Tage Wiederverwendung ab ursprünglichem Servererfolg, nicht gleitend verlängert durch Treffer. Abgelaufene lokale Einträge werden beim Öffnen der DB physisch bereinigt; serverseitige Einträge beim nächsten Claim. Inaktive Geräte/Server können die abgelaufenen Bytes bis zur nächsten Nutzung oder expliziten Löschung behalten. Das ist eine Nutzungsfrist mit verzögerter Bereinigung, keine Zusage taggenauer physischer Löschung. Accountlöschung in `auth.users` entfernt Servereinträge per FK-Cascade. Bestehende weitere Fremdschlüssel der App können eine Accountlöschung unabhängig davon einschränken.

Vertrags- oder Promptrevision, Sprache, Operation, exakter Text/Offset sowie vorhandene Sense-/Formreferenz ändern den Schlüssel; keine aggressive Normalisierung. Bei künftigem Modellwechsel muss zugleich die Prompt-/Vertragsrevision erhöht werden; die Antwortprüfung akzeptiert aktuell nur den festen Modellnamen. Normale App-Neustarts, UI-Refresh und Sprachauswahl löschen den Cache nicht. Ein inhaltlich identischer Kontext bleibt über einen Packwechsel gültig; geänderte Texte/Referenzen treffen nicht mehr. Alte ungültige Cache-Daten werden nicht als neuer Inhalt ausgegeben und nicht automatisch neu generiert.

„Gespeicherte Übersetzungen löschen“ befindet sich in Einstellungen und erläutert vor der Ausführung, was gelöscht wird. Offline werden lokale Datensätze atomar entfernt und die Cloudlöschung vorgemerkt. Der nächste bestätigte Onlineabruf muss diese Löschung zuerst abschließen; ein alter Cloudtreffer darf nicht die lokale Löschung rückgängig machen. Andere Geräte haben eigene Offlinekopien: Dort ebenfalls löschen oder deren 30-Tage-Frist abwarten. Eine globale sofortige Offline-Fernlöschung wird nicht behauptet.

## Cloudschritte – vorbereitet, nicht ausgeführt

Aus dem Hauptprojekt, mit bestehender Supabase-Anmeldung. Folgende Befehle sind unter **macOS Terminal und Windows PowerShell identisch**:

```text
supabase link --project-ref yevntxclpchapacqdizm
supabase migration list
supabase db push --dry-run
```

Vor dem Anwenden muss die Liste geprüft werden: Neu für diesen Auftrag ist ausschließlich `20261024000001_private_translation_cache.sql`; sie baut auf der vorhandenen `20261019000001_runtime_translation_limits.sql`, `content_readers`, `app.usage` und `auth.users` auf. Ist die ältere Runtime-Migration noch nicht angewendet, muss sie ebenfalls vor der Cachemigration angewendet werden. Weitere unerwartete ausstehende Migrationen zuerst einzeln abgleichen. Dieser Auftrag hat weder Remotezustand noch Secrets ausgelesen.

Nach diesem Abgleich, **Datenbank zuerst**, dann beide Functions, dann Appupdate:

```text
supabase db push
supabase functions deploy lookup-word --project-ref yevntxclpchapacqdizm
supabase functions deploy translate-sentence --project-ref yevntxclpchapacqdizm
```

`verify_jwt=true` beibehalten. Bereits benötigtes `ANTHROPIC_API_KEY` bleibt ausschließlich Server-Secret; keine neuen Secrets. Alte Function ohne Cachevertrag ist mit dem neuen App-Antwortvalidator nicht kompatibel: daher keinen App-Rollout vor den Functions. Alte Apps können eindeutige Einzelwortanfragen weiterhin senden, mehrdeutige Wiederholungen ohne Offset werden gezielt abgewiesen. Kein Herabsetzen von Validatoren für Rollout-Kompatibilität.

Lokaler Supabase-Stack, sofern vorhanden (macOS und PowerShell identisch):

```text
supabase test db supabase/tests/database/runtime_translation.test.sql
supabase test db supabase/tests/database/translation_cache.test.sql
```

PGlite-Alternative ohne Cloud: `npm install --prefix <externes-testverzeichnis> --no-audit --no-fund @electric-sql/pglite`, danach `node tool/test_translation_cache_sql.mjs <absoluter-pfad-zum-testverzeichnis>/node_modules/@electric-sql/pglite/dist/index.js` (macOS/PowerShell; Pfade entsprechend anpassen). Das Tool lädt die echten Migrationen und SQL-Assertions; nur Supabase-Systemrollen/Auth-/Storage-Minimalschema und der pgTAP-Ausgaberahmen werden ersetzt. Es prüft PostgreSQL-Semantik, nicht reale konkurrierende Sessions oder das Supabase-Gateway.

## iPhone-Prüfweg nach Cloudschritten und Appupdate

1. Bestehenden Account unter Einstellungen → Inhaltsupdates anmelden. App mit der vorhandenen öffentlichen Supabase-Konfiguration bauen; keinen neuen Service-/KI-Key in Flutter eintragen. Auf macOS `flutter devices`, dann `flutter run -d <geräte-id>` mit den bereits verwendeten `--dart-define`-Parametern. Windows kann die iOS-App nicht bauen; dort nur Cloudschritte. Installation nicht löschen, damit Lerndaten bleiben.
2. Stories → Nachrichten → „Politik in 100 Sekunden“ → im ersten Satz **council** antippen. Bei fehlender lokaler Übersetzung einmal **Mit KI übersetzen** bestätigen. Satz-/Quellsprache kontrollieren. Dieser manuelle Schritt ist eine echte kostenpflichtige Anfrage, nicht Teil der lokalen Abnahme dieses Auftrags.
3. Schließen, Flugmodus, App vollständig beenden/neustarten, dasselbe Wort erneut öffnen: Ergebnis direkt, ohne KI-Knopf. Fehlendes anderes Wort: kein erfundener Treffer; nach Bestätigung verständlicher Verbindungsfehler.
4. Flugmodus beenden; abmelden: private Treffer sind nicht verfügbar. Anderes Konto: keine Übernahme fremder Treffer. Mit ursprünglichem Konto erneut anmelden: dessen ungelöschte Einträge bleiben bis zum Ablauf verfügbar.
5. Einstellungen → gespeicherte Übersetzungen löschen; danach denselben Eintrag öffnen: neuer Miss. Offline löschen, App neu starten, online erneut löschen: Cloudlöschung muss abschließen. Kartenanzahl, „Aus Storys“ und Historie müssen gleich bleiben.
6. Satzübersetzung und pt-BR in tatsächlich fehlenden Kontexten prüfen, ohne geprüfte Packübersetzungen zu entfernen. Geräte-/Cloudqualität, Multi-Device-Latenz und reale Anbieterabrechnung bleiben gesonderte Abnahme.

## Schnittstellen für den nächsten Teil von Paket 2

- `lib/data/translation_request.dart`: exakte Anfrageidentität und gemeinsame lokale Antwortvalidierung; `TranslationRequest`, `RuntimeTranslation`.
- `lib/data/translation_cache.dart`: `cached(...)`, `translate(...)`, `clearSaved()` über `CachedRuntimeTranslationClient`; `TranslationCache` für getrennten lokalen Speicher. Diese Schnittstellen liefern ausschließlich Anzeigeübersetzungen.
- `lib/presentation/providers/runtime_translation_provider.dart` verbindet vorhandenen Authzustand, Speicher und HTTP; `RuntimeTranslationSheet` verwendet dieselbe Schnittstelle mit optionalen `start`, `senseRef`, `formRef`.
- `supabase/functions/_shared/runtime_translation.ts`: validierter v2-Vertrag; SQL-Claims/Finish/Delete in der neuen Migration. Keine Wiederverwendung dieser Endpoints als unvalidierte Kartengenerierung.
- Story-Identitäten und Sammlung aus Paket 1 bleiben erhalten. Wörterbuch, Apple/ML-Kit, importierte Lernkarten und eine ausdrücklich neue Satzgenerierungsfreigabe bleiben dem restlichen Paket 2 vorbehalten; Scheduler/Verteilung bleibt Paket 3.

## Lokale Nachweise · 24.10.2026

Ausgangspunkt sauberer Commit `09c3738`. Alle Texte/Accounts in den neuen Tests sind synthetisch. Kein Netzwerkrecht für die Deno-Abnahme, keine Anbieteranfrage, keine Cloudmigration und kein iPhone-Build.

| Befehl (macOS und PowerShell gleich, mit vorhandenem SDK im PATH) | Beobachteter Output | Exit |
| --- | --- | --- |
| `flutter test --no-pub --reporter expanded` | **552 PASS, 6 bestehende Skips**, 61 Sekunden | 0 |
| `flutter test --no-pub test/translation_cache_test.dart test/runtime_translation_test.dart test/data/content_auth_test.dart test/story_collection_test.dart --reporter expanded` | Nach abschließender Serialisierung der ausstehenden Cloudlöschung und drei Zusatzprüfungen: **51 PASS**, 8 Sekunden | 0 |
| `deno check supabase/functions/lookup-word/index.ts supabase/functions/translate-sentence/index.ts` | Beide Entrypoints typgeprüft | 0 |
| `deno test --allow-read supabase/functions/_shared/runtime_translation_test.ts supabase/functions/_shared/translation_cache_test.ts supabase/functions/_shared/content_distribution_test.ts` | **42 PASS, 0 FAIL**, einschließlich bestehender Inhaltsverteilung | 0 |
| `node --experimental-transform-types --test supabase/functions/_shared/runtime_translation_test.ts supabase/functions/_shared/translation_cache_test.ts` | **31 PASS, 0 FAIL** | 0 |
| `node tool/test_translation_cache_sql.mjs <PGlite-dist/index.js>` | **PASS PostgreSQL/PGlite: runtime_translation.test.sql** und **translation_cache.test.sql** | 0 |
| `flutter test --no-pub test/data/real_pack_test.dart --reporter expanded` | **1 PASS, 5 Sekunden**, originales 30-Sekunden-Budget unverändert | 0 |
| `dart run tool/stage_content_pack.dart --verify` | **22 table counts match**; Schema 4, Version `story_single_sentence_v1`, 26.198.016 Bytes; SHA-256 `b85793932825a22e92ac744a42255e9f333acd35809aaba46edb5a395f099bdb` | 0 |
| `flutter analyze --no-pub` | Ausschließlich bereits bestehendes `avoid_print` in `test/data/baseline_adoption_pack_test.dart:43`; kein neuer Befund | 1 |
| `git -c core.whitespace=cr-at-eol diff --cached --check` | Keine Whitespacebefunde | 0 |

Der vollständige Lauf liegt vor der letzten lokalen Lösch-Serialisierung; danach wurden die betroffenen Cache-/Auth-/Reader-/Storypfade gezielt erneut geprüft. Bestehende Google-Fonts-Warnungen betreffen die Testumgebung; keine Aussage über reale Geräteschriften. Keine Tests deaktiviert, keine Pack-/Performancegrenzen verlängert.

**Gemessene Testaussage statt Einsparungsprozent:** erster erfolgreicher Abruf plus identischer zweiter Abruf = **1 Modellaufruf, 1 Budgetreservierung** im Backendtest. Acht gleichzeitige identische Abrufe = ebenfalls **1 Modellaufruf**; weitere erhalten begrenzt Busy oder den fertigen Treffer. Lokal bleiben Wiederholung, neuer Client mit derselben SQLite-Datei und Offlineabruf bei einem einzigen Remoteaufruf. Das belegt Deduplizierung im reproduzierbaren Test, keine reale Anbieterabrechnung oder Übersetzungsqualität.

Abgedeckt: en/pt-BR, unveränderte Akzente/Unicode-Schreibweisen, Wort-/Satztrennung, unterschiedliche Kontexte/Senses/Formreferenzen, wiederholtes Wort samt tatsächlichem Reader-Offset, fehlender Login/Kontowechsel/Logout während laufender Anfrage, lokaler Neustart, Offlinehit, accountbezogene Löschung, persistente ausstehende Cloudlöschung, parallele Aufrufe und Lösch-Synchronisierung, ungültige/abgebrochene Antwort, Read-/Writefehler, Server-Owner/Anonymous-Isolation, SQL-RLS/RPC-Rechte, Budgethit bei ausgeschöpftem Limit, abgelaufene Lease und späte Antwort nach Löschung. SQL-Snapshots prüfen unveränderte `user_cards` und `review_log`; bestehende Storysammlungstests prüfen dieselben Karten und Historien.

Zwischenbefunde: bestehende HTTP-Testfixtures an vollständigen v2-Antwortvertrag und zusätzlichen Save-RPC angepasst; Dialogtest wartet nun den asynchronen lokalen Lookup ab. SQL-Harness ergänzt `auth.uid()` als minimale Supabase-Systemfunktion; lokale Testvariablen-/Aliasmehrdeutigkeit korrigiert. Danach obige Prüfläufe grün. Es wurde kein Produktvalidator gelockert und kein Timeout erhöht.

## Änderungsanalyse und Grenzen

GitNexus vor Änderungen: Auth-, Runtime-Client-/Backend-, Dialog- und Reader-Impact abgefragt; aufgelöste Risiken LOW/MEDIUM. UNKNOWN bei Provider-/Frameworkcallbacks wurde über tatsächliche Referenzen (`runtimeTranslationProvider`, Logout-Controller, Buttoncallback) ergänzt. Keine Provider-/Callbackkante als Beweis für Unbenutztheit interpretiert.

Nach Indexaktualisierung: 9.570 Knoten, 21.777 Kanten, 286 Flows. Vollständiges `detect_changes(scope: all)` auf vorgemerkten Dateien: **24 Dateien, 59 von 59 Symbolen, 212 gemeldete Abläufe, Risiko critical**, `partial=false`, `truncated=false`. CLI und MCP stimmen überein. Die breite Meldung enthält sehr viele Verbindungen ausschließlich über den geänderten Markdown-Abschnitt „Architecture“ mit leerer Symbol-ID; das ist eine auffällige Graphzuordnung, keine belegte Änderung dieser Laufzeitpfade. Die Gesamtwarnung wurde deshalb nicht zu „low“ umgedeutet. Konkrete Symbolkontexte zusätzlich geprüft: `ContentAuthRepository` → vorhandener Inhaltsupdateprovider/Auth-UI-Tests; `RuntimeTranslationClient` → Reader/Textübung/Provider/Cache; `TranslationBackend` → beide Functions. Konkrete betroffene Flows betreffen Readerinitialisierung, Übersetzungsdialog, Anfragevalidierung und Fehlerausgabe, abgedeckt durch die oben genannten Tests.

Statische Dart-Provider-/Callbackauflösung und modellierte SQL-RPC-Kanten sind keine Vollständigkeitsgarantie. PGlite führt die SQL-Assertions wirklich aus, besitzt aber keine getrennten konkurrierenden PostgreSQL-Sessions. Die Function-Paralleltests nutzen einen synthetischen atomaren Claim; der produktive Claim benutzt den bestehenden globalen PostgreSQL-Transaktionslock. Ein echter Gateway-/Mehrgeräte-/Multi-Session-Test bleibt Teil der Cloudabnahme. Keine Exactly-once- oder Fernlöschgarantie für bereits offline befindliche Geräte.
