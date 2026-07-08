import SwiftUI

/// HARD COPY layout constants (radii, spacing, hard-shadow offset) exposed through the environment
/// so components read them consistently. Colours live in Color+Tokens, type in Font+Tokens.
struct Theme {
    var rowRadius: CGFloat = 22
    var cardRadius: CGFloat = 26
    var spacing: CGFloat = 16
    var shadowOffset: CGSize = CGSize(width: 3, height: 4)
}

extension EnvironmentValues {
    @Entry var theme = Theme()
}

extension View {
    /// The app's ONE glass element (the footer rail). Uses `.regularMaterial` today; swap to the
    /// iOS 26 Liquid Glass `.glassEffect` when built against that SDK. Falls back to opaque cream
    /// under Reduce Transparency so a number on the rail never composites over glass.
    func glassRail(cornerRadius: CGFloat = 26) -> some View {
        modifier(GlassRail(cornerRadius: cornerRadius))
    }
}

private struct GlassRail: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return content
            .background {
                if reduceTransparency {
                    shape.fill(Color.canvas)
                } else {
                    shape.fill(.regularMaterial)
                }
            }
            .overlay(shape.strokeBorder(Color.keyline, lineWidth: 2))
            .hardShadow(shape)
    }
}
