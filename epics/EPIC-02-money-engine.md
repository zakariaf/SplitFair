# EPIC 02 — The Money Engine (BillCore)

> Build and 100%-test the pure, correctness-critical domain: integer cents, one allocate() primitive, and a compute pipeline that reconciles to the exact cent.

## What this epic is for
SplitFair's entire reason to exist is that per-person totals sum to the printed grand total to the exact cent, for any bill, every time. This epic implements that promise as a pure, Foundation-only domain inside the linked `BillCore` package — `Money`/`Currency`, the single largest-remainder `allocate()` primitive, the `Person`/`Item`/`TipMode`/`Bill` model, the `BillMath.compute` pipeline, edge parsing/formatting (`MoneyEdge`), and a plain-text `Summary` — and proves it with a Swift Testing suite before a single pixel of UI exists. The math is the product; everything downstream is decoration on top of a domain that is already green.

## Where we are before starting (starting state)
- EPIC 01 is done: an iOS 17 SwiftUI app builds and launches to a placeholder screen.
- A local `BillCore` Swift package (swift-tools 6.0, Foundation-only, one library target + one Swift Testing target) is linked to the app but contains **no domain code**.
- `swift test` runs the (empty) BillCore test target in milliseconds with no simulator.
- SwiftFormat + SwiftLint + a pre-commit hook are wired; `swiftlint --strict` is the CI gate.
- The folder layout from `splitfair-project-structure` exists: `Packages/BillCore/Sources/BillCore/`, `Packages/BillCore/Tests/BillCoreTests/`, and the app's `App/Features/DesignSystem/Persistence/Sharing` folders.

## What we will have after finishing (definition of done)
- `Money` (Int minor units; `AdditiveArithmetic`/`Comparable`/`Codable`/`Sendable`/`Hashable`) and `typealias Cents = Int` in `Money.swift`.
- `Currency` (`code` + `exponent`, derived from the OS and **persisted**) in `Currency.swift`.
- `allocate(amountCents:weights:)` — the exact integer Hamilton largest-remainder primitive with the debug conservation assert, ascending-index tie-break, equal-weight fallback, negative mirror, and empty-safe behavior — in `Allocate.swift`.
- The domain model — `Person`, `Item` (assignments as `assigneeIDs` links), `TipMode`, `Bill`, `Bill.empty`, and the derived `Breakdown`/`BillResult` (never stored on `Bill`) — in `Model.swift`.
- `BillMath.compute(_:)` plus `subtotals`, `unassignedTotal`, and `resolvedTip` in `BillMath.swift`.
- `MoneyEdge` (locale-aware `parse` → `Cents` with a strict trailing-garbage guard, and `format` `Cents` → `String`) in `MoneyEdge.swift`, and a pure `Summary` builder in `Summary.swift`.
- A Swift Testing suite covering: fuzzed conservation, residual < n, ascending-index tie-break, zero-weight fallback, negative mirror, the pathological set, the percent→cents single-rounding site, the `subtotal == 0` equal-split policy, a golden summary test, and the **$97.20 acceptance bill** (Ana 2039 / Ben 5193 / Cy 2488 / grand 9720, sum-of-finals == grandTotal).
- `swift test` is **green** with no simulator; `BillCore` imports only Foundation.

## Dependencies
- Depends on: EPIC 01 — Project Foundation & Tooling (the linked, empty BillCore package + Swift Testing target).
- Enables: EPIC 03 — App State & Local Persistence (a `BillStore` will wrap this domain and persist `Bill`).

---

## Tasks

### Task 2.1 — Implement Money and Currency value types
**Skills to load:** `splitfair-domain-model`, `splitfair-swift-conventions`

**Why this matters:** Every amount in the app flows through these two types. If money is ever a `Double`/`Float`, `0.01` cannot be represented exactly and "sum of parts == whole" becomes a hope instead of a structural fact — the one bug this entire product is built to avoid. `Currency.exponent` must be captured once and persisted so a bill that was entered in USD (exponent 2), JPY (0), or BHD (3) still reconciles identically even if the device locale changes before relaunch.

