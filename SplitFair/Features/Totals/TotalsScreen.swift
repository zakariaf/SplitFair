import BillCore
import SwiftUI

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

    private let presets = [15, 18, 20, 25]

    var body: some View {
        ZStack(alignment: .topLeading) {
            BillBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    taxTip
                    // Task 7.3 — per-person total cards
                    // Task 7.4 — reconciliation banner
                    // Task 7.5 — round-up
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
