# Portugiesisch · Paket 2 · 18.10.2026

**Zwischenstand, nicht abgenommen.** Ausgang `67386c7`, Arbeitsbranch
`codex/portuguese-package-2`. Persistenz, Sprachfassaden, Updates und
Antwortprüfung sind implementiert und unten lokal geprüft. Der neue vollständige
UI-Test ist noch rot. Nach fünf UI-Versuchen wurde gestoppt. Der Nutzer erlaubte
danach genau einen gezielten Korrekturlauf; dieser ist ausgeführt und wegen des
verbleibenden Rückwechsel-Timeouts beendet. Keine weitere Korrekturschleife. Kein iPhone-,
Simulator-, Cloud- oder Veröffentlichungs-PASS. Kein Push.

## Umsetzung und Datenvertrag

- Einstellungen zeigt Englisch und Portugiesisch (Brasilien), Installationsstatus,
  Wechselmeldung und pt-BR-Akzentpflicht. Oberfläche Deutsch. `settings.target_lang`
  bleibt der persistente Schlüssel; ohne bisherigen Eintrag weiter `en`.
- `LanguageSelectionController.selectLanguage` nutzt das bestehende
  `ContentTransitionGate`. Übung, Inhaltsansicht und Update haben unterscheidbare
  Sperrtexte. Abweisung speichert nichts und plant keinen späteren Wechsel.
  Zielinstallation wird vor Speicherung geöffnet/geprüft; nur ausdrücklich fehlende
  Installation darf leer ausgewählt werden. Readerbarriere und Fehler-Rollback
  erhalten die bisherige Sprache. Gemeinsame UserDatabase und Schema 6 bleiben.
- Userfassaden halten ihre Sprache fest und prüfen beim Inhalts-ID-Zugriff die
  Sprache des Readers. Kartenflags, Präferenzen und asynchrone Stapelauswahl
  halten Schreib-Leases. Stapeloptimismus wird bei Sprachwechsel verworfen.
- Updatecontroller baut Service/Callbacks bei Änderung der ausgewählten Sprache
  neu auf; Epochenschutz verwirft verspätete Zustandsmeldungen. HTTP-Clients und
  automatische Prüffristen sind je Sprache getrennt, Auth bleibt gemeinsam.
  Updateaktionen halten während asynchroner Arbeit einen Gate-Lease; Aktivierung
  übergibt ohne eigenen blockierenden Lease an den bestehenden Übergang.
  Download/Aktivierung ändern die Sprachauswahl nicht.
- Bei uninstalliertem pt-BR zeigt die App den fehlenden Bestand und Zugang zu
  Einstellungen/Inhaltsupdates. Kein englischer Stapel-/Story-/News-/Übungsersatz.
  Bei installiertem pt-BR kommen Lernansichten aus derselben Fassade; ohne Stories
  erscheint ein Leertext. Alte AsyncData werden beim Neuladen ausgeblendet.
- `ReviewPass` friert das Profil aus der Kartensprache ein. pt-BR erhält Akzente
  auch bei `includeDiacritics=false`; NFC/NFD und Groß-/Kleinschreibung bleiben
  gleichwertig. Ziel/Alternative/andere Form/fast richtig/falsch und bestehender
  SRS-Schreibweg bleiben erhalten. Keine englischen Formheuristiken bei pt-BR.
  Englische Einstellung wird nicht umgeschrieben.
- Fix `437c9c4` bleibt erhalten: aktuelle Wortdetails nutzen aktive Revisionen,
  historische Reviews bleiben an ihren alten Satz gebunden.

## Unveränderte 20-Ziele-Lieferung

Original: `portuguese_allgemeine_sprache_20_redaktion_v1.zip`, **20.209 Bytes**,
SHA256 `3f95b05bde3d4f18296154856ac0485f6f4a7d9f510254290375d66fb8ba303c`.
Bytegleiche Sicherung unter `build/portuguese_package_2/`, nicht committed.
Fünf Einträge, kein `editor.xlsx`; keine leere Arbeitsmappe ergänzt.

