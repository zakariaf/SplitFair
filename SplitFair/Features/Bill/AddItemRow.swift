import BillCore
import SwiftUI

/// The inline "add item" affordance: a dashed card that expands into a price + optional-label entry.
/// The price uses a decimal pad (no return key), so a keyboard "Done" toolbar commits it; the label
/// chains to the price with the keyboard's Next. Amounts are parsed via `MoneyEdge` (locale-aware,
/// strict) into integer cents.
struct AddItemRow: View {
    @Environment(BillStore.self) private var store
    @State private var expanded = false
    @State private var priceText = ""
    @State private var labelText = ""
    @FocusState private var field: Field?

    private enum Field { case label, price }

    var body: some View {
        if expanded {
            VStack(spacing: 12) {
                TextField("Label (optional)", text: $labelText)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.next)
                    .focused($field, equals: .label)
                    .onSubmit { field = .price }
                    .font(.personName).foregroundStyle(Color.ink)

                HStack {
                    Text("$").font(.ledger(18)).foregroundStyle(Color.inkSoft)
                    TextField("0.00", text: $priceText)
                        .keyboardType(.decimalPad)
                        .font(.ledger(20)).foregroundStyle(Color.ink)
                        .focused($field, equals: .price)
                }

                HStack(spacing: 12) {
                    SecondaryButton(title: "Cancel") { reset() }
                    Spacer()
                    PrimaryButton(title: "Add", enabled: parsedAmount != nil) { add() }
                }
            }
            .card()
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { add() }
                        .fontWeight(.bold)
                        .disabled(parsedAmount == nil)
                }
            }
            .onAppear { field = .price }
        } else {
            AddItemCard { expanded = true }
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
        field = nil
    }
}
