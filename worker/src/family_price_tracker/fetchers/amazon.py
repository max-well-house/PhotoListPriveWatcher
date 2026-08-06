"""Amazon product-page price fetcher (best-effort, personal/family use).

See docs/scraping-and-legal.md. Prefer exact product URLs. Fail loudly when
markup changes — never invent a price.
"""

from __future__ import annotations

import json
import re
from urllib.parse import urlparse

import requests
from bs4 import BeautifulSoup

from family_price_tracker.models import FetchError, PriceResult, utc_now_iso

ASIN_RE = re.compile(r"/(?:dp|gp/product)/([A-Z0-9]{10})", re.I)
PRICE_RE = re.compile(r"^\s*\$?\s*([0-9]+(?:\.[0-9]{2})?)\s*$")


class AmazonFetcher:
    store_key = "amazon"

    def __init__(self, user_agent: str | None = None, session: requests.Session | None = None):
        self.user_agent = user_agent or (
            "Mozilla/5.0 (compatible; FamilyPriceTracker/0.1; +personal-family-use)"
        )
        self.session = session or requests.Session()

    def fetch(self, *, product_url: str = "", upc: str = "") -> PriceResult | FetchError:
        if not product_url:
            return FetchError(self.store_key, "missing_url", "Amazon fetcher needs product_url")
        try:
            resp = self.session.get(
                product_url,
                headers={
                    "User-Agent": self.user_agent,
                    "Accept-Language": "en-US,en;q=0.9",
                },
                timeout=30,
            )
        except requests.RequestException as exc:
            return FetchError(self.store_key, "http_error", str(exc))

        if resp.status_code >= 400:
            return FetchError(
                self.store_key,
                "http_error",
                f"HTTP {resp.status_code} for {product_url}",
            )

        price = self._parse_price(resp.text)
        if not price:
            return FetchError(
                self.store_key,
                "selector_broken",
                "Could not parse Amazon price (markup may have changed)",
            )

        canonical = self._canonical_url(product_url, resp.text) or product_url
        return PriceResult(
            store_key=self.store_key,
            price=price,
            url=canonical,
            checked_at=utc_now_iso(),
        )

    def _parse_price(self, html: str) -> str | None:
        soup = BeautifulSoup(html, "lxml")

        for sel in (
            "span.a-price .a-offscreen",
            "#priceblock_ourprice",
            "#priceblock_dealprice",
            "#corePrice_feature_div span.a-offscreen",
            "span[data-a-color='price'] .a-offscreen",
        ):
            el = soup.select_one(sel)
            if el and el.get_text(strip=True):
                parsed = self._normalize(el.get_text(strip=True))
                if parsed:
                    return parsed

        for script in soup.find_all("script", type="application/ld+json"):
            try:
                data = json.loads(script.string or "")
            except (json.JSONDecodeError, TypeError):
                continue
            price = self._price_from_jsonld(data)
            if price:
                return price

        meta = soup.find("meta", property="og:price:amount")
        if meta and meta.get("content"):
            return self._normalize(meta["content"])

        return None

    def _price_from_jsonld(self, data: object) -> str | None:
        if isinstance(data, list):
            for item in data:
                found = self._price_from_jsonld(item)
                if found:
                    return found
            return None
        if not isinstance(data, dict):
            return None
        offers = data.get("offers")
        if isinstance(offers, dict):
            p = offers.get("price") or offers.get("lowPrice")
            if p is not None:
                return self._normalize(str(p))
        if isinstance(offers, list):
            for offer in offers:
                if isinstance(offer, dict) and offer.get("price") is not None:
                    return self._normalize(str(offer["price"]))
        return None

    def _normalize(self, raw: str) -> str | None:
        cleaned = raw.replace(",", "").replace("USD", "").strip()
        m = PRICE_RE.match(cleaned) or re.search(r"([0-9]+\.[0-9]{2})", cleaned)
        if not m:
            m = re.search(r"([0-9]+)", cleaned)
        if not m:
            return None
        return m.group(1)

    def _canonical_url(self, product_url: str, html: str) -> str | None:
        m = ASIN_RE.search(product_url)
        if m:
            return f"https://www.amazon.com/dp/{m.group(1)}"
        soup = BeautifulSoup(html, "lxml")
        link = soup.find("link", rel="canonical")
        if link and link.get("href"):
            return link["href"]
        parsed = urlparse(product_url)
        if "amazon." in parsed.netloc:
            return product_url
        return None
