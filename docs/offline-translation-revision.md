# Paket 2B · geänderter Übersetzungsvertrag · 24.10.2026

## Entscheidung vor Implementierung

Ausgangspunkt: sauberer Commit 6d3427d. Dieser Vertrag ersetzt die Geräte-
übersetzung und Kandidatenliste aus dem ursprünglichen Paket 2B.

1. Wort-Tap: geprüfte Wortstelle → exakter privater Kontextcache → ausreichend
   einfacher Wörterbuchfall → automatisches Haiku nur mit dauerhafter Zustimmung.
   Keine Vorabübersetzung bei Storyöffnung, Scrollen oder Import. Satz: explizite
   Aktion „Übersetzen“, geprüfter Inhalt/Cache zuerst, sonst bestehendes Haiku.
2. Frühere einzelne KI-Knopfdrücke sind keine dauerhafte Einwilligung. Neue
   Zustimmung versioniert pro Konto/Projekt auf diesem Gerät im privaten Speicher.
   Hinweis: Wort und vollständiger Satzkontext gehen bei Bedarf an Anthropic,
   keine ausschließlich europäische Verarbeitung. Abschaltbar in Einstellungen.
   Ablehnen bleibt gespeichert. Abgemeldet keine Cloudfreigabe. Keine Übernahme
   auf andere Konten; kein Einschalten durch Cachetreffer oder frühere Anfragen.
3. Wörterbuchentscheidung ohne erfundene Sicherheit: alle gelieferten Kandidaten
   prüfen, keine Auswahl nach Reihenfolge/Häufigkeit/Länge. Nur direkte
   Grundform-Substantive mit identischer einfacher deutscher Nomen-Glosse,
   ohne abweichende Sinne, Formverweise oder fachliche/regionale Einschränkungen.
   Geschlechtsangaben sind zulässig. Keine Zerlegung zusammengesetzter Glossen;
   maximal ausgeschöpfte Ergebnismenge gilt als unklar. Exakt gleiche Datensätze
   dürfen zusammenfallen. Anzeige kennzeichnet allgemeine Wörterbuchbedeutung;
   fehlende weitere Wörterbuchsinne bleiben möglich. Verben/abgeleitete Formen
   sind ohne sichere deutsche Flexion kein lokaler Einzeltreffer.
4. Echte Daten: bank hat Finanz-/Ufer-/weitere Sinne; arrives verweist auf arrive
   mit mehreren Infinitiven; went auf go, fui auf ser. Diese bleiben unklar.
   cat → Katze, coração → Herz und oxigênio → Sauerstoff sind einfache direkte
   Nomen-Glossen. do/na fehlen. Keine Sonderregeln für diese Beispielwörter.
5. Technische Cache-/Wörterbuch-/Zustimmungsfehler blockieren den Cloudpfad.
   Nur fachlicher Miss oder Mehrdeutigkeit darf weiterführen. Autorisierung erneut
   vor Textversand prüfen; Widerruf/Kontowechsel und neue Auswahl sperren späte
   Anzeigen. Deduplizierung bleibt konten- und kontextgebunden, keine Retryschleife.
6. Keine Geräteübersetzung und keine Modelldownloadoberfläche mehr; ausschließlich
   dafür eingeführtes Plugin/SDK/Diagnose entfernen. Systemmodelle nicht anfassen.
   Wörterbuch, Lizenz/Quellen, private Cacheidentität, 30-Tage-Aufbewahrung,
   Sprachfreigaben, Limits und Story-Lernstände bleiben erhalten.
7. Wörterbuchübersetzungen werden nicht als Anthropic-Antwort gespeichert und
   erzeugen keine Lernkarte. Kein Clouddeployment, keine bezahlte Liveabnahme.
   Die 30-Tage-Aufbewahrung bleibt eine separate offene Produktentscheidung.

## Umsetzung und Kosten-/Einwilligungsgrenzen

- Apple-/ML-Kit-Plugin samt ausschließlich zugehörigem Dart-Provider, lokaler
  Diagnose, SDK-Abhängigkeit und Google-Badge entfernt. Registrierungen durch
  Flutter-Werkzeuge neu erzeugt. Keine systemweiten Apple-Modelle gelöscht.
  Die frühere Diagnose-Cachedatei wird nicht mehr geschrieben oder ausgewertet;
  alte lokale Cachebytes sind kein aktiver Diagnosepfad.
