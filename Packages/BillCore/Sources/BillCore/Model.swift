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
///
/// A bill is one entry in the local library (EPIC 10): it carries a stable `id`, a user `title`
/// (empty ⇒ the UI shows an auto-title), a `createdAt` for ordering, and `payerID` — who fronted the
/// money — which feeds the running balances but never the per-person split of this one bill.
public struct Bill: Identifiable, Hashable, Sendable, Codable {
    public let id: UUID
    public var title: String
    public var createdAt: Date
    public var currency: Currency
    public var people: [Person]
    public var items: [Item]
    public var tax: Money
    public var tip: TipMode
    /// Who paid the bill. `nil` ⇒ not recorded; such bills are excluded from balances (see `Balances`).
    public var payerID: Person.ID?

    public init(
        id: UUID = UUID(),
        title: String = "",
        createdAt: Date = Date(),
        currency: Currency = .usd,
        people: [Person] = [],
        items: [Item] = [],
        tax: Money = .zero,
        tip: TipMode = .percent(0),
        payerID: Person.ID? = nil
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.currency = currency
        self.people = people
        self.items = items
        self.tax = tax
        self.tip = tip
        self.payerID = payerID
    }

    public static let empty = Bill()

    private enum CodingKeys: String, CodingKey {
        case id, title, createdAt, currency, people, items, tax, tip, payerID
    }

    /// Lenient decoding: a pre-EPIC-10 bill JSON (no `id`/`title`/`createdAt`/`payerID`) still loads
    /// with sensible defaults, so the legacy single-bill draft migrates cleanly (Task 10.4). This is
    /// tolerant decoding, not versioned migration — there are no schema-version branches. `encode` is
    /// synthesized from the same `CodingKeys`.
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try c.decodeIfPresent(String.self, forKey: .title) ?? ""
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        currency = try c.decode(Currency.self, forKey: .currency)
        people = try c.decodeIfPresent([Person].self, forKey: .people) ?? []
        items = try c.decodeIfPresent([Item].self, forKey: .items) ?? []
        tax = try c.decodeIfPresent(Money.self, forKey: .tax) ?? .zero
        tip = try c.decodeIfPresent(TipMode.self, forKey: .tip) ?? .percent(0)
        payerID = try c.decodeIfPresent(UUID.self, forKey: .payerID)
    }
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
