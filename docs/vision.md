# Vision

Family Price Tracker is a **shared wishlist** for a small family, not a consumer product.

## Surfaces

1. **iOS app** (two primary users) — browse lists, add items, confirm product matches, pick stores, see prices as tappable links.
2. **Google Sheet** — same data for relatives who will never install an app. Photo/notes/priority must be obvious on a phone browser.
3. **Home computer worker** — scheduled job refreshes prices for tracked rows and writes back to the Sheet.

## Principles

- **One list.** Sheet is the source of truth. No second “suggestions” list.
- **Confirm before save.** Never silently assume product identity or store links.
- **Prices over deals.** Linked current price first; coupons/history later.
- **Maintainable fetchers.** One broken retailer must not kill the run; failures must be loud.
- **Family scale.** Two phones + one Sheet; no multi-tenant SaaS.

## Success (first demo)

- Items visible in Sheet (and eventually app).
- Text wishlist item with notes + priority.
- Tracked item with at least one store URL; price shows as a link.
- Worker updates that price once without hand-editing the Sheet.
- Relatives understand what to buy from the Sheet alone.
