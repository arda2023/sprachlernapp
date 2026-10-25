# Paket 2C: Import-Wortstelle hinter Bindestrich — 25.10.2026

## Ursache und Abgrenzung

Reproduktion mit dem ausdrücklich vorgegebenen synthetischen Regressionstext
`I am the return-hamster`: Der Reader erzeugte `hamster` bei UTF-16-Offset 16.
`PersonalTarget.validate` verlangt eine komplette Wortstelle; `personalWords`
erkennt dagegen `return-hamster` bei Offset 9 als zusammenhängendes Wort.
Damit wirft `lib/domain/personal_learning.dart:43` eine `FormatException`,
aufgerufen von `_PersonalLearningButtonState._load`, **vor** Statusrepository,
Releaseauflösung oder irgendeiner Erstellung. Der UI-Catch verbarg die Ursache
hinter „Lernstatus nicht lesbar“. Sichere Diagnose enthält nur Exceptionklasse,
Code und Paketpositionen, keine Exceptionnachricht, Texte, SQL oder Tokens.

Reader-Regression vor Korrektur: zwei Bindestrichfälle FAIL, normaler Satz und
Mehrsatz-Gegenprobe PASS. Einschließlich vorangestelltem Emoji zeigt das denselben
Grenzenkonflikt; kein UTF-16-Zählfehler. Ein fehlender Punkt am Ende wird durch
die bestehende Satzsegmentierung korrekt als letzte Satzspanne erhalten.

Fix 1c31881 bleibt unverändert: Hier wird keine zukünftige lokale ID an
`_guardCards` geschickt. Der persönliche Statusdienst prüft nur tatsächlich
vorhandene Identitätsbindungen; unbekannte Wörter ohne Bindung liefern null.
Produktiver `contentIds`-Callback ist in den neuen Regressionen aktiv.

## Minimale Änderung

Der Reader verwendet für unannotierte Import-/Nachrichtentexte dieselbe
`personalWords`-Segmentierung wie der unveränderte Lernkartenvertrag. Ein Tap
auf einen Bestandteil wählt damit **das ganze Bindestrichwort**. Im normalen
Satz bleibt `hamster` ein eigenständiges Ziel. Übersetzung und Lernkarte erhalten
dieselbe vollständige Wortstelle; kein stilles Austauschen nur für den Add-Pfad.
Annotierte Packtokens und sämtliche Validatoren bleiben unverändert.

Nur eine unmittelbar bei der Zielvalidierung geworfene FormatException erhält
einen fachlichen Hinweis zur ungeeigneten Wortstelle. Fehler aus Provider/DB
bleiben technische Fehler; keine Gleichsetzung mit fehlender Packkarte.
Beide Fehler sperren weiterhin den Button. Keine Änderung an Rückstellungsschutz,
Consent, Sprach-/Releasebindung, Cache, Scheduler oder Backend.

GitNexus (Hauptprojekt, aktualisierter Index): `_addSentence` LOW, direkter
Aufrufer Reader-initState; `_load` LOW, initState/didUpdateWidget. `_wordPattern`
UNKNOWN, deshalb textuell bestätigt: genau eine Verwendung in `_addSentence`.
Neue Tests sind Flutter-Test-Einstiegspunkte; fehlende Graphcaller sind kein
Nachweis fehlender Nutzung. Ein Produktkorrekturversuch. Ein späterer Fehler bei
der Registrierung zweier zusätzlicher Tests wurde nur im Testaufbau korrigiert.

## Prüfungen und tatsächlicher Gerätestand

- Vorheriger installierter Build: devicectl bestätigt Bundle `com.example.sprachapp`,
  Version 1.0.0, Build 1. Diese wiederverwendete Nummer belegt keinen Gitcommit;
  der konkrete Fehler wurde lokal aus dem Reader heraus reproduziert, nicht als
  ausgelesener iPhone-Stack ausgegeben.
- Aktives englisches Gerätejournal erneut lesend exportiert und exakt mit dem
  zuvor auditierten Journal verglichen: Release
  `510c6685-f0ea-4002-9c7c-a09f0bf8212b`. Read-only-Packexport SHA256
  `30cfd77190e8985dac0c058fa3504c3bf20c792ea8830adec2a48b185dda46be`.
- Neue Tests: echter Reader-Tap, produktiver Serviceprovider, Drift-Content und
  Drift-Userrepository mit Packguard. Normalfall, Bindestrich, Emoji und zweite
  Satzspanne. Status ohne Token-/Erstellungsaufruf; explizites Add mit lokalem
  synthetischen HTTP-Backend, separate Zustimmung, idempotentes Speichern,
  `explicitStoryAdditions` („Aus Storys“) und lokale Übungskontexte. Kein Review.
- 38 gezielte Tests PASS einschließlich Original-Pack, persönlichem Add,
  Bedeutung/Rückstellung, Consent, Satzprüfung, Übersetzung und altem Statusguard.
  Original-Packprüfung mit unverändertem Budget, kein Bootstrapersatz für Gerätepack.
- Zusätzlich dieselben fünf Reader-/Add-Tests gegen obigen tatsächlichen Gerätepack:
  5 PASS. Userdaten dabei synthetisch, keine echte user.db verändert oder exportiert.
- Nach Ergänzung der fachlich/technisch getrennten Fehlerfälle: neue Testdatei
  7 PASS. Analyse ausschließlich bekannter Hinweis
  `baseline_adoption_pack_test.dart:43 avoid_print`, keine neuen Befunde.
- Function-/Migrationsstand nur lesend geprüft: `create-learning-card` v1 ACTIVE,
  `verify_jwt=true`, Migration `20261024000002` vorhanden. Keine erneute Migration,
  kein Deployment, kein realer Modellaufruf. Verfügbarkeit ist keine Liveabnahme.
- Profile-Build erfolgreich (27,4 s Xcode, 66,3 MB). Supabase-Defines aus bestehender
  Generated.xcconfig unverändert übernommen; temporäre geschützte Übergabedatei
  danach entfernt, keine Werte in Logs/Commit. Installation als Update und Start
  auf `iPhone von Claus` / `00008110-001651611E01401E` erfolgreich.
- Keine Deinstallation, kein Reset, keine automatisierten Adds/Reviews auf dem
  Gerät. Bestehende fremde Änderungen erhalten und nicht in diesen Commit aufgenommen.
  Der Build enthält den aktuellen Arbeitsbaum einschließlich fremder UI-Arbeit.
- **Kein Geräte-Funktions-PASS:** Installation/Start beobachtet, Wortdialog und
  echter Add werden vom Nutzer geprüft. Kein byteweiser Lernstandvergleich behauptet.

## Nutzerprüfung

Englisch → Stories → vorhandenen Import öffnen → auf den hinteren Wortteil
`hamster` tippen. Auswahl muss `return-hamster` umfassen, technischer Statusfehler
verschwinden. Erst selbst „Zum Lernen hinzufügen“ drücken und gegebenenfalls die
separate Lernkartenfreigabe bestätigen; anschließend „Aus Storys“ prüfen.
Gegenprobe: `The hamster sleeps in its cage.` → `hamster` → ausdrücklich hinzufügen.
Modellqualität/Liveergebnis sind damit noch offen; Fehler nicht durch automatische
kostenpflichtige Wiederholungen kaschieren.
