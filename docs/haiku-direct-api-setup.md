# Haiku 5.5: direkte API für die lokale Redaktion

Stand: 19.10.2026. Ausgangscommit `6f462a1`, Branch `codex/haiku-vertex-eu`.

## Ergebnis und Freigabegrenze

Direkter Anthropic-Zugang im vorhandenen Pythonwrapper ergänzt; explizite Standardwahl `llm.provider: anthropic`. Vertex bleibt mit `provider: vertex` verfügbar. Kein automatischer Wechsel auf einen anderen Anbieter, ein anderes Modell oder eine andere Region. Das bereits installierte offizielle SDK `anthropic[vertex]==1.15.0` enthält beide Clients; keine Installation oder Abhängigkeitsänderung.

Nutzerentscheidung vom 19.10.2026: Google habe die beantragten EU-Kontingente abgelehnt; der Nutzer habe einen eigenen Anthropic-Schlüssel erstellt. Dies sind Nutzerangaben, kein erneuter Cloud-/Schlüsselaudit. Direkte API ist ausschließlich für die **lokale redaktionelle Pipeline ohne echte Nutzerdaten** erlaubt. Dafür wird **keine ausschließliche EU-Verarbeitung zugesichert**. App, künftige Runtime-KI über Supabase/Vertex, TTS und andere Dienste behalten ihre Regeln. Die Stapelphase bleibt beendet; kein neuer Produktionsauftrag.

**Keine Live-Anfrage ausgeführt**, auch keine Tokenzählanfrage. API-Key, Kontoguthaben, Freischaltung, Anbieterlimits, Livequalität und tatsächliche Einsparung bleiben ungeprüft. Der vorbereitete Einzeltest muss vom Nutzer ausdrücklich in seinem Terminal gestartet werden. Die frühere Vertex-Zugangshistorie in `haiku-cloud-access-check.md` und `haiku-live-setup.md` bleibt als datierter Befund erhalten.

## Vorab festgelegter Änderungsumfang

Arbeitsbaum anfangs nur `?? published-baseline-transfer/`; fremdes Verzeichnis unberührt. Vor Edit geprüft: vorgegebene acht Dokumente, vorhandenes SDK, Konfiguration, Wrapper, Ledger, Preisaufrufer und Tests. Kein Secret- oder Nutzerdateiinhalt gelesen.

Vorabplan: (1) Auswahl im bestehenden Wrapper und getrennte Tarife, (2) ausdrücklich startbarer synthetischer Test samt Offline-Verträgen, (3) eng begrenzte Regelausnahme und Einrichtung dokumentieren, Python-Suite/Diff/Graph prüfen, isoliert committen. Die sieben fachlichen Caller und ihre Prompts/Schemas bleiben unverändert.

| Eigene Datei | Zweck |
| --- | --- |
| `pipeline/src/sprachpipe/llm.py` | Explizite Providerwahl, fester direkter SDK-Transport, sichere Fehler, providerbezogener Tarif; ursprüngliche Schnittstelle/Schema-/Budgetprüfung erhalten |
| `pipeline/src/sprachpipe/cost.py` | Route im bestehenden Sidecar korrekt als `eu` oder `not-eu-bound`; historische Spalten unverändert |
| `pipeline/config.yaml` | Standard `anthropic`, Vertexwerte ausdrücklich nur für Vertex; direkte Listenpreise und EU-Alternative |
| `pipeline/src/sprachpipe/selection.py`, `pipeline/scripts/complete_curation.py` | Nur Provider an vorhandene Preisberechnung weitergeben; keine Fach-/Inhaltsänderung |
| `pipeline/src/sprachpipe/haiku_smoke.py` (neu) | Separat gestartete synthetische Probe, keine Inhalts-/Konfigurations-/Credential-Dateien laden |
| `pipeline/tests/test_anthropic_direct.py` (neu) | Echter SDK mit In-Memory-HTTP, ausschließlich künstliche Schlüssel/Antworten |
| `pipeline/tests/test_haiku_contract.py`, `pipeline/tests/test_generate.py` | Bisherige Vertex-Fixtures ausdrücklich auf Vertex setzen, alle bestehenden Vertragsassertionen erhalten |
| `pipeline/tests/test_selection.py` | Nach erstem Prüflauf zusätzlich angekündigt: bisherige EU-Tarifassertionen erhalten und direkten Tarif ergänzen |
| `AGENTS.md`, `CLAUDE.md`, `ARCHITECTURE.md`, `docs/pipeline.md`, `docs/setup.md` | Nur lokale redaktionelle Ausnahme, authentifizierungsabhängige Einrichtung und aktuelle Tarif-/Routingbeschreibung |
| `docs/haiku-direct-api-setup.md`, `NEXTSTEPS.md` | Nachweise, Grenzen und nächste Nutzeraktion; fremde Statusinformationen erhalten |

