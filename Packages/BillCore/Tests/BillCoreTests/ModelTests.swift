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

    @Test("Bill round-trips its library metadata (id, title, createdAt, payerID)")
    func metadataRoundTrip() throws {
        let ana = Person(name: "Ana", colorIndex: 0)
        var bill = Bill(title: "Friday dinner", people: [ana], payerID: ana.id)
        bill.items = [Item(label: "Salad", amount: Money(1250), assigneeIDs: [ana.id])]
        let decoded = try JSONDecoder().decode(Bill.self, from: JSONEncoder().encode(bill))
        #expect(decoded == bill)
        #expect(decoded.id == bill.id)
        #expect(decoded.title == "Friday dinner")
        #expect(decoded.payerID == ana.id)
    }

    /// The exact wire shape of the old single-bill `Bill` — currency/people/items/tax/tip, no id,
    /// title, createdAt, or payerID — encoded with the real codecs so the format can't drift.
    private struct LegacyBill: Encodable {
        let currency: Currency
        let people: [Person]
        let items: [Item]
        let tax: Money
        let tip: TipMode
    }

    @Test("A pre-EPIC-10 bill JSON (no id/title/createdAt/payerID) decodes with defaults")
    func legacyDecodeGetsDefaults() throws {
        let ben = Person(name: "Ben", colorIndex: 0)
        let legacy = LegacyBill(
            currency: .usd,
            people: [ben],
            items: [Item(label: "Steak", amount: Money(2800), assigneeIDs: [ben.id])],
            tax: Money(240),
            tip: .percent(18)
        )
        let bill = try JSONDecoder().decode(Bill.self, from: JSONEncoder().encode(legacy))
        // Old fields survive…
        #expect(bill.currency == .usd)
        #expect(bill.people == [ben])
        #expect(bill.tax == Money(240))
        #expect(bill.tip == .percent(18))
        // …new fields default cleanly rather than throwing keyNotFound.
        #expect(bill.title.isEmpty)
        #expect(bill.payerID == nil)
    }
}
