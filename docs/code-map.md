# Code-Landkarte

Orientierung am vorhandenen Code. Produktregeln stehen in `PRODUCT.md`, Zielschichten in `ARCHITECTURE.md`, Gestaltung in `DESIGN.md`. Pfade sind relativ zum Repository; `P/` steht unten für `lib/presentation/providers/`.

## Ordner

| Ort | Rolle und Einstieg |
| --- | --- |
| `lib/domain/` | Reines Dart ohne Flutter-/`dart:ui`-Imports: Karten, Identitäten, Antwortprüfung, SRS-Queues, Zählerableitung und Repository-Verträge. |
| `lib/data/content/` | Inhaltspack, read-only Drift-Repository, Installation, Validierung, Updatejournal und Inhaltsauthentifizierung. |
| `lib/data/user/` | Drift-Nutzerschema, `DriftUserRepository`, Speicher für generierte Vokabeln. |
| `lib/data/learning/` | `PracticeItemResolver`/`PracticeCatalog` verbinden Pack und Lernstand; Dienste für persönliche und generierte Karten. |
| `lib/data/sync/` | Kontoabgleich, zusätzliche SQL-Tabellen, `SyncJsonStore` und Supabase-RPC-Gateway. |
| `lib/data/auth/` | Native Kontoidentität und Gateway für Kontolöschung. Die gemeinsame Authentifizierung selbst liegt in `data/content/content_auth_repository.dart`. |
| `lib/data/billing/` | Adapty-Kauf-/Identitätsadapter und Gateway zum serverbestätigten Kaufstatus. |
| `lib/data/offline_translation/` | Lokales Wörterbuch und Auswahl einer passenden Wörterbuchbedeutung. |
| `lib/data/platform/`, `lib/data/http/` | Bedingte native/Web-Adapter für SQLite, JSON-Speicher und HTTP. |
| `lib/data/` direkt | Übersetzungsclient, privater Übersetzungscache, persönliche Lernkarten- und Vokabelclients. `data/news/` enthält den Nachrichtenclient. |
| `lib/presentation/` | Riverpod-Provider, `practice/deck_session_controller.dart`, Audioadapter und gemeinsame Darstellungshelfer. |
| `lib/models/` | Bestehende UI-Modelle; `sample_content.dart` enthält Platzhalter, `localized_practice_content.dart` fest hinterlegte lokalisierte Beispielübungen. |
| `lib/screens/` | Aktuelle Screens einschließlich `app_shell.dart`, Reader, Übung, Wortliste, Konto und `web/`. |
| `lib/widgets/`, `lib/theme/` | Wiederverwendbare UI-Bausteine; Farben, Typografie und Theme in `theme/app_theme.dart`. |

## Kern-Provider und Schreibweg

Die Pfeile beschreiben den Aufbau und die Datenversorgung, keine durchgehend lineare `watch`-Kette:

```text
accountSessionProvider → userDatabaseProvider → selectedContentLanguageProvider
  → contentInstallerProvider(lang) → activeContentKeyProvider / contentRepositoryProvider
userDatabaseProvider + selectedContentLanguageProvider → userRepositoryProvider
userRepositoryProvider → userChangesProvider → practiceResolverProvider
contentRepositoryProvider → practiceCatalogProvider → practiceResolverProvider
practiceResolverProvider → decksProvider / vocabBreakdownProvider /
                          lexicalBreakdownProvider / wordListProvider
practiceResolverProvider + userRepositoryProvider → DeckSessionController
  → recordReview → userChangesProvider → abgeleitete Ansichten
```

| Provider/Symbol | Datei und Besonderheit |
| --- | --- |
| `accountSessionProvider` | `P/auth_providers.dart`; Stream der initialisierten Kontoidentität. |
| `contentAuthProvider` | `P/auth_providers.dart`; gemeinsame Kontoauthentifizierung auch für Kauf, Übersetzung und Sync. |
| `userDatabaseProvider` | `P/database_providers.dart`; wartet auf das Konto und least die Datenbank des lokalen Owners. |
| `selectedContentLanguageProvider` | `P/database_providers.dart`; Sprache aus den Einstellungen dieser Datenbank. |
| `contentInstallerProvider` | `P/database_providers.dart`; Installer je Sprache. |
| `activeContentKeyProvider`, `contentRepositoryProvider` | `P/database_providers.dart`; Identität aus Sprache/Generation/Fingerprint und geleaster Leser. Das Repository beobachtet den Key-Provider absichtlich nicht direkt, damit Recovery den gerade validierten Leser nicht entsorgt. |
| `userRepositoryProvider` | `P/database_providers.dart`; Sprachansicht auf die Nutzer-DB, Packzugriff über Prüf-Callbacks. |
| `userChangesProvider` | `P/user_changes_provider.dart`; nummeriert Änderungsereignisse des Nutzer-Repositories. |
| `practiceResolverProvider`, `practiceCatalogProvider` | `P/practice_resolver_providers.dart`; Resolver reagiert auf Lernänderungen, Katalog liest Packmetadaten. |
| `decksProvider`, `vocabBreakdownProvider`, `lexicalBreakdownProvider` | `P/deck_providers.dart`; Stapel und aus Karten abgeleitete Zahlen. |
| `wordListProvider` | `P/learning_providers.dart`; aufgelöste Karten, Kontext, Flags und Reviewhistorie. |
| `DeckSessionController` | `lib/presentation/practice/deck_session_controller.dart`; nutzt Resolver und Nutzer-Repository direkt, baut Queues und verarbeitet `ReviewPass`. |
| `recordReview` | Vertrag in `lib/domain/repositories.dart`, Implementierung in `lib/data/user/drift_user_repository.dart`; Review und Box/Fälligkeit in einer Transaktion. |