## Vertrag und Sicherheit

`Llm.generate_json(prompt, schema, *, model, thinking, step, max_output_tokens)` bleibt synchron und kompatibel. Direkter Client: `AsyncAnthropic(api_key=<nur Umgebung>, base_url="https://api.anthropic.com", max_retries=0, open_telemetry=False)`. Nur `ANTHROPIC_API_KEY` wird explizit übergeben; SDK-Profile, alternative Auth-Tokens und Base-URL-Umgebungswerte ersetzen diesen Weg nicht. Kein ADC-Aufruf und keine Google-Projekt-/Regionskonfiguration für direkte Requests nötig. HTTP-Proxies aus Umgebungsvariablen sind für den direkten Client deaktiviert (`trust_env=False`); Redirects werden nicht verfolgt. Ein Hook erlaubt ausschließlich POST an die exakte feste Route. Der Zählclient erlaubt ausschließlich `/v1/messages/count_tokens`, der Generierungsclient ausschließlich `/v1/messages`.

Modell `claude-haiku-5-5` im direkten Messages-Body; SDK setzt `anthropic-version: 2023-06-01` und API-Key-Header. Vertex setzt weiterhin den bisher geprüften EU-Pfad und seine Bodyversion. Antwortmodell muss mit dem angeforderten Modell übereinstimmen. Fehlende Schlüssel führen zu einer festen verständlichen Fehlermeldung; keine Schlüsselwerte oder Server-Rawtexte in Fehlerausgaben. SDK-Requestdebug und Inhaltstelemetrie sind aus. Tests prüfen DEBUG-Logs, sichtbare Tracebacks und Ledger auf künstliche Geheimnisse.

Thinking aus, Effort low, `output_config.format.type=json_schema`; keine Samplingparameter. Die bestehende Schemakopie und vollständige lokale Originalschema-Prüfung bleiben unverändert. Ungültiges JSON, Schemafehler, Refusal und abgeschnittene Ausgabe werden nicht repariert oder wiederholt. Die ursprünglichen fachlichen Prompts/Validatoren wurden nicht geändert.

Reguläre Pipeline: unveränderte Outputlimits, maximal 4096; höchstens drei äußere Versuche ausschließlich bei 429/500/502/503/504, SDK-Retries null. Maximal 30 Sekunden pro Versuch, 95 Sekunden insgesamt einschließlich Warten/Backoff. Auth-/Netzwerk-/Timeoutfehler führen zu kontrolliertem Abbruch. Konservative Budgetreservierung und Behandlung unbekannter Usage bleiben erhalten; unbekannt ist nicht kostenlos. Bekannte Input-/Outputtokens und Modell stehen im sieben Spalten umfassenden Ledger, Route und Versuch im Sidecar. Ein neuer Provider benötigt einen neuen Lauf/sein eigenes Ledger; historische Läufe nicht mischen.

