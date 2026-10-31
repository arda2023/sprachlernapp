import base64
import json
import tempfile
import unittest
from contextlib import redirect_stdout
from io import StringIO
from pathlib import Path
from unittest.mock import patch

from tool import payment_build


def _jwt(role: str) -> str:
    payload = base64.urlsafe_b64encode(
        json.dumps({"role": role}).encode("utf-8")
    ).decode("ascii").rstrip("=")
    return f"header.{payload}.signature"


def _config(**overrides: object) -> dict[str, object]:
    result: dict[str, object] = {
        "ADAPTY_PUBLIC_SDK_KEY": "public_test_example",
        "SUPABASE_URL": "https://project.supabase.co",
        "SUPABASE_ANON_KEY": _jwt("anon"),
        "GOOGLE_IOS_CLIENT_ID": "",
        "GOOGLE_WEB_CLIENT_ID": "",
        "ENABLE_SANDBOX_PURCHASES": True,
        "LEGAL_DOCUMENTS_APPROVED": False,
    }
    result.update(overrides)
    return result


class PaymentBuildConfigTests(unittest.TestCase):
    def validate(self, config: dict[str, object]) -> dict[str, object]:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "config.json"
            path.write_text(json.dumps(config), encoding="utf-8")
            parsed, digest = payment_build.load_and_validate_config(path)
            self.assertEqual(len(digest), 64)
            return parsed

    def test_accepts_exact_seven_key_public_config(self) -> None:
        self.assertEqual(self.validate(_config()), _config())

    def test_rejects_unknown_or_missing_config_keys(self) -> None:
        for config in (
            _config(SUPABASE_SERVICE_ROLE_KEY="service-role-secret"),
            {key: value for key, value in _config().items() if key != "SUPABASE_URL"},
        ):
            with self.subTest(keys=sorted(config)):
                with self.assertRaises(payment_build.ConfigError):
                    self.validate(config)

    def test_rejects_duplicate_json_key(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "config.json"
            path.write_text(
                '{"ADAPTY_PUBLIC_SDK_KEY":"public_a",'
                '"ADAPTY_PUBLIC_SDK_KEY":"public_b"}',
                encoding="utf-8",
            )
            with self.assertRaisesRegex(payment_build.ConfigError, "Duplicate"):
                payment_build.load_and_validate_config(path)

    def test_rejects_secret_or_development_sdk_prefixes(self) -> None:
        for value in ("secret_live_example", "dev_example", "public_"):
            with self.subTest(prefix=value):
                with self.assertRaises(payment_build.ConfigError):
                    self.validate(_config(ADAPTY_PUBLIC_SDK_KEY=value))

    def test_accepts_anon_jwt_or_publishable_key_only(self) -> None:
        self.validate(_config(SUPABASE_ANON_KEY="sb_publishable_example"))
        for value in (
            _jwt("service_role"),
            "sb_secret_example",
            "sb_publishable_",
            "malformed",
        ):
            with self.subTest(key_kind=value.split(".")[0]):
                with self.assertRaises(payment_build.ConfigError):
                    self.validate(_config(SUPABASE_ANON_KEY=value))

    def test_rejects_non_https_url_and_non_boolean_flags(self) -> None:
        with self.assertRaises(payment_build.ConfigError):
            self.validate(_config(SUPABASE_URL="http://project.supabase.co"))
        with self.assertRaises(payment_build.ConfigError):
            self.validate(_config(ENABLE_SANDBOX_PURCHASES=1))


class PaymentBuildCommandTests(unittest.TestCase):
    def test_debug_forces_sandbox_and_never_approves_legal_release(self) -> None:
        defines = payment_build.effective_defines("ios-debug", _config(
            ENABLE_SANDBOX_PURCHASES=False,
            LEGAL_DOCUMENTS_APPROVED=True,
        ))
        self.assertEqual(defines["ENABLE_SANDBOX_PURCHASES"], "true")
        self.assertEqual(defines["LEGAL_DOCUMENTS_APPROVED"], "false")

    def test_profile_forces_sandbox_and_never_approves_legal_release(self) -> None:
        defines = payment_build.effective_defines(
            "ios-profile",
            _config(
                ENABLE_SANDBOX_PURCHASES=False,
                LEGAL_DOCUMENTS_APPROVED=True,
            ),
        )
        self.assertEqual(defines["ENABLE_SANDBOX_PURCHASES"], "true")
        self.assertEqual(defines["LEGAL_DOCUMENTS_APPROVED"], "false")

    def test_archive_never_sets_legal_approval_and_requires_it_in_config(self) -> None:
        with self.assertRaisesRegex(payment_build.ConfigError, "blocked"):
            payment_build.effective_defines("ios-archive", _config())
        config = _config(LEGAL_DOCUMENTS_APPROVED=True)
        defines = payment_build.effective_defines("ios-archive", config)
        self.assertEqual(defines["LEGAL_DOCUMENTS_APPROVED"], "true")
        self.assertEqual(defines["ENABLE_SANDBOX_PURCHASES"], "true")

    def test_release_can_be_production_only(self) -> None:
        defines = payment_build.effective_defines(
            "ios-archive",
            _config(LEGAL_DOCUMENTS_APPROVED=True, ENABLE_SANDBOX_PURCHASES=False),
        )
        self.assertEqual(defines["LEGAL_DOCUMENTS_APPROVED"], "true")
        self.assertEqual(defines["ENABLE_SANDBOX_PURCHASES"], "false")

    def test_debug_command_always_builds_from_source(self) -> None:
        command = payment_build.flutter_command(
            "ios-debug", Path("defines.json"), device="test-device"
        )
        self.assertEqual(command[:4], ["flutter", "run", "--debug", "--device-id"])
        self.assertFalse(any("use-application-binary" in item for item in command))

    def test_profile_command_runs_fresh_profile_build_on_optional_device(self) -> None:
        command = payment_build.flutter_command(
            "ios-profile", Path("defines.json"), device="test-device"
        )
        self.assertEqual(command[:5], ["flutter", "run", "--profile", "--device-id", "test-device"])
        self.assertFalse(any("use-application-binary" in item for item in command))

    def test_archive_requires_numeric_build_number(self) -> None:
        for value in (None, "", "1.2", "abc"):
            with self.subTest(value=value):
                with self.assertRaises(payment_build.ConfigError):
                    payment_build.flutter_command(
                        "ios-archive", Path("defines.json"), build_number=value
                    )
        command = payment_build.flutter_command(
            "ios-archive", Path("defines.json"), build_number="42"
        )
        self.assertEqual(command[:6], ["flutter", "build", "ipa", "--release", "--build-number", "42"])

    def test_archive_cli_requires_build_number(self) -> None:
        with self.assertRaises(SystemExit) as error:
            payment_build._parser().parse_args(["ios-archive"])
        self.assertEqual(error.exception.code, 2)

    def test_dry_run_redacts_defines_file_path(self) -> None:
        self.assertEqual(
            payment_build._redacted_command(
                [
                    "flutter",
                    "run",
                    "--device-id",
                    "private-device",
                    "--dart-define-from-file=/private/path",
                ]
            ),
            [
                "flutter",
                "run",
                "--device-id",
                "<device>",
                "--dart-define-from-file=<temporary-public-defines>",
            ],
        )

    def test_dry_run_output_and_status_do_not_expose_config_values(self) -> None:
        config = _config()
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            config_path = root / "local.json"
            config_path.write_text(json.dumps(config), encoding="utf-8")
            output = StringIO()
            with (
                patch.object(payment_build, "PAYMENT_BUILD_DIR", root / "status"),
                redirect_stdout(output),
            ):
                result = payment_build.main(
                    [
                        "ios-debug",
                        "--config",
                        str(config_path),
                        "--device",
                        "private-device",
                        "--dry-run",
                    ]
                )
            self.assertEqual(result, 0)
            self.assertNotIn("public_test_example", output.getvalue())
            self.assertNotIn("project.supabase.co", output.getvalue())
            self.assertNotIn("private-device", output.getvalue())
            self.assertIn("<temporary-public-defines>", output.getvalue())
            status = next((root / "status").glob("*.json")).read_text()
            self.assertNotIn("public_test_example", status)
            self.assertNotIn("project.supabase.co", status)

    def test_streamed_build_error_keeps_diagnostic_and_redacts_config_values(self) -> None:
        config = _config(GOOGLE_IOS_CLIENT_ID="oauth-client-id")
        values = [
            config["ADAPTY_PUBLIC_SDK_KEY"].encode(),
            config["SUPABASE_URL"].encode(),
            config["SUPABASE_ANON_KEY"].encode(),
            config["GOOGLE_IOS_CLIENT_ID"].encode(),
        ]
        output = b"BUILD FAILED: " + b" | ".join(values) + b"\n"

        class ChunkedOutput:
            def __init__(self, data: bytes):
                self.parts = [data[:11], data[11:31], data[31:58], data[58:]]

            def read(self, _size: int) -> bytes:
                return self.parts.pop(0) if self.parts else b""

            def close(self) -> None:
                pass

        class FakeProcess:
            def __init__(self):
                self.stdout = ChunkedOutput(output)

            def wait(self) -> int:
                return 1

            def poll(self) -> int:
                return 1

            def terminate(self) -> None:
                pass

        output_capture = StringIO()
        with (
            patch("tool.payment_build.subprocess.Popen", return_value=FakeProcess()),
            redirect_stdout(output_capture),
        ):
            code = payment_build._stream_flutter(
                ["flutter", "build", "ipa"], config, Path("/tmp/private-defines.json")
            )

        streamed = output_capture.getvalue()
        self.assertEqual(code, 1)
        self.assertIn("BUILD FAILED", streamed)
        for value in values:
            self.assertNotIn(value.decode(), streamed)
        self.assertIn("[REDACTED]", streamed)
        self.assertNotIn("/tmp/private-defines.json", streamed)


if __name__ == "__main__":
    unittest.main()
