# NEXTSTEPS
## Stand 19.10.2026 · nächste Produktphase
- Stapelphase beendet; nächste Arbeit: UI, Lernalgorithmus und Funktionen. Keine neuen Stapel, Reservierungen oder Sätze aus dem Haiku-Auftrag.
- Haiku-Direktzugang lokal ergänzt: provider anthropic, claude-haiku-5-5, vorhandenes SDK 1.15.0, gleiche generate_json-Aufrufer; Vertex explizite Alternative, kein Fallback. Nur Redaktion ohne echte Nutzerdaten, keine EU-only-Zusage.
- KI-Ist: fehlende App-Wort-/Satzübersetzungen lokal über authentifizierte Supabase Functions → Anthropic claude-haiku-5-5 implementiert; explizite Bestätigung, Packübersetzungen offline, keine EU-only-Zusage/kein Fallback. sentence-check bleibt Entwurf.
- Offline: Pipeline 668 PASS/1 bestehender Skip/19 Subtests, pip check Exit 0; echte SDK-Requests lokal gemockt, bestehende Vertex-Verträge erhalten. Code/Config/Preisaufrufer/Tests und gezielte Regeln/Doku geändert; docs/haiku-direct-api-setup.md.
- Kosten: keine gemessene Einsparung/Modellqualität. Unbekannte Nutzung konservativ erfasst; lokale Reservierung ist keine garantierte Anbieterrechnungsgrenze.
- Python-Live: Nutzer meldet 205 Input/8 Output erfolgreich; kein eigener App-Nachweis. Runtime lokal: Deno 32 PASS, Flutter-Gruppe 82 PASS + erweiterte neue Tests 14 PASS, SQL/PGlite PASS; Analyse nur alter avoid_print. Details/Abnahme: docs/haiku-runtime-translations.md; frühere ADC-Nachweise: docs/haiku-live-setup.md.
- Inhaltsladen: Lifecycle-Fix 0d5dee9 erhalten; Form-/Tokenabfragen gebündelt, Home ohne Satzvollbeladung. iPhone Profile: pt-BR→en weiterhin 6,90 s, Home-Projektion 3,31→1,28 s, erste Übung 66 ms; Nutzer kaum Unterschied, <1-s-Ziel offen. Nächster Schritt: Zielpack-Öffnung intern messen. docs/content-loading-performance.md.
## Portugiesisch und aktive Inhalte · relevante Vorbefunde
- Paket 2 lokal abgeschlossen: Sprachwahl en/pt-BR, Gate/Rollback, getrennte Updatefristen und Akzentpolicy; Lernstände erhalten. docs/portuguese-package-2.md.
- Übernommene Prüfung Paket 2: UI 2+13, Sprache/Installation 14, Gesamt 380 PASS/5 bestehende Skips, Realpack 1/12s, Stage Exit 0; Analyse Exit 1 nur Alt-avoid_print.
- Nutzer bestätigt portugiesischen Ablauf bis zur Mobile-App als funktionierend; Nutzerbericht, keine neue eigene Geräteprüfung. Sprachqualität/weitere Freigaben bleiben gesondert.
- Paket 1: pt-BR-editorial-v1 mit modellfreiem Tokenizer/eigenem Kanal; bestehender Seed und leere 20-Ziel-Vorlage erhalten, manuelle BR-Prüfung offen. docs/portuguese-package-1.md.
- Sprachplan/Authoringvertrag: docs/portuguese-language-rollout-plan.md und docs/portuguese-authoring-contract-v1/FORMAT.md; kein neuer Inhaltsauftrag durch diesen Plan.
- Englische chitchat-Korrektur laut Nutzer funktionsfähig; keine neue eigene Geräteprüfung. Historische Reviews/SRS erhalten; docs/content-update-active-context-fix.md.
- Story-Originalsatz bevorzugen; 1–2 Wörter benötigen redigierten Ersatz, sonst begründete Ausnahme; feste Satz-/Identitätsbindung erhalten. docs/story-single-sentence-v1.md.
## Erhaltene offene Punkte und Historie
- Publizierte Basis/Editor: bestehende Uploadanker und Entwürfe erhalten; überholte Finalize-/Reupload-Anweisungen nicht wiederholen. docs/content-editor-initial-release.md, docs/content-published-base-adoption.md.
- Aktuelle Veröffentlichungs-/Streamingentscheidungen und noch offene Cloud-/Geräteprüfungen stehen in diesen Berichten; keine neue Veröffentlichung oder Deploymentfreigabe.
- Historische Bestandszahlen, 137 Provenienzlücken, sechs Sprachgrenzfälle und weitere Glossenkuration bleiben dokumentiert; keine neue Bestandsmessung. docs/context-quality-applied-v1.md.
- UI-Werte 40/30 px, Padding 16/6, Fehlerfeedback und Nutzeränderungen erhalten; frühere Nachweise/Commitgrenzen: docs/practice-error-feedback.md.
- Passwortlogin laut vorherigem Nutzerbericht funktionsfähig; keine Auth-/Rollenänderung. docs/content-password-login.md.
- Vollständiger vorheriger NEXTSTEPS-Text: Gitstand 6deba380042578a5cee96af24988db9d713e02ba; relevante Altverweise zusätzlich im Haiku-Plan.
- Historisch Paket A: Pythonanschluss, Konfiguration, Abhängigkeiten, Offline-Tests/Doku. Jetzt zusätzlich begrenzte Runtime-Übersetzung; kein Deployment/Push. Nächste Nutzeraktion: ANTHROPIC_API_KEY als Supabase-Secret, danach geprüfte Migration, zwei Functions und iPhone-Update gemäß Runtime-Bericht; echte App-Abnahme offen.
