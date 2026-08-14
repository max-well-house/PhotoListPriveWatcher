# Sheet schema

Source of truth for Family Price Tracker. Two tabs: **Items** and **Config**.

## Items tab (header row 1)

| Column | Key | Notes |
|---|---|---|
| A | `id` | Stable UUID string — mint once on create (`uuid4`); never rewrite (see Decision #006) |
| B | `photo` | URL or blank (Drive later) |
| C | `name` | Product or text ask |
| D | `list_owner` | Must match Config list owners |
| E | `priority` | Integer 1–5 (1 = highest) |
| F | `type` | `tracked` or `text` |
| G | `size` | Optional |
| H | `color` | Optional |
| I | `qty` | Optional number |
| J | `notes` | Freeform prefs |
| K | `status` | `wanted` \| `purchased` \| `dropped` |
| L | `stores` | Comma-separated store keys checked for this item (e.g. `amazon`) |
| M | `amazon_price` | Number or currency text |
| N | `amazon_url` | Product URL (display as hyperlink in Sheet) |
| O | `target_price` | Reserved |
| P | `target_url` | Reserved |
| Q | `walmart_price` | Reserved |
| R | `walmart_url` | Reserved |
| S | `last_checked` | ISO-8601 UTC when worker last succeeded for any store |
| T | `upc` | Optional |
| U | `asin` | Optional Amazon ASIN |
| V | `hot` | `yes` for daily refresh later; blank = weekly |

## Formatting (relatives / phone Sheet)

Workers and the iOS app use separate `amazon_price` + `amazon_url` columns. For relatives viewing the Sheet itself:

### Clickable price (HYPERLINK)

In an empty helper column (or replace the price display cell), show a tappable price:

```
=HYPERLINK(N2, "$" & TEXT(M2, "0.00"))
```

Copy down for each row. Or keep price + URL in separate columns (app uses both).

### Freeze header row

So column names stay visible while scrolling:

1. Select row 1 (or click the Items tab with the header selected).
2. **View → Freeze → 1 row** (on desktop Sheets).
3. On mobile Sheets: open the sheet → tap the sheet menu → **View** → **Freeze** → **1 row**.

Frozen headers and HYPERLINK cells open correctly in the Google Sheets app on phone; relatives can tap a price to open the store URL in the browser.

### Conditional formatting by priority

Make high-priority rows obvious for relatives (desktop Sheets):

1. Select the Items data range (e.g. `A2:V` or the whole used range).
2. **Format → Conditional formatting**.
3. Add a rule: **Custom formula is** `=$E2=1` → strong fill (e.g. light red / pink).
4. Add a second rule: **Custom formula is** `=$E2=2` → softer fill (e.g. light orange).
5. Apply to the same range; keep priority **1** above **2** so both don’t fight.

Priority column is E (`priority`, 1 = highest). Mobile Sheets shows the colors; editing rules is easier on desktop.

### Data validation: list_owner

Restrict Items `list_owner` (column D) to Config owners so relatives cannot invent list names:

1. Select `D2:D` (or the used data range) on the **Items** tab.
2. **Data → Data validation → Add rule**.
3. Criteria: **Dropdown (from a range)** → `Config!A2:A` (the names under the `list_owner` header, not the header itself).
4. Reject input that is not on the list (a warning is weaker — reject keeps the app and Sheet aligned).

The iOS app loads the same Config column (`fetchListOwners`) and refuses to save an unknown owner.

## Config tab

### List owners (column A header `list_owner`)

```
list_owner
Me
Spouse
Kid A
Kid B
Shared
```

### Store directory (columns C–E)

| store_key | display_name | enabled |
|---|---|---|
| amazon | Amazon | yes |
| target | Target | yes |
| walmart | Walmart | yes |
| costco | Costco | no |
| custom | Custom / other | yes |

## Sample import

Use [sample-rows.csv](sample-rows.csv) for the Items tab (paste or File → Import).
