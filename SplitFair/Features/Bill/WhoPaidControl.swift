import BillCore
import SwiftUI

/// The "Who paid?" strip on the Bill screen: the participants as single-select chips, where the
/// payer is marked by fill **and** a "PAID" tag (never colour alone — non-negotiable #4). Recording
/// the payer is what lets the library compute running balances; it never affects this bill's split.
struct WhoPaidControl: View {
    let people: [Person]
    let payerID: Person.ID?
    let onSelect: (Person.ID?) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("WHO PAID?")
                .font(.caption.weight(.heavy)).tracking(1.2)
                .foregroundStyle(Color.inkSoft)
            if payerID == nil {
                Text("Tap who fronted the bill to track balances")
                    .font(.caption).foregroundStyle(Color.inkSoft)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(people) { person in
                        chip(for: person)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func chip(for person: Person) -> some View {
        let isPayer = person.id == payerID
        return VStack(spacing: 5) {
            DinerChip(
                diner: DinerPalette.style(for: person.colorIndex),
                initials: initials(person),
                assigned: isPayer,
                showsShadow: isPayer
            )
            Text(isPayer ? "PAID" : "tap")
                .font(.caption2.weight(.black)).tracking(0.5)
                .foregroundStyle(isPayer ? Color.ink : Color.inkSoft)
                .opacity(isPayer ? 1 : 0.55)
        }
        .contentShape(Rectangle())
        .onTapGesture { onSelect(isPayer ? nil : person.id) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(isPayer ? "\(person.name), paid the bill" : person.name))
        .accessibilityHint(Text(isPayer ? "Double tap to clear the payer" : "Double tap to mark as who paid"))
    }

    private func initials(_ person: Person) -> String {
        let trimmed = person.name.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "?" : String(trimmed.prefix(2))
    }
}
