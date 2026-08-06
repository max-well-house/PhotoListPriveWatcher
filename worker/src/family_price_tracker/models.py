from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Optional


def utc_now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


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
