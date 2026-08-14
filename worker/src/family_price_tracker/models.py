from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Optional
from urllib.parse import urlparse

UNKNOWN_HOST_MESSAGE = "Amazon, Target, or Walmart URLs for now."


def utc_now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def store_key_from_url(url: str) -> str | None:
    raw = url.strip()
    if not raw:
        return None
    if "://" not in raw:
        raw = "https://" + raw
    host = (urlparse(raw).hostname or "").lower()
    if host == "amzn.to" or host.endswith(".amzn.to"):
        return "amazon"
    if host == "amazon.com" or host.endswith(".amazon.com"):
        return "amazon"
    if host == "target.com" or host.endswith(".target.com"):
        return "target"
    if host == "walmart.com" or host.endswith(".walmart.com"):
        return "walmart"
    return None


@dataclass
class Item:
    id: str
    name: str
    list_owner: str = "Shared"
    priority: int = 3
    type: str = "text"
    size: str = ""
    color: str = ""
    qty: str = ""
    notes: str = ""
    status: str = "wanted"
    stores: str = ""
    amazon_price: str = ""
    amazon_url: str = ""
    target_price: str = ""
    target_url: str = ""
    walmart_price: str = ""
    walmart_url: str = ""
    last_checked: str = ""
    upc: str = ""
    asin: str = ""
    hot: str = ""
    photo: str = ""
    row_index: Optional[int] = None  # 1-based sheet row

    def store_keys(self) -> list[str]:
        if not self.stores.strip():
            keys = []
            if self.amazon_url:
                keys.append("amazon")
            if self.target_url:
                keys.append("target")
            if self.walmart_url:
                keys.append("walmart")
            return keys
        return [s.strip().lower() for s in self.stores.split(",") if s.strip()]

    def url_for_store(self, store_key: str) -> str:
        return {
            "amazon": self.amazon_url,
            "target": self.target_url,
            "walmart": self.walmart_url,
        }.get(store_key, "") or ""

    def refresh_targets(self) -> list[tuple[str, str]]:
        """Checked stores that have a product URL. Empty URL is skipped, not an error."""
        out: list[tuple[str, str]] = []
        for key in self.store_keys():
            url = self.url_for_store(key).strip()
            if url:
                out.append((key, url))
        return out


@dataclass
class PriceResult:
    store_key: str
    price: str
    url: str
    checked_at: str = field(default_factory=utc_now_iso)


@dataclass
class FetchError:
    store_key: str
    code: str
    message: str
