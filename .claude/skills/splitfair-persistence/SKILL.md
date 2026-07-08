---
name: splitfair-persistence
description: Local, offline-only persistence for SplitFair — the single current Bill encoded to one JSON file, auto-saved with debounce plus a scenePhase flush, with no history/accounts/sync. Use when saving/restoring the bill, handling app background/relaunch, implementing Clear bill, or configuring the app's privacy posture.
---

# SplitFair — persistence

Persist exactly **one** `Codable Bill` to a single JSON file. No history, no arrays of bills, no SwiftData, no sync. "No data beyond the current bill" is a feature.

## Store

```swift
// Codable Bill ↔ one file. Injected a URL so it's unit-testable against a temp dir.
final class BillDraftStore {
    let url = URL.applicationSupportDirectory.appending(path: "current-bill.json")
    func load() -> Bill { (try? JSONDecoder().decode(Bill.self, from: Data(contentsOf: url))) ?? .empty }
    func save(_ bill: Bill) throws { try JSONEncoder().encode(bill).write(to: url, options: [.atomic]) }
    func clear() { try? FileManager.default.removeItem(at: url) }
}
```

## Rules

- **Location: Application Support**, not Documents (Documents is user-visible + iCloud-exposed). Create the directory with `withIntermediateDirectories: true` on first launch.
- **Atomic writes** (`options: [.atomic]`). **Keep default file protection** — `.completeFileProtection` would make a save firing exactly at screen-lock *fail*, which is the loss case you most need to survive.
- **Debounce ~600 ms** with a cancel-and-reschedule `Task { try? await Task.sleep(...) }` (not Combine/Timer). Snapshot the `Sendable` `Bill` and write off the main actor.
- **Also flush immediately** when `scenePhase != .active` (belt-and-suspenders against background/lock).
- **Load once at launch**; on missing file OR decode failure → `Bill.empty`. That fallback means **no schema-migration machinery** is ever needed for this ephemeral draft.
- **Clear bill** = set `.empty`, **cancel the pending debounced save** (the `bill = .empty` assignment just scheduled one), then delete the file.

## Privacy posture (part of persistence's promise)

- Ship `PrivacyInfo.xcprivacy`: `NSPrivacyTracking = false`, empty collected-data & tracking-domains, UserDefaults reason `CA92.1` (if used).
- `ITSAppUsesNonExemptEncryption = NO`. No AppTrackingTransparency, no `.entitlements`, no network code anywhere. The App Store privacy label reads **"Data Not Collected."**
