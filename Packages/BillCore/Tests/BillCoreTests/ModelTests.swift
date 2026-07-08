import Foundation
import Testing
@testable import BillCore

@Suite("Domain model")
struct ModelTests {
    @Test("Bill.empty is a clean USD bill")
    func emptyBill() {
        let bill = Bill.empty
        #expect(bill.people.isEmpty)
        #expect(bill.items.isEmpty)
        #expect(bill.tax == .zero)
        #expect(bill.tip == .percent(0))
        #expect(bill.currency == .usd)
    }

    @Test("Two people with the same name stay distinct by id")
    func identity() {
        let a = Person(name: "Sam", colorIndex: 0)
        let b = Person(name: "Sam", colorIndex: 1)
        #expect(a != b)
        #expect(a.id != b.id)
    }

    @Test("Editing an item price leaves its assignment links intact")
    func linksSurviveEdit() {
        let who: Set<UUID> = [UUID(), UUID()]
        var item = Item(label: "Wine", amount: Money(4200), assigneeIDs: who)
        item.amount = Money(3800)
        #expect(item.assigneeIDs == who)
    }

    @Test("Bill round-trips through Codable, including both tip modes")
    func codableRoundTrip() throws {
        let ana = Person(name: "Ana", colorIndex: 0)
        let ben = Person(name: "Ben", colorIndex: 1)
        for tip in [TipMode.percent(20), TipMode.fixed(Money(1510))] {
            var bill = Bill(currency: Currency(code: "EUR", exponent: 2), people: [ana, ben], tax: Money(660), tip: tip)
            bill.items = [Item(label: "Salad", amount: Money(1250), assigneeIDs: [ana.id])]
            let data = try JSONEncoder().encode(bill)
            #expect(try JSONDecoder().decode(Bill.self, from: data) == bill)
        }
    }
}
