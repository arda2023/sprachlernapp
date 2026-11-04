# Sicherheitsnachprüfung und Korrekturen – 01.11.2026

## Ergebnis

Die bestätigten Lücken bei gemeinsamen KI-Ausgaben, missbräuchlichen Themenanfragen, Systembackups und verspäteter physischer Bereinigung wurden bearbeitet. Zusätzlich wurde beim eigenen Durchsehen ein Ressourcenproblem am Kontolöschungs-Endpunkt gefunden und korrigiert. Drei neue Migrationen und fünf betroffene Edge Functions sind im verknüpften Supabase-Projekt `yevntxclpchapacqdizm` veröffentlicht. 31 isolierte Live-Kontrollen bestanden; die drei hierfür angelegten synthetischen Konten wurden vollständig entfernt.

Dies ist eine gezielte Sicherheitsnachprüfung mit Umsetzung, keine neue vollständige App-Store-Freigabe und kein umfassender Penetrationstest. Die App-Store-Einrichtung läuft auf Nutzerseite. Die bei Beginn vorhandenen Änderungen an Kauf-/Premium-Logik und deren Tests wurden nicht überschrieben. Es wurde kein Commit und kein Store-Release erstellt. Die nativen Appänderungen benötigen einen neuen Appbuild auf dem jeweiligen Endgerät; die Serveränderungen sind bereits wirksam.

Der Bericht vom [30.10.2026](release-security-audit.md) bleibt ein historischer Befund. Aussagen dort über fehlende Anmeldung, nicht implementierte Käufe oder rein lokales Abmelden dürfen nicht ungeprüft auf den heutigen Stand übertragen werden.

## Umfang, Methode und Skills

Geprüft wurden Flutter-Client, iOS-/Android-Konfiguration, Auth- und Löschungsabläufe, alle nutzerbezogenen Anthropic-Pfade, deren SQL-Rechte und Quoten, die aktuelle Datenbankkonfiguration und ausgewählte Abhängigkeiten. Die öffentliche Storemetadaten-/Produktkonfiguration wurde nicht verändert.

Verwendete installierte Skills:

