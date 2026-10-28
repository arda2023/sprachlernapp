# Paket 2C: Erstellungsfehler — Diagnose vom 25.10.2026

## Belegter Verlauf und offene Ursache

Der Wortauswahlfix c8c031a bleibt erhalten. Der erste reale Erstellungsaufruf endete am 25.10.2026 um 06:27:55.982 UTC (07:27:55 CET) mit HTTP 502. Der Worker startete um 06:27:49.897 und endete um 06:27:56.003 mit EarlyDrop, CPU 758 ms. Es gab in diesem untersuchten Ablauf keinen CPUTime-/Memory-Abbruch. Der spätere Aufruf um 06:29:29.812 lieferte 409.

Die eng begrenzte, lesende Zustandsprüfung ergab einen pending-Auftrag ohne gespeicherte Antwort, dessen 45-Sekunden-Lease um 06:28:36.361 UTC ablief. Der erste Fehler geschah also VOR dem Leaseablauf. Die Sperre ist eine Folge des erfolglosen/unklaren Versuchs, keine nachgewiesene Fehlerursache.

Aus vorhandenem Auftrag und dem unveränderten v1-Kontrollfluss folgt: Authentifizierung, Release-/Packprüfung und Claim wurden erreicht bzw. bestanden. HTTP 502 liegt dort in der Anbieter-/Antwortprüfungsphase, vor erfolgreichem finish. Historische Logs enthalten weder den konkreten Fehlercode noch den Prüfschritt; der Client verwarf zusätzlich den vorhandenen JSON-Fehlercode. Anbieterablehnung und ungültige Modellantwort lassen sich nachträglich nicht unterscheiden. Keine Behauptung über den tatsächlichen Anbieterbody oder ein bestimmtes verletztes Antwortfeld. Eine gespeicherte Antwort zur lokalen Wiederaufnahme fehlt.

## Begrenzte Änderung

Behoben ist die nachgewiesene Diagnoselücke, nicht eine nur vermutete Modellursache. Der vollständige Handler protokolliert zufällige Diagnose-ID, feste Schritte, Dauer, HTTP-Status und freigegebene Fehlercodes. Schritte unterscheiden Auth, Release, Pack, Referenzen, Claim, Konfiguration, Modellrequest, Envelope, JSON, fachliche Validierung, Speicherung und Abschluss. Keine Texte, Nutzer-/Auftragsschlüssel, Zugangsdaten, URLs oder rohe Modellantworten. Auch ein defekter Log-Sink verändert den Ablauf nicht.

Der Client zeigt ausschließlich begrenzte, freigegebene Servercodes an. Beliebige oder übergroße Fehlerantworten erscheinen nicht in der UI. Ein Fehler behauptet weder Hinzufügen-Erfolg noch unbelegt, dass serverseitig nichts gespeichert sei. Validatoren, Auth, Release-/Hashbindung, Consent, Kostenlimits, SQL-Transaktionen und Auftragssperre bleiben unverändert.

## Lokale Nachweise

Vollständiger Handler mit tatsächlichen veröffentlichten EN-Packbytes (50.282.981 Bytes; SHA-256 92c44ef9f163e213cf9a44e6e23a264de6bfb11f6d233a1b8c5c8f676704f37c), synthetischem Text `I am the return-hamster`, ausgewähltem `return-hamster` an UTF-16-Position 9. Offizielle ARM64 Supabase Edge Runtime v1.77.1, User-Worker-Limits 256 MB, CPU soft 1000/hard 2000 ms, Wall 150 s. Auth, RPC/Zustand und Storage-Transport sind Fixtures; Modellantworten ausschließlich synthetisch. Keine echte Modellanfrage und keine Cloudmutation.

| Fall | Erster / zweiter HTTP-Status | Modellaufrufe | Finish-Aufrufe | CPU je Worker (ms) | Laufzeit je Aufruf (ms) |
| --- | --- | --- | --- | --- | --- |
| Anbieter lehnt ab | 502 MODEL_FAILED / 409 | 1 | 0 | 593 / 542 | 1169 / 627 |
| Antwort verletzt Validator | 502 MODEL_INVALID / 409 | 1 | 0 | 535 / 533 | 1016 / 618 |
| Speicherung nicht bestätigt | 503 STORAGE_UNAVAILABLE / 409 | 1 | 1 | 542 / 531 | 1033 / 616 |
| Speicherung und Wiederaufnahme | 200 / 200 | 1 | 1 | 545 / 538 | 1211 / 616 |

Alle acht Antworten erwartungsgemäß; kein Ressourcenabbruch. Beobachteter Heap plus External bis 166.334.100 Bytes, kein garantierter Peak. Gesamtprozess-RSS bis 319.229.952 Bytes enthält auch Main-/Eventworker und ist nicht der User-Isolate-Speicher. Aggregierte Messwerte, Image- und Quellhashes: [Evidenz](evidence/package-2c-creation-diagnostics-20261025.json). Diese Fixtureprüfung ist keine Cloud-/RLS-Abnahme und rekonstruiert keine verlorene echte Modellantwort.

Tests: Backend/Trace 12 PASS; Flutter Lernen/Importstatus/Bedeutung/Cachehinweise/Sammlung 35 PASS; Client-Fehlerantworten und Original-Packtest 4 PASS. Bestehende Tests decken lokale Transaktionsrücknahme, parallele Adds, Idempotenz, Kontowechsel und Sammlungszuordnung ab. Analyse: ausschließlich bestehender avoid_print-Hinweis in test/data/baseline_adoption_pack_test.dart:43. Python-Probe syntaktisch geprüft. Keine neue Geräteabnahme.