`tool/verify_portuguese_delivery.py` orchestriert ausschließlich vorhandene
`read_delivery`, Profil-, Schema- und Editorprüfer. Repositoryschema und
mitgeliefertes Schema stimmen überein; Hashliste vollständig. Genau 20
`create_target` und eine `create_deck`, alle erwarteten Zielrefs, pt-BR/de,
Profilmanifest/-hash und Kontextdigest geprüft. Seedfingerprint
`5fe98c7c183552e5e6ae708bbb765f75dcef21be41f71d094fac806c25d8f554`
entspricht der leeren Paket-1-Basis; keine englische Basis oder Wortreservierung.
Alle deterministischen Tokengrenzen und Lücken stimmen. Materialisierung prüft
Referenzen/Bedeutungsbindungen. Keine stillen Textkorrekturen.

Originaler Ablauf: `EditorService.preview_upload` → vollständige Vorschau →
`accept_import` **ohne draft_id** → `validate`, ausschließlich neuer temporärer
Store aus dem gebundenen Seed. Letzter Store:
`/var/folders/7b/zjlccwq95qv6mfz9kf_76fn40000gn/T/ptbr-import-mz8l7w2p`.
Originale Editorentwürfe/Heads/Bundles blieben unangetastet.

Ergebnis: `technical: valid`, `editorial: open`, `token_gap_errors: []`, Exit 0.
Die 20 Warnungen `manual-pt-BR-editorial-v1` verlangen weiterhin echte Prüfung
von BR-Gebrauch, Grammatik, Niveau, Übersetzungen und Bindungen. Das ist keine
Transport-/Inhaltsfehlermeldung. Keine echte Bestätigung und kein Release erzeugt.
Receipt/Validation: `build/portuguese_package_2/delivery-result.json`.

## Tatsächliche lokale Prüfungen

Logs unter `build/portuguese_package_2/` bleiben lokal. Flutter auf macOS,
headless Widget-/Darttests mit temporären Datenbanken. Synthetische BR-Fixture
trägt ausdrücklich „SYNTHETISCH – NICHT VERÖFFENTLICHEN“; keine Inhaltsfreigabe.

| Prüfung | Tatsächlicher Output | Exit |
|---|---|---|
| Neue Sprachwahltests | `+5: All tests passed!` | 0 |
| Alle neuen Daten-/Installations-/Update-Lebenszyklustests gemeinsam | `00:01 +14: All tests passed!` | 0 |
| Vorhandene Update-/Barrier-/Reader-/Sprach-/Antwort-/Historientests | `+92 ~4: All tests passed!` | 0 |
| Vorhandene Widget-/Update-UI-Tests | `+73: All tests passed!` | 0 |
| `flutter test --no-pub test/data/real_pack_test.dart` | `00:13 +1: All tests passed!` | 0 |
| `dart run tool/stage_content_pack.dart --verify` | en-Asset verifiziert, 22 Tabellen; SHA b85793932825a22e92ac744a42255e9f333acd35809aaba46edb5a395f099bdb | 0 |
| `pytest pipeline/tests/test_language_profiles.py -q` | `8 passed in 1.86s` | 0 |
| `flutter analyze --no-pub` | nur bekanntes `avoid_print`, baseline_adoption_pack_test.dart:43:7 | 1 |
| Vorbestehender JS-Verifikations-UI-Test | `ReferenceError: adoptPublishedBase is not defined`, unveränderte JS-Quellen; gleicher HEAD-Befund bereits Paket 1 | 1 |
| Neuer Sprachwahl-UI-Test, ursprünglicher fünfter Lauf | Header-RenderFlex-Overflow und Flaggen-/Textassertion | 1 |
| Einmalig erlaubter Korrekturlauf: betroffene UI-Tests | `+74 -1: Some tests failed.`; Headerprobe/Flagge bestehen, Rückwechsel-Timeout | 1 |
| `flutter test --no-pub`, einmaliger angeforderter Abschlusslauf | `01:04 +378 ~5 -2: Some tests failed.`; Rückwechsel-Timeout und Motiv-Dropdown-Finder | 1 |
| Analyse nach dem Korrekturlauf | ausschließlich bekanntes `avoid_print`, `1 issue found`, 4,1 s | 1 |

