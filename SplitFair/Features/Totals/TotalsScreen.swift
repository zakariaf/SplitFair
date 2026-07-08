import BillCore
import SwiftUI

/// Screen 2 — "Tax, Tip & Totals". The settle-up screen: enter tax and tip, read each person's fair
/// total, watch it reconcile, round up, then copy or clear. Composes the design-system components
/// over the shared store.
struct TotalsScreen: View {
    @Environment(BillStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topLeading) {
            BillBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    // Task 7.2 — tax & tip controls
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
}
