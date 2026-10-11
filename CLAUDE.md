# CLAUDE.md

Guidance for Claude Code and other agentic assistants in this repository.

## Project State

Sprachapp is an editorial, reading-first language learning app for iOS and Android (Flutter, Dart `^3.13.2`). v1: adult German speakers learning English through stories and spaced-repetition sentence decks.

Implemented today (placeholder data, in-memory stores): home dashboard, notched bottom bar, deck library/details/practice session, "Inhalte" tab (gap texts, listening and grammar exercises, grammar rules), story library and reader with word lookup, sentence translation and simulated narration, "Wortliste" tab, and pure-Dart domain code in `lib/domain/`. Widget and accessibility tests live in `test/widget_test.dart`.

`lib/models/` and `lib/screens/` are the current state and will be migrated to the target layers (`ARCHITECTURE.md`). Platform folders (`android/`, `ios/`, `macos/`, `linux/`, `windows/`) are generated; do not hand-edit them.

## Commands

Run from the repository root. Flutter commands are identical on both systems.

Windows (PowerShell) and macOS (Terminal):

```
flutter pub get      # after editing pubspec.yaml
flutter run          # device or simulator, 'r' = hot reload
flutter analyze      # flutter_lints, see analysis_options.yaml
flutter test         # all tests
flutter test test/widget_test.dart
flutter build apk    # Android (Windows and macOS)
flutter build ios    # iOS (macOS only)
```

Shell-specific helpers:

| Task | Windows (PowerShell) | macOS (Terminal) |
|---|---|---|
| List files | `Get-ChildItem` | `ls` |
| Search text | `Select-String -Path *.md -Pattern "x"` | `grep -rn "x" *.md` |
| Count lines | `(Get-Content f -Encoding UTF8).Count` | `wc -l f` |
| Set variable | `$env:NAME = "value"` | `export NAME=value` |

Tool setup and logins: `docs/setup.md`.

> **Testing note:** widget tests must disable Google Fonts network requests:
> `setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);`

## Mandatory Rules

1. **No keys**: Never commit API keys or secrets to the repository or embed them in the app. Pipeline and tools read credentials from local login (ADC) or environment variables.
2. **No direct AI calls from the client**: The client never calls an AI provider directly. Runtime AI only via Supabase Edge Functions that call Vertex AI, for user-generated content (see `PRODUCT.md`).
3. **AI access: Vertex AI only** (project `sprachlernapp-510508`, see `docs/pipeline.md`, `docs/backend.md`).
4. **Derived counters**: The four vocabulary counts (*Verfügbare Wiederholungen*, *Wörter im Aufbau*, *Wörter gemeistert*, *Noch nicht angezeigt*) are always derived from card state and due dates, never stored as columns (`docs/srs.md`).
5. **Source of truth**: Product logic is governed by `PRODUCT.md`, visuals and accessibility by `DESIGN.md`. If code contradicts them, the documentation wins; do not edit the documentation to match a code regression, record the discrepancy and align the code.
6. **Shell**: WENN ein Befehl Shell-spezifisch ist → NIE nur Bash angeben; Windows (PowerShell) und macOS getrennt nennen. Entwicklung läuft auf Windows und macOS.
7. **Verification**: Nie "fertig" ohne gezeigten Output (Test, Analyse, Befehlsausgabe).
8. **Domain purity**: `lib/domain/` has no Flutter imports (`dart:ui`, `package:flutter/...`).

## Where to look

| Topic | File |
|---|---|
| Product rules, modes, answers, open decisions | `PRODUCT.md` |
| Colors, typography, layout, accessibility | `DESIGN.md` |
| Layers, data flow, folders | `ARCHITECTURE.md` |
| Boxes, intervals, queues, counters, review log | `docs/srs.md` |
| Content tables, IDs, tombstones | `docs/content-schema.md` |
| Supabase, Edge Functions, Vertex AI in the backend | `docs/backend.md` |
| Content pipeline, QA, costs, TTS | `docs/pipeline.md` |
| Tools, logins, secrets | `docs/setup.md` |
| Current status, open points | `NEXTSTEPS.md` |