Persönliche Regression: bestehende englische Karten, Reviewzeilen mit Fälligkeit,
Favorit/Notiz/Playlist, Stapelauswahl, Sprachpräferenzen, lokale Storykontexte,
Quellen, Identitätsbindungen und Bericht werden vor/nach Rückwechsel vollständig
zeilenweise verglichen. Bestehende lokale Fixturezeilen werden über das direkte
Testrepository gesät, nicht als neuer freigegebener Inhalt ausgegeben. Getrennte
lokale Identitäten bei gleicher Oberfläche „ação“ und gleichem semantischem Anker
in en/pt-BR geprüft. Neustart sowie fehlendes und installiertes pt-BR geprüft.

Weitere Nachweise: unterbrochener Stream, falscher Hash, erneuter Download,
Aktivierungs-Rollback, beschädigte Installation, Readerfehler nach Speicherung
mit Rücknahme der Sprachwahl, echte Session-Lease, Detail-/Reader-Lease,
Update-Lease, verspätete Antwort nach erzwungenem Provider-Neuaufbau und
sprachgetrennte Prüffristen. Die vier übersprungenen Alt-Realbundle-Phasen
benötigen opt-in Umgebungsvariablen; synthetische Historienregression läuft.
Bekannte Drift-Debugwarnungen bei getrennten ContentDatabase-Testinstanzen;
keine durch diese Warnung ausgelösten fehlgeschlagenen Assertions.

### Einmalig erlaubte UI-Korrektur und verbleibender Fehler

Die ersten fünf Versuche korrigierten Testsynchronisation (echte SQLite-/
Isolatearbeit gegen Fake-Widget-Timer), eine außerhalb des sichtbaren
Listenausschnitts liegende Erwartung und den isolierten Scope-Neustart. Der
fünfte Lauf belegte den echten Headerüberlauf; anschließend wurde gestoppt.
Der Nutzer erlaubte ausdrücklich genau einen weiteren Korrekturlauf.

Konkrete Ursache: `HomeHeader` setzte einen Chip mit natürlicher unbeschränkter
Breite neben einen Spacer und zwei 44-pt-Buttons. Die minimale Änderung ersetzt
Chip/Spacer durch `Expanded` + linksbündiges `Align`; der komplette Text kann
innerhalb der verbleibenden Breite umbrechen. Beide Buttons bleiben im Quellcode
unverändert mit `minimumSize: Size(44,44)`. Kein Abschneiden des Namens.

Die ursprüngliche neue Testassertion erwartete den Sprachname allein. Das war
fachlich falsch: Schon Ausgang `67386c7` rendert `'$flag  $name'`. Die korrigierte
Prüfung verlangt jetzt sowohl exakt „🇧🇷  Portugiesisch (Brasilien)“ als auch den
vollständigen Semantiknamen „Zielsprache: Portugiesisch (Brasilien)“. Keine
Assertion wurde entfernt oder abgeschwächt; die fehlgeschlagene Erwartung wurde
an den belegten bestehenden Anzeigevertrag angepasst.

Zusätzliche Headerregression bei **320 pt und 2× Text** besteht: vollständiger
Name/Semantik, Textgrenzen innerhalb des Gutters, zwei Buttons mit exakt
**44×44 pt**, keine Flutter-Layoutausnahme. Der doppelte Inset des neuen
uninstallierten Zustands wurde im selben Korrektursatz entfernt; der innere
ContentUnavailableView behält seinen einmaligen 20-pt-Gutter.

Der erlaubte Lauf erreicht danach installierten pt-BR-Teststapel und
Storyleerzustand ohne Header-/Flaggenfehler. **Verbleibender konkreter Fehler:**
Nach `selectLanguage('en')` läuft `settleIo`/`pumpAndSettle` in
`test/language_selection_ui_test.dart:224` ins Timeout; Stack zeigt Helferzeile 98.
Die abschließende englische Überschrift und Rückkehransicht werden nicht mehr
geprüft. Ob weitere Fake-Timer-Synchronisation oder ein tatsächliches Problem
bei gleichzeitig aktiven Widget-Abonnenten vorliegt, ist nicht belegt. Die
isolierten Provider-/Neustart-/Rückwechseltests bestehen. Kein Rückwechsel-PASS
für diesen UI-Ablauf. Entsprechend der Anweisung nach diesem Fehlversuch keine
weitere Korrektur und kein erneuter gezielter Versuch.

