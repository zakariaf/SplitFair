---
name: splitfair-split-ring
description: The split-ring in SplitFair — a thin ink-bordered ring around each item's price that divides into N equal colored arcs when the item is shared, making a split visible spatially rather than by hue. Use when building or animating the item-row price indicator or showing how many people share an item.
---

# SplitFair — split-ring

A thin (3pt) **ink-bordered ring encircling each item's price** (`splitfair-cards`). It shows *how many people share the item* as equal arc segments — so a split reads **spatially** (arc length), legible even in grayscale. The price text inside stays pure ink; **color rings the number, never touches it.**

## Behavior

- **Unassigned:** a full hollow ink ring (dashed) — pairs with the amber hazard-tape row state (`splitfair-status-flags`).
- **Assigned to N:** the ring divides into **N equal arcs** via `.trim`, each arc tinted the assignee's diner hue (`splitfair-color-system`) with a ~1pt ink gap between arcs.
- Animates the division with a spring on each assign/unassign; a `matchedGeometryEffect` arc flies in from the tapped chip (`splitfair-motion-and-haptics`).

## Geometry

For a circle of circumference `C` and `N` assignees: each arc = `C/N`, drawn length `= C/N − gap`, with `strokeDashoffset = −(i · C/N)`. Rotate −90° so arc 0 starts at top. Assignee order = roster order (deterministic, matches `allocate([1]*N)` in `splitfair-money-math`).

```swift
struct SplitRing: View {
    let assignees: [DinerStyle]      // in roster order; empty = unassigned
    var body: some View {
        ZStack {
            Circle().stroke(Color.divider, lineWidth: 3)                       // base
            if assignees.isEmpty {
                Circle().stroke(Color.inkSoft, style: .init(lineWidth: 3.5, dash: [4, 6]))
            } else {
                let seg = 1.0 / Double(assignees.count)
                ForEach(Array(assignees.enumerated()), id: \.offset) { i, d in
                    Circle()
                        .trim(from: Double(i)*seg, to: Double(i+1)*seg - 0.02) // ink gap
                        .stroke(d.color, style: .init(lineWidth: 5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.32, dampingFraction: 0.7), value: assignees.count)
                }
            }
        }
    }
}
```

## Rules

- The price stays **SF Mono ink** centered inside; the ring is decoration + a redundant "shared N ways" signal, not the number's background.
- Arc count == `Item.assigneeIDs.count`; keep it in sync with the model so it never lies about the split.
- VoiceOver describes it: "split 3 ways" (`splitfair-accessibility`).
