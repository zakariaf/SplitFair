import BillCore
import Foundation
import Observation

/// The single source of truth for the app. One `@MainActor @Observable` store owns the current
/// `Bill`; both screens read it and mutate it only through intent methods. Totals are a COMPUTED
/// property, so they recompute live (no "Calculate" button) and can never drift from a stored copy.
///
/// The current bill auto-saves (debounced) on every mutation and is restored on launch — the only
/// thing persisted, ever (see `BillDraftStore`). No history, no accounts, no sync.
@MainActor @Observable
final class BillStore {
    private(set) var bill: Bill {
        didSet { scheduleSave() }
    }

    /// Derived on read — never stored. Reconciliation is guaranteed by `BillMath` (see BillCore).
    var totals: BillResult { BillMath.compute(bill) }

    @ObservationIgnored private let draftStore: BillDraftStore
    @ObservationIgnored private let saveDebounce: Duration
    @ObservationIgnored private var saveTask: Task<Void, Never>?

    init(draftStore: BillDraftStore = BillDraftStore(), saveDebounce: Duration = .milliseconds(600), seedSample: Bool = false) {
        self.draftStore = draftStore
        self.saveDebounce = saveDebounce
        // Restore on launch (didSet does not fire during init). `seedSample` is a testing/screenshot
        // seam, enabled by the `--seed-sample` launch argument; it never runs in normal use.
        self.bill = seedSample ? BillStore.sampleBill : draftStore.load()
    }

    /// The canonical $97.20 bill plus one unassigned item — used for previews, UI tests, and
    /// screenshots via the `--seed-sample` launch argument.
    static var sampleBill: Bill {
        let ana = Person(name: "Ana", colorIndex: 0)
        let ben = Person(name: "Ben", colorIndex: 1)
        let cy = Person(name: "Cy", colorIndex: 2)
        var bill = Bill(currency: .usd, people: [ana, ben, cy], tax: Money(660), tip: .percent(20))
        bill.items = [
            Item(label: "Salad", amount: Money(1250), assigneeIDs: [ana.id]),
            Item(label: "Steak", amount: Money(2800), assigneeIDs: [ben.id]),
            Item(label: "Cocktail", amount: Money(900), assigneeIDs: [ben.id]),
            Item(label: "Pasta", amount: Money(1600), assigneeIDs: [cy.id]),
            Item(label: "Nachos", amount: Money(1000), assigneeIDs: [ana.id, ben.id, cy.id]),
            Item(label: "Fries", amount: Money(600), assigneeIDs: []),
        ]
        return bill
    }

    // MARK: - People

    func addPerson(named name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let colorIndex = bill.people.count
        let displayName = trimmed.isEmpty ? "Person \(colorIndex + 1)" : trimmed
        bill.people.append(Person(name: displayName, colorIndex: colorIndex))
    }

    /// Rename a diner. A blank name falls back to "Person N" (their 1-based roster position), so a
    /// sticker never loses its identity — the roster and every assignment reference the same `id`.
    func renamePerson(_ id: Person.ID, to name: String) {
        guard let index = bill.people.firstIndex(where: { $0.id == id }) else { return }
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        bill.people[index].name = trimmed.isEmpty ? "Person \(index + 1)" : trimmed
    }

    /// Removing a person drops them from every item's assignees; an item left with none becomes
    /// unassigned (surfaced by the guard), never silently charged.
    func deletePerson(_ id: Person.ID) {
        bill.people.removeAll { $0.id == id }
        for index in bill.items.indices {
            bill.items[index].assigneeIDs.remove(id)
        }
    }

    // MARK: - Items

    func addItem(amount: Money, label: String = "") {
        bill.items.append(Item(label: label, amount: amount))
    }

    func deleteItem(_ id: Item.ID) {
        bill.items.removeAll { $0.id == id }
    }

    func setItemAmount(_ id: Item.ID, _ amount: Money) {
        guard let index = bill.items.firstIndex(where: { $0.id == id }) else { return }
        bill.items[index].amount = amount
    }

    func setItemLabel(_ id: Item.ID, _ label: String) {
        guard let index = bill.items.firstIndex(where: { $0.id == id }) else { return }
        bill.items[index].label = label
    }

    // MARK: - Assignment

    func toggleAssignment(item itemID: Item.ID, person personID: Person.ID) {
        guard let index = bill.items.firstIndex(where: { $0.id == itemID }) else { return }
        if bill.items[index].assigneeIDs.contains(personID) {
            bill.items[index].assigneeIDs.remove(personID)
        } else {
            bill.items[index].assigneeIDs.insert(personID)
        }
    }

    /// Toggle: if everyone already shares the item, clear it; otherwise assign the whole roster.
    func assignToEveryone(item itemID: Item.ID) {
        guard let index = bill.items.firstIndex(where: { $0.id == itemID }) else { return }
        let everyone = Set(bill.people.map(\.id))
        bill.items[index].assigneeIDs = bill.items[index].assigneeIDs == everyone ? [] : everyone
    }

    // MARK: - Tax & tip

    func setTax(_ amount: Money) {
        bill.tax = amount
    }

    func setTip(_ tip: TipMode) {
        bill.tip = tip
    }

    // MARK: - Reset & persistence

    /// Clear the bill. Order matters: setting `.empty` schedules a save, which we immediately cancel
    /// before deleting the file — otherwise the pending save would re-create it.
    func clear() {
        bill = .empty
        saveTask?.cancel()
        saveTask = nil
        draftStore.clear()
    }

    /// Persist immediately (used when the scene leaves `.active`), skipping the debounce.
    func flush() async {
        saveTask?.cancel()
        saveTask = nil
        let snapshot = bill
        let store = draftStore
        await Task.detached { try? store.save(snapshot) }.value
    }

    /// Debounced auto-save: coalesces rapid edits, then writes off the main actor.
    private func scheduleSave() {
        saveTask?.cancel()
        let snapshot = bill
        let store = draftStore
        let delay = saveDebounce
        saveTask = Task {
            try? await Task.sleep(for: delay)
            if Task.isCancelled { return }
            await Task.detached { try? store.save(snapshot) }.value
        }
    }
}
