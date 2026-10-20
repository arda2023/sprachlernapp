# Haiku-Liveeinrichtung auf diesem Mac

Stand: 18.10.2026. **Nicht abgeschlossen.** Erstprüfung ab `1e0afe5`, Fortsetzung ab `2b78981` auf `codex/haiku-vertex-eu`; kein Branchwechsel/Reset. Implementierung `5efa65b` und vorheriger [Zugangsaudit](haiku-cloud-access-check.md) gelesen. Der alte Audit ist eine historische Momentaufnahme; dessen Trial-/Freischaltungsbefunde werden hier nicht als unverändert vorausgesetzt.

## Aktuelles Ergebnis

- Lokale Python-Umgebung vorhanden, Anthropic `1.15.0`, `pip check` erfolgreich. Bestehende 42 Haiku-Vertragstests erfolgreich.
- Erstprüfung: `gcloud --version` Exit 127. Danach installierte der Nutzer die CLI. Jetzt unter `/Users/ardasayar/google-cloud-sdk/bin/gcloud` gefunden: Google Cloud SDK **589.0.0**, Exit 0. Die bestehende Agent-Shell hat den neuen PATH noch nicht übernommen; absoluter Pfad verwendet, keine Shell-Konfiguration geändert.
- Erstprüfung: ADC fehlten. Nach Nutzerinstallation offiziellen interaktiven ADC-Login gestartet; Nutzer bestätigte Kontowahl/Zustimmung persönlich, Login Exit 0. Quotenprojekt ausdrücklich auf `sprachlernapp-510508` gesetzt, Exit 0. Die vorhandene Pipeline-Python-Umgebung lädt und erneuert diese ADC erfolgreich (`valid=true`, Quotenprojekt korrekt). Keine Credentialdatei oder Tokens ausgegeben. `default_project=null` ist hier kein falsches Zielprojekt: der bestehende Vertex-Client setzt seine Projekt-ID explizit.
- Nutzerseitige Modellaktivierung durch lesenden Chrome-Zugriff bestätigt: Modellkarte für `claude-haiku-5-5` im Projekt `sprachlernapp-510508` zeigt „In Agent Studio öffnen“. Keine Modellaktivierung durch den Agenten.
- Aktuelle Console-Quotenprüfung nach dieser Aktivierung: `base_model=anthropic-claude-haiku`, EU-Multiregion-Anfragen/min, Eingabetokens/min und Ausgabetokens/min jeweils **Wert 0**, Nutzung 0. Kein Wechsel zur Zeile `anthropic-claude-haiku-4-5`, zu global oder einer Einzelregion.
- **0 echte Modellanfragen ausgeführt, 0 SDK-Retries.** Minimalprobe und die davon abhängigen en-/pt-BR-Proben nicht gestartet. Anbieter-Tokenzahlen, Modelllatenz und Live-Ausgabevalidierung sind daher unbekannt; kein technischer oder sprachlicher Live-PASS.

## Unveränderter implementierter Vertrag

Aus `pipeline/src/sprachpipe/llm.py` und `pipeline/config.yaml`:

```text
project_id: sprachlernapp-510508
model: claude-haiku-5-5
region: eu
base_url: https://aiplatform.eu.rep.googleapis.com/v1
POST /v1/projects/sprachlernapp-510508/locations/eu/publishers/anthropic/models/claude-haiku-5-5:rawPredict
AsyncAnthropicVertex; ADC; max_retries=0; follow_redirects=False
thinking: disabled; output_config.effort: low; output_config.format: json_schema
```

Der Request-Hook prüft Host/Pfad/Methode; nach der Antwort validiert der Wrapper das vollständige Originalschema. Die Produktionskonfiguration erlaubt äußere Wiederholungen (`max_attempts=3`). Für eine spätere autorisierte Probe muss deshalb ausschließlich die in den Speicher geladene Versuchskonfiguration `max_attempts=1` setzen; die Datei bleibt unverändert. Höchstens drei physische Modellrequests insgesamt, jeweils maximal 256 Ausgabetokens und kurze synthetische Eingaben unter 2000 Tokens. Kein Tokenzähl-Modellaufruf als versteckte Zusatzprobe. Vorheriger Fehler stoppt die Folgeproben. Noch kein Liveversuchskript ausgeführt.

