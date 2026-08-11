# Family Price Tracker — iOS

SwiftUI client for the two primary users. **Requires a Mac + Xcode** to build.

## Status

Read-only list + detail UI against a **documented sample JSON stub** (`Resources/sample_items.json` via `SampleSheetClient`). That satisfies the v0.5.0 list/detail milestone until Google Sign-In is wired on a Mac.

Live Sheet access: follow the research note in [docs/ios-distribution.md](../docs/ios-distribution.md) (OAuth, iOS client ID, readonly Sheets scope). Swap `SampleSheetClient` for a Sheets-backed `SheetClient` — do not embed the worker service-account JSON.

## Structure

```
FamilyPriceTracker/
  Models/Item.swift
  Views/ItemListView.swift
  Views/ItemDetailView.swift
  Services/SheetClient.swift   # SampleSheetClient stub; OAuth Sheets later
  Resources/sample_items.json
  FamilyPriceTrackerApp.swift
```

Until an `.xcodeproj` is generated on a Mac, treat the Swift sources here as the source of truth to copy into a new Xcode App project (iOS 17+).
