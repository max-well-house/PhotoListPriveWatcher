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
python -m family_price_tracker list-items
python -m family_price_tracker add-tracked --url "https://www.amazon.com/dp/B0..." --name "Thing" --notes "black" --priority 2 --list Me
python -m family_price_tracker refresh --item <id>
python -m family_price_tracker refresh --due
python -m family_price_tracker doctor
```

## Legal

Fetchers are best-effort for personal/family use. See [../docs/scraping-and-legal.md](../docs/scraping-and-legal.md).
