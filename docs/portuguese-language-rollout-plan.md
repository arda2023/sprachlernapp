# Brasilianisches Portugiesisch: geprüfter Rolloutplan

Stand 18.10.2026, Ausgangscommit `437c9c4`. **Plan zur Abnahme, keine
Implementierungsfreigabe.** Ziel: Deutsch als Oberfläche/Übersetzungssprache,
Brasilianisches Portugiesisch als neue Lernsprache, Stapel „Allgemeine Sprache“.
Erster vertikaler Lauf: 20 manuell redaktionell erstellte Ziele; nach Abnahme
ungefähr 160, keine Auffüllpflicht. Keine automatische Modellgenerierung.

Arbeitsbaum anfangs ausschließlich `?? published-baseline-transfer/`. Dieser
Ordner bleibt unverändert. Gelesen: AGENTS.md, PRODUCT.md, ARCHITECTURE.md,
content-editor-contract, content-editor-and-updates-plan, Paketberichte 2/3,
Published-Base-Adoption, Active-Context-Fix und NEXTSTEPS. Ältere Plantexte sind
nicht als Implementierungsnachweis verwendet. PRODUCT.md nennt bisher Englisch
als v1 und andere Folgesprachen; die vorliegende Nutzerentscheidung ergänzt den
Umfang, ohne englische Lernregeln/Identitäten zu verändern. Das Produktdokument
wird erst mit einem abgenommenen Implementierungsinkrement angepasst.

## 1. Belegter Istzustand

