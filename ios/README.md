# Family Price Tracker — iOS

SwiftUI client for the two primary users. **Requires a Mac + Xcode** to build and to run Google Sign-In. Swift sources in this folder are the source of truth on Windows.

## Status

v0.7.0: add **text** items and **tracked** items from a product URL (confirm-first), plus a per-item store checklist, against a **documented sample stub** (`Resources/sample_items.json`, `sample_owners.json`, `sample_stores.json` via `SampleSheetClient`). Mutations stay in memory for the session.

Paste Amazon, Target, or Walmart URLs only. The app stores the URL and `stores` column; it does **not** fetch prices. Target/Walmart price write-back is v0.8. Custom stores are v1.2.

Live Google Sheet read/write is **v0.9.1** (Mac session): Google Sign-In, write scope, Xcode project, device install. `GoogleSheetsClient` is written but untested until then. Do not embed the worker service-account JSON.

Until v0.9.1, relatives still add/edit in the Google Sheet if they need a durable row.

## Structure

```
FamilyPriceTracker/
  Models/Item.swift
  Models/StoreCatalog.swift        # store directory + URL host detect
  Views/ItemListView.swift
  Views/ItemDetailView.swift       # notes, stores checklist, per-store URLs
  Views/AddTextItemView.swift      # confirm-before-save
  Views/AddURLItemView.swift       # paste URL; confirm-before-save
  Services/SheetClient.swift       # protocol + SampleSheetClient
  Services/WishlistStore.swift
  Services/GoogleSheetsClient.swift  # Sheets REST; Sign-In in v0.9.1
  Resources/sample_items.json
  Resources/sample_owners.json     # Config list owners for the stub
  Resources/sample_stores.json     # Config store directory for the stub
  FamilyPriceTrackerApp.swift
```

Until an `.xcodeproj` is generated on a Mac (v0.9.1), copy these sources into a new Xcode App project (iOS 17+). Include **all three** JSON resources in the app bundle.

Live Sheet access: [docs/ios-distribution.md](../docs/ios-distribution.md).
