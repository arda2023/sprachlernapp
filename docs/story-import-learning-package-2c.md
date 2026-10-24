# Paket 2C: private Lernkarten aus Texten

Status: implementierter Zwischenstand, **noch nicht abnahmebereit**. Ein neuer
UI-Test und die unten genannten fachlichen/Integrationspunkte bleiben offen.
Keine Deploymentfreigabe, kein Geräte-PASS.

## Vertrag vor Implementierung (24.10.2026)

Ausgangspunkt: 136e01b, Hauptprojekt sauber. Wort-Tap übersetzt ausschließlich.
Add verwendet zuerst den bestehenden geprüften Storyweg. Unannotierte Ziele
werden erst auf Add mit gesonderter, widerrufbarer Konto-/Gerätefreigabe verarbeitet.
Die Übersetzungsfreigabe ist dafür keine Zustimmung.

Vorhandener Speicher: user_cards enthält Form, Formnorm, Lemma-/Senseidentität,
Glosse, Wortart, primary_context_id und denselben SRS-Zustand wie Packkarten.
card_contexts enthält unveränderliche Satz-/Übersetzungs-/Lücken-/Token-Snapshots,
Quelle, Revision und Herkunft. story_learning_additions und story_word_sources
verknüpfen dieselbe Karte mit „Aus Storys“. Die vorhandene Transaktion und der
PracticeItemResolver bleiben der Speicher-/Lernweg; kein zweites SRS.

Neue private Kandidaten erhalten einen eigenen strengen Validator und Herkunft
private_haiku_v1, niemals editorial_chat_reviewed. IDs sind deterministisch aus
Sprache, exaktem Originalsatz und UTF-16-Zielstelle getrennt von Pack-Senses.
Unsichere Bedeutungen verschiedener Kontexte werden nicht zusammengeführt.
Bestehende Packkandidaten müssen aus dem aktiven Pack stammen und serverseitig
gegen content geprüft werden. Das Modell darf nur eine angebotene Kandidaten-ID
wählen; der Client prüft den gewählten Datensatz erneut. Gesperrte/retirierte
Ziele derselben Oberfläche blockieren konservativ eine neue Alias-Erstellung.

Originalsatz unverändert bevorzugen; 1–2 Wörter benötigen bei einer neuen Karte
Ersatz. Bei längeren Sätzen nur belegte Ungeeignetheit des konkreten Lernziels;
Pronomen/fehlende Annotation allein rechtfertigen keinen Ersatz. Ein vollständiger
fester Kontext wird atomar gespeichert, Herkunft inklusive Original bleibt erhalten.
Tokenisierung/Offsets und Antwort werden technisch geprüft; Sprachqualität ist
eine separate reale Abnahme. Fehler speichern nichts, kein bezahlter Retry.

Separater privater serverseitiger Erstellungs-Claim, dieselben globalen/nutzer-
bezogenen Reservierungslimits wie Übersetzung, begrenzte Ein-/Ausgabe. Keine
Kartendaten in translation_cache. Fertige lokale Karten haben keine Cache-TTL.
Cloudmigration und Function werden vorbereitet, nicht deployed. Keine echten
Modellaufrufe, keine Reviews oder Gerätedatenänderungen für lokale Tests.

## Nachweis zum Test-Hänger

Zwei gezielte Änderungen an asynchronem Testaufbau/-abbau beseitigten den
Hänger nicht. Phasenprotokoll `/tmp/2c-widget-diagnostic2.log`: alle UI- und
Datenprüfungen erreicht, anschließend `close consent`, kein `closed consent`.
Die Datenbank ist geöffnet; `close()` wartet auf das in der FakeAsync-Zone
des Widgets erzeugte memoierte Future. Teardown außerhalb dieser Zone kann
dessen Fortsetzung nicht pumpen. Nächster gezielter Diagnoseschritt: genau
dieses Future vor dem Widget in `tester.runAsync` erzeugen, damit Öffnen und
Schließen derselben realen Async-Zone gehören. Keine Produktänderung, keine
Timeout-Erhöhung und keine entfernte Assertion.

## Implementierter Ablauf

- Wort-Tap bleibt Übersetzung. Nur Add ruft `PersonalLearningService.add` auf.
  Unannotierte/importierte Stellen erhalten den privaten Button; kaputte
  vorhandene Referenzen werden nicht durch einen Generierungsfallback kaschiert.
- Vorhandene Quellenbindung wird lokal aufgelöst, einschließlich produktivem
  `contentIds`-Guard. Gleiche Quelle/Wortstelle braucht keinen neuen Aufruf.
