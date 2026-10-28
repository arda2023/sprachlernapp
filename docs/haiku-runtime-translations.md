# Haiku-Laufzeitübersetzungen · 19.10.2026

**Fortschreibung 24.10.2026:** Die folgenden Cache-/Dialogaussagen dokumentieren den damaligen Stand. Paket 2A ersetzt erneute identische Modellanfragen durch private lokale/serverseitige Wiederverwendung; aktuelle Verträge, Nachweise und Deploymentbefehle: [Übersetzungsspeicher](story-translation-cache.md). Keine neue Cloud-/Geräteabnahme dadurch behauptet.

## Ergebnis und Abnahmegrenze

Lokal implementiert: vorhandene Übersetzungsaktionen → gespeicherter Inhalt oder ausdrückliche KI-Bestätigung → authentifizierte Supabase Function → direkte Anthropic Messages API mit `claude-haiku-5-5` → validierte deutsche Antwort. Keine EU-only-Zusage, kein Gemini-/Vertex-Fallback. Kein Deployment, keine Cloudänderung, keine Geräteinstallation und keine kostenpflichtige Modellanfrage in diesem Auftrag. Der vollständige reale App-Weg bleibt bis zur unten beschriebenen Abnahme offen.

Ausgangscommit `6e5e6de`. Der Nutzer berichtet einen erfolgreichen direkten Python-Smoke mit 205 Input-/8 Outputtokens. Das ist ein Nutzerbericht zum Python-Weg, kein von diesem Auftrag beobachteter App-Nachweis. Gleichlautende Zahlen in Backend-Testfixtures sind ausdrücklich synthetisch.

## Tatsächliche Wege vor und nach der Änderung

| Aktion / konkrete Datei | Bisherige Datenquelle | Jetzt |
| --- | --- | --- |
| Story-Worttipp: `lib/screens/stories/story_reader_screen.dart`, `_addAnnotated` → `_lookUp` | `StoryToken.gloss` aus `StoryDocument`, sonst Text „Übersetzung nicht verfügbar“; Lernentscheidung separat lokal | Gespeicherte Glosse unverändert; fehlende Glosse bei tappbarem Wort bietet expliziten KI-Dialog mit Wortform und vollständigem Satz |
| Story-Satztipp: dieselbe Datei, `_translate` | `StorySentence.translation` aus Pack | Vorhandene Übersetzung offline; bei leerem/Platzhalterwert expliziter KI-Dialog |
| Beispielstory/News: dieselbe Datei, `_addSentence`, `openNews`; `lib/models/sample_content.dart` | `sampleLookup`, `sampleTranslateSentence`, lokale Beispielwörter/-sätze; unbekannte Wörter „Übersetzung folgt“ | Gespeicherte Beispiele offline; fehlende Wörter/Sätze über denselben Dialog. Unicode-Wortgrenzen unterstützen portugiesische Buchstaben |
| Textübung: `lib/screens/content/text_exercise_screen.dart`, `_translate` | Lokale Satzübersetzung über `sampleTranslateSentence` | Derselbe lokale Vorrang; bei fehlender Übersetzung wird der vollständige Lösungssatz als Kontext geschickt. Anzeige verdeckt ungelöste Lücken weiterhin mit „…“ |
| Lernkarten/Übersetzungsblase/Wortdetails: `lib/screens/decks/widgets/practice_chrome.dart`, `lib/screens/decks/widgets/translation_bubble.dart`, `lib/screens/words/widgets/word_details_sheet.dart` | Gespeicherte Karten-/Wortübersetzung | Unverändert, keine Modellanfrage |
| Python: `pipeline/src/sprachpipe/llm.py`, `pipeline/config.yaml` | Expliziter direkter Anthropic-Provider, Vertex als explizite Alternative | Unverändert; keine Pipelineänderung in diesem Auftrag |
| Satzprüfung/Umschreiben/Importplanung | Dokumentierter Entwurf, kein vorhandener KI-Aufruf aus der App | Nicht implementiert/aktiviert; keine neue Antwortbewertung, Generierung oder SRS-KI |

Nichtlexikalische bzw. bislang nicht tappbare Packtokens ohne Lemma bleiben ohne Wortaktion; es entsteht kein neuer Lern-/Annotationspfad. Geprüfte Inhalte werden nicht überschrieben. KI-Antworten werden weder in Packs noch als neue Lernkarten gespeichert. Die Rückgabe ist eine Anzeigeübersetzung, keine redaktionelle Freigabe.