| Bereich | Tatsächlicher Pfad/Schnittstelle | Implementiert / Grenze |
|---|---|---|
| Editor-Sprachen | `pipeline/src/sprachpipe/editor/service.py`: `create_language(data)`, `languages()`, `new_draft(lang, deck_ref=None)`; `editor/server.py` `/api/v1/languages` | Kanonisiert BCP-47, legt sprachgetrennten leeren Seed/Head an. Ohne Profil: **state=draft, profile=null**, nicht ready. Tempstore-Probe mit pt-BR bestanden. |
| Austausch | `editor/exchange.py`: `read_delivery(raw, filename, lang, source=None)`, `write_zip`, `template_delivery`; `editor/xlsx.py`: `read_workbook`, `write_workbook` | ZIP/JSON v4 und XLSX v1 existieren, Preview/Annahme getrennt. Sprache muss vor `preview_upload` als Basis existieren. `add.languages` und Top-Level-Sprachdefinition werden abgewiesen. |
| Authoring | `authoring_service.py`: `empty_pack`, `normalize_delivery`, `preview_import`, `apply_operations`, `_create_target`, `validate_draft`, `build_release` | Neuer Stapel und Ziele über vorhandene Operationen möglich. Vollständige Rohdaten/Refs, keine erfundenen IDs. Unbekannte Sprache blockiert Materialisierung/Release. |
| Profile | `pipeline/src/sprachpipe/language_profiles.py`: `canonical_language`, `PROFILES`, `get_profile`; `lib/domain/language_profile.dart`: `ContentLanguageProfile.forLanguage` | Nur `en`/`en-legacy-v1` registriert. Python kann pt-BR kanonisieren, aber `get_profile('pt-BR')` wirft PROFILE_UNSUPPORTED. Dart hat ebenfalls keinen pt-BR-Eintrag. |
| Linguistik | `annotate.py::tokenize`, `linter.py::lint_sentence`, `language_profiles.py::LanguageProfile` | Englisches Modell en_core_web_sm/3.8.0 und globale englische Linterkonfiguration. Frequenz nimmt lang entgegen, Regeln/Modell werden dadurch nicht automatisch portugiesisch. Modellbasierte Annotation ist nicht der manuelle Editorweg und wird nicht aufgerufen. |
| IDs/Besitz/Gruppen | `ids.py::stable_id/form_norm`, `word_registry.py`, `form_targets.py::card_id`, `learning_groups.py`, `authoring_service.py::_create_target` | Sprache in stabilen Lern-/Deck-/Satzschlüsseln, indirekt in Sense-/Token-/Link-IDs. NFC/lower/Apostroph-Normalisierung erhält Akzente. Owner=(lang,form_norm); Singletongruppen werden deterministisch erzeugt. Kein sprachübergreifendes Reuse. |
| Formen | `form_targets.py`; `lib/data/content/form_content_validation.dart`; `lib/domain/content.dart` | Funktionsmengen base/past/past_participle und verb_* sind englisch geprägt. Für Pilot ausschließlich ordinary, keine identity_function/Formstapel. Nicht ungeprüft auf portugiesische Konjugation übertragen. |
| SQLite/Revisionen | `lib/data/content/content_database.dart`, `context_revision_validation.dart`, `drift_content_repository.dart` | Readerabfragen an `info.lang` gebunden; Schema-5-Prüfung benötigt registriertes Profil/Hash. Unicode-Codepoints werden für Dart in UTF-16 umgesetzt. Aktive und historische Satzlinks getrennt. |
| Serverkanal | `supabase/functions/_shared/content_distribution.ts::validateStart/publish/reader`; Migrationen `20261017000002_content_distribution.sql`, `20261018000001_content_verification_runs.sql` | Tabellen, Leserfreigabe und CAS nach (lang,channel). **Upload und Publisher-Kanalabfrage hart en**, Profil-ID/Hash hart englisch. Release-Reader prüft sprachgebundene Rechte. SQL akzeptiert pt-BR bereits. |
| Stufenprüfung | `_shared/content_verification_steps.ts::verificationStages/verifyStage/finalManifest`, `_shared/content_distribution.ts`, `editor/publisher.py` | Normale 13 Stufen (F0–F8,M,P_full,H,A), durable Run-/Lease-/CAS-/Resume-Vertrag. Elternhistorie nur bei vorhandenem Parent. Englische Sonderadoption zusätzlich P_content; keine Vorlage für neue Sprache. |
| Installation | `content_install_journal.dart`, `content_pack_installer.dart`, `content_update_service.dart`, `content_release_client.dart` | Ordner pro Sprache, immutable Generation, Hash-/Inventar-/Profilprüfung, Recovery. **Journal akzeptiert pt-BR bereits**. Assetpfad enthält die angeforderte Sprache; kein genereller Englischfallback. Ohne Asset/Generation: ContentUnavailable(missing). |
| App-Sprachzustand | `database_providers.dart::selectedContentLanguageProvider/activeContentKeyProvider/contentOwnerFor/userRepositoryProvider` | Liest settings.target_lang, Default en; Owner nach (lang,generation). Kein sichtbarer Sprachwähler und kein vollständiger Wechselcommand. Auswahlprovider liest Settings einmal, braucht explizite Invalidierung. |
| Updates | `content_update_provider.dart::ContentUpdateController._getService/check/activate` | `_service`, `_client`, `_lastCheck` werden derzeit instanzweit gecacht; Sprache nur beim ersten Serviceaufbau gelesen. Bloß target_lang ändern wäre falsch: alter Update-Service könnte weiter en verwenden. |
| Nutzerbestand | `user_database.dart` Schema 6, `drift_user_repository.dart::_guardCards/_guardDecks/preferences/activityBetween` | Gemeinsame physische DB, sprachgebundene Fassaden, getrennte Lernpräferenzen, Reviews über Karten zugeordnet. Migration 5→6 existiert bereits; **keine neue Migration allein für pt-BR nötig**. IDs müssen Sprache weiterhin enthalten. |
| Lernen/Wortliste/Zähler | `practice_item_resolver.dart`, `deck_providers.dart`, `learning_providers.dart`, `deck_session_controller.dart` | Gemeinsame sprachgebundene Projektion, abgeleitete Zähler, Session friert Items/Pass ein. Fix 437c9c4: Wortdetails aktive Revision, Reviews historische Revision. Sprachwechsel muss Providergraph konsistent neu binden. |
| Stories | `story_learning_providers.dart`, `drift_content_repository.dart::storySummaries`, `home_screen.dart`, `app_shell.dart` | Echte Repositorydaten, vorhandener Leertext „Noch keine Stories im Inhaltspaket.“. Kein notwendiger sampleStories-Fallback. Async-Views verwenden teilweise skipLoadingOnReload/skipError: beim Sprachwechsel alte en-Daten ausdrücklich nicht weiter anzeigen. |
| Anzeige/Antworten | `home_screen.dart`, `settings/content_updates_screen.dart`, `decks/widgets/practice_menu.dart`, `domain/answer_check.dart`, `domain/grammar_hint.dart` | Sichtbare Texte teils fest „Englisch“. Antwortnormalisierung kann bei includeDiacritics=false Akzente entfernen; aktuelle Session reicht Einstellung weiter. Grammatikhinweise enthalten englische Regeln/Beispiele ohne Sprachprüfung. Beides vor pt-BR-Freigabe absichern. |

Graph: Repository `sprachlernapp`; Index vor Untersuchung aktualisiert mit
`node .gitnexus/run.cjs analyze --index-only` (Exit 0). Queries zu Sprachprofil,
Import und Providerfluss; context(create_language) belegt Sprachseed-/Profilpfad.
Providerkontext hat keine aufgelösten Kanten; gezielte rg-/Quellprüfung ergänzt
ihn. MCP behielt zeitweise alte Commitmetadaten; keine Vollständigkeitsbehauptung
für dynamische Riverpod- oder Pythondispatchkanten. Es werden keine
Produktfunktionen editiert; Implementierungsagent muss vor den jeweiligen Edits
erneut symbolgenaue Impacts ausführen.

## 2. Konsistente Identität und vorgeschlagenes Profil

**Durchgängig `pt-BR`**, auch languages.code, Pack.lang, Delivery.lang,
Manifest.lang, Kanal/Leserfreigabe, settings.target_lang, Userfassade,
LearningIdentity, Registry und Installationsordner `content/pt-BR/`.
Anzeigename „Portugiesisch (Brasilien)“, Eigenname „Português do Brasil“, Glossen
und Übersetzungen `de`. Profilvorschlag `pt-BR-editorial-v1`; Hash erst aus der
implementierten, getesteten Manifestdefinition, niemals einen Platzhalter als
freigegebenen SHA verwenden. `pt` und `pt-PT` bleiben nicht unterstützte andere
Kennungen. Eine künftige europäische Variante benötigt eigenen Kanal/Profil/IDs.
Kein nachträgliches Umbenennen eines eingeführten Codes.