- Wörterbuchasset, Manifest, ursprüngliche Quelldaten/Lizenz und indexierter
  Isolate-Lookup unverändert: 1.473.187 Bytes Gzip, 5.779.456 Bytes SQLite,
  22.860 en-/1.536 pt-Bedeutungsdatensätze. Keine neue Nutzerdownloadstufe.
- `singleDictionaryTranslation` führt nur gleiche einfache Nomen-Glossen zusammen.
  Tags außer grammatischem Geschlecht, Formlinks, abweichende Bedeutungen, komplexe
  Glossen und 80 Treffer (Abfragegrenze) führen zur Enthaltung. NFC erhält Akzente;
  Originalform/Offsets/Cacheidentität werden nicht normalisiert.
- Keine statistische Konfidenz und keine Vollständigkeitsbehauptung: `cat` kann im
  allgemeinen Wörterbuch „Katze“ heißen, ohne besondere Fachkontexte auszuschließen.
  „Wörterbuch · allgemeine Bedeutung“ bleibt sichtbar; keine lange Kandidatenliste.
- Zustimmung `word_cloud_consent`: owner = vorhandene Projekt-/Kontokennung,
  version 1, enabled, decided_at. Neue Tabelle nur in `private_translations.sqlite`.
  Alte Antworten oder einzelne Buttonbestätigungen setzen diese Tabelle nicht.
  Abmelden/anderes Konto erbt keine Freigabe. Auf einem neuen Gerät neu zustimmen.
- `RuntimeTranslationSheet.wordTap` ist standardmäßig false und wird ausschließlich
  im tatsächlichen Reader-Wortcallback gesetzt. Laden/Scrollen/Import setzen es
  nicht. Ohne Freigabe nur lokale Ergebnisse bzw. einmaliger Aktivierungshinweis;
  nach Ablehnung kompakter Verweis auf Einstellungen. Kein zusätzlicher
  „Im Kontext übersetzen“-Knopf und keine KI-Herkunftsbeschriftung am Ergebnis.
- `CachedRuntimeTranslationClient.translateWordOnTap` prüft Zustimmung und
  Kontorevision. `authorize` wird vor Cache/Remoteübergang und im HTTP-Transport
  nach Tokenbeschaffung sowie unmittelbar vor dem Schreiben des Requesttexts
  erneut aufgerufen. Widerruf während dieser Wartezeiten verhindert Textversand.
  Ein schon gesendeter Request kann noch Kosten verursachen; seine späte Antwort
  wird nach Widerruf nicht angezeigt/neu lokal gespeichert. Keine Rückholgarantie.
- Fehlgeschlagener Widerruf zeigt einen Speicherfehler und sperrt weitere
  automatische Anfragen für diesen Client bis zu erfolgreicher Einstellungs-
  speicherung. Nach Neustart gilt der tatsächlich gespeicherte Zustand;
  fehlgeschlagenes Speichern wird nicht als dauerhaft ausgeschaltet ausgegeben.
- Bestehende In-flight-Identität/Kontorevision/Requesthash bleiben maßgeblich;
  acht gleiche parallele Wortanfragen teilen einen Remoteaufruf. Verschiedene
  Wortstellen, Satztexte und Sprachen bleiben getrennt. Wechsel des Dialoginputs
  invalidiert dessen Epoch; spätere Antwort darf keine neue Auswahl überschreiben.
- Bestehende Endpoints, Request-/Antwortvertrag 2, Anthropic-Validatoren,
  Sprachfreigaben, SQL-Claims und Limits bleiben unverändert. Kein Clouddeployment,
  keine Datenbankmigration auf dem Server. Nach wie vor 5/Minute, 20/Tag/Nutzer,
  1000/Tag global; keine automatische kostenpflichtige Wiederholung.
- `gloss_de` wird unverändert aus der validierten einen Kontextantwort angezeigt;
  ausgewählte Oberfläche und genaue UTF-16-Wortstelle werden mitgegeben. Keine
  lokale Infinitiv-/Flexionsumformung. Eine echte Haiku-Qualitätsabnahme für
  „arrives → kommt an“ ist ohne bezahlten Liveaufruf nicht behauptet.