## Konkreter nächster Schritt — noch nicht ausgeführt

1. Nach Freigabe ausschließlich den diagnostisch ergänzten create-learning-card-Handler deployen, JWT-Prüfung beibehalten. Keine Migration, keine Änderung von Secrets oder Übersetzungsfunctions. Derselbe CLI-Befehl gilt in macOS Terminal und Windows PowerShell:

   `supabase functions deploy create-learning-card --project-ref yevntxclpchapacqdizm`

2. Client als Profile-Update mit vorhandenen Supabase-Dart-Defines installieren, ohne Deinstallation/Reset. Dann kann der erste Fehlercode sichtbar bleiben. Das Update allein löst keine Erstellung aus.
3. Erst nach separater Zustimmung zu genau einem potenziell kostenpflichtigen Test einen neuen, vereinbarten synthetischen Kontext ausdrücklich hinzufügen. Wortdialog öffnen allein erzeugt keine Karte. Bei Fehler: ersten UI-Code und sicheren Stage-Trace auswerten, nicht erneut klicken. Bei Erfolg: „Aus Storys“ sowie erneutes Öffnen prüfen; keine Übungsantworten erforderlich.
4. Alten Auftrag unangetastet lassen. Keine künstliche Schlüsseländerung oder Löschung zum Umgehen der Sperre. Ohne gespeicherte Antwort kann die alte Karte nicht modellfrei wiederhergestellt werden. Eine spätere erneute Erstellung braucht eine ausdrückliche Entscheidung und die regulären Sperr-/Quota-Bedingungen; keine automatische Wiederholung.

Der ursprüngliche Anbieter-/Validierungsfehler bleibt bis zu einem aussagekräftigen Trace offen. Es wurden keine spekulativen Korrekturversuche an Modellparametern oder Validatoren vorgenommen. Isolierter lokaler Diagnose-Commit, kein Push.

## Tatsächlicher Einzelversuch nach Diagnose-Deployment

Am 25.10.2026 wurde ausschließlich create-learning-card mit `npx supabase` als Version 2 deployed; ACTIVE und verify_jwt=true danach lesend bestätigt. Profile-Build erfolgreich (50,8 s, 66,3 MB), beide bisherigen Supabase-Defines unverändert übernommen; Update installiert und gestartet. Kein Reset, keine Migration, keine Secretänderung und kein weiterer Function-Deploy.

Der Nutzer meldet um 10:13 CET MODEL_INVALID. Der zugehörige sichere Trace (Diagnose-ID c7ad81db-8577-41a2-a3da-a1764fe72226) beginnt 09:13:50.854 UTC und endet 09:13:54.438 UTC. Auth 76 ms, Release 91 ms, Pack 998 ms, Referenzen 2 ms, Claim 69 ms; Modellrequest 2341 ms, Envelope und JSON erfolgreich. Fehler: stage=validation, code=MODEL_INVALID, elapsed_ms=3584. Kein storage-Schritt erreicht. Der Screenshot verwendet „The hamster sleeps in the cage“ statt des vereinbarten „… its cage.“; dies allein belegt keinen Fehler und ist kein Grund für eine weitere Anfrage.

Die ursprüngliche Sammeldiagnose reicht innerhalb von personalOutput nicht aus. Die verworfene Antwort wurde absichtlich nicht gespeichert; ihr verletztes Feld kann nicht nachträglich aus dem Stage-Trace rekonstruiert werden. Unpassende Wortart, leeres Pflichtfeld oder Offsetfehler sind weiterhin mögliche Ursachen, keine bewiesenen Ergebnisse. Der Request-Schema-/Validatorvergleich zeigt zudem, dass das Schema weniger einschränkt als der nachgeschaltete Validator; es beweist nicht, welche konkrete Regel hier verletzt wurde. Deshalb keine spekulative Änderung der Fachvalidierung oder Modellparameter.

Lokal ergänzt: stabile nummerierte Prüfstellen (RULE_1–RULE_21, Textfelder RULE_100–RULE_109) nur beim Fehler; keine private Antwort, keine Ausnahmebotschaft. Bestehende Prüfbedingungen, Fehlercodes und Sperrverhalten unverändert. Test mit dem vereinbarten Hamstersatz unterscheidet synthetisch leere cache_note (100), ungültige Wortart (2), falschen Offset (13). Jeweils 502, kein storage, erneuter Versuch 409 und insgesamt genau ein simulierter Modellaufruf. Backend/Trace: 13 PASS. Dies ist ausdrücklich kein Fixbeleg für die verlorene echte Antwort.

Die ergänzten Prüfstellen sind noch NICHT deployed. Kein zweiter Liveversuch ausgeführt oder genehmigt, beide alten Aufträge unangetastet. Ein vorhandener, sicher zugänglicher Anbieter-Requestnachweis könnte die ursprüngliche Antwortprüfung noch ohne neuen Modellaufruf klären; ein solcher Nachweis liegt derzeit nicht vor. Ohne ihn oder einen später ausdrücklich freigegebenen Versuch mit exakten Prüfstellencodes bleibt die konkrete Fachursache offen. Kein Geräte-PASS.