**What to do:**
1. Create `Packages/BillCore/Sources/BillCore/Money.swift`. Declare `public typealias Cents = Int` and a thin `Money` newtype over a single signed `Int` (`minorUnits`). Conform to `Hashable, Sendable, Codable, Comparable, AdditiveArithmetic`.
2. Add `public static let zero = Money(0)` and implement `+`, `-`, and `<` operating directly on `minorUnits`. Negative `minorUnits` is legal and means a discount/credit.
3. Create `Packages/BillCore/Sources/BillCore/Currency.swift`. Declare `Currency` with `code: String` and `exponent: Int`, conforming to `Hashable, Sendable, Codable`. Do **not** store a locale or a symbol here — currency is a **bill-level** fact so `Money` arithmetic never has to guard currency equality.
4. Keep both files Foundation-only. No SwiftUI/UIKit import may appear anywhere in `BillCore` — the missing import is the compile firewall.

**Technical details & suggestions:**
```swift
// Money.swift
public typealias Cents = Int

/// Thin newtype over signed Int minor units. Negative == discount/credit. No float, ever.
public struct Money: Hashable, Sendable, Codable, Comparable, AdditiveArithmetic {
    public var minorUnits: Int
    public init(_ minorUnits: Int) { self.minorUnits = minorUnits }
    public static let zero = Money(0)
    public static func + (l: Money, r: Money) -> Money { Money(l.minorUnits + r.minorUnits) }
    public static func - (l: Money, r: Money) -> Money { Money(l.minorUnits - r.minorUnits) }
    public static func < (l: Money, r: Money) -> Bool { l.minorUnits < r.minorUnits }
}

// Currency.swift
/// One Bill == one Currency. Exponent derived from the OS (2 USD, 0 JPY, 3 BHD) and PERSISTED,
/// so the bill reconciles identically even if device locale changes before relaunch.
public struct Currency: Hashable, Sendable, Codable { public var code: String; public var exponent: Int }
```
- `AdditiveArithmetic` gives you `Money.zero` semantics and lets `reduce(Money.zero, +)` work in the reconciliation invariant test.
- Do not add a computed `Double` "dollars" accessor — that is exactly the escape hatch that reintroduces float error. Human-readable strings come only from `MoneyEdge.format` (Task 2.7).
- Deriving `exponent` from the OS at bill-creation time (e.g. via `Locale`/currency identifier) belongs to the app/edge layer; here `Currency` is just the persisted record of that decision. Keep this file inert data.

**Done when:** `Money.swift` and `Currency.swift` compile in the Foundation-only package; `Money.zero + Money(5) == Money(5)`, `Money(3) < Money(4)`, and a round-trip `JSONEncoder`/`JSONDecoder` of both types is identity-preserving. No `Double`/`Float` and no UI import appears in either file.

---

### Task 2.2 — Implement the allocate() largest-remainder primitive
**Skills to load:** `splitfair-money-math`

**Why this matters:** This is the single rounding path for the entire app — shared items, tax proration, and tip proration all route through it. One rounding site means one thing to test and one place a residual cent can land. Getting it exactly right (parts always sum to the input, deterministic tie-break, no crash on pathological input) is the whole ballgame; a bug here silently mischarges real people money.

**What to do:**
1. Create `Packages/BillCore/Sources/BillCore/Allocate.swift`.
2. Implement `public func allocate(amountCents: Cents, weights: [Int]) -> [Cents]` as an **integer** largest-remainder (Hamilton) allocation. No `Double`/`Float` anywhere in the body.
3. Handle the edges in this exact order: empty weights → `[]` (never trap — money math must not crash the UI); negative amount → recurse on the positive and negate each part (`.map(-)`) so discounts/comps mirror exactly; sanitize weights with `max($0, 0)`; if the sanitized weight-sum is 0 → equal-weight fallback (`[1]*n`, divisor `n`).
4. Compute each floor share as `amountCents * w[i] / W` — **product first, then integer div/mod** so no float sneaks in. Track `product % W` as the remainder.
5. Distribute the leftover (always in `0 ..< n`) by descending remainder, breaking ties by **ascending index**, adding 1 cent each until the leftover is exhausted.
6. Add the debug tripwire `assert(shares.reduce(0, +) == amountCents, "allocate must be exact")` — it compiles out in release but catches any future regression in test/debug.