Minimaler Pilotvorschlag ohne neue Downloads:

- Vorhandenes spaCy 3.8.16 `spacy.blank('pt')` als explizit gepinnter Tokenizer;
  **kein** en_core_web_sm, keine automatische POS-/Sensebestimmung. Kleine lokale
  Probe lieferte do/na/ação/ã/õ/ç unverändert, das ersetzt noch keine Goldentests.
  Tokenizerregeln und Bibliotheksversion in Profilfingerprint aufnehmen.
- NFC + lower + typografisches Apostroph→ASCII wie bestehende Identitätsnorm;
  keine Accent-/NFKC-Entfernung. Satztext nicht pauschal kleinschreiben.
  `do`/`na` als vollständige orthografische Tokens mit eigener belegter Semantik;
  kein automatisches Auflösen/Umformulieren. Mehrwortlücke über bestehenden
  lexical_spans-Mechanismus; volle zusammenhängende Tokengrenzen und ein Treffer.
- Neue explizite Policy `manual-pt-BR-editorial-v1`: deutsche Redaktion bestätigt
  brasilianischen Gebrauch, Grammatik, maximal einen Nebensatz, Verständlichkeit
  und Pilotniveau; 14 orthografische Wörter als bewusst gewählte Pilotobergrenze,
  ein grammatischer Übungssatz pro Ziel. Technische Satzzeichen-/Längen-/Gapprüfung
  plus manuelle Grammatikprüfung. Mehrteilige Sätze nicht durch englische Parser
  „prüfen“. Diese Profilpolicy ist erst nach Abnahme/Fähigkeitstests freigabefähig.
- Frequenzpolicy `manual-editorial-no-zipf-v1`: keine behaupteten BR-Zipfwerte,
  keine englischen 4.0/3.5/3.0-Schwellen. Wortwahl manuell; vorhandenes wordfreq
  ist keine brasilianisch validierte Frequenzquelle. Die Ausnahme ist im Profil
  und Review sichtbar, kein stilles Überspringen einer Pflichtprüfung.
- Fehlend: pt-BR-Goldenkorpus für Token-/Kontraktions-/Satzgrenzen, geprüftes
  Modell für POS/Dependenzen/Nebensätze, BR-spezifische Frequenz- und
  Niveaureferenz, redaktionell freigegebene Glossendaten. pt_core_news_sm/md
  sind lokal nicht installiert; auch deren Installation wäre noch kein
  Brasiliennachweis. Kein Download in diesem Auftrag.
- Antwortpolicy für pt-BR: Akzente **immer bedeutungsgetreu erforderlich**;
  includeDiacritics=false darf für dieses Profil kein exaktes Bestehen auslösen.
  UI erklärt „Akzente sind für Portugiesisch erforderlich“ statt stiller
  Einstellungsübernahme. Englische bestehende Einstellung unverändert behalten.
  NFC/NFD-äquivalente Eingaben und Groß-/Kleinschreibung gleich behandeln.
- Reihenfolge Ziel → geprüfte Alternative → belegte andere Form → fast richtig
  → falsch erhalten. Einzelner Akzentfehler kann bei ≥4 Zeichen „fast richtig“
  sein, löst aber nie; kurze Wörter strikt. Keine beliebigen Schreib-/pt-PT-
  Varianten. Neutraler Synonymretry nur kontextgebunden, kein SRS-Nachteil.
  Pilot liefert explizit leere Alternativenlisten. Erweiterte Formen erst später.
- Englische Grammatikbeispiele bei pt-BR unterdrücken; neutraler ehrlicher
  Hinweis oder explizit redaktioneller deutscher Formhinweis. Keine Heuristik
  für -ed/-ing/-s. Sprach-/Audiofunktionen sind nicht als BR-Ressource nachgewiesen
  (SpeechPlayback ist ein Timer-Stand-in); keine Aussprachefreigabe behaupten.

## 3. Mobile Sprachwahl und Zustandsvertrag

Einstellungen erhält oberhalb der sprachbezogenen Lernoptionen die Zeile
**„Lernsprache · Englisch“** beziehungsweise **„Portugiesisch (Brasilien)“**.
Auswahl zeigt Installationsstatus je Sprache. Deutsche Oberfläche bleibt global.
Home und Inhaltsupdates verwenden denselben expliziten Profil-Anzeigenamen;
Version und Sprache stammen aus demselben ausgewählten Schlüssel.

Neuer geplanter Command `LanguageSelectionController.selectLanguage(lang)`:

1. Exakt unterstützten Code prüfen. Während Updateaktion oder gehaltenem
   Session-/Reader-/Sheet-/Write-Lease: verständlicher Hinweis, **keine** Änderung
   von Settings, Queue oder laufendem Pass. Kein automatischer Wiederholungswechsel.