Die ausdrücklich verlangte vollständige Suite wurde einmal unverändert als
Abschlussbefund ausgeführt: **378 bestanden, fünf übersprungen, zwei fehlgeschlagen,
Exit 1**. Sie bestätigt den Rückwechsel-Timeout und meldet zusätzlich
`test/practice_ui_test.dart:353`: der Finder für `DropdownButton<AppMotif>` findet
kein Widget in „Feedback and settings remain usable at 320 pixels and double
text size“. Der bestehende Test tippt direkt nach Öffnen der Einstellungen ohne
Scrollen auf den Motivwähler; vor diesem stehen jetzt die Sprachzeilen. Die genaue
Korrektur bleibt offen und wurde nach dem Stopp nicht versucht. Kein Gesamt-PASS.

Restarbeit für einen gesonderten Folgeauftrag: Rückwechsel-Timeout mit aktiven
Widget-Abonnenten lokalisieren und die sichtbare Erreichbarkeit des Motivwählers
bei großer Schrift korrekt prüfen; danach vollständigen UI-Rückwechsel sowie
Gesamtsuite abnehmen. Keine Erhöhung des Packtestbudgets und keine Lockerung von Assertions.

Die PNGs unter `build/portuguese_package_2/ui/` zeigen wegen nicht geladenen
Fonts/Icons Testglyphblöcke. Sie zählen nicht als visuelle Abnahme. Separater
impeccable-Finishreview, anschließender eng begrenzter Verdict-Pass: Header und
Inset auf Quell-/Testbelegebene **resolved**; disposition weiter **recapture**,
keine visuelle Gesamtfreigabe. Dokumentationsreview: keine neue Farb-/Typo-/
Tokenentscheidung, DESIGN.md unverändert. Vorbestehender dark-only/Motiv-
Widerspruch in PRODUCT.md bleibt unangetastet. Kein Simulator-/iPhone-Nachweis.

### Reproduzierbare Befehle

Repository-Root, Windows (PowerShell) **und** macOS (Terminal), identisch:

```text
flutter test --no-pub test/language_selection_test.dart test/data/portuguese_installation_test.dart test/language_update_lifecycle_test.dart
flutter test --no-pub test/data/content_update_test.dart test/data/content_update_diagnosis_test.dart test/data/content_owner_barrier_test.dart test/data/content_context_revisions_test.dart test/data/content_active_context_test.dart test/data/content_repository_test.dart test/data/story_content_test.dart test/story_single_sentence_test.dart test/learning_integration_test.dart test/domain/answer_check_test.dart test/domain/review_pass_test.dart test/data/user_language_migration_test.dart test/data/portuguese_profile_test.dart
flutter test --no-pub test/widget_test.dart test/content_update_diagnosis_ui_test.dart test/content_updates_ui_test.dart
flutter test --no-pub test/data/real_pack_test.dart
flutter analyze --no-pub
dart run tool/stage_content_pack.dart --verify
node pipeline/tests/editor_verification_ui_test.cjs
```

Für den gesonderten Folgeauftrag; hier keine weitere Korrekturschleife:

```text
flutter test --no-pub test/language_selection_ui_test.dart
flutter test --no-pub
```

Lieferprüfung macOS (Terminal):

```sh
pipeline/.venv-macos/bin/python tool/verify_portuguese_delivery.py /Users/ardasayar/Downloads/portuguese_allgemeine_sprache_20_redaktion_v1.zip
pipeline/.venv-macos/bin/python -m pytest pipeline/tests/test_language_profiles.py -q
```

Windows (PowerShell): gleiche Argumente mit
`pipeline\.venv\Scripts\python.exe` und dem dortigen Original-ZIP-Pfad.
Keine vollständige Python-Suite erforderlich: Produktimporter/Profilcode wurde
hier nicht verändert; der neue Helfer ruft deren vorhandene Prüfwege auf.
Das originale 30-s-Budget des Realpacktests ist unverändert.