- [vibe-security](https://github.com/raroque/vibe-security-skill): Serververtrauen, Secrets, RLS, Auth, Limits und KI-Eingaben.
- [Mobile-Security-Skills](https://github.com/dweinstein/mobile-security-skills): `auth-assessment` und `secure-storage-audit` für Auth, private Dateien und Backups.
- [Cybersecurity-Skills](https://github.com/Masriyan/Claude-Code-CyberSecurity-Skill): `16-ai-llm-security` und `02-vulnerability-scanner`, mit getrennten Aussagen zu Beobachtung, Ableitung und offenen Nachweisen.
- [Apple-App-Review-Skills](https://github.com/cruisediary/apple-app-review-skills): gezielter Abgleich der KI-Datentransparenz. [App-Store-Review](https://github.com/JustinPerea/app-store-review-skill): erneute Einordnung der früheren Releasebefunde. Die 53 vollständigen Storechecks wurden in diesem Sicherheitsauftrag nicht erneut als vollständige Storeprüfung ausgeführt.
- Repository-Skills zu GitNexus-Auswirkungen und Swift für die betroffenen Stellen.

Modi: lokale statische Prüfung; synthetische lokale Tests; passive öffentliche Dokumentation und OSV-Abfrage; autorisierte aktive Tests gegen das eigene Supabase-Projekt mit ausschließlich künstlichen Konten und Themen. Es wurden keine fremden Nutzerkonten für Tests benutzt, keine echten Storekäufe ausgeführt und keine E-Mails versandt. Zugangsdaten wurden nur im Prozess verwendet; Prüfnachweise enthalten keine Tokens oder Schlüsselwerte.

## Befunde und Korrekturen

| Befund | Einstufung | Stand |
|---|---|---|
| Keine gemeinsame monetäre KI-Grenze | Hoch für Kostenmissbrauch | Serverseitig umgesetzt und live getestet |
| Themenfeld konnte als allgemeiner KI-Auftrag missbraucht werden | Mittel | Mehrschichtige Abweisung umgesetzt, synthetisch und live getestet |
| Private Appdaten waren in Systembackups enthalten | Mittel, abhängig vom Inhalt | Android-Regeln erweitert; iOS-Verzeichnisausschluss im Simulator bestätigt |
| Private KI-Antworten wurden nur bei späterer Nutzung bereinigt | Mittel | Stündliche Bereinigung aktiv; SQL-Funktion getestet |
| Kontolöschung wartete auf langsame Requeststreams ohne wirksamen Abbruch | Mittel, Ressourcenverbrauch | Stream-Limit und Abbruch implementiert und getestet |
| Öffentliches EXECUTE auf administrativer RLS-Triggerfunktion | Niedrige Härtungspriorität | Rechte entfernt; beide Advisor-Warnungen verschwunden |
| Schutz vor bekannten kompromittierten Passwörtern deaktiviert | Betriebs-/Auth-Restpunkt | Supabase-Advisor meldet ihn weiterhin; siehe unten |

### 1. Gemeinsame 5-€-Grenze

**Beobachtet:** Vorher gab es getrennte fachliche Quoten für Übersetzungen, persönliche Karten und Vokabellisten. Diese zählten Anfragen oder Wörter, keinen gemeinsamen Euro-Verbrauch. Die großzügige Outputgrenze einer Liste machte allein aus der Wortzahl keine monetäre Garantie. Fehlgeschlagene Zustellungen können beim Anbieter trotzdem Kosten verursachen.

**Korrektur:** `ai_budget.ts` liegt vor allen drei nutzerbezogenen Anbieterpfaden und auch vor der neuen Themenklassifikation. `reserve_ai_spend` reserviert in einer atomaren Datenbanktransaktion; `settle_ai_spend` rechnet einmalig mit bestätigter Provider-Usage ab. Kosten werden pro Konto und UTC-Monat geführt. Service-only-RPCs, RLS und Ganzzahlarithmetik verhindern Manipulation aus der App. Die bestehenden fachlichen Quoten bleiben bestehen.

**Nachweis:** Paralleltest mit zwölf echten Requests, Rollentests und Live-Aufrufe der veröffentlichten Endpunkte nach Budgeterschöpfung. Cachelöschung konnte das Geldbudget nicht zurücksetzen. Kein Modelaufruf wurde beim abgewiesenen Geldbudget gestartet. Cache- und Statusabrufe eines fertigen Ergebnisses erzeugten keine neue Reservierung.

**Grenzen:** Ein konservativer Höchstbetrag muss vor dem Aufruf vollständig passen. Dadurch kann die nutzbare Grenze vor tatsächlichen 5 € erreicht sein. Unklare Ausgänge halten die volle Reservierung bis zum Monatswechsel. Nicht enthalten sind gemeinsame Hosting-/Mail-/Storagekosten und administrative Redaktion. Die Regel gilt pro Supabase-Konto, nicht pro beweisbar identifizierter Person. Bereits vor der Umstellung entstandene Kosten wurden nicht rekonstruiert. Tarif-Freigabe läuft **am 01.12.2026, 00:00 UTC** aus; eine Prüfung und administrative Verlängerung ist nötig. Vollständige Rechnung: [ai-cost-limit.md](ai-cost-limit.md).

### 2. Themenvokabeln statt Chat

**Beobachtet:** Die Eingabe war bereits auf 400 UTF-16-Einheiten, zwei Sätze und eine feste Antwortstruktur begrenzt. Ein Satz wie „Erkläre mir Diabetes“ oder eine gemischte Aufgabe konnte aber strukturell gültig sein. Die bisherige Anweisung, Eingaben nur als Daten zu lesen, war keine verlässliche fachliche Zulassungskontrolle.

**Korrektur:** Die Serverprüfung normalisiert zur Musterprüfung mit NFKC. Fragezeichen einschließlich Varianten, Rollen-/Markupgrenzen, URLs und typische Umgehungsanweisungen werden früh abgelehnt. Danach lässt eine separate, strikt strukturierte KI-Prüfung nur Themen und thematische Vokabelwünsche durch. Ihr Ergebnis darf ausschließlich ein Boolean sein; Prosa, Zusatzfelder, fehlende Felder und ungültige Antworten führen zur Abweisung. Der Klassifikationsaufruf selbst ist budgetiert und liegt hinter Konto-, Premium- und Tagesquotenprüfung.

Der Generator erhält weiterhin ein festes Vokabelschema. Seine Anweisung verbietet zusätzlich, Antworten auf fremde Aufgaben über Beispielsätze oder Vokabelfelder zu verteilen. Weder Klassifikator noch Generator erhalten Werkzeuge, Browserzugriff, Datenbankzugriff, fremde Kontodaten oder Secrets. Die App zeigt bei `TOPIC_NOT_ALLOWED` einen verständlichen Hinweis; das Textfeld beschreibt ausdrücklich den Zweck als Vokabelthema. Es gibt keine automatische Wiederholung abgewiesener Aufträge.

**Live beobachtet:** Abgewiesen wurden unter anderem Erklärungsaufträge, Rechenaufträge, Assistenten-Rollenspiel, eine Sachfrage ohne Fragezeichen und ein gemischter Vokabel-/Codeauftrag. „Urlaub am Meer“, „Medizin, besonders Gehirn und Arme“ und „Restaurant und Essen“ lieferten gültige Vokabeln in Englisch, brasilianischem Portugiesisch und Spanisch. Lokale Tests decken zusätzlich Rollenmarker, Unicode-Fragezeichen, URLs, Encoding-Anweisungen und ungültige Klassifikatorantworten ab.

**Grenzen:** Diese Fälle sind ein konkreter Abwehrnachweis, kein Beweis gegen sämtliche Prompt-Injection-Formulierungen. Ein Modell kann eine geschickt formulierte Aufgabe falsch einordnen. Die verbleibende Begrenzung entsteht durch feste Ausgabefelder, fehlende Werkzeuge, keine frei zugänglichen Secrets, Ausgabevalidierung und Kostenlimits. Es wird keine semantische Fehlerfreiheit oder redaktionelle Sprachfreigabe behauptet. Private Daten sollten weiterhin nicht als Thema eingegeben werden.

### 3. Backup-Ausschlüsse

**Beobachtet:** Android schloss lediglich SecureStorage- und Adapty-Präferenzen aus. `user.db`, `private_translations.sqlite`, private JSON-Dateien und SQLite-Nebendateien lagen dagegen im normalen Application-Support-Speicher. iOS setzte dafür bisher kein eigenes Backup-Ausschlussattribut.

**Korrektur:** Android schließt jetzt die `file`- und `database`-Domains sowohl in den älteren Backupregeln als auch bei Cloudbackup und Geräteübertragung aus. iOS setzt beim Appstart `isExcludedFromBackup` auf das Application-Support-Verzeichnis. Der Verzeichnisausschluss umfasst vorhandene und neue Dateien sowie WAL/SHM-/Migrationskopien. Ein Fehler beim Setzen des Attributs wird mit einer konstanten Meldung ohne Datenpfad protokolliert.

**Nachweis:** Beide nativen Builds erfolgreich. Das neu gebaute iOS-Appbundle wurde auf dem iPhone-17-Pro-Simulator gestartet. Anschließend ergab eine echte Foundation-Abfrage des Appverzeichnisses `isExcludedFromBackup == true`. Android-Manifest und kompilierte Ressourcen binden die beiden XML-Regelsätze ein.

**Wichtige Produktfolge:** Auch der lokale Lernstand wird damit nicht aus einem solchen neuen Systembackup wiederhergestellt. Die App hat weiterhin keine Kontosynchronisation für diesen Lernstand. Die Datenschutzhinweise und PRODUCT.md nennen das ausdrücklich. Bereits existierende Backups werden dadurch nicht rückwirkend gelöscht. Ein tatsächlicher iCloud-/Google-Backup-Restore auf physischen Geräten wurde nicht durchgeführt. Das iOS-Attribut ersetzt keine Beobachtung jedes Geräte-/Backupanbieters.

**Restschutz:** Keine zusätzliche SQLCipher-Verschlüsselung wurde eingeführt. Private Dateien bleiben durch App-Sandbox und Betriebssystem-/Geräteverschlüsselung geschützt. Ein kompromittiertes, entsperrtes oder vollständig ausgelesenes Gerät liegt außerhalb dieser nachgewiesenen Abwehr. Keine Aussage „lokale Daten sind jetzt unter allen Umständen verschlüsselt“.

Quellen: [Apple-Backupattribut](https://developer.apple.com/documentation/foundation/urlresourcevalues/isexcludedfrombackup), [Android Auto Backup](https://developer.android.com/identity/data/autobackup).

### 4. Aufbewahrung ohne spätere Appnutzung

**Beobachtet:** Für Themenantworten und persönliche Kartengenerierung gab es Ablaufzeitpunkte, aber die physische Bereinigung lief erst bei einer späteren Anfrage. Das genügte nicht, um auch bei inaktiven Konten eine zeitnahe Entfernung zu gewährleisten.

**Korrektur:** Der aktive Cronjob `purge-private-ai` läuft stündlich zur Minute 17. Er entfernt abgelaufene private Themenantworten und persönliche Kartengenerierungsantworten, erhält deren No-Replay-Marker und löscht geschlossene Kostenperioden nach Ende des zweiten Folgemonats. Ohne Konto werden diese Daten per FK-Cascade ebenfalls entfernt. Der aktive Geldmonat wird nicht bereinigt und unbekannte Ausgänge werden nicht dadurch erstattet.

**Nachweis:** Die tatsächlichen SQL-Funktionskörper wurden mit alten und aktuellen Fixture-Zeilen geprüft; alte Inhalte verschwinden, aktuelle Antworten und aktuelles Geldbudget bleiben bestehen. Der Cronjob wurde auf dem laufenden Projekt mit Zeitplan, SQL-Kommando und `active=true` gelesen. Die Veröffentlichung am selben Tag beweist noch keine langfristige lückenlose Cron-Ausführung; der Betrieb muss Jobfehler überwachen.

**Präzise Frist:** Entfernung beim nächsten stündlichen Lauf nach Ablauf, regulär also innerhalb von 30 Tagen plus höchstens etwa einer Stunde, bei einem Betriebsfehler entsprechend später. Datenbank-Backups und eigene Aufbewahrung des KI-Anbieters sind davon getrennt. Für normale Übersetzungen gilt ausdrücklich die neuere Nutzerentscheidung vom 01.11.: Aufbewahrung ohne Ablaufdatum bis zur manuellen Cache-/Kontolöschung. Diese Entscheidung wurde nicht durch eine alte 30-Tage-Regel überschrieben.

### 5. Begrenzte Kontolöschungs-Requests

**Beobachtet:** Der Endpunkt hatte einen AbortController, aber sein Requestbody-Leser reagierte nicht darauf. Ein gültig aussehender Authorization-Header und ein nicht endender Body konnten daher die Verarbeitung über die beabsichtigte Frist hinaus offenhalten. Außerdem wurde eine Auth-Antwort zunächst vollständig gepuffert und erst danach auf Größe geprüft.

**Korrektur:** Der gemeinsame JSON-Leser prüft die Bytezahl während des Streams, bindet Abbruchsignale ein und cancelt den Reader. Requestlimit: 1.024 Bytes, Auth-Antwort: 32.768 Bytes. Der bestehende Handler meldet bei Fristablauf 504. Bestätigung, frische Anmeldung, Publisher-Schutz und Löschungsreihenfolge bleiben bestehen.

**Nachweis:** Ein absichtlich endloser Stream wird fristgerecht geschlossen, ohne Auth- oder Löschungsaufruf; ein übergroßer Body wird mit 413 abgewiesen. Die acht Löschungsregressionen einschließlich bestehender Auth-/Adapty-Verkettung bestehen. Langsame Angriffe wurden nicht gegen den Produktivdienst geflutet.

### 6. Tatsächliche Serverrechte und Advisor-Befunde

Alle 19 vor den neuen Migrationen vorhandenen App-Tabellen hatten RLS aktiviert. Die neuen Geldtabellen aktivieren RLS ebenfalls und besitzen keine Client-Schreibrechte. Live-RPC-Tests bestätigen, dass ein angemeldeter Client weder Geld reservieren noch Geld abrechnen noch den privaten Geldledger lesen kann. Die SQL-Tests prüfen zusätzlich die anonyme Rolle und falsche Besitzer.

Die Supabase-Advisor-Warnungen zu `public.rls_auto_enable()` waren real vorhandene unnötige EXECUTE-Rechte auf eine administrative SECURITY-DEFINER-Eventtriggerfunktion. Diese Funktion ist kein regulärer App-API-Endpunkt. Da PostgreSQL Eventtriggerfunktionen nicht beliebig wie gewöhnliche Funktionen ausführt, wurde daraus **keine nachgewiesene anonyme Rechteübernahme** abgeleitet. Die Rechte wurden vorsorglich entfernt; der administrative DDL-Trigger selbst bleibt aktiv. Beide Warnungen verschwanden im erneuten Advisor-Lauf.

Die bisherige native Anmeldung und serverseitige Premiumvalidierung wurden nicht durch Clientflags ersetzt. Administrative redaktionelle KI-Aufrufe sind gesondert authentifiziert und nicht aus der App erreichbar. Der Nachrichtenjob bleibt im Entwurfsverzeichnis.

## Weiter bestehende oder separat zu prüfende Punkte

1. **Leaked-Password-Schutz:** Der laufende Supabase-Advisor meldet weiter `auth_leaked_password_protection`. Das ist eine zusätzliche Auth-Härtung, kein Nachweis eines gestohlenen Passworts. Laut [Supabase-Dokumentation](https://supabase.com/docs/guides/auth/password-security) benötigt diese Funktion Pro oder höher. Nachprüfung auf Rückfrage des Betreibers: Die Management API bestätigte zunächst `password_hibp_enabled=false`; der anschließende gezielte Aktivierungsversuch wurde mit **HTTP 402** und „Configuring leaked password protection via HaveIBeenPwned.org is available on Pro Plans and up.“ abgelehnt. Damit ist die fehlende Tarifberechtigung für dieses Projekt konkret bestätigt; im ersten Prüfbericht war sie nur aus der Dokumentation abgeleitet worden. Es wurde kein kostenpflichtiger Tarifwechsel vorgenommen. Der Schalter bleibt aus; normale E-Mail-Code-Anmeldung ist davon zu unterscheiden. TOTP-Enrollment/Verification und E-Mail-Bestätigung sind in der gelesenen Projektkonfiguration aktiviert. Bereinigter Nachweis: [password-protection-followup.json](security-fixes-evidence-2026-11-01/password-protection-followup.json).
2. **Tarifpflege:** Die KI-Tariffreigabe endet am 01.12.2026, 00:00 UTC. Ohne Prüfung/Verlängerung werden neue KI-Aufrufe dann gesperrt. Diese zusätzliche Befristung war eine Implementierungsentscheidung des Assistenten, keine ausdrückliche Nutzeranforderung, keine Anthropic-Vorgabe und keine App-Store-Bedingung. Die Rückfrage hat die veröffentlichte Frist nicht verändert. Details und Annahmen im Kostenbericht.
3. **App Store und Android-Produktion:** Storeprodukte, Produktionssignatur, Datenschutzangaben, Vertragsfreigabe, Reviewzugang und tatsächliche Storekäufe bleiben Teil der laufenden Veröffentlichungsvorbereitung. Android verwendet für die ausdrücklich private Testauslieferung weiterhin die vorhandene Debugsignatur; sie wurde nicht als öffentliche Produktionssignatur ausgegeben.
4. **KI-Einwilligung:** Die gemeinsame, widerrufbare KI-Freigabe und ihr vom Nutzer ausdrücklich gewünschter anfänglich eingeschalteter Onboardingzustand wurden nicht stillschweigend geändert. Ob die tatsächliche Präsentation und aktive Bestätigung allen anwendbaren Anforderungen genügen, bleibt eine konkrete Datenschutz-/Releaseprüfung. Die Datenschutzhinweise ergänzen jetzt Themenklassifikation, Vokabelgenerierung und Kostenmetadaten. Rechtstexte bleiben bis zur Betreiberfreigabe Entwürfe.
5. **Geräte-/Abhängigkeitstiefe:** Keine Vollprüfung kompromittierter Geräte, kein physischer Backup-Restore, keine vollständige CVE-Abdeckung von Flutter Engine, allen nativen SDKs oder sämtlichen redaktionellen Pythonwerkzeugen. Die positive Pub-Abfrage ersetzt das nicht.
6. **Abmeldung:** Der aktuelle Code führt bereits den Supabase-Signout der bisherigen Sitzung aus und entfernt lokalen SecureStorage. Der alte Befund „nur lokal“ ist überholt. Bei Offline-Abmeldung oder einer bereits ausgegebenen, noch gültigen Access-Token-Laufzeit wird kein sofortiger globaler Tokenwiderruf behauptet.

## Verifikation

| Prüfung | Ergebnis | Grenze |
|---|---:|---|
| Node: KI-Budget, Themen-/Übersetzungs-/Kartengenerierung und Cache | 88 Tests bestanden | Mocks und lokale Verträge |
| Deno: Löschung, Billing, Complimentary, Webhooks, redaktioneller Schutz | 47 Tests bestanden | Keine echten Storekäufe |
| PostgreSQL/PGlite | 11 Assertionsgruppen bestanden | Cron und echte Parallelität separat live |
| Flutter: Auth, Übersetzungen, Themenclient/-UI/-Integration | 59 Tests bestanden | Vor dem zusätzlich ergänzten Clienttest |
| Flutter: finaler Themenclient inklusive neuer Fehlermeldungen | 8 Tests bestanden | Überschneidet sich mit vorheriger Suite |
| Flutter: Rechtstexte und persönlicher Retry-Client | 13 Tests bestanden | Keine rechtliche Inhaltsfreigabe |
| Flutter Analyze: sechs betroffene Dateien | Keine Issues | Keine vollständige App-Sicherheitsgarantie |
| Deno Check: fünf veröffentlichte Einstiegspunkte | Erfolgreich | Typprüfung |
| Live-Supabase | 31 Kontrollen bestanden | Synthetische Testkonten; alle drei gelöscht |
| iOS-Simulatorbuild, Installation und Start | Erfolgreich | Kein signiertes App-Store-Archiv |
| iOS-Backupattribut am gestarteten Appverzeichnis | `true` | Kein physischer Backup-Restore |
| Android-Debugbuild | Erfolgreich | Kein neuer signierter Produktionsbuild |
| Begrenzter Secret-Scan | 1.499 Textdateien, 0 Mustertreffer | Kein vollständiger Git-Historien-/Binärscan |
| OSV für gesperrte hosted Pub-Pakete | 167 Pakete, 0 Treffer | Datenbankstand und Ökosystemabdeckung |
| Supabase Security Advisor danach | Eine verbleibende Passwort-Warnung | Keine Aussage über jeden möglichen Angriff |

Der erste Aufruf der Rechtstexttests verwendete einen nicht existierenden Dateinamen; danach wurden die tatsächlich vorhandenen Tests unter `test/legal/` erfolgreich ausgeführt. Der erste Abhängigkeitsscanner fand lokal kein PyYAML; die Lockdatei wurde anschließend ohne zusätzliche Projektabhängigkeit ausgewertet. Diese Aufrufe sind keine nachträglich verschwiegenen Produktfehler.

GitNexus wurde an den aktuellen Checkout gebunden und neu indexiert. Der Index meldete Beschränkungen bei einzelnen dynamischen bzw. sprachübergreifenden Aufrufen und der Flow-Auswahl. Die anfänglichen unvollständigen Methodenauflösungen wurden daher durch direkte Aufruferprüfung ergänzt. Die finale strukturierte Änderungsanalyse meldete 64 Symbole in 27 getrackten Dateien und 17 betroffene Abläufe, Risiko `critical`, ohne `partial`- oder `truncated`-Markierung. Sie umfasst auch bereits vorhandene Billingänderungen; neue ungetrackte Dateien wurden zusätzlich direkt gelesen und getestet. Das ist keine Entwarnung. Konkrete Regressionen und Liveprüfungen tragen den Funktionsnachweis. Ein automatischer Taint-Pentest wurde nicht behauptet.

Nachweise liegen in [security-fixes-evidence-2026-11-01](security-fixes-evidence-2026-11-01/). Logs enthalten synthetische Inhalte oder technische Statusangaben; keine produktiven Zugangsdaten. Quellhashes binden die geprüften Kernstellen an diesen Stand. Alle verbleibenden Aussagen sind bewusst enger als „die gesamte App ist sicher“ oder „Apple wird sie akzeptieren“.
