# Release- und Cybersecurity-Prüfung der Sprachapp

**Stand: 30.10.2026. Urteil: Der untersuchte Stand ist noch nicht für eine öffentliche Veröffentlichung zu empfehlen.**

Es gibt belegte unfertige Funktionen in der normalen Benutzeroberfläche, insbesondere bei Datenschutz, Anmeldung und Premium. Zusätzlich bestehen konkrete Sicherheits- und Datenschutzrisiken bei Abmeldung, lokalen Daten und Aufbewahrung. Ein uneingeschränktes „releasefähig“ wäre deshalb nicht durch die vorliegenden Nachweise gedeckt. Das ist eine technische Risikobewertung, keine Vorhersage einer garantierten Apple-Entscheidung und keine vollständige rechtliche Freigabe.

**Es wurden keine dieser Probleme behoben.** Quellcode, Datenbankschema, Cloudkonfiguration, Store-Einträge und Berechtigungen wurden für diesen Audit nicht geändert. Neu sind dieser Bericht, seine Prüfnachweise und die Dokumentation des geänderten Arbeitsumfangs.

## 1. Geänderter Auftrag und tatsächlicher Lieferstand

Der Nutzer hat die weitere Erstellung von Geschichten und die übrigen App-Erweiterungen abgebrochen und stattdessen diesen Audit priorisiert. Zu diesem Zeitpunkt waren alle **39 vorhandenen Transkripte in fünf Sprachen** bearbeitet. Quelle 37 fehlt im ursprünglichen Material. Es war kein weiteres Transkript in Arbeit. Die nächste erfundene Geschichte war noch nicht begonnen.

Der vorhandene Ordner enthält **285 Texte**: 195 Transkriptfassungen und 90 Fassungen selbst verfasster Geschichten. Zehn zuvor geplante Texte wurden auf Wunsch nicht mehr erstellt. Der Inhaltsprüfer meldet weiterhin 40 Längenkonflikte bei acht kurzen Quellen in jeweils fünf Sprachen. Diese wurden weder versteckt noch durch aufgefüllte Texte oder gelockerte Prüfregeln beseitigt. Die neuen Textdateien sind **nicht als vollständig eingebundener Produktionskatalog** anzusehen. Ein Ordner mit Texten ersetzt weder annotierte Inhaltspakete noch App-Integration.

Bereits vorhandene Änderungen an Lesefortschritt, Auswahlmarkierung und Lernhinweis bleiben bestehen. Die restliche Anführungszeichenbehandlung, neue Katalogintegration und abschließende Geräteauslieferung werden nach der geänderten Anweisung nicht weiter umgesetzt. Diese offenen Punkte sind keine später noch automatisch auszuführende Aufgabenliste.

## 2. Untersuchungsumfang und Nachweise

### 2.1 Stand und Methode

- Repository: `sprachapp`, Basiscommit `d2c276d8e2e5f9f32494c66330019dd3f1bebb12`, einschließlich vorhandener uncommitteter Änderungen.
- Architektur: Flutter/Dart, iOS und Android, lokale SQLite-/JSON-Daten, Supabase Auth, Datenbank und Edge Functions, serverseitige Anthropic-Aufrufe, native Sprachausgabe.
- Modi: statische lokale Prüfung und isolierte vorhandene Tests; öffentliche Dokumentation und OSV-Abfrage als passive externe Prüfung.
- Keine Angriffstests gegen Produktivnutzer, kein Aufruf kostenpflichtiger KI-Generierung, keine Veröffentlichung, kein Penetrationstest gegen Supabase, kein neuer signierter Store-Build.
- App Store Connect, tatsächlich deployte SQL-Rechte, Provider-Verträge, Rechnungsgrenzen und Live-Auth-Einstellungen wurden nicht aus einem angemeldeten Dashboard geprüft.
- GitNexus wurde für Auth-/Übersetzungs- und Inhaltsflüsse verwendet. Der Taint-Aufruf meldete ausdrücklich **keine vorhandene Taint-Schicht**. „0 findings“ ist deshalb hier kein Nachweis eines sicheren Datenflusses. Der CLI-Befehl `explain` war nicht verfügbar; der MCP-Aufruf bestätigte die fehlende Schicht.

**Belegstatus:** „Belegt“ bedeutet im aktuellen Code oder Prüfoutput nachvollziehbar. „Abgeleitet“ bezeichnet eine plausible Folge mit benannten Voraussetzungen. „Offen“ verlangt zusätzliche Laufzeit-, Build- oder Dashboard-Nachweise. Dateiangaben sind relativ zum Repository; Zeilen beziehen sich auf diesen Prüfstand. Die SHA-256-Werte der zentralen Quellen stehen in [source-hashes.json](release-security-evidence/source-hashes.json).

### 2.2 Eingesetzte gewünschte Skills

