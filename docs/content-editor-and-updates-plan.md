# Lokaler Inhaltseditor und sichere Inhaltsupdates

**Zur Abnahme, noch nicht implementiert.** Planungsstand 16.10.2026. Enthält die Ergänzung zu mehreren Lernsprachen, extern vorbereiteten Stapeln, Tabellenansicht sowie ZIP-/XLSX-Austausch. Keine neuen Kategorien oder echten Sprachinhalte werden mit diesem Plan erzeugt.

Der verbindliche technische Entwurf steht im [Editorvertrag](content-editor-contract.md). „Vorhanden“ bezeichnet gelesenen Code; „geplant“ bezeichnet eine Entscheidung für die Umsetzung. Es folgen genau **Paket 2 – Dashboard** und **Paket 3 – Veröffentlichung und App-Updates**. Keine Cloudfreigabe ist erfolgt.

## 1. Ziel und Architekturentscheidung

Der Hauptweg ist **Vorlage und Authoring-Kontext exportieren → extern vorbereitete Lieferung importieren → Tabelle prüfen und korrigieren → Details annotieren → lokal versionieren → später authentisiert veröffentlichen**. Einzelanlage ergänzt diesen Weg.

Geplant sind eine deutschsprachige Oberfläche aus HTML, CSS und JavaScript-Modulen ohne Frontend-Buildsystem und ein Python-Dienst auf `127.0.0.1`. Er verwendet die vorhandene Pipeline als Bibliothek. Der Dienst hält Entwürfe als versionierte JSON-Dokumente; SQLite bleibt ein daraus erzeugtes Distributionsartefakt. Ein freigegebener `pack.json` samt Registry, Prüfbericht und Manifest ist der eingefrorene Release-Eingang. Cloudspeicher verteilt genau diese unveränderlichen Artefakte, er wird kein zweiter redaktionell beschreibbarer Inhaltsmaster. Die allgemeinen Cloud-Master-Aussagen in `ARCHITECTURE.md`/`docs/backend.md` beschreiben noch keine bestehende Veröffentlichungslösung; diese Konkretisierung ist Teil der Abnahme.

Jede Lernsprache erhält eigene Entwürfe, Registry, Releasefolge, Packs und Veröffentlichungszeiger. Die Übersetzungssprache wird separat geführt, zunächst ausschließlich `de`; bestehende `*_de`-Felder werden nicht umbenannt. Eine neue Sprache darf ohne Sprachadapter als Entwurf existieren, aber weder einen lernfähigen Pack noch eine Veröffentlichung vortäuschen.

Paket 2 muss vollständig ohne Cloud funktionieren. Es enthält die kleinen notwendigen Änderungen an Python- und Dart-Inhaltslesern für den neuen Inhaltsvertrag, damit lokaler Export und Staging tatsächlich überprüfbar sind. Paket 3 ergänzt Authentifizierung, private Verteilung, mehrere installierte Packs und sichere Aktivierung. Ein nach Paket 3 ausgelieferter App-Build versteht diese Verträge; spätere kompatible Inhaltskorrekturen brauchen keinen neuen Build. Neue Sprachalgorithmen oder unbekannte Schemas können weiterhin einen App-Build benötigen.

## 2. Verifizierter Istzustand und Arbeitsgrenze

[verified] Grundlage ist Branch `codex/story-single-sentence-v1`, HEAD `c6cee53fe7be07b323bd60608c825ac59c962cd4`. Bereits vorhandene Änderungen an `NEXTSTEPS.md`, vier Übungsoberflächen-Dateien und drei UI-Tests sowie fremde unversionierte Dateien bleiben außerhalb des Plan-Commits. Keine echten Nutzerdaten wurden geöffnet. Die beiden Plandokumente waren neu.

[verified] Der manifestgebundene Bestand ist `story_single_sentence_v1`, Sprache `en`, Schema 4, 22 Tabellen, 26.198.016 Bytes, SHA-256 `b85793932825a22e92ac744a42255e9f333acd35809aaba46edb5a395f099bdb`. Quelle: `pipeline/out/story_single_sentence_v1/pack.json`, erzeugte SQLite daneben; Asset: `assets/content/en/content.sqlite`. 3.768 Karten, davon 3.767 aktiv; 4.297 Karten-Satzlinks, davon 530 historisch. `internal_test_pack=true`. Aktuelle Manifestprüfung siehe Abschnitt 11.

[verified] Wichtige Grenzen:

- `pipeline/scripts/import_editorial_patch.py::create_content` akzeptiert Lieferformate 2/3, kontrolliert Quell-/Registryhash, Besitz, Ref-Kollisionen, vollständige Annotation, Satzreviews und Alternativsätze. Das ist kein allgemeiner Änderungsimporter. Format 3 verbietet neue Bindungen an alte feste Sätze/Tokens.
- `pipeline/src/sprachpipe/curate.py::apply_targeted_patch` unterstützt gezielte Schema-4-Operationen, aber Satzersatz nur mit **neuer, noch nicht vorhandener Satz-ID**. Er fügt kein neues Begleitvokabular hinzu. Rückstellung ist auf einen Singleton ohne aktive Besitz-/Deck-/Form-/lexikalische Bindungen oder fremde aktive Satzverwendung begrenzt.
- `ids.py::stable_id` bindet bestehende Sätze an Sprache und englischen Text, nicht an Übersetzung oder Tokenannotation. Eine reine Übersetzungsänderung unter derselben ID würde alte Reviews umdeuten. Das heutige `sentence_tokens` hat keine unabhängige Kontextglosse.
- `ContentPackInstaller.install` lädt das Asset und ersetzt die lokale Datei bei abweichendem Hash. Es gibt keinen Download, keinen Releasezeiger und keine Bevorzugung eines neueren installierten Packs. Ein bloß zusätzlich heruntergeladenes Pack würde beim nächsten Assetabgleich wieder ersetzt.
- `RepositoryOwner.acquire` verwaltet Leases und eine Close-Barriere; `DeckSessionController.start` initialisiert seinen Resolver einmal und hält Durchgangssnapshots. Das ist eine Grundlage, noch kein explizites generationsgebundenes Updateprotokoll.
- Historische Texte werden über `DriftContentRepository.historicalSentence`, lokale Storykontexte über unveränderliche `card_contexts` gelesen. Die dokumentierten **137 alten Provenienzlücken** werden nicht als repariert ausgegeben. Neue Releases dürfen keine weiteren erzeugen.

## 3. Funktionszuordnung: Wiederverwendung und tatsächliche Lücken

