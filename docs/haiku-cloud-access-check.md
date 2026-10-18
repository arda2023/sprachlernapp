# Haiku 5.5: lesender Cloud-Zugangsaudit

Stand: 18.10.2026, macOS-Arbeitsumgebung; Ausgangscommit `5efa65b91410c6c4b097b1a4d31c3a57bd2c99c7`, Branch `codex/haiku-vertex-eu`.

## Ergebnis

**Der Anschluss ist derzeit blockiert.** Das Projekt und die EU-Modellroute sind belegt. Die Cloud Console zeigt für die Haiku-Familie drei EU-Kontingente mit Wert **0** und ein Rechnungskonto im kostenlosen Testzeitraum. Zusätzlich findet die lokale Python-Pipeline keine Application Default Credentials (ADC). Dies ist kein Nachweis eines IAM-Verbots und keine Aussage, dass das Modell grundsätzlich nicht verfügbar wäre.

Keine Modellanfrage ausgeführt. Kein Live-Nachweis, keine API-Aktivierung, Anmeldung, Rollen-, Billing- oder sonstige Cloudänderung. Auch ein später bestandener Zugangsaudit würde keine erfolgreiche Modellanfrage belegen.

## Vertrag aus dem Arbeitsstand

Gelesen: `AGENTS.md`, `docs/haiku-migration-plan.md`, `docs/haiku-migration-implementation.md`, `pipeline/config.yaml`, `pipeline/src/sprachpipe/llm.py`, `docs/setup.md`, `NEXTSTEPS.md`.

- Projekt: `sprachlernapp-510508`; Console bestätigt Projektname `sprachlernapp`, Projektnummer `540709320423`.
- Modell: `claude-haiku-5-5`, Publisher `anthropic`; alle vier konfigurierten Textmodellrollen verwenden dieses Modell.
- Standort: `eu`; Host `aiplatform.eu.rep.googleapis.com`, Basis-URL `https://aiplatform.eu.rep.googleapis.com/v1`.
- Erwartete vollständige Route: `https://aiplatform.eu.rep.googleapis.com/v1/projects/sprachlernapp-510508/locations/eu/publishers/anthropic/models/claude-haiku-5-5:rawPredict`.
- `Llm.client` verwendet `AsyncAnthropicVertex`, ohne explizite Credentials oder Access Token: Authentifizierung über ADC. Redirects sind deaktiviert; der Request-Hook prüft die feste Route. Kein anderer Standort oder Anbieter als Ausweichweg.
- Thinking deaktiviert, Effort low; strukturierte Ausgabe gehört zum implementierten Vertrag. Bestehende Offline-Nachweise stehen im Implementierungsbericht; für diesen Audit wurden keine Testsuiten erneut ausgeführt.

## Befunde und Grenzen

„belegt“ bezeichnet eine konkret beobachtete Tatsache, „blockiert“ eine aktuell nicht erfüllte Voraussetzung, „nicht prüfbar“ fehlende oder widersprüchliche Einsicht.

