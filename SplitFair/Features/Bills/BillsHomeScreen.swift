import BillCore
import SwiftUI

/// Screen 0 — "Bills". The app's front door and the reason to reopen it: the running balances
/// summary (added in Task 10.8) over a library of saved bills. Each bill is a HARD COPY receipt
/// card — title, date, ink-on-paper grand total, and the diners who were there. Tap to open, "+"
/// to start a new one, long-press to duplicate / rename / delete.
struct BillsHomeScreen: View {
    @Environment(BillStore.self) private var store
    @State private var openBillActive = false
    @State private var renaming: Bill?
    @State private var renameText = ""
    @State private var pendingDelete: Bill?

    var body: some View {
        ZStack {
            BillBackground()
            if store.bills.isEmpty {
                emptyState
            } else {
                library
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $openBillActive) { BillScreen() }
        .alert("Rename bill", isPresented: renamingShown) {
            TextField("Title", text: $renameText)
                .textInputAutocapitalization(.words)
            Button("Save") { commitRename() }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog(
            "Delete this bill?",
            isPresented: deleteShown,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let bill = pendingDelete { store.deleteBill(bill.id) }
                pendingDelete = nil
            }
            Button("Cancel", role: .cancel) { pendingDelete = nil }
        } message: {
            Text("This can't be undone.")
        }
    }

    // MARK: - Library

    private var library: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                BalancesSummary()            // renders only once "you" is set and balances exist (Task 10.8)
                newBillButton
                ForEach(store.bills) { bill in
                    billCard(bill)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.94).combined(with: .opacity),
                            removal: .opacity
                        ))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.82), value: store.bills.count)
            .padding(.horizontal, 20)
            .padding(.top, 64)
            .padding(.bottom, 40)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("YOUR LIBRARY")
                .font(.caption.weight(.heavy)).tracking(1.4)
                .foregroundStyle(Color.inkSoft)
            Text("Bills")
                .font(.sectionTitle).foregroundStyle(Color.ink)
        }
    }

    private var newBillButton: some View {
        PrimaryButton(title: "New bill", systemImage: "plus") { startNewBill() }
    }

    private func billCard(_ bill: Bill) -> some View {
        let total = BillMath.compute(bill).grandTotal
        return Button { open(bill) } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(displayTitle(bill))
                            .font(.personName).foregroundStyle(Color.ink)
                        Text(bill.createdAt.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption).foregroundStyle(Color.inkSoft)
                    }
                    Spacer(minLength: 8)
                    Text(MoneyDisplay.full(total, bill.currency))
                        .font(.money(24)).foregroundStyle(Color.ink) // ink-on-paper, never tinted
                        .lineLimit(1).minimumScaleFactor(0.6)
                }
                if !bill.people.isEmpty { stickerStrip(bill.people) }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .card()
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button { store.duplicateBill(bill.id) } label: { Label("Duplicate", systemImage: "doc.on.doc") }
            Button { startRename(bill) } label: { Label("Rename", systemImage: "pencil") }
            Button(role: .destructive) { pendingDelete = bill } label: { Label("Delete", systemImage: "trash") }
        }
    }

    /// Up to five diner stickers, then a "+N" overflow.
    private func stickerStrip(_ people: [Person]) -> some View {
        let shown = people.prefix(5)
        let overflow = people.count - shown.count
        return HStack(spacing: 8) {
            ForEach(shown) { person in
                DinerChip(diner: DinerPalette.style(for: person.colorIndex), initials: initials(person), showsShadow: false)
                    .scaleEffect(0.82)
                    .frame(width: 40, height: 40)
            }
            if overflow > 0 {
                Text("+\(overflow)").font(.caption.weight(.bold)).foregroundStyle(Color.inkSoft)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 22) {
            VStack(spacing: 8) {
                Text("NO BILLS\nYET")
                    .font(.hero).multilineTextAlignment(.center)
                    .foregroundStyle(Color.ink)
                Text("Split a dinner, a grocery run, a trip — and keep the tab.")
                    .font(.personName).multilineTextAlignment(.center)
                    .foregroundStyle(Color.inkSoft)
                    .padding(.horizontal, 40)
            }
            newBillButton
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Actions

    private func startNewBill() {
        store.newBill()
        openBillActive = true
    }

    private func open(_ bill: Bill) {
        store.openBill(bill.id)
        openBillActive = true
    }

    private var renamingShown: Binding<Bool> {
        Binding(get: { renaming != nil }, set: { if !$0 { renaming = nil } })
    }

    private var deleteShown: Binding<Bool> {
        Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } })
    }

    private func startRename(_ bill: Bill) {
        renameText = bill.title
        renaming = bill
    }

    private func commitRename() {
        if let bill = renaming { store.renameBill(bill.id, to: renameText) }
        renaming = nil
    }

    private func displayTitle(_ bill: Bill) -> String {
        if !bill.title.isEmpty { return bill.title }
        if let label = bill.items.first(where: { !$0.label.isEmpty })?.label { return label }
        return "Untitled bill"
    }

    private func initials(_ person: Person) -> String {
        let trimmed = person.name.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "?" : String(trimmed.prefix(2))
    }
}
