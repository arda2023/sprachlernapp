# Inhaltspaket Englisch (Entwicklungsasset)

Hier liegen nach dem Stagen `content.sqlite` und `content.manifest.json`. Beide Dateien sind gitignored und werden nie von Hand bearbeitet.

Stagen (Windows PowerShell und macOS Terminal gleich, ab Repository-Root):

```
dart run tool/stage_content_pack.dart --from pipeline/out/curated_test_v1
dart run tool/stage_content_pack.dart --verify
```

Das Werkzeug prüft `finalization_report.json` (Status `ok`, alle Tabellenzahlen), das Schema und schreibt Prüfsumme, Version und Herkunft ins Manifest. Die App installiert die Datei beim Start ins App-Support-Verzeichnis und öffnet sie nur lesend; `pipeline/out/` liest sie nie.

**Internes Testmaterial:** erlaubt auf eigenen Geräten und bei ausgewählten Testpersonen, auch im Release-Build. Keine öffentliche Inhaltsfreigabe (`PRODUCT.md`, Storage). Ohne Pack zeigt die App einen Zustand „Inhalte nicht verfügbar“ statt Platzhalterdaten.
