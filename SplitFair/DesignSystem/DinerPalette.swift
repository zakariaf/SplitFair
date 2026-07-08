import SwiftUI

/// Where a chip's die-cut notch(es) sit. A grayscale-legible silhouette that identifies a diner even
/// when colour is unavailable (colorblindness, grayscale, a read across the table).
enum NotchPosition: Hashable {
    case topLeft, topRight, bottomLeft, bottomRight, topMid, bottomMid
}

/// A subtle per-diner overlay pattern — a further redundant identity channel that survives on a
/// black-and-white printout and for total colorblindness.
enum ChipTexture: Hashable {
    case solid, dots, diagonal, horizontalRule, ring, crossHatch, checker, verticalBars, grid, waves
}

/// One diner's visual identity across four redundant channels: colour + label ink + notch
/// silhouette + texture. Never colour alone.
struct DinerStyle: Identifiable, Hashable {
    let index: Int
    let name: String
    let color: Color
    let labelInk: Color
    let notches: [NotchPosition]
    let texture: ChipTexture
    var id: Int { index }
}

enum DinerPalette {
    private static let white = Color.white
    private static let inkLabel = Color(rgb: 0x1A_1613) // fixed dark, for bright chips (cyan/sunflower)

    /// The fixed 10-colour set, assigned by roster index. Each hue is CVD-tuned (dark ≈ +8% lightness)
    /// and paired with a DISTINCT notch silhouette and texture; the two greens (Pine/Fern) sit far
    /// apart in luminance.
    static let all: [DinerStyle] = [
        DinerStyle(index: 0, name: "Vermilion", color: Color(light: 0xF2_542D, dark: 0xFF_6A46), labelInk: white, notches: [.topLeft], texture: .solid),
        DinerStyle(index: 1, name: "Bubblegum", color: Color(light: 0xE8_4AA6, dark: 0xF3_61B8), labelInk: white, notches: [.topRight], texture: .dots),
        DinerStyle(index: 2, name: "Grape", color: Color(light: 0x8A_5CF6, dark: 0x9E_77FF), labelInk: white, notches: [.bottomLeft], texture: .diagonal),
        DinerStyle(index: 3, name: "Ocean", color: Color(light: 0x2E_7DF7, dark: 0x4C_93FF), labelInk: white, notches: [.bottomRight], texture: .horizontalRule),
        DinerStyle(index: 4, name: "Cyan", color: Color(light: 0x17_BEBB, dark: 0x2A_D3D0), labelInk: inkLabel, notches: [.topLeft, .topRight], texture: .ring),
        DinerStyle(index: 5, name: "Pine", color: Color(light: 0x16_A085, dark: 0x22_B899), labelInk: white, notches: [.bottomLeft, .bottomRight], texture: .crossHatch),
        DinerStyle(index: 6, name: "Sunflower", color: Color(light: 0xF4_B400, dark: 0xFF_C21F), labelInk: inkLabel, notches: [.topLeft, .bottomRight], texture: .checker),
        DinerStyle(index: 7, name: "Terracotta", color: Color(light: 0xB5_651D, dark: 0xCE_7A31), labelInk: white, notches: [.topRight, .bottomLeft], texture: .verticalBars),
        DinerStyle(index: 8, name: "Slate", color: Color(light: 0x5C_6B8A, dark: 0x76_86A6), labelInk: white, notches: [.topMid], texture: .grid),
        DinerStyle(index: 9, name: "Fern", color: Color(light: 0x3F_A34D, dark: 0x54_BA62), labelInk: white, notches: [.bottomMid], texture: .waves),
    ]

    /// Stable style for a roster colour index. Beyond 10 the palette cycles; the chip appends a
    /// numeric badge (see the diner-chip component) so the 11th diner onward never collide.
    static func style(for colorIndex: Int) -> DinerStyle {
        all[((colorIndex % all.count) + all.count) % all.count]
    }

    /// The badge number to show when the palette has cycled (11th diner onward), else nil.
    static func cycleBadge(for colorIndex: Int) -> Int? {
        colorIndex >= all.count ? (colorIndex / all.count) + 1 : nil
    }
}