2. Unter bestehendem `ContentTransitionGate.transition`: Contentlease-Sperre/
   Close-Barriere verwenden; shared UserDatabase geöffnet lassen. Aktive
   Sprach-/Updateidentität unveränderlich für die Operation erfassen.
3. Bereits installierten Zielpack verifizieren/öffnen. Bei Korruption oder
   Close-/Openfehler Auswahl/Reader auf vorheriger Sprache lassen. Wenn ausdrücklich
   noch nie installiert: Wechsel in Zustand `notInstalled` ist erlaubt, ohne Pack.
4. Settings.target_lang atomar speichern und alle sprachabhängigen Provider an
   denselben neuen Schlüssel binden. Gelingt der Umschaltabschluss nicht, Auswahl
   wiederherstellen. Anzeige während Transition leer/loading; kein altes
   AsyncData unter neuer Sprachüberschrift. Auswahl beim nächsten Start lesen.
5. Neue Userfassade mit fester Sprache und dazu passendem contentIds-Callback;
   nicht später über ref.read unbemerkt auf einen anderen Inhaltsbestand zugreifen.
   Updateprovider als Family nach Sprache oder gleichwertig vollständig
   sprachgebundener Lebenszyklus; Service, HTTP-Client, automatische Prüffrist
   und Callbacks neu binden. Gemeinsame Authsession darf erhalten bleiben.

Vor erstem portugiesischem Download: Auswahl bleibt über Neustart pt-BR,
„Portugiesisch (Brasilien) · Noch nicht installiert“, CTA zu Inhaltsupdates.
Keine Stapel/Übungen/Stories als englischer Ersatz; gemischter Start deaktiviert.
Lernstand wird nicht als verlorener englischer Bestand oder als Contentfehler
interpretiert. Vorhandene vollständige lokale pt-BR-Kontexte können nach
bestehendem Vertrag sichtbar bleiben; bei erstem Installieren gibt es keine.
Kein Netz/keine Leserfreigabe/kein veröffentlichtes Angebot: konkreter Status,
kein Reset. Rückwechsel zu installiertem Englisch jederzeit nach sicheren Leases.

Download bleibt in `content/pt-BR/`; Abbruch lässt en und den letzten gültigen
pt-BR-Zeiger unberührt. Keine automatische Sprachumschaltung bei Downloadende.
Aktivierung erst nach Prüfung und sicherem Übergang. Nach Installation ohne
Stories: „Für Portugiesisch (Brasilien) sind noch keine Stories verfügbar.“
Stapel/Wortliste und vier abgeleitete Zähler ausschließlich aus pt-BR-Fassade.
Beim Rückwechsel erscheinen en-Reviews, Notizen, Favoriten, aktive Stapel,
Fälligkeiten und Tagesfortschritt unverändert; keine Counterspalten/Migration.

## 4. Erster regulärer portugiesischer Release

Nach Implementierung/Abnahme der Fähigkeiten, nicht jetzt ausführen:

1. Editor `create_language` mit pt-BR/de/Anzeigenamen; kanonischer leerer eigener
   Seed und leere Registry. Kein englischer Pack als Basis, keine Adoptionsaktion.
   Aktuell heißt der Seed intern `empty-pt-BR`; base_fingerprint setzt dafür
   release_id/version, anders als der alte Plan mit null. Das ist ein lokaler
   Basisanker, **keine** veröffentlichte Elternversion. Plan: für neue leere Seeds
   explizit keinen veröffentlichten Parent in das Bundlemanifest schreiben;
   lokale Basis-Hashes separat erhalten, keine Bestandsheads umdeuten.
2. Frische Vorlage aus exakt diesem Seed exportieren. Chat liefert 20 Ziele
   gemäß FORMAT.md; Importvorschau vollständig, anschließend ausdrücklich annehmen.
   create_deck/create_target und Begleitvokabular verwenden, nicht die internen
   englischen Bestandsübernahmeanker. Technisch prüfen; Redaktion bestätigt den
   tatsächlichen Payloadhash und BR-Policy, nicht importierte Reviewbehauptungen.
3. `EditorService.release` → `authoring_service.build_release`:
   Schema 5, echte SQLite-/Row-/Dart-Readerprüfung einschließlich leerer Basis,
   Registry-/Historienabschluss. Beispiel Versionslabel `ptbr_allgemeine_sprache_v1`
   erst beim echten Release vergeben. Bundle bleibt unverändert, Assets unberührt.
4. Publisher-Login und Kanalabfrage `(pt-BR, internal)` über bestehende Auth.
   Leerer Kanal: generation=0, release_id=null, manifest_sha256=null.
   Uploadstart expected_generation=0, parent_release_id=null,
   parent_manifest_sha256=null; normale Veröffentlichung ohne publication_kind.
5. Bestehende neun Dateien hochladen, native-v2 F0–F8/M/P_full/H/A durchlaufen.
   H benötigt bei erster Generation keinen Parent, prüft weiter Inventar/Freigabe.
   Run-/Leasebindung, Besitz/Rechte, Manifest-/Objekthashes, explizites Resume
   und CAS unverändert. `ADOPTION` bleibt ausschließlich englischer Sonderweg.
