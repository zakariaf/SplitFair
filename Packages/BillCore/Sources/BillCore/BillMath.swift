import Foundation

/// The pure compute pipeline. Because per-person subtotals, tax, and tip are EACH produced by
/// `allocate()` (which provably sums to its exact input), the per-person totals sum to the grand
/// total to the exact minor unit, for any bill — reconciliation is structural, not hoped-for.
public enum BillMath {
    /// Each person's item subtotal. A personal item's cents go to its owner; a shared item is split
    /// among its on-roster assignees, taken in stable roster order, via `allocate([1]*k)`.
    public static func subtotals(people: [Person], items: [Item]) -> [UUID: Money] {
        let roster = people.map(\.id)
        var result = Dictionary(roster.map { ($0, Money.zero) }, uniquingKeysWith: { first, _ in first })
        for item in items {
            let assignees = roster.filter { item.assigneeIDs.contains($0) } // roster order = deterministic
            guard !assignees.isEmpty else { continue } // unassigned -> counted by unassignedTotal
            let shares = allocate(amountCents: item.amount.minorUnits, weights: Array(repeating: 1, count: assignees.count))
            for (index, personID) in assignees.enumerated() {
                result[personID, default: .zero] += Money(shares[index])
            }
        }
        return result
    }

    /// Total of items with no on-roster assignee (never assigned, or assigned only to deleted people).
    /// Surfaced for the amber unassigned guard so this money is never silently charged.
    public static func unassignedTotal(people: [Person], items: [Item]) -> Money {
        let roster = Set(people.map(\.id))
        return items.reduce(Money.zero) { total, item in
            item.assigneeIDs.isDisjoint(with: roster) ? total + item.amount : total
        }
    }

    /// Resolve `TipMode` to absolute cents. For a percentage this is the SECOND rounding site
    /// (`percent -> cents`), rounded to the nearest cent exactly once with integer math.
    public static func resolvedTip(_ bill: Bill) -> Money {
        Money(tipCents(base: assignedSubtotalCents(people: bill.people, items: bill.items), tip: bill.tip))
    }

    /// The single pipeline: subtotals -> allocate(tax, weights) -> allocate(tip, weights).
    public static func compute(_ bill: Bill) -> BillResult {
        let roster = bill.people.map(\.id)
        let subs = subtotals(people: bill.people, items: bill.items)
        let weights = roster.map { subs[$0]?.minorUnits ?? 0 }
        let assignedSub = weights.reduce(0, +)

        let taxShares = allocate(amountCents: bill.tax.minorUnits, weights: weights)
        let tip = tipCents(base: assignedSub, tip: bill.tip) // reuse the already-known subtotal
        let tipShares = allocate(amountCents: tip, weights: weights)

        var perPerson: [UUID: Breakdown] = [:]
        for (index, personID) in roster.enumerated() {
            // Inside this loop the roster is non-empty, so allocate returned one share per weight.
            let sub = weights[index]
            let taxShare = taxShares[index]
            let tipShare = tipShares[index]
            perPerson[personID] = Breakdown(
                subtotal: Money(sub),
                tax: Money(taxShare),
                tip: Money(tipShare),
                total: Money(sub + taxShare + tipShare)
            )
        }

        return BillResult(
            perPerson: perPerson,
            assignedSubtotal: Money(assignedSub),
            unassigned: unassignedTotal(people: bill.people, items: bill.items),
            grandTotal: Money(assignedSub + bill.tax.minorUnits + tip)
        )
    }

    // MARK: - Private

    /// The one `TipMode -> cents` code path. Percent rounds to the nearest cent once (round half up),
    /// using integer math so no `Double` touches money.
    private static func tipCents(base: Int, tip: TipMode) -> Int {
        switch tip {
        case let .fixed(amount):
            return amount.minorUnits
        case let .percent(percent):
            // Percent tip is a percentage of the (non-negative) assigned subtotal — you don't tip a
            // fraction of a net-negative bill. Round to the nearest cent once, round half up, integer math.
            let numerator = max(base, 0) * percent
            return (numerator + 50) / 100
        }
    }

    private static func assignedSubtotalCents(people: [Person], items: [Item]) -> Int {
        subtotals(people: people, items: items).values.reduce(0) { $0 + $1.minorUnits }
    }
}
