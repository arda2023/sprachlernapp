# Vollständiger Vertragsabgleich vor dem Einzelversuch
Stand bb7d3c6. Tatsächlich vom unveränderten Handler erzeugter Request: request.json. Aktiver EN-Pack hashgeprüft; hamster hat 0 Packkandidaten. Nur synthetischer Text, keine lokalen Privatkarten/Cachehinweise. Auth/Release-RPC/Claim/Finish sind lokale Fixtures; Packprojektion, Modellauftrag, Envelopeprüfung und personalOutput sind Produktionscode. Kein Produktionsauftrag wird wiederholt oder verändert.

| Bereich | Auftrag/Schema | Validator | Befund |
|---|---|---|---|
| Pflichtfelder | 15 Felder, required, additionalProperties=false | exakt dieselben 15 Schlüssel | übereinstimmend |
| Textfelder | string ohne Längen-/Leerheitsvorgabe | nicht leer/Whitespace; keine Steuerzeichen; 200, Satz600, Übersetzung1200 UTF-16 | Unterbestimmt, kein Beleg für konkreten Livefehler |
| POS | Prompt Universal POS/no PROPN; Schema beliebiger String | feste 13 Großbuchstabenwerte | Schema bildet Vertrag nicht ab |
| Funktion | Prompt null/base/past/past_participle; Schema string/null | exakt diese Werte | Schema unterbestimmt |
| reuse_id | Prompt nur echte Kandidaten-ID; Schema string/null | exakte Kandidaten-ID, Lemma/POS/Funktion, nicht zurückgestellt | fachliche Prüfung notwendig; kein Kandidat für hamster |
| start | Prompt exakte UTF-16-Position; Schema integer | nichtnegativ, Zielsubstring, ganze Wortgrenze | Prompt sagt nicht ausdrücklich nullbasiert; Request enthält aber exakte start/end |
| Original | Prompt unverändert und gleicher start/reason original | exakte Satz-/Offsetgleichheit bei neuen Karten | übereinstimmend; nur neue Karten werden vollständig geprüft |
| Ersatz | Prompt 3–40 Wörter, ein Satz, exakte Form, begründete Ausnahme | Wortanzahl 3–40, Wortgrenze, Ein-Satz-Test, reason | Ein-Satz-Test verlangt terminale Interpunktion; Prompt nicht explizit |
| Grund | Prompt original/too_short/unusable_target | exakt diese Werte | Schema string unterbestimmt |
| Kurzer Originalsatz | <=2 Wörter Ersatz too_short, außer Wiederverwendung | <=2 too_short; sonst too_short verboten | übereinstimmend |
| Lange Originale | Prompt Original bevorzugen | auch Original auf <=40 Wörter begrenzt | Prompt erwähnt 40 nur beim Ersatz; möglicher Vertragskonflikt, nicht Hamsterfall |
| reason_detail | Original geeignet bzw. konkrete Begründung | beliebiger nichtleerer Text <=200 | nichtleere Angabe nicht explizit im Schema |
| distinctions | genau blocked-IDs, relation Enum, reason string | gleiche IDs; relation erlaubter Wert; reason nichtleer <=200; nur independent | Schema/Prompt weitgehend deckungsgleich, Textgrenzen fehlen |
| cache_use | exakt word/sentence boolean | gleiche Schlüssel/Typen; behauptete Übernahme muss exakt sein | übereinstimmend |
| Wortcache | geeignete Felder EXAKT wiederverwenden | POS aus Cache muss ebenfalls Universal-POS sein | Übersetzungsendpoint erlaubt beliebige POS-Strings; Eignung muss ausdrücklich Universal-POS/Antwortverrat berücksichtigen |
| Satzcache | geeigneten Originalsatz exakt übernehmen | Originalsatz und Übersetzung müssen genau stimmen | Konflikt mit Antwortverrat möglich bei gleichgeschriebenen Wörtern |
| cache_note | bei Nichtübernahme begründen, Schema string | immer nichtleer <=200 | Vollübernahme ohne Notiz schema-/promptkonform, aber ungültig |
| Antwortverrat | Prompt keine Antwort im cue | Zielwort in gloss_de UND translation_de verboten | translation_de nicht explizit als cue benannt; gleichgeschriebenes Hamster führt ANSWER_LEAK, nicht beobachtetes MODEL_INVALID |
| Envelope | festes Modell, max_tokens1500, Thinking aus, effort low | Modellgleichheit, end_turn, ein Textblock, Tokenzahlen | Live-Trace hat diese Prüfungen bestanden |
| Speicherung | nach validierter Antwort | finish stored=true vor200 | Live-Trace erreicht Speicherung nicht; keine Erfolgsbehauptung zulässig |

