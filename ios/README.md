# Family Price Tracker — iOS

SwiftUI client for the two primary users. **Requires a Mac + Xcode** to build and to run Google Sign-In. Swift sources in this folder are the source of truth on Windows.

## Status

v0.6.0: add/edit **text** wishlist items (name, notes, priority 1–5, list owner, status) against a **documented sample stub** (`Resources/sample_items.json` + `sample_owners.json` via `SampleSheetClient`). Mutations stay in memory for the session.

Live Google Sheet read/write is **v0.9.1** (Mac session): Google Sign-In, write scope, Xcode project, device install. `GoogleSheetsClient` is written but untested until then. Do not embed the worker service-account JSON.

Until v0.9.1, relatives still add/edit in the Google Sheet if they need a durable row.

## Structure

```
FamilyPriceTracker/
  Models/Item.swift
  Views/ItemListView.swift
  Views/ItemDetailView.swift
  Views/AddTextItemView.swift      # confirm-before-save
  Services/SheetClient.swift       # protocol + SampleSheetClient
  Services/WishlistStore.swift
  Services/GoogleSheetsClient.swift  # Sheets REST; Sign-In in v0.9.1
  Resources/sample_items.json
  Resources/sample_owners.json     # Config list owners for the stub
  FamilyPriceTrackerApp.swift
```

Until an `.xcodeproj` is generated on a Mac (v0.9.1), copy these sources into a new Xcode App project (iOS 17+). Include both JSON resources in the app bundle.

Live Sheet access: [docs/ios-distribution.md](../docs/ios-distribution.md).