- Der tatsächliche Resolver liefert mögliche Pack- und lokale Karten. Auswahl
  durch Haiku erfordert passende Bedeutung und Form; Rückgabe darf nur eine
  angebotene ID sein. Packreferenzen werden zusätzlich serverseitig geprüft,
  lokale Referenzen vor dem Save erneut gegen die private Datenbank geprüft.
  Eine neue Kontextstelle kann daher trotz gleicher Oberfläche eine eigene
  Identität erhalten. Maximal 24 Kandidaten insgesamt, davon vier lokale.
- Neue Karte: Lemma, POS, Bedeutungsdefinition, Formbeschreibung/-funktion,
  deutsche Glosse, deutscher Satz, exakte Lücke und vollständige Token-Spannen.
  Original inklusive ausgewähltem UTF-16-Span bleibt in der Provenienz erhalten.
  Original bei neuen Karten mindestens drei Wörter; ein/zwei Wörter erzwingen
  Ersatz. Gründe `original`, `too_short`, `unusable_target` mit Detailtext.
- `PersonalLearningCandidate` validiert ausschließlich diesen privaten Weg.
  Redaktionelle Story- und Packvalidatoren unverändert. Neue IDs beginnen mit
  `private:` bzw. bestehendem lokalem `u:`-Schema; keine erfundenen Pack-Senses.
- Bestehende Karten-/Kontext-/Sammlungs-Transaktion plus Quellenalias in einer
  äußeren Transaktion. Bei Konto-/Scopewechsel Rollback. Kein zweites SRS,
  keine gespeicherten Zähler. Bestandskarte, fester Kontext und Reviews bleiben
  bei Wiederverwendung unverändert. Keine fallible Statusnachabfrage nach Save.
- Hinzugefügt → tatsächliche Karten-ID in Wortliste. Sperren und Retirements
  werden konservativ auch für andere Quellen derselben Form berücksichtigt.
  Das kann fachlich unabhängige Bedeutungen vorübergehend ebenfalls blockieren.
- Separate versionsgebundene Einwilligung pro Konto/Gerät in eigener SQLite-Datei,
  abschaltbar in Einstellungen. Kein Ableiten aus Übersetzungsfreigabe.
  Konto/Freigabe werden vor Versand und nach Antwort erneut geprüft.

## Server, Datenschutz und Kosten

`create-learning-card` nutzt die vorhandene Authentifizierung/Sprachfreigabe und
Anthropic `claude-haiku-5-5`, Schlüssel ausschließlich als Serversecret.
Eingabe höchstens 16 KiB, Original 600 UTF-16-Zeichen, Wort 80,
Ausgabe 1.500 Modelltoken, HTTP-Antwort begrenzt. Text/Kandidaten sind Daten,
keine Modellanweisungen. Striktes Antwortschema, exakte Referenzen und Spans;
keine automatische Reparatur, kein Provider-Fallback, kein bezahlter Retry.

Eigene Tabelle `app.personal_learning_jobs`, keine Einträge als Übersetzung.
Service-only RPCs und RLS ohne Clientrechte; gemeinsames Reservierungsbudget
mit Übersetzungen (5/Minute, 20/Tag je Konto und 1.000/Tag global nach bestehendem
Vertrag). Diese Anzahllimits sind keine garantierte Eurogrenze; Kartenerstellung
hat einen höheren Ausgabedeckel als reine Übersetzung. Pending 45 Sekunden,
unklares Ergebnis 24 Stunden gesperrt, fertige Antwort 30 Tage wiederverwendbar.
Ablaufbereinigung erfolgt bei späteren Claims; die Frist ist keine Zusage einer
sekundengenauen physischen Löschung. Lokale Karten haben keine Ablaufzeit.
Abschalten verhindert weitere Verarbeitung; laufender Versand ist nicht rückholbar.

Es wurden **null echte Modellaufrufe** und **keine Cloudmutationen** ausgeführt.
Gemessene Modellaufrufe im synthetischen Backend:

| Fall | Modellaufrufe im Stub |
|---|---:|
| erfolgreiche neue Karte | 1 |
| acht parallele gleiche Anfragen zusammen | 1 |
| nachfolgender Treffer des Erstellungsclaims | 0 zusätzliche |
| ungültige Zustimmung, Auth, Budget, Referenz vor Generierung | 0 |
| Anbieterfehler/Timeout/ungültige Modellantwort | 1, kein Retry |

Im echten Repository-/Provider-Test: Packverknüpfung 1 HTTP-Aufruf zum lokalen
Stub; erneutes Add derselben Quelle 0; acht parallele Adds einer neuen Karte
zusammen 1; neue Quelle mit Wiederverwendung der privaten Karte 1. Diese HTTP-
Zahlen sind keine weiteren echten Modellaufrufe. Bereits vollständig geprüfter
Storyweg bleibt ohne diesen Erstellungsaufruf.

## Noch notwendige Cloudschritte — ausdrücklich nicht ausgeführt

Erst nach Behebung der offenen Abnahmebefunde:

