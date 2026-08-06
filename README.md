# Family Price Tracker

Family wishlist + multi-retailer price tracker. Working title; repo name is historical (`PhotoListPriveWatcher`).

**You + spouse:** iOS app. **Everyone else:** one shared **Google Sheet** (source of truth). **Home PC:** scheduled Python worker refreshes prices.

## Vision (short)

Add items (text, URL, later photo/barcode). Tracked items store **per-store prices as clickable product links**. Matching is confirm-first. Scrapers are isolated and best-effort — prices matter more than deals.

See [docs/vision.md](docs/vision.md), [docs/roadmap.md](docs/roadmap.md), [docs/decisions.md](docs/decisions.md).

## Layout

```
ios/       SwiftUI app (Mac/Xcode to build)
worker/    Python price-refresh job (runs on home Windows/Mac)
sheet/     Schema + sample CSV for Google Sheet
docs/      Vision, roadmap, setup, legal
```

## First demo (vertical slice)

1. Create a Google Sheet from [sheet/SCHEMA.md](sheet/SCHEMA.md); import [sheet/sample-rows.csv](sheet/sample-rows.csv).
2. Share the Sheet with a Google Cloud **service account** (Editor). See [docs/setup-google.md](docs/setup-google.md).
3. Copy `.env.example` → `.env`; set `SHEET_ID` and credentials path.
4. In `worker/`:

```bash
python -m venv .venv
.\.venv\Scripts\activate          # Windows
pip install -r requirements.txt
python -m family_price_tracker list-items
python -m family_price_tracker add-tracked --url "https://www.amazon.com/dp/..." --name "Example" --notes "black / large" --priority 2 --list Me
python -m family_price_tracker refresh --item <id>
```

5. Open the Sheet — price + product URL should be filled. Family can follow links without the app.

iOS read-only list is scaffolded under `ios/` (needs a Mac to compile).

## Non-goals (v1)

Public SaaS, deal scraping, full price-history charts, local zip inventory, Android app, silent auto-linking of stores.

## Legal

Scraping big retailers is brittle and may conflict with their ToS. This project is **personal/family use only**. Prefer official/affiliate APIs when available. See [docs/scraping-and-legal.md](docs/scraping-and-legal.md).

## License

MIT — see [LICENSE](LICENSE).
