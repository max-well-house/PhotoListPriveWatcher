# Google setup (Sheet + service account)

1. Create a Google Cloud project (or reuse one).
2. Enable **Google Sheets API** (and Drive API later for images).
3. Create a **service account**; download JSON key → store outside git (e.g. `secrets/service-account.json`).
4. Copy the service account email (`…@….iam.gserviceaccount.com`).
5. Create a Google Sheet; add tabs **Items** and **Config** per [../sheet/SCHEMA.md](../sheet/SCHEMA.md).
6. **Share** the Sheet with the service account email as **Editor**.
7. Copy the Sheet ID from the URL (`https://docs.google.com/spreadsheets/d/<SHEET_ID>/edit`).
8. Copy `.env.example` → `.env` at repo root (or export env vars) and set:
   - `SHEET_ID`
   - `GOOGLE_APPLICATION_CREDENTIALS` → path to the JSON key

Smoke test from `worker/`:

```bash
python -m family_price_tracker list-items
```