CLI-, Browser- und ADC-Identität sind getrennt. Die erneuerte ADC wurde mit der bestehenden Pipeline-Python-Umgebung geprüft; kein CLI-Login als Ersatz. Die Credentialklasse ist `google.oauth2.credentials.Credentials`; deren `account`-Metadatum ist leer. Ein konkreter Principalname wurde damit nicht ermittelt und nicht aus dem Browserkonto abgeleitet. Der lesende Versuch, genau mit diesen ADC `aiplatform.endpoints.predict` und `serviceusage.services.use` abzufragen, erhielt HTTP 403 mit strukturiertem Grund `SERVICE_DISABLED` für `cloudresourcemanager.googleapis.com`. Das belegt keine fehlenden Prediction-Rechte; die effektive Rechteprüfung bleibt nicht prüfbar. Die API wurde nicht aktiviert und keine andere Identität eingesetzt. Keine eigenständigen Billing-, IAM- oder Quotenänderungen. Die Modellkarte allein belegt weder funktionierende API-Inferenz noch EU-Kapazität.

## Ausgeführte Prüfungen

Befehle im Repository-Root auf macOS/zsh. Outputs sicher gekürzt; keine Header, Credentialdateiinhalte, Schlüssel oder Tokens.

| Befehl / Prüfung | Output | Exit |
| --- | --- | --- |
| `git status --short` (vor eigenen Änderungen) | ausschließlich fremdes `?? published-baseline-transfer/` | 0 |
| `git log -1 --format='%h %s'` | `1e0afe5 docs: record read-only Haiku cloud access audit` | 0 |
| `command -v gcloud` | kein Treffer | 1 |
| `gcloud --version` | `command not found: gcloud` | 127 |
| `uname -m` | `arm64` | 0 |
| `pipeline/.venv-macos/bin/python -m pip check` | `No broken requirements found.`; Cache-Warnung wegen gesperrtem pip-Cache, keine Installation | 0 |
| `pipeline/.venv-macos/bin/python -c 'import anthropic; print("anthropic",anthropic.__version__)'` | `anthropic 1.15.0` | 0 |
| `pipeline/.venv-macos/bin/python -m pytest pipeline/tests/test_haiku_contract.py -q` | `42 passed in 1.53s` | 0 |
| Python-Präsenzprüfung + `google.auth.default(scopes=['https://www.googleapis.com/auth/cloud-platform'])` | sechs CLI-Pfade false; ADC missing / `DefaultCredentialsError`, Override false | 2 |
| `node .gitnexus/run.cjs impact NEXTSTEPS.md --direction upstream --repo .` | UNKNOWN; keine aufgelösten Caller/Prozesse, Index einen Dokumentcommit hinter HEAD | 0 |
| `node .gitnexus/run.cjs impact docs/haiku-live-setup.md --direction upstream --repo .` | neues Dokument nicht im Graph, UNKNOWN | 1 |
| `rg -n 'NEXTSTEPS.md|haiku-live-setup' AGENTS.md CLAUDE.md docs/setup.md NEXTSTEPS.md` | Statusreferenzen in AGENTS:22 / CLAUDE:66; neues Dokument ohne vorhandene Referenz | 0 |

Die sechs mit `Path.exists()` untersuchten CLI-Pfade waren `/opt/homebrew/share/google-cloud-sdk/bin/gcloud`, `/usr/local/share/google-cloud-sdk/bin/gcloud`, `/Users/ardasayar/google-cloud-sdk/bin/gcloud`, `/Users/ardasayar/Downloads/google-cloud-sdk/bin/gcloud`, `/opt/homebrew/bin/gcloud`, `/usr/local/bin/gcloud`. Die anfängliche Authprobe gab ausschließlich Typnamen und einen booleschen Override-Status aus. Bei der Fortsetzung wurden ADC über die Authbibliothek geladen und erneuert; ausgegeben wurden nur Credential-Typ, leeres Account-Metadatum, `valid`, Default-/Quotenprojekt und sichere Fehlerklassifikation. Kein Token und kein roher Providerfehlertext, keine Modellmethode.

