from __future__ import annotations

import logging
import uuid

from family_price_tracker.config import Settings, load_settings
from family_price_tracker.fetchers import get_fetcher, load_builtin_fetchers
from family_price_tracker.models import FetchError, Item, PriceResult
from family_price_tracker.sheets import SheetsClient

log = logging.getLogger(__name__)


def refresh_item(
    client: SheetsClient,
    item: Item,
    settings: Settings,
    *,
    dry_run: bool = False,
) -> list[str]:
    load_builtin_fetchers()
    errors: list[str] = []
    stores = item.store_keys() or (["amazon"] if item.amazon_url else [])
    if not stores:
        errors.append(f"{item.id}: no stores configured")
        return errors

    for store in stores:
        fetcher = get_fetcher(store)
        if fetcher is None:
            errors.append(f"{item.id}/{store}: no fetcher registered")
            continue
        url = {
            "amazon": item.amazon_url,
            "target": item.target_url,
            "walmart": item.walmart_url,
        }.get(store, "")
        # Allow injecting user-agent into AmazonFetcher instances created at import
        if hasattr(fetcher, "user_agent"):
            fetcher.user_agent = settings.user_agent  # type: ignore[attr-defined]

        result = fetcher.fetch(product_url=url, upc=item.upc)
        if isinstance(result, FetchError):
            msg = f"{item.id}/{store}: {result.code} — {result.message}"
            log.error(msg)
            errors.append(msg)
            continue
        assert isinstance(result, PriceResult)
        if store == "amazon":
            if dry_run:
                print(
                    f"dry-run would write\t{item.id}\tamazon\t"
                    f"price={result.price}\turl={result.url}"
                )
                log.info(
                    "dry-run: skip Sheet write for %s amazon → %s",
                    item.id,
                    result.price,
                )
            else:
                client.update_amazon_price(item, result.price, result.url)
                log.info(
                    "Updated %s amazon → %s (%s)", item.id, result.price, result.url
                )
        else:
            errors.append(f"{item.id}/{store}: write-back not implemented yet")
    return errors


def add_tracked(
    client: SheetsClient,
    *,
    url: str,
    name: str,
    notes: str,
    priority: int,
    list_owner: str,
    refresh: bool,
    settings: Settings,
) -> Item:
    item = Item(
        id=str(uuid.uuid4()),
        name=name,
        list_owner=list_owner,
        priority=priority,
        type="tracked",
        notes=notes,
        status="wanted",
        stores="amazon",
        amazon_url=url,
    )
    client.append_item(item)
    log.info("Added tracked item %s", item.id)
    if refresh:
        # Reload to get row_index
        saved = client.get_item(item.id)
        if saved:
            refresh_item(client, saved, settings)
    return item


def cmd_list_items() -> int:
    settings = load_settings()
    client = SheetsClient(settings)
    items = client.list_items()
    if not items:
        print("(no items)")
        return 0
    for item in sorted(items, key=lambda x: (x.priority, x.name.lower())):
        print(
            f"{item.id}\tP{item.priority}\t{item.type}\t{item.list_owner}\t{item.name}"
            f"\tamazon={item.amazon_price or '-'}"
        )
    return 0


def cmd_refresh(item_id: str | None, due: bool, dry_run: bool = False) -> int:
    settings = load_settings()
    client = SheetsClient(settings)
    items = client.list_items()
    if item_id:
        targets = [i for i in items if i.id == item_id]
        if not targets:
            print(f"Item not found: {item_id}")
            return 1
    elif due:
        targets = [i for i in items if i.type == "tracked" and i.status == "wanted"]
    else:
        print("Specify --item <id> or --due")
        return 2

    all_errors: list[str] = []
    for item in targets:
        all_errors.extend(refresh_item(client, item, settings, dry_run=dry_run))
    if all_errors:
        print(f"Completed with {len(all_errors)} error(s)")
        for e in all_errors:
            print(f"  - {e}")
        return 1
    print("OK" + (" (dry-run, no Sheet writes)" if dry_run else ""))
    return 0


def cmd_add_tracked(
    url: str,
    name: str,
    notes: str,
    priority: int,
    list_owner: str,
    do_refresh: bool,
) -> int:
    settings = load_settings()
    client = SheetsClient(settings)
    item = add_tracked(
        client,
        url=url,
        name=name,
        notes=notes,
        priority=priority,
        list_owner=list_owner,
        refresh=do_refresh,
        settings=settings,
    )
    print(item.id)
    return 0


# Sample Amazon product page for manual / doctor checks. Expect breakage when
# Amazon changes HTML; prefer unit tests on saved HTML over live fetches.
AMAZON_FIXTURE_URL = "https://www.amazon.com/dp/B0D1XD1ZV3"


def cmd_doctor() -> int:
    load_builtin_fetchers()
    from family_price_tracker.fetchers import all_fetchers

    print("Registered fetchers:", ", ".join(sorted(all_fetchers())) or "(none)")
    print(f"Amazon fixture URL (may break): {AMAZON_FIXTURE_URL}")
    print("doctor: use refresh --item / --dry-run against a real Sheet row to validate.")
    return 0
