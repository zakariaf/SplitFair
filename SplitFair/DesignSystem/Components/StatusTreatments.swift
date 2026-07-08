import SwiftUI

/// The sticky footer rail — the app's ONE glass element, with a torn perforated top. The live
/// subtotal odometer rides on an opaque cream pill so no digit ever composites over glass. Under
/// Reduce Transparency the rail becomes opaque cream. The trailing slot holds the primary CTA.
struct FooterRail<Trailing: View>: View {
    let title: String
    let amount: String
    var unassignedCount: Int = 0
    @ViewBuilder let trailing: () -> Trailing
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    private var shape: PerforationEdge { PerforationEdge(toothWidth: 22, toothRadius: 6) }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title.uppercased())
                    .font(.caption.weight(.heavy)).tracking(1.2)
                    .foregroundStyle(Color.inkSoft)
                Text(amount)
                    .font(.money(26)).foregroundStyle(Color.ink)
                    .contentTransition(.numericText())
                    .lineLimit(1).minimumScaleFactor(0.6)
                    .padding(.horizontal, 9).padding(.vertical, 2)
                    .background(Capsule().fill(Color.canvas)) // opaque: no digit over glass
                if unassignedCount > 0 {
                    Label("\(unassignedCount) item\(unassignedCount == 1 ? "" : "s") unassigned",
                          systemImage: "exclamationmark.triangle.fill")
                        .font(.caption2.weight(.bold)).foregroundStyle(Color.warning)
                }
            }
            Spacer(minLength: 8)
            trailing()
        }
        .padding(.horizontal, 16).padding(.top, 16).padding(.bottom, 14)
        .background {
            if reduceTransparency { shape.fill(Color.canvas) } else { shape.fill(.regularMaterial) }
        }
        .overlay(shape.stroke(Color.keyline, lineWidth: 2))
        .hardShadow(RoundedRectangle(cornerRadius: 24))
    }
}

/// First-run hero: "WHO'S SPLITTING?" over a ghost sticker. The screen supplies the auto-focused
/// name field beneath it.
struct WhoSplittingHero: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("WHO'S\nSPLITTING?")
                .font(.hero).multilineTextAlignment(.center)
                .foregroundStyle(Color.ink)
            Text("＋")
                .font(.system(size: 22, weight: .bold)).foregroundStyle(Color.inkSoft)
                .frame(width: 64, height: 46)
                .overlay(Capsule().strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5, 4])).foregroundStyle(Color.inkSoft))
        }
    }
}

/// The dashed "+ Add item" card shown when there are diners but no items yet.
struct AddItemCard: View {
    var label: String = "Add item"
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(label, systemImage: "plus")
                .font(.money(15)).foregroundStyle(Color.inkSoft)
                .frame(maxWidth: .infinity).padding(.vertical, 16)
                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                    .foregroundStyle(Color.inkSoft))
        }
        .buttonStyle(.plain)
    }
}
