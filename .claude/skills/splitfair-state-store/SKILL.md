---
name: splitfair-state-store
description: BillStore, the single @MainActor @Observable state object for SplitFair that owns the current Bill, exposes intent methods, and derives totals live. Use when adding UI state, wiring a screen to data, adding an action (assign, add person/item, set tax/tip, clear), or connecting persistence to state.
---

# SplitFair — state store

One observable object, shared by both screens, is the entire state layer. No ViewModels (`splitfair-app-architecture`).

```swift
import BillCore

@MainActor @Observable
final class BillStore {
    private(set) var bill: Bill = .empty                 // single source of truth
    var totals: BillResult { BillMath.compute(bill) }    // computed ⇒ live recompute, zero drift

    // Intents — the only way the bill mutates:
    func addPerson(_ name: String) { … }
    func addItem(_ amount: Money, label: String) { … }
    func toggleAssignment(item: Item.ID, person: Person.ID) { … }
    func assignToEveryone(item: Item.ID) { … }
    func setTax(_ m: Money) { … }
    func setTip(_ t: TipMode) { … }
    func deleteItem(_ id: Item.ID) { … }
    func deletePerson(_ id: Person.ID) { … }   // drop from shared items; solo items → unassigned
    func clear() { … }                          // → .empty, cancel pending save, delete file

    // Persistence hooks (splitfair-persistence): bill didSet → scheduleSave(); flush() on scenePhase leave.
}
```

## Rules

- **`bill` is `private(set)`.** Views read it but mutate only through intent methods — a view can never corrupt the bill.
- **`totals` is computed, never stored.** This gives live recompute (no "Calculate" button) and eliminates drift for free.
- **Create once, inject.** `@State private var store = BillStore()` at the App root, `.environment(store)`, read with `@Environment(BillStore.self)`. Never construct the store inside a frequently-rebuilt child (`@State` re-runs its initializer on rebuild).
- **Two-way binding** only where a `TextField` needs it: `@Bindable var store = store` locally.
- Keep transient input/focus/expanded UI state as view-local `@State`/`@FocusState`, not on the store.
- `deletePerson` must drop the person from every item's `assigneeIDs`; any item left with an empty set becomes unassigned (`splitfair-status-flags`), never silently dropped.