- 30-Tage-Cachefrist unverändert, Wörterbuch nicht als Anthropic gespeichert.
  Cloudfreigabe ausschalten löscht vorhandene private Treffer nicht; die bestehende
  separate Löschaktion bleibt verfügbar. Keine neue Lernkarte oder Sensebindung.

## Nachweise und Geräteabnahme

- Vollständige Flutter-Suite: **585 PASS, 6 bestehende Skips**, 45 Sekunden,
  Original-Packtest und Story-/Resolver-/Sammlungsregressionen enthalten.
- Gezielter Hauptlauf: **56 PASS**; danach zusätzliche Settings-/Persistenz-
  /Widerrufstests: **23 PASS** in den beiden betroffenen Testdateien. Diese
  Zusatztests sind auch im abschließenden Gesamtlauf enthalten.
- Reale Wörterbuchdaten geprüft: cat, coração (NFC und NFD), oxigênio;
  Enthaltung bei bank, arrives, went, fui, banana, do/na und akzentlosem coracao.
  Äquivalente Datensätze, Mehrfachsinne in einer Glosse, Einschränkungen und
  maximale Ergebnismenge separat geprüft. Keine Testwort-Sonderregel im Produkt.
- Widgettests: Pack-/Cachevorrang, unbekannte/abgelehnte Freigabe, keine Anfrage
  ohne Wort-Tap, technische Cache-/Wörterbuchfehler, fehlende Verbindung,
  Limit/Anbieterfehler ohne Retry, keine Downloadoberfläche, Quellen/Lizenz,
  bewusste Satzaktion, verspätete Antwort nach Auswahlaustausch.
- Datentests: acht parallele gleiche Wort-Taps = ein Remoteaufruf; genaue zweite
  Wortstelle, neue Sprache und anderer Kontext getrennt. Zustimmung über echte
  SQLite-Datei/Neustart, Konten-/Vertragsversionstrennung, frühere Einzelanfrage
  ohne dauerhafte Freigabe, Widerruf während Tokenbeschaffung ohne HTTP-Client,
  späte Antwort nach Widerruf, korrupter Cache und fehlgeschlagenes Speichern.
- Backend lokal/synthetisch: **31 PASS**, bestehende Sprach-/Auth-/Budgetgrenzen,
  Cacheclaims und Parallel-Deduplizierung; keine Anbieter-Liveanfrage.
- Stage-Verify **PASS**: 22 Tabellenzählungen, Original-Pack 26.198.016 Bytes,
  SHA-256 b85793932825a22e92ac744a42255e9f333acd35809aaba46edb5a395f099bdb.
- Flutter analyze: nur bestehendes `avoid_print` in
  test/data/baseline_adoption_pack_test.dart:43; keine neuen Befunde.
- iOS Profile und Android Debug erfolgreich gebaut. Pluginregistrierungen und
  Abhängigkeiten ohne device_translation; Android-Dex-Prüfung ohne Klassen unter
  de/sprachapp/device_translation oder com/google/mlkit/nl/translate.
- iPhone von Claus: normales Profile-Update installiert und gestartet, gleiche
  Bundle-ID und bestehende private Supabase-defines. Keine Deinstallation,
  automatisierten Lernaktionen, Modelldownloads oder kostenpflichtigen Livecalls.
  Nutzer bestätigt: neuer Ablauf sichtbar, Einstellung vorhanden, keine
  Modelldownloadoberfläche. **UI-Geräteabnahme durch Nutzerbeobachtung**;
  keine Behauptung einer echten Haiku-Qualitäts-/Kostenabnahme. Kein Android-Gerät.
- Vor-/Nachvergleich der lesend kopierten user.db-Dateien: alle elf Nutzertabellen
  zeilengleich, insbesondere 76 user_cards, 78 review_log, 5 Kontexte, 5 Story-Adds,
  7 Storyquellen und 5 learning_identity_bindings. Keine privaten Zeilen ausgegeben.
- Zwischenbefunde: neuer gleichnamiger „Übersetzen“-Button verlangte einen auf das
  Sheet begrenzten Test-Finder. Neue Einstellung verschiebt den Motivschalter;
  Test scrollt ihn jetzt sichtbar und pumpt den Layout-Frame vor dem Tap.
  Ein erster Scrollversuch ohne diesen Frame scheiterte; zweiter gezielter Versuch
  bestanden, danach vollständige Suite grün. Keine gelockerten Assertions,
  keine erhöhten Timeouts. Bestehende Fontmeldungen nur im Widgettest.

