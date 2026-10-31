#!/usr/bin/env python3
"""Validate local payment build config and run safe Flutter iOS commands."""

from __future__ import annotations

import argparse
import base64
import codecs
import hashlib
import json
import os
import re
import subprocess
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path
from typing import Any
from urllib.parse import urlsplit


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_CONFIG = ROOT / "config" / "adapty.local.json"
PAYMENT_BUILD_DIR = ROOT / "build" / "payment"

STRING_KEYS = {
    "ADAPTY_PUBLIC_SDK_KEY",
    "SUPABASE_URL",
    "SUPABASE_ANON_KEY",
    "GOOGLE_IOS_CLIENT_ID",
    "GOOGLE_WEB_CLIENT_ID",
}
BOOLEAN_KEYS = {"ENABLE_SANDBOX_PURCHASES", "LEGAL_DOCUMENTS_APPROVED"}
CONFIG_KEYS = STRING_KEYS | BOOLEAN_KEYS


class ConfigError(ValueError):
    """A safe-to-print config validation error (never contains a value)."""


def _no_duplicate_object_keys(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for key, value in pairs:
        if key in result:
            raise ConfigError(f"Duplicate config key: {key}")
        result[key] = value
    return result


def _jwt_role(key: str) -> str | None:
    parts = key.split(".")
    if len(parts) != 3 or not all(parts):
        return None
    try:
        payload = parts[1]
        decoded = base64.urlsafe_b64decode(payload + "=" * (-len(payload) % 4))
        claims = json.loads(decoded)
    except (ValueError, json.JSONDecodeError):
        return None
    role = claims.get("role") if isinstance(claims, dict) else None
    return role if isinstance(role, str) else None


def load_and_validate_config(path: Path) -> tuple[dict[str, Any], str]:
    """Read the exact allowlisted schema and return it with a raw-file hash."""
    try:
        raw = path.read_bytes()
    except OSError as error:
        raise ConfigError("Config file could not be read") from error
    digest = hashlib.sha256(raw).hexdigest()
    try:
        config = json.loads(
            raw.decode("utf-8"), object_pairs_hook=_no_duplicate_object_keys
        )
    except ConfigError:
        raise
    except (UnicodeDecodeError, json.JSONDecodeError):
        raise ConfigError("Config is not valid UTF-8 JSON") from None

    if not isinstance(config, dict):
        raise ConfigError("Config root must be a JSON object")
    unknown = set(config) - CONFIG_KEYS
    missing = CONFIG_KEYS - set(config)
    if unknown:
        raise ConfigError("Unsupported config key(s): " + ", ".join(sorted(unknown)))
    if missing:
        raise ConfigError("Missing config key(s): " + ", ".join(sorted(missing)))

    for key in STRING_KEYS:
        if not isinstance(config[key], str):
            raise ConfigError(f"{key} must be a string")
        if any(character in config[key] for character in ("\r", "\n", "\0")):
            raise ConfigError(f"{key} must not contain control characters")
    for key in BOOLEAN_KEYS:
        if type(config[key]) is not bool:
            raise ConfigError(f"{key} must be a JSON boolean")

    adapty_key = config["ADAPTY_PUBLIC_SDK_KEY"]
    if not adapty_key.startswith("public_") or len(adapty_key) == len("public_"):
        raise ConfigError("ADAPTY_PUBLIC_SDK_KEY must use the public_ prefix")

    supabase_url = config["SUPABASE_URL"]
    try:
        parsed_url = urlsplit(supabase_url)
        valid_url = (
            parsed_url.scheme == "https"
            and bool(parsed_url.hostname)
            and parsed_url.username is None
            and parsed_url.password is None
            and parsed_url.path in ("", "/")
            and not parsed_url.query
            and not parsed_url.fragment
        )
    except ValueError:
        valid_url = False
    if not valid_url:
        raise ConfigError("SUPABASE_URL must be a base HTTPS URL")

    supabase_key = config["SUPABASE_ANON_KEY"]
    if not (
        (
            supabase_key.startswith("sb_publishable_")
            and len(supabase_key) > len("sb_publishable_")
        )
        or _jwt_role(supabase_key) == "anon"
    ):
        raise ConfigError(
            "SUPABASE_ANON_KEY must be an anon JWT or sb_publishable_ key"
        )

    return config, digest


def effective_defines(action: str, config: dict[str, Any]) -> dict[str, str]:
    defines = {key: config[key] for key in STRING_KEYS}
    if action in {"ios-debug", "ios-profile"}:
        # Development builds always use sandbox and cannot approve public
        # release purchases through this helper.
        defines["ENABLE_SANDBOX_PURCHASES"] = True
        defines["LEGAL_DOCUMENTS_APPROVED"] = False
    elif action == "ios-archive":
        if config["LEGAL_DOCUMENTS_APPROVED"] is not True:
            raise ConfigError(
                "iOS archive blocked: LEGAL_DOCUMENTS_APPROVED must already be true"
            )
        defines["ENABLE_SANDBOX_PURCHASES"] = config["ENABLE_SANDBOX_PURCHASES"]
        defines["LEGAL_DOCUMENTS_APPROVED"] = config["LEGAL_DOCUMENTS_APPROVED"]
    else:
        raise ConfigError("Unknown build action")

    return {key: _dart_define_value(value) for key, value in defines.items()}


def _dart_define_value(value: Any) -> str:
    if type(value) is bool:
        return "true" if value else "false"
    return value


def flutter_command(
    action: str,
    defines_file: Path,
    *,
    device: str | None = None,
    build_number: str | None = None,
) -> list[str]:
    command = ["flutter"]
    if action in {"ios-debug", "ios-profile"}:
        command.extend(["run", "--debug" if action == "ios-debug" else "--profile"])
        if device:
            command.extend(["--device-id", device])
    elif action == "ios-archive":
        if not build_number:
            raise ConfigError("ios-archive requires --build-number")
        if not re.fullmatch(r"[0-9]+", build_number):
            raise ConfigError("--build-number must contain digits only")
        command.extend(["build", "ipa", "--release", "--build-number", build_number])
    else:
        raise ConfigError("Unknown build action")
    command.append(f"--dart-define-from-file={defines_file}")
    return command


def _redacted_command(command: list[str]) -> list[str]:
    redacted: list[str] = []
    hide_next = False
    for item in command:
        if hide_next:
            redacted.append("<device>")
            hide_next = False
        elif item == "--device-id":
            redacted.append(item)
            hide_next = True
        elif item.startswith("--dart-define-from-file="):
            redacted.append("--dart-define-from-file=<temporary-public-defines>")
        else:
            redacted.append(item)
    return redacted


class StreamingRedactor:
    """Redact config literals while retaining enough overlap for split chunks."""

    def __init__(self, config: dict[str, Any], extra_values: tuple[str, ...] = ()):
        values = [value for key, value in config.items() if key in STRING_KEYS]
        values.extend(extra_values)
        patterns = {
            variant.encode("utf-8")
            for value in values
            if isinstance(value, str) and value
            for variant in (
                value,
                value.replace("/", "\\/"),
                json.dumps(value, ensure_ascii=True)[1:-1],
            )
        }
        for value in tuple(patterns):
            if value.startswith(b"https://") and value.endswith(b"/"):
                patterns.add(value[:-1])
        self.patterns = sorted(patterns, key=len, reverse=True)
        self.max_pattern_size = max((len(value) for value in self.patterns), default=1)
        self.pending = b""

    def feed(self, chunk: bytes, *, final: bool = False) -> bytes:
        self.pending += chunk
        safe_until = (
            len(self.pending)
            if final
            else max(0, len(self.pending) - self.max_pattern_size + 1)
        )
        output = bytearray()
        position = 0
        marker = b"[REDACTED]"
        while position < safe_until:
            match = next(
                (pattern for pattern in self.patterns if self.pending.startswith(pattern, position)),
                None,
            )
            if match is None:
                output.append(self.pending[position])
                position += 1
            else:
                output.extend(marker)
                position += len(match)
        self.pending = self.pending[position:]
        return bytes(output)


def _stream_flutter(command: list[str], config: dict[str, Any], defines_path: Path) -> int:
    redactor = StreamingRedactor(config, (str(defines_path),))
    decoder = codecs.getincrementaldecoder("utf-8")("replace")
    process = subprocess.Popen(
        command,
        cwd=ROOT,
        stdin=None,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        bufsize=0,
        shell=False,
    )
    assert process.stdout is not None
    try:
        while chunk := process.stdout.read(4096):
            safe_bytes = redactor.feed(chunk)
            text = decoder.decode(safe_bytes)
            if text:
                sys.stdout.write(text)
                sys.stdout.flush()
        final_bytes = redactor.feed(b"", final=True)
        final_text = decoder.decode(final_bytes, final=True)
        if final_text:
            sys.stdout.write(final_text)
            sys.stdout.flush()
        return process.wait()
    except BaseException:
        if process.poll() is None:
            process.terminate()
            process.wait()
        raise
    finally:
        process.stdout.close()


def _write_status(
    action: str, config_hash: str | None, exit_code: int, outcome: str
) -> Path:
    PAYMENT_BUILD_DIR.mkdir(parents=True, exist_ok=True)
    created = datetime.now(timezone.utc)
    status_path = PAYMENT_BUILD_DIR / (
        f"{action}-{created.strftime('%Y%m%dT%H%M%S%fZ')}.json"
    )
    status = {
        "action": action,
        "config_sha256": config_hash,
        "exit_code": exit_code,
        "outcome": outcome,
        "created_at_utc": created.isoformat(),
    }
    temporary = status_path.with_suffix(".tmp")
    temporary.write_text(json.dumps(status, indent=2) + "\n", encoding="utf-8")
    os.replace(temporary, status_path)
    return status_path


def _status_label(status_path: Path) -> str:
    return f"build/payment/{status_path.name}"


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="action", required=True)
    for name in ("check", "ios-debug", "ios-profile", "ios-archive"):
        subparser = commands.add_parser(name)
        subparser.add_argument("--config", type=Path, default=DEFAULT_CONFIG)
        subparser.add_argument("--dry-run", action="store_true")
        if name in {"ios-debug", "ios-profile"}:
            subparser.add_argument("--device")
        if name == "ios-archive":
            subparser.add_argument("--build-number", required=True)
    return parser