6. Gesonderter Commit erhöht nur pt-BR/internal auf Generation 1. Konkurrenz
   verliert CAS; Wiederholung derselben Commit-ID idempotent. Erst danach
   erlaubt der sprachgebundene Leserzugang Download/Prüfung/Aktivierung der App.
   Bestehende en-Freigabe impliziert keine pt-BR-Leserfreigabe. Freigabeeinrichtung
   und Deployment sind spätere explizite Betriebsaktionen, nicht dieses Plans.
7. Folgerelease pt-BR nimmt nur den veröffentlichten pt-BR-Parent. Bestehende
   `published_base.py`-Prüfungen auf Sprache/Profil/Kanal/Hash weiterverwenden.
   Kein „Englisch als Vorgänger“, keine zweite interne Erstübernahme.

## 5. Lieferformat, ehrlicher Vorlagenstatus und kleinste Erweiterung

Artefakt: `build/portuguese_authoring_contract_v1.zip` (19.799 Bytes bei diesem Lauf).
SHA256 `cc308d24ff134e2cddd4ce22afeeb90166929441195152423c7b55f25a497392`.
Die ZIP nutzt genau die vorhandenen sechs Austausch-Einträge. FORMAT.md enthält
Pflichtfelder, zulässige Werte, Rohrefbindung, Unicode-/Gapregeln, redaktionelle
Verantwortung und tatsächliches XLSX. Maschinenlesbarer Feldvertrag und
synthetische Beispiel-Delivery liegen zusätzlich **als Referenzmaterial im
`authoring_context.json`**, nicht als zweite importierte Lieferung.

Versionierte Quellen/Reproduktion unter `docs/portuguese-authoring-contract-v1/`:
FORMAT.md, contract.json, template.delivery.json, synthetic-example.delivery.json,
authoring_context.json, build_and_verify.py. Letzteres erstellt ausschließlich
Dokumentationsartefakte/Tempstore und verwendet vorhandene Adapter; keine neue
Produkt-Importlogik. Archivbytes können beim Wiederbau wegen ZIP/XLSX-Zeitstempeln
abweichen; fachlicher JSON-/XLSX-Roundtrip muss identisch bleiben.

**Heute nachgewiesen:** bestehendes JSON-Schema mit Formatprüfung, JSON-/XLSX-
Roundtrip und read_delivery am finalen ZIP einschließlich Hash-/Quellenvergleich.
20 leere Zielslots sind als Draft transportgültig. Synthetisches Beispiel benutzt
`SYNTHETIC_NON_PUBLISHABLE`, unresolved Bindung und keine echten portugiesischen
Wörter. validate_draft meldet bei beiden `unsupported/PROFILE_UNSUPPORTED`,
editorial=open. Keine Freigabe, keine Wortreservierung, kein Lernpack.
Die spätere Chatlieferung darf erst aus einer frisch exportierten geprüften
pt-BR-Basis entstehen; aktuelle Blank-Hashes sind keine Produktionsbasis.

**Neue Sprache und neuer Stapel allein aus Austauschdatei? Heute nein.**
create_deck ist implementiert; Sprache muss bereits über create_language existieren.
`add.languages` ist nicht in TABLES. Ein beliebiges Profilfeld/Extensionsobjekt
wird nicht ignoriert, sondern abgewiesen. Für den Pilot genügt der vorhandene
zweistufige Weg: Sprache anlegen → Vorlage exportieren → Lieferung importieren.
Keine Formatneuerfindung nötig, um die Inhalte später im Chat zu erstellen.

Falls „alles aus einer Datei“ gewünscht wird, ist die kleinste spezifizierte
Vertragserweiterung genau **ein optionales v4-Feld `language_definition`**:
`{lang,display_name,name_native,translation_lang,profile_id,profile_sha256}`,
alle Pflicht, keine weiteren Felder. Nur purpose=new_deck, registriertes exakt
passendes Profil/Hash, `lang=Delivery.lang`, `translation_lang=de`. Preview baut
nur einen temporären deterministischen leeren Seed. Annahme persistiert Seed,
Head und Importbeleg gemeinsam unter Store-Mutex mit Recovery; kein halber
Sprachdatensatz bei Fehler. Existierende Sprache nur bei exakt gleichen
Metadaten/Profil, sonst Konflikt; nie überschreiben. Gleiche Liefer-ID bleibt
idempotent, anderer Payload ist Konflikt. Kein hochladbarer Profilcode.

Erweiterung betrifft Schema, normalize_delivery, preview_upload/accept_import,
XLSX-Meta und Exportkontext; alte Reader weisen das zusätzliche Feld bewusst ab.
Sie ist im contract.json **NOT_ACCEPTED_BY_CURRENT_IMPORTER** und wird nicht
in die heutige delivery.json eingeschleust. Empfehlung: im ersten Inkrement beim
bestehenden zweistufigen Weg bleiben; Ein-Datei-Bootstrap nur nach ausdrücklicher
Planentscheidung zusätzlich in demselben Inkrement, kein drittes Inkrement.

