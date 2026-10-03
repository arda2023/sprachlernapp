# Entwicklungsumgebung (Windows und macOS)

## Werkzeuge

- Docker Desktop (lokales Supabase)
- Supabase CLI
- Google Cloud SDK (`gcloud`)
- Python 3 mit `google-genai`
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
