# Entwicklungsumgebung (Windows und macOS)

## Werkzeuge

- Docker Desktop (lokales Supabase)
- Supabase CLI
- Google Cloud SDK (`gcloud`)
- Python 3 mit gepinntem `anthropic[vertex]==1.15.0`; `google-genai` bleibt für bestehende Werkzeuge erhalten
- Flutter (Dart `^3.13.2`)

## Anmeldung

Gleich auf Windows (PowerShell) und macOS (Terminal):

```
gcloud auth login
gcloud auth application-default login
gcloud config set project sprachlernapp-510508
supabase login
```

## Prüfen

Windows (PowerShell): `gcloud auth application-default print-access-token | Out-Null; $?`
macOS: `gcloud auth application-default print-access-token >/dev/null && echo ok`

## Geheim (nie ins Repo, nie in die App)

- Dienstkonto-Schlüssel (Supabase-Secret `GCP_SA_KEY`)
- Supabase-Zugangsdaten und Service-Role-Key
- Dateien der ADC-Anmeldung (liegen im Nutzerverzeichnis von gcloud)

Nicht geheim: Projekt-ID, Region, Modellname.

## Lokaler Pipeline-Textanschluss (Paket A, 18.10.2026)

Vorhandene Umgebung aktualisieren, ab Repository-Root (kein Modellaufruf):

Windows (PowerShell):
```powershell
pipeline/.venv/Scripts/python.exe -m pip install -e "./pipeline[test]"
pipeline/.venv/Scripts/python.exe -m pytest pipeline/tests/test_haiku_contract.py -q
pipeline/.venv/Scripts/python.exe -m pytest pipeline/tests -q
pipeline/.venv/Scripts/python.exe -m pip check
```

macOS (Terminal):
```sh
pipeline/.venv-macos/bin/python -m pip install -e './pipeline[test]'
pipeline/.venv-macos/bin/python -m pytest pipeline/tests/test_haiku_contract.py -q
pipeline/.venv-macos/bin/python -m pytest pipeline/tests -q
pipeline/.venv-macos/bin/python -m pip check
```

`pipeline/requirements.lock` enthält den lokalen editierbaren Projekteinstieg relativ zum Repository-Root sowie exakte Abhängigkeitspins; Installation mit `-r pipeline/requirements.lock` nur vom Root aus. Die aktuelle macOS-Umgebung bestand bereits vor diesem Auftrag und hat bei einigen Alttransitiven neuere Versionen als der historische Lock. Die neu hinzugefügte SDK-Kette wurde exakt installiert; keine pauschale Aktualisierung aller Alttransitiven.

`pipeline/config.yaml`: Projekt `sprachlernapp-510508`, Region `eu`, Modell `claude-haiku-5-5`, Thinking aus, Effort low. Bestehendes ADC verwenden; kein neuer Secretname, kein `ANTHROPIC_API_KEY` erforderlich. Umgebungswerte für andere Projekte/Endpunkte überschreiben das feste Routing nicht. Diese Offline-Tests lesen keine ADC-Dateien und ersetzen den Transport durch lokale Fakes.

Vor einer späteren, gesondert beauftragten Liveprüfung: Administrator prüft Haiku-5.5-Freischaltung/Bedingungen, Billing/Organisationspolicy, `aiplatform.endpoints.predict` und EU-Quote im bestehenden Projekt. Freischaltrolle: `roles/consumerprocurement.entitlementManager`; Inferenz z. B. `roles/aiplatform.user`. Keine Frankfurt-Einzelregionszusage, keine Freischaltung durch Paket A. Konkreter nächster Schritt: read-only Prüfung der Projekt-/Modellkarte und vorhandener Rechte, noch kein Testprompt. Siehe [Umsetzungsbericht](haiku-migration-implementation.md).
