import BillCore
import SwiftUI

/// Screen 2 — "Tax, Tip & Totals". Stub until EPIC 07: shows the grand total so the Next navigation
/// from Screen 1 is exercisable.
struct TotalsScreen: View {
    @Environment(BillStore.self) private var store

    var body: some View {
        ZStack {
            BillBackground()
            VStack(spacing: 8) {
                Text("Tax, Tip & Totals").font(.sectionTitle).foregroundStyle(Color.ink)
                Text(MoneyDisplay.full(store.totals.grandTotal, store.bill.currency))
                    .font(.heroSubtotal).foregroundStyle(Color.ink)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}
