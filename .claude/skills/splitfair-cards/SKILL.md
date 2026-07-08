---
name: splitfair-cards
description: Specs and SwiftUI for SplitFair's two card types — the item row (Screen 1) and the expandable per-person total card (Screen 2). Use when building, styling, or reviewing item rows, person total cards, or any surface that groups a price or a total.
---

# SplitFair — cards

Both cards use the matte surface + hard offset shadow (`splitfair-shapes-and-depth`), ink numerals (`splitfair-color-system`), and tabular type (`splitfair-typography`).

## Item row (Screen 1)

`RoundedRectangle` r=22, Receipt White surface, hard offset shadow, 20pt padding.

- **Top:** optional label 17pt (placeholder "Item", italic secondary); a **right-aligned SF Mono Heavy 24pt price wrapped in the split-ring** (`splitfair-split-ring`).
- **Bottom:** a horizontally-scrollable strip of diner chips (`splitfair-diner-chip`) + an inline **"Shared by all"** pill that cascade-fills every chip.
- **Left edge:** a 4pt ink rule → turns to **amber hazard-tape when unassigned** (`splitfair-status-flags`).
- Single-tap chips, no modes, no steppers. Tabular digits keep the price column aligned like a printed receipt.

## Per-person total card (Screen 2)

`RoundedRectangle` r=26, hard offset shadow.

- **Header:** the person's color sticker (`splitfair-diner-chip`) + name 17pt.
- **Right:** **SF Rounded Black 40pt total, `.monospacedDigit()`, ink (never colored)** + a ⌄ chevron.
- **Tap → expand** via `matchedGeometryEffect` into that person's itemized lines + prorated tax/tip in SF Mono 15pt, each faintly tinted (~8%) in that person's hue.
- **Bento ordering:** the biggest ower sits first and slightly larger. Collapsed height ≥ 64pt.

```swift
struct PersonTotalCard: View {
    let name: String; let total: Money; let color: Color; @Binding var expanded: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 13) {
                DinerChip(/* color, initials, notch, texture */)
                Text(name).font(.system(size: 17, weight: .semibold)); Spacer()
                Text(Decimal(total.minorUnits)/100, format: .currency(code: "USD"))
                    .font(.money(40)).foregroundStyle(Color.ink)         // ink, never colored
                Image(systemName: "chevron.down").rotationEffect(.degrees(expanded ? 180 : 0))
            }
            if expanded { /* ledger lines: item shares + prorated tax + tip, SF Mono 15 */ }
        }
        .card()
        .onTapGesture { withAnimation(.spring) { expanded.toggle() } }
    }
}
```

## Rules

- **The total is always ink**, never a diner hue or accent — color lives on the chip, not the number (`splitfair-design-system`).
- Expanded breakdown values are tabular; label→value rows use a dotted leader.
- Whole card is the tap target (≥64pt); respect Reduce Motion for the expand (`splitfair-motion-and-haptics`).
