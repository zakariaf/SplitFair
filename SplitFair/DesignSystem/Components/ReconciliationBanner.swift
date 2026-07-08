import BillCore
import SwiftUI

/// The emotional climax: a perforated success-green check-stub with a rubber-stamp "SETTLED ✓" that
/// thunks in and a counting-up grand total proving the parts equal the whole. Re-fires when the
/// total changes (e.g. the tip). Flips to amber + ⚠ if it ever fails to reconcile (with correct
/// math it never does). Green here means ONLY "you're charged right".
struct ReconciliationBanner: View {
    let grandTotal: Money
    var reconciles: Bool = true
    var roundingNote: String?
    var currency: Currency = .usd

    @State private var appeared = false
    @State private var shownTotal = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let deepGreen = Color(rgb: 0x08_281A)
    private let deepAmber = Color(rgb: 0x3A_2A12)
    private var stub: PerforationEdge { PerforationEdge(toothWidth: 26, toothRadius: 7) }

    var body: some View {
        let accent = reconciles ? Color.success : Color.warning
        let deep = reconciles ? deepGreen : deepAmber

        return HStack(spacing: 14) {
            Image(systemName: reconciles ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 44))
                .foregroundStyle(deep)
                .rotationEffect(.degrees(-9))
                .scaleEffect(appeared ? 1 : 1.5)
                .opacity(appeared ? 1 : 0)

            VStack(alignment: .leading, spacing: 3) {
                Text(reconciles ? "Totals add up to" : "Totals don't reconcile")
                    .font(.display(15))
                    .foregroundStyle(deep)
                HStack(alignment: .firstTextBaseline, spacing: 9) {
                    Text(MoneyDisplay.full(Money(shownTotal), currency))
                        .font(.money(28)).foregroundStyle(deep)
                        .contentTransition(.numericText())
                    Text(reconciles ? "SETTLED" : "CHECK")
                        .font(.bodyText(12).weight(.black)).tracking(1.2)
                        .foregroundStyle(accent)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(deep, in: RoundedRectangle(cornerRadius: 6))
                }
                if let roundingNote {
                    Text("rounding balanced · \(roundingNote)")
                        .font(.ledgerLine)
                        .foregroundStyle(deep.opacity(0.8))
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18).padding(.top, 22).padding(.bottom, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(accent)
        .clipShape(stub)
        .overlay(stub.stroke(deep, lineWidth: 2))
        .onAppear(perform: reveal)
        .onChange(of: grandTotal) { _, newValue in refire(to: newValue) }
        .sensoryFeedback(.success, trigger: appeared)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(reconciles
            ? "Totals add up, settled, \(MoneyDisplay.full(grandTotal, currency))"
            : "Totals do not reconcile"))
    }

    private func reveal() {
        guard !appeared else { return }
        if reconciles {
            AccessibilityNotification.Announcement("Totals add up, settled").post()
        }
        guard !reduceMotion else {
            shownTotal = grandTotal.minorUnits
            appeared = true
            return
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) { appeared = true }
        withAnimation(.easeOut(duration: 0.5).delay(0.05)) { shownTotal = grandTotal.minorUnits }
    }

    private func refire(to newValue: Money) {
        guard !reduceMotion else { shownTotal = newValue.minorUnits; return }
        withAnimation(.easeOut(duration: 0.4)) { shownTotal = newValue.minorUnits }
        appeared = false
        withAnimation(.spring(response: 0.45, dampingFraction: 0.5)) { appeared = true }
    }
}

#Preview("Reconciliation") {
    VStack(spacing: 20) {
        ReconciliationBanner(grandTotal: Money(9720), roundingNote: "+$0.02 → tip")
        ReconciliationBanner(grandTotal: Money(9720), reconciles: false)
    }
    .padding()
    .background(Color.canvas)
}
