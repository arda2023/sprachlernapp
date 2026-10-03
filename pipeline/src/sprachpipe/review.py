"""Review list (review.csv) and run report (run_report.md) of a generate run."""

from __future__ import annotations

import csv
from collections import Counter
from pathlib import Path

REVIEW_COLUMNS = ["Form", "Bedeutung", "Satz", "Übersetzung", "Linter-Befunde",
                  "Blindtest-Ergebnis", "qa_status", "Modellantwort bei Abweichung",
                  "bedeutung_check", "verworfen_grund"]


def review_rows(cards: list[dict]) -> list[dict]:
    """One row per generated sentence (every attempt)."""
    rows = []
    for card in cards:
        for slot in card["slots"]:
            for a in slot:
                rows.append({
                    "Form": card["form"],
                    "Bedeutung": f"{card['sense_key']} ({card['gloss_de']})",
                    "Satz": a["text"],
                    "Übersetzung": a["translation_de"],
                    "Linter-Befunde": " | ".join(a["lint"]),
                    "Blindtest-Ergebnis": a["blind"] or "",
                    "qa_status": a["qa_status"],
                    "Modellantwort bei Abweichung":
                        a["blind_answer"] if a["discard_reason"] == "Blindtest" else "",
                    "bedeutung_check": a.get("meaning_check") or "",
                    "verworfen_grund": a.get("discard_reason") or "",
                })
    return rows


def write_review_csv(cards: list[dict], path: str | Path) -> Path:
    """UTF-8 with BOM and ';' so Excel (German locale) shows umlauts and columns."""
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", newline="", encoding="utf-8-sig") as f:
        w = csv.DictWriter(f, fieldnames=REVIEW_COLUMNS, delimiter=";")
        w.writeheader()
        w.writerows(review_rows(cards))
    return path


def _ledger_rows(ledger: Path) -> list[dict]:
    if not ledger.exists():
        return []
    with open(ledger, newline="", encoding="utf-8") as f:
        return list(csv.DictReader(f))


def write_run_report(path: str | Path, *, cards: list[dict], skipped: list[str],
                     ledger: str | Path, packed_cards: int, info: dict,
                     aborted: str | None = None) -> Path:
    path = Path(path)
    attempts = [a for c in cards for s in c["slots"] for a in s]
    finals = [s[-1] for c in cards for s in c["slots"]]
    status = Counter(a["qa_status"] for a in finals)
    rule_fail = Counter(r for a in attempts for r in a["lint_rules"])
    blinded = [a for a in attempts if a["blind"]]
    blind = Counter(a["blind"] for a in blinded)
    discarded = Counter(a["discard_reason"] for a in attempts if a.get("discard_reason"))
    from .quality import overused_lemmas
    overused = overused_lemmas(cards)
    rows = _ledger_rows(Path(ledger))
    tok = {k: sum(int(r[k]) for r in rows)
           for k in ("input_tokens", "output_tokens", "thinking_tokens")}
    usd = sum(float(r["usd"]) for r in rows)
    by_step: dict[str, list] = {}
    for r in rows:
        s = by_step.setdefault(f"{r['step']} ({r['model']})", [0, 0.0])
        s[0] += 1
        s[1] += float(r["usd"])

    def pct(n, d):
        return f"{n}/{d} ({100 * n / d:.0f} %)" if d else "0/0"

    lines = [f"# Run report: generate {info.get('forms', '')}", ""]
    if aborted:
        lines += [f"**Abgebrochen:** {aborted}", ""]
    lines += [
        f"- Modelle: Generierung `{info.get('generate_model')}` ({info.get('generate_thinking')}), "
        f"Blindtest `{info.get('blindtest_model')}` ({info.get('blindtest_thinking')})",
        f"- Prompts: {', '.join(info.get('prompt_versions', []))}",
        f"- Budget: {info.get('max_usd'):.2f} USD",
        "",
        "## Umfang",
        "",
        f"- Formen: {info.get('n_forms', 0)}, übersprungen: {len(skipped)}",
        f"- Karten (Form + Bedeutung): {len(cards)}, im Pack: {packed_cards}",
        f"- Satzkandidaten: {len(finals)} (ok {status['ok']}, failed {status['failed']}); "
        f"Satzversuche insgesamt: {len(attempts)}",
        "",
        "## Durchfallquoten je Regel (alle erzeugten Sätze)",
        "",
        "| Regel | Fehler |",
        "|---|---|",
    ]
    for rule in sorted(rule_fail) or []:
        lines.append(f"| Linter `{rule}` | {pct(rule_fail[rule], len(attempts))} |")
    lines += [f"| Blindtest failed | {pct(blind['failed'], len(blinded))} |",
              "", "## Verworfene Sätze je Grund", "",
              "| Grund | Anzahl |", "|---|---:|"]
    for reason in ("Linter-Regel", "Blindtest", "Bedeutung", "Duplikat"):
        n = sum(v for k, v in discarded.items() if k == reason or k.startswith(reason + ":"))
        lines.append(f"| {reason} | {n} |")
    lines += ["", "## Warnungen", ""]
    lines += [f"- {c['form']} ({c['sense_key']}): "
              f"{sum(1 for a in c['accepted'] for f in a['lint'] if f.startswith('warn:i+1:'))} i+1-Verstöße"
              for c in cards]
    lines += ["- keine Karten"] if not cards else []
    lines += [f"- Häufiges Inhaltswort `{word}`: {count}/{total} Pack-Sätze"
              for word, count, total in overused]
    lines += ["- keine übernutzten Inhaltswörter"] if not overused else []
    lines += [
              "", "## Kosten (ledger.csv)", "",
              f"- Aufrufe: {len(rows)}",
              f"- Token: Eingabe {tok['input_tokens']}, Ausgabe {tok['output_tokens']}, "
              f"Denken {tok['thinking_tokens']}",
              f"- Gesamt: {usd:.4f} USD",
              f"- Pro Karte: {usd / len(cards):.4f} USD" if cards else "- Pro Karte: -",
              "", "| Schritt | Aufrufe | USD |", "|---|---|---|"]
    for step, (n, u) in sorted(by_step.items()):
        lines.append(f"| {step} | {n} | {u:.4f} |")
    lines += ["", "## Übersprungene Formen", ""]
    lines += [f"- {s}" for s in skipped] or ["- keine"]
    incomplete = [f"{c['form']} ({c['sense_key']})" for c in cards if not c.get("packed")]
    lines += ["", "## Karten nicht im Pack (weniger als 3 ok-Sätze)", ""]
    lines += [f"- {s}" for s in incomplete] or ["- keine"]
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return path