| Gewünschte Funktion | Vorhandener Einstieg, belegte Grenze | Kleinste geplante Erweiterung |
|---|---|---|
| Vollständige Stapel-/Zielliste | `pack.py::build_rows`, `DriftContentRepository.deckPracticeTargets`; Roh-Deckmitgliedschaft allein bildet Formziele/Gruppen nicht ab | Abgeleitete Editorprojektion mit aktiven/historischen Zielen, Owner, Gruppe und Formfunktion; keine zweite Datenbank |
| Neuer Stapel und neue Ziele | `create_content`, `authoring_context.py::validate_context`, `word_registry.py::validate_selection`, `form_targets.py::validate_form_selection` | Gemeinsame Authoring-Service-Funktionen für Entwürfe/Import; v2/v3 bleiben Adapter; neue v4-Lieferung erlaubt unvollständige Entwürfe |
| Satzersatz mit vorhandenem Begleitvokabular | `apply_targeted_patch`, `annotate_local`, `tokenize`; exakte Bindungen nötig | Atomare Satzrevision, explizite Annotation, vorhandene Sense-Kandidaten |
| Satzersatz mit neuem Begleitvokabular | `annotation_catalogue` kann explizite neue Lemmas/Senses/Formglossen ergänzen; targeted kann das nicht | Ein atomarer Änderungsplan: Vokabularaddition und Satzrevision gemeinsam validieren; nicht zwei unabhängig freigegebene Teilimporte |
| Nur Satzübersetzung ändern | Alte Satz-ID bleibt bei gleichem Text gleich | Schema-5-Satzrevision mit neuer ID im neuen Namespace, alte Satz-/Token-/Linkzeilen erhalten |
| Nur Lösungshinweis ändern | `card_gloss` schreibt `cards.translation_de` | Dieselbe fachliche Operation mit Karten-Fingerprint; keine Sense-/Wörterbuchänderung, keine neue Lern-ID |
| Ein Token im Kontext anders übersetzen | `_tokens` liest derzeit verknüpfte Karten-/Dictionaryglossen | Revisionsgebundener Token-Glossensnapshot; expliziter Override verändert nur diesen Kontext |
| Geteilte Glosse korrigieren | `senses.gloss_de` und `dictionary_forms.gloss_de` sind gemeinsam genutzt | Wirkungsliste und gesonderte globale Bestätigung; alte Kontextsnapshots bleiben erhalten; Bedeutungswechsel erzeugt neue Sense |
| Lücke/Alternativen | `tokenize(lexical_spans=...)`, `gap_offsets`, `_valid_alternatives`, `evaluateAnswer` | Auswahl über Offsets und Text-Hash; Alternativenreview an Satzrevision und Lücke binden; kein Synonym wird zur Zielantwort |
| Gebundene Karte zurückstellen | targeted lehnt aktive Owner-/Form-/Gruppenbindungen ab | Geprüfter Retirement-Plan mit vollständigen abhängigen Bindungen; kein pauschales Löschen und keine SRS-Übertragung |
| Mehrere hundert Ziele importieren | `export_authoring_context.py`, v2/v3-ZIPs, `prepare_continuation`; normaler Kontext maximal 1.500 Ziele, Batch maximal 100 und derzeit gemischte Themen | Gesamte Lieferung vorab inventarisieren, interne Chunks ≤100, atomarer Gesamtentwurf; thematischer Editorstapel braucht explizite Authoring-Policy statt künstlicher Themenmischung |
| Wiederholter Import | Quell-/Registryhash und Ref-Kollisionen, aber kein Dashboard-Importjournal | Lieferungs-ID + kanonischer Payloadhash + stabile Datensatzrefs, idempotente Belege; Korrekturen mit eigener ID und Preconditions |
| Alte lokale Storykarten | `StoryContextCorrectionSource/Store`, `applyStoryContextCorrections`, `PracticeCatalog.load` | Kumulativer Korrekturverlauf auch bei übersprungenen Releases; exakte Identitäts-/Herkunftsprüfung behalten |
| App-Updates | `ContentManifest.parse`, `validateContentSchema`, `stageContentPack`, Installer/Provider | Private Release-API, gestreamter Download, unveränderliche Generationsdateien, atomarer Zeiger und Session-Barriere |

Keine dieser Erweiterungen ist mit dem Plan bereits implementiert. Fachliche Prüfung bleibt in der Pipeline. Browser, XLSX-Adapter und HTTP-Handler erzeugen nur denselben normalisierten Arbeitsauftrag; sie bekommen keinen zweiten Satz-/Besitzvalidator.

## 4. Sprachfähigkeit: Datenmodell ist noch keine Sprachunterstützung

| Bereich | Verifizierter Stand | Geplante Grenze |
|---|---|---|
| Identitäten und Besitz | `ids.py` verwendet `lang` direkt oder über Eltern-ID; `LearningIdentity`, Lerngruppen und Formindizes sind sprachbezogen | Für bestehende IDs Algorithmus einfrieren. Alle Editorindexschlüssel und Dublettenchecks enthalten Sprache; keine Zusammenführung nach Oberfläche |
| Tokenisierung/Satzgrenzen | `annotate.tokenize` ruft standardmäßig `linter._nlp()` → `en_core_web_sm`; Storyprüfung nutzt ebenfalls dieses Modell | Registrierter, lokal verfügbarer `LanguageProfile` pro Sprache; kein englischer Fallback für unbekannte Sprache |
| Normalisierung | Python `form_norm`: NFC, lower, Apostrophersetzung; Dart hat eigene Inhalts-/Antwortnormalisierung; `_tokens` verwendet für alte Dictionary-Lookups sogar SQLite-`lower(surface)` | `legacy-v1` für bestehende englische Identitäten unverändert; neue Sprachprofile brauchen Python/Dart-Golden-Tests, etwa kombinierte Zeichen und sprachspezifische Großschreibung |
| Formen | `form_targets.FUNCTIONS`: `base`, `past`, `past_participle`; drei zugehörige Verbansichten; Dart-Validator, `StoryLearningCandidate.validationProblem` und SQL-CHECKs in `user_database.dart` begrenzen dieselben Codes | Diese englischen Kategorien nicht automatisch auf andere Sprachen anwenden; andere Profile deklarieren geprüfte Funktionscodes separat |
| Antwortprüfung | `answer_check.dart`: Normalisierung, Diakritikaoption, Alternativen, falsche Form, Tippfehler; kein Sprachparameter, Distanz arbeitet mit UTF-16-Codeeinheiten | Profilwahl pro Session; englisches Verhalten bewahren, sprachabhängige Regeln und Graphemtests explizit prüfen |
| Häufigkeit/Linter | `wordfreq` bekommt `lang`, POS/Teilsätze/Satzschluss und Wortzählung stammen aber aus englisch geprägter Logik | Frequenzquelle/Version/Schwellen sowie Token-/Satz-/Längenregeln je Profil; fehlende Prüfung ist „nicht unterstützt“, niemals „bestanden“ |
| Authoring/Staging | Ein Pack hat eine Sprache; heutiger Kontext-Exporter liest fest `assets/content/en/...`; Staging hat `lang`-Parameter | Ausgewählte Sprache bis in Kontext-, Registry-, Build- und Staging-API durchreichen; getrennte Quellbindungen |
| Installation/Lernstand | Installer unterstützt Pfad mit `lang`, Provider verwenden standardmäßig Englisch, Userprovider explizit `lang: 'en'`; eine gemeinsame `user.db`, viele Tabellen besitzen `lang` | Paket 3: Contentowner je Sprache/Generation, ein gemeinsamer UserDatabase-Owner, sprachbezogene Repository-Fassaden und Query-Grenzen; kein Kopieren englischer Lernstände |

Sprachenverwaltung bietet Code, Anzeigename, Übersetzungssprache und Status „Entwurf / Sprachfunktionen fehlen / geprüft“. Code wird als kanonischer BCP-47-Tag gespeichert und nach erster Referenz nicht umbenannt. Ein passender Adapter muss explizit registriert sein; Länder-/Schriftvarianten erben nicht still einen anderen Adapter. Initial bleibt nur das heutige Englischprofil für Freigaben vorgesehen. Eine zusätzliche synthetische Testsprache dient später allein Isolationstests, nicht als echtes Inhaltsangebot. RTL, nichtlateinische Schriften, Segmentierung ohne Leerzeichen und Antwortvergleich gehören zu den Freigabenachweisen eines künftigen Profils.

