import BillCore
import Foundation
import Testing
@testable import SplitFair

@Suite("LibraryStore persistence + migration")
struct LibraryStoreTests {
    /// A unique temp base directory per test; removed on teardown.
    private func tempBase() -> URL {
        FileManager.default.temporaryDirectory.appending(path: "library-\(UUID().uuidString)", directoryHint: .isDirectory)
    }

    /// The exact wire shape of the pre-EPIC-10 single-bill draft — no id/title/createdAt/payerID.
    private struct LegacyDraft: Encodable {
        let currency: Currency
        let people: [Person]
        let items: [Item]
        let tax: Money
        let tip: TipMode
    }

    @Test("bills round-trip and come back newest-first")
    func billsRoundTrip() throws {
        let base = tempBase()
        defer { try? FileManager.default.removeItem(at: base) }
        let store = LibraryStore(baseURL: base)

        let older = Bill(title: "Lunch", createdAt: Date(timeIntervalSince1970: 1000))
        let newer = Bill(title: "Dinner", createdAt: Date(timeIntervalSince1970: 2000))
        try store.saveBill(older)
        try store.saveBill(newer)

        let loaded = store.loadBills()
        #expect(loaded.count == 2)
        #expect(loaded.first?.id == newer.id)   // newest first
        #expect(loaded.last?.id == older.id)
    }

    @Test("deleteBill removes just that bill")
    func deleteOne() throws {
        let base = tempBase()
        defer { try? FileManager.default.removeItem(at: base) }
        let store = LibraryStore(baseURL: base)
        let a = Bill(title: "A"), b = Bill(title: "B")
        try store.saveBill(a)
        try store.saveBill(b)
        store.deleteBill(a.id)
        let ids = store.loadBills().map(\.id)
        #expect(ids == [b.id])
    }

    @Test("roster round-trips people and the 'you' id")
    func rosterRoundTrip() throws {
        let base = tempBase()
        defer { try? FileManager.default.removeItem(at: base) }
        let store = LibraryStore(baseURL: base)
        let ana = Person(name: "Ana", colorIndex: 0)
        let ben = Person(name: "Ben", colorIndex: 1)
        let snapshot = LibraryStore.RosterSnapshot(people: [ana, ben], meID: ana.id)
        try store.saveRoster(snapshot)
        #expect(store.loadRoster() == snapshot)
    }

    @Test("a missing roster loads empty")
    func missingRosterEmpty() {
        #expect(LibraryStore(baseURL: tempBase()).loadRoster() == LibraryStore.RosterSnapshot())
    }

    @Test("legacy current-bill.json migrates into the library once, seeding the roster")
    func migratesLegacyDraft() throws {
        let base = tempBase()
        defer { try? FileManager.default.removeItem(at: base) }
        try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)

        let ben = Person(name: "Ben", colorIndex: 0)
        let legacy = LegacyDraft(
            currency: .usd,
            people: [ben],
            items: [Item(label: "Steak", amount: Money(2800), assigneeIDs: [ben.id])],
            tax: Money(240),
            tip: .percent(18)
        )
        let legacyURL = base.appending(path: "current-bill.json")
        try JSONEncoder().encode(legacy).write(to: legacyURL)

        let store = LibraryStore(baseURL: base)
        store.migrateLegacyDraftIfNeeded()

        let bills = store.loadBills()
        #expect(bills.count == 1)
        #expect(bills.first?.people == [ben])
        #expect(store.loadRoster().people == [ben])
        #expect(store.loadRoster().meID == nil)                       // "you" set later by the picker
        #expect(!FileManager.default.fileExists(atPath: legacyURL.path)) // consumed

        // Idempotent: running again does nothing (legacy file already gone).
        store.migrateLegacyDraftIfNeeded()
        #expect(store.loadBills().count == 1)
    }

    @Test("a corrupt legacy draft is discarded quietly")
    func corruptLegacyDiscarded() throws {
        let base = tempBase()
        defer { try? FileManager.default.removeItem(at: base) }
        try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        let legacyURL = base.appending(path: "current-bill.json")
        try Data("not json {{{".utf8).write(to: legacyURL)

        let store = LibraryStore(baseURL: base)
        store.migrateLegacyDraftIfNeeded()
        #expect(store.loadBills().isEmpty)
        #expect(!FileManager.default.fileExists(atPath: legacyURL.path))
    }
}
