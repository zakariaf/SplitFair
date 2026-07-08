import BillCore
import Foundation
import Testing
@testable import SplitFair

@MainActor
@Suite("BillStore intents")
struct BillStoreTests {
    @Test("addPerson auto-names blanks and assigns sequential color indices")
    func addPerson() {
        let store = BillStore(library: LibraryStore(baseURL: tempBase()))
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
        let store = BillStore(library: LibraryStore(baseURL: tempBase()))
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
        let store = BillStore(library: LibraryStore(baseURL: tempBase()))
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
        let store = BillStore(library: LibraryStore(baseURL: tempBase()))
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
        let store = BillStore(library: LibraryStore(baseURL: tempBase()))
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
        let store = BillStore(library: LibraryStore(baseURL: tempBase()))
        store.addPerson(named: "Ana")
        store.addItem(amount: Money(100))
        store.clear()
        #expect(store.bill.people.isEmpty)
        #expect(store.bill.items.isEmpty)
    }

    // MARK: - Library

    @Test("newBill and duplicateBill open a bill; delete and rename mutate the library")
    func libraryOps() {
        let store = BillStore(library: LibraryStore(baseURL: tempBase()))
        store.addPerson(named: "Ana")
        store.addItem(amount: Money(1000))
        let first = store.selectedBillID

        store.newBill()
        #expect(store.bills.count == 2)
        #expect(store.selectedBillID != first)
        #expect(store.bill.people.isEmpty) // the new bill is fresh

        store.duplicateBill(first!)
        #expect(store.bills.count == 3)
        #expect(store.bill.people.count == 1)       // the copy carries participants…
        #expect(store.bill.items.count == 1)        // …and items
        #expect(store.bill.id != first)             // …under a fresh id

        store.renameBill(store.selectedBillID!, to: "Copy night")
        #expect(store.bill.title == "Copy night")

        store.deleteBill(first!)
        #expect(store.bills.count == 2)
        #expect(!store.bills.contains { $0.id == first })
    }

    @Test("balances net across two bills: one I paid, one a friend paid")
    func balancesAcrossBills() {
        let store = BillStore(library: LibraryStore(baseURL: tempBase()))
        let ana = store.addFriend(named: "Ana")
        let ben = store.addFriend(named: "Ben")
        store.setMe(ana)

        // Bill 1 — I (Ana) paid; Ben ordered $10.
        store.addParticipant(ana)
        store.addParticipant(ben)
        store.addItem(amount: Money(1000))
        store.toggleAssignment(item: store.bill.items[0].id, person: ben)
        store.setPayer(ana)

        // Bill 2 — Ben paid; I ordered $4.
        store.newBill()
        store.addParticipant(ana)
        store.addParticipant(ben)
        store.addItem(amount: Money(400))
        store.toggleAssignment(item: store.bill.items[0].id, person: ana)
        store.setPayer(ben)

        #expect(store.balances[ben] == Money(600)) // 1000 owed to me − 400 I owe = net +600
        #expect(store.meID == ana)
    }

    // MARK: - Persistence wiring

    private func tempBase() -> URL {
        FileManager.default.temporaryDirectory.appending(path: "billstore-\(UUID().uuidString)", directoryHint: .isDirectory)
    }

    @Test("bills and roster persist across a relaunch")
    func libraryPersists() async throws {
        let base = tempBase()
        defer { try? FileManager.default.removeItem(at: base) }
        let store = BillStore(library: LibraryStore(baseURL: base), saveDebounce: .milliseconds(20))
        store.addPerson(named: "Ana")   // edits the first bill + registers a friend
        store.newBill()
        store.addPerson(named: "Ben")   // edits the second bill + registers a friend
        try? await Task.sleep(for: .milliseconds(150))
        await store.flush()

        let reloaded = BillStore(library: LibraryStore(baseURL: base))
        #expect(reloaded.bills.count == 2)
        #expect(reloaded.roster.count == 2)
    }

    @Test("flush persists the open bill immediately, without waiting for the debounce")
    func flushImmediate() async throws {
        let base = tempBase()
        defer { try? FileManager.default.removeItem(at: base) }
        let store = BillStore(library: LibraryStore(baseURL: base), saveDebounce: .seconds(60))
        store.addPerson(named: "Ana")
        await store.flush()
        #expect(LibraryStore(baseURL: base).loadBills().first?.people.count == 1)
    }

    @Test("clear deletes the bill and cancels the pending save so it stays gone")
    func clearCancelsPendingSave() async throws {
        let base = tempBase()
        defer { try? FileManager.default.removeItem(at: base) }
        let store = BillStore(library: LibraryStore(baseURL: base), saveDebounce: .milliseconds(20))
        store.addPerson(named: "Ana")
        await store.flush()
        #expect(!LibraryStore(baseURL: base).loadBills().isEmpty)
        store.clear()
        try? await Task.sleep(for: .milliseconds(150)) // wait past any debounce
        #expect(LibraryStore(baseURL: base).loadBills().isEmpty) // stayed gone ⇒ save was cancelled
    }
}
