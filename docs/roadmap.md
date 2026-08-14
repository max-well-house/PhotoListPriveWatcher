# Roadmap

Product: **Family Price Tracker** (repo: PhotoListPriveWatcher). Issue board follows Meshen-style versioned milestones.

## Eras

| Era | Focus | Milestones |
|---|---|---|
| 0 Foundation | Docs, schema, worker skeleton | v0.0.1 → v0.2.0 |
| 1 Sheet + sync | Live Sheet + Amazon vertical slice + iOS read | v0.3.0 → v0.5.0 |
| 2 App CRUD | Text items, URL add, more retailers | v0.6.0 → v0.8.0 |
| 3 Identity | Barcode/UPC, Mac live iOS, photos | v0.9.0 → v1.0.0 |
| 4 Cadence | Scheduled refresh | v1.1.0 |
| 5 Expand | Custom stores, more retailers | v1.2.0 → v1.3.0 |

## Vertical slice (build first)

**v0.0.1 → v0.4.0:** monorepo + schema → worker Sheets client → Amazon URL fetch → `refresh --item` writes Sheet.

Then **v0.5.0** iOS read-only (sample stub on Windows). Live device/Sign-In is **v0.9.1**.

## Milestone summaries

- **v0.0.1 Repo + vision** — layout, vision/roadmap/decisions, legal, LICENSE — **done**
- **v0.1.0 Sheet schema** — Items/Config tabs, sample CSV, formatting guide — **done** (2026-08-11)
- **v0.2.0 Worker skeleton** — package, config, fetcher protocol — **done**
- **v0.3.0 Sheets sync foundation** — SA read/write, `list-items` — **done** (2026-08-11)
- **v0.4.0 Vertical slice** — Amazon fetcher, `refresh`, `add-tracked` — **done**
- **v0.5.0 iOS read-only list** — SwiftUI list + tappable prices (sample stub + Sign-In research) — **done** (2026-08-11)
- **v0.6.0 Text items + lists + priority** — app CRUD for text asks (sample stub until v0.9.1)
- **v0.7.0 Add via URL + manual stores** — per-item store checklist
- **v0.8.0 Target + Walmart** — next fetchers + `doctor` CLI
- **v0.9.0 Barcode / UPC** — confirm-first identity (sources; camera smoke in v0.9.1)
- **v0.9.1 Mac session (live iOS)** — Xcode + Sign-In + device; smoke 0.5–0.9 on a real Mac **before v1.0.0**
- **v1.0.0 Photos** — Sheet-visible thumbnails (still needs a Mac)
- **v1.1.0 Scheduled refresh** — weekly / hot daily
- **v1.2.0 Custom stores** — YouTuber merch URLs
- **v1.3.0 More retailers** — tools/outdoors/clothing as needed
- **Up next (v0.4 polish)** — dry-run, UUID docs, fixture URL, priority formatting — **done** (2026-08-11)
- **Unplanned** — history, deals, zip pricing, Android (non-goals / later)

See GitHub **Milestones** and **Issues** for Goal / Acceptance criteria detail.
