from types import SimpleNamespace

from family_price_tracker.config import Settings
from family_price_tracker.models import (
    UNKNOWN_HOST_MESSAGE,
    Item,
    store_key_from_url,
)
from family_price_tracker.refresh import make_tracked_item, refresh_item


def test_store_key_from_url_amazon():
    assert store_key_from_url("https://www.amazon.com/dp/B0D1XD1ZV3") == "amazon"
    assert store_key_from_url("www.amazon.com/dp/ABC") == "amazon"
    assert store_key_from_url("https://amzn.to/abc") == "amazon"


def test_store_key_from_url_target_walmart():
    assert store_key_from_url("https://www.target.com/p/thing/-/A-123") == "target"
    assert store_key_from_url("https://www.walmart.com/ip/thing/123") == "walmart"


def test_store_key_from_url_unknown():
    assert store_key_from_url("https://www.costco.com/thing.html") is None
    assert store_key_from_url("") is None


def test_store_keys_explicit_skips_other_urls():
    item = Item(
        id="1",
        name="x",
        stores="target",
        amazon_url="https://www.amazon.com/dp/ABC",
        target_url="https://www.target.com/p/x",
    )
    assert item.store_keys() == ["target"]
    assert item.refresh_targets() == [("target", "https://www.target.com/p/x")]


def test_store_keys_empty_infers_from_urls():
    item = Item(id="1", name="x", amazon_url="https://www.amazon.com/dp/ABC")
    assert item.store_keys() == ["amazon"]
    assert item.refresh_targets() == [("amazon", "https://www.amazon.com/dp/ABC")]


def test_refresh_targets_skips_checked_without_url():
    item = Item(
        id="1",
        name="x",
        stores="amazon,target",
        amazon_url="https://www.amazon.com/dp/ABC",
    )
    assert item.store_keys() == ["amazon", "target"]
    assert item.refresh_targets() == [("amazon", "https://www.amazon.com/dp/ABC")]


def test_make_tracked_item_infers_amazon():
    item = make_tracked_item(
        url="https://www.amazon.com/dp/B0D1XD1ZV3",
        name="Thing",
        notes="black",
        priority=2,
        list_owner="Me",
    )
    assert item.type == "tracked"
    assert item.stores == "amazon"
    assert item.amazon_url.endswith("B0D1XD1ZV3")
    assert item.target_url == ""


def test_make_tracked_item_infers_target():
    item = make_tracked_item(
        url="https://www.target.com/p/thing/-/A-1",
        name="Thing",
        notes="",
        priority=3,
        list_owner="Me",
    )
    assert item.stores == "target"
    assert item.target_url.startswith("https://www.target.com/")
    assert item.amazon_url == ""


def test_make_tracked_item_rejects_unknown_host():
    try:
        make_tracked_item(
            url="https://www.costco.com/thing.html",
            name="Thing",
            notes="",
            priority=3,
            list_owner="Me",
        )
    except ValueError as exc:
        assert str(exc) == UNKNOWN_HOST_MESSAGE
    else:
        raise AssertionError("expected ValueError")


def test_refresh_item_skips_unchecked_amazon_and_empty_target_url():
    settings = Settings(sheet_id="unused", credentials_path="unused")
    item = Item(
        id="row-1",
        name="x",
        stores="target",
        amazon_url="https://www.amazon.com/dp/ABC",
    )
    errors = refresh_item(SimpleNamespace(), item, settings, dry_run=True)
    assert errors == []


def test_refresh_item_skips_checked_store_without_url():
    settings = Settings(sheet_id="unused", credentials_path="unused")
    item = Item(id="row-1", name="x", stores="amazon")
    errors = refresh_item(SimpleNamespace(), item, settings, dry_run=True)
    assert errors == []
