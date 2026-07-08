---
name: splitfair-shapes-and-depth
description: SplitFair's shape language and depth — hard offset shadows (0 blur), corner radii, and the custom SwiftUI Shapes (perforation edge, corner-notch, split-ring, dot-matrix grid) plus reusable modifiers. Use when building any surface, shadow, sticker, torn edge, or background, or authoring a custom Shape/ViewModifier.
---

# SplitFair — shapes & depth

A "matte receipt + die-cut stickers" world with warm-brutalist confidence.

## Corners & depth

- Cards/rows are chunky `RoundedRectangle` — radius **22** (item rows), **26** (per-person cards), 20pt padding.
- **Depth is a HARD OFFSET SHADOW** (a solid ink/aubergine rectangle offset x+3 y+4, **0 blur**) — never a soft iOS blur. This is the neo-brutalist confidence cue.
- Corners stay warm-rounded (not acid-sharp) so it reads friendly.

```swift
struct BrutalShadow: ViewModifier {
    func body(content: Content) -> some View {
        content.background(Color.ink.offset(x: 3, y: 4))   // solid, 0-blur, behind the shape
    }
}
extension View {
    func card() -> some View {
        padding(20)
            .background(RoundedRectangle(cornerRadius: 26).fill(.surface))
            .modifier(BrutalShadow())
    }
    func sticker(_ c: Color) -> some View {
        padding(10).background(Capsule().fill(c)).overlay(Capsule().stroke(Color.ink, lineWidth: 2))
    }
    func perforatedTop() -> some View { clipShape(PerforationEdge()) }
}
```

## Signature custom Shapes (author as `Shape`)

- **`PerforationEdge`** — a torn zig-zag + dotted top edge (trig loop) for the footer rail and the reconciliation stub, so the total "tears off" like a check stub (`splitfair-reconciliation-banner`, `splitfair-status-flags`).
- **`CornerNotch`** — subtracts a small square/double-square from one corner; the per-diner position is the redundant identity token (`splitfair-diner-chip`).
- **`SplitRing`** — draws N equal arcs (`startAngle`/`endAngle`, animate with `.trim`) around an item's price (`splitfair-split-ring`).
- **Dot-matrix grid** — the faint receipt grid, drawn once in a `Canvas`.

## Background depth (restrained)

2–3 very-low-opacity (~0.06) blurred accent `Ellipse`s drifting slowly **behind** the dot-matrix grid — the ONLY gradient/blur in the app, and **never behind a number**.

```swift
ZStack { Ellipse().fill(hue).blur(80).opacity(0.06) /* offset by a TimelineView date */ }
```

## Rules

- Iconography = SF Symbols (`checkmark.seal.fill`, `exclamationmark.triangle.fill`, `plus.circle`) — nothing bundled.
- Keep sticker shadows shallow — deep/skeuomorphic reads 2011, not 2026.
- Keyline is 2pt ink (light) / cream (dark), from `splitfair-color-system`.
