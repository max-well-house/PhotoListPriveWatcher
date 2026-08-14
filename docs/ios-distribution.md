# iOS distribution

Family Price Tracker is a **private** two-device app. No App Store launch planned for v1.

## Options

1. **Xcode → device** — Developer Mode / personal team; fine for day-to-day while iterating.
2. **TestFlight (recommended later)** — Internal testing for you + spouse; requires Apple Developer Program.
3. **Ad hoc / enterprise** — not needed at family scale.

## Dev constraint

The monorepo is editable on Windows, but **building the SwiftUI app requires a Mac** (or a cloud Mac). Sources under `ios/` are the source of truth on Windows; generate or sync an `.xcodeproj` on a Mac during **v0.9.1**.

Until that Mac session, the app uses **sample JSON** (`SampleSheetClient`) for list, detail, and text-item add/edit. Add/edit is confirm-before-save; mutations are in-memory only. Relatives who need a durable row still use the Google Sheet.

Do not mimic macOS on a Windows PC. Do not put the worker service-account JSON in the app.

## Research: Google Sign-In + Sheets API (chosen approach)

**Approach:** Google Sign-In (OAuth) for the two editors who own the Sheet — same as [Decision #002](decisions.md).

| Concern | Choice |
|---|---|
| Auth | Google Sign-In for iOS (OAuth user tokens) |
| API | Google Sheets API v4 over HTTPS (`GoogleSheetsClient`) |
| Scope | `https://www.googleapis.com/auth/spreadsheets` (read + write). Readonly is not enough for v0.6 CRUD. |
| Sheet access | Share the Sheet with the same Google accounts (Editor); worker SA stays on the PC only |
| SDK | Google Sign-In for iOS + `URLSession` Sheets REST (`GoogleAuthSession` + `GoogleSheetsClient`) |

### Cloud / GCP setup (iOS OAuth client)

Run these once in Google Cloud (same project as the worker Sheets API is fine):

1. Enable **Google Sheets API** (already needed for the worker).
2. **APIs & Services → Credentials → Create credentials → OAuth client ID**.
3. Application type: **iOS**. Bundle ID must match the Xcode app (e.g. `com.family.FamilyPriceTracker` — pick one and keep it stable).
4. Copy the **iOS client ID** and the **reversed client ID** (URL scheme of the form `com.googleusercontent.apps.…`).
5. In Xcode / `Info.plist`, register the reversed client ID under **URL Types** so the Sign-In redirect returns to the app.
6. Configure the OAuth consent screen for **Internal** or **Testing** with the two family Google accounts as test users (External + verification is unnecessary at family scale).
7. Share the Google Sheet with those two accounts as **Editor** (relatives can stay Viewer).

Store client IDs and `SHEET_ID` in local Xcode config / Info.plist / xcconfig — **never commit** them or a service-account JSON into `ios/`. Optional keys: `SHEET_ID`, `SHEET_ITEMS_TAB`, `SHEET_CONFIG_TAB` (see `SheetsRuntimeConfig`).

### v0.9.1 Mac session (live iOS)

Checklist milestone **before v1.0.0**. Not new features — prove everything already coded on Windows:

1. New Xcode iOS 17+ app; copy `ios/FamilyPriceTracker/` sources; add **all three** sample JSON files (`sample_items.json`, `sample_owners.json`, `sample_stores.json`) to the bundle.
2. Add the Google Sign-In package. Implement `GoogleAuthSession` with the **spreadsheets** write scope (constant on `SheetsRuntimeConfig`).
3. Point `FamilyPriceTrackerApp` at `GoogleSheetsClient` when `SheetsRuntimeConfig.fromInfoDictionary()` is present; keep `SampleSheetClient` as fallback.
4. Install on at least one family iPhone (Xcode device or TestFlight).
5. Smoke:
   - Sign In → list loads from the live Sheet.
   - Add a text item (confirm UI) → row visible to a relative → edit notes/priority/list/status → Sheet matches.
   - **v0.7:** paste an Amazon product URL → confirm name/stores → Save → relative sees `type=tracked`, `stores`, and `amazon_url`. Edit the store checklist and a Target/Walmart URL on detail; Config store directory (columns C–E) drives the checklist. On the home PC, `refresh --item` skips unchecked stores and skips a checked store with no URL.
   - **v0.9:** barcode on a **physical device** if those sources exist.

Photos / Drive thumbnails stay **v1.0.0** and still need a Mac.

### Windows note

You can edit Swift and docs on Windows. Sign-In, keychain, Simulator, and device install only work on a Mac (or rented cloud Mac). Do not block add/edit UI progress on OAuth — that closeout is v0.9.1.
