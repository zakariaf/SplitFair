import SwiftUI

/// A torn "tear-off" top edge — a run of scalloped perforations — so a footer rail or reconciliation
/// stub reads like a check stub. Apply with `.clipShape(PerforationEdge())`.
struct PerforationEdge: Shape {
    var toothWidth: CGFloat = 22
    var toothRadius: CGFloat = 6

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: toothRadius))
        var x: CGFloat = 0
        while x < rect.width {
            path.addArc(
                center: CGPoint(x: x + toothWidth / 2, y: toothRadius),
                radius: toothRadius,
                startAngle: .degrees(180),
                endAngle: .degrees(360),
                clockwise: false
            )
            x += toothWidth
        }
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
    }
}

/// The faint dot-matrix receipt grid, drawn once with `Canvas`. Sits behind content, never behind a
/// number's own surface.
struct DotMatrixBackground: View {
    var spacing: CGFloat = 15
    var dotRadius: CGFloat = 0.9

    var body: some View {
        Canvas { context, size in
            let dot = Path(ellipseIn: CGRect(x: 0, y: 0, width: dotRadius * 2, height: dotRadius * 2))
            var y = spacing / 2
            while y < size.height {
                var x = spacing / 2
                while x < size.width {
                    context.fill(dot.offsetBy(dx: x, dy: y), with: .color(Color.ink.opacity(0.05)))
                    x += spacing
                }
                y += spacing
            }
        }
        .allowsHitTesting(false)
    }
}

/// Two or three very-low-opacity blurred colour blobs drifting slowly — the ONLY blur in the app,
/// and never behind a number. Honors Reduce Motion (static when reduced).
struct DriftingBlobs: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let blobs: [(color: Color, x: CGFloat, y: CGFloat, radius: CGFloat)] = [
        (.tangerine, 0.15, 0.10, 130),
        (Color(light: 0x2E_7DF7, dark: 0x4C_93FF), 0.88, 0.34, 115),
        (Color(light: 0x8A_5CF6, dark: 0x9E_77FF), 0.30, 0.86, 105),
    ]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { timeline in
            Canvas { context, size in
                context.addFilter(.blur(radius: 60))
                let time = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
                for (index, blob) in blobs.enumerated() {
                    let dx = CGFloat(sin(time * 0.10 + Double(index))) * 20
                    let dy = CGFloat(cos(time * 0.13 + Double(index))) * 24
                    let center = CGPoint(x: blob.x * size.width + dx, y: blob.y * size.height + dy)
                    let frame = CGRect(
                        x: center.x - blob.radius, y: center.y - blob.radius,
                        width: blob.radius * 2, height: blob.radius * 2
                    )
                    context.fill(Path(ellipseIn: frame), with: .color(blob.color.opacity(0.06)))
                }
            }
            .allowsHitTesting(false)
        }
    }
}