Chrome nur lesend: vorhandene Modellkarte unter `https://console.cloud.google.com/agent-platform/publishers/anthropic/model-garden/claude-haiku-5-5?service=anthropic-932.cloudpartnerservices.goog&project=sprachlernapp-510508` gelesen; danach eigene temporäre Quotenansicht unter `https://console.cloud.google.com/iam-admin/quotas?project=sprachlernapp-510508`, Tabellenfilter `anthropic-claude-haiku`. Nach vollständigem Laden EU-Familienzeilen gelesen. Kein Prompt abgesendet; Browseraktionen haben keinen Shell-Exitcode.

## Fortsetzung nach der persönlichen Anmeldung

Die folgenden Schritte sind tatsächlich ausgeführt (absoluter CLI-Pfad auf diesem Mac):

```text
/Users/ardasayar/google-cloud-sdk/bin/gcloud --version
/Users/ardasayar/google-cloud-sdk/bin/gcloud auth application-default login --project=sprachlernapp-510508
/Users/ardasayar/google-cloud-sdk/bin/gcloud auth application-default set-quota-project sprachlernapp-510508
```

Alle drei Exit 0. Der erste Versionsaufruf im Sandboxkontext meldete zusätzlich ein gesperrtes gcloud-Logverzeichnis; Login und Quotenprojekt wurden anschließend mit dem erforderlichen lokalen Schreib-/Netzzugriff ausgeführt. Der Login wurde per Python-Subprozess gestartet; dessen Ausgabe wurde auf feste Statuszeilen gefiltert, damit weder OAuth-URL noch Zugangsdaten protokolliert werden. Ausgabe: `ADC lokal gespeichert`, `ADC_LOGIN_EXIT=0`. Der Quotenprojektbefehl bestätigt `sprachlernapp-510508`. Lokal übliche ADC-Speicherung außerhalb des Repositorys; keine Datei kopiert oder manuell ausgegeben.

Python-Prüfung mit `pipeline/.venv-macos/bin/python`, `google.auth.default(scopes=['https://www.googleapis.com/auth/cloud-platform'])`, `c.refresh(Request())`: `adc=ok`, `credential_type=Credentials`, `default_project=null`, `quota_project=sprachlernapp-510508`, `valid=true`, `account=""`; Exit 0. Keine Tokens ausgegeben. Danach rein lesender `testIamPermissions`-POST an `https://cloudresourcemanager.googleapis.com/v1/projects/sprachlernapp-510508:testIamPermissions` über `AuthorizedSession(c)` mit den beiden Berechtigungsnamen: HTTP 403. Ein zweiter lesender Abruf wurde gezielt zur Fehlerklassifikation verwendet: `reason=SERVICE_DISABLED`, `domain=googleapis.com`, `service=cloudresourcemanager.googleapis.com`; Prozess jeweils Exit 0, HTTP-Prüfung nicht erfolgreich. **Keine Rollenverweigerung daraus ableiten.** Keine API-Aktivierung als Umweg.

Die EU-Quotenansicht wurde nach dem ADC-Login frisch geöffnet, geladen und wieder mit `anthropic-claude-haiku` gefiltert. Für die Familienzeile ohne `-4-5`: alle drei EU-Werte weiterhin **0**, Nutzung 0. Deshalb Stopp vor dem ersten Modellrequest, unabhängig von der erfolgreichen lokalen Authentifizierung. Noch **0 von höchstens 3** Modellanfragen genutzt. Anbieter-Latenz und Tokens weiterhin unbekannt. Die 42 Vertragstests und `pip check` aus der Erstprüfung wurden nicht ohne Codeänderung erneut ausgeführt.

## Genau nächste Nutzeraktion

