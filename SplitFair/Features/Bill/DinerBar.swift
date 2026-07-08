import BillCore
import SwiftUI

/// The sticky roster: a horizontal-scroll bar of diner stickers with an add control at the end.
/// (Task 6.2 replaces the tap-to-add with an inline name field + Enter-to-chain.)
struct DinerBar: View {
    @Environment(BillStore.self) private var store

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(store.bill.people) { person in
                    DinerChip(diner: DinerPalette.style(for: person.colorIndex), initials: initials(person))
                }
                Button { store.addPerson(named: "") } label: { AddDinerChip() }
                    .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private func initials(_ person: Person) -> String {
        let trimmed = person.name.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "?" : String(trimmed.prefix(2))
    }
}
