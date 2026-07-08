import Foundation
import Testing
@testable import BillCore

@Suite("Reconciliation — the $97.20 acceptance gate")
struct ReconciliationTests {
    private func person(_ name: String, _ color: Int) -> Person { Person(name: name, colorIndex: color) }
    private func item(_ label: String, _ cents: Int, _ who: [Person]) -> Item {
        Item(label: label, amount: Money(cents), assigneeIDs: Set(who.map(\.id)))
    }

    /// Salad + Steak + Cocktail + Pasta + Nachos(shared 3), tax $6.60, tip $15.10 -> $97.20.
    private func acceptanceBill(tip: TipMode) -> (Bill, Person, Person, Person) {
        let ana = person("Ana", 0), ben = person("Ben", 1), cy = person("Cy", 2)
        var bill = Bill(people: [ana, ben, cy], tax: Money(660), tip: tip)
        bill.items = [
            item("Salad", 1250, [ana]),
            item("Steak", 2800, [ben]),
            item("Cocktail", 900, [ben]),
            item("Pasta", 1600, [cy]),
            item("Nachos", 1000, [ana, ben, cy]),
        ]
        return (bill, ana, ben, cy)
    }

    @Test("3 people, shared nachos, tax + fixed $15.10 tip -> $97.20 to the exact cent")
    func acceptanceFixed() {
        let (bill, ana, ben, cy) = acceptanceBill(tip: .fixed(Money(1510)))
        let r = BillMath.compute(bill)
        #expect(r.perPerson[ana.id]?.total == Money(2039)) // $20.39
        #expect(r.perPerson[ben.id]?.total == Money(5193)) // $51.93
        #expect(r.perPerson[cy.id]?.total == Money(2488)) // $24.88
        #expect(r.assignedSubtotal == Money(7550))
        #expect(r.unassigned == .zero)
        #expect(r.grandTotal == Money(9720)) // $97.20
        #expect(r.perPerson.values.reduce(Money.zero) { $0 + $1.total } == r.grandTotal)
    }

    @Test("Same bill with a 20% tip resolves to $15.10 and gives the identical split")
    func acceptancePercent() {
        let (bill, _, ben, _) = acceptanceBill(tip: .percent(20))
        #expect(BillMath.resolvedTip(bill) == Money(1510))
        let r = BillMath.compute(bill)
        #expect(r.grandTotal == Money(9720))
        #expect(r.perPerson[ben.id]?.total == Money(5193))
    }

    /// The percent -> cents conversion is a separate rounding site; it must round to the nearest
    /// cent exactly once. (3333 * 20% = 666.6 -> 667; 10001 * 20% = 2000.2 -> 2000.)
    @Test("percent -> cents rounds to the nearest cent, once", arguments: zip([7550, 3333, 10001], [1510, 667, 2000]))
    func tipRounding(subtotal: Int, expected: Int) {
        let solo = person("A", 0)
        var bill = Bill(people: [solo], tip: .percent(20))
        bill.items = [item("", subtotal, [solo])]
        #expect(BillMath.resolvedTip(bill) == Money(expected))
    }

    @Test("Everyone comped (zero subtotal): tax and tip split evenly and still reconcile")
    func compedReconciles() {
        let a = person("A", 0), b = person("B", 1)
        var bill = Bill(people: [a, b], tax: Money(200), tip: .fixed(Money(100)))
        bill.items = [item("comped", 0, [a])]
        let r = BillMath.compute(bill)
        #expect(r.assignedSubtotal == .zero)
        #expect(r.grandTotal == Money(300))
        #expect(r.perPerson[a.id]?.total == Money(150))
        #expect(r.perPerson[b.id]?.total == Money(150))
        #expect(r.perPerson.values.reduce(Money.zero) { $0 + $1.total } == r.grandTotal)
    }

    @Test("Unassigned items are surfaced, never charged")
    func unassignedSurfaced() {
        let a = person("A", 0)
        var bill = Bill(people: [a], tax: .zero, tip: .percent(0))
        bill.items = [item("mine", 1000, [a]), item("orphan", 600, [])]
        let r = BillMath.compute(bill)
        #expect(r.assignedSubtotal == Money(1000))
        #expect(r.unassigned == Money(600))
        #expect(r.grandTotal == Money(1000)) // the orphan is not in the grand total
    }

    /// The ultimate invariant, fuzzed over random bills (including discount items, comps, and both
    /// tip modes): the sum of the parts always equals the whole, to the exact cent.
    @Test("Random bills always reconcile to the exact cent", arguments: 0 ..< 300)
    func fuzzReconcile(seed: Int) {
        var rng = SeededRNG(seed: UInt64(seed) &+ 0xBEEF)
        let people = (0 ..< Int.random(in: 1 ... 6, using: &rng)).map { Person(name: "P\($0)", colorIndex: $0) }
        var items: [Item] = []
        for _ in 0 ..< Int.random(in: 0 ... 12, using: &rng) {
            let amount = Int.random(in: -500 ... 8000, using: &rng) // negatives model discount/comp items
            let who = people.filter { _ in Bool.random(using: &rng) }
            items.append(Item(label: "", amount: Money(amount), assigneeIDs: Set(who.map(\.id))))
        }
        let tip: TipMode = Bool.random(using: &rng)
            ? .percent(Int.random(in: 0 ... 30, using: &rng))
            : .fixed(Money(Int.random(in: 0 ... 3000, using: &rng)))
        var bill = Bill(people: people, tax: Money(Int.random(in: 0 ... 1500, using: &rng)), tip: tip)
        bill.items = items

        let r = BillMath.compute(bill)
        let sumOfParts = r.perPerson.values.reduce(Money.zero) { $0 + $1.total }
        #expect(sumOfParts == r.grandTotal) // parts == whole, for every random bill
    }
}
