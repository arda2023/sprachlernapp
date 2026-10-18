# Haiku-Liveeinrichtung auf diesem Mac

Stand: 18.10.2026. **Nicht abgeschlossen.** Ausgangsstand `1e0afe5` auf `codex/haiku-vertex-eu`; kein Branchwechsel/Reset. Implementierung `5efa65b` und vorheriger [Zugangsaudit](haiku-cloud-access-check.md) gelesen. Der alte Audit ist eine historische Momentaufnahme; dessen Trial-/Freischaltungsbefunde werden hier nicht als unverändert vorausgesetzt.

## Aktuelles Ergebnis

- Lokale Python-Umgebung vorhanden, Anthropic `1.15.0`, `pip check` erfolgreich. Bestehende 42 Haiku-Vertragstests erfolgreich.
- `gcloud --version` scheitert mit Exit 127. Weder PATH noch die sechs unten geprüften üblichen Installationspfade liefern die CLI. Keine systemweite Abwesenheit außerhalb dieser Orte behauptet.
- ADC-Suche durch die vorhandene Python-Umgebung: `DefaultCredentialsError`, kein `GOOGLE_APPLICATION_CREDENTIALS`-Override. Keine Credentialdatei oder Tokens ausgegeben. ADC-Login konnte ohne CLI nicht gestartet werden; Quotenprojekt deshalb noch nicht gesetzt.
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

CLI-, Browser- und ADC-Identität sind getrennt. Der offene Browser belegt keinen Python-Principal. Der tatsächliche ADC-Principal sowie dessen Prediction-/Service-Usage-Rechte bleiben bis zur lokalen Anmeldung ungeprüft; keine andere Identität wird eingesetzt. Keine eigenständigen Billing-, IAM- oder Quotenänderungen. Die Modellkarte allein belegt weder funktionierende API-Inferenz noch EU-Kapazität.

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

Die sechs mit `Path.exists()` untersuchten CLI-Pfade waren `/opt/homebrew/share/google-cloud-sdk/bin/gcloud`, `/usr/local/share/google-cloud-sdk/bin/gcloud`, `/Users/ardasayar/google-cloud-sdk/bin/gcloud`, `/Users/ardasayar/Downloads/google-cloud-sdk/bin/gcloud`, `/opt/homebrew/bin/gcloud`, `/usr/local/bin/gcloud`. Die Authprobe gab ausschließlich Typnamen und einen booleschen Override-Status aus; keine Credentialwerte und keinen rohen Fehlertext. Keine Refresh- oder Modellmethode aufgerufen.

Chrome nur lesend: vorhandene Modellkarte unter `https://console.cloud.google.com/agent-platform/publishers/anthropic/model-garden/claude-haiku-5-5?service=anthropic-932.cloudpartnerservices.goog&project=sprachlernapp-510508` gelesen; danach eigene temporäre Quotenansicht unter `https://console.cloud.google.com/iam-admin/quotas?project=sprachlernapp-510508`, Tabellenfilter `anthropic-claude-haiku`. Nach vollständigem Laden EU-Familienzeilen gelesen. Kein Prompt abgesendet; Browseraktionen haben keinen Shell-Exitcode.

## Genau nächste Bedienung

**Google Cloud CLI für diesen Apple-Silicon-Mac installieren.** Wie im Auftrag für fehlendes gcloud vorgesehen wurde der Installationsschritt genannt, kein alternativer Authentifizierungsweg improvisiert. Offizielle [Google-Installationsanleitung, macOS](https://docs.cloud.google.com/sdk/docs/install-sdk#mac): Paket „macOS 64-bit (ARM64, Apple silicon)“ herunterladen, außerhalb des Repositorys entpacken, dessen `google-cloud-sdk/install.sh` ausführen und PATH einrichten. Anschließend Terminal neu öffnen und `gcloud --version` prüfen. Keine Zugangsdaten an den Agenten senden. Installation wurde vom Agenten nicht ausgeführt; Rückmeldung des Nutzers steht aus.

Danach kann der bereits autorisierte ADC-Ablauf fortgesetzt werden (diese Befehle sind **noch nicht ausgeführt**; gleich unter macOS Terminal und Windows PowerShell):

```text
gcloud auth application-default login
gcloud auth application-default set-quota-project sprachlernapp-510508
```

Kontowahl/Zustimmung erfolgt persönlich im gestarteten Browser. Keine separate CLI-Anmeldung als Ersatz für ADC. Anschließend ADC-Quotenprojekt sicher aus den geladenen Metadaten prüfen, keine Datei ausgeben und keinen Token drucken.

Vor dem ersten Modellaufruf ist zusätzlich die EU-Quote zu klären: [Kontingente des konkreten Projekts](https://console.cloud.google.com/iam-admin/quotas?project=sprachlernapp-510508) → Filter `anthropic-claude-haiku` → die drei „EU multi-region online prediction“-Zeilen auswählen → Kontingentanpassung anfragen, soweit die Console dies zulässt. Dies muss der Nutzer/Administrator veranlassen. Für nur diese drei kurzen Proben keine Produktionskapazität beantragen; die erforderliche positive Zuteilung muss erst sichtbar sein. Bei nicht verfügbarer Anpassung die konkrete EU-Familie beim Google-Cloud-Support klären. Keine Quotenänderung durch den Agenten; keine Ausweichregion.

## Quellen und Erhalt

Am 18.10.2026 überprüft: [offizieller lokaler ADC-Login](https://docs.cloud.google.com/docs/authentication/set-up-adc-local-dev-environment) und [Claude-Familienquoten](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/partner-models/claude/quotas). Die Quote gehört bei Haiku 5.5 zur Familie `anthropic-claude-haiku`; EU und global sind getrennt. Allgemeine Dokumentationslimits ersetzen die beobachteten Projektlimits nicht.

Nur dieser Bericht und eine Statuszeile in `NEXTSTEPS.md` ändern sich. Kein belegter Implementierungsfehler, daher keine Code-, Konfigurations- oder Abhängigkeitsänderung. Produktionspacks, Assets, Manifest, Editor, user.db, Lernstände, Flutter und Supabase unangetastet; keine Importe, Content-Staging, Veröffentlichung, Deployment oder Push. Fremdes `published-baseline-transfer/` bleibt erhalten. Die Dokumente werden vor einem isolierten Commit gezielt auf CRLF/Whitespace und Änderungsumfang geprüft; GitNexus UNKNOWN wird durch expliziten Text-/Dokumentdiff geprüft.

Dokumentprüfung: `git -c core.whitespace=cr-at-eol diff --cached --check -- docs/haiku-live-setup.md NEXTSTEPS.md` Exit 0. Python-Byteprüfung: beide Dateien CRLF, NEXTSTEPS 24 Zeilen, genau eine Statuszeile verändert, alle anderen unverändert; Exit 0. Staging exakt zwei eigene Dokumente, geschützte versionierte Dateien unverändert. `node .gitnexus/run.cjs detect-changes --scope all --repo .`: Exit 0, 2 Dateien/2 Dokumentabschnitte/0 Prozesse, Risiko low, kein partial/truncated gemeldet; neues Dokument zusätzlich vollständig als Dokumentdiff geprüft.
