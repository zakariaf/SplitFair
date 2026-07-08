import BillCore
import Foundation
import Testing
@testable import SplitFair

@MainActor
@Suite("BillStore intents")
struct BillStoreTests {
    @Test("addPerson auto-names blanks and assigns sequential color indices")
    func addPerson() {
        let store = BillStore()
        store.addPerson(named: "Ana")
        store.addPerson(named: "   ") // blank -> auto name
        #expect(store.bill.people.count == 2)
        #expect(store.bill.people[0].name == "Ana")
        #expect(store.bill.people[0].colorIndex == 0)
        #expect(store.bill.people[1].name == "Person 2")
        #expect(store.bill.people[1].colorIndex == 1)
    }

    @Test("deletePerson removes them and drops their assignments")
    func deletePerson() {
        let store = BillStore()
        store.addPerson(named: "Ana")
        store.addPerson(named: "Ben")
        let ana = store.bill.people[0], ben = store.bill.people[1]
        store.addItem(amount: Money(1000))
        let item = store.bill.items[0].id
        store.toggleAssignment(item: item, person: ana.id)
        store.toggleAssignment(item: item, person: ben.id)
        store.deletePerson(ana.id)
        #expect(store.bill.people.count == 1)
        #expect(store.bill.items[0].assigneeIDs == [ben.id])
    }

    @Test("toggleAssignment adds then removes")
    func toggle() {
        let store = BillStore()
        store.addPerson(named: "Ana")
        store.addItem(amount: Money(500))
        let ana = store.bill.people[0].id, item = store.bill.items[0].id
        store.toggleAssignment(item: item, person: ana)
        #expect(store.bill.items[0].assigneeIDs == [ana])
        store.toggleAssignment(item: item, person: ana)
        #expect(store.bill.items[0].assigneeIDs.isEmpty)
    }

    @Test("assignToEveryone toggles the whole roster on and off")
    func everyone() {
        let store = BillStore()
        for name in ["A", "B", "C"] { store.addPerson(named: name) }
        store.addItem(amount: Money(900))
        let item = store.bill.items[0].id
        store.assignToEveryone(item: item)
        #expect(store.bill.items[0].assigneeIDs.count == 3)
        store.assignToEveryone(item: item)
        #expect(store.bill.items[0].assigneeIDs.isEmpty)
    }

    @Test("totals recompute live and reconcile")
    func totalsLive() {
        let store = BillStore()
        store.addPerson(named: "Ana")
        store.addPerson(named: "Ben")
        store.addItem(amount: Money(1000))
        store.addItem(amount: Money(2000))
        store.toggleAssignment(item: store.bill.items[0].id, person: store.bill.people[0].id)
        store.toggleAssignment(item: store.bill.items[1].id, person: store.bill.people[1].id)
        store.setTip(.percent(20))
        let result = store.totals
        #expect(result.grandTotal == Money(3600)) // 3000 + 20% tip
        #expect(result.perPerson.values.reduce(Money.zero) { $0 + $1.total } == result.grandTotal)
    }

    @Test("clear resets to empty")
    func clear() {
        let store = BillStore()
        store.addPerson(named: "Ana")
        store.addItem(amount: Money(100))
        store.clear()
        #expect(store.bill.people.isEmpty)
        #expect(store.bill.items.isEmpty)
    }
}