## Nachfolgende Betriebsaktionen — nur vorbereitet, nicht ausgeführt

Erst den offenen UI-Rückwechsel und lesbare Darstellung abnehmen, dann getrennte Geräte-/Cloudabnahme.
Projekt **yevntxclpchapacqdizm**. Keine Cloudverbindung in diesem Auftrag.

**Deployment:** Dieses Inkrement ändert keine Edge-Function. Der noch nicht
clouddeployed Ausgangscommit `67386c7` ändert
`_shared/content_distribution.ts` und `_shared/content_verification_steps.ts`.
Beide produktiven Einstiegspunkte `content-publish` und `content-release`
importieren diese Verteilung. Für den ausstehenden pt-BR-Stand beide deployen;
keine KI-Function und keine neue Migration dieses Inkrements. Bestehende
Distribution-/Verification-Migrationen vorab als vorhanden verifizieren;
keinen pauschalen `db push` ausführen.

Später autorisiert, Windows (PowerShell) und macOS (Terminal), identisch:

```text
supabase functions deploy content-publish --project-ref yevntxclpchapacqdizm
supabase functions deploy content-release --project-ref yevntxclpchapacqdizm
```

Bestehende JWT-Prüfung (`verify_jwt=true`) und Zugangskonfiguration erhalten.

**Leserfreigabe:** ausschließlich vorhandenes `public.content_readers` für
`(user_id, channel, lang)`. Vor Änderung in Supabase Dashboard → Projekt →
Authentication → Users Kontozuordnung bestätigen; bekannte ID allein genügt nicht.
SQL Editor, zunächst nur lesen:

```sql
select id, email, email_confirmed_at, banned_until
from auth.users
where id = '2af98709-72e6-4f38-b36c-997473e9eb48';

select user_id, channel, lang
from public.content_readers
where user_id = '2af98709-72e6-4f38-b36c-997473e9eb48';
```

Nur nach ausdrücklicher Kontobestätigung und späterer Berechtigungsfreigabe:

```sql
insert into public.content_readers (user_id, channel, lang)
values ('2af98709-72e6-4f38-b36c-997473e9eb48', 'internal', 'pt-BR')
on conflict (user_id, channel, lang) do nothing;
```

Danach dieselbe Leserabfrage wiederholen. Englischen Eintrag erhalten. Keine
Eintragung in `content_publishers`, kein `GRANT` und keine neue Policy. Die
vorhandene Migration aktiviert RLS und entzieht public/anon/authenticated den
Direktzugriff; Functions prüfen die sprachgebundene Liste über service_role.
Kein manuelles Anlegen/Umsetzen von `content_channels`; das macht der bestehende
Publish-CAS. Ein berechtigter Publisher meldet sich separat an.

**Editor-Klickweg für die echte Lieferung:**

1. Bestehenden Editor mit aktuellem Quellstand starten; pt-BR auswählen.
   Vorhandenen leeren Vorbereitungentwurf und andere Entwürfe erhalten.
2. Importieren → Original-ZIP → vollständige Vorschau prüfen: 20 Ziele, ein Stapel,
   keine unvollständigen/konfligierenden Zielrefs. **„Alle Zeilen als neuen Entwurf
   übernehmen“**, niemals „An aktuellen Entwurf anhängen“.
3. Technisch prüfen. Dann alle Texte, Glossen, Lücken, Bedeutungsbindungen,
   brasilianischen Gebrauch, Satz-/Nebensatzgrenze und Niveau tatsächlich manuell
   prüfen. „Redaktionell bestätigen“ → echte Prüfperson und Prüfnotiz →
   „Prüfung bestätigen“, gebunden an den aktuellen Payloadhash und BR-Policy.
4. Inhalte → Exportieren → „Installierbare Inhaltsversion (Release)“; erster
   regulärer pt-BR-Release, etwa `ptbr_allgemeine_sprache_v1`. Kein englischer
   Parent, keine Bestandsadoption und keine Assetübernahme. Erstgeneration hat
   erwartete Kanalgeneration 0 und veröffentlichten Parent null.
