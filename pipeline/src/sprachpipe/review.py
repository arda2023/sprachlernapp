"""Review list (review.csv) and run report (run_report.md) of a generate run."""

from __future__ import annotations

import csv
import json
from collections import Counter
from pathlib import Path

REVIEW_COLUMNS = ["Form", "Bedeutung", "Satz", "Übersetzung", "Linter-Befunde",
                  "Blindtest-Ergebnis", "qa_status", "Modellantwort bei Abweichung",
                  "bedeutung_check", "Prüfwortart", "Übersetzungsprüfung",
                  "Sprachprüfung", "Prüfbegründung", "verworfen_grund", "Blindtest-Alternativen (Modellbefund)",
                  "Alternativkandidaten", "Alternativprüfung", "Gültige Alternativen"]

# attempt["blind"] → report label; "passed" is only the exact target form.
BLIND_LABELS = {"passed": "Zielform exakt", "confirmed_alternative": "Hauptantwort als Alternative bestätigt",
                "unconfirmed": "Hauptantwort nicht bestätigt",
                "other": "Andere Hauptantwort (nicht geprüft)", "failed": "Leer oder ungültig"}


def _checked(a: dict) -> str:
    return json.dumps([{"candidate": r["candidate"], "sentence": r["sentence"],
                        "status": r["status"], "reason": r["reason"]}
                       for r in a.get("alternative_check") or []], ensure_ascii=False)


def review_rows(cards: list[dict]) -> list[dict]:
    """One row per generated sentence (every attempt)."""
    rows = []
    for card in cards:
        for slot in card["slots"]:
            for a in slot:
                checked = a.get("meaning_check_result") or {}
                reasons = a.get("discard_reasons") or ([a["discard_reason"]]
                                                         if a.get("discard_reason") else [])
                rows.append({
                    "Form": card["form"],
                    "Bedeutung": f"{card['sense_key']} ({card['gloss_de']})",
                    "Satz": a["text"],
                    "Übersetzung": a["translation_de"],
                    "Linter-Befunde": " | ".join(a["lint"]),
                    "Blindtest-Ergebnis": a["blind"] or "",
                    "qa_status": a["qa_status"],
                    "Modellantwort bei Abweichung":
                        a["blind_answer"] if (a["discard_reason"] == "Blindtest" or a["blind"] in
                                              ("other", "unconfirmed", "confirmed_alternative")) else "",
                    "Blindtest-Alternativen (Modellbefund)": json.dumps(a.get("blind_alternatives", []), ensure_ascii=False),
                    "Alternativkandidaten": json.dumps(a.get("alternative_candidates", []), ensure_ascii=False),
                    "Alternativprüfung": _checked(a),
                    "Gültige Alternativen": json.dumps(a.get("valid_alternatives", []), ensure_ascii=False),
                    "bedeutung_check": a.get("meaning_check") or "",
                    "Prüfwortart": checked.get("observed_pos") or "",
                    "Übersetzungsprüfung": ("ok" if checked.get("translation_ok") is True else
                                           "fehlerhaft" if checked.get("translation_ok") is False else ""),
                    "Sprachprüfung": ("ok" if checked.get("language_ok") is True else
                                      "fehlerhaft" if checked.get("language_ok") is False else ""),
                    "Prüfbegründung": checked.get("reason") or "",
                    "verworfen_grund": "; ".join(reasons),
                })
    return rows


