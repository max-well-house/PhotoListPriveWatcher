from __future__ import annotations

from typing import Protocol

from family_price_tracker.models import FetchError, PriceResult


class Fetcher(Protocol):
    store_key: str

    def fetch(self, *, product_url: str = "", upc: str = "") -> PriceResult | FetchError:
        ...


_REGISTRY: dict[str, Fetcher] = {}


def register(fetcher: Fetcher) -> Fetcher:
    _REGISTRY[fetcher.store_key] = fetcher
    return fetcher


def get_fetcher(store_key: str) -> Fetcher | None:
    return _REGISTRY.get(store_key)


def all_fetchers() -> dict[str, Fetcher]:
    return dict(_REGISTRY)


def load_builtin_fetchers() -> None:
    from family_price_tracker.fetchers.amazon import AmazonFetcher

    if "amazon" not in _REGISTRY:
        register(AmazonFetcher())