| Prüfpunkt | Ergebnis | Beobachtung / Grenze |
| --- | --- | --- |
| Projekt und implementierter EU-Vertrag | belegt | Code/Konfiguration und Projekt-Dashboard stimmen bei Projekt-ID überein. Öffentliche Google-Dokumentation führt Haiku 5.5 mit EU-Multiregion. |
| Vertex-Dienst | belegt | Vollständig geladene Liste „Aktivierte APIs und Dienste“, 25 von 25: `aiplatform.googleapis.com` als „Agent Platform API“ vorhanden. |
| Procurement-Dienst | belegt | `cloudcommerceconsumerprocurement.googleapis.com` fehlt in dieser vollständigen aktivierten Liste. Keine Aktivierung vorgenommen. Die öffentliche Anleitung nennt die Zulässigkeit dieses Dienstes für die Partnerfreischaltung; daraus wird kein separates Laufzeit-IAM-Verbot abgeleitet. |
| Billing-Zuordnung | belegt | Projektbezogener Billing-/linkedaccount-Aufruf führt zum bestehenden Rechnungskonto; Übersicht bezeichnet es ausdrücklich als „Konto für kostenlosen Testzeitraum“ und bietet „Upgrade“ an. Keine Kontonummer oder Zahlungsdaten in diesen Bericht übernommen. |
| Billing-Eignung für Partner-MaaS | blockiert | Google schließt den Zugriff auf verwaltete generative Partner-APIs im Free Trial aus. Ein vorhandenes Trial-Guthaben ist daher kein Haiku-Zugangsnachweis. Keine Änderung vorgenommen. |
| Konkrete Haiku-Freischaltung / Vertragsstatus | nicht prüfbar | Modellkarte für exakt `claude-haiku-5-5` zeigt zugleich „Dieses Modell ist für Ihr Projekt einsatzbereit“ und die Schaltfläche „Aktivieren“ sowie ein Bestätigungsfeld. Kein eindeutiger abgeschlossener Entitlement-/Vertragsnachweis. „Aktivieren“ und Bestätigungsfeld nicht betätigt. |
| Aktuelle lokale ADC | blockiert | `google.auth.default` scheitert mit `DefaultCredentialsError`; kein Umgebungs-Override und keine bekannte lokale ADC-Datei vorhanden. Keine Token-Ausgabe oder Anmeldung. |
| CLI-Anmeldung | nicht prüfbar | `gcloud` weder im PATH noch in den geprüften Installationsorten gefunden. Deshalb keine Aussage über eine eventuell auf einem anderen Rechner vorhandene CLI-Anmeldung. |
| Browser-Anmeldung | belegt | Bereits angemeldete Chrome-Console konnte nach Wiederherstellung des Browserzugriffs gelesen werden. Browserkonto ist keine nachgewiesene Pipeline-Identität; dessen E-Mail wird hier nicht gespeichert. |
| Tatsächlich vorgesehene Laufzeitidentität und ihre Rechte | nicht prüfbar | ADC-Mechanismus eindeutig, konkreter Principal in dieser Umgebung nicht bestimmbar. Daher `aiplatform.endpoints.predict`, gegebenenfalls `serviceusage.services.use`, IAM-Bedingungen/Deny und sonstige effektive Zugriffsregeln nicht für diese Identität prüfbar. Keine andere Identität zum Umgehen eingesetzt. |
| Organisations-/Modellbeschränkungen | nicht prüfbar | Projekt-Einstellungen weisen auf fehlende Organisationszuordnung hin. Richtlinienliste: `vertexai.allowedModels` inaktiv, `vertexai.allowedPartnerModelFeatures` aktiv. Deren Detailseite zeigt nur, dass eine Ressource unter einer Organisation gewählt werden müsse. Effektive Werte, insbesondere für strukturierte Ausgabe, bleiben unbekannt; „aktiv“ allein bedeutet kein konkretes Haiku-Verbot. Service-/Endpoint-/Standortbeschränkungen und VPC Service Controls nicht vollständig belegt. |
| EU-Haiku-Kontingente | blockiert | Console-Filter `anthropic-claude-haiku`: EU-Anfragen/min, EU-Eingabetokens/min und EU-Ausgabetokens/min jeweils **Wert 0**, aktuelle Nutzung 0. Verwendet wurde die Familienzeile ohne Suffix `-4-5`. |
| Sofort verfügbare Kapazität / Provisioned Throughput | nicht prüfbar | Keine Anfrage gesendet; keine freie Kapazität oder gebuchte Kapazität nachgewiesen. Öffentliche endpointbezogene Dokumentation schließt Provisioned Throughput für Multiregion aus; die allgemeine Modellkarte nennt es als unterstützte Nutzungsart. Daraus wird keine EU-Kapazitätszusage abgeleitet. |

## Aktuelle offizielle Dokumentation

Abgerufen am 18.10.2026. Öffentliche Angaben ersetzen keine Projektfreigabe.

