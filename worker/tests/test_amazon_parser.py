from family_price_tracker.fetchers.amazon import AmazonFetcher


SAMPLE_HTML = """
<html><body>
  <span class="a-price"><span class="a-offscreen">$19.99</span></span>
  <link rel="canonical" href="https://www.amazon.com/dp/B0D1XD1ZV3"/>
</body></html>
"""


def test_amazon_parse_price_from_offscreen():
    fetcher = AmazonFetcher()
    assert fetcher._parse_price(SAMPLE_HTML) == "19.99"


def test_amazon_parse_jsonld():
    html = """
    <html><script type="application/ld+json">
    {"@type":"Product","offers":{"@type":"Offer","price":"42.00","priceCurrency":"USD"}}
    </script></html>
    """
    fetcher = AmazonFetcher()
    assert fetcher._parse_price(html) == "42.00"


def test_item_store_keys_from_url():
    from family_price_tracker.models import Item

    item = Item(id="1", name="x", amazon_url="https://www.amazon.com/dp/ABC")
    assert item.store_keys() == ["amazon"]