## Wichtige Datenflüsse

- **Pack und Update:** `ContentPackInstaller` öffnet gebündelte/installierte Inhalte; `P/content_update_provider.dart` verbindet `ContentReleaseClient`, `ContentUpdateService` und `ContentInstallJournal` (`lib/data/content/`). Download und Validierung gehen der Aktivierung voraus. Leser werden geschlossen, die aktive Generation umgeschaltet und Leser wieder geöffnet; Fehler können das vorbereitete Journal zurücksetzen.
- **Review:** Übungsscreen → `DeckSessionController.start` → `PracticeItemResolver` und Queue-Funktionen in `domain/srs_state.dart` → `ReviewPass` (`domain/review_pass.dart`) → `commit` → `recordReview`. Änderungsereignisse aktualisieren die Ansichten; die vier Vokabelzähler sind Ableitungen, keine gespeicherten Spalten.
- **Story-Lernen:** Wort-Tap im `screens/stories/story_reader_screen.dart` → Kandidat/Status über `StoryLearningService` (`P/story_learning_providers.dart`) → `WordPopover` → ausdrückliches Add → `StoryLearningRepository.addStoryWord`. Persönliche Karten nutzen `PersonalLearningButton`, `PersonalLearningService` und `PersonalLearningClient`; Übersetzung allein speichert keine Lernkarte.
- **Übersetzung:** Gespeicherte Storyübersetzung → sonst `widgets/runtime_translation_sheet.dart` → privater Cache → Offline-Wörterbuch → bei passender Einwilligung `CachedRuntimeTranslationClient`/`RuntimeTranslationClient`. Authentifizierte Supabase-Funktionen übernehmen Cloudanfragen; Konfiguration in `P/runtime_translation_provider.dart` und `P/offline_translation_provider.dart`.
- **Sync:** `P/learning_sync_provider.dart` hält `LearningSyncService` für das aktuelle Konto; Datenbankänderungen, Timer und App-Lebenszyklus stoßen Abgleiche an. `SupabaseLearningSyncGateway` ruft `push_learning_rows`/`pull_learning_rows` auf. Übertragen werden die Tabellen der Allowlist in `data/sync/learning_sync.dart`, einschließlich Review-, Quellen- und JSON-Dokumentdaten.
- **Konto und Kauf:** `P/account_provider.dart` → gemeinsame `ContentAuthRepository`; Kontoänderungen wechseln Datenbank/Navigation. `P/billing_provider.dart` bindet die Adapty-Identität, `P/purchase_provider.dart` lädt Produkte und verifiziert Zugang über das Billing-Gateway; `P/premium_access_provider.dart` liefert den UI-Zugang einschließlich des erlaubten Sandbox-Pfads.
- **Web:** `lib/main.dart` wählt `screens/web/web_app_gate.dart` → Anmeldung → `WebLearningShell`. Reader, Übung und Provider werden geteilt. `data/platform/sqlite_platform.dart` wählt WASM; die Nutzer-DB verlangt dauerhaften Browserspeicher, private Caches verwenden IndexedDB, Packbytes werden geprüft und read-only geöffnet.

## Datenbanken und Dokumente

| Speicher | Zuständigkeit |
| --- | --- |
| `user.db`, Drift-Schema **v8** | `lib/data/user/user_database.dart`; Lernkarten, Reviews, Einstellungen, Kontexte, Quellen und Bindungen. Native Kontotrennung in `data/platform/sqlite_native.dart`: erstes Konto übernimmt `user.db`, weitere Konten bekommen gehashte Dateinamen, späterer Gast `guest.db`. Web verwendet kontogetrennte Datenbanknamen. |
| `learning_sync_*` | Zusätzliche Tabellen in derselben Nutzer-DB, per `prepareLearningSync` in `lib/data/sync/learning_sync.dart` angelegt, außerhalb des generierten Drift-Schemas und seiner `schemaVersion`. |
| `content.sqlite` je Sprache/Generation | `lib/data/content/content_database.dart` und `content_pack_installer.dart`; nur lesend, keine Appmigration dieses Inhaltsbestands. |
| `private_translations.sqlite` | `TranslationCache` (`lib/data/translation_cache.dart`), verdrahtet in `P/runtime_translation_provider.dart`; kontogebundene Übersetzungen und Einwilligung. |
| `private_learning_consent.sqlite` | `PersonalConsentStore` (`lib/data/personal_learning_client.dart`), verdrahtet in `P/personal_learning_provider.dart`. |
| `reading_progress_<lang>`, `imported_texts_<lang>` | JSON-Dokumente hinter `JsonStore` (`P/reading_providers.dart`). `main.dart` setzt `SyncJsonStore` ein: Speicherung in `learning_sync_documents`, kontogetrennt über die DB. Frühere native `ui/<name>.json`-Dateien sind nur eine zugriffsbeschränkte Migrationsquelle (`AccountLegacyJsonStore`). |