5. Veröffentlichungen → „Private Veröffentlichung“, als vorhandener Publisher
   anmelden. Ausgewähltes pt-BR-Bundle: „1 · Hochladen“ → „2 · Serverprüfung“
   mit normalen 13 Stufen F0–F8/M/P_full/H/A → „3 · Privat veröffentlichen“.
   Nur bei angezeigtem Bedarf ausdrückliches Resume desselben Uploads; Fehler
   stoppt, kein automatisches Wiederholen und kein Neu-Upload auf Verdacht.
6. Nach CAS prüfen: ausschließlich pt-BR/internal Generation 1, unverändertes
   Manifest/Bundle; en-Kanal erhalten. Erst danach auf dem freigegebenen Konto
   pt-BR prüfen/herunterladen/aktivieren. Das wählt keine andere Sprache aus.

**Einmaliger iPhone-Build:** nach vollständiger lokaler UI-Abnahme einmal mit bisherigen
Signierungs-/Bundle-ID-Einstellungen und bestehender Appinstallation am Mac
bauen/aktualisieren. Vorhandenen Gerätebefehl und öffentliche Projektkonfiguration
in `docs/content-update-active-context-fix.md` verwenden; SUPABASE_URL dieses
Projekts und öffentlichen Appkey lokal setzen. Keine Deinstallation, kein Reset,
keine echte user.db für Tests verwenden. Windows/PowerShell kann keinen iPhone-
Build ausführen. Anschließend echte Abläufe en → pt-BR vor Installation → Neustart
→ Installation/Updates → leerer Storybereich/Teststapel → en und persönliche
Daten abnehmen. Bisherige Daten nicht durch Testreviews verändern.

## Graph-, Diff- und Sicherungsnachweis

Vor Symboländerungen wurden GitNexus-Impacts ausgeführt; HIGH bei gemeinsamem
Reader-/Installations-/Review-/Updatepfad und CRITICAL am HomeHeader wurden
benannt. UNKNOWN-Providerkanten wurden zusätzlich an tatsächlichen Referenzen
überprüft. Diese Kantenauflösung ist keine vollständige Laufzeitgarantie.

Der aktuelle CLI 1.6.12 wurde über `.gitnexus/run.cjs` verwendet; erneute
`analyze --index-only --pdg`-Läufe nach den Änderungen. Status vor dem Commit:
`up-to-date`, Runneridentität Schema 4/current, `incompleteReasons: []`,
indexierter Ausgangscommit `67386c70293c902381542e0635026df49ad6b861`,
Arbeitsbaumdrift aktuell. Vollständige strukturierte `detect_changes(scope: all)`
und `scope: staged` aus demselben installierten LocalBackend werden vor Commit
gespeichert; keine partial-/truncated-Freigabe. Der CLI-Kurztext schneidet nur
Anzeigelisten ab und wurde deshalb nicht allein als Nachweis verwendet.

Graph-Risiko **critical**: gemeinsames Gate/`acquire`, Reader, Review und UI.
Zusätzlich enthält der Graph sprachübergreifende heuristische `acquire`-Kanten zu
Python-/Serverabläufen; die tatsächlichen Dart-Gate-Aufrufstellen und die
geänderten Dateien wurden ergänzend gelesen. Keine Interpretation als Low-Risk
oder als bestandenes UI. Die regulären Update-/Barrier-/Historientests bestehen;
die zwei roten UI-Tests bleiben ausdrücklich Commitbestandteil und Restarbeit.

CRLF-Konvention der bearbeiteten Bestandsdateien bleibt erhalten. Prüfbefehl auf
Windows (PowerShell) und macOS (Terminal) identisch:
`git -c core.whitespace=cr-at-eol diff --cached --check`. Nur eigene Dateien werden
als Zwischenstand committed. Fremdes `published-baseline-transfer/`, echte
user.db, englische Assets, Editorstore, publizierte Bundles, Signierung und
Bundle-ID bleiben unangetastet. ZIP und lokale Prüflogs bleiben außerhalb des
Commits. Kein Push und keine Betriebsaktion.
