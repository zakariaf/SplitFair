import BillCore
import SwiftUI

/// The running who-owes-whom summary at the top of the Bills home screen — the payoff of the whole
/// library. Amounts are ink-on-paper; direction ("owes you" / "you owe") is carried by words and an
/// arrow, **never** by red/green (non-negotiable #4). Until "you" is set, it shows a one-time picker.
struct BalancesSummary: View {
    @Environment(BillStore.self) private var store

    var body: some View {
        if store.meID == nil {
            if !store.roster.isEmpty { youPicker }
        } else {
            balancesCard
        }
    }

    // MARK: - Balances

    /// Non-zero balances joined to their roster person, biggest magnitude first.
    private var rows: [(person: Person, cents: Int)] {
        store.balances
            .compactMap { id, money -> (Person, Int)? in
                guard let person = store.roster.first(where: { $0.id == id }) else { return nil }
                return (person, money.minorUnits)
            }
            .sorted { abs($0.1) > abs($1.1) }
    }

    private var currency: Currency { store.bills.first?.currency ?? .usd }

    private var balancesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("BALANCES")
                .font(.caption.weight(.heavy)).tracking(1.4)
                .foregroundStyle(Color.inkSoft)
            if rows.isEmpty {
                Label("You're all square", systemImage: "checkmark.seal.fill")
                    .font(.personName).foregroundStyle(Color.ink)
            } else {
                ForEach(rows, id: \.person.id) { row in
                    balanceRow(person: row.person, cents: row.cents)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    private func balanceRow(person: Person, cents: Int) -> some View {
        let owesYou = cents > 0
        let amount = MoneyDisplay.full(Money(abs(cents)), currency)
        return HStack(spacing: 12) {
            DinerChip(diner: DinerPalette.style(for: person.colorIndex), initials: initials(person), showsShadow: false)
                .scaleEffect(0.82)
                .frame(width: 40, height: 40)
            VStack(alignment: .leading, spacing: 1) {
                Text(person.name).font(.personName).foregroundStyle(Color.ink)
                Label(owesYou ? "owes you" : "you owe", systemImage: owesYou ? "arrow.down.left" : "arrow.up.right")
                    .font(.caption.weight(.bold)).foregroundStyle(Color.inkSoft)
            }
            Spacer(minLength: 8)
            Text(amount)
                .font(.money(20)).foregroundStyle(Color.ink) // ink-on-paper, never red/green
                .lineLimit(1).minimumScaleFactor(0.6)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(owesYou ? "\(person.name) owes you \(amount)" : "You owe \(person.name) \(amount)"))
    }

    // MARK: - "Which one is you?"

    private var youPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("WHICH ONE IS YOU?")
                .font(.caption.weight(.heavy)).tracking(1.4)
                .foregroundStyle(Color.inkSoft)
            Text("Tap your sticker to start tracking balances")
                .font(.caption).foregroundStyle(Color.inkSoft)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(store.roster) { person in
                        VStack(spacing: 4) {
                            DinerChip(diner: DinerPalette.style(for: person.colorIndex), initials: initials(person))
                            Text(person.name).font(.caption2).foregroundStyle(Color.inkSoft).lineLimit(1)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { store.setMe(person.id) }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(Text(person.name))
                        .accessibilityHint(Text("Double tap if this is you"))
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    private func initials(_ person: Person) -> String {
        let trimmed = person.name.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "?" : String(trimmed.prefix(2))
    }
}