Im aktuellen `lib/` gab es keinen Gemini-/Vertex-Modellaufruf; die bisherigen Functions waren Health und Inhaltsverteilung/-veröffentlichung. Konkreter verbleibender Vertex-Pfad: `Llm.client`/expliziter Providerzweig in `pipeline/src/sprachpipe/llm.py`. Historische Gemini-Tarife in YAML sind keine Aufrufe. TTS und redaktionelle Werkzeuge gehören nicht zu den App-Übersetzungsaktionen und bleiben unverändert.

## Architektur und Schutzmaßnahmen

`StoryReaderScreen` / `TextExerciseScreen` → `hasStoredTranslation` → bei Fehlen `RuntimeTranslationSheet` → **Mit KI übersetzen** → `runtimeTranslationProvider` → `RuntimeTranslationClient` → vorhandenes `ContentAuthRepository.accessToken()` → HTTPS `/functions/v1/lookup-word` oder `/functions/v1/translate-sentence` → Nutzerprüfung bei Supabase Auth → `reserve_runtime_translation` → `https://api.anthropic.com/v1/messages`.

Die Function-Konfiguration behält `verify_jwt=true`. Zusätzlich wird der Nutzer bei `/auth/v1/user` geprüft; anonyme Konten sind nicht erlaubt. Die RPC prüft die bestehende `content_readers`-Freigabe für genau die angefragte Sprache und `internal`. Keine neue Rolle oder Freigabe wurde eingerichtet. Flutter verwendet ausschließlich die bestehende öffentliche Supabase-Konfiguration und Nutzeranmeldung. Der lokale Anthropic-Schlüssel wurde weder gelesen noch kopiert; der neue Serverpfad liest ausschließlich das Secret `ANTHROPIC_API_KEY` seiner Function-Umgebung.

Vertrag: `lang: en|pt-BR`, `target_lang: de`, ein Satz (`text` bzw. `sentence`) und beim Wort zusätzlich `form`. Keine Nutzer-ID, Lernstände, Profile oder ganzen Packs an Anthropic. Die App übermittelt keine historischen IDs; alte optionale `sentence_id`/`import_id` werden serverseitig ignoriert. Die bisher beschriebenen Antwortfelder `translation_de` bzw. `form`, `senses[{pos,form_label,gloss_de,lemma}]`, `cached` bleiben erhalten; `provider`, `model`, `request_id`, `usage` kommen hinzu. Quelle für geladene Stories ist `contentRepositoryProvider.info.lang`; aktuelle Beispielnews/-übungen sind Englisch, beide Screen-Schnittstellen akzeptieren explizites pt-BR.

Fester Modellname, Thinking aus, Effort low, strukturiertes JSON-Schema plus unabhängige Validierung der Antwort, Modell-ID, Stopgrund und Tokenzahlen. Kein Retry und kein Fallback. Body höchstens 4096 Byte, Satz 600 Zeichen, Wortform 80; Antwortbody höchstens 16384 Byte, Satzübersetzung 1200 Zeichen bzw. genau ein Sinn mit vier Feldern je höchstens 200 Zeichen. `max_tokens=384`. Function-Deadline 25 Sekunden einschließlich gestalltem Requestbody; Flutter-HTTP 30 Sekunden, Tokenbeschaffung gesondert 30 Sekunden.

Atomare Reservierung in bestehendem `app.usage`, beide Functions/Sprachen teilen Limits: 5/Nutzer/UTC-Minute, 20/Nutzer/UTC-Tag, 1000 insgesamt/UTC-Tag. Service-only SECURITY DEFINER mit leerem search_path und globalem Transaktions-Advisory-Lock. Fehler nach Reservierung zählen weiter; keine automatischen Wiederholungen. Dies begrenzt Anfragen und Ausgabe, garantiert aber keine feste Dollar-Rechnungsgrenze oder exakte Inputtokenobergrenze. Anbieterabrechnung und echte Parallelität mehrerer DB-Sitzungen bleiben gesondert zu prüfen.

