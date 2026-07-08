---
name: splitfair-testing
description: The testing strategy for SplitFair using the Swift Testing framework — unit tests for the allocate()/reconciliation invariants and the $97.20 acceptance bill, plus lint/format tooling. Use when writing or reviewing tests, adding a feature that touches money math, or setting up code-quality checks.
---

# SplitFair — testing

Use the modern **Swift Testing** framework (`import Testing`, `@Test`/`#expect`/`#require`, parameterized `@Test(arguments:)`). Test the pure `BillCore` package — `swift test` runs the whole suite in milliseconds, no simulator. Reserve XCTest/XCUITest for 1-2 happy-path UI smokes whose real payload is `app.performAccessibilityAudit(...)`. **Skip pixel-snapshot tests** (poor ROI for 2 screens, brittle).

## Write the math tests before any UI

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

## Must-cover cases

Conservation (fuzzed), residual < n, ascending-index tie-break, zero-weight fallback, negative mirror, the pathological set (1¢/3-ways, single odd-cent item, everyone comped, 100% discount, large party), the percent→cents single-rounding site, and the $97.20 acceptance bill. Also unit-test persistence: round-trip, corrupt-file → `.empty`, and `clear()` (`splitfair-persistence`).

## Tooling

SwiftFormat + SwiftLint via a pre-commit hook; `swiftlint --strict` in CI. Assert `sum(result) == amount` inside `allocate` as a runtime tripwire (compiles out in release).
