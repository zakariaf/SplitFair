import Foundation

// MARK: - Domain (all value types; assignments are LINKS, not embedded prices)

/// A diner on the bill. Identity is a stable `id`, never value equality — two people named "Sam"
/// stay distinct.
public struct Person: Identifiable, Hashable, Sendable, Codable {
    public let id: UUID
    public var name: String
    /// Stable index into the diner palette, assigned by roster position (a UI concern the model
    /// carries so a person keeps the same colour for the life of the bill).
    public var colorIndex: Int

    public init(id: UUID = UUID(), name: String, colorIndex: Int) {
        self.id = id
        self.name = name
        self.colorIndex = colorIndex
    }
}

/// A line item. `assigneeIDs` are LINKS to the people sharing it, kept separate from the price and
/// label — so editing a price leaves assignments intact, and deleting a person just drops them from
/// the set. An empty set means the item is unassigned (surfaced by `BillMath.unassignedTotal`),
/// never silently charged.
public struct Item: Identifiable, Hashable, Sendable, Codable {
    public let id: UUID
    public var label: String
    public var amount: Money
    public var assigneeIDs: Set<UUID>

    public init(id: UUID = UUID(), label: String, amount: Money, assigneeIDs: Set<UUID> = []) {
        self.id = id
        self.label = label
        self.amount = amount
        self.assigneeIDs = assigneeIDs
    }
}

/// The tip, modeled so illegal states are unrepresentable: either a percentage (resolved to cents
/// exactly once, at the edge) or a fixed amount.
public enum TipMode: Hashable, Sendable, Codable {
    case percent(Int)
    case fixed(Money)
}

/// The whole bill. One `Bill` is denominated in exactly one `Currency`. Totals are NEVER stored
/// here — they are derived by `BillMath.compute` so they cannot drift.
public struct Bill: Hashable, Sendable, Codable {
    public var currency: Currency
    public var people: [Person]
    public var items: [Item]
    public var tax: Money
    public var tip: TipMode

    public init(
        currency: Currency = .usd,
        people: [Person] = [],
        items: [Item] = [],
        tax: Money = .zero,
        tip: TipMode = .percent(0)
    ) {
        self.currency = currency
        self.people = people
        self.items = items
        self.tax = tax
        self.tip = tip
    }

    public static let empty = Bill()
}

// MARK: - Derived results (computed by BillMath, never stored on Bill)

/// One person's share of the bill, broken into its parts.
public struct Breakdown: Hashable, Sendable {
    public var subtotal: Money
    public var tax: Money
    public var tip: Money
    public var total: Money

    public init(subtotal: Money, tax: Money, tip: Money, total: Money) {
        self.subtotal = subtotal
        self.tax = tax
        self.tip = tip
        self.total = total
    }

    public static let zero = Breakdown(subtotal: .zero, tax: .zero, tip: .zero, total: .zero)
}

/// The fully computed result of a bill: each person's breakdown plus the reconciliation totals.
/// `sum(perPerson.total) == assignedSubtotal + tax + tip == grandTotal`, exactly.
public struct BillResult: Sendable {
    public var perPerson: [UUID: Breakdown]
    public var assignedSubtotal: Money
    public var unassigned: Money
    public var grandTotal: Money

    public init(perPerson: [UUID: Breakdown], assignedSubtotal: Money, unassigned: Money, grandTotal: Money) {
        self.perPerson = perPerson
        self.assignedSubtotal = assignedSubtotal
        self.unassigned = unassigned
        self.grandTotal = grandTotal
    }
}