## 5. Bedienung und Zustände

### Einstieg und Tabellenansicht

Links: Sprachauswahl mit getrenntem Hinweis „Übersetzungen: Deutsch“, Stapelliste und Entwürfe. Hauptbereich: Suche; Filter „alle / unvollständig / technische Fehler / redaktionell offen / Konflikte / zurückgestellt“; Aktionen „Vorlage + Kontext“, „Lieferung importieren“, „Ziel ergänzen“. Eine Zeile pro **Lernziel**, nicht pro Schreibweise. Bei Formstapeln ist die Funktion sichtbar; Wiederverwendung zeigt den vorhandenen Eigentümer.

Pflichtspalten: Zielwort/Ausdruck, Lösungshinweis (DE), Satz (gewählte Lernsprache), Satzübersetzung (DE), technischer Status, redaktioneller Status. Sortierung und Zeilennummer sind reine Anzeige. Zellen für Lösungshinweis/Satz/Übersetzung lassen sich gezielt bearbeiten; Identitäten/Funktionen/Owner nur im Detail mit Folgenvorschau. Paginierung zu 100 Zeilen, Suche/Filter im Dienst, Import-/Validierungsjobs mit Zähler „verarbeitet N von M“. Statusmeldungen nennen immer das Gesamtergebnis, nicht nur die aktuelle Seite.

### Detailansicht (schematisch, keine echten Inhalte)

```text
Sprache: Englisch     Stapel: [Titel]     Entwurf gespeichert · Revision 12
Ziel [Ausdruck]       Bedeutung [ausgewählte Bedeutung]       Form [Funktion]
Lösungshinweis (DE)   [................................................]
Satz                 [Text; Wort oder zusammenhängenden Ausdruck auswählen]
Satzübersetzung (DE) [................................................]
Lücke                [gewählte Textstelle] · genau ein Vorkommen erforderlich
Tokenbereich         [Wort] [Wort] [Wort]  → Bedeutung / Formglosse / Kontextglosse
Alternativen         [Alternative] → vollständiger eingesetzter Satz · Prüfung offen
Technisch: 2 Fehler  | Redaktionell: offen | [Vorher/Nachher]
[Entwurf speichern] [Prüfen] [Redaktionell bestätigen] [Zurück zur Tabelle]
```

Alltagseingaben sind Texte und nachvollziehbare Bedeutungs-/Formauswahlen. IDs sind kopierbare technische Details, keine Pflichtfelder im normalen Editor. Vorschläge kommen nur aus dem ausgewählten lokalen Sprachbestand. „Neue Bedeutung“ verlangt Lemma, Wortart, Definition, Glosse und eine ausdrückliche Entscheidung zur Gruppe/Einführung; kein automatisches Ableiten aus der deutschen Übersetzung.

### Konkrete Abläufe

1. **Lieferung:** Sprache/Stapel wählen, Vorlage samt lokalem Bedeutungs-/Besitzkontext exportieren und extern ausfüllen lassen. ZIP/JSON oder XLSX hochladen; Vorschau gruppiert neu, bereits vorhanden, widersprüchlich, unvollständig. „Als Entwurf übernehmen“ verändert keinen gültigen Pack. Anschließend zwei Sätze und einen Lösungshinweis in der Tabelle korrigieren; Detailprüfung markiert betroffene Tokens/Alternativen neu. Vollständige Prüfung und redaktionelle Bestätigung erlauben lokalen Export.
2. **Satz/Übersetzung korrigieren:** bestehende Karte öffnen; geänderten Satz tokenisieren, Lücke auswählen; sichere unveränderte Bindungen als Vorschläge erhalten, unklare markieren. Übersetzungsänderung allein benötigt ebenfalls eine neue Kontextrevision. Vorher/Nachher enthält Satz, Tokens, Lücke und Alternativen.
3. **Nur Lösungshinweis:** Feld ändern; Anzeige erklärt „Hinweis dieser Aufgabe“. Karten-ID, Sense, Wörterbuch und SRS bleiben gleich. Nur der betroffene Reviewbereich öffnet sich erneut.
4. **Kontextübersetzung:** Token anklicken, Kontextglosse ändern oder explizit andere Sense wählen. Die aktuelle Formübersetzung und global geteilte Glosse werden getrennt angezeigt. „Geteilte Glosse korrigieren“ öffnet eine Wirkungsliste und ist eine eigene bestätigte Operation.
5. **Neues Ziel/mehrere Ziele:** vorhandene Identitäten zuerst anbieten. Neue Bedeutung/Funktion erhält neue Lernidentität, auch bei gleicher Schreibweise. Zugehörigkeit zu bestehendem Lernziel ist Wiederverwendung, keine neue Karte; gewöhnlicher Wortbesitz bleibt eindeutig. Neuer Stapel kann leer/unvollständig gespeichert werden; mehrere Ziele bevorzugt über Lieferung.
6. **Zurückstellen:** Folgenvorschau nennt Gruppenprimärkarte, Owner, Formmitgliedschaften und geteilte Kontexte. Singleton kann direkt vorgeschlagen werden; gebundene Karte verlangt geprüfte Neuordnung oder Rückstellung ihrer abhängigen Übungsbindungen. Keine beiläufige Wahl einer Ersatzbedeutung. Tombstones erhalten Historie; betroffene lokale Storyidentität wird weiterhin von aktiver Auswahl ausgeschlossen.
7. **Neustart/verwerfen:** letzte bestätigte Entwurfsrevision lädt wieder. Nicht bestätigte Browsereingaben werden als ungespeichert angezeigt. Verwerfen entfernt nur den Entwurf bzw. setzt ihn auf seine Basis zurück; bereits erstellte Releases bleiben unveränderlich.
8. **Version/Publikation:** „Prüfen“ erzeugt einen Bericht, „Version erstellen“ einen lokalen Release, „Veröffentlichen“ erst in Paket 3 einen privaten Kanalstand. Eine Importdatei mit angeblichen Reviews ist zunächst redaktionell offen. Kein automatisches Publizieren nach Import oder Export.

Ladezustände erhalten vorhandene Zeilen, blockieren nur kollidierende Aktionen und zeigen Fortschritt. HTTP-/Schreibfehler erhalten den letzten gespeicherten Entwurf; ungespeicherte Eingaben bleiben sichtbar. Bei Basis- oder ETag-Konflikt erscheint ein dreiseitiger Vergleich, kein Last-write-wins. Fehler werden mit Datei, Blatt/Zeile oder Datensatz und Feld gezeigt. Technische Gültigkeit und redaktionelle Freigabe haben eigene Textlabels; Farbe ist nur zusätzliche Information. Tastaturzugang, sichtbarer Fokus, beschriftete Felder, Screenreader-Fehlerverknüpfung und mindestens 44-px-Aktionsflächen folgen `DESIGN.md`; keine extern geladenen Schriftarten nötig.

## 6. Vertragsentscheidungen mit besonderer Tragweite

### Satzrevisionen und Schema 5

