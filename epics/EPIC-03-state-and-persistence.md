# EPIC 03 — App State & Local Persistence

> Wire the one observable store and the single-JSON-file draft persistence so the app has live, drift-free state that survives backgrounding.

## What this epic is for

BillCore is a complete, tested pure engine, but nothing in the app talks to it yet — the UI is still a placeholder and no bill outlives a launch. This epic introduces the single `@MainActor @Observable BillStore` that owns the current `Bill`, derives `totals` live off `BillMath.compute`, and exposes the only intents that may mutate the bill. It also adds `BillDraftStore`, which auto-saves that one bill to a single JSON file in Application Support and restores it on the next launch, with no history, accounts, or sync. When this epic lands, the app has real, reactive state that reconciles to the exact cent and quietly persists across backgrounding, lock, and cold start.

## Where we are before starting (starting state)

- A complete, tested `BillCore` engine exists at `Packages/BillCore/`: `Money`, `Currency`, `allocate(amountCents:weights:)`, `Person`, `Item`, `TipMode`, `Bill` (with `Bill.empty`), `BillMath.compute` → `BillResult`, `MoneyEdge`, and `Summary`, all green via `swift test` (including the allocate invariants and the $97.20 acceptance bill).
- The app skeleton from EPIC 01 builds, launches to a placeholder screen, and links `BillCore` via a local SPM package.
- The `App/`, `Features/`, `DesignSystem/`, `Persistence/`, and `Sharing/` folders exist as file-system-synchronized groups.
- There is **no** app-state layer: no `BillStore`, no injection at the App root, and nothing is written to or read from disk.

## What we will have after finishing (definition of done)

- A `@MainActor @Observable final class BillStore` in `SplitFair/App/BillStore.swift` with `private(set) var bill: Bill`, a **computed** `totals: BillResult` returning `BillMath.compute(bill)`, and the full set of intent methods (`addPerson`, `addItem`, `toggleAssignment`, `assignToEveryone`, `setTax`, `setTip`, `deleteItem`, `deletePerson`, `clear`).
- The store is constructed **once** at the `@main App` root via `@State private var store = BillStore()`, injected with `.environment(store)`, and read downstream with `@Environment(BillStore.self)`; two-way binding uses `@Bindable` only where a `TextField` needs it.
- `SplitFair/Persistence/BillDraftStore.swift` encodes exactly one `Codable Bill` to `current-bill.json` in Application Support, writes atomically with default file protection, and loads-or-returns `.empty` on missing/corrupt data (no migrations). Its file URL is injectable for tests.
- The current bill auto-saves with a ~600 ms cancel-and-reschedule debounce off the main actor, plus an immediate flush when `scenePhase != .active`, and restores on launch.
- `clear()` sets `.empty`, cancels the pending save, and deletes the file.
- Persistence is unit-tested against an injected temp URL: round-trip encode/decode, corrupt-file → `.empty` fallback, and `clear()` removes the file — all green via `swift test`.

## Dependencies

- Depends on: EPIC 02 — The Money Engine (BillCore) — the store and persistence both encode/compute over the finished `Bill`/`BillMath` API.
- Enables: EPIC 04 — Design System Foundation — a functional app with real state and persistence, ready to be styled with design tokens.

---

## Tasks

### Task 3.1 — Build the BillStore observable state object

**Skills to load:** `splitfair-state-store`, `splitfair-app-architecture`

**Why this matters:** `BillStore` is the entire state layer for the app — one object shared by both screens. Getting its shape right (one source of truth, computed totals, intents as the only mutation path) is what makes the whole app drift-free: totals can never disagree with the bill because they are recomputed, never stored. Getting it wrong — a stored total, a publicly-settable `bill`, per-screen ViewModels — fractures the single bill into multiple sources of truth and reintroduces exactly the drift bug the money engine was built to eliminate.

**What to do:**