Folgerung: Vertragslücken sind belegt, die historische verletzte MODEL_INVALID-Regel ist es nicht. Keine Validatorlockerung oder Parameteränderung vor dem reproduzierbaren Modellnachweis. Ein synthetischer Einzelversuch kann eine konkrete aktuelle Ablehnung belegen, aber nicht rückwirkend die verlorene frühere Antwort rekonstruieren. Bei Erfolg keine weitere Modellanfrage zum Erzwingen eines Fehlers.

## Einziger genehmigter Modellnachweis und Korrektur

Der Nutzer hat genau einen Entwickler-Aufruf über den verdeckten lokalen Starter ausgeführt. Der Schlüssel wurde ausschließlich an den Kindprozess übergeben, nie in Dateien/Logs/Chat gespeichert. Der Starter hat vor dem Netzwerkversand eine exklusive ATTEMPT_USED-Datei angelegt; keine automatische Wiederholung. Produktionsaufträge, Quoten und Lernstände wurden im kontrollierten Entwicklerweg nicht verändert. Die unveränderte tatsächliche Packprojektion ergab keine hamster-Kandidaten. Auth/RPC/Storage-Transport waren Fixtures, Modellauftrag/Antwortvalidator Produktionscode. Antwort und Request bleiben ausschließlich im geschützten Verzeichnis /private/tmp/sprachapp-2c-single-experiment (Verzeichnis 0700, Antwortdateien 0600), außerhalb des Repositorys. Kein dauerhafter Produktions-Capture eingebaut.

Ergebnis: HTTP 502, ANSWER_LEAK, RULE_21, nach erfolgreicher Envelope-/JSON-Prüfung; Speicherung nicht erreicht. Die synthetische Antwort enthält das im Englischen und Deutschen identisch geschriebene Zielwort in translation_de. Der Worthinweis enthält es nicht. Die unveränderte Antwort reproduziert diese Ablehnung lokal; eine Wiederaufnahme liefert 409 und keinen zweiten simulierten Modellaufruf.

Einordnung: Der Validator erfüllt die bestehende Schutzregel korrekt, weil auch die Satzübersetzung vor der Lösung angezeigt wird (PracticeTranslationCard, initial offene Übersetzung). Die Modellantwort ist als normale Übersetzung plausibel, für diese Übung aber unbrauchbar. Der Auftrag war widersprüchlich/unterbestimmt: normale Satzübersetzung verlangt, Antwortverbot nur allgemein für „cue“ formuliert, während ausschließlich gloss_de ausdrücklich so benannt wurde. Das erklärt die im Experiment nachgewiesene RULE_21-Ablehnung. Es beweist NICHT rückwirkend den früheren MODEL_INVALID-Gerätefehler; dieser hat einen anderen Code und seine Antwort ist verloren.

Minimale Korrektur in PersonalLearningBackend.perform: translation_de heißt jetzt ausdrücklich lösungsfreier deutscher Satzhinweis; beide deutschen Felder sind vor der Lösung sichtbar und dürfen das Zielwort auch bei identischer deutscher Schreibweise/Großschreibung nicht enthalten. Natürlich und bedeutungstreu umschreiben, Quellsatz/Zielform/Position unverändert lassen; dies rechtfertigt keinen Ersatzquellsatz. Cacheteile mit Antwortverrat sind ungeeignet, nicht exakt zu übernehmen und mit cache_use=false zu kennzeichnen. Dasselbe ist als Feldbeschreibung im Antwortschema verankert. Keine Validatorlockerung, nachträgliche semantische Umschreibung oder automatische Reparaturanfrage.

## Prüfungen und Grenzen