<!-- gitnexus:start -->
# GitNexus — Code Intelligence

This project is indexed by GitNexus as **sprachlernapp** (14302 symbols, 30776 relationships, 393 execution flows).

> Index stale? Run `node .gitnexus/run.cjs analyze --index-only` from the project root — it auto-selects an available runner. No `.gitnexus/run.cjs` yet? Bootstrap with `npx`, `bunx`, or `pnpm dlx` — e.g. `bunx gitnexus@latest analyze` (npm 11 npx crash; #1939).

## Always Do

- **MUST run impact before editing.** Use `impact({target: "symbolName", direction: "upstream"})` or `node .gitnexus/run.cjs impact "symbolName" --direction upstream --repo .`; report callers, processes, and risk. Never substitute grep for graph analysis.
- **MUST analyze graph changes before committing.** Use `detect_changes({scope: "all"})` (MCP) or `node .gitnexus/run.cjs detect-changes --scope all --repo .` (CLI fallback). `partial: true` or `truncated: true` is not a clean check — a zero means unseen, not unaffected; re-run it. For regression review: `detect_changes({scope: "compare", base_ref: "main"})` or `node .gitnexus/run.cjs detect-changes --scope compare --base-ref "main" --repo .`.
- MUST warn on HIGH/CRITICAL `risk` pre-edit; never use `riskSharedAxes` to waive a HIGH/CRITICAL `risk` warning. Compare File/symbol: MCP File omits axes; Graph-RAG expands File.
- **MUST treat `risk: UNKNOWN` as unresolved, not as low.** An empty caller set is not evidence the symbol is unused — it can also mean the callers are not resolvable by the index (plain-object property access, dynamic dispatch, cross-language calls). `impact` pairs `UNKNOWN` with a `riskNote` saying so. Confirm with a text search before treating the symbol as safe to change or delete; do not proceed on the strength of a zero.
- **MUST use `query({search_query: "concept"})` for concepts/flows, `context({name: "symbolName"})` for a named symbol, or `impact` for blast radius, on read-only callers, dependencies, imports, or execution flow.** Graph first; text search only for empty/`UNKNOWN`/literals.
- For security review, `explain({target: "fileOrSymbol"})` lists taint findings (source→sink flows; needs `analyze --pdg`).

## Never Do

- NEVER edit a function, class, or method before MCP/CLI impact analysis.
- NEVER ignore HIGH or CRITICAL risk warnings from impact analysis, and never read `UNKNOWN` as an all-clear — it means the walk could not answer, which is the one verdict that requires confirming by other means.
- NEVER rename symbols with find-and-replace — use `rename` which understands the call graph.
- NEVER commit before MCP/CLI graph change analysis.

## Resources

| Resource | Use for |
| --- | --- |
| `gitnexus://repo/sprachlernapp/context` | Codebase overview, check index freshness |
| `gitnexus://repo/sprachlernapp/clusters` | All functional areas |
| `gitnexus://repo/sprachlernapp/processes` | All execution flows |
| `gitnexus://repo/sprachlernapp/process/{name}` | Step-by-step execution trace |

## CLI

| Task | Read this skill file |
| --- | --- |
| Understand architecture / "How does X work?" | `.claude/skills/gitnexus-exploring/SKILL.md` |
| Blast radius / "What breaks if I change X?" | `.claude/skills/gitnexus-impact-analysis/SKILL.md` |
| Trace bugs / "Why is X failing?" | `.claude/skills/gitnexus-debugging/SKILL.md` |
| Rename / extract / split / refactor | `.claude/skills/gitnexus-refactoring/SKILL.md` |
| Tools, resources, schema reference | `.claude/skills/gitnexus-guide/SKILL.md` |
| Index, status, clean, wiki CLI commands | `.claude/skills/gitnexus-cli/SKILL.md` |

<!-- gitnexus:end -->