1. Create `SplitFair/App/BillStore.swift` and `import BillCore`.
2. Declare `@MainActor @Observable final class BillStore`.
3. Add the single source of truth: `private(set) var bill: Bill = .empty`. Views read it but can never assign it.
4. Add the derived total as a **computed** property: `var totals: BillResult { BillMath.compute(bill) }`. Do not cache it, do not add a stored `total`, do not add a "Calculate" button anywhere — a stored total is the classic drift bug.
5. Implement the intent methods below as the **only** way `bill` mutates. Each reads/writes `bill` and lets `@Observable` publish the change.
6. Keep transient input/focus/expanded UI state (text being typed, which card is expanded, keyboard focus) **out** of the store — that lives as view-local `@State`/`@FocusState` in later epics.

**Technical details & suggestions:**

Intent sketches, grounded in the domain model (`Person`, `Item`, `Money`, `TipMode`, `Set<UUID>` assignments):

```swift
import BillCore

@MainActor @Observable
final class BillStore {
    private(set) var bill: Bill = .empty
    var totals: BillResult { BillMath.compute(bill) }   // computed ⇒ live recompute, zero drift

    func addPerson(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        // colorIndex is the STABLE roster index (splitfair-color-system)
        bill.people.append(Person(id: UUID(), name: trimmed, colorIndex: bill.people.count))
    }

    func addItem(_ amount: Money, label: String) {
        bill.items.append(Item(id: UUID(), label: label, amount: amount, assigneeIDs: []))
    }

    func toggleAssignment(item: Item.ID, person: Person.ID) {
        guard let i = bill.items.firstIndex(where: { $0.id == item }) else { return }
        if bill.items[i].assigneeIDs.contains(person) {
            bill.items[i].assigneeIDs.remove(person)     // 2+ assignees ⇒ split; going to 0 ⇒ unassigned
        } else {
            bill.items[i].assigneeIDs.insert(person)
        }
    }

    func assignToEveryone(item: Item.ID) {
        guard let i = bill.items.firstIndex(where: { $0.id == item }) else { return }
        bill.items[i].assigneeIDs = Set(bill.people.map(\.id))   // Shared-by-all
    }

    func setTax(_ m: Money) { bill.tax = m }
    func setTip(_ t: TipMode) { bill.tip = t }

    func deleteItem(_ id: Item.ID) {
        bill.items.removeAll { $0.id == id }
    }

    func deletePerson(_ id: Person.ID) {
        bill.people.removeAll { $0.id == id }
        // Drop from EVERY item's sharer set; an item left empty becomes unassigned, never silently charged.
        for i in bill.items.indices { bill.items[i].assigneeIDs.remove(id) }
    }

    func clear() { bill = .empty }   // persistence wiring (cancel save + delete file) lands in Task 3.4
}
```

Rules to honor exactly:

- `bill` is `private(set)`. Never expose a setter or a `func mutate(_:)` escape hatch.
- `totals` is computed, never stored. This is the live-recompute contract from `splitfair-app-architecture`.
- `Item.ID` and `Person.ID` are `UUID` (the `Identifiable` id) — use those typealiases in the signatures so call sites read cleanly.
- `deletePerson` is the subtle one: it must remove the person from **every** item's `assigneeIDs`. Any item left with an empty set is now unassigned (surfaced by the status/hazard-tape treatment in later epics), which is correct — do **not** delete the item.
- `addPerson` sets `colorIndex` to the current roster count so the diner color is stable per roster position.
- Do **not** reach for `ObservableObject`/`@Published`/Combine — use the Observation framework (`@Observable`) only.
- The `clear()` body here is the state half only; Task 3.4 extends it to cancel the pending save and delete the file.

**Done when:**

- `SplitFair/App/BillStore.swift` compiles with `@MainActor @Observable final class BillStore`, `private(set) var bill`, computed `totals`, and all nine intents present.
- `store.totals.grandTotal` reflects the current bill live with no explicit recompute call.
- A quick harness (or later a test) building the $97.20 bill through the intents yields `totals.grandTotal == Money(9720)`.
- `deletePerson` provably removes that id from all `assigneeIDs` (an item shared only by the deleted person ends up unassigned, not removed).

---

### Task 3.2 — Own the store at the App root and inject it

**Skills to load:** `splitfair-app-architecture`, `splitfair-state-store`