def main(argv: list[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    config_hash: str | None = None
    try:
        config, config_hash = load_and_validate_config(args.config)
        if args.action == "check":
            status = _write_status(args.action, config_hash, 0, "success")
            print(f"Config valid. Status: {_status_label(status)}")
            return 0

        if not args.dry_run and sys.platform != "darwin":
            raise ConfigError("iOS build commands can run only on macOS")

        defines = effective_defines(args.action, config)
        command = flutter_command(
            args.action,
            Path("<temporary-public-defines>"),
            device=getattr(args, "device", None),
            build_number=getattr(args, "build_number", None),
        )
        if args.dry_run:
            print("Validated command (config values redacted):")
            print("  " + " ".join(_redacted_command(command)))
            status = _write_status(args.action, config_hash, 0, "dry-run")
            print(f"Status: {_status_label(status)}")
            return 0

        PAYMENT_BUILD_DIR.mkdir(parents=True, exist_ok=True)
        with tempfile.NamedTemporaryFile(
            mode="w",
            encoding="utf-8",
            suffix=".json",
            prefix="flutter-defines-",
            dir=PAYMENT_BUILD_DIR,
            delete=False,
        ) as defines_stream:
            defines_path = Path(defines_stream.name)
            json.dump(defines, defines_stream)
        try:
            command = flutter_command(
                args.action,
                defines_path,
                device=getattr(args, "device", None),
                build_number=getattr(args, "build_number", None),
            )
            print(f"Running {_redacted_command(command)[1]} (redacted Flutter output follows).")
            exit_code = _stream_flutter(command, config, defines_path)
            outcome = "success" if exit_code == 0 else "failed"
            status = _write_status(args.action, config_hash, exit_code, outcome)
            print(
                f"Flutter exit code: {exit_code}. "
                f"Status: {_status_label(status)}"
            )
            return exit_code
        except OSError:
            status = _write_status(args.action, config_hash, 127, "failed")
            print(
                "Flutter command could not be started. "
                f"Status: {_status_label(status)}"
            )
            return 127
        finally:
            defines_path.unlink(missing_ok=True)
    except ConfigError as error:
        status = _write_status(args.action, config_hash, 2, "rejected")
        print(
            f"Rejected: {error}. Status: {_status_label(status)}", file=sys.stderr
        )
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