- [Haiku-5.5-Modellkarte](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/partner-models/claude/haiku-5-5): Modell-ID, GA und EU-Multiregion; allgemeine Standardlimits sind keine diesem Projekt gewährten Limits.
- [Claude-Quoten](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/partner-models/claude/quotas): Nach dem 26.05.2026 veröffentlichte Modelle verwenden gemeinsame Familienkontingente. Für Haiku 5.5 ist `base_model=anthropic-claude-haiku` relevant. EU und global sind getrennte Kontingenttöpfe. Relevante Metriken unter `aiplatform.googleapis.com/`: `eu_multi_region_online_prediction_requests_per_base_model`, `eu_multi_region_online_prediction_input_tokens_per_minute_per_base_model`, `eu_multi_region_online_prediction_output_tokens_per_minute_per_base_model`. Die Console zeigt für diese EU-Familie jeweils 0; es wurde keine Quotenart vorab angenommen.
- [Partnermodelle und Multiregion](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/partner-models/use-partner-models): bestätigt EU-Host und `locations/eu`, dedizierte Multiregionkontingente und den Ausschluss von Provisioned Throughput an diesem Endpoint. Für Inferenz ist `aiplatform.endpoints.predict` relevant; die Procurement-Entitlement-Manager-Rolle betrifft die Modellaktivierung und wird hier nicht pauschal als notwendige Pipeline-Laufzeitrolle gefordert. Die Procurement-API muss für die Freischaltung durch Richtlinien zugelassen sein.
- [Modellzugriff steuern](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/control-model-access): relevante Constraints `vertexai.allowedModels` und `vertexai.allowedPartnerModelFeatures`; zu prüfende Werte `publishers/anthropic/models/claude-haiku-5-5:predict` und `publishers/anthropic/models/claude-haiku-5-5:structured_outputs`. Effektive Werte hier nicht einsehbar.
- [Free-Trial-Grenzen](https://docs.cloud.google.com/free/docs/free-cloud-features): verwaltete generative Partner-APIs sind vom Trial-Zugang und dessen Guthaben ausgeschlossen; kostenpflichtiges Billing ist eine separate Voraussetzung.
- [ADC-Suche](https://docs.cloud.google.com/docs/authentication/application-default-credentials) und [CLI-Authentifizierung](https://docs.cloud.google.com/sdk/docs/authenticate): CLI-Login und ADC sind separate Konfigurationen. ADC sucht nach Umgebungs-Credentials, lokaler ADC-Konfiguration und gegebenenfalls angehängter Laufzeitidentität. Eine angemeldete CLI oder Console beweist keine ADC-Identität.

## Lesendes Prüfprotokoll

Die folgenden Befehle wurden in macOS/zsh im Projektverzeichnis ausgeführt; Outputs sind sicher gekürzt. Keine Credential-Dateiinhalte, Tokens oder Schlüssel wurden ausgegeben. Browsernavigation hat keinen Shell-Exitcode.

| Tatsächliche Prüfung | Sicher gekürzter Output | Exitcode |
| --- | --- | --- |
| `git status --short` | Nur fremd/untracked: `?? published-baseline-transfer/` vor den eigenen Dokumentänderungen | 0 |
| `command -v gcloud` | kein Treffer | 1 |
| `gcloud version --format=json` | `command not found: gcloud` | 127 |
| Python-Existenzprüfung bekannter SDK-Pfade mit `Path.exists()` | Homebrew share/Caskroom, `/usr/local/share`, Home/Downloads SDK und `~/.local/bin`: alle false | 0 |
| `rg --files /opt/homebrew/bin /usr/local/bin /Users/ardasayar/.local/bin /Users/ardasayar/Downloads -g gcloud -g google-cloud-sdk 2>/dev/null` | keine Treffer; mindestens ein Suchpfad nicht vorhanden, deshalb keine vollständige Systemaussage | 2 |
| `rg --files /Users/ardasayar/Documents /Users/ardasayar/dokumente /opt /usr/local /Applications -g 'gcloud' -g '!node_modules/**' -g '!Library/**' 2>/dev/null` | keine Treffer in den untersuchten Wurzeln | 1 |
| ADC-Probe unten, bestehendes `pipeline/.venv-macos/bin/python` | `adc_load=failed`, `error_type=DefaultCredentialsError`, Override false | 2 |
| Python-Präsenzprobe mit `google.auth._cloud_sdk.get_application_default_credentials_path()` und `Path.exists()` | ADC-Datei false, gcloud-Konfigurationsverzeichnis false, CLOUDSDK_CONFIG/GOOGLE_APPLICATION_CREDENTIALS/CLI-Impersonation-Override jeweils nicht gesetzt | 0 |
| `node .gitnexus/run.cjs context client --file pipeline/src/sprachpipe/llm.py --repo .` | `Llm.client`, Zeilen 335–350; keine aufgelösten Prozesse | 0 |
| `node .gitnexus/run.cjs impact NEXTSTEPS.md --direction upstream --repo .` | UNKNOWN, keine aufgelösten Prozesse; Textreferenzen in AGENTS/CLAUDE anschließend bestätigt | 0 |
| `node .gitnexus/run.cjs impact docs/haiku-cloud-access-check.md --direction upstream --repo .` | Neues Dokument nicht im Graph; UNKNOWN, gezielter Text-/Diffcheck erforderlich | 0 |

ADC-Probe (tatsächlich verwendeter Python-Code; als stdin an `pipeline/.venv-macos/bin/python`):

```python
import os, json, logging
logging.disable(logging.CRITICAL)
from google.auth import default
try:
    c, p = default(scopes=['https://www.googleapis.com/auth/cloud-platform'])
    print(json.dumps({'adc_load': 'ok',
        'credential_type': type(c).__module__ + '.' + type(c).__name__,
        'default_project': p, 'quota_project': getattr(c, 'quota_project_id', None),
        'account': getattr(c, 'account', None),
        'service_account_email': getattr(c, 'service_account_email', None),
        'valid': c.valid,
        'google_application_credentials_override': bool(os.environ.get('GOOGLE_APPLICATION_CREDENTIALS'))}))
except Exception as e:
    print(json.dumps({'adc_load': 'failed', 'error_type': type(e).__name__,
        'google_application_credentials_override': bool(os.environ.get('GOOGLE_APPLICATION_CREDENTIALS'))}))
    raise SystemExit(2)
```

Keine Refresh-/Modellmethode aufgerufen. Der Code instanziiert nicht den Pipeline-Client. Die Probe gab ausschließlich den oben angegebenen Fehlerzweig aus.

Browserprotokoll (vorhandene Chrome-Sitzung, nur Lesen/Navigation/Tabellenfilter):

1. Früherer nativer Chrome-Zugriff lief in ein Tool-Timeout; daraus keine Aussage über Cloudrechte. Nach Nutzerhinweis war der Chrome-Extension-Zugriff verfügbar, ohne Anmeldung durch den Agenten.
2. [Projekt-Dashboard](https://console.cloud.google.com/home/dashboard?project=sprachlernapp-510508): ID und Nummer gelesen.
3. [Aktivierte APIs](https://console.cloud.google.com/apis/dashboard?project=sprachlernapp-510508&show=all): nach vollständigem Laden 25/25 gelesen.
4. [Haiku-Modellkarte](https://console.cloud.google.com/agent-platform/publishers/anthropic/model-garden/claude-haiku-5-5?project=sprachlernapp-510508): widersprüchliche Einsatzbereit-/Aktivieren-Anzeige gelesen; keine Aktivierung.
5. [Billing-Zuordnung](https://console.cloud.google.com/billing/linkedaccount?project=sprachlernapp-510508): bestehende Trial-Übersicht gelesen; kein Upgrade.
6. [Projekteinstellungen](https://console.cloud.google.com/iam-admin/settings?project=sprachlernapp-510508) und [Organisationsrichtlinien](https://console.cloud.google.com/iam-admin/orgpolicies?project=sprachlernapp-510508): Filter `vertexai`, anschließend Partnerfeature-Detailseite gelesen; Detailwerte nicht verfügbar.
7. [Kontingente](https://console.cloud.google.com/iam-admin/quotas?project=sprachlernapp-510508): Filter `anthropic-claude-haiku`, EU-Familienzeilen mit jeweils Wert 0 gelesen. Keine Erhöhungsanfrage.

## Kleinste nächste Nutzeraktion und verbleibende Reihenfolge

**Zuerst persönlich entscheiden, ob das vorhandene Trial-Rechnungskonto für kostenpflichtige Partnernutzung umgestellt werden soll.** Konkreter Weg: [Billing des Projekts](https://console.cloud.google.com/billing/linkedaccount?project=sprachlernapp-510508) → Übersicht → „Upgrade“. Der Agent hat diesen Schritt nicht ausgeführt. Dies ist eine Billingentscheidung, kein bloßer technischer Leseschritt; ohne diese Entscheidung gibt es hier keinen sinnvollen Modelltest.

Falls die Nutzung danach weiterverfolgt wird, in dieser Reihenfolge separat durchführen beziehungsweise prüfen:

1. Exakte [Haiku-Modellkarte](https://console.cloud.google.com/agent-platform/publishers/anthropic/model-garden/claude-haiku-5-5?project=sprachlernapp-510508) öffnen; Freischaltung/Partnerbedingungen persönlich prüfen. API-Aktivierung oder Vertragsannahme erfordern einen gesonderten Änderungsauftrag.
2. [Kontingente und Systemlimits](https://console.cloud.google.com/iam-admin/quotas?project=sprachlernapp-510508) → Filter `anthropic-claude-haiku` → drei „EU multi-region online prediction“-Zeilen. Erst nach Freischaltung erneut lesen; falls weiterhin 0, diese EU-Familienkontingente gezielt anfragen. Nicht global oder eine andere Region verwenden.
3. Den tatsächlich vorgesehenen Ausführungsrechner und dessen ADC-Principal festlegen. Für den aktuellen Mac fehlen eine auffindbare Google-Cloud-CLI und ADC; Installation/Anmeldung wurden nicht ausgeführt. Ein CLI-Login allein würde die Pipeline nicht authentifizieren. Keine Credentials an den Agenten senden. Danach die sichere ADC-Probe erneut ausführen und die Rechte genau dieses Principals prüfen.
4. [IAM-Richtlinien-Fehlerbehebung](https://console.cloud.google.com/iam-admin/troubleshooter?project=sprachlernapp-510508): mit der dann bekannten Laufzeitidentität `aiplatform.endpoints.predict` für Projekt `sprachlernapp-510508` prüfen; gegebenenfalls auch Service-Usage-/Quota-Projektberechtigung. Eine konkrete Principal-Angabe ist heute unbekannt und wird nicht durch das Browserkonto ersetzt. Effektive Partnerfeature-/Service-/Endpoint-Policies bei weiterhin unklarer Console-Anzeige durch den zuständigen Administrator/Support auslesen lassen; keine pauschale Rollenvergabe.

Erst anschließend könnte ein gesondert beauftragter, begrenzter Live-Test einen tatsächlichen Request belegen. Dieser Audit erteilt dazu keine Freigabe.

## Dokumentprüfung und Erhalt fremder Arbeit

Nur dieser Bericht und die Haiku-Zeile in `NEXTSTEPS.md` werden geändert. `published-baseline-transfer/` bleibt unangetastet. Beide Dokumente behalten CRLF; gezielter Diff-/Whitespacecheck und GitNexus-Änderungsanalyse vor dem isolierten Dokumentcommit. Keine erneute vollständige Testsuite, kein Push.

Prüfoutput: CRLF-Prüfung beider Dokumente OK, NEXTSTEPS 24 Zeilen; Exit 0. NEXTSTEPS-Diff genau 1 hinzugefügte / 1 entfernte Zeile, alle anderen Zeilen bytegleich. `git -c core.whitespace=cr-at-eol diff --cached --check -- docs/haiku-cloud-access-check.md NEXTSTEPS.md`: Exit 0. Nach gezieltem Staging meldet `node .gitnexus/run.cjs detect-changes --scope all --repo .`: Exit 0, 2 Dateien / 2 Dokumentabschnitte / 0 betroffene Prozesse, Risiko low, kein partial/truncated gemeldet. Für den neuen Bericht löst der Graph keine Symbole auf; sein vollständiger Dokumentdiff wurde zusätzlich geprüft. Staging enthält ausschließlich diese beiden Dokumente.
