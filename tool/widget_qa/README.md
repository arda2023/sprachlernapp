# Native Widget-QA

Der Renderer kompiliert die drei Produktionsdateien aus `ios/LinglossaWidgets`, registriert die dortigen Fonts und erzeugt echte SwiftUI-Renderings auf einem separaten iPhone-Simulator. Er ändert kein Xcode-Projekt und nutzt nur lokales Ad-hoc-Signing. Alle Build-Artefakte landen im bereits ignorierten `build/widget_qa`.

macOS mit Xcode:

```text
python3 tool/widget_qa/build_and_render.py
swift test --package-path ios
```

Ein anderes Ausgabeverzeichnis lässt sich mit `--output <Verzeichnis>` angeben; `--simulator <UDID>` wählt einen bestehenden Simulator. Standardausgabe: `docs/store-readiness/widgets`.

Windows: Das native iOS-Simulator-Rendering ist nicht verfügbar; diesen Schritt auf dem macOS-Entwicklungsrechner ausführen. Flutter-Tests bleiben davon unabhängig.

Enthalten sind 24 Einzelbilder (3 Größen × 4 Zustände × 2 Farbschemata), 8 Zustandsbögen, 2 vollständige Kontaktbögen, 12 zusätzliche Accessibility-Renderings, 6 Prüfungen des akzentuierten Rendering-Zweigs und ein Simulator-Bildschirmabzug. `manifest.json` nennt Zeitpunkt und Render-ID, damit alte Ergebnisse nicht mit einem neuen Lauf verwechselt werden.

Der produktive Typcheck verwendet iOS 15. Nur die QA-App benötigt iOS 16 für `ImageRenderer`. Die getönten Vorschauen prüfen den Codezweig; SpringBoards klare/getönte Glasdarstellung, echte Widget-Deeplinks und die App-Group-Integration müssen am eingebetteten Widget geprüft werden. Die Testdaten sind fiktiv; das Cover stammt aus dem bestehenden Katalog.

`WidgetQA.swift` gehört ausschließlich zum QA-Build, nicht in das Widget-Extension-Target. Die Swift-Package-Tests kompilieren ausschließlich `WidgetSnapshot.swift`; andere Extension-Dateien und Ressourcen werden ausgeschlossen.