## Zusätzliche Repository-Fähigkeiten

Die Basisschnittstellen stehen in `lib/domain/repositories.dart`. Zusatzverträge werden an den folgenden Stellen geprüft; fehlende Fähigkeiten bedeuten je nach Aufrufer leere Daten, einen Fallback oder einen Fehler.

| Fähigkeit (Definition unter `lib/domain/`) | Prüfung/Verwendung |
| --- | --- |
| `StoryLearningRepository` (`story_learning.dart`) | `PracticeItemResolver.load`/`historicalSentence` prüfen `is`; `StoryLearningService` prüft `is!` und meldet fehlende Unterstützung als Fehler. |
| `StoryContentRepository` (`story_learning.dart`) | Story-Provider und `StoryLearningService.candidate` in `P/story_learning_providers.dart`. |
| `GeneratedVocabularyRepository` (`generated_vocabulary_repository.dart`) | `PracticeItemResolver.load`; ohne Fähigkeit keine generierten Mitgliedschaften. |
| `StoryContextCorrectionStore` / `StoryContextCorrectionSource` (`story_learning.dart`) | `PracticeItemResolver.load` prüft beide und **schreibt** dann Korrekturen, auch beim Laden durch einen lesenden Provider. |
| `RetiredLearningContentRepository` (`story_learning.dart`) | Resolver, `PracticeCatalog.load` und `PersonalLearningService`; ohne Fähigkeit leere Liste zurückgestellter Identitäten. |
| `ReviewActivityRepository` (`review_activity.dart`) | `ReviewActivityReads.activityBetween`/`lastReviewTimes`; sonst `reviewsFor` je Karte. |
| `NewWordRotationStore` (`repositories.dart`) | `DeckSessionController.start`/`commit`; ohne Fähigkeit kein Lesen/Speichern des letzten Quellenzugs. |
| `PersonalLearningStore` (`personal_learning.dart`) | `PersonalLearningService` verwendet einen direkten `as`-Cast beim Speichern, **keine** vorgeschaltete `is`-Prüfung und keinen Fallback. Dort wird auch `StoryLearningRepository` direkt vorausgesetzt. |

`DriftUserRepository` implementiert die Nutzerfähigkeiten: Story-Lernen, generierte Mitgliedschaften, Kontextkorrekturspeicher, Reviewaktivität, Quellenrotation und persönliches Speichern. `DriftContentRepository` implementiert die Inhaltsfähigkeiten: Story-Inhalt, Korrekturquelle und zurückgestellte Identitäten.
`TestUser` in `test/fixtures/deck_repositories.dart` implementiert nur `UserRepository`. Tests mit diesem Fake erreichen daher die vorhandenen Fallbacks, etwa in `domain/review_activity.dart`; sie prüfen nicht automatisch die zusätzlichen Drift-Pfade.

## Zustände außerhalb von Riverpod

| Zustand | Ort und Lebensdauer |
| --- | --- |
| `contentTransitionGate` | `P/database_providers.dart`; gemeinsame Sperre für Inhaltswechsel während Reader, Übung oder Schreibaktionen aktiv sind. |
| `_contentOwners` | Dieselbe Datei; Register nach Sprache/Generation/Fingerprint, geteilt über Provider-Scopes, mit Entfernung nach erfolgreichem letztem Close. |
| `_userDatabaseOwners` | Dieselbe Datei; Register je lokalem Konto-Owner, ohne `onIdle`-Entfernung. |
| `LaunchSplash.enabled` | `lib/widgets/launch_splash.dart`; statischer Schalter, in `main.dart` für native Starts aktiviert. |
| `OnboardingArt.riveReady` | `lib/screens/onboarding/widgets/onboarding_art.dart`; statischer Bereitschaftsschalter nach Rive-Initialisierung in `main.dart` bzw. `main_completion_preview.dart`. |

## Tests

- `test/shell_callbacks_characterization_test.dart`: beide Shells, Story-/Import-Callbacks und Sprachwechsel bei Fortschrittsmeldungen; verdeckte Premiumzweige direkt über Callbacks.
- `test/session_rules_characterization_test.dart`: Sitzungsgrößen, Tagesrest, Premiumfilter und Quellenrotation.
- `test/reader_lookup_characterization_test.dart`: Wort-Popover, Runtimeübersetzung, Markierungen, Fehler und Bedingungen für persönliches Lernen.
- `test/goldens/core_screens_golden_test.dart`, Bilder in `test/goldens/images/`: Home, Übung, Story-Reader und Wortliste, jeweils hell/dunkel. **Nur macOS**; ohne gebündelte Google Fonts wird Typografie nicht abgesichert.
