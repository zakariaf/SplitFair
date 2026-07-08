import BillCore
import SwiftUI

/// Which subtotal the tip percentage applies to. The model computes on the pre-tax subtotal today;
/// `total` is surfaced for when a `tipBase` field is added to Bill/BillMath.
enum TipBase: String, CaseIterable {
    case preTax = "pre-tax"
    case total
}

/// Screen 2's tax + tip entry: a tax field, the preset chips, the live Acid-Lime tip readout (the
/// one lime element, always ink text), and the base toggle. Presentational — the screen owns the
/// state and parses `taxText` via `MoneyEdge`.
struct TaxTipControls: View {
    @Binding var taxText: String
    @Binding var base: TipBase
    /// The highlighted preset, or nil for a custom/fixed tip.
    let selectedPercent: Int?
    /// The resolved tip amount, pre-formatted (e.g. "$15.10").
    let liveTip: String
    var presets: [Int] = [15, 18, 20, 25]
    let onPreset: (Int) -> Void
    let onCustom: () -> Void

    private let limeInk = Color(rgb: 0x1A_1613) // fixed dark; lime is bright in both modes

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("TAX").font(.caption.weight(.heavy)).tracking(1.2).foregroundStyle(Color.inkSoft)
                Spacer()
                Text("$").font(.ledger(18)).foregroundStyle(Color.inkSoft)
                TextField("0.00", text: $taxText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .font(.ledger(20))
                    .foregroundStyle(Color.ink)
                    .frame(maxWidth: 120)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 18).fill(Color.surface))
            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color.keyline, lineWidth: 2))
            .hardShadow(RoundedRectangle(cornerRadius: 18))

            HStack {
                Text("TIP").font(.caption.weight(.heavy)).tracking(1.2).foregroundStyle(Color.inkSoft)
                Spacer()
                Picker("Tip base", selection: $base) {
                    ForEach(TipBase.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .frame(width: 170)
            }

            HStack(spacing: 9) {
                ForEach(presets, id: \.self) { percent in
                    TipChip(title: "\(percent)%", selected: selectedPercent == percent) { onPreset(percent) }
                }
                TipChip(title: "•••", selected: selectedPercent == nil, action: onCustom)
                Spacer(minLength: 0)
            }

            HStack {
                Spacer()
                Text("= \(liveTip)")
                    .font(.money(19)).foregroundStyle(limeInk)
                    .padding(.horizontal, 13).padding(.vertical, 8)
                    .background(Capsule().fill(Color.acidLime))
                    .overlay(Capsule().strokeBorder(Color.keyline, lineWidth: 2))
                    .hardShadow(Capsule(), dx: 2, dy: 3)
                    .contentTransition(.numericText())
            }
        }
    }
}

/// A clay-pressable tip preset stamp — Tangerine fill + white label when selected.
struct TipChip: View {
    let title: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.money(15))
                .foregroundStyle(selected ? Color.white : Color.ink)
                .frame(minWidth: 48)
                .padding(.vertical, 11).padding(.horizontal, 12)
                .background(RoundedRectangle(cornerRadius: 15).fill(selected ? AnyShapeStyle(Color.tangerine) : AnyShapeStyle(Color.surface)))
                .overlay(RoundedRectangle(cornerRadius: 15).strokeBorder(Color.keyline, lineWidth: 2))
                .hardShadow(RoundedRectangle(cornerRadius: 15), dx: 2, dy: 3)
        }
        .buttonStyle(.plain)
    }
}