**Why this matters:** The store must be created exactly once and live for the whole app session. If it is constructed inside a frequently-rebuilt child view, SwiftUI re-runs the initializer on every rebuild and silently discards the user's bill — the single most damaging state bug in an `@Observable` app. Owning it at the `@main App` with `@State` and injecting it through the environment guarantees one instance, one source of truth, reachable from both screens.

**What to do:**

1. In `SplitFair/App/SplitFairApp.swift`, add `@State private var store = BillStore()` on the `@main App` struct — this is the single, once-constructed owner.
2. Inject it into the view tree with `.environment(store)` on the root `NavigationStack`'s content.
3. Read the `scenePhase` at the App level with `@Environment(\.scenePhase) private var phase` (used fully in Task 3.4; wire the property now so the flush hook has a home).
4. Downstream views read the store with `@Environment(BillStore.self) private var store`.
5. Where a view needs a two-way `TextField` binding (person name entry, tax field), create a **local** `@Bindable var store = store` inside that view's body/init scope — not on the store, not app-wide.
6. Do **not** introduce `NavigationPath` or route enums; one plain `NavigationLink` to Screen 2 is the whole navigation model.

**Technical details & suggestions:**

```swift
@main
struct SplitFairApp: App {
    @State private var store = BillStore()          // constructed ONCE at the root
    @Environment(\.scenePhase) private var phase

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                BillScreen()                        // placeholder for now; real screen arrives in EPIC 06
            }
            .environment(store)
        }
        // scenePhase flush wiring completed in Task 3.4:
        .onChange(of: phase) { _, newPhase in
            if newPhase != .active { Task { await store.flush() } }
        }
    }
}
```

Downstream read + local bindable:

```swift
struct SomeChild: View {
    @Environment(BillStore.self) private var store
    var body: some View {
        @Bindable var store = store               // only because the TextField below needs a binding
        TextField("Tax", text: /* bound edge string */)
        Text(store.totals.grandTotal.description)  // read path needs no @Bindable
    }
}
```

Pitfalls to avoid:

- **The `@State`-reinit pitfall:** never write `@State private var store = BillStore()` inside a child view that rebuilds (e.g. a row, a sheet body). `@State` re-runs its initializer whenever SwiftUI recreates the view value, so a child-owned store loses the bill on the next rebuild. The store is owned **only** at the App root.
- Injecting the value type into `.environment(store)` uses the `@Observable`-object overload (not `.environmentObject`). Reading uses `@Environment(BillStore.self)`, not `@EnvironmentObject`.
- `@Bindable` is per-view-body and local; it does not create a new store, it just vends bindings into the shared one. Do not scatter it where only reads happen.
- Keep `flush()` referenced here even though its body is implemented in Task 3.4 — declare a no-op `func flush() async {}` on the store first if you need this to compile before 3.4, then fill it in.

**Done when:**

- `SplitFairApp` owns `@State private var store = BillStore()` and injects `.environment(store)`; the app builds and launches.
- A downstream view reading `@Environment(BillStore.self) private var store` renders a value from `store.totals` without constructing its own store.
- Backgrounding/foregrounding the app does not reset the in-memory bill (the store instance is stable across rebuilds).
- No `@State` store initializer exists anywhere except the App root; no `NavigationPath`/route enum was added.

---

### Task 3.3 — Implement BillDraftStore (Codable one JSON file)

**Skills to load:** `splitfair-persistence`

**Why this matters:** SplitFair persists exactly one thing — the current bill — as one JSON file. "No data beyond the current bill" is a feature, and the persistence layer is where the app's privacy posture ("Data Not Collected") is physically kept honest. Writing to the wrong location (Documents) would expose the draft to the Files app and iCloud backup; over-hardening file protection would make a save fire at screen-lock *fail* — the exact loss case you most need to survive. This task builds the small, correct, testable store; auto-save timing comes next.

**What to do:**

1. Create `SplitFair/Persistence/BillDraftStore.swift` and `import BillCore` + `import Foundation`.
2. Make the file **URL injectable** via the initializer so tests can point it at a temp directory; default it to `current-bill.json` in Application Support.
3. On init (or first write), ensure the Application Support directory exists with `withIntermediateDirectories: true`.
4. Implement `load() -> Bill`: decode the file; on missing file **or** any decode failure, return `Bill.empty`. No migration machinery — the ephemeral draft never needs it.
5. Implement `save(_ bill: Bill) throws`: encode with `JSONEncoder` and write with `options: [.atomic]`, keeping **default** file protection (do not set `.completeFileProtection`).
6. Implement `clear()`: remove the file, ignoring "file doesn't exist" errors.

