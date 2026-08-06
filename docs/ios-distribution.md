# iOS distribution

Family Price Tracker is a **private** two-device app. No App Store launch planned for v1.

## Options

1. **Xcode → device** — Developer Mode / personal team; fine for day-to-day while iterating.
2. **TestFlight (recommended later)** — Internal testing for you + spouse; requires Apple Developer Program.
3. **Ad hoc / enterprise** — not needed at family scale.

## Dev constraint

The monorepo is editable on Windows, but **building the SwiftUI app requires a Mac** (or a cloud Mac CI). Scaffold under `ios/` is intentionally thin until Xcode is available.

## Google Sign-In

iOS will use OAuth against the same Google account(s) that can edit the Sheet. Do not embed the worker service-account JSON in the app.
