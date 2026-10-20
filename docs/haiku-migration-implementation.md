# Haiku über EU-Vertex: Umsetzungspaket A

Stand: 18.10.2026. Auftrag: ausschließlich Paket A aus [dem abgenommenen Plan](haiku-migration-plan.md), Basiscommit `8514fc3f3057858fe2b9f4a6c74785d481b94bf6`. Lokaler Branch `codex/haiku-vertex-eu`.

## Ergebnis und Grenzen

Der vorhandene Python-Textanschluss verwendet `claude-haiku-5-5` über den fest vorgegebenen EU-Vertex-Host im bestehenden Projekt. Die öffentliche synchrone Schnittstelle `Llm.generate_json(prompt, schema, *, model, thinking, step, max_output_tokens)` und ihre sieben fachlichen Aufrufstellen sind erhalten. Intern arbeitet ein abbrechbarer asynchroner SDK-Client. Kein neuer App-Aufrufer, keine Runtime-KI-Function, kein Providerfallback.

Die **Stapelphase bleibt beendet**. Es wurden keine Produktionsinhalte, Wortreservierungen, Packs, Editorbestände, Lernstände oder Reviews angelegt oder geändert. Vollständige Pipeline-Tests verwenden ihre bestehenden synthetischen temporären Artefakte; zusätzliche en-/pt-BR-Antworten sind ausschließlich synthetische Transportfixtures. Der en-only Produktionsgenerator und das modellfreie pt-BR-Profil bleiben unverändert.

**Offline belegt:** SDK-Routing, Parameter, Antwortvalidierung, Timeout-/Retryverhalten und lokale Budgetkonkurrenz. **Nicht belegt:** Haiku-Freischaltung im Projekt, tatsächliche IAM-/Billing-/EU-Kapazität, Livequalität, Tokenisierung/Latenz im Anbieterbetrieb oder gemessene Einsparung. Keine Modellanfragen, Cloudabfragen/-änderungen, Deployments, Geräteinstallation oder Pushes.

Der Nutzer hat den portugiesischen Ablauf bis zur Mobile-App und die englische chitchat-Korrektur als funktionierend bestätigt. Das ist ein **Nutzerbericht**, keine neue eigene Geräteprüfung. Manuelle BR-/Modellqualitätsprüfung und weitere Freigaben werden dadurch nicht ersetzt.

## Implementierte Änderungen

| Datei | Änderung |
|---|---|
| `pipeline/src/sprachpipe/llm.py` | Bestehender Wrapper auf `AsyncAnthropicVertex` umgestellt; gleiche synchrone Außenschnittstelle, scoped Client/Eventloop je Request. Fester Projekt-/EU-/Modellvertrag, Requesthook gegen falsches Routing, keine Redirects/Fallbacks, SDK-Retries und Inhaltstelemetrie aus. |
| `pipeline/src/sprachpipe/cost.py` | Historisches sieben Spalten umfassendes Ledger bleibt lesbar und wird nicht umgeschrieben. Unbekannte Tokenwerte bleiben leer, konservative USD-Reservierung bleibt kostenwirksam; zusätzliche sichere Versuchsmetadaten in `<ledger>.attempts.csv`. USD auf neun Nachkommastellen aufrunden; nicht endliche/negative Budgetparameter ablehnen. |
| `pipeline/config.yaml` | Alle vier Modellrollen auf Haiku; `location: eu`, Thinking aus, Effort low; 30 s je Versuch, 95 s insgesamt, höchstens drei Versuche. Schrittweise Outputlimits unverändert 256–4096. EU-Kurzkontextpreis 0,11/0,55 USD je Mio. Tokens ergänzt; alte Gemini-Preiszeilen für historische Kosten erhalten. |
| `pipeline/pyproject.toml`, `pipeline/requirements.lock` | `anthropic[vertex]==1.15.0` samt exakt gepinnter neuer Abhängigkeitskette. Lock verwendet lokalen editierbaren Root-Einstieg statt alter VCS-Revision. `google-genai` für vorhandene Werkzeuge/Authoring-Snapshots erhalten. |
| `pipeline/tests/test_haiku_contract.py` | Realer gepinnter SDK-Client mit rein lokalem HTTP-Mock; keine ADC-Datei/Netzanfrage. Routing, Env-Overrides, Format, Redaktion, Fehler/Retry/Deadline/Usage, historische Kosten und Konkurrenz. |
| bestehende `test_generate.py`, `test_parallel.py`, `test_meaning_check.py`, `test_alternative_check.py`, `test_selection.py`, `test_qa_cases.py` | Provider-/Budget-/Diagnosefixtures an neuen Vertrag angepasst. Vollständige lokale Schema-Prüfung verlangt nun das zuvor im Fake fehlende Pflichtfeld `usage`. Sprach-/Inhaltsassertionen bleiben erhalten. |
| `ARCHITECTURE.md`, `docs/pipeline.md`, `docs/setup.md`, `docs/backend.md`, `NEXTSTEPS.md` | Aktuellen Pythonanschluss von zukünftiger Runtime-KI trennen, historische Nachweise erhalten, Nutzerbericht korrigieren. Statusdatei 24 Zeilen; unveränderte Zeilen behalten auch ihre ursprünglichen LF-/CRLF-Bytes. |

