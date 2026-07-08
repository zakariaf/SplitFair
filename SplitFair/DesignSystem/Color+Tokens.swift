import SwiftUI
import UIKit

extension Color {
    /// A token that resolves to `light` or `dark` (each `0xRRGGBB`) by the environment's color
    /// scheme. The single light/dark decision lives here, so views never branch on `colorScheme`.
    init(light: UInt32, dark: UInt32) {
        self = Color(uiColor: UIColor { traits in
            UIColor(rgb: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }

    /// A fixed color from a `0xRRGGBB` value (identical in light and dark).
    init(rgb: UInt32) { self = Color(uiColor: UIColor(rgb: rgb)) }
}

private extension UIColor {
    convenience init(rgb: UInt32) {
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: 1
        )
    }
}

// MARK: - HARD COPY color tokens
//
// "Loud frame, calm center": saturated color lives only on diner chips, chrome (CTA/footer), and
// the SETTLED stamp. Every surface that holds a number stays warm and near-neutral, and no number
// ever sits on a gradient, chip, or glass.
extension Color {
    static let canvas = Color(light: 0xFAF2E2, dark: 0x16_121C) // warm cream / deep aubergine
    static let surface = Color(light: 0xFFFFFF, dark: 0x22_1C2E)
    static let sheet = Color(light: 0xFFFFFF, dark: 0x2B_2438)
    static let ink = Color(light: 0x1A_1613, dark: 0xF7_EDDD) // all money + body
    static let inkSoft = Color(light: 0x6E_6152, dark: 0xB3_A594)
    static let keyline = Color(light: 0x1A_1613, dark: 0xF7_EDDD)
    static let divider = Color(light: 0xE7_DCC6, dark: 0x3A_3348)
    static let hardShadow = Color(light: 0x1A_1613, dark: 0x0C_0912) // solid, 0-blur offset shadow

    static let tangerine = Color(light: 0xFF_5A2C, dark: 0xFF_6E44) // primary CTA
    static let acidLime = Color(light: 0xB8_E600, dark: 0xD2_FF3A) // live tip readout (always ink text)
    static let success = Color(light: 0x1F_B25A, dark: 0x34_D07A) // reconciliation ✓ ONLY
    static let warning = Color(light: 0xFF_9E1C, dark: 0xFF_B44D) // unassigned fill / icon (with hazard tape)
    static let warningInk = Color(light: 0x9A_5B00, dark: 0xFF_B44D) // dark amber for warning TEXT on light (>=4.5:1)
    static let warningFill = Color(light: 0xFF_EBC4, dark: 0x3A_2A12)
    static let danger = Color(light: 0xE5_453C, dark: 0xFF_5A50) // Clear bill ONLY
}
