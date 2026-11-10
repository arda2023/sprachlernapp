"""Build the Flutter app for Cloudflare Pages (Windows and macOS).

Only public Supabase client configuration enters the browser build. Never pass
an entire server environment file to Flutter's dart-define-from-file option.
"""
from __future__ import annotations

import argparse
import base64
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import urllib.request

ROOT = Path(__file__).resolve().parent.parent
SQLITE_URL = "https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-3.7.0/sqlite3.wasm"
SQLITE_SHA256 = "fbcd2e8214f9231ea961e1b7706a22dd1194cfbfe6f26f13841b5aa7a0be1a1f"
PUBLIC_NAMES = ("SUPABASE_URL", "SUPABASE_ANON_KEY")


def public_configuration(path: Path | None) -> dict[str, str]:
    source = json.loads(path.read_text(encoding="utf-8")) if path else {}
    values = {name: os.environ.get(name, source.get(name, "")) for name in PUBLIC_NAMES}
    if not all(isinstance(v, str) and v for v in values.values()):
        raise ValueError("SUPABASE_URL und SUPABASE_ANON_KEY fehlen. Umgebungsvariablen oder --config verwenden.")
    if not values["SUPABASE_URL"].startswith("https://"):
        raise ValueError("Der veröffentlichte Build benötigt eine HTTPS-Supabase-URL.")
    key = values["SUPABASE_ANON_KEY"]
    if key.startswith("sb_secret_"):
        raise ValueError("Server-Schlüssel dürfen nicht in den Browser-Build.")
    if key.startswith("ey"):
        payload = key.split(".")[1]
        role = json.loads(base64.urlsafe_b64decode(payload + "=" * (-len(payload) % 4))).get("role")
        if role != "anon":
            raise ValueError("Der Supabase-Schlüssel muss ein öffentlicher anon-Schlüssel sein.")
    elif not key.startswith("sb_publishable_"):
        raise ValueError("Nur ein öffentlicher Supabase-Publishable-/anon-Schlüssel ist erlaubt.")
    return values


def run(*args: str) -> None:
    subprocess.run(args, cwd=ROOT, check=True)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", type=Path, help="Lokale JSON-Konfiguration; nur öffentliche Supabase-Werte werden übernommen.")
    args = parser.parse_args()
    config = public_configuration(args.config)
    flutter = shutil.which("flutter")
    dart = shutil.which("dart")
    if not flutter or not dart:
        raise ValueError("Flutter und Dart müssen im PATH liegen.")
    wasm = ROOT / "web/sqlite3.wasm"
    if not wasm.exists() or hashlib.sha256(wasm.read_bytes()).hexdigest() != SQLITE_SHA256:
        data = urllib.request.urlopen(SQLITE_URL, timeout=60).read()
        if hashlib.sha256(data).hexdigest() != SQLITE_SHA256:
            raise ValueError("SQLite-WASM-Prüfsumme stimmt nicht überein.")
        wasm.write_bytes(data)
    for lang in ("en", "pt-BR", "nb", "it", "es"):
        directory = ROOT / "assets/content" / lang
        if not (directory / "content.sqlite").exists() or not (directory / "content.manifest.json").exists():
            raise ValueError(f"Inhaltspaket {lang} fehlt. Vor dem Build lokal bereitstellen (docs/web.md).")
    run(flutter, "pub", "get")
    run(dart, "compile", "js", "-O4", "tool/drift_worker.dart", "-o", "web/drift_worker.js")
    with tempfile.TemporaryDirectory(prefix="linglossa-web-") as directory:
        definitions = Path(directory) / "public.json"
        definitions.write_text(json.dumps(config), encoding="utf-8")
        run(flutter, "build", "web", "--release", "--no-pub", "--no-wasm-dry-run",
            "--no-web-resources-cdn", f"--dart-define-from-file={definitions}")
    output = ROOT / "build/web"
    for name in ("drift_worker.js.map", "drift_worker.js.deps"):
        (output / name).unlink(missing_ok=True)
    files = [p for p in output.rglob("*") if p.is_file()]
    oversized = [str(p.relative_to(output)) for p in files if p.stat().st_size > 25 * 1024 * 1024]
    if oversized:
        raise ValueError("Cloudflare Pages erlaubt höchstens 25 MiB je Datei: " + ", ".join(oversized))
    if len(files) > 20000:
        raise ValueError("Cloudflare-Pages-Dateilimit überschritten.")
    for required in ("index.html", "main.dart.js", "sqlite3.wasm", "drift_worker.js", "_headers", "_redirects"):
        if not (output / required).is_file():
            raise ValueError(f"Build-Datei fehlt: {required}")
    print(f"Cloudflare-Pages-Build geprüft: {len(files)} Dateien, größte Datei {max(p.stat().st_size for p in files):,} Bytes.")
    print(f"Upload-Verzeichnis: {output}")


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError, subprocess.CalledProcessError) as error:
        raise SystemExit(str(error)) from None