`pipeline/tests/test_cost_schema.py` wurde unverändert mitgeprüft; alte Ledger-/Schemastrukturassertionen gelten weiter. Keine Änderungen an `generate.py`, `annotate.py`, `blindtest.py`, `meaning_check.py`, `alternative_check.py`, `classify.py`, `cli.py` oder `selection.py`. Ihre fachlichen Validatoren sind zusätzlich zur zentralen vollständigen Schema-Prüfung wirksam.

## Tatsächlicher SDK-Vertrag

Installiert und im Transporttest geprüft: `anthropic==1.15.0`, dessen Vertex-Extra bestehendes Google-Auth nutzt; neu installiert: `docstring-parser==0.18.0`, `httpx2==2.13.1`, `httpcore2==2.13.1`, `jiter==0.17.0`, `opentelemetry-api==1.45.1`, `truststore==0.10.5`.

```text
POST https://aiplatform.eu.rep.googleapis.com/v1/projects/sprachlernapp-510508/locations/eu/publishers/anthropic/models/claude-haiku-5-5:rawPredict
anthropic_version: vertex-2023-10-16 (Body)
thinking: {type: disabled}
output_config.effort: low
output_config.format: {type: json_schema, schema: <reduzierte Kopie>}
max_tokens: <unverändertes Schrittlimit>
max_retries: 0
```

Der Test liest den **wirklich vom SDK erstellten HTTP-Request**: Host, Pfad, Methode, Bodyversion, Modell im URL-Pfad statt im Body und Abwesenheit von Gemini-/Samplingparametern. Er setzt absichtlich widersprechende `ANTHROPIC_VERTEX_BASE_URL`, `CLOUD_ML_REGION` und `ANTHROPIC_VERTEX_PROJECT_ID`; trotzdem bleibt der Request exakt auf dem EU-Pfad. Laufzeitkonfiguration für anderes Modell/Projekt/global/Effort wird vor dem Transport abgelehnt. Redirect wird nicht verfolgt. Synthetischer In-Memory-Token ersetzt ADC im Test; produktiv bleibt ADC ohne zusätzlichen Secretnamen vorgesehen.

Die Schemakopie entfernt nur transportspezifisch nicht unterstützte Zahlen-/Längen-/Arraygrenzen und schließt Objektfelder für den Transport. Eigenschaftsnamen werden nicht mit Schlüsselwörtern verwechselt. Das Original wird nicht mutiert und danach vollständig mit `Draft202012Validator` geprüft, einschließlich aller entfernten Grenzen. Daher keine Lockerung der fachlichen Antwortverträge. Nur `end_turn`, gültiges JSON und lokal gültiges Originalschema liefern einen Erfolg; `max_tokens`, `refusal`, fehlende Inhalte und ungültige Antwort werden nicht repariert oder wiederholt. Textblöcke werden nach Typ gewählt, unabhängig von vorausgehenden Thinkingblöcken.

