---
name: splitfair-persistence
description: Local, offline-only persistence for SplitFair — a library of bills (one JSON file each) plus a friends roster in Application Support, auto-saved with debounce plus a scenePhase flush, with no accounts/sync. Use when saving/restoring bills, handling app background/relaunch, implementing Clear bill, migrating the legacy draft, or configuring the app's privacy posture.
---

# SplitFair — persistence

Persist a **local library of bills** (one `Codable Bill` per JSON file under `Bills/`) plus a `roster.json` (the friends and which one is "you"), all in Application Support. No SwiftData, no accounts, no sync — everything stays on device ("Data Not Collected"). (EPIC 10 replaced the original single-file `BillDraftStore` with this `LibraryStore`; a one-time migration imports any legacy `current-bill.json`.)

## Store

```swift
// One JSON file per bill + a roster file. Base URL injected so it's unit-testable against a temp dir.
struct LibraryStore {
    let baseURL: URL                       // Application Support (or a temp dir in tests)
    func loadBills() -> [Bill]             // all Bills/*.json, newest first, skips corrupt files
    func saveBill(_ bill: Bill) throws     // Bills/<id>.json, atomic
    func deleteBill(_ id: Bill.ID)         // remove one file
    func loadRoster() -> RosterSnapshot    // { people, meID } from roster.json
    func saveRoster(_ snapshot: RosterSnapshot) throws
    func migrateLegacyDraftIfNeeded()      // import + delete a pre-EPIC-10 current-bill.json, once
}
```

## Rules

- **Location: Application Support**, not Documents (Documents is user-visible + iCloud-exposed). Create the directory with `withIntermediateDirectories: true` on first launch.
- **Atomic writes** (`options: [.atomic]`). **Keep default file protection** — `.completeFileProtection` would make a save firing exactly at screen-lock *fail*, which is the loss case you most need to survive.
- **Debounce ~600 ms** with a cancel-and-reschedule `Task { try? await Task.sleep(...) }` (not Combine/Timer). Snapshot the `Sendable` `Bill` and write off the main actor.
- **Also flush immediately** when `scenePhase != .active` (belt-and-suspenders against background/lock).
- **Load the library once at launch**; a missing/corrupt bill file is skipped, never fatal. `Bill` decodes leniently (`decodeIfPresent` defaults), so an old-shape bill loads without version branches.
- **Only the edited bill's file rewrites** (per-bill debounced save). The roster saves on roster/"you" changes.
- **Clear bill** = delete the open bill's file and **cancel the pending debounced save** (so no stray write resurrects it), then deselect so the UI returns to the library.

## Privacy posture (part of persistence's promise)

- Ship `PrivacyInfo.xcprivacy`: `NSPrivacyTracking = false`, empty collected-data & tracking-domains, UserDefaults reason `CA92.1` (if used).
- `ITSAppUsesNonExemptEncryption = NO`. No AppTrackingTransparency, no `.entitlements`, no network code anywhere. The App Store privacy label reads **"Data Not Collected."**
