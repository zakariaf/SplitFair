import BillCore
import SwiftUI

/// The sticky roster: a horizontal-scroll bar of diner stickers with an inline "add person" field at
/// the end. Pressing return adds the name and keeps focus so you can rattle off "Sam, Alex, Jo"; a
/// blank name becomes "Person N". Long-press a sticker to remove that diner.
struct DinerBar: View {
    @Environment(BillStore.self) private var store
    @State private var draft = ""
    @FocusState private var focused: Bool

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(store.bill.people) { person in
                    DinerChip(diner: DinerPalette.style(for: person.colorIndex), initials: initials(person))
                        .contextMenu {
                            Button(role: .destructive) {
                                store.deletePerson(person.id)
                            } label: {
                                Label("Remove \(person.name)", systemImage: "trash")
                            }
                        }
                }
                addField
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private var addField: some View {
        HStack(spacing: 6) {
            TextField("Add", text: $draft)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.next)
                .focused($focused)
                .onSubmit(add)
                .font(.personName)
                .foregroundStyle(Color.ink)
                .frame(width: 78)
            Button(action: add) {
                Image(systemName: "plus.circle.fill").font(.title3)
            }
            .foregroundStyle(Color.tangerine)
        }
        .padding(.horizontal, 12)
        .frame(height: 44)
        .overlay(Capsule().strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5, 4])).foregroundStyle(Color.inkSoft))
    }

    private func add() {
        store.addPerson(named: draft) // blank -> "Person N"
        draft = ""
        focused = true // keep focus to chain the next name
    }

    private func initials(_ person: Person) -> String {
        let trimmed = person.name.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "?" : String(trimmed.prefix(2))
    }
}