Eine bloße Schema-4-Glossenänderung reicht nicht. Geplant ist ein **additives Schema 5**, weiterhin alle bisherigen Tabellen plus eine Tabelle `story_context_corrections`. Satzrevisionen bekommen zusätzliche Metadaten und einen neuen ID-Namespace; bestehende ID-Schlüssel bleiben unverändert. Tokens erhalten eingefrorene Kontextglossen. Der genaue Vertrag steht im Begleitdokument. Das ist erforderlich für reine Satzübersetzungsänderungen und unabhängige Tokenübersetzungen bei historisch lesbaren Reviews.

Der erste Schema-5-Build übernimmt alle alten IDs und füllt Glossensnapshots aus dem bisherigen Readerverhalten. Ein Readback vergleicht die sichtbaren historischen Texte und Glossen vor/nach Migration. Neue Satzrevisionen erhalten neue Token-/Link-IDs; alte Zeilen bleiben lesbar. Bedeutungs-/Funktionswechsel sind neue Lernidentitäten, kein Update mit Lernstandsübernahme. Vorhandene, unvollständig rekonstruierbare Althistorie wird separat ausgewiesen und nicht erfunden.

Kumulative Storykorrekturen speichern jede bisherige und neue gültige Kante sowie belegte Ausgangskandidaten je Freigaberevision. Derselbe Kontext aus unterschiedlichen Erzeugungsreleases braucht getrennte exakte Fingerprint-Preconditions; der Vertrag beschreibt diese Fälle ausdrücklich. Ein Client, der Releases überspringt, verarbeitet die eindeutige Kette mit den bestehenden Herkunfts-/Fingerprint-Preconditions. Unbekannte alte Kontexte bleiben unverändert. Keine globale Migration aller lokalen Storykarten anhand der Schreibweise.

### Große Importe und Austausch

ZIP mit JSON, Schema, Anleitung und Authoring-Kontext ist der vollständige Austauschweg. XLSX erhält Detailblätter für Tokens, Lücken, Bedeutungen, Alternativen und Herkunft; ein Einfachblatt kann als unvollständiger Entwurf importiert werden. Der Vertrag definiert die verlustfreie Abbildung und den Umgang mit unbekannten Spalten. Importe führen niemals mitgelieferten Quellcode oder Makros aus.

Vorhandene normale Authoring-Auswahl: maximal 1.500 Ziele, maximal 100 pro Batch; die bisherige Themenmischungsprüfung darf einen Themenstapel nicht zu erfundenen Kategorien zwingen. Paket 2 führt dafür eine explizite `editor-deck-v1`-Policy ein, welche technische Chunkgrenzen von Lernreihenfolge und Themenmischung trennt. Legacy-Authoring behält seine bisherigen Regeln. Formauswahlen haben ihren eigenen vollständigen Batch-/Reuse-Vertrag; dieser wird nicht durch Aufteilen nach Oberfläche ersetzt. UI zeigt erwartete, verarbeitete, blockierte und bestätigte Gesamtmengen. Ein teilweise validiertes Lieferobjekt ist niemals ein gültiger Release.

### Lokaler Betrieb

Geplanter Start nach Paket 2, aus dem Repository, ohne Cloudzugang:

- macOS (Terminal): `pipeline/.venv-macos/bin/python -m sprachpipe.editor`
- Windows (PowerShell, eingerichtete Pipeline-venv): `pipeline\.venv\Scripts\python.exe -m sprachpipe.editor`

Der Dienst öffnet einen lokalen Browser mit einmaligem Bootstrap-Token, bindet nur `127.0.0.1` an einen freien Port und akzeptiert ausschließlich den tatsächlich gebundenen Host/Port. Sitzungs-Cookie, Originprüfung und CSRF-Header schützen Schreiboperationen; Details im Vertrag. Alle Entwurfs-/Upload-/Exportpfade sind serverseitig aus UUIDs abgeleitet. Browseranfragen enthalten keine Shellbefehle, Projektpfade oder frei wählbaren Ausgabeziele. Ein Worker serialisiert Mutationen; lange Validierung läuft außerhalb des HTTP-/UI-Threads. Standarddatenverzeichnis außerhalb des Repos; kein automatisches Schreiben in Assets.

## 7. Veröffentlichung und sichere App-Aktivierung

[verified] Vorhanden sind Supabase-Migrationen für `content`/`app`, lokale Auth-Konfiguration und nur `supabase/functions/health/index.ts` als Funktionsdatei. `20261003000004_storage.sql` legt **öffentliche** Buckets `audio`/`packs` und einen privaten `imports`-Bucket an. Das erfüllt den Testerbedarf nicht. `pubspec.yaml` und `lib/` enthalten keine implementierte Supabase-Anmeldung. Lokale Konfiguration: Auth aktiviert, Signup aktiviert, E-Mailbestätigung aktiviert, Site-URL localhost; ein lokaler Projekt-Linkmarker existiert. Daraus folgt keine Aussage über Erreichbarkeit, Migrationen, Benutzer oder Policies eines echten Cloudprojekts.

Geplant: neuer privater Bucket `content-private`; separat administrierte Leser- und Herausgeberrechte, E-Mail-OTP für eingeladene Tester und Publisher. Flutter erhält ausschließlich Leserzugriff. Dashboard-Browser erhält keine Supabase-Schreibcredentials; Publikationsanmeldung erfolgt über den lokalen Python-Dienst/Terminal, Tokens bleiben serverseitig im Arbeitsspeicher. Kein service-role-Schlüssel auf Entwicklergerät oder in Flutter. Edge Functions verwenden ihre serverseitige Berechtigung erst nach Prüfung der User-JWT und Publisher-Allowlist.

Ein Release wird zunächst unsichtbar hochgeladen und vollständig geprüft. Die Veröffentlichung ist eine Datenbanktransaktion mit Compare-and-swap auf `(lang, channel, generation, previous_manifest_sha256)`. Nur dann wird der gemeinsame Kanalzeiger umgestellt. Veraltete Publisher erhalten 409 und müssen neu basieren; ein Upload allein ist keine Veröffentlichung. Details zu Uploadgröße, Digestprüfung, Registry-Elternbindung und fehlgeschlagenen Jobs im Vertrag.

In der App werden Packs gestreamt in eine neue unveränderliche Generationsdatei geschrieben. Größe, Hash, Manifest, Sprache, Profilfähigkeiten, Schema, Tabellen und referenzielle/historybezogene Invarianten müssen vor Aktivierung stimmen. Neues Pack wartet, solange ein aktiver Durchgang oder ungespeicherter Review existiert. Am sicheren Übergang werden neue Leases gesperrt, alte Content-Leases geschlossen, Close-Barriere abgewartet, Kandidat geprüft und erst dann der aktive Zeiger atomar geschrieben. Neue Provider sehen anschließend die neue Generation. Die UserDatabase-Verbindung wird weder ersetzt noch geleert. Ein Sprachwechsel benutzt dieselbe Session-Barriere.

Rücknahme bedeutet **neues, höher versioniertes Reparaturrelease auf Basis des aktuellen Standes**, nicht Heruntersetzen des Zeigers auf einen alten Pack. Neuere Lernidentitäten, historische Sätze, Tombstones und Storykorrekturketten bleiben vorhanden; fehlerhafte Aufgaben werden zurückgestellt oder bekommen eine neue Kontextrevision. Ein bereits aktiver Pack mit nachträglich beschädigter Datei darf nur auf einen historienkompatiblen Bestand zurückfallen. Gibt es keinen, bleiben Nutzerdaten erhalten und die App zeigt eingeschränkte Verfügbarkeit samt Reparaturmöglichkeit; ein alter Asset-Pack wird nicht als vollständiger Ersatz ausgegeben.