**Positive EU-Haiku-Familienkontingente anfragen.** Die gefilterte Console-Ansicht wurde für den Nutzer offen gelassen: [Kontingente des Projekts](https://console.cloud.google.com/iam-admin/quotas?project=sprachlernapp-510508) → Filter `anthropic-claude-haiku` → die drei Zeilen „EU multi-region online prediction input tokens…“, „…output tokens…“ und „…requests…“ für exakt `base_model: anthropic-claude-haiku` → Kontingentanpassung anfragen, soweit die Console dies zulässt. Keine Produktionskapazität für diese drei kurzen Tests beantragen. Falls keine Anpassung angeboten wird, genau diese drei EU-Familienkontingente durch Google-Cloud-Support klären lassen. Der Agent nimmt keine Quoten-, Billing- oder IAM-Änderung vor. Kein global-/US-Test.

Erst nach sichtbarer positiver EU-Zuteilung die autorisierten begrenzten Proben fortsetzen. Die deaktivierte Resource-Manager-API ist nur ein Hindernis für den gewählten lesenden IAM-Prüfweg; sie muss nicht allein für diese Probe aktiviert werden. Ein späterer konkreter Inferenzfehler wird einmal ausgewertet, ohne Wiederholung oder Ausweichroute. Die Einrichtung bleibt bis zum erfolgreichen EU-Modellaufruf und den abhängigen technischen Proben ausdrücklich nicht abgeschlossen.

## Quellen und Erhalt

Am 18.10.2026 überprüft: [offizieller lokaler ADC-Login](https://docs.cloud.google.com/docs/authentication/set-up-adc-local-dev-environment) und [Claude-Familienquoten](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/partner-models/claude/quotas). Die Quote gehört bei Haiku 5.5 zur Familie `anthropic-claude-haiku`; EU und global sind getrennt. Allgemeine Dokumentationslimits ersetzen die beobachteten Projektlimits nicht.

Nur dieser Bericht und eine Statuszeile in `NEXTSTEPS.md` ändern sich. Kein belegter Implementierungsfehler, daher keine Code-, Konfigurations- oder Abhängigkeitsänderung. Produktionspacks, Assets, Manifest, Editor, user.db, Lernstände, Flutter und Supabase unangetastet; keine Importe, Content-Staging, Veröffentlichung, Deployment oder Push. Fremdes `published-baseline-transfer/` bleibt erhalten. Die Dokumente werden vor einem isolierten Commit gezielt auf CRLF/Whitespace und Änderungsumfang geprüft; GitNexus UNKNOWN wird durch expliziten Text-/Dokumentdiff geprüft.

Dokumentprüfung: `git -c core.whitespace=cr-at-eol diff --cached --check -- docs/haiku-live-setup.md NEXTSTEPS.md` Exit 0. Python-Byteprüfung: beide Dateien CRLF, NEXTSTEPS 24 Zeilen, genau eine Statuszeile verändert, alle anderen unverändert; Exit 0. Staging exakt zwei eigene Dokumente, geschützte versionierte Dateien unverändert. `node .gitnexus/run.cjs detect-changes --scope all --repo .`: Erstprüfung Exit 0, 2 Dateien/2 Dokumentabschnitte/0 Prozesse, Risiko low, kein partial/truncated gemeldet. Vor dieser Dokumentfortsetzung erneut impact ausgeführt: Bericht im um zwei Dokumentcommits zurückliegenden Index nicht aufgelöst (Exit 1, UNKNOWN), Statusdatei UNKNOWN; Textreferenzen in NEXTSTEPS/AGENTS/CLAUDE bestätigt. Vollständiger Dokumentdiff zusätzlich geprüft; Änderungsanalyse vor erneutem Commit wiederholt.

Fortsetzungsprüfung: Eine Zwischenprüfung fand neu eingefügte LF-Zeilen; vor dem Commit vollständig auf CRLF normalisiert. Abschließender gezielter CRLF-/Diffcheck und Prüfung auf genau zwei eigene Dokumente bestanden. Keine erneute Testsuite für die reine Dokumentfortsetzung.
