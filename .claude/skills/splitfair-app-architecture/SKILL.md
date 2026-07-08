---
name: splitfair-app-architecture
description: The right-sized SwiftUI architecture for SplitFair — Model-View with @Observable, one shared store, zero third-party dependencies, iOS 17 target. Use when setting up the app, choosing state/navigation patterns, adding a screen, or whenever tempted to reach for ViewModels, SwiftData, TCA, or other patterns that would be over-engineering here.
---

# SplitFair — app architecture

Three thin screens (Bills · The Bill · Totals) over one shared store that owns the whole library. The correct altitude is **Model-View (MV) with `@Observable`** — Apple's current default. Pour the engineering budget into the money math (`splitfair-money-math`), keep everything else small. (EPIC 10 grew this from the original two-screen, single-bill app; it is still ONE store, still no SwiftData/ViewModels.)

```
Views (SwiftUI)  ─ read store.totals, send intents
      │
BillStore  @MainActor @Observable   ─ the ONE state object   → splitfair-state-store
      │
BillCore   (local SPM package, Foundation ONLY)  ─ pure, tested → splitfair-money-math, splitfair-domain-model
```

## Decisions

| Area | Choice |
|---|---|
| UI | 100% SwiftUI. `@main App` + `WindowGroup` + `NavigationStack`; plain pushes Home → Bill → Totals via `.navigationDestination(isPresented:)` — **no** `NavigationPath`/route enums/Coordinators. No AppDelegate/SceneDelegate, no `UIViewRepresentable`. |
| State | Exactly one `@MainActor @Observable final class BillStore` owning the bills library + roster + selection. `totals` and `balances` are **computed** (live recompute, no drift, no "Calculate" button). |
| Reactivity | `@Observable` (Observation framework). **Never** `ObservableObject`/`@Published`/Combine. |
| Concurrency | Swift 6.2 Approachable Concurrency (default actor = `@MainActor`). Value-type models are already `Sendable`. |
| Deployment target | **iOS 17.0** (18 acceptable), built against the newest SDK. iOS 17 is where `@Observable` + `.sensoryFeedback` land. Liquid Glass comes from the SDK you compile against, not the floor. |
| Dependencies | **Zero** third-party packages. The only module is your own local `BillCore` package. |

## Ownership & injection

```swift
@main struct SplitFairApp: App {
    @State private var store = BillStore()          // constructed ONCE at the root
    @Environment(\.scenePhase) private var phase
    var body: some Scene {
        WindowGroup { NavigationStack { BillScreen() }.environment(store) }
            .onChange(of: phase) { _, new in if new != .active { Task { await store.flush() } } }
    }
}
```
Read it downstream with `@Environment(BillStore.self) private var store`; use `@Bindable var store = store` locally only where a `TextField` needs a two-way binding. Keep transient input/focus/expanded state as view-local `@State`/`@FocusState`.

## Reject as over-engineering (for THIS app)

- **ViewModels (one per screen)** — would fracture the single bill into multiple sources of truth. Both screens read the same store.
- **TCA / Redux / VIPER / Clean / Coordinators / DI container** — machinery for async/side-effects/large composed state this app doesn't have.
- **SwiftData / Core Data** — a query/relationship/migration/sync engine for the exact collection features SplitFair bans; forces reference-type `@Model` against value-type money. Use one JSON file (`splitfair-persistence`).
- **`NavigationPath` / Route enums** — one `NavigationLink` is enough.

If you feel the need for any of the above, stop and reconsider — the task is almost certainly simpler than the pattern.
