import BillCore
import SwiftUI

/// One line in a person's expanded ledger (an item share, or prorated tax/tip).
struct PersonLedgerLine: Identifiable {
    let id = UUID()
    let label: String
    let amount: Money
    let sharedWays: Int

    init(label: String, amount: Money, sharedWays: Int = 1) {
        self.label = label
        self.amount = amount
        self.sharedWays = sharedWays
    }
}

/// A per-person total card: the person's sticker + name + big INK total, tappable to expand into a
/// receipt-style ledger (their items + prorated tax/tip), each line faintly tinted in the diner's
/// hue. Presentational — the screen provides the breakdown and lines (bento order).
struct PersonTotalCard: View {
    let name: String
    let diner: DinerStyle
    let initials: String
    let breakdown: Breakdown
    let lines: [PersonLedgerLine]
    var currency: Currency = .usd
    @Binding var expanded: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: expanded ? 12 : 0) {
            HStack(spacing: 13) {
                DinerChip(diner: diner, initials: initials)
                Text(name).font(.personName).foregroundStyle(Color.ink)
                Spacer(minLength: 8)
                Text(MoneyDisplay.full(breakdown.total, currency))
                    .font(.personTotal).foregroundStyle(Color.ink) // ink, never colored
                Image(systemName: "chevron.down")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.inkSoft)
                    .rotationEffect(.degrees(expanded ? 180 : 0))
            }

            if expanded {
                VStack(spacing: 4) {
                    ForEach(lines) { line in
                        let label = line.label + (line.sharedWays > 1 ? "  ·split \(line.sharedWays)" : "")
                        ledgerRow(label, MoneyDisplay.plain(line.amount, currency), tint: diner.color)
                    }
                    ledgerRow("Tax", MoneyDisplay.plain(breakdown.tax, currency), meta: true)
                    ledgerRow("Tip", MoneyDisplay.plain(breakdown.tip, currency), meta: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) { expanded.toggle() }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(name) owes \(MoneyDisplay.full(breakdown.total, currency))"))
        .accessibilityHint(Text("Double-tap to see the breakdown"))
    }

    private func ledgerRow(_ label: String, _ amount: String, tint: Color = .clear, meta: Bool = false) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(amount)
        }
        .font(.ledgerLine)
        .foregroundStyle(meta ? Color.inkSoft : Color.ink)
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(meta ? AnyShapeStyle(Color.clear) : AnyShapeStyle(tint.opacity(0.08)), in: RoundedRectangle(cornerRadius: 6))
    }
}
