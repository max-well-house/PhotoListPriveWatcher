# Sheet schema

Source of truth for Family Price Tracker. Two tabs: **Items** and **Config**.

## Items tab (header row 1)

| Column | Key | Notes |
|---|---|---|
| A | `id` | Stable UUID string |
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

### Hyperlink tip

In Google Sheets you can show a clickable price with:

```
=HYPERLINK(N2, "$" & TEXT(M2, "0.00"))
```

Or keep price + URL in separate columns (app uses both).

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