1. Migrationstand und bestehenden Serverbestand prüfen. Besonders wichtig:
   `content.cards`, `content.senses`, `content.lemmas` samt Formfunktionen müssen
   die angebotenen IDs des **wirklich aktiven heruntergeladenen Packs** enthalten.
   Weder Bootstrap-Asset noch lokaler Original-Packtest belegen das. Fehlt dieser
   Bestand, schlägt Referenzprüfung vor dem Modell mit 422 fehl. Keine Referenzen
   entfernen, Validatoren lockern oder zusätzlichen Contentimport improvisieren.
2. Bestehende Schemas, Sprachfreigaben, `reserve_runtime_translation` und
   private Cachemigration müssen vorhanden sein. Dann ausschließlich vorbereitete
   Migration `20261024000002_personal_learning.sql` prüfen und anwenden; vorher
   mit `supabase migration list` und `supabase db push --dry-run` fremde/pending
   Migrationen ausschließen. Kein ungeprüftes pauschales db push.
3. Bestehendes `ANTHROPIC_API_KEY`-Secret weiterverwenden, keine Clientdefines
   um Providerkeys ergänzen. `supabase functions deploy create-learning-card`;
   JWT-Prüfung bleibt in config aktiv. Auth-, Sprach- und RLS-Smokeprüfungen zuerst.
4. Erst dann autorisierte echte Modell-/Geräteabnahme durchführen. Bestehende
   Supabase-dart-defines erhalten, iPhone als Update installieren, kein Reset.

Die genannten Supabase-/Flutter-Befehle sind auf macOS (Terminal) und Windows
(PowerShell) identisch. SQL-Migrationen nicht über Shell-Zitatkonstruktionen mit
Schlüsseln oder privaten Texten ausführen.

## Getrennte spätere iPhone-Abnahme

Kein neues Geräte-PASS und keine Installation für dieses Paket behauptet.
Nach Cloudfreigabe mit Testkonto und synthetischen Texten:

1. Stories → Eigene Texte → `She puts a lantern on the table.` importieren.
   `lantern` antippen: nur Übersetzung; Add → separate Freigabe → Ergebnis.
2. `She holds it near her lantern.`: Pronomen allein dürfen den Originalsatz
   nicht ersetzen. Eine passende vorhandene Karte darf jedoch verknüpft werden.
3. `Lantern.` sowie `A lantern.`: für neue Karten Ersatz; bei vorhandener
   passender Karte Wiederverwendung zulässig.
4. `I went to the bank.` und `We sat on the bank.`: `went` als Flexion,
   `bank` als unterschiedliche Bedeutungen; `😀 bank and bank are here.` für
   zweite Wortstelle. Fachliche Modellqualität jeweils am gespeicherten Kontext
   prüfen, nicht nur an erfolgreicher HTTP-Antwort.
5. Portugiesisch: `O coração é importante.`; Akzente und Sprachtrennung prüfen.
6. Sammlung „Aus Storys“ → tatsächliche Karte; App neu starten und offline öffnen.
   Ursprungstext löschen und Übersetzungscache leeren: feste Karte bleibt.
   Übungen/Reviews ausschließlich auf diesen neuen Testkarten nach Zustimmung.
7. Private-Lernkarten-Freigabe abschalten, neues Ziel Add: erneute Freigabe nötig;
   vorhandene Karten bleiben offline nutzbar. Konto-/Sprachwechsel separat prüfen.

## Offene Grenzen / keine Releasefreigabe

- Ein neuer Widgettest zur Einwilligung bleibt rot. Nach isolierter Diagnose ist
  der Teardown-Hänger beseitigt, aber die Dialog-Assertion erreicht den Dialog
  nicht zuverlässig (`findsOneWidget`, gefunden 0). Nach zwei weiteren gezielten
  Async-Anpassungen keine spekulative Umbaufolge. Nächster Schritt: Zustand und
  ausstehende Future unmittelbar vor dem Finder erfassen; FakeAsync/RealAsync
  anhand eines minimalen Consent-Store-Tests trennen. Keine Skips/Timeouterhöhung.
- Der Schalter liest Einwilligung beim Öffnen und nach Bedienung; eine schon
  offene Settingsroute aktualisiert ihre Darstellung bei externem Kontowechsel
  noch nicht aktiv. Versand wird trotzdem kontogebunden geprüft.
- Vorhandene Kartenmetadaten werden wiederverwendet. Ein zusätzlicher Adapter,
  der schon passende **Anzeigeübersetzungen aus dem privaten Übersetzungscache**
  als geprüfte Teilinformationen in die Erstellung übernimmt, fehlt noch. Sie
  werden nicht ungeprüft zur Lernkarte befördert; beim Neuanlegen werden benötigte
  Angaben derzeit gemeinsam mit einem Modellaufruf vervollständigt.
