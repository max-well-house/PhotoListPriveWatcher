# Family Price Tracker — iOS

SwiftUI client for the two primary users. **Requires a Mac + Xcode** to build.

## Status

Scaffold only: models + list/detail UI against a local sample JSON so the project structure is clear on Windows too. Wire Google Sign-In + Sheets API on a Mac (see research issue on the board / [docs/ios-distribution.md](../docs/ios-distribution.md)).

## Planned structure

```
FamilyPriceTracker/
  Models/Item.swift
  Views/ItemListView.swift
  Views/ItemDetailView.swift
  Services/SheetClient.swift   # TODO: Google Sheets API
  Resources/sample_items.json
  FamilyPriceTrackerApp.swift
```

Until an `.xcodeproj` is generated on a Mac, treat the Swift sources here as the source of truth to copy into a new Xcode App project (iOS 17+).
