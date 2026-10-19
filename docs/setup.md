# Entwicklungsumgebung (Windows und macOS)

## Werkzeuge

- Docker Desktop (lokales Supabase)
- Supabase CLI
- Google Cloud SDK (`gcloud`)
- Python 3 mit gepinntem `anthropic[vertex]==1.15.0`; `google-genai` bleibt für bestehende Werkzeuge erhalten
- Flutter (Dart `^3.13.2`)

## Anmeldung

Die folgenden Google-Anmeldungen gelten für Vertex und andere Google-Dienste. Die direkte redaktionelle Anthropic-Pipeline benötigt weder gcloud noch ADC; ihre verdeckte, temporäre Schlüsseleingabe steht in [Direkt-API-Setup](haiku-direct-api-setup.md).

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
- `ANTHROPIC_API_KEY`: nur temporär im lokalen Prozess, nicht in `.env`, `.zshrc`, synchronisierten Projektdateien oder Chat speichern

Nicht geheim: Projekt-ID, Region, Modellname.

## Lokaler Pipeline-Textanschluss (19.10.2026)

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

`pipeline/config.yaml`: `provider: anthropic`, Modell `claude-haiku-5-5`, Thinking aus, Effort low. Der direkte Provider verwendet ausschließlich den lokal eingegebenen `ANTHROPIC_API_KEY`, keine ADC und keine Google-Projektkonfiguration. Keine EU-only-Zusage für diesen vom Nutzer erlaubten redaktionellen Weg, keine echten Nutzerdaten. Explizite Alternative `provider: vertex` behält Projekt `sprachlernapp-510508`, Region `eu` und ADC. Kein automatischer Fallback; Umgebungs-URLs überschreiben das feste Routing nicht. Das vorhandene SDK enthält beide Clients; keine Neuinstallation für den direkten Zugang nötig. Offline-Tests verwenden lokale HTTP-Mocks. Manueller Einzeltest und sichere Schlüsseleingabe: [Abschlussbericht](haiku-direct-api-setup.md). Ein schon laufendes Codex erbt keine Variablen aus einem anderen Terminal.

Nur für die ausdrücklich gewählte Vertex-Alternative gilt weiterhin: Administrator prüft Haiku-5.5-Freischaltung/Bedingungen, Billing/Organisationspolicy, `aiplatform.endpoints.predict` und EU-Quote im bestehenden Projekt. Freischaltrolle: `roles/consumerprocurement.entitlementManager`; Inferenz z. B. `roles/aiplatform.user`. Keine Frankfurt-Einzelregionszusage, keine Freischaltung durch Paket A. Konkreter nächster Schritt: read-only Prüfung der Projekt-/Modellkarte und vorhandener Rechte, noch kein Testprompt. Siehe [Umsetzungsbericht](haiku-migration-implementation.md).