**Technical details & suggestions:**

```swift
import Foundation
import BillCore

final class BillDraftStore {
    let url: URL

    init(url: URL = URL.applicationSupportDirectory.appending(path: "current-bill.json")) {
        self.url = url
        // Application Support is NOT auto-created; make it (and any parents) on first use.
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
    }

    func load() -> Bill {
        // Missing file OR decode failure ⇒ .empty. That fallback is why no schema-migration code exists.
        (try? JSONDecoder().decode(Bill.self, from: Data(contentsOf: url))) ?? .empty
    }

    func save(_ bill: Bill) throws {
        let data = try JSONEncoder().encode(bill)
        try data.write(to: url, options: [.atomic])   // default file protection — survives a save at screen-lock
    }

    func clear() {
        try? FileManager.default.removeItem(at: url)   // ignore "no such file"
    }
}
```

Rules to honor exactly:

- **Location: Application Support, not Documents.** Documents is user-visible in the Files app and exposed to iCloud backup; the draft belongs in Application Support.
- **Atomic writes** (`options: [.atomic]`) so a crash mid-write never leaves a half-file.
- **Keep default file protection.** `.completeFileProtection` would make a write that fires exactly at screen-lock throw, losing the bill — the worst case. Default protection is correct here.
- **Load once, fall back to `.empty`.** Do not attempt versioned decode, do not branch on a schema version — the whole point of an ephemeral single-file draft is that a corrupt/old file just becomes a fresh empty bill.
- The `Currency.exponent` is persisted inside `Bill`, so a round-tripped bill reconciles identically even if device locale changed before relaunch — nothing extra to do here, just don't strip currency on encode.
- `JSONEncoder`/`JSONDecoder` need no custom config: `Money`, `Currency`, `Person`, `Item`, `TipMode`, `Bill` are all already `Codable` in `BillCore`.

**Done when:**

- `SplitFair/Persistence/BillDraftStore.swift` compiles with an injectable `url`, and `load`/`save`/`clear` implemented as above.
- Default init targets `Application Support/current-bill.json`; the directory is created if absent.
- `save` then `load` on the same store returns an equal `Bill`; `load` on a missing or garbage file returns `Bill.empty`.
- No `.completeFileProtection`, no Documents-directory path, and no migration/version code is present.

---

### Task 3.4 — Wire debounced auto-save, scenePhase flush and clear()

**Skills to load:** `splitfair-persistence`, `splitfair-state-store`

**Why this matters:** This is where state meets disk. A naive "save on every keystroke" thrashes the filesystem; no debounce plus no flush loses the bill on background/lock. The correct shape is a ~600 ms cancel-and-reschedule debounce that writes **off** the main actor, backed by an immediate flush whenever the scene leaves `.active`. And `clear()` has a sharp edge: assigning `bill = .empty` itself schedules a save, so `clear()` must cancel that pending save before (or after) deleting the file — otherwise a stray debounced write resurrects the just-cleared bill.

**What to do:**

1. Give `BillStore` a reference to a `BillDraftStore` (default-constructed, but injectable so tests can pass a temp-URL store).
2. Add a `didSet` on `bill` (or call a `scheduleSave()` at the end of each intent) that triggers a debounced save whenever the bill changes.
3. Implement `scheduleSave()`: cancel any in-flight save `Task`, then start a new one that `try? await Task.sleep` for ~600 ms and, if not cancelled, snapshots the `Sendable Bill` and writes it **off the main actor**.
4. Implement `flush() async`: cancel the pending debounce and write the current bill immediately (used by the App-root `scenePhase != .active` hook from Task 3.2).
5. Extend `clear()`: set `bill = .empty`, **cancel the pending save Task**, and delete the file via `draftStore.clear()`.
6. On launch, seed the store from disk: `bill = draftStore.load()` (do this in `init` or an explicit `restore()` the App calls once). Guard against the restore assignment itself scheduling a spurious first save.

