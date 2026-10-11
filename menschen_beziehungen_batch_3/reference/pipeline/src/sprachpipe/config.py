"""Loads pipeline/config.yaml and pipeline/.env."""

from __future__ import annotations

from pathlib import Path

import yaml
from dotenv import load_dotenv

PIPELINE_DIR = Path(__file__).resolve().parents[2]
CONFIG_PATH = PIPELINE_DIR / "config.yaml"


def load_config(path: Path = CONFIG_PATH) -> dict:
    with open(path, encoding="utf-8") as f:
        return yaml.safe_load(f)


def load_env() -> None:
    """Reads pipeline/.env into the environment (existing variables win)."""
    load_dotenv(PIPELINE_DIR / ".env", override=False)