## 6. Genau zwei Implementierungsinkremente

### Inkrement 1 – BR-Profil und regulärer erster Inhaltskanal

| Tatsächliche Datei / Schnittstelle | Kleinste geplante Änderung |
|---|---|
| `pipeline/src/sprachpipe/language_profiles.py` / LanguageProfile, PROFILES, get_profile | Eigenes pt-BR-editorial-v1; explizite Tokenizer-/Normalisierungs-/manuelle Prüf-/Frequenzpolicy; en-Manifest/Hash einfrieren. |
| `pipeline/src/sprachpipe/authoring_service.py` / base_fingerprint, target_findings, validate_draft, _build_verified_bundle | Profilhash für jede registrierte Sprache statt en-Sonderzweig; neue Seed-/Parentsemantik explizit; profilabhängige Prüfungen und hashgebundene manuelle BR-Prüfpunkte. Bestehende Buildpipeline behalten. |
| `pipeline/src/sprachpipe/annotate.py::tokenize`, `linter.py` | Vorhandene Token-/lexical_spans-Hilfe wiederverwenden; nur nötige Policyabtrennung, kein globaler Wechsel englischer Linterregeln. Keine annotate_card-/LLM-Aufrufe. |
| `lib/domain/language_profile.dart`; `lib/data/content/context_revision_validation.dart` | Genaues pt-BR-Profil/Hash und Fähigkeiten registrieren; bestehenden Revision-/Historyvergleich verwenden, keine permissive Prefixauflösung. |
| `supabase/functions/_shared/content_distribution.ts` / validateStart, publish GET channel | Kleine explizite Profilallowlist en + pt-BR; Kanalquery parametrisieren. Auth/Readerrechte/Manifestmerkmale unverändert; ADOPTION weiter en-only. |
| `supabase/functions/_shared/content_verification_steps.ts`; `pipeline/src/sprachpipe/editor/publisher.py`, `service.py::publish_release` | Regulären generation-0/null-Parent-Weg mit pt-BR prüfen; nur konkret nötige Scopeanpassungen. Keine Run-/Lease-/CAS-Abschwächung. |
| `pipeline/data/curation/editorial_content_v4.schema.json`, `editor/exchange.py`, `editor/xlsx.py`, `editor/service.py`, `editor/server.py`, `editor/web/app.js` | Nur falls Ein-Datei-Bootstrap abgenommen: oben exakt beschriebenes optionales Feld/Preview/atomare Annahme. Sonst bestehende Schnittstellen unverändert verwenden. |
| `PRODUCT.md`, `docs/content-editor-contract.md`, `docs/pipeline.md` | Abgenommene BR-Policy/Scope festhalten; nicht bloß bestehende Fehler legitimieren. |

Tests ergänzen in `pipeline/tests/test_language_profiles.py`,
`test_editor_exchange.py`, `test_editor_xlsx.py`, `test_editor_service.py`,
`test_editor_publisher.py`, `test_ids.py`; neue konkrete Fixturedatei
`pipeline/tests/fixtures/ptbr_editorial_v1.json` ausschließlich synthetisch.
Dart: `test/data/content_context_revisions_test.dart`, neue
`test/data/portuguese_profile_test.dart`; Server:
`content_distribution_test.ts`, `content_verification_steps_test.ts`.
Kein SQL-Schemawechsel für den Sprachcode erforderlich. Reader-Tool
`tool/editor_content_pack.dart` bleibt gemeinsamer Nachweis, kein neuer Exporter.

Exitkriterien: en-Profilhash/IDs unverändert; pt-BR-Tokenizer-/Unicodegoldens,
20 vollständige Zielkontexte nach manueller Abnahme, echter normaler Bundlebuild
mit leerer eigener Basis, offline Serverfixtures für generation 0/1 und falschen
en-Parent, vorhandene Historien-/CAS-Tests. Keine Veröffentlichung allein durch
Abschluss dieses Inkrements; Betriebsfreigabe getrennt.

### Inkrement 2 – mobile Sprachwahl, Profilantworten und vertikale Abnahme

