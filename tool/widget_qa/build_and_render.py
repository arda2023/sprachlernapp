"""Build reproducible native widget previews with macOS/Xcode, without a project edit."""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import platform
import plistlib
import shutil
import subprocess
import time

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "ios" / "LinglossaWidgets"
FONTS = SOURCE / "Fonts"
BUILD = ROOT / "build" / "widget_qa"
APP = BUILD / "WidgetQA.app"
BUNDLE_ID = "com.ardasayar.linglossa.WidgetQA"
FONT_NAMES = ["Figtree-Medium", "Figtree-Bold", "Figtree-ExtraBold", "SourceSerif4-SemiBold"]
PRODUCTION_FILES = [SOURCE / name for name in ["WidgetSnapshot.swift", "WidgetViews.swift", "LinglossaWidgets.swift"]]


def run(*args: str, capture: bool = False) -> str | None:
    result = subprocess.run(args, check=True, text=True, capture_output=capture)
    return result.stdout.strip() if capture else None


def simulator(name: str, requested_udid: str | None) -> str:
    device_groups = json.loads(run("xcrun", "simctl", "list", "devices", "available", "--json", capture=True))["devices"]
    devices = [device for group in device_groups.values() for device in group]
    device = next((device for device in devices if
                   (device["udid"] == requested_udid if requested_udid else device["name"] == name)), None)
    if requested_udid and device is None:
        raise RuntimeError(f"Simulator {requested_udid} is not available")
    if device:
        udid = device["udid"]
    else:
        runtimes = json.loads(run("xcrun", "simctl", "list", "runtimes", "--json", capture=True))["runtimes"]
        supported = [runtime for runtime in runtimes if runtime["isAvailable"]
                     and ".iOS-" in runtime["identifier"] and int(runtime["version"].split(".")[0]) >= 16]
        if not supported:
            raise RuntimeError("Install an iOS Simulator runtime (iOS 16 or later) in Xcode first")
        runtime = max(supported, key=lambda item: tuple(int(part) for part in item["version"].split(".")))
        types = json.loads(run("xcrun", "simctl", "list", "devicetypes", "--json", capture=True))["devicetypes"]
        device_type = next((item for item in types if item["identifier"] == "com.apple.CoreSimulator.SimDeviceType.iPhone-17"), None)
        if device_type is None:
            device_type = next(item for item in reversed(types) if item.get("productFamily") == "iPhone")
        udid = run("xcrun", "simctl", "create", name, device_type["identifier"], runtime["identifier"], capture=True)
    if not device or device["state"] != "Booted":
        run("xcrun", "simctl", "boot", udid)
    run("xcrun", "simctl", "bootstatus", udid, "-b")
    return udid


def build() -> None:
    if platform.system() != "Darwin":
        raise RuntimeError("Native widget preview rendering requires macOS and Xcode; it cannot run on Windows")
    APP.mkdir(parents=True, exist_ok=True)
    sdk = run("xcrun", "--sdk", "iphonesimulator", "--show-sdk-path", capture=True)
    architecture = "arm64" if platform.machine() == "arm64" else "x86_64"
    common = ["xcrun", "--sdk", "iphonesimulator", "swiftc", "-swift-version", "6", "-strict-concurrency=complete",
              "-default-isolation", "MainActor", "-enable-upcoming-feature", "NonisolatedNonsendingByDefault", "-sdk", sdk]
    # Guard the shipping extension's iOS 15 baseline separately from ImageRenderer.
    run(*common, "-typecheck", "-target", f"{architecture}-apple-ios15.0-simulator", *map(str, PRODUCTION_FILES))
    print("PASS: production widget sources typecheck for iOS 15 with strict Swift 6 concurrency", flush=True)
    for name in FONT_NAMES:
        shutil.copy2(FONTS / f"{name}.ttf", APP / f"{name}.ttf")
    for name in ["Figtree-OFL.txt", "SourceSerif4-OFL.txt"]:
        shutil.copy2(FONTS / name, APP / name)
    # Use an existing editorial asset, never an import or generated mock cover.
    cover = ROOT / "assets" / "story_covers" / "restaurant_05.png"
    (APP / "home_widget").mkdir(exist_ok=True)
    shutil.copy2(cover, APP / "home_widget" / "qa-cover.png")
    info = {
        "CFBundleIdentifier": BUNDLE_ID, "CFBundleExecutable": "WidgetQA",
        "CFBundleName": "Linglossa Widget QA", "CFBundleDisplayName": "Widget QA",
        "CFBundleVersion": "1", "CFBundleShortVersionString": "1.0", "CFBundlePackageType": "APPL",
        "MinimumOSVersion": "16.0", "LSRequiresIPhoneOS": True,
        "UILaunchScreen": {}, "UIAppFonts": [f"{name}.ttf" for name in FONT_NAMES],
        "CFBundleDevelopmentRegion": "de", "CFBundleLocalizations": ["de"],
        "UISupportedInterfaceOrientations": ["UIInterfaceOrientationPortrait"], "UIDeviceFamily": [1],
    }
    with (APP / "Info.plist").open("wb") as file:
        plistlib.dump(info, file)
    run(*common, "-D", "WIDGET_QA", "-target", f"{architecture}-apple-ios16.0-simulator",
        *map(str, PRODUCTION_FILES), str(Path(__file__).with_name("WidgetQA.swift")), "-o", str(APP / "WidgetQA"))
    run("codesign", "--force", "--sign", "-", str(APP))


def render(udid: str, output_folder: Path) -> None:
    run("xcrun", "simctl", "install", udid, str(APP))
    subprocess.run(["xcrun", "simctl", "terminate", udid, BUNDLE_ID], capture_output=True)
    run_id = str(time.time_ns())
    launched_at = time.time()
    subprocess.run(["xcrun", "simctl", "launch", udid, BUNDLE_ID], check=True,
                   env={**os.environ, "SIMCTL_CHILD_QA_RUN_ID": run_id})
    container = Path(run("xcrun", "simctl", "get_app_container", udid, BUNDLE_ID, "data", capture=True))
    exported = container / "Documents" / "widget-qa"
    for _ in range(60):
        manifest = exported / "manifest.json"
        if ((exported / "completed.txt").exists() and manifest.exists()
                and json.loads(manifest.read_text()).get("runID") == run_id):
            break
        error = exported / "error.txt"
        if error.exists() and error.stat().st_mtime >= launched_at:
            raise RuntimeError(error.read_text())
        time.sleep(0.5)
    else:
        raise RuntimeError("The simulator did not finish rendering within 30 seconds")
    shutil.copytree(exported, output_folder, dirs_exist_ok=True)
    run("xcrun", "simctl", "io", udid, "screenshot", str(output_folder / "simulator-gallery.png"))
    metadata = json.loads((output_folder / "manifest.json").read_text())
    if metadata["count"] != 24 or any(not (output_folder / name).is_file() for name in metadata["requiredScreenshots"]):
        raise RuntimeError("Required screenshot matrix is incomplete")
    print((output_folder / "completed.txt").read_text(), end="")
    print(f"Simulator: {udid}")
    print(f"Screenshots: {output_folder}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=ROOT / "docs" / "store-readiness" / "widgets",
                        help="Screenshot output directory (default: docs/store-readiness/widgets)")
    parser.add_argument("--simulator", help="Use an existing simulator UDID; the default is a separate QA simulator")
    parser.add_argument("--simulator-name", default="Linglossa Widget QA")
    args = parser.parse_args()
    build()
    udid = simulator(args.simulator_name, args.simulator)
    render(udid, args.output.expanduser().resolve())


if __name__ == "__main__":
    main()