- Neuer unabhängiger Vertragstest: vor der Korrektur FAIL (fehlende ausdrückliche Satzhinweis-/Cachevorgabe), danach PASS. Prüft zusätzlich 200 + gespeicherte Wiederaufnahme ohne zweiten Modellaufruf sowie Ablehnung eines verräterischen Satzhinweises ohne Finish. Die Antwortfixture ist handgeschrieben; keine rohe Anbieterantwort im Repository.
- Backend/Trace 14 PASS. Flutter 28 PASS einschließlich neuer SQLite-/Sammlungsregression, Produktion-Providerfluss, bestehender Lernstände/Historie, paralleler Adds und Original-Packtest. Analyse nur bestehender avoid_print-Hinweis in test/data/baseline_adoption_pack_test.dart:43.
- Volle lokale Edge Runtime v1.77.1 mit tatsächlichen EN-Packbytes, 256-MB-Isolate/CPU soft1000 hard2000 ms/Wall150 s: aufgezeichnete Antwort 502 ANSWER_LEAK (1314,5 ms), Wiederaufnahme409 (635,0 ms), 0 Finish; ausdrücklich synthetisch geänderter lösungsfreier Satzhinweis 200 (1144,1 ms), Wiederaufnahme200 (630,1 ms), 1 Finish, jeweils 1 simulierte Modellantwort. CPU 612/560 bzw.557/545 ms; Isolate-Speicher bei Shutdown bis166.405.489 Bytes. Kein Ressourcenabbruch. Gesamtprozess-RSS bis320.253.952 Bytes umfasst mehrere Runtime-Komponenten und ist nicht der Isolate-Peak.
- Die synthetische positive Fixture ist KEINE zweite Modellantwort und KEIN Beweis, dass das Modell den korrigierten Auftrag live erfüllt. Der eine genehmigte Aufruf ist aufgebraucht; keine weiteren Modellaufrufe. Die reale negative Antwort bleibt mit dem korrigierten Code abgelehnt.
- Damit: Diagnose exakt; nachgewiesene Vertragslücke korrigiert; erfolgreiche Livegenerierung nach Korrektur und Geräte-Add noch unbestätigt. Alte return-hamster-/hamster-Sperren unangetastet, keine Wiederholung oder neue Schlüssel zum Umgehen.

## Vorherige Auslieferung (d8a60b0)

Ausschließlich create-learning-card mit npx supabase deployed; danach Version3 ACTIVE und verify_jwt=true lesend bestätigt. Keine Migration, Secrets oder anderen Functions verändert. Aktueller Profile-Build erfolgreich mit beiden vorhandenen Supabase-Defines, als Update auf 00008110-001651611E01401E installiert und gestartet. Keine Deinstallation/Datenrücksetzung. Installation/Start sind kein Geräte-PASS für Erstellung. Kein weiterer Add-Klick im verbleibenden genehmigten Budget zulässig. Der einmalige Testschlüssel kann widerrufen werden.

## Abschluss des lokalen Vertragsabgleichs · 25.10.2026

Die oben aufgeführten offenen Vertragslücken sind jetzt im tatsächlich gesendeten Auftrag und Antwortschema beschrieben. Die bestehenden Validatorbedingungen bleiben gleich; nur die identischen POS-/Funktions-/Grundwerte werden mit dem Schema geteilt. Kein neuer Modellaufruf und keine semantische Reparatur unbrauchbarer Antworten.

| Bereich | Abgleich |
|---|---|
| Pflichtfelder/Typen | Alle 15 Felder weiterhin erforderlich, keine zusätzlichen Felder; verschachtelte Cache-/Unterscheidungsobjekte ebenfalls exakt. |
| Erlaubte Werte/Referenzen | Dieselben 13 POS, drei Funktionen plus null und drei Gründe; reuse_id nur null oder angebotene, nicht zurückgestellte aktive IDs. Bedeutung, Form und Referenzbindung bleiben lokal geprüft. |
| Textgrenzen | Nichtleer, keine U+0000–001F; 200 UTF-16-Einheiten, Satz600, Satzhinweis1200. Anthropic unterstützt die betreffenden minLength/maxLength/minimum-Schlüssel nicht; Feldbeschreibungen und Auftrag drücken die Grenzen aus, der Validator erzwingt sie. Das ist keine Garantie für Modellkonformität. |
| Position/Wörter | Nullbasierte UTF-16-Einheiten, astrale Zeichen zählen zwei; ganze exakte Zielform; interne Apostrophe/Bindestriche gehören zum Wort. |
| Original/Ersatz | Original unverändert einschließlich fehlender Schlussinterpunktion. Bestehende Grenze 3–40 Wörter gilt auch für Originale. Über40 benötigt deshalb einen begründeten geeigneten Ersatz; keine neue Grenze eingeführt. Ersatz genau ein Satz mit Endzeichen. |
| cache_note | Immer nichtleer, auch bei Vollübernahme oder fehlenden Cacheteilen. |
| Cacheeignung | Exakte übernommene Felder, kanonischer POS, passende Form/Bedeutung und bestehende Textgrenzen; verräterische Leseübersetzungen sind keine geeigneten Übungshinweise. Kein Umschreiben des Lesecaches. |

