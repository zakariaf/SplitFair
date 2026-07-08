import BillCore
import SwiftUI

/// The sticky roster: a horizontal-scroll bar of diner stickers with an inline "add person" field at
/// the end. Pressing return adds the name and keeps focus so you can rattle off "Sam, Alex, Jo"; a
/// blank name becomes "Person N". Tap a sticker to rename that diner; long-press to remove them.
struct DinerBar: View {
    @Environment(BillStore.self) private var store
    @State private var draft = ""
    @State private var editing: Person?
    @State private var editName = ""
    @FocusState private var focused: Bool

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(store.bill.people) { person in
                    DinerChip(diner: DinerPalette.style(for: person.colorIndex), initials: initials(person))
                        .transition(.scale(scale: 0.6).combined(with: .opacity))
                        .onTapGesture { startRename(person) }
                        .accessibilityLabel(Text(person.name))
                        .accessibilityHint(Text("Double tap to rename"))
                        .accessibilityActions {
                            Button("Rename") { startRename(person) }
                            Button("Remove \(person.name)", role: .destructive) { store.deletePerson(person.id) }
                        }
                        .contextMenu {
                            Button {
                                startRename(person)
                            } label: {
                                Label("Rename \(person.name)", systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                store.deletePerson(person.id)
                            } label: {
                                Label("Remove \(person.name)", systemImage: "trash")
                            }
                        }
                }
                ForEach(availableFriends) { friend in
                    DinerChip(diner: DinerPalette.style(for: friend.colorIndex), initials: initials(friend), assigned: false, showsShadow: false)
                        .onTapGesture { store.addParticipant(friend.id) }
                        .accessibilityLabel(Text("Add \(friend.name)"))
                        .accessibilityHint(Text("Double tap to add to this bill"))
                }
                addField
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .animation(.spring(response: 0.35, dampingFraction: 0.6), value: store.bill.people.count)
        }
        .alert("Rename diner", isPresented: renameShown) {
            TextField("Name", text: $editName)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
            Button("Save") { commitRename() }
            Button("Cancel", role: .cancel) {}
        }
    }

    /// Persistent friends not yet on this bill — tap to add them (reuses their stable identity, so
    /// balances accumulate across bills). Empty on the first-ever bill.
    private var availableFriends: [Person] {
        store.roster.filter { friend in !store.bill.people.contains { $0.id == friend.id } }
    }

    private var renameShown: Binding<Bool> {
        Binding(get: { editing != nil }, set: { if !$0 { editing = nil } })
    }

    private func startRename(_ person: Person) {
        editName = person.name
        editing = person
    }

    private func commitRename() {
        if let person = editing { store.renamePerson(person.id, to: editName) }
        editing = nil
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