Sprachpacks werden unabhängig installiert. Eine gemeinsame `user.db` bleibt erhalten, Repositoryabfragen und Aktivitäts-/Tageszielprojektionen werden auf die gewählte Sprache begrenzt. Spracheinstellungen für Lernen werden in Paket 3 sprachbezogen ergänzt; globale Darstellungseinstellungen bleiben global. Für einen laufenden Durchgang bleiben Sprache, Profil, Contentgeneration und Userrepository unverändert.

Externe Voraussetzungen erst in Paket 3: Projektstatus/Region und bestehende Ressourcen durch autorisierten Betreiber prüfen; Migrationen/Functions installieren; privaten Bucket und Größenlimits konfigurieren; direkte öffentliche Zugriffe und Rechteeskalation testen; Publisher/Tester einladen; OTP-Mailzustellung und HTTPS-Endpunkte einrichten; App-URL und öffentliche Projektkennung konfigurieren. Keine dieser Arbeiten wurde hier ausgeführt. Kein öffentlicher Bucket als Zwischenlösung.

## 8. Genau zwei Umsetzungspakete

### Paket 2 – Lokales Dashboard, Dateiimport und geprüfter Export

**Ergebnis:** offline startbarer Editor mit Sprachenentwürfen, ZIP-/JSON-/XLSX-Vorlagen und Kontext, Importvorschau, Tabelle, vollständigem Detailworkflow, Entwurfsspeicherung, technischer/redaktioneller Prüfung und lokalem Release/Staging. Neue Sprachprofile dürfen fehlen; deren Entwürfe bleiben benutzbar, Release bleibt blockiert.

Geplante neue Dateien und Schnittstellen:

| Pfad | Verantwortung |
|---|---|
| `pipeline/src/sprachpipe/editor/__main__.py`, `server.py` | Loopbackstart, statische Dateien, feste HTTP-Routen, Host/Origin/CSRF, Uploadgrenzen |
| `pipeline/src/sprachpipe/editor/store.py`, `jobs.py` | JSON-Revisionen, Lock/ETag, Importjournal, Wiederaufnahme, serielle Jobs |
| `pipeline/src/sprachpipe/editor/service.py` | UI-Projektionen, Commands an gemeinsamen Authoring-Service, keine eigene fachliche Validierung |
| `pipeline/src/sprachpipe/authoring_service.py` | `normalize_delivery`, `preview_import`, `apply_operations`, `validate_draft`, `build_release`; CLI und Dashboard verwenden dieselben Funktionen |
| `pipeline/src/sprachpipe/language_profiles.py` | Profilregister, unterstützte Sprachfunktionen, eingefrorenes Englischprofil, kein Fallback |
| `pipeline/src/sprachpipe/editor/exchange.py`, `xlsx_exchange.py` | ZIP-Containment/Hashes, JSON-v2/v3/v4-Adapter, XLSX-Blattmapping; geplant `openpyxl` als lokale Python-Abhängigkeit |
| `pipeline/src/sprachpipe/editor/web/index.html`, `app.js`, `api.js`, `editor.js`, `table.js`, `styles.css` | Tabellen-/Detail-/Import-/Sprachenansicht, keine Cloudcredentials oder Geschäftslogik |
| `pipeline/data/curation/editorial_content_v4.schema.json` | Vollständiger Liefervertrag; Entwurfsvalidierung getrennt von Freigabe |
| `pipeline/src/sprachpipe/context_revisions.py` | Revisionshashes, Glossensnapshot-Migration, Korrekturketten, Historienabschluss |
| `supabase/migrations/20261017000001_content_context_revisions.sql` | Geplante additive Schema-5-Spalten/Tabelle als Schemaquelle; nur Datei erstellen, in Paket 2 nicht deployen |
| `lib/domain/language_profile.dart`, `lib/data/content/context_revision_validation.dart` | Readerfähigkeiten und Schema-5-Prüfung, reine Domain ohne Flutter |

Gezielt zu erweitern: `import_editorial_patch.py` und `export_authoring_context.py` zu dünnen Adaptern des gemeinsamen Services; `authoring_context.py`, `curate.py`, `pack.py`, `schema.py`, `ids.py`, `export.py`, `content_contract.py`, `word_registry.py`, `form_targets.py` und `linter.py` für die beschriebenen Erweiterungen. `pipeline/pyproject.toml`/Lockfile erhalten nur die beschlossene XLSX-Abhängigkeit und Paketdaten der Weboberfläche. Kein neues JS-Framework.

Dart: `content_database.dart`/`form_content_validation.dart` ergänzen Schema 5, `drift_content_repository.dart` liest Revisionen/Glossensnapshots/Korrekturketten; `story_learning.dart`, `drift_user_repository.dart` und `practice_item_resolver.dart` erhalten nur die notwendigen Korrekturketten- und Historienverträge. `tool/stage_content_pack.dart` behält seine bestehenden Prüfungen und ergänzt Schema-/Historyfähigkeit; Dashboard-Staging schreibt ausschließlich ein neues lokales Releaseverzeichnis, niemals automatisch Assets. Alte Schema-1–4-Packs bleiben lesbar. Noch keine Download-/Loginoberfläche und kein Aufruf einer Cloudfunktion.

**Reihenfolge innerhalb dieses Pakets:** gemeinsames Authoring-/Sprachmodell und Schema-5-Goldens → Draft-/Importservice und Austausch → Browserworkflows → Reader/Stage-Kompatibilität → synthetische End-to-End-Abnahme. Das sind Arbeitsschritte innerhalb eines Pakets, keine weiteren Pakete.

Geplante Tests: `pipeline/tests/test_editor_service.py`, `test_editor_exchange.py`, `test_editor_xlsx.py`, `test_editor_http.py`, `test_language_profiles.py`, `test_context_revisions.py`; `test/data/content_context_revisions_test.dart`, `test/data/editor_stage_test.dart`; bestehende Tests `test_editorial_import.py`, `test_content_contract.py`, `test_authoring_context.py`, `test_normal_schema4_authoring.py`, `test_targeted_curation.py`, `test_story_contexts.py` sowie Dart `stage_content_pack_test.dart`, `targeted_curation_test.dart`, `story_single_sentence_test.dart` gezielt ergänzen.

Abnahme (alle synthetisch, keine echten Lernstände):