Normierte Tokens: Haiku `input_tokens`, `output_tokens`, rechnerisch `thinking_tokens=0`. Das dritte Feld ist eine Ledger-Konvention: Haiku-Ausgabe enthält Denken bereits und darf nicht doppelt berechnet werden. Fehlende, negative oder unerwartet cachebezogene Nutzungsangaben werden als unbekannt behandelt. Es wird kein Promptcache angefordert; Cachetarifunterstützung bleibt bewusst außerhalb dieses kleinen Pakets.

Offizielle Vertragsquellen (erneut abgerufen 18.10.2026): [Google-Cloud-Zugang](https://platform.claude.com/docs/en/build-with-claude/claude-on-vertex-ai), [strukturierte Antworten](https://platform.claude.com/docs/en/build-with-claude/structured-outputs), [Effort](https://platform.claude.com/docs/en/build-with-claude/effort). SDK-Version und implementiertes Routing zusätzlich direkt im installierten Paket geprüft. Region ist EU-Multiregion, **keine Zusage für Frankfurt allein**.

## Fehler, Zeitgrenzen und Budget

- Nur HTTP 429/500/502/503/504 werden höchstens dreimal insgesamt versucht. SDK-Retries sind aus; auch SDK-eigene normalerweise wiederholbare Codes wie 408/409 werden hier nicht wiederholt. Jede mögliche Wiederholung braucht vorher eine eigene Budgetprüfung/Reservierung.
- 400/401/403/404/422 und sonstige Fehler, Netzwerk-/Timeoutabbruch, Refusal, Schemafehler und Truncation führen zu kontrolliertem Abbruch. Authfehler stoppen weitere Anfragen im selben Wrapperlauf.
- Die asynchrone Deadline umfasst HTTP-Anfrage und Antwortbody, nicht bloß die Wartezeit zwischen einzelnen Bytes. Ein Test liefert einen langsam tröpfelnden Body und belegt den Abbruch; kein abgekoppelter Modellrequest-Thread läuft weiter. Ein bereits gestarteter ADC-Refresh kann lokal auslaufen, aber die abgebrochene Coroutine sendet danach keinen Modellrequest. Das ist gesondert offline geprüft.
- Die 95-s-Gesamtdeadline umfasst Warten auf Parallelbudget und Backoff; die Versuchsdeadline ist auf den verbleibenden Zeitraum begrenzt. Ein für das Restfenster zu langer Backoff startet keinen weiteren Versuch.
- Reserviert wird lokal vor jedem Versuch: serialisierte ASCII-JSON/UTF-8-Bytelänge des tatsächlichen Bodies plus 4096 Overheadtokens, dazu volles Outputlimit. Input bleibt in der lokalen Politik deutlich unter 100K. Im Dry-Run bleibt die dortige Eingabelänge eine ausdrücklich ausgewiesene Schätzung; keine Produktionsplanung ausgeführt.
- Bekannte Nutzung wird abgerechnet, auch bei Refusal/Truncation/ungültigem JSON. Gemeldete Kosten über der Reservierung stoppen weitere Requests. Unbekannte Nutzung erhält **keine erfundenen Nulltokens oder Nullkosten**: Tokencells leer, lokale Reservierung als USD-Wert, klare Kennzeichnung im Sidecar. Unklare Abbrüche stoppen wartende Folgeanfragen; transiente HTTP-Fehler behalten ihren konservativen Reservierungswert vor einem möglichen Retry.
- **Kein garantierter Anbieterrechnungsdeckel.** Token-/Schemaoverhead, serverseitig nach einem Verbindungsabbruch fortgesetzte Arbeit und unbekannte Gebühren lassen sich offline nicht beweisen. `--max-usd` ist eine konservative lokale Ausgabenpolitik. Sidecar und Ledger trennen gemeldete Nutzung von lokalen Reserved-Werten; historische CSV-Dateien bleiben lesbar. Keine Behauptung tatsächlicher Abrechnung oder Einsparung.
- Safe Sidecar: Modell, Region, Schritt, Versuch, Status, Laufzeit, HTTP-Code, erlaubter Stopgrund, reservierte/erfasste USD. Fehlermeldungen enthalten keine Raw-Providertexte; keine Exceptionkette mit `JSONDecodeError.doc` oder `ValidationError.instance` wird ausgegeben. Der requestinhaltführende Debuglogger des gepinnten SDK und seine Inhaltstelemetrie sind deaktiviert; ein DEBUG-Capture-Test prüft dies.

Parallelbudget gilt wie bisher für die Threads eines Wrapperlaufs und dessen Ledger. Keine neue kontoweite Cloudkostenkontrolle oder multiprozessübergreifende Budgetplattform. Fachliche Neugenerierungsgrenzen, Originalsatzvorrang, Kurzsatz-Ausnahme, Antwortprüfung/SRS/Zähler, TTS und Audio bleiben unverändert. Der verdeckte Blindtest ist jetzt ein separater Prompt auf **demselben** Modell, keine unabhängige zweite Modellinstanz als Qualitätsbeweis.

## Ausgeführte Prüfungen

Befehle tatsächlich auf macOS am Repository-Root ausgeführt; PowerShell-Pendants stehen in [Setup](setup.md). Keine Flutter-/Cloudprüfungen.

```text
pipeline/.venv-macos/bin/python -m pip install 'anthropic[vertex]==1.15.0' --retries 0
Successfully installed anthropic-1.15.0 docstring-parser-0.18.0 httpcore2-2.13.1
httpx2-2.13.1 jiter-0.17.0 opentelemetry-api-1.45.1 truststore-0.10.5
Exit 0 (Netzzugang für ausdrücklich erlaubte lokale Installation)

pipeline/.venv-macos/bin/python -m pip install --no-deps --no-build-isolation -e pipeline --retries 0
Successfully built sprachpipe
Successfully installed sprachpipe-0.1.0
Exit 0

pipeline/.venv-macos/bin/python -m pytest pipeline/tests/test_haiku_contract.py -q
42 passed in 1.54s
Exit 0

pipeline/.venv-macos/bin/python -m pytest pipeline/tests/test_haiku_contract.py pipeline/tests/test_generate.py pipeline/tests/test_parallel.py pipeline/tests/test_cost_schema.py pipeline/tests/test_meaning_check.py pipeline/tests/test_alternative_check.py pipeline/tests/test_selection.py -q --tb=short
156 passed in 3.83s
Exit 0

pipeline/.venv-macos/bin/python -m pip check
No broken requirements found.
Exit 0
```

Die vorhandene macOS-Umgebung hatte bei einigen Alttransitiven bereits neuere Versionen als der historische Lock (z. B. Google-Auth/Pydantic); sie wurden nicht pauschal zurückgesetzt oder aktualisiert. Neue SDK-Abhängigkeiten sind exakt im Lock gepinnt. `google-genai` ist weiter notwendig für vorhandene Werkzeug-/Snapshot-Verträge; kein unnötiges Entfernen aus dieser Migration.

Erste Prüfung der neuen Tests: 28 FAIL/12 PASS wegen eines Testfixtures, das `httpx2.AsyncClient` durch eine Funktion ersetzt hatte und damit die Typprüfung des realen SDK brach. Hypothese anhand installierter Signatur/Typprüfung bestätigt; anschließend realen HTTP-Client behalten und nur seinen Transport in-memory ersetzen: 40 PASS. Zwei zusätzliche Sicherheitsfälle ergeben 42 PASS.

Erste gezielte Regression: 10 FAIL/144 PASS wegen fehlendem `usage`-Pflichtfeld im alten Bedeutungsfake und alten Reservierungszahlen. Exaktes Originalschema mit `jsonschema` gegen das Fake geprüft (`'usage' is a required property`), Pflichtfeld im synthetischen Fake ergänzt, Kosten aus neuer Funktion nachgerechnet; danach 154 PASS, mit zusätzlichen Fällen und finaler Fehlerdiagnose 156 PASS. Keine Fachassertion entfernt, kein Produktionsschema gelockert.

Erster vollständiger Lauf (Sandbox): **2 FAIL, 628 PASS, 1 Skip, 8 ERROR, 19 Subtests PASS**, 127,34 s, Exit 1. Acht Setupfehler durch blockierte lokale HTTP-Sockets bzw. fehlendes Schreibrecht für den bestehenden Dart-SDK-Cache; der portugiesische Reader-Test scheiterte aus derselben Cacheursache (`DART_READER_FAILED`, `engine.stamp.tmp`/`engine.realm: Operation not permitted`). Keine Änderung an Editor/Dart/Flutter-Produktcode. Wiederholung mit notwendigen lokalen Testrechten folgt unten.

Zusätzlich war die Diagnosefixture `test_qa_cases.py` von unterschiedlichen realen Modellrollen ausgegangen. Da beide Rollen jetzt Haiku verwenden, wird dort allein im Fake eine explizit synthetische Prüferkennung gesetzt. Nach Beseitigung dieser Ursache wurde ein weiterer erwarteter Unterschied sichtbar: neun statt sechs Nachkommastellen im Ledger. Nur die erwartete Stringformatierung angepasst; sämtliche Formatfehler-/False-Accept-/False-Reject-Assertions erhalten. Danach `pipeline/.venv-macos/bin/python -m pytest pipeline/tests/test_qa_cases.py -q --tb=short`: **21 PASS in 0,29 s, Exit 0**. Kein unabhängiger zweiter Anbieter wird durch diesen Mock behauptet.

Vollständiger Wiederholungslauf mit den für vorhandene lokale Server-/Dart-Tests nötigen Rechten:

```text
pipeline/.venv-macos/bin/python -m pytest pipeline/tests -q
638 passed, 1 skipped, 19 subtests passed in 169.46s (0:02:49)
Exit 0
```

Der eine bestehende Skip ist `test_editor_password_local.py`: explizite lokale Supabase-Authintegration verlangt `SPRACHAPP_TEST_LOCAL_AUTH=1`; diese wurde nicht angefordert oder aktiviert. Kein übersprungener Haiku-Vertragstest. Der vollständige Lauf enthält die vorhandenen Dart-Readerprüfungen der Pipeline, keine zusätzliche Flutter-Suite oder Geräteprüfung.

Abschließender direkter Referenzcheck bestätigt dieselben sieben Produktionsaufrufe von `generate_json`; deren Dateien sind unverändert. Schutzvergleich: **3017 von 3033** versionierten Ausgangsdateien bytegleich; genau **16** erlaubte Bestandsdateien geändert, zusätzlich neuer Haiku-Vertragstest und dieser Bericht. `git diff --name-only -- assets lib supabase pipeline/data pipeline/src/sprachpipe/editor` gibt nichts aus, Exit 0. Fremdes `published-baseline-transfer/` bleibt unversioniert erhalten; Statusdatei 24 Zeilen.

`git -c core.whitespace=cr-at-eol diff --check` ohne Befund, Exit 0; der finale staged Check erfasst auch beide neuen Dateien. Aktuelle Graphbasis nach vollständigem Neuaufbau: **32.149 Knoten, 77.367 Kanten, 288 Cluster, 408 Flows**, Exit 0 (16,3 s). Vorläufiger `detect-changes --scope all --limit 500 --repo .` für die 16 schon versionierten Änderungen: **66 Symbole, 0 betroffene Prozesse, LOW**, Exit 0. Beide neuen Dateien anschließend mitgestagt und geprüft:

```text
node .gitnexus/run.cjs detect-changes --scope all --limit 500 --repo .
Changes: 18 files, 105 symbols
Affected processes: 0
Risk level: low
Exit 0

git -c core.whitespace=cr-at-eol diff --cached --check
Output leer, Exit 0
```

MCP bestätigt dieselben 18 Dateien/105 Symbole/0 Prozesse/LOW, ohne `partial:true` oder `truncated:true`. Der isolierte Commit enthält ausschließlich die 18 auftragsbezogenen Dateien; kein Push. Lokaler Runner: GitNexus 1.6.12, Node v24.21.0, Runneridentität Schema 4/current; Indexbasis der Abschlussprüfung ist der oben genannte Basiscommit mit den aktuellen Arbeitsbaumänderungen. Das zusätzliche neue Berichtsdokument und Statuszeilen werden vor dem Commit noch einmal vollständig indexiert und gegengeprüft; Produktcode wird dabei nicht verändert.

## Graph und Bestandsschutz

Arbeitsbaum zu Beginn: nur fremdes unversioniertes `published-baseline-transfer/`; unverändert belassen. 3033 versionierte Dateien vor Änderungen gehasht. Zwischenprüfung: 3018 bytegleich, zu diesem Zeitpunkt genau 15 geänderte Bestandsdateien ausschließlich im erlaubten Bereich; zusätzlich neuer Vertragstest und dieser Bericht. Kein `lib/`, `assets/`, `supabase/`, `pipeline/data/` oder Editorproduktionscode geändert. Kein Lesen echter `user.db` oder Secretdateien. Ursprüngliche LF-/CRLF-Bytes unveränderter Zeilen erhalten.

GitNexus-Impact vor Edits: Wrapper/Kosten LOW, Konfigurations-/Dokument-/Testdateien überwiegend UNKNOWN, Lock nicht indexiert. UNKNOWN durch direkte Referenzprüfung ergänzt. Wrapper-Datei zeigt CLI und Selection als direkte Importeure, weiter Authoring-/Formwerkzeuge; `reservation_usd`/Preise wirken auch auf den CLI-Dry-Run. Symbol-Caller von `generate_json` bleiben statisch nur Untergrenze; alle sieben echten Aufrufstellen direkt geprüft. Kein HIGH-/CRITICAL-Pre-Editbefund.

Reindex nach zwischenzeitlichen Änderungen: temporäre LadybugDB-Abfrage während eines noch laufenden Indexaufbaus nicht als saubere Prüfung gewertet. Inkrementeller FTS-Aufbau meldete einen fehlenden `Property.property_fts`-Index; empfohlener `--repair-fts`-Lauf Exit 1. Neue belegte Hypothese: vollständiger Graph-/FTS-Neuaufbau erforderlich. `node .gitnexus/run.cjs analyze --index-only --pdg --force` danach Exit 0: `Repository indexed successfully (15.3s)`, `32,137 nodes | 77,348 edges | 288 clusters | 408 flows`; FTS wieder verfügbar, Runneridentität Schema 4/current, keine incompleteReasons. Gesamtflowabdeckung weiterhin begrenzt; direkte Referenzprüfung und Tests ergänzen dies.

## Konkreter nächster Schritt

**Gesonderter read-only Cloudzugangsaudit**, noch kein Testprompt: Administrator prüft im bestehenden Projekt `sprachlernapp-510508` die Haiku-5.5-Modellkarte auf freigeschalteten Zugriff/akzeptierte Bedingungen, Billing-/Organisationspolicy, vorhandene Prediction-Berechtigung der vorgesehenen ADC-Identität und EU-Quote. Nichts freischalten oder ändern, keine Tokens/Schlüssel ausgeben. Bei fehlender Freischaltung ist die konkret nötige Aktion erst danach separat zu beauftragen; kein stiller Wechsel auf global oder direkte Anthropic-API.

Anschließend erst separat der im Plan begrenzte synthetische Qualitäts-/Kostenvergleich (maximal 48 Versuche/0,50 USD als lokale Politik), noch ohne persönliche Inhalte oder neue Packs. Für Paket A sind kein Supabase-Deploy, DB-Push oder Apprelease erforderlich. Geplante Runtime-KI bleibt Paket B und wurde nicht begonnen.
