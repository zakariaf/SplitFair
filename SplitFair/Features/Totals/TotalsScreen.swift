import BillCore
import SwiftUI
import UIKit

/// Screen 2 — "Tax, Tip & Totals". The settle-up screen: enter tax and tip, read each person's fair
/// total, watch it reconcile, round up, then copy or clear. Composes the design-system components
/// over the shared store.
struct TotalsScreen: View {
    @Environment(BillStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var taxText = ""
    @State private var tipBase: TipBase = .preTax
    @State private var showCustomTip = false
    @State private var customTipText = ""
    @State private var expandedIDs: Set<UUID> = []
    @State private var roundUp = false
    @State private var showClearConfirm = false
    @State private var showCopied = false

    private let presets = [15, 18, 20, 25]

    var body: some View {
        ZStack(alignment: .topLeading) {
            BillBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    taxTip
                    totalsCards
                    ReconciliationBanner(
                        grandTotal: store.totals.grandTotal,
                        reconciles: true,
                        roundingNote: roundUpSurplus,
                        currency: store.bill.currency
                    )
                    roundUpRow
                    actions
                }
                .padding(.horizontal, 16)
                .padding(.top, 64)
                .padding(.bottom, 120)
            }

            backButton
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            taxText = store.bill.tax == .zero ? "" : MoneyDisplay.plain(store.bill.tax, store.bill.currency)
        }
        .onChange(of: taxText) { _, newValue in syncTax(newValue) }
        .alert("Custom tip %", isPresented: $showCustomTip) {
            TextField("20", text: $customTipText).keyboardType(.numberPad)
            Button("Set") {
                if let percent = Int(customTipText), (0 ..< 1000).contains(percent) {
                    store.setTip(.percent(percent))
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("THE PAYOFF")
                .font(.caption.weight(.heavy)).tracking(1.4)
                .foregroundStyle(Color.inkSoft)
            Text("Tax, Tip & Totals")
                .font(.sectionTitle).foregroundStyle(Color.ink)
        }
    }

    private var taxTip: some View {
        TaxTipControls(
            taxText: $taxText,
            base: $tipBase,
            selectedPercent: selectedPercent,
            liveTip: MoneyDisplay.full(BillMath.resolvedTip(store.bill), store.bill.currency),
            presets: presets,
            onPreset: { store.setTip(.percent($0)) },
            onCustom: { customTipText = ""; showCustomTip = true }
        )
    }

    private var selectedPercent: Int? {
        if case let .percent(percent) = store.bill.tip, presets.contains(percent) { return percent }
        return nil
    }

    private var totalsCards: some View {
        VStack(alignment: .leading, spacing: 13) {
            Text("What each person owes")
                .font(.display(15)).foregroundStyle(Color.inkSoft)
            ForEach(orderedPeople) { person in
                PersonTotalCard(
                    name: person.name,
                    diner: DinerPalette.style(for: person.colorIndex),
                    initials: initials(person),
                    breakdown: store.totals.perPerson[person.id] ?? .zero,
                    lines: lines(for: person),
                    currency: store.bill.currency,
                    roundedTotal: roundedTotal(for: person),
                    expanded: expandBinding(person.id)
                )
            }
        }
    }

    /// Bento order — the biggest ower sits first.
    private var orderedPeople: [Person] {
        store.bill.people.sorted {
            total(for: $0) > total(for: $1)
        }
    }

    private func total(for person: Person) -> Int {
        store.totals.perPerson[person.id]?.total.minorUnits ?? 0
    }

    /// A person's item shares, computed with the same `allocate` primitive as the totals.
    private func lines(for person: Person) -> [PersonLedgerLine] {
        store.bill.items.compactMap { item in
            let assignees = store.bill.people.filter { item.assigneeIDs.contains($0.id) }
            guard let index = assignees.firstIndex(where: { $0.id == person.id }) else { return nil }
            let shares = allocate(amountCents: item.amount.minorUnits, weights: Array(repeating: 1, count: assignees.count))
            return PersonLedgerLine(
                label: item.label.isEmpty ? "Item" : item.label,
                amount: Money(shares[index]),
                sharedWays: assignees.count
            )
        }
    }

    private func expandBinding(_ id: UUID) -> Binding<Bool> {
        Binding(
            get: { expandedIDs.contains(id) },
            set: { isOn in
                if isOn { expandedIDs.insert(id) } else { expandedIDs.remove(id) }
            }
        )
    }

    private func initials(_ person: Person) -> String {
        let trimmed = person.name.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "?" : String(trimmed.prefix(2))
    }

    private var roundUpRow: some View {
        HStack(spacing: 12) {
            Toggle("", isOn: $roundUp).labelsHidden().tint(Color.success)
            VStack(alignment: .leading, spacing: 2) {
                Text("Round each person up to $1")
                    .font(.personName).foregroundStyle(Color.ink)
                if let surplus = roundUpSurplus {
                    Text("Adds \(surplus)").font(.caption).foregroundStyle(Color.inkSoft)
                }
            }
            Spacer()
        }
        .padding(4)
        .sensoryFeedback(.impact(weight: .light), trigger: roundUp)
    }

    /// The (higher) amount actually paid when round-up is on — nearest dollar up. Display only.
    private func roundedTotal(for person: Person) -> Money? {
        guard roundUp else { return nil }
        let cents = total(for: person)
        return Money(cents <= 0 ? cents : ((cents + 99) / 100) * 100)
    }

    /// The honest surplus that round-up adds across the table, "+$X → tip".
    private var roundUpSurplus: String? {
        guard roundUp else { return nil }
        let surplus = store.bill.people.reduce(0) { accumulated, person in
            let cents = total(for: person)
            let rounded = cents <= 0 ? cents : ((cents + 99) / 100) * 100
            return accumulated + (rounded - cents)
        }
        return surplus > 0 ? "+\(MoneyDisplay.full(Money(surplus), store.bill.currency)) → tip" : nil
    }

    private var actions: some View {
        HStack(spacing: 12) {
            SecondaryButton(
                title: showCopied ? "Copied ✓" : "Copy summary",
                systemImage: showCopied ? "checkmark" : "doc.on.doc"
            ) { copySummary() }

            ShareLink(item: Summary.text(for: store.bill)) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .bold)).foregroundStyle(Color.ink)
                    .frame(width: 46, height: 46)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.surface))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color.keyline, lineWidth: 2))
                    .hardShadow(RoundedRectangle(cornerRadius: 16, style: .continuous), dx: 2, dy: 3)
            }

            Spacer()
            DangerButton(title: "Clear bill") { showClearConfirm = true }
        }
        .confirmationDialog("Clear this bill?", isPresented: $showClearConfirm, titleVisibility: .visible) {
            Button("Clear bill", role: .destructive) {
                store.clear()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This can't be undone.")
        }
    }

    private func copySummary() {
        UIPasteboard.general.string = Summary.text(for: store.bill)
        withAnimation { showCopied = true }
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            withAnimation { showCopied = false }
        }
    }

    private var backButton: some View {
        Button { dismiss() } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 18, weight: .bold)).foregroundStyle(Color.ink)
                .frame(width: 42, height: 42)
                .background(Circle().fill(Color.surface))
                .overlay(Circle().strokeBorder(Color.keyline, lineWidth: 2))
                .hardShadow(Circle(), dx: 2, dy: 3)
        }
        .padding(.leading, 16)
        .padding(.top, 8)
    }

    private func syncTax(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            store.setTax(.zero)
        } else if let amount = MoneyEdge.parse(trimmed, currency: store.bill.currency) {
            store.setTax(amount)
        }
    }
}