- A1: Lieferung mit 250 Zielen importieren, zwei Sätze/einen Lösungshinweis korrigieren, technische Prüfung und Redaktion abschließen, Export/Readback/Stage bestehen. Keine Freigabe bei 100/250.
- A2: Dieselbe Lieferung erneut einlesen → identischer Importbeleg, null zusätzliche Ziele; korrigierte Lieferung gleicher ID → Konflikt statt Überschreiben.
- A3: Zusätzliche Sprache und kleinen synthetischen Stapel anlegen; gleiche Oberfläche wie Englisch bleibt getrennt, fehlendes Profil blockiert Release. Testadapter weist getrennten Export nach, wird nicht produktiv als unterstützte Sprache registriert.
- A4: Fehlerhafte/unvollständige XLSX nennt Blatt/Zeile/Feld, fehlende Einzelwortglossen bleiben speicherbare Entwürfe; gültiger Bestand bytegleich.
- A5: Vollständiger strukturierter Export und vollständige XLSX-Runde behalten Sense-/Formbindungen, Lücken, Alternativen, Herkunft und Referenzen. Neues Importreview ist erforderlich, technische Roundtrip-Gleichheit allein ist keine Redaktion.
- A6: Neustart, zwei Tabs, veraltete Basis, doppelte/mehrfach vorkommende Zielwörter, Mehrwortlücke, kombinierte Unicodezeichen und Surrogatgrenzen sind getestet.
- A7: Reine Satzübersetzung/Tokenkorrektur erhält Lern-ID und alte Reviewdarstellung; aktive Owner-/Form-Rückstellung verlangt vollständigen Plan; alte Storykorrekturen funktionieren auch nach übersprungenem Release.
- A8: Browser-Smoke unter macOS und Windows mit Tastatur, Fokus, Fehlerverknüpfung und laufendem Importjob; Fremd-Origin, manipulierte Hostheader, Pfade und ZIP-Bombs werden abgewiesen.

Geplante Prüfkommandos nach Implementierung, keine Ausführung vollständiger Suiten in diesem Planauftrag:

- macOS: `pipeline/.venv-macos/bin/python -m pytest pipeline/tests/test_editor_service.py pipeline/tests/test_editor_exchange.py pipeline/tests/test_editor_xlsx.py pipeline/tests/test_editor_http.py pipeline/tests/test_language_profiles.py pipeline/tests/test_context_revisions.py`
- Windows: `pipeline\.venv\Scripts\python.exe -m pytest pipeline/tests/test_editor_service.py pipeline/tests/test_editor_exchange.py pipeline/tests/test_editor_xlsx.py pipeline/tests/test_editor_http.py pipeline/tests/test_language_profiles.py pipeline/tests/test_context_revisions.py`
- Beide: `flutter test test/data/content_context_revisions_test.dart test/data/editor_stage_test.dart test/data/stage_content_pack_test.dart test/data/targeted_curation_test.dart test/story_single_sentence_test.dart` und `flutter analyze`.
- Bestehende Import-/Authoring-Regressionsdateien oben mit demselben jeweiligen Python-Interpreter ausführen. Staging synthetischer Kandidaten in temporäre Pfade; abschließend `dart run tool/stage_content_pack.dart --verify` für das unveränderte Asset.

### Paket 3 – Authentisierte Veröffentlichung, mehrere Sprachpacks und Aktivierung

**Abhängigkeit:** abgenommenes Paket 2 einschließlich Schema-5-Reader, Releasebundle, Historienabschluss und Sprachprofil-ID. Cloudbereitstellung ist eine explizite spätere Einrichtung, kein vorausgesetzter Istzustand.

| Geplanter Pfad | Verantwortung / Schnittstelle |
|---|---|
| `supabase/migrations/20261017000002_content_distribution.sql` | Rollenlisten, immutable Releases, Kanalzeiger, Audit, private Bucket-Policies und transaktionale `publish_content_release`-RPC |
| `supabase/functions/content-publish/index.ts`, `supabase/functions/content-release/index.ts` | Publisherprüfung, unsichtbares Upload/Finalize/CAS bzw. Leserprüfung und kurzlebige Downloadberechtigung |
| `pipeline/src/sprachpipe/editor/publisher.py` | OTP im lokalen Dienst, HTTP-Upload/Retry/Status; kein service-role-Token lokal |
| `lib/data/content/content_release_client.dart`, `content_update_service.dart`, `content_install_journal.dart` | Manifestabfrage, Streaming, Wiederaufnahme/Abbruch, Validierung, Dateigenerationen und Crashprotokoll |
| `lib/data/auth/content_auth_repository.dart` | Einladung/OTP, Sessionerneuerung, SDK-/Secure-Storage-Integration |
| `lib/presentation/providers/content_update_providers.dart`, `language_providers.dart` | Sprachwahl, Generationen, Updatezustände und sichere Aktivierungsbarriere |
| `lib/screens/settings/content_updates_screen.dart` | Sprachen/Packs, Login, Update verfügbar, herunterladen, wartet auf Durchgang, Fehler und Retry |
| `test/data/content_update_service_test.dart`, `test/data/language_preferences_migration_test.dart`, `test/content_update_flow_test.dart`, `test/language_isolation_test.dart` | Crash-/Hash-/Kompatibilitäts-/Session-/Sprachtests mit temporären DBs und Fake-Transport |
| `supabase/tests/database/content_distribution.test.sql` | RLS, Authrollen, CAS, Idempotenz, kein Zugriff auf privaten Pack ohne Rechte |

Bestehende Dateien: `content_pack_installer.dart` wird Assetbootstrap plus Generationsöffner; `database_providers.dart` trennt gemeinsamen UserDatabase-Owner von Contentownern pro Sprache/Generation. `deck_session_controller.dart` hält explizite Lease und Session-Sprache. `learning_providers.dart`, `deck_providers.dart`, `story_learning_providers.dart` beziehen Sprache/Generation konsistent; `drift_user_repository.dart` prüft Sprache auch bei ID-basierten Schreib-/Lesezugriffen. `user_database.dart` ergänzt Schema 6 mit sprachbezogenen Lernpräferenzen und ersetzt die festen englischen Form-CHECKs durch strukturelle Nichtleer-Prüfungen; die semantische Funktionsprüfung erfolgt gegen das geprüfte Sprachprofil. Erforderliche Drift-Tabellenmigrationen erhalten jede Karten-/Binding-/Reviewzeile, IDs, Werte, Indizes und Trigger. Vorhandene Lernpräferenzen werden nach `en` übernommen. `preferences_provider.dart`, `preferences.dart` und der Settings-Einstieg trennen globale Darstellung von Sprachpräferenzen. `story_learning.dart`, `answer_check.dart` und `lib/domain/review_pass.dart` bekommen explizite Profilparameter mit identischem englischem Legacyverhalten; Profilgoldens und Schema-5→6-Migrationstest sind Pflicht. `pubspec.yaml`/Lockfile erhalten erst dann passende geprüfte Auth-/Secure-Storage-Abhängigkeiten. Der bestehende Settings-Einstieg bindet den neuen Screen ein.

**Reihenfolge:** private lokale Backendtests und Authverträge → Upload/Finalize/CAS → mehrere Packgenerationen/Recovery → Session-/Sprachintegration → Stagingumgebung mit eingeladenen Testern. Kein Lernstandsync, keine KI, keine öffentlichen Packs, kein Mehrbenutzer-Webeditor.

Abnahme:

- B1: Anonym, nicht eingeladener Nutzer und normaler Tester können nicht publizieren; anonyme Downloads scheitern. Nur autorisierte Leser erhalten passende interne Packs; Geheimnisse fehlen in Browser/Flutter/Logs.
- B2: Zwei Publisher mit derselben Basis: genau einer gewinnt, der andere erhält Konflikt. Gleicher Commit-Request ist idempotent, Uploadabbruch verändert keinen Kanalstand.
- B3: Unterbrechung in jedem Installationsschritt, falsche Größe/Hash/Sprache/Schema/Profil, fehlende Historie und schließende Verbindung lassen den gültigen Stand unverändert. Auch Neustart nach erfolgreichem Update fällt nicht aufs Asset zurück.
- B4: Update während Durchgang/Review-Schreibvorgang wartet. Alter Durchgang, Rückblick, SRS und gespeicherte IDs bleiben gleich; der nächste Durchgang liest die neue Generation.
- B5: Zwei installierte synthetische Sprachen: getrennte Auswahl, Boxen, Tageswerte, Storybindings, Versionen und Updates. Sprachwechsel während Durchgang wartet; ungültiges Pack einer Sprache betrifft die andere nicht.
- B6: Vorwärts-Rücknahme erhält bereits gelernte neue Karten und alte Reviews; übersprungene Storykorrekturen werden deterministisch angewandt, unbekannte lokale Kontexte nicht überschrieben.
- B7: Offline nach Loginablauf bleiben installierte gültige Packs und Lernstände nutzbar; Abmeldung löscht keine lokalen Lerndaten. Neue Downloads benötigen erneut gültige Berechtigung.

Geplante Prüfkommandos: plattformgleich `flutter test test/data/content_update_service_test.dart test/data/language_preferences_migration_test.dart test/content_update_flow_test.dart test/language_isolation_test.dart`, `flutter analyze`; `supabase test db` erst gegen ausdrücklich dafür eingerichtete lokale Testinstanz. Python-Publishertests mit Fake-HTTP: macOS `pipeline/.venv-macos/bin/python -m pytest pipeline/tests/test_editor_publisher.py`, Windows `pipeline\.venv\Scripts\python.exe -m pytest pipeline/tests/test_editor_publisher.py`. Live-OTP/Storage/CAS später mit synthetischen Packs in autorisierter Stagingumgebung separat nachweisen.

## 9. Risiko- und Nachweismatrix

| Risiko | Schutz | Abnahmenachweis |
|---|---|---|
| Lern-ID mit Satz-ID verwechselt | Unveränderliche Lernidentität, separate Kontextrevision | A7: gleiche Karte, neue Satz-ID, alter Reviewtext |
| Globale Glosse verändert viele Kontexte | Wirkungsliste, eigener Command, historische Glossensnapshots | A7: Kontextkorrektur nur ein Token; globaler Diff vollständig |
| Ziel mehrfach / Mehrwortlücke | Vollständige zusammenhängende Tokenauswahl; Wiederholung weiterhin blockiert, keine „erste Fundstelle“ | A6: doppelte Oberfläche, Satzzeichen, Mehrwortspanne |
| Unicode oder Sprache vermischt | Codepointvertrag, UTF-16-Konvertierung, Sprachprofil und sprachbezogene Indizes | A3/A6/B5 |
| Veralteter Entwurf / Reimport | Basis-/Entityhash, ETag, Importjournal, vollständiger Rebase mit Reviewöffnung | A2/A6; kein Überschreiben per Zeilenposition |
| Teilweise Stapelverarbeitung | Gesamtinventar, feste Chunks, Releasegate über alle Datensätze | A1/A4: 100/250 bleibt blockiert |
| XLSX verliert verschachtelte Daten | Detailblätter und explizite Erweiterungsrecords; fehlende Daten nicht raten | A5: kanonischer Roundtripvergleich |
| Abbruch beim Installieren | Immutable Generation, Journal, atomarer Zeiger, Startup-Recovery | B3: Crash an jeder Grenze |
| Aktiver Durchgang wird ersetzt | Sessionlease, Close-Barriere, Aktivierung erst am Übergang | B4 einschließlich Review-Retry |
| Historie nach Ersatz/Rückstellung | Append-only-Kontexte, Tombstones, kumulativer Historienabschluss | A7/B6; bekannte 137 Altverluste separat |
| Alte lokale Storykontexte | Korrekturketten mit exakten Herkunfts-/Fingerprintguards | A7/B6 einschließlich übersprungener Version |
| Veröffentlichung schlägt fehl / Rücknahme | Unsichtbares Staging, serverseitige Prüfung, CAS, neuer Reparaturrelease | B2/B6 |
| Große Packs blockieren UI | Pythonworker, paginierte Tabelle, gestreamter Download, Dart-Isolateprüfung | A1/B3 mit Größenlimit und Abbruch; Messung statt pauschaler Performancezusage |
| Fremde Website schreibt lokal | Loopback, exakter Host, einmaliger Bootstrap, Origin/CSRF, keine CORS-/Pfad-/Shellschnittstelle | A8 mit Cross-Origin-/DNS-Rebinding-Versuchen |
| Neue Sprache nur scheinbar unterstützt | Fähigkeitsgate für Tokenizer, Regeln, Normalisierung, Antworten, Frequenz und Darstellung | A3/B3; unbekanntes Profil explizit blockiert |

## 10. Graphbefunde, Grenzen und Umsetzungskontext

[graph] GitNexus wurde auf diesem HEAD mit `node .gitnexus/run.cjs analyze --index-only --pdg` aktualisiert: 84.884 Knoten, 260.279 Kanten, 392 erfasste Flows. Indexmeldungen weisen auf begrenzte Prozessabdeckung, Dart-Dispatch und Sprachgrenzen hin; fehlender Flow ist keine Entwarnung. Nach einem MCP-Transportabbruch wurde auf die vorhandene CLI gewechselt.

Primäre Anker: `create_content`, `apply_targeted_patch`, `build_rows`, `ContentPackInstaller`, `RepositoryOwner`. Sekundäre Reader/Sprachpfade sind in den Abschnitten 3/4 und Dateitabellen angegeben. CLI-`context` für die exakte `create_content`-UID zeigt den CLI-Einstieg, bestehende Authoringtests und eingefrorene externe Batchprüfer als Verbraucher. Referenzkopien wurden nicht als aktueller Produktionspfad behandelt.

**HIGH-Risikohinweis für Paket 2:** exaktes `build_rows`-Impact meldet HIGH, 10 direkte und 17 insgesamt betroffene Symbole; betroffene Prozessanker sind `cmd_upsert`, `apply_targeted_patch` und `prepare_continuation`. Deshalb gemeinsame Validatoren erweitern, Legacy-Verträge gezielt testen und keine neue unabhängige Exportpipeline schreiben. `riskSharedAxes=MEDIUM` hebt HIGH nicht auf. Installer: LOW, 2 direkte/20 insgesamt; RepositoryOwner: MEDIUM, 11 direkte/18 insgesamt, unter anderem Provider-/Readerverbraucher. Diese Werte sind Momentaufnahmen und vor Codeänderungen erneut zu ermitteln.

[graph + verified] PDG-Slice an `create_content:549` zeigt fünf lokale vorgelagerte Statements; Quelllektüre bestätigt Deepcopy nach Basis-/Registryguards und Ergänzungen vor finalem `build_rows`. PDG-Risiko UNKNOWN ist keine Freigabe. Relevante Reihenfolge aus Source: Preconditions → Arbeitskopie → Ref-/Besitz-/Annotation-/Reviewprüfung → finaler Build → Export; der heutige Export schreibt erst nach Validierung eine temporäre SQLite und ersetzt nach Close. Für Dart-Lifecycle sind Source- und spätere Integrationstests maßgeblich, kein behaupteter vollständiger PDG-Beweis.