Fehler liefern sichere feste Meldungen, keine Anbieterantworten oder erfundenen Übersetzungen. Erfolgslogs enthalten ausschließlich Anfrage-ID, Provider, Modell und Tokenzahlen. Keine Texte, Nutzer-IDs oder Geheimnisse. Die UI zeigt Modell und Anfrage-ID; vorhandene Übersetzungen erhalten keine KI-Provenienz. Kein persistenter KI-Cache: erneutes Öffnen mit erneuter Bestätigung zählt als neue Anfrage.

## Änderungsdateien

- Backend: `supabase/functions/_shared/runtime_translation.ts`, `lookup-word/index.ts`, `translate-sentence/index.ts`, `supabase/config.toml`.
- Datenbank: `supabase/migrations/20261019000001_runtime_translation_limits.sql`; keine Migration für lokale Lerndaten.
- Flutter: `lib/data/runtime_translation_client.dart`, `lib/presentation/providers/runtime_translation_provider.dart`, `lib/widgets/runtime_translation_sheet.dart`, `lib/screens/stories/story_reader_screen.dart`, `lib/screens/content/text_exercise_screen.dart`.
- Tests: `supabase/functions/_shared/runtime_translation_test.ts`, `supabase/tests/database/runtime_translation.test.sql`, `test/runtime_translation_test.dart`, gezielter News-Test in `test/widget_test.dart`.
- Regeln/Doku: `AGENTS.md`, `CLAUDE.md`, `PRODUCT.md`, `ARCHITECTURE.md`, `docs/backend.md`, dieser Bericht, `NEXTSTEPS.md`. Die enge Direkt-API-Ausnahme folgt dem ausdrücklichen Nutzerauftrag.

Fremdes `published-baseline-transfer/` bleibt unberührt/uncommitted. Keine Produktionspacks, redaktionellen Übersetzungen, Lernstände, review_log, SRS, Abhängigkeiten oder UI-Altwerte geändert. Kein Push.

## Lokale Nachweise

GitNexus-Repository `sprachlernapp`; vor Bearbeitung aktualisierter Index. Query für Übersetzungs-/Authfluss, Impact vor bestehenden Symboländerungen: Reader `_translate`, `_lookUp`, `_addAnnotated`, `_addSentence`, `_StoredStoryReader` und Textübungs-`_translate` LOW (je 1–2 direkte Aufrufer, 0–1 Prozesse); Screen-Klassen LOW (2–3 direkte Aufrufer). Dokument-/Testdateien teils UNKNOWN; das ist keine Entwarnung. Direkte Referenzen und relevante Texte wurden zusätzlich geprüft, mehrdeutige AGENTS/CLAUDE-Treffer per Datei-ID aufgelöst. Kein HIGH-/CRITICAL-Befund vor diesen Änderungen.

Befehle aus dem Repository; Flutter-/Node-/Git-Befehle gelten unter macOS und PowerShell gleich. Der absolute Deno-Pfad unten ist die bereits vorhandene macOS-Testumgebung, keine Installation dieses Auftrags. Auf Windows ist derselbe Deno-Befehl mit dem dort vorhandenen `deno` auszuführen.

| Ausgeführter Befehl | Gekürzter Output / Einordnung | Exit |
| --- | --- | --- |
| `node --experimental-transform-types --test supabase/functions/_shared/runtime_translation_test.ts` | `tests 21 / pass 21 / fail 0`; zusätzlich erste Node-Vertragsprüfung | 0 |
| `/private/tmp/sprachapp-editor-package3/test-runtime/node_modules/@deno/darwin-arm64/deno check supabase/functions/lookup-word/index.ts supabase/functions/translate-sentence/index.ts` | Beide Entrypoints typgeprüft | 0 |
| `/private/tmp/sprachapp-editor-package3/test-runtime/node_modules/@deno/darwin-arm64/deno test --allow-read supabase/functions/_shared/runtime_translation_test.ts supabase/functions/_shared/content_distribution_test.ts` | `32 passed / 0 failed` (21 neue + 11 bestehende); kein Netzwerkrecht, gemockte Modell-/Auth-/RPC-Antworten | 0 |
| `node /private/tmp/sprachapp-runtime-sql-test.mjs` | `PASS PostgreSQL/PGlite: actual migrations and all runtime translation assertions`; echte SQL-Ausführung im isolierten Speicher | 0 |
| `flutter test --no-pub test/widget_test.dart test/data/story_content_test.dart test/data/content_auth_test.dart test/runtime_translation_test.dart` | `82: All tests passed!`; damalige 8 neue Tests enthalten | 0 |
| `flutter test --no-pub test/runtime_translation_test.dart` | Nach zusätzlicher Packfixture und HTTP-Fehlerfällen: `14: All tests passed!` | 0 |
| `flutter analyze --no-pub` | Nur `test/data/baseline_adoption_pack_test.dart:43:7 • avoid_print`, im Ausgangscommit nachgewiesen | 1 |

