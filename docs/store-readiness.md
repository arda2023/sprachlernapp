# App-Store-Vorbereitung

Auftrag vom 13. November 2026, direkt im bestehenden Projektordner. Branch: `feature/store-readiness`, Ausgangscommit: `0f00682`. iPad-Konfiguration, lokale Inhaltspakete, `config/adapty.local.json` und `appstore_ranking_reddit.md` bleiben unverändert. Kein Upload, Push oder Eingriff in App Store Connect.

## Ausgangsprüfung

```text
git branch --show-current: ui-polish-launch-screen
git rev-parse --short=7 HEAD: 0f00682
git status --short: ?? appstore_ranking_reddit.md
No issues found! (ran in 7.4s)
02:14 +1146 ~9: All tests passed!
```

Die bestehende Testsuite gibt Warnungen über nicht gebündelte Google-Fonts aus; sie endet ohne Fehlschlag. Kein Golden wurde aktualisiert.

## Teil 1 – Deutsch als App-Sprache

Commit: `0335d68` (`Set German as the app and platform language`).

- `lib/main.dart`: festes `Locale('de')`, nur Deutsch als unterstützte Oberflächensprache, alle drei Global-Delegates für Material, Cupertino und Widgets. Die gewählte Lernsprache bleibt unabhängig.
- `pubspec.yaml`, `pubspec.lock`: `flutter_localizations` aus dem Flutter-SDK ist jetzt eine direkte Abhängigkeit; die bereits transitiv vorhandene Version bleibt gleich.
- `ios/Runner.xcodeproj/project.pbxproj`: `developmentRegion = de`, `knownRegions = (de, Base)`.
- `ios/Runner/Info.plist`: `CFBundleLocalizations = [de]`; die bestehenden iPad-Orientierungen und Gerätefamilien bleiben unverändert.
- Android: `android:localeConfig` verweist auf das neue `android/app/src/main/res/xml/locales_config.xml` mit `de`. Die deutschen Flutter-Systemtexte gelten auch unter Android; auf Android 13+ wird die unterstützte App-Sprache zusätzlich dem System gemeldet.
- `test/app_locale_test.dart`: tatsächliche App-Wurzel bei englischer Gerätesprache, deutsche Material-/Cupertino-Zwischenablagebeschriftung, Zurück-Tooltip, Tausenderpunkt und Datum. Das SDK übersetzt „Paste“ mit „Einsetzen“. Keine bestehenden Tests angepasst.
- `docs/code-map.md`: Sprachkonfiguration und Prüfpfad ergänzt.

Die vorhandenen eigenen Datumsanzeigen verwenden weiterhin `formatDateDe`; Preise kommen weiterhin fertig formatiert aus dem Store. Es wurde kein globales `Intl.defaultLocale` gesetzt. Material-Systemformate wechseln beabsichtigt zu Deutsch, beispielsweise `1.234` und `12. März 2027`.

Prüfung:

```text
No issues found! (ran in 8.9s)
02:19 +1147 ~9: All tests passed!
Formatted 2 files (0 changed) in 0.04 seconds.
ios/Runner/Info.plist: OK
ios/Runner.xcodeproj/project.pbxproj: OK
iPad orientations unchanged; CFBundleLocalizations: ['de']
```

GitNexus wurde nach einem veralteten, inkonsistenten MCP-Ergebnis vollständig neu aufgebaut. Die frische CLI-Abfrage bindet den richtigen Projektordner und bewertet `SprachApp` mit `LOW`; Quelltextprüfung bestätigt App-Start, Browser-Vorschau und App-Wurzeltests als Verbraucher. Der Änderungscheck meldet niedrige Auswirkungen. Die CRLF-Zeilenenden bestehender Dart-Dateien werden erhalten.

