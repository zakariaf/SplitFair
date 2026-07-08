import SwiftUI

/// A thin ink-bordered ring that encircles an item's price. When shared it divides into N equal
/// colored arcs (in roster order, matching `allocate([1]*N)`), so a split reads spatially by arc
/// length — legible even in grayscale. The price text stays pure ink inside; colour rings the
/// number, never touches it.
struct SplitRing: View {
    /// The diners sharing the item, in roster order. Empty means unassigned.
    let assignees: [DinerStyle]
    var lineWidth: CGFloat = 5

    var body: some View {
        ZStack {
            if assignees.isEmpty {
                Circle()
                    .strokeBorder(Color.inkSoft, style: StrokeStyle(lineWidth: 3, dash: [4, 6]))
            } else {
                // Ink underlay shows through the gaps between arcs as a thin ink border.
                Circle().stroke(Color.ink, lineWidth: lineWidth + 2)

                let count = assignees.count
                let segment = 1.0 / Double(count)
                let gap = count > 1 ? 0.035 : 0.0
                ForEach(Array(assignees.enumerated()), id: \.offset) { index, diner in
                    Circle()
                        .trim(from: Double(index) * segment + gap / 2,
                              to: Double(index + 1) * segment - gap / 2)
                        .stroke(diner.color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt))
                        .rotationEffect(.degrees(-90)) // start at the top
                }
            }
        }
        .padding(lineWidth / 2 + 1) // keep the stroke inside the frame
        .animation(.spring(response: 0.32, dampingFraction: 0.7), value: assignees.count)
        .accessibilityHidden(true) // the item row describes "split N ways"
    }
}

#Preview("SplitRing") {
    HStack(spacing: 20) {
        SplitRing(assignees: []).frame(width: 76, height: 76)
        SplitRing(assignees: Array(DinerPalette.all.prefix(1))).frame(width: 76, height: 76)
        SplitRing(assignees: Array(DinerPalette.all.prefix(3))).frame(width: 76, height: 76)
        ZStack {
            SplitRing(assignees: Array(DinerPalette.all.prefix(2)))
            Text("28.00").font(.ledger(15)).foregroundStyle(Color.ink)
        }
        .frame(width: 76, height: 76)
    }
    .padding()
    .background(Color.canvas)
}
