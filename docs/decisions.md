# Decisions

Living ADR-style notes. Newest first within each number.

## Decision #001 — Stack

- **SoT:** Google Sheet (+ Drive for images later).
- **Sync:** iOS and worker talk to the Sheets API directly (no always-on home API).
- **Worker:** Python 3.11+ on the home PC.
- **iOS:** SwiftUI; private distribution (TestFlight / sideload), not App Store launch.
- **First retailer:** Amazon via product URL.

**Why:** Family-scale; Sheet already used by relatives; Python fits scraping/HTTP; native iOS for camera/barcode later.

## Decision #002 — Auth

- **Worker:** Google Cloud service account JSON on the home machine; Sheet shared with the SA email as Editor.
- **iOS:** Google Sign-In (OAuth) for the two editors who own the Sheet.

**Why:** SA credentials must not ship inside the mobile app; OAuth matches real Google users.

## Decision #003 — Scraper isolation

Each retailer is a module returning `PriceResult | FetchError`. A run continues after per-item/per-store failures and logs them. Prefer official/affiliate endpoints when available; HTML parsers are best-effort and must fail detectably when selectors break.

## Decision #004 — No paid token APIs in the core loop

Product matching prefers barcode/UPC and on-device or self-hosted approaches. Paid vision/LLM APIs are optional later, not required for add → Sheet → refresh.

## Decision #005 — Priority and lists

- Priority: integer **1–5** (1 = highest).
- List owners live on a **Config** tab (default: Me, Spouse, Kid A, Kid B, Shared).
- Status: `wanted` | `purchased` | `dropped`.
- Item type: `tracked` | `text`.

## Decision #006 — Stable item ids (UUID)

- New rows (worker `add-tracked`, future iOS create) mint **`id` = `uuid.uuid4()` string** once at insert.
- Never rewrite `id` on edit or refresh; Sheet row identity is the UUID, not the row number.
- Sample CSV may use readable demo ids (`sample-text-001`); production rows use real UUIDs.

**Why:** Worker and iOS need a stable key across sorts, inserts, and price updates without clobbering notes/priority.
