# STORY_STATUS_01 – Gerätebestand, 24.10.2026

## Nachgewiesene Ursache

Die nur lesende lokale Reproduktion mit kopierter Geräte-user.db (Schema 6,
76 Karten, 78 Reviews, fünf Story-Kontexte) und heruntergeladenem Gerätepack
reproduziert exakt den Nutzerbefund. Keine Reviews/Adds auf dem Gerät ausgelöst.

Vor Korrektur: arrives und points werfen `StateError` in
`DriftUserRepository._guardCards` (Zeile 41), aufgerufen von `cardStates`
(Zeile 82) und `storyLearningStatus` (vor Korrektur Zeile 515).
Die deterministische ID einer noch nicht gespeicherten lokalen Karte wurde
an die strikte Packprüfung übergeben. Die produktive `contentIds`-Anbindung
verlangt für eine nicht gespeicherte ID eine Packkarte. Die zukünftige lokale
Karte ist naturgemäß keine Packkarte. Bisherige Tests ohne diesen Callback
konnten den Fehler nicht erkennen.

| Wort | Packkarte | gespeicherte Bindung | Formfunktion | Ergebnis vorher → nachher |
|---|---|---|---|---|
| arrives | nein | nein | nein | StateError → available |
| points | nein | nein | nein | StateError → available |
| station | ja, Gruppe mit einem Mitglied | nein | nein | available → available |
| early | nein | ja | nein | added → added |

Alle vier Kandidaten haben eine Sensebindung und bestehen die vorhandene
Kandidatenvalidierung. Aktuelle Revision: `chitchat_de_korrektur_v1`.
Die fünf gespeicherten Kontexte stammen aus `story_contexts_v1` (3) und
`story_single_sentence_v1` (2). Sie werden durch Statusabfragen nicht ersetzt.
Formbindungen fehlen im Gerätebestand; synthetische bestehende Form-/Sprachtests
bleiben deshalb zusätzlich erforderlich. Altbestand ist vorhanden, verursacht
aber nicht den Fehler: Entscheidend ist die fehlende zukünftige lokale Zeile.

## Tatsächlich gelesener Pack

Aktiver Manifeststand: en, Generation 2, Schema 5,
Version `chitchat_de_korrektur_v1`.
Heruntergeladene Generation: `510c6685-f0ea-4002-9c7c-a09f0bf8212b`.
43.089.920 Bytes; SHA-256
`30cfd77190e8985dac0c058fa3504c3bf20c792ea8830adec2a48b185dda46be`.
Der beim Kopieren aktive Reader `process-ZZooqH/reader-ar0FC5` ist hashgleich.
Auch der Hash in `active.json` stimmt überein.
Bootstrap: 26.198.016 Bytes; SHA-256
`b85793932825a22e92ac744a42255e9f333acd35809aaba46edb5a395f099bdb`.
Damit ist die Geräteprüfung ausdrücklich kein Bootstrap-Nachweis.
Private Kopien liegen ausschließlich außerhalb des Repositorys im geschützten
Temporärverzeichnis; keine Texte, IDs, Zugangsdaten oder Datenbankkopien im Commit.

## Minimale Korrektur und Diagnose

Nur die zukünftige, aus dem validierten Kandidaten abgeleitete lokale ID wird
zunächst auf Existenz geprüft. Existiert ihre Zeile, läuft sie weiter durch die
unveränderte Sprach-/Referenzprüfung. Explizite gespeicherte Bindungen und
Packreferenzen laufen immer durch dieselbe Prüfung, auch bei fehlender Zeile.
`_guardCards`, Kandidatenvalidatoren, Resolver, Cache und Scheduler unverändert.
Kein Generieren, Löschen, Migrieren oder Umstufen defekter Referenzen.

Der Statusdienst protokolliert im Debug-/Profile-Modus nur Fehlercode,
Exceptionklasse und maximal drei Paket-Quellpositionen. Weder `error.toString()`
noch rohe Stackzeilen werden ausgegeben. Der sichere UI-Code bleibt erhalten.
Ein Test prüft explizit die Entfernung von SQL, privaten URLs und Texten.

## Prüfung

- Neue synthetische Regression mit bestehender lokaler Karte/Alt-Kontext und
  produktivem Pack-ID-Callback: vor Korrektur FAIL mit obigem StateError,
  nach Korrektur PASS. Fehlende beliebige IDs, falsche Packreferenzen und
  sprachfremde Karten bleiben Fehler; Statuslesen verändert Karten/Kontexte nicht.
- Gerätekopie read-only: alle vier Statuswerte nach Korrektur wie oben, PASS.
- 66 gezielte Tests PASS, ein bestehender Skip: Story-/Resolver-/Migration-/Cache-
  Tests, sichere Fehleranzeige, neue Regression und unveränderter Original-Packtest.
- Analyse: nur bestehendes `avoid_print` in baseline_adoption_pack_test.dart:43.
- Ein gezielter Produktkorrekturversuch; keine spekulativen Folgekorrekturen.
- Geräte-UI-Abnahme anschließend durch Nutzer bestätigt: „Alle vier verhalten sich korrekt“. Geräte-PASS als Nutzerbeobachtung, keine eigene Bildschirmbeobachtung.
- Profile-Build erfolgreich (50,9 s), anschließend direkte devicectl-Installation
  als Update erfolgreich auf iPhone von Claus, UDID 00008110-001651611E01401E.
  Vorhandene SUPABASE_URL/SUPABASE_ANON_KEY aus Generated.xcconfig unverändert
  übernommen. Kein Reset, keine Deinstallation, keine Cloudänderung.
- Automatischer Vordergrundstart blockiert: Gerät gesperrt,
  FBSOpenApplicationErrorDomain Code 7 / CoreDeviceError 10002.
  Ein Runner-Prozess ist vorhanden; das ist kein Nachweis geöffneter Wortdialoge.
- Nach Update erneut kopierte user.db: user_cards (76), review_log (78),
  card_contexts (5), story_learning_additions (5), story_word_sources (7),
  learning_identity_bindings (5), form_identity_bindings (0), deck_settings (3)
  und language_learning_preferences (1) zeilenweise unverändert.
- GitNexus nach vollständiger Neuindizierung: detect_changes all, 7 Dateien,
  12 Symbole, Risiko medium, betroffener Diagnosepfad Reactivate → StoryFailureTrace;
  keine partial-/truncated-Markierung. Zusätzliche Textprüfung der Interface-Aufrufer:
  Statusdienst und addStoryWord; beide in den gezielten Tests erfasst.
- Nächster Geräteschritt: entsperren und ausschließlich die vier Wortdialoge öffnen;
  erwartete UI: arrives/points fachlicher Status ohne STORY_STATUS_01,
  station verknüpfbar, early bereits hinzugefügt. Nutzer zur Abnahme angefragt.

Nach Installation bestätigt der Nutzer die manuelle Prüfung aller vier Wortdialoge
auf dem iPhone als korrekt. Damit ist die Geräteabnahme durch Nutzerbeobachtung
erfolgt; der vorangehende gesperrte Startversuch bleibt als Werkzeuggrenze dokumentiert.
