import BillCore
import Foundation
import Observation

/// The single source of truth for the app — one `@MainActor @Observable` store owning the whole
/// on-device state: the persistent friends `roster` (with `meID`, which one is "you"), the `bills`
/// library, and which bill is open (`selectedBillID`). Every screen reads it and mutates only
/// through intent methods.
///
/// Both derivations are COMPUTED, never stored, so they can't drift: `totals` (this bill's split via
/// `BillMath`) and `balances` (who-owes-whom across the library via `netBalances`). Bills and the
/// roster auto-save (debounced, off the main actor) to the local `LibraryStore` — no history limit,
/// no accounts, no sync.
@MainActor @Observable
final class BillStore {
    private(set) var bills: [Bill] = []
    private(set) var roster: [Person] = []
    private(set) var meID: Person.ID?
    private(set) var selectedBillID: Bill.ID?

    @ObservationIgnored private let library: LibraryStore
    @ObservationIgnored private let saveDebounce: Duration
    @ObservationIgnored private var saveTask: Task<Void, Never>?

    init(library: LibraryStore = LibraryStore(), saveDebounce: Duration = .milliseconds(600), seedSample: Bool = false) {
        self.library = library
        self.saveDebounce = saveDebounce
        if seedSample {
            let sample = BillStore.sampleBill
            bills = [sample]
            roster = sample.people
            meID = sample.people.first?.id // "you" = Ana, so balances render in screenshots
            selectedBillID = sample.id
        } else {
            library.migrateLegacyDraftIfNeeded()
            bills = library.loadBills()
            let snapshot = library.loadRoster()
            roster = snapshot.people
            meID = snapshot.meID
            // Always keep a current bill for the editing screens; a brand-new empty bill is not
            // persisted until it is first edited (the mutate path schedules the save).
            selectedBillID = bills.first?.id
            if selectedBillID == nil {
                let fresh = Bill()
                bills = [fresh]
                selectedBillID = fresh.id
            }
        }
    }