Die SQL-Ausführung lädt die echten Migrationen `20261003000001_schemas.sql`, `20261003000003_app_tables.sql`, `20261017000002_content_distribution.sql` und die neue Migration. Nur Supabase-Systemrollen/Auth-/Storage-Minimalschema werden lokal simuliert; sämtliche Assertions der neuen SQL-Testdatei werden ausgeführt, pgTAP-Ausgaberahmen ausgelassen. Kein Supabase-Gateway-, Deployment- oder Multi-Session-Parallelitätstest. Reproduzierbarer vollständiger lokaler Supabase-Test bei vorhandenem lokalen Stack: `supabase test db supabase/tests/database/runtime_translation.test.sql` (macOS und PowerShell identisch); nicht in diesem Auftrag ausgeführt.

Zwischenbefunde wurden behoben: neue Dart-Klammer/Importfehler, Deno-Nullability sowie vier neue Dart-Stilhinweise. Die erste breitere Flutter-Runde hatte 80 bestandene/2 fehlgeschlagene Tests: Sprachwert noch ladend und alter Platzhalterdialog erwartet. Die Sprache stammt jetzt aus dem geladenen Pack; News-Test verlangt den neuen Bestätigungsdialog und prüft weiterhin die gespeicherte Satzübersetzung. Die Wiederholung bestand mit 82 Tests. Keine Prüfungen deaktiviert. Vorhandene Drag-Hit-Test-Warnung in der Story-Navigation blieb bestehen und verhinderte den erfolgreichen Lauf nicht.

Abschließende Änderungsanalyse: `node .gitnexus/run.cjs analyze --index-only --pdg` → 32.862 Knoten / 78.792 Kanten / 403 Flows, Exit 0. Nach gezieltem Staging wurde `detect_changes({scope:"all", repo:cwd, limit:5000})` über den vorhandenen lokalen GitNexus-Backend-Aufruf (`node /private/tmp/haiku-runtime-graph.mjs`) vollständig ausgelesen: 21 Dateien, 139 Symbole, vier betroffene Prozesse, Risiko medium, `partial=false`, `truncated=false`, Exit 0. Betroffene Prozesse: Reader-Aufbau, lokaler Übersetzungsvorrang, neuer Dialog und Backend-Fehlerprüfung; durch die oben genannten Tests abgedeckt.

Gezielter Abschlusscheck: `git -c core.whitespace=cr-at-eol diff --cached --check` → keine Ausgabe, Exit 0. Byteprüfung aller eigenen Dateien gegen HEAD bestätigt erhaltene CRLF-/LF-Konventionen; neue Dateien LF. `NEXTSTEPS.md` hat 24 Zeilen. Der bestehende fremde Ordner wird nicht gestaged.

## Manuelle Einrichtung und echte Abnahme · noch offen