def write_review_csv(cards: list[dict], path: str | Path) -> Path:
    """UTF-8 with BOM and comma delimiter."""
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", newline="", encoding="utf-8-sig") as f:
        w = csv.DictWriter(f, fieldnames=REVIEW_COLUMNS, delimiter=",")
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
    discarded = Counter()
    for attempt in attempts:
        for reason in (attempt.get("discard_reasons") or
                       ([attempt["discard_reason"]] if attempt.get("discard_reason") else [])):
            discarded[reason] += 1
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
        f"- Nicht im Pack: {len(cards) - packed_cards}; Pack-Anteil: {pct(packed_cards, len(cards))}",
        f"- Satzkandidaten: {len(finals)} (ok {status['ok']}, failed {status['failed']}, "
        f"ungenutzt {status['unused']}); "
        f"Satzversuche insgesamt: {len(attempts)}",
        "",
        "## Durchfallquoten je Regel (alle erzeugten Sätze)",
        "",
        "| Regel | Fehler |",
        "|---|---|",
    ]
    for rule in sorted(rule_fail) or []:
        lines.append(f"| Linter `{rule}` | {pct(rule_fail[rule], len(attempts))} |")
    lines += [f"| Blindtest nicht bestanden (nicht bestätigt, leer oder ungültig) | "
              f"{pct(blind['unconfirmed'] + blind['failed'], len(blinded))} |",
              "", "## Blindtest-Ergebnisse (alle Versuche)", "",
              "| Ergebnis | Anzahl |", "|---|---:|"]
    lines += [f"| {label} (`{key}`) | {blind[key]} |" for key, label in BLIND_LABELS.items()]
    checks = [r for a in attempts for r in a.get("alternative_check") or []]
    check_status = Counter(r["status"] for r in checks)
    in_pack = sum(len(a.get("valid_alternatives", [])) for c in cards if c.get("packed")
                  for a in c["accepted"])
    lines += ["", "## Alternativen (alle Versuche, einschließlich ersetzter)", "",
              f"- Kandidaten geprüft: {check_status['confirmed'] + check_status['rejected']}",
              f"- bestätigt: {check_status['confirmed']}, abgelehnt: {check_status['rejected']}, "
              f"ohne gültiges Urteil (ungültige Prüfantwort): {check_status['invalid']}",
              f"- Prüfaufrufe: {sum(1 for a in attempts if a.get('alternative_check'))}",
              f"- In valid_alternatives des Packs: {in_pack}",
              "", "## Verworfene Sätze je Grund", "",
              "| Grund | Anzahl |", "|---|---:|"]
    for reason in ("Linter-Regel", "Blindtest", "Sprache", "Bedeutung", "Wortart", "Übersetzung",
                   "Ungültige Prüfantwort", "Duplikat"):
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
              (f"- Kosten je gepackter Karte: {usd / packed_cards:.4f} USD ({packed_cards} Karten im Pack)"
               if packed_cards else "- Kosten je gepackter Karte: nicht berechenbar (0 Karten im Pack)"),
              "", "| Schritt | Aufrufe | USD |", "|---|---|---|"]
    for step, (n, u) in sorted(by_step.items()):
        lines.append(f"| {step} | {n} | {u:.4f} |")
    lines += ["", "## Übersprungene Formen", ""]
    lines += [f"- {s}" for s in skipped] or ["- keine"]
    incomplete = [c for c in cards if not c.get("packed")]
    lines += ["", "## Karten nicht im Pack (kein einzelner ok-Satz)", ""]
    if not incomplete:
        lines.append("- keine")
    for card in incomplete:
        lines.append(f"- {card['form']} ({card['sense_key']}): "
                     f"{len(card['accepted'])}/1 angenommene Sätze")
        discarded_attempts = [a for slot in card["slots"] for a in slot
                              if a.get("discard_reason") or a.get("discard_reasons")]
        if not discarded_attempts:
            lines.append("  - keine Verwerfungen protokolliert (Abbruch oder Pack-Kollision)")
        for a in discarded_attempts:
            answer = (f"; Blindtest-Antwort: {a['blind_answer']}"
                      if a.get("blind_answer") is not None else "")
            reasons = a.get("discard_reasons") or [a["discard_reason"]]
            detail = (f"; Prüfung: {a['meaning_check_result']['reason']}"
                      if a.get("meaning_check_result") else "")
            alternatives = ("; Alternativen (Modellbefund): " + json.dumps(a["blind_alternatives"], ensure_ascii=False)
                            if a.get("blind_alternatives") else "")
            checked = ("; Alternativprüfung: " + _checked(a)) if a.get("alternative_check") else ""
            lines.append(f"  - {', '.join(reasons)}{answer}{detail}{alternatives}{checked}; Satz: {a['text']}")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return path
