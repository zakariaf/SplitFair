import BillCore
import Foundation
import Observation

/// The single source of truth for the app. One `@MainActor @Observable` store owns the current
/// `Bill`; both screens read it and mutate it only through intent methods. Totals are a COMPUTED
/// property, so they recompute live (no "Calculate" button) and can never drift from a stored copy.
@MainActor @Observable
final class BillStore {
    private(set) var bill: Bill

    /// Derived on read — never stored. Reconciliation is guaranteed by `BillMath` (see BillCore).
    var totals: BillResult { BillMath.compute(bill) }

    init(bill: Bill = .empty) {
        self.bill = bill
    }

    // MARK: - People

    func addPerson(named name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let colorIndex = bill.people.count
        let displayName = trimmed.isEmpty ? "Person \(colorIndex + 1)" : trimmed
        bill.people.append(Person(name: displayName, colorIndex: colorIndex))
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

    // MARK: - Reset

    func clear() {
        bill = .empty
    }
}
