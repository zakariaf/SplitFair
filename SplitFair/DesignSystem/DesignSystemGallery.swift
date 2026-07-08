import SwiftUI

/// A visual gallery of the HARD COPY design system — colour tokens, type scale, diner chips, and
/// depth. Used for #Preview and manual QA; not part of the shipping flow.
struct DesignSystemGallery: View {
    private let swatches: [(String, Color)] = [
        ("Canvas", .canvas), ("Surface", .surface), ("Ink", .ink),
        ("Tangerine", .tangerine), ("Lime", .acidLime),
        ("Success", .success), ("Warning", .warning), ("Danger", .danger),
    ]

    var body: some View {
        ZStack {
            Color.canvas.ignoresSafeArea()
            DotMatrixBackground().ignoresSafeArea()
            DriftingBlobs().ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    Text("HARD COPY").font(.sectionTitle).foregroundStyle(Color.ink)

                    section("Type") {
                        Text("$97.20").font(.heroSubtotal).foregroundStyle(Color.ink)
                        Text("Who's splitting?").font(.hero).foregroundStyle(Color.ink)
                        Text("28.00").font(.itemPrice).foregroundStyle(Color.ink)
                        Text("Split by who ordered what.").font(.personName).foregroundStyle(Color.inkSoft)
                    }

                    section("Colour") {
                        FlowChips(swatches: swatches)
                    }

                    section("Diner stickers") {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 58), spacing: 14)], spacing: 16) {
                            ForEach(DinerPalette.all) { diner in
                                Text(String(diner.name.prefix(2)))
                                    .font(.chipInitials)
                                    .foregroundStyle(diner.labelInk)
                                    .frame(minWidth: 44, minHeight: 44)
                                    .sticker(diner.color)
                                    .notchMarks(diner.notches)
                            }
                        }
                    }

                    section("Depth") {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Nachos").font(.personName).foregroundStyle(Color.ink)
                            Text("10.00").font(.itemPrice).foregroundStyle(Color.ink)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .card()

                        HStack {
                            Text("Subtotal $75.50").font(.money(20)).foregroundStyle(Color.ink)
                            Spacer()
                            Text("Next →")
                                .font(.money(16)).foregroundStyle(.white)
                                .padding(.horizontal, 18).padding(.vertical, 12)
                                .background(Capsule().fill(Color.tangerine))
                                .overlay(Capsule().strokeBorder(Color.keyline, lineWidth: 2))
                                .hardShadow(Capsule())
                        }
                        .padding(12)
                        .glassRail()
                    }
                }
                .padding(20)
            }
        }
    }

    @ViewBuilder
    private func section(_ title: String, @ViewBuilder _ content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.caption).tracking(1.4)
                .foregroundStyle(Color.inkSoft)
            content()
        }
    }
}

private struct FlowChips: View {
    let swatches: [(String, Color)]
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 10)], spacing: 10) {
            ForEach(swatches, id: \.0) { name, color in
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(color)
                        .frame(width: 40, height: 28)
                        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(Color.keyline, lineWidth: 1))
                    Text(name).font(.caption).foregroundStyle(Color.ink)
                    Spacer(minLength: 0)
                }
            }
        }
    }
}

#Preview("Light") { DesignSystemGallery() }
#Preview("Dark") { DesignSystemGallery().preferredColorScheme(.dark) }
