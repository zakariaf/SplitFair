import SwiftUI

/// A die-cut "sticker person": a capsule carrying a diner's colour, initials, unique notch
/// silhouette, and micro-texture — four redundant identity channels, never colour alone.
///
/// In the roster it renders solid; inside an item row it renders `assigned` (filled, keyline, a hair
/// larger, shadow) or hollow (outline only) to show who shares the item.
struct DinerChip: View {
    let diner: DinerStyle
    let initials: String
    var assigned: Bool = true
    var showsShadow: Bool = true

    var body: some View {
        Text(initials)
            .font(.chipInitials)
            .foregroundStyle(assigned ? diner.labelInk : Color.ink)
            .frame(minWidth: 44, minHeight: 44)
            .padding(.horizontal, 4)
            .background(Capsule().fill(assigned ? AnyShapeStyle(diner.color) : AnyShapeStyle(Color.clear)))
            .overlay {
                if assigned {
                    ChipTexturePattern(texture: diner.texture)
                        .opacity(0.14)
                        .clipShape(Capsule())
                }
            }
            .overlay(Capsule().strokeBorder(assigned ? Color.keyline : Color.ink.opacity(0.55), lineWidth: 2))
            .background {
                if assigned && showsShadow {
                    Capsule().fill(Color.hardShadow).offset(x: 2, y: 3)
                }
            }
            .notchMarks(diner.notches)
            .scaleEffect(assigned ? 1.06 : 1.0)
            .animation(.spring(response: 0.32, dampingFraction: 0.7), value: assigned)
            .accessibilityElement()
            .accessibilityLabel(Text(diner.name))
    }
}

/// A dashed "+ Add" chip that bounces a new diner in.
struct AddDinerChip: View {
    var body: some View {
        Label("Add", systemImage: "plus")
            .font(.chipInitials)
            .foregroundStyle(Color.inkSoft)
            .frame(minHeight: 44)
            .padding(.horizontal, 14)
            .overlay(Capsule().strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5, 4])).foregroundStyle(Color.inkSoft))
    }
}

/// The subtle per-diner micro-texture (a fourth redundant identity channel), drawn with `Canvas`.
struct ChipTexturePattern: View {
    let texture: ChipTexture

    var body: some View {
        Canvas { context, size in
            let shading = GraphicsContext.Shading.color(.black)
            let step: CGFloat = 6
            switch texture {
            case .solid:
                break
            case .dots:
                forGrid(size, step) { p in context.fill(dot(at: p, r: 1), with: shading) }
            case .ring:
                let r = min(size.width, size.height) * 0.32
                context.stroke(Path(ellipseIn: CGRect(x: size.width / 2 - r, y: size.height / 2 - r, width: r * 2, height: r * 2)), with: shading, lineWidth: 2)
            case .checker:
                forGrid(size, step * 1.4) { p in
                    if Int(p.x / (step * 1.4) + p.y / (step * 1.4)).isMultiple(of: 2) {
                        context.fill(Path(CGRect(x: p.x, y: p.y, width: step * 1.4, height: step * 1.4)), with: shading)
                    }
                }
            default:
                context.stroke(linePath(size, texture: texture, step: step), with: shading, lineWidth: 1)
            }
        }
    }

    private func forGrid(_ size: CGSize, _ step: CGFloat, _ body: (CGPoint) -> Void) {
        var y: CGFloat = 0
        while y < size.height {
            var x: CGFloat = 0
            while x < size.width { body(CGPoint(x: x, y: y)); x += step }
            y += step
        }
    }

    private func dot(at p: CGPoint, r: CGFloat) -> Path { Path(ellipseIn: CGRect(x: p.x, y: p.y, width: r * 2, height: r * 2)) }

    private func linePath(_ size: CGSize, texture: ChipTexture, step: CGFloat) -> Path {
        var path = Path()
        let diag = size.width + size.height
        switch texture {
        case .diagonal, .crossHatch:
            var x = -size.height
            while x < size.width { path.move(to: CGPoint(x: x, y: 0)); path.addLine(to: CGPoint(x: x + size.height, y: size.height)); x += step }
            if texture == .crossHatch {
                var x2: CGFloat = 0
                while x2 < diag { path.move(to: CGPoint(x: x2, y: 0)); path.addLine(to: CGPoint(x: x2 - size.height, y: size.height)); x2 += step }
            }
        case .horizontalRule, .grid, .waves:
            var y: CGFloat = 0
            while y < size.height { path.move(to: CGPoint(x: 0, y: y)); path.addLine(to: CGPoint(x: size.width, y: y)); y += step }
            fallthrough
        case .verticalBars:
            if texture == .verticalBars || texture == .grid {
                var x: CGFloat = 0
                while x < size.width { path.move(to: CGPoint(x: x, y: 0)); path.addLine(to: CGPoint(x: x, y: size.height)); x += step }
            }
        default:
            break
        }
        return path
    }
}

#Preview("DinerChips") {
    HStack {
        ForEach(DinerPalette.all.prefix(4)) { diner in
            DinerChip(diner: diner, initials: String(diner.name.prefix(2)))
        }
        DinerChip(diner: DinerPalette.all[0], initials: "Ho", assigned: false)
        AddDinerChip()
    }
    .padding()
    .background(Color.canvas)
}