**Technical details & suggestions:**
```swift
public typealias Cents = Int // (already in Money.swift; do not redeclare — reference it)

/// Splits `amountCents` across `weights`, guaranteeing the parts sum EXACTLY to `amountCents`.
/// Conservation asserted in debug; residual < n; deterministic ascending-index tie-break;
/// negative amount mirrors + negates (discounts/comps); zero weight-sum → equal-weight fallback;
/// empty weights → [] (never traps — money math must not crash the UI).
public func allocate(amountCents: Cents, weights: [Int]) -> [Cents] {
    let n = weights.count
    guard n > 0 else { return [] }
    if amountCents < 0 { return allocate(amountCents: -amountCents, weights: weights).map(-) }

    let sanitized = weights.map { max($0, 0) }
    let weightSum = sanitized.reduce(0, +)
    let w = weightSum == 0 ? [Int](repeating: 1, count: n) : sanitized
    let W = weightSum == 0 ? n : weightSum

    var shares = [Cents](repeating: 0, count: n)
    var remainders = [(remainder: Int, index: Int)](); remainders.reserveCapacity(n)
    var distributed = 0
    for i in 0..<n {
        let product = amountCents * w[i]        // product FIRST, then div/mod — no float
        let floorShare = product / W
        shares[i] = floorShare; distributed += floorShare
        remainders.append((product % W, i))
    }
    var leftover = amountCents - distributed    // always in 0 ..< n
    remainders.sort { $0.remainder != $1.remainder ? $0.remainder > $1.remainder : $0.index < $1.index }
    var k = 0
    while leftover > 0 { shares[remainders[k].index] += 1; leftover -= 1; k += 1 }
    assert(shares.reduce(0, +) == amountCents, "allocate must be exact")
    return shares
}
```
- Verified vectors to keep in your head (these become tests in 2.3): `allocate(1001,[1,1,1]) == [334,334,333]`, `allocate(660,[1584,4033,1933]) == [138,353,169]`, `allocate(1510,[1584,4033,1933]) == [317,807,386]`.
- **Do not** sum independently-rounded parts to synthesize a total — always allocate a known integer total and let the parts absorb the residual. This function is the enforcement of that rule.
- `SplitRing` visuals and everything else derive from this; keep it a free `public func` (not a method) so tests call `allocate(...)` directly.
- Pitfall: writing `Double(amountCents) * fraction` "for readability" — banned. Keep the integer product/div/mod exactly as above.

**Done when:** The file compiles Foundation-only; the three verified vectors return exactly the expected arrays; `allocate(amountCents:10, weights:[])` returns `[]`; and the debug assert never fires for any of them. (Formal proof of the invariants is Task 2.3.)

---

### Task 2.3 — Write the allocate invariant test suite first
**Skills to load:** `splitfair-testing`, `splitfair-money-math`

**Why this matters:** The math must be proven before any UI can lean on it. Writing these tests now — and getting them green before touching the model or the pipeline — means the one rounding path is nailed down while it is small and isolated. A fuzzed conservation test catches whole classes of off-by-a-cent regressions that hand-picked examples miss.

