# NEXTSTEPS
## Stand 18.10.2026 · nächste Produktphase
- Stapelphase beendet; nächste Arbeit: UI, Lernalgorithmus und Funktionen. Keine neuen Stapel, Reservierungen oder Sätze aus dem Haiku-Auftrag.
- Zur Abnahme: docs/haiku-migration-plan.md; Inventar, offizielle Quellen, Kostenannahmen, exakte Dateien und Prüfkriterien. Noch keine Migration implementiert.
- KI-Ist: ausschließlich optionaler Python-Wrapper mit gemini-3.8-flash und gemini-2.5-flash; App liest lokale Übersetzungen. Drei Laufzeit-KI-Functions bisher Entwurf.
- Haiku-Vorschlag: claude-haiku-5-5 über bestehenden Vertex-Zugang, ausdrücklich EU-Multiregion eu; heutige Pipeline global. Keine Frankfurt-Einzelregionszusage.
- Kosten: niedrigere Listenpreise, aber keine vergleichbaren Haiku-Verbrauchs-/Qualitätsdaten und keine behauptete reale Einsparung. Freischaltung im Projekt ungeprüft.
- Nächster möglicher Auftrag: kleiner lokaler Wrapperumbau mit Fakeclienttests; Livevergleich erst separat, höchstens 48 Versuche/0,50 USD; kein Deployment für den Wrapper.
## Portugiesisch und aktive Inhalte · relevante Vorbefunde
- Paket 2 lokal abgeschlossen: Sprachwahl en/pt-BR, Gate/Rollback, getrennte Updatefristen und Akzentpolicy; Lernstände erhalten. docs/portuguese-package-2.md.
- Übernommene Prüfung Paket 2: UI 2+13, Sprache/Installation 14, Gesamt 380 PASS/5 bestehende Skips, Realpack 1/12s, Stage Exit 0; Analyse Exit 1 nur Alt-avoid_print.
- Testglyphbilder sind keine visuelle Geräteabnahme; Cloud-, Windows- und iPhone-Betrieb sowie Sprachfreigabe bleiben gesondert offen.
- Paket 1: pt-BR-editorial-v1 mit modellfreiem Tokenizer/eigenem Kanal; bestehender Seed und leere 20-Ziel-Vorlage erhalten, manuelle BR-Prüfung offen. docs/portuguese-package-1.md.
- Sprachplan/Authoringvertrag: docs/portuguese-language-rollout-plan.md und docs/portuguese-authoring-contract-v1/FORMAT.md; kein neuer Inhaltsauftrag durch diesen Plan.
- Aktiver chitchat-Kontext lokal korrigiert, historische Reviews/SRS erhalten; Geräteprüfung offen. docs/content-update-active-context-fix.md.
- Story-Originalsatz bevorzugen; 1–2 Wörter benötigen redigierten Ersatz, sonst begründete Ausnahme; feste Satz-/Identitätsbindung erhalten. docs/story-single-sentence-v1.md.
## Erhaltene offene Punkte und Historie
- Publizierte Basis/Editor: bestehende Uploadanker und Entwürfe erhalten; überholte Finalize-/Reupload-Anweisungen nicht wiederholen. docs/content-editor-initial-release.md, docs/content-published-base-adoption.md.
- Aktuelle Veröffentlichungs-/Streamingentscheidungen und noch offene Cloud-/Geräteprüfungen stehen in diesen Berichten; keine neue Veröffentlichung oder Deploymentfreigabe.
- Historische Bestandszahlen, 137 Provenienzlücken, sechs Sprachgrenzfälle und weitere Glossenkuration bleiben dokumentiert; keine neue Bestandsmessung. docs/context-quality-applied-v1.md.
- UI-Werte 40/30 px, Padding 16/6, Fehlerfeedback und Nutzeränderungen erhalten; frühere Nachweise/Commitgrenzen: docs/practice-error-feedback.md.
- Passwortlogin laut vorherigem Nutzerbericht funktionsfähig; keine Auth-/Rollenänderung. docs/content-password-login.md.
- Vollständiger vorheriger NEXTSTEPS-Text: Gitstand 6deba380042578a5cee96af24988db9d713e02ba; relevante Altverweise zusätzlich im Haiku-Plan.
- Dieser Auftrag ändert nur Dokumentation; Produktionspacks, Editorinhalte, echte user.db, Reviews, Signierung und Sprachfreigaben unberührt. Kein Push.
