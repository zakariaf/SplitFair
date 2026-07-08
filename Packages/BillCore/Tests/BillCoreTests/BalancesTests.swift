import Foundation
import Testing
@testable import BillCore

@Suite("Balances — running who-owes-whom")
struct BalancesTests {
    private func person(_ name: String, _ color: Int = 0) -> Person { Person(name: name, colorIndex: color) }
    private func item(_ cents: Int, _ who: [Person]) -> Item {
        Item(label: "", amount: Money(cents), assigneeIDs: Set(who.map(\.id)))
    }

    @Test("A bill I paid: everyone else owes me exactly their reconciled share")
    func iPaid() {
        let me = person("Me"), ben = person("Ben", 1), cy = person("Cy", 2)
        var bill = Bill(people: [me, ben, cy], payerID: me.id)
        bill.items = [item(1000, [ben]), item(2000, [cy]), item(300, [me])]
        let result = BillMath.compute(bill)
        let net = netBalances(bills: [bill], me: me.id)

        #expect(net[ben.id] == result.perPerson[ben.id]?.total) // positive ⇒ Ben owes me
        #expect(net[cy.id] == result.perPerson[cy.id]?.total)
        #expect(net[me.id] == nil)                              // I never owe myself
        // What everyone owes me sums to the grand total minus my own share — no cent unattributed.
        let owedToMe = net.values.reduce(Money.zero, +)
        #expect(owedToMe == result.grandTotal - (result.perPerson[me.id]?.total ?? .zero))
    }

    @Test("A bill a friend paid: I owe them exactly my reconciled share")
    func friendPaid() {
        let me = person("Me"), ben = person("Ben", 1)
        var bill = Bill(people: [me, ben], payerID: ben.id)
        bill.items = [item(1500, [me]), item(2500, [ben])]
        let myShare = BillMath.compute(bill).perPerson[me.id]?.total.minorUnits ?? 0
        let net = netBalances(bills: [bill], me: me.id)
        #expect(net[ben.id]?.minorUnits == -myShare)            // negative ⇒ I owe Ben
    }

    @Test("Opposite-direction bills net across the library")
    func netsAcross() {
        let me = person("Me"), ben = person("Ben", 1)
        var iPaidBill = Bill(people: [me, ben], payerID: me.id)
        iPaidBill.items = [item(1000, [ben])]                   // Ben owes me 1000
        var benPaidBill = Bill(people: [me, ben], payerID: ben.id)
        benPaidBill.items = [item(400, [me])]                   // I owe Ben 400
        let net = netBalances(bills: [iPaidBill, benPaidBill], me: me.id)
        #expect(net[ben.id] == Money(600))                      // 1000 − 400
    }

    @Test("A bill with no recorded payer is excluded")
    func noPayerExcluded() {
        let me = person("Me"), ben = person("Ben", 1)
        var bill = Bill(people: [me, ben], payerID: nil)
        bill.items = [item(1000, [ben])]
        #expect(netBalances(bills: [bill], me: me.id).isEmpty)
    }

    @Test(arguments: 0 ..< 200)
    func noLeakedCent(seed: Int) {
        var rng = SeededRNG(seed: UInt64(seed) &+ 1)
        let people = (0 ..< Int.random(in: 2 ... 6, using: &rng)).map { Person(name: "P\($0)", colorIndex: $0) }
        let me = people[0]
        var bill = Bill(people: people, payerID: me.id)
        bill.items = (0 ..< Int.random(in: 0 ... 8, using: &rng)).map { _ in
            let k = Int.random(in: 1 ... people.count, using: &rng)
            return item(Int.random(in: 0 ... 50_000, using: &rng), Array(people.shuffled(using: &rng).prefix(k)))
        }
        bill.tax = Money(Int.random(in: 0 ... 5_000, using: &rng))
        bill.tip = .percent(Int.random(in: 0 ... 30, using: &rng))

        let result = BillMath.compute(bill)
        let owedToMe = netBalances(bills: [bill], me: me.id).values.reduce(Money.zero, +)
        // Because I paid, the sum owed to me is exactly the grand total minus my own reconciled share.
        #expect(owedToMe == result.grandTotal - (result.perPerson[me.id]?.total ?? .zero))
    }
}
