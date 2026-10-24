# Paket 2B – Offline-Anzeigeübersetzungen

## Vertrag vor Implementierung · 24.10.2026

Ausgangsbasis: sauberer Hauptprojekt-Commit 1c31881. Nutzer bestätigt Paket 2A
auch offline und nach Neustart; dies ist ein Nutzerbefund.

1. Geprüfte Pack-/Kontextübersetzungen bleiben im vorhandenen Reader zuerst.
   Der bestehende Fallbackdialog liest zuerst den exakten privaten Haiku-Cache.
   Bei Wörtern folgen separat gespeicherte Wörterbuchkandidaten; bei Sätzen
   ein expliziter Geräteübersetzungsauftrag. Haiku bleibt ein eigener bewusster
   Button mit Uploadhinweis. Kein lokaler Fehler startet einen Remoteaufruf.
2. Wörterbuch: deutsche Wiktionary-Ausgabe über Kaikki, Englisch und Portugiesisch,
   konkrete JSONL-Lieferungen vom 24.10.2026, SHA-256 im Buildmanifest.
   Nur deutsche Glossen und ausdrücklich vorhandene `form_of`-Referenzen;
   keine Endungsregeln und keine fremdsprachigen Glossen als deutsche Übersetzung.
   Die extrahierten `forms`-Tabellen enthalten auch fehlzugeordnete Pronomen
   (z.B. I → go); sie werden bewusst nicht als sichere Flexion übernommen.
   Alle Treffer bleiben Kandidaten, keine automatische Sense-/Lernkartenbindung.
3. Reproduzierbarer Python-Konverter liefert ein eigenes indexiertes SQLite-Asset,
   gebündelt mit der App, damit kein zusätzlicher Wörterbuchdownload nötig ist.
   Lazy-Installation mit Versionshash, temporärer Datei und atomarem Rename;
   Hashprüfung/Entpacken/SQLite-Lookup außerhalb des UI-Isolates. Keine Vollabfrage
   beim Appstart und keine Änderungen an content.sqlite/user.db.
4. Datenlizenz CC BY-SA 4.0: abgeleiteter Wörterbuchbestand unter derselben Lizenz,
   Autoren-/Versionsgeschichte über pro Eintrag erhaltene Wiktionary-URL,
   Kaikki-/Wiktextract-Herkunft, Bearbeitungshinweis und Lizenztext in der Lieferung
   und über Quellenanzeige im Dialog. Keine Audio-/Bildübernahme.
5. iOS: eigenes lokales Flutter-Plugin, Apple Translation ab iOS 18,
   tatsächliche Sprachpaarprüfung durch LanguageAvailability. Explizite Vorbereitung
   über prepareTranslation; danach Übersetzung nur bei installiertem Modell.
   SwiftUI-Session an sichtbarem Host, Abbruch beendet die App-Anfrage und verwirft
   späte Ergebnisse. Systemverwaltete Downloads können weiterlaufen; keine Zusage
   bytegenauen Abbruchs oder fester Apple-Modellgröße.
6. Android: lokales Plugin mit ML Kit, en/de/pt-Language-Models, nur bestätigter
   Modelldownload; portugiesische Variante nicht regional zugesichert. Plattform-
   fehler sind normale lokale Zustände. Geräteergebnisse eigene Herkunft, keine
   Anthropic-Payload. Kein neuer Cloudspeicher. Google-Attribution sichtbar.
7. Lokale Ergebnisse werden in diesem Paket nur im offenen Dialog gehalten;
   keine persistente Speicherung als vermeintliche Anthropic-Antwort. Der exakte
   private Cache aus Paket 2A bleibt unverändert priorisiert und kontogebunden.
8. Story-Add, Identitäten, Reviews, Importtokenisierung und Scheduler unverändert.
   Wörterbuch und Geräteübersetzung sind Anzeigehilfen, kein geprüfter Lernkontext.

## Primärquellen und Auswahl