**Technical details & suggestions:**

```swift
@MainActor @Observable
final class BillStore {
    private(set) var bill: Bill = .empty {
        didSet { scheduleSave() }
    }
    var totals: BillResult { BillMath.compute(bill) }

    private let draftStore: BillDraftStore
    private var saveTask: Task<Void, Never>?
    private let debounce: Duration = .milliseconds(600)

    init(draftStore: BillDraftStore = BillDraftStore()) {
        self.draftStore = draftStore
    }

    /// Call once from the App root on launch. Does not schedule a save.
    func restore() {
        let loaded = draftStore.load()
        saveTask?.cancel()                 // in case anything queued
        bill = loaded                      // NOTE: this fires didSet → scheduleSave; cancel below
        saveTask?.cancel()                 // squash the restore's spurious first save
    }

    private func scheduleSave() {
        saveTask?.cancel()                 // cancel-and-reschedule
        let snapshot = bill                // Bill is Sendable — snapshot, then leave the main actor
        let store = draftStore
        let delay = debounce
        saveTask = Task { [weak self] in
            _ = self
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            await Task.detached(priority: .utility) { try? store.save(snapshot) }.value
        }
    }

    func flush() async {
        saveTask?.cancel()
        let snapshot = bill
        let store = draftStore
        await Task.detached(priority: .utility) { try? store.save(snapshot) }.value
    }

    func clear() {
        saveTask?.cancel()                 // kill any queued save BEFORE we wipe
        bill = .empty                      // this schedules a fresh save…
        saveTask?.cancel()                 // …cancel it too
        draftStore.clear()                 // delete the file
    }
}
```

Rules and pitfalls:

- **Debounce with a cancel-and-reschedule `Task`, not Combine/Timer.** Each intent supersedes the last pending write; only the last edit in a 600 ms window hits disk.
- **Write off the main actor.** Snapshot the `Sendable Bill` on the main actor, then do the encode+write in a detached utility task so JSON encoding never blocks UI. Do not `await` the write inline on `@MainActor` without detaching.
- **`flush()` cancels then writes now.** The App root calls `Task { await store.flush() }` when `scenePhase != .active`. This is the belt-and-suspenders save for background/lock, on top of the debounce.
- **The `clear()` trap:** `bill = .empty` runs `didSet` → `scheduleSave()`, queuing a write of the empty bill. That is harmless for the empty state, but the important discipline is cancelling the pre-existing pending save (which may hold the *old* bill) so it can't land after the file is deleted and recreate `current-bill.json`. Cancel around the assignment as shown, then delete the file last.
- **Restore must not thrash:** `restore()` assigns `bill`, which schedules a save of the just-loaded bill. Cancel that so a fresh launch with no edits does not immediately rewrite the file. Wire `restore()` to be called once from the App root (e.g. a `.task { store.restore() }` or in the App init path) — pick one call site and only one.
- Keep the debounce constant readable (`~600 ms`); it is a feel/loss tradeoff, not a magic number to hide.

**Done when:**

- Editing the bill rapidly results in a single write ~600 ms after the last change (not one per keystroke), and the write happens off the main actor.
- Sending the app to background/locking it (`scenePhase != .active`) flushes the current bill to disk immediately.
- Relaunching restores the last bill; a launch with a prior saved bill shows it without any user action.
- `clear()` empties the in-memory bill, cancels any pending save, and removes `current-bill.json`; no stray debounced write recreates the file afterward.

---

### Task 3.5 — Write persistence tests

**Skills to load:** `splitfair-testing`, `splitfair-persistence`

**Why this matters:** Persistence is the one place a silent bug loses the user's real work. Three cases pin the contract so it can't drift: a bill survives an encode/decode round-trip unchanged, a corrupt file degrades to an empty bill instead of crashing on launch, and `clear()` actually removes the file. Because `BillDraftStore` takes an injected URL, all three run against a temp directory via `swift test` in milliseconds with no simulator — the same fast, pure suite that guards the money math.

**What to do:**

