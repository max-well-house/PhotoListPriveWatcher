# iOS distribution

Family Price Tracker is a **private** two-device app. No App Store launch planned for v1.

## Options

1. **Xcode → device** — Developer Mode / personal team; fine for day-to-day while iterating.
2. **TestFlight (recommended later)** — Internal testing for you + spouse; requires Apple Developer Program.
3. **Ad hoc / enterprise** — not needed at family scale.

## Dev constraint

The monorepo is editable on Windows, but **building the SwiftUI app requires a Mac** (or a cloud Mac CI). Sources under `ios/` are the source of truth on Windows; generate or sync an `.xcodeproj` on a Mac when you are ready to run.

Until Google Sign-In is wired, the app loads **sample JSON** (documented stub). That is enough for list/detail UI work; live Sheet reads wait for OAuth below.

## Research: Google Sign-In + Sheets API (chosen approach)

**Approach:** Google Sign-In (OAuth) for the two editors who own the Sheet — same as [Decision #002](decisions.md). Do **not** embed the worker service-account JSON in the app.

| Concern | Choice |
|---|---|
| Auth | Google Sign-In for iOS (OAuth user tokens) |
| API | Google Sheets API v4 over HTTPS |
| Read-only milestone | Scope `https://www.googleapis.com/auth/spreadsheets.readonly` |
| Later CRUD (v0.6+) | Escalate to `https://www.googleapis.com/auth/spreadsheets` |
| Sheet access | Share the Sheet with the same Google accounts (Editor); worker SA stays on the PC only |
| SDK | Google Sign-In for iOS + URL session / GoogleAPIClientForREST, or GTMAppAuth + Sheets REST |

### Cloud / GCP setup (iOS OAuth client)

Run these once in Google Cloud (same project as the worker Sheets API is fine):

1. Enable **Google Sheets API** (already needed for the worker).
2. **APIs & Services → Credentials → Create credentials → OAuth client ID**.
3. Application type: **iOS**. Bundle ID must match the Xcode app (e.g. `com.family.FamilyPriceTracker` — pick one and keep it stable).
4. Copy the **iOS client ID** and the **reversed client ID** (URL scheme of the form `com.googleusercontent.apps.…`).
5. In Xcode / `Info.plist`, register the reversed client ID under **URL Types** so the Sign-In redirect returns to the app.
6. Configure the OAuth consent screen for **Internal** or **Testing** with the two family Google accounts as test users (External + verification is unnecessary at family scale).
7. Share the Google Sheet with those two accounts as **Editor** (relatives can stay Viewer).

Store client IDs in local Xcode config or xcconfig — **never commit** secrets or a service-account JSON into `ios/`.

### App wiring (when on a Mac)

1. Add the Google Sign-In package dependency in Xcode.
2. Call Sign-In, request the Sheets readonly scope, obtain an access token.
3. Replace `SampleSheetClient` in `ios/.../Services/SheetClient.swift` with a live client that `GET`s `'{ItemsTab}'!A2:V` (same columns as [sheet/SCHEMA.md](../sheet/SCHEMA.md)).
4. Pass `SHEET_ID` (and tab name) via build settings or a non-committed local plist — same IDs as `.env` on the worker, not the SA path.

### Windows note

You can edit Swift and docs on Windows, but Sign-In, keychain, and device install only work after an Xcode build on a Mac (or cloud Mac). Do not block list/detail UI progress on OAuth.
