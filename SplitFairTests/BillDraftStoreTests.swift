import BillCore
import Foundation
import Testing
@testable import SplitFair

@Suite("BillDraftStore persistence")
struct BillDraftStoreTests {
    private func tempURL() -> URL {
        FileManager.default.temporaryDirectory.appending(path: "billdraft-\(UUID().uuidString).json")
    }

    @Test("save then load round-trips the bill exactly")
    func roundTrip() throws {
        let url = tempURL()
        defer { try? FileManager.default.removeItem(at: url) }
        let store = BillDraftStore(url: url)
        var bill = Bill(people: [Person(name: "Ana", colorIndex: 0)], tax: Money(660), tip: .percent(20))
        bill.items = [Item(label: "Salad", amount: Money(1250), assigneeIDs: [bill.people[0].id])]
        try store.save(bill)
        #expect(store.load() == bill)
    }

    @Test("a missing file loads as .empty (no migrations)")
    func missingIsEmpty() {
        #expect(BillDraftStore(url: tempURL()).load() == .empty)
    }

    @Test("a corrupt file loads as .empty and never throws")
    func corruptIsEmpty() throws {
        let url = tempURL()
        defer { try? FileManager.default.removeItem(at: url) }
        try Data("not json {{{".utf8).write(to: url)
        #expect(BillDraftStore(url: url).load() == .empty)
    }

    @Test("clear deletes the saved file")
    func clearDeletes() throws {
        let url = tempURL()
        let store = BillDraftStore(url: url)
        try store.save(.empty)
        #expect(FileManager.default.fileExists(atPath: url.path))
        store.clear()
        #expect(!FileManager.default.fileExists(atPath: url.path))
    }
}
