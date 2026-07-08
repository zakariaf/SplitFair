---
name: splitfair-design-system
description: SplitFair's visual language "HARD COPY" (Warm Receipt Brutalism) — principles, the loud-frame/calm-center rule, the iOS 26 Liquid Glass stance, and how to set up design tokens in SwiftUI. Use when styling any screen or view, making a visual decision, setting up the DesignSystem folder, or checking whether a design choice is on-brand.
---

# SplitFair — design system: HARD COPY (Warm Receipt Brutalism)

A settle-up screen that reads like a warm luncheonette check run through a receipt printer: **ink-on-cream tabular numbers you can trust across a restaurant table**, die-cut color "sticker people" for the joy, and a rubber-stamp **SETTLED ✓**. Bold and colorful — never at the expense of money legibility.

## Principles

1. **Loud frame, calm center.** Saturated color lives ONLY on people, chrome (CTA/footer), and celebration (the stamp). Every surface holding a number stays opaque and near-neutral. **No dollar ever sits on a gradient, chip, or glass.**
2. **Trust is a shape, not a hue.** Every stateful meaning carries ≥3 grayscale-legible signals (color + shape/notch/texture + icon/text). If it dies in grayscale, it wasn't designed.
3. **Printer-receipt honesty.** Tabular monospaced digits column-align; the odometer and stamp animate the exact reconciled integer-cent value the math produces (`splitfair-money-math`).
4. **Warm brutalism.** Thick ink keylines + hard offset shadows (0 blur) for arm's-length confidence, softened by warm cream paper, rounded corners, and a serif voice — friendly, not aggressive.
5. **Matte receipt on one glass rail.** Diverge from Liquid Glass on all content; extend it on exactly one chrome element.
6. **Motion only visualizes meaning** — assign / split / reconcile, never idle shimmer (`splitfair-motion-and-haptics`).

## Domain skills

Foundations: `splitfair-color-system` · `splitfair-typography` · `splitfair-shapes-and-depth` · `splitfair-motion-and-haptics` · `splitfair-accessibility`.
Components: `splitfair-buttons` · `splitfair-cards` · `splitfair-diner-chip` · `splitfair-split-ring` · `splitfair-tip-controls` · `splitfair-reconciliation-banner` · `splitfair-status-flags`.

## iOS 26 Liquid Glass stance — "matte receipt on one glass rail"

- **DIVERGE (identity):** all content surfaces are opaque matte paper + die-cut stickers with hard offset shadows — the deliberate opposite of glass. Prices, totals, rows, chips: never translucent.
- **EXTEND (one place):** the single sticky bottom rail uses `.glassEffect` (fallback `.regularMaterial`). Even there, the live number rides an opaque cream pill so no digit composites over glass.
- Under Reduce Transparency the rail → opaque cream. (Liquid Glass requires compiling against the iOS 26 SDK; keep the deployment target at iOS 17 — `splitfair-app-architecture`.)

## Token setup in SwiftUI

Structure `DesignSystem/` as tokens → theme → modifiers → shapes. Colors via Asset Catalog (Any/Dark appearances → automatic light/dark, no manual branches). Full tokens in `splitfair-color-system`, `splitfair-typography`, `splitfair-shapes-and-depth`.

```swift
extension Color {  // see splitfair-color-system for all values
    static let canvas = Color("Canvas"); static let surface = Color("Surface"); static let ink = Color("Ink")
    static let tangerine = Color("Tangerine"); static let acidLime = Color("AcidLime")
    static let success = Color("Success"); static let warning = Color("Warning"); static let danger = Color("Danger")
}
extension Font {   // see splitfair-typography
    static func money(_ s: CGFloat)  -> Font { .system(size: s, weight: .black, design: .rounded).monospacedDigit() }
    static func ledger(_ s: CGFloat) -> Font { .system(size: s, weight: .heavy, design: .monospaced).monospacedDigit() }
    static func display(_ s: CGFloat)-> Font { .custom("Fraunces", size: s) }
}
```

## Do / Don't (headline)

- **Do** keep all money ink-on-cream / cream-on-aubergine; put color on chips, CTA, the lime tip pill, and the stamp only.
- **Do** use the hard offset shadow (solid rect, 0 blur) for depth; reserve green for reconciliation, amber for unassigned, red only for Clear.
- **Don't** place a number on a gradient/chip/glass; don't use red/green for owed vs settled (owed is a neutral ink number); don't over-glass; don't add idle motion.
