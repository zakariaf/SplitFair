---
name: splitfair-diner-chip
description: The die-cut "sticker person" chip in SplitFair — a capsule carrying a diner's color, initials, unique corner-notch, and micro-texture, with hollow/assigned states for tap-to-assign. Use when building the roster bar, item-row assignment chips, person avatars, or the add-person control.
---

# SplitFair — diner chip (sticker)

The core identity element and the whole assignment interaction. A `Capsule`, ≥44×44, that reads as a physical die-cut sticker.

## Anatomy (four redundant identity channels — `splitfair-color-system`)

- **Fill** = the diner's hue.
- **2pt ink/cream keyline** (`splitfair-shapes-and-depth`).
- **Centered initials** in the pre-paired white/ink that clears 4.5:1.
- **Unique corner-notch** (`CornerNotch` shape) — single or double, position per diner; grayscale-legible silhouette.
- **Micro-texture** overlay (~12% opacity) per diner.
- Hard offset shadow (roster/solid state).

## States

- **Roster header:** always solid + shadow.
- **In an item row, unassigned:** hollow — clear fill, ink outline, ink initials, no shadow, scale 1.0.
- **In an item row, assigned:** fills with hue, keyline appears, **scale 1.08 spring**, drops a filled arc onto the row's split-ring (`splitfair-split-ring`), `.sensoryFeedback(.selection)`.
- **Add-person:** dashed-outline capsule with `plus.circle`; bounces a new solid chip in on tap; name field auto-focuses (`splitfair-motion-and-haptics`).

Tap toggles assignment; tapping 2+ people on an item splits it evenly.

```swift
struct DinerChip: View {
    let color: Color; let initials: String; let notch: NotchStyle; let texture: ChipTexture
    var assigned = true
    var body: some View {
        Text(initials).font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundStyle(assigned ? color.pairedInk : Color.ink)
            .padding(.horizontal, 15).frame(minWidth: 44, minHeight: 44)
            .background(Capsule().fill(assigned ? color : .clear))
            .overlay(TextureOverlay(texture).opacity(assigned ? 0.12 : 0).clipShape(Capsule()))
            .overlay(Capsule().stroke(Color.ink, lineWidth: 2))
            .overlay(CornerNotch(notch))                       // die-cut silhouette
            .scaleEffect(assigned ? 1.08 : 1.0)
            .modifier(assigned ? BrutalShadow() : BrutalShadow.none)
    }
}
```

## Rules

- **Never rely on color alone** — initials + notch + texture must carry identity in grayscale/CVD (`splitfair-accessibility`).
- Assigned vs unassigned differ by fill **and** keyline **and** scale **and** the ring arc — four state signals.
- VoiceOver: "Ana, assigned to Nachos, double-tap to remove."
- Colors and per-diner notch/texture come from the fixed palette in `splitfair-color-system`; assign by roster index (stable all session).
