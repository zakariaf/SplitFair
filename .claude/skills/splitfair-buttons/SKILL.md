---
name: splitfair-buttons
description: Specs and SwiftUI for SplitFair's buttons — the primary Tangerine CTA, the outlined secondary, and the destructive Clear-bill button, all with hard offset shadows and press physics. Use when creating, styling, or reviewing any button, call-to-action, or tappable action in the app.
---

# SplitFair — buttons

Three button roles. All use the 2pt ink keyline + hard offset shadow language (`splitfair-shapes-and-depth`) and money/rounded type (`splitfair-typography`).

## Primary (the one loud CTA)

"Next: Tax & Tip →". One per screen. `RoundedRectangle` r=20, **Tangerine fill, white SF Rounded Semibold 17pt**, 2pt ink keyline, hard offset shadow x+3 y+4.

- **Press physics:** shadow collapses to x+1 y+1 + the button nudges down 3pt (a physical "push") + `.sensoryFeedback(.selection)`.
- **Disabled** (unassigned items exist): desaturated, label becomes "Assign all items first," and tapping triggers the unassigned wiggle instead of navigating (`splitfair-status-flags`).
- Lives on the glass footer rail but is itself **opaque**.

## Secondary (outlined sticker)

"Copy summary" and inline actions. Surface/clear fill, 2pt ink keyline, ink label, small or no offset shadow (lower emphasis than primary).

## Destructive ("Clear bill")

Ink keyline + **danger-red label** (`#E5453C` / dark `#FF5A50`) + trash SF Symbol, low emphasis. It is the **only** control that opens a confirm dialog (shake-to-confirm on press). Never use danger-red for anything else.

## SwiftUI sketch

```swift
struct PrimaryButton: View {
    let title: String; var enabled = true; let action: () -> Void
    @State private var pressed = false
    var body: some View {
        Button(action: action) {
            Text(title).font(.money(17)).foregroundStyle(.white).padding(.horizontal, 20).padding(.vertical, 14)
        }
        .background(RoundedRectangle(cornerRadius: 20).fill(enabled ? Color.tangerine : Color.inkSoft))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.ink, lineWidth: 2))
        .background(Color.ink.offset(x: pressed ? 1 : 3, y: pressed ? 1 : 4))
        .offset(y: pressed ? 3 : 0)
        .sensoryFeedback(.selection, trigger: pressed)
        .disabled(!enabled)
    }
}
```

## Rules

- Every button ≥ 44×44pt (`splitfair-accessibility`).
- Label says exactly what happens ("Copy summary" → toast "Copied ✓"). No vague verbs.
- Only the primary gets the deep offset shadow; secondary/destructive stay quieter — spend emphasis in one place.
