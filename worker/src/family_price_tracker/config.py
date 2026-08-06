from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path

from dotenv import load_dotenv


@dataclass
class Settings:
    sheet_id: str
    credentials_path: Path
    items_tab: str = "Items"
    config_tab: str = "Config"
    user_agent: str = "FamilyPriceTracker/0.1 (+personal-family-use)"


def load_settings() -> Settings:
    # Repo root .env, then cwd
    root = Path(__file__).resolve().parents[3]
    load_dotenv(root / ".env")
    load_dotenv()

    sheet_id = os.getenv("SHEET_ID", "").strip()
    creds = os.getenv("GOOGLE_APPLICATION_CREDENTIALS", "").strip()
    if not sheet_id:
        raise SystemExit("SHEET_ID is not set. Copy .env.example → .env and configure.")
    if not creds:
        raise SystemExit(
            "GOOGLE_APPLICATION_CREDENTIALS is not set. Point it at your service-account JSON."
        )
    path = Path(creds)
    if not path.is_file():
        raise SystemExit(f"Credentials file not found: {path}")

    return Settings(
        sheet_id=sheet_id,
        credentials_path=path,
        items_tab=os.getenv("SHEET_ITEMS_TAB", "Items"),
        config_tab=os.getenv("SHEET_CONFIG_TAB", "Config"),
        user_agent=os.getenv(
            "HTTP_USER_AGENT", "FamilyPriceTracker/0.1 (+personal-family-use)"
        ),
    )