**What to do:**
1. Create `Packages/BillCore/Tests/BillCoreTests/AllocateTests.swift` using Swift Testing (`import Testing`, `@testable import BillCore`).
2. Add a **fuzzed conservation** test using a parameterized `@Test(arguments: 0..<500)`: for each seed generate a random `n` (1...20), a random `amount` (0...100_000), and random `weights` (0...500), and `#expect` that `allocate(...).reduce(0, +) == amount`.
3. Add a **residual < n** check: for the same random draws, assert that at most `n` parts were bumped (equivalently `amount - sum(floorShares) < n`), confirming the leftover loop never over-distributes.
4. Add an **edges** test with the exact hand-verified vectors: ascending-index tie-break (`1001/[1,1,1] == [334,334,333]`), `1¢` three ways (`1/[1,1,1] == [1,0,0]`), everyone comped / zero-weight fallback (`100/[0,0,0] == [34,33,33]`), and empty roster (`10/[] == []`).
5. Add a **negative mirror** test: `allocate(-1000, w) == allocate(1000, w).map(-)` for `w = [1584,4033,1933]`.
6. Add the **pathological set**: single odd-cent item, a 100% discount (whole negative amount), and a large party (e.g. `n` in the hundreds) — each still conserving.
7. Run `swift test` and get this suite fully green before starting Task 2.4.

**Technical details & suggestions:**
```swift
import Testing
@testable import BillCore

@Suite("allocate — largest remainder")
struct AllocateTests {
    @Test(arguments: 0..<500)                                     // fuzz: parts always sum to input
    func conservation(seed: Int) {
        var rng = SystemRandomNumberGenerator(); _ = seed
        let n = Int.random(in: 1...20, using: &rng)
        let amount = Int.random(in: 0...100_000, using: &rng)
        let weights = (0..<n).map { _ in Int.random(in: 0...500, using: &rng) }
        #expect(allocate(amountCents: amount, weights: weights).reduce(0, +) == amount)
    }
    @Test("tie-break + edges")
    func edges() {
        #expect(allocate(amountCents: 1001, weights: [1,1,1]) == [334,334,333]) // ascending-index tie-break
        #expect(allocate(amountCents: 1,    weights: [1,1,1]) == [1,0,0])       // 1¢ / 3 ways
        #expect(allocate(amountCents: 100,  weights: [0,0,0]) == [34,33,33])    // everyone comped → equal split
        #expect(allocate(amountCents: 10,   weights: [])      == [])            // empty roster, no trap
    }
    @Test("negative mirrors + negates (discounts)")
    func negative() {
        let w = [1584,4033,1933]
        #expect(allocate(amountCents: -1000, weights: w) == allocate(amountCents: 1000, weights: w).map(-))
    }
}
```
- The must-cover list from `splitfair-testing`: conservation (fuzzed), residual < n, ascending-index tie-break, zero-weight fallback, negative mirror, and the pathological set (1¢/3-ways, single odd-cent item, everyone comped, 100% discount, large party).
- Prefer parameterized `@Test(arguments:)` for the fuzz loop so each seed is an independently reported case.
- Keep the tests calling the free `allocate(...)` function directly — they are unit tests of the primitive, not of the pipeline.

**Done when:** `swift test` runs the `AllocateTests` suite green with no simulator; the fuzzed conservation case passes for all 500 iterations; every edge, negative-mirror, and pathological assertion passes; and the residual-<n property holds.

---

### Task 2.4 — Define the domain model
**Skills to load:** `splitfair-domain-model`

**Why this matters:** The model shape decides which bugs are even possible. Modeling assignments as **links** (`assigneeIDs`) rather than embedding people inside items means editing a price leaves assignments intact and deleting a person simply drops them from sharer sets — no cascading corruption. Identity via a stored `UUID` (never structural equality) prevents two diners both named "Sam" from collapsing into one. And keeping totals **derived, never stored on `Bill`**, kills the classic denormalized-total drift bug at the type level.

**What to do:**
1. Create `Packages/BillCore/Sources/BillCore/Model.swift`.
2. Define `Person` (`Identifiable, Hashable, Sendable, Codable`) with a stable `let id: UUID`, `var name: String`, and `var colorIndex: Int` (stable diner color by roster index).
3. Define `Item` (`Identifiable, Hashable, Sendable, Codable`) with `let id: UUID`, `var label: String`, `var amount: Money`, and `var assigneeIDs: Set<UUID>`. An empty or off-roster assignee set means the item is **surfaced as unassigned, never charged silently**.
4. Define `TipMode` as an enum with `case percent(Int)` and `case fixed(Money)`, conforming to `Hashable, Sendable, Codable`. Use exhaustive switches with **no `default`** downstream so a future case is a compile error until handled.
5. Define `Bill` (`Hashable, Sendable, Codable`) with `currency: Currency`, `people: [Person] = []`, `items: [Item] = []`, `tax: Money = .zero`, `tip: TipMode = .percent(0)`, and `static let empty = Bill(currency: Currency(code: "USD", exponent: 2))`.
6. Define the **derived** types — never stored on `Bill`: `Breakdown` (`subtotal, tax, tip, total: Money`) and `BillResult` (`perPerson: [UUID: Breakdown]`, `assignedSubtotal, unassigned, grandTotal: Money`).