- [Kaikki deutsche Ausgabe](https://kaikki.org/dewiktionary/): deutsche Glossen,
  Daten aus Wiktionary, Extraktion mit Wiktextract; Extraktionsfehler möglich.
- [Englische Lieferung](https://kaikki.org/dewiktionary/Englisch/index.html),
  [portugiesische Lieferung](https://kaikki.org/dewiktionary/Portugiesisch/index.html).
  JSONL-Dateien tatsächlich heruntergeladen: 83.208.409 / 8.988.739 Bytes.
  Diese sprachweisen postprozessierten Downloads sind vom Anbieter als künftig
  entfallend markiert; eingefrorene Hashes schützen diesen Build. Ein späteres
  Update auf Rohdump braucht eine neue validierte Konvertierung.
- [FreeDict](https://freedict.org/downloads/) bietet ebenfalls en-de/por-de;
  die hier gewählte Wiktionary-Ausgabe liefert unmittelbar deutsche Sinne und
  ausdrückliche Formreferenzen in einem einheitlichen überprüfbaren Datenformat.
  Keine Aussage, FreeDict sei generell ungeeignet oder unlizenzierbar.
- [Wiktionary-Lizenz](https://de.wiktionary.org/wiki/Wiktionary:Lizenzbestimmungen):
  aktueller Seitenfuß CC BY-SA 4.0; historischer Haupttext nennt noch 3.0.
- [Apple Translation](https://developer.apple.com/documentation/translation),
  [prepareTranslation](https://developer.apple.com/documentation/translation/translationsession/preparetranslation()),
  [LanguageAvailability](https://developer.apple.com/documentation/translation/languageavailability).
- [ML Kit Android](https://developers.google.com/ml-kit/language/translation/android),
  [Sprachen](https://developers.google.com/ml-kit/language/translation/translation-language-support),
  [Nutzungsregeln](https://developers.google.com/ml-kit/language/translation/translation-terms),
  [Attribution](https://docs.cloud.google.com/translate/attribution).

## Gelieferter Bestand und Grenzen

| Bestand | Englisch → Deutsch | Portugiesisch → Deutsch |
| --- | ---: | ---: |
| Quellzeilen | 70.891 | 7.595 |
| Deutsche Bedeutungsdatensätze | 22.860 | 1.536 |
| Unterschiedliche nachschlagbare Formen | 21.665 | 7.344 |
| Aufgelöste Form→Bedeutung-Verknüpfungen | 19.522 | 16.033 |
| Nicht aufgelöste explizite Quellverweise | 45.483 | 71 |

Formverknüpfungen sind keine zusätzlichen Bedeutungen. Viele englische Formzeilen
verweisen auf im Auszug fehlende Grundwörter; diese bleiben bewusst unaufgelöst.
`bank` liefert mehrere Kandidaten, `went` verweist belegt auf `go`, `fui` auf `ser`.
`coração` wird mit Akzent (auch NFC/NFD) gefunden; `coracao` wird nicht geraten.
`do`, `na` und `of course` fehlen in dieser Lieferung; `from scratch` und
`por favor` sind vorhandene Mehrworttreffer. Der Reader bleibt bei seiner bisherigen
Wortauswahl; es gibt keine neue automatische Phrasenerkennung. Wiederholte Wörter
behalten die bestehenden exakten Cachepositionen, das Wörterbuch kennt keinen
Kontext und keine Position. Allgemeinportugiesische Daten, keine Vollständigkeits-
oder ausschließlich brasilianische Varianten-/Qualitätszusage.

Gebündeltes Gzip: **1.473.187 Bytes**; installierte SQLite-Datei **5.779.456 Bytes**.
Kein separater Wörterbuch-Netzdownload. Erstes Nachschlagen installiert lokal;
kurzzeitig werden Archiv, entpackte Daten und temporäre Datei benötigt. Lizenz,
Manifest und Attributionsgrafik kommen zusätzlich hinzu. Ein späteres Datenupdate
benötigt derzeit ein App-Update, keine zusätzliche Downloadplattform.

Der Konverter ist mit denselben beiden Quellen erneut ausgeführt worden:
Gzip und Manifest bytegleich (`cmp`, Exit 0). Quellhashes stehen im Manifest;
vor einem erneuten Lieferbuild sind heruntergeladene Quellen gegen diese Hashes
zu prüfen. Der Konverter zeichnet neue Hashes auf, erzwingt aber keinen Lock gegen
unabsichtlich ausgetauschte Quellen. SQLite-/Python-/Gzip-Versionen können bei
anderen Werkzeugständen die Binärdarstellung ändern; Inhaltsprüfung bleibt nötig.

## Plattformvertrag und Downloads

- iOS: API ab **iOS 18**, tatsächliche Paarunterstützung zur Laufzeit. Expliziter
  Modellvorbereitungsschritt mit Apple-Systemdialog. Apple nennt keine feste
  Paketgröße; daher keine erfundene Größenangabe. Nach Installation wird das
  Modell lokal verwendet; fehlende Modelle werden beim Übersetzen nicht still
  nachgeladen. Apple Translation hat eigene Systembedingungen und Modellverwaltung.
- Android: Plugin **API 24+**, ML Kit **17.0.3**. Modelle ungefähr **30 MB je Sprache**:
  en→de benötigt de, pt→de zusätzlich pt (insgesamt ungefähr 60 MB für beide Paare).
  Download nur nach Auswahl und über WLAN. Portugiesisch→Deutsch läuft laut ML Kit
  über Englisch; mögliche Qualitätsverluste und keine spezielle pt-BR-Zusage.
- Abbruch beendet die App-Anfrage und verwirft späte Antworten. Systemdownloads
  können weiterlaufen. Download-/Speicher-/Verfügbarkeitsfehler bleiben lokale
  Fehler und lösen keinen Haiku-Aufruf aus. Native Fehler enthalten nur Codes.
- Ergebnisse tragen Apple- bzw. Google-Herkunft und lokalen Vertrag 1; sie leben
  nur im offenen Dialog. Keine persistente Gerätecachemigration, kein Schreiben
  einer lokalen Antwort als Anthropic-Payload. Google-Badge erscheint am Ergebnis.
- Ohne unterstützte Plattform bleibt Wörterbuch/privater Cache nutzbar; Haiku ist
  weiterhin bewusst auswählbar. Ein fehlerhafter privater Cache wird nicht durch
  Überspringen seiner Sicherheitsprüfung verborgen.

## Nachweise · 24.10.2026

- Gezielte Wörterbuch-/Dialog-/Cachetests: **43 PASS**. Reale Assetdaten, Mehrdeutigkeit,
  Akzente, belegte Formen, Sprachtrennung, kaputtes Archiv/Schreibfehler, exakter
  Cachevorrang, fehlende Modelle, unsupported, storage, Downloadfehler, Abbruch
  und späte Antwort. Plattformkanäle hierfür simuliert, keine Geräteabnahme.
- Vollständige Flutter-Suite: **569 PASS, 6 bestehende Skips**, 2:00 Minuten.
  Original-Packtest enthalten und bestanden, bestehende Budgets nicht verändert.
  Widgettests erhalten explizite lokale Adapter statt realer Datei-/Plattform-I/O
  im FakeAsync-Test; ihre bisherigen Assertions bleiben erhalten.
- Stage-Verify: **PASS**, 22 Tabellenzählungen; Original-Pack 26.198.016 Bytes,
  SHA-256 `b85793932825a22e92ac744a42255e9f333acd35809aaba46edb5a395f099bdb`.
- Flutter analyze: nur bestehender `avoid_print`-Hinweis in
  `test/data/baseline_adoption_pack_test.dart:43`; keine neuen Befunde.
- Lookupmessung realer DB: 30 isolierte Abfragen zusammen ungefähr **86–104 ms**
  auf Entwicklungs-Mac einschließlich Isolate-Starts; keine iPhone-Latenzzusage,
  kein belegter Appstart-/Frame-Benchmark. Installation bleibt lazy.
- iOS Profile erfolgreich gebaut (Runner.app 66,2 MB), auf iPhone von Claus als
  Update installiert und gestartet, vorhandene Supabase-defines beibehalten.
  Kein Reset, keine Deinstallation, keine automatisierten Reviews/Adds.
- Lesende Datenbankkopien vor/nach Update: alle 11 Nutzertabellen zeilengleich,
  insbesondere 76 user_cards, 78 review_log, 5 card_contexts, 5 Story-Adds,
  7 Storyquellen und 5 learning_identity_bindings. Keine privaten Zeilen ausgegeben.
  Vergleich der kopierten DB-Dateien, keine eigene Interaktionsabnahme.
- Android Debug-APK erfolgreich gebaut; **kein Android-Gerät geprüft**.
- Nutzerbefund: Wörterbuch auf iPhone funktioniert. Englische Satzübersetzung
  scheiterte zunächst, Portugiesisch noch nicht getestet. Diagnose auf dem Gerät:
  `register controller=absent`. Der bei Pluginregistrierung gespeicherte nil-
  Controller blieb nil und führte zum `busy`-Guard, noch vor Apple Translation.
  Ein gezielter Fix fragt nun `registrar.viewController` erst pro Anfrage ab,
  wie die Flutter-Anbindung im vorhandenen offiziellen url_launcher_ios-Plugin.
  Nach dem Fix auf dem Gerät beobachtet: `request stage=prepare
  controller=present active=false` und `session stage=prepare`. Der native
  Vorbereitungspfad wird jetzt tatsächlich erreicht. Erneute Satz-/Flugmodus-
  abnahme ausstehend; noch kein Geräte-PASS für Übersetzung.
- Lokale Diagnose hält maximal zwölf technische Ereignisse in
  `Library/Caches/device_translation_diagnostic.txt`: Stufe, Controllerstatus,
  Fehlerklasse/-domain/-nummer; keine Texte, Antworten oder NSError-userInfo.
  Sie wird nicht hochgeladen und verändert keine Lernstände.
- Null Haiku-Aufrufe im getesteten Wörterbuch-/Cache-/lokalen Erfolgs- und
  Fehlerpfad. Native Adapter enthalten keinen Haiku-/AI-HTTP-Client; Modelldownload
  erhält nur Sprachcodes. Keine kostenpflichtige Liveanfrage, kein Clouddeployment.

## Kurzer iPhone-Klicktest

1. Englischen Testtext `I went to the bank.` als Story öffnen/importieren. `bank`
   zeigt mehrere Wörterbuchbedeutungen; `went` einen belegten Formverweis, sofern
   keine vorrangige genaue Übersetzung existiert. Nichts zum Lernen hinzufügen.
2. Satzübersetzung öffnen → ggf. Sprachmodelle vorbereiten → anschließend bewusst
   „Auf dem Gerät übersetzen“. Nach Modellinstallation im Flugmodus wiederholen.
3. Unter Portugiesisch `O coração é importante.` ebenso prüfen; Akzent erhalten.
4. Abbrechen bzw. ohne Modell offline probieren: lokale Meldung, kein automatischer
   KI-Aufruf. „Mit KI übersetzen“ bei diesem kostenfreien Test nicht antippen.

## Schnittstellen für Import → Lernkarte (Folgepaket)

- `OfflineDictionary.lookup(lang, form)` liefert `DictionaryCandidate` mit Lemma,
  Wortart, Glosse, Tags, Quell- und Formquell-URL; bewusst ohne card_id/sense_id.
  Diese Anzeigehilfe darf keine Identitätsentscheidung ersetzen.
- `DeviceTranslation.status/prepare/translate/cancel` kapselt Plattformzustand und
  lokale Satzanzeige. Sprache en/pt-BR, Ziel de, Text maximal 600 UTF-16-Zeichen;
  kein Lernkontext-Validator und kein Generator.
- `offlineDictionaryProvider` / `deviceTranslationProvider` sind die austauschbaren
  Adapter; `RuntimeTranslationSheet` behält seine vorhandenen Kontextparameter.
- Für künftige Lernkarten weiterhin vorhandene Story-Resolver/Add-Validierung mit
  Sprache, exakten Offsets, Kontextrevision und Sense-/Formbindung verwenden.
  Paket 2B erweitert diese Verträge nicht. Geprüfter Kontext bzw. gesonderte
  redaktionelle Freigabe bleibt Voraussetzung; Wörterbuch-/Geräteanzeige allein
  macht ein bisher nicht lernbares Importwort nicht lernbar.

## Abschließende Änderungsprüfung

GitNexus `detect_changes(scope=all)` nach Aktualisierung: 75 geänderte Symbole,
38 Dateien, 6 zugeordnete Abläufe, Risikostufe **high**, ohne partial/truncated.
Readerdialog und native Handle/Finish/Diagnosepfade sind tatsächlich betroffen.
Die drei zusätzlich ausgewiesenen Publish/Perform/Release→Fetcher-Pfade beruhen
auf einer fehlerhaften Graphzuordnung der Property `formSource` (leere UID;
Context ordnet fremde Klassen zu). Quellprüfung: tatsächliche Verwendung nur
DictionaryCandidate, Quellenanzeige und Wörterbuchtest; keine Editor-/Release-
Datei verändert. Der Graph ist damit ein Prüfhinweis, keine pauschale Entwarnung.
Vollständige Flutter-Regression und beide nativen Builds wie oben; noch offene
Geräteabnahme ausdrücklich getrennt.