- Bedeutungsgleichheit, sinnvoller deutscher Hinweis und fachlich gerechtfertigter
  Ersatz sind Modellentscheidungen; Strukturprüfungen beweisen keine Sprachqualität.
  Auch „genau ein Satz“ eines Ersatzes ist derzeit Promptvorgabe, kein separater
  linguistischer Satzgrenzenvalidator. Keine redaktionelle Freigabe behauptet.
- Kein Live-Nachweis des Serverregistry-Abgleichs mit aktuellem Gerätepack und
  keine neue Geräteabnahme. Kein Scheduler-, CMS- oder Veröffentlichungsauftrag.

## Tatsächliche lokale Prüfergebnisse (24.10.2026)

| Prüfung | Ergebnis | Protokoll dieses Laufs |
|---|---|---|
| vollständige Flutter-Suite, finaler Stand | 595 PASS, 6 bestehende Skips, 1 FAIL (neuer Einwilligungs-UI-Test) | `/tmp/2c-full-final.log` |
| neue Domain-/Repo-/Providerfälle | 7 Domain + 3 Provider PASS; UI-Fall FAIL | `/tmp/2c-target2.log`, Gesamtlauf |
| angepasste Bestands-UI + Original-Pack | 83 PASS, ursprüngliches Pack-Zeitbudget | `/tmp/2c-existing-final.log` |
| Backend Runtime/Cache/Erstellung | 36 PASS, nur lokale Fetch-Stubs | `/tmp/2c-backend-all.log` |
| SQL Runtime/Cache/Erstellung | 3 Prüfsuiten PASS in PostgreSQL/PGlite | `/tmp/2c-sql-final.log` |
| Deno Typecheck Function-Entrypoint | Exit 0 | `/tmp/2c-deno-check.log` |
| Stage Verify | Exit 0, 22 Tabellen unverändert | `/tmp/2c-stage.log` |
| Flutter analyze | ein bestehender avoid_print-Infohinweis in baseline_adoption_pack_test.dart:43; keine neuen Befunde | `/tmp/2c-analyze-last.log` |

Original-Pack: 26.198.016 Bytes; SHA256
`b85793932825a22e92ac744a42255e9f333acd35809aaba46edb5a395f099bdb`.

Providerfall benutzt echten Fixture-Packinstaller, DriftContentRepository,
produktive Provider und tatsächlichen Pack-ID-Guard. Er prüft Pack- sowie lokale
Wiederverwendung, acht parallele Adds, keine Veränderung alter Reviews/Flags,
Löschen über ImportedTextsNotifier und echte abgelaufene TranslationCache-Zeile.
Separater Datei-DB-Neustart löst die private Karte ohne Content/Netzwerk auf;
Transaktionsfehler und spät geänderter Konto-/Providerscope speichern nichts.
Der unveränderte STORY_STATUS_01-Altstandtest ist Teil der Gesamtsuite.

Vier Bestandstests wurden an den autorisierten neuen UI-Vertrag angepasst:
fehlender Repositorystatus bleibt ein deaktiviertes Add ohne falsche Erfolgsmeldung;
längere Settingslisten werden wirklich gescrollt. Assertions zu Kartenstatus,
Motiv und Sprachwechsel bleiben erhalten. Keine Test-Timeouts erhöht.

GitNexus: Impacts für gemeinsame Repository-/Reader-/Popover-/Settingspfade vor
Änderung ausgeführt, HIGH/CRITICAL gemeldet. Neue Symbole anfangs UNKNOWN;
Aufrufer zusätzlich im Quelltext geprüft. Index erneut vollständig aufgebaut
(9.880 Knoten, 22.721 Kanten); Tool meldet dennoch einen Commit Rückstand und
begrenzte Prozessabdeckung. Das ist keine Aussage, dass fehlende Aufrufer nicht
existieren. Abschließende detect_changes-Prüfung nach Aufnahme neuer Dateien
separat protokollieren; Testbefund bleibt unabhängig vom Graphresultat offen.

Abschließendes `detect_changes(scope: all)` nach Staging: 171 Symbole,
27 geänderte Dateien inklusive fremder skills-lock.json (nicht im Commit),
8 betroffene Prozesse, Risiko HIGH; vollständige Antwort ohne partial/truncated.
Betroffen sind Reader/Übersetzungssheet, Wortlistennavigation, private
Erstellungsvalidierung und Backend/RPC-Pfad. Context-Prüfung bestätigt Provider
als Service-Aufrufer sowie bestehenden Datenbankprovider und Review-/Storytests
als Repository-Verbraucher. SQL/Config ohne Graphsymbole separat geprüft.
Die Ausgabe begründet keine Freigabe des roten UI-Tests. CRLF-Dateien bleiben
CRLF; `git -c core.whitespace=cr-at-eol diff --check` besteht.
