# Worker — Family Price Tracker

Python job that reads tracked rows from the Google Sheet, fetches retailer prices, and writes results back.

## Setup (Windows)

```powershell
cd worker
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

Configure env (repo root `.env` or export):

- `SHEET_ID`
- `GOOGLE_APPLICATION_CREDENTIALS` — path to service-account JSON

See [../docs/setup-google.md](../docs/setup-google.md).

## Commands

```powershell
# From worker/ with PYTHONPATH or installed editable:
$env:PYTHONPATH = "src"
# Manual smoke against a real Sheet (creds only; no price fetch):
python -m family_price_tracker list-items
python -m family_price_tracker add-tracked --url "https://www.amazon.com/dp/B0..." --name "Thing" --notes "black" --priority 2 --list Me
python -m family_price_tracker refresh --item <id>
python -m family_price_tracker refresh --due
# Fetch and print would-write values; no Sheet mutations (still reads the Sheet):
python -m family_price_tracker refresh --item <id> --dry-run
python -m family_price_tracker refresh --due --dry-run
python -m family_price_tracker doctor
```

New rows from `add-tracked` mint a UUID `id` once (never rewritten on refresh). See [../docs/decisions.md](../docs/decisions.md) Decision #006.

## Amazon fixture URL

For manual fetcher / `doctor` checks, use the sample ASIN also in `sheet/sample-rows.csv`:

```
https://www.amazon.com/dp/B0D1XD1ZV3
```

**Expect breakage** when Amazon changes HTML. Prefer `tests/test_amazon_parser.py` (saved HTML) for CI; live hits are optional and flaky. See [../docs/scraping-and-legal.md](../docs/scraping-and-legal.md).

## Legal

Fetchers are best-effort for personal/family use. See [../docs/scraping-and-legal.md](../docs/scraping-and-legal.md).