**Technical details & suggestions:**
```swift
public struct Person: Identifiable, Hashable, Sendable, Codable {
    public let id: UUID            // stable identity
    public var name: String
    public var colorIndex: Int     // stable diner color by roster index (see splitfair-color-system)
}

public struct Item: Identifiable, Hashable, Sendable, Codable {
    public let id: UUID
    public var label: String
    public var amount: Money
    public var assigneeIDs: Set<UUID>   // empty/off-roster ⇒ surfaced as unassigned, never charged silently
}

public enum TipMode: Hashable, Sendable, Codable { case percent(Int); case fixed(Money) }

public struct Bill: Hashable, Sendable, Codable {
    public var currency: Currency
    public var people: [Person] = []
    public var items: [Item] = []
    public var tax: Money = .zero
    public var tip: TipMode = .percent(0)
    public static let empty = Bill(currency: Currency(code: "USD", exponent: 2))
}

// Derived — NEVER stored on Bill (a stored total is the classic drift bug):
public struct Breakdown: Hashable, Sendable { public var subtotal, tax, tip, total: Money }
public struct BillResult: Sendable {
    public var perPerson: [UUID: Breakdown]
    public var assignedSubtotal, unassigned, grandTotal: Money
}
```
- Provide `public init`s for `Person`, `Item`, `Bill`, `Breakdown`, and `BillResult` (public structs across a package boundary need explicit public initializers). Match the field order above.
- Domain models are `struct`/`enum`, never `class` — value types are trivially `Sendable` and thread-safe.
- Keep `Breakdown`/`BillResult` out of `Bill` entirely; they are outputs of `BillMath.compute`, not fields.
- `colorIndex` is data only here; the actual palette lives in the DesignSystem in a later epic.

**Done when:** `Model.swift` compiles Foundation-only; `Bill.empty` constructs; a `Bill` with people/items/tax/tip round-trips through `JSONEncoder`/`JSONDecoder` identically; and `TipMode` encodes/decodes both cases. No `Breakdown`/`BillResult` field exists on `Bill`.

---

### Task 2.5 — Implement the BillMath.compute pipeline
**Skills to load:** `splitfair-money-math`, `splitfair-domain-model`

**Why this matters:** This is where the three passes come together and the grand-total reconciliation becomes **structural**. Because every whole-bill figure (each shared item, the tax, the tip) is distributed by `allocate()`, the per-person finals must sum to the grand total to the exact cent for any input — no epsilon, no "close enough." Getting the pipeline order or the weights wrong reintroduces the drift this whole engine exists to prevent.