Kleinste nächste Nutzeraktion: im [Projekt unter Edge Function Secrets](https://supabase.com/dashboard/project/yevntxclpchapacqdizm/functions/secrets) einen Eintrag **ANTHROPIC_API_KEY** anlegen, Wert persönlich eingeben und **Save**. Nicht in Chat, Repository, Flutter-Konfiguration oder Terminalargumente kopieren. `SUPABASE_URL` und `SUPABASE_SERVICE_ROLE_KEY` sind die vorhandenen serverseitigen Supabase-Variablen; kein Service-Schlüssel ins App-Bundle. [Offizielle Secret-Anleitung](https://supabase.com/docs/guides/functions/secrets).

Danach durch den Nutzer mit vorhandener Supabase-CLI/Anmeldung, aus diesem Repository; macOS und Windows PowerShell identisch:

```text
supabase link --project-ref yevntxclpchapacqdizm
supabase db push --dry-run
```

Vor Anwendung prüfen, dass ausschließlich `20261019000001_runtime_translation_limits.sql` neu angewendet würde und die alten Abhängigkeiten bereits bestehen. Falls andere Migrationen angeboten werden: nicht pauschal anwenden, zuerst diesen konkreten Abgleich klären. Wenn nur die erwartete neue Migration ansteht:

```text
supabase db push
supabase functions deploy lookup-word --project-ref yevntxclpchapacqdizm
supabase functions deploy translate-sentence --project-ref yevntxclpchapacqdizm
```

`verify_jwt=true` beibehalten, keinen `--no-verify-jwt`-Schalter verwenden. Konto und bestehende Sprachfreigabe müssen passen; ein 401/403 ist ein konkreter Auth-/Freigabeblocker und kein Anlass, die Prüfung abzuschalten. Keine weiteren Functions deployen. [Supabase-Authentifizierung](https://supabase.com/docs/guides/functions/auth).

**Neuer iPhone-Build erforderlich**, weil Flutter geändert wurde. Nur am Mac mit bestehendem Signing und bestehender Appinstallation, App nicht löschen. Die bekannte Geräte-ID ist `00008110-001651611E01401E`; mit `flutter devices` prüfen. Der öffentliche Projektkey ist hier absichtlich nicht ausgelesen: im Dashboard unter Project Settings → API Keys den bestehenden öffentlichen anon/publishable Key wählen, niemals service_role/secret. macOS Terminal:

```sh
export SUPABASE_URL='https://yevntxclpchapacqdizm.supabase.co'
printf 'Öffentlicher Supabase-Projektkey: '
read -r SUPABASE_ANON_KEY
export SUPABASE_ANON_KEY
flutter devices
flutter run -d 00008110-001651611E01401E --dart-define="SUPABASE_URL=$SUPABASE_URL" --dart-define="SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY"
```

Windows/PowerShell kann den iPhone-Build nicht erstellen; dort nur die obigen Supabase-Schritte, das Appupdate auf dem Mac. Keine neuen Abhängigkeiten erforderlich.

**Konkreter erster App-Nachweis:** Mit bestehendem für Englisch freigegebenem Konto unter Einstellungen → Inhaltsupdates anmelden. Stories → Nachrichten → **Politik in 100 Sekunden** öffnen; Übersetzungsmodus zunächst aus. Im ersten Satz **council** antippen. Der neue Dialog zeigt den Kontext „The city council voted for a new bus plan on Tuesday.“. Erst **Mit KI übersetzen** löst die kostenpflichtige Anfrage aus. Nach Erfolg müssen deutsche Wortbedeutung, `KI · claude-haiku-5-5` und Anfrage-ID sichtbar sein.

Im [Function-Bereich](https://supabase.com/dashboard/project/yevntxclpchapacqdizm/functions) `lookup-word` → Logs öffnen und genau diese Anfrage-ID mit `provider=anthropic`, `model=claude-haiku-5-5` sowie Tokenzahlen abgleichen. Der Code akzeptiert die Modellantwort nur bei genau dieser Modell-ID und nutzt ausschließlich den festen Anthropic-Host. Ergänzend Anbieter-Verbrauch im eigenen Anthropic-Konto prüfen. Erst diese reale Korrelation belegt den App-Weg; lokales Testlog allein tut es nicht.

Offline-Gegenprobe: Übersetzungsmodus einschalten und denselben Satz antippen. Die vorhandene deutsche Satzübersetzung erscheint ohne KI-Dialog und ohne neue Function-Anfrage. Für einen echten `translate-sentence`- und pt-BR-Nachweis braucht es zusätzlich einen tatsächlich fehlenden Satz bzw. eine fehlende Wortglosse in einem berechtigten portugiesischen Kontext. Die mitgelieferten News-Sätze sind bereits übersetzt; dafür keine Packübersetzung löschen oder künstlich überschreiben. Diese beiden Cloud-Abnahmen sind bis zu einem solchen Fall offen; lokal sind beide Sprachverträge getestet. Eine erfolgreiche Wortabnahme allein ersetzt sie nicht.

Modell-/Schema-Grundlagen: [Haiku-5.5-Migration](https://platform.claude.com/docs/en/models/haiku-5-5/migration-guide), [Messages API](https://platform.claude.com/docs/en/api/http/messages), [strukturierte Antworten](https://platform.claude.com/docs/en/build-with-claude/structured-outputs). Aktuelle offizielle Dokumentation wurde herangezogen; Qualität einer echten Übersetzung und App-Latenz wurden nicht gemessen.
