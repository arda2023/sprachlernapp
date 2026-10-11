# AGENTS.md

Guidance for Codex and other agents. Same mandatory rules as `CLAUDE.md`; details live in the files listed below, not here.

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

- Product rules: `PRODUCT.md`. Visuals and accessibility: `DESIGN.md`.
- Layers and data flow: `ARCHITECTURE.md`.
- Spaced repetition: `docs/srs.md`. Content schema: `docs/content-schema.md`.
- Backend: `docs/backend.md`. Pipeline: `docs/pipeline.md`. Setup: `docs/setup.md`.
- Status and open points: `NEXTSTEPS.md`.

## Commands

Flutter commands (`flutter pub get`, `flutter analyze`, `flutter test`) are identical on Windows (PowerShell) and macOS (Terminal). More in `CLAUDE.md`.

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