Skillkonvention abweichend: Der Nutzer verlangt genau diese zwei Dokumentpfade statt eines generierten `docs/plans/...`-Artefakts. Daher keine zusätzliche Skill-Plandatei und kein vorgetäuschtes Provenienzschema-2-Artefakt. Re-Anker für die Umsetzung: HEAD, tatsächlicher Arbeitsbaum, Manifesthash, nachstehende Quellen und aktuelle Graphprüfung erneut verifizieren. Die neuen Pläne sind keine Codefreigabe.

## 11. Tatsächliche Planprüfung

Lesende Quellprüfung umfasst die geforderten Produkt-/Architektur-/Content-/Backend-/Pipeline-/Gruppen-/Storydokumente sowie die in den Tabellen genannten existierenden Codeeinstiege. Lokale Supabase-Konfiguration wurde nur mit ausgewählten nicht geheimen Feldern ausgewertet; kein Cloudzustand abgefragt.

| Ausgeführter Befehl | Exit / Ergebnis |
|---|---|
| `node .gitnexus/run.cjs analyze --index-only --pdg` | 0, Index aktualisiert, Abdeckungswarnungen wie oben |
| `node .gitnexus/run.cjs context 'Function:pipeline/scripts/import_editorial_patch.py:create_content' --repo .` | 0, eindeutiger aktueller Einstieg |
| `node .gitnexus/run.cjs impact 'Function:pipeline/src/sprachpipe/pack.py:build_rows' --direction upstream --repo .` | 0, HIGH; vorheriger Kurzname war wegen Referenzkopien mehrdeutig |
| `node .gitnexus/run.cjs impact 'Function:pipeline/scripts/import_editorial_patch.py:create_content' --direction upstream --mode pdg --line 549 --repo .` | 0, lokaler Slice, UNKNOWN ausdrücklich nicht als sicher gewertet |
| `node .gitnexus/run.cjs impact ContentPackInstaller --direction upstream --repo .` | 0, LOW |
| `node .gitnexus/run.cjs impact RepositoryOwner --direction upstream --repo .` | 0, MEDIUM |
| `pipeline/.venv-macos/bin/python pipeline/scripts/import_editorial_patch.py --help` | 0, vorhandene Create-/Finish-/Targeted-CLI bestätigt |
| `pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --help` | 0, vorhandene ZIP-/Continuation-CLI bestätigt |
| `pipeline/.venv-macos/bin/python /tmp/sprachapp-editor-plan/probe.py` | 0 nach Korrektur der lokalen Probe; erster Versuch Exit 1 wegen optionalem `removed_in`-Schlüssel, behoben durch `.get`. Keine Produktänderung |
| `dart run tool/stage_content_pack.dart --verify` | 0 nach Freigabe des vorhandenen SDK-Caches; erster Sandboxversuch Exit 1 wegen nicht beschreibbarem `engine.stamp.tmp`/`engine.realm`, kein Packfehler |

Tatsächlicher Stage-Output:

```text
verified assets/content/en/content.sqlite
  version story_single_sentence_v1, schema 4, 26198016 bytes
  sha256 b85793932825a22e92ac744a42255e9f333acd35809aaba46edb5a395f099bdb
  22 table counts match finalization_report.json
  INTERNES TEST-PACK: own devices and selected testers only, no public content release
```

Geschützte Ausgangshashes (vor/nach zu vergleichen):

| Datei | SHA-256 |
|---|---|
| Asset und Quell-SQLite | `b85793932825a22e92ac744a42255e9f333acd35809aaba46edb5a395f099bdb` |
| `assets/content/en/content.manifest.json` | `74a0bce4d16bb3084f762dd6afc69accc44c80db545dba9871b21d0b8c7adbfe` |
| `pipeline/out/story_single_sentence_v1/pack.json` | `313ea762423478c932cb3c92a512ffd07281afed9028a17b9f6ec3a00b7a9aa5` |
| `pipeline/data/curation/story_single_sentence_v1.json` | `be3a8e27b6b919fd51e2ee6e98f49311c2ac03621bdb835b9e35bdb243bf07f5` |
| `pubspec.yaml` | `64557ff410bc64d540c2616874b91e3580dcbdbc08861372c60050a515742fac` |

## 12. Abnahme und offene Entscheidungen

Keine offene Produktfrage blockiert die Umsetzungsvorbereitung. Vorgeschlagene Entscheidungen zur Abnahme: Schema 5 für unveränderliche Kontexte, privater interner Kanal, Deutsch als erste Übersetzungssprache, Englisch als zunächst einzig freigabefähiges Profil, eine gemeinsame sprachgetrennt abgefragte `user.db`, sprachbezogene Lernpräferenzen/Tagesprojektion. Weitere echte Lernsprachen und ihre Regeln werden erst mit einem geprüften Profil freigegeben; die reine Eingabe eines Sprachcodes genügt nicht.

Definition of Done dieses Auftrags: beide Dokumente enthalten Istbelege, konkrete Verträge/Dateipfade, Import-/Sprachenanforderungen und genau zwei Umsetzungspakete; nur Dokumentation geändert; vorgeschriebene Prüfungen und Hashvergleich dokumentiert; nur neue Plandokumente isoliert committed, kein Push. Definition of Done der späteren Pakete sind A1–A8 bzw. B1–B7, nicht die Existenz dieses Plans.

### Abschlussnachweis dieses Planauftrags

Die korrigierte ausschließlich lesende Vertragsprobe endete mit Exit 0:

```text
build_rows: 22 tables; 3768 cards; 3767 active
language-scoped identities: True
same text identity ignores translation: True
token context gloss column: False
tokenizer: en core_web_sm
legacy normalization: 'i̇' 'straße'
schema5 currently: unsupported content schema 5
active sentence links: 3767 historic: 530
```

Geschützte Hashprüfung: `PROTECTED_HASHES PASS count 13` (Assets, Manifest, Quelle, Kuration, pubspec und vorhandene UI-/Teständerungen). NEXTSTEPS wurde ausschließlich in der Standzeile ergänzt und bleibt 25 Zeilen lang; Altinformationen bleiben erhalten und diese Datei bleibt aus dem Commit ausgeschlossen.

`git diff --check -- docs/content-editor-and-updates-plan.md docs/content-editor-contract.md NEXTSTEPS.md` sowie der zusätzliche `git diff --cached --check -- docs/content-editor-and-updates-plan.md docs/content-editor-contract.md` bestehen mit Exit 0 nach der letzten Textänderung. Die Arbeitsdateien haben LF; wegen der bestehenden Repository-CRLF-Konvention besteht außerdem dieselbe gezielte Prüfung mit Exit 0 mit `git -c core.whitespace=cr-at-eol diff --check` ohne persistente Konfigurationsänderung.

Graphprüfung vor Commit: `node .gitnexus/run.cjs detect-changes --scope all --limit 1000 --repo .` erfasst 10 geänderte Dateien/26 bekannte Symbole, Risiko LOW, 0 erfasste Prozesse. Die 26 Symbole stammen aus dem schon vorhandenen UI-Diff und NEXTSTEPS; keine Codefreigabe für diese fremden Änderungen. Der zusätzliche Scope `staged` umfasst nur die zwei neuen Dokumente und meldet korrekt: „Diff touched 2 file(s) but no indexed symbols overlap those hunks — not a clean tree.“ Neue Markdown-Dateien sind nicht als Codesymbole indexiert; daraus wird kein sauberer Arbeitsbaum behauptet. Keine vollständige Testsuite ausgeführt, keine Funktion implementiert, kein Push.