## Klicktest und Beispiele

1. Ohne Cloudfreigabe `cat` in einem importierten englischen Satz antippen:
   „Katze“ aus dem Wörterbuch; `coração` entsprechend „Herz“. Quellen öffnen.
   Bestehender geprüfter Packtext oder genauer privater Treffer hat Vorrang.
2. `bank` in Geld-/Flusskontext oder `arrives` antippen: keine willkürliche lokale
   Auswahl. Ohne Einwilligung erscheint der einmalige Aktivierungshinweis.
   „Nicht jetzt“ speichert die Ablehnung. Danach Aktivierung nur über Einstellungen.
3. Bewusstes Aktivieren erlaubt künftige automatische kostenpflichtige Wort-
   übersetzungen; bei Aktivierung im offenen Wortdialog auch den gerade gewählten
   Fall. Dies ist **kein** kostenfreier Prüfweg. Danach zeigt ein Tap dezenten
   Ladezustand und eine validierte deutsche Antwort, ohne weiteren KI-Knopf.
4. In Einstellungen ausschalten: lokale Pack-/Cache-/Wörterbuchtreffer bleiben,
   neue unklare Wörter lösen keine Cloudanfrage aus. Ganzer Satz: „Übersetzen“
   bleibt explizit mit Übertragungshinweis, ohne Geräte-/Modellvorbereitung.

Nicht abgedeckt: sämtliche Wörter/Sinne, zuverlässige deutsche Flexion aus
allgemeinen Wörterbuchdaten oder garantierte regionale Vollständigkeit. Bei
arrives/went/fui bleibt daher Haiku mit exaktem Satz und tatsächlicher Wortform
nötig, sofern keine geprüfte/cachegespeicherte Übersetzung existiert.

## Schnittstellen für das Folgepaket

`OfflineDictionary.lookup` und `singleDictionaryTranslation` liefern reine
Anzeigehilfen. `RuntimeTranslationSheet.wordTap` kennzeichnet den Nutzerimpuls;
`wordCloudConsent`/`setWordCloudConsent`/`translateWordOnTap` kapseln Freigabe und
Anfrage. Bestehende `TranslationRequest`-Identität und Story-Add/Resolver bleiben
unverändert. Import → Lernkarte braucht weiterhin eine gesonderte validierte
Sense-/Form-/Kontextbindung; keine der Anzeigeantworten erzeugt sie automatisch.

## Abschließende Graphprüfung

`detect_changes(scope: all)` nach erfolgreicher Neuindizierung: 28 Symbole,
43 Dateien, 117 zugeordnete Abläufe; weder partial noch truncated. Rohbewertung
`critical` bleibt als Werkzeugbefund dokumentiert. Alle 117 Abläufe enthalten
jedoch die Markdown-Section `Architecture` mit leerer Symbol-ID; nur einer
enthält zusätzlich ein echtes geändertes Codesymbol (`RuntimeTranslationSheet`).
Die Zuordnung einer Dokumentüberschrift zu ausführbaren Schritten ist kein
belastbarer Aufrufnachweis. Gezieltes `context` bestätigt Sheet → Reader/Text-
Exercise/Tests und RuntimeClient → Provider/Cache/Tests. Beim CachedClient bleibt
die dokumentierte Interface-/DI-Grenze (lower-bound); deshalb keine Behauptung
einer vollständig bewiesenen Reichweite. Die vollständige Flutter-Suite,
Cache-/Consent-/Reader-Regressionen und beide nativen Builds dienen zusätzlich
als praktische Absicherung. Letzter Android-Build: erfolgreich, 10,8 Sekunden.

Wiederholung nach Vormerken dieser Dokumentation: 23 Symbole/210 Abläufe,
weiterhin critical und vollständig geliefert. Auch hier lauten sämtliche
Prozess-Schrittnamen ausschließlich `Architecture` oder `RuntimeTranslationSheet`.
Die wechselnden Zuordnungszahlen trotz unverändertem Quellcode unterstreichen
die Graphgrenze; dies ist ausdrücklich kein grüner Graph-Risikobefund.
