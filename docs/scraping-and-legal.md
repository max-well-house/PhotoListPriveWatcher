# Scraping and legal

This project is for **personal / family use** on a shared wishlist. It is not a product to redistribute, monetize, or scale as a multi-tenant service.

## Risks

- Automated fetching of retailer pages may violate retailer Terms of Service.
- HTML/CSS selectors break often; wrong prices are worse than missing prices.
- Aggressive polling can get IPs blocked.

## Rules of the road

1. Prefer **official APIs, affiliate feeds, or user-pasted product URLs** over blind search scraping.
2. Treat every fetcher as **best-effort**. On parse failure, record a clear error — never invent a price.
3. Isolate fetchers so one retailer outage does not abort the whole job.
4. Keep refresh cadence polite (weekly default; daily only for opt-in “hot” items).
5. Do not ship service-account keys or scrape tooling as a public consumer app.

## When a fetcher breaks

- Fail the item/store with a typed error (`selector_broken`, `http_error`, `not_found`).
- Log enough context to fix (URL, status code, which parser path).
- Leave prior price in the Sheet until a successful refresh (do not blank on failure unless explicitly requested).

## Fixture URL (manual only)

Sample Amazon product used in `sheet/sample-rows.csv` and `worker` docs:

`https://www.amazon.com/dp/B0D1XD1ZV3`

It is **not** a stable contract — Amazon may change the page or block automated fetches. Unit tests should use saved HTML fixtures; live `refresh` / `doctor` against this URL is optional smoke only.