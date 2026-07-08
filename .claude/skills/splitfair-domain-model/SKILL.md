---
name: splitfair-domain-model
description: The pure value-type domain model for SplitFair — Money, Currency, Person, Item, TipMode, Bill, and the BillMath compute pipeline, with assignments modeled as person-to-item links. Use when defining or changing the data model, adding a field, or wiring how items, people, tax, and tip flow into per-person totals.
---

# SplitFair — domain model

All value types, Foundation-only, in the `BillCore` package (`splitfair-project-structure`). Assignments are **links** (`assigneeIDs`), separate from item price/label — so editing a price leaves assignments intact and deleting a person just drops them from sharer sets.

```swift
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

/// One Bill == one Currency. Exponent derived from the OS (2 USD, 0 JPY, 3 BHD) and PERSISTED,
/// so the bill reconciles identically even if device locale changes before relaunch.
public struct Currency: Hashable, Sendable, Codable { public var code: String; public var exponent: Int }

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

public enum BillMath {
    public static func subtotals(people: [Person], items: [Item]) -> [UUID: Money]   // shared via allocate([1,…])
    public static func unassignedTotal(people: [Person], items: [Item]) -> Money     // amber-guard total
    public static func resolvedTip(_ bill: Bill) -> Money                            // percent → cents ONCE
    public static func compute(_ bill: Bill) -> BillResult                           // subtotals → allocate(tax) → allocate(tip)
}
```

## Rules

- The compute pipeline order: **subtotals → allocate(tax, weights = subtotals) → allocate(tip, weights = subtotals)**. See `splitfair-money-math`.
- `resolvedTip` converts `.percent` to cents exactly once (rounding site #2) before any allocation.
- Currency is a **bill-level** fact so `Money` arithmetic never guards currency equality.
- Edge policy to pin (and test): when `assignedSubtotal == 0` (everyone comped / 100% off), `allocate`'s equal-weight fallback splits residual tax/tip evenly. Encode this in a test so it can't drift.
- Discounts/comps: a comped item = amount `.zero`; a whole-bill discount = a negative `Money` prorated with the same `allocate()`.
- Edge parsing/formatting (`MoneyEdge`) is the ONLY place `Decimal`/`FormatStyle` appear (`splitfair-swift-conventions`, `splitfair-ios-platform`).
