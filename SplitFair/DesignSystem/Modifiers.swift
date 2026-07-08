import SwiftUI

extension View {
    /// The HARD COPY depth cue: a solid, 0-blur offset shadow (never a soft iOS blur), drawn as a
    /// copy of `shape` behind the view. Pass the shape that matches the view's own background.
    func hardShadow(_ shape: some Shape, dx: CGFloat = 3, dy: CGFloat = 4) -> some View {
        background(shape.fill(Color.hardShadow).offset(x: dx, y: dy))
    }

    /// A chunky matte card: surface fill + 2pt ink keyline + hard offset shadow.
    func card(cornerRadius: CGFloat = 26, padding: CGFloat = 20) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return self.padding(padding)
            .background(shape.fill(Color.surface))
            .overlay(shape.strokeBorder(Color.keyline, lineWidth: 2))
            .hardShadow(shape)
    }

    /// A die-cut sticker capsule: fill + 2pt ink keyline + a shallow hard offset shadow.
    func sticker(_ fill: Color, horizontalPadding: CGFloat = 15, verticalPadding: CGFloat = 10) -> some View {
        self.padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(Capsule().fill(fill))
            .overlay(Capsule().strokeBorder(Color.keyline, lineWidth: 2))
            .hardShadow(Capsule(), dx: 2, dy: 3)
    }

    /// Overlays a diner's die-cut notch marks at the given corners — the grayscale-legible identity
    /// silhouette that distinguishes two similar hues.
    func notchMarks(_ positions: [NotchPosition]) -> some View {
        overlay {
            GeometryReader { geo in
                ForEach(Array(positions.enumerated()), id: \.offset) { _, position in
                    NotchMark().position(position.point(in: geo.size))
                }
            }
        }
    }
}

/// A single die-cut notch: a canvas-filled, keyline-bordered diamond straddling the chip edge.
struct NotchMark: View {
    var body: some View {
        Rectangle()
            .fill(Color.canvas)
            .overlay(Rectangle().strokeBorder(Color.keyline, lineWidth: 2))
            .frame(width: 11, height: 11)
            .rotationEffect(.degrees(45))
    }
}

extension NotchPosition {
    /// The point on the chip's edge where this notch sits.
    func point(in size: CGSize) -> CGPoint {
        switch self {
        case .topLeft: CGPoint(x: size.width * 0.28, y: 0)
        case .topRight: CGPoint(x: size.width * 0.72, y: 0)
        case .bottomLeft: CGPoint(x: size.width * 0.28, y: size.height)
        case .bottomRight: CGPoint(x: size.width * 0.72, y: size.height)
        case .topMid: CGPoint(x: size.width * 0.5, y: 0)
        case .bottomMid: CGPoint(x: size.width * 0.5, y: size.height)
        }
    }
}
