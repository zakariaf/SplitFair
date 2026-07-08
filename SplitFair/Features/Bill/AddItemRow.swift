import BillCore
import SwiftUI

/// The inline "add item" affordance: a dashed card that expands into a price + optional-label entry.
/// (Task 6.4 refines the input ergonomics — cents-accumulator, keyboard Done toolbar, auto-label.)
struct AddItemRow: View {
    @Environment(BillStore.self) private var store
    @State private var expanded = false
    @State private var priceText = ""
    @State private var labelText = ""
    @FocusState private var priceFocused: Bool

    var body: some View {
        if expanded {
            VStack(spacing: 12) {
                TextField("Label (optional)", text: $labelText)
                    .textInputAutocapitalization(.words)
                    .font(.personName).foregroundStyle(Color.ink)
                HStack {
                    Text("$").font(.ledger(18)).foregroundStyle(Color.inkSoft)
                    TextField("0.00", text: $priceText)
                        .keyboardType(.decimalPad)
                        .font(.ledger(20)).foregroundStyle(Color.ink)
                        .focused($priceFocused)
                }
                HStack(spacing: 12) {
                    SecondaryButton(title: "Cancel") { reset() }
                    Spacer()
                    PrimaryButton(title: "Add", enabled: parsedAmount != nil) { add() }
                }
            }
            .card()
        } else {
            AddItemCard {
                expanded = true
                priceFocused = true
            }
        }
    }

    private var parsedAmount: Money? {
        MoneyEdge.parse(priceText, currency: store.bill.currency)
    }

    private func add() {
        guard let amount = parsedAmount else { return }
        store.addItem(amount: amount, label: labelText.trimmingCharacters(in: .whitespaces))
        reset()
    }

    private func reset() {
        expanded = false
        priceText = ""
        labelText = ""
    }
}