| Tatsächliche Datei / geplante Schnittstelle | Änderung / Prüfumfang |
|---|---|
| Neu `lib/presentation/providers/language_selection_provider.dart` / selectLanguage(lang) | Obiger serialisierter Wechselcommand; registrierte Sprachen + Installationsstatus. |
| `lib/presentation/providers/database_providers.dart` | Auswahl/Generation/Fassaden konsistent invalidieren; feste sprachgebundene Content-ID-Prüfung; UserDB-Owner erhalten. |
| `lib/presentation/providers/content_update_provider.dart` | Sprache als Familykey oder gleichwertiger Lebenszyklusschlüssel; Service/Client/_lastCheck/Callbacks nie über Sprachen wiederverwenden. |
| `lib/screens/settings/settings_screen.dart`, `content_updates_screen.dart`; `lib/screens/home/home_screen.dart` | Lernsprachwahl, persistente Auswahl, dynamischer Name/Status, erforderliche Akzente; fehlender Download klar angezeigt. |
| `lib/screens/app_shell.dart`, `lib/presentation/providers/story_learning_providers.dart`, `deck_providers.dart`, `learning_providers.dart` | Alte AsyncData beim Sprachwechsel entfernen; passende leere Stories/Decks/Wordlist/Zähler. Datenlogik nur bei belegtem Anpassungsbedarf ändern. |
| `lib/domain/answer_check.dart`, `review_pass.dart`, `language_profile.dart`; `lib/presentation/practice/deck_session_controller.dart` | Profilgebundene effektive Akzentpolicy, en-Verhalten unverändert, eingefrorenes Profil/Pack je Durchgang. Kein neuer SRS-Schreibweg. |
| `lib/domain/grammar_hint.dart`, `lib/screens/decks/widgets/practice_menu.dart` | Keine englischen Grammatik-/Tastaturhinweise unter pt-BR; neutraler oder redaktioneller Formhinweis. |
| `lib/data/user/drift_user_repository.dart`, `lib/domain/repositories.dart` | Nur falls für Auswahl nötig: schmaler persistenter Settingszugriff; keine Tabellenmigration, keine Lern-/Reviewänderung. |
| `lib/data/content/content_install_journal.dart`, `content_pack_installer.dart`, `content_update_service.dart`, `drift_content_repository.dart`, `lib/data/learning/practice_item_resolver.dart` | Vorhandene sprachgebundene Schnittstellen zunächst unverändert; Tests belegen pt-BR und Erstinstallation. Keine prophylaktischen Umbauten. |

Neue Tests `test/language_selection_test.dart`,
`test/data/portuguese_installation_test.dart`; bestehende
`test/data/user_language_migration_test.dart`, `content_update_test.dart`,
`content_owner_barrier_test.dart`, `test/domain/answer_check_test.dart`,
`test/learning_integration_test.dart`, `test/data/content_active_context_test.dart`
und `test/content_updates_ui_test.dart` ergänzen. Schema 6 bleibt; generierte
`user_database.g.dart` nicht ohne tatsächlich erforderliche Schemaänderung anfassen.

Exitkriterien: folgende Matrix vollständig lokal grün, danach expliziter
Geräteversuch auf bestehender Installation ohne Löschen. Erst dessen Abnahme
öffnet die redaktionelle Erweiterung Richtung 160; kein automatisches Auffüllen.

## 7. Gegenlese-/Abnahmematrix

| Fall | Überprüfbares Ergebnis |
|---|---|
| Bestehendes en, erstes Appupdate | Auswahl en bleibt; vollständige synthetische Tabellen-Snapshots für Karten/Reviews/Notizen/Favoriten/Bindings unverändert. |
| pt-BR vor Download, Neustart | Auswahl persistiert; notInstalled mit Downloadaktion, keine englischen Daten/Übungsqueue unter pt-BR. |
| Offline/403/kein Kanalangebot | Verständlicher Unterschied; kein Assetfallback, keine Auswahl-/Datenlöschung; en weiter erreichbar. |
| Abbruch/Hashfehler pt-BR-Download | Nur Kandidat betroffen; en-Datei/Zeiger/High-Water-Mark unverändert; Neustart konsistent. |
| Erste Installation | generation 1, Parent null, pt-BR-Pfad/Manifest/Reader/Anzeige identisch; kein englischer Vorgänger. |
| Sprachwechsel während Pass/Reviewretry/Sheet | Blockiert ohne Nebenwirkung; nach explizitem Verlassen möglich; alter Pass/Snapshot behält Satz/Profil. |
| Wechsel während Download/Aktivierung | Serialisiert/blockiert; verspätete Callback-/HTTP-Antwort aktualisiert nie falsche Sprache. |
| pt-BR → en → Neustart | en-Boxen/Fälligkeiten/Reviews/Flags/Notizen/Deckauswahl/Tageswerte exakt wie vorher; pt-BR-Daten getrennt. |
| Gleiche Form/Slug/Sense-Key in beiden Sprachen | Verschiedene stabile IDs/Owner/Bindings; fremdsprachige ID-Lese-/Schreibversuche abgewiesen. |
| NFC/NFD, ã/õ/ç, Großschreibung | Kanonisch gleiche Form gleiche ID/Antwort; unterschiedliche Akzente keine exakte Lösung; kein globales Strippen. |
| do/na, Mehrwortlücke, Emoji vor Lücke | Vollständige Tokens, Codepoint→UTF-16 korrekt; NFD vor Offsetbestimmung normalisieren; keine Teilgrapheme. |
| Ziel zweimal/disjunkte Lücke | Feldfehler, keine erste-Fundstelle-Heuristik. |
| Wort-/Satzglosse und Revision | Jede Tokenbindung explizit; Änderung macht Review offen; aktuelle Wortdetails/neue Pässe neu, alte Reviews historisch. |
| Keine Stories/keine neuen Wörter | Ehrlicher Leerzustand, keine Samples/NaN-Zähler; Fortschritte aus ausgewählter Sprache abgeleitet. |
| Parent/Profil falsch, pt oder pt-PT | Explizite Ablehnung; weder englischer Parent noch Prefixfallback. |
| Zwei Publisher/abgelaufener Run | Bestehende CAS-/Lease-/Resume-Regeln bleiben; genau ein Commit gewinnt. |
| Optionaler Ein-Datei-Bootstrap | Fremdsprache/Hash-/Metadata-Konflikt, Crash, Retry: atomar/idempotent, kein halber Sprachhead. |

