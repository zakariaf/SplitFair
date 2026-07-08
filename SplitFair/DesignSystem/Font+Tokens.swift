import SwiftUI

extension Font {
    /// Display money face — SF Pro Rounded Black, tabular digits so money never jitters or reflows.
    static func money(_ size: CGFloat) -> Font {
        .system(size: size, weight: .black, design: .rounded).monospacedDigit()
    }

    /// Ledger face — SF Mono, tabular; column-aligns like printer output.
    static func ledger(_ size: CGFloat, weight: Font.Weight = .heavy) -> Font {
        .system(size: size, weight: weight, design: .monospaced).monospacedDigit()
    }

    /// Voice face — the warm serif for the wordmark, section titles, and the "WHO'S SPLITTING?" hero
    /// ONLY. A system serif stands in for Fraunces until `Fraunces.ttf` is bundled (add it to the
    /// target + Info.plist `ATSApplicationFontsPath`, then change this ONE implementation to
    /// `.custom("Fraunces", size: size)` — no call sites change).
    static func display(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    /// Body / label face — SF Pro Text.
    static func bodyText(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }

    /// Chip initials — SF Rounded Semibold.
    static var chipInitials: Font { .system(size: 15, weight: .semibold, design: .rounded) }

    // MARK: - HARD COPY type scale
    //
    // Display/hero sizes are capped and wrap rather than truncate; full Dynamic Type mapping is
    // layered in EPIC 08 (accessibility).
    static var heroSubtotal: Font { money(56) }
    static var hero: Font { display(48) }
    static var sectionTitle: Font { display(32) }
    static var personTotal: Font { money(40) }
    static var tipReadout: Font { money(26) }
    static var itemPrice: Font { ledger(24) }
    static var personName: Font { bodyText(17) }
    static var ledgerLine: Font { ledger(15, weight: .regular) }
    static var caption: Font { bodyText(13) }
}