| Gewünschte Quelle | Tatsächlich angewandter Schwerpunkt |
|---|---|
| [cruisediary/apple-app-review-skills](https://github.com/cruisediary/apple-app-review-skills) | Full-Audit-Routing, 31 Themen zu Qualität, Datenschutz, Geschäftsfunktionen, Metadaten, UGC, Layout und Berechtigungen |
| [JustinPerea/app-store-review-skill](https://github.com/JustinPerea/app-store-review-skill) | Targetinventar, 53 Release-Prüfpunkte, Qualitäts- und externe Verifikationscheckliste |
| [raroque/vibe-security-skill](https://github.com/raroque/vibe-security-skill) | Secrets, RLS, Auth, Kostenmissbrauch, KI-Eingaben, Ausgaben, Client-Vertrauen |
| [dweinstein/mobile-security-skills](https://github.com/dweinstein/mobile-security-skills) | Auth-Assessment, Secure-Storage-Audit, Network-Security-Check und MASTG-orientierte Restprüfung |
| [Masriyan/Claude-Code-CyberSecurity-Skill](https://github.com/Masriyan/Claude-Code-CyberSecurity-Skill) | Vulnerability Scanner und AI/LLM Security; Trennung beobachtet/abgeleitet/offen, Abhängigkeiten und Evidenz |

Verwendet wurden die installierten lokalen `SKILL.md`-Fassungen. Skill-Heuristiken sind keine Apple-Regeln: Weder ein fehlendes eigenes Runner-Privacy-Manifest noch fehlendes Certificate Pinning, ein beliebiger TODO-Kommentar oder eine Versionsnummer unter 1.0 allein beweisen eine Ablehnung. Der explizite Auftrag „ohne etwas zu lösen“ hat Vorrang vor automatischen Fix-Angeboten einzelner Skills.

### 2.3 Tatsächlich ausgeführte Prüfungen

| Prüfung | Ergebnis | Aussagegrenze |
|---|---|---|
| Vier Flutter-Testsuiten zu Auth, Translation Cache, Runtime Translation und Consent | **45 Tests bestanden** | Isolierte Tests, kein Nachweis für Live-RLS, Apple-Login oder StoreKit |
| `flutter analyze` | **1 Info**, `avoid_print` in `test/data/baseline_adoption_pack_test.dart:43` | Kein Fehler im Produktionscode gemeldet, kein Security-Zertifikat |
| OSV-Abfrage für aufgelöste hosted Pub-Pakete | **154 Pakete, 0 Treffer** | Datenbankstand der Abfrage; keine vollständige Abdeckung nativer SDKs, Flutter Engine oder Python-Werkzeuge |
| Begrenzter Secret-Musterscan getrackter Textdateien | **1.080 Dateien**, zwei Treffer in Skill-Dokumentation | Beide AWS-Beispielwerte; keine bestätigten produktiven Credentials in diesen Treffern |
| Inhaltsinventar | **285 vorhanden**, zehn aus altem Plan fehlen, 40 Längenkonflikte | Kein Beweis der Produktionsintegration oder vollständiger Sprach-/Faktenfreigabe |
| iOS-Konfiguration und vorhandene Build-Artefakte | SDK-Manifeste, App-Icon und Release-Scheme untersucht | Vorhandenes lokales Artefakt ist kein neu validiertes App-Store-Archiv |

Prüfdateien: [Tests](release-security-evidence/tests.log), [Analyse](release-security-evidence/analyze.log), [OSV](release-security-evidence/osv.json), [Secret-Scan](release-security-evidence/secret-scan.json), [Graph-Abfrage](release-security-evidence/graph.txt).

## 3. Priorisierte Befundübersicht

| ID | Priorität | Status | Befund | Bedeutung |
|---|---|---|---|---|
| A01 | Hoch | Belegt | Datenschutz- und AGB-Aktionen sind Platzhalter | Öffentliche Einreichung so nicht empfehlen |
| A02 | Hoch | Belegt | Premium-Kauf und Wiederherstellung nicht implementiert | Sichtbares Angebot funktioniert nicht |
| A03 | Hoch | Belegt | Onboarding-Anmeldung ist Platzhalter | Apple-/Google-/E-Mail-Auswahl meldet nicht an |
| A04 | Mittel | Belegt | Vorschauen und kommende Funktionen in normaler Oberfläche | Unfertiger Produktzustand sichtbar |
| A05 | Hoch als Freigabeprüfung | Offen | Öffentlicher Inhalt, Rechte, Alterseinstufung und Review-Zugang | Produktionsangebot nicht vollständig nachgewiesen |
| S01 | Mittel | Belegt | Logout widerruft keine Serversitzung | Kopierte Refresh-Tokens werden dadurch nicht entwertet |
| S02 | Mittel, datenabhängig | Belegt/abgeleitet | Private Texte lokal ohne zusätzliche DB-Verschlüsselung und ohne passende Android-Backup-Ausschlüsse | Schutz hängt stark von Gerät und Backup ab |
| S03 | Mittel | Belegt/abgeleitet | Ablaufzeit ist keine garantierte physische Löschung | 30-Tage-Speicheraussage nicht durch zeitgesteuerte Bereinigung belegt |
| S04 | Hoch für Android-Release | Belegt | Release verwendet Debug-Signierung | Kein sauberer Produktions-Signierungsweg |
| S05 | Mittel als Betriebsrisiko | Offen | Deployte RLS-, Kosten-, Auth- und Abuse-Konfiguration | Lokaler guter Code beweist nicht die Cloudkonfiguration |
| S06 | Niedrig bis mittel | Abgeleitet | Prompt Injection und falsche KI-Antworten bleiben möglich | Strukturelle Prüfung sichert nicht semantische Richtigkeit |

Keine bestätigte kritische Remote-Code-Ausführung, kein belegter fremder Kontozugriff und kein produktiver Secret-Leak wurden in diesem Umfang nachgewiesen. Das bedeutet ausdrücklich nicht, dass solche Fehler durch einen vollständigen Pentest ausgeschlossen wurden.

## 4. Apple-Release-Befunde im Detail

### A01 — Datenschutz und Nutzungsbedingungen sind nicht erreichbar

**Belegt, hoch.** `lib/screens/onboarding/paywall_screen.dart:131` setzt `_legal()` ausschließlich auf einen Hinweis, dass Rechtstexte später folgen. Die sichtbaren Aktionen „Nutzungsbedingungen“ und „Datenschutz“ rufen diese Methode in Zeilen 351–357 auf. Das ist kein funktionierender Link und keine Anzeige eines Rechtstextes. Die Daten-/Datenschutzsektion in `lib/screens/settings/settings_screen.dart:277` enthält Einwilligungsschalter und Cache-Löschung, aber diese ersetzen keine vollständige Datenschutzerklärung.

**Folge:** Nutzer können den angekündigten Rechtstext an der angebotenen Stelle nicht lesen. Eine eventuell extern in App Store Connect hinterlegte URL würde diesen belegten UI-Fehler nicht beseitigen. Ob dort überhaupt eine URL hinterlegt ist, ist offen.

**Regelbezug:** 5.1.1(i), zusätzlich Vollständigkeit 2.1. Apples [Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) verlangen zugängliche Datenschutzinformationen und eine vollständige Einreichung. Die übrige Bewertung hier folgt aus dem konkret gelesenen Code.

**Vor Freigabe nachzuweisen:** Auf dem tatsächlichen Release-Gerät müssen beide Aktionen reale, passende Dokumente öffnen. Inhaltlich sind Betreiber, Kontakt, Datenarten, Zwecke, Empfänger, Aufbewahrung, Löschung und der Anthropic-Datenfluss zu klären. Es wurde kein Rechtstext erfunden und keiner eingebaut.

### A02 — Premium-Verkauf und Restore sind Attrappen

**Belegt, hoch.** `paywall_screen.dart:115` öffnet eine Provider-Auswahl und beendet danach den Ablauf mit „Käufe sind in dieser Version noch nicht freigeschaltet“. `_restore()` in Zeile 128 zeigt ebenfalls nur einen Zukunftshinweis. Zugleich steht in Zeile 329 „Premium abonnieren“. Preise von 49,99 € jährlich und 9,99 € monatlich sind im Enum in Zeilen 15–28 fest verdrahtet.

**Folge:** Die präsentierte kaufbare Leistung kann nicht gekauft oder wiederhergestellt werden. Es gibt hier keinen bestätigten Geldverlust und keinen nachgewiesenen illegalen externen Zahlungsweg. Das Problem ist ein unfertiges, sichtbares Verkaufsangebot. Die Texte nennen Laufzeit und Verlängerung bereits, was positiv ist, aber den fehlenden Kaufvertrag nicht ersetzt.

**Regelbezug:** 2.1; bei tatsächlicher digitaler Monetarisierung 3.1.1/3.1.2. Regionale Ausnahmen zu Zahlungswegen werden nicht pauschal ausgeschlossen.

**Vor Freigabe nachzuweisen:** Entweder ein konsistentes kostenloses Release ohne leeres Verkaufsversprechen oder ein tatsächlich getesteter Kauf-/Restore-/Entitlement-Prozess. Store-Produkte, lokalisierte Preise, Abbruch, ausstehende Zahlung, Erstattung und erneute Installation sind aktuell nicht nachgewiesen. Keine Zahlungsintegration wurde hinzugefügt.

### A03 — Die Anmeldung im Onboarding meldet niemanden an

**Belegt, hoch.** `lib/screens/onboarding/onboarding_screen.dart:138` bezeichnet den Pfad ausdrücklich als Platzhalter. `_signIn()` zeigt in Zeilen 140–151 „Anmeldung ... kommt bald“ und beendet das Onboarding ohne Konto. Die Auswahl in `widgets/account_sheet.dart:132` gibt lediglich den Provider zurück.

**Folge:** Der normale Einstieg bietet eine Funktion an, die nicht ausgeführt wird. Es handelt sich nicht um eine Umgehung der echten Supabase-Authentifizierung: Der getrennte Inhaltsupdate-Login nutzt wirkliche OTP-/Passwort-Aufrufe. Die zwei Oberflächen suggerieren aber unterschiedliche Kontofähigkeiten.

**Regelbezug:** 2.1 und korrekte Funktionsdarstellung 2.3.1. Eine eigenständige Verletzung von „Sign in with Apple“ ist daraus nicht bewiesen: Auch der angebotene Google-Login ist kein implementierter Social-Login.

**Vor Freigabe nachzuweisen:** Ein verständlicher, funktionierender Kontoweg oder ein bewusst kontoloser Einstieg. Bei künftig echtem Social-Login sind die dann anwendbaren Login-Regeln gesondert zu bewerten.

### A04 — Interne Vorschauen und Zukunftsfunktionen sind öffentlich erreichbar

**Belegt, mittel.** `lib/screens/settings/settings_screen.dart:316` bietet „Bildschirm-Vorschauen“ ohne erkennbaren Debug-Guard. Zeilen 240–274 zeigen kommende Erinnerungen, Tonoptionen, Audiogeschwindigkeit und Spracheingabe als deaktivierte Funktionen.

**Folge:** Die App wirkt an diesen Stellen noch wie ein Entwicklungsstand. Die Kennzeichnung „noch nicht verfügbar“ ist ehrlicher als ein lautloser leeren Button, kann aber trotzdem gegen eine behauptete vollständige Produktfunktion sprechen. Dass eine Vorschau sicherheitskritische Adminrechte öffnet, wurde nicht belegt.

**Regelbezug:** Vollständigkeit 2.1 und korrekte Metadaten 2.3.1. Ein optionaler deaktivierter Schalter allein garantiert keine Ablehnung. Der Gesamteindruck mit A01–A03 erhöht jedoch das Risiko.

**Vor Freigabe nachzuweisen:** Review-relevante Wege dürfen nicht unklar zwischen Demo und echtem Produkt wechseln. Marketing darf diese Zukunftsfunktionen nicht als verfügbar nennen.

### A05 — Inhalte, Rechte und öffentlicher Vertriebsweg sind nicht freigegeben

**Offene Freigabeprüfung, potenziell hoch.** `lib/data/content/content_release_client.dart:56` akzeptiert ausdrücklich `channel == internal` und `internal_test_pack == true`. `content_auth_repository.dart:92` fordert OTP mit `shouldCreateUser: false` an. `pubspec.yaml` bindet Inhaltspaketordner ein, nicht die neuen `story_library`-Textdateien. Die Paketdateien sind teilweise absichtlich gitignoriert. Diese Tatsachen sind nicht automatisch Fehler, verlangen aber eine Prüfung des tatsächlichen Versandartefakts.

**Folge:** Ein Build aus einem anderen Checkout könnte ein anderes Inhaltsangebot enthalten. Öffentliche Käufer und Apple-Reviewer benötigen einen funktionierenden, dokumentierten Weg zu versprochenen Funktionen. Die bloße Existenz neuer Geschichten im Arbeitsordner beweist nicht, dass sie in der App erscheinen.

**Urheberrechte:** Die Überarbeitung, Kürzung oder Übersetzung fremder YouTube-Transkripte beweist keine Veröffentlichungslizenz. In diesem Audit wurden keine Rechteketten oder individuellen Genehmigungen verifiziert. Das ist keine Feststellung, dass der Nutzer keine Rechte besitzt. Vor einer Veröffentlichung ist für jede übernommene Quelle zu belegen, welche Nutzungsrechte vorliegen. Wiktionary-Attribution ist eine andere Quelle und löst die Rechtefrage der Videos nicht.

**Alter und Inhalt:** Die Redaktion enthält unter anderem DMT-/Drogenthemen. Sachliche Bildungsinhalte sind nicht allein dadurch verboten. Die Alterseinstufung muss aber zum tatsächlich ausgelieferten Katalog passen. Ein pauschales niedriges Rating oder eine Kinderkategorie ist nicht belegt. Maßstab ist Apples aktueller [Fragebogen zur Alterseinstufung](https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions/), nicht eine aus alten Skills übernommene feste Alterszahl.

**Vor Freigabe nachzuweisen:** Inhaltsinventar des Archives, Rechtebelege, korrekte Altersantworten und ein reproduzierbarer Reviewer-Zugang. Die abgebrochenen neuen Geschichten müssen dafür nicht nachträglich fertiggeschrieben werden.

## 5. Cybersecurity-Befunde im Detail

### S01 — Abmeldung entfernt nur die lokale Sitzung

**Belegt, mittel; MASVS-AUTH.** `lib/data/content/content_auth_repository.dart:155–161` erstellt einen neuen Client, benachrichtigt lokale Beobachter, löscht den Secure-Storage-Eintrag und schließt den alten Client. Ein `auth.signOut()` oder anderer serverseitiger Widerruf wird nicht aufgerufen.

**Angriffsvoraussetzung:** Ein Angreifer müsste zuvor eine Kopie eines Tokens erlangt haben. Dieser Audit weist einen solchen Diebstahl nicht nach. Die Lücke erzeugt keinen Token von selbst.

**Auswirkung:** Die lokale Abmeldung entwertet die kopierte Refresh-Sitzung nicht. Der Nutzer kann deshalb annehmen, einen Zugang beendet zu haben, obwohl die serverseitige Sitzung weiter existiert. Bereits ausgestellte Access-Tokens können auch bei einem korrekten Supabase-Logout bis zum Ablauf gültig bleiben; das ist vom fehlenden Refresh-Widerruf zu unterscheiden. [Supabase dokumentiert Logout-Scopes und Tokenverhalten](https://supabase.com/docs/guides/auth/signout).

**Späterer Nachweis:** In einer kontrollierten Testsitzung Refresh vor und nach Abmeldung prüfen, inklusive Offline-Abmeldung und anderer Geräte. Keine fremden Tokens verwenden. Server-Widerruf und Offline-Verhalten wären gesondert zu entwerfen; hier nicht geändert.

### S02 — Private Inhalte und Backups brauchen eine bewusste Schutzentscheidung

**Belegt/abgeleitet, mittel je nach Inhalt; MASVS-STORAGE/PRIVACY.** `lib/presentation/providers/runtime_translation_provider.dart:20–25` öffnet `private_translations.sqlite` mit gewöhnlichem SQLite im App-Support-Verzeichnis. `lib/data/translation_cache.dart:18` speichert Antworten als Text. `PRAGMA secure_delete` in Zeile 16 ist keine Verschlüsselung.

Eigene importierte Texte werden durch `lib/main.dart:61–65` und `lib/presentation/providers/reading_providers.dart:32–55` als JSON im Support-Verzeichnis gespeichert. Die Android-Dateien `res/xml/backup_rules.xml` und `data_extraction_rules.xml` schließen nur zwei Secure-Storage-Preference-Dateien aus, nicht diese Inhalte. Das Manifest verwendet beide Regeln in Zeilen 7–8.

**Auswirkung:** Wer rechtmäßig oder unrechtmäßig Zugriff auf entschlüsselte App-Dateien, ein geeignetes Backup oder ein kompromittiertes Gerät erhält, kann private Inhalte lesen. Normale fremde Apps haben dadurch nicht automatisch Zugriff: Sandbox und Geräteschutz gelten weiterhin. [Android Auto Backup](https://developer.android.com/identity/data/autobackup) hat eigene Verschlüsselungs- und Gerätevoraussetzungen; „alles wird unverschlüsselt öffentlich hochgeladen“ wäre eine falsche Behauptung.

**Offen:** Tatsächlicher Backup-Inhalt auf Zielgeräten, iOS-Dateischutzklassen und iCloud-Backup-Verhalten, Empfindlichkeit der Nutzertexte. Keine zusätzlichen Ausschlüsse oder Kryptografie eingebaut.

**Späterer Nachweis:** Ausschließlich synthetische Texte importieren, Gerät sperren, Backup/Restore und Datenexport untersuchen. Eine Produktentscheidung muss klären, ob private Importe gesichert werden sollen, ausgeschlossen werden oder zusätzlichen Schutz benötigen.

### S03 — Ablaufende Cacheeinträge werden nur bei Aktivität bereinigt

**Belegt/abgeleitet, mittel; MASVS-PRIVACY/STORAGE.** `supabase/migrations/20261024000001_private_translation_cache.sql:28–29` löscht abgelaufene Einträge beim nächsten Claim. `20261025000002_personal_learning_retry_retention.sql:11–13` entfernt abgelaufene Antwortdaten ebenfalls im Claim-Pfad. Lokal bereinigt `translation_cache.dart:24` bei Datenbanköffnung. Ein zeitgesteuerter Cleanup ist in den geprüften Migrationen nicht enthalten.

**Wichtig:** Abgelaufene Antworten werden nicht einfach weiterhin als gültige Cachetreffer angeboten. Das Problem betrifft physische Aufbewahrung, nicht allein Wiederverwendung. Die Onboarding-Aussage in `onboarding_screen.dart:27` spricht von „30 Tage privat gespeichert“, während die detaillierte Wortfreigabe präziser eine Wiederverwendung bis zu 30 Tagen beschreibt.

**Auswirkung:** Bleibt weitere Aktivität aus, können Antwortdaten länger in der Datenbank liegen. Zusätzlich haben Datenbanksicherungen und der externe KI-Provider eigene Aufbewahrungsregeln. Ein nicht eingesehener produktiver Cleanup-Job könnte das Risiko reduzieren, ist aber nicht belegt.

**Späterer Nachweis:** Staging-Eintrag ablaufen lassen, ohne weitere Claims den tatsächlichen Löschzeitpunkt beobachten, Scheduler und Backup-Retention dokumentieren. Nutzerzusagen gegen diese Zeiten prüfen. Keine Daten gelöscht und kein Scheduler angelegt.

### S04 — Android-Release ist mit Debug-Schlüssel konfiguriert

**Belegt, hoch für Android-Veröffentlichung.** `android/app/build.gradle.kts:32–36` weist dem Release-Build `signingConfigs.getByName("debug")` zu. Die Application-ID ist in Zeile 19 noch `com.example.sprachapp`.

**Auswirkung:** Die Release-Konfiguration hat keinen nachgewiesenen produktiven Upload-/Signing-Weg. Ein Debug-Zertifikat ist nicht die gewünschte stabile Produktionsidentität. Daraus folgt nicht, dass der konkrete private Schlüssel öffentlich bekannt wäre. Die Beispiel-ID ist ein Identitäts-/Vorbereitungsproblem, keine eigenständige Exploit-Lücke.

**Späterer Nachweis:** Zertifikat und Paketidentität des tatsächlich hochgeladenen AAB prüfen, Upload-Key/Play App Signing und Updatepfad dokumentieren. Grundlage: [Android App Signing](https://developer.android.com/studio/publish/app-signing). Dies ist kein iOS-Blocker, gehört aber zum gewünschten plattformübergreifenden Bericht.

### S05 — Cloudschutz ist lokal gut angelegt, produktiv nicht bewiesen

**Offen; Betriebsrisiko, keine bestätigte RLS-Umgehung.** In `20261003000003_app_tables.sql:148–191` sind RLS, eigene User-Zeilen, WITH CHECK und getrennte Grants vorhanden. `app.usage` ist für Nutzer nur lesbar. Private Cache-/Jobtabellen sind zusätzlich von direkten Nutzerrechten ausgeschlossen. Service-Funktionen widerrufen öffentliche Ausführungsrechte.

`reserve_runtime_translation` prüft interne Leserfreigaben und begrenzt atomar auf **5 Anfragen pro Minute pro Nutzer, 20 pro Tag pro Nutzer und 1.000 pro Tag insgesamt**. Beleg: `20261019000001_runtime_translation_limits.sql:9–21`. Das ist wesentlich besser als ein manipulierbarer Clientzähler. Es ist trotzdem kein exaktes Geldbudget: verschiedene Anfragen können unterschiedlich viele Tokens kosten.

**Restgefahren:** Abweichende deployte Migrationen, zu breite Admin-Mitgliedschaften, fehlerhafte Bucketregeln, Auth-Missbrauch, viele billige Cache-/Fehleranfragen, Konkurrenz am globalen Advisory-Lock oder falsch konfigurierte Providergrenzen. Die lokal eingetragenen Supabase-Auth-Werte belegen die Cloudwerte nicht.

**Späterer Nachweis:** Zwei synthetische Nutzer gegeneinander testen, Service-RPCs als anon/authenticated negativ prüfen, eigene/fremde Storagepfade testen, deployed Grants exportieren und Last-/Kostenalarmierung belegen. Dieser Audit hat keine produktiven Daten oder Rollen verändert.

### S06 — KI-Eingaben können trotz Strukturprüfung falsche Ausgaben erzeugen

**Abgeleitet, niedrig bis mittel; OWASP-LLM-Risikokategorie Prompt Injection/Output Handling.** `runtime_translation.ts:270–278` trennt Systemanweisung und Benutzerdaten, verlangt ein Schema und weist auf nicht vertrauenswürdigen Text hin. Der Personal-Learning-Pfad hat entsprechende Maßnahmen in `personal_learning.ts:172–175` und zusätzliche Antwortvalidierung.

**Positiv:** Keine frei verfügbaren Shell-/Datei-/Browser-Werkzeuge für das Modell in diesen Aufrufen. Ausgaben werden nicht als ausführbares Programm behandelt. Eingabegröße, Ausgabegröße, Tokenmenge und Deadline sind begrenzt. Authentifizierung erfolgt über `/auth/v1/user`, nicht allein durch unprüfbares JWT-Decoding.

**Restgefahr:** Ein Text kann die semantische Übersetzung oder Karte beeinflussen, obwohl das JSON gültig ist. Das wäre zunächst falscher Lerninhalt, nicht automatisch Zugriff auf andere Nutzerkonten. Ein tatsächlicher erfolgreicher Angriff wurde hier nicht ausgeführt.

**Späterer Nachweis:** Kleine synthetische Testsammlung mit eingebetteten Instruktionen, mehrdeutigen Wörtern und manipulierten Kandidaten; sowohl strukturelle Ablehnung als auch fachliche Richtigkeit prüfen. Keine kostenpflichtigen Provider-Tests durchgeführt.

## 6. Was bereits richtig umgesetzt ist

- **Tokenablage:** `content_auth_repository.dart:130–136` schreibt Sitzungen in `FlutterSecureStorage`, nicht in gewöhnliche JSON-Preferences. Der lokale JSON-Datenbefund betrifft keine nachgewiesene Passwortspeicherung.
- **Keine Provider-Secrets im normalen Clientpfad:** KI wird über Edge Functions aufgerufen. Die Clientkonfiguration weist bekannte Server-Key-Formate ausdrücklich zurück (`content_auth_repository.dart:52–63`). Ein Supabase-Publishable-/Anon-Key ist nicht schon aufgrund seiner Sichtbarkeit ein Secret-Leak.
- **Echte Serveridentität:** `runtime_translation.ts:174–199` holt den Nutzer vom Auth-Server und lehnt anonyme Nutzer ab. Benutzer-IDs aus dem Request bestimmen nicht allein die Zugriffsrechte.
- **RLS und Budgets:** Eigene Zeilen, Service-only-RPCs und atomare Reservierung sind in Migrationen vorhanden. Die Tests beweisen allerdings nicht deren Live-Deployment.
- **Begrenzte Übertragung:** Runtime-Request 4 KiB, Satzlänge 600, Antwortgrenzen und Timeout sind im Serverpfad sichtbar. Fehlertexte geben keine vollständigen Providerantworten preis.
- **Downloadschutz:** `content_release_client.dart:245–266` begrenzt Downloadziele auf den Projektursprung und deaktiviert Redirects. Manifest-/Paketgröße und SHA-256 werden geprüft. Ein Prüfsummenvergleich ist Integritätsschutz, kein unabhängiger Ersatz für das Vertrauen in den Server.
- **KI-Einwilligung:** `word_cloud_consent.dart:9–16` benennt Wort, vollständigen Satz, Anthropic, fehlende EU-Garantie und Widerruf. `personal_learning_button.dart:18–41` verlangt eine ausdrückliche Bestätigung. Deshalb kein pauschaler Befund „keine KI-Einwilligung“.
- **TTS:** `device_speech_playback.dart:65–78` filtert unter Android Stimmen mit Netzwerkbedarf und nicht installierte Stimmen aus. Fehlende Stimmen erhalten in Zeile 206 eine erklärende Meldung. Nicht behaupten, jede Sprache sei ohne Sprachdownload auf jedem Gerät verfügbar.
- **Logs:** Der geprüfte Runtime-Erfolgspfad protokolliert Request-ID, Modell und Nutzung, nicht den Satz oder Tokeninhalt (`runtime_translation.ts:414–421`). Logkonfiguration und Aufbewahrung in der Cloud bleiben offen.

## 7. Apple-Prüfmatrix und bewusst vermiedene Fehlalarme

| Bereich | Ergebnis dieses Audits | Was noch fehlt |
|---|---|---|
| App-Targets | Runner und RunnerTests; keine zusätzliche Extension festgestellt | Endgültiges Archiv erneut inventarisieren |
| Version/SDK | 1.0.0+1; lokale aktuelle Xcode-/SDK-Installation, Release-Archive-Scheme | Upload des konkreten Archives, eindeutige Buildnummer |
| App-Icon/Launch | 1024er Icon ohne Alpha und LaunchScreen-Konfiguration vorhanden | Visuelle Marken-/Darstellungsprüfung im Release |
| iPad/Orientierung | iPad unterstützt, vier Orientierungen deklariert | Split View, kleine Fenster, Hardwarekeyboard und große Schrift real testen |
| Berechtigungen | Für reines Vorlesen kein Mikrofonzugriff nötig; Spracheingabe derzeit deaktiviert | Bei Aktivierung neue Purpose Strings und Zeitpunkt prüfen |
| Hintergrundbetrieb | Kein belegter Missbrauch durch stummes Daueraudio | Audio-Unterbrechung auf echtem Gerät prüfen |
| Privacy Manifest | SDK-Manifeste in vorhandenen Artefakten vorhanden | Aggregierten Privacy Report des neuen Archives prüfen |
| ATT/Tracking | Kein Ad-/Tracking-SDK im untersuchten Kernpfad belegt | SDK-Netzwerkverkehr und Store-Angaben abgleichen |
| Datenschutzerklärung | Belegter Platzhalter, A01 | Echte Erklärung in App und Store |
| KI-Offenlegung | Vorhanden, positive Teilprüfung | Providerverträge, tatsächliche Datenkategorien, Retention |
| Accountlöschung | Kein fertiger Löschpfad gefunden; nur eingeladener echter Login | Anwendbarkeit am endgültigen Accountprodukt beurteilen |
| Sign in with Apple | Onboarding-Login insgesamt Attrappe, A03 | Reale Loginwege und Ausnahmen beurteilen |
| IAP/Restore | Belegte Platzhalter, A02 | Falls Premium bleibt: Store-Sandbox und Entitlements |
| Abo-Preise | Fest im UI, kein Produktpreisabruf | Storefront und lokalisierte Gesamtpreise |
| UGC | Private Importe sind keine öffentliche Community | Bei öffentlichem Teilen Moderation/Report/Block neu prüfen |
| Mindestfunktion | Lernen, Wortlisten und Lesen sind reale Funktionen | Keine pauschale „zu wenig Funktion“-Ablehnung behauptet |
| Metadaten | Storebeschreibung und Screenshots nicht eingesehen | Nur tatsächlich funktionierende Features bewerben |
| Alter/Kinder | Keine abschließende Bewertung | Tatsächlichen Katalog, KI-Ausgaben und Zielgruppe prüfen |
| Export Compliance | Kein abschließender Store-Nachweis | Richtige Erklärung im Submission-Prozess |
| Lizenzen | Wörterbuchquellen-UI vorhanden | Vollständiges SDK-/Font-/Audio-/Transkriptrechteinventar |
| Private/deprecated APIs | Kein belastbarer Befund im geprüften Appcode | Finales Binary und SDKs validieren |
| VPN/HealthKit/Glücksspiel/Krypto-Mining | Keine relevante Implementierung festgestellt | Kein künstlich erfundener Pflichtverstoß |

**Accountlöschung:** Apple knüpft die In-App-Löschanforderung insbesondere an unterstützte Kontoerstellung. Der wirkliche OTP-Pfad setzt `shouldCreateUser: false`; ein Attrappen-Button beweist keine Kontoerstellung. Deshalb wird das fehlende Löschfeature als offene Produkt-/Datenschutzfrage geführt und nicht ohne Weiteres als sichere Apple-Ablehnung. Bei künftigem Signup muss die Anforderung neu bewertet werden. [Apple: Account Deletion](https://developer.apple.com/support/offering-account-deletion-in-your-app/).

**Privacy Manifest:** Einzelne SDKs liefern eigene Deklarationen. Das Fehlen einer Datei unter `ios/Runner` beweist für sich allein keinen Verstoß. Erforderlich ist die Zuordnung der tatsächlich verwendeten APIs zu den im Versandartefakt enthaltenen Gründen und Datenangaben. [Apple: Privacy Manifest Files](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files).

**Privacy Labels:** Aus diesem Audit lässt sich nicht „keine Daten erfasst“ ableiten. Authentifizierung, private Cloudübersetzungen und KI-Übermittlung sind tatsächliche Datenflüsse. Welche App-Store-Kategorien gelten, muss anhand ihrer Zwecke, Speicherung und Kontoverknüpfung bestimmt werden. [Apple: App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/).

**Kein Pinning-Befund:** Kein eigenes Pinning ist nicht automatisch ein ausnutzbarer Fehler. In den geprüften App-Netzwerkpfaden wurde kein pauschales Abschalten der Zertifikatsprüfung belegt. Root-/Jailbreak-Erkennung ist ebenfalls keine allgemeine Pflicht für eine Sprachlernapp.

## 8. Abhängigkeiten und Secrets: Grenzen der Aussage

Die OSV-Abfrage enthält alle 154 aufgelösten hosted Pub-Abhängigkeiten des gelesenen Lockfiles. Keine Antwort enthielt einen bekannten Treffer. Es wurden deshalb keine CVE-Nummern, Fixversionen, EPSS-Werte oder KEV-Zuordnungen erfunden. Das Ergebnis ist kein Beleg für Abwesenheit unbekannter oder noch nicht in OSV erfasster Schwachstellen.

**Nicht vollständig auditiert:** Flutter Engine, native SQLite-Binaries, Rive Native, CocoaPods-Transitives, Android-Gradle-Abhängigkeiten, Buildwerkzeuge und Python-Pipeline. Eine vollständige SBOM samt CVE-/Erreichbarkeitsabgleich bleibt ein Release-Nachweis. Für die oben beschriebenen eigenen Code-/Konfigurationsbefunde sind CVE, EPSS und KEV nicht zugeordnet. CVSS wird nicht künstlich numerisch präzisiert, wenn Exposition und Angriffsvoraussetzungen nicht dynamisch verifiziert sind.

Der Secret-Scan prüfte bekannte Token-/Private-Key-Muster in getrackten, lesbaren Dateien bis 2 MB. Zwei Treffer stammen aus Hindsight-Skill-Dokumentation mit offensichtlichen AWS-Beispielcredentials; sie wurden nicht als produktiver Leak gezählt. Es gab keinen vollständigen Git-History-Scan und keine Vollprüfung ignorierter Dateien oder des endgültigen App-Binaries. Reale Secrets wurden nicht in diesen Bericht kopiert.

`.gitignore` ignoriert `.env` und Supabase-CLI-Zustand. Daraus folgt nicht automatisch, dass jede denkbare anders benannte Secretdatei geschützt ist. Ein separater redigierter History-/Binary-Scan vor Veröffentlichung wäre sinnvoll, wurde aber nicht als bereits bestanden ausgegeben.

## 9. Noch notwendige Nachweise vor einer Freigabe

Dies sind Empfehlungen im Bericht, kein Auftrag zur automatischen Umsetzung.

### 9.1 Konkreter iOS-Release-Build

1. Das endgültige Archive mit den tatsächlich vorgesehenen Inhaltspaketen erzeugen und dessen Provenienz festhalten.
2. Datenschutz, Login, Kauf und Restore direkt aus frischer Installation bedienen; A01–A03 dürfen nicht als Attrappen sichtbar bleiben.
3. Apple-Validierung, Entitlements, Profile, Bundle-ID, Privacy Report und Exportfragen dokumentieren. Die lokal installierte SDK-Version beweist nicht den Inhalt des späteren Archives. [Apple: Submitting](https://developer.apple.com/app-store/submitting/).
4. Auf iPhone und iPad Onboarding, große Schrift, VoiceOver, Querformat, Split View, Popover und Tastatur prüfen. Kein kompletter visueller Accessibility-Pass wurde in diesem Audit durchgeführt.
5. Offline starten, fehlende Sprachstimme testen, Audio unterbrechen, App in Hintergrund schicken und erneut öffnen. Native Sprachqualität und Verfügbarkeit können je Gerät variieren.
6. App Store Connect: erreichbare Support-/Privacy-URLs, wahrheitsgemäße Screenshots, passende Altersangaben, Review-Notizen und zulässiger Zugang zu privaten Funktionen.

### 9.2 Datenschutz und Betriebsprozesse

1. Dateninventar für E-Mail/User-ID, Sitzungstokens, importierte Texte, Übersetzungsantworten, Lernkarten und Betriebslogs festhalten.
2. Supabase-/Anthropic-Verträge und tatsächliche Regionen prüfen. Aus EU-Supabase folgt keine ausschließliche EU-Verarbeitung bei Anthropic.
3. Aufbewahrungszeiten, Cache-Reuse, physische Löschung, Backups und etwaige gesetzliche Aufbewahrung getrennt beschreiben.
4. Account-/Datenlöschung, Auskunft und Kontaktweg als Produktentscheidung festlegen. Cache-Löschung ist nicht gleich Kontolöschung.
5. Keine fremden Originaltexte in Sicherheitsprüfungen an einen Provider senden; synthetische Testdaten reichen für die genannten Nachweise.

### 9.3 Gezielte Security-Abnahme

| Test | Erwarteter Nachweis | Aktueller Status |
|---|---|---|
| Zwei Nutzer, fremde Daten-/Storage-ID | Zugriff zuverlässig abgelehnt | Nur Quellcode geprüft |
| anon/authenticated ruft Service-RPC | Permission denied | Grants im Code geprüft, live offen |
| Abmelden und Refresh erneut versuchen | Bewusst definierte Sitzungsentwertung | S01 offen |
| Konto wechseln bei laufender Übersetzung | Keine Anzeige/Übernahme im falschen Konto | Lokale Tests bestanden, Gerät offen |
| Parallelrequests gegen Quota | Atomarer Grenzwert, keine Doppelabrechnung | SQL-Entwurf geprüft, Belastung offen |
| Langsamer/zu großer Request | Begrenzte Ressourcen, redigierter Fehler | Teilweise Code-/Testnachweis |
| Backup mit synthetischem Privattext | Dokumentiertes Wiederherstellungs-/Ausschlussverhalten | S02 offen |
| Ablauf ohne Folgeaktivität | Aufbewahrung entspricht Nutzeraussage | S03 offen |
| Manipulierter Inhaltsdownload | Hash-/Größen-/Schemafehler verhindern Installation | Schutzcode vorhanden, neues Artefakt offen |
| Release-APK/AAB und IPA untersuchen | Kein Debug-Signing/Secret, passende Permissions | Android-Konfigurationsbefund; finale Artefakte offen |
| KI-Instruktionen im Lerntext | Keine unerlaubte Aktion, sinnvolle oder abgelehnte Antwort | Nur statisch, keine Provider-Angriffstests |

Diese Matrix orientiert sich an MASVS-AUTH, STORAGE, NETWORK, PLATFORM, CODE und PRIVACY. Sie ist keine bestandene MASVS-Zertifizierung. [OWASP Mobile Application Security](https://owasp.org/projects/mobile-application-security).

## 10. Entscheidungshilfe

**Vor einer öffentlichen iOS-Einreichung zuerst klären:** echte Datenschutz-/Rechtstexte, das unfertige Kauf-/Restore-Angebot und die Attrappen-Anmeldung. Danach Produktumfang, Versandinhalt, Rechte und Review-Zugang festlegen. Die bereits vorhandene KI-Einwilligung sollte nicht pauschal als fehlend behandelt werden.

**Sicherheitspriorität:** Sitzungswiderruf, Schutz und Backup privater Texte, belastbare Aufbewahrung sowie Nachweis der deployten Rechte und Kostenbegrenzung. Für Android kommt die Release-Signierung hinzu.

**Unverändert gelassen:** sämtliche beschriebenen Implementierungen. Es gab weder einen stillen Fix noch eine Cloudänderung oder Veröffentlichung. Die abgebrochene Story-/App-Arbeit wird nicht als abgeschlossen umgedeutet; sie ist durch die spätere Nutzeranweisung aus dem restlichen Auftrag entfernt.

## Anhang A — Zusätzliche Build- und Qualitätsbeobachtungen

### A.1 Konkret geprüfte iOS-Konfiguration

Die Targetliste steht in `ios/Runner.xcodeproj/project.pbxproj:177–221`. Sie enthält Runner und RunnerTests. Die Bundle-ID `com.example.sprachapp` erscheint unter anderem in Zeile 479. Eine solche Beispiel-ID ist nicht von sich aus ein Apple-Verbot, muss aber zu Team, App Store Connect und dauerhafter Produktidentität passen. Das Deployment Target ist iOS 15; die App ist für iPhone und iPad konfiguriert. Das Archive-Scheme in `ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme:115` verwendet Release.

Die lokale Werkzeugprüfung ergab Xcode 27.1, Build 27A9275 und iPhoneOS SDK 27.1. Das bereits vorhandene `build/ios/iphoneos/Runner.app` nennt ebenfalls `iphoneos27.1`. Die Werte beschreiben die vorgefundene Entwicklungsumgebung, nicht einen in diesem Audit neu gebauten oder hochgeladenen Release.

Die App-Icon-Konfiguration referenziert ein Marketing-Icon; die Bildprüfung ergab 1024 × 1024 Pixel, RGB, keinen Alphakanal. Motiv, Wiedererkennbarkeit und Rechte am Icon wurden nicht visuell abgenommen. `Info.plist:52` bindet LaunchScreen ein; Zeilen 56–67 enthalten die Orientierungen.

Im bestehenden Build wurden unter anderem Privacy-Manifeste von Flutter, shared_preferences_foundation, app_links, flutter_secure_storage_darwin, share_plus, url_launcher_ios und package_info_plus gefunden. Flutter deklariert unter anderem FileTimestamp-/SystemBootTime-Gründe, shared_preferences UserDefaults. Das beweist Teilabdeckung, keine vollständige Prüfung jedes später mitgelieferten SDKs.

Die vorhandene App ist ungefähr 164 MB groß, mit etwa 133 MB Inhaltspaketen. Das ist weder identisch mit der App-Store-Downloadgröße noch ein Nachweis einer pauschalen Größenverletzung. Download und Installation können zudem durch Gerätevarianten und Kompression anders ausfallen.

### A.2 Offline-Schriften und Accessibility sind noch keine bestandene Geräteprüfung

`lib/theme/app_theme.dart:116` und `:137` nutzen GoogleFonts für Figtree und Source Serif 4. In der aktiven `pubspec.yaml` sind keine entsprechenden Fontbundles eingetragen. Eine Abschaltung von Runtime-Fetching wurde in Tests gefunden, nicht im normalen Appstart. Deshalb ist ein Erststart ohne bereits gefüllten Fontcache ein sinnvoller reproduzierbarer Test. Ein Absturz wurde hier nicht nachgewiesen. Ebenso ist noch offen, welche Font-Netzwerkzugriffe im tatsächlichen Release stattfinden und wie diese in Dateninventar und Datenschutztext einzuordnen sind.

Positive Accessibility-Signale sind SafeArea, Semantics und Anpassungen an Textskalierung, beispielsweise `settings_screen.dart:104`, `paywall_screen.dart:141` sowie die Account-Sheet-Struktur. Die Anwendung hat auch Reduce-Motion-Abfragen. Daraus folgt kein bestandenes VoiceOver-, Kontrast- oder Großschrift-Audit. Zu prüfen sind insbesondere Lesetextauswahl, Popover bei großen Schriftgrößen, Tastaturüberlagerung, Fokusreihenfolge, Statusansagen und die Lesbarkeit in beiden Farbschemata.

### A.3 Export und öffentliche Angaben

Das Fehlen von `ITSAppUsesNonExemptEncryption` allein wurde nicht als Ablehnungsbeweis gewertet. Verschlüsselungsangaben gehören zum konkreten Einreichungsprozess; die tatsächlich verwendeten Verfahren und zutreffende Ausnahmen müssen dort korrekt beantwortet werden. [Apple: Export Compliance](https://developer.apple.com/help/app-store-connect/manage-app-information/overview-of-export-compliance/).

Weitere extern zu prüfende Angaben: Betreiber-/Händlerstatus für die gewählten Vertriebsregionen, Supportkontakt, öffentliche Datenschutzerklärung, Screenshots, Beschreibung, Rechte, Accessibility-Angaben und Review-Notizen. Es wurden keine entsprechenden Storeformulare ausgefüllt und keine rechtlichen Zusicherungen für den Betreiber abgegeben.

## Anhang B — Kurzer Vorschlag für spätere Review-Notizen

Dieser Text ist eine Vorlage, **keine aktuell wahre Freigabeerklärung**. Eckige Felder dürfen erst nach tatsächlicher Prüfung ausgefüllt werden:

> Die App bietet Sprachlernübungen, Wortlisten und Lesetexte. Offline verfügbare Funktionen: [am Release überprüfte Liste]. Für [konkrete private Funktion] verwenden Sie bitte [separat sicher bereitgestellter Testzugang]. Zur Sprachausgabe wird die installierte native Stimme verwendet. Cloudübersetzungen erfolgen erst nach dem erläuterten Zustimmungsablauf; der Pfad lautet [genauer Navigationsweg]. Käufe sind [tatsächlicher Releasezustand]. Die Datenschutzerklärung ist unter [echte URL] und in der App unter [Pfad] erreichbar.

Keine Passwörter, Tokens oder produktiven Testkontodaten in diesen Repository-Bericht eintragen.