Direkter Kurzkontexttarif: 0,10/0,50 USD pro Million Input-/Outputtokens (19.10.2026). Explizites EU-Vertex: 0,11/0,55 (vorhandener Snapshot 18.10.2026). Alte Gemini-Tarife bleiben erhalten. Preisberechnung in Wrapper und Planungswegen wählt denselben Provider; Thinking wird nicht doppelt berechnet. Listenpreiskalkulation und lokale Reservierung sind kein Beleg einer Anbieterrechnung oder garantierter Kostenbegrenzung.

Offizielle Quellen, abgerufen 19.10.2026: [Modell-ID und Preise](https://platform.claude.com/docs/en/models/haiku-5-5/overview), [Haiku-Migration](https://platform.claude.com/docs/en/models/haiku-5-5/migration-guide), [Effort einschließlich deaktiviertem Thinking bei low](https://platform.claude.com/docs/en/build-with-claude/effort), [strukturierte Ausgabe und lokale Validierung](https://platform.claude.com/docs/en/build-with-claude/structured-outputs), [Tokenzählung](https://platform.claude.com/docs/en/build-with-claude/token-counting). Zusätzlich installierte SDK-Signaturen/Authentifizierungspriorität gelesen; keine Modell- oder Kontoabfrage dafür.

## Vorbereiteter Einzeltest und Token-Grenze

Start nur mit `python -m sprachpipe.haiku_smoke --live`. Ohne `--live` beendet argparse mit Exit 2, ohne Netzverkehr. Fester synthetischer Prompt `Return {"ok":true}.`, minimales Boolean-Schema, keine variablen Inhalte, keine Tools. Der Einstieg lädt weder YAML noch `.env`, Packs, Stories, Editor- oder Nutzerdateien. Er schreibt ausschließlich sichere Nutzungsdaten in ein automatisch entferntes temporäres Ledger; Ausgabe enthält Modell, Status, gezählte und tatsächlich gemeldete Tokens beziehungsweise einen sicheren Fehler.

Ablauf: **eine nichtgenerierende Tokenzählanfrage**, einschließlich identischem Schema/Thinking/Effort; nur bei gültigem Zählergebnis bis **400** folgt **höchstens eine Generierungsanfrage**, `max_tokens=128`. Keine Retries auf beiden Wegen, kein Fallback. Je Phase höchstens 30 s, somit höchstens ca. 60 s Netzdeadline. Temporäres lokales Budget 0,01 USD; kein Produktionslauf.

**Offene technische Grenze:** Anthropic bezeichnet Count Tokens als Schätzung, nicht als serverseitigen Inputdeckel. Die 100 Tokens Abstand zur verlangten 500er-Grenze und der winzige feste Request minimieren das Risiko, garantieren jedoch keine harte Obergrenze sämtlicher anbieterseitiger Overheadtokens. Tatsächlich gemeldete Inputtokens über 500 oder Outputtokens über 128 ergeben ausdrücklich Fehler und keine weitere Anfrage. Dieser Auftrag belegt daher einen begrenzten vorbereiteten Test, aber keinen harten serverseitigen `max_input_tokens=500`-Schutz. Ist ein mathematisch garantierter Inputdeckel zwingend, den Test noch nicht starten; ein entsprechender Anbietermechanismus ist nicht belegt.

## Exakte nächste Nutzeraktion: macOS / zsh

Im eigenen Terminal ausführen. Der Schlüssel wird verdeckt über `read` eingegeben, nicht als Befehl; er gelangt nicht in die Shell-History. Der gesamte Test läuft in derselben Subshell, deren Umgebung danach endet. Keine `.zshrc`-/`.env`-Datei anlegen und den Schlüssel nicht in Chat oder Codex einfügen.

```zsh
cd /Users/ardasayar/Documents/FlutterProjekte/sprachapp
(
  unsetopt XTRACE VERBOSE
  read -rs 'ANTHROPIC_API_KEY?Anthropic API-Key (verdeckt): ' || exit 1
  print
  export ANTHROPIC_API_KEY
  pipeline/.venv-macos/bin/python -m sprachpipe.haiku_smoke --live
)
```

Ein bereits laufendes Codex übernimmt diese Variable nicht aus dem anderen Terminal. Deshalb den Test direkt dort ausführen, nicht anschließend den Agenten um Nutzung des dort eingegebenen Schlüssels bitten. Der Agent hat diese Befehle mit Schlüssel/`--live` nicht ausgeführt. Ein erfolgreicher Einzeltest wäre nur ein Zugangs-/Vertragsnachweis, keine redaktionelle Qualitätsfreigabe.

Windows PowerShell, alternativ vom Repository-Root mit vorhandener Windows-Umgebung (hier nicht ausgeführt):

```powershell
Set-PSDebug -Off
$haikuSecret = Read-Host 'Anthropic API-Key' -AsSecureString
try {
  $env:ANTHROPIC_API_KEY = [System.Net.NetworkCredential]::new('', $haikuSecret).Password
  pipeline/.venv/Scripts/python.exe -m sprachpipe.haiku_smoke --live
} finally {
  Remove-Item Env:ANTHROPIC_API_KEY -ErrorAction SilentlyContinue
  $haikuSecret.Dispose()
  Remove-Variable haikuSecret
}
```

Bei einem Fehler nur die sichere JSON-Ergebniszeile weitergeben, niemals Schlüssel, Header oder Credential-Dateien. Keine wiederholten Live-Versuche durch diesen Auftrag freigegeben.

## Prüfprotokoll (macOS, tatsächlich ausgeführt)

- `git status --short`: anfangs ausschließlich fremdes `published-baseline-transfer/`, Exit 0.
- `node .gitnexus/run.cjs analyze --index-only`: Exit 1 wegen fehlendem Registry-Schreibrecht; außerdem hätte der Aufruf ohne `--pdg` die bestehende PDG-Schicht entfernt. Korrigierter vollständiger Neuaufbau mit vorhandener PDG-Schicht und erforderlichem lokalen Recht: `node .gitnexus/run.cjs analyze --index-only --pdg --force`, Exit 0, `32,166 nodes | 77,385 edges | 288 clusters | 408 flows`, 15,8 s. Keine Instruktionsdateien durch den Indexer geändert.
- GitNexus-Kontext/Impact vor Edits, explizit Repository `sprachlernapp`, Checkout `/Users/ardasayar/Documents/FlutterProjekte/sprachapp`, Index nach Neuaufbau auf `6f462a1`: Wrapperdatei LOW mit CLI/Selection als direkten Importeuren; Preisfunktion LOW mit Selection-/CLI-Prozessen; Kosten-/Planungsfunktionen LOW. Keine HIGH/CRITICAL-Warnung. Einzelne Methoden, Tests und Dokumente UNKNOWN; `generate_json` hat eine Receiver-Abdeckungslücke. Sieben fachliche Aufrufstellen, `self.client`, Konfigurations- und Dokumentreferenzen deshalb zusätzlich textlich geprüft. Keine Nulltreffer als Entwarnung gewertet.
- Erster gezielter pytest-Lauf: `1 failed, 182 passed in 5.20s`, Exit 1. Einzige Ursache: historischer EU-Tarif im Dry-Run-Test bei nun direkter Standardwahl. Beide Tarife anschließend parametrisiert geprüft; keine Fachassertion entfernt. Zweiter Lauf: `184 passed in 4.35s`, Exit 0. Danach zusätzliche Antwortmodell-/Smoke-Verbrauchsgrenzen geprüft.
- Ein Dokumentersetzungsbefehl brach mit Exit 1 ab, weil die erwartete alte Formulierung `HTTP-Body` tatsächlich `HTTP-Transport` hieß. Exakte Quellzeile gelesen, gezielte Fortsetzung Exit 0; keine pauschale Datei-Neuschreibung.
- `pipeline/.venv-macos/bin/python -m pip check`: `No broken requirements found.`, Exit 0; lediglich nicht beschreibbarer pip-Cache als Warnung, keine Installation.

Die vollständige Suite wurde mit den für vorhandene lokale HTTP-/Dart-Tests notwendigen Rechten ausgeführt:

```text
pipeline/.venv-macos/bin/python -m pytest pipeline/tests -q
668 passed, 1 skipped, 19 subtests passed in 168.13s (0:02:48)
Exit 0
```

Der bestehende Skip betrifft die nur ausdrücklich aktivierbare lokale Supabase-Authintegration; kein Haiku-Test übersprungen. Keine zusätzliche Flutter-Vollsuite und kein Live-Modellaufruf. Die gezielten Prüfbefehle (gleicher Dateisatz in beiden oben genannten Läufen):

```text
pipeline/.venv-macos/bin/python -m pytest pipeline/tests/test_anthropic_direct.py pipeline/tests/test_haiku_contract.py pipeline/tests/test_generate.py pipeline/tests/test_parallel.py pipeline/tests/test_selection.py pipeline/tests/test_meaning_check.py pipeline/tests/test_alternative_check.py pipeline/tests/test_cost_schema.py -q --tb=short
```

Die vollständige Suite enthält auch die beiden danach ergänzten Tests für das Antwortmodell und einen nachträglich gemeldeten Inputgrenzverstoß. Abschließende Nachweise:

- `node .gitnexus/run.cjs analyze --index-only --pdg`: Exit 0, 12,8 s, `32,400 nodes | 77,962 edges | 294 clusters | 408 flows`. Allgemeine Flowabdeckung bleibt begrenzt; direkte Referenz- und vollständige Diffprüfung ergänzen sie.
- `git add --` ausschließlich der 17 oben genannten Dateien: Exit 0. Fremdes Verzeichnis nicht vorgemerkt.
- `node .gitnexus/run.cjs detect-changes --scope all --limit 500 --repo .`: Exit 0, `17 files, 72 symbols`, `Affected processes: 1`, `Risk level: medium`. MCP bestätigt 72 vollständig gelistete Symbole, keine `partial:true`-/`truncated:true`-Markierung. Betroffener Prozess `Main → Card_info`, Schritt `check_preconditions`: direkte Quell-/Diffprüfung bestätigt dort ausschließlich Weitergabe von `provider` an die bestehende Preisprüfung. Vollständige Python-Suite bestanden.
- Gezielter `git -c core.whitespace=cr-at-eol diff --cached --check --` über genau diese 17 Dateien: kein Output, Exit 0.
- Python-Byteprüfung gegen HEAD: vorhandene LF-/CRLF-Konventionen erhalten; NEXTSTEPS 24 Zeilen, exakt vier gezielte Zeilenänderungen, alle anderen Statuszeilen bytegleich; Exit 0. Neuer Bericht CRLF, neue Pythonmodule LF. Eigene Dateien zusätzlich auf versehentliche API-Key-Präfixe geprüft, keine Treffer.
- `git diff HEAD --name-only -- assets lib supabase pipeline/data pipeline/src/sprachpipe/editor pipeline/pyproject.toml pipeline/requirements.lock`: leer, Exit 0. Die sieben fachlichen Wrapper-Aufrufstellen sind unverändert. Keine Cloudänderungen, Installation, Veröffentlichung, Geräteaktion oder Push.

Eigene Änderungen sind sauber abtrennbar und werden nach finalem Staged-Diffcheck isoliert committet. Offene Einrichtung bleibt die persönliche Schlüsseleingabe und der oben beschriebene Einzeltest; die Einschränkung des geschätzten Inputzählers ist ausdrücklich kein erfüllter harter Inputdeckel.