Nach deinem nächsten Upload: App Store Connect → Apps → Linglossa → TestFlight → iOS → passende Version und Build öffnen → „Build Metadata“/„Build-Metadaten“. Dort die vom Build erkannten Lokalisierungen/Sprachen auf Deutsch prüfen. Die primäre Sprache der Store-Beschreibung ist eine getrennte Metadaten-Einstellung. Nach Veröffentlichung zusätzlich auf der öffentlichen Produktseite unter Informationen → Sprachen prüfen. Der Upload und die Anzeige in App Store Connect wurden hier nicht durchgeführt bzw. bestätigt. [Apples Anleitung zu Build-Metadaten](https://developer.apple.com/help/app-store-connect/manage-builds/view-builds-and-metadata/), [Flutter-Lokalisierung](https://docs.flutter.dev/ui/internationalization), [Android-App-Sprachen](https://developer.android.com/guide/topics/resources/app-languages).

## Teil 2 – Systembewertung nach Übungserfolg

Nur der echte Übungsabschluss aktiviert die Anfrage. Sie wartet auf das Ende der Abschlussanimation; bei reduzierter Bewegung reicht der erste fertig dargestellte Frame. Eine erste abgeschlossene Übung wird ausschließlich lokal vermerkt. Ab einer weiteren Sitzung und mindestens drei aktiven Lerntagen darf ein erreichtes Tagesziel oder ein Wochenstern eine Anfrage auslösen. Es gibt weder Vorabfrage noch Bewertungsknopf, Paywall-Auslöser oder Filter nach Zufriedenheit.

Die reine Funktion `shouldRequestReview` in `lib/domain/review_request.dart` prüft alle Bedingungen, mindestens 120 Tage Abstand und maximal drei Anfragen in einem rollierenden 365-Tage-Fenster. Auch eine zurückgestellte Uhr kann die Sperre nicht umgehen. `ReviewRequestService` serialisiert Aufrufe, entdoppelt Sitzungen und speichert den Zeitpunkt vor dem nativen API-Aufruf in `ui/review_requests.json`. Die Historie gilt geräteweit über Sprach- und Kontowechsel hinweg und wird nicht synchronisiert. Speicher-/Storefehler unterbrechen das Lernen nicht; ein fehlgeschlagener Schreibvorgang verhindert die Anfrage.

Dateien: `lib/domain/review_request.dart`, `lib/data/review/native_review_gateway.dart`, `lib/presentation/review/review_request_service.dart`, `lib/presentation/providers/review_request_provider.dart`, `lib/screens/completion/practice_completion_screen.dart`, `test/review_request_test.dart`, `test/review_completion_test.dart`, `pubspec.yaml`, `pubspec.lock`, automatisch erzeugter macOS-Plugin-Registrant sowie diese Dokumentation und `docs/code-map.md`.

Neue Abhängigkeiten: `in_app_review 2.0.12`, transitiv `in_app_review_platform_interface 2.0.5`. Die Plattformabfrage erlaubt ausschließlich iOS und Android; auch der automatisch erzeugte macOS-Registrant aktiviert deshalb dort keine Bewertungsabfrage.

15 neue Tests: reine Regel, Erstnutzung, Ziel-/Streak-Auslöser, Zeitgrenzen, Jahreslimit, Neustart/Persistenz, Konkurrenz/Entdoppelung, Fehler, fehlender Store, Web/Desktop, verlassener Bildschirm, echter Abschluss mit/ohne Animation und Vorschau. Keine bestehenden Tests oder Goldens geändert.

```text
No issues found! (ran in 10.8s)
02:36 +1162 ~9: All tests passed!
Formatted 7 files (0 changed) in 0.05 seconds.
```

Die sichtbare Darstellung des Systemdialogs entscheidet iOS/Android. Tests belegen die Aufrufe mit Fake, nicht die tatsächliche Anzeige auf dem Gerät. Unter TestFlight zeigt `requestReview()` keinen Dialog; ein lokaler Entwicklungsbuild kann ihn bei einem zulässigen API-Aufruf zeigen. Die App-eigenen Schutzregeln gelten auch dort. [Paketdokumentation und Testbedingungen](https://pub.dev/packages/in_app_review).

GitNexus hatte vor dem Eingriff für `PracticeCompletionScreen` `HIGH` gemeldet: echte Übung, Vorschauen und Shell-Einstiege teilen den Screen. Deshalb ist die neue Wirkung ausschließlich auf dem echten Übungsweg aktiviert; die Vorschau bleibt durch einen eigenen Test abgesichert.

## Noch offen

Benachrichtigungen, Widgets, Barrierefreiheits-Audit und Geräteinstallation folgen in eigenen Teilen.