1. Add persistence tests to the `BillCore` test target if `BillDraftStore` lives testably there, or to the app's test target if it must import the app module — prefer testing the store type directly with an injected temp URL. Use the **Swift Testing** framework (`import Testing`, `@Test`/`#expect`/`#require`).
2. For each test, construct a `BillDraftStore(url:)` pointing at a unique file under `FileManager.default.temporaryDirectory` (append a `UUID().uuidString` so tests don't collide); clean it up at the end.
3. **Round-trip test:** build a non-trivial bill (reuse the $97.20 acceptance bill from the testing skill — 3 people, shared nachos, tax + 20% tip), `save` it, make a fresh store on the same URL, `load`, and `#expect` the loaded bill equals the original.
4. **Corrupt → `.empty` test:** write non-JSON bytes (e.g. `"not json"`) to the URL, then `#expect(store.load() == .empty)`.
5. **`clear()` test:** `save` a bill, assert the file exists, call `clear()`, then `#expect` the file no longer exists (and `load()` returns `.empty`).

**Technical details & suggestions:**

```swift
import Testing
import Foundation
@testable import BillCore   // (+ the module where BillDraftStore lives, if separate)

@Suite("BillDraftStore persistence")
struct BillDraftStoreTests {
    private func tempURL() -> URL {
        FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString).json")
    }

    private func acceptanceBill() -> Bill {
        func p(_ n: String) -> Person { Person(id: UUID(), name: n, colorIndex: 0) }
        let ana = p("Ana"), ben = p("Ben"), cy = p("Cy")
        func it(_ c: Int, _ who: [Person]) -> Item {
            Item(id: UUID(), label: "", amount: Money(c), assigneeIDs: Set(who.map(\.id)))
        }
        var bill = Bill.empty
        bill.people = [ana, ben, cy]
        bill.items  = [it(1250,[ana]), it(2800,[ben]), it(900,[ben]), it(1600,[cy]), it(1000,[ana,ben,cy])]
        bill.tax = Money(660); bill.tip = .fixed(Money(1510))
        return bill
    }

    @Test("round-trip: save then load returns an equal Bill")
    func roundTrip() throws {
        let url = tempURL(); defer { try? FileManager.default.removeItem(at: url) }
        let store = BillDraftStore(url: url)
        let original = acceptanceBill()
        try store.save(original)
        let reloaded = BillDraftStore(url: url).load()
        #expect(reloaded == original)
    }

    @Test("corrupt file falls back to .empty (no crash, no migration)")
    func corruptFallsBackToEmpty() throws {
        let url = tempURL(); defer { try? FileManager.default.removeItem(at: url) }
        try Data("not json".utf8).write(to: url)
        #expect(BillDraftStore(url: url).load() == .empty)
    }

    @Test("clear() removes the file and load() returns .empty")
    func clearRemovesFile() throws {
        let url = tempURL(); defer { try? FileManager.default.removeItem(at: url) }
        let store = BillDraftStore(url: url)
        try store.save(acceptanceBill())
        #expect(FileManager.default.fileExists(atPath: url.path))
        store.clear()
        #expect(!FileManager.default.fileExists(atPath: url.path))
        #expect(store.load() == .empty)
    }
}
```

Notes and gotchas:

- `Bill` is `Hashable`/`Equatable` (`splitfair-domain-model`), so `#expect(reloaded == original)` is a clean structural comparison — no field-by-field checks needed.
- Always use an **injected temp URL**; never let a test touch the real Application Support file (it would pollute the running app's draft and make tests order-dependent).
- Use a unique file per test (`UUID`) and `defer` cleanup so tests are isolated and re-runnable.
- Keep these in the fast `swift test` suite. This epic does not add UI smoke tests — those are the payload of `performAccessibilityAudit` in EPIC 08/09.
- If `BillDraftStore` cannot be imported into the pure `BillCore` test target (because it lives in the app module), test it from the app's unit-test target with the same three cases; the injected-URL requirement is what keeps it testable either way.

**Done when:**

- Three tests exist — round-trip, corrupt → `.empty`, and `clear()` removes the file — all using an injected temp URL and cleaning up after themselves.
- `swift test` (or the app unit-test target) runs them green with no simulator and no touching of the real Application Support file.
- The round-trip test uses the $97.20 acceptance bill and asserts full `Bill` equality after reload.
