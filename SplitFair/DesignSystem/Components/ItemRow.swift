import BillCore
import SwiftUI

/// A line item: optional label + a ledger price wrapped in the split-ring, over a strip of diner
/// chips (tap to assign) and a "Shared by all" pill. The left edge is a thin ink rule, or amber
/// hazard-tape when the item is unassigned. Presentational — the screen passes the item, roster,
/// and callbacks.
struct ItemRow: View {
    let item: Item
    let people: [Person]
    var currency: Currency = .usd
    let onToggle: (Person.ID) -> Void
    let onSharedByAll: () -> Void

    private var assignees: [Person] { people.filter { item.assigneeIDs.contains($0.id) } }
    private var isUnassigned: Bool { assignees.isEmpty }
    private var allAssigned: Bool { !people.isEmpty && people.allSatisfy { item.assigneeIDs.contains($0.id) } }

    private let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.label.isEmpty ? "Item" : item.label)
                        .font(.personName)
                        .foregroundStyle(item.label.isEmpty ? Color.inkSoft : Color.ink)
                    if isUnassigned {
                        Label("tap a name", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption).foregroundStyle(Color.warning)
                    }
                }
                Spacer(minLength: 8)
                ZStack {
                    SplitRing(assignees: assignees.map { DinerPalette.style(for: $0.colorIndex) })
                    Text(MoneyDisplay.plain(item.amount, currency))
                        .font(.ledger(16))
                        .foregroundStyle(Color.ink)
                }
                .frame(width: 74, height: 74)
            }

            HStack(spacing: 8) {
                ForEach(people) { person in
                    let diner = DinerPalette.style(for: person.colorIndex)
                    DinerChip(diner: diner, initials: initials(person), assigned: item.assigneeIDs.contains(person.id), showsShadow: false)
                        .onTapGesture { onToggle(person.id) }
                }
                SharedByAllPill(active: allAssigned, action: onSharedByAll)
            }
        }
        .padding(16)
        .padding(.leading, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(alignment: .leading) {
            ZStack(alignment: .leading) {
                Color.surface
                Group {
                    if isUnassigned { HazardStripes() } else { Color.ink }
                }
                .frame(width: isUnassigned ? 14 : 5)
            }
        }
        .clipShape(shape)
        .overlay(shape.strokeBorder(Color.keyline, lineWidth: 2))
        .hardShadow(shape)
        .accessibilityElement(children: .combine)
    }

    private func initials(_ person: Person) -> String {
        let trimmed = person.name.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "?" : String(trimmed.prefix(2))
    }
}

/// One-tap "Shared by all" — cascade-assign the whole roster.
struct SharedByAllPill: View {
    let active: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text("Shared by all")
                .font(.caption.weight(.bold))
                .foregroundStyle(active ? Color.canvas : Color.ink)
                .padding(.horizontal, 13).frame(height: 34)
                .background(Capsule().fill(active ? AnyShapeStyle(Color.ink) : AnyShapeStyle(Color.clear)))
                .overlay(Capsule().strokeBorder(Color.keyline, style: StrokeStyle(lineWidth: 2, dash: active ? [] : [5, 4])))
        }
        .buttonStyle(.plain)
    }
}

/// Amber + ink diagonal hazard-tape, drawn with `Canvas`. Marks an unassigned item's edge — never
/// colour alone (it pairs with the ⚠ icon and "tap a name" text).
struct HazardStripes: View {
    var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color.warning))
            var x: CGFloat = -size.height
            while x < size.width {
                var stripe = Path()
                stripe.move(to: CGPoint(x: x, y: 0))
                stripe.addLine(to: CGPoint(x: x + size.height, y: size.height))
                stripe.addLine(to: CGPoint(x: x + size.height + 6, y: size.height))
                stripe.addLine(to: CGPoint(x: x + 6, y: 0))
                stripe.closeSubpath()
                context.fill(stripe, with: .color(Color.ink))
                x += 13
            }
        }
    }
}