Verifikation:
- Backend/Trace: 18 PASS. Neue Vertragsregression gegen vorherigen HEAD: FAIL wegen fehlender Schema-Enums; gleicher Test mit Korrektur PASS. Zusätzliche Grenztests für UTF-16, Textlängen, Original41/40 Wörter, fehlendes Satzende, Cacheübernahme und leere cache_note.
- Flutter: 30 PASS inklusive Original-Packtest, erfolgreichem Speicher-/Sammlungsweg, genau einem Übungskontext, Wiederaufnahme ohne zweite Generierung und Erhalt bestehender Historie. Neue Regression schließt/öffnet echte lokale SQLite-Dateien: eine Karte nach dreifacher idempotenter Anlage; normale Leseübersetzung mit „Hamster“ bleibt unverändert neben dem separaten lösungsfreien Hinweis. Keine automatische Übungsantwort.
- Analyse: allein vorhandenes avoid_print in test/data/baseline_adoption_pack_test.dart:43. Eigene Änderungen whitespace-sauber; fremde CRLF-Hinweise in lib/main.dart nicht verändert.
- Vollhandler mit tatsächlichem veröffentlichtem EN-Pack in Edge Runtime v1.77.1, 256MB-Isolate, CPU soft1000/hard2000ms, Wall150s. Auth/RPC/Storagetransport simuliert; aufgezeichnete negative Antwort bzw. ausdrücklich synthetischer positiver Satzhinweis statt Anbieterzugriff. Negativ502 ANSWER_LEAK/409, null Finish, ein Modellstub; positiv200/200, ein Finish, ein Modellstub. Laufzeiten1167,5/666,5 bzw.1145,6/625,8ms; CPU629/573 bzw.545/537ms; maximaler gemessener Isolate-Speicher beim Shutdown166.440.659Bytes. Kein Ressourcenabbruch; Shutdown-Wert ist kein garantierter zeitkontinuierlicher Peak.

## Freigegebener Geräteversuch und reguläre Sperrfristen

Read-only-Prüfung der beiden bestehenden Aufträge: pending, keine gespeicherte Antwort, unveränderte24h-Frist. return-hamster endet26.10.2026 um07:27:51 Europe/Berlin; hamster endet26.10.2026 um10:13:52. Vorher kein Add, keine Sperrlöschung/Schlüsseländerung/Textvariante. Der Nutzer hat genau einen weiteren potenziell kostenpflichtigen Geräte-Add freigegeben und führt den Klick selbst aus.

Ab26.10.2026 10:14Uhr: bestehende englische Story „The hamster sleeps in the cage“ öffnen, hamster antippen, einmal „Zum Lernen hinzufügen“. Keine Neuimporte oder Textänderungen zur Sperrumgehung. Bei Wiederverwendung keinen Modellaufruf erzwingen. Danach „Aus Storys“ → Karte → Übung mit genau einem Kontext öffnen, keine Antwort absenden; App neu starten und Vorhandensein prüfen. Bei erstem Fehler stoppen; UI-Code und Zeitpunkt mit sicherem Stage-/RULE-Trace abgleichen, keine zweite Anfrage.

Auslieferung: ausschließlich create-learning-card Version4 ACTIVE, verify_jwt=true lesend bestätigt; keine Migration/Secretänderung/andere Function. Profile-Build mit denselben zwei vorhandenen Supabase-Defines erfolgreich, als Update auf iPhone von Claus installiert und gestartet (devicectl bestätigt). Keine Deinstallation oder Datenrücksetzung. Sichere Diagnose enthält nur Stufen, Dauer, Status und Prüfcodes; keine Texte/Antworten/Schlüssel. Erfolgreiche Modellantwort im korrigierten Produktionsablauf und Geräte-Persistenz bleiben bis zum Nutzerklick unbestätigt.