Offene Planentscheidungen zur Abnahme: (1) vorgeschlagenes modellfreies,
redaktionelles BR-Pilotprofil samt manueller Frequenz-/Grammatikpolicy statt
Download eines bislang ungeprüften NLP-Modells; (2) vorhandener zweistufiger
Sprachseed-/Importweg empfohlen, Ein-Datei-Erweiterung optional. Die vorgegebenen
20/≈160-Ziele, Deutsch und pt-BR werden nicht erneut zur Disposition gestellt.
Keine dieser Entscheidungen wird durch dieses Dokument bereits implementiert.

## 8. Tatsächliche Prüfung dieses Planauftrags

macOS (Terminal), Repository-Root; keine Paketinstallation/Downloads:

```sh
pipeline/.venv-macos/bin/python -m pytest pipeline/tests/test_language_profiles.py pipeline/tests/test_editor_exchange.py pipeline/tests/test_editor_xlsx.py pipeline/tests/test_editor_service.py pipeline/tests/test_editor_publisher.py pipeline/tests/test_ids.py -q
pipeline/.venv-macos/bin/python docs/portuguese-authoring-contract-v1/build_and_verify.py
```

Windows (PowerShell): gleiche Argumente mit
`pipeline\.venv\Scripts\python.exe` statt `pipeline/.venv-macos/bin/python`.
Hier nicht auf Windows ausgeführt. Die folgenden Befehle sind plattformgleich:

```text
flutter test --no-pub test/data/user_language_migration_test.dart test/data/content_update_test.dart test/data/content_owner_barrier_test.dart test/domain/answer_check_test.dart
deno test --no-remote --allow-read supabase/functions/_shared/content_distribution_test.ts supabase/functions/_shared/content_verification_steps_test.ts
git -c core.whitespace=cr-at-eol diff --check -- docs/portuguese-language-rollout-plan.md docs/portuguese-authoring-contract-v1 NEXTSTEPS.md
```

| Prüfung | Tatsächlicher Output | Exit |
|---|---|---|
| Python gezielt | `64 passed in 16.48s` | 0 |
| Flutter gezielt | `00:01 +31: All tests passed!` | 0 |
| Vertragsartefakt | template + synthetic-example: `SCHEMA/JSON/XLSX PASS; release blocked: unsupported ['PROFILE_UNSUPPORTED']`; Tempstore-Sprachseed PASS; `ZIP read_delivery/hash/source-consistency PASS; 20 empty slots` | 0 |
| Ressourcenprobe | canonical_language(pt-br)=pt-BR; get_profile=PROFILE_UNSUPPORTED; en_core_web_sm vorhanden, pt_core_news_sm/md fehlen; spaCy 3.8.16 blank pt erhält do/na/ação/ã/õ/ç | 0 |
| Serverfixturetests | `zsh:1: command not found: deno` | 127 |

Ein erster Artefaktprüflauf erwartete fälschlich Sprachstatus `blocked`; tatsächliche
Schnittstelle liefert `draft/profile=null`. Probe korrigiert, kein Produktcodefix;
anschließend alle Artefaktchecks Exit 0. Kein verschwiegenes Release-PASS. Deno
nicht nachinstalliert; Serverpfad deshalb quellengeprüft, neue Serverabnahme offen.
Keine vollständige Flutter-Suite/Analyse allein für diese Planung gestartet.
Alle Datenbanktests benutzen temporäre synthetische Dateien; kein Zugriff auf
persönliche user.db, kein Eingriff in Editorentwürfe/Assets/Cloud/Signierung.

Nur Plan-/Vertragsquellen und höchstens 25 eigene NEXTSTEPS-Zeilen werden isoliert
committed. Build-ZIP liegt wie angefordert unter build/ und ist aus den Quellen
reproduzierbar; kein Push. Implementierung wartet auf Planabnahme.

Abschlussprüfung: `git -c core.whitespace=cr-at-eol diff --cached --check`
und unstaged `diff --check`: kein Output, Exit 0. NEXTSTEPS: fünf ergänzte
Zeilen, CRLF erhalten; finaler ZIP-/Memberhash-/FORMAT-Abgleich PASS, Exit 0.
Indexaktualisierung Exit 0; `detect_changes(scope=all)` meldet 38 Symbole,
8 Dateien, 0 aufgelöste betroffene Prozesse, risk low, ohne partial/truncated
im Änderungsbericht. Der Index warnt separat vor begrenzter Flowerfassung und
sprachübergreifend nicht aufgelösten Propertyzugriffen; Null ist deshalb kein
Nachweis vollständiger Laufzeitabdeckung. Keine Produktdatei im Commit.