    /// The canonical $97.20 bill (paid by Ana) plus one unassigned item — used for previews, UI
    /// tests, and screenshots via the `--seed-sample` launch argument.
    static var sampleBill: Bill {
        let ana = Person(name: "Ana", colorIndex: 0)
        let ben = Person(name: "Ben", colorIndex: 1)
        let cy = Person(name: "Cy", colorIndex: 2)
        var bill = Bill(title: "Dinner", currency: .usd, people: [ana, ben, cy], tax: Money(660), tip: .percent(20), payerID: ana.id)
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

    // MARK: - The open bill + derived values

    var currentBill: Bill? { bills.first { $0.id == selectedBillID } }

    /// The open bill, or `.empty` when nothing is selected — the editing screens read this.
    var bill: Bill { currentBill ?? .empty }

    /// This bill's reconciled split. Computed ⇒ live recompute, zero drift (see BillCore).
    var totals: BillResult { BillMath.compute(bill) }

    /// Net who-owes-whom relative to "you", across the whole library. Empty until "you" is set.
    var balances: [Person.ID: Money] {
        guard let meID else { return [:] }
        return netBalances(bills: bills, me: meID)
    }

    // MARK: - Library

    /// Start a fresh bill and open it (persisting the one we're leaving first).
    func newBill() {
        persistCurrentNow()
        let bill = Bill()
        bills.insert(bill, at: 0)
        selectedBillID = bill.id
        saveBillNow(bill)
    }

    func openBill(_ id: Bill.ID) {
        guard id != selectedBillID else { return }
        persistCurrentNow()
        selectedBillID = id
    }

    /// Copy a bill for "same friends, new night": same participants, same items (fresh item ids,
    /// assignments preserved), fresh id/date, and payer cleared so the new outing records its own.
    func duplicateBill(_ id: Bill.ID) {
        guard let source = bills.first(where: { $0.id == id }) else { return }
        persistCurrentNow()
        var copy = Bill(
            title: source.title.isEmpty ? "" : "\(source.title) (copy)",
            currency: source.currency,
            people: source.people,
            tax: source.tax,
            tip: source.tip
        )
        copy.items = source.items.map { Item(label: $0.label, amount: $0.amount, assigneeIDs: $0.assigneeIDs) }
        bills.insert(copy, at: 0)
        selectedBillID = copy.id
        saveBillNow(copy)
    }

    /// Delete a bill from the library. Cancels any pending debounced write first (it may hold a
    /// snapshot of this bill), then removes the file, so no stray save can resurrect it.
    func deleteBill(_ id: Bill.ID) {
        saveTask?.cancel()
        saveTask = nil
        bills.removeAll { $0.id == id }
        library.deleteBill(id)
        if selectedBillID == id {
            selectedBillID = bills.first?.id
            if selectedBillID == nil {
                let fresh = Bill()
                bills = [fresh]
                selectedBillID = fresh.id
            }
        }
    }

    func renameBill(_ id: Bill.ID, to title: String) {
        guard let index = bills.firstIndex(where: { $0.id == id }) else { return }
        bills[index].title = title.trimmingCharacters(in: .whitespaces)
        scheduleSave(bills[index])
    }

    // MARK: - Roster & "you"

    /// Register a new friend in the persistent roster with a stable color, and return their id.
    @discardableResult
    func addFriend(named name: String) -> Person.ID {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let colorIndex = roster.count
        let person = Person(name: trimmed.isEmpty ? "Person \(colorIndex + 1)" : trimmed, colorIndex: colorIndex)
        roster.append(person)
        saveRosterNow()
        return person.id
    }

    func setMe(_ id: Person.ID) {
        meID = id
        saveRosterNow()
    }

    /// Add an existing roster friend to the current bill as a participant.
    func addParticipant(_ friendID: Person.ID) {
        guard let friend = roster.first(where: { $0.id == friendID }) else { return }
        mutateCurrent { bill in
            if !bill.people.contains(where: { $0.id == friendID }) { bill.people.append(friend) }
        }
    }

    /// Record who fronted the current bill (nil clears it).
    func setPayer(_ id: Person.ID?) {
        mutateCurrent { $0.payerID = id }
    }

    // MARK: - People on the current bill

    /// Add a person by name: register them as a stable friend, then add to the current bill.
    func addPerson(named name: String) {
        let friendID = addFriend(named: name)
        addParticipant(friendID)
    }

    /// Rename a diner everywhere it matters: the roster (their canonical name, so balances reflect
    /// it) and this bill's snapshot. A blank name falls back to "Person N".
    func renamePerson(_ id: Person.ID, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let index = roster.firstIndex(where: { $0.id == id }) {
            roster[index].name = trimmed.isEmpty ? "Person \(index + 1)" : trimmed
            saveRosterNow()
        }
        mutateCurrent { bill in
            if let index = bill.people.firstIndex(where: { $0.id == id }) {
                bill.people[index].name = trimmed.isEmpty ? "Person \(index + 1)" : trimmed
            }
        }
    }

    /// Remove a participant from the current bill (not the roster — they may be in other bills or
    /// carry a balance). Drops them from every item's assignees and clears them as payer if set.
    func deletePerson(_ id: Person.ID) {
        mutateCurrent { bill in
            bill.people.removeAll { $0.id == id }
            for index in bill.items.indices { bill.items[index].assigneeIDs.remove(id) }
            if bill.payerID == id { bill.payerID = nil }
        }
    }

    // MARK: - Items on the current bill

    func addItem(amount: Money, label: String = "") {
        mutateCurrent { $0.items.append(Item(label: label, amount: amount)) }
    }

    func deleteItem(_ id: Item.ID) {
        mutateCurrent { $0.items.removeAll { $0.id == id } }
    }

    func setItemAmount(_ id: Item.ID, _ amount: Money) {
        mutateCurrent { bill in
            if let index = bill.items.firstIndex(where: { $0.id == id }) { bill.items[index].amount = amount }
        }
    }

    func setItemLabel(_ id: Item.ID, _ label: String) {
        mutateCurrent { bill in
            if let index = bill.items.firstIndex(where: { $0.id == id }) { bill.items[index].label = label }
        }
    }

    // MARK: - Assignment

    func toggleAssignment(item itemID: Item.ID, person personID: Person.ID) {
        mutateCurrent { bill in
            guard let index = bill.items.firstIndex(where: { $0.id == itemID }) else { return }
            if bill.items[index].assigneeIDs.contains(personID) {
                bill.items[index].assigneeIDs.remove(personID)
            } else {
                bill.items[index].assigneeIDs.insert(personID)
            }
        }
    }

    /// Toggle: if everyone already shares the item, clear it; otherwise assign the whole roster.
    func assignToEveryone(item itemID: Item.ID) {
        mutateCurrent { bill in
            guard let index = bill.items.firstIndex(where: { $0.id == itemID }) else { return }
            let everyone = Set(bill.people.map(\.id))
            bill.items[index].assigneeIDs = bill.items[index].assigneeIDs == everyone ? [] : everyone
        }
    }

    // MARK: - Tax & tip

    func setTax(_ amount: Money) { mutateCurrent { $0.tax = amount } }
    func setTip(_ tip: TipMode) { mutateCurrent { $0.tip = tip } }

    // MARK: - Clear & persistence

    /// "Clear bill" now discards the open bill from the library (settle-up made the single-draft
    /// model obsolete). `deleteBill` cancels the pending save so no stray write resurrects it.
    func clear() {
        guard let id = selectedBillID else { return }
        deleteBill(id)
    }

    /// Persist immediately (used when the scene leaves `.active`), skipping the debounce — the open
    /// bill and the roster both.
    func flush() async {
        saveTask?.cancel()
        saveTask = nil
        let bill = currentBill
        let snapshot = LibraryStore.RosterSnapshot(people: roster, meID: meID)
        let store = library
        await Task.detached {
            if let bill { try? store.saveBill(bill) }
            try? store.saveRoster(snapshot)
        }.value
    }

    // MARK: - Private

    /// Mutate the open bill and schedule its (debounced) save. The single mutation path.
    private func mutateCurrent(_ transform: (inout Bill) -> Void) {
        guard let index = bills.firstIndex(where: { $0.id == selectedBillID }) else { return }
        transform(&bills[index])
        scheduleSave(bills[index])
    }

    /// Debounced auto-save of one bill: coalesces rapid edits, then writes off the main actor.
    private func scheduleSave(_ bill: Bill) {
        saveTask?.cancel()
        let store = library
        let delay = saveDebounce
        saveTask = Task {
            try? await Task.sleep(for: delay)
            if Task.isCancelled { return }
            await Task.detached { try? store.saveBill(bill) }.value
        }
    }

    /// Write the open bill now (fire-and-forget), cancelling the debounce — used when switching bills.
    private func persistCurrentNow() {
        saveTask?.cancel()
        saveTask = nil
        guard let bill = currentBill else { return }
        let store = library
        Task.detached { try? store.saveBill(bill) }
    }

    private func saveBillNow(_ bill: Bill) {
        let store = library
        Task.detached { try? store.saveBill(bill) }
    }

    private func saveRosterNow() {
        let snapshot = LibraryStore.RosterSnapshot(people: roster, meID: meID)
        let store = library
        Task.detached { try? store.saveRoster(snapshot) }
    }
}
