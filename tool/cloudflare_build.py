"""Prepare pinned Flutter and verified content, then run the production web build."""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.request

ROOT = Path(__file__).resolve().parent.parent
FLUTTER_VERSION = "3.47.2"
FLUTTER_REVISION = "d3b14c876900e553bc736ca19295fc09e3853e8e"
FLUTTER_REPOSITORY = "https://github.com/flutter/flutter.git"
LOCK = ROOT / "tool/cloudflare_assets.lock.json"


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def prepare_assets(root: Path = ROOT) -> None:
    lock = json.loads(LOCK.read_text(encoding="utf-8"))
    if lock["version"] != 1:
        raise ValueError("Unsupported content lock version")
    for asset in lock["assets"]:
        relative = Path(asset["path"])
        if relative.is_absolute() or ".." in relative.parts:
            raise ValueError("Unsafe content lock path")
        target = root / relative
        expected = asset["sha256"]
        if target.is_file() and sha256(target) == expected:
            continue
        target.parent.mkdir(parents=True, exist_ok=True)
        url = lock["base_url"] + "/" + relative.as_posix()
        for attempt in range(3):
            temporary = None
            try:
                with tempfile.NamedTemporaryFile(dir=target.parent, delete=False) as output:
                    temporary = Path(output.name)
                    request = urllib.request.Request(url, headers={"User-Agent": "linglossa-build/1.0"})
                    with urllib.request.urlopen(request, timeout=60) as response:
                        size = 0
                        while chunk := response.read(1024 * 1024):
                            size += len(chunk)
                            if size > asset["bytes"]:
                                raise ValueError(f"Unexpected asset size: {relative}")
                            output.write(chunk)
                if size != asset["bytes"] or sha256(temporary) != expected:
                    raise ValueError(f"Content checksum mismatch: {relative}")
                temporary.replace(target)
                print(f"Verified {relative}", flush=True)
                break
            except (OSError, urllib.error.URLError) as error:
                if attempt == 2:
                    raise RuntimeError(f"Content download failed: {relative}") from error
                time.sleep(2 ** attempt)
            finally:
                if temporary is not None:
                    temporary.unlink(missing_ok=True)


def prepare_flutter(use_installed: bool) -> dict[str, str]:
    env = os.environ.copy()
    if use_installed:
        executable = shutil.which("flutter")
        if not executable:
            raise ValueError("Flutter is not installed on PATH")
        sdk = Path(executable).resolve().parent.parent
    else:
        sdk = Path(tempfile.gettempdir()) / f"linglossa-flutter-{FLUTTER_REVISION}"
        if not sdk.exists():
            staging = Path(tempfile.mkdtemp(prefix="linglossa-flutter-install-"))
            try:
                subprocess.run([
                    "git", "clone", "--depth", "1", "--branch", FLUTTER_VERSION,
                    FLUTTER_REPOSITORY, str(staging / "sdk"),
                ], check=True)
                (staging / "sdk").rename(sdk)
            finally:
                shutil.rmtree(staging, ignore_errors=True)
    revision = subprocess.check_output(
        ["git", "-C", str(sdk), "rev-parse", "HEAD"], text=True,
    ).strip()
    if revision != FLUTTER_REVISION:
        raise ValueError(f"Flutter must be {FLUTTER_VERSION} at {FLUTTER_REVISION}")
    env["PATH"] = str(sdk / "bin") + os.pathsep + env.get("PATH", "")
    flutter = sdk / "bin" / ("flutter.bat" if os.name == "nt" else "flutter")
    subprocess.run([str(flutter), "--version"], env=env, check=True)
    return env


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--prepare-only", action="store_true", help="Verify SDK and assets without building")
    parser.add_argument("--use-installed-flutter", action="store_true", help="Use PATH Flutter; enforce pinned revision")
    args = parser.parse_args()
    env = prepare_flutter(args.use_installed_flutter)
    prepare_assets()
    if not args.prepare_only:
        subprocess.run([sys.executable, str(ROOT / "tool/build_web.py")], cwd=ROOT, env=env, check=True)


if __name__ == "__main__":
    try:
        main()
    except (ValueError, RuntimeError, OSError, subprocess.CalledProcessError) as error:
        raise SystemExit(str(error)) from None