**What to do:**
1. Create `Packages/BillCore/Sources/BillCore/BillMath.swift` with `public enum BillMath` holding static functions.
2. Implement `subtotals(people:items:) -> [UUID: Money]`: for each item, personal items (single assignee) go entirely to that owner; each **shared** item is split via `allocate(itemCents, [1]*k)` across its `k` assignees in **roster order** (iterate `people` and keep only those in `assigneeIDs`, so the tie-break is deterministic and stable). Person subtotal `S[i]` = personal + shared shares. Ignore items whose assignee set is empty or off-roster (those are unassigned, handled separately).
3. Implement `unassignedTotal(people:items:) -> Money`: the sum of item amounts that have no on-roster assignee — the amber-guard total that later blocks Next.
4. Implement `resolvedTip(_ bill: Bill) -> Money`: convert `.percent(pct)` to cents **exactly once** (rounding site #2) against the assigned subtotal, and pass `.fixed` straight through. Round the percent to `Int` once before any allocation.
5. Implement `compute(_ bill: Bill) -> BillResult`: build `subtotals` → order the assignees by roster → `tax = allocate(taxCents, weights: S)` → `tip = allocate(tipCents, weights: S)` where `tipCents = resolvedTip(bill)`; assemble `Breakdown` per person with `total = S[i] + tax[i] + tip[i]`; set `assignedSubtotal = Σ S`, `unassigned = unassignedTotal(...)`, and `grandTotal = assignedSubtotal + taxCents + tipCents`.
6. Keep `compute` **pure and total** — no throwing. Clamp/validate at entry; never crash the UI from the math layer.

**Technical details & suggestions:**
```swift
public enum BillMath {
    public static func subtotals(people: [Person], items: [Item]) -> [UUID: Money]   // shared via allocate([1,…])
    public static func unassignedTotal(people: [Person], items: [Item]) -> Money     // amber-guard total
    public static func resolvedTip(_ bill: Bill) -> Money                            // percent → cents ONCE
    public static func compute(_ bill: Bill) -> BillResult                           // subtotals → allocate(tax) → allocate(tip)
}
```
- **Pipeline order is fixed:** subtotals → `allocate(tax, weights = subtotals)` → `allocate(tip, weights = subtotals)`. Weight both tax and tip by the pre-tax subtotals `S` (default tip base = pre-tax subtotal; the post-tax toggle is a later-epic concern but keep `resolvedTip`/weights factored so it can change base without touching `allocate`).
- **Two rounding sites, not one.** `allocate()` is one; percent→cents is the other. Do it once: `let tipCents = Int((Double(assignedSubtotalCents) * pct/100).rounded())` — but note the money rule bans `Double` in arithmetic that lands on a stored amount. Prefer integer math: `tipCents = (assignedSubtotalCents * pct + 50) / 100` for a half-up round, computed **once**, then fed to `allocate`. Pick one rounding expression and pin it with the test in Task 2.6.
- Build the weights array `S` in the **same roster order** you use to index the `allocate` results back to people, so `tax[i]`/`tip[i]` align to the right person. Reuse a single ordered `[UUID]` of assignees for both the weights and the result mapping.
- `grandTotal` must be assembled as `assignedSubtotal + taxCents + tipCents` (known integers), **not** by summing per-person finals — the invariant test then confirms the two independently agree.
- Edge policy to pin (tested in 2.6): when `assignedSubtotal == 0`, the weights are all zero, so `allocate`'s equal-weight fallback splits residual tax/tip evenly across the roster.
- Never store any of these results back on `Bill`. `compute` takes a `Bill` and returns a fresh `BillResult`.

**Done when:** `BillMath.swift` compiles Foundation-only; `compute` is non-throwing and total; for a simple two-person, one-shared-item bill the per-person `total`s sum exactly to `grandTotal`; `unassignedTotal` correctly excludes assigned items; and `resolvedTip` converts a `.percent` to a single integer cents value. (The canonical proof is Task 2.6.)

---

### Task 2.6 — Write the $97.20 acceptance and edge-policy tests
**Skills to load:** `splitfair-testing`

**Why this matters:** The $97.20 bill is the canonical anchor for the whole product — a hand-worked 3-person bill with a shared item, real tax, and a 20% tip whose answer (Ana 2039 / Ben 5193 / Cy 2488, grand 9720) is known to the cent. If this test is green and the reconciliation invariant holds, the engine is trustworthy. Pinning the percent→cents single-rounding site and the `subtotal == 0` equal-split policy stops those two subtle behaviors from silently drifting later.

**What to do:**
1. Create `Packages/BillCore/Tests/BillCoreTests/BillMathTests.swift` (Swift Testing).
2. Add the `$97.20` acceptance test: three people (Ana, Ben, Cy); items `1250→Ana`, `2800→Ben`, `900→Ben`, `1600→Cy`, and shared `1000→{Ana,Ben,Cy}`; `tax = Money(660)`; `tip = .fixed(Money(1510))`. `#expect` `perPerson[ana].total == Money(2039)`, `[ben] == Money(5193)`, `[cy] == Money(2488)`, `grandTotal == Money(9720)`, and the invariant `perPerson.values.reduce(Money.zero) { $0 + $1.total } == grandTotal`.
3. Add the **percent→cents single-rounding** test: build a bill where a naive per-part percent would round differently than a single up-front percent→cents, and assert `resolvedTip` (and the resulting reconciliation) matches the single-rounding answer. Confirm the 20% path also yields `1510` for this bill so `.percent(20)` and `.fixed(1510)` agree.
4. Add the **`subtotal == 0` equal-split policy** test: a bill where every assigned item is comped (`amount == .zero`) but `tax`/`tip` are non-zero; assert `allocate`'s equal-weight fallback splits the residual tax/tip **evenly** across the roster and that finals still sum to `grandTotal`.
5. Run `swift test`; the full BillCore suite (allocate + billmath) must be green.

**Technical details & suggestions:**
```swift
@Suite("Reconciliation acceptance gate")
struct ReconciliationTests {
    @Test("3 people, shared nachos, tax + 20% tip → $97.20 to the exact cent")
    func worked() {
        func p(_ n: String) -> Person { Person(id: UUID(), name: n, colorIndex: 0) }
        let ana = p("Ana"), ben = p("Ben"), cy = p("Cy")
        func it(_ c: Int, _ who: [Person]) -> Item { Item(id: UUID(), label: "", amount: Money(c), assigneeIDs: Set(who.map(\.id))) }
        var bill = Bill.empty
        bill.people = [ana, ben, cy]
        bill.items  = [it(1250,[ana]), it(2800,[ben]), it(900,[ben]), it(1600,[cy]), it(1000,[ana,ben,cy])]
        bill.tax = Money(660); bill.tip = .fixed(Money(1510))
        let r = BillMath.compute(bill)
        #expect(r.perPerson[ana.id]?.total == Money(2039))   // $20.39
        #expect(r.perPerson[ben.id]?.total == Money(5193))   // $51.93
        #expect(r.perPerson[cy.id]?.total  == Money(2488))   // $24.88
        #expect(r.grandTotal == Money(9720))                 // $97.20
        #expect(r.perPerson.values.reduce(Money.zero) { $0 + $1.total } == r.grandTotal) // THE invariant
    }
}
```
- The worked anchor from `splitfair-money-math`: items 1250 + 2800 + 900 + 1600 + shared nachos 1000 (3 ways) ; tax 660 ; tip 20% = 1510 → Ana 2039 / Ben 5193 / Cy 2488, grand **9720**. Cross-check intermediate `allocate` vectors: subtotals feed `allocate(660, S) == [138,353,169]` and `allocate(1510, S) == [317,807,386]` for `S == [1584,4033,1933]`.
- For the single-rounding test, the risk being pinned: rounding each person's tip independently vs. rounding the whole tip once then allocating. Assert the whole-bill approach.
- For the comped-bill test, everyone's subtotal is 0 → all weights 0 → equal-weight fallback. Encode the exact expected even split so it can't drift.

**Done when:** `swift test` is green; the $97.20 test passes all five expectations including the reconciliation invariant; the percent→cents test locks the single-rounding behavior; and the `subtotal == 0` equal-split policy test passes.

---

### Task 2.7 — Implement MoneyEdge (parse/format) and the Summary builder
**Skills to load:** `splitfair-ios-platform`, `splitfair-swift-conventions`, `splitfair-testing`

**Why this matters:** `MoneyEdge` is the **only** place `Decimal`/`FormatStyle` are allowed — the strict boundary between the human-readable edge and the integer core. Parsing must be locale-aware but must never let trailing garbage through: `Decimal.FormatStyle.parseStrategy` silently accepts `"12.50xyz"` as `1250`, so a strict re-format-and-compare guard is required. The `Summary` builder must be pure (no UIKit, no `UIPasteboard`) so it lives in `BillCore` and can be golden-tested; the platform ShareLink/clipboard wiring is a later epic and consumes this text.

**What to do:**
1. Create `Packages/BillCore/Sources/BillCore/MoneyEdge.swift` as an `enum MoneyEdge` (namespace) with static `parse` and `format`.
2. Implement `format(_ cents: Cents, currency: Currency) -> String`: build a value as `Decimal(cents) / pow(10, exponent)` (or `Decimal(cents) / 100` for the common exponent-2 case) and render with `.currency(code:)`. Never hardcode `$` or 2 decimals — derive from `currency` so JPY (0) and BHD (3) format correctly. Initialize `Decimal` from an `Int` or `String`, **never** from a `Double` (`Decimal(someDouble)` carries binary error).
3. Implement `parse(_ input: String, currency: Currency) -> Cents?`: parse locale-aware to a `Decimal`, scale by `10^exponent`, and round to an `Int`. Add the **strict trailing-garbage guard** — re-format the parsed cents back to a canonical string and compare (or otherwise reject any input whose parsed value does not fully consume the string), returning `nil` on mismatch so `"12.50xyz"` is rejected rather than silently accepted.
4. Create `Packages/BillCore/Sources/BillCore/Summary.swift` with a **pure** `Summary` builder: `build(_ bill: Bill, result: BillResult) -> String` producing a plain-text, per-person breakdown (name, subtotal, tax, tip, total) plus the grand total, formatting every amount through `MoneyEdge.format` with the bill's currency. No UIKit, no clipboard, no SwiftUI — just a `String`.
5. Create `Packages/BillCore/Tests/BillCoreTests/SummaryTests.swift`: golden-test the summary for the $97.20 bill (compare the whole produced string against an expected fixed string), and add `MoneyEdge` tests for round-trip parse↔format and the trailing-garbage rejection.

**Technical details & suggestions:**
- Formatting reference (this exact FormatStyle is the edge; in the app it renders via `Text(...).monospacedDigit()`, but the pure string form lives here):
```swift
// value derived from integer cents + currency.exponent — never from a Double
Decimal(cents) / 100  // for exponent 2; generalize with pow(10, currency.exponent)
    .formatted(.currency(code: currency.code))
```
- The trailing-garbage guard is the key pitfall from `splitfair-ios-platform`: `Decimal.FormatStyle.parseStrategy` ignores trailing garbage (`"12.50xyz"` → `1250`). The `.decimalPad` keyboard mostly prevents bad input at the UI, but the parser itself must still reject it — do a strict re-format-and-compare (or a full-consumption check) and return `nil` on any leftover.
- Keep `MoneyEdge` and `Summary` in `BillCore` so `swift test` covers them with no simulator. The app-side `ShareLink(item:)` + optional `UIPasteboard.general.string` + "Copied" toast are EPIC 07 concerns and simply consume `Summary.build(...)`.
- Prefer a stable, deterministic summary layout (fixed line order by roster) so the golden test is not flaky. Because currency formatting is locale-sensitive, pin the test's locale/currency (USD, exponent 2) and, if needed, assert on the integer-derived structure rather than a locale-variant glyph — but keep at least one golden assertion on the full string for the pinned locale.
- Money rule reminder: `Decimal`/`FormatStyle` appear **only** in `MoneyEdge` (and transitively in `Summary` via `MoneyEdge.format`). They must never touch `allocate`, `BillMath`, or `Model`.

**Done when:** `MoneyEdge.format` renders integer cents correctly for exponent-2 currency; `MoneyEdge.parse` returns the right `Cents` for valid locale input and returns `nil` for `"12.50xyz"`; parse↔format round-trips; `Summary.build` produces a stable plain-text breakdown that matches the golden string for the $97.20 bill; and the full `swift test` suite (AllocateTests, BillMathTests, SummaryTests, MoneyEdge tests) is green with no simulator. `Decimal`/`FormatStyle` appear nowhere outside `MoneyEdge.swift`/`Summary.swift`.
